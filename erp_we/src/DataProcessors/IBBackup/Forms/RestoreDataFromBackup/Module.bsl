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
	
	If Not Common.IsWindowsClient() Then
		Raise NStr("vi = 'Cần tùy chỉnh bản sao dự phòng và phục hồi dữ liệu bằng các công cụ của hệ điều hành hoặc các công cụ của bên khác.';
					|ru = 'Резервное копирование и восстановление данных необходимо настроить средствами операционной системы или другими сторонними средствами.';
					|en = 'Set up data backup and restore using operating system tools or other third-party tools.'; fa = 'Set up data backup and restore using operating system tools or other third-party tools.';
					|it = 'Il backup e il recupero dei dati devono essere configurati tramite gli strumenti del sistema operativo o altri strumenti esterni.';
					|pl = 'Tworzenie kopii zapasowych i odzyskiwanie danych muszą być konfigurowane za pomocą systemu operacyjnego lub innych narzędzi stron trzecich.';
					|tr = 'Veri yedekleme ve geri yükleme, işletim sistemin araçları veya diğer üçüncü taraf araçları tarafından yapılandırılmalıdır.'");
	EndIf;
	
	If Common.IsWebClient()
		Or Common.IsMobileClient() Then
		Raise NStr("vi = 'Sao lưu không có sẵn trong máy khách web và máy khách di động.';
					|ru = 'Резервное копирование недоступно в веб-клиенте и мобильном клиенте.';
					|en = 'Web client and mobile client do not support data backup.'; fa = 'Web client and mobile client do not support data backup.';
					|it = 'Il backup non è accessibile nel web-client e nel mobile client.';
					|pl = 'Kopia zapasowa nie jest dostępna w kliencie web i kliencie mobilnym.';
					|tr = 'Yedekleme, web istemcisinde ve mobil istemcide mevcut değildir.'");
	EndIf;
	
	If Not Common.FileInfobase() Then
		Raise NStr("vi = 'Theo phương án làm việc Client server, cần thực hiện sao lưu dự phòng bằng các công cụ khác (công cụ của hệ thống quản trị CSDL).';
					|ru = 'В клиент-серверном варианте работы резервное копирование следует выполнять сторонними средствами (средствами СУБД).';
					|en = 'In the client/server mode, you must back up data by the means of the DBMS.'; fa = 'In the client/server mode, you must back up data by the means of the DBMS.';
					|it = 'Nella versione client-server del lavoro, il backup deve essere eseguito da strumenti esterni (strumenti DBMS).';
					|pl = 'W wersji roboczej klient-serwer tworzenie kopii zapasowych powinno być wykonywane przez narzędzia innych firm (narzędzia SZBD).';
					|tr = 'İstemci / sunucu modunda harici araçları (DBMS araçları) kullanarak verileri yedekleyin.'");
	EndIf;
	
	BackupSettings1 = IBBackupServer.BackupSettings1();
	IBAdministratorPassword = BackupSettings1.IBAdministratorPassword;
	Object.BackupDirectory = BackupSettings1.BackupStorageDirectory;
	
	If InfobaseSessionsCount() > 1 Then
		Items.RecoveryStatusPages.CurrentPage = Items.ActiveUsersPage;
	EndIf;
	
	UserInformation = IBBackupServer.UserInformation();
	PasswordRequired = UserInformation.PasswordRequired;
	If PasswordRequired Then
		IBAdministrator = UserInformation.Name;
	Else
		Items.AuthorizationGroup.Visible = False;
		IBAdministratorPassword = "";
	EndIf;
	
	Items.DonTWaitForSessionsToEnd.Visible = Common.DebugMode();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
#If WebClient Then
	Items.ComcntrGroupFileMode.Visible = False;
#EndIf
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	CurrentPage = Items.DataImportPages.CurrentPage;
	If CurrentPage <> Items.DataImportPages.ChildItems.InformationAndBackupCreationPage Then
		Return;
	EndIf;
	
	WarningText = NStr("vi = 'Ngừng chuẩn bị phục hồi dữ liệu?';
						|ru = 'Прервать подготовку к восстановлению данных?';
						|en = 'Do you want to cancel data restore preparations?'; fa = 'Do you want to cancel data restore preparations?';
						|it = 'Interrompere la preparazione al recupero dei dati?';
						|pl = 'Przerwać przygotowanie do odzyskiwania danych?';
						|tr = 'Verileri geri yüklemek için hazırlanmaktan vazgeçmek istiyor musunuz?'");
	CommonClient.ShowArbitraryFormClosingConfirmation(ThisObject,
		Cancel, Exit, WarningText, "ForceCloseForm");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(False);
	IBConnectionsClient.SetUserTerminationInProgressFlag(False);
	IBConnectionsServerCall.AllowUserAuthorization();
	
	DetachIdleHandler("Timeout2");
	DetachIdleHandler("CheckForSingleConnection");
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "UsersSessions" And Parameter.SessionCount <= 1
		And Items.DataImportPages.CurrentPage = Items.InformationAndBackupCreationPage Then
			StartDataRecovery();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PathToBackupDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectBackupFile();
	
EndProcedure

&AtClient
Procedure UsersListClick(Item)
	
	StandardSubsystemsClient.OpenActiveUserList(, ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateComponentVersionLabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	CommonClient.RegisterCOMConnector();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FormCancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure Done(Command)
	
	ClearMessages();
	
	If Not CheckAttributesFilling() Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("FinishAfterCheckInfobaseAccess", ThisObject);
	
	IBBackupClient.CheckAccessToInfobase(IBAdministratorPassword, Notification);
	
EndProcedure

&AtClient
Procedure DonTWaitForSessionsToEnd(Command)
	StartDataRecovery();
EndProcedure

&AtClient
Procedure GoToEventLog(Command)
	OpenForm("DataProcessor.EventLog.Form.EventLog", , ThisObject);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FinishAfterCheckInfobaseAccess(ConnectionResult, Context) Export
	
	If ConnectionResult.AddInAttachmentError Then
		Items.RecoveryStatusPages.CurrentPage = Items.ConnectionErrorPage;
		ConnectionErrorFound = ConnectionResult.BriefErrorDetails;
		Return;
	EndIf;
	
	SetBackupParemeters();
	
	Pages = Items.DataImportPages;
	
	Pages.CurrentPage = Items.InformationAndBackupCreationPage; 
	Items.Close.Enabled = True;
	Items.Done.Enabled = False;
	
	InfobaseSessionsCount = CheckForBlockingSessions();
	
	IBConnectionsServerCall.SetConnectionLock(
		NStr("vi = 'Đang thực hiện phục hồi cơ sở thông tin.';
			|ru = 'Выполняется восстановление информационной базы.';
			|en = 'Restoring the infobase…'; fa = 'Restoring the infobase…';
			|it = 'Il ripristino del database informatico è in esecuzione.';
			|pl = 'Baza informacji jest przywracana.';
			|tr = 'Infobase kurtarma işlemi devam ediyor.'"),
		"Backup");
	
	If InfobaseSessionsCount = 1 Then
		IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(True);
		IBConnectionsClient.SetUserTerminationInProgressFlag(True);
		StartDataRecovery();
	Else
		IBConnectionsClient.SetTheUserShutdownMode(True);
		SetIdleIdleHandlerOfBackupStart();
		SetIdleHandlerOfBackupTimeout();
	EndIf;
	
EndProcedure

&AtServer
Function CheckForBlockingSessions()
	
	InfobaseSessionsCount = InfobaseSessionsCount();
	Items.ActiveUserCount.Title = InfobaseSessionsCount;
	
	BlockingSessionsInformation = IBConnections.BlockingSessionsInformation("");
	HasBlockingSessions = BlockingSessionsInformation.HasBlockingSessions;
	
	If HasBlockingSessions Then
		Items.ActiveSessionsDecoration.Title = BlockingSessionsInformation.MessageText;
	EndIf;
	
	Items.ActiveSessionsDecoration.Visible = HasBlockingSessions;
	Return InfobaseSessionsCount;
	
EndFunction

&AtClient
Procedure SetIdleHandlerOfBackupTimeout()
	
	AttachIdleHandler("Timeout2", 600, True);
	
EndProcedure

&AtClient
Procedure SetIdleIdleHandlerOfBackupStart() 
	
	AttachIdleHandler("CheckForSingleConnection", 5);
	
EndProcedure

&AtClient
Procedure SelectBackupFile()
	
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.Filter = NStr("vi = 'Bản sao dự phòng của cơ sở (*.zip, *.1CD)|*.zip;*.1cd';
								|ru = 'Резервная копия базы (*.zip, *.1CD)|*.zip;*.1cd';
								|en = 'Infobase backup (*.zip, *.1CD)|*.zip;*.1cd'; fa = 'Infobase backup (*.zip, *.1CD)|*.zip;*.1cd';
								|it = 'Database di backup (*.zip, *.1CD)|*.zip;*.1cd';
								|pl = 'Kopia zapasowa bazy danych (*.zip, *.1CD)|*.zip;*.1cd';
								|tr = 'Infobase yedeklemesi (*.zip, *.1CD)|*.zip;*.1cd'");
	OpenFileDialog.Title= NStr("vi = 'Hãy chọn tệp sao lưu dự phòng';
								|ru = 'Выберите файл резервной копии';
								|en = 'Select a backup file'; fa = 'Select a backup file';
								|it = 'Selezionare il file di backup';
								|pl = 'Wybierz plik kopii zapasowej';
								|tr = 'Bir yedekleme dosyası seçin'");
	OpenFileDialog.CheckFileExistence = True;
	
	If OpenFileDialog.Choose() Then
		
		Object.BackupImportFile = OpenFileDialog.FullFileName;
		
	EndIf;
	
EndProcedure

&AtClient
Function CheckAttributesFilling()
	
#If WebClient Or MobileClient Then
	MessageText = NStr("vi = 'Phục hồi không có sẵn trong máy khách web và máy khách di động.';
						|ru = 'Восстановление не доступно в веб-клиенте и мобильном клиенте.';
						|en = 'Web client and mobile client do not support data backup.'; fa = 'Web client and mobile client do not support data backup.';
						|it = 'Il ripristino non è disponbile nel web-client e nel mobile client.';
						|pl = 'Odzyskiwanie nie jest dostępne w kliencie web i kliencie mobilnym.';
						|tr = 'Kurtarma, web istemcisinde ve mobil istemcide mevcut değildir.'");
	CommonClient.MessageToUser(MessageText);
	Return False;
#Else
	
	If PasswordRequired And IsBlankString(IBAdministratorPassword) Then
		MessageText = NStr("vi = 'Chưa xác định mật khẩu quản trị.';
							|ru = 'Не задан пароль администратора.';
							|en = 'Administrator password is not set.'; fa = 'Administrator password is not set.';
							|it = 'Nessuna password di amministratore è stata impostata.';
							|pl = 'Nie ustawiono hasła administratora.';
							|tr = 'Yönetici şifresi belirtilmemiş.'");
		CommonClient.MessageToUser(MessageText,, "IBAdministratorPassword");
		Return False;
	EndIf;
	
	Object.BackupImportFile = TrimAll(Object.BackupImportFile);
	FileName = TrimAll(Object.BackupImportFile);
	
	If IsBlankString(FileName) Then
		MessageText = NStr("vi = 'Chưa chọn tệp có bản sao dự phòng.';
							|ru = 'Не выбран файл с резервной копией.';
							|en = 'Backup file is not provided.'; fa = 'Backup file is not provided.';
							|it = 'Nessun file di backup selezionato.';
							|pl = 'Nie wybrano pliku kopii zapasowej.';
							|tr = 'Yedekleme dosyası seçilmedi.'");
		CommonClient.MessageToUser(MessageText,, "Object.BackupImportFile");
		Return False;
	EndIf;
	
	ArchiveFile1 = New File(FileName);
	If Upper(ArchiveFile1.Extension) <> ".ZIP" And Upper(ArchiveFile1.Extension) <> ".1CD"  Then
		
		MessageText = NStr("vi = 'Tệp đã chọn không phải là tệp lưu trữ có bản sao dự phòng.';
							|ru = 'Выбранный файл не является архивом с резервной копией.';
							|en = 'The selected file is not a backup file.'; fa = 'The selected file is not a backup file.';
							|it = 'Il file selezionato non è un archivio con la copia di backup.';
							|pl = 'Wybrany plik nie jest archiwum kopii zapasowej.';
							|tr = 'Seçilen dosya yedek kopyası olan bir arşiv değildir.'");
		CommonClient.MessageToUser(MessageText,, "Object.BackupImportFile");
		Return False;
		
	EndIf;
	
	If Upper(ArchiveFile1.Extension) = ".1CD" Then
		
		If Upper(ArchiveFile1.BaseName) <> "1CV8" Then
			MessageText = NStr("vi = 'Tệp đã chọn không phải là bản sao dự phòng (sai tên tệp cơ sở thông tin).';
								|ru = 'Выбранный файл не является резервной копией (неправильное имя файла информационной базы).';
								|en = 'The selected file is not a valid backup file for this infobase. It contains another infobase name.'; fa = 'The selected file is not a valid backup file for this infobase. It contains another infobase name.';
								|it = 'Il file selezionato non è una copia di backup (nome del file di database informatico è scorretto).';
								|pl = 'Wybrany plik nie jest kopią zapasową (niepoprawna nazwa pliku bazy informacyjnej).';
								|tr = 'Seçilen dosya yedekleme değil (Infobase dosyasının adı yanlış).'");
			CommonClient.MessageToUser(MessageText,, "Object.BackupImportFile");
			Return False;
		EndIf;
		
	Else 
		
		Try
			ZipFile = New ZipFileReader(FileName);
		Except
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
					"vi = 'Tệp nén chứa bản sao dự phòng được chọn đã bị hỏng hoặc không phải là tệp nén (%1).';
					|ru = 'Выбранный файл архива с резервной копией поврежден или не является архивом (%1).';
					|en = 'The selected archive file with a backup is damaged or is not a ZIP archive (%1).'; fa = 'The selected archive file with a backup is damaged or is not a ZIP archive (%1).';
					|it = 'Выбранный файл архива с резервной копией поврежден или не является архивом (%1).';
					|pl = 'The selected archive file with a backup is damaged or is not a ZIP archive (%1).';
					|tr = 'Seçili yedekleme arşivi dosyası bozulmuş veya bir arşiv değil (%1).'"),
					ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			CommonClient.MessageToUser(MessageText,, "Object.BackupImportFile");
			Return False;
		EndTry;
		
		If ZipFile.Items.Count() <> 1 Then
			
			MessageText = NStr("vi = 'Tệp đã chọn không phải là tệp lưu trữ có bản sao dự phòng (có nhiều hơn một tệp).';
								|ru = 'Выбранный файл не является архивом с резервной копией (содержит более одного файла).';
								|en = 'The selected file is not a valid backup file. It contains more than one file.'; fa = 'The selected file is not a valid backup file. It contains more than one file.';
								|it = 'Il file selezionato non è un archivio con la copia di backup (contiene più di un file).';
								|pl = 'Wybrany plik nie jest archiwum kopii zapasowej (zawiera więcej niż jeden plik).';
								|tr = 'Seçilen dosya yedek kopyası olan bir arşiv değildir (birden fazla dosya içerir).'");
			CommonClient.MessageToUser(MessageText,, "Object.BackupImportFile");
			Return False;
			
		EndIf;
		
		FileInArchive = ZipFile.Items[0];
		
		If Upper(FileInArchive.Extension) <> "1CD" Then
			
			MessageText = NStr("vi = 'Tệp đã chọn không phải là tệp lưu trữ có bản sao dự phòng (không có tệp cơ sở thông tin).';
								|ru = 'Выбранный файл не является архивом с резервной копией (не содержит файл информационной базы).';
								|en = 'The selected file is not a valid backup file. It does not contain any infobase.'; fa = 'The selected file is not a valid backup file. It does not contain any infobase.';
								|it = 'Il file selezionato non è un archivio con la copia di backup (non contiene il file del database informatico).';
								|pl = 'Wybrany plik nie jest archiwum kopii zapasowej (nie zawiera pliku bazy informacyjnej).';
								|tr = 'Seçilen dosya yedek kopyası olan bir arşiv değildir (Infobase dosyasını içermez).'");
			CommonClient.MessageToUser(MessageText,, "Object.BackupImportFile");
			Return False;
			
		EndIf;
		
		If Upper(FileInArchive.BaseName) <> "1CV8" Then
			
			MessageText = NStr("vi = 'Tệp đã chọn không phải là tệp lưu trữ có bản sao dự phòng (sai tên tệp cơ sở thông tin).';
								|ru = 'Выбранный файл не является архивом с резервной копией (неправильное имя файла информационной базы).';
								|en = 'The selected file is not a valid backup file. The infobase name is not correct.'; fa = 'The selected file is not a valid backup file. The infobase name is not correct.';
								|it = 'Il file selezionato non è un archivio con la copia di backup (il nome del file di database informatico non è corretto).';
								|pl = 'Wybrany plik nie jest archiwum kopii zapasowej (nieprawidłowa nazwa pliku bazy informacyjnej).';
								|tr = 'Seçilen dosya yedek kopyası olan bir arşiv değildir (Infobase dosyasının geçersiz adı).'");
			CommonClient.MessageToUser(MessageText,, "Object.BackupImportFile");
			Return False;
			
		EndIf;
		
	EndIf;
	
	Return True;
	
#EndIf
	
EndFunction

#Region IdleHandlersProcedures

&AtClient
Procedure Timeout2()
	
	DetachIdleHandler("CheckForSingleConnection");
	CancelPreparation();
	
EndProcedure

&AtServer
Procedure CancelPreparation()
	
	Items.FailedLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1.
		|Các bước chuẩn bị để khôi phục dữ liệu từ bản sao lưu đã bị hủy. Infobase đã được mở khóa.';
		|ru = '%1.
		|Подготовка к восстановлению данных из резервной копии отменена. Информационная база разблокирована.';
		|en = '%1.
		|Preparation for restoring data is canceled. Infobase is unlocked.'; fa = '%1.
		|Preparation for restoring data is canceled. Infobase is unlocked.';
		|it = '%1.
		|La preparazione per il ripristino dei dati dalla copia di backup è annullata. Il database informatico è sbloccato.';
		|pl = '%1.
		|Przygotowanie do przywrócenia danych z kopii zapasowej jest anulowane. Baza danych odblokowana.';
		|tr = '%1. 
		| Yedekten veri yenilenmesi için hazırlık iptal edildi. Infobase kilitlendi.'"),
		IBConnections.ActiveSessionsMessage());
	Items.DataImportPages.CurrentPage = Items.BackupCreationErrorsPage;
	Items.Done.Visible = False;
	Items.Close.Title = NStr("vi = 'Đóng';
							|ru = 'Закрыть';
							|en = 'Close'; fa = 'بستن';
							|it = 'Chiudere';
							|pl = 'Close';
							|tr = 'Kapat'");
	Items.Close.DefaultButton = True;
	
	IBConnections.AllowUserAuthorization();
	
EndProcedure

&AtClient
Procedure CheckForSingleConnection()
	
	If InfobaseSessionsCount() = 1 Then
		StartDataRecovery();
	EndIf;
	
EndProcedure

&AtClient
Procedure StartDataRecovery() 
	
#If Not WebClient And Not MobileClient Then
	
	IBBackupClient.DontStopScenariosExecution();
	
	MainScriptFileName = GenerateScriptFiles();
	EventLogClient.AddMessageForEventLog(
		IBBackupClient.EventLogEvent(), 
		"Information",
		NStr("vi = 'Đang thực hiện phục hồi dữ liệu cơ sở thông tin:';
			|ru = 'Выполняется восстановление данных информационной базы:';
			|en = 'Restoring the infobase:'; fa = 'Restoring the infobase:';
			|it = 'Il ripristino dei dati del database informatico è in esecuzione:';
			|pl = 'Odtwarzane są informacje z bazy danych:';
			|tr = 'Infobase kurtarma işlemi devam ediyor:'") + " " + MainScriptFileName);
	
	StandardSubsystemsClient.SkipExitConfirmation();
	
	PathToLauncher = StandardSubsystemsClient.SystemApplicationsDirectory() + "mshta.exe";
	
	CommandLine1 = """%1"" ""%2"" [p1]%3[/p1]";
	CommandLine1 = StringFunctionsClientServer.SubstituteParametersToString(
		CommandLine1,
		PathToLauncher, 
		MainScriptFileName, 
		IBBackupClient.StringUnicode(IBAdministratorPassword));
	
	ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
	ApplicationStartupParameters.Notification = New CallbackDescription("AfterStartScript", ThisObject);
	ApplicationStartupParameters.WaitForCompletion = False;
	
	FileSystemClient.StartApplication(CommandLine1, ApplicationStartupParameters);
	
#EndIf
	
EndProcedure

&AtClient
Procedure AfterStartScript(Result, Context) Export
	
	If Result.ApplicationStarted Then
		Terminate();
	Else 
		ShowMessageBox(, Result.ErrorDescription);
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsToPrepareDataRestore

#If Not WebClient And Not MobileClient Then

&AtClient
Function GenerateScriptFiles() 
	
	CopyingParameters = IBBackupClient.ClientBackupParameters();
	CreateDirectory(CopyingParameters.TempFilesDirForUpdate);
	
	ScriptParameters = IBBackupClient.GeneralScriptParameters();
	ScriptParameters.ApplicationFileName = CopyingParameters.ApplicationFileName;
	ScriptParameters.EventLogEvent = CopyingParameters.EventLogEvent;
	ScriptParameters.COMConnectorName = CommonClientServer.COMConnectorName();
	ScriptParameters.COMConnectorPath = BinDir() + "comcntr.dll";
	ScriptParameters.IsBaseConfigurationVersion = StandardSubsystemsClient.IsBaseConfigurationVersion();
	ScriptParameters.ScriptParameters = IBBackupClient.UpdateAdministratorAuthenticationParameters(IBAdministratorPassword);
	ScriptParameters.OneCEnterpriseStartupParameters = CommonInternalClient.EnterpriseStartupParametersFromScript();
	
	Scripts = GenerateScriptsText(ScriptParameters, ApplicationParameters["StandardSubsystems.MessagesForEventLog"]);
	
	// Auxiliary file: helpers.js.
	ScriptFile = New TextDocument;
	ScriptFile.Output = UseOutput.Enable;
	ScriptFile.SetText(Scripts.Script);
	ScriptFileName = CopyingParameters.TempFilesDirForUpdate + "main.js";
	ScriptFile.Write(ScriptFileName, IBBackupClient.IBBackupApplicationFilesEncoding());
	
	// Auxiliary file: helpers.js.
	ScriptFile = New TextDocument;
	ScriptFile.Output = UseOutput.Enable;
	ScriptFile.SetText(Scripts.AddlBackupFile);
	ScriptFile.Write(CopyingParameters.TempFilesDirForUpdate + "helpers.js", IBBackupClient.IBBackupApplicationFilesEncoding());
	
	PictureLib.ExternalOperationSplash.Write(CopyingParameters.TempFilesDirForUpdate + "splash.png");
	PictureLib.ExternalOperationSplashIcon.Write(CopyingParameters.TempFilesDirForUpdate + "splash.ico");
	PictureLib.TimeConsumingOperation48.Write(CopyingParameters.TempFilesDirForUpdate + "progress.gif");
	
	// Main splash file: splash.hta.
	MainScriptFileName = CopyingParameters.TempFilesDirForUpdate + "splash.hta";
	ScriptFile = New TextDocument;
	ScriptFile.Output = UseOutput.Enable;
	ScriptFile.SetText(Scripts.RecoverySplash);
	ScriptFile.Write(MainScriptFileName, IBBackupClient.IBBackupApplicationFilesEncoding());
	
	LogFile1 = New TextDocument;
	LogFile1.Output = UseOutput.Enable;
	LogFile1.SetText(StandardSubsystemsClient.SupportInformation());
	LogFile1.Write(CopyingParameters.TempFilesDirForUpdate + "templog.txt", TextEncoding.System);
	
	Return MainScriptFileName;
	
EndFunction

#EndIf

&AtServer
Function GenerateScriptsText(ScriptParameters, MessagesForEventLog)
	
	EventLog.WriteEventsToEventLog(MessagesForEventLog);
	
	Result = New Structure("Script, AddlBackupFile, RecoverySplash");
	Result.Script = GenerateScriptText(ScriptParameters);
	Result.AddlBackupFile = DataProcessors.IBBackup.GetTemplate("AddlBackupFile").GetText();
	Result.RecoverySplash = GenerateSplashText();
	Return Result;
	
EndFunction

&AtServer
Function GenerateScriptText(ScriptParameters)
	
	// Configuration update file: main.js.
	ScriptTemplate = DataProcessors.IBBackup.GetTemplate("LoadIBFileTemplate");
	
	Script = ScriptTemplate.GetArea("ParametersArea");
	Script.DeleteLine(1);
	Script.DeleteLine(Script.LineCount());
	If StrStartsWith(Script.GetLine(Script.LineCount()), "#") Then
		Script.DeleteLine(Script.LineCount());
	EndIf;
	
	Text = ScriptTemplate.GetArea("BackupArea");
	Text.DeleteLine(1);
	Text.DeleteLine(Text.LineCount());
	
	Return InsertScriptParameters(Script.GetText(), ScriptParameters)
		+ InsertScriptParameters(Text.GetText(), ScriptParameters);
	
EndFunction

&AtServer
Function InsertScriptParameters(Val Text, Val ScriptParameters)
	
	TextParameters = IBBackupServer.PrepareCommonScriptParameters(ScriptParameters);
	TextParameters["[BackupFile]"] = IBBackupServer.PrepareText(Object.BackupImportFile);
	// ACC:495-off - TempFilesDir is used because temporary directories cannot be deleted automatically.
	TextParameters["[TempFilesDir]"] = IBBackupServer.PrepareText(TempFilesDir()); 
	// ACC:495-on
	Return IBBackupServer.SubstituteParametersToText(Text, TextParameters);
	
EndFunction

&AtServer
Function GenerateSplashText()
	
	TextTemplate1 = DataProcessors.IBBackup.GetTemplate("RecoverySplash").GetText();
	
	TextParameters = New Map;
	TextParameters["[SplashTitle]"] = NStr("vi = 'Khôi phục dữ liệu từ bản sao lưu ...';
											|ru = 'Восстановление данных из резервной копии...';
											|en = 'Restoring data from backup…'; fa = 'Restoring data from backup…';
											|it = 'Ripristino dati dal backup...';
											|pl = 'Odzyskiwanie danych z kopii zapasowej...';
											|tr = 'Yedeklemeden verileri geri yükle...'");
	TextParameters["[SplashText]"] = 
		NStr("vi = 'Vui lòng đợi.
			|<br /> Đang khôi phục cơ sở dữ liệu
			|<br /> từ bản sao lưu.
			|<br /> Không nên dừng quá trình.';
			|ru = 'Пожалуйста, подождите.
			|<br /> Выполняется восстановление базы данных
			|<br /> из резервной копии.
			|<br /> Не рекомендуется останавливать процесс.';
			|en = 'Please wait.
			|<br /> Restoring the database 
			|<br /> from a backup.
			|<br /> It is recommended that you do not interrupt this operation.'; fa = 'Please wait.
			|<br /> Restoring the database 
			|<br /> from a backup.
			|<br /> It is recommended that you do not interrupt this operation.';
			|it = 'Пожалуйста, подождите.
			|<br /> Выполняется восстановление базы данных
			|<br /> из резервной копии.
			|<br /> Не рекомендуется останавливать процесс.';
			|pl = 'Please wait.
			|<br /> Restoring the database 
			|<br /> from a backup.
			|<br /> It is recommended that you do not interrupt this operation.';
			|tr = 'Lütfen bekle. 
			|<br /> Veritabanı yedekten geri yükleniyor
			|<br />. 
			|<br /> İşlemin durdurulması önerilmez.'");
	
	TextParameters["[Step1Initialization]"] = NStr("vi = 'Khởi tạo';
													|ru = 'Инициализация';
													|en = 'Initializing'; fa = 'Initializing';
													|it = 'Inizializzazione';
													|pl = 'Initializing';
													|tr = 'Başlatma'");
	TextParameters["[Step2DataRecovery]"] = NStr("vi = 'Phục hồi dữ liệu';
												|ru = 'Восстановление данных';
												|en = 'Restoring data'; fa = 'Restoring data';
												|it = 'Ripristino dati';
												|pl = 'Przywrócenie danych';
												|tr = 'Veri kurtarma'");
	TextParameters["[Step3AwaitingCompletion]"] = NStr("vi = 'Chờ phục hồi dữ liệu hoàn tất';
														|ru = 'Ожидание завершения восстановления данных';
														|en = 'Waiting for data restore to complete'; fa = 'Waiting for data restore to complete';
														|it = 'Attesa del completamento di ripristino dati';
														|pl = 'Oczekiwanie na zakończenie przywrócenia danych';
														|tr = 'Veri kurtarma işleminin tamamlanması bekleniyor'");
	TextParameters["[Step4AllowConnections]"] = NStr("vi = 'Cho phép kết nối kết nối mới';
													|ru = 'Разрешение подключений новых соединений';
													|en = 'Allowing new connections'; fa = 'Allowing new connections';
													|it = 'Autorizzazione nuove connessioni';
													|pl = 'Zezwolenie podłączeń nowych połączeń';
													|tr = 'Yeni bağlantıların bağlanmasına izin verme'");
	TextParameters["[Step5Completion]"] = NStr("vi = 'Kết thúc';
												|ru = 'Завершение';
												|en = 'Completing'; fa = 'Completing';
												|it = 'Completamento';
												|pl = 'Completing';
												|tr = 'Bitiş'");
	TextParameters["[ProcessIsAborted]"] = NStr("vi = 'Chú ý: quá trình khôi phục dữ liệu bị gián đoạn và CSTT vẫn bị chặn.';
												|ru = 'Внимание: процесс восстановления данных был прерван, и информационная база осталась заблокированной.';
												|en = 'Warning! The data restore was interrupted and the infobase is still locked.'; fa = 'Warning! The data restore was interrupted and the infobase is still locked.';
												|it = 'Attenzione: il ripristino dati è stato interrotto e il database è bloccato.';
												|pl = 'Uwaga: proces przywrócenia danych został przerwany i baza informacyjna pozostała zablokowana.';
												|tr = 'Dikkat: veri kurtarma işlemi kesintiye uğradı ve infobase kilitli kaldı.'");
	TextParameters["[AbortedTooltip]"] = NStr("vi = 'Để bỏ chặn CSTT, hãy sử dụng bảng điều khiển cụm máy chủ hoặc chạy 1C: Enterprise.';
												|ru = 'Для разблокирования информационной базы воспользуйтесь консолью кластера серверов или запустите ""1С:Предприятие"".';
												|en = 'To unlock the infobase, use the server cluster console or run 1C:Enterprise.'; fa = 'To unlock the infobase, use the server cluster console or run 1C:Enterprise.';
												|it = 'Per sbloccare il database usate la console del cluster dei server o avviate ""1C:Enterprise"".';
												|pl = 'Do rozblokowania bazy informacyjnej skorzystaj z konsoli klastera serwrów lub uruchom ""1С:Enterprise"".';
												|tr = 'Infobase kilidini açmak için sunucu kümesi konsolunu kullanın veya 1C:Enterprise''ı çalıştırın.'");
	
	IBBackupServer.SetTheGeneralParametersOfTheScreenSaver(TextParameters);
	
	Return IBBackupServer.SubstituteParametersToText(TextTemplate1, TextParameters);
	
EndFunction

&AtServer
Procedure SetBackupParemeters()
	
	BackupParameters = IBBackupServer.BackupSettings1();
	
	BackupParameters.Insert("IBAdministrator", IBAdministrator);
	BackupParameters.Insert("IBAdministratorPassword", ?(PasswordRequired, IBAdministratorPassword, ""));
	
	IBBackupServer.SetBackupSettings(BackupParameters);
	
EndProcedure

&AtServerNoContext
Function InfobaseSessionsCount()
	
	Return IBConnections.InfobaseSessionsCount(False, False);
	
EndFunction

#EndRegion

#EndRegion