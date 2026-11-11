////////////////////////////////////////////////////////////////////////////////
//
// The "Cryptography Service" subsystem.
//  
////////////////////////////////////////////////////////////////////////////////
//


#Region Internal

#Region GetSecurityToken

Procedure GetSecurityToken(CallbackOnCompletion, Id, OperationParametersList = Undefined) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Id", Id);
	Context.Insert("OperationParametersList", OperationParametersList);
	
	Notification = New CallbackDescription("GetSecurityTokenAfterReceiving", ThisObject, Context);
	#If MobileAppClient Or MobileClient Then
		PasswordEntryForm = "CommonForm.TemporaryPasswordInputMobileApplication";
	#Else
		PasswordEntryForm = "CommonForm.TemporaryPasswordInput";
	#EndIf
	
	CertificateData = New Structure("Id", Id);
	OpenForm(
		PasswordEntryForm, 
		New Structure("Certificate, OperationParametersList", CertificateData, OperationParametersList),
		,,,, 
		Notification);
		
EndProcedure

// Parameters:
// 	Result - Undefined, Structure - result of the handler execution.
// 	IncomingContext - Structure - Incoming Context:
// 	 * CallbackOnCompletion - CallbackDescription - notification.
// 	 * Id - String - the operation identifier.
// 	 * OperationParametersList - Structure - parameters.
Procedure GetSecurityTokenAfterReceiving(Result, IncomingContext) Export
	
	ExecutionResult = New Structure("Completed2", False);
	If TypeOf(Result) = Type("Structure") Then
		If Result.State = "ChangingSettingsForGettingTemporaryPasswords" Then
			Notification = New CallbackDescription("GetSecurityTokenAfterChangingSettingsToGetTemporaryPasswords", ThisObject, IncomingContext);
			DigitalSignatureSaaSClient.ChangeSettingsForGettingTemporaryPasswords(Result.Certificate, Notification);
			Return;
		ElsIf Result.State = "ChangingMethodOfConfirmingCryptoOperation" Then
			Notification = New CallbackDescription("GetSecurityTokenAfterReceiving", ThisObject, IncomingContext);
			DigitalSignatureSaaSClient.ChangeWayCryptoOperationsAreConfirmed(Result.Certificate, Notification);
			Return;
		ElsIf Result.State = "ContinueReceivingSecurityToken" Then
			GetSecurityToken(IncomingContext.CallbackOnCompletion, IncomingContext.Id, IncomingContext.OperationParametersList);	
			Return;
		ElsIf Result.State = "PasswordNotAccepted" Then
			ExceptionText = Result.ErrorDescription;
		ElsIf Result.State = "PasswordAccepted" Then
			ExecutionResult.Insert("Completed2", True);	
		EndIf;
	Else
		ExceptionText = NStr("vi = 'Người sử dụng từ chối nhập mật khẩu';
							|ru = 'Пользователь отказался от ввода пароля';
							|en = 'The user refused to enter the password'; fa = 'The user refused to enter the password';
							|it = 'L''utente ha rifiutato di inserire la password';
							|pl = 'Użytkownik odmówił podania hasła';
							|tr = 'Kullanıcı şifreyi girmekten vazgeçti'");
	EndIf;
	
	
	If Not ExecutionResult.Completed2 Then
		Try
			Raise(ExceptionText);
		Except
			ErrorInfo = ErrorInfo();
		EndTry;
		ExecutionResult.Insert("ErrorInfo", ErrorInfo);
	EndIf;
	
	RunCallback(IncomingContext.CallbackOnCompletion, ExecutionResult);
	
EndProcedure

// Parameters:
// 	Result - See GetSecurityTokenAfterReceiving.Result
// 	IncomingContext - See GetSecurityTokenAfterReceiving.IncomingContext
Procedure GetSecurityTokenAfterChangingSettingsToGetTemporaryPasswords(Result, IncomingContext) Export
	
	If TypeOf(Result) = Type("Structure") Then
		If Result.PhoneNumberChanged Or Result.EmailChanged Then
			GetSecurityToken(IncomingContext.CallbackOnCompletion, IncomingContext.Id, IncomingContext.OperationParametersList);	
		Else
			GetSecurityTokenAfterReceiving(Undefined, IncomingContext);	
		EndIf;
	Else
		GetSecurityTokenAfterReceiving(Undefined, IncomingContext);
	EndIf;
		
EndProcedure

#EndRegion

#Region Encrypt

Procedure Encrypt(CallbackOnCompletion, Data, Recipients, EncryptionType = "CMS", EncryptionParameters = Undefined) Export
	
	Notification = New CallbackDescription(
		"EncryptAfterCompletion", 
		ThisObject, 
		New Structure("CallbackOnCompletion", CallbackOnCompletion));
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.Encrypt(Data, Recipients, EncryptionType, EncryptionParameters));
	
