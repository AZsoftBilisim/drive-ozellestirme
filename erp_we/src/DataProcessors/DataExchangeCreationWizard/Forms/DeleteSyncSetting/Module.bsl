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
	
	// Verify that the form is opened with the required parameters
	If Not Parameters.Property("ExchangeNode") Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", Common.DefaultLanguageCode());
		
	EndIf;
	
	DataExchangeServer.CheckExchangeManagementRights();
	
	InitializeFormAttributes();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetNavigationNumber(1);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseForm = ForceCloseForm 
		Or Items.PanelMain.CurrentPage = Items.EndPage;

	WarningText = NStr("vi = 'Không xóa tùy chỉnh đồng bộ dữ liệu?';
						|ru = 'Отказаться от удаления настройки синхронизации данных?';
						|en = 'Do you want to cancel the deletion of the data synchronization setting?'; fa = 'Do you want to cancel the deletion of the data synchronization setting?';
						|it = 'Rifiutare la cancellazione della configurazione di sincronizzazione dei dati?';
						|pl = 'Zrezygnować z usuwania ustawienia synchronizacji danych?';
						|tr = 'Veri eşleşmesi ayarını silmekten vazgeç?'");
	CommonClient.ShowArbitraryFormClosingConfirmation(
		ThisObject, Cancel, Exit, WarningText, "ForceCloseForm");
	
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
	
	ForceCloseForm = True;
	Close();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region DeleteSyncSetting

&AtClient
Procedure OnStartDeleteSynchronizationSettings()
	
	ContinueWait = True;
	
	OnStartDeleteOfSynchronizationSettingsAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitIdleHandlerParameters(
			IdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForDeleteSynchronizationSettings",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteSynchronizationSettingsDeletion();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForDeleteSynchronizationSettings()
	
	ContinueWait = False;
	OnWaitForDeleteSynchronizationSettingAtServer(IsExchangeWithApplicationInService,
		HandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(IdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForDeleteSynchronizationSettings",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		IdleHandlerParameters = Undefined;
		OnCompleteSynchronizationSettingsDeletion();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteSynchronizationSettingsDeletion()
	
	ErrorMessage = "";
	
	SettingDeleted = True;
	SettingDeletedInCorrespondent = True;
	
	OnCompleteSynchronizationSettingsDeletionAtServer(SettingDeleted,
		SettingDeletedInCorrespondent, ErrorMessage);
	
	If SettingDeleted Then
		ChangeNavigationNumber(+1);
		
		If DeleteSettingItemInCorrespondent
			And SettingDeletedInCorrespondent Then
			Items.SyncDeletedLabelDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xóa thành công tùy chỉnh đồng bộ dữ liệu trong chương trình
				|và chương trình ""%1"".';
				|ru = 'Настройки синхронизации данных в этой программе
				|и программе ""%1"" успешно удалены.';
				|en = 'Data synchronization settings in this application
				|and in %1 are deleted.'; fa = 'Data synchronization settings in this application
				|and in %1 are deleted.';
				|it = 'Configurazione di sincronizzazione dati in questo programma
				| e nel programma ""%1"" cancellate con successo.';
				|pl = 'Ustawienia synchronizacji danych w tym programie
				|i programie „%1” zostały pomyślnie usunięte.';
				|tr = 'Bu uygulamadaki 
				| ve ""%1"" uygulamasındaki senkronizasyon ayarları başarıyla silindi.'"),
				PeerInfobaseName);
		EndIf;
		
	Else
		ChangeNavigationNumber(-1);
		
		If Not IsBlankString(ErrorMessage) Then
			CommonClient.MessageToUser(ErrorMessage);
		Else
			CommonClient.MessageToUser(
				NStr("vi = 'Không thể xóa tùy chỉnh đồng bộ dữ liệu.';
					|ru = 'Не удалось удалить настройку синхронизации данных.';
					|en = 'Cannot delete the data synchronization setting.'; fa = 'Cannot delete the data synchronization setting.';
					|it = 'Impossibile eliminare la configurazione di sincronizzazione dei dati.';
					|pl = 'Nie udało się usunąć ustawienia synchronizacji danych.';
					|tr = 'Veri senkronizasyon ayarları kaldırılamıyor.'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartDeleteOfSynchronizationSettingsAtServer(ContinueWait)
	
	DeletionSettings = New Structure;
	
	If IsExchangeWithApplicationInService Then
		
		DeletionSettings.Insert("ExchangePlanName", ExchangePlanName);
		DeletionSettings.Insert("CorrespondentDataArea", CorrespondentDataArea);
		
		ModuleSetupDeletionWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
		
	Else
		
		DeletionSettings.Insert("ExchangeNode", ExchangeNode);
		DeletionSettings.Insert("DeleteSettingItemInCorrespondent", DeleteSettingItemInCorrespondent);
		DeletionSettings.Insert("AuthenticationData", AuthenticationData);
		
		ModuleSetupDeletionWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
		
	EndIf;
	
	If ModuleSetupDeletionWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ModuleSetupDeletionWizard.OnStartDeleteSynchronizationSettings(DeletionSettings,
		HandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitForDeleteSynchronizationSettingAtServer(IsExchangeWithApplicationInService, HandlerParameters, ContinueWait)
	
	If IsExchangeWithApplicationInService Then
		ModuleSetupDeletionWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	Else
		ModuleSetupDeletionWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	EndIf;
	
	If ModuleSetupDeletionWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ContinueWait = False;
	ModuleSetupDeletionWizard.OnWaitForDeleteSynchronizationSettings(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteSynchronizationSettingsDeletionAtServer(SettingDeleted, SettingDeletedInCorrespondent, ErrorMessage)
	
	If IsExchangeWithApplicationInService Then
		ModuleSetupDeletionWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	Else
		ModuleSetupDeletionWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	EndIf;
	
	If ModuleSetupDeletionWizard = Undefined Then
		SettingDeleted = False;
		SettingDeletedInCorrespondent = False;
		Return;
	EndIf;
	
	CompletionStatus = Undefined;
	
	ModuleSetupDeletionWizard.OnCompleteSynchronizationSettingsDeletion(
		HandlerParameters, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		SettingDeleted = False;
		
		ErrorMessage = CompletionStatus.ErrorMessage;
		Return;
	Else
		ExecutionResult = CompletionStatus.Result;
		
		SettingDeleted                = ExecutionResult.SettingDeleted;
		SettingDeletedInCorrespondent = ExecutionResult.SettingDeletedInCorrespondent;
		ErrorMessage               = ExecutionResult.ErrorMessage;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormInitializationOnCreate

&AtServer
Procedure InitializeFormAttributes()
	
	ExchangeNode = Parameters.ExchangeNode;
	
	Parameters.Property("ExchangePlanName", ExchangePlanName);
	If Not ValueIsFilled(ExchangePlanName) Then
		ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeNode);
	EndIf;
	
	SaaSModel = Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable();
		
	Parameters.Property("CorrespondentDataArea",  CorrespondentDataArea);
	Parameters.Property("PeerInfobaseName",   PeerInfobaseName);
	Parameters.Property("IsExchangeWithApplicationInService", IsExchangeWithApplicationInService);
	
	If Not ValueIsFilled(PeerInfobaseName) Then
		PeerInfobaseName = String(ExchangeNode);
	EndIf;
	
	TransportID = ExchangeMessagesTransport.DefaultTransport(ExchangeNode);

	DirectConnection = False;
	PassiveMode = False;
	
	If ValueIsFilled(TransportID) Then
		TransportParameters = ExchangeMessagesTransport.TransportParameters(TransportID);   
		DirectConnection = TransportParameters.DirectConnection;
		PassiveMode = TransportParameters.PassiveMode;
	EndIf;
	
	GetCorrespondentParameters = SaaSModel
		And Not IsExchangeWithApplicationInService
		And Not DirectConnection
		And Not PassiveMode;
		
	AuthenticationData = ExchangeMessagesTransport.DataSynchronizationPassword(ExchangeNode);
		
	FillNavigationTable();
	
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
	
	If GetCorrespondentParameters Then
		NewNavigation = AddNavigationTableRow("GetCorrespondentParametersPage", "PageNavigationWait");
		NewNavigation.TimeConsumingOperation = True;
		NewNavigation.TimeConsumingOperationHandlerName = "Attachable_GetCorrespondentParametersPageTimeConsumingOperation";
	EndIf;
	
	NewNavigation = AddNavigationTableRow("StartPage", "PageNavigationStart");
	NewNavigation.OnOpenHandlerName = "Attachable_BeginningPageOnOpen1";
	NewNavigation.OnNavigationToNextPageHandlerName = "Attachable_HomePage_WhenGoingFurther";
	
	NewNavigation = AddNavigationTableRow("PageWait", "PageNavigationWait");
	NewNavigation.OnOpenHandlerName = "Attachable_WaitPage_OnOpen";
	
	NewNavigation = AddNavigationTableRow("EndPage", "PageNavigationEnd");
	NewNavigation.OnOpenHandlerName = "Attachable_EndPageOnOpen";
	
EndProcedure

#EndRegion

#Region NavigationEventHandlers

&AtClient
Function Attachable_GetCorrespondentParametersPageTimeConsumingOperation(Cancel, GoToNext)
	
	GoToNext = False;
	OnStartGetApplicationList();
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_BeginningPageOnOpen1(Cancel, SkipPage, IsMoveNext)
	
	Items.StartSubGroup.Visible = DirectConnection;
		
	TitleTemplate1 = NStr("vi = 'Xóa tùy chỉnh cũng trong chương trình ""%1"".';
							|ru = 'Удалить настройку также в программе ""%1"".';
							|en = 'Also delete the setting in %1'; fa = 'Also delete the setting in %1';
							|it = 'Eliminare l''impostazione anche nel programma ""%1"".';
							|pl = 'Usuń ustawienie również w programie „%1”.';
							|tr = '""%1"" programında da ayarı sil.'");
	Items.DeleteSettingItemInCorrespondent.Title = StrTemplate(TitleTemplate1, PeerInfobaseName);
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_HomePage_WhenGoingFurther(Cancel)
	
	If DeleteSettingItemInCorrespondent And Not PasswordFilled Then
		AuthenticationParameters = ExchangeMessagesTransportClient.AuthenticationParameters();
		AuthenticationParameters.Peer = ExchangeNode;
		AuthenticationParameters.TransportID = TransportID;
		
		AuthenticationRequired = False;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Peer", ExchangeNode);
		
		ClosingNotification1 = New CallbackDescription("EndOfAuthentication", ThisObject, AdditionalParameters);
		ExchangeMessagesTransportClient.StartOfAuthentication(AuthenticationParameters, AuthenticationRequired, ClosingNotification1);
		
		PasswordFilled = Not AuthenticationRequired;
		
		Cancel = AuthenticationRequired;
	EndIf;
		
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_WaitPage_OnOpen(Cancel, SkipPage, IsMoveNext)
	
	PasswordFilled = False;
	
	ClosingNotification1 = New CallbackDescription("AfterPermissionDeletion", ThisObject, ExchangeNode);
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Queries = DataExchangeServerCall.RequestToClearPermissionsToUseExternalResources(ExchangeNode);
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, Undefined, ClosingNotification1);
	Else
		RunCallback(ClosingNotification1, DialogReturnCode.OK);
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_WaitingPageTimeConsumingOperation(Cancel, GoToNext)
	
	GoToNext = False;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_EndPageOnOpen(Cancel, SkipPage, IsMoveNext)
	
	Notify("Write_ExchangePlanNode");
	CloseForms("NodeForm");
	CloseForms("SyncSetup");
	
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

&AtClient
Procedure OnStartGetApplicationList()
	
	HandlerParameters = Undefined;
	ContinueWait = False;
	
	OnStartGettingApplicationsListAtServer(HandlerParameters, ContinueWait);
		
	If ContinueWait Then
		DataExchangeClient.InitIdleHandlerParameters(IdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForGetApplicationList",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteGettingApplicationsList();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForGetApplicationList()
	
	ContinueWait = False;
	OnWaitGettingApplicationsListAtServer(HandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(IdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForGetApplicationList",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		IdleHandlerParameters = Undefined;
		OnCompleteGettingApplicationsList();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteGettingApplicationsList()
	
	GoToNext = True;
	OnCompleteGettingApplicationsListAtServer(GoToNext);
	
	If GoToNext Then
		ChangeNavigationNumber(+1);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure OnStartGettingApplicationsListAtServer(HandlerParameters, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	WizardParameters = New Structure("Mode", "ConfiguredExchanges");
	
	ModuleSetupWizard.OnStartGetApplicationList(WizardParameters,
		HandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitGettingApplicationsListAtServer(HandlerParameters, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ModuleSetupWizard.OnWaitForGetApplicationList(
		HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteGettingApplicationsListAtServer(GoToNext)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		Return;
	EndIf;
	
	CompletionStatus = Undefined;
	ModuleSetupWizard.OnCompleteGettingApplicationsList(HandlerParameters, CompletionStatus);
		
	If Not CompletionStatus.Cancel Then
		ApplicationsTable = CompletionStatus.Result;
		ApplicationRow = ApplicationsTable.Find(ExchangeNode, "Peer");
		If Not ApplicationRow = Undefined Then
			IsExchangeWithApplicationInService = True;
			CorrespondentDataArea  = ApplicationRow.DataArea;
			PeerInfobaseName   = ApplicationRow.ApplicationDescription;
		EndIf;
	Else
		Common.MessageToUser(CompletionStatus.ErrorMessage);
		GoToNext = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterPermissionDeletion(Result, InfobaseNode) Export
	
	If Result = DialogReturnCode.OK Then
		OnStartDeleteSynchronizationSettings();
	Else
		ChangeNavigationNumber(-1);
	EndIf;
	
EndProcedure

&AtClient
Procedure EndOfAuthentication(Result, AdditionalParameters) Export 
	
	AuthenticationData = Result;
	
	If Not ValueIsFilled(AuthenticationData) Then
		Return;
	EndIf;
	
	ExchangeMessageTransportServerCall.SetDataSynchronizationPassword(
		AdditionalParameters.Peer, AuthenticationData);
		
	PasswordFilled = True;
		
	ChangeNavigationNumber(+1);
		
EndProcedure

&AtClient
Procedure CloseForms(Val Var_FormName)
	
	ApplicationWindows = GetWindows();
	
	If ApplicationWindows = Undefined Then
		Return;
	EndIf;
		
	For Each ApplicationWindow In ApplicationWindows Do
		If ApplicationWindow.IsMain Then
			Continue;
		EndIf;
			
		Form = ApplicationWindow.GetContent();
		
		If TypeOf(Form) = Type("ClientApplicationForm")
			And Not Form.Modified
			And StrFind(Form.FormName, Var_FormName) <> 0 Then
			
			Form.Close();
			
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion