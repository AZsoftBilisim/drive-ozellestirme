///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SignatureProperties = DigitalSignatureClientServer.ResultOfSignatureValidationOnForm();
	FillPropertyValues(SignatureProperties, Parameters.SignatureProperties);
	
	FillPropertyValues(ThisObject, SignatureProperties);
	FillPropertyValues(ThisObject, SignatureProperties.CheckResult);
	
	If Parameters.SignatureProperties.Property("Object") Then
		SignedObject = Parameters.SignatureProperties.Object;
	EndIf;
	
	Items.GroupMachineReadableLOA.Visible = False;
	
	// StandardSubsystems.MachineReadableLettersOfAuthority
	
	If Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		ModuleMachineReadableLettersOfAuthorityFTSInternal = Common.CommonModule(
			"MachineReadableLettersOfAuthorityFTSInternal");
		If Parameters.SignatureProperties.Property("MachineReadableLetterOfAuthority") And ValueIsFilled(
			Parameters.SignatureProperties.MachineReadableLetterOfAuthority) Then
			Items.GroupMachineReadableLOA.Visible = True;
			Items.MachineReadableLOADecoration.Title = Parameters.SignatureProperties.MachineReadableLetterOfAuthority;
			ModuleMachineReadableLettersOfAuthorityFTSInternal.FillInVerificationProtocol(ThisObject, Items.GroupCheckProtocol,
				Parameters.SignatureProperties.ResultOfSignatureVerificationByMRLOA);
		EndIf;
	EndIf;
	
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
	Items.AdditionalAttributesManualCheckJustification.Visible = ValueIsFilled(AdditionalAttributesManualCheckJustification)
		And StrLen(AdditionalAttributesManualCheckJustification) > 100;
	
	If ValueIsFilled(SignatureMathValidationError)
		Or ValueIsFilled(AdditionalAttributesCheckError)
		Or ValueIsFilled(ErrorDescription) Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "ErrorDescription");
	ElsIf ValueIsFilled(AdditionalAttributesManualCheckJustification) Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "ManualVerification");
	Else
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "");
	EndIf;
	
	If Not IsTempStorageURL(SignatureAddress) Then
		Return;
	EndIf;
	
	SignatureData = GetFromTempStorage(SignatureAddress);
	
	If Not ValueIsFilled(SignatureData) Then
		Return;
	EndIf;
	
	SignAlgorithmDoesNotComplyWithGOST = "";
	SignAlgorithm = DigitalSignatureInternalClientServer.GeneratedSignAlgorithm(
		SignatureData, True, False, SignAlgorithmDoesNotComplyWithGOST);
		
	If ValueIsFilled(SignAlgorithmDoesNotComplyWithGOST) Then
		SignAlgorithm = SignAlgorithmDoesNotComplyWithGOST;
		Items.SignAlgorithm.Visible = False;
		Items.SignAlgorithmWarning.Visible = True;
	Else
		Items.SignAlgorithm.Visible = True;
		Items.SignAlgorithmWarning.Visible = False;
	EndIf;
	
	HashAlgorithm = DigitalSignatureInternalClientServer.HashAlgorithm(
		SignatureAddress, True);
	
	If ValueIsFilled(Status) Then
		Items.DecorationStatus.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trạng thái vào %1: %2';
					|ru = 'Статус на %1: %2';
					|en = 'Status as of %1: %2'; fa = 'Status as of %1: %2';
					|it = 'Статус на %1: %2';
					|pl = 'Status as of %1: %2';
					|tr = 'Durum %1: %2'"), SignatureValidationDate, Status);
	ElsIf ValueIsFilled(BriefCheckResult) Then
		Items.DecorationStatus.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trạng thái vào %1: %2';
					|ru = 'Статус на %1: %2';
					|en = 'Status as of %1: %2'; fa = 'Status as of %1: %2';
					|it = 'Статус на %1: %2';
					|pl = 'Status as of %1: %2';
					|tr = 'Durum %1: %2'"), SignatureValidationDate, BriefCheckResult);
	Else
		Items.DecorationStatus.Visible = False;
	EndIf;
	
	Items.ErrorDescription.Visible = Not IsBlankString(ErrorDescription);
	Items.Comment.Visible = Not IsBlankString(Comment);
	
	Items.GroupMathValidationError.Visible   = Not IsBlankString(SignatureMathValidationError);
	Items.GroupErrorOnAdditionalAttributesManualCheck.Visible = Not IsBlankString(AdditionalAttributesCheckError);
	
	UpdateFormData();
		
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// StandardSubsystems.MachineReadableLettersOfAuthority

