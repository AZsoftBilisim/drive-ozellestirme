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
	
	AccountPasswordRecoveryAddress = Parameters.AccountPasswordRecoveryAddress;
	CloseOnSynchronizationDone           = Parameters.CloseOnSynchronizationDone;
	InfobaseNode                    = Parameters.InfobaseNode;
	ShouldExitApp                   = Parameters.ShouldExitApp;
	
	Parameters.Property("IsExchangeWithApplicationInService", ExchangeBetweenSaaSApplications);
	Parameters.Property("CorrespondentDataArea",  CorrespondentDataArea);
	
	AuthenticationData = ExchangeMessagesTransport.DataSynchronizationPassword(InfobaseNode);
	
	If Not ValueIsFilled(InfobaseNode) Then
		
		If DataExchangeServer.IsSubordinateDIBNode() Then
			InfobaseNode = DataExchangeServer.MasterNode();
		Else
			Text = NStr("vi = 'Chưa xác định tham số biểu mẫu. Không thể mở biểu mẫu.';
						|ru = 'Не заданы параметры формы. Форма не может быть открыта.';
						|en = 'Cannot open the form. The form parameters are not specified.'; fa = 'Cannot open the form. The form parameters are not specified.';
						|it = 'Non è specificato alcun parametro del modulo. Il modulo non può essere aperto.';
						|pl = 'Nie określono parametrów formularza. Formularza nie można otworzyć.';
						|tr = 'Form parametreleri belirtilmemiş. Form açılamıyor.'",
				Common.DefaultLanguageCode());
				
			DataExchangeServer.ReportError(Text, Cancel);
			Return;
		EndIf;
		
	EndIf;
		
	SetPrivilegedMode(True);
	
	PeerInfobaseName = String(InfobaseNode);
	TransportSettings = ExchangeMessagesTransport.DefaultTransportSettings(InfobaseNode, TransportID);
	
	If Not ValueIsFilled(TransportID) Then
		
		Text = NStr("vi = 'Chưa xác định tùy chỉnh kết nối mặc định.
                      |Không thể tiếp tục đồng bộ.';
                      |ru = 'Не заданы настройки подключения по умолчанию.
                      |Синхронизация не может быть продолжена.';
                      |en = 'Default connection settings are not configured.
                      |Synchronization is aborted.'; fa = 'Default connection settings are not configured.
                      |Synchronization is aborted.';
                      |it = 'Не заданы настройки подключения по умолчанию.
                      |Синхронизация не может быть продолжена.';
                      |pl = 'Default connection settings are not configured.
                      |Synchronization is aborted.';
                      |tr = 'Varsayılan bağlantı ayarları yapılmadı.
                      |Senkronizasyon devam edemiyor.'",
			Common.DefaultLanguageCode()); 
		
		Raise Text;
		
	EndIf;
	
	ExecuteDataSending = InformationRegisters.CommonInfobasesNodesSettings.ExecuteDataSending(InfobaseNode);
	
	SetPrivilegedMode(False);
		
	If TransportID = "SM" And TransportSettings.InternalPublication Then
		ExchangeViaInternalPublication = True;
		CorrespondentDataArea = TransportSettings.CorrespondentDataArea; 
	Else
		ExchangeViaInternalPublication = False;
	EndIf;
	
	// Initialize user roles.
	DataExchangeAdministrationRoleAssigned = DataExchangeServer.HasRightsToAdministerExchanges();
	RoleAvailableFullAccess                     = Users.IsFullUser();
	
	NoLongSynchronizationPrompt = True;
	CheckVersionDifference       = Not ExchangeBetweenSaaSApplications;
	
	ConnectOverExternalConnection = False;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS")
		And DataExchangeServer.IsStandaloneWorkplace() Then
		
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		
		NoLongSynchronizationPrompt = Not ModuleStandaloneMode.LongSynchronizationQuestionSetupFlag();
		CheckVersionDifference       = False;
		
	EndIf;
	
	// Set a form title.
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đồng bộ dữ liệu với ""%1""';
			|ru = 'Синхронизация данных с ""%1""';
			|en = 'Synchronize data with %1'; fa = 'همگام‌سازی داده با %1';
			|it = 'Sincronizzazione dati con ""%1""';
			|pl = 'Synchronizacja danych z ""%1""';
			|tr = '%1 ile veri senkronizasyonu'"), PeerInfobaseName);
	
	// For DIB data exchange over a web service, always override the authentication parameters (username and password) saved in the infobase.
	// For non-DIB data exchange, override (prompt for) the authentication parameters (password) only if they aren't saved in the infobase.
	// 
	// 
	UseCurrentUserForAuthentication = False;
	UseSavedAuthenticationParameters    = False;
	SynchronizationPasswordSpecified                          = False;
	SyncPasswordSaved                       = False; // The password is saved in a safe storage (available in the background job)
	WSPassword                                          = "";
	
	HasErrors = ((DataExchangeServer.MasterNode() = InfobaseNode) And ConfigurationChanged());
	
	BackgroundJobUseProgress = ExchangeMessagesTransport.TransportParameter(TransportID, "UseProgress");
	
	WindowOptionsKey = ?(SynchronizationPasswordSpecified And NoLongSynchronizationPrompt,
		"SynchronizationPasswordSpecified", "") + "/" + ?(NoLongSynchronizationPrompt, "NoLongSynchronizationPrompt", "");
		
	FillNavigationTable();
	
	CheckWhetherTheExchangeCanBeStarted(InfobaseNode, IsNodeLocked);
	
	If ExchangeViaInternalPublication Then
		ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
		HasNodeScheduledExchange = ModuleDataExchangeInternalPublication.HasNodeScheduledExchange(
			InfobaseNode, 
			ScenarioUsingInternalPublication,
			IDOfExchangeViaInternalPublication);
	EndIf;
		
	Items.GroupWarningWhenSharingViaInternalPublishing.Visible = ExchangeViaInternalPublication;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If IsNodeLocked Then
		
		Step = 2;
		
	Else
		
		Step = 1;
		
	EndIf;
	
	SetNavigationNumber(Step);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If TimeConsumingOperation Then
		EndExecutingTimeConsumingOperation(IDBackgroundJob);
	EndIf;
	
	If ValueIsFilled(FormReopeningParameters)
		And FormReopeningParameters.Property("NewDataSynchronizationSetting") Then
		
		NewDataSynchronizationSetting = FormReopeningParameters.NewDataSynchronizationSetting;
		
		FormParameters = New Structure;
		FormParameters.Insert("InfobaseNode",                    NewDataSynchronizationSetting);
		FormParameters.Insert("AccountPasswordRecoveryAddress", AccountPasswordRecoveryAddress);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("WindowOpeningMode", FormWindowOpeningMode.LockOwnerWindow);
		
		DataExchangeClient.OpenFormAfterCloseCurrentOne(ThisObject,
			"DataProcessor.DataExchangeExecution.Form.Form", FormParameters, OpeningParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToEventLog(Command)
	
	FormParameters = EventLogFilterData(InfobaseNode);
	OpenForm("DataProcessor.EventLog.Form", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure InstallUpdate(Command)
	
	DataExchangeClient.InstallConfigurationUpdate(ShouldExitApp);
	
EndProcedure

&AtClient
Procedure RestartApplication(Command)

	Exit(False, True);

EndProcedure

&AtClient
Procedure ExecuteExchange(Command)
	
	ExecuteMoveNext();
	
EndProcedure

&AtClient
Procedure ContinueSync(Command)
	
	NavigationNumber = NavigationNumber - 1;
	SetNavigationNumber(NavigationNumber + 1);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Supplied part
////////////////////////////////////////////////////////////////////////////////

&AtClient
Function GetFormButtonByCommandName(FormItem, CommandName)
	
	For Each Item In FormItem.ChildItems Do
		
		If TypeOf(Item) = Type("FormGroup") Then
			
			FormItemByCommandName = GetFormButtonByCommandName(Item, CommandName);
			
			If FormItemByCommandName <> Undefined Then
				
				Return FormItemByCommandName;
				
			EndIf;
			
		ElsIf TypeOf(Item) = Type("FormButton")
			And StrFind(Item.CommandName, CommandName) > 0 Then
			
			Return Item;
			
		Else
			
			Continue;
			
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure ExecuteMoveNext()
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure ChangeNavigationNumber(Iterator_SSLy)
	
	ClearMessages();
	SetNavigationNumber(NavigationNumber + Iterator_SSLy);
	
EndProcedure

&AtClient
Procedure SetNavigationNumber(Val Value)
	
	IsMoveNext = (Value > NavigationNumber);
	
	NavigationNumber = Value;
	
	If NavigationNumber < 0 Then
		NavigationNumber = 0;
	EndIf;
	
	NavigationNumberOnChange(IsMoveNext);
	
EndProcedure

&AtClient
Procedure NavigationNumberOnChange(Val IsMoveNext)
	
	// Run navigation event handlers.
	ExecuteNavigationEventHandlers(IsMoveNext);
	
	// Set up page view.
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	Items.DataExchangeExecution.CurrentPage = Items[NavigationRowCurrent.MainPageName];
	
	If IsMoveNext And NavigationRowCurrent.TimeConsumingOperation Then
		AttachIdleHandler("ExecuteTimeConsumingOperationHandler", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteNavigationEventHandlers(Val IsMoveNext)
	
	// Navigation event handlers.
	If IsMoveNext Then
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber - 1));
		
		If NavigationRows.Count() > 0 Then
			
			NavigationRow = NavigationRows[0];
			
			// OnNavigationToNextPage handler.
			If Not IsBlankString(NavigationRow.OnNavigationToNextPageHandlerName)
				And Not NavigationRow.TimeConsumingOperation Then
				
				ProcedureName = "[HandlerName](Cancel)";
				ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnNavigationToNextPageHandlerName);
				
				Cancel = False;
				
				CalculationResult = Eval(ProcedureName);
				
				If Cancel Then
					
					SetNavigationNumber(NavigationNumber - 1);
					
					Return;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	Else
		
		NavigationRows = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber + 1));
		
		If NavigationRows.Count() > 0 Then
			
			NavigationRow = NavigationRows[0];
			
			// OnNavigationToPreviousPage handler.
			If Not IsBlankString(NavigationRow.OnSwitchToPreviousPageHandlerName)
				And Not NavigationRow.TimeConsumingOperation Then
				
				ProcedureName = "[HandlerName](Cancel)";
				ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnSwitchToPreviousPageHandlerName);
				
				Cancel = False;
				
				CalculationResult = Eval(ProcedureName);
				
				If Cancel Then
					
					SetNavigationNumber(NavigationNumber + 1);
					
					Return;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	If NavigationRowCurrent.TimeConsumingOperation And Not IsMoveNext Then
		
		SetNavigationNumber(NavigationNumber - 1);
		Return;
	EndIf;
	
	// OnOpen handler
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then
		
		ProcedureName = "[HandlerName](Cancel, SkipPage, IsMoveNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.OnOpenHandlerName);
		
		Cancel = False;
		SkipPage = False;
		
		CalculationResult = Eval(ProcedureName);
		
		If Cancel Then
			
			SetNavigationNumber(NavigationNumber - 1);
			
			Return;
			
		ElsIf SkipPage Then
			
			If IsMoveNext Then
				
				SetNavigationNumber(NavigationNumber + 1);
				
				Return;
				
			Else
				
				SetNavigationNumber(NavigationNumber - 1);
				
				Return;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTimeConsumingOperationHandler()
	
	NavigationRowsCurrent = NavigationTable.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Raise NStr("vi = 'Chưa xác định trang để hiển thị.';
					|ru = 'Не определена страница для отображения.';
					|en = 'The page to display is not specified.'; fa = 'The page to display is not specified.';
					|it = 'Non è definita la pagina per visualizzazione.';
					|pl = 'Nie określono strony do odzwierciedlenia.';
					|tr = 'Gösterilecek sayfa tanımlanmamış.'");
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// TimeConsumingOperationProcessing handler.
	If Not IsBlankString(NavigationRowCurrent.TimeConsumingOperationHandlerName) Then
		
		ProcedureName = "[HandlerName](Cancel, GoToNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.TimeConsumingOperationHandlerName);
		
		Cancel = False;
		GoToNext = True;
		
		CalculationResult = Eval(ProcedureName);
		
		If Cancel Then
			
			If VersionDifferenceErrorOnGetData <> Undefined And VersionDifferenceErrorOnGetData.HasError Then
				
				ProcessVersionDifferenceError();
				Return;
				
			EndIf;
			
			SetNavigationNumber(NavigationNumber - 1);
			
			Return;
			
		ElsIf GoToNext Then
			
			SetNavigationNumber(NavigationNumber + 1);
			
			Return;
			
		EndIf;
		
	Else
		
		SetNavigationNumber(NavigationNumber + 1);
		
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Function NavigationTableNewRow(MainPageName,
		OnOpenHandlerName = "",
		TimeConsumingOperation = False,
		TimeConsumingOperationHandlerName = "")
		
	NewRow = NavigationTable.Add();
	
	NewRow.NavigationNumber = NavigationTable.Count();
	NewRow.MainPageName     = MainPageName;
	
	NewRow.OnNavigationToNextPageHandlerName = "";
	NewRow.OnSwitchToPreviousPageHandlerName = "";
	NewRow.OnOpenHandlerName      = OnOpenHandlerName;
	
	NewRow.TimeConsumingOperation = TimeConsumingOperation;
	NewRow.TimeConsumingOperationHandlerName = TimeConsumingOperationHandlerName;
	
	Return NewRow;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// OVERRIDABLE SECTION
////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS SECTION

&AtClient
Procedure RunMoveNext()
	
	GoToNext      = True;
	ExecuteMoveNext();
	
EndProcedure

&AtClient
Procedure ProcessVersionDifferenceError()
	
	Items.DataExchangeExecution.CurrentPage = Items.ExchangeCompletion;
	Items.ExchangeCompletionStatus.CurrentPage = Items.VersionsDifferenceError;
	Items.ActionsPanel.CurrentPage = Items.ActionsContinueCancel;
	Items.ContinueSync.DefaultButton = True;
	Items.DecorationVersionsDifferenceError.Title = VersionDifferenceErrorOnGetData.ErrorText;
	
	CheckVersionDifference = False;
	
EndProcedure

&AtClient
Procedure InitializeDataProcessorVariables()
	
	// Initialize data processor variables.
	ProgressPercent                   = 0;
	MessageFileIDInService = "";
	TimeConsumingOperationID     = "";
	ProgressAdditionalInformation             = "";
	TimeConsumingOperation                  = False;
	TimeConsumingOperationCompleted         = False;
	TimeConsumingOperationCompletedWithError = False;
	
EndProcedure

&AtServer
Procedure CheckWhetherTransferToNewExchangeIsRequired()
	
	ArrayOfMessages = GetUserMessages(True);
	
	If ArrayOfMessages = Undefined Then
		Return;
	EndIf;
	
	Count = ArrayOfMessages.Count();
	If Count = 0 Then
		Return;
	EndIf;
	
	Message      = ArrayOfMessages[Count-1];
	MessageText = Message.Text;
	
	// A subsystem ID is deleted from the message if necessary.
	If StrStartsWith(MessageText, "{MigrationToNewExchangeDone}") Then
		
		MessageData = Common.ValueFromXMLString(MessageText);
		
		If MessageData <> Undefined
			And TypeOf(MessageData) = Type("Structure") Then
			
			ExchangePlanName                    = MessageData.ExchangePlanNameToMigrateToNewExchange;
			ExchangePlanNodeCode                = MessageData.Code;
			NewDataSynchronizationSetting = ExchangePlans[ExchangePlanName].FindByCode(ExchangePlanNodeCode);
			
			BackgroundJobCompleteResult.AdditionalResultData.Insert("FormReopeningParameters",
				New Structure("NewDataSynchronizationSetting", NewDataSynchronizationSetting));
				
			BackgroundJobCompleteResult.AdditionalResultData.Insert("ForceCloseForm", True);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function EventLogFilterData(InfobaseNode)
	
	EventsToFilter = New Array;
	EventsToFilter.Add(DataExchangeServer.EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataImport));
	EventsToFilter.Add(DataExchangeServer.EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataExport));
	
	DataExchangeStatesImport = DataExchangeServer.DataExchangesStates(InfobaseNode, Enums.ActionsOnExchange.DataImport);
	DataExchangeStatesExport = DataExchangeServer.DataExchangesStates(InfobaseNode, Enums.ActionsOnExchange.DataExport);
	
	Result = New Structure;
	Result.Insert("EventLogEvent", EventsToFilter);
	Result.Insert("StartDate",    Min(DataExchangeStatesImport.StartDate, DataExchangeStatesExport.StartDate));
	Result.Insert("EndDate", Max(DataExchangeStatesImport.EndDate, DataExchangeStatesExport.EndDate));
	
	Return Result;
	
