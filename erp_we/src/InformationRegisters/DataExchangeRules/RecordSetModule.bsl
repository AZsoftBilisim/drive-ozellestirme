///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	For Each Record In ThisObject Do
		
		If Record.DebugMode Then
			
			ExchangePlanID = Common.MetadataObjectID(Metadata.ExchangePlans[Record.ExchangePlanName]);
			ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
			SecurityProfileName = ModuleSafeModeManagerInternal.ExternalModuleAttachmentMode(ExchangePlanID);
			
			If SecurityProfileName <> Undefined Then
				SetSafeMode(SecurityProfileName);
			EndIf;
			
			IsFileInfobase = Common.FileInfobase();
			
			If Record.ExportDebugMode Then
				
				CheckExternalDataProcessorFileExistence(Record.ExportDebuggingDataProcessorFileName, IsFileInfobase, Cancel);
				
			EndIf;
			
			If Record.ImportDebugMode Then
				
				CheckExternalDataProcessorFileExistence(Record.ImportDebuggingDataProcessorFileName, IsFileInfobase, Cancel);
				
			EndIf;
			
			If Record.DataExchangeLoggingMode Then
				
				CheckExchangeProtocolFileAvailability(Record.ExchangeProtocolFileName, Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckExternalDataProcessorFileExistence(FileToCheckName, IsFileInfobase, Cancel)
	
	FileNameStructure = CommonClientServer.ParseFullFileName(FileToCheckName);
	CheckDirectoryName	 = FileNameStructure.Path;
	CheckDirectory = New File(CheckDirectoryName);
	FileOnHardDrive = New File(FileToCheckName);
	DirectoryLocation = ? (IsFileInfobase, NStr("vi = 'trên Client';
												|ru = 'на клиенте';
												|en = 'on client'; fa = 'on client';
												|it = 'sul cliente';
												|pl = 'na kliencie';
												|tr = 'istemcide'"), NStr("vi = 'trên Server';
																			|ru = 'на сервере';
																			|en = 'on the server'; fa = 'on the server';
																			|it = 'sul server';
																			|pl = 'na serwerze';
																			|tr = 'sunucuda'"));
	
	If Not CheckDirectory.Exists() Then
		
		MessageString = NStr("vi = 'Thư mục ""%1"" không được tìm thấy %2.';
							|ru = 'Каталог ""%1"" не найден %2.';
							|en = 'Directory %1 not found %2.'; fa = 'Directory %1 not found %2.';
							|it = 'Catalogo ""%1"" non trovato %2.';
							|pl = 'Katalog ""%1"" nie został znaleziony %2.';
							|tr = '""%1"" dizini bulunamadı%2.'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CheckDirectoryName, DirectoryLocation);
		Cancel = True;
		
	ElsIf Not FileOnHardDrive.Exists() Then 
		
		MessageString = NStr("vi = 'Tệp bộ xử lý ngoài ""%1"" không được tìm thấy %2.';
							|ru = 'Файл внешней обработки ""%1"" не найден %2.';
							|en = 'File of external data processor %1 not found %2.'; fa = 'File of external data processor %1 not found %2.';
							|it = 'File di elaborazione esterno ""%1"" non trovato %2.';
							|pl = 'Nie znaleziono zewnętrznego pliku przetwarzania ""%1"" %2.';
							|tr = 'Harici veri işlemci dosyası ""%1"" bulunamadı%2.'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, FileToCheckName, DirectoryLocation);
		Cancel = True;
		
	Else
		
		Return;
		
	EndIf;
	
	Common.MessageToUser(MessageString,,,, Cancel);
	
EndProcedure

Procedure CheckExchangeProtocolFileAvailability(ExchangeProtocolFileName, Cancel)
	
	FileNameStructure = CommonClientServer.ParseFullFileName(ExchangeProtocolFileName);
	CheckDirectoryName = FileNameStructure.Path;
	CheckDirectory = New File(CheckDirectoryName);
	CheckFileName = "test.tmp";
	
	If Not CheckDirectory.Exists() Then
		
		MessageString = NStr("vi = 'Không tìm thấy thư mục tệp giao thức trao đổi ""%1"".';
							|ru = 'Папка файла протокола обмена ""%1"" не найдена.';
							|en = 'Exchange protocol file folder ""%1"" is not found.'; fa = 'Exchange protocol file folder ""%1"" is not found.';
							|it = 'Cartella del file di protocollo di scambio ""%1"" non trovata.';
							|pl = 'Nie znaleziono folderu pliku protokołu wymiany ""%1"".';
							|tr = 'Günlük dosya değişim klasörü ""%1"" bulunamadı.'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CheckDirectoryName);
		Cancel = True;
		
	ElsIf Not CreateCheckFile(CheckDirectoryName, CheckFileName) Then
		
		MessageString = NStr("vi = 'Không thể tạo tệp trong thư mục giao thức trao đổi: ""%1"".';
							|ru = 'Не удалось создать файл в папке протокола обмена: ""%1"".';
							|en = 'Cannot create a file in the exchange protocol folder: ""%1"".'; fa = 'Cannot create a file in the exchange protocol folder: ""%1"".';
							|it = 'Non è stato possibile creare il file nella cartella di protocollo di scambio: ""%1"".';
							|pl = 'Nie można utworzyć pliku w folderze protokołu wymiany: ""%1"".';
							|tr = 'Değişim protokolü klasöründe bir dosya oluşturulamıyor: ""%1"".'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CheckDirectoryName);
		Cancel = True;
		
	ElsIf Not DeleteCheckFile(CheckDirectoryName, CheckFileName) Then
		
		MessageString = NStr("vi = 'Không thể xóa tệp trong thư mục giao thức trao đổi: ""%1"".';
							|ru = 'Не удалось удалить файл в папке протокола обмена: ""%1"".';
							|en = 'Cannot delete a file from the exchange protocol folder: ""%1"".'; fa = 'Cannot delete a file from the exchange protocol folder: ""%1"".';
							|it = 'Non è stato possibile eliminare il file nella cartella del protocollo di scambio: ""%1"".';
							|pl = 'Nie można usunąć pliku w folderze protokołu wymiany: ""%1"".';
							|tr = 'Değişim protokolü klasöründen dosya silinemiyor: ""%1"".'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CheckDirectoryName);
		Cancel = True;
		
	Else
		
		Return;
		
	EndIf;
	
	Common.MessageToUser(MessageString,,,, Cancel);
	
EndProcedure

Function CreateCheckFile(CheckDirectoryName, CheckFileName)
	
	TextDocument = New TextDocument;
	TextDocument.AddLine(NStr("vi = 'Tệp xác minh tạm thời';
								|ru = 'Временный файл проверки';
								|en = 'Temporary file for checking'; fa = 'Temporary file for checking';
								|it = 'File temporaneo di verifica';
								|pl = 'Tymczasowy plik weryfikacyjny';
								|tr = 'Geçici kontrol dosyası'"));
	
	Try
		TextDocument.Write(CheckDirectoryName + "/" + CheckFileName);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function DeleteCheckFile(CheckDirectoryName, CheckFileName)
	
	Try
		DeleteFiles(CheckDirectoryName, CheckFileName);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf