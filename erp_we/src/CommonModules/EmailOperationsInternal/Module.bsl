///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Creates the profile of the passed email for connection to the mail server.
// 
// Parameters:
//  Account - CatalogRef.EmailAccounts
//  ForReceiving  - Boolean
//  
// Returns:
//  InternetMailProfile - an account profile.
//  Undefined - cannot get the account by reference.
//
Function InternetMailProfile(Account, Val ForReceiving = False) Export
	
	QueryText =
	"SELECT ALLOWED
	|	EmailAccounts.IncomingMailServer AS IMAPServerAddress,
	|	EmailAccounts.IncomingMailServerPort AS IMAPPort,
	|	EmailAccounts.UseSecureConnectionForIncomingMail AS IMAPUseSSL,
	|	EmailAccounts.User AS IMAPUser,
	|	EmailAccounts.IncomingMailServer AS POP3ServerAddress,
	|	EmailAccounts.IncomingMailServerPort AS POP3Port,
	|	EmailAccounts.UseSecureConnectionForIncomingMail AS POP3UseSSL,
	|	EmailAccounts.User AS User,
	|	EmailAccounts.OutgoingMailServer AS SMTPServerAddress,
	|	EmailAccounts.OutgoingMailServerPort AS SMTPPort,
	|	EmailAccounts.UseSecureConnectionForOutgoingMail AS SMTPUseSSL,
	|	EmailAccounts.SignInBeforeSendingRequired AS POP3BeforeSMTP,
	|	EmailAccounts.User AS SMTPUser,
	|	EmailAccounts.Timeout AS Timeout,
	|	EmailAccounts.ProtocolForIncomingMail AS Protocol,
	|	EmailAccounts.AuthorizationRequiredOnSendEmails AS AuthorizationRequiredOnSendEmails,
	|	EmailAccounts.EmailServiceAuthorization
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.Ref = &Ref";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Account);
	Selection = Query.Execute().Select();
	
	If Not Selection.Next() Then
		Return Undefined;
	EndIf;
	
	SetPrivilegedMode(True);
	Passwords = Common.ReadDataFromSecureStorage(Account, 
		"Password,SMTPPassword,AccessToken,AccessTokenValidity,UpdateToken");
	SetPrivilegedMode(False);
	
	Result = New InternetMailProfile;
	RequiredProperties = New Array;
	
	If Not ForReceiving Then
		RequiredProperties.Add("SMTPServerAddress");
		RequiredProperties.Add("SMTPPort");
		RequiredProperties.Add("SMTPUseSSL");
	
		If Selection.AuthorizationRequiredOnSendEmails And Not Selection.POP3BeforeSMTP Then
			RequiredProperties.Add("SMTPUser");
		EndIf;
	
		Result.SMTPPassword = Passwords.SMTPPassword;
	EndIf;
	
	If Selection.Protocol = "IMAP" Then
		RequiredProperties.Add("IMAPUseSSL");
		RequiredProperties.Add("IMAPServerAddress");
		RequiredProperties.Add("IMAPPort");
		RequiredProperties.Add("IMAPUser");
		
		Result.IMAPPassword =Passwords.Password;
	ElsIf ForReceiving Then
		RequiredProperties.Add("POP3ServerAddress");
		RequiredProperties.Add("POP3Port");
		RequiredProperties.Add("POP3UseSSL");
		RequiredProperties.Add("User");
		
		Result.Password = Passwords.Password;
	EndIf;
	
	RequiredProperties.Add("Timeout");
	
	If ValueIsFilled(RequiredProperties) Then
		FillPropertyValues(Result, Selection, StrConcat(RequiredProperties, ","));
	EndIf;
	
	If Selection.EmailServiceAuthorization Then
		If ValueIsFilled(Passwords.AccessTokenValidity) And Passwords.AccessTokenValidity - 60 <= CurrentSessionDate() Then
			Passwords.AccessToken = RefreshAccessToken(Account, Passwords.UpdateToken);
		EndIf;
		Result.AccessToken = Passwords.AccessToken;
	EndIf;
	
	ConvertibleValues = New Array;
	ConvertibleValues.Add("POP3ServerAddress");
	ConvertibleValues.Add("IMAPServerAddress");
	ConvertibleValues.Add("SMTPServerAddress");
	ConvertibleValues.Add("User");
	ConvertibleValues.Add("IMAPUser");
	ConvertibleValues.Add("SMTPUser");
	
	For Each PropertyName In ConvertibleValues Do
		Result[PropertyName] = StringIntoPunycode(Result[PropertyName]);
	EndDo;
	
	If Result.SMTPUser = "" Then
		Result.SMTPPassword = "";
	EndIf;
	
	If Result.IMAPPassword = "" Then
		Result.IMAPPassword = Result.SMTPPassword;
	EndIf;
	
	Return Result;
	
EndFunction

// The function is used for integration with the Data exchange subsystem.
// Returns the email settings that match the
// email settings of the correspondent infobase for data exchange setup (see parameters).
// Account search is performed by a predefined item name or by address. If search fails, a new account is created.
// Email settings of this infobase are matched with the email settings of the correspondent account.
//
// Parameters:
//   CorrespondentAccount1 - CatalogObject.EmailAccounts - email settings
//                   of a correspondent infobase obtained from the data synchronization settings file by deserialization
//                   using the ReadXML method.
//
// Returns:
//  CatalogObject.EmailAccounts
//
Function ThisInfobaseAccountByCorrespondentAccountData(CorrespondentAccount1) Export
	
	BeginTransaction();
	Try
		Block = New DataLock;
		Block.Add("Catalog.EmailAccounts");
		Block.Lock();
		
		ThisInfobaseAccount = Undefined;
		// For a predefined account - overwriting the predefined item of the current infobase.
		If CorrespondentAccount1.Predefined Then
			ThisInfobaseAccount = Catalogs.EmailAccounts[CorrespondentAccount1.PredefinedDataName].GetObject();
		Else
			// For a regular account - searching for an existing account with the same address.
			Query = New Query;
			Query.Text = "SELECT TOP 1
			|	Ref
			|FROM Catalog.EmailAccounts
			|WHERE Email = &Email";
			Query.SetParameter("Email", CorrespondentAccount1.Email);
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				ThisInfobaseAccount = Selection.Ref.GetObject();
			EndIf;
		EndIf;
		
		If ThisInfobaseAccount <> Undefined Then
			FillPropertyValues(ThisInfobaseAccount, CorrespondentAccount1,, "PredefinedDataName, Parent, Owner, Ref");
		Else
			ThisInfobaseAccount = CorrespondentAccount1;
		EndIf;
		
		ThisInfobaseAccount.Write();
	
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return ThisInfobaseAccount;
	
EndFunction

// Returns email text types by description.
//
Function EmailTextsType(Description) Export
	
	Return Enums.EmailTextTypes[Description];
	
EndFunction

// Defines if an application supports receiving emails.
// 
// Returns:
//  Boolean
//
Function CanReceiveEmails() Export
	
	Return SubsystemSettings().CanReceiveEmails;
	
EndFunction

// Returns the settings for connecting to the email server for sending emails.
// If the email settings do not exist or are not accessible by rights, returns an empty structure.
//
// Parameters:
//  Account - CatalogRef.EmailAccounts - email settings.
//
// Returns:
//  Structure:
//   * SMTPServerAddress - String
//   * SMTPPort - Number - port STMP, by default 25.
//   * SMTPPassword - String - a password for server STMP
//   * UseSSL - Boolean - the default value is False.
//   * SMTPUser - String
//   * SenderName - String
//
Function AccountSettingsForSendingMail(Account) Export
	
	Result = New Structure;
	Result.Insert("SMTPServerAddress", "");
	Result.Insert("SMTPPort",         25);
	Result.Insert("SMTPPassword",       "");
	Result.Insert("UseSSL",  False);
	Result.Insert("SMTPUser", "");
	Result.Insert("SenderName",   "");
	
	QueryText =
		"SELECT ALLOWED
		|	EmailAccounts.OutgoingMailServer AS SMTPServerAddress,
		|	EmailAccounts.OutgoingMailServerPort AS SMTPPort,
		|	EmailAccounts.UseSecureConnectionForOutgoingMail AS UseSSL,
		|	EmailAccounts.User AS SMTPUser,
		|	EmailAccounts.UserName AS SenderName
		|FROM
		|	Catalog.EmailAccounts AS EmailAccounts
		|WHERE
		|	EmailAccounts.Ref = &Ref";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Account);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		
		SetPrivilegedMode(True);
		SMTPPassword = Common.ReadDataFromSecureStorage(Account, "SMTPPassword");
		SetPrivilegedMode(False);
		
		FillPropertyValues(Result, Selection);
		Result.SMTPPassword = SMTPPassword;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function InternetMailMessageImportanceFromString(Importance) Export
	
	If StrCompare(Importance, EmailOperationsInternalClientServer.InternetMailMessageImportanceHigh()) = 0 Then
		Return InternetMailMessageImportance.High;
	ElsIf StrCompare(Importance, EmailOperationsInternalClientServer.InternetMailMessageImportanceLow()) = 0 Then
		Return InternetMailMessageImportance.Low;
	Else
		Return InternetMailMessageImportance.Normal;
	EndIf;
	
EndFunction 

// Restore password.

Procedure UpdateMailRecoveryServerSettings(Ref) Export
	
	If Not Users.IsFullUser() Then
		Return;
	EndIf;
	
	AccountSettings1 = AccountSettingsForPasswordRecovery();
	If Not AccountSettings1.Used
		Or AccountSettings1.AccountEmail <> Ref Then
			Return;
	EndIf;
	
	PasswordRecoverySettings = AdditionalAuthenticationSettings.GetPasswordRecoverySettings();
	
	If PasswordRecoverySettings.PasswordRecoveryMethod
			<> InfoBaseUserPasswordRecoveryMethod.SendVerificationCodeBySetParameters Then
		Return;
	EndIf;
	
	AccountSettingsForSendingMail = AccountSettingsForSendingMail(Ref);
	FillPropertyValues(PasswordRecoverySettings, AccountSettingsForSendingMail);
	
	AdditionalAuthenticationSettings.SetPasswordRecoverySettings(PasswordRecoverySettings);
	
EndProcedure

Procedure SaveYourAccountSettingsForPasswordRecovery(Settings) Export
	
	If TypeOf(Settings) <> Type("Structure") Then
		Raise NStr("vi = 'Sai kiểu tùy chỉnh email để khôi phục mật khẩu.';
					|ru = 'Неверный тип настроек почты для восстановления пароля.';
					|en = 'Incorrect account settings type for password recovery.'; fa = 'Incorrect account settings type for password recovery.';
					|it = 'Неверный тип настроек почты для восстановления пароля.';
					|pl = 'Incorrect account settings type for password recovery.';
					|tr = 'Parola kurtarma için geçersiz posta ayarı tipi.'");
	EndIf;
	
	AccountInformation = DescriptionOfAccountSettingsForPasswordRecovery();
	FillPropertyValues(AccountInformation, Settings);
	
	Constants.PasswordRecoveryAccount.Set(New ValueStorage(AccountInformation, New Deflation(9)));
	
EndProcedure

Function AccountSettingsForPasswordRecovery() Export
	
	AccountInformation = DescriptionOfAccountSettingsForPasswordRecovery();
	
	SetPrivilegedMode(True);
	DataFromAConstant = Constants.PasswordRecoveryAccount.Get();
	If TypeOf(DataFromAConstant) = Type("ValueStorage") Then
		
		PasswordRecoveryAccountInformation = DataFromAConstant.Get();
		If TypeOf(PasswordRecoveryAccountInformation) = Type("Structure") Then
			FillPropertyValues(AccountInformation, PasswordRecoveryAccountInformation);
		EndIf;
		
	EndIf;
	
	Return AccountInformation;

EndFunction

Function DescriptionOfAccountSettingsForPasswordRecovery() Export
	
	AccountInformation = New Structure();
	AccountInformation.Insert("AccountEmail", Undefined);
	AccountInformation.Insert("Used",       False);
	
	Return AccountInformation;
	
EndFunction

#Region ConfigurationSubsystemsEventHandlers

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.EmailAccounts.FullName(), "AttributesToEditInBatchProcessing");
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export

	If Common.DataSeparationEnabled()
	   And Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	AccountPermissions = Catalogs.EmailAccounts.AccountPermissions();
	For Each PermissionsDetails In AccountPermissions Do
		PermissionsRequests.Add(ModuleSafeModeManager.RequestToUseExternalResources(
			PermissionsDetails.Value, PermissionsDetails.Key));
	EndDo;
	
	PermissionsRequests.Add(
		ModuleSafeModeManager.RequestToUseExternalResources(Permissions()));
		
	Catalogs.InternetServicesAuthorizationSettings.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromMaster.
Procedure OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Sender) Export
	
	OnDataGet(DataElement, ItemReceive, SendBack, Sender);
	
EndProcedure

// See StandardSubsystemsServer.OnReceiveDataFromSlave.
Procedure OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender) Export
	
	OnDataGet(DataElement, ItemReceive, SendBack, Sender);
	
EndProcedure

// See DataExchangeOverridable.OnSetUpSubordinateDIBNode.
Procedure OnSetUpSubordinateDIBNode() Export
	
	DisableAccounts();
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.3.40";
	Handler.Procedure = "Catalogs.EmailAccounts.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("d57f7a36-46ca-4a52-baab-db960e3d376d");
	Handler.Comment = NStr("vi = 'Cập nhật thông tin về tài khoản e-mail.
		|Danh sách tài khoản e-mail có thể không đầy đủ cho đến khi quá trình xử lý hoàn tất.';
		|ru = 'Обновляет сведения об учетных записях электронной почты.
		|До завершения обработки список учетных записей электронной почты может быть неполным.';
		|en = 'Updates email account data.
		|Until processing is finished, the list of email accounts can be incomplete.'; fa = 'Updates email account data.
		|Until processing is finished, the list of email accounts can be incomplete.';
		|it = 'Aggiorna le informazioni sugli account di posta elettronica. 
		|Fino al completamento dell''elaborazione dei dati, l''elenco degli account utente di posta elettronica potrebbe non essere completo.';
		|pl = 'Aktualizuje dane o kontach poczty elektronicznej.
		|Przed zakończeniem przetwarzania lista kont poczty elektronicznej może być nie pełna.';
		|tr = 'E-posta hesaplarıyla ilgili bilgileri günceller.
		|İşlem tamamlanmadan e-posta hesaplarının listesi tamamlanmayabilir.'");
	Handler.UpdateDataFillingProcedure = "Catalogs.EmailAccounts.RegisterDataToProcessForMigrationToNewVersion";
	
	ObjectsToRead = New Array;
	ObjectsToRead.Add("Catalog.EmailAccounts");
	
	ObjectsToChange = New Array;
	ObjectsToChange.Add("Catalog.EmailAccounts");

	If Common.SubsystemExists("StandardSubsystems.Interactions") Then
		ModuleInteractions = Common.CommonModule("Interactions");
		ModuleInteractions.OnReceiveObjectsToReadOfEmailAccountsUpdateHandler(ObjectsToRead);
		ModuleInteractions.OnGetEmailAccountsUpdateHandlerObjectsToChange(ObjectsToChange);
	EndIf;
		
	Handler.ObjectsToRead = StrConcat(ObjectsToRead, ",");
	Handler.ObjectsToChange = StrConcat(ObjectsToChange, ",");
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
		NewRow = Handler.ExecutionPriorities.Add();
		NewRow.Procedure = "NationalLanguageSupportServer.ProcessDataForMigrationToNewVersion";
		NewRow.Order = "Before";
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessKinds.
Procedure OnFillAccessKinds(AccessKinds) Export
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "EmailAccounts";
	AccessKind.Presentation = NStr("vi = 'Trương mục email';
									|ru = 'Учетные записи электронной почты';
									|en = 'User email accounts'; fa = 'User email accounts';
									|it = 'Account della posta elettronica';
									|pl = 'Konta poczty elektronicznej';
									|tr = 'Kullanıcı e-posta hesapları'");
	AccessKind.ValuesType   = Type("CatalogRef.EmailAccounts");
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Catalogs.EmailAccounts, True);
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.Constants.PasswordRecoveryAccount);
	
EndProcedure

// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionKinds.
Procedure OnFillMetadataObjectsAccessRestrictionKinds(LongDesc) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
	
	If ModuleAccessManagementInternal.AccessKindExists("EmailAccounts") Then
		
		LongDesc = LongDesc + "
		|Catalog.EmailAccounts.Read.EmailAccounts
		|Catalog.EmailAccounts.Read.Users
		|Catalog.EmailAccounts.Update.Users
		|";
		
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming.
Procedure OnAddMetadataObjectsRenaming(Renamings) Export
	
	Library = "StandardSubsystems";
	
	OldName = "Role.UseEmailAccounts";
	NewName  = "Role.ReadEmailAccounts";
	Common.AddRenaming(Renamings, "2.3.3.11", OldName, NewName, Library);
	
	OldName = "Role.ReadEmailAccounts";
	NewName  = "Role.AddEditEmailAccounts";
	Common.AddRenaming(Renamings, "2.4.1.1", OldName, NewName, Library);
	
EndProcedure

// See also InfobaseUpdateOverridable.OnDefineSettings
//
// Parameters:
//  Objects - Array of MetadataObject
//
Procedure OnDefineObjectsWithInitialFilling(Objects) Export
	
	Objects.Add(Metadata.Catalogs.EmailAccounts);
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.GetStatusesOfEmailMessages.MethodName);   	
	
EndProcedure

// Encodes a string using the Punycode algorithm
// 
// Parameters:
//  String - String - source string
// 
// Returns:
//  String - encoded string
//
Function StringIntoPunycode(Val String) Export

	URIStructure = CommonClientServer.URIStructure(String);
	HostAddress = URIStructure.Host;
	CopiedHostAddress = EncodeStringWithDelimiter(HostAddress);
	Result = StrReplace(String, HostAddress, CopiedHostAddress);
	
	Login = URIStructure.Login;
	CodedUsername = EncodeStringWithDelimiter(Login);
	Result = StrReplace(Result, Login, CodedUsername);
		
	Return Result;
EndFunction

// Decodes email addresses using the Punycode algorithm
// 
// Parameters:
//  MailMessage - InternetMailMessage - email to process
//
Procedure DecodeAddressesInEmail(MailMessage) Export
	DecodeAddressesCollection(MailMessage.ReadReceiptAddresses);
	DecodeAddressesCollection(MailMessage.ReplyTo);
	DecodeAddressesCollection(MailMessage.To);
	DecodeAddressesCollection(MailMessage.Bcc);
	MailMessage.From.Address = PunycodeIntoString(MailMessage.From.Address);
EndProcedure

// See CommonOverridable.OnAddServerNotifications
Procedure OnAddServerNotifications(Notifications) Export
	
	NameOfAlert = EmailOperationsInternalClientServer.ServerNotificationName();
	
	Notification = ServerNotifications.NewServerNotification(NameOfAlert);
	Notification.NotificationReceiptModuleName = "EmailOperationsInternalClient";
	Notifications.Insert(Notification.Name, Notification);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Checks whether the predefined system email account
// is available for use.
//
Function CheckSystemAccountAvailable() Export
	
	If Not AccessRight("Read", Metadata.Catalogs.EmailAccounts) Then
		Return False;
	EndIf;
	
	QueryText =
		"SELECT ALLOWED
		|	EmailAccounts.Ref AS Ref
		|FROM
		|	Catalog.EmailAccounts AS EmailAccounts
		|WHERE
		|	EmailAccounts.Ref = &Ref";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.Parameters.Insert("Ref", EmailOperations.SystemAccount());
	If Query.Execute().IsEmpty() Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Procedure SendMessage(Val Account, Val SendOptions) Export
	Var MailProtocol, Join;
	
	MailMessage = PrepareEmail(Account, SendOptions);
	SenderAttributes = Common.ObjectAttributesValues(Account, "UserName,Email,SendBCCToThisAddress");
	
	SendOptions.Property("Join", Join);
	SendOptions.Property("MailProtocol", MailProtocol);
	
	SendOptions.Insert("MessageID", "");
	SendOptions.Insert("MessageIDIMAPSending", "");
	SendOptions.Insert("WrongRecipients", New Map);
	
	NewConnection1 = TypeOf(Join) <> Type("InternetMail");
	
	If NewConnection1 Then
		SendingResult = SendMail(Account, MailMessage);
		SendOptions.WrongRecipients = SendingResult.WrongRecipients;
		SendOptions.MessageID = SendingResult.SMTPEmailID;
		SendOptions.MessageIDIMAPSending = SendingResult.IMAPEmailID;
		Return;
	EndIf;
	
	If SenderAttributes.SendBCCToThisAddress Then
		Recipient = MailMessage.Bcc.Add(SenderAttributes.Email);
		Recipient.DisplayName = SenderAttributes.UserName;
	EndIf;
	
	SetSafeModeDisabled(True);
	Profile = InternetMailProfile(Account);
	SetSafeModeDisabled(False);
	
	If MailProtocol = "IMAP" Or MailProtocol = "All" And Not MailServerKeepsMailsSentBySMTP(Profile) Then
		Join.Send(MailMessage, InternetMailTextProcessing.DontProcess, InternetMailProtocol.IMAP);
		SendOptions.MessageIDIMAPSending = MailMessage.MessageID;
		
		EmailFlags = New InternetMailMessageFlags;
		EmailFlags.Seen = True;
		EmailsFlags = New Map;
		EmailsFlags.Insert(MailMessage.MessageID, EmailFlags);
		Join.SetMessagesFlags(EmailsFlags);
	EndIf;
	
	If Not ValueIsFilled(MailProtocol) Or MailProtocol = "All" Then 
		WrongRecipients = Join.Send(MailMessage, InternetMailTextProcessing.DontProcess,
			InternetMailProtocol.SMTP);
			
		SendOptions.MessageID = MailMessage.MessageID;
		SendOptions.WrongRecipients = WrongRecipients;
	EndIf;
	
EndProcedure

Procedure DetermineSentEmailsFolder(Join)
	
	Mailboxes = Join.GetMailboxes();
	For Each Mailbox In Mailboxes Do
		If Lower(Mailbox) = "sentmessages"
			Or Lower(Mailbox) = "inbox.sent"
			Or Lower(Mailbox) = "sent"
			Or Lower(Mailbox) = "sentbox"
			Or Lower(Mailbox) = "sent items" Then
			
			Join.CurrentMailbox = Mailbox;
			Break;
			
		EndIf;
	EndDo;
	
EndProcedure

Function UseIMAPOnSendingEmails(Profile)
	
	Return Not MailServerKeepsMailsSentBySMTP(Profile)
		And ValueIsFilled(Profile.IMAPServerAddress)
		And ValueIsFilled(Profile.IMAPPort)
		And ValueIsFilled(Profile.IMAPUser)
		And Profile.IMAPPassword <> "";
	
EndFunction

// Parameters:
//  UserAccountOrConnection - See EmailOperations.DownloadEmailMessages.
//  ImportParameters - See EmailOperations.DownloadEmailMessages.ImportParameters
//
// Returns:
//   See EmailOperations.DownloadEmailMessages
//
Function DownloadMessages(Val UserAccountOrConnection, Val ImportParameters = Undefined) Export
	
	// Used to check whether authorization at the mail server can be performed.
	Var TestMode;
	
	// Receive only message headers.
	Var GetHeaders;
	
	// Convert messages to simple type
	Var CastMessagesToType;
	
	// Headers or IDs of messages whose full texts are to be retrieved.
	Var HeadersIDs;
	
	Var Account, Join;
	
	If TypeOf(UserAccountOrConnection) = Type("InternetMail") Then
		Join = UserAccountOrConnection;
	Else
		Account = UserAccountOrConnection;
	EndIf;
	
	If ImportParameters.Property("TestMode") Then
		TestMode = ImportParameters.TestMode;
	Else
		TestMode = False;
	EndIf;
	
	If ImportParameters.Property("GetHeaders") Then
		GetHeaders = ImportParameters.GetHeaders;
	Else
		GetHeaders = False;
	EndIf;
	
	If ImportParameters.Property("HeadersIDs") Then
		HeadersIDs = ImportParameters.HeadersIDs;
	Else
		HeadersIDs = New Array;
	EndIf;
	
	If ImportParameters.Property("Filter") Then
		Filter = ImportParameters.Filter;
	Else
		Filter = New Structure;
	EndIf;
	
	MessageSetToDelete = New Array;
	
	SetSafeModeDisabled(True);
	
	If Account = Undefined Then
		TransportSettings = New Structure;
		TransportSettings.Insert("KeepMessageCopiesAtServer", True);
		TransportSettings.Insert("KeepMailAtServerPeriod", 0);
	Else
		TransportSettings = Common.ObjectAttributesValues(Account, "ProtocolForIncomingMail,KeepMessageCopiesAtServer,KeepMailAtServerPeriod");
		If TransportSettings.ProtocolForIncomingMail = "IMAP" Then
			TransportSettings.KeepMessageCopiesAtServer = True;
			TransportSettings.KeepMailAtServerPeriod = 0;
		EndIf;
		
		Join = ConnectToEmailAccount(Account, True);
	EndIf;
	
	If Account <> Undefined And TestMode Then	
		Join.Logoff();
		Return True;
	EndIf;
	
	Try
		If GetHeaders Or HeadersIDs.Count() = 0 Then
			HeadersIDs = Join.GetHeaders(Filter);
			EmailSet = HeadersIDs;
		EndIf;
		
		If Not GetHeaders And Not (ValueIsFilled(Filter) And HeadersIDs.Count() = 0) Then
			If TransportSettings.KeepMessageCopiesAtServer Then
				If TransportSettings.KeepMailAtServerPeriod > 0 Then
					MessageSetToDelete = New Array;
					For Each ItemHeader In HeadersIDs Do
						CurrentDate = CurrentSessionDate();
						DateDifference = (CurrentDate - ItemHeader.PostingDate) / (3600*24);
						If DateDifference >= TransportSettings.KeepMailAtServerPeriod Then
							MessageSetToDelete.Add(ItemHeader);
						EndIf;
					EndDo;
				EndIf;
				AutomaticallyDeleteMessagesOnChoiceFromServer = False;
			Else
				AutomaticallyDeleteMessagesOnChoiceFromServer = True;
			EndIf;
			
			EmailSet = Join.Get(AutomaticallyDeleteMessagesOnChoiceFromServer, HeadersIDs);
			
			If MessageSetToDelete.Count() > 0 Then
				Join.DeleteMessages(MessageSetToDelete);
			EndIf;
		EndIf;
		
		If Account <> Undefined Then
			Join.Logoff();
		EndIf;
	Except
		If Account <> Undefined Then
			Try
				Join.Logoff();
			Except // ACC:280
				// Do not handle and log exceptions. The original exception 
				// is passed to the calling code and will be handled there.
			EndTry;
		EndIf;
		Raise;
	EndTry;
	SetSafeModeDisabled(False);
	
	If TestMode Then
		Return True;
	EndIf;
	
	If ImportParameters.Property("CastMessagesToType") Then
		CastMessagesToType = ImportParameters.CastMessagesToType;
	Else
		CastMessagesToType = True;
	EndIf;

	Columns = Undefined;
	If ImportParameters.Property("Columns") Then
		Columns = ImportParameters.Columns;
	EndIf;
	
	If CastMessagesToType Then
		Return ConvertedEmailSet(EmailSet, Columns);
	EndIf;
	
	Return EmailSet;
	
EndFunction

// Converts a set of emails to a value table with columns of simple types.
// Column values of the types not supported on the client are converted to the String type.
//
Function ConvertedEmailSet(Val EmailSet, Val Columns = Undefined)
	
	Result = CreateAdaptedEmailMessageDetails(Columns);
	
	For Each MailMessage In EmailSet Do
		NewRow = Result.Add();
		For Each ColumnDescription In Columns Do
			EmailField = MailMessage[ColumnDescription];
			
			If TypeOf(EmailField) = Type("String") Then
				EmailField = CommonClientServer.DeleteDisallowedXMLCharacters(EmailField);
			ElsIf TypeOf(EmailField) = Type("InternetMailAddresses") Then
				EmailField = AddressesPresentation(EmailField);
			ElsIf TypeOf(EmailField) = Type("InternetMailAddress") Then
				EmailField = AddressPresentation(EmailField);
			ElsIf TypeOf(EmailField) = Type("InternetMailAttachments") Then
				Attachments = New Map;
				For Each Attachment In EmailField Do
					If TypeOf(Attachment.Data) = Type("BinaryData") Then
						Attachments.Insert(Attachment.Name, Attachment.Data);
					Else
						FillEmailAttachments(Attachments, Attachment.Data);
					EndIf;
				EndDo;
				EmailField = Attachments;
			ElsIf TypeOf(EmailField) = Type("InternetMailTexts") Then
				Texts = New Array;
				For Each NextText In EmailField Do
					TextDetails = New Map;
					TextDetails.Insert("Data", NextText.Data);
					TextDetails.Insert("Encoding", NextText.Encoding);
					TextDetails.Insert("Text", CommonClientServer.DeleteDisallowedXMLCharacters(NextText.Text));
					TextDetails.Insert("TextType", String(NextText.TextType));
					Texts.Add(TextDetails);
				EndDo;
				EmailField = Texts;
			ElsIf TypeOf(EmailField) = Type("InternetMailMessageImportance")
				Or TypeOf(EmailField) = Type("InternetMailMessageNonASCIISymbolsEncodingMode") Then
				EmailField = String(EmailField);
			EndIf;
			
			NewRow[ColumnDescription] = EmailField;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

Function AddressPresentation(InternetMailAddress)
	Result = PunycodeIntoString(InternetMailAddress.Address);
	If Not IsBlankString(InternetMailAddress.DisplayName) Then
		Result = InternetMailAddress.DisplayName + " <" + Result + ">";
	EndIf;
	Return Result;
EndFunction

Function AddressesPresentation(InternetMailAddresses)
	Result = "";
	For Each InternetMailAddress In InternetMailAddresses Do
		Result = ?(IsBlankString(Result), "", Result + "; ") + AddressPresentation(InternetMailAddress);
	EndDo;
	Return Result;
EndFunction

Procedure FillEmailAttachments(Attachments, MailMessage)
	
	For Each Attachment In MailMessage.Attachments Do
		If TypeOf(Attachment.Data) = Type("BinaryData") Then
			Attachments.Insert(Attachment.Name, Attachment.Data);
		Else
			FillEmailAttachments(Attachments, Attachment.Data);
		EndIf;
	EndDo;
	
	EmailPresentation = EmailPresentation(MailMessage.Subject, MailMessage.PostingDate);
	
	IndexOf = 0;
	For Each Text In MailMessage.Texts Do
		If Text.TextType = InternetMailTextType.HTML Then
			Extension = "html";
		ElsIf Text.TextType = InternetMailTextType.PlainText Then
			Extension = "txt";
		Else
			Extension = "rtf";
		EndIf;
		AttachmentsTextName = "";
		While AttachmentsTextName = "" Or Attachments.Get(AttachmentsTextName) <> Undefined Do
			IndexOf = IndexOf + 1;
			AttachmentsTextName = StringFunctionsClientServer.SubstituteParametersToString("%1 - (%2).%3", EmailPresentation, IndexOf, Extension);
		EndDo;
		Attachments.Insert(AttachmentsTextName, Text.Data);
	EndDo;
	
EndProcedure

// Prepares a table for
// storing messages retrieved from the mail server.
// 
// Parameters:
//   Columns - String - a list of message fields (comma-separated)
//                    to be written to the table. The parameter changes the type to Array.
// Returns
//   ValueTable - empty value table with columns.
//
Function CreateAdaptedEmailMessageDetails(Columns = Undefined)
	
	If Columns <> Undefined
	   And TypeOf(Columns) = Type("String") Then
		Columns = StrSplit(Columns, ",");
		For IndexOf = 0 To Columns.Count()-1 Do
			Columns[IndexOf] = TrimAll(Columns[IndexOf]);
		EndDo;
	EndIf;
	
	InternetMailMessageFields = EmailOperations.InternetMailMessageFields();
	
	DefaultColumnArray = New Array;
	DefaultColumnArray.Add(InternetMailMessageFields.Importance);
	DefaultColumnArray.Add(InternetMailMessageFields.Attachments);
	DefaultColumnArray.Add(InternetMailMessageFields.PostingDate);
	DefaultColumnArray.Add(InternetMailMessageFields.DateReceived);
	DefaultColumnArray.Add(InternetMailMessageFields.Header);
	DefaultColumnArray.Add(InternetMailMessageFields.SenderName);
	DefaultColumnArray.Add(InternetMailMessageFields.UID);
	DefaultColumnArray.Add(InternetMailMessageFields.Cc);
	DefaultColumnArray.Add(InternetMailMessageFields.ReplyTo);
	DefaultColumnArray.Add(InternetMailMessageFields.From);
	DefaultColumnArray.Add(InternetMailMessageFields.To);
	DefaultColumnArray.Add(InternetMailMessageFields.Size);
	DefaultColumnArray.Add(InternetMailMessageFields.Subject);
	DefaultColumnArray.Add(InternetMailMessageFields.Texts);
	DefaultColumnArray.Add(InternetMailMessageFields.Encoding);
	DefaultColumnArray.Add(InternetMailMessageFields.NonASCIISymbolsEncodingMode);
	DefaultColumnArray.Add(InternetMailMessageFields.Partial);
	
	If Columns = Undefined Then
		Columns = DefaultColumnArray;
	EndIf;
	
	Result = New ValueTable;
	
	For Each ColumnDescription In Columns Do
		Result.Columns.Add(ColumnDescription);
	EndDo;
	
	Return Result;
	
EndFunction

