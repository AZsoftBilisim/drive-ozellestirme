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
	
	SetPrivilegedMode(True);
	
	If Not StandaloneModeInternal.IsStandaloneWorkplace() Then
		Raise NStr("vi = 'Cơ sở thông tin này không phải là chỗ làm việc độc lập.';
					|ru = 'Эта информационная база не является автономным рабочим местом.';
					|en = 'The infobase is not a standalone workstation.'; fa = 'The infobase is not a standalone workstation.';
					|it = 'Questo data base non è un posto di lavoro autonomo.';
					|pl = 'Ta baza informacyjna nie jest miejscem pracy offline.';
					|tr = 'Bu Infobase bir çevrimdışı çalışma alanı değil.'");
	EndIf;
	
	ApplicationInSaaS = StandaloneModeInternal.ApplicationInSaaS();
	
	TransportID = ExchangeMessagesTransport.DefaultTransport(ApplicationInSaaS);
	
	ScheduledJob = ScheduledJobsServer.GetScheduledJob(
		Metadata.ScheduledJobs.DataSynchronizationWithWebApplication);
	
	SynchronizeDataBySchedule = ScheduledJob.Use;
	DataSynchronizationSchedule      = ScheduledJob.Schedule;
	
	OnChangeDataSynchronizationSchedule();
	
	SynchronizeDataOnStart = Constants.SynchronizeDataWithInternetApplicationsOnStart.Get();
	SynchronizeDataOnExit = Constants.SynchronizeDataWithInternetApplicationsOnExit.Get();
	
	AccountPasswordRecoveryAddress = StandaloneModeInternal.AccountPasswordRecoveryAddress();
	
	SetPrivilegedMode(False);
	
	RefreshVisibilityAtServer();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("RefreshVisibility", 60);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "DataExchangeCompleted" Then
		RefreshVisibility();
		
	ElsIf EventName = "UserSettingsChanged" Then
		RefreshVisibility();
		
	ElsIf EventName = "Write_ExchangeTransportSettings" Then
		
		If Parameter.Property("AutomaticSynchronizationSetup") Then
			SynchronizeDataBySchedule = True;
			SynchronizeDataOnScheduleOnValueChange();
		EndIf;
		
	ElsIf EventName = "DataExchangeResultFormClosed" Then
		UpdateSwitchToConflictsTitle();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowTimeConsumingSynchronizationWarningOnChange(Item)
	
	SwitchLongSynchronizationWarning(ShowTimeConsumingSynchronizationWarning);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PerformDataSynchronization(Command)
	
	AuthenticationParameters = ExchangeMessagesTransportClient.AuthenticationParameters();
	AuthenticationParameters.Peer = ApplicationInSaaS;
	AuthenticationParameters.TransportID = TransportID;
		
	AuthenticationRequired = False;
	ClosingNotification1 = New CallbackDescription("EndOfAuthentication", ThisObject);
	ExchangeMessagesTransportClient.StartOfAuthentication(AuthenticationParameters, AuthenticationRequired, ClosingNotification1);
			
	If Not AuthenticationRequired Then
		DataExchangeClient.ExecuteDataExchangeCommandProcessing(ApplicationInSaaS, ThisObject, AccountPasswordRecoveryAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure EndOfAuthentication(AuthenticationData, AdditionalParameters) Export 
	
	If Not ValueIsFilled(AuthenticationData) Then
		Return;
	EndIf;
	
	ExchangeMessageTransportServerCall.SetDataSynchronizationPassword(
		ApplicationInSaaS, AuthenticationData);
	
	DataExchangeClient.ExecuteDataExchangeCommandProcessing(ApplicationInSaaS, ThisObject, AccountPasswordRecoveryAddress);
	
EndProcedure

&AtClient
Procedure ChangeDataSynchronizationSchedule(Command)
	
	Dialog = New ScheduledJobDialog(DataSynchronizationSchedule);
	CallbackDescription = New CallbackDescription("ChangeDataSynchronizationScheduleCompletion", ThisObject);
	Dialog.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure ChangeDataSynchronizationScheduleCompletion(Schedule, AdditionalParameters) Export
	
	If Schedule <> Undefined Then
		
		DataSynchronizationSchedule = Schedule;
		
		ChangeDataSynchronizationScheduleAtServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InstallUpdate(Command)
	
	DataExchangeClient.InstallConfigurationUpdate();
	
EndProcedure

&AtClient
Procedure RestartApplication(Command)
	
	Exit(False, True);
	
EndProcedure


&AtClient
Procedure SynchronizeDataByScheduleOnChange(Item)
	
	If SynchronizeDataBySchedule And Not SaveUserPassword Then
		
		SynchronizeDataBySchedule = False;
		
		SetServiceConnection(True);
		
	Else
		
		SynchronizeDataOnScheduleOnValueChange();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DataSynchronizationScheduleOptionOnChange(Item)
	
	DataSynchronizationScheduleOptionOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure SynchronizeDataOnStartOnChange(Item)
	
	SetConstantValueSynchronizeDataWithWebApplicationOnStart(
		SynchronizeDataOnStart);
EndProcedure

&AtClient
Procedure SynchronizeDataOnExitOnChange(Item)
	
	SetConstantValueSynchronizeDataWithWebApplicationOnExit(
		SynchronizeDataOnExit);
		
	ParameterName = "StandardSubsystems.SuggestDataSynchronizationWithWebApplicationOnExit";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;

	ApplicationParameters["StandardSubsystems.SuggestDataSynchronizationWithWebApplicationOnExit"] =
		SynchronizeDataOnExit;
	
EndProcedure

&AtClient
Procedure ConfigureConnection(Command)
	
	SetServiceConnection();
	
EndProcedure

&AtClient
Procedure ArchiveOfExchangeMessages(Command)
	
	Filter              = New Structure("InfobaseNode", ApplicationInSaaS);
	FillingValues = New Structure("InfobaseNode", ApplicationInSaaS);
		
	DataExchangeClient.OpenInformationRegisterWriteFormByFilter(Filter,
		FillingValues, "ExchangeMessageArchiveSettings", ThisForm);

EndProcedure

&AtClient
Procedure GoToConflicts(Command)
	
	ExchangeNodes = New Array;
	ExchangeNodes.Add(ApplicationInSaaS);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ExchangeNodes", ExchangeNodes);
	OpenForm("InformationRegister.DataExchangeResults.Form.Form", OpeningParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure RefreshVisibility()
	
	RefreshVisibilityAtServer();
	
EndProcedure

&AtServer
Procedure RefreshVisibilityAtServer()
	
	SetPrivilegedMode(True);
	
	SynchronizationDatePresentation = DataExchangeServer.SynchronizationDatePresentation(
		StandaloneModeInternal.LastSuccessfulSynchronizationDate(ApplicationInSaaS));
	Items.LastSynchronizationInfo.Title = SynchronizationDatePresentation + ".";
	Items.LastSynchronizationInfo1.Title = SynchronizationDatePresentation + ".";
	
	UpdateSwitchToConflictsTitle();
	
	UpdateInstallationRequired = DataExchangeServer.UpdateInstallationRequired();
	
	IsRestartRequired = Catalogs.ExtensionsVersions.ExtensionsChangedDynamically();
	
	If UpdateInstallationRequired Then
		
		Items.StandaloneMode.CurrentPage = Items.IsConfigurationUpdateReceived;
		
		Items.InstallUpdate.DefaultButton         = True;
		Items.InstallUpdate.DefaultItem = True;
		
	ElsIf IsRestartRequired Then
		
		Items.StandaloneMode.CurrentPage = Items.ExtensionsAreReceived;
		
		Items.RestartApplication.DefaultButton         = True;
		Items.RestartApplication.DefaultItem = True;
		
	Else
		
		Items.StandaloneMode.CurrentPage = Items.DataSynchronization;
		
		Items.PerformDataSynchronization.DefaultButton         = True;
		Items.PerformDataSynchronization.DefaultItem = True;
		
	EndIf;
	
	SaveUserPassword = True;
	
	SynchronizeDataBySchedule = ScheduledJobsServer.ScheduledJobUsed(Metadata.ScheduledJobs.DataSynchronizationWithWebApplication);
	
	Items.ConfigureConnection.Enabled = SynchronizeDataBySchedule;
	Items.DataSynchronizationScheduleOption.Enabled = SynchronizeDataBySchedule;
	Items.ChangeDataSynchronizationSchedule.Enabled = SynchronizeDataBySchedule;
	
	Items.ChangeDataSynchronizationSchedule.Visible = Not Common.IsMobileClient();
	
	SetPrivilegedMode(False);
	
	// Setting item visibility by user roles
	RoleAvailableDataSynchronizationSetup = DataExchangeServer.HasRightsToAdministerExchanges();
	Items.DataSynchronizationSetup.Visible = RoleAvailableDataSynchronizationSetup;
	Items.InstallUpdate.Visible = RoleAvailableDataSynchronizationSetup;
	
	If RoleAvailableDataSynchronizationSetup Then
		Items.UpdateReceivedCommentLabel.Title = NStr("vi = 'Đã nhận bản cập nhật chương trình từ Internet.
			|Hãy cài đặt bản cập nhật đã nhận, sau đó sẽ tiếp tục đồng bộ.';
			|ru = 'Получено обновление программы из Интернета.
			|Установите полученное обновление, после чего синхронизация будет продолжена.';
			|en = 'The application update is received from the Internet.
			|Install the received update so that the synchronization continues.'; fa = 'The application update is received from the Internet.
			|Install the received update so that the synchronization continues.';
			|it = 'Aggiornamento del programma ricevuto da Internet.
			|Impostare l''aggiornamento ricevuto, dopo proseguirà la sincronizzazione dati.';
			|pl = 'Aktualizacja oprogramowania została pobrana z Internetu.
			|Zainstaluj pobraną aktualizację, po której synchronizacja będzie kontynuowana.';
			|tr = 'Bu uygulamanın güncellemesi Internet''ten alındı.
			|Veri senkronizasyonuna devam etmek için güncellemeyi yükleyin.'");
	Else
		Items.UpdateReceivedCommentLabel.Title = NStr("vi = 'Đã nhận bản cập nhật chương trình từ Internet.
			|Hãy liên hệ với người quản trị cơ sở thông tin để cài đặt bản cập nhật đã nhận.';
			|ru = 'Получено обновление программы из Интернета.
			|Обратитесь к администратору информационной базы для установки полученного обновления.';
			|en = 'The application update is received from the Internet.
			|Contact the infobase administrator to install the update.'; fa = 'The application update is received from the Internet.
			|Contact the infobase administrator to install the update.';
			|it = 'È stato ricevuto un aggiornamento del programma da Internet.
			| Rivolgersi all''amministratore del database per l''installazione dell''aggiornamento ricevuto.';
			|pl = 'Aktualizacja oprogramowania została otrzymana z Internetu.
			|Skontaktuj się z administratorem bazy informacyjnej, żeby zainstalować pobraną aktualizację.';
			|tr = 'Bu uygulamanın güncellemesi Internet''ten alındı.
			|Alınan güncellemeyi yüklemek için Infobase yöneticisi ile iletişime geçin.'");
	EndIf;
	
	ShowTimeConsumingSynchronizationWarning = StandaloneModeInternal.LongSynchronizationQuestionSetupFlag();
EndProcedure

&AtServer
Procedure UpdateSwitchToConflictsTitle()
	
	If DataExchangeCached.VersioningUsed() Then
		
		TitleStructure = InformationRegisters.DataExchangeResults.TheNumberOfWarningsForTheFormElement(ApplicationInSaaS);
		
		FillPropertyValues (Items.GoToConflicts, TitleStructure);
		FillPropertyValues (Items.GoToConflicts1, TitleStructure);
		
	Else
		
		Items.GoToConflicts.Visible = False;
		Items.GoToConflicts1.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DataSynchronizationScheduleOptionOnChangeAtServer()
	
	NewDataSynchronizationSchedule = "";
	
	If DataSynchronizationScheduleOption = 1 Then
		
		NewDataSynchronizationSchedule = PredefinedScheduleOption1();
		
	ElsIf DataSynchronizationScheduleOption = 2 Then
		
		NewDataSynchronizationSchedule = PredefinedScheduleOption2();
		
	ElsIf DataSynchronizationScheduleOption = 3 Then
		
		NewDataSynchronizationSchedule = PredefinedScheduleOption3();
		
	Else // 4
		
		NewDataSynchronizationSchedule = DataSynchronizationUserSchedule;
		
	EndIf;
	
	If String(DataSynchronizationSchedule) <> String(NewDataSynchronizationSchedule) Then
		
		DataSynchronizationSchedule = NewDataSynchronizationSchedule;
		
		ScheduledJobsServer.SetJobSchedule(
			Metadata.ScheduledJobs.DataSynchronizationWithWebApplication,
			DataSynchronizationSchedule);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SwitchLongSynchronizationWarning(Val Flag)
	
	StandaloneModeInternal.LongSynchronizationQuestionSetupFlag(Flag);
	
EndProcedure

&AtServer
Procedure OnChangeDataSynchronizationSchedule()
	
	Items.DataSynchronizationScheduleOption.ChoiceList.Clear();
	Items.DataSynchronizationScheduleOption.ChoiceList.Add(1, NStr("vi = 'Cứ 15 phút';
																	|ru = 'Каждые 15 минут';
																	|en = 'Every 15 minutes'; fa = 'Every 15 minutes';
																	|it = 'Ogni 15 minuti';
																	|pl = 'Co 15 minut';
																	|tr = '15 dakikada bir'"));
	Items.DataSynchronizationScheduleOption.ChoiceList.Add(2, NStr("vi = 'Mỗi giờ';
																	|ru = 'Каждый час';
																	|en = 'Every hour'; fa = 'Every hour';
																	|it = 'Ogni oa';
																	|pl = 'Co godzinę';
																	|tr = 'Saatte bir'"));
	Items.DataSynchronizationScheduleOption.ChoiceList.Add(3, NStr("vi = 'Hàng ngày vào 10:00, ngoại trừ thứ bảy và chủ nhật';
																	|ru = 'Каждый день в 10:00, кроме сб. и вс.';
																	|en = 'Every day at 10:00 AM except for Sa and Su.'; fa = 'Every day at 10:00 AM except for Sa and Su.';
																	|it = 'Ogni giorno alle 10:00, tranne sabato e domenica';
																	|pl = 'Co godzinę o 10:00, oprócz sb i nd';
																	|tr = 'Hafta içi her gün 10''da'"));
	
	// Selecting a data synchronization schedule option
	DataSynchronizationScheduleOptions = New Map;
	DataSynchronizationScheduleOptions.Insert(String(PredefinedScheduleOption1()), 1);
	DataSynchronizationScheduleOptions.Insert(String(PredefinedScheduleOption2()), 2);
	DataSynchronizationScheduleOptions.Insert(String(PredefinedScheduleOption3()), 3);
	
	DataSynchronizationScheduleOption = DataSynchronizationScheduleOptions[String(DataSynchronizationSchedule)];
	
	If DataSynchronizationScheduleOption = 0 Then
		
		DataSynchronizationScheduleOption = 4;
		Items.DataSynchronizationScheduleOption.ChoiceList.Add(4, String(DataSynchronizationSchedule));
		DataSynchronizationUserSchedule = DataSynchronizationSchedule;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeDataSynchronizationScheduleAtServer()
	
	ScheduledJobsServer.SetJobSchedule(
		Metadata.ScheduledJobs.DataSynchronizationWithWebApplication,
		DataSynchronizationSchedule);
	
	OnChangeDataSynchronizationSchedule();
	
EndProcedure

&AtServerNoContext
Procedure SetConstantValueSynchronizeDataWithWebApplicationOnStart(Val Value)
	
	SetPrivilegedMode(True);
	
	Constants.SynchronizeDataWithInternetApplicationsOnStart.Set(Value);
	
EndProcedure

&AtServerNoContext
Procedure SetConstantValueSynchronizeDataWithWebApplicationOnExit(Val Value)
	
	SetPrivilegedMode(True);
	
	Constants.SynchronizeDataWithInternetApplicationsOnExit.Set(Value);
	
EndProcedure

&AtClient
Procedure SetServiceConnection(AutomaticSynchronizationSetup = False)
	
	FormParameters = New Structure;
	FormParameters.Insert("Peer", ApplicationInSaaS);
	FormParameters.Insert("TransportID", TransportID);
	FormParameters.Insert("AccountPasswordRecoveryAddress", AccountPasswordRecoveryAddress);
	FormParameters.Insert("AutomaticSynchronizationSetup", AutomaticSynchronizationSetup);
	
	OpenForm("Catalog.ExchangeMessageTransportSettings.Form.SaaSConnectionSetup", 
		FormParameters, ThisForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
	RefreshVisibilityAtServer();
	
EndProcedure

&AtClient
Procedure SynchronizeDataOnScheduleOnValueChange()
	
	SetScheduledJobUsage(SynchronizeDataBySchedule);
	
	Items.ConfigureConnection.Enabled = SynchronizeDataBySchedule;
	Items.DataSynchronizationScheduleOption.Enabled = SynchronizeDataBySchedule;
	Items.ChangeDataSynchronizationSchedule.Enabled = SynchronizeDataBySchedule;
	
EndProcedure

&AtServerNoContext
Procedure SetScheduledJobUsage(Val SynchronizeDataBySchedule)
	
	ScheduledJobsServer.SetScheduledJobUsage(
		Metadata.ScheduledJobs.DataSynchronizationWithWebApplication,
		SynchronizeDataBySchedule);
	
EndProcedure

// Predefined data synchronization schedules

&AtServerNoContext
Function PredefinedScheduleOption1() // Every 15 minutes
	
	Months = New Array;
	Months.Add(1);
	Months.Add(2);
	Months.Add(3);
	Months.Add(4);
	Months.Add(5);
	Months.Add(6);
	Months.Add(7);
	Months.Add(8);
	Months.Add(9);
	Months.Add(10);
	Months.Add(11);
	Months.Add(12);
	
	WeekDays = New Array;
	WeekDays.Add(1);
	WeekDays.Add(2);
	WeekDays.Add(3);
	WeekDays.Add(4);
	WeekDays.Add(5);
	WeekDays.Add(6);
	WeekDays.Add(7);
	
	Schedule = New JobSchedule;
	Schedule.Months                   = Months;
	Schedule.WeekDays                = WeekDays;
	Schedule.RepeatPeriodInDay = 60*15; // 15 minutes.
	Schedule.DaysRepeatPeriod        = 1; // Every day.
	
	Return Schedule;
EndFunction

&AtServerNoContext
Function PredefinedScheduleOption2() // Every hour.
	
	Return StandaloneModeInternal.DefaultDataSynchronizationSchedule();
	
EndFunction

&AtServerNoContext
Function PredefinedScheduleOption3() // Every day at 10:00 AM except for Sa and Su.
	
	Months = New Array;
	Months.Add(1);
	Months.Add(2);
	Months.Add(3);
	Months.Add(4);
	Months.Add(5);
	Months.Add(6);
	Months.Add(7);
	Months.Add(8);
	Months.Add(9);
	Months.Add(10);
	Months.Add(11);
	Months.Add(12);
	
	WeekDays = New Array;
	WeekDays.Add(1);
	WeekDays.Add(2);
	WeekDays.Add(3);
	WeekDays.Add(4);
	WeekDays.Add(5);
	
	Schedule = New JobSchedule;
	Schedule.Months            = Months;
	Schedule.WeekDays         = WeekDays;
	Schedule.BeginTime       = Date('00010101100000'); // 10:00
	Schedule.DaysRepeatPeriod = 1; // Every day.
	
	Return Schedule;
EndFunction


#EndRegion
