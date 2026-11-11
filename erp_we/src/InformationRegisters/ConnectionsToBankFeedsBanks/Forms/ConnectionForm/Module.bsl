  
#Region FormEventHandlers
  
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Organization = Parameters.Organization; 
	If Not ValueIsFilled(Organization) 
		And Not Constants.UseMultipleCompanies.Get() Then
		
		Organization = Catalogs.Companies.GetDefaultOrganization();
		
	EndIf;	

	Bank = Parameters.Bank;
	BankAccount = Parameters.BankAccount;
	ServiceSettings = Parameters.ServiceSettings;
	  
	ThisIsAddInvoiceForm = Parameters.ConnectionFormCommand = 
						BankFeedsDictionaryInternal.CommandsForOpeningActivationForm().AddInvoice;
	ThisIsConnectionUpdate = Parameters.ThisIsConnectionUpdate;
	CreateConnectionOfExistingConnection = Parameters.CreateConnectionOfExistingConnection;
	
	If Not ValueIsFilled(ServiceSettings) Then
		
		ServiceSettings = Catalogs.IntegrateWithBankFeeds.FindByAttribute(
			"Service", Enums.BankFeedsServices.SaltEdge);	
	EndIf;	

	If ValueIsFilled(Organization) Then
		
		CurrentUser = Users.CurrentUser();
		
		If ValueIsFilled(CurrentUser) Then

			ContactPerson = Common.ObjectAttributeValue(CurrentUser, "Individual");
			email = ExchangeWithBankFeedsServiceServerCall.CompanySMail(Organization); 
			
		EndIf;
		
	EndIf;
	
	FillProvidersList(ProvidersList);
	ChooseProvider(NameOfProvider, ProviderID, Bank);
	
	If ValueIsFilled(Parameters.LinkToAuthorization) Then
		
		FillInAuthorizationFormOnServiceWithData(Parameters.LinkToAuthorization, 
			Parameters.FillParameters);
		
	EndIf;	
	
	FormControl();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)

	If Not ValueIsFilled(Organization) Then
		Cancel = True;
		
		Text = NStr("vi = 'Chưa điền trường ""Doanh nghiệp"".';
					|ru = 'Поле ""Организация"" не заполнено.';
					|en = 'The ""Company"" field is required.'; fa = 'The ""Company"" field is required.';
					|it = 'Поле ""Организация"" не заполнено.';
					|pl = 'The ""Company"" field is required.';
					|tr = '""İş yeri"" alanı doldurulmamış.'");
		Common.MessageToUser(
			Text,,
			"Organization",,
			Cancel);
		
	EndIf;	
	
	If Not ValueIsFilled(email) Then
		Cancel = True;
		
		Text = NStr("vi = 'Chưa điền trường ""Email xác nhận"".';
					|ru = 'Поле ""Подтвержденный email"" не заполнено.';
					|en = 'The ""Verified email"" field is required.'; fa = 'The ""Verified email"" field is required.';
					|it = 'Поле ""Подтвержденный email"" не заполнено.';
					|pl = 'The ""Verified email"" field is required.';
					|tr = '“Onaylanmış e-posta” alanı doldurulmamış.'");
		Common.MessageToUser(
			Text,,
			"email",,
			Cancel);
		
	EndIf;	
	
	ManualBankDetailsChange = False;
	If ValueIsFilled(BankAccount) Then
		ManualBankDetailsChange = 
			Common.ObjectAttributeValue(BankAccount, "ManualBankDetailsChange");
	EndIf;		
	
	If Not ValueIsFilled(Bank)
		And Not ManualBankDetailsChange Then
		
		Cancel = True;
		
		Text = NStr("vi = 'Chưa điền trường ""Ngân hàng"".';
					|ru = 'Поле ""Банк"" не заполнено.';
					|en = 'The ""Bank"" field is required.'; fa = 'The ""Bank"" field is required.';
					|it = 'Поле ""Банк"" не заполнено.';
					|pl = 'The ""Bank"" field is required.';
					|tr = '“Banka” alanı doldurulmamıştır.'");
		Common.MessageToUser(
			Text,,
			"Bank",,
			Cancel);
		
	EndIf;	
	
	If Not ValueIsFilled(ServiceSettings) Then

		Cancel = True;
		
		Text = NStr("vi = 'Chưa điền trường ""Tùy chỉnh dịch vụ"".';
					|ru = 'Поле ""Настройки сервиса"" не заполнено.';
					|en = 'The ""Service settings"" field is required.'; fa = 'The ""Service settings"" field is required.';
					|it = 'Поле ""Настройки сервиса"" не заполнено.';
					|pl = 'The ""Service settings"" field is required.';
					|tr = '“Servis ayarları” alanı doldurulmamış.'");
		Common.MessageToUser(
			Text,,
			"ServiceSettings",,
			Cancel);
		
	EndIf;	

	If Not ThisIsAddInvoiceForm And  Not ValueIsFilled(BankAccount) Then
		
		Cancel = True;
		
		Text = NStr("vi = 'Chưa điền trường ""Tài khoản ngân hàng"".';
					|ru = 'Поле ""Банковский счет"" не заполнено.';
					|en = 'The ""Bank account"" field is not filled in.'; fa = 'The ""Bank account"" field is not filled in.';
					|it = 'Поле ""Банковский счет"" не заполнено.';
					|pl = 'Pole ""Rachunek bankowy"" nie jest wypełniony.';
					|tr = '""Banka hesabı"" alanı doldurulmamış.'");
		Common.MessageToUser(
			Text,,
			"BankAccount",,
			Cancel);
		
	EndIf;	
	
	If ValueIsFilled(email)
		And Not CommonClientServer.EmailAddressMeetsRequirements(email) Then
			
		Cancel = True;
		
		Text = NStr("vi = 'Đã nhập sai trường ""Email xác nhận""';
					|ru = 'Поле ""Подтвержденный email"" введен не корректно';
					|en = 'The ""Verified email"" field is incorrect'; fa = 'The ""Verified email"" field is incorrect';
					|it = 'Поле ""Подтвержденный email"" введен не корректно';
					|pl = 'The ""Verified email"" field is incorrect';
					|tr = '“Onaylanmış e-posta” alanı doğru girilmemiş'");
		Common.MessageToUser(
			Text,,
			"email",,
			Cancel);
	
	EndIf;	
	
	If Items.ActivationPages.CurrentPage = Items.LidaRegistrationGroup Then	
		
		CheckedAttributes.Add("LastNameFirstNamePatronymicOfRegistrar");
		CheckedAttributes.Add("RegistrarSPlaceOfBirth");
		CheckedAttributes.Add("GenderOfRegistrar");
		CheckedAttributes.Add("RegistrarSCountryOfCitizenship");
		CheckedAttributes.Add("RegistrarSResidentialAddress");
		CheckedAttributes.Add("LegalNameOfCompany");
		CheckedAttributes.Add("CompanyOfficeAddress");
		CheckedAttributes.Add("CompanyIsRegisteredInCountry");
		CheckedAttributes.Add("CompanyRegistrationNumber");
		
		If Not ValueIsFilled(RegistrarSDateOfBirth) Then

			Cancel = True;
		
			Text = NStr("vi = 'Đã điền sai trường ""Ngày sinh"". Hãy chọn ngày chính xác';
						|ru = 'Поле ""Дата рождения"" заполнена некорректно. Выберите корректную дату';
						|en = 'The ""Date of birth"" field is incorrect. Select the correct date'; fa = 'The ""Date of birth"" field is incorrect. Select the correct date';
						|it = 'Поле ""Дата рождения"" заполнена некорректно. Выберите корректную дату';
						|pl = 'The ""Date of birth"" field is incorrect. Select the correct date';
						|tr = '""Doğum tarihi"" alanı doğru doldurulmamış. Doğru tarihi seçin'");
			Common.MessageToUser(
				Text,,
				"RegistrarSDateOfBirth",,
				Cancel);
		
		EndIf;	
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	If ValueIsFilled(Organization) Then
		
		email = ExchangeWithBankFeedsServiceServerCall.CompanySMail(Organization);
		
	EndIf;	
	
EndProcedure 

&AtClient
Procedure ProviderOnChange(Item)

	For Each CurCurrentProvider In ProvidersList Do
		
		If CurCurrentProvider.Presentation = NameOfProvider Then
	
			ProviderID = CurCurrentProvider.Value;
			
			Break;
			
		EndIf;	
	EndDo;	
	
EndProcedure

&AtClient
Procedure ProviderClearing(Item, StandardProcessing)
	
	ProviderID = "";
	
EndProcedure

&AtClient
Procedure BankOnChange(Item)
	
	ChooseProvider(NameOfProvider, ProviderID, Bank);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	
	AdditionalParameters = 
		New Structure("FillParameters,Form", FillParameters, ThisObject);
	
	ClosingSaltEdgeAuthorizationForm(DialogReturnCode.OK, AdditionalParameters);
		
	
EndProcedure

&AtClient
Procedure Connect(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;	

	RegistrationParameters = New Structure();
	RegistrationParameters.Insert("Organization", Organization);  
	
	If ValueIsFilled(Bank) Then
		SelectedBank = Bank;
	Else
		SelectedBank = BankAccount;
	EndIf;	
	
	RegistrationParameters.Insert("Bank", SelectedBank);
	RegistrationAttributes = ReadRegistrationDetailsOnServer(RegistrationParameters);
	
	If RegistrationAttributes.DataIsConfirmedByUser Then
	
		FillParameters = New Structure();
		FillParameters.Insert("Organization", Organization);
		FillParameters.Insert("RegistrationAttributes", RegistrationAttributes);
		FillParameters.Insert("Bank", SelectedBank);
		FillParameters.Insert("BankAccount", BankAccount);
		FillParameters.Insert("ServiceSettings", ServiceSettings);
		FillParameters.Insert("email", email);
		FillParameters.Insert("ProviderID", ProviderID);
		FillParameters.Insert("NewConnectionOnly", False);
		
		ExchangeWithBankFeedsServiceClient.EnableServiceOnClient(FillParameters, ThisObject);	
		
	Else
		
		FillPropertyValues(ThisObject, RegistrationAttributes);
		Items.ActivationPages.CurrentPage = Items.LidaRegistrationGroup;
		FormControl();
	EndIf;	
		
EndProcedure

&AtClient
Procedure Back(Command)
	
	Items.ActivationPages.CurrentPage = Items.ConnectionParameters;
	FormControl();
	
EndProcedure

&AtClient
Procedure Confirm_Data(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;	
	
	RegistrationAttributes = RegistrationAttributes();
	
	If ValueIsFilled(Bank) Then
		SelectedBank = Bank;
	Else
		SelectedBank = BankAccount;
	EndIf;	
	
	FillParameters = New Structure();
	FillParameters.Insert("Organization", Organization);
	FillParameters.Insert("RegistrationAttributes", RegistrationAttributes);
	FillParameters.Insert("Bank", SelectedBank);
	FillParameters.Insert("BankAccount", BankAccount);
	FillParameters.Insert("ServiceSettings", ServiceSettings);
	FillParameters.Insert("email", email);
	FillParameters.Insert("ProviderID", ProviderID);
	FillParameters.Insert("NewConnectionOnly", False);
	
	ExchangeWithBankFeedsServiceClient.EnableServiceOnClient(FillParameters, ThisObject);	
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function ReadRegistrationDetailsOnServer(FillParameters)
	
	Return ExchangeWithBankFeedsServer.ReadRegistrationDetailsOnServer(FillParameters);
	
EndFunction	

&AtClient
Function RegistrationAttributes()

 AttributesSet = New Structure();	

 AttributesSet.Insert("RegistrarSResidentialAddress", RegistrarSResidentialAddress);
 AttributesSet.Insert("RegistrarSDateOfBirth", RegistrarSDateOfBirth);
 AttributesSet.Insert("RegistrarSCountryOfCitizenship", RegistrarSCountryOfCitizenship);
 AttributesSet.Insert("LastNameFirstNamePatronymicOfRegistrar", LastNameFirstNamePatronymicOfRegistrar);
 AttributesSet.Insert("RegistrarSPlaceOfBirth", RegistrarSPlaceOfBirth);  
 AttributesSet.Insert("GenderOfRegistrar", GenderOfRegistrar);  
 AttributesSet.Insert("DataIsConfirmedByUser", True);  

 AttributesSet.Insert("CompanyOfficeAddress", CompanyOfficeAddress);
 AttributesSet.Insert("CompanyIsRegisteredInCountry", CompanyIsRegisteredInCountry);
 AttributesSet.Insert("CompanyRegistrationNumber", CompanyRegistrationNumber);
 AttributesSet.Insert("LegalNameOfCompany", LegalNameOfCompany);
 
 Return AttributesSet;
 
EndFunction

&AtServer
Procedure FormControl()
	
	If ThisIsAddInvoiceForm Then	
		
		Title = NStr("vi = 'Thêm tài khoản ngân hàng từ';
					|ru = 'Добавить банковские счета из';
					|en = 'Add bank accounts from'; fa = 'Add bank accounts from';
					|it = 'Добавить банковские счета из';
					|pl = 'Add bank accounts from';
					|tr = 'Banka hesaplarını şuradan ekleyin'") + " BankFeeds";
		Items.Connect.Title = NStr("vi = 'Tìm kiếm tài khoản ngân hàng';
									|ru = 'Найти банковские счета';
									|en = 'Search for bank accounts'; fa = 'Search for bank accounts';
									|it = 'Найти банковские счета';
									|pl = 'Search for bank accounts';
									|tr = 'Banka hesaplarını bulun'");
		
	EndIf;	

	If Items.ActivationPages.CurrentPage = Items.LidaRegistrationGroup Then

		Items.Confirm_Data.DefaultButton = True;
		
	ElsIf Items.ActivationPages.CurrentPage = Items.ConnectionParameters Then	

		Items.Connect.DefaultButton = True; 
		
		Items.BankAccount.Visible = ValueIsFilled(BankAccount);
	
		Items.Bank.ReadOnly = Not ThisIsAddInvoiceForm;
		Items.Organization.ReadOnly = Not ThisIsAddInvoiceForm;
	
		For Each CurCurrentProvider In ProvidersList Do
			Items.Provider.ChoiceList.Add(CurCurrentProvider.Presentation);
		EndDo;
		
	EndIf;	
	
	If ValueIsFilled(BankAccount) Then 
		ManualBankDetailsChange = 
			Common.ObjectAttributeValue(BankAccount, "ManualBankDetailsChange");
		If ManualBankDetailsChange Then
		
			Items.Bank.AutoMarkIncomplete = False;
		
		EndIf;
	EndIf;
	
	If Not Constants.UseMultipleCompanies.Get() Then
		
		Items.Organization.ReadOnly = False;
		
	EndIf;	
	
EndProcedure	

&AtServer
Procedure FillInAuthorizationFormOnServiceWithData(LinkToAuthorizationInService, RequestFillingParameters) Export
	
	LinkToAuthorization = LinkToAuthorizationInService;
	FillParameters = RequestFillingParameters;
	
	CurCurrentProvider = Common.ObjectAttributeValue(FillParameters.ServiceSettings, "Service");
	
	Items.DecorationDescriptionOfAuthorization.Title = StringFunctions.FormattedString(
	   	 NStr("vi = 'Vui lòng thực hiện các thao tác sau để đăng nhập vào ngân hàng của bạn
					|1. Mở <a href = ""%1"">liên kết đăng nhập </a> và chuyển đến đăng nhập vào trang web của dịch vụ: %2.
					|2. Sau khi đăng nhập thành công, hãy quay lại màn hình này và nhấn nút Đồng ý.';
					|ru = 'Пожалуйста, выполните следующие действия для авторизации в вашем банке
					|1. Откройте <a href = ""%1"">ссылку на авторизацию </a> и пройдите авторизацию на сайте сервиса: %2.
					|2. После успешной авторизации вернитесь на этот экран и нажмите OK.';
					|en = 'Please follow these steps to sign in to your bank
					|1. Open <a href = ""%1"">the authorization link </a> and sign in to the service website: %2.
					|2. After successful authorization, get back to this screen and click OK.'; fa = 'Please follow these steps to sign in to your bank
					|1. Open <a href = ""%1"">the authorization link </a> and sign in to the service website: %2.
					|2. After successful authorization, get back to this screen and click OK.';
					|it = 'Пожалуйста, выполните следующие действия для авторизации в вашем банке
					|1. Откройте <a href = ""%1"">ссылку на авторизацию </a> и пройдите авторизацию на сайте сервиса: %2.
					|2. После успешной авторизации вернитесь на этот экран и нажмите OK.';
					|pl = 'Please follow these steps to sign in to your bank
					|1. Open <a href = ""%1"">the authorization link </a> and sign in to the service website: %2.
					|2. After successful authorization, get back to this screen and click OK.';
					|tr = 'Bankanıza giriş yapmak için lütfen aşağıdaki adımları izleyin
					|1. <a href = ""%1""> yetkilendirme bağlantısını açın </a> ve hizmetin web sitesinde yetkilendirmeyi geçin: %2.
					|2. Yetkilendirme başarılı olduktan sonra bu ekrana dönün ve Tamam''a basın.'"),
	
		LinkToAuthorization, CurCurrentProvider);
		
	Items.ActivationPages.CurrentPage = Items.AuthorizationInService;
	Items.OK.DefaultButton = True;
	
EndProcedure	

&AtClient
Procedure ClosingSaltEdgeAuthorizationForm(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillParameters = AdditionalParameters.FillParameters; 
	Form = AdditionalParameters.Form;
	
	If Result = DialogReturnCode.OK Then
		
		If ThisIsAddInvoiceForm Then

			TimeConsumingOperation = 
					ExchangeWithBankFeedsServiceServerCall.FillInParametersOfBackgroundTaskForConnectingToService(
										AdditionalParameters.Form.UUID, FillParameters);
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
			IdleParameters.OutputIdleWindow = True;
			IdleParameters.OutputProgressBar = True;
			IdleParameters.OutputMessages = False;
			IdleParameters.MessageText = NStr("vi = 'Kết nối đến dịch vụ';
												|ru = 'Подключение к сервису';
												|en = 'Connection to service'; fa = 'Connection to service';
												|it = 'Подключение к сервису';
												|pl = 'Connection to service';
												|tr = 'Servise bağlanma'");
			IdleParameters.UserNotification.Show = False;
			IdleParameters.UserNotification.Explanation = NStr("vi = 'Đã kết nối dịch vụ';
																|ru = 'Сервис подключен';
																|en = 'The service is connected'; fa = 'The service is connected';
																|it = 'Сервис подключен';
																|pl = 'The service is connected';
																|tr = 'Servis bağlantılı'");
			IdleParameters.UserNotification.Text = "BankFeeds";
			
			CallbackOnCompletion = New CallbackDescription("EndingConnectionToReadAccountsService",
																						Form, AdditionalParameters);
			TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);

		ElsIf ThisIsConnectionUpdate Then 	
			
			TimeConsumingOperation = 
				ExchangeWithBankFeedsServiceServerCall.FillInParametersOfBackgroundTaskForCheckingConnectionUpdateToService(
										AdditionalParameters.Form.UUID, FillParameters);
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
			IdleParameters.OutputIdleWindow = True;
			IdleParameters.OutputProgressBar = True;
			IdleParameters.OutputMessages = True;
			IdleParameters.MessageText = NStr("vi = 'Cập nhật kết nối dịch vụ';
												|ru = 'Обновление соединения сервиса';
												|en = 'Service connection update'; fa = 'Service connection update';
												|it = 'Обновление соединения сервиса';
												|pl = 'Service connection update';
												|tr = 'Servis bağlantısının güncellenmesi'");
			IdleParameters.UserNotification.Show = True;
			IdleParameters.UserNotification.Explanation = NStr("vi = 'Đã cập nhật kết nối';
																|ru = 'Соединение обновлено';
																|en = 'Connection is updated'; fa = 'Connection is updated';
																|it = 'Соединение обновлено';
																|pl = 'Connection is updated';
																|tr = 'Bağlantı güncellendi'");
			IdleParameters.UserNotification.Text = "BankFeeds";
			
			AdditionalParameters = New Structure();
			
			CallbackOnCompletion = New CallbackDescription("EndingServiceConnectionUpdate", 
																					Form, AdditionalParameters);
			TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
			
		Else
			TimeConsumingOperation = 
						ExchangeWithBankFeedsServiceServerCall.FillInParametersOfBackgroundTaskForConnectingToService(
										AdditionalParameters.Form.UUID, FillParameters);
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
			IdleParameters.OutputIdleWindow = True;
			IdleParameters.OutputProgressBar = True;
			IdleParameters.OutputMessages = True;
			IdleParameters.MessageText = NStr("vi = 'Kết nối đến dịch vụ';
												|ru = 'Подключение к сервису';
												|en = 'Connection to service'; fa = 'Connection to service';
												|it = 'Подключение к сервису';
												|pl = 'Connection to service';
												|tr = 'Servise bağlanma'");
			IdleParameters.UserNotification.Show = True;
			IdleParameters.UserNotification.Explanation = NStr("vi = 'Đã kết nối dịch vụ';
																|ru = 'Сервис подключен';
																|en = 'The service is connected'; fa = 'The service is connected';
																|it = 'Сервис подключен';
																|pl = 'The service is connected';
																|tr = 'Servis bağlantılı'");
			IdleParameters.UserNotification.Text = "BankFeeds";
			
			AdditionalParameters = New Structure();
			
			CallbackOnCompletion = New CallbackDescription("EndingConnectionToService", Form, AdditionalParameters);
			TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
			
		EndIf;
	EndIf;	

EndProcedure	

&AtClient
Procedure EndingConnectionToReadAccountsService(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillParameters = AdditionalParameters.FillParameters; 
	
	ExchangeWithBankFeedsServiceClient.ReadCompanySInvoicesInService(FillParameters, ThisObject);	
	
EndProcedure	

&AtClient
Procedure EndingServiceConnectionUpdate(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ResultOfResponseFromService = GetFromTempStorage(Result.ResultAddress);
	
	If Result.Status = "Error" Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lỗi kết nối theo doanh nghiệp %1, đến ngân hàng %2. Chưa cập nhật';
				|ru = 'Ошибка подключения по организации %1, к банку %2. Обновление не выполнено';
				|en = 'An error occurred when connecting to the %2 bank for the %1 company. Update failed'; fa = 'An error occurred when connecting to the %2 bank for the %1 company. Update failed';
				|it = 'Ошибка подключения по организации %1, к банку %2. Обновление не выполнено';
				|pl = 'An error occurred when connecting to the %2 bank for the %1 company. Update failed';
				|tr = 'Kuruluş %1 tarafından banka %2''ye bağlantı hatası. Güncelleme gerçekleştirilmedi'"),
			Organization, Bank);
		CommonClient.MessageToUser(MessageText);
		
	ElsIf ResultOfResponseFromService.ResponseStatus = ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses().NoResponseReceived Then
		
		For Each CurrentError In ResultOfResponseFromService.ErrorsArray Do
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi: %1. Chưa cập nhật kết nối';
					|ru = 'Ошибка: %1. Обновление соединения не выполнено';
					|en = 'Error: %1. Connection update failed'; fa = 'Error: %1. Connection update failed';
					|it = 'Ошибка: %1. Обновление соединения не выполнено';
					|pl = 'Error: %1. Connection update failed';
					|tr = 'Hata: %1. Bağlantı güncellemesi başarısız oldu'"), CurrentError);
			CommonClient.MessageToUser(MessageText);
			
		EndDo;	
		
	ElsIf ResultOfResponseFromService.ResponseStatus = ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses().IsAnswered Then

		Close("Join attached");
		
	Else
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lỗi kết nối theo doanh nghiệp %1, đến ngân hàng %2. Chưa cập nhật';
				|ru = 'Ошибка подключения по организации %1, к банку %2. Обновление не выполнено';
				|en = 'An error occurred when connecting to the %2 bank for the %1 company. Update failed'; fa = 'An error occurred when connecting to the %2 bank for the %1 company. Update failed';
				|it = 'Ошибка подключения по организации %1, к банку %2. Обновление не выполнено';
				|pl = 'An error occurred when connecting to the %2 bank for the %1 company. Update failed';
				|tr = 'Kuruluş %1 tarafından banka %2''ye bağlantı hatası. Güncelleme gerçekleştirilmedi'"),
			Organization, Bank);
		CommonClient.MessageToUser(MessageText);
		
	EndIf;	
		
EndProcedure

&AtClient
Procedure EndingConnectionToService(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ResultOfResponseFromService = GetFromTempStorage(Result.ResultAddress);
	
	If Result.Status = "Error" Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lỗi kết nối theo doanh nghiệp %1, đến ngân hàng %2. Chưa cập nhật';
				|ru = 'Ошибка подключения по организации %1, к банку %2. Обновление не выполнено';
				|en = 'An error occurred when connecting to the %2 bank for the %1 company. Update failed'; fa = 'An error occurred when connecting to the %2 bank for the %1 company. Update failed';
				|it = 'Ошибка подключения по организации %1, к банку %2. Обновление не выполнено';
				|pl = 'An error occurred when connecting to the %2 bank for the %1 company. Update failed';
				|tr = 'Kuruluş %1 tarafından banka %2''ye bağlantı hatası. Güncelleme gerçekleştirilmedi'"),
			Organization, Bank);
		CommonClient.MessageToUser(MessageText);
		
	ElsIf ResultOfResponseFromService.ResponseStatus = ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses().NoResponseReceived Then
		
		For Each CurrentError In ResultOfResponseFromService.ErrorsArray Do
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Lỗi: %1. Chưa kêt nối tài khoản';
					|ru = 'Ошибка: %1. Подключение счета не выполнено';
					|en = 'Error: %1. Account connection failed'; fa = 'Error: %1. Account connection failed';
					|it = 'Ошибка: %1. Подключение счета не выполнено';
					|pl = 'Error: %1. Account connection failed';
					|tr = 'Hata: %1. Hesap bağlantısı tamamlanmadı'"), CurrentError);
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
				Organization, Bank);
			ShowUserNotification(NStr("vi = 'Kết nối đến dịch vụ';
										|ru = 'Подключение к сервису';
										|en = 'Connection to service'; fa = 'Connection to service';
										|it = 'Подключение к сервису';
										|pl = 'Connection to service';
										|tr = 'Servise bağlanma'"),,MessageText,,UserNotificationStatus.Important);

		ElsIf CreateConnectionOfExistingConnection Then
			
			Close();
		
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã kết nối theo doanh nghiệp %1, đến ngân hàng %2.';
					|ru = 'Подключение по организации %1, к банку %2 выполнено.';
					|en = 'Connection to the %2 bank for the %1 company is completed.'; fa = 'Connection to the %2 bank for the %1 company is completed.';
					|it = 'Подключение по организации %1, к банку %2 выполнено.';
					|pl = 'Connection to the %2 bank for the %1 company is completed.';
					|tr = 'Organizasyon %1 tarafından banka %2''ye bağlantı yapıldı.'"),
				Organization, Bank);
			
			ShowUserNotification(NStr("vi = 'Kết nối đến dịch vụ';
										|ru = 'Подключение к сервису';
										|en = 'Connection to service'; fa = 'Connection to service';
										|it = 'Подключение к сервису';
										|pl = 'Connection to service';
										|tr = 'Servise bağlanma'"),,MessageText,,UserNotificationStatus.Important);
		Else
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa kết nối theo doanh nghiệp %1, đến ngân hàng %2. Không tìm thấy tài khoản';
					|ru = 'Подключение по организации %1, к банку %2 не выполнено. Не найден счет';
					|en = 'Connection to the %2 bank for the %1 company failed. The account is not found'; fa = 'Connection to the %2 bank for the %1 company failed. The account is not found';
					|it = 'Подключение по организации %1, к банку %2 не выполнено. Не найден счет';
					|pl = 'Connection to the %2 bank for the %1 company failed. The account is not found';
					|tr = 'Kuruluş %1 tarafından %2 bankasına bağlantı gerçekleştirilmedi. Hesap bulunamadı'"),
				Organization, Bank);
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
			Organization, Bank);
		CommonClient.MessageToUser(MessageText);
		
	EndIf;	
		
EndProcedure

&AtServerNoContext
Procedure FillProvidersList(ProvidersList)

	Query = New Query();
	Query.Text = 
	"SELECT
	|	ConnectionsToBankFeedsBanks.NameOfProvider AS NameOfProvider,
	|	ConnectionsToBankFeedsBanks.ProviderID AS ProviderID
	|FROM
	|	InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|
	|GROUP BY
	|	ConnectionsToBankFeedsBanks.NameOfProvider,
	|	ConnectionsToBankFeedsBanks.ProviderID";
	
	Result = Query.Execute().Select();
	
	While Result.Next() Do 
		
		If Not ValueIsFilled(Result.ProviderID)
			Or  Not ValueIsFilled(Result.NameOfProvider) Then
			Continue;
		EndIf;	
		
		ProvidersList.Add(Result.ProviderID, Result.NameOfProvider); 
		
	EndDo;	
	
EndProcedure

&AtServerNoContext
Procedure ChooseProvider(NameOfProvider, ProviderID, Bank)
	
	NameOfProvider = "";
	ProviderID = "";
	
	Query = New Query();
	Query.SetParameter("Bank", Bank);
	Query.Text = 
	"SELECT
	|	ConnectionsToBankFeedsBanks.ProviderID AS ProviderID,
	|	ConnectionsToBankFeedsBanks.NameOfProvider AS NameOfProvider
	|FROM
	|	InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|WHERE
	|	ConnectionsToBankFeedsBanks.Bank = &Bank";
	
	Result = Query.Execute().Select();
	If Result.Next() Then
		
		If Not ValueIsFilled(Result.ProviderID) 
			Or Not ValueIsFilled(Result.NameOfProvider) Then
			Return;
		EndIf;	
		
		NameOfProvider = Result.NameOfProvider;
		ProviderID = Result.ProviderID;
		
	EndIf;	
	
EndProcedure	

#EndRegion














