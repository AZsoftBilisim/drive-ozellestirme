#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("DatabaseEnabled") Then
		DatabaseEnabled = Parameters.DatabaseEnabled;
	EndIf;
	
	If DatabaseEnabled Then
		
		DataForSuspIntegrationSettings = InformationCenterServer.DataForSuspIntegrationSettings();
		USPAddress = DataForSuspIntegrationSettings.AddressOfExternalAnonymousInterface;
		Email = DataForSuspIntegrationSettings.SubscriberSEmailAddressForSuspIntegration;
		
		If Not ValueIsFilled(Email) Then
			Items.DecorationUserEmailNotFilledIn.Visible = True;
			Items.EnterRegistrationCode.Enabled = False;
			Items.EnterTokenForRegistration.Enabled = False;
		EndIf;

		Items.InformationDecoration.Title = NStr("vi = 'Cơ sở thông tin được kết nối với bộ phận hỗ trợ với các tham số sau:';
												|ru = 'Информационная база подключена к службе поддержки со следующими параметрами:';
												|en = 'The infobase is connected to the technical support with the following parameters:'; fa = 'The infobase is connected to the technical support with the following parameters:';
												|it = 'L''infobase è collegata al servizio di supporto con i seguenti parametri:';
												|pl = 'Baza informacyjna jest podłączona do pomocy technicznej z następującymi parametrami:';
												|tr = 'Infobase, aşağıdaki ayarlarla destek hizmetine bağlı:'");
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		
		JobParameters = TimeConsumingOperations.ExecuteInBackground(
			"InformationCenterServer.DetermineConnectionStateInBackground", , ExecutionParameters);
		
		Items.ConnectionStateIcon.Picture = PictureLib.TimeConsumingOperation16;
		
		RegistrationCode = InformationCenterServer.WUSPRegistrationCode();
		InformationAboutInformationSecurity = InformationCenterServer.InformationAboutInformationSecurityForIntegration();
		InformationSecurityID = InformationAboutInformationSecurity.InformationSecurityID;
		
	Else
		
		Items.InformationDecoration.Title = NStr("vi = 'Cơ sở thông tin chưa được kết nối với bộ phận hỗ trợ. Có thể kết nối cơ sở thông tin ngay bây giờ.';
												|ru = 'Информационная база не подключена к службе поддержки. Подключить базу можно сейчас.';
												|en = 'The infobase is not connected to the technical support. You can connect the infobase now.'; fa = 'The infobase is not connected to the technical support. You can connect the infobase now.';
												|it = 'L''infobase non è collegata al servizio di supporto. Adesso è possibile collegare l''infobase.';
												|pl = 'Baza informacyjne nie jest podłączona do pomocy technicznej. Podłączyć bazę można teraz.';
												|tr = 'Infobase, destek hizmeti bağlı değil. Şimdi tabanı bağlayabilirsiniz.'");
		
		Email = UsersInternal.UserDetails(Users.AuthorizedUser()).Email;
		InformationAboutInformationSecurity = InformationCenterServer.InformationAboutInformationSecurityForIntegration();
		ConfigurationName = InformationAboutInformationSecurity.ConfigurationName;
		ConfigurationVersion = InformationAboutInformationSecurity.ConfigurationVersion;
		PlatformVersion = InformationAboutInformationSecurity.PlatformVersion;
		ClientID = InformationAboutInformationSecurity.ClientID;
		InformationSecurityID = InformationAboutInformationSecurity.InformationSecurityID;
		
	EndIf;
	
	Items.RegistrationCode.Visible = Not DatabaseEnabled;
	Items.EnterRegistrationCode.Visible = Not DatabaseEnabled;
	Items.GoToRegistrationPage.Visible = Not DatabaseEnabled;
	Items.CancelConnection.Visible = DatabaseEnabled;
	Items.CancelConnection.Enabled = False;
	
	Items.USPAddress.ReadOnly = DatabaseEnabled;
	Items.Email.ReadOnly = DatabaseEnabled;
	Items.ConnectionStatusGroup.Visible = DatabaseEnabled;
	
	Items.GroupEnteringTokenForActivation.Visible = Not DatabaseEnabled;
	
	Items.GoToPageRequestingUserCodes.Visible = DatabaseEnabled;
	Items.GoToPageRequestingUserCodes.Enabled = False;
	
	Items.DecorationInscriptionConnectDatabase.Visible = Not DatabaseEnabled;
	Items.DecorationInscriptionWithHelpOfCode.Visible = Not DatabaseEnabled;
	Items.SeparatorGroup.Visible = Not DatabaseEnabled;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	If DatabaseEnabled Then
		AttachIdleHandler("DetermineConnectionStateInPendingBackground", 1, True);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToRegistrationPage(Command)
	
	If Not ValueIsFilled(USPAddress) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Cần chỉ ra địa chỉ bộ phận hỗ trợ';
				|ru = 'Необходимо указать адрес службы поддержки';
				|en = 'Specify the technical support address'; fa = 'Specify the technical support address';
				|it = 'È necessario indicare l''indirizzo del servizio di supporto';
				|pl = 'Należy podaś adres pomocy technicznej';
				|tr = 'Destek hizmetinin adresini belirtmek gerekiyor'"), , "USPAddress");
		Return;
	EndIf;
	
	If Not ValueIsFilled(Email) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Cần chỉ ra E-mail của người sử dụng';
				|ru = 'Необходимо указать e-mail пользователя';
				|en = 'Specify user email'; fa = 'Specify user email';
				|it = 'È necessario indicare l''email dell''utente';
				|pl = 'Należy podać adres e-mail użytkownika';
				|tr = 'Kullanıcı e-posta adresini belirtmek gerekiyor'"), , "Email");
		Return;
	EndIf;
	
	PageAddressTemplate = "%1/v1/StartLocalRegistration?email=%2&appname=%3&appversion=%4&platf=%5&ibid=%6&clid=%7";
	LinkToPage = StrTemplate(PageAddressTemplate, 
		USPAddress, Email, ConfigurationName, ConfigurationVersion, PlatformVersion, InformationSecurityID, ClientID);
	
	#If WebClient Then
		GotoURL(LinkToPage);
	#Else
		RunApp(LinkToPage);
	#EndIf
	
EndProcedure

&AtClient
Procedure EnterRegistrationCode(Command)
	Result = EnterRegistrationCodeOnServer();
	If Not Result.Success Then
		CommonClient.MessageToUser(Result.MessageText);
	EndIf;
EndProcedure

&AtClient
Procedure GoToRequests(Command)
	
	Close();
	InformationCenterClient.OpenSupportRequests();
	
EndProcedure

&AtClient
Procedure CancelConnection(Command)

	Notification = New CallbackDescription("CancelConnectionWhenCheckingResponse", ThisObject);
	
	QueryText = NStr("vi = 'Sau khi hủy kết nối, sẽ không thể làm việc với giao tiếp tại bộ phận hỗ trợ. Tiếp tục?';
					|ru = 'После отмены подключения работа с обращениями в службу поддержки будет невозможна. Продолжить?';
					|en = 'After the connection is canceled, operations with requests to the technical support will be unavailable. Continue?'; fa = 'After the connection is canceled, operations with requests to the technical support will be unavailable. Continue?';
					|it = 'Dopo l''annullamento della connessione, il lavoro con le richieste nel servizio di supporto non sarà disponibile. Continuare?';
					|pl = 'Po anulowaniu połączenia praca ze zgłoszeniami do pomocy technicznej będzie niemożliwa. Kontynuować?';
					|tr = 'Bağlantıyı kestikten sonra destek hizmet talepleri ile çalışamazsınız. Devam edilsin mi?'");
	
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);

EndProcedure

&AtClient
Procedure RequestUserCodes(Command)
	
	If Not CheckingBeforeSendingCodeRequests() Then
		Return;
	EndIf;

	QueryResult = RequestUserCodesOnServer();
	
	If Not QueryResult.RequestSent Then
		CommonClient.MessageToUser(QueryResult.MessageText);
		Return;
	EndIf;
	
	If QueryResult.Property("QueryID")
		And ValueIsFilled(QueryResult.QueryID)
		And QueryResult.Property("ThereIsPageWithProtection")
		And QueryResult.ThereIsPageWithProtection Then
		OpenPageForReceivingUserCodesWithProtection(QueryResult.QueryID);
		Return;
	EndIf;
	
	If QueryResult.Property("ThereIsPageWithProtection")
		And Not QueryResult.ThereIsPageWithProtection Then
		
		MessageText = StrTemplate(
			NStr("vi = 'Đã gửi %1 thư.';
				|ru = 'Отправлено писем: %1.';
				|en = 'Sent emails: %1.'; fa = 'Sent emails: %1.';
				|it = 'E-mail inviate: %1.';
				|pl = 'Wysłano wiadomości: %1.';
				|tr = 'Gönderilen e-posta: %1'"),
			QueryResult.SentEmailsCount);
			
		MessageText = MessageText 
			+ Chars.LF 
			+ NStr("vi = 'Mã được gửi vào thư, người sử dụng có thể dùng mã này để làm việc với giao tiếp.';
					|ru = 'Код, отправленный в письме, пользователи могут использовать для работы с обращениями.';
					|en = 'Users can use the code sent in the email to manage tickets.'; fa = 'Users can use the code sent in the email to manage tickets.';
					|it = 'Il codice inviato nell''e-mail può essere utilizzato dagli utenti per gestire le richieste.';
					|pl = 'Kod, wysłany w wiadomości, użytkownicy mogą używać do pracy ze zgłoszeniami.';
					|tr = 'E-postada gönderilen kod, kullanıcılar tarafından başvurularla çalışmak için kullanılabilir.'");
		
		If QueryResult.Property("SubscriberHasNoUserAddress") Then
			CheckAndDisplayErrorsInSendingEmails(QueryResult.SubscriberHasNoUserAddress);
		EndIf;

		If ValueIsFilled(QueryResult.MessageText) Then
			MessageText = MessageText + Chars.LF + QueryResult.MessageText;
		EndIf;
		
		CommonClient.MessageToUser(MessageText);
		
		Return;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToPageRequestingUserCodes(Command)
	GoToPageRequestingUserCodesOnServer();
EndProcedure

&AtClient
Procedure EnterTokenForRegistration(Command)
	
	TextInvalidToken = NStr("vi = 'Sai token để đăng ký.';
							|ru = 'Неверный токен для регистрации.';
							|en = 'Incorrect token for registration.'; fa = 'Incorrect token for registration.';
							|it = 'Token non valido per la registrazione.';
							|pl = 'Nieprawidłowy token do rejestracji.';
							|tr = 'Kayıt için hatalı belirteç.'");
	
	If Not ValueIsFilled(TokenForRegistration) Then
		CommonClient.MessageToUser(
			TextInvalidToken,
			,
			"TokenForRegistration");
		Return;
	EndIf;
	
	TokenDecryptionData = TokenDecryptionData(TokenForRegistration);
	
	If Not TokenDecryptionData.Deciphered Then
		CommonClient.MessageToUser(
			TextInvalidToken,
			,
			"TokenForRegistration");
		Return;
	EndIf;
	
	If Not TokenDecryptionData.Data.Property("email") Then
		CommonClient.MessageToUser(
			TextInvalidToken,
			,
			"TokenForRegistration");
		Return;
	EndIf;
	
	If TokenDecryptionData.Data.email <> Email Then
		CommonClient.MessageToUser(
			NStr("vi = 'Token được dùng cho người sử dụng có địa chỉ e-mail khác.';
				|ru = 'Токен предназначен для пользователя с другим адресом электронной почты.';
				|en = 'The token is generated for a user with a different email address.'; fa = 'The token is generated for a user with a different email address.';
				|it = 'Il token è destinato per l''utente con un indirizzo e-mail diverso.';
				|pl = 'Token jest przeznaczony dla użytkownika z innym adresem poczty elektronicznej.';
				|tr = 'Belirteç, farklı bir e-posta adresine sahip bir kullanıcı içindir.'"),
			,
			"TokenForRegistration");
		Return;
	EndIf;

	USPAddress = TokenDecryptionData.Data.url;
	Email = TokenDecryptionData.Data.email;
	RegistrationCode = TokenDecryptionData.Data.code;
	
	Result = EnterRegistrationCodeOnServer();
	If Not Result.Success Then
		CommonClient.MessageToUser(Result.MessageText);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function EnterRegistrationCodeOnServer()
	
	Result = New Structure;
	Result.Insert("MessageText", "");
	Result.Insert("Success", False);
	
	ServiceAddress = USPAddress + "/v1/FinishLocalRegistration";
	
	Try
		
		URIStructure = CommonClientServer.URIStructure(ServiceAddress);
		Host = URIStructure.Host;
		PathAtServer = URIStructure.PathAtServer;
		Port = URIStructure.Port;
		
		If Lower(URIStructure.Schema) = Lower("https") Then
			SecureConnection = 
				CommonClientServer.NewSecureConnection(, New OSCertificationAuthorityCertificates);
		Else
			SecureConnection = Undefined;
		EndIf;
		
		Join = New HTTPConnection(
			Host,
			Port,
			,
			,
			GetFilesFromInternet.GetProxy(URIStructure.Schema),
			,
			SecureConnection);
		
		QueryData = New Structure;
		QueryData.Insert("email", Email);
		QueryData.Insert("appname", ConfigurationName);
		QueryData.Insert("appversion", ConfigurationVersion);
		QueryData.Insert("platf", PlatformVersion);
		QueryData.Insert("ibid", InformationSecurityID);
		QueryData.Insert("clid", ClientID);
		QueryData.Insert("code", RegistrationCode);
		QueryData.Insert("method_name", "FinishLocalRegistration");
		
		JSONWriter = New JSONWriter;
		JSONWriter.SetString();
		WriteJSON(JSONWriter, QueryData);
		
		QueryString = JSONWriter.Close();
		
		Headers = New Map;
		Headers.Insert("Content-Type", "application/json; charset=utf-8");
		Headers.Insert("Accept", "application/json");
		
		Query = New HTTPRequest(PathAtServer, Headers);
		Query.SetBodyFromString(QueryString);
		
		Response = Join.Post(Query);
		
		If Response.StatusCode <> 200 Then
			
			ErrorText = StrTemplate(NStr("vi = 'Lỗi %1';
										|ru = 'Ошибка %1';
										|en = 'Error %1'; fa = 'Error %1';
										|it = 'Errore %1';
										|pl = 'Błąd %1';
										|tr = '%1 hatası'", Common.DefaultLanguageCode()), String(Response.StatusCode));
			RecordError(Result, ErrorText);
			Return Result;
			
		EndIf;
		
		JSONReader = New JSONReader;
		
		ResponseBodyString = Response.GetBodyAsString();
		JSONReader.SetString(ResponseBodyString);
		
		Try
			ResponseData = ReadJSON(JSONReader, False);	
		Except
			RecordError(Result, ResponseBodyString);
			Return Result;
		EndTry;
		
		If Not ResponseData.success Then
			RecordError(Result, ResponseData.response_text);
			Return Result;
		EndIf;
		
		AddressOfInformationCenter = ResponseData.info_center_address;
		
		WhenRegistrationCodeIsSuccessfullyEntered();
		
		Result.Success = True;
		Return Result;
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		RecordError(Result, 
			InformationCenterInternal.DetailedErrorText(ErrorInfo), 
			InformationCenterInternal.ShortErrorText(ErrorInfo));
			
		Return Result;
		
	EndTry;
	
EndFunction

&AtServer
Procedure RecordError(Result, DetailedErrorText, Val ShortErrorText = "")
	
	If Not ValueIsFilled(ShortErrorText) Then
		ShortErrorText = DetailedErrorText;
	EndIf;
	
	Result.Success = False;
	Result.MessageText = ShortErrorText;
	
	WriteLogEvent(
		StrTemplate("%1.%2", EventLogEventName(), 
			NStr("vi = 'Nhập mã đăng ký';
				|ru = 'Ввод кода регистрации';
				|en = 'Enter registration code'; fa = 'کد ثبت‌نام را وارد کنید';
				|it = 'Inserimento del codice di registrazione';
				|pl = 'Wprowadź kod rejestracji';
				|tr = 'Kayıt kodu gir'", Common.DefaultLanguageCode())),
			EventLogLevel.Error,
			,
			,
			DetailedErrorText);
				
	Result.Success = False;
	Result.MessageText = ShortErrorText;
	
EndProcedure

&AtServer
Procedure WhenRegistrationCodeIsSuccessfullyEntered()
	
	Items.DecorationSuccessfulConnection.Title = StrReplace(
		Items.DecorationSuccessfulConnection.Title,
		"[Email]",
		Email);
	
	InformationCenterServer.RecordDataForSuspIntegrationSettings(
		USPAddress,
		True,
		Email,
		RegistrationCode,
		AddressOfInformationCenter);
	
	Items.GroupPages.CurrentPage = Items.SuccessfulConnectionPage;
	
EndProcedure

&AtServer
Function EventLogEventName()
	
	Return InformationCenterServer.GetEventNameForLog();
	
EndFunction

&AtClient
Procedure DefineSupportedBasesInBackgroundEnd(Operation, AdditionalParameters) Export
	
	If Operation.Status = "Completed2" Then
		
		Result = GetFromTempStorage(Operation.ResultAddress);
		
		If Result.Success Then
			Items.ConnectionStateLabel.Title = NStr("vi = 'Đã kết nối';
													|ru = 'Подключено';
													|en = 'Connected'; fa = 'متصل';
													|it = 'Collegato';
													|pl = 'Connected';
													|tr = 'Bağlı'");
			Items.ConnectionStateIcon.Picture = PictureLib.AppearanceCheckIcon;
			Items.CancelConnection.Enabled = True;
			Items.GoToPageRequestingUserCodes.Enabled = True;
		Else
			Items.ConnectionStateLabel.Title = NStr("vi = 'Lỗi kết nối: ';
													|ru = 'Ошибка подключения: ';
													|en = 'Connection error: '; fa = 'Connection error: ';
													|it = 'Errore di connessione: ';
													|pl = 'Błąd połączenia: ';
													|tr = 'Bağlantı hatası:'") + Result.MessageText;
			Items.ConnectionStateIcon.Picture = PictureLib.AppearanceExclamationMarkIcon;
			Items.GoToPageRequestingUserCodes.Enabled = False;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DetermineConnectionStateInPendingBackground()
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	Handler = New CallbackDescription("DefineSupportedBasesInBackgroundEnd", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(JobParameters, Handler, IdleParameters);
	
EndProcedure

&AtServer
Procedure CancelConnectionOnServer()
	
	InformationCenterServer.ClearDataForSuspIntegrationSettings();
	
EndProcedure

&AtClient
Procedure CancelConnectionWhenCheckingResponse(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		CancelConnectionOnServer();
		Close();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function TokenDecryptionData(Token)
	
	Return InformationCenterServer.DecryptTokenForRegistrationInSupportService(Token);
	
EndFunction

&AtServer
Procedure GoToPageRequestingUserCodesOnServer()
	
	FillInListOfInformationSecurityUsers();
	Title = NStr("vi = 'Hỏi mã người sử dụng';
				|ru = 'Запросить коды пользователей';
				|en = 'Request user codes'; fa = 'درخواست کدهای کاربر';
				|it = 'Richiedere i codici degli utenti';
				|pl = 'Zapytaj o kody użytkowników';
				|tr = 'Kullanıcı kodlarını iste'");
	Items.GroupPages.CurrentPage = Items.RequestUserCodePage;
	
EndProcedure

&AtServer
Procedure FillInListOfInformationSecurityUsers()
	
	Query = New Query;
	Query.Text = "SELECT
	|	UsersContactInformation.Ref AS User,
	|	MIN(UsersContactInformation.LineNumber) AS LineNumber
	|INTO UsersWithKILineNumbers
	|FROM
	|	Catalog.Users.ContactInformation AS UsersContactInformation
	|WHERE
	|	NOT UsersContactInformation.Ref.Invalid
	|	AND NOT UsersContactInformation.Ref.IsInternal
	|	AND UsersContactInformation.EMAddress <> """"
	|
	|GROUP BY
	|	UsersContactInformation.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UsersWithKILineNumbers.User AS User,
	|	UsersContactInformation.EMAddress AS Email,
	|	TRUE AS RequestCode
	|FROM
	|	Catalog.Users.ContactInformation AS UsersContactInformation
	|		INNER JOIN UsersWithKILineNumbers AS UsersWithKILineNumbers
	|		ON UsersContactInformation.Ref = UsersWithKILineNumbers.User
	|			AND (UsersWithKILineNumbers.LineNumber = UsersContactInformation.LineNumber)";
	
	UsersToRequestCodes.Load(Query.Execute().Unload());
	
EndProcedure

&AtClient
Procedure OpenPageForReceivingUserCodesWithProtection(QueryID)
	
	PageAddressTemplate = 
		"%1/v1/RequestLocalUserCodesContinue?rid=%2&register_code=%3&ibid=%4";
	LinkToPage = StrTemplate(PageAddressTemplate, 
		USPAddress, QueryID, RegistrationCode, InformationSecurityID);
		
	#If WebClient Then
		GotoURL(LinkToPage);
	#Else
		RunApp(LinkToPage);
	#EndIf
	
EndProcedure

&AtServer
Function RequestUserCodesOnServer()
	
	UserData_ = New Array;
	For Each UserRow1 In UsersToRequestCodes Do
		If Not UserRow1.RequestCode Then
			Continue;
		EndIf;
		UserData_.Add(
			New Structure(
				"username, email",
				String(UserRow1.User),
				UserRow1.Email));
	EndDo;
	
	QueryResult = InformationCenterServer.RequestUserCodes(UserData_);
	
	Return QueryResult;
	
EndFunction

&AtServer
Function CheckingBeforeSendingCodeRequests()
	
	For IndexOf = 0 To UsersToRequestCodes.Count() - 1 Do
		UserRow1 = UsersToRequestCodes[IndexOf];
		If Not CommonClientServer.EmailAddressMeetsRequirements(UserRow1.Email) Then
			Common.MessageToUser(
			NStr("vi = 'Địa chỉ email bị lỗi';
				|ru = 'Адрес электронной почты содержит ошибки';
				|en = 'The email address contains errors'; fa = 'The email address contains errors';
				|it = 'L''indirizzo di posta elettronica contiene degli errori';
				|pl = 'Adres poczty elektronicznej zawiera błędy';
				|tr = 'E-posta adresi hata içeriyor.'"),
			,
			"UsersToRequestCodes["+String(IndexOf)+"].Email");
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

&AtServer
Procedure CheckAndDisplayErrorsInSendingEmails(SubscriberHasNoUserAddress)
	
	If SubscriberHasNoUserAddress = Undefined Then
		Return;
	EndIf;
	
	MessageTemplate = 
		NStr("vi = 'Không có người sử dụng có địa chỉ %1 trong cơ sở của bộ phận hỗ trợ, vì vậy sẽ không gửi thư cho người đó.';
			|ru = 'Пользователя с адресом %1 нет в базе службы поддержки, поэтому ему не отправлено письмо.';
			|en = 'A user with the %1 address is not found in the technical support database, so no email was sent to them.'; fa = 'A user with the %1 address is not found in the technical support database, so no email was sent to them.';
			|it = 'L''utente con l''indirizzo %1 non è presente nel database del servizio di assistenza, pertanto non gli è stata inviata alcuna e-mail.';
			|pl = 'Użytkownika z adresem %1 nie ma w bazie pomocy technicznej, dlatego do niego nie można wysłać wiadomości.';
			|tr = '%1 adrese sahip kullanıcı destek hizmetinde yok, bu yüzden ona e-posta gönderilmedi.'");
	
	For Each Address In SubscriberHasNoUserAddress Do
		
		UserStrings = UsersToRequestCodes.FindRows(New Structure("Email", Address));
		If UserStrings.Count() = 0 Then
			Continue;
		EndIf;
		
		UserRow1 = UserStrings[0];
		RowIndex = UsersToRequestCodes.IndexOf(UserRow1);
		
		MessageText = StrTemplate(MessageTemplate, Address);
		
		Common.MessageToUser(
			MessageText, 
			, 
			"UsersToRequestCodes["+String(RowIndex)+"].Email");
		
	EndDo;
	
EndProcedure

#EndRegion
