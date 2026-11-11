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
Var InternalData, PasswordProperties, DataDetails, ObjectForm, ProcessingAfterWarning, CurrentPresentationsList;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DigitalSignatureInternal.SetPasswordEntryNote(ThisObject, ,
		Items.AdvancedPasswordNote.Name);
	
	DigitalSignatureInternal.SetSigningEncryptionDecryptionForm(ThisObject, , True);
	
	AllowRememberPassword = Parameters.AllowRememberPassword;
	IsAuthentication = Parameters.IsAuthentication;
	
	If IsAuthentication Then
		Items.FormDecrypt.Title = NStr("vi = 'Đồng ý';
										|ru = 'ОК';
										|en = 'OK'; fa = 'تأیید';
										|it = 'OK';
										|pl = 'OK';
										|tr = 'Tamam'");
		Items.AdvancedPasswordNote.Title = NStr("vi = 'Nhấn nút Đồng ý để chuyển đến nhập mật khẩu.';
												|ru = 'Нажмите ОК, чтобы перейти к вводу пароля.';
												|en = 'Click OK to enter the password.'; fa = 'Click OK to enter the password.';
												|it = 'Cliccare su OK, per passare all''inserimento della password.';
												|pl = 'Naciśnij OK, żeby przejść do wprowadzania hasła.';
												|tr = 'Şifre girmek için OK tuşuna basın.'");
	EndIf;
	
	If DigitalSignatureInternal.UseCloudSignatureService() Then
		ModuleCryptographyServiceDSSConfirmationServer = Common.CommonModule("CryptographyServiceDSSConfirmationServer");
		ModuleCryptographyServiceDSSConfirmationServer.PrepareGroupConfirmation(ThisObject, "Decryption",
				"DetailsGroup2",
				"GroupContainer",
				,
				"ConfirmationCommandsGroup");
		ModuleCryptographyServiceDSSConfirmationServer.ConfirmationWhenChangingCertificate(ThisObject, Certificate);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If InternalData = Undefined Then
		Cancel = True;
	EndIf;
	
	If ValueIsFilled(DefaultFieldNameToActivate) Then
		CurrentItem = Items[DefaultFieldNameToActivate];
	EndIf;
	
	If DigitalSignatureInternalClient.UseCloudSignatureService() Then
		ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
		ModuleCryptographyServiceDSSConfirmationClient.ConfirmationWhenOpening(ThisObject, Cancel, ValueIsFilled(Password) And RememberPassword, DataDetails);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	ClearFormVariables();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionKeysCertificates") Then
		AttachIdleHandler("OnChangeCertificatesList", 0.1, True);
	
	ElsIf Upper(EventName) = Upper("ConfirmationToPerformTheMainOperation") And Source = UUID Then
		If Parameter.Completed2 Then
			CloudSignatureProperties = DigitalSignatureInternalClient.GetThePropertiesOfACloudSignature(DataDetails);
			NotificationOnConfirmation = CloudSignatureProperties.NotificationOnConfirmation;
			If NotificationOnConfirmation = Undefined Then
				DecryptData(New CallbackDescription("DecryptCompletion", ThisObject));
			Else
				RunCallback(NotificationOnConfirmation, ThisObject);
			EndIf;
		Else
			Items.FormDecrypt.Visible = True;
			Items.FormDecrypt.Enabled = True;
			Items.FormDecrypt.DefaultButton = True;
			HandleError(New CallbackDescription("DecryptCompletion", ThisObject),
				New Structure("ErrorDescription", Parameter.Error), New Structure);
		EndIf;	
	
	ElsIf Upper(EventName) = Upper("ConfirmationAuthorization") And Source = UUID Then
		DigitalSignatureInternalClient.GetCertificatesThumbprintsAtClient(
			New CallbackDescription("CertificateOnChangeCompletion", ThisObject),
			ValueIsFilled(ThumbprintsFilter));
	
	ElsIf Upper(EventName) = Upper("ConfirmationPrepareData") And Source = UUID Then
		DigitalSignatureInternalClient.GetDataForACloudSignature(
			Parameter.HandlerNext, Parameter.TheFormContext, 
			Parameter.DataDetails, Parameter.Data, True);
	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PasswordStartChoice(Item, ChoiceData, StandardProcessing)
	DigitalSignatureInternalClient.PasswordFieldStartChoice(ThisObject,
		InternalData, PasswordProperties, StandardProcessing);
EndProcedure

&AtClient
Procedure DataPresentationClick(Item, StandardProcessing)
	
	DigitalSignatureInternalClient.DataPresentationClick(ThisObject,
		Item, StandardProcessing, CurrentPresentationsList);
	
EndProcedure

&AtClient
Procedure CertificateOnChange(Item)
	
	DigitalSignatureInternalClient.GetCertificatesThumbprintsAtClient(
		New CallbackDescription("CertificateOnChangeCompletion", ThisObject),
		ValueIsFilled(ThumbprintsFilter));
	
EndProcedure

// Continues the CertificateOnChange procedure.
&AtClient
Procedure CertificateOnChangeCompletion(CertificatesThumbprintsAtClient, Context) Export
	
	CertificateOnChangeAtServer(CertificatesThumbprintsAtClient);
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject, InternalData, PasswordProperties, New Structure("OnOpen", True));
	
	If DigitalSignatureInternalClient.UseCloudSignatureService() Then
		ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
		ModuleCryptographyServiceDSSConfirmationClient.CheckForCertificateError(ThisObject);
		ModuleCryptographyServiceDSSConfirmationClient.FilterListOfMethods(ThisObject);
		ModuleCryptographyServiceDSSConfirmationClient.ConfirmationOnChange(ThisObject, Items.Certificate, DataDetails, PasswordProperties.Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure CertificateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If CertificatesFilter.Count() > 0 Then
		DigitalSignatureInternalClient.StartChooseCertificateAtSetFilter(ThisObject);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectedCertificate", Certificate);
	FormParameters.Insert("ToEncryptAndDecrypt", True);
	FormParameters.Insert("ReturnPassword", True);
	FormParameters.Insert("ExecuteAtServer", ExecuteAtServer);
	FormParameters.Insert("ShouldDisplayAddCommands", True);
	
	DigitalSignatureInternalClient.SelectSigningOrDecryptionCertificate(FormParameters, Item);
	
EndProcedure

&AtClient
Procedure CertificateOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	If ValueIsFilled(Certificate) Then
		DigitalSignatureClient.OpenCertificate(Certificate);
	EndIf;
	
EndProcedure

&AtClient
Procedure CertificateChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueSelected = True Then
		Certificate = InternalData["SelectedCertificate"];
		InternalData.Delete("SelectedCertificate");
		
	ElsIf ValueSelected = False Then
		Certificate = Undefined;
		
	ElsIf TypeOf(ValueSelected) = Type("String") Then
		FormParameters = New Structure;
		FormParameters.Insert("SelectedCertificateThumbprint", ValueSelected);
		FormParameters.Insert("ToEncryptAndDecrypt", True);
		FormParameters.Insert("ReturnPassword", True);
		FormParameters.Insert("ExecuteAtServer", ExecuteAtServer);
		FormParameters.Insert("ShouldDisplayAddCommands", True);
		
		DigitalSignatureInternalClient.SelectSigningOrDecryptionCertificate(FormParameters, Item);
		Return;
	Else
		Certificate = ValueSelected;
	EndIf;
	
	DigitalSignatureInternalClient.GetCertificatesThumbprintsAtClient(
		New CallbackDescription("CertificateChoiceProcessingCompletion", ThisObject, ValueSelected),
		ValueIsFilled(ThumbprintsFilter));
		
	If DigitalSignatureInternalClient.UseCloudSignatureService() Then
		ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
		ModuleCryptographyServiceDSSConfirmationClient.ConfirmationOnChange(ThisObject, Items.Certificate, DataDetails, PasswordProperties.Value);
	EndIf;
		
EndProcedure

// Continues the CertificateChoiceProcessing procedure.
&AtClient
Procedure CertificateChoiceProcessingCompletion(CertificatesThumbprintsAtClient, ValueSelected) Export
	
	CertificateOnChangeAtServer(CertificatesThumbprintsAtClient);
	
	If ValueSelected = True
	   And InternalData["SelectedCertificatePassword"] <> Undefined Then
		
		DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
			InternalData, PasswordProperties,, InternalData["SelectedCertificatePassword"]);
		InternalData.Delete("SelectedCertificatePassword");
		Items.RememberPassword.ReadOnly = False;
	Else
		DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject, InternalData, PasswordProperties);
	EndIf;
	
	If DigitalSignatureInternalClient.UseCloudSignatureService() Then
		ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
		ModuleCryptographyServiceDSSConfirmationClient.ConfirmationOnChange(ThisObject, Items.Certificate, DataDetails, PasswordProperties.Value);
		ModuleCryptographyServiceDSSConfirmationClient.CheckForCertificateError(ThisObject);
		ModuleCryptographyServiceDSSConfirmationClient.FilterListOfMethods(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure CertificateAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	DigitalSignatureInternalClient.CertificatePickupFromSelectionList(ThisObject, Text, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure CertificateTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	DigitalSignatureInternalClient.CertificatePickupFromSelectionList(ThisObject, Text, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PasswordOnChange(Item)
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, New Structure("OnChangeAttributePassword", True));
	
	If Not AllowRememberPassword
	   And Not RememberPassword
	   And Not PasswordProperties.PasswordVerified Then
		
		Items.RememberPassword.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure RememberPasswordOnChange(Item)
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, New Structure("OnChangeAttributeRememberPassword", True));
	
	If Not AllowRememberPassword
	   And Not RememberPassword
	   And Not PasswordProperties.PasswordVerified Then
		
		Items.RememberPassword.ReadOnly = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifiedPasswordNoteClick(Item)
	
	DigitalSignatureInternalClient.SpecifiedPasswordNoteClick(ThisObject, Item, PasswordProperties);
	
EndProcedure

&AtClient
Procedure SpecifiedPasswordNoteExtendedTooltipURLProcessing(Item, Var_URL, StandardProcessing)
	
	DigitalSignatureInternalClient.SpecifiedPasswordNoteURLProcessing(
		ThisObject, Item, Var_URL, StandardProcessing, PasswordProperties);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Decrypt(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;

	If DigitalSignatureInternalClient.ThisIsACloudSignatureOperation(ThisObject) Then
		ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
		If ModuleCryptographyServiceDSSConfirmationClient.CheckingBeforePerformingOperation(ThisObject, PasswordProperties.Value) Then 
			ModuleCryptographyServiceDSSConfirmationClient.PerformInitialServiceOperation(ThisObject, DataDetails, PasswordProperties.Value);
			Items.FormDecrypt.Enabled = False;
		EndIf;
		
	Else
		If Not Items.FormDecrypt.Enabled Then
			Return;
		EndIf;
		
		Items.FormDecrypt.Enabled = False;
		
		DecryptData(New CallbackDescription("DecryptCompletion", ThisObject));
	EndIf;
	
EndProcedure

// Continues the Decrypt procedure.
&AtClient
Procedure DecryptCompletion(Result, Context) Export
	
	Items.FormDecrypt.Enabled = True;
	
	If Result = True Then
		Close(True);
	ElsIf DigitalSignatureInternalClient.ThisIsACloudSignatureOperation(ThisObject) Then
		Items.FormDecrypt.Visible = True;
		Items.FormDecrypt.DefaultButton = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ContinueOpening(Notification, CommonInternalData, ClientParameters) Export
	
	If ClientParameters = InternalData Then
		ClientParameters = New Structure("Certificate, PasswordProperties", Certificate, PasswordProperties);
		Return;
	EndIf;
	
	If ClientParameters.Property("SpecifiedContextOfOtherOperation") Then
		CertificateProperties = CommonInternalData;
		ClientParameters.DataDetails.OperationContext.ContinueOpening(Undefined, Undefined, CertificateProperties);
		If CertificateProperties.Certificate = Certificate Then
			PasswordProperties = CertificateProperties.PasswordProperties;
		EndIf;
	EndIf;
	
	DataDetails             = ClientParameters.DataDetails;
	ObjectForm               = ClientParameters.Form;
	CurrentPresentationsList = ClientParameters.CurrentPresentationsList;
	
	InternalData = CommonInternalData;
	Context = New Structure("Notification", Notification);
	Notification = New CallbackDescription("ContinueOpening", ThisObject);
	
	DigitalSignatureInternalClient.ContinueOpeningStart(New CallbackDescription(
		"ContinueOpeningAfterStart", ThisObject, Context), ThisObject, ClientParameters,, True);
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningAfterStart(Result, Context) Export
	
	If Result <> True Then
		ContinueOpeningCompletion(Context);
		Return;
	EndIf;
	
	ModuleCryptographyServiceDSSConfirmationClient = Undefined;
	If DigitalSignatureInternalClient.UseCloudSignatureService() Then
		ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("OnOpen", True);
	If PasswordProperties <> Undefined Then
		AdditionalParameters.Insert("OnSetPasswordFromAnotherOperation", True);
	EndIf;
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, AdditionalParameters);
	
	If Not AllowRememberPassword
	   And Not RememberPassword
	   And Not PasswordProperties.PasswordVerified Then
		
		Items.RememberPassword.ReadOnly = True;
	EndIf;
	
	If NoConfirmation
	   And (    AdditionalParameters.PasswordSpecified1
	      Or AdditionalParameters.EnterPasswordInDigitalSignatureApplication
	      Or CloudPasswordConfirmed) Then
		  
		If ModuleCryptographyServiceDSSConfirmationClient <> Undefined Then 
			If Not ModuleCryptographyServiceDSSConfirmationClient.CloudSignatureRequiresConfirmation(ThisObject, AdditionalParameters.PasswordSpecified1) Then
				ProcessingAfterWarning = Undefined;
				DecryptData(New CallbackDescription("ContinueOpeningAfterDataDecryption", ThisObject, Context));
				Return;
			EndIf;	
		Else
			ProcessingAfterWarning = Undefined;
			DecryptData(New CallbackDescription("ContinueOpeningAfterDataDecryption", ThisObject, Context));
			Return;
		EndIf;
	EndIf;
	
	Open();
	
	If ModuleCryptographyServiceDSSConfirmationClient <> Undefined Then
		If ModuleCryptographyServiceDSSConfirmationClient.CheckingExecutionOfInitialOperation(ThisObject, NoConfirmation And AdditionalParameters.PasswordSpecified1) Then 
			ModuleCryptographyServiceDSSConfirmationClient.PerformInitialServiceOperation(ThisObject, DataDetails, PasswordProperties.Value);
		EndIf;
	EndIf;	
	
	ContinueOpeningCompletion(Context);
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningAfterDataDecryption(Result, Context) Export
	
	ContinueOpeningCompletion(Context, Result = True);
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningCompletion(Context, Result = Undefined)
	
	If Not IsOpen() Then
		ClearFormVariables();
	EndIf;
	
	RunCallback(Context.Notification, Result);
	
EndProcedure

&AtClient
Procedure ClearFormVariables()
	
	DataDetails             = Undefined;
	ObjectForm               = Undefined;
	CurrentPresentationsList = Undefined;
	
EndProcedure

&AtClient
Function VariablesCleared()
	
	Return DataDetails = Undefined
		And ObjectForm = Undefined
		And CurrentPresentationsList = Undefined;
	
EndFunction

// ACC:78-off - Intended for the secure transfer of data between forms on the client without sending it to the server.
&AtClient
Procedure ExecuteDecryption(ClientParameters, CompletionProcessing) Export
// ACC:78-on - Intended for the secure transfer of data between forms on the client without sending it to the server.
	
	DigitalSignatureInternalClient.RefreshFormBeforeSecondUse(ThisObject, ClientParameters);
	
	DataDetails             = ClientParameters.DataDetails;
	ObjectForm               = ClientParameters.Form;
	CurrentPresentationsList = ClientParameters.CurrentPresentationsList;
	
	ProcessingAfterWarning = CompletionProcessing;
	
	Context = New Structure("CompletionProcessing", CompletionProcessing);
	DecryptData(New CallbackDescription("ExecuteDecryptionCompletion", ThisObject, Context));
	
EndProcedure

// Continues the ExecuteDecryption procedure.
&AtClient
Procedure ExecuteDecryptionCompletion(Result, Context) Export
	
	RunCallback(Context.CompletionProcessing, Result);
	
EndProcedure

&AtClient
Procedure OnChangeCertificatesList()
	
	DigitalSignatureInternalClient.GetCertificatesThumbprintsAtClient(
		New CallbackDescription("OnChangeCertificatesListCompletion", ThisObject),
		ValueIsFilled(ThumbprintsFilter));
	
EndProcedure

// Continues the OnChangeCertificatesList procedure.
&AtClient
Procedure OnChangeCertificatesListCompletion(CertificatesThumbprintsAtClient, Context) Export
	
	CertificateOnChangeAtServer(CertificatesThumbprintsAtClient, True);
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, New Structure("OnChangeCertificateProperties", True));
	
EndProcedure

&AtServer
Procedure CertificateOnChangeAtServer(CertificatesThumbprintsAtClient, CheckRef = False)
	
	If CheckRef
	   And ValueIsFilled(Certificate)
	   And Common.ObjectAttributeValue(Certificate, "Ref") <> Certificate Then
		
		Certificate = Undefined;
	EndIf;
	
	DigitalSignatureInternal.CertificateOnChangeAtServer(ThisObject, CertificatesThumbprintsAtClient,, True);
	
	If DigitalSignatureInternal.UseCloudSignatureService() Then
		ModuleCryptographyServiceDSSConfirmationServer = Common.CommonModule("CryptographyServiceDSSConfirmationServer");
		ModuleCryptographyServiceDSSConfirmationServer.ConfirmationWhenChangingCertificate(ThisObject, Certificate);
	EndIf;
	
EndProcedure

&AtClient
Procedure DecryptData(Notification)
	
	If DigitalSignatureInternalClient.ThisIsACloudSignatureOperation(ThisObject) Then
		DigitalSignatureInternalClient.SetThePropertiesOfTheCloudSignature(DataDetails,
				New Structure("Account, ConfirmationData", 
				DigitalSignatureInternalClient.GetDataCloudSignature(ThisObject, "UserSettings"),
				DigitalSignatureInternalClient.GetDataCloudSignature(ThisObject, "ConfirmationData")));
	Else	
		DigitalSignatureInternalClient.SetThePropertiesOfTheCloudSignature(DataDetails,
			New Structure("Account, ConfirmationData"));
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("ErrorAtClient", New Structure);
	Context.Insert("ErrorAtServer", New Structure);
	
	SelectedCertificate = New Structure;
	SelectedCertificate.Insert("Ref",    Certificate);
	SelectedCertificate.Insert("Thumbprint", ThumbprintOfCertificate);
	SelectedCertificate.Insert("Data",    AddressOfCertificate);
	
	DataDetails.Insert("SelectedCertificate", SelectedCertificate);
	
	If DataDetails.Property("BeforeExecute")
	   And TypeOf(DataDetails.BeforeExecute) = Type("CallbackDescription") Then
		
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("DataDetails", DataDetails);
		ExecutionParameters.Insert("Notification", New CallbackDescription(
			"DecryptDataAfterProcessingBeforeExecute", ThisObject, Context));
		
		RunCallback(DataDetails.BeforeExecute, ExecutionParameters);
	Else
		DecryptDataAfterProcessingBeforeExecute(New Structure, Context);
	EndIf;
	
EndProcedure

// Continues the DecryptData procedure.
&AtClient
Async Procedure DecryptDataAfterProcessingBeforeExecute(Result, Context) Export
	
	If VariablesCleared() Then
		Return;
	EndIf;
	
	If Result.Property("ErrorDescription") Then
		HandleError(Context.Notification, New Structure("ErrorDescription", Result.ErrorDescription), New Structure);
		Return;
	EndIf;
	
	Context.Insert("FormIdentifier", UUID);
	If TypeOf(ObjectForm) = Type("ClientApplicationForm") Then
		Context.FormIdentifier = ObjectForm.UUID;
	ElsIf TypeOf(ObjectForm) = Type("UUID") Then
		Context.FormIdentifier = ObjectForm;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DataDetails",     DataDetails);
	ExecutionParameters.Insert("Form",              ThisObject);
	ExecutionParameters.Insert("FormIdentifier", Context.FormIdentifier);
	ExecutionParameters.Insert("PasswordValue",     PasswordProperties.Value);
	ExecutionParameters.Insert("AddressOfCertificate",    AddressOfCertificate); // Intended for automatically determining the app.
	
	Context.Insert("ExecutionParameters", ExecutionParameters);
	
	If DigitalSignatureClient.GenerateDigitalSignaturesAtServer()
	   And ExecuteAtServer <> False Then
		
		If ValueIsFilled(CertificateAtServerErrorDescription) Then
			Result = New Structure("Error", CertificateAtServerErrorDescription);
			CertificateAtServerErrorDescription = New Structure;
			DecryptDataAfterExecuteAtServerSide(Result, Context);
		Else
			// An attempt to encrypt on the server.
			DigitalSignatureInternalClient.ExecuteAtSide(New CallbackDescription(
					"DecryptDataAfterExecuteAtServerSide", ThisObject, Context),
				"Details", "AtServerSide", Context.ExecutionParameters);
		EndIf;
	Else
		DecryptDataAfterExecuteAtServerSide(Undefined, Context);
	EndIf;
	
EndProcedure

// Continues the DecryptData procedure.
&AtClient
Async Procedure DecryptDataAfterExecuteAtServerSide(Result, Context) Export
	
	If VariablesCleared() Then
		Return;
	EndIf;
	
	If Result <> Undefined Then
		DecryptDataAfterExecute(Result);
	EndIf;
	
	If Result <> Undefined And Not Result.Property("Error") Then
		DecryptDataAfterExecuteAtClientSide(New Structure, Context);
	Else
		If Result <> Undefined Then
			Context.ErrorAtServer = Result.Error;
			If ExecuteAtServer = True Then
				DecryptDataAfterExecuteAtClientSide(New Structure, Context);
				Return;
			EndIf;
		EndIf;
		
		// An attempt to sign on the client.
		DigitalSignatureInternalClient.ExecuteAtSide(New CallbackDescription(
				"DecryptDataAfterExecuteAtClientSide", ThisObject, Context),
			"Details", "OnClientSide", Context.ExecutionParameters);
	EndIf;
	
EndProcedure

// Continues the DecryptData procedure.
&AtClient
Procedure DecryptDataAfterExecuteAtClientSide(Result, Context) Export
	
	If VariablesCleared() Then
		Return;
	EndIf;
	
	DecryptDataAfterExecute(Result);
	
	If Result.Property("Error") Then
		Error = Result.Error;
		If DataDetails.Property("OperationContext") Then
			DataDetails.OperationContext = ThisObject;
		EndIf;
		Context.ErrorAtClient = Error;
		AdditionalErrorData = CommonClientServer.StructureProperty(
			Error, "AdditionalDataChecksOnClient", Undefined);
		HandleError(Context.Notification, Context.ErrorAtClient, Context.ErrorAtServer, AdditionalErrorData);
		Return;
	EndIf;
	
	If Not WriteEncryptionCertificates(Context.FormIdentifier, Context.ErrorAtClient) Then
		If DataDetails.Property("OperationContext") Then
			DataDetails.OperationContext = ThisObject;
		EndIf;
		HandleError(Context.Notification, Context.ErrorAtClient, Context.ErrorAtServer);
		Return;
	EndIf;
	
	If Not IsAuthentication
	   And ValueIsFilled(DataPresentation)
	   And (Not DataDetails.Property("NotifyOnCompletion")
	      Or DataDetails.NotifyOnCompletion <> False) Then
		
		DigitalSignatureClient.InformOfObjectDecryption(
			DigitalSignatureInternalClient.FullDataPresentation(ThisObject),
			CurrentPresentationsList.Count() > 1);
	EndIf;
	
	If DataDetails.Property("OperationContext") Then
		DataDetails.OperationContext = ThisObject;
	EndIf;
	
	RunCallback(Context.Notification, True);
	
EndProcedure

// Continues the DecryptData procedure.
&AtClient
Procedure DecryptDataAfterExecute(Result)
	
	If Result.Property("OperationStarted") Then
		DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject, InternalData,
			PasswordProperties, New Structure("OnOperationSuccess", True));
	EndIf;
	
EndProcedure

&AtClient
Function WriteEncryptionCertificates(FormIdentifier, Error)
	
	ObjectsDetails = New Array;
	If DataDetails.Property("Data") Then
		AddObjectDetails(ObjectsDetails, DataDetails);
	Else
		For Each DataElement In DataDetails.DataSet Do
			AddObjectDetails(ObjectsDetails, DataElement);
		EndDo;
	EndIf;
	
	Error = WriteEncryptionCertificatesAtServer(ObjectsDetails, FormIdentifier, Error);
	
	Return Not ValueIsFilled(Error);
	
EndFunction

// Returns:
//   Structure:
//     * Ref - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//
&AtClient
Function ObjectDetails(DataElement)
	
	ObjectVersion = Undefined;
	DataElement.Property("ObjectVersion", ObjectVersion);
	
	ObjectDetails = New Structure;
	ObjectDetails.Insert("Ref", DataElement.Object);
	ObjectDetails.Insert("Version", ObjectVersion);
	
	Return ObjectDetails;
	
EndFunction

&AtClient
Procedure AddObjectDetails(ObjectsDetails, DataElement)
	
	If Not DataElement.Property("Object") Then
		Return;
	EndIf;
	
	ObjectsDetails.Add(ObjectDetails(DataElement));
	
EndProcedure

// Parameters:
//   ObjectsDetails - Array of See ObjectDetails
//
&AtServerNoContext
Function WriteEncryptionCertificatesAtServer(Val ObjectsDetails, Val FormIdentifier, Val Error)
	
	EncryptionCertificates = New Array;
	
	BeginTransaction();
	Try
		For Each ObjectDetails In ObjectsDetails Do
			DigitalSignature.WriteEncryptionCertificates(ObjectDetails.Ref,
				EncryptionCertificates, FormIdentifier, ObjectDetails.Version);
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorInfo = ErrorInfo();
		Error.Insert("ErrorDescription", NStr("vi = 'Không thể xóa chứng thư mã hóa theo nguyên nhân:';
												|ru = 'Не удалось очистить сертификаты шифрования по причине:';
												|en = 'Cannot clear the encryption certificates due to:'; fa = 'Cannot clear the encryption certificates due to:';
												|it = 'Не удалось очистить сертификаты шифрования по причине:';
												|pl = 'Cannot clear the encryption certificates due to:';
												|tr = 'Aşağıdaki nedenlerden dolayı şifreleme sertifikaları temizlenemedi:'")
			+ Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;
	
	Return Error;
	
EndFunction

&AtClient
Procedure HandleError(Notification, ErrorAtClient, ErrorAtServer, AdditionalData = Undefined)
	
	If DataDetails.Property("StopExecution") Then
		
		If Not DataDetails.Property("ErrorDescription") Then
			DataDetails.Insert("ErrorDescription");
		EndIf;
		
		DataDetails.ErrorDescription = DigitalSignatureInternalClientServer.GeneralDescriptionOfTheError(
			ErrorAtClient, ErrorAtServer, NStr("vi = 'Không thể giải mã dữ liệu do:';
												|ru = 'Не удалось расшифровать данные по причине:';
												|en = 'Cannot decrypt data due to:'; fa = 'Cannot decrypt data due to:';
												|it = 'Non è stato possibile decrittare i dati a causa di:';
												|pl = 'Nie udało się odszyfrować danych z powodu:';
												|tr = 'Veriler şu sebeple detaylandırılamadı:'"));
		
		If IsOpen() Then
			Close(False);
		Else
			RunCallback(Notification, False);
		EndIf;
		
	Else
		
		If Not IsOpen() And ProcessingAfterWarning = Undefined Then
			Open();
		EndIf;
		
		AdditionalParameters = New Structure("Certificate", Certificate);
		
		If ValueIsFilled(AdditionalData) Then
			For Each KeyAndValue In AdditionalData Do
				AdditionalParameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
			EndDo;
		EndIf;
		
		DigitalSignatureInternalClient.ShowApplicationCallError(
			NStr("vi = 'Không thể giải mã dữ liệu';
				|ru = 'Не удалось расшифровать данные';
				|en = 'Cannot decrypt data'; fa = 'Cannot decrypt data';
				|it = 'Non è stato possibile decriptare i dati';
				|pl = 'Deszyfracja danych nie powiodła się';
				|tr = 'Veriler detaylandırılamadı'"), "",
			ErrorAtClient, ErrorAtServer, AdditionalParameters, ProcessingAfterWarning);
		
		RunCallback(Notification, False);
		
	EndIf;
	
EndProcedure

// StandardSubsystems.DSSElectronicSignatureService

&AtClient
Procedure Attachable_ConfirmationProcessingOfCommand(Command)
	
	ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
	ModuleCryptographyServiceDSSConfirmationClient.ConfirmationProcessingOfCommand(ThisObject, Command, DataDetails, 
		PasswordProperties.Value);
	
EndProcedure

&AtClient
Procedure Attachable_ConfirmationProcessingOfNavigationLink(Item, FormattedStringURL, StandardProcessing)

	ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
	ModuleCryptographyServiceDSSConfirmationClient.ConfirmationProcessingOfNavigationLink(ThisObject, Item, 
		FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_ConfirmationOnChange(Item)

	ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
	ModuleCryptographyServiceDSSConfirmationClient.ConfirmationOnChange(ThisObject, Item, DataDetails, 
		PasswordProperties.Value);
	
EndProcedure

&AtClient
Procedure Attachable_ConfirmationWaitingHandler()
	
	ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
	ModuleCryptographyServiceDSSConfirmationClient.ConfirmationProcessingWaiting(ThisObject, DataDetails, 
		PasswordProperties.Value);

EndProcedure

&AtClient
Procedure Attachable_ConfirmationStartOfSelection(Item, ChoiceData, StandardProcessing)

	ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
	ModuleCryptographyServiceDSSConfirmationClient.ConfirmationStartOfSelection(ThisObject, Item, ChoiceData, 
		StandardProcessing);
	
EndProcedure

// End StandardSubsystems.DSSElectronicSignatureService

#EndRegion
