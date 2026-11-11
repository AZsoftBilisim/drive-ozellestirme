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

	SetConditionalAppearance();
	
	If Not Users.IsFullUser(, True) Then
		Raise(NStr("vi = 'Không đủ quyền truy cập.';
					|ru = 'Недостаточно прав доступа.';
					|en = 'Insufficient access rights.'; fa = 'حقوق دسترسی ناکافی.';
					|it = 'Diritti di accesso insufficienti.';
					|pl = 'Niewystarczające uprawnienia dostępu.';
					|tr = 'Yetersiz erişim hakı.'"), ErrorCategory.AccessViolation);
	EndIf;
	
	FillFormSettings(New Map);
	
	BlankID = String(CommonClientServer.BlankUUID());
	TextUndefined = ScheduledJobsInternal.TextUndefined();
	IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
	
	If Common.DebugMode() Then
		Items.ScheduledJobsTableContextMenuExecuteNotInBackground.Visible = True;
		Items.ScheduledJobsTableExecuteNotInBackground.Visible = True;
	EndIf;
	
	OperationsWithExternalResourcesLocked = ScheduledJobsServer.OperationsWithExternalResourcesLocked();
	Items.ExternalResourcesOperationsLockGroup.Visible = OperationsWithExternalResourcesLocked;
	Items.ScheduledJobsTableLockOperationsWithExternalResources.Enabled = Not OperationsWithExternalResourcesLocked;
	
	If Common.IsMobileClient() Then
		
		Items.ScheduledJobsTableRefreshData.LocationInCommandBar = ButtonLocationInCommandBar.InAdditionalSubmenu;
		Items.ScheduledJobsTableSetUpSchedule.LocationInCommandBar = ButtonLocationInCommandBar.InAdditionalSubmenu;
		Items.HeaderGroup.ShowTitle = True;
		
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ImportScheduledJobs();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ScheduledJobs" Then
		
		If ValueIsFilled(Parameter) Then
			ImportScheduledJobs(Parameter, True);
		Else
			AttachIdleHandler("ScheduledJobsDeferredUpdate", 0.1, True);
		EndIf;
	ElsIf EventName = "OperationsWithExternalResourcesAllowed" Then
		Items.ExternalResourcesOperationsLockGroup.Visible = False;
		Items.ScheduledJobsTableLockOperationsWithExternalResources.Enabled = True;
		StandardSubsystemsClient.SetAdvancedApplicationCaption();
	ElsIf EventName = "OperationsWithExternalResourcesProhibited" Then
		Items.ExternalResourcesOperationsLockGroup.Visible = True;
		Items.ScheduledJobsTableLockOperationsWithExternalResources.Enabled = False;
		StandardSubsystemsClient.SetAdvancedApplicationCaption();
	ElsIf EventName = "Write_ConstantsSet" Then
		AttachIdleHandler("ScheduledJobsDeferredUpdate", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	FillFormSettings(Settings);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure JobsOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.BackgroundJobs And Not BackgroundJobsPageOpened Then
		BackgroundJobsPageOpened = True;
		UpdateBackgroundJobsTableAtClient();
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterKindByPeriodOnChange(Item)
	
	CurrentSessionDate = CurrentSessionDateAtServer();
	
	Items.FilterPeriodFrom.ReadOnly  = Not (FilterKindByPeriod = 4);
	Items.FilterPeriodFor.ReadOnly = Not (FilterKindByPeriod = 4);
	
	If FilterKindByPeriod = 0 Then
		FilterPeriodFrom  = '00010101';
		FilterPeriodFor = '00010101';
		Items.SettingArbitraryPeriod.Visible = False;
	ElsIf FilterKindByPeriod = 4 Then
		FilterPeriodFrom  = BegOfDay(CurrentSessionDate);
		FilterPeriodFor = FilterPeriodFrom;
		Items.SettingArbitraryPeriod.Visible = True;
	Else
		RefreshAutomaticPeriod(ThisObject, CurrentSessionDate);
		Items.SettingArbitraryPeriod.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterByScheduledJobOnChange(Item)

	Items.ScheduledJobForFilter.Enabled = FilterByScheduledJob;
	
EndProcedure

&AtClient
Procedure ScheduledJobForFilterClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	ScheduledJobForFilterID = BlankID;
	
EndProcedure

&AtClient
Procedure ExternalResourcesOperationsLockNoteURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	Items.ExternalResourcesOperationsLockGroup.Visible = False;
	LockOfOperationsWithExternalResourcesURLProcessingAtServerNote();
	Notify("OperationsWithExternalResourcesAllowed");
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBackgroundJobsTable

&AtClient
Procedure BackgroundJobsTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	OpenBackgroundJob();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersScheduledJobsTable

&AtClient
Procedure ScheduledJobsTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = "Predefined"
	 Or Field = "Use" Then
		
		AddCopyEditScheduledJob("Change");
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledJobsTableBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	AddCopyEditScheduledJob(?(Copy, "Copy", "Add"));
	
EndProcedure

&AtClient
Procedure ScheduledJobsTableBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	AddCopyEditScheduledJob("Change");
	
EndProcedure

&AtClient
Procedure ScheduledJobsTableBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	If Items.ScheduledJobsTable.SelectedRows.Count() > 1 Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn một nhiệm vụ thường kỳ';
								|ru = 'Выберите одно регламентное задание.';
								|en = 'Select one scheduled job.'; fa = 'Select one scheduled job.';
								|it = 'Selezionate un task di routine.';
								|pl = 'Wybierz jedno planowe zadanie.';
								|tr = 'Zamanlanmış bir görev seçin.'"));
		
	ElsIf Item.CurrentData.Predefined Then
		ShowMessageBox(, NStr("vi = 'Không thể xóa bỏ nhiệm vụ thường kỳ định trước.';
								|ru = 'Невозможно удалить предопределенное регламентное задание.';
								|en = 'Predefined scheduled job cannot be deleted.'; fa = 'Predefined scheduled job cannot be deleted.';
								|it = 'Non è possibile eliminare il task di routine predefinito.';
								|pl = 'Nie można usunąć zdefiniowanego planowego zadanie.';
								|tr = 'Ön tanımlı planlanmış görev silinemiyor.'") );
	Else
		ShowQueryBox(
			New CallbackDescription("ScheduledJobsTableBeforeDeleteRowCompletion", ThisObject),
			NStr("vi = 'Xóa nhiệm vụ thường kỳ?';
				|ru = 'Удалить регламентное задание?';
				|en = 'Do you want to delete the scheduled job?'; fa = 'Do you want to delete the scheduled job?';
				|it = 'Eliminare il task di routine?';
				|pl = 'Usunąć planowe zadanie?';
				|tr = 'Planlanmış iş silinsin mi?'"), QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateScheduledJobs(Command)
	
	If Items.Jobs.CurrentPage = Items.BackgroundJobs Then
		UpdateBackgroundJobsTableAtClient();
	Else
		ImportScheduledJobs();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteScheduledJobManually(Command)

	If Items.ScheduledJobsTable.CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn nhiệm vụ thường kỳ.';
								|ru = 'Выберите регламентное задание.';
								|en = 'Select a scheduled job.'; fa = 'Select a scheduled job.';
								|it = 'Selezionate un task di routine.';
								|pl = 'Wybierz planowe zadanie.';
								|tr = 'Planlanmış iş seçin.'"));
		Return;
	EndIf;
	
	SelectedRows = New Array;
	For Each SelectedRow In Items.ScheduledJobsTable.SelectedRows Do
		SelectedRows.Add(SelectedRow);
	EndDo;
	IndexOf = 0;
	
	SelectedJobsCount = SelectedRows.Count();
	ErrorMessageArray = New Array;
	
	For Each SelectedRow In SelectedRows Do
		CurrentData = ScheduledJobsTable.FindByID(SelectedRow);
		
		If CurrentData.Parameterized And SelectedJobsCount = 1 Then
			ShowMessageBox(, NStr("vi = 'Không thể thực hiện thủ công nhiệm vụ thường kỳ đã chọn.';
									|ru = 'Выбранное регламентное задание нельзя выполнить вручную.';
									|en = 'The scheduled job cannot be started manually.'; fa = 'The scheduled job cannot be started manually.';
									|it = 'Il task di routine selezionato non può essere eseguito manualmente.';
									|pl = 'Wybrane planowe zadanie nie można wykonać ręcznie.';
									|tr = 'Seçilen zamanlanmış görev manuel olarak yürütülemez.'"));
			Return;
		ElsIf CurrentData.Parameterized Then
			Continue;
		EndIf;
		
		ExecutionParameters = ExecuteScheduledJobManuallyAtServer(CurrentData.Id);
		If ExecutionParameters.Started1 Then
			
			ShowUserNotification(
				NStr("vi = 'Khởi động thủ tục nhiệm vụ hàng kỳ';
					|ru = 'Запущена процедура регламентного задания';
					|en = 'Scheduled job started'; fa = 'Scheduled job started';
					|it = 'È avviata la procedura del task di routine';
					|pl = 'Uruchomiona procedura planowego zadania';
					|tr = 'Zamanlanmış iş başlatıldı'"), ,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1.
					|Quy trình bắt đầu trong nhiệm vụ nền %2';
					|ru = '%1.
					|Процедура запущена в фоновом задании %2';
					|en = '%1.
					|The scheduled job has been started in the background job ""%2"".'; fa = '%1.
					|The scheduled job has been started in the background job ""%2"".';
					|it = '%1.
					|La procedura è avviata nel task in background %2';
					|pl = '%1.
					|Procedura uruchomiona w zadaniu w tle %2';
					|tr = '%1.
					|Prosedür, arka plan görevinde başlatıldı%2'"),
					CurrentData.Description,
					String(ExecutionParameters.StartedAt)),
				PictureLib.ExecuteScheduledJobManually);
			
			BackgroundJobIDsOnManualExecution.Add(
				ExecutionParameters.BackgroundJobIdentifier,
				CurrentData.Description);
			
			AttachIdleHandler(
				"NotifyAboutManualScheduledJobCompletion", 0.1, True);
		ElsIf ExecutionParameters.ProcedureAlreadyExecuting Then
			ErrorMessageArray.Add(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Thủ tục của nhiệm vụ thường kỳ ""%1""
					|  đang chạy trong nhiệm vụ nền ""%2"", đã bắt đầu %3.';
					|ru = 'Процедура регламентного задания ""%1""
					|  уже выполняется в фоновом задании ""%2"", начатом %3.';
					|en = 'The scheduled job ""%1"" is running in
					|the background job ""%2""  started on %3.'; fa = 'The scheduled job ""%1"" is running in
					|the background job ""%2""  started on %3.';
					|it = 'La procedura del task di routine ""%1""
					| è già in esecuzione nel processo in background ""%2"", avviato %3.';
					|pl = 'Procedura planowego zadania ""%1""
					| jest już wykonywane w zadaniu w tle ""%2"", rozpoczętym %3.';
					|tr = '""%1""
					|zamanlanmış görevin prosedürü %2 başlayan ""%3"" arkaplan görevinde zaten yürütülüyor.'"),
					CurrentData.Description,
					ExecutionParameters.BackgroundJobPresentation,
					String(ExecutionParameters.StartedAt)));
		Else
			Items.ScheduledJobsTable.SelectedRows.Delete(
				Items.ScheduledJobsTable.SelectedRows.Find(SelectedRow));
		EndIf;
		
		IndexOf = IndexOf + 1;
	EndDo;
	
	ErrorsCount = ErrorMessageArray.Count();
	If ErrorsCount > 0 Then
		ErrorTextTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Nhiệm vụ chưa thực hiện (%1 trong số %2)';
				|ru = 'Задания не выполнены (%1 из %2)';
				|en = 'The jobs are not completed (%1 out of %2)'; fa = 'The jobs are not completed (%1 out of %2)';
				|it = 'Задания не выполнены (%1 из %2)';
				|pl = 'The jobs are not completed (%1 out of %2)';
				|tr = 'Görev gerçekleştirilmedi (%2 üzerinden %1)'"),
			Format(ErrorsCount, "NG="),
			Format(SelectedRows.Count(), "NG="));
		
		AllErrorsText = New TextDocument;
		AllErrorsText.AddLine(ErrorTextTitle + ":");
		For Each ThisErrorText In ErrorMessageArray Do
			AllErrorsText.AddLine("");
			AllErrorsText.AddLine(ThisErrorText);
		EndDo;
		
		If ErrorsCount > 5 Then
			Buttons = New ValueList;
			Buttons.Add(1, NStr("vi = 'Hiển thị lỗi';
								|ru = 'Показать ошибки';
								|en = 'Show errors'; fa = 'Show errors';
								|it = 'Visualizzare errori';
								|pl = 'Pokaż błędy';
								|tr = 'Hataları göster'"));
			Buttons.Add(DialogReturnCode.Cancel);
			
			ShowQueryBox(
				New CallbackDescription(
					"ExecuteScheduledJobManuallyCompletion", ThisObject, AllErrorsText),
				ErrorTextTitle, Buttons);
		Else
			ShowMessageBox(, TrimAll(AllErrorsText.GetText()));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetUpSchedule(Command)
	
	CurrentData = Items.ScheduledJobsTable.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn nhiệm vụ thường kỳ.';
								|ru = 'Выберите регламентное задание.';
								|en = 'Select a scheduled job.'; fa = 'Select a scheduled job.';
								|it = 'Selezionate un task di routine.';
								|pl = 'Wybierz planowe zadanie.';
								|tr = 'Planlanmış iş seçin.'"));
	
	ElsIf Items.ScheduledJobsTable.SelectedRows.Count() > 1 Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn một nhiệm vụ thường kỳ';
								|ru = 'Выберите одно регламентное задание.';
								|en = 'Select one scheduled job.'; fa = 'Select one scheduled job.';
								|it = 'Selezionate un task di routine.';
								|pl = 'Wybierz jedno planowe zadanie.';
								|tr = 'Zamanlanmış bir görev seçin.'"));
	Else
		Dialog = New ScheduledJobDialog(
			GetSchedule(CurrentData.Id));
		
		Dialog.Show(New CallbackDescription(
			"OpenScheduleEnd", ThisObject, CurrentData));
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableScheduledJob(Command)
	
	SetScheduledJobUsage(True);
	
EndProcedure

&AtClient
Procedure DisableScheduledJob(Command)
	
	SetScheduledJobUsage(False);
	
EndProcedure

&AtClient
Procedure OpenBackgroundJobAtClient(Command)
	
	OpenBackgroundJob();
	
EndProcedure

&AtClient
Procedure CancelBackgroundJob(Command)
	
	If Items.BackgroundJobsTable.CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn nhiệm vụ nền.';
								|ru = 'Выберите фоновое задание.';
								|en = 'Select a background job.'; fa = 'Select a background job.';
								|it = 'Selezionate un task in background.';
								|pl = 'Wybierz zadanie w tle.';
								|tr = 'Arka plan işi seçin.'"));
		Return;
	EndIf;

	CancelBackgroundJobAtServer(Items.BackgroundJobsTable.CurrentData.Id);
	ImportScheduledJobs(, True);
	
	ShowMessageBox(,
		NStr("vi = 'Công việc đã bị hủy nhưng trạng thái hủy sẽ được máy chủ đặt chỉ sau một thời gian, 
		           |có thể cần cập nhật dữ liệu theo cách thủ công.';
		           |ru = 'Задание отменено, но состояние отмены будет установлено сервером только через некоторое время,
		           |возможно потребуется обновить данные вручную.';
		           |en = 'You have canceled the background job, but the server will stop it with a delay.,
		           |You might need to update data on the client manually.'; fa = 'You have canceled the background job, but the server will stop it with a delay.,
		           |You might need to update data on the client manually.';
		           |it = 'Il task è stato annullato, ma lo stato di annullamento verrà impostato dal server solo tra un po'' di tempo,
		           |potrebbe essere necessario aggiornare i dati manualmente.';
		           |pl = 'Zadanie zostanie anulowane, ale stan anulowania zostanie ustawiony przez serwer dopiero po pewnym czasie, 
		           |może być konieczne ręczne zaktualizowanie danych.';
		           |tr = 'İş iptal edildi, ancak iptal durumu sunucu tarafından bir süre sonra ayarlanmayacak, 
		           |verileri manuel olarak yenilemeniz gerekebilir.'"));
	
EndProcedure

&AtClient
Procedure ShowAllJobs(Command)
	Value = Items.ScheduledJobsTableShowAllJobs.Check;
	Items.ScheduledJobsTableShowAllJobs.Check = Not Value;
	
	SetDisabledJobsVisibility(Not Value);
EndProcedure

&AtClient
Procedure ExecuteNotInBackground(Command)
	
	If Items.ScheduledJobsTable.CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn nhiệm vụ thường kỳ.';
								|ru = 'Выберите регламентное задание.';
								|en = 'Select a scheduled job.'; fa = 'Select a scheduled job.';
								|it = 'Selezionate un task di routine.';
								|pl = 'Wybierz planowe zadanie.';
								|tr = 'Planlanmış iş seçin.'"));
		Return;
	EndIf;
	
	SelectedRows = New Array;
	For Each SelectedRow In Items.ScheduledJobsTable.SelectedRows Do
		SelectedRows.Add(SelectedRow);
	EndDo;
	IndexOf = 0;
	SelectedJobsCount = SelectedRows.Count();
	
	For Each SelectedRow In SelectedRows Do
		CurrentData = ScheduledJobsTable.FindByID(SelectedRow);
		
		If CurrentData.Parameterized And SelectedJobsCount = 1 Then
			ShowMessageBox(, NStr("vi = 'Không thể thực hiện thủ công nhiệm vụ thường kỳ đã chọn.';
									|ru = 'Выбранное регламентное задание нельзя выполнить вручную.';
									|en = 'The scheduled job cannot be started manually.'; fa = 'The scheduled job cannot be started manually.';
									|it = 'Выбранное регламентное задание нельзя выполнить вручную.';
									|pl = 'Wybrane planowe zadanie nie można wykonać ręcznie.';
									|tr = 'Seçilen zamanlanmış görev manuel olarak yürütülemez.'"));
			Return;
		ElsIf CurrentData.Parameterized Then
			Continue;
		EndIf;
		
		RunScheduledJobNotInBackground(CurrentData.Id);
		IndexOf = IndexOf + 1;
	EndDo;
	
	ShowUserNotification(
		NStr("vi = 'Đã thực hiện thủ tục nhiệm vụ hàng kỳ';
			|ru = 'Выполнена процедура регламентного задания';
			|en = 'Scheduled job completed'; fa = 'Scheduled job completed';
			|it = 'È completata la procedura del task di routine';
			|pl = 'Została wykonana procedura planowego zadania';
			|tr = 'Zamanlanmış iş prosedürü gerçekleştirildi'"), ,
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1.
			|Thủ tục được thực hiện thủ công mà không có nhiệm vụ nền';
			|ru = '%1.
			|Процедура выполнена вручную без фонового задания';
			|en = '%1.
			|The scheduled job has been completed manually.'; fa = '%1.
			|The scheduled job has been completed manually.';
			|it = '%1.
			|La procedura è stata eseguita manualmente senza un task in background';
			|pl = '%1.
			|Procedura została wykonana ręcznie, bez zadania w tle';
			|tr = '%1.
			|Prosedür manuel olarak, arkaplan görevi olmadan yürütüldü'"),
			CurrentData.Description),
		PictureLib.ExecuteScheduledJobManually);
	
EndProcedure

&AtServer
Procedure RunScheduledJobNotInBackground(JobID)
	
	ScheduledJobsInternal.RaiseIfNoAdministrationRights();
	SetPrivilegedMode(True);
	
	Job = ScheduledJobsServer.GetScheduledJob(JobID);
	JobMetadata = Job.Metadata;
	MethodName = JobMetadata.MethodName;
	JobName = JobMetadata.Name;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.BeforeRunScheduledJobNotInBackground(Job);
	EndIf;
	
	ExecutionParameters = ScheduledJobsServer.NewTaskCompletionParameters();
	ExecutionParameters.InBackground = False;
	
	Common.SystemSettingsStorageSave("ScheduledJobs", MethodName, True);
	ScheduledJobsServer.CompleteTheJob(Job, ExecutionParameters);
	Common.SystemSettingsStorageSave("ScheduledJobs", MethodName, Undefined);
	
EndProcedure

&AtClient
Procedure EventLogEvents(Command)
	
	EventFilter = New Structure;
	If Items.Jobs.CurrentPage = Items.ScheduledJobs Then
		CurrentData = Items.ScheduledJobsTable.CurrentData;
		If CurrentData = Undefined Then
			ShowMessageBox(, NStr("vi = 'Hãy chọn nhiệm vụ thường kỳ.';
									|ru = 'Выберите регламентное задание.';
									|en = 'Select a scheduled job.'; fa = 'Select a scheduled job.';
									|it = 'Selezionate un task di routine.';
									|pl = 'Wybierz planowe zadanie.';
									|tr = 'Planlanmış iş seçin.'"));
			Return;
		EndIf;
		If Not ValueIsFilled(CurrentData.StartDate) And Not ValueIsFilled(CurrentData.EndDate)
			Or (CurrentData.StartDate = TextUndefined And CurrentData.EndDate = TextUndefined) Then
			ShowMessageBox(, NStr("vi = 'Không có sự kiện để xem, vì nhiệm vụ theo lịch trình đã không được thực hiện.';
									|ru = 'Нет событий для просмотра, так как регламентное задание не выполнялось.';
									|en = 'The scheduled job has not run yet. There are no related records in the event log.'; fa = 'The scheduled job has not run yet. There are no related records in the event log.';
									|it = 'Nessun evento da visualizzare, in quanto il task pianificato non è stato eseguito.';
									|pl = 'Brak zdarzeń do wyświetlenia, ponieważ rutynowe zadanie nie zostało wykonane.';
									|tr = 'Zamanlanmış görev çalışmadığı için görüntülenecek olay yok.'"));
			Return;
		EndIf;
		EventFilter.Insert("StartDate", CurrentData.StartDate);
		If CurrentData.EndDate <> EmptyDatePresentation() Then
			EventFilter.Insert("EndDate", CurrentData.EndDate);
		EndIf;
		AddSelectionBySession(EventFilter, CurrentData.Id);
	ElsIf Items.Jobs.CurrentPage = Items.BackgroundJobs Then
		CurrentData = Items.BackgroundJobsTable.CurrentData;
		If CurrentData = Undefined Then
			ShowMessageBox(, NStr("vi = 'Hãy chọn nhiệm vụ nền.';
									|ru = 'Выберите фоновое задание.';
									|en = 'Select a background job.'; fa = 'Select a background job.';
									|it = 'Selezionate un task in background.';
									|pl = 'Wybierz zadanie w tle.';
									|tr = 'Arka plan işi seçin.'"));
			Return;
		EndIf;
		EventFilter.Insert("StartDate", CurrentData.Begin);
		EventFilter.Insert("EndDate", CurrentData.End);
		AddSelectionBySession(EventFilter, CurrentData.ScheduledJobID);
	EndIf;
	
	EventLogClient.OpenEventLog(EventFilter, ThisObject);
	
EndProcedure

&AtClient
Procedure LockOperationsWithExternalResources(Command)
	
	OnCloseNotifyHandler = New CallbackDescription("LockOperationsWithExternalResourcesCompletion", ThisObject);
	MessageText = NStr("vi = 'Sẽ phong tỏa công việc với tất cả các nguồn ngoài (đồng bộ dữ liệu, gửi email...) theo lịch biểu.
	|
	|Nguyên nhân có thể để phong tỏa:
	|• Đánh dấu lỗi của cơ sở thông tin như cơ sở đã được chuyển
	|• Cần phong tỏa tạm thời nhiệm vụ thường kỳ';
	|ru = 'Работа со всеми внешними ресурсами (синхронизация данных, отправка почты и т.п.), выполняемая по расписанию, будет заблокирована.
	|
	|Возможные причины для блокировки:
	|• Ошибочная отметка базы, как перемещенной
	|• Необходимость временной блокировки регламентных заданий';
	|en = 'All scheduled operations involving external resources (such as data synchronization and sending email) will be blocked.
	|
	|Possible reasons for blocking:
	|• The infobase is mistakenly marked as moved.
	|• Scheduled jobs need to be temporary disabled.'; fa = 'All scheduled operations involving external resources (such as data synchronization and sending email) will be blocked.
	|
	|Possible reasons for blocking:
	|• The infobase is mistakenly marked as moved.
	|• Scheduled jobs need to be temporary disabled.';
	|it = 'All scheduled operations involving external resources (such as data synchronization and sending email) will be blocked.
	|
	|Possible reasons for blocking:
	|• The infobase is mistakenly marked as moved.
	|• Scheduled jobs need to be temporary disabled.';
	|pl = 'All scheduled operations involving external resources (such as data synchronization and sending email) will be blocked.
	|
	|Possible reasons for blocking:
	|• The infobase is mistakenly marked as moved.
	|• Scheduled jobs need to be temporary disabled.';
	|tr = 'Programa göre gerçekleştirilen tüm harici kaynaklarla çalışma (veri senkronizasyonu, e-posta gönderme vb.) engellenecektir.
	|
	|Engelleme için olası nedenler:
	|• Bazın taşınmış olarak hatalı işaretlenmesi 
	|• Zamanlanmış görevlerin geçici olarak engellenmesi gerekliliği'");
	ButtonsList = New ValueList();
	ButtonsList.Add(DialogReturnCode.Yes, "Lock");
	ButtonsList.Add(DialogReturnCode.No, "Cancel");
	ShowQueryBox(OnCloseNotifyHandler, 
		MessageText, 
		ButtonsList, , 
		DialogReturnCode.No, NStr("vi = 'Phong tỏa công việc với nguồn ngoài';
									|ru = 'Блокировка работы с внешними ресурсами';
									|en = 'Lock operations with external resources'; fa = 'قفل عملیات با منابع خارجی';
									|it = 'Blocco delle risorse esterne';
									|pl = 'Blokowanie pracy z zasobami zewnętrznymi';
									|tr = 'Çalışmaları dış kaynaklarla kilitleme'"));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.End.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BackgroundJobsTable.End");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", EmptyDatePresentation());
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExecutionState.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledJobsTable.ExecutionState");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("vi = '<không xác định>';
								|ru = '<не определено>';
								|en = '<undefined>'; fa = '<نامشخص>';
								|it = '<non definito>';
								|pl = '<nie określono>';
								|tr = '<belirlenmedi>'");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EndDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledJobsTable.EndDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("vi = '<không xác định>';
								|ru = '<не определено>';
								|en = '<undefined>'; fa = '<نامشخص>';
								|it = '<non definito>';
								|pl = '<nie określono>';
								|tr = '<belirlenmedi>'");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StartDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledJobsTable.StartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("vi = '<không xác định>';
								|ru = '<не определено>';
								|en = '<undefined>'; fa = '<نامشخص>';
								|it = '<non definito>';
								|pl = '<nie określono>';
								|tr = '<belirlenmedi>'");
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Use.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Description.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExecutionState.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.EndDate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StartDate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UserName.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Predefined.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ScheduledJobsTable.JobName");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = DisabledJobs;
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtServer
Procedure SetDisabledJobsVisibility(Show)
	
	Item = ConditionalAppearance.Items.Get(4);
	AppearanceItem = Item.Appearance.Items.Find("Visible");
	
	If Not Show Then
		Item.Filter.Items.Clear();
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField("ScheduledJobsTable.JobName");
		ItemFilter.ComparisonType   = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = DisabledJobs;
		
		AppearanceItem.Use = True;
	Else
		Item.Filter.Items.Clear();
		AppearanceItem.Use = False;
	EndIf;
	
	ParenthesisPosition = StrFind(Items.ScheduledJobs.Title, " (");
	If ParenthesisPosition > 0 Then
		Items.ScheduledJobs.Title = Left(Items.ScheduledJobs.Title, ParenthesisPosition - 1);
	EndIf;
	ItemsOnList = ScheduledJobsTable.Count();
	If ItemsOnList > 0 Then
		If Not Show Then
			ItemsOnList = ItemsOnList - DisabledJobs.Count();
		EndIf;
		Items.ScheduledJobs.Title = Items.ScheduledJobs.Title + " (" + Format(ItemsOnList, "NG=") + ")";
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledJobsTableBeforeDeleteRowCompletion(Response, Context) Export
	
	If Response = DialogReturnCode.Yes Then
		DeleteScheduledJobExecuteAtServer(
			Items.ScheduledJobsTable.CurrentData.Id);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteScheduledJobManuallyCompletion(Response, AllErrorsText) Export
	
	If Response = 1 Then
		AllErrorsText.Show();
	EndIf;
	
EndProcedure

// Parameters:
//  NewSchedule - JobSchedule
//  CurrentData   - FormDataCollectionItem:
//     * Id - String
//
&AtClient
Procedure OpenScheduleEnd(NewSchedule, CurrentData) Export

	If NewSchedule <> Undefined Then
		SetSchedule(CurrentData.Id, NewSchedule);
		ImportScheduledJobs(CurrentData.Id, True);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetSchedule(Val ScheduledJobID)
	
	SetPrivilegedMode(True);
	
	Return ScheduledJobsServer.JobSchedule(
		ScheduledJobID);
	
EndFunction

&AtServerNoContext
Procedure SetSchedule(Val ScheduledJobID, Val Schedule)
	
	SetPrivilegedMode(True);
	
	ScheduledJobsServer.SetJobSchedule(
		ScheduledJobID,
		Schedule);
	
EndProcedure

&AtServer
Procedure FillFormSettings(Val Settings)
	
	DefaultSettings = New Structure;
	
	If Settings.Get("FilterByActiveState") = Undefined Then
		Settings.Insert("FilterByActiveState", True);
	EndIf;
	
	If Settings.Get("FilterByCompletedState") = Undefined Then
		Settings.Insert("FilterByCompletedState", False);
	EndIf;
	
	If Settings.Get("FilterByFailedState") = Undefined Then
		Settings.Insert("FilterByFailedState", False);
	EndIf;

	If Settings.Get("FilterByStateCanceled") = Undefined Then
		Settings.Insert("FilterByStateCanceled", False);
	EndIf;
	
	If Settings.Get("FilterByScheduledJob") = Undefined
	 Or Settings.Get("ScheduledJobForFilterID") = Undefined Then
		Settings.Insert("FilterByScheduledJob", False);
		Settings.Insert("ScheduledJobForFilterID", BlankID);
	EndIf;
	
	// See also the FilterKindByPeriodOnChange radio button event handler.
	If Settings.Get("FilterKindByPeriod") = Undefined Then
		
		Settings.Insert("FilterKindByPeriod", 3); // Today
		CurrentSessionDate = CurrentSessionDate();
	EndIf;
	
	For Each Setting In Settings Do
		DefaultSettings.Insert(Setting.Key, Setting.Value);
	EndDo;
	
	FillPropertyValues(ThisObject, DefaultSettings);
	
	Items.SettingArbitraryPeriod.Visible = (FilterKindByPeriod = 4);
	Items.FilterPeriodFrom.ReadOnly  = Not (FilterKindByPeriod = 4);
	Items.FilterPeriodFor.ReadOnly = Not (FilterKindByPeriod = 4);
	Items.ScheduledJobForFilter.Enabled = FilterByScheduledJob;
	
	RefreshAutomaticPeriod(ThisObject, CurrentSessionDate());
	
EndProcedure

&AtClient
Procedure OpenBackgroundJob()
	
	If Items.BackgroundJobsTable.CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn nhiệm vụ nền.';
								|ru = 'Выберите фоновое задание.';
								|en = 'Select a background job.'; fa = 'Select a background job.';
								|it = 'Selezionate un task in background.';
								|pl = 'Wybierz zadanie w tle.';
								|tr = 'Arka plan işi seçin.'"));
		Return;
	EndIf;
	
	PassedPropertyList =
	"Id,
	|Key,
	|Description,
	|MethodName,
	|State,
	|Begin,
	|End,
	|Placement,
	|MessagesToUserAndErrorDescription,
	|ScheduledJobID,
	|ScheduledJobDescription";
	CurrentDataValues = New Structure(PassedPropertyList);
	FillPropertyValues(CurrentDataValues, Items.BackgroundJobsTable.CurrentData);
	
	FormParameters = New Structure;
	FormParameters.Insert("Id", Items.BackgroundJobsTable.CurrentData.Id);
	FormParameters.Insert("BackgroundJobProperties", CurrentDataValues);
	
	OpenForm("DataProcessor.ScheduledAndBackgroundJobs.Form.BackgroundJob", FormParameters, ThisObject);
	
EndProcedure

&AtServerNoContext
Function CurrentSessionDateAtServer()
	
	Return CurrentSessionDate();
	
EndFunction

&AtServer
Function ScheduledJobsFinishedNotification()
	
	CompletionNotifications = New Array;
	
	If BackgroundJobIDsOnManualExecution.Count() > 0 Then
		IndexOf = BackgroundJobIDsOnManualExecution.Count() - 1;
		
		SetPrivilegedMode(True);
		While IndexOf >= 0 Do
			
			NewUUID = New UUID(
				BackgroundJobIDsOnManualExecution[IndexOf].Value);
			Filter = New Structure;
			Filter.Insert("UUID", NewUUID);
			
			BackgroundJobArray = BackgroundJobs.GetBackgroundJobs(Filter);
			
			If BackgroundJobArray.Count() = 1 Then
				FinishedAt = BackgroundJobArray[0].End;
				
				If ValueIsFilled(FinishedAt) Then
					
					CompletionNotifications.Add(
						New Structure(
							"ScheduledJobPresentation,
							|FinishedAt",
							BackgroundJobIDsOnManualExecution[IndexOf].Presentation,
							FinishedAt));
					
					BackgroundJobIDsOnManualExecution.Delete(IndexOf);
				EndIf;
			Else
				BackgroundJobIDsOnManualExecution.Delete(IndexOf);
			EndIf;
			IndexOf = IndexOf - 1;
		EndDo;
		SetPrivilegedMode(False);
	EndIf;
	
	Return CompletionNotifications;
	
EndFunction

&AtClient
Procedure NotifyAboutManualScheduledJobCompletion()
	
	CompletionNotifications = ScheduledJobsFinishedNotification();
	
	For Each Notification In CompletionNotifications Do
		
		ShowUserNotification(
			NStr("vi = 'Đã thực hiện thủ tục nhiệm vụ hàng kỳ';
				|ru = 'Выполнена процедура регламентного задания';
				|en = 'Scheduled job procedure completed'; fa = 'Scheduled job procedure completed';
				|it = 'È completata la procedura del task di routine';
				|pl = 'Została wykonana procedura planowego zadania';
				|tr = 'Zamanlanmış görev prosedürü gerçekleştirildi'"),
			,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1.
				           |Thủ tục kết thúc trong nhiệm vụ nền %2';
				           |ru = '%1.
				           |Процедура завершена в фоновом задании %2';
				           |en = '%1.
				           |The scheduled job has been completed in the background job ""%2"".'; fa = '%1.
				           |The scheduled job has been completed in the background job ""%2"".';
				           |it = '%1.
				           |La procedura è terminata nel task in background %2';
				           |pl = '%1.
				           |Procedura została zakończona w zadaniu w tle %2';
				           |tr = '%1. 
				           |Prosedür arka plan işinde tamamlandı%2'"),
				Notification.ScheduledJobPresentation,
				String(Notification.FinishedAt)),
			PictureLib.ExecuteScheduledJobManually);
	EndDo;
	
	If BackgroundJobIDsOnManualExecution.Count() > 0 Then
		
		AttachIdleHandler(
			"NotifyAboutManualScheduledJobCompletion", 2, True);
	Else
		ImportScheduledJobs(, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateScheduledJobChoiceList()
	
	Table = ScheduledJobsTable;
	List  = Items.ScheduledJobForFilter.ChoiceList;
	
	// Add a predefined item.
	If List.Count() = 0 Then
		List.Add(BlankID, TextUndefined);
	EndIf;
	
	IndexOf = 1;
	For Each Job In Table Do
		If IndexOf >= List.Count()
		 Or List[IndexOf].Value <> Job.Id Then
			// Insert a new job.
			List.Insert(IndexOf, Job.Id, Job.Description);
		Else
			List[IndexOf].Presentation = Job.Description;
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
	// Delete excessive rows.
	While IndexOf < List.Count() Do
		List.Delete(IndexOf);
	EndDo;
	
	ListItem = List.FindByValue(ScheduledJobForFilterID);
	If ListItem = Undefined Then
		ScheduledJobForFilterID = BlankID;
	EndIf;
	
EndProcedure

&AtServer
Function ExecuteScheduledJobManuallyAtServer(Val ScheduledJobID)
	
	Result = ScheduledJobsInternal.ExecuteScheduledJobManually(ScheduledJobID);
	Return Result;
	
EndFunction

&AtServer
Procedure CancelBackgroundJobAtServer(Val Id)
	
	ScheduledJobsInternal.CancelBackgroundJob(Id);
	UpdateBackgroundJobTable();
	
EndProcedure

&AtServer
Procedure DeleteScheduledJobExecuteAtServer(Val Id)
	
	String = ScheduledJobsTable.FindRows(New Structure("Id", Id))[0];
	ScheduledJobsServer.DeleteScheduledJob(Id);
	ScheduledJobsTable.Delete(ScheduledJobsTable.IndexOf(String));
	
EndProcedure

&AtClient
Procedure AddCopyEditScheduledJob(Val Action)
	
	FormParameters = New Structure;
	FormParameters.Insert("Action", Action);
	
	If Action <> "Add" Then
		If Items.ScheduledJobsTable.CurrentData = Undefined Then
			ShowMessageBox(, NStr("vi = 'Hãy chọn nhiệm vụ thường kỳ.';
									|ru = 'Выберите регламентное задание.';
									|en = 'Select a scheduled job.'; fa = 'Select a scheduled job.';
									|it = 'Selezionate un task di routine.';
									|pl = 'Wybierz planowe zadanie.';
									|tr = 'Planlanmış iş seçin.'"));
			Return;
		Else
			FormParameters.Insert("Id", Items.ScheduledJobsTable.CurrentData.Id);
		EndIf;
	EndIf;
	
	OpenForm("DataProcessor.ScheduledAndBackgroundJobs.Form.ScheduledJob", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ScheduledJobsDeferredUpdate()
	
	ImportScheduledJobs(, True);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RefreshAutomaticPeriod(Form, CurrentSessionDate)
	
	If Form.FilterKindByPeriod = 1 Then
		Form.FilterPeriodFrom  = BegOfDay(CurrentSessionDate) - 3*3600;
		Form.FilterPeriodFor = BegOfDay(CurrentSessionDate) + 9*3600;
		
	ElsIf Form.FilterKindByPeriod = 2 Then
		Form.FilterPeriodFrom  = BegOfDay(CurrentSessionDate) - 24*3600;
		Form.FilterPeriodFor = EndOfDay(Form.FilterPeriodFrom);
		
	ElsIf Form.FilterKindByPeriod = 3 Then
		Form.FilterPeriodFrom  = BegOfDay(CurrentSessionDate);
		Form.FilterPeriodFor = EndOfDay(Form.FilterPeriodFrom);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetScheduledJobUsage(isEnabled)
	
	For Each SelectedRow In Items.ScheduledJobsTable.SelectedRows Do
		CurrentData = ScheduledJobsTable.FindByID(SelectedRow);
		ScheduledJobsServer.ChangeScheduledJob(CurrentData.Id,
			New Structure("Use", isEnabled));
		CurrentData.Use = isEnabled;
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure LockOfOperationsWithExternalResourcesURLProcessingAtServerNote()
	ScheduledJobsServer.UnlockOperationsWithExternalResources();
EndProcedure

&AtClient
Procedure LockOperationsWithExternalResourcesCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		LockOperationsWithExternalResourcesAtServer();
		Notify("OperationsWithExternalResourcesProhibited");
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure LockOperationsWithExternalResourcesAtServer()
	ScheduledJobsServer.LockOperationsWithExternalResources();
EndProcedure

#Region BackgroundLoadingOfScheduledJobs

&AtClient
Procedure ImportScheduledJobs(JobID = Undefined, UpdateSilently = False)
	
	If Not UpdateSilently Then
		Items.ScheduledJobsDeferredImportPages.CurrentPage = Items.ScheduledJobsImportPage;
	EndIf;
	If Items.ScheduledJobsTable.CurrentData <> Undefined Then
		CurrentRowID = Items.ScheduledJobsTable.CurrentData.Id;
	EndIf;
	Result = ImportScheduledJobsServer(JobID);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	CallbackOnCompletion = New CallbackDescription("ImportScheduledJobsCompletion", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure ImportScheduledJobsCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		ProcessResult(Result);
		Items.ScheduledJobsDeferredImportPages.CurrentPage = Items.ScheduledJobsPage;
	ElsIf Result.Status = "Error" Then
		Items.ScheduledJobsDeferredImportPages.CurrentPage = Items.ScheduledJobsPage;
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
	EndIf;
	
EndProcedure

&AtServer
Function ImportScheduledJobsServer(JobID)
	
	If ExecutionResult <> Undefined
		And ValueIsFilled(ExecutionResult.JobID) Then
		TimeConsumingOperations.CancelJobExecution(ExecutionResult.JobID);
	EndIf;
	
	TimeConsumingOperationParameters = TimeConsumingOperationParameters();
	TimeConsumingOperationParameters.Insert("ScheduledJobID", JobID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	If JobID <> Undefined Then
		ExecutionParameters.RunNotInBackground1 = True;
	EndIf;
	ExecutionParameters.WaitCompletion = 0; // Run immediately
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập bảng nhiệm vụ thường kỳ';
														|ru = 'Формирование таблицы регламентных заданий';
														|en = 'Generate scheduled job list'; fa = 'Generate scheduled job list';
														|it = 'Generazione della tabella dei task di routine';
														|pl = 'Tworzenie tabeli planowych zadań';
														|tr = 'Zamanlanmış görev tablosunun oluşturulması'");
	
	Return TimeConsumingOperations.ExecuteInBackground("ScheduledJobsInternal.GenerateScheduledJobsTable",
		TimeConsumingOperationParameters, ExecutionParameters);
	
EndFunction

&AtServer
Function TimeConsumingOperationParameters()
	
	OperationParametersList = New Structure;
	OperationParametersList.Insert("Table", FormAttributeToValue("ScheduledJobsTable"));
	OperationParametersList.Insert("DisabledJobs", DisabledJobs.Copy());
	
	Return OperationParametersList;
	
EndFunction

&AtServer
Procedure ProcessResult(JobParameters)
	
	Result = GetFromTempStorage(JobParameters.ResultAddress);
	DeleteFromTempStorage(JobParameters.ResultAddress);
	
	DisabledJobs.Clear();
	For Each ListItem In Result.DisabledJobs Do
		DisabledJobs.Add(ListItem.Value);
	EndDo;
	
	SetDisabledJobsVisibility(Items.ScheduledJobsTableShowAllJobs.Check);
	
	ValueToFormAttribute(Result.Table, "ScheduledJobsTable");
	
	Items.ScheduledJobsTable.Refresh();
	
	// Positioning of the scheduled jobs list.
	If ValueIsFilled(CurrentRowID) Then
		SearchResult = ScheduledJobsTable.FindRows(New Structure("Id", CurrentRowID));
		If SearchResult.Count() = 1 Then
			String = SearchResult[0];
			Items.ScheduledJobsTable.CurrentRow = String.GetID();
		EndIf;
	EndIf;
	
	ParenthesisPosition = StrFind(Items.ScheduledJobs.Title, " (");
	If ParenthesisPosition > 0 Then
		Items.ScheduledJobs.Title = Left(Items.ScheduledJobs.Title, ParenthesisPosition - 1);
	EndIf;
	ItemsOnList = ScheduledJobsTable.Count();
	If ItemsOnList > 0 Then
		If Not Items.ScheduledJobsTableShowAllJobs.Check Then
			ItemsOnList = ItemsOnList - DisabledJobs.Count();
		EndIf;
		Items.ScheduledJobs.Title = Items.ScheduledJobs.Title + " (" + Format(ItemsOnList, "NG=") + ")";
	EndIf;
	
	UpdateScheduledJobChoiceList();
	
EndProcedure

&AtClientAtServerNoContext
Function EmptyDatePresentation()
	Return "<>";
EndFunction

#EndRegion

#Region BackgroundLoadingOfBackgroundJobs

&AtClient
Procedure UpdateBackgroundJobsTableAtClient()
	
	Result = GenerateBackgroundJobsTableInBackground();
	If Result.Status = "Completed2" Or Result.Status = "Error" Then
		Return;
	EndIf;
	
	Items.HeaderGroup.Enabled = False;
	Items.BackgroundJobsDeferredImportPages.CurrentPage = Items.TimeConsumingOperationPage;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	CallbackOnCompletion = New CallbackDescription("UpdateBackgroundJobTableCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtServer
Function GenerateBackgroundJobsTableInBackground()
	
	Filter = BackgroundJobsFilter();
	TransmittedParameters = New Structure;
	TransmittedParameters.Insert("Filter", Filter);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Nhiệm vụ thường kỳ. Cập nhật danh sách nhiệm vụ nền';
														|ru = 'Регламентные задания. Обновление списка фоновых заданий';
														|en = 'Scheduled jobs. Update background job list'; fa = 'Scheduled jobs. Update background job list';
														|it = 'Task di routine.Aggiornamento dell''elenco dei task in background';
														|pl = 'Planowe zadania. Aktualizacja listy zadań wykonywanych w tle';
														|tr = 'Zamanlanmış görevler. Arkaplan görev listesinin güncellenmesi.'");
	
	Result = TimeConsumingOperations.ExecuteInBackground("ScheduledJobsInternal.FillBackgroundJobsPropertiesTableInBackground",
		TransmittedParameters, ExecutionParameters);
		
	If Result.Status = "Completed2" Then
		UpdateBackgroundJobTable(Result.ResultAddress);
	ElsIf Result.Status = "Error" Then
		Raise Result.ErrorInfo;
	EndIf;
	
	Return Result;
		
EndFunction

&AtServer
Function BackgroundJobsFilter()
	
	Filter = New Structure;
	StateArray = New Array;
	
	If FilterByActiveState Then 
		StateArray.Add(BackgroundJobState.Active);
	EndIf;
	
	If FilterByCompletedState Then 
		StateArray.Add(BackgroundJobState.Completed);
	EndIf;
	
	If FilterByFailedState Then 
		StateArray.Add(BackgroundJobState.Failed);
	EndIf;
	
	If FilterByStateCanceled Then 
		StateArray.Add(BackgroundJobState.Canceled);
	EndIf;
	
	If StateArray.Count() <> 4 Then
		Filter.Insert("State", ?(StateArray.Count() = 1, StateArray[0], StateArray));
	EndIf;
	
	If FilterByScheduledJob Then
		Filter.Insert("ScheduledJobID",
			?(ScheduledJobForFilterID = BlankID,
			"",
			ScheduledJobForFilterID));
	EndIf;
	
	If FilterKindByPeriod <> 0 Then
		RefreshAutomaticPeriod(ThisObject, CurrentSessionDate());
		Filter.Insert("Begin", FilterPeriodFrom);
		Filter.Insert("End",  FilterPeriodFor);
	EndIf;
	
	Return Filter;
	
EndFunction

&AtServer
Procedure UpdateBackgroundJobTable(ResultAddress = Undefined)
	
	If ResultAddress <> Undefined Then
		DataFromStorage = GetFromTempStorage(ResultAddress);
		CurrentTable = DataFromStorage.PropertiesTable;
	Else
		Filter = BackgroundJobsFilter();
		CurrentTable = ScheduledJobsInternal.BackgroundJobsProperties(Filter);
	EndIf;
	
	Table = BackgroundJobsTable;
	IndexOf = 0;
	For Each Job In CurrentTable Do
		
		If IndexOf >= Table.Count()
		 Or Table.Get(IndexOf).Id <> Job.Id Then
			ToUpdate = Table.Insert(IndexOf);
			ToUpdate.Id = Job.Id;
		Else
			ToUpdate = Table[IndexOf];
		EndIf;
		
		FillPropertyValues(ToUpdate, Job);
		
		// Setting the scheduled job description from the ScheduledJobTable collection.
		If ValueIsFilled(ToUpdate.ScheduledJobID) Then
			
			Rows = ScheduledJobsTable.FindRows(
				New Structure("Id", ToUpdate.ScheduledJobID));
			
			ToUpdate.ScheduledJobDescription
				= ?(Rows.Count() = 0, NStr("vi = '<không tìm thấy>';
											|ru = '<не найдено>';
											|en = '<not found>'; fa = '<یافت نشد>';
											|it = '<non trovato>';
											|pl = '<nie znaleziono>';
											|tr = '<bulunamadı>'"), Rows[0].Description);
		Else
			ToUpdate.ScheduledJobDescription  = TextUndefined;
			ToUpdate.ScheduledJobID = TextUndefined;
		EndIf;
		
		ToUpdate.MessagesToUserAndErrorDescription 
			= ScheduledJobsInternal.BackgroundJobMessagesAndErrorDescriptions(
				ToUpdate.Id, Job);
		
		IndexOf = IndexOf + 1;
	EndDo;
	
	While IndexOf < Table.Count() Do
		Table.Delete(Table.Count()-1);
	EndDo;
	
	Items.BackgroundJobsTable.Refresh();
	
	ParenthesisPosition = StrFind(Items.BackgroundJobs.Title, " (");
	If ParenthesisPosition > 0 Then
		Items.BackgroundJobs.Title = Left(Items.BackgroundJobs.Title, ParenthesisPosition - 1);
	EndIf;
	ItemsOnList = BackgroundJobsTable.Count();
	If ItemsOnList > 0 Then
		Items.BackgroundJobs.Title = Items.BackgroundJobs.Title + " (" + Format(ItemsOnList, "NG=") + ")";
	EndIf;
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure UpdateBackgroundJobTableCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		UpdateBackgroundJobTable(Result.ResultAddress);
		Items.HeaderGroup.Enabled = True;
		Items.BackgroundJobsDeferredImportPages.CurrentPage = Items.BackgroundJobsPage;
	ElsIf Result.Status = "Error" Then
		Items.HeaderGroup.Enabled = True;
		Items.BackgroundJobsDeferredImportPages.CurrentPage = Items.BackgroundJobsPage;
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure AddSelectionBySession(Filter, Id)
	
	If Id = ScheduledJobsInternal.TextUndefined() Then
		Return;
	EndIf;
	
	FilterJobs = New Structure;
	FilterJobs.Insert("UUID", New UUID(Id));
	FoundJobs = ScheduledJobsServer.FindJobs(FilterJobs);
	ScheduledJob = Undefined;
	For Each FoundJob In FoundJobs Do
		ScheduledJob = FoundJob;
		Break;
	EndDo;
	
	If ScheduledJob = Undefined Then
		Return;
	EndIf;
	
	FilterCopy = Common.CopyRecursive(Filter); // Structure
	FilterCopy.Insert("Metadata", ScheduledJob.Metadata.FullName());
	
	Result = New ValueTable;
	UnloadEventLog(Result, FilterCopy, , , 1);
	For Each String In Result Do
		Sessions = New ValueList;
		Sessions.Add(String.Session);
		Filter.Insert("Session", Sessions);
	EndDo;
	
EndProcedure

#EndRegion

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