&AtClient
Procedure Attachable_CommandMarkManually(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		ModuleMachineReadableLettersOfAuthorityFTSInternalClient = CommonClient.CommonModule(
			"MachineReadableLettersOfAuthorityFTSInternalClient");
		ModuleMachineReadableLettersOfAuthorityFTSInternalClient.AddMarkAuthorizationLetterIsCorrect(ThisObject, Item.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_URLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If CommonClient.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		ModuleMachineReadableLettersOfAuthorityFTSInternalClient = CommonClient.CommonModule(
			"MachineReadableLettersOfAuthorityFTSInternalClient");
		ModuleMachineReadableLettersOfAuthorityFTSInternalClient.SignatureVerificationErrorsWhenProcessingNavigationLink(
			ThisObject, FormattedStringURL, StandardProcessing);
	EndIf;
	
EndProcedure

// End StandardSubsystems.MachineReadableLettersOfAuthority

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveToFile(Command)
	
	DigitalSignatureClient.SaveSignature(SignatureAddress);
	
EndProcedure

&AtClient
Procedure OpenCertificate(Command)
	
	If ValueIsFilled(CertificateAddress) Then
		DigitalSignatureClient.OpenCertificate(CertificateAddress);
		
	ElsIf ValueIsFilled(Thumbprint) Then
		DigitalSignatureClient.OpenCertificate(Thumbprint);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenCertificateToVerifySignature(Command)
	
	If Not ArePropertiesRead Or ValueIsFilled(SignatureReadError) Then
		DigitalSignatureClient.ReadSignatureProperties(
			New CallbackDescription("AfterSignaturePropertiesRead", ThisObject), SignatureAddress);
		Return;
	Else
		OpenCertificateRead();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExtendActionSignature(Command)
	
	FollowUpHandler = New CallbackDescription("AfterImprovementSignature", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("SignatureType", SignatureType);
	FormParameters.Insert("DataPresentation", 
		StrTemplate("%1, %2, %3", CertificateOwner, SignatureDate, SignatureType));
		
	If ValueIsFilled(SignedObject) Then
		Structure = New Structure;
		Structure.Insert("Signature", SignatureAddress);
		Structure.Insert("SignedObject", SignedObject);
		Structure.Insert("SequenceNumber", SequenceNumber); 
		FormParameters.Insert("Signature", Structure);
	Else
		FormParameters.Insert("Signature", SignatureAddress);
	EndIf;
	
	DigitalSignatureClient.OpenRenewalFormActionsSignatures(ThisObject, FormParameters, FollowUpHandler);
	
EndProcedure

&AtClient
Procedure OpenMathValidationErrorDetails(Command)
	
	OpenErrorDescription(SignatureMathValidationError);
	
EndProcedure

&AtClient
Procedure OpenAdditionalAttributesErrorDetails(Command)
	
	OpenErrorDescription(AdditionalAttributesCheckError);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenErrorDescription(ErrorText)
	
	FormParameters = New Structure;
	FormParameters.Insert("WarningTitle", NStr("vi = 'Kiểm tra chữ ký';
												|ru = 'Проверка подписи';
												|en = 'Signature verification'; fa = 'Signature verification';
												|it = 'Проверка подписи';
												|pl = 'Sprawdzenie podpisu';
												|tr = 'Oluşturulan imzanın kontrolü'"));
	FormParameters.Insert("ErrorTextClient", ErrorText);
	FormParameters.Insert("ShowNeedHelp", True);
	FormParameters.Insert("ShowInstruction", True);
	
	AdditionalParameters = New Structure;
	
	If ValueIsFilled(CertificateAddress) Then
		AdditionalParameters.Insert("CertificateData",
			CertificateAddress);
	EndIf;
	
	If ValueIsFilled(SignatureAddress) Then
		AdditionalParameters.Insert("SignatureData",
			SignatureAddress);
	EndIf;
		
	FormParameters.Insert("AdditionalData", AdditionalParameters);
	
	DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(FormParameters, ThisObject);

EndProcedure

&AtServer
Procedure UpdateFormData()
	
	If DigitalSignature.AddEditDigitalSignatures() Then
		If (ValueIsFilled(DateActionLastTimestamp) And DateActionLastTimestamp <= CurrentSessionDate())
			Or SignatureType = Enums.CryptographySignatureTypes.NormalCMS Or Not SignatureCorrect Then
			Items.FormExtendActionSignature.Visible = False;
		Else
			Items.FormExtendActionSignature.Visible = True;
		EndIf;
	Else
		Items.FormExtendActionSignature.Visible = False;
	EndIf;
		
	If SignatureType = Enums.CryptographySignatureTypes.BasicCAdESBES
		Or SignatureType = Enums.CryptographySignatureTypes.NormalCMS Then
		If ValueIsFilled(DateActionLastTimestamp) Then
			Items.DateActionLastTimestamp.Title = NStr("vi = 'Đã quá hạn hiệu lực chứng chỉ chữ ký';
														|ru = 'Срок действия сертификата подписи истек';
														|en = 'Certificate expired'; fa = 'Certificate expired';
														|it = 'Periodo di validità del certificato di firma scaduto';
														|pl = 'Termin ważności certyfikatu podpisu upłynął';
														|tr = 'İmza sertifikasının geçerlilik dönemi sona erdi'"); 
		Else
			Items.DateActionLastTimestamp.Visible = False;
		EndIf;
	Else
		Items.DateActionLastTimestamp.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterImprovementSignature(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Success Then
		
		For Each KeyAndValue In Result.PropertiesSignatures[0].SignatureProperties Do
			If KeyAndValue.Key = "Signature" Then
				SignatureAddress = PutToTempStorage(KeyAndValue.Value);
				Continue;
			EndIf;
			If KeyAndValue.Value = Undefined Then
				Continue;
			EndIf;
			If Items.Find(KeyAndValue.Key) = Undefined Then
				Continue;
			EndIf;
			
			ThisObject[KeyAndValue.Key] = KeyAndValue.Value;
		EndDo;
		
		UpdateFormData();
	EndIf;
	
EndProcedure

&AtClient
Async Procedure AfterSignaturePropertiesRead(Result, AdditionalParameters) Export
	
	ArePropertiesRead = True;
	
	If Result.Success = True Then
		SignatureReadError = "";
		HasSignatureCertificate = False;
		For Each CertificateData In Result.Certificates Do
			
			NewRow = CertificatesToVerifySignature.Add();
			
			CryptoCertificate = New CryptoCertificate;
			Await CryptoCertificate.InitializeAsync(CertificateData);
			CertificateProperties = Await DigitalSignatureInternalClient.CertificateProperties(CryptoCertificate);
			NewRow.IssuedTo = CertificateProperties.Presentation;
			NewRow.CertificateData = PutToTempStorage(CertificateData, UUID);
			If CertificateData = Result.Certificate Then
				NewRow.IsSignatureCertificate = True;
				HasSignatureCertificate = True;
			EndIf;
			
		EndDo;
		
		If Not HasSignatureCertificate And ValueIsFilled(Result.Certificate) Then
			
			NewRow = CertificatesToVerifySignature.Add();
			
			CryptoCertificate = New CryptoCertificate;
			Await CryptoCertificate.InitializeAsync(Result.Certificate);
			CertificateProperties = Await DigitalSignatureInternalClient.CertificateProperties(CryptoCertificate);
			NewRow.IssuedTo = CertificateProperties.Presentation;
			NewRow.CertificateData = PutToTempStorage(Result.Certificate, UUID);
			NewRow.IsSignatureCertificate = True;
			
		EndIf;
	ElsIf Result.Success = Undefined Then
		SignatureReadError = NStr("vi = 'Không thể nhận chứng thư từ chữ ký, hãy kiểm tra tùy chỉnh ứng dụng chữ ký điện tử.';
									|ru = 'Не удалось получить сертификаты из подписи, проверьте настройки приложений электронной подписи.';
									|en = 'Couldn''t get certificates from the signature. Check the settings of the digital signing apps.'; fa = 'Couldn''t get certificates from the signature. Check the settings of the digital signing apps.';
									|it = 'Не удалось получить сертификаты из подписи, проверьте настройки приложений электронной подписи.';
									|pl = 'Couldn''t get certificates from the signature. Check the settings of the digital signing apps.';
									|tr = 'İmzadan sertifikalar alınamadı, elektronik imza uygulamalar ayarlarını kontrol edin.'");
	Else
		SignatureReadError = Result.ErrorText;
	EndIf;
		
	CertificatesToVerifySignature.Sort("IsSignatureCertificate Desc");
	OpenCertificateRead();
	
EndProcedure

&AtClient
Async Procedure OpenCertificateRead()
	
	If ValueIsFilled(SignatureReadError) Then
		ShowMessageBox(, SignatureReadError);
		Return;
	EndIf;
	
	Count = CertificatesToVerifySignature.Count();
	
	If Count > 1 Then
		
		ValueList = New ValueList();
		For Each Certificate In CertificatesToVerifySignature Do
			
			If Certificate.IsSignatureCertificate Then
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chứng thư của người ký: %1';
						|ru = 'Сертификат подписанта: %1';
						|en = 'Signer''s certificate: %1'; fa = 'Signer''s certificate: %1';
						|it = 'Сертификат подписанта: %1';
						|pl = 'Signer''s certificate: %1';
						|tr = 'İmzalayanın sertifikası: %1'"), Certificate.IssuedTo);
			Else
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chứng thư để kiểm tra chữ ký: %1';
						|ru = 'Сертификат для проверки подписи: %1';
						|en = 'Certificate for signature verification: %1'; fa = 'Certificate for signature verification: %1';
						|it = 'Сертификат для проверки подписи: %1';
						|pl = 'Certificate for signature verification: %1';
						|tr = 'İmza doğrulama sertifikası: %1'"), Certificate.IssuedTo);
			EndIf;
			
			ValueList.Add(Certificate.CertificateData, Presentation);
				
		EndDo;
		
		SelectedItemsCount = Await ValueList.ChooseItemAsync(NStr("vi = 'Hãy chọn chứng thư';
																	|ru = 'Выберите сертификат';
																	|en = 'Select a certificate'; fa = 'Select a certificate';
																	|it = 'Выберите сертификат';
																	|pl = 'Select a certificate';
																	|tr = 'Sertifika seçin'"));

		If SelectedItemsCount <> Undefined Then
			DigitalSignatureClient.OpenCertificate(SelectedItemsCount.Value);
		EndIf;
		
	ElsIf Count = 1 Then
		DigitalSignatureClient.OpenCertificate(CertificatesToVerifySignature[0].CertificateData);
	EndIf;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
