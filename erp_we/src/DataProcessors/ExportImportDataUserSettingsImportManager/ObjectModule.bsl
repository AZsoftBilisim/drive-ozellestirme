#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

	
#Region Variables

Var CurContainer; // DataProcessorObject.ExportImportDataContainerManager
Var CurNameOfSettingsStore;
Var CurSettingsStore;
Var CurHandlers;
Var CurFlowOfLinkReplacement;

#EndRegion

#Region Internal

Procedure Initialize(Container, NameOfSettingsStore, Handlers, LinkReplacementFlow) Export
	
	CurContainer = Container;
	CurHandlers = Handlers;
	CurFlowOfLinkReplacement = LinkReplacementFlow;
	
	CurNameOfSettingsStore = NameOfSettingsStore;
	CurSettingsStore = Common.CalculateInSafeMode(CurNameOfSettingsStore);
	
EndProcedure

// Loads the user settings.
//
// Parameters:
//   UserMatching - Map - collection of users whose settings need to be uploaded: 
//                                Key - old user name
//                                The value is the new user name.
//                                If not specified, then all settings are loaded "as is".
Procedure ImportData(UserMatching = Undefined) Export
	
	Cancel = False;
	CurHandlers.BeforeLoadingSettingsStore(
		CurContainer,
		CurNameOfSettingsStore,
		CurSettingsStore,
		Cancel);
	
	If Not Cancel Then
		
		UploadSettingsToStandardStorage(UserMatching);
		
	EndIf;
	
	CurHandlers.AfterLoadingSettingsStore(
		CurContainer,
		CurNameOfSettingsStore,
		CurSettingsStore);
	
EndProcedure

#EndRegion

#Region Private

Procedure UploadSettingsToStandardStorage(UserMatching)
	
	DescriptionsOfSettings = CurContainer.GetFileDescriptionsFromFolder(
		ExportImportDataInternal.UserSettings(), CurNameOfSettingsStore);
	
	For Each FileDetails In DescriptionsOfSettings Do
		
		CurContainer.UnzipFile(FileDetails);
		
		ErrorsLoadingStorageSettings = New Array();
		
		Try
	    	CurFlowOfLinkReplacement.ReplaceLinksInFile(FileDetails);
			ReplacingLinksIsDone = True;
		Except
			ErrorsLoadingStorageSettings.Add(
				DetailErrorDescription(ErrorInfo()));
			ReplacingLinksIsDone = False;
		EndTry;
			
		If ReplacingLinksIsDone Then
			ReaderStream = DataProcessors.ExportImportDataInfobaseDataReadingStream.Create();
			ReaderStream.OpenFile(FileDetails.FullName, True);

			While ReaderStream.ReadInformationDatabaseDataObject() Do

				Cancel = False;

				RecordingSettings = ReaderStream.CurrentObject(); // See ExportImportDataInternal.NewSettingsEntry 
				Artifacts = ReaderStream.CurObjectArtifacts();

				SettingsKey = RecordingSettings.SettingsKey;
				ObjectKey = RecordingSettings.ObjectKey;
				User = RecordingSettings.User;
				Presentation = RecordingSettings.Presentation;

				If UserMatching <> Undefined Then
					User = UserMatching.Get(User);
					If Not ValueIsFilled(User) Then
						Continue;
					EndIf;
				EndIf;
				
				SerializationViaValueStorage = RecordingSettings.SerializationViaValueStorage;
				
				If SerializationViaValueStorage Then
					Settings = RecordingSettings.Settings.Get();
				Else
					Settings = RecordingSettings.Settings;
				EndIf;

				CurHandlers.BeforeDownloadingSettings(
					CurContainer,
					CurNameOfSettingsStore,
					SettingsKey,
					ObjectKey,
					Settings,
					User,
					Presentation,
					Artifacts,
					Cancel);

				If Not Cancel Then

					SettingsDescription = New SettingsDescription;
					SettingsDescription.Presentation = Presentation;

					CurSettingsStore.Save(
						ObjectKey,
						SettingsKey,
						Settings,
						SettingsDescription,
						User);

				EndIf;

				CurHandlers.AfterLoadingSettings(
					CurContainer,
					CurNameOfSettingsStore,
					SettingsKey,
					ObjectKey,
					Settings,
					User,
					Presentation,
					Artifacts);

			EndDo;

			ReaderStream.Close();
			
			CommonClientServer.SupplementArray(
				ErrorsLoadingStorageSettings,
				ReaderStream.Errors());
			
		EndIf;
		
		If ValueIsFilled(ErrorsLoadingStorageSettings) Then

			BriefWarning = StrTemplate(
				NStr("vi = 'Đã xảy ra lỗi khi kết nhập kho chứa ''%1'', đã bỏ qua kết nhập một phần tùy chỉnh';
					|ru = 'В процессе загрузки хранилища ''%1'' обнаружены ошибки, загрузка части настроек пропущена';
					|en = 'Errors were found while importing the ''%1'' storage. Import is skipped for some settings'; fa = 'Errors were found while importing the ''%1'' storage. Import is skipped for some settings';
					|it = 'Sono stati rilevati errori durante il processo di caricamento del repository ''%1'', il caricamento di alcune impostazioni è stato omesso';
					|pl = 'W trakcie pobierania repozytorium ''%1'' wykryto błędy, pobieranie części ustawień zostało pominięte';
					|tr = '''%1'' deposu içe aktarılırken hatalarla karşılaşıldı, bazı ayarların yüklenmesi atlandı'"),
				CurNameOfSettingsStore);
			
			CurContainer.AddWarning(BriefWarning);	
			
			PartsOfWarningText = New Array;	
			PartsOfWarningText.Add(BriefWarning);		
			PartsOfWarningText.Add(Chars.LF);

			For Each ErrorLoadingStorageSettings In ErrorsLoadingStorageSettings Do
				PartsOfWarningText.Add("● ");
				PartsOfWarningText.Add(ErrorLoadingStorageSettings);
				PartsOfWarningText.Add(Chars.LF);
			EndDo;
						
			EventName = NStr("vi = 'Kết nhập tùy chỉnh người sử dụng. Đã bỏ qua kết nhập một phần tùy chỉnh';
							|ru = 'Загрузка настроек пользователей. Загрузка части настроек пропущена';
							|en = 'User settings import. Import is skipped for some settings'; fa = 'User settings import. Import is skipped for some settings';
							|it = 'Caricamento di impostazioni utenti. Caricamento di alcune impostazioni è stato omesso';
							|pl = 'Pobieranie ustawień użytkowników. Pobieranie części ustawień zostało pominięte';
							|tr = 'Kullanıcı ayarları içe aktarma. Bazı ayarların yüklenmesi atlandı'",
				Common.DefaultLanguageCode());
		
			WriteLogEvent(
				EventName,
				EventLogLevel.Error,,, 
				StrConcat(PartsOfWarningText));
				
		EndIf;
					
		DeleteFiles(FileDetails.FullName);	
			
	EndDo;
	
EndProcedure


#EndRegion

#EndIf
