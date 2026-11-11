///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns an error flag at start:
// 1) Exchange message import error:
// - metadata object ID import error,
// - object ID verification error,
// - error of importing exchange message before infobase update,
// - error of importing exchange message before infobase update when infobase version is not changed;
// 2) Database update error after successful exchange message import.
// 
// Returns:
//  Boolean - Value of the constant "RetryDataExchangeMessageImportBeforeStart".
// 
Function RetryDataExchangeMessageImportBeforeStart() Export

	SetPrivilegedMode(True);

	Return Constants.RetryDataExchangeMessageImportBeforeStart.Get();

EndFunction

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(ParameterName, SpecifiedParameters) Export
	
	// Session parameters must be initialized without using application parameters.

	If ParameterName = "DataExchangeMessageImportModeBeforeStart" Then
		SessionParameters.DataExchangeMessageImportModeBeforeStart = New FixedStructure(New Structure);
		SpecifiedParameters.Add("DataExchangeMessageImportModeBeforeStart");
		Return;
	EndIf;

	If Common.SeparatedDataUsageAvailable() Then
		
		// Procedure for updating cached values and session parameters.
		RefreshObjectsRegistrationMechanismCache();
		
		// Register the names of the parameters set during the runtime of
		// "DataExchangeServerCall.RefreshObjectsRegistrationMechanismCache".
		SpecifiedParameters.Add("ObjectsRegistrationRules");
		SpecifiedParameters.Add("ORMCachedValuesRefreshDate");
		
		SessionParameters.DataSynchronizationPasswords = New ValueStorage(New Map);
		SpecifiedParameters.Add("DataSynchronizationPasswords");

		SessionParameters.PriorityExchangeData = New FixedArray(New Array);
		SpecifiedParameters.Add("PriorityExchangeData");

		SessionParameters.DataSynchronizationSessionParameters = New ValueStorage(New Map);
		SpecifiedParameters.Add("DataSynchronizationSessionParameters");

		CheckStructure =New Structure;
		CheckStructure.Insert("CheckVersionDifference", False);
		CheckStructure.Insert("HasError", False);
		CheckStructure.Insert("ErrorText", "");

		SessionParameters.VersionDifferenceErrorOnGetData = New FixedStructure(CheckStructure);
		SpecifiedParameters.Add("VersionDifferenceErrorOnGetData");

	Else
		
		SessionParameters.DataSynchronizationPasswords = New ValueStorage(New Map);
		SpecifiedParameters.Add("DataSynchronizationPasswords");

		SessionParameters.DataSynchronizationSessionParameters = New ValueStorage(New Map);
		SpecifiedParameters.Add("DataSynchronizationSessionParameters");
	EndIf;

EndProcedure

// Checks whether object registration cache is up-to-date.
// If the cached data is obsolete, cache gets initialized with new values.
//
// Parameters:
//  No.
// 
Procedure CheckObjectsRegistrationMechanismCache() Export

	SetPrivilegedMode(True);

	If Common.SeparatedDataUsageAvailable() Then

		RelevantDate = GetFunctionalOption("ORMCachedValuesLatestUpdate");

		If SessionParameters.ORMCachedValuesRefreshDate <> RelevantDate Then

			RefreshObjectsRegistrationMechanismCache();

		EndIf;

	EndIf;

EndProcedure

// Sets (or updates) cached values and session parameters for data exchange subsystem.
//
// The session parameters are
//   ObjectsRegistrationRules - ValueStorage - A binary value table of object registration rules.
//                                                    SelectiveObjectsRegistrationRules -
//   ORMCachedValuesRefreshDate - Date (date and time) - Date of the most recent cache for the "Data exchange" subsystem.
//                                                                         
//
Procedure RefreshObjectsRegistrationMechanismCache() Export
	
	SetPrivilegedMode(True);
	
	RefreshReusableValues();
	If DataExchangeCached.ExchangePlansInUse().Count() > 0 Then
		
		SessionParameters.ObjectsRegistrationRules = New ValueStorage(DataExchangeServer.GetObjectsRegistrationRules());
		
	Else
		
		SessionParameters.ObjectsRegistrationRules = New ValueStorage(DataExchangeServer.ObjectsRegistrationRulesTableInitialization());
		
	EndIf;
	
	// Getting date value for checking whether cached data is up-to-date.
	SessionParameters.ORMCachedValuesRefreshDate = 
		GetFunctionalOption("ORMCachedValuesLatestUpdate");

EndProcedure

// Updates the "ORMCachedValuesRefreshDate" constant value.
// 
// See the procedure "DataExchangeServerCall.ResetObjectsRegistrationMechanismCache".
//
Procedure ResetObjectsRegistrationMechanismCache() Export

	If Common.SeparatedDataUsageAvailable() Then

		SetPrivilegedMode(True);
		// Write the server date and time in UTC using "CurrentUniversalDate".
		// (Do not use "CurrentSessionDate".)
		// The server time in UTC is used as a uniqueness key in the ORM cache.
		// 
		Constants.ORMCachedValuesRefreshDate.Set(CurrentUniversalDate());

	EndIf;

EndProcedure

// Returns the list of priority exchange data items.
//
// Returns:
//  Array - a collection of references to priority exchange data items.
//
Function PriorityExchangeData() Export

	SetPrivilegedMode(True);

	Result = New Array;

	For Each Item In SessionParameters.PriorityExchangeData Do

		Result.Add(Item);

	EndDo;

	Return Result;
EndFunction

// Clears the list of priority exchange data items.
//
Procedure ClearPriorityExchangeData() Export

	SetPrivilegedMode(True);

	SessionParameters.PriorityExchangeData = New FixedArray(New Array);

EndProcedure

// Adds the passed value to the list of priority exchange data items.
//
Procedure SupplementPriorityExchangeData(Val Data) Export

	Result = PriorityExchangeData();

	Result.Add(Data);

	SetPrivilegedMode(True);

	SessionParameters.PriorityExchangeData = New FixedArray(Result);

EndProcedure

// Returns the flag that shows whether application parameters are imported into the infobase from the exchange message.
// This function is used in DIB data exchange when data is imported to a subordinate node.
// 
// Parameters:
//  Property - String - The property of the session parameter "DataExchangeMessageImportModeBeforeStart"
// 
// Returns:
//  Boolean
//
Function DataExchangeMessageImportModeBeforeStart(Property) Export

	SetPrivilegedMode(True);

	Return SessionParameters.DataExchangeMessageImportModeBeforeStart.Property(Property);

EndFunction

// Returns a flag that shows whether an exchange plan is used in data exchange.
// If an exchange plan contains at least one node apart from the predefined one,
// it is considered being used in data exchange.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//
// Returns:
//  Boolean - True if the exchange plan is being used, False if it is not being used.
//
Function DataExchangeEnabled(Val ExchangePlanName, Val Sender) Export

	SetPrivilegedMode(True);

	Return DataExchangeCached.DataExchangeEnabled(ExchangePlanName, Sender);
EndFunction

// Returns the value of session parameter ObjectsRegistrationRules obtained in privileged mode.
//
// Returns:
//  ValueStorage - the value of the ObjectsRegistrationRules session parameter.
//
Function SessionParametersObjectsRegistrationRules() Export

	SetPrivilegedMode(True);

	Return SessionParameters.ObjectsRegistrationRules;

EndFunction

// Returns the flag that indicates whether data changes are registered for the specified recipient.
//
// Returns:
//  Boolean - True if there is registered data, False - if there is none.
//
Function ChangesRegistered(Val Recipient) Export

	QueryText =
	"SELECT TOP 1 1
	|FROM
	|	&ChangeTableName AS ChangesTable
	|WHERE
	|	ChangesTable.Node = &Node";

	Query = New Query;
	Query.SetParameter("Node", Recipient);

	SetPrivilegedMode(True);

	TemplateRow = "%1.Changes";

	ExchangePlanContent = Metadata.ExchangePlans[DataExchangeCached.GetExchangePlanName(Recipient)].Content;
	For Each CompositionItem In ExchangePlanContent Do

		ChangeTableName = StrTemplate(TemplateRow, CompositionItem.Metadata.FullName());

		Query.Text = StrReplace(QueryText, "&ChangeTableName", ChangeTableName);
		QueryResult = Query.Execute();

		If Not QueryResult.IsEmpty() Then
			Return True;
		EndIf;

	EndDo;

	Return False;
EndFunction

// For internal use only.
// 
// Parameters:
//  FileID - UUID - data transfer session UUID.
//  FilePartToImportNumber - Number - the file part number.
//  FilePartToImport - BinaryData - the file part details.
//  ErrorMessage - String - operation error details.
// 
// Returns:
//  String - Always an empty string
//
Function ImportFilePart(FileID, FilePartToImportNumber, FilePartToImport, ErrorMessage) Export

	ErrorMessage = "";

	If Not ValueIsFilled(FileID) Then
		ErrorMessage = NStr("vi = 'Chưa chỉ ra tên định danh của tệp được kết nhập. Không thể tiếp tục thực hiện phương thức.
								|Hãy chỉ định tên đơn trị đối với tệp được kết nhập.';
								|ru = 'Не указан идентификатор загружаемого файла. Дальнейшее выполнение метода невозможно.
								|Назначьте уникальный идентификатор для загружаемого файла.';
								|en = 'Cannot execute the method. The ID of the file to be imported is not specified.
								|Specify a UUID for the file to be imported.'; fa = 'Cannot execute the method. The ID of the file to be imported is not specified.
								|Specify a UUID for the file to be imported.';
								|it = 'Non è indicato l''ID del file scaricabile. Impossibile proseguire con l''esecuzione del metodo.
								|Assegnare ID univoco per il file scaricabile.';
								|pl = 'Nie jest wskazany identyfikator pobieranego pliku. Dalsze wykonanie metody jest niemożliwe.
								|Wyznacz unikalny identyfikator dla pobieranego pliku.';
								|tr = 'Yüklenen dosya kimliği belirtilmedi. Yönteme devam edilemez.
								|Yüklenen dosya için benzersiz kimlik belirleyin.'");
		Raise (ErrorMessage);
	EndIf;

	If Not ValueIsFilled(FilePartToImport) And TypeOf(FilePartToImport) <> Type("BinaryData") Then
		ErrorMessage = NStr(
			"vi = 'Không thể thực hiện phương thức, bởi vì dữ liệu truyền đi không tương ứng với kiểu để nhận dữ liệu.';
			|ru = 'Метод не может быть выполнен, т.к. переданные данные не соответствуют типу для получения данных.';
			|en = 'Cannot execute the method. The passed data type does not match the expected type.'; fa = 'Cannot execute the method. The passed data type does not match the expected type.';
			|it = 'Il metodo non può essere eseguito perché i dati scambiati non corrispondono al tipo per la ricezione dei dati.';
			|pl = 'Metoda nie może być wykonana, ponieważ przekazane dane nie odpowiadają typowi do otrzymania danych.';
			|tr = 'Yöntem yürütülemez, çünkü aktarılan veriler veri almak için türe uygun değildir.'");
		Raise (ErrorMessage);
	EndIf;

	If Not ValueIsFilled(FilePartToImportNumber) Or FilePartToImportNumber = 0 Then
		FilePartToImportNumber = 1;
	EndIf;

	TempFilesDir = TemporaryExportDirectory(FileID);

	Directory = New File(TempFilesDir);
	If Not Directory.Exists() Then
		CreateDirectory(TempFilesDir);
	EndIf;

	FileName = CommonClientServer.GetFullFileName(TempFilesDir, GetFilePartName(
		FilePartToImportNumber));
	FilePartToImport.Write(FileName);

	Return "";

EndFunction

Function ExportFilePart(FileID, FilePartToExportNumber, ErrorMessage) Export

	ErrorMessage      = "";
	FilePartName          = "";
	TempFilesDir = TemporaryExportDirectory(FileID);

	For DigitsCount = StrLen(Format(FilePartToExportNumber, "NFD=0; NG=0")) To 5 Do

		FormatString = StringFunctionsClientServer.SubstituteParametersToString("ND=%1; NLZ=; NG=0", String(
			DigitsCount));

		FileName = StringFunctionsClientServer.SubstituteParametersToString("%1.zip.%2", FileID, Format(
			FilePartToExportNumber, FormatString));

		FilesNames = FindFiles(TempFilesDir, FileName);

		If FilesNames.Count() > 0 Then

			FilePartName = CommonClientServer.GetFullFileName(TempFilesDir, FileName);
			Break;

		EndIf;

	EndDo;

	FilePart = New File(FilePartName);

	If FilePart.Exists() Then
		Return New BinaryData(FilePartName);
	Else
		ErrorMessage = NStr("vi = 'Không tìm thấy một phần tệp có số đã chỉ ra.';
							|ru = 'Часть файла с указанным номером не найдена.';
							|en = 'The file part with the ID is not found.'; fa = 'The file part with the ID is not found.';
							|it = 'La parte del file con il numero specificato non è stata trovata.';
							|pl = 'Część pliku ze wskazanym numerem nie jest wyszukana.';
							|tr = 'Belirtilen numaraya sahip dosyanın bir kısmı bulunamadı.'");
	EndIf;

EndFunction

Function PrepareFileForImport(FileID, ErrorMessage) Export

	SetPrivilegedMode(True);

	TempStorageFileID = "";

	TempFilesDir = TemporaryExportDirectory(FileID);
	ArchiveName              = CommonClientServer.GetFullFileName(TempFilesDir, "datafile.zip");

	ReceivedFilesArray = FindFiles(TempFilesDir, "data.zip.*");

	If ReceivedFilesArray.Count() > 0 Then

		FilesToMerge = New Array;
		FilePartName = CommonClientServer.GetFullFileName(TempFilesDir, "data.zip.%1");

		For PartNumber = 1 To ReceivedFilesArray.Count() Do
			FilesToMerge.Add(StringFunctionsClientServer.SubstituteParametersToString(FilePartName,
				PartNumber));
		EndDo;

	Else
		MessageTemplate = NStr("vi = 'Không tìm thấy một phân đoạn nào của phiên truyền đi có tên định danh %1.
							|Hãy chắc chắn rằng, trong tùy chỉnh chương trình có đặt tham số
							|""Thư mục tệp tạm thời dành cho Linux"" và ""Thư mục tệp tạm thời dành cho Windows"".';
							|ru = 'Не найден ни один фрагмент сессии передачи с идентификатором %1.
							|Убедитесь, что в настройках программы заданы параметры
							|""Каталог временных файлов для Linux"" и ""Каталог временных файлов для Windows"".';
							|en = 'No parts of the transfer session with the %1 ID are found.
							|Ensure that the ""Linux temporary files directory"" and
							|""Windows temporary files directory"" parameters are specified in the application settings.'; fa = 'No parts of the transfer session with the %1 ID are found.
							|Ensure that the ""Linux temporary files directory"" and
							|""Windows temporary files directory"" parameters are specified in the application settings.';
							|it = 'Non è stato trovato alcun frammento di sessione di trasferimento con ID %1.
							|Verificare che nelle impostazioni del programma siano indicati i parametri
							|""Directory file temporanei per Linux"" e ""Directory file temporanei per Windows"".';
							|pl = 'Nie znaleziono żadnego fragmentu sesji przekazania z identyfikatorem %1.
							|Upewnij się, że w ustawieniach programu są określone parametry
							|""Katalog tymczasowych plików dla Linux"" i ""Katalog tymczasowych plików dla Windows"".';
							|tr = '%1Kimlik ile transfer oturumu parçası bulunamadı. 
							|Uygulama ayarlarında ""Linux için geçici dosya dizini"" ve ""Windows için geçici dosya dizini"" 
							|belirtildiğinden emin olun.'");
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, String(
			FileID));
		Raise (ErrorMessage);
	EndIf;

	Try
		MergeFiles(FilesToMerge, ArchiveName);
	Except
		ErrorMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Raise (ErrorMessage);
	EndTry;
	
	// Unpack.
	Dearchiver = New ZipFileReader(ArchiveName);

	If Dearchiver.Items.Count() = 0 Then

		Try
			DeleteFiles(TempFilesDir);
		Except
			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
				EventLogLevel.Error, , , ErrorMessage);
			Raise (ErrorMessage);
		EndTry;

		ErrorMessage = NStr("vi = 'Tệp nén không chứa dữ liệu.';
							|ru = 'Файл архива не содержит данных.';
							|en = 'The archive file is empty.'; fa = 'The archive file is empty.';
							|it = 'Il file d''archivio non contiene dati.';
							|pl = 'Plik archiwum nie zawiera danych.';
							|tr = 'Arşiv dosyası veri içermemektedir.'");
		Raise (ErrorMessage);

	EndIf;

	ArchiveItem = Dearchiver.Items.Get(0);
	FileName = CommonClientServer.GetFullFileName(TempFilesDir, ArchiveItem.Name);

	Dearchiver.Extract(ArchiveItem, TempFilesDir);
	Dearchiver.Close();
	
	// Placing the file to the file temporary storage directory.
	ImportDirectory          = DataExchangeServer.TempFilesStorageDirectory();
	NameOfFileWithData         = CommonClientServer.GetNameWithExtension(FileID,
		CommonClientServer.GetFileNameExtension(FileName));
	FileNameInImportDirectory = CommonClientServer.GetFullFileName(ImportDirectory, NameOfFileWithData);

	Try
		MoveFile(FileName, FileNameInImportDirectory);
	Except
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessage);
		Raise (ErrorMessage);
	EndTry;

	TempStorageFileID = DataExchangeServer.PutFileInStorage(FileNameInImportDirectory);
	
	// Delete temporary files.
	Try
		DeleteFiles(TempFilesDir);
	Except
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessage);
		Raise (ErrorMessage);
	EndTry;

	Return TempStorageFileID;

EndFunction

Procedure PrepareDataForExportFromInfobase(ProcedureParameters, StorageAddress) Export

	WebServiceParameters = ProcedureParameters["WebServiceParameters"];
	ErrorMessage   = ProcedureParameters["ErrorMessage"];

	SetPrivilegedMode(True);

	ExchangeComponents = ExchangeComponents("Send", WebServiceParameters);
	FileName         = String(New UUID) + ".xml";

	TempFilesDir = DataExchangeServer.TempFilesStorageDirectory();
	FullFileName         = CommonClientServer.GetFullFileName(
		TempFilesDir, FileName);
		
	// Open an exchange file.
	DataExchangeXDTOServer.OpenExportFile(ExchangeComponents, FullFileName);

	If ExchangeComponents.ErrorFlag Then
		ExchangeComponents.ExchangeFile = Undefined;

		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);

		Raise ExchangeComponents.ErrorMessageString;
	EndIf;

	ExchangeSettingsStructure = ExchangeSettingsStructure(ExchangeComponents, Enums.ActionsOnExchange.DataExport);
	
	// Export data.
	Try
		DataExchangeXDTOServer.ExecuteDataExport(ExchangeComponents);
	Except

		If ExchangeComponents.IsExchangeViaExchangePlan Then
			UnlockDataForEdit(ExchangeComponents.CorrespondentNode);
		EndIf;

		Info = ErrorInfo();
		ErrorCode = New Structure("BriefErrorDescription, DetailErrorDescription",
			ErrorProcessing.BriefErrorDescription(Info), ErrorProcessing.DetailErrorDescription(Info));

		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, ErrorCode);
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);

		ExchangeComponents.ExchangeFile = Undefined;

		Raise ErrorCode.BriefErrorDescription;
	EndTry;

	ExchangeComponents.ExchangeFile.Close();

	WriteExchangeFinish(ExchangeSettingsStructure, ExchangeComponents);

	If ExchangeComponents.ErrorFlag Then

		ErrorMessage = ExchangeComponents.ErrorMessageString;
		Raise ErrorMessage;

	Else
		
		// Putting a file to a temporary storage.
		TempStorageFileID = String(DataExchangeServer.PutFileInStorage(FullFileName));
		
		// Creating a temporary directory for storing data file parts.
		TempDirectory                     = TemporaryExportDirectory(
			TempStorageFileID);
		SharedFileName               = CommonClientServer.GetFullFileName(
			TempDirectory, TempStorageFileID + ?(WebServiceParameters.FilePartSize > 0,
			".zip", ".zip.1"));
		SourceFileNameInTemporaryDirectory = CommonClientServer.GetFullFileName(
			TempDirectory, "data.xml");

		CreateDirectory(TempDirectory);
		CopyFile(FullFileName, SourceFileNameInTemporaryDirectory);
		
		// Archive the file.
		Archiver = New ZipFileWriter(SharedFileName);
		Archiver.Add(SourceFileNameInTemporaryDirectory);
		Archiver.Write();

		If WebServiceParameters.FilePartSize > 0 Then
			// Splitting a file into parts.
			FilesNames = SplitFile(SharedFileName, WebServiceParameters.FilePartSize * 1024);
		Else
			FilesNames = New Array;
			FilesNames.Add(SharedFileName);
		EndIf;

		ReturnValue = "{WEBService}$%1$%2";
		ReturnValue = StringFunctionsClientServer.SubstituteParametersToString(ReturnValue,
			FilesNames.Count(), TempStorageFileID);

		Message = New UserMessage;
		Message.Text = ReturnValue;
		Message.Message();

	EndIf;

EndProcedure

Procedure ImportXDTODateToInfobase(ProcedureParameters, StorageAddress) Export

	WebServiceParameters = ProcedureParameters["WebServiceParameters"];
	ErrorMessage   = ProcedureParameters["ErrorMessage"];

	SetPrivilegedMode(True);

	Cancel = False;
	ExchangeComponents = ExchangeComponents("Receive", WebServiceParameters, Cancel);

	If ExchangeComponents.ErrorFlag Then
		ErrorMessage = ExchangeComponents.ErrorMessageString;
		Raise ErrorMessage;
	EndIf;

	ExchangeSettingsStructure = ExchangeSettingsStructure(ExchangeComponents, Enums.ActionsOnExchange.DataImport);

	If Not Cancel Then
		DisableAccessKeysUpdate(True);
		Try
			DataExchangeXDTOServer.RunReadingData(ExchangeComponents);
			DisableAccessKeysUpdate(False);
		Except
			DisableAccessKeysUpdate(False);
			Information = ErrorInfo();
			ErrorMessage = NStr("vi = 'Lỗi khi kết nhập dữ liệu: %1';
								|ru = 'Ошибка при загрузке данных: %1';
								|en = 'Data import error: %1'; fa = 'Data import error: %1';
								|it = 'Errore durante il download dei dati: %1';
								|pl = 'Błąd podczas pobierania danych: %1';
								|tr = 'Veri içe aktarılırken bir hata oluştu: %1'");
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorMessage, ErrorProcessing.DetailErrorDescription(Information));
			DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, ErrorMessage, , , , , True);
			ExchangeComponents.ErrorFlag = True;
		EndTry;

		DisableAccessKeysUpdate(True);
		Try
			DataExchangeXDTOServer.DeleteTempObjectsCreatedByRefs(ExchangeComponents);
			DisableAccessKeysUpdate(False);
		Except
			DisableAccessKeysUpdate(False);
			Information = ErrorInfo();
			ErrorMessage = NStr("vi = 'Lỗi khi xóa các tệp tạm thời đã tạo theo tham chiếu: %1';
								|ru = 'Ошибка при удалении временных объектов, созданных по ссылкам: %1';
								|en = 'Cannot delete temporary objects created by references: %1'; fa = 'Cannot delete temporary objects created by references: %1';
								|it = 'Errore durante l''eliminazione di oggetti temporanei creati dai link: %1';
								|pl = 'Błąd podczas usuwania tymczasowych obiektów, utworzonych wg odnośników: %1';
								|tr = 'Referanslara göre oluşturulan geçici nesneler kaldırılırken bir hata oluştu: %1'");
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorMessage, ErrorProcessing.DetailErrorDescription(Information));
			DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, ErrorMessage, , , , , True);
			ExchangeComponents.ErrorFlag = True;
		EndTry;

		ExchangeComponents.ExchangeFile.Close();
	Else
		ExchangeComponents.ErrorFlag = True;
	EndIf;

	WriteExchangeFinish(ExchangeSettingsStructure, ExchangeComponents);

	If ExchangeComponents.ErrorFlag Then
		Raise ExchangeComponents.ErrorMessageString;
	EndIf;

	If Not ExchangeComponents.ErrorFlag And ExchangeComponents.IsExchangeViaExchangePlan
		And ExchangeComponents.UseHandshake Then
		
		// Writing information on the incoming message number.
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add(Common.TableNameByRef(
				ExchangeComponents.CorrespondentNode));
			LockItem.SetValue("Ref", ExchangeComponents.CorrespondentNode);
			Block.Lock();

			LockDataForEdit(ExchangeComponents.CorrespondentNode);
			NodeObject = ExchangeComponents.CorrespondentNode.GetObject();

			NodeObject.ReceivedNo = ExchangeComponents.IncomingMessageNumber;
			NodeObject.AdditionalProperties.Insert("GettingExchangeMessage");

			NodeObject.Write();

			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;

	EndIf;

EndProcedure

Function TemporaryExportDirectory(Val SessionID) Export

	SetPrivilegedMode(True);

	TempDirectory = "{SessionID}";
	TempDirectory = StrReplace(TempDirectory, "SessionID", String(SessionID));

	Result = CommonClientServer.GetFullFileName(
		DataExchangeServer.TempFilesStorageDirectory(), TempDirectory);

	Return Result;

EndFunction

Procedure CheckInfobaseLockForUpdate() Export

	If ValueIsFilled(InfobaseUpdateInternal.InfobaseLockedForUpdate()) Then

		Raise NStr("vi = 'Tạm thời không thể đồng bộ dữ liệu do đang cập nhật ứng dụng.';
					|ru = 'Синхронизация данных временно недоступна в связи с обновлением приложения.';
					|en = 'Data synchronization is temporarily unavailable due to the application update.'; fa = 'Data synchronization is temporarily unavailable due to the application update.';
					|it = 'La sincronizzazione dei dati è temporaneamente non disponibile a causa dell''aggiornamento dell''applicazione.';
					|pl = 'Synchronizacja danych tymczasowo jest niedostępna w związku z aktualizacją aplikacji.';
					|tr = 'Çevrimiçi uygulama güncellemesi nedeniyle veri senkronizasyonu geçici olarak kullanılamıyor.'");

	EndIf;

EndProcedure

Function GetDataReceiptExecutionStatus(TimeConsumingOperationID, ErrorMessage) Export

	ErrorMessage = "";

	SetPrivilegedMode(True);
	BackgroundJob = BackgroundJobs.FindByUUID(
		New UUID(TimeConsumingOperationID));

	BackgroundJobStates = BackgroundJobsStates();
	If BackgroundJob = Undefined Then
		CurrentBackgroundJobState = BackgroundJobStates.Get(BackgroundJobState.Canceled);
	Else

		If BackgroundJob.ErrorInfo <> Undefined Then
			ErrorMessage = ErrorProcessing.DetailErrorDescription(BackgroundJob.ErrorInfo);
		EndIf;
		CurrentBackgroundJobState = BackgroundJobStates.Get(BackgroundJob.State);

	EndIf;

	Return CurrentBackgroundJobState;

EndFunction

Function GetExecutionStatusOfDataPreparationForSending(BackgroundJobIdentifier, ErrorMessage) Export

	ErrorMessage = "";

	SetPrivilegedMode(True);

	ReturnedStructure = XDTOFactory.Create(
		XDTOFactory.Type("http://v8.1c.ru/SSL/Exchange/EnterpriseDataExchange", "PrepareDataOperationResult"));

	BackgroundJob = BackgroundJobs.FindByUUID(
		New UUID(BackgroundJobIdentifier));

	If BackgroundJob = Undefined Then
		CurrentBackgroundJobState = BackgroundJobsStates().Get(BackgroundJobState.Canceled);
	Else

		ErrorMessage        = "";
		FilePartsCount    = 0;
		FileID       = "";
		CurrentBackgroundJobState = BackgroundJobsStates().Get(BackgroundJob.State);

		If BackgroundJob.ErrorInfo <> Undefined Then
			ErrorMessage = ErrorProcessing.DetailErrorDescription(BackgroundJob.ErrorInfo);
		Else
			If BackgroundJob.State = BackgroundJobState.Completed Then
				ArrayOfMessages  = TimeConsumingOperations.UserMessages(True, BackgroundJob.UUID);
				For Each BackgroundJobMessage In ArrayOfMessages Do
					If StrFind(BackgroundJobMessage.Text, "{WEBService}") > 0 Then
						ResultArray = StrSplit(BackgroundJobMessage.Text, "$", True);
						FilePartsCount = ResultArray[1];
						FileID    = ResultArray[2];
						Break;
					Else
						Continue;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;

	ReturnedStructure.ErrorMessage = ErrorMessage;
	ReturnedStructure.FileID       = FileID;
	ReturnedStructure.PartCount    = FilePartsCount;
	ReturnedStructure.Status       = CurrentBackgroundJobState;

	Return ReturnedStructure;

EndFunction

Function InitializeWebServiceParameters() Export

	ParametersStructure = New Structure;
	ParametersStructure.Insert("ExchangePlanName");
	ParametersStructure.Insert("ExchangePlanNodeCode");
	ParametersStructure.Insert("TempStorageFileID");
	ParametersStructure.Insert("FilePartSize");
	ParametersStructure.Insert("NameOfTheWEBService");

	Return ParametersStructure;

EndFunction

Procedure DisableAccessKeysUpdate(Disconnect, ScheduleUpdate1 = True) Export

	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(Disconnect, ScheduleUpdate1);
	EndIf;

EndProcedure

Procedure PutMessageForDataMapping(ExchangeNode, MessageID) Export

	SetPrivilegedMode(True);
	
	// Deleting a previous message for data mapping.
	Filter = New Structure("InfobaseNode", ExchangeNode);
	CommonSettings = InformationRegisters.CommonInfobasesNodesSettings.Get(Filter);

	If ValueIsFilled(CommonSettings.MessageForDataMapping) Then
		TempFileName = "";
		Try
			TempFileName = DataExchangeServer.GetFileFromStorage(
				CommonSettings.MessageForDataMapping);
		Except
			InformationRegisters.CommonInfobasesNodesSettings.PutMessageForDataMapping(
				ExchangeNode, "");
		EndTry;

		If Not IsBlankString(TempFileName) Then
			File = New File(TempFileName);
			If File.Exists() And File.IsFile() Then
				Try
					DeleteFiles(TempFileName);
				Except
					// Return the file info to the temporary storage where it will be deleted by a schedule job.
					// 
					DataExchangeServer.PutFileInStorage(TempFileName,
						CommonSettings.MessageForDataMapping);
				EndTry;
			EndIf;
		EndIf;
	EndIf;

	InformationRegisters.CommonInfobasesNodesSettings.PutMessageForDataMapping(
		ExchangeNode, MessageID);

EndProcedure

// Sets the flag indicating whether the extension import is required
Procedure EnableLoadingExtensionsThatChangeTheDataStructure() Export

	SetPrivilegedMode(True);

	Constants.LoadExtensionsThatChangeDataStructure.Set(True);

EndProcedure

// Resets the flag indicating whether the extension import is required
Procedure DisableLoadingExtensionsThatChangeTheDataStructure() Export

	SetPrivilegedMode(True);

	If Constants.LoadExtensionsThatChangeDataStructure.Get() Then
		Constants.LoadExtensionsThatChangeDataStructure.Set(False);
	EndIf;

EndProcedure

// Returns the flag indicating whether the extension import is required
// 
// Returns:
//  Boolean - Value of the constant "LoadExtensionsThatChangeDataStructure".
//
Function LoadExtensionsThatChangeDataStructure() Export

	SetPrivilegedMode(True);

	Return Constants.LoadExtensionsThatChangeDataStructure.Get()

EndFunction

#Region SerializationMethodsExchangeExecution

// Returns the table of predefined infobase data.
//
// Returns:
//   ValueTable - A set of predefined items:
//     * TableName - String - infobase table name.
//     * XMLTypeName1 - String - the name of a serialized object type.
//     * Ref - AnyRef - a reference to the predefined data item.
//     * PredefinedDataName - String - name of the predefined item.
// 
Function PredefinedDataTable1() Export

	PredefinedDataTable = New ValueTable;
	PredefinedDataTable.Columns.Add("TableName");
	PredefinedDataTable.Columns.Add("XMLTypeName1");
	PredefinedDataTable.Columns.Add("Ref");
	PredefinedDataTable.Columns.Add("PredefinedDataName");

	MetadataKinds = New Array;
	MetadataKinds.Add(Metadata.Catalogs);
	MetadataKinds.Add(Metadata.ChartsOfCalculationTypes);
	MetadataKinds.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataKinds.Add(Metadata.ChartsOfAccounts);

	QueryBatch = New Array; // Array of Query
	TablesCounter = 0;
	QueryText  = "";

	For Each MetadataKind In MetadataKinds Do

		For Each CurrentMetadata In MetadataKind Do

			If TablesCounter = 256 Then
				QueryBatch.Add(New Query(QueryText));

				TablesCounter = 0;
				QueryText  = "";
			EndIf;

			TablesCounter = TablesCounter + 1;

			If TablesCounter > 1 Then
				QueryText = QueryText + "				
											  |UNION ALL";
			EndIf;

			QueryText = QueryText + StrReplace("
													  |SELECT
													  |	""#TableName"" AS TableName,
													  |	T.Ref AS Ref,
													  |	T.PredefinedDataName AS PredefinedDataName
													  |FROM
													  |	#TableName AS T
													  |WHERE
													  |	T.PredefinedDataName <> """"", "#TableName",
				CurrentMetadata.FullName());

		EndDo;

	EndDo;

	If TablesCounter > 1 Then
		QueryBatch.Add(New Query(QueryText));
	EndIf;

	For Each CurrentQuery In QueryBatch Do

		Selection = CurrentQuery.Execute().Select();
		While Selection.Next() Do
			PredefinedDataRow = PredefinedDataTable.Add();
			FillPropertyValues(PredefinedDataRow, Selection);
			PredefinedDataRow.XMLTypeName1 = XMLTypeOf(PredefinedDataRow.Ref).TypeName;
		EndDo;
		Selection = Undefined;

	EndDo;

	Return PredefinedDataTable;

EndFunction

// Parameters:
//   Data - CatalogObject
//          - DocumentObject
//          - ChartOfAccountsObject
//          - ChartOfCalculationTypesObject
//          - InformationRegisterRecordSet
//          - ConstantValueManager -
//            Data object.
//   PredefinedDataTable - See DataExchangeInternal.PredefinedDataTable1
// 
Procedure MarkRefsToPredefinedData(Data, PredefinedDataTable) Export

	If Data = Undefined Or TypeOf(Data) = Type("ObjectDeletion") Then
		Return;
	Else
		ObjectMetadata = Data.Metadata();

		If Common.IsConstant(ObjectMetadata) Then

			CheckMarkPredefinedDataRef(Data.Value, PredefinedDataTable);

		ElsIf Common.IsRefTypeObject(ObjectMetadata) Then

			CollectionsArray = New Array;
			CollectionsArray.Add(ObjectMetadata.Attributes);
			CollectionsArray.Add(ObjectMetadata.StandardAttributes);

			If Common.IsTask(ObjectMetadata) Then
				CollectionsArray.Add(ObjectMetadata.AddressingAttributes);
			EndIf;

			CheckMarkPredefinedDataRefInObjectAttributesCollection(Data, CollectionsArray,
				PredefinedDataTable);

			For Each TabularSection In ObjectMetadata.TabularSections Do
				CheckMarkPredefinedDataRefInDataTable(Data[TabularSection.Name].Unload(),
					PredefinedDataTable);
			EndDo;

			If Common.IsChartOfAccounts(ObjectMetadata) Or Common.IsChartOfCalculationTypes(
				ObjectMetadata) Then
				For Each TabularSection In ObjectMetadata.StandardTabularSections Do
					TabularPartOfTheChartOfAccounts = TabularSection; // MetadataObjectChartOfAccounts
					CheckMarkPredefinedDataRefInDataTable(
						Data[TabularPartOfTheChartOfAccounts.Name].Unload(), PredefinedDataTable);
				EndDo;
			EndIf;

		ElsIf Common.IsRegister(ObjectMetadata) Then

			CheckMarkPredefinedDataRefInDataTable(Data.Unload(), PredefinedDataTable);

		EndIf;
	EndIf;

EndProcedure

// Parameters:
//   Data - CatalogObject
//          - DocumentObject
//          - ChartOfAccountsObject
//          - InformationRegisterRecordSet - an arbitrary data object.
//   PredefinedDataTable - See DataExchangeInternal.PredefinedDataTable1
// 
Procedure ReplaceRefsToPredefinedItems(Data, PredefinedDataTable) Export

	If Data = Undefined Or TypeOf(Data) = Type("ObjectDeletion") Then
		Return;
	Else
		ObjectMetadata = Data.Metadata();

		If Common.IsConstant(ObjectMetadata) Then

			CheckReplacePredefinedDataRefInObjectAttribute(Data, "Value", PredefinedDataTable);

		ElsIf Common.IsRefTypeObject(ObjectMetadata) Then

			ProcessPredefinedItemImport(Data, PredefinedDataTable);

			CollectionsArray = New Array;
			CollectionsArray.Add(ObjectMetadata.Attributes);
			CollectionsArray.Add(ObjectMetadata.StandardAttributes);

			If Common.IsTask(ObjectMetadata) Then
				CollectionsArray.Add(ObjectMetadata.AddressingAttributes);
			EndIf;

			CheckReplacePredefinedDataRefInObjectAttributesCollection(Data, CollectionsArray,
				PredefinedDataTable);

			For Each TabularSection In ObjectMetadata.TabularSections Do
				CheckReplacePredefinedDataRefInDataTable(Data[TabularSection.Name],
					PredefinedDataTable);
			EndDo;

			If Common.IsChartOfAccounts(ObjectMetadata) Or Common.IsChartOfCalculationTypes(
				ObjectMetadata) Then
				For Each TabularSection In ObjectMetadata.StandardTabularSections Do
					TabularPartOfTheChartOfAccounts = TabularSection; // MetadataObjectChartOfAccounts
					CheckReplacePredefinedDataRefInDataTable(Data[TabularPartOfTheChartOfAccounts.Name],
						PredefinedDataTable);
				EndDo;
			EndIf;

		ElsIf Common.IsRegister(ObjectMetadata) Then

			For Each FilterElement In Data.Filter Do
				FilterStructure1 = New Structure("Value, Use");
				FillPropertyValues(FilterStructure1, FilterElement);

				If FilterStructure1.Use = False Then
					Continue;
				EndIf;

				CheckReplacePredefinedDataRefInObjectAttribute(FilterStructure1, "Value",
					PredefinedDataTable);
				FilterElement.Set(FilterStructure1.Value);
			EndDo;

			CheckReplacePredefinedDataRefInDataTable(Data, PredefinedDataTable);

		EndIf;
	EndIf;

EndProcedure

#EndRegion

Function ExchangePlanContent(ExchangePlanName, Periodic2 = True, Regulatory = True) Export

	Return DataExchangeCached.ExchangePlanContent(ExchangePlanName, Periodic2, Regulatory);

EndFunction

// Adds information on number of items per transaction set in the constant
// to the structure that contains parameters of exchange message transport.
//
// Parameters:
//  Result - Structure - contains parameters of exchange message transport.
// 
Procedure AddTransactionItemsCountToTransportSettings(Result) Export

	Result.Insert("DataExportTransactionItemsCount",
		DataExchangeServer.DataExportTransactionItemsCount());
	Result.Insert("DataImportTransactionItemCount",
		DataExchangeServer.DataImportTransactionItemCount());

EndProcedure

// Returns the area number by the exchange plan node code (message exchange).
// 
// Parameters:
//  NodeCode - String - an exchange plan node code.
// 
// Returns:
//  Number - area number.
//
Function DataAreaNumberFromExchangePlanNodeCode(Val NodeCode) Export

	If TypeOf(NodeCode) <> Type("String") Then
		Raise NStr("vi = 'Sai kiểu tham số số [1].';
					|ru = 'Неправильный тип параметра номер [1].';
					|en = 'Invalid type in parameter number [1].'; fa = 'Invalid type in parameter number [1].';
					|it = 'Tipo errato del parametro numero [1].';
					|pl = 'Nieprawidłowy typ parametru numer [1].';
					|tr = 'Geçersiz parametre numarası [1].'");
	EndIf;

	Result = StrReplace(NodeCode, "S0", "");

	Return Number(Result);
EndFunction

// Returns data of the first record of query result as a structure.
// 
// Parameters:
//  QueryResult - QueryResult - a query result containing the data to be processed.
// 
// Returns:
//  Structure - a structure with the result.
//
Function QueryResultToStructure(Val QueryResult) Export

	Result = New Structure;
	For Each Column In QueryResult.Columns Do
		Result.Insert(Column.Name);
	EndDo;

	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;

	Selection = QueryResult.Select();
	Selection.Next();

	FillPropertyValues(Result, Selection);

	Return Result;
EndFunction

// Parameters:
//   Filter - Filter - custom filter.
//   ItemKey - String - a filter item name.
//   ElementValue - Arbitrary - filter item value.
// 
Procedure SetFilterItemValue(Filter, ItemKey, ElementValue) Export

	FilterElement = Filter.Find(ItemKey);
	If FilterElement <> Undefined Then
		FilterElement.Set(ElementValue);
	EndIf;

EndProcedure

#Region OperationsWithInformationRegisters

// Adds one record to the information register by the passed structure values.
//
// Parameters:
//  RecordStructure - Structure - a structure whose values will be used for creating and filling in the record
//                                set.
//  RegisterName     - String - Name of information register to add the record to.
// 
Procedure AddRecordToInformationRegister(RecordStructure, Val RegisterName, Load = False) Export

	RecordSet = CreateInformationRegisterRecordSet(RecordStructure, RegisterName);
	
	// Adding a single record to a new record set.
	NewRecord = RecordSet.Add();
	
	// Filling record property values from the passed structure.
	FillPropertyValues(NewRecord, RecordStructure);

	RecordSet.DataExchange.Load = Load;
	
	// Writing a record set
	RecordSet.Write();

EndProcedure

// Updates a record in the information register by the passed structure values.
//
// Parameters:
//  RecordStructure - Structure - a structure whose values will be used to create a record manager and update the record.
//  RegisterName     - String - Name of information register to update the record in.
// 
Procedure UpdateInformationRegisterRecord(RecordStructure, Val RegisterName) Export

	RegisterMetadata = Metadata.InformationRegisters[RegisterName]; // MetadataObjectInformationRegister

	BeginTransaction();

	Try
		// Creating a register record manager.
		RecordManager = InformationRegisters[RegisterName].CreateRecordManager();

		DataLock = New DataLock;
		DataLockItem = DataLock.Add("InformationRegister." + RegisterName);
		DataLockItem.Mode = DataLockMode.Exclusive;
	
		// Setting a filter by register dimensions.
		For Each Dimension In RegisterMetadata.Dimensions Do

			DimensionName = Dimension.Name;
		
			// If a value is specified in the structure, the filter is set.
			If RecordStructure.Property(DimensionName) Then
				RecordManager[DimensionName] = RecordStructure[DimensionName];
				DataLockItem.SetValue(DimensionName, RecordStructure[DimensionName]);
			EndIf;

		EndDo;
	
		DataLock.Lock();
		
		// Reading a record from the infobase.
		RecordManager.Read();
	
		// Filling record property values from the passed structure.
		FillPropertyValues(RecordManager, RecordStructure);
	
		// Write the record manager.
		RecordManager.Write();

		CommitTransaction();
	Except
		RollbackTransaction();

		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

		Event = NStr("vi = 'Обмен данными.Обновление записи';
					|ru = 'Обмен данными.Обновление записи';
					|en = 'Data exchange.Update records'; fa = 'Data exchange.Update records';
					|it = 'Обмен данными.Обновление записи';
					|pl = 'Data exchange.Update records';
					|tr = 'Обмен данными.Обновление записи'", Common.DefaultLanguageCode());

		WriteLogEvent(Event, EventLogLevel.Error, RegisterMetadata, , ErrorMessage);
	EndTry;

EndProcedure

// Deletes a record set for the passed structure values from the register.
//
// Parameters:
//  RecordStructure - Structure - a structure whose values are used to delete a record set.
//  RegisterName     - String - Name of the information register to remove the record set from.
// 
Procedure DeleteRecordSetFromInformationRegister(RecordStructure, RegisterName, Load = False) Export

	RecordSet = CreateInformationRegisterRecordSet(RecordStructure, RegisterName);

	RecordSet.DataExchange.Load = Load;
	
	// Write a record set.
	RecordSet.Write();

EndProcedure

// Creates an information register record set by the passed structure values. Adds a single record to the set.
//
// Parameters:
//  RecordStructure - Structure - a structure whose values will be used for creating and filling in the record
//                                set.
//  RegisterName     - String - an information register name.
//  
// Returns:
//   InformationRegisterRecordSet - a register record set by the specified filter.
// 
Function CreateInformationRegisterRecordSet(RecordStructure, RegisterName) Export

	RecordSet = InformationRegisters[RegisterName].CreateRecordSet(); // InformationRegisterRecordSet
	
	// Setting a filter by register dimensions.
	For Each KeyValue In RecordStructure Do
		SetFilterItemValue(RecordSet.Filter, KeyValue.Key, KeyValue.Value);
	EndDo;

	Return RecordSet;

EndFunction

#EndRegion

#EndRegion

#Region Private

Function ExchangeComponents(ExchangeDirection, WebServiceParameters, Cancel = False)

	ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents(ExchangeDirection);

	If ValueIsFilled(WebServiceParameters.ExchangePlanName) And ValueIsFilled(
		WebServiceParameters.ExchangePlanNodeCode) Then
		ExchangeComponents.CorrespondentNode = ExchangePlans[WebServiceParameters.ExchangePlanName].FindByCode(
			WebServiceParameters.ExchangePlanNodeCode);
	Else
		ExchangeComponents.IsExchangeViaExchangePlan = False;
	EndIf;

	ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = False;
	ExchangeComponents.DataExchangeState.StartDate = CurrentSessionDate();
	ExchangeComponents.UseTransactions = False;

	If ExchangeDirection = "Receive" Then

		ExchangeComponents.EventLogMessageKey = GenerateEventLogMessageKey(ExchangeDirection,
			WebServiceParameters);

		FileName = DataExchangeServer.GetFileFromStorage(
			WebServiceParameters.TempStorageFileID);
		DataExchangeXDTOServer.OpenImportFile(ExchangeComponents, FileName);
		DataExchangeXDTOServer.AfterOpenImportFile(ExchangeComponents, Cancel);

		If Cancel Then
			Return ExchangeComponents;
		EndIf;

	Else

		ExchangeComponents.EventLogMessageKey   = GenerateEventLogMessageKey(ExchangeDirection,
			WebServiceParameters);
		ExchangeComponents.ExchangeFormatVersion               = DataExchangeXDTOServer.ExchangeFormatVersionOnImport(
			ExchangeComponents.CorrespondentNode);
		ExchangeComponents.XMLSchema                          = DataExchangeXDTOServer.ExchangeFormat(
			WebServiceParameters.ExchangePlanName, ExchangeComponents.ExchangeFormatVersion);
		ExchangeComponents.ExchangeManager                    = DataExchangeXDTOServer.FormatVersionExchangeManager(
			ExchangeComponents.ExchangeFormatVersion, ExchangeComponents.CorrespondentNode);
		ExchangeComponents.ObjectsRegistrationRulesTable = DataExchangeXDTOServer.ObjectsRegistrationRules(
			ExchangeComponents.CorrespondentNode);
		ExchangeComponents.ExchangePlanNodeProperties           = DataExchangeXDTOServer.ExchangePlanNodeProperties(
			ExchangeComponents.CorrespondentNode);

	EndIf;

	If ExchangeComponents.ErrorFlag Then
		Return ExchangeComponents;
	EndIf;

	DataExchangeXDTOServer.InitializeExchangeRulesTables(ExchangeComponents);

	If ExchangeComponents.IsExchangeViaExchangePlan Then
		DataExchangeXDTOServer.FillXDTOSettingsStructure(ExchangeComponents);
		DataExchangeXDTOServer.FillSupportedXDTOObjects(ExchangeComponents);
	EndIf;

	DataExchangeXDTOServer.AfterInitializationOfTheExchangeComponents(ExchangeComponents);

	Return ExchangeComponents;

EndFunction

Function GetFilePartName(FilePartNumber, ArchiveName = "")

	If Not ValueIsFilled(ArchiveName) Then
		ArchiveName = "data";
	EndIf;

	Result = StringFunctionsClientServer.SubstituteParametersToString("%1.zip.%2", ArchiveName, Format(FilePartNumber,
		"NG=0"));

	Return Result;

EndFunction

Function BackgroundJobsStates()

	BackgroundJobStates = New Map;
	BackgroundJobStates.Insert(BackgroundJobState.Active, "Active");
	BackgroundJobStates.Insert(BackgroundJobState.Completed, "Completed");
	BackgroundJobStates.Insert(BackgroundJobState.Failed, "Failed");
	BackgroundJobStates.Insert(BackgroundJobState.Canceled, "Canceled");

	Return BackgroundJobStates;

EndFunction

Function GenerateEventLogMessageKey(ExchangeDirection, WebServiceParameters)

	If ExchangeDirection = "Receive" Then
		MessageKeyTemplate = NStr("vi = 'Kết nhập dữ liệu thông qua Web-service %1';
									|ru = 'Загрузка данных через Web-сервис %1';
									|en = 'Import data over web service %1'; fa = 'Import data over web service %1';
									|it = 'Download dei dati tramite il servizio web %1';
									|pl = 'Pobieranie danych poprzez Web-serwis %1';
									|tr = 'Verilerin Web-hizmet üzerinden içe aktarılması%1'", Common.DefaultLanguageCode());
	Else
		MessageKeyTemplate = NStr("vi = 'Kết xuất dữ liệu thông qua Web-service %1';
									|ru = 'Выгрузка данных через Web-сервис %1';
									|en = 'Export data over web service %1'; fa = 'Export data over web service %1';
									|it = 'Upload dei dati tramite il servizio web %1';
									|pl = 'Pobieranie danych poprzez Web-serwis %1';
									|tr = 'Verilerin Web-hizmet üzerinden dışa aktarılması%1'", Common.DefaultLanguageCode());
	EndIf;

	Return StringFunctionsClientServer.SubstituteParametersToString(MessageKeyTemplate,
		WebServiceParameters.NameOfTheWEBService);

EndFunction

Function ExchangeSettingsStructure(ExchangeComponents, DataExchangeAction)

	If Not ExchangeComponents.IsExchangeViaExchangePlan Then
		Return Undefined;
	EndIf;

	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
		ExchangeComponents.CorrespondentNode, DataExchangeAction);
	
	If ExchangeSettingsStructure.Cancel Then
		ErrorMessageString = NStr("vi = 'Lỗi khi khởi tạo quá trình trao đổi dữ liệu.';
									|ru = 'Ошибка при инициализации процесса обмена данными.';
									|en = 'Cannot initialize data exchange.'; fa = 'Cannot initialize data exchange.';
									|it = 'Errore nell''inizializzazione del processo di scambio dati.';
									|pl = 'Błąd podczas inicjalizacji procesu  wymiany danych.';
									|tr = 'Veri alışverişi sürecini başlatırken bir hata oluştu.'");
		DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);
		Raise ErrorMessageString;
	EndIf;

	ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
	ExchangeSettingsStructure.StartDate = CurrentSessionDate();

	MessageString = NStr("vi = 'Bắt đầu quá trình trao đổi dữ liệu đối với nút %1';
						|ru = 'Начало процесса обмена данными для узла %1';
						|en = 'Data exchange started. Node: %1'; fa = 'Data exchange started. Node: %1';
						|it = 'Inizio del processo di scambio dati per il nodo %1';
						|pl = 'Początek procesu  wymiany danych dla węzła %1';
						|tr = '%1Ünite için veri değişimi süreci başlatılıyor'", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
		ExchangeSettingsStructure.InfobaseNodeDescription);

	WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey,
		EventLogLevel.Information, ExchangeSettingsStructure.InfobaseNode.Metadata(),
		ExchangeSettingsStructure.InfobaseNode, MessageString);

	Return ExchangeSettingsStructure;

EndFunction

Procedure WriteExchangeFinish(ExchangeSettingsStructure, ExchangeComponents)

	If Not ExchangeComponents.IsExchangeViaExchangePlan Then
		Return;
	EndIf;

	ExchangeSettingsStructure.ExchangeExecutionResult    = ExchangeComponents.DataExchangeState.ExchangeExecutionResult;

	If ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataExport Then
		ExchangeSettingsStructure.ProcessedObjectsCount = ExchangeComponents.ExportedObjectCounter;
		ExchangeSettingsStructure.MessageOnExchange           = ExchangeSettingsStructure.DataExchangeDataProcessor.CommentOnDataExport;
	ElsIf ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataImport Then
		ExchangeSettingsStructure.ProcessedObjectsCount = ExchangeComponents.ImportedObjectCounter;
		ExchangeSettingsStructure.MessageOnExchange           = ExchangeSettingsStructure.DataExchangeDataProcessor.CommentOnDataImport;
	EndIf;

	ExchangeSettingsStructure.ErrorMessageString      = ExchangeComponents.ErrorMessageString;

	DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);

EndProcedure

#Region SerializationMethodsExchangeExecution

Procedure CheckMarkPredefinedDataRef(Value, PredefinedDataTable)

	If Not Common.IsReference(TypeOf(Value)) Then
		Return;
	EndIf;

	PredefinedDataRow = PredefinedDataTable.Find(Value, "Ref");
	If PredefinedDataRow = Undefined Then
		// Value is not a predefined item.
		Return;
	EndIf;

	If Not PredefinedDataRow.ToExport Then
		PredefinedDataRow.ToExport = True;
	EndIf;

EndProcedure

// Parameters:
//   Data - Arbitrary - a data object.
//   CollectionsArray - Array of MetadataObjectCollection - a set of attribute collection.
//   PredefinedDataTable - ValueTable - a predefined items table.
// 
Procedure CheckMarkPredefinedDataRefInObjectAttributesCollection(Data, CollectionsArray,
	PredefinedDataTable)

	For Each AttributesCollection In CollectionsArray Do
		For Each Attribute In AttributesCollection Do
			CheckMarkPredefinedDataRef(Data[Attribute.Name], PredefinedDataTable);
		EndDo;
	EndDo;

EndProcedure

// Parameters:
//   TableData - ValueTable - a table with object data.
//   PredefinedDataTable - ValueTable - a predefined items table.
// 
Procedure CheckMarkPredefinedDataRefInDataTable(TableData, PredefinedDataTable)

	For Each TableRow In TableData Do
		For Each Column In TableData.Columns Do
			CheckMarkPredefinedDataRef(TableRow[Column.Name], PredefinedDataTable);
		EndDo;
	EndDo;

EndProcedure

// Parameters:
//   Data - CatalogObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfAccountsObject
//          - ChartOfCalculationTypesObject
//   PredefinedDataTable - See DataExchangeInternal.PredefinedDataTable1
// 
Procedure ProcessPredefinedItemImport(Data, PredefinedDataTable)

	OriginalDataRef = Data.Ref;
	If Data.IsNew() Then
		OriginalDataRef = Data.GetNewObjectRef();
	EndIf;

	RowPredefinedData = PredefinedDataTable.Find(OriginalDataRef, "SourceRef1");
	If RowPredefinedData = Undefined Then
		Return;
	EndIf;

	DataForImport = RowPredefinedData.Ref.GetObject();
	ObjectMetadata = DataForImport.Metadata();

	CollectionsArray = New Array;
	CollectionsArray.Add(ObjectMetadata.Attributes);
	CollectionsArray.Add(ObjectMetadata.StandardAttributes);

	If Common.IsTask(ObjectMetadata) Then
		CollectionsArray.Add(ObjectMetadata.AddressingAttributes);
	EndIf;

	TransferAttributesCollectionValuesBetweenObjects(Data, DataForImport, CollectionsArray);

	For Each TabularSection In ObjectMetadata.TabularSections Do
		If Data[TabularSection.Name].Count() > 0 Or DataForImport[TabularSection.Name].Count() > 0 Then
			DataForImport[TabularSection.Name].Load(Data[TabularSection.Name].Unload());
		EndIf;
	EndDo;

	If Common.IsChartOfAccounts(ObjectMetadata) Or Common.IsChartOfCalculationTypes(ObjectMetadata) Then
		For Each TabularSection In ObjectMetadata.StandardTabularSections Do
			If Data[TabularSection.Name].Count() > 0 Or DataForImport[TabularSection.Name].Count() > 0 Then
				DataForImport[TabularSection.Name].Load(Data[TabularSection.Name].Unload());
			EndIf;
		EndDo;
	EndIf;

	Data = DataForImport;

EndProcedure

// Parameters:
//   Source - Arbitrary - an object is a data source.
//   Receiver - Arbitrary - a destination data object.
//   CollectionsArray - Array of MetadataObjectCollection - a set of attribute collection.
//
Procedure TransferAttributesCollectionValuesBetweenObjects(Source, Receiver, CollectionsArray)

	For Each AttributesCollection In CollectionsArray Do
		For Each Attribute In AttributesCollection Do
			AttributeName = Attribute.Name;
			If Receiver[AttributeName] = Receiver.Ref Then
				Continue;
			EndIf;
			If Receiver[AttributeName] = Source[AttributeName] Then
				Continue;
			EndIf;
			Receiver[AttributeName] = Source[AttributeName];
		EndDo;
	EndDo;

EndProcedure

// Parameters:
//   Data - Arbitrary - a data object.
//   AttributeName - String - an object attribute name.
//   PredefinedDataTable - See DataExchangeInternal.PredefinedDataTable1
// 
Procedure CheckReplacePredefinedDataRefInObjectAttribute(Data, AttributeName, PredefinedDataTable)

	If AttributeName = "Ref" Then
		Return;
	EndIf;
	
	Value = Data[AttributeName];

	If Not Common.IsReference(TypeOf(Value)) Then
		Return;
	EndIf;

	RowPredefinedData = PredefinedDataTable.Find(Value, "SourceRef1");
	If Not RowPredefinedData = Undefined Then
		Data[AttributeName] = RowPredefinedData.Ref;
	EndIf;

EndProcedure

// Parameters:
//   Data - Arbitrary - a data object.
//   CollectionsArray - Array of MetadataObjectCollection - a set of attribute collection.
//   PredefinedDataTable - See DataExchangeInternal.PredefinedDataTable1
//
Procedure CheckReplacePredefinedDataRefInObjectAttributesCollection(Data, CollectionsArray,
	PredefinedDataTable)

	For Each AttributesCollection In CollectionsArray Do
		For Each Attribute In AttributesCollection Do
			CheckReplacePredefinedDataRefInObjectAttribute(Data, Attribute.Name, PredefinedDataTable);
		EndDo;
	EndDo;

EndProcedure

// Parameters:
//   TableData - TabularSection - an object table or a register record set.
//   PredefinedDataTable - See DataExchangeInternal.PredefinedDataTable1
//
Procedure CheckReplacePredefinedDataRefInDataTable(TableData, PredefinedDataTable)

	If TableData.Count() = 0 Then
		Return;
	EndIf;

	TableTS = TableData.Unload();

	For Each DataTSRow In TableData Do
		For Each Column In TableTS.Columns Do
			If Not CommonClientServer.HasAttributeOrObjectProperty(DataTSRow, Column.Name) Then
				Continue;
			EndIf;
			CheckReplacePredefinedDataRefInObjectAttribute(DataTSRow, Column.Name,
				PredefinedDataTable);
		EndDo;
	EndDo;

EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated. Obsolete. Use the DataExchangeServer.CheckCanSynchronizeData(False).
//
Procedure CheckCanSynchronizeData() Export

	If Not AccessRight("View", Metadata.CommonCommands.Synchronize) Then

		Raise NStr("vi = 'Không đủ quyền để đồng bộ dữ liệu.';
					|ru = 'Недостаточно прав для синхронизации данных.';
					|en = 'Insufficient rights to synchronize data.'; fa = 'Insufficient rights to synchronize data.';
					|it = 'Permessi insufficienti per la sincronizzazione dei dati.';
					|pl = 'Nie wystarczające uprawnienia dla synchronizacji danych.';
					|tr = 'Veri senkronizasyonu için yetersiz haklar.'");

	ElsIf InfobaseUpdate.InfobaseUpdateRequired()
		And Not DataExchangeMessageImportModeBeforeStart("ImportPermitted") Then

		Raise NStr("vi = 'Cơ sở thông tin đang có trạng thái cập nhật.';
					|ru = 'Информационная база находится в состоянии обновления.';
					|en = 'Infobase is updating.'; fa = 'Infobase is updating.';
					|it = 'Il database informatico è in fase di aggiornamento.';
					|pl = 'Baza infromacyjna znajduje się w statusie aktualizacji.';
					|tr = 'Infobase güncelleniyor.'");

	EndIf;

EndProcedure

#EndRegion

#EndRegion

#EndRegion