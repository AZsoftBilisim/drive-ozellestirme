///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MailServiceOnChange(Item)
	
	If Not ValueIsFilled(MailService) Then
		Items.Pages.CurrentPage = Items.PageMailService;
		Return;
	EndIf;
	
	Items.Pages.CurrentPage = Items.PageAppRegistration;
	
	FillMailServiceSettings();
	FillAppRegistrationNotes();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Register(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Cancel = False;
	CheckAppRegistrationAttributesFilling(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	WriteAuthorizationSettings();
	Close();
	
	ShowUserNotification(, , NStr("ru = 'Приложение зарегистрировано.';
									|vi = 'The application is registered.';
									|en = 'The application is registered.'; fa = 'The application is registered.';
									|it = 'The application is registered.';
									|pl = 'The application is registered.';
									|tr = 'Uygulama kaydedildi.'"), PictureLib.DialogInformation);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillMailServiceSettings()
	
	SetPrivilegedMode(True);
	ConnectionSettings = Catalogs.EmailAccounts.ConnectionSettingsByEmailAddress(MailService, , True);
	SetPrivilegedMode(False);
	
	MailServiceSettings = ConnectionSettings.AuthorizationSettings;
	
EndProcedure

&AtClient
Procedure FillAppRegistrationNotes()
	
	If Not ValueIsFilled(MailServiceSettings) Then
		Return;
	EndIf;
	
	RedirectAddress = AuthorizationCodeRedirectionAddress(MailServiceSettings);
	
	If Not ValueIsFilled(MailServiceSettings.ExplanationByRedirectAddress)
		And Not ValueIsFilled(MailServiceSettings.ExplanationByApplicationID)
		And Not ValueIsFilled(MailServiceSettings.ExplanationApplicationPassword) Then
		Return;
	EndIf;
	
	ExplanationByRedirectAddress = MailServiceSettings.ExplanationByRedirectAddress;
	ExplanationByApplicationID = MailServiceSettings.ExplanationByApplicationID;
	ExplanationApplicationPassword = MailServiceSettings.ExplanationApplicationPassword;
	AdditionalNote = MailServiceSettings.AdditionalNote;
	
	AliasRedirectAddresses = MailServiceSettings.AliasRedirectAddresses;
	ApplicationIDAlias = MailServiceSettings.ApplicationIDAlias;
	ApplicationPasswordAlias = MailServiceSettings.ApplicationPasswordAlias;
	
	Items.ExplanationByRedirectAddress.Title = ExplanationByRedirectAddress;
	Items.ExplanationByApplicationID.Title = ExplanationByApplicationID;
	Items.ExplanationApplicationPassword.Title = ExplanationApplicationPassword;
	Items.AdditionalNote.Title = AdditionalNote;
	
	Items.RedirectAddress.Title = AliasRedirectAddresses;
	Items.AppID.Title = ApplicationIDAlias;
	Items.ApplicationPassword.Title = ApplicationPasswordAlias;
	
	Items.ExplanationApplicationPassword.Visible = MailServiceSettings.UseApplicationPassword;
	Items.ApplicationPassword.Visible = MailServiceSettings.UseApplicationPassword;
	
	Items.ExplanationByRedirectAddress.Visible = ValueIsFilled(ExplanationByRedirectAddress);
	Items.ExplanationByApplicationID.Visible = ValueIsFilled(ExplanationByApplicationID);
	Items.ExplanationApplicationPassword.Visible = ValueIsFilled(ExplanationApplicationPassword);
	
	Items.RedirectAddress.Visible = ValueIsFilled(AliasRedirectAddresses);
	
EndProcedure

&AtServerNoContext
Function AuthorizationCodeRedirectionAddress(Val MailServiceSettings)
	
	AuthorizationCodeRedirectionAddress = "";
	
	If EmailOperationsInternal.IsMailServiceOpenAuthorizationPublished() Then
		AuthorizationCodeRedirectionAddress = EmailOperationsInternal.MailServiceOpenAuthorizationAddress();
	Else
		AuthorizationCodeRedirectionAddress = MailServiceSettings.RedirectAddress;
	EndIf;
	
	If Not ValueIsFilled(AuthorizationCodeRedirectionAddress) Then
		AuthorizationCodeRedirectionAddress = MailServiceSettings.RedirectAddressDefault;
	EndIf;
	
	Return AuthorizationCodeRedirectionAddress;
	
EndFunction

&AtClient
Procedure CheckAppRegistrationAttributesFilling(Cancel)
	
	ClearMessages();
	
	CheckTheFillingOfTheBankingDetails(Items.RedirectAddress, Cancel);
	CheckTheFillingOfTheBankingDetails(Items.AppID, Cancel);
	CheckTheFillingOfTheBankingDetails(Items.ApplicationPassword, Cancel);
	
EndProcedure

&AtClient
Procedure CheckTheFillingOfTheBankingDetails(Item, Cancel)
	
	AttributeName = Item.Name;
	
	If Item.Visible And Not ValueIsFilled(ThisObject[AttributeName]) Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Введите %1';
																					|vi = 'Enter %1';
																					|en = 'Enter %1'; fa = 'Enter %1';
																					|it = 'Inserire %1';
																					|pl = 'Wprowadź %1';
																					|tr = 'Girin %1'"), Item.Title);
		CommonClient.MessageToUser(MessageText, , AttributeName, , Cancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure WriteAuthorizationSettings()
	
	AuthorizationSettings = MailServiceSettings;
	AuthorizationSettings.ApplicationPassword = ApplicationPassword;
	AuthorizationSettings.AppID = AppID;
	AuthorizationSettings.RedirectAddress = RedirectAddress;
	
	SetPrivilegedMode(True);
	Catalogs.InternetServicesAuthorizationSettings.WriteAuthorizationSettings(AuthorizationSettings);
	
EndProcedure

#EndRegion
