///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

///////////////////////////////////////////////////////////////////////////////////////////////////////
// The external resource locking mechanism:
// - Disables the scheduled jobs that access external resources.
// - Disconnects the infobase from the Collaboration server (if "Conversations" subsystem is integrated).
// The lock is set if:
// - User signs in to the app.
// - A scheduled job that accesses external resources has started.
// The lock is always set automatically.
// The administrator can confirm the lock or unlock the infobase.
//
//  "BeforeStart" or "OnStartExecuteScheduledJob" obtains the session parameter
// "OperationsWithExternalResourcesLocked", and calls the
// "OnSetSessionParameters" event in the lock object if the environment has changed.
//
// "OnStartExecuteScheduledJob" disables the scheduled jobs if the session parameter's state is locked.
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Function OperationsWithExternalResourcesLocked() Export
	
	Return SessionParameters.OperationsWithExternalResourcesLocked;
	
EndFunction

Procedure AllowExternalResources() Export
	
	BeginTransaction();
	Try
		BlockLockParametersData();
		
		LockParameters = SavedLockParameters();
		EnableDisabledScheduledJobs(LockParameters);
		
		NewLockParameters = CurrentLockParameters();
		NewLockParameters.CheckServerName = LockParameters.CheckServerName;
		SaveLockParameters(NewLockParameters);
		
		If Common.FileInfobase() Then
			WriteFileInfobaseIDToCheckFile(NewLockParameters.TheDatabaseID);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SSLSubsystemsIntegration.WhenAllowingWorkWithExternalResources();
	ExternalResourcesOperationsLockOverridable.WhenAllowingWorkWithExternalResources();
	
	SessionParameters.OperationsWithExternalResourcesLocked = False;
	
	RefreshReusableValues();
	
EndProcedure

Procedure DenyExternalResources() Export
	
	BeginTransaction();
	Try
		InfoBaseID = New UUID();
		Constants.InfoBaseID.Set(String(InfoBaseID));
		
		BlockLockParametersData();
		
		LockParameters = SavedLockParameters();
		LockParameters.TheDatabaseID = InfoBaseID;
		LockParameters.OperationsWithExternalResourcesLocked = True;
		SaveLockParameters(LockParameters);
		
		If Common.FileInfobase() Then
			WriteFileInfobaseIDToCheckFile(LockParameters.TheDatabaseID);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	SSLSubsystemsIntegration.WhenYouAreForbiddenToWorkWithExternalResources();
	ExternalResourcesOperationsLockOverridable.WhenYouAreForbiddenToWorkWithExternalResources();
	
	SessionParameters.OperationsWithExternalResourcesLocked = True;
	
	RefreshReusableValues();
	
EndProcedure

Procedure SetServerNameCheckInLockParameters(CheckServerName) Export
	
	BeginTransaction();
	Try
		BlockLockParametersData();
		
		LockParameters = SavedLockParameters();
		LockParameters.CheckServerName = CheckServerName;
		SaveLockParameters(LockParameters);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure OnEnableAccessToWebServices() Export
	
	BeginTransaction();
	Try
		BlockLockParametersData();
		
		LockParameters = SavedLockParameters();
		EnableDisabledScheduledJobs(LockParameters, True);
		
		NewLockParameters = CurrentLockParameters();
		SaveLockParameters(NewLockParameters);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#Region EventsSubscriptionsHandlers

Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	Handlers.Insert("OperationsWithExternalResourcesLocked",
		"ExternalResourcesOperationsLock.OnSetSessionParameters");
	
EndProcedure


// Parameters:
//  ParameterName - String
//  SpecifiedParameters - See StandardSubsystemsServer.SessionParametersSetting
//
Procedure OnSetSessionParameters(ParameterName, SpecifiedParameters) Export 
	
	If ParameterName = "OperationsWithExternalResourcesLocked" Then
		
		BeginTransaction();
		Try
			
			SessionParameters.OperationsWithExternalResourcesLocked = SetExternalResourcesOperationsLock();
			SpecifiedParameters.Add("OperationsWithExternalResourcesLocked");
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
	EndIf;
	
EndProcedure

Procedure OnStartExecuteScheduledJob(ScheduledJob) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	JobStartAllowed = Common.SystemSettingsStorageLoad(
		"ScheduledJobs", 
		ScheduledJob.MethodName);
	
	If JobStartAllowed = True Then
		Return;
	EndIf;
	
	WorkingWithExternalResources = ScheduledJobUsesExternalResources(ScheduledJob);
	LockForManagingExternalResources = WorkingWithExternalResources.UseExternalResources
		And OperationsWithExternalResourcesLocked();
	LockForAccessToExternalResources = Not LockForManagingExternalResources
		And Not Common.AccessToInternetServicesAllowed()
		And WorkingWithExternalResources.CanAccessExternalResources;
	
	If Not LockForManagingExternalResources And Not LockForAccessToExternalResources Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		BlockLockParametersData();
		
		LockParameters = SavedLockParameters();
		DisableScheduledJob1(LockParameters, ScheduledJob, LockForAccessToExternalResources);
		SaveLockParameters(LockParameters);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If LockForAccessToExternalResources Then
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1
				           |Nhiệm vụ thường kỳ ""%2"" truy cập đến nguồn ngoài, bị tắt sử dụng.';
				           |ru = '%1
				           |Регламентное задание ""%2"", обращающееся к внешним ресурсам, отключено.';
				           |en = '%1
				           |Scheduled job ""%2"" accessing external resources has been disabled.'; fa = '%1
				           |Scheduled job ""%2"" accessing external resources has been disabled.';
				           |it = '%1
				           |Scheduled job ""%2"" accessing external resources has been disabled.';
				           |pl = '%1
				           |Scheduled job ""%2"" accessing external resources has been disabled.';
				           |tr = '%1
				           |Harici kaynaklara erişen ""%2"" zamanlanmış görevi devre dışı bırakılır.'"),
				Common.AccessToInternetServicesDeniedMessageText(),
				ScheduledJob.Synonym);
	ElsIf Common.DataSeparationEnabled() Then
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Ứng dụng đã được di chuyển.
				           |Công việc thường xuyên ""%1"", làm việc với các tài nguyên bên ngoài đã bị vô hiệu hóa.';
				           |ru = 'Приложение было перемещено.
				           |Регламентное задание ""%1"", работающее с внешними ресурсами, отключено.';
				           |en = 'The application has been moved.
				           |The ""%1"" scheduled job, which requires online activities, is disabled.'; fa = 'The application has been moved.
				           |The ""%1"" scheduled job, which requires online activities, is disabled.';
				           |it = 'L''applicazione è stata spostata.
				           |Il task di routine ""%1"", che lavorava con le risorse esterne, è stato disattivato.';
				           |pl = 'Aplikacja została przeniesiona.
				           |Planowe zadanie ""%1"",działające z zewnętrznymi zasobami, zostało wyłączone.';
				           |tr = 'Uygulama taşındı.
				           |Dış kaynaklarla çalışan Zamanlanmış görev ""%1"", kapatıldı.'"), 
				ScheduledJob.Synonym);
	Else 
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Dòng kết nối infobase đã thay đổi.
				           |Có thể infobase đã được di chuyển.
				           |Công việc thường xuyên ""%1"" đã bị tắt.';
				           |ru = 'Изменилась строка соединения информационной базы.
				           |Возможно информационная база была перемещена.
				           |Регламентное задание ""%1"" отключено.';
				           |en = 'The infobase connection string has changed.
				           |The infobase might have been moved.
				           |The ""%1"" scheduled job is disabled.'; fa = 'The infobase connection string has changed.
				           |The infobase might have been moved.
				           |The ""%1"" scheduled job is disabled.';
				           |it = 'È stata modificata la riga di collegamento al database.
				           |È possibile che il database sia stato spostato.
				           |Task di routine ""%1"" disattivato.';
				           |pl = 'Zmienił się ciąg połączenia bazy informacyjnej.
				           |Możliwie, że baza informacyjna została przeniesiona.
				           |Planowe zadanie ""%1"" zostało wyłączone.';
				           |tr = 'Infobase''in bağlantı satırı değişti.
				           |Infobase taşınmış olabilir.
				           |Zamanlanmış görev ""%1"" devre dışı bırakıldı.'"), 
				ScheduledJob.Synonym);
	EndIf;
	
	ScheduledJobsServer.CancelJobExecution(ScheduledJob, ExceptionText);
	
	Raise ExceptionText;
	
EndProcedure

Procedure OnAddClientParametersOnStart(ClientRunParameters, IsCallBeforeStart) Export
	
	ShowLockForm = False;
	
	If IsCallBeforeStart And OperationsWithExternalResourcesLocked() Then
		LockParameters = SavedLockParameters();
		
		FlagOfNecessityToFinalizeDecisionIsSet = 
			LockParameters.OperationsWithExternalResourcesLocked = Undefined;
		
		ShowLockForm = FlagOfNecessityToFinalizeDecisionIsSet And Users.IsFullUser();
	EndIf;
	
	ClientRunParameters.Insert("ShowExternalResourceLockForm", ShowLockForm);
	