EndFunction

&AtServerNoContext
Procedure EndExecutingTimeConsumingOperation(JobID)
	TimeConsumingOperations.CancelJobExecution(JobID);
EndProcedure

&AtServerNoContext
Function UpdateInstallationRequired()
	
	Return DataExchangeServer.UpdateInstallationRequired();
	
EndFunction

&AtServerNoContext
Function IsRestartRequired()
	
	Return Catalogs.ExtensionsVersions.ExtensionsChangedDynamically();
	
EndFunction

&AtServerNoContext
Procedure CheckWhetherTheExchangeCanBeStarted(ExchangeNode, LockSet)
	
	Cancel = False;
	DataExchangeServer.CheckWhetherTheExchangeCanBeStarted(ExchangeNode, Cancel);
	
	LockSet = Not Cancel;
	
EndProcedure

&AtClient
Procedure CheckWhetherTheExchangeCanStartProcessingWaiting()
	
	CheckWhetherTheExchangeCanBeStarted(InfobaseNode, IsNodeLocked);
	
	If IsNodeLocked Then
		ChangeNavigationNumber(+1);
	Else
		AttachIdleHandler("CheckWhetherTheExchangeCanStartProcessingWaiting", 15, True);
	EndIf;
	
EndProcedure

&AtClient
Function Attachable_PageDataExchangeJobCheck_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	If HasNodeScheduledExchange Then
		
		If ValueIsFilled(ScenarioUsingInternalPublication) Then
			
			Template = NStr("vi = 'Việc đồng bộ cho nút ""%1"" đã được lập kế hoạch 
                           |trong kịch bản ""%2"".
                           |
                           |Hãy nhấn nút Tiếp theo để hủy bỏ việc thực hiện kịch bản
                           |và khởi động đồng bộ theo nút.';
                           |ru = 'Синхронизация для узла ""%1"" уже запланирована 
                           |в сценарии ""%2"".
                           |
                           |Нажмите Далее, чтобы отменить выполнение сценария
                           |и запустить синхронизацию по узлу.';
                           |en = 'Synchronization is already scheduled for node ""%1"" 
                           |in scenario ""%2"".
                           |
                           |Click Next to cancel the scenario
                           |and start synchronization by the node.'; fa = 'Synchronization is already scheduled for node ""%1"" 
                           |in scenario ""%2"".
                           |
                           |Click Next to cancel the scenario
                           |and start synchronization by the node.';
                           |it = 'La sincronizzazione del nodo ""%1"" è già programmata 
                           |nello scenario ""%2"".
                           |
                           |Cliccare Avanti per annullare l''esecuzione dello scenario
                           | e avviare la sincronizzazione del nodo.';
                           |pl = 'Synchronizacja dla węzła ""%1"" jest już zaplanowana 
                           |w scenariuszu ""%2"".
                           |
                           |Naciśnij Dalej, aby anulować wykonanie scenariusza
                           |i uruchomić synchronizację dla węzła.';
                           |tr = '""%1"" düğümü için senkronizasyon zaten
                           |""%2"" senaryosunda planlandı.
                           |
                           |Senaryonun yürütülmesini iptal etmek için
                           |ve düğümde senkronizasyonu başlatmak için İleri butonuna tıklayın.'");
			MessageText = StrTemplate(Template, String(InfobaseNode), String(ScenarioUsingInternalPublication));	

		Else
			
			Template = NStr("vi = 'Đối với nút ""%1"" đã thực hiện đồng bộ.
                           |
                           |Hãy nhấn Tiếp theo để ngắt đồng bộ hiện tại
                           |và khởi động lại đồng bộ';
                           |ru = 'Для узла ""%1"" уже выполняется синхронизация.
                           |
                           |Нажмите Далее, чтобы прервать текущую синхронизацию
                           |и запустить ее снова';
                           |en = 'Synchronization is already in progress for node ""%1"".
                           |
                           |Click Next to terminate the current synchronization
                           |and restart it'; fa = 'Synchronization is already in progress for node ""%1"".
                           |
                           |Click Next to terminate the current synchronization
                           |and restart it';
                           |it = 'La sincronizzazione del nodo ""%1"" è già in esecuzione.
                           |
                           |Cliccare Avanti per interrompere la sincronizzazione corrente 
                           | e riavviarla';
                           |pl = 'Dla węzła ""%1"" już trwa synchronizacja.
                           |
                           |Naciśnij Dalej, aby przerwać bieżącą synchronizację
                           |i uruchomić jej ponownie';
                           |tr = '""%1"" düğümü için senkronizasyon zaten yapılıyor.
                           |
                           |Geçerli senkronizasyonu durdurmak ve yeniden başlatmak için
                           |İleri butonuna tıklayın'");
			MessageText = StrTemplate(Template, String(InfobaseNode));

		EndIf;
		
		Items.StatusTaskQueued.Title = MessageText;
		
	Else
		
		SkipPage = True;
		
	EndIf;
		
	Return Undefined;
	
EndFunction

&AtServer
Procedure CancelQueueAndResumeOnServer()
	
	ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
	ModuleDataExchangeInternalPublication.CancelTaskQueue(
		InfobaseNode, 
	    ScenarioUsingInternalPublication,
		IDOfExchangeViaInternalPublication,
		CorrespondentDataArea);
	
EndProcedure

&AtClient
Procedure CancelQueueAndResume(Command)
	CancelQueueAndResumeOnServer();
	ExecuteMoveNext();
EndProcedure

&AtClient
Procedure EndSyncing(Command)

	CompleteSynchronizationOnServer(); 
	Close();

EndProcedure

&AtServer
Procedure CompleteSynchronizationOnServer()

	ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
	ModuleDataExchangeInternalPublication.HasNodeScheduledExchange(
		InfobaseNode, 
		ScenarioUsingInternalPublication,
		IDOfExchangeViaInternalPublication);
		
	CancelQueueAndResumeOnServer();
	
EndProcedure

&AtClient
Function Attachable_WaitingForSynchronizationToStart_ProcessingLongRunningOperation(Cancel, GoToNext)
	
	If Not IsNodeLocked Then
		GoToNext = False;
		
		AttachIdleHandler("CheckWhetherTheExchangeCanStartProcessingWaiting", 15, True);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataImportOnOpen(Cancel, SkipPage, IsMoveNext)
	
	If DataSyncDisabled Then
		SkipPage = True;
	Else
		InitializeDataProcessorVariables();
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataImportTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If DataSyncDisabled Then
		GoToNext = True;
	Else
		GoToNext = False;
		
		BackgroundJobCurrentAction = 1;
		RunBackgroundJobRunDataExchangeStartup(BackgroundJobCurrentAction, Cancel);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataExportOnOpen(Cancel, SkipPage, IsMoveNext)
	
	If DataSyncDisabled Then
		SkipPage = True;
	Else
		InitializeDataProcessorVariables();
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataExportTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	If DataSyncDisabled Then
		GoToNext = True;
	Else
		GoToNext = False;
		OnStartExportData(Cancel);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataExportTimeConsumingOperationProcessingCompletion(Cancel, GoToNext)
	
	If TimeConsumingOperationCompleted
		And Not TimeConsumingOperationCompletedWithError Then
		DataExchangeServerCall.RecordDataExportInTimeConsumingOperationMode(
			InfobaseNode,
			OperationStartDate);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure OnStartExportData(Cancel)

	If ExchangeBetweenSaaSApplications Then
		ContinueWait = True;
		OnStartExportDataAtServer(ContinueWait);
		
		If ContinueWait Then
			DataExchangeClient.InitIdleHandlerParameters(
				DataExportIdleHandlerParameters);
				
			AttachIdleHandler("OnWaitForExportData",
				DataExportIdleHandlerParameters.CurrentInterval, True);
		Else
			OnCompleteDataExport();
		EndIf;
	ElsIf ExchangeViaInternalPublication Then
		OnStartExportDataViaInternalPublicationAtServer();
		
		DataExchangeClient.InitIdleHandlerParameters(
			DataExportIdleHandlerParameters);

		AttachIdleHandler("OnWaitDataExportViaInternalPublication",
			DataExportIdleHandlerParameters.CurrentInterval, True);
	Else
		BackgroundJobCurrentAction = 2;
		RunBackgroundJobRunDataExchangeStartup(BackgroundJobCurrentAction, Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForExportData()
	
	ContinueWait = False;
	OnWaitForExportDataAtServer(DataExportHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(DataExportIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForExportData",
			DataExportIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteDataExport();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteDataExport()
	
	DataExported1 = False;
	ErrorMessage = "";
	
	OnCompleteDataUnloadAtServer(DataExportHandlerParameters, DataExported1, ErrorMessage);
	
	TimeConsumingOperationCompleted = True;
	TimeConsumingOperationCompletedWithError = Not DataExported1;
	HasErrors = HasErrors Or Not DataExported1;
	OutputErrorDescriptionToUser = True;
	ErrorMessageToUser = ErrorMessage;
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtServer
Procedure OnStartExportDataAtServer(ContinueWait)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardSaaS();
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ExportSettings1 = New Structure;
	ExportSettings1.Insert("Peer",               InfobaseNode);
	ExportSettings1.Insert("CorrespondentDataArea", CorrespondentDataArea);
	
	DataExportHandlerParameters = Undefined;
	ModuleInteractiveExchangeWizard.OnStartExportData(ExportSettings1,
		DataExportHandlerParameters, ContinueWait);
	
EndProcedure
	
&AtServerNoContext
Procedure OnWaitForExportDataAtServer(HandlerParameters, ContinueWait)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardSaaS();
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		ContinueWait = False;
	EndIf;
	
	ModuleInteractiveExchangeWizard.OnWaitForExportData(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnCompleteDataUnloadAtServer(HandlerParameters, DataExported1, ErrorMessage)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardSaaS();
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		DataExported1 = False;
		Return;
	EndIf;
	
	CompletionStatus = Undefined;
	
	ModuleInteractiveExchangeWizard.OnCompleteDataExport(HandlerParameters, CompletionStatus);
	HandlerParameters = Undefined;
		
	If CompletionStatus.Cancel Then
		DataExported1 = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
		Return;
	Else
		DataExported1 = CompletionStatus.Result.DataExported1;
		
		If Not DataExported1 Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
			Return;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer 
Procedure OnStartExportDataViaInternalPublicationAtServer()
	
	ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
	ModuleDataExchangeInternalPublication.RunDataExchangeManually(InfobaseNode, ParametersOfExchangeViaInternalPublication);
	
EndProcedure	

&AtClient
Procedure OnWaitDataExportViaInternalPublication()
	
	ContinueWait = False;
	OnWaitDataExportViaInternalPublicationAtServer(ParametersOfExchangeViaInternalPublication, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(DataExportIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitDataExportViaInternalPublication",
			DataExportIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteDataExportViaInternalPublication();
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure OnWaitDataExportViaInternalPublicationAtServer(ExchangeParameters, ContinueWait)
	
	ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
	ModuleDataExchangeInternalPublication.OnWaitForExportData(ExchangeParameters, ContinueWait);
	
EndProcedure

&AtClient
Procedure OnCompleteDataExportViaInternalPublication()
		
	HasErrors = HasErrors Or ParametersOfExchangeViaInternalPublication.Cancel;
		
	OutputErrorDescriptionToUser = True;
	ErrorMessageToUser = ParametersOfExchangeViaInternalPublication.ErrorMessage;
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Function Attachable_ExchangeCompletionOnOpen(Cancel, SkipPage, IsMoveNext)
	
	Items.ActionsPanel.CurrentPage = Items.ActionsClose;
	Items.FormClose.DefaultButton = True;
	
	ExchangeCompletedWithErrorPage = ?(DataExchangeAdministrationRoleAssigned,
		Items.ExchangeCompletedWithErrorForAdministrator,
		Items.ExchangeCompletedWithError);
	
	If DataSyncDisabled Then
		
		Items.ExchangeCompletionStatus.CurrentPage = Items.ExchangeCompletedWithConnectionError;
		
	ElsIf HasErrors Then
		
		If UpdateRequired Or UpdateInstallationRequired() Then
			
			If RoleAvailableFullAccess Then 
				Items.ActionsPanel.CurrentPage = Items.ActionsInstallClose;
				Items.InstallUpdate.DefaultButton = True;
			EndIf;
			
			Items.ExchangeCompletionStatus.CurrentPage = Items.ExchangeCompletedWithErrorUpdateRequired;
			
			Items.PanelUpdateRequired.CurrentPage = ?(RoleAvailableFullAccess, 
				Items.UpdateRequiredFullAccess, Items.UpdateRequiredRestrictedAccess);
				
			Items.UpdateRequiredTextFullAccess.Title = StringFunctionsClientServer.SubstituteParametersToString(
				Items.UpdateRequiredTextFullAccess.Title, PeerInfobaseName);
				
			Items.UpdateRequiredTextRestrictedAccess.Title = StringFunctionsClientServer.SubstituteParametersToString(
				Items.UpdateRequiredTextRestrictedAccess.Title, PeerInfobaseName);
				
		ElsIf IsRestartRequired() Then
				
			Items.ExchangeCompletionStatus.CurrentPage = Items.ExchangeIsCompletedWithErrorRebootIsRequired;
			Items.ActionsPanel.CurrentPage = Items.ActionsReload;
				
		ElsIf ErrorAssigningIDForNode Then
			
			Items.ExchangeCompletionStatus.CurrentPage = Items.ErrorIDAssignmentForNode;			
			
		Else
				
			Items.ExchangeCompletionStatus.CurrentPage = ExchangeCompletedWithErrorPage;
			
			If OutputErrorDescriptionToUser Then
				CommonClient.MessageToUser(ErrorMessageToUser);
			EndIf;
			
		EndIf;
		
	Else
		
		Items.ExchangeCompletionStatus.CurrentPage = Items.ExchangeSucceeded;
		
	EndIf;
	
	// Updating all opened dynamic lists.
	DataExchangeClient.RefreshAllOpenDynamicLists();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ExchangeCompletionTimeConsumingOperationProcessing(Cancel, GoToNext)
	
	GoToNext = False;
	
	Notify("DataExchangeCompleted");
	
	If CloseOnSynchronizationDone
		And Not DataSyncDisabled
		And Not HasErrors Then
		
		Close();
	EndIf;
	
	Return Undefined;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Exchange pages via a Web service

&AtClient
Procedure AuthorizationCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Close();
	EndIf;
	
	// Connection test?
	
	ExecuteMoveNext();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// BACKGROUND TASK PROCESSING SECTION

&AtClient
Procedure RunBackgroundTaskDownloadFileReceivedFromInternet(Action, Cancel)
	
	JobParameters = InitializeTaskParameters(Cancel);
	
	Result = RunBackgroundTaskToDownloadFileReceivedFromInternetAtServer(JobParameters, VersionDifferenceErrorOnGetData, CheckVersionDifference);
	
	If Result = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	If Result.Status = "Running" Then
		
		StartWaitingForBackgroundJobToEnd(Result);
		
	Else
		BackgroundJobCompleteResult = Result;
		AttachIdleHandler("BackgroundJobExecutionResult", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure RunBackgroundJobRunDataExchangeStartup(Action, Cancel)
	
	JobParameters = InitializeTaskParameters(Cancel);
	
	Result = RunBackgroundJobRunDataExchangeAtServer(JobParameters, VersionDifferenceErrorOnGetData, CheckVersionDifference);
	
	If Result = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	If Result.Status = "Running" Then
		
		StartWaitingForBackgroundJobToEnd(Result);
		
	Else
		BackgroundJobCompleteResult = Result;
		AttachIdleHandler("BackgroundJobExecutionResult", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Function InitializeTaskParameters(Cancel)
	
	JobParameters = New Structure;
	JobParameters.Insert("Cancel",                               Cancel);
	JobParameters.Insert("InfobaseNode",              InfobaseNode);
	JobParameters.Insert("ExecuteImport1",                   BackgroundJobCurrentAction = 1);
	JobParameters.Insert("ExecuteExport2",                   BackgroundJobCurrentAction = 2);
	JobParameters.Insert("TransportID",             TransportID);
	JobParameters.Insert("AuthenticationData",                AuthenticationData);
	
	JobParameters.Insert("TimeConsumingOperation",                  TimeConsumingOperation);
	JobParameters.Insert("TimeConsumingOperationID",     TimeConsumingOperationID);
	JobParameters.Insert("MessageFileIDInService", MessageFileIDInService);
	
	Return JobParameters;
	
EndFunction

&AtClient
Procedure StartWaitingForBackgroundJobToEnd(Result)
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow  = False;
	IdleParameters.OutputMessages     = True;
	
	If BackgroundJobUseProgress Then
		IdleParameters.OutputProgressBar     = True;
		IdleParameters.ExecutionProgressNotification = New CallbackDescription("BackgroundJobExecutionProgress", ThisObject);
		IdleParameters.Interval                       = 1;
	EndIf;
	
	CallbackOnCompletion = New CallbackDescription("BackgroundJobCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure BackgroundJobCompletion(Result, AdditionalParameters) Export
	
	BackgroundJobCompleteResult = Result;
	BackgroundJobExecutionResult();
	
EndProcedure

&AtClient
Procedure BackgroundJobExecutionProgress(Progress, AdditionalParameters) Export
	
	If Progress = Undefined Then
		Return;
	EndIf;
	
	If Progress.Progress <> Undefined Then
		ProgressStructure      = Progress.Progress;
		
		AdditionalProgressParameters = Undefined;
		If Not ProgressStructure.Property("AdditionalParameters", AdditionalProgressParameters) Then
			Return;
		EndIf;
		
		If Not AdditionalProgressParameters.Property("DataExchange") Then
			Return;
		EndIf;
		
		ProgressPercent       = ProgressStructure.Percent;
		ProgressAdditionalInformation = ProgressStructure.Text;
	EndIf;
	
EndProcedure

&AtClient
Procedure BackgroundJobExecutionResult()
	
	BackgroundJobGetResultAtServer();
	TimeConsumingOperationCompletion();
	
EndProcedure

&AtClient
Procedure TimeConsumingOperationCompletion()
	
	If BackgroundJobUseProgress Then
		ProgressPercent       = 100;
		ProgressAdditionalInformation = "";
	EndIf;
	
	If TimeConsumingOperationCompletedWithError Then
		MessageFileIDInService = "";
		DataExchangeServerCall.WriteExchangeFinishWithError(
			InfobaseNode,
			?(BackgroundJobCurrentAction = 1, "DataImport", "DataExport"),
			OperationStartDate,
			ErrorMessage);
	Else
		
		// If the data has been obtained from a web app for a while,
		// import the file with data to the infobase.
		If BackgroundJobCurrentAction = 1 
			And ValueIsFilled(MessageFileIDInService) Then
				
			RunBackgroundTaskDownloadFileReceivedFromInternet(BackgroundJobCurrentAction, False);
				
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(MessageFileIDInService) Then
		AfterCompleteBackgroundJob();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCompleteBackgroundJob()
	
	// Data exchange has been updated to a later version. Close the form and open it with the new parameters.
	If BackgroundJobCompleteResult.AdditionalResultData.Property("ForceCloseForm") 
		And BackgroundJobCompleteResult.AdditionalResultData.ForceCloseForm Then
		FormReopeningParameters = BackgroundJobCompleteResult.AdditionalResultData.FormReopeningParameters;
		Close();
	EndIf;
	
	// Go further with a one second delay to display the progress bar 100%.
	AttachIdleHandler("RunMoveNext", 0.1, True);
	
EndProcedure

&AtServer
Function RunBackgroundTaskToDownloadFileReceivedFromInternetAtServer(Val JobParameters, VersionDifferenceErrorOnGetData, CheckVersionDifference)
	
	ExecutionParameters = InitializeExecutionParameters(JobParameters, CheckVersionDifference);
	
	OperationStartDate = CurrentSessionDate();
	JobParameters.Insert("OperationStartDate", OperationStartDate);
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeExecution.ImportFileDownloadedFromInternet",
		JobParameters,
		ExecutionParameters);
		
	IDBackgroundJob  = Result.JobID;
	BackgroundJobStorageAddress = Result.ResultAddress;
	
	Return Result;
	
EndFunction

&AtServer
Function RunBackgroundJobRunDataExchangeAtServer(Val JobParameters, VersionDifferenceErrorOnGetData, CheckVersionDifference)
	
	ExecutionParameters = InitializeExecutionParameters(JobParameters, CheckVersionDifference);
	
	OperationStartDate = CurrentSessionDate();
	JobParameters.Insert("OperationStartDate", OperationStartDate);
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.DataExchangeExecution.StartDataExchangeExecution",
		JobParameters,
		ExecutionParameters);
		
	IDBackgroundJob  = Result.JobID;
	BackgroundJobStorageAddress = Result.ResultAddress;
	
	Return Result;
	
EndFunction

&AtServer
Function InitializeExecutionParameters(JobParameters, CheckVersionDifference)
	
	If JobParameters.ExecuteImport1 Then
		
		If CheckVersionDifference Then
			DataExchangeServer.InitializeVersionDifferenceCheckParameters(CheckVersionDifference);
		EndIf;
		
		DescriptionTemplate = NStr("vi = 'Đang kết nhập dữ liệu từ %1';
									|ru = 'Выполняется загрузка данных из %1';
									|en = 'Importing data from %1'; fa = 'Importing data from %1';
									|it = 'È in corso il download dati da %1';
									|pl = 'Jest wykonywane pobieranie danych z %1';
									|tr = '%1''den veriler içe aktarılıyor'");
		
	Else
		DescriptionTemplate = NStr("vi = 'Đang kết xuất dữ liệu vào %1';
									|ru = 'Выполняется выгрузка данных в %1';
									|en = 'Exporting data to %1'; fa = 'Exporting data to %1';
									|it = 'È in corso l''upload dati in %1';
									|pl = 'Jest wykonywane przesyłanie danych do %1';
									|tr = 'Veriler %1''e aktarılıyor'");
	EndIf;
	
	JobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		DescriptionTemplate, JobParameters.InfobaseNode);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.WaitCompletion = 0;
	
	Return ExecutionParameters;
	
EndFunction


&AtServer
Procedure BackgroundJobGetResultAtServer()
	
	If BackgroundJobCompleteResult = Undefined Then
		BackgroundJobCompleteResult = New Structure;
		BackgroundJobCompleteResult.Insert("Status", Undefined);
	EndIf;
	
	BackgroundJobCompleteResult.Insert("AdditionalResultData", New Structure());
	
	ErrorMessage = "";
	
	StandardErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể thực hiện %1. Chi tiết xem trong nhật ký sự kiện';
			|ru = 'Не удалось выполнить %1. Подробности см. в журнале регистрации';
			|en = 'Cannot %1. See the event log for details.'; fa = 'Cannot %1. See the event log for details.';
			|it = 'Impossibile eseguire %1. Vedi il registro per i dettagli';
			|pl = 'Nie udało się wykonać %1. Szczegóły zobacz w dzienniku rejestracji';
			|tr = '""%1"" çalıştırılamadı. Ayrıntılar için olay günlüğüne bakın.'"),
		?(BackgroundJobCurrentAction = 1, NStr("vi = 'nhận dữ liệu';
												|ru = 'получение данных';
												|en = 'receive data'; fa = 'receive data';
												|it = 'acquisizione dei dati';
												|pl = 'pobieranie danych';
												|tr = 'veri alınıyor'"), NStr("vi = 'gửi dữ liệu';
																			|ru = 'отправку данных';
																			|en = 'send data'; fa = 'send data';
																			|it = 'invio dei dati';
																			|pl = 'wysyłanie danych';
																			|tr = 'veriyi gönder'")));
	
	If BackgroundJobCompleteResult.Status = "Error" Then
		ErrorMessage = BackgroundJobCompleteResult.DetailErrorDescription;
		SetPrivilegedMode(True);
		DataExchangeServer.WriteExchangeFinishWithError(
			InfobaseNode,
			?(BackgroundJobCurrentAction = 1, "DataImport", "DataExport"),
			OperationStartDate,
			ErrorMessage);
		SetPrivilegedMode(False);
		
		ErrorText = NStr("vi = 'Đã tìm thấy trùng lặp trong tùy chỉnh đồng bộ dữ liệu';
						|ru = 'Обнаружено дублирование настроек синхронизации данных';
						|en = 'Duplicate data synchronization settings are detected'; fa = 'Duplicate data synchronization settings are detected';
						|it = 'È stato rilevato un duplicato delle impostazioni di sincronizzazione dati';
						|pl = 'Wykryto duplikowanie ustawień synchronizacji danych';
						|tr = 'Veri senkronizasyonu ayarlarının yinelenmesi algılandı'", Common.DefaultLanguageCode()); 
		If Not IsBlankString(ErrorText) And StrFind(ErrorMessage, ErrorText) > 0 Then
			ErrorAssigningIDForNode = True;	
		EndIf;
				
	Else
		
		BackgroundExecutionResult = GetFromTempStorage(BackgroundJobStorageAddress);
		
		If BackgroundExecutionResult = Undefined Then
			ErrorMessage = StandardErrorPresentation;
		Else
			
			If BackgroundExecutionResult.ExecuteImport1 Then
				
				// Data on exchange rule version difference.
				VersionDifferenceErrorOnGetData = DataExchangeServer.VersionDifferenceErrorOnGetData();
				
				If VersionDifferenceErrorOnGetData <> Undefined
					And VersionDifferenceErrorOnGetData.HasError = True Then
					ErrorMessage = VersionDifferenceErrorOnGetData.ErrorText;
				EndIf;
				
				// Checking the transition to a new data exchange.
				CheckWhetherTransferToNewExchangeIsRequired();
				
				If BackgroundJobCompleteResult.AdditionalResultData.Property("FormReopeningParameters") Then
					Return;
				EndIf;
				
			EndIf;
			
			If BackgroundExecutionResult.Cancel And Not ValueIsFilled(ErrorMessage) Then
				ErrorMessage = StandardErrorPresentation;
			EndIf;
			
			FillPropertyValues(
				ThisObject,
				BackgroundExecutionResult,
				"TimeConsumingOperation, TimeConsumingOperationID, MessageFileIDInService");
			
			DeleteFromTempStorage(BackgroundJobStorageAddress);
			
		EndIf;
		
		BackgroundJobStorageAddress = Undefined;
		IDBackgroundJob  = Undefined;
		
	EndIf;
	
	// If errors occurred during data synchronization, record them.
	If ValueIsFilled(ErrorMessage) Then
		
		// If a long-running operation is started in the peer infobase, it must be completed.
		If Not TimeConsumingOperationCompleted Then
			EndExecutingTimeConsumingOperation(TimeConsumingOperationID);
		EndIf;
		
		TimeConsumingOperationCompleted         = True;
		TimeConsumingOperationCompletedWithError = True;
		
		HasErrors = True;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// TRANSITION INITIALIZATION SECTION

&AtServer
Procedure FillNavigationTable()
	
	NavigationTable.Clear();
	
	NavigationTableNewRow("PageDataSynchronizationUnavailable", "");
	
	If ExchangeViaInternalPublication Then
		NavigationTableNewRow("PageCheckExchangeTasks", "Attachable_PageDataExchangeJobCheck_OnOpen");	
	EndIf;

	NavigationTableNewRow("WaitForSynchronizationToStart", "", True, "Attachable_WaitingForSynchronizationToStart_ProcessingLongRunningOperation");
	
	// Initializing the current exchange scenario.
	If HasErrors Then
		
		NavigationTableNewRow("ExchangeCompletion", "Attachable_ExchangeCompletionOnOpen");
		
	Else
		
		If BackgroundJobUseProgress Then
			PageNameSynchronizationImport = "DataSynchronizationWaitProgressBarImport";
			PageNameSynchronizationExport = "DataSynchronizationWaitProgressBarExport";
		Else
			PageNameSynchronizationImport = "DataSynchronizationWait";
			PageNameSynchronizationExport = "DataSynchronizationWait";
		EndIf;
		
		If ExchangeBetweenSaaSApplications Or ExchangeViaInternalPublication Then
			// Send and receive.
			NavigationTableNewRow(PageNameSynchronizationExport, "Attachable_DataExportOnOpen", True, "Attachable_DataExportTimeConsumingOperationProcessing");
			NavigationTableNewRow(PageNameSynchronizationExport, , True, "Attachable_DataExportTimeConsumingOperationProcessingCompletion");
		Else
						
			If ExecuteDataSending Then
				// Send.
				NavigationTableNewRow(PageNameSynchronizationExport, "Attachable_DataExportOnOpen", True, "Attachable_DataExportTimeConsumingOperationProcessing");
				NavigationTableNewRow(PageNameSynchronizationExport, , True, "Attachable_DataExportTimeConsumingOperationProcessingCompletion");
			EndIf;
			
			// Receive.
			NavigationTableNewRow(PageNameSynchronizationImport, "Attachable_DataImportOnOpen", True, "Attachable_DataImportTimeConsumingOperationProcessing");
			// Send.
			NavigationTableNewRow(PageNameSynchronizationExport, "Attachable_DataExportOnOpen", True, "Attachable_DataExportTimeConsumingOperationProcessing");
			NavigationTableNewRow(PageNameSynchronizationExport, , True, "Attachable_DataExportTimeConsumingOperationProcessingCompletion");
			
		EndIf;
		
		// Complete.
		NavigationTableNewRow("ExchangeCompletion", "Attachable_ExchangeCompletionOnOpen", True, "Attachable_ExchangeCompletionTimeConsumingOperationProcessing");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationErrorIDAssignmentForNodeURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenForm("CommonForm.AdditionalDetails", New Structure("Title,TemplateName",
		NStr("vi = 'Đặt mã cho nút định trước';
			|ru = 'Установка кода для предопределенного узла';
			|en = 'Set predefined node code'; fa = 'Set predefined node code';
			|it = 'Impostazione del codice per il nodo predefinito';
			|pl = 'Ustawienie kodu dla predefiniowanego węzła';
			|tr = 'Öntanımlı ünite için kod ayarlaması'"), "InstructionToSetCodeForPredefinedNode_en"));

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SECTION OF TRANSITION EVENT HANDLERS

////////////////////////////////////////////////////////////////////////////////
// General Exchange Pages

&AtClient
Procedure StatusSynchronizationUnavailabilityURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	If FormattedStringURL = "ExpectSynchronizationCapability" Then
		
		Step = NavigationNumber + 1;
		SetNavigationNumber(Step);
		
	EndIf;
	
EndProcedure



#EndRegion