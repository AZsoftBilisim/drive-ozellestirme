///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Function StampsParameters(DigitalSignatures, MarksTexts = Undefined) Export
	
	ActionPeriodTemplate = NStr("ru = 'с %1 по %2';
								|vi = 'from %1 to %2';
								|en = 'from %1 to %2'; fa = 'from %1 to %2';
								|it = 'from %1 to %2';
								|pl = 'from %1 to %2';
								|tr = '%1 itibaren %2 kadar'");
	IndexOf = 0;
	StampsParameters = New Array;
	Certificates = New Array;
	
	ModuleMachineReadableLettersOfAuthorityFTSInternal = Undefined;
	ModuleFilesOperationsOverridable = Undefined;
	ModuleOrganizationServer = Undefined;
	If Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		ModuleMachineReadableLettersOfAuthorityFTSInternal = Common.CommonModule("MachineReadableLettersOfAuthorityFTSInternal");
	EndIf;
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsOverridable = Common.CommonModule("FilesOperationsOverridable");
	EndIf;
	If Common.SubsystemExists("StandardSubsystems.Companies") Then
		ModuleOrganizationServer = Common.CommonModule("CompaniesServer");
	EndIf;
	
	For Each Signature In DigitalSignatures Do
		
		StampParameters = New Structure;
		StampParameters.Insert("DateSignedFromLabels");
		StampParameters.Insert("SignatureDate");
		
		FillPropertyValues(StampParameters, Signature);
		
		StampParameters.Insert("MarkText", ?(MarksTexts <> Undefined, MarksTexts[IndexOf], Undefined));
		StampParameters.Insert("CompanyLogo", Undefined);
		StampParameters.Insert("CertificateNumber", "");
		StampParameters.Insert("CertificateIssuedBy", "");
		StampParameters.Insert("CertificateRecipient", "");
		StampParameters.Insert("ValidityPeriod", "");
		StampParameters.Insert("StampText", "");
		
		If Signature.Certificate = Undefined Then
			Certificate = Undefined;
			StampParameters.Insert("CertificateRecipient", NStr(
				"ru = 'Сертификат подписанта отсутствует в подписи';
				|vi = 'Signer certificate is missing from the signature';
				|en = 'Signer certificate is missing from the signature'; fa = 'Signer certificate is missing from the signature';
				|it = 'Signer certificate is missing from the signature';
				|pl = 'Signer certificate is missing from the signature';
				|tr = 'İmza sahibi sertifikası imzada bulunmuyor'"));
				
			ErrorText = ?(Signature.SignatureFileName = "", NStr(
				"ru = 'Сертификат подписанта отсутствует в подписи и не найден в локальном хранилище.';
				|vi = 'The certificate is not found in the signature or the local certificate store.';
				|en = 'The certificate is not found in the signature or the local certificate store.'; fa = 'The certificate is not found in the signature or the local certificate store.';
				|it = 'The certificate is not found in the signature or the local certificate store.';
				|pl = 'The certificate is not found in the signature or the local certificate store.';
				|tr = 'İmzalayanın sertifikası imzada bulunmuyor ve yerel depolamada bulunamadı.'"),
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Сертификат подписанта отсутствует в подписи ""%1"" и не найден в локальном хранилище.';
						|vi = 'The certificate is not found in the ""%1"" signature or the local certificate store.';
						|en = 'The certificate is not found in the ""%1"" signature or the local certificate store.'; fa = 'The certificate is not found in the ""%1"" signature or the local certificate store.';
						|it = 'The certificate is not found in the ""%1"" signature or the local certificate store.';
						|pl = 'The certificate is not found in the ""%1"" signature or the local certificate store.';
						|tr = 'İmzalayanın sertifikası ""%1"" imzasında bulunmuyor ve yerel depolamada bulunamadı.'"),
				Signature.SignatureFileName));
			WriteLogEvent(
				NStr("ru = 'Электронная подпись.Получение штампов визуализации электронных подписей';
					|vi = 'Digital signature.Get digital signature visualization stamps';
					|en = 'Digital signature.Get digital signature visualization stamps'; fa = 'Digital signature.Get digital signature visualization stamps';
					|it = 'Digital signature.Get digital signature visualization stamps';
					|pl = 'Digital signature.Get digital signature visualization stamps';
					|tr = 'Dijital imza. Dijital imzaların görselleştirme damgalarının alınması'",
				Common.DefaultLanguageCode()), EventLogLevel.Error,,, ErrorText);
		Else
			Certificate = ?(TypeOf(Signature.Certificate) = Type("CryptoCertificate"), // for backward compatibility
				Signature.Certificate, New CryptoCertificate(Signature.Certificate));
			CertificateProperties = DigitalSignature.CertificateProperties(Certificate);
			
			If ValueIsFilled(StampParameters.DateSignedFromLabels) And (StampParameters.DateSignedFromLabels < CertificateProperties.StartDate
				Or StampParameters.DateSignedFromLabels > CertificateProperties.EndDate) Then
				StampParameters.DateSignedFromLabels = Undefined;
			EndIf;

			ActionPeriod = StringFunctionsClientServer.SubstituteParametersToString(ActionPeriodTemplate, Format(
				CertificateProperties.StartDate, "DLF=D"), Format(CertificateProperties.EndDate, "DLF=D"));
			StampParameters.Insert("CertificateNumber", StrReplace(CertificateProperties.SerialNumber, " ", ""));
			StampParameters.Insert("CertificateIssuedBy", CertificateProperties.IssuedBy);
			StampParameters.Insert("CertificateRecipient", CertificateProperties.IssuedTo);
			StampParameters.Insert("ValidityPeriod", ActionPeriod);
		EndIf;
				
		If ModuleFilesOperationsOverridable <> Undefined And Certificate <> Undefined Then
			
			StampParametersOverride = New Structure;
			StampParametersOverride.Insert("MarkText", StampParameters.MarkText);
			StampParametersOverride.Insert("Logo", StampParameters.CompanyLogo);
			
			ModuleFilesOperationsOverridable.OnPrintFileWithStamp(StampParameters, Certificate); // APK: 222 for backward compatibility
			
			If StampParametersOverride.Logo <> Undefined And StampParameters.CompanyLogo = Undefined Then
				StampParameters.CompanyLogo = StampParametersOverride.Logo;
			EndIf;
			If StampParametersOverride.MarkText <> Undefined And StampParameters.MarkText = Undefined Then
				StampParameters.MarkText = StampParametersOverride.MarkText;
			EndIf;
			
		EndIf;
	
		If ModuleMachineReadableLettersOfAuthorityFTSInternal <> Undefined
			And Signature.Property("ResultOfSignatureVerificationByMRLOA")
			And ValueIsFilled(Signature.ResultOfSignatureVerificationByMRLOA) Then
			
			If IsTempStorageURL(Signature.ResultOfSignatureVerificationByMRLOA) Then
				ResultOfSignatureVerificationByMRLOA = GetFromTempStorage(Signature.ResultOfSignatureVerificationByMRLOA);
			Else
				ResultOfSignatureVerificationByMRLOA = Signature.ResultOfSignatureVerificationByMRLOA;
			EndIf;
			
			If TypeOf(ResultOfSignatureVerificationByMRLOA) = Type("Structure") Then
				ResultOfSignatureVerificationByMRLOA = CommonClientServer.ValueInArray(ResultOfSignatureVerificationByMRLOA);
			EndIf;
			
			If ResultOfSignatureVerificationByMRLOA.Count() > 0 Then
				LOADataForPrinting = ModuleMachineReadableLettersOfAuthorityFTSInternal.LOADataForPrinting(
					ResultOfSignatureVerificationByMRLOA[0].MachineReadableLetterOfAuthority, StampParameters.SignatureDate);
				
				LOAAsString = LOADataForPrinting.LetterOfAuthorityPresentation;
				If StampParameters.CompanyLogo = Undefined Then
					StampParameters.CompanyLogo = LOADataForPrinting.CompanyLogo;
				EndIf;
			Else
				LOAAsString = "";
			EndIf;
		Else
			LOAAsString = "";
		EndIf;
		
		StampParameters.Insert("LetterOfAuthority", LOAAsString);
		
		If ModuleOrganizationServer <> Undefined And StampParameters.CompanyLogo = Undefined Then
			Certificates.Add(Certificate);
		EndIf;
		
		StampsParameters.Add(StampParameters);
		IndexOf = IndexOf + 1;
	EndDo;
	
	If ModuleOrganizationServer <> Undefined And Certificates.Count() > 0 Then
		CertificatesRefs = DigitalSignature.RefsToCertificates(Certificates, True);
		CompaniesRefs = Common.ObjectsAttributeValue(CertificatesRefs, "Organization");
		IndexOf = 0; SignatureIndex = -1;
		For Each StampParameters In StampsParameters Do
			SignatureIndex = SignatureIndex + 1;
			If StampParameters.CompanyLogo <> Undefined Then
				Continue;
			EndIf;
			CertificateReference = CertificatesRefs[IndexOf];
			IndexOf = IndexOf + 1;
			If Not ValueIsFilled(CertificateReference) Then
				Continue;
			EndIf;
			Organization = CompaniesRefs[CertificateReference];
			If Not ValueIsFilled(Organization) Then
				Continue;
			EndIf;
			AdditionalInfo = ModuleOrganizationServer.AdditionalOrganizationInformation(Organization,
				"OrganizationSLogoForAnElectronicSignatureStamp", DigitalSignatures[SignatureIndex].SignatureDate);
			If AdditionalInfo.Property("OrganizationSLogoForAnElectronicSignatureStamp") Then
				StampParameters.CompanyLogo = AdditionalInfo.OrganizationSLogoForAnElectronicSignatureStamp;
			EndIf;
		EndDo;
	EndIf;
	
	For Each StampParameters In StampsParameters Do
		
		StampParameters.SignatureDate = Format(StampParameters.SignatureDate, "DLF=DT;");
		
		StampTextField = New Array;
		AddStampField(StampTextField, NStr("ru = 'Сертификат';
											|vi = 'Certificate';
											|en = 'Certificate'; fa = 'گواهی';
											|it = 'Certificate';
											|pl = 'Certificate';
											|tr = 'Sertifika'"), StampParameters.CertificateNumber);
		AddStampField(StampTextField, NStr("ru = 'Владелец';
											|vi = 'Owner';
											|en = 'Owner'; fa = 'مالک';
											|it = 'Owner';
											|pl = 'Owner';
											|tr = 'Sahip'"), StampParameters.CertificateRecipient);
		AddStampField(StampTextField, NStr("ru = 'Действителен';
											|vi = 'Valid till';
											|en = 'Valid till'; fa = 'معتبر تا';
											|it = 'Valid till';
											|pl = 'Valid till';
											|tr = 'Geçerli'"), StampParameters.ValidityPeriod);
		
		DateSignedFromLabels = "";
		If ValueIsFilled(StampParameters.DateSignedFromLabels) Then
			StampParameters.DateSignedFromLabels = Format(StampParameters.DateSignedFromLabels, "DLF=DT;");
			AddStampField(StampTextField, NStr("ru = 'Дата подписи';
												|vi = 'Date signed';
												|en = 'Date signed'; fa = 'تاریخ امضا';
												|it = 'Date signed';
												|pl = 'Date signed';
												|tr = 'İmza tarihi'"), StampParameters.SignatureDate);
			AddStampField(StampTextField, NStr("ru = 'Метка времени';
												|vi = 'Timestamp';
												|en = 'Timestamp'; fa = 'مهر زمانی';
												|it = 'Timestamp';
												|pl = 'Timestamp';
												|tr = 'Zaman damgası'"), StampParameters.DateSignedFromLabels);
		EndIf;
		
		If ValueIsFilled(StampParameters.LetterOfAuthority) Then
			AddStampField(StampTextField, NStr("ru = 'Доверенность';
												|vi = 'Letter of authority';
												|en = 'Letter of authority'; fa = 'وکالت‌نامه';
												|it = 'Letter of authority';
												|pl = 'Letter of authority';
												|tr = 'Yetki belgesi'"), StampParameters.LetterOfAuthority);
		EndIf;
		
		HeaderLength = 0;
		For Each Item In StampTextField Do
			HeaderLength = Max(HeaderLength, StrLen(Item.Name));
		EndDo;
		
		StampText = New Array;
		
		For Each Item In StampTextField Do
			StampText.Add(Item.Name + ":" + Chars.Tab + Item.Value);
		EndDo;
		StampParameters.StampText = StrConcat(StampText, Chars.LF);
	EndDo;
	
	Return StampsParameters;
	
EndFunction


// For internal use only.
// Verifies the cryptographic certificate.
// Intended only for operation using 1C:Enterprise tools (CryptoManager).
//
// Parameters:
//   CryptoManager - Undefined - get the crypto manager automatically.
//                        - CryptoManager - use the specified crypto manager.
//
//   Certificate           - CryptoCertificate - Certificate.
//                        - BinaryData - certificate binary data.
//                        - String - Temp storage address that contains certificate binary data.
//
//   ErrorDescription       - Null - raise an exception if an error occurs during the check.
//                        - String - Contains error details (if occurred).
//
//   OnDate               - Date - check the certificate on the specified date.
//                          If parameter is not specified or a blank date is specified,
//                          check on the current session date.
//   AdditionalVerificationParameters_ - See AdditionalCertificateVerificationParameters
//
// Returns:
//  Boolean - True if the check is completed successfully.
//           False if the cryptographic manager is not received (because it is not specified).
//
Function CheckCertificate(CryptoManager, Certificate, ErrorDescription = Null, OnDate = Undefined, AdditionalVerificationParameters_ = Undefined) Export
	
	RaiseException1 = ErrorDescription = Null;
	CryptoManagerToCheck = CryptoManager;
	
	CertificateToCheck = Certificate;
	
	If TypeOf(Certificate) = Type("String") Then
		CertificateToCheck = GetFromTempStorage(Certificate);
	EndIf;
	
	If TypeOf(CertificateToCheck) = Type("BinaryData") Then
		CertificateData = CertificateToCheck;
		CertificateToCheck = New CryptoCertificate(CertificateToCheck);
	Else
		CertificateData = CertificateToCheck.Unload();
	EndIf;
	
	If CryptoManagerToCheck = Undefined Then
		UseDigitalSignatureSaaS =
			UseDigitalSignatureSaaS();
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ShowError = RaiseException1 And Not UseDigitalSignatureSaaS;
		
		If DigitalSignatureInternalClientServer.AreCertificateAdditionalPropertiesAvailable() Then
			CreationParameters.SignAlgorithm = DigitalSignatureInternalClientServer.SignAlgorithmPresentation(
				CertificateToCheck.PublicKeyAlgorithm, True, False);
		Else
			If TypeOf(CertificateData) = Type("BinaryData") Then
				CreationParameters.SignAlgorithm =
					DigitalSignatureInternalClientServer.CertificateSignAlgorithm(CertificateData);
			EndIf;
		EndIf;
	
		CryptoManagerToCheck = CryptoManager(
			"CertificateCheck", CreationParameters);
		
		If CryptoManagerToCheck = Undefined Then
			ErrorDescription = CreationParameters.ErrorDescription;
			
			If Not UseDigitalSignatureSaaS Then
				Return False;
			EndIf;
		EndIf;
	EndIf;
	
	AdditionalParameters = AdditionalCertificateVerificationParameters();
	If AdditionalVerificationParameters_ <> Undefined Then
		FillPropertyValues(AdditionalParameters, AdditionalVerificationParameters_);
		
		If TypeOf(AdditionalParameters.PerformCAVerification) = Type("Boolean") Then // Intended for compatibility purposes.
			AdditionalParameters.PerformCAVerification = ?(
				AdditionalParameters.PerformCAVerification,
				DigitalSignatureInternalClientServer.VerifyQualified(), 
				DigitalSignatureInternalClientServer.NotVerifyCertificate());
		EndIf;
		
		ExpectedValues = New Array;
		ExpectedValues.Add(DigitalSignatureInternalClientServer.VerifyQualified());
		ExpectedValues.Add(DigitalSignatureInternalClientServer.QualifiedOnly());
		ExpectedValues.Add(DigitalSignatureInternalClientServer.NotVerifyCertificate());
		CommonClientServer.CheckParameter("DigitalSignatureInternal.CheckCertificate",
			"AdditionalVerificationParameters_.PerformCAVerification", AdditionalParameters.PerformCAVerification,
			Type("String"),, ExpectedValues);
	EndIf;
	
	CertificateCheckModes = DigitalSignatureInternalClientServer.CertificateCheckModes(
		ValueIsFilled(OnDate), AdditionalParameters.IgnoreCertificateRevocationStatus);
	
	If CryptoManagerToCheck = Undefined
	 Or CryptoManagerToCheck = "CryptographyService" Then
		
		ModuleCryptographyService = Common.CommonModule("CryptographyService");
		CheckParameters = DigitalSignatureInternalClientServer.CertificateVerificationParametersInTheService(
			DigitalSignature.CommonSettings(), CertificateCheckModes);
		Try
			If CheckParameters <> Undefined Then
				// ACC:287-off - No.640. It's acceptable to call a non-existent CTL procedure.
				// It's checked against CTL v.2.0.3, where the procedure exists.
				Result = ModuleCryptographyService.VerifyCertificateWithParameters(CertificateData, CheckParameters);
				// ACC:287-on
			Else
				Result = ModuleCryptographyService.CheckCertificate(CertificateData);
			EndIf;
		Except
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			If RaiseException1 Then
				Raise;
			EndIf;
			Return False;
		EndTry;
		If Not Result Then
			ErrorDescription = DigitalSignatureInternalClientServer.ServiceErrorTextCertificateInvalid();
			If RaiseException1 Then
				Raise ErrorDescription;
			EndIf;
			Return False;
		EndIf;
	Else
		
		If AdditionalParameters.IsTimestampDateSpecified And ValueIsFilled(OnDate) Then
			UniversalVerificationDate = OnDate - UTCOffset();
		Else
			UniversalVerificationDate = Undefined;
		EndIf;
		
		ValidationResult = ValidateCertificate(CryptoManagerToCheck, CertificateToCheck, 
			CertificateCheckModes, ErrorDescription, RaiseException1, UniversalVerificationDate);
		If Not ValidationResult Then
			If RaiseException1 Then
				Raise ErrorDescription;
			EndIf;
			Return False;
		EndIf;
	EndIf;
	
	OverdueError = DigitalSignatureInternalClientServer.CertificateOverdue(CertificateToCheck,
		OnDate, UTCOffset());
	
	If ValueIsFilled(OverdueError) Then
		ErrorDescription = OverdueError;
		If RaiseException1 Then
			Raise ErrorDescription;
		EndIf;
		Return False;
	EndIf;
	
	CertificateProperties = Undefined;
	If AdditionalParameters.ToVerifySignature Then
		
		CertificateProperties = DigitalSignatureInternalClientServer.CertificateProperties(
			CertificateToCheck, UTCOffset(), CertificateData);
			
		OverdueError = DigitalSignatureInternalClientServer.PrivateKeyExpired(CertificateProperties, OnDate);

		If ValueIsFilled(OverdueError) Then
			ErrorDescription = OverdueError;
			If RaiseException1 Then
				Raise ErrorDescription;
			EndIf;
			Return False;
		EndIf;
	EndIf;
	
	If AdditionalParameters.PerformCAVerification <> DigitalSignatureInternalClientServer.NotVerifyCertificate() Then
		
		CertificateAuthorityVerificationParameters = New Structure;
		CertificateAuthorityVerificationParameters.Insert("ThisVerificationSignature", AdditionalParameters.ToVerifySignature);
		CertificateAuthorityVerificationParameters.Insert("VerifyCertificate", AdditionalParameters.PerformCAVerification);
		
		Result = ResultofCertificateAuthorityVerification(CertificateToCheck, OnDate,
			CertificateAuthorityVerificationParameters, CertificateProperties);
		
		If Not Result.Valid Or ValueIsFilled(AdditionalParameters.Certificate) And ValueIsFilled(Result.Warning.ErrorText)
				And Not AdditionalParameters.ToVerifySignature Then
			
			CertificateCustomSettings = DigitalSignatureInternalServerCall.CertificateCustomSettings(
					CertificateToCheck.Thumbprint);

			If Not Result.Valid Then
				
				If CertificateCustomSettings.SigningAllowed <> True Then
					ErrorDescription = Result.Warning.ErrorText;
					AdditionalParameters.Warning = Result.Warning;
					AdditionalParameters.Certificate = CertificateCustomSettings.CertificateRef;
					If RaiseException1 Then
						Raise ErrorDescription;
					EndIf;
					Return False;
				EndIf;
				
			EndIf;

			If ValueIsFilled(AdditionalParameters.Certificate) 
			And ValueIsFilled(Result.Warning.ErrorText)
				And Not AdditionalParameters.ToVerifySignature Then
				
				If CertificateCustomSettings.IsNotified
					Or CertificateCustomSettings.CertificateRef = Undefined Then
					AdditionalParameters.Warning = Undefined;
				Else
					AdditionalParameters.Warning = Result.Warning;
					AdditionalParameters.Certificate = CertificateCustomSettings.CertificateRef;
				EndIf;
			EndIf;
			
		EndIf;
	EndIf;
	
	If RaiseException1 Then
		ErrorDescription = Null;
	Else
		ErrorDescription = "";
	EndIf;
	
	Return True;
	
EndFunction

Function AdditionalCertificateVerificationParameters() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("PerformCAVerification", DigitalSignatureInternalClientServer.VerifyQualified());
	AdditionalParameters.Insert("ToVerifySignature", False);
	AdditionalParameters.Insert("IsTimestampDateSpecified", False);
	AdditionalParameters.Insert("IgnoreCertificateRevocationStatus", False);
	AdditionalParameters.Insert("Warning");
	AdditionalParameters.Insert("Certificate");
	
	Return AdditionalParameters;
	
EndFunction

// For internal use only.
Function Encrypt(Data, Certificate, CryptoManager) Export

	ErrorDescription = "";

	Try
		ResultBinaryData = CryptoManager.Encrypt(Data, Certificate);
		DigitalSignatureInternalClientServer.BlankEncryptedData(ResultBinaryData, ErrorDescription);
	Except
		ErrorDescription = ErrorInfo();
	EndTry;
	
	If ValueIsFilled(ErrorDescription) Then
		Raise ErrorDescription;
	EndIf;
	
	Return ResultBinaryData;

EndFunction

// For internal use only.
Function EncryptInCloudSignatureService(Data, Certificate, Account = Undefined) Export
	
	If UseCloudSignatureService() Then

		TheDSSCryptographyServiceModule = Common.CommonModule("DSSCryptographyService");
		
		If Account = Undefined Then
			DSSAccountResult = TheDSSCryptographyServiceModule.ServiceAccountConnectionSettings();
			If Not DSSAccountResult.Completed2 Then
				Raise  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Dịch vụ DSS:
					|%1';
					|ru = 'Сервис DSS:
					|%1';
					|en = 'DSS service:
					|%1'; fa = 'DSS service:
					|%1';
					|it = 'Сервис DSS:
					|%1';
					|pl = 'DSS service:
					|%1';
					|tr = 'DSS Servisi:
					|%1'"), DSSAccountResult.Error);
			EndIf;
			DSSAccount = DSSAccountResult.Result;
		Else
			DSSAccount = Account;
		EndIf;
		
		ErrorDescription = "";
		Try
			Result = TheDSSCryptographyServiceModule.Encrypt(
						DSSAccount, Data, Certificate, "CMS");
			If Result.Completed2 Then
				ResultBinaryData = Result.Result;
				DigitalSignatureInternalClientServer.BlankEncryptedData(ResultBinaryData, ErrorDescription);
			Else
				ErrorDescription = Result.Error;
			EndIf;
		Except
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;

	Else
		ErrorDescription = NStr("vi = 'Chưa tùy chỉnh dịch vụ DSS.';
								|ru = 'Не настроен сервис DSS.';
								|en = 'DSS service is not configured.'; fa = 'DSS service is not configured.';
								|it = 'Не настроен сервис DSS.';
								|pl = 'DSS service is not configured.';
								|tr = 'DSS Servisi ayarlı değil.'");
	EndIf;
	
	If ValueIsFilled(ErrorDescription) Then
		Raise  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Dịch vụ DSS:
					|%1';
					|ru = 'Сервис DSS:
					|%1';
					|en = 'DSS service:
					|%1'; fa = 'DSS service:
					|%1';
					|it = 'Сервис DSS:
					|%1';
					|pl = 'DSS service:
					|%1';
					|tr = 'DSS Servisi:
					|%1'"), ErrorDescription);
	EndIf;
		
	Return ResultBinaryData;
	
EndFunction

// For internal use only.
Function EncryptByBuiltInCryptoProvider(Data, Certificate) Export

	If UseDigitalSignatureSaaS() Then
		ModuleCryptographyService = Common.CommonModule("CryptographyService");
		ErrorDescription = "";
		Try
			ResultBinaryData = ModuleCryptographyService.Encrypt(Data, Certificate);
			DigitalSignatureInternalClientServer.BlankEncryptedData(ResultBinaryData, ErrorDescription);
		Except
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
	Else
		ErrorDescription = NStr("vi = 'Chưa tùy chỉnh nhà cung cấp mã hóa hệ thống.';
								|ru = 'Не настроен встроенный криптопровайдер.';
								|en = 'The built-in cryptographic service provider is not configured.'; fa = 'The built-in cryptographic service provider is not configured.';
								|it = 'Не настроен встроенный криптопровайдер.';
								|pl = 'The built-in cryptographic service provider is not configured.';
								|tr = 'Yerleşik kripto sağlayıcı ayarlı değil.'");
	EndIf;
	
	If ValueIsFilled(ErrorDescription) Then
		Raise  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Nhà cung cấp mã hóa hệ thống:
					|%1';
					|ru = 'Встроенный криптопровайдер:
					|%1';
					|en = 'Built-in cryptographic service provider:
					|%1'; fa = 'Built-in cryptographic service provider:
					|%1';
					|it = 'Встроенный криптопровайдер:
					|%1';
					|pl = 'Built-in cryptographic service provider:
					|%1';
					|tr = 'Yerleşik kripto sağlayıcı:
					|%1'"), ErrorDescription);
	EndIf;
		
	Return ResultBinaryData;
	
EndFunction

// Parameters:
//  ObjectRef - DefinedType.SignedObject
//  ThumbprintsArray - See DigitalSignature.EncryptionCertificates
//
Procedure AddEncryptionCertificates(ObjectRef, ThumbprintsArray) Export

	CommonClientServer.CheckParameter("DigitalSignatureInternal.AddEncryptionCertificates", 
		"ObjectRef", ObjectRef,
		DigitalSignatureInternalCached.OwnersTypes(True));
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckChangeAllowed(ObjectRef);
	EndIf;

	SetPrivilegedMode(True);
	
	SequenceNumber = 1;
	For Each ThumbprintStructure In ThumbprintsArray Do
		RecordManager = InformationRegisters.EncryptionCertificates.CreateRecordManager();
		RecordManager.EncryptedObject = ObjectRef;
		RecordManager.Thumbprint = ThumbprintStructure.Thumbprint;
		RecordManager.Presentation = ThumbprintStructure.Presentation;
		RecordManager.Certificate = New ValueStorage(ThumbprintStructure.Certificate, New Deflation(9));
		RecordManager.SequenceNumber = SequenceNumber;
		SequenceNumber = SequenceNumber + 1;
		RecordManager.Write();
	EndDo;

EndProcedure

// Parameters:
//  Source - DefinedType.SignedObject
//  Receiver - CatalogObject - The equivalent of "DefinedType.SignedObject"
//
Procedure CopySignaturesAndEncryptionCertificates(Source, Receiver) Export

	FunctionName = "DigitalSignatureInternal.CopySignaturesAndEncryptionCertificates";
	CommonClientServer.CheckParameter(FunctionName, "Source", Source,
		DigitalSignatureInternalCached.OwnersTypes(True));
	CommonClientServer.CheckParameter(FunctionName, "Receiver", Source,
		DigitalSignatureInternalCached.OwnersTypes(False));
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckReadAllowed(Source);
		ModuleAccessManagement.CheckChangeAllowed(Receiver);
	EndIf;

	SetPrivilegedMode(True);
	
	If Source.SignedWithDS Then

		Receiver.Read();
		Receiver.SignedWithDS = True;
		Receiver.Write();

		DigitalSignaturesOfInitialFile = DigitalSignature.ObjectSignatures(Source.Ref);
		For Each Record In DigitalSignaturesOfInitialFile Do
			RecordManager = InformationRegisters.DigitalSignatures.CreateRecordManager();
			FillPropertyValues(RecordManager, Record);
			RecordManager.SignedObject = Receiver.Ref;
			RecordManager.Write(True);
		EndDo;

	EndIf;

	If Source.Encrypted Then

		Receiver.Read();
		Receiver.Encrypted = True;

		CertificatesOfSourceFileEncryption = DigitalSignature.EncryptionCertificates(Source);
		AddEncryptionCertificates(Receiver.Ref, CertificatesOfSourceFileEncryption);
	
		// To write a previously signed object.
		Receiver.AdditionalProperties.Insert("WriteSignedObject", True);
		Receiver.Write();

	EndIf;

EndProcedure

// Clears records about encryption certificates after object decryption.
// 
// Parameters:
//  ObjectRef - DefinedType.SignedObject
//
Procedure ClearEncryptionCertificates(ObjectRef) Export

	CommonClientServer.CheckParameter("DigitalSignatureInternal.ClearEncryptionCertificates", 
		"ObjectRef", ObjectRef,
		DigitalSignatureInternalCached.OwnersTypes(True));
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.CheckChangeAllowed(ObjectRef);
	EndIf;

	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.EncryptionCertificates.CreateRecordSet();
	RecordSet.Filter.EncryptedObject.Set(ObjectRef);
	RecordSet.Write(True);

EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - ClientApplicationForm
//  SignaturesListName - String
//
Procedure RegisterSignaturesList(Form, SignaturesListName) Export
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(SignaturesListName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(SignaturesListName + ".SignatureCorrect");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
EndProcedure

// Returns the details of files with data, signatures, and LOAs, extracted from the signing result.
// The result is returned in the notification specified in  See DigitalSignatureClient.Sign.ResultProcessing. 
// . In the array, a file of the Data type is followed by its signature. 
// 
// Parameters:
//  SigningResult - See DigitalSignatureClient.Sign.DataDetails
//  FilesReceiptParameters - Structure:
//   * TransliterateFilesNames - Boolean
//   * ExportCertificate - Boolean
//   * ExportLOA - Boolean
//  UUID - UUID - Intended for storing in a temporary storage.
// 
// Returns:
//  Array of Structure:
//   * Data   - String - Address in the temporary storage. Depending on how it was passed to "DigitalSignatureClient.Sign.DataDetails".
//              - BinaryData 
//   * FileName - String 
//   * FileType - String - "Data", "Signature", "LetterOfAuthority", "LOASignature", "Certificate".
//
Function GetFilesFromSigningResult(SigningResult, FilesReceiptParameters, UUID) Export
	
	If SigningResult.Property("DataSet") Then
		DataSet = SigningResult.DataSet;
	Else
		DataSet = CommonClientServer.ValueInArray(SigningResult);
	EndIf;
	
	SignatureFilesExtension = DigitalSignature.PersonalSettings().SignatureFilesExtension;
	
	Result = New Array;
	
	// StandardSubsystems.MachineReadableLettersOfAuthority

	If FilesReceiptParameters.ExportLOA 
		And ValueIsFilled(SigningResult.SelectedLetterOfAuthority) 
		And Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then

		ModuleMachineReadableLettersOfAuthorityFTSInternal = Common.CommonModule(
			"MachineReadableLettersOfAuthorityFTSInternal");

		If ModuleMachineReadableLettersOfAuthorityFTSInternal.ThisIsMachineReadableAuthorizationLetter(
			SigningResult.SelectedLetterOfAuthority) Then

			ModuleMachineReadableLettersOfAuthorityFTS = Common.CommonModule("MachineReadableLettersOfAuthorityFTS");
			LetterOfAuthorityFiles = ModuleMachineReadableLettersOfAuthorityFTS.LetterOfAuthorityFiles(
			SigningResult.SelectedLetterOfAuthority, False);

			For Each LetterOfAuthorityFile In LetterOfAuthorityFiles Do
				If ValueIsFilled(LetterOfAuthorityFile.ErrorDescription) Then
					Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể lưu tệp giấy ủy quyền %1: %2';
						|ru = 'Не удалось сохранить файл доверенности %1: %2';
						|en = 'Couldn''t save the LOA file %1: %2'; fa = 'Couldn''t save the LOA file %1: %2';
						|it = 'Couldn''t save the LOA file %1: %2';
						|pl = 'Couldn''t save the LOA file %1: %2';
						|tr = '%1 yetki belgesi kaydedilemiyor: %2'"),
						SigningResult.SelectedLetterOfAuthority, LetterOfAuthorityFile.ErrorDescription);
				EndIf;

				StructureOfFileDetails = New Structure("Data, FileName, FileType");
				StructureOfFileDetails.Data = PutToTempStorage(
					LetterOfAuthorityFile.BinaryData, UUID);
				StructureOfFileDetails.FileName = LetterOfAuthorityFile.FileName;
				StructureOfFileDetails.FileType = ?(LetterOfAuthorityFile.FileType = "Signature", "LOASignature", "LetterOfAuthority");
				Result.Add(StructureOfFileDetails);

			EndDo;
		EndIf;
	EndIf;
	
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
	CertificateFileDetailsStructure = Undefined;
		
	For Each SignedFile In DataSet Do
		
		SignatureProperties = SignedFile.SignatureProperties;
		If IsTempStorageURL(SignatureProperties) Then
			SignatureProperties = GetFromTempStorage(SignatureProperties);
		EndIf;
		
		File = New File(SignedFile.Presentation);
		
		If FilesReceiptParameters.ExportCertificate And CertificateFileDetailsStructure = Undefined Then
			
			CertificateData = PutToTempStorage(SignatureProperties.Certificate, UUID);
			CertificateOwner = ?(ValueIsFilled(SignatureProperties.CertificateOwner), SignatureProperties.CertificateOwner, NStr("vi = 'Chứng thư';
																																|ru = 'Сертификат';
																																|en = 'Certificate'; fa = 'گواهی';
																																|it = 'Сертификат';
																																|pl = 'Certificate';
																																|tr = 'Sertifika'"));
			If FilesReceiptParameters.TransliterateFilesNames Then
				CertificateOwner = StringFunctions.LatinString(CertificateOwner);
			EndIf;

			CertificateFileName = DigitalSignatureInternalClientServer.CertificateFileName(
				"", CertificateOwner, "cer", False);

			CertificateFileDetailsStructure = New Structure("Data, FileName, FileType");
			CertificateFileDetailsStructure.Data = CertificateData;
			CertificateFileDetailsStructure.FileName = CertificateFileName;
			CertificateFileDetailsStructure.FileType = "Certificate";
			
		EndIf;
		
		StructureOfFileDetails = New Structure("Data, FileName, FileType");
		StructureOfFileDetails.Data = SignedFile.Data;
		StructureOfFileDetails.FileName = SignedFile.Presentation;
		StructureOfFileDetails.FileType = "Data";
		Result.Add(StructureOfFileDetails);
		
		SignatureData = PutToTempStorage(SignatureProperties.Signature, UUID);
		SignatureFileName = DigitalSignatureInternalClientServer.SignatureFileName(File.BaseName,
				CertificateOwner, SignatureFilesExtension);
		
		StructureOfFileDetails = New Structure("Data, FileName, FileType");
		StructureOfFileDetails.Data = SignatureData;
		StructureOfFileDetails.FileName = SignatureFileName;
		StructureOfFileDetails.FileType = "Signature";
		Result.Add(StructureOfFileDetails);
	
	EndDo;
	
	If CertificateFileDetailsStructure <> Undefined Then
		Result.Add(CertificateFileDetailsStructure);
	EndIf;
	
	Return Result;
	
EndFunction

Function FilesReceiptParameters() Export
	
	Structure = New Structure;
	Structure.Insert("TransliterateFilesNames", False);
	Structure.Insert("ExportCertificate", True);
	Structure.Insert("ExportLOA", True);
	
	Return Structure;
	
EndFunction

// Determines digital signature availability for an object (by its type).
// 
// Parameters:
//  ObjectType - Type - For example, "CatalogRef.Projects".
// 
// Returns:
//  Boolean
//
Function DigitalSignatureAvailable(ObjectType) Export
	
	Return DigitalSignatureInternalCached.OwnersTypes().Get(ObjectType) <> Undefined;
	
EndFunction

// Returns a certificate address in the temporary storage and its extension.
//
// Parameters:
//  DigitalSignatureInformation - Structure - Row with signatures from the array received by the "DigitalSIgnature.ObjectSignatures" method.
//  UUID     - UUID - a form ID.
// 
// Returns:
//  Structure:
//   * CertificateExtension - String - a certificate file extension.
//   * CertificateAddress      - String - an address in the temporary storage, by which the certificate was placed.
//
Function DataByCertificate(DigitalSignatureInformation, UUID) Export
	
	Result = New Structure("CertificateExtension, CertificateAddress");
	CertificateData = DigitalSignatureInformation.Certificate;
	
	If TypeOf(CertificateData) = Type("ValueStorage") Then
		CertificateData = CertificateData.Get();
	EndIf;
	
	If TypeOf(CertificateData) = Type("String") Then
		Result.CertificateExtension = "txt";
		Result.CertificateAddress = PutToTempStorage(
			RowBinaryData(CertificateData), UUID);
	Else
		Result.CertificateExtension = "cer";
		Result.CertificateAddress = PutToTempStorage(
			CertificateData, UUID);
	EndIf;
		
	Return Result;
	
EndFunction

// Returns the capability flag of interactive use of digital signatures and encryption 
// for the current user.
//
// Returns:
//  Boolean - if True, you can use digital signatures and encryption interactively.
//
Function InteractiveUseofElectronicSignaturesandEncryption() Export
	
	Return AccessRight("View", Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates);
	
EndFunction

// Names of the data files and names of their signatures are extracted from the passed file names.
// Mapping is executed according to the signature name generation and signature file extension rules (p7s).
// For example:
//  The data file name is "example.txt"
//  the signature file name is "example-Ivanov Petr.p7s"
//  the signature file name is "example-Ivanov Petr (1).p7s".
//
// Parameters:
//  FilesNames - Array - file names of the Row type.
//
// Returns:
//  Map of KeyAndValue:
//   * Key     - String - a file name.
//   * Value - Array - signature file names of the Row type.
// 
Function SignaturesFilesNamesOfDataFilesNames(FilesNames) Export
	
	SignatureFilesExtension = DigitalSignature.PersonalSettings().SignatureFilesExtension;
	
	Result = New Map;
	
	// Dividing files by extension.
	DataFilesNames = New Array;
	SignatureFilesNames = New Array;
	
	For Each FileName In FilesNames Do
		If StrEndsWith(FileName, SignatureFilesExtension) Then
			SignatureFilesNames.Add(FileName);
		Else
			DataFilesNames.Add(FileName);
		EndIf;
	EndDo;
	
	// Sorting data file names by their length in characters, descending.
	
	For IndexA = 1 To DataFilesNames.Count() Do
		IndexMAX = IndexA; // Assume that the current file has the maximum number of characters.
		For IndexB = IndexA+1 To DataFilesNames.Count() Do
			If StrLen(DataFilesNames[IndexMAX-1]) > StrLen(DataFilesNames[IndexB-1]) Then
				IndexMAX = IndexB;
			EndIf;
		EndDo;
		swap = DataFilesNames[IndexA-1];
		DataFilesNames[IndexA-1] = DataFilesNames[IndexMAX-1];
		DataFilesNames[IndexMAX-1] = swap;
	EndDo;
	
	// Searching for file name mapping.
	For Each DataFileName In DataFilesNames Do
		Result.Insert(DataFileName, FindSignatureFilesNames(DataFileName, SignatureFilesNames));
	EndDo;
	
	// The remaining signature files are not recognized as signatures related to a specific file.
	For Each SignatureFileName In SignatureFilesNames Do
		Result.Insert(SignatureFileName, New Array);
	EndDo;
	
	Return Result;
	
EndFunction

// For internal use only.
// 
// Parameters:
//  CertificatesData - Array of BinaryData
// 
// Returns:
//  Array of BinaryData - Certificates up to the root one.
//
Function CertificatesInOrderToRoot(CertificatesData) Export
	
	By_Order = New Array;
	CertificatesDetails = New Map;
	CertificatesBySubjects = New Map;
	
	For Each CertificateData In CertificatesData Do
		Certificate = New CryptoCertificate(CertificateData);
		By_Order.Add(CertificateData);
		CertificatesDetails.Insert(Certificate, CertificateData);
		CertificatesBySubjects.Insert(
			DigitalSignatureInternalClientServer.IssuerKey(Certificate.Subject),
			CertificateData);
	EndDo;
	
	For Counter = 1 To By_Order.Count() Do
		HasChanges = False;
		DigitalSignatureInternalClientServer.SortCertificates(
			By_Order, CertificatesDetails, CertificatesBySubjects, HasChanges); 
		If Not HasChanges Then
			Break;
		EndIf;
	EndDo;
		
	Return By_Order;

EndFunction

// For internal use only.
// 
// Parameters:
//  CryptoCertificate
//  OnDate - Undefined, Date
//  CheckParameters - Structure:
//   * ThisVerificationSignature - Signature verification flag. Warnings (not errors) are ignored.
//   * VerifyCertificate - String - "QualifiedOnly", "VerifyQualified", "DoNotVerifyCertificate". 
//  CertificateProperties - See DigitalSignature.CertificateProperties
// 
// Returns:
//   See DigitalSignatureInternalClientServer.DefaultCAVerificationResult
//
Function ResultofCertificateAuthorityVerification(CryptoCertificate, OnDate = Undefined, 
	Val CheckParameters = Undefined, CertificateProperties = Undefined) Export
	
	Result = DigitalSignatureInternalClientServer.DefaultCAVerificationResult();
	DigitalSignatureLocalization.OnFillCertificationAuthorityAuditResult(
		Result, CryptoCertificate, OnDate, CheckParameters, CertificateProperties);
	
	Return Result;
	
EndFunction

// For internal use only.
Procedure EditMarkONReminder(Certificate, Remind, ReminderID) Export
	
	CurrentUser = Users.CurrentUser();
	
	UserRemindersAvailable = False;
	If Common.SubsystemExists("StandardSubsystems.UserReminders") Then
		ModuleUserReminder = Common.CommonModule("UserReminders");
		UserRemindersAvailable = ModuleUserReminder.UsedUserReminders();
	EndIf;
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.CertificateUsersNotifications.CreateRecordSet();
	RecordSet.Filter.Certificate.Set(Certificate);
	RecordSet.Filter.User.Set(CurrentUser); 
	
	Record = RecordSet.Add();
	Record.Certificate = Certificate;
	Record.User = CurrentUser;
	Record.IsNotified = Not Remind;
	If UserRemindersAvailable Then
		RecordSet.AdditionalProperties.Insert("ReminderID", ReminderID);
	EndIf;
	RecordSet.Write();
	
	SetPrivilegedMode(False);
	
EndProcedure

// For internal use only.
Procedure ChangeRegulatoryTaskExtensionCredibilitySignatures(RefineSignaturesAutomatically = Undefined,
	AddTimestampsAutomatically = Undefined, CryptoSignatureTypeDefault = Undefined) Export

	JobParameters = New Structure;
	JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ExtendSignatureValidity);
	If Common.DataSeparationEnabled() Then
		JobParameters.Insert("MethodName", Metadata.ScheduledJobs.ExtendSignatureValidity.MethodName);
	EndIf;
	
	If RefineSignaturesAutomatically = Undefined Then
		RefineSignaturesAutomatically = Constants.RefineSignaturesAutomatically.Get();
	EndIf;
	
	If AddTimestampsAutomatically = Undefined Then
		AddTimestampsAutomatically = Constants.AddTimestampsAutomatically.Get();
	EndIf;
	
	If RefineSignaturesAutomatically = 1 And CryptoSignatureTypeDefault = Undefined Then
		CryptoSignatureTypeDefault = Constants.CryptoSignatureTypeDefault.Get();
	EndIf;
		
	If Not Common.DataSeparationEnabled() Then
		Use = AddTimestampsAutomatically 
			Or RefineSignaturesAutomatically = 1 
				And (CryptoSignatureTypeDefault = Enums.CryptographySignatureTypes.WithTimeCAdEST
					Or CryptoSignatureTypeDefault = Enums.CryptographySignatureTypes.ArchivalCAdESAv3)
	Else
		// In SaaS, can be upgraded only to CAdES-T.
		Use = RefineSignaturesAutomatically = 1 
				And CryptoSignatureTypeDefault = Enums.CryptographySignatureTypes.WithTimeCAdEST;
	EndIf;
	
	SetPrivilegedMode(True);
	
	JobsList = ScheduledJobsServer.FindJobs(JobParameters);
	If JobsList.Count() = 0 Then
		JobParameters.Insert("Use", Use);
		ScheduledJobsServer.AddJob(JobParameters);
	Else
		JobParameters = New Structure("Use", Use);
		For Each Job In JobsList Do
			ScheduledJobsServer.ChangeJob(Job, JobParameters);
		EndDo;
	EndIf;

EndProcedure

// For the form of the Administration subsystem's common settings.
// 
// Parameters:
//  Form - ClientApplicationForm - See DataProcessor.SSLAdministrationPanel.
//  DataPathAttribute - String - Attribute data path that was modified in the form.
//
Procedure ConfigureCommonSettingsForm(Form, DataPathAttribute) Export
	
	Items = Form.Items;
	ConstantsSet = Form.ConstantsSet;
	CommonSettings = DigitalSignature.CommonSettings();
	AccessToInternetServicesAllowed = Common.AccessToInternetServicesAllowed();
	
	If Common.DataSeparationEnabled() 
		And (DataPathAttribute = "ConstantsSet.UseDigitalSignature"
			Or DataPathAttribute = "ConstantsSet.UseEncryption"
			Or DataPathAttribute = "ConstantsSet.UseDSSService"
			Or DataPathAttribute = "") Then
				
		Items.VerifyDigitalSignaturesOnTheServer.Visible = UseCloudSignatureService()
			Or UseDigitalSignatureSaaS();
		
	EndIf;
	
	If DataPathAttribute = "AllowAccessToDigitalSignatureInternetServices" Or  DataPathAttribute = ""
	 Or DataPathAttribute = "AllowAccessToInternetServices" Then
		Form.ConstantAllowAccessToDigitalSignatureInternetServices = CommonSettings.AccessToInternetServicesAllowed;
		Items.ConstantAllowAccessToDigitalSignatureInternetServices.Enabled = AccessToInternetServicesAllowed;
		
		AccessToInternetServicesAllowedTitle = New Array;
		AccessToInternetServicesAllowedTitle.Add(NStr(
			"vi = 'Tự động tải về và cài đặt danh sách thu hồi và các khuyến nghị mới nhất về cách khắc phục sự cố từ Internet.';
			|ru = 'Загружать и устанавливать списки отзыва и свежие рекомендации по устранению проблем из Интернета автоматически.';
			|en = 'Automatically update certificate revocation lists and troubleshooting recommendations via the internet.'; fa = 'به‌روزرسانی خودکار فهرست‌های ابطال گواهی و توصیه‌های رفع مشکل از طریق اینترنت.';
			|it = 'Automatically update certificate revocation lists and troubleshooting recommendations via the internet.';
			|pl = 'Automatically update certificate revocation lists and troubleshooting recommendations via the internet.';
			|tr = 'Çağrı listelerini ve en güncel sorun giderme ipuçlarını internetten otomatikman indir ve kur.'"));

		// StandardSubsystems.MachineReadableLettersOfAuthority
		If Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
			AccessToInternetServicesAllowedTitle.Add(NStr(
				"vi = 'Tải lên và kiểm tra trạng thái của các giấy ủy quyền có thể đọc được bằng máy theo định dạng thống nhất trong Danh sách phân bổ của Tổng cục thuế.';
				|ru = 'Загружать и проверять статусы машиночитаемых доверенностей единого формата в Распределенном реестре ФНС.';
				|en = 'Upload and validate the status of MR LOA in the FTS Distributed Ledger'; fa = 'Upload and validate the status of MR LOA in the FTS Distributed Ledger';
				|it = 'Upload and validate the status of MR LOA in the FTS Distributed Ledger';
				|pl = 'Upload and validate the status of MR LOA in the FTS Distributed Ledger';
				|tr = 'Makinede okunabilir yetki belgelerinin durumlarını FVS''nin dağıtımlı siciline tek bir formatta yükle ve kontrol et.'"));
		EndIf;
		// End StandardSubsystems.MachineReadableLettersOfAuthority
		
		Items.ConstantAllowAccessToDigitalSignatureInternetServicesExtendedTooltip.Title = StrConcat(AccessToInternetServicesAllowedTitle, " ");
		Items.GroupCommentAllowInternetDownloadsInDigitalSignature.Visible = Not AccessToInternetServicesAllowed;
		
	EndIf;

	If DataPathAttribute = "ConstantsSet.UseDigitalSignature" Or DataPathAttribute
		= "ConstantsSet.UseEncryption" Or DataPathAttribute = "" Then

		Items.DigitalSignatureAndEncryptionSettings.Enabled = ConstantsSet.UseDigitalSignature
			Or ConstantsSet.UseEncryption;
		Items.GroupAdvancedSignature.Enabled = ConstantsSet.UseDigitalSignature;
		Items.CheckSignaturesAtServerGroup.Enabled = ConstantsSet.UseDigitalSignature
			Or ConstantsSet.UseEncryption;

		If ConstantsSet.UseDigitalSignature And (DataPathAttribute
			= "ConstantsSet.UseDigitalSignature" Or DataPathAttribute = "") Then
			
			Form.ConstantTimestampServersAddresses = StrConcat(CommonSettings.TimestampServersAddresses, Chars.LF);
			Form.ConstantRefineSignaturesAutomatically = Constants.RefineSignaturesAutomatically.Get();
			Form.ConstantAddTimestampsAutomatically = Constants.AddTimestampsAutomatically.Get();
			Form.ConstantRefineSignaturesDates = Constants.RefineSignaturesDates.Get();
			SignatureType = Constants.CryptoSignatureTypeDefault.Get();
			Form.ConstantCryptoSignatureTypeDefault = SignatureType;
			SetHeaderTipsImprovements(Form, SignatureType);
			
			If Items.GenerateDigitalSignaturesAtServer.Visible Then
				Form.ConstantGenerateDigitalSignaturesAtServer = Constants.GenerateDigitalSignaturesAtServer.Get();
			EndIf;
			If Items.VerifyDigitalSignaturesOnTheServer.Visible Then
				Form.ConstantVerifyDigitalSignaturesOnTheServer = Constants.VerifyDigitalSignaturesOnTheServer.Get();
			EndIf;
		EndIf;
		
		SetHeaderElectronicSignatureOnServer(Form);
		
	ElsIf (DataPathAttribute = "ConstantCryptoSignatureTypeDefault" Or DataPathAttribute
		= "ConstantRefineSignaturesAutomatically") Then
		
		Form.ConstantRefineSignaturesAutomatically = Constants.RefineSignaturesAutomatically.Get();
		SignatureType = Constants.CryptoSignatureTypeDefault.Get();
		Form.ConstantCryptoSignatureTypeDefault = SignatureType;
		SetHeaderTipsImprovements(Form, SignatureType);
		
	EndIf;
	
	StandardProcessing = True;
	DigitalSignatureLocalization.OnSetUpGeneralSettingsForm(
		Form, DataPathAttribute, AccessToInternetServicesAllowed, CommonSettings, StandardProcessing);
	If StandardProcessing Then
		Items.CryptoSignatureTypeDefault.ToolTipRepresentation = ToolTipRepresentation.None;
		If DataPathAttribute = "" Then
			Items.CryptoSignatureTypeDefault.Visible = True;
			FillListSignatureTypesCryptography(
				Items.CryptoSignatureTypeDefault.ChoiceList, "Settings");
		EndIf;
	EndIf;
	
EndProcedure

// Returns a selection of individuals' certificates.
// 
// Parameters:
//  IndividualsForFilter - Array of DefinedType.Individual
// 
// Returns:
//   QueryResultSelection:
//     * Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//     * Individual - DefinedType.Individual
//
Function CertificatesOfIndividuals(IndividualsForFilter) Export

	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	DigitalSignatureAndEncryptionKeysCertificates.Ref AS Certificate,
	|	DigitalSignatureAndEncryptionKeysCertificates.Individual AS Individual
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS DigitalSignatureAndEncryptionKeysCertificates
	|WHERE
	|	DigitalSignatureAndEncryptionKeysCertificates.Individual IN(&IndividualsArray)
	|	AND NOT DigitalSignatureAndEncryptionKeysCertificates.DeletionMark
	|	AND DigitalSignatureAndEncryptionKeysCertificates.ValidBefore > &CurrentSessionDate";

	Query.SetParameter("IndividualsArray", IndividualsForFilter);
	Query.SetParameter("CurrentSessionDate", CurrentSessionDate());
	QueryResult = Query.Execute();

	Return QueryResult.Select();

EndFunction

// Returns a selection of individuals' (users') certificates.
// 
// Parameters:
//  Users - Array of CatalogRef.Users
// 
// Returns:
//   QueryResultSelection:
//     * Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//     * User - CatalogRef.Users
//
Function CertificatesOfIndividualsUsers(Users) Export

	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	DigitalSignatureAndEncryptionKeysCertificates.Ref AS Certificate,
	|	UsersCatalog.Ref AS User
	|FROM
	|	Catalog.Users AS UsersCatalog
	|		INNER JOIN Catalog.DigitalSignatureAndEncryptionKeysCertificates AS
	|			DigitalSignatureAndEncryptionKeysCertificates
	|		ON (DigitalSignatureAndEncryptionKeysCertificates.Individual = UsersCatalog.Individual
	|		AND UsersCatalog.Ref IN (&UsersArray)
	|		AND UsersCatalog.Individual <> &EmptyIndividual
	|		AND NOT DigitalSignatureAndEncryptionKeysCertificates.DeletionMark
	|		AND DigitalSignatureAndEncryptionKeysCertificates.ValidBefore > &CurrentSessionDate)";

	
	If DigitalSignature.CommonSettings().IndividualUsed Then
		TypesIndividuals = Metadata.DefinedTypes.Individual.Type.Types();
		Query.SetParameter("EmptyIndividual", New (TypesIndividuals[0]));
	Else
		Query.SetParameter("EmptyIndividual", "");
	EndIf;

	Query.SetParameter("CurrentSessionDate", CurrentSessionDate());
	Query.SetParameter("UsersArray", Users);
	QueryResult = Query.Execute();

	Return QueryResult.Select();

EndFunction

Function GetAddInData(TemplateName) Export
	Return Catalogs.DigitalSignatureAndEncryptionKeysCertificates.GetTemplate(TemplateName);
EndFunction

Function TimestampServerAddressesByDefault() Export
	
	TimestampServersAddresses = "";
	DigitalSignatureLocalization.OnGetTimestampServerAddresses(TimestampServersAddresses);
	Return TimestampServersAddresses;
	
EndFunction

Function CheckSignaturesByMachineReadableLOA(Signatures, SignedObject) Export

	If Not Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		Return New Array;
	EndIf;

	ChecksResults = New Array;
	DigitalSignatureLocalization.OnVerifySignaturesOnMRLOA(Signatures, SignedObject, ChecksResults);
	Return ChecksResults;

EndFunction

// Populates a choice list with signature types based on the settings.
//
// Parameters:
//  ChoiceList - ValueList - List to be populated.
//  Operation     - String - Enhancement, Signing, Settings - Operations the list is generated for.
//               - Undefined - Default value. Used to generate a list without exceptions.
//  SignatureType   - EnumRef.CryptographySignatureTypes - SignatureType that defines what signatures are
//                                                              available for this operation.
//
Procedure FillListSignatureTypesCryptography(ChoiceList, Operation = Undefined, SignatureType = Undefined) Export
	
	ChoiceList.Clear();
	If Operation <> "Improvement"
		And (Not ValueIsFilled(SignatureType) Or SignatureType = Enums.CryptographySignatureTypes.BasicCAdESBES) Then
		SignaturePresentation = "";
		DigitalSignatureLocalization.OnPopulateSignatureTypePresentation(Enums.CryptographySignatureTypes.BasicCAdESBES, SignaturePresentation);
		If SignaturePresentation = "" Then
			SignaturePresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chữ ký cơ bản (%1)
					 |sẽ không có hiệu lực sau khi chứng chỉ của người ký hết hạn hiệu lực (thường là sau 1 năm).';
					 |ru = 'Базовая подпись (%1)
					 |становится недействительной после окончания срока действия сертификата подписанта (обычно в течение 1 года).';
					 |en = 'Basic electronic signature (%1)
					 |becomes invalid after the signer''s certificate expires (usually within a year).'; fa = 'Basic electronic signature (%1)
					 |becomes invalid after the signer''s certificate expires (usually within a year).';
					 |it = 'Базовая подпись (%1)
					 |становится недействительной после окончания срока действия сертификата подписанта (обычно в течение 1 года).';
					 |pl = 'Podstawowy podpis (%1)
					 |staje się nieważny po zakończeniu terminu ważności certyfikatu osoby podpisującej (zazwyczaj w ciągu 1 roku).';
					 |tr = 'Temel imza (%1)
					 | imzacı sertifikasının geçerlilik dönemi sona erdikten sonra (genelde 1 sene içinde) geçersiz olur.'"),
			"CAdES-BES");
		EndIf;
		ChoiceList.Add(Enums.CryptographySignatureTypes.BasicCAdESBES, SignaturePresentation);
	EndIf;

	DataSeparationEnabled = Common.DataSeparationEnabled();
	AddSignatureType = False;
	
	If Not ValueIsFilled(SignatureType) Or SignatureType = Enums.CryptographySignatureTypes.WithTimeCAdEST
		And Operation <> "Improvement" Or SignatureType = Enums.CryptographySignatureTypes.BasicCAdESBES Then
		AddSignatureType = True;
	EndIf;
		
	If AddSignatureType Then
		
		SignaturePresentation = "";
		DigitalSignatureLocalization.OnPopulateSignatureTypePresentation(Enums.CryptographySignatureTypes.WithTimeCAdEST, SignaturePresentation);
		If SignaturePresentation = "" Then
			SignaturePresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chữ ký có dấu thời gian đáng tin cậy (%1)
					 |có hiệu lực sau khi chứng chỉ của người ký hết hiệu lực.';
					 |ru = 'Подпись с меткой доверенного времени (%1)
					 |действует после окончания срока действия сертификата подписанта.';
					 |en = 'Electronic signature with time (%1)
					 |is valid after the signer''s certificate expires.'; fa = 'Electronic signature with time (%1)
					 |is valid after the signer''s certificate expires.';
					 |it = 'Подпись с меткой доверенного времени (%1)
					 |действует после окончания срока действия сертификата подписанта.';
					 |pl = 'Podpis z zaufanym znacznikiem czasu (%1)
					 |jest ważny pof zakończeniu terminu certyfikatu osoby podpisującej.';
					 |tr = 'Güvenilen tarih etiketine (%1)
					 | sahip bir imza, imzacının sertifikasının süresi dolduktan sonra geçerlidir.'"), "CAdES-T");
		EndIf;
		
		ChoiceList.Add(Enums.CryptographySignatureTypes.WithTimeCAdEST,
			SignaturePresentation);
			
	EndIf;

	If Operation = Undefined Or Not (DataSeparationEnabled And Operation = "Settings") Then
		
		SignaturePresentation = "";
		DigitalSignatureLocalization.OnPopulateSignatureTypePresentation(Enums.CryptographySignatureTypes.ArchivalCAdESAv3, SignaturePresentation);
		If SignaturePresentation = "" Then
			SignaturePresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chữ ký lưu trữ (%1)
					 |có chứa tập hợp bằng chứng xác thực, trong đó có chuỗi chứng chỉ và tự động gia hạn.';
					 |ru = 'Архивная подпись (%1)
					 |содержит полный набор доказательств подлинности, в том числе цепочку сертификатов, и автоматически продлевается.';
					 |en = 'Archival electronic signature (%1)
					 |contains the full authenticity proof set, including a certificate chain, and is renewed automatically.'; fa = 'Archival electronic signature (%1)
					 |contains the full authenticity proof set, including a certificate chain, and is renewed automatically.';
					 |it = 'Архивная подпись (%1)
					 |содержит полный набор доказательств подлинности, в том числе цепочку сертификатов, и автоматически продлевается.';
					 |pl = 'Podpis archiwalny (%1)
					 |zawiera pełny zestaw dowodów autentyczności, w tym łańcuch certyfikatów oraz jest przedłużany automatycznie.';
					 |tr = 'Arşiv imzası (%1)
					 |, bir sertifika zinciri de dahil olmak üzere eksiksiz bir doğruluk kanıtlarını içerir ve otomatik olarak yenilenir.'"),
			"CAdES-A");
		EndIf;
		
		ChoiceList.Add(Enums.CryptographySignatureTypes.ArchivalCAdESAv3, SignaturePresentation);
		
	EndIf;

EndProcedure

// Signs the data and returns a signature with or without data.
//
// Parameters:
//  Data - String - an arbitrary string for signing,
//         - BinaryData - binary data for signing.
//
//  CMSParameters            - Structure - returns the DigitalSignature.CMSParameters function.
//  CryptoCertificate  - CryptoCertificate - a crypto certificate to be used.
//  CryptoManager    - CryptoManager   - a crypto manager to be used.
// 
// Returns:
//  String - a string in the Base64 format.
//
Function SignCMS(Val Data, CMSParameters, CryptoCertificate, CryptoManager) Export
	
	Password = CryptoManager.PrivateKeyAccessPassword;
	
	ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
	
	CryptoProviderProperties = CryptoProviderProperties(CryptoManager);
	ComponentObject.PathToCryptoprovider = CryptoProviderProperties.Path;
	
	SignatureValueAttribute = CMSSignResult(ComponentObject,
		Data,
		CMSParameters,
		CryptoCertificate,
		Password);
	
	Return SignatureValueAttribute;
	
EndFunction

#Region SuppliedData

// See SuppliedDataOverridable.GetHandlersForSuppliedData
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.DataKind = "CryptoError3";
	Handler.HandlerCode = "CryptoError";
	Handler.Handler = DigitalSignatureInternal;
	
EndProcedure

// The procedure is called when a new data notification is received.
// In the procedure body, check whether the app requires this data. 
// If it requires, select the Import check box.
// 
// Parameters:
//   Descriptor - XDTODataObject
//   ToImport - Boolean - If True, run import. Otherwise, False.
//
Procedure NewDataAvailable(Val Descriptor, ToImport) Export
	
	ToImport = Descriptor.DataType = "CryptoError3";
	
EndProcedure

// The procedure is called after calling NewDataAvailable, it parses the data.
//
// Parameters:
//   Descriptor - XDTODataObject
//   PathToFile - String - Full name of the extracted file. 
//                  The file is automatically deleted once the procedure is completed.
//                  If a file is not specified, it is set to Undefined.
//
Procedure ProcessNewData(Val Descriptor, Val PathToFile) Export
	
	If Descriptor.DataType = "CryptoError3" Then
		WriteClassifierData(New BinaryData(PathToFile));
	EndIf;
	
EndProcedure

// The procedure is called if data processing is canceled due to an error.
//
// Parameters:
//   Descriptor - XDTODataObject
//
Procedure DataProcessingCanceled(Val Descriptor) Export 
	
EndProcedure

#EndRegion

#Region CloudSignature

// Determines the availability of the cloud signature subsystem
//
// Returns:
//  Boolean
//
Function UseCloudSignatureService() Export
	
	Result = False;
	
	DigitalSignatureLocalization.OnDefineCloudSigningServiceUsage(Result);
	
	Return Result;
	
EndFunction

// Determines the type of the cloud signature app.
//
// Returns:
//  Undefined 
//  Type
//
Function ServiceProgramTypeSignatures() Export
	
	Result = Undefined;
	
	DigitalSignatureLocalization.OnDefineSigningServiceAppType(Result);
	
	Return Result;
	
EndFunction

#EndRegion

#Region ConfigurationSubsystemsEventHandlers

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "Catalogs.DigitalSignatureAndEncryptionApplications.FillInitialSettings";
	Handler.ExecutionMode = "Exclusively";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.6.20";
	Handler.Procedure = "DigitalSignatureInternal.ReplaceRoleAddingChangeElectronicSignaturesAndEncryption";
	Handler.ExecutionMode = "Seamless";
	
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		Handler = Handlers.Add();
		Handler.Version = "3.1.6.69";
		Handler.Comment = NStr("vi = 'Cập nhật thông tin về ứng dụng chữ ký điện tử và mã hóa.';
								|ru = 'Обновление сведений о приложениях электронной подписи и шифрования.';
								|en = 'Updating info on digital signing and encryption apps.'; fa = 'Updating info on digital signing and encryption apps.';
								|it = 'Обновление сведений о приложениях электронной подписи и шифрования.';
								|pl = 'Updating info on digital signing and encryption apps.';
								|tr = 'Elektronik imza ve şifreleme uygulamalarına ilişkin bilgileri güncelleyin.'");
		Handler.Procedure = "DataProcessors.DigitalSignatureAndEncryptionApplications.UpdateNameOfBuiltInCryptoprovider";
		Handler.ExecutionMode = "Seamless";
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.6.128";
	Handler.InitialFilling = True;
	Handler.Comment = NStr("vi = 'Điền tùy chỉnh để nâng cấp chữ ký.';
							|ru = 'Заполнение настроек для усовершенствования подписей.';
							|en = 'Fill in settings for signature enhancement.'; fa = 'Fill in settings for signature enhancement.';
							|it = 'Compilazione impostazioni per il perfezionamento delle firme.';
							|pl = 'Wypełnienie ustawień do udoskonalenia podpisów.';
							|tr = 'İmzaların geliştirilmesi için ayarların doldurulması.'");
	Handler.Procedure = "DigitalSignatureInternal.FillinSettingsToImproveSignatures";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.6.180";
	Handler.Comment = NStr("vi = 'Thiết lập địa chỉ chuẩn của các máy chủ dấu thời gian.';
							|ru = 'Устанавливает стандартные адреса серверов меток времени.';
							|en = 'Defines the standard addresses for timestamp servers.'; fa = 'Defines the standard addresses for timestamp servers.';
							|it = 'Defines the standard addresses for timestamp servers.';
							|pl = 'Defines the standard addresses for timestamp servers.';
							|tr = 'Zaman damgası sunucularının varsayılan adreslerini ayarlar.'");
	Handler.Procedure = "DigitalSignatureInternal.FillinServerAddressesTimestamps";
	Handler.ExecutionMode = "Seamless";
		
	Handler = Handlers.Add();
	Handler.Version = "3.1.8.58";
	Handler.Comment =
		NStr("vi = 'Đang đặt chế độ sử dụng cho ứng dụng chữ ký điện tử và mã hóa.';
			|ru = 'Устанавливает режим использования для приложений электронной подписи и шифрования.';
			|en = 'Sets the usage mode for digital signature and encryption apps.'; fa = 'Sets the usage mode for digital signature and encryption apps.';
			|it = 'Устанавливает режим использования для приложений электронной подписи и шифрования.';
			|pl = 'Sets the usage mode for digital signature and encryption apps.';
			|tr = 'Elektronik imza ve şifreleme uygulamalarının kullanım şeklini belirler.'");
	Handler.Id = New UUID("ddaf9603-7641-470b-93cc-8754c9a64a99");
	Handler.Procedure = "Catalogs.DigitalSignatureAndEncryptionApplications.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.DigitalSignatureAndEncryptionApplications.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead      = "Catalog.DigitalSignatureAndEncryptionApplications";
	Handler.ObjectsToChange    = "Catalog.DigitalSignatureAndEncryptionApplications";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.9.122";
	Handler.Comment = NStr("vi = 'Xóa đường dẫn khỏi tên tệp chữ ký đã điền. Điền mã định danh chữ ký vào biểu ghi Chữ ký điện tử.';
							|ru = 'Удаление путей из заполненных имен файлов подписей. Заполнение идентификатора подписи в регистре Электронные подписи.';
							|en = 'Delete paths from filled in signature file names. Populate the signature ID in the ""Digital signatures"" register.'; fa = 'Delete paths from filled in signature file names. Populate the signature ID in the ""Digital signatures"" register.';
							|it = 'Удаление путей из заполненных имен файлов подписей. Заполнение идентификатора подписи в регистре Электронные подписи.';
							|pl = 'Delete paths from filled in signature file names. Populate the signature ID in the ""Digital signatures"" register.';
							|tr = 'Tamamlanan imza dosyası adlarından yolların silinmesi. Elektronik İmzalar kaydındaki imza kimliğinin doldurulması.'");
	Handler.Id = New UUID("927d1ffb-682a-474d-b3ea-5a40fd20ff08");
	Handler.Procedure = "InformationRegisters.DigitalSignatures.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "InformationRegisters.DigitalSignatures.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead      = "InformationRegister.DigitalSignatures";
	Handler.ObjectsToChange    = "InformationRegister.DigitalSignatures";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";

	Handler = Handlers.Add();
	Handler.Version = "3.1.10.185";
	Handler.Comment = NStr(
		"vi = 'Chuyển thông báo về kết thúc thời hạn hiệu lực của chứng thư, dữ liệu của yêu cầu đến biểu ghi thông tin, điền thời hạn hiệu lực của chứng thư có tính đến thời hạn hiệu lực của khóa riêng, xóa ứng dụng chữ ký điện tử được chọn không chính xác.';
		|ru = 'Перенос оповещений об окончании срока действия сертификата, данных заявлений в регистры сведений, заполнение срока действия сертификата с учетом срока действия закрытого ключа, очистка некорректно выбранного приложения электронной подписи.';
		|en = 'Transfer certificate expiration notifications and certificate application data to information registers. Fill in the certificate validity period considering the validity period of the private key. Discard digital signing apps selected by mistake.'; fa = 'Transfer certificate expiration notifications and certificate application data to information registers. Fill in the certificate validity period considering the validity period of the private key. Discard digital signing apps selected by mistake.';
		|it = 'Перенос оповещений об окончании срока действия сертификата, данных заявлений в регистры сведений, заполнение срока действия сертификата с учетом срока действия закрытого ключа, очистка некорректно выбранного приложения электронной подписи.';
		|pl = 'Transfer certificate expiration notifications and certificate application data to information registers. Fill in the certificate validity period considering the validity period of the private key. Discard digital signing apps selected by mistake.';
		|tr = 'Sertifikanın geçerlilik süresinin dolduğuna ilişkin bildirimlerin, başvuru verilerinin bilgi kayıt defterlerine aktarılması, özel anahtarın geçerlilik süresi dikkate alınarak sertifikanın geçerlilik süresinin doldurulması, hatalı seçilmiş bir elektronik imza başvurusunun silinmesi.'");
	Handler.Id = New UUID("a6c42e6b-4824-4f5e-a35d-aa0922b253f3");
	Handler.Procedure = "Catalogs.DigitalSignatureAndEncryptionKeysCertificates.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.DigitalSignatureAndEncryptionKeysCertificates.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead      = "Catalog.DigitalSignatureAndEncryptionKeysCertificates";
	ObjectsToChange = New Array;
	ObjectsToChange.Add("Catalog.DigitalSignatureAndEncryptionKeysCertificates");
	ObjectsToChange.Add("InformationRegister.CertificateUsersNotifications");
	If Metadata.InformationRegisters.Find("CertificateIssuanceApplications") <> Undefined Then
		ObjectsToChange.Add("InformationRegister.CertificateIssuanceApplications");
	EndIf;
	Handler.ObjectsToChange = StrConcat(ObjectsToChange, ",");
	Handler.ObjectsToLock = "Catalog.DigitalSignatureAndEncryptionKeysCertificates";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.11.61";
	Handler.Procedure = "DigitalSignatureInternal.EnableConstantAllowAccessToInternetServices";
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.12.68";
	Handler.Procedure = "DigitalSignatureInternal.AddRoleReadKeyCertificatesOfDigitalSignatureAndEncryption";
	Handler.ExecutionMode = "Seamless";

EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming.
Procedure OnAddMetadataObjectsRenaming(Renamings) Export
	
	Library = "StandardSubsystems";
	
	OldName = "Role.UseDDS";
	NewName  = "Role.UseDS";
	Common.AddRenaming(Renamings, "2.2.1.7", OldName, NewName, Library);
	
	OldName = "Subsystem.StandardSubsystems.Subsystem.DigitalSignature1";
	NewName  = "Subsystem.StandardSubsystems.Subsystem.DigitalSignature";
	Common.AddRenaming(Renamings, "2.2.1.7", OldName, NewName, Library);
	
	OldName = "Role.UseDS";
	NewName  = "Role.UseElectronicSignatureAndEncryption";
	Common.AddRenaming(Renamings, "2.3.1.10", OldName, NewName, Library);
	
	OldName = "Role.UseElectronicSignatureAndEncryption";
	NewName  = "Role.AddEditDigitalSignaturesAndEncryption";
	Common.AddRenaming(Renamings, "2.3.3.2", OldName, NewName, Library);
	
EndProcedure

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	
	If Common.SeparatedDataUsageAvailable() Then
		SubsystemSettings = New Structure;
		SubsystemSettings.Insert("PersonalSettings", DigitalSignature.PersonalSettings());
		SubsystemSettings.Insert("CommonSettings",        DigitalSignature.CommonSettings());
		SubsystemSettings = New FixedStructure(SubsystemSettings);
		Parameters.Insert("DigitalSignature", SubsystemSettings);
	EndIf;
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplateList.
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.ExtendSignatureValidity.Name);
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.ExtendSignatureValidity.MethodName);
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.OnDefineHandlerAliases(NamesAndAliasesMap)
	EndIf;
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// Cannot import to the DigitalSignatureAndEncryptionApplications catalog.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.DigitalSignatureAndEncryptionApplications.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
	// Cannot import to the DigitalSignatureAndEncryptionKeysCertificates catalog.
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.DigitalSignatureAndEncryptionApplications.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.FullName(), "AttributesToSkipInBatchProcessing");
EndProcedure

// Overrides shared data exceptions for the CloudTechnology subsystem. 
// 
// Parameters:
//  Exceptions - Array of MetadataObject - Exceptions.
//
Procedure OnDefineSharedDataExceptions(Exceptions) Export

	Exceptions.Add(Metadata.InformationRegisters.CertificateRevocationLists);
	
EndProcedure

// See Getting the external components of the Service model being redefined.When defining the used versions of the external components.
Procedure OnDefineAddInsVersionsToUse(IDs) Export

	IDs.Add(DigitalSignatureInternalClientServer.ComponentDetails().ObjectName);

EndProcedure

// See SSLSubsystemsIntegration.OnDefineUsedAddIns.
Procedure OnDefineUsedAddIns(Components) Export

	NewRow = Components.Add();
	NewRow.Id = DigitalSignatureInternalClientServer.ComponentDetails().ObjectName;
	NewRow.AutoUpdate = True;
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
Procedure OnDefineScheduledJobSettings(Settings) Export

	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
			ProcessingApplicationForNewQualifiedCertificateIssue.OnDefineScheduledJobSettings(Settings);
	EndIf;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ExtendSignatureValidity;
	
EndProcedure

// See the work of classificatorsperefineable.Adding classifiers.
Procedure OnAddClassifiers(Classifiers) Export
	
	DigitalSignatureLocalization.OnAddClassifiers(Classifiers);
	
EndProcedure

// See the work of classificatorsperefineable.The prize of the classifier's load.
Procedure OnImportClassifier(Id, Version, Address, Processed, AdditionalParameters) Export
	
	DigitalSignatureLocalization.OnImportClassifier(Id, Version, Address, Processed, AdditionalParameters);
	
EndProcedure

// See StandardSubsystemsServer.
Procedure OnSendDataToMaster(DataElement, ItemSend, Recipient) Export
	
	OnSendData(DataElement, ItemSend, False, False);
	
EndProcedure

// See StandardSubsystemsServer.OnSendDataToSlave.
Procedure OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Recipient) Export
	
	OnSendData(DataElement, ItemSend, True, InitialImageCreating);
	
EndProcedure

#Region AccessControlSubsystemEventHandlers

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates, True);
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.OnFillListsWithAccessRestriction(Lists);
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionKinds.
Procedure OnFillMetadataObjectsAccessRestrictionKinds(LongDesc) Export
	
	LongDesc = LongDesc + "
		|Catalog.DigitalSignatureAndEncryptionKeysCertificates.Read.Users
		|Catalog.DigitalSignatureAndEncryptionKeysCertificates.Update.Users";
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.OnFillMetadataObjectsAccessRestrictionKinds(LongDesc);
	EndIf;
	
	DigitalSignatureOverridable.OnFillMetadataObjectsAccessRestrictionKinds(LongDesc);
	
EndProcedure

#EndRegion

#Region ToDoListSubsystemEventHandlers

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Users.IsExternalUserSession() Then
		Return;
	EndIf;
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.CommonForms.DigitalSignatureAndEncryptionSettings.FullName());
	
	If DigitalSignature.ManageAlertsCertificates() Then
		
		NumberofCertificatesWithexpiringValidity = NumberofCertificatesWithexpiringValidity(); 
		
		For Each Section In Sections Do
			ToDoItem = ToDoList.Add ();
			ToDoItem.Id  = "CertificateRenewalRequired";
			ToDoItem.HasToDoItems       = NumberofCertificatesWithexpiringValidity > 0;
			ToDoItem.Presentation  = NStr("vi = 'Cần gia hạn chứng chỉ';
											|ru = 'Требуется продление сертификата';
											|en = 'Certificate needs to be renewed'; fa = 'Certificate needs to be renewed';
											|it = 'È richiesta la proroga del certificato';
											|pl = 'Wymagane jest przedłużenie certyfikatu';
											|tr = 'Sertifikanın yenilenmesi gerekiyor '");
			ToDoItem.Count     = NumberofCertificatesWithexpiringValidity;
			ToDoItem.Important         = False;
			ToDoItem.Form          = "CommonForm.DigitalSignatureAndEncryptionSettings";
			ToDoItem.FormParameters = New Structure("CertificatesShow", "MyCertificatesWithexpiringValidity");
			ToDoItem.Owner       = Section;
		EndDo;
		
		If DigitalSignature.CommonSettings().CertificateIssueRequestAvailable Then
			
			NumberofApplicationsInProgress = NumberofApplicationsInProgress();
			
			For Each Section In Sections Do
				ToDoItem = ToDoList.Add();
				ToDoItem.Id  = "CertificateIssuanceApplicationsInProgress";
				ToDoItem.HasToDoItems       = NumberofApplicationsInProgress > 0;
				ToDoItem.Presentation  = NStr("vi = 'Thông báo phát hành chứng chỉ đang làm việc';
												|ru = 'Заявления на выпуск сертификата в работе';
												|en = 'Submitted certificate applications'; fa = 'Submitted certificate applications';
												|it = 'Dichiarazione di emissione del certificato a lavoro';
												|pl = 'Wnioski o wydanie certyfikatu w pracy';
												|tr = 'Çalışma sırasında sertifika düzenleme başvuruları'");
				ToDoItem.Count     = NumberofApplicationsInProgress;
				ToDoItem.Important         = False;
				ToDoItem.Form          = "CommonForm.DigitalSignatureAndEncryptionSettings";
				ToDoItem.FormParameters = New Structure("CertificatesShow", "MyStatementsInProgress");
				ToDoItem.Owner       = Section;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	
	RefineSignaturesAutomatically = Constants.RefineSignaturesAutomatically.Get();
	
	If RefineSignaturesAutomatically = 2 Then
		
		Numberofsignaturesforimprovements = SignaturesCount("RequireImprovementSignatures");
		For Each Section In Sections Do
			ToDoItem = ToDoList.Add ();
			ToDoItem.Id  = "RequireImprovementSignatures";
			ToDoItem.HasToDoItems       = Numberofsignaturesforimprovements > 0;
			ToDoItem.Presentation  = NStr("vi = 'Nâng cấp chữ ký';
											|ru = 'Усовершенствовать подписи';
											|en = 'Enhance signatures'; fa = 'ارتقای امضاها';
											|it = 'Perfezionare la firma ';
											|pl = 'Udoskonal podpisy';
											|tr = 'İmzaları geliştir'");
			ToDoItem.Count     = Numberofsignaturesforimprovements;
			ToDoItem.Important         = False;
			ToDoItem.Form          = "CommonForm.RenewDigitalSignatures";
			ToDoItem.FormParameters = New Structure("ExtensionMode", "RequireImprovementSignatures");
			ToDoItem.Owner       = Section;
		EndDo;
		
		NumberofRawSignatures = SignaturesCount("rawsignatures");
		For Each Section In Sections Do
			ToDoItem = ToDoList.Add ();
			ToDoItem.Id  = "rawsignatures";
			ToDoItem.HasToDoItems       = NumberofRawSignatures > 0;
			ToDoItem.Presentation  = NStr("vi = 'Gia hạn chữ ký đã thêm từ trước';
											|ru = 'Продлить ранее добавленные подписи';
											|en = 'Renew previously added signatures'; fa = 'Renew previously added signatures';
											|it = 'Prorogare le registrazioni aggiunte precedentemente';
											|pl = 'Przedłuż wcześniej dodane podpisy';
											|tr = 'Daha önce eklenen imzaları yenile'");
			ToDoItem.Count     = NumberofRawSignatures;
			ToDoItem.Important         = False;
			ToDoItem.Form          = "CommonForm.RenewDigitalSignatures";
			ToDoItem.FormParameters = New Structure("ExtensionMode", "rawsignatures");
			ToDoItem.Owner       = Section;
		EndDo;
		
	ElsIf RefineSignaturesAutomatically = 1 Or Constants.AddTimestampsAutomatically.Get() Then
		
		NumberofErrorsonAutomaticRenewal = SignaturesCount("ErrorsOnAutoRenewal");
		For Each Section In Sections Do
			ToDoItem = ToDoList.Add ();
			ToDoItem.Id  = "ErrorsOnAutoRenewal";
			ToDoItem.HasToDoItems       = NumberofErrorsonAutomaticRenewal > 0;
			ToDoItem.Presentation  = NStr("vi = 'Lỗi khi tự động gia hạn chữ ký';
											|ru = 'Ошибки при автоматическом продлении подписей';
											|en = 'Automatic signature renewal errors'; fa = 'Automatic signature renewal errors';
											|it = 'Errori alla proroga automatica delle firme ';
											|pl = 'Błędy podczas automatycznego przedłużenia podpisów';
											|tr = 'İmzaların otomatik yenileme hataları'");
			ToDoItem.Count     = NumberofErrorsonAutomaticRenewal;
			ToDoItem.Important         = True;
			ToDoItem.Form          = "CommonForm.RenewDigitalSignatures";
			ToDoItem.FormParameters = New Structure("ExtensionMode", "ErrorsOnAutoRenewal");
			ToDoItem.Owner       = Section;
		EndDo;
		
	EndIf;
	
	Numberofsignaturestoaddarchivaltags = SignaturesCount("RequiredAddArchiveTags");
	For Each Section In Sections Do
		ToDoItem = ToDoList.Add ();
		ToDoItem.Id  = "RequiredAddArchiveTags";
		ToDoItem.HasToDoItems       = Numberofsignaturestoaddarchivaltags > 0;
		ToDoItem.Presentation  = NStr("vi = 'Gia hạn chữ ký đã lưu trữ';
										|ru = 'Продлить архивные подписи';
										|en = 'Renew archival signatures'; fa = 'Renew archival signatures';
										|it = 'Prorogare registrazioni di archivio';
										|pl = 'Przedłuż archiwalne podpisy';
										|tr = 'Arşiv imzaları yenile'");
		ToDoItem.Count     = Numberofsignaturestoaddarchivaltags;
		ToDoItem.Important         = False;
		ToDoItem.Form          = "CommonForm.RenewDigitalSignatures";
		ToDoItem.FormParameters = New Structure("ExtensionMode", "RequiredAddArchiveTags");
		ToDoItem.Owner       = Section;
	EndDo;

EndProcedure

#EndRegion

#Region ReportsOptionsSubsystemEventHandlers

// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.RenewDigitalSignatures);
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.DigitalSignatureCertificates);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

// For the procedure of stamping electronic signatures.
//
Procedure AddStampField(StampTextField, Name, Value)
	StampTextField.Add(New Structure("Name, Value", Name, Value));
EndProcedure

// For the OnReceiveDataFromMaster and OnReceiveDataFromSlave procedures.
Procedure OnSendData(DataElement, ItemSend, Subordinate1, InitialImageCreating)
	
	If InitialImageCreating Then
		Return;
	EndIf;
	
	If TypeOf(DataElement) = Type("ConstantValueManager.AllowAccessToDigitalSignatureInternetServices") Then
		ItemSend = DataItemSend.Ignore;
	EndIf;
	
EndProcedure

Function TimestampServersAddresses(String) Export
	Return StrSplit(String, ", ;" + Chars.LF + Chars.Tab + Chars.VTab, False);
EndFunction

// For internal use only.
// 
// Parameters:
//  ContainerSignatures - CryptoSignaturesContainer
//  UTCOffset - Number
//  SessionDate - Date
// 
// Returns:
//  Structure - Cryptographic signature parameters:
//   * SignatureType          - EnumRef.CryptographySignatureTypes
//   * DateActionLastTimestamp - Date, Undefined - Filled only using the cryptographic manager.
//   * DateSignedFromLabels - Date, Undefined - Date of the earliest timestamp.
//   * UnverifiedSignatureDate - Date - Unconfirmed signature data.
//                                 - Undefined - Unconfirmed signature data is missing from the signature data.
//   * DateLastTimestamp - Date - Date of the latest timestamp.
//   * Certificate   - CryptoCertificate - Signatory's certificate.
//   * CertificateDetails - See DigitalSignatureClient.CertificateProperties.
//
Function ParametersCryptoSignatures(ContainerSignatures, UTCOffset, SessionDate) Export

	SignatureParameters = DigitalSignatureInternalClientServer.NewSettingsSignaturesCryptography();
		
	Signature = ContainerSignatures.Signatures[0];
	
	IsCertificateExists = DigitalSignatureInternalClientServer.IsCertificateExists(Signature.SignatureCertificate);
	
	If IsCertificateExists Then
		SignatureParameters.Certificate = Signature.SignatureCertificate;
		SignatureParameters.CertificateDetails = DigitalSignature.CertificateProperties(Signature.SignatureCertificate);
	EndIf;
	
	Return DigitalSignatureInternalClientServer.ParametersCryptoSignatures(SignatureParameters, Signature, IsCertificateExists, UTCOffset, SessionDate);
	
EndFunction

// Obtains signature properties from the signature data. If the Cryptography service failed to obtain the properties, 
// it returns the properties read from the binary data.
// 
// Returns:
//   See DigitalSignatureInternalClientServer.ResultOfReadSignatureProperties
//   Map - If a signature array is passed.
//
Function SignatureProperties(Signatures, ShouldReadCertificates, UseCryptoManager = True) Export
	
	If TypeOf(Signatures) = Type("String") Or TypeOf(Signatures) = Type("BinaryData") Then
		SignaturesArray = CommonClientServer.ValueInArray(Signatures);
		Map = Undefined;
	Else
		SignaturesArray = Signatures;
		Map = New Map;
	EndIf;
	
	IsReadingByCryptoManager = UseCryptoManager 
		And (DigitalSignature.CommonSettings().VerifyDigitalSignaturesOnTheServer
			Or DigitalSignature.CommonSettings().GenerateDigitalSignaturesAtServer
			Or Common.FileInfobase());
	
	For Each Signature In SignaturesArray Do
	
		Result = DigitalSignatureInternalClientServer.ResultOfReadSignatureProperties();

		If IsReadingByCryptoManager Then
			ErrorDescription = "";
			CryptoManager = DigitalSignature.CryptoManager("ReadSignature", False, ErrorDescription,
				Signature); // CryptoManager
			If CryptoManager = Undefined Then
				Result.ErrorText = ErrorDescription;
			Else
				Result = SignaturePropertiesReadByCryptoManager(Signature, CryptoManager, ShouldReadCertificates);
				If Result.Success = True Then
					If Map = Undefined Then
						Return Result;
					Else
						Map.Insert(Signature, Result);
						Continue;
					EndIf;
				Else
					Result.Success = Undefined;
				EndIf;
			EndIf;
		EndIf;
		
		SignaturePropertiesFromBinaryData = SignaturePropertiesFromBinaryData(Signature, ShouldReadCertificates);
		FillPropertyValues(Result, SignaturePropertiesFromBinaryData, , "Success, ErrorText");

		If SignaturePropertiesFromBinaryData.Success = False Then
			Result.Success = False;
			Result.ErrorText = ?(IsBlankString(Result.ErrorText), "", Result.ErrorText + Chars.LF)
				+ SignaturePropertiesFromBinaryData.ErrorText;
		EndIf;
		
		If Map = Undefined Then
			Return Result;
		Else
			Map.Insert(Signature, Result);
		EndIf;
	
	EndDo;
	
	Return Map;
	
EndFunction

Function SignaturePropertiesReadByCryptoManager(Signature, CryptoManager, ShouldReadCertificates) Export
	
	Result = DigitalSignatureInternalClientServer.ResultOfReadSignatureProperties();
	
	BinaryData = DigitalSignatureInternalClientServer.BinaryDataFromTheData(Signature,
		"DigitalSignatureInternal.SignaturePropertiesReadByCryptoManager");
	
	Try
		ContainerSignatures = CryptoManager.GetCryptoSignaturesContainer(BinaryData);
	Except
		Result.Success = False;
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi đọc dữ liệu chữ ký: %1';
						|ru = 'При чтении данных подписи: %1';
						|en = 'When reading the signature data: %1'; fa = 'When reading the signature data: %1';
						|it = 'Alla lettura dei dati di firma: %1';
						|pl = 'Podczas odczytu danych podpisu: %1';
						|tr = 'İmza verilerin okunması sırasında: %1'"), ErrorProcessing.BriefErrorDescription(
					ErrorInfo()));
		Return Result;
	EndTry;

	ParametersCryptoSignatures = ParametersCryptoSignatures(
						ContainerSignatures, UTCOffset(), CurrentSessionDate());

	Result.SignatureType = ParametersCryptoSignatures.SignatureType;
	Result.DateActionLastTimestamp = ParametersCryptoSignatures.DateActionLastTimestamp;
	Result.UnverifiedSignatureDate = ParametersCryptoSignatures.UnverifiedSignatureDate;
	Result.DateSignedFromLabels = ParametersCryptoSignatures.DateSignedFromLabels;
	If ParametersCryptoSignatures.CertificateDetails <> Undefined Then
		Result.Thumbprint = ParametersCryptoSignatures.CertificateDetails.Thumbprint;
		Result.CertificateOwner = ParametersCryptoSignatures.CertificateDetails.IssuedTo;
	EndIf;

	If ShouldReadCertificates Then
		SignatureRow = ContainerSignatures.Signatures[0];
		If DigitalSignatureInternalClientServer.IsCertificateExists( 
					SignatureRow.SignatureCertificate) Then
			Result.Certificate = SignatureRow.SignatureCertificate.Unload();
		EndIf;
		For Each Certificate In SignatureRow.SignatureVerificationCertificates Do
			If DigitalSignatureInternalClientServer.IsCertificateExists(Certificate) Then
				Result.Certificates.Add(Certificate.Unload());
			EndIf;
		EndDo;
	EndIf;

	Result.Success = True;
	Return Result;
	
EndFunction

// Parameters:
//  Signature						 - BinaryData - Signing result.
//  ResultInValueStorage	 - Boolean -  Store the result to ValueStorage.
// 
// Returns:
//   BinaryData - Certificate's binary data.
//   Undefined - The signature doesn't contain cryptographic certificates.
//   ValueStorage - The result is also stored in "ValueStorage".
//
Function CertificateFromSignatureBinaryData(Signature, ResultInValueStorage = False) Export
	
	SignatureProperties = SignaturePropertiesFromBinaryData(Signature, True);
	
	Return ?(ResultInValueStorage,
		New ValueStorage(SignatureProperties.Certificate, New Deflation(9)),
		SignatureProperties.Certificate);
	
EndFunction

Function SignaturePropertiesFromBinaryData(Signature, ShouldReadCertificates) Export
	
	Result = DigitalSignatureInternalClientServer.ResultOfReadSignatureProperties();
	
	Try
		SignaturePropertiesFromBinaryData = DigitalSignatureInternalClientServer.SignaturePropertiesFromBinaryData(
			Signature, UTCOffset(), ShouldReadCertificates);
		If Not ValueIsFilled(SignaturePropertiesFromBinaryData.SignatureType) Then
			Result.ErrorText = NStr("vi = 'Dữ liệu không phải là chữ ký';
									|ru = 'Данные не являются подписью';
									|en = 'The data is not a signature.'; fa = 'The data is not a signature.';
									|it = 'Данные не являются подписью';
									|pl = 'The data is not a signature.';
									|tr = 'Veriler imza değildir'");
			Result.Success = False;
			Return Result;
		EndIf;
	Except
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể đọc thuộc tính chữ ký: %1';
				|ru = 'Не удалось прочитать свойства подписи: %1';
				|en = 'Cannot read the signature properties: %1'; fa = 'Cannot read the signature properties: %1';
				|it = 'Не удалось прочитать свойства подписи: %1';
				|pl = 'Cannot read the signature properties: %1';
				|tr = 'İmza özellikleri okunamadı: %1'"), ErrorProcessing.BriefErrorDescription(
			ErrorInfo()));
		Return Result;
	EndTry;

	Result.SignatureType = SignaturePropertiesFromBinaryData.SignatureType;

	If ValueIsFilled(SignaturePropertiesFromBinaryData.SigningDate) Then
		Result.UnverifiedSignatureDate = SignaturePropertiesFromBinaryData.SigningDate;
	EndIf;
	If ValueIsFilled(SignaturePropertiesFromBinaryData.DateOfTimeStamp) Then
		Result.DateSignedFromLabels = SignaturePropertiesFromBinaryData.DateOfTimeStamp;
	EndIf;

	If SignaturePropertiesFromBinaryData.Certificates.Count() > 0 Then
		
		If SignaturePropertiesFromBinaryData.Certificates.Count() > 1 Then
			Try
				Result.Certificates = CertificatesInOrderToRoot(
					SignaturePropertiesFromBinaryData.Certificates);
				Result.Certificate = ?(ValueIsFilled(SignaturePropertiesFromBinaryData.SignatureCertificate),
					SignaturePropertiesFromBinaryData.SignatureCertificate, Result.Certificates[0]);
			Except
				Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể đọc thuộc tính chứng thư: %1';
						|ru = 'Не удалось прочитать свойства сертификатов: %1';
						|en = 'Cannot read the properties of the certificates: %1'; fa = 'Cannot read the properties of the certificates: %1';
						|it = 'Не удалось прочитать свойства сертификатов: %1';
						|pl = 'Cannot read the properties of the certificates: %1';
						|tr = 'Sertifikaların özellikleri okunamadı: %1'"),
					ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			EndTry;
		Else
			Result.Certificate = ?(ValueIsFilled(SignaturePropertiesFromBinaryData.SignatureCertificate),
				SignaturePropertiesFromBinaryData.SignatureCertificate, SignaturePropertiesFromBinaryData.Certificates[0]);
		EndIf;
		
		Try
			Certificate = New CryptoCertificate(Result.Certificate);
			Result.Certificate = Certificate.Unload();
			CertificateProperties = DigitalSignature.CertificateProperties(Certificate);
			Result.Thumbprint = CertificateProperties.Thumbprint;
			Result.CertificateOwner = CertificateProperties.IssuedTo;
		Except
			Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể đọc thuộc tính chứng thư: %1';
						|ru = 'Не удалось прочитать свойства сертификата: %1';
						|en = 'Cannot read the certificate properties: %1'; fa = 'Cannot read the certificate properties: %1';
						|it = 'Не удалось прочитать свойства сертификата: %1';
						|pl = 'Cannot read the certificate properties: %1';
						|tr = 'Sertifikanın özellikleri okunamadı: %1'"),
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;

	EndIf;

	Result.Success = IsBlankString(Result.ErrorText);
	
	Return Result;

EndFunction

Procedure SetVisibilityOfRefToAppsTroubleshootingGuide(InstructionItem) Export
	
	URL = "";
	DigitalSignatureClientServerLocalization.OnDefineRefToAppsGuide("", URL);
	InstructionItem.Visible = Not IsBlankString(URL);
	
EndProcedure

// For internal use only.
//
// Parameters:
//  AddFromFiles - Boolean - Certificate is imported from a file.
//
// Returns:
//  Structure - Information records to be set on the form that contains the given properties.:
//   * Title - String - Label of the button that adds a certificate.
//   * ExtendedTooltipTitle - String - Extended tooltip of the button that adds a certificate.
//   * Purpose - String - See DigitalSignatureInternalClient.AddCertificateAfterPurposeChoice
//
Function CertificateAdditionCommandProperties(AddFromFiles = False) Export
	
	Result = New Structure("Title, ExtendedTooltipTitle, Purpose");
	
	If DigitalSignature.AddEditDigitalSignatures() Then
		
		If AddFromFiles Then
			Result.Title = NStr("vi = 'Để ký và mã hóa từ tệp...';
								|ru = 'Для подписания и шифрования из файлов...';
								|en = 'Signing & encryption certificate from file…'; fa = 'گواهی امضا و رمزگذاری از فایل…';
								|it = 'Signing & encryption certificate from file…';
								|pl = 'Signing & encryption certificate from file…';
								|tr = 'İmzalama ve şifreleme için dosyalardan...'");
			Result.ExtendedTooltipTitle = NStr("vi = 'Thêm để ký và mã hóa từ tệp';
												|ru = 'Добавить для подписания и шифрования из файлов';
												|en = 'Add signing & encryption certificate from file'; fa = 'افزودن گواهی امضا و رمزگذاری از فایل';
												|it = 'Add signing & encryption certificate from file';
												|pl = 'Add signing & encryption certificate from file';
												|tr = 'İmzalama ve şifreleme için dosyalardan ekle'");
			Result.Purpose = "ForSigningEncryptionAndDecryptionFromFiles";
		Else
			Result.Title = NStr("vi = 'Để ký và mã hóa từ kho chứa riêng...';
								|ru = 'Для подписания и шифрования из личного хранилища...';
								|en = 'Signing & encryption certificate from Personal store…'; fa = 'گواهی امضا و رمزگذاری از مخزن شخصی…';
								|it = 'Signing & encryption certificate from Personal store…';
								|pl = 'Signing & encryption certificate from Personal store…';
								|tr = 'İmzalama ve şifreleme için...'");
			If UseCloudSignatureService() Then
				Result.ExtendedTooltipTitle = NStr("vi = 'Thêm để ký và mã hóa trong số các chương trình đã cài đặt trên máy chủ DSS và trên máy tính';
													|ru = 'Добавить для подписания и шифрования из установленных на сервере DSS и на компьютере';
													|en = 'Add signing and encryption certificates installed on DSS server and computer'; fa = 'Add signing and encryption certificates installed on DSS server and computer';
													|it = 'Добавить для подписания и шифрования из установленных на сервере DSS и на компьютере';
													|pl = 'Add signing and encryption certificates installed on DSS server and computer';
													|tr = 'DSS sunucusuna ve bilgisayara kurulanlardan imzalama ve şifreleme için ekle'");
			ElsIf UseDigitalSignatureSaaS() Then
				Result.ExtendedTooltipTitle = NStr("vi = 'Thêm để ký và mã hóa trong số các chương trình đã cài đặt trong dịch vụ và trên máy tính';
													|ru = 'Добавить для подписания и шифрования из установленных в сервисе и на компьютере';
													|en = 'Add certificates to sign and encrypt from apps installed in the service and on the computer'; fa = 'Add certificates to sign and encrypt from apps installed in the service and on the computer';
													|it = 'Добавить для подписания и шифрования из установленных в сервисе и на компьютере';
													|pl = 'Add certificates to sign and encrypt from apps installed in the service and on the computer';
													|tr = 'Bilgisayara kurulanlardan imzalama ve şifreleme için ekle'");
			Else
				Result.ExtendedTooltipTitle = NStr("vi = 'Thêm để ký và mã hóa trong số các chương trình đã cài đặt trên máy tính';
													|ru = 'Добавить для подписания и шифрования из установленных на компьютере';
													|en = 'Add signing and encryption certificates installed on computer'; fa = 'Add signing and encryption certificates installed on computer';
													|it = 'Добавить для подписания и шифрования из установленных на компьютере';
													|pl = 'Add signing and encryption certificates installed on computer';
													|tr = 'Bilgisayara kurulanlardan imzalama ve şifreleme için ekle'");
			EndIf;
			Result.Purpose = "ToSignEncryptAndDecrypt";
		EndIf;
		
	Else
		
		If AddFromFiles Then
			Result.Title = NStr("vi = 'Để mã hóa và giải mã từ tệp...';
								|ru = 'Для шифрования и расшифровки из файлов...';
								|en = 'To encrypt and decrypt from files…'; fa = 'To encrypt and decrypt from files…';
								|it = 'To encrypt and decrypt from files…';
								|pl = 'To encrypt and decrypt from files…';
								|tr = 'Şifreleme ve deşifre için dosyalardan...'");
			Result.ExtendedTooltipTitle = NStr("vi = 'Thêm để mã hóa và giải mã từ tệp';
												|ru = 'Добавить для шифрования и расшифровки из файлов';
												|en = 'Add to encrypt and decrypt from files'; fa = 'Add to encrypt and decrypt from files';
												|it = 'Add to encrypt and decrypt from files';
												|pl = 'Add to encrypt and decrypt from files';
												|tr = 'Şifreleme ve deşifre için dosyalardan ekle'");
			Result.Purpose = "ForSigningEncryptionAndDecryptionFromFiles";
		Else
			Result.Title = NStr("vi = 'Để mã hóa và giải mã từ kho chứa riêng...';
								|ru = 'Для шифрования и расшифровки из личного хранилища...';
								|en = 'To encrypt and decrypt from personal store…'; fa = 'To encrypt and decrypt from personal store…';
								|it = 'To encrypt and decrypt from personal store…';
								|pl = 'To encrypt and decrypt from personal store…';
								|tr = 'İmzalama ve şifreleme için kişisel depolamadan...'");
			If UseCloudSignatureService() Then
				Result.ExtendedTooltipTitle = NStr("vi = 'Thêm để mã hóa và giải mã trong số các chương trình đã cài đặt trên máy chủ DSS và trên máy tính';
													|ru = 'Добавить для шифрования и расшифровки из установленных на сервере DSS и на компьютере';
													|en = 'Add signing and decryption certificates installed on DSS server and computer'; fa = 'Add signing and decryption certificates installed on DSS server and computer';
													|it = 'Добавить для шифрования и расшифровки из установленных на сервере DSS и на компьютере';
													|pl = 'Add signing and decryption certificates installed on DSS server and computer';
													|tr = 'DSS sunucusuna ve bilgisayara kurulanlardan şifreleme ve deşifre için ekle'");
			ElsIf UseDigitalSignatureSaaS() Then
				Result.ExtendedTooltipTitle = NStr("vi = 'Thêm để mã hóa và giải mã trong số các chương trình đã cài đặt trong dịch vụ và trên máy tính';
													|ru = 'Добавить для шифрования и расшифровки из установленных в сервисе и на компьютере';
													|en = 'Add certificates to encrypt and decrypt from applications installed in the service and on the computer'; fa = 'Add certificates to encrypt and decrypt from applications installed in the service and on the computer';
													|it = 'Добавить для шифрования и расшифровки из установленных в сервисе и на компьютере';
													|pl = 'Add certificates to encrypt and decrypt from applications installed in the service and on the computer';
													|tr = 'Bilgisayara kurulanlardan şifreleme ve deşifre için ekle'");
			Else
				Result.ExtendedTooltipTitle = NStr("vi = 'Thêm để mã hóa và giải mã trong số các chương trình đã cài đặt trên máy tính';
													|ru = 'Добавить для шифрования и расшифровки из установленных на компьютере';
													|en = 'Add certificates to encrypt and decrypt from applications installed on the computer'; fa = 'Add certificates to encrypt and decrypt from applications installed on the computer';
													|it = 'Добавить для шифрования и расшифровки из установленных на компьютере';
													|pl = 'Add certificates to encrypt and decrypt from applications installed on the computer';
													|tr = 'Bilgisayara kurulanlardan şifreleme ve deşifre için ekle'");
			EndIf;
			Result.Purpose = "ToEncryptAndDecrypt";
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// For internal use only.
Function ErrorCertificateMarkedAsRevoked() Export
	
	ErrorPresentation = New Structure;
	ErrorPresentation.Insert("ErrorText", NStr("vi = 'Chứng thư được đánh dấu là bị thu hồi.';
												|ru = 'Сертификат помечен как отозванный.';
												|en = 'The certificate is revoked.'; fa = 'The certificate is revoked.';
												|it = 'Сертификат помечен как отозванный.';
												|pl = 'The certificate is revoked.';
												|tr = 'Sertifika igeri çekildi olarak işaretlendi.'"));
	ErrorPresentation.Insert("Cause", NStr("vi = 'Có thể là, đã yêu cầu thu hồi chứng chỉ.';
											|ru = 'Возможно, подано заявление на отзыв сертификата.';
											|en = 'Probably, a certificate revocation application is submitted.'; fa = 'Probably, a certificate revocation application is submitted.';
											|it = 'Forse è stata presentata la dichiarazione di ritiro del certificato.';
											|pl = 'Możliwe, że jest podany wniosek o odwołanie certyfikatu.';
											|tr = 'Sertifikanın reddi için başvurulmuş olabilir.'"));
	ErrorPresentation.Insert("Decision", StringFunctions.FormattedString(
		NStr("vi = 'Trong menu <b>Hơn nữa</b> trong <a href=""%1"">thẻ chứng chỉ</a> có thể bỏ dấu <b>Chứng chỉ đã thu hồi</b>. Nhưng nếu chứng chỉ đã thu hồi tại trung tâm chứng thực thì sẽ không thể tạo chữ ký bởi chứng chỉ này.';
			|ru = 'В меню <b>Еще</b> в <a href=""%1"">карточке сертификата</a> можно снять пометку <b>Сертификат отозван</b>. Но если сертификат отозван в удостоверяющем центре, сделать подпись таким сертификатом будет все равно невозможно.';
			|en = 'In the <b>More actions</b> menu, in <a href=""%1"">certificate card</a>, you can clear the <b>Certificate revoked</b> mark. However, if a certificate is revoked by a certificate authority, you will not be able to sign with this certificate.'; fa = 'In the <b>More actions</b> menu, in <a href=""%1"">certificate card</a>, you can clear the <b>Certificate revoked</b> mark. However, if a certificate is revoked by a certificate authority, you will not be able to sign with this certificate.';
			|it = 'В меню <b>Еще</b> в <a href=""%1"">карточке сертификата</a> можно снять пометку <b>Сертификат отозван</b>. Но если сертификат отозван в удостоверяющем центре, сделать подпись таким сертификатом будет все равно невозможно.';
			|pl = 'In the <b>More actions</b> menu, in <a href=""%1"">certificate card</a>, you can clear the <b>Certificate revoked</b> mark. However, if a certificate is revoked by a certificate authority, you will not be able to sign with this certificate.';
			|tr = '<b>Daha fazla</b> menüsünde  <a href=""%1""> sertifika kartında <b>Sertifika</a> iptal edildi</b> işareti kaldırılabilir. Ancak sertifika bir sertifika onay merkezinde iptal edilirse, böyle bir sertifika ile imza yapmak imkansız olacaktır.'"),
		"OpenCertificate"));
	Return ErrorPresentation;
	
EndFunction

// For internal use only.
Function UsingKeyAsString(Number) Export
	
	Array = New Array;
	Map = New Map;
	Map.Insert(0, NStr("vi = 'Chữ ký số';
						|ru = 'Цифровая подпись';
						|en = 'Digital signature'; fa = 'امضای دیجیتال';
						|it = 'Digital signature';
						|pl = 'Digital signature';
						|tr = 'Dijital imza'"));
	Map.Insert(1, NStr("vi = 'Tính không thể phủ nhận';
						|ru = 'Неотрекаемость';
						|en = 'Non-repudiation'; fa = 'Non-repudiation';
						|it = 'Non-repudiation';
						|pl = 'Non-repudiation';
						|tr = 'Geri alınamaz'"));
	Map.Insert(2, NStr("vi = 'Mã hóa khóa';
						|ru = 'Шифрование ключей';
						|en = 'Encrypt keys'; fa = 'Encrypt keys';
						|it = 'Encrypt keys';
						|pl = 'Encrypt keys';
						|tr = 'Anahtar şifreleme'"));
	Map.Insert(3, NStr("vi = 'Mã hóa dữ liệu';
						|ru = 'Шифрование данных';
						|en = 'Encrypt data'; fa = 'Encrypt data';
						|it = 'Crittografia dei dati';
						|pl = 'Szyfrowanie danych';
						|tr = 'Veri şifrelemesi'"));
	Map.Insert(4, NStr("vi = 'Thỏa thuận khóa';
						|ru = 'Согласование ключей';
						|en = 'Negotiate keys'; fa = 'Negotiate keys';
						|it = 'Negotiate keys';
						|pl = 'Negotiate keys';
						|tr = 'Anahtar mutabakatı'"));
	Map.Insert(5, NStr("vi = 'Ký chứng thư';
						|ru = 'Подписывание сертификатов';
						|en = 'Sign certificates'; fa = 'Sign certificates';
						|it = 'Sign certificates';
						|pl = 'Sign certificates';
						|tr = 'Sertifikaların imzalanması'"));
	Map.Insert(6, NStr("vi = 'Ký danh sách thu hồi';
						|ru = 'Подписывание списков отзыва';
						|en = 'Sign certificate revocation lists'; fa = 'Sign certificate revocation lists';
						|it = 'Sign certificate revocation lists';
						|pl = 'Sign certificate revocation lists';
						|tr = 'Geri bildirim listelerinin imzalanması'"));
	Map.Insert(7, NStr("vi = 'Chỉ mã hóa';
						|ru = 'Только шифрование';
						|en = 'Encrypt only'; fa = 'Encrypt only';
						|it = 'Encrypt only';
						|pl = 'Encrypt only';
						|tr = 'Sadece şifreleme'"));
	Map.Insert(8, NStr("vi = 'Chỉ giải mã';
						|ru = 'Только расшифровка';
						|en = 'Decrypt only'; fa = 'Decrypt only';
						|it = 'Decrypt only';
						|pl = 'Decrypt only';
						|tr = 'Sadece deşifre'"));
	
	For Var_198_Number = 0 To 8 Do
		If CheckBit(Number, Var_198_Number) Then
			Array.Add(Map.Get(Var_198_Number));
		EndIf;
	EndDo;
	
	Return StrConcat(Array, ", ");
	
EndFunction

// Returns additional parameters of the crypto manager creation.
//
// Returns:
//   Structure:
//    * ShowError     - Boolean - if True, throw an exception that contains the error description.
//
//    * ErrorDescription     - String - an error description that is returned when the function returns Undefined.
//                         - Structure - See DigitalSignatureInternalClientServer.NewErrorsDescription
//
//    * Application          - Undefined - returns a crypto manager of the first
//                         app from the catalog for which it was possible to create it.
//                         - CatalogRef.DigitalSignatureAndEncryptionApplications - App for which
//                         a crypto manager must be created and returned.
//                         - Structure - See DigitalSignature.NewApplicationDetails
//
//    * SignAlgorithm    - String - If specified, returns an app that uses this signature algorithm.
//    * EncryptAlgorithm - String - If specified, returns an application with the given encryption algorithm.
//    * AutoDetect    - Boolean - Flag indicating whether to detect installed apps.
//
Function CryptoManagerCreationParameters() Export
	
	CryptoManagerCreationParameters = New Structure;
	CryptoManagerCreationParameters.Insert("Application", Undefined);
	CryptoManagerCreationParameters.Insert("ShowError", False);
	CryptoManagerCreationParameters.Insert("ErrorDescription", "");
	CryptoManagerCreationParameters.Insert("SignAlgorithm", "");
	CryptoManagerCreationParameters.Insert("EncryptAlgorithm", "");
	CryptoManagerCreationParameters.Insert("AutoDetect", True);
	
	Return CryptoManagerCreationParameters;
	
EndFunction

// Returns the crypto manager (on the server) for the specified app.
//
// Parameters:
//  Operation                       - String - If not blank, it must contain one of the strings that determine
//                                 the operation to be inserted in the error details: Signing, SignatureCheck, Encryption,
//                                 Decryption, CertificateCheck, and GetCertificates.
//  CryptoManagerParameters - See CryptoManagerCreationParameters.
//
// Returns:
//   CryptoManager - -a crypto manager.
//   Undefined - an error occurred. The error description is in the ErrorDescription parameter.
//
Function CryptoManager(Operation, CryptoManagerCreationParameters = Undefined) Export
	
	If CryptoManagerCreationParameters = Undefined Then
		CryptoManagerCreationParameters = CryptoManagerCreationParameters();
	EndIf;
	
	Application			= CryptoManagerCreationParameters.Application;
	ShowError		= CryptoManagerCreationParameters.ShowError;
	SignAlgorithm		= CryptoManagerCreationParameters.SignAlgorithm;
	EncryptAlgorithm	= CryptoManagerCreationParameters.EncryptAlgorithm;
	AutoDetect		= CryptoManagerCreationParameters.AutoDetect;
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("Operation", Operation);
	AdditionalParameters.Insert("AutoDetect", AutoDetect);
	AdditionalParameters.Insert("SignAlgorithm", SignAlgorithm);
	AdditionalParameters.Insert("EncryptAlgorithm", EncryptAlgorithm);
	
	ComputerName = ComputerName();
	ErrorsDescription = DigitalSignatureInternalClientServer.NewErrorsDescription(ComputerName);
	Manager = NewCryptoManager(Application, ErrorsDescription.Errors, AdditionalParameters);
	
	If Manager <> Undefined Then
		Return Manager;
	EndIf;
	
	If Operation = "Signing" Then
		ErrorTitle = NStr("vi = 'Không thể ký dữ liệu trên máy chủ %1 do nguyên nhân:';
							|ru = 'Не удалось подписать данные на сервере %1 по причине:';
							|en = 'Cannot sign data on server %1 due to:'; fa = 'Cannot sign data on server %1 due to:';
							|it = 'Non è stato possibile firmare i dati sul server %1 a causa di:';
							|pl = 'Nie można podpisać danych na serwerze %1 z powodu:';
							|tr = '%1 sunucusunda veriler şu sebeple imzalanamadı:'");
		
	ElsIf Operation = "CheckSignature" Then
		ErrorTitle = NStr("vi = 'Không thể kiểm tra chữ ký trên máy chủ %1 do nguyên nhân:';
							|ru = 'Не удалось проверить подпись на сервере %1 по причине:';
							|en = 'Cannot verify the signature on server %1 due to:'; fa = 'Cannot verify the signature on server %1 due to:';
							|it = 'Non è stato possibile firmare i dati sul server %1 a causa di:';
							|pl = 'Nie można zweryfikować podpisu na serwerze %1 z powodu:';
							|tr = '%1 sunucusunda imza şu sebeple denetlenemedi:'");
	
	ElsIf Operation = "Encryption" Then
		ErrorTitle = NStr("vi = 'Không thể mã hóa dữ liệu trên máy chủ %1 do nguyên nhân:';
							|ru = 'Не удалось зашифровать данные на сервере %1 по причине:';
							|en = 'Cannot encrypt data on server %1 due to:'; fa = 'Cannot encrypt data on server %1 due to:';
							|it = 'Non è stato possibile crittografare i dati sul server %1 a causa di:';
							|pl = 'Nie można zaszyfrować danych na serwerze %1 z powodu:';
							|tr = '%1 sunucusunda veriler şu sebeple şifrelenemedi:'");
		
	ElsIf Operation = "Details" Then
		ErrorTitle = NStr("vi = 'Không thể giải mã dữ liệu trên máy chủ %1 do nguyên nhân:';
							|ru = 'Не удалось расшифровать данные на сервере %1 по причине:';
							|en = 'Cannot decrypt data on server %1 due to:'; fa = 'Cannot decrypt data on server %1 due to:';
							|it = 'Non è stato possibile crittografare i dati sul server %1 a causa di:';
							|pl = 'Nie można odszyfrować danych na serwerze %1 z powodu:';
							|tr = '%1 sunucusunda veriler şu sebeple detaylandırılamadı:'");
		
	ElsIf Operation = "CertificateCheck" Then
		ErrorTitle = NStr("vi = 'Không thể kiểm tra chứng chỉ trên máy chủ %1 do nguyên nhân:';
							|ru = 'Не удалось проверить сертификат на сервере %1 по причине:';
							|en = 'Cannot verify the certificate on server %1 due to:'; fa = 'Cannot verify the certificate on server %1 due to:';
							|it = 'Non è stato possibile verificare il certificato sul server %1 a causa di:';
							|pl = 'Nie można zweryfikować certyfikatu na serwerze %1 z powodu:';
							|tr = '%1 sunucusunda sertifika şu sebeple denetlenemedi:'");
		
	ElsIf Operation = "GetCertificates" Then
		ErrorTitle = NStr("vi = 'Không thể nhận chứng chỉ trên máy chủ %1 do nguyên nhân:';
							|ru = 'Не удалось получить сертификаты на сервере %1 по причине:';
							|en = 'Cannot receive certificates on server %1 due to:'; fa = 'Cannot receive certificates on server %1 due to:';
							|it = 'Non è stato possibile ricevere i certificati sul server %1 a causa di:';
							|pl = 'Nie udało się uzyskać certyfikatów na serwerze %1 z powodu:';
							|tr = '%1 sunucusunda sertifikalar şu sebeple alınamadı:'");
	
	ElsIf Operation = "ReadSignature" Then
		ErrorTitle = NStr("vi = 'Không thể đọc tất cả thuộc tính chữ ký trên máy chủ %1 theo nguyên nhân:';
							|ru = 'Не удалось прочитать все свойства подписи на сервере %1 по причине:';
							|en = 'Cannot read all the signature properties on the %1 server due to:'; fa = 'Cannot read all the signature properties on the %1 server due to:';
							|it = 'Не удалось прочитать все свойства подписи на сервере %1 по причине:';
							|pl = 'Cannot read all the signature properties on the %1 server due to:';
							|tr = '%1 sunucusundaki tüm imza özelliklerinin okunamama nedeni:'");
		
	ElsIf Operation = "ExtensionValiditySignature" Then
		ErrorTitle = NStr("vi = 'Không thể nâng cấp chữ ký trên máy chủ %1 do nguyên nhân:';
							|ru = 'Не удалось усовершенствовать подписи на сервере %1 по причине:';
							|en = 'Couldn''t enhance signatures on server %1 due to:'; fa = 'Couldn''t enhance signatures on server %1 due to:';
							|it = 'Non è stato possibile perfezionare la firma sul server %1 a causa di:';
							|pl = 'Nie można udoskonalić podpisu na serwerze %1 z powodu:';
							|tr = '%1 sunucusunda imzalar şu sebeple geliştirilemedi:'");
		
	ElsIf Operation <> "" Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lỗi gọi ra hàm %1.
			           |Sai giá trị tham số Giao dịch ""%2"".';
			           |ru = 'Ошибка вызова функции %1.
			           |Неверное значение параметра Операция ""%2"".';
			           |en = 'The %1 function call error.
			           |The ""Operation"" parameter has invalid value ""%2"".'; fa = 'The %1 function call error.
			           |The ""Operation"" parameter has invalid value ""%2"".';
			           |it = 'Ошибка вызова функции %1.
			           |Неверное значение параметра Операция ""%2"".';
			           |pl = 'The %1 function call error.
			           |The ""Operation"" parameter has invalid value ""%2"".';
			           |tr = '%1 fonksiyonu çağrılırken hata oluştu.
			           |""%2""İşlem parametre değeri geçersiz.'"), "CryptoManager", Operation);
		Raise(ErrorText, ErrorCategory.ConfigurationError);
		
	ElsIf TypeOf(CryptoManagerCreationParameters.ErrorDescription) = Type("Structure")
		And CryptoManagerCreationParameters.ErrorDescription.Property("ErrorTitle") Then
		
		ErrorTitle = CryptoManagerCreationParameters.ErrorDescription.ErrorTitle;
	Else
		ErrorTitle = NStr("vi = 'Không thể thực hiện giao dịch trên máy chủ %1 do nguyên nhân:';
							|ru = 'Не удалось выполнить операцию на сервере %1 по причине:';
							|en = 'Cannot perform the operation on server %1. Reason:'; fa = 'Cannot perform the operation on server %1. Reason:';
							|it = 'Non è stato possibile eseguire l''operazione sul server %1 a causa di:';
							|pl = 'Nie można wykonać operacji na serwerze %1 z powodu:';
							|tr = '%1 sunucusunda işlem şu sebeple yürütülemedi:'");
	EndIf;
	
	ErrorTitle = StrReplace(ErrorTitle, "%1", ComputerName);
	ErrorsDescription.ErrorTitle = ErrorTitle;
	
	DigitalSignatureInternalClientServer.CryptoManagerFillErrorsPresentation(
		ErrorsDescription,
		Application,
		SignAlgorithm,
		Users.IsFullUser(,, False),
		True);
	
	If TypeOf(CryptoManagerCreationParameters.ErrorDescription) = Type("Structure") Then
		CryptoManagerCreationParameters.ErrorDescription = ErrorsDescription;
	Else
		CryptoManagerCreationParameters.ErrorDescription = ErrorsDescription.ErrorDescription;
	EndIf;
	
	If ShowError Then
		Raise ErrorsDescription.ErrorDescription;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns an array with the server-side certificate thumbprints.
//
Function CertificateThumbprints(OnlyPersonal, ErrorDescription) Export
	
	ThumbprintsArray = New Array;
	
	If DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ShowError = ErrorDescription;
		CryptoManager = CryptoManager("GetCertificates", CreationParameters);
		
		Error = CreationParameters.ErrorDescription;
		If CryptoManager <> Undefined Then
			
			ThumbprintsArray = CertificateThumbprintsInStore(
				CryptoManager, CryptoCertificateStoreType.PersonalCertificates, Error);
			
			If Not OnlyPersonal Then
				CommonClientServer.SupplementArray(ThumbprintsArray,
					CertificateThumbprintsInStore(
						CryptoManager, CryptoCertificateStoreType.RecipientCertificates, Error),
					True);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return ThumbprintsArray;
	 
EndFunction

// Returns an array with the service-side certificate thumbprint.
//
Function ServiceCertificateThumbprints() Export
	
	ThumbprintsArray = New Array;
	
	If UseCloudSignatureService() Then
		
		DigitalSignatureLocalization.OnGetCloudServiceThumbprints(ThumbprintsArray);
	
	EndIf;
	
	Return ThumbprintsArray;
	
EndFunction

// Finds a certificate on the computer by a thumbprint string.
//
// Parameters:
//   Thumbprint              - String - a Base64 coded certificate thumbprint.
//   InPersonalStorageOnly - Boolean - if True, search in the Personal store, otherwise, search everywhere.
//
// Returns:
//   CryptoCertificate - certificate of digital signature and encryption.
//   Undefined - the certificate does not exist.
//
Function GetCertificateByThumbprint(Thumbprint, InPersonalStorageOnly,
			ShowError = True, Application = Undefined, ErrorDescription = "") Export
	
	CreationParameters = CryptoManagerCreationParameters();
	CreationParameters.Application = Application;
	CreationParameters.ShowError = ShowError;
	CreationParameters.ErrorDescription = ErrorDescription;
	
	CryptoManager = CryptoManager("GetCertificates", CreationParameters);
	
	ErrorDescription = CreationParameters.ErrorDescription;
	If CryptoManager = Undefined Then
		Return Undefined;
	EndIf;
	
	StoreType = DigitalSignatureInternalClientServer.StorageTypeToSearchCertificate(InPersonalStorageOnly);
	
	Try
		ThumbprintBinaryData = Base64Value(Thumbprint);
	Except
		If ShowError Then
			Raise;
		EndIf;
		ErrorInfo = ErrorInfo();
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;
	
	If Not ValueIsFilled(ErrorPresentation) Then
		Try
			CryptoCertificateStore = CryptoManager.GetCertificateStore(StoreType);
		Except
			If ShowError Then
				Raise;
			EndIf;
			ErrorInfo = ErrorInfo();
			ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		EndTry;
	EndIf;
	
	If Not ValueIsFilled(ErrorPresentation) Then
		Try
			Certificate = CryptoCertificateStore.FindByThumbprint(ThumbprintBinaryData);
		Except
			If ShowError Then
				Raise;
			EndIf;
			ErrorInfo = ErrorInfo();
			ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		EndTry;
	EndIf;
	
	If TypeOf(Certificate) = Type("CryptoCertificate") Then
		Return Certificate;
	EndIf;
	
	If ValueIsFilled(ErrorPresentation) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa cài đặt chứng chỉ trên máy chủ do nguyên nhân:
			           |%1';
			           |ru = 'Сертификат не установлен на сервере по причине:
			           |%1';
			           |en = 'The certificate was not installed on the server due to:
			           |%1'; fa = 'The certificate was not installed on the server due to:
			           |%1';
			           |it = 'Certificato non installato nel server a causa di:
			           |%1';
			           |pl = 'Nie zainstalowano certyfikatu na serwerze z powodu:
			           |%1';
			           |tr = 'Sunucuda sertifika şu sebeple ayarlanmadı:
			           |%1'")
			+ Chars.LF,
			ErrorPresentation);
	Else
		ErrorText = NStr("vi = 'Chưa cài đặt chứng chỉ trên máy chủ.';
						|ru = 'Сертификат не установлен на сервере.';
						|en = 'The certificate was not installed on the server.'; fa = 'The certificate was not installed on the server.';
						|it = 'Certificato non installato nel server.';
						|pl = 'Nie zainstalowano certyfikatu na serwerze.';
						|tr = 'Sunucuda sertifika ayarlanmadı.'");
	EndIf;
		
	If Not Users.IsFullUser(,, False) Then
		ErrorText = ErrorText + Chars.LF + NStr("vi = 'Hãy liên hệ với người quản trị.';
												|ru = 'Обратитесь к администратору.';
												|en = 'Please contact the application administrator.'; fa = 'Please contact the application administrator.';
												|it = 'Contattate l''amministratore.';
												|pl = 'Skontaktuj się z administratorem.';
												|tr = 'Yöneticiye başvurun.'")
	EndIf;
	
	ErrorText = TrimR(ErrorText);
	
	If TypeOf(ErrorDescription) = Type("Structure") Then
		ErrorDescription = New Structure;
		ErrorDescription.Insert("ErrorDescription", ErrorText);
	Else
		ErrorDescription = ErrorPresentation;
	EndIf;
	
	Return Undefined;
	
EndFunction

// For internal use only.
Function UTCOffset() Export
	
	Return CurrentSessionDate() - CurrentUniversalDate();
	
EndFunction

// Saves the current user settings to work with the digital signature.
Procedure SavePersonalSettings(PersonalSettings) Export
	
	SubsystemKey = SettingsStorageKey();
	
	For Each KeyAndValue In PersonalSettings Do
		Common.CommonSettingsStorageSave(SubsystemKey, KeyAndValue.Key,
			KeyAndValue.Value);
	EndDo;
	
EndProcedure

// The key that is used to store subsystem settings.
Function SettingsStorageKey() Export
	
	Return "DS1"; // Do not replace with "ES". Intended for the backward compatibility purposes.
	
EndFunction

// Returns:
//  Structure:
//   * ReadOnly     - Boolean - if you set True, editing will be prohibited.
//   * FillChecking - Boolean - if you set True, filling will be checked.
//   * Visible          - Boolean - if you set True, the attribute will become hidden.
//   * FillValue - Arbitrary - an initial attribute value of the new object.
//                        - Undefined - filling is not required.
//
Function TheNewSettingsOfTheRequisiteCertificate()
	
	Parameters = New Structure;
	Parameters.Insert("ReadOnly", False);
	Parameters.Insert("FillChecking", False);
	Parameters.Insert("Visible", False);
	Parameters.Insert("FillValue", Undefined);
	
	Return Parameters;
	
EndFunction

// Returns:
//  Structure:
//   * Description - See TheNewSettingsOfTheRequisiteCertificate
//   * Organization  - See TheNewSettingsOfTheRequisiteCertificate
//   * EnterPasswordInDigitalSignatureApplication - See TheNewSettingsOfTheRequisiteCertificate
//
Function NewParametersForCertificateDetails() Export
	
	Return New Structure;
	
EndFunction

// For internal use only.
// Parameters:
//  Ref - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//  Certificate - CryptoCertificate
//  AttributesParameters - See NewParametersForCertificateDetails
//
Procedure BeforeStartEditKeyCertificate(Ref, Certificate, AttributesParameters) Export
	
	Table = New ValueTable;
	Table.Columns.Add("AttributeName",       New TypeDescription("String"));
	Table.Columns.Add("ReadOnly",     New TypeDescription("Boolean"));
	Table.Columns.Add("FillChecking", New TypeDescription("Boolean"));
	Table.Columns.Add("Visible",          New TypeDescription("Boolean"));
	Table.Columns.Add("FillValue");
	
	DigitalSignatureOverridable.BeforeStartEditKeyCertificate(Ref, Certificate, Table);
	
	AttributesParameters = NewParametersForCertificateDetails();
	
	For Each TableRow In Table Do
		Parameters = TheNewSettingsOfTheRequisiteCertificate();
		FillPropertyValues(Parameters, TableRow);
		AttributesParameters.Insert(TableRow.AttributeName, Parameters);
	EndDo;
	
EndProcedure

// For internal use only.
Procedure CheckPresentationUniqueness(Presentation, CertificateReference, Field, Cancel) Export
	
	If Not ValueIsFilled(Presentation) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Ref",       CertificateReference);
	Query.SetParameter("Description", Presentation);
	
	SetPrivilegedMode(True);
	
	Query.Text =
	"SELECT
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Ref <> &Ref
	|	AND Certificates.Description = &Description";
	
	If Not Query.Execute().IsEmpty() Then
		MessageText = NStr("vi = 'Đã có chứng chỉ với tên trình bày như vậy.';
							|ru = 'Сертификат с таким представлением уже существует.';
							|en = 'Certificate with such presentation already exists'; fa = 'Certificate with such presentation already exists';
							|it = 'Certificato con tali specifiche già esistente.';
							|pl = 'Certyfikat z tym zgłoszeniem już istnieje.';
							|tr = 'Bu sunuma sahip bir sertifika zaten var.'");
		Common.MessageToUser(MessageText,, Field,, Cancel);
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// For internal use only.
Function SignatureInfoForEventLog(SignatureDate, SignatureProperties, IsSigningError = False) Export
	
	CertificateProperties = New Structure;
	CertificateProperties.Insert("SerialNumber", Base64Value(""));
	CertificateProperties.Insert("IssuedBy", "");
	CertificateProperties.Insert("IssuedTo", "");
	CertificateProperties.Insert("StartDate", '00010101');
	CertificateProperties.Insert("EndDate", '00010101');
	CertificateProperties.Insert("ValidBefore", '00010101');
	
	NewSignatureProperties = DigitalSignatureClientServer.NewSignatureProperties();
	FillPropertyValues(NewSignatureProperties, SignatureProperties);
	
	If NewSignatureProperties.CertificateDetails <> Undefined Then
		FillPropertyValues(CertificateProperties, NewSignatureProperties.CertificateDetails);
		If Not ValueIsFilled(CertificateProperties.ValidBefore) Then
			CertificateProperties.ValidBefore = CertificateProperties.EndDate;
		EndIf;
	Else
		
		If TypeOf(NewSignatureProperties.Certificate) = Type("String")
		   And IsTempStorageURL(NewSignatureProperties.Certificate) Then
			Certificate = GetFromTempStorage(NewSignatureProperties.Certificate);
		Else
			Certificate = NewSignatureProperties.Certificate;
		EndIf;
		
		If TypeOf(Certificate) = Type("BinaryData") Then
			CryptoCertificate = New CryptoCertificate(Certificate);
			CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
		Else
			CertificateProperties.IssuedTo = NewSignatureProperties.CertificateOwner;
		EndIf;
	EndIf;
	
	If IsSigningError Then
		SignatureInformation = "";
	Else
		SignatureInformation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Ngày ký: %1';
				|ru = 'Дата подписи: %1';
				|en = 'Signed on: %1'; fa = 'Signed on: %1';
				|it = 'Data firma: %1';
				|pl = 'Data podpisu: %1';
				|tr = 'İmza tarihi: %1'"), Format(SignatureDate, "DLF=DT")) + Chars.LF;
	EndIf;
	
	SignatureInformation = SignatureInformation + DigitalSignatureInternalClientServer.DetailsCertificateString(CertificateProperties);
	
	Return SignatureInformation;
	
EndFunction

// For internal use only.
Procedure RegisterDataSigningInLog(DataElement, ErrorDescription = "") Export
	
	IsSigningError = ValueIsFilled(ErrorDescription);
	
	If TypeOf(DataElement.SignatureProperties) = Type("String") Then
		SignatureProperties = GetFromTempStorage(DataElement.SignatureProperties);
	Else
		SignatureProperties = DataElement.SignatureProperties;
	EndIf;
	
	EventLogMessage = SignatureInfoForEventLog(
		SignatureProperties.SignatureDate, SignatureProperties, IsSigningError);
	
	If IsSigningError Then
		EventName = NStr("vi = 'Chữ ký điện tử.Lỗi ký dữ liệu';
						|ru = 'Электронная подпись.Ошибка подписания данных';
						|en = 'Digital signature.Data signing error'; fa = 'Digital signature.Data signing error';
						|it = 'Firma elettronica. Errore nella firma dei dati';
						|pl = 'Podpis elektroniczny.Błąd podpisywania danych';
						|tr = 'Dijital imza. Veri imzalama hatası'",
			Common.DefaultLanguageCode());
		
		EventLogMessage = EventLogMessage + "
		|
		|" + ErrorDescription;
	Else
		EventName = NStr("vi = 'Chữ ký điện tử.Ký dữ liệu';
						|ru = 'Электронная подпись.Подписание данных';
						|en = 'Digital signature.Data signing'; fa = 'Digital signature.Data signing';
						|it = 'Firma elettronica. Firma dei dati';
						|pl = 'Podpis elektroniczny.Podpisywanie danych';
						|tr = 'Dijital imza.Veri imzalama'",
			Common.DefaultLanguageCode());
	EndIf;
	
	If Common.IsReference(TypeOf(DataElement.DataPresentation)) Then
		DataItemMetadata = DataElement.DataPresentation.Metadata();
	Else
		DataItemMetadata = Undefined;
	EndIf;
	
	WriteLogEvent(EventName,
		EventLogLevel.Information,
		DataItemMetadata,
		DataElement.DataPresentation,
		EventLogMessage);
	
EndProcedure



// For internal use only.
Procedure UpdateCertificatesList(Certificates, CertificatesPropertiesAtClient, ButAlreadyAddedOnes,
				Personal, Error, NoFilter, AdditionalParameters = Undefined) Export
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FilterByCompany = AdditionalParameters.FilterByCompany;
		ExecuteAtServer = AdditionalParameters.ExecuteAtServer;
		AreAvailableOnlyWithKey = AdditionalParameters.AreAvailableOnlyWithKey;
	Else
		FilterByCompany = Undefined;
		ExecuteAtServer = Undefined;
		AreAvailableOnlyWithKey = False;
	EndIf;
	
	CertificatesPropertiesTable = New ValueTable;
	CertificatesPropertiesTable.Columns.Add("Thumbprint", New TypeDescription("String", , New StringQualifiers(255)));
	CertificatesPropertiesTable.Columns.Add("IssuedBy");
	CertificatesPropertiesTable.Columns.Add("Presentation");
	CertificatesPropertiesTable.Columns.Add("AtClient",            New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("AtServer",            New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("IsRequest",         New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("InCloudService",     New TypeDescription("Boolean"));
	CertificatesPropertiesTable.Columns.Add("LocationType",        New TypeDescription("Number"));
	CertificatesPropertiesTable.Columns.Add("CertificateStatus", New TypeDescription("Number"));
	CertificatesPropertiesTable.Columns.Add("Isinthedirectory",     New TypeDescription("Boolean"));
	
	For Each CertificateProperties In CertificatesPropertiesAtClient Do
		NewRow = CertificatesPropertiesTable.Add();
		FillPropertyValues(NewRow, CertificateProperties);
		NewRow.AtClient = True;
	EndDo;
	
	CertificatesPropertiesTable.Indexes.Add("Thumbprint");
	
	If DigitalSignature.GenerateDigitalSignaturesAtServer()
	   And ExecuteAtServer <> False Then
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ErrorDescription = Error;
		
		CryptoManager = CryptoManager("GetCertificates", CreationParameters);
		
		Error = CreationParameters.ErrorDescription;
		If CryptoManager <> Undefined Then
			
			Try
				CertificatesArray = CryptoManager.GetCertificateStore(
					CryptoCertificateStoreType.PersonalCertificates).GetAll();
				DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable,
					CertificatesArray, NoFilter, UTCOffset(), CurrentSessionDate());
			Except
				ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				If TypeOf(Error) = Type("Structure") Then
					Error = DigitalSignatureInternalClientServer.NewErrorsDescription(ComputerName());
					Error.ErrorDescription = ErrorDescription;
				Else
					Error = ErrorDescription;
				EndIf;
			EndTry;

			If Not Personal Then
				Try
					CertificatesArray = CryptoManager.GetCertificateStore(
						CryptoCertificateStoreType.RecipientCertificates).GetAll();
					DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable,
						CertificatesArray, NoFilter, UTCOffset(), CurrentSessionDate());
				Except
					ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
					If TypeOf(Error) = Type("Structure") Then
						Error = DigitalSignatureInternalClientServer.NewErrorsDescription(ComputerName());
						Error.ErrorDescription = ErrorDescription;
					Else
						Error = ErrorDescription;
					EndIf;
				EndTry;
			EndIf;
	
		EndIf;
		
	EndIf;
	
	If UseDigitalSignatureSaaS() Then
		
		ModuleCertificateStore = Common.CommonModule("CertificatesStorage");
		CertificatesArray = ModuleCertificateStore.Get("PersonalCertificates");
		
		PropertiesAddingOptions = New Structure("InCloudService", True);
		DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable,
			CertificatesArray, NoFilter, UTCOffset(), CurrentSessionDate(), PropertiesAddingOptions);
		
		If Not Personal Then
			CertificatesArray = ModuleCertificateStore.Get("RecipientCertificates");
			
			DigitalSignatureInternalClientServer.AddCertificatesProperties(CertificatesPropertiesTable,
				CertificatesArray, NoFilter, UTCOffset(), CurrentSessionDate(), PropertiesAddingOptions);
		EndIf;
		
	EndIf;
	
	If UseCloudSignatureService() Then
		
		DigitalSignatureLocalization.OnAddCloudServiceCertificatesProperties(CertificatesPropertiesTable, NoFilter);
		
	EndIf;
	
	FilterExceptAlreadyAddedItems = Not NoFilter And ButAlreadyAddedOnes;
	ProcessAddedCertificates(CertificatesPropertiesTable, FilterExceptAlreadyAddedItems, FilterByCompany, AreAvailableOnlyWithKey);
	
	CertificatesPropertiesTable.Indexes.Add("Presentation");
	CertificatesPropertiesTable.Sort("Presentation Asc");
	
	ProcessedRows  = New Map;
	IndexOf = 0;
	Filter = New Structure("Thumbprint", "");
	
	For Each CertificateProperties In CertificatesPropertiesTable Do
		Filter.Thumbprint = CertificateProperties.Thumbprint;
		Rows = Certificates.FindRows(Filter);
		If Rows.Count() = 0 Then
			If Certificates.Count()-1 < IndexOf Then
				String = Certificates.Add();
			Else
				String = Certificates.Insert(IndexOf);
			EndIf;
		Else
			String = Rows[0];
			RowIndex = Certificates.IndexOf(String);
			If RowIndex <> IndexOf Then
				Certificates.Move(RowIndex, IndexOf - RowIndex);
			EndIf;
		EndIf;
		// Updating only changed values not to update the form table once again.
		UpdateValue(String.Thumbprint,            CertificateProperties.Thumbprint);
		UpdateValue(String.Presentation,        CertificateProperties.Presentation);
		UpdateValue(String.IssuedBy,             CertificateProperties.IssuedBy);
		UpdateValue(String.AtClient,            CertificateProperties.AtClient);
		UpdateValue(String.AtServer,            CertificateProperties.AtServer);
		UpdateValue(String.IsRequest,         CertificateProperties.IsRequest);
		UpdateValue(String.InCloudService,     CertificateProperties.InCloudService);
		UpdateValue(String.LocationType,        CertificateProperties.LocationType);
		UpdateValue(String.CertificateStatus, CertificateProperties.CertificateStatus);
		UpdateValue(String.Isinthedirectory,     CertificateProperties.Isinthedirectory);
		ProcessedRows.Insert(String, True);
		IndexOf = IndexOf + 1;
	EndDo;
	
	IndexOf = Certificates.Count()-1;
	While IndexOf >=0 Do
		String = Certificates.Get(IndexOf);
		If ProcessedRows.Get(String) = Undefined Then
			Certificates.Delete(IndexOf);
		EndIf;
		IndexOf = IndexOf-1;
	EndDo;
	
EndProcedure

// For the CheckCertificate function.
Function ValidateCertificate(CryptoManagerToCheck, CertificateToCheck, 
	CertificateCheckModes, ErrorDescription, RaiseException1, UniversalVerificationDate)
	
	Try
		ValidateCertificateAsOfDate(CryptoManagerToCheck, CertificateToCheck,
			CertificateCheckModes, UniversalVerificationDate);
		Return True;
	Except
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	
	If Not ValueIsFilled(ErrorDescription) Then
		Return False;
	EndIf;

	ClassifierError = ClassifierError(ErrorDescription, True);
	If ClassifierError = Undefined Then
		Return False;
	EndIf;

	If ClassifierError.CertificateRevoked Then
		Try
			DoWriteCertificateRevocationMark(Base64String(CertificateToCheck.Thumbprint));
		Except
			ErrorDescription = ErrorDescription + Chars.LF + ErrorProcessing.BriefErrorDescription(
				ErrorInfo());
		EndTry;
		Return False;
	EndIf;

	If ValueIsFilled(ClassifierError.RemedyActions) Then
		Return RevalidateCertificate(CryptoManagerToCheck, CertificateToCheck,
			CertificateCheckModes, ErrorDescription, RaiseException1,
			ClassifierError.RemedyActions, UniversalVerificationDate);
	EndIf;
	
	Return False;
	
EndFunction

// For the CheckCertificate function.
Procedure ValidateCertificateAsOfDate(CryptoManagerToCheck, CertificateToCheck,
	CertificateCheckModes, UniversalVerificationDate)
	
	If DigitalSignatureInternalClientServer.AreCertificateAdditionalPropertiesAvailable() Then
		//@skip-check bsl-legacy-check-dynamic-feature-access
		CryptoManagerToCheck.CheckCertificate(
			CertificateToCheck, CertificateCheckModes, UniversalVerificationDate);
	Else
		CryptoManagerToCheck.CheckCertificate(CertificateToCheck, CertificateCheckModes);
	EndIf;

EndProcedure

// For the CheckCertificate function.
Function RevalidateCertificate(CryptoManagerToCheck, CertificateToCheck, 
	CertificateCheckModes, ErrorDescription, RaiseException1, RemedyActions, UniversalVerificationDate)
	
	ShouldInstallRevocationList = False;
	
	If TypeOf(CryptoManagerToCheck) = Type("CryptoManager") Then
		If ValueIsFilled(RemedyActions) And RemedyActions.Find("SetListOfCertificateRevocation") <> Undefined 
			And DigitalSignature.AccessToInternetServicesAllowed() Then
			
			CertificateAuthorityName = Lower(DigitalSignature.CertificateIssuerProperties(CertificateToCheck).CommonName);
			If ValueIsFilled(CertificateAuthorityName) Then
				
				CertificateAuthorityName = StringFunctions.LatinString(CertificateAuthorityName);
				CertificateProperties = DigitalSignature.CertificateProperties(CertificateToCheck);
				
				If DigitalSignatureInternalClientServer.AreCertificateAdditionalPropertiesAvailable() Then
					RevocationListInternalAddress = DigitalSignatureInternalClientServer.RevocationListInternalAddress(
						CertificateAuthorityName,
						CertificateProperties, 
						DigitalSignatureInternalCached.CARevocationListDirectories());
				Else
					RevocationListInternalAddress = DigitalSignatureInternalClientServer.RevocationListInternalAddress(
						CertificateAuthorityName,
						CertificateToCheck.Unload(), 
						DigitalSignatureInternalCached.CARevocationListDirectories());
				EndIf;
				
				If ValueIsFilled(RevocationListInternalAddress.InternalAddress) Then
					ShouldInstallRevocationList = True;
				EndIf;
				
			EndIf;
		EndIf;
	EndIf;
	
	If ShouldInstallRevocationList Then
		
		DetailsCertificateString = DigitalSignatureInternalClientServer.DetailsCertificateString(CertificateProperties);
		
		Try
			SetListOfCertificateRevocation(CertificateToCheck,
				RevocationListInternalAddress.ExternalAddress, RevocationListInternalAddress.InternalAddress);
		Except
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể thiết lập danh sách thu hồi trên server khi kiểm tra chứng thư: %1
				|%2.';
				|ru = 'Не удалось установить список отзыва на сервере при проверке сертификата: %1
				|%2.';
				|en = 'Couldn''t install the revocation list on the server when checking the certificate: %1
				|%2.'; fa = 'Couldn''t install the revocation list on the server when checking the certificate: %1
				|%2.';
				|it = 'Не удалось установить список отзыва на сервере при проверке сертификата: %1
				|%2.';
				|pl = 'Couldn''t install the revocation list on the server when checking the certificate: %1
				|%2.';
				|tr = 'Sertifika kontrolü sırasında geri çekme listesi ayarlanamadı: %1
				|%2.'"),
				
				ErrorProcessing.BriefErrorDescription(ErrorInfo()),
				DetailsCertificateString);
			
			WriteLogEvent(
					NStr("vi = 'Chữ ký điện tử. Cập nhật danh sách thu hồi';
						|ru = 'Электронная подпись.Обновление списков отзыва';
						|en = 'Digital signature.Update revocation lists'; fa = 'Digital signature.Update revocation lists';
						|it = 'Электронная подпись.Обновление списков отзыва';
						|pl = 'Podpis elektroniczny.Aktualizacja list odwołania';
						|tr = 'Dijital imza. İptal listesini güncelle'",
					Common.DefaultLanguageCode()),
					EventLogLevel.Error, , ,
					ErrorText);
			
			Return False;
		EndTry;
		
		WriteLogEvent(
					NStr("vi = 'Chữ ký điện tử. Cập nhật danh sách thu hồi';
						|ru = 'Электронная подпись.Обновление списков отзыва';
						|en = 'Digital signature.Update revocation lists'; fa = 'Digital signature.Update revocation lists';
						|it = 'Электронная подпись.Обновление списков отзыва';
						|pl = 'Podpis elektroniczny.Aktualizacja list odwołania';
						|tr = 'Dijital imza. İptal listesini güncelle'",
					Common.DefaultLanguageCode()),
					EventLogLevel.Information, , ,
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Đã cài đặt danh sách thu hồi trên server khi kiểm tra chứng thư: %1';
							|ru = 'Установлен список отзыва на сервере при проверке сертификата: %1';
							|en = 'Certificate revocation list was installed  on server during the certificate validation: %1'; fa = 'Certificate revocation list was installed  on server during the certificate validation: %1';
							|it = 'Установлен список отзыва на сервере при проверке сертификата: %1';
							|pl = 'Certificate revocation list was installed  on server during the certificate validation: %1';
							|tr = 'Sertifika kontrolü esnasında sunucudaki iptal listesi ayarlandı: %1'"),
						DetailsCertificateString));
		
		// Re-check after a certificate revocation list has been set.
		Try
			
			ValidateCertificateAsOfDate(CryptoManagerToCheck, CertificateToCheck,
				CertificateCheckModes, UniversalVerificationDate);
			
		Except

			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());

			If RaiseException1 Then
				Raise;
			EndIf;
			Return False;
		EndTry;
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

// For internal use only.
//
// Parameters:
//   Context - Structure:
//     * ErrorAtServer - Structure:
//         ** Errors - Array
//
Function WriteCertificateAfterCheck(Context) Export
	
	CreationParameters = CryptoManagerCreationParameters();
	CreationParameters.ErrorDescription = New Structure;
	CreationParameters.SignAlgorithm = Context.SignAlgorithm;
	
	CryptoManager = CryptoManager("", CreationParameters);
	
	Context.Insert("ErrorAtServer",
		DigitalSignatureInternalClientServer.NewErrorsDescription());
	
	ApplicationErrorTitle = DigitalSignatureInternalClientServer.CertificateAddingErrorTitle(
			?(Context.ToEncrypt = True, "Encryption", "Signing"), ComputerName());
	
	If TypeOf(CryptoManager) <> Type("CryptoManager")
		And CreationParameters.ErrorDescription.Shared3 Then
		
		Context.ErrorAtServer = CreationParameters.ErrorDescription;
		Context.ErrorAtServer.ErrorTitle = ApplicationErrorTitle;
		Return Undefined;
	EndIf;
	
	ApplicationsDetailsCollection = DigitalSignature.CommonSettings().ApplicationsDetailsCollection;
	CertificateApplicationResult = AppForCertificate(
		Context.CertificateData, True);
	
	If ValueIsFilled(CertificateApplicationResult.Application) Then
		ApplicationsDetailsCollection = DigitalSignatureInternalClientServer.CryptoManagerApplicationsDetails(
			CertificateApplicationResult.Application, Context.ErrorAtServer.Errors, ApplicationsDetailsCollection);
	Else
		
		DigitalSignatureInternalClientServer.CryptoManagerAddError(
			Context.ErrorAtServer.Errors, Undefined, CertificateApplicationResult.Error, True);
		
	EndIf;
	
	CryptoCertificate = New CryptoCertificate(Context.CertificateData);
	IsFullUser = Users.IsFullUser(,, False);
	
	For Each ApplicationDetails In ApplicationsDetailsCollection Do
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.Application = ApplicationDetails.Ref;
		CreationParameters.ErrorDescription = New Structure;
		CreationParameters.SignAlgorithm = Context.SignAlgorithm;
		
		CryptoManager = CryptoManager("", CreationParameters);
		
		If CryptoManager = Undefined Then
			Errors = CreationParameters.ErrorDescription.Errors;
			
			If Errors.Count() > 0
			   And Not (ValueIsFilled(Context.SignAlgorithm)
			         And Errors[0].NoAlgorithm) Then
				
				Errors[0].ErrorTitle = ApplicationErrorTitle;
				Context.ErrorAtServer.Errors.Add(Errors[0]);
			EndIf;
			
			Continue;
			
		EndIf;
		
		CryptoManager.PrivateKeyAccessPassword = Context.CertificatePassword;
		
		If Context.ToEncrypt = True Then
			Success = CheckEncryptionAndDecryption(CryptoManager, Context.CertificateData,
				CryptoCertificate, ApplicationDetails, Context.ErrorAtServer, IsFullUser);
		Else
			Success = CheckSigning(CryptoManager, Context.CertificateData,
				CryptoCertificate, ApplicationDetails, Context.ErrorAtServer, IsFullUser);
		EndIf;
		
		If Not Success Then
			Continue;
		EndIf;
		
		Context.Insert("ApplicationDetails", ApplicationDetails);
		Return DigitalSignatureInternalClientServer.WriteCertificateToCatalog(Context,
			Context.ErrorAtServer);
		
	EndDo;
	
	Return Undefined;
	
EndFunction

// For internal use only.
// 
// Parameters:
//  Thumbprint - String - Certificate thumbprint in the Base64String format. 
//
Function DoWriteCertificateRevocationMark(Thumbprint) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("Thumbprint", Thumbprint);
	Query.Text =
	"SELECT ALLOWED
	|	Certificates.Ref AS Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Thumbprint = &Thumbprint
	|	AND NOT Certificates.Revoked";
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	CertificateRef = Selection.Ref;
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.DigitalSignatureAndEncryptionKeysCertificates");
	LockItem.SetValue("Ref", CertificateRef);
	
	BeginTransaction();
	Try
		
		Block.Lock();
		CertificateObject = CertificateRef.GetObject();
		
		If CertificateObject.Revoked <> True Then
			CertificateObject.Revoked = True;
			CertificateObject.DataExchange.Load = True;
			CertificateObject.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể ghi lại đánh dấu về thu hồi chứng thư %1: %2';
				|ru = 'Не удалось записать отметку об отзыве сертификата %1: %2';
				|en = 'Cannot save the %1 certificate revocation mark: %2'; fa = 'Cannot save the %1 certificate revocation mark: %2';
				|it = 'Не удалось записать отметку об отзыве сертификата %1: %2';
				|pl = 'Cannot save the %1 certificate revocation mark: %2';
				|tr = '%1 sertifikasının iptal işareti kaydedilemedi: %2'"), CertificateRef, 
			ErrorProcessing.BriefErrorDescription(ErrorInfo));
		
		WriteLogEvent(
			NStr("vi = 'Chữ ký điện tử.Thiết lập đánh dấu về thu hồi chứng thư.';
				|ru = 'Электронная подпись.Установка отметки об отзыве сертификата.';
				|en = 'Digital signature.Set certificate revocation mark.'; fa = 'Digital signature.Set certificate revocation mark.';
				|it = 'Электронная подпись.Установка отметки об отзыве сертификата.';
				|pl = 'Digital signature.Set certificate revocation mark.';
				|tr = 'Elektronik imza. Sertifika iptal işaretinin yapılandırılması.'",
			Common.DefaultLanguageCode()),
			EventLogLevel.Error, , CertificateRef,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		Raise ErrorText;
	EndTry;
	
	Return CertificateRef;
	
EndFunction

// For internal use only.
Function BuiltinCryptoprovider() Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Programs.Ref AS Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS Programs
	|WHERE
	|	Programs.IsBuiltInCryptoProvider
	|	AND NOT Programs.DeletionMark
	|
	|ORDER BY
	|	Programs.Description";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		BuiltinCryptoprovider = Selection.Ref;
	Else
		BuiltinCryptoprovider = Undefined;
	EndIf;
	
	Return BuiltinCryptoprovider;
	
EndFunction

// For internal use only.
Function CloudPasswordConfirmed(Certificate)
	
	If Not UseDigitalSignatureSaaS() Then
		Return False;
	EndIf;
	
	If TypeOf(Certificate) = Type("BinaryData") Then
		CertificateData = Certificate;
		
	ElsIf TypeOf(Certificate) = Type("CryptoCertificate") Then
		CertificateData = Certificate.Unload();
	Else
		CertificateData = GetFromTempStorage(Certificate);
	EndIf;
	
	ModuleCryptographyService = Common.CommonModule("CryptographyService");
	CertificateProperties = ModuleCryptographyService.GetCertificateProperties(CertificateData);
	
	SecurityTokens = SecurityTokens(CertificateProperties.Id);
	
	Return ValueIsFilled(SecurityTokens.SecurityToken);
	
EndFunction

// For the CloudPasswordConfirmed function.
Function SecurityTokens(CertificateID)

	Result = New Structure();
	Result.Insert("SecurityToken");
	
	SetPrivilegedMode(True);
	Result.SecurityToken = SessionParameters["SecurityTokens"].Get(CertificateID);
	
	SetPrivilegedMode(False);
	
	// Replacing blank values with blank strings to pass to the crypto service.
	If Not ValueIsFilled(Result.SecurityToken) Then
		Result.SecurityToken = "";
	EndIf;
	
	Return Result;

EndFunction

// In Linux and MacOS, when creating a crypto manager,
// it is required to specify the path to the app.
//
// Returns:
//  Boolean
//
Function RequiresThePathToTheProgram(AtClient = False) Export
	
	If AtClient Then
		Return Common.IsLinuxClient()
		    Or Common.IsMacOSClient();
	EndIf;
	
	SystemInfo = New SystemInfo;
	
	Return Common.IsLinuxServer()
		Or SystemInfo.PlatformType = PlatformType.MacOS_x86
		Or SystemInfo.PlatformType = PlatformType.MacOS_x86_64;
	
EndFunction

#Region CommonProceduresAndFunctionsForManagedForms

// For internal use only.
// 
// Parameters:
//  CertificatesList - ValueList - Certificate list to add Personal store certificates to.
//  Error - String - Error.
//
Procedure AddListofCertificatesInPersonalStorageOnServer(CertificatesList, Error = "") Export
	
	If DigitalSignature.GenerateDigitalSignaturesAtServer() Then

		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ErrorDescription = Error;
		
		CryptoManager = CryptoManager("GetCertificates", CreationParameters);
		
		Error = CreationParameters.ErrorDescription;
		If CryptoManager <> Undefined Then
			
			Try
				CertificatesArray = CryptoManager.GetCertificateStore(
					CryptoCertificateStoreType.PersonalCertificates).GetAll();
				For Each Item In CertificatesArray Do
					CertificatesList.Add(Base64String(Item.Thumbprint));
				EndDo;
			Except
				ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				If TypeOf(Error) = Type("Structure") Then
					Error = DigitalSignatureInternalClientServer.NewErrorsDescription(ComputerName());
					Error.ErrorDescription = ErrorDescription;
				Else
					Error = ErrorDescription;
				EndIf;
			EndTry;
			
		EndIf;
		
	EndIf;
	
	If UseDigitalSignatureSaaS() Then
		
		ModuleCertificateStore = Common.CommonModule("CertificatesStorage");
		CertificatesArray = ModuleCertificateStore.Get("PersonalCertificates");
		For Each Item In CertificatesArray Do
			CertificatesList.Add(Base64String(Item.Thumbprint));
		EndDo;
		
	EndIf;
	
	If UseCloudSignatureService() Then
		TheDSSCryptographyServiceModuleInternal = Common.CommonModule("DSSCryptographyServiceInternal");
		CertificatesArray = TheDSSCryptographyServiceModuleInternal.GetCertificateData_(False);
		For Each Item In CertificatesArray Do
			CertificatesList.Add(Base64String(Item.Thumbprint));
		EndDo;
	EndIf;
	
EndProcedure

// For internal use only.
Procedure SetSigningEncryptionDecryptionForm(Form, Encryption = False, Details = False) Export
	
	Items  = Form.Items;
	Parameters = Form.Parameters;
	
	Items.Certificate.DropListButton = True;
	Items.Certificate.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInDropList;
	
	Form.Title = Parameters.Operation;
	Form.ExecuteAtServer = Parameters.ExecuteAtServer;
	
	If Encryption Then
		If Form.SpecifiedImmutableCertificateSet Then
			Form.NoConfirmation = Parameters.NoConfirmation;
		EndIf;
	Else
		Form.CertificatesFilter = New ValueList;
		If TypeOf(Parameters.CertificatesFilter) = Type("Array") Then
			Form.CertificatesFilter.LoadValues(Parameters.CertificatesFilter);
		ElsIf TypeOf(Parameters.CertificatesFilter) = Type("Structure") Then
			Form.CertificatesFilter = Parameters.CertificatesFilter.Organization;
		EndIf;
		Form.NoConfirmation = Parameters.NoConfirmation;
	EndIf;
	
	ItemDataPresentation = Items.DataPresentation; // FormField, FormFieldExtensionForALabelField
	If ValueIsFilled(Parameters.DataTitle) Then
		ItemDataPresentation.Title = Parameters.DataTitle;
	Else
		ItemDataPresentation.TitleLocation = FormItemTitleLocation.None;
	EndIf;
	
	Form.DataPresentation = Parameters.DataPresentation;
	ItemDataPresentation.Hyperlink = Parameters.DataPresentationCanOpen;
	
	If Not ValueIsFilled(Form.DataPresentation) Then
		ItemDataPresentation.Visible = False;
	EndIf;
	
	If Details Then
		FillThumbprintsFilter(Form);
	ElsIf Not Encryption Then // Signing.
		Items.Comment.Visible = Parameters.ShowComment And Not Form.NoConfirmation;
	EndIf;
	
	If Not Encryption Then
		FillExistingUserCertificates(Form.CertificatePicklist,
			Parameters.CertificatesThumbprintsAtClient, Form.CertificatesFilter,
			Form.ThumbprintsFilter, Details, Form.ExecuteAtServer);
	EndIf;
	
	Certificate = Undefined;
	
	If Details Then
		For Each ListItem In Form.CertificatePicklist Do
			If TypeOf(ListItem.Value) = Type("String") Then
				Continue;
			EndIf;
			Certificate = ListItem.Value;
			Break;
		EndDo;
		
	ElsIf AccessRight("SaveUserData", Metadata) Then
		If Encryption Then
			Certificate = CommonSettingsStorage.Load("Cryptography", "CertificateToEncrypt");
		Else
			Certificate = CommonSettingsStorage.Load("Cryptography", "CertificateToSign");
		EndIf;
	EndIf;
	
	If Not Encryption And TypeOf(Form.CertificatesFilter) = Type("ValueList") Then
		If Form.CertificatePicklist.Count() = 0 Then
			Certificate = Undefined;
		Else
			Certificate = Form.CertificatePicklist[0].Value;
		EndIf;
	EndIf;
	
	If Not (Encryption And Form.SpecifiedImmutableCertificateSet) Then
		Form.Certificate = Certificate;
	EndIf;
	
	If ValueIsFilled(Form.Certificate)
	   And Common.ObjectAttributeValue(Form.Certificate, "Ref") <> Form.Certificate Then
		
		Form.Certificate = Undefined;
	EndIf;
	
	If ValueIsFilled(Form.Certificate) Then
		If Encryption Then
			Form.DefaultFieldNameToActivate = "EncryptionCertificates";
		Else
			Form.DefaultFieldNameToActivate = "Password";
		EndIf;
	Else
		If Not (Encryption And Form.SpecifiedImmutableCertificateSet) Then
			Form.DefaultFieldNameToActivate = "Certificate";
		EndIf;
	EndIf;
	
	FillCertificateAdditionalProperties(Form);
	
	Form.CryptographyManagerOnServerErrorDescription = New Structure;
	If DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ErrorDescription = New Structure;
		
		CryptoManager("GetCertificates", CreationParameters);
		Form.CryptographyManagerOnServerErrorDescription = CreationParameters.ErrorDescription;
		
	EndIf;
	
	If Not Encryption Then
		DigitalSignatureOverridable.BeforeOperationStart(?(Details, "Details", "Signing"),
			Parameters.AdditionalActionParameters, Form.AdditionalActionsOutputParameters);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure CertificateOnChangeAtServer(Form, CertificatesThumbprintsAtClient, Encryption = False, Details = False) Export
	
	If (TypeOf(Form.CertificatesFilter) <> Type("ValueList")
		Or TypeOf(Form.CertificatesFilter) = Type("ValueList") And Form.CertificatesFilter.Count() = 0)
		And AccessRight("SaveUserData", Metadata) Then
		
		If Encryption Then
			CommonSettingsStorage.Save("Cryptography", "CertificateToEncrypt", Form.Certificate);
		ElsIf Not Details Then
			CommonSettingsStorage.Save("Cryptography", "CertificateToSign", Form.Certificate);
		EndIf;
		
	EndIf;
	
	FillExistingUserCertificates(Form.CertificatePicklist,
		CertificatesThumbprintsAtClient, Form.CertificatesFilter,
		Form.ThumbprintsFilter, Details, Form.ExecuteAtServer);
	
	FillCertificateAdditionalProperties(Form);
	
EndProcedure

// For internal use only.
Function SavedCertificateProperties(Thumbprint, Address, AttributesParameters, ToEncrypt = False) Export
	
	SavedProperties = New Structure;
	SavedProperties.Insert("Ref");
	SavedProperties.Insert("Description");
	SavedProperties.Insert("User");
	SavedProperties.Insert("Organization");
	SavedProperties.Insert("Individual");
	SavedProperties.Insert("EnterPasswordInDigitalSignatureApplication");
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("Thumbprint", Thumbprint);
	Query.Text =
	"SELECT
	|	Certificates.Ref AS Ref,
	|	Certificates.Description AS Description,
	|	Certificates.User,
	|	Certificates.Organization,
	|	Certificates.Individual,
	|	Certificates.EnterPasswordInDigitalSignatureApplication,
	|	Certificates.CertificateData
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Thumbprint = &Thumbprint";
	
	CryptoCertificate = New CryptoCertificate(GetFromTempStorage(Address));
	
	FillingValues = AttributesParameters;
	AttributesParameters = Undefined; // It is filled in the BeforeStartEditKeyCertificate procedure.
	
	Selection = Query.Execute().Select();
	
	SetPrivilegedMode(False);
	
	If Selection.Next() Then
		FillPropertyValues(SavedProperties, Selection);
	Else
		SavedProperties.Ref = Catalogs.DigitalSignatureAndEncryptionKeysCertificates.EmptyRef();
		
		If TypeOf(FillingValues) = Type("Structure")
		   And FillingValues.Property("Organization")
		   And ValueIsFilled(FillingValues.Organization) Then
			
			SavedProperties.Organization = FillingValues.Organization;
			
		ElsIf Not Metadata.DefinedTypes.Organization.Type.ContainsType(Type("String")) Then
			FullName = Metadata.FindByType(Metadata.DefinedTypes.Organization.Type.Types()[0]).FullName();
			CompanyCatalogName = "Catalogs." + StrSplit(FullName, ".")[1];
			ModuleOrganization = Common.CommonModule(CompanyCatalogName);
			If Not ToEncrypt Then
				SavedProperties.Organization = ModuleOrganization.DefaultCompany();
			EndIf;
		EndIf;
		
		CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
		SavedProperties.Description = CertificateProperties.Presentation;
		
		If Not ToEncrypt Then
			SavedProperties.User = Users.CurrentUser();
		EndIf;
	EndIf;
	
	BeforeStartEditKeyCertificate(
		SavedProperties.Ref, CryptoCertificate, AttributesParameters);
	
	If Not ValueIsFilled(SavedProperties.Ref) Then
		FillAttribute(SavedProperties, AttributesParameters, "Description");
		FillAttribute(SavedProperties, AttributesParameters, "User");
		FillAttribute(SavedProperties, AttributesParameters, "Organization");
		FillAttribute(SavedProperties, AttributesParameters, "EnterPasswordInDigitalSignatureApplication");
	EndIf;
	
	If Not ValueIsFilled(SavedProperties.Ref)
	   And TypeOf(FillingValues) = Type("Structure")
	   And FillingValues.Property("Organization")
	   And ValueIsFilled(FillingValues.Organization)
	   And Not AttributesParameters.Property("Organization") Then
	
		Parameters = New Structure;
		Parameters.Insert("ReadOnly",     True);
		Parameters.Insert("FillChecking", False);
		Parameters.Insert("Visible",          True);
		AttributesParameters.Insert("Organization", Parameters);
	EndIf;
	
	Return SavedProperties;
	
EndFunction

// For internal use only.
// 
// Parameters:
//  Form - ClientApplicationForm:
//    * CertificateAttributeParameters - See NewParametersForCertificateDetails
//  Application - Undefined
//  ToEncrypt - Boolean
//
Procedure WriteCertificateToCatalog(Form, Application = Undefined, ToEncrypt = False) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Description",   Form.DescriptionCertificate);
	AdditionalParameters.Insert("User",   Form.CertificateUser1);
	AdditionalParameters.Insert("Organization",    Form.CertificateCompany);
	AdditionalParameters.Insert("Individual", Form.CertificateIndividual);
	
	If Not ToEncrypt Then
		AdditionalParameters.Insert("Application", Application);
		AdditionalParameters.Insert("EnterPasswordInDigitalSignatureApplication",
			Form.CertificateEnterPasswordInElectronicSignatureProgram);
	EndIf;
	
	If Not ValueIsFilled(Form.Certificate) Then
		AttributesToSkip1 = New Map;
		AttributesToSkip1.Insert("Ref",         True);
		AttributesToSkip1.Insert("Description",   True);
		AttributesToSkip1.Insert("Organization",    True);
		AttributesToSkip1.Insert("Individual", True);
		AttributesToSkip1.Insert("EnterPasswordInDigitalSignatureApplication", True);
		If Not ToEncrypt And Form.PersonalListOnAdd Then
			AttributesToSkip1.Insert("User",  True);
		EndIf;
		For Each KeyAndValue In Form.CertificateAttributeParameters Do
			AttributeName = KeyAndValue.Key;
			Properties     = KeyAndValue.Value; // See TheNewSettingsOfTheRequisiteCertificate
			If AttributesToSkip1.Get(AttributeName) <> Undefined Then
				Continue;
			EndIf;
			If Properties.FillValue = Undefined Then
				Continue;
			EndIf;
			AdditionalParameters.Insert(AttributeName, Properties.FillValue);
		EndDo;
	EndIf;
	
	Form.Certificate = DigitalSignature.WriteCertificateToCatalog(Form.AddressOfCertificate,
		AdditionalParameters);
	
EndProcedure

// For internal use only.
//
// Parameters:
//   List - DynamicList
//
Procedure SetCertificateListConditionalAppearance(List, ExcludeApplications = False) Export
	
	ConditionalAppearanceItem = List.ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	AppearanceColorItem.Use = True;
	
	If ExcludeApplications And Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.SetCertificateListConditionalAppearance(
			ConditionalAppearanceItem);
	EndIf;
	
	FilterItemsGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterItemsGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	
	DataFilterItem = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("Revoked");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use  = True;
	
	DataFilterItem = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("ValidBefore");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Greater;
	DataFilterItem.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	DataFilterItem.Use  = True;
	
	AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceFieldItem.Field = New DataCompositionField("");
	AppearanceFieldItem.Use = True;
	
EndProcedure

// For internal use only.
//
// Parameters:
//   CertificateData - BinaryData
//
Function CertificateFromBinaryData(CertificateData) Export
	
	If TypeOf(CertificateData) <> Type("BinaryData") Then
		Return Undefined;
	EndIf;
	
	Try
		CryptoCertificate = New CryptoCertificate(CertificateData);
	Except
		CryptoCertificate = Undefined;
	EndTry;
	
	If CryptoCertificate <> Undefined Then
		Return CryptoCertificate;
	EndIf;
	
	TempFileFullName = GetTempFileName("cer");
	CertificateData.Write(TempFileFullName);
	Text = New TextDocument;
	Text.Read(TempFileFullName);
	
	Try
		DeleteFiles(TempFileFullName);
	Except
		WriteLogEvent(
			NStr("vi = 'Chữ ký điện tử.Xóa tệp tạm thời';
				|ru = 'Электронная подпись.Удаление временного файла';
				|en = 'Digital signature.Delete temporary file'; fa = 'Digital signature.Delete temporary file';
				|it = 'Firma elettronica. Eliminazione del file temporaneo';
				|pl = 'Podpis elektroniczny.Usuń plik tymczasowy';
				|tr = 'Dijital imza.Geçici dosyanın silinmesi'",
				Common.DefaultLanguageCode()),
			EventLogLevel.Error, , ,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	If StrStartsWith(Text.GetLine(1), "MII") Then
		Base64Row = Text.GetText();
	Else
		If Text.LineCount() < 3
			Or Text.GetLine(1) <> "-----BEGIN CERTIFICATE-----"
			Or Text.GetLine(Text.LineCount()) <> "-----END CERTIFICATE-----" Then
			
			Return Undefined;
		EndIf;
		
		Text.DeleteLine(1);
		Text.DeleteLine(Text.LineCount());
		Base64Row = Text.GetText();
	EndIf;
	
	Try
		CertificateData = Base64Value(Base64Row);
	Except
		Return Undefined;
	EndTry;
	
	If TypeOf(CertificateData) <> Type("BinaryData") Then
		Return Undefined;
	EndIf;
	
	Try
		CryptoCertificate = New CryptoCertificate(CertificateData);
	Except
		CryptoCertificate = Undefined;
	EndTry;
	
	Return CryptoCertificate;
	
EndFunction

// For internal use only.
//
// Parameters:
//   Form - ClientApplicationForm
//
Procedure SetPasswordEntryNote(Form, ItemNameEnterPasswordInElectronicSignatureProgram = "", ItemNameEnhancedPasswordNote = "") Export
	
	If ValueIsFilled(ItemNameEnterPasswordInElectronicSignatureProgram) Then
		Item = Form.Items[ItemNameEnterPasswordInElectronicSignatureProgram]; // FormField
		Item.Title = NStr("vi = 'Nhập mật khẩu trong ứng dụng chữ ký điện tử';
							|ru = 'Вводить пароль в приложении электронной подписи';
							|en = 'Protect digital signing app with password'; fa = 'حفاظت از برنامه امضای دیجیتال با رمز عبور';
							|it = 'Вводить пароль в приложении электронной подписи';
							|pl = 'Protect digital signing app with password';
							|tr = 'Elektronik imza uygulamasında şifreyi gir'");
		Item.ToolTip =
			NStr("vi = '- Ứng dụng chữ ký điện tử yêu cầu mật khẩu và cho phép bạn lưu mật khẩu.
			           |- Yêu cầu mật khẩu trong ứng dụng 1C:Enterprise bị tắt sử dụng.
			           |
			           |Bắt buộc đối với các khóa riêng của chứng thư mà đã bật tính năng bảo vệ nâng cao trong hệ điều hành.';
			           |ru = '- Приложение электронной подписи запрашивает пароль и позволяет его сохранить.
			           |- Отключается запрос пароля в приложении 1С:Предприятие.
			           |
			           |Обязательно для закрытых ключей сертификатов, для которых в операционной системе включена усиленная защита.';
			           |en = '- The digital signing app prompts for a password and allows you to save it.
			           |- 1C:Enterprise never prompts for a password.
			           |
			           |It is required for private keys of the certificates with strong protection enabled in the OS.'; fa = '- برنامه امضای دیجیتال رمز عبور را درخواست می‌کند و امکان ذخیره آن را می‌دهد.
			           |- 1C:Enterprise هرگز رمز عبور را درخواست نمی‌کند.
			           |
			           |برای کلیدهای خصوصی گواهی‌هایی که حفاظت قوی در سیستم‌عامل برای آن‌ها فعال است لازم است.';
			           |it = '- Приложение электронной подписи запрашивает пароль и позволяет его сохранить.
			           |- Отключается запрос пароля в приложении 1С:Предприятие.
			           |
			           |Обязательно для закрытых ключей сертификатов, для которых в операционной системе включена усиленная защита.';
			           |pl = '- The digital signing app prompts for a password and allows you to save it.
			           |- 1C:Enterprise never prompts for a password.
			           |
			           |It is required for private keys of the certificates with strong protection enabled in the OS.';
			           |tr = '- Elektronik imza uygulaması bir şifre ister ve onu kaydetmenize izin verir.
			           |- 1C:Enterprise uygulamasında şifre isteği devre dışı bırakılır.
			           |
			           |İşletim sisteminde gelişmiş korumanın etkinleştirildiği sertifikaların özel anahtarları için gereklidir.'");
	EndIf;
	
	If ValueIsFilled(ItemNameEnhancedPasswordNote) Then
		Item = Form.Items[ItemNameEnhancedPasswordNote];
		Item.ToolTip =
			NStr("vi = 'Đối với chứng chỉ đã chọn, có chỉ ra ""Nhập mật khẩu trong ứng dụng chữ ký điện tử"".';
				|ru = 'Для выбранного сертификата указано ""Вводить пароль в приложении электронной подписи"".';
				|en = 'The option ""Protect digital signing app with password"" is set for this certificate.'; fa = 'The option ""Protect digital signing app with password"" is set for this certificate.';
				|it = 'Для выбранного сертификата указано ""Вводить пароль в приложении электронной подписи"".';
				|pl = 'The option ""Protect digital signing app with password"" is set for this certificate.';
				|tr = 'Seçilen sertifika için ""Dijital imza programında şifre giriniz"" belirtilir.'");
	EndIf;
	
EndProcedure

// Parameters:
//  Form - ClientApplicationForm
//  Title - String
//
Procedure ToSetTheTitleOfTheBug(Form, Title) Export
	
	Form.Title = Title;
	
	TitleWidth = StrLen(Form.Title);
	If TitleWidth > 80 Then
		TitleWidth = 80;
	EndIf;
	If TitleWidth > Form.Width Then
		Form.Width = TitleWidth;
	EndIf;
	
EndProcedure

// For internal use only.
Procedure ExecuteDataProcessingRegularTask(QueryOptions, ExecutionParameters) Export

	Query = RequestForExtensionSignatureCredibility(QueryOptions);

	If Query = Undefined Then
		Return;
	EndIf;
	
	While True Do
		SetPrivilegedMode(True);
		QueryResult = Query.Execute();
		SetPrivilegedMode(False);
		If QueryResult.IsEmpty() Then
			Break;
		EndIf;
		Selection = QueryResult.Select();
		ImproveRegularTask(Selection, ExecutionParameters);
	EndDo;
		
EndProcedure

// For internal use only.
Procedure ImproveRegularTask(Selection, ExecutionParameters)
	
	SignatureType = ExecutionParameters.SignatureType;
	AddArchiveTimestamp = ExecutionParameters.RequiredAddArchiveTags;
	
	While Selection.Next() Do
		
		Signature = Selection.Signature.Get();
		
		If ExecutionParameters.ServiceAccountDSS = Undefined Then
			
			CreationParameters = CryptoManagerCreationParameters();
			CreationParameters.SignAlgorithm =
				DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(Signature);
			CryptoManager = CryptoManager(
				"ExtensionValiditySignature", CreationParameters);
			
			If CryptoManager = Undefined Then
				SignatureProperties = New Structure("SignedObject, SequenceNumber",
					Selection.SignedObject, Selection.SequenceNumber);
				LogErrorImprovementsSignaturesInLog(CreationParameters.ErrorDescription, SignatureProperties);
				Raise CreationParameters.ErrorDescription;
			EndIf;
			
			CryptoManager.TimestampServersAddresses = ExecutionParameters.TimestampServersAddresses;
			
			Result = DigitalSignature.EnhanceSignature(
				Signature, SignatureType, AddArchiveTimestamp, CryptoManager);
				
		Else
			Result = RefineSignatureInService(Signature, ExecutionParameters);
		EndIf;
		
		SignatureProperties = Result.SignatureProperties;
			
		If Not Result.Success Then
			If SignatureProperties = Undefined Then
				SignatureProperties = DigitalSignatureClientServer.NewSignatureProperties();
			EndIf;
			SignatureProperties.SignedObject = Selection.SignedObject;
			SignatureProperties.SequenceNumber = Selection.SequenceNumber;
			SignatureProperties.IsErrorOccurredDuringAutomaticRenewal = True;
			
			LogErrorImprovementsSignaturesInLog(Result.ErrorText, SignatureProperties);
			
			ErrorPresentation = UpdateAdvancedSignature(SignatureProperties);
			If Not IsBlankString(ErrorPresentation) Then
				Raise ErrorPresentation;
			EndIf;
			Continue;
		EndIf;
		
		SignatureProperties.SignedObject = Selection.SignedObject;
		SignatureProperties.SequenceNumber = Selection.SequenceNumber;
		ErrorPresentation = UpdateAdvancedSignature(SignatureProperties);
		If Not IsBlankString(ErrorPresentation) Then
			Raise ErrorPresentation;
		EndIf;
		
		If ValueIsFilled(SignatureProperties.Signature) Then
			RegisterImprovementSignaturesInJournal(SignatureProperties);
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use only.
Procedure RegisterImprovementSignaturesInJournal(SignatureProperties) Export
	
	SignedObject = SignatureProperties.SignedObject;
	SignedObjectMetadata = SignedObject.Metadata();
	
	EventName = NStr("vi = 'Электронная подпись.УсовершенствованиеПодписи';
					|ru = 'Электронная подпись.УсовершенствованиеПодписи';
					|en = 'Digital signature. EnhanceSignatures'; fa = 'Digital signature. EnhanceSignatures';
					|it = 'Электронная подпись.УсовершенствованиеПодписи';
					|pl = 'Podpis elektroniczny.Udoskonalenie podpisu';
					|tr = 'Dijital imza.İmzaGeliştirme'",
		Common.DefaultLanguageCode());
		
	EventLogMessage = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Số thứ tự chữ ký %1, kiểu chữ ký %2, thời hạn hiệu lực %3';
			|ru = 'Порядковый номер подписи %1, тип подписи %2, срок действия %3';
			|en = 'Signature sequence number %1, signature type %2, validity period %3'; fa = 'Signature sequence number %1, signature type %2, validity period %3';
			|it = 'Numero di ordine della firma %1, tipo firma %2, periodo di validità %3';
			|pl = 'Kolejny numer podpisu %1, typ podpisu %2, termin ważności %3';
			|tr = 'imza sıra numarası %1, imza türü %2, geçerlilik dönemi %3'"), 
		SignatureProperties.SequenceNumber, SignatureProperties.SignatureType, SignatureProperties.DateActionLastTimestamp);
	
	WriteLogEvent(EventName,
		EventLogLevel.Information,
		SignedObjectMetadata,
		SignedObject,
		EventLogMessage);
	
EndProcedure 
	
// For internal use only.
Procedure LogErrorImprovementsSignaturesInLog(ErrorDescription, SignatureProperties = Undefined) 
	
	If SignatureProperties <> Undefined Then
		ErrorDescription = ErrorDescription + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Số thứ tự chữ ký %1';
				|ru = 'Порядковый номер подписи %1';
				|en = 'Signature sequence number %1'; fa = 'Signature sequence number %1';
				|it = 'Numero di ordine della firma %1';
				|pl = 'Kolejny numer podpisu %1';
				|tr = 'İmza sıra numarası %1'"), SignatureProperties.SequenceNumber);
		SignedObject = SignatureProperties.SignedObject;
		SignedObjectMetadata = SignedObject.Metadata();
	Else
		SignedObject = Undefined;
		SignedObjectMetadata = Undefined;
	EndIf;
	
	EventName = NStr("vi = 'Chữ ký điện tử.Hoàn thiện chữ ký';
					|ru = 'Электронная подпись.Усовершенствование подписи';
					|en = 'Digital signature.Enhance signature'; fa = 'Digital signature.Enhance signature';
					|it = 'Электронная подпись.Усовершенствование подписи';
					|pl = 'Digital signature.Enhance signature';
					|tr = 'Elektronik imza. Elektronik imza iyileştirmesi'",
			Common.DefaultLanguageCode());
	WriteLogEvent(EventName,
		EventLogLevel.Warning,
		SignedObjectMetadata,
		SignedObject,
		ErrorDescription);

EndProcedure

// For internal use only.
Function UpdateAdvancedSignature(SignatureProperties) Export
	
	ErrorPresentation = ""; 
	Try
		DigitalSignature.UpdateSignature(SignatureProperties.SignedObject, SignatureProperties, True);
	Except
		ErrorInfo = ErrorInfo();
		ErrorPresentation = NStr("vi = 'Không thể ghi lại chữ ký do nguyên nhân:';
								|ru = 'Не удалось записать подписи по причине:';
								|en = 'Cannot save the signatures due to:'; fa = 'Cannot save the signatures due to:';
								|it = 'Не удалось записать подписи по причине:';
								|pl = 'Cannot save the signatures due to:';
								|tr = 'İmza şu sebeple kaydedilmedi:'")
			+ Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;

	Return ErrorPresentation;
	
EndFunction

// For internal use only.
Function RefineSignatureInService(Signature, ExecutionParameters)
	
	Result = New Structure("Success, ErrorText, SignatureProperties", 
		False,, DigitalSignatureClientServer.NewSignatureProperties());
	
	If ExecutionParameters.SignatureType <> Enums.CryptographySignatureTypes.WithTimeCAdEST Then
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nâng cấp chữ ký trong ứng dụng trên Internet đến kiểu: %1.';
				|ru = 'Невозможно усовершенствовать подпись в приложении в Интернете до типа: %1.';
				|en = 'Couldn''t enhance the signature in the web application to type: %1.'; fa = 'Couldn''t enhance the signature in the web application to type: %1.';
				|it = 'Impossibile perfezionare la firma, nell''applicazione su internet fino al tipo: %1.';
				|pl = 'Nie można udoskonalić podpisu w aplikacji w Internecie do typu: %1.';
				|tr = 'İmza Web uygulamada bu türe geliştirilemez: %1.'"), 
				ExecutionParameters.SignatureType);
		Return Result;
	EndIf;
		
	Try
		ModuleServiceCryptographyDSSASNClientServer = Common.CommonModule("DssasnClientServerCryptographyService");
		SignatureProperties = ModuleServiceCryptographyDSSASNClientServer.GetSignatureProperties(
			Signature, New Structure("CertificateData", True));
		Certificate = SignatureProperties[0].Certificate;
		CryptoCertificate = New CryptoCertificate(Certificate);
		SignatureType = ServiceSignatureType(SignatureProperties[0].SignatureType);
	Except
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nâng cấp chữ ký trong ứng dụng trên Internet do nguyên nhân:
			|%1';
			|ru = 'Не удалось усовершенствовать подпись в приложении в Интернете по причине:
			|%1';
			|en = 'Cannot enhance the signature in the web application due to:
			|%1'; fa = 'Cannot enhance the signature in the web application due to:
			|%1';
			|it = 'Не удалось усовершенствовать подпись в приложении в Интернете по причине:
			|%1';
			|pl = 'Cannot enhance the signature in the web application due to:
			|%1';
			|tr = 'Web uygulamasında imza şu sebeple geliştirilemedi:
			|%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return Result;
	EndTry;
	
	Result.SignatureProperties.SignatureType = SignatureType;
	
	CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
	
	If SignatureType <> Enums.CryptographySignatureTypes.BasicCAdESBES Then
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nâng cấp chữ ký có kiểu %1 trong ứng dụng trên Internet';
				|ru = 'Нельзя усовершенствовать подпись с типом %1 в приложении в Интернете';
				|en = 'Cannot enhance the signature with type %1 in the web application'; fa = 'Cannot enhance the signature with type %1 in the web application';
				|it = 'Impossibile perfezionare la firma con tipo %1 nell''applicazione su internet';
				|pl = 'Nie można udoskonalić podpisu z typem %1 w aplikacji w Internecie';
				|tr = 'Web uygulamasında imza %1 türüyle geliştirilemez'"), SignatureType);
			
		If SignatureType = Enums.CryptographySignatureTypes.NormalCMS Then
			Result.SignatureProperties.DateActionLastTimestamp = CertificateProperties.ValidBefore;
		EndIf;
		Return Result;
	EndIf;
	
	If Not ExecutionParameters.ShouldIgnoreCertificateValidityPeriod 
		And CertificateProperties.ValidBefore < CurrentSessionDate() Then 
		InformationAboutCertificate =
			DigitalSignatureInternalClientServer.DetailsCertificateString(CertificateProperties);
	
		Result.SignatureProperties.DateActionLastTimestamp = CertificateProperties.ValidBefore;
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã quá hạn hiệu lực chứng chỉ:
			|%1';
			|ru = 'Срок действия сертификата подписи истек:
			|%1';
			|en = 'Certificate expired:
			|%1'; fa = 'Certificate expired:
			|%1';
			|it = 'Periodo di validità del certificato di firma scaduto: 
			|%1';
			|pl = 'Termin ważności certyfikatu podpisu upłynął:
			|%1';
			|tr = 'İmza sertifikasının geçerlilik dönemi sona erdi:
			|%1'"), InformationAboutCertificate);
			
		Return Result;
		
	EndIf;
	
	TheDSSCryptographyServiceModule = Common.CommonModule("DSSCryptographyService");
	CertificateVerificationResult = TheDSSCryptographyServiceModule.CheckCertificate(
		ExecutionParameters.ServiceAccountDSS, Certificate);
			
	If CertificateVerificationResult.Completed2 = False Or CertificateVerificationResult.Result <> True Then
		InformationAboutCertificate =
			DigitalSignatureInternalClientServer.DetailsCertificateString(CertificateProperties);
		Result.SignatureProperties.DateActionLastTimestamp = CertificateProperties.EndDate;
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kiểm tra chứng thư trong ứng dụng trên Internet, chi tiết xem trong nhật ký sự kiện:
				|%1';
				|ru = 'Не удалось проверить сертификат в приложении в Интернете, подробности см. в журнале регистрации:
				|%1';
				|en = 'Cannot verify the certificate in the web application. For more information, see the event log:
				|%1'; fa = 'Cannot verify the certificate in the web application. For more information, see the event log:
				|%1';
				|it = 'Не удалось проверить сертификат в приложении в Интернете, подробности см. в журнале регистрации:
				|%1';
				|pl = 'Cannot verify the certificate in the web application. For more information, see the event log:
				|%1';
				|tr = 'Web uygulamasında sertifika doğrulanamadı, ayrıntılar için kayıt günlüğüne bakın:
				|%1'"), InformationAboutCertificate);
	
		Return Result;
	EndIf;
	
	SignatureParameters = ExecutionParameters.ParametersSignatureCAdEST;
	QueryResult = TheDSSCryptographyServiceModule.EnhanceSignature(
		ExecutionParameters.ServiceAccountDSS, Signature, SignatureParameters);
	If QueryResult.Completed2 Then
		SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(
			QueryResult.Result, False, True);
		If Not ValueIsFilled(SignAlgorithm) Then
			Result.ErrorText = NStr("vi = 'Khi nâng cấp chữ ký trong ứng dụng trên Internet đã nhận về sai phản hồi:';
									|ru = 'При усовершенствовании подписи в приложении в Интернете получен некорректный ответ:';
									|en = 'When enhancing the signature in the web application, an invalid response is received:'; fa = 'When enhancing the signature in the web application, an invalid response is received:';
									|it = 'Al perfezionamento della firma nell''applicazione su internet è stata ricevuta una risposta sbagliata:';
									|pl = 'Podczas udoskonalenia podpisu w aplikacji w Internecie została otrzymana niepoprawna odpowiedź:';
									|tr = 'Çevrimiçi başvuru sırasında imza geliştirilirken yanlış bir yanıt alındı:'") 
				+ Chars.LF + QueryResult.Result;
		Else
			Result.Success = True;
			Result.SignatureProperties.SignatureType = ExecutionParameters.SignatureType;
			Result.SignatureProperties.Signature = QueryResult.Result;
		EndIf;
	Else
		Result.ErrorText = 
			NStr("vi = 'Không thể nâng cấp chữ ký trong ứng dụng trên Internet. Xem mô tả lỗi trong nhật ký sự kiện.';
				|ru = 'Не удалось усовершенствовать подпись в приложении в Интернете. Описание ошибки см. в журнале регистрации.';
				|en = 'Cannot enhance the signature in the web application. For the error details, see the event log.'; fa = 'Cannot enhance the signature in the web application. For the error details, see the event log.';
				|it = 'Non è stato possibile perfezionare la firma nell''applicazione su internet. La descrizione degli errori è consultabile nel registro.';
				|pl = 'Nie udało się udoskonalić podpisu w aplikacji w Internecie. Opis błędu patrz w dzienniku rejestracji.';
				|tr = 'İmza web uygulaması üzerinden geliştirilemedi. Hata açıklaması için kayıt günlüğüne bakın.'");
	EndIf;
	
	If QueryResult.MarkerUpdated Then
		ExecutionParameters.ServiceAccountDSS = QueryResult.UserSettings;
	EndIf;
		
	Return Result;
	
EndFunction 

// For internal use only.
Function ServiceSignatureType(SignatureType)
	
	If SignatureType = "CAdES-BES" Then
		Return Enums.CryptographySignatureTypes.BasicCAdESBES;
	ElsIf SignatureType = "CadES-T" Then
		Return Enums.CryptographySignatureTypes.WithTimeCAdEST;
	ElsIf SignatureType = "CMS" Then
		Return Enums.CryptographySignatureTypes.NormalCMS;
	ElsIf SignatureType = "CAdES-Av3" Then
		Return Enums.CryptographySignatureTypes.ArchivalCAdESAv3;
	ElsIf SignatureType = "CadES-X Long Type 2" Then
		Return Enums.CryptographySignatureTypes.ExtendedLongCAdESXLongType2;
	ElsIf SignatureType = "CadES-From1" Then
		Return Enums.CryptographySignatureTypes.WithCompleteValidationDataReferencesCAdESC;
	EndIf;
	
	Return Undefined;
	
EndFunction

// For internal use only.
Function ServiceAccountSettingsToImproveSignatures(FormIdentifier = Undefined) Export
	
	ServiceAccountSettings = New Structure("ServiceAccountDSS, Error, ParametersSignatureCAdEST");
	
	TheDSSCryptographyServiceModule = Common.CommonModule("DSSCryptographyService");
	ConnectionSettings = TheDSSCryptographyServiceModule.ServiceAccountConnectionSettings();
	
	If ValueIsFilled(ConnectionSettings.Error) Then
		ServiceAccountSettings.Error = ConnectionSettings.Error;
		Return ServiceAccountSettings;
	EndIf;
	
	TheDSSCryptographyServiceModuleClientServer = Common.CommonModule("DSSCryptographyServiceClientServer");
	Result = TheDSSCryptographyServiceModule.LoginAuthentication(ConnectionSettings.Result);

	If Result.Completed2 Then
		TimestampServersAddresses = TheDSSCryptographyServiceModuleClientServer.GetServerStampsTime(
			Result.UserSettings);
			
		If TimestampServersAddresses.Count() = 0 Then
			ServiceAccountSettings.Error =
				NStr("vi = 'Trong tài khoản dịch vụ không có địa chỉ máy chủ dấu thời gian hợp lệ ';
					|ru = 'В служебной учетной записи нет доступных адресов серверов меток времени';
					|en = 'Service account does not contain available timestamp server addresses'; fa = 'Service account does not contain available timestamp server addresses';
					|it = 'Nell''account di servizio non vi sono indirizzi disponibili di server di contrassegni di tempo';
					|pl = 'Na koncie serwisowym nie ma dostępnych adresów serwerów znaczników czasu';
					|tr = 'Hizmet hesabının kullanılabilir tarih etiketi sunucu adresleri yok'");
			Return ServiceAccountSettings;
		EndIf;
		
		If FormIdentifier = Undefined Then
			ServiceAccountSettings.ServiceAccountDSS = Result.UserSettings;
		Else
			ServiceAccountSettings.ServiceAccountDSS = 
				PutToTempStorage(Result.UserSettings, FormIdentifier);
		EndIf;
		
	Else
		ServiceAccountSettings.Error = Result.Error;
		Return ServiceAccountSettings;
	EndIf;
		
	ServiceAccountSettings.ParametersSignatureCAdEST = 
		TheDSSCryptographyServiceModuleClientServer.GetCAdESSignatureProperty(
			"T", True, False, "Signature", TimestampServersAddresses[0].Address);

	Return ServiceAccountSettings;
	
EndFunction

// For internal use only.
Function EnhanceServerSide(Parameters) Export
	
	Result = New Structure;
	Result.Insert("Success", False);
	Result.Insert("ErrorText", "");
	Result.Insert("SignatureProperties", DigitalSignatureClientServer.NewSignatureProperties());
	Result.Insert("SignAlgorithm");
	Result.Insert("ErrorCreatingCryptoManager", False);
	Result.Insert("OperationStarted", Parameters.OperationStarted);
	
	Signature = Parameters.DataItemForSErver.Signature;
	If TypeOf(Signature) = Type("String") Then
		Try
			Signature = GetFromTempStorage(Signature);
		Except
			ErrorInfo = ErrorInfo();
			Result.ErrorText = DigitalSignatureInternalClientServer.DataGettingErrorTitle("ExtensionValiditySignature")
			 + Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo);
			Return Result;
		EndTry;
	EndIf;
	
	SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(Signature);
	Result.SignAlgorithm = SignAlgorithm;
	
	If Parameters.ThisistheServiceModelwithEnhancementAvailable Then
	
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("SignatureType", Parameters.SignatureType);
		ExecutionParameters.Insert("ParametersSignatureCAdEST", Parameters.ParametersSignatureCAdEST);
		ExecutionParameters.Insert("ServiceAccountDSS", Parameters.ServiceAccountDSS);
		ExecutionParameters.Insert("ShouldIgnoreCertificateValidityPeriod", Parameters.ShouldIgnoreCertificateValidityPeriod);
		
		QueryResult = RefineSignatureInService(Signature, ExecutionParameters);
		FillPropertyValues(Result, QueryResult);

		If Result.Success Then
			If Parameters.DataItemForSErver.Property("SignedObject") Then
				
				Result.SignatureProperties.SignedObject = Parameters.DataItemForSErver.SignedObject;
				Result.SignatureProperties.SequenceNumber = Parameters.DataItemForSErver.SequenceNumber;
				ErrorPresentation = UpdateAdvancedSignature(Result.SignatureProperties);
				
				If ValueIsFilled(ErrorPresentation) Then
					Result.Success = False;
					Result.ErrorText = ErrorPresentation;
					Return Result;
				EndIf;
				
				If ValueIsFilled(Result.SignatureProperties.Signature) Then
					RegisterImprovementSignaturesInJournal(Result.SignatureProperties);
				EndIf;
				
			EndIf; 
		Else
			Return Result;
		EndIf;
		
		PutToTempStorage(ExecutionParameters.ServiceAccountDSS, Parameters.ServiceAccountDSSSaddress);
		
	Else
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.ErrorDescription = New Structure;
		CreationParameters.SignAlgorithm = SignAlgorithm;
		
		CryptoManager = CryptoManager("ExtensionValiditySignature", CreationParameters);
		
		If CryptoManager = Undefined Then
			Result.ErrorText = CreationParameters.ErrorDescription;
			Result.ErrorCreatingCryptoManager = True;
			Return Result;
		EndIf;
		
		CryptoManager.TimestampServersAddresses = DigitalSignature.CommonSettings().TimestampServersAddresses;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("CryptoManager", CryptoManager);
		AdditionalParameters.Insert("ShouldIgnoreCertificateValidityPeriod", Parameters.ShouldIgnoreCertificateValidityPeriod);
		
		If Parameters.DataItemForSErver.Property("SignedObject") Then
			QueryResult = DigitalSignature.ImproveObjectSignature(Parameters.DataItemForSErver.SignedObject,
				Parameters.DataItemForSErver.SequenceNumber, Parameters.SignatureType,
				Parameters.AddArchiveTimestamp, Parameters.FormIdentifier, AdditionalParameters);
		Else
			QueryResult = DigitalSignature.EnhanceSignature(Signature, Parameters.SignatureType,
				Parameters.AddArchiveTimestamp, AdditionalParameters);
		EndIf;
		
		FillPropertyValues(Result, QueryResult);
		
	EndIf;
	
	If Not Result.Success Then
		Return Result;
	EndIf;
	
	Result.OperationStarted = True;
	
	Return Result;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// Infobase update.

#Region ManagingXMLDSig

// Signs the message by inserting the signature data into the XMLEnvelope.
//
// Parameters:
//  XMLEnvelope             - See DigitalSignatureClient.XMLEnvelope
//  XMLDSigParameters       - See DigitalSignatureClient.XMLDSigParameters
//  CryptoCertificate - CryptoCertificate - a crypto certificate to be used.
//  CryptoManager   - CryptoManager   - a crypto manager
//                           that matches the private key of the certificate with the set password.
//
// Returns:
//  String - the signed XMLEnvelope.
//
Function Sign(Val XMLEnvelope, XMLDSigParameters, CryptoCertificate, CryptoManager) Export
	
	Password = CryptoManager.PrivateKeyAccessPassword;
	
	ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
	
	CryptoProviderProperties = CryptoProviderProperties(CryptoManager);
	ComponentObject.PathToCryptoprovider = CryptoProviderProperties.Path;
	
	XMLEnvelopeProperties = XMLEnvelopeProperties(XMLEnvelope, XMLDSigParameters, False);
	If XMLEnvelopeProperties <> Undefined
	   And ValueIsFilled(XMLEnvelopeProperties.ErrorText) Then
		Raise XMLEnvelopeProperties.ErrorText;
	EndIf;
	
	Base64CryptoCertificate = DigitalSignatureInternalClientServer.Base64CryptoCertificate(
		CryptoCertificate.Unload());
	
	SigningAlgorithmData = New Structure(New FixedStructure(XMLDSigParameters));
	DigitalSignatureInternalClientServer.CheckChooseSignAlgorithm(
		Base64CryptoCertificate, SigningAlgorithmData, True, XMLEnvelopeProperties);
	
	XMLEnvelope = StrReplace(XMLEnvelope, "%BinarySecurityToken%", Base64CryptoCertificate);
	XMLEnvelope = StrReplace(XMLEnvelope, "%SignatureMethod%", SigningAlgorithmData.SelectedSignatureAlgorithm);
	XMLEnvelope = StrReplace(XMLEnvelope, "%DigestMethod%",    SigningAlgorithmData.SelectedHashAlgorithm);
	
	If XMLEnvelopeProperties <> Undefined Then
		For IndexOf = 0 To XMLEnvelopeProperties.AreasToHash.UBound() Do
			HashedArea = XMLEnvelopeProperties.AreasToHash[IndexOf];
			CanonizedTextXMLBody = CanonizedXMLText(ComponentObject,
				XMLEnvelopeProperties.AreasBody[IndexOf], HashedArea.TransformationAlgorithms);
			DigestValueAttribute = HashResult(ComponentObject, CanonizedTextXMLBody,
				SigningAlgorithmData.SelectedHashAlgorithmOID, CryptoProviderProperties.Type);

			XMLEnvelope = StrReplace(XMLEnvelope, HashedArea.HashValue, DigestValueAttribute);
		EndDo;
	Else
		CanonizedTextXMLBody = C14N(ComponentObject, XMLEnvelope,
			SigningAlgorithmData.XPathTagToSign);
		
		DigestValueAttribute = HashResult(ComponentObject, CanonizedTextXMLBody,
			SigningAlgorithmData.SelectedHashAlgorithmOID, CryptoProviderProperties.Type);

		XMLEnvelope = StrReplace(XMLEnvelope, "%DigestValue%", DigestValueAttribute);
	EndIf;
	
	If XMLEnvelopeProperties = Undefined Then
		CanonizedTextXMLSignedInfo = C14N(ComponentObject,
			XMLEnvelope, SigningAlgorithmData.XPathSignedInfo);
	Else
		SignedInfoArea = DigitalSignatureInternalClientServer.XMLScope(XMLEnvelope,
			XMLEnvelopeProperties.SignedInfoArea.TagName);
		SignedInfoArea.NamespacesUpToANode =
			XMLEnvelopeProperties.SignedInfoArea.NamespacesUpToANode;
		
		If ValueIsFilled(SignedInfoArea.ErrorText) Then
			Raise SignedInfoArea.ErrorText;
		EndIf;
		
		CanonizedTextXMLSignedInfo = CanonizedXMLText(ComponentObject,
			SignedInfoArea,
			CommonClientServer.ValueInArray(XMLEnvelopeProperties.TheCanonizationAlgorithm));
	EndIf;
	
	SignatureValueAttribute = SignResult(ComponentObject,
		CanonizedTextXMLSignedInfo,
		CryptoCertificate,
		Password);
	
	XMLEnvelope = StrReplace(XMLEnvelope, "%SignatureValue%", SignatureValueAttribute);
	
	Return XMLEnvelope;
	
EndFunction

// Returns a certificate, by which the signature was made.
// If the signature check fails, an exception is generated.
//
// Parameters:
//  XMLEnvelope           - See DigitalSignatureClient.XMLEnvelope
//  XMLDSigParameters     - See DigitalSignatureClient.XMLDSigParameters
//  CryptoManager - CryptoManager - a crypto manager
//                         that supports the algorithms of the signature to be checked.
//  XMLEnvelopeProperties  - See XMLEnvelopeProperties
//
// Returns:
//  Structure:
//   * Certificate     - CryptoCertificate
//   * SigningDate - Date
//
Function VerifySignature(Val XMLEnvelope, XMLDSigParameters, CryptoManager, XMLEnvelopeProperties = Undefined) Export
	
	ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
	
	CryptoProviderProperties = CryptoProviderProperties(CryptoManager);
	ComponentObject.PathToCryptoprovider = CryptoProviderProperties.Path;
	SigningAlgorithmData = New Structure(New FixedStructure(XMLDSigParameters));
	
	If XMLEnvelopeProperties = Undefined Then
		CanonizedTextXMLSignedInfo = C14N(ComponentObject,
			XMLEnvelope, SigningAlgorithmData.XPathSignedInfo);
		CanonizedTextXMLBody = C14N(ComponentObject,
			XMLEnvelope, SigningAlgorithmData.XPathTagToSign);
		Base64CryptoCertificate = DigitalSignatureInternalClientServer.CertificateFromSOAPEnvelope(XMLEnvelope);
		SignatureValue = DigitalSignatureInternalClientServer.FindInXML(XMLEnvelope, "SignatureValue");
		HashValue    = DigitalSignatureInternalClientServer.FindInXML(XMLEnvelope, "DigestValue");
	Else
		CanonizedTextXMLSignedInfo = CanonizedXMLText(ComponentObject,
			XMLEnvelopeProperties.SignedInfoArea,
			CommonClientServer.ValueInArray(XMLEnvelopeProperties.TheCanonizationAlgorithm));
		
		SignatureValue = XMLEnvelopeProperties.SignatureValue;
		Base64CryptoCertificate = XMLEnvelopeProperties.Certificate.CertificateValue;
		
	EndIf;
	
	DigitalSignatureInternalClientServer.CheckChooseSignAlgorithm(
		Base64CryptoCertificate, SigningAlgorithmData, True, XMLEnvelopeProperties);
		
	SignatureCorrect = VerifySignResult(ComponentObject,
		CanonizedTextXMLSignedInfo,
		SignatureValue,
		Base64CryptoCertificate,
		CryptoProviderProperties.Type);

	If XMLEnvelopeProperties <> Undefined Then
		
		Counter = 1;
		For Each HashedArea In XMLEnvelopeProperties.AreasToHash Do
			CanonizedTextXMLBody = CanonizedXMLText(ComponentObject,
				XMLEnvelopeProperties.AreasBody[Counter-1], HashedArea.TransformationAlgorithms);
			HashValue = HashedArea.HashValue; 
			
			DigestValueAttribute = HashResult(ComponentObject,
				CanonizedTextXMLBody,
				SigningAlgorithmData.SelectedHashAlgorithmOID,
				CryptoProviderProperties.Type);
				
			HashMaps = (DigestValueAttribute = HashValue);
			
			If Not HashMaps Or Not SignatureCorrect Then
				Raise DigitalSignatureInternalClientServer.XMLSignatureVerificationErrorText(SignatureCorrect, HashMaps);
			EndIf;
			Counter = Counter + 1;
		EndDo;
		
		Return XMLSignatureVerificationResult(Base64CryptoCertificate);
		
	EndIf;
	
	DigestValueAttribute = HashResult(ComponentObject,
		CanonizedTextXMLBody,
		SigningAlgorithmData.SelectedHashAlgorithmOID,
		CryptoProviderProperties.Type);
	
	HashMaps = (DigestValueAttribute = HashValue);
	
	If HashMaps And SignatureCorrect Then
		Return XMLSignatureVerificationResult(Base64CryptoCertificate);
	Else
		Raise DigitalSignatureInternalClientServer.XMLSignatureVerificationErrorText(SignatureCorrect, HashMaps);
	EndIf;
	
EndFunction

Function XMLSignatureVerificationResult(Base64CryptoCertificate)
	
	BinaryData = Base64Value(Base64CryptoCertificate);

	Result = New Structure;
	Result.Insert("Certificate", New CryptoCertificate(BinaryData));
	Result.Insert("SigningDate", Undefined);

	Return Result;
		
EndFunction

// Calculates and checks the properties of the XML envelope for signing and checking the signature.
//
// Parameters:
//  XMLEnvelope             - See DigitalSignatureClient.XMLEnvelope
//  XMLDSigParameters       - See DigitalSignatureClient.XMLDSigParameters
//  CheckSignature  - Boolean - If False, the envelope is checked for 
//                                substitution parameters and canonicalization algorithms.
//                              If True, the envelope contains correct algorithms of
//                                canonicalization, signing, and hashing, and filled in
//                                values of signature, hash, and certificate.
//
// Returns:
//   See ReturnedPropertiesOfTheXMLEnvelope
//
Function XMLEnvelopeProperties(XMLEnvelope, XMLDSigParameters, CheckSignature) Export
	
	If ValueIsFilled(XMLDSigParameters.XPathSignedInfo)
	 Or ValueIsFilled(XMLDSigParameters.XPathTagToSign) Then
		Return Undefined; // Backward compatibility.
	EndIf;
	
	XMLReader = New XMLReader;
	XMLReader.SetString(XMLEnvelope);
	
	DOMBuilder = New DOMBuilder;
	DOMDocument = DOMBuilder.Read(XMLReader);
	
	XMLReader.Close();
	
	XMLEnvelopeProperties = ServicePropertiesOfTheXMLEnvelope(CheckSignature);
	
	SignatureNodeName = "Signature";
	NameOfTheSignatureNodeNamespace = "http://www.w3.org/2000/09/xmldsig#";
	NamespacesUpToAndIncludingTheSignatureNode = New Array;
	
	ExcludedNodes = New Array;
	NumberSingnature = 0;
	While True Do
		NumberSingnature = NumberSingnature + 1;
		SignatureNode = FindANodeByName(DOMDocument,
			SignatureNodeName, NameOfTheSignatureNodeNamespace,
			XMLEnvelopeProperties.ErrorText, ExcludedNodes, NamespacesUpToAndIncludingTheSignatureNode);
		If SignatureNode = Undefined Then
			Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
		EndIf;
		
		// If the node's text contains the signature value, this means that signature overlapping is used.
		// Find a different node.
		If StrFind(SignatureNode.TextContent, "%SignatureValue%") = 0 And Not CheckSignature Then
			ExcludedNodes.Add(SignatureNode);
			Continue;
		Else
			Break;
		EndIf;
	EndDo;
	
	For Each ChildNode In SignatureNode.ChildNodes Do
		If ChildNode.LocalName = "SignedInfo" Then
			If Not ProcessTheSignedInfoNode(ChildNode, XMLEnvelopeProperties) Then
				Break;
			EndIf;
		ElsIf ChildNode.LocalName = "SignatureValue" Then
			If Not GetValue(ChildNode, XMLEnvelopeProperties, "SignatureValue") Then
				Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
			EndIf;
		ElsIf ChildNode.LocalName = "KeyInfo" Then
			If Not ProcessTheKeyInfoNode(ChildNode, XMLEnvelopeProperties) Then
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	If ValueIsFilled(XMLEnvelopeProperties.ErrorText) Then
		Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
	EndIf;
	
	For Each KeyAndValue In XMLEnvelopeProperties.RequiredNodes Do
		If KeyAndValue.Value <> Undefined Then
			Continue;
		EndIf;
		NameParts = StrSplit(KeyAndValue.Key, "_");
		If NameParts.Count() > 1 Then
			XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong văn bản XML không tìm thấy nút ""%1"" trong nút ""%2"".';
					|ru = 'В документе XML не найден узел ""%1"" в узле ""%2"".';
					|en = '%1 node is not found in %2 node in XML document.'; fa = '%1 node is not found in %2 node in XML document.';
					|it = 'Nodo ""%1"" nel nodo ""%2"" non trovato nel documento XML.';
					|pl = 'W dokumencie XML nie znaleziono węzła ""%1"" w węźle ""%2"".';
					|tr = 'XML dosyasında ""%2"" düğümünde ""%1"" düğümü bulunamadı.'"), KeyAndValue.Key);
		Else
			XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong văn bản XML không tìm thấy nút ""%1"".';
					|ru = 'В документе XML не найден узел ""%1"".';
					|en = '%1 node is not found in XML document.'; fa = '%1 node is not found in XML document.';
					|it = 'Nodo ""%1"" non trovato nel documento XML.';
					|pl = 'W dokumencie XML nie znaleziono węzła ""%1"".';
					|tr = 'XML dosyasında ""%1"" düğümü bulunamadı.'"), NameParts[0]);
		EndIf;
		Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
	EndDo;
	
	If ValueIsFilled(XMLEnvelopeProperties.Certificate.NodeID)
	   And ValueIsFilled(XMLEnvelopeProperties.Certificate.CertificateValue) Then
		
		XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong văn bản XML chứng thư đã được khai báo hai lần:
			           |- dưới dạng tham chiếu URI đến phần tử ""%1"";
			           |- dưới dạng dữ liệu ""%2"".';
			           |ru = 'В документе XML сертификат объявлен дважды:
			           |- в виде URI ссылки на элемент ""%1"";
			           |- в виде данных ""%2"".';
			           |en = 'The certificate is declared twice in the XML document:
			           |-as a URI link to %1 item;
			           |-as %2 data.'; fa = 'The certificate is declared twice in the XML document:
			           |-as a URI link to %1 item;
			           |-as %2 data.';
			           |it = 'Il certificato è dichiarato due volte nel documento XML:
			           |- come collegamento URL all''elemento ""%1"";
			           |- come dati ""%2"".';
			           |pl = 'W dokumencie XML certyfikat jest ogłoszony dwa razy:
			           |- jako odnośnik URI do elementu ""%1"";
			           |- jako dane ""%2"".';
			           |tr = 'XML belgesinde sertifika iki defa ilan edildi:
			           |- ""%1"" öğenin URl bağlantısı olarak;
			           |- ""%2"" veri şeklinde.'"),
			XMLEnvelopeProperties.Certificate.NodeID,
			XMLEnvelopeProperties.Certificate.CertificateValue);
		
		Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
		
	ElsIf Not ValueIsFilled(XMLEnvelopeProperties.Certificate.NodeID)
	        And Not ValueIsFilled(XMLEnvelopeProperties.Certificate.CertificateValue) Then
		
		XMLEnvelopeProperties.ErrorText =
			NStr("vi = 'Trong văn bản XML không tìm thấy chứng thư.';
				|ru = 'В документе XML не найден сертификат.';
				|en = 'The certificate is not found in the XML document.'; fa = 'The certificate is not found in the XML document.';
				|it = 'Certificato non trovato nel documento XML.';
				|pl = 'W dokumencie XML nie znaleziono certyfikatu.';
				|tr = 'XML dosyasında sertifika bulunamadı.'");
		
		Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
	EndIf;

	ExcludedNodes.Add(SignatureNode);
	
	If ValueIsFilled(XMLEnvelopeProperties.Certificate.NodeID) Then
		CertificateNode = FindANodeByID(DOMDocument,
			XMLEnvelopeProperties.Certificate.NodeID,
			XMLEnvelopeProperties.ErrorText,
			ExcludedNodes);
		If ValueIsFilled(XMLEnvelopeProperties.ErrorText) Then
			Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
		EndIf;
		If Not GetValue(CertificateNode, XMLEnvelopeProperties,
					"CertificateValue", XMLEnvelopeProperties.Certificate) Then
			Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
		EndIf;
		ExcludedNodes.Add(CertificateNode);
	EndIf;
	
	NodesBody = New Array;
	
	For Each HashedArea In XMLEnvelopeProperties.AreasToHash Do
		NamespacesUpToTheBodyNode = New Array;
		BodyNode = FindANodeByID(DOMDocument,
			HashedArea.NodeID,
			XMLEnvelopeProperties.ErrorText,
			ExcludedNodes,
			NamespacesUpToTheBodyNode);
		If ValueIsFilled(XMLEnvelopeProperties.ErrorText) Then
			Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
		EndIf;
		ExcludedNodes.Add(BodyNode);
		NodesBody.Add(BodyNode);
	EndDo;
	
	For Each HashedArea In XMLEnvelopeProperties.AreasToHash Do
		NodeBody2 = FindANodeByID(DOMDocument,
			HashedArea.NodeID,
			XMLEnvelopeProperties.ErrorText, ExcludedNodes, , True);
		If NodeBody2 <> Undefined Then
			Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
		EndIf;
	EndDo;
	
	TheSignedInfoNode = XMLEnvelopeProperties.UniqueNodes.SignedInfo; // DOMElement
	SignedInfoArea = DigitalSignatureInternalClientServer.XMLScope(XMLEnvelope,
		TheSignedInfoNode.TagName, NumberSingnature);
	If ValueIsFilled(SignedInfoArea.ErrorText) Then
		XMLEnvelopeProperties.ErrorText = SignedInfoArea.ErrorText;
		Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
	EndIf;
	SignedInfoArea.NamespacesUpToANode = NamespacesUpToAndIncludingTheSignatureNode;
	XMLEnvelopeProperties.SignedInfoArea = SignedInfoArea;
	
	For Each ItemAreaBody In NodesBody Do
		BodyArea = DigitalSignatureInternalClientServer.XMLScope(XMLEnvelope,
			ItemAreaBody.TagName);
		If ValueIsFilled(BodyArea.ErrorText) Then
			XMLEnvelopeProperties.ErrorText = BodyArea.ErrorText;
			Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
		EndIf;
		BodyArea.NamespacesUpToANode = NamespacesUpToTheBodyNode;
		XMLEnvelopeProperties.AreasBody.Add(BodyArea);
	EndDo;
	
	Return ReturnedPropertiesOfTheXMLEnvelope(XMLEnvelopeProperties);
	
EndFunction

Function AnObjectOfAnExternalComponentOfTheExtraCryptoAPI()
	
	ComponentDetails = DigitalSignatureInternalClientServer.ComponentDetails();
	ComponentObject = Common.AttachAddInFromTemplate(ComponentDetails.ObjectName,
		ComponentDetails.FullTemplateName);
	
	If ComponentObject = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kết nối cấu phần ngoài %1.';
				|ru = 'Не удалось подключить внешнюю компоненту %1.';
				|en = 'Couldn''t attach add-in ""%1"".'; fa = 'Couldn''t attach add-in ""%1"".';
				|it = 'Non è stato possibile collegare la componente esterna %1.';
				|pl = 'Nie udało się podłączyć komponentu zewnętrznego %1.';
				|tr = '%1 harici bileşen bağlanamadı.'"), ComponentDetails.ObjectName);
		Raise ErrorText;
	EndIf;
	
	ConfigureTheComponent(ComponentObject);
	
	Return ComponentObject;
	
EndFunction

Procedure ConfigureTheComponent(ComponentObject)
	
	Try
		ComponentObject.OIDMap =
			DigitalSignatureInternalClientServer.IdentifiersOfHashingAlgorithmsAndThePublicKey();
	Except
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thiết lập thuộc tính %1 cấu hình %2 do nguyên nhân:
				|%3';
				|ru = 'Не удалось установить свойство %1 компоненты %2 по причине:
				|%3';
				|en = 'Cannot set the %1 property of the %2 add-in due to:
				|%3'; fa = 'Cannot set the %1 property of the %2 add-in due to:
				|%3';
				|it = 'Не удалось установить свойство %1 компоненты %2 по причине:
				|%3';
				|pl = 'Cannot set the %1 property of the %2 add-in due to:
				|%3';
				|tr = '%2 bileşeninin %1 özelliği şu sebeple kurulamadı:
				|%3'"), "OIDMap", "ExtraCryptoAPI", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
EndProcedure

Function CheckCMSSignature(Signature, Data, CMSParameters, CryptoManager) Export
	
	ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
	
	CryptoProviderProperties = CryptoProviderProperties(CryptoManager);
	ComponentObject.PathToCryptoprovider = CryptoProviderProperties.Path;
	
	Result = CMSVerifySignResult(ComponentObject,
		Signature,
		Data,
		CMSParameters,
		CryptoProviderProperties.Type);
	
	Return Result;
	
EndFunction

// Installed cryptographic service providers
// 
// Returns:
//  Structure:
//   * CheckCompleted - Boolean
//   * Error - String - If "CheckCompleted" is False
//   * Cryptoproviders - Array of Structure:
//      ** Ref - Undefined, CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//      ** Presentation - String
//      ** ApplicationName - String
//      ** ApplicationType - Number
//      ** SignAlgorithm - String
//      ** HashAlgorithm - String
//      ** EncryptAlgorithm - String
//      ** Id - String
//      ** ApplicationPath - String
//      ** Version - String - Library version
//      ** ILicenseInfo - Boolean - App license presence flag
//      ** AutoDetect - Boolean
//
Function InstalledCryptoProviders(ComponentObject = Undefined) Export
	
	Result = New Structure;
	Result.Insert("CheckCompleted", False);
	Result.Insert("Cryptoproviders", New Array);
	Result.Insert("Error", "");
	
	Settings = DigitalSignature.CommonSettings();
	
	If (Not Common.FileInfobase() Or Common.ClientConnectedOverWebServer())
		And Not DigitalSignature.VerifyDigitalSignaturesOnTheServer()
		And Not DigitalSignature.GenerateDigitalSignaturesAtServer() Then
			Result.Error = NStr("vi = 'Chưa tùy chỉnh mã hóa trên máy chủ.';
								|ru = 'Не настроена криптография на сервере.';
								|en = 'Cryptography is not configured on the server.'; fa = 'Cryptography is not configured on the server.';
								|it = 'Не настроена криптография на сервере.';
								|pl = 'Cryptography is not configured on the server.';
								|tr = 'Kriptografi sunucuda ayarlanmadı.'");
			Return Result;
	EndIf;
	
	Try
		If ComponentObject = Undefined Then
			ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
		EndIf; 
		ResultList = ComponentObject.GetListCryptoProviders();
		ApplicationsByNamesWithType = Settings.ApplicationsByNamesWithType;
		InstalledCryptoProviders = DigitalSignatureInternalClientServer.InstalledCryptoProvidersFromAddInResponse(
			ResultList, ApplicationsByNamesWithType, False);
		Result.CheckCompleted = True;
		Result.Cryptoproviders = InstalledCryptoProviders;
	Except
		Result.CheckCompleted = False;
		Result.Error = ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	
	Return Result;
		
EndFunction

Function CryptoProviderProperties(CryptoManager)
	
	CryptoModuleInformation = CryptoManager.GetCryptoModuleInformation();
	
	CryptoProviderName = CryptoModuleInformation.Name;
	
	ErrorDescription = "";
	CryptoProvidersResult = DigitalSignatureInternalCached.InstalledCryptoProviders();
	AppsAuto = DigitalSignatureInternalClientServer.CryptoProvidersSearchResult(CryptoProvidersResult, ComputerName());
		
	If TypeOf(AppsAuto) = Type("String") Then
		ErrorDescription = AppsAuto;
		AppsAuto = Undefined;
	EndIf;
	
	ApplicationDetails = DigitalSignatureInternalClientServer.ApplicationDetailsByCryptoProviderName(CryptoProviderName,
		DigitalSignature.CommonSettings().ApplicationsDetailsCollection, AppsAuto); // See DigitalSignatureInternalCached.ApplicationDetails
	
	If ApplicationDetails = Undefined Then
		If Not IsBlankString(ErrorDescription) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xác định kiểu nhà cung cấp mã hóa %1. %2';
					|ru = 'Не удалось определить тип криптопровайдера %1. %2';
					|en = 'Cannot determine the type of cryptographic service provider %1. %2'; fa = 'Cannot determine the type of cryptographic service provider %1. %2';
					|it = 'Не удалось определить тип криптопровайдера %1. %2';
					|pl = 'Cannot determine the type of cryptographic service provider %1. %2';
					|tr = '%1 kripto sağlayıcısının türü tespit edilemedi. %2'"), CryptoModuleInformation.Name, ErrorDescription);
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xác định kiểu nhà cung cấp mã hóa %1';
					|ru = 'Не удалось определить тип криптопровайдера %1';
					|en = 'Cannot determine the type of cryptographic service provider %1'; fa = 'Cannot determine the type of cryptographic service provider %1';
					|it = 'Non è stato possibile definire il tipo di cryptoprovider%1';
					|pl = 'Nie można określić typu dostawcy kryptograficznego %1';
					|tr = '%1 kripto sağlayıcının türü tespit edilemedi'"), CryptoModuleInformation.Name);
		EndIf;
		Raise ErrorText;
	EndIf;
	
	If ApplicationDetails.Property("AutoDetect") Then
		DescriptionOfWay = New Structure("ApplicationPath, Exists, ErrorText", ApplicationDetails.PathToAppAuto, True, "");
	Else
		DescriptionOfWay = ApplicationPath(ApplicationDetails.Ref);
	EndIf;
	
	If ValueIsFilled(DescriptionOfWay.ErrorText) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xác định đường dẫn đến ứng dụng chữ ký điện tử
			           |""%1"" do nguyên nhân:
			           |%2';
			           |ru = 'Не удалось определить путь к приложению электронной подписи
			           |""%1"" по причине:
			           |%2';
			           |en = 'Cannot determine the path to digital signing app
			           |""%1"" due to:
			           |%2'; fa = 'Cannot determine the path to digital signing app
			           |""%1"" due to:
			           |%2';
			           |it = 'Не удалось определить путь к приложению электронной подписи
			           |""%1"" по причине:
			           |%2';
			           |pl = 'Cannot determine the path to digital signing app
			           |""%1"" due to:
			           |%2';
			           |tr = '
			           |""%1"" dijital imza uygulamasına yol şu sebeple belirlenemedi:
			           |%2'"),
			ApplicationDetails.Ref,
			DescriptionOfWay.ErrorText);
		Raise ErrorText;
	EndIf;
	
	Properties = New Structure("Type, Path", ApplicationDetails.ApplicationType, "");
	Properties.Path = DescriptionOfWay.ApplicationPath;
	
	Return Properties;
	
EndFunction

Function C14N(ComponentObject, XMLEnvelope, XPath)
	
	Try
		CanonizedXMLText = ComponentObject.C14N(XMLEnvelope, XPath);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("C14N",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If CanonizedXMLText = Undefined Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("C14N",
			ComponentObject.GetLastError());
		Raise ErrorText;
	EndIf;
	
	Return CanonizedXMLText;
	
EndFunction

Function CanonizedXMLText(ComponentObject, XMLScope, Algorithms)
	
	Result = Undefined;
	HigherLevelNamespacesHaveBeenAdded = False;
	
	For Each Algorithm In Algorithms Do
		If Algorithm.Kind = "envsig" Then
			Continue;
		ElsIf Algorithm.Kind = "C14N"
		      Or Algorithm.Kind = "smev" Then
			
			If Not HigherLevelNamespacesHaveBeenAdded Then
				DescriptionOfTheBeginningOfTheArea = DigitalSignatureInternalClientServer.ExtendedBeginningOfTheXMLArea(
					XMLScope, Algorithm, Result);
				If ValueIsFilled(DescriptionOfTheBeginningOfTheArea.ErrorText) Then
					Raise DescriptionOfTheBeginningOfTheArea.ErrorText;
				EndIf;
				XMLText = DigitalSignatureInternalClientServer.XMLAreaText(XMLScope,
					DescriptionOfTheBeginningOfTheArea.Begin);
				HigherLevelNamespacesHaveBeenAdded = True;
				
			ElsIf Result = Undefined Then
				XMLText = DigitalSignatureInternalClientServer.XMLAreaText(XMLScope);
			Else
				XMLText = Result;
			EndIf;
			
			If Algorithm.Kind = "C14N" Then
				Result = C14N_body(ComponentObject, XMLText, Algorithm);
			Else
				Result = CanonizationSMEV(ComponentObject, XMLText);
			EndIf;
		EndIf;
	EndDo;
	
	If Result = Undefined Then
		Result = DigitalSignatureInternalClientServer.XMLAreaText(XMLScope);
	EndIf;
	
	Return Result;
	
EndFunction

Function C14N_body(ComponentObject, XMLText, Algorithm)
	
	Try
		CanonizedXMLText = ComponentObject.c14n_body(XMLText,
			Algorithm.Version, Algorithm.WithComments);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("C14N_body",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If CanonizedXMLText = Undefined Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("C14N_body",
			ComponentObject.GetLastError());
		Raise ErrorText;
	EndIf;
	
	Return CanonizedXMLText;
	
EndFunction

Function CanonizationSMEV(ComponentObject, XMLText)
	
	Try
		CanonizedXMLText = ComponentObject.TransformSMEV(XMLText);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("TransformSMEV",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If CanonizedXMLText = Undefined Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("TransformSMEV",
			ComponentObject.GetLastError());
		Raise ErrorText;
	EndIf;
	
	Return CanonizedXMLText;
	
EndFunction

Function HashResult(ComponentObject, CanonizedTextXMLBody, HashingAlgorithmOID, CryptoProviderType)
	
	Try
		DigestValueAttribute = ComponentObject.Hash(
			CanonizedTextXMLBody,
			HashingAlgorithmOID,
			CryptoProviderType);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("Hash",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If DigestValueAttribute = Undefined Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("Hash",
			ComponentObject.GetLastError());
		Raise ErrorText;
	EndIf;
	
	Return DigestValueAttribute;
	
EndFunction

Function SignResult(ComponentObject, CanonizedTextXMLSignedInfo,
	CryptoCertificate, PrivateKeyAccessPassword)
	
	Base64CryptoCertificate = DigitalSignatureInternalClientServer.Base64CryptoCertificate(
		CryptoCertificate.Unload());
	
	Try
		SignatureValueAttribute = ComponentObject.Sign(
			CanonizedTextXMLSignedInfo,
			Base64CryptoCertificate,
			PrivateKeyAccessPassword);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("Sign",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If SignatureValueAttribute = Undefined Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("Sign",
			ComponentObject.GetLastError());
		Raise ErrorText;
	EndIf;
	
	Return SignatureValueAttribute;
	
EndFunction

Function VerifySignResult(ComponentObject, CanonizedTextXMLSignedInfo,
	SignatureValueAttribute, Base64CryptoCertificate, CryptoProviderType)
	
	Try
		SignatureCorrect = ComponentObject.VerifySign(
			CanonizedTextXMLSignedInfo,
			SignatureValueAttribute,
			Base64CryptoCertificate,
			CryptoProviderType);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("VerifySign",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If SignatureCorrect = Undefined Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("VerifySign",
			ComponentObject.GetLastError());
		Raise ErrorText;
	EndIf;
	
	Return SignatureCorrect;
	
EndFunction

Function CMSSignResult(ComponentObject, DataToSign, CMSParameters, CryptoCertificate, PrivateKeyAccessPassword)
	
	AddInParameters = DigitalSignatureInternalClientServer.AddInParametersCMSSign(CMSParameters, DataToSign);
	
	Base64CryptoCertificate = DigitalSignatureInternalClientServer.Base64CryptoCertificate(
		CryptoCertificate.Unload());
	
	Try
		SignatureValueAttribute = ComponentObject.CMSSign(
			AddInParameters.Data,
			Base64CryptoCertificate,
			PrivateKeyAccessPassword,
			AddInParameters.SignatureType,
			AddInParameters.DetachedAddIn,
			AddInParameters.IncludeCertificatesInSignature);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("CMSSign",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If Not ValueIsFilled(SignatureValueAttribute) Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("CMSSign",
			ComponentObject.GetLastError());
		Raise ErrorText;
	EndIf;
	
	Return SignatureValueAttribute;
	
EndFunction

Function CMSVerifySignResult(ComponentObject, Signature, Data, CMSParameters, CryptoProviderType)
	
	Certificate = Null;
	Try
		SignatureCorrect = ComponentObject.CMSVerifySign(Signature,
			CMSParameters.DetachedAddIn, Data, CryptoProviderType, Certificate);
	Except
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("CMSVerifySign",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	If SignatureCorrect = Undefined Then
		ErrorText = DigitalSignatureInternalClientServer.ErrorCallMethodComponents("CMSVerifySign",
			ComponentObject.GetLastError());
		Raise ErrorText;
		
	ElsIf Not SignatureCorrect Then
		ErrorText = NStr("vi = 'Chữ ký sai.';
						|ru = 'Подпись неверна.';
						|en = 'Invalid signature.'; fa = 'Invalid signature.';
						|it = 'Firma non corretta.';
						|pl = 'Podpis jest niezgodny.';
						|tr = 'İmza geçersiz.'");
		Raise ErrorText;
		
	ElsIf TypeOf(Certificate) <> Type("BinaryData") Then
		ErrorText = NStr("vi = 'Chữ ký đúng, nhưng không chứa dữ liệu chứng thư.';
						|ru = 'Подпись верна, но не содержит данных сертификата.';
						|en = 'The signature is valid but does not contain the certificate data.'; fa = 'The signature is valid but does not contain the certificate data.';
						|it = 'Firma corretta, ma non contiene i dati del certificato.';
						|pl = 'Podpis jest zgodny, ale nie zawiera danych certyfikatu.';
						|tr = 'İmza geçrli, ancak sertifika verileri içermiyor.'");
		Raise ErrorText;
	EndIf;
	
	SigningDate = DigitalSignature.SigningDate(Signature);
	If Not ValueIsFilled(SigningDate) Then
		SigningDate = Undefined;
	EndIf;
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Certificate", New CryptoCertificate(Certificate));
	ReturnValue.Insert("SigningDate", SigningDate);
	
	Return ReturnValue;
	
EndFunction


#EndRegion

#Region AuxiliaryProceduresAndFunctions

// Intended for: UpdateCertificatesList procedure.
Procedure ProcessAddedCertificates(CertificatesPropertiesTable, ButAlreadyAddedOnes,
	FilterByCompany = Undefined, AreAvailableOnlyWithKey = False)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("Thumbprints", CertificatesPropertiesTable.Copy(, "Thumbprint"));
	Query.Text =
	"SELECT
	|	Thumbprints.Thumbprint AS Thumbprint
	|INTO Thumbprints
	|FROM
	|	&Thumbprints AS Thumbprints
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Certificates.Thumbprint AS Thumbprint,
	|	Certificates.Description AS Presentation,
	|	FALSE AS IsRequest,
	|	Certificates.Organization AS Organization,
	|	Certificates.Ref AS Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|		INNER JOIN Thumbprints AS Thumbprints
	|		ON Certificates.Thumbprint = Thumbprints.Thumbprint
	|			AND &OptionalConnection";
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.AddRequestWhenAddingCertificates(
			Query.Text);
	Else
		Query.Text = StrReplace(Query.Text, "AND &OptionalConnection", "");
	EndIf;
	
	Selection = Query.Execute().Select();
	
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		
		String = CertificatesPropertiesTable.Find(Selection.Thumbprint, "Thumbprint");
		CurrentUser = Users.CurrentUser();
		CertificateReference = Selection.Ref;
		If ButAlreadyAddedOnes Then
			If String <> Undefined Then // Protection against data errors (duplicate certificates).
				CertificatesPropertiesTable.Delete(String);
			EndIf;
		ElsIf ValueIsFilled(FilterByCompany) Then
			If String <> Undefined And Selection.Organization <> FilterByCompany Then // Protection against data errors (duplicate certificates).
				CertificatesPropertiesTable.Delete(String);
			EndIf;
		EndIf;
		
		String = CertificatesPropertiesTable.Find(Selection.Thumbprint, "Thumbprint"); // Rerun the search in case the thumbprint was deleted.
		If String = Undefined Then
			Continue;
		EndIf;
		
		// Keep only certificates avaialble to the user.
		If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
			ModuleAccessManagement = Common.CommonModule("AccessManagement");
			ReadingAllowed = ModuleAccessManagement.ReadingAllowed(CertificateReference, CurrentUser);
		Else
			ReadingAllowed = AccessRight("Read", CertificateReference.Metadata());
		EndIf;
		If ReadingAllowed Then // Protection against data errors (duplicate certificates).
			If AreAvailableOnlyWithKey And CertificateReference.Users.Count() <> 0 Then
				CertificateUserString = CertificateReference.Users.Find(CurrentUser, "User");
				If CertificateUserString <> Undefined
					And CertificateUserString.NoKeyUsed Then
					CertificatesPropertiesTable.Delete(String); // Exclude certificates unavailable for signing and decryption.
					Continue;
				EndIf;
			EndIf;
			String.Presentation = Selection.Presentation;
			String.IsRequest  = Selection.IsRequest;
			String.Isinthedirectory = True;
		Else
			CertificatesPropertiesTable.Delete(String);
		EndIf;
		
	EndDo;
	
EndProcedure

// Intended for: UpdateCertificatesList procedure.
Procedure UpdateValue(PreviousValue2, NewValue, SkipNotDefinedValues = False)
	
	If NewValue = Undefined And SkipNotDefinedValues Then
		Return;
	EndIf;
	
	If PreviousValue2 <> NewValue Then
		PreviousValue2 = NewValue;
	EndIf;
	
EndProcedure

Procedure FillAttribute(SavedProperties, AttributesParameters, AttributeName)
	
	If AttributesParameters.Property(AttributeName) Then
		AttributeParameters =  AttributesParameters[AttributeName]; // Structure
		If AttributeParameters.FillValue <> Undefined Then

			SavedProperties[AttributeName] = AttributeParameters.FillValue;
			
		EndIf;
	EndIf;
	
EndProcedure

// Intended for: SetSigningEncryptionDecryptionForm procedure.
Procedure FillThumbprintsFilter(Form)
	
	Parameters = Form.Parameters;
	
	Filter = New Map;
	
	If TypeOf(Parameters.EncryptionCertificates) = Type("Array") Then
		DetailsList1 = New Map;
		Thumbprints = New Map;
		ThumbprintsPresentations = New Map;
		
		EncryptedObjects = New Array;
		
		For Each LongDesc In Parameters.EncryptionCertificates Do
			If DetailsList1[LongDesc] <> Undefined Then
				Continue;
			EndIf;
			DetailsList1.Insert(LongDesc, True);

			If TypeOf(LongDesc) = Type("String") Then
				Certificates = GetFromTempStorage(LongDesc);
				For Each Properties In Certificates Do
					Value = Thumbprints[Properties.Thumbprint];
					Value = ?(Value = Undefined, 1, Value + 1);
					Thumbprints.Insert(Properties.Thumbprint, Value);
					ThumbprintsPresentations.Insert(Properties.Thumbprint, Properties.Presentation);
				EndDo;
			Else
				EncryptedObjects.Add(LongDesc);
			EndIf;

		EndDo;
		
		If EncryptedObjects.Count() > 0 Then
			Certificates = EncryptionCertificatesFromDetails(EncryptedObjects);
			For Each Properties In Certificates Do
				Value = Thumbprints[Properties.Thumbprint];
				Value = ?(Value = Undefined, 1, Value + 1);
				Thumbprints.Insert(Properties.Thumbprint, Value);
				ThumbprintsPresentations.Insert(Properties.Thumbprint, Properties.Presentation);
			EndDo;
		EndIf;
		
		DataItemsCount = Parameters.EncryptionCertificates.Count();
		For Each KeyAndValue In Thumbprints Do
			If KeyAndValue.Value = DataItemsCount Then
				Filter.Insert(KeyAndValue.Key, ThumbprintsPresentations[KeyAndValue.Key]);
			EndIf;
		EndDo;
		
	ElsIf Parameters.EncryptionCertificates <> Undefined Then
		
		Certificates = EncryptionCertificatesFromDetails(Parameters.EncryptionCertificates);
		For Each Properties In Certificates Do
			Filter.Insert(Properties.Thumbprint, Properties.Presentation);
		EndDo;
	EndIf;
	
	Form.ThumbprintsFilter = PutToTempStorage(Filter, Form.UUID);
	
EndProcedure

// Intended for: FillThumbprintsFilter procedure.
Function EncryptionCertificatesFromDetails(LongDesc)
	
	If TypeOf(LongDesc) = Type("String") Then
		Return GetFromTempStorage(LongDesc);
	EndIf;
	
	Certificates = New Array;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	EncryptionCertificates.Presentation,
		|	EncryptionCertificates.Thumbprint,
		|	EncryptionCertificates.Certificate
		|FROM
		|	InformationRegister.EncryptionCertificates AS EncryptionCertificates
		|WHERE
		|	EncryptionCertificates.EncryptedObject IN (&EncryptedObjects)";
		
	If TypeOf(LongDesc) <> Type("Array") Then
		EncryptedObjects = CommonClientServer.ValueInArray(LongDesc);
	Else
		EncryptedObjects = LongDesc;
	EndIf;
	
	Query.SetParameter("EncryptedObjects", EncryptedObjects);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		CertificateProperties = New Structure("Thumbprint, Presentation, Certificate");
		FillPropertyValues(CertificateProperties, SelectionDetailRecords);
		CertificateProperties.Certificate = CertificateProperties.Certificate.Get();
		Certificates.Add(CertificateProperties);
	EndDo;
	
	Return Certificates;
	
EndFunction

Function RowBinaryData(RowData)
	
	TempFile = GetTempFileName();
	
	TextWriter = New TextWriter(TempFile, TextEncoding.UTF8);
	TextWriter.Write(RowData);
	TextWriter.Close();
	
	CertificateBinaryData = New BinaryData(TempFile);
	
	DeleteFiles(TempFile);
	
	Return CertificateBinaryData;
	
EndFunction

// For the SetSigningEncryptionDecryptionForm and CertificateOnChangeAtServer procedures.

Procedure FillExistingUserCertificates(ChoiceList, CertificatesThumbprintsAtClient,
			CertificatesFilter, ThumbprintsFilter, Details, ExecuteAtServer)
	
	ChoiceList.Clear();
	CurrentSessionDate = ?(Details And ValueIsFilled(ThumbprintsFilter), Undefined, CurrentSessionDate());
	
	If DigitalSignature.GenerateDigitalSignaturesAtServer()
	   And ExecuteAtServer <> False Then
		
		CryptoManager = CryptoManager("GetCertificates");
		
		If CryptoManager <> Undefined Then
			StoreType = CryptoCertificateStoreType.PersonalCertificates;
			
			Try
				CertificatesArray = CryptoManager.GetCertificateStore(StoreType).GetAll();
				DigitalSignatureInternalClientServer.AddCertificatesThumbprints(CertificatesThumbprintsAtClient,
					CertificatesArray, UTCOffset(), CurrentSessionDate);
			Except // ACC:280
				// Do not handle the exception as the error is displayed on the certificate pick form.
			EndTry;
			
		EndIf;
		
	EndIf;
	
	If UseDigitalSignatureSaaS() Then
		ModuleCertificateStore = Common.CommonModule("CertificatesStorage");
		CertificatesArray = ModuleCertificateStore.Get("PersonalCertificates");
		
		DigitalSignatureInternalClientServer.AddCertificatesThumbprints(
			CertificatesThumbprintsAtClient, CertificatesArray, UTCOffset(), CurrentSessionDate);
	EndIf;
	
	If UseCloudSignatureService() Then
	
		DigitalSignatureLocalization.OnFillCloudServiceCertificates(CertificatesThumbprintsAtClient);
	
	EndIf;
	
	FilterByCompany = False;
	
	If TypeOf(CertificatesFilter) = Type("ValueList") Then
		If CertificatesFilter.Count() > 0 Then
			CurrentList = New ValueList;
			For Each ListItem In CertificatesFilter Do
				Properties = Common.ObjectAttributesValues(
					ListItem.Value, "Ref, Description, Thumbprint, User");
				
				If CertificatesThumbprintsAtClient.Find(Properties.Thumbprint) <> Undefined Then
					CurrentList.Add(Properties.Ref, Properties.Description,
						Properties.User = Users.AuthorizedUser());
				EndIf;
			EndDo;
			For Each ListItem In CurrentList Do
				If ListItem.Check Then
					ChoiceList.Add(ListItem.Value, ListItem.Presentation);
				EndIf;
			EndDo;
			For Each ListItem In CurrentList Do
				If Not ListItem.Check Then
					ChoiceList.Add(ListItem.Value, ListItem.Presentation);
				EndIf;
			EndDo;
			Return;
		EndIf;
	ElsIf Metadata.DefinedTypes.Organization.Type.ContainsType(TypeOf(CertificatesFilter)) Then
		FilterByCompany = True;
	EndIf;
	
	If ThumbprintsFilter <> Undefined Then
		Filter = GetFromTempStorage(ThumbprintsFilter);
		For Each Thumbprint In CertificatesThumbprintsAtClient Do
			If Filter[Thumbprint] = Undefined Then
				Continue;
			EndIf;
			ChoiceList.Add(Thumbprint, Filter[Thumbprint]);
		EndDo;
		Query = New Query;
		Query.Parameters.Insert("Thumbprints", ChoiceList.UnloadValues());
		Query.Text =
		"SELECT ALLOWED
		|	Certificates.Ref AS Ref,
		|	Certificates.Description AS Description,
		|	Certificates.Thumbprint
		|FROM
		|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
		|WHERE
		|	Certificates.Thumbprint IN(&Thumbprints)";
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ListItem = ChoiceList.FindByValue(Selection.Thumbprint);
			If ListItem <> Undefined Then
				ListItem.Value = Selection.Ref;
				ListItem.Presentation = Selection.Description;
			EndIf;
		EndDo;
		ChoiceList.SortByPresentation();
		Return;
	EndIf;
	
	QueryText =
	"SELECT ALLOWED
	|	Certificates.Ref AS Ref,
	|	Certificates.User AS User,
	|	Certificates.Description AS Description
	|INTO AllCertificates
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
	|WHERE
	|	Certificates.Revoked = FALSE
	|	AND Certificates.Thumbprint IN(&Thumbprints)
	|	AND &FilterByCompany
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllCertificates.Ref AS Ref,
	|	AllCertificates.Description AS Description
	|FROM
	|	AllCertificates AS AllCertificates
	|WHERE
	|	AllCertificates.Ref IN
	|			(SELECT
	|				AllCertificates.Ref AS Ref
	|			FROM
	|				AllCertificates AS AllCertificates
	|			WHERE
	|				AllCertificates.User = &User
	|		
	|			UNION ALL
	|		
	|			SELECT
	|				AllCertificates.Ref
	|			FROM
	|				AllCertificates AS AllCertificates
	|					INNER JOIN Catalog.DigitalSignatureAndEncryptionKeysCertificates.Users AS ElectronicSignatureAndEncryptionKeyCertificatesUsers
	|					ON
	|						AllCertificates.Ref = ElectronicSignatureAndEncryptionKeyCertificatesUsers.Ref
	|			WHERE
	|				ElectronicSignatureAndEncryptionKeyCertificatesUsers.User = &User
	|				AND &FilterNoKeyUsed)";
		
	QueryText = ?(FilterByCompany,
		StrReplace(QueryText, "&FilterByCompany", "Certificates.Organization = &Organization"),
		StrReplace(QueryText, "&FilterByCompany", "TRUE"));
	
	QueryText = ?(Users.IsFullUser(),
		StrReplace(QueryText, "&FilterNoKeyUsed", "TRUE"),
		StrReplace(QueryText, "&FilterNoKeyUsed", "ElectronicSignatureAndEncryptionKeyCertificatesUsers.NoKeyUsed = FALSE"));
	
	Query = New Query(QueryText);
	Query.SetParameter("User", Users.CurrentUser());
	Query.SetParameter("Thumbprints", CertificatesThumbprintsAtClient);
		Query.SetParameter("Organization", CertificatesFilter);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ChoiceList.Add(Selection.Ref, Selection.Description);
	EndDo;
	
EndProcedure

Function CertificateThumbprintsInStore(CryptoManager, StoreType, Error)
	
	Result = New Array;
	Try
		CertificatesArray = CryptoManager.GetCertificateStore(StoreType).GetAll();
	Except
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		If TypeOf(Error) = Type("Structure") Then
			Error = DigitalSignatureInternalClientServer.NewErrorsDescription(ComputerName());
			Error.ErrorDescription = ErrorDescription;
		Else
			Error = ErrorDescription;
		EndIf;
		Return Result;
	EndTry;

	For Each Certificate In CertificatesArray Do
		Result.Add(Base64String(Certificate.Thumbprint));
	EndDo;
	
	Return Result;
	
EndFunction

Procedure FillCertificateAdditionalProperties(Form)
	
	If Not ValueIsFilled(Form.Certificate) Then
		Return;
	EndIf;
	
	AttributesValues = Common.ObjectAttributesValues(Form.Certificate,
		"EnterPasswordInDigitalSignatureApplication, Thumbprint, Application,
		|ValidBefore, CertificateData, Revoked");
	
	Try
		CertificateBinaryData = AttributesValues.CertificateData.Get();
		Certificate = New CryptoCertificate(CertificateBinaryData);
	Except
		ErrorInfo = ErrorInfo();
		Certificate = Form.Certificate;
		Form.Certificate = Undefined;
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận dữ liệu chứng thư ""%1""
			           |do nguyên nhân:
			           |%2';
			           |ru = 'Не удалось получить данные сертификата ""%1""
			           |по причине:
			           |%2';
			           |en = 'Cannot receive the ""%1"" certificate data
			           |due to:
			           |%2'; fa = 'Cannot receive the ""%1"" certificate data
			           |due to:
			           |%2';
			           |it = 'Не удалось получить данные сертификата ""%1""
			           |по причине:
			           |%2';
			           |pl = 'Cannot receive the ""%1"" certificate data
			           |due to:
			           |%2';
			           |tr = '""%1"" sertifikası verileri
			           |şu sebeple alınamadı:
			           |%2'"),
			Certificate,
			ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;
	
	IsBuiltInCryptoProvider = AttributesValues.Application = BuiltinCryptoprovider();
	
	If Form.NoConfirmation
	   And IsBuiltInCryptoProvider Then
		
		Properties = New Structure("CloudPasswordConfirmed",
			CloudPasswordConfirmed(CertificateBinaryData));
		
		FillPropertyValues(Form, Properties);
	EndIf;
	
	Form.AddressOfCertificate = PutToTempStorage(CertificateBinaryData, Form.UUID);
	
	Form.ThumbprintOfCertificate      = AttributesValues.Thumbprint;
	Form.CertificateApp      = AttributesValues.Application;
	Form.ExecuteInSaaS  = IsBuiltInCryptoProvider;
	Form.CertificateExpiresOn = AttributesValues.ValidBefore;
	If CommonClientServer.HasAttributeOrObjectProperty(Form, "CertificateRevoked") Then
		Form.CertificateRevoked        = AttributesValues.Revoked;
	EndIf;
	Form.CertificateEnterPasswordInElectronicSignatureProgram = AttributesValues.EnterPasswordInDigitalSignatureApplication;
	
	If CommonClientServer.HasAttributeOrObjectProperty(Form, "CertificationAuthorityAuditResult") Then
		CheckParameters = Undefined;
		If CommonClientServer.HasAttributeOrObjectProperty(Form, "VerifyCertificate") Then
			CheckParameters = New Structure;
			CheckParameters.Insert("ThisVerificationSignature", False);
			CheckParameters.Insert("VerifyCertificate", Form.VerifyCertificate);
		EndIf;
		Form.CertificationAuthorityAuditResult = ResultofCertificateAuthorityVerification(Certificate,,CheckParameters);
	EndIf;
	
	IsParameterNotifyOnExpirationofValidity = Form.Parameters.Property("NotifyOfCertificateAboutToExpire");
	If IsParameterNotifyOnExpirationofValidity And Form.Parameters.NotifyOfCertificateAboutToExpire 
		Or Not IsParameterNotifyOnExpirationofValidity Then
			
		If CommonClientServer.HasAttributeOrObjectProperty(Form, "CertificationAuthorityAuditResult")
			And Form.CertificationAuthorityAuditResult <> Undefined
			And Form.CertificationAuthorityAuditResult.Valid
			And (ValueIsFilled(Form.CertificationAuthorityAuditResult.Warning.ErrorText) 
			Or ValueIsFilled(Form.CertificationAuthorityAuditResult.Warning.AdditionalInfo)) Then
			Form.NotifyOfCertificateAboutToExpire = Not InformationRegisters.CertificateUsersNotifications.UserAlerted(Form.Certificate)
				And Not CertificateReissued(Form.Certificate);
		Else
			Form.NotifyOfCertificateAboutToExpire = 
				Form.CertificateExpiresOn <= CurrentUniversalDate() + NumberofDaysforEndofTermAlert()*24*60*60
				And Not InformationRegisters.CertificateUsersNotifications.UserAlerted(Form.Certificate)
				And Not CertificateReissued(Form.Certificate);
		EndIf;
		
	EndIf;
	
	Form.CertificateAtServerErrorDescription = New Structure;
	
	If Not DigitalSignature.GenerateDigitalSignaturesAtServer() Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Form.CertificateApp) Then
		CertificateApplicationResult = AppForCertificate(Form.AddressOfCertificate);
		If CertificateApplicationResult.Application = Undefined Then
			ErrorText = DigitalSignatureInternalClientServer.ErrorTextFailedToDefineApp(
				CertificateApplicationResult.Error);
			Form.CertificateAtServerErrorDescription.Insert("ErrorDescription", ErrorText);
			Return;
		ElsIf CommonClientServer.HasAttributeOrObjectProperty(Form, "AppAutoAtServer") Then
			Form.AppAutoAtServer = CertificateApplicationResult.Application;
		EndIf;
		Application = CertificateApplicationResult.Application;
	Else
		Application = Form.CertificateApp;
	EndIf;
	
	GetCertificateByThumbprint(Form.ThumbprintOfCertificate,
		True, False, Application, Form.CertificateAtServerErrorDescription);
	
EndProcedure

Function NumberofDaysforEndofTermAlert()
	Return 30;
EndFunction

// For the CryptoManager function.
Function NewCryptoManager(Application, Errors, AdditionalParameters)
	
	AppsAuto		= Undefined;
	Operation			= AdditionalParameters.Operation;
	AutoDetect		= AdditionalParameters.AutoDetect;
	SignAlgorithm		= AdditionalParameters.SignAlgorithm;
	EncryptAlgorithm	= AdditionalParameters.EncryptAlgorithm;
	
	If TypeOf(Application) = Type("String") Or TypeOf(Application) = Type("BinaryData") Then
		
		ErrorDescription = "";
		IsPrivateKeyRequied = Operation = "Signing"
			Or Operation = "Details";
		PopulateParametersForCreatingCryptoManager(Application, SignAlgorithm, ErrorDescription, IsPrivateKeyRequied);
		
		If ValueIsFilled(ErrorDescription) Then
			ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
			ErrorProperties.LongDesc = ErrorDescription;
			Errors.Add(ErrorProperties);
			
			If Application = Undefined And IsPrivateKeyRequied Then
				Return Undefined;
			EndIf;
		EndIf;
		
	EndIf;
	
	If AutoDetect And TypeOf(Application) <> Type("Structure") And TypeOf(Application) <> Type("FixedStructure") Then
		
		CryptoProvidersResult = DigitalSignatureInternalCached.InstalledCryptoProviders();
		AppsAuto = DigitalSignatureInternalClientServer.CryptoProvidersSearchResult(
			CryptoProvidersResult, ComputerName());
		
		If TypeOf(AppsAuto) = Type("String") Then
			ErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
			ErrorProperties.LongDesc = AppsAuto;
			Errors.Add(ErrorProperties);
			AppsAuto = Undefined;
		EndIf;
	
	EndIf;
	
	ApplicationsDetailsCollection = DigitalSignatureInternalClientServer.CryptoManagerApplicationsDetails(
		Application, Errors, DigitalSignature.CommonSettings().ApplicationsDetailsCollection, AppsAuto);
	
	If ApplicationsDetailsCollection = Undefined Then
		Return Undefined;
	EndIf;
	
	IsLinux = RequiresThePathToTheProgram();
	
	Manager = Undefined;
	For Each ApplicationDetails In ApplicationsDetailsCollection Do
		
		If ValueIsFilled(SignAlgorithm) Then
			SignAlgorithmSupported =
				DigitalSignatureInternalClientServer.CryptoManagerSignAlgorithmSupported(ApplicationDetails,
					Operation, SignAlgorithm, Errors, True, Application <> Undefined);
			
			If Not SignAlgorithmSupported Then
				Manager = Undefined;
				Continue;
			EndIf;
		EndIf;
		
		If ApplicationDetails.Property("AutoDetect") Then
			
			ApplicationProperties1 = New Structure;
			ApplicationProperties1.Insert("ApplicationName",   ApplicationDetails.ApplicationName);
			ApplicationProperties1.Insert("ApplicationPath", ApplicationDetails.AppPathAtServerAuto);
			ApplicationProperties1.Insert("ApplicationType",   ApplicationDetails.ApplicationType);
			
		Else

			IDOfTheProgramPath = ?(ValueIsFilled(ApplicationDetails.Ref),
				ApplicationDetails.Ref, ApplicationDetails.Id);
		
			ApplicationProperties1 = DigitalSignatureInternalClientServer.CryptoManagerApplicationProperties(
				ApplicationDetails, IsLinux, Errors, True, ApplicationPath(IDOfTheProgramPath));

		EndIf;
		
		If ApplicationProperties1 = Undefined Then
			Continue;
		EndIf;
		
		Try
			ModuleInfo = CryptoTools.GetCryptoModuleInformation(
				ApplicationProperties1.ApplicationName,
				ApplicationProperties1.ApplicationPath,
				ApplicationProperties1.ApplicationType);
		Except
			DigitalSignatureInternalClientServer.CryptoManagerAddError(Errors,
				ApplicationDetails.Ref, ErrorProcessing.BriefErrorDescription(ErrorInfo()),
				True, True, True);
			Continue;
		EndTry;
		
		If ModuleInfo = Undefined Then
			DigitalSignatureInternalClientServer.CryptoManagerApplicationNotFound(
				ApplicationDetails, Errors, True);
			
			Manager = Undefined;
			Continue;
		EndIf;
		
		If Not IsLinux Then
			ApplicationNameReceived = ModuleInfo.Name;
			
			ApplicationNameMatches = DigitalSignatureInternalClientServer.CryptoManagerApplicationNameMaps(
				ApplicationDetails, ApplicationNameReceived, Errors, True);
			
			If Not ApplicationNameMatches Then
				Manager = Undefined;
				Continue;
			EndIf;
		EndIf;
		
		Try
			Manager = New CryptoManager(
				ApplicationProperties1.ApplicationName,
				ApplicationProperties1.ApplicationPath,
				ApplicationProperties1.ApplicationType);
		Except
			DigitalSignatureInternalClientServer.CryptoManagerAddError(Errors,
				ApplicationDetails.Ref, ErrorProcessing.BriefErrorDescription(ErrorInfo()),
				True, True, True);
			Continue;
		EndTry;
		
		AlgorithmsSet = DigitalSignatureInternalClientServer.CryptoManagerAlgorithmsSet(
			ApplicationDetails, Manager, Errors, EncryptAlgorithm);
		
		If Not AlgorithmsSet Then
			Continue;
		EndIf;
		
		Break; // The required crypto manager is received.
	EndDo;
	
	Return Manager;
	
EndFunction

// For the NewCryptoManager function.
Procedure PopulateParametersForCreatingCryptoManager(Application, SignAlgorithm, ErrorDescription, IsPrivateKeyRequied)
	
	Data = Application;
	
	Try
		
		DataType = DigitalSignatureInternalClientServer.DefineDataType(Data);
		
	Except
		
		Application = Undefined;
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xác định ứng dụng chữ ký điện tử và mã hóa đối với dữ liệu được chuyển: %1';
				|ru = 'Не удалось определить приложение электронной подписи и шифрования для переданных данных: %1';
				|en = 'Couldn''t determine digital signing and encryption app for the passed data: %1'; fa = 'Couldn''t determine digital signing and encryption app for the passed data: %1';
				|it = 'Не удалось определить приложение электронной подписи и шифрования для переданных данных: %1';
				|pl = 'Couldn''t determine digital signing and encryption app for the passed data: %1';
				|tr = 'Aktarılan verilere ilişkin elektronik imza ve şifreleme uygulaması belirlenememiştir: %1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	If DataType = "Certificate" Then
		
		CertificateApplicationResult = AppForCertificate(Data, IsPrivateKeyRequied);
		If ValueIsFilled(CertificateApplicationResult.Error) Then
			
			ErrorDescription = DigitalSignatureInternalClientServer.ErrorTextFailedToDefineApp(
				CertificateApplicationResult.Error);
			SignAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(Data);
			Application = Undefined;
			
		Else
			Application = CertificateApplicationResult.Application;
		EndIf;
		
		Return;
		
	ElsIf DataType = "Signature" Then
		
		Application = Undefined;
		SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(Data);
		Return;
		
	ElsIf DataType = "EncryptedData" Then
		
		Application = Undefined;
		ErrorDescription = NStr("vi = 'Để xác định ứng dụng giải mã, cần truyền dữ liệu chứng thư vào thủ tục.';
								|ru = 'Для определения приложения для расшифровки в процедуру должны быть переданы данные сертификата.';
								|en = 'To determine a decryption app, pass the certificate data to the procedure.'; fa = 'To determine a decryption app, pass the certificate data to the procedure.';
								|it = 'Для определения приложения для расшифровки в процедуру должны быть переданы данные сертификата.';
								|pl = 'To determine a decryption app, pass the certificate data to the procedure.';
								|tr = 'Şifreleme uygulamasını tespit etmek için veriler sertifikası prosedüre aktarılmış olmalıdır.'");
		Return;
		
	EndIf;
	
	Application = Undefined;
	ErrorDescription = NStr("vi = 'Không thể xác định ứng dụng chữ ký điện tử và mã hóa đối với dữ liệu được chuyển.';
							|ru = 'Не удалось определить приложение электронной подписи и шифрования для переданных данных.';
							|en = 'Couldn''t determine digital signing and encryption app for the passed data.'; fa = 'Couldn''t determine digital signing and encryption app for the passed data.';
							|it = 'Не удалось определить приложение электронной подписи и шифрования для переданных данных.';
							|pl = 'Couldn''t determine digital signing and encryption app for the passed data.';
							|tr = 'Aktarılan verilere ilişkin elektronik imza ve şifreleme uygulaması belirlenememiştir.'");
	
EndProcedure

Function AppForCertificate(Val Certificate, IsPrivateKeyRequied = Undefined,  ComponentObject = Undefined) Export

	Result = New Structure("Application, Error");

	Certificate = CertificateBase64String(Certificate);

	If ComponentObject = Undefined Then
		Try
			ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
		Except
			Result.Error = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể kết nối cấu phần %1 trên máy chủ %2.';
					|ru = 'Не удалось подключить компоненту %1 на сервере %2.';
					|en = 'Cannot attach the %1 add-in on the %2 server.'; fa = 'Cannot attach the %1 add-in on the %2 server.';
					|it = 'Не удалось подключить компоненту %1 на сервере %2.';
					|pl = 'Cannot attach the %1 add-in on the %2 server.';
					|tr = '%2 sunucusundaki %1 bileşenine bağlanılamadı.'"), "ExtraCryptoAPI", ComputerName());
			Return Result;
		EndTry;
	EndIf;
	
	If IsPrivateKeyRequied <> False Then
		
		Try
			CryptoProviderProperties = ComponentObject.GetCryptoProviderProperties(Certificate);
			CurCryptoProvider = DigitalSignatureInternalServerCall.ReadAddInResponce(
				CryptoProviderProperties);
		Except
			Result.Error = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			Return Result;
		EndTry;
		
		ApplicationsByNamesWithType = DigitalSignature.CommonSettings().ApplicationsByNamesWithType;
		ExtendedApplicationDetails = DigitalSignatureInternalClientServer.ExtendedApplicationDetails(
			CurCryptoProvider, ApplicationsByNamesWithType);
		
		If ExtendedApplicationDetails <> Undefined Then
			Result.Application = ExtendedApplicationDetails;
			Return Result;
		ElsIf IsPrivateKeyRequied = True And CurCryptoProvider.Get("type") <> 0 Then
			Result.Error = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chứng thư liên quan đến ứng dụng %1 có kiểu %2 trên server %3, hãy tùy chỉnh ứng dụng để sử dụng và chọn vào chứng thư.';
					|ru = 'Сертификат связан с приложением %1 с типом %2 на сервере %3, настройте его для использования и выберите в сертификате.';
					|en = 'The certificate is connected to the app %1 (of ""%2"" type) on the server %3. Configure the app and select it in the certificate.'; fa = 'The certificate is connected to the app %1 (of ""%2"" type) on the server %3. Configure the app and select it in the certificate.';
					|it = 'Сертификат связан с приложением %1 с типом %2 на сервере %3, настройте его для использования и выберите в сертификате.';
					|pl = 'The certificate is connected to the app %1 (of ""%2"" type) on the server %3. Configure the app and select it in the certificate.';
					|tr = 'Sertifika, %3 sunucusundaki %2 türündeki %1 uygulamasına bağlandı, kullanıcılar için ayarlayın ve sertifikayı seçin.'"),
				CurCryptoProvider.Get("name"),
				CurCryptoProvider.Get("type"), ComputerName());
			Return Result;
		EndIf;
		
	EndIf;
	
	If IsPrivateKeyRequied = True Then
		Result.Error = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xác định ứng dụng bằng khóa riêng của chứng thư trên server %1.';
				|ru = 'Не удалось определить приложение по закрытому ключу сертификата на сервере %1.';
				|en = 'Couldn''t determine app by the private key on the server %1.'; fa = 'Couldn''t determine app by the private key on the server %1.';
				|it = 'Не удалось определить приложение по закрытому ключу сертификата на сервере %1.';
				|pl = 'Couldn''t determine app by the private key on the server %1.';
				|tr = 'Uygulama %1 sunucusundaki açılan sertifika anahtarına göre tespit edilemedi.'"), ComputerName());
		Return Result;
	EndIf;
		
	CertificatePropertiesExtended = CertificatePropertiesExtended(Certificate, ComponentObject);
	ResultCryptoProviders = DigitalSignatureInternalCached.InstalledCryptoProviders();
	
	If ResultCryptoProviders.CheckCompleted Then
		
		Error = "";
		
		Result.Application = DigitalSignatureInternalClientServer.DefineApp(
			CertificatePropertiesExtended.CertificateProperties, ResultCryptoProviders.Cryptoproviders,
			DigitalSignature.CommonSettings().ApplicationsByPublicKeyAlgorithmsIDs, Error);
	
		If Result.Application = Undefined Then
			Result.Error = Error;
		EndIf;
	
		Return Result;
	Else
		Result.Error = ResultCryptoProviders.Error;
		Return Result;
	EndIf;
	
EndFunction

Function UseDigitalSignatureSaaS() Export
	
	If Not Common.SubsystemExists("CloudTechnology.DigitalSignatureSaaS") Then
		Return False;
	EndIf;
	
	ModuleDigitalSignatureSaaS =
		Common.CommonModule("DigitalSignatureSaaS");
	
	Return ModuleDigitalSignatureSaaS.UsageAllowed() And Common.DataSeparationEnabled();
	
EndFunction

Function ApplicationPath(ProgramLink)
	
	Result = New Structure("ApplicationPath, Exists, ErrorText", "", False, "");
	
	If Not RequiresThePathToTheProgram() Then
		Return Result;
	EndIf;
	
	ApplicationsPaths = DigitalSignatureInternalCached.ApplicationsPathsAtLinuxServers(ComputerName());
	DescriptionOfWay = ApplicationsPaths.Get(ProgramLink);
	
	If DescriptionOfWay <> Undefined Then
		Result = DescriptionOfWay;
	EndIf;
	
	Return Result;
	
EndFunction

// For the GetFilesAndSignaturesMap function.
Function FindSignatureFilesNames(DataFileName, SignatureFilesNames)
	
	SignatureNames = New Array;
	
	NameStructure = CommonClientServer.ParseFullFileName(DataFileName);
	BaseName = NameStructure.BaseName;
	
	For Each SignatureFileName In SignatureFilesNames Do
		If StrFind(SignatureFileName, BaseName) > 0 Then
			SignatureNames.Add(SignatureFileName);
		EndIf;
	EndDo;
	
	For Each SignatureFileName In SignatureNames Do
		SignatureFilesNames.Delete(SignatureFilesNames.Find(SignatureFileName));
	EndDo;
	
	Return SignatureNames;
	
EndFunction

// Used in WriteCertificateAfterCheck().
Function CheckEncryptionAndDecryption(CryptoManager, CertificateBinaryData,
			CryptoCertificate, ApplicationDetails, ErrorAtServer, IsFullUser)
	
	ErrorPresentation = "";
	Try
		EncryptedData = CryptoManager.Encrypt(CertificateBinaryData, CryptoCertificate);
	Except
		ErrorInfo = ErrorInfo();
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;
	
	If ValueIsFilled(ErrorPresentation) Then
		DigitalSignatureInternalClientServer.FillErrorAddingCertificate(
			ErrorAtServer,
			ApplicationDetails,
			"Encryption",
			ErrorPresentation,
			IsFullUser,
			False,
			ComputerName());
		
		Return False;
	EndIf;
	
	ErrorInfo = Undefined;
	ErrorPresentation = "";
	Try
		DecryptedData = CryptoManager.Decrypt(EncryptedData);
		DigitalSignatureInternalClientServer.BlankDecryptedData(DecryptedData, ErrorPresentation);
	Except
		ErrorInfo = ErrorInfo();
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;
	
	If ValueIsFilled(ErrorPresentation) Then
		DigitalSignatureInternalClientServer.FillErrorAddingCertificate(
			ErrorAtServer,
			ApplicationDetails,
			"Details",
			ErrorPresentation,
			IsFullUser,
			ErrorInfo = Undefined,
			ComputerName());
		
		Return False;
	EndIf;
		
	Return True;
	
EndFunction

Function CheckSigning(CryptoManager, CertificateBinaryData,
			CryptoCertificate, ApplicationDetails, ErrorAtServer, IsFullUser)
	
	ErrorInfo = Undefined;
	ErrorPresentation = "";
	Try
		SignatureData = CryptoManager.Sign(CertificateBinaryData, CryptoCertificate);
		DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorPresentation);
	Except
		ErrorInfo = ErrorInfo();
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;
	
	If ValueIsFilled(ErrorPresentation) Then
		DigitalSignatureInternalClientServer.FillErrorAddingCertificate(
			ErrorAtServer,
			ApplicationDetails,
			"Signing",
			ErrorPresentation,
			IsFullUser,
			ErrorInfo = Undefined,
			ComputerName());
		
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Returns:
//   ValueTable:
//     * SignAlgorithms     - Array
//     * HashAlgorithms - Array
//     * EncryptAlgorithms  - Array
//     * SignatureVerificationAlgorithms - Array
//     * NotInWindows - Boolean
//     * NotOnLinux   - Boolean
//     * NotInMacOS   - Boolean
//
Function ApplicationsSettingsToSupply() Export
	
	Settings = New ValueTable;
	Settings.Columns.Add("Presentation");
	Settings.Columns.Add("ApplicationName");
	Settings.Columns.Add("ApplicationType");
	Settings.Columns.Add("SignAlgorithm");
	Settings.Columns.Add("HashAlgorithm");
	Settings.Columns.Add("EncryptAlgorithm");
	Settings.Columns.Add("Id");
	
	Settings.Columns.Add("SignAlgorithms",     New TypeDescription("Array"));
	Settings.Columns.Add("HashAlgorithms", New TypeDescription("Array"));
	Settings.Columns.Add("EncryptAlgorithms",  New TypeDescription("Array"));
	Settings.Columns.Add("SignatureVerificationAlgorithms", New TypeDescription("Array"));
	Settings.Columns.Add("NotInWindows", New TypeDescription("Boolean"));
	Settings.Columns.Add("NotOnLinux",   New TypeDescription("Boolean"));
	Settings.Columns.Add("NotInMacOS",   New TypeDescription("Boolean"));
	Settings.Columns.Add("Irrelevant", New TypeDescription("Boolean"));
	
	Return Settings;
	
EndFunction

// Returns:
//   Structure:
//     * Key - String - Prefix of the app ID. For example "CryptoPro".
//     * Value - FixedMap of KeyAndValue:
//         * Key - PlatformType
//         * Value - FixedArray of String - the paths
//             with module names separated by colon.
//
Function SupplyThePathToTheProgramModules() Export
	
	Return New Structure;
	
EndFunction

// Runs during update to SSL v.3.1.5.220 and initial data population.
// 
Procedure FillinSettingsToImproveSignatures() Export
	
	ValueManager = Constants.CryptoSignatureTypeDefault.CreateValueManager();
	ValueManager.Value = Enums.CryptographySignatureTypes.BasicCAdESBES;
	InfobaseUpdate.WriteData(ValueManager);

	FillinServerAddressesTimestamps();
	
EndProcedure

// Runs during update to SSL v.3.1.6.180 
// and when called from the FillinSettingsToImproveSignatures procedure.
// 
Procedure FillinServerAddressesTimestamps() Export
	
	TimestampServersAddresses = "";
	DigitalSignatureLocalization.OnGetTimestampServerAddresses(TimestampServersAddresses);
	
	If Not IsBlankString(TimestampServersAddresses) Then
		ValueManager = Constants.TimestampServersAddresses.CreateValueManager();
		ValueManager.Value = TimestampServersAddresses;
		InfobaseUpdate.WriteData(ValueManager);
	EndIf;
	
EndProcedure

// Runs during the update to SSL v.3.1.11.61. 
Procedure EnableConstantAllowAccessToInternetServices() Export
	
	Constants.AllowAccessToDigitalSignatureInternetServices.Set(True);
	
EndProcedure

Function CertificateReissued(Certificate)
	
	If DigitalSignature.CommonSettings().CertificateIssueRequestAvailable Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		IssuedCertificates = ProcessingApplicationForNewQualifiedCertificateIssue.IssuedCertificates(Certificate);
		If IssuedCertificates.Count() > 0 Then
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

Function NumberofCertificatesWithexpiringValidity()

	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	DigitalSignatureAndEncryptionKeysCertificates.Ref AS Ref
	|INTO UserCertificates
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS DigitalSignatureAndEncryptionKeysCertificates
	|WHERE
	|	DigitalSignatureAndEncryptionKeysCertificates.User = &User
	|
	|UNION ALL
	|
	|SELECT
	|	ElectronicSignatureAndEncryptionKeyCertificatesUsers.Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates.Users AS ElectronicSignatureAndEncryptionKeyCertificatesUsers
	|WHERE
	|	ElectronicSignatureAndEncryptionKeyCertificatesUsers.User = &User
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	COUNT(DISTINCT DigitalSignatureAndEncryptionKeysCertificates.Ref) AS Count
	|FROM
	|	UserCertificates AS UserCertificates
	|		INNER JOIN Catalog.DigitalSignatureAndEncryptionKeysCertificates AS DigitalSignatureAndEncryptionKeysCertificates
	|		ON UserCertificates.Ref = DigitalSignatureAndEncryptionKeysCertificates.Ref
	|WHERE
	|	NOT DigitalSignatureAndEncryptionKeysCertificates.DeletionMark
	|	AND DigitalSignatureAndEncryptionKeysCertificates.ValidBefore >= &CurrentDate
	|	AND DigitalSignatureAndEncryptionKeysCertificates.ValidBefore <= &Date
	|	AND NOT DigitalSignatureAndEncryptionKeysCertificates.Revoked
	|	AND &AdditionalCondition";

	CurrentDate = CurrentUniversalDate();
	Query.SetParameter("CurrentDate", CurrentDate);
	Query.SetParameter("Date", CurrentDate + 30*24*60*60);
	Query.SetParameter("User", Users.CurrentUser());
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.AddRequestToReceiveNumberOfCertificatesWithExpiringValidity(Query);
	Else
		Query.Text = StrReplace(Query.Text, "AND &AdditionalCondition", "");
	EndIf;
	
	Return Query.Execute().Unload()[0].Count;
	
EndFunction

Function NumberofApplicationsInProgress()
	
	ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
				
	Return ProcessingApplicationForNewQualifiedCertificateIssue.NumberofApplicationsInProgress();
	
EndFunction

Function SignaturesCount(Parameter) Export
	
	QueryOptions = New Structure;
	QueryOptions.Insert(Parameter, True);
	QueryOptions.Insert("OnlyQuantity", True);
	
	Query = RequestForExtensionSignatureCredibility(QueryOptions);
		
	If Query = Undefined Then
		Return 0;
	EndIf;
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	Return QueryResult.Unload()[0].Count;
	
EndFunction

Function RequestForExtensionSignatureCredibility(Parameters) Export
	
	QueryOptions = New Structure;
	QueryOptions.Insert("RequireImprovementSignatures", False);
	QueryOptions.Insert("RequiredAddArchiveTags", False);
	QueryOptions.Insert("rawsignatures", False);
	QueryOptions.Insert("ErrorsOnAutoRenewal", False);
	QueryOptions.Insert("OnlyQuantity", False);
	QueryOptions.Insert("RefineToType", Undefined);
	QueryOptions.Insert("ScheduledJob", False);
	
	FillPropertyValues(QueryOptions, Parameters);
	
	Query = New Query;
	QueryText = "";
	
	RefineSignaturesDates = Constants.RefineSignaturesDates.Get();
	
	If QueryOptions.RequireImprovementSignatures Then
		
		QueryText =
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	DigitalSignatures.SignatureType IN(&SignatureType)
		|	AND DigitalSignatures.SignatureCorrect
		|	AND NOT DigitalSignatures.IsErrorOccurredDuringAutomaticRenewal
		|	AND NOT DigitalSignatures.SkipUponRenewal
		|	AND (DigitalSignatures.DateActionLastTimestamp = DATETIME(1, 1, 1)
		|			OR DigitalSignatures.DateActionLastTimestamp > &CurrentSessionDate)
		|	AND DigitalSignatures.SignatureDate >= &RefineSignaturesDates";

		Query.SetParameter("CurrentSessionDate", CurrentSessionDate());
		Query.SetParameter("RefineSignaturesDates", RefineSignaturesDates);
		
		RefineToType = QueryOptions.RefineToType;
		If RefineToType = Undefined Then
			RefineToType = Constants.CryptoSignatureTypeDefault.Get();
		EndIf;
		
		SignatureType = New Array;
		If RefineToType = Enums.CryptographySignatureTypes.WithTimeCAdEST Then
			SignatureType.Add(Enums.CryptographySignatureTypes.BasicCAdESBES);
		ElsIf RefineToType = Enums.CryptographySignatureTypes.ArchivalCAdESAv3 Then
			SignatureType.Add(Enums.CryptographySignatureTypes.BasicCAdESBES);
			SignatureType.Add(Enums.CryptographySignatureTypes.WithTimeCAdEST);
			SignatureType.Add(Enums.CryptographySignatureTypes.WithCompleteValidationDataReferencesCAdESC);
			SignatureType.Add(Enums.CryptographySignatureTypes.CAdESXType1);
			SignatureType.Add(Enums.CryptographySignatureTypes.CAdESXType2);
			SignatureType.Add(Enums.CryptographySignatureTypes.CAdESXLong);
			SignatureType.Add(Enums.CryptographySignatureTypes.CAdESXLongType1);
			SignatureType.Add(Enums.CryptographySignatureTypes.ExtendedLongCAdESXLongType2);
		Else
			QueryText = "";
		EndIf;
		Query.SetParameter("SignatureType", SignatureType);
		
	EndIf;
	
	If QueryOptions.RequiredAddArchiveTags Then
	
		QueryText = ?(QueryText = "", "", QueryText + "
		|
		|UNION ALL
		|
		|")
		+
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	DigitalSignatures.SignatureType = VALUE(Enum.CryptographySignatureTypes.ArchivalCAdESAv3)
		|	AND DigitalSignatures.DateActionLastTimestamp <= &Date
		|	AND NOT DigitalSignatures.IsErrorOccurredDuringAutomaticRenewal
		|	AND NOT DigitalSignatures.SkipUponRenewal
		|	AND DigitalSignatures.SignatureCorrect
		|
		|UNION ALL
		|
		|SELECT
		|	COUNT(*)
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	DigitalSignatures.SignatureType = VALUE(Enum.CryptographySignatureTypes.CAdESAv2)
		|	AND DigitalSignatures.DateActionLastTimestamp <= &Date
		|	AND NOT DigitalSignatures.IsErrorOccurredDuringAutomaticRenewal
		|	AND NOT DigitalSignatures.SkipUponRenewal
		|	AND DigitalSignatures.SignatureCorrect";
		
		Query.SetParameter("Date", AddMonth(CurrentSessionDate(), 1));
		
	EndIf; 
	
	If QueryOptions.rawsignatures Then
		
		QueryText = ?(QueryText = "", "", QueryText + "
		|
		|UNION ALL
		|
		|")
		+
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	DigitalSignatures.SignatureType = VALUE(Enum.CryptographySignatureTypes.EmptyRef)
		|	AND DigitalSignatures.SignatureCorrect
		|	AND NOT DigitalSignatures.IsErrorOccurredDuringAutomaticRenewal
		|	AND NOT DigitalSignatures.SkipUponRenewal
		|	AND (DigitalSignatures.DateActionLastTimestamp = DATETIME(1, 1, 1)
		|			OR DigitalSignatures.DateActionLastTimestamp > &CurrentSessionDate)
		|	AND DigitalSignatures.SignatureDate >= &RefineSignaturesDates";
		
		Query.SetParameter("CurrentSessionDate", CurrentSessionDate());
		Query.SetParameter("RefineSignaturesDates", RefineSignaturesDates);
		
	EndIf;
	
	If QueryOptions.ErrorsOnAutoRenewal Then
		
		QueryText = ?(QueryText = "", "", QueryText + "
		|
		|UNION ALL
		|
		|")
		+
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	DigitalSignatures.IsErrorOccurredDuringAutomaticRenewal";
		
	EndIf;
	
	If IsBlankString(QueryText) Then
		QueryText = 
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	InformationRegister.DigitalSignatures AS DigitalSignatures
		|WHERE
		|	FALSE"
	EndIf;
	
	If Not QueryOptions.OnlyQuantity Then
		
		SearchString = "COUNT(*) AS Count";
		ReplacementString = "DigitalSignatures.SignedObject AS SignedObject,
		|	DigitalSignatures.SequenceNumber AS SequenceNumber,
		|	DigitalSignatures.SignatureDate AS SignatureDate,
		|	DigitalSignatures.CertificateOwner AS CertificateOwner,
		|	DigitalSignatures.SignatureType AS SignatureType,
		|	DigitalSignatures.IsErrorOccurredDuringAutomaticRenewal AS IsErrorOccurredDuringAutomaticRenewal,
		|	DigitalSignatures.DateActionLastTimestamp AS DateActionLastTimestamp";
		
		If QueryOptions.ScheduledJob Then
			ReplacementString = ReplacementString +",
			|	DigitalSignatures.Signature AS Signature";
		EndIf;
		
		QueryText = StrReplace(QueryText, SearchString, ReplacementString);
		
		SearchString = "COUNT(*)";
		QueryText = StrReplace(QueryText, SearchString, ReplacementString);
		
		If QueryOptions.ScheduledJob Then
			QueryText = QueryText + "
						|ORDER BY
						|	SignatureDate
						|";
		EndIf;

	EndIf;
	
	If QueryOptions.ScheduledJob Then
		QueryText = StrReplace(QueryText, "SELECT", "SELECT TOP 1000"); // @query-part-1, @query-part-2
	Else
		QueryText = StrReplace(QueryText, "AND NOT DigitalSignatures.IsErrorOccurredDuringAutomaticRenewal", "");
	EndIf;
	
	Query.Text = QueryText;
	
	Return Query;
	
EndFunction

// Looks up for individuals by description.
// 
// Parameters:
//   IssuedTo - Array of String
//             - String
//
// Returns:
//   Map of KeyAndValue:
//     * Key     - String - Individual's name
//     * Value - Array of DefinedType.Individual - References to the individuals catalog specified in the
//                                                             "Individual" type collection.
//
Function GetIndividualsByCertificateFieldIssuedTo(IssuedTo) Export

	IndividualsByFullName = New Map;

	If DigitalSignature.CommonSettings().IndividualUsed Then
		TypesIndividuals = Metadata.DefinedTypes.Individual.Type.Types();
		IndividualEmptyRef = New (TypesIndividuals[0]);
	Else
		Return IndividualsByFullName;
	EndIf;
	
	IndividualMetadataName = Common.TableNameByRef(IndividualEmptyRef);
	
	Query = New Query;
	QueryText = 
	"SELECT
	|	Persons.Ref AS Ref,
	|	Persons.Description AS Description
	|FROM
	|	Catalog.Users AS Persons
	|WHERE
	|	Persons.Description IN(&IssuedTo)
	|TOTALS BY
	|	Description";
	
	QueryText = StrReplace(QueryText, "Catalog.Users", IndividualMetadataName);
		
	Query.SetParameter("IssuedTo", IssuedTo);
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	
	SelectionDescription = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SelectionDescription.Next() Do
		
		Selection = SelectionDescription.Select();
		IndividualsForName = New Array;
		
		While Selection.Next() Do
			IndividualsForName.Add(Selection.Ref);
		EndDo;
		
		IndividualsByFullName.Insert(SelectionDescription.Description, IndividualsForName); 

	EndDo;
	
	Return IndividualsByFullName;
	
EndFunction

// Intended for: ConfigureCommonSettingsForm procedure.
Procedure SetHeaderTipsImprovements(Form, SignatureType)
	
	Items = Form.Items;
	
	If ValueIsFilled(SignatureType) Then
		
		Items.GroupImproveSignatures.Enabled = 
			SignatureType <> PredefinedValue("Enum.CryptographySignatureTypes.NormalCMS")
			And SignatureType <> PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES");
		
		If Items.GroupImproveSignatures.Enabled Then
			
			Items.DecorationImprovementExtendedTooltip.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chữ ký được thêm vào từ trước và nhận từ bên ngoài sẽ được nâng cấp để lưu trữ lâu dài đến kiểu đã chọn: %1.';
					|ru = 'Подписи, добавленные ранее и полученные извне, будут усовершенствованы для длительного хранения до выбранного типа: %1.';
					|en = 'Previously added and external signatures will be enhanced for long-term storage up to the selected type: %1.'; fa = 'Previously added and external signatures will be enhanced for long-term storage up to the selected type: %1.';
					|it = 'Le firme aggiunte in precedenza e ottenute da fonti esterne saranno perfezionate per una conservazione a lungo termine fino al tipo selezionato: %1.';
					|pl = 'Podpisy, dodane wcześniej i otrzymane z zewnątrz, zostaną udoskonalone dla długotrwałego przechowywania do wybranego typu: %1.';
					|tr = 'Daha önce eklenen ve dışarıdan alınan imzalar, uzun süreli depolama için seçilen türe yükseltilecektir: %1.'"),
				SignatureType);
			
		Else
			Items.DecorationImprovementExtendedTooltip.Title = 
				NStr("vi = 'Chữ ký được thêm vào từ trước và nhận từ bên ngoài sẽ được nâng cấp để lưu trữ lâu dài đến kiểu đã chọn.';
					|ru = 'Подписи, добавленные ранее и полученные извне, будут усовершенствованы для длительного хранения до выбранного типа.';
					|en = 'Previously added and external signatures will be enhanced for long-term storage up to the selected type.'; fa = 'Previously added and external signatures will be enhanced for long-term storage up to the selected type.';
					|it = 'Le firme aggiunte in precedenza e ottenute da fonti esterne saranno perfezionate per una conservazione a lungo termine fino al tipo selezionato.';
					|pl = 'Podpisy, dodane wcześniej i otrzymane z zewnątrz, zostaną udoskonalone dla długotrwałego przechowywania do wybranego typu.';
					|tr = 'Daha önce eklenen ve dışarıdan alınan imzalar, uzun süreli depolama için seçilen türe yükseltilecektir.'");
		EndIf;
		
	Else
		Items.DecorationImprovementExtendedTooltip.Title = 
			NStr("vi = 'Chưa chọn kiểu chữ ký đối với chứng từ.';
				|ru = 'Не выбран тип подписи для документов.';
				|en = 'Signature type for documents is not selected.'; fa = 'Signature type for documents is not selected.';
				|it = 'Tipo di firma per documenti non selezionato.';
				|pl = 'Nie wybrano typu podpisu dla dokumentów.';
				|tr = 'Belgeler için imza türü seçilmedi.'");
		Items.GroupImproveSignatures.Enabled = False;
	EndIf;

EndProcedure

// Intended for: ConfigureCommonSettingsForm procedure.
Procedure SetHeaderElectronicSignatureOnServer(Form)
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	FileInfobase = Common.FileInfobase();
	
	ConstantsSet = Form.ConstantsSet;
	Items = Form.Items;
	
	If ConstantsSet.UseDigitalSignature Then
		CheckBoxTitle = NStr("vi = 'Kiểm tra chữ ký và chứng thư trên máy chủ';
							|ru = 'Проверять подписи и сертификаты на сервере';
							|en = 'Verify signatures and certificates on server'; fa = 'Verify signatures and certificates on server';
							|it = 'Verificare firme e certificati sul server';
							|pl = 'Weryfikuj podpisy i certyfikaty na serwerze';
							|tr = 'Sunucudaki imzaları ve sertifikaları kontrol edin'");
		CheckBoxTooltip =
			NStr("vi = 'Cho phép không cần cài đặt ứng dụng chữ ký điện tử trên máy tính người sử dụng để xác minh chữ ký điện tử và chứng thư.';
				|ru = 'Позволяет не устанавливать приложение электронной подписи на компьютер пользователя для проверки электронных подписей и сертификатов.';
				|en = 'Allows verifying digital signatures and certificates without installing a digital signing app on the user''s computer.'; fa = 'امکان بررسی امضاهای دیجیتال و گواهی‌ها را بدون نصب برنامه امضای دیجیتال روی رایانه کاربر فراهم می‌کند.';
				|it = 'Позволяет не устанавливать приложение электронной подписи на компьютер пользователя для проверки электронных подписей и сертификатов.';
				|pl = 'Allows verifying digital signatures and certificates without installing a digital signing app on the user''s computer.';
				|tr = 'Elektronik imzaları ve sertifikaları kontrol etmek için kullanıcının bilgisayarına elektronik imza uygulaması kurmamanızı sağlar.'");
	Else
		CheckBoxTitle = NStr("vi = 'Kiểm tra chứng thư trên máy chủ';
							|ru = 'Проверять сертификаты на сервере';
							|en = 'Verify certificates on server'; fa = 'Verify certificates on server';
							|it = 'Verificare i certificati sul server';
							|pl = 'Weryfikuj certyfikaty na serwerze';
							|tr = 'Sunucudaki sertifikaları kontrol et'");
		CheckBoxTooltip =
			NStr("vi = 'Cho phép không cần cài đặt ứng dụng chữ ký điện tử trên máy tính người sử dụng để kiểm tra chứng thư.';
				|ru = 'Позволяет не устанавливать приложение электронной подписи на компьютер пользователя для проверки сертификатов.';
				|en = 'Allows verifying certificates without installing a digital signing app on the user''s computer.'; fa = 'Allows verifying certificates without installing a digital signing app on the user''s computer.';
				|it = 'Позволяет не устанавливать приложение электронной подписи на компьютер пользователя для проверки сертификатов.';
				|pl = 'Allows verifying certificates without installing a digital signing app on the user''s computer.';
				|tr = 'Sertifikaları kontrol etmek için kullanıcının bilgisayarına elektronik imza uygulamasını kurmamanızı sağlar.'");
	EndIf;
	
	Items.VerifyDigitalSignaturesOnTheServer.Title = CheckBoxTitle;
	
	If FileInfobase Then
		HintOnServer = NStr("vi = 'Chú ý: trên máy tính, trong đó web-server có kết nối đến cơ sở thông tin file-server đang làm việc, cần cài đặt ít nhất một <a href=%1>ứng dụng chữ ký điện tử</a> từ danh sách.';
							|ru = 'Важно: на компьютер, где работает веб-сервер, подключенный к файловой информационной базе, должно быть установлено хотя бы одно <a href=%1>приложение электронной подписи</a> из списка.';
							|en = 'Important: At least one <a href=%1>digital signing app</a> from the list must be installed on the computer running the web server connected to the file infobase.'; fa = 'Important: At least one <a href=%1>digital signing app</a> from the list must be installed on the computer running the web server connected to the file infobase.';
							|it = 'Важно: на компьютер, где работает веб-сервер, подключенный к файловой информационной базе, должно быть установлено хотя бы одно <a href=%1>приложение электронной подписи</a> из списка.';
							|pl = 'Important: At least one <a href=%1>digital signing app</a> from the list must be installed on the computer running the web server connected to the file infobase.';
							|tr = 'Önemli: dosyaların Infobase''ine bağlanılan ve web sunucusunun çalıştığı bilgisayarda, listeden bir elektronik imza programı kurulmalıdır.'");
	Else
		HintOnServer = NStr("vi = 'Chú ý: trên mỗi máy tính, trong đó server 1C:Enterprise đang làm việc, cần cài đặt ít nhất một <a href=%1>ứng dụng chữ ký điện tử</a> từ danh sách.';
							|ru = 'Важно: на каждый компьютер, где работает сервер 1С:Предприятия, должно быть установлено хотя бы одно <a href=%1>приложение электронной подписи</a> из списка.';
							|en = 'Important: At least one <a href=%1>digital signing app</a> from the list must be installed on each computer running 1C:Enterprise server.'; fa = 'Important: At least one <a href=%1>digital signing app</a> from the list must be installed on each computer running 1C:Enterprise server.';
							|it = 'Важно: на каждый компьютер, где работает сервер 1С:Предприятия, должно быть установлено хотя бы одно <a href=%1>приложение электронной подписи</a> из списка.';
							|pl = 'Important: At least one <a href=%1>digital signing app</a> from the list must be installed on each computer running 1C:Enterprise server.';
							|tr = 'Önemli: 1C:Enterprise sunucusunun çalıştığı her bilgisayarda listeden bir elektronik imza uygulaması kurulmalıdır.'");
	EndIf;
	
	CheckBoxTooltip = CheckBoxTooltip + Chars.LF + Chars.LF + HintOnServer;
	
	Items.VerifyDigitalSignaturesOnTheServerExtendedTooltip.Title = 
		StringFunctions.FormattedString(CheckBoxTooltip, "Programs");
	
	If Not ConstantsSet.UseDigitalSignature Then
		CheckBoxTitle = NStr("vi = 'Mã hóa và giải mã trên máy chủ';
							|ru = 'Шифровать и расшифровывать на сервере';
							|en = 'Encrypt and decrypt on the server'; fa = 'Encrypt and decrypt on the server';
							|it = 'Crittografare e decrittare sul server';
							|pl = 'Szyfruj i deszyfruj na serwerze';
							|tr = 'Sunucuda şifreleme ve şifre çözme'");
		CheckBoxTooltip =
			NStr("vi = 'Cho phép không cần cài đặt ứng dụng chữ ký điện tử và chứng thư trên máy tính của người sử dụng để mã hóa và giải mã.';
				|ru = 'Позволяет не устанавливать приложение электронной подписи и сертификат на компьютер пользователя для шифрования и расшифровки.';
				|en = 'Allows encryption and decryption without installing a digital signing app and a certificate on the user''s computer.'; fa = 'Allows encryption and decryption without installing a digital signing app and a certificate on the user''s computer.';
				|it = 'Позволяет не устанавливать приложение электронной подписи и сертификат на компьютер пользователя для шифрования и расшифровки.';
				|pl = 'Allows encryption and decryption without installing a digital signing app and a certificate on the user''s computer.';
				|tr = 'Şifreleme ve şifre çözme için kullanıcının bilgisayarına elektronik imza uygulamasını ve sertifikasını yüklememenizi sağlar.'");
		
	ElsIf Not ConstantsSet.UseEncryption Then
		CheckBoxTitle = NStr("vi = 'Ký tên trên máy chủ';
							|ru = 'Подписывать на сервере';
							|en = 'Sign on the server'; fa = 'Sign on the server';
							|it = 'Firmare sul server';
							|pl = 'Podpisuj na serwerze';
							|tr = 'Sunucuda oturum aç'");
		CheckBoxTooltip =
			NStr("vi = 'Cho phép không cần cài đặt ứng dụng chữ ký điện tử và chứng thư trên máy tính người sử dụng để ký tên.';
				|ru = 'Позволяет не устанавливать приложение электронной подписи и сертификат на компьютер пользователя для подписания.';
				|en = 'Allows signing without installing a digital signing app and a certificate on the user''s computer.'; fa = 'Allows signing without installing a digital signing app and a certificate on the user''s computer.';
				|it = 'Позволяет не устанавливать приложение электронной подписи и сертификат на компьютер пользователя для подписания.';
				|pl = 'Allows signing without installing a digital signing app and a certificate on the user''s computer.';
				|tr = 'Şifreleme ve şifre çözme için kullanıcının bilgisayarına elektronik imza uygulamasını ve sertifikasını yüklememenizi sağlar.'");
	Else
		CheckBoxTitle = NStr("vi = 'Ký tên và mã hóa trên máy chủ';
							|ru = 'Подписывать и шифровать на сервере';
							|en = 'Sign and encrypt on server'; fa = 'Sign and encrypt on server';
							|it = 'Firmare e crittografare sul server';
							|pl = 'Podpisuj i szyfruj na serwerze';
							|tr = 'Sunucuda imzalamak ve şifresini çözmek'");
		CheckBoxTooltip =
			NStr("vi = 'Cho phép không cần cài đặt ứng dụng chữ ký điện tử và chứng thư trên máy tính của người sử dụng để mã hóa và giải mã.';
				|ru = 'Позволяет не устанавливать приложение электронной подписи и сертификат на компьютер пользователя для подписания, шифрования и расшифровки.';
				|en = 'Allows encryption decryption, and signing without installing a digital signing app and a certificate on the user''s computer.'; fa = 'امکان رمزنگاری، رمزگشایی و امضا را بدون نصب برنامه امضای دیجیتال و گواهی روی رایانه کاربر فراهم می‌کند.';
				|it = 'Позволяет не устанавливать приложение электронной подписи и сертификат на компьютер пользователя для подписания, шифрования и расшифровки.';
				|pl = 'Allows encryption decryption, and signing without installing a digital signing app and a certificate on the user''s computer.';
				|tr = 'Elektronik imza uygulamasını ve sertifikayı kullanıcının bilgisayarına imzalama, şifreleme ve şifre çözme için yüklememenize izin verir.'");
	EndIf;
		
	Items.GenerateDigitalSignaturesAtServer.Title = CheckBoxTitle;
	
	If FileInfobase Then
		HintOnServer = NStr("vi = 'Chú ý: trên máy tính, trong đó web-server kết nối với cơ sở thông tin file-server đang làm việc, cần cài đặt <a href=%1> ứng dụng chữ ký điện tử</a> và <a href=%2>chứng thư</a> có khóa riêng.';
							|ru = 'Важно: на компьютер, где работает веб-сервер, подключенный к файловой информационной базе, должно быть установлено <a href=%1>приложение электронной подписи</a> и <a href=%2>сертификат</a> с закрытым ключом.';
							|en = 'Important: You need to install a <a href=%1>digital signing application</a> and a <a href=%2>certificate</a> with a private key on the computer that hosts the web server connected to the infobase.'; fa = 'Important: You need to install a <a href=%1>digital signing application</a> and a <a href=%2>certificate</a> with a private key on the computer that hosts the web server connected to the infobase.';
							|it = 'Важно: на компьютер, где работает веб-сервер, подключенный к файловой информационной базе, должно быть установлено <a href=%1>приложение электронной подписи</a> и <a href=%2>сертификат</a> с закрытым ключом.';
							|pl = 'Important: You need to install a <a href=%1>digital signing application</a> and a <a href=%2>certificate</a> with a private key on the computer that hosts the web server connected to the infobase.';
							|tr = 'Важно: на компьютер, где работает веб-сервер, подключенный к файловой информационной базе, должно быть установлено <a href=%1>приложение электронной подписи</a> и <a href=%2>сертификат</a> с закрытым ключом.'");
	Else
		HintOnServer = NStr("vi = 'Chú ý: trên mỗi máy tính, trong đó máy chủ 1C:Enterprise đang làm việc, cần cài đặt <a href=%1>ứng dụng chữ ký điện tử</a> và <a href=%2>chứng thư</a> có khóa riêng.';
							|ru = 'Важно: на каждый компьютер, где работает сервер 1С:Предприятия, должно быть установлено <a href=%1>приложение электронной подписи</a> и <a href=%2>сертификат</a> с закрытым ключом.';
							|en = 'Important: You need to install a <a href=%1>digital signing application</a> and a <a href=%2>certificate</a> with a private key on all computers that host 1C:Enterprise server.'; fa = 'Important: You need to install a <a href=%1>digital signing application</a> and a <a href=%2>certificate</a> with a private key on all computers that host 1C:Enterprise server.';
							|it = 'Важно: на каждый компьютер, где работает сервер 1С:Предприятия, должно быть установлено <a href=%1>приложение электронной подписи</a> и <a href=%2>сертификат</a> с закрытым ключом.';
							|pl = 'Important: You need to install a <a href=%1>digital signing application</a> and a <a href=%2>certificate</a> with a private key on all computers that host 1C:Enterprise server.';
							|tr = 'Важно: на каждый компьютер, где работает сервер 1С:Предприятия, должно быть установлено <a href=%1>приложение электронной подписи</a> и <a href=%2>сертификат</a> с закрытым ключом.'"); 
	EndIf;
	
	CheckBoxTooltip = CheckBoxTooltip + Chars.LF + Chars.LF + HintOnServer;
	
	Items.GenerateDigitalSignaturesAtServerExtendedTooltip.Title = 
		StringFunctions.FormattedString(CheckBoxTooltip, "Programs", "Certificates");
		
EndProcedure

Function IsCryptographyAvailable() Export
	
	Settings = DigitalSignature.CommonSettings();
	
	Return Not Common.DataSeparationEnabled()
		And Settings.VerifyDigitalSignaturesOnTheServer
		Or Settings.GenerateDigitalSignaturesAtServer
		Or Common.FileInfobase()
		And Not Common.ClientConnectedOverWebServer();
	
EndFunction

// Verifies the permission to add certificates to the catalog.
// 
// Returns:
//   Boolean
//
Function HasRightToAddCertificatesToCatalog() Export
	
	Return AccessRight("Insert", Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates);
	
EndFunction

#EndRegion

#Region XMLEnvelopeProperties

Function ProcessTheSignedInfoNode(TheSignedInfoNode, XMLEnvelopeProperties)
	
	If Not CheckTheUniquenessOfTheNode(TheSignedInfoNode, XMLEnvelopeProperties) Then
		Return False;
	EndIf;
	
	NodesArrayReference = New Array;
	
	For Each ChildNode In TheSignedInfoNode.ChildNodes Do
		If ChildNode.LocalName = "CanonicalizationMethod" Then
			If Not GetAttribute(ChildNode, "Algorithm", XMLEnvelopeProperties,
						"TheCanonizationAlgorithm", XMLEnvelopeProperties.CheckSignature) Then
				Return False;
			EndIf;
		ElsIf ChildNode.LocalName = "SignatureMethod" Then
			If Not GetAttribute(ChildNode, "Algorithm", XMLEnvelopeProperties,
						"SignAlgorithm", XMLEnvelopeProperties.CheckSignature) Then
				Return False;
			EndIf;
		ElsIf ChildNode.LocalName = "Reference" Then
			NodesArrayReference.Add(ChildNode);
		EndIf;
	EndDo;
	
	Return ProcessReferenceNodes(NodesArrayReference, XMLEnvelopeProperties);
		
EndFunction

Function ProcessReferenceNodes(NodesArrayReference, XMLEnvelopeProperties)
	
	For Each TheReferenceNode In NodesArrayReference Do
		HashedArea = DescriptionOfTheHashedArea();
		
		AdditionalParameters = AttributeAdditionalParameters(True, HashedArea, True);
		If Not GetAttribute(TheReferenceNode, "URI", XMLEnvelopeProperties,
					"NodeID", False, AdditionalParameters) Then
			Return False;
		EndIf;
		
		For Each ChildNode In TheReferenceNode.ChildNodes Do
			If ChildNode.LocalName = "Transforms" Then
				If Not ProcessTheTransformsNode(ChildNode, XMLEnvelopeProperties, HashedArea) Then
					Return False;
				EndIf;
			ElsIf ChildNode.LocalName = "DigestMethod" Then
				AdditionalParameters = AttributeAdditionalParameters(True, HashedArea);
				If Not GetAttribute(ChildNode, "Algorithm", XMLEnvelopeProperties, "HashAlgorithm",
							XMLEnvelopeProperties.CheckSignature, AdditionalParameters) Then
					Return False;
				EndIf;
			ElsIf ChildNode.LocalName = "DigestValue" Then
				AdditionalParameters = AttributeAdditionalParameters(False, HashedArea);
				If Not GetValue(ChildNode, XMLEnvelopeProperties,
						"HashValue", HashedArea, True) Then
					Return False;
				EndIf;
			EndIf;
		EndDo;
		XMLEnvelopeProperties.AreasToHash.Add(HashedArea);
	EndDo;
	
	Return True;
	
EndFunction

Function ProcessTheTransformsNode(TheTransformsNode, XMLEnvelopeProperties, HashedArea)
	
	AdditionalParameters = AttributeAdditionalParameters(True);
	If Not CheckTheUniquenessOfTheNode(TheTransformsNode, XMLEnvelopeProperties, AdditionalParameters) Then
		Return False;
	EndIf;
	
	For Each ChildNode In TheTransformsNode.ChildNodes Do
		If ChildNode.LocalName = "Transform" Then
			AdditionalParameters = AttributeAdditionalParameters(True, HashedArea);
			If Not GetAttribute(ChildNode, "Algorithm", XMLEnvelopeProperties, "TransformationAlgorithms",
						XMLEnvelopeProperties.CheckSignature, AdditionalParameters) Then
				Return False;
			EndIf;
		EndIf;
	EndDo;
	
	Return True;

EndFunction

Function ProcessTheKeyInfoNode(KeyInfoNode, XMLEnvelopeProperties)
	
	If Not CheckTheUniquenessOfTheNode(KeyInfoNode, XMLEnvelopeProperties) Then
		Return False;
	EndIf;
	
	For Each ChildNode In KeyInfoNode.ChildNodes Do
		If ChildNode.LocalName = "X509Data" Then
			If Not ProcessNodeX509Data(ChildNode, XMLEnvelopeProperties) Then
				Break;
			EndIf;
		ElsIf ChildNode.LocalName = "KeyInfoReference"
		      Or ChildNode.LocalName = "SecurityTokenReference" Then
			If Not ProcessANodeWithACertificateReference(ChildNode, XMLEnvelopeProperties) Then
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function ProcessNodeX509Data(NodeX509Data, XMLEnvelopeProperties)
	
	If Not CheckTheUniquenessOfTheNode(NodeX509Data, XMLEnvelopeProperties) Then
		Return False;
	EndIf;
	
	For Each ChildNode In NodeX509Data.ChildNodes Do
		If ChildNode.LocalName <> "X509Certificate" Then
			Continue;
		EndIf;
		If Not GetValue(ChildNode, XMLEnvelopeProperties,
					"CertificateValue", XMLEnvelopeProperties.Certificate) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function ProcessANodeWithACertificateReference(NodeWithALinkToTheCertificate, XMLEnvelopeProperties)
	
	If Not CheckTheUniquenessOfTheNode(NodeWithALinkToTheCertificate, XMLEnvelopeProperties) Then
		Return False;
	EndIf;
	
	AdditionalParameters = AttributeAdditionalParameters(False);
	
	For Each ChildNode In NodeWithALinkToTheCertificate.ChildNodes Do
		If ChildNode.LocalName <> "Reference" Then
			Continue;
		EndIf;
		AdditionalParameters.Properties = XMLEnvelopeProperties.Certificate;
		If Not GetAttribute(ChildNode, "URI", XMLEnvelopeProperties,
				"NodeID", False, AdditionalParameters) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

// Parameters:
//  DOMDocument      - DOMDocument
//  LocalName     - String
//  Namespace - String
//  ErrorText      - String
//  ExcludedNodes  - Undefined
//                   - Array of DOMElement
//  ErrorIfFound - Boolean
//
// Returns:
//  DOMElement
//
Function FindANodeByName(DOMDocument, LocalName, Namespace,
			ErrorText, ExcludedNodes = Undefined,
			NamespacesUpToAndIncludingTheNode = Undefined, ErrorIfFound = False)
	
	NodeFound = False;
	NamespacesUpToANode =
		?(NamespacesUpToAndIncludingTheNode <> Undefined, New Array, Undefined);
	
	For Each Node In DOMDocument.ChildNodes Do
		If ExcludedNodes <> Undefined
		   And ExcludedNodes.Find(Node) <> Undefined Then
			Continue;
		EndIf;
		If Node.LocalName = LocalName
		   And Node.NamespaceURI = Namespace Then
			Result = Node;
			NodeFound = True;
			Break;
		EndIf;
		NamespacesOfNestedNodes =
			?(NamespacesUpToANode <> Undefined, New Array, Undefined);
		Result = FindANodeByName(Node, LocalName, Namespace,
			Null, ExcludedNodes, NamespacesOfNestedNodes);
		If Result <> Undefined Then
			NodeFound = True;
			AddNamespaces(NamespacesUpToANode,
				Node, NamespacesOfNestedNodes);
			Break;
		EndIf;
	EndDo;
	
	If Not NodeFound Then
		Result = Undefined;
	EndIf;
	
	If ErrorText = Null Then
		NamespacesUpToAndIncludingTheNode = NamespacesUpToANode;
		Return Result;
	EndIf;
	
	If NodeFound And ErrorIfFound Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong văn bản XML đã tìm thấy hơn một nút ""%1"" với không gian tên ""%2"".';
				|ru = 'В документе XML найдено более одного узла ""%1"" с пространством имен ""%2"".';
				|en = 'More than one %1 node with %2 namespace is found in the XML document.'; fa = 'More than one %1 node with %2 namespace is found in the XML document.';
				|it = 'Trovato più di un nodo ""%1"" con lo spazio dei nomi ""%2"" nel documento XML.';
				|pl = 'W dokumencie XML znaleziono więcej niż jeden węzeł ""%1"" z obszarem nazw ""%2"".';
				|tr = 'XML belgesinde ""%2"" ad alanlı birden fazla ""%1"" ünite bulundu.'"),
			LocalName,
			Namespace);
	ElsIf Not NodeFound And Not ErrorIfFound Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong văn bản XML không tìm thấy nút ""%1"" với không gian tên ""%2"".';
				|ru = 'В документе XML не найден узел ""%1"" с пространством имен ""%2"".';
				|en = '%1 node with %2 namespace is not found in the XML document.'; fa = '%1 node with %2 namespace is not found in the XML document.';
				|it = 'Nodo ""%1"" con lo spazio dei nomi ""%2"" non trovato nel documento XML.';
				|pl = 'W dokumencie XML nie znaleziono węzła ""%1"" z obszarem nazw ""%2"".';
				|tr = 'XML belgesinde ""%2"" ad alanlı ""%1"" düğümü bulunamadı.'"),
			LocalName,
			Namespace);
	EndIf;
	
	If Result <> Undefined
	   And NamespacesUpToAndIncludingTheNode <> Undefined Then
		
		AddNamespaces(NamespacesUpToAndIncludingTheNode,
			Result, NamespacesUpToANode);
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  DOMDocument       - DOMDocument
//  NodeID - String
//  ErrorText       - String
//  ExcludedNodes   - Array of DOMElement
//  NamespacesUpToANode - Undefined
//                         - Array of String
//  ErrorIfFound - Boolean
//
// Returns:
//  DOMElement
//
Function FindANodeByID(DOMDocument, NodeID, ErrorText,
			ExcludedNodes = Undefined, NamespacesUpToANode = Undefined, ErrorIfFound = False)
	
	NodeFound = False;
	NameOfTheIDAttribute = "Id";
	
	For Each Node In DOMDocument.ChildNodes Do
		If Node.Attributes = Undefined
		 Or ExcludedNodes <> Undefined
		   And ExcludedNodes.Find(Node) <> Undefined Then
			Continue;
		EndIf;
		For Each Attribute In Node.Attributes Do
			If Upper(Attribute.LocalName) = Upper(NameOfTheIDAttribute)
			   And Attribute.NodeValue = NodeID Then
				Result = Node;
				NodeFound = True;
				Break;
			EndIf;
		EndDo;
		If NodeFound Then
			Break;
		EndIf;
		NamespacesOfNestedNodes =
			?(NamespacesUpToANode <> Undefined, New Array, Undefined);
		Result = FindANodeByID(Node,
			NodeID, Null, ExcludedNodes, NamespacesOfNestedNodes);
		If Result <> Undefined Then
			NodeFound = True;
			AddNamespaces(NamespacesUpToANode,
				Node, NamespacesOfNestedNodes);
			Break;
		EndIf;
	EndDo;
	
	If Not NodeFound Then
		Result = Undefined;
	EndIf;
	
	If ErrorText = Null Then
		Return Result;
	EndIf;
	
	If NodeFound And ErrorIfFound Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong văn bản XML đã tìm thấy hơn một nút với thuộc tính ""%1"" và giá trị ""%2"".';
				|ru = 'В документе XML найдено более одного узла с атрибутом ""%1"" и значением ""%2"".';
				|en = 'More than one node with the %1 attribute and the %2 value is found in the XML document.'; fa = 'More than one node with the %1 attribute and the %2 value is found in the XML document.';
				|it = 'Più di un nodo con attributo ""%1"" e valore ""%2"" trovato nel documento XML.';
				|pl = 'W dokumencie XML znaleziono więcej niż jeden węzeł z atrybutem ""%1"" i wartością ""%2"".';
				|tr = 'XML belgesinde ""%1"" öznitelikli ve ""%2"" değere sahip birden fazla ünite bulundu.'"),
			NameOfTheIDAttribute,
			NodeID);
	ElsIf Not NodeFound And Not ErrorIfFound Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong văn bản XML không tìm thấy nút có thuộc tính ""%1"" và giá trị ""%2"".';
				|ru = 'В документе XML не найден узел с атрибутом ""%1"" и значением ""%2"".';
				|en = 'Node with the %1 attribute and the %2 value is not found in the XML document.'; fa = 'Node with the %1 attribute and the %2 value is not found in the XML document.';
				|it = 'Nodo con attributo ""%1"" e valore ""%2"" non trovato nel documento XML.';
				|pl = 'W dokumencie XML nie znaleziono węzła z atrybutem ""%1"" i wartością ""%2"".';
				|tr = 'XML belgesinde ""%1"" öznitelikli ve ""%2"" değere sahip düğüm bulunamadı.'"),
			NameOfTheIDAttribute,
			NodeID);
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AddNamespaces(Namespaces, Node, NamespacesOfNestedNodes)
	
	If Namespaces <> Undefined Then
		For Each Attribute In Node.Attributes Do
			If Attribute.Prefix <> "xmlns" Then
				Continue;
			EndIf;
			Namespace = Attribute.NodeName + "=""" + Attribute.NodeValue + """";
			If Namespaces.Find(Namespace) = Undefined Then
				Namespaces.Add(Namespace);
			EndIf;
		EndDo;
		For Each Namespace In NamespacesOfNestedNodes Do
			If Namespaces.Find(Namespace) = Undefined Then
				Namespaces.Add(Namespace);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Function GetValue(DOMElement, XMLEnvelopeProperties, PropertyName, Properties = Undefined, MultipleSigning = False)
	
	Value = DOMElement.TextContent;
	
	AdditionalParameters = AttributeAdditionalParameters(MultipleSigning, Properties);
	
	Result = CheckSetValue(Value,
		DOMElement, "", XMLEnvelopeProperties, PropertyName, AdditionalParameters);
	
	Return Result;
	
EndFunction

Function AttributeAdditionalParameters(MultipleSigning, Properties = Undefined, NameWithParent = False)
	
	Structure = New Structure;
	Structure.Insert("MultipleSigning", MultipleSigning);
	Structure.Insert("Properties", Properties);
	Structure.Insert("NameWithParent", NameWithParent);
	
	Return Structure;
	
EndFunction

Function GetAttribute(DOMElement, AttributeName, XMLEnvelopeProperties, PropertyName,
			LowercaseValue = False, AdditionalParameters = Undefined)
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AttributeAdditionalParameters(False);
	EndIf;
	
	Attribute = DOMElement.Attributes.GetNamedItem(AttributeName);
	If Attribute = Undefined Then
		XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong văn bản XML đối với nút ""%1"" không tìm thấy thuộc tính ""%2"".';
				|ru = 'В документе XML для узла ""%1"" не найден атрибут ""%2"".';
				|en = 'The %2 attribute is not found for the %1 node in the XML document.'; fa = 'The %2 attribute is not found for the %1 node in the XML document.';
				|it = 'Attributo ""%2"" per il nodo ""%1"" non trovato nel documento XML.';
				|pl = 'W dokumencie XML dla węzła ""%1"" nie znaleziono atrybutu ""%2"".';
				|tr = 'XML dosyasında ""%1"" ünite için ""%2"" öznitelik bulunamadı.'"),
			DOMElement.LocalName, AttributeName);
		Return False;
	EndIf;
	Value = Attribute.NodeValue;
	
	If LowercaseValue Then
		Value = Lower(Value);
	EndIf;
	
	Result = CheckSetValue(Value,
		DOMElement, AttributeName, XMLEnvelopeProperties, PropertyName,
		AdditionalParameters);
	
	Return Result;
	
EndFunction

Function CheckSetValue(Value, DOMElement, AttributeName, XMLEnvelopeProperties, PropertyName, AdditionalParameters)
	
	If Not CheckTheUniquenessOfTheNode(DOMElement, XMLEnvelopeProperties, AdditionalParameters) Then
		Return False;
	EndIf;
	
	If XMLEnvelopeProperties.AvailableProperties.Property(PropertyName) Then
		AvailableValues = XMLEnvelopeProperties.AvailableProperties[PropertyName];
		If AvailableValues.ThisIsBase64String Or AvailableValues.ThisIsTheURI Then
			Value = TrimAll(Value);
		EndIf;
		
		If Not XMLEnvelopeProperties.CheckSignature
		   And ValueIsFilled(AvailableValues.ParameterName) Then
		   
			If Value <> AvailableValues.ParameterName And Not AdditionalParameters.MultipleSigning Then
				If ValueIsFilled(AttributeName) Then
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong văn bản XML đối với nút ""%1"" trong thuộc tính ""%2"" cần chỉ ra giá trị ""%3"".';
							|ru = 'В документе XML для узла ""%1"" в атрибуте ""%2"" должно быть указано значение ""%3"".';
							|en = 'The %1 node requires the %3 value in the %2 attribute in the XML document.'; fa = 'The %1 node requires the %3 value in the %2 attribute in the XML document.';
							|it = 'Nel documento XML per il nodo ""%1"" nell''attributo ""%2"" deve essere indicato il valore ""%3"".';
							|pl = 'W dokumencie XML dla węzła ""%1"" w atrybucie ""%2"" powinna być podana wartość ""%3"".';
							|tr = 'Bir XML belgesinde, ""%1"" ünitenin ""%2"" özniteliğinde değer ""%3"" olarak ayarlanmış olmalıdır.'"),
						DOMElement.LocalName, AttributeName, AvailableValues.ParameterName);
				Else
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong văn bản XML đối với nút ""%1"" cần chỉ ra giá trị ""%2"".';
							|ru = 'В документе XML для узла ""%1"" должно быть указано значение ""%2"".';
							|en = 'The %1 node requires the %2 value in the XML document.'; fa = 'The %1 node requires the %2 value in the XML document.';
							|it = 'Nel documento XML per il nodo ""%1"" deve essere indicato il valore ""%2"".';
							|pl = 'W dokumencie XML dla węzła ""%1"" powinna być podana wartość ""%2"".';
							|tr = 'Bir XML belgesinde, ""%1"" ünitenin değeri ""%2"" olarak ayarlanmış olmalıdır.'"),
						DOMElement.LocalName, AvailableValues.ParameterName);
				EndIf;
				Return False;
			EndIf;
		
		ElsIf AvailableValues.ThisIsBase64String Then
			Try
				Base64Value = Base64Value(Value);
			Except
				Base64Value = "";
			EndTry;
			If Not ValueIsFilled(Base64Value) Then
				If ValueIsFilled(AttributeName) Then
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong văn bản XML đối với nút ""%1"" trong thuộc tính ""%2"" đã chỉ ra không phải là Base64 giá trị ""%3"".';
							|ru = 'В документе XML для узла ""%1"" в атрибуте ""%2"" указано не Base64 значение ""%3"".';
							|en = 'The %3 Base64 value is not specified for the %1 node in the %2 attribute in the XML document.'; fa = 'The %3 Base64 value is not specified for the %1 node in the %2 attribute in the XML document.';
							|it = 'Nel documento XML per il nodo ""%1"" nell''attributo ""%2"" il valore indicato ""%3"" non è del tipo Base64.';
							|pl = 'W dokumencie XML dla węzła ""%1"" w atrybucie ""%2"" podano nie Base64 wartość ""%3"".';
							|tr = 'XML dosyasında ""%1"" ünite için ""%2"" özniteliğinde Base64 olmayan ""%3"" değer ayarlandı.'"),
						DOMElement.LocalName, AttributeName, Value);
				Else
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong văn bản XML đối với nút ""%1"" đã chỉ ra không phải Base64 giá trị ""%2"".';
							|ru = 'В документе XML для узла ""%1"" указано не Base64 значение ""%2"".';
							|en = 'The %2 Base64 value is not specified for the %1 node in the XML document.'; fa = 'The %2 Base64 value is not specified for the %1 node in the XML document.';
							|it = 'Nel documento XML per il nodo ""%1"" il valore indicato ""%2"" non è del tipo Base64.';
							|pl = 'W dokumencie XML dla węzła ""%1"" podano nie Base64 wartość ""%2"".';
							|tr = 'XML dosyasında ""%1"" ünite için Base64 olmayan ""%2"" değer ayarlandı.'"),
						DOMElement.LocalName, AttributeName, Value);
				EndIf;
				Return False;
			EndIf;
			
		ElsIf AvailableValues.ThisIsTheURI Then
			If Not StrStartsWith(Value, "#")
			 Or StrLen(Value) < 2 Then
				If ValueIsFilled(AttributeName) Then
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong văn bản XML đối với nút ""%1"" trong thuộc tính ""%2"" đã chỉ ra sai URI ""%3"".';
							|ru = 'В документе XML для узла ""%1"" в атрибуте ""%2"" указан некорректный URI ""%3"".';
							|en = 'The %1 node has invalid %3 URI in the %2 attribute in the XML document.'; fa = 'The %1 node has invalid %3 URI in the %2 attribute in the XML document.';
							|it = 'Nel documento XML per il nodo ""%1"" nell''attributo ""%2"" è indicato URL non corretto ""%3"".';
							|pl = 'W dokumencie XML dla węzła ""%1"" w atrybucie ""%2"" jest podana niepoprawna wartość URI ""%3"".';
							|tr = 'XML dosyasında ""%1"" ünite için ""%2"" özniteliğinde geçersiz ""%3"" URl belirtildi.'"),
						DOMElement.LocalName, AttributeName, Value);
				Else
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong văn bản XML đối với nút ""%1"" đã chỉ ra sai URI ""%2"".';
							|ru = 'В документе XML для узла ""%1"" указан некорректный URI ""%2"".';
							|en = 'The %1 node has invalid %2 URI in the XML document.'; fa = 'The %1 node has invalid %2 URI in the XML document.';
							|it = 'Nel documento XML è indicato URL non corretto ""%2"" per il nodo ""%1"".';
							|pl = 'W dokumencie XML dla węzła ""%1"" jest podana niepoprawna wartość URI ""%2"".';
							|tr = 'XML dosyasında ""%1"" ünite için geçersiz ""%2"" URl belirtildi.'"),
						DOMElement.LocalName, AttributeName, Value);
				EndIf;
				Return False;
			EndIf;
			Value = Mid(Value, 2);
			
		ElsIf ValueIsFilled(AvailableValues.Values) Then
			LongDesc = AvailableValues.Values.Get(Value);
			If LongDesc = Undefined Then
				If ValueIsFilled(AttributeName) Then
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong văn bản XML đối với nút ""%1"" trong thuộc tính ""%2"" đã chỉ ra giá trị không hợp lệ ""%3"".';
							|ru = 'В документе XML для узла ""%1"" в атрибуте ""%2"" указано недопустимое значение ""%3"".';
							|en = 'The %1 node has invalid %3 value in the %2 attribute in the XML document.'; fa = 'The %1 node has invalid %3 value in the %2 attribute in the XML document.';
							|it = 'Nel documento XML, il nodo ""%1"" ha un valore non valido di ""%3"" nell''attributo ""%2"".';
							|pl = 'W dokumencie XML dla węzła ""%1"" w atrybucie ""%2"" jest podana niedopuszczalna wartość ""%3"".';
							|tr = 'Bir XML belgesinde, ""%1"" ünitenin ""%2"" özniteliğinde geçersiz ""%3"" değer belirtilmiştir.'"),
						DOMElement.LocalName, AttributeName, Value);
				Else
					XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong văn bản XML đối với nút ""%1"" đã chỉ ra giá trị không hợp lệ ""%2"".';
							|ru = 'В документе XML для узла ""%1"" указано недопустимое значение ""%2"".';
							|en = 'The %1 node has invalid %2 value in the XML document.'; fa = 'The %1 node has invalid %2 value in the XML document.';
							|it = 'Nel documento XML il nodo ""%1"" ha un valore non valido ""%2"".';
							|pl = 'W dokumencie XML dla węzła ""%1"" jest podana niedopuszczalna wartość ""%2"".';
							|tr = 'XML dosyasında ""%1"" ünite için geçersiz ""%2"" değer belirtildi.'"),
						DOMElement.LocalName, AttributeName, Value);
				EndIf;
				Return False;
			Else
				Value = LongDesc;
			EndIf;
		EndIf;
	EndIf;
	
	If AdditionalParameters.Properties = Undefined Then
		PropertiesSet = XMLEnvelopeProperties;
	Else
		PropertiesSet = AdditionalParameters.Properties;
	EndIf;
	
	If TypeOf(PropertiesSet[PropertyName]) = Type("Array") Then
		If PropertiesSet[PropertyName].Find(Value) = Undefined Then
			PropertiesSet[PropertyName].Add(Value);
		EndIf;
	Else
		PropertiesSet[PropertyName] = Value;
	EndIf;
	
	Return True;
	
EndFunction

Function CheckTheUniquenessOfTheNode(DOMElement, XMLEnvelopeProperties, AdditionalParameters = Undefined)
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AttributeAdditionalParameters(False);
	EndIf;
	
	PropertyName = DOMElement.LocalName;
	If AdditionalParameters.NameWithParent Then
		PropertyName = DOMElement.ParentNode.LocalName + "_" + PropertyName;
	EndIf;
	
	If XMLEnvelopeProperties.RequiredNodes.Property(PropertyName) Then
		XMLEnvelopeProperties.RequiredNodes[PropertyName] = DOMElement;
	EndIf;
	
	If Not XMLEnvelopeProperties.UniqueNodes.Property(PropertyName) Then
		Return True;
	EndIf;
	
	If AdditionalParameters.MultipleSigning Then
		If PropertyName = "SignedInfo_Reference" Then
			If XMLEnvelopeProperties.UniqueNodes[PropertyName] = Undefined Then
				XMLEnvelopeProperties.UniqueNodes[PropertyName] = New Array;
			EndIf;
			XMLEnvelopeProperties.UniqueNodes[PropertyName].Add(DOMElement);
		Else
			XMLEnvelopeProperties.UniqueNodes[PropertyName] = DOMElement;
		EndIf;
	Else
		
		If XMLEnvelopeProperties.UniqueNodes[PropertyName] <> Undefined Then
			If AdditionalParameters.NameWithParent Then
				XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong văn bản XML nút ""%1"" xuất hiện hơn một lần trong nút ""%2"".';
						|ru = 'В документе XML узел ""%1"" встречается более одного раза в узле ""%2"".';
						|en = 'The %1 node appears more than once in the %2 node in the XML document.'; fa = 'The %1 node appears more than once in the %2 node in the XML document.';
						|it = 'Nel documento XML il nodo ""%1"" è presente più di una volta nel nodo ""%2"".';
						|pl = 'W dokumencie XML węzeł ""%1"" spotyka się więcej niż jeden raz w węźle ""%2"".';
						|tr = 'XML dosyasında ""%1"" düğümü ""%2"" düğümünde bir defadan fazla görülüyor.'"),
					DOMElement.LocalName,
					DOMElement.ParentNode.LocalName);
			Else
				XMLEnvelopeProperties.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong văn bản XML nút ""%1"" xuất hiện hơn một lần.';
						|ru = 'В документе XML узел ""%1"" встречается более одного раза.';
						|en = 'The %1 node appears more than once in the XML document.'; fa = 'The %1 node appears more than once in the XML document.';
						|it = 'Nel documento XML il nodo ""%1"" è presente più di una volta.';
						|pl = 'W dokumencie XML węzeł ""%1"" spotyka się więcej niż jeden raz.';
						|tr = 'XML dosyasında ""%1"" düğümü bir defadan fazla görülüyor.'"),
					PropertyName);
			EndIf;
			Return False;
		EndIf;
		XMLEnvelopeProperties.UniqueNodes[PropertyName] = DOMElement;
	EndIf;
	
	Return True;
	
EndFunction

// Parameters:
//  ServicePropertiesOfTheXMLEnvelope - See ServicePropertiesOfTheXMLEnvelope
//
// Returns:
//  Structure:
//   * ErrorText         - String
//   * SignedInfoArea   - See DigitalSignatureInternalClientServer.XMLScope
//   * AreasBody         - Array of See DigitalSignatureInternalClientServer.XMLScope
//   * TheCanonizationAlgorithm - See TheCanonizationAlgorithm
//   * SignAlgorithm     - See SignatureAndHashingAlgorithm
//   * AreasToHash   - Array of See DescriptionOfTheHashedArea
//   * SignatureValue     - String - the Base64 string.
//   * Certificate          - See CertificateDetails
//   * CheckSignature     - Boolean - when False, signing.
//
Function ReturnedPropertiesOfTheXMLEnvelope(ServicePropertiesOfTheXMLEnvelope = Undefined)
	
	Result = New Structure;
	Result.Insert("ErrorText", "");
	Result.Insert("SignedInfoArea");
	Result.Insert("AreasBody", New Array);
	Result.Insert("TheCanonizationAlgorithm");
	Result.Insert("SignAlgorithm");
	Result.Insert("AreasToHash", New Array);
	Result.Insert("SignatureValue", "");
	Result.Insert("Certificate", CertificateDetails());
	Result.Insert("CheckSignature", False);
	
	If TypeOf(ServicePropertiesOfTheXMLEnvelope) = Type("Structure") Then
		FillPropertyValues(Result, ServicePropertiesOfTheXMLEnvelope);
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  CheckSignature - Boolean
//
// Returns:
//  Structure:
//   * ErrorText         - String
//   * SignedInfoArea   - See DigitalSignatureInternalClientServer.XMLScope
//   * AreasBody         - Array of See DigitalSignatureInternalClientServer.XMLScope
//   * TheCanonizationAlgorithm - See TheCanonizationAlgorithm
//   * SignAlgorithm     - See SignatureAndHashingAlgorithm
//   * AreasToHash   - Array of See DescriptionOfTheHashedArea
//   * SignatureValue     - String - the Base64 string.
//   * Certificate          - See CertificateDetails
//   * CheckSignature     - Boolean - when False, signing.
//   * AvailableProperties   - See AvailableXMLEnvelopeProperties
//   * RequiredNodes    - Structure of KeyAndValue:
//       * Key     - String - a node name or a parent node name with a node name.
//       * Value - DOMElement
//                  - Undefined
//   * UniqueNodes      - Structure of KeyAndValue:
//       * Key     - String - a node name or a parent node name with a node name.
//       * Value - DOMElement
//                  - Undefined
//
Function ServicePropertiesOfTheXMLEnvelope(CheckSignature)
	
	Result = ReturnedPropertiesOfTheXMLEnvelope();
	Result.CheckSignature = CheckSignature;
	Result.Insert("AvailableProperties", AvailableXMLEnvelopeProperties(CheckSignature));
	Result.Insert("RequiredNodes", New Structure(
		"SignedInfo,SignatureValue,KeyInfo,
		|CanonicalizationMethod,SignatureMethod,SignedInfo_Reference,
		|DigestMethod,DigestValue"));
	Result.Insert("UniqueNodes", New Structure(
		"SignedInfo,SignatureValue,KeyInfo,
		|CanonicalizationMethod,SignatureMethod,SignedInfo_Reference,
		|Transforms,DigestMethod,DigestValue,
		|X509Data,X509Certificate,SecurityTokenReference,Reference"));
	
	Return Result;
	
EndFunction

// Returns:
//  Structure:
//   * NodeID      - String
//   * TransformationAlgorithms - Array of See TheCanonizationAlgorithm
//   * HashAlgorithm    - See SignatureAndHashingAlgorithm
//   * HashValue           - String - the Base64 string.
//
Function DescriptionOfTheHashedArea()
	
	Result = New Structure;
	Result.Insert("NodeID", "");
	Result.Insert("TransformationAlgorithms", New Array);
	Result.Insert("HashAlgorithm", "");
	Result.Insert("HashValue", "");
	
	Return Result;
	
EndFunction

// Returns:
//  Structure:
//   * NodeID   - String
//   * CertificateValue - String - the Base64 string.
//
Function CertificateDetails()
	
	Result = New Structure;
	Result.Insert("NodeID",   "");
	Result.Insert("CertificateValue", "");
	
	Return Result;
	
EndFunction

// Parameters:
//  CheckSignature - Boolean
//
// Returns:
//  Structure:
//   * NodeID      - See AvailableValues
//   * TheCanonizationAlgorithm    - See AvailableValues
//   * TransformationAlgorithms - See AvailableValues
//   * HashValue           - See AvailableValues
//   * SignatureValue        - See AvailableValues
//   * CertificateValue    - See AvailableValues
//   * SignAlgorithm        - See AvailableValues
//   * HashAlgorithm    - See AvailableValues
//
Function AvailableXMLEnvelopeProperties(CheckSignature)
	
	Result = New Structure;
	Result.Insert("NodeID", AvailableValues("", , True));
	
	Result.Insert("TheCanonizationAlgorithm", AvailableValues(""));
	// Canonical XML 1.0.
	Values = Result.TheCanonizationAlgorithm.Values;
	Values.Insert("http://www.w3.org/TR/2001/REC-xml-c14n-20010315", TheCanonizationAlgorithm("C14N", 0, 0));
	If CheckSignature Then
		Values.Insert("http://www.w3.org/TR/2001/REC-xml-c14n-20010315#", TheCanonizationAlgorithm("C14N", 0, 0));
	EndIf;
	Values.Insert("http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments", TheCanonizationAlgorithm("C14N", 0, 1));
	// Canonical XML 1.1.
	Values.Insert("http://www.w3.org/2006/12/xml-c14n11", TheCanonizationAlgorithm("C14N", 2, 0));
	If CheckSignature Then
		Values.Insert("http://www.w3.org/2006/12/xml-c14n11#", TheCanonizationAlgorithm("C14N", 2, 0));
	EndIf;
	Values.Insert("http://www.w3.org/2006/12/xml-c14n11#WithComments", TheCanonizationAlgorithm("C14N", 2, 1));
	// Exclusive XML Canonicalization 1.0.
	Values.Insert("http://www.w3.org/2001/10/xml-exc-c14n#", TheCanonizationAlgorithm("C14N", 1, 0));
	If CheckSignature Then
		Values.Insert("http://www.w3.org/2001/10/xml-exc-c14n", TheCanonizationAlgorithm("C14N", 1, 0));
	EndIf;
	Values.Insert("http://www.w3.org/2001/10/xml-exc-c14n#WithComments", TheCanonizationAlgorithm("C14N", 1, 1));
	If CheckSignature Then
		BringKeysToLowercase(Result.TheCanonizationAlgorithm.Values);
	EndIf;
	
	Result.Insert("TransformationAlgorithms", AvailableValues(""));
	Values = New Map(New FixedMap(Values));
	Result.TransformationAlgorithms.Values = Values;
	Values.Insert("urn://smev-gov-ru/xmldsig/transform", TheCanonizationAlgorithm("smev", 0, 0));
	Values.Insert("http://www.w3.org/2000/09/xmldsig#enveloped-signature", TheCanonizationAlgorithm("envsig", 0, 0));
	If CheckSignature Then
		BringKeysToLowercase(Result.TransformationAlgorithms.Values);
	EndIf;
	
	Result.Insert("HashValue",        AvailableValues("%DigestValue%", True));
	Result.Insert("SignatureValue",     AvailableValues("%SignatureValue%", True));
	Result.Insert("CertificateValue", AvailableValues("%BinarySecurityToken%", True));
	
	Result.Insert("SignAlgorithm",     AvailableValues("%SignatureMethod%"));
	Result.Insert("HashAlgorithm", AvailableValues("%DigestMethod%"));
	
	Sets = DigitalSignatureInternalClientServer.SetsOfAlgorithmsForCreatingASignature();
	For Each Set In Sets Do
		Result.SignAlgorithm.Values.Insert(Set.NameOfTheXMLSignatureAlgorithm,
			SignatureAndHashingAlgorithm(Set.NameOfTheXMLSignatureAlgorithm, Set.IDOfTheSignatureAlgorithm));
		Result.HashAlgorithm.Values.Insert(Set.NameOfTheXMLHashingAlgorithm,
			SignatureAndHashingAlgorithm(Set.NameOfTheXMLHashingAlgorithm, Set.IdOfTheHashingAlgorithm));
	EndDo;
	If CheckSignature Then
		BringKeysToLowercase(Result.SignAlgorithm.Values);
		BringKeysToLowercase(Result.HashAlgorithm.Values);
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  Name           - String
//  Id - String
//
// Returns:
//  Structure:
//   * Name           - String
//   * Id - String
//
Function SignatureAndHashingAlgorithm(Name, Id)
	
	Result = New Structure;
	Result.Insert("Name", Name);
	Result.Insert("Id", Id);
	
	Return Result;
	
EndFunction

// Parameters:
//  Kind            - String
//  Version         - Number
//  WithComments - Number
//
// Returns:
//  Structure:
//   * Kind            - String
//   * Version         - Number
//   * WithComments - Number
//
Function TheCanonizationAlgorithm(Kind, Version, WithComments) Export
	
	Result = New Structure;
	Result.Insert("Kind", Kind);
	Result.Insert("Version", Version);
	Result.Insert("WithComments", WithComments);
	
	Return Result;
	
EndFunction

// Parameters:
//  ParameterName    - String
//  ThisIsBase64String - Boolean
//  ThisIsTheURI          - Boolean
//
// Returns:
//  Structure:
//   * ParameterName    - String
//   * ThisIsBase64String - Boolean
//   * ThisIsTheURI          - Boolean
//   * Values - Map of KeyAndValue:
//       ** Key     - String
//       ** Value - Structure
//
Function AvailableValues(ParameterName, ThisIsBase64String = False, ThisIsTheURI = False)
	
	Result = New Structure;
	Result.Insert("ParameterName", ParameterName);
	Result.Insert("Values", New Map);
	Result.Insert("ThisIsBase64String", ThisIsBase64String);
	Result.Insert("ThisIsTheURI", ThisIsTheURI);
	
	Return Result;
	
EndFunction

Procedure BringKeysToLowercase(Values)
	
	NewValues = New Map;
	
	For Each KeyAndValue In Values Do
		NewValues.Insert(Lower(KeyAndValue.Key), KeyAndValue.Value);
	EndDo;
	
	Values = NewValues;
	
EndProcedure

#EndRegion

#Region CryptoErrorsClassifier

Function ClassifierError(TextToSearchInClassifier, ErrorAtServer = False, SignatureVerificationError = False,
		IsCertificateSpecified = False) Export
	
	ClassifierError = DigitalSignatureInternalCached.ClassifierError(
		TextToSearchInClassifier, ErrorAtServer, SignatureVerificationError, IsCertificateSpecified);
	
	If ClassifierError = Undefined Then
		Return Undefined;
	EndIf;
	
	ErrorPresentation = ErrorPresentation();
	FillPropertyValues(ErrorPresentation, ClassifierError);
	
	Return ErrorPresentation;
	
EndFunction

Function ErrorPresentation() Export
	
	ErrorPresentation = New Structure;
	ErrorPresentation.Insert("Ref", "");
	ErrorPresentation.Insert("Cause", "");
	ErrorPresentation.Insert("Decision", "");
	ErrorPresentation.Insert("Remedy", "");
	ErrorPresentation.Insert("RemedyActions");
	ErrorPresentation.Insert("IsCheckRequired", False);
	ErrorPresentation.Insert("CertificateRevoked", False);
	ErrorPresentation.Insert("InvalidSignatureHash", False);
	ErrorPresentation.Insert("UnknownCryptoAlgorithm", False);
	
	Return ErrorPresentation;
	
EndFunction

Function CryptoErrorsClassifier() Export
	
	ClassifierData = Undefined;
	DigitalSignatureLocalization.OnGetCryptoErrorsClassifier(ClassifierData);
		
	Result = NewClassifierOfCryptoErrors();
	If ClassifierData = Undefined Then
		Return Result;
	EndIf;
	
	For Each TableRow In ClassifierData.Classifier Do
		NewRow = Result.Add();
		FillPropertyValues(NewRow, TableRow);
	EndDo;
	
	Return Result;
	
EndFunction

Function NewClassifierOfCryptoErrors()
	
	Result = New ValueTable;
	Result.Columns.Add("ErrorText",
		New TypeDescription("String", New StringQualifiers(500)));
	Result.Columns.Add("ErrorTextLowerCase",
		New TypeDescription("String", New StringQualifiers(500)));
	Result.Columns.Add("Cause",
		New TypeDescription("String", New StringQualifiers(500)));
	Result.Columns.Add("Decision",
		New TypeDescription("String", New StringQualifiers(750)));
	Result.Columns.Add("Remedy",
		New TypeDescription("String", New StringQualifiers(500)));
	Result.Columns.Add("Ref",
		New TypeDescription("String", New StringQualifiers(500)));
		
	Result.Columns.Add("OnlyServer",    New TypeDescription("Boolean"));
	Result.Columns.Add("OnlyClient",    New TypeDescription("Boolean"));
	Result.Columns.Add("IsCheckRequired", New TypeDescription("Boolean"));
	Result.Columns.Add("CertificateRevoked",  New TypeDescription("Boolean"));
	Result.Columns.Add("InvalidSignatureHash", New TypeDescription("Boolean"));
	Result.Columns.Add("IsSignatureVerificationError", New TypeDescription("Boolean"));
	Result.Columns.Add("UnknownCryptoAlgorithm", New TypeDescription("Boolean"));
	
	Return Result;
	
EndFunction

// For internal use only.
Procedure WriteClassifierData(ClassifierData, LastChangeDate = Undefined) Export
	
	If ClassifierData <> Undefined Then
		
		Constants.CryptoErrorsClassifier.Set(
			New ValueStorage(RepresentationOfErrorClassifier(ClassifierData), New Deflation(9)));
	
	EndIf;
	
	If LastChangeDate <> Undefined Then
		Constants.LatestErrorsClassifierUpdateDate.Set(
			LastChangeDate);
	EndIf;
	
EndProcedure

// For internal use only.
Function RepresentationOfErrorClassifier(ClassifierData) Export
	
	JSONReader = New JSONReader;
	If TypeOf(ClassifierData) = Type("String") Then
		JSONReader.SetString(ClassifierData);
	Else
		JSONReader.OpenStream(ClassifierData.OpenStreamForRead());
	EndIf;
	
	ErrorsClassifier = ReadJSON(JSONReader,, "LastChangeDate");
	ClassifierVersion = CommonClientServer.StructureProperty(
		ErrorsClassifier, "Version", Undefined);
	JSONReader.Close();
	
	Classifier = NewClassifierOfCryptoErrors();
	
	For Each KnownError In ErrorsClassifier.Classifier Do
		
		NewError = Classifier.Add();
		NewError.Ref           = KnownError.Anchor;
		NewError.Cause          = KnownError.Reason;
		NewError.Decision          = KnownError.Solution;
		NewError.OnlyServer     = CommonClientServer.StructureProperty(KnownError, "Server", False);
		NewError.OnlyClient     = CommonClientServer.StructureProperty(KnownError, "Client", False);
		NewError.IsSignatureVerificationError     = CommonClientServer.StructureProperty(KnownError, "Sign", False);
		Category = CommonClientServer.StructureProperty(KnownError, "Category", Undefined);
		If ValueIsFilled(Category) Then
			NewError.InvalidSignatureHash = Error_InvalidSignatureHash(Category);
			If Not NewError.InvalidSignatureHash Then
				NewError.IsCheckRequired   = IsErrorRecheckRequired(Category);
				If Not NewError.IsCheckRequired Then
					NewError.CertificateRevoked = ErrorCertificateRevoked(Category);
					If Not NewError.CertificateRevoked Then
						NewError.UnknownCryptoAlgorithm = UnknownCryptoAlgorithmError(Category);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		NewError.ErrorText      = KnownError.ErrorText;
		NewError.Remedy = KnownError.RepairMethods;
		NewError.ErrorTextLowerCase = Lower(NewError.ErrorText);
		
		ErrorTextInEnglish = CommonClientServer.StructureProperty(KnownError, "En", Undefined);
		If ValueIsFilled(ErrorTextInEnglish) Then
			NewErrorInEnglish = Classifier.Add();
			FillPropertyValues(NewErrorInEnglish, NewError);
			NewErrorInEnglish.ErrorText = KnownError.En;
			NewErrorInEnglish.ErrorTextLowerCase = Lower(NewErrorInEnglish.ErrorText);
		EndIf;
		
	EndDo;
	
	Return New Structure("Classifier, Version", Classifier, ClassifierVersion);
	
EndFunction

Function IsErrorRecheckRequired(Category)
	
	If Category = "untrustedroot" Or Category = "no_revocation_check" Or Category = "chaining" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function ErrorCertificateRevoked(Category)
	
	If Category = "cert_revoked" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function Error_InvalidSignatureHash(Category)
	
	If Category = "hash_value" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function UnknownCryptoAlgorithmError(Category)
	
	If Category = "unknown_algo" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region DigitalSignatureDiagnostics

Procedure SupplementWithTechnicalInformationAboutServer(TechnicalInformation,
			VerifiedPathsToProgramModulesOnTheClient) Export
	
	If Not DigitalSignature.GenerateDigitalSignaturesAtServer()
		And Not DigitalSignature.VerifyDigitalSignaturesOnTheServer() Then
		
		TechnicalInformation = TechnicalInformation + Chars.LF
			+ NStr("vi = 'Không sử dụng chữ ký trên máy chủ.';
					|ru = 'Электронная подпись на сервере не используется.';
					|en = 'Digital signature is not used on the server.'; fa = 'Digital signature is not used on the server.';
					|it = 'Firma elettronica non è usata sul server.';
					|pl = 'Podpis elektroniczny na serwerze nie jest używany.';
					|tr = 'Sunucuda dijital imza kullanılmıyor.'") + Chars.LF;
	Else
		TechnicalInformation = TechnicalInformation
			+ Chars.LF + TechnicalInformationOnComputer()
			+ Chars.LF + Chars.LF + TechnicalInformationAboutTheComponent()
			+ Chars.LF + TechnicalInformationOnApplications();
		
		TechnicalInformation = TechnicalInformation
			+ Chars.LF + DigitalSignatureInternalServerCall.TimestampServersDiagnosticsResult();
		
	EndIf;
	
	TechnicalInformation = TechnicalInformation + Chars.LF
		+ TechnicalInformationAboutProgramSettingsInTheReferenceGuide(VerifiedPathsToProgramModulesOnTheClient);
	
	If Common.FileInfobase() Then
		WorkMode = ?(Common.ClientConnectedOverWebServer(),
			NStr("vi = 'File-server thông qua web';
				|ru = 'Файловый через веб';
				|en = 'File mode via web'; fa = 'File mode via web';
				|it = 'Di file via web';
				|pl = 'Plikowy przez www';
				|tr = 'Web üzerinden dosya'"), NStr("vi = 'File-server';
													|ru = 'Файловый';
													|en = 'File'; fa = 'فایل';
													|it = 'Di file';
													|pl = 'Plikowy';
													|tr = 'Dosya'"));
	Else
		WorkMode = NStr("vi = 'Client-server';
						|ru = 'Клиент-серверный';
						|en = 'Client/server'; fa = 'Client/server';
						|it = 'Client-server';
						|pl = 'Klient-serwer';
						|tr = 'İstemci/sunucu'");
	EndIf;
	
	TechnicalInformation = TechnicalInformation
		+ Chars.LF + NStr("vi = 'Chế độ làm việc của cơ sở thông tin';
							|ru = 'Режим работы информационной базы';
							|en = 'Infobase operation mode'; fa = 'Infobase operation mode';
							|it = 'Modalità di funzionamento del database';
							|pl = 'Tryb pracy bazy informacyjnej';
							|tr = 'Infobase çalışma modu.'")+ " - " + WorkMode
		+ Chars.LF + Chars.LF + StandardSubsystemsServer.TechnicalInfoOnExtensionsAndSubsystemsVersions();
	
EndProcedure

Function TechnicalInformationOnComputer()
	
	StartupParameters = FileSystem.ApplicationStartupParameters();
	StartupParameters.WaitForCompletion = True;
	StartupParameters.GetOutputStream = True;
	StartupParameters.ThreadsEncoding = TextEncoding.UTF8;
	
	If Common.IsWindowsServer() Then
		Command = "echo %username%";
	Else
		Command = "whoami";
	EndIf;
	
	Result = FileSystem.StartApplication(Command, StartupParameters);
	If Result.ReturnCode = 0 Then
		OSUserName = TrimAll(Result.OutputStream);
	Else
		OSUserName = "";
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Máy chủ (%1):';
			|ru = 'Сервер (%1):';
			|en = 'Server (%1):'; fa = 'Server (%1):';
			|it = 'Server (%1):';
			|pl = 'Serwer (%1):';
			|tr = 'Sunucu (%1):'"), ComputerName() + "\" + OSUserName) + Chars.LF
		+ StandardSubsystemsServer.SupportInformation();
	
EndFunction

Function TechnicalInformationAboutTheComponent()
	
	VersionComponents = "";
	Try 
		VersionComponents = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI().GetVersion();
	Except
		VersionComponents = ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Phiên bản cấu phần %1 trên máy chủ - %2';
			|ru = 'Версия компоненты %1 на сервере - %2';
			|en = 'Add-in ""%1"" version on server: %2'; fa = 'Add-in ""%1"" version on server: %2';
			|it = 'Versione della componente %1 su server - %2';
			|pl = 'Wersja komponentu %1 na serwerze - %2';
			|tr = '%1 bileşenin sunucudaki sürümü - %2'"), "ExtraCryptoAPI", VersionComponents); 
	
EndFunction

Function TechnicalInformationOnApplications()
	
	DiagnosticsInformation = "";
	
	InstalledAppsResult = InstalledCryptoProviders();
	
	If Not InstalledAppsResult.CheckCompleted Then
		DiagnosticsInformation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tự động xác định ứng dụng chữ ký điện tử và mã hóa trên ""%1"": %2';
				|ru = 'Не удалось автоматически определить приложения электронной подписи и шифрования на ""%1"": %2';
				|en = 'Couldn''t determine digital signing and encryption app on ""%1"": %2'; fa = 'Couldn''t determine digital signing and encryption app on ""%1"": %2';
				|it = 'Не удалось автоматически определить приложения электронной подписи и шифрования на ""%1"": %2';
				|pl = 'Couldn''t determine digital signing and encryption app on ""%1"": %2';
				|tr = '''%1'' üzerinde elektronik imza ve şifreleme uygulamaları otomatik olarak algılanamadı:'"),
			ComputerName(), InstalledAppsResult.Error);
	Else
		
		If InstalledAppsResult.Cryptoproviders.Count() = 0 Then
			DiagnosticsInformation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa cài đặt ứng dụng chữ ký điện tử và mã hóa trên ""%1"".';
					|ru = 'Приложения электронной подписи и шифрования на ""%1"" не установлены.';
					|en = 'No data signing and encryption apps are installed on ""%1"".'; fa = 'No data signing and encryption apps are installed on ""%1"".';
					|it = 'Приложения электронной подписи и шифрования на ""%1"" не установлены.';
					|pl = 'No data signing and encryption apps are installed on ""%1"".';
					|tr = '""%1"" üzerinde elektronik imza ve şifreleme uygulaması ayarlanmadı.'"),
				ComputerName());
		Else
			DiagnosticsInformation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Các ứng dụng chữ ký điện tử và mã hóa được tự động xác định trên server ""%1"":';
					|ru = 'Автоматически определенные приложения электронной подписи и шифрования на сервере ""%1"":';
					|en = 'Digital signing and encryption apps automatically detected on server ""%1"":'; fa = 'Digital signing and encryption apps automatically detected on server ""%1"":';
					|it = 'Автоматически определенные приложения электронной подписи и шифрования на сервере ""%1"":';
					|pl = 'Digital signing and encryption apps automatically detected on server ""%1"":';
					|tr = '""%1"" sunucusunda otomatik olarak algılanan elektronik imza ve şifreleme uygulamaları:'"), ComputerName()) + Chars.LF;
			
			For Each Application In InstalledAppsResult.Cryptoproviders Do
				
				CreationParameters = CryptoManagerCreationParameters();
				CreationParameters.AutoDetect = False;
				CreationParameters.Application = Application;
				CreationParameters.ShowError = False;
				CreationParameters.ErrorDescription = New Structure;
				
				CryptoManager = CryptoManager("", CreationParameters);
				
				DiagnosticsInformation = DiagnosticsInformation
					+ DigitalSignatureInternalClientServer.DiagnosticInformationAboutTheProgram(Application,
						CryptoManager, CreationParameters.ErrorDescription);
			EndDo;
		EndIf;
	EndIf;
	
	UsedApplications = DigitalSignatureInternalServerCall.UsedApplications();
	
	If UsedApplications.Count() = 0 Then
		Return DiagnosticsInformation;
	EndIf;
	
	DiagnosticsInformation = DiagnosticsInformation + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Ứng dụng trên server từ danh mục ""%1"":';
			|ru = 'Приложения на сервере из справочника ""%1"":';
			|en = 'Server application from ""%1"" catalog:'; fa = 'Server application from ""%1"" catalog:';
			|it = 'Server application from ""%1"" catalog:';
			|pl = 'Server application from ""%1"" catalog:';
			|tr = '""%1"" kataloğu üzerinden sunucudaki uygulamalar:'"), ComputerName()) + Chars.LF;
	
	For Each Application In UsedApplications Do
		
		CreationParameters = CryptoManagerCreationParameters();
		CreationParameters.AutoDetect = False;
		CreationParameters.Application = Application;
		CreationParameters.ShowError = False;
		CreationParameters.ErrorDescription = New Structure;
		
		CryptoManager = CryptoManager("", CreationParameters);
		
		DiagnosticsInformation = DiagnosticsInformation
			+ DigitalSignatureInternalClientServer.DiagnosticInformationAboutTheProgram(Application,
				CryptoManager, CreationParameters.ErrorDescription);
	EndDo;
	
	Return DiagnosticsInformation;
	
EndFunction

Function TechnicalInformationAboutProgramSettingsInTheReferenceGuide(VerifiedPathsToProgramModulesOnTheClient)
	
	DiagnosticsInformation = Chars.LF
		+ NStr("vi = 'Tùy chỉnh ứng dụng chữ ký điện tử và mã hóa';
				|ru = 'Настройки приложений электронной подписи и шифрования:';
				|en = 'Digital signing and encryption app settings:'; fa = 'Digital signing and encryption app settings:';
				|it = 'Настройки приложений электронной подписи и шифрования:';
				|pl = 'Digital signing and encryption app settings:';
				|tr = 'Uygulamaların dijital imza ve şifreleme ayarları:'") + Chars.LF;
	
	UsedApplications = DigitalSignatureInternalServerCall.UsedApplications();
	If UsedApplications.Count() = 0 Then
		DiagnosticsInformation = DiagnosticsInformation
			+ NStr("vi = 'Trong danh mục không có một ứng dụng chữ ký điện tử và mã hóa.';
					|ru = 'В справочнике нет ни одного приложения электронной подписи и шифрования.';
					|en = 'The catalog contains no digital signing and encryption apps.'; fa = 'The catalog contains no digital signing and encryption apps.';
					|it = 'В справочнике нет ни одного приложения электронной подписи и шифрования.';
					|pl = 'The catalog contains no digital signing and encryption apps.';
					|tr = 'Rehberde tek bir elektronik imza ve şifreleme uygulaması bulunmamaktadır.'");
		Return DiagnosticsInformation;
	EndIf;
	
	For Each Application In UsedApplications Do
		DiagnosticsInformation = DiagnosticsInformation + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1:
			           |	Ứng dụng: %2
			           |	Kiểu ứng dụng: %3
			           |	Thuật toán chữ ký: %4
			           |	Thuật toán băm: %5
			           |	Thuật toán mã hóa: %6
			           |	Chế độ sử dụng %7';
			           |ru = '%1:
			           |	Приложение: %2
			           |	Тип приложения: %3
			           |	Алгоритм подписи: %4
			           |	Алгоритм хеширования: %5
			           |	Алгоритм шифрования: %6
			           |	Режим использования %7';
			           |en = '%1:
			           |	App: %2
			           |	Type: %3
			           |	Signature algorithm: %4
			           |	Hashing algorithm: %5
			           |	Encryption algorithm: %6
			           |	Usage mode %7'; fa = '%1:
			           |	App: %2
			           |	Type: %3
			           |	Signature algorithm: %4
			           |	Hashing algorithm: %5
			           |	Encryption algorithm: %6
			           |	Usage mode %7';
			           |it = '%1:
			           |	Приложение: %2
			           |	Тип приложения: %3
			           |	Алгоритм подписи: %4
			           |	Алгоритм хеширования: %5
			           |	Алгоритм шифрования: %6
			           |	Режим использования %7';
			           |pl = '%1:
			           |	App: %2
			           |	Type: %3
			           |	Signature algorithm: %4
			           |	Hashing algorithm: %5
			           |	Encryption algorithm: %6
			           |	Usage mode %7';
			           |tr = '%1:
			           |	Programın adı: %2
			           |	Program türü: %3
			           |	İmza algoritması: %4
			           |	Anlamsız veri algoritması: %5
			           |	Şifreleme algoritması: %6
			           |	Kullanıcı modu %7'"),
			Application.Presentation,
			Application.ApplicationName,
			Application.ApplicationType,
			Application.SignAlgorithm,
			Application.HashAlgorithm,
			Application.EncryptAlgorithm,
			Application.UsageMode) + Chars.LF;
		
		If RequiresThePathToTheProgram(True) Then
			AddInformationAboutTheProgramPath(DiagnosticsInformation,
				NStr("vi = 'Đường dẫn đến mô-đun ứng dụng trên client:';
					|ru = 'Пути к модулям приложения на клиенте:';
					|en = 'Paths to app''s modules on the client:'; fa = 'Paths to app''s modules on the client:';
					|it = 'Пути к модулям приложения на клиенте:';
					|pl = 'Paths to app''s modules on the client:';
					|tr = 'İstemcideki uygulama modüllerine giden yollar:'"),
				VerifiedPathsToProgramModulesOnTheClient.Get(Application.Ref).ApplicationPath);
		EndIf;
		If RequiresThePathToTheProgram() Then
			AddInformationAboutTheProgramPath(DiagnosticsInformation,
				NStr("vi = 'Đường dẫn đến mô-đun ứng dụng trên server:';
					|ru = 'Пути к модулям приложения на сервере:';
					|en = 'Paths to the app modules on the server:'; fa = 'Paths to the app modules on the server:';
					|it = 'Пути к модулям приложения на сервере:';
					|pl = 'Paths to the app modules on the server:';
					|tr = 'Sunucudaki uygulama modüllerine giden yollar:'"),
				ApplicationPath(Application.Ref).ApplicationPath);
		EndIf;
	EndDo;
	
	Return DiagnosticsInformation;
	
EndFunction

Procedure AddInformationAboutTheProgramPath(DiagnosticsInformation, Title, ApplicationPath)
	
	ThePathToTheModules = StrSplit(ApplicationPath, ":", False);
	
	DiagnosticsInformation = DiagnosticsInformation
		+ Chars.Tab + Title + Chars.LF
		+ Chars.Tab + Chars.Tab + """" + StrConcat(ThePathToTheModules,
			"""" + Chars.LF + Chars.Tab + Chars.Tab + """") + """"
		+ Chars.LF;
	
EndProcedure

// Download the revocation list file on server.
// 
// Parameters:
//  Addresses - Array of String
//  InternalAddress - String
// 
// Returns:
//  Structure - Download the revocation list file on server:
//   * FileAddress - String - Address the file was downloaded from. 
//   * FileName - String - file name 
//   * FileData - BinaryData
//   * ErrorMessage - String
//
Function DownloadRevocationListFileAtServer(Val Addresses, InternalAddress = Undefined) Export
	
	ImportResult1 = New Structure;
	ImportResult1.Insert("FileAddress", "");
	ImportResult1.Insert("FileName", "");
	ImportResult1.Insert("FileData", Undefined);
	ImportResult1.Insert("ErrorMessage", "");
	
	If Addresses.Count() = 0 Then
		ImportResult1.ErrorMessage = NStr("vi = 'Trong chứng thư chưa chỉ ra địa chỉ danh sách thu hồi.';
											|ru = 'В сертификате не указаны адреса списков отзыва.';
											|en = 'Revocation list addresses are not specified in the certificate.'; fa = 'Revocation list addresses are not specified in the certificate.';
											|it = 'Nel certificato non sono indicati gli indirizzi degli elenchi di chiamata.';
											|pl = 'W certyfikacie nie są podane adresy list odwołania.';
											|tr = 'İptal listesi adresleri sertifikada belirtilmemiştir.'");
		Return ImportResult1;
	EndIf;
	
	DataFromCache = Undefined;

	If ValueIsFilled(InternalAddress) Then
		DataFromCache = RevocationListDataFromDatabase(InternalAddress);
	
		If ValueIsFilled(DataFromCache.CheckDate) Then
			
			PopulateResultOfRevocationListImportFromCacheData(ImportResult1, DataFromCache);
			
			CheckDate = CurrentUniversalDate();
			
			If ValueIsFilled(ImportResult1.ErrorMessage) Then
				If DataFromCache.CheckDate + 1200 > CheckDate Then 
					// Run check upon error no more than once every 20 minutes.
					Return ImportResult1;
				EndIf;
			Else
				If DataFromCache.CheckDate + 1800 > CheckDate Then
					// Return the file if it was uploaded less than 30 min ago.
					Return ImportResult1;
				EndIf;
			EndIf;
			
			ImportResult1.ErrorMessage = "";
			
		EndIf;
	EndIf;
	
	If ValueIsFilled(InternalAddress) Then
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.CertificateRevocationLists");
		LockItem.SetValue("InternalAddress", InternalAddress);
		
		BeginTransaction();
		
		Try
			IsLockEnabled = True;
 			Block.Lock();
 			IsLockEnabled = False;
			
			NewDataFromCache = RevocationListDataFromDatabase(InternalAddress);
			If NewDataFromCache.CheckDate <> DataFromCache.CheckDate Then
				// Infobase data had been modified before the lock was applied.
				PopulateResultOfRevocationListImportFromCacheData(ImportResult1, NewDataFromCache);
				CommitTransaction();
				Return ImportResult1; 
			EndIf;
			
			LastChangeDate = Date(2021,1,1);
			DownloadRevocationListFile(Addresses, ImportResult1, DataFromCache, LastChangeDate);
			
			SetPrivilegedMode(True);
			RecordManager = InformationRegisters.CertificateRevocationLists.CreateRecordManager();
			
			If ValueIsFilled(DataFromCache) And DataFromCache.LastChangeDate = LastChangeDate And LastChangeDate <> Undefined Then
				
				FillPropertyValues(RecordManager, DataFromCache);
				PopulateResultOfRevocationListImportFromCacheData(ImportResult1, DataFromCache);
				
			ElsIf ImportResult1.FileData = Undefined Then

				If ValueIsFilled(DataFromCache) Then
					// Update the previous revocation list data.
					FillPropertyValues(RecordManager, DataFromCache);
					PopulateResultOfRevocationListImportFromCacheData(ImportResult1, DataFromCache);
				Else
					ImportResult1.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Lỗi khi thử kết nhập tệp:
							 |%1
							 |Chi tiết xem trong Nhật ký sự kiện.';
							 |ru = 'Ошибки при попытке загрузить файл(ы):
							 |%1
							 |Подробности см. в Журнале регистрации.';
							 |en = 'Errors occurred when trying to import file(s):
							 |%1
							 |For more information, see the event log.'; fa = 'Errors occurred when trying to import file(s):
							 |%1
							 |For more information, see the event log.';
							 |it = 'Errori durante il tentativo di importare il/i file:
							 |%1
							 | Per i dettagli, visualizzare il Registro.';
							 |pl = 'Błędy podczas próby przesyłania pliku(ów):
							 |%1
							 |Szczegóły zobacz w Dzienniku rejestracji.';
							 |tr = 'Dosyaları yükleme denemesi sırasında hatalar oluştu:
							 |%1
							 |Ayrıntılar için bkz. Olay günlüğü.'"), StrConcat(Addresses, Chars.LF));
				EndIf;
				
			Else
				
				RevocationListValidityPeriod = DigitalSignatureInternalClientServer.RevocationListProperties(ImportResult1.FileData);
				
				If RevocationListValidityPeriod = Undefined Then
					ImportResult1.FileData = Undefined;
					ImportResult1.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Tệp %1 không phải là danh sách thu hồi.';
							|ru = 'Файл %1 не является списком отзыва.';
							|en = 'This file is not a revocation list: %1.'; fa = 'This file is not a revocation list: %1.';
							|it = 'Файл %1 не является списком отзыва.';
							|pl = 'Plik %1 nie jest listą odwołania.';
							|tr = '%1 dosyası bir geri çekme listesi değildir.'"), ImportResult1.FileAddress);
				Else
					RecordManager.RevocationListAddress = ImportResult1.FileAddress;
					RecordManager.RevocationList = New ValueStorage(ImportResult1.FileData,
						New Deflation(9));
					RecordManager.LastChangeDate = LastChangeDate;
					RecordManager.ValidityStartDate      = RevocationListValidityPeriod.StartDate;
					RecordManager.ValidityEndDate   = RevocationListValidityPeriod.EndDate;
				EndIf;

			EndIf;
			
			RecordManager.InternalAddress = InternalAddress;
			RecordManager.CheckDate = CurrentUniversalDate();
			RecordManager.Write();
			CommitTransaction();

		Except
			
			RollbackTransaction();
			
			If IsLockEnabled Then // Revocation list is being updated.
				If Not ValueIsFilled(DataFromCache) Then
					ImportResult1.ErrorMessage = NStr("vi = 'Danh sách thu hồi đang trong quá trình cập nhật.';
														|ru = 'Список отзыва находится в процессе обновления.';
														|en = 'Revocation list is being updated.'; fa = 'Revocation list is being updated.';
														|it = 'L''elenco di chiamata è in corso di aggiornamento.';
														|pl = 'Lista odwołania jest w trakcie aktualizacji.';
														|tr = 'İptal dosyası güncelleniyor.'");
				EndIf;
			Else
				ErrorInfo = ErrorInfo();
				
				ImportResult1.ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Lỗi khi kết nhập danh sách thu hồi:
						|%1
						|Chi tiết xem trong Nhật ký sự kiện.';
						|ru = 'Ошибки при загрузке списка отзыва:
						|%1
						|Подробности см. в Журнале регистрации.';
						|en = 'An error occurred when importing a revocation list:
						|%1
						|For more information, see the event log.'; fa = 'An error occurred when importing a revocation list:
						|%1
						|For more information, see the event log.';
						|it = 'Errori durante l''importazione dell''elenco di chiamata:
						|%1
						|Per i dettagli, visualizzare il Registro.';
						|pl = 'Błędy podczas przesyłania listy odwołania:
						|%1
						|Szczegóły zobacz w Dzienniku rejestracji.';
						|tr = 'İptal listesini yüklerken hatalar oluştu:
						|%1
						|Ayrıntılar için bkz. Olay günlüğü.'"),
					ErrorProcessing.BriefErrorDescription(ErrorInfo));
					
				WriteLogEvent(
					NStr("vi = 'Chữ ký điện tử. Cập nhật danh sách thu hồi';
						|ru = 'Электронная подпись.Обновление списков отзыва';
						|en = 'Digital signature.Update revocation lists'; fa = 'Digital signature.Update revocation lists';
						|it = 'Firma elettronica. Aggiornamento degli elenchi di chiamata';
						|pl = 'Podpis elektroniczny.Aktualizacja list odwołania';
						|tr = 'Dijital imza.İptal listesini güncelle'",
					Common.DefaultLanguageCode()),
					EventLogLevel.Error, , ,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
			EndIf;
			
			Return ImportResult1;
			
		EndTry;
	Else
		DownloadRevocationListFile(Addresses, ImportResult1);
	EndIf;
	
	Return ImportResult1;

EndFunction


// Intended for: DownloadRevocationListFileAtServer procedure
Procedure DownloadRevocationListFile(Addresses, ImportResult1, DataFromCache = Undefined, LastChangeDate = Undefined)
	
	ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
	ModuleNetworkDownloadClientServer = Common.CommonModule("GetFilesFromInternetClientServer");
	
	For Each CurrentAddress In Addresses Do
		
		If StrStartsWith(Lower(CurrentAddress), "ldap://") Then
			Continue;
		EndIf;
		
		FileGettingParameters = ModuleNetworkDownloadClientServer.FileGettingParameters();
		
		If ValueIsFilled(DataFromCache)
			And ValueIsFilled(DataFromCache.LastChangeDate)
			And DataFromCache.RevocationListAddress = CurrentAddress Then
			
			LastChangeDate = DataFromCache.LastChangeDate;
		EndIf;
		
		If ValueIsFilled(LastChangeDate) Then
			FileGettingParameters.Headers.Insert("If-Modified-Since", 
					CommonClientServer.HTTPDate(LastChangeDate));
		EndIf;
		
		ImportResult1.FileAddress = CurrentAddress;
		Result = ModuleNetworkDownload.DownloadFileAtServer(CurrentAddress, FileGettingParameters);
		
		If Result.StatusCode = 304 And ValueIsFilled(DataFromCache) Then // The file wasn't updated.
			PopulateResultOfRevocationListImportFromCacheData(ImportResult1, DataFromCache);
			Return;
		EndIf;
			
		If Result.Status Then
			LastChangeDate = FileLastModifiedDate(Result);
			
			FileName = RevocationListFilename(CurrentAddress);
			
			PathToFile = Result.Path;
			
			TempDirectory = Undefined;
			If StrEndsWith(FileName, ".zip") Then
				TempDirectory = FileSystem.CreateTemporaryDirectory(
					String(New UUID));
				ZipFileReader = New ZipFileReader(PathToFile);
				
				For Each ArchiveItem In ZipFileReader.Items Do
					FileNameInArchive = ArchiveItem.Name;
					ZipFileReader.Extract(ArchiveItem, TempDirectory);
					PathToFile = TempDirectory + FileNameInArchive;
					FileName = FileNameInArchive;
					Break;
				EndDo;
				
				ZipFileReader.Close();
			EndIf;
			
			Text = New TextDocument;
			Text.Read(PathToFile);
			Base64Row = Undefined;
			
			If Text.LineCount() > 3 And StrStartsWith(Text.GetLine(1), "-----BEGIN")
				And StrStartsWith(Text.GetLine(Text.LineCount()), "-----END") Then
				Text.DeleteLine(1);
				Text.DeleteLine(Text.LineCount());
				Base64Row = Text.GetText();
			ElsIf StrStartsWith(Text.GetLine(1), "MI") Then
				Base64Row = Text.GetText();
			EndIf;
			
			If Base64Row <> Undefined Then
				Try
					BinaryData = Base64Value(Base64Row);
					ImportResult1.FileData = BinaryData;
				Except
					ErrorInfo = ErrorInfo();
					ImportResult1.Insert("ErrorMessage",
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Không thể nhận dữ liệu danh sách thu hồi %1 do nguyên nhân:
							|%2';
							|ru = 'Не удалось получить данные списка отзыва %1 по причине:
							|%2';
							|en = 'Cannot get the %1 revocation list data due to:
							|%2'; fa = 'Cannot get the %1 revocation list data due to:
							|%2';
							|it = 'Cannot get the %1 revocation list data due to:
							|%2';
							|pl = 'Cannot get the %1 revocation list data due to:
							|%2';
							|tr = '%1 geri bildirim listesinin verileri şu nedenden dolayı alınamadı:
							|%2'"), CurrentAddress, ErrorProcessing.BriefErrorDescription(ErrorInfo)));
					WriteLogEvent(
						NStr("vi = 'Chữ ký điện tử. Cập nhật danh sách thu hồi';
							|ru = 'Электронная подпись.Обновление списков отзыва';
							|en = 'Digital signature.Update revocation lists'; fa = 'Digital signature.Update revocation lists';
							|it = 'Firma elettronica. Aggiornamento degli elenchi di chiamata';
							|pl = 'Podpis elektroniczny.Aktualizacja list odwołania';
							|tr = 'Dijital imza.İptal listesini güncelle'",
						Common.DefaultLanguageCode()),
						EventLogLevel.Error, , ,
						ImportResult1.ErrorMessage);
				EndTry;
			Else
				ImportResult1.FileData = New BinaryData(PathToFile);
			EndIf;
			
			ImportResult1.FileName = FileName;
			
			If TempDirectory <> Undefined Then
				FileSystem.DeleteTemporaryDirectory(TempDirectory);
			EndIf;
			FileSystem.DeleteTempFile(Result.Path);
			
			Break;
		Else
			LastChangeDate = Undefined;
			ImportResult1.Insert("ErrorMessage", Result.ErrorMessage);
		EndIf;
	EndDo;
	
EndProcedure

Function RevocationListFilename(RevocationListAddress)
	
	PathAtServer = CommonClientServer.URIStructure(RevocationListAddress).PathAtServer;
	
	PathElements = StrSplit(PathAtServer, "/");
	
	Return CommonClientServer.ReplaceProhibitedCharsInFileName(PathElements[PathElements.UBound()]);

EndFunction

// Intended for: DownloadRevocationListFileAtServer procedure
Function RevocationListDataFromDatabase(InternalAddress)
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	RevocationLists.InternalAddress,
		|	RevocationLists.RevocationList,
		|	RevocationLists.CheckDate,
		|	RevocationLists.RevocationListAddress,
		|	RevocationLists.LastChangeDate,
		|	RevocationLists.ValidityStartDate,
		|	RevocationLists.ValidityEndDate
		|FROM
		|	InformationRegister.CertificateRevocationLists AS RevocationLists
		|WHERE
		|	RevocationLists.InternalAddress = &InternalAddress";
	
	Query.SetParameter("InternalAddress", InternalAddress);
	
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Result = New Structure("InternalAddress, RevocationList, CheckDate, 
		|LastChangeDate, RevocationListAddress, ValidityStartDate, ValidityEndDate");
	
	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		FillPropertyValues(Result, SelectionDetailRecords);
	EndDo;
	
	Return Result;
	
EndFunction

// Intended for: DownloadRevocationListFileAtServer procedure
Procedure PopulateResultOfRevocationListImportFromCacheData(ImportResult1, DataFromCache)
	
	If Not ValueIsFilled(DataFromCache.RevocationList) Then
		
		ImportResult1.FileAddress = Undefined;
		ImportResult1.FileName = Undefined;
		ImportResult1.FileData = Undefined;
		ImportResult1.ErrorMessage = NStr("vi = 'Chưa kết nhập danh sách thu hồi.';
											|ru = 'Список отзыва не загружен.';
											|en = 'Revocation list is not imported.'; fa = 'Revocation list is not imported.';
											|it = 'Elenco di chiamata non importato.';
											|pl = 'Lista odwołanie nie została przesłana.';
											|tr = 'İptal listesi yüklenmedi.'");
		Return;
		
	EndIf;
	
	FileData = DataFromCache.RevocationList.Get();
	
	If Not ValueIsFilled(FileData) Then
		
		ImportResult1.FileAddress = Undefined;
		ImportResult1.FileName = Undefined;
		ImportResult1.FileData = Undefined;
		ImportResult1.ErrorMessage = NStr("vi = 'Chưa kết nhập danh sách thu hồi.';
											|ru = 'Список отзыва не загружен.';
											|en = 'Revocation list is not imported.'; fa = 'Revocation list is not imported.';
											|it = 'Elenco di chiamata non importato.';
											|pl = 'Lista odwołanie nie została przesłana.';
											|tr = 'İptal listesi yüklenmedi.'");
		Return;
		
	EndIf;
	
	If Not ValueIsFilled(DataFromCache.ValidityEndDate) 
		Or DataFromCache.ValidityEndDate < CurrentUniversalDate() Then
		
		ImportResult1.FileAddress = Undefined;
		ImportResult1.FileName = Undefined;
		ImportResult1.FileData = Undefined;
		ImportResult1.ErrorMessage = NStr("vi = 'Đã thu hồi danh sách thu hồi. Hãy liên hệ với trung tâm chứng thực cấp chứng thư.';
											|ru = 'Список отзыва просрочен. Обратитесь в удостоверяющий центр, выдавший сертификат.';
											|en = 'The certificate revocation list is expired. Contact the certificate issuer.'; fa = 'The certificate revocation list is expired. Contact the certificate issuer.';
											|it = 'Список отзыва просрочен. Обратитесь в удостоверяющий центр, выдавший сертификат.';
											|pl = 'The certificate revocation list is expired. Contact the certificate issuer.';
											|tr = 'Geri çekme listesinin süresi doldu. Sertifikayı veren sertifika yetkilisine başvurun.'");
		Return;
		
	EndIf;
	
	ImportResult1.FileAddress = DataFromCache.RevocationListAddress;
	ImportResult1.FileName = RevocationListFilename(DataFromCache.RevocationListAddress);
	If StrEndsWith(ImportResult1.FileName, ".zip") Then
		ImportResult1.FileName = StrReplace(ImportResult1.FileName, ".zip", ".crl");
	EndIf;
	ImportResult1.FileData = FileData;
	
EndProcedure

Function CertificatesChain(Val Certificate, FormIdentifier = Undefined, ComponentObject = Undefined) Export
	
	Certificate = CertificateBase64String(Certificate);
	Result = New Structure("Certificates, Error", New Array, ""); 
	
	Try
		If ComponentObject = Undefined Then
			ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
		EndIf;
		
		CertificatesResult = ComponentObject.GetCertificateChain(Certificate);
		
		Error = ComponentObject.ErrorList;
		If ValueIsFilled(Error) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể nhận vòng lặp chứng thư: %1 (%2).';
					|ru = 'Не удалось получить цепочку сертификатов: %1 (%2).';
					|en = 'Cannot receive the certificate chain: %1 (%2).'; fa = 'Cannot receive the certificate chain: %1 (%2).';
					|it = 'Не удалось получить цепочку сертификатов: %1 (%2).';
					|pl = 'Cannot receive the certificate chain: %1 (%2).';
					|tr = 'Sertifika zinciri alınamadı: %1 (%2).'"), Error, ComputerName());
		EndIf;
		
		If CertificatesResult = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể nhận vòng lặp chứng thư (%1).';
					|ru = 'Не удалось получить цепочку сертификатов (%1).';
					|en = 'Cannot receive the certificate chain (%1).'; fa = 'Cannot receive the certificate chain (%1).';
					|it = 'Не удалось получить цепочку сертификатов (%1).';
					|pl = 'Cannot receive the certificate chain (%1).';
					|tr = 'Sertifika zinciri alınamadı (%1).'"), ComputerName());
		EndIf;
		
		Result = DigitalSignatureInternalClientServer.CertificatesChainFromAddInResponse(
			CertificatesResult, FormIdentifier);
	Except
		Result.Error = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return Result;
	EndTry;

	Return Result;
	
EndFunction

Function CertificatePropertiesExtended(Val Certificate, FormIdentifier = Undefined, ComponentObject = Undefined) Export
	
	Certificate = CertificateBase64String(Certificate);
	
	Result = New Structure("Error, CertificateProperties, CertificateBase64String", "");
	Result.CertificateBase64String = Certificate;
		
	Try
		
		CertificateProperties = New Structure;
		CertificateProperties.Insert("AddressesOfRevocationLists", New Array);
		
		If ComponentObject = Undefined Then
			ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
		EndIf;
	
		CertificatePropertiesResult = ComponentObject.GetCertificateProperties(Certificate);
		
		CertificateProperties = DigitalSignatureInternalClientServer.CertificatePropertiesFromAddInResponse(
			CertificatePropertiesResult);
	
		Result.CertificateProperties = CertificateProperties;
		
	Except
		
		Result.Error = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể nhận thuộc tính mở rộng của chứng thư: %1';
				|ru = 'Невозможно получить расширенные свойства сертификата: %1';
				|en = 'Unable to retrieve extended certificate properties: %1'; fa = 'Unable to retrieve extended certificate properties: %1';
				|it = 'Unable to retrieve extended certificate properties: %1';
				|pl = 'Unable to retrieve extended certificate properties: %1';
				|tr = 'Detaylandırılmış sertifika özellikleri alınamıyor: %1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return Result;
		
	EndTry;
	
	Return Result;
	
EndFunction

// Base64String certificate.
// 
// Parameters:
//  Certificate - BinaryData
//             - String - Address in the temp storage.
//             - String - Certificate in the Base64String format.
//             - CryptoCertificate
// 
// Returns:
//  String - Base64String certificate
//
Function CertificateBase64String(Val Certificate)
	
	If TypeOf(Certificate) = Type("String") And IsTempStorageURL(Certificate) Then
		Certificate = GetFromTempStorage(Certificate);
	EndIf;

	If TypeOf(Certificate) = Type("String") Then
		Return Certificate;
	EndIf;
	
	If TypeOf(Certificate) = Type("CryptoCertificate") Then
		Certificate = Certificate.Unload();
	EndIf;
	
	Certificate = Base64String(Certificate);
	Certificate = StrReplace(Certificate, Chars.CR, "");
	Certificate = StrReplace(Certificate, Chars.LF, "");

	Return Certificate;
	
EndFunction

Function FileLastModifiedDate(ImportResult1) Export
	
	Headers = Undefined;
	If TypeOf(ImportResult1) = Type("Structure") Then
		Headers = CommonClientServer.StructureProperty(ImportResult1, "Headers", Undefined);
	ElsIf TypeOf(ImportResult1) = Type("HTTPResponse") Then
		Headers = ImportResult1.Headers;
	EndIf;
	
	If Headers = Undefined Then
		Return Undefined;
	EndIf;
	
	Headers = StandardSubsystemsServer.HTTPHeadersInLowercase(Headers);
	DateLastModifiedString = Headers["last-modified"];
	If DateLastModifiedString <> Undefined Then
		Return CommonClientServer.RFC1123Date(DateLastModifiedString);
	EndIf;
	
	Return Undefined;

EndFunction

Function SupplementErrorClassifierSolutionWithDetails(ClassifierError,
	AdditionalData, ErrorLocation = Undefined) Export

	If Not ValueIsFilled(ClassifierError.RemedyActions) Then
		Return ClassifierError;
	EndIf;

	Decision = New Array;
	Cause = New Array;
	If ClassifierError.RemedyActions.Find(
					"MentionLinkToCAInSolution") <> Undefined Then
		CertificateIssuer = CertificateIssuer(AdditionalData.CertificateData);
		If ValueIsFilled(CertificateIssuer) Then

			Decision.Add(ClassifierError.Decision);
			Decision.Add(Chars.LF);
			Decision.Add(StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Trung tâm chứng thực cấp chứng thư: %1.';
								|ru = 'Удостоверяющий центр, выдавший сертификат: %1.';
								|en = 'Certificate authority that issued the certificate: %1.'; fa = 'Certificate authority that issued the certificate: %1.';
								|it = 'Удостоверяющий центр, выдавший сертификат: %1.';
								|pl = 'Certificate authority that issued the certificate: %1.';
								|tr = 'Sertifikayı veren belgelendirme kuruluşu: %1.'"), CertificateIssuer));
		EndIf;
	EndIf;

	If ClassifierError.RemedyActions.Find(
					"TimestampServersDiagnosticsServer") <> Undefined Then

		Decision.Add(StringFunctions.FormattedString(
			NStr("vi = '<a href = ""%1"">Hãy kiểm tra tính khả dụng</a> của máy chủ dấu thời gian trên máy chủ %2.';
				|ru = '<a href = ""%1"">Проверьте доступность</a> серверов меток времени на сервере %2.';
				|en = '<a href = ""%1"">Check the availability</a> of timestamps on server %2.'; fa = '<a href = ""%1"">Check the availability</a> of timestamps on server %2.';
				|it = '<a href = ""%1"">Проверьте доступность</a> серверов меток времени на сервере %2.';
				|pl = '<a href = ""%1"">Check the availability</a> of timestamps on server %2.';
				|tr = '%2 Sunucudaki zaman damgası</a> sunucusunun kullanılabilirliğini kontrol edin<a href = ""%1"">'"),
			"TimestampServersDiagnosticsServer", ComputerName()));
	EndIf;

	If ClassifierError.RemedyActions.Find(
					"TimestampServersDiagnosticsClient") <> Undefined Then

		If Common.IsWebClient() Then
			
			TimestampServersAddresses = DigitalSignature.CommonSettings().TimestampServersAddresses;
			
			Array = New Array;
			
			For Each ServerAddress In TimestampServersAddresses Do
				
				RefStructure = CommonClientServer.URIStructure(ServerAddress);
				Array.Add(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '<a href = ""%1"">%1</a>';
						|ru = '<a href = ""%1"">%1</a>';
						|en = '<a href = ""%1"">%1</a>'; fa = '<a href = ""%1"">%1</a>';
						|it = '<a href = ""%1"">%1</a>';
						|pl = '<a href = ""%1"">%1</a>';
						|tr = '<a href = ""%1"">%1</a>'"), ServerAddress));
				
			EndDo;
			
			Decision.Add(StringFunctions.FormattedString(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Hãy kiểm tra tính khả dụng của máy chủ dấu thời gian trên máy tính: %1.';
						|ru = 'Проверьте доступность серверов меток времени на компьютере: %1.';
						|en = 'Check the availability of timestamps on computer: %1.'; fa = 'Check the availability of timestamps on computer: %1.';
						|it = 'Проверьте доступность серверов меток времени на компьютере: %1.';
						|pl = 'Check the availability of timestamps on computer: %1.';
						|tr = 'Bilgisayarınızdaki zaman damgası sunucularının kullanılabilirliğini kontrol edin: %1.'"),
					StrConcat(Array, ", "))));
			
		Else
			Decision.Add(StringFunctions.FormattedString(
				NStr("vi = '<a href = ""%1"">Hãy kiểm tra tính khả dụng</a> của máy chủ dấu thời gian trên máy tính.';
					|ru = '<a href = ""%1"">Проверьте доступность</a> серверов меток времени на компьютере.';
					|en = '<a href = ""%1"">Check the availability</a> of timestamps on computer.'; fa = '<a href = ""%1"">Check the availability</a> of timestamps on computer.';
					|it = '<a href = ""%1"">Проверьте доступность</a> серверов меток времени на компьютере.';
					|pl = '<a href = ""%1"">Check the availability</a> of timestamps on computer.';
					|tr = 'Bilgisayarınızdaki zaman damgası sunucularının </a> kullanılabilirliğini kontrol edin: <a href = ""%1"">.'"),
					"TimestampServersDiagnosticsClient"));
		EndIf;

	EndIf;

	If Decision.Count() > 0 Then
		ClassifierError.Decision = New FormattedString(Decision);
	EndIf;
	
	If Cause.Count() > 0 Then
		ClassifierError.Cause = New FormattedString(Cause);
	EndIf;

	Return ClassifierError;

EndFunction

Function CertificateIssuer(CertificateData)
	
	If Not ValueIsFilled(CertificateData) Then
		Return Undefined;
	EndIf;
	
	If ValueIsFilled(CertificateData) Then
		CertificateAuthorityProperties = DigitalSignature.CertificateIssuerProperties(New CryptoCertificate(CertificateData));
		Return CertificateAuthorityProperties.CommonName;
	EndIf;
	
	Return Undefined;
EndFunction

Procedure SetListOfCertificateRevocation(Certificate, Addresses = Undefined, InternalAddress = Undefined) Export
	
	ComponentObject = AnObjectOfAnExternalComponentOfTheExtraCryptoAPI();
	
	If TypeOf(ComponentObject) = Type("String") Then
		Raise ComponentObject;
	EndIf;
	
	If ValueIsFilled(Addresses) Then
		If TypeOf(Addresses) = Type("String") Then
			Addresses = StrSplit(Addresses, ";");
		EndIf;
	Else
		Addresses = New Array;
	EndIf;
	
	AddressesOfRevocationLists = AddressesOfRevocationLists(Certificate, ComponentObject);
	If TypeOf(AddressesOfRevocationLists) = Type("String") And Not ValueIsFilled(Addresses) Then
		Raise AddressesOfRevocationLists;
	EndIf;
	
	For Each Address In AddressesOfRevocationLists Do
		If Addresses.Find(Address) = Undefined Then
			Addresses.Add(Address);
		EndIf;
	EndDo;
	
	Result = DownloadRevocationListFileAtServer(Addresses, InternalAddress);
	
	If ValueIsFilled(Result.ErrorMessage) Then
		Raise Result.ErrorMessage;
	EndIf;
	
	InstallResult = False;
	ErrorDescription = "";
	
	FileData = Result.FileData;
	
	RevocationListProperties = DigitalSignatureInternalClientServer.RevocationListProperties(FileData);
	
	If RevocationListProperties = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tệp %1 không phải là danh sách thu hồi.';
				|ru = 'Файл %1 не является списком отзыва.';
				|en = 'This file is not a revocation list: %1.'; fa = 'This file is not a revocation list: %1.';
				|it = 'Файл %1 не является списком отзыва.';
				|pl = 'Plik %1 nie jest listą odwołania.';
				|tr = '%1 dosyası bir geri çekme listesi değildir.'"), Result.FileAddress);
	EndIf;
	
	If ValueIsFilled(RevocationListProperties.EndDate) And RevocationListProperties.EndDate < CurrentUniversalDate() Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Danh sách thu hồi %1 đã quá hạn. Hãy liên hệ với trung tâm chứng thực cấp chứng chỉ.';
				|ru = 'Список отзыва %1 просрочен. Обратитесь в удостоверяющий центр, выдавший сертификат.';
				|en = 'The certificate revocation list %1 is expired. Contact the certificate issuer.'; fa = 'The certificate revocation list %1 is expired. Contact the certificate issuer.';
				|it = 'Список отзыва %1 просрочен. Обратитесь в удостоверяющий центр, выдавший сертификат.';
				|pl = 'The certificate revocation list %1 is expired. Contact the certificate issuer.';
				|tr = 'Geri çekme listesinin %1 süresi doldu. Sertifikayı veren sertifika yetkilisine başvurun.'"), Result.FileAddress);
	EndIf;
	
	TempFileName = GetTempFileName(".crl");
	FileData.Write(TempFileName);
	
	Try
		ComponentObject.ImportCRu(TempFileName, "CA");
		InstallResult = True;
	Except
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		InstallResult = False;
	EndTry;
	
	FileSystem.DeleteTempFile(TempFileName);
	
	If Not InstallResult Then
		Raise ErrorDescription;
	EndIf;
	
EndProcedure

Function AddressesOfRevocationLists(Certificate, ComponentObject)

	CertificatePropertiesExtended = CertificatePropertiesExtended(Certificate, ComponentObject);

	If ValueIsFilled(CertificatePropertiesExtended.Error) Then
		Return CertificatePropertiesExtended.Error;
	EndIf;

	AddressesOfRevocationLists = CertificatePropertiesExtended.CertificateProperties.AddressesOfRevocationLists;
	If AddressesOfRevocationLists.Count() = 0 Then
		Return NStr("vi = 'Trong chứng thư chưa chỉ ra địa chỉ danh sách thu hồi.';
					|ru = 'В сертификате не указаны адреса списков отзыва.';
					|en = 'Revocation list addresses are not specified in the certificate.'; fa = 'Revocation list addresses are not specified in the certificate.';
					|it = 'В сертификате не указаны адреса списков отзыва.';
					|pl = 'W certyfikacie nie są podane adresy list odwołania.';
					|tr = 'Geri çekme listesi adresleri sertifikada belirtilmemiştir.'");
	EndIf;
	
	Return AddressesOfRevocationLists;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// Replaces in all profiles the role AddEditDigitalSignaturesAndEncryption with the roles:
// AddEditDigitalSignatures, AddEditDigitalSignatureAndEncryptionKeyCertificates,
// and EncryptAndDecryptData.
//
Procedure ReplaceRoleAddingChangeElectronicSignaturesAndEncryption() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	
	NewRoles = New Array;
	NewRoles.Add("AddEditDigitalSignatures");
	NewRoles.Add("EncryptAndDecryptData");
	NewRoles.Add("AddEditDigitalSignatureAndEncryptionKeyCertificates");
	RolesToReplace = New Map;
	RolesToReplace.Insert("? AddEditDigitalSignaturesAndEncryption", NewRoles);
	
	ModuleAccessManagement.ReplaceRolesInProfiles(RolesToReplace);
	
EndProcedure

// Adds role ReadKeyCertificatesOfDigitalSignatureAndEncryption to all profiles that include
// roles AddEditDigitalSignatures and EncryptAndDecryptData.
//
Procedure AddRoleReadKeyCertificatesOfDigitalSignatureAndEncryption() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	RoleToAddName = Metadata.Roles.ReadElectronicSignatureAndEncryptionKeyCertificates.Name;
	RoleNameAddEditDigitalSignatures = Metadata.Roles.AddEditDigitalSignatures.Name;
	RoleNameEncryptAndDecryptData = Metadata.Roles.EncryptAndDecryptData.Name;
	RoleNameDataDecryption = Metadata.Roles.DataDecryption.Name;
	
	NewRolesToAddChangeDigitalSignatures = New Array;
	NewRolesToAddChangeDigitalSignatures.Add(RoleToAddName);
	NewRolesToAddChangeDigitalSignatures.Add(RoleNameAddEditDigitalSignatures);
	
	NewRolesToEncryptAndDecryptData = New Array;
	NewRolesToEncryptAndDecryptData.Add(RoleToAddName);
	NewRolesToEncryptAndDecryptData.Add(RoleNameEncryptAndDecryptData);
	
	NewRolesToDataDecryption = New Array;
	NewRolesToDataDecryption.Add(RoleToAddName);
	NewRolesToDataDecryption.Add(RoleNameDataDecryption);
	
	RolesToReplace = New Map;
	RolesToReplace.Insert(RoleNameAddEditDigitalSignatures, NewRolesToAddChangeDigitalSignatures);
	RolesToReplace.Insert(RoleNameEncryptAndDecryptData, NewRolesToEncryptAndDecryptData);
	RolesToReplace.Insert(RoleNameDataDecryption, NewRolesToDataDecryption);
	
	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	ModuleAccessManagement.ReplaceRolesInProfiles(RolesToReplace);
	
EndProcedure

#EndRegion

#Region CertificateContents

// Extended data for certificate print.
// 
// Parameters:
//  Data - BinaryData - Certificate data.
// 
// Returns:
//  Structure - Extended data for printing the certificate:
//   * IdentificationType - Number
//   * CIPF - String
//   * ClosingStatement - String
//   * CIPF_UC - String
//   * Conclusion - String
//   * Signature - BinaryData
//
Function ExtendedDataForCertificatePrint(Data) Export
	
	Structure = New Structure("IdentificationType, CIPF, ClosingStatement, CIPF_UC, Conclusion, Signature, UsingTheKey");
	
	DataAnalysis = DigitalSignatureInternalClientServer.NewDataAnalysis(Data);
	// SEQUENCE (Certificate).
	DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 16);
		// SEQUENCE (tbsCertificate).
		DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 16);
			// [0] EXPLICIT (version).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 2, 0);
			// INTEGER  (serialNumber         CertificateSerialNumber).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 2);
			// SEQUENCE (signature            AlgorithmIdentifier).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 16);
			// SEQUENCE (issuer               Name).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 16);
			// SEQUENCE (validity             Validity).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 16);
			// SEQUENCE (subject              Name).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 16);
			// SEQUENCE (subjectPublicKeyInfo SubjectPublicKeyInfo).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 16);
			// [1] IMPLICIT UniqueIdentifier OPTIONAL (issuerUniqueID).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 2, 1, False);
			// [2] IMPLICIT UniqueIdentifier OPTIONAL (subjectUniqueID).
			DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 2, 2, False);
			// [3] EXPLICIT SEQUENCE SIZE (1..MAX) OF Extension (extensions). 
			DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 2, 3);
				// SEQUENCE OF
				DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 16);
				OffsetOfTheFollowing = DataAnalysis.Parents[0].OffsetOfTheFollowing;
				While DataAnalysis.Offset < OffsetOfTheFollowing Do
					// SEQUENCE (extension).
					DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 16);
					If DataAnalysis.HasError Then
						Break;
					EndIf; 
						// OBJECT IDENTIFIER
						DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 6);
							DataSize = DataAnalysis.Parents[0].DataSize;
							Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
							BufferString = GetHexStringFromBinaryDataBuffer(Buffer); // ID
						DigitalSignatureInternalClientServer.SkipTheParentBlock(DataAnalysis); // OBJECT IDENTIFIER

						If BufferString = "2A85036470" Then // 1.2.643.100.112
							DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 4); // OCTET STRING
								// IssuerSignTool ::= SEQUENCE {
								//  signTool     UTF8String SIZE(1..200),
								//  cATool       UTF8String SIZE(1..200),
								//  signToolCert UTF8String SIZE(1..100),
								//  cAToolCert   UTF8String SIZE(1..100) }.
								// SEQUENCE (IssuerSignTool).
								DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 16); // SEQUENCE
									Structure.CIPF = StringUTF8(DataAnalysis);
									Structure.CIPF_UC = StringUTF8(DataAnalysis);
									Structure.ClosingStatement = StringUTF8(DataAnalysis);
									Structure.Conclusion = StringUTF8(DataAnalysis);
								DataAnalysis.Parents.Delete(0); // SEQUENCE
							DataAnalysis.Parents.Delete(0); // OCTET STRING
						ElsIf BufferString = "2A85036472" Then // 1.2.643.100.114
							DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 4); // OCTET STRING
								DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 2); // INTEGER
									Structure.IdentificationType = DigitalSignatureInternalClientServer.ToReadTheWholeStream(DataAnalysis);
								DataAnalysis.Parents.Delete(0); // INTEGER
							DataAnalysis.Parents.Delete(0); // OCTET STRING
						ElsIf BufferString = "551D0F" Then // 2.5.29.15 keyUsage
							DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 1, False); // BOOLEAN
								DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 4); // OCTET STRING
								DataSize = DataAnalysis.Parents[0].DataSize;
								Structure.UsingTheKey = GetHexStringFromBinaryDataBuffer(
									DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize));
								
							DataAnalysis.Parents.Delete(0); // OCTET STRING
						EndIf;
					DigitalSignatureInternalClientServer.SkipTheParentBlock(DataAnalysis); // SEQUENCE
				EndDo; 
				DigitalSignatureInternalClientServer.SkipTheParentBlock(DataAnalysis); // SEQUENCE OF
			DigitalSignatureInternalClientServer.SkipTheParentBlock(DataAnalysis); // EXPLICIT SEQUENCE
		DigitalSignatureInternalClientServer.SkipTheParentBlock(DataAnalysis); // SEQUENCE (tbsCertificate)
	DigitalSignatureInternalClientServer.SkipBlock(DataAnalysis, 0, 16); // signatureAlgorithm
	
	DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 3); // signatureValue
	If Not DataAnalysis.HasError Then
		DataSize = DataAnalysis.Parents[0].DataSize;
		Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
		Structure.Signature = GetBinaryDataFromBinaryDataBuffer(Buffer);
	Else 
		Raise NStr("vi = 'Đã xảy ra trường hợp không mong muốn khi đọc dữ liệu mở rộng của chứng thư.';
					|ru = 'Непредвиденная ситуация при чтении расширенных данных сертификата.';
					|en = 'An unexpected error occurred when reading the extended certificate data.'; fa = 'An unexpected error occurred when reading the extended certificate data.';
					|it = 'Situazione imprevista durante la lettura dei dati estesi del buono.';
					|pl = 'Nieprzewidziana sytuacja podczas odczytu rozszerzonych danych certyfikatu.';
					|tr = 'Genişletilmiş sertifika verileri okunurken beklenmeyen bir durum oluştu.'");
	EndIf;

	Return Structure;
	
EndFunction

Function StringUTF8(DataAnalysis)
	
	DigitalSignatureInternalClientServer.SkipBlockStart(DataAnalysis, 0, 12); // UTF8String
	
	DataSize = DataAnalysis.Parents[0].DataSize;
	Buffer = DataAnalysis.Buffer.Read(DataAnalysis.Offset, DataSize); // BinaryDataBuffer
	String = GetStringFromBinaryDataBuffer(Buffer, "UTF-8");
	
	DigitalSignatureInternalClientServer.SkipTheParentBlock(DataAnalysis); // UTF8String
	
	Return String;
	
EndFunction

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("ReplaceRoleAddingChangeElectronicSignaturesAndEncryption");
	Methods.Insert("FillinSettingsToImproveSignatures");
	Methods.Insert("EnableConstantAllowAccessToInternetServices");
	Methods.Insert("FillinServerAddressesTimestamps");
	Methods.Insert("AddRoleReadKeyCertificatesOfDigitalSignatureAndEncryption");
	Methods.Insert("EnhanceServerSide", True);
	Methods.Insert("DownloadRevocationListFileAtServer", True);
	
EndProcedure

#EndRegion