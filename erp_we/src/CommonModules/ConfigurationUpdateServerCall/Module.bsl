///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Checks for active infobase connections.
//
// Returns:
//  Boolean       - True if there are connections.
//                 False if there are no connections.
//
Function HasActiveConnections(MessagesForEventLog = Undefined) Export
	
	VerifyAccessRights("Administration", Metadata);
	EventLog.WriteEventsToEventLog(MessagesForEventLog);
	Return IBConnections.InfobaseSessionsCount(False, False) > 1;
EndFunction

Procedure WriteUpdateStatus(ParametersOfUpdate, MessagesForEventLog = Undefined) Export
	
	VerifyAccessRights("Administration", Metadata);
	
	ScriptDirectory = "";
	If Not IsBlankString(ParametersOfUpdate.MainScriptFileName) Then 
		ScriptDirectory = Left(ParametersOfUpdate.MainScriptFileName, StrLen(ParametersOfUpdate.MainScriptFileName) - 10);
	EndIf;
	ParametersOfUpdate.ScriptDirectory = ScriptDirectory;
	
	ConfigurationUpdate.WriteUpdateStatus(
		ParametersOfUpdate,
		MessagesForEventLog);
	
EndProcedure

Function TemplatesTexts(MessagesForEventLog, InteractiveMode, ExecuteDeferredHandlers, IsDeferredUpdate) Export
	
	VerifyAccessRights("Administration", Metadata);
	
	TemplatesTexts = New Structure;
	TemplatesTexts.Insert("AdditionalConfigurationUpdateFile");
	TemplatesTexts.Insert(?(InteractiveMode, "ConfigurationUpdateSplash", "NonInteractiveConfigurationUpdate"));
	
	If IsDeferredUpdate Then
		TemplatesTexts.Insert("TaskSchedulerTaskCreationScript");
	EndIf;
	
	TemplatesTexts.Insert("PatchesDeletionScript");
	
	For Each TemplateProperties In TemplatesTexts Do
		TemplatesTexts[TemplateProperties.Key] = DataProcessors.InstallUpdates.GetTemplate(TemplateProperties.Key).GetText();
	EndDo;
	
	If InteractiveMode Then
		TemplatesTexts.ConfigurationUpdateSplash = GenerateSplashText(TemplatesTexts.ConfigurationUpdateSplash); 
	EndIf;
	
	// Configuration update file: main.js.
	ScriptTemplate = DataProcessors.InstallUpdates.GetTemplate("ConfigurationUpdateFileTemplate");
	
	ParametersArea = ScriptTemplate.GetArea("ParametersArea");
	ParametersArea.DeleteLine(1);
	ParametersArea.DeleteLine(ParametersArea.LineCount());
	If StrStartsWith(ParametersArea.GetLine(ParametersArea.LineCount()), "#") Then
		ParametersArea.DeleteLine(ParametersArea.LineCount());
	EndIf;
	TemplatesTexts.Insert("ParametersArea", ParametersArea.GetText());
	
	ConfigurationUpdateArea = ScriptTemplate.GetArea("ConfigurationUpdateArea");
	ConfigurationUpdateArea.DeleteLine(1);
	ConfigurationUpdateArea.DeleteLine(ConfigurationUpdateArea.LineCount());
	TemplatesTexts.Insert("ConfigurationUpdateFileTemplate", ConfigurationUpdateArea.GetText());
	
	// Writing accumulated events to the event log.
	EventLog.WriteEventsToEventLog(MessagesForEventLog);
	ExecuteDeferredHandlers = ConfigurationUpdate.ExecuteDeferredHandlers();
	
	ScriptMessages = ScriptMessages();
	For Each TemplateProperties In TemplatesTexts Do
		TemplatesTexts[TemplateProperties.Key] = SubstituteParametersToText(TemplatesTexts[TemplateProperties.Key], ScriptMessages);
	EndDo;
	
	Return TemplatesTexts;
	
EndFunction

Function GenerateSplashText(Val TextTemplate1)
	
	TextParameters = New Map;
	TextParameters["[SplashTitle]"] = NStr("vi = 'Cập nhật cấu hình ""1C:Enterprise""...';
											|ru = 'Обновление конфигурации ""1С:Предприятие""...';
											|en = 'Updating 1C:Enterprise configuration…'; fa = 'Updating 1C:Enterprise configuration…';
											|it = 'Aggiornamento di configurazione ""1C:Enterprise""...';
											|pl = 'Aktualizacja konfiguracja ""1С:Enterprise""...';
											|tr = '""1C:Enterprise"" konfigürasyon güncellemesi...'");
	TextParameters["[SplashText]"] = NStr("vi = 'Vui lòng đợi.
		|<br/> Đang cập nhật cấu hình.';
		|ru = 'Пожалуйста, подождите.
		|<br/> Выполняется обновление конфигурации.';
		|en = 'Please wait.
		|<br/> Application update is in progress.'; fa = 'Please wait.
		|<br/> Application update is in progress.';
		|it = 'Пожалуйста, подождите.
		|<br/> Выполняется обновление конфигурации.';
		|pl = 'Please wait.
		|<br/> Application update is in progress.';
		|tr = 'Lütfen bekleyin.
		|<br/>Konfigürasyon güncellemesi yapılıyor.'");
	
	TextParameters["[Step1Initialization]"] = NStr("vi = 'Khởi tạo';
													|ru = 'Инициализация';
													|en = 'Initializing'; fa = 'Initializing';
													|it = 'Inizializzazione';
													|pl = 'Initializing';
													|tr = 'Başlatma'");
	TextParameters["[Step2ClosingUserSessions]"] = NStr("vi = 'Kết thúc công việc người sử dụng';
														|ru = 'Завершение работы пользователей';
														|en = 'Closing user sessions'; fa = 'Closing user sessions';
														|it = 'Arresto del lavoro degli utenti';
														|pl = 'Zakończenie pracy użytkowników';
														|tr = 'Kullanıcı oturumlarının tamamlanması'");
	TextParameters["[Step3BackupCreation]"] = NStr("vi = 'Tạo bản sao dự phòng cơ sở thông tin';
													|ru = 'Создание резервной копии информационной базы';
													|en = 'Creating infobase backup'; fa = 'Creating infobase backup';
													|it = 'Creazione del backup del database';
													|pl = 'Urworzenie rezerwowej kopii informacyjnej bazy';
													|tr = 'Infobase tabanı yedeği oluşturma'");
	TextParameters["[Step4ConfigurationUpdate]"] = NStr("vi = 'Cập nhật cấu hình CSTT';
														|ru = 'Обновление конфигурации информационной базы';
														|en = 'Updating infobase configuration'; fa = 'Updating infobase configuration';
														|it = 'Aggiornamento di configurazione del database';
														|pl = 'Aktualizacja konfiguracji bazy informacyjnej';
														|tr = 'Infobase konfigürasyon güncellemesi'");
	TextParameters["[Step4DownloadExtensions]"] = NStr("vi = 'Cập nhật phần mở rộng cơ sở thông tin';
														|ru = 'Обновление расширений информационной базы';
														|en = 'Updating infobase extensions'; fa = 'Updating infobase extensions';
														|it = 'Aggiornamento delle estensioni dell''infobase';
														|pl = 'Aktualizacja rozszerzeń bazy informacyjnaj';
														|tr = 'Infobase uzantı güncellemesi'");
	TextParameters["[Step5IBUpdate]"] = NStr("vi = 'Chạy hàm sự kiện cập nhật';
											|ru = 'Выполнение обработчиков обновления';
											|en = 'Running update handlers'; fa = 'Running update handlers';
											|it = 'Esecuzione di elaboratori di aggiornamento';
											|pl = 'Wykonanie procesów przetwarzania aktualizacji';
											|tr = 'Güncelleme işleyicilerin yürütülmesi'");
	TextParameters["[Step6DeferredUpdate]"] = NStr("vi = 'Đang chạy hàm sự kiện cập nhật hoãn lại';
													|ru = 'Выполнение отложенных обработчиков обновления';
													|en = 'Running deferred update handlers'; fa = 'Running deferred update handlers';
													|it = 'Esecuzione dei elaboratori di aggiornamento sospesi';
													|pl = 'Wykonanie odroczonych procesów przetwarzania aktualizacji';
													|tr = 'Ertelenen güncelleme işleyicilerinin yürütülmesi'");
	TextParameters["[Step7CompressTables]"] = NStr("vi = 'Nén bảng CSTT';
													|ru = 'Сжатие таблиц информационной базы';
													|en = 'Compressing infobase tables'; fa = 'Compressing infobase tables';
													|it = 'Compressione delle tabelle del database';
													|pl = 'Kompresja tablic bazy informacyjnej';
													|tr = 'Infobase tablolarının daraltılması'");
	TextParameters["[Step8AllowConnections]"] = NStr("vi = 'Cho phép kết nối mới';
													|ru = 'Разрешение подключения новых соединений';
													|en = 'Granting permission for new connections'; fa = 'Granting permission for new connections';
													|it = 'Autorizzazione nuove connessioni';
													|pl = 'Zezwolenie podłączenia nowych połączeń';
													|tr = 'Yeni bağlantının bağlanılmasına izin verilmesi'");
	TextParameters["[Step9Completion]"] = NStr("vi = 'Kết thúc';
												|ru = 'Завершение';
												|en = 'Completing'; fa = 'Completing';
												|it = 'Completamento';
												|pl = 'Completing';
												|tr = 'Bitiş'");
	TextParameters["[Step10Recovery]"] = NStr("vi = 'Phục hồi cơ sở thông tin';
												|ru = 'Восстановление информационной базы';
												|en = 'Restoring infobase'; fa = 'Restoring infobase';
												|it = 'Ripristino del database';
												|pl = 'Przywrócenie bazy informacyjnej';
												|tr = 'Infobase''in kurtarılması'");
	TextParameters["[Step11DisablePatches]"] = NStr("vi = 'Tắt sử dụng tạm thời bản chỉnh sửa (bản vá lỗi)';
													|ru = 'Временное отключение исправлений (патчей)';
													|en = 'Temporary disable patches'; fa = 'Temporary disable patches';
													|it = 'Временное отключение исправлений (патчей)';
													|pl = 'Temporary disable patches';
													|tr = 'Временное отключение исправлений (патчей)'");
	TextParameters["[Step11PatchesDeletion]"] = NStr("vi = 'Xóa các bản sửa lỗi (bản vá)';
													|ru = 'Удаление исправлений (патчей)';
													|en = 'Deleting patches'; fa = 'Deleting patches';
													|it = 'Eliminazione correzioni (patch)';
													|pl = 'Usunięcie korekt (łat)';
													|tr = 'Düzeltmelerin (yamaların) silinmesi'");
	
	TextParameters["[Step41Load]"] = NStr("vi = 'Kết nhập tệp cập nhật vào cơ sở thông tin chính';
											|ru = 'Загрузка файла обновления в основную базу';
											|en = 'Loading update file to the main infobase'; fa = 'Loading update file to the main infobase';
											|it = 'Scaricamento del file di aggiornamento nella base principale';
											|pl = 'Załadowanie pliku aktualizacji do bazy podstawowej';
											|tr = 'Güncelleme dosyasının ana tabana yüklenmesi'");
	TextParameters["[Step42ConfigurationUpdate]"] = NStr("vi = 'Cập nhật cấu hình CSTT';
														|ru = 'Обновление конфигурации информационной базы';
														|en = 'Updating infobase configuration'; fa = 'Updating infobase configuration';
														|it = 'Aggiornamento di configurazione del database';
														|pl = 'Aktualizacja konfiguracji bazy informacyjnej';
														|tr = 'Infobase konfigürasyon güncellemesi'");
	TextParameters["[Step42EnablePatches]"] = NStr("vi = 'Bật sử dụng các bản chỉnh sửa (bản vá lỗi)';
													|ru = 'Включение исправлений (патчей)';
													|en = 'Enable patches'; fa = 'Enable patches';
													|it = 'Включение исправлений (патчей)';
													|pl = 'Enable patches';
													|tr = 'Включение исправлений (патчей)'");
	TextParameters["[Step43IBUpdate]"] = NStr("vi = 'Chạy hàm sự kiện cập nhật';
												|ru = 'Выполнение обработчиков обновления';
												|en = 'Running update handlers'; fa = 'Running update handlers';
												|it = 'Esecuzione di elaboratori di aggiornamento';
												|pl = 'Wykonanie procesów przetwarzania aktualizacji';
												|tr = 'Güncelleme işleyicilerin yürütülmesi'");
	
	TextParameters["[ProcessIsAborted]"] = NStr("vi = 'Chú ý: quá trình cập nhật bị gián đoạn và CSTT vẫn bị chặn.';
												|ru = 'Внимание: процесс обновления был прерван, и информационная база осталась заблокированной.';
												|en = 'Warning! The update was terminated and the infobase remains locked.'; fa = 'Warning! The update was terminated and the infobase remains locked.';
												|it = 'Attenzione: l''aggiornamento è stato interrotto e il database è bloccato.';
												|pl = 'Uwaga: proces aktualizacji został przerwany i baza informacyjna została zablokowana.';
												|tr = 'Dikkat: güncelleme süreci kesintiye uğradı ve infobase kilitli kaldı.'");
	TextParameters["[AbortedTooltip]"] = NStr("vi = 'Để bỏ chặn CSTT, hãy sử dụng bảng điều khiển cụm máy chủ hoặc chạy 1C:Enterprise.';
												|ru = 'Для разблокирования информационной базы воспользуйтесь консолью кластера серверов или запустите ""1С:Предприятие"".';
												|en = 'To unlock the infobase, use the server cluster console or run 1C:Enterprise.'; fa = 'To unlock the infobase, use the server cluster console or run 1C:Enterprise.';
												|it = 'Per sbloccare il database usate la console del cluster dei server o avviate ""1C:Enterprise"".';
												|pl = 'Do rozblokowania bazy informacyjnej skorzystaj z konsoli klastera serwrów lub uruchom ""1С:Enterprise"".';
												|tr = 'Infobase kilidini açmak için sunucu kümesi konsolunu kullanın veya 1C:Enterprise''ı çalıştırın.'");
	
	TextParameters["[ProductName]"] = NStr("vi = '1C:ENTERPRISE 8.3';
											|ru = '1С:ПРЕДПРИЯТИЕ 8.3';
											|en = '1C:ENTERPRISE 8.3'; fa = '1C:ENTERPRISE 8.3';
											|it = '1C:ENTERPRISE 8.3';
											|pl = '1С:ENTERPRISE 8.3';
											|tr = '1C:ENTERPRISE 8.3'");
	TextParameters["[Copyright]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '© Công ty TNHH ""1C-Soft"", 1996-%1';
			|ru = '© ООО ""1С-Софт"", 1996-%1';
			|en = '© 1C Company, 1996-%1'; fa = '© 1C Company, 1996-%1';
			|it = '© ""1С-Soft"", 1996-%1';
			|pl = '© 1C Company, 1996-%1';
			|tr = '© ООО ""1C-Soft"", 1996-%1'"), Format(Year(CurrentSessionDate()), "NG=0"));
	
	Return SubstituteParametersToText(TextTemplate1, TextParameters);
	
EndFunction

Function SubstituteParametersToText(Val Text, Val TextParameters)
	
	Result = Text;
	For Each TextParameter In TextParameters Do
		Result = StrReplace(Result, TextParameter.Key, TextParameter.Value);
	EndDo;
	Return Result; 
	
EndFunction

// OnlineUserSupport.GetApplicationUpdates

Procedure SaveConfigurationUpdateSettings(Settings) Export
	VerifyAccessRights("Administration", Metadata);
	ConfigurationUpdate.SaveConfigurationUpdateSettings(Settings);
EndProcedure

// End OnlineUserSupport.GetApplicationUpdates

Procedure UpdatePatchesFromScript(NewPatches, PatchesToDelete) Export // ACC:557 To call from a script.
	ConfigurationUpdate.UpdatePatchesFromScript(NewPatches, PatchesToDelete);
EndProcedure

Function ScriptDirectory() Export
	
	Return ConfigurationUpdate.ScriptDirectory();
	
EndFunction

// ACC:299–off for using from the update script.
// ACC:557–off for using from the update script.
//
Procedure DeletePatchesFromScript() Export
	
	MessageText = NStr("vi = 'Đã bắt đầu xóa các bản sửa lỗi trước khi bắt đầu cập nhật ứng dụng.';
						|ru = 'Начато удаление исправлений до запуска обновления приложения.';
						|en = 'Starting patch clean up followed by application update.'; fa = 'Starting patch clean up followed by application update.';
						|it = 'Начато удаление исправлений до запуска обновления приложения.';
						|pl = 'Starting patch clean up followed by application update.';
						|tr = 'Uygulama güncellemesi başlatılmadan önce düzeltmelerin silinmesi başlatıldı.'");
	WriteLogEvent(ConfigurationUpdate.EventLogEvent(), EventLogLevel.Information,,, MessageText);
	
	AllExtensions = ConfigurationExtensions.Get();
	For Each Extension In AllExtensions Do
		If Not ConfigurationUpdate.IsPatch(Extension) Then
			Continue;
		EndIf;
		Try
			Extension.Delete();
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xóa bản sửa lỗi ""%1"" do nguyên nhân: 
				           |
				           |%2';
				           |ru = 'Не удалось удалить исправление ""%1"" по причине:
				           |
				           |%2';
				           |en = 'Cannot delete patch ""%1."" Reason:
				           |
				           |%2'; fa = 'Cannot delete patch ""%1."" Reason:
				           |
				           |%2';
				           |it = 'Non è stato possibile cancellare la correzione ""%1"" a causa di:
				           |
				           |%2';
				           |pl = 'Nie udało się usunąć poprawkę ""%1"" z powodu:
				           |
				           |%2';
				           |tr = '""%1"" yaması silinemedi. Nedeni:
				           |
				           |%2'"), Extension.Name, ErrorProcessing.BriefErrorDescription(ErrorInfo));
			WriteLogEvent(NStr("vi = 'Chỉnh sửa.Xóa bỏ';
								|ru = 'Исправления.Удаление';
								|en = 'Patch.Delete'; fa = 'Patch.Delete';
								|it = 'Correzioni.Rimozione';
								|pl = 'Patch.Delete';
								|tr = 'Düzeltmeler.Silme'", Common.DefaultLanguageCode())
				, EventLogLevel.Error,,, ErrorText);
		EndTry;
	EndDo;
	
	MessageText = NStr("vi = 'Đã xóa thành công bản sửa lỗi.';
						|ru = 'Удаление исправлений завершено.';
						|en = 'Patch deletion completed.'; fa = 'Patch deletion completed.';
						|it = 'Eliminazione delle correzioni terminata.';
						|pl = 'Usunięcie korekt zakończono.';
						|tr = 'Düzeltmelerin silinmesi tamamlandı'");
	WriteLogEvent(ConfigurationUpdate.EventLogEvent(), EventLogLevel.Information,,, MessageText);
	
EndProcedure
// ACC:299-on
// ACC:557-on

// ACC:299–off for using from the update script.
// ACC:557–off for using from the update script.
//
Procedure DisablePatchesFromScript() Export
	
	If Common.IsSubordinateDIBNode() Then
		// In a subordinate node, patches are changed when synchronizing.
		Return;
	EndIf;
	
	MessageText = NStr("vi = 'Đã bắt đầu tắt sử dụng tạm thời các bản sửa lỗi trước khi bắt đầu cập nhật ứng dụng.';
						|ru = 'Начато временное отключение исправлений до запуска обновления приложения.';
						|en = 'Temporary disabling of patches has been started followed by an application update.'; fa = 'Temporary disabling of patches has been started followed by an application update.';
						|it = 'Начато временное отключение исправлений до запуска обновления приложения.';
						|pl = 'Temporary disabling of patches has been started followed by an application update.';
						|tr = 'Начато временное отключение исправлений до запуска обновления приложения.'");
	WriteLogEvent(ConfigurationUpdate.EventLogEvent(), EventLogLevel.Information,,, MessageText);
	ConfigurationUpdate.WriteManifestsOfPatchesToDisable();

	AllExtensions = ConfigurationExtensions.Get();
	For Each Extension In AllExtensions Do
		If Not ConfigurationUpdate.IsPatch(Extension) Then
			Continue;
		EndIf;
		Try
			Extension.Active = False;
			Extension.UnsafeActionProtection = Common.ProtectionWithoutWarningsDetails();
			Extension.UseDefaultRolesForAllUsers = False;
			Extension.Write();
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể tắt sử dụng chỉnh sửa ""%1"" do:
				           |
				           |%2';
				           |ru = 'Не удалось отключить исправление ""%1"" по причине:
				           |
				           |%2';
				           |en = 'Cannot disable patch ""%1"" due to:
				           |
				           |%2'; fa = 'Cannot disable patch ""%1"" due to:
				           |
				           |%2';
				           |it = 'Не удалось отключить исправление ""%1"" по причине:
				           |
				           |%2';
				           |pl = 'Cannot disable patch ""%1"" due to:
				           |
				           |%2';
				           |tr = 'Не удалось отключить исправление ""%1"" по причине:
				           |
				           |%2'"), Extension.Name, ErrorProcessing.BriefErrorDescription(ErrorInfo));
			WriteLogEvent(NStr("vi = 'Chỉnh sửa.Tắt sử dụng';
								|ru = 'Исправления.Отключение';
								|en = 'Patches.Disable'; fa = 'Patches.Disable';
								|it = 'Исправления.Отключение';
								|pl = 'Patches.Disable';
								|tr = 'Исправления.Отключение'", Common.DefaultLanguageCode())
				, EventLogLevel.Error,,, ErrorText);
		EndTry;
	EndDo;
	
	MessageText = NStr("vi = 'Đã hoàn tất Tắt sử dụng Tạm thời các bản sửa lỗi.';
						|ru = 'Временное Отключение исправлений завершено.';
						|en = 'Patches temporary disabled.'; fa = 'Patches temporary disabled.';
						|it = 'Временное Отключение исправлений завершено.';
						|pl = 'Patches temporary disabled.';
						|tr = 'Временное Отключение исправлений завершено.'");
	WriteLogEvent(ConfigurationUpdate.EventLogEvent(), EventLogLevel.Information,,, MessageText);
	
EndProcedure
// ACC:299-on
// ACC:557-on

// ACC:299–off for using from the update script.
// ACC:557–off for using from the update script.
//
Procedure EnablePatchesFromScript() Export
	ConfigurationUpdate.EnableApplicablePatches();
EndProcedure
// ACC:299-on
// ACC:557-on

Function ScriptMessages()
	
	Messages = New Map;
		
	// Messages in templates ConfigurationUpdateFileTemplate, NonInteractiveConfigurationUpdate, and ConfigurationUpdateSplash.
	Messages["[TheStartOfStartupMessage]"] = NStr("vi = 'Đang khởi động: {0}; tham số: {1}; cửa sổ: {2}; đang chờ: {3}';
													|ru = 'Запускается: {0}; параметры: {1}; окно: {2}; ожидание: {3}';
													|en = 'Starting: {0}; parameters: {1}; window: {2}; waiting: {3}'; fa = 'Starting: {0}; parameters: {1}; window: {2}; waiting: {3}';
													|it = 'In avvio: {0}; parametri: {1}; finestra: {2}; attesa: {3}';
													|pl = 'Trwa uruchamianie: {0}; parametry: {1}; okno dialogowe: {2}; oczekiwanie: {3}';
													|tr = 'Başlatılıyor: {0}; parametreler: {1}; pencere: {2}; bekleme: {3}'");
	Messages["[ExceptionDetailsMessage]"] = NStr("vi = 'Loại trừ khi khởi động ứng dụng: {0}, {1}';
												|ru = 'Исключение при запуске приложения: {0}, {1}';
												|en = 'Exception at the application start: {0}, {1}'; fa = 'Exception at the application start: {0}, {1}';
												|it = 'Esclusione all''avvio dell''applicazione: {0}, {1}';
												|pl = 'Wykluczenie podczas uruchomienia aplikacji: {0}, {1}';
												|tr = 'Uygulama başlatma sırasında istisna: {0}, {1}'");
	Messages["[MessageLaunchResult]"] = NStr("vi = 'Mã trả lại: {0}';
											|ru = 'Код возврата: {0}';
											|en = 'Return code: {0}'; fa = 'Return code: {0}';
											|it = 'Codice di reso: {0}';
											|pl = 'Kod zwrotu: {0}';
											|tr = 'İade kodu: {0}'");
	Messages["[TheMessageIsThePathToTheScriptFile]"] = NStr("vi = 'Tệp script: {0}';
															|ru = 'Файл скрипта: {0}';
															|en = 'Script file: {0}'; fa = 'Script file: {0}';
															|it = 'File di script: {0}';
															|pl = 'Plik skryptu: {0}';
															|tr = 'Komut dizisi dosyası: {0}'");
	Messages["[UpdateFileCounterMessage]"] = NStr("vi = 'Số lượng tệp cập nhật: {0}';
													|ru = 'Количество файлов обновления: {0}';
													|en = 'Number of update files: {0}'; fa = 'Number of update files: {0}';
													|it = 'Numero di file di aggiornamento: {0}';
													|pl = 'Ilość plików aktualizacji: {0}';
													|tr = 'Güncelleme dosyalarının sayısı: {0}'");
	Messages["[TheMessageRestoringTheDatabase]"] = NStr("vi = 'Khôi phục CSTT từ tệp nén tạm thời';
														|ru = 'Восстановление ИБ из временного архива';
														|en = 'Restore infobase from a temporary archive'; fa = 'Restore infobase from a temporary archive';
														|it = 'Ripristino infobase dall''archivio temporaneo';
														|pl = 'Przywrócenie BI z archiwum tymczasowego';
														|tr = 'Infobase''nin geçici arşivden kurtarılması'");
	Messages["[TheMessageTheBeginningOfTheConnectionSessionWithTheDatabase]"] = NStr("vi = 'Bắt đầu phiên kết nối ngoài với CSTT';
																					|ru = 'Начат сеанс внешнего соединения с ИБ';
																					|en = 'External infobase connection session started'; fa = 'External infobase connection session started';
																					|it = 'Sessione iniziata di connessione esterna con l''infobase';
																					|pl = 'Rozpoczęto sesję połączenia zewnętrznego z BI';
																					|tr = 'Infobase ile dış bağlantı oturumu başlatıldı'");
	Messages["[MessageDeletingASchedulerTask]"] = NStr("vi = 'Xóa nhiệm vụ của bộ lập kế hoạch nhiệm vụ: {0}';
														|ru = 'Удаление задачи планировщика задач: {0}';
														|en = 'Deleting a scheduler task: {0}'; fa = 'Deleting a scheduler task: {0}';
														|it = 'Eliminazione compito del pianificatore di compiti: {0}';
														|pl = 'Usunięcie zadania planisty zadań: {0}';
														|tr = 'Görev zamanlayıcı görevini sil: {0}'");
	Messages["[TheSchedulerTaskDeletionFailureMessage]"] = NStr("vi = 'Chưa xóa nhiệm vụ từ bộ lập kế hoạch nhiệm vụ do nguyên nhân: {0}';
																|ru = 'Задача из планировщика задач не была удалена по причине: {0}';
																|en = 'Cannot delete the task from the task scheduler due to: {0}'; fa = 'Cannot delete the task from the task scheduler due to: {0}';
																|it = 'Задача из планировщика задач не была удалена по причине: {0}';
																|pl = 'Cannot delete the task from the task scheduler due to: {0}';
																|tr = 'Görev, görev planlayıcısından şu nedenle silinmedi: {0}'");
	Messages["[TheMessageConnectionFailureWithTheDatabase]"] = NStr("vi = 'Loại trừ khi tạo kết nối COM: {0}, {1}';
																	|ru = 'Исключение при создании COM-соединения: {0}, {1}';
																	|en = 'Exception when creating COM connection: {0}, {1}'; fa = 'Exception when creating COM connection: {0}, {1}';
																	|it = 'Esclusione alla creazione della connessione COM: {0}, {1}';
																	|pl = 'Wykluczenie przy nawiązaniu połączenia COM: {0}, {1}';
																	|tr = 'COM-bağlantı oluşturulurken şu adımda istisna: {0}, {1}'");
	Messages["[TheMessageIsACallToCompleteTheUpdate]"] = "ConfigurationUpdate.CompleteUpdate" + "({0}, {1}, {2})";
	Messages["[FailureMessageWhenCallingToCompleteTheUpdate]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Loại trừ khi gọi ra %1: {0}, {1}';
			|ru = 'Исключение при вызове %1: {0}, {1}';
			|en = 'Exception when calling %1: {0}, {1}'; fa = 'Exception when calling %1: {0}, {1}';
			|it = 'Esclusione alla chiamata %1: {0}, {1}';
			|pl = 'Wykluczenie podczas wywołaniu %1: {0}, {1}';
			|tr = '%1çağrı sırasında istisna: {0}, {1}'"), "ConfigurationUpdate.CompleteUpdate");
	Messages["[TheMessageDatabaseUpdateResult]"] = NStr("vi = 'Đã cập nhật thành công cơ sở thông tin';
														|ru = 'Обновление информационной базы завершилось успешно';
														|en = 'The infobase is updated.'; fa = 'The infobase is updated.';
														|it = 'Обновление информационной базы завершилось успешно';
														|pl = 'The infobase is updated.';
														|tr = 'Infobase güncellemesi başarıyla tamamlandı'");
	Messages["[DatabaseUpdateFailureMessage]"] = NStr("vi = 'Đã xảy ra tình huống bất thường khi cập nhật cơ sở thông tin';
														|ru = 'Непредвиденная ситуация при обновлении информационной базы';
														|en = 'An unexpected error occurred while updating the infobase'; fa = 'An unexpected error occurred while updating the infobase';
														|it = 'Непредвиденная ситуация при обновлении информационной базы';
														|pl = 'An unexpected error occurred while updating the infobase';
														|tr = 'Infobase güncellenirken beklenmeyen bir durum oluştu'");
	Messages["[TheMessageDatabaseParameters]"] = NStr("vi = 'Tham số cơ sở thông tin: {0}.';
														|ru = 'Параметры информационной базы: {0}.';
														|en = 'Infobase parameters: {0}.'; fa = 'Infobase parameters: {0}.';
														|it = 'Parametri della base di informazioni: {0}.';
														|pl = 'Parametry bazy informacyjnej: {0}.';
														|tr = 'Infobase parametreleri: {0}.'");
	Messages["[LoggingFailureMessage]"] = NStr("vi = 'Loại trừ khi ghi lại nhật ký: {0}, {1}';
												|ru = 'Исключение при записи журнала: {0}, {1}';
												|en = 'Exception when writing Event log: {0}, {1}'; fa = 'Exception when writing Event log: {0}, {1}';
												|it = 'Esclusione alla registrazione del registro: {0}, {1}';
												|pl = 'Wykluczenie podczas zapisywania dziennika: {0}, {1}';
												|tr = 'Günlük kayıt oluşturma sırasında istisna: {0}, {1}'");
	Messages["[MessageUpdateLogging1S]"] = NStr("vi = 'Giao thức cập nhật đã được lưu trong nhật ký sự kiện.';
												|ru = 'Протокол обновления сохранен в журнал регистрации.';
												|en = 'The update protocol is saved to the event log.'; fa = 'The update protocol is saved to the event log.';
												|it = 'Protocollo di aggiornamento salvato nel registro degli eventi.';
												|pl = 'Protokół aktualizacji został zapisany do dziennika rejestracji.';
												|tr = 'Güncelleme protokolü kayıt günlüğüne kaydedildi.'");
	Messages["[TheMessageCopyingTheDatabase]"] = NStr("vi = '\r\n\Đang thực hiện sao chép từ:\r\n\{0}\r\n\sang:\r\n\{1}';
														|ru = '\r\n\Выполняется копирование из:\r\n\{0}\r\n\в:\r\n\{1}';
														|en = '\r\n\Copying from:\r\n\{0}\r\n\ to:\r\n\{1}'; fa = '\r\n\Copying from:\r\n\{0}\r\n\ to:\r\n\{1}';
														|it = '\r\n\Copia in corso di:\r\n\{0}\r\n\in:\r\n\{1}';
														|pl = '\r\n\Trwa kopiowanie z:\r\n\{0}\r\n\do:\r\n\{1}';
														|tr = '\r\n\Buradan kopyalanıyor:\r\n\{0}\r\n\buraya:\r\n\{1}'");
	Messages["[TheMessageDatabaseFileDoesNotExist]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Tệp cơ sở dữ liệu %1 không tồn tại theo đường dẫn: {0}';
			|ru = 'Файл базы данных %1 не существует по пути: {0}';
			|en = '%1 database file does not exist by path: {0}'; fa = '%1 database file does not exist by path: {0}';
			|it = 'File di database%1 inesistente: {0}';
			|pl = 'Plik bazy danych %1 nie istnieje na ścieżce: {0}';
			|tr = '%1 veritabanı dosyası şu yolda mevcut değil: {0}'"), "1Cv8.1CD");
	Messages["[TheMessageDatabaseBackupDirectoryDoesNotExist]"] = NStr("vi = 'Không tồn tại thư mục để lưu bản sao dự phòng: {0}';
																		|ru = 'Папки для сохранения резервной копии не существует: {0}';
																		|en = 'There is no folder to save the backup: {0}'; fa = 'There is no folder to save the backup: {0}';
																		|it = 'Cartella per il salvataggio del backup non esistente: {0}';
																		|pl = 'Folderu do zapisywania kopii zapasowej nie istnieje: {0}';
																		|tr = 'Yedeği kaydetmek için klasör bulunmuyor: {0}'");
	Messages["[MessageBackupFileParameters]"] = NStr("vi = '\r\n\Đã tồn tại tệp sao lưu dự phòng: {0}\r\n\Đã tạo: {1}\r\n\Lần gọi ra gần đây: {2}\r\n\Lần thay đổi gần đây: {3}\r\n\Dung lượng: {4}\r\n\Kiểu: {5}\r\n\Thuộc tính:\r\n\{6}';
													|ru = '\r\n\Файл резервной копии уже существует: {0}\r\n\Создан: {1}\r\n\Последнее обращение: {2}\r\n\Последнее изменение: {3}\r\n\Размер: {4}\r\n\Тип: {5}\r\n\Атрибуты:\r\n\{6}';
													|en = '\r\n\The backup file already exists: {0}\r\n\Created: {1}\r\n\Last accessed: {2}\r\n\Last modified: {3}\r\n\Size: {4}\r\n\Type: {5}\r\n\Attributes:\r\n\{6}'; fa = '\r\n\The backup file already exists: {0}\r\n\Created: {1}\r\n\Last accessed: {2}\r\n\Last modified: {3}\r\n\Size: {4}\r\n\Type: {5}\r\n\Attributes:\r\n\{6}';
													|it = '\r\n\Il file di backup esiste già: {0}\r\n\Creato: {1}\r\n\Ultimo utilizzo: {2}\r\n\Ultima modifica: {3}\r\n\Dimensione: {4}\r\n\Tipo: {5}\r\n\Attributi:\r\n\{6}';
													|pl = '\r\n\Plik kopii zapasowej już istnieje: {0}\r\n\Utworzono: {1}\r\n\Ostatnie odwołanie: {2}\r\n\Ostatnia zmiana: {3}\r\n\Rozmiar: {4}\r\n\Typ: {5}\r\n\Atrybuty:\r\n\{6}';
													|tr = '\r\n\Yedek zaten mevcut: {0}\r\n\Oluşturuldu: {1}\r\n\Son başvuru: {2}\r\n\Son değişiklik: {3}\r\n\Boyut: {4}\r\n\Tür: {5}\r\n\Öznitelikler:\r\n\{6}'");
	Messages["[TheMessageDiskDoesNotExist]"] = NStr("vi = '\r\n\Không tìm thấy đĩa theo đường dẫn {0}\r\n\Ngoại trừ: {1}, {2}';
													|ru = '\r\n\Диск не найден по пути {0}\r\n\Исключение: {1}, {2}';
													|en = '\r\n\Hard drive is not found at {0}\r\n\Exception: {1}, {2}'; fa = '\r\n\Hard drive is not found at {0}\r\n\Exception: {1}, {2}';
													|it = '\r\n\Disco non trovato al percorso {0}\r\n\Eccezione: {1}, {2}';
													|pl = '\r\n\Nie znaleziono dysku na ścieżce {0}\r\n\Wykluczenie: {1}, {2}';
													|tr = '\r\n\Sabit sürücü yolda bulunamadı {0}\r\n\İstisna: {1}, {2}'");
	Messages["[TheMessageDiskIsUnavailable]"] = NStr("vi = 'Đĩa không được phép theo đường dẫn {0}';
													|ru = 'Диск недоступен по пути {0}';
													|en = 'Hard drive is unavailable at {0}'; fa = 'Hard drive is unavailable at {0}';
													|it = 'Диск недоступен по пути {0}';
													|pl = 'Hard drive is unavailable at {0}';
													|tr = 'Disk bu yolda mevcut değil {0}'");
	Messages["[MessageEnoughDiskSpace]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chỗ trống trên đĩa {0}: {1} Mb\r\n\Dung lượng đĩa %1: {2} Mb\r\n\Kiểu đĩa: {3}';
			|ru = 'Доступно на диске {0}: {1} Mb\r\n\Размер файла %1: {2} Mb\r\n\Тип диска: {3}';
			|en = 'Space available on drive {0}: {1} Mb\r\n\%1 file size: {2} Mb\r\n\Drive type: {3}'; fa = 'Space available on drive {0}: {1} Mb\r\n\%1 file size: {2} Mb\r\n\Drive type: {3}';
			|it = 'Disponibile sul disco {0}: {1} Mb\r\n\Dimensione file %1: {2} Mb\r\n\Tipo di disco: {3}';
			|pl = 'Dostępne na dysku {0}: {1} MB\r\n\Rozmiar pliku %1: {2} MB\r\n\Typ dysku: {3}';
			|tr = 'Sabit sürücüde kullanılabilir {0}: {1} Mb\r\n\Dosya boyutu %1: {2} Mb\r\n\Sabit sürücü türü: {3}'"), "1Cv8.1CD");
	Messages["[MessageDiskSpaceIsInsufficient]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '\r\n\Không đủ dung lượng để tạo bản sao dự phòng.\r\n\Hãy giải phóng dung lượng hoặc chỉ ra thư mục trên đĩa khác.\r\n\Cần: {0} Mb\r\n\Cho phép trên đĩa {1}: {2} Mb\r\n\Dung lượng tệp %1: {3} Mb\r\n\Kiểu đĩa: {4}';
			|ru = '\r\n\Недостаточно свободного места для создания резервной копии.\r\n\Освободите место или укажите папку на другом диске.\r\n\Требуется: {0} Mb\r\n\Доступно на диске {1}: {2} Mb\r\n\Размер файла %1: {3} Mb\r\n\Тип диска: {4}';
			|en = '\r\n\There is not enough free space to create a backup.\r\n\Free up some space or specify a folder on a different hard drive.\r\n\Required: {0} Mb\r\n\Space available on drive {1}: {2} Mb\r\n\%1 File size: {3} Mb\r\n\Drive type: {4}'; fa = '\r\n\There is not enough free space to create a backup.\r\n\Free up some space or specify a folder on a different hard drive.\r\n\Required: {0} Mb\r\n\Space available on drive {1}: {2} Mb\r\n\%1 File size: {3} Mb\r\n\Drive type: {4}';
			|it = '\r\n\Spazio libero insufficiente per la creazione del backup.\r\n\Liberare spazio o indicare una cartella su un altro disco.\r
			|\Si richiede:{0} Mb\r\n\Disponibile su disco {1}: {2} Mb\r\n\Dimensione file %1: {3} Mb\r\n\Tipo di disco: {4}';
			|pl = '\r\n\Niewystarczająco wolnego miejsca do utworzenia kopii zapasowej.\r\n\Zwolnij miejsce lub podaj folder na innym dysku.\r\n\Wymagane jest: {0} Mb\r\n\Dostępne na dysku {1}: {2} Mb\r\n\Rozmiar pliku %1: {3} Mb\r\n\Typ dysku: {4}';
			|tr = '\r\n\Yedeklemek için yeterli alan yok.\r\n\Alan boşaltın veya başka bir sürücüde bir klasör belirtin\r\n\Gereken: {0} Mb\r\n\Sabit sürücüde kullanılabilir {1}: {2} Mb\r\n\Dosya boyutu %1: {3} Mb\r\n\Sabit sürücü türü: {4}'"), "1Cv8.1CD");
	Messages["[TheMessageIsTheResultOfCreatingABackupCopyOfTheDatabase]"] = NStr("vi = 'Đã tạo bản sao dự phòng cơ sở dữ liệu';
																				|ru = 'Резервная копия базы создана';
																				|en = 'Infobase is backed up'; fa = 'Infobase is backed up';
																				|it = 'Backup della base creata';
																				|pl = 'Utworzono kopię zapasową bazy';
																				|tr = 'Tabanın yedek dosyası oluşturuldu'");
	Messages["[TheMessageFailureToCreateABackupCopyOfTheDatabaseInDetail]"] = NStr("vi = 'Ngoại trừ khi tạo bản sao dự phòng cơ sở dữ liệu: {0}, {1}';
																					|ru = 'Исключение при создании резервной копии базы: {0}, {1}';
																					|en = 'Exception when backing up the infobase: {0}, {1}'; fa = 'Exception when backing up the infobase: {0}, {1}';
																					|it = 'Eccezione durante la creazione del backup della base: {0}, {1}';
																					|pl = 'Wykluczenie przy utworzeniu kopii zapasowej bazy: {0}, {1}';
																					|tr = 'Tabanın yedeklemesi oluşturulurken istisna: {0}, {1}'");
	Messages["[TheMessageDatabaseRecoveryResult]"] = NStr("vi = 'Cơ sở dữ liệu đã phục hồi từ bản sao dự phòng';
															|ru = 'База данных восстановлена из резервной копии';
															|en = 'Database is restored from the backup'; fa = 'Database is restored from the backup';
															|it = 'Database creato da backup';
															|pl = 'Baza danych została przywrócona z kopii zapasowej';
															|tr = 'Infobase yedekten kurtarıldı'");
	Messages["[TheMessageDatabaseRecoveryFailureInDetail]"] = NStr("vi = 'Ngoại trừ khi phục hồi cơ sở dữ liệu từ bản sao dự phòng: {0}, {1}.';
																	|ru = 'Исключение при восстановлении базы из резервной копии: {0}, {1}.';
																	|en = 'Exception when restoring an infobase from a backup: {0}, {1}.'; fa = 'Exception when restoring an infobase from a backup: {0}, {1}.';
																	|it = 'Eccezione durante il ripristino della base da backup: {0}, {1}.';
																	|pl = 'Wykluczenie podczas przywrócenia bazy z kopii zapasowej: {0}, {1}.';
																	|tr = 'Yedekten veritabanının geri yüklenmesi sırasında istisna: {0}, {1}.'");
	Messages["[TheMessageChallengeAllowUsersToWork]"] = "IBConnections.AllowUserAuthorization";
	Messages["[MessageCallRefusalToAllowUsersToWork]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Loại trừ khi gọi ra %1: {0}, {1}';
			|ru = 'Исключение при вызове %1: {0}, {1}';
			|en = 'Exception when calling %1: {0}, {1}'; fa = 'Exception when calling %1: {0}, {1}';
			|it = 'Esclusione alla chiamata %1: {0}, {1}';
			|pl = 'Wykluczenie podczas wywołaniu %1: {0}, {1}';
			|tr = '%1çağrı sırasında istisna: {0}, {1}'"), "IBConnections.AllowUserAuthorization");
	Messages["[TheErrorMessageUpdatesFixes]"] = NStr("vi = 'Không thể cập nhật bản sửa cấu hình. Chi tiết xem trong bản ghi trước đó.';
													|ru = 'Не удалось обновить исправления конфигурации. Подробности см. в предыдущей записи.';
													|en = 'Cannot update the configuration patches. For more information, see the previous record.'; fa = 'Cannot update the configuration patches. For more information, see the previous record.';
													|it = 'Non è stato possibile aggiornare le correzioni di configurazione. Visualizzare i dettagli nella registrazione precedente.';
													|pl = 'Nie udało się zaktualizować korekty konfiguracji. Szczegóły patrz w poprzednim wpisie.';
													|tr = 'Konfigürasyon düzeltmeleri güncellenemedi. Ayrıntılar için önceki kayda bakın.'");
	Messages["[CallFailureMessageUpdateFixesFromScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Loại trừ khi gọi ra %1: {0}, {1}';
			|ru = 'Исключение при вызове %1: {0}, {1}';
			|en = 'Exception when calling %1: {0}, {1}'; fa = 'Exception when calling %1: {0}, {1}';
			|it = 'Esclusione alla chiamata %1: {0}, {1}';
			|pl = 'Wykluczenie podczas wywołaniu %1: {0}, {1}';
			|tr = '%1çağrı sırasında istisna: {0}, {1}'"), "ConfigurationUpdateServerCall.UpdatePatchesFromScript");
	Messages["[MessageCallToUpdateTheInformationBase]"] = "InfobaseUpdateServerCall.UpdateInfobase" + "({0})";
	Messages["[MessageCallFailureToUpdateTheInformationBase]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Loại trừ khi gọi ra %1: {0}, {1}.';
			|ru = 'Исключение при вызове %1: {0}, {1}.';
			|en = 'Exception when calling %1: {0}, {1}.'; fa = 'Exception when calling %1: {0}, {1}.';
			|it = 'Esclusione alla chiamata %1: {0}, {1}';
			|pl = 'Wykluczenie podczas wywołania %1: {0}, {1}';
			|tr = 'Çağrı istisnası %1: {0}, {1}.'"), "InfobaseUpdateServerCall.UpdateInfobase");
	Messages["[TheMessageDatabaseUpdateFailureIsGeneral]"] = NStr("vi = 'Không thể cập nhật cơ sở thông tin do nguyên nhân:';
																	|ru = 'Не удалось обновить информационную базу по причине:';
																	|en = 'Cannot update the infobase due to:'; fa = 'Cannot update the infobase due to:';
																	|it = 'Не удалось обновить информационную базу по причине:';
																	|pl = 'Cannot update the infobase due to:';
																	|tr = 'Infobase şu sebeple güncellenemedi:'");
	Messages["[TheMessageBlockingTheDatabase]"] = NStr("vi = 'do cần cập nhật cấu hình';
														|ru = 'в связи с необходимостью обновления конфигурации';
														|en = 'because configuration update is pending'; fa = 'because configuration update is pending';
														|it = 'in collegamento con la necessità di aggiornamento della configurazione';
														|pl = 'w związku z koniecznością aktualizacji konfiguracji';
														|tr = 'konfigürasyonun güncelleme ihtiyacı nedeniyle'");
	Messages["[UserShutdownFailureMessage]"] = NStr("vi = 'Đã thử kết thúc công việc của người sử dụng không thành công: hủy phong tỏa CSTT.';
													|ru = 'Попытка завершения работы пользователей завершилась безуспешно: отменена блокировка ИБ.';
													|en = 'An attempt to close user sessions is unsuccessful. Infobase lock is canceled.'; fa = 'An attempt to close user sessions is unsuccessful. Infobase lock is canceled.';
													|it = 'Il tentativo di completamento del lavoro degli utenti è stato effettuato senza successo: annullato blocco infobase.';
													|pl = 'Próba zakończenia pracy użytkowników zakończyła się bezskutecznie: anulowano blokadę BI.';
													|tr = 'Kullanıcıların çalışmalarını sonlandırma girişimi başarısızlıkla sonuçlandı: Infobase''nin kilitlenmesi iptal edildi.'");
	Messages["[TheMessageCancelingTheBlockingOfUsersWork]"] = NStr("vi = 'Loại trừ khi kết thúc công việc của người sử dụng: {0}, {1}';
																	|ru = 'Исключение при завершении работы пользователей: {0}, {1}';
																	|en = 'Exception when closing user sessions: {0}, {1}'; fa = 'Exception when closing user sessions: {0}, {1}';
																	|it = 'Esclusione al completamento del lavoro degli utenti: {0}, {1}';
																	|pl = 'Wykluczenie podczas zakończenia pracy użytkowników: {0}, {1}';
																	|tr = 'Kullanıcı oturumu kapatma istisnası: {0}, {1}'");
	Messages["[MessageEndOfDatabaseConnectionSession]"] = NStr("vi = 'Đã kết thúc phiên kết nối ngoài với CSTT';
																|ru = 'Завершен сеанс внешнего соединения с ИБ';
																|en = 'External infobase connection session completed'; fa = 'External infobase connection session completed';
																|it = 'Sessione completata di connessione esterna con l''infobase';
																|pl = 'Zakończono sesję połączenia zewnętrznego z BI';
																|tr = 'Infobase ile harici bağlantının oturumu tamamlandı'");
	Messages["[TheMessageBlockingTheWorkOfUsersLogging]"] = NStr("vi = 'Thiết lập phong tỏa các phiên làm việc do cần cập nhật cấu hình';
																|ru = 'Установка блокировки сеансов в связи с необходимостью обновления конфигурации';
																|en = 'Lock sessions because configuration update is pending'; fa = 'Lock sessions because configuration update is pending';
																|it = 'Impostazione di blocco delle sessioni in collegamento con la necessità di aggiornamento della configurazione';
																|pl = 'Ustawienie blokady sesji w związku z koniecznością aktualizacji konfiguracji';
																|tr = 'Konfigürasyonu güncelleme ihtiyacı nedeniyle oturum kilitlemeyi ayarlayın'");
	Messages["[TheMessageBlockingTheWorkOfUsers]"] = NStr("vi = 'do cần cập nhật cấu hình';
															|ru = 'в связи с необходимостью обновления конфигурации';
															|en = 'because configuration update is pending'; fa = 'because configuration update is pending';
															|it = 'in collegamento con la necessità di aggiornamento della configurazione';
															|pl = 'w związku z koniecznością aktualizacji konfiguracji';
															|tr = 'konfigürasyonun güncelleme ihtiyacı nedeniyle'");
	Messages["[MessageDatabaseSessionCounter]"] = NStr("vi = 'Số lượng phiên làm việc trong cơ sở thông tin: {0}';
														|ru = 'Количество сеансов информационной базы: {0}';
														|en = 'Number of infobase sessions: {0}'; fa = 'Number of infobase sessions: {0}';
														|it = 'Numero sessioni dell''infobase: {0}';
														|pl = 'Ilość sesji bazy informacyjnej: {0}';
														|tr = 'Infobase oturum sayısı: {0}'");
	Messages["[TheMessageIsTheResultOfBlockingSessions]"] = NStr("vi = 'Đã thiết lập phong tỏa bắt đầu phiên làm việc: {0}';
																|ru = 'Блокировка начала сеансов установлена: {0}';
																|en = 'Session start lock is set: {0}'; fa = 'Session start lock is set: {0}';
																|it = 'Blocco dell''inizio delle sessioni impostato: {0}';
																|pl = 'Blokowanie rozpoczęcia sesji została ustawiona: {0}';
																|tr = 'Oturumların başlangıç kilitlemesi ayarlandı: {0}'");
	Messages["[TheMessageTheCounterOfTheHungSessionsOfTheDatabase]"] = NStr("vi = 'Số lượng phiên làm việc đang bị treo trong cơ sở thông tin {0}, lần thử số {1}';
																			|ru = 'Количество зависших сеансов информационной базы: {0}, попытка № {1}';
																			|en = 'Number of hung infobase sessions: {0}, attempt #{1}'; fa = 'Number of hung infobase sessions: {0}, attempt #{1}';
																			|it = 'Numero sessioni pendenti dell''infobase: {0}, tentativo № {1}';
																			|pl = 'Ilość zawieszonych sesji bazy informacyjnej: {0}, próba nr {1}';
																			|tr = 'Askıya alınan infobase oturumlarının sayısı: {0}, deneme No. {1}'");
	Messages["[TheMessageIsACallToPerformADeferredUpdateNow]"] = "InfobaseUpdateInternal.ExecuteDeferredUpdateNow" + "()";
	Messages["[MessageCallFailureToPerformADelayedUpdateNow]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Loại trừ khi gọi ra %1: {0}, {1}.';
			|ru = 'Исключение при вызове %1: {0}, {1}.';
			|en = 'Exception when calling %1: {0}, {1}.'; fa = 'Exception when calling %1: {0}, {1}.';
			|it = 'Esclusione alla chiamata %1: {0}, {1}';
			|pl = 'Wykluczenie podczas wywołania %1: {0}, {1}';
			|tr = 'Çağrı istisnası %1: {0}, {1}.'"), "InfobaseUpdateInternal.ExecuteDeferredUpdateNow");
	Messages["[MessageFailedToCallDisablePatchesFromScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Loại trừ khi gọi ra %1: {0}, {1}.';
			|ru = 'Исключение при вызове %1: {0}, {1}.';
			|en = 'Exception when calling %1: {0}, {1}.'; fa = 'Exception when calling %1: {0}, {1}.';
			|it = 'Esclusione alla chiamata %1: {0}, {1}';
			|pl = 'Wykluczenie podczas wywołania %1: {0}, {1}';
			|tr = 'Çağrı istisnası %1: {0}, {1}.'"), "ConfigurationUpdateServerCall.DisablePatchesFromScript");
	Messages["[CallFailureMessageRemoveFixesFromScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Loại trừ khi gọi ra %1: {0}, {1}.';
			|ru = 'Исключение при вызове %1: {0}, {1}.';
			|en = 'Exception when calling %1: {0}, {1}.'; fa = 'Exception when calling %1: {0}, {1}.';
			|it = 'Esclusione alla chiamata %1: {0}, {1}';
			|pl = 'Wykluczenie podczas wywołania %1: {0}, {1}';
			|tr = 'Çağrı istisnası %1: {0}, {1}.'"), "ConfigurationUpdateServerCall.DeletePatchesFromScript");
	Messages["[MessageFailedToDisablePatches]"] = NStr("vi = 'Không thể tắt sử dụng bản sửa lỗi cấu hình. Chi tiết hơn xem trong bản ghi trước đó.';
														|ru = 'Не удалось отключить исправления конфигурации. Подробности см. в предыдущей записи.';
														|en = 'Cannot disable configuration patches. For more information, see the previous log record.'; fa = 'Cannot disable configuration patches. For more information, see the previous log record.';
														|it = 'Не удалось отключить исправления конфигурации. Подробности см. в предыдущей записи.';
														|pl = 'Cannot disable configuration patches. For more information, see the previous log record.';
														|tr = 'Не удалось отключить исправления конфигурации. Подробности см. в предыдущей записи.'");
	Messages["[TheMessageFailureToDeleteFixes]"] = NStr("vi = 'Không thể xóa bản sửa cấu hình. Chi tiết xem trong bản ghi trước đó.';
														|ru = 'Не удалось удалить исправления конфигурации. Подробности см. в предыдущей записи.';
														|en = 'Cannot delete the configuration patches. For more information, see the previous record.'; fa = 'Cannot delete the configuration patches. For more information, see the previous record.';
														|it = 'Non è stato possibile cancellare le correzioni di configurazione. Visualizzare i dettagli nella registrazione precedente.';
														|pl = 'Nie udało się usunąć korekt konfiguracji. Szczegóły patrz w poprzednim wpisie.';
														|tr = 'Konfigürasyon düzeltmeleri kaldırılamadı. Ayrıntılar için önceki kayda bakın.'");
	Messages["[MessageFailedToEnablePatches]"] = NStr("vi = 'Không thể Bật sử dụng bản sửa cấu hình. Chi tiết xem trong bản ghi trước đó.';
														|ru = 'Не удалось Включить исправления конфигурации. Подробности см. в предыдущей записи.';
														|en = 'Cannot enable configuration patches. For more information, see the previous log record.'; fa = 'Cannot enable configuration patches. For more information, see the previous log record.';
														|it = 'Не удалось Включить исправления конфигурации. Подробности см. в предыдущей записи.';
														|pl = 'Cannot enable configuration patches. For more information, see the previous log record.';
														|tr = 'Не удалось Включить исправления конфигурации. Подробности см. в предыдущей записи.'");
	Messages["[MessageCOMConnectorParameters]"] = NStr("vi = 'Sử dụng kết nối COM: {0}';
														|ru = 'Используется COM-соединение: {0}';
														|en = 'COM connection is used: {0}'; fa = 'COM connection is used: {0}';
														|it = 'Viene utilizzata la connessione COM: {0}';
														|pl = 'Jest używane połączenie COM: {0}';
														|tr = 'COM-bağlantıyı kullanın: {0}'");
	Messages["[TheMessageDatabaseUpdateFailureFromTheFile]"] = NStr("vi = 'Không thể cập nhật theo tệp, có thể là cấu hình không được hỗ trợ, thử kết nhập cấu hình.';
																	|ru = 'Не удалось обновить по файлу, возможно конфигурация не находится на поддержке, попытка загрузки конфигурации.';
																	|en = 'Cannot update by file. The configuration may not be supported. Attempting to load configuration.'; fa = 'Cannot update by file. The configuration may not be supported. Attempting to load configuration.';
																	|it = 'Non è stato possibile aggiornare il file, forse la configurazione non si trova in supporto, tentativo di download configurazione.';
																	|pl = 'Nie udało się zaktualizować z pliku, możliwe, że konfiguracja nie jest na obsłudze, próba pobierania konfiguracji.';
																	|tr = 'Dosyaya göre güncellenemedi, belki konfigürasyon desteklenmiyor, konfigürasyon yüklenmeye çalışılıyor.'");
	Messages["[SplashScreenMessageStepError]"] = NStr("vi = 'Kết thúc bị lỗi. Mã lỗi: {0}. Chi tiết xem trong bản ghi trước đó.';
														|ru = 'Завершение с ошибкой. Код ошибки: {0}. Подробности см. в предыдущей записи.';
														|en = 'An error occurred. Error code: {0}. For more information, see the previous record.'; fa = 'An error occurred. Error code: {0}. For more information, see the previous record.';
														|it = 'Esecuzione con errori. Codice errore: {0}. Visualizzare informazioni sulla registrazione precedente.';
														|pl = 'Zakończenie z błędem. Kod błędu: {0}. Szczegóły patrz w poprzednim wpisie.';
														|tr = 'Hatalı sonlandırma. Hata kodu: {0}. Ayrıntılar için önceki kayda bakın.'");
	Messages["[MessageInitialization]"] = NStr("vi = 'Khởi tạo';
												|ru = 'Инициализация';
												|en = 'Initializing'; fa = 'Initializing';
												|it = 'Inizializzazione';
												|pl = 'Initializing';
												|tr = 'Başlatma'");
	Messages["[TheUserShutdownMessage]"] = NStr("vi = 'Kết thúc công việc người sử dụng';
												|ru = 'Завершение работы пользователей';
												|en = 'Closing user sessions'; fa = 'Closing user sessions';
												|it = 'Arresto del lavoro degli utenti';
												|pl = 'Zakończenie pracy użytkowników';
												|tr = 'Kullanıcı oturumlarının tamamlanması'");
	Messages["[TheMessageCreatingABackupCopyOfTheDatabase]"] = NStr("vi = 'Tạo bản sao dự phòng cơ sở thông tin';
																	|ru = 'Создание резервной копии информационной базы';
																	|en = 'Creating infobase backup'; fa = 'Creating infobase backup';
																	|it = 'Creazione del backup del database';
																	|pl = 'Urworzenie rezerwowej kopii informacyjnej bazy';
																	|tr = 'Infobase tabanı yedeği oluşturma'");
	Messages["[MessageExecutingDeferredUpdateHandlers]"] = NStr("vi = 'Đang chạy hàm sự kiện cập nhật hoãn lại';
																|ru = 'Выполнение отложенных обработчиков обновления';
																|en = 'Running deferred update handlers'; fa = 'Running deferred update handlers';
																|it = 'Esecuzione dei elaboratori di aggiornamento sospesi';
																|pl = 'Wykonanie odroczonych procesów przetwarzania aktualizacji';
																|tr = 'Ertelenen güncelleme işleyicilerinin yürütülmesi'");
	Messages["[ConfigurationUpdateMessage]"] = NStr("vi = 'Cập nhật cấu hình CSTT';
													|ru = 'Обновление конфигурации информационной базы';
													|en = 'Updating infobase configuration'; fa = 'Updating infobase configuration';
													|it = 'Aggiornamento di configurazione del database';
													|pl = 'Aktualizacja konfiguracji bazy informacyjnej';
													|tr = 'Infobase konfigürasyon güncellemesi'");
	Messages["[MessageLoadingExtensions]"] = NStr("vi = 'Cập nhật phần mở rộng cơ sở thông tin';
													|ru = 'Обновление расширений информационной базы';
													|en = 'Infobase extension update'; fa = 'Infobase extension update';
													|it = 'Aggiornamento delle estensioni dell''infobase';
													|pl = 'Aktualizacja rozszerzeń bazy informacyjnaj';
													|tr = 'Infobase uzantı güncellemesi'");
	Messages["[UpdateFileDownloadMessage]"] = NStr("vi = 'Kết nhập tệp cập nhật vào cơ sở dữ liệu chính ({0}/{1})';
													|ru = 'Загрузка файла обновления в основную базу ({0}/{1})';
													|en = 'Loading update file to the main infobase ({0}/{1})'; fa = 'Loading update file to the main infobase ({0}/{1})';
													|it = 'Download del file di aggiornamento nella base principale ({0}/{1})';
													|pl = 'Załadowanie pliku aktualizacji do bazy podstawowej ({0}/{1})';
													|tr = 'Güncelleme dosyasının ana veritabanına yüklenmesi ({0}/{1})'");
	Messages["[MessageConfigurationUpdateParameters]"] = NStr("vi = 'Cập nhật cấu hình cơ sở thông tin ({0}/{1})';
																|ru = 'Обновление конфигурации информационной базы ({0}/{1})';
																|en = 'Updating infobase configuration ({0}/{1})'; fa = 'Updating infobase configuration ({0}/{1})';
																|it = 'Aggiornamento di configurazione dell''infobase ({0}/{1})';
																|pl = 'Aktualizacja konfiguracji bazy informacyjnej ({0}/{1})';
																|tr = 'Infobase konfigürasyon güncellemesi ({0}/{1})'");
	Messages["[MessageExecutingUpdateHandlers]"] = NStr("vi = 'Thực hiện hàm sự kiện cập nhật ({0}/{1})';
														|ru = 'Выполнение обработчиков обновления ({0}/{1})';
														|en = 'Running update handlers ({0}/{1})'; fa = 'Running update handlers ({0}/{1})';
														|it = 'Esecuzione degli operatori dell''aggiornamento ({0}/{1})';
														|pl = 'Wykonanie procesów przetwarzania aktualizacji ({0}/{1})';
														|tr = 'Güncelleme işleyicilerin yürütülmesi ({0}/{1})'");
	Messages["[TheConnectionPermissionMessage]"] = NStr("vi = 'Cho phép các kết nối mới';
														|ru = 'Разрешение подключений новых соединений';
														|en = 'Allowing new connections'; fa = 'Allowing new connections';
														|it = 'Autorizzazione nuove connessioni';
														|pl = 'Zezwolenie podłączeń nowych połączeń';
														|tr = 'Yeni bağlantıların bağlanmasına izin verme'");
	Messages["[UpdateCompletionMessage]"] = NStr("vi = 'Kết thúc';
												|ru = 'Завершение';
												|en = 'Completing'; fa = 'Completing';
												|it = 'Completamento';
												|pl = 'Completing';
												|tr = 'Bitiş'");
	
	// Messages in template PatchesDeletionScript.
	Messages["[InitializationFailureMessage]"] = NStr("vi = 'Chưa khởi tạo biến';
														|ru = 'Переменные не инициализированы';
														|en = 'Variables are not initialized'; fa = 'Variables are not initialized';
														|it = 'Переменные не инициализированы';
														|pl = 'Variables are not initialized';
														|tr = 'Değişkenler başlatılmadı'");
	Messages["[MessageCreatingACOMConnectorObject]"] = NStr("vi = 'Tạo đối tượng kết nối COM...';
															|ru = 'Создание объекта COM-соединителя...';
															|en = 'Creating a COM connector object…'; fa = 'Creating a COM connector object…';
															|it = 'Creazione oggetto connessione COM...';
															|pl = 'Utworzenie obiektu łącznika COM...';
															|tr = 'COM-bağlantı nesnesi oluşturuluyor...'");
	Messages["[MessageFailureToCreateACOMConnectorObject]"] = NStr("vi = 'Không thể tạo đối tượng kết nối COM:';
																	|ru = 'Не удалось создать объект COM-соединителя:';
																	|en = 'Cannot create a COM connector object:'; fa = 'Cannot create a COM connector object:';
																	|it = 'Не удалось создать объект COM-соединителя:';
																	|pl = 'Cannot create a COM connector object:';
																	|tr = 'COM bağlayıcısı nesnesi oluşturulamadı:'");
	Messages["[TheMessageEstablishingAConnectionToTheDatabase]"] = NStr("vi = 'Cài đặt kết nối với';
																		|ru = 'Установка соединения с';
																		|en = 'Connecting with'; fa = 'Connecting with';
																		|it = 'Impostazione connessione con';
																		|pl = 'Nawiązanie połączenia z';
																		|tr = '... ile bağlanıyor'");
	Messages["[TheMessageConnectionFailureWithTheDatabaseIsGeneral]"] = NStr("vi = 'Không thể đặt kết nối với';
																			|ru = 'Не удалось установить соединение с';
																			|en = 'Cannot connect to'; fa = 'Cannot connect to';
																			|it = 'Не удалось установить соединение с';
																			|pl = 'Cannot connect to';
																			|tr = 'ile bağlantı kurulamıyor'");
	Messages["[MessageMainEvent]"] = NStr("vi = 'Tắt/Bật sử dụng các bản chỉnh sửa (bản vá lỗi)';
											|ru = 'Отключение/Включение исправлений (патчей)';
											|en = 'Toggle patches'; fa = 'Toggle patches';
											|it = 'Отключение/Включение исправлений (патчей)';
											|pl = 'Toggle patches';
											|tr = 'Отключение/Включение исправлений (патчей)'");
	Messages["[MessageCallDisablePatchesFromScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Gọi ra %1...';
			|ru = 'Вызов %1...';
			|en = 'Calling %1…'; fa = 'Calling %1…';
			|it = 'Chiamata %1...';
			|pl = 'Wywołanie %1...';
			|tr = 'Çağrı %1...'"), "ConfigurationUpdateServerCall.DisablePatchesFromScript");
	Messages["[MessageCallEnablePatchesFromScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Gọi ra %1...';
			|ru = 'Вызов %1...';
			|en = 'Calling %1…'; fa = 'Calling %1…';
			|it = 'Chiamata %1...';
			|pl = 'Wywołanie %1...';
			|tr = 'Çağrı %1...'"), "ConfigurationUpdateServerCall.EnablePatchesFromScript");
	Messages["[TheMessageIsACallToRemoveFixesFromTheScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Gọi ra %1...';
			|ru = 'Вызов %1...';
			|en = 'Calling %1…'; fa = 'Calling %1…';
			|it = 'Chiamata %1...';
			|pl = 'Wywołanie %1...';
			|tr = 'Çağrı %1...'"), "ConfigurationUpdateServerCall.DeletePatchesFromScript");
	Messages["[TheMessageIsACallToUpdateTheFixesFromTheScript]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Gọi ra %1...';
			|ru = 'Вызов %1...';
			|en = 'Calling %1…'; fa = 'Calling %1…';
			|it = 'Chiamata %1...';
			|pl = 'Wywołanie %1...';
			|tr = 'Çağrı %1...'"), "ConfigurationUpdateServerCall.UpdatePatchesFromScript");
	Messages["[ErrorMessage_]"] = NStr("vi = ': Lỗi trong cấu hình:';
										|ru = ': Ошибка в конфигурации:';
										|en = ': Configuration error:'; fa = ': Configuration error:';
										|it = ':Errore in configurazione:';
										|pl = ': Błąd w konfiguracji:';
										|tr = ': Konfigürasyon hatası:'") + Chars.NBSp;
	Messages["[MessageImportance]"] = NStr("vi = 'Bắt buộc';
											|ru = 'Обязательная';
											|en = 'Required'; fa = 'موردنیاز';
											|it = 'Obbligatorio';
											|pl = 'Required';
											|tr = 'Gerekli'");
	
	Return Messages;
	
EndFunction

Function VersionsRequiringSuccessfulUpdate(FilesOfUpdate) Export
	
	Table = New ValueTable;
	Table.Columns.Add("Version");
	Table.Columns.Add("VersionWeight");
	Table.Columns.Add("Required");
	
	If FilesOfUpdate.Count() < 2 Then
		Return New Array;
	EndIf;
	
	For Each InformationRecords In FilesOfUpdate Do
		UpdateDetails1 = New ConfigurationUpdateDescription(InformationRecords.BinaryData);
		
		String = Table.Add();
		String.Version       = UpdateDetails1.TargetConfiguration.Version;
		String.VersionWeight    = VersionWeight(String.Version);
		String.Required = InformationRecords.Required;
	EndDo;
	
	Versions = New Array;
	Table.Sort("VersionWeight Asc");
	LastRow = Table[Table.Count() - 1];
	For Each TableRow In Table Do
		If Not TableRow.Required Then
			Continue;
		EndIf;
		
		If TableRow = LastRow Then
			Continue; // Ignore the latest version.
		EndIf;
		
		Versions.Add(TableRow.Version);
	EndDo;
	
	Return Versions;
	
EndFunction

Function VersionWeight(Version)
	
	VersionByParts = StrSplit(Version, ".");
	
	Return 0
		+ Number(VersionByParts[0]) * 1000000000000
		+ Number(VersionByParts[1]) * 100000000
		+ Number(VersionByParts[2]) * 10000
		+ Number(VersionByParts[3]);
	
EndFunction

Function ParametersOfUpdate() Export
	
	ParametersOfUpdate = New Structure;
	ParametersOfUpdate.Insert("UpdateAdministratorName", Undefined);
	ParametersOfUpdate.Insert("UpdateScheduled", False);
	ParametersOfUpdate.Insert("UpdateComplete", False);
	ParametersOfUpdate.Insert("ConfigurationUpdateResult", Undefined);
	ParametersOfUpdate.Insert("ScriptDirectory", "");
	ParametersOfUpdate.Insert("MainScriptFileName", "");
	ParametersOfUpdate.Insert("PatchInstallationResult", Undefined);
	ParametersOfUpdate.Insert("VersionsRequiringSuccessfulUpdate", Undefined);
	
	Return ParametersOfUpdate;
	
EndFunction

#EndRegion
