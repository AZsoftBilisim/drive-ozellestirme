///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region InterfaceImplementation

// OnlineUserSupport.GetApplicationUpdates

// Opens a form with the list of deferred update
// handlers to the current version.
//
Procedure ShowDeferredHandlers() Export
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.DeferredHandlers");
EndProcedure

// End OnlineUserSupport.GetApplicationUpdates

#EndRegion

#EndRegion

#Region Internal

Procedure ShowUpdateResults() Export
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.ApplicationUpdateResult");
EndProcedure

#Region ConfigurationSubsystemsEventHandlers

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart(Parameters) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If Not CommonClient.DataSeparationEnabled()
	 Or Not CommonClient.SeparatedDataUsageAvailable() Then
		InfobaseUpdateClientOverridable.OnDetermineUpdateAvailability(ClientParameters.MainConfigurationDataVersion);
	EndIf;
	
	If ClientParameters.Property("InfobaseLockedForUpdate") Then
		Buttons = New ValueList();
		Buttons.Add("Restart", NStr("vi = 'Khởi động lại';
									|ru = 'Перезапустить';
									|en = 'Restart'; fa = 'راه‌اندازی مجدد';
									|it = 'Riavviare';
									|pl = 'Restart';
									|tr = 'Yeniden başlat'"));
		Buttons.Add("ExitApp",     NStr("vi = 'Kết thúc công việc';
										|ru = 'Завершить работу';
										|en = 'Exit'; fa = 'خروج';
										|it = 'La sessione è stata completata ';
										|pl = 'Zakończ pracę';
										|tr = 'Sonuçlandır'"));
		
		QuestionParameters = New Structure;
		QuestionParameters.Insert("DefaultButton", "Restart");
		QuestionParameters.Insert("TimeoutButton",    "Restart");
		QuestionParameters.Insert("Timeout",           60);
		
		WarningDetails = New Structure;
		WarningDetails.Insert("Buttons",           Buttons);
		WarningDetails.Insert("QuestionParameters", QuestionParameters);
		WarningDetails.Insert("WarningText",
			ClientParameters.InfobaseLockedForUpdate);
		
		Parameters.Cancel = True;
		Parameters.InteractiveHandler = New CallbackDescription(
			"ShowMessageBoxAndContinue",
			StandardSubsystemsClient,
			WarningDetails);
	EndIf;
	
EndProcedure

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart2(Parameters) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParameters.Property("MustRunDeferredUpdateHandlers") Then
		Parameters.InteractiveHandler = New CallbackDescription(
			"DeferredUpdateStatusCheckInteractiveHandler",
			ThisObject);
	EndIf;
	
EndProcedure

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart3(Parameters) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParameters.Property("ApplicationParametersUpdateRequired") Then
		Parameters.InteractiveHandler = New CallbackDescription(
			"ImportUpdateApplicationParameters", InfobaseUpdateClient);
	EndIf;
	
EndProcedure

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart4(Parameters) Export
	
	If Not CommonClient.SeparatedDataUsageAvailable() Then
		CloseUpdateProgressIndicationFormIfOpen(Parameters);
		Return;
	EndIf;
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientRunParameters.Property("InfobaseUpdateRequired") Then
		If ClientRunParameters.Property("SimplifiedInfobaseUpdateForm") Then
			Parameters.InteractiveHandler = New CallbackDescription(
				"InitiateAreaUpdate", ThisObject);
		Else
			Parameters.InteractiveHandler = New CallbackDescription(
				"StartInfobaseUpdate1", ThisObject);
		EndIf;
	Else
		If ClientRunParameters.Property("LoadDataExchangeMessage") Then
			Restart = False;
			InfobaseUpdateInternalServerCall.UpdateInfobase(True, Restart);
			If Restart Then
				Parameters.Cancel = True;
				Parameters.Restart = True;
			EndIf;
		EndIf;
		CloseUpdateProgressIndicationFormIfOpen(Parameters);
	EndIf;
	
EndProcedure

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart5(Parameters) Export
	
	If CommonClient.FileInfobase()
	   And StrFind(LaunchParameter, "UpdateAndExit") > 0 Then
		
		Terminate();
		
	EndIf;
	
EndProcedure

// See CommonClientOverridable.OnStart.
Procedure OnStart(Parameters) Export
	
	If Not CommonClient.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ShowChangeHistory1();
	
EndProcedure

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientParameters.Property("ShowInvalidHandlersMessage")
		Or ClientParameters.Property("ShowUncompletedHandlersNotification") Then
		AttachIdleHandler("CheckDeferredUpdateStatus", 2, True);
	EndIf;
	
EndProcedure

// Parameters:
//   ReportForm - ClientApplicationForm:
//    * ReportSpreadsheetDocument - SpreadsheetDocument
//   Command - FormCommand
//   Result - Boolean
// 
Procedure OnProcessCommand(ReportForm, Command, Result) Export
	
	If ReportForm.ReportSettings.FullName = "Report.DeferredUpdateProgress" Then
		Details = ReportForm.ReportSpreadsheetDocument.CurrentArea.Details;
		Cache = ReportForm.Report.SettingsComposer.Settings.DataParameters.Items.Find("Cache");
		CachePriorities = ReportForm.Report.SettingsComposer.Settings.DataParameters.Items.Find("CachePriorities");
		DetailsValue = InfobaseUpdateInternalServerCall.ReportDetailsData(
			ReportForm.ReportDetailsData,
			Details,
			Cache.Value,
			CachePriorities.Value);
		
		If DetailsValue = Undefined Then
			Return;
		EndIf;
		
		If Command.Name = "ProgressDelayUpdateDependencies"
			And DetailsValue.FieldName = "HandlerUpdates" Then
			OpenForm("Report.DeferredUpdateProgress.Form.HandlerDependency", DetailsValue);
		ElsIf Command.Name = "ProgressDeferredUpdateErrors" Then
			LogFilter = New Structure;
			LogFilter.Insert("Level", "Error");
			LogFilter.Insert("EventLogEvent", NStr("vi = 'Cập nhật cơ sở thông tin';
													|ru = 'Обновление информационной базы';
													|en = 'Infobase update'; fa = 'به‌روزرسانی پایگاه اطلاعات';
													|it = 'Aggiornamento del database';
													|pl = 'Aktualizacja bazy informacyjnej';
													|tr = 'Infobase güncellemesi'", CommonClient.DefaultLanguageCode()));
			LogFilter.Insert("StartDate", DetailsValue.StartUpdates);
			EventLogClient.OpenEventLog(LogFilter);
		EndIf;
		
	EndIf;
	
EndProcedure

// Handles mouse double-click, "Enter" key, and hyperlink activation in report spreadsheets.
// See "Form field extension for a spreadsheet document field.Choice" in Syntax Assistant.
//
// Parameters:
//   ReportForm          - ClientApplicationForm - Report form.
//   Item              - FormField        - Spreadsheet document.
//   Area              - SpreadsheetDocumentRange - Selected value.
//   StandardProcessing - Boolean - indicates whether standard event processing is executed.
//
Procedure OnProcessSpreadsheetDocumentSelection(ReportForm, Item, Area, StandardProcessing) Export
	
	If ReportForm.ReportSettings.FullName <> "Report.DeferredUpdateProgress" Then
		Return;
	EndIf;
	
	Details = Area.Details;
	
	Details = ReportForm.ReportSpreadsheetDocument.CurrentArea.Details;
	DetailsValue = InfobaseUpdateInternalServerCall.ReportDetailsData(
		ReportForm.ReportDetailsData,
		Details);
		
	If DetailsValue <> Undefined Then
		If DetailsValue.FieldName = "HasErrors" Then
			Value = DetailsValue.Value;
			If Value.Count() <> 3 Then
				Return;
			EndIf;
			
			HasErrors = Value[1];
			If HasErrors = True Then
				StandardProcessing = False;
				LogFilter = New Structure;
				LogFilter.Insert("Level", "Error");
				LogFilter.Insert("EventLogEvent", NStr("vi = 'Cập nhật cơ sở thông tin';
														|ru = 'Обновление информационной базы';
														|en = 'Infobase update'; fa = 'به‌روزرسانی پایگاه اطلاعات';
														|it = 'Aggiornamento del database';
														|pl = 'Aktualizacja bazy informacyjnej';
														|tr = 'Infobase güncellemesi'", CommonClient.DefaultLanguageCode()));
				LogFilter.Insert("StartDate", DetailsValue.StartUpdates);
				EventLogClient.OpenEventLog(LogFilter);
			EndIf;
		ElsIf DetailsValue.FieldName = "ProblemInData" Then
			Value = DetailsValue.Value;
			If Value.Count() <> 3 Then
				Return;
			EndIf;
			
			HasErrors = Value[2];
			If HasErrors = True Then
				StandardProcessing = False;
				If CommonClient.SubsystemExists("StandardSubsystems.AccountingAudit") Then
					ModuleAccountingAuditClient = CommonClient.CommonModule("AccountingAuditClient");
					ModuleAccountingAuditClient.OpenIssuesReport("IBVersionUpdate", False);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure UnlockObjectToEdit(ObjectsArray, AdditionalParameters) Export
	
	QueryText = NStr("vi = 'Dữ liệu đối tượng đã bị phong tỏa, bởi vì chưa hoàn thành việc chuyển sang phiên bản mới của ứng dụng.
		|Chỉ nên áp dụng bỏ phong tỏa trong một số trường hợp, bởi vì dữ liệu sẽ được ghi lại không chính xác.
		|
		|Bỏ phong tỏa để chỉnh sửa?';
		|ru = 'Данные объекта заблокированы, т.к. не завершен переход на новую версию приложения.
		|Разблокировку рекомендуется применять только в крайних случаях, т.к. данные могут быть записаны некорректно.
		|
		|Разблокировать для редактирования?';
		|en = 'Object data is locked because the application is not updated.
		|Unlock data for editing responsibly, as it might corrupt the document.
		|
		|Unlock the data for editing?'; fa = 'Object data is locked because the application is not updated.
		|Unlock data for editing responsibly, as it might corrupt the document.
		|
		|Unlock the data for editing?';
		|it = 'Данные объекта заблокированы, т.к. не завершен переход на новую версию приложения.
		|Разблокировку рекомендуется применять только в крайних случаях, т.к. данные могут быть записаны некорректно.
		|
		|Разблокировать для редактирования?';
		|pl = 'Object data is locked because the application is not updated.
		|Unlock data for editing responsibly, as it might corrupt the document.
		|
		|Unlock the data for editing?';
		|tr = 'Uygulamanın yeni sürümüne geçildiğinden nesne verileri kilitlendi.
		|Veriler doğru yazılmayabileceğinden, kilit açmanın yalnızca acil durumlarda kullanılması önerilir.
		|
		|Düzenleme için kilit açılsın mı?'");
	Parameters = New Structure;
	Parameters.Insert("ObjectsArray", ObjectsArray);
	Parameters.Insert("Form", Undefined);
	If AdditionalParameters.Property("Form") Then
		Parameters.Form = AdditionalParameters.Form;
	EndIf;
	CallbackDescription = New CallbackDescription("UnlockObjectToEditAfterQuestion", ThisObject, Parameters);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

Procedure UnlockObjectToEditAfterQuestion(Result, Parameters) Export
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	InfobaseUpdateInternalServerCall.UnlockObjectToEdit(Parameters.ObjectsArray);
	
	If Parameters.Form <> Undefined Then
		Parameters.Form.ReadOnly = False;
		Parameters.Form.Read();
		ClearMessages();
	Else
		MessageText = NStr("vi = 'Dữ liệu đã phong tỏa. Để chỉnh sửa, cần mở lại thẻ đối tượng.';
							|ru = 'Данные разблокированы. Для редактирования необходимо переоткрыть карточку объекта.';
							|en = 'Data is unlocked. To start editing, reopen the object form.'; fa = 'Data is unlocked. To start editing, reopen the object form.';
							|it = 'I dati sono sono stati sbloccati. Per modificare è necessario riaprire il cartellino dell''oggetto.';
							|pl = 'Dane zostały odblokowane. Do edycji należy ponownie otworzyć kartę obiektu.';
							|tr = 'Verilerin kilidi açıldı. Düzenleme için nesne kartı yeniden açılmalı.'");
		ShowMessageBox(, MessageText);
	EndIf;
	
EndProcedure

// This method is required by UpdateInfobase procedure.
Procedure CloseUpdateProgressIndicationFormIfOpen(Parameters)
	
	ParameterName = "StandardSubsystems.IBVersionUpdate.IBUpdateProgressIndicatorForm";
	Form = ApplicationParameters.Get(ParameterName);
	If Form = Undefined Then
		Return;
	EndIf;
	If Form.IsOpen() Then
		Form.BeginClose();
	EndIf;
	ApplicationParameters.Delete(ParameterName);
	
EndProcedure

// For internal use only. Continues the execution of InfobaseUpdate procedure.
Procedure StartInfobaseUpdate1(Parameters, ContinuationHandler) Export
	
	ParameterName = "StandardSubsystems.IBVersionUpdate.IBUpdateProgressIndicatorForm";
	Form = ApplicationParameters.Get(ParameterName);
	
	If Form = Undefined Then
		FormName = "DataProcessor.ApplicationUpdateResult.Form.ApplicationVersionUpdate";
		Form = OpenForm(FormName,,,,,, New CallbackDescription(
			"AfterCloseIBUpdateProgressIndicatorForm", ThisObject, Parameters));
		ApplicationParameters.Insert(ParameterName, Form);
	EndIf;
	
	Form.UpdateInfobase1();
	
EndProcedure

// For internal use only. Continues the execution of BeforeApplicationStart procedure.
Procedure ImportUpdateApplicationParameters(Parameters, Context) Export
	
	FormName = "DataProcessor.ApplicationUpdateResult.Form.ApplicationVersionUpdate";
	Form = OpenForm(FormName,,,,,, New CallbackDescription(
		"AfterCloseIBUpdateProgressIndicatorForm", ThisObject, Parameters));
	ApplicationParameters.Insert("StandardSubsystems.IBVersionUpdate.IBUpdateProgressIndicatorForm", Form);
	Form.ImportUpdateApplicationParameters(Parameters);
	
EndProcedure

// For internal use only. Continues the execution of InfobaseUpdate procedure.
Procedure AfterCloseIBUpdateProgressIndicatorForm(Result, Parameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Result = New Structure("Cancel, Restart", True, False);
	EndIf;
	
	If Result.Cancel Then
		Parameters.Cancel = True;
		If Result.Restart Then
			Parameters.Restart = True;
		EndIf;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continue the CheckDeferredUpdateHandlersStatus procedure.
Procedure DeferredUpdateStatusCheckInteractiveHandler(Parameters, Context) Export
	
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.DeferredUpdateNotCompleted", , , , , ,
		New CallbackDescription("AfterDeferredUpdateStatusCheckFormClose",
			ThisObject, Parameters));
	
EndProcedure

// For internal use only. Continue the CheckDeferredUpdateHandlersStatus procedure.
Procedure AfterDeferredUpdateStatusCheckFormClose(Result, Parameters) Export
	
	If Result <> True Then
		Parameters.Cancel = True;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// If there is hidden description of changes and settings allow a user
// to view such information, open the ApplicationReleaseNotes form.
//
Procedure ShowChangeHistory1()
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientRunParameters.ShowChangeHistory1 Then
		
		FormParameters = New Structure("ShowOnlyChanges");
		FormParameters.ShowOnlyChanges = True;
		
		OpenForm("CommonForm.ApplicationReleaseNotes", FormParameters);
	EndIf;
	
EndProcedure

// Notifies the user that the deferred data processing
// is not executed.
//
Procedure NotifyDeferredHandlersNotExecuted() Export
	
	If UsersClient.IsExternalUserSession() Then
		Return;
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Đã hạn chế làm việc tạm thời trong ứng dụng';
								|ru = 'Работа в приложении временно ограничена';
								|en = 'The application functionality is temporarily limited.'; fa = 'The application functionality is temporarily limited.';
								|it = 'Работа в приложении временно ограничена';
								|pl = 'The application functionality is temporarily limited.';
								|tr = 'Uygulama işlevselliği geçici olarak kısıtlandı.'"),
		DataProcessorURL(),
		NStr("vi = 'Chưa kết thúc việc chuyển đổi sang phiên bản mới';
			|ru = 'Не завершен переход на новую версию';
			|en = 'Upgrade to the new version is still in progress.'; fa = 'Upgrade to the new version is still in progress.';
			|it = 'Non è stata completata la migrazione alla nuova versione';
			|pl = 'Nie jest zakończone przejście do nowej wersji';
			|tr = 'Yeni sürüme güncelleme tamamlanmamış'"),
		PictureLib.DialogExclamation);
	
EndProcedure

// Returns the URL of InfobaseUpdate data processor
//
Function DataProcessorURL()
	Return "e1cib/app/DataProcessor.ApplicationUpdateResult";
EndFunction

// For internal use only. Continues the execution of BeforeStart procedure.
Procedure InitiateAreaUpdate(Parameters, WarningDetails) Export
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.MessageToLimitedAccessUser");
EndProcedure

Procedure ProcessManualPatchCheckResult(Result, CallbackDescription) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Error Then
		ShowMessageBox(, Result.BriefErrorDetails);
		Return;
	EndIf;
	
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.PromptDontAskAgain = False;
	QuestionParameters.Title = NStr("vi = 'Kiểm tra có bản sửa lỗi hay không';
									|ru = 'Проверка наличия исправлений';
									|en = 'Check for patches'; fa = 'بررسی وصله‌ها';
									|it = 'Verifica presenza correzioni';
									|pl = 'Sprawdzenie istnienia korekt';
									|tr = 'Düzeltmeleri kontrol etme'");
	QuestionParameters.Picture = PictureLib.Information;
	
	If Result.NumberOfCorrections = 0 Then
		Message = NStr("vi = 'Không tìm thấy bản sửa lỗi (vá lỗi) hợp lệ.';
						|ru = 'Доступных исправлений (патчей) не найдено.';
						|en = 'No applicable patches found.'; fa = 'No applicable patches found.';
						|it = 'Non sono state trovate correzioni (patch) disponibili.';
						|pl = 'Nie znaleziono dostępnych korekt (łat).';
						|tr = 'Mevcut düzeltmeler (yama) bulunamadı.'");
		StandardSubsystemsClient.ShowQuestionToUser(Undefined, Message, QuestionDialogMode.OK, QuestionParameters);
		Return;
	EndIf;
	
	Message = NStr("vi = 'Đã tìm thấy bản sửa lỗi: %1. Cài đặt?';
					|ru = 'Найдено исправлений: %1. Выполнить установку?';
					|en = 'Found %1 patches. Do you want to install them?'; fa = 'Found %1 patches. Do you want to install them?';
					|it = 'Correzioni trovate: %1. Eseguire l''impostazione?';
					|pl = 'Znaleziono korekt: %1. Wykonać instalację?';
					|tr = 'Bulunan düzeltmeler: %1. Kurulum yap?'");
	Message = StringFunctionsClientServer.SubstituteParametersToString(Message, Result.NumberOfCorrections);
	
	QuestionParameters.Picture = PictureLib.DialogQuestion;
	QuestionParameters.DefaultButton = DialogReturnCode.Yes;
	StandardSubsystemsClient.ShowQuestionToUser(CallbackDescription, Message, QuestionDialogMode.YesNo, QuestionParameters);
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
Procedure ProcessManualPatchInstallationResult(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.PromptDontAskAgain = False;
	QuestionParameters.Title = NStr("vi = 'Cài đặt bản sửa lỗi';
									|ru = 'Установка исправлений';
									|en = 'Installing patches'; fa = 'Installing patches';
									|it = 'Impostazione correzioni';
									|pl = 'Instalacja korekt';
									|tr = 'Düzeltmeleri ayarlama'");
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	InstallResult = GetFromTempStorage(Result.ResultAddress);
	If InstallResult.Error Then
		ErrorText = InstallResult.BriefErrorDetails
			+ Chars.LF + Chars.LF + NStr("vi = 'Chi tiết kỹ thuật về lỗi xem trong nhật ký sự kiện.';
										|ru = 'Технические подробности о проблеме см. в журнале регистрации.';
										|en = 'For technical error details, see the event log.'; fa = 'For technical error details, see the event log.';
										|it = 'Dettagli tecnici sul problema disponibili sul registro degli eventi.';
										|pl = 'Szczegóły techniczne o problemie patrz w dzienniku rejestracji.';
										|tr = 'Sorunla ilgili teknik ayrıntılar için kayıt defterine bakın.'");
		
		Buttons = New ValueList;
		Buttons.Add("EventLog", NStr("vi = 'Nhật ký sự kiện';
									|ru = 'Журнал регистрации';
									|en = 'Event log'; fa = 'گزارش رویدادها';
									|it = 'Informazioni tecniche sui risultati di elaborazione dei dati';
									|pl = 'Informacja techniczna o rezultatach przetwarzania danych';
									|tr = 'Olay günlüğü'"));
		Buttons.Add("Close", NStr("vi = 'Đóng';
									|ru = 'Закрыть';
									|en = 'Close'; fa = 'بستن';
									|it = 'Закрыть';
									|pl = 'Close';
									|tr = 'Kapat'"));
		QuestionParameters.Picture = PictureLib.DialogExclamation;
		QuestionParameters.DefaultButton = "Close";
		CallbackDescription = New CallbackDescription("HandlePatchInstallationError", ThisObject);
		StandardSubsystemsClient.ShowQuestionToUser(CallbackDescription, ErrorText, Buttons, QuestionParameters);
		
		Return;
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Corrections", AdditionalParameters.Corrections);
	OpeningParameters.Insert("OnUpdate", True);
	ModuleConfigurationUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
	ModuleConfigurationUpdateClient.ShowInstalledPatches(OpeningParameters, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

Procedure HandlePatchInstallationError(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Value = "EventLog" Then
		EventLogClient.OpenEventLog();
	EndIf;
EndProcedure

#EndRegion