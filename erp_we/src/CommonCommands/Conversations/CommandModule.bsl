///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	NewConversation = NewConversation(CommandParameter);
	
	If NewConversation = "Unavailable" Or NewConversation = "DisabledNoEnableRight" Then
		ShowMessageBox(, NStr("vi = 'Không thể sử dụng thảo luận. Hãy liên hệ với người quản trị.';
								|ru = 'Использование обсуждений недоступно. Обратитесь к администратору.';
								|en = 'Conversations are not available. Contact the Administrator.'; fa = 'Conversations are not available. Contact the Administrator.';
								|it = 'Uso delle discussioni non è accessibile. Rivolgersi all''amministratore.';
								|pl = 'Używanie dyskusji jest niedostępne. Zwróć się do administatora.';
								|tr = 'Sohbetler kullanılamıyor. Yöneticiyle iletişime geçin.'"));
		Return;
	ElsIf NewConversation = "DisabledCanEnable" Then
		SuggestConversationsText = 
			NStr("vi = 'Bật sử dụng thảo luận?
				|
				|Qua đó, người sử dụng sẽ có thể gửi cho nhau tin nhắn văn bản
				| và gọi điện video, tạo các cuộc thảo luận theo chủ đề và trao đổi liên lạc về chứng từ.';
				|ru = 'Включить обсуждения?
				|
				|С их помощью пользователи смогут отправлять друг другу текстовые сообщения 
				|и совершать видеозвонки, создавать тематические обсуждения и вести переписку по документам.';
				|en = 'Do you want to enable conversations?
				|
				|With them, users will be able to exchange text messages, make video calls,
				|create themed conversations, and correspond on documents.'; fa = 'Do you want to enable conversations?
				|
				|With them, users will be able to exchange text messages, make video calls,
				|create themed conversations, and correspond on documents.';
				|it = 'Abilitare le discussioni?
				|
				| Con il loro aiuto gli utenti saranno in grado di inviarsi messaggio di testo 
				| e fare videochiamate, creare discussioni tematiche e tenere corrispondenza sui documenti.';
				|pl = 'Włączyć dyskusje?
				|
				|Z ich pomocą użytkownicy będą mogli wysyłać wiadomości tekstowe 
				|i nawiązywać połączenia wideo, tworzyć dyskusje tematyczne i prowadzić korespondencję w dokumentach.';
				|tr = 'Sohbetler etkinleştirilsin mi?
				|
				|Sohbetler aracılığıyla kullanıcılar birbirlerine metin mesajları gönderebilir,
				| görüntülü aramalar yapabilir, konuya bağlı sohbetler oluşturabilir ve belgeler hakkında mesajlaşabilir.'");
		CallbackOnCompletion = New CallbackDescription("SuggestDiscussionsCompletion", ThisObject);
		
		ShowQueryBox(CallbackOnCompletion, SuggestConversationsText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	FileSystemClient.OpenURL(NewConversation);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SuggestDiscussionsCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ConversationsInternalClient.ShowConnection();
	
EndProcedure

&AtServer
Function NewConversation(UserRef)
	
	If Not ConversationsInternalServerCall.Connected2() Then
		If AccessRight("CollaborationSystemInfoBaseRegistration", Metadata) Then 
			Return "DisabledCanEnable";
		Else 
			Return "DisabledNoEnableRight";
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	InfoBaseUserID = Common.ObjectAttributeValue(
		UserRef, "IBUserID");
	SetPrivilegedMode(False);
	
	If Not ValueIsFilled(InfoBaseUserID) Then
		Return "Unavailable";
	EndIf;
	
	Try
		UserIDCollaborationSystem = CollaborationSystem.GetUserID(
			InfoBaseUserID);
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Để bắt đầu thảo luận, người sử dụng %1
			           | cần chạy ứng dụng ít nhất một lần.';
			           |ru = 'Для начала обсуждения необходимо, чтобы пользователь %1
			           |хотя бы один раз запустил приложение.';
			           |en = 'To start a conversation, user ""%1""
			           |must run the application at least once.'; fa = 'To start a conversation, user ""%1""
			           |must run the application at least once.';
			           |it = 'Для начала обсуждения необходимо, чтобы пользователь %1
			           |хотя бы один раз запустил приложение.';
			           |pl = 'To start a conversation, user ""%1""
			           |must run the application at least once.';
			           |tr = 'Bir sohbetin başlaması için kullanıcının en az bir kez%1
			           | uygulamayı başlatması gereklidir.'"),
			UserRef);
	EndTry;
	
	If UserIDCollaborationSystem = CollaborationSystem.CurrentUserID() Then 
		Raise NStr("vi = 'Để bắt đầu một cuộc thảo luận, hãy chọn người sử dụng khác.';
					|ru = 'Для начала обсуждения выберите другого пользователя.';
					|en = 'Select another user to start the conversation.'; fa = 'Select another user to start the conversation.';
					|it = 'Per l''inizio della discussione selezionare un altro utente.';
					|pl = 'Dla rozpoczęcia dyskusji wybierz innego użytkownika.';
					|tr = 'Sohbeti başlatmak için bir kullanıcı seçin.'");
	EndIf;
	
	Conversation = CollaborationSystem.CreateConversation();
	Conversation.Group = False;
	Conversation.Members.Add(CollaborationSystem.CurrentUserID());
	Conversation.Members.Add(UserIDCollaborationSystem);
	Conversation.Write();
	
	Return GetURL(Conversation.ID);
	
EndFunction

#EndRegion
