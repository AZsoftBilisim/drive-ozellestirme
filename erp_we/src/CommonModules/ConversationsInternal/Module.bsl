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
	
	// A server call makes sure the correct state is obtained if the infobase registration data
	// was modified by the method "CollaborationSystem.SetInfoBaseRegistrationData". 
	// It runs faster and doesn't make calls to the Collaboration server.
	//
	// 
	CanUse = CollaborationSystem.CanUse();
	
	Return CanUse And Not Locked2();
	
EndFunction

Function Locked2() Export
	
	SetPrivilegedMode(True);
	RegistrationDetails = Common.ReadDataFromSecureStorage(
		"CollaborationSystemInfoBaseRegistrationData");
	Locked2 = RegistrationDetails <> Undefined;
	Return Locked2;
	
EndFunction

Procedure Lock() Export 
	
	If Not AccessRight("DataAdministration", Metadata) Then 
		Raise 
			NStr("vi = 'Chưa phong tỏa thảo luận. Để thực hiện giao dịch, cần có quyền quản trị dữ liệu.';
				|ru = 'Обсуждения не заблокированы. Для выполнения операции требуется право администрирования данных.';
				|en = 'Conversations are not locked. To perform the operation, you need to have data administration rights.'; fa = 'Conversations are not locked. To perform the operation, you need to have data administration rights.';
				|it = 'Le discussioni non sono bloccate. L''operazione richiede la corretta amministrazione dei dati.';
				|pl = 'Dyskusje nie są zablokowane. W celu wykonania operacji wymagane są uprawnienia administrowania danych.';
				|tr = 'Sohbetler kilitlenmedi. İşlemi yürütmek için veri yönetimi yetkisi gereklidir.'");
	EndIf;
	
	If Locked2() Then 
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	RegistrationDetails = CollaborationSystem.GetInfoBaseRegistrationData();
	If TypeOf(RegistrationDetails) = Type("CollaborationSystemInfoBaseRegistrationData") Then
		Common.WriteDataToSecureStorage(
			"CollaborationSystemInfoBaseRegistrationData", 
			RegistrationDetails);
	EndIf;
	CollaborationSystem.SetInfoBaseRegistrationData(Undefined);
	
EndProcedure

Procedure Unlock() Export 
	
	If Not AccessRight("DataAdministration", Metadata) Then 
		Raise 
			NStr("vi = 'Chưa phong tỏa thảo luận. Để thực hiện giao dịch, cần có quyền quản trị dữ liệu.';
				|ru = 'Обсуждения не заблокированы. Для выполнения операции требуется право администрирования данных.';
				|en = 'Conversations are not locked. To perform the operation, you need to have data administration rights.'; fa = 'Conversations are not locked. To perform the operation, you need to have data administration rights.';
				|it = 'Le discussioni non sono bloccate. L''operazione richiede la corretta amministrazione dei dati.';
				|pl = 'Dyskusje nie są zablokowane. W celu wykonania operacji wymagane są uprawnienia administrowania danych.';
				|tr = 'Sohbetler kilitlenmedi. İşlemi yürütmek için veri yönetimi yetkisi gereklidir.'");
	EndIf;
	
	SetPrivilegedMode(True);
	RegistrationDetails = Common.ReadDataFromSecureStorage(
		"CollaborationSystemInfoBaseRegistrationData");
	Common.DeleteDataFromSecureStorage("CollaborationSystemInfoBaseRegistrationData");
	If TypeOf(RegistrationDetails) = Type("CollaborationSystemInfoBaseRegistrationData") Then 
		CollaborationSystem.SetInfoBaseRegistrationData(RegistrationDetails);
	EndIf;
	RegistrationDetails = Undefined;
	
EndProcedure

// Parameters:
//  Cancel - Boolean
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForObjects
//  Object - FormDataStructure
//         - CatalogObject.Users
//
Procedure OnCreateAtUserServer(Cancel, Form, Object) Export
	
	If Not AccessRight("DataAdministration", Metadata) Then
		Form.SuggestDiscussions = False;
		Return;
	EndIf;
	
	SuggestDiscussions = Common.CommonSettingsStorageLoad("ApplicationSettings", "SuggestDiscussions", True);
	Form.SuggestDiscussions = Not Cancel And Not ValueIsFilled(Object.IBUserID) And SuggestDiscussions 
		And Not ConversationsInternalServerCall.Connected2();
	If Not Form.SuggestDiscussions Then
		Return;
	EndIf;
	
	AdministrationSubsystem = Metadata.Subsystems.Find("Administration");
	If AdministrationSubsystem <> Undefined Then 
		EnableLater = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Có thể kích hoạt thảo luận sau từ phân hệ %1.';
				|ru = 'Включить обсуждения также можно позднее из раздела %1.';
				|en = 'You can also enable conversations later from the %1 section.'; fa = 'You can also enable conversations later from the %1 section.';
				|it = 'È possibile attivare la discussione anche in seguito tramite la sezione %1.';
				|pl = 'Możesz także dołączyć dyskusje później w sekcji %1.';
				|tr = 'Sohbetleri sonradan %1 bölümünden etkinleştirebilirsiniz.'"),
			AdministrationSubsystem.Synonym);
	Else
		EnableLater = NStr("vi = 'Có thể bật sử dụng thảo luận sau từ tùy chỉnh ứng dụng.';
							|ru = 'Включить обсуждения также можно позднее из настроек приложения.';
							|en = 'You can also enable conversations later from the app settings.'; fa = 'You can also enable conversations later from the app settings.';
							|it = 'Включить обсуждения также можно позднее из настроек приложения.';
							|pl = 'You can also enable conversations later from the app settings.';
							|tr = 'Sohbetleri sonradan uygulama ayarlarından etkinleştirebilirsiniz.'");
	EndIf;
	
	Form.SuggestConversationsText = 
		NStr("vi = 'Bật thảo luận?
			       |
			       |Qua đó, người sử dụng có thể gửi tin nhắn văn bản cho nhau và gọi điện video, tạo các cuộc thảo luận theo chủ đề và trao đổi liên lạc theo chứng từ.';
			       |ru = 'Включить обсуждения?
			       |
			       |С их помощью пользователи смогут отправлять друг другу текстовые сообщения и совершать видеозвонки, создавать тематические обсуждения и вести переписку по документам.';
			       |en = 'Do you want to enable conversations?
			       |
			       |With them, users will be able to exchange text messages, make video calls, create themed conversations, and correspond on documents.'; fa = 'Do you want to enable conversations?
			       |
			       |With them, users will be able to exchange text messages, make video calls, create themed conversations, and correspond on documents.';
			       |it = 'Abilitare le discussioni?
			       |
			       | Con il loro aiuto, gli utenti saranno in grado di inviarsi reciprocamente messaggi di testo e fare videochiamate, creare discussioni tematiche e mantenere la corrispondenza sui documenti.';
			       |pl = 'Włącz dyskusje?
			       |
			       |Z ich pomocą użytkownicy będą mogli wysyłać wiadomości tekstowe i nawiązywać połączenia wideo, tworzyć dyskusje tematyczne i prowadzić korespondencję w dokumentach.';
			       |tr = 'Sohbetler etkinleştirilsin mi?
			       |
			       |Sohbetler aracılığıyla kullanıcılar birbirlerine metin mesajları gönderebilir, görüntülü aramalar yapabilir, konuya bağlı sohbetler oluşturabilir ve belgeler hakkında mesajlaşabilir.'")
			+ Chars.LF + Chars.LF + EnableLater;
	
EndProcedure

#Region InterfaceImplementation

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	Permissions = New Array;
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	Resolution = ModuleSafeModeManager.PermissionToUseInternetResource("WSS", "1cdialog.com", 443, 
		NStr("vi = 'Dịch vụ 1C:Dialog cho hệ thống tương tác (thảo luận theo chủ đề, trao đổi thư từ và cuộc gọi video giữa những người sử dụng ứng dụng).';
			|ru = 'Сервис 1С:Диалог для системы взаимодействия (тематические обсуждения, переписка и видеозвонки между пользователями приложения).';
			|en = '1C:Dialog service for Collaboration System (provides chat rooms, messaging, and video calls).'; fa = '1C:Dialog service for Collaboration System (provides chat rooms, messaging, and video calls).';
			|it = 'Сервис 1С:Диалог для системы взаимодействия (тематические обсуждения, переписка и видеозвонки между пользователями приложения).';
			|pl = '1C:Dialog service for Collaboration System (provides chat rooms, messaging, and video calls).';
			|tr = 'Ortak Çalışma Sistemi için 1C:Dialog servisi (uygulama kullanıcıları arasında konuya bağlı sohbetler, mesajlaşmalar ve görüntülü aramalar).'"));
	Permissions.Add(Resolution);
	Resolution = ModuleSafeModeManager.PermissionToUseInternetResource("HTTPS", "*.s3storage.ru", 443, 
		NStr("vi = 'Dịch vụ 1C:Dialog dành cho hệ thống giao tiếp (Kho chứa tệp dịch vụ).';
			|ru = 'Сервис 1С:Диалог для системы взаимодействия (Хранилище файлов сервиса).';
			|en = '1C:Dialog service for Collaboration System (Service file storage).'; fa = '1C:Dialog service for Collaboration System (Service file storage).';
			|it = 'Сервис 1С:Диалог для системы взаимодействия (Хранилище файлов сервиса).';
			|pl = '1C:Dialog service for Collaboration System (Service file storage).';
			|tr = 'Etkileşim sistemi için 1C:Dialog Servisi (Servis dosyası depolama).'"));
	Permissions.Add(Resolution);
	Resolution = ModuleSafeModeManager.PermissionToUseInternetResource("HTTP", "clr.globalsign.com", 80, 
		NStr("vi = 'Dịch vụ 1C:Dialog dành cho hệ thống giao tiếp (Dịch vụ kiểm tra thu hồi chứng thư).';
			|ru = 'Сервис 1С:Диалог для системы взаимодействия (Сервер проверки отзыва сертификатов).';
			|en = '1C:Dialog service for Collaboration System (Certificate revocation check server).'; fa = '1C:Dialog service for Collaboration System (Certificate revocation check server).';
			|it = 'Сервис 1С:Диалог для системы взаимодействия (Сервер проверки отзыва сертификатов).';
			|pl = '1C:Dialog service for Collaboration System (Certificate revocation check server).';
			|tr = 'Etkileşim sistemi için 1C:Dialog Servisi (Sertifika iptal kontrolü sunucusu).'"));
	Permissions.Add(Resolution);
	PermissionsRequests.Add(ModuleSafeModeManager.RequestToUseExternalResources(Permissions));
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Version = "3.1.3.282";
	Handler.Id = New UUID("b3be68c5-708d-42c9-a019-818036d09d06");
	Handler.Procedure = "ConversationsInternal.LockInvalidUsersInCollaborationSystem";
	Handler.ExecutionMode = "Deferred";
	Handler.Comment = NStr("vi = 'Chặn người dùng không có hiệu lực trong hệ thống tương tác.';
							|ru = 'Блокировка недействительных пользователей в системе взаимодействия.';
							|en = 'Disable inactive users in the Collaboration System.'; fa = 'غیرفعال کردن کاربران غیرفعال در سیستم همکاری.';
							|it = 'Blocco degli utenti inattivi nel sistema di collaborazione.';
							|pl = 'Blokowanie nieważnych użytkowników w systemie interakcji.';
							|tr = 'Ortak çalışma sisteminde geçersiz kullanıcıları engelle.'");
	Handler.UpdateDataFillingProcedure = "ConversationsInternal.UsersToBlockInteractionsInTheSystem";
	Handler.ObjectsToRead = "Catalog.Users";
	Handler.ObjectsToChange = "CollaborationSystemUser";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
EndProcedure

// Locks a collaboration system user. 
// If errors occur when locking, ErrorInfo is returned.
// If the user is locked, Undefined is returned.
//
// Parameters:
//    User - CatalogRef.Users
//
// Returns:
//  ErrorInfo, Undefined
//
Function BlockAnInteractionSystemUser(User) Export

	Result = Undefined;
	IBUserID = Common.ObjectAttributeValue(User, "IBUserID");
	If Not ValueIsFilled(IBUserID) Then
		Return Result;
	EndIf;
	
	UserIDCollaborationSystem = Undefined;
	Try
		UserIDCollaborationSystem = CollaborationSystem.GetUserID(
			IBUserID);
	Except
		// ACC:280 - A thrown exception means the Collaboration System user was not found.
	EndTry;
	
	If UserIDCollaborationSystem = Undefined Then
		Return Result;
	EndIf;	
	
	ThePatternOfLogRecording = NStr("vi = 'Người sử dụng %1 không có hiệu lực. Người sử dụng hệ thống tương tác bị chặn';
									|ru = 'Пользователь %1 недействителен. Пользователь системы взаимодействий заблокирован';
									|en = 'The %1 user is invalid. The collaboration system user is locked'; fa = 'The %1 user is invalid. The collaboration system user is locked';
									|it = 'L''utente %1 è inattivo. L''utente del sistema di collaborazione è stato bloccato';
									|pl = 'Użytkownik %1 jest nieważny. Użytkownik systemu interakcji jest zablokowany';
									|tr = '%1 kullanıcısı geçersiz. Ortak çalışma sistemi kullanıcısı engellendi'");
	Try
		CollaborationSystemUser = CollaborationSystem.GetUser(UserIDCollaborationSystem);
		CollaborationSystemUser.IsLocked = True;
		CollaborationSystemUser.Write();
		WriteLogEvent(
			EventLogEvent(NStr("vi = 'Chặn người dùng không có hiệu lực';
								|ru = 'Блокировка недействительных пользователей';
								|en = 'Disable inactive users'; fa = 'Disable inactive users';
								|it = 'Blocco degli utenti inattivi';
								|pl = 'Blokowanie nieważnych użytkowników';
								|tr = 'Geçersiz kullanıcıların engellenmesi'", Common.DefaultLanguageCode())),
			EventLogLevel.Information,, User,
			StringFunctionsClientServer.SubstituteParametersToString(ThePatternOfLogRecording, User));
	Except
		Result = ErrorInfo();
	EndTry;
	
	Return Result;
EndFunction

// Returns an array of users who must be locked in the collaboration system.
//
// Returns:
//    Array of CatalogRef.Users
//
Function InvalidUsers() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Invalid
	|	 OR Users.DeletionMark";
	Result = Query.Execute().Unload();
	ReferencesArrray = Result.UnloadColumn("Ref");
	Return ReferencesArrray;

EndFunction

Procedure UsersToBlockInteractionsInTheSystem(Parameters) Export

	If Not Connected2() Then
		Return;
	EndIf;
	
	ReferencesArrray = InvalidUsers();
    InfobaseUpdate.MarkForProcessing(Parameters, ReferencesArrray);

EndProcedure

Procedure LockInvalidUsersInCollaborationSystem(ParametersOfUpdate) Export

	FullMetadataObjectName = "Catalog.Users";
	Users_Selection = InfobaseUpdate.SelectRefsToProcess(ParametersOfUpdate.Queue, FullMetadataObjectName);
			
	ObjectsWithErrors = 0;
	TextOfTheLastError = "";
	While Users_Selection.Next() Do
		User = Users_Selection.Ref;
		InfobaseUpdate.MarkProcessingCompletion(User); // If the processing fails, manual adjustment is available.
 		Error = BlockAnInteractionSystemUser(User);
		If Error <> Undefined Then
			ObjectsWithErrors = ObjectsWithErrors + 1;
			TextOfTheLastError = ErrorProcessing.DetailErrorDescription(Error);
		EndIf;
	EndDo;
	
	If ObjectsWithErrors > 0 Then
		
		LogError = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể chặn người dùng trong hệ thống tương tác: %1.
					|Có thể là, hệ thống tương tác tạm thời không khả dụng.
					|Để chặn, hãy nhấp vào ""Chặn tương tác không hợp lệ trong hệ thống tương tác"" trong menu con Hơn nữa của danh sách người sử dụng.';
					|ru = 'Не удалось заблокировать пользователей в системе взаимодействия: %1.
					|Возможно, система взаимодействия временно недоступна.
					|Для блокировки нажмите ""Заблокировать недействительных в системе взаимодействия"" в подменю Еще списка пользователей.';
					|en = 'Cannot disable users in the Collaboration System: %1.
					|The Collaboration System might be temporarily unavailable.
					|To disable users, click ""Disable inactive users in Collaboration System"" in the ""More actions"" menu of the user list.'; fa = 'Cannot disable users in the Collaboration System: %1.
					|The Collaboration System might be temporarily unavailable.
					|To disable users, click ""Disable inactive users in Collaboration System"" in the ""More actions"" menu of the user list.';
					|it = 'Non è stato possibile bloccare gli utenti nel sistema di collaborazione:%1.
					| Probabilmente il sistema di collaborazione non è momentaneamente disponibile. 
					|Per bloccare, cliccare su ""Bloccare inattivi nel sistema di collaborazione"" nel sottomenu Altro dell''elenco degli utenti.';
					|pl = 'Nie udało się zablokować użytkowników w systemie interakcji: %1.
					|Możliwie, system interakcji jest czasowo niedostępny.
					|W celu blokowania naciśnij ""Zablokuj nieważnych w systemie interakcji"" w podmenu Jeszcze listy użytkowników.';
					|tr = 'Ortak çalışma sisteminde kullanıcılar engellenemedi: %1.
					|Ortak çalışma sistemi geçici olarak kullanılamıyor olabilir.
					|Engellemek için kullanıcı listesinin Daha fazla alt menüsündeki ""Ortak çalışma sisteminde geçersiz olanları engelle"" butonuna tıklayın.'") + Chars.LF,
			ObjectsWithErrors);

		WriteLogEvent(
			EventLogEvent(NStr("vi = 'Chặn người dùng không có hiệu lực';
								|ru = 'Блокировка недействительных пользователей';
								|en = 'Disable inactive users'; fa = 'Disable inactive users';
								|it = 'Blocco degli utenti inattivi';
								|pl = 'Blokowanie nieważnych użytkowników';
								|tr = 'Geçersiz kullanıcıların engellenmesi'", Common.DefaultLanguageCode())),
			EventLogLevel.Warning,,,
			StringFunctionsClientServer.SubstituteParametersToString(LogError, ObjectsWithErrors)
			+ Chars.LF + TextOfTheLastError);
	
	EndIf;
	
	ParametersOfUpdate.ProcessingCompleted = True;

EndProcedure

#EndRegion

#EndRegion

#Region Private

Function AvailableIntegrations() Export
	
	Result = New Array;
	Result.Add("Telegram");
	Result.Add("WebChat");
	Result.Add("Webhook");

	ConversationsLocalization.OnDefineAvailableIntegrations(Result);
	Return Result;
	
EndFunction

// Returns:
//  Structure:
//   * Id - Undefined
// 				   - CollaborationSystemIntegrationID
//   * Key - String
//   * Type - String
//   * Attendees - Array
//   * token - String
//   * groupId - String
//
Function IntegrationParameters() Export
	IntegrationParameters = New Structure;
	
	IntegrationParameters.Insert("Id");
	IntegrationParameters.Insert("Key", ""); 
	IntegrationParameters.Insert("Type", "");
	IntegrationParameters.Insert("Attendees", New Array);
	IntegrationParameters.Insert("token", "");
	IntegrationParameters.Insert("groupId", "");
	IntegrationParameters.Insert("channel", "");
	
	Return IntegrationParameters;
EndFunction

Function EventLogEvent(EventDetails = "") Export
	Return NStr("vi = 'Thảo luận';
				|ru = 'Обсуждения';
				|en = 'Conversations'; fa = 'گفتگوها';
				|it = 'Conferenze';
				|pl = 'Conversations';
				|tr = 'Sohbetler'", Common.DefaultLanguageCode())
		+ ?(IsBlankString(EventDetails), "", "."+EventDetails);
EndFunction

Function CreateChangeIntegration(Parameters) Export

	Id = CommonClientServer.StructureProperty(Parameters, "Id");
	If Id <> Undefined Then
		NewIntegration = CollaborationSystem.GetIntegration(Id);
	Else
		NewIntegration = CollaborationSystem.CreateIntegration();
	EndIf;
	
	NewIntegration.ExternalSystemType = Parameters.Type;
	NewIntegration.Presentation = Parameters.Key;
	NewIntegration.Key = Parameters.Key;
	NewIntegration.Use = True;
	ExternalSystemDetails = CollaborationSystem.GetExternalSystemDescription(Parameters.Type);
	
	NotGivenParameters = New Array;
	For Each IntegrationParameter In ExternalSystemDetails.ParametersDescriptions Do
		If Not Parameters.Property(IntegrationParameter.Name) Then
			If IntegrationParameter.Required Then
				NotGivenParameters.Add(IntegrationParameter.Name);
			EndIf;
		Else
			NewIntegration.ExternalSystemParameters.Insert(IntegrationParameter.Name, Parameters[IntegrationParameter.Name]);
		EndIf;
	EndDo;
	
	If NotGivenParameters.Count() > 0 Then
		Raise NStr("vi = 'Chưa điền tham số tích hợp: 
			|%1';
			|ru = 'Не заполнены параметры интеграции: 
			|%1';
			|en = 'Integration parameters are not specified:
			|%1'; fa = 'Integration parameters are not specified:
			|%1';
			|it = 'Non sono stati compilati i parametri di integrazione: 
			|%1';
			|pl = 'Nie wypełniono parametrów integracji: 
			|%1';
			|tr = 'Entegrasyon parametreleri doldurulmadı:
			|%1'", StrConcat(NotGivenParameters, Chars.LF + "- "));
	EndIf;
	
	NewIntegration.Members.Clear();
	For Each Member In Conversations.CollaborationSystemUsers(Parameters.Attendees) Do
	    If Member.Value <> Undefined Then
			NewIntegration.Members.Add(Member.Value.ID);
		EndIf;
	EndDo;
	
	NewIntegration.Write();
	
	Return NewIntegration;
	
EndFunction

Procedure DisableIntegration(Id) Export

	Integration = CollaborationSystem.GetIntegration(Id);
	Integration.Use = False;
	Integration.Write();

EndProcedure

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("LockInvalidUsersInCollaborationSystem");
	Methods.Insert("UsersToBlockInteractionsInTheSystem");
	
EndProcedure

#EndRegion