EndProcedure

Procedure EncryptBlock(CallbackOnCompletion, Data, Recipient) Export
	
	Notification = New CallbackDescription(
		"EncryptAfterCompletion", 
		ThisObject, 
		New Structure("CallbackOnCompletion", CallbackOnCompletion));
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.EncryptBlock(Data, Recipient));
	
EndProcedure
	
Procedure EncryptAfterCompletion(TimeConsumingOperation, IncomingContext) Export
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	If Result.Completed2 Then
		Result.Insert("EncryptedData", Result.ExecutionResult);
		Result.Delete("ExecutionResult");
	EndIf;
	
	RunCallback(IncomingContext.CallbackOnCompletion, Result);

EndProcedure

#EndRegion

#Region Decrypt

Procedure Decrypt(CallbackOnCompletion, EncryptedData, EncryptionType = "CMS", EncryptionParameters = Undefined) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("EncryptedData", EncryptedData);
	Context.Insert("EncryptionType", EncryptionType);
	Context.Insert("EncryptionParameters", EncryptionParameters);
	
	Notification = New CallbackDescription("DecryptAfterReceivingPropertiesOfCryptoMessage", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.GetCryptoMessageProperties(EncryptedData, True));	
	
EndProcedure

Procedure DecryptBlock(CallbackOnCompletion, EncryptedData, Recipient, KeyInformation, EncryptionParameters = Undefined) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("EncryptedData", EncryptedData);
	Context.Insert("Recipient", Recipient);
	Context.Insert("KeyInformation", KeyInformation);
	Context.Insert("EncryptionParameters", EncryptionParameters);
	
	Notification = New CallbackDescription("DecryptBlockAfterDecryption", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.DecryptBlock(EncryptedData, Recipient, KeyInformation, EncryptionParameters));	
	
	EndProcedure
	
Procedure DecryptAfterReceivingPropertiesOfCryptoMessage(TimeConsumingOperation, IncomingContext) Export
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	MessageProperties = Undefined;
	
	RecipientsField = "Recipients";
	IdField = "Id";
	
	If Result.Completed2 Then
		MessageProperties = Result.ExecutionResult;

		IDs = New Array;
		If MessageProperties.Type = "envelopedData" Then
			For Each Recipient In MessageProperties[RecipientsField] Do
				If Recipient.Property(IdField) Then
					IDs.Add(Recipient[IdField]);
				EndIf;
			EndDo;			
		Else
			Try
				Raise StrTemplate(NStr("vi = 'Giá trị tham số %1 không hợp lệ - tệp không phải là thông điệp mã hóa';
										|ru = 'Недопустимое значение параметра %1 - файл не является криптосообщением';
										|en = 'Incorrect value of the %1 parameter. The file is not a crypto message'; fa = 'Incorrect value of the %1 parameter. The file is not a crypto message';
										|it = 'Valore del parametro %1%1 non valido - il file non è un messaggio crittografico';
										|pl = 'Niepoprawna wartość parametru %1 - plik nie jest wiadomością kryptograficzną';
										|tr = '%1 parametresinin hatalı değeri - dosya kripto mesaj değil'"),
					"EncryptedData");
			Except
				ExecutionResult = PrepareNegativeResult(ErrorInfo());
				RunCallback(IncomingContext.CallbackOnCompletion, ExecutionResult);
				Return;
			EndTry;	
		EndIf;
		
		If Not ValueIsFilled(IDs) Then
			Try
				Raise(NStr("vi = 'Trong kho chứa không có chứng thực để giải mã tin nhắn.';
							|ru = 'В хранилище отсутствуют сертификаты для расшифровки сообщения.';
							|en = 'There are no certificates for message decryption in storage.'; fa = 'There are no certificates for message decryption in storage.';
							|it = 'Non ci sono i certificati nel repository per decifrare il messaggio.';
							|pl = 'W repozytorium nie ma żadnych certyfikatów do odszyfrowania wiadomości.';
							|tr = 'Depolamada mesajı deşifre etmek için sertifika bulunmuyor.'"));
			Except
				ExecutionResult = PrepareNegativeResult(ErrorInfo());
				RunCallback(IncomingContext.CallbackOnCompletion, ExecutionResult);
				Return;
			EndTry;
		EndIf;
		
		If IDs.Count() > 1 Then
			IDs = CryptographyServiceInternalServerCall.DetermineOrderOfCertificates(IDs);
		EndIf;

		IncomingContext.Insert("IDs", IDs);
		IncomingContext.Insert("CurrentID", 0);
		IncomingContext.Insert(RecipientsField, MessageProperties[RecipientsField]);
		IncomingContext.Insert("ErrorsDetails", New Array);
		DecryptByIteratingOverCertificates(IncomingContext);
	Else		
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);
		If TypeOf(Result) = Type("Structure") And Result.Property("ExecutionResult") Then 
			MessageProperties = Result.ExecutionResult;
		EndIf;
		If ValueIsFilled(MessageProperties) And MessageProperties.Property(RecipientsField) Then
			ExecutionResult.Insert(RecipientsField, MessageProperties[RecipientsField]);
		EndIf;
		RunCallback(IncomingContext.CallbackOnCompletion, ExecutionResult);
	EndIf;

EndProcedure

Procedure DecryptAfterDecryption(TimeConsumingOperation, IncomingContext) Export
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		If TypeOf(Result.ExecutionResult) = Type("Structure") Then
			If Result.ExecutionResult.ReturnCode = "AuthenticationRequired" Then
				Notification = New CallbackDescription("DecryptAfterReceivingSecurityToken", ThisObject, IncomingContext);
				GetSecurityToken(Notification, Result.ExecutionResult.Id, IncomingContext.EncryptionParameters);
			Else
				Raise(NStr("vi = 'Dạng trả lại không xác định';
							|ru = 'Неизвестный код возврата';
							|en = 'Unknown return code'; fa = 'Unknown return code';
							|it = 'Codice restituito sconosciuto';
							|pl = 'Nieznany kod zwrotu';
							|tr = 'Bilinmeyen geri dönüş kodu'"));
			EndIf;
		Else
			Result.Insert("DecryptedData", Result.ExecutionResult);
			Result.Delete("ExecutionResult");
			RunCallback(IncomingContext.CallbackOnCompletion, Result);
		EndIf;
	Else
		IncomingContext.CurrentID = IncomingContext.CurrentID + 1;
		DecryptByIteratingOverCertificates(IncomingContext, Result.ErrorInfo);
	EndIf;
		
EndProcedure

Procedure DecryptAfterReceivingSecurityToken(Result, IncomingContext) Export
	
	If Result.Completed2 Then
		DecryptByIteratingOverCertificates(IncomingContext);
	Else
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(Result.ErrorInfo);
		If IncomingContext.ErrorsDetails.Find(ErrorPresentation) = Undefined Then
			IncomingContext.ErrorsDetails.Add(ErrorPresentation);
		EndIf;		
		IncomingContext.CurrentID = IncomingContext.CurrentID + 1;
		DecryptByIteratingOverCertificates(IncomingContext);
	EndIf;
	
EndProcedure

Procedure DecryptBlockAfterDecryption(TimeConsumingOperation, IncomingContext) Export
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		If TypeOf(Result.ExecutionResult) = Type("Structure") Then
			If Result.ExecutionResult.ReturnCode = "AuthenticationRequired" Then
				Notification = New CallbackDescription("DecryptBlockAfterReceivingSecurityToken", ThisObject, IncomingContext);
				GetSecurityToken(Notification, Result.ExecutionResult.Id, IncomingContext.EncryptionParameters);
			Else
				Raise(NStr("vi = 'Dạng trả lại không xác định';
							|ru = 'Неизвестный код возврата';
							|en = 'Unknown return code'; fa = 'Unknown return code';
							|it = 'Codice restituito sconosciuto';
							|pl = 'Nieznany kod zwrotu';
							|tr = 'Bilinmeyen geri dönüş kodu'"));
			EndIf;
		Else
			Result.Insert("DecryptedData", Result.ExecutionResult);
			Result.Delete("ExecutionResult");
			RunCallback(IncomingContext.CallbackOnCompletion, Result);
		EndIf;
	Else
		RunCallback(IncomingContext.CallbackOnCompletion, Result);
	EndIf;
		
EndProcedure

Procedure DecryptBlockAfterReceivingSecurityToken(Result, IncomingContext) Export
	
	If Result.Completed2 Then
		Notification = New CallbackDescription("DecryptBlockAfterDecryption", ThisObject, IncomingContext);
		WaitForExecutionCompletionInBackground(
			Notification, 
			CryptographyServiceInternalServerCall.DecryptBlock(
				IncomingContext.EncryptedData, 
				IncomingContext.Recipient,
				IncomingContext.KeyInformation, 
				IncomingContext.EncryptionParameters));
		Return;
	Else
		RunCallback(IncomingContext.CallbackOnCompletion, Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region Sign

Procedure Sign(CallbackOnCompletion, Data, Signatory, SignatureType = "CMS", SigningParameters = Undefined) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Data", Data);
	Context.Insert("Signatory", Signatory);
	Context.Insert("SignatureType", SignatureType);
	Context.Insert("SigningParameters", SigningParameters);
	
	Notification = New CallbackDescription("SignAfterReceivingSigningResult", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.Sign(Data, Signatory, SignatureType, SigningParameters));
	
EndProcedure

Procedure SignAfterReceivingSigningResult(TimeConsumingOperation, IncomingContext) Export
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	ExecutionResult = New Structure("Completed2");
	
	If Result.Completed2 Then
		
		If TypeOf(Result.ExecutionResult) = Type("Structure") Then
			If Result.ExecutionResult.ReturnCode = "AuthenticationRequired" Then		
				Context = New Structure;
				Context.Insert("CallbackOnCompletion", IncomingContext.CallbackOnCompletion);
				Context.Insert("Data", IncomingContext.Data);
				Context.Insert("Signatory", IncomingContext.Signatory);
				Context.Insert("SignatureType", IncomingContext.SignatureType);
				Context.Insert("SigningParameters", IncomingContext.SigningParameters);
				
				Notification = New CallbackDescription("SignAfterReceivingSecurityToken", ThisObject, Context);
				GetSecurityToken(Notification, Result.ExecutionResult.Id, IncomingContext.SigningParameters);
			Else
				Raise(NStr("vi = 'Dạng trả lại không xác định';
							|ru = 'Неизвестный код возврата';
							|en = 'Unknown return code'; fa = 'Unknown return code';
							|it = 'Codice restituito sconosciuto';
							|pl = 'Nieznany kod zwrotu';
							|tr = 'Bilinmeyen geri dönüş kodu'"));
			EndIf;
			Return;
		Else
			ExecutionResult.Completed2 = True;
			ExecutionResult.Insert("Signature", Result.ExecutionResult);
		EndIf;
		RunCallback(IncomingContext.CallbackOnCompletion, ExecutionResult);
	Else
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);
		RunCallback(IncomingContext.CallbackOnCompletion, ExecutionResult);
	EndIf;
	
EndProcedure

Procedure SignAfterReceivingSecurityToken(Result, IncomingContext) Export
	
	If Result.Completed2 Then
		Sign(
			IncomingContext.CallbackOnCompletion,
			IncomingContext.Data,
			IncomingContext.Signatory,
			IncomingContext.SignatureType,
			IncomingContext.SigningParameters);
	Else
		RunCallback(IncomingContext.CallbackOnCompletion, Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region VerifySignature

Procedure VerifySignature(CallbackOnCompletion, Signature, Data = Undefined, SignatureType = "CMS", SigningParameters = Undefined) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Signature", Signature);
	Context.Insert("Data", Data);
	Context.Insert("SignatureType", SignatureType);
	Context.Insert("SigningParameters", SigningParameters);
		
	Notification = New CallbackDescription("VerifySignatureAfterReceivingResult", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.VerifySignature(Signature, Data, SignatureType, SigningParameters));
	
EndProcedure

Procedure VerifySignatureAfterReceivingResult(TimeConsumingOperation, IncomingContext) Export
	
	ExecutionResult = New Structure("Completed2");
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		
		CheckResult = Result.ExecutionResult;
		
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("SignatureIsValid", CheckResult);
		
	Else
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);		
	EndIf;
	
	RunCallback(IncomingContext.CallbackOnCompletion, ExecutionResult);
	
EndProcedure

#EndRegion

#Region CheckCertificate

Procedure CheckCertificate(CallbackOnCompletion, Certificate) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Certificate", Certificate);
	
	Notification = New CallbackDescription("VerifyCertificateAfterReceivingResult", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.CheckCertificate(Certificate));
		
EndProcedure

Procedure VerifyCertificateAfterReceivingResult(TimeConsumingOperation, IncomingContext) Export
	
	ExecutionResult = New Structure("Completed2");
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		
		CheckResult = Result.ExecutionResult;
		
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("Valid1", CheckResult);
	
	Else
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);
	EndIf;
	
	RunCallback(IncomingContext.CallbackOnCompletion, ExecutionResult);

EndProcedure

#EndRegion

#Region VerifyCertificateWithParameters

Procedure VerifyCertificateWithParameters(CallbackOnCompletion, Certificate, CheckParameters) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Certificate", Certificate);
	Context.Insert("CheckParameters", CheckParameters);
	
	Notification = New CallbackDescription("VerifyCertificateWithParametersAfterReceivingResult", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.VerifyCertificateWithParameters(Certificate, CheckParameters));
		
EndProcedure

Procedure VerifyCertificateWithParametersAfterReceivingResult(TimeConsumingOperation, IncomingContext) Export
	
	ExecutionResult = New Structure("Completed2");
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		
		CheckResult = Result.ExecutionResult;
		
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("Valid1", CheckResult);
	
	Else
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);
	EndIf;
	
	RunCallback(IncomingContext.CallbackOnCompletion, ExecutionResult);

EndProcedure

#EndRegion

#Region GetCertificateProperties

Procedure GetCertificateProperties(CallbackOnCompletion, Certificate) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Certificate", Certificate);
	
	Notification = New CallbackDescription("GetCertificatePropertiesAfterReceivingResult", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.GetCertificateProperties(Certificate));
	
EndProcedure

Procedure GetCertificatePropertiesAfterReceivingResult(TimeConsumingOperation, IncomingContext) Export
	
	ExecutionResult = New Structure("Completed2");
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		
		CertificateProperties = Result.ExecutionResult;
		
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("Certificate", CertificateProperties);
	
	Else
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);
	EndIf;
	
	RunCallback(IncomingContext.CallbackOnCompletion, ExecutionResult);
	
EndProcedure

#EndRegion

#Region GetCertificatesFromSignature

Procedure GetCertificatesFromSignature(CallbackOnCompletion, Signature) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Signature", Signature);
	
	Notification = New CallbackDescription("GetCertificatesFromSignatureAfterReceivingResult", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.GetCertificatesFromSignature(Signature));
	
EndProcedure

Procedure GetCertificatesFromSignatureAfterReceivingResult(TimeConsumingOperation, IncomingContext) Export
	
	ExecutionResult = New Structure("Completed2");
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		
		Certificates = Result.ExecutionResult;
		
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("Certificates", Certificates);
		
	Else
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);
	EndIf;
	
	RunCallback(IncomingContext.CallbackOnCompletion, ExecutionResult);
	
EndProcedure
		
#EndRegion

#Region DataHashing

Procedure DataHashing(CallbackOnCompletion, Data, HashAlgorithm, HashingParameters) Export
	
	Context = New Structure;
	Context.Insert("CallbackOnCompletion", CallbackOnCompletion);
	Context.Insert("Data", Data);
	Context.Insert("HashAlgorithm", HashAlgorithm);
	Context.Insert("HashingParameters", HashingParameters);
	
	Notification = New CallbackDescription("HashingDataAfterReceivingResult", ThisObject, Context);
	WaitForExecutionCompletionInBackground(
		Notification, 
		CryptographyServiceInternalServerCall.DataHashing(Data, HashAlgorithm, HashingParameters));
	
EndProcedure

Procedure HashingDataAfterReceivingResult(TimeConsumingOperation, IncomingContext) Export
	
	ExecutionResult = New Structure("Completed2");
	
	Result = GetBackgroundExecutionResult(TimeConsumingOperation);
	
	If Result.Completed2 Then
		
		Result = Result.ExecutionResult;
	
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("Hash", Result);
		
	Else
		ExecutionResult = PrepareNegativeResult(Result.ErrorInfo);
	EndIf;
	
	RunCallback(IncomingContext.CallbackOnCompletion, ExecutionResult);
	
EndProcedure

#EndRegion

Procedure WaitForExecutionCompletionInBackground(CallbackOnCompletion, TimeConsumingOperation) Export
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Undefined);
	IdleParameters.OutputIdleWindow = False;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);

EndProcedure

#EndRegion

#Region Private

// Parameters:
// 	Certificate - Structure - required fields:
// 	 * Id - String - ID of the certificate.
// Returns:
// 	 String - ID of the certificate.
Function Id(Val Certificate) Export
	
	Return Certificate.Id;

EndFunction

// Returns:
// 	Structure - LongDesc:
// 	* Completed2 - Boolean - signs of execution
// 	* ExecutionResult - BinaryData, String, Structure - error result or description with fields:
// 	   ** ReturnCode - String - error code
// 	   ** Id - String - ID of the certificate.
Function GetBackgroundExecutionResult(TimeConsumingOperation) Export
	
	If TimeConsumingOperation = Undefined Then
		Return PrepareNegativeResult(NStr("vi = 'Chưa hoàn tất thông thường lần gọi API dịch vụ mã hóa.';
											|ru = 'Вызов API сервиса криптографии не был завершен штатно.';
											|en = 'API cryptography service was not called correctly.'; fa = 'API cryptography service was not called correctly.';
											|it = 'La chiamata del servizio di crittografia API non è stata completata normalmente.';
											|pl = 'Wywołanie interfejsu API usług kryptograficznych nie zostało zakończone w trybie zwykłym.';
											|tr = 'Şifreleme hizmeti API sunucu çağrısı normal bir şekilde tamamlanmadı.'"));
	EndIf;
	
	If TimeConsumingOperation.Status = "Completed2" Then
		Return PreparePositiveResult(GetFromTempStorage(TimeConsumingOperation.ResultAddress));
	Else
		Return PrepareNegativeResult(TimeConsumingOperation.BriefErrorDescription);
	EndIf;
	
EndFunction

Function PreparePositiveResult(ExecutionResult)
	
	Result = New Structure;
	Result.Insert("Completed2", True);
	Result.Insert("ExecutionResult", ExecutionResult);
		
	Return Result;
	
EndFunction

// Returns:
// 	Structure - LongDesc:
// * ErrorInfo - ErrorInfo - information about the error. 
// * Completed2 - Boolean - always = A lie
Function PrepareNegativeResult(ErrorInfo)
	
	Result = New Structure;
	Result.Insert("Completed2", False);
	
	If TypeOf(ErrorInfo) = Type("String") Then
		Result.Insert("ErrorInfo", GetErrorInformationByLine(ErrorInfo));
	Else	
		Result.Insert("ErrorInfo", ErrorInfo);
	EndIf;

	Return Result;
	
EndFunction

Function GetErrorInformationByLine(ExceptionText)
	
	Try
		Raise ExceptionText;
	Except
		Return ErrorInfo();
	EndTry;
	
EndFunction

// Parameters:
// 	IncomingContext - Structure - 
// 	ErrorInfo - ErrorInfo, Undefined - information about the error.
Procedure DecryptByIteratingOverCertificates(IncomingContext, ErrorInfo = Undefined)

	If IncomingContext.CurrentID < IncomingContext.IDs.Count() Then
		Notification = New CallbackDescription("DecryptAfterDecryption", ThisObject, IncomingContext);
		WaitForExecutionCompletionInBackground(
			Notification, 
			CryptographyServiceInternalServerCall.Decrypt(
				IncomingContext.EncryptedData, 
				New Structure("Id", IncomingContext.IDs[IncomingContext.CurrentID]),
				IncomingContext.EncryptionType, 
				IncomingContext.EncryptionParameters));
		Return;
	EndIf;
	
	If ErrorInfo = Undefined Then
		ExceptionText = StrConcat(IncomingContext.ErrorsDetails, Chars.LF);
		If Not ValueIsFilled(ExceptionText) Then
			ExceptionText = NStr("vi = 'Không thể thực hiện diễn giải tin nhắn';
								|ru = 'Не удалось выполнить расшифровку сообщения';
								|en = 'Cannot decrypt a message'; fa = 'Cannot decrypt a message';
								|it = 'Impossibile decodificare il messaggio';
								|pl = 'Nie można odszyfrować wiadomości';
								|tr = 'Mesaj deşifre edilemedi'");
		EndIf;
		Try			
			Raise(ExceptionText);
		Except
			ErrorInfo = ErrorInfo();
		EndTry;
	EndIf;
	
	Result = PrepareNegativeResult(ErrorInfo);
	RecipientsField = "Recipients";
	If IncomingContext.Property(RecipientsField) Then
		Result.Insert(RecipientsField, IncomingContext[RecipientsField]);
	EndIf;
	RunCallback(IncomingContext.CallbackOnCompletion, Result);
	
EndProcedure

#EndRegion