EndProcedure

Procedure AfterImportData(Container) Export
	
	If Common.DataSeparationEnabled() Then
		LockParameters = CurrentLockParameters();
		SaveLockParameters(LockParameters);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region UpdateHandlers

Procedure UpdateExternalResourceAccessLockParameters() Export
	
	BeginTransaction();
	Try
		BlockLockParametersData();
		
		LockParameters = SavedLockParameters();
		
		DataSeparationEnabled = Common.DataSeparationEnabled();
		LockParameters.DataSeparationEnabled = DataSeparationEnabled;
		If DataSeparationEnabled Then
			LockParameters.ConnectionString = "";
			LockParameters.ComputerName = "";
		EndIf;
		
		SaveLockParameters(LockParameters);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region LockParameters

Function CurrentLockParameters()
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	ConnectionString = ?(DataSeparationEnabled, "", InfoBaseConnectionString());
	ComputerName = ?(DataSeparationEnabled, "", ComputerName());
	
	Result = New Structure;
	Result.Insert("TheDatabaseID", StandardSubsystemsServer.InfoBaseID());
	Result.Insert("IsFileInfobase", Common.FileInfobase());
	Result.Insert("DataSeparationEnabled", DataSeparationEnabled);
	Result.Insert("ConnectionString", ConnectionString);
	Result.Insert("ComputerName", ComputerName);
	Result.Insert("CheckServerName", True);
	Result.Insert("OperationsWithExternalResourcesLocked", False);
	Result.Insert("DisabledJobs", New Array);
	Result.Insert("DisabledJobsWhenAccessToWebServicesDisabled", New Array);
	Result.Insert("LockReason", "");
	
	Return Result;
	
EndFunction

Function SavedLockParameters() Export 
	
	SetPrivilegedMode(True);
	SavedParameters = Constants.ExternalResourceAccessLockParameters.Get().Get();
	SetPrivilegedMode(False);
	
	Result = CurrentLockParameters();
	
	If SavedParameters = Undefined Then 
		SaveLockParameters(Result); // Automatic initialization.
		If Common.FileInfobase() Then
			WriteFileInfobaseIDToCheckFile(Result.TheDatabaseID);
		EndIf;
	EndIf;
	
	If TypeOf(SavedParameters) = Type("Structure") Then 
		FillPropertyValues(Result, SavedParameters); // Reinitializing new properties.
	EndIf;
	
	Return Result;
	
EndFunction

Procedure BlockLockParametersData()
	
	Block = New DataLock;
	Block.Add("Constant.ExternalResourceAccessLockParameters");
	Block.Lock();
	
EndProcedure

Procedure SaveLockParameters(LockParameters)
	
	SetPrivilegedMode(True);
	
	ValueStorage = New ValueStorage(LockParameters, New Deflation(9));
	Constants.ExternalResourceAccessLockParameters.Set(ValueStorage);
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region ScheduledJobs

Function ScheduledJobUsesExternalResources(ScheduledJob)
	
	Result = New Structure("UseExternalResources, CanAccessExternalResources", False, False);
	
	JobDependencies = ScheduledJobsInternal.ScheduledJobsDependentOnFunctionalOptions();
	
	Filter = New Structure;
	Filter.Insert("ScheduledJob", ScheduledJob);
	Filter.Insert("UseExternalResources", True);
	
	FoundRows = JobDependencies.FindRows(Filter);
	If FoundRows.Count() <> 0 Then
		Result.UseExternalResources = True;
		Result.CanAccessExternalResources = True;
		Return Result;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("ScheduledJob", ScheduledJob);
	Filter.Insert("CanAccessExternalResources", True);
	
	FoundRows = JobDependencies.FindRows(Filter);
	If FoundRows.Count() <> 0 Then
		Result.CanAccessExternalResources = True;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure DisableScheduledJob1(LockParameters, ScheduledJob, LockForAccessToExternalResources)
	
	Filter = New Structure;
	Filter.Insert("Metadata", ScheduledJob);
	Filter.Insert("Use", True);
	
	FoundJobs = ScheduledJobsServer.FindJobs(Filter);
	
	For Each Job In FoundJobs Do
		ScheduledJobsServer.ChangeJob(Job, New Structure("Use", False));
		If LockForAccessToExternalResources Then
			LockParameters.DisabledJobsWhenAccessToWebServicesDisabled.Add(Job.UUID);
		Else
			LockParameters.DisabledJobs.Add(Job.UUID);
		EndIf;
	EndDo;
	
