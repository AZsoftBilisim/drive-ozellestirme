////////////////////////////////////////////////////////////////////////////////
// Subsystem "Cryptography service (service)".
//  
////////////////////////////////////////////////////////////////////////////////
//


#Region Internal

Procedure Encrypt(Parameters, ResultAddress, AdditionalResultAddress = Undefined) Export
	
	Result = CryptographyService.Encrypt(
		Parameters.Data,
		Parameters.Recipients, 
		Parameters.EncryptionType, 
		Parameters.EncryptionParameters);
		
	If Parameters.ReturnResultAsAddressInTemporaryStorage  Then
		If TypeOf(Result) = Type("Array") Then 
			For IndexOf = 0 To Result.UBound() Do
				If IsTempStorageURL(Result[IndexOf]) Then //The server will return the addresses, you need to shift
					EncryptedData = GetFromTempStorage(Result[IndexOf]);
					DeleteFromTempStorage(Result[IndexOf]);
					Result[IndexOf] = EncryptedData;
				EndIf;
				Result[IndexOf] = PutToTempStorage(Result[IndexOf], Parameters.ResultFileAddresses[IndexOf]);
			EndDo;
		ElsIf TypeOf(Result) <> Type("Structure") Then 
			Result = PutToTempStorage(Result, Parameters.ResultFileAddresses[0]);			
		EndIf;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure EncryptBlock(Parameters, ResultAddress, AdditionalResultAddress = Undefined) Export
	
	Result = CryptographyService.EncryptBlock(
		Parameters.Data,
		Parameters.Recipient);
		
	If Parameters.ReturnResultAsAddressInTemporaryStorage  Then
		Result = PutToTempStorage(Result, Parameters.AddressOfResultFile);
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure Decrypt(Parameters, ResultAddress, AdditionalResultAddress = Undefined) Export
	
	If Parameters.Property("SecurityTokens") Then 
		SetSafeModeDisabled(True);
		InstallSecurityMarkers(Parameters.SecurityTokens);
		SetSafeModeDisabled(False);
	EndIf;

	Result = CryptographyService.Decrypt(
		Parameters.EncryptedData,
		Parameters.Certificate, 
		Parameters.EncryptionType, 
		Parameters.EncryptionParameters);
		
	If Parameters.ReturnResultAsAddressInTemporaryStorage  Then
		If TypeOf(Result) <> Type("Structure") Then 
			Result = PutToTempStorage(Result, Parameters.ResultFileAddresses[0]);			
		EndIf;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
		
EndProcedure

Procedure DecryptBlock(Parameters, ResultAddress, AdditionalResultAddress = Undefined) Export
	
	If Parameters.Property("SecurityTokens") Then 
		SetSafeModeDisabled(True);
		InstallSecurityMarkers(Parameters.SecurityTokens);
		SetSafeModeDisabled(False);
	EndIf;

	Result = CryptographyService.DecryptBlock(
		Parameters.EncryptedData,
		Parameters.Recipient, 
		Parameters.KeyInformation, 
		Parameters.EncryptionParameters);
		
	If Parameters.ReturnResultAsAddressInTemporaryStorage  Then
		If TypeOf(Result) <> Type("Structure") Then 
			Result = PutToTempStorage(Result, Parameters.AddressOfResultFile);			
		EndIf;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
		
EndProcedure

Procedure Sign(Parameters, ResultAddress, AdditionalResultAddress = Undefined) Export
	
	If Parameters.Property("SecurityTokens") Then 
		SetSafeModeDisabled(True);
		InstallSecurityMarkers(Parameters.SecurityTokens);
		SetSafeModeDisabled(False);
	EndIf;
	
	Result = CryptographyService.Sign(
		Parameters.Data,
		Parameters.Signatory, 
		Parameters.SignatureType, 
		Parameters.SigningParameters);
		
	If Parameters.ReturnResultAsAddressInTemporaryStorage  Then
		If TypeOf(Result) = Type("Array") Then 
			For IndexOf = 0 To Result.UBound() Do
				If IsTempStorageURL(Result[IndexOf]) Then //The server will return the addresses, you need to shift
					SignedData = GetFromTempStorage(Result[IndexOf]);
					DeleteFromTempStorage(Result[IndexOf]);
				Else
					SignedData = Result[IndexOf];
				EndIf;
				Result[IndexOf] = PutToTempStorage(SignedData, Parameters.ResultFileAddresses[IndexOf]);
			EndDo;
		ElsIf TypeOf(Result) <> Type("Structure") Then 
			Result = PutToTempStorage(Result, Parameters.ResultFileAddresses[0]);
		EndIf;
	EndIf;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure VerifySignature(Parameters, ResultAddress, AdditionalResultAddress = Undefined) Export
	
	Result = CryptographyService.VerifySignature(
		Parameters.Signature, 
		Parameters.Data, 
		Parameters.SignatureType, 
		Parameters.SigningParameters);
		
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure CheckCertificate(Parameters, ResultAddress, AdditionalResultAddress = Undefined) Export
	
	Result = CryptographyService.CheckCertificate(Parameters.Certificate);
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure VerifyCertificateWithParameters(Parameters, ResultAddress, AdditionalResultAddress = Undefined) Export
	
	Result = CryptographyService.VerifyCertificateWithParameters(Parameters.Certificate, Parameters.CheckParameters);
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure GetCertificateProperties(Parameters, ResultAddress, AdditionalResultAddress = Undefined) Export
	
	CertificateProperties = CryptographyService.GetCertificateProperties(Parameters.Certificate);
	PutToTempStorage(CertificateProperties, ResultAddress);	
	
EndProcedure

Procedure GetSettingsForGettingTemporaryPasswords(Parameters, ResultAddress) Export
	
	PutToTempStorage(
		CryptographyService.GetSettingsForGettingTemporaryPasswords(Parameters.CertificateID), ResultAddress);
	
EndProcedure

Procedure GetTemporaryPassword(Parameters, ResultAddress) Export
	
	SessionID = Undefined;	
	If Parameters.Property("SessionID") Then 
		SessionID = Parameters.SessionID;
	EndIf;
	
	Result = CryptographyService.GetTemporaryPassword(
		Parameters.CertificateID,
		Parameters.Resending,
		Parameters.Type,
		SessionID);
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Procedure GetCryptoMessageProperties(Parameters, ResultAddress, AdditionalResultAddress = Undefined) Export
	
	CryptoMessageProperties = CryptographyService.GetCryptoMessageProperties(Parameters.CryptoMessage, Parameters.OnlyKeyProperties);
	PutToTempStorage(New FixedStructure(CryptoMessageProperties), ResultAddress);
	
EndProcedure

Procedure GetSessionKey(Parameters, ResultAddress) Export
	
	SessionID = Undefined;	
	If Parameters.Property("SessionID") Then 
		SessionID = Parameters.SessionID;
	EndIf;
	
	Try
		Result = GetSessionKeys(Parameters.CertificateID, Parameters.TemporaryPassword, SessionID);
		PutToTempStorage(Result, ResultAddress);
	Except
		Parameters.TemporaryPassword = ?(StrLen(Parameters.TemporaryPassword) = 6, 999999, Parameters.TemporaryPassword);
		WriteErrorToEventLog(EventNameAuthentication(), ErrorInfo(), Parameters);
		
		Raise;
	EndTry;
	
EndProcedure

Procedure GetCertificatesFromSignature(Parameters, ResultAddress, AdditionalResultAddress = Undefined) Export
	
	CertificatesFromSignature = CryptographyService.GetCertificatesFromSignature(Parameters.Signature);
	PutToTempStorage(CertificatesFromSignature, ResultAddress);
		
EndProcedure

Procedure DataHashing(Parameters, ResultAddress, AdditionalResultAddress = Undefined) Export
	
	Result = CryptographyService.DataHashing(
		Parameters.Data, 
		Parameters.HashAlgorithm, 
		Parameters.HashingParameters);

	PutToTempStorage(Result, ResultAddress);
		
EndProcedure

// To calculate the ID of the certificate
// 
// Parameters: 
//  SerialNumber - String
//  Issuer - ValueList of String
// 
// Returns: 
//  String - To calculate the ID of the certificate
Function CalculateCertificateID(SerialNumber, Issuer) Export
	
	Return CryptographyService.CalculateCertificateID(SerialNumber, Issuer);
	
EndFunction

// To run in the background
// 
// Parameters: 
//  ProcedureName - String
//  ProcedureParameters - Array of Arbitrary
// 
// Returns: See TimeConsumingOperations.ExecuteInBackground
Function ExecuteInBackground(ProcedureName, ProcedureParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lần gọi API dịch vụ mã hóa';
														|ru = 'Вызов API сервиса криптографии';
														|en = 'Call cryptography service API'; fa = 'Call cryptography service API';
														|it = 'Chiamata di servizio di crittografia API';
														|pl = 'Wywołaj API usługi kryptograficznej';
														|tr = 'Şifreleme Servisi API''sini Çağır'");
	ExecutionParameters.WaitCompletion = 0;
	
	If ProcedureParameters.Property("ReturnResultAsAddressInTemporaryStorage")
		And ProcedureParameters.ReturnResultAsAddressInTemporaryStorage Then
		ExecutionParameters.AdditionalResult = True;
	EndIf;
	
	Return TimeConsumingOperations.ExecuteInBackground(ProcedureName, ProcedureParameters, ExecutionParameters); 

EndFunction

Procedure ConfirmTemporaryPassword(CertificateID, TemporaryPassword) Export

	Result = GetSessionKeys(CertificateID, TemporaryPassword);

	// We remember the received security tokens.
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	SaveSecurityTokens(Result);
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// The name of the configuration and the security token of the certificate.
// 
// Parameters:
//  CertificateID - String
// 
// Returns:
//  String
Function ConfigurationNameAndCertificateSecurityToken(CertificateID) Export

	Return "CloudTechnology.DigitalSignatureSaaS." + CertificateID;

EndFunction

Procedure SaveSecurityTokens(NewSecurityTokens) Export
	
	// The calling function must set the privileged mode.
	
	// We save the security token for the current session in the session parameters.
	SecurityTokens = New Map;
	For Each MapItem In SessionParameters.SecurityTokens Do
		SecurityTokens.Insert(MapItem.Key, MapItem.Value);
	EndDo;
	
	SecurityTokens[NewSecurityTokens.CertificateID] = NewSecurityTokens.SecurityToken;
	
	SessionParameters.SecurityTokens = New FixedMap(SecurityTokens);		
	
	// We store the long-term security token in a secure password store.
	Common.WriteDataToSecureStorage(
		ConfigurationNameAndCertificateSecurityToken(NewSecurityTokens.CertificateID),
		NewSecurityTokens.LongLastingSecurityToken,
		"LongLastingSecurityToken");
	
EndProcedure

// Extract binary data if necessary
// 
// Parameters: 
//  Parameter - Array of String
//           - FixedArray of String
// 
// Returns: 
//  Array of BinaryData
Function ExtractBinaryDataIfNecessary(Parameter) Export
	
	ExtractedData = New Array;
	If TypeOf(Parameter) = Type("Array") Or TypeOf(Parameter) = Type("FixedArray") Then
		For IndexOf = 0 To Parameter.UBound() Do
			ExtractedData.Add(ExtractBinaryDataFromTemporaryStorageIfNecessary(Parameter[IndexOf]));
		EndDo;
	Else
		ExtractedData = ExtractBinaryDataFromTemporaryStorageIfNecessary(Parameter);
	EndIf;
	
	Return ExtractedData;
	
EndFunction

// Binary data in Base64 if necessary
// 
// Parameters: 
//  Parameter - BinaryData
// 
// Returns: 
//  String - Base64-string
Function BinaryDataInBase64IfNecessary(Val Parameter) Export
	If TypeOf(Parameter) = Type("BinaryData") Then
		Return Base64String(Parameter);
	EndIf;
	Return Parameter;
EndFunction

// Return the result as an address in temporary storage
// 
// Parameters: 
//  Parameter - Array of String, String - parameter.
// 
// Returns: 
//  Boolean
Function ReturnResultAsAddressInTemporaryStorage(Val Parameter) Export
	
	If TypeOf(Parameter) = Type("Array") Then
		Parameter = Parameter[0];
	EndIf;
	
	ReturnAsAddress = False;
	If TypeOf(Parameter) = Type("String") And IsTempStorageURL(Parameter) Then
		ReturnAsAddress = True;
	EndIf;
	
	Return ReturnAsAddress;
	
EndFunction

#EndRegion

#Region Private

// Parameters:
// 	Certificate - Structure - required fields:
// 	 * Id - String - ID of the certificate.
// 	 
// Returns:
// 	 String - ID of the certificate.
Function Id(Val Certificate) Export
	
	Return Certificate.Id;

EndFunction

Function GetPropertyNamesToRestore(Method)
	
	PropertiesForConversion = New Array;
	If StrSplit("crypto/hash", ",").Find(Method) <> Undefined Then
		PropertiesForConversion.Add("data");
	ElsIf Method = "crypto/certificate" Then
		PropertiesForConversion.Add("public_key");
		PropertiesForConversion.Add("thumbprint");
		PropertiesForConversion.Add("serial_number");
	ElsIf Method = "crypto/crypto_message" Then
		PropertiesForConversion.Add("certificates");
		PropertiesForConversion.Add("serial_number");
	EndIf;
	
	Return PropertiesForConversion;
	
EndFunction

// Parameters: 
//	Method - String - Method
//	MethodParameters - Structure - Method Parameters:
//	 * certificate_id - String
//	 * password - String
//	Headers - Map of KeyAndValue
// 
// Returns: 
//	Arbitrary
//
Function ExecuteCryptoserviceMethod(Method, MethodParameters, Headers = Undefined) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	ServiceAddress = Constants.CryptoServiceAddress.Get();
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	ConnectionParameters = CryptographyServiceManager.GetConnectionParameters(ServiceAddress);
	Join = DigitalSignatureSaaS.ConnectingToInternetServer(ConnectionParameters);
	
	UploadDataForProcessingToServer(Join, MethodParameters);
	
	Result = ExecuteServiceMethod(Join, Method, MethodParameters, Headers);
	
	DownloadProcessingResultFromServer(Join, Result);
	
	Return Result;
	
EndFunction

Procedure UploadDataForProcessingToServer(Join, MethodParameters)
	
	For Each Parameter In MethodParameters Do
		If TypeOf(Parameter.Value) = Type("BinaryData") Then
			MethodParameters.Insert(Parameter.Key, SendFileToServer(Join, Parameter.Value)); 
		ElsIf TypeOf(Parameter.Value) = Type("Array") Then
			For IndexOf = 0 To Parameter.Value.UBound() Do
				Parameter.Value[IndexOf] = SendFileToServer(Join, Parameter.Value[IndexOf]);				
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

// Parameters: 
//	Join - HTTPConnection
//	Method - String - Method
//	MethodParameters - See ExecuteCryptoserviceMethod.MethodParameters 
//  AdditionalHeadings - Map of KeyAndValue
// 
// Returns: 
//	Arbitrary
//
Function ExecuteServiceMethod(Join, Method, MethodParameters, AdditionalHeadings = Undefined)
		
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
	If ValueIsFilled(AdditionalHeadings) Then 
		For Each Title In AdditionalHeadings Do 
			Headers.Insert(Title.Key, Title.Value);
		EndDo;
	EndIf;
		
	MethodParameters.Insert("client", ClientName());
	Query = New HTTPRequest(ResourceAddress(Method), Headers);
	Query.SetBodyFromString(
		DigitalSignatureSaaS.StructureInJSON(MethodParameters),,
		ByteOrderMarkUse.DontUse);
	
	Response = CallHTTPMethod(Join, "POST", Query);
	
	If Response.StatusCode <> 200 And Response.StatusCode <> 400 Then
		LogErroneousResponseFromService(Query.ResourceAddress, Response.GetBodyAsString());
	EndIf;
		
	ConversionParameters = New Structure;
	If Response.StatusCode = 200 Then
		ConversionParameters.Insert("PropertiesToReviveNames", GetPropertyNamesToRestore(Method));
	EndIf;
			
	Result = DigitalSignatureSaaS.JSONToStructure(Response.GetBodyAsString(), ConversionParameters);
	
	If Result.status = "success" Then		
		Return Result.data;
	ElsIf Result.status = "fail" Then
		Raise(Result.data);
	EndIf;

EndFunction

Procedure DownloadProcessingResultFromServer(Join, Parameters)
	
	If TypeOf(Parameters) = Type("Array") Then
		For IndexOf = 0 To Parameters.UBound() Do
			If TypeOf(Parameters[IndexOf]) = Type("String") And StrFind(Parameters[IndexOf], "out_") Then
				Parameters[IndexOf] = GetFileFromServer(Join, Parameters[IndexOf]);
			Else
				DownloadProcessingResultFromServer(Join, Parameters[IndexOf]);
			EndIf;
		EndDo;
	ElsIf TypeOf(Parameters) = Type("Structure") Then
		For Each Parameter In Parameters Do
			If TypeOf(Parameter.Value) = Type("String") And StrFind(Parameter.Value, "out_") Then
				Parameters.Insert(Parameter.Key, GetFileFromServer(Join, Parameter.Value));
			Else
				DownloadProcessingResultFromServer(Join, Parameter.Value);
			EndIf;
		EndDo; 
	ElsIf TypeOf(Parameters) = Type("String") And StrFind(Parameters, "out_") Then
		Parameters = GetFileFromServer(Join, Parameters);
	EndIf;
		
EndProcedure

Procedure LogErroneousResponseFromService(ResourceAddress, ServerResponse1)
	
	// @skip-check module-nstr-camelcase - verification error
	WriteLogEvent(
		NStr("vi = 'Chữ ký điện tử trong mô hình dịch vụ.Dịch vụ mật mã.Thực hiện yêu cầu';
			|ru = 'Электронная подпись в модели сервиса.Сервис криптографии.Выполнение запроса';
			|en = 'Digital signature SaaS.Cryptography service.Query execution'; fa = 'Digital signature SaaS.Cryptography service.Query execution';
			|it = 'Firma elettronica nel modello di servizio.Servizio di crittografia.Esecuzione della query';
			|pl = 'E-podpis w modelu usługi.Usługa kryptograficzna.Wykonanie zapytania';
			|tr = 'Servis modelinde dijital imza.Kriptografi servisi.Sorgunun yürütülmesi'", Common.DefaultLanguageCode()), 
		EventLogLevel.Error,,,
		CommentOnException(ServerResponse1, New Structure("ResourceAddress", ResourceAddress)));	 
	
	DigitalSignatureSaaS.RaiseStandardException();
	
EndProcedure

Function SendFileToServer(Join, File)
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/octet-stream");
	Query = New HTTPRequest("/upload", Headers);
	Query.SetBodyFromBinaryData(File);
	
	Response = CallHTTPMethod(Join, "PUT", Query);
	
	If Response.StatusCode <> 201 Then
		LogErroneousResponseFromService(Query.ResourceAddress, Response.GetBodyAsString());
	EndIf;
	
	FileName = CommonCTLClientServer.HTTPHeader(Response, "X-New-Name");

	Return FileName;
	
EndFunction

Function GetFileFromServer(Join, FileName)
		
	Headers = New Map;
	Query = New HTTPRequest("/download/" + FileName, Headers);
	
	Response = CallHTTPMethod(Join, "GET", Query);
	
	If Response.StatusCode <> 200 Then
		LogErroneousResponseFromService(Query.ResourceAddress, Response.GetBodyAsString());
	EndIf;
	
	File = Response.GetBodyAsBinaryData();

	Return File;
	
EndFunction

Function CallHTTPMethod(Join, Method_HTTP, Query)
	
	Try		
		Response = Join.CallHTTPMethod(Method_HTTP, Query);
	Except
		// @skip-check module-nstr-camelcase - verification error
		WriteLogEvent(
			NStr("vi = 'Chữ ký điện tử trong mô hình dịch vụ.Dịch vụ mật mã.Thực hiện yêu cầu';
				|ru = 'Электронная подпись в модели сервиса.Сервис криптографии.Выполнение запроса';
				|en = 'Digital signature SaaS.Cryptography service.Query execution'; fa = 'Digital signature SaaS.Cryptography service.Query execution';
				|it = 'Firma elettronica nel modello di servizio.Servizio di crittografia.Esecuzione della query';
				|pl = 'E-podpis w modelu usługi.Usługa kryptograficzna.Wykonanie zapytania';
				|tr = 'Servis modelinde dijital imza.Kriptografi servisi.Sorgunun yürütülmesi'", Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,,
			CommentOnException(
				DetailErrorDescription(ErrorInfo()),
				New Structure("ResourceAddress", Query.ResourceAddress)));	 
		
		DigitalSignatureSaaS.RaiseStandardException();
	EndTry;

	Return Response;
	
EndFunction

Function SoftwareInterfaceVersion()
	
	Return "v3.1";
	
EndFunction

Function ResourceAddress(Method)
	
	Return StrTemplate("/api/%1/%2", SoftwareInterfaceVersion(), Method);
	
EndFunction

Function ClientName()
	
	Return StrTemplate("%1 (%2):%3", Metadata.Name, Metadata.Version, Format(SaaSOperations.SessionSeparatorValue(), "NG="));
	
EndFunction

Procedure WriteErrorToEventLog(EventName, ErrorInfo, Parameters) Export
	
	Comment = CommentOnException(DetailErrorDescription(ErrorInfo), Parameters);
	WriteLogEvent(EventName, EventLogLevel.Error,,, Comment);
	
EndProcedure

Function CommentOnException(ErrorPresentation, Parameters)
	
	RecordTemplate = 
	"Parameters:
	|%1
	|
	|ErrorPresentation:
	|%2";
	
	Return StrTemplate(
		RecordTemplate, 
		DigitalSignatureSaaS.StructureInJSON(Parameters, New Structure("ReplaceBinaryData", True)),
		TrimAll(ErrorPresentation));
		
EndFunction

// @unavailable-in-safemode
Procedure InstallSecurityMarkers(SecurityTokens)
	
	SetPrivilegedMode(True);
	SessionParameters.SecurityTokens = SecurityTokens;
	SetPrivilegedMode(False);
	
EndProcedure

Function GetSessionKeys(CertificateID, TemporaryPassword, SessionID = Undefined)

	Try
		MethodParameters = New Structure;
		MethodParameters.Insert("certificate_id", CertificateID);
		MethodParameters.Insert("password",       TemporaryPassword);
		
		If ValueIsFilled(SessionID) Then 
			Headers = New Map;
			Headers.Insert("X-Auth-Session", SessionID);
		Else
			Headers = Undefined;
		EndIf;
		
		SecurityTokens = ExecuteCryptoserviceMethod("crypto/all_security_tokens", MethodParameters, Headers);
		
		Result = New Structure;
		Result.Insert("SecurityToken",           SecurityTokens.security_token);
		Result.Insert("LongLastingSecurityToken", SecurityTokens.long_security_token);
		Result.Insert("CertificateID",     CertificateID);						
		
	Except
		ErrorInfo = ErrorInfo();
		MethodParameters.password = ?(StrLen(MethodParameters.password) = 6, 999999, MethodParameters.password);
		WriteErrorToEventLog(EventNameAuthentication(), ErrorInfo, MethodParameters);
		
		// Convert the exception text to an error code.
		ExceptionText = CloudTechnology.DetailedErrorText(ErrorInfo);
		If StrFind(ExceptionText, "Invalid password") Then
			ErrorText = "PasswordIsIncorrect";
		ElsIf StrFind(ExceptionText, "MaxAttemptsInputPasswordExceededError") Then
			ErrorText = "ExceededNumberOfAttemptsToEnterPassword";
		ElsIf StrFind(ExceptionText, "PasswordExpiredError") Then
			ErrorText = "PasswordExpired";
		Else 
			ErrorText = ExceptionText;
		EndIf;		
		
		Raise ErrorText;
	EndTry;

	Return Result;

EndFunction

Function ExtractBinaryDataFromTemporaryStorageIfNecessary(Parameter)
	
	If TypeOf(Parameter) = Type("String") And IsTempStorageURL(Parameter) Then
		Return GetFromTempStorage(Parameter);
	Else
		Return Parameter;
	EndIf;
	
EndFunction

// Sorts the ids of certificates by date of validity and belonging to the database
//
// Parameters:
//	CertificateIDs - Array of String - contains certificate IDs.
//
// Returns:
//  Array of String
//
Function DetermineOrderOfCertificates(CertificateIDs) Export
	
	Result = New Array;
	
	If CertificateIDs.Count() < 2 Then
		Return CertificateIDs;
	EndIf;
	
	IDsTable = New ValueTable;
	IDsTable.Columns.Add("Id", New TypeDescription("String", , New StringQualifiers(40))); 
	
	For Each ArrayRow In CertificateIDs Do
		NewRow = IDsTable.Add();
		NewRow.Id = ArrayRow;
	EndDo;	
	
	QueryText = 
	"SELECT
	|	IDsTable.Id AS Id
	|INTO AllIDs
	|FROM
	|	&IDsTable AS IDsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	AllIDs.Id AS Id,
	|	CASE
	|		WHEN NOT CertificatesStorage.StartDate IS NULL
	|			THEN 1
	|		ELSE 0
	|	END AS Priority,
	|	CertificatesStorage.EndDate AS EndDate
	|FROM
	|	AllIDs AS AllIDs
	|		LEFT JOIN InformationRegister.CertificatesStorage AS CertificatesStorage
	|		ON AllIDs.Id = CertificatesStorage.Id
	|
	|ORDER BY
	|	Priority DESC,
	|	EndDate DESC";
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Query = New Query(QueryText);
	Query.SetParameter("IDsTable", IDsTable);
	Selection = Query.Execute().Select();
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	While Selection.Next() Do
		If Result.Find(Selection.Id) = Undefined Then
			Result.Add(Selection.Id);
		EndIf;	
	EndDo;
	
	Return Result;
	
EndFunction

#Region EventNames

Function EventNameAuthentication()
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Dịch vụ mật mã.Đăng nhập';
				|ru = 'Сервис криптографии.Аутентификация';
				|en = 'Cryptography service.Authentication'; fa = 'Cryptography service.Authentication';
				|it = 'Servizio crittografico.Autenticazione';
				|pl = 'Usługa szyfrowania.Autentyfikacja';
				|tr = 'Kriptografi servisi.Yetkilendirme'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#EndRegion