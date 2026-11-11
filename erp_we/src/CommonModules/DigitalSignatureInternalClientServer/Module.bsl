///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Generates a signature file name from a template.
//
Function SignatureFileName(BaseName, CertificateOwner, SignatureFilesExtension, SeparatorRequired = True) Export
	
	Separator = ?(SeparatorRequired, " - ", " ");
	
	SignatureFileNameWithoutExtension = StringFunctionsClientServer.SubstituteParametersToString("%1%2%3",
		BaseName, Separator, CertificateOwner);
	
	If StrLen(SignatureFileNameWithoutExtension) > 120 Then
		SignatureFileNameWithoutExtension = DigitalSignatureInternalServerCall.AbbreviatedFileName(
			CommonClientServer.ReplaceProhibitedCharsInFileName(SignatureFileNameWithoutExtension), 120);
	EndIf;
	
	SignatureFileName = StringFunctionsClientServer.SubstituteParametersToString("%1.%2",
		SignatureFileNameWithoutExtension, SignatureFilesExtension);
	
	Return CommonClientServer.ReplaceProhibitedCharsInFileName(SignatureFileName);

EndFunction

// Generates a certificate file name from a template.
//
Function CertificateFileName(BaseName, CertificateOwner, CertificateFilesExtension, SeparatorRequired = True) Export
	
	If Not ValueIsFilled(CertificateOwner) Then
		CertificateFileNameWithoutExtension = BaseName;
	Else
		Separator = ?(SeparatorRequired, " - ", " ");
		CertificateFileNameWithoutExtension = StringFunctionsClientServer.SubstituteParametersToString("%1%2%3",
			BaseName, Separator, CertificateOwner);
	EndIf;
	
	If StrLen(CertificateFileNameWithoutExtension) > 120 Then
		CertificateFileNameWithoutExtension = DigitalSignatureInternalServerCall.AbbreviatedFileName(
			CommonClientServer.ReplaceProhibitedCharsInFileName(CertificateFileNameWithoutExtension), 120);
	EndIf;
	
	CertificateFileName = StringFunctionsClientServer.SubstituteParametersToString("%1.%2",
		CertificateFileNameWithoutExtension, CertificateFilesExtension);
	
	Return CommonClientServer.ReplaceProhibitedCharsInFileName(CertificateFileName);
	
EndFunction

// Constructor of the result of the CA list check.
// 
// Returns:
//  Structure - Constructor of the result of the default CA check.:
//   * Valid - Boolean - Flag indicating whether the CA is valid on the date or the check was not performed 
//                 (the certificate is unqualified or CA is missing from the list of qualified CAs)
//   * FoundintheListofCAs - Boolean - Qualified certificate flag
//   * IsState - Boolean - Flag indicating whether the CA is trusted and some checks must be skipped.
//                                For example, in Russia, they include: Treasury of the Russian Federation, Bank of Russia,
//   Federal Tax Service Certification Authority.
//   * ThisIsQualifiedCertificate - Boolean - Flag indicating whether the certificate was issued during a CA accreditation period.
//   * Warning - See WarningWhileVerifyingCertificateAuthorityCertificate
//
Function DefaultCAVerificationResult() Export
	
	Result = New Structure;
	Result.Insert("Valid", True);
	Result.Insert("FoundintheListofCAs", False);
	Result.Insert("IsState", False);
	Result.Insert("ThisIsQualifiedCertificate", False);
	Result.Insert("Warning", WarningWhileVerifyingCertificateAuthorityCertificate());
	
	Return Result;
	
EndFunction

// Returns:
//   Structure - Error or warning on the certificate.:
//   * ErrorText - String
//   * PossibleReissue - Boolean - Flag indicating whether users can apply for a new certificate from the application.
//   * Cause - String - Error reason for display in the extended error form.
//   * Decision - String - Solution for display in the extended error form.
//   * AllowSigning - Boolean - It can be allowed in the user settings.
//
Function WarningWhileVerifyingCertificateAuthorityCertificate() Export
	
	Warning = New Structure;
	Warning.Insert("ErrorText", "");
	Warning.Insert("PossibleReissue", False);
	Warning.Insert("Cause", "");
	Warning.Insert("Decision", "");
	Warning.Insert("AllowSigning", True);
	Warning.Insert("AdditionalInfo", "");
	
	Return Warning;
	
EndFunction

// Returns:
//   Structure:
//   * ErrorText - String
//
Function ErrorTextFailedToDefineApp(Error) Export
	
	If ValueIsFilled(Error) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tự động xác định ứng dụng chữ ký điện tử và mã hóa:
			|%1';
			|ru = 'Не удалось автоматически определить приложение электронной подписи и шифрования:
			|%1';
			|en = 'Couldn''t auto-determine digital signing and encryption app:
			|%1'; fa = 'Couldn''t auto-determine digital signing and encryption app:
			|%1';
			|it = 'Не удалось автоматически определить приложение электронной подписи и шифрования:
			|%1';
			|pl = 'Couldn''t auto-determine digital signing and encryption app:
			|%1';
			|tr = 'Elektronik imza ve şifreleme uygulaması otomatik olarak belirlenememiştir: 
			| %1'"), Error);
	Else
		ErrorText = NStr("vi = 'Không thể tự động xác định ứng dụng chữ ký điện tử và mã hóa.';
						|ru = 'Не удалось автоматически определить приложение электронной подписи и шифрования.';
						|en = 'Couldn''t auto-determine digital signing and encryption app.'; fa = 'Couldn''t auto-determine digital signing and encryption app.';
						|it = 'Не удалось автоматически определить приложение электронной подписи и шифрования.';
						|pl = 'Couldn''t auto-determine digital signing and encryption app.';
						|tr = 'Elektronik imza ve şifreleme uygulaması otomatik olarak belirlenememiştir.'");
	EndIf;
	
	Return ErrorText;
	
EndFunction

Procedure FillCertificateUnqualifiedVerificationResult(CheckParameters, Result) Export
	If CheckParameters.VerifyCertificate = QualifiedOnly() Then
		ErrorText = NStr("vi = 'Chứng thư không đủ tiêu chuẩn, chữ ký bằng chứng thư này không có giá trị pháp lý.';
						|ru = 'Сертификат неквалифицированный, подпись таким сертификатом не является юридически значимой.';
						|en = 'The certificate is non-qualified. A signature made with such a certificate is not legally binding.'; fa = 'The certificate is non-qualified. A signature made with such a certificate is not legally binding.';
						|it = 'Сертификат неквалифицированный, подпись таким сертификатом не является юридически значимой.';
						|pl = 'The certificate is non-qualified. A signature made with such a certificate is not legally binding.';
						|tr = 'Sertifika niteliksizdir; böyle bir sertifikaya sahip bir imzanın hukuken önemi yoktur.'");
		Result.Valid = False;
		Result.Warning.ErrorText = ErrorText;
		Result.Warning.AllowSigning = False;
	EndIf;
EndProcedure

// Returns:
//   String
//   Array of See NewExtendedApplicationDetails
//
Function CryptoProvidersSearchResult(CryptoProvidersResult, ServerName = "") Export
	
	If ServerName = "" Then

		If CryptoProvidersResult = Undefined Then
			ErrorText = NStr(
				"vi = 'Trên máy tính, Không thể tự động xác định ứng dụng chữ ký điện tử và mã hóa đã được cài đặt.';
				|ru = 'На компьютере не удалось автоматически определить установленные приложения электронной подписи и шифрования.';
				|en = 'Couldn''t find digital signing and encryption apps on your computer.'; fa = 'Couldn''t find digital signing and encryption apps on your computer.';
				|it = 'На компьютере не удалось автоматически определить установленные приложения электронной подписи и шифрования.';
				|pl = 'Couldn''t find digital signing and encryption apps on your computer.';
				|tr = 'Bilgisayar yüklü elektronik imza ve şifreleme uygulamalarını otomatik olarak algılayamadı.'");
		ElsIf CryptoProvidersResult.CheckCompleted Then
			If CryptoProvidersResult.Cryptoproviders.Count() > 0 Then
				Return CryptoProvidersResult.Cryptoproviders;
			Else
				ErrorText = NStr("vi = 'Trên máy tính không cài đặt ứng dụng chữ ký điện tử và mã hóa.';
								|ru = 'На компьютере не установлены приложения электронной подписи и шифрования.';
								|en = 'No digital signing and encryption apps are installed on your computer.'; fa = 'No digital signing and encryption apps are installed on your computer.';
								|it = 'На компьютере не установлены приложения электронной подписи и шифрования.';
								|pl = 'No digital signing and encryption apps are installed on your computer.';
								|tr = 'Elektronik imza ve şifreleme uygulamaları bilgisayarda yüklü değildir.'");
			EndIf;
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trên máy tính, Không thể tự động xác định ứng dụng chữ ký điện tử và mã hóa đã được cài đặt:
				 |%1';
				 |ru = 'На компьютере не удалось автоматически определить установленные приложения электронной подписи и шифрования:
				 |%1';
				 |en = 'Couldn''t find digital signing and encryption apps on your computer:
				 |%1'; fa = 'Couldn''t find digital signing and encryption apps on your computer:
				 |%1';
				 |it = 'На компьютере не удалось автоматически определить установленные приложения электронной подписи и шифрования:
				 |%1';
				 |pl = 'Couldn''t find digital signing and encryption apps on your computer:
				 |%1';
				 |tr = 'Bilgisayar yüklü elektronik imza ve şifreleme uygulamalarını otomatik olarak algılayamadı:
				 |%1'"), CryptoProvidersResult.Error);
		EndIf;

	Else
		
		If CryptoProvidersResult = Undefined Then

			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr(
				"vi = 'Trên server %1, không thể tự động xác định ứng dụng chữ ký điện tử và mã hóa đã được cài đặt.';
				|ru = 'На сервере %1 не удалось автоматически определить установленные приложения электронной подписи и шифрования.';
				|en = 'Couldn''t find digital signing and encryption apps installed on the server %1.'; fa = 'Couldn''t find digital signing and encryption apps installed on the server %1.';
				|it = 'На сервере %1 не удалось автоматически определить установленные приложения электронной подписи и шифрования.';
				|pl = 'Couldn''t find digital signing and encryption apps installed on the server %1.';
				|tr = '%1 Sunucuya yüklü elektronik imza ve şifreleme uygulamalarını otomatik olarak algılayamadı.'"),
				ServerName);
		ElsIf CryptoProvidersResult.CheckCompleted Then
			If CryptoProvidersResult.Cryptoproviders.Count() > 0 Then
				Return CryptoProvidersResult.Cryptoproviders;
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trên server %1, không cài đặt ứng dụng chữ ký điện tử và mã hóa.';
					|ru = 'На сервере %1 не установлены приложения электронной подписи и шифрования.';
					|en = 'No digital signing and encryption apps are installed on the server %1.'; fa = 'No digital signing and encryption apps are installed on the server %1.';
					|it = 'На сервере %1 не установлены приложения электронной подписи и шифрования.';
					|pl = 'No digital signing and encryption apps are installed on the server %1.';
					|tr = '%1 sunucusunda elektronik imza ve şifreleme uygulamaları yüklü değil.'"), ServerName);
			EndIf;
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trên server %1, không thể tự động xác định ứng dụng chữ ký điện tử và mã hóa đã được cài đặt:
				 |%2';
				 |ru = 'На сервере %1 не удалось автоматически определить установленные приложения электронной подписи и шифрования:
				 |%2';
				 |en = 'Couldn''t find digital signing and encryption apps installed on the server %1:
				 |%2'; fa = 'Couldn''t find digital signing and encryption apps installed on the server %1:
				 |%2';
				 |it = 'На сервере %1 не удалось автоматически определить установленные приложения электронной подписи и шифрования:
				 |%2';
				 |pl = 'Couldn''t find digital signing and encryption apps installed on the server %1:
				 |%2';
				 |tr = '%1 Sunucuya yüklü elektronik imza ve şifreleme uygulamalarını otomatik olarak algılayamadı: 
				 |%2'"), ServerName, CryptoProvidersResult.Error);
		EndIf;
		
	EndIf;

	Return ErrorText;
	
EndFunction

// Address of the revocation list located on a different resource.
// 
// Parameters:
//  CertificateAuthorityName - String - Issuer's name (Latin letters)
//  Certificate  - BinaryData
//              - String
// 
// Returns:
//  Structure:
//   * InternalAddress - String - ID for searching within the infobase
//   * ExternalAddress - String - Resource address (for downloading)
//
Function RevocationListInternalAddress(CertificateAuthorityName, Certificate, CARevocationListDirectories) Export
	
	Return DigitalSignatureClientServerLocalization.RevocationListInternalAddress(CertificateAuthorityName, Certificate, CARevocationListDirectories);
	
EndFunction

// Determines the type of cryptographic data.
// 
// Parameters:
//  Data - BinaryData
//         - String - Data address
// 
// Returns:
//  Undefined, String - Signature, EncryptedData, or Certificate
//
Function DefineDataType(Data) Export
	
	BinaryData = BinaryDataFromTheData(Data,
		"DigitalSignatureInternalClientServer.DefineDataType");
	
	DataAnalysis = NewDataAnalysis(BinaryData);
	// SEQUENCE (PKCS #7 ContentInfo).
	SkipBlockStart(DataAnalysis, 0, 16);
	
	If DataAnalysis.HasError Then
		Return Undefined;
	EndIf;

	// OBJECT IDENTIFIER (contentType).
	SkipBlockStart(DataAnalysis, 0, 6);
	
	If Not DataAnalysis.HasError Then
		DataSize = DataAnalysis.Parents[0].DataSize;
		If DataSize = 9 Then
			Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
			BufferString = GetHexStringFromBinaryDataBuffer(Buffer);
			If BufferString = "2A864886F70D010702" Then // 1.2.840.113549.1.7.2 signedData (PKCS #7).
				Return "Signature";
			ElsIf BufferString = "2A864886F70D010703" Then // 1.2.840.113549.1.7.3 envelopedData (PKCS #7)
				Return "EncryptedData";
			EndIf;
		Else
			Return Undefined;
		EndIf;
	Else
		DataAnalysis = NewDataAnalysis(BinaryData);
		// SEQUENCE (PKCS #7 ContentInfo).
		SkipBlockStart(DataAnalysis, 0, 16);
			// SEQUENCE (tbsCertificate).
			SkipBlockStart(DataAnalysis, 0, 16);
		If DataAnalysis.HasError Then
			Return Undefined;
		EndIf;
		Return "Certificate";
	EndIf;
		
	Return Undefined;
	
EndFunction

// Certificates up to the root one.
// 
// Parameters:
//  Certificates - Array of CryptoCertificate
// 
// Returns:
//  Array of CryptoCertificate - Certificates up to the root one.
//
Function CertificatesInOrderToRoot(Certificates) Export
	
	By_Order = New Array;
	CertificatesBySubjects = New Map;
	CertificatesDetails = New Map;
	
	For Each Certificate In Certificates Do
		CertificatesDetails.Insert(Certificate, Certificate);
		By_Order.Add(Certificate);
		CertificatesBySubjects.Insert(IssuerKey(Certificate.Subject), Certificate);
	EndDo;
	
	For Counter = 1 To By_Order.Count() Do
		HasChanges = False;
		SortCertificates(
			By_Order, CertificatesDetails, CertificatesBySubjects, HasChanges); 
		If Not HasChanges Then
			Break;
		EndIf;
	EndDo;

	Return By_Order;
	
EndFunction

Function AppsRelevantAlgorithms() Export
	
	Return DigitalSignatureClientServerLocalization.AppsRelevantAlgorithms();
	
EndFunction

// Add-in connection details (ExtraCryptoAPI).
//
// Returns:
//  Structure:
//   * FullTemplateName - String
//   * ObjectName      - String
//
Function ComponentDetails() Export
	
	Parameters = New Structure;
	Parameters.Insert("ObjectName", "ExtraCryptoAPI");
	Parameters.Insert("FullTemplateName",
		"Catalog.DigitalSignatureAndEncryptionKeysCertificates.Template.ComponentExtraCryptoAPI");
	Return Parameters;
	
EndFunction

// Message: Access to web services is restricted.
// 
// Returns:
//  String
//
Function AccessToInternetServicesDeniedMessageText() Export
	Return NStr("vi = 'Người quản trị đã cấm truy cập vào dịch vụ Internet của chữ ký điện tử (""Tùy chỉnh chung"" - ""Chữ ký điện tử"" - ""Cho phép truy cập vào dịch vụ Internet"").';
				|ru = 'Доступ к Интернет-сервисам электронной подписи из приложения запрещен администратором (""Общие настройки"" - ""Электронная подпись"" - ""Разрешить доступ к Интернет-сервисам"").';
				|en = 'Access to digital signing web services is forbidden by the administrator (General settings > Digital signature > Allow access to web services).'; fa = 'Access to digital signing web services is forbidden by the administrator (General settings > Digital signature > Allow access to web services).';
				|it = 'Access to digital signing web services is forbidden by the administrator (General settings > Digital signature > Allow access to web services).';
				|pl = 'Access to digital signing web services is forbidden by the administrator (General settings > Digital signature > Allow access to web services).';
				|tr = 'Uygulamadan dijital imzanın internet hizmetlerine erişim izni, yönetici tarafından yasaklandı (""Genel ayarlar"" - ""Dijital imza"" - ""İnternet hizmetlerine erişime izin ver"").'");
EndFunction

// A signature property constructor during signing.
// 
// Parameters:
//  SignatureBinaryData - BinaryData, String - String if an XML envelop is passed
//  CertificateProperties - See DigitalSignatureClient.CertificateProperties
//  Comment - String
//  AuthorizedUser - CatalogRef.Users
//  SignatureFileName - String - Signature file name.
//  SignatureParameters - See ParametersCryptoSignatures
//  
// Returns:
//  Structure:
//   * Signature - BinaryData
//   * SignatureSetBy - CatalogRef.Users
//   * Comment - String
//   * SignatureFileName - String 
//   * SignatureDate - Date - Unconfirmed signature date
//   * SignatureValidationDate - Date
//   * SignatureCorrect - Boolean
//   * Certificate - BinaryData
//   * Thumbprint - String
//   * CertificateOwner - String
//   * SignatureType - EnumRef.CryptographySignatureTypes
//   * DateActionLastTimestamp - Date
//   * DateSignedFromLabels - Date 
//   * UnverifiedSignatureDate - Date
//
Function SignatureProperties(SignatureBinaryData, CertificateProperties, Comment,
			AuthorizedUser, SignatureFileName = "", SignatureParameters = Undefined, IsVerificationRequired = False) Export
	
	SignatureProperties = New Structure;
	SignatureProperties.Insert("Signature",             SignatureBinaryData);
	SignatureProperties.Insert("SignatureSetBy", AuthorizedUser);
	SignatureProperties.Insert("Comment",         Comment);
	SignatureProperties.Insert("SignatureFileName",     SignatureFileName);
	SignatureProperties.Insert("SignatureDate",         Date('00010101')); // Set before write.
	SignatureProperties.Insert("SignatureValidationDate", Date('00010101')); // Date when the signature was last verified.
	SignatureProperties.Insert("SignatureCorrect",        False);             // Most recent validation result.
	// Derived properties:
	SignatureProperties.Insert("Certificate",          CertificateProperties.BinaryData);
	SignatureProperties.Insert("Thumbprint",           CertificateProperties.Thumbprint);
	SignatureProperties.Insert("CertificateOwner", CertificateProperties.IssuedTo);
	
	SignatureProperties.Insert("SignatureType");
	SignatureProperties.Insert("DateActionLastTimestamp");
	SignatureProperties.Insert("DateSignedFromLabels");
	SignatureProperties.Insert("UnverifiedSignatureDate");
	SignatureProperties.Insert("IsVerificationRequired", IsVerificationRequired);
	SignatureProperties.Insert("SignatureID");
	
	If SignatureParameters <> Undefined Then
		SignatureProperties.Insert("SignatureType", SignatureParameters.SignatureType);
		SignatureProperties.Insert("DateActionLastTimestamp", SignatureParameters.DateActionLastTimestamp);
		SignatureProperties.Insert("DateSignedFromLabels", SignatureParameters.DateSignedFromLabels);
		SignatureProperties.Insert("UnverifiedSignatureDate", SignatureParameters.UnverifiedSignatureDate);
	EndIf;
	
	Return SignatureProperties;
	
EndFunction

// See DigitalSignatureClient.NewSignatureType
// 
// Returns:
//  String
//
Function VerifyQualified() Export
	Return "VerifyQualified";
EndFunction

// See DigitalSignatureClient.NewSignatureType
// 
// Returns:
//  String
//
Function QualifiedOnly() Export
	Return "QualifiedOnly";
EndFunction

// See DigitalSignatureClient.NewSignatureType
// 
// Returns:
//  String
//
Function NotVerifyCertificate() Export
	Return "NotVerifyCertificate";
EndFunction

#EndRegion

#Region Private


Function TokenLibraryLoadingError(ErrorText) Export
	
	Result = False;
	DigitalSignatureClientServerLocalization.OnDefineImportErrorInTokenLibraries(ErrorText, Result);
	Return Result;
	
EndFunction

Function ActionInstallLibrariesForTokens() Export
	Return "InstallLibrariesForTokens";
EndFunction

Function ThisIsCertificateReplacement(PropertiesOfNew, PropertiesOfOld) Export
	
	Result = Undefined;
	DigitalSignatureClientServerLocalization.WhenComparingCertificates(PropertiesOfNew, PropertiesOfOld, Result);
	
	If Result = Undefined Then
		If PropertiesOfNew.CommonName = PropertiesOfOld.CommonName
			And PropertiesOfNew.Organization = PropertiesOfOld.Organization
			And PropertiesOfNew.LastName = PropertiesOfOld.LastName
			And PropertiesOfNew.Name = PropertiesOfOld.Name
			Then
			Return True;
		EndIf;
	Else
		Return Result;
	EndIf;
	
	Return False;
	
EndFunction

// Constructor for reading signature properties.
// 
// Returns:
//   See DigitalSignature.SignatureProperties
//
Function ResultOfReadSignatureProperties() Export
	
	Structure = New Structure;
	Structure.Insert("Success", Undefined);
	Structure.Insert("ErrorText", "");
	
	CommonClientServer.SupplementStructure(
		Structure, SignaturePropertiesUponReadAndVerify());
	Structure.Insert("Certificates", New Array);
		
	Return Structure;
	
EndFunction

Function SignaturePropertiesUponReadAndVerify() Export
	
	Structure = New Structure;
	Structure.Insert("SignatureType");
	Structure.Insert("DateActionLastTimestamp");
	Structure.Insert("DateSignedFromLabels");
	Structure.Insert("UnverifiedSignatureDate");
	
	Structure.Insert("Certificate");
	Structure.Insert("Thumbprint");
	Structure.Insert("CertificateOwner");
		
	Return Structure;
	
EndFunction

Procedure SortCertificates(By_Order, CertificatesDetails, CertificatesBySubjects, HasChanges) Export
	
	For Each CertificateDetails In CertificatesDetails Do
		
		CertificateProperties = CertificateDetails.Key;
		Certificate = CertificateDetails.Value;
	
		IssuerKey = IssuerKey(CertificateProperties.Issuer);
		IssuerCertificate = CertificatesBySubjects.Get(IssuerKey);
		
		Position = By_Order.Find(Certificate);
		

		If CertificateProperties.Issuer.CN = CertificateProperties.Subject.CN
			And IssuerKey = IssuerKey(CertificateProperties.Subject)
			Or IssuerCertificate = Undefined Then

			If Position <> By_Order.UBound() Then
				By_Order.Delete(Position);
				By_Order.Add(Certificate);
				HasChanges = True;
			EndIf;
			Continue;
		EndIf;

		IssuerPosition = By_Order.Find(IssuerCertificate);
		If Position + 1 = IssuerPosition Then
			Continue;
		EndIf;
		
		By_Order.Delete(Position);
		HasChanges = True;
		IssuerPosition = By_Order.Find(IssuerCertificate);
		By_Order.Insert(IssuerPosition, Certificate);
		
	EndDo;
	
EndProcedure 

Function IssuerKey(IssuerOrSubject) Export
	Array = New Array;
	For Each KeyAndValue In IssuerOrSubject Do
		Array.Add(KeyAndValue.Key);
		Array.Add(KeyAndValue.Value);
	EndDo;
	Return IssuerOrSubject.CN + StrConcat(Array);
EndFunction

Function UsersCertificateString(User1, User2, UsersCount) Export
	
	UserRow = StrTemplate("%1, %2", User1, User2);
	If UsersCount > 2 Then
		UserRow = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 và khác (tổng số %2)';
				|ru = '%1 и другие (всего %2)';
				|en = '%1 and other (total %2)'; fa = '%1 and other (total %2)';
				|it = '%1 e altri (totale %2)';
				|pl = '%1 i inne (łącznie %2)';
				|tr = '%1 ve diğerleri (toplam %2)'"), UserRow, Format(UsersCount, "NG=0"));
	EndIf;

	Return UserRow;
	
EndFunction

Function ApplicationDetailsByCryptoProviderName(CryptoProviderName, ApplicationsDetailsCollection, AppsAuto) Export
	
	ApplicationFound = False;
	
	If ValueIsFilled(AppsAuto) Then
		For Each ApplicationDetails In AppsAuto Do
			If ApplicationDetails.ApplicationName = CryptoProviderName Then
				ApplicationFound = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If Not ApplicationFound Then
		For Each ApplicationDetails In ApplicationsDetailsCollection Do
			If ApplicationDetails.ApplicationName = CryptoProviderName Then
				ApplicationFound = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If ApplicationFound Then
		Return ApplicationDetails;
	EndIf;
	
	ApplicationDetails = Undefined;
	
	If CryptoProviderName = "Crypto-Pro GOST R 34.10-2001 KC1 CSP"
	 Or CryptoProviderName = "Crypto-Pro GOST R 34.10-2001 KC2 CSP" Then
		
		ApplicationDetails = ApplicationDetailsByCryptoProviderName(
			"Crypto-Pro GOST R 34.10-2001 Cryptographic Service Provider", ApplicationsDetailsCollection, AppsAuto);
		
	ElsIf CryptoProviderName = "Crypto-Pro GOST R 34.10-2012 KC1 CSP"
	      Or CryptoProviderName = "Crypto-Pro GOST R 34.10-2012 KC2 CSP" Then
		
		ApplicationDetails = ApplicationDetailsByCryptoProviderName(
			"Crypto-Pro GOST R 34.10-2012 Cryptographic Service Provider", ApplicationsDetailsCollection, AppsAuto);
		
	ElsIf CryptoProviderName = "Crypto-Pro GOST R 34.10-2012 KC1 Strong CSP"
	      Or CryptoProviderName = "Crypto-Pro GOST R 34.10-2012 KC2 Strong CSP" Then
		
		ApplicationDetails = ApplicationDetailsByCryptoProviderName(
			"Crypto-Pro GOST R 34.10-2012 Strong Cryptographic Service Provider", ApplicationsDetailsCollection, AppsAuto);
	EndIf;
	
	Return ApplicationDetails;
	
EndFunction

Function CertificatePropertiesFromAddInResponse(AddInResponse) Export
	
	CertificateProperties = New Structure;
	CertificateProperties.Insert("AddressesOfRevocationLists", New Array);
	
	Try
		CertificatePropertiesResult = ReadAddInResponce(
			AddInResponse);
			
		AddressesOfRevocationLists = CertificatePropertiesResult.Get("crls");
		If ValueIsFilled(AddressesOfRevocationLists) Then
			CertificateProperties.AddressesOfRevocationLists = AddressesOfRevocationLists;
		EndIf;

		CertificateProperties.Insert("Issuer", CertificatePropertiesResult.Get("issuer_name"));
		CertificateProperties.Insert("PublicKeyAlgorithm", CertificatePropertiesResult.Get(
			"public_key_algorithm"));
		CertificateProperties.Insert("SignAlgorithm", CertificatePropertiesResult.Get("signature_algorithm"));
		CertificateProperties.Insert("SerialNumber", CertificatePropertiesResult.Get("serial_number"));
		CertificateProperties.Insert("NameOfContainer", CertificatePropertiesResult.Get("container_name"));
		CertificateProperties.Insert("ApplicationDetails", CertificatePropertiesResult.Get("provider"));
		CertificateProperties.Insert("Certificate", CertificatePropertiesResult.Get("value"));
		CertificateProperties.Insert("PublicKey", CertificatePropertiesResult.Get("public_key"));

		Return CertificateProperties;

	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận thuộc tính mở rộng của chứng thư: %1';
				|ru = 'Невозможно получить расширенные свойства сертификата: %1';
				|en = 'Unable to retrieve extended certificate properties: %1'; fa = 'Unable to retrieve extended certificate properties: %1';
				|it = 'Unable to retrieve extended certificate properties: %1';
				|pl = 'Unable to retrieve extended certificate properties: %1';
				|tr = 'Detaylandırılmış sertifika özellikleri alınamıyor: %1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;

EndFunction

Function CertificatesChainFromAddInResponse(AddInResponse, FormIdentifier) Export
	
	Result = New Structure("Certificates, Error", New Array, "");
	
	Try
		CertificatesResult = ReadAddInResponce(
			AddInResponse);
		CertificatesResult = CertificatesResult.Get("Certificates");
	Except
		
		Result.Error = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận chuỗi chứng thư %1';
				|ru = 'Невозможно получить цепочку сертификатов %1';
				|en = 'Unable to retrieve certificate chain %1'; fa = 'Unable to retrieve certificate chain %1';
				|it = 'Unable to retrieve certificate chain %1';
				|pl = 'Unable to retrieve certificate chain %1';
				|tr = '%1 sertifika zinciri alınamıyor'"),
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return Result;
		
	EndTry;
		
	For Each CurrentCertificate In CertificatesResult Do
		
		CertificateDetails = New Structure;
		CertificateDetails.Insert("Subject", CurrentCertificate.Get("subject_name"));
		CertificateData = CurrentCertificate.Get("value");
		If FormIdentifier = Undefined Then
			CertificateDetails.Insert("CertificateData", CertificateData);
		Else
			CertificateDetails.Insert("CertificateData",
				PutToTempStorage(CertificateData, FormIdentifier));
		EndIf;
		
		CertificateDetails.Insert("Issuer", CurrentCertificate.Get("issuer_name"));
		CertificateDetails.Insert("PublicKey", CurrentCertificate.Get("public_key_"));
		
		Result.Certificates.Add(CertificateDetails);
		
	EndDo;
	
	Return Result;
	
EndFunction

Function InstalledCryptoProvidersFromAddInResponse(AddInResponse, ApplicationsByNamesWithType, 
	CheckAtCleint = True) Export
	
	Try
		AllCryptoProviders = ReadAddInResponce(AddInResponse);
		Cryptoproviders = AllCryptoProviders.Get("providers");
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận thuộc tính của nhà cung cấp mã hóa: 
				 | %1';
				 |ru = 'Невозможно получить свойства криптопровайдеров:
				 | %1';
				 |en = 'Unable to retrieve cryptographic provider properties:
				 |%1'; fa = 'Unable to retrieve cryptographic provider properties:
				 |%1';
				 |it = 'Unable to retrieve cryptographic provider properties:
				 |%1';
				 |pl = 'Unable to retrieve cryptographic provider properties:
				 |%1';
				 |tr = 'Kripto sağlayıcı özelliği alınamıyor:
				 | %1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
	
	If TypeOf(Cryptoproviders) <> Type("Array") Then
		Return New Array;
	EndIf;
	
	CryptoProvidersResult = New Array;
	For Each CurCryptoProvider In Cryptoproviders Do
		
		ExtendedApplicationDetails = ExtendedApplicationDetails(
			CurCryptoProvider, ApplicationsByNamesWithType, CheckAtCleint);
			
		If ExtendedApplicationDetails = Undefined Then
			Continue;
		EndIf;
		
		CryptoProvidersResult.Add(ExtendedApplicationDetails);
		
	EndDo;
	
	Return CryptoProvidersResult;
	
EndFunction

Function ReadAddInResponce(Text) Export
	
#If WebClient Then
	Return DigitalSignatureInternalServerCall.ReadAddInResponce(Text);
#Else
	Try
		JSONReader = New JSONReader;
		JSONReader.SetString(Text);
		Result = ReadJSON(JSONReader, True);
		JSONReader.Close();
	Except
		
		ErrorInfo = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể đọc phản hồi cấu phần: %1
					|%2';
					|ru = 'Не удалось прочитать ответ компоненты: %1
					|%2';
					|en = 'Cannot read the add-in response: %1
					|%2'; fa = 'Cannot read the add-in response: %1
					|%2';
					|it = 'Не удалось прочитать ответ компоненты: %1
					|%2';
					|pl = 'Cannot read the add-in response: %1
					|%2';
					|tr = 'Şu bileşene yanıt yazılamadı: %1
					|%2'"), Text, ErrorInfo);
		
	EndTry;
	
	Return Result;
#EndIf
	
EndFunction

Function DefineApp(CertificateProperties,
			InstalledCryptoProviders, SearchOfAppsByPublicKey, ErrorDescription = "") Export
	
	If InstalledCryptoProviders.Count() = 0 Then
		ErrorDescription = NStr("vi = 'Chưa cài đặt ứng dụng chữ ký điện tử và mã hóa.';
								|ru = 'Не установлены приложения электронной подписи и шифрования.';
								|en = 'No installed digital signing and encryption apps are found.'; fa = 'No installed digital signing and encryption apps are found.';
								|it = 'Не установлены приложения электронной подписи и шифрования.';
								|pl = 'No installed digital signing and encryption apps are found.';
								|tr = 'Elektronik imza ve şifreleme uygulamaları yüklü değildir.'");
		Return Undefined;
	EndIf;
	
	AppsByPublicKey = SearchOfAppsByPublicKey.Get(CertificateProperties.PublicKeyAlgorithm);
	
	If AppsByPublicKey = Undefined Then
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa tìm thấy ứng dụng phù hợp của chữ ký điện tử và mã hóa theo khóa mở của chứng thư %1.';
				|ru = 'Не найдено подходящих приложений электронной подписи и шифрования по открытому ключу сертификата %1.';
				|en = 'Couldn''t find digital signing and encryption apps by the passed private key: %1.'; fa = 'Couldn''t find digital signing and encryption apps by the passed private key: %1.';
				|it = 'Не найдено подходящих приложений электронной подписи и шифрования по открытому ключу сертификата %1.';
				|pl = 'Couldn''t find digital signing and encryption apps by the passed private key: %1.';
				|tr = 'Uygun elektronik imza ve sertifika %1 ortak anahtar şifreleme uygulaması bulunamadı.'"),
			CertificateProperties.PublicKeyAlgorithm);
		Return Undefined;
	EndIf;
	
	ApplicationFound = Undefined;
	
	For Each InstalledCryptoProvider In InstalledCryptoProviders Do
		
		If ApplicationNotUsed(InstalledCryptoProvider.UsageMode) Then
			Continue;
		EndIf;
		
		Application = AppsByPublicKey.Get(
			ApplicationSearchKeyByNameWithType(InstalledCryptoProvider.ApplicationName, InstalledCryptoProvider.ApplicationType));
		If Application = Undefined Then
			Continue;
		EndIf;
		
		// If multiple apps installed, CryptoPro has a priority.
		If StrFind(Application, "CryptoPro") Then
			Return InstalledCryptoProvider;
		EndIf;
		
		// If multiple apps installed, Microsoft Enhanced CSP has a priority.
		If StrFind(Application, "MicrosoftEnhanced") Then
			Return InstalledCryptoProvider;
		EndIf;
		
		ApplicationFound = InstalledCryptoProvider;
		
	EndDo;
	
	If ApplicationFound = Undefined Then
		
		AlgorithmsIDs = IDsOfSignatureAlgorithms(True);
		SignAlgorithm = AlgorithmByOID(CertificateProperties.PublicKeyAlgorithm, AlgorithmsIDs, False);
		
		ErrorTemplate = NStr("vi = 'Không thể sử dụng ứng dụng nào
							|có thuật toán chữ ký %1.';
							|ru = 'Не предусмотрено использование ни одного приложения
							|с алгоритмом подписи %1.';
							|en = 'Couldn''t find any apps that are configured for this signature algorithm: %1.'; fa = 'Couldn''t find any apps that are configured for this signature algorithm: %1.';
							|it = 'Не предусмотрено использование ни одного приложения
							|с алгоритмом подписи %1.';
							|pl = 'Couldn''t find any apps that are configured for this signature algorithm: %1.';
							|tr = '%1 imza algoritmasına sahip
							|herhangi bir uygulamanın kullanılması mümkün değildir.'");
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
			TrimAll(StrSplit(SignAlgorithm, ",")[0]));
			
	EndIf;
	
	Return ApplicationFound;
	
EndFunction

Function ApplicationSearchKeyByNameWithType(Name, Type) Export
	
	Return StrTemplate("%1 (%2)", Name, Type);
	
EndFunction

//  Returns:
//   Structure - Contains operation errors occurred in the apps:
//     * ErrorDescription  - String - a full error description (when returned as a string).
//     * ErrorTitle - String - an error title that matches the operation
//                                  when there is one operation (not filled in when there are several operations).
//     * Shared3           - Boolean - if True, then one error is common for all applications.
//     * ComputerName   - String - the computer name when executing the operation on the server side.
//     * Errors          - Array of See NewErrorProperties
//
Function NewErrorsDescription(ComputerName = "") Export
	
	LongDesc = New Structure;
	LongDesc.Insert("ErrorDescription",  "");
	LongDesc.Insert("ErrorTitle", "");
	LongDesc.Insert("Shared3",           False);
	LongDesc.Insert("ComputerName",   ComputerName);
	LongDesc.Insert("Errors",          New Array);
	
	Return LongDesc;
	
EndFunction

// Returns the execution error properties of one operation by one application.
//
// Returns:
//  Structure:
//   * ErrorTitle   - String - an error title that matches the operation
//                           when there are several operations (not filled in when there is one operation).
//   * LongDesc          - String - a short error presentation.
//   * FromException      - Boolean - a description contains a brief error description.
//   * NoExtension     - Boolean - Flag indicating whether the 1C:Enterprise Extension failed to attach (needs to be installed).
//   * ToAdministrator   - Boolean - administrator rights are required to patch an error.
//   * Instruction        - Boolean - to correct, instruction on how to work with the digital signature applications is required.
//   * ApplicationsSetUp - Boolean - to fix an error, you need to configure the applications.
//   * Application         - CatalogRef.DigitalSignatureAndEncryptionApplications
//                       - String - if it is not
//                           filled in, it means an error is common for all applications.
//   * NoAlgorithm      - Boolean - the crypto manager does not support the algorithm specified
//                                  for its creation in addition to the specified application.
//   * PathNotSpecified      - Boolean - the path required for Linux OS is not specified for the application.
//
Function NewErrorProperties() Export
	
	BlankApplication = PredefinedValue("Catalog.DigitalSignatureAndEncryptionApplications.EmptyRef");
	
	ErrorProperties = New Structure;
	ErrorProperties.Insert("ErrorTitle",   "");
	ErrorProperties.Insert("LongDesc",          "");
	ErrorProperties.Insert("FromException",      False);
	ErrorProperties.Insert("NotSupported",  False);
	ErrorProperties.Insert("NoExtension",     False);
	ErrorProperties.Insert("ToAdministrator",   False);
	ErrorProperties.Insert("Instruction",        False);
	ErrorProperties.Insert("ApplicationsSetUp", False);
	ErrorProperties.Insert("Application",         BlankApplication);
	ErrorProperties.Insert("NoAlgorithm",      False);
	ErrorProperties.Insert("PathNotSpecified",      False);
	ErrorProperties.Insert("Token");
	
	Return ErrorProperties;
	
EndFunction

// Error message of the ExtraCryptoAPI call.
// 
// Parameters:
//  MethodName - String
//  ErrorInfo - String
// 
// Returns:
//  String
//
Function ErrorCallMethodComponents(MethodName, ErrorInfo) Export
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Lỗi gọi ra phương thức %1 của cấu phần %2.';
			|ru = 'Ошибка вызова метода %1 компоненты %2.';
			|en = 'Error when calling method ""%1"" of add-in ""%2"".'; fa = 'Error when calling method ""%1"" of add-in ""%2"".';
			|it = 'Errore di chiamata del metodo %1 della componente %2.';
			|pl = 'Błąd wywołania metody %1 komponentu %2.';
			|tr = '%2 bileşenin %1 yöntem çağrı hatası.'"), MethodName, "ExtraCryptoAPI")
		+ Chars.LF + ErrorInfo;
	
EndFunction

// Error text for revoked certificates.
// 
// Parameters:
//  SignatureVerificationResult - See DigitalSignatureClientServer.SignatureVerificationResult
// 
// Returns:
//  String - Error text for revoked certificates
//
Function ErrorTextForRevokedSignatureCertificate(SignatureVerificationResult) Export
	
	If ValueIsFilled(SignatureVerificationResult.DateSignedFromLabels) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chứng thư đã bị thu hồi. Chữ ký hợp lệ nếu chứng thư bị thu hồi muộn hơn %1. Để quyết định xem chữ ký có chính xác hay không, hãy hỏi trung tâm chứng thực đã cấp chứng thư, nguyên nhân và lý do thu hồi.';
				|ru = 'Сертификат отозван. Подпись верна, если сертификат был отозван позднее %1. Чтобы принять решение о том, верна ли подпись, запросите в удостоверяющем центре, выдавшем сертификат, причину и дату отзыва.';
				|en = 'The certificate is revoked. The signature is considered valid if the revocation occurred after %1. To determine the signature validity, request the revocation reason and date from the certificate authority that issued the certificate.'; fa = 'The certificate is revoked. The signature is considered valid if the revocation occurred after %1. To determine the signature validity, request the revocation reason and date from the certificate authority that issued the certificate.';
				|it = 'Сертификат отозван. Подпись верна, если сертификат был отозван позднее %1. Чтобы принять решение о том, верна ли подпись, запросите в удостоверяющем центре, выдавшем сертификат, причину и дату отзыва.';
				|pl = 'The certificate is revoked. The signature is considered valid if the revocation occurred after %1. To determine the signature validity, request the revocation reason and date from the certificate authority that issued the certificate.';
				|tr = 'Sertifika iptal edildi. Sertifika, %1 sonrasında iptal edilmişse imza doğrudur. İmzanın geçerli olup olmadığına karar vermek için, sertifikayı veren belgelendirme kuruluşundan iptal nedenini ve tarihini talep edin.'"),
			SignatureVerificationResult.DateSignedFromLabels);
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã thu hồi chứng thư. Chữ ký có thể đúng vào ngày ký %1, nếu đã thu hồi chứng thư muộn hơn. Để tìm hiểu lý do và ngày thu hồi, hãy liên hệ với trung tâm chứng thực đã cấp chứng thư.';
				|ru = 'Сертификат отозван. Подпись могла быть верна на дату подписания %1, если сертификат был отозван позднее. Чтобы узнать причину и дату отзыва, обратитесь в удостоверяющий центр, выдавший сертификат.';
				|en = 'The certificate is revoked. The signature might have been valid as of signing date %1 if the revocation occurred later. To find out the revocation reason and date, contact the certificate authority that issued the certificate.'; fa = 'The certificate is revoked. The signature might have been valid as of signing date %1 if the revocation occurred later. To find out the revocation reason and date, contact the certificate authority that issued the certificate.';
				|it = 'Сертификат отозван. Подпись могла быть верна на дату подписания %1, если сертификат был отозван позднее. Чтобы узнать причину и дату отзыва, обратитесь в удостоверяющий центр, выдавший сертификат.';
				|pl = 'The certificate is revoked. The signature might have been valid as of signing date %1 if the revocation occurred later. To find out the revocation reason and date, contact the certificate authority that issued the certificate.';
				|tr = 'Sertifika iptal edildi. Sertifikanın daha sonra iptal edilmesi durumunda imza, imza tarihi %1 itibarıyla doğru olabilir. İptalin nedenini ve tarihini öğrenmek için sertifikayı veren belgelendirme kuruluşuyla iletişime geçin.'"),
			SignatureVerificationResult.UnverifiedSignatureDate);
	EndIf;
	
	Return ErrorText;
	
EndFunction

// For internal use only.
// 
// Parameters:
//  Application - CatalogRef.DigitalSignatureAndEncryptionApplications
//            - See DigitalSignatureInternalCached.ApplicationDetails
//            - See NewExtendedApplicationDetails
//  Errors - Array
//  ApplicationsDetailsCollection - Array of See DigitalSignatureInternalCached.ApplicationDetails
//  AppsAuto - Array of See NewExtendedApplicationDetails
//
// Returns:
//  Array of See DigitalSignatureInternalCached.ApplicationDetails
//
Function CryptoManagerApplicationsDetails(Application, Errors, Val ApplicationsDetailsCollection, Val AppsAuto = Undefined) Export
	
	If TypeOf(Application) = Type("Structure") Or TypeOf(Application) = Type("FixedStructure") Then
		
		ApplicationsDetailsCollection = New Array;
		ApplicationsDetailsCollection.Add(Application);
		Return ApplicationsDetailsCollection;
		
	ElsIf Application <> Undefined Then
		
		ApplicationFound = False;
		
		For Each ApplicationDetails In ApplicationsDetailsCollection Do
			
			If ApplicationDetails.Ref = Application Then
				
				If AreAutomaticSettingsUsed(ApplicationDetails.UsageMode)
					And ValueIsFilled(AppsAuto) Then
					
					For Each AppAuto In AppsAuto Do
						If AppAuto.ApplicationName = ApplicationDetails.ApplicationName
							And AppAuto.ApplicationType = ApplicationDetails.ApplicationType Then
							ApplicationsDetailsCollection = New Array;
							ApplicationsDetailsCollection.Add(AppAuto);
							Return ApplicationsDetailsCollection;
						EndIf;
					EndDo;
					
				EndIf;
				
				If ApplicationNotUsed(ApplicationDetails.UsageMode) Then
					Break;
				EndIf;
				
				ApplicationFound = True;
				Break;
				
			EndIf;
			
		EndDo;
		
		If Not ApplicationFound Then
			CryptoManagerAddError(Errors, Application, StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Ứng dụng %1 không được phép sử dụng (đã bị tắt bởi quản trị viên).';
					|ru = 'Приложение %1 не предусмотрено для использования (отключено администратором).';
					|en = '%1 is forbidden by Administrator'; fa = '%1 is forbidden by Administrator';
					|it = 'Приложение %1 не предусмотрено для использования (отключено администратором).';
					|pl = '%1 is forbidden by Administrator';
					|tr = 'Ek %1, kullanım için sunulmamış (yönetici tarafından devre dışı bırakılmış).'"), Application), True);
			Return Undefined;
		EndIf;
		
		ApplicationsDetailsCollection = New Array;
		ApplicationsDetailsCollection.Add(ApplicationDetails);
		
	ElsIf AppsAuto <> Undefined Then
		
		For Each ApplicationDetails In ApplicationsDetailsCollection Do
			If Not ValueIsFilled(ApplicationDetails.Id)
				And Not ApplicationNotUsed(ApplicationDetails.UsageMode) Then
				
				Found4 = Undefined;
				For Each AppAuto In AppsAuto Do
					If ApplicationDetails.ApplicationName = AppAuto.ApplicationName
						And ApplicationDetails.ApplicationType = AppAuto.ApplicationType Then
						Found4 = AppAuto;
						Break;
					EndIf;
				EndDo;
				
				If Found4 = Undefined Then
					NewDetails = NewExtendedApplicationDetails();
					FillPropertyValues(NewDetails, ApplicationDetails);
					NewDetails.AutoDetect = False;
					AppsAuto.Add(NewDetails);
				EndIf;
			EndIf;
		EndDo;
		
		Return AppsAuto;
		
	EndIf;
	
	Return ApplicationsDetailsCollection;
	
EndFunction

Function AreAutomaticSettingsUsed(UsageMode) Export

	Return UsageMode = PredefinedValue(
		"Enum.DigitalSignatureAppUsageModes.Automatically")
		
EndFunction

Function ApplicationNotUsed(UsageMode) Export

	Return UsageMode = PredefinedValue(
		"Enum.DigitalSignatureAppUsageModes.NotUsed")
		
EndFunction

// For internal use only.
// 
// Parameters:
//  ApplicationDetails - See DigitalSignatureInternalCached.ApplicationDetails
//  IsLinux - Boolean
//  Errors - Array
//  IsServer - Boolean
//  ApplicationsPathsAtLinuxServers -String
// 
// Returns:
//  Structure:
//   * ApplicationPath - String
//  Undefined
//
Function CryptoManagerApplicationProperties(ApplicationDetails, IsLinux, Errors, IsServer,
			DescriptionOfWay) Export
	
	If Not ValueIsFilled(ApplicationDetails.ApplicationName) Then
		CryptoManagerAddError(Errors, ApplicationDetails.Ref,
			NStr("vi = 'Chưa chỉ ra tên ứng dụng.';
				|ru = 'Не указано название приложения.';
				|en = 'App name required.'; fa = 'App name required.';
				|it = 'Не указано название приложения.';
				|pl = 'App name required.';
				|tr = 'Uygulama adı belirtilmemiştir.'"), True);
		Return Undefined;
	EndIf;
	
	If Not ValueIsFilled(ApplicationDetails.ApplicationType) Then
		CryptoManagerAddError(Errors, ApplicationDetails.Ref,
			NStr("vi = 'Chưa chỉ ra kiểu ứng dụng.';
				|ru = 'Не указан тип приложения.';
				|en = 'App type required.'; fa = 'App type required.';
				|it = 'Не указан тип приложения.';
				|pl = 'App type required.';
				|tr = 'Uygulama tipi belirtilmemiştir.'"), True);
		Return Undefined;
	EndIf;
	
	ApplicationProperties1 = New Structure("ApplicationName, ApplicationPath, ApplicationType");
	
	ApplicationPath = "";
	AutoDetect = CommonClientServer.StructureProperty(ApplicationDetails, "AutoDetect", False);
	If IsLinux And Not AutoDetect Then
		If ValueIsFilled(DescriptionOfWay.ApplicationPath) And Not DescriptionOfWay.Exists Then
			If DescriptionOfWay.Property("ErrorText")
			   And ValueIsFilled(DescriptionOfWay.ErrorText) Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể xác định đường dẫn đến ứng dụng chữ ký điện tử và mã hóa theo nguyên nhân:
					           |%1';
					           |ru = 'Не удалось определить путь к приложению электронной подписи и шифрования по причине:
					           |%1';
					           |en = 'Couldn''t find the path to the digital signing and encryption app due to:
					           |%1'; fa = 'Couldn''t find the path to the digital signing and encryption app due to:
					           |%1';
					           |it = 'Не удалось определить путь к приложению электронной подписи и шифрования по причине:
					           |%1';
					           |pl = 'Couldn''t find the path to the digital signing and encryption app due to:
					           |%1';
					           |tr = 'Elektronik imza ve şifreleme uygulamasının yolu belirlenemedi çünkü: 
					           |%1'"), DescriptionOfWay.ErrorText);
			Else
				ThePathToTheModules = StrSplit(DescriptionOfWay.ApplicationPath, ":", False);
				If ThePathToTheModules.Count() = 1 Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Tệp không tồn tại: ""%1"".';
							|ru = 'Файл не существует: ""%1"".';
							|en = 'File does not exist: ""%1"".'; fa = 'File does not exist: ""%1"".';
							|it = 'File inesistente: ""%1"".';
							|pl = 'Plik nie istnieje: ""%1"".';
							|tr = 'Dosya mevcut değil: ""%1"". '"), ThePathToTheModules[0]);
				Else
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không có tệp nào tồn tại: ""%1"".';
							|ru = 'Ни один из файлов не существует: ""%1"".';
							|en = 'None of the files exists: ""%1"".'; fa = 'None of the files exists: ""%1"".';
							|it = 'Nessuno dei file esiste: ""%1"".';
							|pl = 'Ani jeden z plików nie istnieje: ""%1"".';
							|tr = 'Dosyalardan hiçbiri mevcut değil: ""%1"".'"),
						StrConcat(ThePathToTheModules, """, """));
				EndIf;
			EndIf;
		Else
			ErrorText = "";
			ApplicationPath = DescriptionOfWay.ApplicationPath;
		EndIf;
		If ValueIsFilled(ErrorText) Then
			CryptoManagerAddError(Errors,
				ApplicationDetails.Ref, ErrorText, IsServer);
			Return Undefined;
		EndIf;
	EndIf;
	
	ApplicationProperties1 = New Structure;
	ApplicationProperties1.Insert("ApplicationName",   ApplicationDetails.ApplicationName);
	ApplicationProperties1.Insert("ApplicationPath", ApplicationPath);
	ApplicationProperties1.Insert("ApplicationType",   ApplicationDetails.ApplicationType);
	
	Return ApplicationProperties1;
	
EndFunction

// For internal use only.
// Parameters:
//  ApplicationDetails - Structure:
//    * Ref - CatalogRef.DigitalSignatureAndEncryptionApplications
//  SignAlgorithms - Array of String
//  SignAlgorithm - String
//  Errors - Array of See NewErrorProperties
//  IsServer - Boolean
//  AddError1 - Boolean
// 
// Returns:
//  Boolean
//
Function CryptoManagerSignAlgorithmSupported(ApplicationDetails, Operation,
			SignAlgorithm, Errors, IsServer, AddError1) Export
	
	PossibleAlgorithms = StrSplit(SignAlgorithm, ",", False);
	
	For Each PossibleAlgorithm In PossibleAlgorithms Do
		PossibleAlgorithm = TrimAll(PossibleAlgorithm);
		
		If Upper(ApplicationDetails.SignAlgorithm) = Upper(PossibleAlgorithm)
		 Or (Operation = "CheckSignature" Or Operation = "CertificateCheck" Or Operation = "ExtensionValiditySignature" Or Operation = "Encryption")
		   And ApplicationDetails.SignatureVerificationAlgorithms.Find(PossibleAlgorithm) <> Undefined Then
			
			Return True;
		EndIf;
	EndDo;
	
	If Not AddError1 Then
		Return False;
	EndIf;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Ứng dụng không hỗ trợ thuật toán chữ ký %1.';
			|ru = 'Приложение не поддерживает алгоритм подписи %1.';
			|en = 'The app does not support signature algorithm %1.'; fa = 'The app does not support signature algorithm %1.';
			|it = 'Приложение не поддерживает алгоритм подписи %1.';
			|pl = 'The app does not support signature algorithm %1.';
			|tr = 'Uygulama, %1 imza algoritmasını desteklemiyor.'"),
		TrimAll(PossibleAlgorithms[0]));
	
	CryptoManagerAddError(Errors, ApplicationDetails.Ref, ErrorText, IsServer, True);
	Errors[Errors.UBound()].NoAlgorithm = True;
	
	Return False;
	
EndFunction

// For internal use only.
// 
// Parameters:
//  ApplicationDetails - See DigitalSignatureInternalCached.ApplicationDetails
//  Manager - CryptoManager
//  Errors - Array
//  EncryptAlgorithm - String
//
// Returns:
//  Boolean
//
Function CryptoManagerAlgorithmsSet(ApplicationDetails, Manager, Errors, EncryptAlgorithm = "") Export
	
	If ApplicationDetails.ApplicationName = "Default" Then
		Return True;
	EndIf;
	
	AlgorithmsSet = False;
	
	DigitalSignatureClientServerLocalization.OnSetCryptoManagerParameters(
		ApplicationDetails, Manager, EncryptAlgorithm, AlgorithmsSet);
	
	If AlgorithmsSet Then
		Return True;
	EndIf;
	
	SignAlgorithm = String(ApplicationDetails.SignAlgorithm);
	Try
		Manager.SignAlgorithm = SignAlgorithm;
	Except
		Manager = Undefined;
		// 1C:Enterprise uses a vague message "Unknown crypto algorithm". Need to replace with a more specific message.
		CryptoManagerAddError(Errors, ApplicationDetails.Ref, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã chọn thuật toán chữ ký không xác định ""%1"".';
				|ru = 'Выбран неизвестный алгоритм подписи ""%1"".';
				|en = 'Unknown signature algorithm ""%1"" is selected.'; fa = 'Unknown signature algorithm ""%1"" is selected.';
				|it = 'Algoritmo di firma ""%1"" sconosciuto selezionato.';
				|pl = 'Wybrany nieznany algorytm podpisu ""%1"".';
				|tr = 'Bilinmeyen ""%1"" imza algoritması seçildi.'"), SignAlgorithm), True);
		Return False;
	EndTry;
	
	HashAlgorithm = String(ApplicationDetails.HashAlgorithm);
	Try
		Manager.HashAlgorithm = HashAlgorithm;
	Except
		Manager = Undefined;
		// 1C:Enterprise uses a vague message "Unknown crypto algorithm". Need to replace with a more specific message.
		CryptoManagerAddError(Errors, ApplicationDetails.Ref, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã chọn thuật toán Hash không xác định ""%1"".';
				|ru = 'Выбран неизвестный алгоритм хеширования ""%1"".';
				|en = 'Unknown hashing algorithm ""%1"" is selected.'; fa = 'Unknown hashing algorithm ""%1"" is selected.';
				|it = 'Algoritmo di cache ""%1"" sconosciuto selezionato.';
				|pl = 'Wybrany nieznany algorytm mieszania ""%1"".';
				|tr = 'Bilinmeyen ""%1"" imzalama algoritması seçildi.'"), HashAlgorithm), True);
		Return False;
	EndTry;
	If IsBlankString(EncryptAlgorithm) Then
		EncryptAlgorithm = DigitalSignatureClientServerLocalization.ConvertedEncryptAlgorithm(String(ApplicationDetails.EncryptAlgorithm));
	Else
		EncryptAlgorithm = DigitalSignatureClientServerLocalization.ConvertedEncryptAlgorithm(EncryptAlgorithm);
	EndIf;
	Try
		Manager.EncryptAlgorithm = EncryptAlgorithm;
	Except
		Manager = Undefined;
		// 1C:Enterprise uses a vague message "Unknown crypto algorithm". Need to replace with a more specific message.
		CryptoManagerAddError(Errors, ApplicationDetails.Ref, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã chọn thuật toán mã hóa không xác định ""%1"".';
				|ru = 'Выбран неизвестный алгоритм шифрования ""%1"".';
				|en = 'Unknown encryption algorithm ""%1"" is selected.'; fa = 'Unknown encryption algorithm ""%1"" is selected.';
				|it = 'Algoritmo di crittografia ""%1"" sconosciuto selezionato.';
				|pl = 'Wybrany nieznany algorytm szyfrowania ""%1"".';
				|tr = 'Bilinmeyen ""%1"" şifreleme algoritması seçildi.'"), EncryptAlgorithm), True);
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// For internal use only.
// 
// Parameters:
//  ApplicationDetails - See DigitalSignatureInternalCached.ApplicationDetails
//  Errors - Array
//  IsServer - Boolean
//
Procedure CryptoManagerApplicationNotFound(ApplicationDetails, Errors, IsServer) Export
	
	CryptoManagerAddError(Errors, ApplicationDetails.Ref,
		NStr("vi = 'Chưa cài đặt ứng dụng trên máy tính.';
			|ru = 'Приложение не установлено на компьютере.';
			|en = 'Application is not installed on the computer.'; fa = 'Application is not installed on the computer.';
			|it = 'Приложение не установлено на компьютере.';
			|pl = 'Application is not installed on the computer.';
			|tr = 'Uygulama bilgisayarda kurulu değil.'"), IsServer, True);
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  ApplicationDetails - See DigitalSignatureInternalCached.ApplicationDetails
//  ApplicationNameReceived - String
//  Errors - Array
//  IsServer - Boolean
//
// Returns:
//  Boolean
//
Function CryptoManagerApplicationNameMaps(ApplicationDetails, ApplicationNameReceived, Errors, IsServer) Export
	
	If ApplicationNameReceived <> ApplicationDetails.ApplicationName Then
		CryptoManagerAddError(Errors, ApplicationDetails.Ref, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã nhận ứng dụng chữ ký điện tử và mã hóa khác với tên ""%1"".';
				|ru = 'Получено другое приложение электронной подписи и шифрования с именем ""%1"".';
				|en = 'A different digital signing and encryption app found: %1.'; fa = 'A different digital signing and encryption app found: %1.';
				|it = 'Получено другое приложение электронной подписи и шифрования с именем ""%1"".';
				|pl = 'A different digital signing and encryption app found: %1.';
				|tr = '""%1"" adlı başka bir elektronik imza ve şifreleme uygulaması alındı.'"), 
			ApplicationNameReceived), IsServer, True);
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// For internal use only.
//
// Parameters:
//  Errors    - Array of See NewErrorProperties
//  Application - CatalogRef.DigitalSignatureAndEncryptionApplications
//            - Structure - See NewExtendedApplicationDetails
//  LongDesc  - String
//  ToAdministrator - Boolean
//  Instruction   - Boolean
//  FromException - Boolean
//  PathNotSpecified - Boolean
//
Procedure CryptoManagerAddError(Errors, Application, LongDesc,
			ToAdministrator, Instruction = False, FromException = False, PathNotSpecified = False) Export
	
	ErrorProperties = NewErrorProperties();
	If TypeOf(Application) = Type("CatalogRef.DigitalSignatureAndEncryptionApplications") Then
		If ValueIsFilled(Application) Then
			ErrorProperties.Application = Application;
		EndIf;
	ElsIf TypeOf(Application) = Type("Structure") Then
		If ValueIsFilled(Application.Ref) Then
			ErrorProperties.Application = Application.Ref;
		Else
			ErrorProperties.Application = ?(ValueIsFilled(Application.Presentation), Application.Presentation,
				ApplicationSearchKeyByNameWithType(Application.ApplicationName, Application.ApplicationType));
		EndIf;
	EndIf;
	ErrorProperties.LongDesc          = LongDesc;
	ErrorProperties.ToAdministrator   = ToAdministrator;
	ErrorProperties.Instruction        = Instruction;
	ErrorProperties.FromException      = FromException;
	ErrorProperties.PathNotSpecified      = PathNotSpecified;
	ErrorProperties.ApplicationsSetUp = True;
	
	Errors.Add(ErrorProperties);
	
EndProcedure

// For internal use only.
//
// Parameters:
//  ErrorsDescription - See NewErrorsDescription
//  Application - CatalogRef.DigitalSignatureAndEncryptionApplications
//  SignAlgorithm - String
//  IsFullUser - Boolean
//  IsServer - Boolean
//
Procedure CryptoManagerFillErrorsPresentation(ErrorsDescription,
			Application, SignAlgorithm, IsFullUser, IsServer) Export
		
	If ErrorsDescription.Errors.Count() = 0 Then
		If Not ValueIsFilled(SignAlgorithm) Then
			ErrorText = NStr("vi = 'Không xem xét sử dụng một ứng dụng chữ ký điện tử và mã hóa.';
							|ru = 'Не предусмотрено использование ни одного приложения электронной подписи и шифрования.';
							|en = 'Couldn''t find any configured digital signing and encryption apps.'; fa = 'Couldn''t find any configured digital signing and encryption apps.';
							|it = 'Не предусмотрено использование ни одного приложения электронной подписи и шифрования.';
							|pl = 'Couldn''t find any configured digital signing and encryption apps.';
							|tr = 'Herhangi bir elektronik imza veya şifreleme uygulamasının kullanımına ilişkin bir hüküm bulunmamaktadır.'");
		Else
			ErrorTemplate = NStr("vi = 'Không xem xét sử dụng một ứng dụng chữ ký điện tử và mã hóa
								|với thuật toán chữ ký %1.';
								|ru = 'Не предусмотрено использование ни одного приложения электронной подписи и шифрования
								|с алгоритмом подписи %1.';
								|en = 'Couldn''t find any apps that are configured for this signature algorithm: %1.'; fa = 'Couldn''t find any apps that are configured for this signature algorithm: %1.';
								|it = 'Не предусмотрено использование ни одного приложения электронной подписи и шифрования
								|с алгоритмом подписи %1.';
								|pl = 'Couldn''t find any apps that are configured for this signature algorithm: %1.';
								|tr = '%1 imza algoritmasıyla
								|herhangi bir elektronik imza ve şifreleme uygulamasının kullanılmasına ilişkin bir hüküm yoktur.'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
				TrimAll(StrSplit(SignAlgorithm, ",")[0]));
		EndIf;
		ErrorsDescription.Shared3 = True;
		CryptoManagerAddError(ErrorsDescription.Errors,
			Undefined, ErrorText, True, True);
	EndIf;
	
	FillCommonErrorsPresentation(ErrorsDescription, IsFullUser);
	
EndProcedure

// For internal use only.
//
// Parameters:
//  ErrorsDescription - See NewErrorsDescription
//  IsFullUser - Boolean
//
Procedure FillCommonErrorsPresentation(ErrorsDescription, IsFullUser)
	
	DetailsParts = New Array;
	If ValueIsFilled(ErrorsDescription.ErrorTitle) Then
		DetailsParts.Add(ErrorsDescription.ErrorTitle);
	EndIf;
	
	ToAdministrator = False;
	For Each ErrorProperties In ErrorsDescription.Errors Do
		LongDesc = "";
		If ValueIsFilled(ErrorProperties.ErrorTitle) Then
			LongDesc = LongDesc + ErrorProperties.ErrorTitle + Chars.LF;
		EndIf;
		If ValueIsFilled(ErrorProperties.Application) Then
			LongDesc = LongDesc + String(ErrorProperties.Application) + ":" + Chars.LF;
		EndIf;
		DetailsParts.Add(LongDesc + ErrorProperties.LongDesc);
		ToAdministrator = ToAdministrator Or ErrorProperties.ToAdministrator;
	EndDo;
	ErrorDescription = StrConcat(DetailsParts, Chars.LF);
	
	If ToAdministrator And Not IsFullUser Then
		ErrorDescription = ErrorDescription + Chars.LF + Chars.LF
			+ NStr("vi = 'Hãy liên hệ với người quản trị.';
					|ru = 'Обратитесь к администратору.';
					|en = 'Please contact the administrator.'; fa = 'Please contact the administrator.';
					|it = 'Contattate l''amministratore.';
					|pl = 'Skontaktuj się z administratorem.';
					|tr = 'Yöneticiye başvurun.'");
	EndIf;
	
	ErrorsDescription.ErrorDescription = ErrorDescription;
	
EndProcedure

// Parameters:
//  ErrorTitle - String
//  ErrorsDescription - See NewErrorsDescription
//
Function TextOfTheProgramSearchError(Val ErrorTitle, ErrorsDescription) Export
	
	For Each Error In ErrorsDescription.Errors Do
		Break;
	EndDo;
	
	ErrorTitle = StrReplace(ErrorTitle, "%1", ErrorsDescription.ComputerName);
	Return ErrorTitle + " " + Error.LongDesc;
	
EndFunction

// For internal use only.
//
// Parameters:
//  Context - Structure:
//   * ApplicationDetails - Structure:
//      * Ref - CatalogRef.DigitalSignatureAndEncryptionApplications
//  Error - See NewErrorsDescription
//
// Returns:
//  CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//
Function WriteCertificateToCatalog(Context, Error) Export
	
	Context.AdditionalParameters.Application = Context.ApplicationDetails.Ref;
	Try
		Certificate = DigitalSignatureInternalServerCall.WriteCertificateToCatalog(
			Context.CertificateData, Context.AdditionalParameters);
	Except
		Certificate = Undefined;
		Context.FormCaption = NStr("vi = 'Không thể thêm chứng thư';
									|ru = 'Невозможно добавить сертификат';
									|en = 'Unable to add certificate'; fa = 'Unable to add certificate';
									|it = 'Unable to add certificate';
									|pl = 'Unable to add certificate';
									|tr = 'Sertifika eklenemiyor'");
		
		Error.Shared3 = True;
		Error.ErrorTitle = NStr("vi = 'Không thể ghi lại chứng thư do:';
								|ru = 'Не удалось записать сертификат по причине:';
								|en = 'Couldn''t save the certificate due to:'; fa = 'Couldn''t save the certificate due to:';
								|it = 'Non è stato possibile registrare il certificato a causa di:';
								|pl = 'Nie udało się zapisać certyfikatu z powodu:';
								|tr = 'Sertifika şu sebeple kaydedilemedi:'");
		
		ErrorProperties = NewErrorProperties();
		ErrorProperties.LongDesc = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		Error.Errors.Add(ErrorProperties);
	EndTry;
	
	Return Certificate;
	
EndFunction

// For internal use only.
Function CertificateAddingErrorTitle(Operation, ComputerName = "") Export
	
	If ValueIsFilled(ComputerName) Then // IsServer flag.
		If Operation = "Signing" Then
			TitleTemplate1 = NStr("vi = 'Không thể kiểm tra chữ ký trên máy chủ %1 do nguyên nhân:';
									|ru = 'Не удалось пройти проверку подписания на сервере %1 по причине:';
									|en = 'Cannot pass the signing check on the server %1 due to:'; fa = 'Cannot pass the signing check on the server %1 due to:';
									|it = 'Non è stato possibile effettuare la verifica della firma nel server %1a causa di:';
									|pl = 'Nie udało się przejść walidacji podpisania na serwerze %1 z powodu:';
									|tr = '%1 sunucusunda imzalama denetiminden şu sebeple geçilemedi:'");
		ElsIf Operation = "Encryption" Then
			TitleTemplate1 = NStr("vi = 'Không thể kiểm tra mã hóa trên máy chủ %1 do nguyên nhân:';
									|ru = 'Не удалось пройти проверку шифрования на сервере %1 по причине:';
									|en = 'Cannot pass the encryption check on the server %1 due to:'; fa = 'Cannot pass the encryption check on the server %1 due to:';
									|it = 'Non è stato possibile effettuare la verifica della crittografia nel server %1a causa di:';
									|pl = 'Nie udało się przejść weryfikacji szyfrowania na serwerze %1 z powodu:';
									|tr = '%1 sunucusunda şifreleme denetiminden şu sebeple geçilemedi:'");
		ElsIf Operation = "Details" Then
			TitleTemplate1 = NStr("vi = 'Không thể kiểm tra giải mã trên máy chủ %1 do nguyên nhân:';
									|ru = 'Не удалось пройти проверку расшифровки на сервере %1 по причине:';
									|en = 'Cannot pass the decryption check on the server %1 due to:'; fa = 'Cannot pass the decryption check on the server %1 due to:';
									|it = 'Non è stato possibile effettuare la verifica della decrittografia nel server %1 a causa di:';
									|pl = 'Nie udało się przejść weryfikacji rozszyfrowania na serwerze %1 z powodu:';
									|tr = '%1 sunucusunda detaylandırma denetiminden şu sebeple geçilemedi:'");
		EndIf;
		ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
			TitleTemplate1, ComputerName);
	Else
		If Operation = "Signing" Then
			ErrorTitle = NStr("vi = 'Không thể kiểm tra ký tên trên máy chủ do nguyên nhân:';
								|ru = 'Не удалось пройти проверку подписания на компьютере по причине:';
								|en = 'Cannot pass the signing check on the computer due to:'; fa = 'Cannot pass the signing check on the computer due to:';
								|it = 'Non è stato possibile effettuare la verifica della firma nel computer a causa di:';
								|pl = 'Nie udało się przejść walidacji podpisania na komputerze z powodu:';
								|tr = 'Bilgisayarda imzalama denetiminden şu sebeple geçilemedi:'");
		ElsIf Operation = "Encryption" Then
			ErrorTitle = NStr("vi = 'Không thể kiểm tra mã hóa trên máy tính do nguyên nhân:';
								|ru = 'Не удалось пройти проверку шифрования на компьютере по причине:';
								|en = 'Cannot pass the encryption check on the computer due to:'; fa = 'Cannot pass the encryption check on the computer due to:';
								|it = 'Non è stato possibile effettuare la verifica della crittografia nel computer a causa di:';
								|pl = 'Nie udało się przejść weryfikacji szyfrowania na komputerze z powodu:';
								|tr = 'Bilgisayarda şifreleme denetiminden şu sebeple geçilemedi:'");
		ElsIf Operation = "Details" Then
			ErrorTitle = NStr("vi = 'Không thể kiểm tra giải mã trên máy tính do nguyên nhân:';
								|ru = 'Не удалось пройти проверку расшифровки на компьютере по причине:';
								|en = 'Cannot pass the decryption check on the computer due to:'; fa = 'Cannot pass the decryption check on the computer due to:';
								|it = 'Non è stato possibile effettuare la verifica della crittografia nel computer a causa di:';
								|pl = 'Nie udało się przejść walidacji rozszyfrowania na komputerze z powodu:';
								|tr = 'Bilgisayarda detaylandırma denetiminden şu sebeple geçilemedi:'");
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(ErrorTitle) Then
		CurrentErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai giá trị tham số Thao tác ""%1"" trong thủ tục %2';
				|ru = 'Некорректное значение параметра Операция ""%1"" в процедуре %2';
				|en = 'Incorrect value of the Operation %1 parameter in the %2 procedure'; fa = 'Incorrect value of the Operation %1 parameter in the %2 procedure';
				|it = 'Valore errato del parametro Operazione ""%1"" nella procedura %2';
				|pl = 'Niepoprawna wartość parametru Operacja ""%1"" в w procedurze %2';
				|tr = '%2 prosedüründe ""%1"" İşlem parametre değeri geçersiz'"),
			Operation,
			"FillErrorAddingCertificate");
		Raise CurrentErrorText;
	EndIf;
	
	Return ErrorTitle;
	
EndFunction

// For internal use only.
//
// Parameters:
//  ErrorsDescription - See NewErrorsDescription
//  ApplicationDetails - Structure:
//   * Ref - CatalogRef.DigitalSignatureAndEncryptionApplications
//            - String - Token presentation.
//  Token - See DigitalSignatureInternalClient.TokenNewProperties
//        - Undefined
//  Operation - String
//  ErrorText - String
//  IsFullUser - Boolean
//  BlankData - Boolean
//  ComputerName - String
//
Procedure FillErrorAddingCertificate(ErrorsDescription, ApplicationDetails, Operation,
			ErrorText, IsFullUser, BlankData = False, ComputerName = "") Export
	
	ErrorTitle = CertificateAddingErrorTitle(Operation, ComputerName);
	
	ErrorProperties = NewErrorProperties();
	ErrorProperties.LongDesc = ErrorText;
	If TypeOf(ApplicationDetails.Ref) = Type("String") Then
		ErrorProperties.Application = ApplicationDetails.Ref;
		ErrorProperties.Token = ApplicationDetails.Token;
	Else
		ErrorProperties.Application = ApplicationDetails.Ref;
	EndIf;
	
	If Not BlankData Then
		ErrorProperties.FromException = True;
		ErrorProperties.Instruction = True;
		ErrorProperties.ApplicationsSetUp = True;
	EndIf;
	
	If Not ValueIsFilled(ErrorsDescription.Errors) Then
		ErrorsDescription.ErrorTitle = ErrorTitle;
		
	ElsIf Not ValueIsFilled(ErrorsDescription.ErrorTitle) Then
		ErrorProperties.ErrorTitle = ErrorTitle;
		
	ElsIf ErrorsDescription.ErrorTitle <> ErrorTitle Then
		For Each CurrentProperties In ErrorsDescription.Errors Do
			CurrentProperties.ErrorTitle = ErrorsDescription.ErrorTitle;
		EndDo;
		ErrorsDescription.ErrorTitle = "";
		ErrorProperties.ErrorTitle = ErrorTitle;
	EndIf;
	
	ErrorsDescription.Errors.Add(ErrorProperties);
	
	FillCommonErrorsPresentation(ErrorsDescription, IsFullUser);
	
EndProcedure

// For internal use only.
Function CertificateCheckModes(IgnoreTimeValidity = False, IgnoreCertificateRevocationStatus = False) Export
	
	CheckModesArray = New Array;
	
#If WebClient Then
		CheckModesArray.Add(CryptoCertificateCheckMode.AllowTestCertificates);
#EndIf
	
	If IgnoreTimeValidity Then
		CheckModesArray.Add(CryptoCertificateCheckMode.IgnoreTimeValidity);
	EndIf;
	
	If IgnoreCertificateRevocationStatus Then
		CheckModesArray.Add(CryptoCertificateCheckMode.IgnoreCertificateRevocationStatus);
	EndIf;
	
	Return CheckModesArray;
	
EndFunction

// For internal use only.
Function CertificateVerificationParametersInTheService(CommonSettings, CertificateCheckModes) Export
	
	If Not CommonSettings.YouCanCheckTheCertificateInTheCloudServiceWithTheFollowingParameters Then
		Return Undefined;
	EndIf;
	
	Modes = New Array;
	For Each Mode In CertificateCheckModes Do
		If Mode = CryptoCertificateCheckMode.IgnoreTimeValidity Then
			Modes.Add("IgnoreTimeValidity");
		ElsIf Mode = CryptoCertificateCheckMode.IgnoreSignatureValidity Then
			Modes.Add("IgnoreSignatureValidity");
		ElsIf Mode = CryptoCertificateCheckMode.IgnoreCertificateRevocationStatus Then
			Modes.Add("IgnoreCertificateRevocationStatus");
		ElsIf Mode = CryptoCertificateCheckMode.AllowTestCertificates Then
			Modes.Add("AllowTestCertificates");
		EndIf;
	EndDo;
	
	Return New Structure("CertificateVerificationMode", StrConcat(Modes, ","));
	
EndFunction

// For internal use only.
Function CertificateOverdue(Certificate, OnDate, UTCOffset) Export
	
	If Not ValueIsFilled(OnDate) Then
		Return "";
	EndIf;
	
	CertificateDates = CertificateDates(Certificate, UTCOffset);
	
	If CertificateDates.EndDate > BegOfDay(OnDate) Then
		Return "";
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chứng thư đã quá hạn %1.';
			|ru = 'На %1 просрочен сертификат.';
			|en = 'Certificate is overdue on %1.'; fa = 'Certificate is overdue on %1.';
			|it = 'Per %1 è scaduto il certificato.';
			|pl = 'Na %1 wygasł certyfikat.';
			|tr = '%1''de sertifika süresi bitmiş.'"), Format(BegOfDay(OnDate), "DLF=D"));
	
EndFunction

// For internal use only.
Function PrivateKeyExpired(CertificateProperties, OnDate) Export
	
	If Not ValueIsFilled(OnDate) Or Not ValueIsFilled(CertificateProperties.PrivateKeyExpirationDate) Then
		Return "";
	EndIf;
	
	If CertificateProperties.PrivateKeyExpirationDate > BegOfDay(OnDate) Then
		Return "";
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đối với %1 đã quá hạn khóa riêng của chứng thư.';
			|ru = 'На %1 просрочен закрытый ключ сертификата.';
			|en = 'As of %1, the private certificate key has expired.'; fa = 'As of %1, the private certificate key has expired.';
			|it = 'На %1 просрочен закрытый ключ сертификата.';
			|pl = 'As of %1, the private certificate key has expired.';
			|tr = 'Sertifikanın özel anahtarının vadesi %1 ile geçmiştir.'"), Format(BegOfDay(OnDate), "DLF=D"));
	
EndFunction

// For internal use only.
Function ServiceErrorTextCertificateInvalid() Export
	
	Return NStr("vi = 'Dịch vụ thông báo rằng, chứng thư không hợp lệ.';
				|ru = 'Сервис сообщил, что сертификат недействителен.';
				|en = 'The service reported that the certificate is invalid.'; fa = 'The service reported that the certificate is invalid.';
				|it = 'Il servizio riporta che il certificato non è valido.';
				|pl = 'Usługa powiadomiła, że certyfikat jest nieważny.';
				|tr = 'Servis, sertifikanın geçersiz olduğunu bildirdi.'");
	
EndFunction

// For internal use only.
//
// Returns:
//  String
//
Function ServiceErrorTextSignatureInvalid() Export
	
	Return NStr("vi = 'Dịch vụ thông báo rằng chữ ký không hợp lệ.';
				|ru = 'Сервис сообщил, что подпись недействительна.';
				|en = 'The service reported that the signature is invalid.'; fa = 'The service reported that the signature is invalid.';
				|it = 'Il servizio riporta che la firma non è valida.';
				|pl = 'Usługa powiadomiła, że podpis jest nieważny.';
				|tr = 'Servis, imzanın geçersiz olduğunu bildirdi.'");
	
EndFunction

// For internal use only.
Function StorageTypeToSearchCertificate(InPersonalStorageOnly) Export
	
	If TypeOf(InPersonalStorageOnly) = Type("CryptoCertificateStoreType") Then
		StoreType = InPersonalStorageOnly;
	ElsIf InPersonalStorageOnly Then
		StoreType = CryptoCertificateStoreType.PersonalCertificates;
	Else
		StoreType = Undefined; // The storage that contains certificates of all available types.
	EndIf;
	
	Return StoreType;
	
EndFunction

// For internal use only.
Procedure AddCertificatesProperties(Table, CertificatesArray, NoFilter,
	UTCOffset, CurrentSessionDate, Parameters = Undefined) Export
	
	ThumbprintsOnly = False;
	InCloudService = False;
	CloudSignature = False;
	IsOnToken = False;
	
	If Parameters <> Undefined Then
		If Parameters.Property("ThumbprintsOnly") Then
			ThumbprintsOnly = Parameters.ThumbprintsOnly;
		EndIf;
		If Parameters.Property("InCloudService") Then
			InCloudService = Parameters.InCloudService;
		EndIf;
		If Parameters.Property("CloudSignature") Then
			CloudSignature = Parameters.CloudSignature;
		EndIf;
		If Parameters.Property("IsOnToken") Then
			IsOnToken = Parameters.IsOnToken;
		EndIf;
	EndIf;
	
	If ThumbprintsOnly Then
		AlreadyAddedCertificatesThumbprints = Table;
		AtServer = False;
	Else
		AlreadyAddedCertificatesThumbprints = New Map; // Skip duplicates.
		AtServer = TypeOf(Table) <> Type("Array");
	EndIf;
	
	For Each CurrentCertificate In CertificatesArray Do
		Thumbprint = Base64String(CurrentCertificate.Thumbprint);
		CertificateDates = CertificateDates(CurrentCertificate, UTCOffset);
		
		If CertificateDates.ValidBefore <= CurrentSessionDate Then
			If Not NoFilter Then
				Continue; // Skip overdue certificates.
			EndIf;
		EndIf;
		
		If AlreadyAddedCertificatesThumbprints.Get(Thumbprint) <> Undefined Then
			Continue;
		EndIf;
		AlreadyAddedCertificatesThumbprints.Insert(Thumbprint, True);
		
		If ThumbprintsOnly Then
			Continue;
		EndIf;
		
		LocationType = 1;
		If AtServer Then
			If CloudSignature Then
				LocationType = 3;
			ElsIf InCloudService Then
				LocationType = 4;
			ElsIf IsOnToken Then
				LocationType = 5;
			Else
				LocationType = 2;
			EndIf;
			String = Table.Find(Thumbprint, "Thumbprint");
			If String <> Undefined Then
				If InCloudService Then
					String.InCloudService = True;
				EndIf;
				If IsOnToken Then
					String.IsOnToken = True;
				EndIf;
				Continue; // Skipping certificates already added on the client.
			EndIf;
		EndIf;
		
		CertificateStatus = 2;
		If CertificateDates.ValidBefore <= CurrentSessionDate Then
			CertificateStatus = 4;
		ElsIf CertificateDates.ValidBefore <= CurrentSessionDate + 30*24*60*60 Then
			CertificateStatus = 3;
		EndIf;
		
		CertificateProperties = New Structure;
		CertificateProperties.Insert("Thumbprint", Thumbprint);
		CertificateProperties.Insert("Presentation", CertificatePresentation(
			New Structure("Certificate, ValidBefore", CurrentCertificate, CertificateDates.ValidBefore)));
		CertificateProperties.Insert("IssuedBy", IssuerPresentation(CurrentCertificate));
		CertificateProperties.Insert("LocationType", LocationType);
		CertificateProperties.Insert("CertificateStatus", CertificateStatus);
		
		If TypeOf(Table) = Type("Array") Then
			Table.Add(CertificateProperties);
		Else
			If CloudSignature Then
				CertificateProperties.Insert("AtServer", False);
			ElsIf InCloudService Then
				CertificateProperties.Insert("InCloudService", True);
			ElsIf AtServer Then
				CertificateProperties.Insert("AtServer", True);
			ElsIf IsOnToken Then
				CertificateProperties.Insert("IsOnToken", True);	
			EndIf;
			FillPropertyValues(Table.Add(), CertificateProperties);
		EndIf;
	EndDo;
	
EndProcedure

// For internal use only.
//
// Parameters:
//   Array - Array
//
Procedure AddCertificatesThumbprints(Array, CertificatesArray, UTCOffset, CurrentSessionDate) Export
	
	For Each CurrentCertificate In CertificatesArray Do
		Thumbprint = Base64String(CurrentCertificate.Thumbprint);
		If TypeOf(CurrentSessionDate) = Type("Date") Then
			CertificateDates = CertificateDates(CurrentCertificate, UTCOffset);
			
			If CertificateDates.ValidBefore <= CurrentSessionDate Then
				Continue; // Skipping overdue certificates.
			EndIf;
		EndIf;
		If Array.Find(Thumbprint) = Undefined Then
			Array.Add(Thumbprint);
		EndIf;
	EndDo;
	
EndProcedure



// For internal use only.
// Returns:
//  Date, Undefined - Date used to verify the signature certificate
//
Function DateToVerifySignatureCertificate(SignatureParameters) Export
	
	If ValueIsFilled(CommonClientServer.StructureProperty(
		SignatureParameters, "DateSignedFromLabels", Undefined)) Then
		Return SignatureParameters.DateSignedFromLabels;
	EndIf;
	
	If ValueIsFilled(CommonClientServer.StructureProperty(
		SignatureParameters, "UnverifiedSignatureDate", Undefined)) Then
		Return SignatureParameters.UnverifiedSignatureDate;
	EndIf;
	
	Return Undefined;
	
EndFunction

Function NewSettingsSignaturesCryptography() Export
	
	SignatureParameters = New Structure;
	
	SignatureParameters.Insert("SignatureType");
	SignatureParameters.Insert("DateActionLastTimestamp");
	SignatureParameters.Insert("CertificateLastTimestamp");
	SignatureParameters.Insert("DateSignedFromLabels");
	SignatureParameters.Insert("UnverifiedSignatureDate");
	SignatureParameters.Insert("DateLastTimestamp");
	SignatureParameters.Insert("CertificateDetails");
	SignatureParameters.Insert("Certificate");
	
	Return SignatureParameters;
	
EndFunction

// For internal use only.
//
// Returns:
//  Structure - Cryptographic signature parameters:
//   * SignatureType          - EnumRef.CryptographySignatureTypes
//   * DateActionLastTimestamp - Date, Undefined - Filled only using the cryptographic manager.
//   * DateSignedFromLabels - Date, Undefined - Date of the earliest timestamp.
//   * UnverifiedSignatureDate - Date - Unconfirmed signature data.
//                                 - Undefined - Unconfirmed signature data is missing from the signature data.
//   * DateLastTimestamp - Date - Date of the latest timestamp.
//   * Certificate   - CryptoCertificate - Signatory's certificate
//   * CertificateDetails - See DigitalSignatureClient.CertificateProperties.
//
Function ParametersCryptoSignatures(SignatureParameters, Signature, IsCertificateExists, UTCOffset, SessionDate) Export
	
	DateSignedFromLabels = Date(3999, 12, 31);
	
	If ValueIsFilled(Signature.UnverifiedSignatureTime) Then
		SignatureParameters.UnverifiedSignatureDate = Signature.UnverifiedSignatureTime + UTCOffset;
	EndIf;
	
	SignatureParameters.SignatureType = CryptoSignatureType(Signature.SignatureType);
	DateActionLastTimestamp = Undefined;
	If Signature.SignatureTimestamp <> Undefined Then
		CertificateLastTimestamp = Signature.SignatureTimestamp.Signatures[0].SignatureCertificate; // CryptoCertificate
		DateActionLastTimestamp = CertificateLastTimestamp.ValidTo;
		DateSignedFromLabels = Min(DateSignedFromLabels, Signature.SignatureTimestamp.Date);
		SignatureParameters.DateLastTimestamp = Signature.SignatureTimestamp.Date + UTCOffset;
	EndIf;
	
	If Signature.SignatureVerificationDataTimestamp <> Undefined Then
		CertificateLastTimestamp = Signature.SignatureVerificationDataTimestamp.Signatures[0].SignatureCertificate;  // CryptoCertificate
		DateActionLastTimestamp = CertificateLastTimestamp.ValidTo;
		DateSignedFromLabels = Min(DateSignedFromLabels, Signature.SignatureVerificationDataTimestamp.Date);
		SignatureParameters.DateLastTimestamp = Signature.SignatureVerificationDataTimestamp.Date + UTCOffset;
	EndIf;
	
	If Signature.ArchiveTimestamps.Count() > 0 Then
		IndexLastLabels = 0;
		DateOfLastTag = Date(1,1,1);
		LabelIndex = 0;
		For Each CurLabel_ In Signature.ArchiveTimestamps Do
			If CurLabel_.Date > DateOfLastTag Then
				IndexLastLabels = LabelIndex;
				DateOfLastTag = CurLabel_.Date;
			EndIf;
			DateSignedFromLabels = Min(DateSignedFromLabels, CurLabel_.Date);
			LabelIndex = LabelIndex + 1;
		EndDo;
		CertificateLastTimestamp = Signature.ArchiveTimestamps[IndexLastLabels].Signatures[0].SignatureCertificate; // CryptoCertificate
		DateActionLastTimestamp = CertificateLastTimestamp.ValidTo;
		SignatureParameters.DateLastTimestamp = Signature.ArchiveTimestamps[IndexLastLabels].Date + UTCOffset;
	EndIf;
	
	If ValueIsFilled(DateActionLastTimestamp) Then
		SignatureParameters.DateActionLastTimestamp = DateActionLastTimestamp + UTCOffset; 
		SignatureParameters.CertificateLastTimestamp = CertificateLastTimestamp;
	ElsIf IsCertificateExists And SignatureParameters.CertificateDetails.ValidBefore < SessionDate Then
		SignatureParameters.DateActionLastTimestamp = SignatureParameters.CertificateDetails.ValidBefore;
		SignatureParameters.CertificateLastTimestamp = Signature.SignatureCertificate;
	ElsIf IsCertificateExists Then
		SignatureParameters.CertificateLastTimestamp = Signature.SignatureCertificate;
	EndIf;

	If DateSignedFromLabels <> Date(3999, 12, 31) Then
		SignatureParameters.DateSignedFromLabels = DateSignedFromLabels + UTCOffset;
	EndIf;
		
	Return SignatureParameters;
	
EndFunction

// For internal use only.
Function CryptoSignatureType(SignatureTypeValue) Export
	
#If MobileClient Then
	
	Return Undefined;
	
#Else

	If TypeOf(SignatureTypeValue) = Type("CryptoSignatureType") Then
		If SignatureTypeValue = CryptoSignatureType.CAdESBES Then
			Return PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES");
		ElsIf SignatureTypeValue = CryptoSignatureType.CAdEST Then
			Return PredefinedValue("Enum.CryptographySignatureTypes.WithTimeCAdEST");
		ElsIf SignatureTypeValue = CryptoSignatureType.CAdESAv3 Then
			Return PredefinedValue("Enum.CryptographySignatureTypes.ArchivalCAdESAv3");
		ElsIf SignatureTypeValue = CryptoSignatureType.CAdESC Then
			Return PredefinedValue("Enum.CryptographySignatureTypes.WithCompleteValidationDataReferencesCAdESC");
		ElsIf SignatureTypeValue = CryptoSignatureType.CAdESXLongType2 Then
			Return PredefinedValue("Enum.CryptographySignatureTypes.ExtendedLongCAdESXLongType2");
		ElsIf SignatureTypeValue = CryptoSignatureType.CAdESAv2 Then
			Return PredefinedValue("Enum.CryptographySignatureTypes.CAdESAv2");
		ElsIf SignatureTypeValue = CryptoSignatureType.CMS Then
			Return PredefinedValue("Enum.CryptographySignatureTypes.NormalCMS");
		ElsIf SignatureTypeValue = CryptoSignatureType.CAdESXLong Then
			Return PredefinedValue("Enum.CryptographySignatureTypes.CAdESXLong");
		ElsIf SignatureTypeValue = CryptoSignatureType.CAdESXLongType1 Then
			Return PredefinedValue("Enum.CryptographySignatureTypes.CAdESXLongType1");
		ElsIf SignatureTypeValue = CryptoSignatureType.CAdESXType1  Then
			Return PredefinedValue("Enum.CryptographySignatureTypes.CAdESXType1");
		ElsIf SignatureTypeValue = CryptoSignatureType.CAdESXType2 Then
			Return PredefinedValue("Enum.CryptographySignatureTypes.CAdESXType2");
		EndIf;
	Else
		If SignatureTypeValue = PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES") Then
			Return CryptoSignatureType.CAdESBES;
		ElsIf SignatureTypeValue = PredefinedValue("Enum.CryptographySignatureTypes.WithTimeCAdEST") Then
			Return CryptoSignatureType.CAdEST;
		ElsIf SignatureTypeValue = PredefinedValue("Enum.CryptographySignatureTypes.ArchivalCAdESAv3") Then
			Return CryptoSignatureType.CAdESAv3;
		ElsIf SignatureTypeValue = PredefinedValue("Enum.CryptographySignatureTypes.WithCompleteValidationDataReferencesCAdESC") Then
			Return CryptoSignatureType.CAdESC;
		ElsIf SignatureTypeValue = PredefinedValue("Enum.CryptographySignatureTypes.ExtendedLongCAdESXLongType2") Then
			Return CryptoSignatureType.CAdESXLongType2;
		ElsIf SignatureTypeValue = PredefinedValue("Enum.CryptographySignatureTypes.CAdESAv2") Then
			Return CryptoSignatureType.CAdESAv2;
		ElsIf SignatureTypeValue = PredefinedValue("Enum.CryptographySignatureTypes.NormalCMS") Then
			Return CryptoSignatureType.CMS;
		ElsIf SignatureTypeValue = PredefinedValue("Enum.CryptographySignatureTypes.CAdESXLong") Then
			Return CryptoSignatureType.CAdESXLong;
		ElsIf SignatureTypeValue = PredefinedValue("Enum.CryptographySignatureTypes.CAdESXLongType1") Then
			Return CryptoSignatureType.CAdESXLongType1;
		ElsIf SignatureTypeValue = PredefinedValue("Enum.CryptographySignatureTypes.CAdESXType1") Then
			Return CryptoSignatureType.CAdESXType1;
		ElsIf SignatureTypeValue = PredefinedValue("Enum.CryptographySignatureTypes.CAdESXType2") Then
			Return CryptoSignatureType.CAdESXType2;
		EndIf;
	EndIf;
	
	Return Undefined;
	
#EndIf
	
EndFunction

// For internal use only.
Function SignatureCreationSettings(SignatureType, TimestampServersAddresses) Export
	
	Result = New Structure("SignatureType, TimestampServersAddresses");
	Result.TimestampServersAddresses = New Array;
	
	If Not ValueIsFilled(SignatureType) Then
		Result.SignatureType = CryptoSignatureType(
			PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES"));
		Return Result;
	EndIf;
	
	If SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.WithTimeCAdEST") 
		Or SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.WithCompleteValidationDataReferencesCAdESC")
		Or SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.ExtendedLongCAdESXLongType2")
		Or SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.ArchivalCAdESAv3") Then 
		
		Result.TimestampServersAddresses = TimestampServersAddresses;
		
		Boundary = Result.TimestampServersAddresses.UBound();
		For Counter = 0 To Boundary Do
			CurrentIndex = Boundary - Counter;
			URIStructure = CommonClientServer.URIStructure(Result.TimestampServersAddresses[CurrentIndex]);
			If URIStructure.ServerName = "" Then
				Result.TimestampServersAddresses.Delete(CurrentIndex);
			EndIf;
		EndDo;
		
		If Result.TimestampServersAddresses.Count() = 0 Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Để tạo chữ ký có kiểu ""%1"" hãy điền địa chỉ máy chủ dấu thời gian.';
					|ru = 'Для создания подписи с типом ""%1"" заполните адреса серверов меток времени.';
					|en = 'To create a signature with type ""%1"", fill in timestamp server addresses.'; fa = 'To create a signature with type ""%1"", fill in timestamp server addresses.';
					|it = 'Для создания подписи с типом ""%1"" заполните адреса серверов меток времени.';
					|pl = 'To create a signature with type ""%1"", fill in timestamp server addresses.';
					|tr = '""%1"" türü bir imza oluşturmak için zaman damgası sunucularının adreslerini doldurun.'"), SignatureType);
		EndIf;
		
	ElsIf SignatureType <> PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES")
		And SignatureType <> PredefinedValue("Enum.CryptographySignatureTypes.NormalCMS") Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không hỗ trợ tạo chữ ký kiểu ""%1"".';
				|ru = 'Создание подписи типа ""%1"" не поддерживается.';
				|en = 'Creating a signature of type ""%1"" is not supported.'; fa = 'Creating a signature of type ""%1"" is not supported.';
				|it = 'Creazione firma di tipo ""%1"" non supportata.';
				|pl = 'Utworzenie podpisu typu ""%1"" nie jest obsługiwane.';
				|tr = '""%1"" türü imza oluşturma desteklenmez.'"), SignatureType);
	EndIf;
	
	Result.SignatureType = CryptoSignatureType(SignatureType);
	
	Return Result;
	
EndFunction

// For internal use only.
Function ToBeImproved(SignatureType, NewSignatureType) Export
	
	If NewSignatureType = PredefinedValue("Enum.CryptographySignatureTypes.WithTimeCAdEST")
		And SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES") Then
		Return True;
	EndIf;
	
	If NewSignatureType = PredefinedValue("Enum.CryptographySignatureTypes.ArchivalCAdESAv3")
		And (SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES")
		Or SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.WithTimeCAdEST")
		Or SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.WithCompleteValidationDataReferencesCAdESC")
		Or SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.CAdESXLong")
		Or SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.CAdESXType1")
		Or SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.CAdESXType2")
		Or SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.CAdESXLongType1")
		Or SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.ExtendedLongCAdESXLongType2")) Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// For internal use only.
Function DataGettingErrorTitle(Operation) Export
	
	If Operation = "Signing" Then
		Return NStr("vi = 'Không thể nhận dữ liệu để ký do nguyên nhân:';
					|ru = 'Не удалось получить данные для подписания по причине:';
					|en = 'Cannot receive data for signing due to:'; fa = 'Cannot receive data for signing due to:';
					|it = 'Не удалось получить данные для подписания по причине:';
					|pl = 'Cannot receive data for signing due to:';
					|tr = 'İmzalama için şu sebeple veri alınamadı:'");
	ElsIf Operation = "Encryption" Then
		Return NStr("vi = 'Không thể nhận dữ liệu để mã hóa do nguyên nhân:';
					|ru = 'Не удалось получить данные для шифрования по причине:';
					|en = 'Cannot receive data to encrypt due to:'; fa = 'Cannot receive data to encrypt due to:';
					|it = 'Не удалось получить данные для шифрования по причине:';
					|pl = 'Cannot receive data to encrypt due to:';
					|tr = 'Şifreleme için şu sebeple veri alınamadı:'");
	ElsIf Operation = "ExtensionValiditySignature" Then
		Return NStr("vi = 'Không thể nhận dữ liệu chữ ký để gia hạn do nguyên nhân:';
					|ru = 'Не удалось получить данные подписи для продления по причине:';
					|en = 'Cannot receive the signature data to renew due to:'; fa = 'Cannot receive the signature data to renew due to:';
					|it = 'Не удалось получить данные подписи для продления по причине:';
					|pl = 'Cannot receive the signature data to renew due to:';
					|tr = 'Uzantı için şu sebeple imza verileri alınamadı:'");
	Else
		Return NStr("vi = 'Không thể nhận dữ liệu để giải mã do nguyên nhân:';
					|ru = 'Не удалось получить данные для расшифровки по причине:';
					|en = 'Cannot receive data to decrypt due to:'; fa = 'Cannot receive data to decrypt due to:';
					|it = 'Не удалось получить данные для расшифровки по причине:';
					|pl = 'Cannot receive data to decrypt due to:';
					|tr = 'Veriler şifreleme için şu sebeple alınamadı:'");
	EndIf;
	
EndFunction

// For internal use only.
Function BlankSignatureData(SignatureData, ErrorDescription) Export
	
	If Not ValueIsFilled(SignatureData) Then
		ErrorDescription = NStr("vi = 'Đã tạo chữ ký trống.';
								|ru = 'Сформирована пустая подпись.';
								|en = 'Empty signature is generated.'; fa = 'Empty signature is generated.';
								|it = 'Firma vuota creata.';
								|pl = 'Utworzono pusty podpis.';
								|tr = 'Boş imza oluşturuldu.'");
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// For internal use only.
Function BlankEncryptedData(EncryptedData, ErrorDescription) Export
	
	If Not ValueIsFilled(EncryptedData) Then
		ErrorDescription = NStr("vi = 'Đã tạo dữ liệu được mã hóa trống.';
								|ru = 'Сформированы пустые зашифрованные данные.';
								|en = 'Empty encrypted data is generated.'; fa = 'Empty encrypted data is generated.';
								|it = 'Creati dati vuoi criptati.';
								|pl = 'Utworzone puste zaszyfrowane dane.';
								|tr = 'Boş şifrelenmiş veriler oluşturuldu.'");
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// For internal use only.
Function BlankDecryptedData(DecryptedData, ErrorDescription) Export
	
	If Not ValueIsFilled(DecryptedData) Then
		ErrorDescription = NStr("vi = 'Đã tạo dữ liệu được giải mã trống.';
								|ru = 'Сформированы пустые расшифрованные данные.';
								|en = 'Empty decrypted data is generated.'; fa = 'Empty decrypted data is generated.';
								|it = 'Creati dati vuoti decrittati.';
								|pl = 'Utworzone puste rozszyfrowane dane.';
								|tr = 'Şifresi açılmış boş veriler oluşturuldu.'");
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// For internal use only.
Function GeneralDescriptionOfTheError(ErrorAtClient, ErrorAtServer, ErrorTitle = "") Export
	
	ErrorDetailsAtClient = SimplifiedErrorStructure(ErrorAtClient, ErrorTitle);
	ErrorDescriptionAtServer = SimplifiedErrorStructure(ErrorAtServer, ErrorTitle);
	
	If Not ValueIsFilled(ErrorDetailsAtClient.ErrorDescription)
	   And Not ValueIsFilled(ErrorDescriptionAtServer.ErrorDescription) Then
	
		GeneralDescriptionOfTheError = NStr("vi = 'Tình huống bất thường';
											|ru = 'Непредвиденная ситуация';
											|en = 'Unexpected error'; fa = 'Unexpected error';
											|it = 'Непредвиденная ситуация';
											|pl = 'Unexpected error';
											|tr = 'Beklenmedik durum'");
		
	ElsIf Not ValueIsFilled(ErrorDetailsAtClient.ErrorDescription)
	      Or ErrorDetailsAtClient.NotSupported
	        And ValueIsFilled(ErrorDescriptionAtServer.ErrorDescription) Then
		
		If ValueIsFilled(ErrorDescriptionAtServer.ErrorTitle)
		   And ValueIsFilled(ErrorDescriptionAtServer.LongDesc) Then
		
			GeneralDescriptionOfTheError =
				  ErrorDescriptionAtServer.ErrorTitle
				+ Chars.LF
				+ NStr("vi = 'Trên server:';
						|ru = 'На сервере:';
						|en = 'On the server:'; fa = 'On the server:';
						|it = 'Su server:';
						|pl = 'Na serwerze';
						|tr = 'Sunucuda:'")
				+ " " + ErrorDescriptionAtServer.LongDesc;
		Else
			GeneralDescriptionOfTheError =
				NStr("vi = 'Trên server:';
					|ru = 'На сервере:';
					|en = 'On the server:'; fa = 'On the server:';
					|it = 'Su server:';
					|pl = 'Na serwerze';
					|tr = 'Sunucuda:'")
				+ " " + ErrorDescriptionAtServer.ErrorDescription;
		EndIf;
		
	ElsIf Not ValueIsFilled(ErrorDescriptionAtServer.ErrorDescription) Then
		GeneralDescriptionOfTheError = ErrorDetailsAtClient.ErrorDescription;
	Else
		If ErrorDetailsAtClient.ErrorTitle = ErrorDescriptionAtServer.ErrorTitle
		   And ValueIsFilled(ErrorDetailsAtClient.ErrorTitle) Then
			
			GeneralDescriptionOfTheError = ErrorDetailsAtClient.ErrorTitle + Chars.LF;
			ErrorTextOnTheClient = ErrorDetailsAtClient.LongDesc;
			ErrorTextOnTheServer = ErrorDescriptionAtServer.LongDesc;
		Else
			GeneralDescriptionOfTheError = "";
			ErrorTextOnTheClient = ErrorDetailsAtClient.ErrorDescription;
			ErrorTextOnTheServer = ErrorDescriptionAtServer.ErrorDescription;
		EndIf;
		
		GeneralDescriptionOfTheError = GeneralDescriptionOfTheError
			+ NStr("vi = 'Trên máy tính:';
					|ru = 'На компьютере:';
					|en = 'On the computer:'; fa = 'On the computer:';
					|it = 'Sul computer:';
					|pl = 'Na komputerze:';
					|tr = 'Bilgisayarda:'")
			+ " " + ErrorTextOnTheClient
			+ Chars.LF
			+ NStr("vi = 'Trên server:';
					|ru = 'На сервере:';
					|en = 'On the server:'; fa = 'On the server:';
					|it = 'Su server:';
					|pl = 'Na serwerze';
					|tr = 'Sunucuda:'")
			+ " " + ErrorTextOnTheServer;
	EndIf;
	
	Return GeneralDescriptionOfTheError;
	
EndFunction

// For internal use only.
Function SigningDateUniversal(Data) Export
	
	BinaryData = BinaryDataFromTheData(Data,
		"DigitalSignatureInternalClientServer.SignAlgorithm");
	
	DataAnalysis = NewDataAnalysis(BinaryData);
		
	// SEQUENCE (PKCS #7 ContentInfo).
	SkipBlockStart(DataAnalysis, 0, 16);
		// OBJECT IDENTIFIER (contentType).
		SkipBlockStart(DataAnalysis, 0, 6);
			// 1.2.840.113549.1.7.2 signedData (PKCS #7).
			ToCheckTheDataBlock(DataAnalysis, "2A864886F70D010702");
			SkipTheParentBlock(DataAnalysis);
		// [0]CS             (content [0] EXPLICIT ANY DEFINED BY contentType OPTIONAL).
		SkipBlockStart(DataAnalysis, 2, 0);
			// SEQUENCE (content SignedData).
			SkipBlockStart(DataAnalysis, 0, 16);
				// INTEGER  (version          Version).
				SkipBlock(DataAnalysis, 0, 2);
				// SET      (digestAlgorithms DigestAlgorithmIdentifiers).
				SkipBlock(DataAnalysis, 0, 17);
				// SEQUENCE (contentInfo      ContentInfo).
				SkipBlock(DataAnalysis, 0, 16);
				// [0]CS    (certificates     [0] IMPLICIT ExtendedCertificatesAndCertificates OPTIONAL).
				SkipBlock(DataAnalysis, 2, 0, False);
				// [1]CS    (crls             [1] IMPLICIT CertificateRevocationLists OPTIONAL).
				SkipBlock(DataAnalysis, 2, 1, False);
				// SET      (signerInfos      SET OF SignerInfo).
				SkipBlockStart(DataAnalysis, 0, 17);
					// SEQUENCE (signerInfo SignerInfo).
					SkipBlockStart(DataAnalysis, 0, 16);
						// INTEGER  (version                   Version).
						SkipBlock(DataAnalysis, 0, 2);
						// SEQUENCE (issuerAndSerialNumber     IssuerAndSerialNumber).
						SkipBlock(DataAnalysis, 0, 16);
						// SEQUENCE (digestAlgorithm           DigestAlgorithmIdentifier).
						SkipBlock(DataAnalysis, 0, 16);
						// [0]CS    (authenticatedAttributes   [0] IMPLICIT Attributes OPTIONAL).
						SkipBlockStart(DataAnalysis, 2, 0);

	If DataAnalysis.HasError Then
		Return Undefined;
	EndIf;
	
	OffsetOfTheFollowing = DataAnalysis.Parents[0].OffsetOfTheFollowing;
	While DataAnalysis.Offset < OffsetOfTheFollowing Do
		
		// SEQUENCE (Attributes).
		SkipBlockStart(DataAnalysis, 0, 16);
		
		If DataAnalysis.HasError Then
			Return Undefined;
		EndIf; 
		
		// OBJECT IDENTIFIER
		SkipBlockStart(DataAnalysis, 0, 6);
		
		DataSize = DataAnalysis.Parents[0].DataSize;
		If DataSize = 0 Then
			WhenADataStructureErrorOccurs(DataAnalysis);
			Return Undefined;
		EndIf;
		
		If DataSize = 9 Then
			Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
			BufferString = GetHexStringFromBinaryDataBuffer(Buffer);
			If BufferString = "2A864886F70D010905" Then // 1.2.840.113549.1.9.5 signingTime
				
				SigningDate = ReadDateFromClipboard(DataAnalysis.Buffer, DataAnalysis.Offset + 11);
				
				If ValueIsFilled(SigningDate) Then
					Return SigningDate;
				Else
					Return Undefined;
				EndIf;
				
			EndIf;
		EndIf; 
		SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER
		SkipTheParentBlock(DataAnalysis); // SEQUENCE
	EndDo;
	
	Return Undefined;
	
EndFunction

// For internal use only.
Function SignaturePropertiesFromBinaryData(Data, UTCOffset = Undefined, ShouldReadCertificates = False) Export
	
	SignatureProperties = New Structure;
	SignatureProperties.Insert("SignatureType", PredefinedValue("Enum.CryptographySignatureTypes.NormalCMS"));
	SignatureProperties.Insert("SigningDate");
	SignatureProperties.Insert("DateOfTimeStamp");
	SignatureProperties.Insert("Certificates", New Array);
	SignatureProperties.Insert("SignatureCertificate", Undefined);
	
	BinaryData = BinaryDataFromTheData(Data,
		"DigitalSignatureInternalClientServer.SignaturePropertiesFromBinaryData");
	
	DataAnalysis = NewDataAnalysis(BinaryData);
		
	// SEQUENCE (PKCS #7 ContentInfo).
	SkipBlockStart(DataAnalysis, 0, 16);
		// OBJECT IDENTIFIER (contentType).
		SkipBlockStart(DataAnalysis, 0, 6);
			// 1.2.840.113549.1.7.2 signedData (PKCS #7).
			ToCheckTheDataBlock(DataAnalysis, "2A864886F70D010702");
			If DataAnalysis.HasError Then
				SignatureProperties.SignatureType = Undefined;
				Return SignatureProperties;
			EndIf;
			SkipTheParentBlock(DataAnalysis);
		// [0]CS             (content [0] EXPLICIT ANY DEFINED BY contentType OPTIONAL).
		SkipBlockStart(DataAnalysis, 2, 0);
			// SEQUENCE (content SignedData).
			SkipBlockStart(DataAnalysis, 0, 16);
				// INTEGER  (version          Version).
				SkipBlock(DataAnalysis, 0, 2);
				// SET      (digestAlgorithms DigestAlgorithmIdentifiers).
				SkipBlock(DataAnalysis, 0, 17);
				// SEQUENCE (contentInfo      ContentInfo).
				SkipBlockStart(DataAnalysis, 0, 16);
					// OBJECT IDENTIFIER (contentType).
					SkipBlockStart(DataAnalysis, 0, 6);
					
					DataSize = DataAnalysis.Parents[0].DataSize;
					Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize);
					BufferString = GetHexStringFromBinaryDataBuffer(Buffer);
					If BufferString = "2A864886F70D0109100104" Then //1.2.840.113549.1.9.16.1.4 tSTInfo
						SkipTheParentBlock(DataAnalysis);
						SkipBlockStart(DataAnalysis, 2, 0); // [0]
						DataSize = DataAnalysis.Parents[0].DataSize;
						Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
						DateOfTimeStamp = ReadDateFromTimeStamp(Buffer);
						If ValueIsFilled(DateOfTimeStamp) Then
							SignatureProperties.DateOfTimeStamp = DateOfTimeStamp + ?(ValueIsFilled(UTCOffset),
								UTCOffset, 0);
						EndIf;
						SkipTheParentBlock(DataAnalysis); // [0]
					Else
						SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER (contentType).
					EndIf;

				SkipTheParentBlock(DataAnalysis); // SEQUENCE (contentInfo      ContentInfo).
				// [0]CS    (certificates [0] IMPLICIT CertificateSet OPTIONAL).
				If ShouldReadCertificates = False Then
					SkipBlock(DataAnalysis, 2, 0, False);
				Else
					If SkipBlockStart(DataAnalysis, 2, 0, False) Then
						// CertificateSet ::= SET OF Certificate Choices
						While True Do
							// Certificate
							Certificate = BlockRead(DataAnalysis, 0, 16);
							If Certificate = Undefined Then
								Break;
							EndIf;
							SignatureProperties.Certificates.Add(Certificate);
						EndDo;
						SkipTheParentBlock(DataAnalysis);
					EndIf;
				EndIf;
				// [1]CS    (crls             [1] IMPLICIT CertificateRevocationLists OPTIONAL).
				SkipBlock(DataAnalysis, 2, 1, False);
				// SET      (signerInfos      SET OF SignerInfo).
				SkipBlockStart(DataAnalysis, 0, 17);
					// SEQUENCE (signerInfo SignerInfo).
					SkipBlockStart(DataAnalysis, 0, 16);
						// INTEGER  (version                   Version).
						SkipBlock(DataAnalysis, 0, 2);
						// SEQUENCE (issuerAndSerialNumber     IssuerAndSerialNumber).
						SkipBlockStart(DataAnalysis, 0, 16);
							// SEQUENCE (issuerAndSerialNumber     issuer rdnSequence).
							SkipBlock(DataAnalysis, 0, 16);
							// INTEGER (serialNumber CertificateSerialNumber).
							SkipBlockStart(DataAnalysis, 0, 2);
							DataSize = DataAnalysis.Parents[0].DataSize;
							Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize);
							SignatureCertificateSerialNumber = GetBinaryDataFromBinaryDataBuffer(Buffer);
							SkipTheParentBlock(DataAnalysis); // INTEGER
							SkipTheParentBlock(DataAnalysis); // SEQUENCE
						// SEQUENCE (digestAlgorithm           DigestAlgorithmIdentifier).
						SkipBlock(DataAnalysis, 0, 16);
						// [0]CS    (authenticatedAttributes   [0] IMPLICIT Attributes OPTIONAL).
						SkipBlockStart(DataAnalysis, 2, 0);
	
	For Each Certificate In SignatureProperties.Certificates Do
		CryptoCertificate = New CryptoCertificate(Certificate);
		If CryptoCertificate.SerialNumber = SignatureCertificateSerialNumber Then
			SignatureProperties.SignatureCertificate = Certificate;
			Break;
		EndIf;
	EndDo;
	
	If DataAnalysis.HasError Then
		Return SignatureProperties;
	EndIf;
	
	ThereIsMessageDigest = False; // 1.2.840.113549.1.9.4
	ThereIsContentType = False; // 1.2.840.113549.1.9.3
	ThereIsCertificateBranch = False; // 1.2.840.113549.1.9.16.2.47 or 1.2.840.113549.1.9.16.2.12
	
	OffsetOfTheFollowing = DataAnalysis.Parents[0].OffsetOfTheFollowing;
	While DataAnalysis.Offset < OffsetOfTheFollowing And Not DataAnalysis.HasError Do
		
		// SEQUENCE (Attributes).
		SkipBlockStart(DataAnalysis, 0, 16);
		
		If DataAnalysis.HasError Then
			Break;
		EndIf; 
		
		// OBJECT IDENTIFIER
		SkipBlockStart(DataAnalysis, 0, 6);
		
		DataSize = DataAnalysis.Parents[0].DataSize;
		If DataSize = 0 Then
			WhenADataStructureErrorOccurs(DataAnalysis);
			Break;
		EndIf;
				
		If DataSize = 9 Then
			Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
			BufferString = GetHexStringFromBinaryDataBuffer(Buffer);

			If BufferString = "2A864886F70D010904" Then // 1.2.840.113549.1.9.4 messageDigest
				ThereIsMessageDigest = True;
			ElsIf BufferString = "2A864886F70D010903" Then // 1.2.840.113549.1.9.3 contentType
				ThereIsContentType = True;
			ElsIf BufferString = "2A864886F70D010905" Then // 1.2.840.113549.1.9.5 signingTime
				
				SigningDate = ReadDateFromClipboard(DataAnalysis.Buffer, DataAnalysis.Offset + 11);
				
				If ValueIsFilled(SigningDate) Then
					SignatureProperties.SigningDate = SigningDate + ?(ValueIsFilled(UTCOffset),
						UTCOffset, 0);
				EndIf;
				
			EndIf;
		
		ElsIf DataSize = 11 Then
			Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
			BufferString = GetHexStringFromBinaryDataBuffer(Buffer);
			
			If BufferString = "2A864886F70D010910022F" Then // 1.2.840.113549.1.9.16.2.47 signingCertificateV2
				ThereIsCertificateBranch = True;
			ElsIf BufferString = "2A864886F70D010910020C" Then // 1.2.840.113549.1.9.16.2.12 signingCertificate
				ThereIsCertificateBranch = True;
			EndIf;
		EndIf;
		
		SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER
		SkipTheParentBlock(DataAnalysis); // SEQUENCE
	EndDo;
	
	If ThereIsCertificateBranch And ThereIsMessageDigest And ThereIsContentType Then
		SignatureProperties.SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES");
	Else
		Return SignatureProperties;
	EndIf;
	
	SkipTheParentBlock(DataAnalysis); // [0]CS
	
	// SEQUENCE (digestEncryptionAlgorithm AlgorithmIdentifier).
	SkipBlock(DataAnalysis, 0, 16);
	// signature SignatureValue
	SkipBlock(DataAnalysis, 0, 4); 
	// [1]CS    (unsignedAttrs [1] IMPLICIT UnsignedAttributes OPTIONAL).
	SkipBlockStart(DataAnalysis, 2, 1);

	ThereIsTimestampBranch = False; // 1.2.840.113549.1.9.16.2.14 
	ThereIsBranchDescriptionOfCertificates = False; // 1.2.840.113549.1.9.16.2.21
	ThereIsBranchDescriptionOfReview = False; // 1.2.840.113549.1.9.16.2.22
	ThereIsBranchValueOfCertificates = False; // 1.2.840.113549.1.9.16.2.23
	ThereIsBranchReviewValue = False; // 1.2.840.113549.1.9.16.2.24
	ThereIsBranchListOfReviewServers = False; // 1.2.840.113549.1.9.16.2.26
	ThereIsArchiveBranch = False; // 0.4.0.1733.2.5
	
	OffsetOfTheFollowing = DataAnalysis.Parents[0].OffsetOfTheFollowing;
	While DataAnalysis.Offset < OffsetOfTheFollowing And Not DataAnalysis.HasError Do
		
		// SEQUENCE (Attributes).
		SkipBlockStart(DataAnalysis, 0, 16);

		If DataAnalysis.HasError Then
			Break;
		EndIf; 
		
		// OBJECT IDENTIFIER
		SkipBlockStart(DataAnalysis, 0, 6);

		DataSize = DataAnalysis.Parents[0].DataSize;
		If DataSize = 0 Then
			WhenADataStructureErrorOccurs(DataAnalysis);
			Break;
		EndIf;
		
		IsBlockSkipped = False;
		
		If DataSize = 11 Then
			
			Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
			BufferString = GetHexStringFromBinaryDataBuffer(Buffer);
			If BufferString = "2A864886F70D010910020E" Then // 1.2.840.113549.1.9.16.2.14 timeStampToken
				
				ThereIsTimestampBranch = True;
				SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER
				IsBlockSkipped = True;
				SkipBlockStart(DataAnalysis, 0, 17); // SET
			
				DataSize = DataAnalysis.Parents[0].DataSize;
				Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
				SignatureData = GetBinaryDataFromBinaryDataBuffer(Buffer);
				
				SignaturePropertiesFromBinaryData = SignaturePropertiesFromBinaryData(SignatureData, UTCOffset, False);
				SignatureProperties.DateOfTimeStamp = SignaturePropertiesFromBinaryData.DateOfTimeStamp;
				
				SkipTheParentBlock(DataAnalysis); // SET
				
			ElsIf BufferString = "2A864886F70D0109100215" Then // 1.2.840.113549.1.9.16.2.21 certificateRefs
				ThereIsBranchDescriptionOfCertificates = True;
			ElsIf BufferString = "2A864886F70D0109100216" Then // 1.2.840.113549.1.9.16.2.22 revocationRefs
				ThereIsBranchDescriptionOfReview = True;
			ElsIf BufferString = "2A864886F70D0109100217" Then // 1.2.840.113549.1.9.16.2.23 certValues
				ThereIsBranchValueOfCertificates = True;
			ElsIf BufferString = "2A864886F70D0109100218" Then // 1.2.840.113549.1.9.16.2.24 revocationValues
				ThereIsBranchReviewValue = True;
			ElsIf BufferString = "2A864886F70D010910021A" Then // 1.2.840.113549.1.9.16.2.26 certCRLTimestamp
				ThereIsBranchListOfReviewServers = True;
			EndIf;
			
		EndIf;

		If DataSize = 6 Then
			Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
			BufferString = GetHexStringFromBinaryDataBuffer(Buffer);
			If BufferString = "04008D450204" Then // 0.4.0.1733.2.4 archiveTimestampV3 attribute
				ThereIsArchiveBranch = True;
				If Not ValueIsFilled(SignatureProperties.DateOfTimeStamp) Then
					SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER
					IsBlockSkipped = True;
						SkipBlockStart(DataAnalysis, 0, 17); // SET
						DataSize = DataAnalysis.Parents[0].DataSize;
							Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
							SignatureData = GetBinaryDataFromBinaryDataBuffer(Buffer);
							SignaturePropertiesFromBinaryData = SignaturePropertiesFromBinaryData(SignatureData, UTCOffset, False);
							SignatureProperties.DateOfTimeStamp = SignaturePropertiesFromBinaryData.DateOfTimeStamp;
						SkipTheParentBlock(DataAnalysis); // SET
	
				EndIf;
			EndIf;
		EndIf;
		If Not IsBlockSkipped Then
			SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER
		EndIf;
		SkipTheParentBlock(DataAnalysis); // SEQUENCE
	EndDo;

	SignatureType = Undefined;
	If ThereIsArchiveBranch Then
		SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.ArchivalCAdESAv3");
	ElsIf ThereIsTimestampBranch And ThereIsBranchDescriptionOfCertificates And ThereIsBranchDescriptionOfReview
		And ThereIsBranchValueOfCertificates And ThereIsBranchReviewValue And ThereIsBranchListOfReviewServers Then
		SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.ExtendedLongCAdESXLongType2");
	ElsIf ThereIsTimestampBranch And ThereIsBranchDescriptionOfCertificates And ThereIsBranchDescriptionOfReview Then
		SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.WithCompleteValidationDataReferencesCAdESC");
	ElsIf ThereIsTimestampBranch Then
		SignatureType = PredefinedValue("Enum.CryptographySignatureTypes.WithTimeCAdEST");
	EndIf;

	If ValueIsFilled(SignatureType) Then
		SignatureProperties.SignatureType = SignatureType;
	EndIf;
	
	Return SignatureProperties;
	
EndFunction

Function ReadDateFromClipboard(Buffer, Offset)
	
	Date_Type = GetHexStringFromBinaryDataBuffer(Buffer.Read(Offset, 2));
	If Date_Type = "170D" Then // UTCTime
		DateBuffer = Buffer.Read(Offset + 2, 12);
		DatePresentation = "20" + GetStringFromBinaryDataBuffer(DateBuffer);
	Else // GeneralizedTime
		DateBuffer = Buffer.Read(Offset + 2, 14);
		DatePresentation = GetStringFromBinaryDataBuffer(DateBuffer);
	EndIf;

	TypeDetails = New TypeDescription("Date");
	SigningDate = TypeDetails.AdjustValue(DatePresentation);
	Return SigningDate;
	
EndFunction

// Intended for the SignaturePropertiesFromBinaryData function.
Function ReadDateFromTimeStamp(Buffer)
	
	DataAnalysis = New Structure;
	DataAnalysis.Insert("HasError", False);
	DataAnalysis.Insert("ThisIsAnASN1EncodingError", False); // Data might be corrupted.
	DataAnalysis.Insert("ThisIsADataStructureError", False); // An expected data item is not found.
	DataAnalysis.Insert("Offset", 0);
	DataAnalysis.Insert("Parents", New Array);
	DataAnalysis.Insert("Buffer", Buffer);
	
	// OCTET STRING
	SkipBlockStart(DataAnalysis, 0, 4);
	// SEQUENCE
	SkipBlockStart(DataAnalysis, 0, 16);
	// INTEGER
	SkipBlock(DataAnalysis, 0, 2);
	// OBJECT IDENTIFIER
	SkipBlock(DataAnalysis, 0, 6);
	// SEQUENCE
	SkipBlock(DataAnalysis, 0, 16);
	// INTEGER
	SkipBlock(DataAnalysis, 0, 2);

	If DataAnalysis.HasError Then
		StampDate = Undefined;
	Else
		// GeneralizedTime
		DateBuffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset + 2, 14);
		DatePresentation = GetStringFromBinaryDataBuffer(DateBuffer);
		TypeDetails = New TypeDescription("Date");
		StampDate = TypeDetails.AdjustValue(DatePresentation);
	EndIf;
	
	Return StampDate;
	
EndFunction

// Finds the tag content in XML.
//
// Parameters:
//  Text                             - String - a searched XML text.
//  NameTag                           - String - a tag whose content is to be found.
//  IncludeStartEndTag - Boolean - flag shows whether the items found by the tag are required. 
//                                               This tag was used for the search, the default value is False.
//  SerialNumber                    - Number  - a position, from which the search starts, the default value is 1.
// 
// Returns:
//   String - String with removed new line characters and a carriage return.
//
Function FindInXML(Text, NameTag, IncludeStartEndTag = False, SerialNumber = 1) Export
	
	Result = Undefined;
	
	Begin    = "<"  + NameTag;
	Ending = "</" + NameTag + ">";
	
	Content = Mid(
		Text,
		StrFind(Text, Begin, SearchDirection.FromBegin, 1, SerialNumber),
		StrFind(Text, Ending, SearchDirection.FromBegin, 1, SerialNumber) + StrLen(Ending) - StrFind(Text, Begin, SearchDirection.FromBegin, 1, SerialNumber));
		
	If IncludeStartEndTag Then
		
		Result = TrimAll(Content);
		
	Else
		
		StartTag = Left(Content, StrFind(Content, ">"));
		Content = StrReplace(Content, StartTag, "");
		
		EndTag1 = Right(Content, StrLen(Content) - StrFind(Content, "<", SearchDirection.FromEnd) + 1);
		Content = StrReplace(Content, EndTag1, "");
		
		Result = TrimAll(Content);
		
	EndIf;
	
	Return Result;
	
EndFunction

// For internal use only.
Function CertificateFromSOAPEnvelope(SOAPEnvelope, AsBase64 = True) Export
	
	Base64Certificate = FindInXML(SOAPEnvelope, "wsse:BinarySecurityToken");
	
	If AsBase64 Then
		Return Base64Certificate;
	EndIf;
	
	Return Base64Value(Base64Certificate);
	
EndFunction

// See DigitalSignatureClient.CertificatePresentation.
Function CertificatePresentation(Certificate, UTCOffset = Undefined) Export
	
	Presentation = "";
	DigitalSignatureClientServerLocalization.OnGetCertificatePresentation(Certificate, UTCOffset, Presentation);
	
	If IsBlankString(Presentation) Then
		If TypeOf(Certificate) = Type("Structure") Then
			Return StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1, đến %2';
																				|ru = '%1, до %2';
																				|en = '%1, to %2'; fa = '%1, to %2';
																				|it = '%1, fino a %2';
																				|pl = '%1, do %2';
																				|tr = '%1, %2''a kadar'"),
				SubjectPresentation(Certificate.Certificate),
				Format(Certificate.ValidBefore, "DF=MM.yyyy"));
		Else
			CertificateDates = CertificateDates(Certificate, UTCOffset);
			Return StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1, đến %2';
																				|ru = '%1, до %2';
																				|en = '%1, to %2'; fa = '%1, to %2';
																				|it = '%1, fino a %2';
																				|pl = '%1, do %2';
																				|tr = '%1, %2''a kadar'"),
				SubjectPresentation(Certificate),
				Format(CertificateDates.ValidBefore, "DF=MM.yyyy"));
		EndIf;
	EndIf;
	
	Return Presentation;
	
EndFunction

// See DigitalSignatureClient.SubjectPresentation.
Function SubjectPresentation(Certificate) Export 
	
	Presentation = "";
	DigitalSignatureClientServerLocalization.OnGetSubjectPresentation(Certificate, Presentation);
	
	If IsBlankString(Presentation) Then
		
		Subject = CertificateSubjectProperties(Certificate);
		
		If ValueIsFilled(Subject.LastName) And ValueIsFilled(Subject.Name) Then
			Presentation = Subject.LastName + " " + Subject.Name;
		ElsIf ValueIsFilled(Subject.LastName) Then
			Presentation = Subject.LastName;
		ElsIf ValueIsFilled(Subject.Name) Then
			Presentation = Subject.Name;
		EndIf;

		If ValueIsFilled(Presentation) Then
			If ValueIsFilled(Subject.Organization) Then
				Presentation = Presentation + ", " + Subject.Organization;
			EndIf;
			If ValueIsFilled(Subject.Department) Then
				Presentation = Presentation + ", " + Subject.Department;
			EndIf;
		ElsIf ValueIsFilled(Subject.CommonName) Then
			Presentation = Subject.CommonName;
		EndIf;

	EndIf;

	Return Presentation;
	
EndFunction

// See DigitalSignatureClient.IssuerPresentation.
Function IssuerPresentation(Certificate) Export
	
	Issuer = CertificateIssuerProperties(Certificate);
	
	Presentation = "";
	
	If ValueIsFilled(Issuer.CommonName) Then
		Presentation = Issuer.CommonName;
	EndIf;
	
	If ValueIsFilled(Issuer.CommonName)
	   And ValueIsFilled(Issuer.Organization)
	   And StrFind(Issuer.CommonName, Issuer.Organization) = 0 Then
		
		Presentation = Issuer.CommonName + ", " + Issuer.Organization;
	EndIf;
	
	If ValueIsFilled(Issuer.Department) Then
		Presentation = Presentation + ", " + Issuer.Department;
	EndIf;
	
	Return Presentation;
	
EndFunction

// Certificate properties.
// 
// Parameters:
//  Certificate - CryptoCertificate - Alternatively, the structure may repeat the property structure of the cryptography certificate.
//  UTCOffset - Number
//  CertificateBinaryData - BinaryData
// 
// Returns:
//  Structure:
// * Thumbprint - String 
// * SerialNumber - BinaryData
// * IssuedTo - String
// * IssuedBy - String 
// * Signing - Boolean
// * Encryption - Boolean
// * StartDate - Date
// * EndDate - Date
// * PrivateKeyStartDate - Date
// * PrivateKeyExpirationDate - Date 
// * ValidBefore - Date 
// * CertificateAuthorityKeyID - String
// * ContainsEmbeddedLicenseCryptoPro - Boolean
// * SignAlgorithm - String
// * PublicKeyAlgorithm - String 
// * AddressesOfRevocationLists - Array 
// * Purpose - String
// * Presentation - String
// 
Function CertificateProperties(Certificate, UTCOffset, CertificateBinaryData = Undefined) Export
	
	Properties = New Structure;
	Properties.Insert("Thumbprint",      Base64String(Certificate.Thumbprint));
	Properties.Insert("SerialNumber",  Certificate.SerialNumber);
	Properties.Insert("IssuedTo",      SubjectPresentation(Certificate));
	Properties.Insert("IssuedBy",       IssuerPresentation(Certificate));
	Properties.Insert("Signing",     Certificate.UseToSign);
	Properties.Insert("Encryption",     Certificate.UseToEncrypt);
	
	CertificateDates = CertificateDates(Certificate, UTCOffset);
	Properties.Insert("StartDate",     CertificateDates.StartDate);
	Properties.Insert("EndDate",  CertificateDates.EndDate);
	Properties.Insert("PrivateKeyStartDate", CertificateDates.PrivateKeyStartDate);
	Properties.Insert("PrivateKeyExpirationDate", CertificateDates.PrivateKeyExpirationDate);
	Properties.Insert("ValidBefore", CertificateDates.ValidBefore);
	
	Properties.Insert("CertificateAuthorityKeyID", "");
	Properties.Insert("ContainsEmbeddedLicenseCryptoPro", False);
	Properties.Insert("SignAlgorithm", "");
	Properties.Insert("PublicKeyAlgorithm", "");
	Properties.Insert("AddressesOfRevocationLists", New Array);
	
	If TypeOf(Certificate) = Type("CryptoCertificate") And AreCertificateAdditionalPropertiesAvailable() Then
		
		Properties.Insert("Purpose", GetCryptoCertificatePurpose(Certificate));
		Properties.PublicKeyAlgorithm = Certificate.PublicKeyAlgorithm;
		Properties.SignAlgorithm = Certificate.SignatureAlgorithm;
		
		CertificationAuthorityKeyData = Certificate.CertificateExtensionsAsRawData.Get("2.5.29.35");
		If CertificationAuthorityKeyData <> Undefined Then
			Properties.CertificateAuthorityKeyID = CertificateAuthorityKeyID(CertificationAuthorityKeyData);
		EndIf;
		
		Properties.ContainsEmbeddedLicenseCryptoPro = Certificate.CertificateExtensions.Get("1.2.643.2.2.49.2") <> Undefined;
		
		AddressesOfRevocationLists = Certificate.CertificateExtensions.Get("2.5.29.31");
		If AddressesOfRevocationLists <> Undefined Then
			Properties.AddressesOfRevocationLists = AddressesOfRevocationLists;
		EndIf;
			
	ElsIf CertificateBinaryData <> Undefined Then
		
		CertificateAdditionalProperties = CertificateAdditionalProperties(CertificateBinaryData, UTCOffset);
		
		If ValueIsFilled(CertificateAdditionalProperties.PrivateKeyExpirationDate) Then
			Properties.ValidBefore = Min(CertificateDates.EndDate, CertificateAdditionalProperties.PrivateKeyExpirationDate);
		EndIf;
		
		Properties.Insert("PrivateKeyStartDate",    CertificateAdditionalProperties.PrivateKeyStartDate);
		Properties.Insert("PrivateKeyExpirationDate", CertificateAdditionalProperties.PrivateKeyExpirationDate);
		Properties.Insert("Purpose", GetPurpose(Certificate));
	Else
		Properties.Insert("Purpose", GetPurpose(Certificate));
	EndIf;
	
	Properties.Insert("Presentation",  CertificatePresentation(
			New Structure("Certificate, ValidBefore", Certificate, Properties.ValidBefore)));
	
	Return Properties;
	
EndFunction

Function AreCertificateAdditionalPropertiesAvailable() Export
#If MobileClient Then
		Return False;
#EndIf
	SystemInfo = New SystemInfo();
	Version = CommonClientServer.ConfigurationVersionWithoutBuildNumber(SystemInfo.AppVersion);
	Return CommonClientServer.CompareVersionsWithoutBuildNumber(Version, "8.3.27") >= 0;
	
EndFunction

// Fills in the table of certificate description from four fields: IssuedTo, IssuedBy, ValidTo, Purpose.
Procedure FillCertificateDataDetails(Table, CertificateProperties) Export
	
	If CertificateProperties.Signing And CertificateProperties.Encryption Then
		Purpose = NStr("vi = 'Ký dữ liệu, Mã hóa dữ liệu';
						|ru = 'Подписание данных, Шифрование данных';
						|en = 'Data signing, Data encryption'; fa = 'Data signing, Data encryption';
						|it = 'Firma dei dati, crittografia dei dati';
						|pl = 'Podpisywanie danych, szyfrowanie danych';
						|tr = 'Verilerin imzalanması, Verilerin şifrelemesi'");
		
	ElsIf CertificateProperties.Signing Then
		Purpose = NStr("vi = 'Ký dữ liệu';
						|ru = 'Подписание данных';
						|en = 'Data signing'; fa = 'امضای داده‌ها';
						|it = 'Firma dati';
						|pl = 'Podpisanie danych';
						|tr = 'Verilerin imzalanması'");
	Else
		Purpose = NStr("vi = 'Mã hóa dữ liệu';
						|ru = 'Шифрование данных';
						|en = 'Data encryption'; fa = 'رمزگذاری داده‌ها';
						|it = 'Crittografia dei dati';
						|pl = 'Szyfrowanie danych';
						|tr = 'Veri şifrelemesi'");
	EndIf;
	
	Table.Clear();
	String = Table.Add();
	String.Property = NStr("vi = 'Người nhận:';
							|ru = 'Кому выдан:';
							|en = 'Owner:'; fa = 'Owner:';
							|it = 'Rilasciato a:';
							|pl = 'Wydano dla:';
							|tr = 'Kime verildi:'");
	String.Value = TrimAll(CertificateProperties.IssuedTo);
	
	String = Table.Add();
	String.Property = NStr("vi = 'Nơi cấp:';
							|ru = 'Кем выдан:';
							|en = 'Issued by:'; fa = 'Issued by:';
							|it = 'Rilasciato da:';
							|pl = 'Wydany przez:';
							|tr = 'Düzenleyen:'");
	String.Value = TrimAll(CertificateProperties.IssuedBy);
	
	String = Table.Add();
	String.Property = NStr("vi = 'Hiệu lực đến:';
							|ru = 'Действителен до:';
							|en = 'Expiration date:'; fa = 'Expiration date:';
							|it = 'Valido fino a:';
							|pl = 'Ważny do:';
							|tr = 'Şu tarihe kadar geçerlidir:'");
	If TypeOf(CertificateProperties) <> Type("Structure") Or CertificateProperties.ValidBefore = CertificateProperties.EndDate Then
		String.Value = Format(CertificateProperties.ValidBefore, "DLF=D");
	Else
		String.Value = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (thời hạn hiệu lực của khóa riêng)';
				|ru = '%1 (срок действия закрытого ключа)';
				|en = '%1 (private key validity period)'; fa = '%1 (private key validity period)';
				|it = '%1 (срок действия закрытого ключа)';
				|pl = '%1 (private key validity period)';
				|tr = '%1 (özel anahtarın geçerlilik süresi)'"), Format(CertificateProperties.ValidBefore, "DLF=D"));
	EndIf;
	
	String = Table.Add();
	String.Property = NStr("vi = 'Mục đích:';
							|ru = 'Назначение:';
							|en = 'Purpose:'; fa = 'Purpose:';
							|it = 'Assegnazione:';
							|pl = 'Purpose:';
							|tr = 'Atama:'");
	String.Value = Purpose;
	
EndProcedure

Function CertificateSubjectProperties(Certificate) Export
	
	Subject = Certificate.Subject;
	
	Properties = New Structure;
	Properties.Insert("CommonName");
	Properties.Insert("Country");
	Properties.Insert("State");
	Properties.Insert("Locality");
	Properties.Insert("Street");
	Properties.Insert("Organization");
	Properties.Insert("Department");
	Properties.Insert("Email");
	Properties.Insert("LastName");
	Properties.Insert("Name");
	
	If Subject.Property("CN") Then
		Properties.CommonName = PrepareRow(Subject.CN);
	EndIf;
	
	If Subject.Property("C") Then
		Properties.Country = PrepareRow(Subject.C);
	EndIf;
	
	If Subject.Property("ST") Then
		Properties.State = PrepareRow(Subject.ST);
	EndIf;
	
	If Subject.Property("L") Then
		Properties.Locality = PrepareRow(Subject.L);
	EndIf;
	
	If Subject.Property("Street") Then
		Properties.Street = PrepareRow(Subject.Street);
	EndIf;
	
	If Subject.Property("O") Then
		Properties.Organization = PrepareRow(Subject.O);
	EndIf;
	
	If Subject.Property("OU") Then
		Properties.Department = PrepareRow(Subject.OU);
	EndIf;
	
	If Subject.Property("E") Then
		Properties.Email = PrepareRow(Subject.E);
	EndIf;
	
	Extensions = Undefined;
	DigitalSignatureClientServerLocalization.OnGetExtendedCertificateSubjectProperties(Subject, Extensions);
	If TypeOf(Extensions) = Type("Structure") Then
		CommonClientServer.SupplementStructure(Properties, Extensions, True);
	EndIf;
	
	If Not ValueIsFilled(Properties.LastName) And Subject.Property("SN") Then
		Properties.LastName = PrepareRow(Subject.SN);
	EndIf;
	
	If Not ValueIsFilled(Properties.Name) And Subject.Property("GN") Then
		Properties.Name = PrepareRow(Subject.GN);
	EndIf;
	
	Return Properties;
	
EndFunction

// See DigitalSignatureClient.CertificateIssuerProperties.
Function CertificateIssuerProperties(Certificate) Export
	
	Issuer = Certificate.Issuer;
	
	Properties = New Structure;
	Properties.Insert("CommonName");
	Properties.Insert("Country");
	Properties.Insert("State");
	Properties.Insert("Locality");
	Properties.Insert("Street");
	Properties.Insert("Organization");
	Properties.Insert("Department");
	Properties.Insert("Email");
	
	If Issuer.Property("CN") Then
		Properties.CommonName = PrepareRow(Issuer.CN);
	EndIf;
	
	If Issuer.Property("C") Then
		Properties.Country = PrepareRow(Issuer.C);
	EndIf;
	
	If Issuer.Property("ST") Then
		Properties.State = PrepareRow(Issuer.ST);
	EndIf;
	
	If Issuer.Property("L") Then
		Properties.Locality = PrepareRow(Issuer.L);
	EndIf;
	
	If Issuer.Property("Street") Then
		Properties.Street = PrepareRow(Issuer.Street);
	EndIf;
	
	If Issuer.Property("O") Then
		Properties.Organization = PrepareRow(Issuer.O);
	EndIf;
	
	If Issuer.Property("OU") Then
		Properties.Department = PrepareRow(Issuer.OU);
	EndIf;
	
	If Issuer.Property("E") Then
		Properties.Email = PrepareRow(Issuer.E);
	EndIf;
	
	Extensions = Undefined;
	DigitalSignatureClientServerLocalization.OnGetExtendedCertificateIssuerProperties(Issuer, Extensions);
	If TypeOf(Extensions) = Type("Structure") Then
		CommonClientServer.SupplementStructure(Properties, Extensions, True);
	EndIf;
	
	Return Properties;
	
EndFunction

// Removes all the data except for the name from the IssuedTo field
// 
// Parameters:
//   IssuedTo - Array of String
//             - String
//            
// Returns:
//   - Array of String - If IssuedTo is Array 
//   - String - If IssuedTo is Array
//
Function ConvertIssuedToIntoFullName(IssuedTo) Export
	
	If TypeOf(IssuedTo) = Type("Array") Then
		For Each ItemIssuedTo In IssuedTo Do
			StringLength = StrFind(ItemIssuedTo, ",");
			ItemIssuedTo = TrimAll(?(StringLength = 0, ItemIssuedTo, Left(ItemIssuedTo, StringLength - 1)));
		EndDo; 
	Else	
		StringLength = StrFind(IssuedTo, ",");
		IssuedTo = TrimAll(?(StringLength = 0, IssuedTo, Left(IssuedTo, StringLength - 1)));
	EndIf;
	
	Return IssuedTo;
	
EndFunction


Function IdentifiersOfHashingAlgorithmsAndThePublicKey() Export
	
	IDs = New Array;
	
	Sets = SetsOfAlgorithmsForCreatingASignature();
	For Each Set In Sets Do
		IDs.Add("<" + Set.IDOfThePublicKeyAlgorithm + "> <" + Set.IdOfTheHashingAlgorithm + ">");
	EndDo;
	
	Return StrConcat(IDs, Chars.LF) + Chars.LF;
	
EndFunction

// See DigitalSignatureClient.XMLEnvelope.
Function XMLEnvelope(Parameters) Export
	
	If Parameters = Undefined Then
		Parameters = XMLEnvelopeParameters();
	EndIf;
	
	XMLEnvelope = Undefined;
	DigitalSignatureClientServerLocalization.OnReceivingXMLEnvelope(Parameters, XMLEnvelope);
	
	If XMLEnvelope = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã chỉ ra giá trị không xác định ""%1"" của tham số %2 trong hàm %3';
					|ru = 'Указано неизвестное значение ""%1"" параметра %2 в функции %3';
					|en = 'The %1 unknown value of the %2 parameter is specified in the %3 function'; fa = 'The %1 unknown value of the %2 parameter is specified in the %3 function';
					|it = 'Valore sconosciuto ""%1"" del parametro %2 nella funzione %3';
					|pl = 'Jest podana nieznana wartość ""%1"" parametru %2 w funkcji %3';
					|tr = '%3 işlevinde %2 parametresinin bilinmeyen ""%1"" değeri gösterilmiştir'"),
				Parameters.Variant, "Variant", "XMLEnvelope");
		Raise ErrorText;
	EndIf;
	
	If ValueIsFilled(Parameters.XMLMessage) Then
		XMLEnvelope = StrReplace(XMLEnvelope, "%MessageXML%", TrimAll(Parameters.XMLMessage));
	EndIf;
	
	Return XMLEnvelope;
	
EndFunction

// See DigitalSignatureClient.XMLEnvelopeParameters.
Function XMLEnvelopeParameters() Export
	
	Result = New Structure;
	
	EnvelopVariant = "";
	DigitalSignatureClientServerLocalization.OnGetDefaultEnvelopeVariant(EnvelopVariant);
	
	Result.Insert("Variant", EnvelopVariant);
	Result.Insert("XMLMessage", "");
	
	Return Result;
	
EndFunction

// See DigitalSignatureClient.XMLDSigParameters.
Function XMLDSigParameters() Export
	
	SigningAlgorithmData = New Structure;
	
	SigningAlgorithmData.Insert("XPathSignedInfo",       "");
	SigningAlgorithmData.Insert("XPathTagToSign", "");
	
	SigningAlgorithmData.Insert("OIDOfPublicKeyAlgorithm", "");
	
	SigningAlgorithmData.Insert("SIgnatureAlgorithmName", "");
	SigningAlgorithmData.Insert("SignatureAlgorithmOID", "");
	
	SigningAlgorithmData.Insert("HashingAlgorithmName", "");
	SigningAlgorithmData.Insert("HashingAlgorithmOID", "");
	
	SigningAlgorithmData.Insert("SignAlgorithm",     "");
	SigningAlgorithmData.Insert("HashAlgorithm", "");
	
	Return SigningAlgorithmData;
	
EndFunction

Function XMLSignatureVerificationErrorText(SignatureCorrect, HashMaps) Export
	
	If SignatureCorrect Then
		ErrorText = NStr("vi = 'Chữ ký sai (%1 đúng, %2 sai).';
						|ru = 'Подпись неверна (%1 корректно, %2 некорректно).';
						|en = 'Invalid signature (%1 is valid, %2 is invalid).'; fa = 'Invalid signature (%1 is valid, %2 is invalid).';
						|it = 'Firma invalida (%1corretto, %2 errato).';
						|pl = 'Podpis jest niezgodny (%1 poprawnie, %2 niepoprawnie).';
						|tr = 'İmza geçersiz (%1 doğru, %2 yanlış).'");
	ElsIf HashMaps Then
		ErrorText = NStr("vi = 'Chữ ký sai (%1 sai, %2 đúng).';
						|ru = 'Подпись неверна (%1 некорректно, %2 корректно).';
						|en = 'Invalid signature (%1 is invalid, %2 is valid).'; fa = 'Invalid signature (%1 is invalid, %2 is valid).';
						|it = 'Firma invalida (%1 errato, %2corretto).';
						|pl = 'Podpis jest niezgodny (%1 niepoprawnie, %2 poprawnie).';
						|tr = 'İmza geçersiz (%1 yanlış, %2 doğru).'");
	Else
		ErrorText = NStr("vi = 'Chữ ký sai (%1 sai, %2 sai).';
						|ru = 'Подпись неверна (%1 некорректно, %2 некорректно).';
						|en = 'Invalid signature (%1 is invalid, %2 is invalid).'; fa = 'Invalid signature (%1 is invalid, %2 is invalid).';
						|it = 'Firma invalida (%1 errato, %2 errato).';
						|pl = 'Podpis jest niezgodny (%1 niepoprawnie, %2 niepoprawnie).';
						|tr = 'İmza geçersiz (%1 yanlış, %2 yanlış).'");
	EndIf;
	Return StringFunctionsClientServer.SubstituteParametersToString(ErrorText, "SignatureValue", "DigestValue");
	
EndFunction

// Returns:
//   See ANewSetOfAlgorithmsForCreatingASignature
//  Undefined - if a set is not found.
//
Function ASetOfAlgorithmsForCreatingASignature(IDOfThePublicKeyAlgorithm)
	
	Sets = SetsOfAlgorithmsForCreatingASignature();
	For Each Set In Sets Do
		If Set.IDOfThePublicKeyAlgorithm = IDOfThePublicKeyAlgorithm Then
			Return Set;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Converts the binary data of the crypto certificate into
// the correctly formatted string in the Base64 format.
//
// Parameters:
//  CertificateData - BinaryData - the binary data of the crypto certificate.
// 
// Returns:
//  String - the binary data of the certificate in the Base64 format.
//
Function Base64CryptoCertificate(CertificateData) Export
	
	Base64Row = Base64String(CertificateData);
	
	Value = StrReplace(Base64Row, Chars.CR, "");
	Value = StrReplace(Value, Chars.LF, "");
	
	Return Value;
	
EndFunction

// Parameters:
//  Base64CryptoCertificate - String - the Base64 string.
//  SigningAlgorithmData    - See DigitalSignatureClient.XMLDSigParameters
//  RaiseException1           - Boolean
//  XMLEnvelopeProperties          - See DigitalSignatureInternal.XMLEnvelopeProperties
//  
// Returns:
//   String - an error text, if it is filled in.
//
Function CheckChooseSignAlgorithm(Base64CryptoCertificate, SigningAlgorithmData,
			RaiseException1 = False, XMLEnvelopeProperties = Undefined) Export
	
	OIDOfPublicKeyAlgorithm = CertificateSignAlgorithm(
		Base64Value(Base64CryptoCertificate),, True);
	
	If Not ValueIsFilled(OIDOfPublicKeyAlgorithm) Then
		ErrorText = NStr("vi = 'Không thể nhận thuật toán khóa công khai từ chứng chỉ.';
						|ru = 'Не удалось получить алгоритм открытого ключа из сертификата.';
						|en = 'Cannot get a public key algorithm from the certificate.'; fa = 'Cannot get a public key algorithm from the certificate.';
						|it = 'Non è stato possibile ottenere l''algoritmo di chiave pubblica dal certificato.';
						|pl = 'Nie udało się otrzymać algorytmu otwartego klucza z certyfikatu.';
						|tr = 'Sertifikadan genel anahtar algoritması alınamadı.'");
		If RaiseException1 Then
			Raise ErrorText;
		EndIf;
		Return ErrorText;
	EndIf;
	
	SigningAlgorithmData.Insert("SelectedSignatureAlgorithmOID",     Undefined);
	SigningAlgorithmData.Insert("SelectedHashAlgorithmOID", Undefined);
	SigningAlgorithmData.Insert("SelectedSignatureAlgorithm",          Undefined);
	SigningAlgorithmData.Insert("SelectedHashAlgorithm",      Undefined);
	
	OIDOfPublicKeyAlgorithms = StrSplit(SigningAlgorithmData.OIDOfPublicKeyAlgorithm, Chars.LF);
	SignAlgorithmsOID        = StrSplit(SigningAlgorithmData.SignatureAlgorithmOID,        Chars.LF);
	HashAlgorithmsOID    = StrSplit(SigningAlgorithmData.HashingAlgorithmOID,    Chars.LF);
	SignAlgorithms            = StrSplit(SigningAlgorithmData.SignAlgorithm,            Chars.LF);
	HashAlgorithms        = StrSplit(SigningAlgorithmData.HashAlgorithm,        Chars.LF);
	
	TheAlgorithmsAreSpecified = False;
	For IndexOf = 0 To OIDOfPublicKeyAlgorithms.Count() - 1 Do
		
		If OIDOfPublicKeyAlgorithm = OIDOfPublicKeyAlgorithms[IndexOf] Then
			
			SigningAlgorithmData.SelectedSignatureAlgorithmOID     = SignAlgorithmsOID[IndexOf];
			SigningAlgorithmData.SelectedHashAlgorithmOID = HashAlgorithmsOID[IndexOf];
			SigningAlgorithmData.SelectedSignatureAlgorithm          = SignAlgorithms[IndexOf];
			SigningAlgorithmData.SelectedHashAlgorithm      = HashAlgorithms[IndexOf];
			
			TheAlgorithmsAreSpecified = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not TheAlgorithmsAreSpecified Then
		SetOfAlgorithms = ASetOfAlgorithmsForCreatingASignature(
			OIDOfPublicKeyAlgorithm);
		
		If SetOfAlgorithms <> Undefined Then
			SigningAlgorithmData.SelectedSignatureAlgorithmOID     = SetOfAlgorithms.IDOfTheSignatureAlgorithm;
			SigningAlgorithmData.SelectedHashAlgorithmOID = SetOfAlgorithms.IdOfTheHashingAlgorithm;
			SigningAlgorithmData.SelectedSignatureAlgorithm          = SetOfAlgorithms.NameOfTheXMLSignatureAlgorithm;
			SigningAlgorithmData.SelectedHashAlgorithm      = SetOfAlgorithms.NameOfTheXMLHashingAlgorithm;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(SigningAlgorithmData.SelectedSignatureAlgorithmOID)
	 Or Not ValueIsFilled(SigningAlgorithmData.SelectedHashAlgorithmOID)
	 Or Not ValueIsFilled(SigningAlgorithmData.SelectedSignatureAlgorithm)
	 Or Not ValueIsFilled(SigningAlgorithmData.SelectedHashAlgorithm) Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa chỉ ra thuật toán ký và hàm băm để tạo chữ ký,
			           |tương ứng với thuật toán khóa công khai của chứng chỉ (OID %1).';
			           |ru = 'Не указаны алгоритмы подписания и хеширования для создания подписи,
			           |соответствующие алгоритму открытого ключа сертификата (OID %1).';
			           |en = 'Signature and hash algorithms that match the certificate''s public key
			           |algorithm (OID %1) are not specified.'; fa = 'Signature and hash algorithms that match the certificate''s public key
			           |algorithm (OID %1) are not specified.';
			           |it = 'Mancano gli algoritmi di firma e hashing per la creazione della firma 
			           |corrispondenti all''algoritmo di chiave pubblica del certificato (OID %1).';
			           |pl = 'Nie wskazano algorytmów podpisania i haszowania w celu utworzenia podpisu,
			           |odpowiadajcego algorytmowi otwartego klucza certyfikatu (OID %1).';
			           |tr = 'Sertifikanın (OID %1) genel anahtar algoritmasına karşılık gelen imzanın
			           |oluşturulması için imzalama ve önbellekleme algoritmaları belirtilmemiş.'"),
			OIDOfPublicKeyAlgorithm);
		
		If RaiseException1 Then
			Raise ErrorText;
		EndIf;
		Return ErrorText;
	EndIf;
	
	If TheAlgorithmsAreSpecified
	 Or XMLEnvelopeProperties = Undefined
	 Or Not XMLEnvelopeProperties.CheckSignature Then
		Return "";
	EndIf;
	
	If XMLEnvelopeProperties.SignAlgorithm.Id
	     <> SigningAlgorithmData.SelectedSignatureAlgorithmOID Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong văn bản XML thuật toán chữ ký đã chỉ ra 
			           |""%1"" (OID ""%2"")
			           |không trùng với thuật toán chữ ký trong chứng thư OID ""%3"".';
			           |ru = 'В документе XML указанный алгоритм подписи
			           |""%1"" (OID ""%2"")
			           |не совпадает с алгоритмом подписи в сертификате OID ""%3"".';
			           |en = 'The %1 signature algorithm
			           |(%2 OID)
			           |specified in the XML document does not match the signature algorithm in the certificate (%3 OID).'; fa = 'The %1 signature algorithm
			           |(%2 OID)
			           |specified in the XML document does not match the signature algorithm in the certificate (%3 OID).';
			           |it = 'Nel documento XML l''algoritmo di firma indicato
			           |""%1"" (OID ""%2"")
			           |non corrisponde all''algoritmo di firma nel certificato OID ""%3"".';
			           |pl = 'W dokumencie XML podany algorytm podpisu
			           |""%1"" (OID ""%2"")
			           |nie jest zgodny z algorytmem podpisu w certyfikacie OID ""%3"".';
			           |tr = 'XML belgesinde belirtilen imza algoritması 
			           |""%1"" (OID ""%2"")
			           |OID ""%3"" sertifikasındaki imza algoritmasıyla eşleşmiyor.'"),
			XMLEnvelopeProperties.SignAlgorithm.Name,
			XMLEnvelopeProperties.SignAlgorithm.Id,
			SigningAlgorithmData.SelectedSignatureAlgorithmOID);
		
		If RaiseException1 Then
			Raise ErrorText;
		EndIf;
		Return ErrorText;
	EndIf;
	
	Return "";
	
EndFunction

// See DigitalSignatureClient.CMSParameters.
Function CMSParameters() Export
	
	Parameters = New Structure;
	
	Parameters.Insert("SignatureType",   "CAdES-BES");
	Parameters.Insert("DetachedAddIn", False);
	Parameters.Insert("IncludeCertificatesInSignature",
		CryptoCertificateIncludeMode.IncludeWholeChain);
	
	Return Parameters;
	
EndFunction

Function AddInParametersCMSSign(CMSParameters, DataDetails) Export
	
	AddInParameters = New Structure;
	
	If TypeOf(DataDetails) = Type("String")
	   And IsTempStorageURL(DataDetails) Then
	
		Data = GetFromTempStorage(DataDetails);
	Else
		Data = DataDetails;
	EndIf;
	
	If CMSParameters.SignatureType = "CAdES-BES" Then
		AddInParameters.Insert("SignatureType", 0);
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai tham số %1 phương thức %2 cấu phần %3.';
				|ru = 'Некорректный параметр %1 метода %2 компоненты %3.';
				|en = 'In add-in ""%3"", method ""%2"" has invalid parameter ""%1"".'; fa = 'In add-in ""%3"", method ""%2"" has invalid parameter ""%1"".';
				|it = 'Parametro errato %1 del metodo %2 della componente %3.';
				|pl = 'Niepoprawny parametr %1 metody %2 komponentu %3.';
				|tr = '%3 bileşen %2 metodunun hatalı %1 parametresi.'"),
			"SignatureType", "CMSSign", "ExtraCryptoAPI");
	EndIf;
	
	If TypeOf(Data) = Type("String")
	 Or TypeOf(Data) = Type("BinaryData") Then
		
		AddInParameters.Insert("Data", Data);
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai tham số %1 phương thức %2 cấu phần %3.';
				|ru = 'Некорректный параметр %1 метода %2 компоненты %3.';
				|en = 'In add-in ""%3"", method ""%2"" has invalid parameter ""%1"".'; fa = 'In add-in ""%3"", method ""%2"" has invalid parameter ""%1"".';
				|it = 'Parametro errato %1 del metodo %2 della componente %3.';
				|pl = 'Niepoprawny parametr %1 metody %2 komponentu %3.';
				|tr = '%3 bileşen %2 metodunun hatalı %1 parametresi.'"),
			"Data", "CMSSign", "ExtraCryptoAPI");
	EndIf;
	
	If TypeOf(CMSParameters.DetachedAddIn) = Type("Boolean") Then
		AddInParameters.Insert("DetachedAddIn", CMSParameters.DetachedAddIn);
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai tham số %1 phương thức %2 cấu phần %3.';
				|ru = 'Некорректный параметр %1 метода %2 компоненты %3.';
				|en = 'In add-in ""%3"", method ""%2"" has invalid parameter ""%1"".'; fa = 'In add-in ""%3"", method ""%2"" has invalid parameter ""%1"".';
				|it = 'Parametro errato %1 del metodo %2 della componente %3.';
				|pl = 'Niepoprawny parametr %1 metody %2 komponentu %3.';
				|tr = '%3 bileşen %2 metodunun hatalı %1 parametresi.'"),
			"DetachedAddIn", "CMSSign", "ExtraCryptoAPI");
	EndIf;
	
	//  0 - CryptoCertificateIncludeMode.DontInclude.
	//  1 - CryptoCertificateIncludeMode.IncludeSubjectCertificate.
	// 17 - CryptoCertificateIncludeMode.IncludeWholeChain.
	AddInParameters.Insert("IncludeCertificatesInSignature", 17);
	If CMSParameters.IncludeCertificatesInSignature = "DontInclude"
		Or CMSParameters.IncludeCertificatesInSignature = CryptoCertificateIncludeMode.DontInclude Then
		
		AddInParameters.IncludeCertificatesInSignature = 0;
	ElsIf CMSParameters.IncludeCertificatesInSignature = "IncludeSubjectCertificate"
		Or CMSParameters.IncludeCertificatesInSignature = CryptoCertificateIncludeMode.IncludeSubjectCertificate Then
		
		AddInParameters.IncludeCertificatesInSignature = 1;
	EndIf;
	
	Return AddInParameters;
	
EndFunction

// Prepares a string to use as a file name.
Function PrepareStringForFileName(String, SpaceReplacement = Undefined) Export
	
	CharsReplacement = New Map;
	CharsReplacement.Insert("\", " ");
	CharsReplacement.Insert("/", " ");
	CharsReplacement.Insert("*", " ");
	CharsReplacement.Insert("<", " ");
	CharsReplacement.Insert(">", " ");
	CharsReplacement.Insert("|", " ");
	CharsReplacement.Insert(":", "");
	CharsReplacement.Insert("""", "");
	CharsReplacement.Insert("?", "");
	CharsReplacement.Insert(Chars.CR, "");
	CharsReplacement.Insert(Chars.LF, " ");
	CharsReplacement.Insert(Chars.Tab, " ");
	CharsReplacement.Insert(Chars.NBSp, " ");
	// Remove quotation characters.
	CharsReplacement.Insert(Char(171), "");
	CharsReplacement.Insert(Char(187), "");
	CharsReplacement.Insert(Char(8195), "");
	CharsReplacement.Insert(Char(8194), "");
	CharsReplacement.Insert(Char(8216), "");
	CharsReplacement.Insert(Char(8218), "");
	CharsReplacement.Insert(Char(8217), "");
	CharsReplacement.Insert(Char(8220), "");
	CharsReplacement.Insert(Char(8222), "");
	CharsReplacement.Insert(Char(8221), "");
	
	PreparedString = "";
	
	CharsCount = StrLen(String);
	
	For CharacterNumber = 1 To CharsCount Do
		Char = Mid(String, CharacterNumber, 1);
		If CharsReplacement[Char] <> Undefined Then
			Char = CharsReplacement[Char];
		EndIf;
		PreparedString = PreparedString + Char;
	EndDo;
	
	If SpaceReplacement <> Undefined Then
		PreparedString = StrReplace(SpaceReplacement, " ", SpaceReplacement);
	EndIf;
	
	Return TrimAll(PreparedString);
	
EndFunction

#Region AuxiliaryProceduresAndFunctions

// For the CertificateOverdue, CertificatePresentation, and CertificateProperties functions.
//
// Parameters:
//   Certificate - CryptoCertificate
//
Function CertificateDates(Certificate, UTCOffset) Export
	
	CertificateDates = New Structure;
	CertificateDates.Insert("StartDate",    Certificate.ValidFrom    + UTCOffset);
	CertificateDates.Insert("EndDate", Certificate.ValidTo + UTCOffset);
	CertificateDates.Insert("ValidBefore", CertificateDates.EndDate);
	CertificateDates.Insert("PrivateKeyStartDate", Date(1,1,1));
	CertificateDates.Insert("PrivateKeyExpirationDate", Date(1,1,1));
	
	If AreCertificateAdditionalPropertiesAvailable() And TypeOf(Certificate) = Type("CryptoCertificate") Then
		DateProperties = New Structure("StartUniversalDateOfPrivateKey, UniversalDateOfPrivateKeyExpiration");
		FillPropertyValues(DateProperties, Certificate);
		If DateProperties.StartUniversalDateOfPrivateKey <> Undefined Then
			CertificateDates.Insert("PrivateKeyStartDate", DateProperties.StartUniversalDateOfPrivateKey
				+ UTCOffset);
		EndIf;
		If DateProperties.UniversalDateOfPrivateKeyExpiration <> Undefined Then
			CertificateDates.Insert("PrivateKeyExpirationDate", DateProperties.UniversalDateOfPrivateKeyExpiration
				+ UTCOffset);
			CertificateDates.Insert("ValidBefore", Min(CertificateDates.EndDate,
				CertificateDates.PrivateKeyExpirationDate));
		EndIf;
	EndIf;
	
	Return CertificateDates;
	
EndFunction

// For the CertificateProperties function.
Function GetPurpose(Certificate) // "2.5.29.37"
	
	If Not Certificate.Extensions.Property("EKU") Then
		Return "";
	EndIf;
	
	FixedPropertiesArray = Certificate.Extensions.EKU;
	
	Purpose = "";
	
	For IndexOf = 0 To FixedPropertiesArray.Count() - 1 Do
		Purpose = Purpose + FixedPropertiesArray.Get(IndexOf);
		Purpose = Purpose + Chars.LF;
	EndDo;
	
	Return PrepareRow(Purpose);
	
EndFunction

// For the CertificateProperties function.
Function GetCryptoCertificatePurpose(Certificate)
	
	Assignments = Certificate.CertificateExtensions.Get("2.5.29.37");
	If Assignments = Undefined Then
		Return "";
	EndIf;
	
	Return StrConcat(Assignments, Chars.LF);
	
EndFunction

// Returns information records from certificate properties as String.
//
// Parameters:
//  CertificateProperties - See DigitalSignature.CertificateProperties
// 
// Returns:
//  String
//
Function DetailsCertificateString(CertificateProperties) Export
	
	InformationAboutCertificate = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chứng chỉ: %1
			|Nơi cấp: %2
			|Chủ sở hữu: %3
			|Có hiệu lực: từ %4 đến %5';
			|ru = 'Сертификат: %1
			|Кем выдан: %2
			|Владелец: %3
			|Действителен: с %4 по %5';
			|en = 'Certificate: %1
			|Issued by: %2
			|Issued to: %3
			|Valid: from %4 to %5'; fa = 'Certificate: %1
			|Issued by: %2
			|Issued to: %3
			|Valid: from %4 to %5';
			|it = 'Certificato: %1
			| Emesso da: %2
			| Proprietario: %3
			| Valido: dal %4 al %5';
			|pl = 'Certyfikat: %1
			|Wydany przez: %2
			|Właściciel: %3
			|Ważny: od %4 do %5';
			|tr = 'Sertifika: %1
			|Düzenleyen: %2
			|Sahibi: %3
			|Geçerlilik dönemi: %4 - %5'"),
		String(CertificateProperties.SerialNumber),
		CertificateProperties.IssuedBy,
		CertificateProperties.IssuedTo,
		Format(CertificateProperties.StartDate,    "DLF=D"),
		Format(CertificateProperties.ValidBefore, "DLF=D"));
	
	Return InformationAboutCertificate;
	
EndFunction

// For the CertificateSubjectProperties and CertificateIssuerProperties functions.
Function PrepareRow(RowFromCertificate)
	
	Return TrimAll(CommonClientServer.ReplaceProhibitedXMLChars(RowFromCertificate));
	
EndFunction

// For the GeneralErrorDescription function.
Function SimplifiedErrorStructure(Error, ErrorTitle)
	
	SimplifiedStructure = New Structure;
	SimplifiedStructure.Insert("ErrorDescription",  "");
	SimplifiedStructure.Insert("ErrorTitle", "");
	SimplifiedStructure.Insert("LongDesc",        "");
	SimplifiedStructure.Insert("NotSupported", False);
	
	If TypeOf(Error) = Type("String") Then
		SimplifiedStructure.ErrorDescription = TrimAll(Error);
		Return SimplifiedStructure;
		
	ElsIf TypeOf(Error) <> Type("Structure") Then
		Return SimplifiedStructure;
	EndIf;
	
	If Error.Property("ErrorDescription") Then
		SimplifiedStructure.ErrorDescription = TrimAll(Error.ErrorDescription);
	EndIf;
	
	If Error.Property("ErrorTitle") Then
		If Error.Property("Errors") And Error.Errors.Count() = 1 Then
			If ErrorTitle <> Undefined Then
				SimplifiedStructure.ErrorTitle = Error.ErrorTitle;
			EndIf;
			ErrorProperties = Error.Errors[0]; // See NewErrorProperties
			NewErrorProperties = NewErrorProperties();
			FillPropertyValues(NewErrorProperties, ErrorProperties);
			LongDesc = "";
			If ValueIsFilled(NewErrorProperties.Application) Then
				LongDesc = LongDesc + String(NewErrorProperties.Application) + ":" + Chars.LF;
			EndIf;
			LongDesc = LongDesc + NewErrorProperties.LongDesc;
			SimplifiedStructure.LongDesc = TrimAll(LongDesc);
			SimplifiedStructure.ErrorDescription = TrimAll(SimplifiedStructure.ErrorTitle + Chars.LF + LongDesc);
			If NewErrorProperties.NotSupported Then
				SimplifiedStructure.NotSupported = True;
			EndIf;
		EndIf;
	ElsIf ValueIsFilled(ErrorTitle) Then
		SimplifiedStructure.ErrorTitle = ErrorTitle;
		SimplifiedStructure.LongDesc = SimplifiedStructure.ErrorDescription;
		SimplifiedStructure.ErrorDescription = ErrorTitle
			+ Chars.LF + SimplifiedStructure.ErrorDescription;
	EndIf;
	
	Return SimplifiedStructure;
	
EndFunction

Function DiagnosticInformationAboutTheProgram(Application, CryptoManager, ErrorDescription) Export
	
	If TypeOf(CryptoManager) = Type("CryptoManager") Then
		Result = NStr("vi = 'Đồng ý';
						|ru = 'ОК';
						|en = 'OK'; fa = 'تأیید';
						|it = 'OK';
						|pl = 'OK';
						|tr = 'Tamam'");
	Else
		ErrorText = "";
		If TypeOf(ErrorDescription) = Type("Structure")
		   And ErrorDescription.Property("Errors")
		   And TypeOf(ErrorDescription.Errors) = Type("Array")
		   And ErrorDescription.Errors.Count() > 0 Then
			
			Error = ErrorDescription.Errors[0]; // See NewErrorProperties
			ErrorText = Error.LongDesc;
		EndIf;
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lỗi ""%1""';
				|ru = 'Ошибка ""%1""';
				|en = 'Error ""%1""'; fa = 'Error ""%1""';
				|it = 'Errore ""%1""';
				|pl = 'Błąd ""%1""';
				|tr = '""%1"" hatası'"), ErrorText);
	EndIf;
	
	Return Application.Presentation + " - " + Result + Chars.LF;
	
EndFunction

// For internal use only.
// 
// Parameters:
//  Cryptoprovider - Map - Taken from the add-in response
//  ApplicationsByNamesWithType - See DigitalSignatureInternalCached.CommonSettings
//  CheckAtCleint - Boolean - Flag indicating whether the CSP is installed on the client local machine
// 
// Returns:
//   See NewExtendedApplicationDetails
//
Function ExtendedApplicationDetails(Cryptoprovider, ApplicationsByNamesWithType, CheckAtCleint = True) Export
	
	ApplicationDetails = NewExtendedApplicationDetails();
	
	ApplicationType = Cryptoprovider.Get("type");
	If ApplicationType = 0 Then
		Return Undefined;
	EndIf;
	
	ApplicationDetails.ApplicationType = ApplicationType;
	ApplicationDetails.ApplicationName = Cryptoprovider.Get("name");
	
	Var_Key = ApplicationSearchKeyByNameWithType(ApplicationDetails.ApplicationName, ApplicationDetails.ApplicationType);
	ApplicationToSupply = ApplicationsByNamesWithType.Get(Var_Key);
	
	If ApplicationToSupply = Undefined Then
		Return Undefined;
	Else
		FillPropertyValues(ApplicationDetails, ApplicationToSupply);
	EndIf;
	
	If Not ValueIsFilled(ApplicationDetails.Presentation) Then
		ApplicationDetails.Presentation = Var_Key;
	EndIf;
	
	If CheckAtCleint Then
		ApplicationDetails.PathToAppAuto = Cryptoprovider.Get("path");
	Else
		ApplicationDetails.AppPathAtServerAuto = Cryptoprovider.Get("path");
	EndIf;
	
	ApplicationDetails.Version = Cryptoprovider.Get("version");
	ApplicationDetails.ILicenseInfo =  Cryptoprovider.Get("license");
	ApplicationDetails.AutoDetect = True;
	
	Return ApplicationDetails;
	
EndFunction

// For internal use only.
Procedure DoProcessAppsCheckResult(Cryptoproviders, Programs, IsConflictPossible, Context, HasAppsToCheck = False) Export
	
	InstalledPrograms = New Map;
	
	For Each CurCryptoProvider In Cryptoproviders Do
		
		Found1 = True; Presentation = Undefined;
		
		If ValueIsFilled(Context.SignAlgorithms) Then
			Found1 = False;
			For Each Algorithm In Context.SignAlgorithms Do
				Found1 = CryptoManagerSignAlgorithmSupported(CurCryptoProvider,
					?(Context.DataType = "Certificate","","CheckSignature"), Algorithm, Undefined, Context.IsServer, False);
				If Found1 Then
					Break;
				EndIf;
			EndDo;
		ElsIf ValueIsFilled(Context.AppsToCheck) Then
			Found1 = False;
			For Each Application In Context.AppsToCheck Do
				If Application.ApplicationName = CurCryptoProvider.ApplicationName
					And Application.ApplicationType = CurCryptoProvider.ApplicationType Then
					Presentation = Application.Presentation;
					Found1 = True;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If Not Found1 Then
			Continue;
		EndIf;
		
		If Context.ExtendedDescription Then
			ProgramVerificationResult = NewExtendedApplicationDetails();
		Else
			ProgramVerificationResult = ProgramVerificationResult();
		EndIf;
		
		FillPropertyValues(ProgramVerificationResult, CurCryptoProvider);
		ProgramVerificationResult.Presentation = 
			?(ValueIsFilled(Presentation), Presentation, CurCryptoProvider.Presentation);
		
		ProgramVerificationResult.Insert("Application", DigitalSignatureApplication(CurCryptoProvider));
		If Not IsBlankString(ProgramVerificationResult.Application) Then
			InstalledPrograms.Insert(ProgramVerificationResult.Application, True);
		EndIf;
		
		Programs.Add(ProgramVerificationResult);
		
	EndDo;
	
	If InstalledPrograms.Count() > 0 Then
		HasAppsToCheck = True;
		IsConflictPossible = InstalledPrograms.Count() > 1;
	EndIf;
	
EndProcedure

Function DigitalSignatureApplication(Cryptoprovider)
	
	Result = "";
	DigitalSignatureClientServerLocalization.OnGetDigitalSigningAppName(Cryptoprovider, Result);
	
	Return Result;
	
EndFunction

// For internal use only.
Function ProgramVerificationResult()
	
	Structure = New Structure;
	Structure.Insert("Presentation");
	Structure.Insert("Ref");
	Structure.Insert("ApplicationName");
	Structure.Insert("ApplicationType");
	Structure.Insert("Application");
	Structure.Insert("Version");
	Structure.Insert("ILicenseInfo");

	Return Structure;
	
EndFunction

// For internal use only.
Function PlacementOfTheCertificate(LocationType) Export
	
	Result = "Local_";
	GeneralPlacement = (LocationType - 1) % 4;
	
	If GeneralPlacement = 2 Then
		Result = "CloudSignature";
	ElsIf GeneralPlacement = 3 Then
		Result = "SignatureInTheServiceModel";
	EndIf;
	
	Return Result;
	
EndFunction

// Returns:
//  Structure:
//   * Ref - Undefined, CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//   * Presentation - String
//   * ApplicationName - String
//   * ApplicationType - Number
//   * SignAlgorithm - String
//   * HashAlgorithm - String
//   * EncryptAlgorithm - String
//   * Id - String
//   * ApplicationPath - String
//   * PathToAppAuto - String
//   * AppPathAtServerAuto - String
//   * Version - String - Library version
//   * ILicenseInfo - Boolean - App license presence flag
//   * UsageMode - EnumRef.DigitalSignatureAppUsageModes
//   * AutoDetect - Boolean - Flag indicating whether the app is determined automatically
//
Function NewExtendedApplicationDetails() Export
	
	LongDesc = New Structure;
	LongDesc.Insert("Ref");
	LongDesc.Insert("Presentation");
	LongDesc.Insert("ApplicationName");
	LongDesc.Insert("ApplicationType");
	LongDesc.Insert("SignAlgorithm");
	LongDesc.Insert("HashAlgorithm");
	LongDesc.Insert("EncryptAlgorithm");
	LongDesc.Insert("Id");
	LongDesc.Insert("SignatureVerificationAlgorithms");
	
	LongDesc.Insert("PathToAppAuto", "");
	LongDesc.Insert("AppPathAtServerAuto", "");
	LongDesc.Insert("Version");
	LongDesc.Insert("ILicenseInfo", False);
	LongDesc.Insert("UsageMode", PredefinedValue(
		"Enum.DigitalSignatureAppUsageModes.Automatically"));
	LongDesc.Insert("AutoDetect", True);
	
	Return LongDesc;

EndFunction

Function DataToSupplementErrorFromClassifier(AdditionalData) Export
	
	Structure = New Structure("CertificateData, SignatureData");
	
	If Not ValueIsFilled(AdditionalData) Then
		Return Structure;
	EndIf;
	
	CertificateData = CommonClientServer.StructureProperty(AdditionalData, "CertificateData", Undefined);
	If ValueIsFilled(CertificateData) Then
		If TypeOf(CertificateData) = Type("String") Then
			CertificateData = GetFromTempStorage(CertificateData);
		EndIf;
	Else
		Certificate = CommonClientServer.StructureProperty(AdditionalData, "Certificate", Undefined);
		If ValueIsFilled(Certificate) Then
			If TypeOf(Certificate) = Type("Array") Then
				If Certificate.Count() > 0 Then
					If TypeOf(Certificate[0]) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
						If ValueIsFilled(Certificate[0]) Then
							CertificateData = DigitalSignatureInternalServerCall.CertificateData(Certificate[0]);
						EndIf;
					ElsIf IsTempStorageURL(Certificate[0]) Then
						CertificateData = GetFromTempStorage(Certificate[0]);
					EndIf;
				EndIf;
			ElsIf TypeOf(Certificate) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
				If ValueIsFilled(Certificate) Then
					CertificateData = DigitalSignatureInternalServerCall.CertificateData(Certificate);
				EndIf;
			ElsIf TypeOf(Certificate) = Type("BinaryData") Then
				CertificateData = Certificate;
			ElsIf IsTempStorageURL(Certificate) Then
				CertificateData = GetFromTempStorage(Certificate);
			EndIf;
		EndIf;
	EndIf;
	
	Structure.CertificateData = CertificateData;
	Structure.SignatureData = CommonClientServer.StructureProperty(AdditionalData, "SignatureData", Undefined);
	
	Return Structure;
	
EndFunction

Function TimestampServersDiagnostics(TimestampServersAddresses, StringForConnection) Export
	
	Array = New Array;
	Array.Add(StringForConnection);
	Array.Add(Chars.LF);
	
	For Each Address In TimestampServersAddresses Do
		
		ErrorMessage = TimestampServerDiagnostics(Address);
		
		If ValueIsFilled(ErrorMessage) Then
			Array.Add(ErrorMessage);
		Else
			Array.Add(StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 - khả dụng.';
																					|ru = '%1 - доступен.';
																					|en = '%1 is available.'; fa = '%1 is available.';
																					|it = '%1 - доступен.';
																					|pl = '%1 is available.';
																					|tr = '%1 - mevcut.'"), Address));
		EndIf;
		
		Array.Add(Chars.LF);
		
	EndDo;
	
	Return StrConcat(Array, Chars.LF);

EndFunction

// A function for timestamp diagnostics.
//
// Parameters:
//   URL - String - file URL in the following format: [Protocol://]<Server>/<Path to the file on the server>.
//
// Returns:
//   Structure:
//      * ErrorMessage - String
//
Function TimestampServerDiagnostics(Val URL, Redirections = Undefined)

#If WebClient Then
	Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr(
			"vi = 'Không thể chẩn đoán khi làm việc trong web-client. Trong trình duyệt hãy thử tải tệp theo liên kết %1';
			|ru = 'Диагностика недоступна при работе в веб-клиенте. Попробуйте в браузере скачать файл по ссылке %1';
			|en = 'Web client doesn''t support availability testing. Download the file by URL: %1'; fa = 'Web client doesn''t support availability testing. Download the file by URL: %1';
			|it = 'Диагностика недоступна при работе в веб-клиенте. Попробуйте в браузере скачать файл по ссылке %1';
			|pl = 'Web client doesn''t support availability testing. Download the file by URL: %1';
			|tr = 'Web istemcisinde çalışırken tanılama kullanılamaz. Dosyayı tarayıcınızdaki %1 bağlantısından indirmeyi deneyin'"),
		URL);

#Else
	
		If Redirections = Undefined Then
			Redirections = New Array;
		EndIf;
		
		URIStructure = CommonClientServer.URIStructure(URL);

		Server        = URIStructure.Host;
		PathAtServer = URIStructure.PathAtServer;
		Protocol      = URIStructure.Schema;

		If IsBlankString(Protocol) Then
			Protocol = "http"; // It is acceptable to use an unprotected connection for diagnostics.
		EndIf;

		If Protocol = "https" Then
			SecureConnection = True;
		EndIf;

		If SecureConnection = True Then
			SecureConnection = CommonClientServer.NewSecureConnection();
		ElsIf SecureConnection = False Then
			SecureConnection = Undefined;
		EndIf;

		Port = URIStructure.Port;
		Proxy = Undefined;
		
		Try

			Join = New HTTPConnection(Server, Port, , , Proxy, 7, SecureConnection);

			Server = Join.Host;
			Port   = Join.Port;

			HTTPRequest = New HTTPRequest(PathAtServer, New Map);
			HTTPRequest.Headers.Insert("Accept-Charset", "UTF-8");
			HTTPRequest.Headers.Insert("X-1C-Request-UID", String(New UUID));
			HTTPResponse = Join.Get(HTTPRequest);

		Except

			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể thiết lập kết nối HTTP với máy chủ %1:%2
					 |do nguyên nhân:
					 |%3';
					 |ru = 'Не удалось установить HTTP-соединение с сервером %1:%2
					 |по причине:
					 |%3';
					 |en = 'Couldn''t establish HTTP connection to server %1:%2.
					 |Reason:
					 |%3'; fa = 'Couldn''t establish HTTP connection to server %1:%2.
					 |Reason:
					 |%3';
					 |it = 'Не удалось установить HTTP-соединение с сервером %1:%2
					 |по причине:
					 |%3';
					 |pl = 'Couldn''t establish HTTP connection to server %1:%2.
					 |Reason:
					 |%3';
					 |tr = '%1:%2
					 | Sunucu ile HTTP-bağlantı yapılamadı çünkü:
					 |%3'"), Server, Format(Port, "NG="), ErrorProcessing.BriefErrorDescription(
				ErrorInfo()));

			Return ErrorText;

		EndTry;

		Try
			
			If HTTPResponse.StatusCode = 301 // 301 Moved Permanently
				Or HTTPResponse.StatusCode = 302 // 302 Found, 302 Moved Temporarily
				Or HTTPResponse.StatusCode = 303 // 303 See Other by GET
				Or HTTPResponse.StatusCode = 307 // 307 Temporary Redirect
				Or HTTPResponse.StatusCode = 308 Then // 308 Permanent Redirect
				
				If Redirections.Count() > 7 Then
					Raise 
						NStr("vi = 'Đã vượt quá số lần chuyển hướng.';
							|ru = 'Превышено количество перенаправлений.';
							|en = 'Redirections limit exceeded.'; fa = 'Redirections limit exceeded.';
							|it = 'Превышено количество перенаправлений.';
							|pl = 'Przekroczono liczbę przekierowań.';
							|tr = 'Tekrar yönlendirme sayısı arttı.'");
				Else 
					
					Headers = New Map;
					For Each Title In HTTPResponse.Headers Do
						Headers.Insert(Lower(Title.Key), Title.Value);
					EndDo;
					
					NewURL1 = Headers["location"];
					If NewURL1 = Undefined Then 
						Raise 
							NStr("vi = 'Chuyển hướng sai, không có HTTP-tiêu đề phản hồi ""Location"".';
								|ru = 'Некорректное перенаправление, отсутствует HTTP-заголовок ответа ""Location"".';
								|en = 'Invalid redirection: no ""Location"" header in the HTTP response.'; fa = 'Invalid redirection: no ""Location"" header in the HTTP response.';
								|it = 'Некорректное перенаправление, отсутствует HTTP-заголовок ответа ""Location"".';
								|pl = 'Niepoprawne przekierowanie, brak nagłówka odpowiedzi HTTP ""Location"".';
								|tr = 'Yanlış yönlendirme, ""Konum"" yanıtının HTTP üstbilgisi eksik.'");
					EndIf;
					
					NewURL1 = TrimAll(NewURL1);
					If IsBlankString(NewURL1) Then
						Raise 
							NStr("vi = 'Chuyển hướng sai, HTTP-tiêu đề phản hồi ""Location"" trống.';
								|ru = 'Некорректное перенаправление, пустой HTTP-заголовок ответа ""Location"".';
								|en = 'Invalid redirection: blank ""Location"" header in the HTTP response.'; fa = 'Invalid redirection: blank ""Location"" header in the HTTP response.';
								|it = 'Некорректное перенаправление, пустой HTTP-заголовок ответа ""Location"".';
								|pl = 'Niepoprawne przekierowanie, pusty nagłówek odpowiedzi HTTP ""Location"".';
								|tr = 'Yanlış yönlendirme, boş HTTP yanıt başlığı ""Konum"".'");
					EndIf;
					
					If Redirections.Find(NewURL1) <> Undefined Then
						Raise StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Chuyển hướng vòng lặp.
							           |Trước đó, đã thử chuyển đến %1.';
							           |ru = 'Циклическое перенаправление.
							           |Попытка перейти на %1 уже выполнялась ранее.';
							           |en = 'Circular redirect.
							           |Redirect to %1 was attempted earlier.'; fa = 'Circular redirect.
							           |Redirect to %1 was attempted earlier.';
							           |it = 'Циклическое перенаправление.
							           |Попытка перейти на %1 уже выполнялась ранее.';
							           |pl = 'Cykliczne przekierowanie.
							           |Próba przejścia na %1 już uruchomione wcześniej.';
							           |tr = 'Döngüsel yönlendirme. 
							           |Daha önce zaten devam etmeye %1çalışıyor.'"),
							NewURL1);
					EndIf;
					
					Redirections.Add(URL);
					If Not StrStartsWith(NewURL1, "http") Then
						// <scheme>://<host>:<port>/<path>
						NewURL1 = StringFunctionsClientServer.SubstituteParametersToString(
							"%1://%2:%3/%4", Protocol, Server, Format(Port, "NG="), NewURL1);
					EndIf;
					
					Return TimestampServerDiagnostics(NewURL1, Redirections);
					
				EndIf;
				
			EndIf;

			If HTTPResponse.StatusCode < 200 Or HTTPResponse.StatusCode >= 300 Then

				If HTTPResponse.StatusCode < 200 Or HTTPResponse.StatusCode >= 300 And HTTPResponse.StatusCode < 400 Then

					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Phản hồi của máy chủ không được hỗ trợ (%1)';
							|ru = 'Неподдерживаемый ответ сервера (%1)';
							|en = 'Unsupported server response (%1)'; fa = 'Unsupported server response (%1)';
							|it = 'Неподдерживаемый ответ сервера (%1)';
							|pl = 'Unsupported server response (%1)';
							|tr = 'Sunucunun desteklenmeyen cevabı:(%1)'"), HTTPResponse.StatusCode);

					Raise ErrorText;

				ElsIf HTTPResponse.StatusCode >= 400 And HTTPResponse.StatusCode < 500 Then

					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Lỗi khi thực hiện truy vấn (%1)';
							|ru = 'Ошибка при выполнении запроса (%1)';
							|en = 'Request error (%1)'; fa = 'Request error (%1)';
							|it = 'Ошибка при выполнении запроса (%1)';
							|pl = 'Request error (%1)';
							|tr = 'Sorgu oluşturma hatası (%1)'"), HTTPResponse.StatusCode);
					Raise ErrorText;

				Else

					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Lỗi server khi xử lý truy vấn đến tài nguyên (%1)';
							|ru = 'Ошибка сервера при обработке запроса к ресурсу (%1)';
							|en = 'A server error occurred while processing a request (%1)'; fa = 'A server error occurred while processing a request (%1)';
							|it = 'Ошибка сервера при обработке запроса к ресурсу (%1)';
							|pl = 'A server error occurred while processing a request (%1)';
							|tr = 'Kaynak sorgu isteği işlenirken sunucu hatası: (%1)'"), HTTPResponse.StatusCode);

					Raise ErrorText;

				EndIf;

			EndIf;

		Except

			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể nhận tệp %1 từ server %2:%3do nguyên nhân:
					 |%4';
					 |ru = 'Не удалось получить файл %1 с сервера %2:%3 по причине:
					 |%4';
					 |en = 'Cannot get file %1 from server %2.%3 Reason:
					 |%4'; fa = 'Cannot get file %1 from server %2.%3 Reason:
					 |%4';
					 |it = 'Не удалось получить файл %1 с сервера %2:%3 по причине:
					 |%4';
					 |pl = 'Cannot get file %1 from server %2.%3 Reason:
					 |%4';
					 |tr = 'Dosyayı %1 sunucudan %2: %3
					 |aşağıdaki nedenle alınamadı:
					 |%4'"), URL, Server, Format(Port, "NG="), ErrorProcessing.BriefErrorDescription(
				ErrorInfo()));
			Return ErrorText;

		EndTry;
		
		Return "";
		
#EndIf
EndFunction

Function TokensTechnicalInfo(TokensInfo, ForTheClient = True) Export
	
	Tokens = New Array;
	For Each Token In TokensInfo Do
		If ValueIsFilled(Token.Error) Then
			If ValueIsFilled(Token.Slot) Then
				Tokens.Add(StrTemplate("%1: %2", Token.Slot, Token.Error));
			Else
				Tokens.Add(Token.Error);
			EndIf;
		Else
			Mechanisms = StrReplace(Token.Mechanisms, Chars.LF, "");
			Mechanisms = StrReplace(Mechanisms, Chars.Tab, "");
			Mechanisms = StrReplace(Mechanisms, " ", "");
			Tokens.Add(StrTemplate("%1: %2", Token.Slot, Mechanisms));
		EndIf;
	EndDo;
	
	If ForTheClient Then
		If Tokens.Count() > 0 Then
			Return StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Các token được xác định tự động trên máy tính:
			|%1';
			|ru = 'Автоматически определенные токены на компьютере:
			|%1';
			|en = 'Tokens found on computer:
			|%1'; fa = 'Tokens found on computer:
			|%1';
			|it = 'Автоматически определенные токены на компьютере:
			|%1';
			|pl = 'Tokens found on computer:
			|%1';
			|tr = 'Bilgisayarda otomatik tanımlı token''lar:
			|%1'"), StrConcat(Tokens, Chars.LF));
		Else
			Return NStr("vi = 'Trên máy tính chưa xác định các token được kết nối.';
						|ru = 'На компьютере не определены подключенные токены.';
						|en = 'No tokens found on computer.'; fa = 'No tokens found on computer.';
						|it = 'На компьютере не определены подключенные токены.';
						|pl = 'No tokens found on computer.';
						|tr = 'Bilgisayarda hiçbir bağlı token tanımlanmamış.'");
		EndIf;
	Else
		If Tokens.Count() > 0 Then
			Return StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Các token được xác định tự động trên server:
			|%1';
			|ru = 'Автоматически определенные токены на сервере:
			|%1';
			|en = 'Tokens found on server:
			|%1'; fa = 'Tokens found on server:
			|%1';
			|it = 'Автоматически определенные токены на сервере:
			|%1';
			|pl = 'Tokens found on server:
			|%1';
			|tr = 'Sunucuda otomatik tanımlı token''lar:
			|%1'"), StrConcat(Tokens, Chars.LF));
		Else
			Return NStr("vi = 'Trên server chưa xác định các token được kết nối.';
						|ru = 'На сервере не определены подключенные токены.';
						|en = 'No tokens found on server.'; fa = 'No tokens found on server.';
						|it = 'На сервере не определены подключенные токены.';
						|pl = 'No tokens found on server.';
						|tr = 'Sunucuda hiçbir bağlı token tanımlanmamış.'");
		EndIf;
	EndIf;

EndFunction

#EndRegion

#Region XMLScope

// Parameters:
//  XMLLine   - String
//  TagName - String
//
// Returns:
//   See XMLScopeProperties
//
Function XMLScope(XMLLine, TagName, NumberSingnature = 1) Export
	
	Result = XMLScopeProperties(TagName);
	
	// Extract the item name, as the document might have other items that start with the same characters.
	// 
	IndicatesTheBeginningOfTheArea = "<" + TagName + " ";
	IndicatesTheEndOfTheArea = "</" + TagName + ">";
	
	Position = StrFind(XMLLine, IndicatesTheBeginningOfTheArea, , , NumberSingnature);
	If Position = 0 Then
		// If no item was found, try to remove the whitespace.
		IndicatesTheBeginningOfTheArea = "<" + TagName;
		Position = StrFind(XMLLine, IndicatesTheBeginningOfTheArea, , , NumberSingnature);
		If Position = 0 Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không tìm thấy phần tử ""%1"" trong văn bản XML.';
					|ru = 'Не найдена элемент ""%1"" в документе XML.';
					|en = 'The %1 element is not found in the XML document.'; fa = 'The %1 element is not found in the XML document.';
					|it = 'Elemento ""%1"" non trovato nel documento XML.';
					|pl = 'Nie znaleziono elementu ""%1"" w dokumencie XML.';
					|tr = 'XML belgesinde ""%1"" bileşeni bulunamadı.'"), TagName);
			Result.ErrorText = ErrorText;
		EndIf;
	EndIf;
	Result.StartPosition = Position;
	Text = Mid(XMLLine, Position);
	
	EntryNumber = 1;
	Position = StrFind(Text, IndicatesTheBeginningOfTheArea, , 2, EntryNumber);
	While Position <> 0 Do
		Position = StrFind(Text, IndicatesTheBeginningOfTheArea, , 2, EntryNumber);
		EntryNumber = EntryNumber + 1;
	EndDo;
	
	Position = StrFind(Text, IndicatesTheEndOfTheArea);
	If Position = 0 Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tìm thấy kết thúc phần tử ""%1"" trong văn bản XML.';
				|ru = 'Не найдено окончание элемента ""%1"" в документе XML.';
				|en = '%1 element end is not found in the XML document.'; fa = '%1 element end is not found in the XML document.';
				|it = 'Carattere di chiusura ""%1"" non trovato nel documento XML.';
				|pl = 'Nie znaleziono zakończenia elementu ""%1"" w dokumencie XML.';
				|tr = 'XML belgesinde ""%1"" bileşeninin uzantısı bulunamadı.'"), TagName);
		Result.ErrorText = ErrorText;
	EndIf;
	
	ThePositionOfTheNextArea = Position + StrLen(IndicatesTheEndOfTheArea);
	Result.Text = Mid(Text, 1, ThePositionOfTheNextArea - 1);
	Result.ThePositionOfTheNextArea = Result.StartPosition + ThePositionOfTheNextArea;
	
	Text = Mid(Text, 1, Position - 1);
	
	Position = StrFind(Text, ">");
	If Position = 0 Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tìm thấy kết thúc tiêu đề của phần tử ""%1"" trong văn bản XML.';
				|ru = 'Не найдено окончание заголовка элемента ""%1"" в документе XML.';
				|en = 'The %1 element title end is not found in the XML document.'; fa = 'The %1 element title end is not found in the XML document.';
				|it = 'Carattere di chiusura dell''intestazione dell''elemento ""%1"" non trovata nel documento XML.';
				|pl = 'Nie znaleziono zakończenia nagłówka elementu ""%1"" w dokumencie XML.';
				|tr = 'XML belgesinde ""%1"" bileşeninin başlık uzantısı bulunamadı.'"), TagName);
		Result.ErrorText = ErrorText;
	EndIf;
	
	Result.Begin = Mid(Text, 1, Position);
	Result.End  = IndicatesTheEndOfTheArea;
	Result.Content = Mid(Text, Position + 1);
	
	Return Result;

EndFunction

// Parameters:
//  XMLScope - See XMLScopeProperties
//  Begin     - Undefined
//             - String
//
// Returns:
//  String
//
Function XMLAreaText(XMLScope, Begin = Undefined) Export
	
	PieceOfText = New Array;
	PieceOfText.Add(?(Begin = Undefined, XMLScope.Begin, Begin));
	PieceOfText.Add(XMLScope.Content);
	PieceOfText.Add(XMLScope.End);
	Result = StrConcat(PieceOfText);
	
	Return Result;
	
EndFunction

// Parameters:
//  XMLScope - See XMLScopeProperties
//  Algorithm   - See DigitalSignatureInternal.TheCanonizationAlgorithm
//  XMLText   - String
//
// Returns:
//  String
//
Function ExtendedBeginningOfTheXMLArea(XMLScope, Algorithm, XMLText) Export
	
	Result = New Structure("Begin, ErrorText", , "");
	
	If Algorithm.Kind = "c14n"
	 Or Algorithm.Kind = "smev" Then
		
		If XMLText = Undefined Then
			CurrentXMLScope = XMLScope;
		Else
			CurrentXMLScope = XMLScope(XMLText, XMLScope.TagName);
			If ValueIsFilled(CurrentXMLScope.ErrorText) Then
				Result.ErrorText = CurrentXMLScope.ErrorText;
				Return Result;
			EndIf;
			CurrentXMLScope.NamespacesUpToANode = XMLScope.NamespacesUpToANode;
		EndIf;
		Result.Begin = ExtendedStart(CurrentXMLScope);
	Else
		Result.Begin = XMLScope.Begin;
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  XMLScope - See XMLScopeProperties
//
// Returns:
//  String
//
Function ExtendedStart(XMLScope)
	
	If Not ValueIsFilled(XMLScope.NamespacesUpToANode) Then
		Return XMLScope.Begin;
	EndIf;
	
	Additional = New Array;
	For Each TablespaceName In XMLScope.NamespacesUpToANode Do
		Position = StrFind(TablespaceName, "=""");
		DeclaringASpace = Left(TablespaceName, Position + 1);
		If StrFind(XMLScope.Begin, DeclaringASpace) > 0 Then
			Continue;
		EndIf;
		Additional.Add(TablespaceName);
	EndDo;
	
	Result = Left(XMLScope.Begin, StrLen(XMLScope.TagName) + 1)
		+ " " + StrConcat(Additional, " ")
		+ " " + Mid(XMLScope.Begin, StrLen(XMLScope.TagName) + 2);
	
	Return Result;
	
EndFunction

// Parameters:
//  TagName - String
//
// Returns:
//  Structure:
//   * TagName - String
//   * ErrorText - String
//   * StartPosition - Number
//   * ThePositionOfTheNextArea - Number
//   * Begin      - String
//   * Content - String
//   * End - String
//   * NamespacesUpToANode - Array of String
//                            - Undefined
//
Function XMLScopeProperties(TagName)
	
	Result = New Structure;
	Result.Insert("TagName", TagName);
	Result.Insert("ErrorText", "");
	Result.Insert("StartPosition", 0);
	Result.Insert("ThePositionOfTheNextArea", 0);
	Result.Insert("Begin", "");
	Result.Insert("Content", "");
	Result.Insert("End", "");
	Result.Insert("Text", "");
	Result.Insert("NamespacesUpToANode");
	
	Return Result;
	
EndFunction

#EndRegion

#Region CertificateContents

Function IsGOSTCertificate(CertificateAlgorithm) Export
	
	Return StrStartsWith(CertificateAlgorithm, "1.2.643");
	
EndFunction

Function SignAlgorithmCorrespondsToCertificate(CertificatePresentation, CertificateAlgorithm, SignAlgorithm, HashAlgorithm = Undefined) Export
	
	If Not IsGOSTCertificate(CertificateAlgorithm) Then
		Return True;
	EndIf;

	If Not ValueIsFilled(SignAlgorithm) And Not ValueIsFilled(HashAlgorithm) Then
		Return True;
	EndIf;

	SetsOfAlgorithmsForCreatingASignature = SetsOfAlgorithmsForCreatingASignature();

	AlgorithmsForCheck = Undefined;
	For Each SetOfAlgorithms In SetsOfAlgorithmsForCreatingASignature Do
		If SetOfAlgorithms.IDOfThePublicKeyAlgorithm = CertificateAlgorithm Then
			AlgorithmsForCheck = SetOfAlgorithms;
			Break;
		EndIf;
	EndDo;

	If AlgorithmsForCheck <> Undefined Then
		
		If SignAlgorithm <> CertificateAlgorithm And AlgorithmsForCheck.IDOfTheSignatureAlgorithm <> CertificateAlgorithm Then
			If AlgorithmsForCheck.SignatureAlgorithmNames.Count() > 0
				And AlgorithmsForCheck.SignatureAlgorithmNames.Find(Upper(SignAlgorithm)) = Undefined Then
				Error = StringFunctionsClientServer.SubstituteParametersToString(
							NStr(
							"vi = 'Chứng thư %1 có liên kết đến ứng dụng chữ ký điện tử có thuật toán chữ ký %2không tương ứng với chứng thư. Chứng thư cần liên kết với ứng dụng có thuật toán ký kết %3.';
							|ru = 'Сертификат %1 связан с приложением электронной подписи с не соответствующим сертификату алгоритмом подписи %2. Сертификат должен быть связан с приложением с алгоритмом подписания %3.';
							|en = 'Certificate %1 is associated with an app whose signature algorithm (%2) does not support the certificate. Associate the certificate with an app that uses the %3 algorithm.'; fa = 'Certificate %1 is associated with an app whose signature algorithm (%2) does not support the certificate. Associate the certificate with an app that uses the %3 algorithm.';
							|it = 'Сертификат %1 связан с приложением электронной подписи с не соответствующим сертификату алгоритмом подписи %2. Сертификат должен быть связан с приложением с алгоритмом подписания %3.';
							|pl = 'Certificate %1 is associated with an app whose signature algorithm (%2) does not support the certificate. Associate the certificate with an app that uses the %3 algorithm.';
							|tr = '%1 sertifikası, %2 sertifikasıyla eşleşmeyen imza algoritmasına sahip bir elektronik imza uygulamasıyla ilişkilendirilmiş. Sertifika, %3 imzalama algoritmasına sahip bir uygulamayla ilişkilendirilmelidir.'"),
					CertificatePresentation, SignAlgorithm, AlgorithmPresentation(
							AlgorithmsForCheck.SignatureAlgorithmNames));

				Return Error;
			EndIf;
		EndIf;
		
		If ValueIsFilled(HashAlgorithm) And (HashAlgorithm <> AlgorithmsForCheck.IdOfTheHashingAlgorithm) Then
			If AlgorithmsForCheck.HashAlgorithmNames.Count() > 0
				And AlgorithmsForCheck.HashAlgorithmNames.Find(Upper(
							HashAlgorithm)) = Undefined Then
				Error = StringFunctionsClientServer.SubstituteParametersToString(
							NStr(
								"vi = 'Chứng thư %1 có liên kết đến ứng dụng chữ ký điện tử có thuật toán băm %2không tương ứng với chứng thư. Chứng thư cần liên kết với ứng dụng có thuật toán băm %3.';
								|ru = 'Сертификат %1 связан с приложением электронной подписи с не соответствующим сертификату алгоритмом хеширования %2. Сертификат должен быть связан с приложением с алгоритмом хеширования %3.';
								|en = 'Certificate %1 is associated with an app whose hashing algorithm (%2) does not support the certificate. Associate the certificate with an app that uses the %3 algorithm.'; fa = 'Certificate %1 is associated with an app whose hashing algorithm (%2) does not support the certificate. Associate the certificate with an app that uses the %3 algorithm.';
								|it = 'Сертификат %1 связан с приложением электронной подписи с не соответствующим сертификату алгоритмом хеширования %2. Сертификат должен быть связан с приложением с алгоритмом хеширования %3.';
								|pl = 'Certificate %1 is associated with an app whose hashing algorithm (%2) does not support the certificate. Associate the certificate with an app that uses the %3 algorithm.';
								|tr = '%1 sertifikası, sertifikayla eşleşmeyen %2 karma algoritmasına sahip bir elektronik imza uygulamasıyla ilişkili. Sertifikanın, %3karma algoritması olan uygulamayla ilişkilendirilmesi gerekir.'"),
					CertificatePresentation, HashAlgorithm, AlgorithmPresentation(
								AlgorithmsForCheck.HashAlgorithmNames));
				Return Error;
			EndIf;
		EndIf;
		
	EndIf;

	Return True;
	
EndFunction

Function CertificateAdditionalProperties(Data, UTCOffset = Undefined) Export

	Structure = New Structure;
	Structure.Insert("ErrorText", "");
	Structure.Insert("PrivateKeyStartDate", Date(1,1,1));
	Structure.Insert("PrivateKeyExpirationDate", Date(1,1,1));
	Structure.Insert("CertificateAuthorityKeyID", "");
	Structure.Insert("ContainsEmbeddedLicenseCryptoPro", False);
	
	BinaryData = BinaryDataFromTheData(Data,
		"DigitalSignatureInternalClientServer.CertificateAdditionalProperties");
	
	DataAnalysis = NewDataAnalysis(BinaryData);
	
	//	TBSCertificate  ::=  SEQUENCE  {
	//		version			[0] EXPLICIT Version DEFAULT v1,
	//		...
	//		extensions		[3] EXPLICIT Extensions OPTIONAL
	//							 -- If present, version MUST be v3
	
	// SEQUENCE (Certificate).
	SkipBlockStart(DataAnalysis, 0, 16);
		// SEQUENCE (tbsCertificate).
		SkipBlockStart(DataAnalysis, 0, 16);
			// [0] EXPLICIT (version).
			SkipBlockStart(DataAnalysis, 2, 0);
				// INTEGER {v1(0), v2(1), v3(2)}. 
				SkipBlockStart(DataAnalysis, 0, 2); 
				Integer = ToReadTheWholeStream(DataAnalysis);
				If Integer <> 2 Then
					Structure.ErrorText = NStr("vi = 'Dữ liệu không phải là chứng thư.';
												|ru = 'Данные не являются сертификатом.';
												|en = 'The data is not a certificate.'; fa = 'The data is not a certificate.';
												|it = 'Данные не являются сертификатом.';
												|pl = 'The data is not a certificate.';
												|tr = 'Veriler sertifika değildir.'");
					Return Structure;
				EndIf;
				SkipTheParentBlock(DataAnalysis);
			// version
			SkipTheParentBlock(DataAnalysis);
			// INTEGER  (serialNumber         CertificateSerialNumber).
			SkipBlock(DataAnalysis, 0, 2);
			// SEQUENCE (signature            AlgorithmIdentifier).
			SkipBlock(DataAnalysis, 0, 16);
			// SEQUENCE (issuer               Name).
			SkipBlock(DataAnalysis, 0, 16);
			// SEQUENCE (validity             Validity).
			SkipBlock(DataAnalysis, 0, 16);
			// SEQUENCE (subject              Name).
			SkipBlock(DataAnalysis, 0, 16);
			// SEQUENCE (subjectPublicKeyInfo SubjectPublicKeyInfo).
			SkipBlock(DataAnalysis, 0, 16);
			// [1] IMPLICIT UniqueIdentifier OPTIONAL (issuerUniqueID).
			SkipBlock(DataAnalysis, 2, 1, False);
			// [2] IMPLICIT UniqueIdentifier OPTIONAL (subjectUniqueID).
			SkipBlock(DataAnalysis, 2, 2, False);
			// [3] EXPLICIT SEQUENCE SIZE (1..MAX) OF Extension (extensions). 
			SkipBlockStart(DataAnalysis, 2, 3);
			If DataAnalysis.HasError Then
				Structure.ErrorText = NStr("vi = 'Sai dữ liệu chứng thư.';
											|ru = 'Некорректные данные сертификата.';
											|en = 'Invalid certificate data.'; fa = 'Invalid certificate data.';
											|it = 'Invalid certificate data.';
											|pl = 'Invalid certificate data.';
											|tr = 'Sertifika verileri hatalı.'");
				Return Structure;
			EndIf; 
				// SEQUENCE OF
				SkipBlockStart(DataAnalysis, 0, 16);
				OffsetOfTheFollowing = DataAnalysis.Parents[0].OffsetOfTheFollowing;
				While DataAnalysis.Offset < OffsetOfTheFollowing Do
					// SEQUENCE (extension).
					SkipBlockStart(DataAnalysis, 0, 16);
					If DataAnalysis.HasError Then
						Structure.ErrorText = NStr("vi = 'Sai dữ liệu chứng thư.';
													|ru = 'Некорректные данные сертификата.';
													|en = 'Invalid certificate data.'; fa = 'Invalid certificate data.';
													|it = 'Invalid certificate data.';
													|pl = 'Invalid certificate data.';
													|tr = 'Sertifika verileri hatalı.'");
						Return Structure;
					EndIf; 
						// OBJECT IDENTIFIER
						SkipBlockStart(DataAnalysis, 0, 6);
							
						DataSize = DataAnalysis.Parents[0].DataSize;
						If DataSize = 0 Then
							Structure.ErrorText = NStr("vi = 'Sai dữ liệu chứng thư.';
														|ru = 'Некорректные данные сертификата.';
														|en = 'Invalid certificate data.'; fa = 'Invalid certificate data.';
														|it = 'Invalid certificate data.';
														|pl = 'Invalid certificate data.';
														|tr = 'Sertifika verileri hatalı.'");
							Return Structure;
						EndIf;
						
						If DataSize = 3 Then
							Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
							BufferString = GetHexStringFromBinaryDataBuffer(Buffer);
							SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER
							If BufferString = "551D23" Then // 2.5.29.35 authorityKeyIdentifier
								FillCertificateAuthorityKeyID(BlockRead(DataAnalysis, 0, 4, True), Structure);
							ElsIf BufferString = "551D10" Then // 2.5.29.16 privateKeyUsagePeriod
								FillPrivateKeyValidityPeriod(BlockRead(DataAnalysis, 0, 4, True), Structure,
									?(UTCOffset = Undefined, 0, UTCOffset));
							EndIf;
						
						ElsIf DataSize = 7 Then
							Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
							BufferString = GetHexStringFromBinaryDataBuffer(Buffer);
							If BufferString = "2A850302023102"  Then // 1.2.643.2.2.49.2
								Structure.ContainsEmbeddedLicenseCryptoPro = True;
							EndIf;
							SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER
						Else
							SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER
						EndIf;
						
					SkipTheParentBlock(DataAnalysis); // SEQUENCE
				EndDo;
	Return Structure;

EndFunction

Procedure FillPrivateKeyValidityPeriod(BinaryData, Structure, UTCOffset)
	
	DataAnalysis = NewDataAnalysis(BinaryData);
	
	// OCTET STRING
	SkipBlockStart(DataAnalysis, 0, 4);
	
	// PrivateKeyUsagePeriod ::= SEQUENCE {
	// notBefore       [0]     GeneralizedTime OPTIONAL,
	// notAfter        [1]     GeneralizedTime OPTIONAL }
	// SEQUENCE
	SkipBlockStart(DataAnalysis, 0, 16);
	
	// [0]
	If SkipBlockStart(DataAnalysis, 2, 0, False) Then
		DateBuffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, 14);
		DatePresentation = GetStringFromBinaryDataBuffer(DateBuffer);
		TypeDetails = New TypeDescription("Date");
		Structure.PrivateKeyStartDate = TypeDetails.AdjustValue(DatePresentation);
		SkipTheParentBlock(DataAnalysis); // [0]
	EndIf;
	
	// [1]
	If SkipBlockStart(DataAnalysis, 2, 1, False) Then
		DateBuffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, 14);
		DatePresentation = GetStringFromBinaryDataBuffer(DateBuffer);
		TypeDetails = New TypeDescription("Date");
		Structure.PrivateKeyExpirationDate = TypeDetails.AdjustValue(DatePresentation);
		SkipTheParentBlock(DataAnalysis); // [1]
	EndIf;
	
	If UTCOffset <> Undefined And ValueIsFilled(Structure.PrivateKeyStartDate) Then
		Structure.PrivateKeyStartDate = Structure.PrivateKeyStartDate + UTCOffset;
	EndIf;
	
	If UTCOffset <> Undefined And ValueIsFilled(Structure.PrivateKeyExpirationDate) Then
		Structure.PrivateKeyExpirationDate = Structure.PrivateKeyExpirationDate + UTCOffset;
	EndIf;

EndProcedure

Procedure FillCertificateAuthorityKeyID(BinaryData, Structure)
	
	DataAnalysis = NewDataAnalysis(BinaryData);
	// OCTET STRING
	SkipBlockStart(DataAnalysis, 0, 4);
	
	CertificateAuthorityKeyID = CertificateAuthorityKeyID(DataAnalysis);
	If CertificateAuthorityKeyID <> Undefined Then
		Structure.CertificateAuthorityKeyID = CertificateAuthorityKeyID;
	EndIf; 

EndProcedure

Function CertificateAuthorityKeyID(DataAnalysis)
	
	If TypeOf(DataAnalysis) = Type("BinaryData") Then
		DataAnalysis = NewDataAnalysis(DataAnalysis);
	EndIf;
	// AuthorityKeyIdentifier ::= SEQUENCE {
	//      keyIdentifier             [0] KeyIdentifier           OPTIONAL,
	//
	//   KeyIdentifier ::= OCTET STRING

	// SEQUENCE
	SkipBlockStart(DataAnalysis, 0, 16);
	// [0]
	SkipBlockStart(DataAnalysis, 2, 0);

	If Not DataAnalysis.HasError Then
		DataSize = DataAnalysis.Parents[0].DataSize;
		Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
		Return GetHexStringFromBinaryDataBuffer(Buffer);
	EndIf;
	
	Return Undefined;

EndFunction

Function GeneratedSignAlgorithm(SignatureData, IncludingOID = False, OIDOnly = False, SignAlgorithmDoesNotComplyWithGOST = Undefined) Export
	
	Return SignAlgorithm(SignatureData, False, IncludingOID, OIDOnly, SignAlgorithmDoesNotComplyWithGOST);
	
EndFunction

Function CertificateSignAlgorithm(CertificateData, IncludingOID = False, OIDOnly = False) Export
	
	Return SignAlgorithm(CertificateData, True, IncludingOID, OIDOnly);
	
EndFunction

Function SignAlgorithm(Data, IsCertificateData, IncludingOID = False, OIDOnly = False, SignAlgorithmDoesNotComplyWithGOST = Undefined)
	
	BinaryData = BinaryDataFromTheData(Data,
		"DigitalSignatureInternalClientServer.SignAlgorithm");
	
	DataAnalysis = NewDataAnalysis(BinaryData);
	HashingAlgorithmOID = "";
	
	If IsCertificateData Then
		// SEQUENCE (Certificate).
		SkipBlockStart(DataAnalysis, 0, 16);
			// SEQUENCE (tbsCertificate).
			SkipBlockStart(DataAnalysis, 0, 16);
				//          (version              [0]  EXPLICIT Version DEFAULT v1).
				SkipBlock(DataAnalysis, 2, 0);
				// INTEGER  (serialNumber         CertificateSerialNumber).
				SkipBlock(DataAnalysis, 0, 2);
				// SEQUENCE (signature            AlgorithmIdentifier).
				SkipBlock(DataAnalysis, 0, 16);
				// SEQUENCE (issuer               Name).
				SkipBlock(DataAnalysis, 0, 16);
				// SEQUENCE (validity             Validity).
				SkipBlock(DataAnalysis, 0, 16);
				// SEQUENCE (subject              Name).
				SkipBlock(DataAnalysis, 0, 16);
				// SEQUENCE (subjectPublicKeyInfo SubjectPublicKeyInfo).
				SkipBlockStart(DataAnalysis, 0, 16);
					// SEQUENCE (algorithm  AlgorithmIdentifier).
					SkipBlockStart(DataAnalysis, 0, 16);
						// OBJECT IDENTIFIER (algorithm).
						SkipBlockStart(DataAnalysis, 0, 6);
	Else
		
		// SEQUENCE (PKCS #7 ContentInfo).
		SkipBlockStart(DataAnalysis, 0, 16);
			// OBJECT IDENTIFIER (contentType).
			SkipBlockStart(DataAnalysis, 0, 6);
				// 1.2.840.113549.1.7.2 signedData (PKCS #7).
				ToCheckTheDataBlock(DataAnalysis, "2A864886F70D010702");
				SkipTheParentBlock(DataAnalysis);
			// [0]CS             (content [0] EXPLICIT ANY DEFINED BY contentType OPTIONAL).
			SkipBlockStart(DataAnalysis, 2, 0);
				// SEQUENCE (content SignedData).
				SkipBlockStart(DataAnalysis, 0, 16);
					// INTEGER  (version          Version).
					SkipBlock(DataAnalysis, 0, 2);
					// SET      (digestAlgorithms DigestAlgorithmIdentifiers).
					SkipBlock(DataAnalysis, 0, 17);
					// SEQUENCE (contentInfo      ContentInfo).
					SkipBlock(DataAnalysis, 0, 16);
					// [0]CS    (certificates     [0] IMPLICIT ExtendedCertificatesAndCertificates OPTIONAL).
					SkipBlock(DataAnalysis, 2, 0, False);
					// [1]CS    (crls             [1] IMPLICIT CertificateRevocationLists OPTIONAL).
					SkipBlock(DataAnalysis, 2, 1, False);
					// SET      (signerInfos      SET OF SignerInfo).
					SkipBlockStart(DataAnalysis, 0, 17);
						// SEQUENCE (signerInfo SignerInfo).
						SkipBlockStart(DataAnalysis, 0, 16);
							// INTEGER  (version                   Version).
							SkipBlock(DataAnalysis, 0, 2);
							// SEQUENCE (issuerAndSerialNumber     IssuerAndSerialNumber).
							SkipBlock(DataAnalysis, 0, 16);
								// SEQUENCE (digestAlgorithm           DigestAlgorithmIdentifier).
								SkipBlockStart(DataAnalysis, 0, 16);
									// OBJECT IDENTIFIER (algorithm).
									SkipBlockStart(DataAnalysis, 0, 6);
									HashingAlgorithmOID = ReadOID(DataAnalysis);
									SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER (algorithm)
								SkipTheParentBlock(DataAnalysis); // SEQUENCE (digestAlgorithm           DigestAlgorithmIdentifier).
							// [0]CS    (authenticatedAttributes   [0] IMPLICIT Attributes OPTIONAL).
							SkipBlock(DataAnalysis, 2, 0, False);
							// SEQUENCE (digestEncryptionAlgorithm AlgorithmIdentifier).
							SkipBlockStart(DataAnalysis, 0, 16);
								// OBJECT IDENTIFIER (algorithm).
								SkipBlockStart(DataAnalysis, 0, 6);
	EndIf;
	
	SignatureAlgorithmOID = ReadOID(DataAnalysis);
	If DataAnalysis.HasError Then
		Return "";
	EndIf;
	
	SignatureRelatedOID = SignAlgorithmRelatedToHashAlgorithmGOST(HashingAlgorithmOID);
	If SignatureRelatedOID <> Undefined And SignatureAlgorithmOID <> SignatureRelatedOID Then
		
		AlgorithmsIDs = IDsOfSignatureAlgorithms(False);
		AlgorithmIncorrect = AlgorithmByOID(SignatureAlgorithmOID, AlgorithmsIDs, True);
		AlgorithmCorrect = AlgorithmByOID(SignatureRelatedOID, AlgorithmsIDs, True);
		
		AlgorithmsIDs = TheIdentifiersOfTheHashAlgorithms();
		HashAlgorithm = AlgorithmByOID(HashingAlgorithmOID, AlgorithmsIDs, True);
		
		SignAlgorithmDoesNotComplyWithGOST = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thuật toán %1 mà được chỉ ra trong chữ ký, không tương ứng với tiêu chuẩn, bởi vì cần chỉ ra %2 mà tương ứng với thuật toán băm %3.';
				|ru = 'Алгоритм %1, указанный в подписи, не соответствует стандарту, так как должен быть указан %2, соответствующий алгоритму хеширования %3.';
				|en = 'The %1 algorithm specified in the signature does not comply with the standard. Specify the %2 algorithm that corresponds to the %3 hashing algorithm.'; fa = 'The %1 algorithm specified in the signature does not comply with the standard. Specify the %2 algorithm that corresponds to the %3 hashing algorithm.';
				|it = 'Алгоритм %1, указанный в подписи, не соответствует стандарту, так как должен быть указан %2, соответствующий алгоритму хеширования %3.';
				|pl = 'The %1 algorithm specified in the signature does not comply with the standard. Specify the %2 algorithm that corresponds to the %3 hashing algorithm.';
				|tr = 'İmzada belirtilen %1 algoritması standarda uymamaktadır çünkü %3 karma algoritmasına karşılık gelen %2 belirtilmelidir.'"),
			AlgorithmIncorrect, AlgorithmCorrect, HashAlgorithm);
		SignatureAlgorithmOID = SignatureRelatedOID;
	EndIf;
	
	If OIDOnly Then
		Return SignatureAlgorithmOID;
	EndIf;
	
	Return SignAlgorithmPresentation(SignatureAlgorithmOID, IsCertificateData, IncludingOID);
	
EndFunction

Function SignAlgorithmPresentation(SignatureAlgorithmOID, IsCertificateData, IncludingOID) Export
	
	AlgorithmsIDs = IDsOfSignatureAlgorithms(IsCertificateData);
	Return AlgorithmByOID(SignatureAlgorithmOID, AlgorithmsIDs, IncludingOID);
	
EndFunction

Function HashAlgorithm(Data, IncludingOID = False) Export
	
	BinaryData = BinaryDataFromTheData(Data,
		"DigitalSignatureInternalClientServer.HashAlgorithm");
	
	DataAnalysis = NewDataAnalysis(BinaryData);
	
	// SEQUENCE (PKCS #7 ContentInfo).
	SkipBlockStart(DataAnalysis, 0, 16);
		// OBJECT IDENTIFIER (contentType).
		SkipBlockStart(DataAnalysis, 0, 6);
			// 1.2.840.113549.1.7.2 signedData (PKCS #7).
			ToCheckTheDataBlock(DataAnalysis, "2A864886F70D010702");
			SkipTheParentBlock(DataAnalysis);
		// [0]CS             (content [0] EXPLICIT ANY DEFINED BY contentType OPTIONAL).
		SkipBlockStart(DataAnalysis, 2, 0);
			// SEQUENCE (content SignedData).
			SkipBlockStart(DataAnalysis, 0, 16);
				// INTEGER  (version          Version).
				SkipBlock(DataAnalysis, 0, 2);
				// SET      (digestAlgorithms DigestAlgorithmIdentifiers).
				SkipBlock(DataAnalysis, 0, 17);
				// SEQUENCE (contentInfo      ContentInfo).
				SkipBlock(DataAnalysis, 0, 16);
				// [0]CS    (certificates     [0] IMPLICIT ExtendedCertificatesAndCertificates OPTIONAL).
				SkipBlock(DataAnalysis, 2, 0, False);
				// [1]CS    (crls             [1] IMPLICIT CertificateRevocationLists OPTIONAL).
				SkipBlock(DataAnalysis, 2, 1, False);
				// SET      (signerInfos      SET OF SignerInfo).
				SkipBlockStart(DataAnalysis, 0, 17);
					// SEQUENCE (signerInfo SignerInfo).
					SkipBlockStart(DataAnalysis, 0, 16);
						// INTEGER  (version                   Version).
						SkipBlock(DataAnalysis, 0, 2);
						// SEQUENCE (issuerAndSerialNumber     IssuerAndSerialNumber).
						SkipBlock(DataAnalysis, 0, 16);
						// SEQUENCE (digestAlgorithm           DigestAlgorithmIdentifier).
						SkipBlockStart(DataAnalysis, 0, 16);
							// OBJECT IDENTIFIER (algorithm).
							SkipBlockStart(DataAnalysis, 0, 6);
	
	HashingAlgorithmOID = ReadOID(DataAnalysis);
	If DataAnalysis.HasError Then
		Return "";
	EndIf;
	
	AlgorithmsIDs = TheIdentifiersOfTheHashAlgorithms();
	Algorithm = AlgorithmByOID(HashingAlgorithmOID, AlgorithmsIDs, IncludingOID);
	
	Return Algorithm;
	
EndFunction

Function EncryptedFileEncryptAlgorithm(Data) Export
	
	AlgorithmInfo = New Structure("Presentation, Id", "", "");
	
	BinaryData = BinaryDataFromTheData(Data,
		"DigitalSignatureInternalClientServer.EncryptedFileEncryptAlgorithm");
	
	DataAnalysis = NewDataAnalysis(BinaryData);
	
	// SEQUENCE (PKCS #7 ContentInfo).
	SkipBlockStart(DataAnalysis, 0, 16);
		// OBJECT IDENTIFIER (contentType).
		SkipBlockStart(DataAnalysis, 0, 6);
			// 1.2.840.113549.1.7.3 envelopedData (PKCS #7).
			ToCheckTheDataBlock(DataAnalysis, "2A864886F70D010703");
			SkipTheParentBlock(DataAnalysis);
		// [0]CS             (content [0] EXPLICIT ANY DEFINED BY contentType OPTIONAL).
		SkipBlockStart(DataAnalysis, 2, 0);
			// SEQUENCE (content envelopedData).
			SkipBlockStart(DataAnalysis, 0, 16);
				// INTEGER  (version          Version).
				SkipBlock(DataAnalysis, 0, 2);
				// SET      (recipientInfos recipientInfos).
				SkipBlock(DataAnalysis, 0, 17);
				// SEQUENCE (content encryptedContentInfo).
				SkipBlockStart(DataAnalysis, 0, 16);
					// OBJECT IDENTIFIER (contentType).
					SkipBlock(DataAnalysis, 0, 6);
					// SEQUENCE (content contentEncryptionAlgorithm).
					SkipBlockStart(DataAnalysis, 0, 16);
						// OBJECT IDENTIFIER (algorithm).
						SkipBlockStart(DataAnalysis, 0, 6);
	
	EncryptAlgorithmOID = ReadOID(DataAnalysis);
	If DataAnalysis.HasError Then
		Return AlgorithmInfo;
	EndIf;
	
	AlgorithmInfo.Id = EncryptAlgorithmOID;
	
	AlgorithmsIDs = EncryptAlgorithmsIDs();
	
	AlgorithmName = AlgorithmsIDs.Get(EncryptAlgorithmOID);
	If ValueIsFilled(AlgorithmName) Then
		AlgorithmInfo.Presentation = StrSplit(AlgorithmName, ",", False)[0];
	EndIf;
	
	Return AlgorithmInfo;
	
EndFunction

// Intended for: DownloadRevocationListFileAtServer procedure and the BeforeWrite check in the CertificateRevocationLists register.
Function RevocationListProperties(Data) Export
	
	BinaryData = BinaryDataFromTheData(
		Data, "DigitalSignatureInternal.RevocationListProperties");
	
	DataAnalysis = NewDataAnalysis(BinaryData);
	
	Result = New Structure("StartDate, EndDate, NextPublicationDate, CertificateAuthorityKeyID");
	
	// SEQUENCE (CertificateList).
		SkipBlockStart(DataAnalysis, 0, 16);
			// SEQUENCE (TBSCertList).
			SkipBlockStart(DataAnalysis, 0, 16);
				// INTEGER  (version          Version).
				SkipBlock(DataAnalysis, 0, 2);
				// SEQUENCE (signature            AlgorithmIdentifier).
				SkipBlock(DataAnalysis, 0, 16);
				// SEQUENCE (issuer               Name).
				SkipBlock(DataAnalysis, 0, 16);
				
				If DataAnalysis.HasError Then
					Return Undefined;
				EndIf;
				
				// UTC TIME (thisUpdate).
				Result.StartDate = ReadDateFromClipboard(DataAnalysis.Buffer, DataAnalysis.Offset);
				// UTC TIME (nextUpdate).
				Result.EndDate = ReadDateFromClipboard(DataAnalysis.Buffer, DataAnalysis.Offset + 15);
				
				// SEQUENCE (thisUpdate              Time).
				SkipBlock(DataAnalysis, 0, 23);
				// SEQUENCE (nextUpdate              Time).
				SkipBlock(DataAnalysis, 0, 23, False);
				// SEQUENCE (revokedCertificates).
				SkipBlock(DataAnalysis, 0, 16, False);
				// [0]crlExtensions                  contentType OPTIONAL).
				SkipBlockStart(DataAnalysis, 2, 0);
				
				If DataAnalysis.HasError Then
					Return Result;
				EndIf;

				// SEQUENCE OF
				SkipBlockStart(DataAnalysis, 0, 16);
				OffsetOfTheFollowing = DataAnalysis.Parents[0].OffsetOfTheFollowing;
				While DataAnalysis.Offset < OffsetOfTheFollowing Do
					// SEQUENCE (extension).
					SkipBlockStart(DataAnalysis, 0, 16);
					If DataAnalysis.HasError Then
						Return Result;
					EndIf;
					
						// OBJECT IDENTIFIER
						SkipBlockStart(DataAnalysis, 0, 6);
							
						DataSize = DataAnalysis.Parents[0].DataSize;
						If DataSize = 0 Then
							Return Result;
						EndIf;
						
						If DataSize = 3 Then
							Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
							BufferString = GetHexStringFromBinaryDataBuffer(Buffer);
							SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER
							If BufferString = "551D23" Then // 2.5.29.35 authorityKeyIdentifier
								FillCertificateAuthorityKeyID(BlockRead(DataAnalysis, 0, 4, True), Result);
							EndIf;
						ElsIf DataSize = 9 Then
							Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
							BufferString = GetHexStringFromBinaryDataBuffer(Buffer);
							SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER
							If BufferString = "2B0601040182371504" Then // 1.3.6.1.4.1.311.21.4 crlNextPublish
								Result.NextPublicationDate = ReadDateFromClipboard(DataAnalysis.Buffer, DataAnalysis.Offset + 2);
							EndIf;
						Else
							SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER
						EndIf;
						
					SkipTheParentBlock(DataAnalysis); // SEQUENCE
				EndDo;
	
	Return Result;
	
EndFunction

Function BinaryDataFromTheData(Data, FunctionName) Export
	
	ExpectedTypes = New Array;
	ExpectedTypes.Add(Type("BinaryData"));
	ExpectedTypes.Add(Type("String"));
	CommonClientServer.CheckParameter(
		FunctionName,
		"Data", Data, ExpectedTypes);
	
	If TypeOf(Data) = Type("String") Then
		If IsTempStorageURL(Data) Then
			BinaryData = GetFromTempStorage(Data);
		Else
			CommonClientServer.Validate(False,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Địa chỉ kho chứa tạm thời không hợp lệ trong tham số Dữ liệu:
					           |%1';
					           |ru = 'Недопустимый адрес временного хранилища в параметре Данные:
					           |%1';
					           |en = 'Incorrect address of a temporary storage in the Data parameter:
					           |%1'; fa = 'Incorrect address of a temporary storage in the Data parameter:
					           |%1';
					           |it = 'Indirizzo di archivio temporaneo non valido nel parametro Dati: 
					           |%1';
					           |pl = 'Niedopuszczalny adres repozytorium tymczasowego w parametrze Dane:
					           |%1';
					           |tr = 'Veriler parametresinde geçici depolama adresi hatalı:
					           |%1'") + Chars.LF, Data),
				FunctionName);
		EndIf;
		If TypeOf(BinaryData) <> Type("BinaryData") Then
			CommonClientServer.Validate(False,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Kiểu giá trị không hợp lệ ""%1""
					           |theo địa chỉ của kho chứa tạm thời được chỉ định trong tham số Dữ liệu';
					           |ru = 'Недопустимый тип значения ""%1""
					           |по адресу временного хранилища, указанному в параметре Данные';
					           |en = 'Invalid type of the ""%1"" value
					           |at the temporary storage address specified in the Data parameter'; fa = 'Invalid type of the ""%1"" value
					           |at the temporary storage address specified in the Data parameter';
					           |it = 'Tipo di valore ""%1""
					           | non disponibile per l''indirizzo di deposito temporaneo indicato nel parametro Dati';
					           |pl = 'Niedopuszczalny typ wartości ""%1""
					           |pod adresem repozytorium tymczasowego, podanego w parametrze Dane';
					           |tr = 'Veriler parametresinde belirtilen geçici depolama adresinde geçersiz değer türü ""%1""
					           |'") + Chars.LF,
					String(TypeOf(BinaryData))),
				FunctionName);
		EndIf;
	Else
		BinaryData = Data;
	EndIf;
	
	Return BinaryData;
	
EndFunction

// Returns:
//  Structure:
//   * HasError - Boolean
//   * ThisIsAnASN1EncodingError - Boolean
//   * ThisIsADataStructureError - Boolean
//   * Offset - Number
//   * Parents - Array of Structure
//   * Buffer - BinaryDataBuffer
// 
Function NewDataAnalysis(BinaryData) Export
	
	DataAnalysis = New Structure;
	DataAnalysis.Insert("HasError", False);
	DataAnalysis.Insert("ThisIsAnASN1EncodingError", False); // Data might be corrupted.
	DataAnalysis.Insert("ThisIsADataStructureError", False); // An expected data item is not found.
	DataAnalysis.Insert("Offset", 0);
	DataAnalysis.Insert("Parents", New Array);
	DataAnalysis.Insert("Buffer", GetBinaryDataBufferFromBinaryData(BinaryData));
	
	Return DataAnalysis;
	
EndFunction

Function AlgorithmByOID(AlgorithmOID, AlgorithmsIDs, IncludingOID)
	
	AlgorithmName = AlgorithmsIDs.Get(AlgorithmOID);
	
	If AlgorithmName = Undefined Then
		If IncludingOID Then
			Return NStr("vi = 'Không xác định';
						|ru = 'Неизвестный';
						|en = 'Unknown'; fa = 'نامشخص';
						|it = 'Sconosciuto';
						|pl = 'Unknown';
						|tr = 'Bilinmeyen'") + " (OID " + AlgorithmOID + ")";
		EndIf;
		Return "";
	ElsIf IncludingOID Then
		Return StrSplit(AlgorithmName, ",", False)[0] + " (OID " + AlgorithmOID + ")";
	Else
		Return AlgorithmName;
	EndIf;
	
EndFunction

Function BlockRead(DataAnalysis, DataClass = Undefined, DataType = Undefined, RequiredBlock = False)
	
	If DataAnalysis.Parents.Count() > 0
		And DataAnalysis.Offset >= DataAnalysis.Parents[0].OffsetOfTheFollowing Then
		Return Undefined;
	EndIf;
	
	Offset = DataAnalysis.Offset;
	
	SkipTheBeginningOfABlockOrBlock(DataAnalysis, True, DataClass, DataType, RequiredBlock);
	If DataAnalysis.Offset = Offset Then
		Return Undefined;
	EndIf;
	
	BlockSize = DataAnalysis.Offset - Offset + DataAnalysis.Parents[0].DataSize;
	
	Buffer = DataAnalysis.Buffer.Read(Offset, BlockSize); // BinaryDataBuffer
	BlockRead = GetBinaryDataFromBinaryDataBuffer(Buffer);
	SkipTheParentBlock(DataAnalysis);
	
	Return BlockRead;
	
EndFunction

Function SkipBlockStart(DataAnalysis, DataClass = Undefined, DataType = Undefined, RequiredBlock = True) Export
	
	Offset = DataAnalysis.Offset;
	SkipTheBeginningOfABlockOrBlock(DataAnalysis, True, DataClass, DataType, RequiredBlock);
	
	Return DataAnalysis.Offset <> Offset;
	
EndFunction

Procedure SkipBlock(DataAnalysis, DataClass = Undefined, DataType = Undefined, RequiredBlock = True) Export
	
	If DataAnalysis.HasError Then
		Return;
	EndIf;
	
	If DataAnalysis.Parents.Count() = 0
	 Or Not DataAnalysis.Parents[0].HasAttachments Then
		
		WhenADataStructureErrorOccurs(DataAnalysis);
		Return;
	EndIf;
	
	SkipTheBeginningOfABlockOrBlock(DataAnalysis, False, DataClass, DataType, RequiredBlock)
	
EndProcedure

Procedure SkipTheParentBlock(DataAnalysis) Export
	
	If DataAnalysis.HasError Then
		Return;
	EndIf;
	
	If DataAnalysis.Parents.Count() < 2
	 Or Not DataAnalysis.Parents[1].HasAttachments Then
		
		WhenADataStructureErrorOccurs(DataAnalysis);
		Return;
	EndIf;
	
	If DataAnalysis.Parents[0].DataSize > 0 Then
		BytesLeft = DataAnalysis.Parents[0].OffsetOfTheFollowing - DataAnalysis.Offset;
		
		If BytesLeft > 0 Then
			ReadByte(DataAnalysis, BytesLeft);
			If DataAnalysis.HasError Then
				Return;
			EndIf;
		ElsIf BytesLeft < 0 Then
			IfTheEncodingErrorIsASN1(DataAnalysis);
			Return;
		EndIf;
	Else
		While True Do
			If EndOfABlockOfIndeterminateLength(DataAnalysis) Then
				If DataAnalysis.HasError Then
					Return;
				EndIf;
				DataAnalysis.Offset = DataAnalysis.Offset + 2;
				Break;
			EndIf;
			SkipBlock(DataAnalysis);
		EndDo;
	EndIf;
	
	DataAnalysis.Parents.Delete(0);
	
EndProcedure

Procedure ToCheckTheDataBlock(DataAnalysis, DataString1)
	
	If DataAnalysis.HasError Then
		Return;
	EndIf;
	
	If DataAnalysis.Parents.Count() = 0 Then
		WhenADataStructureErrorOccurs(DataAnalysis);
		Return;
	EndIf;
	
	DataSize = DataAnalysis.Parents[0].DataSize;
	If DataSize = 0 Then
		WhenADataStructureErrorOccurs(DataAnalysis);
		Return;
	EndIf;
	Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
	
	If Buffer.Size <> DataSize Then
		IfTheEncodingErrorIsASN1(DataAnalysis);
		Return;
	EndIf;
	DataAnalysis.Offset = DataAnalysis.Offset + DataSize;
	
	BufferString = GetHexStringFromBinaryDataBuffer(Buffer);
	If DataString1 <> BufferString Then
		WhenADataStructureErrorOccurs(DataAnalysis);
		Return;
	EndIf;
	
EndProcedure

Function ReadOID(DataAnalysis)
	
	If DataAnalysis.HasError Then
		Return Undefined;
	EndIf;
	
	If DataAnalysis.Parents.Count() = 0 Then
		WhenADataStructureErrorOccurs(DataAnalysis);
		Return Undefined;
	EndIf;
	
	Integers = New Array;
	DataSize = DataAnalysis.Parents[0].DataSize;
	If DataSize = 0 Then
		WhenADataStructureErrorOccurs(DataAnalysis);
		Return Undefined;
	EndIf;
	OffsetBoundary = DataAnalysis.Offset + DataSize;
	
	While DataAnalysis.Offset < OffsetBoundary Do
		Integer1 = ToReadTheWholeStream(DataAnalysis);
		If DataAnalysis.HasError Then
			Return Undefined;
		EndIf;
		Integers.Add(Integer1);
	EndDo;
	
	If DataAnalysis.Offset <> OffsetBoundary
	 Or Integers.Count() = 0 Then
		
		IfTheEncodingErrorIsASN1(DataAnalysis);
		Return Undefined;
	EndIf;
	
	SidNumber2 = Integers[0];
	If SidNumber2 < 40 Then
		SID1 = 0;
	ElsIf SidNumber2 < 80 Then
		SID1 = 1;
	Else
		SID1 = 2;
	EndIf;
	Integers[0] = SidNumber2 - SID1*40;
	Integers.Insert(0, SID1);
	
	StringsOfNumbers = New Array;
	For Each Integer1 In Integers Do
		StringsOfNumbers.Add(Format(Integer1, "NZ=0; NG="));
	EndDo;
	
	Return StrConcat(StringsOfNumbers, ".");
	
EndFunction

Procedure SkipTheBeginningOfABlockOrBlock(DataAnalysis, StartOfTheBlock,
			TheRequiredDataClass, RequiredDataType, RequiredBlock)
	
	If DataAnalysis.Parents.Count() > 0
	   And DataAnalysis.Offset >= DataAnalysis.Parents[0].OffsetOfTheFollowing Then
	
		WhenADataStructureErrorOccurs(DataAnalysis);
		Return;
	EndIf;
	
	TheDisplacementOfTheBlock = DataAnalysis.Offset;
	Byte = ReadByte(DataAnalysis);
	If DataAnalysis.HasError Then
		Return;
	EndIf;
	
	DataClass = BitwiseShiftRight(Byte, 6);
	DataType = Byte - DataClass * 64;
	HasAttachments = False;
	
	If DataType > 31 Then
		HasAttachments = True;
		DataType = DataType - 32;
	EndIf;
	
	If DataType > 30 Then
		DataType = ToReadTheWholeStream(DataAnalysis);
		If DataAnalysis.HasError Then
			Return;
		EndIf;
	EndIf;
	
	If TheRequiredDataClass <> Undefined
	   And TheRequiredDataClass <> DataClass
	 Or RequiredDataType <> Undefined
	   And RequiredDataType <> DataType Then
	
		If RequiredBlock Then
			WhenADataStructureErrorOccurs(DataAnalysis);
		Else
			DataAnalysis.Offset = TheDisplacementOfTheBlock;
		EndIf;
		Return;
	EndIf;
	
	DataSize = ToReadTheSizeData(DataAnalysis);
	If DataAnalysis.HasError Then
		Return;
	EndIf;
	
	If StartOfTheBlock Or HasAttachments And DataSize = 0 Then
		If DataSize = 0 Then
			If DataAnalysis.Parents.Count() = 0 Then
				If Not EndOfABlockOfIndeterminateLength(DataAnalysis, True) Then
					IfTheEncodingErrorIsASN1(DataAnalysis);
					Return;
				EndIf;
				OffsetOfTheFollowing = DataAnalysis.Buffer.Size - 2;
				DataSize = OffsetOfTheFollowing - DataAnalysis.Offset;
			Else
				// For a block of undefined length, NextOffset is a border.
				OffsetOfTheFollowing = DataAnalysis.Parents[0].OffsetOfTheFollowing;
			EndIf;
		Else
			OffsetOfTheFollowing = DataAnalysis.Offset + DataSize;
			If DataAnalysis.Parents.Count() = 0
			   And OffsetOfTheFollowing > DataAnalysis.Buffer.Size Then
				
				IfTheEncodingErrorIsASN1(DataAnalysis);
				Return;
			EndIf;
		EndIf;
		CurrentBlock = New Structure("HasAttachments, OffsetOfTheFollowing, DataSize",
			HasAttachments, OffsetOfTheFollowing, DataSize);
		DataAnalysis.Parents.Insert(0, CurrentBlock);
		If Not StartOfTheBlock Then
			SkipTheParentBlock(DataAnalysis);
		EndIf;
	Else
		If DataSize = 0 Then
			ReadTheEndOfABlockWithoutAttachmentsOfIndeterminateLength(DataAnalysis);
		Else
			ReadByte(DataAnalysis, DataSize);
		EndIf;
		If DataAnalysis.HasError Then
			Return;
		EndIf;
	EndIf;
	
EndProcedure

Function EndOfABlockOfIndeterminateLength(DataAnalysis, CommonBlock = False)
	
	Buffer = DataAnalysis.Buffer;
	
	If CommonBlock Then
		
		UnwantedTrailingCharacters = 0;
		While Buffer[Buffer.Size - UnwantedTrailingCharacters -1] <> 0 And UnwantedTrailingCharacters < Buffer.Size Do
			UnwantedTrailingCharacters = UnwantedTrailingCharacters + 1;
		EndDo;
		
		Offset = Buffer.Size - UnwantedTrailingCharacters - 2;
		If Offset < 2 Then
			IfTheEncodingErrorIsASN1(DataAnalysis);
			Return False;
		EndIf;
		
	Else
		Offset = DataAnalysis.Offset;
		If Offset + 2 > DataAnalysis.Parents[0].OffsetOfTheFollowing Then
			IfTheEncodingErrorIsASN1(DataAnalysis);
			Return False;
		EndIf;
	EndIf;
	
	Return Buffer[Offset] = 0 And Buffer[Offset + 1] = 0;
	
EndFunction

Procedure ReadTheEndOfABlockWithoutAttachmentsOfIndeterminateLength(DataAnalysis)
	
	ThePreviousByte = -1;
	Byte = -1;
	
	While True Do
		ThePreviousByte = Byte;
		Byte = ReadByte(DataAnalysis);
		If DataAnalysis.HasError Then
			Return;
		EndIf;
		If Byte = 0 And ThePreviousByte = 0 Then
			Break;
		EndIf;
	EndDo;
	
EndProcedure

Function ToReadTheWholeStream(DataAnalysis) Export
	
	Integer = 0;
	For Counter = 1 To 9 Do
		Byte = ReadByte(DataAnalysis);
		If DataAnalysis.HasError Then
			Return Undefined;
		EndIf;
		If Byte < 128 Then
			Integer = Integer * 128 + Byte;
			Break;
		Else
			Integer = Integer * 128 + (Byte - 128);
		EndIf;
	EndDo;
	
	If Counter > 8 Then
		IfTheEncodingErrorIsASN1(DataAnalysis);
		Return Undefined;
	EndIf;
	
	Return Integer;
	
EndFunction

Function ToReadTheSizeData(DataAnalysis)
	
	Byte = ReadByte(DataAnalysis);
	If DataAnalysis.HasError Then
		Return Undefined;
	EndIf;
	
	If Byte < 128 Then
		Return Byte;
	EndIf;
	
	NumberOfBytes = Byte - 128;
	If NumberOfBytes = 0 Or NumberOfBytes > 8 Then
		If Byte = 128 Then
			Return 0; // Block of undefined length.
		EndIf;
		IfTheEncodingErrorIsASN1(DataAnalysis);
		Return Undefined;
	EndIf;
	
	Integer = 0;
	For Counter = 1 To NumberOfBytes Do
		Byte = ReadByte(DataAnalysis);
		If DataAnalysis.HasError Then
			Return Undefined;
		EndIf;
		Integer = Integer * 256 + Byte;
	EndDo;
	
	Return Integer;
	
EndFunction

Function ReadByte(DataAnalysis, TimesCount = 1)
	
	If DataAnalysis.HasError Then
		Return Undefined;
	EndIf;
	
	If DataAnalysis.Offset + TimesCount <= DataAnalysis.Buffer.Size Then
		Byte = DataAnalysis.Buffer.Get(DataAnalysis.Offset + TimesCount - 1);
		DataAnalysis.Offset = DataAnalysis.Offset + TimesCount;
	Else
		Byte = Undefined;
		IfTheEncodingErrorIsASN1(DataAnalysis);
	EndIf;
	
	Return Byte;
	
EndFunction

Procedure IfTheEncodingErrorIsASN1(DataAnalysis)
	
	DataAnalysis.ThisIsAnASN1EncodingError = True;
	DataAnalysis.HasError = True;
	
EndProcedure

Procedure WhenADataStructureErrorOccurs(DataAnalysis)
	
	DataAnalysis.ThisIsADataStructureError = True;
	DataAnalysis.HasError = True;
	
EndProcedure

Function EncryptAlgorithmsIDs()
	
	AlgorithmsIDs = New Map;
	
	Sets = New Array;
	
	DigitalSignatureClientServerLocalization.OnSetEncryptAlgorithmsSets(Sets);
	
	For Each Set In Sets Do
		AlgorithmsIDs.Insert(Set.EncryptAlgorithmID,
			StrConcat(Set.EncryptAlgorithmNames, ", "));
	EndDo;
	
	Return AlgorithmsIDs;
	
EndFunction

Function IDsOfSignatureAlgorithms(PublicKeyAlgorithmsOnly)
	
	AlgorithmsIDs = New Map;
	
	Sets = SetsOfAlgorithmsForCreatingASignature();
	For Each Set In Sets Do
		AlgorithmsIDs.Insert(Set.IDOfThePublicKeyAlgorithm,
			StrConcat(Set.SignatureAlgorithmNames, ", "));
		
		If PublicKeyAlgorithmsOnly Then
			Continue;
		EndIf;
		
		AlgorithmsIDs.Insert(Set.IDOfTheSignatureAlgorithm,
			StrConcat(Set.SignatureAlgorithmNames, ", "));
		
		If ValueIsFilled(Set.IDOfTheExchangeAlgorithm) Then
			AlgorithmsIDs.Insert(Set.IDOfTheExchangeAlgorithm,
				StrConcat(Set.SignatureAlgorithmNames, ", "));
		EndIf;
	EndDo;
	
	Return AlgorithmsIDs;
	
EndFunction

Function TheIdentifiersOfTheHashAlgorithms()
	
	AlgorithmsIDs = New Map;
	
	Sets = SetsOfAlgorithmsForCreatingASignature();
	For Each Set In Sets Do
		AlgorithmsIDs.Insert(Set.IdOfTheHashingAlgorithm,
			StrConcat(Set.HashAlgorithmNames, ", "));
	EndDo;
	
	Return AlgorithmsIDs;
	
EndFunction

// Returns:
//  Array of See ANewSetOfAlgorithmsForCreatingASignature
//
Function SetsOfAlgorithmsForCreatingASignature() Export
	
	Sets = New Array;
	
	// md2WithRSAEncryption
	Properties = ANewSetOfAlgorithmsForCreatingASignature();
	Properties.IDOfThePublicKeyAlgorithm = "1.2.840.113549.1.1.1";
	Properties.IDOfTheSignatureAlgorithm        = "1.2.840.113549.1.1.2";
	Properties.SignatureAlgorithmNames                = CommonClientServer.ValueInArray("RSA_SIGN");
	Properties.IdOfTheHashingAlgorithm    = "1.2.840.113549.2.2";
	Properties.HashAlgorithmNames            = CommonClientServer.ValueInArray("MD2");
	Properties.NameOfTheXMLSignatureAlgorithm     = "";
	Properties.NameOfTheXMLHashingAlgorithm = "";
	Sets.Add(Properties);
	
	// md4withRSAEncryption
	Properties = ANewSetOfAlgorithmsForCreatingASignature();
	Properties.IDOfThePublicKeyAlgorithm = "1.2.840.113549.1.1.1";
	Properties.IDOfTheSignatureAlgorithm        = "1.2.840.113549.1.1.3";
	Properties.SignatureAlgorithmNames                = CommonClientServer.ValueInArray("RSA_SIGN");
	Properties.IdOfTheHashingAlgorithm    = "1.2.840.113549.2.4";
	Properties.HashAlgorithmNames            = CommonClientServer.ValueInArray("MD4");
	Properties.NameOfTheXMLSignatureAlgorithm     = "";
	Properties.NameOfTheXMLHashingAlgorithm = "";
	Sets.Add(Properties);
	
	// md5WithRSAEncryption
	Properties = ANewSetOfAlgorithmsForCreatingASignature();
	Properties.IDOfThePublicKeyAlgorithm = "1.2.840.113549.1.1.1";
	Properties.IDOfTheSignatureAlgorithm        = "1.2.840.113549.1.1.4";
	Properties.SignatureAlgorithmNames                = CommonClientServer.ValueInArray("RSA_SIGN");
	Properties.IdOfTheHashingAlgorithm    = "1.2.840.113549.2.5";
	Properties.HashAlgorithmNames            = CommonClientServer.ValueInArray("MD5");
	Properties.NameOfTheXMLSignatureAlgorithm     = "";
	Properties.NameOfTheXMLHashingAlgorithm = "";
	Sets.Add(Properties);
	
	// sha1WithRSAEncryption
	Properties = ANewSetOfAlgorithmsForCreatingASignature();
	Properties.IDOfThePublicKeyAlgorithm = "1.2.840.113549.1.1.1";
	Properties.IDOfTheSignatureAlgorithm        = "1.2.840.113549.1.1.5";
	Properties.SignatureAlgorithmNames                = CommonClientServer.ValueInArray("RSA_SIGN");
	Properties.IdOfTheHashingAlgorithm    = "1.3.14.3.2.26";
	Properties.HashAlgorithmNames            = CommonClientServer.ValueInArray("SHA-1");
	Properties.NameOfTheXMLSignatureAlgorithm     = "";
	Properties.NameOfTheXMLHashingAlgorithm = "";
	Sets.Add(Properties);
	
	// sha256WithRSAEncryption
	Properties = ANewSetOfAlgorithmsForCreatingASignature();
	Properties.IDOfThePublicKeyAlgorithm = "1.2.840.113549.1.1.1";
	Properties.IDOfTheSignatureAlgorithm        = "1.2.840.113549.1.1.11";
	Properties.SignatureAlgorithmNames                = CommonClientServer.ValueInArray("RSA_SIGN");
	Properties.IdOfTheHashingAlgorithm    = "2.16.840.1.101.3.4.2.1";
	Properties.HashAlgorithmNames            = CommonClientServer.ValueInArray("SHA-256");
	Properties.NameOfTheXMLSignatureAlgorithm     = "";
	Properties.NameOfTheXMLHashingAlgorithm = "";
	Sets.Add(Properties);
	
	// sha384WithRSAEncryption
	Properties = ANewSetOfAlgorithmsForCreatingASignature();
	Properties.IDOfThePublicKeyAlgorithm = "1.2.840.113549.1.1.1";
	Properties.IDOfTheSignatureAlgorithm        = "1.2.840.113549.1.1.12";
	Properties.SignatureAlgorithmNames                = CommonClientServer.ValueInArray("RSA_SIGN");
	Properties.IdOfTheHashingAlgorithm    = "2.16.840.1.101.3.4.2.2";
	Properties.HashAlgorithmNames            = CommonClientServer.ValueInArray("SHA-384");
	Properties.NameOfTheXMLSignatureAlgorithm     = "";
	Properties.NameOfTheXMLHashingAlgorithm = "";
	Sets.Add(Properties);
	
	// sha512WithRSAEncryption
	Properties = ANewSetOfAlgorithmsForCreatingASignature();
	Properties.IDOfThePublicKeyAlgorithm = "1.2.840.113549.1.1.1";
	Properties.IDOfTheSignatureAlgorithm        = "1.2.840.113549.1.1.13";
	Properties.SignatureAlgorithmNames                = CommonClientServer.ValueInArray("RSA_SIGN");
	Properties.IdOfTheHashingAlgorithm    = "2.16.840.1.101.3.4.2.3";
	Properties.HashAlgorithmNames            = CommonClientServer.ValueInArray("SHA-512");
	Properties.NameOfTheXMLSignatureAlgorithm     = "";
	Properties.NameOfTheXMLHashingAlgorithm = "";
	Sets.Add(Properties);
	
	DigitalSignatureClientServerLocalization.OnSetAlgorithmSetsToCreateSignature(Sets);
	
	Return Sets;
	
EndFunction

// Returns:
//  Structure:
//   * IDOfThePublicKeyAlgorithm - String
//   * IDOfTheSignatureAlgorithm - String
//   * SignatureAlgorithmNames - Array of String
//   * IdOfTheHashingAlgorithm - String
//   * HashAlgorithmNames - Array of String
//   * NameOfTheXMLSignatureAlgorithm - String
//   * NameOfTheXMLHashingAlgorithm - String
//
Function ANewSetOfAlgorithmsForCreatingASignature() Export
	
	Properties = New Structure;
	Properties.Insert("IDOfThePublicKeyAlgorithm", "");
	Properties.Insert("IDOfTheSignatureAlgorithm", "");
	Properties.Insert("SignatureAlgorithmNames", New Array);
	Properties.Insert("IDOfTheExchangeAlgorithm", "");
	Properties.Insert("IdOfTheHashingAlgorithm", "");
	Properties.Insert("HashAlgorithmNames", New Array);
	Properties.Insert("NameOfTheXMLSignatureAlgorithm", "");
	Properties.Insert("NameOfTheXMLHashingAlgorithm", "");
	
	Return Properties;
	
EndFunction

// Returns:
//  Structure:
//   * EncryptAlgorithmID - String
//   * EncryptAlgorithmNames - Array of String
//
Function NewEncryptAlgorithmsSet() Export
	
	Properties = New Structure;
	Properties.Insert("EncryptAlgorithmID", "");
	Properties.Insert("EncryptAlgorithmNames", New Array);
	
	Return Properties;
	
EndFunction

Function AlgorithmPresentation(SignatureAlgorithmNames)
	UBound = SignatureAlgorithmNames.UBound();
	If UBound = 0 Then
		Return SignatureAlgorithmNames[0];
	Else
		Names = "";
		For N1 = 1 To UBound Do
			Names = Names + SignatureAlgorithmNames[N1] + ?(N1 = UBound, "", ", ");
		EndDo;
		Return SignatureAlgorithmNames[0] + " (" + Names + ")";
	EndIf;
EndFunction

Function SignAlgorithmRelatedToHashAlgorithmGOST(HashAlgorithm)
	
	If Not ValueIsFilled(HashAlgorithm) Then
		Return Undefined;
	EndIf;
	
	Map = New Map;
	Map.Insert("1.2.643.7.1.1.2.2", "1.2.643.7.1.1.1.1");
	Map.Insert("1.2.643.7.1.1.2.3", "1.2.643.7.1.1.1.2");
	
	Return Map.Get(HashAlgorithm);
		
EndFunction

Function IsCertificateExists(CryptoCertificate) Export
	
	If CryptoCertificate = Undefined Then
		Return False;
	EndIf;
	
	Try
		// Raise an exception if the certificate is not initialized. For example, if the certificate is missing from the signature container.
		SerialNumber = CryptoCertificate.SerialNumber;
		Return True;
	Except
		Return False;
	EndTry;
	
EndFunction

#EndRegion

#EndRegion