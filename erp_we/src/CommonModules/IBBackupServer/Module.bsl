///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Saves backup parameters.
//
Procedure SetBackupSettings(Val Settings, Val User = Undefined) Export
	If Not ValueIsFilled(Settings) Then
		Settings = NewBackupSettings();
	EndIf;	
	Common.CommonSettingsStorageSave("BackupParameters", "", Settings);
	If User <> Undefined Then
		CopyingParameters = New Structure("User", User);
		Constants.BackupParameters.Set(New ValueStorage(CopyingParameters, New Deflation(9)));
	EndIf;
EndProcedure

// Returns the current backup setting as String.
// Two options of using functions: passing all parameters, or without parameters.
//
Function CurrentBackupSetting() Export
	
	BackupSettings1 = BackupSettings1();
	If BackupSettings1 = Undefined Then
		Return NStr("vi = 'Để tùy chỉnh sao lưu dự phòng, hãy liên hệ với người quản trị.';
					|ru = 'Для настройки резервного копирования обратитесь к администратору.';
					|en = 'To set up backup, contact your administrator.'; fa = 'To set up backup, contact your administrator.';
					|it = 'Per impostare il backup, contattare l''amministratore.';
					|pl = 'Aby skonfigurować kopiowanie zapasowe zwróć się do administratora.';
					|tr = 'Yedeklemeyi yapılandırmak için yöneticiye başvurun.'");
	EndIf;
	
	CurrentSetting = NStr("vi = 'Chưa tùy chỉnh sao lưu dự phòng, cơ sở thông tin có nguy cơ bị mất dữ liệu.';
							|ru = 'Резервное копирование не настроено, информационная база подвергается риску потери данных.';
							|en = 'Backup is not set up. Configure backup settings to prevent data loss.'; fa = 'Backup is not set up. Configure backup settings to prevent data loss.';
							|it = 'Il backup non è stato impostato, si rischia di perdere i dati del database.';
							|pl = 'Tworzenie kopii zapasowej nie jest skonfigurowane, baza danych jest zagrożona utratą danych.';
							|tr = 'Yedekleme yapılandırılmamış. Veritabanını veri kaybı risklerine maruz kalabilir.'");
	
	If Common.FileInfobase() Then
		
		If BackupSettings1.CreateBackupAutomatically Then
			
			If BackupSettings1.ExecutionOption = "OnExit" Then
				CurrentSetting = NStr("vi = 'Đang thực hiện sao lưu dự phòng thường xuyên khi kết thúc công việc.';
										|ru = 'Резервное копирование выполняется регулярно при завершении работы.';
										|en = 'Backups are created automatically on exit.'; fa = 'Backups are created automatically on exit.';
										|it = 'Il backup viene eseguito regolarmente alla fine della sessione.';
										|pl = 'Kopia zapasowa wykonywana jest regularnie przy zakończeniu pracy.';
										|tr = 'Yedekleme işlem bitiminde düzenli olarak yapılır.'");
			ElsIf BackupSettings1.ExecutionOption = "Schedule3" Then // On schedule.
				Schedule = CommonClientServer.StructureToSchedule(BackupSettings1.CopyingSchedule);
				If Not IsBlankString(Schedule) Then
					CurrentSetting = NStr("vi = 'Đang thực hiện sao lưu dự phòng thường xuyên theo lịch biểu: %1';
											|ru = 'Резервное копирование выполняется регулярно по расписанию: %1';
											|en = 'Backups are created on schedule: %1.'; fa = 'Backups are created on schedule: %1.';
											|it = 'Il backup viene eseguito regolarmente secondo la pianificazione: %1';
											|pl = 'Kopie zapasowe są regularnie planowane wg harmonogramu:%1';
											|tr = 'Düzenli aralıklarla yedekleme:%1'");
					CurrentSetting = StringFunctionsClientServer.SubstituteParametersToString(CurrentSetting, Schedule);
				EndIf;
			EndIf;
			
		Else
			
			If BackupSettings1.BackupConfigured Then
				CurrentSetting = NStr("vi = 'Không thực hiện sao lưu dự phòng (do các ứng dụng bên ngoài tiến hành).';
										|ru = 'Резервное копирование не выполняется (организовано сторонними приложениями).';
										|en = 'Backups are created by third-party backup tools.'; fa = 'Backups are created by third-party backup tools.';
										|it = 'Резервное копирование не выполняется (организовано сторонними приложениями).';
										|pl = 'Backups are created by third-party backup tools.';
										|tr = 'Yedekleme çalışmıyor (harici uygulamalar tarafından düzenlenmiştir).'");
			EndIf;
			
		EndIf;
		
	Else
		
		CurrentSetting = NStr("vi = 'Không thực hiện sao lưu dự phòng (do các công cụ của hệ quản trị CSDL tiến hành).';
								|ru = 'Резервное копирование не выполняется (организовано средствами СУБД).';
								|en = 'Backups are created by the means of DBMS.'; fa = 'Backups are created by the means of DBMS.';
								|it = 'Il backup non viene eseguito (viene organizzato tramite il DBMS).';
								|pl = 'Kopia zapasowa nie jest wykonywana (organizowana za pomocą SZBD).';
								|tr = 'Yedekleme çalışmıyor (DBMS kaynakları tarafından düzenlenmiş).'");
		
	EndIf;
	
	Return CurrentSetting;
	
EndFunction

// Link for substitution in a formatted string for opening infobase backup data processor.
//
// Returns:
//   String - URL.
//
Function BackupDataProcessorURL() Export
	
	Return "e1cib/app/DataProcessor.IBBackup";
	
EndFunction

#Region ConfigurationSubsystemsEventHandlers

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Common.IsWebClient()
		Or Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	DisabledNotificationOfBackupSettings = ModuleToDoListServer.UserTaskDisabled("SetUpBackup");
	DisabledNotificationOfBackupExecution = ModuleToDoListServer.UserTaskDisabled("ExecuteBackup");
	
	If Not AccessRight("View", Metadata.DataProcessors.IBBackupSetup)
		Or (DisabledNotificationOfBackupSettings
			And DisabledNotificationOfBackupExecution) Then
		Return;
	EndIf;
	
	BackupSettings1 = BackupSettings1();
	If BackupSettings1 = Undefined Then
		Return;
	EndIf;
	
	NotificationOption = BackupSettings1.NotificationParameter1;
	
	// The procedure can be called only if the "To-do list" subsystem is integrated.
	// Therefore, don't check if the subsystem is integrated.
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.DataProcessors.IBBackupSetup.FullName());
	
	For Each Section In Sections Do
		
		If Not DisabledNotificationOfBackupSettings Then
			
			BackupSettingFormName = ?(Common.FileInfobase(),
				"DataProcessor.IBBackupSetup.Form.BackupSetup",
				"DataProcessor.IBBackupSetup.Form.BackupSetupClientServer");
			
			ToDoItem = ToDoList.Add();
			ToDoItem.Id  = "SetUpBackup" + StrReplace(Section.FullName(), ".", "");
			ToDoItem.HasToDoItems       = NotificationOption = "NotConfiguredYet";
			ToDoItem.Presentation  = NStr("vi = 'Tùy chỉnh sao lưu dự phòng';
											|ru = 'Настроить резервное копирование';
											|en = 'Set up backup'; fa = 'Set up backup';
											|it = 'Impostare il backup';
											|pl = 'Skonfiguruj tworzenie kopii zapasowych';
											|tr = 'Yedeklemeyi yapılandır'");
			ToDoItem.Important         = True;
			ToDoItem.Form          = BackupSettingFormName;
			ToDoItem.Owner       = Section;
		EndIf;
		
		If Not DisabledNotificationOfBackupExecution Then
			ToDoItem = ToDoList.Add();
			ToDoItem.Id  = "ExecuteBackup" + StrReplace(Section.FullName(), ".", "");
			ToDoItem.HasToDoItems       = NotificationOption = "Overdue";
			ToDoItem.Presentation  = NStr("vi = 'Chưa thực hiện sao lưu dự phòng';
											|ru = 'Резервное копирование не выполнено';
											|en = 'Backup required'; fa = 'Backup required';
											|it = 'Backup non riuscito';
											|pl = 'Nie udało się utworzyć kopii zapasowej';
											|tr = 'Yedekleme tamamlanmadı'");
			ToDoItem.Important         = True;
			ToDoItem.Form          = "DataProcessor.IBBackup.Form.DataBackup";
			ToDoItem.Owner       = Section;
		EndIf;
		
	EndDo;
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	Parameters.Insert("IBBackup", BackupSettings1(True));
	Parameters.Insert("IBBackupOnExit", ParametersOnExit1());
	
EndProcedure

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	
	Parameters.Insert("IBBackup", BackupSettings1());
	
EndProcedure

// See SafeModeManagerOverridable.OnEnableSecurityProfiles.
Procedure OnEnableSecurityProfiles() Export
	
	Settings = BackupSettings1();
	If Settings = Undefined Then
		Return;
	EndIf;
	
	If Settings.Property("IBAdministratorPassword") Then
		Settings.IBAdministratorPassword = "";
		SetBackupSettings(Settings);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Returns IBBackup subsystem parameters that are required on user
// exit.
//
// Returns:
//  Structure - parameters.
//
Function ParametersOnExit1()
	
	BackupSettings1 = BackupSettings1();
	ExecuteOnExit1 = ?(BackupSettings1 = Undefined, False,
		BackupSettings1.CreateBackupAutomatically
		And BackupSettings1.ExecutionOption = "OnExit");
	
	ParametersOnExit = New Structure;
	ParametersOnExit.Insert("NotificationRolesAvailable",   Users.IsFullUser(,True));
	ParametersOnExit.Insert("ExecuteOnExit1", ExecuteOnExit1);
	
	Return ParametersOnExit;
	
EndFunction

// Returns the default automatic backup settings.
//
Function NewBackupSettings()
	
	Parameters = New Structure;
	
	Parameters.Insert("CreateBackupAutomatically", False);
	Parameters.Insert("BackupConfigured", False);
	
	Parameters.Insert("LastNotificationDate", '00010101');
	Parameters.Insert("LatestBackupDate", '00010101');
	Parameters.Insert("MinDateOfNextAutomaticBackup", '29990101');
	
	Parameters.Insert("CopyingSchedule", CommonClientServer.ScheduleToStructure(New JobSchedule));
	Parameters.Insert("BackupStorageDirectory", "");
	Parameters.Insert("ManualBackupsStorageDirectory", ""); // For manual backing up.
	Parameters.Insert("BackupCreated1", False);
	Parameters.Insert("RestorePerformed", False);
	Parameters.Insert("CopyingResult", Undefined);
	Parameters.Insert("BackupFileName", "");
	Parameters.Insert("ExecutionOption", "Schedule3");
	Parameters.Insert("ProcessRunning", False);
	Parameters.Insert("IBAdministrator", "");
	Parameters.Insert("IBAdministratorPassword", "");
	Parameters.Insert("DeletionParameters", DefaultBackupDeletionParameters());
	Parameters.Insert("LastBackupManualStart", True);
	
	Return Parameters;
	
EndFunction

// Returns saved backup parameters.
//
// Returns:
//   See NewBackupSettings
//
Function BackupParameters() Export
	
	Parameters = Common.CommonSettingsStorageLoad("BackupParameters", "");
	NewParameters = NewBackupSettings();
	If Parameters = Undefined Then
		SetBackupSettings(NewParameters);
	Else
		FillPropertyValues(NewParameters, Parameters); 
	EndIf;
	Return NewParameters;
	
EndFunction

// Returns:
//   Boolean - True if it is time for backup.
//
Function NecessityOfAutomaticBackup()
	
	If Not Common.FileInfobase() Then
		Return False;
	EndIf;
	
	Parameters = BackupParameters();
	If Parameters = Undefined Then
		Return False;
	EndIf;
	Schedule = Parameters.CopyingSchedule;
	If Schedule = Undefined Then
		Return False;
	EndIf;
	
	If Parameters.Property("ProcessRunning") And Parameters.ProcessRunning Then
		Return False;
	EndIf;
	
	CheckDate = CurrentSessionDate();
	NextCopyingDate = Parameters.MinDateOfNextAutomaticBackup;
	If NextCopyingDate = '29990101' Or NextCopyingDate > CheckDate Then
		Return False;
	EndIf;
	
	CheckStartDate = Parameters.LatestBackupDate;
	ScheduleValue1 = CommonClientServer.StructureToSchedule(Schedule);
	Return ScheduleValue1.ExecutionRequired(CheckDate, CheckStartDate);
	
EndFunction

Procedure ResetBackupFlag() Export
	
	Settings = BackupSettings1();
	Settings.BackupCreated1 = False;
	SetBackupSettings(Settings);
	
	If Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		OperationName = "StandardSubsystems.IBBackup.BackupCreated";
		ModuleMonitoringCenter = Common.CommonModule("MonitoringCenter");
		ModuleMonitoringCenter.WriteBusinessStatisticsOperation(OperationName, 1);
	EndIf;
	
EndProcedure

// Parameters: 
//  NotificationDate1 - Date - date and time the user was last notified of required
//	                         backup.
//
Procedure SetLastNotificationDate(NotificationDate1) Export
	
	Settings = BackupParameters();
	Settings.LastNotificationDate = NotificationDate1;
	SetBackupSettings(Settings);
	
EndProcedure

// Parameters: 
//  TagName - String - a parameter name.
//   ElementValue - Arbitrary - a parameter value.
//
Procedure SetSettingValue(TagName, ElementValue) Export
	
	Settings = BackupParameters();
	Settings.Insert(TagName, ElementValue);
	SetBackupSettings(Settings);
	
EndProcedure

// Parameters: 
//  WorkStart - Boolean - shows that the call is performed on application start.
//
// Returns:
//  Structure - backup parameters.
//
Function BackupSettings1(WorkStart = False) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return Undefined; 
	EndIf;
	
	If Not Users.IsFullUser(,True) Then
		Return Undefined; 
	EndIf;
	
	Result = BackupParameters();
	
	// Defining a user notification option
	NotificationOption = "DontNotify";
	NotifyOfBackupNecessity = CurrentSessionDate() >= (Result.LastNotificationDate + 3600 * 24);
	If IsInfobaseBackupSubsystemUsed() Then
		If Result.CreateBackupAutomatically Then
			NotificationOption = ?(NecessityOfAutomaticBackup(), "Overdue", "Configured");
		ElsIf Not Result.BackupConfigured Then
			If NotifyOfBackupNecessity Then	
				BackupSettings1 = Constants.BackupParameters.Get().Get();
				If BackupSettings1 <> Undefined
					And BackupSettings1.User <> Users.CurrentUser() Then
					NotificationOption = "DontNotify";
				Else
					NotificationOption = "NotConfiguredYet";
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Result.Insert("NotificationParameter1", NotificationOption);
	
	If Result.BackupCreated1 And Result.CopyingResult  Then
		CurrentSessionDate = CurrentSessionDate();
		Result.LatestBackupDate = CurrentSessionDate;
		// Save the date of the last backup to common settings storage.
		Settings = BackupParameters();
		Settings.LatestBackupDate = CurrentSessionDate;
		SetBackupSettings(Settings);
	EndIf;
	
	If Result.RestorePerformed Then
		UpdateRestoreResult();
	EndIf;
	
	If WorkStart And Result.ProcessRunning Then
		Result.ProcessRunning = False;
		SetSettingValue("ProcessRunning", False);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a flag indicating that the IBBackup subsystem is selected as the main backup
// subsystem.
//
// Returns:
//  Boolean
//
Function IsInfobaseBackupSubsystemUsed()
	
	If Common.SubsystemExists("OnlineUserSupport.CloudArchive20") Then
		ModuleCloudArchive20 = Common.CommonModule("CloudArchive20");
		Return ModuleCloudArchive20.IsInfobaseBackupSubsystemUsed();
	EndIf;
	
	Return True;
	
EndFunction

Procedure UpdateRestoreResult()
	
	Settings = BackupParameters();
	Settings.RestorePerformed = False;
	SetBackupSettings(Settings);
	
EndProcedure

Function UserInformation() Export
	
	UserInformation = New Structure("Name, PasswordRequired", "", False);
	UsedUsers = InfoBaseUsers.GetUsers().Count() > 0;
	
	If Not UsedUsers Then
		Return UserInformation;
	EndIf;
	
	CurrentUser = StandardSubsystemsServer.CurrentUser();
	PasswordRequired = CurrentUser.PasswordIsSet And CurrentUser.StandardAuthentication;
	
	UserInformation.Name = CurrentUser.Name;
	UserInformation.PasswordRequired = PasswordRequired;
	
	Return UserInformation;
	
EndFunction

// Writes a flag indicating that backup has been done.
// Called from the script via COM connection.
// 
// Parameters:
//  Result - Boolean - the result of copying.
//  BackupFileName - String - a backup file name.
//
Procedure FinishBackup(Result, BackupFileName =  "") Export
	
	Settings = BackupSettings1();
	Settings.BackupCreated1 = True;
	Settings.CopyingResult = Result;
	Settings.BackupFileName = BackupFileName;
	SetBackupSettings(Settings);
	
EndProcedure

// Writes a flag that indicates executed restoration from the backup.
// Called from the script via COM connection.
//
// Parameters:
//  Result - Boolean - a restore result.
//
Procedure CompleteRestore(Result) Export
	
	Settings = BackupSettings1();
	Settings.RestorePerformed = True;
	SetBackupSettings(Settings);
	
EndProcedure

Function DefaultBackupDeletionParameters()
	
	DeletionParameters = New Structure;
	DeletionParameters.Insert("RestrictionType", "ByPeriod");
	DeletionParameters.Insert("CopiesCount", 10);
	DeletionParameters.Insert("PeriodUOM", "Month");
	DeletionParameters.Insert("ValueInUOMs", 6);
	Return DeletionParameters;
	
EndFunction

// Parameters:
//   ScriptParameters - See IBBackupClient.GeneralScriptParameters.
//
Function PrepareCommonScriptParameters(Val ScriptParameters) Export
	
	ConnectionParameters = ScriptParameters.ScriptParameters;
	InfoBaseConnectionString = ConnectionParameters.InfoBaseConnectionString + ConnectionParameters.StringForConnection;
	
	If StrEndsWith(InfoBaseConnectionString, ";") Then
		InfoBaseConnectionString = Left(InfoBaseConnectionString, StrLen(InfoBaseConnectionString) - 1);
	EndIf;
	
	BinDir = ?(IsBlankString(ScriptParameters.BinDir), BinDir(), ScriptParameters.BinDir);
	NameOfExecutableApplicationFile = BinDir + ScriptParameters.ApplicationFileName;
	
	// Determining path to the infobase.
	FileModeFlag = Undefined;
	InfobasePath = IBConnectionsClientServer.InfobasePath(FileModeFlag, 0);
	
	InfobasePathParameter = ?(FileModeFlag, "/F", "/S") + InfobasePath; 
	InfobasePathString	= ?(FileModeFlag, InfobasePath, "");
	
	TextParameters = New Map;
	TextParameters["[NameOfExecutableApplicationFile]"] = PrepareText(NameOfExecutableApplicationFile);
	TextParameters["[InfobasePathParameter]"] = PrepareText(InfobasePathParameter);
	TextParameters["[InfobaseFilePathString]"] = PrepareText(
		CommonClientServer.AddLastPathSeparator(StrReplace(InfobasePathString, """", "")));
	TextParameters["[InfoBaseConnectionString]"] = PrepareText(InfoBaseConnectionString);
	TextParameters["[AdministratorName]"] = PrepareText(UserName());
	TextParameters["[EventLogEvent]"] = PrepareText(ScriptParameters.EventLogEvent);
	TextParameters["[CreateDataBackup]"] = "true";
	TextParameters["[COMConnectorName]"] = PrepareText(ScriptParameters.COMConnectorName);
	TextParameters["[UseCOMConnector]"] = ?(ScriptParameters.IsBaseConfigurationVersion, "false", "true");
	TextParameters["[OneCEnterpriseStartupParameters]"] = PrepareText(ScriptParameters.OneCEnterpriseStartupParameters);
	TextParameters["[UnlockCode1]"] = "Backup";
	TextParameters["[COMConnectorPath]"] = PrepareText(ScriptParameters.COMConnectorPath);
	
	Return TextParameters;
	
EndFunction

Function SubstituteParametersToText(Val Text, Val TextParameters) Export
	
	Result = Text;	
	CommonClientServer.SupplementMap(TextParameters, ScriptMessages());
	
	For Each TextParameter In TextParameters Do
		Result = StrReplace(Result, TextParameter.Key, TextParameter.Value);
	EndDo;
	
	Return Result; 
	
EndFunction

Function PrepareText(Val Text) Export 
	
	Text = StrReplace(Text, "\", "\\");
	Text = StrReplace(Text, """", "\""");
	Text = StrReplace(Text, "'", "\'");
	Return "'" + Text + "'";
	
EndFunction

Function ScriptMessages()
	
	Messages = New Map;
	
	// Messages in templates BackupFileTemplate and LoadIBFileTemplate.
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
	Messages["[StartupFailureMessage]"] = NStr("vi = 'Không tồn tại tệp khởi chạy: {0}';
												|ru = 'Запускаемый файл не существует: {0}';
												|en = 'The executable file does not exist: {0}'; fa = 'The executable file does not exist: {0}';
												|it = 'Il file avviabile non esiste: {0}';
												|pl = 'Uruchamianego pliku nie istnieje: {0}';
												|tr = 'Başlatılan dosya mevcut değil: {0}'");
	Messages["[MessageLogging1S]"] = NStr("vi = 'Loại trừ khi ghi lại nhật ký: {0}, {1}';
											|ru = 'Исключение при записи журнала: {0}, {1}';
											|en = 'Exception when writing event log: {0}, {1}'; fa = 'Exception when writing event log: {0}, {1}';
											|it = 'Esclusione alla registrazione del registro: {0}, {1}';
											|pl = 'Wykluczenie podczas zapisywania dziennika: {0}, {1}';
											|tr = 'Günlük kayıt oluşturma sırasında istisna: {0}, {1}'");
	Messages["[TheMessageIsThePathToTheScriptFile]"] = NStr("vi = 'Tệp script: {0}';
															|ru = 'Файл скрипта: {0}';
															|en = 'Script file: {0}'; fa = 'Script file: {0}';
															|it = 'File di script: {0}';
															|pl = 'Plik skryptu: {0}';
															|tr = 'Komut dizisi dosyası: {0}'");
	Messages["[MessagePathToTheBackupFile]"] = NStr("vi = 'Tệp sao lưu dự phòng: {0}';
													|ru = 'Файл резервной копии: {0}';
													|en = 'Backup file: {0}'; fa = 'Backup file: {0}';
													|it = 'File di backup: {0}';
													|pl = 'Plik kopii zapasowej: {0}';
													|tr = 'Yedekleme dosyası: {0}'");
	Messages["[TheMessageIsTheResultOfCreatingABackupCopyOfTheDatabase]"] = NStr("vi = 'Đã tạo thành công bản sao dự phòng';
																				|ru = 'Резервная копия успешно создана';
																				|en = 'Backed up'; fa = 'Backed up';
																				|it = 'Backup creato con successo';
																				|pl = 'Kopia zapasowy została utworzona pomyślnie';
																				|tr = 'Yedekleme dosyası başarıyla oluşturuldu'");
	Messages["[TheMessageFailureToCreateABackupCopyOfTheDatabase]"] = NStr("vi = 'Không thể tạo bản sao dự phòng cơ sở dữ liệu';
																			|ru = 'Не удалось создать резервную копию базы';
																			|en = 'Cannot back up the infobase'; fa = 'Cannot back up the infobase';
																			|it = 'Non è stato possibile creare un backup della base';
																			|pl = 'Nie udało się utworzyć kopii zapasowej bazy';
																			|tr = 'Tabanın yedekleme dosyası oluşturulamadı'");
	Messages["[TheMessageTheBeginningOfTheConnectionSessionWithTheDatabase]"] = NStr("vi = 'Bắt đầu phiên kết nối ngoài với CSTT';
																					|ru = 'Начат сеанс внешнего соединения с ИБ';
																					|en = 'External infobase connection session started'; fa = 'External infobase connection session started';
																					|it = 'Sessione iniziata di connessione esterna con l''infobase';
																					|pl = 'Rozpoczęto sesję połączenia zewnętrznego z BI';
																					|tr = 'Infobase ile dış bağlantı oturumu başlatıldı'");
	Messages["[MessageOSBitnessUndefined]"] = NStr("vi = '<Không xác định>';
													|ru = '<Неопределена>';
													|en = '<Undefined>'; fa = '<Undefined>';
													|it = '<non definito>';
													|pl = '<Undefined>';
													|tr = '<Tanımsız>'");
	Messages["[MessageCOMConnectorVersion]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Phiên bản %1: {0} {1}';
			|ru = 'Версия %1: {0} {1}';
			|en = 'Version %1: {0} {1}'; fa = 'Version %1: {0} {1}';
			|it = 'Versione %1:  {0} {1}';
			|pl = 'Wersja %1: {0} {1}';
			|tr = 'Sürüm %1: {0} {1}'"), "comcntr.dll");
	Messages["[TheMessageConnectionFailureWithTheDatabase]"] = NStr("vi = 'Loại trừ khi tạo kết nối COM tại bước: {0}, {1}, {2}';
																	|ru = 'Исключение при создании COM-соединения на шаге: {0}, {1}, {2}';
																	|en = 'Exception during COM connection creation at the step: {0}, {1}, {2}'; fa = 'Exception during COM connection creation at the step: {0}, {1}, {2}';
																	|it = 'Esclusione alla creazione della connessione COM al passaggio: {0}, {1}, {2}';
																	|pl = 'Wykluczenie przy nawiązaniu połączenia COM na kroku: {0}, {1}, {2}';
																	|tr = 'COM-bağlantı oluşturulurken şu adımda istisna: {0}, {1}, {2}'");
	Messages["[TheMessageLoggingFailure1S]"] = NStr("vi = 'Loại trừ khi ghi vào nhật ký sự kiện: {0}, {1}';
													|ru = 'Исключение при записи в журнал регистрации: {0}, {1}';
													|en = 'Exception when writing data to event log: {0}, {1}'; fa = 'Exception when writing data to event log: {0}, {1}';
													|it = 'Esclusione alla registrazione nel registro: {0}, {1}';
													|pl = 'Wykluczenie podczas zapisywania do dziennika rejestracji: {0}, {1}';
													|tr = 'Günlük kaydı oluşturulurken istisna: {0}, {1}'");
	Messages["[TheMessageFailureWhenCallingCompleteBackup]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Loại trừ khi gọi ra %1: {0}, {1}';
			|ru = 'Исключение при вызове %1: {0}, {1}';
			|en = 'Exception when calling %1: {0}, {1}'; fa = 'Exception when calling %1: {0}, {1}';
			|it = 'Esclusione alla chiamata %1: {0}, {1}';
			|pl = 'Wykluczenie podczas wywołaniu %1: {0}, {1}';
			|tr = '%1çağrı sırasında istisna: {0}, {1}'"), "IBBackupServer.FinishBackup");
	Messages["[TheMessageDatabaseBackupResult]"] = NStr("vi = 'Đã thực hiện thành công sao lưu dự phòng cơ sở dữ liệu.';
														|ru = 'Резервное копирование базы выполнено успешно.';
														|en = 'Infobase is backed up.'; fa = 'Infobase is backed up.';
														|it = 'Backup della base eseguito con successo.';
														|pl = 'Kopiowanie zapasowe bazy zostało wykonane pomyślnie.';
														|tr = 'Tabanın yedeklemesi başarıyla tamamlandı.'");
	Messages["[TheMessageDatabaseBackupFailure]"] = NStr("vi = 'Đã xảy ra tình huống bất thường khi sao lưu dự phòng cơ sở thông tin.';
														|ru = 'Непредвиденная ситуация при резервном копировании информационной базы.';
														|en = 'An unexpected error occurred while backing up the infobase.'; fa = 'An unexpected error occurred while backing up the infobase.';
														|it = 'Непредвиденная ситуация при резервном копировании информационной базы.';
														|pl = 'An unexpected error occurred while backing up the infobase.';
														|tr = 'Infobase yedeklenirken beklenmeyen bir durum oluştu.'");
	Messages["[TheMessageDatabaseParameters]"] = NStr("vi = 'Tham số cơ sở thông tin: {0}.';
														|ru = 'Параметры информационной базы: {0}.';
														|en = 'Infobase parameters: {0}.'; fa = 'Infobase parameters: {0}.';
														|it = 'Parametri infobase: {0}.';
														|pl = 'Parametry bazy informacyjnej: {0}.';
														|tr = 'Infobase parametreleri: {0}.'");
	Messages["[MessageBackupLogging1S]"] = NStr("vi = 'Giao thức sao lưu dự phòng được lưu trong nhật ký sự kiện.';
												|ru = 'Протокол резервного копирования сохранен в журнал регистрации.';
												|en = 'The backup protocol is saved to the event log.'; fa = 'The backup protocol is saved to the event log.';
												|it = 'Protocollo di backup salvato nel registro degli eventi.';
												|pl = 'Protokół kopiowania zapasowego został zapisany do dziennika rejestracji.';
												|tr = 'Yedekleme protokolü günlüğe kaydedilmiştir.'");
	Messages["[LoggingFailureMessage]"] = NStr("vi = 'Loại trừ khi ghi vào nhật ký sự kiện: {0}, {1}';
												|ru = 'Исключение при записи в журнал: {0}, {1}';
												|en = 'Exception when writing data to log: {0}, {1}'; fa = 'Exception when writing data to log: {0}, {1}';
												|it = 'Esclusione alla registrazione nel registro: {0}, {1}';
												|pl = 'Wykluczenie podczas zapisywania do dziennika: {0}, {1}';
												|tr = 'Günlük kaydı oluşturulurken istisna: {0}, {1}'");
	Messages["[MessageBackupFileSizeInMb]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Dung lượng tệp cơ sở %1: {0} Mb';
			|ru = 'Размер файла базы %1: {0} Мб';
			|en = 'Infobase ""%1"" file size: {0} MB'; fa = 'Infobase ""%1"" file size: {0} MB';
			|it = 'Dimensione file di base %1: {0} Mb';
			|pl = 'Rozmiar pliku bazy %1: {0} MB';
			|tr = '%1 tabanın dosya boyutu: {0} Mb'"), "1Cv8.1CD");
	Messages["[TheMessageFailedToCompressTheBackupFileINZIP]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Dung lượng tệp cơ sở %1 vượt quá 2 Gb, do đó không thể nén vào tệp zip';
			|ru = 'Размер файла базы %1 превышает 2 Гб, поэтому сжатие в zip не используется';
			|en = 'Infobase ""%1"" file size exceeds 2 GB. It will not be compressed to a ZIP archive.'; fa = 'Infobase ""%1"" file size exceeds 2 GB. It will not be compressed to a ZIP archive.';
			|it = 'La dimensione del file di base %1supera i 2 Gb, dunque non può essere compresso in zip';
			|pl = 'Rozmiar pliku bazy %1 przekracza 2 GB, dlatego kompresja do zip nie jest używana';
			|tr = '%1 tabanın dosya boyutu 2 Gb''dan büyük olduğundan zip sıkıştırması kullanılmaz'"), "1Cv8.1CD");
	Messages["[TheMessageTheBeginningOfCreatingABackupCopyOfTheDatabase]"] = NStr("vi = 'Bắt đầu tạo bản sao dự phòng...';
																					|ru = 'Начато создание резервной копии...';
																					|en = 'Backup started…'; fa = 'Backup started…';
																					|it = 'Avvio creazione backup...';
																					|pl = 'Rozpoczęto utworzenie kopii zapasowej...';
																					|tr = 'Yedekleme başlatıldı...'");
	Messages["[TheMessageFailureToCreateABackupCopyOfTheDatabaseInDetail]"] = NStr("vi = 'Ngoại trừ khi tạo bản sao dự phòng cơ sở dữ liệu: {0}, {1}';
																					|ru = 'Исключение при создании резервной копии базы: {0}, {1}';
																					|en = 'Exception when backing up the infobase: {0}, {1}'; fa = 'Exception when backing up the infobase: {0}, {1}';
																					|it = 'Eccezione durante la creazione del backup della base: {0}, {1}';
																					|pl = 'Wykluczenie przy utworzeniu kopii zapasowej bazy: {0}, {1}';
																					|tr = 'Tabanın yedeklemesi oluşturulurken istisna: {0}, {1}'");
	Messages["[TheMessageAssumptionOfADatabaseBackupError]"] = NStr("vi = 'Sau 15 phút, vẫn chưa bắt đầu tạo tệp sao lưu dự phòng (dung lượng {0} byte), có thể là do lỗi. Đã ngắt sao lưu dự phòng.';
																	|ru = 'За 15 минут файл резервной копии все еще не начал создаваться (размер {0} байт), предположительно, из-за возникшей ошибки. Резервное копирование прервано.';
																	|en = 'After 15 minutes of runtime, no backup file has been created (size is {0} byte). Probably, an error has occurred. Back up is canceled.'; fa = 'After 15 minutes of runtime, no backup file has been created (size is {0} byte). Probably, an error has occurred. Back up is canceled.';
																	|it = 'Negli ultimi 15 minuti il file di backup non è stato ancora creato (dimensione {0} byte), probabilmente per l''insorgere di errori. Backup interrotto.';
																	|pl = 'Za 15 minut nadal nie zaczęło się utworzeni pliku kopii zapasowej (rozmiar {0} bajt), prawdopodobnie, z powodu błędu. Kopiowanie rezerwowe zostało przerwane.';
																	|tr = '15 dakika sonra, muhtemelen bir hata nedeniyle, yedekleme dosyasının oluşturulması hala başlatılamadı (boyut {0} bayt). Yedekleme iptal edildi.'");
	Messages["[MessageErrorDeletingTheLockFile]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chưa xóa tệp phong tỏa %1: {0}, {1}';
			|ru = 'Не был удален файл блокировок %1: {0}, {1}';
			|en = 'The ""%1"" lock file is not deleted: {0}, {1}'; fa = 'The ""%1"" lock file is not deleted: {0}, {1}';
			|it = 'Не был удален файл блокировок %1: {0}, {1}';
			|pl = 'The ""%1"" lock file is not deleted: {0}, {1}';
			|tr = 'Kilitleme dosyası %1 silinemedi: {0}, {1}'"), "1Cv8.CDN");
	
	// Messages in templates BackupSplash and RecoverySplash.
	Messages["[SplashScreenMessageStepError]"] = NStr("vi = 'Kết thúc bị lỗi. Mã lỗi: {0}. Chi tiết xem trong bản ghi trước.';
														|ru = 'Завершение с ошибкой. Код ошибки: {0}. Подробности см. в предыдущей записи.';
														|en = 'An error occurred. Error code: {0}. For more information, see the previous record.'; fa = 'An error occurred. Error code: {0}. For more information, see the previous record.';
														|it = 'Esecuzione con errori. Codice errore: {0}. Visualizzare informazioni sulla registrazione precedente.';
														|pl = 'Zakończenie z błędem. Kod błędu: {0}. Szczegóły patrz w poprzednim wpisie.';
														|tr = 'Hatalı sonlandırma. Hata kodu: {0}. Ayrıntılar için önceki kayda bakın.'");
	
	// Messages in template LoadIBFileTemplate.
	Messages["[TheMessageFailureWhenCallingCompleteRecovery]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Loại trừ khi gọi ra %1: {0}, {1}';
			|ru = 'Исключение при вызове %1: {0}, {1}';
			|en = 'Exception when calling %1: {0}, {1}'; fa = 'Exception when calling %1: {0}, {1}';
			|it = 'Esclusione alla chiamata %1: {0}, {1}';
			|pl = 'Wykluczenie podczas wywołaniu %1: {0}, {1}';
			|tr = '%1çağrı sırasında istisna: {0}, {1}'"), "IBBackupServer.CompleteRestore");
	Messages["[TheMessageDatabaseRecoveryResult]"] = NStr("vi = 'Đã phục hồi thành công cơ sở thông tin.';
															|ru = 'Восстановление информационной базы прошло успешно.';
															|en = 'Infobase is restored.'; fa = 'Infobase is restored.';
															|it = 'Il ripristino dell''infobase è stato effettuato con successo.';
															|pl = 'Przywrócenie bazy informacyjnej przeszło pomyślnie.';
															|tr = 'Infobase''in geri yüklemesi başarıyla tamamlandı.'");
	Messages["[DatabaseRecoveryFailureMessage]"] = NStr("vi = 'Đã xảy ra tình huống bất thường khi khôi phục cơ sở thông tin.';
														|ru = 'Непредвиденная ситуация при восстановлении информационной базы.';
														|en = 'An unexpected error occurred while restoring the infobase.'; fa = 'An unexpected error occurred while restoring the infobase.';
														|it = 'Непредвиденная ситуация при восстановлении информационной базы.';
														|pl = 'An unexpected error occurred while restoring the infobase.';
														|tr = 'Infobase''nin geri yüklemesi sırasında beklenmeyen bir durum oluştu.'");
	Messages["[MessageRecoveryLogging1S]"] = NStr("vi = 'Giao thức phục hồi được lưu trong nhật ký sự kiện.';
													|ru = 'Протокол восстановления сохранен в журнал регистрации.';
													|en = 'The restore protocol is saved to the event log.'; fa = 'The restore protocol is saved to the event log.';
													|it = 'Protocollo di ripristino salvato nel registro degli eventi.';
													|pl = 'Protokół przywrócenia został zapisany do dziennika rejestracji.';
													|tr = 'Geri yükleme protokolü kayıt günlüğüne kaydedildi.'");
	Messages["[TheMessageFailureToTransferTheDatabaseFileToATemporaryDirectory]"] = NStr("vi = 'Tệp cơ sở chưa được chuyển đến thư mục tạm thời (có thể là chương trình có các phiên đang làm việc): {0}, {1}.';
																						|ru = 'Файл базы не был перенесен во временный каталог (возможно в приложении есть активные сеансы): {0}, {1}.';
																						|en = 'The infobase file is not transferred to a temporary directory. The app might have active sessions: {0}, {1}.'; fa = 'The infobase file is not transferred to a temporary directory. The app might have active sessions: {0}, {1}.';
																						|it = 'Файл базы не был перенесен во временный каталог (возможно в приложении есть активные сеансы): {0}, {1}.';
																						|pl = 'The infobase file is not transferred to a temporary directory. The app might have active sessions: {0}, {1}.';
																						|tr = 'Veritabanı dosyası geçici bir kataloğa aktarılamadı (uygulamada aktif oturumlar olabilir): {0}, {1}.'");
	Messages["[MessageAttemptToTransferADatabaseFileToATemporaryDirectory]"] = NStr("vi = 'Thử chuyển tệp cơ sở dữ liệu sang thư mục tạm thời ({0} từ 5): {1}, {2}.';
																					|ru = 'Попытка переноса файла базы во временный каталог ({0} из 5): {1}, {2}.';
																					|en = 'Attempting to transfer an infobase file to a temporary directory ({0} out of 5): {1}, {2}.'; fa = 'Attempting to transfer an infobase file to a temporary directory ({0} out of 5): {1}, {2}.';
																					|it = 'Tentativo di trasferimento del file di base nel catalogo temporaneo ({0} di 5): {1}, {2}.';
																					|pl = 'Próba przeniesienia pliku bazy do katalogu tymczasowego ({0} z 5): {1}, {2}.';
																					|tr = 'Veritabanı dosyasının geçici kataloğa (5''dan {0}) taşıma girişimi: {1}, {2}.'");
	Messages["[TheMessageDatabaseRecoveryFailureInDetail]"] = NStr("vi = 'Ngoại trừ khi phục hồi cơ sở dữ liệu từ bản sao dự phòng: {0}, {1}.';
																	|ru = 'Исключение при восстановлении базы из резервной копии: {0}, {1}.';
																	|en = 'Exception when restoring an infobase from a backup: {0}, {1}.'; fa = 'Exception when restoring an infobase from a backup: {0}, {1}.';
																	|it = 'Eccezione durante il ripristino della base da backup: {0}, {1}.';
																	|pl = 'Wykluczenie podczas przywrócenia bazy z kopii zapasowej: {0}, {1}.';
																	|tr = 'Yedekten veritabanının geri yüklenmesi sırasında istisna: {0}, {1}.'");
	
	Return Messages;
	
EndFunction

Procedure SetTheGeneralParametersOfTheScreenSaver(Parameters) Export 
	
	Parameters["[ProductName]"] = NStr("vi = '1C:ENTERPRISE 8.3';
										|ru = '1С:ПРЕДПРИЯТИЕ 8.3';
										|en = '1C:ENTERPRISE 8.3'; fa = '1C:ENTERPRISE 8.3';
										|it = '1C:ENTERPRISE 8.3';
										|pl = '1С:ENTERPRISE 8.3';
										|tr = '1C:ENTERPRISE 8.3'");
	Parameters["[Copyright]"] = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '© Công ty TNHH ""1C-Soft"", 1996-%1';
			|ru = '© ООО ""1С-Софт"", 1996-%1';
			|en = '© 1C Company, 1996-%1'; fa = '© 1C Company, 1996-%1';
			|it = '© ""1С-Soft"", 1996-%1';
			|pl = '© 1C Company, 1996-%1';
			|tr = '© ООО ""1C-Soft"", 1996-%1'"), Format(Year(CurrentSessionDate()), "NG=0"));
	
EndProcedure

#EndRegion