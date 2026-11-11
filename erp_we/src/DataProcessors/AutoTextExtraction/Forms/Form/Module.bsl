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
	
	If Common.IsWebClient() Or Not Common.IsWindowsClient() Then
		Return; // Cancel is set in OnOpen().
	EndIf;
	
	TextExtractionEnabled = False;
	
	ExecutionTimeInterval = Common.CommonSettingsStorageLoad("AutoTextExtraction", "ExecutionTimeInterval");
	If ExecutionTimeInterval = 0 Then
		ExecutionTimeInterval = 60;
		Common.CommonSettingsStorageSave("AutoTextExtraction", "ExecutionTimeInterval",  ExecutionTimeInterval);
	EndIf;
	
	FileCountInBlock = Common.CommonSettingsStorageLoad("AutoTextExtraction", "FileCountInBlock");
	If FileCountInBlock = 0 Then
		FileCountInBlock = 100;
		Common.CommonSettingsStorageSave("AutoTextExtraction", "FileCountInBlock",  FileCountInBlock);
	EndIf;
	
	Items.UnextractedTextFilesCountInfo.Title = StatusTextCalculation();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not TextsExtractionAvailable() Then
		Cancel = True;
		MessageText = NStr("vi = 'Hỗ trợ lấy ra nội dung chỉ trên Client chạy hệ điều hành Windows.';
							|ru = 'Извлечение текстов поддерживается только в клиенте под управлением ОС Windows.';
							|en = 'Text extraction is only available in the Windows client.'; fa = 'Text extraction is only available in the Windows client.';
							|it = 'L''estrazione dei testi è supportata solo dal cliente gestito dal Sistema Operativo Windows.';
							|pl = 'Ekstrakcja tekstu jest obsługiwana tylko na kliencie SO Windows.';
							|tr = 'Metin çıkarma yalnızca Windows tabanlı bir istemcide desteklenir.'");
		ShowMessageBox(, MessageText);
		Return;
	EndIf;
	
	UpdateInformationOnFilesWithNonExtractedTextCount();
	
EndProcedure

&AtClient
Procedure ExecutionTimeIntervalOnChange(Item)
	
	CommonClient.CommonSettingsStorageSave("AutoTextExtraction", "ExecutionTimeInterval",  ExecutionTimeInterval);
	
	If TextExtractionEnabled Then
		DetachIdleHandler("TextExtractionClientHandler");
		ExpectedExtractionStartTime = CommonClient.SessionDate() + ExecutionTimeInterval;
		AttachIdleHandler("TextExtractionClientHandler", ExecutionTimeInterval);
		CountdownUpdate();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FileCountInBlockOnChange(Item)
	CommonClient.CommonSettingsStorageSave("AutoTextExtraction", "FileCountInBlock",  FileCountInBlock);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Start(Command)
	
	TextExtractionEnabled = True; 
	
	ExpectedExtractionStartTime = CommonClient.SessionDate();
	AttachIdleHandler("TextExtractionClientHandler", ExecutionTimeInterval);
	
#If Not WebClient And Not MobileClient Then
	TextExtractionClientHandler();
#EndIf
	
	AttachIdleHandler("CountdownUpdate", 1);
	CountdownUpdate();
	
EndProcedure

&AtClient
Procedure CommandStop(Command)
	ExecuteStop();
EndProcedure

&AtClient
Procedure ExtractAll(Command)
	
#If Not WebClient And Not MobileClient Then
		UnextractedTextFileCountBeforeOperation = UnextractedTextFileCount;
		Status = "";
		PortionSize = 0; // Extract all
		TextExtractionClient(PortionSize);
		
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã hoàn tất trích xuất văn bản từ
			         |tất cả các tệp có văn bản chưa được phục hồi.
			         |
			         |Các tệp đã xử lý: %1.';
			         |ru = 'Завершено извлечение текста из
			         |всех файлов с неизвлеченным текстом.
			         |
			         |Обработано файлов: %1.';
			         |en = 'Extracting text from all files
			         |with extraction pending is completed.
			         |
			         | Files processed: %1.'; fa = 'Extracting text from all files
			         |with extraction pending is completed.
			         |
			         | Files processed: %1.';
			         |it = 'L''estrazione del testo da
			         |tutti i file dove il testo non è stato estratto.
			         |
			         |File elaborati: %1.';
			         |pl = 'Zakończono wyodrębnianie tekstu ze
			         |wszystkich plików z nieodkrytym tekstem.
			         |
			         |Opracowano plików: %1.';
			         |tr = 'Metin ayıklamayan tüm dosyalardan
			         | metin çıkarımı tamamlandı.
			         |
			         | İşlenen dosyaların sayısı:%1.'"),
			UnextractedTextFileCountBeforeOperation));
#EndIf
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function TextsExtractionAvailable()
	
#If WebClient Or MobileClient Then
	Return False;
#Else
	Return CommonClient.IsWindowsClient();
#EndIf
	
EndFunction

&AtClientAtServerNoContext
Function StatusTextCalculation()
	Return NStr("vi = 'Tìm kiếm tệp chưa lấy ra nội dung...';
				|ru = 'Поиск файлов с неизвлеченным текстом...';
				|en = 'Searching for files with text extraction pending…'; fa = 'Searching for files with text extraction pending…';
				|it = 'La ricerca file con il testo non estratto...';
				|pl = 'Wyszukaj pliki z nieodzyskanym tekstem...';
				|tr = 'Çıkarılmamış metne sahip dosyalar aranıyor...'");
EndFunction

&AtClient
Procedure UpdateInformationOnFilesWithNonExtractedTextCount()
	
	DetachIdleHandler("StartUpdateInformationOnFileCountWithUnextractedText");
	If CurrentBackgroundJob = "Calculation1" And ValueIsFilled(BackgroundJobIdentifier) Then
		CancelBackgroundJob1();
	EndIf;
	AttachIdleHandler("StartUpdateInformationOnFileCountWithUnextractedText", 2, True);
	
EndProcedure

&AtClient
Procedure CancelBackgroundJob1()
	CancelJobExecution(BackgroundJobIdentifier);
	CurrentBackgroundJob = "";
	BackgroundJobIdentifier = "";
EndProcedure

&AtServerNoContext
Procedure CancelJobExecution(BackgroundJobIdentifier)
	If ValueIsFilled(BackgroundJobIdentifier) Then 
		TimeConsumingOperations.CancelJobExecution(BackgroundJobIdentifier);
	EndIf;
EndProcedure

&AtClient
Procedure StartUpdateInformationOnFileCountWithUnextractedText()
	
	If ValueIsFilled(BackgroundJobIdentifier) Then
		Items.UnextractedTextFilesCountInfo.Title = StatusTextCalculation();
		Return;
	EndIf;
	
	Items.UnextractedTextFilesCountInfo.Title = StatusTextCalculation();
	TimeConsumingOperation = ExecuteSearchOfFilesWIthNonExtractedText();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	CallbackDescription = New CallbackDescription("OnCompleteUpdateUnextractedTextFilesCountInformation", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure OnCompleteUpdateUnextractedTextFilesCountInformation(Result, AdditionalParameters) Export
	
	BackgroundJobIdentifier = "";
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;

	OutputInformationOnNonExtractedTextFilesCount();
	
EndProcedure

&AtClient
Procedure OutputInformationOnNonExtractedTextFilesCount()
	
	UnextractedTextFilesCountInfo = GetFromTempStorage(ResultAddress);
	If UnextractedTextFilesCountInfo = Undefined Then
		Return;
	EndIf;
	
	UnextractedTextFileCount = UnextractedTextFilesCountInfo;
	
	If UnextractedTextFileCount > 0 Then
		Items.UnextractedTextFilesCountInfo.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Số lượng tệp có nội dung chưa lấy ra: %1';
				|ru = 'Количество файлов с неизвлеченным текстом: %1';
				|en = 'Files with text extraction pending: %1'; fa = 'Files with text extraction pending: %1';
				|it = 'Numero file con il testo non estratto: %1';
				|pl = 'Ilość plików z nieodzyskanym tekstem: %1';
				|tr = 'Çıkarılmamış metne sahip dosya sayısı: %1'"),
			UnextractedTextFileCount);
	Else
		Items.UnextractedTextFilesCountInfo.Title = NStr("vi = 'Số lượng tệp có nội dung chưa lấy ra: không';
														|ru = 'Количество файлов с неизвлеченным текстом: нет';
														|en = 'Files with text extraction pending: None'; fa = 'Files with text extraction pending: None';
														|it = 'Numero file con il testo non estratto: no';
														|pl = 'Ilość plików z nieodzyskanym tekstem: Nie';
														|tr = 'Çıkarılmamış metne sahip dosya sayısı: yok'");
	EndIf;
	
EndProcedure

&AtServer
Function ExecuteSearchOfFilesWIthNonExtractedText()
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tìm kiếm tệp chưa lấy ra nội dung.';
														|ru = 'Поиск файлов с неизвлеченным текстом.';
														|en = 'Search for files with text extraction pending.'; fa = 'Search for files with text extraction pending.';
														|it = 'Ricerca file con il testo non estratto.';
														|pl = 'Wyszukiwanie plików z niepobranym tekstem.';
														|tr = 'Çıkarılmamış metne sahip dosyalar aranıyor.'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "FilesOperationsInternal.VersionsWithUnextractedTextCount");
	CurrentBackgroundJob = "Calculation1";
	BackgroundJobIdentifier = TimeConsumingOperation.JobID;
	ResultAddress = TimeConsumingOperation.ResultAddress;
	
	Return TimeConsumingOperation;
	
EndFunction

&AtServerNoContext
Procedure WriteLogEventServer(MessageText)
	
	WriteLogEvent(NStr("vi = 'Tệp.Trích dẫn nội dung';
						|ru = 'Файлы.Извлечение текста';
						|en = 'Files.Extract text'; fa = 'Files.Extract text';
						|it = 'File.Estrazione testo';
						|pl = 'Pliki.Pobieranie tekstu';
						|tr = 'Dosyalar. Metin Çıkarma'", Common.DefaultLanguageCode()),
		EventLogLevel.Error,,, MessageText);
	
EndProcedure

&AtClient
Procedure CountdownUpdate()
	
	Left = ExpectedExtractionStartTime - CommonClient.SessionDate();
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Còn %1 giây trước khi bắt đầu lấy ra nội dung ';
			|ru = 'До начала извлечения текстов осталось %1 сек';
			|en = 'Text extraction starts in %1 sec'; fa = 'Text extraction starts in %1 sec';
			|it = 'Mancano %1 secondi all''inizio dell''estrazione testi';
			|pl = 'Pozostało do ekstrakcji tekstu %1 sek';
			|tr = '%1 metin çıkarımı başlamadan önce'"),
		Left);
	
	If Left <= 1 Then
		MessageText = "";
	EndIf;
	
	ExecutionTimeInterval = Items.ExecutionTimeInterval.EditText;
	Status = MessageText;
	
EndProcedure

&AtClient
Procedure TextExtractionClientHandler()
	
#If Not WebClient And Not MobileClient Then
	TextExtractionClient();
#EndIf

EndProcedure

#If Not WebClient And Not MobileClient Then
	
// Extracts text from files for full-text search.
&AtClient
Procedure TextExtractionClient(PortionSize = Undefined)
	
	ExpectedExtractionStartTime = CommonClient.SessionDate() + ExecutionTimeInterval;
	
	Try
		
		PortionSizeCurrent = FileCountInBlock;
		If PortionSize <> Undefined Then
			PortionSizeCurrent = PortionSize;
		EndIf;
		FilesArray = GetFilesForTextExtraction(PortionSizeCurrent);
		
		If FilesArray.Count() = 0 Then
			ShowUserNotification(NStr("vi = 'Lấy ra nội dung';
										|ru = 'Извлечение текстов';
										|en = 'Extract text'; fa = 'استخراج متن';
										|it = 'Estrazione testi';
										|pl = 'Pobieranie tekstów';
										|tr = 'Metinlerin çıkarılması'"),, NStr("vi = 'Không có tệp để trích ra nội dung';
																	|ru = 'Нет файлов для извлечения текста';
																	|en = 'No files for text extraction.'; fa = 'No files for text extraction.';
																	|it = 'Nessun file per estrazione testi';
																	|pl = 'Brak plików do wyodrębnienia tekstu';
																	|tr = 'Metni çıkarılacak dosya yok'"));
			Return;
		EndIf;
		
		For IndexOf = 0 To FilesArray.Count() - 1 Do
			
			Extension = FilesArray[IndexOf].Extension;
			FileDescription = FilesArray[IndexOf].Description;
			FileOrFileVersion = FilesArray[IndexOf].Ref;
			Encoding = FilesArray[IndexOf].Encoding;
			
			Try
				FileAddress = GetFileNavigationLink(
					FileOrFileVersion, UUID);
				
				NameWithExtension = CommonClientServer.GetNameWithExtension(
					FileDescription, Extension);
				
				Progress = IndexOf * 100 / FilesArray.Count();
				Status(NStr("vi = 'Đang lấy ra nội dung của tệp';
							|ru = 'Идет извлечение текста файла';
							|en = 'Extracting text from files'; fa = 'Extracting text from files';
							|it = 'Estrazione testo del file è in corso';
							|pl = 'Pobieranie tekstu pliku';
							|tr = 'Dosya metnini çıkarma'"), Progress, NameWithExtension);
				
				FilesOperationsInternalClient.ExtractVersionText(
					FileOrFileVersion, FileAddress, Extension, UUID, Encoding);
			
			Except
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Tình huống bất thường khi trích dẫn văn bản từ tệp ""%1"":
						|%2';
						|ru = 'Непредвиденная ситуация при извлечении текста из файла ""%1"":
						|%2';
						|en = 'An unexpected error occurred while extracting the text from the ""%1"" file:
						|%2'; fa = 'An unexpected error occurred while extracting the text from the ""%1"" file:
						|%2';
						|it = 'Непредвиденная ситуация при извлечении текста из файла ""%1"":
						|%2';
						|pl = 'An unexpected error occurred while extracting the text from the ""%1"" file:
						|%2';
						|tr = '""%1"" dosyasındaki metnin çıkarılmasında beklenmedik durum:
						|%2'"),
					String(FileOrFileVersion), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
				Status(MessageText);
				ExtractionResult = "FailedExtraction";
				ExtractionErrorRecord(FileOrFileVersion, ExtractionResult, MessageText);
			EndTry;
			
		EndDo;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã hoàn tất trích xuất văn bản.
			           |Các tệp đã được xử lý: %1';
			           |ru = 'Извлечение текста завершено.
			           |Обработано файлов: %1';
			           |en = 'Text extraction completed.
			           |Files processed: %1'; fa = 'Text extraction completed.
			           |Files processed: %1';
			           |it = 'L''estrazione del testo è terminata.
			           |File elaborati: %1';
			           |pl = 'Wyodrębnianie tekstu jest zakończone 
			           |Opracowano plików: %1';
			           |tr = 'Metin çıkarımı tamamlandı. 
			           |İşlenen dosya sayısı:%1'"),
			FilesArray.Count());		
		ShowUserNotification(NStr("vi = 'Lấy ra nội dung';
									|ru = 'Извлечение текстов';
									|en = 'Extract text'; fa = 'استخراج متن';
									|it = 'Estrazione testi';
									|pl = 'Pobieranie tekstów';
									|tr = 'Metinlerin çıkarılması'"),, MessageText);
		
	Except
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tình huống bất thường khi trích dẫn văn bản từ tệp ""%1"":
			|%2';
			|ru = 'Непредвиденная ситуация при извлечении текста из файла ""%1"":
			|%2';
			|en = 'An unexpected error occurred while extracting the text from the ""%1"" file:
			|%2'; fa = 'An unexpected error occurred while extracting the text from the ""%1"" file:
			|%2';
			|it = 'Непредвиденная ситуация при извлечении текста из файла ""%1"":
			|%2';
			|pl = 'An unexpected error occurred while extracting the text from the ""%1"" file:
			|%2';
			|tr = '""%1"" dosyasındaki metnin çıkarılmasında beklenmedik durum:
			|%2'"),
			String(FileOrFileVersion), ErrorProcessing.BriefErrorDescription(ErrorInfo()));	
		ShowUserNotification(NStr("vi = 'Lấy ra nội dung';
									|ru = 'Извлечение текстов';
									|en = 'Extract text'; fa = 'استخراج متن';
									|it = 'Estrazione testi';
									|pl = 'Pobieranie tekstów';
									|tr = 'Metinlerin çıkarılması'"),, MessageText);	
		WriteLogEventServer(MessageText);
	EndTry;
	
	UpdateInformationOnFilesWithNonExtractedTextCount();
	
EndProcedure

#EndIf

&AtServerNoContext
Procedure ExtractionErrorRecord(FileOrFileVersion, ExtractionResult, MessageText)
	
	SetPrivilegedMode(True);
	
	FilesOperationsInternal.RecordTextExtractionResult(FileOrFileVersion, ExtractionResult, "");
	
	// Record to the event log.
	WriteLogEventServer(MessageText);
	
EndProcedure


// Parameters:
//   FileCountInBlock - Number
// Returns:
//   Array of Structure:
//   * Ref - DefinedType.AttachedFile
//   * Extension - String
//   * Description - String
//   * Encoding - String 
//
&AtServerNoContext
Function GetFilesForTextExtraction(FileCountInBlock)
	
	Result = New Array;
	
	Query = New Query;
	GetAllFiles = (FileCountInBlock = 0);
	
	Query = New Query;
	Query.Text = FilesOperationsInternal.QueryTextToExtractText(GetAllFiles, True);
	
	Upload0 = Query.Execute().Unload();
	
	For Each String In Upload0 Do
		
		StringStructure = New Structure;
		StringStructure.Insert("Ref",       String.Ref);
		StringStructure.Insert("Extension",   String.Extension);
		StringStructure.Insert("Description", String.Description);
		StringStructure.Insert("Encoding",    String.Encoding);
		
		Result.Add(StringStructure);
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function GetFileNavigationLink(Val FileOrFileVersion, Val UUID)
	
	Return FilesOperationsInternal.FileURL2(FileOrFileVersion,
		UUID);
	
EndFunction

&AtClient
Procedure ExecuteStop()
	DetachIdleHandler("TextExtractionClientHandler");
	DetachIdleHandler("CountdownUpdate");
	Status = "";
	TextExtractionEnabled = False;
EndProcedure

#EndRegion
