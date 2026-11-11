///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Opens backup form.
//
// Parameters:
//    Parameters - Structure - backup form parameters.
//
Procedure OpenBackupForm(Parameters = Undefined) Export
	
	OpenForm("DataProcessor.IBBackup.Form.DataBackup", Parameters);
	
EndProcedure

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonClientOverridable.OnStart.
Procedure OnStart(Parameters) Export
	
	If CommonClient.DataSeparationEnabled()
	 Or Not BackupAvailable() Then
		Return;
	EndIf;
	
	Settings = StandardSubsystemsClient.ClientParametersOnStart().IBBackup;
	If Not ValueIsFilled(Settings) Then
		Return;
	EndIf;
	
	FillGlobalVariableValues(Settings);
	CheckIBBackup(Settings);
	If Settings.RestorePerformed Then
		NotificationText1 = NStr("vi = 'Đã phục hồi dữ liệu thành công.';
								|ru = 'Восстановление данных проведено успешно.';
								|en = 'Data successfully restored.'; fa = 'Data successfully restored.';
								|it = 'Recupero dei dati è eseguito con successo.';
								|pl = 'Odzyskiwanie danych przebiegło pomyślnie.';
								|tr = 'Veri başarıyla geri yüklendi.'");
		ShowUserNotification(NStr("vi = 'Đã phục hồi dữ liệu.';
									|ru = 'Данные восстановлены.';
									|en = 'Data is restored.'; fa = 'Data is restored.';
									|it = 'Dati recuperati.';
									|pl = 'Dane zostały przywrócone.';
									|tr = 'Veri geri yüklendi.'"), , NotificationText1);
	EndIf;
	
	NotificationOption = Settings.NotificationParameter1;
	If NotificationOption = "DontNotify" Then
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.ToDoList") Then
		ShowWarning = False;
		IBBackupClientOverridable.OnDetermineBackupWarningRequired(ShowWarning);
	Else
		ShowWarning = True;
	EndIf;
	
	If ShowWarning
		And (NotificationOption = "Overdue" Or NotificationOption = "NotConfiguredYet") Then
		NotifyUserOfBackup(NotificationOption);
	EndIf;
	
	AttachIdleBackupHandler();
	
EndProcedure

// Parameters:
//  Cancel - See CommonClientOverridable.BeforeExit.Cancel
//  Warnings - See CommonClientOverridable.BeforeExit.Warnings
//
Procedure BeforeExit(Cancel, Warnings) Export
	
#If WebClient Or MobileClient Then
		Return;
#EndIf
	
	If Not CommonClient.IsWindowsClient()
	 Or Not CommonClient.FileInfobase()
	 Or CommonClient.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	Parameters = StandardSubsystemsClient.ClientParameter();
	
	If Not Parameters.IBBackupOnExit.NotificationRolesAvailable
		Or Not Parameters.IBBackupOnExit.ExecuteOnExit1 Then
		Return;
	EndIf;
	
	WarningParameters = StandardSubsystemsClient.WarningOnExit();
	WarningParameters.CheckBoxText = NStr("vi = 'Thực hiện sao lưu dự phòng';
											|ru = 'Выполнить резервное копирование';
											|en = 'Back up'; fa = 'پشتیبان‌گیری';
											|it = 'Esegui il backup';
											|pl = 'Utwórz kopię zapasową';
											|tr = 'Yedekleyin'");
	WarningParameters.Priority = 50;
	WarningParameters.WarningText = NStr("vi = 'Đã lập kế hoạch sao lưu dự phòng khi kết thúc công việc.';
										|ru = 'Запланировано резервное копирование при завершении работы.';
										|en = 'Backup scheduled at exit.'; fa = 'Backup scheduled at exit.';
										|it = 'Запланировано резервное копирование при завершении работы.';
										|pl = 'Backup scheduled at exit.';
										|tr = 'Kapatma sırasında veri yedeklemesi planlandı.'");
	
	ActionIfFlagSet = WarningParameters.ActionIfFlagSet;
	ActionIfFlagSet.Form = "DataProcessor.IBBackup.Form.DataBackup";
	FormParameters = New Structure();
	FormParameters.Insert("WorkMode", "ExecuteOnExit");
	ActionIfFlagSet.FormParameters = FormParameters;
	
	Warnings.Add(WarningParameters);
	
EndProcedure

// See SSLSubsystemsIntegrationClient.OnCheckIfCanBackUpInUserMode.
Procedure OnCheckIfCanBackUpInUserMode(Result) Export
	
	If CommonClient.FileInfobase() Then
		Result = True;
	EndIf;
	
EndProcedure

// See SSLSubsystemsIntegrationClient.OnPromptUserForBackup.
Procedure OnPromptUserForBackup() Export
	
	OpenBackupForm();
	
EndProcedure

#EndRegion

#Region Private

Procedure FillGlobalVariableValues(Settings) Export
	
	Result = New Structure;
	Result.Insert("ProcessRunning");
	Result.Insert("MinDateOfNextAutomaticBackup");
	Result.Insert("LatestBackupDate");
	Result.Insert("NotificationParameter1");
	FillPropertyValues(Result, Settings);
	Result.Insert("ScheduleValue1", CommonClientServer.StructureToSchedule(Settings.CopyingSchedule));
	ApplicationParameters.Insert("StandardSubsystems.IBBackupParameters", Result);
	
EndProcedure

// Checks whether it is necessary to start automatic backup
// during user working, as well as repeat notification after ignoring the initial one.
//
Procedure StartIdleHandler() Export
	
	If Not BackupAvailable() Then
		Return;
	EndIf;
	
	If CommonClient.FileInfobase()
	   And NecessityOfAutomaticBackup() Then
		
		PerformABackup();
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.ToDoList") Then
		ShowWarning = False;
		IBBackupClientOverridable.OnDetermineBackupWarningRequired(ShowWarning);
	Else
		ShowWarning = True;
	EndIf;
	
	NotificationOption = ApplicationParameters["StandardSubsystems.IBBackupParameters"].NotificationParameter1;
	If ShowWarning
		And (NotificationOption = "Overdue" Or NotificationOption = "NotConfiguredYet") Then
		NotifyUserOfBackup(NotificationOption);
	EndIf;
	
EndProcedure

// Checks whether the automatic backup is required.
//
// Returns:
//   Boolean - True if necessary, otherwise False.
//
Function NecessityOfAutomaticBackup()
	
	Settings = ApplicationParameters["StandardSubsystems.IBBackupParameters"];
	If Settings = Undefined Then
		Return False;
	EndIf;
	
	ScheduleValue1 = Undefined;
	If Settings.ProcessRunning
		Or Not Settings.Property("MinDateOfNextAutomaticBackup")
		Or Not Settings.Property("ScheduleValue1", ScheduleValue1)
		Or Not Settings.Property("LatestBackupDate") Then
		Return False;
	EndIf;
	If ScheduleValue1 = Undefined Then
		Return False;
	EndIf;
	
	CheckDate = CommonClient.SessionDate();
	NextCopyingDate = Settings.MinDateOfNextAutomaticBackup;
	If NextCopyingDate = '29990101' Or NextCopyingDate > CheckDate Then
		Return False;
	EndIf;
	
	Return ScheduleValue1.ExecutionRequired(CheckDate, Settings.LatestBackupDate);
EndFunction

// Starts backup on schedule.
// 
Procedure PerformABackup()
	
	Buttons = New ValueList;
	Buttons.Add("Yes", NStr("vi = 'Có';
							|ru = 'Да';
							|en = 'Yes'; fa = 'بله';
							|it = 'Sì';
							|pl = 'Tak';
							|tr = 'Evet'"));
	Buttons.Add("None", NStr("vi = 'Không';
							|ru = 'Нет';
							|en = 'No'; fa = 'خیر';
							|it = 'Non ci sono';
							|pl = 'Nie';
							|tr = 'Hayır'"));
	Buttons.Add("Snooze", NStr("vi = 'Hoãn lại 15 phút';
								|ru = 'Отложить на 15 минут';
								|en = 'Snooze for 15 minutes'; fa = 'Snooze for 15 minutes';
								|it = 'Rinvia per 15 minuti';
								|pl = 'Odłóż na 15 minut';
								|tr = '15 dakika ertele'"));
	
	DescriptionOfTheAlert = New CallbackDescription("PerformABackupCompletion", ThisObject);
	ShowQueryBox(DescriptionOfTheAlert, NStr("vi = 'Mọi thứ đã sẵn sàng để sao lưu dự phòng theo lịch biểu.
		| Thực hiện sao lưu ngay bây giờ?';
		|ru = 'Все готово для выполнения резервного копирования по расписанию.
		|Выполнить резервное копирование сейчас?';
		|en = 'Scheduled backup is all set to start.
		|Do you want to start it now?'; fa = 'Scheduled backup is all set to start.
		|Do you want to start it now?';
		|it = 'Tutto è pronto per il backup pianificato.
		|Eseguire il backup adesso?';
		|pl = 'Wszystko jest gotowe do wykonania kopii zapasowej według harmonogramu.
		| Utwórz kopię zapasową już teraz?';
		|tr = 'Her şey zamanlanmış yedeklemeyi gerçekleştirmek için hazırdır. 
		|Şimdi yedekle?'"),
		Buttons, 30, "Yes", NStr("vi = 'Sao lưu dự phòng theo lịch biểu';
								|ru = 'Резервное копирование по расписанию';
								|en = 'Scheduled backup'; fa = 'Scheduled backup';
								|it = 'Backup pianificato';
								|pl = 'Zaplanowana kopia zapasowa';
								|tr = 'Zamanlanmış yedeklenme'"), "Yes");
	
EndProcedure

Procedure PerformABackupCompletion(QuestionResult, AdditionalParameters) Export
	
	ExecuteBackup = QuestionResult = "Yes" Or QuestionResult = DialogReturnCode.Timeout;
	DeferBackup = QuestionResult = "Snooze";
	
	NextDate = IBBackupServerCall.NextAutomaticCopyingDate(DeferBackup);
	Settings = ApplicationParameters["StandardSubsystems.IBBackupParameters"];
	Settings.MinDateOfNextAutomaticBackup = NextDate;
	
	If ExecuteBackup Then
		FormParameters = New Structure("WorkMode", "ExecuteNow");
		OpenForm("DataProcessor.IBBackup.Form.DataBackup", FormParameters);
	EndIf;
	
EndProcedure

// Checks on application startup whether it is the first start after backup. 
// If yes, it displays a handler form with backup results.
//
// Parameters:
//  Parameters - Structure - backup parameters.
//
Procedure CheckIBBackup(Parameters)
	
	If Not Parameters.BackupCreated1 Then
		Return;
	EndIf;
	
	If Parameters.LastBackupManualStart Then
		
		FormParameters = New Structure();
		FormParameters.Insert("WorkMode", ?(Parameters.CopyingResult, "CompletedSuccessfully1", "NotCompleted"));
		FormParameters.Insert("BackupFileName", Parameters.BackupFileName);
		OpenForm("DataProcessor.IBBackup.Form.DataBackup", FormParameters);
		
	Else
		
		ShowUserNotification(NStr("vi = 'Sao lưu dự phòng';
									|ru = 'Резервное копирование';
									|en = 'Backup'; fa = 'پشتیبان‌گیری';
									|it = 'Backup';
									|pl = 'Kopiowanie zapasowe';
									|tr = 'Yedek kopyalama'"),
			"e1cib/command/CommonCommand.ShowBackupResult",
			NStr("vi = 'Đã thực hiện sao lưu dự phòng thành công';
				|ru = 'Резервное копирование проведено успешно';
				|en = 'Backup successful'; fa = 'پشتیبان‌گیری موفق بود';
				|it = 'Backup riuscito';
				|pl = 'Kopiowanie zapasowe zostało przeprowadzone pomyślnie';
				|tr = 'Yedek kopyalama başarıyla gerçekleştirildi'"), PictureLib.DialogInformation);
		IBBackupServerCall.SetSettingValue("BackupCreated1", False);
		
	EndIf;
	
EndProcedure

// Shows a notification according to results of backup parameters analysis.
//
// Parameters: 
//   NotificationOption - String - check result for notifications.
//
Procedure NotifyUserOfBackup(NotificationOption)
	
	ExplanationText = "";
	If NotificationOption = "Overdue" Then
		
		ExplanationText = NStr("vi = 'Chưa thực hiện sao lưu dự phòng tự động.';
								|ru = 'Автоматическое резервное копирование не было выполнено.';
								|en = 'Automatic backup has not been done.'; fa = 'Automatic backup has not been done.';
								|it = 'Il backup automatico non è stato eseguito.';
								|pl = 'Automatyczne tworzenie kopii zapasowej nie zostało wykonane.';
								|tr = 'Otomatik yedekleme gerçekleştirilmedi.'"); 
		ShowUserNotification(NStr("vi = 'Sao lưu dự phòng';
									|ru = 'Резервное копирование';
									|en = 'Backup'; fa = 'پشتیبان‌گیری';
									|it = 'Backup';
									|pl = 'Kopiowanie zapasowe';
									|tr = 'Yedek kopyalama'"),
			"e1cib/app/DataProcessor.IBBackup", ExplanationText, PictureLib.DialogExclamation);
		
	ElsIf NotificationOption = "NotConfiguredYet" Then
		
		SettingsFormName = "e1cib/app/DataProcessor.IBBackupSetup/";
		ExplanationText = NStr("vi = 'Nên tùy chỉnh sao lưu dự phòng cơ sở thông tin.';
								|ru = 'Рекомендуется настроить резервное копирование информационной базы.';
								|en = 'It is recommended that you set up infobase backup.'; fa = 'It is recommended that you set up infobase backup.';
								|it = 'Si consiglia di impostare il backup del database.';
								|pl = 'Zaleca się utworzenie bazy danych kopii zapasowych.';
								|tr = 'Infobase için yedeklemeyi yapılandırmanızı öneririz.'"); 
		ShowUserNotification(NStr("vi = 'Sao lưu dự phòng';
									|ru = 'Резервное копирование';
									|en = 'Backup'; fa = 'پشتیبان‌گیری';
									|it = 'Backup';
									|pl = 'Kopiowanie zapasowe';
									|tr = 'Yedek kopyalama'"),
			SettingsFormName, ExplanationText, PictureLib.DialogExclamation);
			
	EndIf;
	
	CurrentDate = CommonClient.SessionDate();
	IBBackupServerCall.SetLastNotificationDate(CurrentDate);
	
EndProcedure

// Returns an event type of the event log for the current subsystem.
//
// Returns:
//   String - an event type of the event log.
//
Function EventLogEvent() Export
	
	Return NStr("vi = 'Sao lưu dự phòng cơ sở thông tin';
				|ru = 'Резервное копирование информационной базы';
				|en = 'Infobase backup'; fa = 'پشتیبان‌گیری پایگاه اطلاعات';
				|it = 'Backup del database';
				|pl = 'Utworzenie kopii zapasowej bazy informacyjnej';
				|tr = 'Infobase yedeği'", CommonClient.DefaultLanguageCode());
	
EndFunction

// Getting user authentication parameters for update.
// Creates a virtual user if necessary.
//
// Returns:
//  Structure - parameters of a virtual user.
//
Function UpdateAdministratorAuthenticationParameters(AdministratorPassword) Export
	
	Result = New Structure("UserName, UserPassword, StringForConnection, InfoBaseConnectionString");
	
	CurrentConnections = IBConnectionsServerCall.ConnectionsInformation(True,
		ApplicationParameters["StandardSubsystems.MessagesForEventLog"]);
	Result.InfoBaseConnectionString = CurrentConnections.InfoBaseConnectionString;
	If Not CurrentConnections.HasActiveUsers Then
		Return Result;
	EndIf;
	
	Result.UserName    = StandardSubsystemsClient.ClientParametersOnStart().UserCurrentName;
	Result.UserPassword = StringUnicode(AdministratorPassword);
	Result.StringForConnection  = "Usr=""{0}"";Pwd=""{1}""";
	Return Result;
	
EndFunction

Function StringUnicode(String) Export
	
	Result = "";
	
	For CharacterNumber = 1 To StrLen(String) Do
		
		Char = Format(CharCode(Mid(String, CharacterNumber, 1)), "NG=0");
		Char = StringFunctionsClientServer.SupplementString(Char, 4);
		Result = Result + Char;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Checks whether an add-in can be attached to the infobase.
//
Procedure CheckAccessToInfobase(AdministratorPassword, Val Notification) Export
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("AdministratorPassword", AdministratorPassword);
	
	Notification = New CallbackDescription("CheckAccessToInfobaseAfterCOMRegistration", ThisObject, Context);
	CommonClient.RegisterCOMConnector(False, Notification);
	
EndProcedure

Procedure CheckAccessToInfobaseAfterCOMRegistration(IsRegistered, Context) Export
	
	Notification = Context.Notification;
	AdministratorPassword = Context.AdministratorPassword;
	
	ConnectionResult = ConnectionResult();
	
	If IsRegistered Then 
		
		ClientParametersOnStart = StandardSubsystemsClient.ClientParametersOnStart();
		
		ConnectionParameters = CommonClientServer.ParametersStructureForExternalConnection();
		ConnectionParameters.InfobaseDirectory = StrSplit(InfoBaseConnectionString(), """")[1];
		ConnectionParameters.UserName = ClientParametersOnStart.UserCurrentName;
		ConnectionParameters.UserPassword = AdministratorPassword;
		
		Result = CommonClient.EstablishExternalConnectionWithInfobase(ConnectionParameters);
		
		If Result.AddInAttachmentError Then
			EventLogClient.AddMessageForEventLog(
				EventLogEvent(),"Error", Result.DetailedErrorDetails, , True);
		EndIf;
		
		FillPropertyValues(ConnectionResult, Result);
		
		Result.Join = Undefined; // Disconnect.
		
	EndIf;
	
	RunCallback(Notification, ConnectionResult);
	
EndProcedure

Function ConnectionResult()
	
	Result = New Structure;
	Result.Insert("AddInAttachmentError", False);
	Result.Insert("BriefErrorDetails", "");
	
	Return Result;
	
EndFunction

// Attaching a global idle handler.
//
Procedure AttachIdleBackupHandler() Export
	
	AttachIdleHandler("BackupActionsHandler", 60);
	
EndProcedure

// Disable global idle handler.
//
Procedure DisableBackupIdleHandler() Export
	
	DetachIdleHandler("BackupActionsHandler");
	
EndProcedure

Function NumberOfSecondsInPeriod(Period, PeriodType)
	
	If PeriodType = "Day" Then
		Multiplier = 3600 * 24;
	ElsIf PeriodType = "Week" Then
		Multiplier = 3600 * 24 * 7; 
	ElsIf PeriodType = "Month" Then
		Multiplier = 3600 * 24 * 30;
	ElsIf PeriodType = "Year" Then
		Multiplier = 3600 * 24 * 365;
	EndIf;
	
	Return Multiplier * Period;
	
EndFunction

#If Not WebClient And Not MobileClient Then

Procedure DeleteConfigurationBackups() Export
	
	FixedIBBackupParameters = StandardSubsystemsClient.ClientRunParameters().IBBackup;
	StorageDirectory = FixedIBBackupParameters.BackupStorageDirectory;
	DeletionParameters = FixedIBBackupParameters.DeletionParameters;
	If DeletionParameters.RestrictionType = "StoreAll" Or StorageDirectory = Undefined Then
		Return;
	EndIf;
		
	// ACC:566-off - The code is never executed in a browser.
	Try
		File = New File(StorageDirectory);
		If Not File.IsDirectory() Then
			Return;
		EndIf;
		
		BackupFiles = FindFiles(StorageDirectory, "backup????_??_??_??_??_??*", False);
		DeletedFileList = New Array;
		
		If DeletionParameters.RestrictionType = "ByPeriod" Then
			For Each ItemFile In BackupFiles Do
				CurrentDate = CommonClient.SessionDate();
				ValueInSeconds = NumberOfSecondsInPeriod(DeletionParameters.ValueInUOMs, 
					DeletionParameters.PeriodUOM);
				Deletion1 = ((CurrentDate - ValueInSeconds) > ItemFile.GetModificationTime());
				If Deletion1 Then
					DeletedFileList.Add(ItemFile.FullName);
				EndIf;
			EndDo;
			
		ElsIf BackupFiles.Count() > DeletionParameters.CopiesCount Then
			ListOfFiles = New ValueList;
			ListOfFiles.LoadValues(BackupFiles);
			
			For Each File In ListOfFiles Do
				File.Presentation = File.Value.FullName;
				File.Value = File.Value.GetModificationTime();
			EndDo;
			
			ListOfFiles.SortByValue(SortDirection.Asc);
			
			For IndexOf = 0 To ListOfFiles.Count() - DeletionParameters.CopiesCount - 1 Do
				DeletedFileList.Add(ListOfFiles[IndexOf].Presentation);
			EndDo;
		EndIf;
		
		For Each DeletedFile In DeletedFileList Do
			Try
				DeleteFiles(DeletedFile);
			Except
				EventLogClient.AddMessageForEventLog(EventLogEvent(), "Error",
					NStr("vi = 'Không thể xóa thư mục có bản sao dự phòng.';
						|ru = 'Не удалось провести очистку каталога с резервными копиями.';
						|en = 'Failed to clean up backup storage directory.'; fa = 'Failed to clean up backup storage directory.';
						|it = 'Impossibile cancellare la directory di backup.';
						|pl = 'Nie udało się wyczyścić katalogu kopii zapasowej.';
						|tr = 'Yedeklemeli bir dizin temizlenemiyor.'") + Chars.LF 
					+ ErrorProcessing.DetailErrorDescription(ErrorInfo()),,True);
			EndTry;
		EndDo;
		
	Except
		EventLogClient.AddMessageForEventLog(EventLogEvent(), "Error",
			NStr("vi = 'Không thể xóa thư mục có bản sao dự phòng.';
				|ru = 'Не удалось провести очистку каталога с резервными копиями.';
				|en = 'Failed to clean up backup storage directory.'; fa = 'Failed to clean up backup storage directory.';
				|it = 'Impossibile cancellare la directory di backup.';
				|pl = 'Nie udało się wyczyścić katalogu kopii zapasowej.';
				|tr = 'Yedeklemeli bir dizin temizlenemiyor.'") + Chars.LF 
			+ ErrorProcessing.DetailErrorDescription(ErrorInfo()),,True);
	EndTry;
	
	// ACC:566-on
	
EndProcedure

Function IBBackupApplicationFilesEncoding() Export
	
	// wscript.exe can process only UTF-16 LE-encoded files.
	Return TextEncoding.UTF16;
	
EndFunction

// Returns backup script parameters.
//
// Returns:
//   Structure - structure of the backup script.
//
Function ClientBackupParameters() Export
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("ApplicationFileName", StandardSubsystemsClient.ApplicationExecutableFileName());
	ParametersStructure.Insert("EventLogEvent", NStr("vi = 'Sao lưu dự phòng CSTT';
													|ru = 'Резервное копирование ИБ';
													|en = 'Infobase backup'; fa = 'پشتیبان‌گیری پایگاه اطلاعات';
													|it = 'Backup del DB';
													|pl = 'Kopiowanie zapasowe BI';
													|tr = 'Infobase yedek kopyalama'"));
	
	// Call "TempFilesDir" (instead of "GetTempFileName") as the directory shouldn't be deleted when the client app exits. 
	// 
	TempFilesDirForUpdate = TempFilesDir() + "1Cv8Backup." + Format(CommonClient.SessionDate(), "DF=yyMMddHHmmss") + "\";
	ParametersStructure.Insert("TempFilesDirForUpdate", TempFilesDirForUpdate);
	
	Return ParametersStructure;
	
EndFunction

Procedure DontStopScenariosExecution() Export
	
	Shell = New COMObject("Wscript.Shell");
	Shell.RegWrite("HKCU\Software\Microsoft\Internet Explorer\Styles\MaxScriptStatements", 1107296255, "REG_DWORD");

EndProcedure

#EndIf

Function BackupAvailable()
	
#If WebClient Or MobileClient Then
	Return False;
#Else
	Return CommonClient.IsWindowsClient();
#EndIf
	
EndFunction

// Returns:
//  Structure:
//    * BinDir - String
//    * ApplicationFileName - String
//    * EventLogEvent - String
//    * COMConnectorName - String
//    * IsBaseConfigurationVersion - String
//    * ScriptParameters - String
//    * OneCEnterpriseStartupParameters - String
//
Function GeneralScriptParameters() Export
	
	ScriptParameters = New Structure;
	ScriptParameters.Insert("BinDir"            , "");
	ScriptParameters.Insert("ApplicationFileName"           , "");
	ScriptParameters.Insert("EventLogEvent"   , "");
	ScriptParameters.Insert("COMConnectorName"           , "");
	ScriptParameters.Insert("IsBaseConfigurationVersion", "");
	ScriptParameters.Insert("ScriptParameters"            , "");
	ScriptParameters.Insert("OneCEnterpriseStartupParameters" , "");
	ScriptParameters.Insert("COMConnectorPath"         , "");
	Return ScriptParameters;
	
EndFunction	

#EndRegion
