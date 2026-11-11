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
	
	If ValueIsFilled(Parameters.Token) Then
		
		FillPropertyValues(ThisObject, Parameters.Token,,"Certificates");
		
		If IsServer Then
			TitleTemplate1 = NStr("vi = '%1 trên server';
									|ru = '%1 на сервере';
									|en = '%1 on server'; fa = '%1 on server';
									|it = '%1 на сервере';
									|pl = '%1 on server';
									|tr = '1  sunucuda'");
		Else
			TitleTemplate1 = NStr("vi = '%1 trên máy tính';
									|ru = '%1 на компьютере';
									|en = '%1 on computer'; fa = '%1 on computer';
									|it = '%1 на компьютере';
									|pl = '%1 on computer';
									|tr = '%1 bilgisayarda'");
		EndIf;
		
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			TitleTemplate1, Parameters.Token.Presentation);
		
	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	AttachIdleHandler("FillCertificatesListWaitHandler", 0.1, True);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FillCertificatesListWaitHandler()
	FillInListOfCertificates(False);
EndProcedure

&AtClient
Procedure FillInListOfCertificates(Refresh)
	
	Certificates.Clear();
	
	Token = New Structure;
	Token.Insert("Slot");
	Token.Insert("SerialNumber");
	Token.Insert("Presentation");
	FillPropertyValues(Token, ThisObject);
	
	Items.GroupRefreshCertificates.Visible = True;
	DigitalSignatureClientLocalization.OnGettingCertificatesOnToken(New CallbackDescription("AfterGettingCertificateOnToken", ThisObject),
		Token, True, Undefined, Refresh);
	
EndProcedure

&AtClient
Procedure AfterGettingCertificateOnToken(CertificatesArray, Context) Export

	Errors = New Array;
	PopulateCertificateListOnServer(CertificatesArray, Errors);
	If Errors.Count() > 0 Then
		ErrorText = StrConcat(Errors, Chars.LF);
	EndIf;
		
	If ValueIsFilled(ErrorText) Then
		FormParameters = New Structure;
		FormParameters.Insert("WarningTitle", NStr("vi = 'Không thể đọc chứng thư trên token';
													|ru = 'Не удалось прочитать сертификаты на токене';
													|en = 'Couldn''t read certificates stored on the token'; fa = 'Couldn''t read certificates stored on the token';
													|it = 'Не удалось прочитать сертификаты на токене';
													|pl = 'Couldn''t read certificates stored on the token';
													|tr = 'Token''daki sertifikalar okunamadı'"));
		FormParameters.Insert("ErrorTextClient", ErrorText);
		FormParameters.Insert("ShowNeedHelp", True);
		DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(FormParameters, ThisObject);
	EndIf;
	
	Items.GroupRefreshCertificates.Visible = False;

EndProcedure

&AtClient
Procedure Refresh(Command)
	FillInListOfCertificates(True);
EndProcedure

&AtServer
Procedure PopulateCertificateListOnServer(CertificatesAsString, Errors)
		
	For Each Certificate In CertificatesAsString Do
		
		If TypeOf(Certificate) = Type("String") Then
			
			Certificate = StrReplace(Certificate, "-----BEGIN CERTIFICATE-----", "");
			Certificate = StrReplace(Certificate, "-----END CERTIFICATE-----", "");
			Certificate = StrReplace(Certificate, Chars.LF, "");
			
			Try
				CertificateData = Base64Value(Certificate);
			Except
				Errors.Add(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
				Continue;
			EndTry;
			
			If TypeOf(CertificateData) <> Type("BinaryData") Then
				Continue;
			EndIf;
		Else
			CertificateData = Certificate;
		EndIf;

		Try
			CryptoCertificate = New CryptoCertificate(CertificateData);
		Except
			Errors.Add(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Continue;
		EndTry;
		
		CertificateProperties = DigitalSignatureInternalClientServer.CertificateProperties(
			CryptoCertificate, DigitalSignatureInternal.UTCOffset(), CertificateData);
		
		NewRow = Certificates.Add();
		NewRow.ValidUntil = CertificateProperties.ValidBefore;
		NewRow.Thumbprint = CertificateProperties.Thumbprint;
		NewRow.Presentation = CertificateProperties.Presentation;
		NewRow.IssuedBy = CertificateProperties.IssuedBy;
		NewRow.CertificateAddress = PutToTempStorage(CryptoCertificate.Unload(), UUID);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CertificatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CertificateRef = CertificateRef(Items.Certificates.CurrentData.Thumbprint);
	If Not ValueIsFilled(CertificateRef) Then
		DigitalSignatureClient.OpenCertificate(Items.Certificates.CurrentData.CertificateAddress);
	Else
		DigitalSignatureClient.OpenCertificate(CertificateRef);
	EndIf;
	
EndProcedure 

&AtServerNoContext
Function CertificateRef(Thumbprint)
    Return DigitalSignature.CertificateRef(Thumbprint);
EndFunction

#EndRegion