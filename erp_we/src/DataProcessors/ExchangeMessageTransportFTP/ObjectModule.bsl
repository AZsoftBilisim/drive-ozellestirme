///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ExchangeMessage Export; // For import, it is the name of the file stored in "TempDirectory". For export, the name of the file to be sent out
Var TempDirectory Export; // A temporary exchange directory.
Var DirectoryID Export;
Var Peer Export;
Var ExchangePlanName Export;
Var CorrespondentExchangePlanName Export;
Var ErrorMessage Export;
Var ErrorMessageEventLog Export;

Var NameTemplatesForReceivingMessage Export;
Var NameOfMessageToSend Export;

// For FTP
Var SendGetDataTimeout; // Timeout for exchanging data with a FTP server.
Var PingTimeout; // FTP connection check timeout.
Var FTPServerName; // FTP server name or IP address.
Var DirectoryAtFTPServer; // Directory on server for storing and receiving exchange messages.

#EndRegion

#Region Public

// See DataProcessorObject.ExchangeMessageTransportFILE.SendData
Function SendData(MessageForDataMapping = False) Export
	
	Try
		Result = SendMessage();
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Result = False;
		
	EndTry;
	
	Return Result;

EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.GetData
Function GetData() Export
	
	Try
		
		For Each Template In NameTemplatesForReceivingMessage Do
			
			Result = GetMessage(Template);
			
			If Result Then
				Break;
			EndIf;
			
		EndDo;
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Result = False;
		
	EndTry;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.CorrespondentParameters
Function CorrespondentParameters(ConnectionSettings) Export
	
	Result = ExchangeMessagesTransport.StructureOfResultOfObtainingParametersOfCorrespondent();
	Result.ConnectionIsSet = True;
	Result.ConnectionAllowed = True;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.BeforeExportData
