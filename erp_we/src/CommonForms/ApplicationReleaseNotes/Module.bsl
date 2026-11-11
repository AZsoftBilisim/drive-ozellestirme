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
	
	SubsystemSettings  = InfobaseUpdateInternal.SubsystemSettings();
	FormAddressInApplication = SubsystemSettings.ApplicationChangeHistoryLocation;
	
	If ValueIsFilled(FormAddressInApplication) Then
		Items.FormAddressInApplication.Title = FormAddressInApplication;
	EndIf;
	
	If Not Parameters.ShowOnlyChanges Then
		Items.FormAddressInApplication.Visible = False;
	EndIf;
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Những điểm mới trong cấu hình %1';
																			|ru = 'Что нового в конфигурации %1';
																			|en = 'What''s new in %1'; fa = 'What''s new in %1';
																			|it = 'Cosa c''è di nuovo nella configurazione %1';
																			|pl = 'Co nowego w konfiguracji %1';
																			|tr = 'Yapılandırmadaki yenilikler%1'"), Metadata.Synonym);
	
	If ValueIsFilled(Parameters.UpdateStartTime) Then
		UpdateStartTime = Parameters.UpdateStartTime;
		UpdateEndTime = Parameters.UpdateEndTime;
	EndIf;
	
	Sections = InfobaseUpdateInternal.NotShownUpdateDetailSections();
	LatestVersion1 = InfobaseUpdateInternal.SystemChangesDisplayLastVersion();
	
	If Sections.Count() = 0 Then
		DocumentUpdatesDetails = Metadata.CommonTemplates.Find("SystemReleaseNotes");
		If DocumentUpdatesDetails <> Undefined
			And (LatestVersion1 = Undefined
				Or Not Parameters.ShowOnlyChanges) Then
			AllSections = InfobaseUpdateInternal.UpdateDetailsSections();
			If TypeOf(AllSections) = Type("ValueList")
				And AllSections.Count() <> 0 Then
				For Each Item In AllSections Do
					Sections.Add(Item.Presentation);
				EndDo;
				DocumentUpdatesDetails = InfobaseUpdateInternal.DocumentUpdatesDetails(Sections);
			Else
				DocumentUpdatesDetails = GetCommonTemplate(DocumentUpdatesDetails);
			EndIf;
		Else
			DocumentUpdatesDetails = New SpreadsheetDocument();
		EndIf;
	Else
		DocumentUpdatesDetails = InfobaseUpdateInternal.DocumentUpdatesDetails(Sections);
	EndIf;
	
	If DocumentUpdatesDetails.TableHeight = 0 Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã cập nhật thành công cấu hình sang phiên bản %1';
																			|ru = 'Конфигурация успешно обновлена на версию %1';
																			|en = 'The application is updated to version %1.'; fa = 'The application is updated to version %1.';
																			|it = 'La configurazione è stata aggiornata con successo alla versione %1';
																			|pl = 'Konfiguracja została pomyślnie zaktualizowana do wersji %1';
																			|tr = 'Uygulama, %1 sürümüne güncellendi.'"), Metadata.Version);
		DocumentUpdatesDetails.Area("R1C1:R1C1").Text = Text;
	EndIf;
	
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	For Each SubsystemName In SubsystemsDetails.Order Do
		SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName);
		If Not ValueIsFilled(SubsystemDetails.MainServerModule) Then
			Continue;
		EndIf;
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		Module.OnPrepareUpdateDetailsTemplate(DocumentUpdatesDetails);
	EndDo;
	InfobaseUpdateOverridable.OnPrepareUpdateDetailsTemplate(DocumentUpdatesDetails);
	
	UpdatesDetails.Clear();
	UpdatesDetails.Put(DocumentUpdatesDetails);
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	UpdateStartTime = UpdateInfo.UpdateStartTime;
	UpdateEndTime = UpdateInfo.UpdateEndTime;
	
	If Not Common.SeparatedDataUsageAvailable()
		Or UpdateInfo.DeferredUpdateCompletedSuccessfully <> Undefined
		Or UpdateInfo.HandlersTree <> Undefined
			And UpdateInfo.HandlersTree.Rows.Count() = 0 Then
		Items.DeferredUpdate.Visible = False;
	EndIf;
	
	If Common.FileInfobase() Then
		MessageTitle = NStr("vi = 'Cần thực hiện các thủ tục bổ sung để xử lý dữ liệu';
							|ru = 'Необходимо выполнить дополнительные процедуры обработки данных';
							|en = 'Additional data processing required'; fa = 'Additional data processing required';
							|it = 'È necessario effettuare delle procedure aggiuntive di elaborazione dei dati';
							|pl = 'Należy wykonać dodatkowe procedury przetwarzania danych';
							|tr = 'Ek veri işleme prosedürlerini yürütme'");
		Items.DeferredDataUpdate.Title = MessageTitle;
	EndIf;
	
	If Not Users.IsFullUser(, True) Then
		Items.DeferredDataUpdate.Title =
			NStr("vi = 'Chưa thực hiện thủ tục bổ sung để xử lý dữ liệu';
				|ru = 'Не выполнены дополнительные процедуры обработки данных';
				|en = 'Additional data processing skipped'; fa = 'Additional data processing skipped';
				|it = 'Ulteriori procedure di elaborazione dei dati non sono state eseguite';
				|pl = 'Dodatkowe procedury przetwarzania danych nie zostały wykonane';
				|tr = 'Ek veri işleme prosedürleri uygulanmadı'");
	EndIf;
	
	Items.TechnicalInformationOnUpdateResult.Visible = 
		(Users.IsFullUser() And Not Common.DataSeparationEnabled())
		And (ValueIsFilled(UpdateStartTime) Or ValueIsFilled(UpdateEndTime));
	
	ClientServerInfobase = Not Common.FileInfobase();
	
	// Displaying the information on disabled scheduled jobs.
	If Not ClientServerInfobase
		And Users.IsFullUser(, True) Then
		ClientLaunchParameter = StandardSubsystemsServer.ClientParametersAtServer().Get("LaunchParameter");
		ScheduledJobsDisabled = StrFind(ClientLaunchParameter, "ScheduledJobsDisabled2") <> 0;
		If Not ScheduledJobsDisabled Then
			Items.ScheduledJobsDisabledGroup.Visible = False;
		EndIf;
	Else
		Items.ScheduledJobsDisabledGroup.Visible = False;
	EndIf;
	
	Items.UpdatesDetails.HorizontalScrollBar = ScrollBarUse.DontUse;
	
	InfobaseUpdateInternal.SetShowDetailsToCurrentVersionFlag();
	
	If Common.IsMobileClient() Then
		Items.CommandBarForm.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If ClientServerInfobase Then
		AttachIdleHandler("UpdateDeferredUpdateStatus", 60);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UpdatesDetailsSelection(Item, Area, StandardProcessing)
	
	If TypeOf(Area) = Type("SpreadsheetDocumentRange")
		And (StrFind(Area.Text, "http://") = 1 Or StrFind(Area.Text, "https://") = 1) Then
		FileSystemClient.OpenURL(Area.Text);
	EndIf;
	
	InfobaseUpdateClientOverridable.OnClickUpdateDetailsDocumentHyperlink(Area);
	
EndProcedure

&AtClient
Procedure ShowUpdateResultInfoClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowErrorsAndWarnings", True);
	FormParameters.Insert("StartDate", UpdateStartTime);
	FormParameters.Insert("EndDate", UpdateEndTime);
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DeferredDataUpdate(Command)
	OpenForm("DataProcessor.ApplicationUpdateResult.Form.ApplicationUpdateResult");
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateDeferredUpdateStatus()
	
	UpdateDeferredUpdateStatusAtServer();
	
EndProcedure

&AtServer
Procedure UpdateDeferredUpdateStatusAtServer()
	
	UpdateInfo = InfobaseUpdateInternal.InfobaseUpdateInfo();
	If UpdateInfo.DeferredUpdatesEndTime <> Undefined Then
		Items.DeferredUpdate.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduledJobsDisabledURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	Notification = New CallbackDescription("ScheduledJobsDisabledURLProcessingCompletion", ThisObject);
	QueryText = NStr("vi = 'Khởi động lại ứng dụng?';
					|ru = 'Перезапустить приложение?';
					|en = 'Restart the application?'; fa = 'Restart the application?';
					|it = 'Перезапустить приложение?';
					|pl = 'Restart the application?';
					|tr = 'Uygulama yeniden başlatılsın mı?'");
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.No);
EndProcedure

&AtClient
Procedure ScheduledJobsDisabledURLProcessingCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		NewStartupParameter = StrReplace(LaunchParameter, "ScheduledJobsDisabled2", "");
		NewStartupParameter = StrReplace(NewStartupParameter, "StartInfobaseUpdate", "");
		NewStartupParameter = StrConcat(StrSplit(NewStartupParameter, ";", False), ";");
		NewStartupParameter = "/C """ + NewStartupParameter + """";
		Terminate(True, NewStartupParameter);
	EndIf;
	
EndProcedure

#EndRegion
