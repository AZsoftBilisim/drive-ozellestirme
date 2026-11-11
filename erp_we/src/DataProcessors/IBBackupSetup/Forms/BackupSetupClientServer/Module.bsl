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
	
	If Common.IsWebClient() Then
		Raise NStr("vi = 'Không cho phép sao lưu dự phòng tại Web-client.';
					|ru = 'Резервное копирование недоступно в веб-клиенте.';
					|en = 'Web client does not support data backup.'; fa = 'Web client does not support data backup.';
					|it = 'Il backup non è disponibile in web-client.';
					|pl = 'Kopia zapasowa nie jest dostępna w kliencie Web.';
					|tr = 'Yedekleme web istemcisinde mevcut değildir.'");
	EndIf;
	
	If Not Common.IsWindowsClient() Then
		Raise NStr("vi = 'Cần tùy chỉnh bản sao dự phòng và phục hồi dữ liệu bằng các công cụ của hệ điều hành hoặc các công cụ của bên khác.';
					|ru = 'Резервное копирование и восстановление данных необходимо настроить средствами операционной системы или другими сторонними средствами.';
					|en = 'Set up data backup and restore using operating system tools or other third-party tools.'; fa = 'Set up data backup and restore using operating system tools or other third-party tools.';
					|it = 'Il backup e il recupero dei dati devono essere configurati tramite gli strumenti del sistema operativo o altri strumenti esterni.';
					|pl = 'Tworzenie kopii zapasowych i odzyskiwanie danych muszą być konfigurowane za pomocą systemu operacyjnego lub innych narzędzi stron trzecich.';
					|tr = 'Veri yedekleme ve geri yükleme, işletim sistemin araçları veya diğer üçüncü taraf araçları tarafından yapılandırılmalıdır.'");
	EndIf;
	
	Settings = IBBackupServer.BackupParameters();
	DisableNotifications = Settings.BackupConfigured;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Settings = ApplicationParameters["StandardSubsystems.IBBackupParameters"];
	Settings.NotificationParameter1 = ?(DisableNotifications, "DontNotify", "NotConfiguredYet");
	
	If DisableNotifications Then
		IBBackupClient.DisableBackupIdleHandler();
	Else
		IBBackupClient.AttachIdleBackupHandler();
	EndIf;
	
	SetBackupSettings();
	Notify("BackupSettingsFormClosed");
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetBackupSettings()
	
	Settings = IBBackupServer.BackupParameters();
	Settings.BackupConfigured = DisableNotifications;
	Settings.CreateBackupAutomatically = False;
	IBBackupServer.SetBackupSettings(Settings);
	
EndProcedure

#EndRegion
