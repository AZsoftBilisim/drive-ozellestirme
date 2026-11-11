////////////////////////////////////////////////////////////////////////////////
// Subsystem "Electronic signature in the service model".
//  
////////////////////////////////////////////////////////////////////////////////
//


#Region Public

// The ability to use an electronic signature in the service model.
// 
// Returns: 
//  Boolean
Function UsageAllowed() Export
	
	Return GetFunctionalOption("UseDigitalSignatureSaaS");
	
EndFunction

// The ability to use a long-term token.
// 
// Returns: 
//  Boolean
Function LongTermTokenUsageIsPossible() Export
	
	Result = False;
 
	SubsystemName = "RegulatedReporting";
	If Common.SubsystemExists(SubsystemName) Then
		SubsystemVersion = InfobaseUpdate.IBVersion(SubsystemName);
		Try
			Result = SubsystemVersion > "1.1.14.01";
		Except
		EndTry;	
	EndIf;	
	
	Return Result;
	
EndFunction

// Returns the certificate settings: use of a long-term token and its value
//
// Parameters:
//   Certificate - Structure, String - contains properties of the certificate, the existence of the property "ID" is mandatory.
//
// Returns:
//   Structure - consists of fields:
//   * CryptoOperationsConfirmationMethod - Arbitrary -
//   * Token - Arbitrary -
//   * Id - Arbitrary -
//   * Thumbprint - Arbitrary -
//
Function CertificateSigningDecryptProperties(Certificate) Export
	
	Result = DigitalSignatureSaaSInternal.CertificateSigningDecryptProperties(Certificate);
	
	Return Result;
	
EndFunction

// Deletes settings for using a long-term token
//
// Parameters:
//   Certificate - Structure - Fields:
//					* Id - String - necessarily.
//	 		    - String - contains properties of the certificate, the existence of the property "ID" is mandatory.
//
Procedure DeleteDecryptionSigningProperties(Certificate) Export
	
	DigitalSignatureSaaSInternal.DeleteDecryptionSigningProperties(Certificate);
	
EndProcedure

// Saves settings for using a long-term token
//
// Parameters:
//	Certificate - Structure - Fields:
//					* Id - String - necessarily.
//	 		   - String - contains properties of the certificate, the existence of the property "ID" is mandatory.
//
Procedure SetDecryptionSigningProperties(Certificate) Export
	
	DigitalSignatureSaaSInternal.SetDecryptionSigningProperties(Certificate);
	
EndProcedure

Procedure ConfigureUseOfLongTermToken(CryptoOperationsConfirmationMethod, Certificate) Export
	
	DigitalSignatureSaaSInternal.ConfigureUseOfLongTermToken(CryptoOperationsConfirmationMethod, Certificate);
	
EndProcedure

// Find a certificate by ID
// 
// Parameters:
//  Certificate - Arbitrary
// 
// Returns:
//  BinaryData - Find the certificate by ID.
Function FindCertificateById(Certificate) Export
	
	Result = DigitalSignatureSaaSInternal.FindCertificateById(Certificate);
	
	Return Result;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Outdated: You should use the electronic signature of the Service model.Properties of the decryption of the signature of the certificate
// Returns certificate settings: using a long-term token and its value
//
// Parameters:
//   Certificate - Structure, String - contains properties of the certificate, the existence of the property "ID" is mandatory.
//
// Returns:
//   Structure - consists of fields:
//   * CryptoOperationsConfirmationMethod - Arbitrary -
//   * Token - Arbitrary -
//   * Id - Arbitrary -
//   * Thumbprint - Arbitrary -
//
Function CertificateSigningDecryptionProperties(Certificate) Export // cSpell:ignore Decryption - compatibility
	
	Return CertificateSigningDecryptProperties(Certificate);
	
EndFunction

// Outdated: You should use the electronic signature of the Service model.Remove the property of decryption of the signature
// Deletes settings for using a long-term token
//
// Parameters:
//   Certificate - Structure - Fields:
//					* Id - String - necessarily.
//	 		    - String - contains properties of the certificate, the existence of the property "ID" is mandatory.
//
Procedure DeleteSigningDecryptionProperties(Certificate) Export // cSpell:ignore Decryption - compatibility
	
	DeleteDecryptionSigningProperties(Certificate);
	
EndProcedure

// Outdated: You should use the electronic signature of the Service model.Set the property of decryption of the signature
// Saves settings for using a long-term token
//
// Parameters:
//	Certificate - Structure - Fields:
//					* Id - String - necessarily.
//	 		   - String - contains properties of the certificate, the existence of the property "ID" is mandatory.
//
Procedure SetSigningDecryptionProperties(Certificate) Export // cSpell:ignore Decryption - compatibility
	
	SetDecryptionSigningProperties(Certificate);
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(Val ParameterName, SpecifiedParameters) Export
	
	If ParameterName = "SecurityTokens" Then
		SessionParameters.SecurityTokens = New FixedMap(New Map);
		SpecifiedParameters.Add("SecurityTokens");
	EndIf;
	
EndProcedure

