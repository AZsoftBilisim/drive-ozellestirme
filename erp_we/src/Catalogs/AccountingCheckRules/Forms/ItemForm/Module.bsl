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
	
	If Not ValueIsFilled(Object.Ref) Then
		Raise NStr("vi = 'Cấm tạo trực tác.';
					|ru = 'Интерактивное создание запрещено.';
					|en = 'Interactive creation is prohibited.'; fa = 'Interactive creation is prohibited.';
					|it = 'La creazione interattiva è vietata.';
					|pl = 'Tworzenie interaktywne jest zabronione.';
					|tr = 'Manuel oluşturma yasaktır.'");
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	Items.IndividualSchedulePresentation.Enabled = Not ReadOnly;
	Items.PresentationOfCommonSchedule.Enabled          = Not ReadOnly;
	
	CurrentCheckMetadata = CheckMetadata(Object.Id);
	SetImportanceFieldAccessibility(ThisObject, CurrentCheckMetadata);
	SetPathToHandlerProcedure(ThisObject, CurrentCheckMetadata);
	
	AccountingCheckRulesSettingAllowed = AccessRight("Update", Metadata.Catalogs.AccountingCheckRules);
	Items.FormExecuteCheck.Visible              = Users.IsFullUser(, False);
	Items.FormCustomizeStandardSettings.Visible = AccountingCheckRulesSettingAllowed;
	
	SetInitialScheduleSettings();
	IsSystemAdministrator = Users.IsFullUser(, True);
	If IsSystemAdministrator Then
		GenerateSchedules();
	Else
		Items.ScheduleGroup.Visible = False;
	EndIf;
		
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not ValueIsFilled(CurrentObject.Code) Then
		CurrentObject.SetNewCode();
	EndIf;
	
	If ValueIsFilled(IndividualScheduleAddress) Then
		CurrentObject.CheckRunSchedule = GetFromTempStorage(IndividualScheduleAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure IndividualSchedulePresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	StorageData = GetFromTempStorage(FormattedStringURL);
	If StorageData = "AddJob" Then
		ScheduleDialog1    = New ScheduledJobDialog(New JobSchedule);
		ChangeNotification = New CallbackDescription("AddJobAtClientCompletion", ThisObject);
		ScheduleDialog1.Show(ChangeNotification);
	Else
		ScheduleDialog1    = New ScheduledJobDialog(StorageData);
		ChangeNotification = New CallbackDescription("ChangeTaskOnClientCompletion", ThisObject);
		ScheduleDialog1.Show(ChangeNotification);
	EndIf;
	
EndProcedure

&AtClient
Procedure RunsInBackgroundOnScheduleOnChange(Item)
	
	If RunsInBackgroundOnSchedule Then
		SetScheduleSettingsAtServer();
	Else
		HideScheduleSettingsAtServer();
	EndIf;
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ScheduleSelectorOnChange(Item)
	
	SetScheduleSettingsAtServer();
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteCheck(Command)
	
	If Not Write() Then
		Return;
	EndIf;	
	
	If Not Object.Use Then
		CallbackOnCompletion = New CallbackDescription("ExecuteCheckAfterQuestion", ThisObject);
		ShowQueryBox(CallbackOnCompletion, NStr("vi = 'Đã vô hiệu hóa kiểm tra. Vẫn thực hiện tất cả?';
												|ru = 'Проверка отключена. Все равно выполнить?';
												|en = 'Checkup is disabled. Check anyway?'; fa = 'Checkup is disabled. Check anyway?';
												|it = 'Verifica disattivata. Eseguire comunque?';
												|pl = 'Sprawdzenie jest wyłączone. Wykonać mimo wszystko?';
												|tr = 'Kontrol devre dışı. Yine de yapılsın mı?'"), QuestionDialogMode.YesNo);
		Return;
	EndIf;	
	
	ExecuteCheckAfterQuestion(DialogReturnCode.Yes, Undefined);
	
EndProcedure

&AtClient
Procedure CustomizeStandardSettings(Command)
	
	QueryText = NStr("vi = 'Đặt tùy chỉnh chuẩn';
					|ru = 'Установить стандартные настройки?';
					|en = 'Restore default settings?'; fa = 'Restore default settings?';
					|it = 'Impostare le impostazioni standard?';
					|pl = 'Ustawić ustawienia standardowe?';
					|tr = 'Standart ayarlar kullanılsın mı?'");
	Handler = New CallbackDescription("SetStandardSettingsAtClient", ThisObject);
	ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ClearCheckResults(Command)
	ClearCheckResultsAtServer();
	Message = NStr("vi = 'Đã xóa thành công kết quả kiểm tra trước đó.';
					|ru = 'Результаты предыдущих проверок успешно очищены.';
					|en = 'The results of the previous checks are successfully cleared.'; fa = 'The results of the previous checks are successfully cleared.';
					|it = 'Risultati delle verifiche precedenti cancellati con successo.';
					|pl = 'Wyniki poprzednich sprawdzeń zostały pomyślnie wyczyszczone.';
					|tr = 'Önceki kontrollerin sonuçları başarıyla temizlendi.'");
	CommonClient.MessageToUser(Message);
EndProcedure

#EndRegion

#Region Private

&AtServer
Function RunCheckAtServer()
	
	If TimeConsumingOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thực hiện kiểm tra tiến hành kế toán ""%1""';
			|ru = 'Выполнение проверки ведения учета ""%1""';
			|en = 'Run data integrity check ""%1""'; fa = 'Run data integrity check ""%1""';
			|it = 'Esecuzione della verifica di contabilità ""%1""';
			|pl = 'Wykonanie sprawdzenia prowadzenia ewidencji ""%1""';
			|tr = '""%1"" muhasebe kontrolünü yap'"), Object.Description);
	
	Checks = New Array;
	Checks.Add(Object.Ref);
	Return TimeConsumingOperations.ExecuteProcedure(ExecutionParameters, "AccountingAuditInternal.ExecuteChecks", Checks);
	
EndFunction

&AtClient
Procedure ExecuteCheckAfterQuestion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;	
	
	TimeConsumingOperation = RunCheckAtServer();
	
	CallbackOnCompletion = New CallbackDescription("ExecuteCheckCompletion", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.MessageText = NStr("vi = 'Đang thực hiện kiểm tra. Điều này có thể mất nhiều thời gian.';
										|ru = 'Выполняется проверка. Это может занять некоторое время.';
										|en = 'Checking. This might take a while.'; fa = 'Checking. This might take a while.';
										|it = 'Verifica in corso. Questo potrebbe richiedere alcuni minuti.';
										|pl = 'Trwa wykonanie sprawdzenia, To może zająć trochę czasu.';
										|tr = 'Kontrol yapılıyor. İşlem biraz zaman alabilir.'");
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure ExecuteCheckCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		
	ElsIf Result.Status = "Completed2" Then
		ShowUserNotification(NStr("vi = 'Đã thực hiện kiểm tra';
									|ru = 'Проверка выполнена';
									|en = 'Scan completed'; fa = 'Scan completed';
									|it = 'Verifica effettuata';
									|pl = 'Weryfikacja wykonana';
									|tr = 'Kontrol tamamlandı'"),,
			NStr("vi = 'Đã hoàn tất thành công kiểm tra quản lý kế toán.';
				|ru = 'Проверка ведения учета завершена успешно.';
				|en = 'Data integrity check completed successfully.'; fa = 'Data integrity check completed successfully.';
				|it = 'Verifica di contabilità eseguita con successo.';
				|pl = 'Sprawdzenie prowadzenia ewidencji zostało zakończone pomyślnie.';
				|tr = 'Muhasebe kontrolü başarıyla tamamlandı.'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateSchedules()
	
	GenerateRowWithCommonSchedule();
	GenerateRowWithIndividualSchedule();
	
EndProcedure

&AtServer
Procedure GenerateRowWithIndividualSchedule()
	
	ScheduledJobID = Object.ScheduledJobID;
	SeparateScheduledJob      = Undefined;
	SeparateScheduledJobPresentation  = "";
	
	If ValueIsFilled(ScheduledJobID) Then
		SeparateScheduledJob = ScheduledJobsServer.Job(ScheduledJobID);
		If SeparateScheduledJob <> Undefined Then
			SeparateScheduledJobPresentation = String(SeparateScheduledJob.Schedule) + ". ";
		EndIf;
	EndIf;
	
	If Not Common.DataSeparationEnabled() Then
		
		If SeparateScheduledJob = Undefined Then
			Items.IndividualSchedulePresentation.Title = 
				New FormattedString(NStr("vi = 'Tùy chỉnh lịch biểu';
										|ru = 'Настроить расписание';
										|en = 'Set schedule'; fa = 'تعیین زمان‌بندی';
										|it = 'Impostare l''orario';
										|pl = 'Ustaw harmonogram';
										|tr = 'Programı ayarlamak'"), , , , PutToTempStorage("AddJob", UUID));
		Else
			Items.IndividualSchedulePresentation.Title = 
				New FormattedString(SeparateScheduledJobPresentation, , , , PutToTempStorage(SeparateScheduledJob.Schedule, UUID));
		EndIf;
		
	Else
		
		If SeparateScheduledJob = Undefined Then
			Items.IndividualSchedulePresentation.Title = 
				New FormattedString(SeparateScheduledJobPresentation + ". ", , StyleColors.HyperlinkColor);
		Else
			Items.IndividualSchedulePresentation.Title = 
				New FormattedString(SeparateScheduledJobPresentation, , StyleColors.HyperlinkColor);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateRowWithCommonSchedule()
	
	CommonScheduledJob = ScheduledJobsServer.Job(Metadata.ScheduledJobs.AccountingCheck);
	If CommonScheduledJob <> Undefined Then
		If Not Common.DataSeparationEnabled() Then
			CommonSchedulePresentation = String(CommonScheduledJob.Schedule);
		Else
			If Users.IsFullUser(, True) Then
				CommonSchedule = Common.ObjectAttributeValue(CommonScheduledJob.Template, "Schedule").Get();
				CommonSchedulePresentation = String(CommonSchedule);
			EndIf;
		EndIf;
	Else
		CommonSchedulePresentation = NStr("vi = 'Nhiệm vụ thường kỳ không khả dụng';
											|ru = 'Регламентное задание не доступно';
											|en = 'The scheduled job is not available'; fa = 'The scheduled job is not available';
											|it = 'Compito pianificato non disponibile';
											|pl = 'Zadanie reglamentowane jest niedostępne';
											|tr = 'Zamanlanmış görev kullanılamıyor'");
	EndIf;
	
	Items.PresentationOfCommonSchedule.Title = 
		New FormattedString(CommonSchedulePresentation, , StyleColors.HyperlinkColor);
	
EndProcedure

&AtClient
Procedure ChangeTaskOnClientCompletion(Schedule, AdditionalParameters) Export
	ChangeJobAtServerCompletion(Schedule, AdditionalParameters);
EndProcedure

&AtServer
Procedure ChangeJobAtServerCompletion(Schedule, AdditionalParameters)
	
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	ScheduledJob = ScheduledJobsServer.Job(Object.ScheduledJobID);
	If ScheduledJob = Undefined Then
		AddTaskOnServerCompletion(Schedule, AdditionalParameters);
	Else
		
		ScheduledJobsServer.ChangeJob(Object.ScheduledJobID, New Structure("Schedule", Schedule));
		Items.IndividualSchedulePresentation.Title = 
			New FormattedString(String(Schedule), , , , PutToTempStorage(Schedule, UUID));
		
		IndividualScheduleAddress = PutToTempStorage(New ValueStorage(CommonClientServer.ScheduleToStructure(Schedule)), UUID);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddJobAtClientCompletion(Schedule, AdditionalParameters) Export
	AddTaskOnServerCompletion(Schedule, AdditionalParameters);
EndProcedure

&AtServer
Procedure AddTaskOnServerCompletion(Schedule, AdditionalParameters)
		
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	JobParameters = New Structure;
	JobParameters.Insert("Schedule",    Schedule);
	JobParameters.Insert("Use", True);
	JobParameters.Insert("Metadata",    Metadata.ScheduledJobs.AccountingCheck);
	
	ScheduledJob = ScheduledJobsServer.AddJob(JobParameters);
	
	Object.ScheduledJobID = String(ScheduledJob.UUID);
	
	JobParameters = New Structure;
	
	ParametersArray = New Array;
	ParametersArray.Add(String(ScheduledJob.UUID));
	
	JobParameters.Insert("Parameters", ParametersArray);
	ScheduledJobsServer.ChangeJob(ScheduledJob.UUID, JobParameters);
	
	Items.IndividualSchedulePresentation.Title =
		New FormattedString(String(Schedule), , , , PutToTempStorage(Schedule, UUID));
		
	IndividualScheduleAddress = PutToTempStorage(New ValueStorage(CommonClientServer.ScheduleToStructure(Schedule)), UUID);
	
EndProcedure

&AtServerNoContext
Function CheckMetadata(Id)
	
	CheckStructure = New Structure;
	Checks          = AccountingAuditInternalCached.AccountingChecks().Checks;
	CheckString    = Checks.Find(Id, "Id");
	
	If CheckString = Undefined Then
		Return Undefined;
	Else
		ChecksColumns = Checks.Columns;
		For Each CurrentColumn In ChecksColumns Do
			CheckStructure.Insert(CurrentColumn.Name, CheckString[CurrentColumn.Name]);
		EndDo;
	EndIf;
	
	Return CheckStructure;
	
EndFunction

&AtServerNoContext
Procedure SetImportanceFieldAccessibility(Form, CurrentCheckMetadata)
	Form.Items.IssueSeverity.Enabled = Not (CurrentCheckMetadata <> Undefined And CurrentCheckMetadata.ImportanceChangeDenied);
EndProcedure

&AtServerNoContext
Procedure SetPathToHandlerProcedure(Form, CurrentCheckMetadata)
	Form.HandlerProcedurePath = ?(CurrentCheckMetadata = Undefined, NStr("vi = 'Chưa xác định hàm sự kiện';
																		|ru = 'Не задан обработчик';
																		|en = 'Handler is not defined'; fa = 'Handler is not defined';
																		|it = 'Gestore non indicato';
																		|pl = 'Nie zadano procesora danych';
																		|tr = 'İşleyici belirtilmedi'"), CurrentCheckMetadata.HandlerChecks);
EndProcedure

&AtServer
Procedure ClearCheckResultsAtServer()
	
	RecordSet = InformationRegisters.AccountingCheckResults.CreateRecordSet();
	RecordSet.Filter.CheckRule.Set(Object.Ref);
	RecordSet.Write(True);
	
EndProcedure

&AtClient
Procedure SetStandardSettingsAtClient(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SetStandardSettingsAtServer();
	Modified = True;
	
EndProcedure

&AtServer
Procedure SetStandardSettingsAtServer()
	
	CurrentCheckMetadata = CheckMetadata(Object.Id);
	If CurrentCheckMetadata = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Việc kiểm tra tiến hành kế toán với tên ""%1"" không tồn tại.';
				|ru = 'Проверка ведения учета с идентификатором ""%1"" не существует.';
				|en = 'Data integrity check with ID %1 does not exist.'; fa = 'Data integrity check with ID %1 does not exist.';
				|it = 'La verifica di contabilità con ID ""%1"" non esiste.';
				|pl = 'Sprawdzenia prowadzenia ewidencji z identyfikatorem ""%1"" nie istnieje.';
				|tr = '""%1"" kimlikli muhasebe kontrolü mevcut değil.'"), Object.Id);
	EndIf;
		
	FillPropertyValues(Object, CurrentCheckMetadata, , "Id");
	Object.AccountingCheckIsChanged = False;
	
EndProcedure

&AtServer
Procedure SetScheduleSettingsAtServer()
	
	If ScheduleSelector = 0 Then
		
		If Object.RunMethod = Enums.CheckMethod.ByCommonSchedule Then
			
			ScheduleSelector = 1;
			
			Items.ScheduleSelector.Enabled                     = True;
			Items.IndividualSchedulePresentation.Enabled = False;
			Items.PresentationOfCommonSchedule.Enabled          = True;
			
		ElsIf Object.RunMethod = Enums.CheckMethod.OnSeparateSchedule Then
			
			ScheduleSelector = 2;
			
			Items.ScheduleSelector.Enabled                     = True;
			Items.IndividualSchedulePresentation.Enabled = True;
			Items.PresentationOfCommonSchedule.Enabled          = False;
			
		EndIf;
		
	ElsIf ScheduleSelector = 1 Then
		
		Object.RunMethod = Enums.CheckMethod.ByCommonSchedule;
		Items.ScheduleSelector.Enabled                     = True;
		Items.IndividualSchedulePresentation.Enabled = False;
		Items.PresentationOfCommonSchedule.Enabled          = True;
		
	ElsIf ScheduleSelector = 2 Then
		
		Object.RunMethod = Enums.CheckMethod.OnSeparateSchedule;
		Items.ScheduleSelector.Enabled                     = True;
		Items.IndividualSchedulePresentation.Enabled = True;
		Items.PresentationOfCommonSchedule.Enabled          = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure HideScheduleSettingsAtServer()
	
	Object.RunMethod = Enums.CheckMethod.Manually;
	Items.ScheduleSelector.Enabled                     = False;
	Items.IndividualSchedulePresentation.Enabled = False;
	Items.PresentationOfCommonSchedule.Enabled          = False;
	
EndProcedure

&AtServer
Procedure SetInitialScheduleSettings()
	
	If Object.RunMethod = Enums.CheckMethod.ByCommonSchedule Then
		
		RunsInBackgroundOnSchedule = True;
		ScheduleSelector           = 1;
		
		Items.ScheduleSelector.Enabled                     = True;
		Items.IndividualSchedulePresentation.Enabled = False;
		Items.PresentationOfCommonSchedule.Enabled          = True;
		
	ElsIf Object.RunMethod = Enums.CheckMethod.OnSeparateSchedule Then
		
		RunsInBackgroundOnSchedule = True;
		ScheduleSelector           = 2;
		
		Items.ScheduleSelector.Enabled                     = True;
		Items.IndividualSchedulePresentation.Enabled = True;
		Items.PresentationOfCommonSchedule.Enabled          = False;
		
	Else
		
		RunsInBackgroundOnSchedule = False;
		ScheduleSelector           = 1;
		
		Items.ScheduleSelector.Enabled                     = False;
		Items.IndividualSchedulePresentation.Enabled = False;
		Items.PresentationOfCommonSchedule.Enabled          = False
		
	EndIf;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
