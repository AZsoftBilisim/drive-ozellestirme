///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// In the local mode of operation, it returns the scheduled jobs matching the filter.
// In SaaS mode, returns the value table which contains details of the jobs found in the JobsQueue catalog.
// 
//
// Parameters:
//  Filter - Structure - Has the following properties: 
//          1. Common for all run modes:
//             * UUID - UUID - a scheduled job ID in the local
//                                         mode or an ID of the queue job reference in SaaS mode.
//                                       - String - a string of the scheduled job UUID in the local
//                                         mode or an ID of the queue job reference in SaaS mode.
//                                       - CatalogRef.JobsQueue - - Queue job ID in the SaaS mode.
//                                            
//                                       - ValueTableRow of See FindJobs
//             * Metadata              - MetadataObjectScheduledJob - a scheduled job metadata.
//                                       - String - Name of the scheduled job metadata object.
//             * Use           - Boolean - If True, a job is enabled.
//             * Key                    - String - an applied ID of a job.
//          2) Allowed keys only for local mode:
//             * Description            - String - scheduled job description.
//             * Predefined        - Boolean - If True, scheduled job is defined in the metadata.
//          3) Allowed keys only for SaaS mode:
//             * MethodName               - String - a method name (or alias) of a job queue handler.
//             * DataArea           - Number - job data area separator value.
//             * JobState        - EnumRef.JobsStates - queue job state.
//             * Template                  - CatalogRef.QueueJobTemplates - a job template used
//                                            for separated queue jobs only.
//
// Returns:
//     Array of ScheduledJob - In the local mode, a scheduled job array.
//     ValueTable - In SaaS mode, has the following columns:
//        * Use                - Boolean - If True, a job is enabled.
//        * Key                         - String - an applied ID of a job.
//        * Parameters                    - Array - parameters to be passed to job handler.
//        * Schedule                   - JobSchedule - a job schedule.
//        * UUID      - CatalogRef.JobsQueue - - Queue job ID in the SaaS mode.
//                                            
//        * ScheduledStartTime - Date - date and time of scheduled job launch
//                                         (as adjusted for the data area time zone).
//        * MethodName                    - String - a method name (or alias) of a job queue handler.
//        * DataArea                - Number - job data area separator value.
//        * JobState             - EnumRef.JobsStates - queue job state.
//        * Template                       - CatalogRef.QueueJobTemplates - a job template
//                                            used for separated queue jobs only.
//        * ExclusiveExecution       - Boolean - If this flag is set, the job will be executed 
//                                                  even if session start is prohibited in the data
//                                                  area. If any jobs with this flag
//                                                  are available in a data area, they will be executed first.
//        * RestartIntervalOnFailure - Number - Interval between job restart
//                                                          attempts after its abnormal termination, in seconds.
//        * RestartCountOnFailure - Number - number of retries after job abnormal termination.
//
Function FindJobs(Filter) Export
	
	RaiseIfNoAdministrationRights();
	
	FilterCopy = Common.CopyRecursive(Filter); // See FindJobs.Filter
	
	If Common.DataSeparationEnabled() Then
		
		If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
			
			If FilterCopy.Property("UUID") Then
				If Not FilterCopy.Property("Id") Then
					FilterCopy.Insert("Id", FilterCopy.UUID);
				EndIf;
				FilterCopy.Delete("UUID");
			EndIf;
			
			If Common.SeparatedDataUsageAvailable() Then
				// ACC:1386-off - The module is included in the CloudTechnology.Core subsystem.
				ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
				// ACC:1386-on
				DataArea = ModuleSaaSOperations.SessionSeparatorValue();
				FilterCopy.Insert("DataArea", DataArea);
			EndIf;
			
			ModuleJobsQueue  = Common.CommonModule("JobsQueue");
			
			If FilterCopy.Property("Metadata") Then
				If TypeOf(FilterCopy.Metadata) = Type("MetadataObject") Then
					MetadataScheduledJob = FilterCopy.Metadata;
				Else
					MetadataScheduledJob = Metadata.ScheduledJobs.Find(FilterCopy.Metadata);
				EndIf;
				FilterCopy.Delete("Metadata");
				FilterCopy.Delete("MethodName");
				FilterCopy.Delete("Template");
				If MetadataScheduledJob <> Undefined Then
					QueueJobTemplates = StandardSubsystemsCached.QueueJobTemplates();
					If QueueJobTemplates.Get(MetadataScheduledJob.Name) <> Undefined Then
						SetPrivilegedMode(True);
						Template = ModuleJobsQueue.TemplateByName_(MetadataScheduledJob.Name);
						SetPrivilegedMode(False);
						FilterCopy.Insert("Template", Template);
					Else
						FilterCopy.Insert("MethodName", MetadataScheduledJob.MethodName);
					EndIf;
				Else
					FilterCopy.Insert("MethodName", String(New UUID));
				EndIf;
			ElsIf FilterCopy.Property("Id") Then
				If TypeOf(FilterCopy.Id) = Type("String") Then
					FilterCopy.Id = New UUID(FilterCopy.Id);
				EndIf;
				If TypeOf(FilterCopy.Id) = Type("UUID") Then
					FilterCopy.Id = QueueJobLink(FilterCopy.Id, FilterCopy);
				ElsIf TypeOf(FilterCopy.Id) = Type("ValueTableRow") Then
					FilterCopy.Id = FilterCopy.Id.Id;
				EndIf;
			EndIf;
			
			Return UpdatedTaskList(ModuleJobsQueue.GetJobs(FilterCopy));
			
		EndIf;
	Else
		
		JobsList = ScheduledJobs.GetScheduledJobs(FilterCopy);
		
		Return JobsList;
		
	EndIf;
	
EndFunction

// Returns a queue job or a scheduled job.
//
// Parameters:
//  Id - MetadataObject - metadata object of a scheduled job to search
//                                     the predefined scheduled job.
//                - String - a name of the predefined scheduled job metadata in any mode or
//                           a string of the scheduled job UUID in the local mode, or
//                           a string of the queue job reference UUID in SaaS mode.
//                - UUID - a scheduled job ID in the local mode or
//                           an ID of the queue job reference in SaaS mode.
//                - ScheduledJob - a scheduled job from which you need to get the UUID
//                           for getting a fresh copy of the scheduled job in the local mode.
//                - CatalogRef.JobsQueue - an ID of a queue job in the SaaS mode.
//                - ValueTableRow of See FindJobs
// 
// Returns:
//  ScheduledJob - The local mode.
//  ValueTableRow from See FindJobs
//  Undefined - Job is not found.
//
Function Job(Val Id) Export
	
	RaiseIfNoAdministrationRights();
	
	Id = UpdatedTaskID(Id);
	ScheduledJob = Undefined;
	
	If Common.DataSeparationEnabled() Then
		
		If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
			Filter = ?(TypeOf(Id) = Type("MetadataObject"),
				New Structure("Metadata", Id),
				New Structure("UUID", Id));
			
			JobsList = FindJobs(Filter);
			For Each Job In JobsList Do
				ScheduledJob = Job;
				Break;
			EndDo;
		EndIf;
		
	Else
		
		If TypeOf(Id) = Type("MetadataObject") Then
			If Id.Predefined Then
				ScheduledJob = ScheduledJobs.FindPredefined(Id);
			Else
				JobsList = ScheduledJobs.GetScheduledJobs(New Structure("Metadata", Id));
				If JobsList.Count() > 0 Then
					ScheduledJob = JobsList[0];
				EndIf;
			EndIf; 
		Else
			ScheduledJob = ScheduledJobs.FindByUUID(Id);
		EndIf;
	EndIf;
	
	Return ScheduledJob;
	
