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

#EndRegion

#Region Public

// Sends the exchange message to the specified resource from the temporary exchange message directory.
//
// Parameters:
//  MessageForDataMapping - Boolean - If the message is intended for mapping
// 
//  Returns:
//    Boolean - True if the function is executed successfully, False if an error occurred.
// 
Function SendData(MessageForDataMapping = False) Export
	
	Result = True;
		
	Try
		Result = SendMessage();
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Result = False;
		
	EndTry;
	
	Return Result;

EndFunction

// Gets an exchange message from the specified resource and puts it in the temporary exchange message directory.
//
//  Returns:
//    Boolean - True if the function is executed successfully, False if an error occurred.
// 
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

// Returns the peer infobase parameters. Applicable when the peer infobase uses a direct connection. 
// 
// Parameters:
//  ConnectionSettings - Structure - Peer infobase connection settings.
//    See DataExchangeServer.ExchangeSettingsForInfobaseNode
// 
// Returns: 
//   Structure - See ExchangeMessagesTransport.StructureOfResultOfObtainingParametersOfCorrespondent.
//
Function CorrespondentParameters(ConnectionSettings) Export
	
	Result = ExchangeMessagesTransport.StructureOfResultOfObtainingParametersOfCorrespondent();
	Result.ConnectionIsSet = True;
	Result.ConnectionAllowed = True;
	
	Return Result;
	
EndFunction

// Runs before sending and exporting data.
//
// Parameters:
//  MessageForDataMapping - Boolean - If the message is intended for mapping
// 
//  Returns:
//    Boolean - True if the function is executed successfully, False if an error occurred.
// 
Function BeforeExportData(MessageForDataMapping = False) Export
	
	Return True;
	
EndFunction

// Saves synchronization settings to the peer infobase. Applicable for direct connections to the peer infobase.
// 
// Parameters:
//  ConnectionSettings - Structure - Peer infobase connection settings.
//    See DataExchangeServer.ExchangeSettingsForInfobaseNode
// 
// Returns: 
//   Boolean - "True" if the parameters are successfully saved. "False" is errors occurred.
//
Function SaveSettingsInCorrespondent(ConnectionSettings) Export
		
	Return True;
	
EndFunction

// Checks if additional authentication data should be provided before syncing.
// See DataProcessorObject.ExchangeMessageTransportWS.AuthenticationRequired
// 
// Returns: 
//   Boolean - "True" if authentication is required.
//   In this case, an authentication form is required in the "TransportParameters" manager module procedure. 
//   "False" if authentication is not required
//
Function AuthenticationRequired() Export
	
	Return False;
	
EndFunction

// This event occurs if synchronization is deleted with the parameter "Also delete setting in peer infobase". 
// 
// Returns:
//  Boolean - If deleted successfully. "False" if an error occurred.
Function DeleteSynchronizationSettingInCorrespondent() Export

	Return True;
		
EndFunction

#EndRegion

#Region Private

