///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	
	Parameters.Insert("ProxyServerSettings", GetFilesFromInternet.ProxySettingsAtClient());
	
EndProcedure

// See SafeModeManagerOverridable.OnEnableSecurityProfiles.
Procedure OnEnableSecurityProfiles() Export
	
	// Reset proxy settings to default condition.
	SaveServerProxySettings(Undefined);
	
	WriteLogEvent(EventLogEvent(),
		EventLogLevel.Warning, Metadata.Constants.ProxyServerSetting,,
		NStr("vi = 'Khi bật hồ sơ bảo mật, đã đặt lại các tùy chỉnh Proxy-server về tùy chỉnh hệ thống.';
			|ru = 'При включении профилей безопасности настройки прокси-сервера сброшены на системные.';
			|en = 'Since a security profile is enabled, the proxy server settings are reverted to the default ones.'; fa = 'Since a security profile is enabled, the proxy server settings are reverted to the default ones.';
			|it = 'Quando si abilitano i profili di sicurezza, le impostazioni del server proxy vengono ripristinate su quelle del sistema.';
			|pl = 'Po włączeniu profili zabezpieczeń ustawienia serwera proxy zostaną zresetowane na systemowe.';
			|tr = 'Güvenlik profillerini etkinleştirirken, proxy sunucu ayarları varsayılan değerlere sıfırlandı.'"));
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Permissions = New Array();
	
	// Permissions for running the procedures "GetFilesFromInternetInternal.CheckServerAvailability"
	// and "GetFilesFromInternetInternal.ServerRouteTraceLog".
	If Common.IsWindowsServer() Then
		Permissions.Add(ModuleSafeModeManager.PermissionToUseOperatingSystemApplications("cmd /S /C ""%(ping %)%""",
			NStr("vi = 'Cho phép đối với ping';
				|ru = 'Разрешение для ping';
				|en = 'Permission for ping'; fa = 'Permission for ping';
				|it = 'Autorizzazione per ping';
				|pl = 'Zezwolenie dla ping';
				|tr = 'Ping için izin'", Common.DefaultLanguageCode())));
		Permissions.Add(ModuleSafeModeManager.PermissionToUseOperatingSystemApplications("cmd /S /C ""%(tracert %)%""",
			NStr("vi = 'Cho phép đối với tracert.';
				|ru = 'Разрешение для tracert.';
				|en = 'Permission for tracert.'; fa = 'Permission for tracert.';
				|it = 'Autorizzazione per tracert.';
				|pl = 'Zezwolenie dla tracert.';
				|tr = 'Tracert için izin.'", Common.DefaultLanguageCode())));
	ElsIf Common.IsLinuxServer() Then
		Permissions.Add(ModuleSafeModeManager.PermissionToUseOperatingSystemApplications("ping % % % % %",
			NStr("vi = 'Cho phép đối với ping';
				|ru = 'Разрешение для ping';
				|en = 'Permission for ping'; fa = 'Permission for ping';
				|it = 'Autorizzazione per ping';
				|pl = 'Zezwolenie dla ping';
				|tr = 'Ping için izin'", Common.DefaultLanguageCode())));
		Permissions.Add(ModuleSafeModeManager.PermissionToUseOperatingSystemApplications("traceroute % % % % %",
			NStr("vi = 'Cho phép đối với traceroute.';
				|ru = 'Разрешение для traceroute.';
				|en = 'Permission for traceroute.'; fa = 'Permission for traceroute.';
				|it = 'Autorizzazione per traceroute.';
				|pl = 'Zezwolenie dla traceroute.';
				|tr = 'Traceroute için izin.'", Common.DefaultLanguageCode())));
	EndIf;
	
	PermissionsRequests.Add(
		ModuleSafeModeManager.RequestToUseExternalResources(Permissions));
	
EndProcedure


#EndRegion

#Region Private

#Region Proxy

// Saves proxy server setting parameters on the 1C:Enterprise server side.
//
Procedure SaveServerProxySettings(Val Settings) Export
	
	If Not Users.IsFullUser(, True) Then
		Raise(NStr("vi = 'Không đủ quyền để thực hiện giao dịch.';
					|ru = 'Недостаточно прав для выполнения операции.';
					|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
					|it = 'Diritti insufficienti per eseguire l''operazione.';
					|pl = 'Niewystarczające uprawnienia do wykonania operacji.';
					|tr = 'İşlem için gerekli yetkiler yok.'"), ErrorCategory.AccessViolation);
	EndIf;
	
	SetPrivilegedMode(True);
	Constants.ProxyServerSetting.Set(New ValueStorage(Settings, New Deflation(9)));
	
EndProcedure

#EndRegion

#Region DownloadFile

#If Not WebClient Then

// function meant for getting files from the Internet
//
// Parameters:
//   URL           - String - file url.
//   ReceivingParameters   - Structure:
//    * PathForSaving            - String - path on the server (including file name) for saving the downloaded file.
//    * User                 - String - a user that established the connection.
//    * Password                       - String - the password of the user that established the connection.
//    * Port                         - Number  - a port used for connecting to the server.
//    * Timeout                      - Number  - the file download timeout, in seconds.
//    * SecureConnection         - Boolean - in case of http download the flag shows
//                                             that the connection must be established via https.
//    * PassiveConnection          - Boolean - in case of ftp download the flag shows
//                                             that the connection must be passive (or active).
//    * Headers                    - Map - see the details of the Headers parameter of the HTTPRequest object.
//    * UseOSAuthentication - Boolean - see the details of the UseOSAuthentication parameter of the HTTPConnection object.
//    * IsPackageDeliveryCheckOnErrorEnabled - See GetFilesFromInternet.ConnectionDiagnostics.IsPackageDeliveryCheckEnabled.
//    
//
//   SavingSetting - Map - contains parameters to save the downloaded file. Keys:
//                 StorageLocation - String - can include
//                        "Server" - server,
//                        "TemporaryStorage" - temporary storage.
//                 Path - String (optional parameter) -
//                        path to folder at client or at server or temporary storage address will be generated
//                        if not specified.
//   WriteError1 - Boolean                     
//
// Returns:
//   Structure:
//      * Status - Boolean
//      * Path   - String
//      * ErrorMessage - String
//      * Headers         - Map
//      * StatusCode      - Number
//
Function DownloadFile(Val URL, Val ReceivingParameters, Val SavingSetting, Val WriteError1 = True) Export
	
	ReceivingSettings = GetFilesFromInternetClientServer.FileGettingParameters();
	If ReceivingParameters <> Undefined Then
		FillPropertyValues(ReceivingSettings, ReceivingParameters);
	EndIf;
	
	If SavingSetting.Get("StorageLocation") <> "TemporaryStorage" Then
		SavingSetting.Insert("Path", ReceivingSettings.PathForSaving);
	EndIf;
	
	ProxyServerSetting = GetFilesFromInternet.ProxySettingsAtServer();
	
	Redirections = New Array;
	
	Return GetFileFromInternet(URL, SavingSetting, ReceivingSettings,
		ProxyServerSetting, WriteError1, Redirections);
	
EndFunction

// function meant for getting files from the Internet
//
// Parameters:
//   URL - String - file URL in the following format: [Protocol://]<Server>/<Path to the file on the server>.
//   
// SavingSetting - Map - contains parameters to save the downloaded file.
//		StorageLocation - String - Valid values are
//			"Server" - A server.
//			"TemporaryStorage" - A temporary storage.
//		Path - String - (Optional) Either the path to a folder at the client or at the server
//			or the address in a temporary storage. If not specified, it will be generated automatically.
//
// ConnectionSetting - Map -
//		SecureConnection* - Boolean - Secure connection.
//		PassiveConnection* - Boolean - Secure connection.
//		User - String - User that established the connection.
//		Password - String - Password of the user that established the connection.
//		Port - Number - Port used for connecting to the server.
//		... - See GetFilesFromInternet.ConnectionDiagnostics.IsPackageDeliveryCheckEnabled
//		* - Mutually exclusive keys.
//
// ProxySettings - Map of KeyAndValue:
//     * Key - String
//     * Value - Arbitrary
//    Keys are:
//		# UseProxy - Boolean - Indicates whether to use the proxy server.
//		# BypassProxyOnLocal - Boolean - Indicates whether to use the proxy server for local addresses.
//		# UseSystemSettings - Boolean - Indicates whether to use the system settings of the proxy server.
//		# Server - String - a proxy server address.
//		# Port - Number - Proxy server port.
//		# User - String - Username for authorization on the proxy server.
//		# Password - String - User password.
//		
//
//
// Returns:
//   Structure:
//      * Status - Boolean
//      * Path   - String
//      * ErrorMessage - String
//      * Headers         - Map
//      * StatusCode      - Number
//
Function GetFileFromInternet(Val URL, Val SavingSetting, Val ConnectionSetting,
	Val ProxySettings, Val WriteError1, Redirections = Undefined)
	
	If ConnectionSetting.ShouldCheckAccessToInternetServices And Not Common.AccessToInternetServicesAllowed() Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận tệp %1 do:
					|%2';
					|ru = 'Не удалось получить файл %1 по причине:
					|%2';
					|en = 'Couldn''t get the file ""%1"" due to:
					|%2'; fa = 'Couldn''t get the file ""%1"" due to:
					|%2';
					|it = 'Couldn''t get the file ""%1"" due to:
					|%2';
					|pl = 'Couldn''t get the file ""%1"" due to:
					|%2';
					|tr = '%1 dosyası şu nedenle alınamadı:
					|%2'"), URL, Common.AccessToInternetServicesDeniedMessageText());
					
			If WriteError1 Then
				WriteErrorToEventLog(ErrorText);
			EndIf;
		Return FileGetResult(False, ErrorText);
		
	EndIf;
	
	URIStructure = CommonClientServer.URIStructure(URL);
	
	Server        = URIStructure.Host;
	PathAtServer = URIStructure.PathAtServer;
	Protocol      = URIStructure.Schema;
	
	If IsBlankString(Protocol) Then 
		Protocol = "http";
	EndIf;
	
	SecureConnection = ConnectionSetting.SecureConnection;
	UserName      = ConnectionSetting.User;
	UserPassword   = ConnectionSetting.Password;
	Port                 = ConnectionSetting.Port;
	Timeout              = ConnectionSetting.Timeout;
	IsPackageDeliveryCheckOnErrorEnabled = ConnectionSetting.IsPackageDeliveryCheckOnErrorEnabled;
	
	If (Protocol = "https" Or Protocol = "ftps") And SecureConnection = Undefined Then
		SecureConnection = True;
	EndIf;
	
	If SecureConnection = True Then
		SecureConnection = CommonClientServer.NewSecureConnection();
	ElsIf SecureConnection = False Then
		SecureConnection = Undefined;
		// Otherwise the SecureConnection parameter was specified explicitly.
	EndIf;
	
	If Port = Undefined Then
		Port = URIStructure.Port;
	EndIf;
	
	If ProxySettings = Undefined Then 
		Proxy = Undefined;
	Else 
		Proxy = NewInternetProxy(ProxySettings, Protocol);
	EndIf;
	
	If SavingSetting["Path"] <> Undefined Then
		PathForSaving = SavingSetting["Path"];
	Else
		PathForSaving = GetTempFileName(); // ACC:441 The temporary file must be deleted by the calling code.
	EndIf;
	
	If Timeout = Undefined Then 
		Timeout = GetFilesFromInternetClientServer.AutomaticTimeoutDetermination();
	EndIf;
	
	FTPProtocolISUsed = (Protocol = "ftp" Or Protocol = "ftps");
	
	If FTPProtocolISUsed Then
		
		PassiveConnection                       = ConnectionSetting.PassiveConnection;
		SecureConnectionUsageLevel = ConnectionSetting.SecureConnectionUsageLevel;
		
		Try
			
			If Timeout = GetFilesFromInternetClientServer.AutomaticTimeoutDetermination() Then
				
				Join = New FTPConnection(
					Server, 
					Port, 
					UserName, 
					UserPassword,
					Proxy, 
					PassiveConnection, 
					7, 
					SecureConnection, 
					SecureConnectionUsageLevel);
				
				FileSize = FTPFileSize1(Join, PathAtServer);
				Timeout = GetFilesFromInternet.FileImportTimeout(FileSize);
				
			EndIf;
			
			Join = New FTPConnection(
				Server, 
				Port, 
				UserName, 
				UserPassword,
				Proxy, 
				PassiveConnection, 
				Timeout, 
				SecureConnection, 
				SecureConnectionUsageLevel);
			
			Server = Join.Host;
			Port   = Join.Port;
			
			Join.Get(PathAtServer, PathForSaving);
			
		Except
			
			DiagnosticsResult = GetFilesFromInternet.ConnectionDiagnostics(URL, WriteError1, 
				IsPackageDeliveryCheckOnErrorEnabled);
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể lấy tệp %1 từ máy chủ %2:%3
				           |vì lý do:
				           |%4
				           |Kết quả chẩn đoán:
				           |%5';
				           |ru = 'Не удалось получить файл %1 с сервера %2:%3
				           |по причине:
				           |%4
				           |Результат диагностики:
				           |%5';
				           |en = 'Cannot get file %1 from server %2:%3.
				           |Reason:
				           |%4
				           |Diagnostics result:
				           |%5'; fa = 'Cannot get file %1 from server %2:%3.
				           |Reason:
				           |%4
				           |Diagnostics result:
				           |%5';
				           |it = 'Impossibile acquisire il file %1 dal server%2:%3
				           |a causa di:
				           |%4
				           | Risultato diagnostico:
				           |%5';
				           |pl = 'Nie można pobrać plik %1 z serwera %2:%3
				           | w wyniku:
				           |%4
				           |Wynik diagnostyki:
				           |%5';
				           |tr = 'Dosyayı %1 sunucudan %2: %3
				           |aşağıdaki nedenle alınamadı:
				           |%4
				           |Tanılama sonuçları:
				           |%5'"),
				URL, Server, Format(Port, "NG="),
				ErrorProcessing.BriefErrorDescription(ErrorInfo()),
				DiagnosticsResult.ErrorDescription);
				
			If WriteError1 Then
				ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1
					           |
					           |Tìm kiếm:
					           |Kết nối bảo mật: %2
					           |Time-out: %3';
					           |ru = '%1
					           |
					           |Трассировка:
					           |Защищенное соединение: %2
					           |Таймаут: %3';
					           |en = '%1
					           |
					           |Trace parameters:
					           |Secure connection: %2
					           |Timeout: %3'; fa = '%1
					           |
					           |Trace parameters:
					           |Secure connection: %2
					           |Timeout: %3';
					           |it = '%1
					           |
					           |Tracciamento
					           |Connessione protetta: %2
					           |Time-out: %3';
					           |pl = '%1
					           |
					           |Śledzenie:
					           |Chronione połączenie: %2
					           |Limit czasu: %3';
					           |tr = '%1
					           |
					           |İzleme:
					           |Güvenli bağlantı: %2
					           |Zaman aşımı: %3'"),
					ErrorText,
					Format(Join.SecureConnection <> Undefined, NStr("vi = 'БЛ=Không; БИ=Có';
																	|ru = 'БЛ=Нет; БИ=Да';
																	|en = 'BF=No; BT=Yes'; fa = 'BF=خیر; BT=بله';
																	|it = 'БЛ=No; БИ=Si';
																	|pl = 'BF=Nie; BT=Tak';
																	|tr = 'BF=Hayır; BT=Evet'")),
					Format(Join.Timeout, "NG=0"));
					
				WriteErrorToEventLog(ErrorMessage);
			EndIf;
			
			Return FileGetResult(False, ErrorText);
			
		EndTry;
		
	Else // HTTP protocol is used.
		
		Headers                    = ConnectionSetting.Headers;
		UseOSAuthentication = ConnectionSetting.UseOSAuthentication;
		
		Try
			
			If Timeout = GetFilesFromInternetClientServer.AutomaticTimeoutDetermination() Then
				
				Join = New HTTPConnection(
					Server, 
					Port, 
					UserName, 
					UserPassword,
					Proxy, 
					7, 
					SecureConnection, 
					UseOSAuthentication);
				
				FileSize = HTTPFileSize(Join, PathAtServer, Headers);
				Timeout = GetFilesFromInternet.FileImportTimeout(FileSize);
				
			EndIf;
			
			Join = New HTTPConnection(
				Server, 
				Port, 
				UserName, 
				UserPassword,
				Proxy, 
				Timeout, 
				SecureConnection, 
				UseOSAuthentication);
			
			Server = Join.Host;
			Port   = Join.Port;
			
			HTTPRequest = New HTTPRequest(PathAtServer, Headers);
			HTTPRequest.Headers.Insert("Accept-Charset", "UTF-8");
			HTTPRequest.Headers.Insert("X-1C-Request-UID", String(New UUID));
			HTTPResponse = Join.Get(HTTPRequest, PathForSaving);
			
		Except
			
			BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			
			DiagnosticsResult = GetFilesFromInternet.ConnectionDiagnostics(URL, WriteError1,
				IsPackageDeliveryCheckOnErrorEnabled, BriefErrorDescription);
			
			ErrorTemplate = NStr("vi = 'Không thể thiết lập kết nối HTTP với server %1:%2
				|vì lý do:
				|%3
				|
				|Kết quả chẩn đoán:
				|%4';
				|ru = 'Не удалось установить HTTP-соединение с сервером %1:%2
				|по причине:
				|%3
				|
				|Результат диагностики:
				|%4';
				|en = 'Cannot establish HTTP connection to server %1:%2.
				|Reason:
				|%3
				|
				|Diagnostics result:
				|%4'; fa = 'Cannot establish HTTP connection to server %1:%2.
				|Reason:
				|%3
				|
				|Diagnostics result:
				|%4';
				|it = 'Non è stato possibile stabilire una connessione HTTP con il server %1:%2
				|a causa di:
				|%3
				|
				|Risultato della diagnostica:
				|%4';
				|pl = 'Nie udało się powiązać połączenie HTTP z serwerem %1:%2
				|z powodu:
				|%3
				|
				|Rezultat diagnostyki:
				|%4';
				|tr = 'Sunucu ile HTTP-bağlantı yapılamadı %1:%2
				|nedenle:
				|%3
				|
				|Tanılama sonuçları:
				|%4'");
			
			RedirectionPresentations = RedirectionPresentations(Redirections);
			If Not IsBlankString(RedirectionPresentations) Then
				ErrorTemplate = ErrorTemplate + Chars.LF + Chars.LF + RedirectionPresentations;
			EndIf;
			
			If WriteError1 Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
					Server, Format(Port, "NG="),
					ErrorProcessing.DetailErrorDescription(ErrorInfo()),
					DiagnosticsResult.ErrorDescription);
				WriteErrorToEventLog(ErrorText);
			EndIf;
				
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
				Server, Format(Port, "NG="),
				BriefErrorDescription,
				DiagnosticsResult.ErrorDescription);
			Return FileGetResult(False, ErrorText);
			
		EndTry;
		
		Try
			
			If HTTPResponse.StatusCode = 301 // 301 Moved Permanently
				Or HTTPResponse.StatusCode = 302 // 302 Found, 302 Moved Temporarily
				Or HTTPResponse.StatusCode = 303 // 303 See Other by GET
				Or HTTPResponse.StatusCode = 307 // 307 Temporary Redirect
				Or HTTPResponse.StatusCode = 308 Then // 308 Permanent Redirect
				
				If Redirections.Count() > 7 Then
					Raise(NStr("vi = 'Đã vượt quá số lần chuyển hướng.';
								|ru = 'Превышено количество перенаправлений.';
								|en = 'Redirections limit exceeded.'; fa = 'Redirections limit exceeded.';
								|it = 'Superato il numero di reindirizzamenti.';
								|pl = 'Przekroczono liczbę przekierowań.';
								|tr = 'Tekrar yönlendirme sayısı arttı.'"), ErrorCategory.NetworkError);
				EndIf;
					
				NewURL1 = StandardSubsystemsServer.HTTPHeadersInLowercase(HTTPResponse.Headers)["location"];
				If NewURL1 = Undefined Then 
					Raise(NStr("vi = 'Chuyển hướng sai, không có HTTP-tiêu đề phản hồi ""Location"".';
								|ru = 'Некорректное перенаправление, отсутствует HTTP-заголовок ответа ""Location"".';
								|en = 'Invalid redirection: no ""Location"" header in the HTTP response.'; fa = 'Invalid redirection: no ""Location"" header in the HTTP response.';
								|it = 'Reindirizzamento non valido, manca l''intestazione della posizione HTTP.';
								|pl = 'Niepoprawne przekierowanie, brak nagłówka odpowiedzi HTTP ""Location"".';
								|tr = 'Yanlış yönlendirme, ""Konum"" yanıtının HTTP üstbilgisi eksik.'"),
						ErrorCategory.NetworkError);
				EndIf;
				
				NewURL1 = TrimAll(NewURL1);
				If IsBlankString(NewURL1) Then
					Raise(NStr("vi = 'Chuyển hướng sai, HTTP-tiêu đề phản hồi ""Location"" trống.';
								|ru = 'Некорректное перенаправление, пустой HTTP-заголовок ответа ""Location"".';
								|en = 'Invalid redirection: blank ""Location"" header in the HTTP response.'; fa = 'Invalid redirection: blank ""Location"" header in the HTTP response.';
								|it = 'Reindirizzamento non valido, intestazione di risposta HTTP Location vuota.';
								|pl = 'Niepoprawne przekierowanie, pusty nagłówek odpowiedzi HTTP ""Location"".';
								|tr = 'Yanlış yönlendirme, ""Konum"" yanıtının HTTP üstbilgisi boş.'"),
						ErrorCategory.NetworkError);
				EndIf;
				
				If Redirections.Find(NewURL1) <> Undefined Then
					Raise(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Chuyển hướng vòng lặp.
									|Trước đó, đã thử chuyển đến %1.';
									|ru = 'Циклическое перенаправление.
									|Попытка перейти на %1 уже выполнялась ранее.';
									|en = 'Circular redirect.
									|Redirect to %1 was attempted earlier.'; fa = 'Circular redirect.
									|Redirect to %1 was attempted earlier.';
									|it = 'Reindirizzamento ciclico. 
									|Tentativo di passare a %1 eseguito precedentemente.';
									|pl = 'Cykliczne przekierowanie.
									|Próba przejścia na %1 już uruchomione wcześniej.';
									|tr = 'Döngüsel yönlendirme. 
									|Daha önce zaten devam etmeye %1çalışıyor.'"),
						NewURL1),
						ErrorCategory.NetworkError);
				EndIf;
				
				Redirections.Add(URL);
				If Not StrStartsWith(NewURL1, "http") Then
					// <scheme>://<host>:<port>/<path>
					NewURL1 = StringFunctionsClientServer.SubstituteParametersToString(
						"%1://%2:%3/%4", Protocol, Server, Format(Port, "NG="), NewURL1);
				EndIf;
				
				Return GetFileFromInternet(NewURL1, SavingSetting, ConnectionSetting,
					ProxySettings, WriteError1, Redirections);
				
			EndIf;
			
			If HTTPResponse.StatusCode < 200 Or HTTPResponse.StatusCode >= 300 Then
				
				If HTTPResponse.StatusCode = 304 Then
					
					HTTPHeaders = StandardSubsystemsServer.HTTPHeadersInLowercase(HTTPRequest.Headers);
					If (HTTPHeaders["if-modified-since"] <> Undefined Or HTTPHeaders["if-none-match"] <> Undefined) Then
						WriteError1 = False;
					EndIf;
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Server internet tin rằng, phản hồi của nó không thay đổi kể từ lần yêu cầu cuối cùng của bạn:
						           |%1';
						           |ru = 'Интернет-сервер убежден, что с вашего последнего запроса его ответ не изменился:
						           |%1';
						           |en = 'Web server response has not changed since your last request:
						           |%1'; fa = 'Web server response has not changed since your last request:
						           |%1';
						           |it = 'Интернет-сервер убежден, что с вашего последнего запроса его ответ не изменился:
						           |%1';
						           |pl = 'Web server response has not changed since your last request:
						           |%1';
						           |tr = 'İnternet sunucu, son sorgunuzdan beri cevabının değişmediğini düşünüyor: 
						           |%1'"),
						HTTPConnectionCodeDetails(HTTPResponse.StatusCode));
					
					AddServerResponseBody(PathForSaving, ErrorText);
					Raise(ErrorText, ErrorCategory.NetworkError);
					
				ElsIf HTTPResponse.StatusCode < 200
					Or HTTPResponse.StatusCode >= 300 And HTTPResponse.StatusCode < 400 Then
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Phản hồi của máy chủ internet không được hỗ trợ:
						           |%1';
						           |ru = 'Неподдерживаемый ответ интернет-сервера:
						           |%1';
						           |en = 'Unsupported web server response:
						           |%1'; fa = 'Unsupported web server response:
						           |%1';
						           |it = 'Неподдерживаемый ответ интернет-сервера:
						           |%1';
						           |pl = 'Unsupported web server response:
						           |%1';
						           |tr = 'İnternet sunucunun desteklenmeyen cevabı:
						           |%1'"),
						HTTPConnectionCodeDetails(HTTPResponse.StatusCode));
					
					AddServerResponseBody(PathForSaving, ErrorText);
					Raise(ErrorText, ErrorCategory.NetworkError);
					
				ElsIf HTTPResponse.StatusCode >= 400 And HTTPResponse.StatusCode < 500 Then 
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Server internet không thể thực hiện yêu cầu:
						           |%1';
						           |ru = 'Интернет-сервер не смог выполнить запрос:
						           |%1';
						           |en = 'Web server request failed:
						           |%1'; fa = 'Web server request failed:
						           |%1';
						           |it = 'Интернет-сервер не смог выполнить запрос:
						           |%1';
						           |pl = 'Web server request failed:
						           |%1';
						           |tr = 'İnternet sunucusu talep oluşturamadı: 
						           |%1'"),
						HTTPConnectionCodeDetails(HTTPResponse.StatusCode));
					
					AddServerResponseBody(PathForSaving, ErrorText);
					Raise(ErrorText, ErrorCategory.NetworkError);
					
				Else 
					
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Server internet đã quá tải, tạm thời tắt sử dụng hoặc đang bảo trì:
						           |%1';
						           |ru = 'Интернет-сервер перегружен, временно отключен или находится на техобслуживании:
						           |%1';
						           |en = 'Web server is overwhelmed, disconnected, or under maintenance:
						           |%1'; fa = 'Web server is overwhelmed, disconnected, or under maintenance:
						           |%1';
						           |it = 'Интернет-сервер перегружен, временно отключен или находится на техобслуживании:
						           |%1';
						           |pl = 'Web server is overwhelmed, disconnected, or under maintenance:
						           |%1';
						           |tr = 'İnternet sunucusu aşırı yüklenmiş, geçici olarak devre dışı veya bakımda:
						           |%1'"),
						HTTPConnectionCodeDetails(HTTPResponse.StatusCode));
					
					AddServerResponseBody(PathForSaving, ErrorText);
					Raise(ErrorText, ErrorCategory.NetworkError);
					
				EndIf;
				
			EndIf;
			
		Except
			
			ErrorTemplate = NStr("vi = 'Không thể nhận tệp %1 từ server %2:%3
				|do nguyên nhân:
				|%4';
				|ru = 'Не удалось получить файл %1 с сервера %2:%3
				|по причине:
				|%4';
				|en = 'Cannot get file %1 from server %2.%3
				|Reason:
				|%4'; fa = 'Cannot get file %1 from server %2.%3
				|Reason:
				|%4';
				|it = 'Impossibile acquisire il file %1 dal server%2:%3
				|a causa di:
				|%4';
				|pl = 'Nie udało się pobrać pliku %1 z serwera %2:%3
				| z powodu:
				|%4';
				|tr = 'Dosyayı %1 sunucudan %2: %3
				|aşağıdaki nedenle alınamadı:
				|%4'");
			
			RedirectionPresentations = RedirectionPresentations(Redirections);
			If Not IsBlankString(RedirectionPresentations) Then
				ErrorTemplate = ErrorTemplate + Chars.LF + Chars.LF + RedirectionPresentations;
			EndIf;
				
			If WriteError1 Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
					URL, Server, Format(Port, "NG="),
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1
					           |
					           |Tìm kiếm:
					           |Kết nối bảo mật: %2
					           |Hết giờ: %3
					           |Đăng nhập hệ điều hành: %4';
					           |ru = '%1
					           |
					           |Трассировка:
					           |Защищенное соединение: %2
					           |Таймаут: %3
					           |Аутентификация ОС: %4';
					           |en = '%1
					           |
					           |Trace parameters:
					           |Secure connection: %2
					           |Timeout: %3
					           |OS authentication: %4'; fa = '%1
					           |
					           |Trace parameters:
					           |Secure connection: %2
					           |Timeout: %3
					           |OS authentication: %4';
					           |it = '%1
					           |
					           |Tracciamento
					           |Connessione protetta: %2
					           |Time-out: %3
					           | Autenticazione sistema operativo: %4';
					           |pl = '%1
					           |
					           |Śledzenie:
					           |Chronione połączenie: %2
					           |Limit czasu: %3
					           |Uwierzytelnianie systemu operacyjnego: %4';
					           |tr = '%1
					           |
					           |İzleme:
					           |Güvenli bağlantı: %2
					           |Zaman aşımı: %3
					           |Sabit kıymetlerin doğrulaması: %4'"),
					ErrorText,
					Format(Join.SecureConnection <> Undefined, NStr("vi = 'БЛ=Không; БИ=Có';
																	|ru = 'БЛ=Нет; БИ=Да';
																	|en = 'BF=No; BT=Yes'; fa = 'BF=خیر; BT=بله';
																	|it = 'БЛ=No; БИ=Si';
																	|pl = 'BF=Nie; BT=Tak';
																	|tr = 'BF=Hayır; BT=Evet'")),
					Format(Join.Timeout, "NG=0"),
					Format(Join.UseOSAuthentication, NStr("vi = 'БЛ=Không; БИ=Có';
															|ru = 'БЛ=Нет; БИ=Да';
															|en = 'BF=No; BT=Yes'; fa = 'BF=خیر; BT=بله';
															|it = 'БЛ=No; БИ=Si';
															|pl = 'BF=Nie; BT=Tak';
															|tr = 'BF=Hayır; BT=Evet'")));
				
				AddHTTPHeaders(HTTPRequest, ErrorMessage);
				AddHTTPHeaders(HTTPResponse, ErrorMessage);
				
				WriteErrorToEventLog(ErrorMessage);
			EndIf;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
				URL, Server, Format(Port, "NG="),
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
			Return FileGetResult(False, ErrorText, HTTPResponse);
			
		EndTry;
		
	EndIf;
	
	// If the file is saved in accordance with the setting.
	If SavingSetting["StorageLocation"] = "TemporaryStorage" Then
		UniqueKey = New UUID;
		Address = PutToTempStorage (New BinaryData(PathForSaving), UniqueKey);
		Return FileGetResult(True, Address, HTTPResponse);
	ElsIf SavingSetting["StorageLocation"] = "Server" Then
		Return FileGetResult(True, PathForSaving, HTTPResponse);
	Else
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa chỉ ra nơi để lưu tệp khi gọi ra %1.';
				|ru = 'Не указано место для сохранения файла при вызове %1.';
				|en = 'File save location is not specified for ""%1"".'; fa = 'File save location is not specified for ""%1"".';
				|it = 'Не указано место для сохранения файла при вызове %1.';
				|pl = 'File save location is not specified for ""%1"".';
				|tr = 'Arama sırasında dosyayı kaydetmek için konum belirtilmedi %1.'"), "GetFileFromInternet"),
			ErrorCategory.ConfigurationError);
	EndIf;
	
EndFunction

// Parameters:
//   Status - Boolean - success or failure of the operation.
//   MessagePath - String
//   HTTPResponse - HTTPResponse
//
// Returns:
//   Structure:
//      * Status - Boolean
//      * Path   - String
//      * ErrorMessage - String
//      * Headers         - Map
//      * StatusCode      - Number
//
Function FileGetResult(Val Status, Val MessagePath, HTTPResponse = Undefined)
	
	Result = New Structure("Status", Status);
	
	If Status Then
		Result.Insert("Path", MessagePath);
	Else
		Result.Insert("ErrorMessage", MessagePath);
		Result.Insert("StatusCode", 1);
	EndIf;
	
	If HTTPResponse <> Undefined Then
		ResponseHeadings = HTTPResponse.Headers;
		If ResponseHeadings <> Undefined Then
			Result.Insert("Headers", ResponseHeadings);
		EndIf;
		
		Result.Insert("StatusCode", HTTPResponse.StatusCode);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function HTTPFileSize(HTTPConnection, Val PathAtServer, Val Headers = Undefined)
	
	HTTPRequest = New HTTPRequest(PathAtServer, Headers);
	Try
		ReceivedHeaders = HTTPConnection.Head(HTTPRequest);// HEAD
	Except
		Return 0;
	EndTry;
	SizeInString = StandardSubsystemsServer.HTTPHeadersInLowercase(ReceivedHeaders.Headers)["content-length"];
	
	NumberType = New TypeDescription("Number");
	FileSize = NumberType.AdjustValue(SizeInString);
	
	Return FileSize;
	
EndFunction

Function FTPFileSize1(FTPConnection, Val PathAtServer)
	
	FileSize = 0;
	
	Try
		FilesFound = FTPConnection.FindFiles(PathAtServer);
		If FilesFound.Count() > 0 Then
			FileSize = FilesFound[0].Size();
		EndIf;
	Except
		FileSize = 0;
	EndTry;
	
	Return FileSize;
	
EndFunction

Function HTTPConnectionCodeDetails(StatusCode)
	
	If StatusCode = 304 Then // Not Modified
		Details = NStr("vi = 'Không cần chuyển lại tài nguyên được yêu cầu.';
						|ru = 'Нет необходимости повторно передавать запрошенные ресурсы.';
						|en = 'There is no need to retransmit the requested resources.'; fa = 'There is no need to retransmit the requested resources.';
						|it = 'Non è necessario trasmettere nuovamente le risorse richieste.';
						|pl = 'Nie trzeba ponownie przesyłać żądanych zasobów.';
						|tr = 'Talep edilen kaynaklar tekrar aktarılmaz.'");
	ElsIf StatusCode = 400 Then // Bad Request
		Details = NStr("vi = 'Chưa thể thực hiện truy vấn.';
						|ru = 'Запрос не может быть исполнен.';
						|en = 'Couldn''t process the request.'; fa = 'Couldn''t process the request.';
						|it = 'La richiesta non può essere eseguita.';
						|pl = 'Żądanie nie może zostać wykonane.';
						|tr = 'Talep yerine getirilemez.'");
	ElsIf StatusCode = 401 Then // Unauthorized
		Details = NStr("vi = 'Đã vô hiệu hóa việc thử đăng nhập đến máy chủ.';
						|ru = 'Попытка авторизации на сервере была отклонена.';
						|en = 'The server denied authorization.'; fa = 'The server denied authorization.';
						|it = 'Il tentativo di autorizzazione sul server è stato respinto.';
						|pl = 'Próba autoryzacji na serwerze została odrzucona.';
						|tr = 'Sunucudaki doğrulama girişimi reddedildi.'");
	ElsIf StatusCode = 402 Then // Payment Required
		Details = NStr("vi = 'Cần thanh toán.';
						|ru = 'Требуется оплата.';
						|en = 'Payment is required.'; fa = 'Payment is required.';
						|it = 'Pagamento è richiesto.';
						|pl = 'Wymagana płatność.';
						|tr = 'Ödeme gerekli.'");
	ElsIf StatusCode = 403 Then // Forbidden
		Details = NStr("vi = 'Không truy cập đến tài nguyên được yêu cầu.';
						|ru = 'К запрашиваемому ресурсу нет доступа.';
						|en = 'No access to the requested resource.'; fa = 'No access to the requested resource.';
						|it = 'Non c''è accesso alla risorsa richiesta.';
						|pl = 'Nie ma dostępu do żądanego zasobu.';
						|tr = 'Sorgulanan kaynak erişilemez.'");
	ElsIf StatusCode = 404 Then // Not Found
		Details = NStr("vi = 'Tài nguyên được yêu cầu không tồn tại trên máy chủ.';
						|ru = 'Запрашиваемый ресурс не существует на сервере.';
						|en = 'The requested resource does not exist on the server.'; fa = 'The requested resource does not exist on the server.';
						|it = 'La risorsa richiesta non esiste nel server.';
						|pl = 'Zapytywany zasób nie istnieje na serwerze.';
						|tr = 'Sorgulanan kaynak sunucuda mevcut değil.'");
	ElsIf StatusCode = 405 Then // Method Not Allowed
		Details = NStr("vi = 'Máy chủ không hỗ trợ phương thức truy vấn.';
						|ru = 'Метод запроса не поддерживается сервером.';
						|en = 'The request method is not supported by the server.'; fa = 'The request method is not supported by the server.';
						|it = 'Il metodo di richiesta non è supportato dal server.';
						|pl = 'Metoda żądania nie jest obsługiwana przez serwer.';
						|tr = 'Sorgu yöntemi sunucu tarafından desteklenmez.'");
	ElsIf StatusCode = 406 Then // Not Acceptable
		Details = NStr("vi = 'Máy chủ không hỗ trợ định dạng dữ liệu đã yêu cầu.';
						|ru = 'Запрошенный формат данных не поддерживается сервером.';
						|en = 'The server does not support the requested data format.'; fa = 'The server does not support the requested data format.';
						|it = 'Il formato dati richiesto non è supportato dal server.';
						|pl = 'Żądany format danych nie jest obsługiwany przez serwer.';
						|tr = 'Sorgulanan veri formatı sunucu tarafından desteklenmez.'");
	ElsIf StatusCode = 407 Then // Proxy Authentication Required
		Details = NStr("vi = 'Lỗi đăng nhập trên proxy-server';
						|ru = 'Ошибка аутентификации на прокси-сервере';
						|en = 'Proxy server authentication error.'; fa = 'Proxy server authentication error.';
						|it = 'Errore di autenticazione sul server proxy';
						|pl = 'Błąd uwierzytelniania na serwerze proxy';
						|tr = 'Proxy sunucu doğrulama hatası'");
	ElsIf StatusCode = 408 Then // Request Timeout
		Details = NStr("vi = 'Đã quá thời gian máy chủ đợi phản hồi từ client.';
						|ru = 'Время ожидания сервером передачи от клиента истекло.';
						|en = 'Request timeout.'; fa = 'Request timeout.';
						|it = 'Tempo di attesa del trasferimento del server dal client scaduto.';
						|pl = 'Limit czasu transferu serwera z klienta wygasł.';
						|tr = 'İstemciden aktarım sunucusu zaman aşımına uğradı.'");
	ElsIf StatusCode = 409 Then // Conflict
		Details = NStr("vi = 'Không thể thực hiện yêu cầu do mâu thuẫn với tài nguyên.';
						|ru = 'Запрос не может быть выполнен из-за конфликтного обращения к ресурсу.';
						|en = 'Cannot execute the request due to an access conflict.'; fa = 'Cannot execute the request due to an access conflict.';
						|it = 'La richiesta non può essere eseguita a causa di una chiamata in conflitto con la risorsa.';
						|pl = 'Żądanie nie mogło zostać wykonane z powodu sprzecznego wywołania zasobu.';
						|tr = 'Sorgu, kaynak çakışması nedeniyle gerçekleştirilemez.'");
	ElsIf StatusCode = 410 Then // Gone
		Details = NStr("vi = 'Tài nguyên trên máy chủ đã được di chuyển.';
						|ru = 'Ресурс на сервере был перемещен.';
						|en = 'The resource is no longer available on the server.'; fa = 'The resource is no longer available on the server.';
						|it = 'La risorsa sul server è stata spostata.';
						|pl = 'Zasób na serwerze został przeniesiony.';
						|tr = 'Sunucudaki kaynak taşındı.'");
	ElsIf StatusCode = 411 Then // Length Required
		Details = NStr("vi = 'Máy chủ cần chỉ ra ""Content-length."" trong tiêu đề truy vấn.';
						|ru = 'Сервер требует указание ""Content-length."" в заголовке запроса.';
						|en = 'The ""Content-length"" request header is not specified.'; fa = 'The ""Content-length"" request header is not specified.';
						|it = 'Il server richiede l''indicazione ""Content-length."" nell''intestazione della richiesta.';
						|pl = 'Serwer wymaga wskazania ""Content-length."" w nagłówku żądania.';
						|tr = 'Sunucu, sorgu başlığında ""İçerik uzunluğu"" belirtilmesini gerektirir.'");
	ElsIf StatusCode = 412 Then // Precondition Failed
		Details = NStr("vi = 'Truy vấn không áp dụng với tài nguyên';
						|ru = 'Запрос не применим к ресурсу';
						|en = 'The request is not applicable to the resource.'; fa = 'The request is not applicable to the resource.';
						|it = 'La richiesta non si applica alla risorsa';
						|pl = 'Żądanie nie dotyczy zasobu';
						|tr = 'Sorgu kaynağa uygulanmaz'");
	ElsIf StatusCode = 413 Then // Request Entity Too Large
		Details = NStr("vi = 'Máy chủ từ chối xử lý, dung lượng dữ liệu được chuyển quá lớn.';
						|ru = 'Сервер отказывается обработать, слишком большой объем передаваемых данных.';
						|en = 'The server cannot process the request because the data volume is too large.'; fa = 'The server cannot process the request because the data volume is too large.';
						|it = 'Il server si rifiuta di eseguire elaborazione, il volume dati da trasferire è troppo grande.';
						|pl = 'Serwer odmawia przetwarzania zbyt dużej ilości danych.';
						|tr = 'Sunucu işlemeyi reddediyor, aktarılan verilerin hacmi fazladır.'");
	ElsIf StatusCode = 414 Then // Request-URL Too Long
		Details = NStr("vi = 'Máy chủ từ chối xử lý, URL quá dài.';
						|ru = 'Сервер отказывается обработать, слишком длинный URL.';
						|en = 'The cannot process the request because the URL is too long.'; fa = 'The cannot process the request because the URL is too long.';
						|it = 'Il server si rifiuta di eseguire elaborazione, URL è troppo lungo.';
						|pl = 'Serwer odmawia przetworzenia, adres URL jest za długi.';
						|tr = 'Sunucu işlemeyi reddediyor, URL aşırı uzun.'");
	ElsIf StatusCode = 415 Then // Unsupported Media-Type
		Details = NStr("vi = 'Máy chủ nhận thấy, rằng một phần truy vấn được thực hiện với định dạng không được hỗ trợ';
						|ru = 'Сервер заметил, что часть запроса была сделана в неподдерживаемом формат';
						|en = 'A part of the request has unsupported format.'; fa = 'A part of the request has unsupported format.';
						|it = 'Il server ha notato che una parte della richiesta è stata eseguita in un formato non supportato';
						|pl = 'Serwer zauważył, że część żądania została wykonana w nieobsługiwanym formacie';
						|tr = 'Sunucu, sorgunun bir kısmının desteklenmeyen bir biçimde yapıldığını fark etti'");
	ElsIf StatusCode = 416 Then // Requested Range Not Satisfiable
		Details = NStr("vi = 'Không thể cung cấp một phần tài nguyên được yêu cầu';
						|ru = 'Часть запрашиваемого ресурса не может быть предоставлена';
						|en = 'A part of the requested resource cannot be provided.'; fa = 'A part of the requested resource cannot be provided.';
						|it = 'Parte della risorsa richiesta non può essere fornita';
						|pl = 'Nie można dostarczyć części żądanego zasobu';
						|tr = 'İstenen kaynağın bir kısmı sağlanamaz'");
	ElsIf StatusCode = 417 Then // Expectation Failed
		Details = NStr("vi = 'Máy chủ không thể đưa ra phản hồi đến truy vấn đã chỉ ra.';
						|ru = 'Сервер не может предоставить ответ на указанный запрос.';
						|en = 'The server cannot provide a response to the specified request.'; fa = 'The server cannot provide a response to the specified request.';
						|it = 'Il server non può fornire una risposta alla richiesta specificata.';
						|pl = 'Serwer nie może dostarczyć odpowiedzi na określone żądanie.';
						|tr = 'Sunucu, belirtilen sorgu yanıtını sağlayamaz.'");
	ElsIf StatusCode = 429 Then // Too Many Requests
		Details = NStr("vi = 'Quá nhiều truy vấn trong thời gian ngắn.';
						|ru = 'Слишком много запросов за короткое время.';
						|en = 'Too many requests in a short amount of time.'; fa = 'Too many requests in a short amount of time.';
						|it = 'Troppe richieste in breve tempo.';
						|pl = 'Zbyt wiele próśb w krótkim czasie.';
						|tr = 'Kısa sürede çok fazla sorgu.'");
	ElsIf StatusCode = 500 Then // Internal Server Error
		Details = NStr("vi = 'Lỗi nội bộ của Internet-server.';
						|ru = 'Внутренняя ошибка интернет-сервера.';
						|en = 'Internal online server error.'; fa = 'Internal online server error.';
						|it = 'Внутренняя ошибка интернет-сервера.';
						|pl = 'Internal online server error.';
						|tr = 'İnternet sunucusunun dahili hatası.'");
	ElsIf StatusCode = 501 Then // Not Implemented
		Details = NStr("vi = 'Máy chủ không hỗ trợ phương thức truy vấn.';
						|ru = 'Сервер не поддерживает метод запроса.';
						|en = 'The server does not support the request method.'; fa = 'The server does not support the request method.';
						|it = 'Il server non supporta il metodo di richiesta.';
						|pl = 'Serwer nie obsługuje metody żądania.';
						|tr = 'Sunucu sorgu yöntemini desteklemiyor.'");
	ElsIf StatusCode = 502 Then // Bad Gateway
		Details = NStr("vi = 'Máy chủ, hoạt động như một cổng hoặc proxy-server,
		                         |đã nhận được thông báo phản hồi không hợp lệ từ máy chủ cấp cao.';
		                         |ru = 'Сервер, выступая в роли шлюза или прокси-сервера, 
		                         |получил недействительное ответное сообщение от вышестоящего сервера.';
		                         |en = 'The server received an invalid response from the upstream server
		                         |while acting as a gateway or proxy server.'; fa = 'The server received an invalid response from the upstream server
		                         |while acting as a gateway or proxy server.';
		                         |it = 'Il server, che funge da gateway o server proxy, 
		                         |ha ricevuto un messaggio di risposta non valido dal server upstream.';
		                         |pl = 'Serwer, działający jako brama lub serwer proxy, 
		                         |odebrał komunikat o nieprawidłowej odpowiedzi z serwera nadrzędnego.';
		                         |tr = 'Ağ geçidi veya proxy rolü konuşan sunucu, 
		                         |üst düzey bir sunucudan geçersiz bir yanıt iletisi aldı.'");
	ElsIf StatusCode = 503 Then // Server Unavailable
		Details = NStr("vi = 'Tạm thời, server không khả dụng.';
						|ru = 'Сервер временно недоступен.';
						|en = 'Server is temporarily unavailable.'; fa = 'Server is temporarily unavailable.';
						|it = 'Сервер временно недоступен.';
						|pl = 'Server is temporarily unavailable.';
						|tr = 'Sunucu geçici olarak kullanılamıyor.'");
	ElsIf StatusCode = 504 Then // Gateway Timeout
		Details = NStr("vi = 'Máy chủ hoạt động như một cổng hoặc proxy-server 
		                         |đã không đợi phản hồi từ máy chủ cấp cao để hoàn thành truy vấn hiện tại.';
		                         |ru = 'Сервер в роли шлюза или прокси-сервера 
		                         |не дождался ответа от вышестоящего сервера для завершения текущего запроса.';
		                         |en = 'The server did not receive a timely response from the upstream server
		                         |while acting as a gateway or proxy server.'; fa = 'The server did not receive a timely response from the upstream server
		                         |while acting as a gateway or proxy server.';
		                         |it = 'Il server gateway o server proxy 
		                         |non ha atteso una risposta dal server upstream per completare la richiesta corrente.';
		                         |pl = 'Serwer bramki lub serwer proxy 
		                         |nie czekał na odpowiedź z serwera nadrzędnego, aby ukończyć bieżące żądanie.';
		                         |tr = 'Ağ geçidi veya proxy rolündeki sunucu, 
		                         |geçerli sorguyu tamamlamak için bir üst sunucudan yanıt beklemedi.'");
	ElsIf StatusCode = 505 Then // HTTP Version Not Supported
		Details = NStr("vi = 'Máy chủ không hỗ trợ phiên bản đã chỉ ra trong truy vấn của giao thức HTTP';
						|ru = 'Сервер не поддерживает указанную в запросе версию протокола HTTP';
						|en = 'The server does not support HTTP version specified in the request.'; fa = 'The server does not support HTTP version specified in the request.';
						|it = 'Il server non supporta la versione HTTP specificata nella richiesta';
						|pl = 'Serwer nie obsługuje wersji protokołu HTTP określonej w żądaniu.';
						|tr = 'Sunucu HTTP protokolünün sorguda belirtilen sürümünü desteklemiyor'");
	ElsIf StatusCode = 506 Then // Variant Also Negotiates
		Details = NStr("vi = 'Đã tùy chỉnh sai máy chủ và không thể xử lý truy vấn.';
						|ru = 'Сервер настроен некорректно, и не способен обработать запрос.';
						|en = 'The server cannot process a request because it is configured incorrectly.'; fa = 'The server cannot process a request because it is configured incorrectly.';
						|it = 'Il server è configurato in modo errato e non può elaborare la richiesta.';
						|pl = 'Serwer jest skonfigurowany niepoprawnie i nie może przetworzyć żądania.';
						|tr = 'Sunucu düzgün yapılandırılmamış ve isteği işleyemiyor.'");
	ElsIf StatusCode = 507 Then // Insufficient Storage
		Details = NStr("vi = 'Trên máy chủ không đủ chỗ để thực hiện truy vấn.';
						|ru = 'На сервере недостаточно места для выполнения запроса.';
						|en = 'Not enough space on the server to run the request.'; fa = 'Not enough space on the server to run the request.';
						|it = 'Non c''è abbastanza spazio sul server per espletare la richiesta.';
						|pl = 'Na serwerze brakuje miejsca, aby spełnić żądanie.';
						|tr = 'Sunucu isteği gerçekleştirmek için yeterli alan yok.'");
	ElsIf StatusCode = 509 Then // Bandwidth Limit Exceeded
		Details = NStr("vi = 'Máy chủ đã vượt quá giới hạn phân bổ về mức tiêu thụ lưu lượng.';
						|ru = 'Сервер превысил отведенное ограничение на потребление трафика.';
						|en = 'The server exceeded the bandwidth limit.'; fa = 'The server exceeded the bandwidth limit.';
						|it = 'Il server ha superato il limite assegnato sul consumo di traffico.';
						|pl = 'Serwer przekroczył przydzielony limit na zużycie ruchu.';
						|tr = 'Sunucu, ayrılan trafik tüketim kısıtlamasını aştı.'");
	ElsIf StatusCode = 510 Then // Not Extended
		Details = NStr("vi = 'Máy chủ cần nhiều thông tin hơn về truy vấn hoàn tất.';
						|ru = 'Сервер требует больше информации о совершаемом запросе.';
						|en = 'The server requires additional request details.'; fa = 'The server requires additional request details.';
						|it = 'Il server richiede ulteriori informazioni sulla richiesta effettuata.';
						|pl = 'Serwer wymaga więcej informacji o żądaniu.';
						|tr = 'Sunucu, işlenen sorgu hakkında daha fazla bilgi gerektirir.'");
	ElsIf StatusCode = 511 Then // Network Authentication Required
		Details = NStr("vi = 'Cần đăng nhập trên máy chủ.';
						|ru = 'Требуется авторизация на сервере.';
						|en = 'Authorization on the server is required.'; fa = 'Authorization on the server is required.';
						|it = 'Autorizzazione richiesta sul server.';
						|pl = 'Wymagana autoryzacja na serwerze.';
						|tr = 'Sunucuda yetkilendirme gereklidir.'");
	Else 
		Details = NStr("vi = '<Mã trạng thái không xác định>.';
						|ru = '<Неизвестный код состояния>.';
						|en = '<Unknown status code>.'; fa = '<Unknown status code>.';
						|it = '<Codice di stato sconosciuto>.';
						|pl = '<Nieznany kod statusu>.';
						|tr = '<Bilinmeyen durum kodu>.'");
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '[%1] %2';
			|ru = '[%1] %2';
			|en = '[%1] %2'; fa = '[%1] %2';
			|it = '[%1] %2';
			|pl = '[%1] %2';
			|tr = '[%1] %2'"), 
		StatusCode, 
		Details);
	
EndFunction

Function RedirectionPresentations(Redirections)
	
	If Redirections.Count() = 0 Then 
		Return "";
	EndIf;

	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chuyển hướng được thực hiện (%1):
					|%2';
					|ru = 'Выполненные перенаправления (%1):
					|%2';
					|en = 'Redirected (%1):
					|%2'; fa = 'Redirected (%1):
					|%2';
					|it = 'Выполненные перенаправления (%1):
					|%2';
					|pl = 'Redirected (%1):
					|%2';
					|tr = 'Tamamlanan yönlendirmeler (%1):
					|%2'"),
		Redirections.Count(),
		StrConcat(Redirections, Chars.LF));

EndFunction

Procedure AddServerResponseBody(PathToFile, ErrorText)
	
	ServerResponseBody = TextFromHTMLFromFile(PathToFile);
	
	If Not IsBlankString(ServerResponseBody) Then 
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1
			           |
			           |Thông báo từ server internet:
			           |%2';
			           |ru = '%1
			           |
			           |Сообщение от интернет-сервера:
			           |%2';
			           |en = '%1
			           |
			           |Message from web server:
			           |%2'; fa = '%1
			           |
			           |Message from web server:
			           |%2';
			           |it = '%1
			           |
			           |Сообщение от интернет-сервера:
			           |%2';
			           |pl = '%1
			           |
			           |Message from web server:
			           |%2';
			           |tr = '%1
			           |
			           |İnternet sunucudan gelen mesaj:
			           |%2'"),
			ErrorText,
			ServerResponseBody);
	EndIf;
	
EndProcedure

Function TextFromHTMLFromFile(PathToFile)
	
	ResponseFile = New TextReader(PathToFile, TextEncoding.UTF8);
	SourceText = ResponseFile.Read(1024 * 15);
	ErrorText = StringFunctionsClientServer.ExtractTextFromHTML(SourceText);
	ResponseFile.Close();
	
	Return ErrorText;
	
EndFunction

Procedure AddHTTPHeaders(Object, ErrorText)
	
	If TypeOf(Object) = Type("HTTPRequest") Then 
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1
			           |
			           |truy vấn HTTP:
			           |Địa chỉ nguồn: %2
			           |Tiêu đề: %3';
			           |ru = '%1
			           |
			           |HTTP запрос:
			           |Адрес ресурса: %2
			           |Заголовки: %3';
			           |en = '%1
			           |
			           |HTTP request:
			           |Resource address: %2
			           |Headers: %3'; fa = '%1
			           |
			           |HTTP request:
			           |Resource address: %2
			           |Headers: %3';
			           |it = '%1
			           |
			           |Richiesta HTTP:
			           |Indirizzo della risorsa: %2
			           |Intestazioni: %3';
			           |pl = '%1
			           |
			           |Żądanie HTTP:
			           |Adres zasobu: %2
			           |Nagłówki: %3';
			           |tr = '%1
			           |
			           |HTTP sorgu:
			           |Kaynağın adresi: %2
			           |Başlıklar: %3'"),
			ErrorText,
			Object.ResourceAddress,
			HTTPHeadersPresentation(Object.Headers));
	ElsIf TypeOf(Object) = Type("HTTPResponse") Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1
			           |
			           |phản hồi HTTP:
			           |Mã phản hồi: %2
			           |Tiêu đề: %3';
			           |ru = '%1
			           |
			           |HTTP ответ:
			           |Код ответа: %2
			           |Заголовки: %3';
			           |en = '%1
			           |
			           |HTTP response:
			           |Response code: %2
			           |Headers: %3'; fa = '%1
			           |
			           |HTTP response:
			           |Response code: %2
			           |Headers: %3';
			           |it = '%1
			           |
			           |Risposta HTTP:
			           |Codice della risposta: %2
			           |Intestazioni: %3';
			           |pl = '%1
			           |
			           |Żądanie HTTP:
			           |Kod odpowiedzi: %2
			           |Nagłówki: %3';
			           |tr = '%1
			           |
			           |HTTP cevap:
			           |Cevap kodu: %2
			           |Başlıklar: %3'"),
			ErrorText,
			Object.StatusCode,
			HTTPHeadersPresentation(Object.Headers));
	EndIf;
	
EndProcedure

Function HTTPHeadersPresentation(Headers)
	
	HeadersPresentation = "";
	
	For Each Title In Headers Do 
		HeadersPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1
			           |%2: %3';
			           |ru = '%1
			           |%2: %3';
			           |en = '%1
			           |%2: %3'; fa = '%1
			           |%2: %3';
			           |it = '%1
			           |%2: %3';
			           |pl = '%1
			           |%2: %3';
			           |tr = '%1
			           |%2: %3'"), 
			HeadersPresentation,
			Title.Key, Title.Value);
	EndDo;
		
	Return HeadersPresentation;
	
EndFunction

Function InternetProxyPresentation(Proxy, Protocol = Undefined)
	
	Log = New Array;
	If ValueIsFilled(Protocol) Then
		Server = Proxy.Server(Protocol);
		Port = Proxy.Port(Protocol);
		
		If ValueIsFilled(Server) Then
			If Not ValueIsFilled(Port) Then
				Port = DefaultPort(Protocol);
			EndIf;
		Else
			Server = Proxy.Server();
			Port = Proxy.Port();
		EndIf;
		
		Log.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1: %2:%3';
				|ru = '%1: %2:%3';
				|en = '%1: %2:%3'; fa = '%1: %2:%3';
				|it = '%1: %2:%3';
				|pl = '%1: %2:%3';
				|tr = '%1: %2:%3'"), Upper(Protocol), Server, Format(Port, "NG=")));
	Else
		Log.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Địa chỉ:  %1:%2
			           |HTTP:   %3:%4
			           |Secure: %5:%6
			           |FTP:    %7:%8';
			           |ru = 'Адрес:  %1:%2
			           |HTTP:   %3:%4
			           |Secure: %5:%6
			           |FTP:    %7:%8';
			           |en = 'Address: %1:%2
			           |HTTP:    %3:%4
			           |HTTPS:   %5:%6
			           |FTP:     %7:%8'; fa = 'Address: %1:%2
			           |HTTP:    %3:%4
			           |HTTPS:   %5:%6
			           |FTP:     %7:%8';
			           |it = 'Indirizzo:  %1:%2
			           |HTTP:   %3:%4
			           |Secure: %5:%6
			           |FTP:    %7:%8';
			           |pl = 'Adres:  %1:%2
			           |HTTP:   %3:%4
			           |Secure: %5:%6
			           |FTP:    %7:%8';
			           |tr = 'Adres:  %1:%2
			           |HTTP:   %3:%4
			           |Secure: %5:%6
			           |FTP:    %7:%8'"),
			Proxy.Server(),        Format(Proxy.Port(),        "NG="),
			Proxy.Server("http"),  Format(Proxy.Port("http"),  "NG="),
			Proxy.Server("https"), Format(Proxy.Port("https"), "NG="),
			Proxy.Server("ftp"),   Format(Proxy.Port("ftp"),   "NG=")));
	EndIf;
		
	If Proxy.UseOSAuthentication("") Then 
		Log.Add(NStr("vi = 'Sử dụng đăng nhập hệ điều hành';
					|ru = 'Используется аутентификация операционной системы';
					|en = 'OS authentication.'; fa = 'OS authentication.';
					|it = 'Viene applicata autenticazione del sistema operativo';
					|pl = 'Używanie uwierzytelniania systemu operacyjnego';
					|tr = 'İşletim sistemi kimlik doğrulaması kullanılır'"));
	Else 
		User = Proxy.User("");
		Password = Proxy.Password("");
		PasswordState = ?(IsBlankString(Password), NStr("vi = '<chưa chỉ ra>';
														|ru = '<не указан>';
														|en = '<not specified>'; fa = '<مشخص نشده>';
														|it = '<non specificato>';
														|pl = '<nie określono>';
														|tr = '<belirtilmedi>'"), NStr("vi = '********';
																						|ru = '********';
																						|en = '********'; fa = '********';
																						|it = '********';
																						|pl = '********';
																						|tr = '********'"));
		
		Log.Add(NStr("vi = 'Sử dụng đăng nhập theo tên người sử dụng và mật khẩu';
					|ru = 'Используется аутентификация по имени пользователя и паролю';
					|en = 'Authentication with username and password.'; fa = 'Authentication with username and password.';
					|it = 'Viene applicata autenticazione per username e password';
					|pl = 'Wykorzystywane jest uwierzytelnianie według nazwy użytkownika i hasła';
					|tr = 'Kullanıcı adı ve şifre kimlik doğrulaması kullanılır'"));
		Log.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Người sử dụng: %1
			           |Mật khẩu: %2';
			           |ru = 'Пользователь: %1
			           |Пароль: %2';
			           |en = 'User: %1
			           |Password: %2'; fa = 'User: %1
			           |Password: %2';
			           |it = 'Utente: %1
			           |Password: %2';
			           |pl = 'Użytkownik: %1
			           |Hasło: %2';
			           |tr = 'Kullanıcı: %1
			           |Şifre: %2'"),
			User,
			PasswordState));
	EndIf;
	
	If Proxy.BypassProxyOnLocal Then 
		Log.Add(NStr("vi = 'Không sử dụng Proxy đối với địa chỉ cục bộ';
					|ru = 'Не использовать прокси для локальных адресов';
					|en = 'Bypass proxy for local addresses.'; fa = 'عبور از پروکسی برای آدرس‌های محلی.';
					|it = 'Non utilizzare proxy per indirizzi locali';
					|pl = 'Nie używaj proxy dla adresów lokalnych';
					|tr = 'Yerel URL''ler için baypas proxy''si'"));
	EndIf;
	
	If Proxy.BypassProxyOnAddresses.Count() > 0 Then 
		Log.Add(NStr("vi = 'Không sử dụng đối với địa chỉ tiếp theo:';
					|ru = 'Не использовать для следующих адресов:';
					|en = 'Bypass proxy for the following addresses:'; fa = 'Bypass proxy for the following addresses:';
					|it = 'Non applicare per i seguenti indirizzi:';
					|pl = 'Nie używaj dla następujących adresów:';
					|tr = 'Aşağıdaki adresler için kullanma:'"));
		For Each AddressToExclude In Proxy.BypassProxyOnAddresses Do
			Log.Add(AddressToExclude);
		EndDo;
	EndIf;
	
	Return StrConcat(Log, Chars.LF);
	
EndFunction

// Returns proxy according to settings ProxyServerSetting for the specified Protocol protocol.
//
// Parameters:
//   ProxyServerSetting - Map of KeyAndValue:
//    * Key - String - see the list of available keys below.
//    * Value - Arbitrary
//    UseProxy - Boolean - indicates whether to use the proxy server.
//    BypassProxyOnLocal - indicates whether to use the proxy server for local addresses.
//    BypassProxyOnAddresses - Array from String
//    UseSystemSettings - Boolean - indicates whether to use system settings of the proxy server.
//    Server - String - a proxy server address.
//    Port - String - a proxy server port.
//    User - String - a username to authorize on the proxy server.
//    Password - String - a user password.
//    UseOSAuthentication - Boolean - indicates that authentication by operating system is used.
//   URLOrProtocol - String - resource address or protocol for which proxy server parameters are set, for example
//                             "https://1ci.com", "http", "https", "ftp", "ftps".
//
// Returns:
//   InternetProxy
//
Function NewInternetProxy(ProxyServerSetting, URLOrProtocol) Export
	
	If ProxyServerSetting = Undefined Then
		// Proxy server system settings.
		Return Undefined;
	EndIf;
	
	UseProxy = ProxyServerSetting.Get("UseProxy");
	If Not UseProxy Then
		// Do not use a proxy server.
		Return New InternetProxy(False);
	EndIf;
	
	UseSystemSettings = ProxyServerSetting.Get("UseSystemSettings");
	If UseSystemSettings Then
		// Proxy server system settings.
		Return New InternetProxy(True);
	EndIf;
	
	UseOSAuthentication = ProxyServerSetting.Get("UseOSAuthentication");
	UseOSAuthentication = ?(UseOSAuthentication = True, True, False);

	AdditionalSettings = ProxyServerSetting.Get("AdditionalProxySettings");
	If TypeOf(AdditionalSettings) <> Type("Map") Then
		AdditionalSettings = New Map;
	EndIf;
	
	// Manually configured proxy settings.
	Proxy = New InternetProxy;
	
	Logs = StrSplit("http,https,ftp,ftps", ",", False);
	For Each Protocol In Logs Do
		ServerAddress = ProxyServerSetting["Server"];
		Port = ProxyServerSetting["Port"];
		
		ProxyByProtocol = AdditionalSettings[Protocol];
		If TypeOf(ProxyByProtocol) = Type("Structure") Then
			ServerAddress = ProxyByProtocol.Address;
			Port = ProxyByProtocol.Port;
		EndIf;
		
		If Not ValueIsFilled(Port) Then
			Port = Undefined;
		EndIf;
		
		Proxy.Set(Protocol, ServerAddress, Port, 
			ProxyServerSetting["User"], ProxyServerSetting["Password"], UseOSAuthentication);
	EndDo;
	
	Proxy.BypassProxyOnLocal = ProxyServerSetting["BypassProxyOnLocal"];
	
	ExceptionsAddresses = ProxyServerSetting.Get("BypassProxyOnAddresses");
	If TypeOf(ExceptionsAddresses) = Type("Array") Then
		For Each ExceptionAddress In ExceptionsAddresses Do
			Proxy.BypassProxyOnAddresses.Add(ExceptionAddress);
		EndDo;
	EndIf;
	
	Return Proxy;
	
EndFunction

// Writes the error to the event log as "Network download".
//
// Parameters:
//   ErrorMessage - String - error message.
// 
Procedure WriteErrorToEventLog(Val ErrorMessage)
	
	WriteLogEvent(EventLogEvent(), EventLogLevel.Error,,,
		ErrorMessage);
	
EndProcedure

Function EventLogEvent()
	
	Return NStr("vi = 'Nhận tệp từ Internet';
				|ru = 'Получение файлов из Интернета';
				|en = 'Network download'; fa = 'دانلود از شبکه';
				|it = 'Recupero di file da Internet';
				|pl = 'Pobieranie plików z internetu';
				|tr = 'İnternetten dosya al'", Common.DefaultLanguageCode());
	
EndFunction

#EndIf

#EndRegion

#Region ConnectionDiagnostics

// Service information that displays current settings and proxy states to perform diagnostics.
//
// Parameters:
//  Protocol - String - a protocol for which you need to get the proxy settings.
//
// Returns:
//  Structure:
//     * ProxyConnection - Boolean - flag that indicates that proxy connection should be used.
//     * Presentation - String - presentation of the current set up proxy.
//
Function ProxySettingsState(Val Protocol = Undefined) Export
	
	Protocol = TheProtocolForTheProxy(Protocol);
	Proxy = GetFilesFromInternet.GetProxy(Protocol);
	ProxySettings = GetFilesFromInternet.ProxySettingsAtServer();
	
	Log = New Array;
	
	If ProxySettings = Undefined Then 
		Log.Add(NStr("vi = 'Chưa chỉ ra tham số proxy-server trong CSTT (sử dụng tùy chỉnh Proxy hệ thống).';
					|ru = 'Параметры прокси-сервера в ИБ не указаны (используются системные настройки прокси).';
					|en = 'The proxy server parameters are not specified in the infobase. System proxy server are used instead.'; fa = 'The proxy server parameters are not specified in the infobase. System proxy server are used instead.';
					|it = 'I parametri del server proxy non sono specificati nel database (vengono utilizzate le impostazioni proxy del sistema).';
					|pl = 'Ustawienia serwera proxy w IB nie są określone (używane są ustawienia proxy systemu).';
					|tr = 'Proxy sunucunun ayarları IB''de belirtilmemiştir (sistem proxy ayarları kullanılır).'"));
	ElsIf Not ProxySettings.Get("UseProxy") Then
		Log.Add(NStr("vi = 'Tham số proxy-server trong CSTT: Không sử dụng proxy-server.';
					|ru = 'Параметры прокси-сервера в ИБ: Не использовать прокси-сервер.';
					|en = 'Proxy server parameters in the infobase: Do not use proxy server.'; fa = 'Proxy server parameters in the infobase: Do not use proxy server.';
					|it = 'I parametri del server proxy nel database: Non utilizzare il server proxy.';
					|pl = 'Ustawienia serwera proxy w IB: Nie używaj serwera proxy.';
					|tr = 'Proxy sunucunun IB''deki ayarları: Proxy sunucusu kullanılamaz.'"));
	ElsIf ProxySettings.Get("UseSystemSettings") Then
		Log.Add(NStr("vi = 'Tham số proxy-server trong CSTT: Sử dụng tùy chỉnh hệ thống proxy-server.';
					|ru = 'Параметры прокси-сервера в ИБ: Использовать системные настройки прокси-сервера.';
					|en = 'Proxy server parameters in the infobase: Use system proxy server settings.'; fa = 'Proxy server parameters in the infobase: Use system proxy server settings.';
					|it = 'I parametri del server proxy nel database: Utilizzare le impostazioni del server proxy del sistema.';
					|pl = 'Ustawienia serwera proxy w IB: Użyj ustawień systemu serwera proxy.';
					|tr = 'Proxy sunucunun IB''deki ayarları: Proxy sunucunun sistem ayarlarını kullan.'"));
	Else
		Log.Add(NStr("vi = 'Tham số proxy-server trong CSTT: Sử dụng tùy chỉnh khác của proxy-server.';
					|ru = 'Параметры прокси-сервера в ИБ: Использовать другие настройки прокси-сервера.';
					|en = 'Proxy server parameters in the infobase: Use other proxy server settings.'; fa = 'Proxy server parameters in the infobase: Use other proxy server settings.';
					|it = 'I parametri del server proxy nel database: Utilizzare altre impostazioni del server proxy.';
					|pl = 'Ustawienia proxy w IB: Użyj innych ustawień serwera proxy.';
					|tr = 'Proxy sunucunun IB''deki ayarları: Proxy sunucunun sistem diğer ayarlarını kullan.'"));
	EndIf;
	
	If Proxy = Undefined Then 
		Proxy = New InternetProxy(True);
	EndIf;
	
	ProxyConnection = Not IsBlankString(Proxy.Server(Protocol)) Or Not IsBlankString(Proxy.Server());
	
	If ProxyConnection Then 
		Log.Add(NStr("vi = 'Đang thực hiện kết nối qua proxy-server:';
					|ru = 'Соединение выполняется через прокси-сервер:';
					|en = 'Connecting via proxy server:'; fa = 'Connecting via proxy server:';
					|it = 'La connessione viene effettuata tramite un server proxy:';
					|pl = 'Połączenie jest nawiązywane za pośrednictwem serwera proxy:';
					|tr = 'Bağlantı proxy sunucusu üzerinden yapılıyor:'"));
		Log.Add(InternetProxyPresentation(Proxy, Protocol));
	EndIf;
	
	Result = New Structure;
	Result.Insert("ProxyConnection", ProxyConnection);
	Result.Insert("Presentation", StrConcat(Log, Chars.LF));
	Result.Insert("SystemProxySettingsUsed", ProxySettings = Undefined Or ProxySettings["UseSystemSettings"] = True);
	
	Return Result;
	
EndFunction

Function DiagnosticsLocationPresentation() Export
	
	If Common.DataSeparationEnabled() Then
		Return NStr("vi = 'Kết nối được thực hiện trong máy chủ 1C:Enterprise trên Internet (mô hình dịch vụ).';
					|ru = 'Подключение проводится на сервере 1С:Предприятия в интернете (модель сервиса).';
					|en = 'Attempting connection on a remote 1C:Enterprise server (SaaS).'; fa = 'Attempting connection on a remote 1C:Enterprise server (SaaS).';
					|it = 'La connessione viene effettuata sul server 1C:Enterprise in internet (modello del servizio).';
					|pl = 'Podłączenie jest wykonywane na serwerze 1С:Предприятия в интернете (model serwisu).';
					|tr = 'Bağlantı, 1C:Enterprise''nin sunucusunda İnternet üzerinden yapılıyor.'");
	Else 
		If Common.FileInfobase() Then
			If Common.ClientConnectedOverWebServer() Then 
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Kết nối được tạo từ CSTT file-server trên web-server < %1>.';
						|ru = 'Подключение проводится из файловой информационной базы на веб-сервере <%1>.';
						|en = 'Attempting connection from a file infobase on web server <%1>.'; fa = 'Attempting connection from a file infobase on web server <%1>.';
						|it = 'La connessione viene effettuata dal database di file su server web <%1>.';
						|pl = 'Podłączenie jest wykonywane z plikowej bazy informacyjnej w serwisie internetowym <%1>.';
						|tr = 'Bağlantı, web sunucusundaki Infobase''dan yapılıyor <%1>.'"), ComputerName());
			Else 
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Kết nối được tạo từ tệp CSTT file-server trên máy tính < %1>.';
						|ru = 'Подключение проводится из файловой информационной базы на компьютере <%1>.';
						|en = 'Attempting connection from a file infobase on computer <%1>.'; fa = 'Attempting connection from a file infobase on computer <%1>.';
						|it = 'La connessione viene effettuata dal database di file sul computer <%1>.';
						|pl = 'Podłączenie jest wykonywane z plikowej bazy informacyjnej na komputerze <%1>.';
						|tr = 'Bağlantı, bilgisayardaki Infobase''den yapılıyor <%1>.'"), ComputerName());
			EndIf;
		Else
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Kết nối được thực hiện trên máy chủ 1C:Enterprise <%1>.';
					|ru = 'Подключение проводится на сервере 1С:Предприятие <%1>.';
					|en = 'Attempting connection on 1C:Enterprise server <%1>.'; fa = 'Attempting connection on 1C:Enterprise server <%1>.';
					|it = 'La connessione viene effettuata sul server 1C:Enterprise <%1>.';
					|pl = 'Podłączenie jest wykonywane na serwerze 1C:Enterprise <%1>.';
					|tr = 'Bağlantı, 1C:Enterprise sunucusunda <%1> yapılıyor.'"), ComputerName());
		EndIf;
	EndIf;
	
EndFunction

Function CheckServerAvailability(ServerAddress) Export
	
	Result = New Structure("Available, DiagnosticsLog", False, "");
	
	If Not Common.DomainNameCorrect(ServerAddress) Then
		Result.DiagnosticsLog = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai địa chỉ server: %1';
				|ru = 'Неверный адрес сервера: %1';
				|en = 'Incorrect server address: %1'; fa = 'Incorrect server address: %1';
				|it = 'Incorrect server address: %1';
				|pl = 'Incorrect server address: %1';
				|tr = 'Geçersiz sunucu adresi: %1'"), ServerAddress);
		Return Result;
	EndIf;
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	ApplicationStartupParameters.GetOutputStream = True;
	ApplicationStartupParameters.GetErrorStream = True;
	ApplicationStartupParameters.ExecutionEncoding = "OEM";
	
	If Common.IsWindowsServer() Then
		CommandTemplate = "ping %1 -n 4 -w 1000";
	Else
		CommandTemplate = "ping -c 4 -W 1 %1";
	EndIf;
	CommandString = StringFunctionsClientServer.SubstituteParametersToString(CommandTemplate, ServerAddress);
	
	Try
		RunResult = FileSystem.StartApplication(CommandString, ApplicationStartupParameters);
	Except
		Result.DiagnosticsLog = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kiểm tra tính khả dụng của nguồn Internet ""%1"" do nguyên nhân:
				|%2
				|
				|thông qua lệnh ""%3"".';
				|ru = 'Не удалось проверить доступность интернет-ресурса ""%1"" по причине:
				|%2
				|
				|с помощью команды ""%3"".';
				|en = 'Cannot check whether the ""%1"" Internet resource is available due to:
				|%2
				|
				|using the ""%3"" command.'; fa = 'Cannot check whether the ""%1"" Internet resource is available due to:
				|%2
				|
				|using the ""%3"" command.';
				|it = 'Impossibile verificare l''accessibilità della risorsa internet ""%1"" a causa di:
				|%2
				|
				|con il comando ""%3"".';
				|pl = 'Nie udało się sprawdzić dostępności zasobu internetowego ""%1"" z powodu:
				|%2
				|
				|za pomocą polecenia ""%3"".';
				|tr = '""%1"" İnternet kaynağın erişebilirliği şu sebeple kontrol edilemedi:
				|%2
				|
				| ""%3"" komutu ile.'"), 
				ServerAddress, ErrorProcessing.BriefErrorDescription(ErrorInfo()), CommandString);
		Return Result; 
	EndTry;	
	
	// Error handling differs between OS:
	// - Windows sends errors to the output stream.
	// - Debian and RHEL send errors to the error stream.
	AvailabilityLog = RunResult.OutputStream + RunResult.ErrorStream;
	
	If Common.IsWindowsServer() Then
		Available = StrFind(AvailabilityLog, "Destination host unreachable") = 0 // Do not localize.
			And (StrFind(AvailabilityLog, "(0% loss)") > 0 // Do not localize.
			Or StrFind(AvailabilityLog, "(25% loss)") > 0); // Do not localize.
	Else 
		Available = StrFind(AvailabilityLog, "Destination Host Unreachable") = 0 // Do not localize.
			And (StrFind(AvailabilityLog, "(0% packet loss)") > 0 // Do not localize.
			Or StrFind(AvailabilityLog, "(25% packet loss)") > 0); // Do not localize.
	EndIf;
	
	Log = New Array;
	If Available Then
		Log.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Máy chủ từ xa  %1 khả dụng:';
				|ru = 'Удаленный сервер %1 доступен:';
				|en = 'Remote server %1 is available:'; fa = 'Remote server %1 is available:';
				|it = 'Server remoto %1 disponibile:';
				|pl = 'Serwer zdalny%1 jest dostępny:';
				|tr = 'Uzak sunucu %1 kullanılamaz:'"), 
			ServerAddress));
	Else
		Log.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Server từ xa %1 không khả dụng:';
				|ru = 'Удаленный сервер %1 недоступен:';
				|en = 'Remote server %1 is unavailable:'; fa = 'Remote server %1 is unavailable:';
				|it = 'Удаленный сервер %1 недоступен:';
				|pl = 'Remote server %1 is unavailable:';
				|tr = 'Uzak sunucu %1 kullanılamaz:'"), 
			ServerAddress));
	EndIf;
	
	Log.Add("> " + CommandString);
	Log.Add(AvailabilityLog);
	
	Result.Available = Available;
	Result.DiagnosticsLog = StrConcat(Log, Chars.LF);
	Return Result; 
	
EndFunction

Function ServerRouteTraceLog(ServerAddress) Export
	
	If Not Common.DomainNameCorrect(ServerAddress) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể theo dõi lộ trình đến %1 server từ xa:
				|Địa chỉ server không hợp lệ.';
				|ru = 'Трассировка маршрута к удаленному серверу %1 не выполнена:
				|Неверный адрес сервера.';
				|en = 'Route tracing to the %1 remote server failed:
				|Incorrect server address.'; fa = 'Route tracing to the %1 remote server failed:
				|Incorrect server address.';
				|it = 'Route tracing to the %1 remote server failed:
				|Incorrect server address.';
				|pl = 'Route tracing to the %1 remote server failed:
				|Incorrect server address.';
				|tr = '%1 uzak sunucusuna rota izlemesi başarısız oldu:
				|Geçersiz sunucu adresi.'"), ServerAddress);
		Return ErrorText;
	EndIf;
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	ApplicationStartupParameters.GetOutputStream = True;
	ApplicationStartupParameters.GetErrorStream = True;
	ApplicationStartupParameters.ExecutionEncoding = "OEM";
	
	If Common.IsWindowsServer() Then
		CommandTemplate = "tracert -w 100 -h 15 %1";
	Else 
		// If traceroute is not installed, the output stream will have an error.
		// You can ignore that since the output is not parsable.
		// For the administrator, it will be clear what utility should be installed.
		CommandTemplate = "traceroute -w 100 -m 100 %1";
	EndIf;
	
	CommandString = StringFunctionsClientServer.SubstituteParametersToString(CommandTemplate, ServerAddress);
	
	Result = FileSystem.StartApplication(CommandString, ApplicationStartupParameters);
	
	Log = New Array;
	Log.Add(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Theo dõi lộ trình đến máy chủ %1 từ xa:';
			|ru = 'Трассировка маршрута к удаленному серверу %1:';
			|en = 'Tracing route to remote server %1:'; fa = 'Tracing route to remote server %1:';
			|it = 'Tracciamento del percorso al server remoto %1:';
			|pl = 'Trasowanie trasy do do usuniętego serwera %1:';
			|tr = '%1 Uzak sunucuya rota izleme:'"), ServerAddress));
	
	Log.Add("> " + CommandString);
	Log.Add(Result.OutputStream);
	Log.Add(Result.ErrorStream);
	
	Return StrConcat(Log, Chars.LF);
	
EndFunction

Function DefaultPort(Protocol)
	
	DefaultPorts = New Map;
	DefaultPorts.Insert("http", 80);
	DefaultPorts.Insert("https", 443);
	DefaultPorts.Insert("ftp", 21);
	DefaultPorts.Insert("ftps", 990);
	
	Return DefaultPorts[Lower(Protocol)];
	
EndFunction

Function TheProtocolForTheProxy(Val URLOrProtocol)
	
	AcceptableProtocols = New Map();
	AcceptableProtocols.Insert("HTTP",  True);
	AcceptableProtocols.Insert("HTTPS", True);
	AcceptableProtocols.Insert("FTP",   True);
	AcceptableProtocols.Insert("FTPS",  True);
	
	If StrFind(URLOrProtocol, "://") > 0 Then
		URLStructure1 = CommonClientServer.URIStructure(URLOrProtocol);
		Protocol = ?(IsBlankString(URLStructure1.Schema), "http", URLStructure1.Schema);
	Else
		Protocol = Lower(URLOrProtocol);
	EndIf;
	
	If AcceptableProtocols[Upper(Protocol)] = Undefined Then
		Protocol = "HTTP";
	EndIf;
	
	Return Protocol;
	
EndFunction

#EndRegion

#EndRegion