Function BeforeExportData(MessageForDataMapping = False) Export
	
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.SaveSettingsInCorrespondent
Function SaveSettingsInCorrespondent(ConnectionSettings) Export
		
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.AuthenticationRequired
Function AuthenticationRequired() Export
	
	Return False;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionIsSet() Export
	
	// Function return value.
	Result = True;
	
	If Common.DataSeparationEnabled() Then
		Return Result;
	EndIf;
	
	If IsBlankString(Path) Then
		ErrorMessage = NStr("vi = 'Chưa đặt đường dẫn đến server.';
							|ru = 'Не задан путь на сервере.';
							|en = 'Path on the server is not specified.'; fa = 'Path on the server is not specified.';
							|it = 'Il percorso non è impostato sul server.';
							|pl = 'Nie zadano ścieżki na serwerze.';
							|tr = 'Sunucudaki yol belirtilmemiş.'");
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		Return False;
	EndIf;
	
	// Creating a file in the temporary directory.
	TempConnectionTestFileName = GetTempFileName("tmp");
	FileNameForDestination = DataExchangeServer.TempConnectionTestFileName();
	
	TextWriter = New TextWriter(TempConnectionTestFileName);
	TextWriter.WriteLine(FileNameForDestination);
	TextWriter.Close();
	
	// Copying a file to the external resource from the temporary directory.
	Result = CopyFileToFTPServer(TempConnectionTestFileName, FileNameForDestination, PingTimeout);
	
	// Deleting a file from the external resource.
	If Result Then
		Result = DeleteFileAtFTPServer(FileNameForDestination, True);
	EndIf;
	
	// Deleting a file from the temporary directory.
	DeleteFiles(TempConnectionTestFileName);
	
	Return Result;
	
EndFunction

Function SendMessage()
	
	Result = True;
	
	If CompressOutgoingMessageFile Then
		
		If Not ExchangeMessagesTransport.PackExchangeMessageIntoZipFile(ThisObject, ArchivePasswordExchangeMessages) Then
			Result = False;
		EndIf;

		File = New File(ExchangeMessage);
		ReceiverFileName = File.Name;
		
	Else
		
		ReceiverFileName = NameOfMessageToSend;

	EndIf;
	
	If Result Then
		
		// Checking that the exchange message size does not exceed the maximum allowed size.
		If DataExchangeServer.ExchangeMessageSizeExceedsAllowed(ExchangeMessage, MaxMessageSize) Then
			
			ErrorMessage = NStr("vi = 'Đã vượt quá dung lượng thông điệp trao đổi cho phép.';
								|ru = 'Превышен допустимый размер сообщения обмена.';
								|en = 'The maximum allowed exchange message size is exceeded.'; fa = 'The maximum allowed exchange message size is exceeded.';
								|it = 'La dimensione del messaggio di scambio ammessa è stata superata.';
								|pl = 'Został przekroczony dopuszczalny rozmiar wiadomości wymiany.';
								|tr = 'Veri alışverişi mesajının maksimum boyutu aşıldı.'");
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
			
			Result = False;
			
		EndIf;
		
	EndIf;
		
	If Result Then
		
		// Copying the archive file to the FTP server in the data exchange directory.
		If Not CopyFileToFTPServer(ExchangeMessage, ReceiverFileName, SendGetDataTimeout) Then
			Result = False;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function GetMessage(MessageNameTemplate)
	
	ExchangeMessagesFilesTable = New ValueTable;
	ExchangeMessagesFilesTable.Columns.Add("File");
	ExchangeMessagesFilesTable.Columns.Add("Modified");
	
	Try
		FTPConnection = GetFTPConnection(SendGetDataTimeout);
	Except
		
		ErrorMessage = NStr("vi = 'Lỗi khởi tạo kết nối đến máy chủ FTP.';
							|ru = 'Ошибка инициализации подключения к FTP-серверу.';
							|en = 'An occurred when initializing connection to the FTP server.'; fa = 'An occurred when initializing connection to the FTP server.';
							|it = 'Errore durante l''inizializzazione della connessione al server FTP.';
							|pl = 'Błąd inicjalizacji podłączenia do serwera FTP.';
							|tr = 'FTP-sunucusuna bağlantı başlatma hatası.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndTry;
	
	Try
		FoundFileArray = FTPConnection.FindFiles(DirectoryAtFTPServer, MessageNameTemplate, False);
	Except
		
		ErrorMessage = NStr("vi = 'Lỗi khởi tạo kết nối đến máy chủ FTP.';
							|ru = 'Ошибка инициализации подключения к FTP-серверу.';
							|en = 'An occurred when initializing connection to the FTP server.'; fa = 'An occurred when initializing connection to the FTP server.';
							|it = 'Errore durante l''inizializzazione della connessione al server FTP.';
							|pl = 'Błąd inicjalizacji podłączenia do serwera FTP.';
							|tr = 'FTP-sunucusuna bağlantı başlatma hatası.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndTry;
	
	For Each CurrentFile In FoundFileArray Do
		
		If Not CurrentFile.IsFile() Then
			
			Continue;
			
		// Checking that the file size is greater than 0.
		ElsIf (CurrentFile.Size() = 0) Then
			
			Continue;
			
		EndIf;
		
		// The file is a required exchange message. Adding the file to the table.
		TableRow = ExchangeMessagesFilesTable.Add();
		TableRow.File           = CurrentFile;
		TableRow.Modified = CurrentFile.GetModificationTime();
		
	EndDo;
	
	If ExchangeMessagesFilesTable.Count() = 0 Then
		
		ErrorMessage = NStr("vi = 'Trong thư mục trao đổi thông tin, chưa tìm thấy tệp thông báo có dữ liệu.
                                  |Thư mục trao đổi thông tin trên server: ""%1""
                                  |Tên tệp thông báo trao đổi: ""%2""';
                                  |ru = 'В каталоге обмена информацией не был обнаружен файл сообщения с данными.
                                  |Каталог обмена информацией на сервере: ""%1""
                                  |Имя файла сообщения обмена: ""%2""';
                                  |en = 'An information exchange directory is missing a message file.
                                  |Server directory: %1
                                  |File: %2'; fa = 'An information exchange directory is missing a message file.
                                  |Server directory: %1
                                  |File: %2';
                                  |it = 'В каталоге обмена информацией не был обнаружен файл сообщения с данными.
                                  |Каталог обмена информацией на сервере: ""%1""
                                  |Имя файла сообщения обмена: ""%2""';
                                  |pl = 'An information exchange directory is missing a message file.
                                  |Server directory: %1
                                  |File: %2';
                                  |tr = 'Veri mesajı dosyası iletişim dizininde bulunamadı.
                                  |Sunucudaki iletişim dizini: ""%1""
                                  |Alışveriş mesajı dosyasının adı: ""%2""'");
		
		ErrorMessage = StrTemplate(ErrorMessage, DirectoryAtFTPServer, MessageNameTemplate);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	Else
		
		ExchangeMessagesFilesTable.Sort("Modified Desc");
		
		// Obtaining the newest exchange message file from the table.
		File = ExchangeMessagesFilesTable[0].File;
		FilePacked = (Upper(File.Extension) = ".ZIP");
			
		If FilePacked Then
			
			ArchiveTempFileName = CommonClientServer.GetFullFileName(
				TempDirectory, String(New UUID) + ".zip");
				
			Try
				FTPConnection.Get(File.FullName, ArchiveTempFileName);
			Except

				ErrorMessage = NStr("vi = 'Lỗi khi nhận tệp từ server FTP.';
									|ru = 'Ошибка при получении файла с FTP-сервера.';
									|en = 'Error receiving the file from the FTP server.'; fa = 'Error receiving the file from the FTP server.';
									|it = 'Errore durante la ricezione del file sul server FTP.';
									|pl = 'Błąd podczas pobierania pliku z serwera FTP.';
									|tr = 'Dosya FTP-sunucusundan alınırken bir hata oluştu.'");
				ErrorMessageEventLog = ErrorMessage;
					
				ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
				ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
				
				Return False;
				
			EndTry;
		
			If Not ExchangeMessagesTransport.UnzipExchangeMessageFromZipFile(
				ThisObject, ArchiveTempFileName, ArchivePasswordExchangeMessages) Then
				
				Return False;
				
			EndIf;
			
		Else
	
			Try
				
				FTPConnection.Get(File.FullName, ExchangeMessage);
				
			Except
				
				ErrorMessage = NStr("vi = 'Lỗi khi nhận tệp từ server FTP.';
									|ru = 'Ошибка при получении файла с FTP-сервера.';
									|en = 'Error receiving the file from the FTP server.'; fa = 'Error receiving the file from the FTP server.';
									|it = 'Errore durante la ricezione del file sul server FTP.';
									|pl = 'Błąd podczas pobierania pliku z serwera FTP.';
									|tr = 'Dosya FTP-sunucusundan alınırken bir hata oluştu.'");
				ErrorMessageEventLog = ErrorMessage;
		
				ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
				ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport"); 
				
				Return False;
				
			EndTry;
			
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// FTP management.

Function GetFTPConnection(Timeout)
	
	ServerNameAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(Path));
	FTPServerName = ServerNameAndDirectoryAtServer.ServerName;
	DirectoryAtFTPServer = ServerNameAndDirectoryAtServer.DirectoryName;
	
	FTPSettings = ExchangeMessagesTransport.FTPConnectionSetup(Timeout);
	FTPSettings.Server               = FTPServerName;
	FTPSettings.Port                 = Port;
	FTPSettings.UserName      = User;
	FTPSettings.UserPassword   = Password;
	FTPSettings.PassiveConnection  = PassiveConnection;
	FTPSettings.SecureConnection = DataExchangeServer.SecureConnection(Path);
	
	Return ExchangeMessagesTransport.FTPConnection(FTPSettings);
	
EndFunction

Function CopyFileToFTPServer(Val SourceFileName, ReceiverFileName, Val Timeout)
	
	Var DirectoryAtServer;
	
	ServerAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(Path));
	DirectoryAtServer = ServerAndDirectoryAtServer.DirectoryName;
	
	Try
		FTPConnection = GetFTPConnection(Timeout);
	Except
		
		ErrorMessage = NStr("vi = 'Lỗi khởi tạo kết nối đến server FTP.';
							|ru = 'Ошибка инициализации подключения к FTP-серверу.';
							|en = 'An occurred when initializing connection to the FTP server.'; fa = 'An occurred when initializing connection to the FTP server.';
							|it = 'Errore durante l''inizializzazione della connessione al server FTP.';
							|pl = 'Błąd inicjalizacji podłączenia do serwera FTP.';
							|tr = 'FTP-sunucusuna bağlantı başlatma hatası.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Return False;
		
	EndTry;
	
	If Timeout = PingTimeout 
		And FTPConnection.PassiveMode 
		And Not PassiveConnection Then
		
		ErrorMessage = NStr("vi = 'Lỗi khi thử thiết lập kết nối chủ động với server FTP. Hãy thử sử dụng kết nối thụ động.';
							|ru = 'Ошибка при попытке установить активное соединение с FTP-сервером. Попробуйте использовать пассивное соединение.';
							|en = 'An error occurred during the attempt to establish an active connection to the FTP server. Try establishing a passive connection.'; fa = 'An error occurred during the attempt to establish an active connection to the FTP server. Try establishing a passive connection.';
							|it = 'Errore durante il tentativo di impostare una connessione attiva con il server FTP. Provare ad utilizzare la connessione passiva.';
							|pl = 'Błąd podczas próby ustawienia aktywnego połączenia z serwerem FTP. Spróbuj użyć pasywnego połączenia.';
							|tr = 'FTP sunucusuyla etkin bağlantı kurulumu sırasında hata oluştu. Pasif bağlantı kullanmayı deneyin.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Return False;
		
	EndIf;
	
	CreateDirectoryIfNecessary(FTPConnection, DirectoryAtServer);
	
	Try
		FTPConnection.Put(SourceFileName, DirectoryAtServer + ReceiverFileName);
	Except
		
		ErrorMessage = NStr("vi = 'Lỗi kết nối đến server FTP, hãy kiểm tra tính chính xác khi đặt đường dẫn và quyền truy cập đến tài nguyên.';
							|ru = 'Ошибка подключения к FTP-серверу, проверьте правильность задания пути и права доступа к ресурсу.';
							|en = 'An error occurred when establishing connection to the FTP server. Check whether the path is specified correctly and access rights are sufficient.'; fa = 'An error occurred when establishing connection to the FTP server. Check whether the path is specified correctly and access rights are sufficient.';
							|it = 'Errore durante la connessione al server FTP, verificare la correttezza del percorso e i diritti di accesso alla risorsa.';
							|pl = 'Błąd podłączenia do serwera FTP, sprawdź prawidłowość wskazania ścieżki i uprawnień dostępu do zasobu.';
							|tr = 'FTP-sunucuna bağlantı hatası, yol ve kaynak erişim hakkının doğru belirlenip belirlenmediğini kontrol edin.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");

		Return False;
	EndTry;
	
	If Common.DataSeparationEnabled() Then
		Return True;
	EndIf;
	
	Try
		FilesArray = FTPConnection.FindFiles(DirectoryAtServer, ReceiverFileName, False);
	Except
		
		ErrorMessage = NStr("vi = 'Lỗi khi tìm kiếm tệp trên server FTP.';
							|ru = 'Ошибка при поиске файлов на FTP-сервере.';
							|en = 'Error searching for files on the FTP server.'; fa = 'Error searching for files on the FTP server.';
							|it = 'Errore durante la ricerca di file sul server FTP.';
							|pl = 'Błąd podczas wyszukiwania plików na serwerze FTP.';
							|tr = 'Dosyalar FTP-sunucuda aranırken bir hata oluştu.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Return False;
		
	EndTry;
	
	Return FilesArray.Count() > 0;
	
EndFunction

Procedure CreateDirectoryIfNecessary(FTPConnection, DirectoryAtServer)
	
	If DirectoryAtServer = "/" Then
		Return;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		
		// When working in the service, checking the availability of the catalog is a very expensive operation.
		// Therefore, Create a directory is used every time. 
		// If the directory already exists, then go to the Exception and do nothing
		Try
			FTPConnection.CreateDirectory(DirectoryAtServer);
		Except
			// No action required
		EndTry;
		
	Else	
		
		NamesArray = StrSplit(DirectoryAtServer, "/", False);
		DirectoryName = "";
		
		For Each Name In NamesArray Do
		
			DirectoryName = DirectoryName + "/" + Name;
		
			If FTPConnection.FindFiles(DirectoryName).Count() = 0 Then
				FTPConnection.CreateDirectory(DirectoryName);
			EndIf;
		
		EndDo;
	
	EndIf;
	
EndProcedure

Function DeleteFileAtFTPServer(Val FileName, ConnectionCheckUp = False)
	
	Var DirectoryAtServer;
	
	ServerAndDirectoryAtServer = SplitFTPResourceToServerAndDirectory(TrimAll(Path));
	DirectoryAtServer = ServerAndDirectoryAtServer.DirectoryName;
	
	Try
		FTPConnection = GetFTPConnection(PingTimeout);
	Except
		
		ErrorMessage = NStr("vi = 'Lỗi khởi tạo kết nối đến server FTP.';
							|ru = 'Ошибка инициализации подключения к FTP-серверу.';
							|en = 'An occurred when initializing connection to the FTP server.'; fa = 'An occurred when initializing connection to the FTP server.';
							|it = 'Errore durante l''inizializzazione della connessione al server FTP.';
							|pl = 'Błąd inicjalizacji podłączenia do serwera FTP.';
							|tr = 'FTP-sunucusuna bağlantı başlatma hatası.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True); 
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	EndTry;
	
	Try
		FTPConnection.Delete(DirectoryAtServer + FileName);
	Except
		
		ErrorMessage = NStr("vi = 'Lỗi xóa tệp trên server FTP, hãy kiểm tra quyền truy cập đến tài nguyên.';
							|ru = 'Ошибка удаления файла на FTP-сервере, проверьте права доступа к ресурсу.';
							|en = 'Error deleting the file from the FTP server. Check whether resource access rights are sufficient.'; fa = 'Error deleting the file from the FTP server. Check whether resource access rights are sufficient.';
							|it = 'Errore durante l''eliminazione del file sul server FTP, controllare i diritti di accesso alla risorsa.';
							|pl = 'Błąd usunięcia pliku na serwerze FTP, sprawdź uprawnienia dostępu do zasobu.';
							|tr = 'Dosya FTP-sunucusundan kaldırılırken bir hata oluştu, kayak erişim haklarını kontrol edin.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		If ConnectionCheckUp Then
			
			ErrorMessage = NStr("vi = 'Không thể kiểm tra kết nối thông qua tệp thử nghiệm ""%1"".
				|Có thể là thư mục đã đặt không tồn tại hoặc không hợp lệ.
				|Nên tham khảo tài liệu về máy chủ FTP để tùy chỉnh hỗ trợ tên tệp Cyrillic.';
				|ru = 'Не удалось проверить подключение с помощью тестового файла ""%1"".
				|Возможно, заданный каталог не существует или не доступен.
				|Рекомендуется также обратиться к документации по FTP-серверу для настройки поддержки имен файлов с кириллицей.';
				|en = 'Cannot check connection using test file ""%1"".
				|Maybe, the specified directory does not exist or is unavailable.
				|Check FTP server documentation to configure support of Cyrillic file names.'; fa = 'Cannot check connection using test file ""%1"".
				|Maybe, the specified directory does not exist or is unavailable.
				|Check FTP server documentation to configure support of Cyrillic file names.';
				|it = 'Non è stato possibile verificare la connessione utilizzando il file di test ""%1"".
				| La directory specificata potrebbe non esistere o non è disponibile.
				|È inoltre consigliabile fare riferimento alla documentazione del server FTP per configurare il supporto per i nomi di file in cirillico.';
				|pl = 'Nie udało się sprawdzić połączenie przy pomocy pliku testowego ""%1"".
				|Możliwe, że nie istnieje zadanego katalogu lub on jest niedostępny.
				|Zaleca się także zwrócić się do dokumentacji, dotyczącej serwera FTP do ustawienia obsługi nazw plików z cyrylicą.';
				|tr = '""%1""Test dosyası kullanılarak bağlantı test edilemedi. 
				|Belirtilen dizin mevcut olmayabilir ya da erişilmeyebilir. 
				| Ayrıca Kiril alfabesi ile belirlenen dosya adlarını desteklemek için FTP sunucusu ile ilgili belgelere bakmanız önerilir.'");
			ErrorMessage = StrTemplate(ErrorMessage, FileName);
			ErrorMessageEventLog = ErrorMessage;
			
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
			
		EndIf;
		
		Return False;
		
	EndTry;
	
	Return True;
	
EndFunction

Function SplitFTPResourceToServerAndDirectory(Val FullPath)
	
	Result = New Structure("ServerName, DirectoryName");
	
	FTPParameters = ExchangeMessagesTransport.FTPServerNameAndPath(FullPath);
	
	Result.ServerName  = FTPParameters.Server;
	Result.DirectoryName = FTPParameters.Path;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Initialize

TempDirectory = Undefined;
ExchangeMessage = Undefined;

FTPServerName = Undefined;
DirectoryAtFTPServer = Undefined;

SendGetDataTimeout = 12*60*60;
PingTimeout = 10;

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf