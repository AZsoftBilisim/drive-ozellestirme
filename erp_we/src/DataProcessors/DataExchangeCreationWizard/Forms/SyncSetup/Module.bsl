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
	If Not Parameters.Property("ExchangePlanName") Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", Common.DefaultLanguageCode());
		
	EndIf;
	
	DataExchangeServer.CheckExchangeManagementRights();
	
	InitializeFormAttributes();
	
	InitializeFormProperties();
	
	SetInitialFormItemsView();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FillSetupStagesTable();
	UpdateCurrentSettingsStateDisplay();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	RefExists   = False;
	SettingCompleted = False;
	
	If ValueIsFilled(Object.InfobaseNode) Then
		SettingCompleted = SynchronizationSetupCompleted(Object.InfobaseNode, RefExists);
		If Not RefExists Then
			// Closing form when deleting synchronization setup.
			Return;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Object.InfobaseNode)
		Or Not SettingCompleted
		Or (DIBSetup And Not ContinueSetupInSubordinateDIBNode And Not InitialImageCreated(Object.InfobaseNode))Then
		WarningText = NStr("vi = 'Vẫn chưa hoàn tất tùy chỉnh đồng bộ dữ liệu.
		|Kết thúc làm việc với trợ giúp? Có thể tiếp tục tùy chỉnh sau.';
		|ru = 'Настройка синхронизации данных еще не завершена.
		|Завершить работу с помощником? Настройку можно будет продолжить позже.';
		|en = 'The data synchronization setup is not completed.
		|Do you want to close the wizard? You can continue the setup later.'; fa = 'The data synchronization setup is not completed.
		|Do you want to close the wizard? You can continue the setup later.';
		|it = 'La configurazione della sincronizzazione dei dati non è ancora completata.
		| Terminare il lavoro con l''assistente? La configurazione può essere proseguita in seguito.';
		|pl = 'Konfigurowanie synchronizacji danych nie zostało jeszcze zakończone.
		|Zakończyć pracę z asystentem? Konfigurację można będzie kontynuować później.';
		|tr = 'Veri senkronizasyonu ayarı henüz tamamlanmadı.
		|Sihirbazdan çıkmak istiyor musunuz? Ayarlara daha sonra devam edilebilir.'");
		CommonClient.ShowArbitraryFormClosingConfirmation(
			ThisObject, Cancel, Exit, WarningText, "ForceCloseForm");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		Notify("DataExchangeCreationWizardFormClosed");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectTransportType(Command)
	
	FormParameters = New Structure("ExchangePlanName, TransportID, SettingID, WizardRunOption");
	FillPropertyValues(FormParameters, Object);
	
	ClosingNotification1 = New CallbackDescription("SelectTransportTypeCompletion", ThisObject);
	
	OpenForm("DataProcessor.DataExchangeCreationWizard.Form.SelectTransportType",
		FormParameters, ThisForm,,,, ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DataSyncDetails(Command)
	
	DataExchangeClient.OpenSynchronizationDetails(SettingOptionDetails.DetailedExchangeInformation);
	
EndProcedure

&AtClient
Procedure SetUpConnectionParameters(Command)
		
	FullNameOfConfigurationForm = ExchangeMessageTransportServerCall.FullNameOfFirstSetupForm(Object.TransportID);
	
	ConnectionSettings = ExchangeMessagesTransportClientServer.ConnectionSettingsForProcessing(Object);
	
	FormParameters = New Structure;
	FormParameters.Insert("ConnectionSettings", ConnectionSettings);
	FormParameters.Insert("SettingID", ConnectionSettings.SettingID);
	FormParameters.Insert("TransportSettings", ConnectionSettings.TransportSettings);
		
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TransportID", Object.TransportID);
	
	ClosingNotification1 = New CallbackDescription("SetUpConnectionParametersCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(FullNameOfConfigurationForm, FormParameters,,,,, 
		ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ConfigureGeneralParameters(Command)
	
	If ValueIsFilled(Object.AuthenticationData) Then
		ConfigureGeneralParametersContinued();
		Return;
	EndIf;
	
	AuthenticationParameters = ExchangeMessagesTransportClient.AuthenticationParameters();
	AuthenticationParameters.Peer = Object.InfobaseNode;
	AuthenticationParameters.ExchangePlanName = Object.ExchangePlanName;
	AuthenticationParameters.TransportID = Object.TransportID;
	AuthenticationParameters.TransportSettings = Object.TransportSettings;
	
	AuthenticationRequired = False;
	ClosingNotification1 = New CallbackDescription("ConfigureGeneralSettingsEndAuthentication", ThisObject);
	ExchangeMessagesTransportClient.StartOfAuthentication(AuthenticationParameters, AuthenticationRequired, ClosingNotification1);
	
	If Not AuthenticationRequired Then
		ConfigureGeneralParametersContinued();
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureGeneralSettingsEndAuthentication(AuthenticationData, AdditionalParameters) Export 
	
	If Not ValueIsFilled(AuthenticationData) Then
		Return;
	EndIf;
	
	Object.AuthenticationData = AuthenticationData;
	
	ConfigureGeneralParametersContinued();
	
EndProcedure

&AtClient
Procedure ConfigureGeneralParametersContinued()

	FormParameters = New Structure;
	
	ConnectionSettings = ExchangeMessagesTransportClientServer.StructureOfConnectionSettings();
	FillPropertyValues(ConnectionSettings, Object);
	
	ConnectionSettings.ExchangePlanName = Object.ExchangePlanName;
	ConnectionSettings.SettingID = Object.SettingID;
	
	FormParameters.Insert("ConnectionSettings", ConnectionSettings);
	
	If ContinueSetupInSubordinateDIBNode Then
		FormParameters.Insert("ContinueSetupInSubordinateDIBNode");
	EndIf;
	
	ClosingNotification1 = New CallbackDescription("ConfigureGeneralParametersCompletion", ThisObject);
	
	OpenForm("DataProcessor.DataExchangeCreationWizard.Form.SetUpCommonParameters", 
		FormParameters, ThisForm,,,, ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure GetConnectionConfirmation(Command)
		
	If XDTOCorrespondentSettingsReceived(Object.InfobaseNode) Then
		ShowMessageBox(, NStr("vi = 'Đã xác nhận kết nối.';
								|ru = 'Подключение подтверждено.';
								|en = 'The connection is confirmed.'; fa = 'The connection is confirmed.';
								|it = 'Connessione confermata.';
								|pl = 'Połączenie potwierdzone.';
								|tr = 'Bağlantı onaylandı.'"));
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("OnlineUserSupport.DataExchangeWithExternalSystems") Then
		Context = New Structure;
		Context.Insert("Mode",                  "ConfirmConnection");
		Context.Insert("Peer",          Object.InfobaseNode);
		Context.Insert("SettingID", "SettingID");
		Context.Insert("ConnectionParameters",   ExternalSystemConnectionParameters);
		
		Cancel = False;
		WizardFormName  = "";
		WizardParameters = New Structure;
		
		ModuleDataExchangeWithExternalSystemsClient = CommonClient.CommonModule("DataExchangeWithExternalSystemsClient");
		ModuleDataExchangeWithExternalSystemsClient.BeforeSettingConnectionSettings(
			Context, Cancel, WizardFormName, WizardParameters);
		
		If Not Cancel Then
			ClosingNotification1 = New CallbackDescription("GetConnectionConfirmationCompletion", ThisObject);
			OpenForm(WizardFormName,
				WizardParameters, ThisObject, , , , ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureDataExportImportRules(Command)
	
	ContinueNotification = New CallbackDescription("ConfigureDataExportImportRulesContinued", ThisObject);
	
	// For XDTO exchange plans, get the peer infobase's settings before configuring the exchange rules.
	// 
	If XDTOSetup Then
		AbortSetup = False;
		ExecuteXDTOSettingsImportIfNecessary(AbortSetup, ContinueNotification);
		
		If AbortSetup Then
			Return;
		EndIf;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ContinueSetup",            True);
	Result.Insert("DataReceivedForMapping", DataReceivedForMapping);
	
	RunCallback(ContinueNotification, Result);
	
EndProcedure

&AtClient
Procedure CreateInitialDIBImage(Command)
	
	WizardParameters = New Structure("Key, Node", Object.InfobaseNode, Object.InfobaseNode);
			
	ClosingNotification1 = New CallbackDescription("CreateInitialDIBImageCompletion", ThisObject);
	OpenForm(InitialImageCreationFormName,
		WizardParameters, ThisObject, , , , ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MapAndExportData(Command)
	
	ContinueNotification = New CallbackDescription("MapAndExportDataContinued", ThisObject);
	
	WizardParameters = New Structure;
	WizardParameters.Insert("SendData",     False);
	WizardParameters.Insert("ScheduleSetup", False);
	
	If IsExchangeWithApplicationInService Then
		WizardParameters.Insert("CorrespondentDataArea", CorrespondentDataArea);
	EndIf;
	
	AuxiliaryParameters = New Structure;
	AuxiliaryParameters.Insert("WizardParameters",  WizardParameters);
	AuxiliaryParameters.Insert("ClosingNotification1", ContinueNotification);
	
	DataExchangeClient.OpenObjectsMappingWizardCommandProcessing(Object.InfobaseNode,
		ThisObject, AuxiliaryParameters);
	
EndProcedure

&AtClient
Procedure ExecuteInitialDataExport(Command)

	Cancel = False;
	
	BeforePerformingTheInitialUpload(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	If ValueIsFilled(Object.AuthenticationData) Then
		ExecuteInitialDataExportContinued();
		Return;
	EndIf;
	
	AuthenticationParameters = ExchangeMessagesTransportClient.AuthenticationParameters();
	AuthenticationParameters.Peer = Object.InfobaseNode;
	AuthenticationParameters.ExchangePlanName = Object.ExchangePlanName;
	AuthenticationParameters.TransportID = Object.TransportID;
	AuthenticationParameters.TransportSettings = Object.TransportSettings;
	
	AuthenticationRequired = False;
	ClosingNotification1 = New CallbackDescription("PerformInitialDataUploadEndAuthentication", ThisObject);
	ExchangeMessagesTransportClient.StartOfAuthentication(AuthenticationParameters, AuthenticationRequired, ClosingNotification1);
	
	If Not AuthenticationRequired Then
		ExecuteInitialDataExportContinued();
	EndIf;
		
EndProcedure
	
&AtClient
Procedure PerformInitialDataUploadEndAuthentication(AuthenticationData, AdditionalParameters) Export 
	
	If Not ValueIsFilled(AuthenticationData) Then
		Return;
	EndIf;
	
	Object.AuthenticationData = AuthenticationData;
	
	ExecuteInitialDataExportContinued();
	
EndProcedure
	
&AtClient 
Procedure ExecuteInitialDataExportContinued()
	
	WizardParameters = New Structure;
	WizardParameters.Insert("ExchangeNode", Object.InfobaseNode);
	WizardParameters.Insert("InitialExport");
	WizardParameters.Insert("AuthenticationData", Object.AuthenticationData);
	
	If SaaSModel Then
		WizardParameters.Insert("IsExchangeWithApplicationInService", IsExchangeWithApplicationInService);
		WizardParameters.Insert("CorrespondentDataArea",  CorrespondentDataArea);
	EndIf;
	
	ClosingNotification1 = New CallbackDescription("ExecuteInitialDataExportCompletion", ThisObject);
	OpenForm("DataProcessor.InteractiveDataExchangeWizard.Form.ExportMappingData",
		WizardParameters, ThisObject, , , , ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure BeforePerformingTheInitialUpload(Cancel)
	
EndProcedure

&AtServerNoContext
Function SynchronizationSetupStatus(ExchangeNode)
	
	Result = New Structure;
	Result.Insert("SynchronizationSetupCompleted",           SynchronizationSetupCompleted(ExchangeNode));
	Result.Insert("InitialImageCreated",                      InitialImageCreated(ExchangeNode));
	Result.Insert("MessageWithDataForMappingReceived", DataExchangeServer.MessageWithDataForMappingReceived(ExchangeNode));
	Result.Insert("XDTOCorrespondentSettingsReceived",       XDTOCorrespondentSettingsReceived(ExchangeNode));
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function XDTOCorrespondentSettingsReceived(ExchangeNode)
	
	CorrespondentSettings = DataExchangeXDTOServer.SupportedPeerInfobaseFormatObjects(ExchangeNode, "SendReceive");
	
	Return CorrespondentSettings.Count() > 0;
	
EndFunction

&AtServerNoContext
Function InitialImageCreated(ExchangeNode)
	
	Return InformationRegisters.CommonInfobasesNodesSettings.InitialImageCreated(ExchangeNode);
	
EndFunction

&AtClient
Procedure SetUpConnectionParametersCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	Object.TransportSettings = ClosingResult;
	
	If CurrentSetupStep = "ConnectionSetup" Then
		GoToNextSetupStage();
	EndIf;
	
EndProcedure

&AtClient 
Procedure SelectTransportTypeCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then
		Return;
	EndIf;
		
	For Each KeyAndValue In ClosingResult Do
		If ValueIsFilled(KeyAndValue.Value) Then
			Object[KeyAndValue.Key] = KeyAndValue.Value;
		EndIf;
	EndDo;
	
	TransportSettingsAvailable = ValueIsFilled(Object.TransportSettings);

	If Object.WizardRunOption = "ContinueDataExchangeSetup" Then
		CurrentSetupStep = "SelectTransportType";
	EndIf;
	
	If CurrentSetupStep = "SelectTransportType" Then
		
		GoToNextSetupStage();
		
		If Object.WizardRunOption = "ContinueDataExchangeSetup" 
			And TransportSettingsAvailable
			And Not SettingUpSubAssetInCorrespondentOnServer() Then
			
			GoToNextSetupStage();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function SettingUpSubAssetInCorrespondentOnServer()
	
	Return ExchangeMessagesTransport.TransportParameter(
		Object.TransportID, "SettingUpSubAssetInCorrespondent");
	
EndFunction

&AtClient
Procedure ConfigureGeneralParametersCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	Object.InfobaseNode = ClosingResult.ExchangeNode;
	
	If ValueIsFilled(Object.AuthenticationData) Then
		ExchangeMessageTransportServerCall.SetDataSynchronizationPassword(
			Object.InfobaseNode, Object.AuthenticationData);
	EndIf;
		
	If ClosingResult.Property("HasDataToMap")
		And ClosingResult.HasDataToMap Then
		DataReceivedForMapping = True;
	EndIf;
	
	FillSetupStagesTable();
	UpdateCurrentSettingsStateDisplay();
	
	If CurrentSetupStep = "CommonParameters" Then
		GoToNextSetupStage();
	EndIf;
	
EndProcedure

&AtClient
Procedure GetConnectionConfirmationCompletion(Result, AdditionalParameters) Export
	
	If XDTOCorrespondentSettingsReceived(Object.InfobaseNode) Then
		GoToNextSetupStage();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteXDTOSettingsImportIfNecessary(AbortSetup, ContinueNotification)
	
	SetupStatus = SynchronizationSetupStatus(Object.InfobaseNode);
	If Not SetupStatus.SynchronizationSetupCompleted
		And Not SetupStatus.XDTOCorrespondentSettingsReceived Then
		
		ImportParameters = New Structure;
		ImportParameters.Insert("ExchangeNode", Object.InfobaseNode);
		
		OpenForm("DataProcessor.DataExchangeCreationWizard.Form.XDTOSettingsImport",
			ImportParameters, ThisObject, , , , ContinueNotification, FormWindowOpeningMode.LockOwnerWindow);
			
		AbortSetup = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureDataExportImportRulesContinued(ClosingResult, AdditionalParameters) Export
	
	If TypeOf(ClosingResult) <> Type("Structure")
		Or Not ClosingResult.ContinueSetup Then
		
		Return;
		
	EndIf;
	
	If ClosingResult.DataReceivedForMapping
		And Not DataReceivedForMapping Then
		DataReceivedForMapping = ClosingResult.DataReceivedForMapping;
	EndIf;
	
	FillSetupStagesTable();
	UpdateCurrentSettingsStateDisplay();
	
	ClosingNotification1 = New CallbackDescription("ConfigureDataExportImportRulesCompletion", ThisObject);
	
	CheckParameters = New Structure;
	CheckParameters.Insert("Peer",          Object.InfobaseNode);
	CheckParameters.Insert("ExchangePlanName",         Object.ExchangePlanName);
	CheckParameters.Insert("SettingID", Object.SettingID);
	
	SetupExecuted = False;
	BeforeDataSynchronizationSetup(CheckParameters, SetupExecuted, DataSyncSettingsWizardFormName);
	
	If SetupExecuted Then
		ShowMessageBox(, NStr("vi = 'Đã thực hiện tùy chỉnh quy tắc gửi và nhận dữ liệu.';
								|ru = 'Настройка правил отправки и получения данных выполнена.';
								|en = 'The rules for sending and receiving data are configured.'; fa = 'The rules for sending and receiving data are configured.';
								|it = 'Configurazione delle regole di invio e ricezione dati completata.';
								|pl = 'Zasady wysyłania i odbierania danych są skonfigurowane.';
								|tr = 'Veri gönderimi ve alımı kurallarının yapılandırılması tamamlandı.'"));
		RunCallback(ClosingNotification1, True);
		Return;
	EndIf;
	
	WizardParameters = New Structure;
	
	If IsBlankString(DataSyncSettingsWizardFormName) Then
		WizardParameters.Insert("Key", Object.InfobaseNode);
		WizardParameters.Insert("WizardFormName", "ExchangePlan.[ExchangePlanName].ObjectForm");
		
		WizardParameters.WizardFormName = StrReplace(WizardParameters.WizardFormName,
			"[ExchangePlanName]", Object.ExchangePlanName);
	Else
		WizardParameters.Insert("ExchangeNode", Object.InfobaseNode);
		WizardParameters.Insert("WizardFormName", DataSyncSettingsWizardFormName);
	EndIf;
	
	OpenForm(WizardParameters.WizardFormName,
		WizardParameters, ThisObject, , , , ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ConfigureDataExportImportRulesCompletion(ClosingResult, AdditionalParameters) Export
	
	If CurrentSetupStep = "RulesSetting"
		And SynchronizationSetupCompleted(Object.InfobaseNode) Then
		Notify("Write_ExchangePlanNode");
		If ContinueSetupInSubordinateDIBNode Then
			RefreshInterface();
		EndIf;
		GoToNextSetupStage();
	EndIf;
	
EndProcedure

&AtClient
Procedure MapAndExportDataContinued(ClosingResult, AdditionalParameters) Export
	
	If CurrentSetupStep = "MapAndImport"
		And DataForMappingImported(Object.InfobaseNode) Then
		GoToNextSetupStage();
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateInitialDIBImageCompletion(ClosingResult, AdditionalParameters) Export
	
	If CurrentSetupStep = "InitialDIBImage"
		And InitialImageCreated(Object.InfobaseNode) Then
		GoToNextSetupStage();
	EndIf;
	
	RefreshInterface();
	
EndProcedure

&AtClient
Procedure ExecuteInitialDataExportCompletion(ClosingResult, AdditionalParameters) Export
	
	If CurrentSetupStep = "InitialDataExport"
		And ClosingResult = Object.InfobaseNode Then
		GoToNextSetupStage();
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateCurrentSettingsStateDisplay()
	
	// Visibility of setup items.
	For Each SetupStage In SetupSteps Do
		CommonClientServer.SetFormItemProperty(Items, SetupStage.Group, "Visible", SetupStage.Used);
	EndDo;
	
	If IsBlankString(CurrentSetupStep) Then
		// All stages are completed.
		For Each SetupStage In SetupSteps Do
			Items[SetupStage.Group].Enabled = True;
			Items[SetupStage.Button].Font = CommonClient.StyleFont("SynchronizationSetupWizardCommandStandardFont");
			
			// Green flag is only for the main setting stages.
			If SetupStage.IsMain Then
				Items[SetupStage.Panel].CurrentPage = Items[SetupStage.PageSuccessfully];
			Else
				Items[SetupStage.Panel].CurrentPage = Items[SetupStage.EmptySpacePage];
			EndIf;
		EndDo;
	Else
		
		CurrentStageFound = False;
		For Each SetupStage In SetupSteps Do
			If SetupStage.Name1 = CurrentSetupStep Then
				Items[SetupStage.Group].Enabled = True;
				Items[SetupStage.Panel].CurrentPage = Items[SetupStage.PageCurrent];
				Items[SetupStage.Button].Font = CommonClient.StyleFont("SynchronizationSetupWizardCommandImportantFont");
				CurrentStageFound = True;
			ElsIf Not CurrentStageFound Then
				Items[SetupStage.Group].Enabled = True;
				Items[SetupStage.Panel].CurrentPage = Items[SetupStage.PageSuccessfully];
				Items[SetupStage.Button].Font = CommonClient.StyleFont("SynchronizationSetupWizardCommandStandardFont");
			Else
				Items[SetupStage.Group].Enabled = False;
				Items[SetupStage.Panel].CurrentPage = Items[SetupStage.EmptySpacePage];
				Items[SetupStage.Button].Font = CommonClient.StyleFont("SynchronizationSetupWizardCommandStandardFont");
			EndIf;
		EndDo;
		
		For Each SetupStage In SetupSteps Do
			If Not SetupStage.Used Then
				Items[SetupStage.Group].Enabled = False;
				Items[SetupStage.Panel].CurrentPage = Items[SetupStage.EmptySpacePage];
			EndIf;
		EndDo;
		
	EndIf;
	
	StepsAfterActivation = "RulesSetting,InitialDIBImage,MapAndImport,InitialDataExport,ConfirmConnection"; 
	If StrFind(StepsAfterActivation, CurrentSetupStep) > 0 Then
		
		Items.SelectTransportType.Enabled = False;
		Items.SetUpConnectionParameters.Enabled = False;
		Items.GetConnectionConfirmation.Enabled = False;
		Items.ConfigureGeneralParameters.Enabled = False;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToNextSetupStage()
	
	NextRow = Undefined;
	CurrentStageFound = False;
	For Each SetupStagesString In SetupSteps Do
		If CurrentStageFound And SetupStagesString.Used Then
			NextRow = SetupStagesString;
			Break;
		EndIf;
		
		If SetupStagesString.Name1 = CurrentSetupStep Then
			CurrentStageFound = True;
		EndIf;
	EndDo;
	
	If NextRow <> Undefined Then
		CurrentSetupStep = NextRow.Name1;
		
		If CurrentSetupStep = "RulesSetting" Then
			CheckParameters = New Structure;
			CheckParameters.Insert("Peer",          Object.InfobaseNode);
			CheckParameters.Insert("ExchangePlanName",         Object.ExchangePlanName);
			CheckParameters.Insert("SettingID", Object.SettingID);
			
			SetupExecuted = SynchronizationSetupCompleted(Object.InfobaseNode);
			If Not SetupExecuted Then
				If Not XDTOSetup Or XDTOCorrespondentSettingsReceived(Object.InfobaseNode) Then
					BeforeDataSynchronizationSetup(CheckParameters, SetupExecuted, DataSyncSettingsWizardFormName);
				EndIf;
			EndIf;
			
			If SetupExecuted Then
				GoToNextSetupStage();
				Return;
			EndIf;
		EndIf;
			
		If Not NextRow.IsMain Then
			CurrentSetupStep = "";
		EndIf;
	Else
		CurrentSetupStep = "";
	EndIf;
	
	AttachIdleHandler("UpdateCurrentSettingsStateDisplay", 0.2, True);
	
EndProcedure

&AtServerNoContext
Function SynchronizationSetupCompleted(ExchangeNode, RefExists = False)
	
	RefExists = Common.RefExists(ExchangeNode);
	Return DataExchangeServer.SynchronizationSetupCompleted(ExchangeNode);
	
EndFunction

&AtServerNoContext
Function DataForMappingImported(ExchangeNode)
	
	Return Not DataExchangeServer.MessageWithDataForMappingReceived(ExchangeNode);
	
EndFunction

&AtServerNoContext
Procedure BeforeDataSynchronizationSetup(CheckParameters, SetupExecuted, WizardFormName)
	
	If DataExchangeServer.HasExchangePlanManagerAlgorithm("BeforeDataSynchronizationSetup", CheckParameters.ExchangePlanName) Then
		
		Context = New Structure;
		Context.Insert("Peer",          CheckParameters.Peer);
		Context.Insert("SettingID", CheckParameters.SettingID);
		Context.Insert("InitialSetting",     Not SynchronizationSetupCompleted(CheckParameters.Peer));
		
		ExchangePlans[CheckParameters.ExchangePlanName].BeforeDataSynchronizationSetup(
			Context, SetupExecuted, WizardFormName);
		
		If SetupExecuted Then
			DataExchangeServer.CompleteDataSynchronizationSetup(CheckParameters.Peer);
		EndIf;
		
	EndIf;
	
EndProcedure

#Region FormInitializationOnCreate

&AtServer
Procedure InitializeFormProperties()
	
	Title = SettingOptionDetails.ExchangeCreateWizardTitle;
	
	If IsBlankString(Title) Then
		If DIBSetup Then
			Title = NStr("vi = 'Tùy chỉnh cơ sở thông tin phân tán';
						|ru = 'Настройка распределенной информационной базы';
						|en = 'Configure distributed infobase'; fa = 'Configure distributed infobase';
						|it = 'Configurazione del database informatico distribuito';
						|pl = 'Konfiguracja przydzielonej bazy informacyjnej';
						|tr = 'Dağıtılmış Infobase ayarı'");
		Else
			Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tùy chỉnh đồng bộ dữ liệu với ""%1""';
					|ru = 'Настройка синхронизации данных с ""%1""';
					|en = 'Configure data synchronization with %1'; fa = 'Configure data synchronization with %1';
					|it = 'La configurazione della sincronizzazione dei dati da ""%1""';
					|pl = 'Konfigurowanie synchronizacji danych z ""%1""';
					|tr = '%1 ile veri senkronizasyonu ayarı'"),
				SettingOptionDetails.PeerInfobaseName);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeFormAttributes()
	
	Parameters.Property("SettingOptionDetails",    SettingOptionDetails);
	
	NewSYnchronizationSetting = Parameters.Property("NewSYnchronizationSetting");
	ContinueSetupInSubordinateDIBNode = Parameters.Property("ContinueSetupInSubordinateDIBNode");
	
	SaaSModel = Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable();
	
	If NewSYnchronizationSetting Then
		Object.ExchangePlanName         = Parameters.ExchangePlanName;
		Object.SettingID = Parameters.SettingID;
		
		If Not ContinueSetupInSubordinateDIBNode Then
			If DataExchangeServer.IsSubordinateDIBNode() Then
				DIBExchangePlanName = DataExchangeServer.MasterNode().Metadata().Name;
				
				ContinueSetupInSubordinateDIBNode = (Object.ExchangePlanName = DIBExchangePlanName)
				And Not Constants.SubordinateDIBNodeSetupCompleted.Get();
			EndIf;
		EndIf;
		
		If ContinueSetupInSubordinateDIBNode Then
			
			DataExchangeServer.OnContinueSubordinateDIBNodeSetup();
			Object.InfobaseNode = DataExchangeServer.MasterNode();
			Object.WizardRunOption = "ContinueDataExchangeSetup";
			
		Else
			
			Object.WizardRunOption = "NewSynchronization";
			
		EndIf;
		
	Else
		Object.InfobaseNode = Parameters.ExchangeNode;
		
		Object.ExchangePlanName         = DataExchangeCached.GetExchangePlanName(Object.InfobaseNode);
		Object.SettingID = DataExchangeServer.SavedExchangePlanNodeSettingOption(Object.InfobaseNode);
		
		If SaaSModel Then
			Parameters.Property("CorrespondentDataArea",  CorrespondentDataArea);
			Parameters.Property("IsExchangeWithApplicationInService", IsExchangeWithApplicationInService);
		EndIf;
		
		Object.WizardRunOption = "ContinueDataExchangeSetup";
	EndIf;
		
	If ContinueSetupInSubordinateDIBNode Or SettingOptionDetails = Undefined Then
		
		ModuleWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
		SettingOptionDetails = ModuleWizard.SettingOptionDetailsStructure();
		
		SettingsValuesForOption = DataExchangeServer.ExchangePlanSettingValue(Object.ExchangePlanName,
			"CorrespondentConfigurationDescription,
			|NewDataExchangeCreationCommandTitle,
			|ExchangeCreateWizardTitle,
			|BriefExchangeInfo,
			|DetailedExchangeInformation",
			Object.SettingID);
			
		FillPropertyValues(SettingOptionDetails, SettingsValuesForOption);
		SettingOptionDetails.PeerInfobaseName = SettingsValuesForOption.CorrespondentConfigurationDescription;
		
		JSONText = Constants.SubordinateDIBNodeSettings.Get();
		
		If ValueIsFilled(JSONText) Then
			
			ConnectionSettings = ExchangeMessagesTransport.ConnectionSettingsFromJSON(JSONText);
			
			If  ValueIsFilled(ConnectionSettings.TransportID)
				And ConnectionSettings.Property("TransportSettings") Then

				// Save to a safe storage
				AttributesForSecureStorage = ExchangeMessagesTransport.TransportParameter(
				ConnectionSettings.TransportID, "AttributesForSecureStorage");

				TransportSettings = ConnectionSettings.TransportSettings;

				SetPrivilegedMode(True);

				For Each Attribute In AttributesForSecureStorage Do

					Value = TransportSettings[Attribute];

					If ValueIsFilled(Value) Then

						Value_ID = String(New UUID);
						Common.WriteDataToSecureStorage(Value_ID, Value);
						TransportSettings[Attribute] = Value_ID;

					EndIf;

				EndDo;

				SetPrivilegedMode(False);
				
			EndIf;
			
		Else
			
			ConnectionSettings = New Structure;
			ConnectionSettings.Insert("SecondInfobaseDescription", ExchangePlans.MasterNode().Description);
			ConnectionSettings.Insert("DestinationInfobasePrefix", ExchangePlans.MasterNode().Code);
			
		EndIf;
		
		FillPropertyValues(Object, ConnectionSettings);
		
	EndIf;
	
	If ValueIsFilled(Object.InfobaseNode)
		And Not ValueIsFilled(Object.TransportID)
		And Not ValueIsFilled(Object.TransportSettings) Then
		
		SettingCompleted = SynchronizationSetupCompleted(Object.InfobaseNode);
		
		Object.TransportSettings = ExchangeMessagesTransport.DefaultTransportSettings(
			Object.InfobaseNode, Object.TransportID);
		
	EndIf;
	
	TransportSettingsAvailable = ValueIsFilled(Object.TransportSettings)
		Or ValueIsFilled(Object.TransportID) 
			And ExchangeMessagesTransport.TransportParameter(Object.TransportID, "PassiveMode");
	
	Backup = Not SaaSModel
		And Not ContinueSetupInSubordinateDIBNode
		And Common.SubsystemExists("StandardSubsystems.IBBackup");
		
	If Backup Then
		ModuleIBBackupServer = Common.CommonModule("IBBackupServer");
		
		BackupDataProcessorURL =
			ModuleIBBackupServer.BackupDataProcessorURL();
	EndIf;
		
	DIBSetup = DataExchangeCached.IsDistributedInfobaseExchangePlan(Object.ExchangePlanName);
	XDTOSetup = DataExchangeServer.IsXDTOExchangePlan(Object.ExchangePlanName);
	UniversalExchangeSetup = DataExchangeCached.IsStandardDataExchangeNode(Object.ExchangePlanName); // No conversion rules.
	
	InteractiveSendingAvailable = Not DIBSetup And Not UniversalExchangeSetup;
	
	If NewSYnchronizationSetting
		Or DIBSetup
		Or UniversalExchangeSetup Then
		
		DataReceivedForMapping = False;
		
	ElsIf IsExchangeWithApplicationInService Then
		
		DataReceivedForMapping = DataExchangeServer.MessageWithDataForMappingReceived(Object.InfobaseNode);
		
	Else
		
		DirectConnection = ExchangeMessagesTransport.TransportParameter(Object.TransportID, "DirectConnection");
		
		If DirectConnection And TransportSettingsAvailable Then
			DataReceivedForMapping = DataExchangeServer.MessageWithDataForMappingReceived(Object.InfobaseNode);
		Else
			DataReceivedForMapping = True;
		EndIf;
		
	EndIf;
		
	SettingsValuesForOption = DataExchangeServer.ExchangePlanSettingValue(Object.ExchangePlanName,
		"InitialImageCreationFormName,
		|DataSyncSettingsWizardFormName,
		|DataMappingSupported,
		|CorrespondentConfigurationName,
		|CorrespondentExchangePlanName,
		|ExchangeFormat,
		|SettingsFileNameForDestination,
		|CorrespondentConfigurationDescription,
		|BriefExchangeInfo,
		|DetailedExchangeInformation",
		Object.SettingID);
		
	FillPropertyValues(ThisObject, SettingsValuesForOption);
	
	If IsBlankString(InitialImageCreationFormName)
		And Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		InitialImageCreationFormName = "CommonForm.[InitialImageCreationForm]";
		InitialImageCreationFormName = StrReplace(InitialImageCreationFormName,
			"[InitialImageCreationForm]", "CreateInitialImageWithFiles");
	EndIf; 
	
	FillPropertyValues(Object, SettingsValuesForOption);
	
	If Not ValueIsFilled(Object.CorrespondentExchangePlanName) Then
		Object.CorrespondentExchangePlanName = Object.ExchangePlanName;
	EndIf;
	
	If SaaSModel Then
		
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		Object.ThisInfobaseDescription = ModuleDataExchangeSaaS.GeneratePredefinedNodeDescription();
		
	Else
		
		// This infobase presentation.
		Object.ThisInfobaseDescription = DataExchangeServer.PredefinedExchangePlanNodeDescription(Object.ExchangePlanName);
		If IsBlankString(Object.ThisInfobaseDescription) Then
			Object.ThisInfobaseDescription = DataExchangeCached.ThisInfobaseName();
		EndIf;
		
		If Not ValueIsFilled(Object.SecondInfobaseDescription) Then
			Object.SecondInfobaseDescription = SettingsValuesForOption.CorrespondentConfigurationDescription;
		EndIf;
				
	EndIf;
	
	Object.SourceInfobaseID = 
		DataExchangeServer.PredefinedExchangePlanNodeCode(Object.ExchangePlanName);
	
	If XDTOSetup Then
		
		Object.UsePrefixesForExchangeSettings = 
			Not DataExchangeXDTOServer.VersionWithDataExchangeIDSupported(
			ExchangePlans[Object.ExchangePlanName].EmptyRef());
	
		If IsBlankString(Object.SourceInfobaseID) Then
			Object.SourceInfobaseID = 
				?(Object.UsePrefixesForExchangeSettings,
					Object.SourceInfobasePrefix,
					String(New UUID));
		EndIf;
		
	Else
		Object.UsePrefixesForExchangeSettings = True;
	EndIf;
	
	Object.UsePrefixesForCorrespondentExchangeSettings = True;
	
	If Not ValueIsFilled(Object.SourceInfobasePrefix) Then
		
		InfobasePrefix = GetFunctionalOption("InfobasePrefix");
		
		If ValueIsFilled(InfobasePrefix) Then
			Object.SourceInfobasePrefix = InfobasePrefix;
		Else
			DataExchangeOverridable.OnDetermineDefaultInfobasePrefix(Object.SourceInfobasePrefix);
		EndIf;
	
	EndIf;
	
	CurrentSetupStep = "";
	If (NewSYnchronizationSetting And Not ContinueSetupInSubordinateDIBNode)
		Or (ContinueSetupInSubordinateDIBNode And Not TransportSettingsAvailable) Then
		CurrentSetupStep = "SelectTransportType";
	ElsIf NewSYnchronizationSetting And ContinueSetupInSubordinateDIBNode Then
		CurrentSetupStep = "CommonParameters";
	ElsIf Not SynchronizationSetupCompleted(Object.InfobaseNode) Then
		CurrentSetupStep = "RulesSetting";
	ElsIf DIBSetup
		And Not ContinueSetupInSubordinateDIBNode
		And Not InitialImageCreated(Object.InfobaseNode) Then
		If Not IsBlankString(InitialImageCreationFormName) Then
			CurrentSetupStep = "InitialDIBImage";
		EndIf;
	ElsIf ValueIsFilled(Object.InfobaseNode) Then
		MessagesNumbers = Common.ObjectAttributesValues(Object.InfobaseNode, "ReceivedNo, SentNo");
		If MessagesNumbers.ReceivedNo = 0
			And MessagesNumbers.SentNo = 0
			And DataExchangeServer.MessageWithDataForMappingReceived(Object.InfobaseNode) Then
			CurrentSetupStep = "MapAndImport";
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function AddSetupStage(Name1, Button, FormItems, Used, IsMain = True)
	
	StageString = SetupSteps.Add();
	StageString.Name1        = Name1;
	StageString.Button          = Button;
	StageString.Used    = Used;
	StageString.IsMain        = IsMain;
	
	FillPropertyValues(StageString, FormItems);
	
	Return StageString;
	
EndFunction

&AtClient
Procedure FillSetupStagesTable()
	
	SetupSteps.Clear();
	
	// Select transport type
	TheStageIsUsed = NewSYnchronizationSetting
		Or (ContinueSetupInSubordinateDIBNode And Not TransportSettingsAvailable);
	
	FormItems = New Structure;
	FormItems.Insert("Group"			, Items.TransportTypeSelectionGroup.Name);
	FormItems.Insert("Panel"			, Items.TransportTypeSelectionPanel.Name);
	FormItems.Insert("PageSuccessfully", Items.TransportTypeSelectionPageIsSuccessful.Name);
	FormItems.Insert("PageCurrent", Items.CurTransportTypeSelectionPage.Name);
	FormItems.Insert("EmptySpacePage"	, Items.TransportTypeSelectionPageIsEmpty.Name);
	
	AddSetupStage("SelectTransportType", "SelectTransportType", FormItems, TheStageIsUsed);
		
	// Configure connection.
	TheStageIsUsed = TransportSettingsAvailable Or NewSYnchronizationSetting;
	
	FormItems = New Structure;
	FormItems.Insert("Group"			, Items.ConnectionSetupGroup.Name);
	FormItems.Insert("Panel"			, Items.ConnectionSetupPanel.Name);
	FormItems.Insert("PageSuccessfully", Items.ConnectionSetupSuccessfulPage.Name);
	FormItems.Insert("PageCurrent", Items.ConnectionSetupPageActive.Name);
	FormItems.Insert("EmptySpacePage"	, Items.ConnectionSetupPageEmpty.Name);
	
	AddSetupStage("ConnectionSetup", "SetUpConnectionParameters", FormItems, TheStageIsUsed);
	
	// Common synchronization parameters
	TheStageIsUsed = TransportSettingsAvailable Or NewSYnchronizationSetting;
	
	FormItems = New Structure;
	FormItems.Insert("Group" , Items.GroupCommonParameters.Name);
	FormItems.Insert("Panel" , Items.GeneralParametersPanel.Name);
	FormItems.Insert("PageSuccessfully", Items.GeneralParametersPageIsSuccessful.Name);
	FormItems.Insert("PageCurrent", Items.GeneralParametersCurPage.Name);
	FormItems.Insert("EmptySpacePage", Items.GeneralParametersPageIsEmpty.Name);
	
	AddSetupStage("CommonParameters", "ConfigureGeneralParameters", FormItems, TheStageIsUsed);
	
	// Confirm connection.
	TheStageIsUsed = False;
	
	FormItems = New Structure;
	FormItems.Insert("Group", Items.ConnectionConfirmationGroup.Name);
	FormItems.Insert("Panel", Items.ConnectionConfirmationPanel.Name);
	FormItems.Insert("PageSuccessfully", Items.ConnectionConfirmationStepSucceededPage.Name);
	FormItems.Insert("PageCurrent", Items.ConnectionConfirmationStepInProgressPage.Name);
	FormItems.Insert("EmptySpacePage", Items.ConnectionConfirmationStepToProcessPage.Name);
	
	AddSetupStage("ConfirmConnection", "GetConnectionConfirmation", FormItems, TheStageIsUsed);
		
	// Configure synchronization rules.
	FormItems = New Structure;
	FormItems.Insert("Group", Items.RulesSetupGroup.Name);
	FormItems.Insert("Panel", Items.RulesSetupPanel.Name);
	FormItems.Insert("PageSuccessfully", Items.RulesSetupSuccessfulPage.Name);
	FormItems.Insert("PageCurrent", Items.RulesSetupPageActive.Name);
	FormItems.Insert("EmptySpacePage", Items.RulesSetupPageEmpty.Name);
	
	AddSetupStage("RulesSetting", "SetSendingAndReceivingRules", FormItems, True);
		
	// Initial DIB image
	TheStageIsUsed = DIBSetup
		And Not ContinueSetupInSubordinateDIBNode
		And Not IsBlankString(InitialImageCreationFormName);
		
	FormItems = New Structure;
	FormItems.Insert("Group", Items.InitialDIBImageGroup.Name);
	FormItems.Insert("Panel", Items.InitialDIBImagePanel.Name);
	FormItems.Insert("PageSuccessfully", Items.InitialDIBImagePageSuccessful.Name);
	FormItems.Insert("PageCurrent", Items.InitialDIBImagePageActive.Name);
	FormItems.Insert("EmptySpacePage", Items.InitialDIBImagePageEmpty.Name);
	
	AddSetupStage("InitialDIBImage", "CreateInitialDIBImage", FormItems, TheStageIsUsed);
		
	// Map and import data
	TheStageIsUsed = Not DIBSetup 
		And Not UniversalExchangeSetup
		And DataReceivedForMapping 
		And DataMappingSupported <> False;
		
	FormItems = New Structure;
	FormItems.Insert("Group", Items.MapAndImportGroup.Name);
	FormItems.Insert("Panel", Items.MapAndImportPanel.Name);
	FormItems.Insert("PageSuccessfully", Items.MapAndImportPageSuccessful.Name);
	FormItems.Insert("PageCurrent", Items.MapAndImportPageActive.Name);
	FormItems.Insert("EmptySpacePage", Items.MapAndImportPageEmpty.Name);
	
	AddSetupStage("MapAndImport", "MapAndExportData", FormItems, TheStageIsUsed);
		
	// Initial data export
	TheStageIsUsed = InteractiveSendingAvailable 
		And (TransportSettingsAvailable Or NewSYnchronizationSetting);

	FormItems = New Structure;
	FormItems.Insert("Group", Items.InitialDataExportGroup.Name);
	FormItems.Insert("Panel", Items.InitialDataExportPanel.Name);
	FormItems.Insert("PageSuccessfully", Items.InitialDataExportPageSuccessful.Name);
	FormItems.Insert("PageCurrent", Items.InitialDataExportPageActive.Name);
	FormItems.Insert("EmptySpacePage", Items.InitialDataExportPageEmpty.Name);
	
	AddSetupStage("InitialDataExport", "ExecuteInitialDataExport", FormItems, TheStageIsUsed);
	
EndProcedure

&AtServer
Procedure SetInitialFormItemsView()
	
	Items.ExchangeBriefInfoLabelDecoration.Title = SettingOptionDetails.BriefExchangeInfo;
	Items.DataSyncDetails.Visible = ValueIsFilled(SettingOptionDetails.DetailedExchangeInformation);
	Items.GroupBackupPrompt.Visible = Backup;
	Items.GetConnectionConfirmation.ExtendedTooltip.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.GetConnectionConfirmation.ExtendedTooltip.Title,
		SettingOptionDetails.PeerInfobaseName);
		
	If Backup Then
		Items.BackupLabelDecoration.Title = StringFunctions.FormattedString(
			NStr("vi = 'Trước khi bắt đầu tùy chỉnh đồng bộ dữ liệu mới, nên <a href=""%1"">tạo bản sao dự phòng dữ liệu</a>.';
				|ru = 'Перед началом настройки новой синхронизации данных рекомендуется <a href=""%1"">создать резервную копию данных</a>.';
				|en = 'It is recommend that you <a href=""%1"">back up your data</a> before you start setting up a new data sync.'; fa = 'It is recommend that you <a href=""%1"">back up your data</a> before you start setting up a new data sync.';
				|it = 'Перед началом настройки новой синхронизации данных рекомендуется <a href=""%1"">создать резервную копию данных</a>.';
				|pl = 'It is recommend that you <a href=""%1"">back up your data</a> before you start setting up a new data sync.';
				|tr = 'Yeni veri senkronizasyon yapılandırılması öncesinde <a href=""%1"">verilerinizi yedeklemeniz</a> önerilir.'"),
			BackupDataProcessorURL);
	EndIf;
	
EndProcedure



#EndRegion

#EndRegion