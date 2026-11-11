///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Constructor of the SignatureProperties parameter. Intended for adding and updating signature data.
// Contains the signature's extended details.
// 
// Returns:
//   Structure:
//     * Signature             - BinaryData - Signing result.
//                           - String - Signed XMLEnvelope (if it was passed in the data).
//     * SignatureSetBy - CatalogRef.Users - a user who
//                           signed the infobase object.
//     * Comment         - String - a comment if it was entered upon signing.
//     * SignatureFileName     - String - if a signature is added from a file.
//     * SignatureDate         - Date - a signature date. It makes sense
//                           when the date cannot be extracted from signature data.
//     * SkipUponRenewal - Boolean - Indicates whether the signature is not subject to enhancement.
//                                For example, if the EDI provider ensures the validity.
//
//     Used when updating signature validation results.:
//     * SignatureValidationDate - Date - Date when the signature was last verified.
//     * SignatureCorrect        - Boolean - Last signature check result.
//     * IsVerificationRequired   - Boolean - Verification failure flag.
//     * IsSignatureMathematicallyValid - Boolean - Indicates if the signature is valid. Applies to signatures with no additional attributes.
//     * SignatureMathValidationError - String - Error if VerifySignature has
//                                                      VerifyAdditionalAttributes set to False.
//     * AdditionalAttributesCheckError - String - Error verifying the certificate and its enhanced
//                                                        signature attributes (such as the timestamp).
//     * IsAdditionalAttributesCheckedManually - Boolean - Indicates if "SignatureCorrect" was set manually.
//         If "IsSignatureMathematicallyValid" is set to "False", an exception is thrown on manual input.
//     * AdditionalAttributesManualCheckAuthor - CatalogRef.Users
//     * AdditionalAttributesManualCheckJustification - String - Reference to the organization that validated the signature.
//                                                                   For example, "EDI Operator".
//
//     Intended for updating enhanced signatures.:
//     * SignedObject   - DefinedType.SignedObject - Object the signature associated with.
//                             Ignored in methods there this object is a parameter.
//     * SequenceNumber     - Number - Signature ID that used for list sorting.
//                             Empty if the signature is not associated with an object.
//     * IsErrorOccurredDuringAutomaticRenewal - Boolean - Do no use. This is an internal parameter, which is filled by the scheduled job.
//     Intended for linking with the machine-readable letter of authority.:
//     * SignatureID - UUID
//     * ResultOfSignatureVerificationByMRLOA - Array of Structure
//                                     - Structure - MachineReadableLettersOfAuthorityFTS.ResultOfSignatureVerificationByMRLOA
//                                                   Derived signature properties
//                                     - String - the address in the temporary storage of the types listed above.
//
//     Derived signature properties:
//     * SignatureType          - EnumRef.CryptographySignatureTypes
//     * DateSignedFromLabels  - Date, Undefined - Date of the earliest timestamp.
//     * DateActionLastTimestamp - Date - Validity period of the certificate that the last timestamp was signed with.
//                                           Empty date if there's no timestamp.
//                                           Applicable if the period was determined using CryptoManager.
//     * Certificate          - ValueStorage - contains export of the certificate
//                             that was used for signing (it is in the signature).
//                           - BinaryData
//     * Thumbprint           - String - a certificate thumbprint in the Base64 string format.
//     * CertificateOwner - String - a subject presentation received from the certificate binary data.
//     * CertificateDetails - Structure - Property required for certificates that cannot be passed to the CryptoCertificate's method.
//                             Has the following properties:
//        ** SerialNumber  - String - Serial number of the certificate as in the CryptoCertificate platform object.
//        ** IssuedBy       - String - as the IssuerPresentation function returns.
//        ** IssuedTo      - String - as the SubjectPresentation function returns.
//        ** StartDate     - String - a certificate date as in the CryptoCertificate platform object in the DLF=D format.
//        ** EndDate  - String - a certificate date as in the CryptoCertificate platform object in the DLF=D format.
//        ** ValidBefore - String - (Optional) Earliest of the expiration dates of the private key and public key.
//                                     Applicable if the dates are specified in the certificate. The format is "DLF=D".
//
Function NewSignatureProperties() Export
	
	Structure = New Structure;
	Structure.Insert("Signature");
	Structure.Insert("SignatureSetBy");
	Structure.Insert("Comment");
	Structure.Insert("SignatureFileName");
	Structure.Insert("SignatureDate");
	
	Structure.Insert("SignedObject");
	Structure.Insert("SequenceNumber");
	
	Structure.Insert("SignatureValidationDate");
	Structure.Insert("SignatureCorrect");
	Structure.Insert("IsVerificationRequired", False);
	
	Structure.Insert("IsSignatureMathematicallyValid");
	Structure.Insert("SignatureMathValidationError");
	Structure.Insert("AdditionalAttributesCheckError");
	Structure.Insert("IsAdditionalAttributesCheckedManually");
	Structure.Insert("AdditionalAttributesManualCheckAuthor");
	Structure.Insert("AdditionalAttributesManualCheckJustification");
	
	Structure.Insert("Certificate");
	Structure.Insert("Thumbprint");
	Structure.Insert("CertificateOwner");
	Structure.Insert("SignatureType");
	Structure.Insert("DateSignedFromLabels");
	Structure.Insert("DateActionLastTimestamp");
	
	Structure.Insert("CertificateDetails");
	
	Structure.Insert("SkipUponRenewal");
	Structure.Insert("IsErrorOccurredDuringAutomaticRenewal", False);
	Structure.Insert("SignatureID");
	Structure.Insert("ResultOfSignatureVerificationByMRLOA");
	
	Return Structure;
	
