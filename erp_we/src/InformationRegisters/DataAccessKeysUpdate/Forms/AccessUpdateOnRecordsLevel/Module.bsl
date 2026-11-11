///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var ResultAddress, StoredDataAddress, ProgressUpdateJobID,
		AccessUpdateErrorText, IsProgressUpdatedAfterStartImmediatelyCommand,
		RefreshProgressBarOnActivateForm, DateOfAccessUpdatePlanChange;

#EndRegion


#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	URL = "e1cib/app/InformationRegister.DataAccessKeysUpdate.Form.AccessUpdateOnRecordsLevel";
	
	AccessManagementInternal.CheckIsAccessRestrictionDisabled();
	
	ProgressUpdatePeriod = 3;
	ProgressAutoUpdate = Not Parameters.DisableProgressAutoUpdate;
	ShowItemsCount = True;
	ShowAccessKeysCount = True;
	
	ShowProcessingDelay = True;
	SortFields.Add("ListProcessingDelay", "Asc");
	MaxDate = AccessManagementInternal.MaxDate();
	SetSortingPicture(Items.ListsListProcessingDelay, False);
	
	If Parameters.ShowProgressPerLists Then
		Items.BriefDetailed.Show();
	EndIf;
	
	SetPrivilegedMode(True);
	AccessUpdateThreadsCount = Constants.AccessUpdateThreadsCount.Get();
	If AccessManagementInternal.DiskLoadBalancingAvailable() Then
		DiskLoadBalancing = AccessManagementInternal.DiskLoadBalancing();
	Else
		DiskLoadBalancing = False;
		Items.DiskLoadBalancing1.Enabled = False;
		Items.DiskLoadBalancing2.Enabled = False;
	EndIf;
	SetPrivilegedMode(False);
	If AccessUpdateThreadsCount = 0 Then
		AccessUpdateThreadsCount = 1;
	EndIf;
	Items.AccessUpdateThreadsCountGroupTooltip1.ToolTip =
		Metadata.Constants.AccessUpdateThreadsCount.Tooltip;
	Items.AccessUpdateThreadsCountGroupTooltip2.ToolTip =
		Metadata.Constants.AccessUpdateThreadsCount.Tooltip;
	
	Items.DiskLoadBalancingGroupTooltip1.ToolTip =
		NStr("vi = 'Nếu khi cập nhật truy cập, tốc độ truyền dữ liệu
		           |với ổ HDD giảm xuống còn 2-10 Mb/giây thay vì
		           |40-150 Mb/giây và ổ bị chiếm 100% trong
		           | 5-10 phút trở lên, thì ổ chậm.
		           |Lưu ý: Ổ SSD được coi là nhanh.';
		           |ru = 'Если при обновлении доступа скорость передачи данных
		           |с устройства HDD уменьшается до 2-10 Мб/сек вместо
		           |40-150 мб/сек и устройство занято на 100% в течении
		           |5-10 минут или более, то диск медленный.
		           |Прим: устройство SSD считается быстрым.';
		           |en = 'If the HDD transfer rate decreases
		           |from 40–150 MB/s to 2–10 MB/s
		           |during access updates and the HDD load is 100%
		           |for 5–10 minutes or more, the hard drive is slow.
		           |Note: SSD is considered to be fast.'; fa = 'If the HDD transfer rate decreases
		           |from 40–150 MB/s to 2–10 MB/s
		           |during access updates and the HDD load is 100%
		           |for 5–10 minutes or more, the hard drive is slow.
		           |Note: SSD is considered to be fast.';
		           |it = 'Если при обновлении доступа скорость передачи данных
		           |с устройства HDD уменьшается до 2-10 Мб/сек вместо
		           |40-150 мб/сек и устройство занято на 100% в течении
		           |5-10 минут или более, то диск медленный.
		           |Прим: устройство SSD считается быстрым.';
		           |pl = 'If the HDD transfer rate decreases
		           |from 40–150 MB/s to 2–10 MB/s
		           |during access updates and the HDD load is 100%
		           |for 5–10 minutes or more, the hard drive is slow.
		           |Note: SSD is considered to be fast.';
		           |tr = 'Güncelleme sırasında verilerin HDD''den aktarım hızı gereken 
		           |40-150 MB/saniye yerine 
		           |2-10 MB/saniye kadar düşüyorsa ve disk 5-10 saniye veya daha uzun süre boyunca 100% yüklenirse
		           |, disk yavaştır.
		           |Örn: SSD disk hızlı kabul edilir.'");
	Items.DiskLoadBalancingGroupTooltip2.ToolTip =
		Items.DiskLoadBalancingGroupTooltip1.ToolTip;
	
	If Common.FileInfobase()
	 Or Common.DataSeparationEnabled() Then
		
		Items.NumberOfAccessUpdateThreads1Group.Visible = False;
		Items.NumberOfAccessUpdateStreams2Group.Visible = False;
	EndIf;
	
	RedColor = StyleColors.SpecialTextColor;
	BoldFont = StyleFonts.ImportantLabelFont;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RefreshProgressBarOnActivateForm = False;
	IsProgressUpdatedAfterStartImmediatelyCommand = True;
	UpdateAccessUpdateThreadsCountGroupTitle();
	
	OnReopen();
	
EndProcedure

&AtClient
Procedure OnReopen()
	
	UpdateAccessUpdateJobState(, True);
	
	StartProgressUpdate(True, True);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If ValueIsFilled(ProgressUpdateJobID) Then
		CancelProgressUpdateAtServer(ProgressUpdateJobID);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_DataAccessKeysUpdate"
	 Or EventName = "Write_UsersAccessKeysUpdate" Then
		
		StartProgressUpdate(True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AccessUpdateThreadsOnChangeCount(Item)
	
	If AccessUpdateThreadsCount = 0 Then
		AccessUpdateThreadsCount = 1;
	EndIf;
	
	SetAccessUpdateThreadsCountAtServer(AccessUpdateThreadsCount);
	
	UpdateAccessUpdateThreadsCountGroupTitle();
	
EndProcedure

&AtClient
Procedure AccessUpdateThreadsCountChangeEditingText(Item, Text, StandardProcessing)
	
	StandardProcessing = False;
	If ValueIsFilled(Text) Then
		AccessUpdateThreadsCount = Number(Text);
	Else
		AccessUpdateThreadsCount = 1;
	EndIf;
	
	AccessUpdateThreadsOnChangeCount(Item);
	
EndProcedure

&AtClient
Procedure DiskLoadBalancingOnChange(Item)
	
	DiskLoadBalancingOnChangeAtServer(DiskLoadBalancing);
	
EndProcedure

&AtClient
Procedure LastAccessUpdateCompletionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "ShowErrorText" Then
		TextDocument = New TextDocument;
		TextDocument.SetText(AccessUpdateErrorText);
		TextDocument.Show(NStr("vi = 'Lỗi cập nhật truy cập';
								|ru = 'Ошибка обновления доступа';
								|en = 'Access update error'; fa = 'Access update error';
								|it = 'Errore di aggiornamento dell''accesso';
								|pl = 'Aktualizacja dostępu nie powiodła się';
								|tr = 'Erişim güncellemesi hatası'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure ProgressAutoUpdateOnChange(Item)
	
	StartProgressUpdate();
	
EndProcedure

&AtClient
Procedure CalculateByDataAmountOnChange(Item)
	
	UpdateDisplaySettingsVisibility();
	
	IsRepeatedProgressUpdate = False;
	StartProgressUpdate(True);
	
EndProcedure

&AtClient
Procedure ShowItemsCountOnChange(Item)
	
	Items.ListsItemCount.Visible             = ShowItemsCount;
	Items.ListsProcessedItemsCount.Visible = ShowItemsCount;
	
EndProcedure

&AtClient
Procedure ShowAccessKeysCountOnChange(Item)
	
	Items.ListsAccessKeysCount.Visible             = ShowAccessKeysCount;
	Items.ListsProcessedAccessKeysCount.Visible = ShowAccessKeysCount;
	
EndProcedure

&AtClient
Procedure ShowProcessingDelayOnChange(Item)
	
	Items.ListsListProcessingDelay.Visible = ShowProcessingDelay;
	
EndProcedure

&AtClient
Procedure ShowTableNameOnChange(Item)
	
	Items.ListsTableName.Visible = ShowTableName;
	
EndProcedure

&AtClient
Procedure ShowProcessedListsOnChange(Item)
	
	StartProgressUpdate(True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLists

&AtClient
Procedure ListsOnActivateRow(Item)
	
	AttachIdleHandler("UpdateDisplaySettingsVisibility", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure StartAccessUpdateImmediately(Command)
	
	IsProgressUpdatedAfterStartImmediatelyCommand = False;
	AttachIdleHandler("StartAccessUpdateNowIdleHandler", 0.1, True);
	Items.StartAccessUpdateImmediately.Enabled = False;
	UpdateAccessUpdateJobStateInThreeSeconds();
	
EndProcedure

&AtClient
Procedure EnableAccessUpdate(Command)
	
	EnableAccessUpdateAtServer();
	
	Items.AccessUpdateProhibited.Visible = False;
	Items.ScheduledJobDisabled.Visible = False;
	
	StartProgressUpdate(True);
	
EndProcedure

&AtClient
Procedure StopAndProhibitAccessUpdate(Command)
	
	AttachIdleHandler("StopAndProhibitAccessUpdateIdleHandler", 0.1, True);
	Items.StopAndProhibitAccessUpdate.Enabled = False;
	UpdateAccessUpdateJobStateInThreeSeconds();
	
EndProcedure

&AtClient
Procedure RefreshProgressBar(Command)
	
	StartProgressUpdate(True);
	
EndProcedure

&AtClient
Procedure CancelRefreshingProgressBar(Command)
	
	If ValueIsFilled(ProgressUpdateJobID) Then
		CancelProgressUpdateAtServer(ProgressUpdateJobID);
		If ProgressAutoUpdate Then
			ProgressAutoUpdate = False;
			Explanation = NStr("vi = 'Đã ngắt tự động cập nhật tiến trình';
								|ru = 'Автообновление прогресса отключено';
								|en = 'Automatic update of the progress bar is disabled.'; fa = 'Automatic update of the progress bar is disabled.';
								|it = 'Aggiornamento automatico avanzamento disabilitato';
								|pl = 'Automatyczna aktualizacja postępu wyłączona';
								|tr = 'Otomatik ilerleme güncellemesi devre dışı bırakıldı'");
		Else
			Explanation = "";
		EndIf;
		ShowUserNotification(NStr("vi = 'Đã hủy bỏ cập nhật tiến trình';
									|ru = 'Обновление прогресса отменено';
									|en = 'Progress bar update canceled'; fa = 'Progress bar update canceled';
									|it = 'Aggiornamento del progresso disabilitato';
									|pl = 'Aktualizacja postępu anulowana';
									|tr = 'İlerlemenin güncellenmesi iptal edildi'"),,
			Explanation);
	EndIf;
	
	Items.ProgressBarRefresh.CurrentPage = Items.RefreshingProgressBarCompleted;
	Items.CancelRefreshingProgressBar.Enabled = False;
	
EndProcedure

&AtClient
Procedure ManualControl(Command)
	
	OpenForm("InformationRegister.DataAccessKeysUpdate.Form.AccessUpdateManualControl");
	
EndProcedure

&AtClient
Procedure SortListAsc(Command)
	
	SortList();
	
EndProcedure

&AtClient
Procedure SortListDesc(Command)
	
	SortList(True);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListsListProcessingDelay.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Lists.ListProcessingDelay");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 999999;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Lists.ItemsProcessed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 100;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Lists.AccessKeysProcessed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 100;
	
	Item.Appearance.SetParameterValue("Text", "--- ---");
	
EndProcedure

&AtServerNoContext
Procedure SetAccessUpdateThreadsCountAtServer(Val Count)
	
	If Constants.AccessUpdateThreadsCount.Get() <> Count Then
		Constants.AccessUpdateThreadsCount.Set(Count);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure DiskLoadBalancingOnChangeAtServer(DiskLoadBalancing)
	
	AccessManagementInternal.SetDiskLoadBalancing(DiskLoadBalancing);
	DiskLoadBalancing = AccessManagementInternal.DiskLoadBalancing();
	
EndProcedure

&AtClient
Procedure UpdateAccessUpdateThreadsCountGroupTitle()
	
	Items.NumberOfAccessUpdateThreads1Group.Title =
		Format(AccessUpdateThreadsCount, "NG=") + " "
			+ UsersInternalClientServer.IntegerSubject(AccessUpdateThreadsCount,
				"", NStr("vi = 'luồng, luồng, luồng ,,,,,, 0';
						|ru = 'поток,потока,потоков,,,,,,0';
						|en = 'thread,threads,,0'; fa = 'thread,threads,,0';
						|it = 'flusso,flussi,flussi,,,,,,0';
						|pl = 'thread,threads,,0';
						|tr = 'akış,akışın,akışların,,,,,,0'"));
	
	Items.NumberOfAccessUpdateStreams2Group.Title =
		Items.NumberOfAccessUpdateThreads1Group.Title;
	
EndProcedure

&AtClient
Procedure UpdateAccessUpdateJobStateInThreeSeconds()
	
	DetachIdleHandler("UpdateAccessUpdateJobStateIdleHandler");
	AttachIdleHandler("UpdateAccessUpdateJobStateIdleHandler", 3.5);
	
EndProcedure

&AtClient
Procedure UpdateAccessUpdateJobStateIdleHandler()
	
	UpdateAccessUpdateJobState();
	
EndProcedure

&AtClient
Procedure UpdateAccessUpdateJobState(State = Undefined, OnOpen = False)
	
	If Not OnOpen And Not IsFormActive() Then
		DetachIdleHandler("UpdateAccessUpdateJobStateIdleHandler");
		AttachIdleHandler("UpdateAccessUpdateJobStateIdleHandler", 1);
		Return;
	EndIf;
	
	UpdateDisplaySettingsVisibility();
	
	If State = Undefined Then
		State = AccessUpdateJobState();
	EndIf;
	
	Universal = State.LimitAccessAtRecordLevelUniversally;
	Items.WarningUniversalRestrictionDisabledGroup.Visible = Not Universal;
	Items.AllowAccessUpdate.Enabled  = Universal;
	Items.EnableScheduledJob.Enabled = Universal;
	
	Items.InitialAccessUpdateInProgressWarningGroup.Visible =
		Universal And Not State.LimitAccessAtRecordLevelUniversallyEnabled;
	
	Items.AccessUpdateProhibited.Visible = State.AccessUpdateProhibited;
	Items.ScheduledJobDisabled.Visible = Not State.AccessUpdateProhibited
		And State.ScheduledJobDisabled And Not State.AccessUpdateInProgress And UpdatedTotal <> 100;
	
	AccessUpdateErrorText = State.AccessUpdateErrorText;
	
	If ValueIsFilled(State.LastAccessUpdateCompletion) Then
		PartsFormat = New Map;
		
		If State.UpdateCanceledAbnormally Then
			If State.LastCompletionToday Then
				Template = NStr("vi = '<1> bị hủy bất thường </ 1> sau khi bắt đầu ở %1';
								|ru = '<1>отменено нештатно</1> после запуска в %1';
								|en = '<1>terminated</1> after a start at %1'; fa = '<1>terminated</1> after a start at %1';
								|it = '<1>annullamento anomalo</1> dopo l''avvio in %1';
								|pl = '<1>anulowano niestandardowo</1> po uruchomieniu w %1';
								|tr = '%1''de başlatıldıktan sonra <1>beklenmeyen şekilde iptal edildi</1>'");
			Else
				Template = NStr("vi = '<1> bị hủy bất thường </ 1> sau khi chạy %1';
								|ru = '<1>отменено нештатно</1> после запуска %1';
								|en = '<1>terminated</1> after a start on %1'; fa = '<1>terminated</1> after a start on %1';
								|it = '<1>annullamento anomalo</1> dopo l''avvio %1';
								|pl = '<1>anulowano niestandardowo</1> po uruchomieniu %1';
								|tr = '%1 başlatıldıktan sonra <1>beklenmeyen şekilde iptal edildi</1>'");
			EndIf;
			PartsFormat.Insert(1, New Structure("Font, TextColor", BoldFont, RedColor));
		ElsIf ValueIsFilled(AccessUpdateErrorText) Then
			If State.RefreshEnabledCanceled Then
				If State.LastCompletionToday Then
					Template = NStr("vi = '<1> đã hủy </ 1> <2> có lỗi </ 2> từ %1 đến %2';
									|ru = '<1>отменено</1> <2>с ошибкой</2> в %1 через %2';
									|en = '<1>canceled</1> <2>with an error</2> at %1, duration: %2'; fa = '<1>canceled</1> <2>with an error</2> at %1, duration: %2';
									|it = '<1>annullato</1> <2>con errore</2> alle %1 tra %2';
									|pl = '<1>anulowano</1> <2>z błędem</2> w %1 za %2';
									|tr = '%2 aracılığıyla %1''de <2>hatasıyla</2> <1>iptal edildi</1>'");
				Else
					Template = NStr("vi = '<1> đã hủy </ 1> <2> có lỗi </ 2>%1 đến %2';
									|ru = '<1>отменено</1> <2>с ошибкой</2> %1 через %2';
									|en = '<1>canceled</1> <2>with an error</2> %1, duration: %2'; fa = '<1>canceled</1> <2>with an error</2> %1, duration: %2';
									|it = '<1>annullato</1> <2>con errore</2> %1 tra %2';
									|pl = '<1>ukończono</1> <2>z błędem</2> %1 za %2';
									|tr = '%2 aracılığıyla %1 <2>hatasıyla</2> <1>iptal edildi</1>'");
				EndIf;
			Else
				If State.LastCompletionToday Then
					Template = NStr("vi = '<1> đã hoàn thành </ 1> <2> có lỗi </ 2> từ %1 đến %2';
									|ru = '<1>завершено</1> <2>с ошибкой</2> в %1 через %2';
									|en = '<1>completed</1> <2>with an error</2> at %1, duration: %2'; fa = '<1>completed</1> <2>with an error</2> at %1, duration: %2';
									|it = '<1>completato</1> <2>con errore</2> alle %1 tra %2';
									|pl = '<1>ukończono</1> <2>z błędem</2> w %1 za %2';
									|tr = '%2 aracılığıyla %1''de <2>hatasıyla</2> <1>tamamlandı</1>'");
				Else
					Template = NStr("vi = '<1> đã hoàn thành </ 1> <2> có lỗi </ 2> %1 đến %2';
									|ru = '<1>завершено</1> <2>с ошибкой</2> %1 через %2';
									|en = '<1>completed</1> <2>with an error</2>on %1, duration: %2'; fa = '<1>completed</1> <2>with an error</2>on %1, duration: %2';
									|it = '<1>completato</1> <2>con errore</2> %1 tra %2';
									|pl = '<1>ukończono</1> <2>z błędem</2> %1 za %2';
									|tr = '%2 aracılığıyla %1 <2>hatasıyla</2> <1>tamamlandı</1>'");
				EndIf;
			EndIf;
			PartsFormat.Insert(1, New Structure("Font, TextColor", BoldFont, RedColor));
			PartsFormat.Insert(2, New Structure("Ref", "ShowErrorText"));
		Else
			If State.RefreshEnabledCanceled Then
				If State.LastCompletionToday Then
					Template = NStr("vi = 'đã hủy trong %1 sau %2';
									|ru = 'отменено в %1 через %2';
									|en = 'canceled at %1, duration: %2'; fa = 'canceled at %1, duration: %2';
									|it = 'annullato alle %1 tra %2';
									|pl = 'anulowane w %1 przez %2';
									|tr = '%2 aracılığıyla %1''de iptal edildi '");
				Else
					Template = NStr("vi = 'đã hủy %1 sau %2';
									|ru = 'отменено %1 через %2';
									|en = 'canceled on %1, duration: %2'; fa = 'canceled on %1, duration: %2';
									|it = 'annullato %1 tra %2';
									|pl = 'anulowane %1 przez %2';
									|tr = '%2 aracılığıyla %1 iptal edildi '");
				EndIf;
			Else
				If State.LastCompletionToday Then
					Template = NStr("vi = 'đã kết thúc trong %1 sau %2';
									|ru = 'завершено в %1 за %2';
									|en = 'completed at %1, duration: %2'; fa = 'completed at %1, duration: %2';
									|it = 'completato alle %1 in %2';
									|pl = 'ukończono w %1 za %2';
									|tr = '%2 süresinde %1''de tamamlandı'");
				Else
					Template = NStr("vi = 'đã kết thúc %1 trong %2';
									|ru = 'завершено %1 за %2';
									|en = 'completed on %1, duration: %2'; fa = 'completed on %1, duration: %2';
									|it = 'completato %1 in %2';
									|pl = 'ukończono %1 za %2';
									|tr = '%2 süresinde %1 tamamlandı'");
				EndIf;
			EndIf;
		EndIf;
		If State.LastCompletionToday Then
			Template = StrReplace(Template, "%1", "<3>%1</3>");
			PartsFormat.Insert(3, New Structure("Font", BoldFont));
			
			LastCompletion = StringFunctionsClientServer.SubstituteParametersToString(Template,
				Format(State.LastAccessUpdateCompletion, "DLF=T"),
				State.LastExecutionDuration);
		Else
			LastCompletion = StringFunctionsClientServer.SubstituteParametersToString(Template,
				Format(State.LastAccessUpdateCompletion, "DLF=DT"),
				State.LastExecutionDuration);
		EndIf;
		LastCompletion = StringWithFormattedParts("(" + LastCompletion + ")", PartsFormat, 3);
	Else
		LastCompletion = "(" + ?(State.AccessUpdateInProgress,
			NStr("vi = 'chưa hoàn thành';
				|ru = 'не завершалось';
				|en = 'never completed'; fa = 'never completed';
				|it = 'non è stato completato';
				|pl = 'nie zostało ukończone';
				|tr = 'tamamlanmadı'"), NStr("vi = 'chưa khởi động';
												|ru = 'не запускалось';
												|en = 'never started'; fa = 'never started';
												|it = 'non è stato avviato';
												|pl = 'nie zostało uruchomione';
												|tr = 'başlatılmadı'")) + ")";
	EndIf;
	Items.LastAccessUpdateCompletion.Title = LastCompletion;
	
	JobExecutionCompleted = ValueIsFilled(State.LastAccessUpdateCompletion)
		And LastAccessUpdateCompletion <> State.LastAccessUpdateCompletion;
	LastAccessUpdateCompletion = State.LastAccessUpdateCompletion;
	
	IsJobExecutionStateChanged = State.AccessUpdateInProgress
		<> Items.AccessUpdateInProgress.Visible;
	Items.AccessUpdateInProgress.Visible   =    State.AccessUpdateInProgress;
	Items.AccessUpdateNotStarted.Visible = Not State.AccessUpdateInProgress;
	
	Items.StopAndProhibitAccessUpdate.Enabled =    State.AccessUpdateInProgress;
	Items.StartAccessUpdateImmediately.Enabled      = Not State.AccessUpdateInProgress And Universal;
	
	Items.BackgroundJobInProgressPicture.Visible       =    State.BackgroundJobRunning;
	Items.BackgroundJobPendingExecutionPicture.Visible = Not State.BackgroundJobRunning;
	
	AreUpdatePlansChanged = Not State.AccessUpdateInProgress
		And DateOfAccessUpdatePlanChange <> State.DateOfUpdatePlanChange;
	DateOfAccessUpdatePlanChange = State.DateOfUpdatePlanChange;
	
	If Not State.AccessUpdateInProgress Then
		Items.BackgroundJobRunTime1.Title = "";
		Items.BackgroundJobRunTime2.Title = "";
	Else
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đang thực hiện %1';
																					|ru = 'Выполняется %1';
																					|en = 'Running for %1'; fa = 'Running for %1';
																					|it = 'In corso %1';
																					|pl = 'W trakcie wykonywania %1';
																					|tr = 'Gerçekleştiriliyor %1'"),
			ExecutionTimeAsString(State.RunningInSeconds));
		
		Items.BackgroundJobRunTime1.Title = TitleText;
		Items.BackgroundJobRunTime2.Title = TitleText;
		
		FirstJobVisibility = Items.BackgroundJobRunTime1.Visible;
		FirstJobVisibility = Not FirstJobVisibility;
		
		Items.BackgroundJobRunTime1.Visible =    FirstJobVisibility;
		Items.BackgroundJobRunTime2.Visible = Not FirstJobVisibility;
	EndIf;
	
	If RefreshProgressBarOnActivateForm = True Then
		StartProgressUpdate(True, True);
		RefreshProgressBarOnActivateForm = False;
		
	ElsIf Not OnOpen
	        And Not ProgressAutoUpdate
	        And (JobExecutionCompleted
	           Or IsProgressUpdatedAfterStartImmediatelyCommand <> True
	           Or IsJobExecutionStateChanged
	           Or AreUpdatePlansChanged) Then
		
		StartProgressUpdate(True);
	EndIf;
	
	UpdateAccessUpdateJobStateInThreeSeconds();
	
EndProcedure

&AtClientAtServerNoContext
Function ExecutionTimeAsString(TimeInSeconds)
	
	MinutesTotal = Int(TimeInSeconds / 60);
	Seconds = TimeInSeconds - MinutesTotal * 60;
	HoursTotal = Int(MinutesTotal / 60);
	Minutes = MinutesTotal - HoursTotal * 60;
	
	If HoursTotal > 0 Then
		Template = NStr("vi = '%3 giờ %2 phút %1 giây';
						|ru = '%3 ч %2 мин %1 сек';
						|en = '%3 h %2 min %1 sec'; fa = '%3 h %2 min %1 sec';
						|it = '%3 h %2 min %1 sec';
						|pl = '%3 g %2 min %1 sek';
						|tr = '%3 %2 dak %1 san'");
		
	ElsIf Minutes > 0 Then
		Template = NStr("vi = '%2 phút %1 giây';
						|ru = '%2 мин %1 сек';
						|en = '%2 min %1 sec'; fa = '%2 min %1 sec';
						|it = '%2 min %1 sec';
						|pl = '%2 min %1 sek';
						|tr = '%2 dak %1 san'");
	Else
		Template = NStr("vi = '%1 giây';
						|ru = '%1 сек';
						|en = '%1 sec'; fa = '%1 sec';
						|it = '%1 sec-';
						|pl = '%1 sek';
						|tr = 'saniye %1'");
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(Template,
		Format(Seconds, "NZ=0; NG="), Format(Minutes, "NZ=0; NG="), Format(HoursTotal, "NG="));
	
EndFunction

&AtServerNoContext
Function AccessUpdateJobState()
	
	LastAccessUpdate = AccessManagementInternal.LastAccessUpdate();
	CurrentDateAtServer = AccessManagementInternal.CurrentDateAtServer();
	
	State = New Structure;
	
	State.Insert("LimitAccessAtRecordLevelUniversally",
		AccessManagementInternal.LimitAccessAtRecordLevelUniversally(True));
	
	State.Insert("LimitAccessAtRecordLevelUniversallyEnabled",
		AccessManagementInternal.LimitAccessAtRecordLevelUniversally(True, True));
	
	State.Insert("LastAccessUpdateCompletion",
		?(ValueIsFilled(LastAccessUpdate.FullCompletionDate),
			LastAccessUpdate.FullCompletionDate,
			LastAccessUpdate.EndDateAtServer));
	
	State.Insert("LastExecutionDuration",
		ExecutionTimeAsString(LastAccessUpdate.LastExecutionSeconds));
	
	State.Insert("LastCompletionToday",
		IsCurrentDate(CurrentDateAtServer, State.LastAccessUpdateCompletion));
	
	State.Insert("RefreshEnabledCanceled",
		LastAccessUpdate.RefreshEnabledCanceled);
	
	State.Insert("AccessUpdateErrorText",
		LastAccessUpdate.CompletionErrorText);
	
	State.Insert("AccessUpdateProhibited",
		LastAccessUpdate.AccessUpdateProhibited);
	
	State.Insert("RunningInSeconds", 0);
	State.Insert("UpdateCanceledAbnormally", False);
	
	Performer = AccessManagementInternal.AccessUpdateAssignee(LastAccessUpdate);
	
	If Performer = Undefined Then
		State.Insert("AccessUpdateInProgress", False);
		State.Insert("BackgroundJobRunning", False);
		If LastAccessUpdate.StartDateAtServer > LastAccessUpdate.EndDateAtServer Then
			State.UpdateCanceledAbnormally = True;
			State.LastAccessUpdateCompletion = LastAccessUpdate.StartDateAtServer;
		EndIf;
		
	ElsIf TypeOf(Performer) = Type("BackgroundJob")
	        And (Performer.UUID <> LastAccessUpdate.BackgroundJobIdentifier
	           Or Common.FileInfobase()
	             And Not BackgroundJobSessionExists(Performer)) Then
		
		State.Insert("AccessUpdateInProgress", True);
		WaitsForSecondsExecution = CurrentDateAtServer - Performer.Begin;
		WaitsForSecondsExecution = ?(WaitsForSecondsExecution < 0, 0, WaitsForSecondsExecution);
		State.Insert("BackgroundJobRunning", WaitsForSecondsExecution < 2);
	Else
		State.Insert("AccessUpdateInProgress", True);
		State.Insert("BackgroundJobRunning", True);
		RunningInSeconds = CurrentDateAtServer - LastAccessUpdate.StartDateAtServer;
		State.Insert("RunningInSeconds", ?(RunningInSeconds < 0, 0, RunningInSeconds));
	EndIf;
	
	State.Insert("ScheduledJobDisabled", False);
	State.Insert("DateOfUpdatePlanChange", '00010101');
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	DataAccessKeysUpdate.RegisterRecordChangeDate AS ChangeDate
	|FROM
	|	InformationRegister.DataAccessKeysUpdate AS DataAccessKeysUpdate
	|
	|ORDER BY
	|	DataAccessKeysUpdate.RegisterRecordChangeDate DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	UsersAccessKeysUpdate.RegisterRecordChangeDate AS ChangeDate
	|FROM
	|	InformationRegister.UsersAccessKeysUpdate AS UsersAccessKeysUpdate
	|
	|ORDER BY
	|	UsersAccessKeysUpdate.RegisterRecordChangeDate DESC";
	
	QueryResults = Query.ExecuteBatch();
	
	If QueryResults[0].IsEmpty() And QueryResults[1].IsEmpty() Then
		Return State;
	EndIf;
	
	If Not QueryResults[0].IsEmpty() Then
		State.DateOfUpdatePlanChange = QueryResults[0].Unload()[0].ChangeDate;
	EndIf;
	If Not QueryResults[1].IsEmpty() Then
		ChangeDate = QueryResults[1].Unload()[0].ChangeDate;
		If ChangeDate > State.DateOfUpdatePlanChange Then
			State.DateOfUpdatePlanChange = ChangeDate;
		EndIf;
	EndIf;
	
	Filter = New Structure("Metadata", Metadata.ScheduledJobs.AccessUpdateOnRecordsLevel);
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	isEnabled = False;
	For Each Job In Jobs Do
		If Job.Use Then
			isEnabled = True;
			Break;
		EndIf;
	EndDo;
	
	If Not isEnabled Then
		State.ScheduledJobDisabled = True;
	EndIf;
	
	Return State;
	
EndFunction

&AtServerNoContext
Function BackgroundJobSessionExists(BackgroundJob)
	
	Sessions = GetInfoBaseSessions();
	For Each Session In Sessions Do
		If Session.ApplicationName <> "BackgroundJob" Then
			Continue;
		EndIf;
		BackgroundSessionJob = Session.GetBackgroundJob();
		If BackgroundSessionJob = Undefined Then
			Continue;
		EndIf;
		If BackgroundSessionJob.UUID = BackgroundJob.UUID Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServerNoContext
Function IsCurrentDate(CurrentDate, Date)
	
	Return CurrentDate < Date + 12 * 60 * 6;
	
EndFunction

&AtClient
Procedure StartAccessUpdateNowIdleHandler()
	
	AccessUpdateJobState = Undefined;
	
	WarningText = StartAccessUpdateNowAtServer(AccessUpdateJobState);
	
	If ValueIsFilled(WarningText) Then
		ShowMessageBox(, WarningText);
	EndIf;
	
	UpdateAccessUpdateJobState(AccessUpdateJobState);
	
EndProcedure

&AtServerNoContext
Function StartAccessUpdateNowAtServer(AccessUpdateJobState)
	
	Result = AccessManagementInternal.StartAccessUpdateAtRecordLevel(True);
	
	AccessUpdateJobState = AccessUpdateJobState();
	
	Return Result.WarningText;
	
EndFunction

&AtClient
Function IsFormActive()
	
	IsFormActive = ActiveWindow() = Window Or IsInputAvailable();
	
	If Items.UpdatedTotal.ShowPercent <> IsFormActive Then
		Items.UpdatedTotal.ShowPercent = IsFormActive;
	EndIf;
	
	Return IsFormActive;
	
EndFunction

&AtClient
Procedure StartProgressUpdate(ManualStart = False, OnActivateForm = False)
	
	If ManualStart And ValueIsFilled(ProgressUpdateJobID) Then
		CancelProgressUpdateAtServer(ProgressUpdateJobID);
		
	ElsIf Not ProgressAutoUpdate And Not ManualStart
	 Or Items.ProgressBarRefresh.CurrentPage = Items.RefreshingProgressBar Then
		
		Return;
	EndIf;
	
	If Not OnActivateForm And Not IsFormActive() Then
		RefreshProgressBarOnActivateForm = True;
		Return;
	EndIf;
	
	AttachIdleHandler("UpdateProgressIdleHandler", 0.1, True);
	UpdateAccessUpdateJobStateInThreeSeconds();
	
	Items.ProgressBarRefresh.CurrentPage = Items.RefreshingProgressBar;
	Items.CancelRefreshingProgressBar.Enabled = False;
	Items.RefreshingProgressBarPicture.Visible = True;
	Items.RefreshingProgressBarPendingPicture.Visible = False;
	
	IsProgressUpdatedAfterStartImmediatelyCommand = True;
	
EndProcedure

&AtClient
Procedure StartProgressUpdateIdleHandler()
	
	StartProgressUpdate();
	
EndProcedure

&AtClient
Procedure UpdateProgressIdleHandler()
	
	Context = New Structure;
	Context.Insert("CalculateByDataAmount",  CalculateByDataAmount);
	Context.Insert("ShowProcessedLists",    ShowProcessedLists And CalculateByDataAmount);
	Context.Insert("IsRepeatedProgressUpdate", IsRepeatedProgressUpdate);
	Context.Insert("UpdatedTotal",                  UpdatedTotal);
	Context.Insert("ProgressUpdatePeriod",       ProgressUpdatePeriod);
	Context.Insert("ProgressAutoUpdate",         ProgressAutoUpdate);
	Context.Insert("AddedRows",               New Array);
	Context.Insert("DeletedRows",                 New Map);
	Context.Insert("ModifiedRows",                New Map);
	Context.Insert("AccessUpdateInProgress",    Items.AccessUpdateInProgress.Visible);
	
	Try
		Status = StartProgressUpdateAtServer(Context, ResultAddress, StoredDataAddress,
			UUID, ProgressUpdateJobID);
	Except
		ProgressAutoUpdate = False;
		Items.ProgressBarRefresh.CurrentPage = Items.RefreshingProgressBarCompleted;
		Items.CancelRefreshingProgressBar.Enabled = False;
		StandardSubsystemsClient.OutputErrorInfo(ErrorInfo());
		Return;
	EndTry;
	Items.CancelRefreshingProgressBar.Enabled = True;
	
	If Status = "Completed2" Or Status = "Error" Then
		UpdateProgressAfterReceiveData(Context);
		
	ElsIf Status = "Running" Then
		RefreshingProgressBar = False;
		AttachIdleHandler("CompleteProgressUpdateIdleHandler", 1, True);
		UpdateAccessUpdateJobStateInThreeSeconds();
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteProgressUpdateIdleHandler()
	
	If Not ValueIsFilled(ProgressUpdateJobID) Then
		Return;
	EndIf;
	
	Context = New Structure;
	JobCompleted = EndProgressUpdateAtServer(Context, ResultAddress,
		StoredDataAddress, ProgressUpdateJobID);
	
	If Not JobCompleted Then
		If Context.RefreshingProgressBar Then
			RefreshingProgressBar = True;
		EndIf;
		Items.RefreshingProgressBarPicture.Visible         =    RefreshingProgressBar;
		Items.RefreshingProgressBarPendingPicture.Visible = Not RefreshingProgressBar;
		
		UpdateAccessUpdateJobState(Context.AccessUpdateJobState);
		
		AttachIdleHandler("CompleteProgressUpdateIdleHandler", 1, True);
		Return;
	EndIf;
	
	UpdateProgressAfterReceiveData(Context);
	
EndProcedure

&AtClient
Procedure UpdateProgressAfterReceiveData(Context)
	
	If Context.Property("ErrorInfo") Then
		ProgressAutoUpdate = False;
		CompleteProgressUpdateAtClient(Context);
		If TypeOf(Context.ErrorInfo) = Type("String") Then
			ShowMessageBox(, Context.ErrorInfo);
		Else
			StandardSubsystemsClient.OutputErrorInfo(Context.ErrorInfo);
		EndIf;
		Return;
	EndIf;
	
	UpdatedTotal = Context.UpdatedTotal;
	If Context.Property("ProgressUpdatePeriod") Then
		ProgressUpdatePeriod = Context.ProgressUpdatePeriod;
	EndIf;
	If Context.Property("ProgressAutoUpdate") Then
		ProgressAutoUpdate = Context.ProgressAutoUpdate;
	EndIf;
	
	CurrentMoment = CommonClient.SessionDate();
	UpdateDelay = SortFields[0].Value = "ListProcessingDelay";
	
	IndexOf = Lists.Count() - 1;
	While IndexOf >= 0 Do
		String = Lists.Get(IndexOf);
		If Context.DeletedRows.Get(String.List) <> Undefined Then
			Lists.Delete(IndexOf);
		Else
			ChangedRow = Context.ModifiedRows.Get(String.List);
			If ChangedRow <> Undefined Then
				FillPropertyValues(String, ChangedRow);
			EndIf;
			If UpdateDelay Then
				UpdateListUpdateDelay(String, CurrentMoment);
			EndIf;
		EndIf;
		IndexOf = IndexOf - 1;
	EndDo;
	For Each AddedRow In Context.AddedRows Do
		NewRow = Lists.Add();
		FillPropertyValues(NewRow, AddedRow);
		If UpdateDelay Then
			UpdateListUpdateDelay(NewRow, CurrentMoment);
		EndIf;
	EndDo;
	
	If Context.AddedRows.Count() > 0
	 Or SortingWithGoToBeginning()
	   And Context.ModifiedRows.Count() > 0  Then
		
		SortListByFields();
	EndIf;
	
	CompleteProgressUpdateAtClient(Context);
	
EndProcedure

&AtClient
Procedure CompleteProgressUpdateAtClient(Context)
	
	If ProgressAutoUpdate Then
		AttachIdleHandler("StartProgressUpdateIdleHandler",
			ProgressUpdatePeriod, True);
	EndIf;
	
	Items.ProgressBarRefresh.CurrentPage = Items.RefreshingProgressBarCompleted;
	
	If Not Context.Property("ErrorInfo") Then
		IsRepeatedProgressUpdate = True;
	EndIf;
	
	UpdateAccessUpdateJobState(Context.AccessUpdateJobState);
	
EndProcedure

&AtClient
Procedure UpdateListUpdateDelay(String, CurrentMoment)
	
	Divisor = 5;
	
	If ValueIsFilled(String.LatestUpdate) Then
		String.ListProcessingDelay =
			Int((CurrentMoment - String.LatestUpdate) / Divisor) * Divisor;
		
	ElsIf String.FirstUpdateSchedule < MaxDate Then
		String.ListProcessingDelay =
			Int((CurrentMoment - String.FirstUpdateSchedule) / Divisor) * Divisor;
	Else
		String.ListProcessingDelay = 999999;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function StartProgressUpdateAtServer(Context, ResultAddress, StoredDataAddress,
			FormIdentifier, ProgressUpdateJobID)
	
	If ValueIsFilled(StoredDataAddress) Then
		LaunchOnOpening = False;
		StoredData = GetFromTempStorage(StoredDataAddress);
	Else
		LaunchOnOpening = True;
		StoredData = AccessManagementInternal.NewStorableProgressUpdateData();
		StoredDataAddress = PutToTempStorage(StoredData, FormIdentifier);
	EndIf;
	
	FixedContext = New FixedStructure(Context);
	ProcedureParameters = New Structure(FixedContext);
	
	ResultAddress = PutToTempStorage(Undefined, FormIdentifier);
	ProcedureParameters.Insert("StoredData", StoredData);
	ProcedureParameters.Insert("Version", 1);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormIdentifier);
	ExecutionParameters.WaitCompletion = 0;
	If Not Common.FileInfobase()
	 Or Common.DataSeparationEnabled()
	 Or LaunchOnOpening And Not Context.AccessUpdateInProgress Then
		ExecutionParameters.WithDatabaseExtensions = True;
	Else
		ExecutionParameters.RunNotInBackground1 = True;
	EndIf;
	ExecutionParameters.ResultAddress = ResultAddress;
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Quản lý truy cập: Nhận tiến trình cập nhật truy cập';
			|ru = 'Управление доступом: Получение прогресса обновления доступа';
			|en = 'Access management: Get access update progress'; fa = 'Access management: Get access update progress';
			|it = 'Controllo dell''accesso: ottenere i progressi di aggiornamento dell''accesso';
			|pl = 'Kontrola dostępu: Uzyskiwanie dostępu do postępu aktualizacji';
			|tr = 'Erişim yönetimi: Erişim güncelleme ilerlemesini elde etmek'");
	ExecutionParameters.RefinementErrors =
		NStr("vi = 'Không thể cập nhật tiến trình do nguyên nhân:';
			|ru = 'Не удалось обновить прогресс по причине:';
			|en = 'Couldn''t refresh the progress bar due to:'; fa = 'Couldn''t refresh the progress bar due to:';
			|it = 'Не удалось обновить прогресс по причине:';
			|pl = 'Couldn''t refresh the progress bar due to:';
			|tr = 'Şu nedenle ilerleme güncellenemedi:'");

	RunResult = TimeConsumingOperations.ExecuteInBackground("AccessManagementInternal.UpdateProgressInBackground",
		ProcedureParameters, ExecutionParameters);
	
	ProgressUpdateJobID = Undefined;
	
	If RunResult.Status = "Completed2" Then
		EndProgressUpdateAtServer(Context, ResultAddress,
			StoredDataAddress, Undefined);
		
	ElsIf RunResult.Status = "Running" Then
		ProgressUpdateJobID = RunResult.JobID;
		
	ElsIf RunResult.Status = "Error" Then
		Context.Insert("ErrorInfo", RunResult.ErrorInfo);
		Context.Insert("AccessUpdateJobState", AccessUpdateJobState());
	EndIf;
	
	Return RunResult.Status;
	
EndFunction

&AtServerNoContext
Procedure CancelProgressUpdateAtServer(JobID)
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	JobID = Undefined;
	
EndProcedure

&AtServerNoContext
Function EndProgressUpdateAtServer(Context, Val ResultAddress, Val StoredDataAddress,
			ProgressUpdateJobID)
	
	If ProgressUpdateJobID <> Undefined Then
		Result = TimeConsumingOperations.JobCompleted(ProgressUpdateJobID, True);
		If Result.Status = "Running" Then
			Context = New Structure("AccessUpdateJobState", AccessUpdateJobState());
			Context.Insert("RefreshingProgressBar",
				TimeConsumingOperations.ReadProgress(ProgressUpdateJobID) <> Undefined);
			Return False;
		ElsIf Result.Status <> "Completed2" Then
			ProgressUpdateJobID = Undefined;
			Context = New Structure("AccessUpdateJobState", AccessUpdateJobState());
			Context.Insert("ErrorInfo", Result.ErrorInfo);
			Return True;
		EndIf;
	EndIf;
	ProgressUpdateJobID = Undefined;
	
	Context = GetFromTempStorage(ResultAddress);
	If Not Context.Property("ErrorInfo") Then
		PutToTempStorage(Context.StoredData, StoredDataAddress);
		Context.Delete("StoredData");
	EndIf;
	
	Context.Insert("AccessUpdateJobState", AccessUpdateJobState());
	
	Return True;
	
EndFunction

&AtClient
Procedure UpdateDisplaySettingsVisibility()
	
	DisplaySettings = CalculateByDataAmount;
	
	If Items.ViewSettings.Visible <> DisplaySettings Then
		Items.ViewSettings.Visible = DisplaySettings;
		
		If DisplaySettings Then
			Items.ListsItemCount.Visible                 = ShowItemsCount;
			Items.ListsProcessedItemsCount.Visible     = ShowItemsCount;
			Items.ListsAccessKeysCount.Visible             = ShowAccessKeysCount;
			Items.ListsProcessedAccessKeysCount.Visible = ShowAccessKeysCount;
			Items.ListsTableName.Visible                          = ShowTableName;
		Else
			Items.ListsItemCount.Visible                 = False;
			Items.ListsProcessedItemsCount.Visible     = False;
			Items.ListsAccessKeysCount.Visible             = False;
			Items.ListsProcessedAccessKeysCount.Visible = False;
			Items.ListsTableName.Visible                          = False;
		EndIf;
	EndIf;
	
	Items.ListsListProcessingDelay.Visible = ShowProcessingDelay;
	
EndProcedure

&AtClient
Procedure SortList(Descending = False)
	
	CurrentColumn = Items.Lists.CurrentItem;
	
	If CurrentColumn = Undefined
	 Or Not StrStartsWith(CurrentColumn.Name, "Lists") Then
		
		ShowMessageBox(,
			NStr("vi = 'Hãy chọn cột để sắp xếp';
				|ru = 'Выберите колонку для сортировки';
				|en = 'Please select a column to sort.'; fa = 'Please select a column to sort.';
				|it = 'Selezionare colonna da ordinare';
				|pl = 'Wybierz kolumnę do sortowania';
				|tr = 'Sıralamak için bir sütun seçin'"));
		Return;
	EndIf;
	
	ClearSortingPicture(Items["Lists" + SortFields[0].Value]);
	
	SortFields.Clear();
	
	Field = Mid(CurrentColumn.Name, StrLen("Lists") + 1);
	SortFields.Add(Field, ?(Descending, "Desc", "Asc"));
	If Field <> "ListPresentation" Then
		SortFields.Add("ListPresentation", "Asc");
	EndIf;
	
	SetSortingPicture(CurrentColumn, Descending);
	
	SortListByFields();
	
	ShowUserNotification(
		?(Descending, NStr("vi = 'Sắp xếp giảm dần';
							|ru = 'Сортировка по убыванию';
							|en = 'Sort descending'; fa = 'مرتب‌سازی نزولی';
							|it = 'Smistamento in decrescenza dell''unita';
							|pl = 'Sortuj malejąco';
							|tr = 'Azalan şekilde sıralama'"),
			NStr("vi = 'Sắp xếp tăng dần';
				|ru = 'Сортировка по возрастанию';
				|en = 'Sort ascending'; fa = 'مرتب‌سازی صعودی';
				|it = 'Smistamento in ordine crescente';
				|pl = 'Sortuj rosnąco';
				|tr = 'Artan şekilde sıralama'")),,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Cột ""%1""';
				|ru = 'Колонка ""%1""';
				|en = 'Column:""%1""'; fa = 'Column:""%1""';
				|it = 'Colonna ""%1""';
				|pl = 'Kolumna ""%1""';
				|tr = '""%1"" sütunu'"),
			StrReplace(CurrentColumn.Title, Chars.LF, " ")));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSortingPicture(Item, Descending)
	
	WidthAddition = 3;
	
	If Item.Width > 0 Then
		Item.Width = Item.Width + WidthAddition;
	EndIf;
	Item.HeaderPicture = ?(Descending,
		PictureLib.SortListDesc,
		PictureLib.SortListAsc);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ClearSortingPicture(Item)
	
	WidthAddition = 3;
	
	Item.HeaderPicture = New Picture;
	If Item.Width > WidthAddition Then
		Item.Width = Item.Width - WidthAddition;
	EndIf;
	
EndProcedure

&AtClient
Function SortingWithGoToBeginning()
	
	Return SortFields[0].Value <> "ListPresentation";
	
EndFunction

&AtClient
Procedure SortListByFields(SortFieldIndex = 0, ListRows = Undefined)
	
	If SortFieldIndex >= SortFields.Count() Then
		Return;
	EndIf;
	
	SortField = SortFields[SortFieldIndex].Value;
	If ListRows = Undefined Then
		ListRows = New ValueList;
		If Lists.Count() < 2 Then
			Return;
		EndIf;
		For Each String In Lists Do
			ListRows.Add(String,
				PresentationForSort(String[SortField]));
		EndDo;
	ElsIf ListRows.Count() < 2 Then
		Return;
	Else
		For Each ListItem In ListRows Do
			ListItem.Presentation =
				PresentationForSort(ListItem.Value[SortField]);
		EndDo;
	EndIf;
	
	InitialIndex = Lists.IndexOf(ListRows[0].Value);
	ListRows.SortByPresentation(
		SortDirection[SortFields[SortFieldIndex].Presentation]);
	
	CurrentBusinessUnitPresentation = Undefined;
	Substrings = Undefined;
	NewIndex = InitialIndex;
	For Each ListItem In ListRows Do
		CurrentIndex = Lists.IndexOf(ListItem.Value);
		If CurrentIndex <> NewIndex Then
			Lists.Move(CurrentIndex, NewIndex - CurrentIndex);
		EndIf;
		If CurrentBusinessUnitPresentation <> ListItem.Presentation Then
			If Substrings <> Undefined Then
				SortListByFields(SortFieldIndex + 1, Substrings);
			EndIf;
			Substrings = New ValueList;
			CurrentBusinessUnitPresentation = ListItem.Presentation;
		EndIf;
		Substrings.Add(ListItem.Value);
		NewIndex = NewIndex + 1;
	EndDo;
	
	If Substrings <> Undefined Then
		SortListByFields(SortFieldIndex + 1, Substrings);
	EndIf;
	
	If SortFieldIndex = 0
	   And SortingWithGoToBeginning()
	   And Lists.Count() > 0 Then
		
		Items.Lists.CurrentRow = Lists[0].GetID();
	EndIf;
	
EndProcedure

&AtClient
Function PresentationForSort(Value)
	
	Return Format(Value, "ND=15; NFD=4; NZ=00000000000,0000; NLZ=; NG=");
	
EndFunction

&AtServerNoContext
Procedure EnableAccessUpdateAtServer()
	
	AccessManagementInternal.DenyAccessUpdate(False);
	AccessManagementInternal.SetAccessUpdate(True);
	
EndProcedure

&AtClient
Procedure StopAndProhibitAccessUpdateIdleHandler()
	
	StopAndProhibitAccessUpdateAtServer();
	
	Items.AccessUpdateProhibited.Visible = True;
	Items.ScheduledJobDisabled.Visible = False;
	
	StartProgressUpdate(True);
	
EndProcedure

&AtServerNoContext
Procedure StopAndProhibitAccessUpdateAtServer()
	
	AccessManagementInternal.SetAccessUpdate(False);
	AccessManagementInternal.CancelAccessUpdateAtRecordLevel();
	
EndProcedure

&AtClientAtServerNoContext
Function StringWithFormattedParts(Template, PartsFormat, PartsToFormatCount)
	
	Parts = New Array;
	
	For PartToFormatNumber = 1 To PartsToFormatCount Do
		SeparatorStart = "<"  + PartToFormatNumber + ">";
		SeparatorEnd  = "</" + PartToFormatNumber + ">";
		If StrOccurrenceCount(Template, SeparatorStart) <> 1
		 Or StrOccurrenceCount(Template, SeparatorEnd) <> 1 Then
			Template = StrReplace(Template, SeparatorStart, "");
			Template = StrReplace(Template, SeparatorEnd, "");
			Continue;
		EndIf;
	Position = StrFind(Template, SeparatorStart);
		If Position > 1 Then
			String = Left(Template, Position - 1);
			Parts.Add(StringWithFormattedParts(String, PartsFormat, PartsToFormatCount));
		EndIf;
		Template = Mid(Template, Position + StrLen(SeparatorStart));
		Position = StrFind(Template, SeparatorEnd);
		StringToFormat = Left(Template, Position - 1);
		If PartsFormat.Get(PartToFormatNumber) <> Undefined Then
			FormatParameters = New Structure("Font, TextColor, BackColor, Ref");
			FillPropertyValues(FormatParameters, PartsFormat.Get(PartToFormatNumber));
			StringToFormat = New FormattedString(StringToFormat,
				FormatParameters.Font, FormatParameters.TextColor, FormatParameters.BackColor, FormatParameters.Ref);
		EndIf;
		Parts.Add(StringToFormat);
		Template = Mid(Template, Position + StrLen(SeparatorEnd));
		If Template = "" Then
			Break;
		EndIf;
	EndDo;
	
	If Template <> "" Then
		Parts.Add(Template);
	EndIf;
	
	Return New FormattedString(Parts);
	
EndFunction

#EndRegion

