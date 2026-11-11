///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Gets the file from the Internet via http(s) protocol or ftp protocol and saves it at the specified path on server.
//
// Parameters:
//   URL                - String - file URL in the following format: [Protocol://]<Server>/<Path to the file on the server>.
//   ReceivingParameters - See GetFilesFromInternetClientServer.FileGettingParameters
//   WriteError1   - Boolean - if True, write file download errors to the event log.
//
// Returns:
//   Structure:
//      * Status            - Boolean - a result of receiving a file.
//      * Path   - String   - path to the file on the server. This key is used only if Status is True.
//      * ErrorMessage - String - error message if Status is False.
//      * Headers         - Map - see details of the Headers parameter of the HTTPResponse object in Syntax Assistant.
//      * StatusCode      - Number - Added in case of an error.
//                                    See the "StatusCode" parameter of the "HTTPResponse" object in Syntax Assistant.
//
Function DownloadFileAtServer(Val URL, ReceivingParameters = Undefined, Val WriteError1 = True) Export
	
	SavingSetting = New Map;
	SavingSetting.Insert("StorageLocation", "Server");
	
	Return GetFilesFromInternetInternal.DownloadFile(URL,
		ReceivingParameters, SavingSetting, WriteError1);
	
EndFunction

// Gets a file from the Internet over HTTP(S) or FTP and saves it to a temporary storage.
// Note. After getting the file, clear the temporary storage
// using the DeleteFromTempStorage method. If you do not do it, the file will remain in
// the server memory until the session is over.
//
// Parameters:
//   URL                - String - file URL in the following format: [Protocol://]<Server>/<Path to the file on the server>.
//   ReceivingParameters - See GetFilesFromInternetClientServer.FileGettingParameters.
//   WriteError1   - Boolean - if True, write file download errors to the event log.
//
// Returns:
//   Structure:
//      * Status            - Boolean - a result of receiving a file.
//      * Path              - String   - an address of a temporary storage with binary file data.
//                            The key is used only if the status is True.
//      * ErrorMessage - String - error message if Status is False.
//      * Headers         - Map - see details of the Headers parameter of the HTTPResponse object in Syntax Assistant.
//      * StatusCode      - Number - Added in case of an error.
//                                    See the "StatusCode" parameter of the "HTTPResponse" object in Syntax Assistant.
//
Function DownloadFileToTempStorage(Val URL, ReceivingParameters = Undefined, Val WriteError1 = True) Export
	
	SavingSetting = New Map;
	SavingSetting.Insert("StorageLocation", "TemporaryStorage");
	
	Return GetFilesFromInternetInternal.DownloadFile(URL,
		ReceivingParameters, SavingSetting, WriteError1);
	
EndFunction

// Returns the current user's proxy server settings for Internet access from
// the client.
//
// Returns:
//    Map of KeyAndValue:
//      * Key - String
//      * Value - Arbitrary
//    Keys:
//      # UseProxy - Boolean - indicates whether to use the proxy server.
//      # BypassProxyOnLocal - Boolean - indicates whether to use the proxy server for local addresses.
//      # UseSystemSettings - Boolean - indicates whether to use system settings of the proxy server.
//      # Server - String - a proxy server address.
//      # Port - Number - a proxy server port.
//      # User - String - a username to authorize on the proxy server.
//      # Password - String - a user password.
//
Function ProxySettingsAtClient() Export
	
	UserName = Undefined;
	
	If Common.FileInfobase() Then
		
		// In the file mode, scheduled jobs run on the user's computer.
		// 
		
		SetPrivilegedMode(True);
		CurrentInfobaseSession1 = GetCurrentInfoBaseSession();
		BackgroundJob = CurrentInfobaseSession1.GetBackgroundJob();
		IsScheduledJobSession = BackgroundJob <> Undefined And BackgroundJob.ScheduledJob <> Undefined;
		
		If IsScheduledJobSession Then
			
			If Not ValueIsFilled(BackgroundJob.ScheduledJob.UserName) Then 
				
				// If a scheduled job is started on behalf of the default user, take the proxy settings
				// from the user settings saved on the computer where the session is running.
				// 
				
				Sessions = GetInfoBaseSessions(); // Array of InfoBaseSession
				For Each Session In Sessions Do 
					If Session.ComputerName = CurrentInfobaseSession1.ComputerName Then 
						UserName = Session.User.Name;
						Break;
					EndIf;
				EndDo;
			EndIf;
			
		EndIf;
		
		SetPrivilegedMode(False);
	EndIf;
	
	Return Common.CommonSettingsStorageLoad("ProxyServerSetting", "",,, UserName);
	
