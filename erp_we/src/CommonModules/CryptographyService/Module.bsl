////////////////////////////////////////////////////////////////////////////////
// The "Cryptography Service" subsystem.
//  
////////////////////////////////////////////////////////////////////////////////
//


#Region Public

// Encrypts data for the specified list of recipients.
//
// Parameters:
//   Data - BinaryData, String, Array - one or more files that need to be encrypted.
//                                             Binary data or address in temporary storage of the data file
//                                     		   to be encrypted.
//
//   Recipients - BinaryData - certificate files 
//              - Structure, FixedStructure - parameters for searching for certificates in the repository:
//			       * Thumbprint     - BinaryData, String - the thumbprint of the certificate
//			       or
//				   * SerialNumber - BinaryData, String - certificate serial number,
//			       * Issuer      - Structure, FixedStructure, String - publisher properties 
//			       or  
//			       * Certificate    - BinaryData - certificate file.
//				- Array, FixedArray - certificates of recipients of the encrypted message.
//
//   EncryptionType - String - encryption type. Only CMS is supported.
//
//   EncryptionParameters - Structure, FixedStructure - allows you to specify additional encryption parameters.
//
// Returns:
//	 BinaryData, String - encrypted data. If the data is transferred via temporary storage,
//                            then the result will be returned as well.
//
Function Encrypt(Data, Recipients, EncryptionType = "CMS", EncryptionParameters = Undefined) Export
	
	Try
		EncryptCheckIncomingParameters(
			Data, 
			Recipients, 
			EncryptionType, 
			EncryptionParameters);
			
		ReturnResultAsAddress = CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(Data);
		ReturnResultAsArray = TypeOf(Data) = Type("Array");
		Data = CryptographyServiceInternal.ExtractBinaryDataIfNecessary(Data);			
		
		If Not ReturnResultAsArray Then 
			Data = CommonClientServer.ValueInArray(Data);
		EndIf;
		
		MethodParameters = New Structure;
		MethodParameters.Insert("data", Data);
		MethodParameters.Insert("certificates", GetBinaryDataOfCertificates(Recipients));
		
		SetSafeModeDisabled(True);
		Result = ExecuteCryptoserviceMethod("crypto/encryptor", MethodParameters);
		SetSafeModeDisabled(False);
	Except
		Parameters = New Structure;
		Parameters.Insert("Data", Data);
		Parameters.Insert("Recipients", Recipients);
		Parameters.Insert("EncryptionType", EncryptionType);
		Parameters.Insert("EncryptionParameters", EncryptionParameters);
		
		WriteErrorToEventLog(EventNameEncryption(), ErrorInfo(), Parameters);
		Raise;
	EndTry;
	
	If ReturnResultAsAddress Then
		For IndexOf = 0 To Result.UBound() Do
			Result[IndexOf] = PutToTempStorage(Result[IndexOf], New UUID);
		EndDo;
	EndIf;
	If Not ReturnResultAsArray And Result.Count() = 1 Then
		Result = Result[0];
	EndIf;
	
	Return Result;
	
EndFunction

// Encrypts the data block for the recipient.
//
// Parameters:
//   Data - BinaryData, String - Binary data or address in temporary storage of the data file
//                                     to be encrypted.
//
//   Recipient - BinaryData - certificate files 
//              - Structure, FixedStructure - parameters for searching for certificates in the repository:
//				   * Thumbprint     - BinaryData, String - the thumbprint of the certificate.
//				   or
//				   * SerialNumber - BinaryData, String - serial number of the certificate.
//				   * Issuer      - Structure, FixedStructure, String - publisher properties
//				   or
//				   * Certificate    - BinaryData - certificate file.
//
// Returns:
//	 BinaryData, String - encrypted data. If the data is transferred via temporary storage,
//                            then the result will be returned as well.
//
Function EncryptBlock(Data, Recipient) Export
	
	Try
		EncryptCheckIncomingParametersBlock(
			Data, 
			Recipient);
			
		ReturnResultAsAddress = CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(Data);
		Data = CryptographyServiceInternal.ExtractBinaryDataIfNecessary(Data);			
	
		MethodParameters = New Structure;
		MethodParameters.Insert("certificate", GetBinaryCertificateData(Recipient));
		MethodParameters.Insert("data", Data);
				
		SetSafeModeDisabled(True);
		Result = ExecuteCryptoserviceMethod("crypto/encryptor_block", MethodParameters);
		SetSafeModeDisabled(False);
	Except
		Parameters = New Structure;
		Parameters.Insert("Data", Data);
		Parameters.Insert("Recipient", Recipient);
				
		WriteErrorToEventLog(EventNameBlockEncryption(), ErrorInfo(), Parameters);
		Raise;
	EndTry;
	
	Try
		Result.ephemeral_key = Base64Value(Result.ephemeral_key);
		Result.iv_data = Base64Value(Result.iv_data);
		Result.session_key = Base64Value(Result.session_key);	
	Except
		Parameters = New Structure;
		Parameters.Insert("Data", Data);
		Parameters.Insert("Recipient", Recipient);
				
		WriteErrorToEventLog(EventNameBlockEncryption(), ErrorInfo(), Parameters);
		Raise;
	EndTry;
	
	If ReturnResultAsAddress Then
		Result = PutToTempStorage(Result, New UUID);
	EndIf;

	Return Result;
	
EndFunction

// Performs the decryption of the data.
//
// Parameters:
//   EncryptedData - BinaryData, String - binary data or address in temporary storage of the data file
//                                                  to be decrypted.
//
//   Certificate - Structure - certificate to use for decryption:
//     * Id - String - ID of the certificate.
//
//   EncryptionType - String - only CMS is supported.
//
//   EncryptionParameters - Structure, FixedStructure - allows you to specify additional encryption parameters:
//     * UseLongLastingSecurityToken - Boolean - If True, a long-term security token can be used for decryption.
//                                                           False is the default value.
//
// Returns:
//	 BinaryData - decrypted data,
//   String - decrypted data if the data is transferred via temporary storage,
//	 Structure - Description of the execution error:
//     * ReturnCode - String - error code.
//     * Id - String - ID of the certificate.
//
Function Decrypt(EncryptedData, Certificate, EncryptionType = "CMS", EncryptionParameters = Undefined) Export

	Try
		DecryptCheckingIncomingParameters(
			EncryptedData, 
			EncryptionType, 
			EncryptionParameters);

		UseLongLastingSecurityToken = CommonClientServer.StructureProperty(
			EncryptionParameters, "UseLongLastingSecurityToken", False);

		SetSafeModeDisabled(True);
		SecurityTokens = SecurityTokens(Certificate.Id, UseLongLastingSecurityToken);
		SetSafeModeDisabled(False);
		
		If Not ValueIsFilled(SecurityTokens.SecurityToken)
			And Not ValueIsFilled(SecurityTokens.LongLastingSecurityToken) Then
			Return New Structure("ReturnCode, Id", "AuthenticationRequired", Certificate.Id);
		EndIf;

		ReturnResultAsAddress = CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(EncryptedData);
		
		MethodParameters = New Structure;
		MethodParameters.Insert("data", EncryptedData);
		MethodParameters.Insert("security_token", SecurityTokens.SecurityToken);
		MethodParameters.Insert("long_security_token", SecurityTokens.LongLastingSecurityToken);
		
		SetSafeModeDisabled(True);
		Result = ExecuteCryptoserviceMethod("crypto/decryptor", MethodParameters);
		SetSafeModeDisabled(False);
		
		If Not ValueIsFilled(Result) Then
			Raise(NStr("vi = 'Không thể thực hiện diễn giải tin nhắn';
						|ru = 'Не удалось выполнить расшифровку сообщения';
						|en = 'Cannot decrypt a message'; fa = 'Cannot decrypt a message';
						|it = 'Impossibile decodificare il messaggio';
						|pl = 'Nie można odszyfrować wiadomości';
						|tr = 'Mesaj deşifre edilemedi'"));
		EndIf;
		
		If ReturnResultAsAddress Then
			Result = PutToTempStorage(Result, New UUID);
		EndIf;
		
		Return Result;
		
	Except
		ErrorInfo = ErrorInfo();
		ExceptionText = CloudTechnology.DetailedErrorText(ErrorInfo);
		If StrFind(ExceptionText, "InvalidSecurityTokenError") Then
			Return New Structure("ReturnCode, Id", "AuthenticationRequired", Certificate.Id);
		EndIf;
		
		Parameters = New Structure;
		Parameters.Insert("EncryptedData", EncryptedData);
		Parameters.Insert("Certificate", Certificate);
		Parameters.Insert("EncryptionType", EncryptionType);
		Parameters.Insert("EncryptionParameters", EncryptionParameters);
	
		WriteErrorToEventLog(EventNameDecryption(), ErrorInfo, Parameters);
		
		Raise;
	EndTry;
	
EndFunction

// Performs the decryption of the data by iterating through the certificates from cryptozoology.
//
// Parameters:
//   EncryptedData - BinaryData, String - binary data or address in temporary storage of the data file
//                                                  to be decrypted.
//
//   EncryptionType - String - only CMS is supported.
//
//   EncryptionParameters - Structure, FixedStructure - allows you to specify additional encryption parameters.
//     * Use a long - term security token - Boolean-If True, a long-term security token can be used for decryption.
//                                                           False is the default value.
//
// Returns:
//	 BinaryData, String - decrypted data. If the data is transferred via temporary storage,
//                            then the result will be returned as well.
//   Structure - Description of the execution error.
//     * Return Code - String - error code.
//     * ID - String - ID of the certificate.
//
Function DecryptByIteratingOverCertificates(EncryptedData, EncryptionType = "CMS", EncryptionParameters = Undefined) Export

	ReturnResultAsAddress = CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(EncryptedData);

	CryptoMessage = CryptographyServiceInternal.ExtractBinaryDataIfNecessary(EncryptedData);

	MessageProperties = GetCryptoMessageProperties(CryptoMessage, True);
	
	IDs = New Array;
	If MessageProperties.Type = "envelopedData" Then
		Recipients = MessageProperties.Recipients; // See GetCertificatePropertiesFromJson
		For Each Recipient In Recipients Do 
			If Recipient.Property("Id") Then 
				IDs.Add(Recipient.Id);
			EndIf;
		EndDo;
	Else
		Raise StrTemplate(NStr("vi = 'Giá trị tham số %1 không hợp lệ - tệp không phải là thông điệp mã hóa';
								|ru = 'Недопустимое значение параметра %1 - файл не является криптосообщением';
								|en = 'Incorrect value of the %1 parameter. The file is not a crypto message'; fa = 'Incorrect value of the %1 parameter. The file is not a crypto message';
								|it = 'Valore del parametro %1 non valido - il file non è un messaggio crittografico';
								|pl = 'Niepoprawna wartość parametru %1 - plik nie jest wiadomością kryptograficzną';
								|tr = '%1 parametresinin hatalı değeri - dosya kripto mesaj değil'"),
			"EncryptedData");
	EndIf;
	
	If Not ValueIsFilled(IDs) Then
		Raise(NStr("vi = 'Trong kho chứa không có chứng thư để giải mã tin nhắn.';
					|ru = 'В хранилище отсутствуют сертификаты для расшифровки сообщения.';
					|en = 'There are no certificates for message decryption in storage.'; fa = 'There are no certificates for message decryption in storage.';
					|it = 'Non ci sono i certificati nel repository per decifrare il messaggio.';
					|pl = 'W repozytorium nie ma żadnych certyfikatów do odszyfrowania wiadomości.';
					|tr = 'Depolamada mesajı deşifre etmek için sertifika bulunmuyor.'"));
	EndIf;
	
	IDs = CryptographyServiceInternal.DetermineOrderOfCertificates(IDs);

	DecryptedData = Undefined;

	For Each CurrentID In IDs Do

		Try
			Certificate = New Structure("Id", CurrentID);
			DecryptedData = Decrypt(CryptoMessage, Certificate, EncryptionType, EncryptionParameters);
		Except
			// A log entry is not required.
			// An error could occur during decryption, if the certificate was unsuitable, then we try the next one in the list.
		EndTry;

		If DecryptedData <> Undefined Then
			// If the decryption was successful or an error occurred that prevents further execution, then we stop sorting certificates.
			Break;
		EndIf;
		
	EndDo;
	
	If TypeOf(DecryptedData) = Type("Structure") Then
		// A special error of the cryptography service, we stop execution and pass information about it to the calling method.
		Return DecryptedData;
	EndIf;
	
	If ReturnResultAsAddress Then
		DecryptedData = PutToTempStorage(DecryptedData, New UUID);
	EndIf;
	
	Return DecryptedData;

EndFunction

// Performs decryption of a data block.
//
// Parameters:
//   EncryptedData - BinaryData, String - binary data or address in temporary storage of the data file
//                                                  to be decrypted.
//
//   Recipient - BinaryData - the certificate file of the recipient of the encrypted message
//              - Structure, FixedStructure - parameters for searching for certificates in the repository:
//                 * Id - String - ID of the certificate.
//
//   KeyInformation - Structure, FixedStructure - allows you to send data about encryption keys to the request:
//       * ephemeral_key - BinaryData, String - in base64, an ephemeral key
//       * session_key - BinaryData, String - in base64, the session key
//       * iv_data - BinaryData, String - in base64, initialization vector data
//
//   EncryptionParameters - Structure, FixedStructure - allows you to specify additional encryption parameters.
//
// Returns:
//	 BinaryData - decrypted data;
//	 String - decrypted data if the data is transferred via temporary storage;
//   Structure - description of the execution error:
//     * ReturnCode - String - error code.
//     * Id - String - ID of the certificate.
//
Function DecryptBlock(EncryptedData, Recipient, KeyInformation, EncryptionParameters = Undefined) Export
	
	Try
		DecryptCheckIncomingParametersBlock(
			EncryptedData, 
			Recipient,
			KeyInformation, 
			EncryptionParameters);
			
		UseLongLastingSecurityToken = CommonClientServer.StructureProperty(
			EncryptionParameters, "UseLongLastingSecurityToken", False);
			
		Certificate = FindCertificate(Recipient);
		If Not ValueIsFilled(Certificate) Then
			Raise(NStr("vi = 'Không tìm thấy chứng thư của người ký trong kho chứa chứng thư.';
						|ru = 'Сертификат подписанта не найден в хранилище сертификатов.';
						|en = 'The signer certificate is not found in the certificate store.'; fa = 'The signer certificate is not found in the certificate store.';
						|it = 'Il certificato del firmatario non è stato trovato nel repository dei certificati.';
						|pl = 'W magazynie certyfikatów nie znaleziono certyfikatu osoby podpisującej.';
						|tr = 'İmzalayanın sertifikası, sertifika deposunda bulunamadı.'"));
		EndIf;
		
		SetSafeModeDisabled(True);
		SecurityTokens = SecurityTokens(Certificate.Id, UseLongLastingSecurityToken);
		SetSafeModeDisabled(False);
		
		If Not ValueIsFilled(SecurityTokens.SecurityToken)
			And Not ValueIsFilled(SecurityTokens.LongLastingSecurityToken) Then
			Return New Structure("ReturnCode, Id", "AuthenticationRequired", Certificate.Id);
		EndIf;
						
		clear_padding = True;
		If ValueIsFilled(EncryptionParameters) Then 
			EncryptionParameters.Property("ClearPaddingBytes", clear_padding);
			clear_padding = ?(TypeOf(clear_padding) = Type("Boolean"), clear_padding, True);
		EndIf;		
		
		ReturnResultAsAddress = CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(EncryptedData);
		
		MethodParameters = New Structure;
		MethodParameters.Insert("security_token", SecurityTokens.SecurityToken);
		MethodParameters.Insert("long_security_token", SecurityTokens.LongLastingSecurityToken);
		MethodParameters.Insert("data", EncryptedData);
		MethodParameters.Insert("ephemeral_key", 
			CryptographyServiceInternal.BinaryDataInBase64IfNecessary(KeyInformation.ephemeral_key));
		MethodParameters.Insert("session_key", 
			CryptographyServiceInternal.BinaryDataInBase64IfNecessary(KeyInformation.session_key));
		MethodParameters.Insert("iv_data", 
			CryptographyServiceInternal.BinaryDataInBase64IfNecessary(KeyInformation.iv_data));
		MethodParameters.Insert("clear_padding", clear_padding);
		
		SetSafeModeDisabled(True);
		Result = ExecuteCryptoserviceMethod("crypto/decryptor_block", MethodParameters);
		SetSafeModeDisabled(False);
		
		If Not ValueIsFilled(Result) Then
			Raise(NStr("vi = 'Không thể thực hiện diễn giải khối dữ liệu';
						|ru = 'Не удалось выполнить расшифровку блока данных';
						|en = 'Cannot decrypt data block'; fa = 'Cannot decrypt data block';
						|it = 'Impossibile decodificare il blocco di dati';
						|pl = 'Nie można odszyfrować bloku danych';
						|tr = 'Veri bloku deşifre edilemedi'"));
		EndIf;
		
		If ReturnResultAsAddress Then
			Result = PutToTempStorage(Result, New UUID);
		EndIf;
		
		Return Result;
		
	Except
		ErrorInfo = ErrorInfo();
		ExceptionText = CloudTechnology.DetailedErrorText(ErrorInfo);
		If StrFind(ExceptionText, "InvalidSecurityTokenError") Then
			Return New Structure("ReturnCode, Id", "AuthenticationRequired", Recipient.Id);
		EndIf;
		
		Parameters = New Structure;
		Parameters.Insert("EncryptedData", EncryptedData);
		Parameters.Insert("Recipient", Recipient);
		Parameters.Insert("KeyInformation", KeyInformation);
		Parameters.Insert("EncryptionParameters", EncryptionParameters);
	
		WriteErrorToEventLog(EventNameBlockDecryption(), ErrorInfo, Parameters);
		
		Raise;
	EndTry;
	
EndFunction

// Performs data signing.
//
// Parameters:
//   Data - BinaryData, String, Array - one or more files to sign. 
//                                             Binary data or address in temporary storage of the data file
//                                             to be signed.
//
//   Signatory - BinaryData - the certificate file to sign. 
//             - Structure, FixedStructure - parameters for searching for the certificate in the repository.
//		          * Fingerprint - Binary data, String - fingerprint certificate.
//		          or
//		          * SerialNumber - binary Data, String - certificate serial number.
//		          * Publisher-Structure, fixed Structure, String-publisher properties.
//		          or
//		          * Certificate-binary Data-certificate file.
//
//   SignatureType - String - the type of the signature. Only "CMS" or "GOST3410"are supported.
//
//   SigningParameters - Structure, FixedStructure - allows you to specify additional signing parameters:
//     * DisconnectedSignature - Boolean - only CMS is supported. if True, a detached signature will be generated, otherwise it will be attached.
//                                       True is the default value.
//     * UseLongLastingSecurityToken - Boolean - If True, a long-term security token can be used for decryption.
//                                                           False is the default value.
//
// Returns:
//	 BinaryData - Signature; 
//	 Signature string if data is transferred via temporary storage;
//   Structure - description of the execution error:
//     * ReturnCode - String - error code.
//     * Id - String - ID of the certificate.
//
Function Sign(Data, Signatory, SignatureType = "CMS", SigningParameters = Undefined) Export

	SignCheckIncomingParameters(
		Data, 
		Signatory, 
		SignatureType, 
		SigningParameters);

	UseLongLastingSecurityToken = CommonClientServer.StructureProperty(
		SigningParameters, "UseLongLastingSecurityToken", False);
	
	Certificate = FindCertificate(Signatory);
	If Not ValueIsFilled(Certificate) Then
		Raise(NStr("vi = 'Không tìm thấy chứng thư của người ký trong kho chứa chứng thư.';
					|ru = 'Сертификат подписанта не найден в хранилище сертификатов.';
					|en = 'The signer certificate is not found in the certificate store.'; fa = 'The signer certificate is not found in the certificate store.';
					|it = 'Il certificato del firmatario non è stato trovato nel repository dei certificati.';
					|pl = 'W magazynie certyfikatów nie znaleziono certyfikatu osoby podpisującej.';
					|tr = 'İmzalayanın sertifikası, sertifika deposunda bulunamadı.'"));
	EndIf;
	
	
	SetSafeModeDisabled(True);
	SecurityTokens = SecurityTokens(Certificate.Id, UseLongLastingSecurityToken);
	SetSafeModeDisabled(False);
	
	If Not ValueIsFilled(SecurityTokens.SecurityToken)
		And Not ValueIsFilled(SecurityTokens.LongLastingSecurityToken) Then
		Return New Structure("ReturnCode, Id", "AuthenticationRequired", Certificate.Id);
	EndIf;
	
	ReturnResultAsAddress = CryptographyServiceInternal.ReturnResultAsAddressInTemporaryStorage(Data);
	ReturnResultAsArray = TypeOf(Data) = Type("Array");
		
	Try
		If ValueIsFilled(SigningParameters) 
			And SigningParameters.Property("DisconnectedSignature") Then
			DisconnectedSignature = SigningParameters.DisconnectedSignature;
		Else
			DisconnectedSignature = True;
		EndIf;
		
		If Not ReturnResultAsArray Then 
			Data = CommonClientServer.ValueInArray(Data);
		EndIf;
	
	    MethodParameters = New Structure;
		MethodParameters.Insert("security_token",      SecurityTokens.SecurityToken);
		MethodParameters.Insert("long_security_token", SecurityTokens.LongLastingSecurityToken);
		MethodParameters.Insert("data",                Data);
		MethodParameters.Insert("type",                SignatureType);
		MethodParameters.Insert("include_data",        Not DisconnectedSignature);
		
		SetSafeModeDisabled(True);
		Result = ExecuteCryptoserviceMethod("crypto/signature", MethodParameters);
		SetSafeModeDisabled(False);
		
		If ReturnResultAsAddress Then
			For IndexOf = 0 To Result.UBound() Do
				Result[IndexOf] = PutToTempStorage(Result[IndexOf], New UUID);
			EndDo;
		EndIf;
		If Not ReturnResultAsArray And Result.Count() = 1 Then
			Result = Result[0];
		EndIf;
		
		Return Result;
		
	Except
		ErrorInfo = ErrorInfo();
		ExceptionText = CloudTechnology.DetailedErrorText(ErrorInfo);
		If StrFind(ExceptionText, "InvalidSecurityTokenError") Then
			Return New Structure("ReturnCode, Id", "AuthenticationRequired", Certificate.Id);
		EndIf;
		
		Parameters = New Structure;
		Parameters.Insert("Data", Data);
		Parameters.Insert("Signatory", Signatory);
		Parameters.Insert("SignatureType", SignatureType);
		Parameters.Insert("SigningParameters", SigningParameters);
	
		WriteErrorToEventLog(EventNameSigning(), ErrorInfo, Parameters);
		
		Raise;
	EndTry;
	
EndFunction

// Performs signature verification.
//
// Parameters:
//   Signature - BinaryData - the signature that you want to test.
//
//   Data - BinaryData - source data required for signature verification. Used for checking the disconnected Signature.
//
//   SignatureType - String - the type of the signature. Only "CMS" or "GOST3410"are supported.
//
//   SigningParameters - Structure, FixedStructure - allows you to specify additional signing parameters.
//     * Detached signature - Boolean - used in conjunction with the signature type = "CMS", if True, the signature will be verified using the data.
//                                       True is the default value.
//     * Certificate - Binary data - certificate file, must be used in conjunction with the signature type = "GOST3410".
//
// Returns:
//	 Boolean - if True, then the signature is valid.
//
Function VerifySignature(Signature, Data = Undefined, SignatureType = "CMS", SigningParameters = Undefined) Export
	
	CheckSignatureCheckingIncomingParameters(
		Signature, 
		Data, 
		SignatureType, 
		SigningParameters);
	
	Try
		MethodParameters = New Structure;
		MethodParameters.Insert("signature", Signature);
		MethodParameters.Insert("data", Data);
		MethodParameters.Insert("type", SignatureType);
		
		If SignatureType = "GOST3410" Then
			MethodParameters.Insert("certificate", SigningParameters.Certificate);
		EndIf;
		
		SetSafeModeDisabled(True);
		Return ExecuteCryptoserviceMethod("crypto/verification/signature", MethodParameters);
		
	Except
		
		Parameters = New Structure;
		Parameters.Insert("Data", Data);
		Parameters.Insert("Signature", Signature);
		Parameters.Insert("SignatureType", SignatureType);
		Parameters.Insert("SigningParameters", SigningParameters);
	
		WriteErrorToEventLog(EventNameSignatureVerification(), ErrorInfo(), Parameters);
		
		Raise;
	EndTry;
	
EndFunction

//  Calculates the hash amount based on the transmitted data.
//
// Parameters:
//   Data - BinaryData, String - binary data or an address in the temporary storage of the data file
//                                     from which the hash sum must be calculated.
//   HashAlgorithm - String - constant from the list "GOST R 34.11-94", "GOST R 34.11-2012 256","GOST R 34.11-2012 512".
//
//   HashingParameters - Structure, FixedStructure - allows you to specify additional hashing parameters.
//     * Invert half-bytes-Boolean-controls the inversion of half-bytes in the hash sum value. Applies only to " GOST R 34.11-94"
//                                For example, the forward order is 62 FB, the reverse is 26 BF.
//                                True is the default value.
//
// Returns:
//	 BinaryData - value of the hash sum.
//
Function DataHashing(Data, HashAlgorithm = "GOST R 34.11-94", HashingParameters = Undefined) Export
	
	HashingDataCheckingIncomingParameters(
		Data, 
		HashAlgorithm, 
		HashingParameters);
	
	Try
		If ValueIsFilled(HashingParameters) 
			And HashingParameters.Property("InvertNibbles") Then
			InvertNibbles = HashingParameters.InvertNibbles;
		Else
			InvertNibbles = True;
		EndIf;
		
		MethodParameters = New Structure;
		MethodParameters.Insert("data", Data);
		MethodParameters.Insert("algorithm", HashAlgorithm);
		MethodParameters.Insert("inverted_halfbytes", InvertNibbles);
		
		SetSafeModeDisabled(True);
		Return ExecuteCryptoserviceMethod("crypto/hash", MethodParameters);
		
	Except
		ErrorInfo = ErrorInfo();
		
		Parameters = New Structure;
		Parameters.Insert("Data", Data);
		Parameters.Insert("HashAlgorithm", HashAlgorithm);
		Parameters.Insert("HashingParameters", HashingParameters);
	
		WriteErrorToEventLog(EventNameHashing(), ErrorInfo, Parameters);
		
		Raise;
	EndTry;
	
EndFunction

// Performs certificate verification.
//
// Parameters:
//   Certificate - BinaryData - certificate file.
//
// Returns:
//	 Boolean - if True, then the certificate is valid.
//
Function CheckCertificate(Certificate) Export
	
	CheckCertificateCheckIncomingParameters(Certificate);
	
	Try
		MethodParameters = New Structure;
		MethodParameters.Insert("certificate", CertificatesStorage.DERCertificate(Certificate));
		
		Result = CryptographyServiceInternal.ExecuteCryptoserviceMethod("crypto/verification/certificate", MethodParameters);
		
		Return Result;
	Except
		Parameters = New Structure("Certificate", Certificate);
		CryptographyServiceInternal.WriteErrorToEventLog(NameOfCertificateVerificationEvent(), ErrorInfo(), Parameters);
		
		Raise;
	EndTry;
	
	Return Undefined;
		
EndFunction

// Checks the certificate with additional parameters
//
// Parameters:
//   Certificate - BinaryData - certificate file.
//   CheckParameters - Structure - contains additional validation parameters.
//		* Verification mode of the certificate-String-the options "Ignore timesreferences" are processed",
//												" 
//												
//												Ignore the validity of the signature", "Ignore the verification of the list of called certificates", "Allow the test certificates"
//
// Returns:
//	 Boolean - if True, then the certificate is valid.
//
Function VerifyCertificateWithParameters(Certificate, CheckParameters) Export
	
	CheckCertificateCheckIncomingParameters(Certificate);
	
	Try
		MethodParameters = New Structure;
		MethodParameters.Insert("certificate", CertificatesStorage.DERCertificate(Certificate));
		
		CertificateVerificationMode = CommonClientServer.StructureProperty(CheckParameters, "CertificateVerificationMode", "");
		If ValueIsFilled(CertificateVerificationMode) Then
			MethodParameters.Insert("mode", PrepareCertificateVerificationModes(CertificateVerificationMode));
		EndIf;
		
		Result = CryptographyServiceInternal.ExecuteCryptoserviceMethod("crypto/verification/certificate", MethodParameters);
		
		Return Result;
	Except
		Parameters = New Structure("Certificate", Certificate);
		CryptographyServiceInternal.WriteErrorToEventLog(NameOfCertificateVerificationEvent(), ErrorInfo(), Parameters);
		
		Raise;
	EndTry;
	
	Return Undefined;
		
EndFunction

// Retrieves the basic properties of the passed certificate.
// 
// Parameters:
//   Certificate - BinaryData - the certificate whose properties you want to get.
//
// Returns:
//	 FixedStructure - certificate properties:
//    * Version - String - the version of the certificate.
//    * StartDate - Date - certificate start date (UTC).
//    * EndDate - Date - certificate expiration date (UTC).
//    * Issuer - FixedStructure - information about the certificate publisher:
//        ** CN - String - commonName 
//        ** O - String - organizationName; 
//        ** OU - String - organizationUnitName; 
//        ** C - String - countryName; 
//        ** ST - String - stateOrProvinceName; 
//        ** L - String - localityName; 
//        ** E - String - emailAddress; 
//        ** SN - String - surname; 
//        ** GN - String - givenName; 
//        ** T - String - title;
//        ** STREET - String - streetAddress;
//        ** OGRN - String - Bin;
//        ** OGRNIP - String - OGRNIP;
//        ** INN - String - INN (optional);
//        ** INNLE - String - TIN YUL (optional);
//        ** SNILS - String - SNILS;
//           ...
//    * UseToSign - Boolean - specifies whether this certificate can be used for signing.
//    * UseToEncrypt - Boolean - specifies whether this certificate can be used for encryption.
//    * PublicKey - BinaryData - contains public key data.
//    * Thumbprint - BinaryData - contains the data of the print. It is calculated dynamically using the SHA-1 algorithm.
//    * Extensions - FixedStructure -  Extended Certificate Properties:
//        ** EKU - FixedArray of Arbitrary - Enhanced Key Usage.
//    * SerialNumber - BinaryData - serial number of the certificate.
//    * Subject - FixedStructure - information about the subject of the certificate. Composition see Publisher:
//        ** CN - String - commonName ...
//    * Certificate - BinaryData - certificate file in DER encoding.
//    * Id - String - calculated by the key properties of the Publisher and the serial number using the SHA1 algorithm.
//                               Used to identify the certificate in the cryptography service.
//
Function GetCertificateProperties(Certificate) Export
	
	GetCertificatePropertiesCheckIncomingParameters(Certificate);
	
	Try
		DERCertificate = CertificatesStorage.DERCertificate(Certificate);
		
		MethodParameters = New Structure;
		MethodParameters.Insert("certificate", DERCertificate);
		
		Result = CryptographyServiceInternal.ExecuteCryptoserviceMethod("crypto/certificate", MethodParameters);
		
		Properties = New Structure;
		Properties.Insert("Version"                   , StrTemplate("V%1", Result.version + 1));
		Properties.Insert("StartDate"            	 , XMLValue(Type("Date"), Left(Result.valid_from, 19)));
		Properties.Insert("EndDate"            , XMLValue(Type("Date"), Left(Result.valid_to, 19)));
		Properties.Insert("Issuer"                 , ConvertOID(Result.issuer));
		Properties.Insert("UseToSign"   , Result.use_to_sign);
		Properties.Insert("UseToEncrypt", Result.use_to_encrypt);
		Properties.Insert("PublicKey"             , Result.public_key);
		Properties.Insert("Thumbprint"                , Result.thumbprint);
		Properties.Insert("Extensions"      , ExtendedCertificateProperties(Result.extensions));
		Properties.Insert("SerialNumber"            , Result.serial_number);
		Properties.Insert("Subject"                  , ConvertOID(Result.subject));
		Properties.Insert("Description"             , CertificateDescription(Result.subject));
		Properties.Insert("Certificate"               , DERCertificate);
		Properties.Insert("Id"            , CalculateJSONCertificateID(Result));
		
		Return New FixedStructure(Properties);
	
	Except
		Parameters = New Structure("Certificate", Certificate);
		CryptographyServiceInternal.WriteErrorToEventLog(NameOfCertificatePropertyEvent(), ErrorInfo(), Parameters);
		
		Raise;
	EndTry;
		
EndFunction

// Retrieves an array of certificates from the signature data.
//
// Parameters:
//   Signature - BinaryData - signature file.
//
// Returns:
//	 Array of FixedStructure - with certificate properties:
//    * Issuer - FixedStructure - information about the certificate publisher:
//        ** CN - String - commonName; 
//        ** O - String - organizationName; 
//        ** OU - String - organizationUnitName; 
//        ** C - String - countryName; 
//        ** ST - String - stateOrProvinceName; 
//        ** L - String - localityName; 
//        ** E - String - emailAddress; 
//        ** SN - String - surname; 
//        ** GN - String - givenName; 
//        ** T - String - title;
//        ** STREET - String - streetAddress;
//        ** OGRN - String - Bin;
//        ** OGRNIP - String - OGRNIP;
//        ** INN - String - TIN;
//        ** INNLE - String - TIN YUL (optional);
//        ** SNILS - String - SNILS;
//    * SerialNumber - BinaryData - serial number of the certificate.
//    * Certificate - BinaryData - certificate file in DER encoding.
//    * Id - String - calculated by the key properties of the Publisher and the serial number using the SHA1 algorithm.
//                               Used to identify the certificate in the cryptography service.
//
Function GetCertificatesFromSignature(Signature) Export
	
	GetCertificatesFromSigningCheckIncomingParameters(Signature);
	
	If TypeOf(Signature) = Type("String") Then
		Signature = GetFromTempStorage(Signature);
	EndIf;
	
	CryptoMessageProperties = GetCryptoMessageProperties(Signature);
	If CryptoMessageProperties.Type = "signedData" Then
		Return CryptoMessageProperties.Certificates;	
	Else
		Raise(NStr("vi = 'Tham số <Chữ ký> không phải là tệp chữ ký';
					|ru = 'Параметр <Подпись> не является файлом подписи';
					|en = 'The <Signature> parameter is not a signature file'; fa = 'The <Signature> parameter is not a signature file';
					|it = 'Il parametro <Подпись> non è un file di firma';
					|pl = 'Parametr <Podpis> nie jest plikiem podpisu';
					|tr = '<İmza> parametresi imza dosyası değil'"));
	EndIf;
	
EndFunction

// Retrieves properties from a cryptographic message file.
//
// Parameters:
//   CryptoMessage - BinaryData, String - binary data or address in the temporary storage of the cryptographic message file.
//   OnlyKeyProperties - Boolean - if True, the Content will always be returned empty.
//
// Returns:
// 	Structure - Crypto Message Properties:
// 	 * Size - Number - file size in bytes.
// 	 * Type - String - specifies the message type: envelopedData, signedData, unknown.
// 	 * Recipients - FixedArray of Structure - description of the certificates of the recipients of the encrypted message. Only for Type="EnvelopedData":
//   	** Id - String - calculated by the key properties of the Publisher and the serial number according to the SHA1 algorithm, 
//   								the remaining fields are See GetCertificateProperties.
// 	 * Signatories - FixedArray of Structure - description of the certificates of the recipients of the encrypted message. Only for Type="SignedData":
// 	    ** Id - String - calculated by the key properties of the Publisher and the serial number using the SHA1 algorithm.
//   								other fields See GetCertificateProperties.
// 	 * Content - BinaryData - content of the cryptographic message.
//
Function GetCryptoMessageProperties(CryptoMessage, OnlyKeyProperties = False) Export
	
	CryptoMessageProperties = New Structure;
	CryptoMessageProperties.Insert("Type", "unknown");
	
	Try
		GetPropertiesOfCryptographicMessageCheckingIncomingParameters(CryptoMessage);
		
		CryptoMessageProperties.Insert("Size", CryptoMessage.Size());
		
		MethodParameters = New Structure;
		MethodParameters.Insert("message", CryptoMessage);
		
		Result = CryptographyServiceInternal.ExecuteCryptoserviceMethod("crypto/crypto_message", MethodParameters);
		
		CryptoMessageProperties.Insert("Type", Result.type);	
		
		Recipients = GetCertificatePropertiesFromJson(Result.recipient_infos);
		CryptoMessageProperties.Insert("Recipients", New FixedArray(Recipients));
		
		Signatories = GetCertificatePropertiesFromJson(Result.signer_infos);
		CryptoMessageProperties.Insert("Signatories", New FixedArray(Signatories));			
		
		If Not OnlyKeyProperties Then
			Certificates = New Array;
			For Each certificate In Result.certificates Do
				Certificates.Add(certificate);		
			EndDo;
			CryptoMessageProperties.Insert("Certificates", New FixedArray(Certificates));
			If Not ValueIsFilled(Result.content) Then
				Result.content = Base64Value("");
			EndIf;
			
			CryptoMessageProperties.Insert("Content", Result.content);
		EndIf;
	Except
		CryptographyServiceInternal.WriteErrorToEventLog(EventNamePropertiesOfCryptoMessage(), ErrorInfo(), CryptoMessageProperties);
	EndTry;
	
	Return CryptoMessageProperties;
	
EndFunction

// Gets possible ways to deliver temporary passwords.
//
// Parameters:
//   CertificateID - String - ID of the certificate to get password delivery methods for.
//
// Returns:
//   Structure - Contains keys:
//     * Phone          - String - the disguised representation of your phone to receive a temporary password in an SMS.
//     * Email - String - the disguised e-mail to retrieve the temporary password in the mail.
//
Function GetSettingsForGettingTemporaryPasswords(CertificateID) Export
	
	Try
		MethodParameters = New Structure;
		MethodParameters.Insert("certificate_id", CertificateID);
		
		Result = CryptographyServiceInternal.ExecuteCryptoserviceMethod("crypto/auth_parameters", MethodParameters);
		
		WaysToDeliverPasswords = New Structure("Phone,Email", "", "");
		For Each ResultItem In Result Do 
			If ResultItem.type = "phone" Then
				WaysToDeliverPasswords.Phone = ResultItem.value;
			ElsIf ResultItem.type = "email" Then
				WaysToDeliverPasswords.Email = ResultItem.value;
			EndIf;	
		EndDo;
		
		Return WaysToDeliverPasswords;
	Except
		Parameters = New Structure("CertificateID", CertificateID);
		CryptographyServiceInternal.WriteErrorToEventLog(EventNameAuthentication(), ErrorInfo(), Parameters);
		
		Raise;
	EndTry;
	
EndFunction

// Requests the cryptography service to send a temporary password.
//
// Parameters:
//	CertificateID - String - ID of the certificate that requires a temporary password.
//	Resending - Boolean - True if the request is repeated.
//	PasswordsDeliveryMethod - String - One of the values: "phone" or "email".
//	SessionID - String - session ID
//
// Returns:
//	Structure - Contains keys:
//		* DelayBeforeResending - Number - The number of seconds before requesting a new password again.
//		* PasswordValidityPeriod - Number - The number of seconds that the sent password is valid.
//		* SessionID - String - if there is a "session_id".
//
Function GetTemporaryPassword(CertificateID, Resending, PasswordsDeliveryMethod, SessionID = Undefined) Export

	ExecutionResult = New Structure();
	ExecutionResult.Insert("DelayBeforeResending", 0);
	ExecutionResult.Insert("PasswordValidityPeriod",             0);

	MethodParameters = New Structure;
	MethodParameters.Insert("certificate_id", CertificateID);
	MethodParameters.Insert("repeat",         Resending);
	MethodParameters.Insert("type",           PasswordsDeliveryMethod);
	
	If ValueIsFilled(SessionID) Then
		Headers = New Map;
		Headers.Insert("X-Auth-Session", SessionID);
	Else
		Headers = Undefined;
	EndIf;		
		
	Try

		GetTemporaryPasswordCheckIncomingParameters(CertificateID, Resending, PasswordsDeliveryMethod);
		
		Result = CryptographyServiceInternal.ExecuteCryptoserviceMethod("crypto/password", MethodParameters, Headers);
		
		ExecutionResult.DelayBeforeResending = Result.delay;
		ExecutionResult.PasswordValidityPeriod             = Result.life_time;
		
		If Result.Property("session_id") Then 
			ExecutionResult.Insert("SessionID", Result.session_id);
		EndIf;
		
	Except
		
		CryptographyServiceInternal.WriteErrorToEventLog(EventNameAuthentication(), ErrorInfo(), MethodParameters);
		Raise;
	
	EndTry;
	
	Return ExecutionResult;

EndFunction

// Sends the previously received temporary password to the cryptography service and requests security tokens for it.
//
// Parameters:
//	CertificateID - String - ID of the certificate to use for signing.
//	TemporaryPassword - String - Temporary password previously sent by the cryptography service.
//
Procedure ConfirmTemporaryPassword(CertificateID, TemporaryPassword) Export

	CryptographyServiceInternal.ConfirmTemporaryPassword(CertificateID, TemporaryPassword);

EndProcedure

// Tries to get previously saved security tokens: session and long-term
//
// Parameters:
//	CertificateID - String - ID of the certificate to use for signing.
//	UseLongLastingSecurityToken - Boolean - indicates whether a long-term token is being searched for.
//	
// Returns:
//	Structure - Marker:
//   * SecurityToken - String
//   * LongLastingSecurityToken - String
// @unavailable-in-safemode
Function SecurityTokens(CertificateID, UseLongLastingSecurityToken) Export

	Result = New Structure();
	Result.Insert("SecurityToken");
	Result.Insert("LongLastingSecurityToken");
	
	SetPrivilegedMode(True);
	Result.SecurityToken = SessionParameters.SecurityTokens.Get(CertificateID);
	
	If UseLongLastingSecurityToken Then 
		Result.LongLastingSecurityToken = Common.ReadDataFromSecureStorage(
			CryptographyServiceInternal.ConfigurationNameAndCertificateSecurityToken(CertificateID),
			"LongLastingSecurityToken",
			False);
	EndIf;
	
	SetPrivilegedMode(False);
	
	// We will replace the empty values with empty strings for transmission to the cryptography service.
	If Not ValueIsFilled(Result.SecurityToken) Then
		Result.SecurityToken = "";
	EndIf;
	
	If Not ValueIsFilled(Result.LongLastingSecurityToken) Then
		Result.LongLastingSecurityToken = "";
	EndIf;
	
	Return Result;

EndFunction

#EndRegion

#Region Private

Function SoftwareInterfaceVersion()
	
	Return "v3.1";
	
EndFunction

Function ClientName()
	
	Return StrTemplate("%1 (%2):%3", Metadata.Name, Metadata.Version, Format(SaaSOperations.SessionSeparatorValue(), "NG="));
	
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

Function FindCertificate(Certificate)
	
	CertificateProperties = Undefined;
	If TypeOf(Certificate) = Type("BinaryData") Then
		CertificateProperties = GetCertificateProperties(Certificate);
	ElsIf (TypeOf(Certificate) = Type("Structure")
		Or  TypeOf(Certificate) = Type("FixedStructure"))
		And Certificate.Property("Certificate") Then
		CertificateProperties = GetCertificateProperties(Certificate.Certificate);
	Else
		CertificateProperties = CertificatesStorage.FindCertificate(Certificate);
	EndIf;
	
	Return CertificateProperties;
	
EndFunction

Function GetBinaryCertificateData(Certificate)
	
	CertificateBinaryData = Undefined;
	
	If TypeOf(Certificate) = Type("BinaryData") Then
		CertificateBinaryData = CertificatesStorage.DERCertificate(Certificate);
	ElsIf (TypeOf(Certificate) = Type("Structure") Or TypeOf(Certificate) = Type("FixedStructure"))
		And Certificate.Property("Certificate") Then
		CertificateBinaryData = CertificatesStorage.DERCertificate(Certificate.Certificate);
	Else
		CertificateBinaryData = CertificatesStorage.FindCertificate(Certificate).Certificate;
	EndIf;
	
	If Not ValueIsFilled(CertificateBinaryData) Then
		Raise(NStr("vi = 'Không thể lấy ra dữ liệu nhị phân của chứng thư';
					|ru = 'Не удалось извлечь двоичные данные сертификата';
					|en = 'Cannot extract binary certificate data.'; fa = 'Cannot extract binary certificate data.';
					|it = 'Impossibile estrarre i dati binari del certificato';
					|pl = 'Nie można wyodrębnić danych binarnych certyfikatu';
					|tr = 'Sertifika ikili verileri çıkarılamadı'"));
	EndIf;
	
	Return CertificateBinaryData;
	
EndFunction

Function GetBinaryDataOfCertificates(Certificates)
	
	BinaryCertificateData = New Array;
	
	If TypeOf(Certificates) = Type("Array") Or TypeOf(Certificates) = Type("FixedArray") Then
		CertificatesArray = Certificates;
	Else
		CertificatesArray = New Array;
		CertificatesArray.Add(Certificates);
	EndIf;
	
	For Each Certificate In CertificatesArray Do 
		BinaryCertificateData.Add(GetBinaryCertificateData(Certificate));	
	EndDo;
	
	Return BinaryCertificateData;
	
EndFunction

// Execute the cryptoservice method
// 
// Parameters: 
//  Method - String
//  MethodParameters - Structure:
//   * session_key - String
//   * ephemeral_key - String
//   * data - BinaryData
//          - String
// 
// Returns:
//  Arbitrary
// @unavailable-in-safemode
Function ExecuteCryptoserviceMethod(Method, MethodParameters) Export
	
	SetPrivilegedMode(True);
	ServiceAddress = Constants.CryptoServiceAddress.Get();
	SetPrivilegedMode(False);
	
	ConnectionParameters = CryptographyServiceManager.GetConnectionParameters(ServiceAddress);
	Join = DigitalSignatureSaaS.ConnectingToInternetServer(ConnectionParameters);
	
	UploadDataForProcessingToServer(Join, MethodParameters);
	
	Result = ExecuteServiceMethod(Join, Method, MethodParameters);
	
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

Function ResourceAddress(Method)
	
	Return StrTemplate("/api/%1/%2", SoftwareInterfaceVersion(), Method);
	
EndFunction

Function CallHTTPMethod(Join, Method_HTTP, Query)
	
	Try		
		Response = Join.CallHTTPMethod(Method_HTTP, Query);
	Except
		// @skip-check module-nstr-camelcase - verification error
		WriteLogEvent(
			NStr("vi = 'Chữ ký điện tử trong mô hình dịch vụ.Dịch vụ mã hóa.Thực hiện truy vấn';
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

// Parameters: 
//  Join - HTTPConnection
//  Method - String
//  MethodParameters - Structure:
// * ephemeral_key - String
// * data - BinaryData
// 		  - String
// 
// Returns: 
//  Arbitrary -Execute the service method
Function ExecuteServiceMethod(Join, Method, MethodParameters)
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/json");
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
	
Procedure LogErroneousResponseFromService(ResourceAddress, ServerResponse1)
	
	// @skip-check module-nstr-camelcase - verification error
	WriteLogEvent(
		NStr("vi = 'Chữ ký điện tử trong mô hình dịch vụ.Dịch vụ mã hóa.Thực hiện truy vấn';
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

Function ConvertOID(ListOfOIDs)
	
	Properties = New Structure;
	For Each RDN In ListOfOIDs Do
		Properties.Insert(GetNameByOID(RDN.OID), RDN.Value);
	EndDo;
	
	Return New FixedStructure(Properties);
	
EndFunction

Function ExtendedCertificateProperties(ListOfOIDs)
	
	EKU = New Array;
	For Each OID In ListOfOIDs Do
		Name = GetNameByOID(OID, "");
		If ValueIsFilled(Name) Then
			EKU.Add(StrTemplate("%1 (%2)", Name, OID));
		Else
			EKU.Add(OID);
		EndIf;
	EndDo;

	EKU = New FixedArray(EKU);
	
	Return New FixedStructure(New Structure("EKU", EKU));
	
EndFunction

// Returns the properties of certificates.
// 
// Parameters:
// 	ListOfSerialNumberPublisherPairs - FixedArray of Structure - publisher's data.
// Returns:
// 	Array of FixedStructure - LongDesc:
//	* SerialNumber - String - 
//	* Issuer - String - 
//	* Id - String - 
Function GetCertificatePropertiesFromJson(ListOfSerialNumberPublisherPairs) Export
	
	Certificates = New Array;
	
	For Each Pair In ListOfSerialNumberPublisherPairs Do
		Certificate = New Structure;
		Certificate.Insert("SerialNumber", Pair.serial_number);
		Certificate.Insert("Issuer", ConvertOID(Pair.issuer));
		If Pair.Property("certificate_id") Then
			Certificate.Insert("Id", (Pair.certificate_id));
		EndIf;
		
		Certificates.Add(New FixedStructure(Certificate));
	EndDo;
	
	Return Certificates;

EndFunction

Function GetNameByOID(OID, DefaultName = Undefined)
	
	Name = MatchingOIDName().Get(OID);
	If Name = Undefined Then
		If DefaultName <> Undefined Then
			Name = DefaultName;
		Else
			Name = "_" + StrReplace(OID, ".", "_");
		EndIf;
	EndIf;
	
	Return Name;
	
EndFunction

// Prepares the matching of names and OIDs in the certificate
//
// Returns:
//	Map
//
Function MatchingOIDName()
	
	OIDMap = New Map;
	OIDMap.Insert("2.5.4.3", "CN"); // commonName
	OIDMap.Insert("2.5.4.6", "C"); // countryName
	OIDMap.Insert("2.5.4.8", "ST"); // stateOrProvinceName
	OIDMap.Insert("2.5.4.7", "L"); // localityName
	OIDMap.Insert("2.5.4.9", "STREET"); // streetAddress
	OIDMap.Insert("2.5.4.10", "O"); // organizationName
	OIDMap.Insert("2.5.4.11", "OU"); // organizationUnitName
	OIDMap.Insert("2.5.4.12", "T"); // title
	OIDMap.Insert("1.2.643.100.1", "OGRN"); // OGRN
	OIDMap.Insert("1.2.643.100.5", "OGRNIP"); // OGRNIE
	OIDMap.Insert("1.2.643.100.3", "SNILS"); // SNILS
	OIDMap.Insert("1.2.643.3.131.1.1", "INN"); // TIN
	OIDMap.Insert("1.2.643.100.4", "INNLE"); // INN YUL
	OIDMap.Insert("1.2.840.113549.1.9.1", "E"); // emailAddress	
	OIDMap.Insert("2.5.4.4", "SN"); // surname
	OIDMap.Insert("2.5.4.42", "GN"); // givenName
	
	Return OIDMap;
	
EndFunction

Function MatchingOIDName_()
	
	OIDMap = New Map;
	OIDMap.Insert("CN", "2.5.4.3"); // commonName
	OIDMap.Insert("C", "2.5.4.6"); // countryName
	OIDMap.Insert("ST", "2.5.4.8"); // stateOrProvinceName
	OIDMap.Insert("L", "2.5.4.7"); // localityName
	OIDMap.Insert("STREET", "2.5.4.9"); // streetAddress
	OIDMap.Insert("O", "2.5.4.10"); // organizationName
	OIDMap.Insert("OU", "2.5.4.11"); // organizationUnitName
	OIDMap.Insert("T", "2.5.4.12"); // title
	OIDMap.Insert("OGRN", "1.2.643.100.1"); // OGRN
	OIDMap.Insert("OGRNIP", "1.2.643.100.5"); // OGRNIE
	OIDMap.Insert("SNILS", "1.2.643.100.3"); // SNILS
	OIDMap.Insert("INN", "1.2.643.3.131.1.1"); // TIN
	OIDMap.Insert("INNLE", "1.2.643.100.4"); // INN YUL
	OIDMap.Insert("E", "1.2.840.113549.1.9.1"); // emailAddress	
	OIDMap.Insert("SN", "2.5.4.4"); // surname
	OIDMap.Insert("GN", "2.5.4.42"); // givenName
	
	Return OIDMap;
	
EndFunction

// Calculates and returns the ID of the certificate.
// 
// Parameters: 
//  SerialNumber - String
//  Issuer - ValueList of String
// 
// Returns:
//  String
Function CalculateCertificateID(SerialNumber, Issuer) Export
	
	MatchingOIDName_ = MatchingOIDName_();
	For Each Item In Issuer Do
		If MatchingOIDName_.Get(Item.Presentation) <> Undefined Then
			Item.Presentation = MatchingOIDName_.Get(Item.Presentation);
		EndIf;
	EndDo;
	
	Return CertificateID(SerialNumber, Issuer);
	
EndFunction

Function CertificateID(SerialNumber, ListOfOIDs)
	
	Keys = StrSplit("2.5.4.3,2.5.4.4,2.5.4.6,2.5.4.7,2.5.4.8,2.5.4.10,2.5.4.11,2.5.4.12,2.5.4.42,1.2.840.113549.1.9.1", ",");
	Properties = New ValueList;
	For Each Item In ListOfOIDs Do
		If Keys.Find(Item.Presentation) <> Undefined Then
			Properties.Add(Item.Value, Item.Presentation);
		EndIf;
	EndDo;
	
	SerialNumberString = Lower(StrReplace(SerialNumber, " ", ""));
	
	Properties.SortByPresentation(SortDirection.Asc);
	
	ArrayOfValues = Properties.UnloadValues();
	
	ArrayOfValues.Add(SerialNumberString);
	
	CertificateAuthorityAndSerialNumber = StrConcat(ArrayOfValues, "#");
	
	Hashing = New DataHashing(HashFunction.SHA1);
	Hashing.Append(CertificateAuthorityAndSerialNumber);
	
	Return Lower(StrReplace(Hashing.HashSum, " ", ""));	
	
EndFunction

Function CalculateJSONCertificateID(CertificateProperties)
	
	Properties = New ValueList;
	For Each RDN In CertificateProperties.issuer Do
		Properties.Add(RDN.value, RDN.oid);
	EndDo;
	
	Return CertificateID(CertificateProperties.serial_number, Properties)
	
EndFunction

Function PrepareCertificateVerificationModes(CertificateCheckModes)
	
	RowsArray = StrSplit(CertificateCheckModes, ",", False);
	ArrayOfModes = New Array;
	For Each ArrayRow In RowsArray Do
		CurrentValue = Lower(TrimAll(ArrayRow));
		NewValue = "";
		If CurrentValue = Lower("IgnoreTimeValidity") Then
			NewValue = "IgnoreTimeValidity";
		ElsIf CurrentValue = Lower("IgnoreSignatureValidity") Then
			NewValue = "IgnoreSignatureValidity";
		ElsIf CurrentValue = Lower("IgnoreCertificateRevocationStatus") Then
			NewValue = "IgnoreCertificateRevocationStatus";
		ElsIf CurrentValue = Lower("AllowTestCertificates") Then
			NewValue = "AllowTestCertificates";
		Else
			NewValue = TrimAll(ArrayRow);
		EndIf;
		
		If ValueIsFilled(NewValue) Then
			ArrayOfModes.Add(NewValue);
		EndIf;
		
	EndDo;
	
	Result = StrConcat(ArrayOfModes, ",");
	
	Return Result;
	
EndFunction

#Region CheckingInputParameters

Procedure EncryptCheckIncomingParameters(Data, Recipients, EncryptionType, EncryptionParameters)

	CommonClientServer.CheckParameter(
		"CryptographyService.Encrypt", 
		"Data",
		Data, 
		New TypeDescription("BinaryData, Array, String"));
	
	CommonClientServer.CheckParameter(
		"CryptographyService.Encrypt", 
		"Recipients",
		Recipients, 
		New TypeDescription("BinaryData, Structure, FixedStructure, Array, FixedArray"));
	
	CommonClientServer.CheckParameter(
		"CryptographyService.Encrypt", 
		"EncryptionType",
		EncryptionType, 
		New TypeDescription("String"));
	
	CommonClientServer.Validate(
		EncryptionType = "CMS",
		StrTemplate(NStr("vi = 'Giá trị tham số %1 không hợp lệ (kiểu mã hóa không xác định)';
						|ru = 'Недопустимое значение параметра %1 (неизвестный тип шифрования)';
						|en = 'Incorrect value of the %1 parameter (unknown encryption type)'; fa = 'Incorrect value of the %1 parameter (unknown encryption type)';
						|it = 'Valore del parametro %1 non valido (tipo di crittografia sconosciuto)';
						|pl = 'Niepoprawna wartość dla %1%1 (nieznany typ szyfrowania)';
						|tr = '%1 parametresinin geçersiz değeri (bilinmeyen şifreleme türü)'"),
			"EncryptionType"),
		"CryptographyService.Encrypt");
	
	If ValueIsFilled(EncryptionParameters) Then
		CommonClientServer.CheckParameter(
			"CryptographyService.Encrypt", 
			"EncryptionParameters",
			EncryptionParameters, 
			New TypeDescription("Structure, FixedStructure"));
	EndIf;
	
	If TypeOf(Data) = Type("String") Then 
		CommonClientServer.Validate(
				IsTempStorageURL(Data),
				NStr("vi = 'Giá trị tham số Данные không hợp lệ (đã chỉ ra địa chỉ là địa chỉ kho chứa tạm thời)';
					|ru = 'Недопустимое значение параметра Данные (указан адрес, который не является адресом временного хранилища)';
					|en = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).'; fa = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).';
					|it = 'Valore del parametro Dati non valido (è stato indicato l''indirizzo diverso da quello del repository temporaneo)';
					|pl = 'Niepoprawna wartość parametru Data (podany jest adres, który nie jest adresem tymczasowego repozytorium)';
					|tr = 'Veri parametresi için geçersiz değer (geçici depolama adresi olmayan adres belirtilmiş)'"), 
				"CryptographyService.Encrypt");
	EndIf;	
	If TypeOf(Data) <> Type("Array") Then 
		Return;
	EndIf;
	
	IndexOf = 0;
	For Each Item In Data Do
		CommonClientServer.CheckParameter(
			"CryptographyService.Encrypt", 
			StrTemplate("Data[%1]", IndexOf),
			Item, 
			New TypeDescription("String, BinaryData"));
		
		If TypeOf(Item) = Type("String") Then
			CommonClientServer.Validate(
				IsTempStorageURL(Item),
				StrTemplate(NStr("vi = 'Giá trị tham số không hợp lệ Данные[%1] (đã chỉ ra địa chỉ không phải là địa chỉ kho chứa tạm thời)';
								|ru = 'Недопустимое значение параметра Данные[%1] (указан адрес, который не является адресом временного хранилища)';
								|en = 'Invalid value of the Data [%1] parameter (the specified address is not a temporary storage address).'; fa = 'Invalid value of the Data [%1] parameter (the specified address is not a temporary storage address).';
								|it = 'Valore del parametro Dati[%1] non valido (è stato indicato l''indirizzo diverso da quello del repository temporaneo)';
								|pl = 'Niepoprawna wartość parametru Data[%1] (podany jest adres, który nie jest adresem tymczasowego repozytorium)';
								|tr = 'Veri[%1] parametresi için geçersiz değer (geçici depolama adresi olmayan adres belirtilmiş)'"), IndexOf), 
				"CryptographyService.Encrypt");
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
EndProcedure

Procedure EncryptCheckIncomingParametersBlock(Data, Recipient)

	CommonClientServer.CheckParameter(
		"CryptographyService.EncryptBlock", 
		"Data",
		Data, 
		New TypeDescription("BinaryData, String"));
	
	CommonClientServer.CheckParameter(
		"CryptographyService.EncryptBlock", 
		"Recipient",
		Recipient, 
		New TypeDescription("BinaryData, Structure, FixedStructure"));
	
	If TypeOf(Data) = Type("String") Then 
		CommonClientServer.Validate(
				IsTempStorageURL(Data),
				NStr("vi = 'Giá trị tham số Данные không hợp lệ (đã chỉ ra địa chỉ là địa chỉ kho chứa tạm thời)';
					|ru = 'Недопустимое значение параметра Данные (указан адрес, который не является адресом временного хранилища)';
					|en = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).'; fa = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).';
					|it = 'Valore del parametro Dati non valido (è stato indicato l''indirizzo diverso da quello del repository temporaneo)';
					|pl = 'Niepoprawna wartość parametru Data (podany jest adres, który nie jest adresem tymczasowego repozytorium)';
					|tr = 'Veri parametresi için geçersiz değer (geçici depolama adresi olmayan adres belirtilmiş)'"), 
				"CryptographyService.EncryptBlock");
	EndIf;	
			
EndProcedure

Procedure DecryptCheckingIncomingParameters(EncryptedData, EncryptionType, EncryptionParameters)
	
	CommonClientServer.CheckParameter(
		"CryptographyService.Decrypt", 
		"EncryptedData",
		EncryptedData, 
		New TypeDescription("BinaryData, String"));
	
	CommonClientServer.CheckParameter(
		"CryptographyService.Decrypt", 
		"EncryptionType",
		EncryptionType, 
		New TypeDescription("String"));
	
	CommonClientServer.Validate(
		EncryptionType = "CMS",
		StrTemplate(NStr("vi = 'Giá trị tham số %1 không hợp lệ (kiểu mã hóa không xác định)';
						|ru = 'Недопустимое значение параметра %1 (неизвестный тип шифрования)';
						|en = 'Incorrect value of the %1 parameter (unknown encryption type)'; fa = 'Incorrect value of the %1 parameter (unknown encryption type)';
						|it = 'Valore del parametro %1 non valido (tipo di crittografia sconosciuto)';
						|pl = 'Niepoprawna wartość dla %1%1 (nieznany typ szyfrowania)';
						|tr = '%1 parametresinin geçersiz değeri (bilinmeyen şifreleme türü)'"),
			"EncryptionType"),
		"CryptographyService.Decrypt");
	
	If ValueIsFilled(EncryptionParameters) Then
		CommonClientServer.CheckParameter(
			"CryptographyService.Decrypt", 
			"EncryptionParameters",
			EncryptionParameters, 
			New TypeDescription("Structure, FixedStructure"));
	EndIf;
	
	If TypeOf(EncryptedData) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(EncryptedData),
			StrTemplate(NStr("vi = 'Giá trị tham số %1 không hợp lệ (chỉ ra địa chỉ không phải là địa chỉ kho chứa tạm thời)';
							|ru = 'Недопустимое значение параметра %1 (указан адрес, который не является адресом временного хранилища)';
							|en = 'Incorrect value of the %1 parameter (the specified address is not a temporary storage address)'; fa = 'Incorrect value of the %1 parameter (the specified address is not a temporary storage address)';
							|it = 'Valore del parametro %1 non valido (è stato indicato l''indirizzo diverso da quello del repository temporaneo)';
							|pl = 'Niepoprawna wartość parametru %1 (podany jest adres, który nie jest adresem tymczasowego repozytorium)';
							|tr = '%1 parametresi için geçersiz değer (geçici depolama adresi olmayan adres belirtilmiş)'"),
				"EncryptedData"),
			"CryptographyService.Decrypt");
	EndIf;
		
EndProcedure

Procedure DecryptCheckIncomingParametersBlock(EncryptedData, Recipient, KeyInformation, EncryptionParameters)
	
	CommonClientServer.CheckParameter(
		"CryptographyService.DecryptBlock", 
		"EncryptedData",
		EncryptedData, 
		New TypeDescription("BinaryData, String"));
		
	CommonClientServer.CheckParameter(
		"CryptographyService.DecryptBlock", 
		"Recipient",
		Recipient, 
		New TypeDescription("BinaryData, Structure, FixedStructure"));
	
	CommonClientServer.CheckParameter(
		"CryptographyService.DecryptBlock", 
		"KeyInformation",
		KeyInformation, 
		New TypeDescription("Structure"));
	
	CommonClientServer.Validate(
		KeyInformation.Property("ephemeral_key")
		And KeyInformation.Property("iv_data")
		And KeyInformation.Property("session_key"),
		StrTemplate(NStr("vi = 'Không có một và/hoặc thuộc tính bắt buộc của tham số %1 (%2)';
						|ru = 'Отсутствует одно и/или более обязательных свойств параметра %1 (%2)';
						|en = 'One or more required properties of the %1 (%2) parameter are missing'; fa = 'One or more required properties of the %1 (%2) parameter are missing';
						|it = 'Manca una o più proprietà obbligatorie del parametro %1 (%2)';
						|pl = 'Nie ma jednego i/lub więcej obowiązkowych właściwości parametru %1 (%2)';
						|tr = '%1 parametresinin bir ve/veya daha fazla zorunlu özelliği eksik  (%2)'"),
			"KeyInformation", "ephemeral_key|session_key|iv_data"),
		"CryptographyService.DecryptBlock");
		
	CommonClientServer.CheckParameter(
		"CryptographyService.DecryptBlock", 
		"KeyInformation.ephemeral_key",
		KeyInformation.ephemeral_key, 
		New TypeDescription("BinaryData, String"));
		
	CommonClientServer.CheckParameter(
		"CryptographyService.DecryptBlock", 
		"KeyInformation.session_key",
		KeyInformation.session_key, 
		New TypeDescription("BinaryData, String"));
		
	CommonClientServer.CheckParameter(
		"CryptographyService.DecryptBlock", 
		"KeyInformation.iv_data",
		KeyInformation.iv_data, 
		New TypeDescription("BinaryData, String"));
		
	If ValueIsFilled(EncryptionParameters) Then
		CommonClientServer.CheckParameter(
			"CryptographyService.DecryptBlock", 
			"EncryptionParameters",
			EncryptionParameters, 
			New TypeDescription("Structure, FixedStructure"));
	EndIf;
	
	If TypeOf(EncryptedData) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(EncryptedData),
			StrTemplate(NStr("vi = 'Giá trị tham số %1 không hợp lệ (chỉ ra địa chỉ không phải là địa chỉ kho chứa tạm thời)';
							|ru = 'Недопустимое значение параметра %1 (указан адрес, который не является адресом временного хранилища)';
							|en = 'Incorrect value of the %1 parameter (the specified address is not a temporary storage address)'; fa = 'Incorrect value of the %1 parameter (the specified address is not a temporary storage address)';
							|it = 'Valore del parametro %1 non valido (è stato indicato l''indirizzo diverso da quello del repository temporaneo)';
							|pl = 'Niepoprawna wartość parametru %1 (podany jest adres, który nie jest adresem tymczasowego repozytorium)';
							|tr = '%1 parametresi için geçersiz değer (geçici depolama adresi olmayan adres belirtilmiş)'"),
				"EncryptedData"),
			"CryptographyService.DecryptBlock");
	EndIf;
		
EndProcedure

Procedure HashingDataCheckingIncomingParameters(Data, HashAlgorithm, HashingParameters)

	CommonClientServer.CheckParameter(
		"CryptographyService.DataHashing", 
		"Data",
		Data, 
		New TypeDescription("BinaryData, String"));
	
	If TypeOf(Data) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(Data),
			NStr("vi = 'Giá trị tham số Данные không hợp lệ (đã chỉ ra địa chỉ là địa chỉ kho chứa tạm thời)';
				|ru = 'Недопустимое значение параметра Данные (указан адрес, который не является адресом временного хранилища)';
				|en = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).'; fa = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).';
				|it = 'Valore del parametro Dati non valido (è stato indicato l''indirizzo diverso da quello del repository temporaneo)';
				|pl = 'Niepoprawna wartość parametru Data (podany jest adres, który nie jest adresem tymczasowego repozytorium)';
				|tr = 'Veri parametresi için geçersiz değer (geçici depolama adresi olmayan adres belirtilmiş)'"), 
			"CryptographyService.DataHashing");
	EndIf;
	
	CommonClientServer.Validate(
		StrSplit("GOST R 34.11-94^GOST R 34.11-2012 256^GOST R 34.11-2012 512", "^").Find(HashAlgorithm) <> Undefined,
		StrTemplate(NStr("vi = 'Giá trị tham số %1 không hợp lệ (thuật toán hàm băm không xác định)';
						|ru = 'Недопустимое значение параметра %1 (неизвестный алгоритм хеширования)';
						|en = 'Invalid value of the %1 parameter (unknown hashing algorithm)'; fa = 'Invalid value of the %1 parameter (unknown hashing algorithm)';
						|it = 'Valore del parametro %1 non valido (algoritmo di hashing non valido)';
						|pl = 'Niepoprawna wartość parametru %1 (nieznany algorytm hash)';
						|tr = '%1 parametresinin geçersiz değeri (bilinmeyen karma algoritması)'"),
			"HashAlgorithm"),
		"CryptographyService.DataHashing");
		
	If ValueIsFilled(HashingParameters) Then
		CommonClientServer.CheckParameter(
			"CryptographyService.DataHashing", 
			"HashingParameters",
			HashingParameters, 
			New TypeDescription("Structure, FixedStructure"));
	EndIf;
	
EndProcedure

Procedure SignCheckIncomingParameters(Data, Signatory, SignatureType, SigningParameters)

	CommonClientServer.CheckParameter(
		"CryptographyService.Sign", 
		"Data",
		Data, 
		New TypeDescription("BinaryData, Array, String"));
	
	CommonClientServer.CheckParameter(
		"CryptographyService.Sign", 
		"Signatory",
		Signatory, 
		New TypeDescription("BinaryData, Structure, FixedStructure"));
	
	CommonClientServer.CheckParameter(
		"CryptographyService.Sign", 
		"SignatureType",
		SignatureType, 
		New TypeDescription("String"));
	
	CommonClientServer.Validate(
		SignatureType = "CMS" Or SignatureType = "GOST3410",
		StrTemplate(NStr("vi = 'Giá trị tham số %1 không hợp lệ (kiểu chữ ký không xác định)';
						|ru = 'Недопустимое значение параметра %1 (неизвестный тип подписи)';
						|en = 'Invalid value of the %1 parameter (unknown signature type)'; fa = 'Invalid value of the %1 parameter (unknown signature type)';
						|it = 'Valore del parametro %1 non valido (tipo di firma sconosciuto)';
						|pl = 'Niepoprawna wartość dla %1 (nieznany typ podpisu)';
						|tr = '%1 parametresinin geçersiz değeri (bilinmeyen imza türü)'"),
			"SignatureType"),
		"CryptographyService.Sign");
	
	If ValueIsFilled(SigningParameters) Then
		CommonClientServer.CheckParameter(
			"CryptographyService.Sign", 
			"SigningParameters",
			SigningParameters, 
			New TypeDescription("Structure, FixedStructure"));
	EndIf;
	
	If TypeOf(Data) = Type("String") Then 
		CommonClientServer.Validate(
				IsTempStorageURL(Data),
				NStr("vi = 'Giá trị tham số Данные không hợp lệ (đã chỉ ra địa chỉ là địa chỉ kho chứa tạm thời)';
					|ru = 'Недопустимое значение параметра Данные (указан адрес, который не является адресом временного хранилища)';
					|en = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).'; fa = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).';
					|it = 'Valore del parametro Dati non valido (è stato indicato l''indirizzo diverso da quello del repository temporaneo)';
					|pl = 'Niepoprawna wartość parametru Data (podany jest adres, który nie jest adresem tymczasowego repozytorium)';
					|tr = 'Veri parametresi için geçersiz değer (geçici depolama adresi olmayan adres belirtilmiş)'"), 
				"CryptographyService.Sign");
	EndIf;	
	If TypeOf(Data) <> Type("Array") Then 
		Return;
	EndIf;
	
	IndexOf = 0;
	For Each Item In Data Do
		CommonClientServer.CheckParameter(
			"CryptographyService.Sign", 
			StrTemplate("Data[%1]", IndexOf),
			Item, 
			New TypeDescription("String, BinaryData"));
		
		If TypeOf(Item) = Type("String") Then
			CommonClientServer.Validate(
				IsTempStorageURL(Item),
				StrTemplate(NStr("vi = 'Giá trị tham số Данные không hợp lệ[%1] (đã chỉ ra địa chỉ không phải là địa chỉ kho chứa tạm thời)';
								|ru = 'Недопустимое значение параметра Данные[%1] (указан адрес, который не является адресом временного хранилища)';
								|en = 'Invalid value of the Data [%1] parameter (the specified address is not a temporary storage address).'; fa = 'Invalid value of the Data [%1] parameter (the specified address is not a temporary storage address).';
								|it = 'Valore del parametro Dati[%1] non valido (è stato indicato l''indirizzo diverso da quello del repository temporaneo)';
								|pl = 'Niepoprawna wartość parametru Data[%1] (podany jest adres, który nie jest adresem tymczasowego repozytorium)';
								|tr = 'Veri[%1] parametresi için geçersiz değer (geçici depolama adresi olmayan adres belirtilmiş)'"), IndexOf), 
				"CryptographyService.Sign");
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
		
EndProcedure

Procedure CheckSignatureCheckingIncomingParameters(Signature, Data, SignatureType, SigningParameters)

	CommonClientServer.CheckParameter(
		"CryptographyService.VerifySignature", 
		"Signature",
		Signature, 
		New TypeDescription("BinaryData, String"));
	
	If ValueIsFilled(SigningParameters) Then
		CommonClientServer.CheckParameter(
			"CryptographyService.VerifySignature", 
			"SigningParameters",
			SigningParameters, 
			New TypeDescription("Structure, FixedStructure"));
	EndIf;
	
	If Not ValueIsFilled(SigningParameters)
		Or Not SigningParameters.Property("DisconnectedSignature")
		Or Not SigningParameters.DisconnectedSignature Then
		CommonClientServer.CheckParameter(
			"CryptographyService.VerifySignature", 
			"Data",
			Data, 
			New TypeDescription("BinaryData, String"));
	EndIf;
	
	CommonClientServer.CheckParameter(
		"CryptographyService.VerifySignature", 
		"SignatureType",
		SignatureType, 
		New TypeDescription("String"));
	
	CommonClientServer.Validate(
		SignatureType = "CMS" Or SignatureType = "GOST3410",
		StrTemplate(NStr("vi = 'Giá trị tham số %1 không hợp lệ (kiểu chữ ký không xác định)';
						|ru = 'Недопустимое значение параметра %1 (неизвестный тип подписи)';
						|en = 'Invalid value of the %1 parameter (unknown signature type)'; fa = 'Invalid value of the %1 parameter (unknown signature type)';
						|it = 'Valore del parametro %1 non valido (tipo di firma sconosciuto)';
						|pl = 'Niepoprawna wartość dla %1 (nieznany typ podpisu)';
						|tr = '%1 parametresinin geçersiz değeri (bilinmeyen imza türü)'"),
			"SignatureType"),
		"CryptographyService.VerifySignature");
	
	If TypeOf(Signature) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(Signature),
			NStr("vi = 'Giá trị tham số Подпись không hợp lệ (đã chỉ ra địa chỉ không phải là địa chỉ kho chứa tạm thời)';
				|ru = 'Недопустимое значение параметра Подпись (указан адрес, который не является адресом временного хранилища)';
				|en = 'Invalid value of the Signature parameter (the specified address is not a temporary storage address).'; fa = 'Invalid value of the Signature parameter (the specified address is not a temporary storage address).';
				|it = 'Valore del parametro Firma non valido (è indicato l''indirizzo diverso da quello del repository temporaneo)';
				|pl = 'Niepoprawna wartość parametru Podpisu (podany adres nie jest adresem tymczasowego magazynu)';
				|tr = 'İmza parametresi için geçersiz değer (geçici depolama adresi olmayan adres belirtilmiş)'"), 
			"CryptographyService.VerifySignature");
	EndIf;
		
	If TypeOf(Data) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(Data),
			NStr("vi = 'Giá trị tham số Данные không hợp lệ (đã chỉ ra địa chỉ là địa chỉ kho chứa tạm thời)';
				|ru = 'Недопустимое значение параметра Данные (указан адрес, который не является адресом временного хранилища)';
				|en = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).'; fa = 'Invalid value of the Data parameter (the specified address is not a temporary storage address).';
				|it = 'Valore del parametro Dati non valido (è stato indicato l''indirizzo diverso da quello del repository temporaneo)';
				|pl = 'Niepoprawna wartość parametru Data (podany jest adres, który nie jest adresem tymczasowego repozytorium)';
				|tr = 'Veri parametresi için geçersiz değer (geçici depolama adresi olmayan adres belirtilmiş)'"), 
			"CryptographyService.VerifySignature");
	EndIf;
	
	If SignatureType = "GOST3410" Then 
		CommonClientServer.Validate(
			ValueIsFilled(SigningParameters) And SigningParameters.Property("Certificate"),
			NStr("vi = 'Để kiểm tra chữ ký theo tiêu chuẩn quốc tế 34.10-94, cần chỉ ra chứng thư';
				|ru = 'Для проверки подписи по ГОСТ Р 34.10-94 необходимо указание сертификата';
				|en = 'To check the signature according to GOST R 34.10-94, specify the certificate'; fa = 'To check the signature according to GOST R 34.10-94, specify the certificate';
				|it = 'Per verificare la firma in base al GOST R 34.10-94, è necessario indicare il certificato';
				|pl = 'Aby zweryfikować podpis zgodnie z GOST R 34.10-94, wymagane jest wskazanie certyfikatu';
				|tr = 'DS P 34.10-94 imzasını kontrol etmek için sertifikanın belirtilmesi gerekiyor'"), 
			"CryptographyService.VerifySignature");
	EndIf;
		
EndProcedure

Procedure GetPropertiesOfCryptographicMessageCheckingIncomingParameters(CryptoMessage)

	CommonClientServer.CheckParameter(
		"CryptographyService.GetCryptoMessageProperties", 
		"CryptoMessage",
		CryptoMessage, 
		New TypeDescription("BinaryData, String"));
	
	If TypeOf(CryptoMessage) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(CryptoMessage),
			NStr("vi = 'Giá trị tham số Криптосообщение không hợp lệ (đã chỉ ra địa chỉ không phải là địa chỉ kho chứa tạm thời)';
				|ru = 'Недопустимое значение параметра Криптосообщение (указан адрес, который не является адресом временного хранилища)';
				|en = 'Invalid value of the CryptoMessage parameter (the specified address is not a temporary storage address).'; fa = 'Invalid value of the CryptoMessage parameter (the specified address is not a temporary storage address).';
				|it = 'Valore del parametro MessaggioCrittografico non valido (è indicato l''indirizzo diverso da quello del repository temporaneo)';
				|pl = 'Niepoprawna wartość parametru Komunikatu kryptograficznego (podany adres nie jest adresem tymczasowego magazynu)';
				|tr = 'Kripto mesaj parametresi için geçersiz değer (geçici depolama adresi olmayan adres belirtilmiş)'"), 
			"CryptographyService.GetCryptoMessageProperties");
	EndIf;
		
EndProcedure

Procedure GetCertificatesFromSigningCheckIncomingParameters(Signature)
		
	CommonClientServer.CheckParameter(
		"CryptographyService.GetCertificatesFromSignature", 
		"Signature",
		Signature, 
		New TypeDescription("BinaryData, String"));
	
	If TypeOf(Signature) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(Signature),
			NStr("vi = 'Giá trị tham số không hợp lệ Chữ ký (đã chỉ ra địa chỉ mà không phải là địa chỉ kho chứa tạm thời)';
				|ru = 'Недопустимое значение параметра Подпись (указан адрес, который не является адресом временного хранилища)';
				|en = 'Invalid value of the Signature parameter (the specified address is not a temporary storage address).'; fa = 'Invalid value of the Signature parameter (the specified address is not a temporary storage address).';
				|it = 'Valore del parametro Firma non valido (è indicato l''indirizzo diverso da quello del repository temporaneo)';
				|pl = 'Niepoprawna wartość parametru Podpisu (podany adres nie jest adresem tymczasowego magazynu)';
				|tr = 'İmza parametresi için geçersiz değer (geçici depolama adresi olmayan adres belirtilmiş)'"), 
			"CryptographyService.GetCertificatesFromSignature");
	EndIf;
		
EndProcedure

Procedure CheckCertificateCheckIncomingParameters(Certificate)
		
	CommonClientServer.CheckParameter(
		"CryptographyService.CheckCertificate", 
		"Certificate",
		Certificate, 
		New TypeDescription("BinaryData, Structure"));
		
EndProcedure

Procedure GetCertificatePropertiesCheckIncomingParameters(Certificate)
	
	CommonClientServer.CheckParameter(
		"CryptographyService.GetCertificateProperties", 
		"Certificate",
		Certificate, 
		New TypeDescription("BinaryData, Structure"));
	
EndProcedure

Procedure GetTemporaryPasswordCheckIncomingParameters(CertificateID, Resending, PasswordsDeliveryMethod)

	CommonClientServer.CheckParameter(
		"CryptographyService.GetTemporaryPassword", 
		"CertificateID",
		CertificateID, 
		New TypeDescription("String"));

	CommonClientServer.CheckParameter(
		"CryptographyService.GetTemporaryPassword", 
		"Resending",
		Resending, 
		New TypeDescription("Boolean"));

	CommonClientServer.CheckParameter(
		"CryptographyService.GetTemporaryPassword", 
		"PasswordsDeliveryMethod",
		PasswordsDeliveryMethod, 
		New TypeDescription("String"));
		
	If TypeOf(PasswordsDeliveryMethod) = Type("String") Then
		CommonClientServer.Validate(
			PasswordsDeliveryMethod = "phone" Or PasswordsDeliveryMethod = "email",
			StrTemplate(NStr("vi = 'Giá trị tham số %1 không hợp lệ, giá trị hợp lệ ""%2"" hoặc ""%3""';
							|ru = 'Недопустимое значение параметра %1, допустимые значения ""%2"" или ""%3""';
							|en = 'Incorrect value of the %1 parameter. Valid values are ""%2"" or ""%3""'; fa = 'Incorrect value of the %1 parameter. Valid values are ""%2"" or ""%3""';
							|it = 'Valore del parametro %1 non accessibile, valori accessibili ""%2"" o ""%3""';
							|pl = 'Niedopuszczalna wartość parametru %1, dopuszczalne wartości ""%2"" lub ""%3""';
							|tr = 'Geçersiz parametre değeri %1, geçerli değerler ""%2"" veya ""%3""'"),
				"PasswordsDeliveryMethod", "phone", "email"),
			"CryptographyService.GetTemporaryPassword");
	EndIf;
		
EndProcedure
	
Function CertificateDescription(ListOfOIDs)
	
	For Each OIDElement In ListOfOIDs Do
		If OIDElement.OID = "2.5.4.3" Then
			Return OIDElement.Value;
		EndIf;
	EndDo;	
	
	Return "";
	
EndFunction
	
#EndRegion

#Region EventNames

Function EventNameEncryption()
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Dịch vụ mật mã.Mã hóa';
				|ru = 'Сервис криптографии.Шифрование';
				|en = 'Cryptography service.Encryption'; fa = 'Cryptography service.Encryption';
				|it = 'Servizio crittografico.Crittografia';
				|pl = 'Usługa szyfrowania.Szyfrowanie';
				|tr = 'Kriptografi servisi.Şifreleme'", Common.DefaultLanguageCode());
	
EndFunction

Function EventNameBlockEncryption()
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Dịch vụ mật mã.Mã hóa khối';
				|ru = 'Сервис криптографии.Шифрование блока';
				|en = 'Cryptography service.Block encryption'; fa = 'Cryptography service.Block encryption';
				|it = 'Servizio crittografico.Crittografia del blocco';
				|pl = 'Usługa szyfrowania.Szyfrowanie bloku';
				|tr = 'Kriptografi servisi.Blok şifrelemesi'", Common.DefaultLanguageCode());
	
EndFunction

Function EventNameDecryption()
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Dịch vụ mật mã.Diễn giải';
				|ru = 'Сервис криптографии.Расшифровка';
				|en = 'Cryptography service.Decryption'; fa = 'Cryptography service.Decryption';
				|it = 'Servizio crittografico.Decrittografia';
				|pl = 'Usługa szyfrowania.Deszyfrowanie';
				|tr = 'Kriptografi servisi.Şifre çözme'", Common.DefaultLanguageCode());
	
EndFunction

Function EventNameBlockDecryption()
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Dịch vụ mật mã.Diễn giải khối';
				|ru = 'Сервис криптографии.Расшифровка блока';
				|en = 'Cryptography service.Block decryption'; fa = 'Cryptography service.Block decryption';
				|it = 'Servizio crittografico.Decrittografia del blocco';
				|pl = 'Usługa szyfrowania.Deszyfrowanie bloku';
				|tr = 'Kriptografi servisi.Blok şifre çözme'", Common.DefaultLanguageCode());
	
EndFunction

Function EventNameAuthentication()
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Dịch vụ mật mã.Đăng nhập';
				|ru = 'Сервис криптографии.Аутентификация';
				|en = 'Cryptography service.Authentication'; fa = 'Cryptography service.Authentication';
				|it = 'Servizio crittografico.Autenticazione';
				|pl = 'Usługa szyfrowania.Autentyfikacja';
				|tr = 'Kriptografi servisi.Yetkilendirme'", Common.DefaultLanguageCode());
	
EndFunction

Function EventNamePropertiesOfCryptoMessage()
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Dịch vụ mật mã.Thuộc tính mã hóa tin nhắn';
				|ru = 'Сервис криптографии.Свойства криптосообщения';
				|en = 'Cryptography service.Crypto message properties'; fa = 'Cryptography service.Crypto message properties';
				|it = 'Servizio crittografico.Proprietà del messaggio crittografato';
				|pl = 'Usługa szyfrowania.Właściwości kryptograficzne';
				|tr = 'Kriptografi servisi.Kripto mesaj özellikleri'", Common.DefaultLanguageCode());
	
EndFunction

Function NameOfCertificateVerificationEvent()
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Dịch vụ mật mã.Kiểm tra chứng chỉ';
				|ru = 'Сервис криптографии.Проверка сертификата';
				|en = 'Cryptography service.Certificate check'; fa = 'Cryptography service.Certificate check';
				|it = 'Servizio crittografico.Verifica del certificato';
				|pl = 'Usługa szyfrowania.Weryfikacja certyfikatu';
				|tr = 'Kriptografi servisi.Sertifika kontrolü'", Common.DefaultLanguageCode());
	
EndFunction

Function NameOfCertificatePropertyEvent()
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Dịch vụ mật mã.Thuộc tính chứng chỉ';
				|ru = 'Сервис криптографии.Свойства сертификата';
				|en = 'Cryptography service.Certificate properties'; fa = 'Cryptography service.Certificate properties';
				|it = 'Servizio crittografico.Proprietà del certificato';
				|pl = 'Usługa szyfrowania.Właściwości certyfikatu';
				|tr = 'Kriptografi servisi.Sertifika özelliği'", Common.DefaultLanguageCode());
	
EndFunction

Function EventNameSignatureVerification()
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Dịch vụ mật mã.Kiểm tra chữ ký';
				|ru = 'Сервис криптографии.Проверка подписи';
				|en = 'Cryptography service.Signature check'; fa = 'Cryptography service.Signature check';
				|it = 'Servizio crittografico.Verifica della firma';
				|pl = 'Usługa szyfrowania.Weryfikacja podpisu';
				|tr = 'Kriptografi servisi.İmza kontrolü'", Common.DefaultLanguageCode());
	
EndFunction

Function EventNameHashing()
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Dịch vụ mật mã.Băm';
				|ru = 'Сервис криптографии.Хеширование';
				|en = 'Cryptography service.Hashing'; fa = 'Cryptography service.Hashing';
				|it = 'Servizio crittografico.Hashing';
				|pl = 'Usługa szyfrowania.Hashing';
				|tr = 'Kriptografi servisi.Karma'", Common.DefaultLanguageCode());
	
EndFunction

Function EventNameSigning()
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Dịch vụ mật mã.Ký tên';
				|ru = 'Сервис криптографии.Подписание';
				|en = 'Cryptography service.Signing'; fa = 'Cryptography service.Signing';
				|it = 'Servizio crittografico.Firma';
				|pl = 'Usługa szyfrowania.Podpisywanie';
				|tr = 'Kriptografi servisi.İmzala'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#EndRegion