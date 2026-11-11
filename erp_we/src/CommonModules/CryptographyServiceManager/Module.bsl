////////////////////////////////////////////////////////////////////////////////
// Subsystem "Cryptography service Manager".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ConnectionApplication

// Send an application for activation
//
// Parameters:
//  ApplicationForm_ - Structure - statement.
// 
// Returns:
//  Structure - Result:
//  * Completed2 - Boolean
//  * ErrorCode - String
//  * ErrorDescription - String
//
Function SendApplicationForActivation(ApplicationForm_) Export
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/requests/%1/request_sender", SoftwareInterfaceVersion_v2_0());
	SetSafeModeDisabled(False);
	
	QueryOptions = ApplicationForm_;
	QueryOptions.Insert("client", GetClientDescription());
	
	ResponseFields = New Structure("req_id", "Id");
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);

EndFunction

// Form an application for signing
//
// Parameters:
//  ApplicationForm_ - Structure - statement.
// 
// Returns:
//  Structure - Result:
//  * Completed2 - Boolean
//  * ErrorCode - String
//  * ErrorDescription - String
//
Function FormApplicationForSigning(ApplicationForm_) Export
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/requests/%1/request", SoftwareInterfaceVersion_v2_0());
	SetSafeModeDisabled(False);
	
	QueryOptions = ApplicationForm_;
	QueryOptions.Insert("client", GetClientDescription());
	
	ResponseFields = New Structure("req_id, request", "Id", "ApplicationForm_");
	ConversionParameters = New Structure("PropertiesToReviveNames", StrSplit("request", ","));
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields,, ConversionParameters);

EndFunction

// Send a signed application
//
// Parameters:
//  ApplicationForm_ - Structure - statement.
// 
// Returns:
//  Structure - Result:
//  * Completed2 - Boolean
//  * ErrorCode - String
//  * ErrorDescription - String
//
Function SendSignedStatement(ApplicationForm_) Export
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/requests/%1/signed_request_sender", SoftwareInterfaceVersion_v2_0());
	SetSafeModeDisabled(False);
	
	QueryOptions = ApplicationForm_;
	QueryOptions.Insert("client", GetClientDescription());
	
	ResponseFields = New Structure;
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);

EndFunction

// Function-Get the status of the connection request
//
// Parameters:
//  ApplicationID - String - ID of the application.
// 
// Returns:
//  Structure - Result:
//  * Completed2 - Boolean
//  * ErrorCode - String
//  * ErrorDescription - String
///
Function GetStatusOfActivationRequest(ApplicationID) Export
	
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/requests/%1/request/%2",
										SoftwareInterfaceVersion_v1_1(),
										ApplicationID);
	SetSafeModeDisabled(False);
										
	ResponseFields = New Structure();
	ResponseFields.Insert("status", "Status");
	ResponseFields.Insert("details", "Explanation");
	ResponseFields.Insert("token_id", "CertificateID");
	ResponseFields.Insert("token_value", "Token");
	
	Return CallHTTPMethod("GET", URL, Undefined, ResponseFields);

EndFunction

#EndRegion

#Region PhoneAndEmailVerification

// Get the phone verification code
//
// Parameters:
//  Phone - String - telephone,
//  Id - String - ID.
// 
// Returns:
//  Structure - result, fields:
// 	 * Id - String - 
// 	 * CodeNumber - Number - 
// 	 * CodeValidityPeriod - Number - 
// 	 * DelayBeforeResending - Number -  
Function GetPhoneVerificationCode(Phone, Id = "") Export
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/verification/%1/phone/code", SoftwareInterfaceVersion_v1_1());
	SetSafeModeDisabled(False);
	
	QueryOptions = New Structure("phone,req_id,repeat", Phone, Id, ValueIsFilled(Id));
	
	ResponseFields = New Structure;
	ResponseFields.Insert("req_id", "Id");
	ResponseFields.Insert("num", "CodeNumber");
	ResponseFields.Insert("life_time", "CodeValidityPeriod");
	ResponseFields.Insert("delay", "DelayBeforeResending");
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);

EndFunction

