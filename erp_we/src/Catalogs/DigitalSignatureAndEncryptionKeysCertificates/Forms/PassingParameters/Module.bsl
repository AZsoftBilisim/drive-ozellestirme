///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var CommonInternalData;

&AtClient
Var OperationsContextsTempStorage;

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	CommonInternalData = New Map;
	Cancel = True;
	
	OperationsContextsTempStorage = New Map;
	AttachIdleHandler("DeleteObsoleteOperationsContexts", 300);
	
EndProcedure

#EndRegion

#Region Private

// ACC:78-off - Intended for the secure transfer of data between forms on the client without sending it to the server.
&AtClient
Procedure OpenNewForm(FormType, ServerParameters1, ClientParameters = Undefined,
			CompletionProcessing = Undefined, Val NewFormOwner = Undefined) Export
// ACC:78-on - Intended for the secure transfer of data between forms on the client without sending it to the server.
	
	FormsKinds =
		",DataSigning,DataEncryption,DataDecryption,
		|,SelectSigningOrDecryptionCertificate,CertificateCheck,SendForSigning,";
		
	If StrFind(FormsKinds, "," + FormType + ",") = 0 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không hỗ trợ lỗi trong thủ tục %1. %2 ""%3"".';
				|ru = 'Ошибка в процедуре %1. %2 ""%3"" не поддерживается.';
				|en = 'Error in procedure %1. %2 ""%3"" is not supported.'; fa = 'Error in procedure %1. %2 ""%3"" is not supported.';
				|it = 'Errore nella procedura %1%2 ""%3"" non supportato.';
				|pl = 'Błąd w procedurze %1. %2 ""%3"" nie jest obsługiwane.';
				|tr = '%1prosedüründe hata oluştu. %2""%3"" desteklenmiyor.'"),
			"OpenNewForm", "FormType", FormType);
	EndIf;
	
	If NewFormOwner = Undefined Then
		NewFormOwner = New UUID;
	EndIf;
	
	If FormType = "SendForSigning" Then
		NewFormName = "";
		DigitalSignatureClientLocalization.OnDefineSignatureSubmissionForm(NewFormName);
		If NewFormName = "" Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không hỗ trợ lỗi trong thủ tục %1. %2 ""%3"".';
					|ru = 'Ошибка в процедуре %1. %2 ""%3"" не поддерживается.';
					|en = 'Error in procedure %1. %2 ""%3"" is not supported.'; fa = 'Error in procedure %1. %2 ""%3"" is not supported.';
					|it = 'Errore nella procedura %1%2 ""%3"" non supportato.';
					|pl = 'Błąd w procedurze %1. %2 ""%3"" nie jest obsługiwane.';
					|tr = '%1prosedüründe hata oluştu. %2""%3"" desteklenmiyor.'"),
				"OpenNewForm", "FormType", FormType);
		EndIf;
	Else
		NewFormName = "Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form." + FormType;
	EndIf;
	
	Context = New Structure;
	Form = OpenForm(NewFormName, ServerParameters1, NewFormOwner,,,,
		New CallbackDescription("OpenNewFormClosingNotification", ThisObject, Context));
	
	If Form = Undefined Then
		If TypeOf(CompletionProcessing) = Type("CallbackDescription") Then
			RunCallback(CompletionProcessing, Undefined);
		EndIf;
		Return;
	EndIf;
	
	StandardSubsystemsClient.SetFormStorageOption(Form, True);
	
	Context.Insert("Form", Form);
	Context.Insert("CompletionProcessing", CompletionProcessing);
	Context.Insert("ClientParameters", ClientParameters);
	Context.Insert("Notification", New CallbackDescription("ExtendStoringOperationContext", ThisObject));
	
	Notification = New CallbackDescription("OpenNewFormContinued", ThisObject, Context);
	
	If ClientParameters = Undefined Then
		Form.ContinueOpening(Notification, CommonInternalData);
	Else
		Form.ContinueOpening(Notification, CommonInternalData, ClientParameters);
	EndIf;
	
EndProcedure

// Continues the OpenNewForm procedure.
&AtClient
Procedure OpenNewFormContinued(Result, Context) Export
	
	Form = Context.Form;
	If Form.IsOpen() Then
		Return;
	ElsIf Context.Form.FormName =
		"Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.SelectSigningOrDecryptionCertificate"
		And Not IsBlankString(Form.WarningTextOnOpen) Then
		ShowMessageBox(, Form.WarningTextOnOpen);
		Return;
	EndIf;
	
	UpdateFormStorage(Context);
	
	If TypeOf(Context.CompletionProcessing) = Type("CallbackDescription") Then
		RunCallback(Context.CompletionProcessing, Result);
	EndIf;
	
