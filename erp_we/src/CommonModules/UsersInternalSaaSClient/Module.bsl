///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Opens the service user password input form.
//
// Parameters:
//  ContinuationHandler      - CallbackDescription - to be processed after the password is entered.
//  OwnerForm             - ClientApplicationForm - that requests the password.
//  ServiceUserPassword - String - a current SaaS user password.
//
Procedure RequestPasswordForAuthenticationInService(ContinuationHandler, OwnerForm, ServiceUserPassword) Export
	
	Context = New Structure;
	Context.Insert("ContinuationHandler", ContinuationHandler);
	Context.Insert("OwnerForm", OwnerForm);
	Context.Insert("ServiceUserPassword", ServiceUserPassword);
	
	If ServiceUserPassword = Undefined Then
		Notification = New CallbackDescription("AfterAuthenticationPasswordRequestInService", ThisObject, Context);
		OpenForm("CommonForm.AuthenticationInService", , OwnerForm, , , , Notification);
	Else
		AfterAuthenticationPasswordRequestInService(ServiceUserPassword, Context)
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure AfterAuthenticationPasswordRequestInService(ServiceUserPassword, Context) Export
	
	Context.ServiceUserPassword = ServiceUserPassword;
	
	Notification = New CallbackDescription(
		"AfterAuthenticationPasswordRequestInServiceContinued", ThisObject, Context);
	
	StandardSubsystemsClient.StartNotificationProcessing(Notification);
	
EndProcedure

Procedure AfterAuthenticationPasswordRequestInServiceContinued(Result, Context) Export

	ErrorText = "";
	Try
		RunCallback(Context.ContinuationHandler, Context.ServiceUserPassword);
	Except
		ErrorInfo = ErrorInfo();
		UsersInternalSaaSServerCall.WriteTheErrorToTheLog(
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo) + Chars.LF
			+ NStr("vi = 'Có thể đã nhập sai mật khẩu, hãy nhập lại mật khẩu.';
					|ru = 'Возможно пароль введен неверно, повторите ввод пароля.';
					|en = 'Password may be incorrect. Retype the password.'; fa = 'Password may be incorrect. Retype the password.';
					|it = 'Sembra che ci sia un errore nella password, reinserire la password.';
					|pl = 'Możliewie, hasło zostało wprowadzono niepoprawnie, powtórz wprowadzenie hasła.';
					|tr = 'Parola yanlış girilmiş olabilir, yeniden deneyin.'");
	EndTry;
	
	If ValueIsFilled(ErrorText) Then
		Notification = New CallbackDescription("AfterRequestAuthenticationPasswordInServiceAndErrorWarning", ThisObject, Context);
		ShowMessageBox(Notification, ErrorText);
	EndIf;
	
EndProcedure

Procedure AfterRequestAuthenticationPasswordInServiceAndErrorWarning(Context) Export
	
	RequestPasswordForAuthenticationInService(Context.ContinuationHandler,
		Context.OwnerForm, Undefined);
	
EndProcedure

#EndRegion