// Check phone number by code
//
// Parameters:
//  Id - String - ID,
//  Code - String - code.
// 
// Returns:
//  Structure - Result:
//  * Completed2 - Boolean
//  * ErrorCode - Number
//  * ErrorDescription - String
///
Function CheckPhoneNumberByCode(Id, Code) Export
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/verification/%1/phone", SoftwareInterfaceVersion_v1_1());
	SetSafeModeDisabled(False);
	
	QueryOptions = New Structure("req_id,code", Id, Code);
	
	ResponseFields = New Structure;
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);
	
EndFunction

// To receive the verification code email
//
// Parameters:
//  Email - String - Email,
//  Id - String - ID.
// 
// Returns:
//  Structure - Result:
//   * Id - String - 
//	 * CodeNumber - Number - 
//	 * CodeValidityPeriod - Number - 
//	 * DelayBeforeResending - Number -  
Function GetEmailVerificationCode(Email, Id = "") Export
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/verification/%1/email/code", SoftwareInterfaceVersion_v1_1());
	SetSafeModeDisabled(False);
	
	QueryOptions = New Structure("email,req_id,repeat", Email, Id, ValueIsFilled(Id));
	
	If Not Common.SubsystemExists("RegulatedReporting.ElectronicDocumentManagementWithRegulatoryAuthorities") Then
		QueryOptions.Insert("subject", NStr("vi = 'Mã kiểm tra xác nhận thư điện tử trong 1C';
											|ru = 'Проверочный код подтверждения электронной почты в 1С';
											|en = 'Email confirmation code in 1C'; fa = 'Email confirmation code in 1C';
											|it = 'Codice di conferma della email in 1C';
											|pl = 'Kod kontrolny potwierdzenia poczty elektronicznej w 1C';
											|tr = '1C e-posta doğrulama kodu'"));
	EndIf;

	ResponseFields = New Structure;
	ResponseFields.Insert("req_id", "Id");
	ResponseFields.Insert("num", "CodeNumber");
	ResponseFields.Insert("life_time", "CodeValidityPeriod");
	ResponseFields.Insert("delay", "DelayBeforeResending");
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);
	
EndFunction

// Check your email for the code
//
// Parameters:
//  Id - String - ID,
//  Code - String - code.
// 
// Returns:
//  Structure - Result:
//  * Completed2 - Boolean
//  * ErrorCode - Number
//  * ErrorDescription - String
///
Function CheckEmailByCode(Id, Code) Export
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/verification/%1/email", SoftwareInterfaceVersion_v1_1());
	SetSafeModeDisabled(False);
	
	QueryOptions = New Structure("req_id,code", Id, Code);
	
	ResponseFields = New Structure;
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);

EndFunction

#EndRegion

#Region ChangingSettingsForReceivingTemporaryPasswordsByProvider

// Print your application
//
// Parameters:
//  ApplicationID - String - the ID of the application,
//  CheckID - String - verification ID,
//  CertificateID - String - ID of the certificate.
// 
// Returns:
//  Structure - Result:
//  * Completed2 - Boolean
//  * ErrorCode - Number
//  * ErrorDescription - String
//
Function PrintStatement(ApplicationID, CheckID, CertificateID) Export
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/otp/%1/phone/request/%2",
										SoftwareInterfaceVersion_v1_1(),
										ApplicationID);
	SetSafeModeDisabled(False);									
										
	QueryOptions = New Structure("client", GetClientDescription());
	QueryOptions.Insert("phone", CheckID);
	QueryOptions.Insert("cert_id", CertificateID);
	
	Result = CallHTTPMethod("POST", URL, QueryOptions, New Structure);
	If Result.Completed2 Then
		TempFileName = GetTempFileName("mxl");
		ResultData = Result.File; // BinaryData
		ResultData.Write(TempFileName);
		
		SpreadsheetDocument = New SpreadsheetDocument;
		SpreadsheetDocument.Read(TempFileName);
		
		DeleteFiles(TempFileName);
		
		Result.File = SpreadsheetDocument;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Send an application