EndProcedure

Procedure EnableDisabledScheduledJobs(LockParameters, UnlockToAccessWebServices = False)
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	If UnlockToAccessWebServices Then
		DisabledJobs = LockParameters.DisabledJobsWhenAccessToWebServicesDisabled;
	Else
		DisabledJobs = LockParameters.DisabledJobs;
	EndIf;
	
	For Each JobID In DisabledJobs Do
		
		If DataSeparationEnabled = (TypeOf(JobID) = Type("UUID")) Then
			Continue;
		EndIf;
		
		Filter = New Structure;
		Filter.Insert("UUID", JobID);
		Filter.Insert("Use", False);
		
		FoundJobs = ScheduledJobsServer.FindJobs(Filter);
		
		For Each Job In FoundJobs Do
			ScheduledJobsServer.ChangeJob(Job, New Structure("Use", True));
			DisabledJobs.Add(Job.UUID);
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FileInfobaseIDCheckFile

Function FileInfobaseIDCheckFileExists()
	
	FileInfo3 = New File(PathToFileInfobaseIDCheckFile());
	Return FileInfo3.Exists();
	
EndFunction

Function FileInfobaseIDFromCheckFile()
	
	TextReader = New TextReader(PathToFileInfobaseIDCheckFile());
	TheDatabaseID = TextReader.ReadLine();
	TextReader.Close();
	Return TheDatabaseID;
	
EndFunction

Procedure WriteFileInfobaseIDToCheckFile(TheDatabaseID)
	
	FileContent = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1
		           |
		           |Tệp được tạo tự động bởi giải pháp ứng dụng ""%2"".
		           |Nó chứa tên cơ sở thông tin và cho phép bạn xác định rằng, cơ sở thông tin này đã được sao chép. 
		           |
		           |Khi sao chép tệp của cơ sở thông tin, bao gồm cả khi tạo bản sao lưu, không nên sao chép tệp này.
		           |Việc sử dụng đồng thời hai bản sao của cơ sở thông tin có cùng tên có thể dẫn đến xung đột
		           |khi đồng bộ hóa dữ liệu, gửi thư và các công việc khác với tài nguyên bên ngoài.
		           |
		           |Nếu tệp không có trong thư mục chứa cơ sở thông tin, thì ứng dụng sẽ hỏi quản trị viên xem nó có được phép
		           | hoạt động với các tài nguyên bên ngoài hay không.';
		           |ru = '%1
		           |
		           |Файл создан автоматически прикладным решением ""%2"".
		           |Он содержит идентификатор информационной базы и позволяет определить, что эта информационная база была скопирована.
		           |
		           |При копировании файлов информационной базы, в том числе при создании резервной копии, не следует копировать этот файл.
		           |Одновременное использование двух копий информационной базы с одинаковым идентификатором может привести к конфликтам
		           |при синхронизации данных, отправке почты и другой работе с внешними ресурсами.
		           |
		           |Если файл отсутствует в каталоге с информационной базой, то при запуске администратору будет задан вопрос, разрешена 
		           |ли работа с внешними ресурсами.';
		           |en = '%1
		           |
		           |The file is automatically created by the ""%2"" application.
		           |It contains the infobase ID and allows you to identify that this infobase was copied.
		           |
		           |Upon copying infobase files and creating a backup, do not copy this file.
		           |Using both infobase copies with the same ID at the same time can lead to conflicts
		           |while synchronizing data, sending emails, and performing other operations with external resources.
		           |
		           |If the file is missing from the infobase directory, the app will prompt
		           |the administrator if accessing external resources is allowed.'; fa = '%1
		           |
		           |The file is automatically created by the ""%2"" application.
		           |It contains the infobase ID and allows you to identify that this infobase was copied.
		           |
		           |Upon copying infobase files and creating a backup, do not copy this file.
		           |Using both infobase copies with the same ID at the same time can lead to conflicts
		           |while synchronizing data, sending emails, and performing other operations with external resources.
		           |
		           |If the file is missing from the infobase directory, the app will prompt
		           |the administrator if accessing external resources is allowed.';
		           |it = '%1
		           |
		           |Файл создан автоматически прикладным решением ""%2"".
		           |Он содержит идентификатор информационной базы и позволяет определить, что эта информационная база была скопирована.
		           |
		           |При копировании файлов информационной базы, в том числе при создании резервной копии, не следует копировать этот файл.
		           |Одновременное использование двух копий информационной базы с одинаковым идентификатором может привести к конфликтам
		           |при синхронизации данных, отправке почты и другой работе с внешними ресурсами.
		           |
		           |Если файл отсутствует в каталоге с информационной базой, то при запуске администратору будет задан вопрос, разрешена 
		           |ли работа с внешними ресурсами.';
		           |pl = '%1
		           |
		           |The file is automatically created by the ""%2"" application.
		           |It contains the infobase ID and allows you to identify that this infobase was copied.
		           |
		           |Upon copying infobase files and creating a backup, do not copy this file.
		           |Using both infobase copies with the same ID at the same time can lead to conflicts
		           |while synchronizing data, sending emails, and performing other operations with external resources.
		           |
		           |If the file is missing from the infobase directory, the app will prompt
		           |the administrator if accessing external resources is allowed.';
		           |tr = '%1
		           |
		           |Dosya otomatik olarak uygulama çözümü ""%2"" tarafından oluşturulur. 
		           |Bir Infobase kimliği içerir ve bu infobase''in kopyalandığını belirlemenizi sağlar. 
		           |
		           |Bir yedek oluştururken de dahil olmak üzere Infobase dosyalarını kopyalarken, bu dosyayı kopyalamayın.
		           | Aynı kimliğe sahip bir Infobase''in iki kopyasını eş zamanlı olarak kullanmak, veri senkronizasyonu, posta gönderme ve diğer dış kaynaklarla 
		           |çakışmalara neden olabilir. 
		           |
		           |Dosya Infobase ile klasörde yoksa, program bu 
		           |Infobase dış kaynaklarla çalışmasına iznin verilip verilmediğini yöneticiye sorar.'"), 
		TheDatabaseID, 
		Metadata.Synonym);
	
	FileName = PathToFileInfobaseIDCheckFile();
	
	TextWriter = New TextWriter(FileName);
	Try
		TextWriter.Write(FileContent);
	Except
		TextWriter.Close();
		Raise;
	EndTry;
	TextWriter.Close();
	
