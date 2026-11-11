#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region BSPProceduresAndFunctions

#Region OutputDescriptions

// Returns a representation of the command to create a new data exchange.
//
// Returns:
//  String - The Presentation of the command displayed in the user interface.
//
// For example:
//	Return of the NStr("ru = 'Create an exchange in a distributed information base'");
//
Function NewDataExchangeCreationCommandTitle() Export
	
	Return NStr("vi = 'Chương trình bất kỳ có hỗ trợ định dạng dữ liệu đa năng';
				|ru = 'Любая программа с поддержкой универсального формата данных';
				|en = 'Any application that supports interim format data'; fa = 'Any application that supports interim format data';
				|it = 'Qualsiasi programma con il supporto del formato dati universale';
				|pl = 'Dowolna programa, obsługująca uniwersalny format danych';
				|tr = 'Yaygın veri formatını destekleyen herhangi bir program'");
	
EndFunction

// Returns a summary of the exchange information output when setting up data synchronization.
//
// Parameters:
//   SettingID          - String - the name of the additional exchange setting.
//
// Returns:
//   String - brief information on the exchange.
//
Function BriefExchangeInfo(SettingID)
	
	NoteText = "";
	
	If SettingID = IdOfExchangeSetupBP30() Then
		NoteText = NStr("vi = 'Tùy chỉnh này cho phép đồng bộ dữ liệu giữa các chương trình ""%1""
		|và ""Kế toán doanh nghiệp, phiên bản 3.0"". Các chứng từ và thông tin tra cứu tham gia vào đồng bộ.';
		|ru = 'Данная настройка позволит синхронизировать данные между программами ""%1""
		|и ""Бухгалтерия предприятия, редакция 3.0"".  В синхронизации участвуют документы и нормативно-справочная информация.';
		|en = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Enterprise Accounting 3.0. Synchronization involves documents and master data.'; fa = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Enterprise Accounting 3.0. Synchronization involves documents and master data.';
		|it = 'Questa impostazione permette di sincronizzare i dati tra i programmi ""%1""
		|e ""1C:Enterprise Accounting 3.0"". Nella sincronizzazione vengono inclusi documenti e informazioni di riferimento.';
		|pl = 'Ta konfiguracja umożliwi synchronizację danych między programami ""%1""
		|i ""1C:Enterprise Accounting 3.0"".  W synchronizacji uczestniczą dokumenty i informacje normatywnie-pomocnicze.';
		|tr = 'Bu ayar, ""%1""
		|ve ""İşletme muhasebesi, revizyon 3.0"" programları arasında veri senkronizasyonu yapılmasını sağlar.  Senkronizasyon, belgeleri ve master veri bilgilerini içerir.'");
	ElsIf SettingID = IdOfExchangeSetupBPCORP30() Then
		NoteText = NStr("vi = 'Tùy chỉnh này cho phép đồng bộ dữ liệu giữa chương trình ""%1""
		|và ""Kế toán doanh nghiệp CORP, phiên bản 3.0"". Các chứng từ và thông tin tra cứu tham gia vào đồng bộ.';
		|ru = 'Данная настройка позволит синхронизировать данные между программами ""%1""
		|и ""Бухгалтерия предприятия КОРП, редакция 3.0"".  В синхронизации участвуют документы и нормативно-справочная информация.';
		|en = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Enterprise Accounting CORP 3.0. Synchronization involves documents and master data.'; fa = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Enterprise Accounting CORP 3.0. Synchronization involves documents and master data.';
		|it = 'Questa impostazione permette di sincronizzare i dati tra i programmi ""%1""
		|e ""1C:Enterprise Accounting CORP 3.0"". Nella sincronizzazione vengono inclusi documenti e informazioni di riferimento.';
		|pl = 'Ta konfiguracja umożliwi synchronizację danych między programami ""%1""
		|i ""1C:Enterprise Accounting CORP 3.0"".  W synchronizacji uczestniczą dokumenty i informacje normatywnie-pomocnicze.';
		|tr = 'Bu ayar, ""%1""
		| ile ""CORP işletme muhasebesi, revizyon 3.0"" arasında veri senkronizasyonu yapmanızı sağlar.  Senkronizasyon, belgeleri ve master veri bilgilerini içerir.'");
	ElsIf SettingID = IdOfBasicUTBP30ExchangeSetup() Then
		NoteText = NStr("vi = 'Tùy chỉnh này cho phép gửi dữ liệu từ chương trình ""1C:Quản lý thương mại cơ bản, phiên bản 11""
		|sang chương trình ""Kế toán doanh nghiệp, phiên bản 3.0"". Thực hiện đồng bộ dữ liệu ở chế độ một chiều.';
		|ru = 'Данная настройка позволит отправлять данные из программы ""1С:Управление торговлей базовая, редакция 11""
		|в программу ""Бухгалтерия предприятия, редакция 3.0"". Синхронизация данных выполняется в одностороннем режиме.';
		|en = 'With this setting, you can send data from 1C:Trade Management basic 11 
		|to 1C:Enterprise Accounting 3.0. Data is synchronized in one-way mode.'; fa = 'With this setting, you can send data from 1C:Trade Management basic 11 
		|to 1C:Enterprise Accounting 3.0. Data is synchronized in one-way mode.';
		|it = 'Questa impostazione permette di inviare i dati dal programma ""1C:Trade Management basic 11""
		|al programma ""1C:Enterprise Accounting 3.0"". La sincronizzazione dati avviene in modo unidirezionale.';
		|pl = 'Ta konfiguracja umożliwi wysyłanie danych z programu ""1C:Trade Management basic 11""
		|do programu ""1C:Enterprise Accounting 3.0"". Synchronizacja danych jest wykonywana w trybie jednostronnym.';
		|tr = 'Bu ayar, 1C:Trade Management temel, revizyon 11''den
		|İşletme muhasebesi, revizyon 3.0''a veri gönderilmesine olanak tanır. Veri senkronizasyonu tek yönlü modda gerçekleştirilir.'");
	ElsIf SettingID = "CashExchange" Then
		NoteText = NStr("vi = 'Tùy chỉnh này cho phép đồng bộ dữ liệu giữa các chương trình ""%1""
		|và ""1C:Kassa"". Các chứng từ và thông tin tra cứu tham gia vào đồng bộ.';
		|ru = 'Данная настройка позволит синхронизировать данные между программами ""%1""
		|и ""1С:Касса"".  В синхронизации участвуют документы и нормативно-справочная информация.';
		|en = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Checkout. Synchronization involves documents and master data.'; fa = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Checkout. Synchronization involves documents and master data.';
		|it = 'Questa impostazione permette di sincronizzare i dati tra i programmi ""%1""
		|e ""1C:Checkout"". Nella sincronizzazione vengono inclusi documenti e informazioni di riferimento.';
		|pl = 'Ta konfiguracja umożliwi synchronizację danych między programami ""%1""
		|i ""1C:Checkout"".  W synchronizacji uczestniczą dokumenty i informacje normatywnie pomocnicze.';
		|tr = 'Bu ayar ""%1""
		|ve ""1C:Checkout"" programları arasında veri senkronizasyonu yapılmasını sağlar.  Senkronizasyon, belgeleri ve master veri bilgileri içerir.'");
	ElsIf SettingID = "ExchangeOfUPRMC" Then
		NoteText = NStr("vi = 'Tùy chỉnh này cho phép đồng bộ dữ liệu giữa các chương trình ""%1""
		|và ""1C:Cashier''s workplace"". Các chứng từ và thông tin tra cứu tham gia vào đồng bộ.';
		|ru = 'Данная настройка позволит синхронизировать данные между программами ""%1""
		|и ""1С:Рабочее место кассира"".  В синхронизации участвуют документы и нормативно-справочная информация.';
		|en = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:POS. Synchronization involves documents and master data.'; fa = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:POS. Synchronization involves documents and master data.';
		|it = 'Questa impostazione permette di sincronizzare i dati tra i programmi ""%1""
		|e ""1C:Posto di lavoro del cassiere"". Nella sincronizzazione vengono inclusi documenti e informazioni di riferimento.';
		|pl = 'Ta konfiguracja umożliwi synchronizację danych między programami ""%1""
		|i ""1C:POS"". W synchronizacji uczestniczą dokumenty i informacje normatywnie pomocnicze.';
		|tr = 'Bu ayar, ""%1""
		|ve ""1C:POS"" programları arasında veri senkronizasyonu yapmanızı sağlar.  Senkronizasyon, belgeleri ve master veri bilgileri içerir.'"); 
	ElsIf SettingID = IdOfWorkflowExchangeSettings() Then
		NoteText = NStr("ru = 'Данная настройка позволит синхронизировать данные между программами ""%1""
		|и ""1С:Документооборот КОРП, редакция 3.0"".  В синхронизации участвует нормативно-справочная информация.';
		|vi = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Document Management CORP 3.0. Synchronization involves master data.';
		|en = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Document Management CORP 3.0. Synchronization involves master data.'; fa = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Document Management CORP 3.0. Synchronization involves master data.';
		|it = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Document Management CORP 3.0. Synchronization involves master data.';
		|pl = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Document Management CORP 3.0. Synchronization involves master data.';
		|tr = 'Bu ayar, ""%1""
		|ve ""1C:Document Management CORP, 3.0 revizyonu"" programları arasında veri senkronizasyonu yapmanızı sağlar. Senkronizasyon, düzenleyici referans bilgilerini içermektedir.'");
	ElsIf SettingID = "UpbpExchange" Then
		NoteText = NStr("vi = 'Tùy chỉnh này cho phép đồng bộ dữ liệu giữa các chương trình ""%1""
		|và ""Kế toán doanh nghiệp, phiên bản 3.0"". Các chứng từ và thông tin tra cứu tham gia vào đồng bộ.';
		|ru = 'Данная настройка позволит синхронизировать данные между программами ""%1""
		|и ""Бухгалтерия предприятия, редакция 3.0"".  В синхронизации участвуют документы и нормативно-справочная информация.';
		|en = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Enterprise Accounting 3.0. Synchronization involves documents and master data.'; fa = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Enterprise Accounting 3.0. Synchronization involves documents and master data.';
		|it = 'Questa impostazione permette di sincronizzare i dati tra i programmi ""%1""
		|e ""1C:Enterprise Accounting 3.0"". Nella sincronizzazione vengono inclusi documenti e informazioni di riferimento.';
		|pl = 'Ta konfiguracja umożliwi synchronizację danych między programami ""%1""
		|i ""1C:Enterprise Accounting 3.0"".  W synchronizacji uczestniczą dokumenty i informacje normatywnie-pomocnicze.';
		|tr = 'Bu ayar, ""%1""
		|ve ""İşletme muhasebesi, revizyon 3.0"" programları arasında veri senkronizasyonu yapılmasını sağlar.  Senkronizasyon, belgeleri ve master veri bilgilerini içerir.'");
	ElsIf SettingID = "ExchangeUP2ZUP3" Then
		NoteText = NStr("vi = 'Tùy chỉnh này cho phép đồng bộ dữ liệu giữa các chương trình ""%1""
		|và ""HRM and Payroll, phiên bản 3"". Các chứng từ và thông tin tra cứu tham gia vào đồng bộ.';
		|ru = 'Данная настройка позволит синхронизировать данные между программами ""%1""
		|и ""Зарплата и Управление Персоналом, редакция 3"".  В синхронизации участвуют документы и нормативно-справочная информация.';
		|en = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:HRM 3. Synchronization involves documents and master data.'; fa = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:HRM 3. Synchronization involves documents and master data.';
		|it = 'Questa impostazione permette di sincronizzare i dati tra i programmi ""%1""
		|e ""Retribuzione e Gestione del Personale, versione 3£. Nella sincronizzazione vengono inclusi documenti e informazioni di riferimento.';
		|pl = 'Ta konfiguracja umożliwi synchronizację danych między programami ""%1""
		|i ""Wynagrodzenie i Zarządzanie Kadrami, edycja 3"".  W synchronizacji uczestniczą dokumenty i informacje normatywnie-pomocnicze.';
		|tr = 'Bu ayar, ""%1""
		|ile ""Maaş ve Personel Yönetimi, revizyon 3"" arasında veri senkronizasyonu yapılmasını sağlar.  Senkronizasyon, belgeleri ve master veri bilgileri içerir.'");
	ElsIf SettingID = "UpuppExchange" Then
		NoteText = NStr("vi = 'Tùy chỉnh này cho phép đồng bộ dữ liệu giữa các chương trình ""%1""
		|và ""Quản lý doanh nghiệp sản xuất, phiên bản 1.3"". Các chứng từ và thông tin tra cứu tham gia vào đồng bộ.';
		|ru = 'Данная настройка позволит синхронизировать данные между программами ""%1""
		|и ""Управление производственным предприятием, редакция 1.3"".  В синхронизации участвуют документы и нормативно-справочная информация.';
		|en = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Manufacturing Enterprise Management 1.3. Synchronization involves documents and master data.'; fa = 'With this setting, you can synchronize data between ""%1"" 
		|and 1C:Manufacturing Enterprise Management 1.3. Synchronization involves documents and master data.';
		|it = 'Questa impostazione permette di sincronizzare i dati tra i programmi ""%1""
		|e ""Gestione imprese produttive, versione 1.3"". Nella sincronizzazione vengono inclusi documenti e informazioni di riferimento.';
		|pl = 'Ta konfiguracja umożliwi synchronizację danych między programami ""%1""
		|i ""Zarządzanie przedsiębiorstwem produkcyjnym, edycja 1.3"".  W synchronizacji uczestniczą dokumenty i informacje normatywnie-pomocnicze.';
		|tr = 'Bu ayar, ""%1""
		|ile ""Üretim işletmesi yönetimi, revizyon 1.3"" arasında veri senkronizasyonu yapılmasını sağlar.  Senkronizasyon, belgeleri ve master veri içerir.'");
	Else
		NoteText = NStr("vi = 'Cho phép đồng bộ dữ liệu giữa các chương trình bất kỳ có hỗ trợ định dạng trao đổi đa năng ""Enterprise Data"".';
						|ru = 'Позволяет синхронизировать данные между любыми программами, поддерживающими универсальный формат обмена ""Enterprise Data"".';
						|en = 'Allows you to synchronize data between any applications that support interim exchange format ""Enterprise Data"".'; fa = 'Allows you to synchronize data between any applications that support interim exchange format ""Enterprise Data"".';
						|it = 'Permette di sincronizzare i dati tra qualsiasi programma che supporti il formato universale di scambio ""Enterprise Data"".';
						|pl = 'Pozwala synchronizować dane między dowolnymi programami, które obsługują uniwersalny format wymiany ""Enterprise Data"".';
						|tr = '""Enterprise Data"" yaygın değişim formatını destekleyen tüm programlar arasında veri senkronizasyonu yapılmasını sağlar.'");
	EndIf;
	
	NoteText = StringFunctionsClientServer.SubstituteParametersToString(
                     NoteText, Metadata.Synonym);
	
	Return NoteText;
	
EndFunction


#EndRegion

#Region OverridableUploadAddOnSettings

// It is intended for setting up options for interactive configuration of unloading according to the node scenario.
// To configure it, you need to set the values of the parameter properties to the required values.
//
// Parameters:
//     Recipient - ExchangePlanRef - The node for which the configuration is being performed
//     Parameters  - Structure        - Parameters to change. Contains fields:
//
//         Add-on options - Structure - settings of the typical "Do not add" option.
//                                                Contains fields:
//             Usage - Boolean - option usage permission flag. The default is True.
//             Order - Number - the order in which the option is placed on the assistant form, from top to bottom. The default is 1.
//             The title - String - allows you to redefine the name of a typical variant.
//             Explanation - String - allows you to redefine the text of the explanation option for the user.
//
//         Variantsedocuments - Structure - settings of the typical option "Add all documents for the period".
//                                                Contains fields:
//             Usage - Boolean - option usage permission flag. The default is True.
//             Order - Number - the order in which the option is placed on the assistant form, from top to bottom. The default is 2.
//             The title - String - allows you to redefine the name of a typical variant.
//             Explanation - String - allows you to redefine the text of the explanation option for the user.
//
//         Variant Spontaneous selection - Structure - settings of the typical option "Add data with random selection".
//                                                Contains fields:
//             Usage - Boolean - option usage permission flag. The default is True.
//             Order - Number - the order in which the option is placed on the assistant form, from top to bottom. The default is 3.
//             The title - String - allows you to redefine the name of a typical variant.
//             Explanation - String - allows you to redefine the text of the explanation option for the user.
//
//         Optional - Structure - settings of an additional option according to the node scenario.
//                                                Contains fields:
//             Usage - Boolean            - option permission flag. The default is False.
//             Order - Number - the order in which the option is placed on the assistant form, from top
//                                                            to bottom. The default is 4.
//             Title - String - the name of the option to display on the form.
//             The name of the Selection form is String - The name of the form that is called for editing settings.
//             The Form command header is the Header string for drawing commands to open the settings form on the form.
//             Use the Selection period - Boolean            - flag that a general selection by period is required. The
//                                                            default is False.
//             Selection period - Standard Period - the value of the general selection period offered by default.
//
//             Selection - Assignment table - contains lines describing detailed selections according to the node scenario.
//                                                            Contains columns:
//                 The full name of the metadata - String - the full name of the metadata of the registered object, the selection
//                                                               of which describes the string. For example
//                                                               , "Document._demopodavailyetovars". You can use
//                                                               the special values "All Documents" and "All References"
//                                                               to select, respectively, all documents and all
//                                                               Catalogs registered at the Recipient node.
//                 Period Selection is Boolean                - flag that this line describes a selection with a common period.
//                 Period - Standard Period - the value of the general selection period for the row metadata
//                                                               offered by default.
//                 Selection - Selection of new data - selection by default. Selection fields are formed in
//                                                               accordance with the general rules for the formation
//                                                               of layout fields. For example, to specify the selection by the Attribute
//                                                               of the "Organization" document, you must use the "Link.Organization".
Procedure SetUpInteractiveExport(Recipient, Parameters) Export
	
	DetailsOfExchangeNode = Common.ObjectAttributesValues(Recipient, "DocumentsExportMode, CatalogsExportMode");
	
	If DetailsOfExchangeNode.DocumentsExportMode = Enums.ExchangeObjectExportModes.DoNotExport 
		And DetailsOfExchangeNode.CatalogsExportMode = Enums.ExchangeObjectExportModes.DoNotExport Then
		
		Parameters.AllDocumentsOption.Use      = False;
		Parameters.OptionDoNotAdd.Use     = False;
		Parameters.ArbitraryFilterOption.Use = False;
		Parameters.AdditionalOption.Use     = False;
		
	Else
		
		// Disabling the option "VariantVseDocuments"
		
		Parameters.AllDocumentsOption.Use = False;
		
		// Setting up the "No add-on" option 
		Parameters.OptionDoNotAdd.Use = True;
		Parameters.OptionDoNotAdd.Order       = 3;
		Parameters.OptionDoNotAdd.Title     = NStr("vi = 'Không thêm chứng từ để gửi';
													|ru = 'Не добавлять документы к отправке';
													|en = 'Do not add documents to send'; fa = 'Do not add documents to send';
													|it = 'Non aggiungere documenti all''invio';
													|pl = 'Nie dodawaj dokumentów do wysyłki';
													|tr = 'Gönderime belge ekleme'") 
			+ Chars.LF 
			+ NStr("vi = 'Chỉ gửi thông tin tra cứu đã thay đổi từ thời điểm gửi gần nhất.';
					|ru = 'Отправлять только нормативно-справочную информацию, измененную с момента последней отправки.';
					|en = 'Send only master data that has been changed since the last time it was sent.'; fa = 'Send only master data that has been changed since the last time it was sent.';
					|it = 'Inviare solo le informazioni di riferimento modificate al momento dell''ultimo invio.';
					|pl = 'Wysyłaj tylko normatywnie-pomocnicze informacje, zmienione od momentu ostatniej wysyłki.';
					|tr = 'Yalnızca son gönderildiği zamandan bu yana değişen master veri bilgilerini gönder.'");
		
		// Setting up the "Random selection" option 
		Parameters.ArbitraryFilterOption.Use = True;
		Parameters.ArbitraryFilterOption.Order       = 2;
		
		RulesForSendingRecipientSDocuments = Common.ObjectAttributeValue(Recipient, "DocumentsSendingRules");
		
		If RulesForSendingRecipientSDocuments = "NotSynchronize" Then
			Parameters.ArbitraryFilterOption.Title = NStr("vi = 'Thêm danh mục';
															|ru = 'Добавить справочники';
															|en = 'Add catalogs'; fa = 'Add catalogs';
															|it = 'Aggiungere directory';
															|pl = 'Dodaj katalogi';
															|tr = 'Katalogları ekle'");
		Else
			Parameters.ArbitraryFilterOption.Title = NStr("vi = 'Thêm danh mục và chứng từ tùy ý';
															|ru = 'Добавить произвольные справочники и документы';
															|en = 'Add arbitrary catalogs and documents'; fa = 'Add arbitrary catalogs and documents';
															|it = 'Aggiungere directory arbitrarie e documenti';
															|pl = 'Dodaj dowolne katalogi i dokumenty';
															|tr = 'Keyfi katalog ve belgeleri ekle'");
		EndIf;
		
		If Not RulesForSendingRecipientSDocuments = "NotSynchronize" Then
			// Calculate and set the script parameters
			DefaultParameters = DefaultUploadParameters(Recipient);
			
			// Setting up the "Advanced" option according to the node scenario
			Parameters.AdditionalOption.Use            = True;
			Parameters.AdditionalOption.Order                  = 1;
			Parameters.AdditionalOption.Title                = NStr("vi = 'Gửi tất cả chứng từ';
																	|ru = 'Отправить все документы';
																	|en = 'Send all documents'; fa = 'Send all documents';
																	|it = 'Inviare tutti i documenti';
																	|pl = 'Wysyłaj wszystkie dokumenty';
																	|tr = 'Tüm belgeleri gönder'");
			Parameters.AdditionalOption.FilterFormName           = "ExchangePlan.DataSynchronizationViaUniversalFormat.Form.ExportSetting";
			Parameters.AdditionalOption.FormCommandTitle    = NStr("vi = 'Chọn doanh nghiệp để lọc';
																	|ru = 'Выбрать организации для отбора';
																	|en = 'Select companies to filter'; fa = 'Select companies to filter';
																	|it = 'Selezionare l''azienda per il filtro';
																	|pl = 'Wybierz firmy do filtrowania';
																	|tr = 'Filtre için iş yerini seç'");
			Parameters.AdditionalOption.UseFilterPeriod = True;
			Parameters.AdditionalOption.FilterPeriod1             = DefaultParameters.Period;
			
			// Adding the selection settings line
			FilterDetails = Parameters.AdditionalOption.Filter; // ValueTable
			 
			FIlterRow = FilterDetails.Add();
			FIlterRow.FullMetadataName = "AllDocuments";
			FIlterRow.PeriodSelection = True;
			FIlterRow.Period       = DefaultParameters.Period;
			FIlterRow.Filter        = DefaultParameters.Filter;
		Else
			Parameters.AdditionalOption.Use = False;
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns a Presentation of the selection for the option to supplement the upload according to the node scenario.
// See the description of "Optional" in the procedure "Configure Interactive Upload".
//
// Parameters:
//     Recipient - ExchangePlanRef - The node for which the selection view is defined
//     Parameters  - Structure        - Characteristics of selection. Contains fields:
//         Use the Selection period - Boolean            - flag that you need to use the general selection for the period.
//         The selection period is the standard period - the value of the general selection period.
//         Selection - Assignment table - contains lines describing detailed selections according to the node scenario.
//                                                        Contains columns:
//                 The full name of the metadata - String - the full name of the metadata of the registered object, the selection
//                                                               of which describes the string. For example
//                                                               , "Document._demopodavailyetovars". 
//                                                               The special values "All Documents" and
//                                                               "All Documents" can be used to select, respectively, all
//                                                               documents and all Catalogs registered at
//                                                               the Recipient node.
//                 Period Selection - Boolean                - flag that this line describes a selection with a common period.
//                 Period - Standard Period - the value of the general selection period for row metadata.
//                 Selection - Selection of new data - selection fields. Selection fields are formed in accordance with
//                                                               the general rules for the formation of layout fields.
//                                                               For example, to specify the selection by the Attribute of the document
//                                                               "Organization", the field "Link.Organization".
//
// Returns: 
//     String - selection description
//
Function InteractiveExportFilterPresentation(Recipient, Parameters) Export
	
	If Parameters.UseFilterPeriod Then
		If ValueIsFilled(Parameters.FilterPeriod1) Then
			PeriodDetails = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'cho kỳ: %1';
					|ru = 'за период: %1';
					|en = 'for the period: %1'; fa = 'for the period: %1';
					|it = 'nel periodo: %1';
					|pl = 'za okres: %1';
					|tr = 'dönem içerisinde: %1'"), Lower(Parameters.FilterPeriod1));
		Else
			ExportStartDate = Common.ObjectAttributeValue(Recipient, "DocumentsExportStartDate");
			If ValueIsFilled(ExportStartDate) Then
				PeriodDetails = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'bắt đầu từ ngày bắt đầu gửi chứng từ: %1';
						|ru = 'начиная с даты начала отправки документов: %1';
						|en = 'starting from the document sending date: %1'; fa = 'starting from the document sending date: %1';
						|it = 'iniziando dalla data di inizio di invio dei documenti: %1';
						|pl = 'zaczynając od daty rozpoczęcia wysyłki dokumentów: %1';
						|tr = 'belge gönderiminin başlangıç tarihinden itibaren: %1'"), Format(ExportStartDate, "DLF=DD"));
			Else
				PeriodDetails = NStr("vi = 'trong toàn kỳ kế toán';
									|ru = 'за весь период учета';
									|en = 'for the entire accounting period'; fa = 'for the entire accounting period';
									|it = 'per tutto il periodo di contabilità';
									|pl = 'za cały okres ewidencji';
									|tr = 'tüm muhasebe dönemi içinde'");
			EndIf;
		EndIf;
	Else
		PeriodDetails = "";
	EndIf;
	
	CompaniesList = OrganizationsThatSelectInteractiveUploads(Parameters.Filter);
	
	If CompaniesList.Count()=0 Then
		OrganizationSelectionDescription = NStr("vi = 'theo tất cả doanh nghiệp';
												|ru = 'по всем организациям';
												|en = 'by all companies'; fa = 'by all companies';
												|it = 'per tutte le aziende';
												|pl = 'według wszystkich firm';
												|tr = 'tüm iş yerlerine'");
	Else
		OrganizationSelectionDescription = "";
		For Each Item In CompaniesList Do
			OrganizationSelectionDescription = OrganizationSelectionDescription+ ", " + Item.Presentation;
		EndDo;
		OrganizationSelectionDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'có lọc theo doanh nghiệp: %1';
				|ru = 'с отбором по организациям: %1';
				|en = 'with filter by companies: %1'; fa = 'with filter by companies: %1';
				|it = 'con il filtro per aziende: %1';
				|pl = 'z filtrem według firm: %1';
				|tr = 'iş yerine göre filtre ile: %1'"), TrimAll(Mid(OrganizationSelectionDescription, 2)));
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Sẽ gửi tất cả chứng từ %1,
		|%2';
		|ru = 'Будут отправлены все документы %1,
		|%2';
		|en = 'All documents will be sent %1,
		|%2'; fa = 'All documents will be sent %1,
		|%2';
		|it = 'Saranno inviati tutti i documenti %1,
		|%2';
		|pl = 'Zostaną wysłane wszystkie dokumenty %1,
		|%2';
		|tr = 'Tüm belgeler gönderilecektir %1,
		|%2'"),
		PeriodDetails, OrganizationSelectionDescription);
	
EndFunction

// Calculation of default unloading parameters.
//
// Parameters:
//     Recipient - ExchangePlanRef - The node for which the configuration is performed.
//
// The return value - Structure - contains the fields:
//     Selection View - String - text description of the selection by default 
//     Period - Standard Period - the default value of the general selection period
//     Selection - Selection of new data - selection.
//
Function DefaultUploadParameters(Recipient)
	
	Result = New Structure;
	
	// The default period
	Result.Insert("Period", New StandardPeriod);
	Result.Period.Variant = StandardPeriodVariant.LastMonth;
	
	// Default selection and its representation
	FilterComposer = New DataCompositionSettingsComposer;
	Result.Insert("Filter", FilterComposer.Settings.Filter);
	
	// General idea, we do not include the period, since in this scenario the period field will be edited separately.
	Result.Insert( "FilterPresentation", 
		StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Sẽ gửi tất cả chứng từ trong %1';
			|ru = 'Будут отправлены все документы за %1';
			|en = 'All documents for %1 will be sent'; fa = 'All documents for %1 will be sent';
			|it = 'Saranno inviati tutti i documenti per %1';
			|pl = 'Zostaną wysłane wszystkie dokumenty za %1';
			|tr = '%1 için tüm belgeler gönderilecektir'"),
		Lower(String(Result.Period.Variant))));
	
	Return Result;
	
EndFunction

// Returns a list of organizations according to the selection table (see "Interactive Upload Selection View")
// It is also used from the demo form of the "Upload Settings" of this exchange plan.
//
// Parameters:
//     FilterTable - ValueTable   - contains lines describing detailed selections according to the node scenario. Contains columns:
//         Full Data nameimage - String
//         Period Selection is Boolean
//         Period - Standard Period
//         Selection - A selection of new data.
//
// Returns:
//     ValueList of CatalogRef.Companies - link to the organization, representation - name.
//
Function OrganizationsThatSelectInteractiveUploads(Val FilterTable) Export
	
	Result = New ValueList;
	
	Filter = FilterTable[0].Filter; // DataCompositionFilter
	If FilterTable.Count()=0 Or Filter.Items.Count()=0 Then
		// No selection data available
		Return Result;
	EndIf;
	
	// We know the composition of the selection, since we put it there ourselves - either from the "Set up Interactive Upload"
	// or as a result of editing in the form.
	DataString1 = Filter.Items[0];
	Selected_1   = DataString1.RightValue; // CatalogRef.Companies, ValueList of CatalogRef.Companies
	CollectionType = TypeOf(Selected_1);
	
	If CollectionType=Type("ValueList") Then
		
		For Each Item In Selected_1 Do
			AddListOfOrganizations(Result, Item.Value);
		EndDo;
		
	ElsIf CollectionType=Type("Array") Then
		
		AddListOfOrganizations(Result, Selected_1);
		
	ElsIf CollectionType=Type("CatalogRef.Companies") Then
		
		If Result.FindByValue(Selected_1)=Undefined Then
			Result.Add(Selected_1, Selected_1.Description);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Adds a collection to the list of organizations
//
// Parameters:
//     List      - ValueList of CatalogRef.Companies - updated list
//     Companies - CatalogRef.Companies, Array of CatalogRef.Companies - collection of organizations.
// 
Procedure AddListOfOrganizations(List, Val Companies)
	
	For Each Organization In Companies Do
		
		If TypeOf(Organization)=Type("Array") Then
			AddListOfOrganizations(List, Organization);
			Continue;
		EndIf;
		
		If List.FindByValue(Organization)=Undefined Then
			List.Add(Organization, Organization.Description);
		EndIf;
		
	EndDo;
	
EndProcedure

// When determining the supported format objects.
// 
// Parameters:
//  SupportedObjects - ValueTable - Contains a list of format objects supported by this information base in the context of format versions:
//   *Version - String - Format version, for example "1.6"
//   *Object - String - An object of the format, for example, "Directory.Nomenclature"
//   *Send - Boolean - True if the information database supports sending this format object
//               The column is available if Mode = "Sending" or "Sending receiving"
//   *Receive - Boolean - True if the information database supports receiving this format object
//               The column is available if Mode = "Receive", "Send"
//  Mode - String - Type of requested information. Possible values: "Sending" - request for format objects
//			for which sending is supported; "Receiving" - request for objects for which receiving is supported;
//			"Send-Receive" is a request for all supported objects in the format.
//  ExchangeNode - ExchangePlanRef, Undefined - A link to the exchange plan node corresponding to the correspondent
//			in the context of which information about supported format objects is requested. 
//          It can be used if necessary to limit the list of objects supported by this information base 
//          , depending on the exchange configuration option set on the node.
//
Procedure OnDefineSupportedFormatObjects(SupportedObjects, Mode, ExchangeNode = Undefined) Export
	
	AllowDataImportToBaseVersion = ?(ExchangeNode <> Undefined, ExchangeNode.AllowDataImportToBaseVersion, False);
	If StrFind(Mode, "Receive") > 0 And StandardSubsystemsServer.IsBaseConfigurationVersion()
		And Not AllowDataImportToBaseVersion Then
		SupportedObjects.FillValues(False, "Receive");
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// Fills in settings that affect the use of the exchange plan.
// 
// Parameters:
//  Settings - See DataExchangeServer.DefaultExchangePlanSettings
//
Procedure OnGetSettings(Settings) Export
	
	Settings.SourceConfigurationName = DataExchangeTMERP.SourceConfigurationName();
	
	Settings.IsXDTOExchangePlan                              = True;
	Settings.Global                                     = True;
	Settings.WarnAboutExchangeRuleVersionMismatch = False;
	Settings.ExchangeFormat = "http://v8.1c.ru/edi/edi_stnd/EnterpriseData";
	
	FormatVersions = New Map;
	TMDataExchange.AvailableVersionsOfUniversalFormat(FormatVersions);
	
	Settings.ExchangeFormatVersions = FormatVersions;
	Settings.UseCacheOfPublicIdentifiers				= True;
	Settings.ExchangePlanUsedInSaaS					= True;
	
	Settings.Algorithms.OnGetSettingOptionDetails		= True;
	Settings.Algorithms.OnGetExchangeSettingsOptions			= True;
	Settings.Algorithms.SetUpInteractiveExport				= True;
	Settings.Algorithms.InteractiveExportFilterPresentation	= True;
	Settings.Algorithms.OnDefineSupportedFormatObjects = True;
	
	Settings.RulesForRegisteringInManager							= True;
	Settings.RegistrationManagerName = "RegistrationManager";
	
EndProcedure

// Fills in the collection of settings options provided for the exchange plan.
// 
// Parameters:
//  ExchangeSettingsOptions - ValueTable - a collection of exchange settings options, see the description of the return value
//                                       of the Exchange Settings function for the silence of the general module of the Exchange Server.
//  ContextParameters     - See DataExchangeServer.ContextParametersOfSettingsOptionsReceipt
//
Procedure OnGetExchangeSettingsOptions(ExchangeSettingsOptions, ContextParameters) Export
	
	If GetFunctionalOption("TradeManagement")
		And StandardSubsystemsServer.IsBaseConfigurationVersion() Then
			
			If ContextParameters.CorrespondentName = "EnterpriseAccounting"
				Or Not ValueIsFilled(ContextParameters.CorrespondentName) Then
				SettingsMode = ExchangeSettingsOptions.Add();
				SettingsMode.SettingID        = IdOfBasicUTBP30ExchangeSetup();
				SettingsMode.CorrespondentInSaaS   = True;
				SettingsMode.CorrespondentInLocalMode = True;
			EndIf;
			
	EndIf;
			
	If ContextParameters.CorrespondentName = "EnterpriseAccounting"
		Or Not ValueIsFilled(ContextParameters.CorrespondentName) Then
		SettingsMode = ExchangeSettingsOptions.Add();
		SettingsMode.SettingID        = IdOfExchangeSetupBP30();
		SettingsMode.CorrespondentInSaaS   = True;
		SettingsMode.CorrespondentInLocalMode = True;
	EndIf;
	
	If ContextParameters.CorrespondentName = "EnterpriseAccountingCORP"
		Or Not ValueIsFilled(ContextParameters.CorrespondentName) Then
		SettingsMode = ExchangeSettingsOptions.Add();
		SettingsMode.SettingID        = IdOfExchangeSetupBPCORP30();
		SettingsMode.CorrespondentInSaaS   = True;
		SettingsMode.CorrespondentInLocalMode = True;
	EndIf;
	If ContextParameters.CorrespondentName = "SalaryAndPersonnelManagement"
		Or Not ValueIsFilled(ContextParameters.CorrespondentName) Then
		SettingsMode = ExchangeSettingsOptions.Add();
		SettingsMode.SettingID        = "ExchangeUP2ZUP3";
		SettingsMode.CorrespondentInSaaS   = True;
		SettingsMode.CorrespondentInLocalMode = True;
	EndIf;
	
	If Not ValueIsFilled(ContextParameters.CorrespondentName) Then
		SettingsMode = ExchangeSettingsOptions.Add();
		SettingsMode.SettingID        = "UpuppExchange";
		SettingsMode.CorrespondentInSaaS   = False;
		SettingsMode.CorrespondentInLocalMode = True;
	EndIf;
	If Not ValueIsFilled(ContextParameters.CorrespondentName) Then
		
		SettingsMode = ExchangeSettingsOptions.Add();
		SettingsMode.SettingID        = "CashExchange";
		SettingsMode.CorrespondentInSaaS   = True;
		SettingsMode.CorrespondentInLocalMode = True;
		
		SettingsMode = ExchangeSettingsOptions.Add();
		SettingsMode.SettingID        = "ExchangeOfUPRMC";
		SettingsMode.CorrespondentInSaaS   = True;
		SettingsMode.CorrespondentInLocalMode = True;
		
		SettingsMode = ExchangeSettingsOptions.Add();
		SettingsMode.SettingID        = "UniversalExchange";
		SettingsMode.CorrespondentInSaaS   = True;
		SettingsMode.CorrespondentInLocalMode = True;
		
		SettingsMode = ExchangeSettingsOptions.Add();
		SettingsMode.SettingID        = IdOfWorkflowExchangeSettings();
		SettingsMode.CorrespondentInSaaS   = True;
		SettingsMode.CorrespondentInLocalMode = True;
		
	EndIf;
	
EndProcedure

// Fills in a set of parameters that define the exchange configuration option.

// When receiving a description of the configuration option.
// 
// Parameters:
//  OptionDetails       - See DataExchangeServer.DefaultExchangeSettingOptionDetails
//  SettingID - String - ID of the exchange configuration option.
//  ContextParameters     - See DataExchangeServer.ContextParametersOfSettingOptionDetailsReceipt
Procedure OnGetSettingOptionDetails(OptionDetails, SettingID, ContextParameters) Export
	
	OptionDetails.PathToRulesSetFileOnUserSite = "https://users.v8.1c.ru/distribution/project/EnterpriseERP20";
	OptionDetails.PathToRulesSetFileInTemplateDirectory       = "\1c\enterprise";
	OptionDetails.SettingsFileNameForDestination                     = NStr("vi = 'Đồng bộ dữ liệu thông qua định dạng EnterpriseData';
																			|ru = 'Синхронизация данных через формат EnterpriseData';
																			|en = 'Data synchronization via EnterpriseData format'; fa = 'Data synchronization via EnterpriseData format';
																			|it = 'Sincronizzazione dei dati tramite il formato EnterpriseData';
																			|pl = 'Synchronizacja danych przez format EnterpriseData';
																			|tr = 'EnterpriseData formatı aracılığıyla veri senkronizasyonu'");
	OptionDetails.UseDataExchangeCreationWizard        = UseDataExchangeCreationWizard();
	OptionDetails.UsedExchangeMessagesTransports            = UsedExchangeMessagesTransports(SettingID);
	OptionDetails.BriefExchangeInfo                        = BriefExchangeInfo(SettingID);
	OptionDetails.CommonNodeData                                 = CommonNodeData();
	If SettingID = IdOfWorkflowExchangeSettings() Then
		OptionDetails.Insert("NewDataExchangeCreationCommandTitle", NStr("vi = '1C:Document Management CORP, phiên bản 3.0 (EnterpriseData)';
																		|ru = '1С:Документооборот КОРП, редакция 3.0 (EnterpriseData)';
																		|en = '1C:Document Management CORP 3.0 (EnterpriseData)'; fa = '1C:Document Management CORP 3.0 (EnterpriseData)';
																		|it = '1С:Документооборот КОРП, редакция 3.0 (EnterpriseData)';
																		|pl = '1C:Document Management CORP 3.0 (EnterpriseData)';
																		|tr = '1C:Document Management CORP, 3.0 revizyonu (EnterpriseData)'"));
		OptionDetails.Insert("ExchangeCreateWizardTitle",               NStr("vi = 'Tùy chỉnh đồng bộ với chương trình ""1C:Document Management CORP, phiên bản 3.0"" (EnterpriseData)';
																			|ru = 'Настройка синхронизации с программой ""1С:Документооборот КОРП, редакция. 3.0"" (EnterpriseData)';
																			|en = 'Set up synchronization with 1C:Document Management CORP 3.0 application (EnterpriseData)'; fa = 'Set up synchronization with 1C:Document Management CORP 3.0 application (EnterpriseData)';
																			|it = 'Настройка синхронизации с программой ""1С:Документооборот КОРП, редакция. 3.0"" (EnterpriseData)';
																			|pl = 'Set up synchronization with 1C:Document Management CORP 3.0 application (EnterpriseData)';
																			|tr = '""1C:Document Management CORP, 3.0 revizyonu"" ile senkronizasyon ayarı (EnterpriseData)'"));
		OptionDetails.Insert("ExchangePlanNodeTitle",                       NStr("vi = 'Đồng bộ với chương trình ""1C:Document Management CORP, phiên bản 3.0""';
																				|ru = 'Синхронизация с программой ""1С:Документооборот КОРП, редакция 3.0""';
																				|en = 'Synchronization with 1C:Document Management CORP 3.0 application'; fa = 'Synchronization with 1C:Document Management CORP 3.0 application';
																				|it = 'Синхронизация с программой ""1С:Документооборот КОРП, редакция 3.0""';
																				|pl = 'Synchronization with 1C:Document Management CORP 3.0 application';
																				|tr = '""1C:Document Management CORP, 3.0 revizyonu"" ile senkronizasyon'"));
		OptionDetails.Insert("CorrespondentConfigurationDescription",         NStr("vi = '1C:Document Management CORP, phiên bản 3.0';
																					|ru = '1С:Документооборот КОРП, редакция 3.0';
																					|en = '1C:Document Management CORP 3.0'; fa = '1C:Document Management CORP 3.0';
																					|it = '1С:Документооборот КОРП, редакция 3.0';
																					|pl = '1C:Document Management CORP 3.0';
																					|tr = '1C:Document Management CORP, 3.0 revizyonu'"));
		OptionDetails.Insert("CorrespondentConfigurationName",                  "DocumentManagementCORP");
		
	ElsIf SettingID = "UpbpExchange" 
		Or SettingID = IdOfExchangeSetupBP30()
		Or SettingID = IdOfBasicUTBP30ExchangeSetup()
		Then
		
		OptionDetails.Insert("NewDataExchangeCreationCommandTitle", NStr("vi = 'Kế toán doanh nghiệp, phiên bản 3.0 (EnterpriseData)';
																		|ru = 'Бухгалтерия предприятия, редакция 3.0 (EnterpriseData)';
																		|en = '1C:Enterprise Accounting 3.0 (EnterpriseData)'; fa = '1C:Enterprise Accounting 3.0 (EnterpriseData)';
																		|it = 'Contabilità di impresa, versione 3.0 (EnterpriseData)';
																		|pl = '1C:Enterprise Accounting 3.0 (EnterpriseData)';
																		|tr = 'İşletme muhasebesi, revizyon 3.0 (EnterpriseData)'"));
		OptionDetails.Insert("ExchangeCreateWizardTitle",               NStr("vi = 'Tùy chỉnh đồng bộ với chương trình ""Kế toán doanh nghiệp, phiên bản 3.0"" (EnterpriseData)';
																			|ru = 'Настройка синхронизации с программой ""Бухгалтерия предприятия, редакция. 3.0"" (EnterpriseData)';
																			|en = 'Set up synchronization with 1C:Enterprise Accounting 3.0 application (EnterpriseData)'; fa = 'Set up synchronization with 1C:Enterprise Accounting 3.0 application (EnterpriseData)';
																			|it = 'Impostazione di sincronizzazione con il programma ""Contabilità di impresa, versione. 3.0 (EnterpriseData)';
																			|pl = 'Ustawienie synchronizacji z programem ""1C:Enterprise Accounting 3.0"" (EnterpriseData)';
																			|tr = '""İşletme muhasebesi, revizyon 3.0"" programı ile senkronizasyonun ayarlanması. (EnterpriseData)'"));
		OptionDetails.Insert("ExchangePlanNodeTitle",                       NStr("vi = 'Đồng bộ với chương trình ""Kế toán doanh nghiệp, phiên bản 3.0""';
																				|ru = 'Синхронизация с программой ""Бухгалтерия предприятия, редакция 3.0""';
																				|en = 'Synchronization with 1C:Enterprise Accounting 3.0 application'; fa = 'Synchronization with 1C:Enterprise Accounting 3.0 application';
																				|it = 'Sincronizzazione con il programma ""1C:Enterprise Accounting 3.0""';
																				|pl = 'Synchronizacja z programem ""1C:Enterprise Accounting 3.0""';
																				|tr = '""İşletme muhasebesi, revizyon 3.0"" yazılımı ile senkronizasyon'"));
		OptionDetails.Insert("CorrespondentConfigurationDescription",         NStr("vi = 'Kế toán doanh nghiệp, phiên bản 3.0';
																					|ru = 'Бухгалтерия предприятия, редакция 3.0';
																					|en = '1C:Enterprise Accounting 3.0'; fa = '1C:Enterprise Accounting 3.0';
																					|it = '1C:Enterprise Accounting 3.0';
																					|pl = '1C:Enterprise Accounting 3.0';
																					|tr = 'İşletme muhasebesi, revizyon 3.0'"));
		OptionDetails.Insert("CorrespondentConfigurationName",                  "EnterpriseAccounting");
		
	ElsIf SettingID = IdOfExchangeSetupBPCORP30() Then
		
		OptionDetails.Insert("NewDataExchangeCreationCommandTitle", NStr("vi = 'Kế toán doanh nghiệp CORP, phiên bản 3.0 (EnterpriseData)';
																		|ru = 'Бухгалтерия предприятия КОРП, редакция 3.0 (EnterpriseData)';
																		|en = '1C:Enterprise Accounting CORP 3.0 (EnterpriseData)'; fa = '1C:Enterprise Accounting CORP 3.0 (EnterpriseData)';
																		|it = 'Contabilità di impresa CORP, versione 3.0 (EnterpriseData)';
																		|pl = '1C:Enterprise Accounting CORP 3.0 (EnterpriseData)';
																		|tr = 'CORP işletme muhasebesi, revizyon 3.0 (EnterpriseData)'"));
		OptionDetails.Insert("ExchangeCreateWizardTitle",               NStr("vi = 'Tùy chỉnh đồng bộ với chương trình ""Kế toán doanh nghiệp CORP, phiên bản 3.0"" (EnterpriseData)';
																			|ru = 'Настройка синхронизации с программой ""Бухгалтерия предприятия КОРП, редакция. 3.0"" (EnterpriseData)';
																			|en = 'Set up synchronization with 1C:Enterprise Accounting CORP 3.0 application (EnterpriseData)'; fa = 'Set up synchronization with 1C:Enterprise Accounting CORP 3.0 application (EnterpriseData)';
																			|it = 'Impostazione di sincronizzazione con il programma ""Contabilità di impresa CORP, versione. 3.0 (EnterpriseData)';
																			|pl = 'Ustawienie synchronizacji z programem ""1C:Enterprise Accounting 3.0 CORP, edycja. 3.0"" (EnterpriseData)';
																			|tr = '""CORP işletme muhasebesi, revizyon 3.0"" programı ile senkronizasyonun ayarlanması (EnterpriseData)'"));
		OptionDetails.Insert("ExchangePlanNodeTitle",                       NStr("vi = 'Đồng bộ với chương trình ""Kế toán doanh nghiệp CORP, phiên bản 3.0""';
																				|ru = 'Синхронизация с программой ""Бухгалтерия предприятия КОРП, редакция 3.0""';
																				|en = 'Synchronization with 1C:Enterprise Accounting CORP 3.0 application'; fa = 'Synchronization with 1C:Enterprise Accounting CORP 3.0 application';
																				|it = 'Sincronizzazione con il programma ""1C:Enterprise Accounting CORP 3.0""';
																				|pl = 'Synchronizacja z programem ""1C:Enterprise Accounting CORP 3.0""';
																				|tr = '""CORP işletme muhasebesi, revizyon 3.0"" programı ile senkronizasyon'"));
		OptionDetails.Insert("CorrespondentConfigurationDescription",         NStr("vi = 'Kế toán doanh nghiệp CORP, phiên bản 3.0';
																					|ru = 'Бухгалтерия предприятия КОРП, редакция 3.0';
																					|en = '1C:Enterprise Accounting CORP 3.0'; fa = '1C:Enterprise Accounting CORP 3.0';
																					|it = '1C:Enterprise Accounting CORP 3.0';
																					|pl = '1C:Enterprise Accounting CORP 3.0';
																					|tr = 'CORP işletme muhasebesi, revizyon 3.0'"));
		OptionDetails.Insert("CorrespondentConfigurationName",                  "EnterpriseAccounting");
		
	ElsIf SettingID = "ExchangeUP2ZUP3" Then
		
		OptionDetails.Insert("NewDataExchangeCreationCommandTitle", NStr("vi = 'HRM & PAYROLL, phiên bản 3 (EnterpriseData)';
																		|ru = 'Зарплата и Управление Персоналом, редакция 3 (EnterpriseData)';
																		|en = '1C:HRM 3 (EnterpriseData)'; fa = '1C:HRM 3 (EnterpriseData)';
																		|it = 'Retribuzione e Gestione del Personale, versione 3 (EnterpriseData)';
																		|pl = 'Wynagrodzenie i Zarządzanie Kadrami, edycja 3 (EnterpriseData)';
																		|tr = 'Maaş ve Personel Yönetimi, revizyon 3 (EnterpriseData)'"));
		OptionDetails.Insert("ExchangeCreateWizardTitle",               NStr("vi = 'Tùy chỉnh đồng bộ với chương trình ""HRM & Payroll, phiên bản 3"" (EnterpriseData)';
																			|ru = 'Настройка синхронизации с программой ""Зарплата и Управление Персоналом, редакция 3"" (EnterpriseData)';
																			|en = 'Set up synchronization with 1C:HRM 3 application (EnterpriseData)'; fa = 'Set up synchronization with 1C:HRM 3 application (EnterpriseData)';
																			|it = 'Impostazione di sincronizzazione con il programma ""Retribuzione e Gestione del Personale, versione 3"" (EnterpriseData)';
																			|pl = 'Ustawienie synchronizacji z programem ""Wynagrodzenie i Zarządzanie Kadrami, edycja 3"" (EnterpriseData)';
																			|tr = '""Maaş ve Personel Yönetimi, revizyon 3"" yazılımı (EnterpriseData) ile senkronizasyonun ayarlanması'"));
		OptionDetails.Insert("ExchangePlanNodeTitle",                       NStr("vi = 'Đồng bộ với chương trình ""HRM & Payroll, phiên bản 3""';
																				|ru = 'Синхронизация с программой ""Зарплата и Управление Персоналом, редакция 3""';
																				|en = 'Synchronization with 1C:HRM 3 application'; fa = 'Synchronization with 1C:HRM 3 application';
																				|it = 'Sincronizzazione con il programma ""Retribuzione e Gestione del Personale, versione 3""';
																				|pl = 'Synchronizacja z programem ""Wynagrodzenie i Zarządzanie Kadrami, edycja 3""';
																				|tr = '""Maaş ve Personel Yönetimi, revizyon 3"" yazılımı ile senkronizasyon'"));
		OptionDetails.Insert("CorrespondentConfigurationDescription",         NStr("vi = 'HRM & Payroll, phiên bản 3';
																					|ru = 'Зарплата и Управление Персоналом, редакция 3';
																					|en = '1C:HRM 3'; fa = '1C:HRM 3';
																					|it = 'Retribuzione e Gestione del Personale, versione 3';
																					|pl = 'Wynagrodzenie i Zarządzanie Kadrami, edycja 3';
																					|tr = 'Maaş ve Personel Yönetimi, revizyon 3'"));
		OptionDetails.Insert("CorrespondentConfigurationName",                 "SalaryAndPersonnelManagement");
		
	ElsIf SettingID = "UpuppExchange" Then
		OptionDetails.Insert("NewDataExchangeCreationCommandTitle", NStr("vi = 'Quản lý doanh nghiệp sản xuất, phiên bản 1.3 (EnterpriseData)';
																		|ru = 'Управление производственным предприятием, редакция 1.3 (EnterpriseData)';
																		|en = '1C:Manufacturing Enterprise Management 1.3 (EnterpriseData)'; fa = '1C:Manufacturing Enterprise Management 1.3 (EnterpriseData)';
																		|it = 'Gestione dell''impresa di produzione, versione 1.3 (EnterpriseData)';
																		|pl = 'Zarządzanie przedsiębiorstwem produkcyjnym, edycja 1.3 (EnterpriseData)';
																		|tr = 'Üretim işletmesi yönetimi, revizyon 1.3 (EnterpriseData)'"));
		OptionDetails.Insert("ExchangeCreateWizardTitle",               NStr("vi = 'Tùy chỉnh đồng bộ với chương trình ""Quản lý doanh nghiệp sản xuất 1.3"" (EnterpriseData)';
																			|ru = 'Настройка синхронизации с программой ""Управление производственным предприятием, редакция. 1.3"" (EnterpriseData)';
																			|en = 'Set up synchronization with 1C:Manufacturing Enterprise Management 1.3 application (EnterpriseData)'; fa = 'Set up synchronization with 1C:Manufacturing Enterprise Management 1.3 application (EnterpriseData)';
																			|it = 'Impostazione di sincronizzazione con il programma ""Gestione dell''impresa di produzione, versione. 1.3"" (EnterpriseData)';
																			|pl = 'Ustawienie synchronizacji z programem ""Zarządzanie przedsiębiorstwem produkcyjnym, edycja. 1.3"" (EnterpriseData)';
																			|tr = '""Üretim işletmesi yönetimi, revizyon 1.3,"" yazılımı ile senkronizasyonun ayarlanması. 1.3"" (EnterpriseData)'"));
		OptionDetails.Insert("ExchangePlanNodeTitle",                       NStr("vi = 'Đồng bộ với chương trình ""Quản lý doanh nghiệp sản xuất, phiên bản 1.3""';
																				|ru = 'Синхронизация с программой ""Управление производственным предприятием, редакция 1.3""';
																				|en = 'Synchronization with 1C:Manufacturing Enterprise Management 1.3 application'; fa = 'Synchronization with 1C:Manufacturing Enterprise Management 1.3 application';
																				|it = 'Sincronizzazione con il programma ""Gestione imprese produttive, versione 1.3""';
																				|pl = 'Synchronizacja z programem ""Zarządzanie przedsiębiorstwem produkcyjnym, edycja 1.3""';
																				|tr = '""Üretim işletmesi yönetimi, revizyon 1.3"" yazılımı ile senkronizasyon'"));
		OptionDetails.Insert("CorrespondentConfigurationDescription",         NStr("vi = 'Quản lý doanh nghiệp sản xuất, phiên bản 1.3';
																					|ru = 'Управление производственным предприятием, редакция 1.3';
																					|en = '1C:Manufacturing Enterprise Management 1.3'; fa = '1C:Manufacturing Enterprise Management 1.3';
																					|it = 'Gestione imprese produttive, versione 1.3';
																					|pl = 'Zarządzanie przedsiębiorstwem produkcyjnym, edycja 1.3';
																					|tr = 'Üretim işletmesi yönetimi, revizyon 1.3'"));
		OptionDetails.Insert("CorrespondentConfigurationName",                  "ManagementOfManufacturingEnterprise");
		
	ElsIf SettingID = "CashExchange" Then
		OptionDetails.Insert("NewDataExchangeCreationCommandTitle", NStr("vi = '1C:Quầy thu ngân (EnterpriseData)';
																		|ru = '1С:Касса (EnterpriseData)';
																		|en = '1C:Checkout (EnterpriseData)'; fa = '1C:Checkout (EnterpriseData)';
																		|it = '1C:Checkout (EnterpriseData)';
																		|pl = '1C:Checkout (EnterpriseData)';
																		|tr = '1C:Checkout (EnterpriseData)'"));
		OptionDetails.Insert("ExchangeCreateWizardTitle",               NStr("vi = 'Tùy chỉnh đồng bộ với chương trình ""1C:Quầy thu ngân"" (EnterpriseData)';
																			|ru = 'Настройка синхронизации с программой ""1С:Касса"" (EnterpriseData)';
																			|en = 'Set up synchronization with 1C:Checkout application (EnterpriseData)'; fa = 'Set up synchronization with 1C:Checkout application (EnterpriseData)';
																			|it = 'Impostazione di sincronizzazione con il programma ""1C:Checkout"" (EnterpriseData)';
																			|pl = 'Ustawienie synchronizacji z programem ""1C:Checkout"" (EnterpriseData)';
																			|tr = '""1C:Checkout"" (EnterpriseData) yazılımı ile senkronizasyonun ayarlanması'"));
		OptionDetails.Insert("ExchangePlanNodeTitle",                       NStr("vi = 'Đồng bộ với chương trình ""1C:Kassa""';
																				|ru = 'Синхронизация с программой ""1С:Касса""';
																				|en = 'Synchronization with 1C:Checkout application'; fa = 'Synchronization with 1C:Checkout application';
																				|it = 'Sincronizzazione con il programma ""1C:Checkout""';
																				|pl = 'Synchronizacja z programem ""1C:Checkout""';
																				|tr = '""1C:Checkout"" yazılımı ile senkronizasyon'"));
		OptionDetails.Insert("CorrespondentConfigurationDescription",         NStr("vi = '1C:Kassa';
																					|ru = '1С:Касса';
																					|en = '1C:Checkout'; fa = '1C:Checkout';
																					|it = '1C:Checkout';
																					|pl = '1C:Checkout';
																					|tr = '1C:Checkout'"));
		OptionDetails.Insert("CorrespondentConfigurationName",                  "CashAccount");	
		
	ElsIf SettingID = "ExchangeOfUPRMC" Then
		
		DescriptionOfConfigurationOptionExchangeUPRMC(OptionDetails);
		
	ElsIf SettingID = "UniversalExchange" Then
		
		OptionDetails.Insert("NewDataExchangeCreationCommandTitle", NStr("vi = 'Chương trình khác (EnterpriseData)';
																		|ru = 'Другая программа (EnterpriseData)';
																		|en = 'Another application (EnterpriseData)'; fa = 'Another application (EnterpriseData)';
																		|it = 'Altro programma (EnterpriseData)';
																		|pl = 'Inny program (EnterpriseData)';
																		|tr = 'Diğer yazılım (EnterpriseData)'"));
		OptionDetails.Insert("ExchangeCreateWizardTitle",               NStr("vi = 'Tùy chỉnh đồng bộ dữ liệu thông qua định dạng EnterpriseData';
																			|ru = 'Настройка синхронизации данных через формат EnterpriseData';
																			|en = 'Data synchronization setup via EnterpriseData format'; fa = 'Data synchronization setup via EnterpriseData format';
																			|it = 'Impostazione di sincronizzazione dati tramite formato EnterpriseData';
																			|pl = 'Ustawienie synchronizacji danych przez format EnterpriseData';
																			|tr = 'EnterpriseData formatı aracılığıyla veri senkronizasyonunun ayarlanması'"));
		OptionDetails.Insert("ExchangePlanNodeTitle",                       NStr("vi = 'Đồng bộ dữ liệu thông qua định dạng EnterpriseData';
																				|ru = 'Синхронизация данных через формат EnterpriseData';
																				|en = 'Data synchronization via EnterpriseData format'; fa = 'Data synchronization via EnterpriseData format';
																				|it = 'Sincronizzazione dei dati tramite il formato EnterpriseData';
																				|pl = 'Synchronizacja danych przez format EnterpriseData';
																				|tr = 'EnterpriseData formatı aracılığıyla veri senkronizasyonu'"));
		OptionDetails.Insert("CorrespondentConfigurationDescription",         NStr("vi = 'Chương trình khác';
																					|ru = 'Другая программа';
																					|en = 'Another application'; fa = 'Another application';
																					|it = 'Altro programma';
																					|pl = 'Inny program';
																					|tr = 'Diğer yazılım'"));
		OptionDetails.Insert("CorrespondentConfigurationName",                  "OtherProgram");
		
	Else
		
		OptionDetails.Insert("CorrespondentConfigurationDescription",         NStr("vi = 'Thông qua định dạng trao đổi EnterpriseData';
																					|ru = 'Через формат обмена EnterpriseData';
																					|en = 'Via EnterpriseData exchange format'; fa = 'Via EnterpriseData exchange format';
																					|it = 'Tramite il formato di scambio EnterpriseData';
																					|pl = 'Przez format wymiany EnterpriseData';
																					|tr = 'EnterpriseData değişim formatı aracılığıyla'"));
		
	EndIf;
	
EndProcedure

Procedure TransitionFromTradeManagement() Export
	
	ExchangePlanNodes = ExchangePlans.DataSynchronizationViaUniversalFormat.Select();
	
	While ExchangePlanNodes.Next() Do
		
		If StrFind(ExchangePlanNodes.SettingsMode, "BPExchange") > 0 
			Or ExchangePlanNodes.SettingsMode= "UT_BP3Exchange" Then
			AnotherNode = ExchangePlanNodes.GetObject();
			AnotherNode.SettingsMode = IdOfExchangeSetupBP30();

			AnotherNode.Write();
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region OtherProceduresAndFunctions_

// Generates and returns a list of rules for unloading the contract according to the data of settlement objects.
//
// Returns: 
// 	ValueList of String
//
Function ListOfContractFormationRules() Export
	
	RulesList = New ValueList;
	RulesList.Add("WithoutSeparation", NStr("vi = 'Hợp đồng đối tác được lập thông qua liên kết với thỏa thuận hoặc đơn hàng';
											|ru = 'Договоры контрагентов формируются без привязки к соглашениям или заказам';
											|en = 'Counterparty contracts are created without linking to agreements or orders'; fa = 'Counterparty contracts are created without linking to agreements or orders';
											|it = 'I contratti delle controparti si creano senza collegamenti ad accordi o ordini';
											|pl = 'Kontrakty kontrahentów są tworzone bez powiązania do umów lub zamówień';
											|tr = 'Cari hesapların sözleşmeleri, anlaşmalara veya siparişlere bağlı olmaksızın oluşturulur'"));
	
	If (GetFunctionalOption("UseSalesOrders")
		Or GetFunctionalOption("UsePurchaseOrders"))
		And Not (GetFunctionalOption("UseReceiptForMultipleOrders")
			And GetFunctionalOption("UseSaleByMultipleOrders")
			And GetFunctionalOption("UseCustomerInvoicesForSeveralOrders")) Then
		
		RulesList.Add("ByOrders", NStr("vi = 'Các đơn hàng khác nhau tương ứng với các hợp đồng khác nhau của đối tác';
										|ru = 'Разным заказам соответствуют разные договоры контрагентов';
										|en = 'Different orders correspond to different counterparty contracts'; fa = 'Different orders correspond to different counterparty contracts';
										|it = 'A diversi ordini corrispondono diversi ordini delle controparti';
										|pl = 'Różnym zamówieniom odpowiadają różne kontrakty kontrahentów';
										|tr = 'Farklı siparişler farklı cari hesap sözleşmelerine uygun gelir'"));
		
	EndIf;
	
	If Constants.UseTermsOfSales.Get() <> Enums.UseTermsOfSales.DontUse Then
		RulesList.Add("ByAgreements", NStr("vi = 'Các thỏa thuận khác nhau tương ứng với các hợp đồng khác nhau của đối tác';
											|ru = 'Разным соглашениям соответствуют разные договоры контрагентов';
											|en = 'Different agreements correspond to different counterparty contracts'; fa = 'Different agreements correspond to different counterparty contracts';
											|it = 'A diversi accordi corrispondono diversi contratti delle controparti';
											|pl = 'Różnym umowom odpowiadają różne kontrakty kontrahentów';
											|tr = 'Farklı anlaşmalar farklı cari hesap sözleşmelerine uygun gelir'"));
	EndIf;
	
	If GetFunctionalOption("UseSalesOpportunitiesToCustomer") Then
		RulesList.Add("ByTransactions", NStr("vi = 'Các vụ việc khác nhau tương ứng với các hợp đồng khác nhau của đối tác';
											|ru = 'Разным сделкам соответствуют разные договоры контрагентов';
											|en = 'Different sales opportunities correspond to different counterparty contracts'; fa = 'Different sales opportunities correspond to different counterparty contracts';
											|it = 'A diverse transazioni corrispondono diversi contratti delle controparti';
											|pl = 'Różnym transakcjom odpowiadają różne kontrakty kontrahentów';
											|tr = 'Farklı cari hesap sözleşmeleri farklı işlemlere uygun gelir'"));
	EndIf;
	
	Return RulesList;
	
EndFunction

// Fills in the dependent details of the exchange plan node when writing
//
// Parameters:
//  ExchangePlanNode - ExchangePlanObject - the node of the exchange plan that needs to be filled in.
//
Procedure UpdatingDetailsOfExchangePlanNode(ExchangePlanNode) Export
	
	SettingsMode                   = ExchangePlanNode.SettingsMode;
	CatalogsSendingRules        = ExchangePlanNode.CatalogsSendingRules;
	DocumentsSendingRules          = ExchangePlanNode.DocumentsSendingRules;
	NumberOfSelectedOrganizations     = ExchangePlanNode.Companies.Count();
	UseFilterByCompanies    = ExchangePlanNode.UseFilterByCompanies;
	NumberOfSelectedPriceTypes        = ExchangePlanNode.ProductPricesTypes.Count();
	UploadProductPrices          = ExchangePlanNode.UploadProductPrices;
	UseFilterByAccountingSections   = ExchangePlanNode.UseFilterByAccountingSectionAndDocument;
	UseFilterByWarehouses         = ExchangePlanNode.UseFilterByWarehouses;
	NumberOfSelectedWarehouses         = ExchangePlanNode.Warehouses.Count();
	UseProductSelection    = ExchangePlanNode.UseProductSelection;
	NumberOfSelectionsByProductType    = ExchangePlanNode.ItemFilters.Count();
	UseCourierSelection        = ExchangePlanNode.UseCourierSelection;
	NumberOfSelectedCouriers        = ExchangePlanNode.Couriers.Count();
	UseFilterByPersons = ExchangePlanNode.UseFilterByPersons;
	NumberOfSelectedIndividuals   = ExchangePlanNode.Persons.Count();
	UseFilterByCashRegisters       = ExchangePlanNode.UseFilterByCashRegisters;
	NumberOfSelectedCashRegisterRegisters         = ExchangePlanNode.CashRegisters.Count();
	UseETSelection              = ExchangePlanNode.UseFilterByPOSTerminals;
	NumberOfSelectedET              = ExchangePlanNode.POSTerminals.Count();
	
	If GetFunctionalOption("TradeManagement")
		And (SettingsMode = IdOfExchangeSetupBP30()
		Or SettingsMode = IdOfExchangeSetupBPCORP30()
		Or SettingsMode = IdOfBasicUTBP30ExchangeSetup()
		Or SettingsMode = IdOfExchangeSettingsIsUniversal()) Then
		
		TMDataExchange.UpdateAttributeForUsingExchangeWithAccounting(ExchangePlanNode, ExchangePlanNode.DeletionMark);
		
	EndIf;
	
	// Cleaning of unused details and filling out of office
	If CatalogsSendingRules = "NotSynchronize" Then
		
		ExchangePlanNode.UseFilterByCompanies = False;
		ExchangePlanNode.UploadProductPrices       = False;
		ExchangePlanNode.UploadAnalyticsByWarehouse     = False;
		ExchangePlanNode.UseProductSelection = False;
		ExchangePlanNode.UploadInformativePrices      = False;
		ExchangePlanNode.UploadMarkingData       = False;
		ExchangePlanNode.CatalogsExportMode       = Enums.ExchangeObjectExportModes.DoNotExport;
		ExchangePlanNode.ExportModeOnDemand   = Enums.ExchangeObjectExportModes.DoNotExport;
		
	Else
		
		ExchangePlanNode.ExportModeOnDemand = Enums.ExchangeObjectExportModes.ExportIfNecessary;
		
		If CatalogsSendingRules = "SynchronizeAsNeeded" Then
			ExchangePlanNode.UseProductSelection = False;
			ExchangePlanNode.UploadInformativePrices      = False;
			ExchangePlanNode.CatalogsExportMode = Enums.ExchangeObjectExportModes.ExportIfNecessary;
		Else
			ExchangePlanNode.CatalogsExportMode = Enums.ExchangeObjectExportModes.ExportByCondition;
		EndIf;
		
	EndIf;
	
	If DocumentsSendingRules = "NotSynchronize" Then
		ExchangePlanNode.DocumentsExportMode = Enums.ExchangeObjectExportModes.DoNotExport;
	ElsIf DocumentsSendingRules = "InteractiveSynchronization" Then
		ExchangePlanNode.DocumentsExportMode = Enums.ExchangeObjectExportModes.ManualExport;
	Else
		ExchangePlanNode.DocumentsExportMode = Enums.ExchangeObjectExportModes.ExportByCondition;
	EndIf;
	
	If Not UseFilterByCompanies And NumberOfSelectedOrganizations <> 0 Then
		ExchangePlanNode.Companies.Clear();
	ElsIf NumberOfSelectedOrganizations = 0 And UseFilterByCompanies Then
		ExchangePlanNode.UseFilterByCompanies = False;
	EndIf;
	
	If Not UploadProductPrices And NumberOfSelectedPriceTypes <> 0 Then
		ExchangePlanNode.ProductPricesTypes.Clear();
	ElsIf UploadProductPrices Then
		If Not GetFunctionalOption("UseSeveralPriceTypes") Then
			PriceTypePriceList_ = PriceManagementSystem.PriceTypePriceList_();
			
			ExchangePlanNode.ProductPricesTypes.Clear();
			DifferentTypesOfPrices = ExchangePlanNode.ProductPricesTypes.Add();
			DifferentTypesOfPrices.ProductPricesType = PriceTypePriceList_;
		ElsIf NumberOfSelectedPriceTypes = 0 And Not SettingsMode = "CashExchange" Then
			ExchangePlanNode.UploadProductPrices = False;
		EndIf;
	EndIf;
	
	If Not UseProductSelection And NumberOfSelectionsByProductType <> 0 Then
		ExchangePlanNode.ItemFilters.Clear();
	ElsIf NumberOfSelectionsByProductType = 0 And UseProductSelection Then
		ExchangePlanNode.UseProductSelection = False;
	EndIf;
	
	If Not UseCourierSelection And NumberOfSelectedCouriers <> 0 Then
		ExchangePlanNode.Couriers.Clear();
	ElsIf NumberOfSelectedCouriers = 0 And UseCourierSelection Then
		ExchangePlanNode.UseCourierSelection = False;
	EndIf;

	If Not UseFilterByWarehouses And NumberOfSelectedWarehouses <> 0 Then
		ExchangePlanNode.Warehouses.Clear();
	ElsIf NumberOfSelectedWarehouses = 0 And UseFilterByWarehouses Then
		ExchangePlanNode.UseFilterByWarehouses = False;
	EndIf;
	
	If Not UseFilterByPersons And NumberOfSelectedIndividuals <> 0 Then
		ExchangePlanNode.Persons.Clear();
	ElsIf NumberOfSelectedIndividuals = 0 And UseFilterByPersons Then
		ExchangePlanNode.UseFilterByPersons = False;
	EndIf;
	
	If Not UseFilterByCashRegisters And NumberOfSelectedCashRegisterRegisters <> 0 Then
		ExchangePlanNode.CashRegisters.Clear();
	ElsIf NumberOfSelectedCashRegisterRegisters = 0 And UseFilterByCashRegisters Then
		ExchangePlanNode.UseFilterByCashRegisters = False;
	EndIf;
	
	If SettingsMode = "ExchangeOfUPRMC" And UseFilterByCashRegisters And NumberOfSelectedCashRegisterRegisters <> 0 Then
		
		UpdateDependentSelections(ExchangePlanNode);
		
	EndIf;
	
	If Not UseETSelection And NumberOfSelectedET <> 0 Then
		ExchangePlanNode.POSTerminals.Clear();
	ElsIf NumberOfSelectedET = 0 And UseETSelection Then
		ExchangePlanNode.UseFilterByPOSTerminals = False;
	EndIf;
	
	If Not ValueIsFilled(ExchangePlanNode.ManagementCompany) Then
		ExchangePlanNode.ManagementCompany = Catalogs.Companies.ManagementCompany;
	EndIf;
	
	If DocumentsSendingRules <> "AutoSynchronization" Then
		ExchangePlanNode.DocumentsExportStartDate = Date(1,1,1,0,0,0);
	EndIf;
	
	If Not ValueIsFilled(ExchangePlanNode.ExchangeFormatVersion) Then
		ExchangePlanNode.ExchangeFormatVersion = "1.8";
	EndIf;
	
	If (UseFilterByAccountingSections 
		And ExchangePlanNode.AccountingSections.FindRows(New Structure("ToExport", True)).Count() = 0)
		Or ExchangePlanNode.DocumentsExportMode = Enums.ExchangeObjectExportModes.DoNotExport Then
		
		ExchangePlanNode.UseFilterByAccountingSections = False;
		
	EndIf;
	
	If Not ExchangePlanNode.UseFilterByAccountingSections Then
		
		ExchangePlanNode.AccountingSections.Clear();
		
		AccountingSections = GetAccountingSections(False, SettingsMode);
		ExchangePlanNode.AccountingSections.Load(AccountingSections);
		
	EndIf;
	
EndProcedure

// Fills in the description of the configuration option for the exchange with the identifier "Exchange"
// 
// Parameters:
//  OptionDetails - See DataExchangeServer.DefaultExchangeSettingOptionDetails
Procedure DescriptionOfConfigurationOptionExchangeUPRMC(OptionDetails) Export
	
	OptionDetails.Insert("NewDataExchangeCreationCommandTitle", NStr("vi = '1C:Cashier''s workplace (EnterpriseData)';
																	|ru = '1С:Рабочее место кассира (EnterpriseData)';
																	|en = '1C:POS (EnterpriseData)'; fa = '1C:POS (EnterpriseData)';
																	|it = '1C:Posto di lavoro del cassiere (EnterpriseData)';
																	|pl = '1C:POS (EnterpriseData)';
																	|tr = '1C:POS (EnterpriseData)'"));
	OptionDetails.Insert("ExchangeCreateWizardTitle",               NStr("vi = 'Tùy chỉnh đồng bộ với chương trình ""1C:Cashier''s workplace"" (EnterpriseData)';
																		|ru = 'Настройка синхронизации с программой ""1С:Рабочее место кассира"" (EnterpriseData)';
																		|en = 'Configure synchronization with 1C:POS application (EnterpriseData)'; fa = 'Configure synchronization with 1C:POS application (EnterpriseData)';
																		|it = 'Impostazione di sincronizzazione con il programma ""1C:Posto di lavoro del cassiere"" (EnterpriseData)';
																		|pl = 'Ustawienie synchronizacji z programem ""1C:POS"" (EnterpriseData)';
																		|tr = '1C:POS (EnterpriseData) yazılımı ile senkronizasyon ayarları'"));
	OptionDetails.Insert("ExchangePlanNodeTitle",                       NStr("vi = 'Đồng bộ với chương trình ""1C:Cashier''s workplace""';
																			|ru = 'Синхронизация с программой ""1С:Рабочее место кассира""';
																			|en = 'Synchronize with 1C:POS application'; fa = 'Synchronize with 1C:POS application';
																			|it = 'Sincronizzazione con il programma ""1C:Posto di lavoro del cassiere""';
																			|pl = 'Synchronizacja z programem ""1C:POS""';
																			|tr = '""1C:POS"" yazılımı ile senkronizasyon'"));
	OptionDetails.Insert("CorrespondentConfigurationDescription",         NStr("vi = '1C:Cashier''s workplace';
																				|ru = '1С:Рабочее место кассира';
																				|en = '1C:POS'; fa = '1C:POS';
																				|it = '1C:Posto di lavoro del cassiere';
																				|pl = '1C:POS';
																				|tr = '1C:POS'"));
	OptionDetails.Insert("CorrespondentConfigurationName",                  "CashierWorkplace");
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region SelectionBySectionsTypesOfDocuments

Procedure FillInSectionOnDocuments(DocumentsKinds, AccountingSection, SectionStructure) 
	MetaDocuments = Metadata.Documents;
	For Each ArrayElement In SectionStructure Do
		If Not MetaDocuments.Find(ArrayElement) = Undefined Then
			NewString = DocumentsKinds.Add(); 
			NewString.MetadataObjectName = MetaDocuments[ArrayElement].Name; 
			NewString.Presentation = ?(Not IsBlankString(MetaDocuments[ArrayElement].ObjectPresentation), MetaDocuments[ArrayElement].ObjectPresentation, String(MetaDocuments[ArrayElement]));
			NewString.AccountingSection = AccountingSection; 
		EndIf; 
	EndDo;
EndProcedure

// Initial filling of sections and types of documents that they contain.
//
// Parameters:
//   ObjectNode - ExchangePlanObject - the exchange plan for which the filling is performed.
//   ArrayOfSectionsOfExchangePlan - Array of String - names of sections for which filling is performed.
//
Procedure FillInTypesOfDocumentsForAccountingSections(ObjectNode, ArrayOfSectionsOfExchangePlan) Export
	
	SectionsArray = New Array;
	SectionsArray.Add("Return leftovers");
	SectionsArray.Add("NonCurrent assets_1");
	SectionsArray.Add("Purchases");
	SectionsArray.Add("Salary");
	SectionsArray.Add("TreasuryAndARAPAccounting");
	SectionsArray.Add("Sales");
	SectionsArray.Add("Production");
	SectionsArray.Add("Warehouse");
	
	ArrayInputOfBalances  = New Array;
	ArrayInputOfBalances.Add("OBEntry");
	ArrayInputOfBalances.Add("OBEntryARAP");
	ArrayInputOfBalances.Add("OBEntryCash");
	ArrayInputOfBalances.Add("OBEntryFinancialInstruments");
	ArrayInputOfBalances.Add("OBEntryARAPAdvanceHolders"); 
	ArrayInputOfBalances.Add("OBEntryGoods");
	
	ArrayOfNonCurrentAssets  = New Array;
	ArrayOfNonCurrentAssets.Add("EntryOfCapitalAssetsBalance2_4");
	ArrayOfNonCurrentAssets.Add("EntryOfCapitalAssetsBalance"); 
	
	PurchaseArray = New Array;
	PurchaseArray.Add("ReturnOfGoodsToVendor");
	PurchaseArray.Add("PurchaseOrder");
	PurchaseArray.Add("PurchaseAdjustment");
	PurchaseArray.Add("ConsignmentReportToVendor");
	PurchaseArray.Add("VendorInvoice");
	PurchaseArray.Add("VendorInvoiceServicesAndAssets");
	PurchaseArray.Add("VendorInvoiceReceived");
	PurchaseArray.Add("ReceivedTaxInvoicePrepayment");
	PurchaseArray.Add("InvoiceReceivedByTaxAgent");
	PurchaseArray.Add("CCDImport"); 
	PurchaseArray.Add("NotificationOfImportOfTraceableGoods");
	PurchaseArray.Add("NotificationOfBalancesOfTraceableGoods");
	PurchaseArray.Add("NotificationOfMovementOfTraceableGoods");
	
	TreasuryArray  = New Array;
	TreasuryArray.Add("ExpenseReport");
	TreasuryArray.Add("DepositCashIntoCashRegister");
	TreasuryArray.Add("ARAPSettlement");
	TreasuryArray.Add("StatementOfOtherIncomeToBank");
	TreasuryArray.Add("StatementOfOtherIncomeToCashAccount");
	TreasuryArray.Add("StatementOfOtherIncomeByTransfer");
	TreasuryArray.Add("DisposalOfMonetaryDocuments");
	TreasuryArray.Add("CashWithdrawalFromCashRegister");
	TreasuryArray.Add("PaymentRequest");
	TreasuryArray.Add("ARAPAdjustment");
	TreasuryArray.Add("LoanAndDepositInterestCharge");
	TreasuryArray.Add("PaymentCardTransaction");
	TreasuryArray.Add("YandexCheckoutOperation");
	TreasuryArray.Add("BankReportOnAcquiringTransactions");
	TreasuryArray.Add("BankAccountReceiptNote");
	TreasuryArray.Add("ReceiptOfMonetaryDocuments");
	TreasuryArray.Add("CashAccountReceiptNote");
	TreasuryArray.Add("CashVoucher");
	TreasuryArray.Add("BankAccountIssue"); 
	
	SalesArray  = New Array;
	SalesArray.Add("CustomerInvoiceServices");
	SalesArray.Add("GiftCertificateCancellation");
	SalesArray.Add("CustomerInvoiceServices");
	SalesArray.Add("ReturnOfGiftCards");
	SalesArray.Add("ReturnOfGoodsFromCustomer");
	SalesArray.Add("IntercompanyGoodsReturn");
	SalesArray.Add("SalesOrder");
	SalesArray.Add("CashRegisterShift");
	SalesArray.Add("SaleAdjustment");
	SalesArray.Add("ConsignmentReportFromCustomer");
	SalesArray.Add("WriteOffReportFromCommissionAgent");
	SalesArray.Add("CommissionReportIntercompany");
	SalesArray.Add("CommissionWriteOffReportIntercompany");
	SalesArray.Add("ConsignmentReportToVendor");
	SalesArray.Add("PurchaseInvoiceConsignmentStockLost");
	SalesArray.Add("RetailReturnsReport");
	SalesArray.Add("RetailSalesReport");
	SalesArray.Add("TransferOfGoodsToBailee");
	SalesArray.Add("CustomerInvoiceIntercompany");
	SalesArray.Add("GiftCertificateSale");
	SalesArray.Add("CustomerInvoice"); 
	SalesArray.Add("CustomerInvoiceServicesAndAssets");
	SalesArray.Add("CustomerCommercialInvoice");
	SalesArray.Add("InvoiceIssued");
	SalesArray.Add("IssuedTaxInvoicePrepayment");
	SalesArray.Add("InvoiceToCommissionAgent");
	
	ArrayProduction = New Array;  
	ArrayProduction.Add("ReturnOfMaterialsFromProduction");
	ArrayProduction.Add("ReturnOfRawMaterialsToMaterialProvider");
	ArrayProduction.Add("ReturnOfRawMaterialsFromToller");
	ArrayProduction.Add("ReturnOfGiftCards");
	ArrayProduction.Add("ReturnOfGoodsFromCustomer");
	ArrayProduction.Add("IntercompanyGoodsReturn"); 
	ArrayProduction.Add("MovementOfProductsAndMaterials");
	ArrayProduction.Add("SalesOrder");
	ArrayProduction.Add("MaterialProviderOrder2_5");
	ArrayProduction.Add("ReportToMaterialProvider2_5");
	ArrayProduction.Add("SubcontractorReport"); 
	ArrayProduction.Add("SubcontractorReport2_5");
	ArrayProduction.Add("GoodsShipmentFromStorage");
	ArrayProduction.Add("MaterialTransferToProduction");
	ArrayProduction.Add("MaterialTransferToToller");
	ArrayProduction.Add("TransferOfGoodsToBailee");
	ArrayProduction.Add("MaterialTransferToToller");
	ArrayProduction.Add("TransferOfGoodsToBailee");
	ArrayProduction.Add("SupplyFromMaterialProvider");
	ArrayProduction.Add("ReceiptFromToller");
	ArrayProduction.Add("ReceiptOfGoodsFromCustodian");
	ArrayProduction.Add("GoodsReceiptForStorage");
	ArrayProduction.Add("BackflushProduction");
	ArrayProduction.Add("AssemblyFromComponents");
	ArrayProduction.Add("TransferToMaterialProvider");
	
	ArrayWarehouse = New Array;
	ArrayWarehouse.Add("InventoryConsumption");
	ArrayWarehouse.Add("RedemptionOfGoodsFromStorage");
	ArrayWarehouse.Add("TransferOrder");
	ArrayWarehouse.Add("PhysicalCountReport");
	ArrayWarehouse.Add("PhysicalCountOfInventoryInOperation");
	ArrayWarehouse.Add("InventorySurplusRecognition");
	ArrayWarehouse.Add("RecordInventoryInOperation");
	ArrayWarehouse.Add("ReportOnVMIAdjustment");
	ArrayWarehouse.Add("InventoryTransfer");
	ArrayWarehouse.Add("CustomerInvoiceIntercompany");
	ArrayWarehouse.Add("GoodsMisgrading");
	ArrayWarehouse.Add("InventoryRecount"); 
	ArrayWarehouse.Add("OtherGoodsRecordingAsReceived");
	ArrayWarehouse.Add("Decomissioning");
	ArrayWarehouse.Add("WriteOffOfGoodsShortages");
	
	PayrollArray = New Array;
	PayrollArray.Add("PostingPayrollExpensesInFinancialAccounting");
	PayrollArray.Add("EmployeeLoanAgreement");
	PayrollArray.Add("WorkOutput");
	
	PartitionStructure = New Structure;
	ArrayOther = New Array;
	
	PartitionStructure.Insert("ArrayInputOfBalances", ArrayInputOfBalances);
	PartitionStructure.Insert("ArrayOfNonCurrentAssets", ArrayOfNonCurrentAssets);
	PartitionStructure.Insert("PurchaseArray", PurchaseArray); 
	PartitionStructure.Insert("PayrollArray", PayrollArray);
	PartitionStructure.Insert("TreasuryArray", TreasuryArray);
	PartitionStructure.Insert("SalesArray", SalesArray);
	PartitionStructure.Insert("ArrayProduction", ArrayProduction);
	PartitionStructure.Insert("ArrayWarehouse", ArrayWarehouse);
	PartitionStructure.Insert("ArrayOther", ArrayOther);
	
	For Each AccountingSection In SectionsArray Do 
		If ArrayOfSectionsOfExchangePlan.Find(AccountingSection) = Undefined Then
			Continue;
		EndIf;
		AccountingSectionKey = "Array" + StrReplace(AccountingSection, " ", "");
		SectionStructure = PartitionStructure[AccountingSectionKey];
		FillInSectionOnDocuments(ObjectNode.DocumentsKinds, AccountingSection, SectionStructure);
	EndDo;
	ObjectNode.UseFilterByAccountingSectionAndDocument = True;
	ObjectNode.UseFilterByAccountingSections = False;
EndProcedure

#EndRegion

#Region OtherProceduresAndFunctions_

// Filling in accounting sections in settings forms
// 
// Parameters:
//  InFormOfStructure - Boolean
//  SettingID - String
// 
// Returns:
// Structure:
//    * AccountingSection - Array of String
//    * ToExport - Boolean,
// ValueTable:
//   * AccountingSection - String
//   * ToExport - Boolean
Function GetAccountingSections(InFormOfStructure, SettingID = "") Export
	
	AccountingSections = New ValueTable;
	AccountingSections.Columns.Add("AccountingSection");
	AccountingSections.Columns.Add("ToExport");
	
	If SettingID = "ExchangeUP2ZUP3" Then
		Section = AccountingSections.Add();
		Section.AccountingSection = "Salary";
		Section.ToExport = True;
	Else
		
		Section = AccountingSections.Add();
		Section.AccountingSection = "Return leftovers";
		Section.ToExport = True;
		
		If Not Constants.TradeManagement.Get() Then
			Section = AccountingSections.Add();
			Section.AccountingSection = "NonCurrent assets_1";
			Section.ToExport = True;
		EndIf;
		
		Section = AccountingSections.Add();
		Section.AccountingSection = "Purchases";
		Section.ToExport = True;
		
		Section = AccountingSections.Add();
		Section.AccountingSection = "TreasuryAndARAPAccounting";
		Section.ToExport = True;
		
		Section = AccountingSections.Add();
		Section.AccountingSection = "Sales";
		Section.ToExport = True;
		
		If Not Constants.TradeManagement.Get() Then
			Section = AccountingSections.Add();
			Section.AccountingSection = "Production";
			Section.ToExport = True;
		EndIf;
		
		Section = AccountingSections.Add();
		Section.AccountingSection = "Warehouse";
		Section.ToExport = True;
		
	EndIf;
	
	If InFormOfStructure Then
		Return New Structure("AccountingSection, ToExport", 
			AccountingSections.UnloadColumn("AccountingSection"), 
			AccountingSections.UnloadColumn("ToExport"));
	Else
		Return AccountingSections;
	EndIf;
	
EndFunction

// Determines whether the assistant will be used to create new exchange plan nodes.
//
// Returns:
//  Boolean - indicates whether the assistant is being used.
//
Function UseDataExchangeCreationWizard()
	
	If GetFunctionalOption("TradeManagement")
		And StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		
		// If there is already a synchronization setting, then the assistant for creating a new exchange is not available.
		Query = New Query("SELECT
			|	DataSynchronizationViaUniversalFormat.Ref
			|FROM
			|	ExchangePlan.DataSynchronizationViaUniversalFormat AS DataSynchronizationViaUniversalFormat
			|WHERE
			|	DataSynchronizationViaUniversalFormat.SettingsMode = &UTBPExchange
			|	AND DataSynchronizationViaUniversalFormat.ThisNode = FALSE");
			
		Query.SetParameter("UTBPExchange", IdOfBasicUTBP30ExchangeSetup());
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			Return False;
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

// Returns an array of used message transports for this exchange plan
//
// 1. For example, if the exchange plan supports only two message transports FILE and FTP,
// then the function body should be defined as follows:
//
//	Result = New Array;
//	The result.Add(Enumerations.Type of transportcommunication of the exchange.FILE);
//	The result.Add(Enumerations.Type of transportcommunication of the exchange.FTP);
//	Return Result;
//
// 2. For example, if the exchange plan supports all message transports defined in the configuration,
// then the function body should be defined as follows:
//
//	Return the sent server.Alltransportsconfiguration Exchange().
//
// Returns:
//  Array of EnumRef.ExchangeMessagesTransportTypes - contains the values of the enumeration of the type of transport of the exchange message.
//
Function UsedExchangeMessagesTransports(SettingID="")
	
	Result = New Array;
	Result.Add(DataProcessors.ExchangeMessageTransportFILE);
	
	If SettingID = "UpuppExchange" Then
		Result.Add(DataProcessors.ExchangeMessageTransportFTP);
	ElsIf StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		FillInUsedExchangeMessageTransports(Result, True);
	ElsIf SettingID = "ExchangeOfUPRMC" Then
		Result.Add(DataProcessors.ExchangeMessageTransportFTP);
		FillInUsedExchangeMessageTransports(Result, True);
	Else
		FillInUsedExchangeMessageTransports(Result, False);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the names of the details and tabular parts of the exchange plan, separated by commas,
// which are common to a pair of exchanging configurations.
//
// Returns:
//   String - A list of the names of the details.
//
Function CommonNodeData()
	
	Return "ExportModeOnDemand";
	
EndFunction

// Fill in the used exchange message transports.
// 
// Parameters:
//  Result - Array of MetadataObject - Array of supported exchange transports.
//  BaseVersion - Boolean - Basic version
//
Procedure FillInUsedExchangeMessageTransports(Result, BaseVersion)
	
	Result.Add(DataProcessors.ExchangeMessageTransportWS);
	Result.Add(DataProcessors.ExchangeMessageTransportHTTP);
	Result.Add(DataProcessors.ExchangeMessageTransportPassiveMode);
	Result.Add(DataProcessors.ExchangeMessageTransportYandexDisk);
	Result.Add(DataProcessors.ExchangeMessageTransportGoogleDrive);
	
	If Not BaseVersion Then
		Result.Add(DataProcessors.ExchangeMessageTransportFTP);
		Result.Add(DataProcessors.ExchangeMessageTransportEMAIL);
		Result.Add(DataProcessors.ExchangeMessageTransportCOM);
		Result.Add(DataProcessors.ExchangeMessageTransportESB1C);
		Result.Add(DataProcessors.ExchangeMessageTransportSM);
	EndIf;
	
EndProcedure

#EndRegion

#Region SwitchingToUniversalFormat

// The wrapper function performs parameter preparation and calls the main function 
// (See SwitchToDataSynchronizationViaUniversalFormat).
// It is called during the first exchange to set up data synchronization via a universal format
//  via a COM connection.
//
// Parameters:
//  DataSynchronizationSettings_ - Structure - information about the synchronization setting that the transition takes place with: 
//  * Code - String - The setup code.
//  * SettingsMode - String - an option to configure data synchronization via the universal format of the correspondent database.
//  * Error - Boolean - a sign of an error when executing the function.
//  * ErrorMessage - String - text of the error message.
//
// Returns:
//  ExchangePlanRef, Undefined - Link to setting up data synchronization via a universal format (if the transition is successful),
//  Undefined (in case of critical errors that occurred during the transition).
Function SwitchingToSynchronizationViaUniversalFormatExternalConnection(DataSynchronizationSettings_) Export
	
	SettingsMode = DataSynchronizationSettings_.SettingsMode;
	
	If Not ValueIsFilled(SettingsMode) Then
		
		DataSynchronizationSettings_.Error = True;
		MessageText = NStr("vi = 'Chưa chỉ ra phương án tùy chỉnh đồng bộ trong cơ sở thông tin trao đổi';
							|ru = 'Не указан вариант настройки синхронизации в базе-корреспонденте';
							|en = 'Synchronization setup option is not specified in the peer infobase'; fa = 'Synchronization setup option is not specified in the peer infobase';
							|it = 'Non è indicata la variante di impostazione di sincronizzazione nella base corrispondente';
							|pl = 'Nie jest podany wariant ustawienia synchronizacji w bazie korespondencie';
							|tr = 'Muhabir tabanda senkronizasyon ayar seçeneği belirtilmedi'");
		DataSynchronizationSettings_.ErrorMessage = MessageText;
		
		Return Undefined;
		
	EndIf;
	
	NameOfOldConfigurationExchangePlan = NameOfOldConfigurationExchangePlan(SettingsMode);
	
	If Not ValueIsFilled(NameOfOldConfigurationExchangePlan) Then
		
		DataSynchronizationSettings_.Error = True;
		
		NString = NStr("vi = 'Đã chuyển phương án tùy chỉnh đồng bộ không xác định: %1.';
						|ru = 'Передан неизвестный вариант настройки синхронизации: %1.';
						|en = 'Unknown synchronization setup option is transferred: %1.'; fa = 'Unknown synchronization setup option is transferred: %1.';
						|it = 'È indicata una variante di impostazione di sincronizzazione sconosciuta: %1.';
						|pl = 'Został przekazany nieznany wariant ustawienia synchronizacji: %1.';
						|tr = 'Bilinmeyen bir senkronizasyon ayarı varyantı transfer edildi: %1.'");
		
		DataSynchronizationSettings_.ErrorMessage = 
			StringFunctionsClientServer.SubstituteParametersToString(NString, SettingsMode);

		Return Undefined;
		
	EndIf;
	
	If Metadata.ExchangePlans.Find(NameOfOldConfigurationExchangePlan) = Undefined Then
		
		DataSynchronizationSettings_.Error = True;
		
		NString = NStr("vi = 'Không tìm thấy sơ đồ trao đổi tương ứng với phương án tùy chỉnh: %1.';
						|ru = 'Не обнаружен план обмена, соответствующий варианту настройки: %1.';
						|en = 'Exchange plan matching the setup option is not found: %1.'; fa = 'Exchange plan matching the setup option is not found: %1.';
						|it = 'Non è stato rilevato il piano di scambio corrispondente alla variante di impostazione: %1.';
						|pl = 'Nie wykryto planu wymiany, zgodnego z wariantem ustawienia: %1.';
						|tr = 'Ayar seçeneğine uygun gelen değişim planı bulunmadı: %1.'");
		
		DataSynchronizationSettings_.ErrorMessage = 
			StringFunctionsClientServer.SubstituteParametersToString(NString, SettingsMode);
			
		Return Undefined;
		
	EndIf;
	
	SetupCode = DataSynchronizationSettings_.Code;
	
	DataSynchronizationSetup = ExchangePlans[NameOfOldConfigurationExchangePlan].FindByCode(SetupCode);
	
	If Not ValueIsFilled(DataSynchronizationSetup) Then
		
		DataSynchronizationSettings_.Error = True;
		
		NString = NStr("vi = 'Không tìm thấy nút cơ sở thông tin trao đổi đối với sơ đồ trao đổi: %1, mã: %2.';
						|ru = 'Не найден узел корреспондента для плана обмена: %1, код: %2.';
						|en = 'Peer infobase node for the exchange plan is not found: %1, code: %2.'; fa = 'Peer infobase node for the exchange plan is not found: %1, code: %2.';
						|it = 'Non è stato trovato il nodo del corrispondente per il piano di scambio: %1, codice: %2.';
						|pl = 'Nie znaleziono węzła korespondenta dla planu wymiany: %1, kod: %2.';
						|tr = 'Değişim planı: %1, kod: %2 için uygun gelen muhabir düğümü bulunamadı.'");
		
		DataSynchronizationSettings_.ErrorMessage = 
			StringFunctionsClientServer.SubstituteParametersToString(NString, 
			NameOfOldConfigurationExchangePlan, 
			SetupCode);
		
		Return Undefined;
		
	EndIf;
	
	Return SwitchToDataSynchronizationViaUniversalFormat(DataSynchronizationSetup);
	
EndFunction

// The wrapper function performs parameter preparation and calls the main function 
// (See SwitchToDataSynchronizationViaUniversalFormat).
// It is called during Internet transport: the correspondent has made the transition to a universal format,
//  but the current IB is not. 
//
// Parameters:
//  NodeCode - String - The setup code.
//  Error - Boolean - a sign of an error when executing the function.
//
// Returns:
//  ExchangePlanRef - Link to setting up data synchronization via a universal format (if the transition is successful),
//  Undefined (in case of critical errors that occurred during the transition).
Function SwitchingToSynchronizationViaUniversalInternetFormat(NodeCode, Error) Export
	
	If Metadata.ExchangePlans.Find("ExchangeTradeManagementEnterpriseAccounting1930") <> Undefined Then
		NameOfExchangePlanToGo = "ExchangeTradeManagementEnterpriseAccounting1930";
	ElsIf Metadata.ExchangePlans.Find("ExchangeTradeManagementEnterpriseAccounting30") <> Undefined Then
		NameOfExchangePlanToGo = "ExchangeTradeManagementEnterpriseAccounting30";
	EndIf;
	
	SettingUpSynchronizationViaUniversalFormat = Undefined;
	
	If NameOfExchangePlanToGo <> "" Then
		
		DataSynchronizationSetup = ExchangePlans[NameOfExchangePlanToGo].FindByCode(NodeCode);
		
		If Not DataSynchronizationSetup.IsEmpty() Then
			
			ExchangePlanManager = ExchangePlans.DataSynchronizationViaUniversalFormat;
			
			Try
				
				SettingUpSynchronizationViaUniversalFormat = 
					ExchangePlanManager.SwitchToDataSynchronizationViaUniversalFormat(DataSynchronizationSetup);
				
			Except
				Error = True;
			EndTry;
			
		EndIf;
		
	EndIf;
	
	Return SettingUpSynchronizationViaUniversalFormat;
	
EndFunction

// The function returns the name of the old configuration exchange plan
//  corresponding to the configuration option in data synchronization via a universal format.
//
// Parameters:
//   SettingsMode - String
//
// Returns:
//   String - name of the exchange plan.
Function NameOfOldConfigurationExchangePlan(SettingsMode) Export
	
	If TrimAll(SettingsMode) = IdOfExchangeSetupBP30() Then
		
		Return "ExchangeTradeManagementEnterpriseAccounting30";
		
	ElsIf TrimAll(SettingsMode) = IdOfExchangeSetupBPCORP30() Then
		
		Return "ExchangeTradeManagementEnterpriseAccounting1930";
		
	EndIf;
	
	Return "";
	
EndFunction

// The function makes the transition from the existing data synchronization setting 
//  to the data synchronization setting via a universal format.
//
// Parameters:
//  DataSynchronizationSetup - ExchangePlanRef.DataSynchronizationViaUniversalFormat - A link to the data synchronization setting from which the transition is performed.
// 
// Returns:
//  - ExchangePlanRef - A link to setting up data synchronization via a universal format (if the transition is successful).
//  - Undefined - in case of critical errors that occurred during the transition.
Function SwitchToDataSynchronizationViaUniversalFormat(DataSynchronizationSetup) Export
	
	SettingUpSynchronizationViaUniversalFormat = Undefined;
	SetupCode = DataSynchronizationSetup.Code;
	NameOfOldConfigurationExchangePlan = DataSynchronizationSetup.Metadata().Name;
	
	RefreshReusableValues();
	
	// Search or create synchronization settings via a universal format.
	Query = New Query("SELECT TOP 1
		|	DataSynchronizationViaUniversalFormat.Ref
		|FROM 
		|	ExchangePlan.DataSynchronizationViaUniversalFormat AS DataSynchronizationViaUniversalFormat
		|WHERE 
		|	NOT DataSynchronizationViaUniversalFormat.ThisNode 
		|	AND DataSynchronizationViaUniversalFormat.Code = &SetupCode");
	
	Query.SetParameter("SetupCode", SetupCode);
	QueryResult = Query.Execute();
	
	EventNameLog = NStr("vi = 'Chuyển đến đồng bộ dữ liệu thông qua định dạng đa năng';
						|ru = 'Переход на синхронизацию данных через универсальный формат';
						|en = 'Switch to interim format data synchronization'; fa = 'Switch to interim format data synchronization';
						|it = 'Passaggio alla sincronizzazione dati tramite il formato universale';
						|pl = 'Przejście do synchronizacji danych przez uniwersalny format';
						|tr = 'Yaygın format üzerinden veri senkronizasyonuna geçiş'", Common.DefaultLanguageCode());
	
	Message = NStr("vi = 'Bắt đầu chuyển';
					|ru = 'Начало перехода';
					|en = 'Switch start'; fa = 'Switch start';
					|it = 'Avvio passaggio';
					|pl = 'Początek przejścia';
					|tr = 'Transfer başlangıcı'");
	WriteLogEvent(EventNameLog, EventLogLevel.Information, , , Message);

	Message = NStr("vi = 'Tạo mới tùy chỉnh đồng bộ dữ liệu';
					|ru = 'Создание новой настройки синхронизации данных';
					|en = 'Create new data synchronization setup'; fa = 'Create new data synchronization setup';
					|it = 'Creazione nuova impostazione di sincronizzazione dati';
					|pl = 'Utworzenie nowej konfiguracji synchronizacji danych';
					|tr = 'Yeni veri senkronizasyon ayarı oluşturma'");
	WriteLogEvent(EventNameLog, EventLogLevel.Information, , , Message);
	
	BeginTransaction();
	
	Try
		
		If Not QueryResult.IsEmpty() Then
			
			Selection = QueryResult.Select();
			Selection.Next();
			NewObjectSetting = Selection.Ref.GetObject();
			
		Else
			// Creating a new setting.
			NewObjectSetting = ExchangePlans.DataSynchronizationViaUniversalFormat.CreateNode();
		EndIf;
		
		FillPropertyValues(NewObjectSetting, DataSynchronizationSetup,,
			"SentNo, ReceivedNo, DeletionMark");
		
		SettingsMode = "";
		
		If NameOfOldConfigurationExchangePlan = "ExchangeTradeManagementEnterpriseAccounting30" Then
			
			SettingsMode = IdOfExchangeSetupBP30();
			
		ElsIf NameOfOldConfigurationExchangePlan = "ExchangeTradeManagementEnterpriseAccounting1930" Then
			
			SettingsMode = IdOfExchangeSetupBPCORP30();
			
		EndIf;
		
		NewObjectSetting.SettingsMode = SettingsMode;
		
		MetadataOfOldSetting = Metadata.ExchangePlans[NameOfOldConfigurationExchangePlan];
		If MetadataOfOldSetting.TabularSections.Find("Companies") <> Undefined Then
			
			NewObjectSetting.Companies.Clear();
			
			For Each OrganizationString In DataSynchronizationSetup.Companies Do
				NewBusinessLine = NewObjectSetting.Companies.Add();
				FillPropertyValues(NewBusinessLine, OrganizationString);
			EndDo;
			
		EndIf;
		
		NewObjectSetting.UploadAnalyticsByWarehouse = True;
		
		If MetadataOfOldSetting.Attributes.Find("GeneralizedWarehouse") <> Undefined Then
			//@skip-check bsl-legacy-check-static-feature-access-for-unknown-left-part
			// this property of the exchange plan from which the transition is made is relevant for TM
			If ValueIsFilled(DataSynchronizationSetup.GeneralizedWarehouse) Then
				NewObjectSetting.UploadAnalyticsByWarehouse = False;
			EndIf;
		EndIf;
		
		AvailableFormatVersions = New Map;
		TMDataExchange.AvailableVersionsOfUniversalFormat(AvailableFormatVersions);
		
		For Each KeyAndValue In AvailableFormatVersions Do
			NewObjectSetting.ExchangeFormatVersion = KeyAndValue.Key;
		EndDo;
		
		NewObjectSetting.Write();
		
		SettingUpSynchronizationViaUniversalFormat = NewObjectSetting.Ref;
		
		PredefinedNodeCode = Common.ObjectAttributeValue(ExchangePlans.DataSynchronizationViaUniversalFormat.ThisNode(), "Code");
		If StrLen(PredefinedNodeCode) = 36 Then
			RecordStructure = New Structure;
			RecordStructure.Insert("Peer", SettingUpSynchronizationViaUniversalFormat);
			RecordStructure.Insert("NodeCode",
				//@skip-check bsl-legacy-check-string-literal
				// this is the code of the exchange plan from which the transition is made, relevant for TM
				Common.ObjectAttributeValue(ExchangePlans[NameOfOldConfigurationExchangePlan].ThisNode(), "Code"));
			DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "PredefinedNodesAliases");
		EndIf;
		
		// Registration of changes.
		Message = NStr("vi = 'Ghi nhận thay đổi';
						|ru = 'Регистрация изменений';
						|en = 'Change registration'; fa = 'تغییر ثبت';
						|it = 'Registrazione delle modifiche';
						|pl = 'Rejestracja zmian';
						|tr = 'Değişim kaydı'");
		WriteLogEvent(EventNameLog, EventLogLevel.Information, , , Message);

		PerformChangeRegistration(DataSynchronizationSetup, SettingUpSynchronizationViaUniversalFormat);
		
		// Transport settings.
		Message = NStr("vi = 'Điền tùy chỉnh truyền thông điệp';
						|ru = 'Заполнение настроек транспорта сообщений';
						|en = 'Fill in message transport settings'; fa = 'Fill in message transport settings';
						|it = 'Compilazione impostazioni di trasporto messaggi';
						|pl = 'Wypełnienie ustawień transportowania wiadomości';
						|tr = 'Mesaj transfer ayarlarının doldurulması'");
		WriteLogEvent(EventNameLog, EventLogLevel.Information, , , Message);

		UploadMessageAfterTransition = False;
		ProcessExchangeMessageTransportSettings(DataSynchronizationSetup, 
			SettingUpSynchronizationViaUniversalFormat, 
			UploadMessageAfterTransition);

		// Date the change was banned.
		Message = NStr("vi = 'Điền tùy chỉnh cấm thay đổi dữ liệu';
						|ru = 'Заполнение настроек запрета изменения данных';
						|en = 'Fill in period-end closing settings'; fa = 'Fill in period-end closing settings';
						|it = 'Compilazione impostazioni di divieto di modifica dati';
						|pl = 'Wypełnienie ustawień zakazu zmiany danych';
						|tr = 'Veri değiştirme yasağı için ayarların doldurulması'");
		WriteLogEvent(EventNameLog, EventLogLevel.Information, , , Message);

		ProcessDatesWhenChangesAreBanned(DataSynchronizationSetup, SettingUpSynchronizationViaUniversalFormat);
		
		// Data exchange scenarios.
		Message = NStr("vi = 'Điền kịch bản trao đổi dữ liệu';
						|ru = 'Заполнение сценариев обмена данными';
						|en = 'Fill in data exchange scenarios'; fa = 'Fill in data exchange scenarios';
						|it = 'Compilazione scenari di scambio dati';
						|pl = 'Wypełnienie scenariuszy wymiany danych';
						|tr = 'Veri değişimi senaryolarının doldurulması'");
		WriteLogEvent(EventNameLog, EventLogLevel.Information, , , Message);

		HandleDataExchangeScenarios(DataSynchronizationSetup, SettingUpSynchronizationViaUniversalFormat);
		
		//  Public identificationsynchronized objects and data objects for registration and exchange.
		CheckCorrespondenceOfInformationDatabaseObjects(DataSynchronizationSetup, 
			SettingUpSynchronizationViaUniversalFormat);
		
		// Filling in the settings of the main node.
		Message = NStr("vi = 'Điền tùy chỉnh nút chính';
						|ru = 'Заполнение настроек главного узла';
						|en = 'Fill in master node settings'; fa = 'Fill in master node settings';
						|it = 'Compilazione impostazione nodo principale';
						|pl = 'Wypełnienie ustawień głównego węzła';
						|tr = 'Ana düğümün ayarlarının doldurulması'");
		WriteLogEvent(EventNameLog, EventLogLevel.Information, , , Message);

		ThisNodeLink = ExchangePlans.DataSynchronizationViaUniversalFormat.ThisNode();
		ThisNodeCode = Common.ObjectAttributeValue(ThisNodeLink, "Code");
		
		If Not ValueIsFilled(ThisNodeCode) Then
			
			OldMasterNode = ExchangePlans[NameOfOldConfigurationExchangePlan].ThisNode();
			NewMasterNode = ThisNodeLink.GetObject();
			
			FillPropertyValues(NewMasterNode, OldMasterNode,,
				"SentNo, ReceivedNo, DeletionMark");
			
			If MetadataOfOldSetting.TabularSections.Find("Companies") <> Undefined Then
				
				NewMasterNode.Companies.Clear();
				
				For Each OrganizationString In OldMasterNode.Companies Do
					NewBusinessLine = NewMasterNode.Companies.Add();
					FillPropertyValues(NewBusinessLine, OrganizationString);
				EndDo;
				
			EndIf;
			
			NewMasterNode.Write();
			
		EndIf;
		
		Message = NStr("vi = 'Điền kết quả trao đổi dữ liệu';
						|ru = 'Заполнение результатов обмена данными';
						|en = 'Fill in data exchange results'; fa = 'Fill in data exchange results';
						|it = 'Compilazione risultati di scambio dati';
						|pl = 'Wypełnienie wyników wymiany danych';
						|tr = 'Veri değişimi sonuçlarının doldurulması'");
		WriteLogEvent(EventNameLog, EventLogLevel.Information, , , Message);
		ProcessDataExchangeResults(DataSynchronizationSetup, SettingUpSynchronizationViaUniversalFormat);
		
		If Not DataSynchronizationSetup.DeletionMark Then
			Message = NStr("vi = 'Đặt dấu xóa tùy chỉnh cũ';
							|ru = 'Пометка на удаление старой настройки';
							|en = 'Mark previous setup for deletion'; fa = 'Mark previous setup for deletion';
							|it = 'Contrassegno per l''eliminazione della vecchia impostazione';
							|pl = 'Zaznaczenie do usunięcia starej konfiguracji';
							|tr = 'Eski ayarı silmek işareti'");
			WriteLogEvent(EventNameLog, EventLogLevel.Information, , , Message);
			DataSynchronizationSetup.GetObject().SetDeletionMark(True);
		EndIf;
		
		ExchangePlans.DeleteChangeRecords(DataSynchronizationSetup);
	
		CommitTransaction();
	Except
		RollbackTransaction();
		
		Message = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EventNameLog, EventLogLevel.Error, , , Message);
		
		Raise;
	EndTry;
	
	// Update the exchange rules if necessary.
	Query = New Query("SELECT TOP 2
		|	DataSynchronizationViaUniversalFormat.Ref
		|FROM 
		|	ExchangePlan.DataSynchronizationViaUniversalFormat AS DataSynchronizationViaUniversalFormat
		|WHERE 
		|	NOT DataSynchronizationViaUniversalFormat.ThisNode");
	
	If Query.Execute().Unload().Count() < 2 Then
		// The first setup for this exchange plan has been created, the rules have not yet been updated.
		DataExchangeServer.UpdateDataExchangeRules();
	EndIf;
	
	If UploadMessageAfterTransition Then
		
		// Uploading a message according to the new exchange setting.
		Cancel = False;
		
		DataExchangeServer.ExecuteExchangeActionForInfobaseNode(Cancel, 
			SettingUpSynchronizationViaUniversalFormat,
			Enums.ActionsOnExchange.DataExport);
			
		If Cancel Then
			Message = NStr("vi = 'Chưa thực hiện kết xuất dữ liệu thông qua định dạng đa năng.';
							|ru = 'Выгрузка данных через универсальный формат не выполнена.';
							|en = 'Data is not exported via interim format.'; fa = 'Data is not exported via interim format.';
							|it = 'Upload dati tramite formato universale non eseguito.';
							|pl = 'Eksportowanie danych przez uniwersalny format nie zostało wykonane.';
							|tr = 'Yaygın format aracılığıyla veri yükleme işlemi gerçekleştirilmedi.'");
			WriteLogEvent(EventNameLog, EventLogLevel.Error, , , Message);
		Else
			Message = NStr("vi = 'Kết xuất dữ liệu thông qua định dạng đa năng.';
							|ru = 'Выгрузка данных через универсальный формат.';
							|en = 'Data export via interim format.'; fa = 'Data export via interim format.';
							|it = 'Upload dati tramite formato universale.';
							|pl = 'Eksportowanie danych przez uniwersalny format.';
							|tr = 'Yaygın format aracılığıyla veri yükleme işlemi.'");
			WriteLogEvent(EventNameLog, EventLogLevel.Information, , , Message);
		EndIf;
		
	EndIf;
	
	Message = NStr("vi = 'Kết thúc chuyển';
					|ru = 'Окончание перехода';
					|en = 'Switch end'; fa = 'Switch end';
					|it = 'Fine passaggio';
					|pl = 'Koniec przejścia';
					|tr = 'Transfer işlemi sonu'");
	
	WriteLogEvent(EventNameLog, EventLogLevel.Information, , , Message);
	
	Return SettingUpSynchronizationViaUniversalFormat;
	
EndFunction

// The procedure copies the registration of changes from one node to another.
//
// Parameters:
//  OldNode - ExchangePlanRef - link to the exchange plan node that is the source of the information
//  NewNode - ExchangePlanRef - a link to the exchange plan node that is the recipient of the information.
Procedure PerformChangeRegistration(OldNode, NewNode)
	
	CompositionOfNewExchangePlan = Metadata.ExchangePlans.DataSynchronizationViaUniversalFormat.Content;
	
	MessageNo = Common.ObjectAttributeValue(OldNode, "SentNo");
	ChangesSelection = ExchangePlans.SelectChanges(OldNode, MessageNo);
	
	While ChangesSelection.Next() Do
		
		RegistrationObject = ChangesSelection.Get();
		
		If RegistrationObject = Undefined Then
			Continue;
		ElsIf TypeOf(RegistrationObject) = Type("ObjectDeletion") Then
			If Not CompositionOfNewExchangePlan.Contains(RegistrationObject.Ref.Metadata()) Then
				Continue;
			EndIf;
		ElsIf Not CompositionOfNewExchangePlan.Contains(RegistrationObject.Metadata()) Then
			Continue;
		EndIf;
		
		ExchangePlans.RecordChanges(NewNode, RegistrationObject);
		
	EndDo;
	
EndProcedure

// The procedure transfers information about the date of the change ban from one node to another.
//
// Parameters:
//  OldNode - ExchangePlanRef - link to the exchange plan node that is the source of the information
//  NewNode - ExchangePlanRef - a link to the exchange plan node that is the recipient of the information.
Procedure ProcessDatesWhenChangesAreBanned(OldNode, NewNode)
	
	ClosingDates = InformationRegisters.PeriodClosingDates.CreateRecordSet();
	ClosingDates.Filter.User.Set(OldNode);
	ClosingDates.Read();
	
	BanDatesNew = InformationRegisters.PeriodClosingDates.CreateRecordSet();
	BanDatesNew.Filter.User.Set(NewNode);
	
	For Each PeriodEndClosingDate In ClosingDates Do
		
		RecordNew = BanDatesNew.Add();
		RecordNew.User = NewNode;
		FillPropertyValues(RecordNew, PeriodEndClosingDate,,"User");
		
	EndDo;
	
	ClosingDates.Clear();
	ClosingDates.Write();
	BanDatesNew.Write();
	
EndProcedure

// The procedure transfers information about data exchange scenarios from one node to another.
//
// Parameters:
//  OldNode - ExchangePlanRef - link to the exchange plan node that is the source of the information
//  NewNode - ExchangePlanRef - a link to the exchange plan node that is the recipient of the information.
Procedure HandleDataExchangeScenarios(OldNode, NewNode)
	
	Query = New Query("SELECT DISTINCT
		|	Ref
		|FROM 
		|	Catalog.DataExchangeScenarios.ExchangeSettings
		|WHERE 
		|	InfobaseNode = &SyncSetup
		|	AND NOT Ref.DeletionMark");
	
	Query.SetParameter("SyncSetup", OldNode);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ObjectSharingScenario = Selection.Ref.GetObject(); // CatalogObject.DataExchangeScenarios
		TheStructureOfTheSearch = New Structure("InfobaseNode", OldNode);
		RowsDataSource = ObjectSharingScenario.ExchangeSettings.FindRows(TheStructureOfTheSearch);
		
		For Each DataSourceRow In RowsDataSource Do
			DataSourceRow.InfobaseNode = NewNode;
		EndDo;
		
		ObjectSharingScenario.Write();
		
	EndDo;
	
EndProcedure

// The procedure transfers information about the correspondences of information database objects from one node to another.
//
// Parameters:
//  OldNode - ExchangePlanRef - link to the exchange plan node that is the source of the information
//  NewNode - ExchangePlanRef - a link to the exchange plan node that is the recipient of the information.
Procedure CheckCorrespondenceOfInformationDatabaseObjects(OldNode, NewNode)
	
	// Filling in the given objects for registration and exchanges
	NameOfEventSection = NStr("vi = 'Chuyển đến đồng bộ dữ liệu thông qua định dạng đa năng';
								|ru = 'Переход на синхронизацию данных через универсальный формат';
								|en = 'Switch to interim format data synchronization'; fa = 'Switch to interim format data synchronization';
								|it = 'Passaggio alla sincronizzazione dati tramite il formato universale';
								|pl = 'Przejście do synchronizacji danych przez uniwersalny format';
								|tr = 'Yaygın format üzerinden veri senkronizasyonuna geçiş'", Common.DefaultLanguageCode());
	NameOfEventSubsection = NStr("vi = 'Dữ liệu để ghi nhận vào trao đổi';
								|ru = 'Данные для регистрации в обменах';
								|en = 'Data for registration in exchanges'; fa = 'Data for registration in exchanges';
								|it = 'Dati per la registrazione negli scambi';
								|pl = 'Dane do rejestracji w wymianach';
								|tr = 'Değişimlerde kayıt için veriler'", Common.DefaultLanguageCode());
	EventName = StrTemplate("%1.%2", NameOfEventSection, NameOfEventSubsection); 
	
	Message = NStr("vi = 'Điền dữ liệu để ghi nhận vào trao đổi';
					|ru = 'Заполнение данных для регистрации в обменах';
					|en = 'Fill in data to register in exchanges'; fa = 'Fill in data to register in exchanges';
					|it = 'Compilazione dati per la registrazione negli scambi';
					|pl = 'Wypełnienie danych dla rejestracji w wymianach';
					|tr = 'Değişimlerde kayıt için verilerin doldurulması'");
	WriteLogEvent(EventName, EventLogLevel.Information,,, Message);

	Query = New Query("SELECT DISTINCT
		|	SourceUUID AS Ref
		|FROM
		|	InformationRegister.InfobaseObjectsMaps
		|WHERE 
		|	InfobaseNode = &SyncSetup");
	
	Query.SetParameter("SyncSetup", OldNode);
	
	RecordsetObjectData = InformationRegisters.ObjectsDataToRegisterInExchanges.CreateRecordSet();
	RecordsetObjectData.Filter.InfobaseNode.Set(NewNode);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		NewRecordObjectData = RecordsetObjectData.Add();
		NewRecordObjectData.Ref = Selection.Ref;
		NewRecordObjectData.InfobaseNode = NewNode;
	EndDo;
	
	RecordsetObjectData.Write();
	
	// Public identificationsynchronized objects - filled only on the side of the PS,
	// since they need to be filled in only for one of the correspondents.
	If StrFind(Lower(Metadata.Name), "accounting") > 0 Then
		Query = New Query("SELECT
			|	SourceUUID AS Whedon,
			|	COUNT(DestinationUUID) AS RefsCount
			|INTO MatchingObjectsWithSelection
			|FROM 
			|	InformationRegister.InfobaseObjectsMaps
			|WHERE InfobaseNode = &SyncSetup 
			|	AND DestinationUUID <> CAST("""" AS STRING(36))
			|GROUP BY SourceUUID
			|;
			|SELECT 
			|	MatchingObjectsWithSelection.Whedon AS SourceUUID,
			|	ComplianceOfInformationSecurityObjects.DestinationUUID,
			|	ComplianceOfInformationSecurityObjects.DestinationType
			|FROM 
			|	MatchingObjectsWithSelection
			|LEFT JOIN 
			|	InformationRegister.InfobaseObjectsMaps AS ComplianceOfInformationSecurityObjects 
			|ON 
			|	ComplianceOfInformationSecurityObjects.SourceUUID = MatchingObjectsWithSelection.Whedon
			|	AND ComplianceOfInformationSecurityObjects.InfobaseNode = &SyncSetup
			|	AND ComplianceOfInformationSecurityObjects.DestinationUUID <> CAST("""" AS STRING(36))
			|WHERE 
			|	MatchingObjectsWithSelection.RefsCount > 1 
			|	AND ComplianceOfInformationSecurityObjects.DestinationUUID <> CAST("""" AS STRING(36))
			|;
			|SELECT 
			|	MatchingObjectsWithSelection.Whedon AS Ref,
			|	ComplianceOfInformationSecurityObjects.DestinationUUID AS Id
			|FROM 
			|	MatchingObjectsWithSelection
			|LEFT JOIN 
			|	InformationRegister.InfobaseObjectsMaps AS ComplianceOfInformationSecurityObjects 
			|ON 
			|	ComplianceOfInformationSecurityObjects.SourceUUID = MatchingObjectsWithSelection.Whedon
			|	AND ComplianceOfInformationSecurityObjects.InfobaseNode = &SyncSetup
			|	AND ComplianceOfInformationSecurityObjects.DestinationUUID <> CAST("""" AS STRING(36))
			|WHERE MatchingObjectsWithSelection.RefsCount = 1
			|");
		
		Query.SetParameter("SyncSetup", OldNode);
		QueryResult = Query.ExecuteBatch();
		
		NameOfEventSection = NStr("vi = 'Chuyển đến đồng bộ dữ liệu thông qua định dạng đa năng';
									|ru = 'Переход на синхронизацию данных через универсальный формат';
									|en = 'Switch to interim format data synchronization'; fa = 'Switch to interim format data synchronization';
									|it = 'Passaggio alla sincronizzazione dati tramite il formato universale';
									|pl = 'Przejście do synchronizacji danych przez uniwersalny format';
									|tr = 'Yaygın format üzerinden veri senkronizasyonuna geçiş'", Common.DefaultLanguageCode());
		NameOfEventSubsection = NStr("vi = 'Điền tên định danh công khai';
									|ru = 'Заполнение публичных идентификаторов';
									|en = 'Fill public IDs'; fa = 'Fill public IDs';
									|it = 'Compilazione ID pubblici';
									|pl = 'Wypełnienie identyfikatorów publicznych';
									|tr = 'Kamu tanımlayıcıların doldurulması'", Common.DefaultLanguageCode());
		EventName = StrTemplate("%1.%2", NameOfEventSection, NameOfEventSubsection); 
		
		Message = NStr("vi = 'Tạo tên định danh công khai - bắt đầu';
						|ru = 'Формирование публичных идентификаторов - начало';
						|en = 'Public ID generation - start'; fa = 'Public ID generation - start';
						|it = 'Creazione ID pubblici - avvio';
						|pl = 'Tworzenie identyfikatorów publicznych - początek';
						|tr = 'Kamu tanımlayıcıların oluşturulması - başlangıc'");
		WriteLogEvent(EventName, EventLogLevel.Information, , , Message);
		
		// Displaying one-to-many links
		If Not QueryResult[1].IsEmpty() Then
			
			Message = NStr("vi = 'Đã tìm thấy các bản ghi, trong đó một tham chiếu đến nguồn tương ứng với nhiều đích';
							|ru = 'Обнаружены записи, в которых одной ссылке на источник соответствуют несколько приемников';
							|en = 'Records where one source reference has multiple destinations are detected'; fa = 'Records where one source reference has multiple destinations are detected';
							|it = 'Sono state rilevate registrazioni in cui a un collegamento alla fonte corrispondono più ricevitori';
							|pl = 'Wykryto wpisy, w których jednemu odnośnikowi odpowiada kilka odbiorców';
							|tr = 'Birden çok hedefin aynı kaynak bağlantıyla eşleştiği yerde kayıtlar bulundu'") 
						+ Chars.LF + NStr("vi = 'Sẽ không xử lý các bản ghi này.';
											|ru = 'Эти записи обработаны не будут.';
											|en = 'These records will not be processed.'; fa = 'These records will not be processed.';
											|it = 'Queste registrazioni non saranno elaborate.';
											|pl = 'Te wpisy nie będą przetworzone.';
											|tr = 'Bu kayıtlar işlenmeyecek.'");
			WriteLogEvent(EventName, EventLogLevel.Error, , , Message);
			
			Selection = QueryResult[1].Select();
			
			While Selection.Next() Do
				NString = NStr("vi = 'Tên định danh duy nhất của nguồn: %1, Tên định danh duy nhất của đích: %2, Kiểu đích: %3';
								|ru = 'Уникальный идентификатор источника: %1, Уникальный идентификатор приемника: %2, Тип приемника: %3';
								|en = 'Source UUID: %1, Destination UUID: %2, Destination type: %3'; fa = 'Source UUID: %1, Destination UUID: %2, Destination type: %3';
								|it = 'ID univoco fonte: %1, ID univoco ricevitore: %2, Tipo di ricevitore: %3';
								|pl = 'Unikalny identyfikator źródła: %1, Unikalny identyfikator odbiorcy: %2, Typ odbiorcy: %3';
								|tr = 'Yaygın kaynak tanımlayıcısı: %1, Yaygın hedef tanımlayıcısı: %2, Hedef tipi: %3'");
				Message = StringFunctionsClientServer.SubstituteParametersToString(NString, 
					Selection.SourceUUID, 
					Selection.DestinationUUID, 
					Selection.DestinationType);
				
				WriteLogEvent(EventName, EventLogLevel.Error, , , Message);
				
			EndDo;
			
		EndIf;
		
		// Formation of entries in the register Public identifiers
		RecordCounter = 0;
		Selection = QueryResult[2].Select();
		
		While Selection.Next() Do
			
			// Checking the equality of identifiers
			SourceIDInString = TrimAll(Selection.Ref.UUID());
			
			If SourceIDInString = TrimAll(Selection.Id) Then
				Continue;
			EndIf;
			
			RecordCounter = RecordCounter + 1;
			RecordStructure = New Structure("InfobaseNode, Ref, Id", 
				NewNode, Selection.Ref, Selection.Id);
				
			DataExchangeInternal.AddRecordToInformationRegister(RecordStructure, 
				"SynchronizedObjectPublicIDs", False);
			
		EndDo;
		
		Message = NStr("vi = 'Đã hoàn thành việc tạo tên định danh công khai. Số lượng bản ghi:';
						|ru = 'Формирование публичных идентификаторов завершено. Количество записей:';
						|en = 'Public IDs are generated. Number of records:'; fa = 'Public IDs are generated. Number of records:';
						|it = 'Creazione di ID pubblici completata. Numero registrazioni:';
						|pl = 'Tworzenie identyfikatorów publicznych zostało zakończone. Ilość wpisów:';
						|tr = 'Kamu tanımlayıcıların oluşturulması tamamlandı. Kayıt sayısı:'") 
			+ RecordCounter;
			
		WriteLogEvent(EventName, EventLogLevel.Information, , , Message);
		
	EndIf;
	
	// Clearing the register of corresponding Information Database objects
	RecordSetMatchingObjects = InformationRegisters.InfobaseObjectsMaps.CreateRecordSet();
	RecordSetMatchingObjects.Filter.InfobaseNode.Set(OldNode);
	RecordSetMatchingObjects.Write();
	
	Message = NStr("vi = 'Đã xóa tương ứng giữa các đối tượng của các cơ sở thông tin';
					|ru = 'Соответствие объектов информационных баз очищен';
					|en = 'Mapping of infobase objects is cleared'; fa = 'Mapping of infobase objects is cleared';
					|it = 'Corrispondenza degli oggetti di infobase cancellata';
					|pl = 'Zgodność obiektów baz informacyjnych jest wyczyszczona';
					|tr = 'Infobase nesne eşleşmesi silindi'");
	
	WriteLogEvent(EventName, EventLogLevel.Information, , , Message);

EndProcedure

// The procedure transfers information about message transport settings from one node to another.
//
// Parameters:
//  OldNode - ExchangePlanRef - link to the exchange plan node that is the source of the information
//  NewNode - ExchangePlanRef - link to the exchange plan node that is the recipient of the information
//  UploadMessageAfterTransition - Boolean - a sign that after the transition
//   is completed, the exchange message should be unloaded according to the new setting. It is set during the procedure if
//   the default mode of transport is a file resource, ftp or email.
Procedure ProcessExchangeMessageTransportSettings(OldNode, NewNode, UploadMessageAfterTransition)
	
	NewNodeExchangeTransportSettings = InformationRegisters.DeleteDataExchangeTransportSettings.CreateRecordSet();
	NewNodeExchangeTransportSettings.Filter.Peer.Set(NewNode);
	TransportSettingsForOldNode = InformationRegisters.DeleteDataExchangeTransportSettings.CreateRecordSet();
	TransportSettingsForOldNode.Filter.Peer.Set(OldNode);
	TransportSettingsForOldNode.Read();
	
	ArrayOfAvailableMessageTransports = UsedExchangeMessagesTransports();
	
	If TransportSettingsForOldNode.Count()>0 Then
		
		NewNodeExchangeTransportSettings.Load(TransportSettingsForOldNode.Unload());
		
		For Each ConfiguringNode In NewNodeExchangeTransportSettings Do
			
			ConfiguringNode.Peer = NewNode;
			DefaultTransportKind = ConfiguringNode.DefaultExchangeMessagesTransportKind;
			
			If DefaultTransportKind = Enums.ExchangeMessagesTransportTypes.FILE
				Or DefaultTransportKind = Enums.ExchangeMessagesTransportTypes.EMAIL
				Or DefaultTransportKind = Enums.ExchangeMessagesTransportTypes.FTP Then
				UploadMessageAfterTransition = True;
			EndIf;
			
			If ArrayOfAvailableMessageTransports.Find(DefaultTransportKind) = Undefined Then
				
				// Redefining the default mode of transport
				DefaultView_ = Undefined;
				
				If ValueIsFilled(ConfiguringNode.FILEDataExchangeDirectory) Then
					DefaultView_ = Enums.ExchangeMessagesTransportTypes.FILE;
				ElsIf ValueIsFilled(ConfiguringNode.FTPConnectionPath) Then
					DefaultView_ = Enums.ExchangeMessagesTransportTypes.FTP;
				ElsIf ValueIsFilled(ConfiguringNode.EMAILAccount) Then
					DefaultView_ = Enums.ExchangeMessagesTransportTypes.EMAIL;
				EndIf;
				
				ConfiguringNode.DefaultExchangeMessagesTransportKind = DefaultView_;
				
				NameOfEventSection = NStr("vi = 'Chuyển đến đồng bộ dữ liệu thông qua định dạng đa năng';
											|ru = 'Переход на синхронизацию данных через универсальный формат';
											|en = 'Switch to interim format data synchronization'; fa = 'Switch to interim format data synchronization';
											|it = 'Passaggio alla sincronizzazione dati tramite il formato universale';
											|pl = 'Przejście do synchronizacji danych przez uniwersalny format';
											|tr = 'Yaygın format üzerinden veri senkronizasyonuna geçiş'", Common.DefaultLanguageCode());
				NameOfEventSubsection = NStr("vi = 'Điền tùy chỉnh truyền thông điệp';
											|ru = 'Заполнение настроек транспорта сообщений';
											|en = 'Fill in message transport settings'; fa = 'Fill in message transport settings';
											|it = 'Compilazione impostazioni di trasporto messaggi';
											|pl = 'Wypełnienie ustawień transportowania wiadomości';
											|tr = 'Mesaj transfer ayarlarının doldurulması'", Common.DefaultLanguageCode());
				EventName = StrTemplate("%1.%2", NameOfEventSection, NameOfEventSubsection);
				
				NString = NStr("vi = 'Kết nối được dùng trước đây mặc định không khả dụng để đồng bộ dữ liệu thông qua định dạng đa năng (%1)';
								|ru = 'Используемое ранее подключение по умолчанию недоступно для синхронизации данных через универсальный формат (%1)';
								|en = 'Previously used default connection is unavailable for interim format data synchronization (%1)'; fa = 'Previously used default connection is unavailable for interim format data synchronization (%1)';
								|it = 'La connessione precedentemente utilizzabile da impostazione predefinita non è disponibile per la sincronizzazione dati tramite formato universale (%1)';
								|pl = 'Wcześniej używane domyślne połączenie jest niedostępne dla synchronizacji danych przez format uniwersalny (%1)';
								|tr = 'Daha önce kullanılan varsayılan bağlantı, yaygın format (%1) aracılığıyla veri senkronizasyonu için mevcut değil'");
				Message = StringFunctionsClientServer.SubstituteParametersToString(NString, DefaultTransportKind);
				
				WriteLogEvent(EventName, EventLogLevel.Error,,, Message);
				
				If ValueIsFilled(ConfiguringNode.DefaultExchangeMessagesTransportKind) Then
					
					NString = NStr("vi = 'Thay vào đó, kết nối mặc định được chỉ định là %1. Cần kiểm tra chính xác tùy chỉnh truyền thông điệp';
									|ru = 'Взамен назначено подключение по умолчанию: %1. Необходимо проверить корректность настроек транспорта сообщений';
									|en = 'Default connection assigned instead: %1. Check if the message transport settings are correct'; fa = 'Default connection assigned instead: %1. Check if the message transport settings are correct';
									|it = 'Invece è stata assegnata una connessione predefinita: %1. È necessario verificare la correttezza delle impostazioni di trasporto dei messaggi';
									|pl = 'Zamiast jest przeznaczone połączenie domyślne: %1. Należy sprawdzić poprawność ustawień transportowania wiadomości';
									|tr = 'Bunun yerine varsayılan bağlantı atandı: %1. Mesaj transfer ayarlarının doğru olup olmadığının kontrol edilmesi gerekir'");
					Message = StringFunctionsClientServer.SubstituteParametersToString(NString, 
						ConfiguringNode.DefaultExchangeMessagesTransportKind);
					
				Else
					Message = NStr("vi = 'Kết nối mặc định đã bị xóa. Cần thực hiện tùy chỉnh truyền thông điệp bằng thủ công';
									|ru = 'Подключение по умолчанию очищено. Необходимо выполнить настройку транспорта сообщений вручную';
									|en = 'Default connection is cleared. Set up the message transport manually'; fa = 'Default connection is cleared. Set up the message transport manually';
									|it = 'Connessione predefinita cancellata. È necessario eseguire l''impostazione di trasporto dei messaggi manualmente';
									|pl = 'Połączenie domyślne jest wyczyszczone. Należy ustawić transportowanie wiadomości ręcznie';
									|tr = 'Varsayılan bağlantı temizlendi. Mesaj transferinin manuel olarak ayarlanması gerekir'");
				EndIf;
				
				WriteLogEvent(EventName, EventLogLevel.Error,,, Message);
				
			EndIf;
			
		EndDo;
		
		TransportSettingsForOldNode.Clear();
		TransportSettingsForOldNode.Write();
		NewNodeExchangeTransportSettings.Write();
		
	EndIf;
	
	SettingsOfNewNodeSIBNodes = InformationRegisters.CommonInfobasesNodesSettings.CreateRecordSet();
	SettingsOfNewNodeSIBNodes.Filter.InfobaseNode.Set(NewNode);
	
	SettingsOfIBNodesOfOldNode = InformationRegisters.CommonInfobasesNodesSettings.CreateRecordSet();
	SettingsOfIBNodesOfOldNode.Filter.InfobaseNode.Set(OldNode);
	SettingsOfIBNodesOfOldNode.Read();
	
	If SettingsOfIBNodesOfOldNode.Count()>0 Then
		
		SettingsOfNewNodeSIBNodes.Load(SettingsOfIBNodesOfOldNode.Unload());
		
		For Each ConfiguringNode In SettingsOfNewNodeSIBNodes Do
			ConfiguringNode.InfobaseNode = NewNode;
		EndDo;
		
		SettingsOfIBNodesOfOldNode.Clear();
		SettingsOfIBNodesOfOldNode.Write();
		SettingsOfNewNodeSIBNodes.Write();
		
	EndIf;
	
EndProcedure

// The procedure transfers information about the results of data exchange from one node to another.
//
// Parameters:
//  OldNode - ExchangePlanRef - link to the exchange plan node that is the source of the information
//  NewNode - ExchangePlanRef - a link to the exchange plan node that is the recipient of the information.
Procedure ProcessDataExchangeResults(OldNode, NewNode)
	
	ExchangeResults = InformationRegisters.DataExchangeResults.CreateRecordSet();
	ExchangeResults.Read();
	
	RecordsCount = ExchangeResults.Count();
	
	For Cnt = 1 To RecordsCount Do
		
		IndexOf = RecordsCount - Cnt;
		ExchangeResult = ExchangeResults[IndexOf];
		
		If ExchangeResult.InfobaseNode <> OldNode Then
			Continue;
		EndIf;
		
		If ExchangeResult.IsSkipped Then
			ExchangeResults.Delete(ExchangeResult);
			Continue;
		EndIf;
		
		ExchangeResult.InfobaseNode = NewNode;
		
	EndDo;
		
	ExchangeResults.Write();
	
EndProcedure

// The procedure attempts to switch to a new exchange from an existing exchange.
//  Called if a message is received during data synchronization that does not correspond to the format of the "old" exchange.
//
// Parameters:
//  DataSynchronizationSetup - ExchangePlanRef - link to the exchange plan node from which the transition to a new exchange is being performed
//  ExchangeOverExternalConnection - Boolean - indicates that the current exchange is being performed via an external connection.
Procedure SwitchToNewExchange(DataSynchronizationSetup, ExchangeOverExternalConnection = False) Export
	
	SettingUpSynchronizationViaUniversalFormat = 
		SwitchToDataSynchronizationViaUniversalFormat(DataSynchronizationSetup);
	
	// Transfer of information for processing the execution of the data exchange and the assistant Interactive data exchange.
	ValueToPass = New Structure;
	ExchangePlanNameToMigrateToNewExchange = SettingUpSynchronizationViaUniversalFormat.Metadata().Name;
	ValueToPass.Insert("ExchangePlanNameToMigrateToNewExchange", ExchangePlanNameToMigrateToNewExchange);
	ValueToPass.Insert("Code", SettingUpSynchronizationViaUniversalFormat.Code);
	
	TextToPass = "{MigrationToNewExchangeDone}"+Common.ValueToXMLString(ValueToPass);
	GetUserMessages(True); // Deleting previous messages.
	Common.MessageToUser(TextToPass);
	
EndProcedure

#EndRegion

#Region ExchangeOfUPRMC
// Registers changes on the transferred node, taking into account the Balance in the warehouse specified in the node settings
//
// Parameters:
//  Node - ExchangePlanRef.DataSynchronizationViaUniversalFormat
//
Procedure RegisterChangesOnNodeForBalancesInWarehouse(Node) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	DataSynchronizationViaUniversalFormatWarehouses.Ref AS Node,
	|	DataSynchronizationViaUniversalFormatWarehouses.Warehouse AS Warehouse
	|FROM
	|	ExchangePlan.DataSynchronizationViaUniversalFormat.Warehouses AS DataSynchronizationViaUniversalFormatWarehouses
	|WHERE
	|	DataSynchronizationViaUniversalFormatWarehouses.Ref.ExportItemsWithInventoryOnly
	|	AND DataSynchronizationViaUniversalFormatWarehouses.Ref = &Node
	|	AND DataSynchronizationViaUniversalFormatWarehouses.Ref.SettingsMode = &SettingsMode";
	
	Query.SetParameter("Node", Node);
	Query.SetParameter("SettingsMode", "ExchangeOfUPRMC");
	
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Return;
	EndIf;
		
	Warehouse = Selection.Warehouse;
	
	Query = New Query;
	Query.Text = 
	// The product with the Product list and characteristics is in the Balance in the warehouse specified in the selection
	// Barcodes are registered only according to the Product list that is on the Balance
	"SELECT
	|	StockBalance.Products AS Products,
	|	StockBalance.Characteristic AS Characteristic,
	|	StockBalance.Series AS Series,
	|	ISNULL(ItemsBarcodes.Barcode, &IsBlankString) AS Barcode
	|INTO RegistrationDataOnBalances
	|FROM
	|	AccumulationRegister.ProductStock.Balance(, Warehouse = &Warehouse) AS StockBalance
	|		LEFT JOIN InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		ON StockBalance.Products = ItemsBarcodes.Products
	|			AND StockBalance.Characteristic = ItemsBarcodes.Characteristic
	|WHERE
	|	StockBalance.InStockBalance > 0
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ObjectsDataToRegisterInExchanges.Ref AS LinkToRegistration
	|INTO DataOfRegisteredObjects
	|FROM
	|	InformationRegister.ObjectsDataToRegisterInExchanges AS ObjectsDataToRegisterInExchanges
	|WHERE
	|	ObjectsDataToRegisterInExchanges.InfobaseNode = &Node
	|INDEX BY
	|	LinkToRegistration
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemsBatches.Ref AS LinkToRegistration
	|INTO DataForRegistrationForReference
	|FROM
	|	Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		INNER JOIN Catalog.ItemsBatches AS ItemsBatches
	|		ON BatchAccountingPolicies.Ref = ItemsBatches.ProductKind
	|			AND (BatchAccountingPolicies.Warehouse = &Warehouse)
	|			AND (BatchAccountingPolicies.BatchAccountingPolicy.PolicyType IN (&PolicyType))
	|
	|UNION ALL
	|
	|SELECT
	|	Products.Ref
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	Products.ItemsType IN(&TypeOfProductServiceWork)
	|INDEX BY
	|	LinkToRegistration
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ItemsBarcodes.Products AS Products,
	|	ItemsBarcodes.Characteristic AS Characteristic,
	|	ItemsBarcodes.Series AS Series,
	|	ItemsBarcodes.Package AS Package,
	|	ItemsBarcodes.Barcode AS Barcode
	|INTO ChangeProductBarcodes
	|FROM
	|	InformationRegister.ItemsBarcodes.Changes AS ItemsBarcodes
	|WHERE
	|	ItemsBarcodes.Node = &Node
	|INDEX BY
	|	Barcode
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ModifiedSHK.Products AS Products,
	|	ModifiedSHK.Characteristic AS Characteristic,
	|	ModifiedSHK.Series AS Series,
	|	ModifiedSHK.Package AS Package,
	|	ModifiedSHK.Barcode AS Barcode
	|INTO ModifiedCCForRegisteredTuples
	|FROM
	|	InformationRegister.ItemsBarcodes.Changes AS ModifiedSHK
	|		INNER JOIN InformationRegister.ItemsBarcodes AS SHKData
	|		ON ModifiedSHK.Barcode = SHKData.Barcode
	|			AND ModifiedSHK.Products = SHKData.Products
	|			AND ModifiedSHK.Characteristic = SHKData.Characteristic
	|			AND ModifiedSHK.Series = SHKData.Series
	|			AND ModifiedSHK.Package = SHKData.Package
	|			INNER JOIN DataOfRegisteredObjects AS ItemSubmitted
	|			ON SHKData.Products = ItemSubmitted.LinkToRegistration
	|WHERE
	|	SHKData.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
    |
	|UNION ALL
    |
	|SELECT
	|	ModifiedSHK.Products AS Products,
	|	ModifiedSHK.Characteristic AS Characteristic,
	|	ModifiedSHK.Series AS Series,
	|	ModifiedSHK.Package AS Package,
	|	ModifiedSHK.Barcode
	|FROM
	|	InformationRegister.ItemsBarcodes.Changes AS ModifiedSHK
	|		INNER JOIN InformationRegister.ItemsBarcodes AS SHKData
	|		ON ModifiedSHK.Barcode = SHKData.Barcode
	|			AND ModifiedSHK.Products = SHKData.Products
	|			AND ModifiedSHK.Characteristic = SHKData.Characteristic
	|			AND ModifiedSHK.Series = SHKData.Series
	|			AND ModifiedSHK.Package = SHKData.Package
	|			INNER JOIN DataOfRegisteredObjects AS ItemSubmitted
	|			ON SHKData.Products = ItemSubmitted.LinkToRegistration
	|			INNER JOIN DataOfRegisteredObjects AS SentCharacteristic
	|			ON SHKData.Characteristic = SentCharacteristic.LinkToRegistration
	|WHERE
	|	SHKData.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|INDEX BY
	|	Barcode
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataForRegistration_.Products AS Products,
	|	DataForRegistration_.Characteristic AS Characteristic,
	|	DataForRegistration_.Series AS Series,
	|	DataForRegistration_.Barcode AS Barcode
	|INTO RegistrationOnBalanceOfSchool
	|FROM
	|	RegistrationDataOnBalances AS DataForRegistration_
	|		LEFT JOIN DataOfRegisteredObjects AS DataOfRegisteredItemsItem
	|		ON DataForRegistration_.Products = DataOfRegisteredItemsItem.LinkToRegistration
	|WHERE
	|	DataForRegistration_.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|	AND DataOfRegisteredItemsItem.LinkToRegistration IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DataForRegistration_.Products AS Products,
	|	DataForRegistration_.Characteristic AS Characteristic,
	|	DataForRegistration_.Series AS BatchBatch,
	|	DataForRegistration_.Barcode AS Barcode
	|	
	|FROM
	|	RegistrationDataOnBalances AS DataForRegistration_
	|		LEFT JOIN DataOfRegisteredObjects AS DataOfRegisteredItemsItem
	|		ON DataForRegistration_.Products = DataOfRegisteredItemsItem.LinkToRegistration
	|		LEFT JOIN DataOfRegisteredObjects AS DataOfRegisteredObjectsCharacteristics
	|		ON DataForRegistration_.Characteristic = DataOfRegisteredObjectsCharacteristics.LinkToRegistration
	|WHERE
	|	DataForRegistration_.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|	AND (DataOfRegisteredItemsItem.LinkToRegistration IS NULL
	|		OR DataOfRegisteredObjectsCharacteristics.LinkToRegistration IS NULL)
	|INDEX BY 
	|	Barcode 
	|;
	|
	|	
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataForRegistration_.Products AS Products
	|INTO ItemsForUploadingPrices
	|FROM
	|	RegistrationDataOnBalances AS DataForRegistration_
	|		LEFT JOIN DataOfRegisteredObjects AS DataOfRegisteredObjects
	|		ON DataForRegistration_.Products = DataOfRegisteredObjects.LinkToRegistration
	|WHERE
	|	DataOfRegisteredObjects.LinkToRegistration IS NULL
	|INDEX BY 
	|	Products
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ItemsForUploadingPrices.Products AS Products,
	|	Prices.Ref AS DocSettingPrices,
	|	Prices.Ref.Date AS DocDate
	|INTO SettingPricesByItem
	|FROM
	|	Document.PriceSetup.Goods AS Prices
	|		INNER JOIN ItemsForUploadingPrices AS ItemsForUploadingPrices
	|		ON Prices.Products = ItemsForUploadingPrices.Products
	|WHERE
	|	NOT &PriceManagementSystem25
	|	AND Prices.Ref.Approved
	|	AND Prices.Ref.Posted
	|	AND Prices.Ref.Date >= &DateOfDocUnloading
	|
	|UNION ALL 
	|
	|SELECT DISTINCT
	|	ItemsForUploadingPrices.Products,
	|	Prices.Ref,
	|	Prices.Ref.Date
	|FROM
	|	Document.PriceSetup.Goods2_5 AS Prices
	|		INNER JOIN ItemsForUploadingPrices AS ItemsForUploadingPrices
	|		ON Prices.Products = ItemsForUploadingPrices.Products
	|WHERE
	|	&PriceManagementSystem25
	|	AND Prices.Ref.Approved
	|	AND Prices.Ref.Posted
	|	AND Prices.Ref.Date >= &DateOfDocUnloading
	|INDEX BY 
	|	Products
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettingPricesByItem.Products AS Products,
	|	MAX(SettingPricesByItem.DocDate) AS DocDate
	|INTO ItemPriceDate
	|FROM
	|	SettingPricesByItem AS SettingPricesByItem
	|
	|GROUP BY
	|	SettingPricesByItem.Products
	|INDEX BY
	|	Products
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT  DISTINCT
	|	 LastPriceByItem.DocSettingPrices AS LinkToRegistration
	|INTO LateRegistrationOfPriceSettings
	|FROM
	|(SELECT
	|	SettingPricesByItem.Products AS Products,
	|	MAX(SettingPricesByItem.DocSettingPrices) AS DocSettingPrices
	|FROM
	|	SettingPricesByItem AS SettingPricesByItem
	|	INNER JOIN ItemPriceDate AS ItemPriceDate
	|		ON SettingPricesByItem.Products = ItemPriceDate.Products
	|		AND SettingPricesByItem.DocDate = ItemPriceDate.DocDate
	|
	|GROUP BY
	|	SettingPricesByItem.Products) LastPriceByItem
	|INDEX BY
	|	LinkToRegistration
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT 
	|	ItemsBarcodes.Products AS Products, 
	|	ItemsBarcodes.Characteristic AS Characteristic, 
	|	ItemsBarcodes.Series AS Series, 
	|	ItemsBarcodes.Package AS Package, 
	|	ItemsBarcodes.Barcode AS Barcode
	|FROM RegistrationOnBalanceOfSchool AS RegistrationOnBalanceOfSchool
	|	LEFT JOIN ChangeProductBarcodes AS ModifiedSHK
	|	ON RegistrationOnBalanceOfSchool.Barcode = ModifiedSHK.Barcode
	|		AND RegistrationOnBalanceOfSchool.Products = ModifiedSHK.Products
	|		AND RegistrationOnBalanceOfSchool.Characteristic = ModifiedSHK.Characteristic
	|		AND RegistrationOnBalanceOfSchool.Series = ModifiedSHK.Series
	|	INNER JOIN InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|	ON RegistrationOnBalanceOfSchool.Products = ItemsBarcodes.Products
	|		AND RegistrationOnBalanceOfSchool.Characteristic = ItemsBarcodes.Characteristic
	|		AND RegistrationOnBalanceOfSchool.Series = ItemsBarcodes.Series
	|		AND RegistrationOnBalanceOfSchool.Barcode = ItemsBarcodes.Barcode
	|WHERE
	|	ModifiedSHK.Barcode IS NULL
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ItemsBarcodes.Products AS Products,
	|	ItemsBarcodes.Characteristic AS Characteristic,
	|	ItemsBarcodes.Series AS Series,
	|	ItemsBarcodes.Package AS Package,
	|	ItemsBarcodes.Barcode AS Barcode
	|FROM
	|	ChangeProductBarcodes AS ItemsBarcodes
	|		LEFT JOIN ModifiedCCForRegisteredTuples AS PreviouslySentTuplesOfSHK
	|		ON ItemsBarcodes.Barcode = PreviouslySentTuplesOfSHK.Barcode
	|		LEFT JOIN RegistrationOnBalanceOfSchool AS RegistrationOnBalanceOfSchool
	|		ON ItemsBarcodes.Barcode = RegistrationOnBalanceOfSchool.Barcode
	|WHERE
	|	RegistrationOnBalanceOfSchool.Barcode IS NULL
	|	AND PreviouslySentTuplesOfSHK.Barcode IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataForRegistration_.Products AS DataForRegistration_
	|FROM
	|	RegistrationDataOnBalances AS DataForRegistration_
	|		LEFT JOIN DataOfRegisteredObjects AS DataOfRegisteredObjects
	|		ON DataForRegistration_.Products = DataOfRegisteredObjects.LinkToRegistration
	|WHERE
	|	DataOfRegisteredObjects.LinkToRegistration IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	DataForRegistration_.Characteristic
	|FROM
	|	RegistrationDataOnBalances AS DataForRegistration_
	|		LEFT JOIN DataOfRegisteredObjects AS DataOfRegisteredObjects
	|		ON DataForRegistration_.Characteristic = DataOfRegisteredObjects.LinkToRegistration
	|WHERE
	|	DataOfRegisteredObjects.LinkToRegistration IS NULL
	|	AND NOT DataForRegistration_.Characteristic = &EmptyCharacteristic
	|
	|UNION ALL
	|
	|SELECT
	|	DataForRegistration_.Series
	|FROM
	|	RegistrationDataOnBalances AS DataForRegistration_
	|		LEFT JOIN DataOfRegisteredObjects AS DataOfRegisteredObjects
	|		ON DataForRegistration_.Series = DataOfRegisteredObjects.LinkToRegistration
	|WHERE
	|	DataOfRegisteredObjects.LinkToRegistration IS NULL
	|	AND NOT DataForRegistration_.Series = &EmptyBatch_
	|
	|UNION ALL
	|
	|SELECT
	|	LateRegistrationOfPriceSettings.LinkToRegistration
	|FROM
	|	LateRegistrationOfPriceSettings AS LateRegistrationOfPriceSettings
	|	LEFT JOIN DataOfRegisteredObjects AS Registrations
	|		ON LateRegistrationOfPriceSettings.LinkToRegistration = Registrations.LinkToRegistration
	|WHERE
	|	Registrations.LinkToRegistration IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DataForRegistration_.LinkToRegistration
	|FROM
	|	DataForRegistrationForReference AS DataForRegistration_
	|		LEFT JOIN DataOfRegisteredObjects AS DataOfRegisteredObjects
	|		ON DataForRegistration_.LinkToRegistration = DataOfRegisteredObjects.LinkToRegistration
	|WHERE
	|	DataOfRegisteredObjects.LinkToRegistration IS NULL";
	
	TypesOfPolicySeriesReferenceIndication = New Array;
	TypesOfPolicySeriesReferenceIndication.Add(Enums.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification);
	TypesOfPolicySeriesReferenceIndication.Add(Enums.TypesOfBatchSpecificationPolicies.FEFOAutoCalculationOfRemainingBatch);
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	
	Query.SetParameter("Node", Node);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("SettingsMode", "SURMKExchange");
	Query.SetParameter("EmptyCharacteristic", Catalogs.ItemsCharacteristics.EmptyRef());
	Query.SetParameter("EmptyBatch_", Catalogs.ItemsBatches.EmptyRef());
	Query.SetParameter("IsBlankString", "");
	Query.SetParameter("PolicyType", TypesOfPolicySeriesReferenceIndication);
	Query.SetParameter("TypeOfProductServiceWork", ArrayOfProductTypes);
	Query.SetParameter("PriceManagementSystem25", GetFunctionalOption("UsePriceManagementSystem25"));
	Query.SetParameter("DateOfDocUnloading", Common.ObjectAttributeValue(Node, "DocumentsExportStartDate"));
	
	QueryResult = Query.ExecuteBatch();
	ChangesToObjects = QueryResult[QueryResult.UBound()].Unload();
	
	DataForRegistration_ = ChangesToObjects.UnloadColumn("DataForRegistration_");
	If DataForRegistration_.Count() > 0 Then
		ExchangePlans.RecordChanges(Node, DataForRegistration_);
	EndIf;
	
	For Each Data In DataForRegistration_ Do
		InformationRegisters.ObjectsDataToRegisterInExchanges.AddObjectToAllowedObjectsFilter(Data, Node);
	EndDo;
	
	BarcodeChanges = QueryResult[QueryResult.UBound()-1].Unload();
	Set = InformationRegisters.ItemsBarcodes.CreateRecordSet();
	
	// We delete the registration of changes by barcodes, the Products of which are not on the Balance.
	For Each BarcodeData_1 In BarcodeChanges Do
		Set.Filter.Barcode.Set(BarcodeData_1.Barcode, True);
		Set.Filter.Products.Set(BarcodeData_1.Products, True);
		Set.Filter.Characteristic.Set(BarcodeData_1.Characteristic, True);
		Set.Filter.Series.Set(BarcodeData_1.Series, True);
		Set.Filter.Package.Set(BarcodeData_1.Package, True);
		Set.Read();
		ExchangePlans.DeleteChangeRecords(Node, Set);
	EndDo;
	
	// Adding a late registration of the SHK in the exchange
	LatePrimaryUnloadingOfSHK = QueryResult[QueryResult.UBound()-2].Unload();
	Set = InformationRegisters.ItemsBarcodes.CreateRecordSet();
	For Each BarcodeData_1 In LatePrimaryUnloadingOfSHK Do
		Set.Filter.Barcode.Set(BarcodeData_1.Barcode, True);
		Set.Filter.Products.Set(BarcodeData_1.Products, True);
		Set.Filter.Characteristic.Set(BarcodeData_1.Characteristic, True);
		Set.Filter.Series.Set(BarcodeData_1.Series, True);
		Set.Filter.Package.Set(BarcodeData_1.Package, True);
		Set.Read();
		ExchangePlans.RecordChanges(Node, Set);
	EndDo;
	
EndProcedure

// Filling in the dependent Attributes for setting up the UPRMC.
// based on the current values of the Cash Register cash registers, other Attributes are set.
// Parameters:
//	Object - ExchangePlanObject.DataSynchronizationViaUniversalFormat
Procedure UpdateDependentSelections(Object) Export

	If Object.SettingsMode <> "ExchangeOfUPRMC" Then
		
		Return;
		
	EndIf;
	
	Object.Companies.Clear();
	Object.UseFilterByCompanies = True;
	Object.Warehouses.Clear();
	Object.WarehousesOfInformativeBalance.Clear();
	Object.UseFilterByWarehouses = Object.UseFilterByCashRegisters;
	Object.ProductPricesTypes.Clear();
	Object.DocumentsKinds.Clear();
	Object.UploadProductPrices = True;
	
	If Object.CashRegisters.Count() = 0 Then
		Object.POSTerminals.Clear(); 
		Object.PaymentSystemContracts.Clear(); 
		
		Return;
		
	EndIf;
	
	RequestingCollections = New Query;
	RequestingCollections.Text = 
	"SELECT
	|	CashRegisters.Ref AS CashRegister,
	|	CashRegisters.Warehouse AS CashRegister_Warehouse
	|INTO TimeOfCashRegisterCashAccount
	|FROM
	|	Catalog.CashRegisters AS CashRegisters
	|WHERE
	|	NOT CashRegisters.DeletionMark
	|	AND CashRegisters.CashRegisterType = VALUE(Enum.CashRegisterTypes.StandaloneCWP)
	|	AND CashRegisters.Ref IN(&CurrentCashRegisterCashAccounts)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TimeOfCashRegisterCashAccount.CashRegister.Owner AS CashAccountCompany
	|INTO CashRegisterOrganizations
	|FROM
	|	TimeOfCashRegisterCashAccount AS TimeOfCashRegisterCashAccount
	|WHERE
	|	TimeOfCashRegisterCashAccount.CashRegister.Ref IS NOT NULL 
	|
	|INDEX BY
	|	CashAccountCompany
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TimeOfCashRegisterCashAccount.CashRegister_Warehouse AS CashRegister_Warehouse
	|INTO CashRegisterWarehouses
	|FROM
	|	TimeOfCashRegisterCashAccount AS TimeOfCashRegisterCashAccount
	|WHERE
	|	TimeOfCashRegisterCashAccount.CashRegister_Warehouse.Ref IS NOT NULL 
	|
	|INDEX BY
	|	CashRegister_Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	POSTerminals.Ref AS POSTerminal
	|FROM
	|	Catalog.POSTerminals AS POSTerminals
	|		INNER JOIN CashRegisterOrganizations AS CashRegisterOrganizations
	|		ON POSTerminals.Owner.Organization = CashRegisterOrganizations.CashAccountCompany
	|WHERE
	|	POSTerminals.Ref IN(&CurrentEqTerminals)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AcquiringContracts.Ref AS ConnectionContract
	|FROM
	|	Catalog.AcquiringContracts AS AcquiringContracts
	|		INNER JOIN CashRegisterOrganizations AS CashRegisterOrganizations
	|		ON AcquiringContracts.Organization = CashRegisterOrganizations.CashAccountCompany
	|WHERE
	|	AcquiringContracts.Ref IN(&CurrentEqContracts)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CashRegisterWarehouses.CashRegister_Warehouse.RetailPriceType AS ProductPricesType
	|FROM
	|	CashRegisterWarehouses AS CashRegisterWarehouses
	|WHERE
	|	CashRegisterWarehouses.CashRegister_Warehouse.RetailPriceType.Ref IS NOT NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CashRegisterWarehouses.CashRegister_Warehouse AS Warehouse
	|FROM
	|	CashRegisterWarehouses AS CashRegisterWarehouses
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CashRegisterOrganizations.CashAccountCompany AS Organization
	|FROM
	|	CashRegisterOrganizations AS CashRegisterOrganizations";
	
	RequestingCollections.Parameters.Insert("CurrentCashRegisterCashAccounts", 
		Object.CashRegisters.Unload().UnloadColumn("CashRegister"));
	RequestingCollections.Parameters.Insert("CurrentEqTerminals", 
		Object.POSTerminals.Unload().UnloadColumn("POSTerminal"));
	RequestingCollections.Parameters.Insert("CurrentEqContracts", 
		Object.PaymentSystemContracts.Unload().UnloadColumn("ConnectionContract"));
	QueryResults = RequestingCollections.ExecuteBatch();
	PackageSize = QueryResults.Count();
	
	Object.Companies.Load(QueryResults[PackageSize-1].Unload());
	Object.Warehouses.Load(QueryResults[PackageSize-2].Unload());
	
	If Object.UploadInformativeBalance Then
		Object.WarehousesOfInformativeBalance.Load(QueryResults[PackageSize-2].Unload());
	EndIf;
	
	Object.ProductPricesTypes.Load(QueryResults[PackageSize-3].Unload());
	Object.PaymentSystemContracts.Load(QueryResults[PackageSize-4].Unload());
	Object.POSTerminals.Load(QueryResults[PackageSize-5].Unload());

EndProcedure

#EndRegion

#Region ExchangeSettingOptionIDs

 // Returns the ID of the exchange setup with BP 3.0 (PROF).
//
// Returns:
//   String - setting ID
//
Function IdOfExchangeSetupBP30() Export
	
	// Corresponds to "SwappBP30" in pre-versions.
	SettingID = "ERP_BP3Exchange";
	If GetFunctionalOption("TradeManagement") Then
		
		SettingID = "UT_BP3Exchange";
		
	EndIf;
	
	Return SettingID;
	
EndFunction

// Returns the ID of the exchange setup with BP 3.0 (CORP).
//
// Returns:
//   String - setting ID
//
Function IdOfExchangeSetupBPCORP30() Export
	
	// Corresponds to "Exchange CORP30" in pre-versions.
	SettingID = "ERP_BPCORP30Exchange";
	If GetFunctionalOption("TradeManagement") Then
		
		SettingID = "ExchangeUT_BPCORP30";
		
	EndIf;
	
	Return SettingID;
	
EndFunction

// Returns the ID of the exchange settings of the base UT with BP 3.0 (PROF).
//
// Returns:
//   String - setting ID
//
Function IdOfBasicUTBP30ExchangeSetup() Export
	
	// Corresponds to the "exchange of TP" in pre-versions.
	Return "UTB_BP3Exchange";
	
EndFunction

// Returns the ID of setting up exchanges with 1C:Document Management 3.0
//
// Returns:
//   String - setting ID
//
Function IdOfWorkflowExchangeSettings() Export
	
	Return "DoupExchange";
	
EndFunction

// Returns the ID of the universal exchange setting
//
// Returns:
//   String - setting ID
//
Function IdOfExchangeSettingsIsUniversal() Export
	
	Return "UniversalExchange";
	
EndFunction

#EndRegion

// This is the setup ID from BP3.
// 
// Parameters:
//  SettingID - String - setting ID
// 
// Returns:
//  Boolean
Function ThisIsIdOfSBP3Setting(SettingID) Export
	
	If IsBlankString(SettingID) Then
		Return False;
	EndIf;
	
	OptionsForFPS3Settings = New Array;
	
	OptionsForFPS3Settings.Add("UpbpExchange");
	OptionsForFPS3Settings.Add(ExchangePlans.DataSynchronizationViaUniversalFormat.IdOfExchangeSetupBP30());
	OptionsForFPS3Settings.Add(ExchangePlans.DataSynchronizationViaUniversalFormat.IdOfExchangeSetupBPCORP30()); 
	
	ThisIsOptionForConfiguringFPS3 = OptionsForFPS3Settings.Find(SettingID) <> Undefined; 
	
	Return ThisIsOptionForConfiguringFPS3;
	
EndFunction

#EndRegion

#EndIf