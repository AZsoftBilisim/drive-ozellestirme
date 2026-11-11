
#Region Internal

// Initializes the upload.
//
// Parameters:
//   ApplicationURL - String - url of the application that was created specifically for migration.
//   Login - String - username of the user in this app.
//   Password - String - user password.
//   ExportUserSettings - Map of KeyAndValue - collection of users whose settings need to be uploaded:
//      * Key - CatalogRef.Users - the user whose settings you want to upload.
//      * Value - String - new user login.
//   CompleteMigrationAutomatically - Boolean - if True, an attempt will be made to set exclusive mode and
//                                             complete the migration.
//   AdditionalProperties - Structure - additional properties to save.
//
Procedure BeginUnload(ApplicationURL, Login, Password, ExportUserSettings, CompleteMigrationAutomatically, AdditionalProperties) Export
	
	ValidateExchangePlanContent();
	
	CheckSessionSharingUsage();
	
	Record = InformationRegisters.ApplicationsMigrationExportState.CreateRecordManager();
	Record.Read();
	If Record.Selected() Then
		Raise NStr("vi = 'Đã bắt đầu chuyển.';
					|ru = 'Переход уже начался.';
					|en = 'Migration has already started.'; fa = 'Migration has already started.';
					|it = 'La transizione è già iniziata.';
					|pl = 'Przejście zostało już rozpoczęte.';
					|tr = 'Transfer artık başladı.'");
	EndIf;
	
	BeginTransaction();
	Try
		NewNode = ExchangePlans.ApplicationsMigration.CreateNode();
		NewNode.Description = StrTemplate(NStr("vi = 'Di chuyển đến %1 (%2)';
												|ru = 'Миграция в %1 (%2)';
												|en = 'Migration in %1 (%2)'; fa = 'Migration in %1 (%2)';
												|it = 'Migrazione a %1 (%2)';
												|pl = 'Migracja do %1 (%2)';
												|tr = '%1 geçiş (%2)'"), Metadata.Presentation(), ApplicationURL);
		NewNode.Code = String(New UUID);
		NewNode.Write();
		
		AccessParameters = New Structure;
		AccessParameters.Insert("URL", ApplicationURL);
		AccessParameters.Insert("UserName", Login);
		AccessParameters.Insert("Password", Password);
		
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(NewNode.Ref, AccessParameters, "AccessParameters");
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
		
		Record = InformationRegisters.ApplicationsMigrationExportState.CreateRecordManager();
		Record.State = Enums.ApplicationMigrationStates.Running;
		Record.StartDate = CurrentUniversalDate();
		Record.ApplicationURL = ApplicationURL;
		Record.ExportUserSettings = New ValueStorage(ExportUserSettings);
		Record.ExchangeNode = NewNode.Ref;
		Record.CompleteMigrationAutomatically = CompleteMigrationAutomatically;
		Record.AdditionalProperties = New ValueStorage(AdditionalProperties);
		Record.Initiator = Users.CurrentUser();
		Record.Write();
		
		DefaultValues = ScheduledJobs.CreateScheduledJob(Metadata.ScheduledJobs.ApplicationsMigrationExport);
		
		JobParameters = New Structure;
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ApplicationsMigrationExport);
		JobParameters.Insert("Use", True);
		JobParameters.Insert("Schedule", DefaultValues.Schedule);
		JobParameters.Insert("RestartCountOnFailure", DefaultValues.RestartCountOnFailure);
		JobParameters.Insert("RestartIntervalOnFailure", DefaultValues.RestartIntervalOnFailure);
		JobParameters.Insert("Key", DefaultValues.Key);
		
		ScheduledJobsServer.AddJob(JobParameters);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Cancels the upload.
//
Procedure CancelUpload() Export
	
	CheckSessionSharingUsage();
	
	BeginTransaction();
	Try
		Record = InformationRegisters.ApplicationsMigrationExportState.CreateRecordManager();
		Record.Read();
		If Not Record.Selected() Then
			Raise NStr("vi = 'Chưa thực hiện chuyển.';
						|ru = 'Переход не выполняется.';
						|en = 'Migration is not in progress.'; fa = 'Migration is not in progress.';
						|it = 'La transizione non riesce.';
						|pl = 'Przejście nie jest wykonywane.';
						|tr = 'Aktarma gerçekleştirilemiyor'");
		EndIf;
		
		If ValueIsFilled(Record.ExchangeNode) Then
		
			SetSafeModeDisabled(True);
			SetPrivilegedMode(True);
			AccessParameters = Common.ReadDataFromSecureStorage(Record.ExchangeNode, "AccessParameters");
			Record.ExchangeNode.GetObject().Delete();
			SetPrivilegedMode(False);
			SetSafeModeDisabled(False);
			
			ScheduledJobsServer.DeleteJob(Metadata.ScheduledJobs.ApplicationsMigrationExport);
			
			Record.Delete();
			
			Try
				CancelDownloadInService(AccessParameters);
			Except
				MessageTemplate = NStr("vi = 'Đã kết thúc bị lỗi việc hủy bỏ di chuyển trong dịch vụ, hãy liên hệ với người quản trị dịch vụ. 
		                                |Mô tả lỗi:
		                                |%1';
		                                |ru = 'Отмена миграции на сервисе завершилась с ошибкой, обратитесь к администратору сервиса. 
		                                |Описание ошибки:
		                                |%1';
		                                |en = 'Failed to cancel migration. Contact service administrator.
		                                |Error details:
		                                |%1'; fa = 'Failed to cancel migration. Contact service administrator.
		                                |Error details:
		                                |%1';
		                                |it = 'L''annullamento della migrazione del servizio ha esito negativo, contattare l''amministratore del servizio. 
		                                |Descrizione dell''errore:
		                                |%1';
		                                |pl = 'Anulowanie migracji na serwisie jest zakończone z błędem, zwróć się do administratora serwisu. 
		                                |Opis błędu:
		                                |%1';
		                                |tr = 'Serviste geçiş iptali hatayla sonuçlandı, hizmet yöneticisiyle iletişime geçin. 
		                                |Hata açıklaması:
		                                |%1'");
				UserMessage = New UserMessage;
				UserMessage.Text = StrTemplate(
					MessageTemplate, CloudTechnology.ShortErrorText(ErrorInfo()));
				UserMessage.Message();
			EndTry;
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns the status of the upload.
//
// Returns:
//   Structure - structure with keys:
//     * StartDate - Date - universal start date of the transition.
//     * SentMessageNumber - Number - number of the sent message.
//     * ReceivedMessageNumber - Number - number of processed messages.
//     * ObjectsChanged - Number - the number of registered changes.
//     * ObjectsExported - Number - the number of unloaded objects.
//     * ObjectsImported - Number - the number of objects loaded.
//     * ImportObjects - Number - the number of objects that still need to be loaded. 
//     * CompletedOn - Date - universal completion date of the transition.
//     * State - EnumRef.ApplicationMigrationStates - migration status.
//     * Comment - String - add. description of the state.
//
Function ExportState() Export 
	
	ExportState = New Structure;
	ExportState.Insert("StartDate", Date(1, 1, 1));
	ExportState.Insert("ApplicationURL", "");
	ExportState.Insert("CompleteMigrationAutomatically", False);
	ExportState.Insert("SentMessageNumber", 0);
	ExportState.Insert("ReceivedMessageNumber", 0);
	ExportState.Insert("ObjectsChanged", 0);
	ExportState.Insert("ObjectsExported", 0);
	ExportState.Insert("ObjectsImported", 0);
	ExportState.Insert("ImportObjects", 0);
	ExportState.Insert("ExclusiveModeRequired", False);
	ExportState.Insert("CompletedOn", Date(1, 1, 1));
	ExportState.Insert("State", Enums.ApplicationMigrationStates.EmptyRef());
	ExportState.Insert("Comment", "");
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ExportState.StartDate AS StartDate,
	|	ExportState.ApplicationURL AS ApplicationURL,
	|	ExportState.CompleteMigrationAutomatically AS CompleteMigrationAutomatically,
	|	ExportState.SentMessageNumber AS SentMessageNumber,
	|	ExportState.ReceivedMessageNumber AS ReceivedMessageNumber,
	|	ExportState.ObjectsChanged AS ObjectsChanged,
	|	ExportState.ObjectsExported AS ObjectsExported,
	|	ExportState.ObjectsImported AS ObjectsImported,
	|	ExportState.State AS State,
	|	ExportState.Comment AS Comment,
	|	ExportState.CompletedOn AS CompletedOn,
	|	ExportState.AdditionalProperties AS AdditionalProperties
	|FROM
	|	InformationRegister.ApplicationsMigrationExportState AS ExportState";
	
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Return ExportState;
	EndIf;
	
	FillPropertyValues(ExportState, Selection);
	
	ExportState.ImportObjects = ExportState.ObjectsExported - ExportState.ObjectsImported + ExportState.ObjectsChanged;
	For Each KeyAndValue In Selection.AdditionalProperties.Get() Do
		ExportState.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	ExportState.ExclusiveModeRequired = ExportState.ObjectsExported > 0 And ExportState.ObjectsChanged < DataChunkSize();
	
	Return ExportState;
	
EndFunction

// Initializes the download.
//
// Parameters:
// AreaUsers - Map - the source link is used as the key, and the user login is used as the value.
// ApplicationKind - Structure
//
Procedure StartDownloading(AreaUsers, ApplicationKind = Undefined) Export
	
	CheckSessionSharingUsage();
		
	BeginTransaction();
	Try
		ImportState = InformationRegisters.ApplicationsMigrationImportState.CreateRecordManager();
		ImportState.Read();
		If ImportState.Selected() Then
			Raise NStr("vi = 'Đang kết nhập.';
						|ru = 'Загрузка уже выполняется.';
						|en = 'Import is already in progress.'; fa = 'Import is already in progress.';
						|it = 'Il download è già in esecuzione.';
						|pl = 'Pobieranie już jest wykonywane.';
						|tr = 'İçe aktarma zaten çalışıyor'");
		EndIf;
		
		ImportState = InformationRegisters.ApplicationsMigrationImportState.CreateRecordManager();
		ImportState.StartDate = CurrentUniversalDate();
		ImportState.RefsMap = New ValueStorage(New Map);
		ImportState.Users = New ValueStorage(AreaUsers); 
		ImportState.ApplicationKind = New ValueStorage(ApplicationKind);
		ImportState.Write();
		
		DefaultValues = ScheduledJobs.CreateScheduledJob(Metadata.ScheduledJobs.ApplicationsMigrationImport);
		
		JobParameters = New Structure;
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ApplicationsMigrationImport);
		JobParameters.Insert("Use", True);
		JobParameters.Insert("Schedule", DefaultValues.Schedule);
		JobParameters.Insert("RestartCountOnFailure", DefaultValues.RestartCountOnFailure);
		JobParameters.Insert("RestartIntervalOnFailure", DefaultValues.RestartIntervalOnFailure);
		JobParameters.Insert("Key", DefaultValues.Key);
		JobParameters.Insert("ExclusiveExecution", True);
		
		ScheduledJobsServer.AddJob(JobParameters);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert(MethodNameExportJob());
	NamesAndAliasesMap.Insert(MethodNameImportJob());
	NamesAndAliasesMap.Insert(MethodNameDeleteTemporaryUser());
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.ExchangePlans.ApplicationsMigration,
		ExportImportData.ActionWithLinksDoNotChange());
		
	Types.Add(Metadata.InformationRegisters.ApplicationsMigrationImportQueue);
	Types.Add(Metadata.InformationRegisters.ApplicationsMigrationImportState);
	Types.Add(Metadata.InformationRegisters.ApplicationsMigrationExportState);
	Types.Add(Metadata.Constants.ApplicationsMigrationUsed);
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
//
// Parameters:
//	Settings - See ScheduledJobsOverridable.OnDefineScheduledJobSettings.Settings
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ApplicationsMigrationExport;
	Setting.UseExternalResources = True;

EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.SharedData = True;
	Handler.Version    = "1.0.16.6";
	Handler.Procedure = "ExchangePlans.ApplicationsMigration.FillInAuxiliaryData";
	Handler.ExecutionMode = "Seamless";
	
	If SaaSOperations.DataSeparationEnabled() Then
		Handler = Handlers.Add();
		Handler.SharedData = True;
		Handler.Version    = "2.0.10.5";
		Handler.Procedure = "ApplicationsMigration.DeleteTemporaryUsers";
		Handler.ExecutionMode = "Seamless";
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export

	Parameters.Insert("MigrationOfApplicationsOpenForm", YouNeedToOpenForm());
	
EndProcedure

// Routine task Migrationapplicationload.
//
Procedure ExportJob(CompleteMigration = False) Export
	
 	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ApplicationsMigrationExport);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	ExportState = InformationRegisters.ApplicationsMigrationExportState.CreateRecordManager();
	ExportState.Read();
	If Not ExportState.Selected() Then
		ErrorPresentation = NStr("vi = 'Không tìm thấy trạng thái kết xuất.';
								|ru = 'Состояние выгрузки не найдено.';
								|en = 'Export state not found.'; fa = 'Export state not found.';
								|it = 'Lo stato di scaricamento non è stato trovato.';
								|pl = 'Status pobierania nie znaleziono.';
								|tr = 'Dışa aktarma durumu bulunamadı'");
		ErrorLogging(NStr("vi = 'Kết xuất';
							|ru = 'Выгрузка';
							|en = 'Export'; fa = 'خروج اطلاعات';
							|it = 'Upload';
							|pl = 'Export';
							|tr = 'Dışa aktarma'", Common.DefaultLanguageCode()), ErrorPresentation);
		ScheduledJobsServer.DeleteJob(Metadata.ScheduledJobs.ApplicationsMigrationExport);
		Return;
	EndIf;
	
	ExchangeNode = ExportState.ExchangeNode;
	
	If Not ValueIsFilled(ExchangeNode) Then
		ErrorPresentation = NStr("vi = 'Không tìm thấy nút trao đổi.';
								|ru = 'Не найден узел обмена.';
								|en = 'Exchange node not found.'; fa = 'Exchange node not found.';
								|it = 'Nessun nodo del cambio trovato.';
								|pl = 'Nie jest znaleziony węzeł wymiany.';
								|tr = 'Değişim düğümü bulunamadı'");
		EndUploadWithError(ExportState, ErrorPresentation, ErrorPresentation);
		Return;
	EndIf;
	
	Try
		LockDataForEdit(ExchangeNode);
		RecordKey = InformationRegisters.ApplicationsMigrationExportState.CreateRecordKey(New Structure);
		LockDataForEdit(RecordKey);
	Except
		Return;
	EndTry;
	
	AccessParameters = Common.ReadDataFromSecureStorage(ExchangeNode, "AccessParameters");
	
	If AccessParameters = Undefined Then
		ErrorPresentation = NStr("vi = 'Không tìm thấy tham số kết nối.';
								|ru = 'Не найдены параметры подключения.';
								|en = 'Connection parameters not found.'; fa = 'Connection parameters not found.';
								|it = 'Non sono state trovate impostazioni di connessione.';
								|pl = 'Nie są znalezione parametry podłączenia.';
								|tr = 'Bağlantı parametreleri bulunmadı'");
		EndUploadWithError(ExportState, ErrorPresentation, ErrorPresentation);
		Return;
	EndIf;
	
	// Objects are registered before accessing the service, because the application may not be ready yet.
	If ExportState.SentMessageNumber = 0 Then
		For Each KeyAndValue In ApplicationsMigrationCached.UnloadedObjects() Do
			ExchangePlans.RecordChanges(ExchangeNode, KeyAndValue.Key);
			If Metadata.CalculationRegisters.Contains(KeyAndValue.Key) Then
				For Each Recalculation In KeyAndValue.Key.Recalculations Do
					ExchangePlans.RecordChanges(ExchangeNode, Recalculation);
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	Try
		ImportState = DownloadStateFromService(AccessParameters);
	Except
		// The service may be unavailable, this is not an error.
		ErrorPresentation = CloudTechnology.DetailedErrorText(ErrorInfo());
		Template = NStr("vi = 'Không thể nhận trạng thái kết nhập, có thể là dịch vụ tạm thời không khả dụng: %1 %2';
						|ru = 'Не удалось получить состояние загрузки, возможно сервис временно недоступен: %1 %2';
						|en = 'Cannot get the import state. The service might be temporarily unavailable: %1 %2'; fa = 'Cannot get the import state. The service might be temporarily unavailable: %1 %2';
						|it = 'Impossibile ottenere lo stato di scaricamento, il servizio potrebbe essere temporaneamente non disponibile: %1 %2';
						|pl = 'Nie udało się uzyskać status pobierania, możliwie, że serwis tymczasowo jest niedostępny: %1%2';
						|tr = 'İçe aktarma durumu alınamadı, hizmet geçici olarak kullanılamıyor olabilir: %1 %2'", Common.DefaultLanguageCode());
		Comment = StrTemplate(Template, Chars.LF, ErrorPresentation);
		NoteRegistration(NStr("vi = 'Kết xuất';
								|ru = 'Выгрузка';
								|en = 'Export'; fa = 'خروج اطلاعات';
								|it = 'Upload';
								|pl = 'Export';
								|tr = 'Dışa aktarma'", Common.DefaultLanguageCode()), Comment);
		CheckDate = ?(ValueIsFilled(ExportState.ImportStateDate), ExportState.ImportStateDate, ExportState.StartDate);
		If (CurrentUniversalDate() - CheckDate) > (86400) Then
			ErrorPresentation = NStr("vi = 'Dịch vụ không khả dụng trong 24 giờ, đã dừng kết xuất.';
									|ru = 'Сервис недоступен 24 часа, выгрузка прервана.';
									|en = 'The service is unavailable within 24 hours, export is canceled.'; fa = 'The service is unavailable within 24 hours, export is canceled.';
									|it = 'Il servizio non è disponibile 24 ore, lo scarico è interrotto.';
									|pl = 'Serwis jest niedostępny w ciągu 24 godzin, wysłanie zostało przerwane.';
									|tr = 'Servis 24 saat kullanılamıyor, dışa aktarma durduruldu.'");
			EndUploadWithError(ExportState, ErrorPresentation, ErrorPresentation);
		EndIf;
		Return;
	EndTry;
	
	If ExportState.ReceivedMessageNumber < ImportState.ReceivedMessageNumber Then
		ExportState.ReceivedMessageNumber = ImportState.ReceivedMessageNumber;
		ExchangePlans.DeleteChangeRecords(ExchangeNode, ImportState.ReceivedMessageNumber);
	EndIf;
	
	If ImportState.ResendingRequired Then
		
		// This means that the version in the receiver has been updated and you need to resend the already uploaded objects.
		RegisterChangesAgain(ExchangeNode, ExportState.SentMessageNumber);
		
		BeginTransaction();
		Try
			// The queue is cleared at the receiver, here you also need to reset the number of the sent
			ExportState.SentMessageNumber = ImportState.ReceivedMessageNumber;
			
			ImportState = ConfirmReloadingInService(AccessParameters);
			
			FillInUploadState(ExportState, ImportState, ExchangeNode);
			ExportState.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
	EndIf;
	
	If ImportState.ConfigurationVersion <> Metadata.Version Then
		ExportState.State = Enums.ApplicationMigrationStates.RefreshPending;
		ExportState.Comment = ImportState.ConfigurationVersion;
		FillInUploadState(ExportState, ImportState, ExchangeNode);
		ExportState.Write();
	ElsIf ExportState.State = Enums.ApplicationMigrationStates.RefreshPending Then
		ExportState.State = Enums.ApplicationMigrationStates.Running;
		ExportState.Write();
		Return;
	EndIf;
	
	
	MessageNo = ExportState.SentMessageNumber + 1;
		
	If (ExportState.SentMessageNumber - ImportState.ReceivedMessageNumber) >= MaximumLoadQueue() Then
		
		FillInUploadState(ExportState, ImportState, ExchangeNode);
		ExportState.Write();
		
		Return;
		
	ElsIf ImportState.CompletedWithErrors Then
		
		FillInUploadState(ExportState, ImportState, ExchangeNode);
		ExportState.CompletedOn = CurrentUniversalDate();
		ScheduledJobsServer.DeleteJob(Metadata.ScheduledJobs.ApplicationsMigrationExport);
		ExchangeNode.GetObject().Delete();
		ExportState.Write();
		
		Return;
		
	ElsIf ExportState.State = Enums.ApplicationMigrationStates.PendingImport Then
		// Messages are no longer generated, but are only expected when everything is loaded.
		BeginTransaction();
		Try
			If Not ImportState.LoadingIsInProgress Then
				ExportState.CompletedOn = CurrentUniversalDate();
				ExportState.State = Enums.ApplicationMigrationStates.OperationSuccessful;
				ExportState.Comment = NStr("vi = 'Đã kết thúc chuyển.
					|
					|Chú ý! 
					|Những thay đổi bất kỳ trong ứng dụng gốc sẽ không được chuyển đến ứng dụng đã tạo trong dịch vụ đám mây.
					|Chỉ nên làm việc với các ứng dụng này trong dịch vụ đám mây.';
					|ru = 'Переход завершен.
					|
					|Внимание! 
					|Любые изменения в исходном приложении не будут переданы в созданное приложение облачного сервиса.
					|Рекомендуется работать с данными приложения только в облачном сервисе.';
					|en = 'Migration completed.
					|
					|Warning! 
					|Any changes to the source application will not be passed to a created cloud service application.
					|We recommend that you work on application data in the cloud service only.'; fa = 'Migration completed.
					|
					|Warning! 
					|Any changes to the source application will not be passed to a created cloud service application.
					|We recommend that you work on application data in the cloud service only.';
					|it = 'Trasferimento completato.
					|
					|Attenzione!
					|Eventuali modifiche nell''applicazione originale non verranno trasferite nell''applicazione creata nel cloud. 
					|Si consiglia di lavorare con i dati dell''applicazione esclusivamente nel servizio cloud.';
					|pl = 'Przejście jest zakończone.
					|
					|Uwaga! 
					|Jakiekolwiek zmiany w aplikacji źródłowej nie zostaną przekazane do utworzonej aplikacji serwisu w chmurze.
					|Zaleca się praca z danymi aplikacji tylko w serwisie w chmurze.';
					|tr = 'Geçiş tamamlandı.
					|
					|Dikkat! 
					|Kaynak uygulamada yapılan herhangi bir değişiklik, oluşturulan bulut hizmeti uygulamasına transfer edilmeyecektir.
					|Bulut hizmetinde yalnızca uygulama verileriyle çalışmanız önerilir.'");
				ExportState.ExchangeNode = Undefined;
				ScheduledJobsServer.DeleteJob(Metadata.ScheduledJobs.ApplicationsMigrationExport);
				ExchangeNode.GetObject().Delete();
			EndIf;
			FillInUploadState(ExportState, ImportState, ExchangeNode);
			ExportState.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		If Not ImportState.LoadingIsInProgress Then
			DataTransferServer.GetFromLogicalStorage(AccessParameters, "migration", "remove-user");
		EndIf;
		Return;
	EndIf;
	
	DumpDirectory = GetTempFileName("AppMigrationOut") + GetPathSeparator();
	CreateDirectory(DumpDirectory);
	
	
	BeginTransaction();
	Try
		
		Result = UploadDataToFolder(DumpDirectory, 
			ExchangeNode, 
			MessageNo, 
			ExportState.LastMetadataObject, 
			ExportState.ExportUserSettings.Get(), 
			ExportState.CompleteMigrationAutomatically Or CompleteMigration);
		
	Except
		
		RollbackTransaction();
		ErrorInfo = ErrorInfo();
		ExportState.AttemptsNumber = ExportState.AttemptsNumber + 1;
		ExportState.LastExportDate = CurrentUniversalDate();
			
		FillInUploadState(ExportState, ImportState, ExchangeNode);
		
		If ExportState.AttemptsNumber >= 3 Then
						
			EndUploadWithError(ExportState,
				CloudTechnology.DetailedErrorText(ErrorInfo), 
				CloudTechnology.ShortErrorText(ErrorInfo));
			
		Else
			
			ExportState.Comment = CloudTechnology.ShortErrorText(ErrorInfo);
			ExportState.Write();
			
			ErrorLogging(NStr("vi = 'Kết xuất';
								|ru = 'Выгрузка';
								|en = 'Export'; fa = 'خروج اطلاعات';
								|it = 'Upload';
								|pl = 'Export';
								|tr = 'Dışa aktarma'", Common.DefaultLanguageCode()), 
				CloudTechnology.DetailedErrorText(ErrorInfo));
			
		EndIf;
		
		Return;
		
	EndTry;
	
	Try
		// The message is sent only if there is data in it.
		If Result.ObjectCount > 0 Or Result.ThisIsLastMessage Then
		
			ArchiveFileName = GetTempFileName("zip");
			RecordZIP = New ZipFileWriter(ArchiveFileName);
			RecordZIP.Add(DumpDirectory + "*", ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.ProcessRecursively);
			RecordZIP.Write();
			
			ExportState.SentMessageNumber = MessageNo;
			ExportState.ObjectsExported = ExportState.ObjectsExported + Result.ObjectCount;
			ExportState.AttemptsNumber = 0;
			ExportState.LastExportDate = CurrentUniversalDate();
			ExportState.Comment = "";
			If Result.ThisIsLastMessage Then
				ExportState.State = Enums.ApplicationMigrationStates.PendingImport;
			EndIf;
			ExportState.Write();
			
			ImportState = SendMessageToService(AccessParameters, ArchiveFileName);
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	FillInUploadState(ExportState, ImportState, ExchangeNode);
	ExportState.Write();
	
	If ValueIsFilled(ArchiveFileName) Then
		Try
			DeleteFiles(ArchiveFileName);
		Except
			ErrorPresentation = CloudTechnology.DetailedErrorText(ErrorInfo());
			ErrorLogging(NStr("vi = 'Kết xuất';
								|ru = 'Выгрузка';
								|en = 'Export'; fa = 'خروج اطلاعات';
								|it = 'Upload';
								|pl = 'Export';
								|tr = 'Dışa aktarma'", Common.DefaultLanguageCode()), ErrorPresentation);
		EndTry;
	EndIf;
			
	Try
		DeleteFiles(DumpDirectory);
	Except
		ErrorPresentation = CloudTechnology.DetailedErrorText(ErrorInfo());
		ErrorLogging(NStr("vi = 'Kết xuất';
							|ru = 'Выгрузка';
							|en = 'Export'; fa = 'خروج اطلاعات';
							|it = 'Upload';
							|pl = 'Export';
							|tr = 'Dışa aktarma'", Common.DefaultLanguageCode()), ErrorPresentation);
	EndTry;
	
EndProcedure

// Regular job Microcurrenttherapy.
//
Procedure TaskLoading() Export
	
	// A general purpose call.At the beginning of the fulfillment of the regulatory task() is not required, 
	// because this routine task can only be in a new area in which the update has not been performed.
		
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	CheckSessionSharingUsage();
	
	ImportState = InformationRegisters.ApplicationsMigrationImportState.CreateRecordManager();
	ImportState.Read();
	
	If Not ImportState.Selected() Then
		Comment = NStr("vi = 'Không tìm thấy trạng thái kết nhập. Đã dừng kết nhập';
						|ru = 'Состояние загрузки не найдено. Загрузка прервана';
						|en = 'Import state not found. Import canceled'; fa = 'Import state not found. Import canceled';
						|it = 'Lo stato di caricamento non è stato trovato. Download interrotto';
						|pl = 'Status pobierania nie znaleziono. Pobieranie zostało przerwane';
						|tr = 'İçe aktarma durumu bulunamadı. İçe aktarma durduruldu.'", Common.DefaultLanguageCode());
		ErrorLogging(NStr("vi = 'Kết nhập';
							|ru = 'Загрузка';
							|en = 'Import'; fa = 'ورود اطلاعات';
							|it = 'Scaricamento';
							|pl = 'Import';
							|tr = 'İçe aktarma'", Common.DefaultLanguageCode()), Comment);
		DeleteQueue();
		ScheduledJobsServer.DeleteJob(Metadata.ScheduledJobs.ApplicationsMigrationImport);
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ApplicationsMigrationImportQueue.Number AS Number,
	|	ApplicationsMigrationImportQueue.FileName AS FileName
	|FROM
	|	InformationRegister.ApplicationsMigrationImportQueue AS ApplicationsMigrationImportQueue
	|
	|ORDER BY
	|	Number";
		
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		// If the queue is empty for a long time, then the initiator of the migration no longer generates messages.
		TimeCountdown = ?(ValueIsFilled(ImportState.LastImportDate), ImportState.LastImportDate, ImportState.StartDate);
		If (CurrentUniversalDate() - TimeCountdown) > (86400) Then
			ErrorPresentation = NStr("vi = 'Không có thông báo trong vòng 24 giờ.';
									|ru = 'Отсутствуют сообщения в течении 24 часов.';
									|en = 'Messages are missing within 24 hours.'; fa = 'Messages are missing within 24 hours.';
									|it = 'Nessun messaggio entro 24 ore.';
									|pl = 'Brakują komunikaty w ciągu 24 godzin.';
									|tr = '24 saat mesaj bulunmuyor.'");
			EndUploadWithError_(ImportState, ErrorPresentation, ErrorPresentation);
		EndIf;
		Return;
	EndIf;
	
	File = New File(FilesCTL.FullTemporaryStorageFileName(Selection.FileName));
	If Not File.Exists() Then
		DetailErrorDescription = StrTemplate(NStr("vi = 'Không tìm thấy tệp thông báo %1.';
													|ru = 'Файл сообщения %1 не найден.';
													|en = '%1 message file not found.'; fa = '%1 message file not found.';
													|it = 'File %1 non trovato.';
													|pl = 'Plik komunikatu %1 nie znaleziono.';
													|tr = '%1 mesaj dosyası bulunmadı'"), Selection.FileName);
		BriefErrorDescription = NStr("vi = 'Không tìm thấy tệp thông báo.';
									|ru = 'Файл сообщения не найден.';
									|en = 'Message file not found.'; fa = 'Message file not found.';
									|it = 'File non trovato.';
									|pl = 'Plik komunikatu nie znaleziono.';
									|tr = 'Mesaj dosyası bulunmadı'");
		EndUploadWithError_(ImportState, DetailErrorDescription, BriefErrorDescription);
		Return;
	EndIf;
	
	RefsMap = ImportState.RefsMap.Get();
	If RefsMap = Undefined Then
		RefsMap = New Map;
	EndIf;
	
	ObjectsToClear = ImportState.ObjectsToClear.Get(); // Map
	If ObjectsToClear = Undefined Then
		ObjectsToClear = New Map;
		For Each KeyAndValue In ApplicationsMigrationCached.UnloadedObjects() Do
			ObjectsToClear.Insert(KeyAndValue.Key.FullName(), True);
		EndDo;
		// This is the very beginning
		If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
			
			ModuleAccessManagement = Common.CommonModule("AccessManagement");
			ModuleAccessManagement.DisableAccessKeysUpdate(True, False);
			
		EndIf;
		
		SetRegistersTotalsUsage(False);
		ClearUserData(FilesOperationsInternalSaaSCached.FilesCatalogsAndStorageOptionObjects().StorageObjects);
		ClearUserData(ObjectsToClear);
	EndIf;
		
	ImportDirectory = GetTempFileName("AppMigrationIn") + GetPathSeparator();
	CreateDirectory(ImportDirectory);
	
	ZIPReader = New ZipFileReader(File.FullName);
	ZIPReader.ExtractAll(ImportDirectory, ZIPRestoreFilePathsMode.Restore);
	ZIPReader.Close();
	
	Try
		
		Result = LoadDataFromCatalog(ImportDirectory, RefsMap, ObjectsToClear);
		
	Except
		
		ErrorInfo = ErrorInfo();
		If ImportState.AttemptsNumber >= 3 Then
			EndUploadWithError_(ImportState, 
				CloudTechnology.DetailedErrorText(ErrorInfo), 
				CloudTechnology.ShortErrorText(ErrorInfo));
		Else 
			ErrorLogging(NStr("vi = 'Kết nhập';
								|ru = 'Загрузка';
								|en = 'Import'; fa = 'ورود اطلاعات';
								|it = 'Scaricamento';
								|pl = 'Import';
								|tr = 'İçe aktarma'", Common.DefaultLanguageCode()), 
				CloudTechnology.DetailedErrorText(ErrorInfo));
			ImportState.AttemptsNumber = ImportState.AttemptsNumber + 1;
			ImportState.LastImportDate = CurrentUniversalDate();
			ImportState.ErrorDescription = CloudTechnology.ShortErrorText(ErrorInfo);
			ImportState.Write();
		EndIf;
		
		Return;
		
	EndTry;
	
	BeginTransaction();
	Try
		If Result.Success Then
		
			DownloadQueue = InformationRegisters.ApplicationsMigrationImportQueue.CreateRecordManager();
			DownloadQueue.Number = Selection.Number;
			DownloadQueue.Delete();

			FilesCTL.SetTemporaryStorageFileRetentionPeriod(Selection.FileName, 60);
			
			ImportState.RefsMap = New ValueStorage(RefsMap);
			ImportState.ObjectsToClear = New ValueStorage(ObjectsToClear);
			ImportState.ReceivedMessageNumber = Selection.Number;
			ImportState.ObjectsImported = ImportState.ObjectsImported + Result.ObjectsImported;
			
			If Result.ThisIsLastMessage Then
				
				If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
					
					ModuleAccessManagement = Common.CommonModule("AccessManagement");
					ModuleAccessManagement.DisableAccessKeysUpdate(False);
					
				EndIf;
				
				SetRegistersTotalsUsage(True);
				
				If Common.SubsystemExists("StandardSubsystems.TotalsAndAggregatesManagement") Then
					
					ModuleName = "TotalsAndAggregatesManagementInternal";
					ModuleTotalsAndAggregatesInternal = Common.CommonModule(ModuleName);
					ModuleTotalsAndAggregatesInternal.CalculateTotals();
					
				EndIf;
				
				ImportState.CompletedOn = CurrentUniversalDate();
				
				CompleteDownload(ImportState);
				
			EndIf;
			
			ImportState.LastImportDate = CurrentUniversalDate();
			ImportState.Write();
			
		Else
			
			// The configuration version does not match.
			// You need to reload all the objects that are in the queue.
			DeleteQueue();
			
			ImportState.ResendingRequired = True;
			ImportState.Write();
			
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Result.ThisIsLastMessage Then
		MessagesSaaS.DeliverQuickMessages();
	EndIf;
	
	Try
		DeleteFiles(ImportDirectory);
	Except
		ErrorPresentation = CloudTechnology.DetailedErrorText(ErrorInfo());
		ErrorLogging(NStr("vi = 'Kết nhập';
							|ru = 'Загрузка';
							|en = 'Import'; fa = 'ورود اطلاعات';
							|it = 'Scaricamento';
							|pl = 'Import';
							|tr = 'İçe aktarma'", Common.DefaultLanguageCode()), ErrorPresentation);
	EndTry;
	
	Try
		FilesCTL.DeleteTemporaryStorageFile(Selection.FileName);
	Except
		ErrorPresentation = CloudTechnology.DetailedErrorText(ErrorInfo());
		ErrorLogging(NStr("vi = 'Kết nhập';
							|ru = 'Загрузка';
							|en = 'Import'; fa = 'ورود اطلاعات';
							|it = 'Scaricamento';
							|pl = 'Import';
							|tr = 'İçe aktarma'", Common.DefaultLanguageCode()), ErrorPresentation);
	EndTry;
		
EndProcedure

// Checks the structure of the plan of exchange, in case of incorrect composition is called an exception.
// Checks:
//   1) auto-registration is disabled for all objects. 
//   2) the structure contains all the objects necessary for exchange.
//
Procedure ValidateExchangePlanContent() Export
	
	ExchangePlanContent = New Map;
	For Each Content In Metadata.ExchangePlans.ApplicationsMigration.Content Do
		If Content.AutoRecord = AutoChangeRecord.Allow Then
			Raise NStr("vi = 'Đã tùy chỉnh sai sơ đồ trao đổi ""Di chuyển ứng dụng"": cần tắt tự động ghi nhận.';
						|ru = 'Некорректно настроен план обмена ""Миграция приложений"": авторегистрация должна быть выключена.';
						|en = 'The ""Application migration"" exchange plan is set up incorrectly: autoregistration must be disabled.'; fa = 'The ""Application migration"" exchange plan is set up incorrectly: autoregistration must be disabled.';
						|it = 'Il piano di condivisione migrazione app non è configurato correttamente: la registrazione automatica deve essere disattivata.';
						|pl = 'Nie poprawnie jest ustawiony plan wymiany ""Миграция приложений"": automatyczna rejestracja powinna być wyłączona.';
						|tr = '""Uygulama Geçişi"" değişim planı yanlış yapılandırılmış: otomatik kayıt devre dışı bırakılmalıdır.'");
		EndIf;
		ExchangePlanContent.Insert(Content.Metadata, True);
	EndDo;
	
	For Each ObjectToImport In ApplicationsMigrationCached.UnloadedObjects() Do
		If ExchangePlanContent.Get(ObjectToImport.Key) = Undefined Then
			Template = NStr("vi = 'Đã tùy chỉnh sai sơ đồ trao đổi ""Di chuyển ứng dụng"": cần thêm %1 vào thành phần.';
							|ru = 'Некорректно настроен план обмена ""Миграция приложений"": в состав нужно добавить %1.';
							|en = 'The ""Application migration"" exchange plan is set up incorrectly: add %1.'; fa = 'The ""Application migration"" exchange plan is set up incorrectly: add %1.';
							|it = 'Il piano di migrazione delle applicazioni non è configurato correttamente: è necessario aggiungere la parte %1.';
							|pl = 'Nie poprawnie jest ustawiony plan wymiany ""Миграция приложений"": do składu trzeba dodać %1.';
							|tr = '""Uygulama Geçişi"" değişim planı yanlış yapılandırıldı: içeriğe %1 eklemeniz gerekiyor.'");
			Raise StrTemplate(Template, ObjectToImport.Key.FullName());
		EndIf;
	EndDo;
	
EndProcedure

// Handler for subscribing to the event before writing the Object.
//
Procedure BeforeWriteObject(Source, Cancel) Export
	
	// Deceived.No download is required, because the subscription belongs to the exchange plan.
	SetSafeModeDisabled(True);
	RecordChanges(Source);
	
EndProcedure

// Handler for subscribing to a document Record event.
//
Procedure BeforeWritingDocument(Source, Cancel, WriteMode, PostingMode) Export
	
	// Deceived.No download is required, because the subscription belongs to the exchange plan.
	SetSafeModeDisabled(True);
	RecordChanges(Source);
	
EndProcedure

// Handler for subscribing to the pre-Recordset event.
//
Procedure BeforeRecordingSet(Source, Cancel, Replacing) Export
	
	// Deceived.No download is required, because the subscription belongs to the exchange plan.
	SetSafeModeDisabled(True);
	RecordChanges(Source);
	
EndProcedure

// Handler for subscribing to the event before recording the calculation Set.
//
Procedure BeforeRecordingCalculationSet(Source, Cancel, Replacing, WriteOnly, WriteActualActionPeriod, WriteRecalculations) Export
	
	// Deceived.No download is required, because the subscription belongs to the exchange plan.
	SetSafeModeDisabled(True);
	RecordChanges(Source);
	
EndProcedure

// Handler for subscribing to the event before deleting an Object.
//
Procedure BeforeDeleteObject(Source, Cancel) Export
	
	// Deceived.No download is required, because the subscription belongs to the exchange plan.
	SetSafeModeDisabled(True);
	RecordChanges(Source);
	
EndProcedure

// It turns out the user's subscribers from the service.
// It is used in the external processing of the transition to the service, which should work on the BTS from 1.2.2.
//
// Parameters:
//   SourceOfAccessParameters - ClientApplicationForm, Structure -
//
// Returns:
//   ValueList - as the value of the code, as the representation of the name.
//
Function UserSubscribers(SourceOfAccessParameters) Export
	
	AccessParameters = GetAccessParameters(SourceOfAccessParameters);
	Method = "account/list";
	
	MethodParameters = New Structure;
	MethodParameters.Insert("general", New Structure);
	If Not MethodInAddressIsSupported(AccessParameters) Then
		MethodParameters.general.Insert("type", "ext");
		MethodParameters.general.Insert("method", Method);
	EndIf;
	MethodParameters.general.Insert("version", 3);
	
	Result = CallProgramInterfaceMethod(AccessParameters, MethodParameters, Method);
	
	UserSubscribers = New ValueList;
	
	Try
		For Each Subscriber In Result.account Do
			If Subscriber.role = "owner" Or Subscriber.role = "administrator" Then
				UserSubscribers.Add(Subscriber.id, Subscriber.name);
			EndIf;
		EndDo;
	Except
		Raise StrTemplate(NStr("vi = 'Sai định dạng phản hồi của giao diện lệnh bên ngoài: ""%1""';
								|ru = 'Неверный формат ответа внешнего программного интерфейса: ""%1""';
								|en = 'Invalid format of the external API response: ""%1""'; fa = 'Invalid format of the external API response: ""%1""';
								|it = 'Formato di risposta non valido dell''interfaccia software esterna: ""%1""';
								|pl = 'Błędny format odpowiedzi zewnętrznego interfejsu programowego: ""%1""';
								|tr = 'Hatalı harici API cevap formatı: ""%1""'"), "ext/account/list");
	EndTry;
	
	Return UserSubscribers;
	
EndFunction

// Calls the method of the program interface of the service manager.
//
// Parameters:
//   SourceOfAccessParameters - ClientApplicationForm, Structure -
//   MethodParameters - Structure - parameters of the called method.
//   Method - String, Undefined - the name of the method to substitute in the request URL. If not specified, in the service manager
//      the method name from the request parameters will be used.
//
// Returns:
// 	Structure - query result:
//	* Field - Arbitrary - an arbitrary set of fields.
Function CallProgramInterfaceMethod(SourceOfAccessParameters, MethodParameters, Method = Undefined) Export
	
	AccessParameters = GetAccessParameters(SourceOfAccessParameters);
	JSONData = ObjectInJSON(MethodParameters);
	
	URIStructure = CommonClientServer.URIStructure(AccessParameters.APIAddress);
	
	ResourceAddress = URIStructure.PathAtServer + "/execute";
	If Method <> Undefined And MethodInAddressIsSupported(AccessParameters) Then
		ResourceAddress = ResourceAddress + "/usr/" + Method;
	EndIf;
	
	SecureConnection = CommonClientServer.NewSecureConnection(, New OSCertificationAuthorityCertificates);
	SetSafeModeDisabled(True);
	Join = New HTTPConnection(URIStructure.Host, URIStructure.Port,
		AccessParameters.Login, AccessParameters.Password,
		GetFilesFromInternet.GetProxy(URIStructure.Schema), 30, SecureConnection);
	SetSafeModeDisabled(False);
	
	Query = New HTTPRequest(ResourceAddress);
	Query.SetBodyFromString(JSONData);
	
	Response = Join.CallHTTPMethod("POST", Query);
	
	If Response.StatusCode = 401 Then
		Raise NStr("vi = 'Sai tên đăng nhập hoặc mật khẩu.';
					|ru = 'Неверный логин или пароль.';
					|en = 'Invalid credentials.'; fa = 'Invalid credentials.';
					|it = 'Nome utente o password non validi.';
					|pl = 'Błędny login lub hasło.';
					|tr = 'Hatalı kullanıcı adı veya parola.'");
	ElsIf Response.StatusCode <> 200 Then
		Template = NStr("vi = '""Không thể thực hiện yêu cầu, mã lỗi: %1';
						|ru = '""Не удалось выполнить запрос, код ошибки: %1';
						|en = '""Cannot run the query. Error code: %1'; fa = '""Cannot run the query. Error code: %1';
						|it = '""Richiesta non riuscita, codice di errore: %1';
						|pl = '""Wykonanie żądania nie powiodło się, kod błędu: %1';
						|tr = '""Sorgu gerçekleştirilemedi, hata kodu: %1'");
		Raise StrTemplate(Template, "" + Response.StatusCode + Chars.LF + Response.GetBodyAsString());
	EndIf;
	
	Result = JSONObject(Response.GetBodyAsString());
	
	If Result.general.error Then
		Raise Result.general.message;
	EndIf;
	
	Return Result;
	
EndFunction

// Performs a service check.
// It is used in the external processing of the transition to the service, which should work on the BTS from 1.2.2.
//
// Parameters:
//	ServerName - String - server name.
//	APIAddress - String - output parameter.
//	RegistrationAddress - String - output parameter.
//	RecoveryAddress - String - output parameter.
//	RegistrationAllowed - Boolean - output parameter. 
// Returns:
//   Boolean - True - if it supports migration.
//
Function ServiceSupportsMigration(ServerName, APIAddress, RegistrationAddress, RecoveryAddress, RegistrationAllowed) Export
	
	SecureConnection = CommonClientServer.NewSecureConnection(, New OSCertificationAuthorityCertificates);
	SetSafeModeDisabled(True);
	Join = New HTTPConnection(ServerName, , , , GetFilesFromInternet.GetProxy("https"), 30, SecureConnection);
	SetSafeModeDisabled(False);
	
	Query = New HTTPRequest("/info/hs/migration/info");
	
	Try
		Response = Join.CallHTTPMethod("GET", Query);
	Except
		Template = NStr("vi = 'Dịch vụ tạm thời không thể truy cập hoặc không hỗ trợ di chuyển,
                       |mô tả lỗi:
                       |%1';
                       |ru = 'Сервис временно недоступен или не поддерживает миграцию,
                       |описание ошибки:
                       |%1';
                       |en = 'Service temporarily unavailable or does not support migration.
                       |Error details:
                       |%1'; fa = 'Service temporarily unavailable or does not support migration.
                       |Error details:
                       |%1';
                       |it = 'Il servizio è temporaneamente non disponibile o non supporta la migrazione, 
                       |la descrizione dell''errore: 
                       |%1';
                       |pl = 'Usługa jest tymczasowo niedostępna lub nie obsługuje migrację,
                       |opis błędu:
                       |%1';
                       |tr = 'Hizmet geçici olarak kullanılamıyor veya geçişi desteklemiyor,
                       |hata açıklaması:
                       |%1'");
		Common.MessageToUser(
			StrTemplate(Template, CloudTechnology.ShortErrorText(ErrorInfo())));
		Return False;
	EndTry;
	
	If Response.StatusCode <> 200 Then
		Common.MessageToUser(NStr("vi = 'Dịch vụ không hỗ trợ di chuyển';
									|ru = 'Сервис не поддерживает миграцию';
									|en = 'Service does not support migration'; fa = 'Service does not support migration';
									|it = 'Il servizio non supporta la migrazione';
									|pl = 'Serwis nie obsługuje migrację';
									|tr = 'Servis geçişi desteklemiyor'"));
		Return False;
	EndIf;
	
	Try
		
		FreshParameters = JSONObject(Response.GetBodyAsString());
		
		If FreshParameters.enabled <> True Then
			Common.MessageToUser(NStr("vi = 'Dịch vụ không hỗ trợ di chuyển';
										|ru = 'Сервис не поддерживает миграцию';
										|en = 'Service does not support migration'; fa = 'Service does not support migration';
										|it = 'Il servizio non supporta la migrazione';
										|pl = 'Serwis nie obsługuje migrację';
										|tr = 'Servis geçişi desteklemiyor'"));
			Return False;
		EndIf;
		
		If FreshParameters.applications.Find(Metadata.Name) = Undefined Then
			Common.MessageToUser(NStr("vi = 'Dịch vụ không hỗ trợ di chuyển ứng dụng này';
										|ru = 'Сервис не поддерживает миграцию текущего приложения';
										|en = 'Service does not support migration of the current application'; fa = 'Service does not support migration of the current application';
										|it = 'Il servizio non supporta la migrazione dell''applicazione corrente';
										|pl = 'Serwis nie obsługuje migracji bieżącej aplikacji';
										|tr = 'Servis, mevcut uygulamanın geçişini desteklemiyor'"));		
			Return False;
		EndIf;
		
		APIAddress = FreshParameters.url_api;
		
	Except
		Common.MessageToUser(NStr("vi = 'Dịch vụ không hỗ trợ di chuyển';
									|ru = 'Сервис не поддерживает миграцию';
									|en = 'Service does not support migration'; fa = 'Service does not support migration';
									|it = 'Il servizio non supporta la migrazione';
									|pl = 'Serwis nie obsługuje migrację';
									|tr = 'Servis geçişi desteklemiyor'"));
		Return False;
	EndTry;
	
	RegistrationAddress = "";
	FreshParameters.Property("url_register", RegistrationAddress);
	
	RecoveryAddress = "";
	FreshParameters.Property("url_recover", RecoveryAddress);
	
	RegistrationAllowed = False;
	FreshParameters.Property("register_available", RegistrationAllowed);
	
	Return True;
	
EndFunction

// Gets the users of the service.
// It is used in the external processing of the transition to the service, which should work on the BTS from 1.2.2.
//
// Parameters:
//   SourceOfAccessParameters - ClientApplicationForm, Structure -
//
// Returns:
//   Array of Structure - LongDesc:
//     * Login - String -
//     * Description - String -
//     * Email - String -
//     * Role - See ApplicationsMigrationClientServer.RolePresentation
//
Function ServiceUsers(SourceOfAccessParameters) Export
	
	AccessParameters = GetAccessParameters(SourceOfAccessParameters);
	Method = "account/users/list";
	
	MethodParameters = New Structure;
	
	MethodParameters.Insert("auth", New Structure);
	MethodParameters.auth.Insert("account", AccessParameters.SubscriberCode);
	
	MethodParameters.Insert("general", New Structure);
	If Not MethodInAddressIsSupported(AccessParameters) Then
		MethodParameters.general.Insert("type", "ext");
		MethodParameters.general.Insert("method", Method);
	EndIf;
	MethodParameters.general.Insert("version", 3);
	
	MethodParameters.Insert("id", AccessParameters.SubscriberCode);
	
	CallResult = CallProgramInterfaceMethod(AccessParameters, MethodParameters, Method);
	
	ListOfServiceUsers = New Array;
	For Each UserData In CallResult.user Do
		
		SaaSUser = New Structure("Login, Description, Email, Role");
		SaaSUser.Login = UserData.login;
		SaaSUser.Description = UserData.name;
		SaaSUser.Email = UserData.email;
		SaaSUser.Role = ApplicationsMigrationClientServer.RolePresentation(UserData.role);
		
		ListOfServiceUsers.Add(SaaSUser);
		
	EndDo;
	
	Return ListOfServiceUsers;
	
EndFunction

// Creates an application for migration in the service.
//
// Parameters:
//   SourceOfAccessParameters - ClientApplicationForm, Structure -
//   Description - String - Name of the application.
//   TimeZone - String - the app's time zone.
//   UsersRights - ValueTable - table with columns:
//     * Login - String - username of the service user.
//     * User - CatalogRef.Users - the user that the service user will be linked to.
//     * Right - String - See ApplicationsMigrationClientServer.APIID.
//   RecoveryExtensions - ValueTable - table with columns:
//     * Name - String
//     * Version - String 
//
// Returns:
//   Structure - Keys:
//     * ApplicationURL - String - the url of the app.
//     * Login - String - username of the service user.
//     * Password - String - the service user's password.
//     * Code - Number - area code.
//
Function CreateMigrationApplication(SourceOfAccessParameters, Description, TimeZone, UsersRights, 
		RecoveryExtensions = Undefined) Export
	
	AccessParameters = GetAccessParameters(SourceOfAccessParameters);

	Rights = New Array;
	For Each TableRow In UsersRights Do
		If Not ValueIsFilled(TableRow.Right) Then
			Continue;
		EndIf;
		Right = New Structure("login, role, userid");
		Right.login = TableRow.Login;
		Right.role = ApplicationsMigrationClientServer.APIID(TableRow.Right);
		Right.userid = String(TableRow.User.UUID());
		Rights.Add(Right);
	EndDo;
	
	Method = "tenant/create_for_migration";
	
	MethodParameters = New Structure;
	
	MethodParameters.Insert("auth", New Structure);
	MethodParameters.auth.Insert("account", AccessParameters.SubscriberCode);
	
	MethodParameters.Insert("general", New Structure);
	If Not MethodInAddressIsSupported(AccessParameters) Then
		MethodParameters.general.Insert("type", "ext");
		MethodParameters.general.Insert("method", Method);
	EndIf;
	MethodParameters.general.Insert("version", 3);
	
	Extensions = New Array;
	If RecoveryExtensions <> Undefined And AccessParameters.SoftwareInterfaceVersion >= 24 Then
		MethodParameters.general.version = 24;
		For Each StringExtension In RecoveryExtensions Do
			Extensions.Add(New Structure("id, version", StringExtension.Name, StringExtension.Version));
		EndDo;
	EndIf;

	PlusExtensions = New Map();
	ExportImportDataInternal.FillInInstalledPlusExtensions(PlusExtensions);
	
	MigrationWithPlusExtensionsSupportedSinceVersion = 28;
	If AccessParameters.SoftwareInterfaceVersion < MigrationWithPlusExtensionsSupportedSinceVersion 
		And PlusExtensions.Count() > 0 Then
		ExtensionNames = New Array;
		For Each KeyValue In PlusExtensions Do
			ExtensionNames.Add(KeyValue.Value.ExtensionName);
		EndDo;
		
		Raise StrTemplate(NStr("vi = 'Bộ quản lý dịch vụ không hỗ trợ di chuyển với các phần mở rộng 1C:Plus
			|Đã cài đặt phần mở rộng: 
			|%1';
			|ru = 'Менеджер сервиса не поддерживает миграцию с расширениями 1С:Плюс
			|Установлены расширения: 
			|%1';
			|en = 'The service manager does not support migration with 1C:Plus extensions
			|Installed extensions:
			|%1'; fa = 'The service manager does not support migration with 1C:Plus extensions
			|Installed extensions:
			|%1';
			|it = 'Менеджер сервиса не поддерживает миграцию с расширениями 1С:Плюс
			|Установлены расширения: 
			|%1';
			|pl = 'The service manager does not support migration with 1C:Plus extensions
			|Installed extensions:
			|%1';
			|tr = 'Servis Yöneticisi, 1C:Plus uzantılarıyla geçişi desteklemiyor
			|Kurulu eklentiler: 
			|%1'"), StrConcat(ExtensionNames, Chars.LF));
	EndIf;
	
	For Each KeyValue In PlusExtensions Do
		ExtensionData = KeyValue.Value;
		ExtensionInfo = NewRecoveryExtension(
			ExtensionData.ExtensionName, 
			ExtensionData.ExtensionVersion, 
			ExtensionData.Extension_Id,
			ExtensionData.Extension_VersionId);
		
		Extensions.Add(ExtensionInfo);
	EndDo;
	
	If Extensions.Count() > 0 Then
		MethodParameters.Insert("extensions", Extensions);
	EndIf;
	
	MethodParameters.Insert("id", AccessParameters.SubscriberCode);
	MethodParameters.Insert("application", AppTypesServer.CurrentAppTypeName());
	MethodParameters.Insert("version", Metadata.Version);
	MethodParameters.Insert("name", Description);
	MethodParameters.Insert("timezone", TimeZone);
	MethodParameters.Insert("users", Rights);
	
	CallResult = CallProgramInterfaceMethod(AccessParameters, MethodParameters, Method);
	
	Result = New Structure;
	Result.Insert("ApplicationURL", CallResult.tenant.url);
	Result.Insert("Login", CallResult.tenant.login);
	Result.Insert("Password", CallResult.tenant.password);
	Result.Insert("Code", CallResult.tenant.id);
	
	Return Result;
	
EndFunction

// Retrieves data from the service organization in the service.
//
// Parameters:
//   SourceOfAccessParameters - ClientApplicationForm, Structure -
//
// Returns:
//   Structure - Keys:
//     * Code - Number
//     * Description - String
//     * Email - String 
//     * Phone - String
//     * ErrorDescription - String
//
Function ServiceOrganizationData(SourceOfAccessParameters) Export
	
	AccessParameters = GetAccessParameters(SourceOfAccessParameters);
	Method = "account/servant_info";
	
	MethodParameters = New Structure;
	
	MethodParameters.Insert("auth", New Structure);
	MethodParameters.auth.Insert("account", AccessParameters.SubscriberCode);
	
	MethodParameters.Insert("general", New Structure);
	If Not MethodInAddressIsSupported(AccessParameters) Then
		MethodParameters.general.Insert("type", "ext");
		MethodParameters.general.Insert("method", Method);
	EndIf;
	MethodParameters.general.Insert("version", 1);
	
	MethodParameters.Insert("id", AccessParameters.SubscriberCode);
	
	Result = New Structure("Code, Description, Email, Phone, ErrorDescription");
	
	Try
		
		CallResult = CallProgramInterfaceMethod(AccessParameters, MethodParameters, Method);
		
		Result.Code = CallResult.servant.id;
		Result.Description = CallResult.servant.name;
		Result.Email = CallResult.servant.email;
		Result.Phone = CallResult.servant.phone;
	
	Except
		
		Result.ErrorDescription = CloudTechnology.ShortErrorText(ErrorInfo());
		
	EndTry;
	
	Return Result;
	
EndFunction

// Registers in the service.
//
// Parameters:
//   ServerName - String - server name
//   Description - String - the name of the caller
//   Login - String -
//   Email - String - email address
//   Password - String -
//   Phone - String - subscriber's phone number
//
// Returns:
//   Boolean - the result of registration.
//
Function CreateAccount(ServerName, Description, Login, Email, Password, Phone) Export
	
	QueryOptions = New Structure;
	QueryOptions.Insert("name", Description);
	QueryOptions.Insert("login", Login);
	QueryOptions.Insert("email", Email);
	QueryOptions.Insert("password", Password);
	QueryOptions.Insert("phone", Phone);
	
	SecureConnection = CommonClientServer.NewSecureConnection(, New OSCertificationAuthorityCertificates);
	SetSafeModeDisabled(True);
	Join = New HTTPConnection(ServerName, , , , GetFilesFromInternet.GetProxy("https"), 30, SecureConnection);
	SetSafeModeDisabled(False);
	
	Query = New HTTPRequest("/info/hs/migration/register");
	Query.SetBodyFromString(ObjectInJSON(QueryOptions));
	
	Try
		Response = Join.CallHTTPMethod("POST", Query);
	Except
		Common.MessageToUser(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	If Response.StatusCode <> 200 Then
		Common.MessageToUser(StrTemplate(NStr("vi = 'Không thể thực hiện yêu cầu, mã phản hồi: %1';
												|ru = 'Не удалось выполнить запрос, код ответа: %1';
												|en = 'Cannot run the query, response code: %1'; fa = 'Cannot run the query, response code: %1';
												|it = 'Richiesta non riuscita, codice di risposta: %1';
												|pl = 'Wykonanie żądania nie powiodło się, kod odpowiedzi: %1';
												|tr = 'Sorgu gerçekleştirilemedi, cevap kodu: %1'"), Response.StatusCode));
		Return False;
	EndIf;
	
	Result = JSONObject(Response.GetBodyAsString());
	
	If Result.error Then
		Common.MessageToUser(Result.description);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Confirms registration in the service.
//
// Parameters:
//   ServerName - String - server name
//   ConfirmationCode - String - registration confirmation code
//
// Returns:
//   Boolean - the result of the registration confirmation.
//
Function ConfirmRegistration(ServerName, ConfirmationCode) Export
	
	QueryOptions = New Structure;
	QueryOptions.Insert("code", ConfirmationCode);
		
	SecureConnection = CommonClientServer.NewSecureConnection(, New OSCertificationAuthorityCertificates);
	SetSafeModeDisabled(True);
	Join = New HTTPConnection(ServerName, , , , GetFilesFromInternet.GetProxy("https"), 30, SecureConnection);
	SetSafeModeDisabled(False);
	
	Query = New HTTPRequest("/info/hs/migration/activation");
	Query.SetBodyFromString(ObjectInJSON(QueryOptions));
	
	Try
		Response = Join.CallHTTPMethod("POST", Query);
	Except
		Common.MessageToUser(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	If Response.StatusCode <> 200 Then
		Common.MessageToUser(StrTemplate(NStr("vi = 'Không thể thực hiện yêu cầu, mã phản hồi: %1';
												|ru = 'Не удалось выполнить запрос, код ответа: %1';
												|en = 'Cannot run the query, response code: %1'; fa = 'Cannot run the query, response code: %1';
												|it = 'Richiesta non riuscita, codice di risposta: %1';
												|pl = 'Wykonanie żądania nie powiodło się, kod odpowiedzi: %1';
												|tr = 'Sorgu gerçekleştirilemedi, cevap kodu: %1'"), Response.StatusCode));
		Return False;
	EndIf;
	
	Result = JSONObject(Response.GetBodyAsString());
	
	If Result.error Then
		Common.MessageToUser(Result.description);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

#Region DataTransferSubsystemIntegration

// Returns a description of the logical storage data.
//
// Parameters:
//  StorageID - String - ID of the logical storage.
//  DataID    - String - ID of the storage data.
// 
// Returns:
//   Structure - description of the State of the queue job:
//    * FileName - String - file name.
//    * Size - Number - file size in bytes.
//    * Data - BinaryData - binary data of the task description file.
//
Function LongDesc(StorageID, DataID) Export
	
	Result = New Structure("Success, Comment, ImportState", True, "");
	If DataID = "status" Then
		Result.ImportState = ImportState();
	ElsIf DataID = "remove-user" Then
		JobParameters = New Structure("MethodName", MethodNameDeleteTemporaryUser());
		FoundJobs = JobsQueue.GetJobs(JobParameters);
		If FoundJobs.Count() = 0 Then
			MethodParameters = New Array;
			MethodParameters.Add(InfoBaseUsers.CurrentUser().Name);
			JobParameters.Insert("Use", True);
			JobParameters.Insert("Parameters", MethodParameters);
			JobsQueue.AddJob(JobParameters);
		Else
			JobsQueue.ChangeJob(FoundJobs[0].Id, New Structure("ScheduledStartTime", CurrentSessionDate()));
		EndIf;
	Else
		Result.Success = False;
		Result.Comment = StrTemplate(NStr("vi = 'Không hỗ trợ tên định danh dữ liệu: %1.';
											|ru = 'Неподдерживаемый идентификатор данных: %1.';
											|en = 'Unsupported data ID: %1.'; fa = 'Unsupported data ID: %1.';
											|it = 'ID dati non supportato: %1';
											|pl = 'Nie obsługiwany identyfikator danych: %1.';
											|tr = 'Desteklenmeyen veri kimliği: %1.'"), DataID);
	EndIf;
	
	BinaryData = GetBinaryDataFromString(Common.ValueToXMLString(Result));
	
	LongDesc = New Structure;
    LongDesc.Insert("FileName", DataID);
    LongDesc.Insert("Size", BinaryData.Size());
    LongDesc.Insert("Data", BinaryData);
	
	Return LongDesc;
    
EndFunction

// Returns the logical data storage.
//
// Parameters:
//  DataDetails - Structure - description of storage data.
// 
// Returns:
//   BinaryData -
//
Function Data(DataDetails) Export
	
	Return DataDetails.Data;
	
EndFunction

// Writes data to logical storage.
// Performs actions:
// - saves the data file to the file storage
// - schedules the task queue for file processing tasks
// - returns the task id in the response.
//
// Returns:
//   Structure - Download State:
//   * id - Structure:
//    ** Success - Boolean
//    ** Comment - String
//    ** ImportState - See ImportState
//
Function Load(DataDetails) Export
	
	Result = New Structure("Success, Comment, ImportState", True, "");
	
	SetSafeModeDisabled(True);
	If DataDetails.FileName = "message" Then
		
		Try
			ImportMessage(DataDetails.Data);
		Except
			ErrorInfo = ErrorInfo();
			ErrorLogging(NStr("vi = 'Kết nhập thông điệp';
								|ru = 'Загрузка сообщения';
								|en = 'Message import'; fa = 'Message import';
								|it = 'Caricamento del messaggio';
								|pl = 'Pobieranie komunikatu';
								|tr = 'Mesaj içe aktarma'", Common.DefaultLanguageCode()), 
				CloudTechnology.DetailedErrorText(ErrorInfo));
			Result.Success = False;
			Result.Comment = CloudTechnology.ShortErrorText(ErrorInfo);
		EndTry;
	
	ElsIf DataDetails.FileName = "cancel" Then
		
		Try
			CancelDownload();
		Except
			Result.Success = False;
			Result.Comment = CloudTechnology.ShortErrorText(ErrorInfo());
		EndTry;
		
	ElsIf DataDetails.FileName = "confirm_reload" Then
		
		Try
			ConfirmReUpload();
		Except
			Result.Success = False;
			Result.Comment = CloudTechnology.ShortErrorText(ErrorInfo());
		EndTry;
		
	Else
		
		Result.Success = False;
		Result.Comment = StrTemplate(NStr("vi = 'Không hỗ trợ kết nhập tệp ""%1"".';
											|ru = 'Загрузка файла ""%1"" не поддерживается.';
											|en = 'Cannot import the ""%1"" file.'; fa = 'Cannot import the ""%1"" file.';
											|it = 'Caricamento di file ""%1"" non supportato.';
											|pl = 'Pobieranie pliku ""%1"" nie jest obsługiwane.';
											|tr = '""%1"" dosya içe aktarımı desteklenmiyor.'"), DataDetails.FileName);
			
	EndIf;
	SetSafeModeDisabled(False);
	
	Result.ImportState = ImportState();
	
    Return New Structure("id", Result);
	
EndFunction

#EndRegion

// The update handler
Procedure DeleteTemporaryUsers() Export

	AllUsers = InfoBaseUsers.GetUsers();
	For Each IBUser In AllUsers Do
		If IBUser.Name = "migration" And IBUser.DataSeparation.Property("DataAreaMainData") Then
			DataArea = Number(IBUser.DataSeparation.DataAreaMainData);
			RecordArea = InformationRegisters.DataAreas.CreateRecordManager();
			RecordArea.DataAreaAuxiliaryData = DataArea;
			RecordArea.Read();
			If RecordArea.Selected() And RecordArea.Status = Enums.DataAreaStatuses.Used Then
				IBUser.Delete();
			EndIf;
			
		EndIf;
	EndDo;
	
EndProcedure

Procedure DeleteTemporaryUser(Name) Export
	
	IBUser = InfoBaseUsers.FindByName(Name);
	If IBUser <> Undefined Then
		IBUser.Delete();
	EndIf;
	
	Filter = New Structure("MethodName", MethodNameDeleteTemporaryUser());
	For Each Job In JobsQueue.GetJobs(Filter) Do
		JobsQueue.DeleteJob(Job.Id);
	EndDo;
	
EndProcedure

// Get data of modified objects.
// 
// Parameters:
//  Node - ExchangePlanRef.ApplicationsMigration - Exchange plan sub-asset
// 
// Returns:
//  Structure - Data Of Modified Objects:
//  * ObjectsTable - ValueTable - Table of modified objects:
//     ** FullName - String - full name of the metadata object
//     ** ObjectCount - Number - Number of objects
//  * ObjectCount - Number - Number of modified objects
Function GetModifiedObjectsData(Node) Export
	
	ObjectsTable = New ValueTable();
	ObjectsTable.Columns.Add(
		"FullName",
		New TypeDescription("String", , New StringQualifiers(256, AllowedLength.Variable)));
	ObjectsTable.Columns.Add(
		"ObjectCount",
		New TypeDescription("Number", New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));
	
	Query = New Query();
	Query.SetParameter("Node", Node);
	
	QueriesTexts = ModifiedObjectsQueryTexts();
	
	For Each QueryText In QueriesTexts Do
		
		Query.Text = QueryText;
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			FillPropertyValues(ObjectsTable.Add(), Selection);
		EndIf;
		
	EndDo;
	
	Result = New Structure();
	Result.Insert("ObjectsTable", ObjectsTable);
	Result.Insert("ObjectCount", ObjectsTable.Total("ObjectCount"));
	
	Return Result;
	
EndFunction

Function MethodNameExportJob() Export
	
	Return "ApplicationsMigration.ExportJob";
	
EndFunction

Function MethodNameImportJob() Export
	
	Return "ApplicationsMigration.TaskLoading";

EndFunction

Function MethodNameDeleteTemporaryUser() Export
	
	Return "ApplicationsMigration.DeleteTemporaryUser";

EndFunction

#EndRegion

#Region Private

// Loads data from the folder.
//
// Parameters:
//   ImportDirectory - String - full name of the folder.
//   RefsMap - Map - a collection of old and new links that must be saved between calls.
//   ObjectsToClear - Map - a collection of fully qualified metadata names that must be saved between calls.
//
// Returns:
//   Structure - download result, keys:
//     * Success - Boolean -
//     * ObjectsImported - Number - Optional. The number of objects loaded.
//     * ThisIsLastMessage - Boolean - Optional. True if this is the last message.
//
Function LoadDataFromCatalog(ImportDirectory, RefsMap, ObjectsToClear)
	
	Manifest = ReadDataFromFile(ImportDirectory + "Manifest.xml");
	
	If AppTypesServer.AppTypePropertiesByName(Manifest.ConfigurationName, False) = Undefined Then
		Raise NStr("vi = 'Tên cấu hình không trùng khớp.';
					|ru = 'Имя конфигурации не совпадает.';
					|en = 'Configuration name does not match.'; fa = 'Configuration name does not match.';
					|it = 'Il nome della configurazione non corrisponde.';
					|pl = 'Nazwa konfiguracji nie jest zbieżna.';
					|tr = 'Konfigürasyon ismi eşleşmiyor.'");
	EndIf;
	
	ImportState = InformationRegisters.ApplicationsMigrationImportState.CreateRecordManager();
	ImportState.Read();
	AppTypeProperties = ImportState.ApplicationKind.Get();
	
	AppTypeName = AppTypesServer.BasicAppType().Name;
	If AppTypeProperties <> Undefined Then
		AppTypeName = AppTypeProperties.Name;
	EndIf;
	
	If Manifest.ConfigurationName <> AppTypeName Then
		Raise NStr("vi = 'Tên cấu hình không trùng khớp.';
					|ru = 'Имя конфигурации не совпадает.';
					|en = 'Configuration name does not match.'; fa = 'Configuration name does not match.';
					|it = 'Il nome della configurazione non corrisponde.';
					|pl = 'Nazwa konfiguracji nie jest zbieżna.';
					|tr = 'Konfigürasyon ismi eşleşmiyor.'");
	EndIf;
	
	If Manifest.ConfigurationVersion <> Metadata.Version Then
		// The message cannot be uploaded.
		Return New Structure("Success", False);		
	EndIf;
	
	ObjectsUnloadedCompletely = Undefined;
	If Manifest.Property("ObjectsUnloadedCompletely", ObjectsUnloadedCompletely) Then
		Template = NStr("vi = 'Không thể kết xuất đối tượng theo từng phần: %1.';
						|ru = 'Не удалось выгрузить порциями объекты: %1.';
						|en = 'Cannot export objects in portions: %1.'; fa = 'Cannot export objects in portions: %1.';
						|it = 'Impossibile caricare le porzioni di oggetti: %1.';
						|pl = 'Nie udało się przesłać porcjami obiekty: %1.';
						|tr = 'Yığınlanmış nesneler dışa aktarılamadı: %1.'", Common.DefaultLanguageCode());
		Comment = StrTemplate(Template, StrConcat(ObjectsUnloadedCompletely, ", "));
		ErrorLogging(NStr("vi = 'Kết nhập';
							|ru = 'Загрузка';
							|en = 'Import'; fa = 'ورود اطلاعات';
							|it = 'Scaricamento';
							|pl = 'Import';
							|tr = 'İçe aktarma'", Common.DefaultLanguageCode()), Comment);
	EndIf;
	
	ThisIsLastMessage = Manifest.ThisIsLastMessage;
	
	ImportParameters = ImportParameters(ImportDirectory, RefsMap, ObjectsToClear);
	
	ObjectsImported = UploadUserData_(ImportParameters);
	
	If ThisIsLastMessage Then
		
		UserWorkHistory.ClearAll();
		
		ClearUserData(ObjectsToClear);
		
		AddFullUsersToAdministratorsGroupAndUpdateRolesForOtherUsers();
		
		LoadSequenceBoundaries(ImportParameters);
		
		DownloadUserSettings(ReportsVariantsStorage, "ReportsVariantsStorage.xml", ImportParameters);
		DownloadUserSettings(FormDataSettingsStorage, "FormDataSettingsStorage.xml", ImportParameters);
		DownloadUserSettings(CommonSettingsStorage, "CommonSettingsStorage.xml", ImportParameters);
		DownloadUserSettings(DynamicListsUserSettingsStorage, "DynamicListsUserSettingsStorage.xml", ImportParameters);
		DownloadUserSettings(ReportsUserSettingsStorage, "ReportsUserSettingsStorage.xml", ImportParameters);
		DownloadUserSettings(SystemSettingsStorage, "SystemSettingsStorage.xml", ImportParameters);
		
		LoadCompositionOfStandardODataInterface(ImportDirectory);
		
		DownloadSubsystemVersions(ImportDirectory);
		
	EndIf;
	
	Return New Structure("Success, ObjectsImported, ThisIsLastMessage", True, ObjectsImported, ThisIsLastMessage);
	
EndFunction

// Uploads data to the specified folder.
//
// Parameters:
//   DumpDirectory - String - the full name of the directory where you want to upload.
//   ExchangeNode - ExchangePlanRef.ApplicationsMigration - the host to which the selected change.
//   MessageNo - Number - the message number is recorded in the manifest.
//   LastMetadataObject - String - the full name of the metadata object, if filled in,
//        loading will start from the next object.
//   ExportUserSettings - Map - collection of users whose settings need to be uploaded:
//     * Key - CatalogRef.Users - the user whose settings you want to upload.
//     * Value - String - new user login.
//   CompleteMigrationAutomatically - Boolean - indicates that an 
//        attempt will be made to set exclusive mode if necessary.
//
// Returns:
//   Structure - execution result, keys:
//     * MessageNo - Number -
//     * ConfigurationName - String -
//     * ConfigurationVersion - String -
//     * PlatformVersion - String -
//     * DurationSec - Number - 
//     * ObjectCount - Number - 
//     * ThisIsLastMessage - Number - 
//     * ObjectsUnloadedCompletely - Array - array of strings, optional.
//
Function UploadDataToFolder(DumpDirectory, ExchangeNode, MessageNo, LastMetadataObject, ExportUserSettings, CompleteMigrationAutomatically)
	
	BeginTime = CurrentUniversalDateInMilliseconds();
	
	DataDirectory = DumpDirectory + "Data" + GetPathSeparator();
	CreateDirectory(DataDirectory);
	
	ExportingParameters = ExportingParameters(DumpDirectory, DataDirectory, ExportUserSettings);
	
	ObjectsExported = UploadUserData(ExchangeNode, MessageNo, LastMetadataObject, ExportingParameters);
	
	ThisIsLastMessage = False;
	If ObjectsExported < ExportingParameters.DataChunkSize Then
		If CompleteMigrationAutomatically Then
			Try
				SetExclusiveMode(True);
			Except
				Comment = NStr("vi = 'Không thể thiết lập chế độ độc quyền.';
								|ru = 'Не удалось установить монопольный режим.';
								|en = 'Cannot enable exclusive mode.'; fa = 'Cannot enable exclusive mode.';
								|it = 'Impossibile stabilire la modalità esclusiva.';
								|pl = 'Nie udało się ustawić tryb wyłączności.';
								|tr = 'Özel mod ayarlanamadı.'", Common.DefaultLanguageCode());
				NoteRegistration(NStr("vi = 'Kết xuất';
										|ru = 'Выгрузка';
										|en = 'Export'; fa = 'خروج اطلاعات';
										|it = 'Upload';
										|pl = 'Export';
										|tr = 'Dışa aktarma'"), Comment);
			EndTry;
		EndIf;
		ThisIsLastMessage = CompleteMigrationAutomatically And ExclusiveMode() And ChangedCount(ExchangeNode) = 0;
	EndIf;
	
	If ThisIsLastMessage Then
		
		UnloadSequenceBoundaries(ExportingParameters);
		
		UploadUserSettings("ReportsVariantsStorage", ReportsVariantsStorage, "ReportsVariantsStorage.xml", ExportingParameters);
		UploadUserSettings("FormDataSettingsStorage", FormDataSettingsStorage, "FormDataSettingsStorage.xml", ExportingParameters);
		UploadUserSettings("CommonSettingsStorage", CommonSettingsStorage, "CommonSettingsStorage.xml", ExportingParameters);
		UploadUserSettings("DynamicListsUserSettingsStorage", DynamicListsUserSettingsStorage, "DynamicListsUserSettingsStorage.xml", ExportingParameters);
		UploadUserSettings("ReportsUserSettingsStorage", ReportsUserSettingsStorage, "ReportsUserSettingsStorage.xml", ExportingParameters);
		UploadUserSettings("SystemSettingsStorage", SystemSettingsStorage, "SystemSettingsStorage.xml", ExportingParameters);
		
		UnloadCompositionOfStandardODataInterface(DumpDirectory);
		
		UnloadSubsystemVersions(DumpDirectory);
		
	EndIf;
	
	UploadGeneralData(ExportingParameters);
		
	WriteDataToFile(ExportingParameters.Data, DumpDirectory + "Data.xml");
	WriteDataToFile(AllTheseNodes(), DumpDirectory + "ThisNodes.xml");
	
	SystemInfo = New SystemInfo;
	
	Manifest = New Structure;
	Manifest.Insert("MessageNo", MessageNo);
	Manifest.Insert("ConfigurationName", AppTypesServer.CurrentAppTypeName());
	Manifest.Insert("ConfigurationVersion", Metadata.Version);
	Manifest.Insert("PlatformVersion", SystemInfo.AppVersion);
	Manifest.Insert("DurationSec", (CurrentUniversalDateInMilliseconds() - BeginTime) / 1000);
	Manifest.Insert("ObjectCount", ObjectsExported);
	Manifest.Insert("ThisIsLastMessage", ThisIsLastMessage);
	
	If ExportingParameters.ObjectsUnloadedCompletely.Count() > 0 Then
		Manifest.Insert("ObjectsUnloadedCompletely", ExportingParameters.ObjectsUnloadedCompletely);
	EndIf;
	
	WriteDataToFile(Manifest, DumpDirectory + "Manifest.xml");
	
	Return Manifest;
	
EndFunction

// Puts a message in the queue.
//
// Parameters:
//   Source - Stream, String, BinaryData - Message data. 
//
// @unavailable-in-safemode
Procedure ImportMessage(Source)
	
	CheckSessionSharingUsage();
	SetPrivilegedMode(True);
	
	CheckIfDownloadIsInProgress();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	COUNT(*) AS DownloadQueue
	|FROM
	|	InformationRegister.ApplicationsMigrationImportQueue AS ApplicationsMigrationImportQueue";
	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.DownloadQueue >= MaximumLoadQueue() Then
		Raise StrTemplate(NStr("vi = 'Tải xuống hàng đợi lớn hơn %1';
								|ru = 'Очередь загрузки больше %1';
								|en = 'Import queue is more than %1'; fa = 'Import queue is more than %1';
								|it = 'Coda di scaricamento più di %1';
								|pl = 'Kolejność pobierania jest większa %1';
								|tr = 'İçe aktarma kuyruğu %1''ten/dan fazla'"), MaximumLoadQueue());
	EndIf;
	
	TemporaryStorageFileName = FilesCTL.NewTemporaryStorageFile("AppMigrationIn", "zip", 60);
	FileName = FilesCTL.FullTemporaryStorageFileName(TemporaryStorageFileName);
	
	If TypeOf(Source) = Type("String") Then
		MoveFile(Source, FileName);
	ElsIf TypeOf(Source) = Type("Stream")
		Or TypeOf(Source) = Type("MemoryStream") 
		Or TypeOf(Source) = Type("FileStream") Then 
		WriteStream = New FileStream(FileName, FileOpenMode.CreateNew);
		Source.CopyTo(WriteStream);
		WriteStream.Close();
	ElsIf TypeOf(Source) = Type("BinaryData") Then
		Source.Write(FileName);
	EndIf;
	
	ZipFileReader = New ZipFileReader(FileName);
	ZipFileEntry = ZipFileReader.Items.Find("Manifest.xml");
	If ZipFileEntry = Undefined Then
		Raise "vi = 'Không tìm thấy tệp Manifest.xml';
				|ru = 'Не найден файл Manifest.xml';
				|en = 'File Manifest.xml is not found.';
				|it = 'File Manifest.xml non trovato';
				|pl = 'Nie znaleziono pliku Manifest.xml';
				|tr = 'Manifest.xml dosyası bulunamadı'";
	EndIf;
	
	TempDirectory = GetTempFileName();
	CreateDirectory(TempDirectory);
	
	ZipFileReader.Extract(ZipFileEntry, TempDirectory, ZIPRestoreFilePathsMode.DontRestore);
	
	Manifest = ReadDataFromFile(TempDirectory + GetPathSeparator() + "Manifest.xml");
	
	Try
		DeleteFiles(TempDirectory);
	Except
		ErrorPresentation = CloudTechnology.DetailedErrorText(ErrorInfo());
		ErrorLogging(NStr("vi = 'Kết nhập';
							|ru = 'Загрузка';
							|en = 'Import'; fa = 'ورود اطلاعات';
							|it = 'Scaricamento';
							|pl = 'Import';
							|tr = 'İçe aktarma'", Common.DefaultLanguageCode()), ErrorPresentation);
	EndTry;
	
	If Manifest.ConfigurationVersion <> Metadata.Version Then
		Raise NStr("vi = 'Phiên bản cấu hình không trùng khớp.';
					|ru = 'Версия конфигурации не совпадает.';
					|en = 'Configuration version does not match.'; fa = 'Configuration version does not match.';
					|it = 'Versione della configurazione non corrisponde.';
					|pl = 'Wersja konfiguracji nie jest zbieżna.';
					|tr = 'Konfigürasyon sürümü eşleşmiyor.'");
	EndIf;
	
	MessageNo = Manifest.MessageNo;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ApplicationsMigrationImportQueue");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		RecordSet = InformationRegisters.ApplicationsMigrationImportQueue.CreateRecordSet();
		Record = RecordSet.Add();
		Record.Number = MessageNo;
		Record.FileName = TemporaryStorageFileName;
		RecordSet.Write(False);

		FilesCTL.SetTemporaryStorageFileRetentionPeriod(TemporaryStorageFileName, 60 * 24 * 2); // Two days
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Disables the download flag, and the download itself will be completed in the scheduled task.
//
// @unavailable-in-safemode
Procedure CancelDownload()
	
	CheckSessionSharingUsage();
	
	SetPrivilegedMode(True);
	BeginTransaction();
	Try	
		CheckIfDownloadIsInProgress();
		
		ScheduledJobsServer.DeleteJob(Metadata.ScheduledJobs.ApplicationsMigrationImport);
		
		DataAreaRecordset = InformationRegisters.DataAreas.CreateRecordSet();
		DataAreaRecordset.Read();
		DataAreaRecordset[0].Status = Enums.DataAreaStatuses.ForDeletion;
		DataAreaRecordset.Write();
		
		DeleteQueue();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns the download status.
// 
// Returns:
//   Structure - structure with keys:
//     * ConfigurationName - String - configuration name.
//     * ConfigurationVersion - String - configuration version.
//     * LoadingIsInProgress - Boolean - indicates that the download is in progress.
//     * ReceivedMessageNumber - Number - number of processed messages.
//     * ObjectsImported - Number - the number of objects loaded.
//     * CompletedWithErrors - Boolean - indicates completion with errors.
//     * ErrorDescription - String - error description.
//     * ResendingRequired - Boolean - True if you need to resend data that is currently
//                                             in the queue.
//
Function ImportState()
	
	CheckSessionSharingUsage();
	
	Status = New Structure();
	Status.Insert("ConfigurationName", Metadata.Name);
	Status.Insert("ConfigurationVersion", Metadata.Version);
	Status.Insert("LoadingIsInProgress", False);
	Status.Insert("ReceivedMessageNumber", 0);
	Status.Insert("ObjectsImported", 0);
	Status.Insert("CompletedWithErrors", False);
	Status.Insert("ErrorDescription", "");
	Status.Insert("ResendingRequired", False);
	
	ImportState = InformationRegisters.ApplicationsMigrationImportState.CreateRecordManager();
	ImportState.Read();
	If ImportState.Selected() Then
		FillPropertyValues(Status, ImportState);
		Status.LoadingIsInProgress = Not ValueIsFilled(ImportState.CompletedOn);
		If Not Status.LoadingIsInProgress Then
			MethodParameters = New Array;
			MethodParameters.Add(InfoBaseUsers.CurrentUser().Name);
			JobParameters = New Structure;
			JobParameters.Insert("MethodName", MethodNameDeleteTemporaryUser());
			JobParameters.Insert("Use", True);
			JobParameters.Insert("Parameters", MethodParameters);
			JobParameters.Insert("ScheduledStartTime", CurrentSessionDate() + 86400);
			JobsQueue.AddJob(JobParameters);
		EndIf;
	EndIf;
	
	Return Status;
	
EndFunction

// Returns the size of the data portion.
//
// Returns:
//   Number - serving size.
//
Function DataChunkSize() Export
	
	Return 10000;
	
EndFunction

// Returns the download status from the service.
//
// Returns:
//   Structure - description See ImportState
//               ().
//
Function DownloadStateFromService(AccessParameters)
	
	Result = DataTransferServer.GetFromLogicalStorage(AccessParameters, "migration", "status");
	
	If Result = Undefined Then
		Raise NStr("vi = 'Không thể nhận trạng thái.';
					|ru = 'Не удалось получить статус.';
					|en = 'Cannot receive a status.'; fa = 'Cannot receive a status.';
					|it = 'Non è stato possibile ottenere il status.';
					|pl = 'Nie udało się uzyskać statusu.';
					|tr = 'Durum alınamadı.'");
	EndIf;
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(Result.FullName);
	ImportState = XDTOSerializer.ReadXML(XMLReader);
	XMLReader.Close();
	
	Try
		DeleteFiles(Result.FullName);
	Except
		ErrorPresentation = CloudTechnology.DetailedErrorText(ErrorInfo());
		ErrorLogging(NStr("vi = 'Kết xuất';
							|ru = 'Выгрузка';
							|en = 'Export'; fa = 'خروج اطلاعات';
							|it = 'Upload';
							|pl = 'Export';
							|tr = 'Dışa aktarma'", Common.DefaultLanguageCode()), ErrorPresentation);
	EndTry;
	
	If ImportState.Success Then
		Return ImportState.ImportState;
	Else
		Raise ImportState.Comment;
	EndIf;
	
EndFunction

// Sends the generated message to the service.
//  
// Parameters:
//   AccessParameters - Structure - description See DataTransferServer.SendToLogicalStorage
//                                  ().
//   FileName - String - name of the zip file.
//
// Returns:
//   Structure - description See ImportState
//               ().
//
Function SendMessageToService(AccessParameters, FileName)
	
	Result = DataTransferServer.SendToLogicalStorage(AccessParameters, "migration", FileName, "message");
	
	If Result = Undefined Then
		Raise NStr("vi = 'Không thể gửi tin nhắn.';
					|ru = 'Не удалось отправить сообщение.';
					|en = 'Cannot send the message.'; fa = 'Cannot send the message.';
					|it = 'Non è stato possibile inviare messaggio.';
					|pl = 'Nie udało się wysłać komunikat.';
					|tr = 'Mesaj gönderilemedi.'");
	ElsIf Not Result.Success Then
		Raise Result.Comment;
	Else 
		Return Result.ImportState;
	EndIf;
	
EndFunction

// Cancels the download in the service.
//  
// Parameters:
//   AccessParameters - Structure - description See DataTransferServer.SendToLogicalStorage
//   ().
//                                  File name - String - name of the zip file.
//
// Returns:
//   Structure - description See ImportState
//               ().
//
Function CancelDownloadInService(AccessParameters)
	
	Result = DataTransferServer.SendToLogicalStorage(AccessParameters, "migration", GetBinaryDataFromString("cancel"), "cancel");
	
	If Result = Undefined Then
		Raise NStr("vi = 'Không thể hủy bỏ kết nhập trong dịch vụ.';
					|ru = 'Не удалось отменить загрузку в сервисе.';
					|en = 'Cannot cancel import in the service.'; fa = 'Cannot cancel import in the service.';
					|it = 'Impossibile annullare il download nel servizio.';
					|pl = 'Nie udało się anulować pobieranie w serwisie.';
					|tr = 'Serviste içe aktarma iptal edilemedi.'");
	EndIf;
	
	If Result.Success Then
		Return Result.ImportState;
	Else
		Raise Result.Comment;
	EndIf;
	
EndFunction

// Confirms the re-upload in the service.
//  
// Parameters:
//   AccessParameters - Structure - description See DataTransferServer.SendToLogicalStorage
//   ().
//                                  File name - String - name of the zip file.
//
// Returns:
//   Structure - description See ImportState
//               ().
//
Function ConfirmReloadingInService(AccessParameters)
	
	Result = DataTransferServer.SendToLogicalStorage(AccessParameters, "migration", GetBinaryDataFromString("confirm_reload"), "confirm_reload");
	
	If Result = Undefined Then
		Raise NStr("vi = 'Không thể xác nhận kết nhập lại trong dịch vụ.';
					|ru = 'Не удалось подтвердить повторную загрузку в сервисе.';
					|en = 'Cannot confirm reimport in the service.'; fa = 'Cannot confirm reimport in the service.';
					|it = 'Impossibile confermare nuovamente il download nel servizio.';
					|pl = 'Nie udało się potwierdzić ponowne pobieranie w serwisie.';
					|tr = 'Serviste tekrardan içe aktarma onaylanamadı.'");
	EndIf;
	
	If Result.Success Then
		Return Result.ImportState;
	Else
		Raise Result.Comment;
	EndIf;
	
EndFunction

// Returns the parameters required for uploading.
//
// Parameters:
//   DumpDirectory - String - the full name of the directory that you are uploading.
//   DataDirectory - String - the full name of the folder to which data is uploaded is always the "Data"
//                            folder in the upload folder.
//   ExportUserSettings - Map - a collection of users whose settings need to be uploaded.
//
// Returns:
//   Structure - structure with keys:
//     * DumpDirectory - String - the full name of the directory that you are uploading.
//     * DataDirectory - String - the full name of the folder to which data is uploaded is always the "Data"
//                                folder in the upload folder.
//     * ExportUserSettings - Map - a collection of users whose settings need to be uploaded.
//     * Data - See DataTable
//     * GeneralDataLinks - Map of KeyAndValue - collection of all common links that will be discovered:
//       ** Key - CatalogRef
//       ** Value - Boolean - True
//     * TypesOfSharedDataToBeMatchedBySearchFields - See ApplicationsMigrationCached.TypesOfSharedDataToBeMatchedBySearchFields
//     * TypesOfMappedSharedDataByPredefinedName - See ApplicationsMigrationCached.TypesOfMappedSharedDataByPredefinedName
//     * ProhibitedTypesOfSharedData - See ApplicationsMigrationCached.ProhibitedTypesOfSharedData
//     * CatalogsFiles_ - See FilesOperationsInternalSaaSCached.FilesCatalogsAndStorageOptionObjects
//     * DataChunkSize - Number
//     * ObjectsUnloadedCompletely - Array
//
Function ExportingParameters(DumpDirectory, DataDirectory, ExportUserSettings)
	
	ExportingParameters = New Structure;
	ExportingParameters.Insert("DumpDirectory", DumpDirectory);
	ExportingParameters.Insert("DataDirectory", DataDirectory);
	ExportingParameters.Insert("ExportUserSettings", ExportUserSettings);
	ExportingParameters.Insert("Data", DataTable());
	ExportingParameters.Insert("GeneralDataLinks", New Map);
	ExportingParameters.Insert("TypesOfSharedDataToBeMatchedBySearchFields", ApplicationsMigrationCached.TypesOfSharedDataToBeMatchedBySearchFields());
	ExportingParameters.Insert("TypesOfMappedSharedDataByPredefinedName", ApplicationsMigrationCached.TypesOfMappedSharedDataByPredefinedName());
	ExportingParameters.Insert("ProhibitedTypesOfSharedData", ApplicationsMigrationCached.ProhibitedTypesOfSharedData());
	ExportingParameters.Insert("CatalogsFiles_", FilesOperationsInternalSaaSCached.FilesCatalogsAndStorageOptionObjects());
	ExportingParameters.Insert("DataChunkSize", DataChunkSize());
	ExportingParameters.Insert("ObjectsUnloadedCompletely", New Array);
	ExportingParameters.Insert("Serializer", New XDTOSerializer(GetFactoryWithTypesSpecified()));
	
	Return ExportingParameters;
	
EndFunction

Function GetFactoryWithTypesSpecified()
	
	Types = ExportImportDataInternalEvents.GetTypesThatRequireAnnotationOfLinksWhenUnloading();
	
	SetOfSchemes = XDTOFactory.ExportXMLSchema("http://v8.1c.ru/8.1/data/enterprise/current-config");
	Schema = SetOfSchemes[0];
	Schema.UpdateDOMElement();
	
	SpecifiedTypes = New Map;
	For Each Type In Types Do
		SpecifiedTypes.Insert(XMLType(Type.StandardAttributes.Ref.Type.Types()[0]).TypeName, True);
	EndDo;
	
	Namespace = New Map;
	Namespace.Insert("xs", "http://www.w3.org/2001/XMLSchema");
	DOMNamespaceResolver = New DOMNamespaceResolver(Namespace);
	XPathText = "/xs:schema/xs:complexType/xs:sequence/xs:element[starts-with(@type,'tns:')]";
	
	Query = Schema.DOMDocument.CreateXPathExpression(XPathText,
		DOMNamespaceResolver);
	Result = Query.Evaluate(Schema.DOMDocument);

	While True Do
		
		FieldNode_ = Result.IterateNext();
		If FieldNode_ = Undefined Then
			Break;
		EndIf;
		AttributeType = FieldNode_.Attributes.GetNamedItem("type");
		TypeWithoutNSPrefix = Mid(AttributeType.TextContent, StrLen("tns:") + 1);
		
		If SpecifiedTypes.Get(TypeWithoutNSPrefix) = Undefined Then
			Continue;
		EndIf;
		
		FieldNode_.SetAttribute("nillable", "true");
		FieldNode_.RemoveAttribute("type");
	EndDo;
	
	SchemaWithTypeAnnotation = GetTempFileName("xsd");
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(SchemaWithTypeAnnotation);
	DOMWriter = New DOMWriter;
	DOMWriter.Write(Schema.DOMDocument, XMLWriter);
	XMLWriter.Close();
	
	Factory = CreateXDTOFactory(SchemaWithTypeAnnotation);
	
	Return Factory;
	
EndFunction

// Uploads the data registered in the exchange plan.
//
// Parameters:
//   ExchangeNode - ExchangePlanRef.ApplicationsMigration - the exchange node where the changes are selected.
//   Loading statesrecording register.Migrationapplicationstates of loading - State of unloading.
//   ExportingParameters - Structure - description See ExportingParameters
//                                   ().
//
// Returns:
//   Number - the number of unloaded objects.
//
Function UploadUserData(ExchangeNode, MessageNo, LastMetadataObject, ExportingParameters)
	
	UploadStartTemplate = NStr("vi = 'Kết xuất đối tượng: %1';
								|ru = 'Выгрузка объекта: %1';
								|en = 'Exporting object: %1'; fa = 'Exporting object: %1';
								|it = 'Upload oggetto: %1';
								|pl = 'Przesyłanie obiektu: %1';
								|tr = 'Nesneyi dışa aktarma:%1'", Common.DefaultLanguageCode());
	TemplateEndOfUpload = NStr("vi = 'Đã kết xuất đối tượng: %1, Số lượng: %2, Thời lượng (giây): %3';
								|ru = 'Выгружен объект: %1, Количество: %2, Длительность (сек): %3';
								|en = 'Exported object: %1, Quantity: %2, Duration (sec): %3'; fa = 'Exported object: %1, Quantity: %2, Duration (sec): %3';
								|it = 'Oggetto scaricato: %1, Quantità: %2, Durata (sec): %3';
								|pl = 'Został przesłany obiekt: %1, Ilość: %2, Czas trwania (sek): %3';
								|tr = 'Nesne dışa aktarıldı: %1, Miktar: %2, Süre (san): %3'", Common.DefaultLanguageCode());
	TotalObjectCount = 0;
	LeftToExport = ExportingParameters.DataChunkSize;
	For Each MetadataObject In MetadataSamplingOrder(LastMetadataObject) Do
		
		Comment = StrTemplate(UploadStartTemplate, MetadataObject.FullName());
		NoteRegistration(NStr("vi = 'Thống kê kết xuất';
								|ru = 'Статистика выгрузки';
								|en = 'Export statistics'; fa = 'Export statistics';
								|it = 'Statistiche di scarico';
								|pl = 'Statystyka wysłania';
								|tr = 'Dışa aktarma istatistiği'"), Comment);
		
		Begin = CurrentUniversalDateInMilliseconds();
		
		If Metadata.Constants.Contains(MetadataObject) Then
			
			ObjectsExported = UnloadConstant(MetadataObject, ExchangeNode, MessageNo, ExportingParameters);
			
		ElsIf Metadata.Catalogs.Contains(MetadataObject) 
			Or Metadata.Documents.Contains(MetadataObject) 
			Or Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject)
			Or Metadata.ChartsOfAccounts.Contains(MetadataObject)
			Or Metadata.ChartsOfCalculationTypes.Contains(MetadataObject)
			Or Metadata.Tasks.Contains(MetadataObject) 
			Or Metadata.BusinessProcesses.Contains(MetadataObject) Then
			
			ObjectsExported = UnloadReferenceType(MetadataObject, ExchangeNode, MessageNo, LeftToExport, ExportingParameters);
			
		ElsIf Metadata.InformationRegisters.Contains(MetadataObject)
			Or Metadata.AccumulationRegisters.Contains(MetadataObject) 
			Or Metadata.CalculationRegisters.Contains(MetadataObject) 
			Or Metadata.CalculationRegisters.Contains(MetadataObject.Parent())
			Or Metadata.AccountingRegisters.Contains(MetadataObject) 
			Or Metadata.Sequences.Contains(MetadataObject) Then
			
			ObjectsExported = UploadSetOfRecords(MetadataObject, ExchangeNode, MessageNo, LeftToExport, ExportingParameters);
			
		Else
			
			RaiseExceptionUnknownMetadataObject(MetadataObject);
			
		EndIf;
		
		Duration = (CurrentUniversalDateInMilliseconds() - Begin) / 1000;
		Comment = StrTemplate(TemplateEndOfUpload, MetadataObject.FullName(), ObjectsExported, XDTOSerializer.XMLString(Duration));
		NoteRegistration(NStr("vi = 'Thống kê kết xuất';
								|ru = 'Статистика выгрузки';
								|en = 'Export statistics'; fa = 'Export statistics';
								|it = 'Statistiche di scarico';
								|pl = 'Statystyka wysłania';
								|tr = 'Dışa aktarma istatistiği'"), Comment);
		
		TotalObjectCount = TotalObjectCount + ObjectsExported;
		LeftToExport = ExportingParameters.DataChunkSize - TotalObjectCount;
				
		// Limit the portion by the number of records.
		If LeftToExport <= 0 Then
			Break;
		EndIf;
		
	EndDo;
	
	LastMetadataObject = MetadataObject.FullName();
	
	Return TotalObjectCount;
	
EndFunction

// Unloads a constant.
//
// Parameters:
//   MetadataObject - MetadataObjectConstant - the object that you want to upload.
//   Node - ExchangePlanRef.ApplicationsMigration - the exchange node for selecting changes.
//   ExportingParameters - See ExportingParameters
//
// Returns:
//   Number - the number of unloaded objects.
//
Function UnloadConstant(MetadataObject, Node, MessageNo, ExportingParameters)
	
	Query = New Query;
	Query.SetParameter("Node", Node);
	Query.Text = StrReplace(
	"SELECT TOP 1
	|	TRUE AS Validation
	|FROM
	|	TableName AS Changes
	|WHERE
	|	Changes.Node = &Node
	|	AND Changes.MessageNo IS NULL", "TableName", MetadataObject.FullName() + "." + "Changes");
	If Query.Execute().IsEmpty() Then
		Return 0;
	EndIf;
	
	DataSelection = ExchangePlans.SelectChanges(Node, MessageNo, MetadataObject);
	If Not DataSelection.Next() Then
		Return 0;
	EndIf;
	
	Id = GenerateFileName(ExportingParameters.DataDirectory, ExportingParameters.Data.Count());
	
	Object = DataSelection.Get();
	
	Cancel = False;
	ApplicationsMigrationOverridable.OnExportObject(Object, Cancel);
	If Cancel Then
		Return 0;
	EndIf;
	
	If TypeOf(Object.Value) = Type("ValueStorage") Then
		UnloadValueStore(Object.Value, Id, 0, ExportingParameters);
	EndIf;
	
	WriteDataToFile(Object, ExportingParameters.DataDirectory + Id + ".xml");
	
	AddAuxiliaryDataFromXMLFile(ExportingParameters.DataDirectory + Id + ".xml", ExportingParameters);
	
	TableRow = ExportingParameters.Data.Add();
	TableRow.MetadataObject = MetadataObject.FullName();
	TableRow.Id = Id;
	TableRow.RecordsCount = 1;
	
	Return 1;
	
EndFunction

// Unloads the reference object.
//
// Parameters:
//   MetadataObject - MetadataObjectCatalog, MetadataObjectDocument - 
//                    - MetadataObjectChartOfCharacteristicTypes, MetadataObjectChartOfAccounts -
//                    - MetadataObjectChartOfCalculationTypes, MetadataObjectTask -
//                    - MetadataObjectBusinessProcess - the object that you want to upload.
//   Node - ExchangePlanRef.ApplicationsMigration - the exchange node for selecting changes.
//   ExportingParameters - Structure - description See ExportingParameters
//                                   ().
//
// Returns:
//   Number - the number of unloaded objects.
//
Function UnloadReferenceType(MetadataObject, Node, MessageNo, LeftToExport, ExportingParameters)

	TableName = MetadataObject.FullName();
	
	Query = New Query;
	Query.SetParameter("Node", Node);
	Query.Text = 
	"SELECT TOP 1
	|	Changes.Ref AS Ref
	|FROM
	|	TableName AS Changes
	|WHERE
	|	Changes.Node = &Node
	|	AND Changes.MessageNo IS NULL";
	Query.Text = StrReplace(Query.Text, "1", Format(LeftToExport, "NG=0"));
	Query.Text = StrReplace(Query.Text, "TableName", StrTemplate("%1.%2", TableName, "Changes"));
	
	SelectionFilter = Query.Execute().Unload().UnloadColumn(0);
	
	If SelectionFilter.Count() = 0 Then
		Return 0;
	EndIf;
	
	HandlerFiles_ = ExportingParameters.CatalogsFiles_.CatalogsFiles_[TableName];
	IsFilesCatalog = HandlerFiles_ <> Undefined;
	If IsFilesCatalog Then
		HandlerFiles_ = Common.CommonModule(HandlerFiles_);
		FilesCount = 0;
	EndIf;
	
	NumberOfStorageFiles = 0;
	StorageDetails = StorageDetails(MetadataObject.Attributes);
	If IsFilesCatalog Then
		StorageDetails.Delete(StorageDetails.Find("FileStorage"));
	EndIf;
	
	TabularPartsWithStorage = New Structure;
	For Each TabularSection In MetadataObject.TabularSections Do // MetadataObject
		Attributes = StorageDetails(TabularSection.Attributes);
		If Attributes.Count() Then
			TabularPartsWithStorage.Insert(MetadataObjectName(TabularSection), Attributes);
		EndIf;
	EndDo;
	
	Id = GenerateFileName(ExportingParameters.DataDirectory, ExportingParameters.Data.Count());
	FileName = Id + ".xml";
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(ExportingParameters.DataDirectory + FileName);
	XMLWriter.WriteStartElement("Data");
	RecordCorrespondenceOfNamespaces(XMLWriter);
	
	ObjectCount = 0;
	
	DataSelection = ExchangePlans.SelectChanges(Node, MessageNo, SelectionFilter);
	While DataSelection.Next() Do
		
		Object = DataSelection.Get();
		
		Cancel = False;
		ApplicationsMigrationOverridable.OnExportObject(Object, Cancel);
		If Cancel Then
			Continue;
		EndIf;
		
		ObjectCount = ObjectCount + 1;
		
		If TypeOf(Object) <> Type("ObjectDeletion") Then
		
			For Each Attribute In StorageDetails Do
				UnloadValueStore(Object[Attribute], Id, NumberOfStorageFiles, ExportingParameters);
			EndDo;
			
			If IsFilesCatalog And Not Object.IsFolder Then
				FilesDirectory = ExportingParameters.DataDirectory + Id + "-files";
				AttachmentFileName = GenerateFileName(FilesDirectory, FilesCount) + ".bin";
				Object.Volume = Undefined;
				FullNameOfAttachmentFile = FilesDirectory + GetPathSeparator() + AttachmentFileName;
				Try
					HandlerFiles_.ExportFile(Object, FullNameOfAttachmentFile);
					Object.FileStorage = New ValueStorage(AttachmentFileName);
				Except
					Object.FileStorage = Undefined;
					ErrorLogging(
						NStr("vi = 'Kết xuất danh mục tệp';
							|ru = 'Выгрузка справочника файлов';
							|en = 'Export file catalog'; fa = 'Export file catalog';
							|it = 'Caricamento directory dei file';
							|pl = 'Eksport katalogu plików';
							|tr = 'Dosya kataloğu dışa aktarma'", Common.DefaultLanguageCode()),
						DetailErrorDescription(ErrorInfo()),
						Object.Metadata(),
						Object.Ref);
					Info = New File(FullNameOfAttachmentFile);
					If Info.Exists() Then
						DeleteFiles(FullNameOfAttachmentFile);
					EndIf;
				EndTry;
			EndIf;
			
			For Each TabularSection In TabularPartsWithStorage Do
				For Each LineOfATabularSection In Object[TabularSection.Key] Do
					For Each Attribute In TabularSection.Value Do
						UnloadValueStore(LineOfATabularSection[Attribute], Id, NumberOfStorageFiles, ExportingParameters);
					EndDo;
				EndDo;
			EndDo;
			
		EndIf;
		
		ExportingParameters.Serializer.WriteXML(XMLWriter, Object, "Object", XMLTypeAssignment.Explicit);
		
	EndDo;
	
	XMLWriter.WriteEndElement();
	XMLWriter.Close();
		
	If ObjectCount = 0 Then
		
		DeleteFiles(ExportingParameters.DataDirectory + FileName);
		
	Else
		
		AddAuxiliaryDataFromXMLFile(ExportingParameters.DataDirectory + FileName, ExportingParameters);
				
		TableRow = ExportingParameters.Data.Add();
		TableRow.MetadataObject = TableName;
		TableRow.Id = Id;
		TableRow.RecordsCount = ObjectCount;
		
	EndIf;
	
	Return ObjectCount;
	
EndFunction

// Unloads a set of records.
//
// Parameters:
//   MetadataObject - MetadataObject - Data register, accumulation Register, calculation Register, 
//	   bookshelf Register, Sequence - the object to be unloaded.
//   Node - ExchangePlanRef.ApplicationsMigration - the exchange node for selecting changes.
//   MessageNo - Number - number of the upload message. 
//   LeftToExport - Number - 
//   ExportingParameters - Structure - See ExportingParameters().
//
// Returns:
//   Number - the number of unloaded objects.
//
Function UploadSetOfRecords(MetadataObject, Node, MessageNo, LeftToExport, ExportingParameters) Export
	
	TableName = MetadataObject.FullName();
	
	FilterChanges = FilterRecordSetChanges(MetadataObject, Node, LeftToExport);
	
	If TypeOf(FilterChanges) = Type("Array") And FilterChanges.Count() = 0 Then
		Return 0;
	EndIf;
	
	If Metadata.Sequences.Contains(MetadataObject) 
		Or Metadata.CalculationRegisters.Contains(MetadataObject.Parent()) Then
		
		StorageDetails = New Array;
		
	Else 
		
		StorageDetails = StorageDetails(MetadataObject.Attributes);
		For Each Attribute In StorageDetails(MetadataObject.Resources) Do
			StorageDetails.Add(Attribute);
		EndDo;
		
	EndIf;
	
	NumberOfStorageFiles = 0;
	
	Id = GenerateFileName(ExportingParameters.DataDirectory, ExportingParameters.Data.Count());
	FileName = Id + ".xml";
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(ExportingParameters.DataDirectory + FileName);
	XMLWriter.WriteStartElement("Data");
	RecordCorrespondenceOfNamespaces(XMLWriter);
	
	ObjectCount = 0;
	
	While True Do
		// The filter size may be smaller than the portion size, so there is a cycle here.
		DataSelection = ExchangePlans.SelectChanges(Node, MessageNo, FilterChanges);
		
		// Temporary bypass of the platform error: some data registers cannot be unloaded in chunks.
		If TypeOf(FilterChanges) = Type("Array") Then
			If Not DataSelection.Next() Then
				ExportingParameters.ObjectsUnloadedCompletely.Add(MetadataObject.FullName());
				DataSelection = ExchangePlans.SelectChanges(Node, MessageNo, MetadataObject);
			Else
				DataSelection.Reset();
			EndIf;
		EndIf;
		
		While DataSelection.Next() Do
			
			ObjectCount = ObjectCount + 1;
			
			Object = DataSelection.Get();
			
			Cancel = False;
			ApplicationsMigrationOverridable.OnExportObject(Object, Cancel);
			If Cancel Then
				Continue;
			EndIf;
			
			If TypeOf(Object) <> Type("ObjectDeletion") And StorageDetails.Count() Then
				For Each Record In Object Do
					For Each Attribute In StorageDetails Do
						UnloadValueStore(Record[Attribute], Id, NumberOfStorageFiles, ExportingParameters);
					EndDo;
				EndDo;
			EndIf;
			
			ExportingParameters.Serializer.WriteXML(XMLWriter, Object, "Object", XMLTypeAssignment.Explicit);
			
		EndDo;
		
		If TypeOf(FilterChanges) = Type("MetadataObject")
			Or ObjectCount >= LeftToExport Then
			Break;
		EndIf;
		
		FilterChanges = FilterRecordSetChanges(MetadataObject, Node, LeftToExport - ObjectCount);
		
		If TypeOf(FilterChanges) = Type("Array") And FilterChanges.Count() = 0 Then
			Break;
		EndIf;
		
	EndDo;
	
	XMLWriter.WriteEndElement();
	XMLWriter.Close();
		
	If ObjectCount = 0 Then
		
		DeleteFiles(ExportingParameters.DataDirectory + FileName);
		
	Else
		
		AddAuxiliaryDataFromXMLFile(ExportingParameters.DataDirectory + FileName, ExportingParameters);
		
		TableRow = ExportingParameters.Data.Add();
		TableRow.MetadataObject = TableName;
		TableRow.Id = Id;
		TableRow.RecordsCount = ObjectCount;
		
	EndIf;
	
	Return ObjectCount;
	
EndFunction

// Returns a change filter for a set of records.
//
// Parameters:
//   MetadataObject - MetadataObject -
//   Node - ExchangePlanRef.ApplicationsMigration -
//   LeftToExport - Number -
//
// Returns:
//   Array of MetadataObject -
//
Function FilterRecordSetChanges(MetadataObject, Node, LeftToExport)
	
	If Metadata.CalculationRegisters.Contains(MetadataObject.Parent()) Then
		TableName = StrTemplate("%1.%2.%3", "CalculationRegister", MetadataObject.Parent().Name, MetadataObject.Name);
	Else
		TableName = MetadataObject.FullName();
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Node", Node);
	Query.Text =
	"SELECT
	|	COUNT(*) AS Count
	|FROM
	|	TableName AS Changes
	|WHERE
	|	Changes.Node = &Node
	|	AND Changes.MessageNo IS NULL";
	Query.Text = StrReplace(Query.Text, "TableName", StrTemplate("%1.%2", TableName, "Changes"));
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		If Selection.Count = 0 Then
			Return New Array;
		EndIf;
	EndIf;
	
	If Metadata.Sequences.Contains(MetadataObject) 
		Or Metadata.CalculationRegisters.Contains(MetadataObject.Parent()) Then
		// Some objects can only be selected completely.
		Return MetadataObject;
	EndIf;
	
	PortionSize = LeftToExport;
	If Metadata.AccountingRegisters.Contains(MetadataObject) Then
		PortionSize = Min(1000, PortionSize);
	EndIf;
	
	FilterFields = RecordsetSelectionFields(MetadataObject);
	ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	
	If FilterFields.Count() = 0 Then
		Return MetadataObject;
	EndIf;
	
	Query.Text =
	"SELECT TOP 1
	|	&Fields
	|FROM
	|	TableName AS Changes
	|WHERE
	|	Changes.Node = &Node
	|	AND Changes.MessageNo IS NULL";
	Query.Text = StrReplace(Query.Text, "1", Format(PortionSize, "NG=0"));
	Query.Text = StrReplace(Query.Text, "TableName", StrTemplate("%1.%2", TableName, "Changes"));
	Query.Text = StrReplace(Query.Text, "&Fields", StrConcat(FilterFields, ", "));
	
	Selection = Query.Execute().Select();
	FilterChanges = New Array;
	While Selection.Next() Do
		RecordSet = ObjectManager.CreateRecordSet();
		For Each FilterField In FilterFields Do
			FilterElement = RecordSet.Filter[FilterField]; // FilterItem
			FilterElement.Set(Selection[FilterField]);
		EndDo;
		FilterChanges.Add(RecordSet);
	EndDo;
	
	Return FilterChanges;
	
EndFunction

// Uploads the storage to a file.
//
// Parameters:
//   Attribute - ValueStorage - the value that you want to upload.
//   Id - String - ID of the object to upload.
//   FilesCount - Number - variable for accumulating the number of files for this metadata object.
//   ExportingParameters - Structure - description See ExportingParameters
//                                   ().
//
Procedure UnloadValueStore(Attribute, Id, FilesCount, ExportingParameters) Export
	
	If TypeOf(Attribute) <> Type("ValueStorage") Then
		Return;
	EndIf;
	
	Try
		Value = Attribute.Get();
	Except
		Return;
	EndTry;
	
	If Value = Undefined
		Or (CommonCTL.IsPrimitiveType(TypeOf(Value)) And Not ValueIsFilled(Value)) Then
		Return;
	EndIf;	
	
	DirectoryOfRepositories = ExportingParameters.DataDirectory + Id + "-storages";
	
	FileName = GenerateFileName(DirectoryOfRepositories, FilesCount);
	
	If TypeOf(Value) = Type("BinaryData") Then
		FileName = FileName + ".bin";
		Value.Write(DirectoryOfRepositories + GetPathSeparator() + FileName);
	Else
		FileName = FileName + ".xml";
		
		XMLWriter = New XMLWriter;
		XMLWriter.OpenFile(DirectoryOfRepositories + GetPathSeparator() + FileName);
		XDTOSerializer.WriteXML(XMLWriter, Value, XMLTypeAssignment.Explicit);
		XMLWriter.Close();
		
		AddAuxiliaryDataFromXMLFile(DirectoryOfRepositories + GetPathSeparator() + FileName, ExportingParameters);
		
	EndIf;
	
	Attribute = New ValueStorage(FileName);
	
EndProcedure

// Uploads General data for accumulated links.
//
// Parameters:
//   ExportingParameters - Structure - description See ExportingParameters
//                                   ().
//
Procedure UploadGeneralData(ExportingParameters) Export
	
	If ExportingParameters.GeneralDataLinks.Count() = 0 Then
		Return;
	EndIf;
	
	RefsByTypes = New Map;
	For Each KeyAndValue In ExportingParameters.GeneralDataLinks Do
		Ref = KeyAndValue.Key;
		List = RefsByTypes[TypeOf(Ref)];
		If List = Undefined Then
			List = New Array;
			RefsByTypes.Insert(TypeOf(Ref), List);
		EndIf;
		List.Add(Ref);
	EndDo;
	
	For Each KeyAndValue In RefsByTypes Do
		
		MetadataObject = Metadata.FindByType(KeyAndValue.Key);
		
		Id = GenerateFileName(ExportingParameters.DataDirectory, ExportingParameters.Data.Count());
		FileName = Id + ".xml";
		XMLWriter = New XMLWriter;
		XMLWriter.OpenFile(ExportingParameters.DataDirectory + FileName);
		XMLWriter.WriteStartElement("Data");
		RecordCorrespondenceOfNamespaces(XMLWriter);
		
		For Each Ref In KeyAndValue.Value Do
			
			Object = Ref.GetObject();
			If Object = Undefined Then
				Continue;
			EndIf;
			If ExportingParameters.TypesOfMappedSharedDataByPredefinedName[KeyAndValue.Key] <> Undefined
				And Not Object.Predefined Then
				Raise StrTemplate(NStr("vi = 'Đã tìm thấy tham chiếu đến dữ liệu chung mà không có trường tìm kiếm. Kiểu dữ liệu: %1';
										|ru = 'Обнаружена ссылка на общие данные без поля поиска. Тип данных: %1';
										|en = 'Reference to common data without search field was found. Data type: %1'; fa = 'Reference to common data without search field was found. Data type: %1';
										|it = 'È stato rilevato un collegamento a dati condivisi senza campo di ricerca. Tipo di dati: %1';
										|pl = 'Został ujawniony odnośnik do ogólnych danych bez pola wyszukiwania. Typ danych: %1';
										|tr = 'Arama alanı olmadan paylaşılan veri bağlantısı bulundu. Veri türü: %1'"), Object.Metadata().FullName());
			EndIf;
			
			ExportingParameters.Serializer.WriteXML(XMLWriter, Object, "Object", XMLTypeAssignment.Explicit);
			
		EndDo;
		
		XMLWriter.WriteEndElement();
		XMLWriter.Close();
		
		AddAuxiliaryDataFromXMLFile(ExportingParameters.DataDirectory + FileName, ExportingParameters);
		
		TableRow = ExportingParameters.Data.Add();
		TableRow.MetadataObject = MetadataObject.FullName();
		TableRow.Id = Id;
		TableRow.RecordsCount = KeyAndValue.Value.Count();
		
	EndDo;
	
EndProcedure

// Unloads the boundaries of all sequences.
//
// Parameters:
//   ExportingParameters - See ExportingParameters
//
Procedure UnloadSequenceBoundaries(ExportingParameters)
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(ExportingParameters.DumpDirectory + "SequenceBounds.xml");
	XMLWriter.WriteStartElement("Data");
	RecordCorrespondenceOfNamespaces(XMLWriter);
	
	PortionSize = 10000;
	
	For Each MetadataObject In Metadata.Sequences Do
		
		Query = New Query;
		QueryFilter = New Structure;
		
		If MetadataObject.Dimensions.Count() = 0 Then
			
			Query.Text =
			"SELECT
			|	Period, Recorder
			|FROM
			|	TableName";
			
			Query.Text = StrReplace(Query.Text, "TableName", 
				StrTemplate("%1.%2.%3", "Sequence", MetadataObject.Name, "Boundaries"));
			
			ExportingParameters.Serializer.WriteXML(XMLWriter, 
				Query.Execute().Unload(), 
				MetadataObject.Name, 
				XMLTypeAssignment.Explicit);
			
		Else
			
			Dimensions = New Array;
			QueryFields = New Array;
			QueryFields.Add("ISNULL(Period, DATETIME(1,1,1)) AS Period");
			QueryFields.Add("Recorder");
			For Each Dimension In MetadataObject.Dimensions Do
				QueryFields.Add(Dimension.Name);
				Dimensions.Add(Dimension.Name);
				QueryFilter.Insert(Dimension.Name);
				Query.SetParameter(Dimension.Name, Undefined);
			EndDo;
			
			LineMeasurements = StrConcat(Dimensions, ",");
			
			// Example of a condition:
			// WHERE (Measuring1 > &Measuring1) 
			//    OR (Measuring1 = &Measuring1 AND Measuring2 > & Measuring2)
			//    OR (Measuring1 = &Measuring1 AND Measuring2 = &Measuring2 AND Measuring3 > &Measuring3)
			//    OR < ... >
			QueryConditions = New Array;
			For MeasurementIndex = 0 To Dimensions.UBound() Do
				SoftwareTermsAndConditions = New Array;
				// Conditions for equality.
				For IndexIsEqualTo = 0 To MeasurementIndex - 1 Do
					SoftwareTermsAndConditions.Add(Dimensions[IndexIsEqualTo] + " = &" + Dimensions[IndexIsEqualTo]);
				EndDo;
				// The condition is for more (it is always the same).
				SoftwareTermsAndConditions.Add(Dimensions[MeasurementIndex] + " > &" + Dimensions[MeasurementIndex]);
				
				QueryConditions.Add("(" + StrConcat(SoftwareTermsAndConditions, " And ") + ")");
			EndDo;
			
			// Cursor query.
			
			Query.Text =
			"SELECT TOP 1
			|	&Fields
			|FROM
			|	TableName
			|WHERE 
			|	&Conditions" + Chars.LF + "ORDER BY" + Chars.LF + LineMeasurements;
			
			Query.Text = StrReplace(Query.Text, "1", Format(PortionSize, "NG=0"));
			Query.Text = StrReplace(Query.Text, "&Fields", StrConcat(QueryFields, ","));
			Query.Text = StrReplace(Query.Text, "TableName", 
				StrTemplate("%1.%2.%3", "Sequence", MetadataObject.Name, "Boundaries"));
			Query.Text = StrReplace(Query.Text, "&Conditions", StrConcat(QueryConditions, " OR "));
			
		EndIf;
		
		While True Do
			
			FillPropertyValues(Query.Parameters, QueryFilter);
			Boundaries = Query.Execute().Unload();
			
			If Boundaries.Count() = 0 Then
				Break;
			EndIf;
			
			Data = New ValueTable;
			For Each Column In Boundaries.Columns Do
				If Column.Name = "Recorder" Then
					Data.Columns.Add(Column.Name, New TypeDescription(Column.ValueType));
				Else
					Data.Columns.Add(Column.Name, New TypeDescription(Column.ValueType, , "Null"));
				EndIf;
			EndDo;
			For Each TableRow In Boundaries Do
				FillPropertyValues(Data.Add(), TableRow);
			EndDo;
			
			ExportingParameters.Serializer.WriteXML(XMLWriter, Data, MetadataObject.Name, XMLTypeAssignment.Explicit);
			
			If Boundaries.Count() < PortionSize Then
				Break;
			EndIf;
			
			FillPropertyValues(QueryFilter, Boundaries[Boundaries.Count() - 1]);
			
		EndDo;
		
	EndDo;
	
	XMLWriter.WriteEndElement();
	XMLWriter.Close();
	
	AddAuxiliaryDataFromXMLFile(ExportingParameters.DumpDirectory + "SequenceBounds.xml", ExportingParameters);
	
EndProcedure

// Unloads the information security user settings.
//
// Parameters:
//   SettingsStorage - StandardSettingsStorageManager - the settings that you want to upload.
//   FileName - String - the short name of the file to which you want to upload settings.
//   ExportingParameters - Structure - description See ExportingParameters
//                                   ().
//
Procedure UploadUserSettings(NameOfSettingsStore_, SettingsStorage, FileName, ExportingParameters)
	
	If TypeOf(SettingsStorage) <> Type("StandardSettingsStorageManager") Then
		Return;
	EndIf;
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(ExportingParameters.DumpDirectory + FileName);
	XMLWriter.WriteStartElement("Settings");
	RecordCorrespondenceOfNamespaces(XMLWriter);
	
	For Each IBUser In InfoBaseUsers.GetUsers() Do
		User = Catalogs.Users.FindByAttribute("IBUserID", IBUser.UUID);
		If Not ValueIsFilled(User) Then
			// Mapping is not possible during loading.
			Continue;
		EndIf;
		
		UserName = ExportingParameters.ExportUserSettings.Get(User);
		If UserName = Undefined Then
			Continue;
		EndIf;
		
		Selection = SettingsStorage.Select(New Structure("User", IBUser.Name));
		While True Do
			
			Try
				If Not Selection.Next() Then
					Break;
				EndIf;
			Except
				ErrorTemplate = NStr("vi = 'Đã bỏ qua kết xuất tùy chỉnh %1 (người sử dụng: %2, khóa đối tượng: %3, khóa tùy chỉnh: %4) do nguyên nhân: %5';
									|ru = 'Выгрузка настройки %1 (пользователь: %2, ключ объекта: %3, ключ настроек: %4 ) пропущена по причине: %5';
									|en = 'Export of the %1 setting (user: %2, object key: %3, setting key: %4 ) was skipped due to: %5'; fa = 'Export of the %1 setting (user: %2, object key: %3, setting key: %4 ) was skipped due to: %5';
									|it = 'Scaricare le impostazioni %1 (utente: %2, chiave oggetto: %3, chiave impostazioni: %4 ) saltato per un motivo: %5';
									|pl = 'Pobieranie ustawienia %1 (użytkownik: %2, klucz obiektu: %3, klucz ustawień: %4 ) jest przepuszczone z powodu: %5';
									|tr = '%1 yapılandırmasını yükle (kullanıcı: %2, nesne anahtarı: %3, ayarlar anahtarı: %4 ) atlama sebebi: %5'");
				Comment = StrTemplate(ErrorTemplate, 
					NameOfSettingsStore_, 
					Selection.User, 
					Selection.ObjectKey, 
					Selection.SettingsKey, 
					DetailErrorDescription(ErrorInfo()));
				ErrorLogging(NStr("vi = 'Kết xuất';
									|ru = 'Выгрузка';
									|en = 'Export'; fa = 'خروج اطلاعات';
									|it = 'Upload';
									|pl = 'Export';
									|tr = 'Dışa aktarma'", Common.DefaultLanguageCode()), Comment);
				Continue;
			EndTry;
			
			If Selection.Settings = Undefined Then
				Continue;
			EndIf;
			
			SettingsType1 = TypeOf(Selection.Settings);
			
			If SettingsType1 = Type("UserWorkFavorites") Then
				
				For Each Item In Selection.Settings Do // UserWorkFavoritesItem
					NavigationLinkStructure = ConvertNavigationLinkToStructure(Item.URL);
					If NavigationLinkStructure <> Undefined Then
						XMLEntryNavigationLink = New XMLWriter;
						XMLEntryNavigationLink.SetString();
						XDTOSerializer.WriteXML(XMLEntryNavigationLink, NavigationLinkStructure, XMLTypeAssignment.Explicit);
						AddAuxiliaryDataFromXMLString(XMLEntryNavigationLink.Close(), ExportingParameters);
					EndIf;
				EndDo;
				
			EndIf;
			
			Setting = New Structure("ObjectKey, SettingsKey, Settings,  Presentation");
			FillPropertyValues(Setting, Selection);
			Setting.Insert("User", UserName);
			
			XMLText = SerializeSettingToString(Setting, "Setting");
			XMLWriter.WriteRaw(XMLText);
			
		EndDo;
	EndDo;
	
	XMLWriter.WriteEndElement();
	XMLWriter.Close();
	
	AddAuxiliaryDataFromXMLFile(ExportingParameters.DumpDirectory + FileName, ExportingParameters);
	
EndProcedure

Function SerializeSettingToString(Value, FullName)
	
	Try
		XMLWriter = New XMLWriter;
		XMLWriter.SetString();
		XDTOSerializer.WriteXML(XMLWriter, Value, FullName, XMLTypeAssignment.Explicit);
		Return XMLWriter.Close();
	Except
	EndTry;
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, New ValueStorage(Value), FullName, XMLTypeAssignment.Explicit);
	Return XMLWriter.Close();
	
EndFunction

// Unloads the contents of the standard interface.
//
// Parameters:
//   The upload parameter_string is the full name of the folder.
//
Procedure UnloadCompositionOfStandardODataInterface(DumpDirectory)
	
	Content = New Array;
	
	For Each MetadataObject In GetStandardODataInterfaceContent() Do
		Content.Add(MetadataObject.FullName());
	EndDo;
	
	WriteDataToFile(Content, DumpDirectory + "StandardODataInterfaceContent.xml");
	
EndProcedure

// Unloads the subsystem versions.
//
// Parameters:
//   The upload parameter_string is the full name of the folder.
//
Procedure UnloadSubsystemVersions(DumpDirectory)
	
	SubsystemsVersions = New Structure;
	
	SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails().ByNames;
	For Each SubsystemDetails In SubsystemsDetails Do
		SubsystemsVersions.Insert(SubsystemDetails.Key, InfobaseUpdate.IBVersion(SubsystemDetails.Key));
	EndDo;
	
	WriteDataToFile(SubsystemsVersions, DumpDirectory + "SubsystemsVersions.xml");
	
EndProcedure

// Returns parameters for loading.
//
// Parameters:
//   ImportDirectory - String - the full name of the directory from which you are downloading.
//   RefsMap - Map - matching old and new links.
//   ObjectsToClear - Map - the collection of metadata names that you want to clear.
//
// Returns:
//   Structure - structure with keys:
//     * ImportDirectory - String - the full name of the directory from which you are downloading.
//     * DataDirectory - String - the full name of the directory where the data is located is the Data directory in the download directory.
//     * DataTable - See DataTable
//     * SharedData - Map - matching old and new shared data links.
//     * TypesOfExchangeNodes - See TypesOfExchangeNodes
//     * RefsMap - Map - matching old and new links.
//     * Separator - Number - value of the current separator.
//     * CatalogsFiles_ - See FilesOperationsInternalSaaSCached.FilesCatalogsAndStorageOptionObjects 
//     * ObjectsToClear - Map - the collection of metadata names that you want to clear.
//     * TypesOfSharedDataToBeMatchedBySearchFields - See ApplicationsMigrationCached.TypesOfSharedDataToBeMatchedBySearchFields
//     * TypesOfMappedSharedDataByPredefinedName - See ApplicationsMigrationCached.TypesOfMappedSharedDataByPredefinedName
//     * ProhibitedTypesOfSharedData - See ApplicationsMigrationCached.ProhibitedTypesOfSharedData
//     * TypesOfLinksToBeRecreated - See ApplicationsMigrationCached.TypesOfLinksToBeRecreated
//     * SharedMetadataObjects - See ApplicationsMigrationCached.SharedMetadataObjects
//
Function ImportParameters(ImportDirectory, RefsMap, ObjectsToClear)
	
	DataDirectory = ImportDirectory + "Data" + GetPathSeparator();
	DataTable = ReadDataFromFile(ImportDirectory + "Data.xml");
	
	If DataTable = Undefined Then
		Raise NStr("vi = 'Không có tệp Data.xml';
					|ru = 'Отсутствует файл Data.xml';
					|en = 'Data.xml file is missing'; fa = 'Data.xml file is missing';
					|it = 'File Data mancante.xml';
					|pl = 'Brakuje plik Data.xml';
					|tr = 'Data.xml dosyası eksik'");
	EndIf;
	
	SharedData = DownloadGeneralData(DataDirectory, DataTable);
	
	ImportParameters = New Structure;
	ImportParameters.Insert("ImportDirectory", ImportDirectory);
	ImportParameters.Insert("DataDirectory", DataDirectory);
	ImportParameters.Insert("DataTable", DataTable);
	ImportParameters.Insert("SharedData", SharedData);
	ImportParameters.Insert("TypesOfExchangeNodes", TypesOfExchangeNodes());
	ImportParameters.Insert("RefsMap", ReadMatchingLinks(RefsMap, ImportDirectory));
	ImportParameters.Insert("Separator", SessionParameters.DataAreaValue);
	ImportParameters.Insert("CatalogsFiles_", FilesOperationsInternalSaaSCached.FilesCatalogsAndStorageOptionObjects());
	ImportParameters.Insert("ObjectsToClear", ObjectsToClear);
	ImportParameters.Insert("TypesOfSharedDataToBeMatchedBySearchFields", ApplicationsMigrationCached.TypesOfSharedDataToBeMatchedBySearchFields());
	ImportParameters.Insert("TypesOfMappedSharedDataByPredefinedName", ApplicationsMigrationCached.TypesOfMappedSharedDataByPredefinedName());
	ImportParameters.Insert("ProhibitedTypesOfSharedData", ApplicationsMigrationCached.ProhibitedTypesOfSharedData());
	ImportParameters.Insert("TypesOfLinksToBeRecreated", ApplicationsMigrationCached.TypesOfLinksToBeRecreated());
	ImportParameters.Insert("SharedMetadataObjects", ApplicationsMigrationCached.SharedMetadataObjects());
	
	Return ImportParameters;
	
EndFunction

// Loads user data.
//
// Parameters:
//   ImportParameters - See ImportParameters
//
// Returns:
//   Number - the number of objects loaded.
//
Function UploadUserData_(ImportParameters)
	
	DownloadStartTemplate = NStr("vi = 'Đang kết nhập đối tượng: %1';
								|ru = 'Загружается объект: %1';
								|en = 'Object is being imported: %1'; fa = 'Object is being imported: %1';
								|it = 'Caricati oggetti: %1';
								|pl = 'Jest pobierany obiekt: %1';
								|tr = 'Nesne içe aktarılıyor: %1'", Common.DefaultLanguageCode());
	TemplateEndOfDownload = NStr("vi = 'Đã kết nhập đối tượng: %1, Số lượng: %2, Thời gian (giây): %3';
								|ru = 'Загружен объект: %1, Количество: %2, Длительность (сек): %3';
								|en = 'Imported object: %1, Quantity: %2, Duration (sec): %3'; fa = 'Imported object: %1, Quantity: %2, Duration (sec): %3';
								|it = 'Oggetto caricato: %1, Quantità: %2, Durata (sec): %3';
								|pl = 'Został pobrany obiekt: %1, Ilość: %2, Czas trwania (sek): %3';
								|tr = 'Nesne içe aktarıldı: %1, Miktar: %2, Süre (san): %3'", Common.DefaultLanguageCode());
	LoadableObjects = ApplicationsMigrationCached.UnloadedObjects();
	TotalObjectCount = 0;
	
	For Each DataString1 In ImportParameters.DataTable Do
		
		Begin = CurrentUniversalDateInMilliseconds();
		
		ReplaceLinksWhenLoadingFromXMLFile(ImportParameters.DataDirectory + DataString1.Id + ".xml", ImportParameters);
		MetadataObject = Metadata.FindByFullName(DataString1.MetadataObject);
		
		Comment = StrTemplate(DownloadStartTemplate, MetadataObject.FullName());
		NoteRegistration(NStr("vi = 'Thống kê kết nhập';
								|ru = 'Статистика загрузки';
								|en = 'Import statistics'; fa = 'Import statistics';
								|it = 'Statistiche di caricamento';
								|pl = 'Statystyka pobierania';
								|tr = 'İçe aktarma istatistiği'"), Comment);
		
		If LoadableObjects[MetadataObject] = Undefined Then
			
			Continue;
		
		ElsIf Metadata.Constants.Contains(MetadataObject) Then
			
			ObjectsImported = LoadConstant(MetadataObject, DataString1.Id, ImportParameters);
			
		ElsIf Metadata.Catalogs.Contains(MetadataObject) 
			Or Metadata.Documents.Contains(MetadataObject) 
			Or Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject)
			Or Metadata.ChartsOfAccounts.Contains(MetadataObject)
			Or Metadata.ChartsOfCalculationTypes.Contains(MetadataObject)
			Or Metadata.Tasks.Contains(MetadataObject) 
			Or Metadata.BusinessProcesses.Contains(MetadataObject) Then
			
			ObjectsImported = LoadReferenceType(MetadataObject, DataString1.Id, ImportParameters);
			
		ElsIf Metadata.InformationRegisters.Contains(MetadataObject)
			Or Metadata.AccumulationRegisters.Contains(MetadataObject) 
			Or Metadata.CalculationRegisters.Contains(MetadataObject) 
			Or Metadata.CalculationRegisters.Contains(MetadataObject.Parent())
			Or Metadata.AccountingRegisters.Contains(MetadataObject) 
			Or Metadata.Sequences.Contains(MetadataObject) Then
			
			ObjectsImported = LoadRecordset(MetadataObject, DataString1.Id, ImportParameters);
			
		Else
			
			RaiseExceptionUnknownMetadataObject(MetadataObject);
			
		EndIf;
		
		Duration = (CurrentUniversalDateInMilliseconds() - Begin) / 1000;
		Comment = StrTemplate(TemplateEndOfDownload, MetadataObject.FullName(), ObjectsImported, Duration);
		NoteRegistration(NStr("vi = 'Thống kê kết nhập';
								|ru = 'Статистика загрузки';
								|en = 'Import statistics'; fa = 'Import statistics';
								|it = 'Statistiche di caricamento';
								|pl = 'Statystyka pobierania';
								|tr = 'İçe aktarma istatistiği'"), Comment);
		
		TotalObjectCount = TotalObjectCount + ObjectsImported;
		
	EndDo;
	
	Return TotalObjectCount;
	
EndFunction

// Parameters:
//   MetadataObject - MetadataObjectConstant - the object that you want to upload.
//   Id - String - ID of the object to load.
//   ImportParameters - See ImportParameters
//
// Returns:
//   Number - the number of unloaded objects.
//
Function LoadConstant(MetadataObject, Id, ImportParameters)
	
	ImportParameters.ObjectsToClear.Delete(MetadataObject.FullName());
	
	JointlyDivided = ImportParameters.SharedMetadataObjects[MetadataObject] <> Undefined;
	
	Object = ReadDataFromFile(ImportParameters.DataDirectory + Id + ".xml");
	CheckTypeOfObjectRead(Object, MetadataObject);
	
	If JointlyDivided Then
		Object.DataAreaAuxiliaryData = ImportParameters.Separator;
	EndIf;
	
	If TypeOf(Object.Value) = Type("ValueStorage") Then
		LoadValueStore(Object.Value, Id, ImportParameters);
	EndIf;
	
	Cancel = False;
	ApplicationsMigrationOverridable.OnImportObject(Object, Cancel);
	If Cancel Then
		Return 0;
	EndIf;
	
	Object.DataExchange.Load = True;
	Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	Object.Write();
	
	Return 1;
	
EndFunction

// Loads the reference object.
//
// Parameters:
//   MetadataObject - MetadataObjectCatalog, MetadataObjectDocument - 
//                    - MetadataObjectChartOfCharacteristicTypes, MetadataObjectChartOfAccounts - 
//                    - MetadataObjectChartOfCalculationTypes, MetadataObjectTask -
//                    - MetadataObjectBusinessProcess - the object that you want to upload.
//   Id - String - ID of the object to load.
//   ImportParameters - See ImportParameters
//
// Returns:
//   Number - the number of unloaded objects.
//
Function LoadReferenceType(MetadataObject, Id, ImportParameters)
	
	ThisIsCatalogOfAccessGroupProfiles = MetadataObject = Metadata.Catalogs.AccessGroupProfiles;
	If ThisIsCatalogOfAccessGroupProfiles Then
		UnavailableRoles = UnavailableRoles();
	EndIf;
	
	ThisIsUsersCatalog = MetadataObject = Metadata.Catalogs.Users;
	
	HandlerFiles_ = ImportParameters.CatalogsFiles_.CatalogsFiles_[MetadataObject.FullName()];
	IsFilesCatalog = HandlerFiles_ <> Undefined;
	If IsFilesCatalog Then
		HandlerFiles_ = Common.CommonModule(HandlerFiles_);
	EndIf;
	
	If ImportParameters.ObjectsToClear[MetadataObject.FullName()] <> Undefined Then
		ImportParameters.ObjectsToClear.Delete(MetadataObject.FullName());
		ClearReferenceType(MetadataObject);
	EndIf;
	
	JointlyDivided = ImportParameters.SharedMetadataObjects[MetadataObject] <> Undefined;
	
	StorageDetails = StorageDetails(MetadataObject.Attributes);
	If IsFilesCatalog Then
		StorageDetails.Delete(StorageDetails.Find("FileStorage"));
	EndIf;
	
	TabularPartsWithStorage = New Structure;
	For Each TabularSection In MetadataObject.TabularSections Do
		Attributes = StorageDetails(TabularSection.Attributes);
		If Attributes.Count() Then
			TabularPartsWithStorage.Insert(TabularSection.Name, Attributes);
		EndIf;
	EndDo;
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(ImportParameters.DataDirectory + Id + ".xml");
	XMLReader.MoveToContent();
	
	If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> "Data" Then
		Raise(NStr("vi = 'Lỗi đọc XML. Sai định dạng tệp. Đang chờ bắt đầu phần tử ""Data"".';
					|ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента ""Data"".';
					|en = 'XML reading error. Invalid file format. Start of ""Data"" element is expected.'; fa = 'XML reading error. Invalid file format. Start of ""Data"" element is expected.';
					|it = 'Errore di lettura XML. Formato file errato. Atteso l''inizio dell''elemento ""Data"".';
					|pl = 'Błąd odczytu XML. Błędny format pliku. Oczekiwany jest początek elementu ""Дата"".';
					|tr = 'XML okuma hatası. Hatalı dosya formatı. ""Data"" öğesinin başlangıcı bekleniyor.'"));
	EndIf;	
	
	PredefinedSupported = 
		CommonCTL.IsRefDataSupportingPredefinedItems(MetadataObject);
	Hierarchical = PredefinedSupported And Not CommonCTL.IsChartOfCalculationTypes(MetadataObject) 
		And (CommonCTL.IsChartOfAccounts(MetadataObject) Or MetadataObject.Hierarchical);
	ObjectCount = 0;
	
	XMLReader.Read();
	While XMLReader.NodeType = XMLNodeType.StartElement Do
		
		Object = XDTOSerializer.ReadXML(XMLReader); // CatalogObject, DocumentObject
		
		If TypeOf(Object) = Type("ObjectDeletion") Then
			Object.DataExchange.Load = True;
			Object.Write();
			Continue;
		EndIf;
		
		CheckTypeOfObjectRead(Object, MetadataObject);
		
		If ThisIsCatalogOfAccessGroupProfiles Then
			For ReverseIndex = 1 - Object.Roles.Count() To 0 Do
				If UnavailableRoles[Object.Roles[-ReverseIndex].Role] <> Undefined Then
					Object.Roles.Delete(-ReverseIndex);
				EndIf;
			EndDo;
		EndIf;
		
		If JointlyDivided Then
			Object.DataAreaAuxiliaryData = ImportParameters.Separator;
		EndIf;
		
		For Each Attribute In StorageDetails Do
			LoadValueStore(Object[Attribute], Id, ImportParameters);
		EndDo;
		
		For Each TabularSection In TabularPartsWithStorage Do
			For Each LineOfATabularSection In Object[TabularSection.Key] Do
				For Each Attribute In TabularSection.Value Do
					LoadValueStore(LineOfATabularSection[Attribute], Id, ImportParameters);
				EndDo;
			EndDo;
		EndDo;
		
		If ThisIsUsersCatalog Then
			Object.ServiceUserID = Undefined;
		ElsIf IsFilesCatalog And Not Object.IsFolder And Object.FileStorage.Get() <> Undefined Then
			HandlerFiles_.ImportFile_(Object, ImportParameters.DataDirectory + Id + "-files" + GetPathSeparator() + Object.FileStorage.Get());
		EndIf;
		
		Cancel = False;
		ApplicationsMigrationOverridable.OnImportObject(Object, Cancel);
		If Cancel Then
			Continue;
		EndIf;
		
		Object.DataExchange.Load = True;
		Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		Duplicates = DuplicatesOfPredefinedItems(Object, MetadataObject, PredefinedSupported);
		
		BeginTransaction();
		Try
			
			For Each DoublePredefined In Duplicates Do
				If Hierarchical Then
					ReplaceReferencesToParent(DoublePredefined, Object.GetNewObjectRef(), MetadataObject);
				EndIf;
				DuplicatePredefinedObjects = DoublePredefined.GetObject(); 
				DuplicatePredefinedObjects.DataExchange.Load = True;
				DuplicatePredefinedObjects.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
				DuplicatePredefinedObjects.Delete();
			EndDo;
			
			Object.Write();
			
			CommitTransaction();
				
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		ObjectCount = ObjectCount + 1;
		
	EndDo;
	
	XMLReader.Close();
	
	Return ObjectCount
	
EndFunction

Procedure ReplaceReferencesToParent(Original, Replacement, MetadataObject)
	Query = New Query;
	Query.Text = StrReplace("SELECT
		|	T.Ref AS Ref
		|FROM
		|	&Table AS T
		|WHERE 
		|	T.Parent = &Ref
		|	AND T.Predefined",
		"&Table",
		MetadataObject.FullName());
	Query.SetParameter("Ref", Original);
	SubordinateItems = Query.Execute().Unload().UnloadColumn("Ref");
	For Each Subordinated In SubordinateItems Do
		SubordinateObject = Subordinated.GetObject();
		SubordinateObject.Parent = Replacement;
		SubordinateObject.DataExchange.Load = True;
		SubordinateObject.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		SubordinateObject.Write();
	EndDo;
EndProcedure

Function DuplicatesOfPredefinedItems(Object, MetadataObject, PredefinedSupported)
	Duplicates = New Array;
	
	If PredefinedSupported And Object.Predefined Then
		
		PredefinedItemName = Object.PredefinedDataName;
				
		Query = New Query;
		Query.Text = StrReplace("SELECT
			|	T.Ref AS Ref
			|FROM
			|	&Table AS T
			|WHERE 
			|	T.PredefinedDataName = &PredefinedItemName
			|	AND T.Ref <> &Ref",
			"&Table",
		 	MetadataObject.FullName());
		Query.SetParameter("PredefinedItemName", PredefinedItemName);
		Query.SetParameter("Ref", Object.Ref);
		
		Duplicates = Query.Execute().Unload().UnloadColumn("Ref");
	EndIf;
	
	Return Duplicates;
EndFunction

// Clears the reference type:
//
// Parameters:
//   MetadataObject - MetadataObjectCatalog, MetadataObjectDocument -
//                    - MetadataObjectChartOfCharacteristicTypes, MetadataObjectChartOfAccounts -
//                    - MetadataObjectChartOfCalculationTypes, MetadataObjectTask -
//                    - MetadataObjectBusinessProcess - the object that you want to upload.
//
Procedure ClearReferenceType(MetadataObject)
	
	Query = New Query;
	Query.Text = StrReplace(
		"SELECT
		|	Ref AS Ref
		|FROM
		|	&Table", "&Table", MetadataObject.FullName());
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Object = Selection.Ref.GetObject();
		Object.DataExchange.Load = True;
		Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		Object.Delete();
	EndDo;
	
EndProcedure

// Loads a set of records.
//
// Parameters:
//   MetadataObject - MetadataObjectInformationRegister, MetadataObjectAccumulationRegister -
//                    - MetadataObjectCalculationRegister, MetadataObjectAccountingRegister -
//                    - MetadataObjectSequence - the object that you want to upload.
//   Id - String - ID of the object to load.
//   ImportParameters - See ImportParameters
//
// Returns:
//   Number - the number of unloaded objects.
//
Function LoadRecordset(MetadataObject, Id, ImportParameters)
	
	If ImportParameters.ObjectsToClear[MetadataObject.FullName()] <> Undefined Then
		
		ImportParameters.ObjectsToClear.Delete(MetadataObject.FullName());
		ClearRecordSet(MetadataObject);
		
	EndIf;
	
	JointlyDivided = ImportParameters.SharedMetadataObjects[MetadataObject] <> Undefined;
	
	If Metadata.Sequences.Contains(MetadataObject) 
		Or Metadata.CalculationRegisters.Contains(MetadataObject.Parent()) Then
		StorageDetails = New Array;
	Else
		StorageDetails = StorageDetails(MetadataObject.Resources);
		For Each Attribute In StorageDetails(MetadataObject.Attributes) Do
			StorageDetails.Add(Attribute);
		EndDo;
	EndIf;
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(ImportParameters.DataDirectory + Id + ".xml");
	XMLReader.MoveToContent();
	
	If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> "Data" Then
		Raise(NStr("vi = 'Lỗi đọc XML. Sai định dạng tệp. Chờ bắt đầu phần tử ""Data"".';
					|ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента ""Data"".';
					|en = 'XML reading error. Invalid file format. Start of ""Data"" element is expected.'; fa = 'XML reading error. Invalid file format. Start of ""Data"" element is expected.';
					|it = 'Errore di lettura XML. Formato file errato. Atteso l''inizio dell''elemento ""Data"".';
					|pl = 'Błąd odczytu XML. Błędny format pliku. Oczekiwany jest początek elementu ""Дата"".';
					|tr = 'XML okuma hatası. Hatalı dosya formatı. ""Data"" öğesinin başlangıcı bekleniyor.'"));
	EndIf;	
	
	ObjectCount = 0;
	
	XMLReader.Read();
	While XMLReader.NodeType = XMLNodeType.StartElement Do
		
		Object = XDTOSerializer.ReadXML(XMLReader);
		
		CheckTypeOfObjectRead(Object, MetadataObject);
		
		If JointlyDivided Then
			Object.Filter.DataAreaAuxiliaryData.Value = ImportParameters.Separator;
		EndIf;
		If JointlyDivided Or StorageDetails.Count() > 0 Then 
			For Each Record In Object Do
				If JointlyDivided Then
					Record.DataAreaAuxiliaryData = ImportParameters.Separator;
				EndIf;
				For Each Attribute In StorageDetails Do
					LoadValueStore(Record[Attribute], Id, ImportParameters);
				EndDo;
			EndDo;
		EndIf;
		
		Cancel = False;
		ApplicationsMigrationOverridable.OnImportObject(Object, Cancel);
		If Cancel Then
			Continue;
		EndIf;
		
		Object.DataExchange.Load = True;
		Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		
		If CommonCTL.IsInformationRegister(MetadataObject)
			And MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate 
			And MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.RecorderPosition Then
			WriteRegisterOfInformationWithRemovalOfDuplicates(MetadataObject, Object);
		Else
			Object.Write();
		EndIf;
		
		ObjectCount = ObjectCount + 1;
		
	EndDo;
	
	XMLReader.Close();
	
	Return ObjectCount;
	
EndFunction

// Writes a set of data register records in an attempt, if
// the record fails, the interfering sets are cleared and re-recorded.
// 
// Parameters:
//  MetadataObject - MetadataObjectInformationRegister - metadata object
//  RecordSet - InformationRegisterRecordSet - Object
//
Procedure WriteRegisterOfInformationWithRemovalOfDuplicates(MetadataObject, RecordSet)
	
	Try
		RecordSet.Write();
	Except
		DimensionValues = New ValueTable;
		Dimensions = New Array;
		ConnectionConditions = New Array;
		If MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
			DimensionValues.Columns.Add(MetadataObject.StandardAttributes.Period.Name, MetadataObject.StandardAttributes.Period.Type);
			Dimensions.Add(MetadataObject.StandardAttributes.Period.Name);
			ConnectionConditions.Add(StrTemplate("RegisterTable.%1 = DimensionValues.%1", MetadataObject.StandardAttributes.Period.Name));
		EndIf;
		For Each Dimension In MetadataObject.Dimensions Do
			DimensionValues.Columns.Add(Dimension.Name, Dimension.Type);
			Dimensions.Add(Dimension.Name);
			ConnectionConditions.Add(StrTemplate("RegisterTable.%1 = DimensionValues.%1", Dimension.Name));
		EndDo;
		For Each Record In RecordSet Do
			FillPropertyValues(DimensionValues.Add(), Record);
		EndDo;
		Query = New Query;
		Query.SetParameter("Recorder", RecordSet.Filter.Recorder.Value);
		Query.SetParameter("DimensionValues", DimensionValues);
		Query.Text = 
		"SELECT
		|	&Dimensions
		|INTO DimensionValues
		|FROM
		|	&DimensionValues AS DimensionValues
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	RegisterTable.Recorder AS Recorder
		|FROM
		|	&RegisterTable AS RegisterTable
		|		INNER JOIN DimensionValues AS DimensionValues
		|		ON (&ConnectionConditions)
		|WHERE
		|	RegisterTable.Recorder <> &Recorder";
		Query.Text = StrReplace(Query.Text, "&Dimensions", StrConcat(Dimensions, ", "));
		Query.Text = StrReplace(Query.Text, "&ConnectionConditions", StrConcat(ConnectionConditions, " And "));
		Query.Text = StrReplace(Query.Text, "&RegisterTable", MetadataObject.FullName());
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			Duplicates = InformationRegisters[MetadataObject.Name].CreateRecordSet();
			Duplicates.Filter.Recorder.Set(Selection.Recorder);
			Duplicates.DataExchange.Load = True;
			Duplicates.Write();
		EndDo;
		RecordSet.Write();
		
	EndTry;
	
EndProcedure

// Clears the record set.
// 
// Parameters:
//   MetadataObject - MetadataObjectInformationRegister, MetadataObjectAccumulationRegister - 
//                    - MetadataObjectCalculationRegister, MetadataObjectRecalculation - 
//                    - MetadataObjectAccountingRegister, MetadataObjectSequence - the object to be unloaded.
//
Procedure ClearRecordSet(MetadataObject)
	
	ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	
	If Metadata.InformationRegisters.Contains(MetadataObject) 
		And MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
		RecordSet = ObjectManager.CreateRecordSet();
		RecordSet.DataExchange.Load = True;
		RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		RecordSet.Write();
	ElsIf Metadata.CalculationRegisters.Contains(MetadataObject.Parent()) Then
		Query = New Query;
		Query.Text = StrReplace(
		"SELECT DISTINCT
		|	RecalculationObject AS RecalculationObject
		|FROM
		|	&Table", "&Table", StrReplace(MetadataObject.FullName(), "." + "Recalculation" + ".", "."));
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			RecordSet = ObjectManager.CreateRecordSet();
			// @skip-warning PropertyNotFound - verification error.
			SelectingRecalculationObject = RecordSet.Filter.RecalculationObject; // FilterItem
			SelectingRecalculationObject.Set(Selection.Recorder);
			RecordSet.DataExchange.Load = True;
			RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
			RecordSet.Write();
		EndDo;
	Else
		Query = New Query;
		Query.Text = StrReplace(
		"SELECT DISTINCT
		|	Recorder AS Recorder
		|FROM
		|	&Table", "&Table", MetadataObject.FullName());
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			RecordSet = ObjectManager.CreateRecordSet();
			// @skip-warning PropertyNotFound - verification error.
			FilterRecorder = RecordSet.Filter.Recorder; // FilterItem
			FilterRecorder.Set(Selection.Recorder);
			RecordSet.DataExchange.Load = True;
			RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
			RecordSet.Write();
		EndDo;
	EndIf;
	
	// Additionally, the boundaries of the sequence with broken links are cleared.
	If Metadata.Sequences.Contains(MetadataObject) And MetadataObject.Dimensions.Count() Then
		
		Dimensions = New Array;
		For Each Dimension In MetadataObject.Dimensions Do
			Dimensions.Add(Dimension.Name);
		EndDo;
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	&Fields
		|FROM
		|	TableName";
		Query.Text = StrReplace(Query.Text, "&Fields", StrConcat(Dimensions, ","));
		Query.Text = StrReplace(Query.Text, "TableName", MetadataObject.FullName() + "." + "Boundaries");
		Selection = Query.Execute().Select();
		If Selection.Count() Then
			
			MetadataOfDocument = Undefined;
			For Each MetadataOfDocument In MetadataObject.Documents Do
				Break;
			EndDo;
			ManagerOfDocument = Common.ObjectManagerByFullName(MetadataOfDocument.FullName());
			DocumentRef = ManagerOfDocument.GetRef(New UUID);
			
			RecordSet = ObjectManager.CreateRecordSet();
			// @skip-warning PropertyNotFound - verification error.
			FilterRecorder = RecordSet.Filter.Recorder; // FilterItem
			FilterRecorder.Set(DocumentRef);
			RecordSet.DataExchange.Load = True;
			RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
			While Selection.Next() Do
				FillPropertyValues(RecordSet.Add(), Selection);
			EndDo;
			RecordSet.Write();
			
			RecordSet.Clear();
			RecordSet.Write();
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Loads shared data from the folder.
//
// Parameters:
//  DataDirectory - String - full name of the folder.
//  DataTable - See DataTable
//
// Returns:
//  Map of KeyAndValue - matching old and new shared data links:
//   * Key - AnyRef
//   * Value - AnyRef
//
Function DownloadGeneralData(DataDirectory, DataTable) Export
	
	// The key is the old link, the Value is the new link.
	SharedData = New Map;
	
	GeneralDataMatchedBySearchFields = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	
	For Each MetadataObject In OrderOfComparisonOfCommonData() Do
		
		FoundRow = DataTable.Find(MetadataObject.FullName(), "MetadataObject");
		
		If FoundRow = Undefined Then
			Continue;
		EndIf;
		
		MatchBySearchFields = GeneralDataMatchedBySearchFields.Find(MetadataObject) <> Undefined;
		
		XMLReader = New XMLReader;
		XMLReader.OpenFile(DataDirectory + FoundRow.Id + ".xml");
		XMLReader.MoveToContent();
		
		DataTable.Delete(FoundRow);
		
		If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> "Data" Then
			Raise(NStr("vi = 'Lỗi đọc XML. Sai định dạng tệp. Chờ bắt đầu phần tử ""Data"".';
						|ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента ""Data"".';
						|en = 'XML reading error. Invalid file format. Start of ""Data"" element is expected.'; fa = 'XML reading error. Invalid file format. Start of ""Data"" element is expected.';
						|it = 'Errore di lettura XML. Formato file errato. Atteso l''inizio dell''elemento ""Data"".';
						|pl = 'Błąd odczytu XML. Błędny format pliku. Oczekiwany jest początek elementu ""Дата"".';
						|tr = 'XML okuma hatası. Hatalı dosya formatı. ""Data"" öğesinin başlangıcı bekleniyor.'"));
		EndIf;
		
		Objects = New Array;
		
		XMLReader.Read();
		While XMLReader.NodeType = XMLNodeType.StartElement Do
			Object = XDTOSerializer.ReadXML(XMLReader);
			CheckTypeOfObjectRead(Object, MetadataObject);
		    Objects.Add(Object);
			
			If Objects.Count() = 10000 Then
				If MatchBySearchFields Then
					MatchGeneralDataBySearchFields(MetadataObject, Objects, SharedData);
				Else
					MatchSharedDataByPredefinedName(MetadataObject, Objects, SharedData);
				EndIf;
				Objects.Clear();
			EndIf;
			
		EndDo;
		XMLReader.Close();
		
		If Objects.Count() > 0 Then
			If MatchBySearchFields Then
				MatchGeneralDataBySearchFields(MetadataObject, Objects, SharedData);
			Else
				MatchSharedDataByPredefinedName(MetadataObject, Objects, SharedData);
			EndIf;
		EndIf;
		
	EndDo;
	
	Return SharedData;
		
EndFunction

// Loads the value stores in the props.
//
// Parameters:
//   Attribute - ValueStorage - the value of the props.
//   Id - String - ID of the object to load.
//   ImportParameters - See ImportParameters
//
Procedure LoadValueStore(Attribute, Id, ImportParameters) Export
	
	If TypeOf(Attribute) <> Type("ValueStorage") Then
		Return;
	EndIf;
	
	Try
		FileName = Attribute.Get();
	Except
		Return;
	EndTry;
	
	If TypeOf(FileName) <> Type("String") Or IsBlankString(FileName) Then
		Return;
	EndIf;
	
	FullFileName = ImportParameters.DataDirectory + Id + "-storages" + GetPathSeparator() + FileName;
	
	If StrEndsWith(FileName, ".bin") Then
		
		BinaryData = New BinaryData(FullFileName);
		Attribute = New ValueStorage(BinaryData);
		
	Else
		
		ReplaceLinksWhenLoadingFromXMLFile(FullFileName, ImportParameters);
		
		XMLReader = New XMLReader();
		XMLReader.OpenFile(FullFileName);
		Value = XDTOSerializer.ReadXML(XMLReader);
		XMLReader.Close();
		
		Attribute = New ValueStorage(Value);
		
	EndIf;
	
EndProcedure

// Loads the user settings.
//
// Parameters:
//   SettingsStorage - StandardSettingsStorageManager - repository into which to load the settings.
//   FileName - String - short file name.
//   ImportParameters - See ImportParameters
//
Procedure DownloadUserSettings(SettingsStorage, FileName, ImportParameters)
	
	If TypeOf(SettingsStorage) <> Type("StandardSettingsStorageManager") Then
		Return;
	EndIf;
	
	// Clearing all settings.
	SettingsStorage.Delete(Undefined, Undefined, Undefined);
	
	File = New File(ImportParameters.ImportDirectory + FileName);
	If Not File.Exists() Then
		Return;
	EndIf;
	
	ReplaceLinksWhenLoadingFromXMLFile(File.FullName, ImportParameters);
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(ImportParameters.ImportDirectory + FileName);
	XMLReader.MoveToContent();
	
	If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> "Settings" Then
		Raise(NStr("vi = 'Lỗi đọc XML. Sai định dạng tệp. Chờ bắt đầu phần tử ""Tùy chỉnh"".';
					|ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента ""Настройки"".';
					|en = 'XML reading error. Invalid file format. Start of ""Settings"" element is expected.'; fa = 'XML reading error. Invalid file format. Start of ""Settings"" element is expected.';
					|it = 'Errore di lettura XML. Formato file errato. Atteso l''inizio dell''elemento ""Impostazione"".';
					|pl = 'Błąd odczytu XML. Błędny format pliku. Oczekiwany jest początek elementu ""Настройки"".';
					|tr = 'XML okuma hatası. Hatalı dosya formatı. ""Ayarlar"" öğesinin başlangıcı bekleniyor.'"));
	EndIf;
	
	XMLReader.Read();
	While XMLReader.NodeType = XMLNodeType.StartElement Do
		Setting = XDTOSerializer.ReadXML(XMLReader);
		If TypeOf(Setting) = Type("ValueStorage") Then
			Setting = Setting.Get();
		EndIf;
		
		If TypeOf(Setting.Settings) = Type("UserWorkFavorites") Then
			NewFavorites = New UserWorkFavorites;
			For Each Item In Setting.Settings Do // UserWorkFavoritesItem
				NavigationLinkStructure = ConvertNavigationLinkToStructure(Item.URL);
				If NavigationLinkStructure <> Undefined Then
					For Each ReplacementElement In NavigationLinkStructure.Replacement Do
						NewValue = UniqueIDPerLine32(GetLinkWhenUploading(TypeOf(ReplacementElement.Value), String(ReplacementElement.Value.UUID()), ImportParameters));
						NavigationLinkStructure.URL = StrReplace(NavigationLinkStructure.URL, ReplacementElement.Key, NewValue);
					EndDo;
					Item.URL = NavigationLinkStructure.URL;
				EndIf;
				NewItem = New UserWorkFavoritesItem;
				FillPropertyValues(NewItem, Item);
				NewFavorites.Add(NewItem);
			EndDo;
			Setting.Settings = NewFavorites;
		EndIf;
		
		SettingsDescription = New SettingsDescription;
		SettingsDescription.Presentation = Setting.Presentation;
		SettingsStorage.Save(Setting.ObjectKey, Setting.SettingsKey, Setting.Settings, SettingsDescription, Setting.User);
	EndDo;
		
	XMLReader.Close();
	
EndProcedure

// Loads sequence boundaries from a file.
//
// Parameters:
// 	ImportParameters - See ImportParameters
Procedure LoadSequenceBoundaries(ImportParameters)
	
	File = New File(ImportParameters.ImportDirectory + "SequenceBounds.xml");
	If Not File.Exists() Then
		Return;
	EndIf;
	
	ReplaceLinksWhenLoadingFromXMLFile(File.FullName, ImportParameters);
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(ImportParameters.ImportDirectory + "SequenceBounds.xml");
	XMLReader.MoveToContent();
	
	If XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.Name <> "Data" Then
		Raise(NStr("vi = 'Lỗi đọc XML. Sai định dạng tệp. Chờ bắt đầu phần tử ""Data"".';
					|ru = 'Ошибка чтения XML. Неверный формат файла. Ожидается начало элемента ""Data"".';
					|en = 'XML reading error. Invalid file format. Start of ""Data"" element is expected.'; fa = 'XML reading error. Invalid file format. Start of ""Data"" element is expected.';
					|it = 'Errore di lettura XML. Formato file errato. Atteso l''inizio dell''elemento ""Data"".';
					|pl = 'Błąd odczytu XML. Błędny format pliku. Oczekiwany jest początek elementu ""Дата"".';
					|tr = 'XML okuma hatası. Hatalı dosya formatı. ""Data"" öğesinin başlangıcı bekleniyor.'"));
	EndIf;
	
	XMLReader.Read();
	While XMLReader.NodeType = XMLNodeType.StartElement Do
		
		SequenceName = XMLReader.Name;
		Boundaries = XDTOSerializer.ReadXML(XMLReader);
		
		Filter = New Structure;
		For Each Dimension In Metadata.Sequences[SequenceName].Dimensions Do
			Filter.Insert(MetadataObjectName(Dimension));
		EndDo;
		
		For Each Boundary In Boundaries Do
			FillPropertyValues(Filter, Boundary);
			PointInTime = New PointInTime(Boundary.Period, Boundary.Recorder);
			Sequences[SequenceName].SetBound(PointInTime, Filter);
		EndDo;
		
	EndDo;
		
	XMLReader.Close();
	
EndProcedure

// Loads the composition of the standard interface.
//
// Parameters:
//   ImportDirectory - String - full name of the folder.
//
Procedure LoadCompositionOfStandardODataInterface(ImportDirectory)
	
	File = New File(ImportDirectory + "StandardODataInterfaceContent.xml");
	If Not File.Exists() Then
		Return;
	EndIf;
	
	Content = ReadDataFromFile(ImportDirectory + "StandardODataInterfaceContent.xml");
	
	MetadataObjects = New Array;
	For Each ObjectName In Content Do
		MetadataObjects.Add(Metadata.FindByFullName(ObjectName));
	EndDo;
		
	SetStandardODataInterfaceContent(MetadataObjects);
	
EndProcedure

// Loads subsystem versions.
//
// Parameters:
//   ImportDirectory - String - full name of the folder.
//
Procedure DownloadSubsystemVersions(ImportDirectory)
	
	SubsystemsVersions = ReadDataFromFile(ImportDirectory + "SubsystemsVersions.xml");
	
	For Each SubsystemVersion In SubsystemsVersions Do
		InfobaseUpdateInternal.SetIBVersion(SubsystemVersion.Key, SubsystemVersion.Value, (SubsystemVersion.Key = Metadata.Name));
		InfobaseUpdateInternalSaaS.OnMarkDeferredUpdateHandlersRegistration(SubsystemVersion.Key, True, True);
	EndDo;
	
EndProcedure

// Writes data to a file, and the data is serialized in XML.
//
// Parameters:
//   Data - Arbitrary - any type that is serialized to XML.
//   FileName - String - full file name.
//
Procedure WriteDataToFile(Data, FileName) Export
	
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(FileName);
	XDTOSerializer.WriteXML(XMLWriter, Data, XMLTypeAssignment.Explicit);
	XMLWriter.Close();
	
EndProcedure

// Reads data from a file.
//
// Parameters:
//   FileName - String - full file name.
//
// Returns:
//   Arbitrary - any type that is serialized to XML.
//
Function ReadDataFromFile(FileName) Export
	
	File = New File(FileName);
	If Not File.Exists() Then
		Return Undefined;
	EndIf;
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(FileName);
	Data = XDTOSerializer.ReadXML(XMLReader);
	XMLReader.Close();
	
	Return Data;
	
EndFunction

// Verifies the use of the separation session, if the division is not used, then the exception is thrown.
//
Procedure CheckSessionSharingUsage()
	
	If Not SaaSOperations.SeparatedDataUsageAvailable() Then
		Raise NStr("vi = 'Có thể thực hiện chỉ trong phiên làm việc đã chia tách.';
					|ru = 'Выполнение возможно только в разделенном сеансе.';
					|en = 'Can be executed only in separated session.'; fa = 'Can be executed only in separated session.';
					|it = 'L''esecuzione è possibile solo in una sessione separata.';
					|pl = 'Wykonanie jest możliwe tylko w podzielonej sesji.';
					|tr = 'Yürütme ancak ayrılmış oturumda gerçekleştirilebilir.'");
	EndIf;
	
EndProcedure

// Clears the download queue.
Procedure DeleteQueue()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ApplicationsMigrationImportQueue.FileName AS FileName
	|FROM
	|	InformationRegister.ApplicationsMigrationImportQueue AS ApplicationsMigrationImportQueue";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		FilesCTL.DeleteTemporaryStorageFile(Selection.FileName);
	EndDo;
	
	RecordSet = InformationRegisters.ApplicationsMigrationImportQueue.CreateRecordSet();
	RecordSet.Write();
	
EndProcedure

// The designer of a data table.
//
// Returns:
//   ValueTable - table with columns:
//     * MetadataObject - String - full name of the metadata.
//     * Id - String - object ID, the sequence number given to the string representation.
//     * RecordsCount - Number - the number of unloaded objects.
//
Function DataTable() Export
	
	Data = New ValueTable;
	Data.Columns.Add("MetadataObject", New TypeDescription("String"));
	Data.Columns.Add("Id", New TypeDescription("String"));
	Data.Columns.Add("RecordsCount", New TypeDescription("Number"));
	
	Return Data;
	
EndFunction

Procedure AddAuxiliaryDataFromXMLFile(FileName, ExportingParameters) Export
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(FileName);
	
	AddAuxiliaryDataFromXML(XMLReader, ExportingParameters);
	
EndProcedure

Procedure AddAuxiliaryDataFromXMLString(String, ExportingParameters)
	
	XMLReader = New XMLReader;
	XMLReader.SetString(String);
	
	AddAuxiliaryDataFromXML(XMLReader, ExportingParameters);
	
EndProcedure

Procedure AddAuxiliaryDataFromXML(XMLReader, ExportingParameters)
	
	ValueType = Undefined;
	While XMLReader.Read() Do
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			ValueType = Undefined;
			While XMLReader.ReadAttribute() Do
				If XMLReader.LocalName = "type" 
					And XMLReader.NamespaceURI = "http://www.w3.org/2001/XMLSchema-instance"  Then
					Parts = StrSplit(XMLReader.Value, ":");
					If Parts.Count() = 1 Then
						Prefix = "";
						TypeName = Parts[0];
					Else
						Prefix = Parts[0];
						TypeName = Parts[1];
					EndIf;
					
					If Not XMLReader.LookupNamespaceURI(Prefix) = "http://v8.1c.ru/8.1/data/enterprise/current-config" 
						Or (ExportingParameters.TypesOfSharedDataToBeMatchedBySearchFields.Get(Type(TypeName)) = Undefined 
						And ExportingParameters.TypesOfMappedSharedDataByPredefinedName.Get(Type(TypeName)) = Undefined) Then
						ValueType = Undefined;
					Else
						ValueType = Type(TypeName);	
					EndIf;
				EndIf;
			EndDo;
			
		ElsIf ValueType <> Undefined And XMLReader.NodeType = XMLNodeType.Text Then
			
			TypeParameters = New Array;
			TypeParameters.Add(New UUID(XMLReader.Value));
			Value = New(ValueType, TypeParameters);
			If Not Value.IsEmpty() Then
				ExportingParameters.GeneralDataLinks.Insert(Value, True);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	XMLReader.Close();
	
EndProcedure

// Generates the file name based on the subdirectory, according to the rule that the folder should contain no more than 1000 files.
//
// Parameters:
//   Directory - String - full name of the folder, used to create a subdirectory.
//   FilesCount - Number - a variable that accumulates the number of files in the folder.
//
// Returns:
//	String - file name.
//
Function GenerateFileName(Directory, FilesCount) Export
	
	FileName = Format(FilesCount % 1000, "ND=3; NZ=000; NLZ=; NG=0");
	DirectoryNumber = Int(FilesCount / 1000);
	Subdirectory = ?(DirectoryNumber = 0, "", Format(DirectoryNumber, "NG=0") + GetPathSeparator());
	
	If FilesCount % 1000 = 0 Then
		CreateDirectory(Directory + GetPathSeparator() + Subdirectory);
	EndIf;
	
	FilesCount = FilesCount + 1;
	
	Return Subdirectory + FileName;
	
EndFunction

// Records the correspondence of frequently used namespaces, this slightly reduces the size of the xml.
//
// Parameters:
//   XMLWriter - XMLWriter -
//
Procedure RecordCorrespondenceOfNamespaces(XMLWriter) Export
	
	XMLWriter.WriteNamespaceMapping("xs", "http://www.w3.org/2001/XMLSchema");
	XMLWriter.WriteNamespaceMapping("xi", "http://www.w3.org/2001/XMLSchema-instance");
	XMLWriter.WriteNamespaceMapping("v8", "http://v8.1c.ru/8.1/data/core");
	XMLWriter.WriteNamespaceMapping("en", "http://v8.1c.ru/8.1/data/enterprise");
	XMLWriter.WriteNamespaceMapping("cc", "http://v8.1c.ru/8.1/data/enterprise/current-config");
	
EndProcedure

// Returns all types of exchange nodes.
//
// Returns:
//  Map of KeyAndValue - collection of node types:
//   * Key - Type
//   * Value - Boolean
//
Function TypesOfExchangeNodes() Export
	
	Types = New Map;
	
	For Each ExchangePlan In ExchangePlans Do
		Types.Insert(TypeOf(ExchangePlan.EmptyRef()), True);
	EndDo;
	
	Return Types;
	
EndFunction

// Returns a collection of exchange plan nodes that have this node = True;
//
// Returns:
//   Array of ExchangePlanRef
//
Function AllTheseNodes() Export
	
	Nodes = New Array;
	
	For Each MetadataObject In Metadata.ExchangePlans Do
		Nodes.Add(ExchangePlans[MetadataObject.Name].ThisNode());
	EndDo;
	
	Return Nodes;
	
EndFunction

// Returns a collection of account names that contain the value Store type.
//
// Parameters:
//   Attributes - MetadataObjectCollection - collection of Bank details.
//
// Returns:
//   Array of String - an array of details with the storage type of the value.
//
Function StorageDetails(Attributes) Export
	
	StorageDetails = New Array;
	
	For Each Attribute In Attributes Do
		If Attribute.Type.ContainsType(Type("ValueStorage")) Then
			StorageDetails.Add(Attribute.Name);
		EndIf;
	EndDo;
	
	Return StorageDetails;
	
EndFunction

// Searches for a match for each shared data link by a predefined name.
//
// Parameters:
//   MetadataObject - MetadataObjectCatalog, MetadataObjectChartOfCharacteristicTypes - 
//					  - MetadataObjectChartOfCalculationTypes - the metadata object to be mapped to.
//   Objects - Array - array of links to be mapped to.
//   SharedData - Map - the collection where the link match is placed.
//
Procedure MatchSharedDataByPredefinedName(MetadataObject, Objects, SharedData) Export
	
	ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	
	For Each Object In Objects Do
		Ref = ?(ValueIsFilled(Object.Ref), Object.Ref, Object.GetNewObjectRef());
		SharedData.Insert(Ref, ObjectManager[Object.PredefinedDataName]);
	EndDo;
	
EndProcedure

// Searches for a match for each shared data link by key search fields.
//
// Parameters:
//  MetadataObject - MetadataObjectCatalog, MetadataObjectChartOfCharacteristicTypes - 
//					  - MetadataObjectChartOfCalculationTypes - the metadata object to be mapped to.
//  Objects - Array - array of links to be mapped to.
//  SharedData - Map of KeyAndValue - the collection where the matching links are placed:
//   * Key - AnyRef
//   * Value - AnyRef
//
Procedure MatchGeneralDataBySearchFields(MetadataObject, Objects, SharedData) Export
	
	ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	
	Fields = ObjectManager.NaturalKeyFields();
	ObjectsFields = StrConcat(Fields, ", ");
	ConnectionConditions = New Array;
	ReplacementFields = New Array;
	
	ObjectsTable = New ValueTable;
	ObjectsTable.Columns.Add("Ref", TypeOfReferenceObject(MetadataObject));
	For Each Field In Fields Do
		FieldType = TypeOfSearchField(MetadataObject, Field);
		ObjectsTable.Columns.Add(Field, FieldType);
		ConnectionConditions.Add(StrTemplate("%1.%3 = %2.%3", "ObjectsTable", "CatalogTable", Field));
		// Link Replacements
		For Each Type In FieldType.Types() Do
			If Metadata.FindByType(Type) <> Undefined Then
				ReplacementFields.Add(Field);
			EndIf;
		EndDo;
	EndDo;
	
	For Each Object In Objects Do
		For Each Field In ReplacementFields Do
			NewValue = SharedData[Object[Field]];
			If NewValue <> Undefined Then
				Object[Field] = NewValue;
			EndIf;
		EndDo;
		NewRow = ObjectsTable.Add(); 
		FillPropertyValues(NewRow, Object);
		If Not ValueIsFilled(NewRow.Ref) Then
			NewRow.Ref = Object.GetNewObjectRef();
		EndIf;
	EndDo;
	
	// The field name of the defined data cannot be used in connection conditions
	If Fields.Find("PredefinedDataName") = Undefined Then
	
		Query = New Query;
		Query.SetParameter("ObjectsTable", ObjectsTable);
		Query.Text =
		"SELECT
		|	ObjectsTable.Ref AS Ref,
		|	&ObjectsFields
		|INTO ObjectsTable
		|FROM
		|	&ObjectsTable AS ObjectsTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ObjectsTable.Ref AS OldLink,
		|	CatalogTable.Ref AS NewRef
		|FROM
		|	ObjectsTable AS ObjectsTable
		|		INNER JOIN &CatalogTable AS CatalogTable
		|		ON &ConnectionConditions";
		
		Query.Text = StrReplace(Query.Text, "&CatalogTable", MetadataObject.FullName());
		Query.Text = StrReplace(Query.Text, "&ObjectsFields", ObjectsFields);
		Query.Text = StrReplace(Query.Text, "&ConnectionConditions", StrConcat(ConnectionConditions, " And "));

		Selection = Query.Execute().Select();
		While Selection.Next() Do
			SharedData.Insert(Selection.OldLink, Selection.NewRef);
		EndDo;
		
	Else
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	CatalogTable.Ref,
		|	&ObjectsFields
		|FROM
		|	&CatalogTable AS CatalogTable";
		
		Query.Text = StrReplace(Query.Text, "&CatalogTable", MetadataObject.FullName());
		Query.Text = StrReplace(Query.Text, "&ObjectsFields", ObjectsFields);
		CatalogTable = Query.Execute().Unload();
		CatalogTable.Indexes.Add(ObjectsFields);

		For Each Object In ObjectsTable Do
			Search = New Structure(ObjectsFields);
			FillPropertyValues(Search, Object);
			FoundRows = CatalogTable.FindRows(Search);
			If FoundRows.Count() > 0 Then
				SharedData.Insert(Object.Ref, FoundRows[0].Ref);
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// Returns the order of matching shared data.
//
// Returns:
//   Array - array of metadata objects
//
Function OrderOfComparisonOfCommonData()
	
	TypesOfSharedData = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
		
	Count_ = New Map;
	
	// Filling in the vertices of the graph.
	For Each MetadataObject In TypesOfSharedData Do
		Count_.Insert(MetadataObject, New Structure("Object, Dependencies, Color", MetadataObject, New Array, 0));
	EndDo;
	For Each Type In ApplicationsMigrationCached.TypesOfMappedSharedDataByPredefinedName() Do
		MetadataObject = Metadata.FindByType(Type.Key);
		Count_.Insert(MetadataObject, New Structure("Object, Dependencies, Color", MetadataObject, New Array, 0));
	EndDo;
	
	// Filling in the edges of the graph.
	For Each MetadataObject In TypesOfSharedData Do
		ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		For Each FieldForSearch In ObjectManager.NaturalKeyFields() Do
			For Each Type In TypeOfSearchField(MetadataObject, FieldForSearch).Types() Do
				FoundObject = Metadata.FindByType(Type);
				If FoundObject = Undefined Then
					Continue;
				EndIf;
				ObjectDependencies_ = Count_[MetadataObject].Dependencies; // Array
				ObjectDependencies_.Add(FoundObject);
			EndDo;
		EndDo;
	EndDo;
	
	// Topological sorting.
	Order = New Array;
	For Each Vertex In Count_ Do
		DepthFirstSearch(Count_, Vertex.Value, Order);
	EndDo;
	
	Return Order;
	
EndFunction

// The "deep Search" algorithm (recursive).
//
// Parameters:
//   Count_ - Map of KeyAndValue- collection of objects, their dependencies and colors:
//     * Key - Arbitrary - the key is used for quick search.
//     * Value - Structure:
//         ** Object - Arbitrary - the object that the dependency is being built for.
//         ** Dependencies - Array - array of objects that are used in the Object.
//         ** Color - Number - 0,1,2 - white, gray, black.
//   Vertex - Structure - For a description, see the Graph parameter.Meaning.
//   Order - Array of MetadataObject - an array of metadata objects that will contain the result after execution.
//
Procedure DepthFirstSearch(Count_, Vertex, Order) Export
	
	// If the vertex is "gray", then a cycle has been found, topological sorting is impossible.
	If Vertex.Color = 1 Then
		
		Raise NStr("vi = 'Phụ thuộc đệ quy.';
					|ru = 'Рекурсивная зависимость.';
					|en = 'Recursive dependence.'; fa = 'Recursive dependence.';
					|it = 'Dipendenza ricorsiva.';
					|pl = 'Zależność rekurencyjna.';
					|tr = 'Tekrarlamalı bağımlılık.'");
		
	ElsIf Vertex.Color = 0 Then
		
		// At the entrance, the vertex becomes "gray".
		Vertex.Color = 1;
		
		// From each vertex we make a detour into the depth.
		For Each Object In Vertex.Dependencies Do
			NewPeak = Count_[Object];
			If NewPeak <> Undefined Then
				DepthFirstSearch(Count_, NewPeak, Order);
			EndIf;
		EndDo;
		
		// When exiting, the vertex becomes "black".
		Vertex.Color = 2;
		// And at the same time it is entered into the final list.
		Order.Add(Vertex.Object);
		
	EndIf;
	
EndProcedure

// Returns the field type by name.
//
// Parameters:
//   MetadataObject - MetadataObject - the object whose field you want to analyze.
//   FieldName - String - field name.
//
// Returns:
//   TypeDescription - field type.
//
Function TypeOfSearchField(MetadataObject, FieldName) Export
	
	For Each Attribute In MetadataObject.StandardAttributes Do
		If Attribute.Name = FieldName Then
			Return Attribute.Type;
		EndIf;
	EndDo;
	
	Attribute = MetadataObject.Attributes.Find(FieldName);
	If Attribute <> Undefined Then
		Return Attribute.Type;
	EndIf;
	
	CommonAttribute = Metadata.CommonAttributes.Find(FieldName);
	If CommonAttribute <> Undefined And CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.DontUse Then
		CompositionItem = CommonAttribute.Content.Find(MetadataObject);
		If CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Use
			Or CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Auto 
			And CommonAttribute.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use Then
			Return CommonAttribute.Type;			
		EndIf;
	EndIf;
	
	Raise StrTemplate(NStr("vi = 'Không thể sử dụng trường %1 để làm trường khóa tự nhiên của đối tượng %2:
		|không tìm thấy trường đối tượng';
		|ru = 'Поле %1 не может использоваться в качестве поля естественного ключа объекта %2:
		|поле объекта не обнаружено';
		|en = 'Cannot use the %1 field as a natural key field of %2 object:
		|the object field is not found'; fa = 'Cannot use the %1 field as a natural key field of %2 object:
		|the object field is not found';
		|it = 'Il campo %1 non può essere usato come campo della chiave naturale dell''oggetto %2:
		| campo dell''oggetto non trovato';
		|pl = 'Pole %1 nie może być używane jako pole naturalnego klucza obiektu %2:
		| nie odnaleziono pola obiektu';
		|tr = '%1 alanı, %2 nesnesinin doğal anahtar alanı olarak kullanılamaz:
		|nesne alanı bulunamadı'", Common.DefaultLanguageCode()),
		FieldName,
		MetadataObject.FullName());
	
EndFunction

// Deletes all records of the specified objects from the database.
//
// Parameters:
//   ObjectsToClear - Map - as the key of the metadata Object to clear.
//
Procedure ClearUserData(ObjectsToClear) Export
	
	MetadataForInitializingPredefined = New Array;
	For Each KeyAndValue In ObjectsToClear Do
		
		MetadataObject = Metadata.FindByFullName(KeyAndValue.Key);
		
		If Metadata.Constants.Contains(MetadataObject) Then
			
			ValueManager = Constants[MetadataObject.Name].CreateValueManager();
			ValueManager.Value = Undefined;
			ValueManager.DataExchange.Load = True;
			ValueManager.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
			ValueManager.Write();
			
		ElsIf Metadata.Catalogs.Contains(MetadataObject)
			Or Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject)
			Or Metadata.ChartsOfAccounts.Contains(MetadataObject)
			Or Metadata.ChartsOfCalculationTypes.Contains(MetadataObject) Then
			
			ClearReferenceType(MetadataObject);
			MetadataForInitializingPredefined.Add(MetadataObject);
			
		ElsIf Metadata.Tasks.Contains(MetadataObject) 
			Or Metadata.Documents.Contains(MetadataObject)
			Or Metadata.BusinessProcesses.Contains(MetadataObject) Then
			
			ClearReferenceType(MetadataObject);
			
		ElsIf Metadata.InformationRegisters.Contains(MetadataObject)
			Or Metadata.AccumulationRegisters.Contains(MetadataObject) 
			Or Metadata.CalculationRegisters.Contains(MetadataObject) 
			Or Metadata.CalculationRegisters.Contains(MetadataObject.Parent())
			Or Metadata.AccountingRegisters.Contains(MetadataObject) 
			Or Metadata.Sequences.Contains(MetadataObject) Then
			
			ClearRecordSet(MetadataObject);
			
		EndIf;
		
	EndDo;
	
	For Each ObjectWithPredefined In MetadataForInitializingPredefined Do
		Manager = Common.ObjectManagerByFullName(ObjectWithPredefined.FullName());
		Manager.SetPredefinedDataInitialization(False);
	EndDo;
		
	ObjectsToClear.Clear();
	
EndProcedure

Procedure ReplaceLinksWhenLoadingFromXMLFile(FileName, ImportParameters)
	
	TimeFile = GetTempFileName("xml");
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(TimeFile);
	XMLWriter.WriteXMLDeclaration();
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(FileName);
	
	ReplaceLinksWhenLoadingFromXML(XMLReader, XMLWriter, ImportParameters);
	
	XMLReader.Close();
	XMLWriter.Close();
	
	MoveFile(TimeFile, FileName);
	
EndProcedure

Procedure ReplaceLinksWhenLoadingFromXML(XMLReader, XMLWriter, ImportParameters)
	
	While XMLReader.Read() Do
		
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			
			XMLWriter.WriteStartElement(XMLReader.Name);
			
			ValueType = Undefined;
			While XMLReader.ReadAttribute() Do
				
				XMLWriter.WriteAttribute(XMLReader.Name, XMLReader.Value);
				
				If XMLReader.LocalName = "type" And XMLReader.NamespaceURI = "http://www.w3.org/2001/XMLSchema-instance" Then
					Parts = StrSplit(XMLReader.Value, ":");
					If Parts.Count() = 1 Then
						Prefix = "";
						TypeName = Parts[0];
					Else
						Prefix = Parts[0];
						TypeName = Parts[1];
					EndIf;
					If XMLReader.LookupNamespaceURI(Prefix) = "http://v8.1c.ru/8.1/data/enterprise/current-config" Then
						ValueType = Type(TypeName);
					EndIf;
				EndIf;
			EndDo;
			
		ElsIf XMLReader.NodeType = XMLNodeType.Text Then
			
			If ValueType = Undefined Then
				XMLWriter.WriteText(XMLReader.Value);
			Else
				NewValue = GetLinkWhenUploading(ValueType, XMLReader.Value, ImportParameters);
				XMLWriter.WriteText(NewValue);
			EndIf;
			
		ElsIf XMLReader.NodeType = XMLNodeType.EndElement Then
			
			XMLWriter.WriteEndElement();
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function GetLinkWhenUploading(ValueType, PreviousValue2, ImportParameters)
	
	NewValue = PreviousValue2;
	
	If ImportParameters.TypesOfSharedDataToBeMatchedBySearchFields[ValueType] <> Undefined Then
		
		TypeParameters = New Array;
		TypeParameters.Add(New UUID(PreviousValue2));
		OldLink = New(ValueType, TypeParameters);
		
		If ValueIsFilled(OldLink) Then
			NewRef = ImportParameters.SharedData[OldLink];
			If NewRef <> Undefined Then
				NewValue = String(NewRef.UUID());
			EndIf;
		EndIf
		
	ElsIf ImportParameters.TypesOfLinksToBeRecreated[ValueType] <> Undefined Then
		
		TypeParameters = New Array;
		TypeParameters.Add(New UUID(PreviousValue2));
		OldLink = New(ValueType, TypeParameters);
		
		If ValueIsFilled(OldLink) Then
			NewRef = ImportParameters.RefsMap[OldLink];
			If NewRef = Undefined Then
				TypeParameters = New Array;
				TypeParameters.Add(New UUID);
				NewRef = New(ValueType, TypeParameters);
				ImportParameters.RefsMap.Insert(OldLink, NewRef);
			EndIf;
			NewValue = String(NewRef.UUID());
		EndIf;
		
	ElsIf ImportParameters.TypesOfMappedSharedDataByPredefinedName[ValueType] <> Undefined Then
		
		TypeParameters = New Array;
		TypeParameters.Add(New UUID(PreviousValue2));
		OldLink = New(ValueType, TypeParameters);
		
		If ValueIsFilled(OldLink) Then
			NewRef = ImportParameters.SharedData[OldLink];
			If NewRef <> Undefined Then
				NewValue = String(NewRef.UUID());
			EndIf;
		EndIf;
		
	ElsIf ImportParameters.TypesOfExchangeNodes[ValueType] <> Undefined Then
		
		TypeParameters = New Array;
		TypeParameters.Add(New UUID(PreviousValue2));
		OldLink = New(ValueType, TypeParameters);
		
		If ValueIsFilled(OldLink) Then
			NewRef = ImportParameters.RefsMap[OldLink];
			If NewRef <> Undefined Then
				NewValue = String(NewRef.UUID());
			EndIf;
		EndIf;
		
	ElsIf ImportParameters.ProhibitedTypesOfSharedData[ValueType] <> Undefined Then
		
		TypeParameters = New Array;
		TypeParameters.Add(New UUID(PreviousValue2));
		OldLink = New(ValueType, TypeParameters);
		
		If ValueIsFilled(OldLink) Then
			Raise StrTemplate(NStr("vi = 'Trong đối tượng đã tìm thấy tham chiếu không hợp lệ. Kiểu dữ liệu: %1';
									|ru = 'В объекте обнаружена недопустимая ссылка. Тип данных: %1';
									|en = 'Invalid link is found in the object. Data type: %1'; fa = 'Invalid link is found in the object. Data type: %1';
									|it = 'Viene rilevato un riferimento non valido nell''oggetto. Tipo di dati: %1';
									|pl = 'W obiekcie jest ujawniony niedopuszczalny odnośnik. Typ danych: %1';
									|tr = 'Nesnede izin verilmeyen bağlantı bulundu. Veri türü: %1'"), OldLink.Metadata().FullName());
		EndIf;
		
	EndIf;
	
	Return NewValue;
	
EndFunction


// Adds links read from the file to the passed collection.
//
// Parameters:
//  RefsMap - Map of KeyAndValue - collection of matching links:
//   * Key - AnyRef
//   * Value - AnyRef
//  ImportDirectory - String - full name of the folder where the download is being made.
//
// Returns:
//  Map of KeyAndValue:
//   * Key - AnyRef
//   * Value - AnyRef
//
Function ReadMatchingLinks(Val RefsMap, ImportDirectory) Export
	
	File = New File(ImportDirectory + "ThisNodes.xml");
	If File.Exists() Then
		
		TheseNodes = ReadDataFromFile(ImportDirectory + "ThisNodes.xml"); // Array of ExchangePlanRef
		
		For Each OldNode In TheseNodes Do
			RefsMap.Insert(OldNode, ExchangePlans[OldNode.Metadata().Name].ThisNode());
		EndDo;
		
	EndIf;
	
	Return RefsMap;
	
EndFunction

// Parses the navigation link and presents it as an XDTO object.
//
// Parameters:
//   URL - String - navigation links.
//
// Returns:
//   Structure - serialized object Structure with keys:
//     * URL - String - the converted navigation link
//                                      differs from the original navigation link in that the links are highlighted and replaced with parameters.
//     * Replacement - Map - the consistency of the parameters and links.
//
Function ConvertNavigationLinkToStructure(Val URL)
	
	If Not StrStartsWith(URL, "e1cib/data/") Then
		Return Undefined;
	EndIf;
	
	URL = DecodeString(URL, StringEncodingMethod.URLEncoding);
	
	StartOfParameters = StrFind(URL, "?");
	PathToMetadataObject = Mid(URL, 12, StartOfParameters - 12);
	PathParts = StrSplit(PathToMetadataObject, ".");
	
	MetadataObject = Metadata.FindByFullName(PathParts[0] + "." + PathParts[1]); // MetadataObjectCatalog
	If MetadataObject = Undefined Then
		Return Undefined;
	EndIf;
	
	IsReferenceObject = CommonCTL.IsRefData(MetadataObject);
	ItIsIndependentRegister = Metadata.InformationRegisters.Contains(MetadataObject) And MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent;
	
	If Not IsReferenceObject And Not ItIsIndependentRegister Then
		Return Undefined;
	EndIf;
	
	TypesOfParameters_ = New Structure;
	If IsReferenceObject Then
		TypesOfParameters_.Insert("ref", MetadataObject.StandardAttributes.Ref.Type);
		TypesOfParameters_.Insert("index", New TypeDescription("Number"));
	Else 
		For Each Attribute In MetadataObject.StandardAttributes Do
			TypesOfParameters_.Insert(Attribute.Name, Attribute.Type);
		EndDo;
		For Each Attribute In MetadataObject.Dimensions Do
			TypesOfParameters_.Insert(Attribute.Name, Attribute.Type);
		EndDo;
	EndIf;
	
	URLParameters = New Array;
	FavoritesElement = New Structure("URL, Replacement", URL, New Map);
	
	ParametersString1 = Mid(URL, StartOfParameters + 1);
	For Each Parameter In StrSplit(ParametersString1, "&") Do
		
		EqualsSign = StrFind(Parameter, "=");
		ParameterName = Left(Parameter, EqualsSign - 1);
		ParameterValue = Mid(Parameter, EqualsSign + 1);
		ParameterType = TypesOfParameters_[ParameterName];
		If ParameterType.Types().Count() = 1 Then
			RefType = ParameterType.Types()[0];
		Else
			// Composite type.
			RefType = Type(Left(ParameterValue, StrFind(ParameterValue, ":") - 1));
		EndIf;
		
		RefMetadata = Metadata.FindByType(RefType); 
		If RefMetadata = Undefined Then
			URLParameters.Add(Parameter);
		Else
			Id = UniqueIdentifierFromLine32(Mid(ParameterValue, StrFind(ParameterValue, ":") + 1));
			ConstructorParameters = New Array;
			ConstructorParameters.Add(Id);
			ParameterReference = New (RefType, ConstructorParameters);
			
			ReplacementID = String(New UUID);
			NewParameterValue_ = Left(ParameterValue, StrFind(ParameterValue, ":")) + ReplacementID;
			URLParameters.Add(ParameterName + "=" + EncodeString(NewParameterValue_, StringEncodingMethod.URLEncoding));
			FavoritesElement.Replacement.Insert(ReplacementID, ParameterReference);
		EndIf;
			
	EndDo;
	
	NewNavigationLink = "e1cib/data/" + PathToMetadataObject + "?" + StrConcat(URLParameters, "&");
	FavoritesElement.URL = NewNavigationLink;
	
	Return FavoritesElement;
	
EndFunction

// Converts the unique identifier representation for the navigation link to a unique identifier.
//
// Parameters:
//   Representation - String - representation of a unique identifier.
//
// Returns:
//   UUID - the received ID.
//
Function UniqueIdentifierFromLine32(Val Representation)
	
	Term1 = Mid(Representation, 25, 8);
	Term2 = Mid(Representation, 21, 4);
	Term3 = Mid(Representation, 17, 4);
	Term4 = Mid(Representation, 1,  4);
	Term5 = Mid(Representation, 5,  12);
	
	Return New UUID(Term1 + "-" + Term2 + "-" + Term3 + "-" + Term4 + "-" + Term5);
	
EndFunction

// Converts the unique ID to the format of the navigation link ID.
//
// Parameters:
//   Id - UUID - which you want to convert.
//
// Returns:
//   String - string representation.
//
Function UniqueIDPerLine32(Val Id)
	
	LinkID = String(Id);
	
	Return Mid(LinkID, 20, 4) + Mid(LinkID, 25) + Mid(LinkID, 15, 4) + Mid(LinkID, 10, 4) + Mid(LinkID, 1, 8);
	
EndFunction

// Adds all users with the full Rights role to the Administrators access group.
//
Procedure AddFullUsersToAdministratorsGroupAndUpdateRolesForOtherUsers()
	
	UsersIDs = New Array;
	For Each User In InfoBaseUsers.GetUsers() Do
		If User.Roles.Contains(Metadata.Roles.FullAccess) Then
			UsersIDs.Add(User.UUID);
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("UsersIDs", UsersIDs);
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.IBUserID IN(&UsersIDs)";
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		CatObject = AccessManagement.AdministratorsAccessGroup().GetObject();
		Selection = Result.Select();
		While Selection.Next() Do
			
			UserObject = Selection.Ref.GetObject(); // CatalogObject.Users
			
			// In the new area, the user has only two types of CI.
			For Each CIRow In UserObject.ContactInformation Do
				If CIRow.Type = Enums.ContactInformationTypes.Phone Then
					CIRow.Kind = Catalogs.ContactInformationKinds.UserPhone;
					CIRow.KindForList = Catalogs.ContactInformationKinds.UserPhone;
				ElsIf  CIRow.Type = Enums.ContactInformationTypes.Email Then
					CIRow.Kind = Catalogs.ContactInformationKinds.UserEmail;
					CIRow.KindForList = Catalogs.ContactInformationKinds.UserEmail;
				EndIf;
			EndDo;
			
			If CatObject.Users.Find(Selection.Ref, "User") = Undefined Then
				UserObject.AdditionalProperties.Insert("CreateAdministrator", NStr("vi = 'Tạo người quản trị vùng dữ liệu khi di chuyển ứng dụng.';
																					|ru = 'Создание администратора области данных при миграции приложения.';
																					|en = 'Create data area administrator during application migration.'; fa = 'Create data area administrator during application migration.';
																					|it = 'Creare un amministratore dell''area dati durante la migrazione dell''applicazione.';
																					|pl = 'Utworzenie administratora obszaru danych podczas migracji aplikacji.';
																					|tr = 'Uygulama geçişinde veri alanı yöneticisi oluşturma.'"));
				CatObject.Users.Add().User = Selection.Ref;
			EndIf;
			
			UserObject.Write();
			
		EndDo;
		CatObject.DataExchange.Load = True;
		CatObject.Write();
	EndIf;
	
	AccessManagement.UpdateUserRoles();
	
EndProcedure

// Adds all nodes of the application Migration exchange plan to the source as recipients.
//
// Parameters:
//   Source - CatalogObject, DocumentObject, InformationRegisterRecordSet - an object that is registered in the exchange plan.
//
// @unavailable-in-safemode
Procedure RecordChanges(Source)
	
	If Source.AdditionalProperties.Property("DisableObjectChangeRecordMechanism") Then
		Return;
	EndIf;
	
	If Source.AdditionalProperties.Property("TypeExcludedFromUploadUpload") Then
		Return;
	EndIf;
	
	SeparatedDataUsageAvailable = Common.SeparatedDataUsageAvailable();
	
	If SeparatedDataUsageAvailable And Not GetFunctionalOption("ApplicationsMigrationUsed") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If ApplicationsMigrationCached.UnloadedObjects().Get(Source.Metadata()) <> Undefined Then
		
		If Not ExtensionObjectIsPartOfExchangePlan(Source.Metadata()) Then
			Return;
		EndIf;
		
		Query = New Query;
		
		If SeparatedDataUsageAvailable Then
			Query.Text =
			"SELECT
			|	ApplicationsMigration.Ref AS Ref
			|FROM
			|	ExchangePlan.ApplicationsMigration AS ApplicationsMigration
			|WHERE
			|	NOT ApplicationsMigration.ThisNode";
		Else
			If Metadata.InformationRegisters.Contains(Source.Metadata()) Then
				// @skip-warning PropertyNotFound - verification error.
				Query.SetParameter("DataArea", Source.Filter.DataAreaAuxiliaryData.Value);
			Else
				Query.SetParameter("DataArea", Source.DataAreaAuxiliaryData);
			EndIf;
			Query.Text =
			"SELECT
			|	ApplicationsMigration.Ref AS Ref
			|FROM
			|	ExchangePlan.ApplicationsMigration AS ApplicationsMigration
			|WHERE
			|	NOT ApplicationsMigration.ThisNode
			|	AND ApplicationsMigration.DataAreaMainData = &DataArea";
		EndIf;
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			Source.DataExchange.Recipients.Add(Selection.Ref);
		EndDo;
			
	EndIf;
	
EndProcedure

// Returns the sorted order for selecting metadata objects based on the last uploaded object.
//
// Parameters:
//   LastObject - String - full name of the metadata object.
//
// Returns:
//   Array - array of full names of metadata objects.
//
Function MetadataSamplingOrder(LastObject)
	
	Objects = New ValueList;
	
	For Each KeyAndValue In ApplicationsMigrationCached.UnloadedObjects() Do
		
		MetadataObject = KeyAndValue.Key;
		
		Order = "12";
		If Metadata.Constants.Contains(MetadataObject) Then
			Order = "00";
		ElsIf Metadata.Catalogs.Contains(MetadataObject) Then
			Order = "01";
		ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject) Then
			Order = "02";
		ElsIf Metadata.ChartsOfAccounts.Contains(MetadataObject) Then
			Order = "03";
		ElsIf Metadata.ChartsOfCalculationTypes.Contains(MetadataObject) Then
			Order = "04";
		ElsIf Metadata.InformationRegisters.Contains(MetadataObject) Then
			Order = "05";
		ElsIf Metadata.Documents.Contains(MetadataObject) Then
			Order = "06";
		ElsIf Metadata.AccumulationRegisters.Contains(MetadataObject) Then
			Order = "07";
		ElsIf Metadata.AccountingRegisters.Contains(MetadataObject) Then
			Order = "08";
		ElsIf Metadata.CalculationRegisters.Contains(MetadataObject) 
			Or Metadata.CalculationRegisters.Contains(MetadataObject.Parent()) Then
			Order = "09";
		ElsIf Metadata.BusinessProcesses.Contains(MetadataObject) Then
			Order = "10";
		ElsIf Metadata.Tasks.Contains(MetadataObject) Then
			Order = "11";
		ElsIf Metadata.Sequences.Contains(MetadataObject) Then
			Order = "12";
		EndIf;
		
		Objects.Add(MetadataObject, Order + MetadataObject.FullName());
	EndDo;
	
	Objects.SortByPresentation();
	FoundItem = Objects.FindByValue(Metadata.FindByFullName(LastObject));
	
	If FoundItem <> Undefined Then
		Offset = Objects.Count() - 1;
		For RepeatCount = 0 To Objects.IndexOf(FoundItem) - 1 Do
			Objects.Move(0, Offset);
		EndDo;
	EndIf;
	
	Return Objects.UnloadValues();
	
EndFunction

// Fills in the status of discharge taking into account the status of the download. 
//
// Parameters:
//   ExportState - InformationRegisterRecord.ApplicationsMigrationExportState - the record to update.
//   ImportState - Structure - description See ImportState
//                                   ().
//   ExchangeNode - ExchangePlanRef.ApplicationsMigration - the node where changes are being selected.
//
Procedure FillInUploadState(ExportState, ImportState, ExchangeNode)
	
	ExportState.ImportStateDate = CurrentUniversalDate();
	ExportState.ObjectsImported = ImportState.ObjectsImported;
	ExportState.ObjectsChanged = ChangedCount(ExchangeNode);
	If ImportState.CompletedWithErrors Then
		ExportState.State = Enums.ApplicationMigrationStates.OperationFailed;
		ExportState.Comment = NStr("vi = 'Khi kết nhập thông báo, đã xảy ra lỗi:';
									|ru = 'При загрузке сообщения возникла ошибка:';
									|en = 'An error occurred when importing the message:'; fa = 'An error occurred when importing the message:';
									|it = 'Si è verificato un errore durante il caricamento del messaggio:';
									|pl = 'Podczas pobierania komunikatu powstał błąd:';
									|tr = 'Mesaj içe aktarılırken hata oluştu:'") + Chars.LF + ImportState.ErrorDescription;
	EndIf;
	
EndProcedure

// Returns the maximum queue length.
//
// Returns:
//   Number - queue length.
//
Function MaximumLoadQueue() Export
	
	Return 3;
	
EndFunction

// Counts the number of registered changes per node.
//
// Parameters:
//   Node - ExchangePlanRef.ApplicationsMigration - the node where changes are being selected.
//
// Returns:
//   Number - the number of changes.
//
Function ChangedCount(Node) Export
	
	Query = New Query();
	Query.SetParameter("Node", Node);
	
	ObjectCount = 0;
	QueriesTexts = ModifiedObjectsQueryTexts();
	
	For Each QueryText In QueriesTexts Do
		
		Query.Text = QueryText;
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			ObjectCount = ObjectCount + Selection.ObjectCount;
		EndIf;
		
	EndDo;
	
	Return ObjectCount;
	
EndFunction

// Request texts for modified objects.
// 
// Returns:
//  Array of String - Query Texts For Modified Objects
Function ModifiedObjectsQueryTexts()
	
	QueriesTexts = New Array();
	
	For Each Content In ApplicationsMigrationCached.UnloadedObjects() Do
		
		MetadataObject = Content.Key;
		
		If Not ExtensionObjectIsPartOfExchangePlan(MetadataObject) Then
			Continue;
		EndIf;
		
		FullMetadataObjectName = MetadataObject.FullName();
		TableName = StrReplace(FullMetadataObjectName, ".Recalculation.", ".") + "." + "Changes";
		
		QueryText = StrTemplate(
			"SELECT
			|	""%1"" AS FullName,
			|	COUNT(*) AS ObjectCount
			|FROM
			|	%2
			|WHERE
			|	Node = &Node
			|	AND MessageNo IS NULL",
			FullMetadataObjectName,
			TableName);
		
		QueriesTexts.Add(QueryText);
		
	EndDo;
	
	Return QueriesTexts;
	
EndFunction

// Checks whether the metadata object is part of the Application Migration exchange plan
//
// Parameters:
//   MetadataObject - MetadataObject - the metadata object to be checked.
//
// Returns:
//   Boolean
//
Function ExtensionObjectIsPartOfExchangePlan(MetadataObject)
	
	If MetadataObject.ConfigurationExtension() = Undefined Then
		Return True;
	EndIf;
	
	Return Metadata.ExchangePlans.ApplicationsMigration.Content.Contains(MetadataObject);
	
EndFunction

// Returns selection fields for a set of records.
//
// Parameters:
//   MetadataObject - MetadataObject
//
// Returns:
//   Array of String - array of field names.
//
Function RecordsetSelectionFields(MetadataObject) Export
	
	FilterFields = New Array;
	
	If Metadata.InformationRegisters.Contains(MetadataObject)
		And MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
		
		If MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical
			And MetadataObject.MainFilterOnPeriod Then
			FilterFields.Add("Period");
		EndIf;
		For Each Dimension In MetadataObject.Dimensions Do
			If Dimension.MainFilter Then
				FilterFields.Add(Dimension.Name);
			EndIf;
		EndDo;
	ElsIf Metadata.CalculationRegisters.Contains(MetadataObject.Parent()) Then
		FilterFields.Add("RecalculationObject");
	Else
		FilterFields.Add("Recorder");
	EndIf;
	
	Return FilterFields;
	
EndFunction

// Returns unavailable roles to users.
//
// Returns:
//  Map of KeyAndValue:
//   * Key - CatalogRef.MetadataObjectIDs
//   * Value - Boolean
Function UnavailableRoles() Export
	
	UnavailableRoles = UsersInternalCached.UnavailableRoles();
	RolesNames = New Array;
	For Each UnavailableRole In UnavailableRoles Do
		RolesNames.Add("Role." + UnavailableRole.Key);
	EndDo;
	Query = New Query;
	Query.SetParameter("RolesNames", RolesNames);
	Query.Text =
	"SELECT
	|	MetadataObjectIDs.Ref AS Ref
	|FROM
	|	Catalog.MetadataObjectIDs AS MetadataObjectIDs
	|WHERE
	|	MetadataObjectIDs.FullName IN(&RolesNames)";
	
	UnavailableRoles = New Map;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		UnavailableRoles.Insert(Selection.Ref, True);
	EndDo;
	
	Return UnavailableRoles;
	
EndFunction

// Verifies that the object matches the specified metadata object, if does not match, an exception is thrown.
//
// Parameters:
//   Object - Arbitrary - the loaded object.
//   MetadataObject - MetadataObject - 
//
Procedure CheckTypeOfObjectRead(Object, MetadataObject) Export
	
	If MetadataObject <> Object.Metadata() Then
		Raise NStr("vi = 'Kiểu đối tượng đã đọc không tương ứng với kiểu được yêu cầu.';
					|ru = 'Тип прочитанного объекта не соответствует объявленному.';
					|en = 'Type of read object does not match the declared one.'; fa = 'Type of read object does not match the declared one.';
					|it = 'Il tipo dell''oggetto letto non corrisponde a quello dichiarato.';
					|pl = 'Typ odczytanego obiektu nie odpowiada deklarowanemu.';
					|tr = 'Okunan nesnenin türü belirtilen ile eşleşmiyor.'");
	EndIf;
	
EndProcedure

// Completes the upload and logs the error in the log.
//
// Parameters:
//   DetailErrorDescription - String - an error that is recorded in the log.
//   BriefErrorDescription - String - it is saved in the register and will be shown to the user.
//
Procedure EndUploadWithError(ExportState, DetailErrorDescription, BriefErrorDescription)
	
	ErrorLogging(NStr("vi = 'Kết xuất';
						|ru = 'Выгрузка';
						|en = 'Export'; fa = 'خروج اطلاعات';
						|it = 'Upload';
						|pl = 'Eksportowanie';
						|tr = 'Dışa aktarma'", Common.DefaultLanguageCode()), DetailErrorDescription);
	
	BeginTransaction();
	Try
		ExportState.State = Enums.ApplicationMigrationStates.OperationFailed;
		ExportState.Comment = BriefErrorDescription;
		ExportState.CompletedOn = CurrentUniversalDate();
		ExportState.Write();
		ScheduledJobsServer.DeleteJob(Metadata.ScheduledJobs.ApplicationsMigrationExport);
		If ValueIsFilled(ExportState.ExchangeNode) Then
			ObjectNode = ExportState.ExchangeNode.GetObject();
			If ObjectNode <> Undefined Then
				ObjectNode.Delete();
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Completes the upload and logs the error in the log.
//
// Parameters:
//   DetailErrorDescription - String - an error that is recorded in the log.
//   BriefErrorDescription - String - it is saved in the register and will be shown to the user.
//
Procedure EndUploadWithError_(ImportState, DetailErrorDescription, BriefErrorDescription)
	
	ErrorLogging(NStr("vi = 'Kết nhập';
						|ru = 'Загрузка';
						|en = 'Import'; fa = 'ورود اطلاعات';
						|it = 'Scaricamento';
						|pl = 'Pobieranie';
						|tr = 'İçe aktarma'", Common.DefaultLanguageCode()), DetailErrorDescription);
	
	BeginTransaction();
	Try
		MessageType = RemoteAdministrationControlMessagesInterface.DataAreaPreparationErrorMessage();
		Message = MessagesSaaS.NewMessage(MessageType);
		Message.Body.Zone = SessionParameters.DataAreaValue;
		Message.Body.ErrorDescription = BriefErrorDescription;
		
		MessagesSaaS.SendMessage(Message, SaaSOperationsCTLCached.ServiceManagerEndpoint(), True);
		
		ImportState.CompletedWithErrors = True;
		ImportState.ErrorDescription = BriefErrorDescription;
		ImportState.CompletedOn = CurrentUniversalDate();
		ImportState.Write();
		
		ScheduledJobsServer.DeleteJob(Metadata.ScheduledJobs.ApplicationsMigrationImport);
		
		DeleteQueue();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Completes the download.
//
// Parameters:
//   ImportState - InformationRegisterRecord.ApplicationsMigrationImportState -
//
Procedure CompleteDownload(ImportState)
	
	ScheduledJobsServer.DeleteJob(Metadata.ScheduledJobs.ApplicationsMigrationImport);
	
	DataAreaRecordset = InformationRegisters.DataAreas.CreateRecordSet();
	DataAreaRecordset.Read();
	DataAreaRecordset[0].Status = Enums.DataAreaStatuses.Used;
	DataAreaRecordset.Write();
	
	SaaSOperationsCTL.UpdateAccessGroupsOfSuppliedProfiles();
	
	DownloadableUsers = ImportState.Users.Get(); // Array of See Users.NewIBUserDetails
	For Each UserDetails In DownloadableUsers Do
		
		UserObject = Undefined;
		If ValueIsFilled(UserDetails.Id) Then
			UserObject = Catalogs.Users.GetRef(UserDetails.Id).GetObject();
		EndIf;
		If UserObject = Undefined Then
			UserObject = Catalogs.Users.CreateItem();
		EndIf;
		
		UserObject.ServiceUserID = UserDetails.ServiceUserID;
		UserObject.Description = UserDetails.FullName;
		
		ItemInstanceAddressStructure = SaaSOperationsCTL.CompositionOfPostalAddress(UserDetails.Mail);
		SaaSOperationsCTL.UpdateEmailAddress(UserObject, UserDetails.Mail, ItemInstanceAddressStructure);
		
		SaaSOperationsCTL.UpdatePhone(UserObject, UserDetails.Phone);
		
		IBUserDetails = Users.NewIBUserDetails();
		IBUserDetails.Name = UserDetails.Name;
		IBUserDetails.StandardAuthentication = UserDetails.StandardAuthentication;
		IBUserDetails.OpenIDAuthentication = UserDetails.OpenIDAuthentication;
		IBUserDetails.ShowInList = UserDetails.ShowInList;
		IBUserDetails.StoredPasswordValue = UserDetails.StoredPasswordValue;
		IBUserDetails.Language = SaaSOperationsCTL.LanguageByCode(UserDetails.LanguageCode);
		IBUserDetails.OSAuthentication = UserDetails.OSAuthentication;
		IBUserDetails.OSUser   = UserDetails.OSUser;
		IBUserDetails.Insert("Action", "Write");
		
		UserObject.AdditionalProperties.Insert("IBUserDetails", IBUserDetails);
		UserObject.AdditionalProperties.Insert("RemoteAdministrationChannelMessageProcessing");
		
		IsNew = UserObject.IsNew();
		
		If IsNew Then
			
			If UserDetails.Right = "StartAndAdministration" Then
				IBUserDetails.Roles = New Array;
				IBUserDetails.Roles.Add("FullAccess");
			EndIf;
			
		EndIf;
		
		UserObject.Write();
		
		If IsNew Then
			
			If UserDetails.Right = "StartAndAdministration" Then
				If UsersInternal.CannotEditRoles()
					And Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
					
					ModuleAccessManagementInternalSaaS = Common.CommonModule("AccessManagementInternalSaaS");
					ModuleAccessManagementInternalSaaS.SetUserBelongingToAdministratorGroup(UserObject.Ref, True);
				EndIf;
			ElsIf UserDetails.Right = "Run" Then
				SaaSOperationsOverridable.SetDefaultRights(UserObject.Ref);
				SaaSOperationsCTLOverridable.SetDefaultRights(UserObject.Ref, True);
			ElsIf UserDetails.Right = "APIAccess" Then
				SaaSOperationsCTLOverridable.SetAccessToThisDataArea(UserObject.Ref, True);
			EndIf;
		EndIf;
	EndDo;
	
	AccessManagement.UpdateUserRoles();
	
	ApplicationKind = ImportState.ApplicationKind.Get();
	AppTypesInternal.SetAppTypeByMessage(ApplicationKind);
	
	ExtensionsDirectory.ChangeUsageValueInApp(ExtensionsDirectory.AvailableInInfobase());
	PersonalAreaOfService.UpdatePersonalAreaUsage();
	
	Description = Constants.DataAreaPresentation.Get();
	If IsBlankString(Description) Then
		Description = StrTemplate("%1(%2)", Metadata.Synonym, SaaSOperations.SessionSeparatorValue());
	EndIf;
	SaaSOperationsCTL.UpdatePredefinedNodesCode();
	SaaSOperationsCTL.UpdatePropertiesOfPredefinedNodes(Description);
	
	JobsQueueInternalDataSeparation.AfterImportData(Undefined);
	
	If SaaSOperations.UserRightsSettingsInSaaSSupportedSSL() Then
		ModuleAccessManagementInternalSaaS = 
			Common.CommonModule("AccessManagementInternalSaaS");
		
		ModuleAccessManagementInternalSaaS.SendAccessGroupsToServiceManager();
	EndIf;

	DataAreaCode = SaaSOperations.SessionSeparatorValue();
	MessageType = RemoteAdministrationControlMessagesInterface.MessageDataAreaIsReadyForUse();
	Message = MessagesSaaS.NewMessage(MessageType);
	Message.Body.Zone = DataAreaCode;
	
	MessagesSaaS.SendMessage(Message, SaaSOperationsCTLCached.ServiceManagerEndpoint(), True);
	
EndProcedure

// Logs an error in the registration log.
//
// Parameters:
//   Event - String - 
//   Comment - String -
//   MetadataObject - MetadataObject -
//   Data - Arbitrary - 
//
Procedure ErrorLogging(Event, Comment, MetadataObject = Undefined, Data = Undefined)
	
	EventName = StrTemplate(NStr("vi = 'Di chuyển ứng dụng.%1';
								|ru = 'Миграция приложений.%1';
								|en = 'Application migration.%1'; fa = 'Application migration.%1';
								|it = 'Migrazione delle applicazioni.%1';
								|pl = 'Migracja aplikacji.%1';
								|tr = 'Uygulama geçişi.%1'", Common.DefaultLanguageCode()), Event);
	WriteLogEvent(EventName, EventLogLevel.Error, MetadataObject, Data, Comment);
	
EndProcedure

// Registers the note in the registration log.
//
// Parameters:
//   Event - String - 
//   Comment - String - 
//
Procedure NoteRegistration(Event, Comment)
	
	EventName = StrTemplate(NStr("vi = 'Di chuyển ứng dụng.%1';
								|ru = 'Миграция приложений.%1';
								|en = 'Application migration.%1'; fa = 'Application migration.%1';
								|it = 'Migrazione delle applicazioni.%1';
								|pl = 'Migracja aplikacji.%1';
								|tr = 'Uygulama geçişi.%1'", Common.DefaultLanguageCode()), Event);
	WriteLogEvent(EventName, EventLogLevel.Note, , , Comment);
	
EndProcedure

// Checks whether the download is running, and if it is not, an exception will be thrown.
//
// @unavailable-in-safemode
Procedure CheckIfDownloadIsInProgress()
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ApplicationsMigrationImportState.CompletedOn AS CompletedOn
	|FROM
	|	InformationRegister.ApplicationsMigrationImportState AS ApplicationsMigrationImportState";
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	If Not Selection.Next() Or ValueIsFilled(Selection.CompletedOn) Then
		Raise NStr("vi = 'Chưa thực hiện kết nhập thông điệp.';
					|ru = 'Загрузка сообщений не выполняется.';
					|en = 'Message import not performed.'; fa = 'Message import not performed.';
					|it = 'Download messaggi non in esecuzione.';
					|pl = 'Pobieranie komunikatów nie jest wykonywane.';
					|tr = 'Mesaj içe aktarma yürütülmüyor.'");
	EndIf;
	
EndProcedure

// Serializes an object in JSON
//
// Parameters:
//   Object - Arbitrary - any serializable object.
//
// Returns:
//   String - the result of serialization.
//
Function ObjectInJSON(Object)
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, Object);
	
	Return JSONWriter.Close();
	
EndFunction

// Deserializes from JSON to match.
//
// Parameters:
//   JSON - String - string in JSON format
//
// Returns:
//   Structure - the result of deserialization.
//
Function JSONObject(JSON)
	
	JSONReader = New JSONReader;
	JSONReader.SetString(JSON);
	Object = ReadJSON(JSONReader);
	JSONReader.Close();
	
	Return Object;
	
EndFunction

// Throws an exception specifying the metadata object.
//
// Parameters:
//   MetadataObject - MetadataObject -
//
Procedure RaiseExceptionUnknownMetadataObject(Val MetadataObject) Export
	
	Raise StrTemplate(NStr("vi = 'Đối tượng metadata không xác định: %1';
							|ru = 'Неизвестный объект метаданных: %1';
							|en = 'Unknown metadata object: %1'; fa = 'Unknown metadata object: %1';
							|it = 'Oggetto di metadati sconosciuto: %1';
							|pl = 'Nieznany obiekt metadanych: %1';
							|tr = 'Bilinmeyen meta veri nesnesi:%1'"), MetadataObject.FullName());
	
EndProcedure

// Enables or disables the use of the total of all registers.
//
// Parameters:
//   Use - Boolean -
//
Procedure SetRegistersTotalsUsage(Use)
	
	Model = ApplicationsMigrationCached.AreaDataModel();
	For Each MetadataObject In Metadata.AccumulationRegisters Do
		If Model.Get(MetadataObject) <> Undefined Then
			If MetadataObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers
				And AccumulationRegisters[MetadataObject.Name].GetAggregatesMode() Then
				AccumulationRegisters[MetadataObject.Name].SetAggregatesUsing(Use);
			Else		
				AccumulationRegisters[MetadataObject.Name].SetTotalsUsing(Use);
			EndIf;
			If MetadataObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Balance Then
				AccumulationRegisters[MetadataObject.Name].SetPresentTotalsUsing(Use);
			EndIf; 
		EndIf;
	EndDo;
	For Each MetadataObject In Metadata.AccountingRegisters Do
		If Model.Get(MetadataObject) <> Undefined Then
			AccountingRegisters[MetadataObject.Name].SetTotalsUsing(Use);
			AccountingRegisters[MetadataObject.Name].SetPresentTotalsUsing(Use);
		EndIf;
	EndDo;
	
EndProcedure

// Re-registers changes that were previously numbered.
//
// Parameters:
//   ExchangeNode - ExchangePlanRef.ApplicationsMigration -
//   MessageNo - Number - changes are limited to this number.
//
Procedure RegisterChangesAgain(ExchangeNode, MessageNo)
	
	Query = New Query;
	Query.SetParameter("Node", ExchangeNode);
	Query.SetParameter("MessageNo", MessageNo);
	
	For Each Content In ApplicationsMigrationCached.UnloadedObjects() Do
		
		MetadataObject = Content.Key;
		TableName = StrReplace(MetadataObject.FullName(), ".Recalculation.", ".") + "." + "Changes";
		
		If Metadata.Constants.Contains(MetadataObject) Then
			
			Query.Text = StrReplace(
			"SELECT TOP 1
			|	TRUE AS Validation
			|FROM
			|	TableName AS Changes
			|WHERE
			|	Changes.Node = &Node
			|	AND Changes.MessageNo <= &MessageNo", "TableName", TableName);
			
			If Not Query.Execute().IsEmpty() Then
				ExchangePlans.RecordChanges(ExchangeNode, MetadataObject);
			EndIf;
			
		ElsIf Metadata.Catalogs.Contains(MetadataObject) 
			Or Metadata.Documents.Contains(MetadataObject) 
			Or Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject)
			Or Metadata.ChartsOfAccounts.Contains(MetadataObject)
			Or Metadata.ChartsOfCalculationTypes.Contains(MetadataObject)
			Or Metadata.Tasks.Contains(MetadataObject) 
			Or Metadata.BusinessProcesses.Contains(MetadataObject) Then
			
			Query.Text = StrReplace(
			"SELECT DISTINCT 
			|	Ref AS Ref
			|FROM
			|	TableName AS Changes
			|WHERE
			|	Changes.Node = &Node
			|	AND Changes.MessageNo <= &MessageNo", "TableName", TableName);
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				ExchangePlans.RecordChanges(ExchangeNode, Selection.Ref);
			EndDo;
			
		ElsIf Metadata.InformationRegisters.Contains(MetadataObject)
			Or Metadata.AccumulationRegisters.Contains(MetadataObject) 
			Or Metadata.CalculationRegisters.Contains(MetadataObject) 
			Or Metadata.CalculationRegisters.Contains(MetadataObject.Parent())
			Or Metadata.AccountingRegisters.Contains(MetadataObject) 
			Or Metadata.Sequences.Contains(MetadataObject) Then
			
			ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
			
			FilterFields = RecordsetSelectionFields(MetadataObject);
			
			If FilterFields.Count() = 0 Then
				Query.Text = StrReplace(
				"SELECT TOP 1 
				|	TRUE AS Validation
				|FROM
				|	TableName AS Changes
				|WHERE
				|	Changes.Node = &Node
				|	AND Changes.MessageNo <= &MessageNo", "TableName", TableName);
			Else
				Query.Text = StrReplace(
				"SELECT DISTINCT 
				|	&Fields
				|FROM
				|	TableName AS Changes
				|WHERE
				|	Changes.Node = &Node
				|	AND Changes.MessageNo <= &MessageNo", "TableName", TableName);
				Query.Text = StrReplace(Query.Text, "&Fields", StrConcat(FilterFields, ","))
			EndIf;
			
			QueryResult = Query.Execute();
			If QueryResult.IsEmpty() Then
				Continue;
			EndIf;
			
			Selection = QueryResult.Select();
			While Selection.Next() Do
				
				RecordSet = ObjectManager.CreateRecordSet();
				For Each FilterField In FilterFields Do
					FilterElement = RecordSet.Filter[FilterField]; // FilterItem
					FilterElement.Set(Selection[FilterField]);
				EndDo;
				ExchangePlans.RecordChanges(ExchangeNode, RecordSet);
				
			EndDo;
			
		Else
			RaiseExceptionUnknownMetadataObject(MetadataObject);
		EndIf;
		
	EndDo;
	
EndProcedure

// Resets the resend flag in the destination app.
//
// @unavailable-in-safemode
Procedure ConfirmReUpload()
	
	SetPrivilegedMode(True);
	
	CheckIfDownloadIsInProgress();
	
	ImportState = InformationRegisters.ApplicationsMigrationImportState.CreateRecordManager();
	ImportState.Read();
	ImportState.ResendingRequired = False;
	ImportState.Write();
	
	SetPrivilegedMode(False);
	
EndProcedure

// Returns the name of the passed metadata object.
// 
// Parameters:
// 	MetadataObject - MetadataObject - metadata object.
// Returns:
// 	String - the name of the metadata object.
Function MetadataObjectName(MetadataObject) Export

	Return MetadataObject.Name;
	
EndFunction

// Returns a metadata object named "Link" from the Standard Requirements.
// 
// Parameters:
// 	MetadataObject - MetadataObject - reference type object
// 					 - Structure - LongDesc:
// 						* StandardAttributes - StandardAttributeDescriptions - description of the bank details.
// 												- Structure - Standard Object Details:
// 													** Ref - StandardAttributeDescription - the "Link"attribute.
// Returns:
//  TypeDescription - object type.
Function TypeOfReferenceObject(MetadataObject)
	
	Return MetadataObject.StandardAttributes.Ref.Type;
	
EndFunction

Function MethodInAddressIsSupported(AccessParameters)

	Return AccessParameters.SoftwareInterfaceVersion >=19;

EndFunction

// Get access parameters.
// 
// Parameters:
//  Source - Structure, ClientApplicationForm - source of parameters
// 
// Returns:
// Structure - Access Parameters:
// * APIAddress - String - ExtAPI address of the service manager
// * SoftwareInterfaceVersion - Number - ExtAPI version of the service manager
// * Login - String
// * Password - String
// * SubscriberCode - Number
Function GetAccessParameters(Source)
	
	Result = New Structure();
	Result.Insert("APIAddress", "");
	Result.Insert("SoftwareInterfaceVersion", 0);
	Result.Insert("Login", "");
	Result.Insert("Password", "");
	Result.Insert("SubscriberCode", 0);
	
	FillPropertyValues(Result, Source);
	
	Return Result;
	
EndFunction

// Returns whether to open the application migration form.
//
// Returns:
//   Boolean - True if you need to open the form.
//
Function YouNeedToOpenForm()
	
	If Not SaaSOperations.SeparatedDataUsageAvailable()
		Or Not Users.IsFullUser() Then
		Return False;
	EndIf;
	
	States1 = New Array;
	States1.Add(Enums.ApplicationMigrationStates.Running);
	States1.Add(Enums.ApplicationMigrationStates.PendingImport);
	States1.Add(Enums.ApplicationMigrationStates.OperationSuccessful);
	States1.Add(Enums.ApplicationMigrationStates.OperationFailed);
	
	Query = New Query;
	Query.SetParameter("Initiator", Users.CurrentUser());
	Query.SetParameter("States1", States1);
	Query.Text =
	"SELECT
	|	TRUE AS Validation
	|FROM
	|	InformationRegister.ApplicationsMigrationExportState AS ApplicationsMigrationExportState
	|WHERE
	|	ApplicationsMigrationExportState.Initiator = &Initiator
	|	AND ApplicationsMigrationExportState.State IN(&States1)";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function NewRecoveryExtension(Name, Version, ID, VersionID) Export
	Result = New Structure();
	Result.Insert("id", Name); 
	Result.Insert("version", Version);
	Result.Insert("PlusExtId", ID);
	Result.Insert("PlusExtVersionId", VersionID);
	Return Result;
EndFunction

#EndRegion
