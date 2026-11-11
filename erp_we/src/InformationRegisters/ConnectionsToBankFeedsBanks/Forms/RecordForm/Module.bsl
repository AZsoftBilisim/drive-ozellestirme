#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.CompanyLink)
		And ValueIsFilled(Parameters.BankLink) Then
		
		LinkEntry = InformationRegisters.ConnectionsToBankFeedsBanks.CreateRecordManager();
		LinkEntry.Organization = Parameters.CompanyLink;
		LinkEntry.Bank = Parameters.BankLink;
		LinkEntry.Read();
		
		If ValueIsFilled(LinkEntry.Organization)
			And ValueIsFilled(LinkEntry.Bank) Then
			ValueToFormData(LinkEntry, Record);
		Else
			Record.Organization = Parameters.CompanyLink;
			Record.Bank = Parameters.BankLink;
		EndIf;

	Else

		LinkEntry = InformationRegisters.ConnectionsToBankFeedsBanks.CreateRecordManager();
		LinkEntry.Organization = Record.Organization;
		LinkEntry.Bank = Record.Bank;
		LinkEntry.Read();
		
	EndIf;
	
	If LinkEntry <> Undefined Then

		RegistrationAttributes = LinkEntry.RegistrationAttributes.Get();  
		
		If ValueIsFilled(RegistrationAttributes) Then
		
			FillPropertyValues(ThisObject, RegistrationAttributes);
		
		EndIf;	

	EndIf;	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	StartCheckingStatusOfConnectionAndConsent();
	
EndProcedure

#EndRegion
		  
#Region FormCommandsEventHandlers
		  
&AtClient
Procedure Connect(Command)
	
	FillParameters = New Structure();
	FillParameters.Insert("Organization", Record.Organization);
	FillParameters.Insert("Bank", Record.Bank);
	FillParameters.Insert("ServiceSettings", Record.ServiceSettings);
	FillParameters.Insert("RegistrationAttributes", ReadRegistrationDetailsOnServer(FillParameters));
	FillParameters.Insert("NewConnectionOnly", True);
	FillParameters.Insert("email", Record.email);

	ExchangeWithBankFeedsServiceClient.EnableServiceOnClient(FillParameters, ThisObject);	
	
EndProcedure

&AtClient
Procedure Disconnect(Command)
	
    Close(New Structure("DisableBankFeeds", True));
	
EndProcedure

&AtClient
Procedure UpdateConnection(Command)
	
	FillParameters = New Structure();
	FillParameters.Insert("Organization", Record.Organization);
	FillParameters.Insert("Bank", Record.Bank);
	FillParameters.Insert("RegistrationAttributes", ReadRegistrationDetailsOnServer(FillParameters));
	FillParameters.Insert("ServiceSettings", Record.ServiceSettings);
	FillParameters.Insert("email", Record.email);
	FillParameters.Insert("ThisIsConnectionUpdate", True);

	ExchangeWithBankFeedsServiceClient.UpdateServiceConnectionOnClient(FillParameters, ThisObject);	
	
EndProcedure

&AtClient
Procedure Revoke_Consent(Command)
	
	FillParameters = New Structure();
	FillParameters.Insert("Organization", Record.Organization);
	FillParameters.Insert("Bank", Record.Bank);
	FillParameters.Insert("ServiceSettings", Record.ServiceSettings);
	FillParameters.Insert("email", Record.email);

	ExchangeWithBankFeedsServiceClient.RevokeConsentToConnectServiceOnClient(FillParameters, ThisObject);	
	
EndProcedure

&AtClient
Procedure CheckStatusOfConnectionAndConsent(Command)
	
	StartCheckingStatusOfConnectionAndConsent();	
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure StartCheckingStatusOfConnectionAndConsent() Export
	
	StatusesAreBeingChecked = True;
	FormControl();
	
	FillParameters = New Structure();
	FillParameters.Insert("Organization", Record.Organization);
	FillParameters.Insert("Bank", Record.Bank);
	FillParameters.Insert("ServiceSettings", Record.ServiceSettings);
	FillParameters.Insert("email", Record.email);

	ExchangeWithBankFeedsServiceClient.CheckStatusOfConnectionAndConsentOfServiceOnClient(FillParameters, ThisObject);	
	
EndProcedure

