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
	
	SubsystemSettings = InfobaseUpdateInternal.SubsystemSettings();
	ToolTipText      = SubsystemSettings.UpdateResultNotes;
	
	If Not IsBlankString(ToolTipText) Then
		Items.WhereToFindThisFormHint.Title = ToolTipText;
	EndIf;
	
	If Not Users.IsFullUser(, True) Then
		
		Items.MinimalUserActivityPeriodHintGroup.Visible = False;
		Items.WhereToFindThisFormHint.Title = 
			NStr("vi = 'Cũng có thể kiểm soát quá trình xử lý dữ liệu của phiên bản ứng dụng từ phân hệ
		               |""Thông tin"" trên bàn làm việc, lệnh ""Mô tả thay đổi ứng dụng"".';
		               |ru = 'Ход обработки данных версии приложения можно также проконтролировать из раздела
		               |""Информация"" на рабочем столе, команда ""Описание изменений приложения"".';
		               |en = 'To view the progress of processing app data,
		               |go to Quick menu > Information > Release notes.'; fa = 'To view the progress of processing app data,
		               |go to Quick menu > Information > Release notes.';
		               |it = 'Ход обработки данных версии приложения можно также проконтролировать из раздела
		               |""Информация"" на рабочем столе, команда ""Описание изменений приложения"".';
		               |pl = 'To view the progress of processing app data,
		               |go to Quick menu > Information > Release notes.';
		               |tr = 'Uygulama sürümleri veri işleminin ilerlemesi, masaüstündeki 
		               |""Bilgi"" bölümünden de ""Uygulama değişikliklerinin açıklaması"" komutundan kontrol edilebilir.'");
		
	EndIf;
	
	// Read constant values.
	GetInfobaseUpdateThreadsCount();
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	UpdatePriority = ?(UpdateInfo.DeferredUpdateManagement.Property("ForceUpdate"), "DataProcessing", "UserWork");
	UpdateEndTime = UpdateInfo.UpdateEndTime;
	
	DeferredUpdateStartTime = UpdateInfo.DeferredUpdateStartTime;
	DeferredUpdatesEndTime = UpdateInfo.DeferredUpdatesEndTime;
	
	FileIB = Common.FileInfobase();
	
	If ValueIsFilled(UpdateEndTime) Then
		Items.UpdateCompletedInformation.Title = StringFunctionsClientServer.SubstituteParametersToString(
			Items.UpdateCompletedInformation.Title,
			Metadata.Version,
			Format(UpdateEndTime, "DLF=D"),
			Format(UpdateEndTime, "DLF=T"),
			UpdateInfo.UpdateDuration);
	Else
		UpdateCompletedTitle = NStr("vi = 'Đã cập nhật thành công ứng dụng sang phiên bản %1';
									|ru = 'Версия приложения успешно обновлена на версию %1';
									|en = 'The application is updated to version %1.'; fa = 'The application is updated to version %1.';
									|it = 'Версия приложения успешно обновлена на версию %1';
									|pl = 'The application is updated to version %1.';
									|tr = 'Uygulama %1 sürümüne güncellendi'");
		Items.UpdateCompletedInformation.Title = StringFunctionsClientServer.SubstituteParametersToString(UpdateCompletedTitle, Metadata.Version);
	EndIf;
	
	If UpdateInfo.DeferredUpdatesEndTime = Undefined Then
		
		If Not Users.IsFullUser(, True) Then
			Items.UpdateStatus.CurrentPage = Items.UpdateStatusForUser;
		Else
			
			If Not FileIB And UpdateInfo.DeferredUpdateCompletedSuccessfully = Undefined Then
				Items.UpdateStatus.CurrentPage = Items.UpdateInProgress;
				CheckPerformDeferredUpdate(UpdateInfo);
			Else
				Items.UpdateStatus.CurrentPage = Items.FileInfobaseUpdate;
			EndIf;
			
		EndIf;
		
	Else
		MessageText = UpdateResultMessage();
		Items.UpdateStatus.CurrentPage = Items.UpdateCompleted;
		
		TitleTemplate1 = NStr("vi = 'Đã kết thúc thủ tục bổ sung xử lý dữ liệu %1 sang %2';
								|ru = 'Дополнительные процедуры обработки данных завершены %1 в %2';
								|en = 'Additional data processing procedures were completed on %1 at %2.'; fa = 'Additional data processing procedures were completed on %1 at %2.';
								|it = 'Le procedure aggiuntive di elaborazione dei dati sono completate %1 in %2';
								|pl = 'Dodatkowe procedury przetwarzania danych zakończono %1 w %2';
								|tr = 'Ek veri işlemci prosedürleri %1 %2 tamamlandı'");
		Items.DeferredUpdateCompletedInformation.Title = 
		StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, 
			Format(UpdateInfo.DeferredUpdatesEndTime, "DLF=D"),
			Format(UpdateInfo.DeferredUpdatesEndTime, "DLF=T"));
		
	EndIf;
	
	SetVisibilityForInfobaseUpdateThreadsCount();
	
	If Not FileIB Then
		UpdateCompleted = False;
		ShowUpdateStatus(UpdateCompleted);
		SetAvailabilityForInfobaseUpdateThreadsCount(ThisObject);
		
		If UpdateCompleted Then
			RefreshUpdateCompletedPage(UpdateInfo);
			Items.UpdateStatus.CurrentPage = Items.UpdateCompleted;
		EndIf;
		
	Else
		UpdateInformationOnIssues();
		Items.UpdateStatusInformation.Visible = False;
		Items.ModifySchedule.Visible         = False;
	EndIf;
	
	If Users.IsFullUser(, True) Then
		
		If Common.DataSeparationEnabled() Then
			Items.ScheduleSetupGroup.Visible = False;
		Else
			FilterOfTasks = New Structure;
			FilterOfTasks.Insert("Metadata", Metadata.ScheduledJobs.DeferredIBUpdate);
			Jobs = ScheduledJobsServer.FindJobs(FilterOfTasks);
			For Each Job In Jobs Do
				Schedule = Job.Schedule;
				Break;
			EndDo;
		EndIf;
		
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Items.MainUpdateHyperlink.Visible = False;
		Items.PriorityGroup.Visible               = False;
	EndIf;
	
	ProcessUpdateResultAtServer();
	
	HideExtraGroupsInForm(Parameters.OpenedFromAdministrationPanel, UpdateInfo);
	
	Items.OpenDeferredHandlersList.Title = MessageText;
	Items.InformationTitle.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đang thực hiện thủ tục xử lý dữ liệu bổ sung lên phiên bản %1
			|Tạm thời hạn chế làm việc với dữ liệu này.';
			|ru = 'Выполняются дополнительные процедуры обработки данных на версию %1
			|Работа с этими данными временно ограничена.';
			|en = 'Additional data processing procedures required for upgrade to version %1 are in progress.
			|Operations with this data are temporarily restricted.'; fa = 'Additional data processing procedures required for upgrade to version %1 are in progress.
			|Operations with this data are temporarily restricted.';
			|it = 'Ulteriori procedure di elaborazione dei dati per la versione %1 
			|sono in corso. L''uso di questi dati è temporaneamente limitato';
			|pl = 'Są wykonywane dodatkowe procedury przetwarzania danych na wersję %1
			|Praca z tymi danymi jest czasowo ograniczona';
			|tr = 'Sürüm için ek veri işleme prosedürleri gerçekleştiriliyor%1
			|Bu verilerle çalışmak geçici olarak sınırlıdır.'"), Metadata.Version);
	
	Items.FormRelaunchDeferredUpdate.Visible = Not Common.IsSubordinateDIBNode()
		And ThereHandlersWithParallelExecutionMode()
		And Users.IsFullUser();
	
	TroubleHintWithData = NStr("vi = 'Các vấn đề với dữ liệu có thể cản trở việc xử lý dữ liệu khi chuyển sang phiên bản mới.
		|Nếu đã thực hiện thủ tục xử lý dữ liệu bổ sung bị lỗi thì cần:
		|  • chuyển đến danh sách vấn đề và sửa lỗi theo khuyến nghị trong báo cáo;
		|  • tiếp tục thực hiện các thủ tục xử lý dữ liệu bổ sung, theo đó cần chuyển đến hyperlink <b>Không phải tất cả thủ tục đều được thực hiện ...</b> và nhấn nút <b>Khởi động</b> phía dưới biểu mẫu.';
		|ru = 'Проблемы с данными могут мешать их обработке при переходе на новую версию.
		|Если выполнение дополнительных процедур обработки данных завершилось с ошибкой, то необходимо:
		|  • перейти к списку проблем и исправить их согласно рекомендации в отчете;
		|  • продолжить выполнение дополнительных процедур обработки данных, для чего необходимо перейти по гиперссылке <b>Не все процедуры удалось выполнить ...</b> и нажать на кнопку <b>Запустить</b> внизу формы.';
		|en = 'When the application is updating, data issues might prevent the processing.
		|If additional data processing procedures fail, do the following:
		| • Open the issue list and follow the recommendations.
		| • Follow the link <b>Some of the update procedures are not completed</b> and click <b>Run</b> to resume additional data processing procedures.'; fa = 'When the application is updating, data issues might prevent the processing.
		|If additional data processing procedures fail, do the following:
		| • Open the issue list and follow the recommendations.
		| • Follow the link <b>Some of the update procedures are not completed</b> and click <b>Run</b> to resume additional data processing procedures.';
		|it = 'Проблемы с данными могут мешать их обработке при переходе на новую версию.
		|Если выполнение дополнительных процедур обработки данных завершилось с ошибкой, то необходимо:
		|  • перейти к списку проблем и исправить их согласно рекомендации в отчете;
		|  • продолжить выполнение дополнительных процедур обработки данных, для чего необходимо перейти по гиперссылке <b>Не все процедуры удалось выполнить ...</b> и нажать на кнопку <b>Запустить</b> внизу формы.';
		|pl = 'When the application is updating, data issues might prevent the processing.
		|If additional data processing procedures fail, do the following:
		| • Open the issue list and follow the recommendations.
		| • Follow the link <b>Some of the update procedures are not completed</b> and click <b>Run</b> to resume additional data processing procedures.';
		|tr = 'Veri sorunları, yeni bir sürüme yükseltme sırasında bunların işlenmesine müdahale edebilir. 
		|Ek veri işleme prosedürlerinin yürütülmesi bir hatayla sonuçlandıysa, şunları yapmanız gerekir: 
		| sorun listesine gitmeli ve bunları rapordaki önerilere göre düzeltmelisiniz; 
		|köprüyü izlemeniz gereken ek veri işleme prosedürlerini<b> gerçekleştirmeye devam edin Tüm prosedürler tamamlanamadı ...</b>ve formun altındaki<b> Çalıştır düğmesini tıklayın</b>.'");
	TroubleHintWithData = StringFunctions.FormattedString(TroubleHintWithData);
	Items.Problemswithdata.ExtendedTooltip.Title = TroubleHintWithData;
	Items.IssuesDataCompleted.ExtendedTooltip.Title = TroubleHintWithData;
	
	SeparatedDataUsageAvailable = Common.SeparatedDataUsageAvailable(); 
	Items.UpdateStatus.Visible = SeparatedDataUsageAvailable;
	Items.FormRelaunchDeferredUpdate.Visible = SeparatedDataUsageAvailable;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.IBVersionUpdateSaaS") Then
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule("InfobaseUpdateInternalSaaS");
		AreasUpdateProgressReport = ModuleInfobaseUpdateInternalSaaS.AreasUpdateProgressReport();
		
		Items.HyperlinkAreasUpdateProgress.Visible = Not SeparatedDataUsageAvailable;
	Else
		Items.HyperlinkAreasUpdateProgress.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
#If MobileClient Then
	CommandBarLocation = FormCommandBarLabelLocation.None;
#EndIf
	
	If Not FileIB Then
		AttachIdleHandler("CheckHandlersExecutionStatus", 15);
	EndIf;
	
	ProcessUpdateResultAtClient();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "DeferredUpdate" Then
		
		If Not FileIB Then
			Items.UpdateStatus.CurrentPage = Items.UpdateInProgress;
		EndIf;
		
		UpdateCompletedSuccessful = False;
		AttachIdleHandler("RunDeferredUpdate", 0.5, True);
	ElsIf EventName = "DeferredUpdateRestarted" Then
		If FileIB Then
			Items.UpdateStatus.CurrentPage = Items.FileInfobaseUpdate;
		Else
			Items.UpdateStatus.CurrentPage = Items.UpdateInProgress;
		EndIf;
		UpdateCompletedSuccessful = False;
		CheckHandlersExecutionStatus();
		AttachIdleHandler("CheckHandlersExecutionStatus", 15);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateStatusInformationClick(Item)
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.DeferredHandlers");
EndProcedure

&AtClient
Procedure MainUpdateHyperlinkClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("StartDate", DeferredUpdateStartTime);
	If DeferredUpdatesEndTime <> Undefined Then
		FormParameters.Insert("EndDate", DeferredUpdatesEndTime);
	EndIf;
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

&AtClient
Procedure UpdateErrorInformationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	
	ApplicationsList = New Array;
	ApplicationsList.Add("COMConnection");
	ApplicationsList.Add("Designer");
	ApplicationsList.Add("1CV8");
	ApplicationsList.Add("1CV8C");
	
	FormParameters.Insert("User", UserName());
	FormParameters.Insert("ApplicationName", ApplicationsList);
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

&AtClient
Procedure UpdatePriorityOnChange(Item)
	
	SetUpdatePriority();
	SetAvailabilityForInfobaseUpdateThreadsCount(ThisObject);
	
EndProcedure

&AtClient
Procedure InfobaseUpdateThreadCountOnChange(Item)
	
	SetInfobaseUpdateThreadsCount();
	
EndProcedure

&AtClient
Procedure PatchesInstalledInformationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	ShowInstalledPatches();
EndProcedure

&AtClient
Procedure ExplanationUpdateNotRunningURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	If FormattedStringURL = "CheckLock" Then
		If CommonClient.SubsystemExists("StandardSubsystems.UsersSessions") Then
			ModuleIBConnectionsClient = CommonClient.CommonModule("IBConnectionsClient");
			ModuleIBConnectionsClient.OnOpenUserActivityLockForm();
		EndIf;
	ElsIf FormattedStringURL = "Enable" Then
		EnableScheduledJob();
		MessageText = NStr("vi = 'Đã bật sử dụng nhiệm vụ. Sẽ sớm cập nhật trạng thái.';
							|ru = 'Задание включено. Статус обновления скоро обновится.';
							|en = 'Duty is enabled. The status will refresh soon.'; fa = 'Duty is enabled. The status will refresh soon.';
							|it = 'Compito attivato. Lo stato di aggiornamento sarà aggiornato a breve.';
							|pl = 'Zadanie zostało włączone. Status aktualizacji wkrótce zostanie zaktualizowany.';
							|tr = 'İş etkin. Güncelleme durumu yakında güncellenecektir.'");
		ShowMessageBox(, MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure HyperlinkAreasUpdateProgressClick(Item)
	OpenForm(AreasUpdateProgressReport);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RunUpdate(Command)
	
	If Not FileIB Then
		Items.UpdateStatus.CurrentPage = Items.UpdateInProgress;
	EndIf;
	
	AttachIdleHandler("RunDeferredUpdate", 0.5, True);
	
EndProcedure

&AtClient
Procedure OpenDeferredHandlersList(Command)
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.DeferredHandlers");
EndProcedure

&AtClient
Procedure ModifySchedule(Command)
	
	Dialog = New ScheduledJobDialog(Schedule);
	
	CallbackDescription = New CallbackDescription("ChangeScheduleAfterSetUpSchedule", ThisObject);
	Dialog.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure InformationForTechnicalSupport(Command)
	
	If Not IsBlankString(ScriptDirectory) Then
		CallbackDescription = New CallbackDescription("BeginFindingFilesCompletion", ThisObject);
		BeginFindingFiles(CallbackDescription, ScriptDirectory, "log*.txt");
	EndIf;
	
EndProcedure

&AtClient
Procedure BeginFindingFilesCompletion(FilesArray, AdditionalParameters) Export
	If FilesArray.Count() > 0 Then
		LogFile = FilesArray[0];
		FileSystemClient.OpenFile(LogFile.FullName);
	Else
		// If there is no log, open temporary directory of the update script.
		FileSystemClient.OpenExplorer(ScriptDirectory);
	EndIf;
EndProcedure

&AtClient
Procedure ProblemSituationsClick(Item)
	Levels = New Array;
	Levels.Add("Error");
	Levels.Add("Warning");
	
	LogFilter = New Structure;
	LogFilter.Insert("StartDate", DeferredUpdateStartTime);
	LogFilter.Insert("Level", Levels);
	LogFilter.Insert("EventLogEvent", NStr("vi = 'Cập nhật cơ sở thông tin';
											|ru = 'Обновление информационной базы';
											|en = 'Infobase update'; fa = 'به‌روزرسانی پایگاه اطلاعات';
											|it = 'Aggiornamento del database';
											|pl = 'Aktualizacja bazy informacyjnej';
											|tr = 'Infobase güncellemesi'", CommonClient.DefaultLanguageCode()));
	EventLogClient.OpenEventLog(LogFilter, ThisObject);
EndProcedure

&AtClient
Procedure RelaunchDeferredUpdate(Command)
	OpenForm("InformationRegister.UpdateHandlers.Form.RestartDeferredUpdate");
EndProcedure

&AtClient
Procedure ProblemswithdataClick(Item)
	If CommonClient.SubsystemExists("StandardSubsystems.AccountingAudit") Then
		ModuleAccountingAuditClient = CommonClient.CommonModule("AccountingAuditClient");
		ModuleAccountingAuditClient.OpenIssuesReport("IBVersionUpdate", False);
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure HideExtraGroupsInForm(OpenedFromAdministrationPanel, InformationRecords)
	
	IsFullUser = Users.IsFullUser(, True);
	
	If Not IsFullUser Or OpenedFromAdministrationPanel Then
		WindowOptionsKey = "FormForOrdinaryUser";
		
		Items.WhereToFindThisFormHint.Visible = False;
		Items.MainUpdateHyperlink.Visible = AccessRight("View", Metadata.DataProcessors.EventLog);
		
	Else
		WindowOptionsKey = "FormForAdministrator";
	EndIf;
	
	If IsFullUser
		And ValueIsFilled(InformationRecords.VersionPatchesDeletion)
		And Metadata.Version = InformationRecords.VersionPatchesDeletion Then
		Items.PatchesDeletionInformationGroup.Visible = True;
		WindowOptionsKey = "PatchesDeletionWarning";
	Else
		Items.PatchesDeletionInformationGroup.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetUpdatePriority()
	
	BeginTransaction();
	Try
		Block = New DataLock;
		Block.Add("Constant.IBUpdateInfo");
		Block.Lock();
		
		UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
		If UpdatePriority = "DataProcessing" Then
			UpdateInfo.DeferredUpdateManagement.Insert("ForceUpdate");
		Else
			UpdateInfo.DeferredUpdateManagement.Delete("ForceUpdate");
		EndIf;
		
		InfobaseUpdateInternal.WriteInfobaseUpdateInfo(UpdateInfo);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServer
Procedure SetInfobaseUpdateThreadsCount()
	
	Constants.InfobaseUpdateThreadCount.Set(InfobaseUpdateThreadCount);
	
EndProcedure

&AtClient
Procedure RunDeferredUpdate()
	
	ExecuteUpdateAtServer();
	If Not FileIB Then
		CheckHandlersExecutionStatus();
		AttachIdleHandler("CheckHandlersExecutionStatus", 15);
		Return;
	EndIf;
	
	Items.UpdateStatus.CurrentPage = Items.UpdateCompleted;
	
EndProcedure

&AtClient
Procedure CheckHandlersExecutionStatus()
	
	UpdateCompleted = False;
	CheckHandlersExecutionStatusAtServer(UpdateCompleted);
	If UpdateCompleted Then
		Items.UpdateStatus.CurrentPage = Items.UpdateCompleted;
		DetachIdleHandler("CheckHandlersExecutionStatus")
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckHandlersExecutionStatusAtServer(UpdateCompleted)
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	If UpdateInfo.DeferredUpdatesEndTime <> Undefined Then
		UpdateCompleted = True;
	Else
		ShowUpdateStatus(UpdateCompleted);
	EndIf;
	
	If UpdateCompleted = True Then
		RefreshUpdateCompletedPage(UpdateInfo);
		UpdateInformationOnIssues();
	Else
		CheckPerformDeferredUpdate(UpdateInfo);
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteUpdateAtServer()
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	
	UpdateInfo.DeferredUpdateCompletedSuccessfully = Undefined;
	UpdateInfo.DeferredUpdatesEndTime = Undefined;
	
	ResetHandlersStatus(Enums.UpdateHandlersStatuses.Error);
	ResetHandlersStatus(Enums.UpdateHandlersStatuses.Running);
	
	InfobaseUpdateInternal.WriteInfobaseUpdateInfo(UpdateInfo);
	
	Constants.DeferredUpdateCompletedSuccessfully.Set(False);
	
	If Not FileIB Then
		EnableScheduledJob();
		Return;
	EndIf;
	
	InfobaseUpdateInternal.ExecuteDeferredUpdateNow(Undefined);
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	RefreshUpdateCompletedPage(UpdateInfo);
	
EndProcedure

&AtServer
Procedure ResetHandlersStatus(Status)
	
	// ACC:1327-off - There's no concurrent access to the register.
	// ACC:1328-off - There's no concurrent access to the register.
	Query = New Query;
	Query.SetParameter("Status", Status);
	Query.Text =
		"SELECT
		|	UpdateHandlers.HandlerName AS HandlerName
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.Status = &Status";
	Handlers = Query.Execute().Unload();
	For Each Handler In Handlers Do
		RecordSet = InformationRegisters.UpdateHandlers.CreateRecordSet();
		RecordSet.Filter.HandlerName.Set(Handler.HandlerName);
		RecordSet.Read();
		
		Record = RecordSet[0];
		Record.AttemptCount = 0;
		Record.Status = Enums.UpdateHandlersStatuses.WasNotExecuted;
		ExecutionStatistics = Record.ExecutionStatistics.Get();
		ExecutionStatistics.Insert("StartsCount", 0);
		Record.ExecutionStatistics = New ValueStorage(ExecutionStatistics, New Deflation(9));
		
		RecordSet.Write();
	EndDo;
	// ACC:1327-on
	// ACC:1328-on
	
EndProcedure

&AtServer
Procedure RefreshUpdateCompletedPage(UpdateInfo)
	
	TitleTemplate1 = NStr("vi = 'Đã kết thúc thủ tục xử lý dữ liệu bổ sung %1 trong %2';
							|ru = 'Дополнительные процедуры обработки данных завершены %1 в %2';
							|en = 'Additional data processing procedures were completed on %1 at %2.'; fa = 'Additional data processing procedures were completed on %1 at %2.';
							|it = 'Le procedure aggiuntive di elaborazione dei dati sono completate %1 in %2';
							|pl = 'Dodatkowe procedury przetwarzania danych zakończono %1 w %2';
							|tr = 'Ek veri işlemci prosedürleri %1 %2 tamamlandı'");
	MessageText = UpdateResultMessage();
	
	Items.DeferredUpdateCompletedInformation.Title = 
		StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, 
			Format(UpdateInfo.DeferredUpdatesEndTime, "DLF=D"),
			Format(UpdateInfo.DeferredUpdatesEndTime, "DLF=T"));
	
	Items.OpenDeferredHandlersList.Title = MessageText;
	
	DeferredUpdatesEndTime = UpdateInfo.DeferredUpdatesEndTime;
	
EndProcedure

&AtServer
Function UpdateResultMessage()
	
	Progress = HandlersExecutionProgress();
	
	If Progress.TotalHandlerCount = Progress.CompletedHandlersCount Then
		
		If Progress.TotalHandlerCount = 0 Then
			Items.NoDeferredHandlersInformation.Visible = True;
			Items.DeferredUpdateCompletedInformation.Visible    = False;
			Items.SwitchToDeferredHandlersListGroup.Visible = False;
			MessageText = "";
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã thực hiện thành công tất cả thủ tục cập nhật (%1)';
																						|ru = 'Все процедуры обновления выполнены успешно (%1)';
																						|en = 'All update procedures are completed (%1).'; fa = 'All update procedures are completed (%1).';
																						|it = 'Tutte le procedure di aggiornamento sono state completate correttamente (%1)';
																						|pl = 'Wszystkie procedury aktualizacji wykonano pomyślnie (%1)';
																						|tr = 'Tüm güncelleme prosedürleri başarıyla tamamlandı (%1)'"), Progress.CompletedHandlersCount);
		EndIf;
		Items.CompletedPicture.Picture = PictureLib.Success32;
		UpdateCompletedSuccessful = True;
	Else
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không phải tất cả thủ tục đều được thực hiện (đã thực hiện %1 trong số %2)';
																					|ru = 'Не все процедуры удалось выполнить (выполнено %1 из %2)';
																					|en = 'Some of the update procedures are not completed (%1 out of %2 completed)'; fa = 'Some of the update procedures are not completed (%1 out of %2 completed)';
																					|it = 'Non tutte le procedure sono state eseguite (completate %1 da %2)';
																					|pl = 'Nie wszystkie procedury udało się wykonać (wykonano %1 z %2)';
																					|tr = 'Bazı prosedürler gerçekleşmedi ( %1, %2 dışında gerçekleşti)'"), 
			Progress.CompletedHandlersCount, Progress.TotalHandlerCount);
		Items.CompletedPicture.Picture = PictureLib.DialogStop;
	EndIf;
	Return MessageText;
	
EndFunction

&AtServer
Procedure ShowUpdateStatus(UpdateCompleted = False)
	
	Progress = HandlersExecutionProgress();
	
	If Progress.TotalHandlerCount = Progress.CompletedHandlersCount Then
		UpdateCompleted = True;
	EndIf;
	
	Items.UpdateStatusInformation.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã thực hiện: %1 trong số %2';
			|ru = 'Выполнено: %1 из %2';
			|en = 'Completed: %1 out of %2.'; fa = 'تکمیل‌شده: %1 از %2.';
			|it = 'Completati: %1 da %2';
			|pl = 'Wykonano: %1 z %2';
			|tr = 'Tamamlanan: %1 / %2.'"),
		Progress.CompletedHandlersCount,
		Progress.TotalHandlerCount);
	
	UpdateInformationOnIssues();
	
EndProcedure

&AtServer
Procedure UpdateInformationOnIssues()
	
	// Display information about the handler issue.
	NumberofProblemsInHandlers = ProblemSituationsInUpdateHandlers();
	If NumberofProblemsInHandlers <> 0 And Not UpdateCompletedSuccessful Then
		TextIndicator = NStr("vi = 'Vấn đề với người phát triển';
							|ru = 'Проблемы с обработчиками';
							|en = 'Handler issues found'; fa = 'Handler issues found';
							|it = 'Problemi con gli elaboratori';
							|pl = 'Problemy z procesorami danych';
							|tr = 'İşleyicilerle ilgili sorunlar'");
	Else
		TextIndicator = NStr("vi = 'Không tìm thấy vấn đề với người phát triển';
							|ru = 'Проблем с обработчиками не обнаружено';
							|en = 'No handler issues found'; fa = 'No handler issues found';
							|it = 'Problemi con gli elaboratori non rilevati';
							|pl = 'Nie wykryto problemów z procesorami danych';
							|tr = 'İşleyicilerle ilgili sorun bulunamadı'");
	EndIf;
	
	Items.ProblemSituations.Title = TextIndicator; // On the update progress page.
	Items.ProblemSituationsCompleted.Title = TextIndicator; // On the completed handler page.
	
	// Display information about the data issue.
	ShouldShowDataIssues = InfobaseUpdateInternal.ShouldShowDataIssues();
	If ShouldShowDataIssues Then
		NumberofProblemswithData = InfobaseUpdateInternal.NumberofProblemswithData();
	Else
		NumberofProblemswithData = 0; 
		Items.GroupIndicationofProblemswithData.Visible = False;
		Items.GroupIndicationofProblemswithDataCompleted.Visible = False;
	EndIf;
	If NumberofProblemswithData <> 0 Then
		TextIndicator = NStr("vi = 'Vấn đề với dữ liệu (%1)';
							|ru = 'Проблемы с данными (%1)';
							|en = 'Data issues (%1)'; fa = 'Data issues (%1)';
							|it = 'Problemi con i dati (%1)';
							|pl = 'Problemy z danymi (%1)';
							|tr = 'Veri sorunları (%1)'");
		TextIndicator = StringFunctionsClientServer.SubstituteParametersToString(TextIndicator, NumberofProblemswithData);
	Else
		TextIndicator = NStr("vi = 'Không tìm thấy vấn đề với dữ liệu';
							|ru = 'Проблем с данными не обнаружено';
							|en = 'No data issues found'; fa = 'No data issues found';
							|it = 'Problemi con i dati non rilevati';
							|pl = 'Nie wykryto problemów z danymi';
							|tr = 'Veri sorunları bulunamadı'");
	EndIf;
	
	Items.Problemswithdata.Title = TextIndicator; // On the update progress page.
	Items.IssuesDataCompleted.Title = TextIndicator; // On the completed handler page.
	
	// Appearance of data issue elements.
	HyperlinkProblemsWithHandlers = False;
	HyperlinkProblemsWithData       = False;
	ImageProblemsWithHandlers = PictureLib.AppearanceCheckIcon;
	ImageProblemsWithData       = PictureLib.AppearanceCheckIcon;
	
	If NumberofProblemsInHandlers <> 0 And NumberofProblemswithData <> 0 Then
		If Not UpdateCompletedSuccessful Then
			ImageProblemsWithHandlers = Items.PictureTemplate.Picture;
			HyperlinkProblemsWithHandlers = True;
		EndIf;
		ImageProblemsWithData       = Items.PictureTemplate.Picture;
		HyperlinkProblemsWithData       = True;
		
	ElsIf NumberofProblemsInHandlers <> 0 And Not UpdateCompletedSuccessful And NumberofProblemswithData = 0 Then
		ImageProblemsWithHandlers = Items.PictureTemplate.Picture;
		HyperlinkProblemsWithHandlers = True;
		
	ElsIf NumberofProblemsInHandlers = 0 And NumberofProblemswithData <> 0 Then
		ImageProblemsWithData    = Items.PictureTemplate.Picture;
		HyperlinkProblemsWithData = True;
		
	EndIf;
	
	Items.Problemswithdata.Hyperlink   = HyperlinkProblemsWithData;
	Items.ProblemSituations.Hyperlink = HyperlinkProblemsWithHandlers;
	Items.IssuesDataCompleted.Hyperlink   = HyperlinkProblemsWithData;
	Items.ProblemSituationsCompleted.Hyperlink = HyperlinkProblemsWithHandlers;
	
	Items.DecorationIndicationProblems.Picture         = ImageProblemsWithHandlers;
	Items.DecorationIndicationProblemsWithData.Picture = ImageProblemsWithData;
	Items.DecorationIndicationProblemsCompleted.Picture         = ImageProblemsWithHandlers;
	Items.DecorationIndicationDataProblemsCompleted.Picture = ImageProblemsWithData;
	
	// Display warning about the data processor loop.
	WarnLooping = False;
	If UpdatePriority = "DataProcessing"
		And JobActive
		And CompletedAllSequentialHandlers() Then
		UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
		UpdateSessionStartDate = UpdateInfo.UpdateSessionStartDate;
		If UpdateSessionStartDate <> Undefined
			And CurrentSessionDate() - UpdateSessionStartDate > 5400
			And Not HaveProgressIntervalsDataProcessing() Then
			WarnLooping = True;
		EndIf;
	EndIf;
	
	Items.DecorationWarningLooping.Visible = WarnLooping;
EndProcedure

&AtServer
Function HandlersExecutionProgress()
	
	Query = New Query;
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.SetParameter("Status", Enums.UpdateHandlersStatuses.Completed);
	Query.Text =
		"SELECT
		|	COUNT(UpdateHandlers.HandlerName) AS Count
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode
		|	AND UpdateHandlers.Status = &Status";
	Result = Query.Execute().Unload();
	CompletedHandlersCount = Result[0].Count;
	Query.Text =
		"SELECT
		|	COUNT(UpdateHandlers.HandlerName) AS Count
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode";
	Result = Query.Execute().Unload();
	TotalHandlerCount = Result[0].Count;
	
	Result = New Structure;
	Result.Insert("TotalHandlerCount", TotalHandlerCount);
	Result.Insert("CompletedHandlersCount", CompletedHandlersCount);
	
	Return Result;
	
EndFunction

&AtServer
Function CompletedAllSequentialHandlers()
	
	Query = New Query;
	Query.SetParameter("DeferredHandlerExecutionMode", Enums.DeferredHandlersExecutionModes.Sequentially);
	Query.SetParameter("Status", Enums.UpdateHandlersStatuses.Completed);
	Query.Text =
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.DeferredHandlerExecutionMode = &DeferredHandlerExecutionMode
		|	AND UpdateHandlers.Status <> &Status";
	
	Return Query.Execute().IsEmpty();
	
EndFunction

&AtServer
Function HaveProgressIntervalsDataProcessing()
	
	CheckedInterval = BegOfHour(CurrentSessionDate() - 7200);
	
	Query = New Query;
	Query.SetParameter("IntervalHour", CheckedInterval);
	Query.Text =
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.UpdateProgress AS UpdateProgress
		|WHERE
		|	UpdateProgress.IntervalHour >= &IntervalHour";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtServer
Procedure SetDeferredUpdateSchedule(NewSchedule)
	
	FilterOfTasks = New Structure;
	FilterOfTasks.Insert("Metadata", Metadata.ScheduledJobs.DeferredIBUpdate);
	Jobs = ScheduledJobsServer.FindJobs(FilterOfTasks);
	
	For Each Job In Jobs Do
		JobParameters = New Structure("Schedule", NewSchedule);
		ScheduledJobsServer.ChangeJob(Job, JobParameters);
	EndDo;
	
	Schedule = NewSchedule;
	
EndProcedure

&AtClient
Procedure ChangeScheduleAfterSetUpSchedule(NewSchedule, AdditionalParameters) Export
	
	If NewSchedule <> Undefined Then
		If NewSchedule.RepeatPeriodInDay = 0 Then
			Notification = New CallbackDescription("ChangeScheduleAfterQuery", ThisObject, NewSchedule);
			
			QuestionButtons = New ValueList;
			QuestionButtons.Add("SetUpSchedule", NStr("vi = 'Tùy chỉnh lịch biểu';
														|ru = 'Настроить расписание';
														|en = 'Set schedule'; fa = 'تعیین زمان‌بندی';
														|it = 'Impostare l''orario';
														|pl = 'Ustaw harmonogram';
														|tr = 'Programı ayarlamak'"));
			QuestionButtons.Add("RecommendedSettings1", NStr("vi = 'Thiết lập các tùy chỉnh được khuyến cáo';
															|ru = 'Установить рекомендуемые настройки';
															|en = 'Use recommended settings'; fa = 'Use recommended settings';
															|it = 'Imposta le configurazioni consigliate';
															|pl = 'Ustaw zalecane ustawienia';
															|tr = 'Önerilen ayarları kur'"));
			
			MessageText = NStr("vi = 'Thủ tục xử lý dữ liệu bổ sung được thực hiện theo từng phần nhỏ,
				|do đó để làm việc chính xác với dữ liệu, cần đặt khoảng thời gian lặp lại sau khi hoàn thành.
				|
				|Để thực hiện điều này, trong cửa sổ tùy chỉnh lịch biểu, cần chuyển đến thẻ ""Ngày""
				|và điền trường ""Lặp lại sau"".';
				|ru = 'Дополнительные процедуры обработки данных выполняются небольшими порциями,
				|поэтому для их корректной работы необходимо обязательно задать интервал повтора после завершения.
				|
				|Для этого в окне настройки расписания необходимо перейти на вкладку ""Дневное""
				|и заполнить поле ""Повторять через"".';
				|en = 'Additional data processing procedures are executed in small batches.
				|To have them executed correctly, specify the repeat interval.
				|
				|In the schedule settings window, click the ""Daily"" tab
				|and fill in the ""Repeat after"" field.'; fa = 'Additional data processing procedures are executed in small batches.
				|To have them executed correctly, specify the repeat interval.
				|
				|In the schedule settings window, click the ""Daily"" tab
				|and fill in the ""Repeat after"" field.';
				|it = 'Ulteriori procedure di elaborazione dei dati vengono eseguite in piccole porzioni,
				| quindi per il loro corretto funzionamento è necessario impostare l''intervallo di ripetizione dopo il completamento.
				|
				|Per fare ciò, nella finestra delle impostazioni dell''orario è necessario passare alla scheda ""Giornaliero""
				|e compilare il campo ""Ripetere tra"".';
				|pl = 'Dodatkowe procedury przetwarzania danych są wykonywane niewielkimi porcjami,
				|dlatego dla ich poprawnej pracy należy podać interwał powtórzenia po zakończeniu.
				|
				|W tym celu w oknie dialogowym ustawienia harmonogramu należy przejść na kartę ""Dzienny""
				|i wypełnij pole ""Powtórz po"".';
				|tr = 'Ek veri işleme prosedürleri küçük parçalar halinde gerçekleştirilir,
				| bu nedenle doğru çalışmaları için tamamlandıktan sonra yeniden deneme aralığının ayarlanması gerekir.
				|
				| Bunu yapmak için, zamanlama ayarları penceresinde ""Günlük""
				| sekmesine gidin ve ""Şu aralıkla tekrarla"" alanını doldurun.'");
			ShowQueryBox(Notification, MessageText, QuestionButtons,, "SetUpSchedule");
		Else
			SetDeferredUpdateSchedule(NewSchedule);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeScheduleAfterQuery(Result, NewSchedule) Export
	
	If Result = "RecommendedSettings1" Then
		NewSchedule.RepeatPeriodInDay = 60;
		NewSchedule.RepeatPause = 60;
		SetDeferredUpdateSchedule(NewSchedule);
	Else
		CallbackDescription = New CallbackDescription("ChangeScheduleAfterSetUpSchedule", ThisObject);
		Dialog = New ScheduledJobDialog(NewSchedule);
		Dialog.Show(CallbackDescription);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessUpdateResultAtServer()
	
	Items.InstalledPatchesGroup.Visible = False;
	// If it is the first start after a configuration update, storing and resetting status.
	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate")
		And Common.SeparatedDataUsageAvailable() Then
		PatchInfo = Undefined;
		ModuleConfigurationUpdate = Common.CommonModule("ConfigurationUpdate");
		ModuleConfigurationUpdate.CheckUpdateStatus(UpdateResult, ScriptDirectory, PatchInfo);
		ProcessPatchInstallResult(PatchInfo);
	EndIf;
	
	If IsBlankString(ScriptDirectory) Then 
		Items.InformationForTechnicalSupport.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessPatchInstallResult(PatchInfo)
	
	If TypeOf(PatchInfo) <> Type("Structure") Then
		Return;
	EndIf;
	
	TotalPatchCount = PatchInfo.TotalPatchCount;
	If TotalPatchCount = 0 Then
		Return;
	EndIf;
	
	Items.InstalledPatchesGroup.Visible = True;
	Corrections.LoadValues(PatchInfo.Installed);
	
	If PatchInfo.Unspecified > 0 Then
		InstalledSuccessfully = TotalPatchCount - PatchInfo.Unspecified;
		Ref = New FormattedString(NStr("vi = 'Không thể cài đặt bản sửa lỗi';
										|ru = 'Не удалось установить исправления';
										|en = 'Cannot install the patches'; fa = 'Cannot install the patches';
										|it = 'Impossibile installare le rettifiche';
										|pl = 'Nie udało się ustawić korekty';
										|tr = 'Düzeltmeler yüklenemedi'"),,,, "UnsuccessfulInstallation");
		PatchesLabel = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '(%1 trong số %2)';
																					|ru = '(%1 из %2)';
																					|en = '(%1 out of %2).'; fa = '(%1 out of %2).';
																					|it = '(%1 da %2)';
																					|pl = '(%1 z %2)';
																					|tr = '(%1 / %2)'"), InstalledSuccessfully, TotalPatchCount);
		PatchesLabel = New FormattedString(Ref, " ", PatchesLabel);
		Items.InstalledPatchesGroup.CurrentPage = Items.PatchesInstallationErrorGroup;
		Items.PatchesErrorInformation.Title = PatchesLabel;
	Else
		Ref = New FormattedString(NStr("vi = 'Bản sửa lỗi (vá lỗi)';
										|ru = 'Исправления (патчи)';
										|en = 'The patches'; fa = 'The patches';
										|it = 'Correzioni (patch)';
										|pl = 'Korekty (łaty)';
										|tr = 'Düzeltmeler (yamalar)'"),,,, "InstalledPatches");
		PatchesLabel = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'đã cài đặt thành công (%1)';
				|ru = 'успешно установлены (%1)';
				|en = 'are installed (%1).'; fa = 'are installed (%1).';
				|it = 'installate con successo (%1)';
				|pl = 'pomyślnie zainstalowano (%1)';
				|tr = 'başarıyla kuruldu (%1)'"), TotalPatchCount);
		PatchesLabel = New FormattedString(Ref, " ", PatchesLabel);
		Items.PatchesInstalledInformation.Title = PatchesLabel;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessUpdateResultAtClient()
	
	If UpdateResult <> Undefined
		And CommonClient.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		
		ModuleConfigurationUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
		ModuleConfigurationUpdateClient.ProcessUpdateResult(UpdateResult, ScriptDirectory);
		If UpdateResult = False Then
			Items.UpdateResultsGroup.CurrentPage = Items.UpdateErrorGroup;
			// If the configuration is not updated, the deferred handlers are also not executed.
			Items.UpdateStatus.Visible = False;
			Items.WhereToFindThisFormHint.Visible = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowInstalledPatches()
	
	If CommonClient.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		OpeningParameters = New Structure;
		OpeningParameters.Insert("Corrections", Corrections);
		
		ModuleConfigurationUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
		ModuleConfigurationUpdateClient.ShowInstalledPatches(OpeningParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetInfobaseUpdateThreadsCount()
	
	If AccessRight("Read", Metadata.Constants.InfobaseUpdateThreadCount) Then
		InfobaseUpdateThreadCount =
			InfobaseUpdateInternal.InfobaseUpdateThreadCount();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityForInfobaseUpdateThreadsCount(Form)
	
	Available = (Form.UpdatePriority = "DataProcessing");
	Form.Items.InfobaseUpdateThreadCount.Enabled = Available;
	
EndProcedure

&AtServer
Procedure SetVisibilityForInfobaseUpdateThreadsCount()
	
	MultithreadUpdateAllowed = InfobaseUpdateInternal.MultithreadUpdateAllowed();
	Items.InfobaseUpdateThreadCount.Visible = MultithreadUpdateAllowed;
	
	If MultithreadUpdateAllowed Then
		Items.UpdatePriority.ToolTipRepresentation = ToolTipRepresentation.None;
	Else
		Items.UpdatePriority.ToolTipRepresentation = ToolTipRepresentation.Button;
	EndIf;
	
EndProcedure

&AtServer
Function ProblemSituationsInUpdateHandlers()
	
	Query = New Query;
	Query.SetParameter("ExecutionMode", Enums.HandlersExecutionModes.Deferred);
	Query.Text =
		"SELECT
		|	UpdateHandlers.HandlerName AS HandlerName,
		|	UpdateHandlers.ExecutionStatistics AS ExecutionStatistics
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.ExecutionMode = &ExecutionMode";
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.UpdateHandlers");
	LockItem.Mode = DataLockMode.Shared;
	BeginTransaction();
	Try
		Block.Lock();
	
		Result = Query.Execute().Unload();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	IssuesCount = 0;
	For Each String In Result Do
		ExecutionStatistics = String.ExecutionStatistics;
		ExecutionStatistics = ExecutionStatistics.Get();
		If TypeOf(ExecutionStatistics) <> Type("Map") Then
			Continue;
		EndIf;
		
		If ExecutionStatistics["HasErrors"] = True Then
			IssuesCount = IssuesCount + 1;
		EndIf;
	EndDo;
	
	Return IssuesCount;
	
EndFunction

&AtServer
Procedure CheckPerformDeferredUpdate(UpdateInfo)
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If Not Users.IsFullUser(, True) Then
		Return;
	EndIf;
	
	Job = ScheduledJobsServer.Job(Metadata.ScheduledJobs.DeferredIBUpdate);
	TaskIsRunning = False;
	Messages = New Array;
	IdentifierHyperlinks = "";
	If Job.Use Then
		FilterOfTasks = New Structure;
		FilterOfTasks.Insert("MethodName", "InfobaseUpdateInternal.ExecuteDeferredUpdate");
		FoundJobs = BackgroundJobs.GetBackgroundJobs(FilterOfTasks);
		
		For Each BackgroundJob In FoundJobs Do
			// Running background update job is found.
			If BackgroundJob.State = BackgroundJobState.Active Then
				JobActive = True;
				TaskIsRunning = True;
				Break;
			EndIf;
			JobActive = False;
			
			// ACC:143-off - Background jobs use the current date.
			// The background job ran recently.
			If BackgroundJob.End > CurrentDate() - Job.Schedule.RepeatPeriodInDay * 5 Then
				TaskIsRunning = True;
			EndIf;
			
			If Not TaskIsRunning Then
				ExecutionRequired = Job.Schedule.ExecutionRequired(CurrentDate(), BackgroundJob.Begin, BackgroundJob.End);
				TaskIsRunning = Not ExecutionRequired;
			EndIf;
			// ACC:143-on
			
			Break;
		EndDo;
		
		MessageText = NStr("vi = 'Nhiệm vụ thường kỳ <b>Cập nhật hoãn lại</b> đã bật, nhưng
			|chưa thực hiện. Có thể là đã bật phong tỏa thực hiện nhiệm vụ thường kỳ.';
			|ru = 'Регламентное задание <b>Отложенное обновление</b> включено, но
			|не выполняется. Вероятно включена блокировка выполнения регламентных заданий.';
			|en = 'Scheduled job <b>Deferred update</b> is active but not running.
			|Probably, the scheduled job lock is enabled.'; fa = 'Scheduled job <b>Deferred update</b> is active but not running.
			|Probably, the scheduled job lock is enabled.';
			|it = 'Регламентное задание <b>Отложенное обновление</b> включено, но
			|не выполняется. Вероятно включена блокировка выполнения регламентных заданий.';
			|pl = 'Scheduled job <b>Deferred update</b> is active but not running.
			|Probably, the scheduled job lock is enabled.';
			|tr = 'Zamanlanmış görev<b>Gecikmeli güncelleme</b> etkin ancak 
			|çalışmıyor. Zamanlanmış görevlerin yürütülmesinin engellenmesi muhtemelen etkinleştirilmiştir.'");
		Messages.Add(StrConcat(StrSplit(MessageText, Chars.LF), " "));
		If Common.SubsystemExists("StandardSubsystems.UsersSessions") Then
			Messages.Add(NStr("vi = '<a href=""%1"">Kiểm tra phong tỏa nhiệm vụ thường kỳ</a>';
								|ru = '<a href=""%1"">Проверить блокировку регламентных заданий</a>';
								|en = '<a href=""%1"">Check scheduled job lock</a>'; fa = '<a href=""%1"">Check scheduled job lock</a>';
								|it = '<a href=""%1"">Проверить блокировку регламентных заданий</a>';
								|pl = '<a href=""%1"">Check scheduled job lock</a>';
								|tr = 'Planlanmış işlerin kilitlenmesini kontrol et'"));
			IdentifierHyperlinks = "CheckLock";
		EndIf;
	Else
		MessageText = NStr("vi = 'Chưa thực hiện thủ tục xử lý dữ liệu bổ sung,
			|bởi vì đã vô hiệu hóa nhiệm vụ thường kỳ <b>Cập nhật hoãn lại</b>.';
			|ru = 'Дополнительные процедуры обработки данных не выполняются,
			|т.к. отключено регламентное задание <b>Отложенное обновление</b>.';
			|en = 'Additional procedures of data processing are not running
			|because the <b>Deferred update</b> scheduled job is disabled.'; fa = 'Additional procedures of data processing are not running
			|because the <b>Deferred update</b> scheduled job is disabled.';
			|it = 'Дополнительные процедуры обработки данных не выполняются,
			|т.к. отключено регламентное задание <b>Отложенное обновление</b>.';
			|pl = 'Additional procedures of data processing are not running
			|because the <b>Deferred update</b> scheduled job is disabled.';
			|tr = 'Ek veri işleme prosedürleri gerçekleştirilmez, 
			|çünkü zamanlanmış görev devre dışı bırakılmış <b>Gecikmeli güncelleme</b>.'");
		Messages.Add(StrConcat(StrSplit(MessageText, Chars.LF), " "));
		Messages.Add(NStr("vi = '<a href=""%1"">Bật</a>';
							|ru = '<a href=""%1"">Включить</a>';
							|en = '<a href=""%1"">Enable</a>'; fa = '<a href=""%1"">Enable</a>';
							|it = '<a href=""%1"">Включить</a>';
							|pl = '<a href=""%1"">Enable</a>';
							|tr = '<a href=""%1"">Aç</a>'"));
		IdentifierHyperlinks = "Enable";
	EndIf;
	MessageText = StringFunctions.FormattedString(StrConcat(Messages, Chars.LF), IdentifierHyperlinks);
	Items.ExplanationUpdateNotRunning.Title = MessageText;
	
	Items.HeaderGroupClientServer.Visible = TaskIsRunning;
	Items.GroupHeaderUpdateNotRunning.Visible = Not TaskIsRunning;
	
EndProcedure

&AtServer
Procedure EnableScheduledJob()
	InfobaseUpdateInternal.OnEnableDeferredUpdate(True);
EndProcedure

&AtServer
Function ThereHandlersWithParallelExecutionMode()
	
	Query = New Query;
	Query.SetParameter("DeferredHandlerExecutionMode", Enums.DeferredHandlersExecutionModes.Parallel);
	Query.Text =
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.UpdateHandlers AS UpdateHandlers
		|WHERE
		|	UpdateHandlers.DeferredHandlerExecutionMode = &DeferredHandlerExecutionMode";
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion
