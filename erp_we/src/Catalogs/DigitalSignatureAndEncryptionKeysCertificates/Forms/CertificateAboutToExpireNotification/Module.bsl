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
	
	Certificate = Parameters.Certificate;
	
	CertificateIssueRequestAvailable = DigitalSignature.CommonSettings().CertificateIssueRequestAvailable;
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined 
		And ValueIsFilled(Certificate) Then
		ProcessingApplicationForNewQualifiedCertificateIssue = Common.ObjectManagerByFullName(
			"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		IssuedCertificates = ProcessingApplicationForNewQualifiedCertificateIssue.IssuedCertificates(
			Certificate);
	EndIf;
	
	YesReissued = IssuedCertificates.Count() > 0;
	Items.DecorationReissued.Visible = YesReissued;
	
	CertificateIssueRequestAvailable = CertificateIssueRequestAvailable
		And AccessRight("Edit", Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates);
		
	AdditionalDataChecks = Parameters.AdditionalDataChecks; // See DigitalSignatureInternalClientServer.WarningWhileVerifyingCertificateAuthorityCertificate
	
	If ValueIsFilled(AdditionalDataChecks) And TypeOf(AdditionalDataChecks) = Type("Structure") Then
		
		Items.DecorationCertificate.Title = ?(ValueIsFilled(AdditionalDataChecks.ErrorText), 
			AdditionalDataChecks.ErrorText,
			AdditionalDataChecks.AdditionalInfo);
		If ValueIsFilled(AdditionalDataChecks.Cause) Then
			Items.DecorationReason.Title = AdditionalDataChecks.Cause;
			Items.DecorationReason.Visible = True;
		EndIf;
		
		If Not YesReissued Then
			If AdditionalDataChecks.PossibleReissue And Not CertificateIssueRequestAvailable Then
				Items.DecorationDecision.Title = Decision();
				Items.DecorationDecision.Visible = True;
			Else
				If ValueIsFilled(AdditionalDataChecks.Decision) Then
					Items.DecorationDecision.Title = AdditionalDataChecks.Decision;
					Items.DecorationDecision.Visible = True;
				EndIf;
			EndIf;
		EndIf;
		
	Else
		
		If ValueIsFilled(Certificate) Then
			ValidBefore = Common.ObjectAttributeValue(Certificate, "ValidBefore")
				+ DigitalSignatureInternal.UTCOffset();
			Items.DecorationCertificate.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 chứng chỉ hết thời hạn hiệu lực';
					|ru = '%1 закончится срок действия сертификата';
					|en = 'The certificate expires on %1'; fa = 'The certificate expires on %1';
					|it = '%1 si conclude il periodo di validità del certificato';
					|pl = '%1 upłynie termin ważności certyfikatu';
					|tr = '%1sertifikanın geçerlilik dönemi sona erecektir'"), ValidBefore);
			If Not YesReissued Then
				If CertificateIssueRequestAvailable Then
					Decision = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Hãy đăng ký <a href = ""%1"">chứng chỉ</a> mới.';
						|ru = 'Подайте <a href = ""%1"">заявление</a> на новый сертификат.';
						|en = 'Submit <a href = ""%1"">application</a> for a new certificate.'; fa = 'Submit <a href = ""%1"">application</a> for a new certificate.';
						|it = 'Подайте <a href = ""%1"">заявление</a> на новый сертификат.';
						|pl = 'Submit <a href = ""%1"">application</a> for a new certificate.';
						|tr = 'Yeni sertifika için <a href = ""%1"">başvurusunda</a> bulunun.'"),
						"ApplyforCertificate");
				Else
					Decision = Decision();
				EndIf;

				Items.DecorationDecision.Title = StringFunctions.FormattedString(Decision);
				Items.DecorationDecision.Visible = True;
			EndIf;
		Else
			Items.DecorationCertificate.Title = NStr("vi = 'Chưa điền tham số Chứng chỉ khi mở biểu mẫu.';
													|ru = 'Не заполнен параметр Сертификат при открытии формы.';
													|en = 'The Certificate parameter is not filled in when opening the form.'; fa = 'The Certificate parameter is not filled in when opening the form.';
													|it = 'Non è stato compilato il parametro Certificato all''apertura del modulo.';
													|pl = 'Nie wypełniono parametru Certyfikat podczas otwarcia formularza.';
													|tr = 'Form açıldığında Sertifika parametresi boş bırakıldı.'");
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DontRemindAgainOnChange(Item)
	
	DigitalSignatureInternalClient.EditMarkONReminder(Certificate, Not DontRemindAgain, ThisObject);
	
EndProcedure

&AtClient
Procedure DecorationReissuedURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	If IssuedCertificates.Count() = 1 Then
		OpenCertificateAfterSelectionFromList(IssuedCertificates[0], Undefined);
	Else	
		CallbackDescription = New CallbackDescription("OpenCertificateAfterSelectionFromList", ThisObject, Item);
		ShowChooseFromList(CallbackDescription, IssuedCertificates);
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationDecisionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	AdditionalData = DigitalSignatureInternalClient.AdditionalDataForErrorClassifier();
	AdditionalData.Certificate = Certificate;
	DigitalSignatureInternalClient.HandleNaviLinkClassifier(
		Item, FormattedStringURL, StandardProcessing, AdditionalData);
		
EndProcedure

#EndRegion


#Region Private

&AtClient
Procedure OpenCertificateAfterSelectionFromList(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.ObjectForm", 
			New Structure("Key", Result.Value));
	EndIf;
		
EndProcedure

&AtServer
Function Decision()
	
	If DigitalSignature.CommonSettings().AvailableCheckAccordingtoCAList Then
		ModuleDigitalSignatureClientServerLocalization = Common.CommonModule(
			"DigitalSignatureClientServerLocalization");
		Return StringFunctions.FormattedString(
				NStr("vi = 'Hãy nhận chứng chỉ mới tại<a href = ""%1"">trung tâm cấp chứng chỉ tương ứng</a>.';
					|ru = 'Получите новый сертификат в <a href = ""%1"">соответствующем удостоверяющем центре</a>.';
					|en = 'Request a new certificate from the <a href = ""%1"">appropriate CA</a>.'; fa = 'Request a new certificate from the <a href = ""%1"">appropriate CA</a>.';
					|it = 'Получите новый сертификат в <a href = ""%1"">соответствующем удостоверяющем центре</a>.';
					|pl = 'Request a new certificate from the <a href = ""%1"">appropriate CA</a>.';
					|tr = 'Yeni sertifikayı <a href = ""%1"">ilgili onay merkezinde</a>teslim alabilirsiniz.'"),
					ModuleDigitalSignatureClientServerLocalization.LinktothearticleonCAs());
	Else
		Return NStr("vi = 'Hãy nhận chứng chỉ mới.';
					|ru = 'Получите новый сертификат.';
					|en = 'Request a new certificate.'; fa = 'Request a new certificate.';
					|it = 'Ricevere nuovo certificato.';
					|pl = 'Otrzymaj nowy certyikat.';
					|tr = 'Yeni sertifikayı teslim alın.'");
	EndIf;
	
EndFunction

#EndRegion