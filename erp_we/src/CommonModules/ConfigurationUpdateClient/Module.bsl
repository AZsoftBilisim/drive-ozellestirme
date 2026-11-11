///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns whether configuration updates installation is supported by this computer.
// Update installation:
// - is available only in Windows;
// - is not available if connected via the web server (update requires batch run of Designer
//   that directly connects to the infobase);
// - is available if Designer (full distribution package of 1C:Enterprise technological platform for Windows) is installed;
// - is available if administration rights are granted.
// - is not available in SaaS mode (update installation is centralized and executed via Service manager).
//
// Returns:
//    Structure:
//     * Supported - Boolean - True if configuration update installation is supported.
//     * ErrorDescription - String - error description if update installation is not supported.
//
Function UpdatesInstallationSupported() Export
	
	Result = New Structure;
	Result.Insert("Supported", False);
	Result.Insert("InstallationOfPatchesIsSupported", False);
	Result.Insert("ErrorDescription", "");
	
	If CommonClient.DataSeparationEnabled() Then
		Result.ErrorDescription = 
			NStr("vi = 'Đang thực hiện cài đặt bản cập nhật đối với ứng dụng trong Internet tập trung thông qua Bộ quản lý dịch vụ. ';
				|ru = 'Установка обновлений для приложения в Интернете выполняется централизованно через Менеджер сервиса.';
				|en = 'Cloud applications support only centralized updates initiated from the service manager.'; fa = 'Cloud applications support only centralized updates initiated from the service manager.';
				|it = 'Impostazione dell''aggiornamento per l''applicazione su internet viene eseguita in modo centralizzato attraverso Manager di servizio.';
				|pl = 'Instalacja aktualizacji dla aplikacji w Internecie jest wykonywana scentralizowanie przez Menedżera usług.';
				|tr = 'Uygulama için güncellemelerin İnternet''te yüklenmesi, Servis Yöneticisi aracılığıyla merkezi olarak gerçekleştirilir.'");
		Return Result;
	EndIf;
	
	If Not UsersClient.IsFullUser(True) Then
		Result.ErrorDescription = NStr("vi = 'Để cài đặt bản cập nhật, cần có quyền quản trị.';
										|ru = 'Для установки обновления требуются права администрирования.';
										|en = 'You need the administrator rights to install the update.'; fa = 'You need the administrator rights to install the update.';
										|it = 'Per instalalre l''aggiornamento sono richiesti i diritti di amministrazione.';
										|pl = 'Do zainstalowania aktualizacji wymagane są uprawnienia administracyjne.';
										|tr = 'Güncellemenin yüklenmesi için yönetici yetkileri gerekmektedir.'");
		Return Result;
	EndIf;
	
#If WebClient Then
	
	Result.InstallationOfPatchesIsSupported = True;
	Result.ErrorDescription =
		NStr("vi = 'Trên Web-client chỉ có thể cài đặt bản sửa lỗi.
			|Để cài đặt bản cập nhật, hãy cài đặt
			|phiên bản đầy đủ của nền tảng công nghệ 1C:Enterprise dành cho Windows.';
			|ru = 'В веб-клиенте доступна только установка исправлений.
			|Для установки обновления, установите
			|полный дистрибутив технологической платформы 1С:Предприятие для Windows.';
			|en = 'Only patch installation is available in the web client.
			|To install the update, install
			|the distribution package of 1C:Enterprise for Windows.'; fa = 'Only patch installation is available in the web client.
			|To install the update, install
			|the distribution package of 1C:Enterprise for Windows.';
			|it = 'Nel client web è disponibile solo l''impostazione di patch.
			|Per impostare l''anniornamento,
			| installare il pacchetto di distribuzione completo della piattaforma tecnologica 1C:Enterprise per Windows.';
			|pl = 'W kliencie webowym dostępna jest tylko instalacji korekt.
			|W celu instalacji aktualizacji, zainstaluj
			|pełną dystrybucję platformy technologicznej 1C:Enterprise dla Windows.';
			|tr = 'Web istemcisinde yalnızca yama yüklemesi mevcuttur.
			|Güncellemeyi yüklemek için Windows için 1C:Enterprise teknoloji platformunun 
			|tam dağıtım kitini yükleyin.'");
	
#ElsIf MobileClient Then
	Result.ErrorDescription = NStr("vi = 'Chỉ cho phép cài đặt bản cập nhật trong hệ điều hành Windows.';
									|ru = 'Установка обновления доступна только в ОС Windows.';
									|en = 'The update is available only on Windows.'; fa = 'The update is available only on Windows.';
									|it = 'L''installazione dell''aggiornamento è disponibile solo nel sistema operativo Windows.';
									|pl = 'Instalacja aktualizacji jest dostępna tylko w systemie Windows.';
									|tr = 'Güncelleme yüklemesi yalnızca Windows işletim sisteminde kullanılabilir.'");
#Else
	
	If Not CommonClient.IsWindowsClient() Then 
		Result.ErrorDescription = NStr("vi = 'Chỉ cho phép cài đặt bản cập nhật trong hệ điều hành Windows.';
										|ru = 'Установка обновления доступна только в ОС Windows.';
										|en = 'The update is available only on Windows.'; fa = 'The update is available only on Windows.';
										|it = 'L''installazione dell''aggiornamento è disponibile solo nel sistema operativo Windows.';
										|pl = 'Instalacja aktualizacji jest dostępna tylko w systemie Windows.';
										|tr = 'Güncelleme yüklemesi yalnızca Windows işletim sisteminde kullanılabilir.'");
	EndIf;
	
	If CommonClient.ClientConnectedOverWebServer() Then 
		If Not IsBlankString(Result.ErrorDescription) Then
			Result.ErrorDescription = Result.ErrorDescription + Chars.LF + Chars.LF; 
		EndIf;
		
		Result.InstallationOfPatchesIsSupported = True;
		Result.ErrorDescription = Result.ErrorDescription
			+ NStr("vi = 'Khi kết nối thông qua Web-server chỉ có thể cài đặt bản sửa lỗi.
				|Để cài đặt bản cập nhật, cần cài đặt
				|phiên bản đầy đủ của nền tảng công nghệ 1C:Enterprise dành cho Windows.';
				|ru = 'При подключении через веб-сервер доступна только установка исправлений.
				|Для установки обновления, установите
				|полный дистрибутив технологической платформы 1С:Предприятие для Windows.';
				|en = 'Only patch installation is available from the web server.
				|To install the update, install
				|the distribution package of 1C:Enterprise for Windows.'; fa = 'Only patch installation is available from the web server.
				|To install the update, install
				|the distribution package of 1C:Enterprise for Windows.';
				|it = 'Durante la connessione tramite web server è disponibile solo l''impostazione di patch.
				|Per l''impostazione dell''aggiornamento, installare
				|il pacchetto di distribuzione completo della piattaforma tecnologica 1C:Enterprise per Windows.';
				|pl = 'Przy połączeniu przez serwer webowy jest dostępna tylko instalacja korekt.
				|W celu instalacji aktualizacji, zainstaluj
				|pełną dystrybucję platformy technologicznej 1С:Enterprise dla Windows.';
				|tr = 'Web-sunucusu üzerinden bağlanıldığında yalnızca düzeltme yüklemesi mevcuttur.
				|Güncellemeyi yüklemek için Windows için 1C:Enterprise teknoloji platformunun 
				|tam dağıtım kitini yükleyin.'");
	EndIf;
	
	If Not DesignerBatchModeSupported() Then 
		If Not IsBlankString(Result.ErrorDescription) Then
			Result.ErrorDescription = Result.ErrorDescription + Chars.LF + Chars.LF; 
		EndIf;
		
		Result.ErrorDescription = Result.ErrorDescription
			+ NStr("vi = 'Để cài đặt bản cập nhật, cần mở bộ thiết kế.
				|Hãy cài đặt bộ phân phối đầy đủ của nền tảng công nghệ 1C:Enterprise dành cho Windows.';
				|ru = 'Для установки обновления требуется конфигуратор.
				|Установите полный дистрибутив технологической платформы 1С:Предприятие для Windows.';
				|en = 'Designer is required to install the update.
				|Install the distribution package for 1C:Enterprise for Windows.'; fa = 'Designer is required to install the update.
				|Install the distribution package for 1C:Enterprise for Windows.';
				|it = 'Per l''installazione è richiesto il configuratore.
				|Installare il pacchetto di distribuzione completo della piattaforma tecnologica 1C:Enterprise per Windows.';
				|pl = 'Aby zainstalować konfigurator wymagany jest konfigurator.
				|Zainstaluj pełną dystrybucję platformy technologicznej 1C:Enterprise dla Windows.';
				|tr = 'Güncellemenin kurulumu için yapılandırıcı gerekiyor.
				|1C:Enterprise teknolojik platformunun Windows için tam dağıtımı yükleyin.'");
	EndIf;
	
#EndIf
	
	Result.Supported = IsBlankString(Result.ErrorDescription);
	
	If Result.Supported Then 
		Result.InstallationOfPatchesIsSupported = True;
	EndIf;
	
	Return Result;
	
EndFunction

// Opens the update installation form with the specified parameters.
//
// Parameters:
//    UpdateIntallationParameters - Structure - additional update installation parameters:
//     * ShouldExitApp - Boolean - True if the application is closed after installing an update. 
//                                          Default value is False.
//     * IsConfigurationUpdateReceived - Boolean - True if an update was retrieved 
//                                          from an online application. The default value is False - regular update installation mode.
//     * RunUpdate     - Boolean - if True, skip update file selection and proceed
//                                          to installing an update. The default value is False - offer a choice.
//
Procedure ShowUpdateSearchAndInstallation(UpdateIntallationParameters = Undefined) Export
	
	Result = UpdatesInstallationSupported();
	If Result.Supported
		Or Result.InstallationOfPatchesIsSupported Then
		
		OpenForm("DataProcessor.InstallUpdates.Form", UpdateIntallationParameters);
	Else 
		ShowMessageBox(, Result.ErrorDescription);
	EndIf;
	
EndProcedure

// Displays a backup creation settings form.
//
// Parameters:
//    BackupParameters - Structure - backup form parameters:
//      * CreateDataBackup - Number - if 0, Do not back up the infobase;
//                                          1 - create a temporary infobase backup;
//                                          2, Create an infobase backup.
//      * IBBackupDirectoryName - String - a backup directory.
//      * RestoreInfobase - Boolean - roll back in case of update errors.
//    CallbackDescription - CallbackDescription - a description of form closing notification.
//
Procedure ShowBackup(BackupParameters, CallbackDescription) Export
	
	OpenForm("DataProcessor.InstallUpdates.Form.BackupCreationSetup", BackupParameters,,,,, CallbackDescription);
	
EndProcedure

#Region InterfaceImplementation

// Returns the backup settings title text for displaying in a form.
//
// Parameters:
//    Parameters - Structure - backup parameters.
//
// Returns:
//    String - backup creation hyperlink title.
//
Function BackupCreationTitle(Parameters) Export
	
	If Parameters.CreateDataBackup = 0 Then
		Return NStr("vi = 'Không tạo bản sao lưu dự phòng CSDL';
					|ru = 'Не создавать резервную копию ИБ';
					|en = 'Do not back up the infobase'; fa = 'Do not back up the infobase';
					|it = 'Non creare il backup DB';
					|pl = 'Nie twórz kopii zapasowej BI';
					|tr = 'Infobase''i yedekleme'");
	ElsIf Parameters.CreateDataBackup = 1 Then
		If Parameters.RestoreInfobase Then 
			Return NStr("vi = 'Tạo mới bản sao dự phòng CSTT và thực hiện từ chối khi có tình huống bất thường';
						|ru = 'Создавать временную резервную копию ИБ и выполнять откат при нештатной ситуации';
						|en = 'Create a temporary infobase backup and roll back if any issues occur'; fa = 'ایجاد پشتیبان موقت پایگاه اطلاعات و بازگردانی در صورت بروز مشکل';
						|it = 'Crea un backup temporaneo del database e effettua il ripristino nel caso di un''emergenza';
						|pl = 'Tworzyć kopię zapasową BI i wykonywać powrót w przypadku wystąpienia nieoczekiwanej sytuacji';
						|tr = 'Acil bir durumda geçici bir IS yedeği oluşturun ve geri alın'");
		Else 
			Return NStr("vi = 'Tạo một bản sao lưu tạm thời của CSTT và không quay trở lại trong trường hợp khẩn cấp';
						|ru = 'Создавать временную резервную копию ИБ и не выполнять откат при нештатной ситуации';
						|en = 'Create a temporary infobase backup and do not roll back if any issues occur'; fa = 'Create a temporary infobase backup and do not roll back if any issues occur';
						|it = 'Crea un backup temporaneo del database e non effettua il ripristino nel caso di un''emergenza';
						|pl = 'Tworzyć tymczasową kopię zapasową BI i nie wykonywać rollback w sytuacji nadzwyczajnej';
						|tr = 'Geçici Infobase yedeklemesi oluşturun ve acil durumda başlangıca dönmeyin'");
		EndIf;
	ElsIf Parameters.CreateDataBackup = 2 Then
		If Parameters.RestoreInfobase Then 
			Return NStr("vi = 'Tạo một bản sao lưu bảo mật thông tin và quay lại trong trường hợp khẩn cấp';
						|ru = 'Создавать резервную копию ИБ и выполнять откат при нештатной ситуации';
						|en = 'Create an infobase backup and roll back if any issues occur'; fa = 'Create an infobase backup and roll back if any issues occur';
						|it = 'Crea un backup del database e effettua il ripristino nel caso di un''emergenza';
						|pl = 'Tworzyć kopię zapasową BI i wykonywać rollback w sytuacji nadzwyczajnej';
						|tr = 'Infobase yedeklemesi oluşturun ve acil durumda başlangıca dönün'");
		Else 
			Return NStr("vi = 'Tạo một bản sao lưu của CSTT và không quay trở lại trong trường hợp khẩn cấp';
						|ru = 'Создавать резервную копию ИБ и не выполнять откат при нештатной ситуации';
						|en = 'Create an infobase backup and do not roll back if any issues occur'; fa = 'Create an infobase backup and do not roll back if any issues occur';
						|it = 'Crea un backup del database e non effettua il ripristino nel caso di un''emergenza';
						|pl = 'Tworzyć kopię zapasową BI i nie wykonywać rollback w sytuacji nadzwyczajnej';
						|tr = 'Infobase yedeklemesi oluşturun ve acil durumda başlangıca dönmeyin'");
		EndIf;
	Else
		Return "";
	EndIf;
	
EndFunction

// OnlineUserSupport.GetApplicationUpdates

// Checks whether update installation is possible. If possible, runs
// the update script or schedules an update for a specified time.
//
// Parameters:
//    Form - ClientApplicationForm - a form where a user initiates an update (it must be closed at the end). 
//    Parameters - Structure - update installation parameters:
//        * UpdateMode - Number - an update installation option. Available values:
//                                    0 - now, 1 - on exit, 2 - scheduled update.
//        * UpdateDateTime - Date - a scheduled update date.
//        * EmailReport - Boolean - shows whether update reports are sent by email.
//        * Email - String - an email address for sending update reports.
//        * SchedulerTaskCode - Number - a code of a scheduled update task.
//        * UpdateFileName - String - the update file name.
//        * CreateDataBackup - Number - shows whether a backup is created.
//        * IBBackupDirectoryName - String - a backup directory.
//        * RestoreInfobase - Boolean - shows whether an infobase is restored from a backup in case of update errors.
//        * ShouldExitApp - Boolean - shows that an update is installed when the application is closed.
//        * FilesOfUpdate - Array of Structure:
//           ** UpdateFileFullName - String
//           ** ExecuteUpdateHandlers - Boolean - Indicates whether to run the update handlers after migrating to the given version.
//        * Corrections - Structure:
//           ** Set - Array - Paths to the patch files
//                                    in a temporary storage.
//           ** Delete    - Array - UUIDs of patches to be deleted (String).
//        * PlatformDirectory - String - path to the platform to be updated if it is not specified
//                                    that the update is running on the current session platform.
//    AdministrationParameters - See StandardSubsystemsServer.AdministrationParameters.
//
Procedure InstallUpdate(Form, Parameters, AdministrationParameters) Export
	
#If Not WebClient And Not MobileClient Then
	
	
	If Parameters.UpdateMode = 0 Then
		InstallUpdateNowStart(Form, Parameters, AdministrationParameters);
		Return;
	EndIf;
	
	If Form <> Undefined Then
		Form.Close();
	EndIf;
	
	If Parameters.UpdateMode = 1 Then // On exit
		ParameterName = "StandardSubsystems.SuggestInfobaseUpdateOnExitSession";
		ApplicationParameters.Insert(ParameterName, True);
		ApplicationParameters.Insert("StandardSubsystems.UpdateFilesNames", UpdateFilesNames(Parameters, Undefined));
	ElsIf Parameters.UpdateMode = 2 Then // Schedule an update.
		ScheduleConfigurationUpdate(Parameters, AdministrationParameters);
	EndIf;
	
#EndIf
	
EndProcedure

// End OnlineUserSupport.GetApplicationUpdates

#EndRegion

#EndRegion

#Region Internal

Procedure ProcessUpdateResult(UpdateResult, ScriptDirectory) Export
	
	If IsBlankString(ScriptDirectory) Then
		EventLogClient.AddMessageForEventLog(EventLogEvent(),
			"Warning", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Nhật ký cập nhật xem trong thư mục tệp tạm thời %1 (số).';
					|ru = 'Журнал обновления см. в каталоге временных файлов %1.(цифры).';
					|en = 'See the update log in the temporary file folder: %1.(digits).'; fa = 'See the update log in the temporary file folder: %1.(digits).';
					|it = 'See the update log in the temporary file folder: %1.(digits).';
					|pl = 'See the update log in the temporary file folder: %1.(digits).';
					|tr = 'Güncelleme günlüğüne geçici %1 dosya dizininde bakınız.(rakamlar).'"), "%temp%\1Cv8Update"),, True);
		UpdateResult = True; // Consider the update being successful.
	Else 
		EventLogClient.AddMessageForEventLog(EventLogEvent(),
			"Information", 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Thư mục có nhật ký cập nhật: %1';
					|ru = 'Папка с журналом обновления: %1';
					|en = 'Update log folder: %1'; fa = 'Update log folder: %1';
					|it = 'Cartella con registro aggiornamenti: %1';
					|pl = 'Folder z dziennikiem aktualizacji: %1';
					|tr = 'Güncelleme günlüğü ile klasör: %1'"), ScriptDirectory),, True);
		
#If Not WebClient And Not MobileClient Then
		ReadDataToEventLog(UpdateResult, ScriptDirectory);
#EndIf
		
	EndIf;
	
EndProcedure

Procedure WriteDownTheErrorOfTheNeedToUpdateThePlatform(ErrorText) Export
	
	ScriptDirectory = ConfigurationUpdateServerCall.ScriptDirectory();
	WriteErrorLogFileAndExit(ScriptDirectory, ErrorText);
	
EndProcedure

// Updates database configuration.
//
// Parameters:
//  StandardProcessing - Boolean - if False, do not show
//                                  the manual update instruction.
//
Procedure InstallConfigurationUpdate(ShouldExitApp = False) Export
	
	FormParameters = New Structure("ShouldExitApp, IsConfigurationUpdateReceived",
		ShouldExitApp, ShouldExitApp);
	ShowUpdateSearchAndInstallation(FormParameters);
	
EndProcedure

// Writes an error marker file to the script directory.
//
Procedure WriteErrorLogFileAndExit(Val DirectoryName, Val DetailErrorDescription) Export
	
#If Not WebClient Then
	
	If StrFind(LaunchParameter, "UpdateAndExit") > 0 Then
		
		Directory = New File(DirectoryName);
		If Directory.Exists() And Directory.IsDirectory() Then // ACC:566 Synchronous calls outside of the web client are allowed.
			
			ErrorRegistrationFile = New TextWriter(DirectoryName + "error.txt");
			ErrorRegistrationFile.Close();
			
			LogFile1 = New TextWriter(DirectoryName + "templog.txt", TextEncoding.System);
			LogFile1.Write(DetailErrorDescription);
			LogFile1.Close();
			
			Terminate();
			
		EndIf;
	EndIf;
	
#EndIf
	
EndProcedure

// Opens a form with a list of installed patches.
//
Procedure ShowInstalledPatches(Parameters = Undefined, OpeningMode = Undefined) Export
	
	If Parameters = Undefined Then
		Parameters = New Structure;
	EndIf;
	
	OpenForm("CommonForm.InstalledPatches", Parameters,,,,,, OpeningMode);
	
EndProcedure

// Determines whether an extension is a patch.
// Parameters:
//  PatchName - String - an extension name.
//
Function IsPatch(PatchName) Export
	Return StrStartsWith(PatchName, "EF_");
EndFunction

#Region ConfigurationSubsystemsEventHandlers

// See CommonClientOverridable.BeforeStart
Procedure BeforeStart(Parameters) Export
	If StrFind(LaunchParameter, "DisablePatchesAndExit") > 0 Then
		ConfigurationUpdateServerCall.DisablePatchesFromScript();
		Terminate();
	EndIf;
EndProcedure

// See CommonClientOverridable.OnStart.
Procedure OnStart(Parameters) Export
	
	CheckForConfigurationUpdate();
	
EndProcedure

// Parameters:
//  Cancel - See CommonClientOverridable.BeforeExit.Cancel
//  Warnings - See CommonClientOverridable.BeforeExit.Warnings
//
Procedure BeforeExit(Cancel, Warnings) Export
	
	// NOTE: When raising the flag, the subsystem "ConfigurationUpdate" clears the warnings list.
	// 
	If ApplicationParameters["StandardSubsystems.SuggestInfobaseUpdateOnExitSession"] = True Then
		WarningParameters = StandardSubsystemsClient.WarningOnExit();
		WarningParameters.CheckBoxText  = NStr("vi = 'Cài đặt bản cập nhật cấu hình';
												|ru = 'Установить обновление конфигурации';
												|en = 'Install configuration update'; fa = 'Install configuration update';
												|it = 'Aggiornamento della configurazione configurare';
												|pl = 'Zainstaluj aktualizację konfiguracji';
												|tr = 'Yapılandırma güncellemesini yükle'");
		WarningParameters.WarningText  = NStr("vi = 'Đã lập kế hoạch cài đặt bản cập nhật.';
												|ru = 'Запланирована установка обновления.';
												|en = 'Update installation is scheduled.'; fa = 'Update installation is scheduled.';
												|it = 'Запланирована установка обновления.';
												|pl = 'Update installation is scheduled.';
												|tr = 'Güncelleme planlandı.'");
		WarningParameters.Priority = 50;
		WarningParameters.OutputSingleWarning = True;
		
		ActionIfFlagSet = WarningParameters.ActionIfFlagSet;
		ActionIfFlagSet.Form = "DataProcessor.InstallUpdates.Form";
		ActionIfFlagSet.FormParameters = New Structure("ShouldExitApp, RunUpdate", 
			True, True);
		
		Warnings.Add(WarningParameters);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function VersionsRequiringSuccessfulUpdate(TransferredUpdateFiles)
	FilesOfUpdate = New Array;
	For Each UpdateFile In TransferredUpdateFiles Do
		InformationRecords = New Structure;
		InformationRecords.Insert("BinaryData", New BinaryData(UpdateFile.UpdateFileFullName));
		InformationRecords.Insert("Required", UpdateFile.ExecuteUpdateHandlers);
		FilesOfUpdate.Add(InformationRecords);
	EndDo;
	
	Return ConfigurationUpdateServerCall.VersionsRequiringSuccessfulUpdate(FilesOfUpdate);
EndFunction

// OnlineUserSupport.GetApplicationUpdates

Function UpdateInstallationPossible(Parameters, AdministrationParameters)
	
	Result = UpdatesInstallationSupported();
	If Not Result.Supported Then 
		ShowMessageBox(, Result.ErrorDescription);
		Return False;
	EndIf;
	
	IsFileInfobase = CommonClient.FileInfobase();
	
	If IsFileInfobase And Parameters.CreateDataBackup = 2 Then
		File = New File(Parameters.IBBackupDirectoryName);
		If Not File.Exists() Or Not File.IsDirectory() Then // ACC:566 Synchronous calls outside of the web client are allowed.
			ShowMessageBox(,
				NStr("vi = 'Chỉ định thư mục hiện có để lưu bản sao lưu CSTT.';
					|ru = 'Укажите существующую папку для сохранения резервной копии ИБ.';
					|en = 'Please specify an existing folder for storing the infobase backup.'; fa = 'Please specify an existing folder for storing the infobase backup.';
					|it = 'Indicare una cartella esistente per la conservazione della copia di riserva dell''infobase.';
					|pl = 'Podaj istniejąca folder do zapisywania kopii zapasowej BI.';
					|tr = 'IB yedek kopyasını kaydetmek için mevcut bir klasörü belirtin.'"));
			Return False;
		EndIf;
	EndIf;
	
	If Parameters.UpdateMode = 0 Then // Update now.
		ParameterName = "StandardSubsystems.MessagesForEventLog";
		If IsFileInfobase
			And ConfigurationUpdateServerCall.HasActiveConnections(ApplicationParameters[ParameterName]) Then
			
			ShowMessageBox(,
				NStr("vi = 'Không thể tiếp tục cập nhật cấu hình vì
				           |tất cả các kết nối với CSTT chưa được hoàn tất.';
				           |ru = 'Невозможно продолжить обновление конфигурации,
				           |так как не завершены все соединения с информационной базой.';
				           |en = 'Cannot proceed with configuration update
				           |as some infobase connections were not closed.'; fa = 'Cannot proceed with configuration update
				           |as some infobase connections were not closed.';
				           |it = 'Impossibile continuare l''aggiornamento di configurazione, 
				           | perché non tutte le connessioni al database sono state terminate.';
				           |pl = 'Niemożłiwe jest kontynuowanie aktualizacji konfiguracji,
				           | ponieważ nie są zakończone wszystkie połączenia z bazą informacyjną.';
				           |tr = '
				           |Infobase ile tüm kurulumları tamamlanmadı için konfigürasyon güncellemesine devam edilemiyor.'"));
			Return False;
		EndIf;
	ElsIf Parameters.UpdateMode = 2 Then
		If Not UpdateDateCorrect(Parameters) Then
			Return False;
		EndIf;
		
		InvalidEmailSpecified = Parameters.EmailReport
			And Not CommonClientServer.EmailAddressMeetsRequirements(Parameters.Email);
		
		If InvalidEmailSpecified Then
			ShowMessageBox(,
				NStr("vi = 'Hãy chỉ ra địa chỉ E-mail đúng.';
					|ru = 'Укажите допустимый адрес электронной почты.';
					|en = 'Please specify a valid email address.'; fa = 'Please specify a valid email address.';
					|it = 'Specificare un indirizzo e-mail valido.';
					|pl = 'Podaj dopuszczalny adres poczty elektronicznej.';
					|tr = 'İzin verilen bir e-posta adresi belirtin.'"));
			Return False;
		EndIf;
		
		If Not JobSchedulerSupported() Then
			ShowMessageBox(,
				NStr("vi = 'Bộ lập kế hoạch nhiệm vụ được hỗ trợ chỉ bắt đầu từ hệ điều hành phiên bản 6.0 Vista.';
					|ru = 'Планировщик заданий поддерживается только начиная с операционной системы версии 6.0 Vista.';
					|en = 'Job scheduler supports Windows Vista 6.0 or later.'; fa = 'Job scheduler supports Windows Vista 6.0 or later.';
					|it = 'L''utilità di pianificazione è supportata solo a partire dalla versione 6.0 di Vista.';
					|pl = 'Program planowania zadań jest obsługiwany tylko zaczynając od systemu operacyjnego wersji 6.0 Vista.';
					|tr = 'Görev planlayıcısı işletim sistemin yalnızca 6.0 Vista sürümünden itibaren desteklenir.'"));
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

Function JobSchedulerSupported()
	
	// Task Scheduler is supported for versions 6.0 (Windows Vista) and later.
	
	SystemInfo = New SystemInfo();
	
	PointPosition = StrFind(SystemInfo.OSVersion, ".");
	If PointPosition < 2 Then 
		Return False;
	EndIf;
	
	VersionNumber = Mid(SystemInfo.OSVersion, PointPosition - 2, 2);
	
	TypeDescriptionNumber = New TypeDescription("Number");
	VersionLaterThanVista = TypeDescriptionNumber.AdjustValue(VersionNumber) >= 6;
	
	Return VersionLaterThanVista;
	
EndFunction

Function UpdateDateCorrect(Parameters)
	
	CurrentDate = CommonClient.SessionDate();
	If Parameters.UpdateDateTime < CurrentDate Then
		MessageText = NStr("vi = 'Có thể lập kế hoạch cập nhật cấu hình chỉ vào ngày và giờ trong tương lai.';
							|ru = 'Обновление конфигурации может быть запланировано только на будущую дату и время.';
							|en = 'A configuration update can be scheduled only for a future date and time.'; fa = 'A configuration update can be scheduled only for a future date and time.';
							|it = 'L''aggiornamento della configurazione può essere pianificato solo per la data e l''ora future.';
							|pl = 'Aktualizacja konfiguracji może być zaplanowana tylko na przyszłą datę i czas.';
							|tr = 'Yapılandırma güncellemesi sadece ileri bir tarih ve saat için planlanabilir.'");
	ElsIf Parameters.UpdateDateTime > AddMonth(CurrentDate, 1) Then
		MessageText = NStr("vi = 'Có thể dự tính cập nhật cấu hình không muộn hơn 1 tháng so với ngày hiện tại.';
							|ru = 'Обновление конфигурации может быть запланировано не позднее, чем через месяц относительно текущей даты.';
							|en = 'A configuration update cannot be scheduled to a date later than one month from the current date.'; fa = 'A configuration update cannot be scheduled to a date later than one month from the current date.';
							|it = 'L''aggiornamento della configurazione può essere pianificato entro e non oltre un mese rispetto alla data corrente.';
							|pl = 'Aktualizacja konfiguracji może być zaplanowana nie później, niż za miesiąc po bieżącej dacie.';
							|tr = 'Yapılandırma güncellemesi, geçerli tarihten itibaren bir ay içinde geçmeyecek şekilde programlanabilir.'");
	EndIf;
	
	DateCorrect = IsBlankString(MessageText);
	If Not DateCorrect Then
		ShowMessageBox(, MessageText);
	EndIf;
	
	Return DateCorrect;
	
EndFunction

// End OnlineUserSupport.GetApplicationUpdates


Procedure InsertScriptParameter(Val ParameterName, Val ParameterValue, DoFormat, ParametersArea)
	
	If DoFormat Then
		ParameterValue = DoFormat(ParameterValue);
	ElsIf TypeOf(ParameterValue) = Type("Boolean") Then
		ParameterValue = ?(ParameterValue, "true", "false");
	EndIf;
	ParametersArea = StrReplace(ParametersArea, "[" + ParameterName + "]", ParameterValue);
	
EndProcedure

Function UpdateFilesNames(Parameters, FirstFileOnly = False)
	
	ParameterName = "StandardSubsystems.UpdateFilesNames";
	If ApplicationParameters.Get(ParameterName) <> Undefined Then
		If FirstFileOnly = True Then
			Return ApplicationParameters[ParameterName].NameOfFirstFile;
		ElsIf FirstFileOnly = False Then
			If ApplicationParameters[ParameterName].Property("FilesOfUpdate") Then
				Parameters.Insert("FilesOfUpdate", ApplicationParameters[ParameterName].FilesOfUpdate);
			EndIf;
			Return ApplicationParameters[ParameterName].FilesNames;
		EndIf;
		Return ApplicationParameters[ParameterName];
	EndIf;
	
	If Parameters.Property("UpdateFileRequired") And Not Parameters.UpdateFileRequired Then
		NameOfFirstFile = "";
		UpdateFilesNames = "";
	Else
		NameOfFirstFile = Null;
		If IsBlankString(Parameters.UpdateFileName) Then
			FilesNames = New Array;
			For Each UpdateFile In Parameters.FilesOfUpdate Do
				If NameOfFirstFile = Null Then
					NameOfFirstFile = UpdateFile.UpdateFileFullName;
				EndIf;
				UpdateFilePrefix = ?(UpdateFile.ExecuteUpdateHandlers, "+", "");
				FilesNames.Add(DoFormat(UpdateFilePrefix + UpdateFile.UpdateFileFullName));
			EndDo;
			UpdateFilesNames = StrConcat(FilesNames, ",");
		Else
			UpdateFilesNames = DoFormat(Parameters.UpdateFileName);
			NameOfFirstFile = Parameters.UpdateFileName;
		EndIf;
	EndIf;
	
	NameOfFirstFile = ?(NameOfFirstFile = Null, "", NameOfFirstFile);
	UpdateFilesNames = "[" + UpdateFilesNames + "]";
	
	If FirstFileOnly = True Then
		Return NameOfFirstFile;
	ElsIf FirstFileOnly = False Then
		Return UpdateFilesNames;
	EndIf;
	
	Result = New Structure;
	Result.Insert("NameOfFirstFile", NameOfFirstFile);
	Result.Insert("FilesNames", UpdateFilesNames);
	If Parameters.Property("FilesOfUpdate") Then
		Result.Insert("FilesOfUpdate", Parameters.FilesOfUpdate);
	EndIf;
	
	Return Result;
	
EndFunction

Function DoFormat(Val Text)
	Text = StrReplace(Text, "\", "\\");
	Text = StrReplace(Text, """", "\""");
	Text = StrReplace(Text, "'", "\'");
	Return "'" + Text + "'";
EndFunction

Function EncodingOfTheLogFile(Val BinDir)
	
	EncodingOfTheLogFile = "UTF-8";
	PartsOfTheProgramCatalog = StrSplit(BinDir, GetPathSeparator(), False);
	For Each ProgramVersionNumber In PartsOfTheProgramCatalog Do
		PartsOfTheProgramVersionNumber = StrSplit(ProgramVersionNumber, ".", False);
		If PartsOfTheProgramVersionNumber.Count() <> 4 Then
			Continue;	
		EndIf;
		ThisIsTheVersionNumber = True;
		For Each PartOfTheProgramVersionNumber In PartsOfTheProgramVersionNumber Do
			If Not IsNumber(PartOfTheProgramVersionNumber) Then
				ThisIsTheVersionNumber = False;
				Break;	
			EndIf;
		EndDo;
		If Not ThisIsTheVersionNumber Then
			Continue;	
		EndIf;
	EndDo;
	Return EncodingOfTheLogFile;

EndFunction

Function IsNumber(Val ValueToCheck)
	
	If ValueToCheck = "0" Then
		Return True;
	EndIf;
	
	NumberDetails = New TypeDescription("Number");
	Return NumberDetails.AdjustValue(ValueToCheck) <> 0;
	
EndFunction

Function GetUpdateAdministratorAuthenticationParameters(AdministrationParameters)
	
	Result = New Structure("StringForConnection, InfoBaseConnectionString");
	
	ClusterPort = AdministrationParameters.ClusterPort;
	CurrentConnections = IBConnectionsServerCall.ConnectionsInformation(True,
		ApplicationParameters["StandardSubsystems.MessagesForEventLog"], ClusterPort);
	
	ConnectionString = CurrentConnections.InfoBaseConnectionString;
	PathToTheDatabase = "";
	If StrFind(ConnectionString, "'") > 0 Then
		FileInfobase1 = CommonClient.FileInfobase(ConnectionString);
		If FileInfobase1 Then
			PathToTheDatabase = StrReplace(StrReplace(ConnectionString, "File=", ""), ";", "");
			ErrorText = NStr("vi = 'Không thể thực hiện cập nhật sang phiên bản mới của ứng dụng, bởi vì thư mục
				|của cơ sở thông tin có ký tự dấu ngoặc đơn không hợp lệ "" '' "":
				|%1%2';
				|ru = 'Невозможно выполнить обновление на новую версию приложения, т.к. каталог
				|информационной базы содержит недопустимый символ одинарной кавычки "" '' "":
				|%1%2';
				|en = 'Cannot update the application as the infobase
				|directory contains an incorrect single quote character "" '' "":
				|%1%2'; fa = 'Cannot update the application as the infobase
				|directory contains an incorrect single quote character "" '' "":
				|%1%2';
				|it = 'Невозможно выполнить обновление на новую версию приложения, т.к. каталог
				|информационной базы содержит недопустимый символ одинарной кавычки "" '' "":
				|%1%2';
				|pl = 'Cannot update the application as the infobase
				|directory contains an incorrect single quote character "" '' "":
				|%1%2';
				|tr = 'Infobase dizini geçersiz tek tırnak karakteri "" '' "" içerdiğinden dolayı
				|uygulama yeni sürüme yükseltilemiyor:
				|%1%2'");
			Postfix = NStr("vi = 'Hãy sắp xếp cơ sở thông tin vào thư mục khác và thử lại cập nhật.';
							|ru = 'Переместите информационную базу в другой каталог и повторите попытку обновления.';
							|en = 'Move the infobase to another directory and retry the update.'; fa = 'Move the infobase to another directory and retry the update.';
							|it = 'Переместите информационную базу в другой каталог и повторите попытку обновления.';
							|pl = 'Move the infobase to another directory and retry the update.';
							|tr = 'Infobase''i başka bir dizine taşıyın ve güncellemeyi tekrar deneyin.'");
		Else
			PathToTheDatabase = ConnectionString;
			ErrorText = NStr("vi = 'Không thể thực hiện cập nhật sang phiên bản mới của ứng dụng, bởi vì trong địa chỉ
				|của dịch vụ hoặc tên cơ sở thông tin có ký tự dấu ngoặc đơn không hợp lệ "" '' "":
				|%1%2';
				|ru = 'Невозможно выполнить обновление на новую версию приложения, т.к. в адресе
				|сервера или имени информационной базы содержится недопустимый символ одинарной кавычки "" '' "":
				|%1%2';
				|en = 'Cannot update the application as the server address
				|or the infobase name contains an incorrect single quote character "" '' "":
				|%1%2'; fa = 'Cannot update the application as the server address
				|or the infobase name contains an incorrect single quote character "" '' "":
				|%1%2';
				|it = 'Невозможно выполнить обновление на новую версию приложения, т.к. в адресе
				|сервера или имени информационной базы содержится недопустимый символ одинарной кавычки "" '' "":
				|%1%2';
				|pl = 'Cannot update the application as the server address
				|or the infobase name contains an incorrect single quote character "" '' "":
				|%1%2';
				|tr = 'Sunucu adresi veya infobase adı geçersiz tek tırnak karakteri "" '' "" içerdiğinden dolayı
				|uygulama yeni sürüme yükseltilemiyor:
				|%1%2'");
			Postfix = NStr("vi = 'Hãy sắp xếp cơ sở thông tin sang dịch vụ khác hoặc đổi lại tên, sau đó thử lại cập nhật.';
							|ru = 'Переместите информационную базу на другой сервер или переименуйте ее, затем повторите попытку обновления.';
							|en = 'Move the infobase to another server or rename it and then retry the update.'; fa = 'Move the infobase to another server or rename it and then retry the update.';
							|it = 'Переместите информационную базу на другой сервер или переименуйте ее, затем повторите попытку обновления.';
							|pl = 'Move the infobase to another server or rename it and then retry the update.';
							|tr = 'Infobase''i başka bir sunucuya taşıyın veya yeniden adlandırın, ardından güncellemeyi tekrar deneyin.'");
		EndIf;
		ErrorText = StrConcat(StrSplit(ErrorText, Chars.LF), " ");
		
		ErrorText = ErrorText + Chars.LF + Chars.LF + Postfix;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Chars.LF, PathToTheDatabase);
		
		Raise ErrorText;
	EndIf;
	
	Result.InfoBaseConnectionString = CurrentConnections.InfoBaseConnectionString;
	Result.StringForConnection = "Usr=""{0}"";Pwd=""{1}""";
	
	Return Result;
	
EndFunction

Function ScheduleServiceTaskName(Val TaskCode)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Cập nhật cấu hình (%1)';
																		|ru = 'Обновление конфигурации (%1)';
																		|en = 'Update configuration (%1)'; fa = 'Update configuration (%1)';
																		|it = 'Aggiornamento della configurazione (%1)';
																		|pl = 'Aktualizacja konfiguracji (%1)';
																		|tr = 'Yapılandırmayı güncelle (%1)'"), Format(TaskCode, "NG=0"));
	
EndFunction

Function StringUnicode(String)
	
	Result = "";
	
	For CharacterNumber = 1 To StrLen(String) Do
		
		Char = Format(CharCode(Mid(String, CharacterNumber, 1)), "NG=0");
		Char = StringFunctionsClientServer.SupplementString(Char, 4);
		Result = Result + Char;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the event name for writing to the event log.
Function EventLogEvent() Export
	Return NStr("vi = 'Cập nhật cấu hình';
				|ru = 'Обновление конфигурации';
				|en = 'Configuration update'; fa = 'به‌روزرسانی پیکربندی';
				|it = 'Aggiornamento della configurazione';
				|pl = 'Aktualizacja konfiguracji';
				|tr = 'Yapılandırma güncellemesi'", CommonClient.DefaultLanguageCode());
EndFunction

// Checks whether a configuration update is available at startup.
//
Procedure CheckForConfigurationUpdate()
	
	If Not CommonClient.IsWindowsClient() Then
		Return;
	EndIf;
	
#If Not WebClient And Not MobileClient Then
	If CommonClient.DataSeparationEnabled()
	 Or Not CommonClient.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientRunParameters.Property("ShowInvalidHandlersMessage") Then
		Return; // Update results form will be shown later.
	EndIf;
	
	SettingsOfUpdate = ClientRunParameters.SettingsOfUpdate;
	UpdateAvailability = SettingsOfUpdate.CheckPreviousInfobaseUpdates;
	
	If UpdateAvailability Then
		// The previous update must be completed.
		OpenForm("DataProcessor.ApplicationUpdateResult.Form.ApplicationUpdateResult");
		Return;
	EndIf;
	
	If SettingsOfUpdate.ConfigurationChanged Then
		ShowUserNotification(NStr("vi = 'Cập nhật cấu hình';
									|ru = 'Обновление конфигурации';
									|en = 'Configuration update'; fa = 'به‌روزرسانی پیکربندی';
									|it = 'Aggiornamento della configurazione';
									|pl = 'Aktualizacja konfiguracji';
									|tr = 'Yapılandırma güncellemesi'"),
			"e1cib/app/DataProcessor.InstallUpdates",
			NStr("vi = 'Cấu hình khác với cấu hình chính cơ sở thông tin.';
				|ru = 'Конфигурация отличается от основной конфигурации информационной базы.';
				|en = 'The configuration is different from the main infobase configuration.'; fa = 'The configuration is different from the main infobase configuration.';
				|it = 'La configurazione è diversa dalla configurazione di base di informazioni.';
				|pl = 'Konfiguracja różni się od podstawowej konfiguracji bazy informacyjnej.';
				|tr = 'Yapılandırma, Infobase''in temel yapılandırmasından farklıdır.'"), 
			PictureLib.DialogInformation);
	EndIf;
	
#EndIf

EndProcedure

#If Not WebClient And Not MobileClient Then

Procedure ReadDataToEventLog(UpdateResult, ScriptDirectory)
	
	UpdateResult = Undefined;
	ErrorOccurredDuringUpdate = False;
	
	FilesArray = FindFiles(ScriptDirectory, "log*.txt");
	
	If FilesArray.Count() = 0 Then
		Return;
	EndIf;
	
	LogFile = FilesArray[0];
	
	TextDocument = New TextDocument;
	TextDocument.Read(LogFile.FullName);
	
	For LineNumber = 1 To TextDocument.LineCount() Do
		
		CurrentRow = TextDocument.GetLine(LineNumber);
		If IsBlankString(CurrentRow) Then
			Continue;
		EndIf;
		
		LevelPresentation = "Information";
		If Mid(CurrentRow, 3, 1) = "." And Mid(CurrentRow, 6, 1) = "." Then // A string with a date.
			RowArray = StrSplit(CurrentRow, " ", False);
			DateArray = StrSplit(RowArray[0], ".");
			TimeArray = StrSplit(RowArray[1], ":");
			EventDate = Date(DateArray[2], DateArray[1], DateArray[0], TimeArray[0], TimeArray[1], TimeArray[2]);
			If RowArray[2] = "{ERR}" Then
				LevelPresentation = "Error";
				ErrorOccurredDuringUpdate = True;
			EndIf;
			
			Comment = TrimAll(Mid(CurrentRow, StrFind(CurrentRow, "}") + 2));
			If StrStartsWith(Comment, "UpdateSuccessful") 
				Or Comment = "RefreshEnabled completed2" Then // ACC:1297 Do not localize (a part of a log); for compatibility purposes.
				UpdateResult = True;
				Continue;
			ElsIf StrStartsWith(Comment, "UpdateNotExecuted")  
				Or Comment = "RefreshEnabled not completed2" Then // ACC:1297 Do not localize (a part of a log); for compatibility purposes.
				UpdateResult = False;
				Continue;
			EndIf;
			
			For NextLineNumber = LineNumber + 1 To TextDocument.LineCount() Do
				CurrentRow = TextDocument.GetLine(NextLineNumber);
				If Mid(CurrentRow, 3, 1) = "." And Mid(CurrentRow, 6, 1) = "." Then
					// The next line is a new event line.
					LineNumber = NextLineNumber - 1;
					Break;
				EndIf;
				
				Comment = Comment + Chars.LF + CurrentRow;
			EndDo;
			
			EventLogClient.AddMessageForEventLog(EventLogEvent(), 
				LevelPresentation, Comment, EventDate);
			
		EndIf;
		
	EndDo;
	
	// When updating SSL from a version earlier than 2.3.1.6, then see if update errors
	// - occur as the following events might be missing from the event log:
	// - Updated successfully
	// - Update failed
	If UpdateResult = Undefined Then 
		UpdateResult = Not ErrorOccurredDuringUpdate;
	EndIf;
	
	EventLogClient.WriteEventsToEventLog();

EndProcedure

Function UpdateProgramFilesEncoding()
	
	// wscript.exe can process only UTF-16 LE-encoded files.
	Return TextEncoding.UTF16;
	
EndFunction

Function PatchesFilesNames(Parameters, TempFilesDir)
	
	ParameterName = "StandardSubsystems.PatchesFilesNames";
	If ApplicationParameters.Get(ParameterName) <> Undefined Then
		Return ApplicationParameters[ParameterName];
	EndIf;
	
	FilesNames = New Array;
	For Each PatchFileName In Parameters.PatchesFiles Do
		If StrEndsWith(PatchFileName, ".cfe") Then
			ArchiveName = TempFilesDir + StrReplace(String(New UUID),"-", "") + ".zip";
			WriteArchive = New ZipFileWriter(ArchiveName);
			WriteArchive.Add(PatchFileName);
			WriteArchive.Write();
			
			FilesNames.Add(DoFormat(ArchiveName));
		Else
			FilesNames.Add(DoFormat(PatchFileName));
		EndIf;
	EndDo;
	PatchesFilesNames = StrConcat(FilesNames, ",");
	
	Return "[" + PatchesFilesNames + "]";
	
EndFunction

Function PatchesInformation(Parameters, TempFilesDir)
	
	ParameterName = "StandardSubsystems.PatchesInformation";
	If ApplicationParameters.Get(ParameterName) <> Undefined Then
		Return ApplicationParameters[ParameterName];
	EndIf;
	
	PatchesToInstall1 = "['']";
	PatchesToDelete = "['']";
	If Parameters.Property("PatchesFiles") Then
		PatchesToInstall1 = PatchesFilesNames(Parameters, TempFilesDir);
	ElsIf Parameters.Property("Corrections") Then
		If Parameters.Corrections.Property("Set")
			And Parameters.Corrections.Set.Count() > 0 Then
			FilesNames = New Array;
			For Each NewPatch In Parameters.Corrections.Set Do
				ArchiveName = TempFilesDir + StrReplace(String(New UUID),"-", "") + ".zip";
				Data = GetFromTempStorage(NewPatch); // BinaryData
				Data.Write(ArchiveName);
				FilesNames.Add(DoFormat(ArchiveName));
			EndDo;
			PatchesToInstall1 = StrConcat(FilesNames, ",");
			PatchesToInstall1 = "[" + PatchesToInstall1 + "]";
		EndIf;
		
		If Parameters.Corrections.Property("Delete")
			And Parameters.Corrections.Delete.Count() > 0 Then
			PatchesToDelete = "'" + StrConcat(Parameters.Corrections.Delete, "','") + "'";
			PatchesToDelete = "[" + PatchesToDelete + "]";
		EndIf;
	EndIf;
	
	PatchesInformation = New Structure;
	PatchesInformation.Insert("Set", PatchesToInstall1);
	PatchesInformation.Insert("Delete", PatchesToDelete);
	
	Return PatchesInformation;
	
EndFunction

Function GenerateUpdateScriptFiles(Val InteractiveMode, Parameters, AdministrationParameters)
	
	IsFileInfobase = CommonClient.FileInfobase();
	
	PlatformDirectory = Undefined;
	Parameters.Property("PlatformDirectory", PlatformDirectory);
	BinDir = ?(ValueIsFilled(PlatformDirectory), PlatformDirectory, BinDir());
	
	DesignerExecutableFileName = BinDir + StandardSubsystemsClient.ApplicationExecutableFileName(True);
	ClientExecutableFileName = BinDir + StandardSubsystemsClient.ApplicationExecutableFileName();
	COMConnectorPath = BinDir() + "comcntr.dll";
	COMConnectorName = CommonClientServer.COMConnectorName();
	EncodingOfTheLogFile = EncodingOfTheLogFile(BinDir);
	UseCOMConnector = Not (StandardSubsystemsClient.IsBaseConfigurationVersion()
		Or StandardSubsystemsClient.IsTrainingPlatform());
	
	ScriptParameters = GetUpdateAdministratorAuthenticationParameters(AdministrationParameters);
	InfoBaseConnectionString = ScriptParameters.InfoBaseConnectionString + ScriptParameters.StringForConnection;
	If StrEndsWith(InfoBaseConnectionString, ";") Then
		InfoBaseConnectionString = Left(InfoBaseConnectionString, StrLen(InfoBaseConnectionString) - 1);
	EndIf;
	
	// Determining path to the infobase.
	InfobasePath = IBConnectionsClientServer.InfobasePath(, AdministrationParameters.ClusterPort);
	InfobasePathParameter = ?(IsFileInfobase, "/F", "/S") + InfobasePath;
	InfobasePathString = ?(IsFileInfobase, InfobasePath, "");
	InfobasePathString = CommonClientServer.AddLastPathSeparator(StrReplace(InfobasePathString, """", "")) + "1Cv8.1CD";
	
	Email = ?(Parameters.UpdateMode = 2 And Parameters.EmailReport, Parameters.Email, "");
	
	// Instead of "GetTempFileName", use "TempFilesDir" since the directory shouldn't be auto-deleted when the client app exits. 
	// Reason: the executable files, runtime log, and backup (if configured) are saved to this directory.
	// 
	TempFilesDirForUpdate = TempFilesDir() + "1Cv8Update." + Format(CommonClient.SessionDate(), "DF=yyMMddHHmmss") + "\";
	
	If Parameters.CreateDataBackup = 1 Then 
		BackupDirectory = TempFilesDirForUpdate;
	ElsIf Parameters.CreateDataBackup = 2 Then 
		BackupDirectory = CommonClientServer.AddLastPathSeparator(Parameters.IBBackupDirectoryName);
	Else 
		BackupDirectory = "";
	EndIf;
	
	UserNotificationInterval = 0;
	If Parameters.Property("UserNotificationInterval") Then
		UserNotificationInterval = Parameters.UserNotificationInterval;
	EndIf;
	
	CreateDataBackup = IsFileInfobase And (Parameters.CreateDataBackup = 1 Or Parameters.CreateDataBackup = 2);
	
	ExecuteDeferredHandlers = False;
	IsDeferredUpdate = (Parameters.UpdateMode = 2);
	TemplatesTexts = ConfigurationUpdateServerCall.TemplatesTexts(ApplicationParameters["StandardSubsystems.MessagesForEventLog"], 
		InteractiveMode, ExecuteDeferredHandlers, IsDeferredUpdate);
	UserName = AdministrationParameters.InfobaseAdministratorName;
	
	If IsDeferredUpdate Then 
		RandomNumberGenerator = New RandomNumberGenerator;
		TaskCode = Format(RandomNumberGenerator.RandomNumber(1000, 9999), "NG=0");
		TaskName = ScheduleServiceTaskName(TaskCode);
	EndIf;
	
	OneCEnterpriseStartupParameters = CommonInternalClient.EnterpriseStartupParametersFromScript();
	
	PerformAConfigurationUpdate = Parameters.Property("ConfigurationChanged") And Parameters.ConfigurationChanged;
	DownloadExtensions = Parameters.Property("LoadExtensions") And Parameters.LoadExtensions;
	
	ParametersArea = TemplatesTexts.ParametersArea;
	InsertScriptParameter("DesignerExecutableFileName" , DesignerExecutableFileName          , True, ParametersArea);
	InsertScriptParameter("ClientExecutableFileName"       , ClientExecutableFileName                , True, ParametersArea);
	InsertScriptParameter("COMConnectorPath"               , COMConnectorPath                        , True, ParametersArea);
	InsertScriptParameter("EncodingOfTheLogFile"                 , EncodingOfTheLogFile                          , False, ParametersArea);
	InsertScriptParameter("InfobasePathParameter"   , InfobasePathParameter            , True, ParametersArea);
	InsertScriptParameter("InfobaseFilePathString", InfobasePathString              , True, ParametersArea);
	InsertScriptParameter("InfoBaseConnectionString", InfoBaseConnectionString         , True, ParametersArea);
	InsertScriptParameter("EventLogEvent"         , EventLogEvent()                , True, ParametersArea);
	InsertScriptParameter("Email"             , Email                      , True, ParametersArea);
	InsertScriptParameter("UpdateAdministratorName"       , UserName                            , True, ParametersArea);
	InsertScriptParameter("COMConnectorName"                 , COMConnectorName                          , True, ParametersArea);
	InsertScriptParameter("BackupDirectory"             , BackupDirectory                      , True, ParametersArea);
	InsertScriptParameter("CreateDataBackup"           , CreateDataBackup                    , False  , ParametersArea);
	InsertScriptParameter("RestoreInfobase" , Parameters.RestoreInfobase, False  , ParametersArea);
	InsertScriptParameter("BlockIBConnections"           , Not IsFileInfobase                         , False  , ParametersArea);
	InsertScriptParameter("UseCOMConnector"        , UseCOMConnector                 , False  , ParametersArea);
	InsertScriptParameter("StartSessionAfterUpdate"       , Not Parameters.ShouldExitApp       , False  , ParametersArea);
	InsertScriptParameter("CompressIBTables"           , IsFileInfobase                            , False  , ParametersArea);
	InsertScriptParameter("ExecuteDeferredHandlers"    , ExecuteDeferredHandlers             , False  , ParametersArea);
	InsertScriptParameter("TaskSchedulerTaskName"        , TaskName                                  , True, ParametersArea);
	InsertScriptParameter("OneCEnterpriseStartupParameters"       , OneCEnterpriseStartupParameters                , True, ParametersArea);
	InsertScriptParameter("UnlockCode1"                  , "IBConfigurationBatchUpdate"         , False,   ParametersArea);
	InsertScriptParameter("UserNotificationInterval"  , UserNotificationInterval           , False,   ParametersArea);
	InsertScriptParameter("PerformAConfigurationUpdate"   , PerformAConfigurationUpdate            , False,   ParametersArea);
	InsertScriptParameter("DownloadExtensions"       , DownloadExtensions                , False,   ParametersArea);
	
	CreateDirectory(TempFilesDirForUpdate);
	PatchesInformation = PatchesInformation(Parameters, TempFilesDirForUpdate);
	ParametersArea = StrReplace(ParametersArea, "[UpdateFilesNames]", UpdateFilesNames(Parameters));
	ParametersArea = StrReplace(ParametersArea, "[PatchesFilesNames]", PatchesInformation.Set);
	ParametersArea = StrReplace(ParametersArea, "[DeletedChangesNames]", PatchesInformation.Delete);
	
	If Parameters.Property("FilesOfUpdate") Then
		Parameters.Insert("VersionsRequiringSuccessfulUpdate", VersionsRequiringSuccessfulUpdate(Parameters.FilesOfUpdate));
	Else
		Parameters.Insert("VersionsRequiringSuccessfulUpdate", New Array);
	EndIf;
	
	TemplatesTexts.ConfigurationUpdateFileTemplate = ParametersArea + TemplatesTexts.ConfigurationUpdateFileTemplate;
	TemplatesTexts.Delete("ParametersArea");
	
	//
	WriteTextToFile(TempFilesDirForUpdate + "main.js", TemplatesTexts.ConfigurationUpdateFileTemplate);
	
	// Auxiliary file: helpers.js.
	WriteTextToFile(TempFilesDirForUpdate + "helpers.js", TemplatesTexts.AdditionalConfigurationUpdateFile);
	
	If InteractiveMode Then
		PictureLib.ExternalOperationSplash.Write(TempFilesDirForUpdate + "splash.png");
		PictureLib.ExternalOperationSplashIcon.Write(TempFilesDirForUpdate + "splash.ico");
		PictureLib.TimeConsumingOperation48.Write(TempFilesDirForUpdate + "progress.gif");

		MainScriptFileName = TempFilesDirForUpdate + "splash.hta";
		WriteTextToFile(MainScriptFileName, TemplatesTexts.ConfigurationUpdateSplash);
	Else
		MainScriptFileName = TempFilesDirForUpdate + "updater.js";
		WriteTextToFile(MainScriptFileName, TemplatesTexts.NonInteractiveConfigurationUpdate);
	EndIf;
	
	If IsDeferredUpdate Then 
		
		StartDate2 = Format(Parameters.UpdateDateTime, "DF=yyyy-MM-ddTHH:mm:ss");
		
		ScriptPath = StandardSubsystemsClient.SystemApplicationsDirectory() + "wscript.exe";
		ScriptParameters = StringFunctionsClientServer.SubstituteParametersToString("//nologo ""%1"" /p1:""%2"" /p2:""%3""",
			MainScriptFileName,
			StringUnicode(AdministrationParameters.InfobaseAdministratorPassword),
			StringUnicode(AdministrationParameters.ClusterAdministratorPassword));
		
		TaskDetails1 = NStr("vi = 'Cập nhật cấu hình 1C:Enterprise';
							|ru = 'Обновление конфигурации 1С:Предприятие';
							|en = 'Update 1C:Enterprise configuration'; fa = 'Update 1C:Enterprise configuration';
							|it = 'Aggiornamento di configurazione 1C:Enterprise';
							|pl = 'Aktualizacja konfiguracji 1C:Enterprise';
							|tr = '1C:Enterprise yapılandırma güncellemesi'");
		
		TaskSchedulerTaskCreationScript = TemplatesTexts.TaskSchedulerTaskCreationScript;
		
		InsertScriptParameter("StartDate2" , StartDate2, True, TaskSchedulerTaskCreationScript);
		InsertScriptParameter("ScriptPath" , ScriptPath, True, TaskSchedulerTaskCreationScript);
		InsertScriptParameter("ScriptParameters" , ScriptParameters, True, TaskSchedulerTaskCreationScript);
		InsertScriptParameter("TaskName" , TaskName, True, TaskSchedulerTaskCreationScript);
		InsertScriptParameter("TaskDetails1" , TaskDetails1, True, TaskSchedulerTaskCreationScript);
		
		TaskSchedulerTaskCreationScriptName = TempFilesDirForUpdate + "addsheduletask.js";
		WriteTextToFile(TaskSchedulerTaskCreationScriptName, TaskSchedulerTaskCreationScript);
		
		Parameters.SchedulerTaskCode = TaskCode;
		
		Parameters.Insert("TaskSchedulerTaskCreationScriptName", TaskSchedulerTaskCreationScriptName);
		
	EndIf;
	
	WriteTextToFile(TempFilesDirForUpdate + "templog.txt",
		StandardSubsystemsClient.SupportInformation(), TextEncoding.System);
	
	WriteTextToFile(TempFilesDirForUpdate + "add-delete-patches.js",
		TemplatesTexts.PatchesDeletionScript);
	
	Return MainScriptFileName;
	
EndFunction

Procedure WriteTextToFile(FullFileName, Text, Encoding = Undefined)
	
	If Encoding = Undefined Then
		Encoding = UpdateProgramFilesEncoding();
	EndIf;
	
	ScriptFile = New TextWriter(FullFileName, Encoding);
	ScriptFile.Write(Text);
	ScriptFile.Close();
	
EndProcedure

Function ParameterNameUpdateNow()
	
	Return "StandardSubsystems.ConfigurationUpdate.UpdateNow";
	
EndFunction

Function ParameterNameSkipExit()
	
	Return "StandardSubsystems.SkipQuitSystemAfterWarningsHandled";
	
EndFunction

// Returns:
//  Structure:
//   * Form - See InstallUpdate.Form
//   * Parameters - See InstallUpdate.Parameters
//   * AdministrationParameters - See InstallUpdate.AdministrationParameters
//
Function NewParametersUpdateNow(Form, Parameters, AdministrationParameters)
	
	Result = New Structure;
	Result.Insert("Form", Form);
	Result.Insert("Parameters", Parameters);
	Result.Insert("AdministrationParameters", AdministrationParameters);
	
	Return Result;
	
EndFunction

Procedure InstallUpdateNowStart(Form, Parameters, AdministrationParameters)
	
	ApplicationParameters.Insert(ParameterNameUpdateNow(),
		NewParametersUpdateNow(Form, Parameters, AdministrationParameters));
	
	AttachIdleHandler("WaitHandlerSetUpdateNow", 0.1, True);
	ApplicationParameters.Insert(ParameterNameSkipExit(), True);
	
EndProcedure

Procedure ScheduleConfigurationUpdate(Parameters, AdministrationParameters)
	
	GenerateUpdateScriptFiles(False, Parameters, AdministrationParameters);
	
	ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
	ApplicationStartupParameters.ExecuteWithFullRights = True;
	
	StartupCommand = New Array;
	StartupCommand.Add("wscript.exe");
	StartupCommand.Add("//nologo");
	StartupCommand.Add(Parameters.TaskSchedulerTaskCreationScriptName);
	
	FileSystemClient.StartApplication(StartupCommand, ApplicationStartupParameters);
	
	ParametersOfUpdate = ConfigurationUpdateServerCall.ParametersOfUpdate();
	ParametersOfUpdate.UpdateAdministratorName = UserName();
	ParametersOfUpdate.UpdateScheduled = True;
	ParametersOfUpdate.UpdateComplete = False;
	ParametersOfUpdate.ConfigurationUpdateResult = False;
	ConfigurationUpdateServerCall.WriteUpdateStatus(ParametersOfUpdate);
	
EndProcedure

Procedure WaitHandlerSetUpdateNowContinued() Export
	
	ApplicationParameters.Delete(ParameterNameSkipExit());
	
	ParametersUpdateNow = ApplicationParameters[ParameterNameUpdateNow()]; // See NewParametersUpdateNow
	If ParametersUpdateNow = Undefined Then
		Return;
	EndIf;
	
	Form = ParametersUpdateNow.Form;
	If TypeOf(Form) = Type("ClientApplicationForm") And Form.IsOpen() Then
		AttachIdleHandler("WaitHandlerSetUpdateNow", 0.1, True);
		ApplicationParameters.Insert(ParameterNameSkipExit(), True);
		Form.Close();
		Return;
	EndIf;
	
	ApplicationParameters.Delete(ParameterNameUpdateNow());
	DetachIdleHandler("WaitHandlerSetUpdateNow");
	
	RunUpdateScript(ParametersUpdateNow.Parameters,
		ParametersUpdateNow.AdministrationParameters);
	
EndProcedure

// Parameters:
//  Parameters - See InstallUpdate.Parameters
//  AdministrationParameters - See StandardSubsystemsServer.AdministrationParameters.
//
Procedure RunUpdateScript(Parameters, AdministrationParameters)
	
	Context = New Structure;
	Context.Insert("Parameters", Parameters);
	Context.Insert("AdministrationParameters", AdministrationParameters);
	
	FormParameters = New Structure("NameOfFirstUpdateFile",
		UpdateFilesNames(Parameters, True));
	
	Notification = New CallbackDescription("RunUpdateScriptAfterUpdateFileChecked",
		ThisObject, Context);
	
	Form = OpenForm("CommonForm.CheckUpdateFile", FormParameters,,,,,
		Notification, FormWindowOpeningMode.LockWholeInterface);
	
	If Form = Undefined Then
		RunUpdateScriptOnDataCleanUp(Context);
	ElsIf Not Form.IsOpen() Then
		RunUpdateScriptAfterUpdateFileChecked(Form.Result, Context);
	EndIf;
	
EndProcedure

// Parameters:
//  Context - Structure:
//   * Parameters - See InstallUpdate.Parameters
//   * AdministrationParameters - See StandardSubsystemsServer.AdministrationParameters.
//  Result - Boolean, Undefined
//
Procedure RunUpdateScriptAfterUpdateFileChecked(Result, Context) Export
	
	If Result = True Then
		RunUpdateScriptAfterObsoleteDataPurge(True, Context);
	Else
		RunUpdateScriptOnDataCleanUp(Context);
	EndIf;
	
EndProcedure

// Parameters:
//  Context - See RunUpdateScriptAfterUpdateFileChecked.Context
//
Procedure RunUpdateScriptOnDataCleanUp(Context)
	
	FullFormName = "DataProcessor.ApplicationUpdateResult.Form.ClearObsoleteData";
	
	Windows = GetWindows();
	For Each Window In Windows Do
		For Each Form In Window.Content Do
			If Form.FormName = FullFormName And Form.IsOpen() Then
				Form.Close();
			EndIf;
		EndDo;
	EndDo;
	
	Notification = New CallbackDescription("RunUpdateScriptAfterObsoleteDataPurge",
		ThisObject, Context);
	
	FormParameters = New Structure;
	FormParameters.Insert("ClearAndClose", True);
	
	OpenForm(FullFormName, FormParameters,,,,,
		Notification, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

// Parameters:
//  Result - Boolean, Undefined
//  Context - See RunUpdateScriptAfterUpdateFileChecked.Context
//
Procedure RunUpdateScriptAfterObsoleteDataPurge(Result, Context) Export
	
	If Result <> True Then
		If Result <> False Then
			ShowMessageBox(, NStr("vi = 'Đã hủy cập nhật cấu hình.';
									|ru = 'Обновление конфигурации отменено.';
									|en = 'Configuration update is canceled.'; fa = 'Configuration update is canceled.';
									|it = 'Обновление конфигурации отменено.';
									|pl = 'Configuration update is canceled.';
									|tr = 'Konfigürasyon güncellemesi iptal edildi.'"));
		EndIf;
		Return;
	EndIf;
	
	RunUpdateScriptCompletion(Context.Parameters, Context.AdministrationParameters);
	
EndProcedure

// Parameters:
//  Parameters - See InstallUpdate.Parameters
//  AdministrationParameters - See StandardSubsystemsServer.AdministrationParameters.
//
Procedure RunUpdateScriptCompletion(Parameters, AdministrationParameters)
	
	MainScriptFileName = GenerateUpdateScriptFiles(True, Parameters, AdministrationParameters);
	EventLogClient.AddMessageForEventLog(EventLogEvent(), "Information",
		NStr("vi = 'Đang thực hiện thủ tục cập nhật cấu hình:';
			|ru = 'Выполняется процедура обновления конфигурации:';
			|en = 'Updating the configuration:'; fa = 'Updating the configuration:';
			|it = 'The configuration update procedure is in progress:';
			|pl = 'Jest wykonywana procedura aktualizacji konfiguracji:';
			|tr = 'Güncelleme konfigürasyonu prosedürü gerçekleştiriliyor:'") + " " + MainScriptFileName);
	
	VersionsRequiringSuccessfulUpdate = New Array;
	If Parameters.Property("VersionsRequiringSuccessfulUpdate") Then
		VersionsRequiringSuccessfulUpdate = Parameters.VersionsRequiringSuccessfulUpdate;
	EndIf;
	
	ParametersOfUpdate = ConfigurationUpdateServerCall.ParametersOfUpdate();
	ParametersOfUpdate.UpdateAdministratorName = UserName();
	ParametersOfUpdate.UpdateScheduled = True;
	ParametersOfUpdate.UpdateComplete = False;
	ParametersOfUpdate.ConfigurationUpdateResult = False;
	ParametersOfUpdate.MainScriptFileName = MainScriptFileName;
	ParametersOfUpdate.VersionsRequiringSuccessfulUpdate = VersionsRequiringSuccessfulUpdate;
	ConfigurationUpdateServerCall.WriteUpdateStatus(ParametersOfUpdate,
		ApplicationParameters["StandardSubsystems.MessagesForEventLog"]);
	
	DontStopScenariosExecution();
	
	PathToLauncher = StandardSubsystemsClient.SystemApplicationsDirectory() + "mshta.exe";
	
	CommandLine1 = """%1"" ""%2"" [p1]%3[/p1][p2]%4[/p2]";
	CommandLine1 = StringFunctionsClientServer.SubstituteParametersToString(CommandLine1,
		PathToLauncher, MainScriptFileName,
		StringUnicode(AdministrationParameters.InfobaseAdministratorPassword),
		StringUnicode(AdministrationParameters.ClusterAdministratorPassword));
	
	ReturnCode = Undefined;
	RunApp(CommandLine1,,, ReturnCode); // ACC:534 Start update script.
	StandardSubsystemsClient.SkipExitConfirmation();
	Exit(False);
	
EndProcedure

Procedure DontStopScenariosExecution()
	
	Shell = New COMObject("Wscript.Shell");
	Shell.RegWrite("HKCU\Software\Microsoft\Internet Explorer\Styles\MaxScriptStatements", 1107296255, "REG_DWORD");

EndProcedure

#EndIf

// Returns True if Designer is available.
//
// See Common.DebugMode
//
// Returns:
//  Boolean - True if Designer is available.
//
Function DesignerBatchModeSupported()
	
#If WebClient Or MobileClient Then
	Return False;
#Else
	Designer1 = BinDir() + StandardSubsystemsClient.ApplicationExecutableFileName(True);
	DesignerFile = New File(Designer1);
	Return DesignerFile.Exists(); // ACC:566 Synchronous calls outside of the web client are allowed.
#EndIf
	
EndFunction

#EndRegion