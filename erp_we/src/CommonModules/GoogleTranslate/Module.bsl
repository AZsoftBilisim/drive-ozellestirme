///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Function TranslateText(Text, TranslationLanguage = Undefined, SourceLanguage = Undefined) Export
	
	If Not ValueIsFilled(Text) Then
		Return Text;
	EndIf;
	
	Return TranslateTheTexts(CommonClientServer.ValueInArray(Text), TranslationLanguage, SourceLanguage)[Text];
	
EndFunction

Function TranslateTheTexts(Texts, TranslationLanguage = Undefined, SourceLanguage = Undefined) Export
	
	If Not Common.AccessToInternetServicesAllowed() Then
		WriteErrorToEventLog(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thực hiện dịch nội dung do:
			|%1';
			|ru = 'Не удалось выполнить перевод текста по причине:
			|%1';
			|en = 'Translation failed:
			|%1'; fa = 'Translation failed:
			|%1';
			|it = 'Translation failed:
			|%1';
			|pl = 'Translation failed:
			|%1';
			|tr = 'Metnin tercüme edilememe nedeni:
			|%1'"), Common.AccessToInternetServicesDeniedMessageText()));
		Raise ErrorText(NStr("vi = 'Không thể dịch văn bản.';
							|ru = 'Не удалось выполнить перевод текста.';
							|en = 'Translation failed.'; fa = 'Translation failed.';
							|it = 'Traduzione non riuscita.';
							|pl = 'Nie udało się wykonać tłumaczenia tekstu.';
							|tr = 'Metnin çevirisi yapılamadı.'"));
	EndIf;
	
	CommonClientServer.CheckParameter("TranslateTheTexts", "Texts", Texts, Type("Array"));
	
	If Not ValueIsFilled(TranslationLanguage) Then
		TranslationLanguage = Common.DefaultLanguageCode();
	EndIf;
	
	HostName = "translation.googleapis.com";
	
	SetPrivilegedMode(True);
	HTTPRequest = New HTTPRequest("/language/translate/v2?key=" + AuthorizationSettings().APIKey);
	SetPrivilegedMode(False);
	
	QueryOptions = New Structure;
	QueryOptions.Insert("format", "text");
	QueryOptions.Insert("q", Texts);
	QueryOptions.Insert("target", TranslationLanguage);
	
	If ValueIsFilled(SourceLanguage) Then
		QueryOptions.Insert("source", SourceLanguage);
	EndIf;
	
	HTTPRequest.SetBodyFromString(Common.ValueToJSON(QueryOptions));
	QueryResult = ExecuteQuery(HTTPRequest, HostName);
	
	If Not QueryResult.QueryCompleted Then
		Raise ErrorText(NStr("vi = 'Không thể dịch văn bản.';
							|ru = 'Не удалось выполнить перевод текста.';
							|en = 'Translation failed.'; fa = 'Translation failed.';
							|it = 'Traduzione non riuscita.';
							|pl = 'Nie udało się wykonać tłumaczenia tekstu.';
							|tr = 'Metnin çevirisi yapılamadı.'"));
	EndIf;
	
	ServerResponse1 = Common.JSONValue(QueryResult.ServerResponse1);
	
	Result = New Map;
	For IndexOf = 0 To Texts.UBound() Do
		Translation = ServerResponse1["data"]["translations"][IndexOf];
		Result.Insert(Texts[IndexOf], Translation["translatedText"]);
		If Not ValueIsFilled(SourceLanguage) Then
			SourceLanguage = Translation["detectedSourceLanguage"];
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function MaxBatchSize() Export
	
	Return 10000;
	
EndFunction

Function AvailableLanguages() Export
	
	HostName = "translation.googleapis.com";
	
	SetPrivilegedMode(True);
	HTTPRequest = New HTTPRequest("/language/translate/v2/languages?key=" + AuthorizationSettings().APIKey);
	SetPrivilegedMode(False);
	
	QueryResult = ExecuteQuery(HTTPRequest, HostName);
	
	If Not QueryResult.QueryCompleted Then
		Raise ErrorText(NStr("vi = 'Không thể nhận danh sách ngôn ngữ khả dụng.';
							|ru = 'Не удалось получить список доступных языков.';
							|en = 'Cannot retrieve the list of available languages.'; fa = 'Cannot retrieve the list of available languages.';
							|it = 'Impossibile ottenere l''elenco delle lingue disponibili.';
							|pl = 'Nie udało się pobrać listy dostępnych języków.';
							|tr = 'Mevcut dillerin listesi alınamadı.'"));
	EndIf;
	
	Result = New Array;
	AvailableLanguages = Common.JSONValue(QueryResult.ServerResponse1);
	For Each Language In AvailableLanguages["data"]["languages"] Do
		LanguageCode = Language["language"];
		Result.Add(LanguageCode);
	EndDo;
	
	Return Result;
	
EndFunction

Function ExecuteQuery(Val HTTPRequest, Val HostName)
	
	Proxy = GetFilesFromInternet.GetProxy("https");
	SecureConnection = CommonClientServer.NewSecureConnection();
	
	Try
		AccessAllowed = Common.AccessToInternetServicesAllowed(True);
		Join = New HTTPConnection(HostName, , , , Proxy, 60, SecureConnection);
		HTTPResponse = Join.Post(HTTPRequest);
	Except
		WriteErrorToEventLog(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kết nối với máy chủ %1 do nguyên nhân:
			|%2';
			|ru = 'Не удалось установить соединение с сервером %1 по причине:
			|%2';
			|en = 'Cannot establish a connection with server %1 due to:
			|%2'; fa = 'Cannot establish a connection with server %1 due to:
			|%2';
			|it = 'Impossibile impostare la connessione con il server %1 a causa di:
			|%2';
			|pl = 'Nie udało się połączyć się z serwerem %1 z powodu:
			|%2';
			|tr = '%1 sunucu ile bağlantı şu sebeple kurulamadı:
			|%2'"), HostName, ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		Raise;
	EndTry;
	
	Result = New Structure;
	Result.Insert("QueryCompleted", False);
	Result.Insert("ServerResponse1", "");
	
	If HTTPResponse.StatusCode <> 200 Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa thực hiện yêu cầu ""%1"". Mã trạng thái: %2.';
				|ru = 'Запрос ""%1"" не выполнен. Код состояния: %2.';
				|en = 'Request ""%1"" failed. Status code: %2.'; fa = 'Request ""%1"" failed. Status code: %2.';
				|it = 'Richiesta ""%1"" non è riuscita. Codice di stato: %2.';
				|pl = 'Zapytanie ""%1"" nie jest wykonane. Kod statusu: %2.';
				|tr = '""%1"" talebi yerine getirilmedi. Durum kodu: %2.'"),
			HTTPRequest.ResourceAddress,
			HTTPResponse.StatusCode) + Chars.LF + HTTPResponse.GetBodyAsString();
		WriteErrorToEventLog(ErrorText);
	EndIf;
		
	If HTTPResponse.StatusCode = 401 
		Or HTTPResponse.StatusCode = 403 Then
		ErrorInfo = Common.JSONValue(HTTPResponse.GetBodyAsString());
		Raise ErrorInfo["error"]["message"];
	EndIf;
	
	Result.QueryCompleted = HTTPResponse.StatusCode = 200;
	Result.ServerResponse1 = HTTPResponse.GetBodyAsString();
	
	Return Result;
	
EndFunction

Function AuthorizationSettings() Export
	
	ParameterNames = "APIKey";
	Result = New Structure(ParameterNames);
	
	If Common.SeparatedDataUsageAvailable() Then
		Owner = Common.MetadataObjectID("Constant.TextTranslationService");
		Settings = Common.ReadDataFromSecureStorage(Owner, ParameterNames);
		
		If TypeOf(Settings) = Type("Structure") Then
			FillPropertyValues(Result, Settings);
		ElsIf TypeOf(Settings) = Type("String") Then
			Result.APIKey = Settings;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  Settings - See TextTranslationTool.TextTranslationServiceSettings
//
Procedure OnDefineSettings(Settings) Export
	
	Settings.ConnectionInstructions = StringFunctions.FormattedString(NStr(
		"vi = 'Cách tùy chỉnh:
		|1. Kích hoạt tài khoản lịch tại <a href = ""%1"">Google Cloud</a>.
		|2. Trên trang <a href = ""%2"">Dữ liệu ghi nhận</a> nhấn nút <b>Tạo dữ liệu kế toán</b>, chọn <b>Khóa API</b>.
		|3. Sao chép dòng đã nhận từ trường <b>Khóa API của bạn</b> trong trường <b>Khóa API</b>.';
		|ru = 'Как настроить:
		|1. Активируйте платежный аккаунт в <a href = ""%1"">Google Cloud</a>.
		|2. На странице <a href = ""%2"">Учетные данные</a> нажмите на кнопку <b>Создать учетные данные</b>, выберите <b>Ключ API</b>.
		|3. Скопируйте полученную строку из поля <b>Ваш ключ API</b> в поле <b>Ключ API</b>.';
		|en = 'How to setup:
		|1. Activate a billing account in <a href = ""%1"">Google Cloud</a>.
		|2. On the <a href = ""%2"">API Credentials</a> page, click <b>Create credentials</b> and select <b>API key</b>.
		|3. Copy the resulting string from the <b>Your API key</b> field into the <b>API key</b> field.'; fa = 'How to setup:
		|1. Activate a billing account in <a href = ""%1"">Google Cloud</a>.
		|2. On the <a href = ""%2"">API Credentials</a> page, click <b>Create credentials</b> and select <b>API key</b>.
		|3. Copy the resulting string from the <b>Your API key</b> field into the <b>API key</b> field.';
		|it = 'Как настроить:
		|1. Активируйте платежный аккаунт в <a href = ""%1"">Google Cloud</a>.
		|2. На странице <a href = ""%2"">Учетные данные</a> нажмите на кнопку <b>Создать учетные данные</b>, выберите <b>Ключ API</b>.
		|3. Скопируйте полученную строку из поля <b>Ваш ключ API</b> в поле <b>Ключ API</b>.';
		|pl = 'How to setup:
		|1. Activate a billing account in <a href = ""%1"">Google Cloud</a>.
		|2. On the <a href = ""%2"">API Credentials</a> page, click <b>Create credentials</b> and select <b>API key</b>.
		|3. Copy the resulting string from the <b>Your API key</b> field into the <b>API key</b> field.';
		|tr = 'Nasıl ayarlanır:
		|1. Ödeme hesabını <a href = ""%1"">Google Cloud</a> üzerinde aktifleştirin.
		|2. <a href = ""%2"">Kimlik bilgileri</a> sayfasında <b>Kimlik bilgilerini oluştur</b> butonuna basın, <b>API anahtar</b> seçin.
		|3. Elde edilen satırı <b>API anahtarınız</b>alanından <b>API anahtarı</b> alanına kopyalayın.'"),
		"https://console.cloud.google.com/billing",
		"https://console.cloud.google.com/apis/credentials");
	
	Parameter = Settings.AuthorizationParameters.Add();
	Parameter.Name = "APIKey";
	Parameter.Presentation = NStr("vi = 'Mã API';
									|ru = 'Ключ API';
									|en = 'API key'; fa = 'API key';
									|it = 'Chiave API';
									|pl = 'Klucz API';
									|tr = 'API anahtarı'");
	Parameter.ToolTipRepresentation = ToolTipRepresentation.ShowTop;
	
EndProcedure

Function SetupExecuted() Export
	
	SetPrivilegedMode(True);
	Return ValueIsFilled(AuthorizationSettings().APIKey);
	
EndFunction

Procedure WriteErrorToEventLog(Comment)
	
	WriteLogEvent(NStr("vi = 'Dịch văn bản';
						|ru = 'Перевод текста';
						|en = 'Translator'; fa = 'مترجم';
						|it = 'Traduzione del testo';
						|pl = 'Tłumaczenie tekstu';
						|tr = 'Metin çevirisi'", Common.DefaultLanguageCode()),
		EventLogLevel.Error, , Enums.TextTranslationServices.GoogleTranslate, Comment);
	
EndProcedure

Function ErrorText(ErrorText)
	
	If Users.IsFullUser() Then
		Return ErrorText + Chars.LF + NStr("vi = 'Chi tiết xem trong nhật ký sự kiện';
											|ru = 'Подробности см. в журнале регистрации.';
											|en = 'See the Event log for details.'; fa = 'See the Event log for details.';
											|it = 'Vedere il registro per i dettagli.';
											|pl = 'Szczegóły zob. w dzienniku rejestracji.';
											|tr = 'Ayrıntılar için olay günlüğüne bakın.'");
	EndIf;
	
	Return ErrorText + Chars.LF + NStr("vi = 'Hãy liên hệ với người quản trị.';
										|ru = 'Обратитесь к администратору.';
										|en = 'Please contact the administrator.'; fa = 'Please contact the administrator.';
										|it = 'Contattate l''amministratore.';
										|pl = 'Skontaktuj się z administratorem.';
										|tr = 'Yöneticiye başvurun.'");
	
EndFunction

// Returns a list of permissions to use the translation service.
//
// Returns:
//  Array
//
Function Permissions() Export
	
	Protocol = "HTTPS";
	Address = "translation.googleapis.com";
	Port = Undefined;
	LongDesc = NStr("vi = 'Dịch vụ dịch nội dung Google Translate';
					|ru = 'Сервис перевода текста Google Translate';
					|en = 'Google Translate translation service'; fa = 'Google Translate translation service';
					|it = 'Servizio di traduzione del testo Google Translate';
					|pl = 'Serwis tłumaczenia tekstu Google Translate';
					|tr = 'Google Translate metin çeviri hizmeti'");
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Resolution = ModuleSafeModeManager.PermissionToUseInternetResource(Protocol, Address, Port, LongDesc);
	
	Permissions = New Array;
	Permissions.Add(Resolution);
	
	Return Permissions;
	
EndFunction

#EndRegion