EndFunction

// Adds a new queue job or a new scheduled job.
// 
// Parameters: 
//  Parameters - Structure - parameters of the job to be added. Possible properties:
//   * Use - Boolean - True if a scheduled job runs automatically on schedule. 
//   * Metadata    - MetadataObjectScheduledJob - required. The metadata object which will be used 
//                              to generate a scheduled job.
//   * Parameters     - Array - parameters of the scheduled job. The number of parameters must match 
//                              the parameters of the scheduled job method.
//   * Key          - String - an applied ID of a scheduled job.
//   * RestartIntervalOnFailure - Number - Interval between job restart attempts 
//                              after its abnormal termination, in seconds.
//   * Schedule    - JobSchedule - a job schedule.
//   * RestartCountOnFailure - Number - number of retries after job abnormal termination.
//
// Returns:
//  ScheduledJob - The local mode.
//  ValueTableRow from See FindJobs
// 
Function AddJob(Parameters) Export
	
	RaiseIfNoAdministrationRights();
	
	If Common.DataSeparationEnabled() Then
		
		If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
			
			JobParameters = Common.CopyRecursive(Parameters);
			
			If Common.SeparatedDataUsageAvailable() Then
				// ACC:1386-off - The module is included in the CloudTechnology.Core subsystem.
				ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
				// ACC:1386-on
				DataArea = ModuleSaaSOperations.SessionSeparatorValue();
				JobParameters.Insert("DataArea", DataArea);
			EndIf;
			
			JobMetadata = JobParameters.Metadata;
			MethodName = JobMetadata.MethodName;
			JobParameters.Insert("MethodName", MethodName);
			
			JobParameters.Delete("Metadata");
			JobParameters.Delete("Description");
			
			ModuleJobsQueue = Common.CommonModule("JobsQueue");
			Job = ModuleJobsQueue.AddJob(JobParameters);
			Filter = New Structure("Id", Job);
			JobsList = UpdatedTaskList(ModuleJobsQueue.GetJobs(Filter));
			For Each Job In JobsList Do
				Return Job;
			EndDo;
			
		EndIf;
		
	Else
		Job = AddARoutineTask(Parameters);
	EndIf;
	
	Return Job;
	
EndFunction

// Deletes a queue job or a scheduled job.
//
// Parameters:
//  Id - MetadataObject - a metadata object of a scheduled job to search for
//                                     the non-predefined scheduled job.
//                - String - a name of the predefined scheduled job metadata in any mode or
//                           a string of the scheduled job UUID in the local mode, or
//                           a string of the queue job reference UUID in SaaS mode.
//                - UUID - a scheduled job ID in the local mode or
//                           an ID of the queue job reference in SaaS mode.
//                - ScheduledJob - a scheduled job whose UUID is used 
//                  to identify the scheduled job instance to be deleted in the local mode.
//                - CatalogRef.JobsQueue - an ID of a queue job in the SaaS mode.
//                - ValueTableRow of See FindJobs
//
Procedure DeleteJob(Val Id) Export
	
	RaiseIfNoAdministrationRights();
	
	Id = UpdatedTaskID(Id);
	
	If Common.DataSeparationEnabled() Then
		If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
			If TypeOf(Id) = Type("ValueTableRow") Then
				JobsList = CommonClientServer.ValueInArray(Id);
			Else
				Filter = ?(TypeOf(Id) = Type("MetadataObject"),
					New Structure("MethodName", Id.MethodName),
					New Structure("UUID", Id));
				JobsList = FindJobs(Filter);
			EndIf;
			ModuleJobsQueue = Common.CommonModule("JobsQueue");
			For Each Job In JobsList Do
				ModuleJobsQueue.DeleteJob(Job.Id);
			EndDo;
		EndIf;
	Else
		DeleteScheduledJob(Id);
	EndIf;
	
EndProcedure

// Changes a queue job or a scheduled one.
//
// In SaaS mode (separation is enabled):
// - If called within a transaction, object lock is set for the job.
// - If the job is based on a template or it is predefined,
// only the Usage property can be specified in the Parameters parameter. In this case, you cannot
// change the schedule as it is stored in the shared Job template
// and not saved for every area separately.
// 
// Parameters: 
//  Id - MetadataObject - Scheduled job metadata object for searching.
//                - String - a name of the predefined scheduled job metadata in any mode or
//                           a string of the scheduled job UUID in the local mode, or
//                           a string of the queue job reference UUID in SaaS mode.
//                - UUID - a scheduled job ID in the local mode or
//                            an ID of the queue job reference in SaaS mode.
//                - ScheduledJob - a scheduled job in the local mode.
//                - CatalogRef.JobsQueue - an ID of a queue job in the SaaS mode.
//                - ValueTableRow of See FindJobs
//
//  Parameters - Structure - parameters that should be set to the job, possible properties:
//   * Use - Boolean - True if a scheduled job is executed automatically according to the schedule.
//   * Parameters     - Array - parameters of the scheduled job. The number of parameters must match
//                              the parameters of the scheduled job method.
//   * Key          - String - an applied ID of a scheduled job.
//   * RestartIntervalOnFailure - Number - Interval between job restart attempts
//                              after its abnormal termination, in seconds.
//   * Schedule    - JobSchedule - a job schedule.
//   * RestartCountOnFailure - Number - number of retries after job abnormal termination.
//   
Procedure ChangeJob(Val Id, Val Parameters) Export
	
	RaiseIfNoAdministrationRights();
	
	Id = UpdatedTaskID(Id);
	
	If Common.DataSeparationEnabled() Then
		If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
			JobParameters = Common.CopyRecursive(Parameters);
			JobParameters.Delete("Description");
			If JobParameters.Count() = 0 Then
				Return;
			EndIf;
			
			If TypeOf(Id) = Type("ValueTableRow") Then
				JobsList = CommonClientServer.ValueInArray(Id);
			Else
				Filter = ?(TypeOf(Id) = Type("MetadataObject"),
					New Structure("Metadata", Id),
					New Structure("UUID", Id));
				JobsList = FindJobs(Filter);
			EndIf;
			
			// If a scheduled job is predefined and there's a queue template,
			// then only "Use" can be modified.
			PredefinedJobParameters = New Structure;
			If JobParameters.Property("Use") Then
				PredefinedJobParameters.Insert("Use",
					JobParameters.Use);
			EndIf;
			
			ModuleJobsQueue = Common.CommonModule("JobsQueue");
			For Each Job In JobsList Do
				If Not ValueIsFilled(Job.Template) Then
					ModuleJobsQueue.ChangeJob(Job.Id, JobParameters);
				ElsIf ValueIsFilled(PredefinedJobParameters) Then
					ModuleJobsQueue.ChangeJob(Job.Id, PredefinedJobParameters);
				EndIf;
			EndDo;
		EndIf;
	Else
		ChangeScheduledJob(Id, Parameters);
	EndIf;
	
EndProcedure

// Returns the UUID of a queue job or a scheduled job.
// To call, you must have the administrator rights or SetPrivilegedMode.
//
// Parameters:
//  Id - MetadataObject - metadata object of a scheduled job to search
//                                     the scheduled job.
//                - String - a string of the scheduled job UUID or
//                           an ID of the queue job reference in SaaS mode.
//                - UUID - a scheduled job ID in the local mode or
//                            an ID of the queue job reference in SaaS mode.
//                - ScheduledJob - a scheduled job.
//
// Returns:
//  UUID - a scheduled job ID in the local mode or
//                             an ID of the queue job reference in SaaS mode.
// 
Function UUID(Val Id) Export
	
	Return UniqueIdentifierOfTheTask(Id, True);
	
EndFunction

// Intended to restrict the permissions available in a scheduled job session or
// when working with the Collaboration System.
// If the list of infobase users is not empty, it creates and assigns a utility user
// to the scheduled job (a user with no permissions and
// no authentication required).
// If the procedure is called within a scheduled job session
// that does not yet have a utility user assigned, an exception is raised
// to restart the job after the user has been set.
// 
// Parameters:
//  ScheduledJob - MetadataObjectScheduledJob - Scheduled job metadata.
//  InfobaseDummyUser - See Users.InfobaseDummyUser
//                          - Undefined - a common service user, otherwise you need
//                            to pass a similar one, for example, with a different name, if required.
//
Procedure SetInternalUserOfScheduledJob(ScheduledJob, InfobaseDummyUser = Undefined) Export
	
	SetPrivilegedMode(True);
	
	// Create a utility user if none exists.
	If InfobaseDummyUser = Undefined Then
		InfobaseDummyUser = InfobaseDummyUser(ScheduledJob);
	EndIf;
	If InfobaseDummyUser = Undefined Then
		Return;
	EndIf;
	
	CurrentSession = GetCurrentInfoBaseSession();
	
	// Check the current scheduled job for a user.
	BackgroundJob = CurrentSession.GetBackgroundJob();
	If UserName() = InfobaseDummyUser.Name
	   And BackgroundJob <> Undefined
	   And BackgroundJob.MethodName = ScheduledJob.MethodName Then
		Return;
	EndIf;
	
	// Assign the utility user if no user is assigned.
	If Common.DataSeparationEnabled() Then
		Filter = New Structure("MethodName", ScheduledJob.MethodName);
	Else
		Filter = New Structure("Metadata", ScheduledJob);
	EndIf;
	FoundJobs = FindJobs(Filter);
	
	JobParameters = New Structure("UserName", InfobaseDummyUser.Name);
	IsInternalUserSet = False;
	
	For Each FoundJob In FoundJobs Do
		If FoundJob.UserName <> InfobaseDummyUser.Name Then
			ChangeJob(FoundJob.UUID, JobParameters);
			IsInternalUserSet = True;
		EndIf;
	EndDo;
	
	// Call an exception to restart the scheduled job.
	If Not IsInternalUserSet
	 Or UserName() = InfobaseDummyUser.Name
	 Or BackgroundJob = Undefined
	 Or BackgroundJob.MethodName <> ScheduledJob.MethodName
	   And Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	Text = NStr("vi = 'Cần thực hiện nhiệm vụ thường kỳ này với tên người dùng hệ thống.
	                   |Việc thực hiện đã bị gián đoạn. Đã thiết lập người dùng hệ thống để khởi động.
	                   |Không cần thao tác bổ sung. Sẽ thực hiện lần khởi chạy tiếp theo với tên người dùng hệ thống.';
	                   |ru = 'Это регламентное задание должно выполняться от имени служебного пользователя.
	                   |Выполнение прервано. Установлен служебный пользователь для запуска.
	                   |Дополнительных действий не требуется. Следующий запуск будет выполнен от имени служебного пользователя.';
	                   |en = 'This scheduled job must be executed under a utility user account.
	                   |Execution has been interrupted. A service user has been assigned to the job.
	                   |No further action is required. Next time the job will run under the utility user account.'; fa = 'This scheduled job must be executed under a utility user account.
	                   |Execution has been interrupted. A service user has been assigned to the job.
	                   |No further action is required. Next time the job will run under the utility user account.';
	                   |it = 'This scheduled job must be executed under a utility user account.
	                   |Execution has been interrupted. A service user has been assigned to the job.
	                   |No further action is required. Next time the job will run under the utility user account.';
	                   |pl = 'This scheduled job must be executed under a utility user account.
	                   |Execution has been interrupted. A service user has been assigned to the job.
	                   |No further action is required. Next time the job will run under the utility user account.';
	                   |tr = 'Bu zamanlanmış görev bir hizmet kullanıcısı olarak yürütülmelidir.
	                   |Yürütme yarıda kesildi. Hizmet kullanıcısı çalıştırılmak üzere ayarlanmıştır.
	                   |Başka bir işlem gerekmemektedir. Bir sonraki çalıştırma hizmet kullanıcısı olarak gerçekleştirilecektir.'")
	                   + Chars.LF;
	Raise Text;
	
EndProcedure

// Starts a background task based on a routine task or executes its method not in the background.
// The user to run is always current (the platform does not allow you to specify it).
//
// Parameters:
//  Id - MetadataObject - metadata of a routine task.
//                - String - the name of the routine task metadata.
//                - ScheduledJob - an instance of a routine task when it needs
//                    to be completed with parameters (you can pass an unrecorded object created).
//
//  ExecutionParameters - See NewTaskCompletionParameters
//                      - Undefined - to use the default values.
//
// Returns:
//  BackgroundJob - running task.
//  Undefined - if you specified run not in the background.
//
Function CompleteTheJob(Id, Val ExecutionParameters = Undefined) Export
	
	ScheduledJob = Undefined;
	
	If TypeOf(Id) = Type("ScheduledJob") Then
		ScheduledJob = Id;
		JobMetadata = Id.Metadata;
		
	ElsIf TypeOf(Id) = Type("MetadataObject") Then
		If Not Metadata.ScheduledJobs.Contains(Id) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Недопустимое значение параметра %1 в %2.
				           |Ожидался объект метаданных регламентного задания, а передан другой объект метаданных.';
				           |vi = 'Invalid value for parameter %1 in %2.
				           |A scheduled job metadata object was expected, but a different metadata object was passed.';
				           |en = 'Invalid value for parameter %1 in %2.
				           |A scheduled job metadata object was expected, but a different metadata object was passed.'; fa = 'Invalid value for parameter %1 in %2.
				           |A scheduled job metadata object was expected, but a different metadata object was passed.';
				           |it = 'Invalid value for parameter %1 in %2.
				           |A scheduled job metadata object was expected, but a different metadata object was passed.';
				           |pl = 'Invalid value for parameter %1 in %2.
				           |A scheduled job metadata object was expected, but a different metadata object was passed.';
				           |tr = '%2 içinde %1 parametre değeri geçersiz. 
				           |Bir zamanlanmış görev meta veri nesnesi beklenirken farklı bir meta veri nesnesi iletildi.'"),
				"Id",
				"ScheduledJobsServer.CompleteTheJob");
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndIf;
		JobMetadata = Id;
		
	ElsIf TypeOf(Id) = Type("String") Then
		JobMetadata = Metadata.ScheduledJobs.Find(Id);
		If JobMetadata = Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Недопустимое значение параметра %1 в %2.
				           |Регламентное задание ""%3"" не существует в метаданных.';
				           |vi = 'Invalid value for parameter %1 in %2.
				           |Scheduled job ""%3"" doesn''t exist in metadata.';
				           |en = 'Invalid value for parameter %1 in %2.
				           |Scheduled job ""%3"" doesn''t exist in metadata.'; fa = 'Invalid value for parameter %1 in %2.
				           |Scheduled job ""%3"" doesn''t exist in metadata.';
				           |it = 'Invalid value for parameter %1 in %2.
				           |Scheduled job ""%3"" doesn''t exist in metadata.';
				           |pl = 'Invalid value for parameter %1 in %2.
				           |Scheduled job ""%3"" doesn''t exist in metadata.';
				           |tr = '%2 içinde %1 parametre değeri geçersiz.
				           |""%3"" zamanlanmış görevi meta verilerde mevcut değil.'"),
				"Id",
				"ScheduledJobsServer.CompleteTheJob",
				Id);
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndIf;
	Else
		CommonClientServer.CheckParameter("ScheduledJobsServer.CompleteTheJob",
			"Id", Id, New TypeDescription("MetadataObject,String,ScheduledJob"));
	EndIf;
	
	Parameters = ?(ScheduledJob <> Undefined, ScheduledJob.Parameters, Undefined);
	
	ExecutionParameters = ?(ExecutionParameters = Undefined,
		NewTaskCompletionParameters(), ExecutionParameters);
	
	If Not ExecutionParameters.InBackground Then
		ParametersString = "";
		If Parameters <> Undefined And Parameters.Count() > 0 Then
			For IndexOf = 0 To Parameters.UBound() Do 
				ParametersString = ParametersString + "Parameters[" + XMLString(IndexOf) + "],";
			EndDo;
			ParametersString = Mid(ParametersString, 1, StrLen(ParametersString) - 1);
		EndIf;
		Execute(Metadata.ScheduledJobs[JobMetadata.Name].MethodName + "(" + ParametersString + ")"); // APK:487 Executable code is safe.
		Return Undefined;
	EndIf;
	
	Filter = Undefined;
	If ExecutionParameters.SearchForActive = True Then
		Filter = New Structure;
		Filter.Insert("MethodName", JobMetadata.MethodName);
		Filter.Insert("State", BackgroundJobState.Active);
		
	ElsIf TypeOf(ExecutionParameters.SearchForActive) = Type("Structure") Then
		Filter = ExecutionParameters.SearchForActive;
		
	ElsIf ExecutionParameters.SearchForActive <> False Then
		CommonClientServer.CheckParameter("ScheduledJobsServer.CompleteTheJob",
			"ExecutionParameters", ExecutionParameters, Type("Structure"),
			New Structure("SearchForActive", New TypeDescription("Boolean,Structure")));
	EndIf;
	
	If Filter <> Undefined Then
		FoundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
		If FoundJobs.Count() > 0 Then
			Return FoundJobs[0];
		EndIf;
	EndIf;
	
	Var_Key = ExecutionParameters.Key;
	If Var_Key = Undefined Then
		If ScheduledJob <> Undefined And ValueIsFilled(ScheduledJob.Key) Then
			Var_Key = ScheduledJob.Key;
		ElsIf ValueIsFilled(JobMetadata.Key) Then
			Var_Key = JobMetadata.Key;
		EndIf;
	EndIf;
	
	Description = ExecutionParameters.Description;
	If Description = Undefined Then
		If ScheduledJob <> Undefined Then
			Description = ScheduledJob.Description;
		EndIf;
		If Not ValueIsFilled(Description) Then
			Description = JobMetadata.Presentation();
		EndIf;
		If Not ValueIsFilled(Description) Then
			Description = JobMetadata.Name;
		EndIf;
	EndIf;
	
	If TypeOf(ExecutionParameters.IsManualStart) = Type("Boolean") Then
		If ScheduledJob <> Undefined Then
			SetPrivilegedMode(True);
			If ScheduledJobs.FindByUUID(ScheduledJob.UUID) <> Undefined Then
				Description = Description + " " + String(ScheduledJob.UUID);
			EndIf;
			SetPrivilegedMode(False);
		EndIf;
		If ExecutionParameters.IsManualStart Then
			Template = NStr("ru = 'Запуск вручную: %1 (из сеанса %2 от %3)';
							|vi = 'Manual start: %1 (from session %2 dated %3)';
							|en = 'Manual start: %1 (from session %2 dated %3)'; fa = 'Manual start: %1 (from session %2 dated %3)';
							|it = 'Manual start: %1 (from session %2 dated %3)';
							|pl = 'Manual start: %1 (from session %2 dated %3)';
							|tr = 'Manuel başlatma: %1 (oturum %2 , %3 tarafından)'",
				Common.DefaultLanguageCode());
		Else
			Template = NStr("ru = 'Автозапуск: %1 (из сеанса %2 от %3)';
							|vi = 'Autostart: %1 (from session %2 dated %3)';
							|en = 'Autostart: %1 (from session %2 dated %3)'; fa = 'Autostart: %1 (from session %2 dated %3)';
							|it = 'Autostart: %1 (from session %2 dated %3)';
							|pl = 'Autostart: %1 (from session %2 dated %3)';
							|tr = 'Otomatik başlatma: %1 (oturum %2 , %3 tarafından)'",
				Common.DefaultLanguageCode());
		EndIf;
		CurrentSession = GetCurrentInfoBaseSession();
		Description = StringFunctionsClientServer.SubstituteParametersToString(Template,
			Description,
			Format(CurrentSession.SessionNumber, "NG="),
			Format(CurrentSession.SessionStarted, "DLF=DT"));
	EndIf;
	
	If ExecutionParameters.WithDatabaseExtensions = True Then
		BackgroundJob = ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(
			Metadata.ScheduledJobs[JobMetadata.Name].MethodName,
			Parameters, Var_Key, Description);
		
	ElsIf ExecutionParameters.WithDatabaseExtensions = False Then
		BackgroundJob = ConfigurationExtensions.ExecuteBackgroundJobWithoutExtensions(
			Metadata.ScheduledJobs[JobMetadata.Name].MethodName,
			Parameters, Var_Key, Description);
	Else
		BackgroundJob = BackgroundJobs.Execute(
			Metadata.ScheduledJobs[JobMetadata.Name].MethodName,
			Parameters, Var_Key, Description);
	EndIf;
	
	Return BackgroundJob;
	
EndFunction

#Region ParameterConstructors

// Constructor of parameters for the Perform Task function.
//
// Returns:
//  Structure:
//    * InBackground - Boolean - the default is True.
//                If False, then the routine task method is called in the current session,
//                the other properties (below) are not taken into account.
//
//    * IsManualStart - Boolean - True by default (to clarify the name of the task).
//                           True - if the launch is performed by the user using the button from the form, then the clarification
//                             "Manual launch: <parameter Name> (from session <number> from <date>)".
//                           False - if the launch is performed programmatically at some event (
//                             metadata has changed during the work of the task or after recording the object it is required to work
//                             out the quick part of updating rights to dependent objects), then the clarification
//                             "Autorun: <parameter Name> (from session <number> from <date>)".
//                        - Undefined - use the value of the Name property without specifying it.
//
//    * SearchForActive - Boolean - the default is False. Run if not executed, otherwise return active.
//                         False - do not search for an active task, start it right away and return the running one.
//                         True - search by method name and Active State. If found, return the first one.
//                     - Structure - As a Selection parameter, background tasks are selected from the platform method.Getfone assignments.
//
//    * Key         - Undefined - the default value. Take the key from the routine task,
//                       if specified, otherwise take the key from the metadata of the routine task.
//                   - String - just like the platform method has background tasks.Execute.
//
//    * Description - Undefined - by default. Take the name from the routine assignment,
//                       if completed, otherwise take the Presentation of its metadata.
//                   - String - just like the platform method has background tasks.Execute,
//                       but taking into account the value of the property, this is a manual start.
//
//    * WithDatabaseExtensions - Boolean - the default is True. Defines the execution method.
//                                  The truth is the Configuration extensions.Perform a Background tasksextension of basedata
//                                  False - Configuration extensions.performfoneadjustment without extensions
//                              - Undefined - BackgroundJobs.Execute
// 
Function NewTaskCompletionParameters() Export
	
	Result = New Structure;
	Result.Insert("InBackground",                   True);
	Result.Insert("IsManualStart",        True);
	Result.Insert("SearchForActive",          False);
	Result.Insert("Key",                    Undefined);
	Result.Insert("Description",            Undefined);
	Result.Insert("WithDatabaseExtensions", True);
	
	Return Result;
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsWithoutQueueJobSupportInSaaS

// Returns the use of a scheduled job.
// To call, you must have the administrator rights or SetPrivilegedMode.
//
// In SaaS mode, manages scheduled jobs of the platform but not queue jobs
// in the separated and shared modes.
//
// Parameters:
//  Id - MetadataObject - metadata object of a scheduled job to search
//                  the predefined scheduled job.
//                - UUID - a scheduled job ID.
//                - String - a scheduled job UUID string.
//                - ScheduledJob - a scheduled job.
//
// Returns:
//  Boolean - True if the scheduled job is used.
// 
Function ScheduledJobUsed(Val Id) Export
	
	RaiseIfNoAdministrationRights();
	
	Job = GetScheduledJob(Id);
	
	Return Job.Use;
	
EndFunction

// Returns a scheduled job schedule.
// To call, you must have the administrator rights or SetPrivilegedMode.
//
// In SaaS mode, manages scheduled jobs of the platform but not queue jobs
// in the separated and shared modes.
//
// Parameters:
//  Id - MetadataObject - metadata object of a scheduled job to search
//                  the predefined scheduled job.
//                - UUID - a scheduled job ID.
//                - String - a scheduled job UUID string.
//                - ScheduledJob - a scheduled job.
//
//  InStructure    - Boolean - If True, the schedule will be transformed
//                  into a structure that you can pass to the client.
// 
// Returns:
//  JobSchedule, Structure - the structure contains the same properties as the schedule.
// 
Function JobSchedule(Val Id, Val InStructure = False) Export
	
	RaiseIfNoAdministrationRights();
	
	Job = GetScheduledJob(Id);
	
	If InStructure Then
		Return CommonClientServer.ScheduleToStructure(Job.Schedule);
	EndIf;
	
	Return Job.Schedule;
	
EndFunction

// Sets the use of a scheduled job.
// To call, you must have the administrator rights or SetPrivilegedMode.
//
// In SaaS mode, manages scheduled jobs of the platform but not queue jobs
// in the separated and shared modes.
//
// Parameters:
//  Id - MetadataObject        - metadata object of a scheduled job to search
//                                            the predefined scheduled job.
//                - UUID - a scheduled job ID.
//                - String                  - a scheduled job UUID string.
//                - ScheduledJob     - a scheduled job.
//  Use - Boolean                  - a usage value to be set.
//
Procedure SetScheduledJobUsage(Val Id, Val Use) Export
	
	RaiseIfNoAdministrationRights();
	
	JobID = UniqueIdentifierOfTheTask(Id);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ProgramInterfaceCache");
	LockItem.SetValue("Id", String(JobID));
	
	BeginTransaction();
	Try
		Block.Lock();
		Job = GetScheduledJob(JobID);
		
		If Job.Use <> Use Then
			Job.Use = Use;
			Job.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Sets a scheduled job schedule.
// To call, you must have the administrator rights or SetPrivilegedMode.
//
// In SaaS mode, manages scheduled jobs of the platform but not queue jobs
// in the separated and shared modes.
//
// Parameters:
//  Id - MetadataObject - metadata object of a scheduled job to search
//                  the predefined scheduled job.
//                - UUID - a scheduled job ID.
//                - String - a scheduled job UUID string.
//                - ScheduledJob - a scheduled job.
//
//  Schedule    - JobSchedule - a schedule.
//                - Structure - The value returned by the ScheduleToStructure function
//                  of the CommonClientServer common module.
// 
Procedure SetJobSchedule(Val Id, Val Schedule) Export
	
	RaiseIfNoAdministrationRights();
	
	JobID = UniqueIdentifierOfTheTask(Id);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ProgramInterfaceCache");
	LockItem.SetValue("Id", String(JobID));
	
	BeginTransaction();
	Try
		Block.Lock();
		Job = GetScheduledJob(JobID);
		
		If TypeOf(Schedule) = Type("JobSchedule") Then
			Job.Schedule = Schedule;
		Else
			Job.Schedule = CommonClientServer.StructureToSchedule(Schedule);
		EndIf;
		
		Job.Write();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Returns ScheduledJob from the infobase.
