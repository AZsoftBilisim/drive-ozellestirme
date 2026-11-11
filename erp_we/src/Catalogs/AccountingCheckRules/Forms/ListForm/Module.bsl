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
	
	AccountingCheckRulesSettingAllowed = AccessRight("Update", Metadata.Catalogs.AccountingCheckRules);
	IsFullUser = Users.IsFullUser(, False);
	Items.FormExecuteCheck.Visible = IsFullUser;
	Items.FormExecuteAllChecks.Visible = IsFullUser;
	Items.ListContextMenuExecuteCheck.Visible = AccountingCheckRulesSettingAllowed;
	Items.FormRestoreByInitialFilling.Visible = AccountingCheckRulesSettingAllowed;
	
	IsSystemAdministrator = Users.IsFullUser(, True);
	
	If IsSystemAdministrator Then
		CommonScheduledJob = ScheduledJobsServer.Job(Metadata.ScheduledJobs.AccountingCheck);
		If CommonScheduledJob <> Undefined Then
			If Not Common.DataSeparationEnabled() Then
				CommonSchedulePresentation = String(CommonScheduledJob.Schedule);
				PropertiesOfLastJob = ScheduledJobsServer.PropertiesOfLastJob(CommonScheduledJob);
				If PropertiesOfLastJob <> Undefined Then
					LastCheckDate = PropertiesOfLastJob.End;
				Else
					LastCheckInformation = AccountingAuditInternal.LastAccountingCheckInformation();
					LastCheckDate = LastCheckInformation.LastCheckDate;
				EndIf;
				
				If LastCheckDate = Undefined Then
					ToolTipText = NStr("vi = 'Không có thông tin về lần kiểm tra gần nhất.';
										|ru = 'Нет информации о последнем запуске проверки.';
										|en = 'No information on the last check start.'; fa = 'No information on the last check start.';
										|it = 'No information on the last check start.';
										|pl = 'No information on the last check start.';
										|tr = 'Kontrolün son çalıştırılmasına dair bilgi bulunmamaktadır.'");
				Else
					ToolTipText = NStr("vi = 'Lần kiểm tra gần nhất đã kết thúc %1 trong %2';
										|ru = 'Последняя проверка закончилась %1 в %2';
										|en = 'The last check was completed on %1 at %2'; fa = 'The last check was completed on %1 at %2';
										|it = 'The last check was completed on %1 at %2';
										|pl = 'The last check was completed on %1 at %2';
										|tr = 'Son kontrol %1/%2 tamamlandı'");
					ToolTipText = StringFunctionsClientServer.SubstituteParametersToString(ToolTipText,
						Format(LastCheckDate, "DLF=D"), Format(LastCheckDate, "DLF=T"));
				EndIf;
				Items.PresentationOfCommonSchedule.ToolTip = ToolTipText;
			Else
				If IsSystemAdministrator Then
					CommonSchedulePresentation = String(Common.ObjectAttributeValue(CommonScheduledJob.Template, "Schedule").Get());
					Items.ScheduledJobPresentation.Visible = True;
				Else
					Items.ScheduledJobPresentation.Visible = False;
					Items.PresentationOfCommonSchedule.Visible    = False;
					CommonSchedulePresentation                        = "";
				EndIf;
			EndIf;
		Else
			If (Common.DataSeparationEnabled() And IsSystemAdministrator) Or Not Common.DataSeparationEnabled() Then
				CommonSchedulePresentation = NStr("vi = 'Nhiệm vụ thường kỳ không khả dụng';
													|ru = 'Регламентное задание не доступно';
													|en = 'The scheduled job is not available'; fa = 'The scheduled job is not available';
													|it = 'Compito pianificato non disponibile';
													|pl = 'Zadanie reglamentowane jest niedostępne';
													|tr = 'Zamanlanmış görev kullanılamıyor'");
			Else
				CommonSchedulePresentation                     = "";
				Items.PresentationOfCommonSchedule.Visible = False;
			EndIf;
		EndIf;
		
		List.SettingsComposer.Settings.AdditionalProperties.Insert("PresentationOfCommonSchedule", CommonSchedulePresentation);
		
		Items.PresentationOfCommonSchedule.Title = GenerateRowWithSchedule();
	Else
		Items.PresentationOfCommonSchedule.Visible    = False;
		Items.ScheduledJobPresentation.Visible = False;
	EndIf;
	
	Items.PresentationOfCommonSchedule.Enabled = InfobaseUpdate.ObjectProcessed(
		Metadata.Catalogs.AccountingCheckRules.FullName()).Processed;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	ComposerAdditionalProperties = Settings.AdditionalProperties;
	If Not ComposerAdditionalProperties.Property("PresentationOfCommonSchedule") Then
		Return;
	EndIf;
	
	RowsKeys = Rows.GetKeys();
	For Each RowKey In RowsKeys Do
		RowData = Rows[RowKey].Data;
		If RowData.IsFolder Then
			Continue;
		EndIf;
		If RowData.RunMethod = Enums.CheckMethod.Manually Then
			RowData.ScheduledJobPresentation = NStr("vi = 'Thủ công';
													|ru = 'Вручную';
													|en = 'Manually'; fa = 'دستی';
													|it = 'Manualmente';
													|pl = 'Manually';
													|tr = 'Manuel'");
		ElsIf RowData.RunMethod = Enums.CheckMethod.ByCommonSchedule Then
			RowData.ScheduledJobPresentation = NStr("vi = 'Theo lịch biểu chung';
													|ru = 'По общему расписанию';
													|en = 'On general schedule'; fa = 'On general schedule';
													|it = 'Secondo il piano di lavoro generale';
													|pl = 'Według ogólnego rozkładu';
													|tr = 'Ortak programa göre'")
		ElsIf RowData.RunMethod = Enums.CheckMethod.OnSeparateSchedule Then
			JobID = RowData.ScheduledJobID;
			If Not ValueIsFilled(JobID) Then
				RowData.ScheduledJobPresentation = NStr("vi = 'Chưa xác định lịch biểu';
														|ru = 'Расписание не задано';
														|en = 'No schedule'; fa = 'No schedule';
														|it = 'Orario non è impostato';
														|pl = 'Harmonogram nie jest zadany';
														|tr = 'Plan ayarlanmadı'");
			Else
				FoundScheduledJob = ScheduledJobsServer.Job(New UUID(JobID));
				If FoundScheduledJob <> Undefined Then
					ScheduleAsString = String(FoundScheduledJob.Schedule);
				Else
					
					Block = New DataLock;
					LockItem = Block.Add("Catalog.AccountingCheckRules");
					LockItem.SetValue("Ref", RowKey);
					BeginTransaction();
					Try
						Block.Lock();
						RuleObject = RowKey.GetObject();
						
						Parameters = New Structure;
						Parameters.Insert("Use", True);
						Parameters.Insert("Metadata",    Metadata.ScheduledJobs.AccountingCheck);
						Parameters.Insert("Schedule",    CommonClientServer.StructureToSchedule(
							RuleObject.CheckRunSchedule.Get()));
						
						RestoredJob = ScheduledJobsServer.AddJob(Parameters);
						
						JobParameters = New Structure;
						ParametersArray = New Array;
						ParametersArray.Add(String(RestoredJob.UUID));
						JobParameters.Insert("Parameters", ParametersArray);
						
						ScheduledJobsServer.ChangeJob(RestoredJob.UUID, JobParameters);
						
						RuleObject.ScheduledJobID = String(RestoredJob.UUID);
						InfobaseUpdate.WriteData(RuleObject);
						
						ScheduleAsString = String(RestoredJob.Schedule);
						CommitTransaction();
					Except
						RollbackTransaction();
						Raise;
					EndTry;
					
				EndIf;
				RowData.ScheduledJobPresentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Theo lịch biểu: ""%1""';
						|ru = 'По расписанию: ""%1""';
						|en = 'On schedule: ""%1""'; fa = 'On schedule: ""%1""';
						|it = 'Secondo programmazione: ""%1""';
						|pl = 'Zgodnie z harmonogramem: ""%1""';
						|tr = 'Programa göre: ""%1""'"), ScheduleAsString);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteCheck(Command)
	
	HasGroups = False;
	Checks = ChecksSelected(HasGroups);
	If Checks.Count() = 0 Then
		Raise NStr("vi = 'Hãy chọn một hoặc nhiều kiểm tra trong danh sách.';
					|ru = 'Выберите в списке одну или несколько проверок.';
					|en = 'Select one or several checks in the list.'; fa = 'Select one or several checks in the list.';
					|it = 'Selezionare nell''elenco una o più verifiche.';
					|pl = 'Wybierz na liście jedno lub kilka sprawdzeń.';
					|tr = 'Listede bir veya birden fazla kontrol seçin.'");
	EndIf;
		
	If HasGroups Then
		Checks = AllSelectedChecks(Checks);
	EndIf;

	If Checks.Count() > 1 Then
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thực hiện các kiểm tra đã chọn (%1)?
				|Điều này có thể mất nhiều thời gian.';
				|ru = 'Выполнить выбранные проверки (%1)?
				|Это может занять некоторое время.';
				|en = 'Run the selected checks (%1)?
				|This might take a while.'; fa = 'Run the selected checks (%1)?
				|This might take a while.';
				|it = 'Eseguire le verifiche selezionate (%1)?
				|Questo potrebbe richiedere alcuni minuti.';
				|pl = 'Wykonaj wybrane sprawdzenia (%1)?
				|To może zająć trochę czasu.';
				|tr = 'Seçilen kontroller (%1) yapılsın mı?
				|İşlem biraz zaman alabilir.'"),
			Checks.Count());
	Else
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thực hiện kiểm tra đã chọn (%1)?
				|Việc này có thể mất nhiều thời gian.';
				|ru = 'Выполнить выбранную проверку ""%1""?
				|Это может занять некоторое время.';
				|en = 'Run selected check ""%1""?
				|This might take a while.'; fa = 'Run selected check ""%1""?
				|This might take a while.';
				|it = 'Eseguire la verifica selezionata ""%1""?
				|Questo potrebbe richiedere alcuni minuti.';
				|pl = 'Wykonaj wybrane sprawdzenie (%1)?
				|To może zająć trochę czasu.';
				|tr = 'Seçilen ""%1"" kontrolü yapılsın mı?
				|İşlem biraz zaman alabilir.'"),
			Checks[0]);
	EndIf;
	ShowQueryBox(New CallbackDescription("ExecuteCheckContinued", ThisObject, Checks),
		QueryText, QuestionDialogMode.YesNo);
	
EndProcedure
	
&AtClient
Procedure ExecuteAllChecks(Command)
	Checks = AllSelectedChecks();
	If Checks.Count() = 0 Then
		Raise NStr("vi = 'Hãy chọn một hoặc nhiều kiểm tra trong danh sách.';
					|ru = 'Выберите в списке одну или несколько проверок.';
					|en = 'Select one or several checks in the list.'; fa = 'Select one or several checks in the list.';
					|it = 'Selezionare nell''elenco una o più verifiche.';
					|pl = 'Wybierz na liście jedno lub kilka sprawdzeń.';
					|tr = 'Listede bir veya birden fazla kontrol seçin.'");
	EndIf;
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thực hiện tất cả kiểm tra (%1)?
			|Điều này có thể mất nhiều thời gian.';
			|ru = 'Выполнить все проверки (%1)?
			|Это может занять некоторое время.';
			|en = 'Run all checks (%1)?
			|This might take a while.'; fa = 'Run all checks (%1)?
			|This might take a while.';
			|it = 'Eseguire tutte le verifiche (%1)?
			|Questo potrebbe richiedere alcuni minuti.';
			|pl = 'Wykonaj wszystkie sprawdzenia (%1)?
			|To może zająć trochę czasu.';
			|tr = 'Tüm kontroller (%1) yapılsın mı?
			|İşlem biraz zaman alabilir.'"),
		Checks.Count());
	ShowQueryBox(New CallbackDescription("ExecuteCheckContinued", ThisObject, Checks),
		QueryText, QuestionDialogMode.YesNo);
		
EndProcedure
	
&AtClient
Procedure RestoreByInitialFilling(Command)
	RestoreByInitialFillingAtServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	
	// Do not display if the issue reason is not described.
	
	Item = List.ConditionalAppearance.Items.Add();
	
	FormattedField = Item.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(Items.Reasons.Name);
	FormattedField.Use = True;
	
	DataFilterItem = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Reasons");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = Item.Appearance.Items.Find("Visible");
	AppearanceColorItem.Value = False;   
	AppearanceColorItem.Use = True;
	
EndProcedure

&AtServer
Function ExecuteChecksAtServer(Checks)
	
	FormIdentifier = New UUID;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(FormIdentifier);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Thực hiện kiểm tra tiến hành kế toán';
														|ru = 'Выполнение проверок ведения учета';
														|en = 'Run data integrity checks'; fa = 'Run data integrity checks';
														|it = 'Esecuzione delle verifiche di contabilità';
														|pl = 'Wykonanie sprawdzeń prowadzenia ewidencji';
														|tr = 'Muhasebe kontrolü yap'");
	
	MethodParameters        = New Map;
	CheckUpperBoundary = Checks.UBound();
	
	For IndexOfCheck = 0 To CheckUpperBoundary Do
		ParametersArray = New Array;
		ParametersArray.Add(Checks[IndexOfCheck]);
		
		MethodParameters.Insert(IndexOfCheck, ParametersArray);
	EndDo;
	
	Return TimeConsumingOperations.ExecuteProcedureinMultipleThreads(
		"AccountingAuditInternal.ExecuteCheck",
		ExecutionParameters,
		MethodParameters);
	
EndFunction

&AtClient
Procedure ExecuteCheckContinued(QuestionResult, Checks) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	TimeConsumingOperation = ExecuteChecksAtServer(Checks);
	
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
		Notify("AccountingAuditSuccessfulCheck");
		ShowUserNotification(NStr("vi = 'Đã thực hiện kiểm tra';
									|ru = 'Проверка выполнена';
									|en = 'Scan completed'; fa = 'Scan completed';
									|it = 'Verifica effettuata';
									|pl = 'Weryfikacja wykonana';
									|tr = 'Kontrol tamamlandı'"),
			"e1cib/data/Report.AccountingCheckResults",
			NStr("vi = 'Đã hoàn tất thành công kiểm tra quản lý kế toán.';
				|ru = 'Проверка ведения учета завершена успешно.';
				|en = 'Data integrity check completed successfully.'; fa = 'Data integrity check completed successfully.';
				|it = 'Verifica di contabilità eseguita con successo.';
				|pl = 'Sprawdzenie prowadzenia ewidencji zostało zakończone pomyślnie.';
				|tr = 'Muhasebe kontrolü başarıyla tamamlandı.'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure RestoreByInitialFillingAtServer()
	
	AccountingAudit.UpdateAccountingChecksParameters();
	
EndProcedure

&AtClient
Function ChecksSelected(HasGroups)
	
	Result = New Array;
	For Each Validation In Items.List.SelectedRows Do
		CheckData = Items.List.RowData(Validation);
		If CheckData <> Undefined Then
			Result.Add(CheckData.Ref);
			If CheckData.IsFolder Then
				HasGroups = True;
			EndIf;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

&AtServerNoContext
Function AllSelectedChecks(Checks = Undefined)
	
	If Checks = Undefined Then
		Query = New Query(
			"SELECT ALLOWED
			|	AccountingCheckRules.Ref AS Ref
			|FROM
			|	Catalog.AccountingCheckRules AS AccountingCheckRules
			|WHERE
			|	NOT AccountingCheckRules.IsFolder");
	Else	
		Query = New Query(
			"SELECT ALLOWED
			|	AccountingCheckRules.Ref AS Ref
			|FROM
			|	Catalog.AccountingCheckRules AS AccountingCheckRules
			|WHERE
			|	AccountingCheckRules.Ref IN HIERARCHY(&Checks)
			|	AND NOT AccountingCheckRules.IsFolder");
		
		Query.SetParameter("Checks", Checks);
	EndIf;	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

&AtServer
Function GenerateRowWithSchedule()
	
	CommonScheduledJob = ScheduledJobsServer.Job(Metadata.ScheduledJobs.AccountingCheck);
	If CommonScheduledJob <> Undefined Then
		If Not Common.DataSeparationEnabled() Then
			CommonSchedule              = CommonScheduledJob.Schedule;
			CommonSchedulePresentation = String(CommonScheduledJob.Schedule);
		Else
			If Users.IsFullUser(, True) Then
				CommonSchedule              = Common.ObjectAttributeValue(CommonScheduledJob.Template, "Schedule").Get();
				CommonSchedulePresentation = String(CommonSchedule);
			Else
				CommonSchedule = Undefined;
				CommonSchedulePresentation = NStr("vi = 'Không được phép xem lịch biểu';
													|ru = 'Просмотр расписания недоступен';
													|en = 'Viewing schedule is unavailable'; fa = 'Viewing schedule is unavailable';
													|it = 'Visualizzazione della programmazione non disponibile';
													|pl = 'Przegląd harmonogramu jest niedostępny';
													|tr = 'Program görüntülenemiyor'");
			EndIf;
		EndIf;
	Else
		CommonSchedule              = Undefined;
		CommonSchedulePresentation = NStr("vi = 'Không sử dụng được nhiệm vụ thường kỳ';
											|ru = 'Регламентное задание недоступно';
											|en = 'The scheduled job is not available'; fa = 'The scheduled job is not available';
											|it = 'Compito pianificato non disponibile';
											|pl = 'Zadanie reglamentowane jest niedostępne';
											|tr = 'Zamanlanmış görev kullanılamıyor'");
	EndIf;
	
	If Not Common.DataSeparationEnabled() Then
		
		TextRef = PutToTempStorage(CommonSchedule, UUID);
	
		Return New FormattedString(NStr("vi = 'Lịch biểu chung thực hiện kiểm tra:';
										|ru = 'Общее расписание выполнения проверок:';
										|en = 'General check schedule:'; fa = 'General check schedule:';
										|it = 'Programmazione comune di esecuzione delle verifiche:';
										|pl = 'Wspólny harmonogram wykonania sprawdzeń:';
										|tr = 'Paylaşımlı kontrol programı:'") + " ",
			New FormattedString(CommonSchedulePresentation, , , , TextRef));
			
	Else
			
		Return New FormattedString(NStr("vi = 'Lịch biểu chung thực hiện kiểm tra:';
										|ru = 'Общее расписание выполнения проверок:';
										|en = 'General check schedule:'; fa = 'General check schedule:';
										|it = 'Programmazione comune di esecuzione delle verifiche:';
										|pl = 'Wspólny harmonogram wykonania sprawdzeń:';
										|tr = 'Paylaşımlı kontrol programı:'") + " ",
			New FormattedString(CommonSchedulePresentation, , StyleColors.HyperlinkColor));
			
	EndIf;
	
EndFunction

&AtClient
Procedure PresentationOfCommonScheduleURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	Dialog     = New ScheduledJobDialog(GetFromTempStorage(FormattedStringURL));
	Notification = New CallbackDescription("PresentationOfCommonScheduleClickAtClientCompletion", ThisObject);
	Dialog.Show(Notification);
	
EndProcedure

&AtClient
Procedure PresentationOfCommonScheduleClickAtClientCompletion(Schedule, AdditionalParameters) Export
	PresentationOfCommonScheduleClickAtServerCompletion(Schedule, AdditionalParameters);
EndProcedure

&AtServer
Procedure PresentationOfCommonScheduleClickAtServerCompletion(Schedule, AdditionalParameters)
	
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	CommonJobID = ScheduledJobsServer.UUID(Metadata.ScheduledJobs.AccountingCheck);
	ScheduledJobsServer.ChangeJob(CommonJobID, New Structure("Schedule", Schedule));
	
	Items.PresentationOfCommonSchedule.Title = GenerateRowWithSchedule();
	
	List.SettingsComposer.Settings.AdditionalProperties.Insert("PresentationOfCommonSchedule", String(Schedule));
	Items.List.Refresh();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