//
// Parameters:
//  ApplicationID - String - the ID of the application,
//  ApplicationFile - String - application file.
// 
// Returns:
//  Structure - Result:
//  * Completed2 - Boolean
//  * ErrorCode - Number
//  * ErrorDescription - String
//
Function SendApplication(ApplicationID, ApplicationFile) Export
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/otp/%1/phone/request/%2",
										SoftwareInterfaceVersion_v1_1(),
										ApplicationID);
	SetSafeModeDisabled(False);
										
	Headers = New Map;
	Headers.Insert("Content-Disposition", 
		StrTemplate("attachment; filename=%1", EncodeString(ApplicationFile.Name, StringEncodingMethod.URLEncoding)));
		
	Result = CallHTTPMethod("PUT", URL, GetFromTempStorage(ApplicationFile.Address), New Structure, Headers);
	
	Return Result;
	
EndFunction

#EndRegion

#Region ChangingSettingsForObtainingTemporaryPasswordsByUser

// Start changing settings for getting temporary passwords
//
// Parameters:
//  CertificateID - String - the certificate ID,
//  Phone - String - telephone,
//  Email - String - Email,
//  Id - String - ID.
// 
// Returns:
//  Structure - result, fields:
// 	 * Id - String - 
// 	 * CodeValidityPeriod - Number - 
// 	 * DelayBeforeResending - Number -  
Function StartChangingSettingsForGettingTemporaryPasswords(CertificateID, Phone, Email, Id = "") Export
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/otp/%1/users_requests", SoftwareInterfaceVersion_v1_1());
	SetSafeModeDisabled(False);
	
	QueryOptions = New Structure("client", GetClientDescription());
	If ValueIsFilled(Id) Then
		QueryOptions.Insert("req_id", Id);
	Else
		QueryOptions.Insert("cert_id", CertificateID);
		If Phone <> Undefined Then
			QueryOptions.Insert("phone", Phone);
		EndIf;
		If Email <> Undefined Then
			QueryOptions.Insert("email", Email);
		EndIf;
	EndIf;

	ResponseFields = New Structure("req_id,life_time,delay", "Id", "CodeValidityPeriod", "DelayBeforeResending");
	
	Return CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);
	
EndFunction

// Finish changing the settings for getting temporary passwords
//
// Parameters:
//  Id - String - ID,
//  Code - String - code.
// 
// Returns:
//  Structure - Result:
//  * Completed2 - Boolean
//  * ErrorCode - Number
//  * ErrorDescription - String
//
Function FinishChangingSettingsForGettingTemporaryPasswords(Id, Code) Export
			
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/otp/%1/user_request/%2", SoftwareInterfaceVersion_v1_1(), Id);
	SetSafeModeDisabled(False);
										
	QueryOptions = New Structure("req_id,code", Id, Code);
	
	Return CallHTTPMethod("PUT", URL, QueryOptions, New Structure);
	
EndFunction

#EndRegion

#Region CertificateApplications

// Creates a private key and certificate request container
//
// Parameters:
//	StatementParameters - Structure - Contains fields for generating a certificate application:
// 	 * ApplicationID   - String - ID of the certificate request search.
//	 * RequestContent 		- String - contains the OID fields.
//	 * PhoneNumber			- String - contains the ID of the confirmed phone number
//	 * Email			- String - contains the ID of the verified mail
//	 * NotaryLawyerHeadOfFarm	- Boolean - 
//	 * SubscriberID	- String - ID.
//	ResultAddress - String - the address of the temporary storage where the result of the Structure function is laid out.
// 
Procedure CreateContainerAndRequestCertificate(StatementParameters, ResultAddress) Export
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/certificate/new_request/%1", StatementParameters.ApplicationID);
	SetSafeModeDisabled(False);
	
	EncodedString 	= XDTOSerializer.XMLString(New ValueStorage(StatementParameters.RequestContent));
	QueryOptions 	= New Structure();
	QueryOptions.Insert("NotaryLawyerHeadOfFarm", StatementParameters.NotaryLawyerHeadOfFarm);
	QueryOptions.Insert("SubscriberID", StatementParameters.SubscriberID);
	QueryOptions.Insert("Email", StatementParameters.Email);
	QueryOptions.Insert("CellPhone", StatementParameters.PhoneNumber);
	QueryOptions.Insert("RequestContent", EncodedString);
	QueryOptions.Insert("client", GetClientDescription());
	
	ResponseFields 				= New Structure("request, public_key, provider, provtype", 
												"CertificateRequest", "PublicKey", "ProviderName", "ProviderType");
	ConversionParameters = New Structure("PropertiesToReviveNames", StrSplit("request,public_key", ","));
	Result				= CallHTTPMethod("PUT", URL, QueryOptions, ResponseFields, , ConversionParameters);
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure	