EndProcedure

// Continues the OpenNewForm procedure.
&AtClient
Procedure OpenNewFormClosingNotification(Result, Context) Export
	
	UpdateFormStorage(Context);
	
	If TypeOf(Context.CompletionProcessing) = Type("CallbackDescription") Then
		RunCallback(Context.CompletionProcessing, Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateFormStorage(Context)
	
	StandardSubsystemsClient.SetFormStorageOption(Context.Form, False);
	Context.Form.OnCloseNotifyDescription = Undefined;
	
	If TypeOf(Context.ClientParameters) = Type("Structure")
	   And Context.ClientParameters.Property("DataDetails")
	   And TypeOf(Context.ClientParameters.DataDetails) = Type("Structure")
	   And Context.ClientParameters.DataDetails.Property("OperationContext")
	   And TypeOf(Context.ClientParameters.DataDetails.OperationContext) = Type("ClientApplicationForm") Then
	
#If WebClient Then
		ExtendStoringOperationContext(Context.ClientParameters.DataDetails.OperationContext);
#EndIf
	EndIf;
	
EndProcedure

&AtClient
Procedure ExtendStoringOperationContext(Form) Export
	
	If TypeOf(Form) = Type("ClientApplicationForm") Then
		OperationsContextsTempStorage.Insert(Form,
			New Structure("Form, Time", Form, CommonClient.SessionDate()));
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteObsoleteOperationsContexts()
	
	RefsToFormsToDelete = New Array;
	For Each KeyAndValue In OperationsContextsTempStorage Do
		
		If KeyAndValue.Value.Form.IsOpen() Then
			OperationsContextsTempStorage[KeyAndValue.Key].Time = CommonClient.SessionDate();
			
		ElsIf KeyAndValue.Value.Time + 15*60 < CommonClient.SessionDate() Then
			RefsToFormsToDelete.Add(KeyAndValue.Key);
		EndIf;
	EndDo;
	
	For Each Form In RefsToFormsToDelete Do
		OperationsContextsTempStorage.Delete(Form);
	EndDo;
	
EndProcedure

&AtClient
Procedure SetCertificatePassword(CertificateReference, Password, PasswordNote) Export // ACC:78 - An exception for secure password storage.
	
	SpecifiedPasswords = CommonInternalData.Get("SpecifiedPasswords");
	SpecifiedPasswordsNotes = CommonInternalData.Get("SpecifiedPasswordsNotes");
	
	If SpecifiedPasswords = Undefined Then
		SpecifiedPasswords = New Map;
		CommonInternalData.Insert("SpecifiedPasswords", SpecifiedPasswords);
		SpecifiedPasswordsNotes = New Map;
		CommonInternalData.Insert("SpecifiedPasswordsNotes", SpecifiedPasswordsNotes);
	EndIf;
	
	SpecifiedPasswords.Insert(CertificateReference, ?(Password = Undefined, Password, String(Password)));
	
	NewPasswordNote = New Structure;
	NewPasswordNote.Insert("ExplanationText", "");
	NewPasswordNote.Insert("HyperlinkNote", False);
	NewPasswordNote.Insert("ToolTipText", "");
	NewPasswordNote.Insert("ProcessAction", Undefined);
	
	If TypeOf(PasswordNote) = Type("Structure") Then
		FillPropertyValues(NewPasswordNote, PasswordNote);
	EndIf;
	
	SpecifiedPasswordsNotes.Insert(CertificateReference, NewPasswordNote);
	
EndProcedure

&AtClient
Function CertificatePasswordIsSet(CertificateReference) Export // ACC:78 - An exception for secure password storage.
	
	SpecifiedPasswords = CommonInternalData.Get("SpecifiedPasswords");
	
	If SpecifiedPasswords <> Undefined And SpecifiedPasswords.Get(CertificateReference) <> Undefined Then
		Return True;
	EndIf;
	
	PasswordStorage = CommonInternalData.Get("PasswordStorage");
	
	If PasswordStorage <> Undefined And PasswordStorage.Get(CertificateReference) <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Procedure ResetTheCertificatePassword(CertificateReference) Export // ACC:78 - An exception for secure password storage.
	
	PasswordStorage = CommonInternalData.Get("PasswordStorage");
	If PasswordStorage <> Undefined Then
		PasswordStorage.Insert(CertificateReference, Undefined);
	EndIf;
	
EndProcedure

#EndRegion