// Generates a list of information security parameters.
//
// Parameters:
//	ParametersTable - See SaaSOperations.IBParameters
//
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
		
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "UseDigitalSignatureSaaS");
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "DigitalSignatureAddingServiceAddressSaaS");
	SaaSOperations.AddConstantToInformationSecurityParameterTable(ParametersTable, "CryptoServiceAddress");	
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "DigitalSignatureServiceInSaaSUserName";
	ParameterString.LongDesc = "DigitalSignatureServiceInSaaSUserName";
	ParameterString.Type = New TypeDescription("String");
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "DigitalSignatureAttachmentSaaSServiceUserPassword";
	ParameterString.LongDesc = "DigitalSignatureAttachmentSaaSServiceUserPassword";
	ParameterString.Type = New TypeDescription("String");
	
EndProcedure

// Called before attempting to write the values of is parameters
// to constants of the same name.
//
// Parameters:
// ParameterValues - Structure - the values of the parameters which you want to install.
// If the parameter value is set in this procedure
// , the corresponding key Value pair must be removed from the structure.
//
Procedure OnSetIBParametersValues(Val ParameterValues) Export
	
	Owner = Common.MetadataObjectID("Constant.DigitalSignatureAddingServiceAddressSaaS");
	If ParameterValues.Property("DigitalSignatureServiceInSaaSUserName") Then
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, ParameterValues.DigitalSignatureServiceInSaaSUserName, "Login");
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
		ParameterValues.Delete("DigitalSignatureServiceInSaaSUserName");
	EndIf;
	
	If ParameterValues.Property("DigitalSignatureAttachmentSaaSServiceUserPassword") Then
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(Owner, ParameterValues.DigitalSignatureAttachmentSaaSServiceUserPassword, "Password");
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
		ParameterValues.Delete("DigitalSignatureAttachmentSaaSServiceUserPassword");
	EndIf;
	
EndProcedure

// Fills the structure with arrays of supported versions of all software interfaces to be versioned,
// using the names of software interfaces as keys.
// Provides the functionality of the InterfaceVersion Web service.
// During implementation, it is necessary to change the body of the procedure so that it returns the current version sets (see example below).
//
// Parameters:
// SupportedVersionsStructure - Structure - in which:
//  Key - Name of the software interface,
//  Value - Array Of String - supported versions of the software interface.
//
// Implementation example:
//
//  Servertransmission of files
//  Version Array = New Array;
//  Array of versions.Add("1.0.1.1");
//  Array of versions.Add("1.0.2.1");
//  Structure of supported versions.Insert("Servertransmission of files", array of versions);
//  End of servertransmission of files
//
Procedure OnDefineSupportedInterfaceVersions(SupportedVersionsStructure) Export
	
	VersionsArray = New Array;
	VersionsArray.Add("1.0.1.1");
	SupportedVersionsStructure.Insert("DigitalSignatureSaaS", VersionsArray);	
	
EndProcedure

// Returns the structure of parameters required for the client code
// to work when running the configuration, i.e. in event handlers
// - Before starting worksystem,
// - At the beginning of the worksystem.
//
// Important: you must not use commands to reset the cache
// of reusable modules at startup, otherwise launching it may lead
// to unpredictable errors and unnecessary server calls.
//
// Parameters:
//   Parameters - Structure - (return value) structure of client operation parameters at startup.
//
// Example of implementation:
//   To set the client's operation parameters, you can use the template:
//
//     Parameters.Insert(<Parameter name>, <code for getting the parameter value>);
//
//
Procedure OnAddClientParameters(Parameters) Export
	
	Parameters.Insert("UsingElectronicSignatureInServiceModelIsPossible", UsageAllowed());
	
EndProcedure