// Binds the certificate to the private key in the cloud storage
//
// Parameters:
//  StatementParameters - Structure - Contains fields for generating a certificate application:
//   * ApplicationID   - String - ID of the certificate request search
//   * CertificateData - BinaryData - contains the certificate data in PEM encoding.
//
//  ResultAddress - String - the address of the temporary storage where the result of the Structure function is laid out.
//
Procedure BindCertToContainerAndSystemStore(StatementParameters, ResultAddress) Export
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/certificate/initialize_request/%1", StatementParameters.ApplicationID);
	SetSafeModeDisabled(False);
	
	CertificateData		= CertificatesStorage.DERCertificate(StatementParameters.CertificateData, Chars.LF);
	QueryOptions 		= New Structure("data", CertificateData);
	ConversionParameters = New Structure("PropertiesToReviveNames", StrSplit("data", ","));
	
	ResponseFields 	= New Structure("success", "Success");
	Result	= CallHTTPMethod("PUT", URL, QueryOptions, ResponseFields, , ConversionParameters);
	
	Try
		If Result.Completed2 Then
			CertificatesStorage.Add(CertificateData, Enums.CertificatesStorageType.PersonalCertificates);	
		EndIf;
	Except
		Result.Completed2 = False;
		Result.Insert("ErrorCode", "ErrorAccessingServer");
		Result.Insert("ErrorDescription", CloudTechnology.ShortErrorText(ErrorInfo()));
		// @skip-check module-nstr-camelcase - verification error
		WriteLogEvent(
			NStr("vi = 'Chữ ký điện tử trong mô hình dịch vụ.Bộ quản lý dịch vụ mã hóa';
				|ru = 'Электронная подпись в модели сервиса.Менеджер сервиса криптографии';
				|en = 'Digital signature SaaS.Cryptography service manager'; fa = 'Digital signature SaaS.Cryptography service manager';
				|it = 'Firma elettronica nel modello di servizio.Responsabile del servizio di crittografia';
				|pl = 'Podpis elektroniczny w modelu serwisu.Menedżer serwisu kryptografii';
				|tr = 'Dijital İmzalar Saas. Kriptografi servisi yöneticisi'", Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,, CloudTechnology.DetailedErrorText(ErrorInfo()));
	EndTry;	
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

#EndRegion

#Region SubscriberCertificatesByVerificationIDTIN

// Certificates of the subscriber ID check INN
// 
// Parameters: 
//  TIN - String
//  Id - String
//  OnlyValidOnes - Boolean - Only active users
// 
// Returns: 
//  Structure - Certificates of the subscriber ID check INN:
// * Certificates - Array of Structure:
// 	  ** ID - String
// or, if an error occurs 
// * ErrorDescription - String
// * ErrorCode - String
// * Completed2 - Boolean
Function SubscriberCertificatesByVerificationIDTIN(TIN, Id, OnlyValidOnes = True) Export
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/requests/%1/abonent_certificates", SoftwareInterfaceVersion_v2_0());
	SetSafeModeDisabled(False);
	
	QueryOptions = New Structure("client", GetClientDescription());
	QueryOptions.Insert("req_id", Id);
	QueryOptions.Insert("inn", TIN);
	QueryOptions.Insert("valid", OnlyValidOnes);

	ResponseFields = New Structure("certificates", "Certificates");
	
	Result = CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);
	
	If Result.Completed2 Then 
		For Each Certificate In Result.Certificates Do 
			Certificate.ValidTo = XMLValue(Type("Date"), Certificate.ValidTo);
			Certificate.ValidFrom = XMLValue(Type("Date"), Certificate.ValidFrom);
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region CertificateSearch

// Search for the certificate by fingerprint or serial number.
// 
// Parameters: 
//  Thumbprint - String
//  SerialNumber - String
//  Abbreviated - Boolean
// 
// Returns: 
//  Structure :
// * Completed2 - Boolean
// * ErrorCode - String
// * ErrorDescription - String
Function SearchForCertificateByFingerprintOrSerialNumber(
			Thumbprint = Undefined, 
			SerialNumber = Undefined, 
			Abbreviated = False) Export
	
	SetSafeModeDisabled(True);
	URL = ServiceAddress() + StrTemplate("/hs/requests/%1/find_certificate", SoftwareInterfaceVersion_v2_0());
	SetSafeModeDisabled(False);
	
	QueryOptions = New Structure("client", GetClientDescription());
	If ValueIsFilled(Thumbprint) Then 
		QueryOptions.Insert("thumbprint", Thumbprint);
	EndIf;
	If ValueIsFilled(SerialNumber) Then 
		QueryOptions.Insert("serialnumber", SerialNumber);
	EndIf;
	If Abbreviated Then 
		QueryOptions.Insert("important_only", True);
	EndIf;
	
	If Not ValueIsFilled(Thumbprint) And Not ValueIsFilled(SerialNumber) Then 
		Return New Structure("Completed2, ErrorCode, ErrorDescription", 
						False, 
						"ParametersNotFilledIn", 
						NStr("vi = 'Cần điền vào thumbprint hoặc serialnumber.';
							|ru = 'Необходимо заполнить thumbprint или serialnumber.';
							|en = 'Fill in thumbprint or serialnumber.'; fa = 'Fill in thumbprint or serialnumber.';
							|it = 'È necessario compilare thumbprint o serialnumber.';
							|pl = 'Należy wypełnić thumbprint albo serialnumber.';
							|tr = 'Thumbprint veya serialnumber doldurulması zorunlu.'", Common.DefaultLanguageCode()));
	EndIf;
	
	ResponseFields = New Structure("certificates", "Certificates");
	
	Result = CallHTTPMethod("POST", URL, QueryOptions, ResponseFields);
	
	If Result.Completed2 Then 
		For Each Certificate In Result.Certificates Do 
			If Not Certificate.Property("ValidTo") Then 
				Continue;
			EndIf;
			Certificate.ValidTo = XMLValue(Type("Date"), Certificate.ValidTo);
			Certificate.ValidFrom = XMLValue(Type("Date"), Certificate.ValidFrom);
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function GetClientDescription()
	
	ClientDescription = New Structure;
	ClientDescription.Insert("version", Metadata.Version);
	ClientDescription.Insert("name", Metadata.Name);
	ClientDescription.Insert("id", Format(SaaSOperations.SessionSeparatorValue(), "NG="));
	
	Return ClientDescription;
	
EndFunction

// To obtain connection parameters
// 
// Parameters:
//  URL - String
// 
// Returns: See CommonClientServer.URIStructure
Function GetConnectionParameters(URL) Export
	
	ConnectionParameters = CommonClientServer.URIStructure(URL);
	ConnectionParameters.Schema = ?(ValueIsFilled(ConnectionParameters.Schema), ConnectionParameters.Schema, "http");	
	ConnectionParameters.Insert("Timeout", 180);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID(Metadata.Constants.DigitalSignatureAddingServiceAddressSaaS);
	ConnectionParameters.Insert("Login", Common.ReadDataFromSecureStorage(Owner, "Login", True));
	ConnectionParameters.Insert("Password", Common.ReadDataFromSecureStorage(Owner, "Password", True));
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Return ConnectionParameters;
	
EndFunction

// @unavailable-in-safemode
Function ServiceAddress()
	
	SetPrivilegedMode(True);
	Return Constants.DigitalSignatureAddingServiceAddressSaaS.Get();
	
EndFunction

Function SoftwareInterfaceVersion_v1_1()
	
	Return "v1.1";
	
EndFunction

Function SoftwareInterfaceVersion_v2_0()
	
	Return "v2.0";
	
EndFunction

Function CallHTTPMethod(HTTPMethod, URL, QueryOptions, MatchingResponseFields, Headers = Undefined, ConversionParameters = Undefined)
	
	Result = New Structure;	
	
	ConnectionParameters = GetConnectionParameters(URL);
	Try
		Join = DigitalSignatureSaaS.ConnectingToInternetServer(ConnectionParameters);
	Except
		ErrorInfo = ErrorInfo();
		// @skip-check module-nstr-camelcase - verification error
		WriteLogEvent(
			NStr("vi = 'Chữ ký điện tử trong mô hình dịch vụ.Bộ quản lý dịch vụ mã hóa';
				|ru = 'Электронная подпись в модели сервиса.Менеджер сервиса криптографии';
				|en = 'Digital signature SaaS.Cryptography service manager'; fa = 'Digital signature SaaS.Cryptography service manager';
				|it = 'Firma elettronica nel modello di servizio.Responsabile del servizio di crittografia';
				|pl = 'Podpis elektroniczny w modelu serwisu.Menedżer serwisu kryptografii';
				|tr = 'Dijital İmzalar Saas. Kriptografi servisi yöneticisi'", Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,, CloudTechnology.DetailedErrorText(ErrorInfo));
			
		Result.Insert("Completed2", False);
		Result.Insert("ErrorCode", "CouldnTEstablishConnection");
		Result.Insert("ErrorDescription", NStr("vi = 'Không thể cài đặt kết nối với máy chủ.';
												|ru = 'Не удалось установить соединение с сервером.';
												|en = 'Cannot connect to the server.'; fa = 'Cannot connect to the server.';
												|it = 'Non è stato possibile stabilire la connessione con il server.';
												|pl = 'Nie udało się uzyskać połączenie z serwerem.';
												|tr = 'Sunucu ile bağlantı kurulamıyor'"));		
		Return Result;
	EndTry;

	Query = New HTTPRequest(ConnectionParameters.PathAtServer);
	If TypeOf(QueryOptions) = Type("Structure") Then
		Query.Headers.Insert("Content-Type", "application/json");
		Query.SetBodyFromString(DigitalSignatureSaaS.StructureInJSON(QueryOptions));
	ElsIf TypeOf(QueryOptions) = Type("BinaryData") Then
		Query.Headers.Insert("Content-Type", "application/octet-stream");
		Query.SetBodyFromBinaryData(QueryOptions);
	EndIf;
	If ValueIsFilled(Headers) Then
		For Each Title In Headers Do
			Query.Headers.Insert(Title.Key, Title.Value);
		EndDo;
	EndIf;
	
	Try
		Response = Join.CallHTTPMethod(HTTPMethod, Query);
	Except
		ErrorInfo = ErrorInfo();
		// @skip-check module-nstr-camelcase - verification error
		WriteLogEvent(
			NStr("vi = 'Chữ ký điện tử trong mô hình dịch vụ.Bộ quản lý dịch vụ mã hóa';
				|ru = 'Электронная подпись в модели сервиса.Менеджер сервиса криптографии';
				|en = 'Digital signature SaaS.Cryptography service manager'; fa = 'Digital signature SaaS.Cryptography service manager';
				|it = 'Firma elettronica nel modello di servizio.Responsabile del servizio di crittografia';
				|pl = 'Podpis elektroniczny w modelu serwisu.Menedżer serwisu kryptografii';
				|tr = 'Dijital İmzalar Saas. Kriptografi servisi yöneticisi'", Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,, CloudTechnology.DetailedErrorText(ErrorInfo));
		
		Result.Insert("Completed2", False);
		Result.Insert("ErrorCode", "ErrorAccessingServer");
		Result.Insert("ErrorDescription", CloudTechnology.DetailedErrorText(ErrorInfo));		
		Return Result;
	EndTry;

	If Response.StatusCode = 200 Then
		Result.Insert("Completed2", True);
		
		ContentType = CommonCTLClientServer.HTTPHeader(Response, "Content-Type");
		
		If (ContentType = "application/json") Or (ContentType = "application/javascript") Then
			AnswerParameters = DigitalSignatureSaaS.JSONToStructure(Response.GetBodyAsString(), ConversionParameters);
			For Each Field In MatchingResponseFields Do
				If AnswerParameters.Property(Field.Key) Then
					Result.Insert(Field.Value, AnswerParameters[Field.Key]);
				EndIf;
			EndDo;
		ElsIf ContentType = "application/octet-stream" Then
			Result.Insert("File", Response.GetBodyAsBinaryData());
			Result.Insert("Name", StrReplace(CommonCTLClientServer.HTTPHeader(Response, "Content-Disposition"), "attachment; filename=", ""));
		EndIf;
	ElsIf Response.StatusCode = 400 Then
		Result.Insert("Completed2", False);
		AnswerParameters = DigitalSignatureSaaS.JSONToStructure(Response.GetBodyAsString());
		Result.Insert("ErrorCode", GetErrorCode(AnswerParameters.err_code));
		Result.Insert("ErrorDescription", TrimAll(AnswerParameters.err_msg));
	Else
		// @skip-check module-nstr-camelcase - verification error
		WriteLogEvent(
			NStr("vi = 'Chữ ký điện tử trong mô hình dịch vụ.Bộ quản lý dịch vụ mã hóa';
				|ru = 'Электронная подпись в модели сервиса.Менеджер сервиса криптографии';
				|en = 'Digital signature SaaS.Cryptography service manager'; fa = 'Digital signature SaaS.Cryptography service manager';
				|it = 'Firma elettronica nel modello di servizio.Responsabile del servizio di crittografia';
				|pl = 'Podpis elektroniczny w modelu serwisu.Menedżer serwisu kryptografii';
				|tr = 'Dijital İmzalar Saas. Kriptografi servisi yöneticisi'", Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,, Response.GetBodyAsString());
		Result.Insert("Completed2", False);
		Result.Insert("ErrorCode", "UnknownError");
		Result.Insert("ErrorDescription", NStr("vi = 'Tạm thời không sử dụng được dịch vụ. Hãy liên hệ với bộ phận hỗ trợ hoặc thử lại sau.';
												|ru = 'Сервис временно недоступен. Обратитесь в службу поддержки или повторите попытку позже.';
												|en = 'The service is temporarily unavailable. Contact the technical support or try again later.'; fa = 'The service is temporarily unavailable. Contact the technical support or try again later.';
												|it = 'Servizio momentaneamente non disponibile. Rivolgersi al centro assistenza o ripetere più tardi.';
												|pl = 'Serwis tymczasowo jest niedostępny. Zwróć się do służby pomocy lub powtórz próbę później.';
												|tr = 'Hizmet geçici olarak kullanılamıyor. Lütfen destekle iletişime geçin veya daha sonra tekrar deneyin.'"));
	EndIf;
	
	Return Result;
	
EndFunction

Function GetErrorCode(err_code)
	
	ErrorCodes = New Map;
	ErrorCodes.Insert("CertificateNotFound", "CertificateNotFound");
	ErrorCodes.Insert("RequestNotFound", "ApplicationNotFound");
	ErrorCodes.Insert("NewPhoneIsEqualToTheCurrent", "NewPhoneIsEqualToCur");
	ErrorCodes.Insert("NewEmailIsEqualToTheCurrent", "NewEmailIsEqualToCur");
	ErrorCodes.Insert("MaxAttemptsInputCodeExceeded", "CodeAttemptLimitExceeded");
	ErrorCodes.Insert("CodeExpired", "CodeExpired");
	ErrorCodes.Insert("CodeIsWrong", "InvalidCode");
	ErrorCodes.Insert("TooFrequentCodeRequests", "ReSendingTooOften");
	
	ErrorCode = ErrorCodes.Get(err_code);
	If Not ValueIsFilled(ErrorCode) Then
		ErrorCode = err_code;
	EndIf;
	
	Return ErrorCode;
	
EndFunction

#EndRegion