Procedure CheckSendReceiveEmailAvailability(Account, ErrorMessage, AdditionalMessage) Export
	
	AccountSettings1 = Common.ObjectAttributesValues(Account, "UseForSending,UseForReceiving,ProtocolForIncomingMail");
	
	ErrorMessage = "";
	AdditionalMessage = "";
	
	If AccountSettings1.UseForSending Then
		ErrorText = Catalogs.EmailAccounts.CheckCanConnectToMailServer(Account, False);
		If ValueIsFilled(ErrorText) Then
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không thể kết nối đến máy chủ SMTP: %1';
																						|ru = 'Не удалось подключиться к серверу SMTP: %1';
																						|en = 'Cannot connect to SMTP server: %1'; fa = 'Cannot connect to SMTP server: %1';
																						|it = 'Impossibile connettersi al server SMTP: %1';
																						|pl = 'Nie udało się połączyć z serwerem SMTP: %1';
																						|tr = 'SMTP sunucusuna bağlanılamıyor: %1'") + Chars.LF, ErrorText);
		EndIf;
		If Not AccountSettings1.UseForReceiving Then
			AdditionalMessage = Chars.LF + NStr("vi = '(Đã kiểm tra việc gửi email.)';
												|ru = '(Выполнена проверка отправки электронных сообщений.)';
												|en = '(The check whether the mail is sent is performed.)'; fa = '(The check whether the mail is sent is performed.)';
												|it = '(La verifica dell''invio di messaggi elettronici è stata effettuata.)';
												|pl = '(Dokonano weryfikacji wysyłania wiadomości e-mail.)';
												|tr = '(Eposta gönderme kontrolü tamamlandı.)'");
		EndIf;
	EndIf;
	
	If AccountSettings1.UseForReceiving 
		Or AccountSettings1.UseForSending And AccountSettings1.ProtocolForIncomingMail = "IMAP" Then
		
		ErrorText = Catalogs.EmailAccounts.CheckCanConnectToMailServer(Account, True);
		If ValueIsFilled(ErrorText) Then
			If ValueIsFilled(ErrorMessage) Then
				ErrorMessage = ErrorMessage + Chars.LF;
			EndIf;
			
			ErrorMessage = ErrorMessage + StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không thể kết nối đến máy chủ %1:
				|%2';
				|ru = 'Не удалось подключиться к серверу %1:
				|%2';
				|en = 'Cannot connect to %1 server:
				|%2'; fa = 'Cannot connect to %1 server:
				|%2';
				|it = 'Impossibile connettersi al server %1:
				|%2';
				|pl = 'Nie udało się podłączyć się do serwera %1:
				|%2';
				|tr = '%1 sunucusuna bağlanılamıyor:
				|%2'"), AccountSettings1.ProtocolForIncomingMail, ErrorText);
		EndIf;
		
		If Not AccountSettings1.UseForSending Then
			AdditionalMessage = Chars.LF + NStr("vi = '(Đã kiểm tra việc nhận email.)';
												|ru = '(Выполнена проверка получения электронных сообщений.)';
												|en = '(The check whether the mail is received is performed.)'; fa = '(The check whether the mail is received is performed.)';
												|it = '(La verifica della ricezione di messaggi elettronici è stata effettuata.)';
												|pl = '(Dokonano weryfikacji odbioru wiadomości e-mail.)';
												|tr = '(E-posta alma kontrolü tamamlandı).'");
		EndIf;
		
	EndIf;
	
EndProcedure

// Disables all accounts. The procedure is used on DIB node initial setup.
Procedure DisableAccounts()
	
	QueryText =
	"SELECT
	|	EmailAccounts.Ref
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.UseForReceiving
	|
	|UNION ALL
	|
	|SELECT
	|	EmailAccounts.Ref
	|FROM
	|	Catalog.EmailAccounts AS EmailAccounts
	|WHERE
	|	EmailAccounts.UseForSending";
	
	Query = New Query(QueryText);
	Selection = Query.Execute().Select(); // ACC:1328 - The initial setup of a DIB node does not require a data lock.
	While Selection.Next() Do
		Account = Selection.Ref.GetObject();
		Account.UseForSending = False;
		Account.UseForReceiving = False;
		Account.DataExchange.Load = True;
		Account.Write(); // ACC:1327 - The initial setup of a DIB node does not require a data lock.
	EndDo;
	
EndProcedure

// The procedure handles the OnReceiveDataFromMaster and OnReceiveDataFromSlave events that occur
// during data exchange in a distributed infobase.
//
// Parameters:
//   See the same-name event handlers in Syntax Assistant.
//
Procedure OnDataGet(DataElement, ItemReceive, SendBack, Sender)
	
	If TypeOf(DataElement) = Type("CatalogObject.EmailAccounts") Then
		If DataElement.IsNew() Then
			DataElement.UseForReceiving = False;
			DataElement.UseForSending = False;
		Else
			DataElement.UseForReceiving = Common.ObjectAttributeValue(DataElement.Ref, "UseForReceiving");
			DataElement.UseForSending = Common.ObjectAttributeValue(DataElement.Ref, "UseForSending");
		EndIf;
	EndIf;
	
EndProcedure

Procedure PrepareAttachments(Attachments, SettingsForSaving) Export
	Var ZipFileWriter, ArchiveName;
	
	Result = New Array;
	
	// Prepare an archive.
	HasFilesAddedToArchive = False;
	If SettingsForSaving.PackToArchive Then
		ArchiveName = GetTempFileName("zip");
		ZipFileWriter = New ZipFileWriter(ArchiveName);
	EndIf;
	
	TempDirectoryName = GetTempFileName();
	CreateDirectory(TempDirectoryName);
	
	SelectedSaveFormats = SettingsForSaving.SaveFormats;
	FormatsTable = StandardSubsystemsServer.SpreadsheetDocumentSaveFormatsSettings();
	
	FileNameForArchive = Undefined;
	For IndexOf = -Attachments.UBound() To 0 Do
		Attachment = Attachments[-IndexOf];
		SpreadsheetDocument = GetFromTempStorage(Attachment.AddressInTempStorage);
		If TypeOf(SpreadsheetDocument) = Type("SpreadsheetDocument") Then 
			AddressInTempStorage = Attachment.AddressInTempStorage;
			Attachments.Delete(-IndexOf);
		Else
			Continue;
		EndIf;
		
		If EvalOutputUsage(SpreadsheetDocument) = UseOutput.Disable Then
			Continue;
		EndIf;
		
		If SpreadsheetDocument.Protection Then
			Continue;
		EndIf;
		
		If SpreadsheetDocument.TableHeight = 0 Then
			Continue;
		EndIf;
		
		For Each SelectedFormat In SelectedSaveFormats Do
			FileType = SpreadsheetDocumentFileType[SelectedFormat];
			FormatSettings = FormatsTable.FindRows(New Structure("SpreadsheetDocumentFileType", FileType))[0];
			FileName = CommonClientServer.ReplaceProhibitedCharsInFileName(Attachment.Presentation);
			If FileNameForArchive = Undefined Then
				FileNameForArchive = FileName + ".zip";
			Else
				FileNameForArchive = NStr("vi = 'Chứng từ';
											|ru = 'Документы';
											|en = 'Documents'; fa = 'اسناد';
											|it = 'Documenti';
											|pl = 'Dokumenty';
											|tr = 'Belgeler'") + ".zip";
			EndIf;
			FileName = FileName + "." + FormatSettings.Extension;
			
			If SettingsForSaving.TransliterateFilesNames Then
				FileName = StringFunctions.LatinString(FileName);
			EndIf;
			
			FullFileName = FileSystem.UniqueFileName(CommonClientServer.AddLastPathSeparator(TempDirectoryName) + FileName);
			SpreadsheetDocument.Write(FullFileName, FileType);
			
			If FileType = SpreadsheetDocumentFileType.HTML Then
				InsertPicturesToHTML(FullFileName);
			EndIf;
			
			If ZipFileWriter <> Undefined Then 
				HasFilesAddedToArchive = True;
				ZipFileWriter.Add(FullFileName);
			Else
				BinaryData = New BinaryData(FullFileName);
				AddressInTempStorage = PutToTempStorage(BinaryData, New UUID);
				FileDetails = New Structure;
				FileDetails.Insert("Presentation", FileName);
				FileDetails.Insert("AddressInTempStorage", AddressInTempStorage);
				If FileType = SpreadsheetDocumentFileType.ANSITXT Then
					FileDetails.Insert("Encoding", "windows-1251");
				EndIf;
				Result.Add(FileDetails);
			EndIf;
		EndDo;
	EndDo;
	
	// If the archive is prepared, writing it and putting in the temporary storage.
	If HasFilesAddedToArchive Then 
		ZipFileWriter.Write();
		BinaryData = New BinaryData(ArchiveName);
		
		// Using the existing temporary storage address related to the form.
		PutToTempStorage(BinaryData, AddressInTempStorage);
		
		FileDetails = New Structure;
		FileDetails.Insert("Presentation", FileNameForArchive);
		FileDetails.Insert("AddressInTempStorage", AddressInTempStorage);
		Result.Add(FileDetails);
	EndIf;
	
	For Each FileDetails In Result Do
		Attachments.Add(FileDetails);
	EndDo;
		
	DeleteFiles(TempDirectoryName);
	If ValueIsFilled(ArchiveName) Then
		DeleteFiles(ArchiveName);
	EndIf;
	
EndProcedure

Function EvalOutputUsage(SpreadsheetDocument)
	If SpreadsheetDocument.Output = UseOutput.Auto Then
		Return ?(AccessRight("Output", Metadata), UseOutput.Enable, UseOutput.Disable);
	Else
		Return SpreadsheetDocument.Output;
	EndIf;
EndFunction

Procedure InsertPicturesToHTML(HTMLFileName)
	
	TextDocument = New TextDocument();
	TextDocument.Read(HTMLFileName, TextEncoding.UTF8);
	HTMLText = TextDocument.GetText();
	
	HTMLFile = New File(HTMLFileName);
	
	PicturesDirectoryName = HTMLFile.BaseName + "_files";
	PicturesDirectoryPath = StrReplace(HTMLFile.FullName, HTMLFile.Name, PicturesDirectoryName);
	
	// The folder is only for pictures.
	PicturesFiles = FindFiles(PicturesDirectoryPath, "*");
	
	For Each PicturesFile In PicturesFiles Do
		PictureInText = Base64String(New BinaryData(PicturesFile.FullName));
		PictureInText = "data:image/" + Mid(PicturesFile.Extension,2) + ";base64," + Chars.LF + PictureInText;
		
		HTMLText = StrReplace(HTMLText, PicturesDirectoryName + "\" + PicturesFile.Name, PictureInText);
	EndDo;
		
	TextDocument.SetText(HTMLText);
	TextDocument.Write(HTMLFileName, TextEncoding.UTF8);
	
EndProcedure

Function SubsystemSettings() Export
	Settings = New Structure;
	Settings.Insert("CanReceiveEmails", Not StandardSubsystemsServer.IsBaseConfigurationVersion());
	Settings.Insert("ShouldUsePOP3Protocol", True);
	EmailOperationsOverridable.OnDefineSettings(Settings);
	Return Settings;
EndFunction

Function DetermineMIMETypeByFileName(FileName)
	Extension = "";
	Position = StrFind(FileName, ".", SearchDirection.FromEnd);
	If Position > 0 Then
		Extension = Lower(Mid(FileName, Position + 1));
	EndIf;
	Return MIMETypes()[Extension];
EndFunction

Function MIMETypes()
	Result = New Map;
	
	Result.Insert("json", "application/json");
	Result.Insert("pdf", "application/pdf");
	Result.Insert("xhtml", "application/xhtml+xml");
	Result.Insert("zip", "application/zip");
	Result.Insert("gzip", "application/gzip");
	
	Result.Insert("aac", "audio/aac");
	Result.Insert("ogg", "audio/ogg");
	Result.Insert("wma", "audio/x-ms-wma");
	Result.Insert("wav", "audio/vnd.wave");
	
	Result.Insert("gif", "image/gif");
	Result.Insert("jpeg", "image/jpeg");
	Result.Insert("png", "image/png");
	Result.Insert("svg", "image/svg");
	Result.Insert("tiff", "image/tiff");
	Result.Insert("ico", "image/vnd.microsoft.icon");
	
	Result.Insert("html", "text/html");
	Result.Insert("txt", "text/plain");
	Result.Insert("xml", "text/xml");
	
	Result.Insert("mpeg", "video/mpeg");
	Result.Insert("mp4", "video/mp4");
	Result.Insert("mov", "video/quicktime");
	Result.Insert("wmv", "video/x-ms-wmv");
	Result.Insert("flv", "video/x-flv");
	Result.Insert("3gpp", "video/3gpp");
	Result.Insert("3gp", "video/3gpp");
	Result.Insert("3gpp2", "video/3gpp2");
	Result.Insert("3g2", "video/3gpp2");
	
	Result.Insert("odt", "application/vnd.oasis.opendocument.text");
	Result.Insert("ods", "application/vnd.oasis.opendocument.spreadsheet");
	Result.Insert("odp", "application/vnd.oasis.opendocument.presentation");
	Result.Insert("odg", "application/vnd.oasis.opendocument.graphics");
	
	Result.Insert("doc", "application/msword");
	Result.Insert("docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document");
	Result.Insert("xls", "application/vnd.ms-excel");
	Result.Insert("xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
	Result.Insert("ppt", "application/vnd.ms-powerpoint");
	Result.Insert("pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation");
	
	Result.Insert("rar", "application/x-rar-compressed");
	
	Result.Insert("p7m", "application/x-pkcs7-mime");
	Result.Insert("p7s", "application/x-pkcs7-signature");
	
	Return Result;
EndFunction

Function GetFormattedDocumentHTMLForEmail(FormattedDocument)
	
	// Exports formatted document to HTML text and pictures.
	HTMLText = "";
	Images = New Structure;
	FormattedDocument.GetHTML(HTMLText, Images);
	
	// Converting HTML text to HTMLDocument.
	Builder = New DOMBuilder;
	HTMLReader = New HTMLReader;
	HTMLReader.SetString(HTMLText);
	HTMLDocument = Builder.Read(HTMLReader);
	
	// Replacing picture names in the HTML document with IDs.
	For Each Picture In HTMLDocument.Images Do
		AttributePictureSource = Picture.Attributes.GetNamedItem("src");
		If StrStartsWith(AttributePictureSource.TextContent, "data:") Then
			Continue;
		EndIf;
		Picture.SetAttribute("alt", AttributePictureSource.TextContent);
		AttributePictureSource.TextContent = "cid:" + AttributePictureSource.TextContent;
	EndDo;
	
	// Converting HTMLDocument back to HTML text
	DOMWriter = New DOMWriter;
	HTMLWriter = New HTMLWriter;
	HTMLWriter.SetString();
	DOMWriter.Write(HTMLDocument, HTMLWriter);
	HTMLText = HTMLWriter.Close();
	
	// Prepare the result.
	Result = New Structure;
	Result.Insert("HTMLText", HTMLText);
	Result.Insert("Images", Images);
	
	Return Result;
	
EndFunction

Function EmailPresentation(EmailSubject, EmailDate)
	
	TemplateOfPresentation = NStr("vi = '%1 ngày %2';
									|ru = '%1 от %2';
									|en = '%1, %2'; fa = '%1, %2';
									|it = '%1 del %2';
									|pl = '%1 z dn. %2';
									|tr = '%2 tarihli %1'");
	
	Return StringFunctionsClientServer.SubstituteParametersToString(TemplateOfPresentation,
		?(IsBlankString(EmailSubject), NStr("vi = '<Không có chủ đề>';
											|ru = '<Без темы>';
											|en = '<No subject>'; fa = '<No subject>';
											|it = '<senza soggetto>';
											|pl = '<Bez tematu>';
											|tr = '<Konu yok>'"), EmailSubject),
		Format(EmailDate, "DLF=D"));
	
EndFunction

// Converts the collection of passed attachments to a standard format.
// It is used to bypass the situations when the source form does not consider lifetime of the temporary storage 
// where attachments are uploaded to. The attachments are uploaded to the temporary storage for the session time.
//
Function AttachmentsDetails(AttachmentCollection) Export
	If TypeOf(AttachmentCollection) <> Type("ValueList") And TypeOf(AttachmentCollection) <> Type("Array") Then
		Return AttachmentCollection;
	EndIf;
	
	Result = New Array;
	For Each Attachment In AttachmentCollection Do
		AttachmentDetails = AttachmentDetails();
		BinaryData = GetFromTempStorage(Attachment.AddressInTempStorage);
		FillPropertyValues(AttachmentDetails, Attachment, , "AddressInTempStorage");
		AttachmentDetails.AddressInTempStorage = PutToTempStorage(BinaryData, New UUID);
		Result.Add(AttachmentDetails);
	EndDo;
	
	Return Result;
EndFunction

Function AttachmentDetails()
	Result = New Structure;
	Result.Insert("Presentation");
	Result.Insert("AddressInTempStorage");
	Result.Insert("Encoding");
	Result.Insert("Id");
	
	Return Result;
EndFunction

Function MailServerKeepsMailsSentBySMTP(InternetMailProfile)
	
	Return Lower(InternetMailProfile.SMTPServerAddress) = "smtp.gmail.com"
		Or StrEndsWith(Lower(InternetMailProfile.SMTPServerAddress), ".outlook.com") > 0;
	
EndFunction

Function HasExternalResources(HTMLDocument) Export
	
	DisplayFilters = New Array;
	DisplayFilters.Add(FilterByAttribute("src", "^(http|https)://"));
	
	Filter = CombineFilters(DisplayFilters);
	FoundNodes = HTMLDocument.FindByFilter(Common.ValueToJSON(Filter));
	
	Return FoundNodes.Count() > 0;
	
EndFunction

Procedure DisableUnsafeContent(HTMLDocument, DisableExternalResources = True) Export
	
	DisplayFilters = New Array;
	DisplayFilters.Add(FilterByNodeName("script"));
	DisplayFilters.Add(FilterByNodeName("link"));
	DisplayFilters.Add(FilterByNodeName("iframe"));
	DisplayFilters.Add(FilterByAttributeName("onerror"));
	DisplayFilters.Add(FilterByAttributeName("onmouseover"));
	DisplayFilters.Add(FilterByAttributeName("onmouseout"));
	DisplayFilters.Add(FilterByAttributeName("onclick"));
	DisplayFilters.Add(FilterByAttributeName("onload"));
	
	Filter = CombineFilters(DisplayFilters);
	HTMLDocument.DeleteByFilter(Common.ValueToJSON(Filter));
	
	If DisableExternalResources Then
		Filter = FilterByAttribute("src", "^(http|https)://");
		FoundNodes = HTMLDocument.FindByFilter(Common.ValueToJSON(Filter));
		For Each Node In FoundNodes Do
			Node.Value = "";
		EndDo;
	EndIf;
	
EndProcedure

Function FilterByNodeName(NodeName)
	
	Result = New Structure;
	Result.Insert("type", "elementname");
	Result.Insert("value", New Structure("value, operation", NodeName, "equals"));
	
	Return Result;
	
EndFunction

Function CombineFilters(DisplayFilters, UnionType = "Or")
	
	If DisplayFilters.Count() = 1 Then
		Return DisplayFilters[0];
	EndIf;
	
	Result = New Structure;
	Result.Insert("type", ?(UnionType = "And", "intersection", "union"));
	Result.Insert("value", DisplayFilters);
	
	Return Result;
	
EndFunction

Function FilterByAttribute(AttributeName, ValueTemplate)
	
	DisplayFilters = New Array;
	DisplayFilters.Add(FilterByAttributeName(AttributeName));
	DisplayFilters.Add(FilterByAttributeValue(ValueTemplate));
	
	Result = CombineFilters(DisplayFilters, "And");
	
	Return Result;
	
EndFunction

Function FilterByAttributeName(AttributeName)
	
	Result = New Structure;
	Result.Insert("type", "attribute");
	Result.Insert("value", New Structure("value, operation", AttributeName, "nameequals"));
	
	Return Result;
	
EndFunction

Function FilterByAttributeValue(ValueTemplate)
	
	Result = New Structure;
	Result.Insert("type", "attribute");
	Result.Insert("value", New Structure("value, operation", ValueTemplate, "valuematchesregex"));
	
	Return Result;
	
EndFunction

Function SendMail(Account, MailMessage) Export
	
	Emails = CommonClientServer.ValueInArray(MailMessage);
	Return SendEmails(Account, Emails)[MailMessage];
	
EndFunction

// See EmailOperations.SendEmails
Function SendEmails(UserAccountOrConnection, Emails, ExceptionText = Undefined) Export
	Var Account, Join;
	
	If TypeOf(UserAccountOrConnection) = Type("InternetMail") Then
		Join = UserAccountOrConnection;
	Else
		Account = UserAccountOrConnection;
	EndIf;
	
	If Account <> Undefined Then
		SenderAttributes = Common.ObjectAttributesValues(Account, 
			"UserName,Email,SendBCCToThisAddress,UseForReceiving");
		
		SetSafeModeDisabled(True);
		Profile = InternetMailProfile(Account);
	
		ReceivingProtocol = InternetMailProtocol.POP3;
		If UseIMAPOnSendingEmails(Profile) Then
			ReceivingProtocol = InternetMailProtocol.IMAP;
		EndIf;
	
		ErrorText = "";
		Try
			Join = ConnectToEmailAccount(Account);
			If ReceivingProtocol = InternetMailProtocol.IMAP Then
				DetermineSentEmailsFolder(Join);
			EndIf;
		Except
			ErrorInfo = ErrorInfo();
			
			If Not EmailOperationsInternalClientServer.IsInternetMailError(ErrorInfo)
				Or ReceivingProtocol <> InternetMailProtocol.IMAP Or SenderAttributes.UseForReceiving Then
				Raise;
			EndIf;
			
			ErrorText = ExtendedErrorPresentation(ErrorInfo, Common.DefaultLanguageCode(), , Account);
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể kết nối với máy chủ IMAP:
				|%1';
				|ru = 'Не удалось подключиться к серверу IMAP:
				|%1';
				|en = 'Cannot connect to IMAP server:
				|%1'; fa = 'Cannot connect to IMAP server:
				|%1';
				|it = 'Non è stato possibile collegarsi al server IMAP:
				|%1';
				|pl = 'Nie udało się podłączyć się do serwera IMAP:
				|%1';
				|tr = 'IMAP sunucusuna bağlanılamadı:
				|%1'", Common.DefaultLanguageCode()), ErrorText);
			
			WriteLogEvent(EventNameSendEmail(), EventLogLevel.Error, 
				Metadata.Catalogs.EmailAccounts, Account, ErrorText);
			
			ReceivingProtocol = InternetMailProtocol.POP3;
			Join = New InternetMail;
			ConnectToInternetMail(Join, Profile, ReceivingProtocol);
			
		EndTry;
	EndIf;
	
	EmailsSendingResults = New Map;
	ProcessTexts = InternetMailTextProcessing.DontProcess;
	
	Try
		For Each MailMessage In Emails Do
			MailMessage.SenderName = SenderAttributes.UserName;
			MailMessage.From.DisplayName = SenderAttributes.UserName;
			MailMessage.From.Address = SenderAttributes.Email;
			
			If SenderAttributes.SendBCCToThisAddress Then
				Recipient = MailMessage.Bcc.Add(SenderAttributes.Email);
				Recipient.DisplayName = SenderAttributes.UserName;
			EndIf;
			
			EmailSendingResult = New Structure;
			EmailSendingResult.Insert("WrongRecipients", New Map);
			EmailSendingResult.Insert("SMTPEmailID", "");
			EmailSendingResult.Insert("IMAPEmailID", "");
			
			EncodeAddressesInEmailMessage(MailMessage);
			
			If ReceivingProtocol = InternetMailProtocol.IMAP Then
				
				Try
					Join.Send(MailMessage, ProcessTexts, InternetMailProtocol.IMAP);
				Except
					ErrorInfo = ErrorInfo();
					ExceptionClarification = CommonClientServer.ExceptionClarification(ErrorInfo);
					ErrorCode = EmailOperationsInternalClientServer.InternetMailErrorCode();
					
					Raise(
						ExceptionClarification.Text, ExceptionClarification.Category, ErrorCode, , ErrorInfo);
				EndTry;
				
				EmailSendingResult.Insert("IMAPEmailID", MailMessage.MessageID);
				
				EmailFlags = New InternetMailMessageFlags;
				EmailFlags.Seen = True;
				EmailsFlags = New Map;
				EmailsFlags.Insert(MailMessage.MessageID, EmailFlags);
				Join.SetMessagesFlags(EmailsFlags);
				
			EndIf;
			
			WrongRecipients = New Map;
			Try
				WrongRecipients = Join.Send(MailMessage, ProcessTexts, InternetMailProtocol.SMTP);
			Except
				ErrorInfo = ErrorInfo();
				ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
				If EmailRecipientRejectedByServer(ErrorText) Then
					For Each Recipient In MailMessage.To Do
						WrongRecipients.Insert(Recipient.Address, ErrorText);
					EndDo;
				Else
					
					ExceptionClarification = CommonClientServer.ExceptionClarification(ErrorInfo);
					ErrorCode = EmailOperationsInternalClientServer.InternetMailErrorCode();
					
					Raise(
						ExceptionClarification.Text, ExceptionClarification.Category, ErrorCode, , ErrorInfo);
					
				EndIf;
			EndTry;
			
			EmailSendingResult.WrongRecipients = WrongRecipients;
			EmailSendingResult.SMTPEmailID = MailMessage.MessageID;
			
			If WrongRecipients.Count() > 0 Then
				ErrorsTexts = New Array;
				For Each WrongRecipient In WrongRecipients Do
					Recipient = WrongRecipient.Key;
					ErrorText = WrongRecipient.Value;
					ErrorsTexts.Add(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = '%1: %2';
							|ru = '%1: %2';
							|en = '%1: %2'; fa = '%1: %2';
							|it = '%1: %2';
							|pl = '%1: %2';
							|tr = '%1: %2'"), Recipient, ErrorText));
				EndDo;
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa gửi thư đến những người nhận sau đây:
					|%1';
					|ru = 'Отправка письма следующим получателям не выполнена:
					|%1';
					|en = 'The message was not sent to the following recipients:
					|%1'; fa = 'The message was not sent to the following recipients:
					|%1';
					|it = 'Invio della lettera ai seguenti mittenti non eseguito:
					|%1';
					|pl = 'Nie wykonano wysyłki wiadomości do następujących odbiorców:
					|%1';
					|tr = 'Bu alıcılara e-posta gönderilmemiştir:
					|%1'", 
					Common.DefaultLanguageCode()), StrConcat(ErrorsTexts, Chars.LF));
				WriteLogEvent(EventNameSendEmail(), EventLogLevel.Error, , 
					Account, ErrorText);
			EndIf;
			
			EmailsSendingResults.Insert(MailMessage, EmailSendingResult);
		EndDo;
	Except
		ErrorInfo = ErrorInfo();
		If Account <> Undefined Then
			Try
				Join.Logoff();
			Except // ACC:280
				// Do not handle and log exceptions. The original exception 
				// is passed to the calling code and will be handled there.
			EndTry;
		EndIf;
		
		ExceptionText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		If Not EmailOperationsInternalClientServer.IsInternetMailError(ErrorInfo)
			Or EmailsSendingResults.Count() = 0 Then
			Raise;
		EndIf;
		
		ErrorText = ExtendedErrorPresentation(ErrorInfo, Common.DefaultLanguageCode(), , Account);
		WriteLogEvent(EventNameSendEmail(), EventLogLevel.Error, , Account, ErrorText);
		Return EmailsSendingResults;
	EndTry;
	
	If Account <> Undefined Then
		Join.Logoff();
	EndIf;
	SetSafeModeDisabled(False);
	
	Return EmailsSendingResults;
	
EndFunction

Function EventNameSendEmail()
	
	Return NStr("vi = 'Làm việc với thư điện tử. Gửi thư';
				|ru = 'Работа с почтовыми сообщениями.Отправка почты';
				|en = 'Email management.Send message'; fa = 'Email management.Send message';
				|it = 'Lavoro con messaggi postali.Invio della posta';
				|pl = 'Praca z wiadomościami e-mail.Wysyłanie wiadomości e-mail';
				|tr = 'E-posta işlemleri. E-posta gönder'", Common.DefaultLanguageCode());

EndFunction

Function PrepareEmail(Account, EmailParameters) Export
	
	MailMessage = New InternetMailMessage;
	
	SenderAttributes = Common.ObjectAttributesValues(Account, "UserName,Email");
	MailMessage.SenderName              = SenderAttributes.UserName;
	MailMessage.From.DisplayName = SenderAttributes.UserName;
	MailMessage.From.Address           = SenderAttributes.Email;
	
	If EmailParameters.Property("Subject") Then
		MailMessage.Subject = EmailParameters.Subject;
	EndIf;
	
	Whom = EmailParameters.Whom;
	If TypeOf(Whom) = Type("String") Then
		Whom = CommonClientServer.ParseStringWithEmailAddresses(Whom);
	EndIf;
	For Each RecipientEmailAddress In Whom Do
		Recipient = MailMessage.To.Add(RecipientEmailAddress.Address);
		Recipient.DisplayName = RecipientEmailAddress.Presentation;
	EndDo;
	
	If EmailParameters.Property("Cc") Then
		For Each CcRecipientEmailAddress In EmailParameters.Cc Do
			Recipient = MailMessage.Cc.Add(CcRecipientEmailAddress.Address);
			Recipient.DisplayName = CcRecipientEmailAddress.Presentation;
		EndDo;
	EndIf;
	
	If EmailParameters.Property("BCCs") Then
		For Each InformationOnRecipient In EmailParameters.BCCs Do
			Recipient = MailMessage.Bcc.Add(InformationOnRecipient.Address);
			Recipient.DisplayName = InformationOnRecipient.Presentation;
		EndDo;
	EndIf;
	
	If EmailParameters.Property("ReplyToAddress") Then
		For Each ReplyToEmailAddress In EmailParameters.ReplyToAddress Do
			ReturnEmailAddress = MailMessage.ReplyTo.Add(ReplyToEmailAddress.Address);
			ReturnEmailAddress.DisplayName = ReplyToEmailAddress.Presentation;
		EndDo;
	EndIf;
	
	Attachments = Undefined;
	EmailParameters.Property("Attachments", Attachments);
	If Attachments <> Undefined Then
		For Each Attachment In Attachments Do
			If TypeOf(Attachment) = Type("Structure") Then
				FileData = Undefined;
				If IsTempStorageURL(Attachment.AddressInTempStorage) Then
					FileData = GetFromTempStorage(Attachment.AddressInTempStorage);
				Else
					FileData = Attachment.AddressInTempStorage;
				EndIf;
				NewAttachment = MailMessage.Attachments.Add(FileData, Attachment.Presentation);
				If Attachment.Property("Encoding") And Not IsBlankString(Attachment.Encoding) Then
					NewAttachment.Encoding = Attachment.Encoding;
				EndIf;
				If Attachment.Property("Id") Then
					NewAttachment.CID = Attachment.Id;
				EndIf;
			Else // For backward compatibility with version 2.2.1.
				If TypeOf(Attachment.Value) = Type("Structure") Then
					NewAttachment = MailMessage.Attachments.Add(Attachment.Value.BinaryData, Attachment.Key);
					If Attachment.Value.Property("Id") Then
						NewAttachment.CID = Attachment.Value.Id;
					EndIf;
					If Attachment.Value.Property("Encoding") Then
						NewAttachment.Encoding = Attachment.Value.Encoding;
					EndIf;
					If Attachment.Value.Property("MIMEType") Then
						NewAttachment.MIMEType = Attachment.Value.MIMEType;
					EndIf;
					If Attachment.Value.Property("Name") Then
						NewAttachment.Name = Attachment.Value.Name;
					EndIf;
				Else
					InternetMailAttachment = MailMessage.Attachments.Add(Attachment.Value, Attachment.Key);
					If TypeOf(Attachment.Value) = Type("InternetMailMessage") Then
						InternetMailAttachment.MIMEType = "message/rfc822";
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	For Each Attachment In MailMessage.Attachments Do
		If Not ValueIsFilled(Attachment.MIMEType) Then
			MIMEType = DetermineMIMETypeByFileName(Attachment.Name);
			If ValueIsFilled(MIMEType) Then
				Attachment.MIMEType = MIMEType;
			EndIf;
		EndIf;
	EndDo;
	
	If EmailParameters.Property("BasisIDs") Then
		MailMessage.SetField("References", 
		                               EmailParameters.BasisIDs, 
		                               InternetMailMessageNonASCIISymbolsEncodingMode.None);
	EndIf;
	
	If EmailParameters.Property("BasisID") Then
		MailMessage.SetField("In-Reply-To", 
		                               EmailParameters.BasisID, 
		                               InternetMailMessageNonASCIISymbolsEncodingMode.None);
	EndIf;
	
	Body = "";
	EmailParameters.Property("Body", Body);
	
	TextType = Undefined;
	If TypeOf(Body) = Type("FormattedDocument") Then
		EmailContent = GetFormattedDocumentHTMLForEmail(Body);
		Body = EmailContent.HTMLText;
		Images = EmailContent.Images;
		TextType = InternetMailTextType.HTML;
		
		For Each Picture In Images Do
			IconName = Picture.Key;
			PictureData = Picture.Value;
			Attachment = MailMessage.Attachments.Add(PictureData.GetBinaryData(), IconName);
			Attachment.CID = IconName;
		EndDo;
	EndIf;
	Text = MailMessage.Texts.Add(Body);
	If ValueIsFilled(TextType) Then
		Text.TextType = TextType;
	EndIf;
	
	If TextType = Undefined Then
		If EmailParameters.Property("TextType", TextType) Then
			If TypeOf(TextType) = Type("String") Then
				If      TextType = "HTML" Then
					Text.TextType = InternetMailTextType.HTML;
				ElsIf TextType = "RichText" Then
					Text.TextType = InternetMailTextType.RichText;
				Else
					Text.TextType = InternetMailTextType.PlainText;
				EndIf;
			ElsIf TypeOf(TextType) = Type("EnumRef.EmailTextTypes") Then
				If      TextType = Enums.EmailTextTypes.HTML
					Or TextType = Enums.EmailTextTypes.HTMLWithPictures Then
					Text.TextType = InternetMailTextType.HTML;
				ElsIf TextType = Enums.EmailTextTypes.RichText Then
					Text.TextType = InternetMailTextType.RichText;
				Else
					Text.TextType = InternetMailTextType.PlainText;
				EndIf;
			Else
				Text.TextType = TextType;
			EndIf;
		Else
			Text.TextType = InternetMailTextType.PlainText;
		EndIf;
	EndIf;
	
	Importance = Undefined;
	If EmailParameters.Property("Importance", Importance) Then
		MailMessage.Importance = Importance;
	EndIf;
	
	Encoding = Undefined;
	If EmailParameters.Property("Encoding", Encoding) Then
		MailMessage.Encoding = Encoding;
	EndIf;
	
	If EmailParameters.Property("RequestDeliveryReceipt") Then
		MailMessage.RequestDeliveryReceipt = EmailParameters.RequestDeliveryReceipt;
	EndIf;
	
	If EmailParameters.Property("RequestReadReceipt") Then
		MailMessage.RequestReadReceipt = EmailParameters.RequestReadReceipt;
		MailMessage.ReadReceiptAddresses.Add(SenderAttributes.Email);
	EndIf;
	
	If Not EmailParameters.Property("ProcessTexts") Or EmailParameters.ProcessTexts Then
		MailMessage.ProcessTexts();
	EndIf;
	
	Return MailMessage;
	
EndFunction

// Returns a list of permissions for automatic email setting search.
//
// Returns:
//  Array
//
Function Permissions() Export
	
	Protocol = "HTTPS";
	Address = AddressOfExternalResource();
	Port = Undefined;
	LongDesc = NStr("vi = 'Tìm kiếm tùy chỉnh email và chẩn đoán lỗi kết nối.';
					|ru = 'Поиск настроек почты и диагностика ошибок подключения.';
					|en = 'Search for email settings and run connection error troubleshooting.'; fa = 'Search for email settings and run connection error troubleshooting.';
					|it = 'Ricerca impostazioni di posta e diagnostica degli errori di connessione.';
					|pl = 'Wyszukiwanie ustawień poczty i diagnostyka błędów połączenia.';
					|tr = 'Posta ayarlarını arayın ve bağlantı hatalarını tespit edin.'");
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Permissions = New Array;
	Permissions.Add(
		ModuleSafeModeManager.PermissionToUseInternetResource(Protocol, Address, Port, LongDesc));
	
	For Each Address In DNSServerAddresses() Do
		Protocol = "TCP";
		Port = 53;
		LongDesc = NStr("vi = 'Tìm kiếm cài đặt thư.';
						|ru = 'Поиск настроек почты.';
						|en = 'Search for email settings.'; fa = 'Search for email settings.';
						|it = 'Поиск настроек почты.';
						|pl = 'Search for email settings.';
						|tr = 'E-posta ayar araması.'");
	
		Permissions.Add(
			ModuleSafeModeManager.PermissionToUseInternetResource(Protocol, Address, Port, LongDesc));
	EndDo;
	
	If Common.IsWindowsServer() Then
		CommandTemplate = "cmd /S /C ""%(nslookup -type=mx % %)%""";
	ElsIf Common.IsLinuxServer() Then
		CommandTemplate = "nslookup -type=mx % %";
	EndIf;
	Permissions.Add(ModuleSafeModeManager.PermissionToUseOperatingSystemApplications(CommandTemplate,
		NStr("vi = 'Quyền cho phép đối với nslookup.';
			|ru = 'Разрешение для nslookup.';
			|en = 'Permission for nslookup.'; fa = 'Permission for nslookup.';
			|it = 'Разрешение для nslookup.';
			|pl = 'Permission for nslookup.';
			|tr = 'Nslookup için çözüm.'", Common.DefaultLanguageCode())));
	
	Return Permissions;
	
EndFunction

Function EmailRecipientRejectedByServer(Val ErrorText)
	
	ErrorText = Lower(ErrorText);
	Return StrFind(ErrorText, "invalid mailbox") > 0
		Or StrFind(ErrorText, "user not found") > 0;
	
EndFunction

// Returns parameters to get the error details.
//
// Returns:
//  Structure:
//    * ErrorText               - String - Detailed error text.
//    * LanguageCode                  - String - The interface language for the current user.
//    * Context                  - String - See ContextForExplanation.
//    * ServerNames             - String - See ServersNamesForExplanation.
//
Function ExplanationParameters() Export
	
	Result = New Structure;
	Result.Insert("ErrorText", "");
	Result.Insert("LanguageCode", CurrentLanguage().LanguageCode);
	Result.Insert("Context", "");
	Result.Insert("ServerNames", "");
	
	Return Result;
	
EndFunction

// Returns context that requires error details.
//
// Returns:
//  Structure:
//    * Key - String
//    * Value - String
//
Function ContextForExplanation() Export
	
	Result = New Structure;
	Result.Insert("AutoSetUp", "AutomaticSetting");
	Result.Insert("ManualSetting", "ManualSetting");
	Result.Insert("SendingEmail", "SendingEmail");
	
	Return Result;
	
EndFunction

// Returns email server names (separated with commas) that require error details.
//
// Parameters:
//  IncomingMailServer - String
//  OutgoingMailServer - String
//
// Returns:
//  String
//
Function ServersNamesForExplanation(IncomingMailServer, OutgoingMailServer) Export
	
	If IsBlankString(IncomingMailServer) And IsBlankString(OutgoingMailServer) Then
		Return "";
	EndIf;
	
	Result = New Array;
	Result.Add(IncomingMailServer);
	Result.Add(OutgoingMailServer);
	
	Return StrConcat(Result, ", ");
	
EndFunction

// Returns error details.
//
// Parameters:
//  ExplanationParameters - Structure - See ExplanationParameters.
//
// Returns:
//  Structure:
//    * PossibleReasons - Array
//    * MethodsToFixError - Array
//
Function ExplanationOnError(ExplanationParameters) Export
	
	ErrorText = ExplanationParameters.ErrorText;
	LanguageCode = ExplanationParameters.LanguageCode;
	
	ErrorsDetails = New Array;
	
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		FileAddress = AddressOfFIleWithErrorsDetails();
		ImportedFile = ModuleNetworkDownload.DownloadFileAtServer(FileAddress);
		If ImportedFile.Status Then
			JSONReader = New JSONReader();
			JSONReader.OpenFile(ImportedFile.Path);
			ErrorsDetails = ReadJSON(JSONReader, True);
			JSONReader.Close();
		EndIf;
	EndIf;
	
	PossibleReasons = New Array;
	MethodsToFixError = New Array;
	
	For Each ErrorDescription In ErrorsDetails Do
		TextTemplates = ErrorDescription["SearchPatterns"];
		If Not ValueIsFilled(TextTemplates) Then
			Continue;
		EndIf;
		
		For Each TextTemplate1 In TextTemplates Do
			If Not TheStringMatchesTheTemplate(ErrorText, TextTemplate1) Then
				Continue;
			EndIf;
			
			For Each PossibleReason In StrSplit(PropertyValue("Reason", ErrorDescription, LanguageCode), Chars.LF, False) Do
				PossibleReasons.Add(PossibleReason);
			EndDo;
			
			For Each Item In ErrorDescription["HowToFix"] Do
				If Not RemedyApplicable(Item, ExplanationParameters) Then
					Continue;
				EndIf;
				
				Remedy = Item[LanguageCode];
				If Remedy = Undefined Then
					Remedy = Item[Common.DefaultLanguageCode()];
				EndIf;
				MethodsToFixError.Add(Remedy);
			EndDo;
		EndDo;
	EndDo;
	
	If Not ValueIsFilled(PossibleReasons) Then
		If Not ValueIsFilled(ErrorsDetails) Then
			PossibleReasons.Add(NStr("vi = 'Không có kết nối Internet.';
									|ru = 'Отсутствует подключение к Интернету.';
									|en = 'No Internet connection.'; fa = 'No Internet connection.';
									|it = 'Manca la connessione a internet.';
									|pl = 'Brak połączenia z Internetem.';
									|tr = 'İnternet bağlantısı yok.'"));
		EndIf;
		PossibleReasons.Add(NStr("vi = 'Sai tùy chỉnh kết nối đến máy chủ thư.';
								|ru = 'Неверные настройки подключения к почтовому серверу.';
								|en = 'Invalid email server connection settings.'; fa = 'Invalid email server connection settings.';
								|it = 'Impostazioni invalide di connessione al server di posta.';
								|pl = 'Nieprawidłowe ustawienia połączenie z serwerem pocztowym.';
								|tr = 'E-posta sunucusu bağlantı ayarları yanlış.'"));
		PossibleReasons.Add(NStr("vi = 'Sự cố trên server email.';
								|ru = 'Неполадки на почтовом сервере.';
								|en = 'Mail server malfunction.'; fa = 'Mail server malfunction.';
								|it = 'Неполадки на почтовом сервере.';
								|pl = 'Mail server malfunction.';
								|tr = 'Posta sunucusuyla ilgili sorunlar.'"));
	EndIf;
	
	If Not ValueIsFilled(MethodsToFixError) Then
		If Not ValueIsFilled(ErrorsDetails) Then
			MethodsToFixError.Add(NStr("vi = 'Hãy kiểm tra kết nối đến Internet.';
										|ru = 'Проверьте подключение к Интернету.';
										|en = 'Check the Internet connection.'; fa = 'Check the Internet connection.';
										|it = 'Verificare la connessione a internet.';
										|pl = 'Sprawdź połączeni z Internetem.';
										|tr = 'İnternet bağlantısını kontrol edin.'"));
		EndIf; 
		
		If IsAutoSetting(ExplanationParameters) Then
			MethodsToFixError.Add(NStr("vi = 'Hãy kiểm tra tùy chỉnh đã nhập.';
										|ru = 'Проверьте введенные настройки.';
										|en = 'Check the specified settings.'; fa = 'Check the specified settings.';
										|it = 'Verificare le impostazioni inserite.';
										|pl = 'Sprawdź wprowadzone ustawienia.';
										|tr = 'Girilen ayarları kontrol edin.'"));
		Else
			MethodsToFixError.Add(StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"vi = 'Hãy thử tùy chỉnh lại email (nút <a href=""%1"">Tùy chỉnh lại</a> trong tùy chỉnh thư).';
				|ru = 'Попробуйте перенастроить почту (кнопка <a href=""%1"">Перенастроить</a> в настройках почты).';
				|en = 'Try reconfiguring your account (click <a href=""%1"">Reconfigure</a> in account settings).'; fa = 'Try reconfiguring your account (click <a href=""%1"">Reconfigure</a> in account settings).';
				|it = 'Попробуйте перенастроить почту (кнопка <a href=""%1"">Перенастроить</a> в настройках почты).';
				|pl = 'Try reconfiguring your account (click <a href=""%1"">Reconfigure</a> in account settings).';
				|tr = 'E-posta hesabınızı yeniden yapılandırmayı deneyin (posta ayarlarında <a href=""%1"">Yeniden yapılandır</a> butonu).'"),
				"00aae216-28f1-4b32-8ac5-d2a104368df5"));
		EndIf;
	
		MethodsToFixError.Add(NStr("vi = 'Hãy lặp lại thao tác một lần nữa sau một thời gian.';
									|ru = 'Повторите действие еще раз через некоторое время.';
									|en = 'Try again later.'; fa = 'Try again later.';
									|it = 'Повторите действие еще раз через некоторое время.';
									|pl = 'Try again later.';
									|tr = 'Bir süre sonra eylemi tekrar tekrarlayın.'"));
		MethodsToFixError.Add(NStr("vi = 'Hãy liên hệ với người quản trị mạng cục bộ.';
									|ru = 'Обратитесь к администратору локальной сети.';
									|en = 'Contact the network administrator.'; fa = 'Contact the network administrator.';
									|it = 'Rivolgetevi all''amministratore della rete locale.';
									|pl = 'Zwróć się do administratora sieci lokalnej.';
									|tr = 'Yerel ağ yöneticinize başvurun.'"));
		MethodsToFixError.Add(NStr("vi = 'Hãy liên hệ với người quản trị máy chủ thư.';
									|ru = 'Обратитесь к администратору почтового сервера.';
									|en = 'Contact the email server administrator.'; fa = 'Contact the email server administrator.';
									|it = 'Rivolgersi all''amministratore del servizio di posta.';
									|pl = 'Skontaktuj się z administratorem serwera pocztowego.';
									|tr = 'E-posta sunucusu yöneticinize başvurun.'"));
	EndIf;
	
	PossibleReasons = CommonClientServer.CollapseArray(PossibleReasons);
	MethodsToFixError = CommonClientServer.CollapseArray(MethodsToFixError);
	
	Result = New Structure;
	Result.Insert("PossibleReasons", FormattedStrings(PossibleReasons));
	Result.Insert("MethodsToFixError", FormattedStrings(MethodsToFixError));
	
	Return Result;
	
EndFunction

Function PropertyValue(PropertyName, PropertiesCollection, LanguageCode)
	
	Result = "";
	
	If TypeOf(PropertiesCollection[PropertyName]) = Type("Map") Then
		Result = PropertiesCollection[PropertyName][LanguageCode];
		If Not ValueIsFilled(Result) Then
			Result = PropertiesCollection[PropertyName][Common.DefaultLanguageCode()];
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

Function FormattedList(Rows) Export
	
	List = New Array;
	For IndexOf = 0 To Rows.UBound() Do
		String = Rows[IndexOf];

		List.Add("• ");
		List.Add(String);
		If IndexOf < Rows.UBound() Then
			List.Add(Chars.LF);
		EndIf;
	EndDo;
	
	Return New FormattedString(List);
	
EndFunction

Function FormattedStrings(Rows)
	
	Result = New Array;
	For Each String In Rows Do
		FormattedString = StringFunctions.FormattedString(String);
		Result.Add(FormattedString);
	EndDo;
	
	Return Result;
	
EndFunction

Function IsAutoSetting(ExplanationParameters)
	
	Return ExplanationParameters.Context = ContextForExplanation().AutoSetUp;
	
EndFunction

Function RemedyApplicable(Remedy, ExplanationParameters)
	
	Result = True;
	ExtendedTags = Remedy["TagsV2"];
	
	If ExtendedTags = Undefined Then
		Return Result;
	EndIf;
	
	CheckRemedyByContext(Result, ExtendedTags, ExplanationParameters);
	CheckRemedyByProvider(Result, ExtendedTags, ExplanationParameters);
	
	Return Result;
	
EndFunction

Procedure CheckRemedyByContext(Result, ExtendedTags, ExplanationParameters)
	
	Contexts = ExtendedTags.Get("context");
	
	If Contexts = Undefined Then
		Return;
	EndIf;
	
	CurrentContext = ExplanationParameters.Context;
	
	For Each Context In Contexts Do
		
		If Context = "ClientServerMode" Then
			Result = Result And Not Common.FileInfobase();
		Else
			Result = Result And CurrentContext = Context;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckRemedyByProvider(Result, ExtendedTags, ExplanationParameters)
	
	Providers = ExtendedTags.Get("provider");
	
	If Providers = Undefined Then
		Return;
	EndIf;
	
	ServerNames = ExplanationParameters.ServerNames;
	
	For Each Provider In Providers Do
		Result = Result And StrFind(ServerNames, Provider) > 0;
	EndDo;
	
EndProcedure

Function ExtendedErrorPresentation(ErrorInfo, LanguageCode,
	EnableVerboseRepresentationErrors = True, Account = Undefined) Export
	
	BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
	
	IncomingMailServer = "";
	OutgoingMailServer = "";
	
	If TypeOf(Account) = Type("CatalogRef.EmailAccounts") Then
		UserAccountAttributes = Common.ObjectAttributesValues(Account, "IncomingMailServer, OutgoingMailServer");
		IncomingMailServer = UserAccountAttributes.IncomingMailServer;
		OutgoingMailServer = UserAccountAttributes.OutgoingMailServer;
	EndIf;
	
	ExplanationParameters = ExplanationParameters();
	ExplanationParameters.ErrorText = BriefErrorDescription;
	ExplanationParameters.LanguageCode = LanguageCode;
	ExplanationParameters.Context = ContextForExplanation().SendingEmail;
	ExplanationParameters.ServerNames = ServersNamesForExplanation(IncomingMailServer, OutgoingMailServer);
	
	ExplanationOnError = ExplanationOnError(ExplanationParameters);
	
	Template = NStr("vi = '%1
	|
	|Nguyên nhân có thể có:
	|%2
	|
	|Cách khắc phục:
	|%3';
	|ru = '%1
	|
	|Возможные причины:
	|%2
	|
	|Способы устранения:
	|%3';
	|en = '%1
	|
	|Possible reasons:
	|%2
	|
	|Methods to fix the error:
	|%3'; fa = '%1
	|
	|Possible reasons:
	|%2
	|
	|Methods to fix the error:
	|%3';
	|it = '%1
	|
	|Cause possibili:
	|%2
	|
	|Metodi di eliminazione:
	|%3';
	|pl = '%1
	|
	|Możliwe przyczyny:
	|%2
	|
	|Sposoby rozwiązania:
	|%3';
	|tr = '%1
	|
	|Olası nedenler:
	|%2
	|
	|Çözümler:
	|%3'", LanguageCode);
	
	
	PossibleReasons = FormattedList(ExplanationOnError.PossibleReasons);
	MethodsToFixError = FormattedList(ExplanationOnError.MethodsToFixError);
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		Template, BriefErrorDescription, PossibleReasons, MethodsToFixError);
	
	If EnableVerboseRepresentationErrors Then
		Template = NStr("vi = '%1
		|
		|Thông tin bổ sung:
		|%2';
		|ru = '%1
		|
		|Дополнительная информация:
		|%2';
		|en = '%1
		|
		|Additional information:
		|%2'; fa = '%1
		|
		|Additional information:
		|%2';
		|it = '%1
		|
		|Informazioni aggiuntive:
		|%2';
		|pl = '%1
		|
		|Informacje dodatkowe:
		|%2';
		|tr = '%1
		|
		|Ek bilgi:
		|%2'", LanguageCode);
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(Template, ErrorText, DetailErrorDescription);
	EndIf;
	
	Return ErrorText;
	
EndFunction

Function TheStringMatchesTheTemplate(Val String, Val Template)
	
	String = StrConcat(StrSplit(String, " " + Chars.LF + Chars.CR + Chars.Tab, False), " ");
	TheStringMatchesTheTemplate = True;
	
	For Each PartsOfTheTemplate In StrSplit(Template, "*", False) Do
		FragmentToSearchFor = StrConcat(StrSplit(PartsOfTheTemplate, " " + Chars.LF + Chars.CR + Chars.Tab, False), " ");
		
		Position = StrFind(String, FragmentToSearchFor);
		If Position = 0 Then
			TheStringMatchesTheTemplate = False;
			Break;
		EndIf;
		
		String = Mid(String, Position + StrLen(FragmentToSearchFor));
	EndDo;
	
	Return TheStringMatchesTheTemplate;
	
EndFunction

Function PrepareHTTPRequest(ResourceAddress, QueryOptions, PutParametersInQueryBody = True) Export
	
	Headers = New Map;
	
	If PutParametersInQueryBody Then
		Headers.Insert("Content-Type", "application/x-www-form-urlencoded");
	EndIf;
	
	If TypeOf(QueryOptions) = Type("String") Then
		ParametersString1 = QueryOptions;
	Else
		ParametersList = New Array;
		For Each Parameter In QueryOptions Do
			Values = Parameter.Value;
			If TypeOf(Parameter.Value) <> Type("Array") Then
				Values = CommonClientServer.ValueInArray(Parameter.Value);
			EndIf;
			
			For Each Value In Values Do
				ParametersList.Add(Parameter.Key + "=" + EncodeString(Value, StringEncodingMethod.URLEncoding));
			EndDo;
		EndDo;
		ParametersString1 = StrConcat(ParametersList, "&");
	EndIf;
	
	If Not PutParametersInQueryBody Then
		ResourceAddress = ResourceAddress + "?" + ParametersString1;
	EndIf;

	HTTPRequest = New HTTPRequest(ResourceAddress, Headers);
	
	If PutParametersInQueryBody Then
		HTTPRequest.SetBodyFromString(ParametersString1);
	EndIf;
	
	Return HTTPRequest;

EndFunction

Function ExecuteQuery(ServerAddress, ResourceAddress, QueryOptions, PutParametersInQueryBody = True) Export
	
	Result = New Structure;
	Result.Insert("QueryCompleted", False);
	Result.Insert("ServerResponse1", "");
	
	If Not Common.AccessToInternetServicesAllowed() Then
		WriteLogEvent(EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , Common.AccessToInternetServicesDeniedMessageText());
		Return Result;
	EndIf;
	
	HTTPRequest = PrepareHTTPRequest(ResourceAddress, QueryOptions, True);
	HTTPResponse = Undefined;
	
	Proxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		Proxy = ModuleNetworkDownload.GetProxy("https");
	EndIf;
	
	Try
		Join = New HTTPConnection(ServerAddress, , , , Proxy,
			60, CommonClientServer.NewSecureConnection());
		If PutParametersInQueryBody Then
			HTTPResponse = Join.Post(HTTPRequest);
		Else
			HTTPResponse = Join.Get(HTTPRequest);
		EndIf;
	Except
		WriteLogEvent(EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	If HTTPResponse <> Undefined Then
		If HTTPResponse.StatusCode <> 200 Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa thực hiện yêu cầu ""%1"". Mã trạng thái: %2.';
					|ru = 'Запрос ""%1"" не выполнен. Код состояния: %2.';
					|en = 'Request failed: %1. Status code: %2.'; fa = 'Request failed: %1. Status code: %2.';
					|it = 'Richiesta ""%1"" non è riuscita. Codice di stato: %2.';
					|pl = 'Zapytanie ""%1"" nie jest wykonane. Kod statusu: %2.';
					|tr = '""%1"" talebi yerine getirilmedi. Durum kodu: %2.'"), ResourceAddress, HTTPResponse.StatusCode) + Chars.LF
				+ HTTPResponse.GetBodyAsString();
			WriteLogEvent(EventNameAuthorizationByProtocolOAuth(),
				EventLogLevel.Error, , , ErrorText);
		EndIf;
		
		Result.QueryCompleted = HTTPResponse.StatusCode = 200;
		Result.ServerResponse1 = HTTPResponse.GetBodyAsString();
	EndIf;
	
	Return Result;
	
EndFunction

Function EventNameAuthorizationByProtocolOAuth() Export
	
	Return NStr("vi = 'Làm việc với thông báo thư. Đăng nhập vào máy chủ thư';
				|ru = 'Работа с почтовыми сообщениями.Авторизация на почтовом сервере';
				|en = 'Email management. Email server authorization'; fa = 'Email management. Email server authorization';
				|it = 'Lavoro con messaggi di posta. Autorizzazione al server di posta';
				|pl = 'Praca z wiadomościami pocztowymi. Autoryzacja na serwerze pocztowym';
				|tr = 'E-posta yönetimi.E-posta sunucusunda giriş'", Common.DefaultLanguageCode());

EndFunction

Function GenerateVerificationCode() Export
	
	VerificationCode = "";
	
	Letters = "abcdefghijklmnopqrstuvwxyz";
	Digits = "1234567890";
	AdditionalChars = "-._~";
	
	AllowedChars = Letters + Upper(Letters) + Digits + AdditionalChars;
	StringLength = StrLen(AllowedChars);
	
	RandomNumberGenerator = New RandomNumberGenerator(CurrentUniversalDateInMilliseconds());
	
	For Counter = 1 To 128 Do
		Position = RandomNumberGenerator.RandomNumber(1, StringLength);
		Char = Mid(AllowedChars, Position, 1);
		VerificationCode = VerificationCode + Char;
	EndDo;
	
	Return VerificationCode;
	
EndFunction

Function EncodeStringMethodS256(String) Export
	
	DataHashing = New DataHashing(HashFunction.SHA256);
	DataHashing.Append(String);
	Result = Base64URLString(DataHashing.HashSum);
	
	Return Result;
	
EndFunction

Function Base64URLString(Value)
	
	Result = Base64String(Value);
	Result = StrReplace(Result, "+", "-");
	Result = StrReplace(Result, "/", "_");
	Result = StrReplace(Result, "=", "");
	Result = StrReplace(Result, Chars.LF, "");
	
	Return Result;

EndFunction

Function RefreshAccessToken(Val Account, Val UpdateToken)
	
	AttributesValues = Common.ObjectAttributesValues(Account, 
		"Email, EmailServiceName");
	
	If Not Common.AccessToInternetServicesAllowed() Then
		WriteLogEvent(EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , Common.AccessToInternetServicesDeniedMessageText());
		Return "";
	EndIf;	

	If Not ValueIsFilled(AttributesValues.EmailServiceName) Then
		ErrorText = NStr("vi = 'Chưa chỉ ra tên dịch vụ thư để đăng nhập. Cần tùy chỉnh lại thư.';
						|ru = 'Не указано имя почтового сервиса для авторизации. Необходимо перенастроить почту.';
						|en = 'Email service for authorization is not specified. Reconfigure your account.'; fa = 'Email service for authorization is not specified. Reconfigure your account.';
						|it = 'Non è indicato il nome del servizio di posta per l''autorizzazione. Reimpostare la posta.';
						|pl = 'Nie podano nazwy serwisu pocztowego dla autoryzacji. Należy ponownie ustawić pocztę.';
						|tr = 'Giriş için e-posta servisinin adı belirtilmedi. E-posta yeniden yapılandırılmalıdır.'");
		WriteLogEvent(EventNameAuthorizationByProtocolOAuth(), EventLogLevel.Error, , Account,
			ErrorText);
		Return "";
	EndIf;
	
	URIStructure = CommonClientServer.URIStructure(AttributesValues.Email);
	
	SetPrivilegedMode(True);
	AuthorizationSettings = Catalogs.InternetServicesAuthorizationSettings.SettingsAuthorizationInternetService(
		AttributesValues.EmailServiceName, URIStructure.Host);
	SetPrivilegedMode(False);
		
	If Not ValueIsFilled(AuthorizationSettings.AppID) Then
		ErrorText = NStr("vi = 'Không tìm thấy các tùy chỉnh đăng nhập dịch vụ Internet ""%1"" đối với tên miền ""%2"". Cần tùy chỉnh lại thư.';
						|ru = 'Настройки авторизации Интернет-сервиса ""%1"" не найдены для домена ""%2"". Необходимо перенастроить почту.';
						|en = 'Authorization settings of the ""%1"" online service are not found for domain ""%2"". Reconfigure your account.'; fa = 'Authorization settings of the ""%1"" online service are not found for domain ""%2"". Reconfigure your account.';
						|it = 'Impostazioni di autorizzazione servizio internet ""%1"" non trovate per il dominio ""%2""Reimpostare la posta.';
						|pl = 'Ustawienia autoryzacji serwisu internetowego ""%1"" nie znaleziono dla domeny ""%2"". Należy ponownie ustawić pocztę.';
						|tr = '""%1"" çevrimiçi servisine giriş ayarları ""%2"" alanı için bulunamadı. E-posta hesabı yeniden yapılandırılmalıdır.'");
		WriteLogEvent(EventNameAuthorizationByProtocolOAuth(), EventLogLevel.Error, , Account,
			ErrorText);
			Return "";
	EndIf;
	
	URIStructure = CommonClientServer.URIStructure(AuthorizationSettings.KeyReceiptAddress);
	ServerAddress = URIStructure.Host;
	ResourceAddress = "/" + URIStructure.PathAtServer;
	
	QueryOptions = New Structure;
	QueryOptions.Insert("client_id", AuthorizationSettings.AppID);
	
	If ValueIsFilled(AuthorizationSettings.UseApplicationPassword) Then
		QueryOptions.Insert("client_secret", AuthorizationSettings.ApplicationPassword);
	EndIf;
	
	If ValueIsFilled(AuthorizationSettings["PermissionsToRequest"]) Then
		QueryOptions.Insert("scope", AuthorizationSettings["PermissionsToRequest"]);
	EndIf;

	QueryOptions.Insert("refresh_token", UpdateToken);
	QueryOptions.Insert("grant_type", "refresh_token");
	
	RequestTime = CurrentSessionDate();
	
	QueryResult = ExecuteQuery(ServerAddress, ResourceAddress, QueryOptions);
	
	Try
		AnswerParameters = Common.JSONValue(QueryResult.ServerResponse1);
	Except
		AnswerParameters = New Map;
	EndTry;
	
	AccessToken = AnswerParameters["access_token"];
	AccessTokenValidity = AnswerParameters["expires_in"];
	If ValueIsFilled(AnswerParameters["refresh_token"]) Then
		UpdateToken = AnswerParameters["refresh_token"];
	EndIf;
	ErrorCode = AnswerParameters["error"];
	ErrorText = AnswerParameters["error_description"];
	
	If ValueIsFilled(ErrorCode) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận khóa truy cập đến tài khoản email %1 do nguyên nhân:
			|%2
			|Phản hồi của máy chủ:
			|%3';
			|ru = 'Не удалось получить ключи доступа к учетной записи почты %1 по причине:
			|%2
			|Ответ сервера:
			|%3';
			|en = 'Cannot get access keys to the %1 email account due to:
			|%2
			|Server response:
			|%3'; fa = 'Cannot get access keys to the %1 email account due to:
			|%2
			|Server response:
			|%3';
			|it = 'Non è stato possibile ricevere le chiave di accesso all''account di posta %1a causa di:
			|%2
			|Risposta del server: 
			|%3';
			|pl = 'Nie udało się otrzymać kluczy dostępu do konta poczty %1 z powodu:
			|%2
			|Odpowiedź serwera:
			|%3';
			|tr = '%1E-posta hesabı erişim anahtarları şu sebeple alınamadı:
			|%2
			|Sunucu yanıtı:
			|%3'"), AttributesValues.Email, ErrorText, QueryResult.ServerResponse1);
		WriteLogEvent(EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Error, , , ErrorText);

		Return "";
	ElsIf Not QueryResult.QueryCompleted Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận khóa truy cập đến tài khoản email %1 do nguyên nhân:
			|Chưa thực hiện truy vấn.
			|Phản hồi của máy chủ:
			|%2';
			|ru = 'Не удалось получить ключи доступа к учетной записи почты %1 по причине:
			|Запрос не выполнен.
			|Ответ сервера:
			|%2';
			|en = 'Cannot get access keys to the %1 email account due to:
			|Request failed.
			|Server response:
			|%2'; fa = 'Cannot get access keys to the %1 email account due to:
			|Request failed.
			|Server response:
			|%2';
			|it = 'Non è stato possibile ricevere le chiavi di accesso all''account di posta %1 a causa di:
			|Richiesta non eseguita.
			|Risposta server:
			|%2';
			|pl = 'Nie udało się otrzymać kluczy dostępu do konta poczty %1 z powodu:
			|Zapytanie nie zostało wykonane.
			|Odpowiedź serwera:
			|%2';
			|tr = '%1E-posta hesabı erişim anahtarları şu sebeple alınamadı:
			|Sorgu gerçekleştirilemedi.
			|Sunucu yanıtı:
			|%2'"), AttributesValues.Email, QueryResult.ServerResponse1);
		WriteLogEvent(EventNameAuthorizationByProtocolOAuth(), EventLogLevel.Error, , Account,
			ErrorText);
		Return "";
	EndIf;
	
	If ValueIsFilled(AccessTokenValidity) Then
		AccessTokenValidity = RequestTime + AccessTokenValidity;
	EndIf;
	
	SetPrivilegedMode(True);

	Common.WriteDataToSecureStorage(Account, AccessToken, "AccessToken");
	Common.WriteDataToSecureStorage(Account, AccessTokenValidity, "AccessTokenValidity");
	Common.WriteDataToSecureStorage(Account, UpdateToken, "UpdateToken");
	
	SetPrivilegedMode(False);
	
	Return AccessToken;
	
EndFunction

// Parameters:
//  Item - FormFieldExtensionForATextBox
//
Procedure CheckoutPasswordField(Item) Export
	
	Item.PasswordMode = True;
	Item.ChoiceButtonPicture = PictureLib.CharsBeingTypedShown;
	Item.ChoiceButton = False;
	
EndProcedure

Procedure GetStatusesOfEmailMessages() Export

	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.GetStatusesOfEmailMessages);
	
	EmailMessagesIDs = New ValueTable;
	EmailMessagesIDs.Columns.Add("Sender",         New TypeDescription("CatalogRef.EmailAccounts"));
	EmailMessagesIDs.Columns.Add("EmailID", New TypeDescription("String",,,,New StringQualifiers(255)));
	EmailMessagesIDs.Columns.Add("RecipientAddress",     New TypeDescription("String",,,,New StringQualifiers(100)));
	
	BeforeGetEmailMessagesStatuses(EmailMessagesIDs);
	
	If EmailMessagesIDs.Count() = 0 Then
		Return;
	EndIf;
		
	Query = New Query;
	Query.Text = 
		"SELECT
		|	EmailMessagesIDs.Sender AS Sender,
		|	EmailMessagesIDs.EmailID AS EmailID,
		|	EmailMessagesIDs.RecipientAddress AS RecipientAddress
		|INTO EmailMessagesIDs
		|FROM
		|	&EmailMessagesIDs AS EmailMessagesIDs
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	EmailMessagesIDs.Sender AS Sender,
		|	EmailMessagesIDs.EmailID AS EmailID,
		|	EmailMessagesIDs.RecipientAddress AS RecipientAddress
		|FROM
		|	EmailMessagesIDs AS EmailMessagesIDs
		|		LEFT JOIN Catalog.EmailAccounts AS EmailAccounts
		|		ON EmailMessagesIDs.Sender = EmailAccounts.Ref
		|WHERE
		|	ISNULL(EmailAccounts.UseForReceiving, FALSE)
		|TOTALS BY
		|	Sender";
	
	Query.SetParameter("EmailMessagesIDs", EmailMessagesIDs);
	
	QueryResult = Query.Execute();
	
	SelectionSender = QueryResult.Select(QueryResultIteration.ByGroups);
	
	MessagesImportParameters = New Structure;
	ColumnsOfMessagesTable = New Array;
	InternetMailMessageFields = EmailOperations.InternetMailMessageFields();
	ColumnsOfMessagesTable.Add(InternetMailMessageFields.Header);
	ColumnsOfMessagesTable.Add(InternetMailMessageFields.PostingDate);
	ColumnsOfMessagesTable.Add(InternetMailMessageFields.Texts);
	ColumnsOfMessagesTable.Add(InternetMailMessageFields.From);
	MessagesImportParameters.Insert("Columns", ColumnsOfMessagesTable);
	
	FilterMessages_ = New Structure;
	FilterMessages_.Insert("AfterDateOfPosting", BegOfDay(CurrentSessionDate()) - 86400);
	MessagesImportParameters.Insert("Filter", FilterMessages_);

	DeliveryStatuses = New ValueTable;
	DeliveryStatuses.Columns.Add("Sender",        	 New TypeDescription("CatalogRef.EmailAccounts"));
	DeliveryStatuses.Columns.Add("EmailID",  New TypeDescription("String",,,,New StringQualifiers(255)));
	DeliveryStatuses.Columns.Add("RecipientAddress",      New TypeDescription("String",,,,New StringQualifiers(100)));
	DeliveryStatuses.Columns.Add("Status",               New TypeDescription("EnumRef.EmailMessagesStatuses"));
	DeliveryStatuses.Columns.Add("StatusChangeDate", New TypeDescription("Date"));  
	DeliveryStatuses.Columns.Add("Cause",              New TypeDescription("String",,,,New StringQualifiers(500)));
	
	While SelectionSender.Next() Do
					
		Messages = EmailOperations.DownloadEmailMessages(SelectionSender.Sender, MessagesImportParameters);
		
		Selection = SelectionSender.Select();
		
		While Selection.Next() Do
			For Each Message In Messages Do // InternetMailMessage
				If StrFind(Message.Header, Selection.RecipientAddress) = 0 
					And StrFind(Message.Header, Selection.EmailID) = 0
					And StrFind(Message.From, "mailer-daemon")= 0 
					And StrFind(Message.Header, "prod.outlook.com")= 0 Then
					Continue;
				EndIf;
				If StrFind(Message.Header, Selection.EmailID) > 0 Then
					If StrFind(Message.Header, Selection.RecipientAddress) > 0 And StrFind(Message.Header, "X-Failed-Recipients") > 0  Then
						RowFilter = New Structure("EmailID, RecipientAddress", Selection.EmailID, Selection.RecipientAddress);
						ExistingStatusesRows = DeliveryStatuses.FindRows(RowFilter);
						If ExistingStatusesRows.Count() > 0 Then
							DeliveryStatusesString = ExistingStatusesRows[0];
						Else
							DeliveryStatusesString = DeliveryStatuses.Add(); 
						EndIf;
						DeliveryStatusesString.Sender = SelectionSender.Sender;
						DeliveryStatusesString.EmailID = Selection.EmailID;
						DeliveryStatusesString.RecipientAddress = Selection.RecipientAddress;
						DeliveryStatusesString.Status = Enums.EmailMessagesStatuses.NotDelivered;
						
						CharNumberReasonLine = StrFind(Message.Header, "X-Mailer-Daemon-Error");
						If CharNumberReasonLine > 0 Then 
							CharNumberReasonStart = CharNumberReasonLine + StrLen("X-Mailer-Daemon-Error:");
							Cause = Mid(Message.Header, CharNumberReasonStart);
							CharNumberNewLine = StrFind(Cause, Chars.LF);
							Cause = TrimAll(Left(Cause, CharNumberNewLine));
							Cause = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Chưa gửi thư do nguyên nhân: %1.';
									|ru = 'Письмо не доставлено по причине: %1.';
									|en = 'The message is not delivered due to: %1.'; fa = 'The message is not delivered due to: %1.';
									|it = 'Письмо не доставлено по причине: %1.';
									|pl = 'The message is not delivered due to: %1.';
									|tr = 'E-posta şu sebeple gönderilmedi: %1.'"), Cause);
						Else
								Cause = NStr("vi = 'Chưa gửi thư.';
											|ru = 'Письмо не доставлено.';
											|en = 'The message is not delivered.'; fa = 'The message is not delivered.';
											|it = 'Письмо не доставлено.';
											|pl = 'The message is not delivered.';
											|tr = 'E-posta gönderilmedi.'");
						EndIf;
						
						DeliveryStatusesString.Cause = Cause;
						DeliveryStatusesString.StatusChangeDate = Message.PostingDate;
						Break;
					ElsIf StrFind(Message.Header, "Delivery Status Notification") > 0 Or StrFind(
						Message.Header, "Disposition-Notification-To") > 0 
						Or StrFind(Message.Header, "report-type=delivery-status") > 0 Then
						
						RowFilter = New Structure("EmailID, RecipientAddress", Selection.EmailID, Selection.RecipientAddress);
						ExistingStatusesRows = DeliveryStatuses.FindRows(RowFilter);
						If ExistingStatusesRows.Count() > 0 Then
							Continue;
						EndIf;
						
						DeliveryStatusesString = DeliveryStatuses.Add();
						DeliveryStatusesString.Sender = SelectionSender.Sender;
						DeliveryStatusesString.EmailID = Selection.EmailID;
						DeliveryStatusesString.RecipientAddress = Selection.RecipientAddress;
						DeliveryStatusesString.Status = Enums.EmailMessagesStatuses.Delivered;
						DeliveryStatusesString.StatusChangeDate = Message.PostingDate;
						Continue;
					EndIf;
				Else
					If Message.Texts.Count() > 0 Then
						For Each EmailText In Message.Texts Do
							If EmailText["TextType"] = "HTML" Then
								Continue;
							EndIf;
							RowFilter = New Structure("EmailID, RecipientAddress", Selection.EmailID, Selection.RecipientAddress);
							ExistingStatusesRows = DeliveryStatuses.FindRows(RowFilter);
							If ExistingStatusesRows.Count() > 0 Then
								Break;
							EndIf;

							If StrFind(EmailText["Text"], Selection.EmailID) > 0
								And StrFind(EmailText["Text"], Selection.RecipientAddress) > 0
								And (StrFind(EmailText["Text"], "this error:") > 0
								Or StrFind(EmailText["Text"], "Delivery has failed") > 0) Then
								DeliveryStatusesString = DeliveryStatuses.Add();
								DeliveryStatusesString.Sender = SelectionSender.Sender;
								DeliveryStatusesString.EmailID = Selection.EmailID;
								DeliveryStatusesString.RecipientAddress = Selection.RecipientAddress;
								DeliveryStatusesString.Status = Enums.EmailMessagesStatuses.NotDelivered;
								
								CharNumberReasonStart = StrFind(EmailText["Text"], "this error:");
								If CharNumberReasonStart = 0 Then
									CharNumberReasonStart = StrFind(EmailText["Text"], "Your message");
								EndIf;
								Cause = Mid(EmailText["Text"], CharNumberReasonStart);
								CharNumberReasonEnd = StrFind(Cause, Chars.LF,,,2);
								Cause = Mid(Cause, 1, CharNumberReasonEnd);
								
								Cause = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Chưa gửi thư do nguyên nhân: %1.';
									|ru = 'Письмо не доставлено по причине: %1.';
									|en = 'The message is not delivered due to: %1.'; fa = 'The message is not delivered due to: %1.';
									|it = 'Письмо не доставлено по причине: %1.';
									|pl = 'The message is not delivered due to: %1.';
									|tr = 'E-posta şu sebeple gönderilmedi: %1.'"), TrimAll(Cause));
								
								DeliveryStatusesString.Cause = Cause;
								DeliveryStatusesString.StatusChangeDate = Message.PostingDate;
								
							ElsIf StrFind(EmailText["Text"], Selection.EmailID) > 0
								And StrFind(EmailText["Text"], Selection.RecipientAddress) > 0 Then
								
								DeliveryStatusesString = DeliveryStatuses.Add();
								DeliveryStatusesString.Sender = SelectionSender.Sender;
								DeliveryStatusesString.EmailID = Selection.EmailID;
								DeliveryStatusesString.RecipientAddress = Selection.RecipientAddress;
								DeliveryStatusesString.Status = Enums.EmailMessagesStatuses.Delivered;
								DeliveryStatusesString.StatusChangeDate = Message.PostingDate;
							ElsIf StrFind(EmailText["Text"], Selection.RecipientAddress) > 0
								And StrFind(EmailText["Text"], "message could not") Then
								
								DeliveryStatusesString = DeliveryStatuses.Add(); 
								DeliveryStatusesString.Sender = SelectionSender.Sender;
								DeliveryStatusesString.EmailID = Selection.EmailID;
								DeliveryStatusesString.RecipientAddress = Selection.RecipientAddress;
								DeliveryStatusesString.Status = Enums.EmailMessagesStatuses.NotDelivered;
								
								CharNumberReasonStart = StrFind(EmailText["Text"], Selection.RecipientAddress, SearchDirection.FromEnd);
								Cause = Mid(EmailText["Text"], CharNumberReasonStart);
								Cause = StrReplace(Cause, Chars.CR, "");
								
								Cause = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Chưa gửi thư do nguyên nhân: %1.';
									|ru = 'Письмо не доставлено по причине: %1.';
									|en = 'The message is not delivered due to: %1.'; fa = 'The message is not delivered due to: %1.';
									|it = 'Письмо не доставлено по причине: %1.';
									|pl = 'The message is not delivered due to: %1.';
									|tr = 'E-posta şu sebeple gönderilmedi: %1.'"), TrimAll(Cause));
								
								DeliveryStatusesString.Cause = Cause;
								DeliveryStatusesString.StatusChangeDate = Message.PostingDate;
								
							EndIf;
							Continue;
						EndDo;
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	
	EndDo;
	
	AfterGetEmailMessagesStatuses(DeliveryStatuses);
	
EndProcedure

// See EmailOperationsOverridable.BeforeGetEmailMessagesStatuses
Procedure BeforeGetEmailMessagesStatuses(EmailMessagesIDs) 
	
	SSLSubsystemsIntegration.BeforeGetEmailMessagesStatuses(EmailMessagesIDs);
	EmailOperationsOverridable.BeforeGetEmailMessagesStatuses(EmailMessagesIDs);  
	
EndProcedure  

// See EmailOperationsOverridable.AfterGetEmailMessagesStatuses
Procedure AfterGetEmailMessagesStatuses(DeliveryStatuses)
	
	SSLSubsystemsIntegration.AfterGetEmailMessagesStatuses(DeliveryStatuses);
	EmailOperationsOverridable.AfterGetEmailMessagesStatuses(DeliveryStatuses);  
	
EndProcedure

Function ConnectToEmailAccount(Val Account, Val ForReceiving = False) Export
	
	SetSafeModeDisabled(True);
	InternetMailProfile = InternetMailProfile(Account, ForReceiving);
	SetSafeModeDisabled(False);
	
	Protocol = InternetMailProtocol.POP3;
	If ForReceiving And ValueIsFilled(InternetMailProfile.IMAPServerAddress)
		Or Not ForReceiving And UseIMAPOnSendingEmails(InternetMailProfile) Then
		Protocol = InternetMailProtocol.IMAP;
	EndIf;
	
	InternetMail = New InternetMail;
	ConnectToInternetMail(InternetMail, InternetMailProfile, Protocol);
	
	Return InternetMail;
	
EndFunction

Procedure ConnectToInternetMail(InternetMail, Profile, Protocol)
	
	Try
		InternetMail.Logon(Profile, Protocol);
	Except
		
		ErrorInfo = ErrorInfo();
		ExceptionClarification = CommonClientServer.ExceptionClarification(ErrorInfo);
		ErrorCode = EmailOperationsInternalClientServer.InternetMailErrorCode();
		
		Raise(ExceptionClarification.Text, ExceptionClarification.Category, ErrorCode, , ErrorInfo);
		
	EndTry;
	
EndProcedure

#Region Punycode

Function EncodeStringWithDelimiter(String, Separators = ".")
	SubstringsArray = StrSplit(String, Separators);
	CopiedHostAddress = "";
	SeparatorPosition = 0;
	For Each Substring In SubstringsArray Do
		SeparatorPosition = SeparatorPosition + StrLen(Substring)+1; 
		CopiedHostAddress = CopiedHostAddress + EncodePunycodeString(Substring);
		CopiedHostAddress = CopiedHostAddress + Mid(String, SeparatorPosition, 1);
	EndDo;
	Return CopiedHostAddress;
EndFunction

Function DecodeStringWithDelimiter(String, Separators = ".")
	SubstringsArray = StrSplit(String, Separators);
	DecodedHostAddress = "";
	SeparatorPosition = 0;
	For Each Substring In SubstringsArray Do
		SeparatorPosition = SeparatorPosition + StrLen(Substring)+1; 
		DecodedHostAddress = DecodedHostAddress + DecodePunycodeString(Substring);
		DecodedHostAddress = DecodedHostAddress + Mid(String, SeparatorPosition, 1);
	EndDo;
	Return DecodedHostAddress;
EndFunction

// Parameters:
//  MailMessage - InternetMailMessage
//
Procedure EncodeAddressesInEmailMessage(MailMessage)
	CopyAddressesCollection(MailMessage.ReadReceiptAddresses);
	CopyAddressesCollection(MailMessage.ReplyTo);
	CopyAddressesCollection(MailMessage.To);
	CopyAddressesCollection(MailMessage.Bcc);
	MailMessage.From.Address = StringIntoPunycode(MailMessage.From.Address);
EndProcedure

// Parameters:
//  CollectionOfAddresses - InternetMailAddresses
//
Procedure CopyAddressesCollection(CollectionOfAddresses)
	If CollectionOfAddresses <> Undefined Then
		For Each Address In CollectionOfAddresses Do
			Address.Address = StringIntoPunycode(Address.Address);
		EndDo;
	EndIf;
EndProcedure

// Parameters:
//  CollectionOfAddresses - InternetMailAddresses
//
Procedure DecodeAddressesCollection(CollectionOfAddresses)
	If CollectionOfAddresses <> Undefined Then
		For Each Address In CollectionOfAddresses Do
			Address.Address = PunycodeIntoString(Address.Address);
		EndDo;
	EndIf;
EndProcedure

Function IsASCIIChar(Val Char)
	Return CharCode(Char) < 128;
EndFunction

Function OrdinalNumberIntoChar(Val SequenceNumber)
	Return Char(SequenceNumber + 22 + 75 * (SequenceNumber < 26));
EndFunction

Function CharCodeToOrdinalNum(Val Code)
	Code0 = CharCode("0");
	CodeA = CharCode("a");
	
	If Code - Code0 < 10 Then
		Return Code - Code0 + 26;
	ElsIf Code - CodeA < 26 Then
		Return Code - CodeA;
	Else
		Raise NStr("vi = 'Dữ liệu đăng nhập không hợp lệ';
					|ru = 'Плохие данные на вход';
					|en = 'Bad input data'; fa = 'Bad input data';
					|it = 'Плохие данные на вход';
					|pl = 'Bad input data';
					|tr = 'Girişteki kötü veriler'");
	EndIf;
EndFunction

Function OffsetAdaptation(Val Delta, Val CharPosition, Val FirstAdaptation)
	Delta = Int(?(FirstAdaptation, Delta / 700, Delta / 2));
	Delta = Delta + Int(Delta / CharPosition);
	
	DeltaDivider = 36 - 1;
	Threshold = Int(DeltaDivider * 26 / 2);
	Move = 0;
	
	While Delta > Threshold Do
		Delta = Int(Delta / DeltaDivider);
		Move = Move + 36;
	EndDo;
	
	Return Move + Int((DeltaDivider + 1) * Delta / (Delta + 38));
EndFunction

Function EncodePunycodeString(Val IncomingString)
	Result = New Array;
	
	Delta = 0;
	CurrentPosition = 0;
	OutputCharCount = 0;
	CurrentGreatest = 0;
	AdjustedDelta = 0;
	Move = 0;

	Largest = 128;
	Offset = 72;
	StringLength = StrLen(IncomingString);

	For SymbolIndex = 1 To StringLength Do
		NextInTurnChar = Mid(IncomingString, SymbolIndex, 1);
		If IsASCIIChar(NextInTurnChar) Then
			Result.Add(NextInTurnChar);
			OutputCharCount = OutputCharCount + 1;
		EndIf;
	EndDo;

	CurrentPosition = OutputCharCount;
	Begin = OutputCharCount;

	If OutputCharCount = StringLength Then
		Return IncomingString;
	EndIf;
	
	HasHyphen = ?(Result.Find("-") = Undefined, False, True);
	
	Result.Add("-");
	OutputCharCount = OutputCharCount + 1;

	While CurrentPosition < StringLength Do
		CurrentGreatest = 9999999999;
		For SymbolIndex = 1 To StringLength Do
			Code = CharCode(IncomingString, SymbolIndex);
			If Code >= Largest And Code < CurrentGreatest Then
				CurrentGreatest = Code;
			EndIf;
		EndDo;
		
		If CurrentGreatest - Largest > Int((9999999999 - Delta) / (CurrentPosition + 1)) Then
			Raise "Overflow";
		EndIf;
		
		Delta = Delta + (CurrentGreatest - Largest) * (CurrentPosition + 1);
		Largest = CurrentGreatest;
		
		For SymbolIndex = 1 To StringLength Do
			Code = CharCode(IncomingString, SymbolIndex);
			If Code < Largest Then
				Delta = Delta + 1;
				If Delta = 0 Then
					Raise "Overflow";
				EndIf;
			ElsIf Code = Largest Then
				AdjustedDelta = Delta;
				Move = 36;
				
				While True Do
					EstimatedSequenceNumber = ?(Move <= Offset, 1,
						?(Move >= Offset + 26, 26, Move - Offset));
					If AdjustedDelta < EstimatedSequenceNumber Then
						Break;
					EndIf;
					
					EncodedChar = OrdinalNumberIntoChar(EstimatedSequenceNumber 
					+ (AdjustedDelta - EstimatedSequenceNumber) % (36 - EstimatedSequenceNumber));
					Result.Add(EncodedChar);
					
					AdjustedDelta = Int((AdjustedDelta - EstimatedSequenceNumber) / (36 - EstimatedSequenceNumber));
					Move = Move + 36;
				EndDo;
				
				Result.Add(OrdinalNumberIntoChar(AdjustedDelta));
				
				Offset = OffsetAdaptation(Delta, CurrentPosition + 1, CurrentPosition = Begin);
				Delta = 0;
				CurrentPosition = CurrentPosition + 1;
			EndIf;
		EndDo;
		
		Delta = Delta + 1;
		Largest = Largest + 1;
	EndDo;
	EncodedString = "xn--" + StrConcat(Result);
	
	If Not HasHyphen Then
		EncodedString = StrReplace(EncodedString, "---", "--");
	EndIf;
	
	Return EncodedString;
EndFunction

Function DecodePunycodeString(Val EncodedString)
	If Not StrStartsWith(EncodedString, "xn--") Then
		Return EncodedString;
	Else
		EncodedString = StrReplace(EncodedString, "xn--", "");
	EndIf;
	Result = New Array;
	Code = 128;
	InsertPosition = 0;
	Offset = 72;
	
	ReadPosition = StrFind(EncodedString, "-", SearchDirection.FromEnd);
	If ReadPosition > 0 Then
		For SymbolIndex = 1 To ReadPosition-1 Do
			NextInTurnChar = Mid(EncodedString, SymbolIndex, 1);
			If Not IsASCIIChar(NextInTurnChar) Then
				Raise NStr("vi = 'Dữ liệu đăng nhập không hợp lệ';
							|ru = 'Плохие данные на вход';
							|en = 'Bad input data'; fa = 'Bad input data';
							|it = 'Плохие данные на вход';
							|pl = 'Bad input data';
							|tr = 'Girişteki kötü veriler'");
			EndIf;
			Result.Add(NextInTurnChar);
		EndDo;
	EndIf;
	ReadPosition = ReadPosition + 1;

	While ReadPosition <= StrLen(EncodedString) Do
		PrevInsertionPosition = InsertPosition;
		InsertionPositionMultiplier = 1;
		Move = 36;
		
		While True Do
			If ReadPosition > StrLen(EncodedString) Then
				Raise NStr("vi = 'Dữ liệu đăng nhập không hợp lệ';
							|ru = 'Плохие данные на вход';
							|en = 'Bad input data'; fa = 'Bad input data';
							|it = 'Плохие данные на вход';
							|pl = 'Bad input data';
							|tr = 'Girişteki kötü veriler'");
			EndIf;
			
			NextCharCode = CharCode(Mid(EncodedString, ReadPosition, 1));
			ReadPosition = ReadPosition + 1;
			
			NextCharOrdinalNum = CharCodeToOrdinalNum(NextCharCode);
			If NextCharOrdinalNum > (9999999999 - InsertPosition) / InsertionPositionMultiplier Then
				Raise NStr("vi = 'Đầy';
							|ru = 'Переполнение';
							|en = 'Overflow'; fa = 'Overflow';
							|it = 'Переполнение';
							|pl = 'Overflow';
							|tr = 'Fazla doldurma'");
			EndIf;
			
			InsertPosition = InsertPosition + NextCharOrdinalNum * InsertionPositionMultiplier;
			
			SequenceNumber = 0;
			If Move <= Offset Then
				SequenceNumber = 1;
			ElsIf Move >= Offset + 26 Then
				SequenceNumber = 26;
			Else
				SequenceNumber = Move - Offset;
			EndIf;
			If NextCharOrdinalNum < SequenceNumber Then
				Break;
			EndIf;
			
			InsertionPositionMultiplier = InsertionPositionMultiplier * (36 - SequenceNumber);
			Move = Move + 36;
		EndDo;
		
		If (InsertPosition / (Result.Count() + 1)) > (9999999999 - Code) Then
			Raise NStr("vi = 'Đầy';
						|ru = 'Переполнение';
						|en = 'Overflow'; fa = 'Overflow';
						|it = 'Переполнение';
						|pl = 'Overflow';
						|tr = 'Fazla doldurma'");
		EndIf;
		
		Offset = OffsetAdaptation(InsertPosition - PrevInsertionPosition, Result.Count() + 1, PrevInsertionPosition = 0);

		Code = Code + Int(InsertPosition / (Result.Count() + 1));
		InsertPosition = InsertPosition % (Result.Count() + 1);
		Result.Insert(InsertPosition, Char(Code));
		InsertPosition = InsertPosition + 1;
	EndDo;

	Return StrConcat(Result);
EndFunction

// Decodes a string using the Punycode algorithm
// 
// Parameters:
//  String - String - encoded string
// 
// Returns:
//  String - decoded string
//
Function PunycodeIntoString(Val String) Export
	URIStructure = CommonClientServer.URIStructure(String);
	HostAddress = URIStructure.Host;
	DecodedHostAddress = DecodeStringWithDelimiter(HostAddress);
	Result = StrReplace(String, HostAddress, DecodedHostAddress);
	
	Login = URIStructure.Login;
	DecodedUsername = DecodeStringWithDelimiter(Login);
	Result = StrReplace(Result, Login, DecodedUsername);
		
	Return Result;
EndFunction

Function DNSServerAddresses() Export
	
	Result = New Array;
	
	StandardProcessing = True;
	EmailOperationsLocalization.OnGettingDNSServerAddresses(Result, StandardProcessing);
	If Not StandardProcessing Then
		Return Result;
	EndIf;
	
	Result.Add("8.8.8.8"); // dns.google
	Result.Add("8.8.4.4"); // dns.google
	
	Return Result;
	
EndFunction

Function AddressOfFileWithSettings() Export
	
	FileAddress = "https://downloads.1c.eu/content/common/settings/mailservers.json";
	EmailOperationsLocalization.OnReceivingAddressOfSettingsFile(FileAddress);
	Return FileAddress;
		
EndFunction

Function AddressOfFIleWithErrorsDetails()
	
	FileAddress = "https://downloads.1c.eu/content/common/settings/v2/mailerrors.json";
	EmailOperationsLocalization.OnReceivingAddressOfFileWithDescriptionOfErrors(FileAddress);
	Return FileAddress;
	
EndFunction

Function AddressOfExternalResource()
	
	AddressOfExternalResource = "downloads.1c.eu";
	EmailOperationsLocalization.OnGettingAddressOfExternalResource(AddressOfExternalResource);
	Return AddressOfExternalResource;
	
EndFunction

#EndRegion

Function IsMailServiceOpenAuthorizationPublished() Export
	
	IsServicePublished = False;
	InfobasePublicationURL = Common.InfobasePublicationURL();
	
	If Not ValueIsFilled(InfobasePublicationURL) Then
		Return IsServicePublished;
	EndIf;
	
	If Not IsEmbeddedServicePublicationCheckAvailable() Then
		Return IsServicePublished;
	EndIf;
	
	URIStructure = CommonClientServer.URIStructure(InfobasePublicationURL);
	
	ServerAddress = URIStructure.Host;
	ResourceAddress = "/" + URIStructure.PathAtServer + "/hs/oauth2_mail/ping";
	Port = URIStructure.Port;
	
	Proxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		Proxy = ModuleNetworkDownload.GetProxy("https");
	EndIf;
	
	SecureConnection = Undefined;
	If Lower(URIStructure.Schema) = Lower("https") Then
		SecureConnection = CommonClientServer.NewSecureConnection();
	EndIf;
	
	Try
		
		Query = New HTTPRequest(ResourceAddress);
		Join = New HTTPConnection(ServerAddress, Port, , , Proxy, 5, SecureConnection);
		
		Response = Join.Get(Query);
		IsServicePublished = Response.StatusCode = 200;
		
	Except
		
		CommentTemplate = NStr("ru = 'Не удалось проверить публикацию HTTP-сервиса ""Открытая авторизация почтового сервиса"".
			|
			|Подробное описание:
			|%1';
			|vi = 'Failed to verify publication of the HTTP service ""Open authorization of the email service"".
			|
			|Details:
			|%1';
			|en = 'Failed to verify publication of the HTTP service ""Open authorization of the email service"".
			|
			|Details:
			|%1'; fa = 'Failed to verify publication of the HTTP service ""Open authorization of the email service"".
			|
			|Details:
			|%1';
			|it = 'Failed to verify publication of the HTTP service ""Open authorization of the email service"".
			|
			|Details:
			|%1';
			|pl = 'Failed to verify publication of the HTTP service ""Open authorization of the email service"".
			|
			|Details:
			|%1';
			|tr = '""E-posta servisi açık yetkilendirmesi"" HTTP servisinin yayını kontrol edilemedi.
			|
			|Ayrıntılı açıklama:
			|%1'");
		
		Comment = StringFunctionsClientServer.SubstituteParametersToString(
			CommentTemplate,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(
			EventNameAuthorizationByProtocolOAuth(),
			EventLogLevel.Information,
			,
			,
			Comment);
			
	EndTry;
	
	Return IsServicePublished;
	
EndFunction

Function IsEmbeddedServicePublicationCheckAvailable()
	
	Return Not (Common.FileInfobase()
		And (Common.IsWebClient() Or Common.ClientConnectedOverWebServer()));
	
EndFunction

Function MailServiceOpenAuthorizationAddress() Export
	
	Return Common.InfobasePublicationURL() + "/hs/oauth2_mail/callback";
	
EndFunction

#EndRegion