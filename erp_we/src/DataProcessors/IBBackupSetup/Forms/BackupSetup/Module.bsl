///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var WriteSettings, NextDate;

#EndRegion

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
	
	If Common.IsWebClient() Then
		Raise NStr("vi = 'Không cho phép sao lưu dự phòng tại Web-client.';
					|ru = 'Резервное копирование недоступно в веб-клиенте.';
					|en = 'Web client does not support data backup.'; fa = 'Web client does not support data backup.';
					|it = 'Il backup non è disponibile in web-client.';
					|pl = 'Kopia zapasowa nie jest dostępna w kliencie Web.';
					|tr = 'Yedekleme web istemcisinde mevcut değildir.'");
	EndIf;
	
	BackupSettings1 = IBBackupServer.BackupSettings1();
	
	Object.ExecutionOption = BackupSettings1.ExecutionOption;
	Object.CreateBackupAutomatically = BackupSettings1.CreateBackupAutomatically;
	Object.BackupConfigured = BackupSettings1.BackupConfigured;
	
	If Not Object.BackupConfigured Then
		Object.CreateBackupAutomatically = True;
	EndIf;
	IsBaseConfigurationVersion = StandardSubsystemsServer.IsBaseConfigurationVersion();
	Items.Normal.Visible = Not IsBaseConfigurationVersion;
	Items.Basic.Visible = IsBaseConfigurationVersion;
	
	IBAdministratorPassword = BackupSettings1.IBAdministratorPassword;
	Schedule = CommonClientServer.StructureToSchedule(BackupSettings1.CopyingSchedule);
	Items.ModifySchedule.Title = String(Schedule);
	Object.BackupDirectory = BackupSettings1.BackupStorageDirectory;
	
	// Filling settings for storing old copies.
	
	FillPropertyValues(Object, BackupSettings1.DeletionParameters);
	
	UpdateBackupDirectoryRestrictionType(ThisObject);
	
	UserInformation = IBBackupServer.UserInformation();
	PasswordRequired = UserInformation.PasswordRequired;
	If PasswordRequired Then
		IBAdministrator = UserInformation.Name;
	Else
		Items.AuthorizationGroup.Visible = False;
		Items.InfobaseAdministratorAuthorization.Visible = False;
		IBAdministratorPassword = "";
	EndIf;
	
	SetVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Settings = ApplicationParameters["StandardSubsystems.IBBackupParameters"];
	If Settings = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	NextDate = Settings.MinDateOfNextAutomaticBackup;
	Settings.MinDateOfNextAutomaticBackup = '29990101';
	WriteSettings = False;
	
	
#If WebClient Then
	Items.UpdateComponentVersionLabel.Visible = False;
#EndIf
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If WriteSettings Then
		ParameterName = "IBBackupOnExit";
		ParametersOnExit = New Structure(StandardSubsystemsClient.ClientParameter(ParameterName));
		ParametersOnExit.ExecuteOnExit1 = Object.CreateBackupAutomatically
			And Object.ExecutionOption = "OnExit";
		ParametersOnExit = New FixedStructure(ParametersOnExit);
		StandardSubsystemsClient.SetClientParameter(ParameterName, ParametersOnExit);
	Else
		Settings = ApplicationParameters["StandardSubsystems.IBBackupParameters"];
		Settings.MinDateOfNextAutomaticBackup = NextDate;
	EndIf;
	
	If Exit Then
		Return;
	EndIf;
	
	Notify("BackupSettingsFormClosed");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CreateBackupAutomaticallyOnChange(Item)
	
	SetVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure BackupDirectoryRestrictionTypeOnChange(Item)
	
	
	UpdateBackupDirectoryRestrictionType(ThisObject);
	
EndProcedure

&AtClient
Procedure PathToBackupDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	OpenFileDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	OpenFileDialog.Title= NStr("vi = 'Hãy chọn thư mục để lưu bản sao dự phòng';
								|ru = 'Выберите каталог для сохранения резервных копий';
								|en = 'Choose a directory to save backups to'; fa = 'Choose a directory to save backups to';
								|it = 'Selezionare una directory per salvare i backup';
								|pl = 'Wybierz katalog dla kopii zapasowych';
								|tr = 'Yedeklerin kaydedileceği klasörü seç'");
	OpenFileDialog.Directory = Items.PathToBackupDirectory.EditText;
	
	If OpenFileDialog.Choose() Then
		Object.BackupDirectory = OpenFileDialog.Directory;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToEventLogLabelClick(Item)
	OpenForm("DataProcessor.EventLog.Form.EventLog", , ThisObject);
EndProcedure

&AtClient
Procedure BackupOptionOnChange(Item)
	
	Items.ModifySchedule.Enabled = (Object.ExecutionOption = "Schedule3");
	
EndProcedure

&AtClient
Procedure BackupRetentionPeriodUnitOfMeasurementClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure UpdateComponentVersionLabelURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	CommonClient.RegisterCOMConnector();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	WriteSettings = True;
	GoFromSettingPage();
	
EndProcedure

&AtClient
Procedure ModifySchedule(Command)
	
	ScheduleDialog1 = New ScheduledJobDialog(Schedule);
	CallbackDescription = New CallbackDescription("ModifyScheduleCompletion", ThisObject);
	ScheduleDialog1.Show(CallbackDescription);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GoFromSettingPage()
	
	Settings = ApplicationParameters["StandardSubsystems.IBBackupParameters"];
	CurrentUser = UsersClient.CurrentUser();
	
	If Object.CreateBackupAutomatically Then
		
		If Not CheckDirectoryWithBackups() Then
			Return;
		EndIf;
		
		Context = New Structure;
		Context.Insert("IBBackupParameters", Settings);
		Context.Insert("CurrentUser", CurrentUser);
		
		Notification = New CallbackDescription(
			"NavigateFromSettingPageAfterCheckAccessToInfobase", ThisObject, Context);
		
		IBBackupClient.CheckAccessToInfobase(IBAdministratorPassword, Notification);
		Return;
	EndIf;
		
	StopNotificationService(CurrentUser);
	IBBackupClient.DisableBackupIdleHandler();
	Settings.MinDateOfNextAutomaticBackup = '29990101';
	Settings.NotificationParameter1 = "DontNotify";
	
	RefreshReusableValues();
	Close();
	
EndProcedure

&AtClient
Procedure NavigateFromSettingPageAfterCheckAccessToInfobase(ConnectionResult, Context) Export
	
	IBBackupParameters = Context.IBBackupParameters;
	CurrentUser = Context.CurrentUser;
	
	If ConnectionResult.AddInAttachmentError Then
		Items.WizardPages.CurrentPage = Items.AdditionalSettings;
		ConnectionErrorFound = ConnectionResult.BriefErrorDetails;
		Return;
	EndIf;
	
	WriteSettings(CurrentUser);
	
	If Object.ExecutionOption = "Schedule3" Then
		CurrentDate = CommonClient.SessionDate();
		IBBackupParameters.MinDateOfNextAutomaticBackup = CurrentDate;
		IBBackupParameters.LatestBackupDate = CurrentDate;
		IBBackupParameters.ScheduleValue1 = Schedule;
	ElsIf Object.ExecutionOption = "OnExit" Then
		IBBackupParameters.MinDateOfNextAutomaticBackup = '29990101';
	EndIf;
	
	IBBackupClient.AttachIdleBackupHandler();
	
	SettingsFormName = "e1cib/app/DataProcessor.IBBackupSetup/";
	
	ShowUserNotification(NStr("vi = 'Sao lưu dự phòng';
								|ru = 'Резервное копирование';
								|en = 'Backup'; fa = 'پشتیبان‌گیری';
								|it = 'Backup';
								|pl = 'Kopiowanie zapasowe';
								|tr = 'Yedek kopyalama'"), SettingsFormName,
		NStr("vi = 'Đã tùy chỉnh sao lưu dự phòng.';
			|ru = 'Резервное копирование настроено.';
			|en = 'Backup is all set up.'; fa = 'Backup is all set up.';
			|it = 'Il backup è configurato.';
			|pl = 'Kopiowanie zapasowe ustawione.';
			|tr = 'Yedek kopyalama ayarlandı.'"));
	
	IBBackupParameters.NotificationParameter1 = "DontNotify";
	
	RefreshReusableValues();
	Close();
	
EndProcedure

&AtClient
Function CheckDirectoryWithBackups()
	
#If WebClient Or MobileClient Then
	MessageText = NStr("vi = 'Thao tác không khả dụng trong web-client hoặc trong mobile-client.
		|Hãy khởi động thin client.';
		|ru = 'Действие недоступно в веб-клиенте или в мобильном клиенте.
		|Запустите тонкий клиент.';
		|en = 'Cannot perform the operation in web client or mobile client.
		|Start thin client.'; fa = 'Cannot perform the operation in web client or mobile client.
		|Start thin client.';
		|it = 'L''azione non è disponibile nel web client o nel client mobile.
		|Avviare thin client.';
		|pl = 'Działanie jest niedostępne w kliencie webowym lub kliencie mobilnym.
		|Uruchom klient cienki.';
		|tr = 'Eylem, web veya mobil istemcide mevcut değil. 
		|İnce istemciyi başlatın.'");
	CommonClient.MessageToUser(MessageText);
	AttributesFilled = False;
#Else
	AttributesFilled = True;
	
	If IsBlankString(Object.BackupDirectory) Then
		
		MessageText = NStr("vi = 'Không có thư mục nào được chọn để sao lưu.';
							|ru = 'Не выбрана папка для резервной копии.';
							|en = 'Select a folder for backup.'; fa = 'Select a folder for backup.';
							|it = 'Cartella non selezionata per la copia di riserva.';
							|pl = 'Nie wybrano foldera dla kopii zapasowej.';
							|tr = 'Yedekleme klasörü seçilmedi.'");
		CommonClient.MessageToUser(MessageText,, "Object.BackupDirectory");
		AttributesFilled = False;
		
	ElsIf FindFiles(Object.BackupDirectory).Count() = 0 Then
		
		MessageText = NStr("vi = 'Một thư mục không tồn tại đã được chỉ định.';
							|ru = 'Указана несуществующая папка.';
							|en = 'Non-existent folder is specified.'; fa = 'Non-existent folder is specified.';
							|it = 'La cartella indicata non esiste.';
							|pl = 'Jest wskazany nie istniejący folder.';
							|tr = 'Var olmayan bir klasör belirtildi.'");
		CommonClient.MessageToUser(MessageText,, "Object.BackupDirectory");
		AttributesFilled = False;
		
	Else
		
		Try
			TestFile = New XMLWriter;
			TestFile.OpenFile(Object.BackupDirectory + "/test.test1From1");
			TestFile.WriteXMLDeclaration();
			TestFile.Close();
		Except
			MessageText = NStr("vi = 'Không có quyền truy cập vào thư mục có bản sao lưu.';
								|ru = 'Нет доступа к папке с резервными копиями.';
								|en = 'Cannot access the backup folder.'; fa = 'Cannot access the backup folder.';
								|it = 'Impossibile accedere alla cartella con le copie di riserva.';
								|pl = 'Brak dostępu z kopiami rezerwowymi.';
								|tr = 'Yedekleme klasörüne erişim yok.'");
			CommonClient.MessageToUser(MessageText,, "Object.BackupDirectory");
			AttributesFilled = False;
		EndTry;
		
		If AttributesFilled Then
			
			Try
				DeleteFiles(Object.BackupDirectory, "*.test1From1");
			Except
				// ACC:280 Not an error if files are not deleted at this step.
			EndTry;
			
		EndIf;
		
	EndIf;
	
	If PasswordRequired And IsBlankString(IBAdministratorPassword) Then
		
		MessageText = NStr("vi = 'Chưa xác định mật khẩu quản trị.';
							|ru = 'Не задан пароль администратора.';
							|en = 'Administrator password is not set.'; fa = 'Administrator password is not set.';
							|it = 'Nessuna password di amministratore è stata impostata.';
							|pl = 'Nie ustawiono hasła administratora.';
							|tr = 'Yönetici şifresi belirtilmemiş.'");
		CommonClient.MessageToUser(MessageText,, "IBAdministratorPassword");
		AttributesFilled = False;
		
	EndIf;

#EndIf
	
	Return AttributesFilled;
	
EndFunction

&AtServerNoContext
Procedure StopNotificationService(CurrentUser)
	// Stops notifications of backup.
	BackupSettings1 = IBBackupServer.BackupSettings1();
	BackupSettings1.CreateBackupAutomatically = False;
	BackupSettings1.BackupConfigured = True;
	BackupSettings1.MinDateOfNextAutomaticBackup = '29990101';
	IBBackupServer.SetBackupSettings(BackupSettings1, CurrentUser);
EndProcedure

&AtServer
Procedure WriteSettings(CurrentUser)
	
	IsBaseConfigurationVersion = StandardSubsystemsServer.IsBaseConfigurationVersion();
	If IsBaseConfigurationVersion Then
		Object.ExecutionOption = "OnExit";
	EndIf;
	
	Settings = IBBackupServer.BackupParameters();
	
	Settings.Insert("IBAdministrator", IBAdministrator);
	Settings.Insert("IBAdministratorPassword", ?(PasswordRequired, IBAdministratorPassword, ""));
	Settings.LastNotificationDate = Date('29990101');
	Settings.BackupStorageDirectory = Object.BackupDirectory;
	Settings.ExecutionOption = Object.ExecutionOption;
	Settings.CreateBackupAutomatically = Object.CreateBackupAutomatically;
	Settings.BackupConfigured = True;
	
	FillPropertyValues(Settings.DeletionParameters, Object);
	
	If Object.ExecutionOption = "Schedule3" Then
		
		ScheduleStructure = CommonClientServer.ScheduleToStructure(Schedule);
		Settings.CopyingSchedule = ScheduleStructure;
		Settings.MinDateOfNextAutomaticBackup = CurrentSessionDate();
		Settings.LatestBackupDate = CurrentSessionDate();
		
	ElsIf Object.ExecutionOption = "OnExit" Then
		
		Settings.MinDateOfNextAutomaticBackup = '29990101';
		
	EndIf;
	
	IBBackupServer.SetBackupSettings(Settings, CurrentUser);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateBackupDirectoryRestrictionType(Form)
	
	Form.Items.GroupStoreLastBackupsForPeriod.Enabled = (Form.Object.RestrictionType = "ByPeriod");
	Form.Items.BackupsCountInDirectoryGroup.Enabled = (Form.Object.RestrictionType = "ByCount");
	
EndProcedure

&AtClient
Procedure ModifyScheduleCompletion(ScheduleResult, AdditionalParameters) Export
	
	If ScheduleResult = Undefined Then
		Return;
	EndIf;
	
	Schedule = ScheduleResult;
	Items.ModifySchedule.Title = String(Schedule);
	
EndProcedure

/////////////////////////////////////////////////////////
// Presentation of data on the form.

&AtServer
Procedure SetVisibilityAvailability()
	
	Items.ModifySchedule.Enabled = (Object.ExecutionOption = "Schedule3");
	
	BackupAvailable = Object.CreateBackupAutomatically;
	Items.GroupParameters.Enabled = BackupAvailable;
	Items.SelectAutomaticBackupOption.Enabled = BackupAvailable;
	
EndProcedure

#EndRegion
