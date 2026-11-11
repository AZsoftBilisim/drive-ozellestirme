///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Returns PutInUserWorkingDirectory session parameter.
Function UserWorkingDirectory() Export
	
	ParameterName = "StandardSubsystems.WorkingDirectoryAccessCheckExecuted";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, False);
	EndIf;
	
	DirectoryName =
		StandardSubsystemsClient.ClientRunParameters().PersonalFilesOperationsSettings.PathToLocalFileCache;
	
	// Already specified.
	If DirectoryName <> Undefined
		And Not IsBlankString(DirectoryName)
		And ApplicationParameters["StandardSubsystems.WorkingDirectoryAccessCheckExecuted"] Then
		
		Return DirectoryName;
	EndIf;
	
	If DirectoryName = Undefined Then
		DirectoryName = FilesOperationsInternalClient.SelectPathToUserDataDirectory();
		If Not IsBlankString(DirectoryName) Then
			FilesOperationsInternalClient.SetUserWorkingDirectory(DirectoryName);
		Else
			ApplicationParameters["StandardSubsystems.WorkingDirectoryAccessCheckExecuted"] = True;
			Return ""; // Web client without 1C:Enterprise Extension.
		EndIf;
	EndIf;
	
#If Not WebClient Then
	
	// Create a directory for files.
	Try
		// If a directory is passed whose name is illegal in this file system,
		// no exception is thrown (however, the directory will be unavailable).
		InformationAboutTheCatalog = New File(DirectoryName);
		If Not InformationAboutTheCatalog.Exists() Then
			Raise NStr("vi = 'Thư mục không tồn tại.';
						|ru = 'Каталог не существует.';
						|en = 'Directory does not exist.'; fa = 'Directory does not exist.';
						|it = 'Directory inesistente.';
						|pl = 'Katalogu nie istnieje.';
						|tr = 'Katalog mevcut değil.'");
		EndIf;

		CreateDirectory(DirectoryName);
		TestDirectoryName = DirectoryName + "CheckAccess\";
		CreateDirectory(TestDirectoryName);
		DeleteFiles(TestDirectoryName);
	Except
		// Insufficient rights to create a directory, or this path does not exist.
		// Set the default settings.
		EventLogMessage = NStr("vi = 'Thư mục làm việc%1 không tìm thấy hoặc không có quyền ghi. Đã khôi phục cài đặt mặc định.';
								|ru = 'Не найден рабочий каталог %1 или нет права на запись. Восстановлены настройки по умолчанию.';
								|en = 'Working directory %1 is not found or there is no save permission. Default settings are restored.'; fa = 'Working directory %1 is not found or there is no save permission. Default settings are restored.';
								|it = 'Directory di lavoro %1 non trovata o non si possiede diritto di salvare nella directory. Impostazioni predefinite ripristinate.';
								|pl = 'Nie znaleziono katalogu roboczego %1 lub nie ma praw do zapisywania. Ustawienia domyślne zostały przywrócone.';
								|tr = '%1 çalışma kataloğu mevcut değil ya da kaydedilmesi için yetki yok. Varsayılan ayarlar geri yüklendi.'");
		EventLogMessage = StringFunctionsClientServer.SubstituteParametersToString(EventLogMessage, DirectoryName);
		DirectoryName = FilesOperationsInternalClient.SelectPathToUserDataDirectory();
		FilesOperationsInternalClient.SetUserWorkingDirectory(DirectoryName);
		
		EventLogClient.AddMessageForEventLog(
			NStr("vi = 'Làm việc với tệp';
				|ru = 'Работа с файлами';
				|en = 'File management'; fa = 'مدیریت فایل';
				|it = 'Lavoro con file';
				|pl = 'Praca z plikami';
				|tr = 'Dosya işlemleri'", CommonClient.DefaultLanguageCode()),
			"Warning",
			EventLogMessage,
			CommonClient.SessionDate(),
			True);

	EndTry;
	
#EndIf
	
	ApplicationParameters["StandardSubsystems.WorkingDirectoryAccessCheckExecuted"] = True;
	
	Return DirectoryName;
	
EndFunction

Function IsDirectoryFiles(FilesOwner) Export
	
	Return FilesOperationsInternalServerCall.IsDirectoryFiles(FilesOwner);
	
EndFunction

Function CurrentSessionStart() Export
	Return FilesOperationsInternalServerCall.CurrentSessionStart();
EndFunction

#EndRegion
