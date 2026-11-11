///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Function Connected2() Export
	
	Return ConversationsInternalServerCall.Connected2();
	
EndFunction

Procedure ShowConnection(CompletionDetails = Undefined) Export
	
	OpenForm("DataProcessor.EnableDiscussions.Form",,,,,, CompletionDetails);
	
EndProcedure

Procedure ShowDisconnection() Export
	
	If Not ConversationsInternalServerCall.Connected2() Then 
		ShowMessageBox(, NStr("vi = 'Đã vô hiệu hóa từ trước các cuộc thảo luận.';
								|ru = 'Обсуждения уже отключены ранее.';
								|en = 'Conversations are already disabled.'; fa = 'Conversations are already disabled.';
								|it = 'Le conversazioni sono state già precedentemente disattivate.';
								|pl = 'Dyskusje już zostały wyłączone wcześniej.';
								|tr = 'Sohbetler daha önce devre dışı bırakıldı.'"));
		Return;
	EndIf;
	
	Buttons = New ValueList;
	Buttons.Add("Disconnect", NStr("vi = 'Ngắt bỏ';
									|ru = 'Отключить';
									|en = 'Disable'; fa = 'غیرفعال';
									|it = 'Disattivare';
									|pl = 'Disable';
									|tr = 'Devre dışı bırak'"));
	Buttons.Add(DialogReturnCode.No);
	
	Notification = New CallbackDescription("AfterResponseToDisablePrompt", ThisObject);
	
	ShowQueryBox(Notification, NStr("vi = 'Ngắt thảo luận?';
									|ru = 'Отключить обсуждения?';
									|en = 'Do you want to disable conversations?'; fa = 'Do you want to disable conversations?';
									|it = 'Disattivare discussioni?';
									|pl = 'Wyłączyć dyskusje?';
									|tr = 'Sohbetler devre dışı bırakılsın mı?'"),
		Buttons,, DialogReturnCode.No);
	
EndProcedure

Procedure AfterWriteUser(Form, CompletionDetails) Export
	
	If Not Form.SuggestDiscussions
	 Or Not ValueIsFilled(Form.Object.IBUserID) Then
		RunCallback(CompletionDetails);
		Return;
	EndIf;
	
	Form.SuggestDiscussions = False;
		
	CallbackOnCompletion = New CallbackDescription("SuggestDiscussionsCompletion", ThisObject, CompletionDetails);
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.PromptDontAskAgain = True;
	QuestionParameters.Title = NStr("vi = 'Thảo luận (hệ thống tương tác)';
									|ru = 'Обсуждения (система взаимодействий)';
									|en = 'Conversations (collaboration system)'; fa = 'Conversations (collaboration system)';
									|it = 'Discussioni (sistema di interazioni)';
									|pl = 'Dyskusje (system interakcji)';
									|tr = 'Sohbetler (Ortak Çalışma Sistemi)'");
	StandardSubsystemsClient.ShowQuestionToUser(CallbackOnCompletion, Form.SuggestConversationsText,
		QuestionDialogMode.YesNo, QuestionParameters);
	
EndProcedure

Procedure OnGetCollaborationSystemUsersChoiceForm(ChoicePurpose, Form, ConversationID, Parameters, SelectedForm, StandardProcessing) Export

	Parameters.Insert("SelectConversationParticipants", True);
	Parameters.Insert("ChoiceMode", True);
	Parameters.Insert("CloseOnChoice", False);
	Parameters.Insert("MultipleChoice", True);
	Parameters.Insert("AdvancedPick", True);
	Parameters.Insert("SelectedUsers", New Array);
	Parameters.Insert("PickFormHeader", NStr("vi = 'Người tham gia thảo luận';
											|ru = 'Участники обсуждения';
											|en = 'Conversation members'; fa = 'اعضای گفتگو';
											|it = 'Partecipanti alla conversazione';
											|pl = 'Uczestnicy dyskusji';
											|tr = 'Sohbet üyeleri'"));
	
	StandardProcessing = False;
	
	SelectedForm = "Catalog.Users.ChoiceForm";

EndProcedure

Procedure ShowSettingOfIntegrationWithExternalSystems() Export
	OpenForm("DataProcessor.EnableDiscussions.Form.SettingsOfMessagesFromOtherApps",,ThisObject);
EndProcedure

Procedure OnStart(Parameters) Export
	
	CommandsGenerationHandler = New CallbackDescription("OnGenerateInteractionSystemCommands", ThisObject);
	CollaborationSystem.AttachGenerateCommandsHandler(CommandsGenerationHandler);
	
EndProcedure

#EndRegion

#Region Private

Procedure StartPickingConversationParticipants(Item) Export
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CloseOnChoice", False);
	FormParameters.Insert("MultipleChoice", True);
	FormParameters.Insert("AdvancedPick", True);
	FormParameters.Insert("SelectedUsers", New Array);
	FormParameters.Insert("PickFormHeader", NStr("vi = 'Người tham gia thảo luận';
												|ru = 'Участники обсуждения';
												|en = 'Conversation members'; fa = 'اعضای گفتگو';
												|it = 'Partecipanti alla conversazione';
												|pl = 'Uczestnicy dyskusji';
												|tr = 'Sohbet üyeleri'"));
	
	OpenForm("Catalog.Users.ChoiceForm", FormParameters,Item,,,,,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

Procedure ShowIntegrationInformation(Form, IntegrationDetails, IntegrationChangeNotification) Export

	Notification = New CallbackDescription("IntegrationCreationCompletion", ThisObject,
		New Structure("Notification", IntegrationChangeNotification));
		
	IntegrationTypes = ConversationsInternalClientServer.ExternalSystemsTypes();
	FormName = "DataProcessor.EnableDiscussions.Form";
	If IntegrationDetails.Type = IntegrationTypes.Telegram Then
		FormName = FormName + ".TelegramBotCreation";
	ElsIf IntegrationDetails.Type = IntegrationTypes.Max Then
		FormName = FormName + ".CreateMaxBot";
	ElsIf IntegrationDetails.Type = IntegrationTypes.VKontakte Then	
		FormName = FormName + ".BotCreationVKontakte";
	ElsIf IntegrationDetails.Type = IntegrationTypes.WhatsApp Then	
		FormName = FormName + ".WhatsAppBotCreation";
	ElsIf IntegrationDetails.Type = IntegrationTypes.WebChat Then	
		FormName = FormName + ".WebChatBotCreation";
	ElsIf IntegrationDetails.Type = IntegrationTypes.Webhook Then	
		FormName = FormName + ".WebhookBotCreation";
	EndIf;
		
	OpenForm(FormName, IntegrationDetails, Form,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

Procedure IntegrationCreationCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	RunCallback(AdditionalParameters.Notification, True);

EndProcedure

Procedure AfterResponseToDisablePrompt(ReturnCode, Context) Export
	
	If ReturnCode = "Disconnect" Then 
		OnDisconnect();
	EndIf;
	
EndProcedure

Procedure OnDisconnect()
	
	Notification = New CallbackDescription("AfterDisconnectSuccessfully", ThisObject,,
		"OnProcessDisableDiscussionError", ThisObject);
	
	Try
		CollaborationSystem.BeginInfoBaseUnregistration(Notification);
	Except
		OnProcessDisableDiscussionError(ErrorInfo(), False, Undefined);
	EndTry;
	
EndProcedure

Procedure AfterDisconnectSuccessfully(Context) Export
	
	Notify("ConversationsEnabled", False);
	
EndProcedure

Procedure OnProcessDisableDiscussionError(ErrorInfo, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	
	EventLogClient.AddMessageForEventLog(
		NStr("vi = 'Thảo luận.Lỗi hủy ghi nhận cơ sở thông tin';
			|ru = 'Обсуждения.Ошибка отмены регистрации информационной базы';
			|en = 'Conversations.An error occurred when unregistering infobase'; fa = 'Conversations.An error occurred when unregistering infobase';
			|it = 'Discussione. Errore di cancellazione della registrazione dell''infobase';
			|pl = 'Dyskusje.Błąd anulowania rejestracji bazy informacyjnej';
			|tr = 'Sohbetler.Infobase kaydı iptal edilirken hata oluştu'",
			CommonClient.DefaultLanguageCode()),
		"Error",
		ErrorProcessing.DetailErrorDescription(ErrorInfo),, True);
	
	StandardSubsystemsClient.OutputErrorInfo(ErrorInfo);
	
EndProcedure

Procedure SuggestDiscussionsCompletion(Result, CompletionDetails) Export
	
	If Result = Undefined Then
		RunCallback(CompletionDetails);
		Return;
	EndIf;
	
	If Result.NeverAskAgain Then
		CommonClient.CommonSettingsStorageSave("ApplicationSettings", "SuggestDiscussions", False);
	EndIf;
	
	If Result.Value = DialogReturnCode.Yes Then
		ShowConnection();
		Return;
	EndIf;
	RunCallback(CompletionDetails);
	
EndProcedure

Procedure OnGenerateInteractionSystemCommands(CommandsParameters, Commands, DefaultCommand, AdditionalParameters) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.UserReminders") Then
		ModuleUserReminderInternalClient = CommonClient.CommonModule("UserRemindersInternalClient");
		ModuleUserReminderInternalClient.AddConversationsCommands(CommandsParameters, Commands, DefaultCommand);
	EndIf;
	
	CheckRunningAction(CommandsParameters, Commands, DefaultCommand);
	
EndProcedure

Procedure CheckRunningAction(CommandsParameters, Commands, DefaultCommand)
	
	If Not ShouldShowSecurityWarnings(CommandsParameters) Then
		Return;
	EndIf;
	
	CommandsToRemove = New Array;
	
	For IndexOf = -Commands.UBound() To 0 Do
		If Commands[-IndexOf].Command = CollaborationSystemStandardCommand.OpenAttachment Then
			Commands.Delete(IndexOf);
		EndIf;
	EndDo;
	
	If Not ConversationsInternalServerCall.CanOpenExternalReportsAndDataProcessors() Then
		DefaultCommand = New CollaborationSystemCommandDescription(
			CollaborationSystemStandardCommand.SaveAttachment);
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("ShowSecurityWarning", ThisObject, CommandsParameters);
	DefaultCommand = New CollaborationSystemCommandDescription(CallbackDescription);
	
EndProcedure

Function ShouldShowSecurityWarnings(CommandsParameters)
	
	IsExternalReportOrDataProcessor = False;
	
	If CommandsParameters.Attachment <> Undefined Then
		File = New File (CommandsParameters.Attachment.Description);
		IsExternalReportOrDataProcessor = Lower(File.Extension) = ".erf" Or Lower(File.Extension) = ".epf";
	EndIf;
	
	Return IsExternalReportOrDataProcessor
		And AllowedAttachment()[AttachmentID(CommandsParameters)] <> True
		
EndFunction

Procedure ShowSecurityWarning(CommandsParameters) Export
	
	CallbackDescription = New CallbackDescription("ContinueOpenAttachment", ThisObject, CommandsParameters);
	UsersInternalClient.ShowSecurityWarning(CallbackDescription,
		UsersInternalClientServer.SecurityWarningKinds().BeforeAddExternalReportOrDataProcessor);
	
EndProcedure

Procedure ContinueOpenAttachment(Result, CommandsParameters) Export

	If Result <> "Continue" Then
		Return;
	EndIf;
	
	AllowedAttachment()[AttachmentID(CommandsParameters)] = True;
	
	CallbackDescription = New CallbackDescription("OnOpenStreamToReadAttachment",
		ThisObject, CommandsParameters.Attachment);
	
	CommandsParameters.Attachment.BeginOpenStreamForRead(CallbackDescription);
	
EndProcedure

Procedure OnOpenStreamToReadAttachment(Stream, Attachment) Export

	If Stream = Undefined Then
		Return;
	EndIf;
	
	BinaryDataBuffer = New BinaryDataBuffer(Attachment.Size);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("BinaryDataBuffer", BinaryDataBuffer);
	AdditionalParameters.Insert("Attachment", Attachment);

	CallbackDescription = New CallbackDescription("OnCompleteReadingStream", ThisObject, AdditionalParameters);
	
	Stream.BeginReading(CallbackDescription, BinaryDataBuffer, 0, Attachment.Size);

EndProcedure

Procedure OnCompleteReadingStream(Count, AdditionalParameters) Export
	
	BinaryDataBuffer = AdditionalParameters.BinaryDataBuffer;
	Attachment = AdditionalParameters.Attachment;
	BinaryData = GetBinaryDataFromBinaryDataBuffer(BinaryDataBuffer);
	AddressInTempStorage = PutToTempStorage(BinaryData);
	
	File = New File(Attachment.Description);
	
	If Lower(File.Extension) = ".epf" Then
		DataProcessorName = ConversationsInternalServerCall.AttachExternalDataProcessor(AddressInTempStorage);
		OpenForm("ExternalDataProcessor."+ DataProcessorName +".Form");
	ElsIf File.Extension = ".erf" Then
		ReportName = ConversationsInternalServerCall.AttachExternalReport(AddressInTempStorage);
		OpenForm("ExternalReport."+ ReportName +".Form");
	EndIf;	
	
EndProcedure

Function AttachmentID(CommandsParameters)
	
	If CommandsParameters.Attachment = Undefined Then
		Return Undefined;
	EndIf;

	Return StrTemplate("%1_%2_%3",
		CommandsParameters.Message.Id,
		CommandsParameters.Attachment.Description,
		CommandsParameters.Attachment.Size);
		
EndFunction
	
Function AllowedAttachment()

	ParameterName = "StandardSubsystems.Conversations.AllowedAttachment";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, New Map);
	EndIf;
	
	Return ApplicationParameters[ParameterName];

EndFunction

#EndRegion