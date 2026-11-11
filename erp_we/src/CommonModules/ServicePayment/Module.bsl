
#Region Public

// Returns the version of the billing interface (versions are numbered with a simple natural number).
// 
// Returns:
//  Number - interface version.
//
Function InterfaceVersion() Export
	
	Return 3;
	
EndFunction

// Returns a Presentation Of The service payment currency.
// 
// Returns:
//  String - presentation of the payment currency. 
//
Function PresentationOfPaymentCurrency() Export
	
	PresentationOfPaymentCurrency = NStr("vi = 'đồng';
										|ru = 'руб.';
										|en = 'euros'; fa = 'euros';
										|it = 'руб.';
										|pl = 'euros';
										|tr = 'rub.'"); 
	ServicePaymentOverridable.OnSetPaymentCurrencyPresentation(PresentationOfPaymentCurrency);
	
	Return PresentationOfPaymentCurrency;
	
EndFunction

// See CommonOverridable.OnAddClientParametersOnStart
// The method is overridden in the fresh extension.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method
Procedure OnAddClientParametersOnStart(Parameters) Export
EndProcedure

// Returns States of expiration of tariff subscriptions submitted by the service manager.
// The data is returned only for users with the "Subscriber Owner" role.
// The method is overridden in the fresh extension.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method
// 
// Returns:
//  Structure:
//   * TestResultsAreCompleted - Number
//   * CompletedFree - Number
//   * EndingPaid - Number
//   * TotalCompleted - Number
//   * NotTestResultsAreCompleted - Number
//   * NotCompletedFree - Number
//   * NotEndingPaid - Number
//   * NotTotalCompleted - Number
Function StatesOfCompletionOfTariffSubscriptions() Export
EndFunction

// Returns a sign of support for loading service rates into the data of the information database.
// 
// Returns:
//  Boolean - if True, then the download is supported.
//
Function TariffLoadingIsSupported() Export
	
	Result = False;
	ServicePaymentOverridable.OnDefineServicePlansImportSupport(Result);
	
	Return Result;
	
EndFunction

// Uploading tariffs to the directories of the information base from the service manager.
// 
Procedure DownloadServiceRates() Export
	
	If Not SaaSOperations.DataSeparationEnabled() Then
		AuthorizationData = ServiceProgrammingInterfaceInternal.AuthorizationDataInService();
		SubscriberCode = AuthorizationData.SubscriberCode;
	Else
		SubscriberCode = ServiceProgrammingInterface.SubscriberCode();
	EndIf; 
	
	Filter = ServiceProgrammingInterface.NewSelectionOfSupportCompanyTariffsList();
	Filter.ServiceProviderCode = SubscriberCode;
	Filter.ReceivingParameters.Add(ServiceProgrammingInterface.ParameterForGettingValidityPeriods());

	RawData = New Structure;
	RawData.Insert("ServiceOrganizationRates", 
		ServiceProgrammingInterface.ServiceOrganizationRates(Filter));
		
	Filter = ServiceProgrammingInterface.NewTariffsListFilter();
	Filter.ReceivingParameters.Add(ServiceProgrammingInterface.ParameterForGettingPaidOnly());
	Filter.ReceivingParameters.Add(ServiceProgrammingInterface.ParameterForGettingValidityPeriods());
	RawData.Insert("ProviderRates", ServiceProgrammingInterface.ServiceRates(Filter));
	
	ProcessingResult = NewProcessingResult();
	
	Try
		ServicePaymentOverridable.OnImportServicePlans(RawData, ProcessingResult);
		If ProcessingResult.Error Then
			Raise ProcessingResult.Message;
		EndIf;
	Except
		ErrorInfo = ErrorInfo();
		EventName = EventLogEvent(NStr("vi = 'Kết nhập biểu phí dịch vụ';
										|ru = 'Загрузка тарифов сервиса';
										|en = 'Import service plans'; fa = 'ورود طرح‌های سرویس';
										|it = 'Загрузка тарифов сервиса';
										|pl = 'Import service plans';
										|tr = 'Servis planı içe aktarımı'", Common.DefaultLanguageCode()));
		WriteLogEvent(EventName, EventLogLevel.Error, , ,
			CloudTechnology.DetailedErrorText(ErrorInfo));
		Raise StrTemplate(
			NStr("vi = 'Lỗi khi kết nhập biểu phí dịch vụ theo nguyên nhân:
					   |%1
					   |Xem chi tiết trong nhật ký sự kiện của ứng dụng lập hóa đơn điện tử.';
					   |ru = 'Ошибка при загрузке тарифов сервиса по причине:
					   |%1
					   |См. подробности в журнале регистрации приложения биллинга.';
					   |en = 'An error occurred when importing the service plans. Reason:
					   |%1
					   |For more information, see the event log of the billing application.'; fa = 'An error occurred when importing the service plans. Reason:
					   |%1
					   |For more information, see the event log of the billing application.';
					   |it = 'Ошибка при загрузке тарифов сервиса по причине:
					   |%1
					   |См. подробности в журнале регистрации приложения биллинга.';
					   |pl = 'An error occurred when importing the service plans. Reason:
					   |%1
					   |For more information, see the event log of the billing application.';
					   |tr = 'Servis planı içe aktarılırken şu nedenle bir hata oluştu:
					   |%1
					   |Bkz. faturalama uygulama günlüğündeki ayrıntılar.'"),
			CloudTechnology.ShortErrorText(ErrorInfo));
	EndTry;
	
EndProcedure

// Sends a response to the billing accounting system to the address of the invoice for payment.
//
// Parameters:
//  InvoiceId - UUID - ID of the payment invoice.
//  Data - See ServicePayment.ResponseDataTemplate
//
// Returns:
//  HTTPResponse - the response of the service manager.
//
// Example:
//  ...
//  Data = Service payment.Templateddannyhot response();
//  Data.Insert ("paid", True); // Indicates payment of the invoice.
//  Payment for the service.To send a request for a Billing account system(Account ID, Data); // Sending.
//
Function SendResponseToBillingSystem(InvoiceId, Data) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	If SaaSOperations.DataSeparationEnabled() Then
		ServiceAddress = SaaSOperations.InternalServiceManagerURL();
	Else
		ServiceAddress = ServiceProgrammingInterfaceInternal.ServiceAddressFromLocalDatabase();
	EndIf;
	
	AccountAddress = StrTemplate("%1/%2/%3", ServiceAddress, AddressOfInvoicesForPaymentOfBillingSystem(), InvoiceId);
	ServerData = CommonClientServer.URIStructure(AccountAddress);
	AccountSystemUserName = Constants.AccountSystemUserName.Get();
	AccountSystemUserPassword = Common.ReadDataFromSecureStorage(
		OwnerOfAuthorizationPasswordInAccountSystem());
		
	If Not ValueIsFilled(AccountSystemUserName) Then
		ErrorText = NStr("vi = 'Chưa tùy chỉnh tham số kết nối đến hệ thống kế toán lập hóa đơn điện tử. 
								 |Cần thiết lập tùy chỉnh theo tham chiếu: 
								 |%1';
								 |ru = 'Не настроены параметры подключения к учетной системе биллинга. 
								 |Нужно установить настройки по ссылке: 
								 |%1';
								 |en = 'Parameters for connecting to the billing accounting system are not configured. 
								 |Configure settings by reference:
								 |%1'; fa = 'Parameters for connecting to the billing accounting system are not configured. 
								 |Configure settings by reference:
								 |%1';
								 |it = 'Non sono impostati i parametri di connessione all''account di sistema di fatturazione. 
								 |È necessario impostare le impostazioni al collegamento:
								 |%1';
								 |pl = 'Nie ustawiono parametrów podłączenia do ewidencyjnego systemu rozliczeniowego. 
								 |Należy skonfigurować ustawienia, otwierając odnośnik: 
								 |%1';
								 |tr = 'Faturalama muhasebe sistemine bağlanmak için parametreler yapılandırılmamıştır. 
								 |Bağlantıdan ayarları yapmanız gerekiyor: 
								 |%1'");
		LinkToSettings = "e1cib/data/DataProcessor.AdministrationPanelCTL.Form.ServicePaymentSettings";
		Raise StrTemplate(ErrorText, LinkToSettings); 
	EndIf;
	
	SSLScheme = "https";
	If Lower(ServerData.Schema) = SSLScheme Then
		SecureConnection =  CommonClientServer.NewSecureConnection();
	Else
		SecureConnection = Undefined;
	EndIf;
	
	Join = New HTTPConnection(ServerData.Host, ServerData.Port,
		AccountSystemUserName, AccountSystemUserPassword,
		GetFilesFromInternet.GetProxy(ServerData.Schema), 5, SecureConnection);
	
	Method_HTTP = "PUT";
	HTTPRequest = New HTTPRequest;
	HTTPRequest.ResourceAddress = ServerData.PathAtServer;
	HTTPRequest.SetBodyFromString(JSONString(Data));
	Response = Join.CallHTTPMethod(Method_HTTP, HTTPRequest);
	LogHTTPRequest(HTTPRequest, Response);
	
	// The transaction may not have time to be committed for the object.
	If Response.StatusCode = 404 Then
		For Counter = 1 To 3 Do
			CommonCTL.Pause(1);
			Response = Join.CallHTTPMethod(Method_HTTP, HTTPRequest);
			If Not Response.StatusCode = 404 Then
				Break;
			EndIf; 
		EndDo;
		If Response.StatusCode = 404 Then
			Raise StrTemplate(NStr("vi = 'Lỗi 404 khi gửi phản hồi theo hóa đơn %1 đến địa chỉ %2. 
				|Có thể là khi đăng tải nội bộ Bộ quản lý dịch vụ chưa đăng tải HTTP-service %3.';
				|ru = 'Ошибка 404 при отправке ответа по счету %1 на адрес %2. 
				|Возможно во внутренней публикации Менеджера сервиса не опубликован HTTP-сервис %3.';
				|en = 'Error 404 occurred when sending a response on the %1invoice to the %2 address.
				|The %3 HTTP service is not published in the internal Service Manager publication.'; fa = 'Error 404 occurred when sending a response on the %1invoice to the %2 address.
				|The %3 HTTP service is not published in the internal Service Manager publication.';
				|it = 'Errore 404 di l''invio della risposta del conto %1 all''indirizzo %2. 
				| È possibile che nella pubblicazione interna del Service Manager non sia stato pubblicato il servizio HTTP %3.';
				|pl = 'Błąd 404 podczas wysyłki odpowiedzi dotyczącej konta %1 na adres %2. 
				|Możliwe, że w publikacji wewnętrznej Menedżera serwisu nie jest opublikowany serwis HTTP %3.';
				|tr = '%1 hesabı için %2 adresine yanıt gönderilirken 404 hatası oluştu. 
				|HTTP hizmeti %3, Servis Yöneticisi dahili yayımlamasında yayınlanmamış olabilir.'"),
				InvoiceId, AccountAddress, "UniversalIntegration");
		EndIf; 
	EndIf;
	
	ErrorTextTemplate = NStr("vi = 'Lỗi %1 khi gửi phản hồi theo tài khoản %2 đến địa chỉ %3 theo nguyên nhân: %4';
							|ru = 'Ошибка %1 при отправке ответа по счету %2 на адрес %3 по причине: %4';
							|en = 'Error %1 occurred when sending the response on proforma invoice %2 to %3. Reason: %4'; fa = 'Error %1 occurred when sending the response on proforma invoice %2 to %3. Reason: %4';
							|it = 'Ошибка %1 при отправке ответа по счету %2 на адрес %3 по причине: %4';
							|pl = 'Error %1 occurred when sending the response on proforma invoice %2 to %3. Reason: %4';
							|tr = '%3 adresine %2 hesabına göre cevap gönderme %1 hata sebebi: %4'");
	If Response.StatusCode = 401 Then
		Raise StrTemplate(ErrorTextTemplate, Response.StatusCode, InvoiceId, AccountAddress,
			StrTemplate(NStr("vi = 'Người dùng %1 chưa đăng nhập.';
							|ru = 'Пользователь %1 не авторизован.';
							|en = 'User %1 is not authorized.'; fa = 'User %1 is not authorized.';
							|it = 'Пользователь %1 не авторизован.';
							|pl = 'User %1 is not authorized.';
							|tr = '%1 kullanıcı yetkilendirilmemiş.'"), AccountSystemUserName));
	ElsIf Response.StatusCode = 403 Then
		Raise StrTemplate(ErrorTextTemplate, Response.StatusCode, InvoiceId, AccountAddress,
			StrTemplate(NStr("vi = 'Yêu cầu %1 không được phép đối với người dùng %2.';
							|ru = 'Запрос %1 не разрешен пользователю %2.';
							|en = 'The %1 request is restricted for user %2.'; fa = 'The %1 request is restricted for user %2.';
							|it = 'Запрос %1 не разрешен пользователю %2.';
							|pl = 'The %1 request is restricted for user %2.';
							|tr = '%2 kullanıcı için %1 sorgusu izin verilmiyor.'"), Method_HTTP, AccountSystemUserName)); 
	ElsIf Response.StatusCode = 405 Then
		Raise StrTemplate(ErrorTextTemplate, Response.StatusCode, InvoiceId, AccountAddress,
			StrTemplate(NStr("vi = 'Không hỗ trợ phương thức %1.';
							|ru = 'Метод %1 не поддерживается.';
							|en = 'The %1 method is not supported.'; fa = 'The %1 method is not supported.';
							|it = 'Метод %1 не поддерживается.';
							|pl = 'The %1 method is not supported.';
							|tr = '%1 yöntem desteklenmiyor.'"), Method_HTTP));
	ElsIf Response.StatusCode = 400 Or Response.StatusCode >= 500 Then
		Raise StrTemplate(ErrorTextTemplate, Response.StatusCode, InvoiceId, AccountAddress,
			Response.GetBodyAsString());
	EndIf;
	
	Return Response;
	
EndFunction

// Returns a data template when sending information about the status of the invoice for payment.
//
// Parameters:
//  ResponseCode - Number - response code. If the parameter is not passed, 10200 is set.
//              For installation, you can use the methods:
//              Error Data Return code() - corresponds to code 10400 - is used when processing known errors.
//              Internal Error Return code() - corresponds to code 10500 - is used when unexpected errors occur.
//  Message - String - error message. The error text can be set, which will be returned to the user.
// 
// Returns:
//  Structure:
//   * response - Number - the response code.
//   * error - Boolean - error indication. It is cocked if a response code other than 102xx is transmitted.
//   * message - String - error message.
//
Function ResponseDataTemplate(ResponseCode = 10200, Message = "") Export
	
	ResponseData = New Structure;
	ResponseData.Insert("response", ResponseCode);
	ResponseData.Insert("error", ?(ResponseCode >= 10200 And ResponseCode <= 10299, False, True));
	ResponseData.Insert("message", Message);
	
	Return ResponseData;
	
EndFunction

// Returns the data error code.
// 
// Returns:
//   Number - the data error return code is 10400.
//
Function ReturnCodeDataError() Export
	
	Return 10400;
	
EndFunction

// Returns the internal error code.
// 
// Returns:
//   Number - the internal error return code is 10500.
//
Function ReturnCodeInternalError() Export
	
	Return 10500;
	
EndFunction

#EndRegion 

#Region Internal

// Setting service payment settings.
// 
// Parameters:
//  SubscriberCode - Number - the code of the subscriber-the owner of the accounting system.
// 
Procedure SetServicePaymentSettings(SubscriberCode) Export
	
	ProcessingResult = NewProcessingResult();
	
	Try
		ServicePaymentOverridable.AtSettingServicePaymentSettings(SubscriberCode, ProcessingResult);
		If ProcessingResult.Error Then
			Raise ProcessingResult.Message;
		EndIf;
	Except
		ErrorInfo = ErrorInfo();
		EventName = EventLogEvent(NStr("vi = 'Thiết lập tùy chỉnh thanh toán của dịch vụ';
										|ru = 'Установка настроек оплаты сервиса';
										|en = 'Configure service payment settings'; fa = 'Configure service payment settings';
										|it = 'Установка настроек оплаты сервиса';
										|pl = 'Configure service payment settings';
										|tr = 'Servis Ödemeleri ayar kurulumu'", Common.DefaultLanguageCode()));
		WriteLogEvent(EventName, EventLogLevel.Error, , ,
			CloudTechnology.DetailedErrorText(ErrorInfo));
		Raise StrTemplate(
			NStr("vi = 'Lỗi khi thiết lập tùy chỉnh thanh toán của dịch vụ theo nguyên nhân:
					   |%1
					   |Xem chi tiết trong nhật ký sự kiện của ứng dụng lập hóa đơn điện tử.';
					   |ru = 'Ошибка при установке настроек оплаты сервиса по причине:
					   |%1
					   |См. подробности в журнале регистрации приложения биллинга.';
					   |en = 'An error occurred when configuring service payment settings. Reason:
					   |%1
					   |For more information, see the event log of the billing application.'; fa = 'An error occurred when configuring service payment settings. Reason:
					   |%1
					   |For more information, see the event log of the billing application.';
					   |it = 'Ошибка при установке настроек оплаты сервиса по причине:
					   |%1
					   |См. подробности в журнале регистрации приложения биллинга.';
					   |pl = 'An error occurred when configuring service payment settings. Reason:
					   |%1
					   |For more information, see the event log of the billing application.';
					   |tr = 'Servis Ödemeleri ayarları yapılırken şu nedenle bir hata oluştu:
					   |%1
					   |Bkz. faturalama uygulama günlüğündeki ayrıntılar.'"),
			CloudTechnology.ShortErrorText(ErrorInfo));
	EndTry;
		
	If TariffLoadingIsSupported() Then
		DownloadServiceRates()
	EndIf;
	
EndProcedure

// Deleting service payment settings.
//
// Parameters:
//  SubscriberCode - Number - the code of the subscriber-the owner of the accounting system.
//
Procedure DeleteServicePaymentSettings(SubscriberCode) Export
	
	ProcessingResult = NewProcessingResult();
	
	Try
		ServicePaymentOverridable.AtDeletingServicePaymentSettings(SubscriberCode, ProcessingResult);
		If ProcessingResult.Error Then
			Raise ProcessingResult.Message;
		EndIf;
	Except
		ErrorInfo = ErrorInfo();
		EventName = EventLogEvent(NStr("vi = 'Xóa tùy chỉnh thanh toán của dịch vụ';
										|ru = 'Удаление настроек оплаты сервиса';
										|en = 'Delete service payment settings'; fa = 'Delete service payment settings';
										|it = 'Удаление настроек оплаты сервиса';
										|pl = 'Delete service payment settings';
										|tr = 'Servis Ödemeleri ayar silinmesi'", Common.DefaultLanguageCode()));
		WriteLogEvent(EventName, EventLogLevel.Error, , ,
			CloudTechnology.DetailedErrorText(ErrorInfo));
		Raise StrTemplate(
			NStr("vi = 'Lỗi khi xóa tùy chỉnh thanh toán của dịch vụ theo nguyên nhân:
					   |%1
					   |Xem chi tiết trong nhật ký sự kiện của ứng dụng lập hóa đơn điện tử.';
					   |ru = 'Ошибка при удалении настроек оплаты сервиса по причине:
					   |%1
					   |См. подробности в журнале регистрации приложения биллинга.';
					   |en = 'An error occurred when deleting service payment settings. Reason:
					   |%1
					   |For more information, see the event log of the billing application.'; fa = 'An error occurred when deleting service payment settings. Reason:
					   |%1
					   |For more information, see the event log of the billing application.';
					   |it = 'Ошибка при удалении настроек оплаты сервиса по причине:
					   |%1
					   |См. подробности в журнале регистрации приложения биллинга.';
					   |pl = 'An error occurred when deleting service payment settings. Reason:
					   |%1
					   |For more information, see the event log of the billing application.';
					   |tr = 'Servis Ödemeleri silinirken şu nedenle bir hata oluştu:
					   |%1
					   |Bkz. faturalama uygulama günlüğündeki ayrıntılar.'"),
			CloudTechnology.ShortErrorText(ErrorInfo));
	EndTry;
	
EndProcedure

// Handler for the background task of preparing an invoice for payment.
//
// Parameters:
//  QueryData - See InvoiceRequestData
//
Procedure PrepareInvoiceForPayment(QueryData) Export
	
	Try	
		InvoiceId = New UUID(QueryData.InvoiceId);
		
		// Creating an invoice for payment based on the request data.
		ProcessingResult = NewProcessingResult();
		ProformaInvoice = CreatePaymentInvoice(QueryData, ProcessingResult);
		If ProcessingResult.Error Then
			Data = ResponseDataTemplate(ReturnCodeDataError(), ProcessingResult.Message);
			SendResponseToBillingSystem(InvoiceId, Data);
			Return;
		EndIf; 
		
		// Receipt of a printed invoice form.
		ProcessingResult = NewProcessingResult();
		PrintForm = PrintedInvoiceForm(QueryData, ProformaInvoice, ProcessingResult);
		If Not PrintForm = Undefined Then
			Stream = New MemoryStream;
			PrintForm.Write(Stream, SpreadsheetDocumentFileType.MXL);
			BinaryData = Stream.CloseAndGetBinaryData();
			SetSafeModeDisabled(True);
			PlaceFileInInvoice(InvoiceId, BinaryData, "bill.mxl");
			SetSafeModeDisabled(False);
		ElsIf ProcessingResult.Error Then
			Data = ResponseDataTemplate(ReturnCodeDataError(), ProcessingResult.Message);
			SendResponseToBillingSystem(InvoiceId, Data);
			Return;
		EndIf;
		
		// Getting binary data of the invoice for payment.
		ProcessingResult = NewProcessingResult();
		InvoiceData = CustomerInvoiceDetails(QueryData, ProformaInvoice, ProcessingResult);
		If Not InvoiceData = Undefined Then
			SetSafeModeDisabled(True);
			PlaceFileInInvoice(InvoiceId, InvoiceData, "bill.zip");
			SetSafeModeDisabled(False);
		ElsIf ProcessingResult.Error Then
			Data = ResponseDataTemplate(ReturnCodeDataError(), ProcessingResult.Message);
			SendResponseToBillingSystem(InvoiceId, Data);
			Return;
		EndIf;
		
		If PrintForm = Undefined And InvoiceData = Undefined Then
			Raise StrTemplate(
				NStr("vi = 'Các phương thức định trước %1 và %2chưa đặt hoặc không trả lại dữ liệu.';
					|ru = 'Не заданы или не возвращают данных переопределяемые методы %1 и %2.';
					|en = 'The overridable %1 and %2 methods are not set or return no data.'; fa = 'The overridable %1 and %2 methods are not set or return no data.';
					|it = 'Dati dei metodi predefiniti %1 e %2 non indicati o non restituiti';
					|pl = 'Nie są zadane lub nie zwracają dane predefiniowane metody %1 i %2.';
					|tr = 'Overridable %1 ve %2 yöntemleri ayarlanmadı veya veri döndürmedi.'"),
				"ServicePaymentOverridable.OnGetProformaInvoicePrintForm",
				"ServicePaymentOverridable.OnGetProformaInvoiceDetails");
		EndIf;
			
		ProcessingResult = NewProcessingResult();
		PaymentURL = PaymentInvoiceLink(QueryData, ProformaInvoice, ProcessingResult);
		If ProcessingResult.Error Then
			Data = ResponseDataTemplate(ReturnCodeDataError(), ProcessingResult.Message);
			SendResponseToBillingSystem(InvoiceId, Data);
			Return;
		EndIf;
		
		Data = ResponseDataTemplate();
		Data.Insert("payment_link", PaymentURL);
		
		SendResponseToBillingSystem(InvoiceId, Data);
		
	Except
		ErrorInfo = ErrorInfo();
		EventName = EventLogEvent(NStr("vi = 'Soạn hóa đơn thanh toán';
										|ru = 'Подготовка счета на оплату';
										|en = 'Prepare a proforma invoice'; fa = 'Prepare a proforma invoice';
										|it = 'Predisposizione del conto per il pagamento';
										|pl = 'Przygotowanie rachunku do opłaty';
										|tr = 'Ticari fatura hazırlama'", Common.DefaultLanguageCode()));
		WriteLogEvent(EventName, EventLogLevel.Error, , ,
			CloudTechnology.DetailedErrorText(ErrorInfo));
		Data = ResponseDataTemplate(ReturnCodeInternalError(), CloudTechnology.ShortErrorText(ErrorInfo));
		SendResponseToBillingSystem(InvoiceId, Data);
		
	EndTry;
	
EndProcedure

// Returns the data of the invoice request for payment in a structured form.
// 
// Parameters:
//  Query - HTTPServiceRequest - request an invoice for payment from the service manager.
//
// Returns:
//  Structure - request data:
//   * InvoiceId - UUID - ID of the payment invoice
//   * SellerCode - Number - code of the subscriber-seller
//   * NameOfSeller - String - name of the subscriber-seller
//   * SellerPublicId - String - public tax ID (TIN) of the subscriber-seller
//   * SellerSMail - String - email address of the subscriber-seller
//   * BuyerSCode - Number - subscriber code, the buyer
//   * BuyerSName - String - name of the subscriber-buyer
//   * PublicBuyerID - String - public tax identifier (TIN) of the subscriber-buyer
//   * BuyerSMail - String - e-mail address of the subscriber-buyer
//   * BuyerSPhoneNumber - String - phone number of the subscriber-buyer
//   * AdditionalInformation - String - additional information about the payment invoice
//   * Renewal - Boolean - indication of the extension of the paid period 
//   * PaymentURL - String - payment invoice link
//   * Sum - Number - the amount of the invoice for payment (bit depth 31.2)
//   * ServicePlans - ValueTable:
//     ** ProviderServicePlanCode - String - provider's tariff code
//     ** ServiceProviderPlanCode - String - the code of the tariff of the service organization that overrides the provider's tariff
//     ** ValidityPeriodCode - String - code of the tariff validity period
//     ** Count - Number - number of tariffs (bit depth 10.0)
//     ** Sum - Number - the cost of the specified tariff validity period (bit depth 31.2)
//     ** NumberOfBaseDocument - String - the number of the subscription to the tariff for which the request was sent to the account
//   * Services - ValueTable:
//     ** OperationService - String - name of the service
//     ** Sum - Number - the cost of the service (bit depth 31.2).
//
Function InvoiceRequestData(Query) Export
	
	Data = JSONData(Query.GetBodyAsString());
		
	IsInternal = ServiceProgrammingInterfaceInternal;
	Result = IsInternal.RenameProperties(Data, RenamingRequestFields());
	Result.ServicePlans = IsInternal.StructuresArrayIntoValueTable(Result.ServicePlans, IsInternal.RenamingInvoice());
	Result.Services = IsInternal.StructuresArrayIntoValueTable(Result.Services, IsInternal.RenamingServiceAccount());
		
	Return Result; // @skip-check constructor-function-return-section

EndFunction

// Converts the passed value to a JSON string.
//
// Parameters:
//  Data - Structure - data.
// 
// Returns:
//  String - a string in JSON format.
//
Function JSONString(Data) Export
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, Data,, "ConvertingJSONData", ServicePayment);
	
	Return JSONWriter.Close();
	
EndFunction

// Converts a JSON string into a structure.
//
// Parameters:
//	String - String - string in JSON format
//	PropertiesWithDateValuesNames - Array of String - property names to convert to Date type values.
// 
// Returns:
//	Structure - data from the passed string.
Function JSONData(String, PropertiesWithDateValuesNames = Undefined) Export
	
	If IsBlankString(String) Then
		Return New Structure;
	EndIf; 
	
	If PropertiesWithDateValuesNames = Undefined Then
		PropertiesWithDateValuesNames = New Array;
	EndIf; 
	
	JSONReader = New JSONReader;
	JSONReader.SetString(String);
	
	If PropertiesWithDateValuesNames.Count() = 0 Then
		Response = ReadJSON(JSONReader); 
	Else
		Response = ReadJSON(JSONReader, , , , 
			"RestoringDateValue", ServicePayment, ,
			PropertiesWithDateValuesNames);
	EndIf;
	
	Return Response; // @skip-check constructor-function-return-section
	
EndFunction

// See the global context method - Write JSON, the Conversion functionname parameter.
// 
// Parameters:
//  Property - String
//  Value - Arbitrary
//  AdditionalParameters - Arbitrary
//  Cancel - Boolean
// 
// Returns:
//  String - JSON Data Conversion
Function ConvertingJSONData(Property, Value, AdditionalParameters, Cancel) Export
	
	If TypeOf(Value) = Type("Null") Then
		Cancel = True;
	ElsIf Common.IsReference(TypeOf(Value)) Then
		Return String(Value.UUID());
	ElsIf TypeOf(Value) = Type("UUID") Then
		Return String(Value);
	EndIf;
	
EndFunction

// Handler for restoring a Date type value when reading a JSON string.
// 
// Parameters:
//  Property - String - the name of the object's property.
//  Value - String, Number - the value obtained from the JSON string.
//  AdditionalParameters - Arbitrary - additional parameters of the handler.
// 
// Returns:
//  Date - the restored date value.
Function RestoringDateValue(Property, Value, AdditionalParameters) Export
	
	// Checking standard values 2018-01-01T00:00:00, 2018-01-01T00:00:00Z, 2018-01-01T00:00:00+0000
	If StrLen(Value) <= 24 And Mid(Value, 5, 1) = "-" And Mid(Value, 8, 1) = "-" And Mid(Value, 11, 1) = "T" Then
		Return XMLValue(Type("Date"), Value);
	EndIf; 
	
	// Restoring the date in the format dd.MM.yyyy
	PartsOfDateValue = StrSplit(Value, ".");
	If PartsOfDateValue.Count() >= 3 Then
		Return Date(Number(PartsOfDateValue[2]), Number(PartsOfDateValue[1]), Number(PartsOfDateValue[0]));
	EndIf;
	
	// Restoring the date in MM/dd/yyyy format
	PartsOfDateValue = StrSplit(Value, "/");
	If PartsOfDateValue.Count() >= 3 Then
		Return Date(Number(PartsOfDateValue[2]), Number(PartsOfDateValue[0]), Number(PartsOfDateValue[1]));
	EndIf;
	
	Return Value;
	
EndFunction

// Renaming request fields.
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String
//   * Value - See ServiceProgrammingInterfaceInternal.ColumnDetails
Function RenamingRequestFields() Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Renamings = New Map;
	Renamings.Insert("id", IsInternal.ColumnDetails("InvoiceId", New TypeDescription("UUID")));
	Renamings.Insert("seller_id", IsInternal.ColumnDetails("SellerCode", Common.StringTypeDetails(12)));
	Renamings.Insert("seller_name", IsInternal.ColumnDetails("NameOfSeller", Common.StringTypeDetails(64)));
	Renamings.Insert("seller_public_id", IsInternal.ColumnDetails("SellerPublicId", Common.StringTypeDetails(36)));
	Renamings.Insert("seller_email", IsInternal.ColumnDetails("SellerSMail", New TypeDescription("String")));
	Renamings.Insert("client_id", IsInternal.ColumnDetails("BuyerSCode", Common.StringTypeDetails(12)));
	Renamings.Insert("client_name", IsInternal.ColumnDetails("BuyerSName", Common.StringTypeDetails(64)));
	Renamings.Insert("client_public_id", IsInternal.ColumnDetails("PublicBuyerID", Common.StringTypeDetails(36)));
	Renamings.Insert("client_email", IsInternal.ColumnDetails("BuyerSMail", Common.StringTypeDetails(500)));
	Renamings.Insert("client_phone", IsInternal.ColumnDetails("BuyerSPhoneNumber", Common.StringTypeDetails(500)));
	Renamings.Insert("client_info", IsInternal.ColumnDetails("AdditionalInformation", New TypeDescription("String")));
	Renamings.Insert("renewal", IsInternal.ColumnDetails("Renewal", New TypeDescription("Boolean")));
	Renamings.Insert("payment_link",  IsInternal.ColumnDetails("PaymentURL", Common.StringTypeDetails(1024)));
	Renamings.Insert("total_cost",  IsInternal.ColumnDetails("Sum", Common.TypeDescriptionNumber(31, 2, AllowedSign.Nonnegative)));
	Renamings.Insert("tariffs", "ServicePlans");
	Renamings.Insert("services", "Services");
	
	Return Renamings;
	
EndFunction

Procedure LogHTTPRequest(Query, Response, BinaryData = False) Export
	
	LongDesc = QueryDetails(Query, BinaryData) + Chars.LF + "---" + Chars.LF + ResponseDescription(Response, BinaryData);
	WriteLogEvent(EventLogEvent(NStr("vi = 'Truy vấn HTTP';
									|ru = 'HTTP-запрос';
									|en = 'HTTP request'; fa = 'HTTP request';
									|it = 'HTTP-запрос';
									|pl = 'HTTP request';
									|tr = 'HTTP sorgu'")), EventLogLevel.Information,
		Metadata.HTTPServices.Billing, , LongDesc);
	
EndProcedure

// Add data headers.
// 
// Parameters:
//  Response - HTTPServiceResponse
Procedure AddDataHeaders(Response) Export
	
	Headers = Response.Headers;
	
	Headers.Insert("Accept", "application/json");
	Headers.Insert("Accept-Charset", "utf-8");
	Headers.Insert("Content-Type", "application/json; charset=utf-8");
	Headers.Insert("Cache-Control", "no-cache");
	
EndProcedure

// The owner of the authorization password in the service.
// 
// Parameters:
//  User - CatalogRef.Users
// 
// Returns:
//  String
Function OwnerOfAuthorizationPasswordInService(User) Export
	
	Return InformationRegisters.AuthorizationIn1cFresh.OwnerOfSecureStorage(User);
	
EndFunction

// The owner of the authorization password in the accounting system.
// 
// Returns:
//  String
Function OwnerOfAuthorizationPasswordInAccountSystem() Export
	
	Return Metadata.Constants.AccountSystemUserName.FullName();
	
EndFunction

#EndRegion

#Region Private

Function NewProcessingResult()
	
	ProcessingResult = New Structure;
	ProcessingResult.Insert("Error", False);
	ProcessingResult.Insert("Message", "");
	
	Return ProcessingResult;
	
EndFunction

Function AddressOfInvoicesForPaymentOfBillingSystem()
	
	Return "hs/ui/bills";
	
EndFunction

Function CreatePaymentInvoice(QueryData, ProcessingResult)

	ProformaInvoice = Undefined;
	
	ServicePaymentOverridable.OnCreateProformaInvoice(
		QueryData, ProformaInvoice, ProcessingResult);
		
	Return ProformaInvoice;

EndFunction

Function PrintedInvoiceForm(QueryData, ProformaInvoice, ProcessingResult)
	
	PrintForm = Undefined; // SpreadsheetDocument
	
	ServicePaymentOverridable.OnGetProformaInvoicePrintForm(
		QueryData, ProformaInvoice, PrintForm, ProcessingResult);
		
	Return PrintForm;
	
EndFunction

Function CustomerInvoiceDetails(QueryData, ProformaInvoice, ProcessingResult)
	
	Data = Undefined;
	
	ServicePaymentOverridable.OnGetProformaInvoiceDetails(
		QueryData, ProformaInvoice, Data, ProcessingResult);
		
	Return Data;
	
EndFunction

Function PaymentInvoiceLink(QueryData, ProformaInvoice, ProcessingResult)
	
	PaymentURL = "";
	
	ServicePaymentOverridable.OnGetPaymentURL(
			QueryData, ProformaInvoice, PaymentURL, ProcessingResult);	
	
	Return PaymentURL;
	
EndFunction
 
// @unavailable-in-safemode
Function PlaceFileInInvoice(InvoiceId, BinaryData, FileName)
	
	TokenParameters = ServiceProgrammingInterface.NewOptionsForGettingFileUploadCoupon();
	TokenParameters.InvoiceId = InvoiceId;
	TokenParameters.Size = BinaryData.Size();
	TokenParameters.FileName = FileName;
	TokenData = ServiceProgrammingInterface.InvoiceForPaymentAndDownloadCoupon(TokenParameters);
	Address = StrTemplate("hs/dt/upload/%1", TokenData.FileImportCoupon);
	SetPrivilegedMode(True);
	If SaaSOperations.DataSeparationEnabled() Then
		ServiceAddress = SaaSOperations.InternalServiceManagerURL();
	Else
		ServiceAddress = ServiceProgrammingInterfaceInternal.ServiceAddressFromLocalDatabase();
	EndIf;
	
	FullAddress = StrTemplate("%1/%2", ServiceAddress, Address);
	ServerData = CommonClientServer.URIStructure(FullAddress);
	
	If SaaSOperations.DataSeparationEnabled() Then
		Join = SaaSOperationsCTL.ConnectingToServiceManager(ServerData);
	Else
		Join = ServiceProgrammingInterfaceInternal.ConnectingToServiceManagerFromLocalDatabase(ServerData);
	EndIf; 
	
	HTTPRequest = New HTTPRequest;
	HTTPRequest.ResourceAddress = ServerData.PathAtServer;
	HTTPRequest.SetBodyFromBinaryData(BinaryData);
	HTTPRequest.Headers.Insert("IBSession", "start");
	HTTPRequest.Headers.Insert("Content-Range", 
		StrTemplate("bytes 0-%1/%2", Format(TokenParameters.Size - 1, "NG=0"), 
		Format(TokenParameters.Size, "NG=0")));
	
	Response = Join.CallHTTPMethod("PUT", HTTPRequest);
	
	If Response.StatusCode = 500 Then
		For Counter = 1 To 3 Do
			CommonCTL.Pause(Counter * 3);
			Response = Join.CallHTTPMethod("PUT", HTTPRequest);
			If Not Response.StatusCode = 201 Then
				Break;
			EndIf; 
		EndDo;
	EndIf;
	
	If Not Response.StatusCode = 201 Then
		LogHTTPRequest(HTTPRequest, Response, True);
		If Response.StatusCode = 500 Then
			ErrorText = StrTemplate(
				NStr("vi = 'Lỗi 500 khi gắn tệp vào hóa đơn thanh toán %1 do nguyên nhân: %2';
					|ru = 'Ошибка 500 при помещении файла в счет на оплату %1 по причине: %2';
					|en = 'Error 500 occurred when placing a file to the %1 proforma invoice due to: %2'; fa = 'Error 500 occurred when placing a file to the %1 proforma invoice due to: %2';
					|it = 'Errore 500 di posizionamento del file nella fattura di pagamento %1 a causa di: %2';
					|pl = 'Błąd 500 podczas przeniesienia pliku do rachunku do opłaty %1 z powodu: %2';
					|tr = 'Şu nedenle %1 faturaya dosya koyarken hata 500: %2'"),
				InvoiceId, Response.GetBodyAsString());
			Raise ErrorText;
		EndIf; 
	EndIf;
	
	Return Response;
	
EndFunction

#Region Logging

Function EventLogEvent(Refinement) Export

	Return StrTemplate("%1.%2", NStr("vi = 'Thanh toán dịch vụ';
									|ru = 'Оплата сервиса';
									|en = 'Service payments'; fa = 'پرداخت‌های سرویس';
									|it = 'Pagamento del servizio';
									|pl = 'Opłata usługi';
									|tr = 'Servis ödemeleri'", Common.DefaultLanguageCode()), Refinement);

EndFunction

Function BaseURL(HTTPServiceRequest)
	
	BaseURL = HTTPServiceRequest.Headers.Get("X-Forwarded-Path");
	If BaseURL = Undefined Then
		Return NormalizeAddress(HTTPServiceRequest.BaseURL);
	Else
		AddressParts = StrSplit(NormalizeAddress(HTTPServiceRequest.BaseURL), "/", False);
		Return AddressParts[0] + "//" + AddressParts[1] + BaseURL;
	EndIf;
	
EndFunction

Function NormalizeAddress(Address)
	
	AddressParts = StrSplit(Address, "/", False);
	
	Protocol = TrimAll(AddressParts[0]) + "//";
	AddressParts.Delete(0);
	
	NameParts = StrSplit(TrimAll(AddressParts[0]), ":");
	AddressParts.Delete(0);
	ServerName = NameParts[0];
	ServerPort = ?(NameParts.Count() = 1, "", TrimAll(NameParts[1]));
	If Protocol = "http://" Then
		ServerPort = ?(IsBlankString(ServerPort) Or ServerPort = "80", "", ":" + ServerPort);
	ElsIf Protocol = "https://" Then
		ServerPort = ?(IsBlankString(ServerPort) Or ServerPort = "443", "", ":" + ServerPort);
	Else
		Raise StrTemplate(NStr("vi = 'Giao thức không xác định: %1';
								|ru = 'Неизвестный протокол: %1';
								|en = 'Unknown protocol: %1'; fa = 'Unknown protocol: %1';
								|it = 'Protocollo sconosciuto: %1';
								|pl = 'Nieznany protokół: %1';
								|tr = 'Bilinmeyen protokol: %1'", 
			Common.DefaultLanguageCode()), Protocol);
	EndIf;
	
	Path = "/" + StrConcat(AddressParts, "/");
	
	Return Protocol + ServerName + ServerPort + Path;
	
EndFunction

Function QueryDetails(Query, BinaryData = False)
	
	QueryOptions = Undefined;
	If TypeOf(Query) = Type("HTTPServiceRequest") Then
		If Query.QueryOptions.Count() Then
			QueryOptions = New Array;
			For Each KeyAndValue In Query.QueryOptions Do
				QueryOptions.Add(KeyAndValue.Key + "=" + EncodeString(
					KeyAndValue.Value, StringEncodingMethod.URLEncoding));
			EndDo;
			QueryOptions = "?" + StrConcat(QueryOptions, "&");
		EndIf;
		Address = Query.HTTPMethod + " " + BaseURL(Query) + Query.RelativeURL + QueryOptions;
	Else
		Address = Query.ResourceAddress;
	EndIf;
	
	Headers = New Array;
	Asterisks = "***";
	For Each Title  In Query.Headers Do
		HeaderKey = Title.Key;
		HeaderValue = Title.Value;
		// For the Authorization header, we hide the password value.
		If Lower(HeaderKey) = "authorization" And Not IsBlankString(HeaderValue) Then
			PartsOfTheValue = StrSplit(HeaderValue, " ");
			If PartsOfTheValue.Count() = 1 Then
				PartsOfTheValue[0] = Asterisks;
			ElsIf Lower(PartsOfTheValue[0]) = "basic" Then
				Try
					UsernamePassword = GetStringFromBinaryData(Base64Value(PartsOfTheValue[1]));
					LoginPasswordParts = StrSplit(UsernamePassword, ":");
					If LoginPasswordParts.Count() >= 2 Then
						LoginPasswordParts[1] = Asterisks;
						PartsOfTheValue[1] = StrConcat(LoginPasswordParts, ":");
					Else
						PartsOfTheValue[1] = Asterisks;
					EndIf;
				Except
					PartsOfTheValue[1] = Asterisks;
				EndTry;
			Else
				PartsOfTheValue[1] = Asterisks;
			EndIf;
			HeaderValue = StrConcat(PartsOfTheValue, " ");
		EndIf;
		Headers.Add(StrTemplate("%1: %2", HeaderKey, HeaderValue));
	EndDo;
	
	If BinaryData Then
		RequestBody = GetBase64StringFromBinaryData(Query.GetBodyAsBinaryData());
	Else
		RequestBody = Query.GetBodyAsString();
	EndIf; 
	
	If StrLen(RequestBody) > 1000 Then
		RequestBody = StrTemplate(NStr("vi = '%1...';
										|ru = '%1...';
										|en = '%1...'; fa = '%1...';
										|it = '%1...';
										|pl = '%1...';
										|tr = '%1...'"), Left(RequestBody, 1000));
	EndIf; 
	
	Return StrTemplate(
		"%1
		|%2
		|
		|%3", Address, 
		StrConcat(Headers, Chars.LF), RequestBody);
	
EndFunction

Function ResponseDescription(Response, BinaryData = False)
	
	Headers = New Array;
	For Each Title  In Response.Headers Do
		Headers.Add(StrTemplate("%1: %2", Title.Key, Title.Value));
	EndDo; 
	
	If TypeOf(Response) = Type("HTTPServiceResponse") Then
		StatusCode = StrTemplate("%1 %2", Response.StatusCode, Response.Reason);
	Else
		StatusCode = Response.StatusCode
	EndIf; 
	
	If BinaryData Then
		ResponseBody = GetBase64StringFromBinaryData(Response.GetBodyAsBinaryData());
	Else
		ResponseBody = Response.GetBodyAsString();
	EndIf; 

	If StrLen(ResponseBody) > 1000 Then
		ResponseBody = StrTemplate(NStr("vi = '%1...';
										|ru = '%1...';
										|en = '%1...'; fa = '%1...';
										|it = '%1...';
										|pl = '%1...';
										|tr = '%1...'"), Left(ResponseBody, 1000));
	EndIf; 
	
	
	Return StrTemplate(
		"%1
		|%2
		|
		|%3", 
		StatusCode,
		StrConcat(Headers, Chars.LF), Response.GetBodyAsString());
	
EndFunction

#EndRegion

#EndRegion
