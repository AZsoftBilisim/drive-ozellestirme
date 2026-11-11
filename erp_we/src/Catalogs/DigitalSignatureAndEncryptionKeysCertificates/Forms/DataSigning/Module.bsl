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
	
	SignatoryType = "SignByCertificate";
	
	DigitalSignatureInternal.SetPasswordEntryNote(ThisObject, ,
		Items.AdvancedPasswordNote.Name);
	
	NewParameterSignatureType = New Structure;
	NewParameterSignatureType.Insert("SignatureTypes", New Array);
	NewParameterSignatureType.Insert("Visible", False);
	NewParameterSignatureType.Insert("Enabled", False);
	NewParameterSignatureType.Insert("CanSelectLetterOfAuthority", False);
	NewParameterSignatureType.Insert("AllowSendingForSigning", False);
	NewParameterSignatureType.Insert("BatchSendingForSigning", Undefined);
	NewParameterSignatureType.Insert("Sender");
	NewParameterSignatureType.Insert("VerifyCertificate", DigitalSignatureInternalClientServer.VerifyQualified());
	
	If Not TypeOf(Parameters.SignatureType) = Type("Structure") Then
		If ValueIsFilled(Parameters.SignatureType) Then
			NewParameterSignatureType.SignatureTypes.Add(Parameters.SignatureType);
		EndIf;
	Else
		FillPropertyValues(NewParameterSignatureType, Parameters.SignatureType);
	EndIf;
	
	SetSignatureType(NewParameterSignatureType);
	DigitalSignatureInternal.SetSigningEncryptionDecryptionForm(ThisObject);
	
	// StandardSubsystems.MobileSignatureService
	If Common.SubsystemExists("StandardSubsystems.MobileSignatureService") Then
		If NewParameterSignatureType.AllowSendingForSigning
			And DigitalSignature.UseMobileSignatureService() Then
			DigitalSignatureLocalization.OnRetrieveSigningTypes(Items.SignatoryType.ChoiceList);
		EndIf;
		Items.SignatoryType.Visible = Items.SignatoryType.ChoiceList.Count() > 1;
		If Items.SignatoryType.ChoiceList.FindByValue("SendForSigning") <> Undefined Then
			
			ModuleMobileSignatureServiceInternal = Common.CommonModule("MobileSignatureServiceInternal");
			ModuleMobileSignatureServiceInternal.SignatoryOnCreateAtServer(ThisObject, Parameters.Signatory);
			
			If TypeOf(Parameters.CertificatesFilter) = Type("Structure") And Parameters.CertificatesFilter.Property("Organization") Then
				ChoiceParameters = New Array;
				ChoiceParameters.Add(New ChoiceParameter("Organization", Parameters.CertificatesFilter.Organization));
				Items.Signatory.ChoiceParameters = New FixedArray(ChoiceParameters);
			EndIf;
			
			If ValueIsFilled(Parameters.Signatory) Or ValueIsFilled(Signatory) Or (TypeOf(
				Parameters.CertificatesThumbprintsAtClient) = Type(
				"Array") And Parameters.CertificatesThumbprintsAtClient.Count() = 0 Or TypeOf(
				Parameters.CertificatesThumbprintsAtClient) = Type("String"))
				And Not DigitalSignature.GenerateDigitalSignaturesAtServer()
				And Not DigitalSignatureInternal.UseCloudSignatureService()
				And Not DigitalSignatureInternal.UseDigitalSignatureSaaS() Then

				SignatoryType = "SendForSigning";
				DefaultFieldNameToActivate = "Signatory";
				If ValueIsFilled(Signatory) And Parameters.NoConfirmation Then
					NoConfirmation = True;
				EndIf;
				SetAuthorizationLetterChoiceParametersLinks();
			EndIf;
		EndIf;
	EndIf;
	// End StandardSubsystems.MobileSignatureService
	
	SigningTypePagesVisibility(ThisObject);
	
	// StandardSubsystems.MachineReadableLettersOfAuthority
	If Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		Items.PowerOfAttorneyGroup.Visible = NewParameterSignatureType.CanSelectLetterOfAuthority;
		If NewParameterSignatureType.CanSelectLetterOfAuthority Then
			If ValueIsFilled(Parameters.AuthorityLettersFilter) Then
				ModuleMachineReadableLettersOfAuthorityFTSInternal = Common.CommonModule("MachineReadableLettersOfAuthorityFTSInternal");
				ModuleMachineReadableLettersOfAuthorityFTSInternal.AddAuthorizationLetterSelectionParameters(ThisObject, Parameters.AuthorityLettersFilter);
			EndIf;
			PickLOAByCertificate();
		EndIf;
	EndIf;
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
	If DigitalSignatureInternal.UseCloudSignatureService() Then
		ModuleCryptographyServiceDSSConfirmationServer = Common.CommonModule("CryptographyServiceDSSConfirmationServer");
		
		ModuleCryptographyServiceDSSConfirmationServer.PrepareGroupConfirmation(ThisObject, "Signing",
				"SignGroup",
				"GroupContainer",
				"GroupContainer1",
				"ConfirmationCommandsGroup");
		ModuleCryptographyServiceDSSConfirmationServer.ConfirmationWhenChangingCertificate(ThisObject, Certificate);
	EndIf;
	
	RefreshVisibilityWarnings();
	
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
			PackageData = CommonClientServer.StructureProperty(Parameter, "PackageData");
			DigitalSignatureInternalClient.SetThePropertiesOfTheCloudSignature(DataDetails, New Structure("PackageData", PackageData));
			CloudSignatureProperties = DigitalSignatureInternalClient.GetThePropertiesOfACloudSignature(DataDetails);
			NotificationOnConfirmation = CloudSignatureProperties.NotificationOnConfirmation;
			
			If NotificationOnConfirmation = Undefined Then
				SignData(New CallbackDescription("SignCompletion", ThisObject));
			Else
				RunCallback(NotificationOnConfirmation, ThisObject);
			EndIf;
		Else
			Items.Sign.Visible = True;
			Items.Sign.Enabled = True;
			Items.Sign.DefaultButton = True;
			HandleError(New CallbackDescription("SignCompletion", ThisObject),
				New Structure("ErrorDescription", Parameter.Error), New Structure);
		EndIf;
		
	ElsIf Upper(EventName) = Upper("ConfirmationAuthorization") And Source = UUID Then
		DigitalSignatureInternalClient.GetCertificatesThumbprintsAtClient(
			New CallbackDescription("CertificateChoiceProcessingCompletion", ThisObject));
	
	ElsIf Upper(EventName) = Upper("ConfirmationPrepareData") And Source = UUID Then
		SelectedCertificate = New Structure;
		SelectedCertificate.Insert("Ref",    Certificate);
		SelectedCertificate.Insert("Thumbprint", ThumbprintOfCertificate);
		SelectedCertificate.Insert("Data",    AddressOfCertificate);
		Parameter.DataDetails.Insert("SelectedSignatory",    Undefined);
		Parameter.DataDetails.Insert("SelectedCertificate",   SelectedCertificate);
		Parameter.DataDetails.Insert("SelectedLetterOfAuthority", MachineReadableLetterOfAuthority);
		Parameter.DataDetails.Insert("MachineReadableSigningLOACheckResult", MachineReadableSigningLOACheckResult);

		DigitalSignatureInternalClient.GetDataForACloudSignature(
			Parameter.HandlerNext, Parameter.TheFormContext, 
			Parameter.DataDetails, Parameter.Data, True);
	
	EndIf;
		
	// StandardSubsystems.MobileSignatureService
	If Upper(EventName) = Upper("Write_MobileSignatureServiceSignatories") And Signatory = Source Then
		SignerOnChangeATServer();
	EndIf;
	// End StandardSubsystems.MobileSignatureService
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If SignatoryType = "SendForSigning" Then
		IndexOf = CheckedAttributes.Find("Certificate");
		If CheckedAttributes.Find("Certificate") <> Undefined Then
			CheckedAttributes.Delete(IndexOf);
		EndIf;
		If CheckedAttributes.Find("Signatory") = Undefined
			And (Not ValueIsFilled(SignatoryParameters)
			Or ValueIsFilled(SignatoryParameters) And Not ValueIsFilled(SignatoryParameters.IndividualTIN)) Then
			CheckedAttributes.Add(Signatory);
		EndIf;
	Else
		IndexOf = CheckedAttributes.Find("Signatory");
		If CheckedAttributes.Find("Signatory") <> Undefined Then
			CheckedAttributes.Delete(IndexOf);
		EndIf;
		If CheckedAttributes.Find("Certificate") = Undefined Then
			CheckedAttributes.Add(Signatory);
		EndIf;
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
Procedure SelectLetterOfAuthorityOnChange(Item)
	
	Items.GroupPages.CurrentPage = ?(ByLetterOfAuthority, Items.PageSelectLetterOfAuthority,
		Items.PageWithoutLetterOfAuthority);
	Items.PageWithoutLetterOfAuthority.Visible = Not ByLetterOfAuthority;
	Items.PageSelectLetterOfAuthority.Visible = ByLetterOfAuthority;
	
	If Not ByLetterOfAuthority Then
		MachineReadableLetterOfAuthority = Undefined;
		MachineReadableSigningLOACheckResult = Undefined;
	Else
		AttachIdleHandler("Attachable_PickLetterOfAuthority", 0.1, True);
	EndIf;
	
	SaveAuthorizationLetterSettingAfterSign = True;
	
EndProcedure

&AtClient
Procedure DataPresentationClick(Item, StandardProcessing)
	
	DigitalSignatureInternalClient.DataPresentationClick(ThisObject,
		Item, StandardProcessing, CurrentPresentationsList);
	
EndProcedure

&AtClient
Procedure CertificateOnChange(Item)
	
	SaveSignatorySettingAfterSign = True;
	DigitalSignatureInternalClient.GetCertificatesThumbprintsAtClient(
		New CallbackDescription("CertificateOnChangeCompletion", ThisObject));
	
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
	
	If TypeOf(CertificatesFilter) = Type("ValueList") And CertificatesFilter.Count() > 0 Then
		DigitalSignatureInternalClient.StartChooseCertificateAtSetFilter(ThisObject);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectedCertificate", Certificate);
	FormParameters.Insert("ToEncryptAndDecrypt", False);
	FormParameters.Insert("ReturnPassword", True);
	If TypeOf(CertificatesFilter) <> Type("ValueList") Then
		FormParameters.Insert("FilterByCompany", CertificatesFilter);
	EndIf;
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
	Else
		Certificate = ValueSelected;
	EndIf;
	
	DigitalSignatureInternalClient.GetCertificatesThumbprintsAtClient(
		New CallbackDescription("CertificateChoiceProcessingCompletion", ThisObject, ValueSelected));
	
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
	
EndProcedure

&AtClient
Procedure RememberPasswordOnChange(Item)
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, New Structure("OnChangeAttributeRememberPassword", True));
	
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

&AtClient
Procedure SignatureTypeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SignatoryTypeOnChange(Item)
	
	SigningTypePagesVisibility(ThisObject);
	SetAuthorizationLetterChoiceParametersLinks();
	// StandardSubsystems.MachineReadableLettersOfAuthority
	If Items.PowerOfAttorneyGroup.Visible Then
		PickLOAByCertificate();
	EndIf;
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
EndProcedure

&AtClient
Procedure SignatoryOpening(Item, StandardProcessing)
	
	DigitalSignatureClientLocalization.SignatoryOnOpen(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SignatoryCreating(Item, StandardProcessing)
	
	DigitalSignatureClientLocalization.SignatoryOnOpen(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SignatoryClearing(Item, StandardProcessing)
	
	DigitalSignatureClientLocalization.SignerWhenClearing(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SignatoryOnChange(Item)
	
	SaveSignatorySettingAfterSign = True;
	
	// StandardSubsystems.MobileSignatureService
	SignerOnChangeATServer();
	// End StandardSubsystems.MobileSignatureService
	
	// StandardSubsystems.MachineReadableLettersOfAuthority
	If Items.PowerOfAttorneyGroup.Visible Then
		PickLOAByCertificate();
	EndIf;
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
EndProcedure

&AtClient
Procedure TypeOfSignatureONChange(Item)

	SaveSignatorySettingAfterSign = True;
	// StandardSubsystems.MobileSignatureService
	FillInSubmissionSettings();
	// End StandardSubsystems.MobileSignatureService
EndProcedure

&AtClient
Procedure MachineReadableLetterOfAuthorityOnChange(Item)
	
	SaveAuthorizationLetterSettingAfterSign = True;
	
EndProcedure

&AtClient
Procedure SendingSettingsOnChange(Item)
	
	SaveSignatorySettingAfterSign = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Sign(Command)
	
	DataDetails.Insert("UserClickedSignButton", True);
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	If SignatoryType = "SignByCertificate" Then
		
		If DigitalSignatureInternalClient.ThisIsACloudSignatureOperation(ThisObject) Then
			ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule(
				"CryptographyServiceDSSConfirmationClient");
			If ModuleCryptographyServiceDSSConfirmationClient.CheckingBeforePerformingOperation(ThisObject,
				PasswordProperties.Value) Then
					
				If TypeOf(DataDetails) = Type("Structure") And DataDetails.Property("Data") And TypeOf(
					DataDetails.Data) = Type("Structure") And DataDetails.Data.Property("CMSParameters") Then
					DataDetails.Data.CMSParameters.IncludeCertificatesInSignature = DigitalSignatureInternalClient.IncludingCertificatesInSignatureAsString(
						DataDetails.Data.CMSParameters.IncludeCertificatesInSignature);
				ElsIf TypeOf(DataDetails) = Type("Structure") And DataDetails.Property("DataSet") Then
					
					For Each SetData In DataDetails.DataSet Do
						If TypeOf(SetData.Data) = Type("Structure") And SetData.Data.Property("CMSParameters") Then
							SetData.Data.CMSParameters.IncludeCertificatesInSignature = DigitalSignatureInternalClient.IncludingCertificatesInSignatureAsString(
								SetData.Data.CMSParameters.IncludeCertificatesInSignature);
						EndIf;
					EndDo;
					
				EndIf;
				ModuleCryptographyServiceDSSConfirmationClient.PerformInitialServiceOperation(ThisObject,
					DataDetails, PasswordProperties.Value);
				Items.Sign.Enabled = False;
				DataDetails.Insert("SigningInThisApplication", True);
			EndIf;
		Else
			If Not Items.Sign.Enabled Then
				Return;
			EndIf;
			
			Items.Sign.Enabled = False;
			DataDetails.Insert("SigningInThisApplication", True);
			SignData(New CallbackDescription("SignCompletion", ThisObject));

		EndIf;
		
	// StandardSubsystems.MobileSignatureService
	Else
		
		If Not Items.Sign.Enabled Then
			Return;
		EndIf;
		
		Items.Sign.Enabled = False;
		DataDetails.Insert("SigningInThisApplication", False);
		SignDataInMobileSignatureService(New CallbackDescription("SignCompletion", ThisObject));
		
	// End StandardSubsystems.MobileSignatureService
	EndIf;
	
EndProcedure

// Continues the Sign procedure.
&AtClient
Procedure SignCompletion(Result, Context) Export
	
	Items.Sign.Enabled = True;
	
	If Result = True Then
		Close(True);
	ElsIf DigitalSignatureInternalClient.ThisIsACloudSignatureOperation(ThisObject) Then
		Items.Sign.Visible = True;
		Items.Sign.DefaultButton = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SigningTypePagesVisibility(Form)
	
	If Form.SignatoryType = "SignByCertificate" Then
		Form.Items.PagesSigning.CurrentPage = Form.Items.PageSigning;
		Form.Items.PageSendForSigning.Visible = False;
		Form.Items.PageSigning.Visible = True;
	Else
		Form.Items.PagesSigning.CurrentPage = Form.Items.PageSendForSigning;
		Form.Items.PageSigning.Visible = False;
		Form.Items.PageSendForSigning.Visible = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAuthorizationLetterChoiceParametersLinks()

	ChoiceParametersArray = New Array;
	
	If SignatoryType = "SignByCertificate" Then
		ChoiceParameterLink = New ChoiceParameterLink("AgentCertificate", "Certificate", LinkedValueChangeMode.Clear);
		ChoiceParametersArray.Add(ChoiceParameterLink);
	EndIf;
	
	Items.MachineReadableLetterOfAuthority.ChoiceParameterLinks =  New FixedArray(ChoiceParametersArray);
	
EndProcedure

&AtServer
Procedure SetSignatureType(Val ParameterSignatureType)
	
	VerifyCertificate = ParameterSignatureType.VerifyCertificate;
	
	If ParameterSignatureType.SignatureTypes.Count() = 0 Then
		
		TypesList = New ValueList;
		DigitalSignatureInternal.FillListSignatureTypesCryptography(TypesList, "Signing",
			Constants.CryptoSignatureTypeDefault.Get());
		For Each Item In TypesList Do
			ParameterSignatureType.SignatureTypes.Add(Item.Value);
		EndDo;
		
		ParameterSignatureType.Enabled = ParameterSignatureType.SignatureTypes.Count() <> 1;
		ParameterSignatureType.Visible = ParameterSignatureType.SignatureTypes.Count() <> 1;
		
	EndIf;
	
	Items.SignatureType.ChoiceList.Clear();
	Items.SignatureType.ChoiceList.LoadValues(ParameterSignatureType.SignatureTypes);
	
	SignatureType = ParameterSignatureType.SignatureTypes[0];
	
	Items.SignatureType.Visible = ParameterSignatureType.Visible;
	Items.SignatureType.Enabled = ParameterSignatureType.Enabled;
	
	Items.PowerOfAttorneyGroup.Visible = False;
	
	Items.BatchSending.Visible = ParameterSignatureType.BatchSendingForSigning = Undefined;
	BatchSending = ParameterSignatureType.BatchSendingForSigning;
	SenderParameters = ParameterSignatureType.Sender;
	
	If Items.SignatureType.Visible Then
		TypesList = New ValueList;
		DigitalSignatureInternal.FillListSignatureTypesCryptography(TypesList);
		
		ToolTipText = New Array;
		For Each ListItem In Items.SignatureType.ChoiceList Do
			Found4 = TypesList.FindByValue(ListItem.Value);
			If Found4 <> Undefined Then
				ToolTipText.Add(Found4.Presentation);
			EndIf;
		EndDo;
		
		Items.SignatureType.ExtendedTooltip.Title = StrConcat(ToolTipText, Chars.LF);
	EndIf;
	
EndProcedure

// StandardSubsystems.MachineReadableLettersOfAuthority
&AtServer
Procedure PickLOAByCertificate()

	SettingByLOA = Undefined;
	Items.MachineReadableLetterOfAuthority.ChoiceList.Clear();
	MachineReadableLetterOfAuthority = Undefined;
	MachineReadableSigningLOACheckResult = Undefined;
	
	If Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		ModuleMachineReadableLettersOfAuthorityFTSInternal = Common.CommonModule("MachineReadableLettersOfAuthorityFTSInternal");
		SettingByLOA = ModuleMachineReadableLettersOfAuthorityFTSInternal.SettingUpByAuthorizationLetterForSelection(ThisObject);
	EndIf;
	
	If SettingByLOA = Undefined Or SettingByLOA.ByLetterOfAuthority = True Then
		PickLetterOfAuthority(SettingByLOA);
	EndIf;

	ByLetterOfAuthority = ValueIsFilled(MachineReadableLetterOfAuthority) Or TypeOf(SettingByLOA) = Type(
		"Structure") And SettingByLOA.ByLetterOfAuthority = True;

	Items.GroupPages.CurrentPage = ?(ByLetterOfAuthority, Items.PageSelectLetterOfAuthority,
		Items.PageWithoutLetterOfAuthority);

EndProcedure
// End StandardSubsystems.MachineReadableLettersOfAuthority

&AtServerNoContext
Function ErrorCertificateMarkedAsRevoked()
	
	Return DigitalSignatureInternal.ErrorCertificateMarkedAsRevoked()
	
EndFunction

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
	Items.BatchSending.Visible = Items.BatchSending.Visible And DataDetails.Property("DataSet")
		And DataDetails.DataSet.Count() > 1;
	ObjectForm               = ClientParameters.Form;
	CurrentPresentationsList = ClientParameters.CurrentPresentationsList;
	
	InternalData = CommonInternalData;
	Context = New Structure("Notification", Notification);
	Notification = New CallbackDescription("ContinueOpening", ThisObject);
	
	DigitalSignatureInternalClient.ContinueOpeningStart(New CallbackDescription(
		"ContinueOpeningAfterStart", ThisObject, Context), ThisObject, ClientParameters);
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningAfterStart(Result, Context) Export
	
	If Result <> True Then
		ContinueOpeningCompletion(Context);
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("OnOpen", True);
	If PasswordProperties <> Undefined Then
		AdditionalParameters.Insert("OnSetPasswordFromAnotherOperation", True);
	EndIf;
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, AdditionalParameters);
	
	ModuleCryptographyServiceDSSConfirmationClient = Undefined;
	If DigitalSignatureInternalClient.UseCloudSignatureService() Then
		ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
	EndIf;
	
	ShouldOpenToSelectLetterOfAuthority = False;
	If ByLetterOfAuthority And Not ValueIsFilled(MachineReadableLetterOfAuthority) Then
		ShouldOpenToSelectLetterOfAuthority = True;
	EndIf;
	
	If NoConfirmation And Not ShouldOpenToSelectLetterOfAuthority Then
		
		If SignatoryType = "SignByCertificate" And (AdditionalParameters.PasswordSpecified1
				Or AdditionalParameters.EnterPasswordInDigitalSignatureApplication
				Or CloudPasswordConfirmed) Then
					
			DataDetails.Insert("SigningInThisApplication", True);
			If ModuleCryptographyServiceDSSConfirmationClient <> Undefined Then
				If Not ModuleCryptographyServiceDSSConfirmationClient.CloudSignatureRequiresConfirmation(
					ThisObject, AdditionalParameters.PasswordSpecified1) Then
					
					ProcessingAfterWarning = Undefined;
					SignData(New CallbackDescription("ContinueOpeningAfterSignData", ThisObject, Context));
					Return;
				EndIf;
			Else
				ProcessingAfterWarning = Undefined;
				SignData(New CallbackDescription("ContinueOpeningAfterSignData", ThisObject, Context));
				Return;
			EndIf;
			
		// StandardSubsystems.MobileSignatureService
		ElsIf SignatoryType = "SendForSigning" And ValueIsFilled(Signatory) Then
			
			DataDetails.Insert("SigningInThisApplication", False);
			ProcessingAfterWarning = Undefined;
			SignDataInMobileSignatureService(New CallbackDescription("ContinueOpeningAfterSignData", ThisObject, Context));
			Return;
		// End StandardSubsystems.MobileSignatureService
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
Procedure ContinueOpeningAfterSignData(Result, Context) Export
	
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

&AtServer
Procedure RefreshVisibilityWarnings()
	
	Items.GroupRecalled.Visible = CertificateRevoked;
	
	If ValueIsFilled(CertificationAuthorityAuditResult) Then
		Items.AdditionalDataGroup.Visible = Not CertificateRevoked And ValueIsFilled(
			CertificationAuthorityAuditResult.Warning.AdditionalInfo);
		Items.DecorationAdditionalInformation.Title =
			CertificationAuthorityAuditResult.Warning.AdditionalInfo;
	Else
		Items.AdditionalDataGroup.Visible = False;
	EndIf;
	
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
Procedure PerformSigning(ClientParameters, CompletionProcessing) Export
// ACC:78-on - Intended for the secure transfer of data between forms on the client without sending it to the server.
	
	DigitalSignatureInternalClient.RefreshFormBeforeSecondUse(ThisObject, ClientParameters);
	
	DataDetails             = ClientParameters.DataDetails;
	ObjectForm               = ClientParameters.Form;
	CurrentPresentationsList = ClientParameters.CurrentPresentationsList;
	
	ProcessingAfterWarning = CompletionProcessing;
	
	Context = New Structure("CompletionProcessing", CompletionProcessing);
	SignData(New CallbackDescription("PerformSigningCompletion", ThisObject, Context));
	
EndProcedure

// Continues the ExecuteSigning procedure.
&AtClient
Procedure PerformSigningCompletion(Result, Context) Export
	
	RunCallback(Context.CompletionProcessing, Result);
	
EndProcedure

&AtClient
Procedure OnChangeCertificatesList()
	
	DigitalSignatureInternalClient.GetCertificatesThumbprintsAtClient(
		New CallbackDescription("OnChangeCertificatesListCompletion", ThisObject));
	
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
	
	DigitalSignatureInternal.CertificateOnChangeAtServer(ThisObject, CertificatesThumbprintsAtClient);
	
	If DigitalSignatureInternal.UseCloudSignatureService() Then
		ModuleCryptographyServiceDSSConfirmationServer = Common.CommonModule("CryptographyServiceDSSConfirmationServer");
		ModuleCryptographyServiceDSSConfirmationServer.ConfirmationWhenChangingCertificate(ThisObject, Certificate);
	EndIf;
	
	// StandardSubsystems.MachineReadableLettersOfAuthority
	
	If Items.PowerOfAttorneyGroup.Visible Then
		PickLOAByCertificate();
	EndIf;
	
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
	RefreshVisibilityWarnings();
	
EndProcedure

&AtClient
Procedure Attachable_PickLetterOfAuthority()
	PickLetterOfAuthority()
EndProcedure

&AtServer
Procedure PickLetterOfAuthority(LetterOfAuthoritySetting = Undefined)
	
	If Not IsTempStorageURL(AddressOfCertificate) And SignatoryType = "SignByCertificate"
		Or SignatoryType <> "SignByCertificate" And Not ValueIsFilled(Signatory) Then
		Return;
	EndIf;
		
	// StandardSubsystems.MachineReadableLettersOfAuthority
	
	If Not Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		Return;
	EndIf;
		
	MachineReadableLetterOfAuthority = Undefined;
	MachineReadableSigningLOACheckResult = Undefined;
	Items.MachineReadableLetterOfAuthority.ChoiceList.Clear();
	
	ModuleMachineReadableLettersOfAuthorityFTSInternal = Common.CommonModule("MachineReadableLettersOfAuthorityFTSInternal");
	ModuleMachineReadableLettersOfAuthorityFTSInternal.PickUpAuthorizationLetterInFormOfSigning(ThisObject, LetterOfAuthoritySetting);
	
	// End StandardSubsystems.MachineReadableLettersOfAuthority

EndProcedure

&AtClient
Procedure SignData(Notification)
	
	DataDetails.Insert("SignatureType", SignatureType);
	
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
	
	If CertificateExpiresOn < CommonClient.SessionDate() Then
		
		PrivateKeyExpirationDate = PrivateKeyExpirationDate(AddressOfCertificate);
		If ValueIsFilled(PrivateKeyExpirationDate) And PrivateKeyExpirationDate
			< CommonClient.SessionDate() Then
			Context.ErrorAtClient.Insert("ErrorDescription", NStr("vi = 'Chứng chỉ đã chọn đã hết hạn của khóa riêng.
																	 |Hãy chọn chứng chỉ khác.';
																	 |ru = 'У выбранного сертификата истек срок действия закрытого ключа.
																	 |Выберите другой сертификат.';
																	 |en = 'The selected certificate''s private key has expired.
																	 |Select another certificate.'; fa = 'The selected certificate''s private key has expired.
																	 |Select another certificate.';
																	 |it = 'У выбранного сертификата истек срок действия закрытого ключа.
																	 |Выберите другой сертификат.';
																	 |pl = 'The selected certificate''s private key has expired.
																	 |Select another certificate.';
																	 |tr = 'Seçilen sertifikanın özel anahtarının süresi doldu.
																	 |Başka bir sertifika seçin.'"));
		Else
			Context.ErrorAtClient.Insert("ErrorDescription", NStr("vi = 'Chứng chỉ đã chọn đã hết hạn.
																	 |Hãy chọn chứng chỉ khác.';
																	 |ru = 'У выбранного сертификата истек срок действия.
																	 |Выберите другой сертификат.';
																	 |en = 'The selected certificate has expired.
																	 |Select another certificate.'; fa = 'The selected certificate has expired.
																	 |Select another certificate.';
																	 |it = 'Il certificato selezionato è scaduto.
																	 | Selezionare un altro certificato.';
																	 |pl = 'Termin ważności wybranego certyfikatu minął.
																	 |Wybierz inny certyfikat.';
																	 |tr = 'Seçilen sertifikanın geçerlilik dönemi sona erdi.
																	 |Başka bir sertifika seçin.'"));
		EndIf;
		
		HandleError(Context.Notification, Context.ErrorAtClient, Context.ErrorAtServer);
		Return;
	EndIf;

	If CertificateRevoked Then
		Context.ErrorAtClient.Insert("ErrorDescription",
			NStr("vi = 'Chứng thư được đánh dấu trong ứng dụng là đã thu hồi.
			|Hãy chọn chứng thư khác.';
			|ru = 'Сертификат помечен в приложении как отозванный.
			|Выберите другой сертификат.';
			|en = 'The certificate is marked as revoked.
			|Select another certificate.'; fa = 'The certificate is marked as revoked.
			|Select another certificate.';
			|it = 'Сертификат помечен в приложении как отозванный.
			|Выберите другой сертификат.';
			|pl = 'The certificate is marked as revoked.
			|Select another certificate.';
			|tr = 'Sertifika uygulamada reddedilmiş olarak işaretlenmiştir.
			|Başka bir sertifika seçin.'"));
		AdditionalErrorData = New Structure("AdditionalDataChecksOnClient", ErrorCertificateMarkedAsRevoked());
		HandleError(Context.Notification, Context.ErrorAtClient, Context.ErrorAtServer,,AdditionalErrorData);
		Return;
	EndIf;
	
	// StandardSubsystems.MachineReadableLettersOfAuthority
	
	If CommonClient.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority")
		And ByLetterOfAuthority
		And ValueIsFilled(MachineReadableLetterOfAuthority) Then
		
		ModuleMachineReadableLettersOfAuthorityFTSInternalClient = CommonClient.CommonModule("MachineReadableLettersOfAuthorityFTSInternalClient");
		MachineReadableSigningLOACheckResult = ModuleMachineReadableLettersOfAuthorityFTSInternalClient.MachineReadableSigningLOACheckResult(
			MachineReadableLetterOfAuthority, AddressOfCertificate);
		If MachineReadableSigningLOACheckResult.VerificationOfSignatory.IsValid = False Then
			Context.ErrorAtClient.Insert("ErrorDescription", MachineReadableSigningLOACheckResult.VerificationOfSignatory.VerificationText);
			HandleError(Context.Notification, Context.ErrorAtClient, Context.ErrorAtServer);
			Return;
		EndIf;
	EndIf;
	
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
	If ValueIsFilled(CertificationAuthorityAuditResult)
		And Not CertificationAuthorityAuditResult.Valid Then
		
		If CertificationAuthorityAuditResult.Warning.AllowSigning Then
			SigningAllowed = CommonClient.CommonSettingsStorageLoad(
				Certificate, "AllowSigning", Undefined);
			
			If SigningAllowed = Undefined Then
				Notification = New CallbackDescription("SignDataAfterCAQuestionAnswered", ThisObject, Context);
				
				QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
				QuestionParameters.Picture = PictureLib.DialogExclamation;
				QuestionParameters.Title = NStr("vi = 'Yêu cầu cho phép ký';
												|ru = 'Запрос разрешения на подпись';
												|en = 'Request for permission to sign'; fa = 'Request for permission to sign';
												|it = 'Запрос разрешения на подпись';
												|pl = 'Request for permission to sign';
												|tr = 'İmza yetkisi isteği'");
				QuestionParameters.CheckBoxText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Ghi nhớ chọn đối với chứng thư ""%1""';
						|ru = 'Запомнить выбор для сертификата ""%1""';
						|en = 'Remember my choice for certificate ""%1""'; fa = 'Remember my choice for certificate ""%1""';
						|it = 'Запомнить выбор для сертификата ""%1""';
						|pl = 'Remember my choice for certificate ""%1""';
						|tr = '""%1"" sertifikası için seçimi hatırlat'"), Certificate);
				
				Buttons = New ValueList;
				Buttons.Add(True, NStr("vi = 'Cho phép ký';
										|ru = 'Разрешить подписание';
										|en = 'Allow signing'; fa = 'اجازه امضا';
										|it = 'Разрешить подписание';
										|pl = 'Allow signing';
										|tr = 'İmzalamaya izin ver'"));
				Buttons.Add(False,   NStr("vi = 'Hủy bỏ ký';
											|ru = 'Отменить подписание';
											|en = 'Cancel signing'; fa = 'Cancel signing';
											|it = 'Отменить подписание';
											|pl = 'Cancel signing';
											|tr = 'İmzalamayı iptal et'"));
				
				ErrorWarning = CertificationAuthorityAuditResult.Warning; // See DigitalSignatureInternalClientServer.WarningWhileVerifyingCertificateAuthorityCertificate
				StandardSubsystemsClient.ShowQuestionToUser(Notification, ErrorWarning.ErrorText, Buttons, QuestionParameters);
				Return;
			EndIf;
		Else
			SigningAllowed = False;
		EndIf;
		
		SignDataAfterCAQuestionAnswered(SigningAllowed, Context);
		Return;
	EndIf;
	
	SignDataAfterCAQuestionAnswered(True, Context);
	
EndProcedure

// Continues the SignData procedure.
&AtClient
Procedure SignDataAfterCAQuestionAnswered(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") Then
		
		NeverAskAgain = Result.NeverAskAgain;
		Result = Result.Value;
		
		If NeverAskAgain Then
			CommonClient.CommonSettingsStorageSave(
				Certificate, "AllowSigning", Result);
		EndIf;
		
	EndIf;
	
	If VerifyCertificate = DigitalSignatureInternalClientServer.NotVerifyCertificate() Then
		SignDataAfterSelectedCertificateVerified(True, Context);
	Else
		If Result = Undefined Or Not Result Then
			ErrorWarning = CertificationAuthorityAuditResult.Warning; // See DigitalSignatureInternalClientServer.WarningWhileVerifyingCertificateAuthorityCertificate
			Context.ErrorAtClient.Insert("ErrorDescription", ErrorWarning.ErrorText);
			AdditionalErrorData = New Structure("AdditionalDataChecksOnClient", ErrorWarning);
			HandleError(Context.Notification, Context.ErrorAtClient, Context.ErrorAtServer, ,
				AdditionalErrorData);
			Return;
		EndIf;
		
		AdditionalInspectionParameters = DigitalSignatureInternalClient.AdditionalCertificateVerificationParameters();
		AdditionalInspectionParameters.ShowError = False;
		AdditionalInspectionParameters.ToVerifySignature = True;
		AdditionalInspectionParameters.MergeCertificateDataErrors = False;
		AdditionalInspectionParameters.PerformCAVerification = DigitalSignatureInternalClientServer.NotVerifyCertificate();
	
		DigitalSignatureInternalClient.CheckCertificate(New CallbackDescription(
				"SignDataAfterSelectedCertificateVerified", ThisObject, Context),
			AddressOfCertificate,,, AdditionalInspectionParameters);
	EndIf;
	
EndProcedure

// Continues the SignData procedure.
&AtClient
Procedure SignDataAfterSelectedCertificateVerified(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") Then // Certificate check error.
		
		If Result.CertificateRevoked Then
			Context.ErrorAtClient.Insert("ErrorDescription", NStr("vi = 'Chứng thư đã thu hồi.
																	 |Hãy chọn chứng thư khác.';
																	 |ru = 'Сертификат отозван.
																	 |Выберите другой сертификат.';
																	 |en = 'The certificate is revoked.
																	 |Select another certificate.'; fa = 'The certificate is revoked.
																	 |Select another certificate.';
																	 |it = 'Сертификат отозван.
																	 |Выберите другой сертификат.';
																	 |pl = 'The certificate is revoked.
																	 |Select another certificate.';
																	 |tr = 'Sertifika iptal edildi.
																	 |Başka bir sertifika seçin.'"));
			AdditionalErrorData = New Structure("AdditionalDataChecksOnClient",
				ErrorCertificateMarkedAsRevoked());
			HandleError(Context.Notification, Context.ErrorAtClient, Context.ErrorAtServer, ,
				AdditionalErrorData);
			Return;
		EndIf;
		
		Context.Insert("CertificateValid", False);
		Context.Insert("IsVerificationRequired", Result.IsVerificationRequired);
		
		If Result.IsVerificationRequired = True Then
			SigningAllowed = CommonClient.CommonSettingsStorageLoad(
					Certificate, "AllowSigningWithCertificateRequiringVerification", False);
			If SigningAllowed Then
				SignDataAfterInvalidSignatureWarning(New Structure("Value", "AllowSigning"),
					New Structure("Context", Context));
				Return;
			EndIf;
		EndIf;
		
		Notification = New CallbackDescription("SignDataAfterInvalidSignatureWarning", ThisObject,
			New Structure("Context, CertificateVerificationResult", Context, Result));
		
		QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionParameters.Picture = PictureLib.DialogExclamation;
		
		Buttons = New ValueList;
		Buttons.Add("CancelSigning",  NStr("vi = 'Hủy ký';
											|ru = 'Отменить подписание';
											|en = 'Cancel signing'; fa = 'Cancel signing';
											|it = 'Отменить подписание';
											|pl = 'Cancel signing';
											|tr = 'İmzalamayı iptal et'"));
		Buttons.Add("AllowSigning", NStr("vi = 'Cho phép ký';
										|ru = 'Разрешить подписание';
										|en = 'Allow signing'; fa = 'اجازه امضا';
										|it = 'Разрешить подписание';
										|pl = 'Allow signing';
										|tr = 'İmzalamaya izin ver'"));
		Buttons.Add("ShowError",      NStr("vi = 'Chi tiết...';
											|ru = 'Подробности...';
											|en = 'Details...'; fa = 'Details...';
											|it = 'Подробности...';
											|pl = 'Details...';
											|tr = 'Ayrıntılar...'"));
		
		If Result.IsVerificationRequired = True Then
			
			QuestionParameters.PromptDontAskAgain = True;
			QuestionParameters.Title = NStr("vi = 'Chữ ký sẽ không được kiểm tra';
											|ru = 'Подпись будет не проверена';
											|en = 'Signature will not be verified'; fa = 'Signature will not be verified';
											|it = 'Signature will not be verified';
											|pl = 'Signature will not be verified';
											|tr = 'İmza doğrulanmayacak'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chứng thư chưa được kiểm tra. Chữ ký do chứng thư này đặt sẽ không cần kiểm tra.
					|
					|%1';
					|ru = 'Сертификат не прошел проверку. Подпись, установленная таким сертификатом, будет требовать проверки.
					|
					|%1';
					|en = 'The certificate failed validation. Any signature created with this certificate will require verification.
					|
					|%1'; fa = 'The certificate failed validation. Any signature created with this certificate will require verification.
					|
					|%1';
					|it = 'The certificate failed validation. Any signature created with this certificate will require verification.
					|
					|%1';
					|pl = 'The certificate failed validation. Any signature created with this certificate will require verification.
					|
					|%1';
					|tr = 'Sertifika doğrulanmamıştır. Böyle bir sertifika tarafından yapılandırılan imzanın doğrulanması gerekecektir.
					|
					|%1'"), DigitalSignatureInternalClientServer.GeneralDescriptionOfTheError(
				Result.ErrorDetailsAtClient, Result.ErrorDescriptionAtServer, Undefined));
		Else
			QuestionParameters.PromptDontAskAgain = False;
			QuestionParameters.Title = NStr("vi = 'Chữ ký sẽ không chính xác';
											|ru = 'Подпись будет неверна';
											|en = 'The signature will be invalid'; fa = 'The signature will be invalid';
											|it = 'Подпись будет неверна';
											|pl = 'The signature will be invalid';
											|tr = 'İmza hatalı olacaktır'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chứng thư chưa được kiểm tra. Chữ ký do chứng thư này thiết lập, sẽ không chính xác.
						|
						|%1';
						|ru = 'Сертификат не прошел проверку. Подпись, установленная таким сертификатом, будет неверна.
						|
						|%1';
						|en = 'The certificate has failed verification. A signature created by this certificate will be invalid.
						|
						|%1'; fa = 'The certificate has failed verification. A signature created by this certificate will be invalid.
						|
						|%1';
						|it = 'Сертификат не прошел проверку. Подпись, установленная таким сертификатом, будет неверна.
						|
						|%1';
						|pl = 'The certificate has failed verification. A signature created by this certificate will be invalid.
						|
						|%1';
						|tr = 'Sertifika doğrulanmamıştır. Böyle bir sertifika tarafından yapılandırılan imza geçersiz olacaktır.
						|
						|%1'"), DigitalSignatureInternalClientServer.GeneralDescriptionOfTheError(
					Result.ErrorDetailsAtClient, Result.ErrorDescriptionAtServer, Undefined));
		EndIf;
		StandardSubsystemsClient.ShowQuestionToUser(Notification, ErrorText, Buttons, QuestionParameters);
		Return;
		
	EndIf;
	
	Context.Insert("CertificateValid",   True);
	Context.Insert("IsVerificationRequired", False);
	SignDataAfterInvalidSignatureWarning(New Structure("Value", "AllowSigning"), 
		New Structure("Context", Context));
	
EndProcedure

// Continues the SignData procedure.
&AtClient
Procedure SignDataAfterInvalidSignatureWarning(Result, AdditionalParameters) Export
	
	Context = AdditionalParameters.Context;

	If Result = Undefined Or Result.Value = "CancelSigning" Or Result.Value = "ShowError" Then
		
		If ValueIsFilled(AdditionalParameters.CertificateVerificationResult.ErrorDetailsAtClient) Then
			Context.ErrorAtClient.Insert("ErrorDescription", AdditionalParameters.CertificateVerificationResult.ErrorDetailsAtClient);
		EndIf;
		If ValueIsFilled(AdditionalParameters.CertificateVerificationResult.ErrorDescriptionAtServer) Then
			Context.ErrorAtServer.Insert("ErrorDescription", AdditionalParameters.CertificateVerificationResult.ErrorDescriptionAtServer);
		EndIf;
		
		HandleError(Context.Notification, Context.ErrorAtClient, Context.ErrorAtServer,,, Result <> Undefined And Result.Value = "ShowError");
		Return;
	
	EndIf;
	
	If Result.Property("NeverAskAgain") And Result.NeverAskAgain Then
		CommonClient.CommonSettingsStorageSave(
			Certificate, "AllowSigningWithCertificateRequiringVerification", True);
	EndIf;
		
	SelectedCertificate = New Structure;
	SelectedCertificate.Insert("Ref",    Certificate);
	SelectedCertificate.Insert("Thumbprint", ThumbprintOfCertificate);
	SelectedCertificate.Insert("Data",    AddressOfCertificate);
	DataDetails.Insert("SelectedSignatory",    Undefined);
	DataDetails.Insert("SelectedCertificate",   SelectedCertificate);
	DataDetails.Insert("SelectedLetterOfAuthority", MachineReadableLetterOfAuthority);
	DataDetails.Insert("MachineReadableSigningLOACheckResult", MachineReadableSigningLOACheckResult);
	
	If DataDetails.Property("BeforeExecute")
	   And TypeOf(DataDetails.BeforeExecute) = Type("CallbackDescription") Then
		
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("DataDetails", DataDetails);
		ExecutionParameters.Insert("Notification", New CallbackDescription(
			"SignDataAfterProcesssingBeforeExecute", ThisObject, Context));
		
		RunCallback(DataDetails.BeforeExecute, ExecutionParameters);
	Else
		SignDataAfterProcesssingBeforeExecute(New Structure, Context);
	EndIf;
	
EndProcedure

// Continues the SignData procedure.
&AtClient
Procedure SignDataAfterProcesssingBeforeExecute(Result, Context) Export
	
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
	ExecutionParameters.Insert("AddressOfCertificate",    AddressOfCertificate);
	ExecutionParameters.Insert("CertificateValid",    Context.CertificateValid);
	ExecutionParameters.Insert("IsVerificationRequired",  Context.IsVerificationRequired);
	
	ExecutionParameters.Insert("FullDataPresentation",
		DigitalSignatureInternalClient.FullDataPresentation(ThisObject));
	ExecutionParameters.Insert("CurrentPresentationsList", CurrentPresentationsList);
	
	Context.Insert("ExecutionParameters", ExecutionParameters);
	
	If DigitalSignatureClient.GenerateDigitalSignaturesAtServer()
	   And ExecuteAtServer <> False Then
		
		If ValueIsFilled(CertificateAtServerErrorDescription) Then
			Result = New Structure("Error", CertificateAtServerErrorDescription);
			CertificateAtServerErrorDescription = New Structure;
			SignDataAfterExecutionAtServerSide(Result, Context);
		Else
			// An attempt to sign on the server.
			DigitalSignatureInternalClient.ExecuteAtSide(New CallbackDescription(
					"SignDataAfterExecutionAtServerSide", ThisObject, Context),
				"Signing", "AtServerSide", Context.ExecutionParameters);
		EndIf;
	Else
		SignDataAfterExecutionAtServerSide(Undefined, Context);
	EndIf;
	
EndProcedure

// Continues the SignData procedure.
&AtClient
Async Procedure SignDataAfterExecutionAtServerSide(Result, Context) Export
	
	If VariablesCleared() Then
		Return;
	EndIf;
	
	If Result <> Undefined Then
		SignDataAfterExecute(Result);
	EndIf;
	
	If Result <> Undefined And Not Result.Property("Error") Then
		SignDataAfterExecutionAtClientSide(New Structure, Context);
	Else
		If Result <> Undefined Then
			Context.ErrorAtServer = Result.Error;
			If ExecuteAtServer = True Then
				SignDataAfterExecutionAtClientSide(New Structure, Context);
				Return;
			EndIf;
		EndIf;
		
		// An attempt to sign on the client.
		DigitalSignatureInternalClient.ExecuteAtSide(New CallbackDescription(
				"SignDataAfterExecutionAtClientSide", ThisObject, Context),
			"Signing", "OnClientSide", Context.ExecutionParameters);
	EndIf;
	
EndProcedure

// Continues the SignData procedure.
&AtClient
Procedure SignDataAfterExecutionAtClientSide(Result, Context) Export
	
	If VariablesCleared() Then
		Return;
	EndIf;
	
	SignDataAfterExecute(Result);
	
	If Result.Property("Error") Then
		
		If DataDetails.Property("OperationContext") Then
			DataDetails.OperationContext = ThisObject;
		EndIf;
		
		Context.ErrorAtClient = Result.Error;
		UnsignedData = DigitalSignatureInternalClient.CurrentDataItemProperties(
			Context.ExecutionParameters);
			
		HandleError(Context.Notification, Context.ErrorAtClient, Context.ErrorAtServer, UnsignedData);
		Return;
		
	EndIf;
	
	If ValueIsFilled(DataPresentation)
	   And (Not DataDetails.Property("NotifyOnCompletion")
	      Or DataDetails.NotifyOnCompletion <> False) Then
		
		DigitalSignatureClient.ObjectSigningInfo(
			DigitalSignatureInternalClient.FullDataPresentation(ThisObject),
			CurrentPresentationsList.Count() > 1);
	EndIf;
	
	If DataDetails.Property("OperationContext") Then
		DataDetails.OperationContext = ThisObject;
	EndIf;
	
	If NotifyOfCertificateAboutToExpire Then
		
		FormOpenParameters = New Structure("Certificate", Certificate);
		If CertificationAuthorityAuditResult <> Undefined 
			And CertificationAuthorityAuditResult.Valid
			And (ValueIsFilled(CertificationAuthorityAuditResult.Warning.ErrorText) 
			Or ValueIsFilled(CertificationAuthorityAuditResult.Warning.AdditionalInfo)) Then
			FormOpenParameters.Insert("AdditionalDataChecks", CertificationAuthorityAuditResult.Warning);
		EndIf;
		
		ActionOnClick = New CallbackDescription("OpenNotificationFormNeedReplaceCertificate",
			DigitalSignatureInternalClient, FormOpenParameters);
		
		ShowUserNotification(
			NStr("vi = 'Cần thay đổi chứng chỉ';
				|ru = 'Необходима замена сертификата';
				|en = 'You need to reissue the certificate'; fa = 'You need to reissue the certificate';
				|it = 'È necessario sostituire il certificato';
				|pl = 'Jest konieczna wymiana certyfikatu';
				|tr = 'Sertifika değiştirilmelidir'"), ActionOnClick, Certificate,
			PictureLib.DialogExclamation, UserNotificationStatus.Important,
			Certificate);
	EndIf;
	
	RunCallback(Context.Notification, True);
	
EndProcedure

// Continues the SignData procedure.
&AtClient
Procedure SignDataAfterExecute(Result)
	
	If Result.Property("OperationStarted") Then
		DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject, InternalData,
			PasswordProperties, New Structure("OnOperationSuccess", True));
	EndIf;
	
	If Result.Property("HasProcessedDataItems") Then
		// Cannot change the certificate once the signing has started.
		// Otherwise, the dataset will be processed in different ways.
		CommonClientServer.SetFormItemProperty(Items,
				"Signatory",
				"ReadOnly",
				True);

		Items.Certificate.ReadOnly = True;
		Items.Comment.ReadOnly = True;
		Items.SignatoryType.ReadOnly = True;
	EndIf;
	
	SettingSignatory = Undefined;
	If SignatoryType = "SignByCertificate" Then
		SettingSignatory = Certificate;
	ElsIf ValueIsFilled(Signatory) Then
		SettingSignatory = Signatory;
	EndIf;

	If ValueIsFilled(SettingSignatory) Then
		
		SaveSettings = New Array;
		
		// StandardSubsystems.MachineReadableLettersOfAuthority
		If SaveAuthorizationLetterSettingAfterSign Then
			AddLettersOfAuthoritySetting(SaveSettings, SettingSignatory);
		EndIf;
		// End StandardSubsystems.MachineReadableLettersOfAuthority
		
		If SaveSignatorySettingAfterSign Then
			SaveSettings.Add(New Structure("Object, Setting, Value",
				UsersClient.CurrentUser(), "DataSigning_DefaultSignatory", SettingSignatory));
				
			// StandardSubsystems.MobileSignatureService	
			If SignatoryType <> "SignByCertificate" And ValueIsFilled(Signatory) Then
				AddSignerSetting(SaveSettings, SettingSignatory);
			EndIf;
			// End StandardSubsystems.MobileSignatureService
		EndIf;
		
		If SaveSettings.Count() > 0 Then
			CommonClient.CommonSettingsStorageSaveArray(SaveSettings);
		EndIf;
		
	EndIf;
	
EndProcedure

// StandardSubsystems.MachineReadableLettersOfAuthority
&AtServer
Procedure AddLettersOfAuthoritySetting(SaveSettings, SettingSignatory)

	If Common.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		ModuleMachineReadableLettersOfAuthorityFTSInternal = Common.CommonModule("MachineReadableLettersOfAuthorityFTSInternal");
		ModuleMachineReadableLettersOfAuthorityFTSInternal.AddLettersOfAuthoritySetting(ThisObject, SaveSettings, SettingSignatory);
	EndIf;

EndProcedure
// End StandardSubsystems.MachineReadableLettersOfAuthority

&AtServerNoContext
Function PrivateKeyExpirationDate(CertificateAddress)
	CertificateProperties = DigitalSignature.CertificateProperties(GetFromTempStorage(CertificateAddress));
	Return CertificateProperties.PrivateKeyExpirationDate;
EndFunction

&AtClient
Procedure HandleError(Notification, ErrorAtClient, ErrorAtServer, UnsignedData = Undefined, AdditionalData = Undefined, ShowError_ = True)
	
	If DataDetails.Property("StopExecution") Then
		
		If ShowError_ Then
			
			If Not DataDetails.Property("ErrorDescription") Then
				DataDetails.Insert("ErrorDescription");
			EndIf;
		
		DataDetails.ErrorDescription = DigitalSignatureInternalClientServer.GeneralDescriptionOfTheError(
			ErrorAtClient, ErrorAtServer, NStr("vi = 'Không thể ký chứng từ do nguyên nhân:';
												|ru = 'Не удалось подписать документы по причине:';
												|en = 'Cannot sign documents due to:'; fa = 'Cannot sign documents due to:';
												|it = 'Non è stato possibile firmare i documenti a causa di:';
												|pl = 'Nie udało się podpisać dokumentów z powodu:';
												|tr = 'Belgeler şu sebeple imzalanamadı:'"));

		EndIf;
		
		If IsOpen() Then
			Close(False);
		Else
			RunCallback(Notification, False);
		EndIf;
		
	Else
		
		If Not IsOpen() And ProcessingAfterWarning = Undefined Then
			Open();
		EndIf;
		
		If ShowError_ Then
			AdditionalParameters = New Structure;
			If ValueIsFilled(AdditionalData) Then
				For Each KeyAndValue In AdditionalData Do
					AdditionalParameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
				EndDo;
			EndIf;
			If UnsignedData <> Undefined Then
				AdditionalParameters.Insert("UnsignedData", UnsignedData);
			EndIf;
			AdditionalParameters.Insert("Certificate", Certificate);
			
			DigitalSignatureInternalClient.ShowApplicationCallError(
				NStr("vi = 'Không thể ký chứng từ';
					|ru = 'Не удалось подписать документы';
					|en = 'Cannot sign documents'; fa = 'Cannot sign documents';
					|it = 'Non è stato possibile firmare i documenti';
					|pl = 'Nie udało się podpisać dokumentów';
					|tr = 'Belgeler imzalanamadı'"), "", 
				ErrorAtClient, ErrorAtServer, AdditionalParameters, ProcessingAfterWarning);
		EndIf;
			
		RunCallback(Notification, False);
		
	EndIf;
	
EndProcedure

// StandardSubsystems.MobileSignatureService
&AtClient
Procedure SignDataInMobileSignatureService(Notification)
	
	DataDetails.Insert("SignatureType", SignatureType);
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("ErrorAtClient", New Structure);
	Context.Insert("ErrorAtServer", New Structure);
	
	DataDetails.Insert("SelectedCertificate", Undefined);
	DataDetails.Insert("SelectedLetterOfAuthority", MachineReadableLetterOfAuthority);
	DataDetails.Insert("TypeOfMobileSignature", TypeOfMobileSignature);
	DataDetails.Insert("SendingSettings", SendingSettings);
	
	If ValueIsFilled(Signatory) Then
		ModuleMobileSignatureServiceInternalServerCall = CommonClient.CommonModule(
			"MobileSignatureServiceInternalServerCall");
		DataDetails.Insert("SelectedSignatory", 
			ModuleMobileSignatureServiceInternalServerCall.SignatoryParameters(Signatory));
	Else
		DataDetails.Insert("SelectedSignatory", SignatoryParameters);
	EndIf;
	
	If DataDetails.Property("BeforeExecute")
	   And TypeOf(DataDetails.BeforeExecute) = Type("CallbackDescription") Then
		
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("DataDetails", DataDetails);
		ExecutionParameters.Insert("Notification", New CallbackDescription(
			"SignDataInServiceAfterProcessBeforeExecute", ThisObject, Context));
		
		RunCallback(DataDetails.BeforeExecute, ExecutionParameters);
	Else
		SignDataInServiceAfterProcessBeforeExecute(New Structure, Context);
	EndIf;
	
EndProcedure

&AtClient
Procedure SignDataInServiceAfterProcessBeforeExecute(Result, Context) Export
	
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
	ExecutionParameters.Insert("IsVerificationRequired",  True);
	
	ExecutionParameters.Insert("FullDataPresentation",
		DigitalSignatureInternalClient.FullDataPresentation(ThisObject));
	ExecutionParameters.Insert("CurrentPresentationsList", CurrentPresentationsList);
	
	Context.Insert("ExecutionParameters", ExecutionParameters);
	
	CallbackDescription = New CallbackDescription("AfterSignDataInService", ThisObject, Context);
	ModuleMobileSignatureServiceClientServer = CommonClient.CommonModule("MobileSignatureServiceClientServer");
	
	SigningParameters = ModuleMobileSignatureServiceClientServer.SigningParameters();
	SigningParameters.SignatureType = SignatureType;
	SigningParameters.BatchSendingForSigning = BatchSending;
	SigningParameters.TypeOfMobileSignature = TypeOfMobileSignature;
	SigningParameters.SendingSettings = SendingSettings;
	SigningParameters.Comment = Comment;
	If ByLetterOfAuthority And ValueIsFilled(MachineReadableLetterOfAuthority) Then
		SigningParameters.LetterOfAuthority = MachineReadableLetterOfAuthority;
	EndIf;
		
	ModuleMobileSignatureServiceInternalClient = CommonClient.CommonModule("MobileSignatureServiceInternalClient");
	ModuleMobileSignatureServiceInternalClient.SignDataInService(CallbackDescription, Context, SigningParameters);
	
EndProcedure

&AtClient
Procedure AfterSignDataInService(Result, Context) Export
	
	If VariablesCleared() Then
		Return;
	EndIf;

	SignDataAfterExecute(Result);
	
	If Result.Property("CancellationOfSigning") Then
		RunCallback(Context.Notification, False);
		Return;
	EndIf;

	If Result.Property("Error") Then
		
		If DataDetails.Property("OperationContext") Then
			DataDetails.OperationContext = ThisObject;
		EndIf;
		
		Context.ErrorAtClient = New Structure("ErrorDescription", Result.Error);
		HandleError(Context.Notification, Context.ErrorAtClient, Context.ErrorAtServer);
		Return;
		
	EndIf;

	RunCallback(Context.Notification, True);
	
EndProcedure

&AtServer
Procedure SignerOnChangeATServer()
	
	ModuleMobileSignatureServiceInternal = Common.CommonModule("MobileSignatureServiceInternal");
	ModuleMobileSignatureServiceInternal.SignerOnChangeATServer(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInSubmissionSettings()
	
	ModuleMobileSignatureServiceInternal = Common.CommonModule("MobileSignatureServiceInternal");
	ModuleMobileSignatureServiceInternal.FillInSubmissionSettings(ThisObject);
	
EndProcedure

&AtServer
Procedure AddSignerSetting(SaveSettings, SettingSignatory)
	If Common.SubsystemExists("StandardSubsystems.MobileSignatureService") Then
		ModuleMobileSignatureServiceInternal = Common.CommonModule("MobileSignatureServiceInternal");
		ModuleMobileSignatureServiceInternal.AddSignerSetting(ThisObject, SaveSettings, SettingSignatory);
	EndIf;
EndProcedure

// End StandardSubsystems.MobileSignatureService

// StandardSubsystems.DSSElectronicSignatureService

#Region ConnectedHandlers

&AtClient
Procedure Attachable_ConfirmationProcessingOfCommand(Command)
	
	ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
	ModuleCryptographyServiceDSSConfirmationClient.ConfirmationProcessingOfCommand(ThisObject, Command, DataDetails, 
		PasswordProperties.Value);
	
EndProcedure

&AtClient
Procedure Attachable_ConfirmationProcessingOfNavigationLink(Item, FormattedStringURL, 
	StandardProcessing)

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

#EndRegion

// End StandardSubsystems.DSSElectronicSignatureService

#EndRegion