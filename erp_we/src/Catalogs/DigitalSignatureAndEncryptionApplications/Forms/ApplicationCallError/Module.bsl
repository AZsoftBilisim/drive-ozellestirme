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
	
	DigitalSignatureInternal.ToSetTheTitleOfTheBug(ThisObject,
		Parameters.FormCaption);
	
	IsFullUser = Users.IsFullUser(,, False);
	
	ErrorAtClient = Parameters.ErrorAtClient;
	ErrorAtServer = Parameters.ErrorAtServer;
	
	AddErrors(ErrorAtClient);
	AddErrors(ErrorAtServer, True);
	
	Items.ErrorsPicture.Visible =
		  Errors.FindRows(New Structure("ErrorAtServer", False)).Count() <> 0
		And Errors.FindRows(New Structure("ErrorAtServer", True)).Count() <> 0;
	
	Items.Errors.HeightInTableRows = Min(Errors.Count(), 3);
	
	ErrorDescription = DigitalSignatureInternalClientServer.GeneralDescriptionOfTheError(
		ErrorAtClient, ErrorAtServer);
	
	ShowInstruction                = Parameters.ShowInstruction;
	ShowOpenApplicationsSettings = Parameters.ShowOpenApplicationsSettings;
	ShowExtensionInstallation       = Parameters.ShowExtensionInstallation;
	
	DetermineCapabilities(ShowInstruction, ShowOpenApplicationsSettings, ShowExtensionInstallation,
		ErrorAtClient, IsFullUser);
	
	DetermineCapabilities(ShowInstruction, ShowOpenApplicationsSettings, ShowExtensionInstallation,
		ErrorAtServer, IsFullUser);
	
	ShowExtensionInstallation = ShowExtensionInstallation And Not Parameters.ExtensionAttached;
	
	If Not ShowExtensionInstallation Then
		Items.FormInstallExtension.Visible = False;
	EndIf;
	
	If Not ShowOpenApplicationsSettings Then
		Items.FormOpenApplicationsSettings.Visible = False;
	EndIf;
	
	AdditionalData = Parameters.AdditionalData;
	
	If ValueIsFilled(AdditionalData)
	   And TypeOf(AdditionalData.UnsignedData) = Type("Structure") Then
		
		DigitalSignatureInternal.RegisterDataSigningInLog(
			AdditionalData.UnsignedData, ErrorDescription);
		
		AdditionalData.UnsignedData = Undefined;
	EndIf;
	
	// StandardSubsystems.SupportRequests
	If Common.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternal = Common.CommonModule(
			"SupportRequestsInternal");
		
		ModuleSupportRequestsInternal.OnCreateAtServer(ThisObject);
		
		If ShowInstruction Then
			ModuleSupportRequestsInternal.ShowNeedHelpSection(Items);
		Else
			ModuleSupportRequestsInternal.HideNeedHelpSection(Items);
		EndIf;
		
	Else
		Items.AssistanceRequiredGroup.Visible = False;
	EndIf;
	// End StandardSubsystems.SupportRequests
	
	StandardSubsystemsServer.ResetWindowLocationAndSize(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Errors.Count() = 1
	 Or Errors.Count() = 2
	   And Errors[0].ErrorAtServer <> Errors[1].ErrorAtServer Then
		
		Cancel = True;
		
		Notification = New CallbackDescription("OnOpenContinued", ThisObject);
		StandardSubsystemsClient.StartNotificationProcessing(Notification);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersErrors

&AtClient
Procedure ErrorsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	If Field = Items.ErrorsMoreDetails Then
		
		CurrentData = Items.Errors.CurrentData;
		
		If CurrentData.Action = "InstallLibrariesForTokens" Then
			OpeningParameters = New Structure("TokenKind, OnlyTokenInstallation");
			FillPropertyValues(OpeningParameters, CurrentData.Parameters);
			OpeningParameters.OnlyTokenInstallation = True;
			DigitalSignatureInternalClient.OpenCryptoProviderAppsInstallationForm(OpeningParameters,
				ThisObject, New CallbackDescription("AfterPerformActionsDetails", ThisObject));
		Else
			
			ErrorParameters = New Structure;
			ErrorParameters.Insert("WarningTitle", Title);
			ErrorParameters.Insert(?(CurrentData.ErrorAtServer,
				"ErrorTextServer", "ErrorTextClient"), CurrentData.DetailsWithTitle);
			
			If ValueIsFilled(AdditionalData) Then
				ErrorParameters.Insert("AdditionalData", AdditionalData);
			EndIf;
			
			DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(ErrorParameters, ThisObject);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenApplicationsSettings(Command)
	
	Close();
	DigitalSignatureClient.OpenDigitalSignatureAndEncryptionSettings("Programs");
	
EndProcedure

&AtClient
Procedure InstallExtension(Command)
	
	DigitalSignatureClient.InstallExtension(True);
	Close();
	
EndProcedure

&AtClient
Procedure SupportTicket(Command)
	
	ExportTechnicalInfo(False);
	
EndProcedure

&AtClient
Procedure InfoForSupport(Command)
	
	Items.AssistanceRequiredGroup.Hide();
	ExportTechnicalInfo(True);
	
EndProcedure

#EndRegion

#Region Private

// Continues the OnOpen procedure.
&AtClient
Procedure OnOpenContinued(Result, Context) Export
	
	ErrorParameters = New Structure;
	ErrorParameters.Insert("WarningTitle", Title);
	ErrorParameters.Insert(?(Errors[0].ErrorAtServer,
		"ErrorTextServer", "ErrorTextClient"), Errors[0].DetailsWithTitle);
	
	If Errors.Count() > 1 Then
		ErrorParameters.Insert(?(Errors[1].ErrorAtServer,
			"ErrorTextServer", "ErrorTextClient"), Errors[1].DetailsWithTitle);
	EndIf;
	
	ErrorParameters.Insert("ShowNeedHelp", True);
	ErrorParameters.Insert("ShowInstruction", ShowInstruction);
	ErrorParameters.Insert("ShowOpenApplicationsSettings", ShowOpenApplicationsSettings);
	ErrorParameters.Insert("ShowExtensionInstallation", ShowExtensionInstallation);
	ErrorParameters.Insert("ErrorDescription", ErrorDescription);
	ErrorParameters.Insert("AdditionalData", AdditionalData);
	
	ContinuationHandler = CallbackDescriptionOnClose;
	CallbackDescriptionOnClose = Undefined;
	
	DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(ErrorParameters, ThisObject, ContinuationHandler);
	
EndProcedure

&AtServer
Procedure DetermineCapabilities(Instruction, ApplicationsSetUp, Extension, Error, IsFullUser)
	
	DetermineCapabilitiesByProperties(Instruction, ApplicationsSetUp, Extension, Error, IsFullUser);
	
	If Not Error.Property("Errors")
		Or TypeOf(Error.Errors) <> Type("Array") Then
		
		Return;
	EndIf;
	
	For Each CurrentError In Error.Errors Do
		DetermineCapabilitiesByProperties(Instruction, ApplicationsSetUp,
			Extension, CurrentError, IsFullUser);
	EndDo;
	
EndProcedure

&AtServer
Procedure DetermineCapabilitiesByProperties(Instruction, ApplicationsSetUp, Extension, Error, IsFullUser)
	
	If Error.Property("ApplicationsSetUp")
		And Error.ApplicationsSetUp = True Then
		
		ApplicationsSetUp = IsFullUser
			Or Not Error.Property("ToAdministrator")
			Or Error.ToAdministrator <> True;
		
	EndIf;
	
	If Error.Property("Instruction")
		And Error.Instruction = True Then
		
		Instruction = True;
	EndIf;
	
	If Error.Property("NoExtension")
		And Error.NoExtension = True Then
		
		Extension = True;
	EndIf;
	
EndProcedure

// Parameters:
//   ErrorsDescription - FormDataCollection:
//   * Errors - Array of Structure
//   ErrorAtServer - Boolean
//
&AtServer
Procedure AddErrors(ErrorsDescription, ErrorAtServer = False)
	
	If Not ValueIsFilled(ErrorsDescription) Then
		Return;
	EndIf;
	
	If ErrorsDescription.Property("Errors")
		And TypeOf(ErrorsDescription.Errors) = Type("Array")
		And ErrorsDescription.Errors.Count() > 0 Then
		
		ErrorsProperties = ErrorsDescription.Errors; // Array of See DigitalSignatureInternalClientServer.NewErrorProperties
		For Each ErrorProperties In ErrorsProperties Do
			
			NewErrorProperties = DigitalSignatureInternalClientServer.NewErrorProperties();
			FillPropertyValues(NewErrorProperties, ErrorProperties);
			
			DetailsWithTitle = "";
			If ValueIsFilled(NewErrorProperties.ErrorTitle) Then
				DetailsWithTitle = NewErrorProperties.ErrorTitle + Chars.LF;
			ElsIf ValueIsFilled(ErrorsDescription.ErrorTitle) Then
				DetailsWithTitle = ErrorsDescription.ErrorTitle + Chars.LF;
			EndIf;
			LongDesc = "";
			If ValueIsFilled(NewErrorProperties.Application) Then
				LongDesc = LongDesc + String(NewErrorProperties.Application) + ":" + Chars.LF;
			EndIf;
			LongDesc = LongDesc + NewErrorProperties.LongDesc;
			DetailsWithTitle = DetailsWithTitle + LongDesc;
			
			ErrorString = Errors.Add();
			ErrorString.Cause = LongDesc;
			ErrorString.DetailsWithTitle = DetailsWithTitle;
			
			If ValueIsFilled(NewErrorProperties.Token)
				And DigitalSignatureInternalClientServer.TokenLibraryLoadingError(NewErrorProperties.LongDesc) Then
				ErrorString.MoreDetails = NStr("vi = 'Thiết lập';
												|ru = 'Установить';
												|en = 'Install'; fa = 'نصب';
												|it = 'Install';
												|pl = 'Install';
												|tr = 'Ayarla'") + "...";
				ErrorString.Action = DigitalSignatureInternalClientServer.ActionInstallLibrariesForTokens();
				ErrorString.Parameters = New Structure("TokenKind", NewErrorProperties.Token.Token);
			EndIf;
			If Not ValueIsFilled(ErrorString.MoreDetails) Then
				ErrorString.MoreDetails = NStr("vi = 'Chi tiết';
												|ru = 'Подробнее';
												|en = 'Details'; fa = 'جزئیات';
												|it = 'Dettagliatamente';
												|pl = 'Details';
												|tr = 'Ayrıntılar'") + "...";
			EndIf;
			
			ErrorString.ErrorAtServer = ErrorAtServer;
			ErrorString.Picture = ?(ErrorAtServer,
				PictureLib.ComputerServer,
				PictureLib.ComputerClient);
			
		EndDo;
	Else
		ErrorString = Errors.Add();
		ErrorString.Cause = ErrorsDescription.ErrorDescription;
		ErrorString.DetailsWithTitle = ErrorsDescription.ErrorDescription;
		ErrorString.MoreDetails = NStr("vi = 'Chi tiết';
										|ru = 'Подробнее';
										|en = 'Details'; fa = 'جزئیات';
										|it = 'Dettagliatamente';
										|pl = 'Details';
										|tr = 'Ayrıntılar'") + "...";
		ErrorString.ErrorAtServer = ErrorAtServer;
		ErrorString.Picture = ?(ErrorAtServer,
			PictureLib.ComputerServer,
			PictureLib.ComputerClient);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterPerformActionsDetails(Result, Context) Export
	Close();
EndProcedure

&AtClient
Procedure ExportTechnicalInfo(ExportArchive)
	
	ErrorsText = "";
	FilesDetails = New Array;
	If ValueIsFilled(AdditionalData) Then
		DigitalSignatureInternalServerCall.AddADescriptionOfAdditionalData(
			AdditionalData, FilesDetails, ErrorsText);
	EndIf;
	
	ErrorsText = ErrorsText + ErrorDescription;
	
	If ExportArchive Then
		DigitalSignatureInternalClient.GenerateTechnicalInformation(
			ErrorsText, Undefined, , FilesDetails);
	Else
		DigitalSignatureInternalClient.GenerateTechnicalInformation(
			ErrorsText, New Structure("Subject, Message", Title), , FilesDetails);
	EndIf;
	
EndProcedure

#EndRegion