EndFunction

// Signature verification result.
// 
// Returns:
//  Structure:
//   * Result - Boolean     - True if the check is passed.
//             - String       - Check error details.
//             - Undefined - Failed to get the cryptographic manager (when it is not specified).
//   * SignatureCorrect        - Boolean, Undefined - Last signature check result.
//   * CertificateRevoked   - Boolean - Flag indicating whether the error occurred because the certificate was revoked.
//   * IsVerificationRequired   - Boolean - Signature verification failure flag.
//   * IsSignatureMathematicallyValid - Boolean - Indicates if the signature is valid. 
//                                           The verification scope excludes certificates and enhanced signature attributes.
//   * SignatureMathValidationError - String - Error if VerifySignature has
//                                                    VerifyAdditionalAttributes set to False.
//   * AdditionalAttributesCheckError - String - Error verifying the certificate and its enhanced
//                                                      signature attributes (such as the timestamp).
//   * CertificateVerificationParameters - See DigitalSignatureClient.SignatureVerificationParameters.
//
//   * SignatureType          - EnumRef.CryptographySignatureTypes - Not filled when checking XML envelope signatures.
//   * DateActionLastTimestamp - Date - Validity period of the certificate that the last timestamp was signed with.
//    Empty date if there's no timestamp. Applicable if the period was determined using CryptoManager.
//   * UnverifiedSignatureDate - Date - Unconfirmed signature data.
//                                 - Undefined - Unconfirmed signature data is missing from the signature data
//                                                and for the XML envelope.
//   * DateSignedFromLabels  - Date - Date of the earliest timestamp.
//                         - Undefined - Timestamp is missing from the signature data during the XML envelope check.
//   * Certificate          - BinaryData - Signatory's certificate
//   * Thumbprint           - String - a certificate thumbprint in the Base64 string format.
//   * CertificateOwner - String - a subject presentation received from the certificate binary data.
//
Function SignatureVerificationResult() Export
	
	Structure = New Structure;
	Structure.Insert("Result");
	Structure.Insert("SignatureCorrect");
	Structure.Insert("CertificateRevoked", False);
	Structure.Insert("IsVerificationRequired");
	
	Structure.Insert("IsSignatureMathematicallyValid");
	Structure.Insert("SignatureMathValidationError");
	Structure.Insert("AdditionalAttributesCheckError");
	Structure.Insert("CertificateVerificationParameters", DigitalSignatureInternalClientServer.VerifyQualified());
	
	CommonClientServer.SupplementStructure(
		Structure, DigitalSignatureInternalClientServer.SignaturePropertiesUponReadAndVerify());
		
	Return Structure;
	
