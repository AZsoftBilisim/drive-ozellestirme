///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	IsFullUser = Users.IsFullUser(, True);
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	For Each RightsVerificationElement In Parameters.MetadataForCheckingAccessRightsForChanges Do
        MetadataForRightsVerification = Metadata.FindByFullName(RightsVerificationElement.Value);
		If ValueIsFilled(MetadataForRightsVerification) And Not AccessRight("Update", MetadataForRightsVerification) Then
			Raise NStr("vi = 'Không đủ quyền truy cập để thay đổi thuộc tính của nhiệm vụ thường kỳ';
						|ru = 'Недостаточно прав доступа для изменения свойств регламентного задания';
						|en = 'Insufficient access rights to edit scheduled job properties'; fa = 'Insufficient access rights to edit scheduled job properties';
						|it = 'Недостаточно прав доступа для изменения свойств регламентного задания';
						|pl = 'Insufficient access rights to edit scheduled job properties';
						|tr = 'Zamanlanmış görevlerin özelliklerinin değiştirilebilmesi için erişim yetkileri yetersiz.'");
		EndIf;	
	EndDo;
	
	Action = Parameters.Action;
	
	If StrFind(", Add, Copy, Change,", ", " + Action + ",") = 0 Then
		Raise NStr("vi = 'Sai tham số mở biểu mẫu ""Nhiệm vụ thường kỳ"".';
					|ru = 'Неверные параметры открытия формы ""Регламентное задание"".';
					|en = 'Incorrect opening parameters of the ""Scheduled job"" form.'; fa = 'Incorrect opening parameters of the ""Scheduled job"" form.';
					|it = 'Неверные параметры открытия формы ""Регламентное задание"".';
					|pl = 'Nieprawidłowe ustawienia otwierania formy ""Planowe zadanie"".';
					|tr = '""Zamanlanmış görev"" açılış formunun parametreleri yanlış.'");
	EndIf;
	
	If Action = "Add" Then
		
		NameOfMetadataObjects = Parameters.NameOfRoutineTaskMetadata;
		If IsBlankString(NameOfMetadataObjects) Then
			Raise NStr("vi = 'Chưa chỉ ra tên nhiệm vụ thường kỳ để thêm.';
						|ru = 'Не указано имя регламентного задания для добавления.';
						|en = 'The name of the scheduled job to add is not specified.'; fa = 'The name of the scheduled job to add is not specified.';
						|it = 'Не указано имя регламентного задания для добавления.';
						|pl = 'The name of the scheduled job to add is not specified.';
						|tr = 'Eklenecek zamanlanmış görevin adı belirtilmemiş.'");
		EndIf;
		
		Schedule = New JobSchedule;
		Job = Metadata.ScheduledJobs[NameOfMetadataObjects];
		
		MetadataSynonym   = Job.Synonym;
		MetadataMethodName = Job.MethodName;
			
	Else
		Job = GetScheduledJob(Parameters.Id);
		
		Id = String(Parameters.Id);
		If TypeOf(Job) = Type("ScheduledJob") Then
			FillPropertyValues(
				ThisObject,
				Job,
				"Key,
				|Predefined,
				|Use,
				|Description,
				|UserName,
				|RestartIntervalOnFailure,
				|RestartCountOnFailure");
			
			If Job.Metadata = Undefined Then
				NameOfMetadataObjects        = NStr("vi = '<không có metadata>';
													|ru = '<нет метаданных>';
													|en = '<no metadata>'; fa = '<no metadata>';
													|it = '<нет метаданных>';
													|pl = '<brak metadanych>';
													|tr = '<meta veri yok>'");
				MetadataSynonym    = NStr("vi = '<không có metadata>';
											|ru = '<нет метаданных>';
											|en = '<no metadata>'; fa = '<no metadata>';
											|it = '<нет метаданных>';
											|pl = '<brak metadanych>';
											|tr = '<meta veri yok>'");
				MetadataMethodName  = NStr("vi = '<không có metadata>';
											|ru = '<нет метаданных>';
											|en = '<no metadata>'; fa = '<no metadata>';
											|it = '<нет метаданных>';
											|pl = '<brak metadanych>';
											|tr = '<meta veri yok>'");
			Else
				NameOfMetadataObjects        = Job.Metadata.Name;
				MetadataSynonym    = Job.Metadata.Synonym;
				MetadataMethodName  = Job.Metadata.MethodName;
			EndIf;

			Schedule = Job.Schedule;
			
		ElsIf TypeOf(Job) = Type("CatalogRef.JobsQueue") Then
			
			Structure_Of_Task = Common.ObjectAttributesValues(Job, "Key,
																		|Use,
																		|UserName,
																		|RestartIntervalOnFailure,
																		|RestartCountOnFailure,
																		|Schedule,
																		|Parameters");
			
			FillPropertyValues(
				ThisObject,
				Structure_Of_Task,
				"Key,
				|Use,
				|UserName,
				|RestartIntervalOnFailure,
				|RestartCountOnFailure");
			
			NameOfMetadataObjects        = NStr("vi = '<không có metadata>';
												|ru = '<нет метаданных>';
												|en = '<no metadata>'; fa = '<no metadata>';
												|it = '<нет метаданных>';
												|pl = '<brak metadanych>';
												|tr = '<meta veri yok>'");
			MetadataSynonym    = NStr("vi = '<không có metadata>';
										|ru = '<нет метаданных>';
										|en = '<no metadata>'; fa = '<no metadata>';
										|it = '<нет метаданных>';
										|pl = '<brak metadanych>';
										|tr = '<meta veri yok>'");
			MetadataMethodName  = NStr("vi = '<không có metadata>';
										|ru = '<нет метаданных>';
										|en = '<no metadata>'; fa = '<no metadata>';
										|it = '<нет метаданных>';
										|pl = '<brak metadanych>';
										|tr = '<meta veri yok>'");

			Schedule = Structure_Of_Task.Schedule.Get();
			
		EndIf;

		If IsFullUser And TypeOf(Job) = Type("ScheduledJob") Then
			MessagesToUserAndErrorDescription = ScheduledJobsInternal.ScheduledJobMessagesAndErrorDescriptions(Job);
		EndIf;
	EndIf;
	
	If Action <> "Change" Then
		Id = NStr("vi = '<sẽ tạo khi ghi lại>';
					|ru = '<будет создан при записи>';
					|en = '<will be generated automatically>'; fa = '<will be generated automatically>';
					|it = '<будет создан при записи>';
					|pl = '<zostanie utworzone po zapisie>';
					|tr = '<yazarken oluşturulacak>'");
		Use = False;
		
	EndIf;
	
	If Action = "Add" Or IsBlankString(Description) Then
		Description = AutoDescription(ThisObject);
	Else
		AutoDescription(ThisObject);
	EndIf;
	
	UpdateAutoNamingDetails();
	
	// Filling in the user name selection list.
	If IsFullUser Then
		UsersArray = InfoBaseUsers.GetUsers();
		
		For Each User In UsersArray Do
			Items.UserName.ChoiceList.Add(User.Name);
		EndDo;
	EndIf;
	
EndProcedure 

&AtClient
Procedure OnOpen(Cancel)
	
	If Action = "Add" Then
		
		RefreshFormTitle();
		
	Else
		RefreshFormTitle();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("WriteAndCloseCompletion", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
	UpdateAutoNaming(Modified);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	
	AutomaticNamingIndex = 0;
	NameIsChangedByUser = True;
	AutoNameIsUsed = False;
	For Each ListItem In Items.Description.ChoiceList Do
		
		If ListItem.Value = Description Then
			AutoNameIsUsed = True;
			NameIsChangedByUser = False;
			AutomaticNamingIndex = Items.Description.ChoiceList.IndexOf(ListItem);
		EndIf;
		
	EndDo;
		
	RefreshFormTitle();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Write(Command)
	
	WriteScheduledJob();
	
EndProcedure

&AtClient
Procedure WriteAndCloseExecute()
	
	WriteAndCloseCompletion();
	
EndProcedure

&AtClient
Procedure SetUpScheduleExecute()

	Dialog = New ScheduledJobDialog(Schedule);
	Dialog.Show(New CallbackDescription("OpenScheduleEnd", ThisObject));
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WriteAndCloseCompletion(Result = Undefined, AdditionalParameters = Undefined) Export
	
	WriteScheduledJob();
	Modified = False;
	Close();
	
EndProcedure

&AtClient
Procedure OpenScheduleEnd(NewSchedule, Context) Export

	If NewSchedule <> Undefined Then
		Schedule = NewSchedule;
		Modified = True;
		If DataSeparationEnabled 
			And Schedule.RepeatPeriodInDay > 0
			And Schedule.RepeatPeriodInDay < 3600 Then
			
			Schedule.RepeatPeriodInDay = 3600;
			
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteScheduledJob()
	
	If Not ValueIsFilled(NameOfMetadataObjects) Then
		Return;
	EndIf;
	
	CurrentID = ?(Action = "Change", Id, Undefined);
	
	WriteScheduledJobAtServer();
	RefreshFormTitle();
	
	Notify("Write_ScheduledJobs", CurrentID);
	
EndProcedure

&AtServer
Procedure WriteScheduledJobAtServer()
	
	JobParameters = New Structure();
	JobParameters.Insert("Key");
	JobParameters.Insert("Description");
	JobParameters.Insert("Use");
	JobParameters.Insert("UserName");
	JobParameters.Insert("RestartIntervalOnFailure");
	JobParameters.Insert("RestartCountOnFailure");
	JobParameters.Insert("Parameters", New Array());
	JobParameters.Insert("Schedule");
	If Not Action = "Change" Then
		JobParameters.Insert("Metadata", NameOfMetadataObjects);
	EndIf;
	
	FillPropertyValues(
		JobParameters,
		ThisObject,
		"Key, 
		|Description,
		|Use,
		|UserName,
		|RestartIntervalOnFailure,
		|RestartCountOnFailure,
		|Schedule");
		
	SetPrivilegedMode(True);

	If Action = "Change" Then
		ChangeJob(Id, JobParameters);
	Else
		UniqueIdentifierOfTheTask = AddJob(JobParameters);
		Id = String(UniqueIdentifierOfTheTask);
	EndIf;

	SetPrivilegedMode(False);

	Modified = False;
	
EndProcedure

&AtClient
Procedure RefreshFormTitle()
	
	If Not IsBlankString(Description) Then
		Presentation = Description;
		
	ElsIf Not IsBlankString(MetadataSynonym) Then
		Presentation = MetadataSynonym;
	Else
		Presentation = NameOfMetadataObjects;
	EndIf;
	
	If Action = "Change" Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (Nhiệm vụ thường kỳ)';
																				|ru = '%1 (Регламентное задание)';
																				|en = '%1 (Scheduled job)'; fa = '%1 (Scheduled job)';
																				|it = '%1 (Регламентное задание)';
																				|pl = '%1 (Planowe zadanie)';
																				|tr = '%1 (Zamanlanmış görev)'"), Presentation);
	Else
		Title = NStr("vi = 'Nhiệm vụ thường kỳ (tạo mới)';
					|ru = 'Регламентное задание (создание)';
					|en = 'Scheduled job (Create)'; fa = 'Scheduled job (Create)';
					|it = 'Регламентное задание (создание)';
					|pl = 'Planowe zadanie (utworzenie)';
					|tr = 'Zamanlanmış görev (oluşturma)'");
	EndIf;
	
EndProcedure

#Region ScheduledJobs

// Returns a routine task from the information base.
//
// In the service model, it works with scheduled tasks of the platform, not with queue tasks,
// in the same way in both split and undivided modes.
//
// Parameters:
//  Id - MetadataObject - a scheduled task metadata object for searching
//                  for a predefined scheduled task.
//                - UUID - ID of the scheduled task.
//                - String - the string of the unique identifier of the routine task.
//                - ScheduledJob - the routine task from which you need to get
//                  a unique identifier for getting a fresh copy of the routine task.
// 
// Returns:
//  ScheduledJob - read from the database.
//
&AtServer
Function GetScheduledJob(Id)

	SetPrivilegedMode(True);

	Job_Result = ScheduledJobsServer.Job(Id);

	SetPrivilegedMode(False);
	
	If TypeOf(Job_Result)  = Type("ValueTableRow") Then
		Job = Job_Result.UUID;
	Else
		Job = Job_Result;
	EndIf;
	
	Return Job;
	
EndFunction

// Adds a new task to the queue or routine.
// 
// Parameters: 
//  JobParameters - Structure - parameters of the task being added, possible properties:
//   * Use - Boolean - True if the scheduled task should be performed automatically according to the schedule. 
//   * Metadata    - MetadataObjectScheduledJob - be sure to specify. The metadata object 
//                              that will be used to create the routine task.
//   * Parameters     - Array - parameters of the routine task. The number and composition of parameters must correspond 
//                              to the parameters of the routine task method.
//   * Key          - String - application ID of the scheduled task.
//   * RestartIntervalOnFailure - Number - the interval in seconds after which the task should be restarted 
//                              in case of an emergency.
//   * Schedule    - JobSchedule - the job schedule.
//   * RestartCountOnFailure - Number - the number of repetitions when the task crashes.
//
// Returns:
//  ScheduledJob,
//  See ScheduledJobsServer.FindJobs - in local operation mode,
// 
&AtServer
Function AddJob(JobParameters)

	SetPrivilegedMode(True);

	Job = ScheduledJobsServer.AddJob(JobParameters);
	UniqueIdentifierOfTheTask = ScheduledJobsServer.UUID(Job);
	
	SetPrivilegedMode(False);
	
	Action = "Change";
	
	Return UniqueIdentifierOfTheTask;
	
EndFunction

// Modifies a queue task or a routine one.
//
// In the service model (separation is enabled):
// - in case of a call in a transaction, an object lock is set for a task,
// - if the task is created based on a template or predefined,
// only the Use property can be specified in the Parameters parameter. In this case, the schedule
// cannot be changed, because it is stored centrally in an undivided task Template,
// it is not stored separately for each area.
// 
// Parameters: 
//  Id - MetadataObject - a routine task metadata object for searching
//                                     for an undefined routine task.
//                - String - the metadata name of a predefined routine task in any operating mode
//                           , or a string of the unique identifier of the routine task in the local operating mode
//                           , or a string of the unique identifier of the queue task link in the service model.
//                - UUID - the ID of the routine task in the local operation mode
//                           or the ID of the queue task link in the service model.
//                - ScheduledJob - routine task in local operation mode.
//                - CatalogRef.JobsQueue - id of the queue job in the service model.
//                - ValueTableRow: See ScheduledJobsServer.FindJobs
//
//  JobParameters - Structure - parameters to set for the task, possible properties:
//   * Use - Boolean - True if the scheduled task should be performed automatically according to the schedule.
//   * Parameters     - Array - parameters of the routine task. The number and composition of parameters must correspond
//                              to the parameters of the routine task method.
//   * Key          - String - application ID of the scheduled task.
//   * RestartIntervalOnFailure - Number - the interval in seconds after which the task should be restarted
//                              in case of an emergency.
//   * Schedule    - JobSchedule - the job schedule.
//   * RestartCountOnFailure - Number - the number of repetitions when the task crashes.
//
&AtServer
Procedure ChangeJob(Id, JobParameters)

	SetPrivilegedMode(True);

	ScheduledJobsServer.ChangeJob(Id, JobParameters);

	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region Other
&AtClientAtServerNoContext
Function AutoDescription(Form)
	
	NameString_ = Form.MetadataSynonym;
	
	If Form.Items.Description.ChoiceList.Count() = 0 Then
		Form.Items.Description.ChoiceList.Add(NameString_);
	EndIf;
	
	If Form.AutomaticNamingIndex <= Form.Items.Description.ChoiceList.Count() - 1 Then
		Return Form.Items.Description.ChoiceList.Get(Form.AutomaticNamingIndex).Value;
	Else
		Return NameString_;
	EndIf;
	
EndFunction

&AtClient
Procedure UpdateAutoNaming(Refresh = True)
	
	NameOfRow = AutoDescription(ThisObject);
	If Not ValueIsFilled(Description)
		Or (Refresh And AutoNameIsUsed And Not NameIsChangedByUser) Then
		Description = NameOfRow;
		AutoNameIsUsed = True;
		RefreshFormTitle();
	EndIf;
	
EndProcedure

// Update auto-naming details
//
&AtServer
Procedure UpdateAutoNamingDetails()
	
	AutomaticNamingIndex = 0;
	NameIsChangedByUser = True;
	AutoNameIsUsed = False;
	For Each ListItem In Items.Description.ChoiceList Do
		
		If ListItem.Value = Description Then
			AutoNameIsUsed = True;
			NameIsChangedByUser = False;
			AutomaticNamingIndex = Items.Description.ChoiceList.IndexOf(ListItem);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
