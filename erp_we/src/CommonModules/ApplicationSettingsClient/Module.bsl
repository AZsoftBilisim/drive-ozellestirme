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

// Called from the "OnOpen" handler of the SSL/OSL administration panel.
// Sets up the visibility of the SSL library management elements.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  Cancel - Boolean
//
Procedure OnlineSupportAndServicesOnOpen(Form, Cancel) Export
	
	// Update items states.
	OnlineSupportAndServicesSetAvailability(Form);
	
	OnlineSupportAndServicesOnChangeOfChatConnectionStatus(Form);
	
EndProcedure

// Called from the "NotificationProcessing" handler of the SSL/OSL administration panel.
// Sets up the visibility of the SSL library management elements.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  EventName - String - The event name (for identifying messages).
//  Parameter - Arbitrary - an event parameter.
//  Source - Arbitrary - Event source.
//
Procedure OnlineSupportAndServicesProcessNotification(Form, EventName, Parameter, Source) Export
	
	If EventName = "ConversationsEnabled" Then
		OnlineSupportAndServicesOnChangeOfChatConnectionStatus(Form, Parameter);
	EndIf;
	
EndProcedure

// Handles the "OnChange" event on the following forms of the SSL/OSL "Online support and services" administration panel:
// "MonitoringCenterAllowSendingData", "MonitoringCenterAllowSendingDataToThirdParty", "MonitoringCenterProhibitSendingData".
// 
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  Item - FormField
//  OperationParametersList - Structure:
//    * RunResult - See TimeConsumingOperations.ExecuteInBackground
//
Procedure OnlineSupportAndServicesAllowSendDataOnChange(Form, Item, OperationParametersList) Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.MonitoringCenter")
		Or OperationParametersList.RunResult = Undefined Then
		Return;
	EndIf;

	Form.MonitoringCenterJobID = OperationParametersList.RunResult.JobID;
	Form.MonitoringCenterJobResultAddress = OperationParametersList.RunResult.ResultAddress;
	ModuleMonitoringCenterClient = CommonClient.CommonModule("MonitoringCenterClient");
	Notification = New CallbackDescription("AfterUpdateID", ModuleMonitoringCenterClient);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OutputIdleWindow = False;
	TimeConsumingOperationsClient.WaitCompletion(OperationParametersList.RunResult, Notification, IdleParameters);
	
EndProcedure

// Handles the "OnChange" event associated with the constant on
// the SSL form the SSL/OSL "Online support and services" administration panel.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  Item - FormField
//
Procedure OnlineSupportAndServicesOnConstantChange(Form, Item) Export
	
	ConstantName = Item.Name;
	
	OnlineSupportAndServicesSetAvailability(Form, ConstantName);
	RefreshReusableValues();
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

// Handles events of the "AddressClassifierLoading" command of
// the SSL/OSL "Online support and services" administration panel.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  Command - FormCommand
//
Procedure OnlineSupportAndServicesImportAddressClassifier(Form, Command) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.AddressClassifier") Then
		ModuleAddressClassifierClient = CommonClient.CommonModule("AddressClassifierClient");
		ModuleAddressClassifierClient.LoadAddressClassifier();
	EndIf;
	
EndProcedure

// Handles events of the "ClearAddressInfoRecords" command of
// the SSL/OSL "Online support and services" administration panel.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  Command - FormCommand
//
Procedure OnlineSupportAndServicesClearAddressInfoRecords(Form, Command) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.AddressClassifier") Then
		ModuleAddressClassifierClient = CommonClient.CommonModule("AddressClassifierClient");
		ModuleAddressClassifierClient.ShowCleaningOfAddressClassifier();
	EndIf;
	
EndProcedure

// Handles events of the "ImportCurrenciesRates" command of
// the "Online support and services" in SSL/OSL administration panel.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  Command - FormCommand
//
Procedure OnlineSupportAndServicesImportExchangeRates(Form, Command) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.Currencies") Then
		ModuleCurrencyExchangeRatesClient = CommonClient.CommonModule("CurrencyRateOperationsClient");
		ModuleCurrencyExchangeRatesClient.ShowExchangeRatesImport();
	EndIf;
	
EndProcedure

// Handles events of the "OpenChangeHistory" command of
// the SSL/OSL "Online support and services" administration panel.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  Command - FormCommand
//
Procedure OnlineSupportAndServicesSystemChangelog(Form, Command) Export
	
	OpenForm("CommonForm.ApplicationReleaseNotes",, Form);
	
EndProcedure

// Handles events of the "ConfigureAccessToMorpher" command of
// the SSL/OSL "Online support and services" administration panel.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  Command - FormCommand
//
Procedure OnlineSupportAndServicesConfigureAccessToMorpher(Form, Command) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.ObjectPresentationDeclension") Then
		ModuleObjectsPresentationsDeclensionClient = CommonClient.CommonModule(
			"ObjectPresentationDeclensionClient");
		ModuleObjectsPresentationsDeclensionClient.ShowMorpherServiceAccessSettings();
	EndIf;
	
EndProcedure

// Handles events of the "MonitoringCenterSettings" command of
// the SSL/OSL "Online support and services" administration panel.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  Command - FormCommand
//
Procedure OnlineSupportAndServicesMonitoringCenterSettings(Form, Command) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		OpeningParameters = New Structure;
		OpeningParameters.Insert("JobID"  , Form.MonitoringCenterJobID);
		OpeningParameters.Insert("JobResultAddress", Form.MonitoringCenterJobResultAddress);
		ModuleMonitoringCenterClient = CommonClient.CommonModule("MonitoringCenterClient");
		ModuleMonitoringCenterClient.ShowMonitoringCenterSettings(Form, OpeningParameters);
	EndIf;
	
EndProcedure

// Handles events of the "MonitoringCenterSendContactInformation" command of
// the SSL/OSL "Online support and services" administration panel.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  Command - FormCommand
//
Procedure OnlineSupportAndServicesMonitoringCenterSendContactInfo(Form, Command) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		ModuleMonitoringCenterClient = CommonClient.CommonModule("MonitoringCenterClient");
		ModuleMonitoringCenterClient.ShowSendSettingOfContactInfo(Form);
	EndIf;
	
EndProcedure

// Handles events of the "OpenAddIns" command of
// the SSL/OSL "Online support and services" administration panel.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  Command - FormCommand
//
Procedure OnlineSupportAndServicesOpenAddIns(Form, Command) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.AddIns") Then
		ModuleAddInsClient = CommonClient.CommonModule("AddInsClient");
		ModuleAddInsClient.ShowAddIns();
	EndIf;
	
EndProcedure

// Handles events of the "UpdateResultsAndAdditionalDataProcessing" command of
// the SSL/OSL "Online support and services" administration panel.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  Command - FormCommand
//
Procedure OnlineSupportAndServicesOpenInfobaseUpdateProgress(Form, Command) Export
	
	FormParameters = New Structure("OpenedFromAdministrationPanel", True);
	OpenForm(
		"DataProcessor.ApplicationUpdateResult.Form.ApplicationUpdateResult",
		FormParameters);
	
EndProcedure

// Handles events of the "EnableDisableConversations" command of
// the SSL/OSL "Online support and services" administration panel.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  Command - FormCommand
//
Procedure OnlineSupportAndServicesToggleConversations(Form, Command) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.Conversations") Then
		
		ModuleConversationsInternalClient = CommonClient.CommonModule("ConversationsInternalClient");
		
		If ModuleConversationsInternalClient.Connected2() Then
			ModuleConversationsInternalClient.ShowDisconnection();
		Else
			ModuleConversationsInternalClient.ShowConnection();
		EndIf;
		
	EndIf;
	
EndProcedure

// Handles events of the "ConversationsConfigureIntegrationWithExternalSystems" command of
// the SSL/OSL "Online support and services" administration panel.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  Command - FormCommand
//
Procedure OnlineSupportAndServicesShowSettingForIntegrationWithExternalSystems(Form, Command) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.Conversations") Then
		ModuleConversationsInternalClient = CommonClient.CommonModule("ConversationsInternalClient");
		ModuleConversationsInternalClient.ShowSettingOfIntegrationWithExternalSystems();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Procedure OpenCommonSettings() Export
	
	OpenForm("DataProcessor.SSLAdministrationPanel.Form.CommonSettings");
	
EndProcedure

#EndRegion

#Region Private

Procedure OnlineSupportAndServicesOnChangeOfChatConnectionStatus(
	Form,
	ConversationsEnabled = Undefined)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Conversations") Then
		
		Items = Form.Items;
		
		If ConversationsEnabled = Undefined Then
			ModuleConversationsInternalClient = CommonClient.CommonModule("ConversationsInternalClient");
			ConversationsEnabled = ModuleConversationsInternalClient.Connected2();
			Form.ConversationsEnabled = ConversationsEnabled;
		EndIf;
		
		If ConversationsEnabled Then
			Items.EnableDisableConversations.Title = NStr("vi = 'Ngắt bỏ';
															|ru = 'Отключить';
															|en = 'Disable'; fa = 'غیرفعال';
															|it = 'Отключить';
															|pl = 'Disable';
															|tr = 'Devre dışı bırak'");
			Items.ConversationsEnabledState.Title = NStr("vi = 'Đã kết nối thảo luận.';
														|ru = 'Обсуждения подключены.';
														|en = 'Conversations are enabled.'; fa = 'Conversations are enabled.';
														|it = 'Обсуждения подключены.';
														|pl = 'Conversations are enabled.';
														|tr = 'Tartışmalar etkinleştirildi.'");
			CommonClientServer.SetFormItemProperty(Items,
				"ConversationsConfigureIntegrationWithExternalSystems",
				"Enabled",
				True);
		Else
			Items.EnableDisableConversations.Title = NStr("vi = 'Kết nối';
															|ru = 'Подключить';
															|en = 'Enable'; fa = 'فعال';
															|it = 'Подключить';
															|pl = 'Enable';
															|tr = 'Bağla'");
			Items.ConversationsEnabledState.Title = NStr("vi = 'Chưa kết nối thảo luận.';
														|ru = 'Подключение обсуждений не выполнено.';
														|en = 'Conversations are disabled.'; fa = 'Conversations are disabled.';
														|it = 'Подключение обсуждений не выполнено.';
														|pl = 'Conversations are disabled.';
														|tr = 'Konuşmalar devre dışı.'");
			CommonClientServer.SetFormItemProperty(Items,
				"ConversationsConfigureIntegrationWithExternalSystems",
				"Enabled",
				False);
		EndIf;
		
	EndIf;
	
EndProcedure

// Updates the elements availability on the SSL/OSL "Online support and services" administration panel.
//
// Parameters:
//  Form - See DataProcessor.SSLAdministrationPanel.
//  ConstantName - String - If filled, the elements associated with the command are updated.
//
Procedure OnlineSupportAndServicesSetAvailability(Form, ConstantName = "")
	
	If Not Form.IsSystemAdministrator Then
		Return;
	EndIf;
	
	Items = Form.Items;
	
	If (ConstantName = "UseMorpherDeclinationService" Or ConstantName = "")
		And CommonClient.SubsystemExists("StandardSubsystems.ObjectPresentationDeclension") Then
		
		CommonClientServer.SetFormItemProperty(
			Items,
			"InflectionSettingsGroup",
			"Enabled",
			Form.UseMorpherDeclinationService);
			
	EndIf;
	
EndProcedure

#EndRegion