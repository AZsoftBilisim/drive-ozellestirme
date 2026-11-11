///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Operation Handlers

// An analog of the "Upload" operation.
Function ExecuteExport(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage)
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	ExchangeMessage = "";
	
	DataExchangeServer.ExportForInfobaseNodeViaString(ExchangePlanName, InfobaseNodeCode, ExchangeMessage);
	
	ExchangeMessageStorage = New ValueStorage(ExchangeMessage, New Deflation(9));
	
	Return "";
	
EndFunction

// An analog of the "Download" operation.
Function ExecuteImport(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage)
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	DataExchangeServer.ImportForInfobaseNodeViaString(ExchangePlanName, InfobaseNodeCode, ExchangeMessageStorage.Get());
	
	Return "";
	
EndFunction

// An analog of the "UploadData" operation.
Function RunDataExport(ExchangePlanName,
								InfobaseNodeCode,
								FileIDAsString,
								TimeConsumingOperation,
								OperationID,
								TimeConsumingOperationAllowed)
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	FileID = New UUID;
	FileIDAsString = String(FileID);
	RunExportDataInClientServerMode(ExchangePlanName, InfobaseNodeCode, FileID, TimeConsumingOperation, OperationID, TimeConsumingOperationAllowed);
	
	Return "";
	
EndFunction

// An analog of the "DownloadData" operation.
Function RunDataImport(ExchangePlanName,
								InfobaseNodeCode,
								FileIDAsString,
								TimeConsumingOperation,
								OperationID,
								TimeConsumingOperationAllowed)
	
	CheckInfobaseLockForUpdate();
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	FileID = New UUID(FileIDAsString);
	RunImportDataInClientServerMode(ExchangePlanName, InfobaseNodeCode, FileID, TimeConsumingOperation, OperationID, TimeConsumingOperationAllowed);
	
	Return "";
	
EndFunction

// An analog of the "GetIBParameters" operation.
Function GetInfobaseParameters(ExchangePlanName, NodeCode, ErrorMessage)
	
	Result = DataExchangeServer.InfoBaseAdmParams(ExchangePlanName, NodeCode, ErrorMessage);
	Return XDTOSerializer.WriteXDTO(Result);
	
EndFunction

// An analog of the "GetIBData" operation.
Function GetInfobaseData(FullTableName)
	
	Return XDTOSerializer.WriteXDTO(DataExchangeServer.CorrespondentData(FullTableName));
	
EndFunction

// An analog of the "GetCommonNodsData" operation.
Function GetCommonNodesData(ExchangePlanName)
	
	SetPrivilegedMode(True);
	
	Return XDTOSerializer.WriteXDTO(DataExchangeServer.DataForThisInfobaseNodeTabularSections(ExchangePlanName));
	
EndFunction

// An analog of the "CreateExchange" operation.
Function CreateDataExchange(ExchangePlanName, ParametersString1, FiltersSettingsXDTO, DefaultValuesXDTO)
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	// Creating an instance of exchange setup wizard data processor.
	DataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard().Create();
	DataExchangeCreationWizard.ExchangePlanName = ExchangePlanName;
	
	Cancel = False;
	
	// Loading wizard parameters from a string to the wizard data processor.
	DataExchangeCreationWizard.ImportWizardParameters(Cancel, ParametersString1);
	
	If Cancel Then
		Message = NStr("vi = 'Khi tạo tùy chỉnh trao đổi trong cơ sở thông tin thứ hai đã xảy ra lỗi: %1';
						|ru = 'При создании настройки обмена во второй информационной базе возникли ошибки: %1';
						|en = 'Errors occurred in the peer infobase during the data exchange setup: %1'; fa = 'Errors occurred in the peer infobase during the data exchange setup: %1';
						|it = 'Durante la creazione delle impostazioni di scambio nella seconda infobase, si sono verificati degli errori: %1';
						|pl = 'Podczas utworzenia ustawień wymiany w drugiej bazie informacyjnej wystąpiły błędy: %1';
						|tr = 'İkinci veritabanında alışveriş ayarları yapılandırılırken hatalar oluştu: %1'");
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, DataExchangeCreationWizard.ErrorMessageString());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , Message);
		
		Raise Message;
	EndIf;
	
	DataExchangeCreationWizard.WizardRunOption = "ContinueDataExchangeSetup";
	DataExchangeCreationWizard.IsDistributedInfobaseSetup = False;
	DataExchangeCreationWizard.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WS;
	DataExchangeCreationWizard.SourceInfobasePrefixIsSet = ValueIsFilled(GetFunctionalOption("InfobasePrefix"));
	
	// Creating an exchange setting.
	DataExchangeCreationWizard.SetUpNewDataExchangeWebService(
											Cancel,
											XDTOSerializer.ReadXDTO(FiltersSettingsXDTO),
											XDTOSerializer.ReadXDTO(DefaultValuesXDTO));
	
	If Cancel Then
		Message = NStr("vi = 'Khi tạo tùy chỉnh trao đổi trong cơ sở thông tin thứ hai đã xảy ra lỗi: %1';
						|ru = 'При создании настройки обмена во второй информационной базе возникли ошибки: %1';
						|en = 'Errors occurred in the peer infobase during the data exchange setup: %1'; fa = 'Errors occurred in the peer infobase during the data exchange setup: %1';
						|it = 'Durante la creazione delle impostazioni di scambio nella seconda infobase, si sono verificati degli errori: %1';
						|pl = 'Podczas utworzenia ustawień wymiany w drugiej bazie informacyjnej wystąpiły błędy: %1';
						|tr = 'İkinci veritabanında alışveriş ayarları yapılandırılırken hatalar oluştu: %1'");
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, DataExchangeCreationWizard.ErrorMessageString());
		
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , Message);
		
		Raise Message;
	EndIf;
	
	Return "";
	
EndFunction

// An analog of the "UpdateExchange" operation.
Function UpdateDataExchangeSettings(ExchangePlanName, NodeCode, DefaultValuesXDTO)
	
	DataExchangeServer.ExternalConnectionUpdateDataExchangeSettings(ExchangePlanName, NodeCode, XDTOSerializer.ReadXDTO(DefaultValuesXDTO));
	
	Return "";
	
EndFunction

// An analog of the "RegisterOnlyCatalogData" operation.
Function RecordOnlyCatalogChanges(ExchangePlanName, NodeCode, TimeConsumingOperation, OperationID)
	
	RegisterDataForInitialExport(ExchangePlanName, NodeCode, TimeConsumingOperation, OperationID, True);
	
	Return "";
	
EndFunction

// An analog of the "RegisterAllDataExceptCatalogs" operation.
Function RecordAllDataChangesButCatalogChanges(ExchangePlanName, NodeCode, TimeConsumingOperation, OperationID)
	
	RegisterDataForInitialExport(ExchangePlanName, NodeCode, TimeConsumingOperation, OperationID, False);
	
	Return "";
	
EndFunction

// An analog of the "GetContinuousOperationStatus" operation.
Function GetTimeConsumingOperationState(OperationID, ErrorMessageString)
	
	BackgroundJobStates = New Map;
	BackgroundJobStates.Insert(BackgroundJobState.Active,           "Active");
	BackgroundJobStates.Insert(BackgroundJobState.Completed,         "Completed");
	BackgroundJobStates.Insert(BackgroundJobState.Failed, "Failed");
	BackgroundJobStates.Insert(BackgroundJobState.Canceled,          "Canceled");
	
	SetPrivilegedMode(True);
	
	BackgroundJob = BackgroundJobs.FindByUUID(New UUID(OperationID));
	
	If BackgroundJob = Undefined Then
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tìm thấy giao dịch kéo dài với tên định danh %1.';
				|ru = 'Не найдено длительной операции с идентификатором %1.';
				|en = 'No long-running operation with ID %1 was found.'; fa = 'No long-running operation with ID %1 was found.';
				|it = 'Non è stata trovata nessuna operazione di lunga durata con l''identificativo %1.';
				|pl = 'Nie znaleziono operacji długotrwałej z identyfikatorem %1';
				|tr = '%1 belirteçli uzun süreli işlemler bulunamadı.'"),
			OperationID);
		Return BackgroundJobStates.Get(BackgroundJobState.Canceled);
	EndIf;
	
	If BackgroundJob.ErrorInfo <> Undefined Then
		
		ErrorMessageString = ErrorProcessing.DetailErrorDescription(BackgroundJob.ErrorInfo);
		
	EndIf;
	
	Return BackgroundJobStates.Get(BackgroundJob.State);
EndFunction

// An analog of the "GetFunctionalOption" operation.
Function GetFunctionalOptionValue(Name)
	
	Return GetFunctionalOption(Name);
	
EndFunction

// An analog of the "PrepareGetFile" operation.
Function PrepareGetFile(FileId, BlockSize, TransferId, PartQuantity)
	
	SetPrivilegedMode(True);
	
	TransferId = New UUID;
	
	SourceFileName1 = DataExchangeServer.GetFileFromStorage(FileId);
	
	TempDirectory = TemporaryExportDirectory(TransferId);
	
	SourceFileNameInTemporaryDirectory = CommonClientServer.GetFullFileName(TempDirectory, "data.zip");
	
	CreateDirectory(TempDirectory);
	
	MoveFile(SourceFileName1, SourceFileNameInTemporaryDirectory);
	
	If BlockSize <> 0 Then
		// Splitting a file into parts
		FilesNames = SplitFile(SourceFileNameInTemporaryDirectory, BlockSize * 1024);
		PartQuantity = FilesNames.Count();
		
		DeleteFiles(SourceFileNameInTemporaryDirectory);
	Else
		PartQuantity = 1;
		MoveFile(SourceFileNameInTemporaryDirectory, SourceFileNameInTemporaryDirectory + ".1");
	EndIf;
	
	Return "";
	
EndFunction

// An analog of the "GetFilePart" operation.
Function GetFilePart(TransferId, PartNumber, PartData)
	
	FilesNames = FindPartFile(TemporaryExportDirectory(TransferId), PartNumber);
	
	If FilesNames.Count() = 0 Then
		
		MessageTemplate = NStr("vi = 'Không tìm thấy phân đoạn %1 của phiên truyền dữ liệu có tên định danh %2';
								|ru = 'Не найден фрагмент %1 сессии передачи с идентификатором %2';
								|en = 'Part %1 of the transfer session with ID %2 is not found'; fa = 'Part %1 of the transfer session with ID %2 is not found';
								|it = 'Frammento %1 della sessione di trasferimento con ID %2 non trovato.';
								|pl = 'Nie znaleziono fragmentu %1 sesji transmisji z identyfikatorem %2';
								|tr = '%2 belirteçli %1 aktarım oturumu kısmı bulunamadı'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, String(PartNumber), String(TransferId));
		Raise(MessageText);
		
	ElsIf FilesNames.Count() > 1 Then
		
		MessageTemplate = NStr("vi = 'Đã tìm thấy nhiều phân đoạn %1 của phiên truyền dữ liệu có tên định danh %2';
								|ru = 'Найдено несколько фрагментов %1 сессии передачи с идентификатором %2';
								|en = 'Multiple parts %1 of the transfer session with ID %2 are not found'; fa = 'Multiple parts %1 of the transfer session with ID %2 are not found';
								|it = 'Sono stati ritrovati alcuni frammenti %1 della sessione di trasferimento con ID%2';
								|pl = 'Znaleziono parę fragmentów %1 sesji transmisji z identyfikatorem %2';
								|tr = '%2 belirteçli bir kaç %1 aktarım oturumu kısmı bulundu'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, String(PartNumber), String(TransferId));
		Raise(MessageText);
		
	EndIf;
	
	PartFileName = FilesNames[0].FullName;
	PartData = New BinaryData(PartFileName);
	
	Return "";
	
EndFunction

// An analog of the "ReleaseFile" operation.
Function ReleaseFile(TransferId)
	
	Try
		DeleteFiles(TemporaryExportDirectory(TransferId));
	Except
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return "";
	
EndFunction

// An analog of the "PutFilePart" operation.
//
// Parameters:
//   TransferId - UUID - data transfer session UUID.
//   PartNumber - Number - the file part number.
//   PartData - BinaryData - the file part details.
//
Function PutFilePart(TransferId, PartNumber, PartData)
	
	TempDirectory = TemporaryExportDirectory(TransferId);
	
	If PartNumber = 1 Then
		
		CreateDirectory(TempDirectory);
		
	EndIf;
	
	FileName = CommonClientServer.GetFullFileName(TempDirectory, GetPartFileName(PartNumber));
	
	PartData.Write(FileName);
	
	Return "";
	
EndFunction

// An analog of the "SaveFileFromParts" operation.
Function SaveFileFromParts(TransferId, PartQuantity, FileId)
	
	SetPrivilegedMode(True);
	
	TempDirectory = TemporaryExportDirectory(TransferId);
	
	PartsFilesToMerge = New Array;
	
	For PartNumber = 1 To PartQuantity Do
		
		FileName = CommonClientServer.GetFullFileName(TempDirectory, GetPartFileName(PartNumber));
		
		If FindFiles(FileName).Count() = 0 Then
			MessageTemplate = NStr("vi = 'Không tìm thấy phân đoạn %1 của phiên truyền có tên định danh %2.
					|Cần chắc chắn rằng, trong tùy chỉnh chương trình có đặt tham số
					|""Thư mục tệp tạm thời dành cho Linux"" và ""Thư mục tệp tạm thời dành cho Windows"".';
					|ru = 'Не найден фрагмент %1 сессии передачи с идентификатором %2.
					|Необходимо убедиться, что в настройках программы заданы параметры
					|""Каталог временных файлов для Linux"" и ""Каталог временных файлов для Windows"".';
					|en = 'Part %1 of the transfer session with ID %2 is not found. 
					|Make sure that the ""Directory of temporary files for Linux""
					| and ""Directory of temporary files for Windows"" parameters are specified in the application settings.'; fa = 'Part %1 of the transfer session with ID %2 is not found. 
					|Make sure that the ""Directory of temporary files for Linux""
					| and ""Directory of temporary files for Windows"" parameters are specified in the application settings.';
					|it = 'Il  frammento %1 della sessione di trasferimento con l''ID non è stato trovato.%2
					| È necessario assicurarsi che le impostazioni del programma specifichino i parametri 
					|""File temporanei per Linux"" e ""File temporanei per Windows"".';
					|pl = 'Nie znaleziono fragment %1 sesji transmisji z identyfikatorem %2.
					|Należy upewnić się, że w opcjach programu ustawiono parametry
					|""Katalog tymczasowych plików dla systemu Linux"" i ""Katalog plików tymczasowych systemu Windows"".';
					|tr = '%2belirteç ile aktarım oturumu %1kısmı bulunamadı. 
					|Uygulama ayarlarında ""Linux için geçici dosya dizini"" ve ""Windows için geçici dosya dizini"" 
					|belirtildiğinden emin olmak gerekir.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, String(PartNumber), String(TransferId));
			Raise(MessageText);
		EndIf;
		
		PartsFilesToMerge.Add(FileName);
		
	EndDo;
	
	ArchiveName = CommonClientServer.GetFullFileName(TempDirectory, "data.zip");
	
	MergeFiles(PartsFilesToMerge, ArchiveName);
	
	Dearchiver = New ZipFileReader(ArchiveName);
	
	If Dearchiver.Items.Count() = 0 Then
		Try
			DeleteFiles(TempDirectory);
		Except
			WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		Raise(NStr("vi = 'Tệp sao lưu không chứa dữ liệu.';
					|ru = 'Файл архива не содержит данных.';
					|en = 'The archive file is empty.'; fa = 'The archive file is empty.';
					|it = 'Il file d''archivio non contiene dati.';
					|pl = 'Plik archiwum nie zawiera danych.';
					|tr = 'Arşiv dosyası veri içermemektedir.'"));
	EndIf;
	
	DumpDirectory = DataExchangeServer.TempFilesStorageDirectory();
	
	ArchiveItem = Dearchiver.Items.Get(0);
	FileName = CommonClientServer.GetFullFileName(DumpDirectory, ArchiveItem.Name);
	
	Dearchiver.Extract(ArchiveItem, DumpDirectory);
	Dearchiver.Close();
	
	FileId = DataExchangeServer.PutFileInStorage(FileName);
	
	Try
		DeleteFiles(TempDirectory);
	Except
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return "";
	
EndFunction

// An analog of the "PutFileIntoStorage" operation.
Function PutFileIntoStorage(FileName, FileId)
	
	SetPrivilegedMode(True);
	
	FileId = DataExchangeServer.PutFileInStorage(FileName);
	
	Return "";
	
EndFunction

// An analog of the "GetFileFromStorage" operation.
Function GetFileFromStorage(FileId)
	
	SetPrivilegedMode(True);
	
	SourceFileName1 = DataExchangeServer.GetFileFromStorage(FileId);
	DestinationFileName = "";
	
	If StrEndsWith(SourceFileName1, ".zip") Then
		ZIPReader = New ZipFileReader(SourceFileName1);
		ZIPReader.Extract(ZIPReader.Items[0], DataExchangeServer.TempFilesStorageDirectory());
		
		DestinationFileName = ZIPReader.Items[0].FullName;
		
		ZIPReader.Close();
		
		DeleteFiles(SourceFileName1);
	EndIf;
	
	File = New File(DestinationFileName);
	
	Return File.Name;
EndFunction

// An analog of the "FileExists" operation.
Function FileExists(FileName)
	
	SetPrivilegedMode(True);
	
	TempFileFullName = CommonClientServer.GetFullFileName(DataExchangeServer.TempFilesStorageDirectory(), FileName);
	
	File = New File(TempFileFullName);
	
	Return File.Exists();
EndFunction

// An analog of the "Ping" operation.
Function Ping()
	// Test connection.
	Return "";
EndFunction

// An analog of the "TestConnection" operation.
Function TestConnection(ExchangePlanName, NodeCode, Result)
	
	// Checking whether a user has rights to perform the data exchange.
	Try
		DataExchangeServer.CheckCanSynchronizeData(True);
	Except
		Result = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	// Checking whether the infobase is locked for update.
	Try
		CheckInfobaseLockForUpdate();
	Except
		Result = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	SetPrivilegedMode(True);
	
	// Checking whether the exchange plan node exists (it might be deleted).
	NodeRef1 = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeCode);
	If NodeRef1 = Undefined
		Or Common.ObjectAttributeValue(NodeRef1, "DeletionMark") Then
		ApplicationPresentation = ?(Common.DataSeparationEnabled(),
			Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
			
		ExchangePlanPresentation1 = Metadata.ExchangePlans[ExchangePlanName].Presentation();
			
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong ""%1"" không tìm thấy tùy chỉnh đồng bộ dữ liệu ""%2"" với tên định danh ""%3"".';
				|ru = 'В ""%1"" не найдена настройка синхронизации данных ""%2"" с идентификатором ""%3"".';
				|en = 'Data synchronization setting ""%2"" with ID %3 is not found in %1.'; fa = 'Data synchronization setting ""%2"" with ID %3 is not found in %1.';
				|it = 'In ""%1"" non è stata trovata l''impostazione di sincronizzazione dei dati ""%2"" con ID ""%3"".';
				|pl = 'W ""%1"" nie znaleziono ustawienia synchronizacji danych ""%2"" z identyfikatorem ""%3"".';
				|tr = '""%1""de ""%3"" belirteçli ""%2"" veri senkronizasyonu ayarları bulunamadı.'"),
			ApplicationPresentation, ExchangePlanPresentation1, NodeCode);
		
		Return False;
	EndIf;
	
	Return True;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Local service procedures and functions.

Procedure CheckInfobaseLockForUpdate()
	
	If ValueIsFilled(InfobaseUpdateInternal.InfobaseLockedForUpdate()) Then
		
		Raise NStr("vi = 'Tạm thời không thể đồng bộ dữ liệu do đang cập nhật ứng dụng trên Internet.';
					|ru = 'Синхронизация данных временно недоступна в связи с обновлением приложения в Интернете.';
					|en = 'Data synchronization is temporarily unavailable due to online application update.'; fa = 'Data synchronization is temporarily unavailable due to online application update.';
					|it = 'La sincronizzazione dei dati non è momentaneamente disponibile a causa dell''aggiornamento dell''app su internet.';
					|pl = 'Synchronizacja danych jest chwilowo niedostępna z powodu aktualizacji aplikacji w Internecie.';
					|tr = 'Uygulamanın çevrimiçi güncellemesi nedeniyle veri senkronizasyonu geçici olarak kullanılamıyor.'");
		
	EndIf;
	
EndProcedure

Procedure RunExportDataInClientServerMode(ExchangePlanName,
														InfobaseNodeCode,
														FileID,
														TimeConsumingOperation,
														OperationID,
														TimeConsumingOperationAllowed)
	
	BackgroundJobKey = ExportImportDataBackgroundJobKey(ExchangePlanName,
		InfobaseNodeCode,
		NStr("vi = 'Kết xuất';
			|ru = 'Выгрузка';
			|en = 'Export'; fa = 'خروج اطلاعات';
			|it = 'Upload';
			|pl = 'Eksportowanie';
			|tr = 'Dışa aktar'"));
	
	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise NStr("vi = 'Đang thực hiện đồng bộ dữ liệu.';
					|ru = 'Синхронизация данных уже выполняется.';
					|en = 'Data synchronization is already running.'; fa = 'Data synchronization is already running.';
					|it = 'Sincronizzazione dati già eseguita';
					|pl = 'Synchronizacja danych jest już w toku.';
					|tr = 'Verilerin senkronizasyonu zaten yürütülüyor.'");
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ExchangePlanName", ExchangePlanName);
	ProcedureParameters.Insert("InfobaseNodeCode", InfobaseNodeCode);
	ProcedureParameters.Insert("FileID", FileID);
	ProcedureParameters.Insert("UseCompression", True);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kết xuất dữ liệu thông qua Web-service.';
														|ru = 'Выгрузка данных через веб-сервис.';
														|en = 'Export data via web service.'; fa = 'Export data via web service.';
														|it = 'Caricamento dati tramite web-service.';
														|pl = 'Wyeksportowanie danych za pośrednictwem serwisu internetowego.';
														|tr = 'Web servis üzerinden verilerin dışa aktarılması.'");
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1 = Not TimeConsumingOperationAllowed;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeWebService.ExportToFileTransferServiceForInfobaseNode",
		ProcedureParameters,
		ExecutionParameters);
		
	If BackgroundJob.Status = "Running" Then
		OperationID = String(BackgroundJob.JobID);
		TimeConsumingOperation = True;
		Return;
	ElsIf BackgroundJob.Status = "Completed2" Then
		TimeConsumingOperation = False;
		Return;
	Else
		Message = NStr("vi = 'Lỗi khi kết xuất dữ liệu thông qua Web-service.';
						|ru = 'Ошибка при выгрузке данных через веб-сервис.';
						|en = 'Error exporting data via web service.'; fa = 'Error exporting data via web service.';
						|it = 'Errore durante il caricamento dati tramite web-service.';
						|pl = 'Błąd podczas wyeksportowania danych za pośrednictwem serwisu internetowego.';
						|tr = 'Web servis üzerinden verilerin dışa aktarılması sırasında hata.'");
		If ValueIsFilled(BackgroundJob.DetailErrorDescription) Then
			Message = BackgroundJob.DetailErrorDescription;
		EndIf;
		
		WriteLogEvent(DataExchangeServer.ExportDataToFilesTransferServiceEventLogEvent(),
			EventLogLevel.Error, , , Message);
		
		Raise Message;
	EndIf;
	
EndProcedure

Procedure RunImportDataInClientServerMode(ExchangePlanName,
													InfobaseNodeCode,
													FileID,
													TimeConsumingOperation,
													OperationID,
													TimeConsumingOperationAllowed)
	
													
	BackgroundJobKey = ExportImportDataBackgroundJobKey(ExchangePlanName,
		InfobaseNodeCode,
		NStr("vi = 'Kết nhập';
			|ru = 'Загрузка';
			|en = 'Import'; fa = 'ورود اطلاعات';
			|it = 'Scaricamento';
			|pl = 'Pobieranie';
			|tr = 'İçe aktar'"));
	
	If DataExchangeServer.HasActiveBackgroundJobs(BackgroundJobKey) Then
		Raise NStr("vi = 'Đang thực hiện đồng bộ dữ liệu.';
					|ru = 'Синхронизация данных уже выполняется.';
					|en = 'Data synchronization is already running.'; fa = 'Data synchronization is already running.';
					|it = 'Sincronizzazione dati già eseguita';
					|pl = 'Synchronizacja danych jest już w toku.';
					|tr = 'Verilerin senkronizasyonu zaten yürütülüyor.'");
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ExchangePlanName", ExchangePlanName);
	ProcedureParameters.Insert("InfobaseNodeCode", InfobaseNodeCode);
	ProcedureParameters.Insert("FileID", FileID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kết nhập dữ liệu thông qua Web-service.';
														|ru = 'Загрузка данных через веб-сервис.';
														|en = 'Import data via web service.'; fa = 'Import data via web service.';
														|it = 'Caricamento dati tramite web-service';
														|pl = 'Pobieranie danych za pośrednictwem serwisu internetowego.';
														|tr = 'Web-istemci üzerinden verilerin yüklemesi.'");
	ExecutionParameters.BackgroundJobKey = BackgroundJobKey;
	ExecutionParameters.RunNotInBackground1 = Not TimeConsumingOperationAllowed;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeWebService.ImportFromFileTransferServiceForInfobaseNode",
		ProcedureParameters,
		ExecutionParameters);
		
	If BackgroundJob.Status = "Running" Then
		OperationID = String(BackgroundJob.JobID);
		TimeConsumingOperation = True;
		Return;
	ElsIf BackgroundJob.Status = "Completed2" Then
		TimeConsumingOperation = False;
		Return;
	Else
		
		Message = NStr("vi = 'Lỗi khi kết nhập dữ liệu thông qua Web-service.';
						|ru = 'Ошибка при загрузке данных через веб-сервис.';
						|en = 'Error importing data via web service.'; fa = 'Error importing data via web service.';
						|it = 'Errore durante il caricamento dati tramite web-service.';
						|pl = 'Błąd podczas pobierania danych za pośrednictwem serwisu internetowego.';
						|tr = 'Web-istemci üzerinden verilerin yükleme hatası.'");
		If ValueIsFilled(BackgroundJob.DetailErrorDescription) Then
			Message = BackgroundJob.DetailErrorDescription;
		EndIf;
		
		WriteLogEvent(DataExchangeServer.ImportDataFromFilesTransferServiceEventLogEvent(),
			EventLogLevel.Error, , , Message);
		
		Raise Message;
	EndIf;
	
EndProcedure

Function ExportImportDataBackgroundJobKey(ExchangePlan, NodeCode, Action)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Sơ đồ trao đổi:%1 Mã nút:%2 Thao tác:%3';
			|ru = 'ПланОбмена:%1 КодУзла:%2 Действие:%3';
			|en = 'ExchangePlan:%1 NodeCode:%2 Action:%3'; fa = 'ExchangePlan:%1 NodeCode:%2 Action:%3';
			|it = 'PianoScambio: %1 CodiceNodo:%2 Attività: %3';
			|pl = 'PlanWymiany:%1 KodWęzła:%2 Działanie:%3';
			|tr = 'ПланОбмена:%1 КодУзла:%2 İşlem:%3'"),
		ExchangePlan,
		NodeCode,
		Action);
	
EndFunction

Procedure RegisterDataForInitialExport(Val ExchangePlanName, Val NodeCode, TimeConsumingOperation, OperationID, CatalogsOnly)
	
	SetPrivilegedMode(True);
	
	InfobaseNode = DataExchangeServer.ExchangePlanNodeByCode(ExchangePlanName, NodeCode);
	
	If Not ValueIsFilled(InfobaseNode) Then
		Message = NStr("vi = 'Không tìm thấy nút sơ đồ trao đổi; tên sơ đồ trao đổi %1; mã nút %2';
						|ru = 'Не найден узел плана обмена; имя плана обмена %1; код узла %2';
						|en = 'Node not found. Exchange plan: %1. Node ID: %2'; fa = 'Node not found. Exchange plan: %1. Node ID: %2';
						|it = 'Non è stato trovato un nodo del piano di scambio; nome del piano di scambio %1; codice del nodo %2';
						|pl = 'Nie znaleziono węzła planu wymiany; nazwa planu wymiany %1; kod węzła %2';
						|tr = 'Değişim plan düğümü bulunamadı; değişim planı adı%1; düğüm kodu %2'");
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, ExchangePlanName, NodeCode);
		Raise Message;
	EndIf;
	
	If Common.FileInfobase() Then
		
		If CatalogsOnly Then
			
			DataExchangeServer.RegisterOnlyCatalogsForInitialExport(InfobaseNode);
			
		Else
			
			DataExchangeServer.RegisterAllDataExceptCatalogsForInitialExport(InfobaseNode);
			
		EndIf;
		
	Else
		
		If CatalogsOnly Then
			MethodName = "DataExchangeServer.RegisterCatalogsOnlyForInitialBackgroundExport";
			JobDescription = NStr("vi = 'Ghi nhận thay đổi danh mục để kết xuất ban đầu.';
									|ru = 'Регистрация изменений справочников для начальной выгрузки.';
									|en = 'Register catalog changes for initial export.'; fa = 'Register catalog changes for initial export.';
									|it = 'Registrazione delle modifiche nei registri di riferimento per lo scarico iniziale.';
									|pl = 'Rejestracja zmian katalogów do początkowego wyeksportowania.';
									|tr = 'İlk aktarım için katalog değişikliklerinin kaydı.'");
		Else
			MethodName = "DataExchangeServer.RegisterAllDataExceptCatalogsForInitialBackgroundExport";
			JobDescription = NStr("vi = 'Ghi nhận thay đổi tất cả dữ liệu ngoại trừ danh mục để kết xuất ban đầu.';
									|ru = 'Регистрация изменений всех данных кроме справочников для начальной выгрузки.';
									|en = 'Register all data changes except for catalogs for initial export.'; fa = 'Register all data changes except for catalogs for initial export.';
									|it = 'Registrazione delle modifiche di tutti i dati tranne dei registri di riferimento per lo scarico iniziale.';
									|pl = 'Rejestracja zmian wszystkich danych z wyjątkiem katalogów dla początkowego wyeksportowania.';
									|tr = 'İlk aktarım için katalog dışında tüm veri değişikliklerinin kaydı.'");
		EndIf;
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("InfobaseNode", InfobaseNode);
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
		ExecutionParameters.BackgroundJobDescription = JobDescription;
		
		BackgroundJob = TimeConsumingOperations.ExecuteInBackground(MethodName, ProcedureParameters, ExecutionParameters);
			
		If BackgroundJob.Status = "Running" Then
			OperationID = String(BackgroundJob.JobID);
			TimeConsumingOperation = True;
		ElsIf BackgroundJob.Status = "Completed2" Then
			TimeConsumingOperation = False;
		Else
			If ValueIsFilled(BackgroundJob.DetailErrorDescription) Then
				Raise BackgroundJob.DetailErrorDescription;
			EndIf;
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi khi thực hiện nhiệm vụ nền: %1';
					|ru = 'Ошибка при выполнении фонового задания: %1';
					|en = 'Background job error: %1.'; fa = 'Background job error: %1.';
					|it = 'Errore durante l''esecuzione di un compito in background: %1';
					|pl = 'Błąd podczas wykonywania pracy w tle: %1';
					|tr = 'Arka plan görevi yürütülürken hata: %1'"),
				JobDescription);
		EndIf;
		
	EndIf;
	
EndProcedure

Function GetPartFileName(PartNumber)
	
	Result = "data.zip.[n]";
	
	Return StrReplace(Result, "[n]", Format(PartNumber, "NG=0"));
EndFunction

Function TemporaryExportDirectory(Val SessionID)
	
	SetPrivilegedMode(True);
	
	TempDirectory = "{SessionID}";
	TempDirectory = StrReplace(TempDirectory, "SessionID", String(SessionID));
	
	Result = CommonClientServer.GetFullFileName(DataExchangeServer.TempFilesStorageDirectory(), TempDirectory);
	
	Return Result;
EndFunction

Function FindPartFile(Val Directory, Val FileNumber)
	
	For DigitsCount = NumberDigitsCount(FileNumber) To 5 Do
		
		FormatString = StringFunctionsClientServer.SubstituteParametersToString("ND=%1; NLZ=; NG=0", String(DigitsCount));
		
		FileName = StringFunctionsClientServer.SubstituteParametersToString("data.zip.%1", Format(FileNumber, FormatString));
		
		FilesNames = FindFiles(Directory, FileName);
		
		If FilesNames.Count() > 0 Then
			
			Return FilesNames;
			
		EndIf;
		
	EndDo;
	
	Return New Array;
EndFunction

Function NumberDigitsCount(Val Number)
	
	Return StrLen(Format(Number, "NFD=0; NG=0"));
	
EndFunction

#EndRegion