EndFunction

// Returns the 1C:Enterprise server's proxy settings.
//
// Returns:
//   Map of KeyAndValue:
//     * Key - String
//     * Value - Arbitrary
//    Keys:
//      # UseProxy - Boolean - indicates whether to use the proxy server.
//      # BypassProxyOnLocal - Boolean - indicates whether to use the proxy server for local addresses.
//      # UseSystemSettings - Boolean - indicates whether to use system settings of the proxy server.
//      # Server - String - a proxy server address.
//      # Port - Number - a proxy server port.
//      # User - String - a username to authorize on the proxy server.
//      # Password - String - a user password.
//
Function ProxySettingsAtServer() Export
	
	If Common.FileInfobase() Then
		Return ProxySettingsAtClient();
	Else
		SetPrivilegedMode(True);
		ProxySettingsAtServer = Constants.ProxyServerSetting.Get().Get();
		Return ?(TypeOf(ProxySettingsAtServer) = Type("Map"),
			ProxySettingsAtServer,
			Undefined);
	EndIf;
	
EndFunction

// Returns InternetProxy object for Internet access.
// The following protocols are acceptable for creating InternetProxy: http, https, ftp, and ftps.
//
// Parameters:
//    URLOrProtocol - String - URL in the following format: [Protocol://]<Server>/<Path to the file on the server>,
//                              or protocol identifier (http, ftp, …).
//
// Returns:
//    InternetProxy - describes proxy server parameters for various protocols.
//                     If the network protocol scheme cannot be recognized,
//                     the proxy will be created based on the HTTP protocol.
//
Function GetProxy(Val URLOrProtocol) Export
	
	Return GetFilesFromInternetInternal.NewInternetProxy(ProxySettingsAtServer(), URLOrProtocol);
	
EndFunction

