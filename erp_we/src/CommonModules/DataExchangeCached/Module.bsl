///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ObsoleteProceduresAndFunctions

// Deprecated. Instead, use the new function
//  See DataExchangeServer.IsStandaloneWorkplace.
// 
// Returns:
//  Boolean
//
Function IsStandaloneWorkplace() Export
	
	Return StandaloneWorkstationMode();
	
EndFunction

// Deprecated. Instead, use the new function
//  See DataExchangeServer.ExchangePlanNodeByCode.
// 
// Parameters:
//  ExchangePlanName - String -  Exchange plan name
//  NodeCode - String - Node code
// 
// Returns:
//   See DataExchangeServer.ExchangePlanNodeByCode
//
Function FindExchangePlanNodeByCode(ExchangePlanName, NodeCode) Export
	
	TextTemplate1 = "ExchangePlan.%1";
	NameOfTheStringExchangePlan = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, ExchangePlanName);
	
	QueryText =
	"SELECT
	|	ExchangePlan.Ref AS Ref
	|FROM
	|	&ExchangePlanName AS ExchangePlan
	|WHERE
	|	ExchangePlan.Code = &Code";
	
	QueryText = StrReplace(QueryText, "&ExchangePlanName", NameOfTheStringExchangePlan);
	
	Query = New Query;
	Query.SetParameter("Code", NodeCode);
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		Return Undefined;
		
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	Return Selection.Ref;
EndFunction

#EndRegion

#EndRegion

#Region Internal

// See DataExchangeServer.IsStandaloneWorkplace.
Function StandaloneWorkstationMode() Export
	
	SetPrivilegedMode(True);
	
	If Constants.SubordinateDIBNodeSetupCompleted.Get() Then
		
		Return Constants.IsStandaloneWorkplace.Get();
		
	Else
		
		MasterNodeOfThisInfobase = DataExchangeServer.MasterNode();
		Return MasterNodeOfThisInfobase <> Undefined
			And IsStandaloneWorkstationNode(MasterNodeOfThisInfobase);
		
	EndIf;
	
EndFunction

// Returns a flag that shows whether an exchange plan is used in data exchange.
// If an exchange plan contains at least one node apart from the predefined one,
// it is considered being used in data exchange.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//  Sender - ExchangePlanRef - the parameter value is set if it is necessary
//   to determine whether there are other exchange nodes besides the one from
//   which the object was received.
//
// Returns:
//  Boolean -  If True, exchange plan is used. Otherwise, False.
//
Function DataExchangeEnabled(Val ExchangePlanName, Val Sender = Undefined) Export
	
	If Not GetFunctionalOption("UseDataSynchronization") Then
		
		Return False;
		
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	&MetadataTableName AS ExchangePlan
	|WHERE
	|	NOT ExchangePlan.DeletionMark
	|	AND NOT ExchangePlan.ThisNode
	|	AND ExchangePlan.Ref <> &Sender";
	
	ReplacementString = StringFunctionsClientServer.SubstituteParametersToString("ExchangePlan.%1", ExchangePlanName);
	QueryText = StrReplace(QueryText, "&MetadataTableName", ReplacementString);
	
	Query = New Query(QueryText);
	Query.SetParameter("Sender", Sender);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// See DataExchangeServer.IsStandaloneWorkstationNode.
Function IsStandaloneWorkstationNode(Val InfobaseNode) Export
	
	Return DataExchangeCached.StandaloneModeSupported()
		And DataExchangeCached.GetExchangePlanName(InfobaseNode) = DataExchangeCached.StandaloneModeExchangePlan();
	
EndFunction

// Returns the flag showing whether the node belongs to DIB exchange plan.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
//
//  Returns:
//    Boolean - If True, the node belongs to the exchange plan of the distributed infobase. Otherwise, False.
//
Function IsDistributedInfobaseNode(Val InfobaseNode) Export

	Return InfobaseNode.Metadata().DistributedInfoBase;
	
EndFunction

// See DataExchangeServer.ExchangePlanSettings
Function ExchangePlanSettings(ExchangePlanName, CorrespondentVersion = "", CorrespondentName = "", CorrespondentInSaaS = Undefined) Export
	Return DataExchangeServer.ExchangePlanSettings(ExchangePlanName, CorrespondentVersion, CorrespondentName, CorrespondentInSaaS);
EndFunction

// See DataExchangeServer.SettingOptionDetails
Function SettingOptionDetails(ExchangePlanName, SettingID, 
								CorrespondentVersion = "", CorrespondentName = "") Export
	Return DataExchangeServer.SettingOptionDetails(ExchangePlanName, SettingID, 
								CorrespondentVersion, CorrespondentName);
EndFunction
////////////////////////////////////////////////////////////////////////////////
// The mechanism for registering objects on exchange plan nodes (MRO).

// Gets the name of this infobase from a constant or a configuration synonym.
// (For internal use only).
// 
// Returns:
//  String
//
Function ThisInfobaseName() Export
	
	SetPrivilegedMode(True);
	
	Result = Constants.SystemTitle.Get();
	
	If IsBlankString(Result) Then
		
		Result = Metadata.Synonym;
		
	EndIf;
	
	Return Result;
EndFunction

// Gets a code of a predefined exchange plan node.
// 
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
// 
// Returns:
//  String - a code of a predefined exchange plan node.
//
Function GetThisNodeCodeForExchangePlan(ExchangePlanName) Export
	
	Return Common.ObjectAttributeValue(GetThisExchangePlanNode(ExchangePlanName), "Code");
	
EndFunction

// Gets a name of a predefined exchange plan node.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node.
// 
// Returns:
//  String - a name of a predefined exchange plan node.
//
Function ThisNodeDescription(Val InfobaseNode) Export
	
	Return String(GetThisExchangePlanNode(GetExchangePlanName(InfobaseNode)));
	
EndFunction

// Gets an array of names of configuration exchange plans that use the SSL functionality.
//
// Parameters:
//  No.
// 
// Returns:
//   Array - an array of exchange plan name items.
//
Function SSLExchangePlans() Export
	
	Return SSLExchangePlansList().UnloadValues();
	
EndFunction

// Determines whether an exchange plan specified by name is used in SaaS mode.
// For this purpose, all exchange plans on their manager module level
// define the ExchangePlanUsedInSaaS() function
// which explicitly returns True or False.
//
// Parameters:
//   ExchangePlanName - String
//
// Returns:
//   Boolean
//
Function ExchangePlanUsedInSaaS(Val ExchangePlanName) Export
	
	Result = False;
	
	If SSLExchangePlans().Find(ExchangePlanName) <> Undefined Then
		Result = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName,
			"ExchangePlanUsedInSaaS", "");
	EndIf;
	
	Return Result;
	
EndFunction