// Establishes a connection to the Internet server over the http(s) Protocol.
//
// Parameters:
//  ConnectionParameters - Structure - additional parameters for "fine" tuning:
//    * Schema - String - the value of the "http" constant"
//    * Host - String - 
//    * Port - Number -  
//    * Login - String - 
//    * Password - String - 
//    * Timeout - Number - specifies the waiting time for the connection and operations to be performed, in seconds.
//
// Returns:
//	HTTPConnection - connection.
Function ConnectingToInternetServer(ConnectionParameters) Export

	Timeout = 30;
	If ConnectionParameters.Property("Timeout") Then
		Timeout = ConnectionParameters.Timeout;
	EndIf;
	
	Try
		SetSafeModeDisabled(True);
		Join = New HTTPConnection(
			ConnectionParameters.Host,
			ConnectionParameters.Port,
			ConnectionParameters.Login,
			ConnectionParameters.Password, 
			GetFilesFromInternet.GetProxy(ConnectionParameters.Schema),
			Timeout,
			?(Lower(ConnectionParameters.Schema) = "http", Undefined, CommonClientServer.NewSecureConnection()));
		SetSafeModeDisabled(False);
	Except
		ErrorInfo = ErrorInfo();	
		// @skip-check module-nstr-camelcase - verification error
		WriteLogEvent(
			NStr("vi = 'Chữ ký điện tử trong mô hình dịch vụ.Kết nối với Server Internet';
				|ru = 'Электронная подпись в модели сервиса.Соединение с сервером интернета';
				|en = 'Digital signature SaaS.Connect to online server'; fa = 'Digital signature SaaS.Connect to online server';
				|it = 'Firma elettronica nel modello di servizio. Connessione al server internet';
				|pl = 'Podpis elektroniczny w modelu usługi.Połączenie z serwerem internetowym';
				|tr = 'Servis modelinde dijital imza.İnternet sunucusu ile bağlantı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo));
		Raise;
	EndTry;
	
	Return Join;
	
EndFunction

// Converts a string in JSON format to a structure. 
//
// Parameters:
//  JSONString              - String - a string in JSON format.
//  ConversionParameters - Structure - additional parameters for conversion settings:
//    * PropertiesToReviveNames - Array, FixedArray - a list of properties 
//                                      to convert from Base64 to binary data.
// Returns:
//	Structure:
//	 * Field - Arbitrary - an arbitrary set of fields.
//
Function JSONToStructure(JSONString, ConversionParameters = Undefined) Export
	
	JSONReader = New JSONReader;
	JSONReader.SetString(JSONString);
	
	If TypeOf(ConversionParameters) = Type("Structure")
		And ConversionParameters.Property("PropertiesToReviveNames")
		And ValueIsFilled(ConversionParameters.PropertiesToReviveNames) Then
		Object = ReadJSON(
			JSONReader,,,, 
			"ConvertBase64ToBinaryData", 
			DigitalSignatureSaaS, 
			ConversionParameters,
			ConversionParameters.PropertiesToReviveNames);
	Else
		Object = ReadJSON(JSONReader);
	EndIf;
	
	JSONReader.Close();
	
	Return Object;
	
EndFunction

// Converts the structure to a JSON string. Binary data is converted to Base64 strings.
//
// Parameters:
//  Object - Structure - which must be converted to a JSON string.
//  ConversionParameters - Structure - Additional parameters that will be passed to the value recovery function.
//
// Returns:
//	String - in JSON format.
//
Function StructureInJSON(Object, ConversionParameters = Undefined) Export
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(
		JSONWriter, 
		Object,, 
		"ConvertBinaryDataToBase64", 
		DigitalSignatureSaaS, 
		ConversionParameters);
	
	Return JSONWriter.Close();
	
EndFunction

Procedure RaiseStandardException() Export
	
	Raise(NStr("vi = 'Tạm thời không sử dụng được dịch vụ. Hãy liên hệ với bộ phận hỗ trợ hoặc thử lại sau.';
				|ru = 'Сервис временно недоступен. Обратитесь в службу поддержки или повторите попытку позже.';
				|en = 'The service is temporarily unavailable. Contact the technical support or try again later.'; fa = 'The service is temporarily unavailable. Contact the technical support or try again later.';
				|it = 'Servizio momentaneamente non disponibile. Rivolgersi al centro assistenza o ripetere più tardi.';
				|pl = 'Serwis tymczasowo jest niedostępny. Zwróć się do służby pomocy lub powtórz próbę później.';
				|tr = 'Hizmet geçici olarak kullanılamıyor. Lütfen destekle iletişime geçin veya daha sonra tekrar deneyin.'"));
	
EndProcedure

#EndRegion

#Region Private

#Region WorkWithJSON

// A utility function intended for use in the Write JSON object
// It serves as a function for converting binary data to base64 and contains the required 
// parameters for this case.
// 
// Parameters: 
// 	Property 				- String - the property name is passed to the parameter if the structure or match is being written
// 	Value 				- Arbitrary - expected binary data type
// 	AdditionalParameters - Structure - additional parameters that are specified in the call to the Write JSON method:
//   * ReplaceBinaryData - Boolean - replaces binary data
// 	Cancel - Boolean	- refusing to write a property
// 
// Returns: 
//  String
//
Function ConvertBinaryDataToBase64(Property, Value, AdditionalParameters, Cancel) Export
	
	If TypeOf(Value) = Type("BinaryData") Then
		If TypeOf(AdditionalParameters) = Type("Structure")
			And AdditionalParameters.Property("ReplaceBinaryData")
			And AdditionalParameters.ReplaceBinaryData Then
			Return Value.Size();
		Else
			Return Base64String(Value);
		EndIf;
	EndIf;
		
EndFunction

// A utility function intended for use in the readjson object
// It serves as a function for restoring a base64 string to binary data and contains the required 
// parameters for this case.
// 
// Parameters: 
//	Property 				- String - specified only when reading JSON objects,
//	Value 				- Arbitrary - the value of the type allowed for serialization
//	AdditionalParameters - Arbitrary - contains additional parameters 
// 
// Returns: 
//  BinaryData
//
Function ConvertBase64ToBinaryData(Property, Value, AdditionalParameters) Export
	
	If TypeOf(Value) = Type("String") Then
		Return Base64Value(Value);
	ElsIf TypeOf(Value) = Type("Array") Then
		For IndexOf = 0 To Value.UBound() Do
			Value[IndexOf] = Base64Value(Value[IndexOf]);	
		EndDo;
		Return Value;
	EndIf;
	
	Return Value;
	
EndFunction

#EndRegion

#EndRegion