// Runs the network resource diagnostics.
// In SaaS mode, returns only an error description.
//
// Parameters:
//  URL - String - URL resource address to be diagnosed.
//  WriteError1 - Boolean - indicates whether it is necessary to write errors to the event log.
//  IsPackageDeliveryCheckEnabled - Boolean - Include a PING command to the required URL resource in the diagnostics.
//  ErrorText - String - Original exception text.
//
// Returns:
//  Structure:
//    *  ErrorDescription    - String - brief error message.
//    *  DiagnosticsLog - String - a detailed log of diagnostics with technical details.
//
// Example:
//	Diagnostics of address classifier web service.
//	Result = GetFilesFromInternet.ConnectionDiagnostics("https://api.orgaddress.1c.com/orgaddress/v1?wsdl");
//	
//	ErrorDescription = Result.ErrorDescription;
//	DiagnosticsLog = Result.DiagnosticsLog;
//
Function ConnectionDiagnostics(URL, WriteError1 = True, IsPackageDeliveryCheckEnabled = True, ErrorText = "") Export
	
	LongDesc = New Array;
	LongDesc.Add(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Khi truy cập theo URL: %1';
			|ru = 'При обращении по URL: %1';
			|en = 'Accessing URL: %1.'; fa = 'Accessing URL: %1.';
			|it = 'Quando si accede all''URL: %1';
			|pl = 'Podczas odwołania do URL: %1';
			|tr = 'URL''ye erişirken: %1'"), 
		URL));
	LongDesc.Add(GetFilesFromInternetInternal.DiagnosticsLocationPresentation());
	
	RefStructure = CommonClientServer.URIStructure(URL);
	
	If Not IsBlankString(ErrorText)
		And StrFind(Upper(ErrorText), Upper("Deleted node not passed_ checking2")) > 0 Then // ACC:1297 - A non-localizable piece of information about an exception error.
		
		
		LongDesc.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr(
			"vi = 'Hãy kiểm tra đường dẫn chứng nhận cho chứng thư %1trên máy tính <%2>. Nếu cần, hãy cấp quyền truy cập vào thông tin của trung tâm chứng thực hoặc cài đặt chứng thư gốc và chứng thư trung gian. Nếu chứng thư là tự ký, hãy thêm nó vào các chứng thư đáng tin cậy.';
			|ru = 'Проверьте путь сертификации сертификата к %1 на компьютере <%2>. При необходимости предоставьте доступ к сведениям центра сертификации или установите корневой и промежуточные сертификаты. Если сертификат самоподписанный, добавьте его в доверенные.';
			|en = 'Check the certification path for the %1 certificate on computer <%2>. If necessary, grant access to the certification authority information or install the root and intermediate certificates. If the certificate is self-signed, add it to the trusted certificates.'; fa = 'Check the certification path for the %1 certificate on computer <%2>. If necessary, grant access to the certification authority information or install the root and intermediate certificates. If the certificate is self-signed, add it to the trusted certificates.';
			|it = 'Check the certification path for the %1 certificate on computer <%2>. If necessary, grant access to the certification authority information or install the root and intermediate certificates. If the certificate is self-signed, add it to the trusted certificates.';
			|pl = 'Check the certification path for the %1 certificate on computer <%2>. If necessary, grant access to the certification authority information or install the root and intermediate certificates. If the certificate is self-signed, add it to the trusted certificates.';
			|tr = '<%2> bilgisayarındaki %1 dahilindeki sertifikanın sertifika yolunu kontrol edin. Gerekirse, sertifika yetkilisi bilgilerine erişim izni verin veya kök ve ara sertifikaları yükleyin. Sertifika kendinden imzalıysa, sertifikayı güvenilir sertifikalara ekleyin.'"),
			RefStructure.ServerName, ComputerName()));
		
		GetFilesFromInternetLocalization.OnGenerateMessageAboutKnownIssue(LongDesc, ErrorText);
		
		ErrorDescription = StrConcat(LongDesc, Chars.LF);
		
		Result = New Structure;
		Result.Insert("ErrorDescription", ErrorDescription);
		Result.Insert("DiagnosticsLog", "");
		
		Return Result;
		
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		LongDesc.Add(NStr("vi = 'Hãy liên hệ với người quản trị.';
							|ru = 'Обратитесь к администратору.';
							|en = 'Please contact the administrator.'; fa = 'Please contact the administrator.';
							|it = 'Contattate l''amministratore.';
							|pl = 'Skontaktuj się z administratorem.';
							|tr = 'Yöneticiye başvurun.'"));
			
		GetFilesFromInternetLocalization.OnGenerateMessageAboutKnownIssue(LongDesc, ErrorText);
		
		ErrorDescription = StrConcat(LongDesc, Chars.LF);
		
		Result = New Structure;
		Result.Insert("ErrorDescription", ErrorDescription);
		Result.Insert("DiagnosticsLog", "");
		
		Return Result;
		
	EndIf;
	
	Log = New Array;
	If IsPackageDeliveryCheckEnabled Then
		Log.Add(
			NStr("vi = 'Nhật ký chẩn đoán:
			           |Kiểm tra tính khả dụng của máy chủ.
			           |Xem thông báo nhật ký sau để biết lỗi được chẩn đoán.';
			           |ru = 'Журнал диагностики:
			           |Выполняется проверка доступности сервера.
			           |Описание диагностируемой ошибки см. в следующем сообщении журнала.';
			           |en = 'Diagnostics log:
			           |Server availability test.
			           |See the error description in the next log record.'; fa = 'Diagnostics log:
			           |Server availability test.
			           |See the error description in the next log record.';
			           |it = 'Registro della diagnostica:
			           |Sta venendo eseguito un controllo di disponibilità del server.
			           |Per la descrizione dell''errore diagnosticato, consultare il seguente messaggio del registro.';
			           |pl = 'Dziennik diagnostyki:
			           |Jest wykonywana weryfikacja dostępności serwera.
			           |Opis wykrywanego błędu zob. w następnej wiadomości dziennika.';
			           |tr = 'Tanılama günlüğü: 
			           |sunucu kullanılabilirliğini denetler. 
			           |Teşhis edilen hatanın açıklaması için aşağıdaki günlük iletisine bakın.'"));
	Else
		Log.Add(
			NStr("vi = 'Nhật ký chẩn đoán:
			           |Kiểm tra tính khả dụng của máy chủ kiểm soát.
			           |Xem thông báo nhật ký sau để biết lỗi được chẩn đoán.';
			           |ru = 'Журнал диагностики:
			           |Выполняется проверка доступности контрольного сервера.
			           |Описание диагностируемой ошибки см. в следующем сообщении журнала.';
			           |en = 'Diagnostics log:
			           |Monitoring server availability test.
			           |See the error details in the next log record.'; fa = 'Diagnostics log:
			           |Monitoring server availability test.
			           |See the error details in the next log record.';
			           |it = 'Журнал диагностики:
			           |Выполняется проверка доступности контрольного сервера.
			           |Описание диагностируемой ошибки см. в следующем сообщении журнала.';
			           |pl = 'Diagnostics log:
			           |Monitoring server availability test.
			           |See the error details in the next log record.';
			           |tr = 'Tanılama günlüğü: 
			           |sunucu kullanılabilirliğini denetler. 
			           |Teşhis edilen hatanın açıklaması için aşağıdaki günlük iletisine bakın.'"));
	EndIf;
	Log.Add();
	
	ProxySettingsState = GetFilesFromInternetInternal.ProxySettingsState(RefStructure.Schema);
	ProxyConnection = ProxySettingsState.ProxyConnection;
	Log.Add(ProxySettingsState.Presentation);
	
	If ProxyConnection And Not ProxySettingsState.SystemProxySettingsUsed Then 
		
		LongDesc.Add(
			NStr("vi = 'Không thực hiện chẩn đoán kết nối vì đã tùy chỉnh proxy-server.
			           |Hãy liên hệ với người quản trị.';
			           |ru = 'Диагностика соединения не выполнена, т.к. настроен прокси-сервер.
			           |Обратитесь к администратору.';
			           |en = 'Connection diagnostics are not performed because a proxy server is configured.
			           |Please contact the administrator.'; fa = 'Connection diagnostics are not performed because a proxy server is configured.
			           |Please contact the administrator.';
			           |it = 'La diagnostica della connessione non è stata effettuata poiché è impostato un proxy-server.
			           |Rivolgetevi all''amministratore.';
			           |pl = 'Diagnostyka połączenia nie jest wykonana, ponieważ jest ustawiony serwer proxy.
			           |Zwróć się do administratora.';
			           |tr = 'Proxy sunucusu yapılandırıldığından bağlantı tanılama başarısız oldu. 
			           |Lütfen sistem yöneticinize başvurun.'"));
		
	Else
		
		ResourceServerAddress = RefStructure.Host;
		VerificationServerAddress = "google.com";
		GetFilesFromInternetLocalization.OnGetChecksumServerAddress(VerificationServerAddress);
		
		If IsPackageDeliveryCheckEnabled Then
			ResourceAvailabilityResult = GetFilesFromInternetInternal.CheckServerAvailability(ResourceServerAddress);
			
			Log.Add();
			Log.Add("1) " + ResourceAvailabilityResult.DiagnosticsLog);
		
			If ResourceAvailabilityResult.Available Then 
				
				LongDesc.Add(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã thực hiện kết nối đến tài nguyên không tồn tại trên máy chủ %1
					           |hoặc xảy ra lỗi trên máy chủ từ xa.';
					           |ru = 'Выполнено обращение к несуществующему ресурсу на сервере %1
					           |или возникли неполадки на удаленном сервере.';
					           |en = 'Attempted to access a resource that does not exist on server %1,
					           |or some issues occurred on the remote server.'; fa = 'Attempted to access a resource that does not exist on server %1,
					           |or some issues occurred on the remote server.';
					           |it = 'Si è cercato di accedere ad una risorsa inesistente sul server %1
					           | oppure si sono verificati dei guasti sul server remoto.';
					           |pl = 'Zostało wykonane odwołanie do nie istniejącego zasobu na serwerze %1
					           |lub wystąpiły problemy na usuniętym serwerze.';
					           |tr = 'Sunucudaki mevcut olmayan kaynağa erişildi%1
					           |veya uzak sunucuda sorun yaşandı.'"),
					ResourceServerAddress));
				
			Else 
				
				VerificationResult = GetFilesFromInternetInternal.CheckServerAvailability(VerificationServerAddress);
				Log.Add("2) " + VerificationResult.DiagnosticsLog);
				
				If Not VerificationResult.Available Then
					
					LongDesc.Add(
						NStr("vi = 'Không thể truy cập Internet do:
						           |- máy tính không có kết nối với Internet;
						           |- sự cố với nhà cung cấp Internet;
						           |- kết nối Internet bị chặn bởi tường lửa,
						           |chương trình chống vi-rút hoặc chương trình khác.';
						           |ru = 'Отсутствует доступ в сеть интернет по причине:
						           |- компьютер не подключен к интернету;
						           |- неполадки у интернет-провайдера;
						           |- подключение к интернету блокирует межсетевой экран, 
						           |  антивирус или другое программное обеспечение.';
						           |en = 'No Internet access. Possible reasons:
						           |- Computer is not connected to the Internet.
						           | - Internet provider issues.
						           |- Access blocked by firewall,
						           |antivirus, or another software.'; fa = 'No Internet access. Possible reasons:
						           |- Computer is not connected to the Internet.
						           | - Internet provider issues.
						           |- Access blocked by firewall,
						           |antivirus, or another software.';
						           |it = 'Отсутствует доступ в сеть интернет по причине:
						           |- компьютер не подключен к интернету;
						           |- неполадки у интернет-провайдера;
						           |- подключение к интернету блокирует межсетевой экран, 
						           |  антивирус или другое программное обеспечение.';
						           |pl = 'No Internet access. Possible reasons:
						           |- Computer is not connected to the Internet.
						           | - Internet provider issues.
						           |- Access blocked by firewall,
						           |antivirus, or another software.';
						           |tr = 'Aşağıdakilerden dolayı İnternet erişimi yoktur: - 
						           |bilgisayar İnternete bağlı değildir - 
						           | İnternet sağlayıcısıyla ilgili sorunlar - 
						           |
						           | İnternet bağlantısı, güvenlik duvarı, antivirüs programı veya diğer yazılımlar tarafından engellendi.'"));
					
				Else 
					
					LongDesc.Add(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Server %1 không khả dụng do:
						           |- sự cố với nhà cung cấp Internet;
						           |- kết nối với server bị chặn bởi tường lửa, 
						           |phần mềm chống vi-rút hoặc phần mềm khác;
						           |- server đang ngừng hoạt động hoặc đang được bảo trì.';
						           |ru = 'Сервер %1 недоступен по причине:
						           |- неполадки у интернет-провайдера;
						           |- подключение к серверу блокирует межсетевой экран, 
						           |  антивирус или другое программное обеспечение;
						           |- сервер отключен или на техническом обслуживании.';
						           |en = 'The %1 server is currently unavailable. Possible reasons:
						           |- Internet provider issues.
						           |- Access blocked by firewall,
						           |antivirus, or another software.
						           |- Server is disabled or undergoing maintenance.'; fa = 'The %1 server is currently unavailable. Possible reasons:
						           |- Internet provider issues.
						           |- Access blocked by firewall,
						           |antivirus, or another software.
						           |- Server is disabled or undergoing maintenance.';
						           |it = 'Сервер %1 недоступен по причине:
						           |- неполадки у интернет-провайдера;
						           |- подключение к серверу блокирует межсетевой экран, 
						           |  антивирус или другое программное обеспечение;
						           |- сервер отключен или на техническом обслуживании.';
						           |pl = 'The %1 server is currently unavailable. Possible reasons:
						           |- Internet provider issues.
						           |- Access blocked by firewall,
						           |antivirus, or another software.
						           |- Server is disabled or undergoing maintenance.';
						           |tr = 'Sunucuya%1 şu nedenlerden dolayı erişilemiyor: 
						           |- İnternet sağlayıcısıyla ilgili bir sorun; 
						           |- Sunucuyla bağlantı, güvenlik duvarı, 
						           |antivirüs veya diğer yazılımlar tarafından engellendi; 
						           |- Sunucunun bağlantısı kesildi veya bakım halinde.'"),
						ResourceServerAddress));
					
					TraceLog = GetFilesFromInternetInternal.ServerRouteTraceLog(ResourceServerAddress);
					Log.Add("3) " + TraceLog);
					
				EndIf;
				
			EndIf;
		Else
			VerificationResult = GetFilesFromInternetInternal.CheckServerAvailability(VerificationServerAddress);
				Log.Add("1) " + VerificationResult.DiagnosticsLog);
				
				If Not VerificationResult.Available Then
					
					LongDesc.Add(
						NStr("vi = 'Không thể truy cập Internet do:
						           |- máy tính không có kết nối với Internet;
						           |- sự cố với nhà cung cấp Internet;
						           |- kết nối Internet bị chặn bởi tường lửa,
						           |chương trình chống vi-rút hoặc chương trình khác.';
						           |ru = 'Отсутствует доступ в сеть интернет по причине:
						           |- компьютер не подключен к интернету;
						           |- неполадки у интернет-провайдера;
						           |- подключение к интернету блокирует межсетевой экран, 
						           |  антивирус или другое программное обеспечение.';
						           |en = 'No Internet access. Possible reasons:
						           |- Computer is not connected to the Internet.
						           | - Internet provider issues.
						           |- Access blocked by firewall,
						           |antivirus, or another software.'; fa = 'No Internet access. Possible reasons:
						           |- Computer is not connected to the Internet.
						           | - Internet provider issues.
						           |- Access blocked by firewall,
						           |antivirus, or another software.';
						           |it = 'Отсутствует доступ в сеть интернет по причине:
						           |- компьютер не подключен к интернету;
						           |- неполадки у интернет-провайдера;
						           |- подключение к интернету блокирует межсетевой экран, 
						           |  антивирус или другое программное обеспечение.';
						           |pl = 'No Internet access. Possible reasons:
						           |- Computer is not connected to the Internet.
						           | - Internet provider issues.
						           |- Access blocked by firewall,
						           |antivirus, or another software.';
						           |tr = 'Aşağıdakilerden dolayı İnternet erişimi yoktur: - 
						           |bilgisayar İnternete bağlı değildir - 
						           | İnternet sağlayıcısıyla ilgili sorunlar - 
						           |
						           | İnternet bağlantısı, güvenlik duvarı, antivirüs programı veya diğer yazılımlar tarafından engellendi.'"));
					
				Else 
					
					LongDesc.Add(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Server %1 không khả dụng do:
						           |- sự cố với nhà cung cấp Internet;
						           |- kết nối với server bị chặn bởi tường lửa, 
						           |phần mềm chống vi-rút hoặc phần mềm khác;
						           |- server đang ngừng hoạt động hoặc đang được bảo trì.';
						           |ru = 'Сервер %1 недоступен по причине:
						           |- неполадки у интернет-провайдера;
						           |- подключение к серверу блокирует межсетевой экран, 
						           |  антивирус или другое программное обеспечение;
						           |- сервер отключен или на техническом обслуживании.';
						           |en = 'The %1 server is currently unavailable. Possible reasons:
						           |- Internet provider issues.
						           |- Access blocked by firewall,
						           |antivirus, or another software.
						           |- Server is disabled or undergoing maintenance.'; fa = 'The %1 server is currently unavailable. Possible reasons:
						           |- Internet provider issues.
						           |- Access blocked by firewall,
						           |antivirus, or another software.
						           |- Server is disabled or undergoing maintenance.';
						           |it = 'Сервер %1 недоступен по причине:
						           |- неполадки у интернет-провайдера;
						           |- подключение к серверу блокирует межсетевой экран, 
						           |  антивирус или другое программное обеспечение;
						           |- сервер отключен или на техническом обслуживании.';
						           |pl = 'The %1 server is currently unavailable. Possible reasons:
						           |- Internet provider issues.
						           |- Access blocked by firewall,
						           |antivirus, or another software.
						           |- Server is disabled or undergoing maintenance.';
						           |tr = 'Sunucuya%1 şu nedenlerden dolayı erişilemiyor: 
						           |- İnternet sağlayıcısıyla ilgili bir sorun; 
						           |- Sunucuyla bağlantı, güvenlik duvarı, 
						           |antivirüs veya diğer yazılımlar tarafından engellendi; 
						           |- Sunucunun bağlantısı kesildi veya bakım halinde.'"),
						ResourceServerAddress));
				EndIf;
		EndIf;
	EndIf;
	
	GetFilesFromInternetLocalization.OnGenerateMessageAboutKnownIssue(LongDesc, ErrorText);
	
	ErrorDescription = StrConcat(LongDesc, Chars.LF);
	
	Log.Insert(0);
	Log.Insert(0, ErrorDescription);
	
	DiagnosticsLog = StrConcat(Log, Chars.LF);
	
	If WriteError1 Then
		WriteLogEvent(
			NStr("vi = 'Chẩn đoán';
				|ru = 'Диагностика соединения';
				|en = 'Connection diagnostics'; fa = 'Connection diagnostics';
				|it = 'Diagnostica della connessione';
				|pl = 'Diagnostyka połączenia';
				|tr = 'Bağlantı tanısı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, DiagnosticsLog);
	EndIf;
	
	Result = New Structure;
	Result.Insert("ErrorDescription", ErrorDescription);
	Result.Insert("DiagnosticsLog", DiagnosticsLog);
	
	Return Result;
	
EndFunction

// Defines the import timeout (in seconds) for the given file size.
// The timeout equals the file size multiplied by 128.
// If the size if unknown, then the timeout is maximum (no more than 43200).
// The minimal timeout is 30, which is required to establish a connection.
//
// Parameters:
//  Size - Number - File size in bytes.
//
// Returns:
//  Number
//
Function FileImportTimeout(Size) Export
	
	BytesInMegabyte = 1048576;
	
	Timeout = Round(Size / BytesInMegabyte * 128);
	If Timeout > 43200 Then
		Timeout = 43200;
	ElsIf Timeout < 30 Then
			Timeout = 30;
	EndIf;
	
	Return Timeout;
	
EndFunction

#EndRegion
