////////////////////////////////////////////////////////////////////////////////
// Exchange servicebankfeeds Client: list of functions on the client
//
////////////////////////////////////////////////////////////////////////////////

#Region Internal

#Region SyncingBankFeeds                  

// Called when syncing BankFeeds.
// Transactions are automatically loaded and payment orders are unloaded.
//
// Parameters:
//  Form - ClientApplicationForm
//  BeginOfPeriod - Date
//  EndOfPeriod - Date
//
Procedure SyncBankFeeds(Form, BeginOfPeriod,EndOfPeriod) Export    
	
	If ValueIsFilled(Form.BankAccountSelection) Then 
		
		BankAccountIsConnectedToService = TestServiceConnection(Form.BankAccountSelection);
		
		If Not BankAccountIsConnectedToService Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					 NStr("vi = 'Tài khoản ngân hàng %1 chưa được kết nối đến';
							|ru = 'Банковский счет %1 не подключен к';
							|en = 'The %1 bank account is not connected to'; fa = 'The %1 bank account is not connected to';
							|it = 'Банковский счет %1 не подключен к';
							|pl = 'The %1 bank account is not connected to';
							|tr = 'Banka hesabı %1''e bağlı değil'") + " BankFeeds", Form.BankAccountSelection);
			
			ShowMessageBox(,MessageText);
			
			Return;
			
		EndIf;
		
	EndIf;

	ImportParameters = New Structure();
	ImportParameters.Insert("BankAccountAddress", "");
	ImportParameters.Insert("StartDate", BeginOfPeriod);
	ImportParameters.Insert("EndDate", EndOfPeriod);
	ImportParameters.Insert("CreateCounterparties", True);
	ImportParameters.Insert("PostDocuments", True);     
	ImportParameters.Insert("BankAccount", Form.BankAccountSelection);     
	ImportParameters.Insert("DownloadIsPerformedWhenSyncing", True);
	ImportParameters.Insert("ArticlesOfCashFlowOfOperations", Undefined);

	DownloadTransactions(ImportParameters, Form);	
	
EndProcedure

#EndRegion

#Region ReadBankAccountsInService

// Called when the company's invoices are read in the service Command
//
// Parameters:
//  FillParameters - Structure - The fill parameters
//  Form - ClientApplicationForm
//
Procedure ReadCompanySInvoicesInService(FillParameters, Form) Export

	TimeConsumingOperation = ExchangeWithBankFeedsServiceServerCall.FillInParametersOfBackgroundTaskReadInvoicesForOrganization(
		Form.UUID, FillParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = False;
	IdleParameters.MessageText = NStr("vi = 'Đọc tài khoản ngân hàng theo doanh nghiệp';
										|ru = 'Прочитать банковские счета по организации';
										|en = 'Read bank accounts of the company'; fa = 'Read bank accounts of the company';
										|it = 'Прочитать банковские счета по организации';
										|pl = 'Read bank accounts of the company';
										|tr = 'Banka hesaplarını kuruluşa göre okuma'") + " BankFeeds";
	IdleParameters.UserNotification.Show = False;
	IdleParameters.UserNotification.Explanation = NStr("vi = 'Hóa đơn đã đọc';
														|ru = 'Счета прочитаны';
														|en = 'Bank accounts are read'; fa = 'Bank accounts are read';
														|it = 'Счета прочитаны';
														|pl = 'Bank accounts are read';
														|tr = 'Faturalar okundu'");
	IdleParameters.UserNotification.Text = "BankFeeds";
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("Organization", FillParameters.Organization);
	
	CallbackOnCompletion = New CallbackDescription("EndOfReadingBankAccountsForCompanyInService",
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

// Called when the company's invoices are read in the service Command
//
// Parameters:
//  Result - Structure - The fill parameters
//  AdditionalParameters - Structure - advanced setting
//
Procedure EndOfReadingBankAccountsForCompanyInService(Result, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	
	HandlerNotifications = New CallbackDescription("AfterAddingAccountsFromBankFeeds", ThisObject, AdditionalParameters);
	
	If Result.Status = "Error" Then
		
		MessageText = NStr("vi = 'Lỗi thêm hóa đơn mới';
							|ru = 'Ошибка добавления нового счета';
							|en = 'Error adding a new account'; fa = 'Error adding a new account';
							|it = 'Ошибка добавления нового счета';
							|pl = 'Error adding a new account';
							|tr = 'Yeni hesap eklerken hata oluştu'");
		CommonClient.MessageToUser(MessageText);
		
	Else
		
		OpenForm("CommonForm.BankFeedsAccountTable",
			New Structure("BankAccount, ResultOfResponseFromService", Form.BankAccount, Result),
			Form,,,,HandlerNotifications, FormWindowOpeningMode.LockOwnerWindow);
			
	EndIf;
		
EndProcedure

// Called after adding accounts to the program from the Bank Feeds Service 
//
// Parameters:
//  Result - Structure - The fill parameters
//  Parameters - Structure - Parameters 
//
Procedure AfterAddingAccountsFromBankFeeds(Result, Parameters) Export

	Form = Parameters.Form;

	Form.Close(Result);
	
EndProcedure

#EndRegion 

#Region StateOfPaymentDocument

// Called when you click on the button in the Payment document 
//
// Parameters:
//  DocumentRef - DocumentRef - link to the document
//  Form - ClientApplicationForm
//  StandardProcessing - Boolean - 
//
Procedure ProcessClickingOnStateOfDocument(DocumentRef, Form, StandardProcessing) Export
	
	If Form.StateOfBankFeeds <> "Conducted" Then
		
		StandardProcessing = False;
		OpenBankClientForm(DocumentRef, Form);

	EndIf;	
	
EndProcedure

#EndRegion 

#Region ConnectionCheckUp

// Called to verify connection to the service 
//
// Parameters:
//  FillParameters - DocumentRef - link to the document
//  Form - ClientApplicationForm - Form
//
Procedure CheckServiceConnection(FillParameters, Form) Export

	TimeConsumingOperation = ExchangeWithBankFeedsServiceServerCall.FillInParametersOfBackgroundTaskForCheckingConnection(
		Form.UUID, FillParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = False;
	IdleParameters.MessageText = NStr("vi = 'Kiểm tra tùy chỉnh kết nối';
										|ru = 'Проверка настроек подключения';
										|en = 'Check connection settings'; fa = 'Check connection settings';
										|it = 'Проверка настроек подключения';
										|pl = 'Check connection settings';
										|tr = 'Bağlantı ayarlarının kontrolü'") + " BankFeeds";
	IdleParameters.UserNotification.Show = False;
	IdleParameters.UserNotification.Explanation = NStr("vi = 'Đã kiểm tra kết nối thành công';
														|ru = 'Проверка подключения успешна';
														|en = 'Connection test succeeded'; fa = 'Connection test succeeded';
														|it = 'Проверка подключения успешна';
														|pl = 'Connection test succeeded';
														|tr = 'Bağlantı kontrolü başarılı'");
	IdleParameters.UserNotification.Text = "BankFeeds";
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("FillParameters", FillParameters);
	
	CallbackOnCompletion = New CallbackDescription("EndOfBankFeedsConnectionCheck", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);

	
EndProcedure

// Called when the user's authorization on the service form Ends
// 
// Parameters:
//   Result - Structure - result parameters
//   AdditionalParameters - Structure - advanced setting
//
Procedure EndOfBankFeedsConnectionCheck(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
		
	Else 
		ResultOfResponseFromService = GetFromTempStorage(Result.ResultAddress);
		
		If ResultOfResponseFromService.ResponseStatus = ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses().IsAnswered Then
			
			MessageText = NStr("vi = 'Kết nối thành công!';
								|ru = 'Соединение устанавливается успешно!';
								|en = 'Connection is successful.'; fa = 'Connection is successful.';
								|it = 'Соединение устанавливается успешно!';
								|pl = 'Connection is successful.';
								|tr = 'Bağlantı başarıyla kuruldu!'");   
			
			ShowUserNotification(MessageText,,,,UserNotificationStatus.Important);
			
		Else 
			
			CommonClient.MessageToUser(NStr("vi = 'Connection check failed';
											|ru = 'Connection check failed';
											|en = 'Connection check failed'; fa = 'Connection check failed';
											|it = 'Connection check failed';
											|pl = 'Connection check failed';
											|tr = 'Connection check failed'"));
			
			For Each CurrentError In ResultOfResponseFromService.ErrorsArray Do
			
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Lỗi: %1';
						|ru = 'Ошибка: %1';
						|en = 'Error: %1'; fa = 'Error: %1';
						|it = 'Ошибка: %1';
						|pl = 'Error: %1';
						|tr = 'Hata: %1'"), CurrentError);
				CommonClient.MessageToUser(MessageText);
			
			EndDo;	
			
		EndIf;	 
		
	EndIf;	
	
EndProcedure
	
#EndRegion 

#Region ConnectingToService

// Starts the procedure for connecting to the service in the background
// 
// Parameters:
//   FillParameters - Structure - The fill parameters
//  Form - ClientApplicationForm - Form
//
Procedure EnableServiceOnClient(FillParameters, Form) Export

	TimeConsumingOperation = ExchangeWithBankFeedsServiceServerCall.FillInParametersOfBackgroundTaskForUserAuthorization(
		Form.UUID, FillParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = True;
	IdleParameters.MessageText = NStr("vi = 'Cài đặt kết nối với';
										|ru = 'Установка соединения с';
										|en = 'Connecting with'; fa = 'Connecting with';
										|it = 'Установка соединения с';
										|pl = 'Nawiązanie połączenia z';
										|tr = '... ile bağlanıyor'") + " BankFeeds";
	IdleParameters.UserNotification.Show = False;
	IdleParameters.UserNotification.Explanation = NStr("vi = 'Kết nối đăng nhập';
														|ru = 'Подключение к авторизации';
														|en = 'Connection to authorization'; fa = 'Connection to authorization';
														|it = 'Подключение к авторизации';
														|pl = 'Connection to authorization';
														|tr = 'Yetkilendirme bağlantısı'") + " BankFeeds";
	IdleParameters.UserNotification.Text = "BankFeeds";
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("FillParameters", FillParameters);
	
	CallbackOnCompletion = New CallbackDescription("EndOfUserAuthorizationOnService", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

// Called when the user's authorization on the service form Ends
// 
// Parameters:
//   Result - Structure - result parameters
//   AdditionalParameters - Structure - advanced setting
//
Procedure EndOfUserAuthorizationOnService(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	Else 
		ResultOfResponseFromService = GetFromTempStorage(Result.ResultAddress);
		FillParameters = AdditionalParameters.FillParameters;
		Form = AdditionalParameters.Form;
		
		If ResultOfResponseFromService.ResponseStatus = ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses().IsAnswered Then
			
			Form.FillInAuthorizationFormOnServiceWithData(
										ResultOfResponseFromService.LinkToAuthorization, FillParameters);	
			
		ElsIf ResultOfResponseFromService.ResponseStatus = 
				ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses().RequestIsNotNeededDataIsReady Then 
			
			Form.ClosingSaltEdgeAuthorizationForm(DialogReturnCode.OK, AdditionalParameters);
			
		Else 
			
			CommonClient.MessageToUser(NStr("vi = 'Chưa thực hiện đăng nhập ngân hàng';
											|ru = 'Авторизация банка не выполнена';
											|en = 'Bank authorization failed'; fa = 'Bank authorization failed';
											|it = 'Авторизация банка не выполнена';
											|pl = 'Bank authorization failed';
											|tr = 'Banka yetkilendirmesi başarısız oldu'"));
			
			For Each CurrentError In ResultOfResponseFromService.ErrorsArray Do
			
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Lỗi: %1';
						|ru = 'Ошибка: %1';
						|en = 'Error: %1'; fa = 'Error: %1';
						|it = 'Ошибка: %1';
						|pl = 'Error: %1';
						|tr = 'Hata: %1'"), CurrentError);
				CommonClient.MessageToUser(MessageText);
			
			EndDo;	
			
		EndIf;	 
		
		Notify("UpdateFormForBankConnectionListBankFeeds",, ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion 

#Region ConnectionStatusUpdate

// Checks the Status of the connection and consent on the service
// 
// Parameters:
//   FillParameters - Structure - The fill parameters
//  Form - ClientApplicationForm - Form
//
Procedure CheckStatusOfConnectionAndConsentOfServiceOnClient(FillParameters, Form) Export
	
	TimeConsumingOperation = ExchangeWithBankFeedsServiceServerCall.FillInParametersOfBackgroundTaskToCheckStatusOfConnectionAndConsent(
		Form.UUID, FillParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.OutputProgressBar = False;
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("FillParameters", FillParameters);
	
	CallbackOnCompletion = New CallbackDescription("EndOfVerificationOfConnectionStatusAndServiceConsent", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure	

// Called at the End of the connection Status check and consent on the form 
// 
// Parameters:
//   Result - Structure - result parameters
//   AdditionalParameters - Structure - advanced setting
//
Procedure EndOfVerificationOfConnectionStatusAndServiceConsent(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	Else 
		ResultOfResponseFromService = GetFromTempStorage(Result.ResultAddress);
		Form = AdditionalParameters.Form;
		
		If ResultOfResponseFromService.ResponseStatus = ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses().IsAnswered Then
			
			Form.ConnectionInfo = ResultOfResponseFromService.ConnectionInfo;
			Form.StatusesAreBeingChecked = False; 
			Form.ConnectionAndAgreementAreActive =  
				ResultOfResponseFromService.ConnectionIsActive And ResultOfResponseFromService.ConnectionIsActive;
			Form.FormControl();
			
		Else 
			
			Form.ConnectionInfo = ResultOfResponseFromService.ConnectionInfo;
			Form.StatusesAreBeingChecked = False; 
			Form.ConnectionAndAgreementAreActive =  
				ResultOfResponseFromService.ConnectionIsActive And ResultOfResponseFromService.ConnectionIsActive;
			Form.FormControl();
			
			CommonClient.MessageToUser(NStr("vi = 'Chưa kiểm tra trạng thái kết nối và thống nhất';
											|ru = 'Проверка статуса соединения и согласия не выполнена';
											|en = 'Connection status and consent check failed'; fa = 'Connection status and consent check failed';
											|it = 'Проверка статуса соединения и согласия не выполнена';
											|pl = 'Connection status and consent check failed';
											|tr = 'Bağlantı durumu ve onay kontrolü gerçekleştirilmedi'"));
			
			For Each CurrentError In ResultOfResponseFromService.ErrorsArray Do
			
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Lỗi: %1';
						|ru = 'Ошибка: %1';
						|en = 'Error: %1'; fa = 'Error: %1';
						|it = 'Ошибка: %1';
						|pl = 'Error: %1';
						|tr = 'Hata: %1'"), CurrentError);
				CommonClient.MessageToUser(MessageText);
			
			EndDo;	
			
		EndIf;	 
			
	EndIf;	
			
EndProcedure			

#EndRegion 

#Region ConnectionUpdate

// Starts the connection update procedure on the service in the background
// 
// Parameters:
//   FillParameters - Structure - The fill parameters
//  Form - ClientApplicationForm - Form
//
Procedure UpdateServiceConnectionOnClient(FillParameters, Form) Export
	
	TimeConsumingOperation = ExchangeWithBankFeedsServiceServerCall.FillInParametersOfBackgroundConnectionUpdateTask(
		Form.UUID, FillParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = True;
	IdleParameters.MessageText = NStr("vi = 'Cập nhật kết nối';
										|ru = 'Обновление соединения';
										|en = 'Connection update'; fa = 'Connection update';
										|it = 'Обновление соединения';
										|pl = 'Connection update';
										|tr = 'Bağlantının yenilenmesi'") + " BankFeeds";
	IdleParameters.UserNotification.Show = True;
	IdleParameters.UserNotification.Explanation = NStr("vi = 'Cập nhật kết nối';
														|ru = 'Обновление соединения';
														|en = 'Connection update'; fa = 'Connection update';
														|it = 'Обновление соединения';
														|pl = 'Connection update';
														|tr = 'Bağlantının yenilenmesi'") + " BankFeeds";
	IdleParameters.UserNotification.Text = "BankFeeds";
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("FillParameters", FillParameters);
	
	CallbackOnCompletion = New CallbackDescription("EndOfServiceConnectionUpdate", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure	

// Called when the connection update on the service form Ends
// 
// Parameters:
//   Result - Structure - result parameters
//   AdditionalParameters - Structure - advanced setting
//
Procedure EndOfServiceConnectionUpdate(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	Else 
		ResultOfResponseFromService = GetFromTempStorage(Result.ResultAddress);
		FillParameters = AdditionalParameters.FillParameters;
		
		If ResultOfResponseFromService.ResponseStatus = ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses().IsAnswered Then
			
			HandlerNotifications = New CallbackDescription("AfterUpdatingBankFeedsConnection", 
																				ThisObject, AdditionalParameters);
		
			FormParameters = New Structure;
			FormParameters.Insert("Organization", FillParameters.Organization);
			FormParameters.Insert("Bank", FillParameters.Bank);
			FormParameters.Insert("ThisIsConnectionUpdate", True);
			FormParameters.Insert("LinkToAuthorization", ResultOfResponseFromService.LinkToConnectionUpdate);
			FormParameters.Insert("FillParameters", FillParameters);
	
			OpenForm("InformationRegister.ConnectionsToBankFeedsBanks.Form.ConnectionForm", FormParameters, , , , ,
				HandlerNotifications);
			
		Else 
			
			CommonClient.MessageToUser(NStr("vi = 'Chưa thực hiện đăng nhập ngân hàng';
											|ru = 'Авторизация банка не выполнена';
											|en = 'Bank authorization failed'; fa = 'Bank authorization failed';
											|it = 'Авторизация банка не выполнена';
											|pl = 'Bank authorization failed';
											|tr = 'Banka yetkilendirmesi başarısız oldu'"));
			
			For Each CurrentError In ResultOfResponseFromService.ErrorsArray Do
			
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Lỗi: %1';
						|ru = 'Ошибка: %1';
						|en = 'Error: %1'; fa = 'Error: %1';
						|it = 'Ошибка: %1';
						|pl = 'Error: %1';
						|tr = 'Hata: %1'"), CurrentError);
				CommonClient.MessageToUser(MessageText);
			
			EndDo;	
			
		EndIf;	 
			
	EndIf;	
			
EndProcedure			

// Called at the End of connection verification on the service form
// 
// Parameters:
//   Result - Structure - result parameters
//   AdditionalParameters - Structure - advanced setting
//
Procedure AfterUpdatingBankFeedsConnection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Form = AdditionalParameters.Form;
	
	If Result <> Undefined 
		And Result = "Join attached" Then
			Form.StartCheckingStatusOfConnectionAndConsent();
	EndIf;	
	
EndProcedure

#EndRegion 

#Region RevocationOfConsent

Procedure RevokeConsentToConnectServiceOnClient(FillParameters, Form) Export
	
	TimeConsumingOperation = ExchangeWithBankFeedsServiceServerCall.FillInParametersOfBackgroundTaskForRevocationOfConsent(
		Form.UUID, FillParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = True;
	IdleParameters.MessageText = NStr("vi = 'Thu hồi đồng ý';
										|ru = 'Отзыв согласия';
										|en = 'Consent revocation'; fa = 'Consent revocation';
										|it = 'Отзыв согласия';
										|pl = 'Consent revocation';
										|tr = 'Onay iptali'") + " BankFeeds";
	IdleParameters.UserNotification.Show = True;
	IdleParameters.UserNotification.Explanation = NStr("vi = 'Thu hồi đồng ý';
														|ru = 'Отзыв согласия';
														|en = 'Consent revocation'; fa = 'Consent revocation';
														|it = 'Отзыв согласия';
														|pl = 'Consent revocation';
														|tr = 'Onay iptali'") + " BankFeeds";
	IdleParameters.UserNotification.Text = "BankFeeds";
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("FillParameters", FillParameters);
	
	CallbackOnCompletion = New CallbackDescription("EndOfWithdrawalOfConsentOfService", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure	

Procedure EndOfWithdrawalOfConsentOfService(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	Else 
		ResultOfResponseFromService = GetFromTempStorage(Result.ResultAddress);
		Form = AdditionalParameters.Form;
		
		If ResultOfResponseFromService.ResponseStatus = ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses().IsAnswered Then
			
			If ResultOfResponseFromService.StatusOfConsent = "revoked" Then

				Form.StartCheckingStatusOfConnectionAndConsent();
				
			Else
				
				ShowMessageBox(, NStr("vi = 'Chưa đóng kết nối';
										|ru = 'Соединение не закрыто';
										|en = 'Connection is not closed'; fa = 'Connection is not closed';
										|it = 'Соединение не закрыто';
										|pl = 'Connection is not closed';
										|tr = 'Bağlantı kapatılmadı'"));     
			EndIf;
			
		Else 
			
			CommonClient.MessageToUser(NStr("vi = 'Chưa thu hồi thống nhất';
											|ru = 'Отзыв согласия не выполнен';
											|en = 'Consent revocation failed'; fa = 'Consent revocation failed';
											|it = 'Отзыв согласия не выполнен';
											|pl = 'Consent revocation failed';
											|tr = 'Geri çekilen rıza yerine getirilmemiştir'"));
			
			For Each CurrentError In ResultOfResponseFromService.ErrorsArray Do
			
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Lỗi: %1';
						|ru = 'Ошибка: %1';
						|en = 'Error: %1'; fa = 'Error: %1';
						|it = 'Ошибка: %1';
						|pl = 'Error: %1';
						|tr = 'Hata: %1'"), CurrentError);
				CommonClient.MessageToUser(MessageText);
			
			EndDo;	
			
		EndIf;	 
			
	EndIf;	
			
EndProcedure			

#EndRegion 

 #Region ImportTransactions

// Starts the procedure for downloading transactions from the service
// 
// Parameters:
//   ImportParameters - Structure - The fill parameters
//  Form - ClientApplicationForm - Form
//
Procedure DownloadTransactions(ImportParameters, Form) Export

	TimeConsumingOperation = ExchangeWithBankFeedsServiceServerCall.FillInParametersOfBackgroundTaskForDownloadingTransactions(
		Form.UUID, ImportParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OwnerForm = Form;
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = True;
	IdleParameters.MessageText = NStr("vi = 'Kết nhập giao dịch từ';
										|ru = 'Загрузка транзакций из';
										|en = 'Importing transactions from'; fa = 'Importing transactions from';
										|it = 'Загрузка транзакций из';
										|pl = 'Importing transactions from';
										|tr = 'İşlemlerin şuradan yüklenmesi'") + " BankFeeds";
	IdleParameters.UserNotification.Show = False;
	IdleParameters.UserNotification.Explanation = NStr("vi = 'Giao dịch được kết nhập';
														|ru = 'Транзакции загружены';
														|en = 'Transactions are imported'; fa = 'Transactions are imported';
														|it = 'Транзакции загружены';
														|pl = 'Transactions are imported';
														|tr = 'İşlemler yüklendi'");
	IdleParameters.UserNotification.Text = "BankFeeds";
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("ImportParameters", ImportParameters);
	
	CallbackOnCompletion = New CallbackDescription("EndOfDownloadingTransactionsFromService", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

// Called at the End of the transaction upload on the service form
// 
// Parameters:
//   Result - Structure - result parameters
//   AdditionalParameters - Structure - advanced setting
//
Procedure EndOfDownloadingTransactionsFromService(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;               
	
	FillParameters = AdditionalParameters.ImportParameters;
	Form = AdditionalParameters.Form;
	ResultsTable = GetFromTempStorage(Result.ResultAddress);
	
	ThereAreAnswersReceived = False;
	
	If ResultsTable = Undefined Then
		Return;
	EndIf;	
	
	For Each CurRowOfResult In ResultsTable Do
		
		If Result.Status = "Error" Then
			
			Raise Result.BriefErrorDescription;
		
		ElsIf CurRowOfResult.ResponseStatus = ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses().NoResponseReceived Then
		
			For Each CurrentError In CurRowOfResult.ErrorsArray Do
			
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Theo hóa đơn %1 có lỗi: %2. Chưa kết nhập giao dịch';
						|ru = 'По счету %1 ошибка: %2. Загрузка транзакций не выполнена';
						|en = 'Error by the %1 account: %2. Transaction import failed'; fa = 'Error by the %1 account: %2. Transaction import failed';
						|it = 'По счету %1 ошибка: %2. Загрузка транзакций не выполнена';
						|pl = 'Error by the %1 account: %2. Transaction import failed';
						|tr = '%1 hesabında hata: %2. İşlem yüklemesi başarısız oldu'")
						, CurRowOfResult.FillParameters.BankAccount, CurrentError); 
				CommonClient.MessageToUser(MessageText);
			
			EndDo;	
		
		ElsIf CurRowOfResult.ResponseStatus = ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses().IsAnswered Then
			
			ThereAreAnswersReceived = True;
		
			For Each CurrentError In CurRowOfResult.ErrorsArray Do
			
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Theo hóa đơn %1 có lỗi: %2. Chưa kết nhập giao dịch';
						|ru = 'По счету %1 ошибка: %2. Загрузка транзакций не выполнена';
						|en = 'Error by the %1 account: %2. Transaction import failed'; fa = 'Error by the %1 account: %2. Transaction import failed';
						|it = 'По счету %1 ошибка: %2. Загрузка транзакций не выполнена';
						|pl = 'Error by the %1 account: %2. Transaction import failed';
						|tr = '%1 hesabında hata: %2. İşlem yüklemesi başarısız oldu'")
						, CurRowOfResult.FillParameters.BankAccount, CurrentError); 
				
				ThereAreAnswersReceived = False;
			EndDo;	
		
		EndIf;	                                       
	
	EndDo;
	
	If AdditionalParameters.ImportParameters.DownloadIsPerformedWhenSyncing Then

		If CurRowOfResult <> Undefined 
			And CurRowOfResult.Property("Number_Transactions") Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Số lượng giao dịch được kết nhập: %1';
					|ru = 'Загружено транзакций: %1';
					|en = 'Imported transactions: %1'; fa = 'Imported transactions: %1';
					|it = 'Загружено транзакций: %1';
					|pl = 'Imported transactions: %1';
					|tr = 'İndirilen işlemler: %1'"), CurRowOfResult.Number_Transactions);
			ShowUserNotification(MessageText,,,,UserNotificationStatus.Important);
			
		EndIf;	

		ExportingParameters = New Structure(); 
		ExportingParameters.Insert("UploadIsPerformedWhenSyncing", True);
		ExportingParameters.Insert("AddressDocumentsToBeUploaded", "");
		ExportingParameters.Insert("AddressBankAccounts", "");
		ExportingParameters.Insert("BankAccount", FillParameters.BankAccount);
		
		UploadPaymentDocuments(ExportingParameters, Form);	                      
		
	ElsIf ThereAreAnswersReceived Then

		//@skip-check dynamic-feature-access-translation-ambiguity
		Form.Items.ImportedDocuments.Refresh();
				
		If CurRowOfResult <> Undefined 
			And CurRowOfResult.Property("Number_Transactions") Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Số lượng giao dịch được kết nhập: %1';
					|ru = 'Загружено транзакций: %1';
					|en = 'Imported transactions: %1'; fa = 'Imported transactions: %1';
					|it = 'Загружено транзакций: %1';
					|pl = 'Imported transactions: %1';
					|tr = 'İndirilen işlemler: %1'"), CurRowOfResult.Number_Transactions);
			ShowUserNotification(MessageText,,,,UserNotificationStatus.Important);
			
		Else
					
		MessageText = NStr("vi = 'Giao dịch được kết nhập';
							|ru = 'Транзакции загружены';
							|en = 'Transactions are imported'; fa = 'Transactions are imported';
							|it = 'Транзакции загружены';
							|pl = 'Transactions are imported';
							|tr = 'İşlemler yüklendi'");
		ShowUserNotification(MessageText,,NStr("vi = 'Kết nhập giao dịch';
												|ru = 'Загрузка транзакций';
												|en = 'Import transactions'; fa = 'ورود تراکنش‌ها';
												|it = 'Загрузка транзакций';
												|pl = 'Import transactions';
												|tr = 'İşlemlerin yüklenmesi'"),,UserNotificationStatus.Important);
		EndIf;	
				
	EndIf;	
	
EndProcedure

#EndRegion

#Region ExportPaymentDocuments

// Starts the procedure for uploading payment documents to the service
// 
// Parameters:
//   ExportingParameters - Structure - The fill parameters
//   Form - ClientApplicationForm - Form
//
Procedure UploadPaymentDocuments(ExportingParameters, Form) Export
	
	TimeConsumingOperation = 
		ExchangeWithBankFeedsServiceServerCall.FillInParametersOfBackgroundTaskForUploadingPaymentDocuments(
																	Form.UUID, ExportingParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = True;
	IdleParameters.MessageText = NStr("vi = 'Kết xuất chứng từ thanh toán';
										|ru = 'Выгрузка платежных документов';
										|en = 'Export payment documents'; fa = 'خروج اطلاعات اسناد پرداخت';
										|it = 'Выгрузка платежных документов';
										|pl = 'Export payment documents';
										|tr = 'Ödeme belgelerinin dışa aktarılması'") + " BankFeeds";
	IdleParameters.UserNotification.Show = False;
	IdleParameters.UserNotification.Explanation = NStr("vi = 'Chứng từ thanh toán được kết xuất';
														|ru = 'Платежные документы выгружены';
														|en = 'Payment documents are exported'; fa = 'Payment documents are exported';
														|it = 'Платежные документы выгружены';
														|pl = 'Payment documents are exported';
														|tr = 'Ödeme belgeleri dışa aktarıldı'");
	IdleParameters.UserNotification.Text = "BankFeeds";
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("ExportingParameters", ExportingParameters);
	
	CallbackOnCompletion = New CallbackDescription("EndOfUploadingPaymentDocumentsToService", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

// Converts a row of a table of values into a structure
// 
// Parameters:
//   ValueTableRow - ValueTableRow - row of the table of values
//   
// Returns:
// 		Structure - set of values:
// 		* NameColumn - String
//
Function ValueTableRowToStructure(ValueTableRow) Export
	
	Structure = New Structure;
	For Each Column In ValueTableRow.Owner().Columns Do
		Structure.Insert(Column.Name, ValueTableRow[Column.Name]);
	EndDo;
	
	Return Structure;
	
EndFunction

// Called at the End of uploading payment documents on the service form
// 
// Parameters:
//   Result - Structure - result parameters
//   AdditionalParameters - Structure - advanced setting
//
Procedure EndOfUploadingPaymentDocumentsToService(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;

	ResponseStatus = ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses();
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	Else 
		ResultOfResponseFromService = GetFromTempStorage(Result.ResultAddress);
		FillParameters = AdditionalParameters.ExportingParameters;
		Form = AdditionalParameters.Form;
		
		HasErrors = False;
		
		For Each CurRowOfResult In ResultOfResponseFromService Do
			
			If Result.Status = "Error" Then
				
				Raise Result.BriefErrorDescription;
				
			ElsIf CurRowOfResult.ResponseStatus = ExchangeWithBankFeedsServiceServerCall.StatusesOfResponses().NoResponseReceived Then
				
				For Each CurrentError In CurRowOfResult.ErrorsArray Do
					
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Theo hóa đơn %1 có lỗi: %2. Đã ngắt kết xuất chứng từ thanh toán';
						|ru = 'По счету %1 ошибка: %2. Выгрузка платежных документов прервана';
						|en = 'Error by the %1 account: %2. Payment document export is interrupted'; fa = 'Error by the %1 account: %2. Payment document export is interrupted';
						|it = 'По счету %1 ошибка: %2. Выгрузка платежных документов прервана';
						|pl = 'Error by the %1 account: %2. Payment document export is interrupted';
						|tr = 'Hesap %1 hatası: %2. Ödeme belgelerinin indirilmesi kesintiye uğradı'")
					, CurRowOfResult.FillParameters.BankAccount, CurrentError); 
					
					HasErrors = True;
					
					CommonClient.MessageToUser(MessageText);
					
				EndDo;	
			
			EndIf;	                                       
			
		EndDo;
		
		If ResultOfResponseFromService.Count() > 0
			And Not HasErrors Then

			HasErrors = False;
			For Each CurrentResult In ResultOfResponseFromService Do
				
				If CurrentResult.ResponseStatus = ResponseStatus.NoResponseReceived Then
				
					For Each CurrentError In CurrentResult.ErrorsArray Do
			
						MessageText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Lỗi: %1. Chưa kết xuất chứng từ thanh toán';
								|ru = 'Ошибка: %1. Выгрузка платежных документов не выполнена';
								|en = 'Error: %1. Payment document export failed'; fa = 'Error: %1. Payment document export failed';
								|it = 'Ошибка: %1. Выгрузка платежных документов не выполнена';
								|pl = 'Error: %1. Payment document export failed';
								|tr = 'Hata: %1 . Ödeme belgelerinin indirilmesi gerçekleştirilmedi'"), CurrentError);
						CommonClient.MessageToUser(MessageText);
			
						HasErrors = True;
					EndDo;	
					
				EndIf;	
			
			EndDo;
			
			If Not HasErrors Then
			
				FormOpenParameters = New Structure("ArrayOfPaymentConfirmationLinks", ResultOfResponseFromService);

				FormOpenParameters.Insert("AddressBankAccounts", AdditionalParameters.ExportingParameters.AddressBankAccounts);
				FormOpenParameters.Insert("AddressDocumentsToBeUploaded", AdditionalParameters.ExportingParameters.AddressDocumentsToBeUploaded);
				FormOpenParameters.Insert("UploadIsPerformedWhenSyncing", 
				AdditionalParameters.ExportingParameters.UploadIsPerformedWhenSyncing);  
				If AdditionalParameters.ExportingParameters.Property("BankAccount") Then	
					FormOpenParameters.Insert("BankAccount", 
						AdditionalParameters.ExportingParameters.BankAccount);
				EndIf;		
			
				AdditionalParameters.Insert("ArrayOfPaymentDocuments", ResultOfResponseFromService);

				FormClosingNotification = New CallbackDescription("ClosingPaymentConfirmationFormInSaltEdge", 
					Form, AdditionalParameters);
			
				OpenForm("Catalog.IntegrateWithBankFeeds.Form.ServicePaymentConfirmationForm", 
					FormOpenParameters,,,,, FormClosingNotification);
			Else		
				ExchangeWithBankFeedsServiceClient.CheckStatusOfPaymentsAfterSending(Form);	
				
			EndIf;		
			
		Else
				
				ExchangeWithBankFeedsServiceClient.CheckStatusOfPaymentsAfterSending(Form);	
				If FillParameters.UploadIsPerformedWhenSyncing Then
					Notify("UpdateLogOfDocumentsNonCashPayments",, ThisObject);
				EndIf;	
				
		EndIf;	 
		
		If Not FillParameters.UploadIsPerformedWhenSyncing Then
		
			Notify("UpdateFormForBankConnectionListBankFeeds",, ThisObject);
			
		EndIf;	
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CheckingStatusOfPaymentDocumentsAfterSendingToService

// Actions are started to check the Status of payments in the service
// 
// Parameters:
//   Form - ClientApplicationForm - Form
//   TransmittedParameters - Structure - The fill parameters
//
Procedure CheckStatusOfPaymentsAfterSending(Form, TransmittedParameters = Undefined) Export
	
	TimeConsumingOperation = 
			ExchangeWithBankFeedsServiceServerCall.FillInParametersOfBackgroundTaskForCheckingStatusOfPaymentDocuments(
												Form.UUID);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = True;
	IdleParameters.MessageText = NStr("vi = 'Kiểm tra trạng thái chứng từ thanh toán';
										|ru = 'Проверка статуса платежных документов';
										|en = 'Check payment document status'; fa = 'Check payment document status';
										|it = 'Проверка статуса платежных документов';
										|pl = 'Check payment document status';
										|tr = 'Ödeme belgelerinin durumunun kontrol edilmesi'") + "BankFeeds";
	IdleParameters.UserNotification.Show = False;
	IdleParameters.UserNotification.Explanation = NStr("vi = 'Đã kiểm tra trạng thái chứng từ thanh toán';
														|ru = 'Статусы платежных документов проверены';
														|en = 'Payment document statuses checked'; fa = 'Payment document statuses checked';
														|it = 'Статусы платежных документов проверены';
														|pl = 'Payment document statuses checked';
														|tr = 'Ödeme belgelerinin durumları kontrol edildi'");
	IdleParameters.UserNotification.Text = "BankFeeds";
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("DocumentsArray", New Array()); 
	
	If ValueIsFilled(TransmittedParameters) 
		And TransmittedParameters.ExportingParameters.UploadIsPerformedWhenSyncing 
		And TransmittedParameters.Property("ArrayOfPaymentDocuments") Then
			AdditionalParameters.DocumentsArray = TransmittedParameters.ArrayOfPaymentDocuments;
	EndIf;	
	
	CallbackOnCompletion = New CallbackDescription("EndOfCheckingStatusOfPaymentDocumentsInService", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure	

// The procedure starts after checking the Status of the payment in the service
// 
// Parameters:
//   Result - Structure - launch result 
//   AdditionalParameters - Structure - 
//
Procedure EndOfCheckingStatusOfPaymentDocumentsInService(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return ;
	EndIf;	
	
	Form = AdditionalParameters.Form; 
	
	Notify("UpdateFormOfUploadingPaymentDocumentsListBankFeeds",, Form);
	
	// If the name of the form is the Payment confirmation form in the service, then we will launch the handler after checking the payment Status
	If Form.FormName = "Catalog.IntegrateWithBankFeeds.Form.ServicePaymentConfirmationForm" Then
		
		Form.UpdatePaymentList();
		
	EndIf;
	
	If AdditionalParameters.DocumentsArray.Count() > 0 Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã gửi theo %1: %2';
					|ru = 'Отправлено по %1: %2';
					|en = 'Sent by %1: %2'; fa = 'Sent by %1: %2';
					|it = 'Отправлено по %1: %2';
					|pl = 'Sent by %1: %2';
					|tr = '%1: %2 tarafından gönderildi'"), "BankFeeds", 
					ExchangeWithBankFeedsServiceServerCall.NumberOfDocumentsSentToBank(AdditionalParameters.DocumentsArray));
			ShowUserNotification(MessageText,,,,UserNotificationStatus.Important);
		
	EndIf;	
	
EndProcedure

// The procedure disables the connection of the account to BankFeeds
//
//
// Parameters:
//   Form - ClientApplicationForm - Form
//
Procedure DisableConnectionToService(Form) Export 
	
	Object = Form.Object;
	
	If Form.UseEDIWithBanksBankFeeds 
		And ValueIsFilled(Object.BankFeedsAccountID) Then
		
		Object.BankFeedsAccountID = "";
		
		Notify("UpdateBankFeedsPage",, ThisObject);
		
	EndIf;	
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Checks the connection to the service
// 
// Parameters:
// 	BankAccount - CatalogRef.CompaniesBankAccounts - Bank account
// 
// Returns:
// Boolean - True if the bank account is connected to the service
//
Function TestServiceConnection(BankAccount)
	
   Return ExchangeWithBankFeedsServiceServerCall.TestServiceConnection(BankAccount);
	
EndFunction	

// Called when opening the form for uploading a payment document 
//
// Parameters:
//  DocumentRef - DocumentRef - link to the document 
//  Form - ClientApplicationForm
//
Procedure OpenBankClientForm(DocumentRef, Form)

	OpenForm("DataProcessor.EDIWithBanksBankFeeds.Form.ExportPaymentDocuments",
		New Structure("BankAccount, PaymentDocument", Form.Object.BankAccount, DocumentRef),);
	
EndProcedure	

#EndRegion
