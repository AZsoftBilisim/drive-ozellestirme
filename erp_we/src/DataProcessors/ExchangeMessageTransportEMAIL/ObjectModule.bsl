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

Var EmailOperationsCommonModule;

#EndRegion

#Region Public

// See DataProcessorObject.ExchangeMessageTransportFILE.SendData
Function SendData(MessageForDataMapping = False) Export
	
	Try
		Result = SendMessage();
	Except
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

// See DataProcessorObject.ExchangeMessageTransportFILE.BeforeExportData
Function BeforeExportData(MessageForDataMapping = False) Export
	
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.CorrespondentParameters
Function CorrespondentParameters(ConnectionSettings) Export
	
	Result = ExchangeMessagesTransport.StructureOfResultOfObtainingParametersOfCorrespondent();
	Result.ConnectionIsSet = True;
	Result.ConnectionAllowed = True;
	
	Return Result;
	
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
		
		SimpleBody = NStr("vi = 'Thông điệp trao đổi dữ liệu';
							|ru = 'Сообщение обмена данными';
							|en = 'Data exchange message'; fa = 'Data exchange message';
							|it = 'Messaggio di scambio dati';
							|pl = 'Wiadomość wymiany danych';
							|tr = 'Veri değişim mesajı'");
		
		Result = SendMessagebyEmail(
			SimpleBody,
			ReceiverFileName,
			ExchangeMessage);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function GetMessage(MessageNameTemplate)
	
	ExchangeMessagesTable = ExchangeMessagesTable();
	
	ColumnsArray1 = New Array;
	
	ImportParameters = New Structure;
	ImportParameters.Insert("GetHeaders", True);
	ImportParameters.Insert("CastMessagesToType", False);
	
	Try
		MessageSet = EmailOperationsCommonModule.DownloadEmailMessages(Account, ImportParameters);
	Except
		
		ErrorMessage = NStr("vi = 'Lỗi khi nhận tiêu đề thông điệp từ server email.';
							|ru = 'Ошибка при получении заголовков сообщений с сервера электронной почты.';
							|en = 'Error receiving message headers from the email server.'; fa = 'Error receiving message headers from the email server.';
							|it = 'Errore nella ricezione dei titoli di messaggi dal server di posta elettronica.';
							|pl = 'Błąd podczas odebrania nagłówków wiadomości z serweru poczty elektronicznej.';
							|tr = 'E-posta sunucusundan mesaj üst bilgileri alınırken hata oluştu.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndTry;
		
	For Each MailMessage In MessageSet Do
		
		Subject = TrimAll(MailMessage.Subject);
		Subject = StrReplace(Subject, Chars.Tab, "");
		
		NewRow = ExchangeMessagesTable.Add();
		NewRow.Subject = Subject;
		NewRow.PostingDate = MailMessage.PostingDate;
		NewRow.RowID = String(New UUID);
		NewRow.Id.Add(MailMessage);
		
	EndDo;

	Query = New Query;
	Query.Text = 
		"SELECT
		|	T.RowID AS RowID,
		|	T.PostingDate AS PostingDate,
		|	T.Subject AS Subject
		|INTO TT
		|FROM
		|	&ExchangeMessagesTable AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT.RowID AS RowID
		|FROM
		|	TT AS TT
		|WHERE
		|	TT.Subject LIKE &Template
		|
		|ORDER BY
		|	TT.PostingDate DESC";
	
	// Search ignoring the extension
	Position = StrFind(MessageNameTemplate, ".", SearchDirection.FromEnd);
	MessageNameTemplateForSearching = Left(MessageNameTemplate,  Position - 1);
	MessageNameTemplateForSearching = "%" + StrReplace(MessageNameTemplateForSearching, "*", "%") + "%";
	
	Query.SetParameter("ExchangeMessagesTable", ExchangeMessagesTable);
	Query.SetParameter("Template", MessageNameTemplateForSearching);
	
	EmailSearchResults = Query.Execute().Unload(); 
	
	If EmailSearchResults.Count() = 0 Then
		
		ErrorMessage = NStr("vi = 'Không tìm thấy email có tiêu đề: ""%1""';
							|ru = 'Не обнаружены письма с заголовком: ""%1""';
							|en = 'The messages with ""%1"" header are not found.'; fa = 'The messages with ""%1"" header are not found.';
							|it = 'Nessuna lettera trovata con il titolo: ""%1""';
							|pl = 'Nie znaleziono wiadomości z nagłówkiem: ""%1""';
							|tr = '""%1"" başlıklı yazılar bulunmadı'");
		ErrorMessage = StrTemplate(ErrorMessage, MessageNameTemplate);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndIf;
	
	ColumnsArray1 = New Array;
	ColumnsArray1.Add("Attachments");
	
	Id = ExchangeMessagesTable.Find(EmailSearchResults[0].RowID).Id;
	
	ImportParameters = New Structure;
	ImportParameters.Insert("Columns", ColumnsArray1);
	ImportParameters.Insert("HeadersIDs", Id);
		
	Try
		MessageSet = EmailOperationsCommonModule.DownloadEmailMessages(Account, ImportParameters);
	Except
		
		ErrorMessage = NStr("vi = 'Lỗi khi nhận thông điệp từ máy chủ email.';
							|ru = 'Ошибка при получении сообщения с сервера электронной почты.';
							|en = 'Error receiving the message from the email server.'; fa = 'Error receiving the message from the email server.';
							|it = 'Errore nella ricezione del messaggio dal server di posta elettronica.';
							|pl = 'Błąd podczas odebrania wiadomości z serwera poczty elektronicznej.';
							|tr = 'E-posta sunucusundan mesaj alınırken hata oluştu.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndTry;

	BinaryData = Undefined;
	For Each KeyAndValue In MessageSet[0].Attachments Do
		FilePacked = Upper(Right(KeyAndValue.Key, 3)) = "ZIP";
		BinaryData = KeyAndValue.Value;
	EndDo;
	
	If BinaryData = Undefined Then
		
		ErrorMessage = NStr("vi = 'Lỗi: trong email không tìm thấy tệp có thông điệp.';
							|ru = 'Ошибка: в почтовом сообщении не найден файл с сообщением.';
							|en = 'Error: no exchange message file is found in the email message.'; fa = 'Error: no exchange message file is found in the email message.';
							|it = 'Errore: non è stato trovato il file con il messaggio nel messaggio di posta.';
							|pl = 'Błąd: w wiadomości pocztowej nie znaleziono pliku z wiadomością.';
							|tr = 'Hata: posta mesajında mesaj dosyası bulunamadı.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Return False;
		
	EndIf;
		
	If FilePacked Then
		
		// Getting the temporary archive file name.
		ArchiveTempFileName = CommonClientServer.GetFullFileName(
			ExchangeMessage, String(New UUID) + ".zip");
		
		BinaryData.Write(ArchiveTempFileName);
		
		If Not ExchangeMessagesTransport.UnzipExchangeMessageFromZipFile(
			ThisObject, ArchiveTempFileName, ArchivePasswordExchangeMessages) Then
			
			Return False;
			
		EndIf;
	
	Else
		
		Try
			BinaryData.Write(ExchangeMessage);
		Except
			
			ErrorMessage = NStr("vi = 'Lỗi khi ghi lại tệp thông điệp trao đổi trên đĩa.';
								|ru = 'Ошибка при записи файла сообщения обмена на диск.';
								|en = 'Error saving the exchange message file to the hard drive.'; fa = 'Error saving the exchange message file to the hard drive.';
								|it = 'Errore durante la scrittura del file di messaggio di scambio sul disco.';
								|pl = 'Błąd podczas zapisywania pliku wiadomości wymiany na dysk.';
								|tr = 'Alışveriş mesajı dosyası diske kaydedilirken bir hata oluştu.'");
			ErrorMessageEventLog = ErrorMessage;
		
			ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
			ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
			
			Return False;
			
		EndTry;
		
	EndIf;
	
	Return True;
	
EndFunction

Function ConnectionIsSet() Export
	
	If Not ValueIsFilled(Account) Then
		ErrorMessage = NStr("vi = 'Lỗi khởi tạo: chưa chỉ ra trương mục email truyền thông điệp trao đổi.';
							|ru = 'Ошибка инициализации: не указана учетная запись электронной почты транспорта сообщений обмена.';
							|en = 'Initialization error: the exchange message transport email account is not specified.'; fa = 'Initialization error: the exchange message transport email account is not specified.';
							|it = 'Errore di inizializzazione: l''account e-mail di trasmissione dei messaggi di scambio non è specificato.';
							|pl = 'Błąd inicjalizacji: nie wskazano konta poczty elektronicznej transportu wiadomości wymiany.';
							|tr = 'Başlatma hatası: ileti aktarım paylaşımı e-posta hesabı belirtilmedi.'");
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function ExchangeMessagesTable()
	
	ExchangeMessagesTable = New ValueTable;
	ExchangeMessagesTable.Columns.Add("RowID", New TypeDescription("String",,,, New StringQualifiers(36)));
	ExchangeMessagesTable.Columns.Add("Id",   New TypeDescription("Array"));
	ExchangeMessagesTable.Columns.Add("PostingDate", New TypeDescription("Date"));
	ExchangeMessagesTable.Columns.Add("Subject", New TypeDescription("String",,,, New StringQualifiers(200)));
	
	Return ExchangeMessagesTable;
	
EndFunction

Function SendMessagebyEmail(Body, OutgoingMessageFileName, PathToFile)
	
	AttachmentDetails = New Structure;
	AttachmentDetails.Insert("Presentation", OutgoingMessageFileName);
	AttachmentDetails.Insert("AddressInTempStorage", PutToTempStorage(New BinaryData(PathToFile)));
	
	Email = Common.ObjectAttributeValue(Account, "Email");
	
	MessageSubject1 = "Exchange message (%1)"; // Non-localizable string.
	MessageSubject1 = StrTemplate(MessageSubject1, OutgoingMessageFileName);
	
	MessageParameters = New Structure;
	MessageParameters.Insert("Whom",     Email);
	MessageParameters.Insert("Subject",     MessageSubject1);
	MessageParameters.Insert("Body",     Body);
	MessageParameters.Insert("Attachments", New Array);
	
	MessageParameters.Attachments.Add(AttachmentDetails);
	
	Try
		NewEmail = EmailOperationsCommonModule.PrepareEmail(Account, MessageParameters);
		EmailOperationsCommonModule.SendMail(Account, NewEmail);
	Except
		
		ErrorMessage = NStr("vi = 'Lỗi khi gửi thông điệp qua email.';
							|ru = 'Ошибка при отправке сообщения электронной почты.';
							|en = 'Error sending the email message.'; fa = 'Error sending the email message.';
							|it = 'Errore nell''invio di email.';
							|pl = 'Błąd podczas wysyłki poczty elektronicznej.';
							|tr = 'E-posta gönderilirken bir hata oluştu.'");
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Return False;
		
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#Region Initialize

TempDirectory = Undefined;
MessagesOfExchange  = Undefined;

If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
	EmailOperationsCommonModule = Common.CommonModule("EmailOperations");
EndIf;

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf