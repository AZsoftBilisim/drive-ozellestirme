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
	
	ExternalSystemsTypes = ConversationsInternalClientServer.ExternalSystemsTypes();
	AvailableIntegrations = ConversationsInternal.AvailableIntegrations();
	AvailableCreationCommands = New Map;
		
	ExternalSystemType = ExternalSystemsTypes.Max;
	IsIntegrationAvailable = AvailableIntegrations.Find(ExternalSystemType) <> Undefined;
	AvailableCreationCommands["CreateMaxBot"] = IsIntegrationAvailable;
	If IsIntegrationAvailable Then
		Connection = ConnectionsList.GetItems().Add();
		Connection.Description = NStr("ru = 'Чаты Max';
										|vi = 'Chats in MAX';
										|en = 'Chats in MAX'; fa = 'Chats in MAX';
										|it = 'Chats in MAX';
										|pl = 'Chats in MAX';
										|tr = 'Max Sohbetleri'");
		Connection.Active = -1;
		Connection.Type = ExternalSystemType;
	EndIf;
	
	ExternalSystemType = ExternalSystemsTypes.Telegram;
	IsIntegrationAvailable = AvailableIntegrations.Find(ExternalSystemType) <> Undefined;
	AvailableCreationCommands["CreateTelegramBot"] = IsIntegrationAvailable;
	If IsIntegrationAvailable Then
		Connection = ConnectionsList.GetItems().Add();
		Connection.Description = NStr("vi = 'Trò chuyện Telegram';
										|ru = 'Чаты Telegram';
										|en = 'Telegram chats'; fa = 'Telegram chats';
										|it = 'Chat Telegram';
										|pl = 'Czaty Telegram';
										|tr = 'Telegram sohbetleri'");
		Connection.Active = -1;
		Connection.Type = ExternalSystemType;
	EndIf;

	ExternalSystemType = ExternalSystemsTypes.VKontakte;
	IsIntegrationAvailable = AvailableIntegrations.Find(ExternalSystemType) <> Undefined;
	AvailableCreationCommands["CreateBotVKontakte"] = IsIntegrationAvailable;
	If IsIntegrationAvailable Then
		Connection = ConnectionsList.GetItems().Add();
		Connection.Description = NStr("vi = 'Trò chuyện VKontakte';
										|ru = 'Чаты ВКонтакте';
										|en = 'VK chats'; fa = 'VK chats';
										|it = 'Chat Vkontakte';
										|pl = 'Czaty VKontakte';
										|tr = 'VK sohbetleri'");
		Connection.Active = -1;
		Connection.Type = ExternalSystemType;
	EndIf;
	
	ExternalSystemType = ExternalSystemsTypes.WhatsApp;
	IsIntegrationAvailable = AvailableIntegrations.Find(ExternalSystemType) <> Undefined;
	AvailableCreationCommands["CreateWhatsAppBot"] = IsIntegrationAvailable;
	If IsIntegrationAvailable Then
		Connection = ConnectionsList.GetItems().Add();
		Connection.Description = NStr("vi = 'Trò chuyện WhatsApp';
										|ru = 'Чаты WhatsApp';
										|en = 'WhatsApp chats'; fa = 'WhatsApp chats';
										|it = 'WhatsApp chats';
										|pl = 'WhatsApp chats';
										|tr = 'WhatsApp sohbetleri'");
		Connection.Active = -1;
		Connection.Type = ExternalSystemType;
	EndIf;
	
	ExternalSystemType = ExternalSystemsTypes.WebChat;
	IsIntegrationAvailable = AvailableIntegrations.Find(ExternalSystemType) <> Undefined;
	AvailableCreationCommands["CreateWebChat"] = IsIntegrationAvailable;
	If IsIntegrationAvailable Then
		Connection = ConnectionsList.GetItems().Add();
		Connection.Description = NStr("vi = 'Trò chuyện trên trang web';
										|ru = 'Чаты на сайте';
										|en = 'Website chats'; fa = 'Website chats';
										|it = 'Website chats';
										|pl = 'Website chats';
										|tr = 'Site sohbetleri'");
		Connection.Active = -1;
		Connection.Type = ExternalSystemType;
	EndIf;
	
	ExternalSystemType = ExternalSystemsTypes.Webhook;
	IsIntegrationAvailable = AvailableIntegrations.Find(ExternalSystemType) <> Undefined;
	AvailableCreationCommands["CreateWebhookBot"] = IsIntegrationAvailable;
	If IsIntegrationAvailable Then
		Connection = ConnectionsList.GetItems().Add();
		Connection.Description = NStr("vi = 'Tích hợp Webhook';
										|ru = 'Интеграция Webhook';
										|en = 'Webhook integration'; fa = 'یکپارچه‌سازی Webhook';
										|it = 'Webhook integration';
										|pl = 'Webhook integration';
										|tr = 'Webhook entegrasyonu'");
		Connection.Active = -1;
		Connection.Type = ExternalSystemType;
	EndIf;

	UpdateIntegrationsList(AvailableIntegrations);
	SetCreationCommandsVisibility(AvailableCreationCommands);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateMaxBot(Command)
	Notification = New CallbackDescription("AfterChangeIntegration", ThisObject);
	ConversationsInternalClient.ShowIntegrationInformation(ThisObject, 
		New Structure("Type", ConversationsInternalClientServer.ExternalSystemsTypes().Max),
		Notification);
EndProcedure

&AtClient
Procedure CreateTelegramBot(Command)
	Notification = New CallbackDescription("AfterChangeIntegration", ThisObject);
	ConversationsInternalClient.ShowIntegrationInformation(ThisObject, 
		New Structure("Type", ConversationsInternalClientServer.ExternalSystemsTypes().Telegram),
		Notification);
EndProcedure

&AtClient
Procedure CreateBotVKontakte(Command)
	Notification = New CallbackDescription("AfterChangeIntegration", ThisObject);
	ConversationsInternalClient.ShowIntegrationInformation(ThisObject, 
		New Structure("Type", ConversationsInternalClientServer.ExternalSystemsTypes().VKontakte),
		Notification);
EndProcedure

&AtClient
Procedure CreateWhatsAppBot(Command)
	
	Notification = New CallbackDescription("AfterChangeIntegration", ThisObject);
	ConversationsInternalClient.ShowIntegrationInformation(ThisObject, 
		New Structure("Type", ConversationsInternalClientServer.ExternalSystemsTypes().WhatsApp),
		Notification);

EndProcedure

&AtClient
Procedure CreateWebChat(Command)
	
	Notification = New CallbackDescription("AfterChangeIntegration", ThisObject);
	ConversationsInternalClient.ShowIntegrationInformation(ThisObject, 
		New Structure("Type", ConversationsInternalClientServer.ExternalSystemsTypes().WebChat),
		Notification);
		
EndProcedure

&AtClient
Procedure CreateWebhookBot(Command)
	
	Notification = New CallbackDescription("AfterChangeIntegration", ThisObject);
	ConversationsInternalClient.ShowIntegrationInformation(ThisObject, 
		New Structure("Type", ConversationsInternalClientServer.ExternalSystemsTypes().Webhook),
		Notification);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetCreationCommandsVisibility(AvailableCreationCommands)
	
	For Each CreationElement In Items.CreateSubmenu.ChildItems Do
		CreationElement.Visible = (AvailableCreationCommands[CreationElement.CommandName] = True);
	EndDo;
	
EndProcedure

&AtClient
Procedure AfterChangeIntegration(Result, AdditionalParameters) Export
	UpdateIntegrationsList();
EndProcedure

&AtServer
Procedure UpdateIntegrationsList(Val AvailableIntegrations = Undefined)

	If Not Conversations.ConversationsAvailable() Then
		Return;
	EndIf;
	
	IntegrationTypes = New Map;
	
	For Each IntegrationType In ConnectionsList.GetItems() Do
		IntegrationType.GetItems().Clear();
		IntegrationTypes.Insert(IntegrationType.Type, IntegrationType);
	EndDo;
	
	IntegrationsTable = New ValueTable;
	IntegrationsTable.Columns.Add("Use");
	IntegrationsTable.Columns.Add("Presentation");
	IntegrationsTable.Columns.Add("Id");
	IntegrationsTable.Columns.Add("ExternalSystemType");
	
	Integrations = CollaborationSystem.GetIntegrations();
	If AvailableIntegrations = Undefined Then
		AvailableIntegrations = ConversationsInternal.AvailableIntegrations();
	EndIf;
	For Each Integration In Integrations Do
		If AvailableIntegrations.Find(Integration.ExternalSystemType) <> Undefined Then
			FillPropertyValues(IntegrationsTable.Add(), Integration);
		EndIf;
	EndDo;
	
	IntegrationsTable.Sort("Presentation Asc");
	
	For Each Integration In IntegrationsTable Do
		
		Category = IntegrationTypes[Integration.ExternalSystemType];
		If Category <> Undefined Then
			NewIntegration = Category.GetItems().Add();
			IntegrationToFormData(Integration, NewIntegration);	
		Else
			WriteLogEvent(ConversationsInternal.EventLogEvent(),
				EventLogLevel.Error,,,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Kiểu tích hợp ngoài không được hỗ trợ %1.';
						|ru = 'Неподдерживаемый тип внешней интеграции %1.';
						|en = 'Unsupported external integration type: %1.'; fa = 'Unsupported external integration type: %1.';
						|it = 'Unsupported external integration type: %1.';
						|pl = 'Unsupported external integration type: %1.';
						|tr = '%1 harici entegrasyon türü desteklenmiyor.'"), Integration.ExternalSystemType));
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  Integration - CollaborationSystemIntegration 
//  FormData1 - FormDataTreeItem of See DataProcessor.EnableDiscussions.Form.SettingsOfMessagesFromOtherApps.ConnectionsList
//
&AtServer
Procedure IntegrationToFormData(Val Integration, Val FormData1)
	
	FormData1.Active = ?(Integration.Use, 0, 2);
	FormData1.Description = Integration.Presentation;
	FormData1.Id = Integration.ID;
	FormData1.Type = Integration.ExternalSystemType;

EndProcedure

&AtClient
Procedure ConnectionsListSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	
	Integration = ConnectionsList.FindByID(RowSelected);
	If Integration.Id = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("AfterChangeIntegration", ThisObject);
	FormParameters = New Structure;
	FormParameters.Insert("Type", Integration.Type);
	FormParameters.Insert("Id", Integration.Id);
	ConversationsInternalClient.ShowIntegrationInformation(ThisObject, FormParameters, Notification);
EndProcedure

&AtClient
Procedure Refresh(Command)
	UpdateAtServer();
EndProcedure

&AtServer
Procedure UpdateAtServer()
	UpdateIntegrationsList();
EndProcedure

#EndRegion
