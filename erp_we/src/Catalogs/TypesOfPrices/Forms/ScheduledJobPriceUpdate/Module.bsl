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
	
	If Not AccessRight("Update", Metadata.Catalogs.TypesOfPrices) Then
		Raise NStr("vi = 'Không đủ quyền truy cập.
		                             |
		                             |Chỉ người sử dụng có quyền thay đổi dạng giá
		                             |có thể thay đổi thuộc tính nhiệm vụ thường kỳ.';
		                             |ru = 'Недостаточно прав доступа.
		                             |
		                             |Изменение свойств регламентного задания
		                             |выполняется только пользователями с правом изменения видов цен.';
		                             |en = 'Insufficient access rights.
		                             |
		                             |Only users with the right to change price types
		                             |can change scheduled job properties.'; fa = 'Insufficient access rights.
		                             |
		                             |Only users with the right to change price types
		                             |can change scheduled job properties.';
		                             |it = 'Недостаточно прав доступа.
		                             |
		                             |Изменение свойств регламентного задания
		                             |выполняется только пользователями с правом изменения видов цен.';
		                             |pl = 'Insufficient access rights.
		                             |
		                             |Only users with the right to change price types
		                             |can change scheduled job properties.';
		                             |tr = 'Yetersiz erişim hakkı.
		                             |
		                             |Programlı bir işin özelliklerini değiştirmek
		                             |sadece fiyat türlerini değiştirme yetkisine sahip kullanıcılar tarafından yapılmaktadır.'");
	EndIf;
	
	Action = Parameters.Action;
	
	If StrFind(", Add, Copy, Change,", ", " + Action + ",") = 0 Then
		Raise NStr("vi = 'Sai tham số mở biểu mẫu ""Nhiệm vụ thường kỳ"".';
					|ru = 'Неверные параметры открытия формы ""Регламентное задание"".';
					|en = 'Cannot open the ""Scheduled job"" form. Invalid opening parameters.'; fa = 'Cannot open the ""Scheduled job"" form. Invalid opening parameters.';
					|it = 'Parametri scorretti di apertura del modulo ""Task di routine"".';
					|pl = 'Nieprawidłowe ustawienia otwierania formy ""Planowe zadanie"".';
					|tr = '""Programlı iş"" açılış formunun yanlış parametreleri.'");
	EndIf;
	
	If Action = "Add" Then
		
		Schedule = New JobSchedule;
		Job = Metadata.ScheduledJobs.UpdatePrices;
		
		NameOfMetadataObjects       = Job.Name;
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
			
			If Job.Parameters.Count() Then
				FillInDetailsByParameters(Job.Parameters);
			EndIf;
		
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

			Schedule = Structure_Of_Task.Schedule.Get();
			
			JobParameters = Structure_Of_Task.Parameters.Get();
			If JobParameters.Count() Then
				FillInDetailsByParameters(JobParameters);
			EndIf;
		EndIf;

		If IsFullUser And TypeOf(Job) = Type("ScheduledJob") Then
			MessagesToUserAndErrorDescription = ScheduledJobsInternal.ScheduledJobMessagesAndErrorDescriptions(Job);
		EndIf;
	EndIf;
	
	If Action <> "Change" Then
		Id = NStr("vi = '<sẽ tạo khi ghi lại>';
					|ru = '<будет создан при записи>';
					|en = '<will be generated automatically>'; fa = '<will be generated automatically>';
					|it = '<verrà creato alla registrazione>';
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
	
	OptionToUpdatePricesWhenChangingOnServer(ThisObject);
EndProcedure 

&AtClient
Procedure OnOpen(Cancel)
	
	If Action = "Add" Then
		
		RefreshFormTitle();
		SetFormItemsVisibility();
		
	Else
		RefreshFormTitle();
		SetFormItemsVisibility();
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

&AtClient
Procedure PriceUpdateOptionOnChange(Item)
	
	OptionToUpdatePricesWhenChangingOnServer(ThisObject);	
	
	UpdateAutoNaming();
	
EndProcedure

&AtClient
Procedure TypesOfPricesOnEditEnd(Item, NewRow, CancelEdit)
	
	UpdateAutoNaming();
	
EndProcedure

//&NaKliente
//The procedure for updating the price of the change(Element)
//	
//	is to update the Auto-name();
//	
//End of the procedure

&AtClient
Procedure TypesOfPricesAfterDeleteRow(Item)
	
	UpdateAutoNaming();
	
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
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.UpdatePrices);
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

	TableOfPriceTypes = New ValueTable();
	TableOfPriceTypes.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));
	TableOfPriceTypes.Columns.Add("ResetPrices",New TypeDescription("Boolean"));
	For Each Item In TypesOfPrices Do
		TableRow = TableOfPriceTypes.Add();
		TableRow.PriceKind 		= Item.Value;
		TableRow.ResetPrices 	= False;
	EndDo;
	
	ParametersOfUpdate = New Structure("PriceUpdateOption", PriceUpdateOption);
	
	JobParameters.Parameters.Add(TableOfPriceTypes);
	JobParameters.Parameters.Add(ParametersOfUpdate);
	
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
																				|it = '%1 (Task di routine)';
																				|pl = '%1 (Planowe zadanie)';
																				|tr = '%1 (Programlı iş)'"), Presentation);
	Else
		Title = NStr("vi = 'Nhiệm vụ thường kỳ (tạo mới)';
					|ru = 'Регламентное задание (создание)';
					|en = 'Scheduled job (Create)'; fa = 'Scheduled job (Create)';
					|it = 'Task di routine (creazione)';
					|pl = 'Planowe zadanie (utworzenie)';
					|tr = 'Zamanlanmış görev (oluşturma)'");
	EndIf;
	
EndProcedure

&AtClient
Procedure SetFormItemsVisibility()
	
	Items.PriceTypeSettingsGroup.Visible = True; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure OptionToUpdatePricesWhenChangingOnServer(Form)
	
	Form.Items.TypesOfPricesForAutomaticUpdates.Enabled = (Form.PriceUpdateOption<>0);

	If Form.PriceUpdateOption=0 And Form.TypesOfPrices.Count() Then
		Form.TypesOfPrices.Clear();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDetailsByParameters(Var_Parameters)
	
	TypesOfPrices.Clear();
	
	If (Var_Parameters.Count() > 0) Then
		
		For Each String In Var_Parameters[0] Do
			TypesOfPrices.Add(String.PriceKind);
		EndDo;
		
		PriceUpdateOption = Var_Parameters[1].PriceUpdateOption;
		
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
//  ScheduledJob - in the local mode of operation.
//  String of value tables from See ScheduledJobsServer.FindJobs
//  Undefined - the task was not found.
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
//  UUID - the ID of the routine task in the local operation mode
//                            or the ID of the queue task link in the service model.
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
//  Parameters - Structure - parameters to set for the job, possible properties:
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
Procedure ChangeJob(Id, JobParameters) Export

	SetPrivilegedMode(True);

	ScheduledJobsServer.ChangeJob(Id, JobParameters);

	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region Other
&AtClientAtServerNoContext
Function AutoDescription(Form)
	
	Form.Items.Description.ChoiceList.Clear();
	
	NameString_ = "";
	
	NameString_ = NStr("vi = 'Cập nhật giá (';
						|ru = 'Обновление цен (';
						|en = 'Update prices ('; fa = 'Update prices (';
						|it = 'Aggiornamento prezzi (';
						|pl = 'Aktualizacja cen (';
						|tr = 'Fiyat güncellemesi ('");
	
	If Form.PriceUpdateOption = 0 Then
		NameString_ = NameString_ + NStr("vi = 'Tất cả)';
										|ru = 'Все)';
										|en = 'All)'; fa = 'All)';
										|it = 'Tutti)';
										|pl = 'Wszystkie)';
										|tr = 'Tümü)'");
	ElsIf Form.PriceUpdateOption = 1 Then
		NameString_ = NameString_ + NStr("vi = 'Chỉ mục được chọn)';
										|ru = 'Только выбранные)';
										|en = 'Selected roles only)'; fa = 'Selected roles only)';
										|it = 'Solo selezionate)';
										|pl = 'Tylko wybrane)';
										|tr = 'Sadece seçilenler)'");
	ElsIf Form.PriceUpdateOption = 2 Then
		NameString_ = NameString_ + NStr("vi = 'Các mục được chọn và phụ thuộc)';
										|ru = 'Выбранные и зависимые)';
										|en = 'Selected and dependent)'; fa = 'Selected and dependent)';
										|it = 'Selezionati e dipendenti)';
										|pl = 'Wybrane i zależne)';
										|tr = 'Seçilenler ve bağlı olanlar)'");
	ElsIf Form.PriceUpdateOption = 3 Then
		NameString_ = NameString_ + NStr("vi = 'Tất cả ngoại trừ các mục được chọn)';
										|ru = 'Все кроме выбранных)';
										|en = 'All except selected)'; fa = 'All except selected)';
										|it = 'Tutti tranne i selezionati)';
										|pl = 'Wszystkie oprócz wybranych)';
										|tr = 'Seçilenler hariç tümü)'");
	EndIf;
	
	ThisIsFirstItemOfList = True;
	For Each PriceKind In Form.TypesOfPrices Do
		NameString_ = NameString_ + ?(ThisIsFirstItemOfList," ",", ") + PriceKind;
		ThisIsFirstItemOfList = False;
	EndDo;
	
	Form.Items.Description.ChoiceList.Add(NameString_);
	
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
		
		If ListItem.Value = ThisObject.Description Then
			AutoNameIsUsed = True;
			NameIsChangedByUser = False;
			AutomaticNamingIndex = Items.Description.ChoiceList.IndexOf(ListItem);
		EndIf;
		
	EndDo;
	
EndProcedure
#EndRegion

#EndRegion
