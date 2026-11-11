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
	
	InfobaseNode = DataExchangeServer.MasterNode();
	IsStandaloneWorkplace = DataExchangeServer.IsStandaloneWorkplace();
	UserName = InfoBaseUsers.CurrentUser().Name;
	
	If InfobaseNode = Undefined Then
		
		Raise NStr("vi = 'Cơ sở thông tin này không phải là chỗ làm việc độc lập hoặc phân tán.';
					|ru = 'Эта информационная база не является распределенной или автономным рабочим местом.';
					|en = 'The infobase is neither a standalone workstation nor a distributed infobase.'; fa = 'The infobase is neither a standalone workstation nor a distributed infobase.';
					|it = 'Эта информационная база не является распределенной или автономным рабочим местом.';
					|pl = 'The infobase is neither a standalone workstation nor a distributed infobase.';
					|tr = 'Bu infobase dağıtılmıştır veya çevrimdışı çalışma alanı değildir.'", Common.DefaultLanguageCode());
		
	EndIf;
	
	If IsStandaloneWorkplace Then
		Items.ConnectionParametersPages.CurrentPage = Items.SWPPage;
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		AccountPasswordRecoveryAddress = ModuleStandaloneMode.AccountPasswordRecoveryAddress();
		TimeConsumingOperationAllowed = True;
				
		If ExchangeMessagesTransport.DataSynchronizationPasswordSpecified(InfobaseNode) Then
			AuthenticationData = ExchangeMessagesTransport.DataSynchronizationPassword(InfobaseNode);
			Password = AuthenticationData.Password;
		EndIf;	
		
	EndIf;
	
	FillInInformationAboutMessageFromArchiveAtServer();
	
	NodeNameLabel = NStr("vi = 'Không thể cài đặt bản cập nhật chương trình đã nhận từ
		|""%1"".
		|Xem thông tin kỹ thuật trong <a href = ""%2"">Nhật ký sự kiện</a>.';
		|ru = 'Не удалось установить обновление программы, полученное из
		|""%1"".
		|Техническую информацию см. в <a href = ""%2"">Журнале регистрации</a>.';
		|en = 'Cannot install the application update received from
		|""%1"".
		|See <a href = ""%2"">Event log</a> for technical information.'; fa = 'Cannot install the application update received from
		|""%1"".
		|See <a href = ""%2"">Event log</a> for technical information.';
		|it = 'Не удалось установить обновление программы, полученное из
		|""%1"".
		|Техническую информацию см. в <a href = ""%2"">Журнале регистрации</a>.';
		|pl = 'Cannot install the application update received from
		|""%1"".
		|See <a href = ""%2"">Event log</a> for technical information.';
		|tr = '
		|""%1""den gelen uygulama güncelemesi yüklenemiyor.
		|Teknik bilgi için <a href = ""%2"">Olay günlüğüne</a> bakınız.'");
	Items.NodeNameHelpText.Title = 
		StringFunctions.FormattedString(NodeNameLabel, String(InfobaseNode), "EventLog");
	
	SetFormItemsView();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("FillInInformationAboutMessageFromArchive", 60, False);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NodeNameHelpTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters,,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ContinueUploadingMessageFromArchiveOnChange(Item)
	
	Items.ConnectionParametersPages.Visible = Not ContinueUploadingMessageFromArchive;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SyncAndContinue(Command)
	
	WarningText = "";
	HasErrors = False;
	
	CheckUpdateRequired();
	
	If UpdateStatus = "NoUpdateRequired" Then
		
		SynchronizeAndContinueWithoutIBUpdate();
		
	ElsIf UpdateStatus = "InfobaseUpdate" Then
		
		SynchronizeAndContinueWithIBUpdate();
		
	ElsIf UpdateStatus = "ConfigurationUpdate" Then
		
		WarningText = NStr("vi = 'Từ nút chính, đã nhận các thay đổi mà vẫn chưa được áp dụng.
			|Cần mở bộ thiết kế và cập nhật cấu hình cơ sở dữ liệu.';
			|ru = 'Из главного узла получены изменения, которые еще не применены.
			|Требуется открыть конфигуратор и обновить конфигурацию базы данных.';
			|en = 'Changes that have not been applied yet were received from the main node.
			|Open Designer and update the database configuration.'; fa = 'Changes that have not been applied yet were received from the main node.
			|Open Designer and update the database configuration.';
			|it = 'Le modifiche non ancora applicate vengono ricevute dal nodo principale.
			| Risulta necessario aprire il configuratore e aggiornare la configurazione del database.';
			|pl = 'Zmiany, które nie zostały jeszcze zastosowane, zostały odebrane z głównego węzła.
			|Wymagane jest otwarcie konfiguratora i aktualizacja konfiguracji bazy danych.';
			|tr = 'Ana üniteden henüz uygulanmamış değişiklikler alındı.
			|Designer''ı açıp veritabanı yapılandırmasını güncelleyin.'");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotSyncAndContinue(Command)
	
	DoNotSyncAndContinueAtServer();
	
	Close("Continue");
	
EndProcedure

&AtClient
Procedure ExitApplication(Command)
	
	If ValueIsFilled(ParametersOfExchangeHandler) Then
		CancelJobExecution(ParametersOfExchangeHandler.OperationID);
	EndIf;

	DetachIdleHandler("WhileWaitingForDataExchangeMessageToLoadWithoutUpdatingInfobase");
	DetachIdleHandler("WhileWaitingForUpdateDataExchangeMessageToLoad");

	Close();
		
EndProcedure

&AtClient
Procedure ConnectionParameters(Command)

	FormParameters = New Structure("Peer", InfobaseNode);
	
	OpenForm("Catalog.ExchangeMessageTransportSettings.Form.TransportSettingPanel",
		FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ForgotPassword(Command)
	ExchangeMessagesTransportClient.OpenInstructionHowToChangeDataSynchronizationPassword(AccountPasswordRecoveryAddress);
EndProcedure

&AtClient
Procedure OpenMessageFromArchive(Command)
	
	If Not ValueIsFilled(PeriodOfRecordingArchiveMessage) Then
		CommonClient.MessageToUser(NStr("vi = 'Архивное сообщение отсутствует';
										|ru = 'Архивное сообщение отсутствует';
										|en = 'There is no archive message'; fa = 'There is no archive message';
										|it = 'Архивное сообщение отсутствует';
										|pl = 'There is no archive message';
										|tr = 'Архивное сообщение отсутствует'"));
		Return;
	EndIf;
	
	RecordStructure = New Structure("Period, InfobaseNode", PeriodOfRecordingArchiveMessage, InfobaseNode);
	
	ValueType = Type("InformationRegisterRecordKey.ArchiveOfExchangeMessages");
	WriteParameters = New Array(1);
	WriteParameters[0] = RecordStructure;
	
	RecordKey = New(ValueType, WriteParameters);
	
	WriteParameters = New Structure;
	WriteParameters.Insert("Key", RecordKey);
	
	OpenForm("InformationRegister.ArchiveOfExchangeMessages.Form.RecordForm", 
		WriteParameters,
		ThisObject,
		UUID);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Scenario without updating the information base.

&AtClient
Procedure SynchronizeAndContinueWithoutIBUpdate()
	
	AttachIdleHandler("AtBeginningOfDownloadOfDataExchangeMessageWithoutUpdatingInfobase", 0.1, True);
	
	SettingUpFormElementsForLongTermOperation(True);

EndProcedure

&AtClient
Procedure AtBeginningOfDownloadOfDataExchangeMessageWithoutUpdatingInfobase()
	
	ContinueWait = True;
	WhenYouStartDownloadingDataExchangeMessageWithoutUpdatingInfobaseAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitIdleHandlerParameters(
			ParametersOfExchangeWaitingHandler);
		
		AttachIdleHandler("WhileWaitingForDataExchangeMessageToLoadWithoutUpdatingInfobase",
			ParametersOfExchangeWaitingHandler.CurrentInterval, True);
	Else
		AttachIdleHandler("AtEndOfLoadingDataExchangeMessageWithoutUpdatingInfobase", 0.1, True);
	EndIf;

EndProcedure

&AtServer
Procedure WhenYouStartDownloadingDataExchangeMessageWithoutUpdatingInfobaseAtServer(ContinueWait) 
	
	AuthenticationData = New Structure;
	
	If IsStandaloneWorkplace Then
		AuthenticationData.Insert("UserName", UserName);
		AuthenticationData.Insert("Password", Password);
	EndIf;
			
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ContinueUploadingMessageFromArchive", ContinueUploadingMessageFromArchive);
	ProcedureParameters.Insert("InfobaseNode", InfobaseNode);
	ProcedureParameters.Insert("AuthenticationData",   AuthenticationData);
	ProcedureParameters.Insert("HasErrors",             False);
	
	OperationStartDate = CurrentSessionDate();
	
	ParametersOfExchangeHandler = Undefined;
	
	ModuleDataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleDataExchangeCreationWizard.AtBeginningOfDownloadOfDataExchangeMessageWithoutUpdatingInfobase(ProcedureParameters,
		ParametersOfExchangeHandler, ContinueWait);      
		
EndProcedure

&AtClient
Procedure WhileWaitingForDataExchangeMessageToLoadWithoutUpdatingInfobase()
	
	ContinueWait = False;
	WhileWaitingForDataExchangeMessageToLoadWithoutUpdatingInfobaseAtServer(ParametersOfExchangeHandler, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(ParametersOfExchangeWaitingHandler);
		
		AttachIdleHandler("WhileWaitingForDataExchangeMessageToLoadWithoutUpdatingInfobase",
			ParametersOfExchangeWaitingHandler.CurrentInterval, True);
	Else
		AttachIdleHandler("AtEndOfLoadingDataExchangeMessageWithoutUpdatingInfobase", 0.1, True);
	EndIf;

EndProcedure

&AtServerNoContext
Procedure WhileWaitingForDataExchangeMessageToLoadWithoutUpdatingInfobaseAtServer(HandlerParameters, ContinueWait)
	
	ModuleDataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleDataExchangeCreationWizard.WhileWaitingForMessageToLoadBeforeUpdatingInformationBase(HandlerParameters, ContinueWait);
	
EndProcedure

&AtClient
Procedure AtEndOfLoadingDataExchangeMessageWithoutUpdatingInfobase()
	
	ErrorMessage = "";
	
	WhenDownloadOfDataExchangeMessageIsCompletedWithoutUpdatingInfobaseATServer(ParametersOfExchangeHandler, ErrorMessage);
	
	If Not IsBlankString(ErrorMessage) Then
		CommonClient.MessageToUser(ErrorMessage,,,, HasErrors);
	EndIf;
	
	SynchronizeAndContinueWithoutIBUpdateCompletion();
	
	SyncAndContinueCompletion();
	
EndProcedure

&AtServerNoContext
Procedure WhenDownloadOfDataExchangeMessageIsCompletedWithoutUpdatingInfobaseATServer(HandlerParameters, ErrorMessage)
	
	CompletionStatus = Undefined;
	
	ModuleDataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleDataExchangeCreationWizard.UponCompletionOfMessageDownloadBeforeUpdatingInformationBase(HandlerParameters, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		If CompletionStatus.Result <> Undefined And CompletionStatus.Result.Cancel Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		EndIf;
	EndIf; 

EndProcedure  

&AtServer
Procedure SynchronizeAndContinueWithoutIBUpdateCompletion()
	
	// The repeat mode should be enabled in the following cases:
	// 1. Metadata with a later configuration version is imported (an infobase update required).
	// - If "Cancel" is set to "True", it cannot proceed as duplicates of generated data might occur.
	// - If "Cancel" is set to "False", an infobase update error might occur requiring re-import of the message.
	// 2. Metadata with the same configuration version is imported (no infobase update required).
	// - If "Cancel" is set to "True" and the startup proceeds, an error might occur
	//   (for example, because predefined items were not imported).
	// - If "Cancel" is set to "False", you can proceed as the import can be done later
	//   (if import fails, you can also import a new exchange message later).
	
	SetPrivilegedMode(True);
	
	If Not HasErrors Then
		
		Return;
		
	ElsIf ConfigurationChanged() Then
		If Not Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(True);
		EndIf;
		WarningText = NStr("vi = 'Từ nút chính đã nhận các thay đổi mà cần được áp dụng.
			|Hãy mở bộ thiết kế và cập nhật cấu hình cơ sở dữ liệu.';
			|ru = 'Из главного узла получены изменения, которые нужно применить.
			|Требуется открыть конфигуратор и обновить конфигурацию базы данных.';
			|en = 'Changes to be applied were received from the main node.
			|Open Designer and update the database configuration.'; fa = 'Changes to be applied were received from the main node.
			|Open Designer and update the database configuration.';
			|it = 'Le modifiche vengono ricevute dal nodo principale e devono essere applicate.
			| È necessario aprire il configuratore e aggiornare la configurazione del database.';
			|pl = 'Zmiany, które są otrzymane z głównego węzła, które należy zastosować.
			|Wymagane jest otwarcie konfiguratora i aktualizacja konfiguracji bazy danych.';
			|tr = 'Ana üniteden uygulanacak değişiklikler alındı
			|Designer''ı açıp veritabanı yapılandırmasını güncelleyin.'");
	Else
		
		If InfobaseUpdate.InfobaseUpdateRequired() Then
			EnableDataExchangeMessageImportRecurrenceBeforeStart();
		EndIf;
		
		WarningText = NStr("vi = 'Đã kết thúc nhận dữ liệu từ nút chính bị lỗi.
			|Xem chi tiết trong nhật ký sự kiện.';
			|ru = 'Получение данных из главного узла завершилось с ошибками.
			|Подробности см. в журнале регистрации.';
			|en = 'Receiving data from the master node is completed with errors.
			|For more information, see the event log.'; fa = 'Receiving data from the master node is completed with errors.
			|For more information, see the event log.';
			|it = 'La ricezione dati da parte del nodo principale ha riscontrato degli errori. 
			| Vedi il registro per i dettagli.';
			|pl = 'Odzyskiwanie danych z węzła głównego zakończyło się błędem.
			|Szczegółowe informacje zob. w dzienniku rejestracji.';
			|tr = 'Ana üniteden veri alımı hatalarla sonuçlandı.
			|Ayrıntılar için olay günlüğüne bakabilirsiniz.'");
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Scenario with updating the information base.

&AtClient
Procedure SynchronizeAndContinueWithIBUpdate()
	
	AttachIdleHandler("AtBeginningOfDownloadMessageExchangesDataWithUpdate", 0.1, True);
	
	SettingUpFormElementsForLongTermOperation(True);
	
EndProcedure

&AtClient
Procedure AtBeginningOfDownloadMessageExchangesDataWithUpdate()
	
	ContinueWait = True;
	AtBeginningOfDownloadUpdateDataExchangeMessageIsAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitIdleHandlerParameters(
			ParametersOfExchangeWaitingHandler);
		
		AttachIdleHandler("WhileWaitingForUpdateDataExchangeMessageToLoad",
			ParametersOfExchangeWaitingHandler.CurrentInterval, True);
	Else
		AttachIdleHandler("WhenDownloadIsCompleteMessageExchangesDataWithUpdate", 0.1, True);
	EndIf;

EndProcedure

&AtServer
Procedure AtBeginningOfDownloadUpdateDataExchangeMessageIsAtServer(ContinueWait) 
	
	AuthenticationData = New Structure;
	
	If IsStandaloneWorkplace Then
		AuthenticationData.Insert("UserName", UserName);
		AuthenticationData.Insert("Password", Password);
	EndIf;

	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ContinueUploadingMessageFromArchive", ContinueUploadingMessageFromArchive);
	ProcedureParameters.Insert("InfobaseNode", InfobaseNode);
	ProcedureParameters.Insert("AuthenticationData",   AuthenticationData);
	ProcedureParameters.Insert("HasErrors",             HasErrors);
	
	OperationStartDate = CurrentSessionDate();
	
	ParametersOfExchangeHandler = Undefined;
	
	ModuleDataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleDataExchangeCreationWizard.AtBeginningOfDownloadMessageExchangesDataWithUpdate(ProcedureParameters,
		ParametersOfExchangeHandler, ContinueWait);      
		
EndProcedure

&AtClient
Procedure WhileWaitingForUpdateDataExchangeMessageToLoad()
	
	ContinueWait = False;
	WhileWaitingForUpdateDataExchangeMessageToLoadAtServer(ParametersOfExchangeHandler, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(ParametersOfExchangeWaitingHandler);
		
		AttachIdleHandler("WhileWaitingForUpdateDataExchangeMessageToLoad",
			ParametersOfExchangeWaitingHandler.CurrentInterval, True);
	Else
		AttachIdleHandler("WhenDownloadIsCompleteMessageExchangesDataWithUpdate", 0.1, True);
	EndIf;

EndProcedure  

&AtServerNoContext
Procedure WhileWaitingForUpdateDataExchangeMessageToLoadAtServer(HandlerParameters, ContinueWait)
	
	ModuleDataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleDataExchangeCreationWizard.WhileWaitingForUpdateDataExchangeMessageToLoad(HandlerParameters, ContinueWait);
	
EndProcedure

&AtClient
Procedure WhenDownloadIsCompleteMessageExchangesDataWithUpdate()
	
	ErrorMessage = "";
	
	WhenDownloadIsCompleteUpdateDataExchangeMessageIsAtServer(ParametersOfExchangeHandler, ErrorMessage);
	
	If Not IsBlankString(ErrorMessage) Then
		CommonClient.MessageToUser(ErrorMessage,,,, HasErrors);
	EndIf;
	
	SynchronizeAndContinueWithIBUpdateCompletion();
	
	SyncAndContinueCompletion();

EndProcedure

&AtServerNoContext
Procedure WhenDownloadIsCompleteUpdateDataExchangeMessageIsAtServer(HandlerParameters, ErrorMessage)
	
	CompletionStatus = Undefined;
	
	ModuleDataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	ModuleDataExchangeCreationWizard.WhenDownloadIsCompleteMessageExchangesDataWithUpdate(HandlerParameters, CompletionStatus);
	
	If CompletionStatus.Cancel Then
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		If CompletionStatus.Result <> Undefined And CompletionStatus.Result.Cancel Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		EndIf;
	EndIf;
	
EndProcedure  

&AtServer
Procedure SynchronizeAndContinueWithIBUpdateCompletion()
	
	SetPrivilegedMode(True);
	
	If Not HasErrors Then
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		
		If Not Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(True);
		EndIf;
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart(
			"SkipImportPriorityDataBeforeStart", True);
		
	ElsIf ConfigurationChanged() Then
			
		If Not Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(True);
		EndIf;
		WarningText = NStr("vi = 'Từ nút chính đã nhận các thay đổi mà cần được áp dụng.
			|Hãy mở bộ thiết kế và cập nhật cấu hình cơ sở dữ liệu.';
			|ru = 'Из главного узла получены изменения, которые нужно применить.
			|Требуется открыть конфигуратор и обновить конфигурацию базы данных.';
			|en = 'Changes to be applied were received from the main node.
			|Open Designer and update the database configuration.'; fa = 'Changes to be applied were received from the main node.
			|Open Designer and update the database configuration.';
			|it = 'Le modifiche vengono ricevute dal nodo principale e devono essere applicate.
			| È necessario aprire il configuratore e aggiornare la configurazione del database.';
			|pl = 'Zmiany, które są otrzymane z głównego węzła, które należy zastosować.
			|Wymagane jest otwarcie konfiguratora i aktualizacja konfiguracji bazy danych.';
			|tr = 'Ana üniteden uygulanacak değişiklikler alındı
			|Designer''ı açıp veritabanı yapılandırmasını güncelleyin.'");
		
	Else
		
		DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		
		EnableDataExchangeMessageImportRecurrenceBeforeStart();
		
		WarningText = NStr("vi = 'Đã kết thúc nhận dữ liệu từ nút chính bị lỗi.
			|Xem chi tiết trong nhật ký sự kiện.';
			|ru = 'Получение данных из главного узла завершилось с ошибками.
			|Подробности см. в журнале регистрации.';
			|en = 'Receiving data from the master node is completed with errors.
			|For more information, see the event log.'; fa = 'Receiving data from the master node is completed with errors.
			|For more information, see the event log.';
			|it = 'La ricezione dati da parte del nodo principale ha riscontrato degli errori. 
			| Vedi il registro per i dettagli.';
			|pl = 'Odzyskiwanie danych z węzła głównego zakończyło się błędem.
			|Szczegółowe informacje zob. w dzienniku rejestracji.';
			|tr = 'Ana üniteden veri alımı hatalarla sonuçlandı.
			|Ayrıntılar için olay günlüğüne bakabilirsiniz.'");
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Scenario without synchronization

&AtServer
Procedure DoNotSyncAndContinueAtServer()
	
	SetPrivilegedMode(True);
	
	If Not InfobaseUpdate.InfobaseUpdateRequired() Then
		If Constants.LoadDataExchangeMessage.Get() Then
			Constants.LoadDataExchangeMessage.Set(False);
			DataExchangeServer.ClearDataExchangeMessageFromMasterNode();
		EndIf;
	EndIf;
	
	DataExchangeServer.SetDataExchangeMessageImportModeBeforeStart(
		"SkipImportDataExchangeMessageBeforeStart", True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Service procedures and functions.

&AtServer
Procedure CheckUpdateRequired()
	
	SetPrivilegedMode(True);
	
	If ConfigurationChanged() Then
		UpdateStatus = "ConfigurationUpdate";
	ElsIf InfobaseUpdate.InfobaseUpdateRequired() Then
		UpdateStatus = "InfobaseUpdate";
	Else
		UpdateStatus = "NoUpdateRequired";
	EndIf;
	
EndProcedure

&AtClient
Procedure SyncAndContinueCompletion()
	
	SetFormItemsView();
	
	If IsBlankString(WarningText) Then
		
		ShowUserNotification(NStr("vi = 'Làm việc độc lập';
									|ru = 'Автономная работа';
									|en = 'Standalone mode'; fa = 'حالت مستقل';
									|it = 'Lavoro autonomo';
									|pl = 'Praca offline';
									|tr = 'Tek başına mod'"),
			,
			NStr("vi = 'Đã hoàn tất đồng bộ lại dữ liệu.';
				|ru = 'Повторная синхронизация данных завершена.';
				|en = 'Data re-synchronization is completed.'; fa = 'Data re-synchronization is completed.';
				|it = 'Data re-synchronization is completed.';
				|pl = 'Data re-synchronization is completed.';
				|tr = 'Verilerin yeniden senkronizasyonu tamamlandı.'"),
			PictureLib.Information32,
			UserNotificationStatus.Important);
		
		Close("Continue");
	Else
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

// Sets the RetryDataExchangeMessageImportBeforeStart constant value to True.
// Clears exchange messages received from the master node.
//
&AtServer
Procedure EnableDataExchangeMessageImportRecurrenceBeforeStart()
	
	DataExchangeServer.ClearDataExchangeMessageFromMasterNode();
	
	Constants.RetryDataExchangeMessageImportBeforeStart.Set(True);
	
EndProcedure

&AtServer
Procedure SetFormItemsView()
	
	If DataExchangeServer.LoadDataExchangeMessage()
		And InfobaseUpdate.InfobaseUpdateRequired() Then
		
		Items.FormNotSyncAndContinue.Visible = False;
		Items.DoNotSyncHelpText.Visible = False;
	Else
		Items.FormNotSyncAndContinue.Visible = True;
		Items.DoNotSyncHelpText.Visible = True;
	EndIf;
	
	Items.PanelMain.CurrentPage = ?(TimeConsumingOperation, Items.TimeConsumingOperation, Items.Begin);
	Items.TimeConsumingOperationButtonsGroup.Visible = TimeConsumingOperation;
	Items.MainButtonsGroup.Visible = Not TimeConsumingOperation;
	
EndProcedure

&AtClient
Procedure FillInInformationAboutMessageFromArchive()
	
	FillInInformationAboutMessageFromArchiveAtServer();
	
EndProcedure  

&AtServer
Procedure FillInInformationAboutMessageFromArchiveAtServer()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ArchiveOfExchangeMessagesSliceLast.Period AS Period
	|FROM
	|	InformationRegister.ArchiveOfExchangeMessages.SliceLast(, InfobaseNode = &InfobaseNode) AS ArchiveOfExchangeMessagesSliceLast";
	
	Query.SetParameter("InfobaseNode", InfobaseNode);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then 
		Items.OpenMessageFromArchive.Title = NStr("vi = '<Сообщение в архиве отсутствует>';
													|ru = '<Сообщение в архиве отсутствует>';
													|en = '<There is no message in the archive>'; fa = '<There is no message in the archive>';
													|it = '<Сообщение в архиве отсутствует>';
													|pl = '<There is no message in the archive>';
													|tr = '<Сообщение в архиве отсутствует>'");
		Items.ContinueUploadingMessageFromArchive.ReadOnly = True;
		
		ContinueUploadingMessageFromArchive = False;
		PeriodOfRecordingArchiveMessage = Date(1,1,1);
	Else
		Selection = QueryResult.Select();
		Selection.Next();
		
		Items.OpenMessageFromArchive.Title = StrTemplate(NStr("vi = 'Архивное сообщение от %1.';
																|ru = 'Архивное сообщение от %1.';
																|en = 'Archive message dated %1.'; fa = 'Archive message dated %1.';
																|it = 'Архивное сообщение от %1.';
																|pl = 'Archive message dated %1.';
																|tr = 'Архивное сообщение от %1.'"), Format(Selection.Period, "DLF=DT"));
		Items.ContinueUploadingMessageFromArchive.ReadOnly = False;
		
		PeriodOfRecordingArchiveMessage = Selection.Period;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingUpFormElementsForLongTermOperation(LongTermOperationIsBeingPerformed)
	
	If LongTermOperationIsBeingPerformed Then
		Items.PanelMain.CurrentPage = Items.TimeConsumingOperation;
		Items.MainButtonsGroup.Visible = False;
		Items.TimeConsumingOperationButtonsGroup.Visible = True;
	Else
		Items.PanelMain.CurrentPage = Items.Begin; 
		Items.MainButtonsGroup.Visible = True;
		Items.TimeConsumingOperationButtonsGroup.Visible = False;
	EndIf;

EndProcedure

&AtServerNoContext
Procedure CancelJobExecution(Val TaskID_)
	
	TimeConsumingOperations.CancelJobExecution(TaskID_);
	
EndProcedure

#EndRegion