&AtClient
Procedure FillInAuthorizationFormOnServiceWithData(LinkToAuthorizationInService, RequestFillingParameters) Export
	
	HandlerNotifications = New CallbackDescription("AfterCreatingExchangeSettingsBankFeeds", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", RequestFillingParameters.Organization);
	FormParameters.Insert("Bank", RequestFillingParameters.Bank);
	FormParameters.Insert("LinkToAuthorization", LinkToAuthorizationInService); 
	FormParameters.Insert("FillParameters", RequestFillingParameters); 
	FormParameters.Insert("CreateConnectionOfExistingConnection", True); 
	
	OpenForm("InformationRegister.ConnectionsToBankFeedsBanks.Form.ConnectionForm", FormParameters, , , , ,
		HandlerNotifications);
	
EndProcedure	

&AtClient
Procedure AfterCreatingExchangeSettingsBankFeeds(ConfigureExchange, Var_Parameters) Export

	StartCheckingStatusOfConnectionAndConsent();
			
EndProcedure

&AtClient
Procedure EndingConnectionToService(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ResultOfResponseFromService = GetFromTempStorage(Result.ResultAddress);
	
	If Result.Status = "Error" Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lỗi kết nối theo doanh nghiệp %1, đến ngân hàng %2. Chưa kết nối';
				|ru = 'Ошибка подключения по организации %1, к банку %2. Подключение не выполнено';
				|en = 'An error occurred when connecting to the %2 bank for the %1 company. Connection failed'; fa = 'An error occurred when connecting to the %2 bank for the %1 company. Connection failed';
				|it = 'Ошибка подключения по организации %1, к банку %2. Подключение не выполнено';
				|pl = 'An error occurred when connecting to the %2 bank for the %1 company. Connection failed';
				|tr = 'Kuruluş %1 tarafından banka %2''ye bağlantı hatası. Bağlantı tamamlanmadı'"),
			Record.Organization, Record.Bank);
		CommonClient.MessageToUser(MessageText);
		
	ElsIf ResultOfResponseFromService.ResponseStatus = ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses().NoResponseReceived Then
		
		For Each CurrentError In ResultOfResponseFromService.ErrorsArray Do
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi: %1. Chưa kết nối tài khoản!';
					|ru = 'Ошибка: %1. Подключение счета не выполнено!';
					|en = 'Error: %1. Account connection failed.'; fa = 'Error: %1. Account connection failed.';
					|it = 'Ошибка: %1. Подключение счета не выполнено!';
					|pl = 'Error: %1. Account connection failed.';
					|tr = 'Hata: %1. Hesap bağlantısı tamamlanmadı!'"), CurrentError);
			CommonClient.MessageToUser(MessageText);
			
		EndDo;	
		
	ElsIf ResultOfResponseFromService.ResponseStatus = ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses().IsAnswered Then

		If ResultOfResponseFromService.InvoiceId <> "" Then

			Close(New Structure("AccountNumber", ResultOfResponseFromService.InvoiceId));
		
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã kết nối theo doanh nghiệp %1, đến ngân hàng %2.';
					|ru = 'Подключение по организации %1, к банку %2 выполнено.';
					|en = 'Connection to the %2 bank for the %1 company is completed.'; fa = 'Connection to the %2 bank for the %1 company is completed.';
					|it = 'Подключение по организации %1, к банку %2 выполнено.';
					|pl = 'Connection to the %2 bank for the %1 company is completed.';
					|tr = 'Organizasyon %1 tarafından banka %2''ye bağlantı yapıldı.'"),
				Record.Organization, Record.Bank);
			
			ShowUserNotification(NStr("vi = 'Kết nối đến dịch vụ';
										|ru = 'Подключение к сервису';
										|en = 'Connection to service'; fa = 'Connection to service';
										|it = 'Подключение к сервису';
										|pl = 'Connection to service';
										|tr = 'Servise bağlanma'"),,MessageText,,UserNotificationStatus.Important);
			
		Else     
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa kết nối theo doanh nghiệp %1, đến ngân hàng %2. Không tìm thấy tài khoản!';
					|ru = 'Подключение по организации %1, к банку %2 не выполнено. Не найден счет!';
					|en = 'Connection to the %2 bank for the %1 company failed. The account is not found.'; fa = 'Connection to the %2 bank for the %1 company failed. The account is not found.';
					|it = 'Подключение по организации %1, к банку %2 не выполнено. Не найден счет!';
					|pl = 'Connection to the %2 bank for the %1 company failed. The account is not found.';
					|tr = 'Kuruluş %1 tarafından %2 bankasına bağlantı gerçekleştirilmedi. Hesap bulunamadı!'"),
				Record.Organization, Record.Bank);
			ShowMessageBox(,MessageText,,NStr("vi = 'Kết nối đến dịch vụ';
												|ru = 'Подключение к сервису';
												|en = 'Connection to service'; fa = 'Connection to service';
												|it = 'Подключение к сервису';
												|pl = 'Connection to service';
												|tr = 'Servise bağlanma'"));
			
		EndIf;	
		
	Else
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lỗi kết nối theo doanh nghiệp %1, đến ngân hàng %2. Chưa kết nối';
				|ru = 'Ошибка подключения по организации %1, к банку %2. Подключение не выполнено';
				|en = 'An error occurred when connecting to the %2 bank for the %1 company. Connection failed'; fa = 'An error occurred when connecting to the %2 bank for the %1 company. Connection failed';
				|it = 'Ошибка подключения по организации %1, к банку %2. Подключение не выполнено';
				|pl = 'An error occurred when connecting to the %2 bank for the %1 company. Connection failed';
				|tr = 'Kuruluş %1 tarafından banka %2''ye bağlantı hatası. Bağlantı tamamlanmadı'"),
			Record.Organization, Record.Bank);
		CommonClient.MessageToUser(MessageText);
		
	EndIf;	
		
EndProcedure

&AtServerNoContext
Function ReadRegistrationDetailsOnServer(FillParameters)
	
	Return ExchangeWithBankFeedsServer.ReadRegistrationDetailsOnServer(FillParameters);
	
EndFunction	

&AtClient
Procedure FormControl() Export
	
	Items.GroupStatusUpdating.Visible = StatusesAreBeingChecked;
	Items.ConnectionInformationGroup.Visible = Not StatusesAreBeingChecked;
	
	If ConnectionAndAgreementAreActive Then

		Items.ConnectionInfo.TextColor = WebColors.Green;
		
	Else
		
		Items.ConnectionInfo.TextColor = WebColors.Red;
		
	EndIf;
	
	StatusWaiting =   NStr("vi = 'Kiểm tra kết nối...';
							|ru = 'Проверка подключения...';
							|en = 'Checking the connection...'; fa = 'Checking the connection...';
							|it = 'Проверка подключения...';
							|pl = 'Checking the connection...';
							|tr = 'Bağlantı kontrolü...'");
	
EndProcedure	

#EndRegion

