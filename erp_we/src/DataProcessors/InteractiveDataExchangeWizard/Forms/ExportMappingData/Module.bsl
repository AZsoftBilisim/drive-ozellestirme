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
	
	CheckCanUseForm(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	InitializeFormAttributes();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetNavigationNumber(1);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If InitialExport Then
		WarningText = NStr("vi = 'Hủy bỏ kết xuất dữ liệu ban đầu?';
							|ru = 'Отменить начальную выгрузку данных?';
							|en = 'Do you want to cancel the initial data export?'; fa = 'Do you want to cancel the initial data export?';
							|it = 'Annullare upload iniziale dei dati?';
							|pl = 'Anulować początkowe ładowanie danych?';
							|tr = 'Verilerin ilk dışa aktarımı iptal edilsin mi?'");
	Else
		WarningText = NStr("vi = 'Hủy kết xuất dữ liệu?';
							|ru = 'Отменить выгрузку данных?';
							|en = 'Do you want to cancel the data export?'; fa = 'Do you want to cancel the data export?';
							|it = 'Annullare upload dei dati?';
							|pl = 'Anulować ładowanie danych?';
							|tr = 'Verilerin dışa aktarımı iptal edilsin mi?'");
	EndIf;
	
	CommonClient.ShowArbitraryFormClosingConfirmation(
		ThisObject, Cancel, Exit, WarningText, "ForceCloseForm");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	Notify("DataExchangeCompleted");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NextCommand(Command)
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure BackCommand(Command)
	
	ChangeNavigationNumber(-1);
	
EndProcedure

&AtClient
Procedure DoneCommand(Command)
	
	CloseParameter = Undefined;
	If DataExportCompleted Then
		CloseParameter = ExchangeNode;
	EndIf;
	
	ForceCloseForm = True;
	Close(CloseParameter);
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure ConnectionSettings(Command)
	
	ClosingNotification1 = New CallbackDescription("ConnectionSettingsCompletion", ThisObject);
	
	FormParameters = New Structure("Peer", ExchangeNode);
	
	OpenForm("Catalog.ExchangeMessageTransportSettings.Form.TransportSettingPanel",
		FormParameters,,,,, ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

#Region ConnectionParametersCheck

&AtClient
Procedure OnStartTestConnection()
	
	ContinueWait = True;
	
	OnStartTestConnectionAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitIdleHandlerParameters(
			ConnectionCheckIdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForTestConnection",
			ConnectionCheckIdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteConnectionTest();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForTestConnection()
	
	ContinueWait = False;
	OnWaitConnectionCheckAtServer(ConnectionCheckHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(ConnectionCheckIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForTestConnection",
			ConnectionCheckIdleHandlerParameters.CurrentInterval, True);
	Else
		ConnectionCheckIdleHandlerParameters = Undefined;
		OnCompleteConnectionTest();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteConnectionTest()
	
	OnCompleteConnectionTestAtServer();
	
	If TransportSettingAvailable
		And Not ConnectionCheckCompleted Then
		SetNavigationNumber(2); // Set up connection.
	Else
		ChangeNavigationNumber(+1);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartTestConnectionAtServer(ContinueWait)
	
	ConnectionSettings = New Structure;
	ConnectionSettings.Insert("Peer", ExchangeNode);
	ConnectionSettings.Insert("TransportID", TransportID);
	ConnectionSettings.Insert("TransportSettings", TransportSettings);
	ConnectionSettings.Insert("ExchangePlanName", DataExchangeCached.GetExchangePlanName(ExchangeNode));
	ConnectionSettings.Insert("CorrespondentExchangePlanName", 
		DataExchangeCached.GetNameOfCorrespondentExchangePlan(ExchangeNode));
		
	ConnectionSettings.Insert("ExchangeSetupOption", "");
	ConnectionSettings.Insert("AuthenticationData", AuthenticationData);
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	ModuleSetupWizard.OnStartTestConnection(
		ConnectionSettings, ConnectionCheckHandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitConnectionCheckAtServer(HandlerParameters, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	ContinueWait = False;
	ModuleSetupWizard.OnWaitForTestConnection(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteConnectionTestAtServer()
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	CompletionStatus = Undefined;
	ModuleSetupWizard.OnCompleteConnectionTest(
		ConnectionCheckHandlerParameters, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		ConnectionCheckCompleted = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		ConnectionCheckCompleted = CompletionStatus.Result.ConnectionIsSet
			And CompletionStatus.Result.ConnectionAllowed;
			
		If Not ConnectionCheckCompleted
			And Not IsBlankString(CompletionStatus.Result.ErrorMessage) Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ConnectionSettingsCompletion(Result, AdditionalParameters) Export
	
	InitializeTransportParameters();
	
EndProcedure

#EndRegion

#Region ChangeRecords

&AtClient
Procedure OnStartChangeRegistration()
	
	ContinueWait = True;
	OnStartChangesRegistrationAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitIdleHandlerParameters(
			DataRegistrationIdleHandlerParametersForInitialExport);
			
		AttachIdleHandler("OnWaitForChangeRegistration",
			DataRegistrationIdleHandlerParametersForInitialExport.CurrentInterval, True);
	Else
		OnCompleteChangeRegistration();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForChangeRegistration()
	
	ContinueWait = False;
	OnWaitForChangeRegistrationAtServer(DataRegistrationHandlerParametersForInitialExport, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(DataRegistrationIdleHandlerParametersForInitialExport);
		
		AttachIdleHandler("OnWaitForChangeRegistration",
			DataRegistrationIdleHandlerParametersForInitialExport.CurrentInterval, True);
	Else
		DataRegistrationIdleHandlerParametersForInitialExport = Undefined;
		OnCompleteChangeRegistration();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteChangeRegistration()
	
	OnCompleteChangeRegistrationAtServer();
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtServer
Procedure OnStartChangesRegistrationAtServer(ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	RegistrationSettings = New Structure;
	RegistrationSettings.Insert("ExchangeNode", ExchangeNode);
	
	ModuleSetupWizard.OnStartRecordDataForInitialExport(
		RegistrationSettings, DataRegistrationHandlerParametersForInitialExport, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitForChangeRegistrationAtServer(HandlerParameters, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	ContinueWait = False;
	ModuleSetupWizard.OnWaitForRecordDataForInitialExport(
		HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteChangeRegistrationAtServer()
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	CompletionStatus = Undefined;
	ModuleSetupWizard.OnCompleteDataRecordingForInitialExport(
		DataRegistrationHandlerParametersForInitialExport, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		ChangesRegistrationCompleted = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		ChangesRegistrationCompleted = CompletionStatus.Result.DataRegistered;
			
		If Not ChangesRegistrationCompleted
			And Not IsBlankString(CompletionStatus.Result.ErrorMessage) Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region DataExport

&AtClient
Procedure OnStartExportDataForMapping()
	
	ProgressPercent = 0;
	
	ContinueWait = True;
	OnStartDataExportToMapAtServer(ContinueWait);
	
	If ContinueWait Then
		
		If IsExchangeWithApplicationInService Then
			DataExchangeClient.InitIdleHandlerParameters(
				MappingDataExportIdleHandlerParameters);
				
			AttachIdleHandler("OnWaitForExportDataForMapping",
				MappingDataExportIdleHandlerParameters.CurrentInterval, True);
		Else
			CallbackOnCompletion = New CallbackDescription("ExportMappingDataCompletion", ThisObject);
		
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
			IdleParameters.OutputIdleWindow = False;
			IdleParameters.OutputProgressBar = UseProgress;
			IdleParameters.ExecutionProgressNotification = New CallbackDescription("DataExportForMappingProgress", ThisObject);
			
			TimeConsumingOperationsClient.WaitCompletion(MappingDataExportHandlerParameters.BackgroundJob,
				CallbackOnCompletion, IdleParameters);
		EndIf;
			
	Else
			
		OnCompleteDataExportForMapping();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForExportDataForMapping()
	
	ContinueWait = False;
	OnWaitDataExportToMapAtServer(MappingDataExportHandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(MappingDataExportIdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForExportDataForMapping",
			MappingDataExportIdleHandlerParameters.CurrentInterval, True);
	Else
		MappingDataExportIdleHandlerParameters = Undefined;
		OnCompleteDataExportForMapping();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteDataExportForMapping()
	
	ProgressPercent = 100;
	
	OnCompleteDataExportForMappingAtServer();
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure ExportMappingDataCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		OnCompleteDataExportForMapping();
	EndIf;
	
EndProcedure

&AtClient
Procedure DataExportForMappingProgress(Progress, AdditionalParameters) Export
	
	If Progress = Undefined Then
		Return;
	EndIf;
	
	ProgressStructure = Progress.Progress;
	If ProgressStructure <> Undefined Then
		ProgressPercent = ProgressStructure.Percent;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartDataExportToMapAtServer(ContinueWait)
	
	ExportSettings1 = New Structure;
	
	If IsExchangeWithApplicationInService Then
		ExportSettings1.Insert("Peer", ExchangeNode);
		ExportSettings1.Insert("CorrespondentDataArea", CorrespondentDataArea);
		
		ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardSaaS();
	Else
		ExportSettings1.Insert("ExchangeNode", ExchangeNode);
		ExportSettings1.Insert("TransportID", TransportID);
		ExportSettings1.Insert("TransportSettings", TransportSettings);
		ExportSettings1.Insert("AuthenticationData", AuthenticationData);
		
		ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizard();
	EndIf;
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ModuleInteractiveExchangeWizard.OnStartExportDataForMapping(
		ExportSettings1, MappingDataExportHandlerParameters, ContinueWait);
	
EndProcedure
	
&AtServerNoContext
Procedure OnWaitDataExportToMapAtServer(HandlerParameters, ContinueWait)
	
	ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardSaaS();
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ModuleInteractiveExchangeWizard.OnWaitForExportDataForMapping(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteDataExportForMappingAtServer()
	
	If IsExchangeWithApplicationInService Then
		ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizardSaaS();
	Else
		ModuleInteractiveExchangeWizard = DataExchangeServer.ModuleInteractiveDataExchangeWizard();
	EndIf;
	
	If ModuleInteractiveExchangeWizard = Undefined Then
		DataExportCompleted = False;
		Return;
	EndIf;
	
	CompletionStatus = Undefined;
	
	ModuleInteractiveExchangeWizard.OnCompleteDataExportForMapping(
		MappingDataExportHandlerParameters, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		DataExportCompleted = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		DataExportCompleted = CompletionStatus.Result.DataExported1;
			
		If Not DataExportCompleted
			And Not IsBlankString(CompletionStatus.Result.ErrorMessage) Then
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormInitializationOnCreate

&AtServer
Procedure CheckCanUseForm(Cancel = False)
	
	// It is required to pass the parameters of data export execution.
	If Not Parameters.Property("ExchangeNode") Then
		MessageText = NStr("vi = 'Biểu mẫu không được dùng để sử dụng trực tiếp.';
							|ru = 'Форма не предназначена для непосредственного использования.';
							|en = 'The form cannot be opened manually.'; fa = 'The form cannot be opened manually.';
							|it = 'Il modello non è destinato per l''uso diretto.';
							|pl = 'Formularz nie jest przeznaczony dla bezpośredniego użycia.';
							|tr = 'Form doğrudan kullanım için uygun değildir.'");
		Common.MessageToUser(MessageText, , , , Cancel);
		Return;
	EndIf;
	
	If DataExchangeCached.IsDistributedInfobaseNode(Parameters.ExchangeNode) Then
		MessageText = NStr("vi = 'Không hỗ trợ kết xuất ban đầu đối với các nút cơ sở thông tin phân tán.';
							|ru = 'Начальная выгрузка не поддерживается для узлов распределенных информационных баз.';
							|en = 'Initial export is not supported for distributed infobase nodes.'; fa = 'Initial export is not supported for distributed infobase nodes.';
							|it = 'Upload iniziale non è supportato per i nodi dei database informatici distribuiti.';
							|pl = 'Początkowe ładowanie nie jest obsługiwane dla węzłów rozprowadzonych baz informacyjnych.';
							|tr = 'Dağıtılmış infobase''lerin üniteleri için ilk dışa aktarma desteklenmiyor.'");
		Common.MessageToUser(MessageText, , , , Cancel);
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeFormAttributes()
	
	ExchangeNode = Parameters.ExchangeNode;
	
	If Parameters.Property("InitialExport") Then
		DataExportMode = "InitialExport";
		InitialExport = True;
	Else
		DataExportMode = "StandardExport";
	EndIf;
	
	ApplicationDescription = String(ExchangeNode);
	
	Parameters.Property("IsExchangeWithApplicationInService", IsExchangeWithApplicationInService);
	Parameters.Property("CorrespondentDataArea",  CorrespondentDataArea);
	
	AuthenticationData = ExchangeMessagesTransport.DataSynchronizationPassword(ExchangeNode);
	
	InitializeTransportParameters();
		
	SetApplicationDescriptionInFormLabels();
	
EndProcedure

&AtServer
Procedure InitializeTransportParameters()
	
	TransportID = ExchangeMessagesTransport.DefaultTransport(ExchangeNode);
	UseProgress = ExchangeMessagesTransport.TransportParameter(TransportID, "UseProgress");
	
	PromptForPassword              = False;
	ConnectionCheckCompleted = False;
	DataExportCompleted      = False;
	TransportSettingAvailable  = False;
	
	PassiveMode = ExchangeMessagesTransport.TransportParameter(ExchangeNode, "PassiveMode");
	
	If PassiveMode Then
		
		ConnectionCheckCompleted = True;
		DataExportCompleted      = True;
	
	EndIf;
	
	FillNavigationTable();
	
EndProcedure

&AtServer
Procedure SetApplicationDescriptionInFormLabels()
	
	Items.PasswordLabelDecoration.Title = 
		StrTemplate(Items.PasswordLabelDecoration.Title, ApplicationDescription);
	
	Items.DataExportNoProgressBarLabelDecoration.Title = 
		StrTemplate(Items.DataExportNoProgressBarLabelDecoration.Title, ApplicationDescription);
	
	Items.DataExportProgressLabelDecoration.Title = 
		StrTemplate(Items.DataExportProgressLabelDecoration.Title, ApplicationDescription);
	
	Items.ExportCompletedLabelDecoration.Title =
		StrTemplate(Items.ExportCompletedLabelDecoration.Title, ApplicationDescription);
	
EndProcedure

#EndRegion

#Region WizardScenarios

&AtServer
Function AddNavigationTableRow(MainPageName, NavigationPageName, DecorationPageName = "")
	
	NavigationsString = NavigationTable.Add();
	NavigationsString.NavigationNumber = NavigationTable.Count();
	NavigationsString.MainPageName = MainPageName;
	NavigationsString.NavigationPageName = NavigationPageName;
	NavigationsString.DecorationPageName = DecorationPageName;
	
	Return NavigationsString;
	
EndFunction

&AtServer
Procedure FillNavigationTable()
	
	NavigationTable.Clear();
	
	NewNavigation = AddNavigationTableRow("StartPage", "PageNavigationStart");
	NewNavigation.OnOpenHandlerName = "Attachable_BeginningPageOnOpen1";
	
	If TransportSettingAvailable Then
		NewNavigation = AddNavigationTableRow("ConnectionSettingsPage", "PageNavigationFollowUp");
		NewNavigation.OnOpenHandlerName = "Attachable_ConnectionSettingsPageOnOpen";
	EndIf;
	
	If PromptForPassword Then
		NewNavigation = AddNavigationTableRow("PasswordRequestPage", "PageNavigationFollowUp");
		NewNavigation.OnNavigationToNextPageHandlerName = "Attachable_PasswordRequestPageOnGoNext";
	EndIf;
	
	PassiveMode = ExchangeMessagesTransport.TransportParameter(TransportID, "PassiveMode");
	If Not PassiveMode Then
		NewNavigation = AddNavigationTableRow("ConnectionTestPage", "PageNavigationWait");
		NewNavigation.TimeConsumingOperation = True;
		NewNavigation.TimeConsumingOperationHandlerName = "Attachable_ConnectionCheckPageTimeConsumingOperation";
	EndIf;
	
	NewNavigation = AddNavigationTableRow("ChangeRecordingPage", "PageNavigationWait");
	NewNavigation.OnOpenHandlerName = "Attachable_ChangeRegistrationPageOnOpen";
	NewNavigation.TimeConsumingOperation = True;
	NewNavigation.TimeConsumingOperationHandlerName = "Attachable_ChangeRegistrationPageTimeConsumingOperation";
	
	If Not PassiveMode Then
		If UseProgress Then
			NewNavigation = AddNavigationTableRow("ExportDataProgressPage", "PageNavigationWait");
		Else
			NewNavigation = AddNavigationTableRow("ExportDataWithoutProgressPage", "PageNavigationWait");
		EndIf;
		NewNavigation.OnOpenHandlerName = "Attachable_DataExportPageOnOpen";
		NewNavigation.TimeConsumingOperation = True;
		NewNavigation.TimeConsumingOperationHandlerName = "Attachable_DataExportPageTimeConsumingOperation";
	EndIf;
	
	NewNavigation = AddNavigationTableRow("EndPage", "PageNavigationEnd");
	NewNavigation.OnOpenHandlerName = "Attachable_EndPageOnOpen";
	
EndProcedure

#EndRegion

#Region NavigationEventHandlers

&AtClient
Function Attachable_BeginningPageOnOpen1(Cancel, SkipPage, IsMoveNext)
	
	Items.DataExportMode.Enabled = Not InitialExport;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ConnectionSettingsPageOnOpen(Cancel, SkipPage, IsMoveNext)
	
	SkipPage = IsMoveNext;
	
	Return Undefined;
		
EndFunction

&AtClient
Function Attachable_PasswordRequestPageOnGoNext(Cancel)
	
	If Not PromptForPassword Then
		Return Undefined;
	EndIf;
	
	If IsBlankString(WSPassword) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Hãy nhập mật khẩu.';
				|ru = 'Укажите пароль.';
				|en = 'Please enter the password.'; fa = 'Please enter the password.';
				|it = 'Inserire la password.';
				|pl = 'Podaj hasło.';
				|tr = 'Şifreyi belirtin.'"), , "WSPassword", , Cancel);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ConnectionCheckPageTimeConsumingOperation(Cancel, GoToNext)
	
	GoToNext = False;
	OnStartTestConnection();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ChangeRegistrationPageOnOpen(Cancel, SkipPage, IsMoveNext)
	
	If Not ConnectionCheckCompleted Then
		SkipPage = True;
		Return Undefined;
	Else
		If DataExportMode = "StandardExport" Then
			SkipPage = True;
			ChangesRegistrationCompleted = True;
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_ChangeRegistrationPageTimeConsumingOperation(Cancel, GoToNext)
	
	GoToNext = False;
	OnStartChangeRegistration();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataExportPageOnOpen(Cancel, SkipPage, IsMoveNext)
	
	SkipPage = Not ConnectionCheckCompleted
		Or Not ChangesRegistrationCompleted;
		
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_DataExportPageTimeConsumingOperation(Cancel, GoToNext)
	
	GoToNext = False;
	OnStartExportDataForMapping();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_EndPageOnOpen(Cancel, SkipPage, IsMoveNext)
	
	If Not ConnectionCheckCompleted Then
		Items.CompletionStatusPanel.CurrentPage = Items.CompletionPageConnectionCheckError;
	ElsIf Not ChangesRegistrationCompleted Then
		Items.CompletionStatusPanel.CurrentPage = Items.ChangesRegistrationErrorPage;
	ElsIf Not DataExportCompleted Then
		Items.CompletionStatusPanel.CurrentPage = Items.DataExportErrorPage;
	Else
		Items.CompletionStatusPanel.CurrentPage = Items.SuccessfulCompletionPage;
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region AdditionalNavigationHandlers

&AtClient
Procedure ChangeNavigationNumber(Iterator_SSLy)
	
	ClearMessages();
	
	SetNavigationNumber(NavigationNumber + Iterator_SSLy);
	
EndProcedure

&AtClient
Procedure SetNavigationNumber(Val Value)
	
	IsMoveNext = (Value > NavigationNumber);
	
	NavigationNumber = Value;
	
	If NavigationNumber < 1 Then
		
		NavigationNumber = 1;
		
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
	
	Items.PanelMain.CurrentPage  = Items[NavigationRowCurrent.MainPageName];
	Items.NavigationPanel.CurrentPage = Items[NavigationRowCurrent.NavigationPageName];
	
	Items.NavigationPanel.CurrentPage.Enabled = Not (IsMoveNext And NavigationRowCurrent.TimeConsumingOperation);
	
	// Set the default button.
	NextButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "NextCommand");
	
	If NextButton <> Undefined Then
		
		NextButton.DefaultButton = True;
		
	Else
		
		ConfirmButton = GetFormButtonByCommandName(Items.NavigationPanel.CurrentPage, "DoneCommand");
		
		If ConfirmButton <> Undefined Then
			
			ConfirmButton.DefaultButton = True;
			
		EndIf;
		
	EndIf;
	
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
				
				Result = Eval(ProcedureName);
				
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
				
				Result = Eval(ProcedureName);
				
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
		
		Result = Eval(ProcedureName);
		
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
		
		Result = Eval(ProcedureName);
		
		If Cancel Then
			
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

#EndRegion

#EndRegion