EndProcedure

Function PathToFileInfobaseIDCheckFile()
	
	Return CommonClientServer.FileInfobaseDirectory() + GetPathSeparator() + "DoNotCopy.txt";
	
EndFunction

#EndRegion

#Region LockSetting

Function SetExternalResourcesOperationsLock()
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return False;
	EndIf;
	
	LockParameters = SavedLockParameters();
	
	// Either the flag indicating that a decision about the lock should be made is raised,
	// or the administrator confirmed the lock.
	If LockParameters.OperationsWithExternalResourcesLocked = Undefined 
		Or LockParameters.OperationsWithExternalResourcesLocked = True Then
		Return True; 
	EndIf;
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	If DataSeparationEnabled Then
		Return False; // Infobase transfer is determined by the service manager in SaaS mode.
	EndIf;
	
	// The following code is for the case when data separation is disabled.
	
	DataSeparationChanged = LockParameters.DataSeparationEnabled <> DataSeparationEnabled;
	
	If DataSeparationChanged Then
		MessageText = NStr("vi = 'Cơ sở thông tin đã được chuyển từ ứng dụng sang Internet.';
							|ru = 'Информационная база была перемещена из приложения в Интернете.';
							|en = 'The infobase has been moved from a web application.'; fa = 'The infobase has been moved from a web application.';
							|it = 'Il database è stato spostato dall''applicazione su Internet.';
							|pl = 'Baza informacji została przeniesiona z aplikacji w Internecie.';
							|tr = 'Infobase, çevrim içi uygulamadan taşındı.'");
		SetFlagShowsNecessityOfLock(LockParameters, MessageText);
		Return True;
	EndIf;
	
	ConnectionString = InfoBaseConnectionString();
	If ConnectionString = LockParameters.ConnectionString Then
		Return False; // If the connection string matches, do not perform any further check.
	EndIf;
	
	IsFileInfobase = Common.FileInfobase();
	
	MovedBetweenFileAndClientServerMode = IsFileInfobase <> LockParameters.IsFileInfobase;
	
	If MovedBetweenFileAndClientServerMode Then
		MessageText = 
			?(IsFileInfobase, 
				NStr("vi = 'Cơ sở thông tin đã được chuyển từ chế độ Client-server sang File-server.';
					|ru = 'Информационная база была перемещена из клиент-серверного режима работы в файловый.';
					|en = 'The infobase has been moved from the client/server mode to the file mode.'; fa = 'The infobase has been moved from the client/server mode to the file mode.';
					|it = 'Il database è stato spostato dal regime di lavoro client-server a quello a file.';
					|pl = 'Baza informacji została przeniesiona z trybu klient-serwer do trybu pracy w pliku.';
					|tr = 'Infobase, istemci-sunucu çalışma modundan dosya moduna taşındı.'"),
				NStr("vi = 'Cơ sở thông tin đã được chuyển từ chế độ File-server sang Client-server.';
					|ru = 'Информационная база была перемещена из файловый режима работы в клиент-серверный.';
					|en = 'The infobase has been moved from the file mode to the client/server mode.'; fa = 'The infobase has been moved from the file mode to the client/server mode.';
					|it = 'Il database è stato spostato dal regime di lavoro a file a quello client-server.';
					|pl = 'Baza danych informacji została przeniesiona z trybu plików do trybu pracy w klient-serwer.';
					|tr = 'Infobase, dosya modundan istemci-sunucu çalışma moduna taşındı.'"));
		SetFlagShowsNecessityOfLock(LockParameters, MessageText);
		Return True;
	EndIf;
	
	// The code below assumes that the operation mode hasn't changed:
	// - A file infobase remains a file infobase
	// - A client/server infobase remains a client/server infobase
	
	If IsFileInfobase Then
		
		// For file infobases, the connection string may vary between devices.
		// Therefore, check if the infobase was re-located using the checking file.
		
		If Not FileInfobaseIDCheckFileExists() Then
			MessageText = NStr("vi = 'Trong thư mục cơ sở thông tin không có tệp kiểm tra %1.';
								|ru = 'В каталоге информационной базы отсутствует файл проверки %1.';
								|en = 'The infobase directory does not contain check file %1.'; fa = 'The infobase directory does not contain check file %1.';
								|it = 'The infobase directory does not contain check file %1.';
								|pl = 'The infobase directory does not contain check file %1.';
								|tr = 'Infobase dizini %1 denetim dosyasını içermiyor.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, "DoNotCopy.txt");
			SetFlagShowsNecessityOfLock(LockParameters, MessageText);
			Return True;
		EndIf;
		
		InfobaseIDChanged = FileInfobaseIDFromCheckFile() <> LockParameters.TheDatabaseID;
		
		If InfobaseIDChanged Then
			MessageText = 
				NStr("vi = 'Tên định danh cơ sở thông tin trong tệp kiểm tra %1 không tương ứng với tên định danh trong cơ sở thông tin hiện tại.';
					|ru = 'Идентификатор информационной базы в файле проверки %1 не соответствует идентификатору в текущей базе.';
					|en = 'The infobase ID in check file %1 does not match ID in the current infobase.'; fa = 'The infobase ID in check file %1 does not match ID in the current infobase.';
					|it = 'ID infobase nel file di verifica %1 non corrisponde all''ID nella base corrente.';
					|pl = 'Identyfikator bazy danych w pliku weryfikacyjnym %1 nie pasuje do identyfikatora w bieżącej bazie danych.';
					|tr = '%1 denetim dosyasındaki Infobase kimliği mevcut Infobase kimliğiyle eşleşmiyor.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, "DoNotCopy.txt");
			SetFlagShowsNecessityOfLock(LockParameters, MessageText);
			Return True;
		EndIf;
		
	Else // Client/server infobase.
		
		BaseName = Lower(StringFunctionsClientServer.ParametersFromString(ConnectionString).Ref);
		ConnectionManagerServerName = Lower(StringFunctionsClientServer.ParametersFromString(ConnectionString).Srvr);
		WorkingProcessServerName = Lower(ComputerName());
		
		SavedInfobaseName = 
			Lower(StringFunctionsClientServer.ParametersFromString(LockParameters.ConnectionString).Ref);
		SavedConnectionManagerServerName = 
			Lower(StringFunctionsClientServer.ParametersFromString(LockParameters.ConnectionString).Srvr);
		SavedWorkingProcessServerName = Lower(LockParameters.ComputerName);
		
		InfobaseNameChanged = BaseName <> SavedInfobaseName;
		ComputerNameChanged = LockParameters.CheckServerName
			And WorkingProcessServerName <> SavedWorkingProcessServerName
			And StrFind(SavedConnectionManagerServerName, ConnectionManagerServerName) = 0;
		
		// In scalable clusters, "SavedConnectionManagerServerName" might contain
		// multiple server names that act as connection managers.
		// When starting the scheduled job, "ConnectionManagerServerName" contains the name of the active manager. 
		// To work with that, search for the current server in the saved name.
		
		If InfobaseNameChanged Or ComputerNameChanged Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Các tham số đã thay đổi để kiểm soát tính duy nhất của cơ sở máy khách-máy chủ.
				           |
				           |Đã là:
				           |Dòng kết nối: <%1>
				           |Tên máy tính: <%2>
				           |
				           |Trở thành:
				           |Dòng kết nối: <%3>
				           |Tên máy tính: <%4>
				           |
				           |Kiểm tra tên máy chủ: <%5>';
				           |ru = 'Изменились параметры контроля уникальности клиент-серверной базы.
				           |
				           |Было:
				           |Строка соединения: <%1>
				           |Имя компьютера: <%2>
				           |
				           |Стало:
				           |Строка соединения: <%3>
				           |Имя компьютера: <%4>
				           |
				           |Проверять имя сервера: <%5>';
				           |en = 'Parameters of client-server base uniqueness control were changed.
				           |
				           |Previous parameters:
				           |Connection string: <%1>
				           |Computer name: <%2>
				           |
				           |Current parameters:
				           |Connection string: <%3>
				           |Computer name: <%4>
				           |
				           |Check server name: <%5>'; fa = 'Parameters of client-server base uniqueness control were changed.
				           |
				           |Previous parameters:
				           |Connection string: <%1>
				           |Computer name: <%2>
				           |
				           |Current parameters:
				           |Connection string: <%3>
				           |Computer name: <%4>
				           |
				           |Check server name: <%5>';
				           |it = 'Sono stati modificati i parametri di controllo dell''unicità della base client-server.
				           |
				           |Era:
				           |Riga di connessione: <%1>
				           |Nome del computer: <%2>
				           |
				           |Diventato:
				           |Riga di connessione: <%3>
				           |Nome del computer: <%4>
				           |
				           |Controllare il nome del server: <%5>';
				           |pl = 'Zmieniono ustawienia kontroli unikalności bazy danych klient-serwer.
				           |
				           |Było:
				           |Wiersz połączenia: <%1>
				           |Nazwa komputera: <%2>
				           |
				           |Teraz:
				           |Ciąg połączenia: <%3>
				           |Nazwa komputera: <%4>
				           |
				           | Sprawdź nazwę serwera: <%5>';
				           |tr = 'İstemci-sunucu veritabanının benzersizliğini denetleme parametreleri değişti.
				           |
				           |Önceki:
				           |Bağlantı satırı: <%1>
				           |Bilgisayar adı: <%2>
				           |
				           |Şimdi:
				           |Bağlantı satırı: <%3>
				           |Bilgisayar adı: <%4>
				           |
				           |Sunucu adını kontrol et: <%5>'"),
				LockParameters.ConnectionString, 
				SavedWorkingProcessServerName,
				ConnectionString,
				WorkingProcessServerName,
				LockParameters.CheckServerName);
			
			SetFlagShowsNecessityOfLock(LockParameters, MessageText);
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

Procedure SetFlagShowsNecessityOfLock(LockParameters, MessageText)
	
	BlockLockParametersData();
	
	CurrentBlockingParameters = SavedLockParameters();
	If CurrentBlockingParameters.OperationsWithExternalResourcesLocked = Undefined Then
		// If the flag indicating that a lock decision should be made was set in another session.
		Return;
	EndIf;
	
	LockParameters.OperationsWithExternalResourcesLocked = Undefined;
	LockParameters.LockReason = LockReasonPresentation(LockParameters);
	SaveLockParameters(LockParameters);
	
	SSLSubsystemsIntegration.WhenYouAreForbiddenToWorkWithExternalResources();
	ExternalResourcesOperationsLockOverridable.WhenYouAreForbiddenToWorkWithExternalResources();
	
	WriteLogEvent(EventLogEventName(), EventLogLevel.Warning,,, MessageText);
	
EndProcedure

Function LockReasonPresentation(LockParameters)
	
	CurrentDate = CurrentDate(); // ACC:143 Lock information is required in server date.
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã chặn trên máy chủ <b>%1</b> <b>%2</b> в <b>%3</b> %4.
		           |
		           |Vị trí cơ sở thông tin đã thay đổi từ
		           |<b>%5</b>
		           |sang 
		           |<b>%6</b>';
		           |ru = 'Блокировка выполнена на сервере <b>%1</b> <b>%2</b> в <b>%3</b> %4.
		           |
		           |Размещение информационной базы изменилось с
		           |<b>%5</b>
		           |на 
		           |<b>%6</b>';
		           |en = 'The lock was set on server <b>%1</b> on <b>%2</b> at <b>%3</b> %4.
		           |
		           |The infobase location has been changed.
		           |Old location: <b>%5</b>
		           |New location: <b>%6</b>
		           |'; fa = 'The lock was set on server <b>%1</b> on <b>%2</b> at <b>%3</b> %4.
		           |
		           |The infobase location has been changed.
		           |Old location: <b>%5</b>
		           |New location: <b>%6</b>
		           |';
		           |it = 'Блокировка выполнена на сервере <b>%1</b> <b>%2</b> в <b>%3</b> %4.
		           |
		           |Размещение информационной базы изменилось с
		           |<b>%5</b>
		           |на 
		           |<b>%6</b>';
		           |pl = 'The lock was set on server <b>%1</b> on <b>%2</b> at <b>%3</b> %4.
		           |
		           |The infobase location has been changed.
		           |Old location: <b>%5</b>
		           |New location: <b>%6</b>
		           |';
		           |tr = 'Kilitleme <b>%1</b> sunucusunda <b>%2</b> <b>%3</b> %4 içinde gerçekleşti.
		           |
		           |Infobase konumu
		           |<b>%5</b>
		           |üzerinden
		           |<b>%6</b>olarak değişti'"),
		ComputerName(),
		Format(CurrentDate, "DLF=D"),
		Format(CurrentDate, "DLF=T"),
		CurrentOperationPresentation(),
		ConnectionStringPresentation(LockParameters.ConnectionString),
		ConnectionStringPresentation(InfoBaseConnectionString()));
	
EndFunction

Function CurrentOperationPresentation()
	
	CurrentInfobaseSession1 = GetCurrentInfoBaseSession();
	BackgroundJob = CurrentInfobaseSession1.GetBackgroundJob();
	IsScheduledJobSession = BackgroundJob <> Undefined And BackgroundJob.ScheduledJob <> Undefined;
	
	If IsScheduledJobSession Then
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'khi thử thực hiện nhiệm vụ thường kỳ <b>%1</b>';
				|ru = 'при попытке выполнения регламентного задания <b>%1</b>';
				|en = 'on attempt to execute scheduled job <b>%1</b>'; fa = 'on attempt to execute scheduled job <b>%1</b>';
				|it = 'при попытке выполнения регламентного задания <b>%1</b>';
				|pl = 'on attempt to execute scheduled job <b>%1</b>';
				|tr = '<b>%1</b> zamanlanmış görevinin yürütülmesi sırasında'"),
			BackgroundJob.ScheduledJob.Description);
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'khi người sử dụng <b>%1</b>đăng nhập';
			|ru = 'при входе пользователя <b>%1</b>';
			|en = 'when user <b>%1</b> logged in'; fa = 'when user <b>%1</b> logged in';
			|it = 'при входе пользователя <b>%1</b>';
			|pl = 'when user <b>%1</b> logged in';
			|tr = '<b>%1</b> kullanıcısının girişi sırasında'"),
		UserName());
	
EndFunction

Function ConnectionStringPresentation(ConnectionString)
	
	Result = ConnectionString;
	
	Parameters = StringFunctionsClientServer.ParametersFromString(ConnectionString);
	If Parameters.Property("File") Then
		Result = Parameters.File;
	EndIf;
	
	Return Result;
	
EndFunction

Function EventLogEventName() Export 
	
	Return NStr("vi = 'Đã phong tỏa làm việc với nguồn ngoài';
				|ru = 'Работа с внешними ресурсами заблокирована';
				|en = 'Online activities are disabled'; fa = 'فعالیت‌های آنلاین غیرفعال هستند';
				|it = 'Il lavoro con risorse esterne è bloccato';
				|pl = 'Praca z zasobami zewnętrznymi jest zablokowana';
				|tr = 'Dış kaynaklarla çalışma kilitlendi'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("OnSetSessionParameters");
	Methods.Insert("UpdateExternalResourceAccessLockParameters");
	
EndProcedure

#EndRegion