// Fills in the list of possible error codes.
//
// Returns:
//  Map of KeyAndValue:
//    * Key - Number - error code
//    * Value - String - error details
//
Function ErrorsMessages() Export
	
	ErrorsMessages = New Map;
		
	ErrorsMessages.Insert(2,  NStr("vi = 'Lỗi giải nén tệp trao đổi. Tệp đã bị phong tỏa.';
									|ru = 'Ошибка распаковки файла обмена. Файл заблокирован.';
									|en = 'Error extracting exchange file. File is locked.'; fa = 'Error extracting exchange file. File is locked.';
									|it = 'Errore della decompressione del file di scambio. Il file è bloccato.';
									|pl = 'Błąd rozpakowania pliku wymiany. Plik jest zablokowany.';
									|tr = 'Bir değişim dosyasını paketinden çıkarılırken bir hata oluştu. Dosya kilitli.'"));
	ErrorsMessages.Insert(3,  NStr("vi = 'Không tồn tại tệp quy tắc trao đổi đã chỉ ra.';
									|ru = 'Указанный файл правил обмена не существует.';
									|en = 'The exchange rules file does not exist.'; fa = 'The exchange rules file does not exist.';
									|it = 'Il file delle regole di scambio specificato non esiste.';
									|pl = 'Wskazany plik reguł wymiany nie istnieje.';
									|tr = 'Belirtilen değişim kuralları dosyası mevcut değil.'"));
	ErrorsMessages.Insert(4,  NStr("vi = 'Lỗi khi tạo đối tượng COM Msxml2.DOMDocument';
									|ru = 'Ошибка при создании COM-объекта Msxml2.DOMDocument';
									|en = 'Cannot create COM object: Msxml2.DOMDocument'; fa = 'Cannot create COM object: Msxml2.DOMDocument';
									|it = 'Errore durante la creazione dell''oggetto COM Msxml2.DOMDocument';
									|pl = 'Błąd przy utworzeniu Obiektu COM Msxml2.DOMDocument';
									|tr = 'Msxml2.DOMDocument COM nesnesi oluştururken bir hata oluştu'"));
	ErrorsMessages.Insert(5,  NStr("vi = 'Lỗi mở tệp trao đổi';
									|ru = 'Ошибка открытия файла обмена';
									|en = 'Error opening exchange file'; fa = 'Error opening exchange file';
									|it = 'Errore durante l''apertura del file di scambio';
									|pl = 'Błąd otwarcia pliku wymiany';
									|tr = 'Değişim dosyası açılırken bir hata oluştu'"));
	ErrorsMessages.Insert(6,  NStr("vi = 'Lỗi khi kết nhập quy tắc trao đổi';
									|ru = 'Ошибка при загрузке правил обмена';
									|en = 'Error importing exchange rules'; fa = 'Error importing exchange rules';
									|it = 'Errore durante il download delle regole di scambio';
									|pl = 'Błąd podczas pobierania reguł wymiany';
									|tr = 'Değişim kuralları içe aktarılırken bir hata oluştu'"));
	ErrorsMessages.Insert(7,  NStr("vi = 'Lỗi định dạng quy tắc trao đổi';
									|ru = 'Ошибка формата правил обмена';
									|en = 'Exchange rule format error'; fa = 'Exchange rule format error';
									|it = 'Errore nel formato delle regole di scambio';
									|pl = 'Błąd formatu reguł wymiany';
									|tr = 'Değişim kuralı biçiminde hata'"));
	ErrorsMessages.Insert(8,  NStr("vi = 'Đã chỉ ra sai tên tệp để kết xuất dữ liệu';
									|ru = 'Некорректно указано имя файла для выгрузки данных';
									|en = 'Invalid data export file name'; fa = 'Invalid data export file name';
									|it = 'È indicato il nome di file errato per upload dei dati';
									|pl = 'Niepoprawnie jest wskazana nazwa pliku do pobierania danych';
									|tr = 'Veri dışa aktarma için belirtilen dosya adı yanlıştır'"));
	ErrorsMessages.Insert(9,  NStr("vi = 'Lỗi định dạng tệp trao đổi';
									|ru = 'Ошибка формата файла обмена';
									|en = 'Exchange file format error'; fa = 'Exchange file format error';
									|it = 'Errore nel formato del file di scambio';
									|pl = 'Błąd formatu pliku wymiany';
									|tr = 'Değişim dosyası biçiminde hata'"));
	ErrorsMessages.Insert(10, NStr("vi = 'Chưa chỉ ra tên tệp để kết xuất dữ liệu (Tên tệp dữ liệu)';
									|ru = 'Не указано имя файла для выгрузки данных (Имя файла данных)';
									|en = 'Data export file name is not specified'; fa = 'Data export file name is not specified';
									|it = 'Non è specificato il nome del file per upload dei dati (Nome file di dati)';
									|pl = 'Nie jest wskazana nazwa pliku do pobierania danych (Nazwa pliku danych)';
									|tr = 'Veri dışa aktarma için dosya adı belirtilmemiş (Veri dosyasının adı)'"));
	ErrorsMessages.Insert(11, NStr("vi = 'Tham chiếu đến đối tượng metadata không tồn tại trong quy tắc trao đổi';
									|ru = 'Ссылка на несуществующий объект метаданных в правилах обмена';
									|en = 'Exchange rules reference a metadata object that does not exist'; fa = 'Exchange rules reference a metadata object that does not exist';
									|it = 'Il link ad un oggetto di metadati inesistente nelle regole di scambio';
									|pl = 'Odnośnik do nie istniejącego obiektu metadanych w regułach wymiany';
									|tr = 'Değişim kurallarında varolan bir meta veri nesnesine bağlanma'"));
	ErrorsMessages.Insert(12, NStr("vi = 'Chưa chỉ ra tên tệp có quy tắc trao đổi (Tên tệp quy tắc)';
									|ru = 'Не указано имя файла с правилами обмена (Имя файла правил)';
									|en = 'Exchange rules file name is not specified'; fa = 'Exchange rules file name is not specified';
									|it = 'Non è specificato il nome del file con regole di scambio (Nome file delle regole)';
									|pl = 'Nie jest wskazana nazwa pliku z regułami wymiany (Nazwa pliku reguł)';
									|tr = 'Değişim kuralları ile dosya adı belirtilmemiş (Kural dosyasının adı)'"));
			
	ErrorsMessages.Insert(13, NStr("vi = 'Lỗi nhận giá trị thuộc tính đối tượng (theo tên thuộc tính nguồn)';
									|ru = 'Ошибка получения значения свойства объекта (по имени свойства источника)';
									|en = 'Error getting value of object property by property name in source infobase'; fa = 'Error getting value of object property by property name in source infobase';
									|it = 'Errore nell''acquisizione del valore di proprietà dell''oggetto (per nome della proprietà di origine)';
									|pl = 'Błąd pobierania wartości właściwości obiektu (wg nazwy właściwości źródła)';
									|tr = 'Nesne özelliğinin bir değeri alınırken bir hata oluştu (kaynak özelliği adıyla)'"));
	ErrorsMessages.Insert(14, NStr("vi = 'Lỗi nhận giá trị thuộc tính đối tượng (theo tên thuộc tính đích)';
									|ru = 'Ошибка получения значения свойства объекта (по имени свойства приемника)';
									|en = 'Error getting value of object property by property name in destination infobase'; fa = 'Error getting value of object property by property name in destination infobase';
									|it = 'Errore nell''acquisizione del valore di proprietà dell''oggetto (per nome della proprietà di ricevente)';
									|pl = 'Błąd pobierania wartości właściwości obiektu (wg nazwy właściwości odbiornika)';
									|tr = 'Nesne özelliği değerini alınırken bir hata oluştu (hedef özellik adına göre)'"));
	
	ErrorsMessages.Insert(15, NStr("vi = 'Chưa chỉ ra tên tệp để kết nhập dữ liệu (Tên tệp để kết nhập)';
									|ru = 'Не указано имя файла для загрузки данных (Имя файла для загрузки)';
									|en = 'Data import file name is not specified'; fa = 'Data import file name is not specified';
									|it = 'Non è specificato il nome del file per download dei dati (Nome del file da caricare)';
									|pl = 'Nie jest wskazana nazwa pliku do pobierania danych (Nazwa pliku do pobierania)';
									|tr = 'Veri dışa aktarma için dosya adı belirtilmemiş (İçe aktarılacak dosyasının adı)'"));
			
	ErrorsMessages.Insert(16, NStr("vi = 'Lỗi nhận giá trị thuộc tính đối tượng trực thuộc (theo tên thuộc tính nguồn)';
									|ru = 'Ошибка получения значения свойства подчиненного объекта (по имени свойства источника)';
									|en = 'Error getting value of subordinate object property by property name in source infobase'; fa = 'Error getting value of subordinate object property by property name in source infobase';
									|it = 'Errore nell''acquisizione del valore di proprietà dell''oggetto subordinato (per nome della proprietà di origine)';
									|pl = 'Błąd pobierania wartości właściwości podporządkowanego obiektu (wg nazwy właściwości źródła)';
									|tr = 'Alt nesne özelliğinin değeri alınırken bir hata oluştu (kaynak özellik adına göre)'"));
	ErrorsMessages.Insert(17, NStr("vi = 'Lỗi nhận giá trị thuộc tính đối tượng trực thuộc (theo tên thuộc tính đích)';
									|ru = 'Ошибка получения значения свойства подчиненного объекта (по имени свойства приемника)';
									|en = 'Error getting value of subordinate object property by property name in destination infobase'; fa = 'Error getting value of subordinate object property by property name in destination infobase';
									|it = 'Errore nell''acquisizione del valore di proprietà dell''oggetto subordinato (per nome della proprietà di ricevente)';
									|pl = 'Błąd pobierania wartości właściwości podporządkowanego obiektu (wg nazwy właściwości odbiornika)';
									|tr = 'Alt nesne özelliğinin değeri alınırken bir hata oluştu (kaynak özellik adına göre)'"));
	ErrorsMessages.Insert(18, NStr("vi = 'Lỗi khi tạo bộ xử lý có mã của hàm sự kiện';
									|ru = 'Ошибка при создании обработки с кодом обработчиков';
									|en = 'Error creating data processor with handlers code'; fa = 'Error creating data processor with handlers code';
									|it = 'Errore durante la creazione di elaborazione con il codice dei processori';
									|pl = 'Błąd podczas utworzenia przetwarzania z kodem programów przetwarzania';
									|tr = 'İşleyici koduyla bir veri işlemci oluştururken bir hata oluştu'"));
	ErrorsMessages.Insert(19, NStr("vi = 'Lỗi trong hàm sự kiện ПередЗагрузкойОбъекта';
									|ru = 'Ошибка в обработчике события ПередЗагрузкойОбъекта';
									|en = 'Event handler error: BeforeImportObject'; fa = 'Event handler error: BeforeImportObject';
									|it = 'Errore nel gestore dell''evento PrimaDiDownloadOggetto';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПередЗагрузкойОбъекта';
									|tr = 'ПередЗагрузкойОбъекта olayın işleyicisinde hata oluştu'"));
	ErrorsMessages.Insert(20, NStr("vi = 'Lỗi trong hàm sự kiện ПриЗагрузкеОбъекта';
									|ru = 'Ошибка в обработчике события ПриЗагрузкеОбъекта';
									|en = 'Event handler error: OnImportObject'; fa = 'Event handler error: OnImportObject';
									|it = 'Errore nel gestore dell''evento DuranteDownloadOggetto';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПриЗагрузкеОбъекта';
									|tr = 'ПриЗагрузкеОбъекта olayın işleyicisinde hata oluştu'"));
	ErrorsMessages.Insert(21, NStr("vi = 'Lỗi trong hàm sự kiện ПослеЗагрузкиОбъекта';
									|ru = 'Ошибка в обработчике события ПослеЗагрузкиОбъекта';
									|en = 'Event handler error: AfterImportObject'; fa = 'Event handler error: AfterImportObject';
									|it = 'Errore nel gestore dell''evento DopoDownloadOggetto';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПослеЗагрузкиОбъекта';
									|tr = 'ПослеЗагрузкиОбъекта olayın işleyicisinde hata oluştu'"));
	ErrorsMessages.Insert(22, NStr("vi = 'Lỗi trong hàm sự kiện ПередЗагрузкойДанных (chuyển đổi)';
									|ru = 'Ошибка в обработчике события ПередЗагрузкойДанных (конвертация)';
									|en = 'Event handler error (data conversion): BeforeDataImport'; fa = 'Event handler error (data conversion): BeforeDataImport';
									|it = 'Errore nel gestore dell''evento PrimaDiDownloadDati (conversione)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПередЗагрузкойДанных (konwersja)';
									|tr = 'ПередЗагрузкойДанных olay işleyicisinde bir hata oluştu (dönüştürme)'"));
	ErrorsMessages.Insert(23, NStr("vi = 'Lỗi trong hàm sự kiện ПослеЗагрузкиДанных (chuyển đổi)';
									|ru = 'Ошибка в обработчике события ПослеЗагрузкиДанных (конвертация)';
									|en = 'Event handler error (data conversion): AfterImportData'; fa = 'Event handler error (data conversion): AfterImportData';
									|it = 'Errore nel gestore dell''evento DopoDownloadDati (conversione)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПослеЗагрузкиДанных (konwersja)';
									|tr = 'ПослеЗагрузкиДанных olay işleyicisinde bir hata oluştu (dönüştürme)'"));
	ErrorsMessages.Insert(24, NStr("vi = 'Lỗi khi xóa đối tượng';
									|ru = 'Ошибка при удалении объекта';
									|en = 'An error occurred when deleting the object'; fa = 'An error occurred when deleting the object';
									|it = 'Errore durante eliminazione dell''oggetto';
									|pl = 'Błąd podczas usuwania obiektu';
									|tr = 'Nesne silinirken bir hata oluştu'"));
	ErrorsMessages.Insert(25, NStr("vi = 'Lỗi khi ghi lại chứng từ';
									|ru = 'Ошибка при записи документа';
									|en = 'Error writing document'; fa = 'Error writing document';
									|it = 'Errore durante la scrittura del documento';
									|pl = 'Błąd podczas zapisywania dokumentu';
									|tr = 'Belge yazılırken bir hata oluştu'"));
	ErrorsMessages.Insert(26, NStr("vi = 'Lỗi ghi lại đối tượng';
									|ru = 'Ошибка записи объекта';
									|en = 'Object writing error'; fa = 'Object writing error';
									|it = 'Errore di scrittura oggetto';
									|pl = 'Błąd zapisu obiektu';
									|tr = 'Nesne kaydında hata'"));
	ErrorsMessages.Insert(27, NStr("vi = 'Lỗi trong hàm sự kiện ПередОбработкойПравилаОчистки';
									|ru = 'Ошибка в обработчике события ПередОбработкойПравилаОчистки';
									|en = 'Event handler error: BeforeProcessClearingRule'; fa = 'Event handler error: BeforeProcessClearingRule';
									|it = 'Errore nel gestore dell''evento PrimaDiElaborazioneDellaRegolaDiCancellazione';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПередОбработкойПравилаОчистки';
									|tr = 'ПередОбработкойПравилаОчистки olayın işleyicisinde hata oluştu'"));
	ErrorsMessages.Insert(28, NStr("vi = 'Lỗi trong hàm sự kiện ПослеОбработкиПравилаОчистки';
									|ru = 'Ошибка в обработчике события ПослеОбработкиПравилаОчистки';
									|en = 'Event handler error: AfterProcessClearingRule'; fa = 'Event handler error: AfterProcessClearingRule';
									|it = 'Errore nel gestore dell''evento DopoElaborazioneDellaRegolaDiCancellazione';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПослеОбработкиПравилаОчистки';
									|tr = 'ПослеОбработкиПравилаОчистки olayın işleyicisinde hata oluştu'"));
	ErrorsMessages.Insert(29, NStr("vi = 'Lỗi trong hàm sự kiện ПередУдалениемОбъекта';
									|ru = 'Ошибка в обработчике события ПередУдалениемОбъекта';
									|en = 'Event handler error: BeforeDeleteObject'; fa = 'Event handler error: BeforeDeleteObject';
									|it = 'Errore nel gestore dell''evento PrimaDiCancellazioneOggetto';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПередУдалениемОбъекта';
									|tr = 'ПередУдалениемОбъекта olayın işleyicisinde hata oluştu'"));
	
	ErrorsMessages.Insert(31, NStr("vi = 'Lỗi trong hàm sự kiện ПередОбработкойПравилаВыгрузки';
									|ru = 'Ошибка в обработчике события ПередОбработкойПравилаВыгрузки';
									|en = 'Event handler error: BeforeProcessExportRule'; fa = 'Event handler error: BeforeProcessExportRule';
									|it = 'Errore nel gestore dell''evento PrimaDiElaborazioneDiRegolaUpload';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПередОбработкойПравилаВыгрузки';
									|tr = 'ПередОбработкойПравилаВыгрузки olayın işleyicisinde hata oluştu'"));
	ErrorsMessages.Insert(32, NStr("vi = 'Lỗi trong hàm sự kiện ПослеОбработкиПравилаВыгрузки';
									|ru = 'Ошибка в обработчике события ПослеОбработкиПравилаВыгрузки';
									|en = 'Event handler error: AfterProcessExportRule'; fa = 'Event handler error: AfterProcessExportRule';
									|it = 'Errore nel gestore dell''evento DopoElaborazioneDiRegolaUpload';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПослеОбработкиПравилаВыгрузки';
									|tr = 'ПослеОбработкиПравилаВыгрузки olayın işleyicisinde hata oluştu'"));
	ErrorsMessages.Insert(33, NStr("vi = 'Lỗi trong hàm sự kiện ПередВыгрузкойОбъекта';
									|ru = 'Ошибка в обработчике события ПередВыгрузкойОбъекта';
									|en = 'Event handler error: BeforeExportObject'; fa = 'Event handler error: BeforeExportObject';
									|it = 'Errore nel gestore dell''evento PrimaDiUploadOggetto';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПередВыгрузкойОбъекта';
									|tr = 'NesneDışaAktarılmadanÖnce olayın işleyicisinde hata oluştu'"));
	ErrorsMessages.Insert(34, NStr("vi = 'Lỗi trong hàm sự kiện ПослеВыгрузкиОбъекта';
									|ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъекта';
									|en = 'Event handler error: AfterExportObject'; fa = 'Event handler error: AfterExportObject';
									|it = 'Errore nel gestore dell''evento DopoUploadOggetto';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПослеВыгрузкиОбъекта';
									|tr = 'NesneDışaAktarılmadanSonra olayın işleyicisinde hata oluştu'"));
			
	ErrorsMessages.Insert(41, NStr("vi = 'Lỗi trong hàm sự kiện ПередВыгрузкойОбъекта';
									|ru = 'Ошибка в обработчике события ПередВыгрузкойОбъекта';
									|en = 'Event handler error: BeforeExportObject'; fa = 'Event handler error: BeforeExportObject';
									|it = 'Errore nel gestore dell''evento PrimaDiUploadOggetto';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПередВыгрузкойОбъекта';
									|tr = 'NesneDışaAktarılmadanÖnce olayın işleyicisinde hata oluştu'"));
	ErrorsMessages.Insert(42, NStr("vi = 'Lỗi trong hàm sự kiện ПриВыгрузкеОбъекта';
									|ru = 'Ошибка в обработчике события ПриВыгрузкеОбъекта';
									|en = 'Event handler error: OnExportObject'; fa = 'Event handler error: OnExportObject';
									|it = 'Errore nel gestore dell''evento DuranteUploadOggetto';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПриВыгрузкеОбъекта';
									|tr = 'NesneDışaAktarılırken olayın işleyicisinde hata oluştu'"));
	ErrorsMessages.Insert(43, NStr("vi = 'Lỗi trong hàm sự kiện ПослеВыгрузкиОбъекта';
									|ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъекта';
									|en = 'Event handler error: AfterExportObject'; fa = 'Event handler error: AfterExportObject';
									|it = 'Errore nel gestore dell''evento DopoUploadOggetto';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПослеВыгрузкиОбъекта';
									|tr = 'NesneDışaAktarılmadanSonra olayın işleyicisinde hata oluştu'"));
			
	ErrorsMessages.Insert(45, NStr("vi = 'Không tìm thấy quy tắc chuyển đổi đối tượng';
									|ru = 'Не найдено правило конвертации объектов';
									|en = 'Object conversion rule not found'; fa = 'Object conversion rule not found';
									|it = 'Nessuna regola di conversione dell''oggetto trovata';
									|pl = 'Nie jest znaleziona reguła konwersji obiektów';
									|tr = 'Nesne dönüştürme kuralı bulunamadı'"));
		
	ErrorsMessages.Insert(48, NStr("vi = 'Lỗi trong hàm sự kiện ПередОбработкойВыгрузки của nhóm thuộc tính';
									|ru = 'Ошибка в обработчике события ПередОбработкойВыгрузки группы свойств';
									|en = 'Event handler error: BeforeProcessExport (of property group)'; fa = 'Event handler error: BeforeProcessExport (of property group)';
									|it = 'Errore nel gestore dell''evento PrimaDiElaborazioneUpload dei gruppi di proprietà';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПередОбработкойВыгрузки grupy właściwości';
									|tr = 'Özellik grubunun DışaAktarımİşlenmedenÖnce olay işleyicisinde bir hata oluştu'"));
	ErrorsMessages.Insert(49, NStr("vi = 'Lỗi trong hàm sự kiện ПослеОбработкиВыгрузки nhóm thuộc tính';
									|ru = 'Ошибка в обработчике события ПослеОбработкиВыгрузки группы свойств';
									|en = 'Event handler error: AfterProcessExport (of property group)'; fa = 'Event handler error: AfterProcessExport (of property group)';
									|it = 'Errore nel gestore dell''evento DopoElaborazioneUpload dei gruppi di proprietà';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПослеОбработкиВыгрузки grupy właściwości';
									|tr = 'Özellik grubunun DışaAktarımİşlendiktenSonra olay işleyicisinde bir hata oluştu'"));
	ErrorsMessages.Insert(50, NStr("vi = 'Lỗi trong hàm sự kiện ПередВыгрузкой (đối tượng thu thập)';
									|ru = 'Ошибка в обработчике события ПередВыгрузкой (объекта коллекции)';
									|en = 'Event handler error: BeforeExport (of collection object)'; fa = 'Event handler error: BeforeExport (of collection object)';
									|it = 'Errore nel gestore dell''evento PrimaDiUpload (dell''oggetto di raccolta)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПередВыгрузкой (obiektu kolekcji)';
									|tr = 'DışaAktarımdanÖnce olay işleyicisinde hata oluştu (koleksiyon nesnesinin)'"));
	ErrorsMessages.Insert(51, NStr("vi = 'Lỗi trong hàm sự kiện ПриВыгрузке (đối tượng thu thập)';
									|ru = 'Ошибка в обработчике события ПриВыгрузке (объекта коллекции)';
									|en = 'Event handler error: OnExport (of collection object)'; fa = 'Event handler error: OnExport (of collection object)';
									|it = 'Errore nel gestore dell''evento DuranteUpload (dell''oggetto di raccolta)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПриВыгрузкеОбъекта (obiektu kolekcji)';
									|tr = 'DışaAktarımıSırasında olay işleyicisinde hata oluştu (koleksiyon nesnesinin)'"));
	ErrorsMessages.Insert(52, NStr("vi = 'Lỗi trong hàm sự kiện ПослеВыгрузки (đối tượng thu thập)';
									|ru = 'Ошибка в обработчике события ПослеВыгрузки (объекта коллекции)';
									|en = 'Event handler error: AfterExport (of collection object)'; fa = 'Event handler error: AfterExport (of collection object)';
									|it = 'Errore nel gestore dell''evento DopoUpload (dell''oggetto di raccolta)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПослеВыгрузки (obiektu kolekcji)';
									|tr = 'DışaAktarımdanSonra olay işleyicisinde hata oluştu (koleksiyon nesnesinin)'"));
	ErrorsMessages.Insert(53, NStr("vi = 'Lỗi trong hàm sự kiện toàn cục ПередЗагрузкойОбъекта (chuyển đổi)';
									|ru = 'Ошибка в глобальном обработчике события ПередЗагрузкойОбъекта (конвертация)';
									|en = 'Global event handler error (data conversion): BeforeImportObject'; fa = 'Global event handler error (data conversion): BeforeImportObject';
									|it = 'Errore nel gestore globale dell''evento ПередЗагрузкойОбъекта (conversione)';
									|pl = 'Błąd w globalnym programie przetwarzania zdarzenia ПередЗагрузкойОбъекта (konwersja)';
									|tr = 'NesneYüklenmedenÖnce global olay işleyicisinde bir hata oluştu (dönüştürme)'"));
	ErrorsMessages.Insert(54, NStr("vi = 'Lỗi trong hàm sự kiện toàn cục ПослеЗагрузкиОбъекта (chuyển đổi)';
									|ru = 'Ошибка в глобальном обработчике события ПослеЗагрузкиОбъекта (конвертация)';
									|en = 'Global event handler error (data conversion): AfterImportObject'; fa = 'Global event handler error (data conversion): AfterImportObject';
									|it = 'Errore nel gestore globale dell''evento ПослеЗагрузкиОбъекта (conversione)';
									|pl = 'Błąd w globalnym programie przetwarzania zdarzenia ПослеЗагрузкиОбъекта (konwersja)';
									|tr = 'NesneYüklendiktenSonra global olay işleyicisinde bir hata oluştu (dönüştürme)'"));
	ErrorsMessages.Insert(55, NStr("vi = 'Lỗi trong hàm sự kiện ПередВыгрузкой (thuộc tính)';
									|ru = 'Ошибка в обработчике события ПередВыгрузкой (свойства)';
									|en = 'Event handler error: BeforeExport (of property)'; fa = 'Event handler error: BeforeExport (of property)';
									|it = 'Errore nel gestore dell''evento PrimaDiUpload (proprietà)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПередВыгрузкой (właściwości)';
									|tr = 'DışaAktarımdanÖnce olay işleyicisinde bir hata oluştu (özellikler)'"));
	ErrorsMessages.Insert(56, NStr("vi = 'Lỗi trong hàm sự kiện ПриВыгрузке (thuộc tính)';
									|ru = 'Ошибка в обработчике события ПриВыгрузке (свойства)';
									|en = 'Event handler error: OnExport (of property)'; fa = 'Event handler error: OnExport (of property)';
									|it = 'Errore nel gestore dell''evento DuranteUpload (proprietà)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПриВыгрузкеОбъекта (właściwości)';
									|tr = 'DışaAktarımSırasında olay işleyicisinde bir hata oluştu (özellikler)'"));
	ErrorsMessages.Insert(57, NStr("vi = 'Lỗi trong hàm sự kiện ПослеВыгрузки (thuộc tính)';
									|ru = 'Ошибка в обработчике события ПослеВыгрузки (свойства)';
									|en = 'Event handler error: AfterExport (of property)'; fa = 'Event handler error: AfterExport (of property)';
									|it = 'Errore nel gestore dell''evento DopoUpload (proprietà)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПослеВыгрузки (właściwości)';
									|tr = 'DışaAktarımSonrasında olay işleyicisinde bir hata oluştu (özellikler)'"));
	
	ErrorsMessages.Insert(62, NStr("vi = 'Lỗi trong hàm sự kiện ПередВыгрузкойДанных (chuyển đổi)';
									|ru = 'Ошибка в обработчике события ПередВыгрузкойДанных (конвертация)';
									|en = 'Event handler error (data conversion): BeforeExportData'; fa = 'Event handler error (data conversion): BeforeExportData';
									|it = 'Errore nel gestore dell''evento PrimaDiUploadDati (conversione)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПередВыгрузкойДанных (konwersja)';
									|tr = 'VeriDışaAktarılmadanÖnce olay işleyicisinde bir hata oluştu (dönüştürme)'"));
	ErrorsMessages.Insert(63, NStr("vi = 'Lỗi trong hàm sự kiện ПослеВыгрузкиДанных (chuyển đổi)';
									|ru = 'Ошибка в обработчике события ПослеВыгрузкиДанных (конвертация)';
									|en = 'Event handler error (data conversion): AfterExportData'; fa = 'Event handler error (data conversion): AfterExportData';
									|it = 'Errore nel gestore dell''evento DopoUploadDati (conversione)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПослеВыгрузкиДанных (konwersja)';
									|tr = 'VeriDışaAktarıldıktanSonra olay işleyicisinde bir hata oluştu (dönüştürme)'"));
	ErrorsMessages.Insert(64, NStr("vi = 'Lỗi trong hàm sự kiện toàn cục ПередКонвертациейОбъекта (chuyển đổi)';
									|ru = 'Ошибка в глобальном обработчике события ПередКонвертациейОбъекта (конвертация)';
									|en = 'Global event handler error (data conversion): BeforeConvertObject'; fa = 'Global event handler error (data conversion): BeforeConvertObject';
									|it = 'Errore nel gestore globale dell''evento ПередКонвертациейОбъекта (conversione)';
									|pl = 'Błąd w globalnym programie przetwarzania zdarzenia ПередКонвертациейОбъекта (konwersja)';
									|tr = 'NesneDönüştürüldüktenSonra global olay işleyicisinde bir hata oluştu (dönüştürme)'"));
	ErrorsMessages.Insert(65, NStr("vi = 'Lỗi trong hàm sự kiện toàn cục ПередВыгрузкойОбъекта (chuyển đổi)';
									|ru = 'Ошибка в глобальном обработчике события ПередВыгрузкойОбъекта (конвертация)';
									|en = 'Global event handler error (data conversion): BeforeExportObject'; fa = 'Global event handler error (data conversion): BeforeExportObject';
									|it = 'Errore nel gestore globale dell''evento ПередВыгрузкойОбъекта (conversione)';
									|pl = 'Błąd w globalnym programie przetwarzania zdarzenia ПередВыгрузкойОбъекта (konwersja)';
									|tr = 'NesneDışaAktarılmadanÖnce global işleyicisinde bir hata oluştu (dönüştürme)'"));
	ErrorsMessages.Insert(66, NStr("vi = 'Lỗi nhận tập hợp đối tượng trực thuộc từ dữ liệu đầu vào';
									|ru = 'Ошибка получения коллекции подчиненных объектов из входящих данных';
									|en = 'Error getting collection of subordinate objects from incoming data'; fa = 'Error getting collection of subordinate objects from incoming data';
									|it = 'Errore di acquisizione della raccolta di oggetti subordinati dai dati in arrivo';
									|pl = 'Błąd pobierania kolekcji podporządkowanych obiektów z danych przychodzących';
									|tr = 'Gelen verilerden bir alt nesne koleksiyonu alınırken bir hata oluştu'"));
	ErrorsMessages.Insert(67, NStr("vi = 'Lỗi nhận thuộc tính đối tượng trực thuộc từ dữ liệu đầu vào';
									|ru = 'Ошибка получения свойства подчиненного объекта из входящих данных';
									|en = 'Error getting property of subordinate object from incoming data'; fa = 'Error getting property of subordinate object from incoming data';
									|it = 'Errore di acquisizione della proprietà dell''oggetto subordinato dai dati in arrivo';
									|pl = 'Błąd pobierania właściwości podporządkowanego obiektu z danych przychodzących';
									|tr = 'Alt nesne özelliklerini gelen verilerden alırken bir hata oluştu'"));
	ErrorsMessages.Insert(68, NStr("vi = 'Lỗi nhận thuộc tính đối tượng từ dữ liệu đầu vào';
									|ru = 'Ошибка получения свойства объекта из входящих данных';
									|en = 'Error getting object property from incoming data'; fa = 'Error getting object property from incoming data';
									|it = 'Errore di acquisizione della proprietà dell''oggetto dai dati in arrivo';
									|pl = 'Błąd pobierania właściwości obiektu z danych przychodzących';
									|tr = 'Nesne özelliklerini gelen verilerden alırken bir hata oluştu'"));
	
	ErrorsMessages.Insert(69, NStr("vi = 'Lỗi trong hàm sự kiện toàn cục ПослеВыгрузкиОбъекта (chuyển đổi)';
									|ru = 'Ошибка в глобальном обработчике события ПослеВыгрузкиОбъекта (конвертация)';
									|en = 'Global event handler error (data conversion): AfterExportObject'; fa = 'Global event handler error (data conversion): AfterExportObject';
									|it = 'Errore nel gestore globale dell''evento ПослеВыгрузкиОбъекта (conversione)';
									|pl = 'Błąd w globalnym programie przetwarzania zdarzenia ПослеВыгрузкиОбъекта (konwersja)';
									|tr = 'NesneDışaAktarıldıktanSonra global olay işleyicisinde bir hata oluştu (dönüştürme)'"));
	
	ErrorsMessages.Insert(71, NStr("vi = 'Không tìm thấy tương ứng đối với giá trị Nguồn';
									|ru = 'Не найдено соответствие для значения Источника';
									|en = 'Cannot find a match for the source value'; fa = 'Cannot find a match for the source value';
									|it = 'Nessuna corrispondenza trovata per il valore di Origine';
									|pl = 'Nie jest znaleziona zgodność dla wartości Źródła';
									|tr = 'Kaynak değerinin eşleşmesi bulunamadı'"));
	
	ErrorsMessages.Insert(72, NStr("vi = 'Lỗi khi kết xuất dữ liệu đối với nút sơ đồ trao đổi';
									|ru = 'Ошибка при выгрузке данных для узла плана обмена';
									|en = 'Error exporting data for exchange plan node'; fa = 'Error exporting data for exchange plan node';
									|it = 'Errore durante l''upload dei dati per il nodo del piano di scambio';
									|pl = 'Błąd podczas wysłania danych dla węzła planu wymiany';
									|tr = 'Değişim planı ünitesi için veri dışa aktarılırken bir hata oluştu'"));
	
	ErrorsMessages.Insert(73, NStr("vi = 'Lỗi trong hàm sự kiện ПоследовательностьПолейПоиска';
									|ru = 'Ошибка в обработчике события ПоследовательностьПолейПоиска';
									|en = 'Event handler error: SearchFieldSequence'; fa = 'Event handler error: SearchFieldSequence';
									|it = 'Errore nel gestore dell''evento SequenzaCampiDiRicerca';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПоследовательностьПолейПоиска';
									|tr = 'AramaAlanlarınınSırası olay işleyicisinde bir hata oluştu'"));
	ErrorsMessages.Insert(74, NStr("vi = 'Hãy kết nhập lại quy tắc trao đổi để kết xuất dữ liệu.';
									|ru = 'Перезагрузите правила обмена для выгрузки данных.';
									|en = 'To export data, reload data exchange rules.'; fa = 'To export data, reload data exchange rules.';
									|it = 'Ripetere il download delle regole di scambio per caricare i dati.';
									|pl = 'Ponownie uruchom reguły wymiany dla eksportu danych.';
									|tr = 'Verilerin dışa aktarımı için değişim kurallarını yeniden başlatın.'"));
	
	ErrorsMessages.Insert(75, NStr("vi = 'Lỗi trong hàm sự kiện ПослеЗагрузкиПравилОбмена (chuyển đổi)';
									|ru = 'Ошибка в обработчике события ПослеЗагрузкиПравилОбмена (конвертация)';
									|en = 'Event handler error (data conversion): AfterImportExchangeRules'; fa = 'Event handler error (data conversion): AfterImportExchangeRules';
									|it = 'Errore nel gestore dell''evento DopoDownloadRegoleDiScambio (conversione)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПослеЗагрузкиПравилОбмена (konwersja)';
									|tr = 'DeğişimKurallarıYüklendiktenSonra olay işleyicisinde bir hata oluştu (dönüştürme)'"));
	ErrorsMessages.Insert(76, NStr("vi = 'Lỗi trong hàm sự kiện ПередОтправкойИнформацииОбУдалении (chuyển đổi)';
									|ru = 'Ошибка в обработчике события ПередОтправкойИнформацииОбУдалении (конвертация)';
									|en = 'Event handler error (data conversion): BeforeSendDeletionInfo'; fa = 'Event handler error (data conversion): BeforeSendDeletionInfo';
									|it = 'Errore nel gestore dell''evento PrimaDiSpedizioneDell''InformazioneSullaCancellazione (conversione)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПередОтправкойИнформацииОбУдалении (konwersja)';
									|tr = 'SilmeBilgisiGönderilmedenÖnce olay işleyicisinde bir hata oluştu (dönüştürme)'"));
	ErrorsMessages.Insert(77, NStr("vi = 'Lỗi trong hàm sự kiện ПриПолученииИнформацииОбУдалении (chuyển đổi)';
									|ru = 'Ошибка в обработчике события ПриПолученииИнформацииОбУдалении (конвертация)';
									|en = 'Event handler error (data conversion): OnGetDeletionInfo'; fa = 'Event handler error (data conversion): OnGetDeletionInfo';
									|it = 'Errore nel gestore dell''evento DuranteAcquisizioneDell''InformazioneSullaCancellazione (conversione)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПриПолученииИнформацииОбУдалении (konwersja)';
									|tr = 'SilmeBilgisiAlındıktanSonra olay işleyicisinde bir hata oluştu (dönüştürme)'"));
	
	ErrorsMessages.Insert(78, NStr("vi = 'Lỗi khi thực hiện thuật toán sau khi kết nhập giá trị tham số';
									|ru = 'Ошибка при выполнении алгоритма после загрузки значений параметров';
									|en = 'Algorithm fails after parameter values are imported'; fa = 'Algorithm fails after parameter values are imported';
									|it = 'Errore durante l''esecuzione di algoritmo dopo il download di valori dei parametri';
									|pl = 'Błąd podczas wykonania algorytmu po pobieraniu wartości parametrów';
									|tr = 'Parametre değerlerini içe aktardıktan sonra algoritmayı çalıştırırken bir hata oluştu.'"));
	
	ErrorsMessages.Insert(79, NStr("vi = 'Lỗi trong hàm sự kiện ПослеВыгрузкиОбъектаВФайл';
									|ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъектаВФайл';
									|en = 'Event handler error: AfterExportObjectToFile'; fa = 'Event handler error: AfterExportObjectToFile';
									|it = 'Errore nel gestore dell''evento DopoUploadOggettoNelFile';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПослеВыгрузкиОбъектаВФайл';
									|tr = 'NesneDosyayaAktarıldıktanSonra olay işleyicisinde hata oluştu'"));
	
	ErrorsMessages.Insert(80, NStr("vi = 'Lỗi đặt thuộc tính phần tử định trước.
		|Không thể đặt dấu xóa phần tử định trước. Chưa đặt dấu xóa đối tượng.';
		|ru = 'Ошибка установки свойства предопределенного элемента.
		|Нельзя помечать на удаление предопределенный элемент. Пометка на удаление для объекта не установлена.';
		|en = 'Error marking item for deletion.
		|Predefined items cannot be marked for deletion.'; fa = 'Error marking item for deletion.
		|Predefined items cannot be marked for deletion.';
		|it = 'Errore durante l''impostazione della proprietà di un elemento predefinito.
		|Non è possibile contrassegnare un elemento predefinito per la cancellazione. Il contrassegno per la cancellazione non è impostato per l''oggetto.';
		|pl = 'Błąd ustawienia właściwości predefiniowanego elementu.
		|Nie można zaznaczać do usunięcia element predefiniowany. Zaznaczenie do usunięcia dla obiektu nie jest ustawione.';
		|tr = 'Önceden tanımlanmış öğe özelliği ayarının hatası. 
		|Önceden silinecek olarak tanımlanmış öğeyi işaretleyemezsiniz. Nesnelerin silinmesi için işaret yüklenmemiş.'"));
	//
	ErrorsMessages.Insert(81, NStr("vi = 'Đã xảy ra xung đột thay đổi đối tượng.
		|Đối tượng của cơ sở thông tin này đã bị thay thế bởi phiên bản đối tượng từ cơ sở thông tin thứ hai.';
		|ru = 'Возникла коллизия изменений объектов.
		|Объект этой информационной базы был заменен версией объекта из второй информационной базы.';
		|en = 'Object version conflict.
		|The object in the destination infobase is replaced with an object version from the source infobase.'; fa = 'Object version conflict.
		|The object in the destination infobase is replaced with an object version from the source infobase.';
		|it = 'Si è verificata una collisione nelle modifiche agli oggetti
		|L''oggetto di questo database è stato sostituito dalla versione dell''oggetto del secondo database.';
		|pl = 'Powstała kolizja zmian obiektów.
		|Obiekt tej bazy informacyjnej został wymieniony na wersję obiektu z drugiej bazy informacyjnej.';
		|tr = 'Nesne değişikliği çarpışması meydana geldi. 
		|Bu Infobase nesnesi, ikinci Infobase nesne sürümü ile değiştirildi.'"));
	//
	ErrorsMessages.Insert(82, NStr("vi = 'Đã xảy ra xung đột thay đổi đối tượng.
		|Đối tượng từ cơ sở thông tin thứ hai chưa được tiếp nhận. Đối tượng của cơ sở thông tin này không thay đổi.';
		|ru = 'Возникла коллизия изменений объектов.
		|Объект из второй информационной базы не принят. Объект этой информационной базы не изменен.';
		|en = 'Object version conflict.
		|An object version from the source infobase is rejected. The object in the destination infobase is not changed.'; fa = 'Object version conflict.
		|An object version from the source infobase is rejected. The object in the destination infobase is not changed.';
		|it = 'Si è verificata una collisione nelle modifiche agli oggetti
		|L''oggetto del secondo database non è stato accettato. L''oggetto di questo database non è stato modificato.';
		|pl = 'Powstała kolizja zmian obiektów.
		|Obiekt z drugiej bazy informacyjnej nie był przyjęty. Obiekt tej bazy informacyjnej nie jest zmieniony.';
		|tr = 'Nesne değişiklikleri çakışması ortaya çıktı. 
		|İkinci Infobase''deki nesne kabul edilmedi. Bu Infobase nesnesi değiştirilmedi.'"));
	//
	ErrorsMessages.Insert(83, NStr("vi = 'Lỗi truy cập đến phần bảng đối tượng. Không thể thay đổi phần bảng đối tượng.';
									|ru = 'Ошибка обращения к табличной части объекта. Табличная часть объекта не может быть изменена.';
									|en = 'Object table access error. Cannot change the table.'; fa = 'Object table access error. Cannot change the table.';
									|it = 'Errore durante l''accesso alla parte tabulare dell''oggetto. La parte tabulare dell''oggetto non può essere modificata.';
									|pl = 'Błąd zwrotu do części tabelarycznej obiektu. Część tabelaryczna obiektu nie może być zmieniona.';
									|tr = 'Nesne sekme bölümüne erişilirken bir hata oluştu. Nesne sekme bölümü değiştirilemez.'"));
	ErrorsMessages.Insert(84, NStr("vi = 'Xung đột ngày cấm thay đổi.';
									|ru = 'Коллизия дат запрета изменения.';
									|en = 'Period-end closing dates conflict.'; fa = 'Period-end closing dates conflict.';
									|it = 'Il conflitto delle date di divieto della modifica.';
									|pl = 'Kolizja dat zakazu zmiany.';
									|tr = 'Değişim kapanış tarihlerinin çarpışması.'"));
	
	ErrorsMessages.Insert(174, NStr("vi = 'Thông điệp trao đổi đã được nhận từ trước';
									|ru = 'Сообщение обмена было принято ранее';
									|en = 'The exchange message was received earlier'; fa = 'پیام تبادل قبلاً دریافت شده بود';
									|it = 'Il messaggio di scambio è stato precedentemente accettato';
									|pl = 'Komunikat wymiany został przyjęty wcześniej';
									|tr = 'Değişim iletisi daha önce alındı'"));
	ErrorsMessages.Insert(175, NStr("vi = 'Lỗi trong hàm sự kiện ПередПолучениемИзмененныхОбъектов (chuyển đổi)';
									|ru = 'Ошибка в обработчике события ПередПолучениемИзмененныхОбъектов (конвертация)';
									|en = 'Event handler error (data conversion): BeforeGetChangedObjects'; fa = 'Event handler error (data conversion): BeforeGetChangedObjects';
									|it = 'Errore nel gestore dell''evento PrimaDiAcquisizioneDegliOggettiModificati (conversione)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПередПолучениемИзмененныхОбъектов (konwersja)';
									|tr = 'DeğişmişNesnelerAlınmadanÖnce olay işleyicisinde hata oluştu (dönüştürme)'"));
	ErrorsMessages.Insert(176, NStr("vi = 'Lỗi trong hàm sự kiện ПослеПолученияИнформацииОбУзлахОбмена (chuyển đổi)';
									|ru = 'Ошибка в обработчике события ПослеПолученияИнформацииОбУзлахОбмена (конвертация)';
									|en = 'Event handler error (data conversion): AfterGetExchangeNodesInformation'; fa = 'Event handler error (data conversion): AfterGetExchangeNodesInformation';
									|it = 'Errore nel gestore dell''evento DopoAcquisizioneDelleInformazioniSuiNodiDiScambio (conversione)';
									|pl = 'Błąd w programie przetwarzania zdarzenia ПослеПолученияИнформацииОбУзлахОбмена (konwersja)';
									|tr = 'DeğişimÜniteleriBilgisiAlındıktanSonra olay işleyicisinde hata oluştu (dönüştürme)'"));
		
	ErrorsMessages.Insert(177, NStr("vi = 'Tên của sơ đồ trao đổi từ thông điệp trao đổi không phù hợp với tên dự kiến.';
									|ru = 'Имя плана обмена из сообщения обмена не соответствует ожидаемому.';
									|en = 'Unexpected exchange plan name in exchange message.'; fa = 'Unexpected exchange plan name in exchange message.';
									|it = 'Il nome del piano di scambio dal messaggio di scambio non corrisponde a quello atteso.';
									|pl = 'Nazwa planu wymiany z komunikatu wymiany nie odpowiada oczekiwanej.';
									|tr = 'Değişim mesajındaki değişim planının ismi beklendiği gibi değil.'"));
	ErrorsMessages.Insert(178, NStr("vi = 'Người nhận từ thông điệp trao đổi không phù hợp với người nhận dự kiến.';
									|ru = 'Получатель из сообщения обмена не соответствует ожидаемому.';
									|en = 'Unexpected destination in exchange message.'; fa = 'Unexpected destination in exchange message.';
									|it = 'Il ricevente del messaggio di scambio non corrisponde a quello atteso.';
									|pl = 'Odbiorca z komunikatu wymiany nie odpowiada oczekiwanemu.';
									|tr = 'Değişim mesajındaki alıcı beklendiği gibi değil.'"));
	
	ErrorsMessages.Insert(1000, NStr("vi = 'Lỗi khi tạo tệp tạm thời để kết xuất dữ liệu';
									|ru = 'Ошибка при создании временного файла выгрузки данных';
									|en = 'Error creating temporary data export file'; fa = 'Error creating temporary data export file';
									|it = 'Errore durante la creazione del file temporaneo di upload dei dati';
									|pl = 'Błąd przy utworzeniu pliku tymczasowego wysłania danych';
									|tr = 'Geçici bir veri aktarımı dosyası oluşturulurken bir hata oluştu'"));
	
	Return ErrorsMessages;
	
EndFunction

Function StandaloneModeSupported() Export
	
	Return StandaloneModeExchangePlans().Count() = 1;
	
EndFunction

Function ExchangePlanPurpose(ExchangePlanName) Export
	
	Return DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "ExchangePlanPurpose");
	
EndFunction

// Determines whether an exchange plan has a template.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//  TemplateName - String - a name of the template to check for existence.
//
//  Returns:
//    Boolean - True if the exchange plan contains the specified template. Otherwise, False.
//
Function HasExchangePlanTemplate(Val ExchangePlanName, Val TemplateName) Export
	
	Return Metadata.ExchangePlans[ExchangePlanName].Templates.Find(TemplateName) <> Undefined;
	
EndFunction

// Returns the flag showing that the exchange plan belongs to the DIB exchange plan.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//
//  Returns:
//    Boolean - True if the exchange plan belongs to the DIB exchange plan. Otherwise, False.
//
Function IsDistributedInfobaseExchangePlan(ExchangePlanName) Export
	
	Return Metadata.ExchangePlans[ExchangePlanName].DistributedInfoBase;
	
EndFunction

Function StandaloneModeExchangePlan() Export
	
	Result = StandaloneModeExchangePlans();
	
	If Result.Count() = 0 Then
		
		Raise NStr("vi = 'Không cho phép làm việc độc lập trong hệ thống.';
					|ru = 'Автономная работа в системе не предусмотрена.';
					|en = 'Application does not support offline work.'; fa = 'Application does not support offline work.';
					|it = 'Il lavoro autonomo nel sistema non è supportato.';
					|pl = 'Autonomiczna praca w systemie nie jest przewidziana.';
					|tr = 'Uygulamada çevrimdışı çalışma desteklenmiyor.'");
		
	ElsIf Result.Count() > 1 Then
		
		Raise NStr("vi = 'Đã tạo hơn một sơ đồ trao đổi để làm việc độc lập.';
					|ru = 'Создано более одного плана обмена для автономной работы.';
					|en = 'Multiple exchange plans are found for offline mode.'; fa = 'Multiple exchange plans are found for offline mode.';
					|it = 'È stato creato più di un piano di scambio per il lavoro autonomo.';
					|pl = 'Utworzono więcej niż jeden plan wymiany dla pracy autonomicznej.';
					|tr = 'Çevrimdışı çalışma için birden fazla değişim planı oluşturuldu.'");
		
	EndIf;
	
	Return Result[0];
EndFunction

// See DataExchangeServer.IsXDTOExchangePlan
Function IsXDTOExchangePlan(ExchangePlan) Export
	If TypeOf(ExchangePlan) = Type("String") Then
		ExchangePlanName = ExchangePlan;
	Else
		ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangePlan);
	EndIf;
	Return DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "IsXDTOExchangePlan");
EndFunction

Function IsStringAttributeOfUnlimitedLength(FullName, AttributeName) Export
	
	MetadataObject = Metadata.FindByFullName(FullName);
	Attribute = MetadataObject.Attributes.Find(AttributeName);
	
	If Attribute <> Undefined
		And Attribute.Type.ContainsType(Type("String"))
		And (Attribute.Type.StringQualifiers.Length = 0) Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Gets a name of the exchange plan as a metadata object for the specified node.
//
// Parameters:
//  ExchangePlanNode - ExchangePlanRef - an exchange plan node.
// 
// Returns:
//  String - Name of the exchange plan as a metadata object.
//
Function GetExchangePlanName(ExchangePlanNode) Export
	
	Return ExchangePlanNode.Metadata().Name;
	
EndFunction

Function GetNameOfCorrespondentExchangePlan(ExchangePlanNode) Export
	
	ExchangePlanName = GetExchangePlanName(ExchangePlanNode);
	
	If Not DataExchangeCached.IsXDTOExchangePlan(ExchangePlanNode) Then
		Return ExchangePlanName;
	EndIf;
	
	CorrespondentExchangePlanName = InformationRegisters.CommonInfobasesNodesSettings.CorrespondentExchangePlanName(ExchangePlanNode);
	
	If CorrespondentExchangePlanName = "" Then
		CorrespondentExchangePlanName = ExchangePlanName;
	EndIf; 
	
	Return CorrespondentExchangePlanName;
	
EndFunction

// Gets an array of names of separated configuration exchange plans that use the SSL functionality.
// If the configuration does not contain separators, all exchange plans are treated as separated.
//
// Parameters:
//  No.
// 
// Returns:
//   Array - an array of elements of separated exchange plan names.
//
Function SeparatedSSLExchangePlans() Export
	
	Result = New Array;
	
	For Each ExchangePlanName In SSLExchangePlans() Do
		
		If Common.SubsystemExists("CloudTechnology.Core") Then
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			IsSeparatedConfiguration = ModuleSaaSOperations.IsSeparatedConfiguration();
		Else
			IsSeparatedConfiguration = False;
		EndIf;
		
		If IsSeparatedConfiguration Then
			
			If ModuleSaaSOperations.IsSeparatedMetadataObject("ExchangePlan." + ExchangePlanName,
					ModuleSaaSOperations.MainDataSeparator()) Then
				
				Result.Add(ExchangePlanName);
				
			EndIf;
			
		Else
			
			Result.Add(ExchangePlanName);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

// It determines whether versioning is used.
// 
// Parameters:
//  Sender - ExchangePlanRef - determines
//   whether object version creating is needed for the passed node if the parameter is passed.
//  CheckAccessRights - Boolean
// 
// Returns:
//  Boolean
//
Function VersioningUsed(Sender = Undefined, CheckAccessRights = False) Export
	
	Used = False;
	
	If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		
		Used = ?(Sender <> Undefined, IsSSLDataExchangeNode(Sender), True);
		
		If Used And CheckAccessRights Then
			
			ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
			Used = ModuleObjectsVersioning.HasRightToReadObjectVersionInfo();
			
		EndIf;
			
	EndIf;
	
	Return Used;
	
EndFunction

// Determines whether an exchange plan has a registration manager.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//
//  Returns:
//    Boolean - If True, the exchange plan has a registration module. Otherwise, False.
//                                                            
Function RulesForRegisteringInManager(Val ExchangePlanName) Export
	
	ExchangePlanSettings = DataExchangeServer.ExchangePlanSettings(ExchangePlanName, "", "", Undefined);
		
	Return ExchangePlanSettings.RulesForRegisteringInManager;	
	
EndFunction

// Returns the name of the registration manager (common module name) for the given exchange plan.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//
//  Returns:
//    Boolean - If True, the exchange plan has a registration module. Otherwise, False.
// 
Function RegistrationManagerName(Val ExchangePlanName) Export
	
	ExchangePlanSettings = DataExchangeServer.ExchangePlanSettings(ExchangePlanName, "", "", Undefined);
	
	Return ExchangePlanSettings.RegistrationManagerName;	
	
EndFunction	

// Returns the flag indicating whether the cache was used for searching references in the "SynchronizedObjectPublicIDs" information register
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//
//  Returns:
//    Boolean - If True, the cache was used. If False, requests to "SynchronizedObjectPublicIDs" were used.
// 
Function UseCacheOfPublicIdentifiers(Val ExchangePlanName) Export
	
	ExchangePlanSettings = DataExchangeServer.ExchangePlanSettings(ExchangePlanName, "", "", Undefined);
	
	Return ExchangePlanSettings.UseCacheOfPublicIdentifiers;
	
EndFunction

// Returns the "Global" flag value for an EnterpriseData exchange plan 
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//
//  Returns:
//    Boolean
// 
Function ThisIsGlobalExchangeThroughUniversalFormat(Val ExchangePlanName) Export
	
	ExchangePlanSettings = DataExchangeServer.ExchangePlanSettings(ExchangePlanName, "", "", Undefined);
	
	Return ExchangePlanSettings.Global;
	
EndFunction

// Returns an array of version numbers supported by correspondent API for the DataExchange subsystem.
// 
// Parameters:
//   Peer - Structure
//                 - ExchangePlanRef - Exchange plan node that corresponds
//                 the correspondent infobase.
//
// Returns:
//   Array of String - Array of version numbers that are supported by correspondent API.
//
Function CorrespondentVersions(Val Peer) Export
	
	If TypeOf(Peer) = Type("Structure") Then
		SettingsStructure = Peer;
	Else
		If DataExchangeCached.IsMessagesExchangeNode(Peer) Then
			ModuleMessagesExchangeTransportSettings = Common.CommonModule("InformationRegisters.MessageExchangeTransportSettings");
			SettingsStructure = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(Peer);
		EndIf;
	EndIf;
	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("URL",      SettingsStructure.WSWebServiceURL);
	ConnectionParameters.Insert("UserName", SettingsStructure.WSUserName);
	ConnectionParameters.Insert("Password", SettingsStructure.WSPassword);
	
	Return Common.GetInterfaceVersions(ConnectionParameters, "DataExchange");
	
EndFunction

// Gets a predefined exchange plan node.
// 
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
// 
// Returns:
//  ExchangePlanRef - Predefined exchange plan node.
//
Function GetThisExchangePlanNode(ExchangePlanName) Export
	
	Return ExchangePlans[ExchangePlanName].ThisNode();
	
EndFunction

// Returns the flag showing that the node belongs to a standard exchange plan (without conversion rules).
//
// Parameters:
//  ExchangePlanName - String - a name of the exchange plan which requires the function value.
//
//  Returns:
//    Boolean - True if the node belongs to the standard exchange plan. Otherwise, False.
//
Function IsStandardDataExchangeNode(ExchangePlanName) Export
	
	If DataExchangeServer.IsXDTOExchangePlan(ExchangePlanName) Then
		Return False;
	EndIf;
	
	Return Not DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName)
		And Not DataExchangeCached.HasExchangePlanTemplate(ExchangePlanName, "ExchangeRules");
	
EndFunction

// Returns an array of all nodes of the specified exchange plan but the predefined node.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
// 
// Returns:
//  Array of ExchangePlanRef - Array of all nodes of the specified exchange plan but the predefined node.
//
Function ExchangePlanNodes(ExchangePlanName) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
		"SELECT
		|	ExchangePlan.Ref AS Ref
		|FROM
		|	#ExchangePlanTableName AS ExchangePlan
		|WHERE
		|	NOT ExchangePlan.ThisNode");
	
	Query.Text = StrReplace(Query.Text, "#ExchangePlanTableName", "ExchangePlan." + ExchangePlanName);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// The mechanism for registering objects on exchange plan nodes (MRO).

// Retrieves the table of object registration rules for the exchange plan.
//
// Parameters:
//  ExchangePlanName - String - a name of the exchange plan as it is set in Designer
//                    for which the registration rules are to be received.
//
// Returns:
//   ValueTable - a table of registration rules for current exchange plan.
//
Function ExchangePlanObjectsRegistrationRules(Val ExchangePlanName) Export
	
	ObjectsRegistrationRules = DataExchangeInternal.SessionParametersObjectsRegistrationRules().Get();
	
	Return ObjectsRegistrationRules.Copy(New Structure("ExchangePlanName", ExchangePlanName));
EndFunction

// Gets the table of object registration rules for the specified exchange plan.
//
// Parameters:
//  ExchangePlanName   - String - an exchange plan name, as it is set in Designer.
//  FullObjectName - String - a full name of the metadata object
//                   for which registration rules are to be received.
//
// Returns:
//   ValueTable - a table of object registration rules for the specified exchange plan.
//
Function ObjectRegistrationRules(Val ExchangePlanName, Val FullObjectName) Export
	
	ExchangePlanObjectsRegistrationRules = DataExchangeEvents.ExchangePlanObjectsRegistrationRules(ExchangePlanName);
	
	Return ExchangePlanObjectsRegistrationRules.Copy(New Structure("MetadataObjectName3", FullObjectName));
	
EndFunction

// Returns a flag that shows whether registration rules exist for the object by the specified exchange plan.
//
// Parameters:
//  ExchangePlanName   - String - an exchange plan name, as it is set in Designer.
//  FullObjectName - String - a full name of the metadata object
//                   whose registration rules must be checked for existence.
//
//  Returns:
//     Boolean - True if the object registration rules exist. Otherwise, False.
//
Function ObjectRegistrationRulesExist(Val ExchangePlanName, Val FullObjectName) Export
	
	Return DataExchangeEvents.ObjectRegistrationRules(ExchangePlanName, FullObjectName).Count() <> 0;
	
EndFunction

// Determines whether automatic registration of a metadata object in exchange plan is allowed.
//
// Parameters:
//  ExchangePlanName   - String - a name of the exchange plan as it is set in Designer which contains the metadata
//                              object.
//  FullObjectName - String - a full name of the metadata object whose automatic registration flag must be checked.
//
//  Returns:
//    Boolean - True if metadata object automatic registration is allowed in the exchange plan;
//   False if metadata object auto registration is denied in the exchange plan
//          or the exchange plan does not include the metadata object.
//
Function AutoRegistrationAllowed(Val ExchangePlanName, Val FullObjectName) Export
	
	ExchangePlanContentItem = Metadata.ExchangePlans[ExchangePlanName].Content.Find(Metadata.FindByFullName(FullObjectName));
	
	If ExchangePlanContentItem = Undefined Then
		Return False; // The exchange plan does not include the metadata object.
	EndIf;
	
	Return ExchangePlanContentItem.AutoRecord = AutoChangeRecord.Allow;
EndFunction

// Determines whether the exchange plan includes the metadata object.
//
// Parameters:
//  ExchangePlanName   - String - an exchange plan name, as it is set in Designer.
//  FullObjectName - String - a full name of the metadata object whose automatic registration flag is to be checked.
//
//  Returns:
//    Boolean - True if the exchange plan includes the object. Otherwise, False.
//
Function ExchangePlanContainsObject(Val ExchangePlanName, Val FullObjectName) Export
	
	ExchangePlanContentItem = Metadata.ExchangePlans[ExchangePlanName].Content.Find(Metadata.FindByFullName(FullObjectName));
	
	Return ExchangePlanContentItem <> Undefined;
EndFunction

// Returns a list of exchange plans that contain at least one exchange node (ignoring ThisNode).
// 
// Returns:
//   See DataExchangeServer.GetExchangePlansInUse
//
Function ExchangePlansInUse() Export
	
	Return DataExchangeServer.GetExchangePlansInUse();
	
EndFunction

// Returns the exchange plan content specified by the user.
// Custom exchange plan content is determined by the object registration rules
// and node settings specified by the user.
//
// Parameters:
//  Recipient - ExchangePlanRef - an exchange plan node reference.
//               User content is retrieved for this node.
//
//  Returns:
//   Map of KeyAndValue:
//     * Key     - String - a full name of a metadata object that is included in the exchange plan content;
//     * Value - EnumRef.ExchangeObjectExportModes - object export mode.
//
Function UserExchangePlanComposition(Val Recipient) Export
	
	SetPrivilegedMode(True);
	
	Result = New Map;
	
	RecipientProperties = Common.ObjectAttributesValues(Recipient,
		Common.AttributeNamesByType(Recipient, Type("EnumRef.ExchangeObjectExportModes")));
	
	Priorities = ObjectsExportModesPriorities();
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(Recipient);
	Rules = DataExchangeCached.ExchangePlanObjectsRegistrationRules(ExchangePlanName);
	Rules.Indexes.Add("MetadataObjectName3");
	
	For Each Item In Metadata.ExchangePlans[ExchangePlanName].Content Do
		
		ObjectName = Item.Metadata.FullName();
		ObjectRules = Rules.FindRows(New Structure("MetadataObjectName3", ObjectName));
		ExportMode = Undefined;
		
		If ObjectRules.Count() = 0 Then // Registration rules are not set.
			
			ExportMode = Enums.ExchangeObjectExportModes.ExportAlways;
			
		Else // Registration rules are set.
			
			For Each ORR In ObjectRules Do
				
				If ValueIsFilled(ORR.FlagAttributeName) Then
					ExportMode = ObjectExportMaxMode(RecipientProperties[ORR.FlagAttributeName], ExportMode, Priorities);
				EndIf;
				
			EndDo;
			
			If ExportMode = Undefined
				Or ExportMode = Enums.ExchangeObjectExportModes.EmptyRef() Then
				ExportMode = Enums.ExchangeObjectExportModes.ExportByCondition;
			EndIf;
			
		EndIf;
		
		Result.Insert(ObjectName, ExportMode);
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return Result;
EndFunction

// Returns the object export mode based on the custom exchange plan content (user settings).
//
// Parameters:
//  ObjectName - String -  a metadata object full name. Export mode is retrieved for this metadata object;
//  Recipient - ExchangePlanRef - an exchange plan node reference. The function gets custom content from this node.
//
// Returns:
//   EnumRef.ExchangeObjectExportModes - object export mode.
//
Function ObjectExportMode(Val ObjectName, Val Recipient) Export
	
	Result = DataExchangeCached.UserExchangePlanComposition(Recipient).Get(ObjectName);
	
	Return ?(Result = Undefined, Enums.ExchangeObjectExportModes.ExportAlways, Result);
EndFunction

Function ObjectExportMaxMode(Val ExportMode1, Val ExportMode2, Val Priorities)
	
	If Priorities.Find(ExportMode1) < Priorities.Find(ExportMode2) Then
		
		Return ExportMode1;
		
	Else
		
		Return ExportMode2;
		
	EndIf;
	
EndFunction

Function ObjectsExportModesPriorities()
	
	Result = New Array;
	Result.Add(Enums.ExchangeObjectExportModes.ExportAlways);
	Result.Add(Enums.ExchangeObjectExportModes.ManualExport);
	Result.Add(Enums.ExchangeObjectExportModes.ExportByCondition);
	Result.Add(Enums.ExchangeObjectExportModes.EmptyRef());
	Result.Add(Enums.ExchangeObjectExportModes.ExportIfNecessary);
	Result.Add(Enums.ExchangeObjectExportModes.DoNotExport);
	Result.Add(Undefined);
	
	Return Result;
EndFunction

// Returns the flag showing whether the node belongs to a universal exchange plan (using conversion rules).
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
//
//  Returns:
//    Boolean - True if the node belongs to the universal exchange plan. Otherwise, False.
//
Function IsUniversalDataExchangeNode(InfobaseNode) Export
	
	If DataExchangeServer.IsXDTOExchangePlan(InfobaseNode) Then
		Return True;
	Else
		Return Not IsDistributedInfobaseNode(InfobaseNode)
			And HasExchangePlanTemplate(GetExchangePlanName(InfobaseNode), "ExchangeRules");
	EndIf;
	
EndFunction

// Returns the flag showing whether the node belongs to an exchange plan that uses SSL exchange functionality.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef
//                         - ExchangePlanObject - an exchange plan node that requires receiving
//                           the function value.
//
//  Returns:
//    Boolean - True if the node belongs to the exchange plan that uses the SSL functionality. Otherwise, False.
//
Function IsSSLDataExchangeNode(Val InfobaseNode) Export
	
	Return SSLExchangePlans().Find(GetExchangePlanName(InfobaseNode)) <> Undefined;
	
EndFunction

// Returns the flag showing whether the node belongs to a separated exchange plan that uses SSL exchange functionality.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
//
//  Returns:
//    Boolean - True if the node belongs to the separated exchange plan that uses the SSL functionality. Otherwise, False.
//
Function IsSeparatedSSLDataExchangeNode(InfobaseNode) Export
	
	Return SeparatedSSLExchangePlans().Find(GetExchangePlanName(InfobaseNode)) <> Undefined;
	
EndFunction

// Returns the flag showing whether the node belongs to the exchange plan used for message exchange.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
//
//  Returns:
//    Boolean - True if the node belongs to the message exchange plan. Otherwise, False.
//
Function IsMessagesExchangeNode(InfobaseNode) Export
	
	If Not Common.SubsystemExists("CloudTechnology.MessagesExchange") Then
		Return False;
	EndIf;
	
	Return DataExchangeCached.GetExchangePlanName(InfobaseNode) = "MessagesExchange";
	
EndFunction

// Gets a list of templates of standard exchange rules from configuration for the specified exchange plan;
// The list contains names and synonyms of the rule templates.
// 
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
// 
// Returns:
//   See RulesForExchangePlanFromConfiguration.
//
Function ConversionRulesForExchangePlanFromConfiguration(ExchangePlanName) Export
	
	Return RulesForExchangePlanFromConfiguration(ExchangePlanName, "ExchangeRules");
	
EndFunction

// Gets a list of templates of standard registration rules from configuration for the specified exchange plan;
// The list contains names and synonyms of the rule templates.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
// 
// Returns:
//   See RulesForExchangePlanFromConfiguration
//
Function RegistrationRulesForExchangePlanFromConfiguration(ExchangePlanName) Export
	
	Return RulesForExchangePlanFromConfiguration(ExchangePlanName, "RecordRules");
	
EndFunction

// Gets a list of configuration exchange plans that use the SSL functionality.
// The list is filled with names and synonyms of exchange plans.
// 
// Returns:
//  ValueList of String - List of configuration exchange plans.
//
Function SSLExchangePlansList() Export
	
	// Function return value.
	ExchangePlansList = New ValueList;
	
	SubsystemExchangePlans = New Array;
	
	DataExchangeOverridable.GetExchangePlans(SubsystemExchangePlans);
	
	For Each ExchangePlan In SubsystemExchangePlans Do
		
		ExchangePlansList.Add(ExchangePlan.Name, ExchangePlan.Synonym);
		
	EndDo;
	
	Return ExchangePlansList;
	
EndFunction

// For internal use.
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef - Exchange plan node that requires 
//                           receiving the function value.
// 
// Returns:
//  String 
//
Function CommonNodeData(Val InfobaseNode) Export
	
	Return DataExchangeServer.CommonNodeData(GetExchangePlanName(InfobaseNode),
		InformationRegisters.CommonInfobasesNodesSettings.CorrespondentVersion(InfobaseNode),
		"");
EndFunction

// For internal use.
// 
// Parameters:
//  ExchangePlanName - String - Exchange plan name as it is set in Designer.
//  CorrespondentVersion - String
//  SettingID - String
// 
// Returns:
//  Structure - Exchange plan tables:
//    * CommonTables - Array of String
//    * ThisInfobaseTables - Array of String
//    * AllTablesOfThisInfobase - Array of String
//
Function ExchangePlanTabularSections(Val ExchangePlanName, Val CorrespondentVersion = "", Val SettingID = "") Export
	
	CommonTables             = New Array;
	ThisInfobaseTables          = New Array;
	AllTablesOfThisInfobase       = New Array;
	
	CommonNodeData = DataExchangeServer.CommonNodeData(ExchangePlanName, CorrespondentVersion, SettingID);
	
	TabularSections = DataExchangeEvents.ObjectTabularSections(Metadata.ExchangePlans[ExchangePlanName]);
	
	If Not IsBlankString(CommonNodeData) Then
		
		For Each TabularSection In TabularSections Do
			
			If StrFind(CommonNodeData, TabularSection) <> 0 Then
				
				CommonTables.Add(TabularSection);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	ThisInfobaseSettings = DataExchangeServer.NodeFiltersSetting(ExchangePlanName, CorrespondentVersion, SettingID);
	
	ThisInfobaseSettings = DataExchangeEvents.StructureKeysToString(ThisInfobaseSettings);
	
	If IsBlankString(CommonNodeData) Then
		
		For Each TabularSection In TabularSections Do
			
			AllTablesOfThisInfobase.Add(TabularSection);
			
			If StrFind(ThisInfobaseSettings, TabularSection) <> 0 Then
				
				ThisInfobaseTables.Add(TabularSection);
				
			EndIf;
			
		EndDo;
		
	Else
		
		For Each TabularSection In TabularSections Do
			
			AllTablesOfThisInfobase.Add(TabularSection);
			
			If StrFind(ThisInfobaseSettings, TabularSection) <> 0 Then
				
				If StrFind(CommonNodeData, TabularSection) = 0 Then
					
					ThisInfobaseTables.Add(TabularSection);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Result = New Structure;
	Result.Insert("CommonTables",             CommonTables);
	Result.Insert("ThisInfobaseTables",          ThisInfobaseTables);
	Result.Insert("AllTablesOfThisInfobase",       AllTablesOfThisInfobase);
	
	Return Result;
	
EndFunction

// Gets the exchange plan manager by exchange plan name.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//
// Returns:
//  ExchangePlanManager - an exchange plan manager.
//
Function GetExchangePlanManagerByName(ExchangePlanName) Export
	
	Return ExchangePlans[ExchangePlanName];
	
EndFunction

// Wrapper of the function with the same name.
// 
// Parameters:
//   Filter - Structure - Contains filter item values.
//						If specified, a metadata tree is obtained considering the passed filter:
//            Key - String - Name of the metadata item property.
//            Value - Array - An array of values for the filter.
// 
// Returns:
//   See DataExchangeServer.ConfigurationMetadataTree
//
Function ConfigurationMetadata(Filter) Export
	
	For Each FilterElement In Filter Do
		
		Filter[FilterElement.Key] = StrSplit(FilterElement.Value, ",");
		
	EndDo;
	
	Return DataExchangeServer.ConfigurationMetadataTree(Filter);
	
EndFunction

// For internal use.
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef - Exchange plan node that requires 
//                           receiving the function value.
//  ExchangeMessageFileName - String
// 
// Returns:
//   See DataExchangeServer.ExchangeSettingsForInfobaseNode
//
Function ExchangeSettingsStructureForInteractiveImportSession(InfobaseNode, ExchangeMessageFileName) Export
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
		InfobaseNode,
		Enums.ActionsOnExchange.DataImport,
		Undefined);
		
	ExchangeSettingsStructure.DataExchangeDataProcessor.ExchangeFileName = ExchangeMessageFileName;
	
	Return ExchangeSettingsStructure;
	
EndFunction

// Wrapper of the function with the same name from the DataExchangeEvents module.
// 
// Parameters:
//  PropertiesValues - Structure - Structure containing object property values from the rules
//  QueryText - String - Query text from the rules
//  ExchangePlanName - String - Exchange plan name as it is set in Designer.
//  FlagAttributeName - String
//  Upload0 - Boolean
// 
// Returns:
//   See DataExchangeEvents.NodesArrayByPropertiesValues
//
Function NodesArrayByPropertiesValues(PropertiesValues, QueryText, ExchangePlanName, FlagAttributeName, Val Upload0 = False) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(PropertiesValues) = Type("String") Then
		PropertyValuesStructure = Common.ValueFromXMLString(PropertiesValues);
	Else
		PropertyValuesStructure = PropertiesValues;
	EndIf;
	
	Return DataExchangeEvents.NodesArrayByPropertiesValues(
		PropertyValuesStructure, QueryText, ExchangePlanName, FlagAttributeName, Upload0);
	
EndFunction

// Determines whether the exchange plan can be used.
// The flag is calculated by the configuration functional options composition.
// If no functional option includes the exchange plan, the function returns True.
// If functional options include the exchange plan and one or more functional option
// is enabled, the function returns True.
// Otherwise, the function returns False.
//
// Parameters:
//  ExchangePlanName - String - name of the exchange plan to get the flag for.
//
// Returns:
//   Boolean - True if the exchange plan can be used.
//  False - it cannot be used.
//
Function ExchangePlanUsageAvailable(Val ExchangePlanName) Export
	
	ObjectBelongsToFunctionalOptions = False;
	
	For Each FunctionalOption In Metadata.FunctionalOptions Do
		
		If FunctionalOption.Content.Contains(Metadata.ExchangePlans[ExchangePlanName]) Then
			
			ObjectBelongsToFunctionalOptions = True;
			
			If GetFunctionalOption(FunctionalOption.Name) = True Then
				
				Return True;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Not ObjectBelongsToFunctionalOptions Then
		
		Return True;
		
	EndIf;
	
	Return False;
EndFunction

// Returns an array of all reference types available in the configuration.
// 
// Returns:
//  Array of Type - All reference types in the configuration.
//
Function AllConfigurationReferenceTypes() Export
	
	Result = New Array;
	
	CommonClientServer.SupplementArray(Result, Catalogs.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, Documents.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, BusinessProcesses.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ChartsOfCharacteristicTypes.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ChartsOfAccounts.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ChartsOfCalculationTypes.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, Tasks.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ExchangePlans.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, Enums.AllRefsType().Types());
	
	Return Result;
EndFunction

Function StandaloneModeExchangePlans()
	
	// For SaaS standalone infobases, the exchange plan should be:
	// - Separated
	// - Set up for a distributed infobase
	// - Set up for SaaS mode ("ExchangePlanUsedInSaaS" is set to "True")
	
	Result = New Array;
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		If DataExchangeServer.IsSeparatedSSLExchangePlan(ExchangePlan.Name)
			And ExchangePlan.DistributedInfoBase
			And DataExchangeCached.ExchangePlanUsedInSaaS(ExchangePlan.Name) Then
			
			Result.Add(ExchangePlan.Name);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

Function SecurityProfileName(Val ExchangePlanName) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Return Undefined;
	EndIf;
	
	If Catalogs.MetadataObjectIDs.IsDataUpdated() Then
		ExchangePlanID = Common.MetadataObjectID(Metadata.ExchangePlans[ExchangePlanName]);
		ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
		SecurityProfileName = ModuleSafeModeManagerInternal.ExternalModuleAttachmentMode(ExchangePlanID);
	Else
		SecurityProfileName = Undefined;
	EndIf;
	
	If SecurityProfileName = Undefined Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		SecurityProfileName = ModuleSafeModeManager.InfobaseSecurityProfile();
		If IsBlankString(SecurityProfileName) Then
			SecurityProfileName = Undefined;
		EndIf;
	EndIf;
	
	Return SecurityProfileName;
	
EndFunction

Function RegistrationWhileLooping(InfobaseNode) Export
	
	Return InformationRegisters.CommonInfobasesNodesSettings.RegistrationWhileLooping(InfobaseNode);
	
EndFunction

Function WSProxy(ConnectionParameters, ErrorMessage = "", UserMessage = "") Export
	
	Return DataExchangeWebService.WSProxy(ConnectionParameters, ErrorMessage, UserMessage);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Initialization of the structure of data exchange settings.

// Gets a list of templates of standard rules for data exchange from configuration for the specified exchange plan;
// The list contains names and synonyms of the rule templates.
// 
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
// 
// Returns:
//  ValueList of String - List of templates of standard rules for data exchange.
//
Function RulesForExchangePlanFromConfiguration(ExchangePlanName, TemplateNameLiteral)
	
	RulesList = New ValueList;
	
	If IsBlankString(ExchangePlanName) Then
		Return RulesList;
	EndIf;
	
	For Each Template In Metadata.ExchangePlans[ExchangePlanName].Templates Do
		
		If StrFind(Template.Name, TemplateNameLiteral) <> 0 And StrFind(Template.Name, "Correspondent") = 0 Then
			
			RulesList.Add(Template.Name, Template.Synonym);
			
		EndIf;
		
	EndDo;
	
	Return RulesList;
EndFunction

// Returns a node content table (reference types only).
//
// Parameters:
//    ExchangePlanName - String - an exchange plan to analyze.
//    Periodic2  - Flag indicating that the result must include objects with dates (such as documents).
//    Regulatory     - 
//
// Returns:
//    ValueTable:
//      * FullMetadataName - String - a full metadata name (a table name for the query).
//      * ListPresentation - String - list presentation for a table.
//      * Presentation       - String - object presentation for a table.
//      * PictureIndex      - Number - a picture index according to PictureLib.MetadataObjectsCollection.
//      * Type                 - Type - the corresponding type.
//      * PeriodSelection        - Boolean - a flag showing that filter by period can be applied to the object.
//
Function ExchangePlanContent(ExchangePlanName, Periodic2 = True, Regulatory = True) Export
	
	ResultTable2 = New ValueTable;
	For Each KeyValue In (New Structure("FullMetadataName, Presentation, ListPresentation, PictureIndex, Type, PeriodSelection")) Do
		ResultTable2.Columns.Add(KeyValue.Key);
	EndDo;
	For Each KeyValue In (New Structure("FullMetadataName, Presentation, ListPresentation, Type")) Do
		ResultTable2.Indexes.Add(KeyValue.Key);
	EndDo;
	
	ExchangePlanContent = Metadata.ExchangePlans.Find(ExchangePlanName).Content;
	For Each CompositionItem In ExchangePlanContent Do
		
		ObjectMetadata = CompositionItem.Metadata;
		LongDesc = MetadataObjectDetails(ObjectMetadata);
		If LongDesc.PictureIndex >= 0 Then
			If Not Periodic2 And LongDesc.Periodic3 Then 
				Continue;
			ElsIf Not Regulatory And LongDesc.Reference Then 
				Continue;
			EndIf;
			
			String = ResultTable2.Add();
			FillPropertyValues(String, LongDesc);
			String.PeriodSelection        = LongDesc.Periodic3;
			String.FullMetadataName = ObjectMetadata.FullName();
			String.ListPresentation = DataExchangeServer.ObjectsListPresentation(ObjectMetadata);
			String.Presentation       = DataExchangeServer.ObjectPresentation(ObjectMetadata);
		EndIf;
	EndDo;
	
	ResultTable2.Sort("ListPresentation");
	Return ResultTable2;
	
EndFunction

// Returns the metadata object details.
// 
// Parameters:
//   Meta - MetadataObject - Metadata object.
//
// Returns:
//   Structure:
//     * PictureIndex - Number - picture index.
//     * Periodic3 - Boolean - True if the object is periodic.
//     * Reference - Boolean - True if the object is regulatory.
//     * Type - Type - a reference value type.
//
Function MetadataObjectDetails(Meta)
	
	Result = New Structure("PictureIndex, Periodic3, Reference, Type", -1, False, False);
	
	If Metadata.Catalogs.Contains(Meta) Then
		Result.PictureIndex = 3;
		Result.Reference = True;
		Result.Type = Type("CatalogRef." + Meta.Name);
		
	ElsIf Metadata.Documents.Contains(Meta) Then
		Result.PictureIndex = 7;
		Result.Periodic3 = True;
		Result.Type = Type("DocumentRef." + Meta.Name);
		
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(Meta) Then
		Result.PictureIndex = 9;
		Result.Reference = True;
		Result.Type = Type("ChartOfCharacteristicTypesRef." + Meta.Name);
		
	ElsIf Metadata.ChartsOfAccounts.Contains(Meta) Then
		Result.PictureIndex = 11;
		Result.Reference = True;
		Result.Type = Type("ChartOfAccountsRef." + Meta.Name);
		
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(Meta) Then
		Result.PictureIndex = 13;
		Result.Reference = True;
		Result.Type = Type("ChartOfCalculationTypesRef." + Meta.Name);
		
	ElsIf Metadata.BusinessProcesses.Contains(Meta) Then
		Result.PictureIndex = 23;
		Result.Periodic3 = True;
		Result.Type = Type("BusinessProcessRef." + Meta.Name);
		
	ElsIf Metadata.Tasks.Contains(Meta) Then
		Result.PictureIndex = 25;
		Result.Periodic3  = True;
		Result.Type = Type("TaskRef." + Meta.Name);
		
	EndIf;
	
	Return Result;
EndFunction

// Returns the name of the temporary file directory.
//
// Returns:
//  String - a path to the temporary file directory.
//
Function TempFilesStorageDirectory(SafeMode = Undefined) Export
	
	If Common.FileInfobase() And Not Common.DebugMode() Then
		
		Return TrimAll(TempFilesDir());
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	CommonPlatformType = "";
	If Common.IsLinuxServer() Then
	
		Result         = Constants.DataExchangeMessageDirectoryForLinux.Get();
		CommonPlatformType = "Linux";
		
	Else
		
		Result         = Constants.DataExchangeMessageDirectoryForWindows.Get();
		CommonPlatformType = "Windows";
		
	EndIf;
	
	SetPrivilegedMode(False);
	
	If IsBlankString(Result) Then
		
		Result = TrimAll(TempFilesDir());
		
	Else
		
		Result = TrimAll(Result);
		
		// Check whether the directory exists.
		Directory = New File(Result);
		If Not Directory.Exists() Then
			
			ConstantPresentation = ?(CommonPlatformType = "Linux", 
				Metadata.Constants.DataExchangeMessageDirectoryForLinux.Presentation(),
				Metadata.Constants.DataExchangeMessageDirectoryForWindows.Presentation());
			
			MessageTemplate = NStr("vi = 'Thư mục tệp tạm thời không tồn tại.
					|Cần chắc chắn rằng, trong tùy chỉnh chương trình đã đặt đúng giá trị tham số
					|""%1"".';
					|ru = 'Каталог временных файлов не существует.
					|Необходимо убедиться, что в настройках программы задано правильное значение параметра
					|""%1"".';
					|en = 'Temporary file directory does not exist.
					|Ensure that the value is valid for the parameter:
					|""%1"".'; fa = 'Temporary file directory does not exist.
					|Ensure that the value is valid for the parameter:
					|""%1"".';
					|it = 'Directory di file temporanei inesistente.
					|È necessario accertarsi del fatto che nelle impostazioni del programma sia indicato il valore corretto del parametro
					|""%1"".';
					|pl = 'Katalog tymczasowych plików nie istnieje.
					|Należy upewnić się, że w ustawieniach programu jest podana prawidłowa wartość parametrów
					|""%1"".';
					|tr = 'Geçici dosya dizini mevcut değil. 
					|Uygulama ayarlarında 
					| ""%1"" parametre değerinin doğru belirtildiğinden emin olunmalıdır.'", Common.DefaultLanguageCode());
			
			MessageText = StrTemplate(MessageTemplate, ConstantPresentation);
			Raise(MessageText);
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Initializes columns of object registration rule table by properties.
//
//  Returns:
//    ValueTree
//
Function FilterByExchangePlanPropertiesTableInitialization() Export

	DataProcessor = DataProcessors.ObjectsRegistrationRulesImport;
	Return DataProcessor.FilterByExchangePlanPropertiesTableInitialization();
	
EndFunction

// Initializes columns of object registration rule table by properties.
//
//  Returns:
//    ValueTree
//
Function FilterByObjectPropertiesTableInitialization() Export

	DataProcessor = DataProcessors.ObjectsRegistrationRulesImport;
	Return DataProcessor.FilterByObjectPropertiesTableInitialization();
	
EndFunction

Function IsRegister(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsRegister(MetadataObject);
	
EndFunction

Function IsDocument(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsDocument(MetadataObject);
	
EndFunction

Function IsCatalog(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsCatalog(MetadataObject);
	
EndFunction

Function IsEnum(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsEnum(MetadataObject);
	
EndFunction

Function IsChartOfCharacteristicTypes(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsChartOfCharacteristicTypes(MetadataObject);
	
EndFunction

Function IsBusinessProcess(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsBusinessProcess(MetadataObject);
	
EndFunction

Function IsTask(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsTask(MetadataObject);
	
EndFunction

Function IsChartOfAccounts(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsChartOfAccounts(MetadataObject);
	
EndFunction

Function IsChartOfCalculationTypes(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsChartOfCalculationTypes(MetadataObject);
	
EndFunction

Function IsConstant(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsConstant(MetadataObject);
	
EndFunction

#EndRegion