Function ConnectionIsSet() Export
	
	Directory = New File(DataExchangeDirectory);
	
	If IsBlankString(DataExchangeDirectory) Then
		
		ErrorMessage = NStr("vi = 'Lỗi kết nối: Chưa chỉ ra thư mục trao đổi thông tin.';
							|ru = 'Ошибка подключения: Не указан каталог обмена информацией.';
							|en = 'Connection error: The data exchange directory is not specified.'; fa = 'Connection error: The data exchange directory is not specified.';
							|it = 'Errore di connessione: Nessuna directory di scambio informazioni specificata.';
							|pl = 'Błąd podłączenia: Nie wskazano katalogu wymiany informacji.';
							|tr = 'Bağlantı hatası: Veri alışverişi dizini belirtilmedi.'");
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	ElsIf Not Directory.Exists() Then
		
		ErrorMessage = NStr("vi = 'Lỗi kết nối: Thư mục trao đổi thông tin không tồn tại.';
							|ru = 'Ошибка подключения: Каталог обмена информацией не существует.';
							|en = 'Connection error: The data exchange directory does not exist.'; fa = 'Connection error: The data exchange directory does not exist.';
							|it = 'Errore di connessione: La directory di scambio informazioni non esiste.';
							|pl = 'Błąd podłączenia: Nie istnieje katalogu wymiany informacji.';
							|tr = 'Bağlantı hatası: Veri alışverişi dizini mevcut değil.'");
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	EndIf;
	
	CheckFileName = DataExchangeServer.TempConnectionTestFileName();
	
	If Not CreateCheckFile(CheckFileName) Then
		
		ErrorMessage = NStr("vi = 'Lỗi ghi lại tệp vào thư mục trao đổi thông tin. Hãy kiểm tra quyền truy cập của người sử dụng đến thư mục.';
							|ru = 'Ошибка записи файла в каталог обмена информацией. Проверьте права пользователя на доступ к каталогу.';
							|en = 'An error occurred when saving the file to the data exchange directory. Check if the user is authorized to access the directory.'; fa = 'An error occurred when saving the file to the data exchange directory. Check if the user is authorized to access the directory.';
							|it = 'Errore durante la scrittura del file nella directory di scambio informazioni. Verificare i diritti dell''utente per accedere alla directory.';
							|pl = 'Błąd zapisu pliku do katalogu wymiany informacji. Sprawdź uprawnienia użytkownika na dostęp do katalogu.';
							|tr = 'Dosya veri alışverişi dizinine yazılırken bir hata oluştu. Kullanıcının dizine erişme yetkisi olup olmadığını kontrol edin.'");
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	ElsIf Not DeleteCheckFile(CheckFileName) Then
		
		ErrorMessage = NStr("vi = 'Lỗi xóa tệp khỏi thư mục trao đổi thông tin. Hãy kiểm tra quyền truy cập của người sử dụng đến thư mục.';
							|ru = 'Ошибка удаления файла из каталога обмена информацией. Проверьте права пользователя на доступ к каталогу.';
							|en = 'An error occurred when removing the file from the data exchange directory. Check if the user is authorized to access the directory.'; fa = 'An error occurred when removing the file from the data exchange directory. Check if the user is authorized to access the directory.';
							|it = 'Errore durante l''eliminazione del file dalla directory di scambio informazioni. Verificare i diritti dell''utente per accedere alla directory.';
							|pl = 'Błąd usunięcia pliku z katalogu wymiany informacji. Sprawdź uprawnienia użytkownika na dostęp do katalogu.';
							|tr = 'Dosya veri alışverişi dizininden kaldırılırken bir hata oluştu. Kullanıcının dizine erişme yetkisi olup olmadığını kontrol edin.'");
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

Function SendMessage()
	
	Result = True;
	
	If CompressOutgoingMessageFile Then
		
		If Not ExchangeMessagesTransport.PackExchangeMessageIntoZipFile(ThisObject, ArchivePasswordExchangeMessages) Then
			Result = False;
		EndIf;
		
		File = New File(ExchangeMessage);
		ReceiverFileName = CommonClientServer.GetFullFileName(DataExchangeDirectory, File.Name);
		
	Else
		
		ReceiverFileName = CommonClientServer.GetFullFileName(DataExchangeDirectory, NameOfMessageToSend);
		
	EndIf;
	
	// Copying the message file to the data exchange directory.
	If Not ExecuteFileCopying(ExchangeMessage, ReceiverFileName) Then
		Result = False;
	EndIf;
	
	Return Result;
	
EndFunction

Function GetMessage(MessageNameTemplate)
	
	ExchangeMessagesFilesTable = New ValueTable;
	ExchangeMessagesFilesTable.Columns.Add("File", New TypeDescription("File"));
	ExchangeMessagesFilesTable.Columns.Add("Modified");
	
	FoundFileArray = FindFiles(DataExchangeDirectory, MessageNameTemplate, False);
	
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
			
		ErrorMessage = 
			NStr("vi = 'Trong thư mục trao đổi thông tin, chưa tìm thấy tệp thông báo có dữ liệu.
                  |Thư mục trao đổi thông tin: ""%1""
                  |Tên tệp thông báo trao đổi: ""%2""';
                  |ru = 'В каталоге обмена информацией не был обнаружен файл сообщения с данными.
                  |Каталог обмена информацией: ""%1""
                  |Имя файла сообщения обмена: ""%2""';
                  |en = 'An information exchange directory is missing a message file.
                  |Directory: %1
                  |File: %2'; fa = 'An information exchange directory is missing a message file.
                  |Directory: %1
                  |File: %2';
                  |it = 'В каталоге обмена информацией не был обнаружен файл сообщения с данными.
                  |Каталог обмена информацией: ""%1""
                  |Имя файла сообщения обмена: ""%2""';
                  |pl = 'An information exchange directory is missing a message file.
                  |Directory: %1
                  |File: %2';
                  |tr = 'Veri mesajı dosyası iletişim dizininde bulunamadı.
                  |Sunucudaki iletişim dizini: ""%1""
                  |Alışveriş mesajı dosyasının adı: ""%2""'");
		
		ErrorMessage = StrTemplate(ErrorMessage, DataExchangeDirectory, MessageNameTemplate);
		
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	Else
		
		ExchangeMessagesFilesTable.Sort("Modified Desc");
		
		// Obtaining the newest exchange message file from the table.
		File = ExchangeMessagesFilesTable[0].File;
		FilePacked = (Upper(File.Extension) = ".ZIP");
		
		If FilePacked Then
			
			If Not ExchangeMessagesTransport.UnzipExchangeMessageFromZipFile(
				ThisObject, File.FullName, ArchivePasswordExchangeMessages) Then
				
				Return False;
				
			EndIf;
			
		Else
			
			If Not ExecuteFileCopying(File.FullName, ExchangeMessage) Then
				
				Return False;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

Function CreateCheckFile(CheckFileName)
	
	TextDocument = New TextDocument;
	TextDocument.AddLine(NStr("vi = 'Tệp xác minh tạm thời';
								|ru = 'Временный файл проверки';
								|en = 'Temporary file for checking'; fa = 'Temporary file for checking';
								|it = 'File temporaneo di verifica';
								|pl = 'Tymczasowy plik weryfikacyjny';
								|tr = 'Geçici kontrol dosyası'"));
	
	Try
		
		TextDocument.Write(CommonClientServer.GetFullFileName(DataExchangeDirectory, CheckFileName));
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
			
		Return False;
		
	EndTry;
	
	Return True;
EndFunction

Function DeleteCheckFile(CheckFileName)
	
	Try
		
		DeleteFiles(DataExchangeDirectory, CheckFileName);
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	EndTry;
	
	Return True;
EndFunction

Function ExecuteFileCopying(Val SourceFileName, Val ReceiverFileName)
	
	Try
		
		DeleteFiles(ReceiverFileName);
		CopyFile(SourceFileName, ReceiverFileName);
		
	Except
		
		ErrorMessage = NStr("vi = 'Lỗi khi sao chép tệp từ %1 sang %2.';
							|ru = 'Ошибка при копировании файла из %1 в %2.';
							|en = 'Error copying file from %1 to %2.'; fa = 'Error copying file from %1 to %2.';
							|it = 'Ошибка при копировании файла из %1 в %2.';
							|pl = 'Error copying file from %1 to %2.';
							|tr = 'Dosya %1 2''den %2''e kopyalandığında bir hata oluştu.'");
		ErrorMessage = StrTemplate(ErrorMessage, SourceFileName, ReceiverFileName);
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False
		
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#Region Initialize

TempDirectory = Undefined;
ExchangeMessage = Undefined;

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf