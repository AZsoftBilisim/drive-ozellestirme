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
Var BackupInProgress;

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
	
	If Parameters.WorkMode = "ExecuteNow" Then
		Items.WizardPages.CurrentPage = Items.InformationAndBackupCreationPage;
		If Not IsBlankString(Parameters.Explanation) Then
			Items.WaitGroup.CurrentPage = Items.WaitingForStartPage;
			Items.WaitingForBackupLabel.Title = Parameters.Explanation;
		EndIf;
	ElsIf Parameters.WorkMode = "ExecuteOnExit" Then
		Items.WizardPages.CurrentPage = Items.InformationAndBackupCreationPage;
	ElsIf Parameters.WorkMode = "CompletedSuccessfully1" Then
		Items.WizardPages.CurrentPage = Items.BackupSuccessfulPage;
		BackupFileName = Parameters.BackupFileName;
	ElsIf Parameters.WorkMode = "NotCompleted" Then
		Items.WizardPages.CurrentPage = Items.BackupCreationErrorsPage;
	EndIf;
	
	AutomaticRun = (Parameters.WorkMode = "ExecuteNow" Or Parameters.WorkMode = "ExecuteOnExit");
	Object.BackupDirectory = ?(AutomaticRun, 
		?(Not IsBlankString(BackupSettings1.BackupStorageDirectory), 
			BackupSettings1.BackupStorageDirectory,
			BackupSettings1.ManualBackupsStorageDirectory),
		?(Not IsBlankString(BackupSettings1.ManualBackupsStorageDirectory),
			BackupSettings1.ManualBackupsStorageDirectory,
			BackupSettings1.BackupStorageDirectory));
	
	If BackupSettings1.LatestBackupDate = Date(1, 1, 1) Then
		TitleText = NStr("vi = 'Vẫn chưa thực hiện sao lưu dự phòng lần nào';
						|ru = 'Резервное копирование еще ни разу не проводилось';
						|en = 'The infobase has never been backed up.'; fa = 'The infobase has never been backed up.';
						|it = 'Il backup non è mai stato eseguito';
						|pl = 'Kopia bezpieczeństwa nigdy nie była tworzona';
						|tr = 'Yedekleme hiç yapılmadı'");
	Else
		TitleText = NStr("vi = 'Lần cuối tiến hành sao lưu dự phòng: %1';
						|ru = 'В последний раз резервное копирование проводилось: %1';
						|en = 'Most recent backup: %1'; fa = 'Most recent backup: %1';
						|it = 'L''ultimo backup è stato eseguito: %1';
						|pl = 'Ostatnią kopię zapasową utworzono: %1';
						|tr = 'Son yedekleme: %1'");
		LastBackupDate = Format(BackupSettings1.LatestBackupDate, "DLF=DDT");
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(TitleText, LastBackupDate);
	EndIf;
	Items.LastBackupDateLabel.Title = TitleText;
	Items.AutomaticBackupGroup.Visible = Not BackupSettings1.CreateBackupAutomatically;
	Items.DonTWaitForSessionsToEnd.Visible = Common.DebugMode();
	
	UserInformation = IBBackupServer.UserInformation();
	PasswordRequired = UserInformation.PasswordRequired;
	If PasswordRequired Then
		IBAdministrator = UserInformation.Name;
	Else
		Items.AuthorizationGroup.Visible = False;
		IBAdministratorPassword = "";
	EndIf;
	
	ManualStart1 = (Items.WizardPages.CurrentPage = Items.BackupCreationPage);
	If ManualStart1 Then
		If InfobaseSessionsCount() > 1 Then
			Items.BackupStatusPages.CurrentPage = Items.ActiveUsersPage;
		EndIf;
		Items.Next.Title = NStr("vi = 'Lưu bản sao dự phòng';
								|ru = 'Сохранить резервную копию';
								|en = 'Save backup'; fa = 'Save backup';
								|it = 'Salvare copia di backup';
								|pl = 'Zapisz kopię zapasową';
								|tr = 'Yedek kopya kaydet'");
	EndIf;
	
	IBBackupServer.SetSettingValue("LastBackupManualStart", ManualStart1);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	GoToPage3(Items.WizardPages.CurrentPage);
	
#If WebClient Then
	Items.UpdateComponentVersionLabel.Visible = False;
#EndIf
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	CurrentPage = Items.WizardPages.CurrentPage;
	If CurrentPage <> Items.InformationAndBackupCreationPage Then
		Return;
	EndIf;
	
	WarningText = NStr("vi = 'Ngừng chuẩn bị sao lưu dự phòng dữ liệu?';
						|ru = 'Прервать подготовку к резервному копированию данных?';
						|en = 'Do you want to cancel preparing for backup?'; fa = 'Do you want to cancel preparing for backup?';
						|it = 'Interrompere la preparazione al backup dei dati?';
						|pl = 'Zaprzestać przygotowywania do tworzenia kopii zapasowych danych?';
						|tr = 'Yedeklemeye hazırlanmayı durdurmak istiyor musunuz?'");
	CommonClient.ShowArbitraryFormClosingConfirmation(ThisObject,
		Cancel, Exit, WarningText, "ForceCloseForm");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	DetachIdleHandler("Timeout2");
	DetachIdleHandler("CheckForSingleConnection");
	
	If BackupInProgress = True Then
		Return;
	EndIf;
	
	IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(False);
	IBConnectionsClient.SetUserTerminationInProgressFlag(False);
	IBConnectionsServerCall.AllowUserAuthorization();
	
	If ProcessRunning() Then
		SetProcessRunning(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "UsersSessions" And Parameter.SessionCount <= 1
		And ApplicationParameters["StandardSubsystems.IBBackupParameters"].ProcessRunning Then
			StartBackup();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UsersListClick(Item)
	
	StandardSubsystemsClient.OpenActiveUserList(, ThisObject);
	
EndProcedure

&AtClient
Procedure PathToBackupDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectedPath = GetPath(FileDialogMode.ChooseDirectory);
	If Not IsBlankString(SelectedPath) Then 
		Object.BackupDirectory = SelectedPath;
	EndIf;

EndProcedure

&AtClient
Procedure BackupFileNameOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	FileSystemClient.OpenExplorer(BackupFileName);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	ClearMessages();
	If Not CheckAttributesFilling() Then
		Return;
	EndIf;
	
	CurrentWizardPage = Items.WizardPages.CurrentPage;
	If CurrentWizardPage = Items.BackupCreationPage Then
		GoToPage3(Items.InformationAndBackupCreationPage);
		SetBackupArchivePath(Object.BackupDirectory, AutomaticRun);
	Else
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure GoToEventLog(Command)
	OpenForm("DataProcessor.EventLog.Form.EventLog", , ThisObject);
EndProcedure

&AtClient
Procedure DonTWaitForSessionsToEnd(Command)
	StartBackup();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GoToPage3(NewPage)
	
	GoToNext = True;
	If NewPage = Items.InformationAndBackupCreationPage Then
		GoToInformationAndBackupPage(GoToNext);
	ElsIf NewPage = Items.BackupCreationErrorsPage 
		Or NewPage = Items.BackupSuccessfulPage Then
		GoToBackupResultsPage();
	EndIf;
	
	If Not GoToNext Then
		Return;
	EndIf;
	
	If NewPage <> Undefined Then
		Items.WizardPages.CurrentPage = NewPage;
	Else
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToInformationAndBackupPage(GoToNext)
	
	If Not CheckAttributesFilling() Then
		Return;
	EndIf;
	
	CheckForBlockingSessions();
	Notification = New CallbackDescription(
		"GoToPageBackupAfterInfobaseAccessCheck", ThisObject);
	IBBackupClient.CheckAccessToInfobase(IBAdministratorPassword, Notification);
	
EndProcedure

&AtClient
Procedure GoToPageBackupAfterInfobaseAccessCheck(ConnectionResult, Context) Export
	
	If ConnectionResult.AddInAttachmentError Then
		Items.WizardPages.CurrentPage = Items.BackupCreationPage;
		Items.BackupStatusPages.CurrentPage = Items.ConnectionErrorPage;
		ConnectionErrorFound = ConnectionResult.BriefErrorDetails;
		Return;
	EndIf;
	
	SetBackupParemeters();
	SetProcessRunning(True);
	
	InfobaseSessionsCount = CheckForBlockingSessions();
	
	Items.Cancel.Enabled = True;
	Items.Next.Enabled = False;
	SetButtonTitleNext(True);
	
	IBConnectionsServerCall.SetConnectionLock(
		NStr("vi = 'Đang thực hiện sao lưu dự phòng cơ sở thông tin.';
			|ru = 'Выполняется резервное копирование информационной базы.';
			|en = 'Backing up the infobase.'; fa = 'Backing up the infobase.';
			|it = 'È in corso il backup del database informatico.';
			|pl = 'Trwa tworzenie kopii zapasowej bazy danych.';
			|tr = 'Infobase yedekleniyor.'"),
		"Backup");
	
	If InfobaseSessionsCount = 1 Then
		IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(True);
		IBConnectionsClient.SetUserTerminationInProgressFlag(True);
		StartBackup();
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
Procedure GoToBackupResultsPage()
	
	Items.Next.Visible = False;
	Items.Cancel.Title = NStr("vi = 'Đóng';
								|ru = 'Закрыть';
								|en = 'Close'; fa = 'بستن';
								|it = 'Chiudere';
								|pl = 'Close';
								|tr = 'Kapat'");
	Items.Cancel.DefaultButton = True;
	
	Settings = BackupSettings1();
	IBBackupClient.FillGlobalVariableValues(Settings);
	
	ResetBackupFlag();
	
EndProcedure

&AtServerNoContext
Procedure ResetBackupFlag()
	
	IBBackupServer.ResetBackupFlag();
	
EndProcedure

&AtServer
Procedure SetBackupParemeters()
	
	Settings = IBBackupServer.BackupSettings1();
	Settings.Insert("IBAdministrator", IBAdministrator);
	Settings.Insert("IBAdministratorPassword", ?(PasswordRequired, IBAdministratorPassword, ""));
	IBBackupServer.SetBackupSettings(Settings);
	
EndProcedure

&AtServerNoContext
Function BackupSettings1()
	
	Return IBBackupServer.BackupSettings1();
	
EndFunction

&AtClient
Function CheckAttributesFilling()

#If WebClient Then
	MessageText = NStr("vi = 'Không cho phép tạo bản sao dự phòng trên Web-client.';
						|ru = 'Создание резервной копии не доступно в веб-клиенте.';
						|en = 'Web client does not support data backup.'; fa = 'Web client does not support data backup.';
						|it = 'Il backup non è disponibile in web-client.';
						|pl = 'Tworzenie kopii zapasowej nie jest dostępne w kliencie Web.';
						|tr = 'Web istemcide yedekleme yapılamaz.'");
	CommonClient.MessageToUser(MessageText);
	AttributesFilled = False;
#Else
	
	AttributesFilled = True;
	
	Object.BackupDirectory = TrimAll(Object.BackupDirectory);
	
	If IsBlankString(Object.BackupDirectory) Then
		MessageText = NStr("vi = 'Chưa chọn thư mục cho bản sao dự phòng.';
							|ru = 'Не выбран каталог для резервной копии.';
							|en = 'Backup directory is not provided.'; fa = 'Backup directory is not provided.';
							|it = 'Nessuna directory è stata selezionata per il backup.';
							|pl = 'Nie wybrano katalogu kopii zapasowych.';
							|tr = 'Yedekleme dizini seçilmedi.'");
		CommonClient.MessageToUser(MessageText,, "Object.BackupDirectory");
		AttributesFilled = False;
	ElsIf FindFiles(Object.BackupDirectory).Count() = 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã chỉ định thư mục không tồn tại ""%1"". 
			|Nếu đã tùy chỉnh bản sao dự phòng trong máy tính khác, hãy chỉ định thư mục mạng khả dụng đối với máy tính bất kỳ làm việc trong ứng dụng.';
			|ru = 'Указан несуществующий каталог ""%1"". 
			|Если резервное копирование было настроено на другом компьютере, укажите сетевой каталог, доступный с любого компьютера, где ведется работа в приложении.';
			|en = 'A non-existent directory specified: %1.
			|If backup is configured on another computer, specify a network directory available from any computer with this app.'; fa = 'A non-existent directory specified: %1.
			|If backup is configured on another computer, specify a network directory available from any computer with this app.';
			|it = 'Указан несуществующий каталог ""%1"". 
			|Если резервное копирование было настроено на другом компьютере, укажите сетевой каталог, доступный с любого компьютера, где ведется работа в приложении.';
			|pl = 'A non-existent directory specified: %1.
			|If backup is configured on another computer, specify a network directory available from any computer with this app.';
			|tr = 'Var olmayan bir ''%1'' dizini belirtildi. 
			|Yedekleme başka bir bilgisayarda yapılandırılmışsa, uygulamanın kullanıldığı herhangi bir bilgisayardan erişilebilen bir ağ dizini belirtin.'"),
			Object.BackupDirectory);
		CommonClient.MessageToUser(MessageText,, "Object.BackupDirectory");
		AttributesFilled = False;
	Else
		
		FileName = "test.test1From1";
		Try
			TestFile = New XMLWriter;
			TestFile.OpenFile(Object.BackupDirectory + "/" + FileName);
			TestFile.WriteXMLDeclaration();
			TestFile.Close();
		Except
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không có quyền ghi vào thư mục sao lưu.
					|Không tạo được tệp thử nghiệm %1 vì lý do: %2';
					|ru = 'Нет прав на запись в каталог с резервными копиями.
					|Не удалось создать тестовый файл %1 по причине: %2';
					|en = 'Insufficient permissions when writing to the backup directory.
					|Cannot create test file %1 due to: %2'; fa = 'Insufficient permissions when writing to the backup directory.
					|Cannot create test file %1 due to: %2';
					|it = 'Non si possiedono i diritti di salvataggio nella directory con i backup.
					|Non è stato possibile creare il file di testo %1 a causa di: %2';
					|pl = 'Brak uprawnień do zapisywania do katalogu z kopiami rezerwowymi.
					|Nie udało się utworzyć testowego pliku %1 z powodu: %2';
					|tr = 'Yedeklerle katalogda kayda izni yok. 
					|Şu nedenle bir test%1dosyası oluşturulamadı:%2'"),
				FileName, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			CommonClient.MessageToUser(MessageText,, "Object.BackupDirectory");
			AttributesFilled = False;
		EndTry;
		
		If AttributesFilled Then
			
			// ACC:280-off - Exceptions are not processed. This step does not delete any files.
			Try
				DeleteFiles(Object.BackupDirectory, "*.test1From1");
			Except
			EndTry;
			// ACC:280-on
			
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

&AtClient
Procedure SetIdleHandlerOfBackupTimeout()
	
	AttachIdleHandler("Timeout2", 600, True);
	
EndProcedure

&AtClient
Procedure Timeout2()
	
	DetachIdleHandler("CheckForSingleConnection");
	QueryText = NStr("vi = 'Không thể loại bỏ toàn bộ người sử dụng khỏi cơ sở thông tin. Tiến hành sao lưu dự phòng? (có thể có lỗi khi sao lưu)';
					|ru = 'Не удалось отключить всех пользователей от базы. Провести резервное копирование? (возможны ошибки при архивации)';
					|en = 'Cannot terminate all user sessions. Are you sure you still want to back up the data? The backup might contain errors.'; fa = 'Cannot terminate all user sessions. Are you sure you still want to back up the data? The backup might contain errors.';
					|it = 'Impossibile disconnettere tutti gli utenti dal database. Eseguire il backup? (sono possibili errori durante l''archiviazione)';
					|pl = 'Nie udało się odłączyć wszystkich użytkowników od bazy danych. Utworzyć kopię zapasową? (możliwe błędy podczas archiwizacji)';
					|tr = 'Tüm kullanıcılar tabandan kesilemez. Veriler yedeklensin mi? (yedekleme sırasında hatalar oluşabilir)'");
	ExplanationText = NStr("vi = 'Không thể loại bỏ người sử dụng.';
							|ru = 'Не удалось отключить пользователя.';
							|en = 'Cannot terminate the user session.'; fa = 'Cannot terminate the user session.';
							|it = 'Impossibile disconnettere l''utente.';
							|pl = 'Nie udało się wyłączyć użytkownika.';
							|tr = 'Kullanıcı devre dışı bırakılamaz.'");
	CallbackDescription = New CallbackDescription("Timeout2Completion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, 30, DialogReturnCode.No, ExplanationText, DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure Timeout2Completion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		StartBackup();
	Else
		ClearMessages();
		IBConnectionsClient.SetTerminateAllSessionsExceptCurrentFlag(False);
		CancelPreparation();
EndIf;
	
EndProcedure

&AtServer
Procedure CancelPreparation()
	
	Items.FailedLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1.
		|Đã hủy chuẩn bị sao lưu. Đã mở khóa Infobase.';
		|ru = '%1.
		|Подготовка к резервному копированию отменена. Информационная база разблокирована.';
		|en = '%1.
		|Preparation for backing up is canceled. Infobase is unlocked.'; fa = '%1.
		|Preparation for backing up is canceled. Infobase is unlocked.';
		|it = '%1.
		|Preparazione del backup è annullata. Il database informatico è sbloccato.';
		|pl = '%1.
		|Przygotowanie do utworzenia kopii zapasowej zostało anulowane. Baza danych odblokowana.';
		|tr = '%1. 
		| Yedekleme için hazırlık iptal edildi. Infobase kilitlendi.'"),
		IBConnections.ActiveSessionsMessage());
	Items.WizardPages.CurrentPage = Items.BackupCreationErrorsPage;
	Items.GoToEventLog1.Visible = False;
	Items.Next.Visible = False;
	Items.Cancel.Title = NStr("vi = 'Đóng';
								|ru = 'Закрыть';
								|en = 'Close'; fa = 'بستن';
								|it = 'Chiudere';
								|pl = 'Close';
								|tr = 'Kapat'");
	Items.Cancel.DefaultButton = True;
	
	IBConnections.AllowUserAuthorization();
	
EndProcedure

&AtClient
Procedure SetIdleIdleHandlerOfBackupStart()
	
	AttachIdleHandler("CheckForSingleConnection", 5);
	
EndProcedure

&AtClient
Procedure CheckForSingleConnection()
	
	UsersCount = InfobaseSessionsCount();
	Items.ActiveUserCount.Title = String(UsersCount);
	If UsersCount = 1 Then
		StartBackup();
	Else
		CheckForBlockingSessions();
	EndIf;
	
EndProcedure

&AtClient
Procedure SetButtonTitleNext(ThisButtonNext)
	
	Items.Next.Title = ?(ThisButtonNext, NStr("vi = 'Tiếp theo >';
												|ru = 'Далее >';
												|en = 'Next >'; fa = 'بعدی >';
												|it = 'Avanti >';
												|pl = 'Dalej >';
												|tr = 'İleri >'"), NStr("vi = 'Đồng ý';
																	|ru = 'Готово';
																	|en = 'Finish'; fa = 'پایان';
																	|it = 'Fine';
																	|pl = 'Gotowe';
																	|tr = 'Bitiş'"));
	
EndProcedure

&AtClient
Function GetPath(DialogMode)
	
	Mode = DialogMode;
	OpenFileDialog = New FileDialog(Mode);
	If Mode = FileDialogMode.ChooseDirectory Then
		OpenFileDialog.Title= NStr("vi = 'Hãy chọn thư mục';
									|ru = 'Выберите каталог';
									|en = 'Select directory'; fa = 'Select directory';
									|it = 'Scegliete la directory';
									|pl = 'Wybierz katalog';
									|tr = 'Dizini seçin'");
	Else
		OpenFileDialog.Title= NStr("vi = 'Hãy chọn tệp';
									|ru = 'Выберите файл';
									|en = 'Select file'; fa = 'انتخاب فایل';
									|it = 'Selezionare un file';
									|pl = 'Wybierz plik';
									|tr = 'Dosya seç'");
	EndIf;	
		
	If OpenFileDialog.Choose() Then
		If DialogMode = FileDialogMode.ChooseDirectory Then
			Return OpenFileDialog.Directory;
		Else
			Return OpenFileDialog.FullFileName;
		EndIf;
	EndIf;
	
EndFunction

&AtClient
Procedure StartBackup()
	
#If Not WebClient And Not MobileClient Then
	
	IBBackupClient.DontStopScenariosExecution();
	
	MainScriptFileName = GenerateScriptFiles();
	
	EventLogClient.AddMessageForEventLog(
		IBBackupClient.EventLogEvent(),
		"Information", 
		NStr("vi = 'Đang sao lưu dự phòng cơ sở thông tin:';
			|ru = 'Выполняется резервное копирование информационной базы:';
			|en = 'Backing up the infobase backup:'; fa = 'Backing up the infobase backup:';
			|it = 'È in corso il backup del database informatico:';
			|pl = 'Trwa tworzenie kopii zapasowej bazy danych:';
			|tr = 'Infobase yedekleniyor:'") + " " + MainScriptFileName);
		
	If Parameters.WorkMode = "ExecuteNow" Or Parameters.WorkMode = "ExecuteOnExit" Then
		IBBackupClient.DeleteConfigurationBackups();
	EndIf;
	
	BackupInProgress = True;
	ForceCloseForm = True;
	
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

#Region FormServerEventHandlersAndBackupSettingsChangeHandlers

&AtServerNoContext
Procedure SetBackupArchivePath(Val Path, Val AutomaticRun)
	
	PathSettings = IBBackupServer.BackupSettings1();
	If AutomaticRun Then
		PathSettings.BackupStorageDirectory = Path;
	Else
		PathSettings.ManualBackupsStorageDirectory = Path;
	EndIf;
	IBBackupServer.SetBackupSettings(PathSettings);
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsToPrepareBackup

#If Not WebClient And Not MobileClient Then

&AtClient
Function GenerateScriptFiles()
	
	BackupParameters = IBBackupClient.ClientBackupParameters();
	CreateDirectory(BackupParameters.TempFilesDirForUpdate);
	
	ScriptParameters = IBBackupClient.GeneralScriptParameters();
	ScriptParameters.BinDir = Parameters.BinDir;
	ScriptParameters.ApplicationFileName = BackupParameters.ApplicationFileName;
	ScriptParameters.EventLogEvent = BackupParameters.EventLogEvent;
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
	ScriptFileName = BackupParameters.TempFilesDirForUpdate + "main.js";
	ScriptFile.Write(ScriptFileName, IBBackupClient.IBBackupApplicationFilesEncoding());
	
	// Auxiliary file: helpers.js.
	ScriptFile = New TextDocument;
	ScriptFile.Output = UseOutput.Enable;
	ScriptFile.SetText(Scripts.AddlBackupFile);
	ScriptFile.Write(BackupParameters.TempFilesDirForUpdate + "helpers.js", 
		IBBackupClient.IBBackupApplicationFilesEncoding());
	
	PictureLib.ExternalOperationSplash.Write(BackupParameters.TempFilesDirForUpdate + "splash.png");
	PictureLib.ExternalOperationSplashIcon.Write(BackupParameters.TempFilesDirForUpdate + "splash.ico");
	PictureLib.TimeConsumingOperation48.Write(BackupParameters.TempFilesDirForUpdate + "progress.gif");
	
	// Main splash file: splash.hta.
	MainScriptFileName = BackupParameters.TempFilesDirForUpdate + "splash.hta";
	ScriptFile = New TextDocument;
	ScriptFile.Output = UseOutput.Enable;
	ScriptFile.SetText(Scripts.BackupSplash);
	ScriptFile.Write(MainScriptFileName, IBBackupClient.IBBackupApplicationFilesEncoding());
	
	LogFile1 = New TextDocument;
	LogFile1.Output = UseOutput.Enable;
	LogFile1.SetText(StandardSubsystemsClient.SupportInformation());
	LogFile1.Write(BackupParameters.TempFilesDirForUpdate + "templog.txt", TextEncoding.System);
	
	Return MainScriptFileName;
	
EndFunction

#EndIf

&AtServer
Function GenerateScriptsText(Val ScriptParameters, MessagesForEventLog)
	
	EventLog.WriteEventsToEventLog(MessagesForEventLog);
	
	Result = New Structure("Script, AddlBackupFile, BackupSplash");
	Result.Script = GenerateScriptText(ScriptParameters);
	Result.AddlBackupFile = DataProcessors.IBBackup.GetTemplate("AddlBackupFile").GetText();
	Result.BackupSplash = GenerateSplashText();
	Return Result;
	
EndFunction

&AtServer
Function GenerateScriptText(ScriptParameters)
	
	// Configuration update file: main.js.
	ScriptTemplate = DataProcessors.IBBackup.GetTemplate("BackupFileTemplate");
	
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
	
	DirectoryName = CheckDirectoryForRootItemIndication(Object.BackupDirectory);
	
	TextParameters = IBBackupServer.PrepareCommonScriptParameters(ScriptParameters);
	TextParameters["[CreateDataBackup]"] = "true";
	TextParameters["[BackupDirectory]"] = IBBackupServer.PrepareText(DirectoryName + "\backup" + DirectoryStringFromDate());
	TextParameters["[RestoreInfobase]"] = "false";
	TextParameters["[ExecuteOnExit]"] = ?(Parameters.WorkMode = "ExecuteOnExit", "true", "false");
	
	Return IBBackupServer.SubstituteParametersToText(Text, TextParameters);
	
EndFunction

&AtServer
Function GenerateSplashText()
	
	TextTemplate1 = DataProcessors.IBBackup.GetTemplate("BackupSplash").GetText();
	
	TextParameters = New Map;
	TextParameters["[SplashTitle]"] = NStr("vi = 'Sao lưu CSTT ...';
											|ru = 'Резервное копирование информационной базы...';
											|en = 'Creating infobase backup…'; fa = 'Creating infobase backup…';
											|it = 'Backup del database...';
											|pl = 'Tworzenie kopii zapasowych bazy danych...';
											|tr = 'Infobase yedek kopyalanması...'");
	TextParameters["[SplashText]"] = 
		NStr("vi = 'Vui lòng đợi.
			|<br /> Cơ sở dữ liệu đang được sao lưu.
			|<br /> Nó không được khuyến khích để dừng quá trình.';
			|ru = 'Пожалуйста, подождите.
			|<br /> Выполняется резервное копирование базы.
			|<br /> Не рекомендуется останавливать процесс.';
			|en = 'Please wait.
			|<br /> Infobase backup is in progress.
			|<br /> It is recommended that you do not interrupt this operation.'; fa = 'Please wait.
			|<br /> Infobase backup is in progress.
			|<br /> It is recommended that you do not interrupt this operation.';
			|it = 'Пожалуйста, подождите.
			|<br /> Выполняется резервное копирование базы.
			|<br /> Не рекомендуется останавливать процесс.';
			|pl = 'Please wait.
			|<br /> Infobase backup is in progress.
			|<br /> It is recommended that you do not interrupt this operation.';
			|tr = 'Lütfen bekle. 
			|<br /> Veritabanı yedekleniyor. 
			|<br /> İşlemin durdurulması önerilmez.'");
	
	TextParameters["[Step1Initialization]"] = NStr("vi = 'Khởi tạo';
													|ru = 'Инициализация';
													|en = 'Initialization'; fa = 'Initialization';
													|it = 'Inizializzazione';
													|pl = 'Initialization';
													|tr = 'Başlatma'");
	TextParameters["[Step2BackupCreation]"] = NStr("vi = 'Tạo bản sao dự phòng cơ sở thông tin';
													|ru = 'Создание резервной копии информационной базы';
													|en = 'Creating infobase backup'; fa = 'Creating infobase backup';
													|it = 'Creazione del backup del database';
													|pl = 'Urworzenie rezerwowej kopii informacyjnej bazy';
													|tr = 'Infobase tabanı yedeği oluşturma'");
	TextParameters["[Step3AwaitingCompletion]"] = NStr("vi = 'Chờ đợi để sao lưu hoàn tất';
														|ru = 'Ожидание завершения резервного копирования';
														|en = 'Awaiting backup completion'; fa = 'Awaiting backup completion';
														|it = 'attesa del completamento di backup';
														|pl = 'Oczekiwanie zakończenia utworzenia kopii zapasowej';
														|tr = 'Yedeklemenin tamamlanması bekleniyor'");
	TextParameters["[Step4AllowConnections]"] = NStr("vi = 'Cho phép kết nối kết nối mới';
													|ru = 'Разрешение подключений новых соединений';
													|en = 'Allowing new connections'; fa = 'Allowing new connections';
													|it = 'Autorizzazione nuove connessioni';
													|pl = 'Zezwolenie podłączeń nowych połączeń';
													|tr = 'Yeni bağlantıların bağlanmasına izin verme'");
	TextParameters["[Step5Completion]"] = NStr("vi = 'Kết thúc';
												|ru = 'Завершение';
												|en = 'Completion'; fa = 'تکمیل';
												|it = 'Completamento';
												|pl = 'Completion';
												|tr = 'Bitiş'");
	TextParameters["[ProcessIsAborted]"] = NStr("vi = 'Chú ý: quá trình sao lưu bị gián đoạn và CSTT vẫn bị chặn.';
												|ru = 'Внимание: процесс резервного копирования был прерван, и информационная база осталась заблокированной.';
												|en = 'Warning! The backup was interrupted and the infobase is still locked.'; fa = 'Warning! The backup was interrupted and the infobase is still locked.';
												|it = 'Attenzione: il processo di backup è stato interrotto e il database è bloccato.';
												|pl = 'Uwaga: proces utworzenia kopii zapasowej został przerwany i baza informacyjna została zablokowana.';
												|tr = 'Dikkat: yedekleme işlemi kesintiye uğradı ve infobase kilitli kaldı.'");
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
Function CheckDirectoryForRootItemIndication(DirectoryString)
	
	If StrEndsWith(DirectoryString, ":\") Then
		Return Left(DirectoryString, StrLen(DirectoryString) - 1) ;
	Else
		Return DirectoryString;
	EndIf;
	
EndFunction

&AtServer
Function DirectoryStringFromDate()
	
	ReturnString = "";
	DateNow = CurrentSessionDate();
	ReturnString = Format(DateNow, "DF = yyyy_MM_dd_HH_mm_ss");
	Return ReturnString;
	
EndFunction

&AtClient
Procedure UpdateComponentVersionLabelURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	CommonClient.RegisterCOMConnector();
	
EndProcedure

&AtServerNoContext
Function InfobaseSessionsCount()
	
	Return IBConnections.InfobaseSessionsCount(False, False);
	
EndFunction

&AtClient
Function ProcessRunning()
	
	Settings = ApplicationParameters["StandardSubsystems.IBBackupParameters"];
	If Settings = Undefined Then
		NewSettings1 = BackupSettings1();
		IBBackupClient.FillGlobalVariableValues(NewSettings1);
		Settings = ApplicationParameters["StandardSubsystems.IBBackupParameters"];
	EndIf;	
	Return ?(Settings.ProcessRunning <> Undefined, Settings.ProcessRunning, False);
	
EndFunction

&AtClient
Procedure SetProcessRunning(Val ProcessRunning)
	
	Settings = ApplicationParameters["StandardSubsystems.IBBackupParameters"];
	If Settings = Undefined Then
		NewSettings1 = BackupSettings1();
		IBBackupClient.FillGlobalVariableValues(NewSettings1);
		Settings = ApplicationParameters["StandardSubsystems.IBBackupParameters"];
	EndIf;	
	Settings.ProcessRunning = ProcessRunning;
	IBBackupServerCall.SetSettingValue("ProcessRunning", ProcessRunning);
	
EndProcedure

#EndRegion

#EndRegion