//
// In SaaS mode, manages scheduled jobs of the platform but not queue jobs
// in the separated and shared modes.
//
// Parameters:
//  Id - MetadataObject - metadata object of a scheduled job to search
//                  the predefined scheduled job.
//                - UUID - a scheduled job ID.
//                - String - a scheduled job UUID string.
//                - ScheduledJob - a scheduled job from which you need to get
//                  the unique ID for getting a fresh copy of the scheduled job.
// 
// Returns:
//  ScheduledJob - read from the database.
//
Function GetScheduledJob(Val Id) Export
	
	RaiseIfNoAdministrationRights();
	
	If TypeOf(Id) = Type("ScheduledJob") Then
		Id = Id.UUID;
	EndIf;
	
	If TypeOf(Id) = Type("String") Then
		Id = New UUID(Id);
	EndIf;
	
	If TypeOf(Id) = Type("MetadataObject") Then
		ScheduledJob = ScheduledJobs.FindPredefined(Id);
	Else
		ScheduledJob = ScheduledJobs.FindByUUID(Id);
	EndIf;
	
	If ScheduledJob = Undefined Then
		Raise( NStr("vi = 'Nhiệm vụ thường kỳ không tồn tại.
		                              |Có thể là người sử dụng khác đã xóa nhiệm vụ này.';
		                              |ru = 'Регламентное задание не существует.
		                              |Возможно оно удалено другим пользователем.';
		                              |en = 'The scheduled job does not exist.
		                              |It might have been deleted by another user.'; fa = 'The scheduled job does not exist.
		                              |It might have been deleted by another user.';
		                              |it = 'Compito regolatorio inesistente. 
		                              | È possibile sia stato cancellato da un altro utente.';
		                              |pl = 'Zadania reglamentowanego nie istnieje.
		                              |Możliwie ono jest usunięto przez innego użytkownika.';
		                              |tr = 'Zamanlanmış görev mevcut değil. 
		                              |Başka bir kullanıcı tarafından silinmiş olabilir.'") );
	EndIf;
	
	Return ScheduledJob;
	
EndFunction

// Returns the result of the last run of the given scheduled job.
// Including when it was run manually from the "Scheduled and background jobs" data processor.
// 
// Parameters:
//  Job - ScheduledJob - Scheduled job whose last run results are to be obtained.
//                                  
//          - String - Scheduled job's UUID
//
// Returns:
//  Undefined
//  * Description - String:
//     * Key - String
//  * End - Date
//  * ScheduledJobID - String
//  * State - BackgroundJobState
//  * MethodName - String
//  * Placement - String
//  ErrorDetailsDescription - String
//  * StartAttempt - Number
//  * MessagesToUser - Array
//  * SessionNumber - Number
//  * SessionStart - Date
//     * Description - String
//     * Key - String
//     * End - Date
//     * ScheduledJobID - String
//     * State - BackgroundJobState
//     * MethodName - String
//     * Placement - String
//     ErrorDetailsDescription - String
//     * StartAttempt - Number
//     * MessagesToUser - Array
//     * SessionNumber - Number
//     * SessionStart - Date
//
Function PropertiesOfLastJob(Val Job) Export
	
	RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	If TypeOf(Job) = Type("ScheduledJob") Then
		Job = Job.UUID;
	EndIf;
	
	If TypeOf(Job) = Type("String") Then
		Job = New UUID(Job);
	EndIf;
	
	ScheduledJob = ScheduledJobs.FindByUUID(Job);
	CurrentFilter = New Structure("MethodName", ScheduledJob.Metadata.MethodName);
	Result = BackgroundJobs.GetBackgroundJobs(CurrentFilter);
	If Result.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	BackgroundJobLast = LastBackgroundJobInArray(Result);
	
	BackgroundJobProperties = NewBackgroundJobsProperties();
	FillPropertyValues(BackgroundJobProperties, BackgroundJobLast);
	
	BackgroundJobProperties.Id = BackgroundJobLast.UUID;
	BackgroundJobProperties.ScheduledJobID = Job;
	Return BackgroundJobProperties;
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctions_

// Returns a flag showing that operations with external resources are locked.
//
// Returns:
//   Boolean   - True if operations with external resources are locked.
//
Function OperationsWithExternalResourcesLocked() Export
	
	If Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		ModuleWorkLockWithExternalResources = Common.CommonModule("ExternalResourcesOperationsLock");
		Return ModuleWorkLockWithExternalResources.OperationsWithExternalResourcesLocked();
	EndIf;
	
	Return False;
	
EndFunction

// Allows operating with external resources.
//
Procedure UnlockOperationsWithExternalResources() Export
	
	If Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		ModuleWorkLockWithExternalResources = Common.CommonModule("ExternalResourcesOperationsLock");
		ModuleWorkLockWithExternalResources.AllowExternalResources();
	EndIf;
	
EndProcedure

// Denies operations with external resources.
//
Procedure LockOperationsWithExternalResources() Export
	
	If Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		ModuleWorkLockWithExternalResources = Common.CommonModule("ExternalResourcesOperationsLock");
		ModuleWorkLockWithExternalResources.DenyExternalResources();
	EndIf;
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// CloudTechnology.ExportImportData

// Sets a flag of scheduled jobs usage in the infobase
// depending on values of functional options.
//
// Parameters:
//  EnableJobs - Boolean - If "True", disabled scheduled jobs will be enabled
//                             when they become available according to functional options. The default value is False.
//
Procedure SetScheduledJobsUsageByFunctionalOptions(EnableJobs = False) Export
	
	If Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		ModuleScheduledJobsInternal = Common.CommonModule("ScheduledJobsInternal");
		ModuleScheduledJobsInternal.SetScheduledJobsUsageByFunctionalOptions(EnableJobs);
	EndIf;
	
EndProcedure

// End CloudTechnology.ExportImportData

#EndRegion

#EndRegion

#Region Internal

// Sets the required values of scheduled job parameters.
// In SaaS mode, for a job created based on a job queue template,
// only the value of the Usage property can be changed.
//
// Parameters:
//  ScheduledJob - MetadataObjectScheduledJob - a job whose properties
//                        need to be changed.
//  ParametersToChange - Structure - properties of the scheduled job that need to be changed.
//                        Structure key - a parameter name, and value - a form parameter value.
//  Filter               - See FindJobs.Filter.
//
Procedure SetScheduledJobParameters(ScheduledJob, ParametersToChange, Filter = Undefined) Export
	
	If Filter = Undefined Then
		Filter = New Structure;
	EndIf;
	Filter.Insert("Metadata", ScheduledJob);
	
	JobsList = FindJobs(Filter);
	If JobsList.Count() = 0 Then
		ParametersToChange.Insert("Metadata", ScheduledJob);
		AddJob(ParametersToChange);
	Else
		For Each Job In JobsList Do
			ChangeJob(Job, ParametersToChange);
		EndDo;
	EndIf;
EndProcedure

// Defines whether a predefined scheduled job is used.
//
// Parameters:
//  MetadataJob - MetadataObject - predefined scheduled job metadata.
//  Use     - Boolean - If True, the job must be enabled. Otherwise, False.
//
Procedure SetPredefinedScheduledJobUsage(MetadataJob, Use) Export
	
	If Common.DataSeparationEnabled() Then
		Filter     = New Structure;
		Filter.Insert("Metadata", MetadataJob);
		Parameters = New Structure;
		Parameters.Insert("Use", Use);
		Jobs = FindJobs(Filter);
		For Each Job In Jobs Do
			ChangeJob(Job, Parameters);
			Break;
		EndDo;
	Else
		JobID = UniqueIdentifierOfTheTask(MetadataJob);
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ProgramInterfaceCache");
		LockItem.SetValue("Id", String(JobID));
		
		BeginTransaction();
		Try
			Block.Lock();
			Job = ScheduledJobs.FindByUUID(JobID);
			
			If Job.Use <> Use Then
				Job.Use = Use;
				Job.Write();
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

// Cancels background job execution for a scheduled job
// and writes to the event log.
//
Procedure CancelJobExecution(Val ScheduledJob, TextForLog) Export
	
	CurrentSession = GetCurrentInfoBaseSession().GetBackgroundJob();
	If CurrentSession = Undefined Then
		Return;
	EndIf;
	
	If ScheduledJob = Undefined Then
		For Each Job In Metadata.ScheduledJobs Do
			If Job.MethodName = CurrentSession.MethodName Then
				ScheduledJob = Job;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If ScheduledJob = Undefined Then
		Return;
	EndIf;
	
	EventName = NStr("vi = 'Hủy nhiệm vụ nền';
					|ru = 'Отмена фонового задания';
					|en = 'Cancel background job'; fa = 'لغو کار پس‌زمینه';
					|it = 'Annullamento del Task di background';
					|pl = 'Anulowanie zadania w tle';
					|tr = 'Arka plan işini iptal et'", Common.DefaultLanguageCode());
	
	WriteLogEvent(EventName,
		EventLogLevel.Warning,
		ScheduledJob,
		,
		TextForLog);
	
	CurrentSession.Cancel();
	CurrentSession.WaitForExecutionCompletion(1);
	
EndProcedure

Function ScheduledJobParameter(ScheduledJob, PropertyName, DefaultValue) Export
	
	JobParameters = New Structure;
	JobParameters.Insert("Metadata", ScheduledJob);
	
	SetPrivilegedMode(True);
	
	JobsList = FindJobs(JobParameters);
	For Each Job In JobsList Do
		Return Job[PropertyName];
	EndDo;
	
	Return DefaultValue;
	
EndFunction

// Sets an exclusive managed lock for saving scheduled jobs.
//  The lock is set to the ProgramInterfaceCache information register.
//
// Parameters:
//  Id - UUID - a scheduled job ID.
//                - MetadataObjectScheduledJob - Before adding a new metadata object without duplicates.
//
Procedure BlockARoutineTask(Id) Export 
	
	If TypeOf(Id) = Type("MetadataObject") Then
		LockID = Id.Name;
	Else
		LockID = String(Id);
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ProgramInterfaceCache");
	LockItem.SetValue("Id", LockID);
	Block.Lock();
	
EndProcedure

// Adds a new scheduled job ignoring the queue of SaaS mode jobs.
// 
// Parameters: 
//  Parameters - Structure - parameters of the job to be added. Possible properties:
//   * Use - Boolean - True if a scheduled job runs automatically on schedule. 
//   * Metadata    - MetadataObjectScheduledJob - required. The metadata object which will be used 
//                              to generate a scheduled job.
//   * Parameters     - Array - parameters of the scheduled job. The number of parameters must match 
//                              the parameters of the scheduled job method.
//   * Key          - String - an applied ID of a scheduled job.
//   * RestartIntervalOnFailure - Number - Interval between job restart attempts 
//                              after its abnormal termination, in seconds.
//   * Schedule    - JobSchedule - a job schedule.
//   * RestartCountOnFailure - Number - number of retries after job abnormal termination.
//
// Returns:
//  ScheduledJob
//
Function AddARoutineTask(Parameters) Export
	
	RaiseIfNoAdministrationRights();
	
	JobMetadata = Parameters.Metadata;
	Job = ScheduledJobs.CreateScheduledJob(JobMetadata);
	
	If Parameters.Property("Description") Then
		Job.Description = Parameters.Description;
	Else
		Job.Description = JobMetadata.Description;
	EndIf;
	
	If Parameters.Property("Use") Then
		Job.Use = Parameters.Use;
	Else
		Job.Use = JobMetadata.Use;
	EndIf;
	
	If Parameters.Property("Key") Then
		Job.Key = Parameters.Key;
	Else
		Job.Key = JobMetadata.Key;
	EndIf;
	
	If Parameters.Property("UserName") Then
		Job.UserName = Parameters.UserName;
	EndIf;
	
	If Parameters.Property("RestartIntervalOnFailure") Then
		Job.RestartIntervalOnFailure = Parameters.RestartIntervalOnFailure;
	Else
		Job.RestartIntervalOnFailure = JobMetadata.RestartIntervalOnFailure;
	EndIf;
	
	If Parameters.Property("RestartCountOnFailure") Then
		Job.RestartCountOnFailure = Parameters.RestartCountOnFailure;
	Else
		Job.RestartCountOnFailure = JobMetadata.RestartCountOnFailure;
	EndIf;
	
	If Parameters.Property("Parameters") Then
		Job.Parameters = Parameters.Parameters;
	EndIf;
	
	If Parameters.Property("Schedule") Then
		Job.Schedule = Parameters.Schedule;
	EndIf;
	
	Job.Write();
	
	Return Job;
	
EndFunction

// Deletes a custom scheduled job (ignoring the SaaS job queue).
//
// Parameters:
//  Id - MetadataObject - a metadata object of a scheduled job to search for
//                                     the non-predefined scheduled job.
//                - String - a name of the predefined scheduled job metadata or
//                           a string of the scheduled job UUID.
//                - UUID - a scheduled job ID.
//                - ScheduledJob - a scheduled job whose UUID is used 
//                  to identify the scheduled job instance to be deleted.
//
Procedure DeleteScheduledJob(Val Id) Export
	
	RaiseIfNoAdministrationRights();
	
	Id = UpdatedTaskID(Id);
	
	JobsList = New Array; // Array of ScheduledJob
	
	If TypeOf(Id) = Type("MetadataObject") Then
		Filter = New Structure("Metadata, Predefined", Id, False);
		JobsList = ScheduledJobs.GetScheduledJobs(Filter);
	Else
		ScheduledJob = ScheduledJobs.FindByUUID(Id);
		If ScheduledJob <> Undefined Then
			JobsList.Add(ScheduledJob);
		EndIf;
	EndIf;
	
	For Each ScheduledJob In JobsList Do
		JobID = UniqueIdentifierOfTheTask(ScheduledJob);
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ProgramInterfaceCache");
		LockItem.SetValue("Id", String(JobID));
		
		BeginTransaction();
		Try
			Block.Lock();
			Job = ScheduledJobs.FindByUUID(JobID);
			If Job <> Undefined Then
				Job.Delete();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;
	
EndProcedure

// Changes the scheduled job ignoring the queue of SaaS mode jobs.
//
// Parameters: 
//  Id - MetadataObject - a metadata object of a scheduled job to search for
//                                     the non-predefined scheduled job.
//                - String - a name of the predefined scheduled job metadata or
//                           a string of the scheduled job UUID.
//                - UUID - a scheduled job ID.
//                - ScheduledJob - a scheduled job.
//
//  Parameters - Structure - parameters that should be set to the job, possible properties:
//   * Use - Boolean - True if a scheduled job is executed automatically according to the schedule.
//   * Parameters     - Array - parameters of the scheduled job. The number of parameters must match
//                              the parameters of the scheduled job method.
//   * Key          - String - an applied ID of a scheduled job.
//   * RestartIntervalOnFailure - Number - Interval between job restart attempts
//                              after its abnormal termination, in seconds.
//   * Schedule    - JobSchedule - a job schedule.
//   * RestartCountOnFailure - Number - number of retries after job abnormal termination.
//   
Procedure ChangeScheduledJob(Val Id, Val Parameters) Export
	
	RaiseIfNoAdministrationRights();
	
	Id = UpdatedTaskID(Id);
	JobID = UniqueIdentifierOfTheTask(Id);
	
	If JobID = Undefined Then
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tìm thấy nhiệm vụ thường kỳ theo tên định danh đã chuyển.
				|
				|Nếu chưa xác định nhiệm vụ thường kỳ thì ban đầu cần thêm nhiệm vụ đó
				|vào danh sách nhiệm vụ thông qua phương thức %1.';
				|ru = 'Регламентное задание по переданному идентификатору не найдено.
				|
				|Если регламентное задание не предопределенное, то его необходимо сначала добавить
				|в список заданий при помощи метода %1.';
				|en = 'Scheduled job by the passed ID is not found.
				|
				|If the scheduled job is not predefined, first of all add
				|it to the list of jobs using method %1.'; fa = 'Scheduled job by the passed ID is not found.
				|
				|If the scheduled job is not predefined, first of all add
				|it to the list of jobs using method %1.';
				|it = 'Il compito regolamentato per ID trasferito non trovato.
				|
				|Se il compito regolamentato non è predefinito, è necessario aggiungerlo all''inizio
				|nell''elenco dei compiti tramite il metodo %1.';
				|pl = 'Zadanie reglamentowane według przekazanego identyfikatora nie zostało znalezione.
				|
				|Jeśli zadanie reglamentowane nie jest predefiniowane, to go należy najpierw dodać
				|do lista zadań za pomocą metody %1.';
				|tr = 'İletilen kimlik ile ilgili bir zamanlanmış görev bulunamadı.
				|
				|Eğer zamanlanmış görev önceden tanımlanmamış ise, önce 
				|görev listesine %1yöntemle eklenmelidir.'"),
			"ScheduledJobsServer.AddJob");
		
		Raise ExceptionText;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ProgramInterfaceCache");
	LockItem.SetValue("Id", String(JobID));
	
	BeginTransaction();
	Try
		Block.Lock();
		Job = ScheduledJobs.FindByUUID(JobID);
		If Job <> Undefined Then
			HasChanges = False;
			
			UpdateTheValueOfTheTaskProperty(Job, "Description", Parameters, HasChanges);
			UpdateTheValueOfTheTaskProperty(Job, "Use", Parameters, HasChanges);
			UpdateTheValueOfTheTaskProperty(Job, "Key", Parameters, HasChanges);
			UpdateTheValueOfTheTaskProperty(Job, "UserName", Parameters, HasChanges);
			UpdateTheValueOfTheTaskProperty(Job, "RestartIntervalOnFailure", Parameters, HasChanges);
			UpdateTheValueOfTheTaskProperty(Job, "RestartCountOnFailure", Parameters, HasChanges);
			UpdateTheValueOfTheTaskProperty(Job, "Parameters", Parameters, HasChanges);
			UpdateTheValueOfTheTaskProperty(Job, "Schedule", Parameters, HasChanges);
			
			If HasChanges Then
				Job.Write();
			EndIf;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Parameters:
//   BackgroundJobArray - Array of BackgroundJob
//   LastBackgroundJob - BackgroundJob
//                           - Undefined
// Returns:
//   BackgroundJob, Undefined
//
Function LastBackgroundJobInArray(BackgroundJobArray, LastBackgroundJob = Undefined) Export
	
	For Each CurrentBackgroundJob In BackgroundJobArray Do
		If LastBackgroundJob = Undefined Then
			LastBackgroundJob = CurrentBackgroundJob;
			Continue;
		EndIf;
		If ValueIsFilled(LastBackgroundJob.End) Then
			If Not ValueIsFilled(CurrentBackgroundJob.End)
			 Or LastBackgroundJob.End < CurrentBackgroundJob.End Then
				LastBackgroundJob = CurrentBackgroundJob;
			EndIf;
		Else
			If Not ValueIsFilled(CurrentBackgroundJob.End)
			   And LastBackgroundJob.Begin < CurrentBackgroundJob.Begin Then
				LastBackgroundJob = CurrentBackgroundJob;
			EndIf;
		EndIf;
	EndDo;
	
	Return LastBackgroundJob;
	
EndFunction

#EndRegion

#Region Private

Function UpdatedTaskID(Val Id)
	
	If TypeOf(Id) = Type("ScheduledJob") Then
		Id = Id.UUID;
	EndIf;
	
	If TypeOf(Id) = Type("String") Then
		MetadataObject = Metadata.ScheduledJobs.Find(Id);
		If MetadataObject = Undefined Then
			Id = New UUID(Id);
		Else
			Id = MetadataObject;
		EndIf;
	EndIf;
	
	Return Id;
	
EndFunction

Function UniqueIdentifierOfTheTask(Val Id, InSplitModeTheQueueJobID = False)
	
	If TypeOf(Id) = Type("UUID") Then
		Return Id;
	EndIf;
	
	If TypeOf(Id) = Type("ScheduledJob") Then
		Return Id.UUID;
	EndIf;
	
	If TypeOf(Id) = Type("String") Then
		Return New UUID(Id);
	EndIf;
	
	If InSplitModeTheQueueJobID
	   And Common.DataSeparationEnabled() Then
		
		If TypeOf(Id) = Type("MetadataObject") Then
			JobParameters = New Structure("Metadata", Id);
			JobsList = FindJobs(JobParameters);
			If JobsList = Undefined Then
				Return Undefined;
			EndIf;
			
			For Each Job In JobsList Do
				Return Job.Id.UUID();
			EndDo;
		ElsIf TypeOf(Id) = Type("ValueTableRow") Then
			Return Id.Id.UUID();
		ElsIf Common.IsReference(TypeOf(Id)) Then
			Return Id.UUID();
		Else
			Return Undefined;
		EndIf;
	Else
		If TypeOf(Id) = Type("MetadataObject") And Id.Predefined Then
			Return ScheduledJobs.FindPredefined(Id).UUID;
		ElsIf TypeOf(Id) = Type("MetadataObject") And Not Id.Predefined Then
			JobsList = ScheduledJobs.GetScheduledJobs(New Structure("Metadata", Id));
			For Each ScheduledJob In JobsList Do
				Return ScheduledJob.UUID;
			EndDo; 
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

// For the ChangeJob procedure.
Procedure UpdateTheValueOfTheTaskProperty(Job, PropertyName, JobParameters, HasChanges)
	
	If Not JobParameters.Property(PropertyName) Then
		Return;
	EndIf;
	
	If Job[PropertyName] = JobParameters[PropertyName]
	 Or TypeOf(Job[PropertyName]) = Type("JobSchedule")
	   And TypeOf(JobParameters[PropertyName]) = Type("JobSchedule")
	   And String(Job[PropertyName]) = String(JobParameters[PropertyName]) Then
		
		Return;
	EndIf;
	
	If TypeOf(Job[PropertyName]) = Type("JobSchedule") 
		And TypeOf(JobParameters[PropertyName]) = Type("Structure") Then
		FillPropertyValues(Job[PropertyName], JobParameters[PropertyName]);
	Else
		Job[PropertyName] = JobParameters[PropertyName];
	EndIf;
	
	HasChanges = True;
	
EndProcedure

// For functions FindJob, Job, AddJob.
Function UpdatedTaskList(JobsList)
	
	// For backward compatibility the ID field is not removed.
	ListCopy = JobsList.Copy();
	ListCopy.Columns.Add("UUID");
	For Each Job In ListCopy Do
		Job.UUID = Job.Id;
	EndDo;
	
	Return ListCopy;
	
EndFunction

// For functions FindJobs, Job, DeleteJob, ChangeJob.
Function QueueJobLink(Id, JobParameters)
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	CatalogForJob = ModuleJobsQueue.CatalogJobsQueue();
	
	Return CatalogForJob.GetRef(Id);
	
EndFunction

// Throws an exception if the user does not have the administration right.
Procedure RaiseIfNoAdministrationRights()
	
	CheckSystemAdministrationRights = True;
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		CheckSystemAdministrationRights = False;
	EndIf;
	
	If Not Users.IsFullUser(, CheckSystemAdministrationRights) Then
		Raise NStr("vi = 'Vi phạm quyền truy cập.';
					|ru = 'Нарушение прав доступа.';
					|en = 'Access violation.'; fa = 'Access violation.';
					|it = 'Violazione dei diritti di accesso.';
					|pl = 'Naruszenie praw dostępu.';
					|tr = 'Erişim hakkı ihlali.'");
	EndIf;
	
EndProcedure

Function NewBackgroundJobsProperties()
	
	BackgroundJobsProperties = New Structure;
	BackgroundJobsProperties.Insert("Id");
	BackgroundJobsProperties.Insert("Key");
	BackgroundJobsProperties.Insert("Begin");
	BackgroundJobsProperties.Insert("End");
	BackgroundJobsProperties.Insert("ScheduledJobID");
	BackgroundJobsProperties.Insert("State");
	BackgroundJobsProperties.Insert("MethodName");
	BackgroundJobsProperties.Insert("Placement");
	BackgroundJobsProperties.Insert("StartAttempt");
	BackgroundJobsProperties.Insert("UserMessages");
	BackgroundJobsProperties.Insert("SessionNumber");
	BackgroundJobsProperties.Insert("SessionStarted");
	
	Return BackgroundJobsProperties;
	
EndFunction

// Parameters:
//  ScheduledJob - MetadataObjectScheduledJob
//
// Returns:
//  See Users.InfobaseDummyUser
//
Function InfobaseDummyUser(ScheduledJob)
	
	Properties = Users.NewIBUserDetails(, True);
	Properties.Name = InternalUsername();
	RefToNew = Catalogs.Users.GetRef(
		New UUID("91f28855-c379-11ef-8882-b06ebfbf08c7"));
	
	Try
		InfobaseDummyUser = Users.InfobaseDummyUser(Properties, RefToNew);
	Except
		ErrorInfo = ErrorInfo();
		ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo người sử dụng hệ thống ""%1""
			           |để cài đặt vào nhiệm vụ thường kỳ ""%2"" do:';
			           |ru = 'Не удалось создать служебного пользователя ""%1""
			           |для установки в регламентное задание ""%2"" по причине:';
			           |en = 'Couldn''t create utility user ""%1"" to assign it
			           |to scheduled job ""%2"" due to:'; fa = 'Couldn''t create utility user ""%1"" to assign it
			           |to scheduled job ""%2"" due to:';
			           |it = 'Не удалось создать служебного пользователя ""%1""
			           |для установки в регламентное задание ""%2"" по причине:';
			           |pl = 'Couldn''t create utility user ""%1"" to assign it
			           |to scheduled job ""%2"" due to:';
			           |tr = 'Не удалось создать служебного пользователя ""%1""
			           |для установки в регламентное задание ""%2"" по причине:'"),
			ScheduledJob.Presentation(),
			InternalUsername());
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, ErrorTitle);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	
	Return InfobaseDummyUser;
	
EndFunction

Function InternalUsername()
	
	Return "InternalUserForScheduledJobStart";
	
EndFunction

#EndRegion