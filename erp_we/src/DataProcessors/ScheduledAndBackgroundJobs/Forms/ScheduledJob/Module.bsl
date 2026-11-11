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
	
	If Not Users.IsFullUser(, True) Then
		Raise NStr("vi = 'Không đủ quyền truy cập.
		                             |Chỉ người quản trị có thể thay đổi thuộc tính của nhiệm vụ thường kỳ.';
		                             |ru = 'Недостаточно прав доступа.
		                             |Изменение свойств регламентного задания доступно только администратору.';
		                             |en = 'Insufficient access rights.
		                             |Only administrators can change scheduled job settings.'; fa = 'Insufficient access rights.
		                             |Only administrators can change scheduled job settings.';
		                             |it = 'Недостаточно прав доступа.
		                             |Изменение свойств регламентного задания доступно только администратору.';
		                             |pl = 'Insufficient access rights.
		                             |Only administrators can change scheduled job settings.';
		                             |tr = 'Yetersiz erişim hakları.
		                             |Zamanlanmış görevin özelliklerini değiştirmek yalnızca yönetici tarafından yapılabilir.'",
			ErrorCategory.AccessViolation);
	EndIf;
	
	Action = Parameters.Action;
	If StrFind(", Add, Copy, Change,", ", " + Action + ",") = 0 Then
		Raise NStr("vi = 'Sai tham số mở biểu mẫu ""Nhiệm vụ thường kỳ"".';
					|ru = 'Неверные параметры открытия формы ""Регламентное задание"".';
					|en = 'Cannot open the ""Scheduled job"" form. Invalid opening parameters.'; fa = 'Cannot open the ""Scheduled job"" form. Invalid opening parameters.';
					|it = 'Parametri scorretti di apertura del modulo ""Task di routine"".';
					|pl = 'Nieprawidłowe ustawienia otwierania formy ""Planowe zadanie"".';
					|tr = '""Zamanlanmış iş"" açılış formun yanlış parametreleri.'",
			ErrorCategory.ConfigurationError);
	EndIf;
	
	If Action = "Add" Then
		
		ParameterizedJobs = New Map;
		JobDependencies     = ScheduledJobsInternal.ScheduledJobsDependentOnFunctionalOptions();
		
		FilterParameters        = New Structure;
		FilterParameters.Insert("IsParameterized", True);
		SearchResult = JobDependencies.FindRows(FilterParameters);
		
		For Each TableRow In SearchResult Do
			ParameterizedJobs[TableRow.ScheduledJob] = True;
		EndDo;
		
		Schedule = New JobSchedule;
		
		For Each ScheduledJobMetadata1 In Metadata.ScheduledJobs Do
			If ParameterizedJobs[ScheduledJobMetadata1] <> Undefined Then
				Continue;
			EndIf;
			
			ScheduledJobMetadataDetailsCollection.Add(ScheduledJobMetadata1.Name + Chars.LF
					+ ScheduledJobMetadata1.Synonym + Chars.LF
					+ ScheduledJobMetadata1.MethodName,
				?(IsBlankString(ScheduledJobMetadata1.Synonym),
				  ScheduledJobMetadata1.Name,
				  ScheduledJobMetadata1.Synonym) );
		EndDo;
	Else
		Job = ScheduledJobsServer.GetScheduledJob(Parameters.Id);
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
		
		Id = String(Job.UUID);
		If Job.Metadata = Undefined Then
			NameOfMetadataObjects        = NStr("vi = '<không có metadata>';
												|ru = '<нет метаданных>';
												|en = '<no metadata>'; fa = '<no metadata>';
												|it = '<nessun metadato>';
												|pl = '<brak metadanych>';
												|tr = '<meta veri yok>'");
			MetadataSynonym    = NStr("vi = '<không có metadata>';
										|ru = '<нет метаданных>';
										|en = '<no metadata>'; fa = '<no metadata>';
										|it = '<nessun metadato>';
										|pl = '<brak metadanych>';
										|tr = '<meta veri yok>'");
			MetadataMethodName  = NStr("vi = '<không có metadata>';
										|ru = '<нет метаданных>';
										|en = '<no metadata>'; fa = '<no metadata>';
										|it = '<nessun metadato>';
										|pl = '<brak metadanych>';
										|tr = '<meta veri yok>'");
		Else
			NameOfMetadataObjects        = Job.Metadata.Name;
			MetadataSynonym    = Job.Metadata.Synonym;
			MetadataMethodName  = Job.Metadata.MethodName;
		EndIf;
		Schedule = Job.Schedule;
		
		If Action = "Copy" Then
			Predefined = False;
		Else
			MessagesToUserAndErrorDescription =
				ScheduledJobsInternal.ScheduledJobMessagesAndErrorDescriptions(Job);
		EndIf;
		
		Items.Description.Visible = Not Predefined;
	EndIf;
	
	If Action <> "Change" Then
		Id = NStr("vi = '<sẽ tạo khi ghi>';
					|ru = '<будет создан при записи>';
					|en = '<will be generated automatically>'; fa = '<will be generated automatically>';
					|it = '<verrà creato alla registrazione>';
					|pl = '<zostanie utworzone po zapisie>';
					|tr = '<yazarken oluşturulacak>'");
		Use = False;
		
		Description = ?(Action = "Add", "", ScheduledJobsInternal.ScheduledJobPresentation(Job));
	EndIf;
	
	// Populate the choice list with usernames.
	UsersArray = InfoBaseUsers.GetUsers(); // Array of InfoBaseUser
	For Each User In UsersArray Do
		Items.UserName.ChoiceList.Add(User.Name);
	EndDo;
	
EndProcedure 

&AtClient
Procedure OnOpen(Cancel)
	
	If Action = "Add" Then
		AttachIdleHandler("SelectNewScheduledJobTemplate", 0.1, True);
	Else
		RefreshFormTitle();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("WriteAndCloseCompletion", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	
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
Procedure SelectNewScheduledJobTemplate()
	
	// Scheduled job template selection (metadata).
	ScheduledJobMetadataDetailsCollection.ShowChooseItem(
		New CallbackDescription("SelectNewScheduledJobTemplateCompletion", ThisObject),
		NStr("vi = 'Hãy chọn khuôn mẫu nhiệm vụ thường kỳ';
			|ru = 'Выберите шаблон регламентного задания';
			|en = 'Select a scheduled job template'; fa = 'Select a scheduled job template';
			|it = 'Selezionate un modello del task di routine';
			|pl = 'Wybierz szablon planowego zadania';
			|tr = 'Zamanlanmış bir iş şablonu seçin'"));
	
EndProcedure

&AtClient
Procedure SelectNewScheduledJobTemplateCompletion(ListItem, Context) Export
	
	If ListItem = Undefined Then
		Close();
		Return;
	EndIf;
	
	NameOfMetadataObjects       = StrGetLine(ListItem.Value, 1);
	MetadataSynonym   = StrGetLine(ListItem.Value, 2);
	MetadataMethodName = StrGetLine(ListItem.Value, 3);
	Description        = ListItem.Presentation;
	
	RefreshFormTitle();
	
EndProcedure

&AtClient
Procedure OpenScheduleEnd(NewSchedule, Context) Export

	If NewSchedule <> Undefined Then
		Schedule = NewSchedule;
		Modified = True;
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
	
	JobParameters = New Structure(
	"Key,
	|Description,
	|Use,
	|UserName,
	|RestartIntervalOnFailure,
	|RestartCountOnFailure,
	|Schedule");
	FillPropertyValues(JobParameters, ThisObject);
	
	If Action = "Change" Then
		ScheduledJobsServer.ChangeScheduledJob(Id, JobParameters);
	Else
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs[NameOfMetadataObjects]);
		
		Job = ScheduledJobsServer.AddARoutineTask(JobParameters);
		
		Id = String(Job.UUID);
		Action = "Change";
	EndIf;
	
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
																				|it = '%1 (Task di routine)';
																				|pl = '%1 (Planowe zadanie)';
																				|tr = '%1 (Planlanmış iş)'"), Presentation);
	Else
		Title = NStr("vi = 'Nhiệm vụ thường kỳ (tạo mới)';
					|ru = 'Регламентное задание (создание)';
					|en = 'Scheduled job (Create)'; fa = 'Scheduled job (Create)';
					|it = 'Task di routine (creazione)';
					|pl = 'Planowe zadanie (utworzenie)';
					|tr = 'Zamanlanmış görev (oluşum)'");
	EndIf;
	
EndProcedure

#EndRegion
