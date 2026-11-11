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
	
	Items.AddCertificateIssueRequest.Visible = 
		DigitalSignature.CommonSettings().CertificateIssueRequestAvailable And Not Parameters.HideApplication;
		
	If DigitalSignature.AddEditDigitalSignatures()
		And Not DigitalSignature.UseEncryption()
		And Not Items.AddCertificateIssueRequest.Visible Then
		
		Cancel = True;
		Return;
		
	EndIf;
	
	CertificateAdditionCommandProperties = DigitalSignatureInternal.CertificateAdditionCommandProperties();
	Items.AddToSignAndEncrypt.Title = StrReplace(
		CertificateAdditionCommandProperties.Title, "For", NStr("vi = 'Thêm đối với';
																|ru = 'Добавить для';
																|en = 'Add for'; fa = 'Add for';
																|it = 'Add for';
																|pl = 'Add for';
																|tr = 'Şunun için ekle'"));
	PurposeToSignAndEncrypt = CertificateAdditionCommandProperties.Purpose;
	
	CertificateAdditionCommandProperties = DigitalSignatureInternal.CertificateAdditionCommandProperties(True);
	Items.AddForSigningAndEncryptionFromFiles.Title = StrReplace(
		CertificateAdditionCommandProperties.Title, "For", NStr("vi = 'Thêm đối với';
																|ru = 'Добавить для';
																|en = 'Add for'; fa = 'Add for';
																|it = 'Add for';
																|pl = 'Add for';
																|tr = 'Şunun için ekle'"));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddToSignAndEncrypt(Command)
	
	Close(PurposeToSignAndEncrypt);
	
EndProcedure

&AtClient
Procedure AddForSigningAndEncryptionFromFiles(Command)
	
	Close("ForSigningEncryptionAndDecryptionFromFiles");
	
EndProcedure

&AtClient
Procedure AddFromFiles(Command)
	
	Close("OnlyForEncryptionFromFiles");
	
EndProcedure

&AtClient
Procedure AddFromDirectory(Command)
	
	Close("OnlyForEncryptionFromDirectory");
	
EndProcedure

&AtClient
Procedure AddCertificateIssueRequest(Command)
	
	Close("CertificateIssueRequest");
	
EndProcedure

&AtClient
Procedure AddToEncryptOnly(Command)
	
	Close("ToEncryptOnly");
	
EndProcedure

#EndRegion