EndFunction

// Constructor for filling signature verification result on the form.
// 
// Returns:
//  Structure - Signature verification result.:
//   * SequenceNumber - See NewSignatureProperties.
//   * Object - See NewSignatureProperties.
//   * SignatureDate - See NewSignatureProperties.
//   * Comment - See NewSignatureProperties.
//   * SignatureAddress - String - Signature address in temporary storage.
//   * Thumbprint - See NewSignatureProperties.
//   * CertificateAddress - String - Certificate address in a temporary storage.
//   * SignatureCorrect - See NewSignatureProperties.
//   * SignatureValidationDate - See NewSignatureProperties.
//   * CertificateOwner - See NewSignatureProperties.
//   * IsVerificationRequired - See NewSignatureProperties.
//   * SignatureSetBy - See NewSignatureProperties.
//   * SignatureType - See NewSignatureProperties.
//   * DateActionLastTimestamp - See NewSignatureProperties.
//   * MachineReadableLetterOfAuthority - 
//   * MachineReadableLOAValid - Boolean
//   * ResultOfSignatureVerificationByMRLOA - See NewSignatureProperties.
//   * CheckResult - Structure - Verification result properties to be saved in the infobase.:
//     ** IsSignatureMathematicallyValid - Boolean
//     ** SignatureMathValidationError - String - Error text.
//     ** AdditionalAttributesCheckError - String - Error text.
//     ** IsAdditionalAttributesCheckedManually - Boolean - Manual verification flag.
//     ** AdditionalAttributesManualCheckAuthor - CatalogRef.Users
//     ** AdditionalAttributesManualCheckJustification - String
//   * BriefCheckResult - String - Intended for displaying the signature verification result on the form.
//
Function ResultOfSignatureValidationOnForm() Export
	
	SignatureProperties = New Structure;
	
	SignatureProperties.Insert("SequenceNumber");
	SignatureProperties.Insert("Object");
	SignatureProperties.Insert("SignatureDate");
	SignatureProperties.Insert("Comment");
	SignatureProperties.Insert("SignatureAddress");
	SignatureProperties.Insert("Thumbprint");
	SignatureProperties.Insert("CertificateAddress");
	SignatureProperties.Insert("SignatureCorrect");
	SignatureProperties.Insert("SignatureValidationDate");
	SignatureProperties.Insert("CertificateOwner");
	SignatureProperties.Insert("SignatureFileName");
	SignatureProperties.Insert("IsVerificationRequired");
	SignatureProperties.Insert("SignatureSetBy");
	SignatureProperties.Insert("SignatureType");
	SignatureProperties.Insert("DateActionLastTimestamp");
	SignatureProperties.Insert("SignatureID");
	
	// Compatibility block start.
	SignatureProperties.Insert("ErrorDescription"); 
	SignatureProperties.Insert("Status");
	// Compatibility block end.
	
	SignatureProperties.Insert("MachineReadableLetterOfAuthority");
	SignatureProperties.Insert("MachineReadableLOAValid");
	SignatureProperties.Insert("ResultOfSignatureVerificationByMRLOA");

	CheckResult = New Structure;
	CheckResult.Insert("IsSignatureMathematicallyValid");
	CheckResult.Insert("SignatureMathValidationError");
	CheckResult.Insert("AdditionalAttributesCheckError");
	CheckResult.Insert("IsAdditionalAttributesCheckedManually");
	CheckResult.Insert("AdditionalAttributesManualCheckAuthor");
	CheckResult.Insert("AdditionalAttributesManualCheckJustification");
	
	SignatureProperties.Insert("CheckResult", CheckResult);
	SignatureProperties.Insert("BriefCheckResult");
	
	Return SignatureProperties;
	
EndFunction

// Fills the check text on the form and puts the text to the "BriefCheckResult" attribute. 
//
// Parameters:
//  SignatureProperties - See ResultOfSignatureValidationOnForm
//  SessionDate - Date
//
Procedure FillSignatureStatus(SignatureProperties, SessionDate) Export
	
	If Not ValueIsFilled(SignatureProperties.SignatureAddress) Then
		Status = "";
		If ValueIsFilled(SignatureProperties.CheckResult)
			And ValueIsFilled(SignatureProperties.CheckResult.AdditionalAttributesCheckError) Then
			SignatureProperties.BriefCheckResult = 
				SignatureProperties.CheckResult.AdditionalAttributesCheckError;
		Else
			SignatureProperties.BriefCheckResult = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ожидается подписание документа с %1';
					|vi = 'Pending document to be signed with %1';
					|en = 'Pending document to be signed with %1'; fa = 'Pending document to be signed with %1';
					|it = 'Pending document to be signed with %1';
					|pl = 'Pending document to be signed with %1';
					|tr = 'Belgenin %1 tarihinden itibaren imzalanması bekleniyor'"), SignatureProperties.SignatureDate);
		EndIf;
		Return;
	EndIf;
	
	If Not ValueIsFilled(SignatureProperties.SignatureValidationDate) Then
		Status = "";
		SignatureProperties.BriefCheckResult = NStr("vi = 'Chưa tiến hành';
													|ru = 'Не проверена';
													|en = 'Not verified'; fa = 'Not verified';
													|it = 'Не проверена';
													|pl = 'Not verified';
													|tr = 'Kontrol edilmedi'");
		Return;
	EndIf;
		
	CheckResult = SignatureProperties.CheckResult;
	
	If ValueIsFilled(CheckResult) And CheckResult.IsAdditionalAttributesCheckedManually Then
		Status = NStr("vi = 'Đã kiểm tra thủ công';
						|ru = 'Проверена вручную';
						|en = 'Verified manually'; fa = 'Verified manually';
						|it = 'Проверена вручную';
						|pl = 'Verified manually';
						|tr = 'Manuel olarak kontrol edildi'");
	ElsIf SignatureProperties.SignatureCorrect
		And ValueIsFilled(SignatureProperties.DateActionLastTimestamp)
		And SignatureProperties.DateActionLastTimestamp < SessionDate Then
		Status = NStr("vi = 'Chính xác vào ngày ký';
						|ru = 'Была верна на дату подписи';
						|en = 'Was valid as of signing date'; fa = 'Was valid as of signing date';
						|it = 'Valida alla data di firma';
						|pl = 'Była zgodna na datę podpisu';
						|tr = 'İmzalama tarihinde geçerli idi'");
	ElsIf SignatureProperties.SignatureCorrect Then
		Status = NStr("vi = 'Đúng';
						|ru = 'Верна';
						|en = 'Valid'; fa = 'معتبر';
						|it = 'Верна';
						|pl = 'Valid';
						|tr = 'Geçerli'");
	ElsIf SignatureProperties.IsVerificationRequired Then
		Status = NStr("vi = 'Cần kiểm tra';
						|ru = 'Требуется проверка';
						|en = 'Verification required'; fa = 'تأیید اعتبار لازم است';
						|it = 'Требуется проверка';
						|pl = 'Verification required';
						|tr = 'Doğrulama gerekli'");
	Else
		Status = NStr("vi = 'Sai';
						|ru = 'Неверна';
						|en = 'Invalid'; fa = 'نامعتبر';
						|it = 'Неверна';
						|pl = 'Invalid';
						|tr = 'Geçersiz'");
	EndIf;
	
	If Not ValueIsFilled(CheckResult) Then
		SignatureProperties.BriefCheckResult = Status;
		Return;
	EndIf;

	If SignatureProperties.SignatureCorrect Then
		If ValueIsFilled(CheckResult.AdditionalAttributesManualCheckJustification) Then
			
			If StrLen(CheckResult.AdditionalAttributesManualCheckJustification) > 100 Then
				AdditionalAttributesManualCheckJustification =
					Left(CheckResult.AdditionalAttributesManualCheckJustification, 100) + "...";
			Else
				AdditionalAttributesManualCheckJustification = CheckResult.AdditionalAttributesManualCheckJustification;
			EndIf;
			
			SignatureProperties.BriefCheckResult = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1. %2 (%3)';
					|ru = '%1. %2 (%3)';
					|en = '%1. %2 (%3)'; fa = '%1. %2 (%3)';
					|it = '%1. %2 (%3)';
					|pl = '%1. %2 (%3)';
					|tr = '%1. %2 (%3)'"), Status,
				AdditionalAttributesManualCheckJustification, CheckResult.AdditionalAttributesManualCheckAuthor);
		Else
			
			If SignatureProperties.SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES")
				Or SignatureProperties.SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.NormalCMS")
				Or Not ValueIsFilled(SignatureProperties.SignatureType) Then
					
				If ValueIsFilled(SignatureProperties.DateActionLastTimestamp)
					And SignatureProperties.DateActionLastTimestamp < SessionDate Then
					SignatureProperties.BriefCheckResult = 
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = '%1. Chưa thay đổi chứng từ, chứng thư vẫn còn hiệu lực tới ngày ký.';
								|ru = '%1. Документ не изменен, сертификат был действителен на дату подписи.';
								|en = '%1. The document wasn''t modified, and the certificate was valid at the signing date.'; fa = '%1. The document wasn''t modified, and the certificate was valid at the signing date.';
								|it = '%1. Документ не изменен, сертификат был действителен на дату подписи.';
								|pl = '%1. The document wasn''t modified, and the certificate was valid at the signing date.';
								|tr = '1. Belgede değişiklik yapılmamıştır, sertifika imza tarihinde geçerlidir.'"), Status);
				Else
					SignatureProperties.BriefCheckResult =  
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = '%1. Chưa thay đổi chứng từ, chứng thư còn hiệu lực tới ngày ký.';
								|ru = '%1. Документ не изменен, сертификат действителен на дату проверки.';
								|en = '%1. The document wasn''t modified, and the certificate was valid at the verification date.'; fa = '%1. The document wasn''t modified, and the certificate was valid at the verification date.';
								|it = '%1. Документ не изменен, сертификат действителен на дату проверки.';
								|pl = '%1. The document wasn''t modified, and the certificate was valid at the verification date.';
								|tr = '%1. Belgede değişiklik yapılmamıştır, sertifika imza tarihinde geçerlidir.'"), Status);
				EndIf;
			Else
				SignatureProperties.BriefCheckResult = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1. Chưa thay đổi chứng từ, chứng thư còn hiệu lực đến ngày dấu thời gian.';
						|ru = '%1. Документ не изменен, сертификат действителен на дату метки времени.';
						|en = '%1. The document wasn''t modified, and the certificate was valid at the timestamp date.'; fa = '%1. The document wasn''t modified, and the certificate was valid at the timestamp date.';
						|it = '%1. Документ не изменен, сертификат действителен на дату метки времени.';
						|pl = '%1. The document wasn''t modified, and the certificate was valid at the timestamp date.';
						|tr = '%1. Belgede değişiklik yapılmamıştır, sertifika zaman damgası tarihi itibarıyla geçerlidir.'"), Status);
			EndIf;
			
		EndIf;
		Return;
	EndIf;

	If ValueIsFilled(CheckResult.SignatureMathValidationError) And ValueIsFilled(
		CheckResult.AdditionalAttributesCheckError) Then

		SignatureProperties.BriefCheckResult =  StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1. Đã thay đổi chứng từ và chưa xác minh chứng thư. %2 %3';
				|ru = '%1. Документ изменен и сертификат не прошел проверку. %2 %3';
				|en = '%1. The document was modified, and the certificate validation failed. %2 %3'; fa = '%1. The document was modified, and the certificate validation failed. %2 %3';
				|it = '%1. Документ изменен и сертификат не прошел проверку. %2 %3';
				|pl = '%1. The document was modified, and the certificate validation failed. %2 %3';
				|tr = '%1. Belge değiştirildi ve sertifika doğrulanmadı. %2 %3'"), Status,
			CheckResult.SignatureMathValidationError, CheckResult.AdditionalAttributesCheckError);
	ElsIf ValueIsFilled(CheckResult.SignatureMathValidationError) Then

		SignatureProperties.BriefCheckResult =  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1. Đã thay đổi chứng từ. %2';
						|ru = '%1. Документ изменен. %2';
						|en = '%1. The document was modified. %2'; fa = '%1. The document was modified. %2';
						|it = '%1. Документ изменен. %2';
						|pl = '%1. The document was modified. %2';
						|tr = '%1. Belge değiştirildi. %2'"), Status, CheckResult.SignatureMathValidationError);
	ElsIf ValueIsFilled(CheckResult.AdditionalAttributesCheckError) Then
			
		If CheckResult.IsSignatureMathematicallyValid = False Then
			SignatureProperties.BriefCheckResult =  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1. %2';
						|ru = '%1. %2';
						|en = '%1. %2'; fa = '%1. %2';
						|it = '%1. %2';
						|pl = '%1. %2';
						|tr = '%1. %2'"), Status, CheckResult.AdditionalAttributesCheckError);
		ElsIf SignatureProperties.SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.NormalCMS")
			Or SignatureProperties.SignatureType = PredefinedValue(
			"Enum.CryptographySignatureTypes.BasicCAdESBES") Then

			SignatureProperties.BriefCheckResult =  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1. Chưa thay đổi chứng từ, nhưng chưa xác minh chứng thư. %2';
						|ru = '%1. Документ не изменен, но сертификат не прошел проверку. %2';
						|en = '%1. The document was not modified, but the certificate validation failed. %2'; fa = '%1. The document was not modified, but the certificate validation failed. %2';
						|it = '%1. Документ не изменен, но сертификат не прошел проверку. %2';
						|pl = '%1. The document was not modified, but the certificate validation failed. %2';
						|tr = '%1. Belgede değişiklik yapılmamıştır, ancak sertifika doğrulanmadı. %2'"), Status, 
				CheckResult.AdditionalAttributesCheckError);
		Else
			SignatureProperties.BriefCheckResult =  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1. Chưa thay đổi chứng từ, nhưng chưa xác minh một trong số các chứng thư hoặc thuộc tính bổ sung. %2';
						|ru = '%1. Документ не изменен, но один из сертификатов или дополнительные атрибуты подписи не прошли проверку. %2';
						|en = '%1. The document was not modified, but one of the certificates or additional attributes failed validation. %2'; fa = '%1. The document was not modified, but one of the certificates or additional attributes failed validation. %2';
						|it = '%1. The document was not modified, but one of the certificates or additional attributes failed validation. %2';
						|pl = '%1. The document was not modified, but one of the certificates or additional attributes failed validation. %2';
						|tr = '%1. Belge değiştirilmedi, ancak sertifikalardan biri veya ek imza öznitelikleri doğrulanamadı. %2'"), Status,
				CheckResult.AdditionalAttributesCheckError);
		EndIf;
	Else
		SignatureProperties.BriefCheckResult =  StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1.';
				|ru = '%1.';
				|en = '%1.'; fa = '%1.';
				|it = '%1.';
				|pl = '%1.';
				|tr = '%1.'"), Status);
	EndIf;
	
EndProcedure

// Generates a signature file name from a template.
//
// Parameters:
//  BaseName			 - String - Original file name without the extension. For example, "SignedObject.Description".
//  CertificateOwner			 - String - Certificate owner (full name, job title, etc.).
//  SignatureFilesExtension	 - String - Extension for signature files to be added to the filename.
//  SeparatorRequired		 - Boolean - Flag indicating if the filename includes a delimiter.
// 
// Returns:
//  String
//
Function SignatureFileName(BaseName, CertificateOwner, SignatureFilesExtension, SeparatorRequired = True) Export
	
	Return DigitalSignatureInternalClientServer.SignatureFileName(BaseName,
		CertificateOwner, SignatureFilesExtension, SeparatorRequired);
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// See DigitalSignatureClient.CertificatePresentation.
// See DigitalSignature.CertificatePresentation.
//
Function CertificatePresentation(Certificate, MiddleName = False, ValidityPeriod = True) Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	If ValidityPeriod Then
		Return DigitalSignature.CertificatePresentation(Certificate);
	Else	
		Return DigitalSignature.SubjectPresentation(Certificate);
	EndIf;	
#Else
	If ValidityPeriod Then
		Return DigitalSignatureClient.CertificatePresentation(Certificate);
	Else
		Return DigitalSignatureClient.SubjectPresentation(Certificate);
	EndIf;
#EndIf
	
EndFunction

// Deprecated.
// See DigitalSignatureClient.SubjectPresentation.
// See DigitalSignature.SubjectPresentation.
//
Function SubjectPresentation(Certificate, MiddleName = True) Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return DigitalSignature.SubjectPresentation(Certificate);
#Else
	Return DigitalSignatureClient.SubjectPresentation(Certificate);
#EndIf
	
EndFunction

// Deprecated.
// See DigitalSignatureClient.IssuerPresentation.
// See DigitalSignature.IssuerPresentation.
//
Function IssuerPresentation(Certificate) Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return DigitalSignature.IssuerPresentation(Certificate);
#Else
	Return DigitalSignatureClient.IssuerPresentation(Certificate);
#EndIf
	
EndFunction

// Deprecated.
// See DigitalSignatureClient.CertificateProperties.
// See DigitalSignature.CertificateProperties.
//
Function FillCertificateStructure(Certificate) Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return DigitalSignature.CertificateProperties(Certificate);
#Else
	Return DigitalSignatureClient.CertificateProperties(Certificate);
#EndIf
	
EndFunction

// Deprecated.
// See DigitalSignatureClient.CertificateSubjectProperties.
// See DigitalSignature.CertificateSubjectProperties.
//
Function CertificateSubjectProperties(Certificate) Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return DigitalSignature.CertificateSubjectProperties(Certificate);
#Else
	Return DigitalSignatureClient.CertificateSubjectProperties(Certificate);
#EndIf
	
EndFunction

// Deprecated.
// See DigitalSignatureClient.CertificateIssuerProperties.
// See DigitalSignature.CertificateIssuerProperties.
//
Function CertificateIssuerProperties(Certificate) Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return DigitalSignature.CertificateIssuerProperties(Certificate);
#Else
	Return DigitalSignatureClient.CertificateIssuerProperties(Certificate);
#EndIf
	
EndFunction

// Deprecated.
// See DigitalSignatureClient.XMLDSigParameters.
// See DigitalSignature.XMLDSigParameters.
//
Function XMLDSigParameters() Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Return DigitalSignature.XMLDSigParameters();
#Else
	Return DigitalSignatureClient.XMLDSigParameters();
#EndIf
	
EndFunction

#EndRegion

#EndRegion