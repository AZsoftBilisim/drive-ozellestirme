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
Var InternalData, ClientParameters, PasswordProperties, ContextExecutionParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DigitalSignatureInternal.SetPasswordEntryNote(
		ThisObject, , Items.AdvancedPasswordNote.Name);
	
	Certificate = Parameters.Certificate;
	CheckOnSelection = Parameters.CheckOnSelection;
	
	If ValueIsFilled(Parameters.FormCaption) Then
		AutoTitle = False;
		Title = Parameters.FormCaption;
	EndIf;
	
	If CheckOnSelection Then
		Items.FormClose.Title = NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Cancel';
									|tr = 'İptal'");
		Items.FormValidate.Title = NStr("vi = 'Kiểm tra và tiếp tục';
										|ru = 'Проверить и продолжить';
										|en = 'Check and continue'; fa = 'Check and continue';
										|it = 'Verificare e continuare';
										|pl = 'Sprawdź i kontynuuj';
										|tr = 'Kontrol et ve devam et'");
	EndIf;
	
	EnterPassword = True;
	StandardChecks = True;
	MergeResults = ?(Parameters.MergeResults = "MergeByAnd"
		Or Parameters.MergeResults = "MergeByOr",
		Parameters.MergeResults, "DontMerge");
	
	If Parameters.CheckResult <> Undefined Then
		CheckCompleted = True;
		ChecksAtClient = Parameters.CheckResult.ChecksAtClient;
		ChecksAtServer = Parameters.CheckResult.ChecksAtServer;
		AdditionalDataChecksOnServer = CommonClientServer.StructureProperty(
			Parameters.CheckResult, "AdditionalDataChecksOnServer", New Structure);
		AdditionalDataChecksOnClient = CommonClientServer.StructureProperty(
			Parameters.CheckResult, "AdditionalDataChecksOnClient", New Structure);
	EndIf;
	
	Checks = New ValueTable;
	Checks.Columns.Add("Name",           New TypeDescription("String"));
	Checks.Columns.Add("Presentation", New TypeDescription("String"));
	Checks.Columns.Add("ToolTip",     New TypeDescription("String"));
	
	DigitalSignatureOverridable.OnCreateFormCertificateCheck(
		Parameters.Certificate, Checks, Parameters.AdditionalChecksParameters,
		StandardChecks, EnterPassword);
	If Not StandardChecks And Checks.Count() = 0 Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Để kiểm tra chứng thư, đã tắt sử dụng kiểm tra chuẩn,
			|đồng thời chưa chỉ định kiểm tra bổ sung %1.';
			|ru = 'Для проверки сертификата отключены стандартные проверки,
			|при этом дополнительных проверок не указано в %1.';
			|en = 'Standard checks for checking the certificate are disabled,
			|at that additional checks are not specified in %1.'; fa = 'Standard checks for checking the certificate are disabled,
			|at that additional checks are not specified in %1.';
			|it = 'Для проверки сертификата отключены стандартные проверки,
			|при этом дополнительных проверок не указано в %1.';
			|pl = 'Standard checks for checking the certificate are disabled,
			|at that additional checks are not specified in %1.';
			|tr = 'Sertifikanın kontrolü için standart denetimler devre dışı bırakıldı,
			|ek denetimler %1''de belirtilmiyor.'"), 
			"DigitalSignatureOverridable.OnCreateFormCertificateCheck"), 
			ErrorCategory.ConfigurationError);
	EndIf;
		
	If ValueIsFilled(Parameters.SignatureType) Then
		SignatureType = Parameters.SignatureType;
	EndIf;
	IgnoreCertificateRevocationStatus = Parameters.IgnoreCertificateRevocationStatus;
	PerformCAVerification = Parameters.PerformCAVerification;
	If IsBlankString(PerformCAVerification) Then
		PerformCAVerification = DigitalSignatureInternalClientServer.VerifyQualified();
	EndIf;
	
	Items.GroupPages.Visible = ChecksAtClient <> Undefined Or ChecksAtServer <> Undefined;
	AreChecksPassed = True;
	
	For Each Validation In Checks Do
		
		Var_Group = FormGroupWithoutDisplay("Group" + Validation.Name, Items.AdditionalChecksGroup);
		
		Var_Group.Visible = False;
		
		AddPicture(Validation.Name + "AtClientPicture", Var_Group);
		AddPicture(Validation.Name + "AtServerPicture", Var_Group);
		
		ResultAndDecisionGroup = FormGroupWithoutDisplay(Validation.Name + "ResultAndDecision", Var_Group,
			ChildFormItemsGroup.Vertical);
			
		Label = Items.Add(Validation.Name + "Label", Type("FormDecoration"), ResultAndDecisionGroup);
		Label.Title = Validation.Presentation;
		Label.ExtendedTooltip.Title = Validation.ToolTip;
		Label.SetAction("Click", "Attachable_LabelClick");
		
		AddItemsDescriptionsErrors(Validation.Name, ResultAndDecisionGroup);
		AddItemsDescriptionsErrors(Validation.Name, ResultAndDecisionGroup, True);
		
		FillPropertyValues(AdditionalChecks.Add(), Validation);
		
		If ChecksAtClient <> Undefined Then
			OutputCheckResult(Validation.Name);
		EndIf;
		
		If ChecksAtServer <> Undefined Then
			OutputCheckResult(Validation.Name, True);
		EndIf;
		
	EndDo;
	
	If Not StandardChecks Then
		
		Items.GeneralChecksGroup.Visible = False;
		Items.OperationsCheckGroup.Visible = False;
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "CustomChecks");
		
	Else
		
		GroupsNamesByCheckNames = GroupsNamesByCheckNames(Items);
		
		For Each Validation In StandardChecks() Do
			
			Items[GroupsNamesByCheckNames[Validation]].Visible = False;
			Items[Validation + "ErrorClient"].Visible = False;
			Items[Validation + "DecisionClientLabel"].Visible = False;
			Items[Validation + "ErrorServer"].Visible = False;
			Items[Validation + "DecisionServerLabel"].Visible = False;
			Items[Validation + "Label"].Title = StandardItemTitle(Validation + "Label", SignatureType);
			
			If ChecksAtClient <> Undefined Then
				OutputCheckResult(Validation);
			EndIf;
			
			If ChecksAtServer <> Undefined Then
				OutputCheckResult(Validation, True);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	PagesVisibility(ThisObject);
	
	CertificateProperties = Common.ObjectAttributesValues(Certificate,
		"CertificateData, Application, EnterPasswordInDigitalSignatureApplication, Thumbprint, Revoked");
		
	Revoked = CertificateProperties.Revoked;
	
	Application = CertificateProperties.Application;
	CertificateAddress = PutToTempStorage(
		CertificateProperties.CertificateData.Get(), UUID);
	CertificateEnterPasswordInElectronicSignatureProgram = CertificateProperties.EnterPasswordInDigitalSignatureApplication;
	
	ThisServiceAccount = TypeOf(Application) = DigitalSignatureInternal.ServiceProgramTypeSignatures()
		And DigitalSignatureInternal.UseCloudSignatureService();
	IsBuiltInCryptoProvider = Application = DigitalSignatureInternal.BuiltinCryptoprovider();
	
	HaveServiceAccount = DigitalSignatureInternal.UseCloudSignatureService()
		And DigitalSignatureInternalServerCall.TheCloudSignatureServiceIsConfigured();
	HasBuiltinCryptoprovider = DigitalSignatureInternal.UseDigitalSignatureSaaS();
		
	If ThisServiceAccount Then
		TheDSSCryptographyServiceModuleInternal = Common.CommonModule("DSSCryptographyServiceInternal");
		TheDSSCryptographyServiceModuleClientServer = Common.CommonModule("DSSCryptographyServiceClientServer");
		CertificateData = TheDSSCryptographyServiceModuleInternal.GetCertificateDataByFingerprint(
								TheDSSCryptographyServiceModuleClientServer.TransformFingerprint(CertificateProperties.Thumbprint));
		If CertificateData = Undefined Or CertificateData.Account <> Application Then
			Raise TheDSSCryptographyServiceModuleInternal.GetErrorDescription(Undefined, "SomeoneElseSCertificate");
		EndIf;
		
		ModuleCryptographyServiceDSSConfirmationServer = Common.CommonModule("CryptographyServiceDSSConfirmationServer");
		ModuleCryptographyServiceDSSConfirmationServer.PrepareGroupConfirmation(ThisObject, "Validation", "", "");
		ModuleCryptographyServiceDSSConfirmationServer.ConfirmationWhenChangingCertificate(ThisObject, Certificate);
		
	ElsIf IsBuiltInCryptoProvider Or (Not StandardChecks And Not EnterPassword) Then
		Items.PasswordEntryGroup.Visible = False;
	EndIf;
	
	RefreshVisibilityAtServer();
	
	If StandardChecks Then
		FirstCheckName = ?(Items.LegalCertificateGroup.Visible,
			"LegalCertificate", "CertificateExists");
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.AssistanceRequiredGroup.Behavior = UsualGroupBehavior.Collapsible;
	EndIf;
	
	// StandardSubsystems.SupportRequests
	If Common.SubsystemExists("StandardSubsystems.SupportRequests") Then
		
		ModuleSupportRequestsInternal = Common.CommonModule(
			"SupportRequestsInternal");
		
		ModuleSupportRequestsInternal.OnCreateAtServer(ThisObject);
		
	Else
		Items.AssistanceRequiredGroup.Visible = False;
	EndIf;
	// End StandardSubsystems.SupportRequests
	
	StandardSubsystemsServer.ResetWindowLocationAndSize(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If InternalData = Undefined Then
		Cancel = True;
	EndIf;
	
	If ThisServiceAccount Then
		ModuleCryptographyServiceDSSConfirmationClient = CommonClient.CommonModule("CryptographyServiceDSSConfirmationClient");
		ModuleCryptographyServiceDSSConfirmationClient.ConfirmationWhenOpening(ThisObject, Cancel, ValueIsFilled(Password) And RememberPassword);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionKeysCertificates") And Source = Certificate Then
		UpdateCertificateInformation();
		Return;
	EndIf;
	
	If Upper(EventName) = Upper("SSL_VerifyCertificate") 
		And Parameter = CertificateAddress Or Upper(EventName) = Upper("Installation_AddInExtraCryptoAPI") Then
		Validate(Undefined);
	EndIf;
	
	// When changing usage settings.
	If Upper(EventName) <> Upper("Write_ConstantsSet") Then
		Return;
	EndIf;
	
	If Upper(Source) = Upper("VerifyDigitalSignaturesOnTheServer")
		Or Upper(Source) = Upper("GenerateDigitalSignaturesAtServer") Then
		
		AttachIdleHandler("OnChangeSigningOrEncryptionUsage", 0.1, True);
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
Procedure Attachable_LabelClick(Item)
	
	TagName = Left(Item.Name, StrLen(Item.Name) - StrLen("Label"));
	ErrorName = TagName + "Error";
	
	WarningParameters = New Structure;
	WarningParameters.Insert("WarningTitle", StandardItemTitle(Item.Name, SignatureType));
	WarningParameters.Insert("ErrorTextClient", ChecksAtClient[ErrorName]);
	WarningParameters.Insert("ErrorTextServer",
		?(OperationsAtServer Or HasBuiltinCryptoprovider Or HaveServiceAccount, 
			ChecksAtServer[ErrorName], ""));
	WarningParameters.Insert("AdditionalData", AdditionalData(TagName));
	
	DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(WarningParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_NavigationLinkProcessingLabel(Item, FormattedStringURL, StandardProcessing)
	
	If StrEndsWith(Item.Name, "ErrorServerLabel") Or StrEndsWith(Item.Name, "ErrorClientLabel") Then
		Return;
	EndIf;
	
	DigitalSignatureInternalClient.HandleNaviLinkClassifier(Item,
		FormattedStringURL, StandardProcessing, AdditionalData());
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
Procedure DecorationTimestampCertificateURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	DigitalSignatureInternalClient.OpenCertificate(FormattedStringURL);
	
EndProcedure

&AtClient
Procedure DecorationChecksPassedClick(Item)
	
	If StandardChecks Then
		
		GroupsNamesByCheckNames = GroupsNamesByCheckNames(Items);
		
		BasicChecks = StandardChecks();
		If Not IsBuiltInCryptoProvider Then
			BasicChecks.Add("ProgramExists");
		EndIf;
		
		For Each Validation In BasicChecks Do
			If Validation = "LegalCertificate" Then
				Continue;
			EndIf;
			Items[GroupsNamesByCheckNames[Validation]].Visible = True;
		EndDo;
		
	EndIf;
	
	For Each Validation In AdditionalChecks Do
		Items["Group" + Validation.Name].Visible = True;
	EndDo;
	
	Items.GroupPages.CurrentPage = Items.PageChecks;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Validate(Command)
	
	CheckCertificate(New CallbackDescription("ValidateCompletion", ThisObject));
	
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

&AtClient
Procedure VisibilityOnCheckEnd()
	Items.FormValidate.Enabled = True;
	PagesVisibility(ThisObject);
EndProcedure

&AtClientAtServerNoContext
Function GroupsNamesByCheckNames(FormItems)
	
	GroupsNamesByCheckNames = New Map;
		
	GroupsNamesByCheckNames.Insert("LegalCertificate", FormItems.LegalCertificateGroup.Name);
	GroupsNamesByCheckNames.Insert("CertificateExists", FormItems.CertificateExistsGroup.Name);
	GroupsNamesByCheckNames.Insert("CertificateData",  FormItems.CertificateDataGroup.Name);
	GroupsNamesByCheckNames.Insert("ProgramExists",   FormItems.GroupAppPresence.Name);
	GroupsNamesByCheckNames.Insert("Signing",         FormItems.SignGroup.Name);
	GroupsNamesByCheckNames.Insert("Encryption",         FormItems.GroupEncryption.Name);
	GroupsNamesByCheckNames.Insert("Details",        FormItems.DetailsGroup2.Name);
	GroupsNamesByCheckNames.Insert("CheckSignature",    FormItems.GroupSignatureVerification.Name);
	
	Return GroupsNamesByCheckNames;
	
EndFunction

&AtClient
Procedure ExportTechnicalInfo(ExportArchive)
	
	If Not CheckCompleted Then
		ShowMessageBox(,
			NStr("vi = 'Để thu thập thông tin kỹ thuật về sự cố gặp phải, cần thực hiện kiểm tra chứng thư.';
				|ru = 'Для сбора технической информации о возникшей проблеме выполните проверку сертификата.';
				|en = 'To gather technical information about the issue, validate the certificate.'; fa = 'To gather technical information about the issue, validate the certificate.';
				|it = 'Per raccogliere informazioni tecniche sul rilevamento del problema, eseguire la verifica del certificato.';
				|pl = 'W celu zbierania informacji technicznych o zaistniałym problemie wykonaj weryfikację certyfikatu.';
				|tr = 'Oluşan hata ile ilgili teknik bilgileri toplamak için sertifika denetimini yürütün.'"));
		Return;
	EndIf;
	
	ChecksContent = StandardChecks();
	For Each Validation In AdditionalChecks Do
		ChecksContent.Add(Validation.Name);
	EndDo;
	
	ErrorsText = "";
	FilesDetails = New Array;
	
	Certificates = New Array;
	Certificates.Add(Certificate);
	For Each TimestampCertificate In TimestampCertificates Do
		Certificates.Add(TimestampCertificate.CertificateAddress);
	EndDo;
	
	DigitalSignatureInternalServerCall.AddADescriptionOfAdditionalData(
		New Structure("Certificate", Certificates), FilesDetails, ErrorsText);
		
	MessageSubject1 = "";
	ErrorsText = ErrorsText + NStr("vi = 'Kết quả kiểm tra trên client';
									|ru = 'Результат проверки на клиенте';
									|en = 'Result of validation on client'; fa = 'Result of validation on client';
									|it = 'Результат проверки на клиенте';
									|pl = 'Wynik sprawdzenia na kliencie';
									|tr = 'İstemci kontrolünün sonucu'") + ":" + Chars.LF;
	SupplementTextWithErrors(ErrorsText, ChecksContent, False, MessageSubject1);
	
	ErrorsText = ErrorsText + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kết quả kiểm tra trên server ""%1"":';
			|ru = 'Результат проверки на сервере ""%1"":';
			|en = 'Result of verification on server ""%1"":'; fa = 'Result of verification on server ""%1"":';
			|it = 'Результат проверки на сервере ""%1"":';
			|pl = 'Wynik sprawdzenia na serwerze""%1"":';
			|tr = '""%1"" sunucusunda kontrolün sonucu:'"), ServerName) + Chars.LF;
	SupplementTextWithErrors(ErrorsText, ChecksContent, True, MessageSubject1);
	
	If ExportArchive Then
		DigitalSignatureInternalClient.GenerateTechnicalInformation(
			ErrorsText, Undefined, , FilesDetails);
	Else
		DigitalSignatureInternalClient.GenerateTechnicalInformation(
			ErrorsText, New Structure("Subject, Message",
				?(IsBlankString(MessageSubject1), NStr("vi = 'Vấn đề khi kiểm tra chứng thư chữ ký điện tử';
														|ru = 'Проблема при проверке сертификата электронной подписи';
														|en = 'Issue occurred verifying the signature certificate'; fa = 'Issue occurred verifying the signature certificate';
														|it = 'Проблема при проверке сертификата электронной подписи';
														|pl = 'Issue occurred verifying the signature certificate';
														|tr = 'Elektronik imza sertifikasını doğrulama hatası'"), MessageSubject1),
				DigitalSignatureInternalClient.TechnicalSupportRequestTextUponCertificateCheck()),
			Undefined, FilesDetails);
	EndIf;
	
EndProcedure

// Continues the Check procedure.
&AtClient
Procedure ValidateCompletion(Var_Undefined, Context) Export
	
	VisibilityOnCheckEnd();
	
	If TimestampCertificates.Count() = 0 Then
		Items.DecorationTimestampCertificate.Visible = False;
	Else
		Array = New Array;
		For Each TimestampCertificate In TimestampCertificates Do
			If Not TimestampCertificate.IsObtainedAtClient Then
				Array.Add(StringFunctionsClient.FormattedString(
							NStr("vi = 'Chứng thư dấu thời gian mà nhận được trên server: <a href = %1>%2</a>.';
								|ru = 'Сертификат метки времени, полученной на сервере: <a href = %1>%2</a>.';
								|en = 'Certificate of server-side timestamp: <a href = %1>%2</a>.'; fa = 'Certificate of server-side timestamp: <a href = %1>%2</a>.';
								|it = 'Сертификат метки времени, полученной на сервере: <a href = %1>%2</a>.';
								|pl = 'Certificate of server-side timestamp: <a href = %1>%2</a>.';
								|tr = 'Sunucuya alınan zaman damgasının sertifikası: <a href = %1>%2</a>.'"),
						TimestampCertificate.CertificateAddress, TimestampCertificate.Presentation));
			ElsIf Not TimestampCertificate.IsObtainedAtServer Then
				Array.Add(StringFunctionsClient.FormattedString(
							NStr("vi = 'Chứng thư dấu thời gian mà nhận được trên server: <a href = %1>%2</a>.';
								|ru = 'Сертификат метки времени, полученной на компьютере: <a href = %1>%2</a>.';
								|en = 'Certificate of computer-side timestamp: <a href = %1>%2</a>.'; fa = 'Certificate of computer-side timestamp: <a href = %1>%2</a>.';
								|it = 'Сертификат метки времени, полученной на компьютере: <a href = %1>%2</a>.';
								|pl = 'Certificate of computer-side timestamp: <a href = %1>%2</a>.';
								|tr = 'Bigisayara alınan zaman damgasının sertifikası: <a href = %1>%2</a>.'"),
						TimestampCertificate.CertificateAddress, TimestampCertificate.Presentation));
			Else
				Array.Add(StringFunctionsClient.FormattedString(
							NStr("vi = 'Chứng thư của dấu thời gian đã nhận: <a href = %1>%2</a>.';
								|ru = 'Сертификат полученной метки времени: <a href = %1>%2</a>.';
								|en = 'Timestamp certificate: <a href = %1>%2</a>.'; fa = 'Timestamp certificate: <a href = %1>%2</a>.';
								|it = 'Сертификат полученной метки времени: <a href = %1>%2</a>.';
								|pl = 'Timestamp certificate: <a href = %1>%2</a>.';
								|tr = 'Alınan zaman damgasının sertifikası: <a href = %1>%2</a>.'"),
						TimestampCertificate.CertificateAddress, TimestampCertificate.Presentation));
			EndIf;
		EndDo;
		Items.DecorationTimestampCertificate.Title = New FormattedString(Array);
		Items.DecorationTimestampCertificate.Visible = True;
	EndIf;
	
	If Not CheckOnSelection Then
		Return;
	EndIf;
	
	If ClientParameters.Result.ChecksPassed Then
		Close(True);
	Else
		ShowCannotContinueWarning();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure PagesVisibility(Form)
	If Form.AreChecksPassed = True Then
		Form.Items.GroupPages.CurrentPage = Form.Items.PageChecksPassed;
		Form.Items.FormClose.DefaultButton = True;
	Else
		Form.Items.GroupPages.CurrentPage = Form.Items.PageChecks;
	EndIf;
EndProcedure

// ACC:78-off - Intended for the secure transfer of data between forms on the client without sending it to the server.
&AtClient
Procedure ContinueOpening(Notification, CommonInternalData, IncomingClientParameters) Export
// ACC:78-on - Intended for the secure transfer of data between forms on the client without sending it to the server.
	
	InternalData = CommonInternalData;
	ClientParameters = IncomingClientParameters;
	ClientParameters.Insert("Result");
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("OnOpen", True);
	If ClientParameters.Property("SpecifiedContextOfOtherOperation") Then
		
		CertificateProperties = CommonInternalData;
		ClientParameters.OperationContext.ContinueOpening(
			Undefined, Undefined, CertificateProperties);
		
		If CertificateProperties.Certificate = Certificate Then
			PasswordProperties = CertificateProperties.PasswordProperties;
		EndIf;
		
		AdditionalParameters.Insert("PasswordSpecified1");
		AdditionalParameters.Insert("OnSetPasswordFromAnotherOperation", True);
		
	EndIf;
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, AdditionalParameters);
	
	Items.RememberPassword.Enabled = Items.Password.Enabled;
	If Not Items.Password.Enabled Then
		CurrentItem = Items.FormValidate;
	EndIf;
	
	If ClientParameters.Property("NoConfirmation")
		And ClientParameters.NoConfirmation
		And (AdditionalParameters.PasswordSpecified1
		Or AdditionalParameters.EnterPasswordInDigitalSignatureApplication) Then
		
		If Not ClientParameters.Property("ResultProcessing")
			Or TypeOf(ClientParameters.ResultProcessing) <> Type("CallbackDescription") Then
			
			Open();
		EndIf;
		
		Context = New Structure("Notification", Notification);
		
		CheckCertificate(New CallbackDescription(
			"ContinueOpeningAfterCertificateCheck", ThisObject, Context));
		
		Return;
		
	EndIf;
	
	Open();
	
	RunCallback(Notification);
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningAfterCertificateCheck(Result, Context) Export
	
	If ClientParameters.Result.ChecksPassed Then
		RunCallback(Context.Notification, True);
		Return;
	EndIf;
	
	VisibilityOnCheckEnd();
	
	If Not IsOpen()
		And Not (ClientParameters.Property("DontShowResults")
		And ClientParameters.DontShowResults) Then
		
		Open();
	EndIf;
	
	If CheckOnSelection Then
		ShowCannotContinueWarning();
	EndIf;
	
	RunCallback(Context.Notification);
	
EndProcedure

&AtClient
Procedure OnChangeSigningOrEncryptionUsage()
	
	RefreshVisibilityAtServer()
	
EndProcedure

&AtClient
Procedure ShowCannotContinueWarning()
	
	ShowMessageBox(,
		NStr("vi = 'Không thể tiếp tục vì chưa thực hiện kiểm tra tất cả những gì cần thiết.';
			|ru = 'Не удалось продолжить, т.к. пройдены не все требуемые проверки.';
			|en = 'Cannot continue as not all required checks are passed.'; fa = 'Cannot continue as not all required checks are passed.';
			|it = 'Non è stato possibile proseguire, poiché non tutte le verifiche richieste sono state effettuate.';
			|pl = 'Kontynuacja nie powiodła się, ponieważ nie zostały wykonane wszystkie wymagane procedury weryfikacji.';
			|tr = 'Tüm gereken denetimlerden geçilmediğinden devam edilemiyor.'"));
	
EndProcedure

&AtClient
Procedure CheckCertificate(Notification)
	
	PasswordAccepted = False;
	ChecksAtClient = New Structure;
	ChecksAtServer = New Structure;
	AdditionalDataChecksOnClient = New Structure;
	AdditionalDataChecksOnServer = New Structure;
	TimestampCertificates.Clear();
	Items.DecorationTimestampCertificate.Visible = False;
	
	AreChecksPassed = True;
	Items.GroupPages.Visible = True;
	Items.FormValidate.Enabled = False;
	Items.GroupPages.CurrentPage = Items.PageVerificationInProgress;
	
	// Clearing the previous check results.
	If StandardChecks Then
		
		BasicChecks = StandardChecks();
		If Not IsBuiltInCryptoProvider Then
			BasicChecks.Add("ProgramExists");
		EndIf;
		
		For Each Validation In BasicChecks Do
			SetItem(ThisObject, Validation, False, , , MergeResults);
			SetItem(ThisObject, Validation, True, , , MergeResults);
		EndDo;
		
	EndIf;
	
	For Each Validation In AdditionalChecks Do
		SetItem(ThisObject, Validation.Name, False, , , MergeResults);
		SetItem(ThisObject, Validation.Name, True, , , MergeResults);
	EndDo;
	
	Context = New Structure("Notification", Notification);
	
	CheckAtClientSide(New CallbackDescription(
		"CheckCertificateAfterCheckAtClient", ThisObject, Context));
	
EndProcedure

// Continues the CheckCertificate procedure.
&AtClient
Procedure CheckCertificateAfterCheckAtClient(Result, Context) Export
	
	If IsBuiltInCryptoProvider Or ThisServiceAccount Then
		
		If OperationsAtServer Then
			CheckAtServerSideAdditionalChecks(PasswordProperties.Value);
		EndIf;
		
		If StandardChecks Then
			Notification = New CallbackDescription("VerifyCertificateAfterVerificationOnClientServer", ThisObject,
				Context);
			NewContext = New Structure;
			NewContext.Insert("ServiceCertificateCheckOnClient", True);
			NewContext.Insert("ValidationInServiceInsteadofValidationOnServer", False);
			CheckAtClientSide(Notification, NewContext);
		Else
			VerifyCertificateAfterVerificationOnClientServer(Result, Context);
		EndIf;
		
	Else
		
		ValidateInServiceInsteadofValidateOnServer = StandardChecks
			And VerifyDigitalSignaturesOnTheServer
			And (HasBuiltinCryptoprovider Or HaveServiceAccount)
			And Not OperationsAtServer;
		
		If ValidateInServiceInsteadofValidateOnServer Then
			
			If OperationsAtServer Then
				CheckAtServerSideAdditionalChecks(PasswordProperties.Value);
			EndIf;
			
			If StandardChecks And TheOperationIsActive() Then
				Notification = New CallbackDescription("VerifyCertificateAfterVerificationOnClientServer", ThisObject,
					Context);
				NewContext = New Structure;
				NewContext.Insert("ValidationInServiceInsteadofValidationOnServer", True);
				NewContext.Insert("ServiceCertificateCheckOnClient", False);
				CheckAtClientSide(Notification, NewContext);
			Else
				VerifyCertificateAfterVerificationOnClientServer(Result, Context);
			EndIf;
			
		Else
			If OperationsAtServer Then
				If StandardChecks Then
					CheckAtServerSide(PasswordProperties.Value);
				Else
					CheckAtServerSideAdditionalChecks(PasswordProperties.Value);
				EndIf;
			EndIf;
			VerifyCertificateAfterVerificationOnClientServer(Result, Context);
		EndIf;
		
	EndIf;
		
EndProcedure

&AtClient
Procedure VerifyCertificateAfterVerificationOnClientServer(Result, Context) Export
	
	If PasswordAccepted Then
		DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
			InternalData, PasswordProperties, New Structure("OnOperationSuccess", True));
	EndIf;
	
	Result = New Structure;
	Result.Insert("ChecksPassed", False);
	Result.Insert("ChecksAtClient", ChecksAtClient);
	Result.Insert("ChecksAtServer", ChecksAtServer);
	Result.Insert("AdditionalDataChecksOnClient", AdditionalDataChecksOnClient);
	Result.Insert("AdditionalDataChecksOnServer", AdditionalDataChecksOnServer);
	
	ClientParameters.Insert("Result", Result);
	
	If ClientParameters.Property("ResultProcessing")
	   And TypeOf(ClientParameters.ResultProcessing) = Type("CallbackDescription") Then
		
		RunCallback(ClientParameters.ResultProcessing, Result.ChecksPassed);
	EndIf;
	
	RunCallback(Context.Notification);
	
EndProcedure

#Region CheckAtCleint

&AtClient
Procedure CheckAtClientSide(Notification, Context = Undefined)
	
	CheckCompleted = True;
	If Context = Undefined Then
		Context = New Structure;
		Context.Insert("ValidationInServiceInsteadofValidationOnServer", False);
		Context.Insert("ServiceCertificateCheckOnClient", False);
	EndIf;
	
	Context.Insert("Notification", Notification);
	
	If StandardChecks Then
		DigitalSignatureClient.InstallExtension(False, New CallbackDescription(
			"CheckAtClientSideAfterAttachCryptoExtension", ThisObject, Context),
			NStr("vi = 'Để tiếp tục, hãy cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
				|ru = 'Для продолжения установите расширение для работы с 1С:Предприятием.';
				|en = 'To continue, install 1C:Enterprise Extension.'; fa = 'To continue, install 1C:Enterprise Extension.';
				|it = 'Для продолжения установите расширение для работы с 1С:Предприятием.';
				|pl = 'W celu kontynuowania zainstaluj rozszerzenie do pracy z 1C:Enterprise.';
				|tr = 'Devam etmek için 1C:Enterprise ile çalışma uzantısını yükleyin.'"));
	Else
		Context.Insert("CryptoManager", Undefined);
		CheckAtClientSideAdditionalChecks(Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterAttachCryptoExtension(Attached, Context) Export
	
	CertificateData = GetFromTempStorage(CertificateAddress);
	Context.Insert("SignAlgorithm",
		DigitalSignatureInternalClientServer.CertificateSignAlgorithm(CertificateData));
	
	If Attached <> True Then
		
		CreationParameters = DigitalSignatureInternalClient.CryptoManagerCreationParameters();
		CreationParameters.ShowError = False;
		CreationParameters.SignAlgorithm = Context.SignAlgorithm;
		
		DigitalSignatureInternalClient.CreateCryptoManager(New CallbackDescription(
				"CheckAtClientSideAfterAttemptToCreateCryptoManager", ThisObject, Context),
			"CertificateCheck", CreationParameters);
		
		Return;
		
	EndIf;
	
	// Checking certificate data.
	Context.Insert("CertificateData", CertificateData);
	
	CryptoCertificate = New CryptoCertificate;
	CryptoCertificate.BeginInitialization(New CallbackDescription(
			"CheckAtClientSideAfterInitializeCertificate", ThisObject, Context,
			"CheckAtClientSideAfterCertificateInitializationError", ThisObject),
		Context.CertificateData);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterAttemptToCreateCryptoManager(Result, Context) Export
	
	SetItem(ThisObject, FirstCheckName, False, Result, False, MergeResults);
	RunCallback(Context.Notification);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterCertificateInitializationError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	SetItem(ThisObject, FirstCheckName, False, ErrorDescription, True, MergeResults);
	
	RunCallback(Context.Notification);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterInitializeCertificate(CryptoCertificate, Context) Export
	
	Context.Insert("CryptoCertificate", CryptoCertificate);
	
	// Verified certificate.
	CheckLegalCertificateAtClient(Context);
	
	Context.Insert("ThisOperationInService", False);
	
	// Availability of a certificate in the personal list.
	If ThisServiceAccount And Not Context.ServiceCertificateCheckOnClient Then
		
		Context.Insert("ThisOperationInService", True);
		TheNotificationIsAsFollows = New CallbackDescription("VerifyOnTheClientSideAfterAuthorizationInTheCloudSignature", ThisObject, Context);
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		TheDSSCryptographyServiceModuleClient.VerifyingUserAuthentication(TheNotificationIsAsFollows, Application);
		
	ElsIf HaveServiceAccount And Context.ValidationInServiceInsteadofValidationOnServer Then
		
		Context.Insert("ThisOperationInService", True);
		Context.Insert("UserSettings", Undefined);
		TheNotificationIsAsFollows = New CallbackDescription(
				"VerifyOnTheClientSideAfterVerifyingTheCloudSignatureCertificate", ThisObject, Context);
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		TheDSSCryptographyServiceModuleClient.CheckCertificate(TheNotificationIsAsFollows, Context.UserSettings, Context.CertificateData);
		
	ElsIf IsBuiltInCryptoProvider And Not Context.ServiceCertificateCheckOnClient Then
		
		Context.Insert("ThisOperationInService", True);
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Thumbprint", Context.CryptoCertificate.Thumbprint);
		ModuleCertificateStoreClient = CommonClient.CommonModule("CertificatesStorageClient");
		ModuleCertificateStoreClient.FindCertificate(New CallbackDescription(
			"CheckAtClientSideAfterCertificateSearchInSaaSMode", ThisObject, Context), TheStructureOfTheSearch);
	ElsIf HasBuiltinCryptoprovider And Context.ValidationInServiceInsteadofValidationOnServer Then
		
		Context.Insert("ThisOperationInService", True);
		// Checking certificate data.
		ModuleCryptographyServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
			
		ModuleCryptographyServiceClient.CheckCertificate(New CallbackDescription(
			"CheckAtClientSideAfterCertificateCheckInSaaSMode", ThisObject, Context),
			Context.CertificateData);
	Else
		If Context.ServiceCertificateCheckOnClient Then
			CreationParameters = DigitalSignatureInternalClient.CryptoManagerCreationParameters();
			CreationParameters.SignAlgorithm = Context.SignAlgorithm;
			CreationParameters.ShowError = False;
	
			// Checking certificate data.
			DigitalSignatureInternalClient.CreateCryptoManager(
				New CallbackDescription("CheckAtClientSideAfterCreateAnyCryptoManager",
				ThisObject, Context), "CertificateCheck", CreationParameters);
		Else
			DigitalSignatureInternalClient.GetCertificateByThumbprint(New CallbackDescription(
				"CheckAtClientSideAfterCertificateSearch", ThisObject, Context),
				Base64String(Context.CryptoCertificate.Thumbprint), True, Undefined);
		EndIf;	
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckLegalCertificateAtClient(Context)
	
	If Not Items.LegalCertificateGroup.Visible
	 Or Context.CryptoCertificate.Subject.Property("SN") Then
		
		ErrorDescription = "";
	Else
		ErrorDescription = NStr("vi = 'Không tìm thấy trường ""SN"" trong mô tả chủ thể chứng chỉ.';
								|ru = 'В описании субъекта сертификата не найдено поле ""SN"".';
								|en = 'The ""SN"" field is not found in the certificate subject description.'; fa = 'The ""SN"" field is not found in the certificate subject description.';
								|it = 'Nella descrizione del soggetto del certificato non è stato trovato il campo ""SN"".';
								|pl = 'W opisie podmiotu certyfikatu nie znaleziono pola ""SN"".';
								|tr = 'Sertifika nesne açıklamasında ""SN"" alanı bulunamadı.'");
	EndIf;
	SetItem(ThisObject, "LegalCertificate", False, ErrorDescription, , MergeResults);

EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterCertificateSearch(Result, Context) Export
	
	If TypeOf(Result) = Type("CryptoCertificate") Then
		SetItem(ThisObject, "CertificateExists", False, "", , MergeResults);
	Else
		SetItem(ThisObject, "CertificateExists", False,
			?(TypeOf(Result) = Type("String"), Result, Result.ErrorDescription) + Chars.LF + Chars.LF
			+ NStr("vi = 'Không thể kiểm tra ký tên, chữ ký đã tạo và giải mã.';
					|ru = 'Проверка подписания, созданной подписи и расшифровки не могут быть выполнены.';
					|en = 'Cannot check signing, created signature and decryption.'; fa = 'Cannot check signing, created signature and decryption.';
					|it = 'Non è possibile eseguire la verifica della firma, della firma creata e della decrittografia.';
					|pl = 'Weryfikacja pisowni, utworzonego podpisu i deszyfracji nie mogą zostać wykonane.';
					|tr = 'İmza doğrulama, oluşturulan imza ve şifre çözme işlemi yapılamaz.'"),
			True, MergeResults);
	EndIf;
	
	CreationParameters = DigitalSignatureInternalClient.CryptoManagerCreationParameters();
	CreationParameters.SignAlgorithm = Context.SignAlgorithm;
	CreationParameters.ShowError = False;
	
	// Checking certificate data.
	DigitalSignatureInternalClient.CreateCryptoManager(New CallbackDescription(
		"CheckAtClientSideAfterCreateAnyCryptoManager", ThisObject, Context),
		"CertificateCheck", CreationParameters);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
// 
// Parameters:
//  Result - Structure:
//   * ErrorDescription - Structure:
//      ** LongDesc - String
//
&AtClient
Procedure CheckAtClientSideAfterCertificateSearchInSaaSMode(Result, Context) Export
	
	ErrorDescription = "";
	If Not Result.Completed2 Then
		ErrorDescription = Result.ErrorDescription.LongDesc;
	ElsIf Not ValueIsFilled(Result.Certificate) Then
		ErrorDescription = NStr("vi = 'Không tồn tại chứng chỉ trong dịch vụ (có thể là đã bị xóa).';
								|ru = 'Сертификат отсутствует в сервисе (возможно удален).';
								|en = 'The certificate does not exist in the service. It might have been deleted.'; fa = 'The certificate does not exist in the service. It might have been deleted.';
								|it = 'Certificato assente nel servizio (forse eliminato).';
								|pl = 'Brak certyfikatu w usłudze (mógł być usunięty).';
								|tr = 'Hizmette sertifika eksik (silinmiş olabilir).'");
	EndIf;
	If Not IsBlankString(ErrorDescription) Then
		ErrorDescription = ErrorDescription + Chars.LF
			+ NStr("vi = 'Không thể kiểm tra ký tên, chữ ký đã tạo và giải mã.';
					|ru = 'Проверка подписания, созданной подписи и расшифровки не могут быть выполнены.';
					|en = 'Cannot check signing, created signature and decryption.'; fa = 'Cannot check signing, created signature and decryption.';
					|it = 'Non è possibile eseguire la verifica della firma, della firma creata e della decrittografia.';
					|pl = 'Weryfikacja pisowni, utworzonego podpisu i deszyfracji nie mogą zostać wykonane.';
					|tr = 'İmza doğrulama, oluşturulan imza ve şifre çözme işlemi yapılamaz.'");
	EndIf;
	SetItem(ThisObject, "CertificateExists", True, ErrorDescription, , MergeResults);
	
	// If the certificate is not found in the certificate store, checks stop.
	If Not IsBlankString(ErrorDescription) Then
		RunCallback(Context.Notification);
		Return;
	EndIf;
	
	// Checking certificate data.
	ModuleCryptographyServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
		
	ModuleCryptographyServiceClient.CheckCertificate(New CallbackDescription(
			"CheckAtClientSideAfterCertificateCheckInSaaSMode", ThisObject, Context),
			Result.Certificate.Certificate);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterCreateAnyCryptoManager(Result, Context) Export
	
	If TypeOf(Result) = Type("CryptoManager") Then
		AdditionalInspectionParameters = DigitalSignatureInternalClient.AdditionalCertificateVerificationParameters();
		AdditionalInspectionParameters.PerformCAVerification = DigitalSignatureInternalClientServer.NotVerifyCertificate();
		AdditionalInspectionParameters.MergeCertificateDataErrors = False;
		AdditionalInspectionParameters.CheckInServiceAfterError = False;
		DigitalSignatureInternalClient.CheckCertificate(New CallbackDescription(
				"CheckAtClientSideAfterCertificateCheck", ThisObject, Context),
			Context.CryptoCertificate, Result,,AdditionalInspectionParameters);
		Return;
	EndIf;
		
	StandardProcessing = True;
	DigitalSignatureClientLocalization.OnGettingTokenByCertificate(
		New CallbackDescription("AfterGettingTokenByCertificate", ThisObject, 
			New Structure("Context, Result", Context, Result)),
		Context.CryptoCertificate, StandardProcessing, True, True);
		
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	CheckAtClientSideAfterCertificateCheck(Result, Context);

EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Async Procedure AfterGettingTokenByCertificate(Token, AdditionalParameters) Export
	
	If Not ValueIsFilled(Token) Then
		CheckAtClientSideAfterCertificateCheck(AdditionalParameters.Result, AdditionalParameters.Context);
		Return;
	EndIf;
	
	Context = AdditionalParameters.Context;
	
	Context.Insert("CryptoManager", Undefined);
	Token.Insert("Password", PasswordProperties.Value);
	Context.Insert("Token", Token);
	
	If AdditionalParameters.Result = True Then
		ErrorDetailsAtClient = "";
	ElsIf TypeOf(AdditionalParameters.Result) = Type("Structure") Then
		ErrorDetailsAtClient = AdditionalParameters.Result.ErrorDetailsAtClient;
	Else
		ErrorDetailsAtClient = AdditionalParameters.Result;
	EndIf;
	
	SetItem(ThisObject, "CertificateData", False,
		NStr("vi = 'Việc kiểm tra mức độ đúng đắn của chứng thư bằng các công cụ của token sẽ có trong các phiên bản sau của ứng dụng.';
			|ru = 'Проверка корректности сертификата средствами токена появится в следующих версиях приложения.';
			|en = 'Certificate validation using the token''s built-in mechanisms will be released later.'; fa = 'Certificate validation using the token''s built-in mechanisms will be released later.';
			|it = 'Certificate validation using the token''s built-in mechanisms will be released later.';
			|pl = 'Certificate validation using the token''s built-in mechanisms will be released later.';
			|tr = 'Sertifikanın geçerliliğinin token ile doğrulaması, uygulamanın sonraki sürümlerinde mevcuttur.'"),
		True, MergeResults);
	
	SetItem(ThisObject, "ProgramExists", False, NStr("vi = 'Việc kiểm tra chứng thư được thực hiện bằng các công cụ của token.';
													|ru = 'Проверка сертификата выполняется средствами токена.';
													|en = 'Certificate is validated using the token''s built-in mechanisms.'; fa = 'Certificate is validated using the token''s built-in mechanisms.';
													|it = 'Certificate is validated using the token''s built-in mechanisms.';
													|pl = 'Certificate is validated using the token''s built-in mechanisms.';
													|tr = 'Sertifika kontrolü, token aracılığıyla gerçekleştirilir.'" + Chars.LF + ErrorDetailsAtClient),
		False, MergeResults);
		
	// Signing
	ErrorDescription = Await AdditionalCheckOnthePossibilityofSigning(Context.CryptoCertificate, False);
	SignatureData = Undefined;
	If Not ValueIsFilled(ErrorDescription) Then
		SignatureParameters = DigitalSignatureInternalClient.ParametersOfSignatureOnToken(Token, 
			Context.CryptoCertificate, PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES"));
		
		StandardProcessing = True;
		NotificationAfterOperationOnToken = New CallbackDescription("AfterSigningOnToken", ThisObject, Context);
		DigitalSignatureClientLocalization.OnSigningOnToken(NotificationAfterOperationOnToken, SignatureParameters,
			Context.CertificateData, StandardProcessing);
		If Not StandardProcessing Then
			Return;
		EndIf;
		
		SetItem(ThisObject, "Signing", False, NStr("ru = 'Не найдена процедура подписания для токена.';
													|vi = 'Signing procedure for the token not found.';
													|en = 'Signing procedure for the token not found.'; fa = 'Signing procedure for the token not found.';
													|it = 'Signing procedure for the token not found.';
													|pl = 'Signing procedure for the token not found.';
													|tr = 'Token için imzalama prosedürü bulunamadı.'"), True, MergeResults);
	Else
		SetItem(ThisObject, "Signing", False, ErrorDescription, True, MergeResults);
	EndIf;
	
	AfterSignatureInTokenChecked(Undefined, Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Async Procedure AfterSigningOnToken(SignatureData, Context) Export

	If TypeOf(SignatureData) <> Type("String") And ValueIsFilled(SignatureType) And SignatureType <> PredefinedValue(
			"Enum.CryptographySignatureTypes.BasicCAdESBES") And SignatureType <> PredefinedValue(
			"Enum.CryptographySignatureTypes.NormalCMS") Then
		SignatureParameters = DigitalSignatureInternalClient.ParametersOfSignatureOnToken(Context.Token,
			Context.CryptoCertificate, SignatureType);

		StandardProcessing = True;
		NotificationAfterOperationOnToken = New CallbackDescription("AfterSigningOnTokenWithSignatureType", ThisObject,
			Context);
		DigitalSignatureClientLocalization.OnSigningOnToken(NotificationAfterOperationOnToken, SignatureParameters,
			Context.CertificateData, StandardProcessing);
		If Not StandardProcessing Then
			Return;
		EndIf;
	EndIf;
	
	AfterSigningOnTokenWithSignatureType(SignatureData, Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Async Procedure AfterSigningOnTokenWithSignatureType(SignatureData, Context) Export
	
	ErrorDescription = "";
	
	If TypeOf(SignatureData) = Type("String") Then
		ErrorDescription = SignatureData;
	EndIf;
	
	If TypeOf(SignatureData) = Type("BinaryData") Then
		PasswordAccepted = True;
		SignatureVerificationParameters = New Structure;
		SignatureVerificationParameters.Insert("Signature", SignatureData);
		SignatureVerificationParameters.Insert("SignAlgorithm", Context.SignAlgorithm);
		SignatureVerificationParameters.Insert("CheckResult", DigitalSignatureClientServer.SignatureVerificationResult());
		SignatureVerificationParameters.Insert("Notification", New CallbackDescription("AfterSignatureInTokenChecked", ThisObject, Context));
		SignatureVerificationParameters.Insert("VerifyCertificate",
			DigitalSignatureInternalClientServer.NotVerifyCertificate());
		SignatureVerificationParameters.Insert("RawData", Context.CertificateData);
		DigitalSignatureInternalClient.VerifySignatureUsingToken(SignatureVerificationParameters);
	Else
		AfterSignatureInTokenChecked(Undefined, Context);
	EndIf;
	
	SetItem(ThisObject, "Signing", False, ErrorDescription, True, MergeResults);
	
EndProcedure

// Continues the "CheckAtClientSide" procedure.
&AtClient
Async Procedure AfterSignatureInTokenChecked(Result, Context) Export
	
	If Result <> Undefined Then
		If Result.SignatureCorrect <> True Then
			ErrorDescription = ?(ValueIsFilled(Result.SignatureMathValidationError),
				Result.SignatureMathValidationError, Result.AdditionalAttributesCheckError);
			SetItem(ThisObject, "CheckSignature", False, ErrorDescription, True, MergeResults);
		Else
			SetItem(ThisObject, "CheckSignature", False, "", False, MergeResults);
		EndIf;
	EndIf;
	
	EncryptionParameters = DigitalSignatureInternalClient.EncryptionOnTokenParameters(Context.Token,
		Context.CryptoCertificate);
	StandardProcessing = True;
	NotificationAfterOperationOnToken = New CallbackDescription("AfterEncryptionOnToken", ThisObject, Context);
	DigitalSignatureClientLocalization.OnEncryptionOnToken(NotificationAfterOperationOnToken,
		EncryptionParameters, Context.CertificateData, StandardProcessing);
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	RunCallback(NotificationAfterOperationOnToken, NStr("ru = 'Не найдена процедура шифрования для токена.';
														|vi = 'Encryption procedure for the token not found.';
														|en = 'Encryption procedure for the token not found.'; fa = 'Encryption procedure for the token not found.';
														|it = 'Encryption procedure for the token not found.';
														|pl = 'Encryption procedure for the token not found.';
														|tr = 'Token için şifreleme prosedürü bulunamadı.'"));
		
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure AfterEncryptionOnToken(EncryptedData, Context) Export
	
	If TypeOf(EncryptedData) = Type("String") Then
		SetItem(ThisObject, "Encryption", False, EncryptedData, True, MergeResults);
		CheckAtClientSideAdditionalChecks(Context);
	Else
		
		If TypeOf(EncryptedData) <> Type("BinaryData") Then
			SetItem(ThisObject, "Encryption", False, NStr(
				"ru = 'Не удалось зашифровать данные средствами токена.';
				|vi = 'Couldn''t encrypt data using the token.';
				|en = 'Couldn''t encrypt data using the token.'; fa = 'Couldn''t encrypt data using the token.';
				|it = 'Couldn''t encrypt data using the token.';
				|pl = 'Couldn''t encrypt data using the token.';
				|tr = 'Veriler, token aracılığıyla şifrelenemedi.'"), True, MergeResults);
			CheckAtClientSideAdditionalChecks(Context);
		Else
			SetItem(ThisObject, "Encryption", False, "", False, MergeResults);
			
			DetailsParameters = DigitalSignatureInternalClient.DecryptionOnTokenParameters(Context.Token, 
						Context.CryptoCertificate);
			NotificationAfterOperationOnToken = New CallbackDescription("AfterDecryptionOnToken",
				ThisObject, Context);
			StandardProcessing = True;
			DigitalSignatureClientLocalization.OnDecryptionOnToken(NotificationAfterOperationOnToken,
				DetailsParameters, EncryptedData, StandardProcessing);
			If Not StandardProcessing Then
				Return;
			EndIf;
					
			RunCallback(NotificationAfterOperationOnToken, 
				NStr("ru = 'Не найдена процедура расшифровки для токена.';
					|vi = 'Decryption procedure for the token not found.';
					|en = 'Decryption procedure for the token not found.'; fa = 'Decryption procedure for the token not found.';
					|it = 'Decryption procedure for the token not found.';
					|pl = 'Decryption procedure for the token not found.';
					|tr = 'Token için şifre çözme prosedürü bulunamadı.'"));
			
		EndIf;
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure AfterDecryptionOnToken(DecryptedData, Context) Export
	If TypeOf(DecryptedData) = Type("String") Then
		SetItem(ThisObject, "Details", False, DecryptedData, True, MergeResults);

	Else
		SetItem(ThisObject, "Details", False, "", False, MergeResults);
	EndIf;
	
	CheckAtClientSideAdditionalChecks(Context);
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Async Procedure CheckAtClientSideAfterCertificateCheck(Result, Context) Export
	
	If Result = True Then
		ErrorDetailsAtClient = "";
	ElsIf TypeOf(Result) = Type("Structure") Then
		ErrorDetailsAtClient = Result.ErrorDetailsAtClient;
	Else
		ErrorDetailsAtClient = Result;
	EndIf;
	
	SetItem(ThisObject, "CertificateData", False, ErrorDetailsAtClient, True, MergeResults);
	
	If Context.ServiceCertificateCheckOnClient Then
		RunCallback(Context.Notification);
		Return;
	EndIf;
	
	// App availability.
	If ValueIsFilled(Application) Then
		
		CreationParameters = DigitalSignatureInternalClient.CryptoManagerCreationParameters();
		CreationParameters.Application = Application;
		CreationParameters.ShowError = False;
		CreationParameters.InteractiveMode = CertificateEnterPasswordInElectronicSignatureProgram;
		
		DigitalSignatureInternalClient.CreateCryptoManager(New CallbackDescription(
				"CheckAtClientSideAfterCreateCryptoManager", ThisObject, Context),
			"CertificateCheck", CreationParameters);
		
	Else
		
		AppAutoAtClientResult = Await DigitalSignatureInternalClient.AppForCertificate(
			CertificateAddress);
		AppAutoAtClient = AppAutoAtClientResult.Application;
		If AppAutoAtClientResult.Application = Undefined Then
			ErrorDescription = DigitalSignatureInternalClientServer.ErrorTextFailedToDefineApp(
				AppAutoAtClientResult.Error);
			CheckAtClientSideAfterCreateCryptoManager(ErrorDescription, Context);
		Else
			CreationParameters = DigitalSignatureInternalClient.CryptoManagerCreationParameters();
			CreationParameters.Application = AppAutoAtClient;
			CreationParameters.ShowError = False;
			CreationParameters.InteractiveMode = CertificateEnterPasswordInElectronicSignatureProgram;

			DigitalSignatureInternalClient.CreateCryptoManager(
				New CallbackDescription("CheckAtClientSideAfterCreateCryptoManager", ThisObject,
				Context), "CertificateCheck", CreationParameters);
		EndIf;
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
// 
// Parameters:
//  Result - Structure:
//   * ErrorInfo - Structure:
//      ** LongDesc - String
//  Context - Structure
//
&AtClient
Procedure CheckAtClientSideAfterCertificateCheckInSaaSMode(Result, Context) Export
	
	If Result.Completed2 And Result.Valid1 Then
		ErrorDescription = "";
	Else
		ErrorDescription = Result.ErrorInfo.LongDesc;
	EndIf;
	
	SetItem(ThisObject, "CertificateData", True, ErrorDescription, True, MergeResults);
	
	If Context.ValidationInServiceInsteadofValidationOnServer Then
		RunCallback(Context.Notification);
		Return;
	EndIf;
	
	// App availability.
	If ValueIsFilled(Application) Then
		CheckAtClientSideInSaaSMode("CryptographyService", Context);
	Else
		ErrorDescription = NStr("vi = 'Trong chứng thư, không chỉ ra ứng dụng để sử dụng khóa đóng.';
								|ru = 'В сертификате не указано приложение для использования закрытого ключа.';
								|en = 'The certificate does not specify an application for using the private key.'; fa = 'The certificate does not specify an application for using the private key.';
								|it = 'The certificate does not specify an application for using the private key.';
								|pl = 'The certificate does not specify an application for using the private key.';
								|tr = 'Sertifikada özel anahtarı kullanabilecek bir uygulama belirtilmemiştir.'");
		CheckAtClientSideAfterCreateCryptoManager(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Async Procedure CheckAtClientSideAfterCreateCryptoManager(Result, Context) Export
	
	Context.Insert("CryptoManager", Undefined);
	
	If TypeOf(Result) = Type("CryptoManager") Then
		Context.CryptoManager = Result;
		ErrorDescription = "";
	Else
		ErrorDescription = Result + Chars.LF + Chars.LF
			+ NStr("vi = 'Không thể kiểm tra ký tên, chữ ký đã tạo, mã hóa và 
			             |giải mã.';
			             |ru = 'Проверка подписания, созданной подписи, шифрования и
			             |расшифровки не могут быть выполнены.';
			             |en = 'Cannot verify signing, signature, 
			             |decryption and encryption. '; fa = 'Cannot verify signing, signature, 
			             |decryption and encryption. ';
			             |it = 'Non è possibile eseguire la verifica della firma, della firma creata, della crittografia e della 
			             |decrittografia.';
			             |pl = 'Weryfikacja pisowni, utworzonego podpisu i
			             |deszyfracji nie mogą zostać wykonane.';
			             |tr = 'İmza doğrulama, oluşturulan imza, şifreleme ve
			             | şifre çözme işlemi yapılamaz.'");
	EndIf;
	SetItem(ThisObject, "ProgramExists", Context.ThisOperationInService, ErrorDescription, True, MergeResults);
	
	If Context.CryptoManager = Undefined Then
		RunCallback(Context.Notification);
		Return;
	EndIf;
	
	If Not DigitalSignatureInternalClient.InteractiveCryptographyModeUsed(Context.CryptoManager) Then
		Context.CryptoManager.PrivateKeyAccessPassword = PasswordProperties.Value;
	EndIf;
	
	ErrorDescription = Await AdditionalCheckOnthePossibilityofSigning(Context.CryptoCertificate, False);
	
	// Signing
	If ChecksAtClient.CertificateExists = True And Not ValueIsFilled(ErrorDescription) Then
		
		Try
			SignatureData = Await Context.CryptoManager.SignAsync(Context.CertificateData, Context.CryptoCertificate);
			DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorDescription);
		Except
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		
		If ValueIsFilled(ErrorDescription) Then
			SetItem(ThisObject, "Signing", False, ErrorDescription, True, MergeResults);
			CheckAtClientSideAfterSigning(Null, Context);
			Return;
		Else
			PasswordAccepted = True;
		EndIf;
		
		If ValueIsFilled(SignatureType) And SignatureType <> PredefinedValue("Enum.CryptographySignatureTypes.BasicCAdESBES")
			And SignatureType <> PredefinedValue("Enum.CryptographySignatureTypes.NormalCMS") Then
			
			Try
				SettingsSignatures = DigitalSignatureInternalClientServer.SignatureCreationSettings(SignatureType,
					DigitalSignatureClient.CommonSettings().TimestampServersAddresses);
				Context.CryptoManager.TimestampServersAddresses = SettingsSignatures.TimestampServersAddresses;
				DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorDescription);
			Except
				ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			EndTry;

			If ValueIsFilled(ErrorDescription) Then
				SetItem(ThisObject, "Signing", False, ErrorDescription, True, MergeResults);
				CheckAtClientSideAfterSigning(Null, Context);
				Return;
			EndIf;

			Try
				SignatureData = Await Context.CryptoManager.SignAsync(Context.CertificateData, Context.CryptoCertificate, 
					SettingsSignatures.SignatureType);
			Except
				ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			EndTry;
			
			If ValueIsFilled(ErrorDescription) Then
				SetItem(ThisObject, "Signing", False, ErrorDescription, True, MergeResults);
				CheckAtClientSideAfterSigning(Null, Context);
				Return;
			EndIf;

		EndIf;
		
		CheckAtClientSideAfterSigning(SignatureData, Context);
		
	Else
		CheckAtClientSideAfterSigning(Null, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Async Procedure CheckAtClientSideInSaaSMode(Result, Context)
	
	Context.Insert("CryptoManager", Undefined);
	
	If TypeOf(Result) = Type("String") And Result = "CryptographyService" Then
		Context.CryptoManager = Result;
		ErrorDescription = "";
	Else
		ErrorDescription = Result + Chars.LF + Chars.LF
			+ NStr("vi = 'Không thể kiểm tra ký tên, chữ ký đã tạo, mã hóa và
			             |giải mã.';
			             |ru = 'Проверка подписания, созданной подписи, шифрования и
			             |расшифровки не могут быть выполнены.';
			             |en = 'Cannot verify signing, signature, 
			             |decryption and encryption. '; fa = 'Cannot verify signing, signature, 
			             |decryption and encryption. ';
			             |it = 'Non è possibile eseguire la verifica della firma, della firma creata, della crittografia e della 
			             |decrittografia.';
			             |pl = 'Weryfikacja pisowni, utworzonego podpisu i
			             |deszyfracji nie mogą zostać wykonane.';
			             |tr = 'İmza doğrulama, oluşturulan imza, şifreleme ve
			             | şifre çözme işlemi yapılamaz.'");
	EndIf;
	SetItem(ThisObject, "ProgramExists", True, ErrorDescription, True, MergeResults);
	
	If Context.CryptoManager = Undefined Then
		RunCallback(Context.Notification);
		Return;
	EndIf;
	
	ErrorDescription = Await AdditionalCheckOnthePossibilityofSigning(Context.CryptoCertificate, True);
	
	// Signing.
	If ChecksAtClient.CertificateExists = True And Not ValueIsFilled(ErrorDescription) Then
		ModuleCryptographyServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
		ModuleCryptographyServiceClient.Sign(New CallbackDescription(
				"CheckAtClientSideAfterSigningSaaS", ThisObject, Context,
				"CheckAtClientSideAfterSigningError", ThisObject),
			Context.CertificateData, Context.CertificateData);
	Else
		CheckAtClientSideAfterSigningSaaS(Null, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterSigningError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	CheckAtClientSideAfterSigning(ErrorProcessing.BriefErrorDescription(ErrorInfo), Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterSigning(SignatureData, Context)
	
	If SignatureData <> Null Then
		If TypeOf(SignatureData) = Type("String") Then
			ErrorDescription = SignatureData;
		Else
			ErrorDescription = "";
			DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorDescription);
		EndIf;
		If Not ValueIsFilled(ErrorDescription) Then
			PasswordAccepted = True;
		EndIf;
		SetItem(ThisObject, "Signing", Context.ThisOperationInService, ErrorDescription, True, MergeResults);
	EndIf;
	
	// Check the signature.
	If SignatureData <> Null And ChecksAtClient.CertificateExists = True And Not ValueIsFilled(ErrorDescription) Then
		Context.Insert("SignatureData", SignatureData);
		Context.CryptoManager.BeginVerifyingSignature(New CallbackDescription(
				"CheckAtClientSideAfterCheckSignature", ThisObject, Context,
				"CheckAtClientSideAfterCheckSignatureError", ThisObject),
			Context.CertificateData, SignatureData);
	Else
		CheckAtClientSideAfterCheckSignature(Null, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
// 
// Parameters:
//  SignatureData - Structure:
//   * ErrorInfo - Structure:
//      ** LongDesc - String
//  Context - Structure
//
&AtClient
Procedure CheckAtClientSideAfterSigningSaaS(SignatureData, Context) Export
	
	If TypeOf(SignatureData) = Type("Structure") Then
		If Not SignatureData.Completed2 Then
			ErrorDescription = SignatureData.ErrorInfo.LongDesc;
		Else
			ErrorDescription = "";
			SignatureData = SignatureData.Signature;
			DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorDescription);
		EndIf;
		If Not ValueIsFilled(ErrorDescription) Then
			PasswordAccepted = True;
		EndIf;
		SetItem(ThisObject, "Signing", True, ErrorDescription, True, MergeResults);
	EndIf;
	
	// Check the signature.
	If SignatureData <> Null And ChecksAtServer.CertificateExists = True And Not ValueIsFilled(ErrorDescription) Then
		ModuleCryptographyServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
		ModuleCryptographyServiceClient.VerifySignature(New CallbackDescription(
					"CheckAtClientSideAfterCheckSignatureInSaaSMode", ThisObject, Context,
					"CheckAtClientSideAfterCheckSignatureError", ThisObject),
				SignatureData, Context.CertificateData);
	Else
		CheckAtClientSideAfterCheckSignatureInSaaSMode(Null, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterCheckSignatureError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	CheckAtClientSideAfterCheckSignature(ErrorProcessing.BriefErrorDescription(ErrorInfo), Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Async Procedure CheckAtClientSideAfterCheckSignature(Certificate, Context) Export
	
	If Certificate <> Null Then
		If TypeOf(Certificate) = Type("String") Then
			ErrorDescription = Certificate;
		Else
			ErrorDescription = "";
		EndIf;
		
		If Not ValueIsFilled(ErrorDescription) And ValueIsFilled(SignatureType) And SignatureType
			<> PredefinedValue(
		"Enum.CryptographySignatureTypes.BasicCAdESBES") And SignatureType <> PredefinedValue(
		"Enum.CryptographySignatureTypes.NormalCMS") Then

			Try
				SignatureProperties = Await DigitalSignatureInternalClient.SignaturePropertiesReadByCryptoManager(
					Context.SignatureData, Context.CryptoManager, True);
			Except
				ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			EndTry;

			If Not ValueIsFilled(ErrorDescription) And ValueIsFilled(SignatureProperties.ErrorText) Then
				ErrorDescription = SignatureProperties.ErrorText;
			ElsIf Not ValueIsFilled(ErrorDescription) Then
				TimestampCertificateData = SignatureProperties.Certificates[SignatureProperties.Certificates.UBound()];
				TimestampCertificate = New CryptoCertificate();
				Await TimestampCertificate.InitializeAsync(TimestampCertificateData);
				CertificateProperties = DigitalSignatureInternalClientServer.CertificateProperties(
					TimestampCertificate, DigitalSignatureInternalClient.UTCOffset());
				
				Found4 = TimestampCertificates.FindRows(New Structure("Thumbprint",
					CertificateProperties.Thumbprint));

				If Found4.Count() = 0 Then
					NewRow = TimestampCertificates.Add();
					NewRow.CertificateAddress = PutToTempStorage(TimestampCertificateData,
						UUID);
					NewRow.Thumbprint = CertificateProperties.Thumbprint;
					NewRow.IsObtainedAtClient = True;
					NewRow.Presentation = CertificateProperties.Presentation;
				Else
					Found4[0].IsObtainedAtClient = True;
				EndIf;
			EndIf;
		EndIf;
		
		SetItem(ThisObject, "CheckSignature", False, ErrorDescription, True, MergeResults);
		
	EndIf;
	
	Context.CryptoManager.BeginEncrypting(New CallbackDescription(
			"CheckAtClientSideAfterEncryption", ThisObject, Context,
			"CheckAtClientSideAfterEncryptionError", ThisObject),
		Context.CertificateData, Context.CryptoCertificate);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
// 
// Parameters:
//  Result - Structure:
//   * ErrorInfo - Structure:
//      ** LongDesc - String
//  Context - Structure
//
&AtClient
Procedure CheckAtClientSideAfterCheckSignatureInSaaSMode(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") Then
		If Not Result.Completed2 Then
			ErrorDescription = Result.ErrorInfo.LongDesc;
		Else
			ErrorDescription = "";
		EndIf;
		SetItem(ThisObject, "CheckSignature", True, ErrorDescription, True, MergeResults);
	EndIf;
	
	ModuleCryptographyServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
	ModuleCryptographyServiceClient.Encrypt(New CallbackDescription(
			"CheckAtClientSideAfterEncryptionInSaaSMode", ThisObject, Context,
			"CheckAtClientSideAfterEncryptionError", ThisObject),
			Context.CertificateData, Context.CertificateData);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterEncryptionError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	CheckAtClientSideAfterEncryption(ErrorProcessing.BriefErrorDescription(ErrorInfo), Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterEncryption(EncryptedData, Context) Export
	
	If TypeOf(EncryptedData) = Type("String") Then
		ErrorDescription = EncryptedData;
	Else
		ErrorDescription = "";
		DigitalSignatureInternalClientServer.BlankEncryptedData(EncryptedData, ErrorDescription);
	EndIf;
	SetItem(ThisObject, "Encryption", Context.ThisOperationInService, ErrorDescription, True, MergeResults);
	
	// Decryption.
	If ChecksAtClient.CertificateExists = True And Not ValueIsFilled(ErrorDescription) Then
		Context.CryptoManager.BeginDecrypting(New CallbackDescription(
				"CheckAtClientSideAfterDecryption", ThisObject, Context,
				"CheckAtClientSideAfterDecryptionError", ThisObject),
			EncryptedData);
	Else
		CheckAtClientSideAfterDecryption(Null, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
// 
// Parameters:
//  Result - Structure:
//   * ErrorInfo - Structure:
//      ** LongDesc - String
//  Context - Structure
//
&AtClient
Procedure CheckAtClientSideAfterEncryptionInSaaSMode(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") Then
		If Not Result.Completed2 Then
			ErrorDescription = Result.ErrorInfo.LongDesc;
		Else
			ErrorDescription = "";
			EncryptedData = Result.EncryptedData;
			DigitalSignatureInternalClientServer.BlankEncryptedData(EncryptedData, ErrorDescription);
		EndIf;
	EndIf;
	SetItem(ThisObject, "Encryption", True, ErrorDescription, True, MergeResults);
	
	// Decryption.
	If ChecksAtServer.CertificateExists = True And Not ValueIsFilled(ErrorDescription) Then
		ModuleCryptographyServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
		ModuleCryptographyServiceClient.Decrypt(New CallbackDescription(
				"CheckAtClientSideAfterDecryptionInSaaSMode", ThisObject, Context,
				"CheckAtClientSideAfterDecryptionError", ThisObject),
			Result.EncryptedData);
	Else
		CheckAtClientSideAfterDecryptionInSaaSMode(Null, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterDecryptionError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	CheckAtClientSideAfterDecryption(ErrorProcessing.BriefErrorDescription(ErrorInfo), Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterDecryption(DecryptedData, Context) Export
	
	If DecryptedData <> Null Then
		If TypeOf(DecryptedData) = Type("String") Then
			ErrorDescription = DecryptedData;
		Else
			ErrorDescription = "";
			DigitalSignatureInternalClientServer.BlankDecryptedData(DecryptedData, ErrorDescription);
		EndIf;
		SetItem(ThisObject, "Details", Context.ThisOperationInService, ErrorDescription, True, MergeResults);
	EndIf;
	
	CheckAtClientSideAdditionalChecks(Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
// 
// Parameters:
//  Result - Structure:
//   * ErrorInfo - Structure:
//      ** LongDesc - String
//  Context - Structure
//
&AtClient
Procedure CheckAtClientSideAfterDecryptionInSaaSMode(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") Then
		If Not Result.Completed2 Then
			ErrorDescription = Result.ErrorInfo.LongDesc;
		Else
			ErrorDescription = "";
			DigitalSignatureInternalClientServer.BlankDecryptedData(Result.DecryptedData, ErrorDescription);
		EndIf;
		SetItem(ThisObject, "Details", True, ErrorDescription, True, MergeResults);
	EndIf;
	
	CheckAtClientSideAdditionalChecks(Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAdditionalChecks(Context)
	
	// Additional checks.
	Context.Insert("IndexOf", -1);
	
	CheckAtClientSideLoopStart(Context);
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideAfterAdditionalCheck(Var_Undefined, Context) Export
	
	ExecutionParameters = ContextExecutionParameters.Get(Context);
	ContextExecutionParameters.Delete(Context);
	
	SetItem(ThisObject, Context.ListItem.Name, False,
		ExecutionParameters.ErrorDescription,
		ExecutionParameters.IsWarning <> True,
		MergeResults);
	
	CheckAtClientSideLoopStart(Context);
	
EndProcedure

#EndRegion

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckAtClientSideLoopStart(Context)
	
	If AdditionalChecks.Count() <= Context.IndexOf + 1 Then
		RunCallback(Context.Notification);
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("ListItem", AdditionalChecks[Context.IndexOf]);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("Certificate",           Certificate);
	ExecutionParameters.Insert("Validation",             Context.ListItem.Name);
	ExecutionParameters.Insert("CryptoManager", Context.CryptoManager);
	ExecutionParameters.Insert("ErrorDescription",       "");
	ExecutionParameters.Insert("IsWarning",    False);
	ExecutionParameters.Insert("WaitForContinue",   False);
	ExecutionParameters.Insert("Password",               ?(EnterPassword, PasswordProperties.Value, Undefined));
	ExecutionParameters.Insert("ChecksResults",   ChecksAtClient);
	ExecutionParameters.Insert("Notification",           New CallbackDescription(
		"CheckAtClientSideAfterAdditionalCheck", ThisObject, Context));
	
	If TypeOf(ContextExecutionParameters) <> Type("Map") Then
		ContextExecutionParameters = New Map;
	EndIf;
	ContextExecutionParameters.Insert(Context, ExecutionParameters);
	
	Try
		DigitalSignatureClientOverridable.OnAdditionalCertificateCheck(ExecutionParameters);
	Except
		ErrorInfo = ErrorInfo();
		ExecutionParameters.WaitForContinue = False;
		ExecutionParameters.ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndTry;
	
	If ExecutionParameters.WaitForContinue <> True Then
		CheckAtClientSideAfterAdditionalCheck(Undefined, Context);
	EndIf;
	
EndProcedure

#Region ClientVerificationCloudSignature

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure VerifyOnTheClientSideAfterAuthorizationInTheCloudSignature(CallResult, Context) Export
	
	If Not CallResult.Completed2 Then
		ErrorDescription = CallResult.Error;
	EndIf;
	
	// If authentication failed, stop the checks.
	If Not IsBlankString(ErrorDescription) Then
		Return;
	EndIf;
	
	Context.Insert("UserSettings", CallResult.UserSettings);
	
	TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
	TheDSSCryptographyServiceModuleClientServer = CommonClient.CommonModule("DSSCryptographyServiceClientServer");
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Thumbprint", TheDSSCryptographyServiceModuleClientServer.TransformFingerprint(Context.CryptoCertificate.Thumbprint));
	TheDSSCryptographyServiceModuleClient.FindCertificate(New CallbackDescription(
		"CheckOnTheClientSideAfterSearchingForTheCloudSignatureCertificate", ThisObject, Context), TheStructureOfTheSearch);
	
EndProcedure
		
// Continues the CheckAtClientSide procedure.
&AtClient
Procedure CheckOnTheClientSideAfterSearchingForTheCloudSignatureCertificate(CallResult, Context) Export
	
	ErrorDescription = "";
	If Not TheOperationIsActive() Then
		ErrorDescription = NStr("vi = 'Đã đóng biểu mẫu kiểm tra.';
								|ru = 'Форма проверки закрыта.';
								|en = 'Check form is closed.'; fa = 'Check form is closed.';
								|it = 'Modulo di verifica chiuso.';
								|pl = 'Formularz weryfikacji jest zamknięty.';
								|tr = 'Kontrol formu kapalı.'");
	ElsIf Not CallResult.Completed2 Then
		ErrorDescription = CallResult.Error;
	ElsIf Not ValueIsFilled(CallResult.CertificateData) Then
		ErrorDescription = NStr("vi = 'Không tồn tại chứng chỉ trong dịch vụ (có thể là đã bị xóa).';
								|ru = 'Сертификат отсутствует в сервисе (возможно удален).';
								|en = 'The certificate does not exist in the service. It might have been deleted.'; fa = 'The certificate does not exist in the service. It might have been deleted.';
								|it = 'Certificato assente nel servizio (forse eliminato).';
								|pl = 'Brak certyfikatu w usłudze (mógł być usunięty).';
								|tr = 'Hizmette sertifika eksik (silinmiş olabilir).'");
	EndIf;
	
	If Not IsBlankString(ErrorDescription) Then
		ErrorDescription = ErrorDescription + Chars.LF
			+ NStr("vi = 'Không thể kiểm tra ký tên, chữ ký đã tạo và giải mã.';
					|ru = 'Проверка подписания, созданной подписи и расшифровки не могут быть выполнены.';
					|en = 'Cannot check signing, created signature and decryption.'; fa = 'Cannot check signing, created signature and decryption.';
					|it = 'Non è possibile eseguire la verifica della firma, della firma creata e della decrittografia.';
					|pl = 'Weryfikacja pisowni, utworzonego podpisu i deszyfracji nie mogą zostać wykonane.';
					|tr = 'İmza doğrulama, oluşturulan imza ve şifre çözme işlemi yapılamaz.'");
	EndIf;
	SetItem(ThisObject, "CertificateExists", True, ErrorDescription, , MergeResults);
	
	If Not IsBlankString(ErrorDescription) Then
		RunCallback(Context.Notification);
		Return;
	EndIf;
	
	// Checking certificate data.
	HandlerNext = New CallbackDescription(
			"VerifyOnTheClientSideAfterVerifyingTheCloudSignatureCertificate", ThisObject, Context);
	
	TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
	TheDSSCryptographyServiceModuleClient.CheckCertificate(HandlerNext, Context.UserSettings,
		CallResult.CertificateData.Certificate);
	
EndProcedure
		
// Continues the CheckAtClientSide procedure.
&AtClient
Procedure VerifyOnTheClientSideAfterVerifyingTheCloudSignatureCertificate(Result, Context) Export
	
	If Not TheOperationIsActive() Then
		ErrorDescription = NStr("vi = 'Biểu mẫu kiểm tra đã đóng.';
								|ru = 'Форма проверки закрыта.';
								|en = 'Check form is closed.'; fa = 'Check form is closed.';
								|it = 'Modulo di verifica chiuso.';
								|pl = 'Formularz weryfikacji jest zamknięty.';
								|tr = 'Kontrol formu kapalı.'");
	ElsIf Result.Completed2 And Result.Result Then
		ErrorDescription = "";
	Else
		ErrorDescription = DigitalSignatureInternalClient.ErrorTextCloudSignature("CertificateCheck",
			Result, True);
	EndIf;
	
	SetItem(ThisObject, "CertificateData", True, ErrorDescription, True, MergeResults);
	
	If Context.ValidationInServiceInsteadofValidationOnServer Then
		RunCallback(Context.Notification);
		Return;
	EndIf;
	
	// Application availability.
	If ValueIsFilled(Application) Then
		VerifyClientSideCloudSignature("CloudSignature", Context);
	Else
		ErrorDescription = NStr("vi = 'Trong chứng thư, không chỉ ra ứng dụng để sử dụng khóa đóng.';
								|ru = 'В сертификате не указано приложение для использования закрытого ключа.';
								|en = 'The certificate does not specify an application for using the private key.'; fa = 'The certificate does not specify an application for using the private key.';
								|it = 'The certificate does not specify an application for using the private key.';
								|pl = 'The certificate does not specify an application for using the private key.';
								|tr = 'Sertifikada özel anahtarı kullanabilecek bir uygulama belirtilmemiştir.'");
		CheckAtClientSideAfterCreateCryptoManager(ErrorDescription, Context);
	EndIf;
	
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Async Procedure VerifyClientSideCloudSignature(Result, Context)
	
	Context.Insert("CryptoManager", Undefined);
	
	If Not TheOperationIsActive() Then
		ErrorDescription = NStr("vi = 'Đã đóng biểu mẫu kiểm tra.';
								|ru = 'Форма проверки закрыта.';
								|en = 'Check form is closed.'; fa = 'Check form is closed.';
								|it = 'Modulo di verifica chiuso.';
								|pl = 'Formularz weryfikacji jest zamknięty.';
								|tr = 'Kontrol formu kapalı.'");
	ElsIf TypeOf(Result) = Type("String") And Result = "CloudSignature" Then
		Context.CryptoManager = Result;
		ErrorDescription = "";
	Else
		ErrorDescription = Result + Chars.LF + Chars.LF
			+ NStr("vi = 'Không thể kiểm tra ký tên, chữ ký đã tạo, mã hóa và
			             |giải mã.';
			             |ru = 'Проверка подписания, созданной подписи, шифрования и
			             |расшифровки не могут быть выполнены.';
			             |en = 'Cannot verify signing, signature, 
			             |decryption and encryption.'; fa = 'Cannot verify signing, signature, 
			             |decryption and encryption.';
			             |it = 'Non è possibile eseguire la verifica della firma, della firma creata, della crittografia e della 
			             |decrittografia.';
			             |pl = 'Weryfikacja pisowni, utworzonego podpisu i
			             |deszyfracji nie mogą zostać wykonane.';
			             |tr = 'İmza doğrulama, oluşturulan imza, şifreleme ve
			             | şifre çözme işlemi yapılamaz.'");
	EndIf;
	SetItem(ThisObject, "ProgramExists", True, ErrorDescription, True, MergeResults);
	
	If Context.CryptoManager = Undefined Then
		RunCallback(Context.Notification);
		Return;
	EndIf;
	
	ErrorDescription = Await AdditionalCheckOnthePossibilityofSigning(Context.CryptoCertificate, True);
	
	// Signing
	If ChecksAtServer.CertificateExists = True And Not ValueIsFilled(ErrorDescription) Then

		TheDSSCryptographyServiceModuleClientServer = CommonClient.CommonModule("DSSCryptographyServiceClientServer");
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		
		HandlerNext = New CallbackDescription(
				"VerifyOnTheClientSideAfterSigningCloudSignature", ThisObject, Context,
				"CheckAtClientSideAfterSigningError", ThisObject);
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Thumbprint", TheDSSCryptographyServiceModuleClientServer.TransformFingerprint(Context.CryptoCertificate.Thumbprint));
		
		PINCodeValue = ?(ValueIsFilled(PasswordProperties.Value), PasswordProperties.Value, Undefined);
		OperationParametersList = New Structure;
		OperationParametersList.Insert("Pin", TheDSSCryptographyServiceModuleClient.PreparePasswordObject(PINCodeValue));
		
		TheDSSCryptographyServiceModuleClient.Sign(
				HandlerNext,
				Context.UserSettings,
				Context.CertificateData,
				,
				TheStructureOfTheSearch,
				OperationParametersList);
				
	Else
		VerifyOnTheClientSideAfterSigningCloudSignature(Undefined, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure VerifyOnTheClientSideAfterSigningCloudSignature(CallResult, Context) Export
	
	ErrorDescription = Undefined;
	
	If Not TheOperationIsActive() Then
		ErrorDescription = NStr("vi = 'Biểu mẫu kiểm tra đã đóng.';
								|ru = 'Форма проверки закрыта.';
								|en = 'Check form is closed.'; fa = 'Check form is closed.';
								|it = 'Modulo di verifica chiuso.';
								|pl = 'Formularz weryfikacji jest zamknięty.';
								|tr = 'Kontrol formu kapalı.'");
	ElsIf CallResult <> Undefined Then
		If Not CallResult.Completed2 Then
			ErrorDescription = CallResult.Error;
		Else
			SignatureData = CallResult.Result;
			ErrorDescription = "";
			DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorDescription);
		EndIf;
		
		If Not ValueIsFilled(ErrorDescription) Then
			PasswordAccepted = True;
		EndIf;
	EndIf;
	
	SetItem(ThisObject, "Signing", True, ErrorDescription, True, MergeResults);
	
	// Check the signature.
	If CallResult <> Undefined And ChecksAtServer.CertificateExists = True And Not ValueIsFilled(ErrorDescription) Then
		HandlerNext = New CallbackDescription(
					"VerifyOnTheClientSideAfterVerifyingTheSignatureCloudSignature", ThisObject, Context,
					"CheckAtClientSideAfterCheckSignatureError", ThisObject);
		
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		TheDSSCryptographyServiceModuleClient.VerifySignature(HandlerNext, 
						Context.UserSettings, 
						SignatureData,
						Context.CertificateData,
						"CMS");
	Else
		VerifyOnTheClientSideAfterVerifyingTheSignatureCloudSignature(Undefined, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure VerifyOnTheClientSideAfterVerifyingTheSignatureCloudSignature(CallResult, Context) Export
	
	ErrorDescription = Undefined;
	
	If Not TheOperationIsActive() Then
		ErrorDescription = NStr("vi = 'Biểu mẫu kiểm tra đã đóng.';
								|ru = 'Форма проверки закрыта.';
								|en = 'Check form is closed.'; fa = 'Check form is closed.';
								|it = 'Modulo di verifica chiuso.';
								|pl = 'Formularz weryfikacji jest zamknięty.';
								|tr = 'Kontrol formu kapalı.'");
	ElsIf CallResult <> Undefined Then
		If Not CallResult.Completed2 Then
			ErrorDescription = DigitalSignatureInternalClient.ErrorTextCloudSignature(
				"CheckSignature", CallResult, True);
		Else
			ErrorDescription = "";
		EndIf;
		SetItem(ThisObject, "CheckSignature", True, ErrorDescription, True, MergeResults);
	EndIf;
	
	If Not ValueIsFilled(ErrorDescription) Then
		HandlerNext = New CallbackDescription(
				"VerifyOnTheClientSideAfterEncryptionCloudSignature", ThisObject, Context,
				"CheckAtClientSideAfterEncryptionError", ThisObject);
		
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		TheDSSCryptographyServiceModuleClient.Encrypt(HandlerNext,
				Context.UserSettings,
				Context.CertificateData,
				Context.CertificateData);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure VerifyOnTheClientSideAfterEncryptionCloudSignature(CallResult, Context) Export
	
	ErrorDescription = Undefined;
	If Not TheOperationIsActive() Then
		ErrorDescription = NStr("vi = 'Biểu mẫu kiểm tra đã đóng.';
								|ru = 'Форма проверки закрыта.';
								|en = 'Check form is closed.'; fa = 'Check form is closed.';
								|it = 'Modulo di verifica chiuso.';
								|pl = 'Formularz weryfikacji jest zamknięty.';
								|tr = 'Kontrol formu kapalı.'");
	ElsIf CallResult <> Undefined Then
		If Not CallResult.Completed2 Then
			ErrorDescription = CallResult.Error;
		Else
			ErrorDescription = "";
		EndIf;
	EndIf;
	SetItem(ThisObject, "Encryption", True, ErrorDescription, True, MergeResults);
	
	// Decryption.
	If ChecksAtServer.CertificateExists = True And Not ValueIsFilled(ErrorDescription) Then
		HandlerNext = New CallbackDescription(
				"VerifyOnTheClientSideAfterDecryptingTheCloudSignature", ThisObject, Context,
				"CheckAtClientSideAfterDecryptionError", ThisObject);
		
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		TheDSSCryptographyServiceModuleClientServer = CommonClient.CommonModule("DSSCryptographyServiceClientServer");
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Thumbprint", TheDSSCryptographyServiceModuleClientServer.TransformFingerprint(Context.CryptoCertificate.Thumbprint));
		
		PINCodeValue = ?(ValueIsFilled(PasswordProperties.Value), PasswordProperties.Value, Undefined);
		OperationParametersList = New Structure;
		OperationParametersList.Insert("Pin", TheDSSCryptographyServiceModuleClient.PreparePasswordObject(PINCodeValue));
		
		TheDSSCryptographyServiceModuleClient.Decrypt(HandlerNext, Context.UserSettings, CallResult.Result, , TheStructureOfTheSearch, OperationParametersList);
	Else
		VerifyOnTheClientSideAfterDecryptingTheCloudSignature(Undefined, Context);
	EndIf;
	
EndProcedure

// Continues the CheckAtClientSide procedure.
&AtClient
Procedure VerifyOnTheClientSideAfterDecryptingTheCloudSignature(CallResult, Context) Export
	
	ErrorDescription = Undefined;
	If Not TheOperationIsActive() Then
		ErrorDescription = NStr("vi = 'Biểu mẫu kiểm tra đã đóng.';
								|ru = 'Форма проверки закрыта.';
								|en = 'Check form is closed.'; fa = 'Check form is closed.';
								|it = 'Modulo di verifica chiuso.';
								|pl = 'Formularz weryfikacji jest zamknięty.';
								|tr = 'Kontrol formu kapalı.'");
	ElsIf CallResult <> Undefined Then
		If Not CallResult.Completed2 Then
			ErrorDescription = CallResult.Error;
		Else
			ErrorDescription = "";
			DigitalSignatureInternalClientServer.BlankDecryptedData(CallResult.Result, ErrorDescription);
		EndIf;
		SetItem(ThisObject, "Details", True, ErrorDescription, True, MergeResults);
	EndIf;
	
	CheckAtClientSideAdditionalChecks(Context);
	
EndProcedure

&AtClient
Function TheOperationIsActive()
	
	Result = IsOpen();
	Return Result;
	
EndFunction	

#EndRegion

#Region CheckAtServer

&AtServer
Procedure CheckAtServerSide(Val PasswordValue)
	
	CheckCompleted = True;
	
	ServerName = ComputerName();
	
	CertificateData = GetFromTempStorage(CertificateAddress);
	
	Try
		CryptoCertificate = New CryptoCertificate(CertificateData);
	Except
		SetItem(ThisObject, FirstCheckName, True,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()), True, MergeResults);
		Return;
	EndTry;
	
	// Verified certificate.
	CheckLegalCertificateAtServer(CryptoCertificate);
	
	// Availability of a certificate in the personal list.
	Result = New Structure;
	DigitalSignatureInternal.GetCertificateByThumbprint(
		Base64String(CryptoCertificate.Thumbprint), True, False, , Result);
	
	ErrorDescription = "";
	If ValueIsFilled(Result) Then
		ErrorDescription = Result.ErrorDescription + Chars.LF + Chars.LF
			+ NStr("vi = 'Không thể kiểm tra ký tên, chữ ký đã tạo và giải mã.';
					|ru = 'Проверка подписания, созданной подписи и расшифровки не могут быть выполнены.';
					|en = 'Cannot check signing, created signature and decryption.'; fa = 'Cannot check signing, created signature and decryption.';
					|it = 'Non è possibile eseguire la verifica della firma, della firma creata e della decrittografia.';
					|pl = 'Weryfikacja pisowni, utworzonego podpisu i deszyfracji nie mogą zostać wykonane.';
					|tr = 'İmza doğrulama, oluşturulan imza ve şifre çözme işlemi yapılamaz.'");
	EndIf;
	SetItem(ThisObject, "CertificateExists", True, ErrorDescription, , MergeResults);
	
	// Check certificate data.
	CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
	If DigitalSignatureInternalClientServer.AreCertificateAdditionalPropertiesAvailable() Then
		CreationParameters.SignAlgorithm = DigitalSignatureInternalClientServer.SignAlgorithmPresentation(
			CryptoCertificate.PublicKeyAlgorithm, True, False);
	Else
		CreationParameters.SignAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(CertificateData);
	EndIf;
	
	CryptoManager = DigitalSignatureInternal.CryptoManager(
		"CertificateCheck", CreationParameters);
	
	ErrorDescription = CreationParameters.ErrorDescription;
	If Not ValueIsFilled(ErrorDescription) Then
		AdditionalCertificateVerificationParameters = 
			DigitalSignatureInternal.AdditionalCertificateVerificationParameters();
		AdditionalCertificateVerificationParameters.PerformCAVerification = False;
		DigitalSignatureInternal.CheckCertificate(CryptoManager, CryptoCertificate, ErrorDescription,,AdditionalCertificateVerificationParameters);
	EndIf;
	
	SetItem(ThisObject, "CertificateData", True, ErrorDescription, True, MergeResults);
	
	// App availability.
	If ValueIsFilled(Application) Then
		CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
		CreationParameters.Application = Application;
		
		CryptoManager = DigitalSignatureInternal.CryptoManager("CertificateCheck", CreationParameters);
		ErrorDescription = CreationParameters.ErrorDescription;
	Else
		
		AppAutoAtServerResult = DigitalSignatureInternal.AppForCertificate(CertificateAddress);
		AppAutoAtServer = AppAutoAtServerResult.Application;
		
		If AppAutoAtServerResult.Application = Undefined Then
			ErrorDescription = DigitalSignatureInternalClientServer.ErrorTextFailedToDefineApp(
				AppAutoAtServerResult.Error);
			CryptoManager = Undefined;
		Else
			CreationParameters = DigitalSignatureInternal.CryptoManagerCreationParameters();
			CreationParameters.Application = AppAutoAtServer;
			CryptoManager = DigitalSignatureInternal.CryptoManager("CertificateCheck", CreationParameters);
			ErrorDescription = CreationParameters.ErrorDescription;
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(ErrorDescription) Then
		
		ErrorDescription = ErrorDescription + Chars.LF + Chars.LF
			+ NStr("vi = 'Không thể kiểm tra ký tên,
			|chữ ký đã tạo, mã hóa và giải mã.';
			|ru = 'Проверка подписания, созданной подписи, шифрования и
			|расшифровки не могут быть выполнены.';
			|en = 'Cannot verify signing, signature, 
			|decryption and encryption. '; fa = 'Cannot verify signing, signature, 
			|decryption and encryption. ';
			|it = 'Non è possibile eseguire la verifica della firma, della firma creata, della crittografia e della 
			|decrittografia.';
			|pl = 'Weryfikacja pisowni, utworzonego podpisu i
			|deszyfracji nie mogą zostać wykonane.';
			|tr = 'İmza doğrulama, oluşturulan imza, şifreleme ve
			| şifre çözme işlemi yapılamaz.'");
		
	EndIf;
	SetItem(ThisObject, "ProgramExists", True, ErrorDescription, True, MergeResults);
	
	If CryptoManager = Undefined Then
		Return;
	EndIf;
	
	CryptoManager.PrivateKeyAccessPassword = PasswordValue;
	
	ErrorDescription = "";
	
	If Revoked Then
		ErrorDescription = DigitalSignatureInternal.ErrorCertificateMarkedAsRevoked();
		SetItem(ThisObject, "Signing", True, ErrorDescription, True, MergeResults);
	Else
		If PerformCAVerification <> DigitalSignatureInternalClientServer.NotVerifyCertificate() Then
			CheckParameters = New Structure;
			CheckParameters.Insert("ThisVerificationSignature", False);
			CheckParameters.Insert("VerifyCertificate", PerformCAVerification);
			
			ResultCheckCA = DigitalSignatureInternal.ResultofCertificateAuthorityVerification(
				CryptoCertificate,, CheckParameters);
			If Not ResultCheckCA.Valid Then
				
				If  PerformCAVerification = DigitalSignatureInternalClientServer.QualifiedOnly() Then
					SigningAllowed = False;
				Else
					SigningAllowed = Common.CommonSettingsStorageLoad(
						Certificate, "AllowSigning", Undefined);
				EndIf;
				
				If SigningAllowed = Undefined Or Not SigningAllowed Then
					ErrorDescription = ResultCheckCA.Warning.ErrorText;
					SetItem(ThisObject, "Signing", True, ResultCheckCA.Warning, True,
						MergeResults);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	If ChecksAtServer.CertificateExists = True And Not ValueIsFilled(ErrorDescription) Then
		SignatureData = CheckSigningArServer(CryptoManager, CertificateData, CryptoCertificate, ErrorDescription);
	EndIf;
	
	If ChecksAtServer.CertificateExists = True And Not ValueIsFilled(ErrorDescription) Then
		CheckSignatureAtServer(CryptoManager, CertificateData, SignatureData);
	EndIf;
	
	ErrorDescription = "";
	EncryptedData = CheckEncryptionAtServer(CryptoManager, CertificateData, CryptoCertificate, ErrorDescription); 
	
	If ChecksAtServer.CertificateExists = True And Not ValueIsFilled(ErrorDescription) Then
		CheckDecryptionAtServer(CryptoManager, EncryptedData);
	EndIf;
	
	CheckAtServerSideAdditionalChecks(PasswordValue, CryptoManager);
	
EndProcedure

&AtServer
Procedure CheckLegalCertificateAtServer(CryptoCertificate)
	
	ErrorDescription = "";
	If Items.LegalCertificateGroup.Visible
		And Not CryptoCertificate.Subject.Property("SN") Then
		
		ErrorDescription = NStr("vi = 'Không tìm thấy trường ""SN"" trong mô tả chủ thể của chứng chỉ.';
								|ru = 'В описании субъекта сертификата не найдено поле ""SN"".';
								|en = 'The ""SN"" field is not found in the certificate subject description.'; fa = 'The ""SN"" field is not found in the certificate subject description.';
								|it = 'Nella descrizione del soggetto del certificato non è stato trovato il campo ""SN"".';
								|pl = 'W opisie podmiotu certyfikatu nie znaleziono pola ""SN"".';
								|tr = 'Sertifika nesne açıklamasında ""SN"" alanı bulunamadı.'");
	EndIf;
	SetItem(ThisObject, "LegalCertificate", True, ErrorDescription, , MergeResults);

EndProcedure

&AtServer
Function CheckSigningArServer(CryptoManager, CertificateData, CryptoCertificate, ErrorDescription)
	
	Try
		SignatureData = CryptoManager.Sign(CertificateData, CryptoCertificate);
		DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorDescription);
	Except
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	
	PasswordAccepted = Not ValueIsFilled(ErrorDescription);
	
	If ValueIsFilled(ErrorDescription) Then
		SetItem(ThisObject, "Signing", True, ErrorDescription, True, MergeResults);
		Return SignatureData;
	EndIf;
	
	If ValueIsFilled(SignatureType) And SignatureType <> PredefinedValue(
		"Enum.CryptographySignatureTypes.BasicCAdESBES") And SignatureType <> PredefinedValue(
		"Enum.CryptographySignatureTypes.NormalCMS") Then
		
		Try
			SettingsSignatures = DigitalSignatureInternalClientServer.SignatureCreationSettings(SignatureType,
				DigitalSignature.CommonSettings().TimestampServersAddresses);
			CryptoManager.TimestampServersAddresses = SettingsSignatures.TimestampServersAddresses;
			SignatureData = CryptoManager.Sign(CertificateData, CryptoCertificate,
				SettingsSignatures.SignatureType);
			DigitalSignatureInternalClientServer.BlankSignatureData(SignatureData, ErrorDescription);
		Except
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		
	EndIf;
	
	SetItem(ThisObject, "Signing", True, ErrorDescription, True, MergeResults);
	Return SignatureData;
	
EndFunction

&AtServer
Procedure CheckSignatureAtServer(CryptoManager, CertificateData, SignatureData)
		
	ErrorDescription = "";
	Try
		CryptoManager.VerifySignature(CertificateData, SignatureData);
	Except
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	
	If Not ValueIsFilled(ErrorDescription) And ValueIsFilled(SignatureType) And SignatureType <> PredefinedValue(
		"Enum.CryptographySignatureTypes.BasicCAdESBES") And SignatureType <> PredefinedValue(
		"Enum.CryptographySignatureTypes.NormalCMS") Then
		
		Try
			SignatureProperties = DigitalSignatureInternal.SignaturePropertiesReadByCryptoManager(
				SignatureData, CryptoManager, True);
		Except
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
			
		If Not ValueIsFilled(ErrorDescription) And ValueIsFilled(SignatureProperties.ErrorText) Then
			ErrorDescription = SignatureProperties.ErrorText;
		ElsIf Not ValueIsFilled(ErrorDescription) Then
			TimestampCertificateData = SignatureProperties.Certificates[SignatureProperties.Certificates.UBound()];
			TimestampCertificate = New CryptoCertificate(TimestampCertificateData);
			CertificateProperties = DigitalSignatureInternalClientServer.CertificateProperties(
				TimestampCertificate, DigitalSignatureInternal.UTCOffset());
			
			Found4 = TimestampCertificates.FindRows(New Structure("Thumbprint", CertificateProperties.Thumbprint));
				
			If Found4.Count() = 0 Then
					NewRow = TimestampCertificates.Add();
					NewRow.CertificateAddress = PutToTempStorage(TimestampCertificateData,
						UUID);
					NewRow.Thumbprint = CertificateProperties.Thumbprint;
					NewRow.IsObtainedAtServer = True;
				
			Else
				Found4[0].IsObtainedAtServer = True;
			EndIf;
		
		EndIf;
	EndIf;
	
	SetItem(ThisObject, "CheckSignature", True, ErrorDescription, True, MergeResults);
	
EndProcedure

&AtServer
Function CheckEncryptionAtServer(CryptoManager, CertificateData, CryptoCertificate, ErrorDescription)
	
	Try
		EncryptedData = CryptoManager.Encrypt(CertificateData, CryptoCertificate);
		DigitalSignatureInternalClientServer.BlankEncryptedData(EncryptedData, ErrorDescription);
	Except
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	SetItem(ThisObject, "Encryption", True, ErrorDescription, True, MergeResults);
	
	Return EncryptedData;
	
EndFunction

&AtServer
Procedure CheckDecryptionAtServer(CryptoManager, EncryptedData)
	
	ErrorDescription = "";
	Try
		DecryptedData = CryptoManager.Decrypt(EncryptedData);
		DigitalSignatureInternalClientServer.BlankDecryptedData(DecryptedData, ErrorDescription);
	Except
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	SetItem(ThisObject, "Details", True, ErrorDescription, True, MergeResults);
	
EndProcedure

&AtServer
Procedure CheckAtServerSideAdditionalChecks(PasswordValue, CryptoManager = Undefined)
	
	ServerName = ComputerName();
	
	// Additional checks.
	For Each ListItem In AdditionalChecks Do
		
		ErrorDescription = "";
		IsWarning = False;
		Try
			ExecutionParameters = New Structure;
			ExecutionParameters.Insert("Certificate",           Certificate);
			ExecutionParameters.Insert("Validation",             ListItem.Name);
			ExecutionParameters.Insert("CryptoManager", CryptoManager);
			ExecutionParameters.Insert("ErrorDescription",       ErrorDescription);
			ExecutionParameters.Insert("IsWarning",    IsWarning);
			ExecutionParameters.Insert("Password",               ?(EnterPassword, PasswordValue, Undefined));
			ExecutionParameters.Insert("ChecksResults",   ChecksAtServer);
			
			DigitalSignatureOverridable.OnAdditionalCertificateCheck(ExecutionParameters);
			
			ErrorDescription    = ExecutionParameters.ErrorDescription;
			IsWarning = ExecutionParameters.IsWarning;
		Except
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		
		SetItem(ThisObject, ListItem.Name, True,
			ErrorDescription, IsWarning <> True, MergeResults);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure AddPicture(TagName, Parent, Picture = Undefined)
	
	Decoration = Items.Add(TagName, Type("FormDecoration"), Parent);
	Decoration.Type = FormDecorationType.Picture;
	Decoration.Width = 2;
	Decoration.Height = 1;
	Decoration.Picture = ?(Picture = Undefined, New Picture, Picture);
	Decoration.PictureSize = PictureSize.AutoSize;
	
EndProcedure

&AtServer
Procedure AddItemsDescriptionsErrors(CheckName, Parent, AtServer = False)
	
	ErrorGroupClient = FormGroupWithoutDisplay(
			CheckName + ?(AtServer, "ErrorServer", "ErrorClient"), Parent,
			ChildFormItemsGroup.AlwaysHorizontal);
	ErrorGroupClient.Visible = False;
		
	AddPicture(CheckName + ?(AtServer, "ErrorServerImage", "ErrorClientPicture"),
		ErrorGroupClient, PictureLib[?(AtServer, "ComputerServer", "ComputerClient")]);
	Label = Items.Add(CheckName + ?(AtServer, "ErrorServerLabel", "ErrorClientLabel"),
		Type("FormDecoration"), ErrorGroupClient);
	Label.TextColor = StyleColors.NoteText;
	Label = Items.Add(CheckName + ?(AtServer, "DecisionServerLabel", "DecisionClientLabel"),
		Type("FormDecoration"), Parent);
	Label.TextColor = StyleColors.NoteText;
	Label.SetAction("URLProcessing", "Attachable_NavigationLinkProcessingLabel");
	
EndProcedure

&AtServer
Function FormGroupWithoutDisplay(GroupName, Parent, Grouping = Undefined)
	
	Var_Group = Items.Add(GroupName, Type("FormGroup"), Parent);
	Var_Group.Type = FormGroupType.UsualGroup;
	Var_Group.Representation = UsualGroupRepresentation.None;
	Var_Group.ShowTitle = False;
	
	Var_Group.Group = ?(Grouping = Undefined,
		ChildFormItemsGroup.AlwaysHorizontal, Grouping);
		
	Return Var_Group;
	
EndFunction

&AtServer
Procedure RefreshVisibilityAtServer()
	
	OperationsAtServer = (DigitalSignature.VerifyDigitalSignaturesOnTheServer()
		Or DigitalSignature.GenerateDigitalSignaturesAtServer());
		
	VerifyDigitalSignaturesOnTheServer = Constants.VerifyDigitalSignaturesOnTheServer.Get();
		
	CheckInService = (IsBuiltInCryptoProvider Or ThisServiceAccount 
		Or VerifyDigitalSignaturesOnTheServer And (HaveServiceAccount Or HasBuiltinCryptoprovider));
		
	VisibilityCheckOnServer = OperationsAtServer Or CheckInService;
	VisibilityColumnsOnServer = VisibilityCheckOnServer And MergeResults <> "MergeByAnd" And MergeResults <> "MergeByOr";
	
	Items.HeaderGroup.Visible = VisibilityCheckOnServer;
	
	For Each Validation In StandardChecks() Do
		Items[Validation + "ErrorClientPicture"].Visible = VisibilityCheckOnServer;
		Items[Validation + "AtServerPicture"].Visible = VisibilityColumnsOnServer;
	EndDo;
	
	For Each Validation In AdditionalChecks Do
		Items[Validation.Name + "ErrorClientPicture"].Visible = VisibilityCheckOnServer;
		Items[Validation.Name + "AtServerPicture"].Visible = VisibilityColumnsOnServer;
	EndDo;
	
	Items.ChecksOnServerPicture.Visible = VisibilityColumnsOnServer;
	Items.ChecksOnClientPicture.Visible = VisibilityColumnsOnServer;
	
EndProcedure

&AtServer
Procedure OutputCheckResult(Validation, AtServer = False)
	
	ChecksResults = ThisObject[?(AtServer, "ChecksAtServer", "ChecksAtClient")];
	Additional_DataChecks = ThisObject[?(AtServer, "AdditionalDataChecksOnServer", "AdditionalDataChecksOnClient")];
	
	If ChecksResults = Undefined Then
		Return;
	EndIf;
		
	CheckResult = ChecksResults[Validation];
	If CheckResult = Undefined Then
		SetItem(ThisObject, Validation, AtServer, , , MergeResults);
		Return;
	EndIf;
		
	ErrorsOnCheck = ?(ChecksResults.Property(Validation + "Error"),
		ChecksResults[Validation + "Error"], "");
		
	If Additional_DataChecks.Property(Validation) Then
		Structure = Additional_DataChecks[Validation];
		Structure.Insert("ErrorText", ErrorsOnCheck);
		SetItem(ThisObject, Validation, AtServer,
			Structure, Not CheckResult, MergeResults);
	Else
		SetItem(ThisObject, Validation, AtServer,
			ErrorsOnCheck, Not CheckResult, MergeResults);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetItem(Form, Action, AtServer,
	ErrorDescription = Undefined, IsError = False, MergeResults = "DontMerge")
	
	LabelItemName = Action + "Label";
	AtClientPictureItemName = Action + "AtClientPicture";
	AtServerPictureItemName = Action + "AtServerPicture"; 
	ErrorPropertyName = Action + "Error";
	
	ItemLabel = Form.Items[LabelItemName]; // FormDecoration, FormDecorationExtensionForALabel
	ShouldMergeResults = (MergeResults = "MergeByAnd" Or MergeResults = "MergeByOr");  
	If ShouldMergeResults Then
		ItemPicture1 = Form.Items[AtClientPictureItemName]; // FormDecoration
	Else
		ItemPicture1 = Form.Items[?(AtServer, AtServerPictureItemName, AtClientPictureItemName)]; // FormDecoration
	EndIf;
	
	Checks = Form[?(AtServer, "ChecksAtServer", "ChecksAtClient")];
	SecondContextChecks = Form[?(AtServer, "ChecksAtClient", "ChecksAtServer")];
	
	SecondContextCheckValue = Undefined;
	If TypeOf(SecondContextChecks) = Type("Structure") And SecondContextChecks.Property(Action) Then
		SecondContextCheckValue = SecondContextChecks[Action];
	EndIf;
	
	KnownErrorWithoutClassifier = Undefined;
	If TypeOf(ErrorDescription) = Type("Structure") Then
		KnownErrorWithoutClassifier = ErrorDescription;
		ErrorDescription = KnownErrorWithoutClassifier.ErrorText;
	EndIf;
	
	If ValueIsFilled(ErrorDescription) Then
		CheckValue = False;
		CheckResult = CheckValue;
		If MergeResults = "MergeByOr" And SecondContextCheckValue <> Undefined Then
			CheckResult = False Or SecondContextCheckValue;
		EndIf;
	Else
		CheckValue = ?(ErrorDescription = Undefined, Undefined, True);
		If CheckValue <> Undefined And SecondContextCheckValue <> Undefined 
			And ShouldMergeResults Then
			CheckResult = ?(MergeResults = "MergeByAnd",
				CheckValue And SecondContextCheckValue,
				CheckValue Or SecondContextCheckValue);
		EndIf;
	EndIf;
	Checks.Insert(Action, CheckValue);
	
	GroupNameByCheckName = GroupsNamesByCheckNames(Form.Items)[Action];
	If GroupNameByCheckName = Undefined Then
		GroupNameByCheckName = "Group" + Action;
	EndIf;
	Form.Items[GroupNameByCheckName].Visible = 
		CheckValue = False Or SecondContextCheckValue = False;

	Checks.Insert(ErrorPropertyName, ?(ErrorDescription = Undefined, "", ErrorDescription));
		
	ErrorGroupNameServer = Action + "ErrorServer"; 
	ErrorGroupNameClient = Action + "ErrorClient"; 
	ErrorLabelItemNameServer = Action + "ErrorServerLabel"; 
	ErrorLabelItemNameClient = Action + "ErrorClientLabel"; 
	SolutionLabelItemNameServer = Action + "DecisionServerLabel"; 
	SolutionLabelItemNameClient = Action + "DecisionClientLabel"; 

	If ValueIsFilled(ErrorDescription) Then
		
		If CheckResult Then
			Return;
		EndIf;
		
		Form.AreChecksPassed = False;
		
		ErrorGroup = Form.Items[?(AtServer, ErrorGroupNameServer, ErrorGroupNameClient)];
		ErrorGroup.Visible = True;
		ItemPicture1.Picture = ?(IsError,
			PictureLib.Warning,
			PictureLib.CertificateCheckWarning);
		
		ItemPicture1.ToolTip = ErrorDescription;
		ItemLabel.Hyperlink = True;
		
		ElementLabelError = Form.Items[?(AtServer, ErrorLabelItemNameServer, ErrorLabelItemNameClient)]; // FormDecoration, FormDecorationExtensionForALabel
		ElementLabelError.Title = ErrorDescription;
		
		LabelNameSolution = ?(AtServer, SolutionLabelItemNameServer, SolutionLabelItemNameClient);
		SolutionLabelFormItem = Form.Items[LabelNameSolution];
			
		LabelErrorSigningItemName = "Signing" + ?(AtServer, "ErrorServerLabel", "ErrorClientLabel"); 
		LabelErrorSigningFormItem = Form.Items[LabelErrorSigningItemName]; 

		KnownErrorDescription = ClassifierError(ErrorDescription, AtServer, Action = "CheckSignature", ValueIsFilled(Form.Certificate));
		IsKnownError = KnownErrorDescription <> Undefined;
	
		Form.Items[LabelNameSolution].Visible = IsKnownError;
		If Not IsKnownError Then
			
			If KnownErrorWithoutClassifier = Undefined Then
				ElementLabelError.Title = GenerateHeaderInDetail(ErrorDescription);
				Return;
			Else
				SolutionLabelFormItem.Visible = True;
				FormAttributeName = ?(AtServer, "AdditionalDataChecksOnServer", "AdditionalDataChecksOnClient");
				Additional_DataChecks = Form[FormAttributeName];
				Additional_DataChecks.Insert(Action,
					New Structure("Cause, Decision", KnownErrorWithoutClassifier.Cause, KnownErrorWithoutClassifier.Decision));
				Form[FormAttributeName] = Additional_DataChecks;
				KnownErrorDescription = New Structure;
				KnownErrorDescription.Insert("Cause", KnownErrorWithoutClassifier.Cause);
				KnownErrorDescription.Insert("Decision", KnownErrorWithoutClassifier.Decision);
				KnownErrorDescription.Insert("RemedyActions");
			EndIf;
			
		EndIf;
		
		If ValueIsFilled(KnownErrorDescription.Cause) Then
			ElementLabelError.Title = KnownErrorDescription.Cause;
		EndIf;
		
		If Action = "Details"
			And LabelErrorSigningFormItem.Visible = True
			And ElementLabelError.Title = LabelErrorSigningFormItem.Title Then
			
			SolutionLabelFormItem.Visible = False;
			ElementLabelError.Visible = True;
			ElementLabelError.Title = NStr("vi = 'Xem mục Ký dữ liệu.';
											|ru = 'См. пункт Подписание данных.';
											|en = 'See the ""Data signing"" item.'; fa = 'See the ""Data signing"" item.';
											|it = 'См. пункт Подписание данных.';
											|pl = 'See the ""Data signing"" item.';
											|tr = 'Veri İmzalama maddesine bakınız'");
			Return;
		EndIf;
		
		If ValueIsFilled(Form.Certificate) And ValueIsFilled(KnownErrorDescription.RemedyActions) Then
			
			DataToSupplement = DigitalSignatureInternalClientServer.DataToSupplementErrorFromClassifier(
				New Structure("Certificate, CertificateData", Form.Certificate, Form.CertificateAddress));
			
			KnownErrorDescription = DigitalSignatureInternalServerCall.SupplementErrorClassifierSolutionWithDetails(
				KnownErrorDescription, DataToSupplement, ?(AtServer, "Server", "Client"));
			
		EndIf;
		Form.Items[LabelNameSolution].Title = KnownErrorDescription.Decision;
		Return;
		
	EndIf;
	
	ErrorGroup = Form.Items[?(AtServer, ErrorGroupNameServer, ErrorGroupNameClient)];
	ItemDecision = Form.Items[?(AtServer, SolutionLabelItemNameServer, SolutionLabelItemNameClient)];
	
	If ShouldMergeResults Then
		
		If CheckValue = Undefined And SecondContextCheckValue = Undefined Then
			ErrorGroup.Visible = False;
			ItemDecision.Visible = False;
			ItemPicture1.Picture = PictureLib.NoCertificateCheckPerformed;
			ItemPicture1.ToolTip = NStr("vi = 'Không kiểm tra.';
										|ru = 'Проверка не выполнялась.';
										|en = 'No check was performed.'; fa = 'هیچ بررسی‌ای انجام نشد.';
										|it = 'Verifica non effettuata.';
										|pl = 'Weryfikacja nie była wykonywana.';
										|tr = 'Denetim yapılmadı.'");
			ItemLabel.Hyperlink = False;
			ItemLabel.Title = ItemTitle(Form.AdditionalChecks, ItemLabel.Name, Form.SignatureType);
		ElsIf CheckValue <> Undefined And SecondContextCheckValue = Undefined Then
			ErrorGroup.Visible = False;
			ItemDecision.Visible = False;
			ItemPicture1.Picture = PictureLib.CertificateCheckSuccess;
			ItemPicture1.ToolTip = NStr("vi = 'Đã kiểm tra thành công.';
										|ru = 'Проверка выполнена успешно.';
										|en = 'Check succeeded.'; fa = 'Check succeeded.';
										|it = 'La verifica è stata effettuata con successo.';
										|pl = 'Weryfikacja została wykonana pomyślnie.';
										|tr = 'Kontrol başarıyla tamamlandı.'");
			ItemLabel.Hyperlink = False;
			ItemLabel.Title = ItemTitle(Form.AdditionalChecks, ItemLabel.Name, Form.SignatureType);
		ElsIf CheckValue <> Undefined And CheckResult Then
			ErrorGroup.Visible = False;
			ItemDecision.Visible = False;
			ItemPicture1.Picture = PictureLib.CertificateCheckSuccess;
			ItemPicture1.ToolTip = NStr("vi = 'Đã kiểm tra thành công.';
										|ru = 'Проверка выполнена успешно.';
										|en = 'Check succeeded.'; fa = 'Check succeeded.';
										|it = 'La verifica è stata effettuata con successo.';
										|pl = 'Weryfikacja została wykonana pomyślnie.';
										|tr = 'Kontrol başarıyla tamamlandı.'");
			ItemLabel.Hyperlink = False;
			ItemLabel.Title = ItemTitle(Form.AdditionalChecks, ItemLabel.Name, Form.SignatureType);
		EndIf;
		
		Return;
	EndIf;

	ItemPicture1.Picture = ?(ErrorDescription = Undefined,
		PictureLib.NoCertificateCheckPerformed,
		PictureLib.CertificateCheckSuccess);
	ItemPicture1.ToolTip = ?(ErrorDescription = Undefined,
		NStr("vi = 'Không kiểm tra.';
			|ru = 'Проверка не выполнялась.';
			|en = 'No check was performed.'; fa = 'هیچ بررسی‌ای انجام نشد.';
			|it = 'Verifica non effettuata.';
			|pl = 'Weryfikacja nie była wykonywana.';
			|tr = 'Denetim yapılmadı.'"),
		NStr("vi = 'Đã kiểm tra thành công.';
			|ru = 'Проверка выполнена успешно.';
			|en = 'Check succeeded.'; fa = 'Check succeeded.';
			|it = 'La verifica è stata effettuata con successo.';
			|pl = 'Weryfikacja została wykonana pomyślnie.';
			|tr = 'Kontrol başarıyla tamamlandı.'"));
	
	If SecondContextChecks = Undefined
		Or Not SecondContextChecks.Property(Action + "Error")
		Or IsBlankString(SecondContextChecks[Action + "Error"]) Then
		
		ErrorGroup.Visible = False;
		ItemDecision.Visible = False;
		ItemLabel.Hyperlink = False;
		ItemLabel.Title = ItemTitle(Form.AdditionalChecks, ItemLabel.Name, Form.SignatureType); 
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function GenerateHeaderInDetail(ErrorDescription)
	
	URL = "";
	DigitalSignatureClientServerLocalization.OnDefineRefToSearchByErrorsWhenManagingDigitalSignature(
		URL, ErrorDescription);
	If IsBlankString(URL) Then
		Return ErrorDescription;
	EndIf;

	Array = New Array;
	Array.Add(ErrorDescription);
	Array.Add(" ");

	String = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '<a href = %1>Tìm kiếm giải pháp...</a>';
			|ru = '<a href = %1>Поиск решения...</a>';
			|en = '<a href = %1>Finding solution…</a>'; fa = '<a href = %1>Finding solution…</a>';
			|it = '<a href = %1>Поиск решения...</a>';
			|pl = '<a href = %1>Finding solution…</a>';
			|tr = '<a href = %1> Çözüm bulma..</a>'"), URL);

#If Server Then
	Array.Add(StringFunctions.FormattedString(String));
#Else
	Array.Add(StringFunctionsClient.FormattedString(String));
#EndIf
	Return New FormattedString(Array);
	
EndFunction

&AtClientAtServerNoContext
Function ItemTitle(AdditionalChecks, TagName, SignatureType)
	
	ItemTitle = StandardItemTitle(TagName, SignatureType);
	If Not IsBlankString(ItemTitle) Then
		Return ItemTitle;
	EndIf;
		
	For Each Validation In AdditionalChecks Do
		If Validation.Name + "Label" = TagName Then
			Return Validation.Presentation;
		EndIf;
	EndDo;
	Return "";
	
EndFunction

&AtClientAtServerNoContext
Function StandardItemTitle(TagName, SignatureType)
	
	If TagName = "LegalCertificateLabel" Then
		Return NStr("vi = 'Theo quy định của Luật pháp';
					|ru = 'Соответствие законодательству Российской Федерации';
					|en = 'Compliance with legislation of the Russian Federation'; fa = 'انطباق با قوانین فدراسیون روسیه';
					|it = 'Conformità con la legislazione della Federazione Russa';
					|pl = 'Zgodność z ustawodawstwem Federacji Rosyjskiej';
					|tr = 'Rusya Federasyonu kanunlarına uygunluk'");
		
	ElsIf TagName = "CertificateExistsLabel" Then
		Return NStr("vi = 'Có chứng chỉ trong danh sách riêng';
					|ru = 'Наличие сертификата в личном списке';
					|en = 'Certificate is available in the Personal list'; fa = 'گواهی در فهرست شخصی در دسترس است';
					|it = 'Disponibilità del certificato nell''elenco privato';
					|pl = 'Istnienie certyfikatu w liście prywatnej';
					|tr = 'Kişisel listede sertifikanın bulunması'");
		
	ElsIf TagName = "CertificateDataLabel" Then
		Return NStr("vi = 'Tính xác thực của dữ liệu chứng chỉ';
					|ru = 'Корректность данных сертификата';
					|en = 'Certificate data accuracy'; fa = 'Certificate data accuracy';
					|it = 'Correttezza dei dati del certificato';
					|pl = 'Poprawność danych certyfikatu';
					|tr = 'Sertifika verilerinin doğruluğu'");
		
	ElsIf TagName = "ProgramExistsLabel" Then
		Return NStr("vi = 'Sẵn có ứng dụng để ký và diễn giải';
					|ru = 'Наличие приложения для подписания и расшифровки';
					|en = 'Existence of a signing and decryption app'; fa = 'Existence of a signing and decryption app';
					|it = 'Наличие приложения для подписания и расшифровки';
					|pl = 'Existence of a signing and decryption app';
					|tr = 'İmzalama ve şifre çözme için bir uygulamanın olması'");
		
	ElsIf TagName = "SigningLabel" Then
		
		If ValueIsFilled(SignatureType) Then
			
			SignatureTypeString = String(SignatureType);
			SignatureTypeString = Lower(Left(SignatureTypeString, 1)) + Mid(SignatureTypeString, 2);
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Ký dữ liệu bởi kiểu chữ ký - %1';
					|ru = 'Подписание данных типом подписи - %1';
					|en = 'Signing data with signature type: %1'; fa = 'Signing data with signature type: %1';
					|it = 'Подписание данных типом подписи - %1';
					|pl = 'Signing data with signature type: %1';
					|tr = 'Verilerin %1 imza tipiyle imzalanması'"), SignatureTypeString);
			
		Else
			Return NStr("vi = 'Ký dữ liệu';
						|ru = 'Подписание данных';
						|en = 'Data signing'; fa = 'امضای داده‌ها';
						|it = 'Firma dati';
						|pl = 'Podpisanie danych';
						|tr = 'Verilerin imzalanması'");
		EndIf;
		
	ElsIf TagName = "CheckSignatureLabel" Then
		Return NStr("vi = 'Kiểm tra chữ ký đã tạo';
					|ru = 'Проверка созданной подписи';
					|en = 'Check created signature'; fa = 'بررسی امضای ایجادشده';
					|it = 'Verifica della firma creata';
					|pl = 'Sprawdzenie utworzonego podpisu';
					|tr = 'Oluşturulan imzanın kontrolü'");
		
	ElsIf TagName = "EncryptionLabel" Then
		Return NStr("vi = 'Mã hóa dữ liệu';
					|ru = 'Шифрование данных';
					|en = 'Data encryption'; fa = 'رمزگذاری داده‌ها';
					|it = 'Crittografia dei dati';
					|pl = 'Szyfrowanie danych';
					|tr = 'Veri şifrelemesi'");
		
	ElsIf TagName = "DetailsLabel" Then
		Return NStr("vi = 'Giải mã dữ liệu';
					|ru = 'Расшифровка данных';
					|en = 'Data decryption'; fa = 'رمزگشایی داده‌ها';
					|it = 'Crittografia dati';
					|pl = 'Rozszyfrowanie danych';
					|tr = 'Veri detaylandırması'");
	Else
		Return "";
	EndIf;
	
EndFunction

#EndRegion

&AtClient
Procedure SupplementTextWithErrors(ErrorsText, Checks, AtServer = False, MessageSubject1 = "")
	
	ChecksContent = ThisObject[?(AtServer, "ChecksAtServer", "ChecksAtClient")];
	For Each Validation In Checks Do
		
		If ChecksContent = Undefined Then
			ErrorsText = ErrorsText + Validation + ": "
				+ NStr("vi = 'Không thực hiện vì không cần (không tùy chỉnh)';
						|ru = 'Не выполнялась, так как не требуется (не настроено)';
						|en = 'Not performed as it is not necessary (not configured)'; fa = 'Not performed as it is not necessary (not configured)';
						|it = 'Non è stato effettuato, poiché non è necessario (non impostato)';
						|pl = 'Nie wykonano, ponieważ nie jest wymagane (nie ustawiono)';
						|tr = 'Gerekli olmadığından yapılmadı (ayarlanmadı)'") + Chars.LF;
		Else
			
			CheckResult = ?(ChecksContent.Property(Validation),
				ChecksAtClient[Validation], Undefined);
			
			CheckErrorText = ?(ChecksContent.Property(Validation + "Error"),
				TrimAll(ChecksAtClient[Validation + "Error"]), "");
				
			If IsBlankString(MessageSubject1) And Not IsBlankString(CheckErrorText) Then
				MessageSubject1 = CheckErrorText;
			EndIf;
			
			ErrorsText = ErrorsText + Validation + ": "
				+ ?(CheckResult = Undefined, NStr("vi = 'Không thực hiện được do các lỗi trước đó';
													|ru = 'Не выполнялась из-за предыдущих ошибок';
													|en = 'Not performed because of previous errors'; fa = 'Not performed because of previous errors';
													|it = 'Non eseguito a causa degli errori precedenti';
													|pl = 'Nie wykonano z powodu poprzednich błędów';
													|tr = 'Önceki hatalardan dolayı yapılmadı'"),
				Format(CheckResult, NStr("vi = 'БЛ=Lỗi; БИ=''Thành công''';
										|ru = 'БЛ=Ошибка; БИ=Успех';
										|en = 'BF=Error; BT=Success'; fa = 'BF=Error; BT=Success';
										|it = 'БЛ=Errore; BV=Successo';
										|pl = 'BF=Błąd; BT=Powodzenie';
										|tr = 'BF=Hata; BT=Başarı'")))
				+ ?(IsBlankString(CheckErrorText), "", " """ + CheckErrorText + """") + Chars.LF;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Function ClassifierError(ErrorDescription, ErrorAtServer, SignatureVerificationError, IsCertificateSpecified)
	
	Return DigitalSignatureInternal.ClassifierError(ErrorDescription, ErrorAtServer, SignatureVerificationError, IsCertificateSpecified);
	
EndFunction

&AtClientAtServerNoContext
Function StandardChecks()
	
	StandardChecks = New Array;
	StandardChecks.Add("LegalCertificate");
	StandardChecks.Add("CertificateExists");
	StandardChecks.Add("CertificateData");
	StandardChecks.Add("ProgramExists");
	StandardChecks.Add("Signing");
	StandardChecks.Add("CheckSignature");
	StandardChecks.Add("Encryption");
	StandardChecks.Add("Details");
	
	Return StandardChecks;
	
EndFunction

&AtClient
Function AdditionalData(ErrorName = Undefined)
	
	AdditionalData = DigitalSignatureInternalClient.AdditionalDataForErrorClassifier();
	AdditionalData.Certificate = Certificate;
	AdditionalData.CertificateData = CertificateAddress;

	If ErrorName <> Undefined Then
		AdditionalData.AdditionalDataChecksOnClient = 
			CommonClientServer.StructureProperty(AdditionalDataChecksOnClient, ErrorName, Undefined);
		AdditionalData.AdditionalDataChecksOnServer =
			CommonClientServer.StructureProperty(AdditionalDataChecksOnServer, ErrorName, Undefined);
	EndIf;
	
	Return AdditionalData;
	
EndFunction

&AtClient
Async Function AdditionalCheckOnthePossibilityofSigning(CryptoCertificate, ExecutionSide)
	
	ErrorDescription = "";
	
	If Revoked Then
		ErrorCertificateMarkedAsRevoked = ErrorCertificateMarkedAsRevoked();
		ErrorDescription = ErrorCertificateMarkedAsRevoked.ErrorText;
		SetItem(ThisObject, "Signing", ExecutionSide, ErrorCertificateMarkedAsRevoked, True, MergeResults);
	ElsIf PerformCAVerification <> DigitalSignatureInternalClientServer.NotVerifyCertificate() Then
		
		CheckParameters = New Structure;
		CheckParameters.Insert("ThisVerificationSignature", False);
		CheckParameters.Insert("VerifyCertificate", PerformCAVerification);
			
		ResultofCertificateAuthorityVerification = Await DigitalSignatureInternalClient.ResultofCertificateAuthorityVerification(
			CryptoCertificate,, CheckParameters);

		If Not ResultofCertificateAuthorityVerification.Valid Then

			If PerformCAVerification = DigitalSignatureInternalClientServer.QualifiedOnly() Then
				SigningAllowed = False;
			Else
				SigningAllowed = CommonClient.CommonSettingsStorageLoad(
					Certificate, "AllowSigning", Undefined);
			EndIf;
			If SigningAllowed = Undefined Or Not SigningAllowed Then
				ErrorDescription = ResultofCertificateAuthorityVerification.Warning.ErrorText;
				SetItem(ThisObject, "Signing", ExecutionSide,
					ResultofCertificateAuthorityVerification.Warning, True, MergeResults);
			EndIf;
		EndIf;
	
	EndIf;
	
	Return ErrorDescription;
	
EndFunction

&AtServerNoContext
Function ErrorCertificateMarkedAsRevoked()
	
	Return DigitalSignatureInternal.ErrorCertificateMarkedAsRevoked()
	
EndFunction 

&AtServer
Procedure UpdateCertificateInformation()
	
	CertificateProperties = Common.ObjectAttributesValues(Certificate,
		"Application, EnterPasswordInDigitalSignatureApplication, Revoked");
	
	Revoked = CertificateProperties.Revoked;
	Application = CertificateProperties.Application;
	CertificateEnterPasswordInElectronicSignatureProgram = CertificateProperties.EnterPasswordInDigitalSignatureApplication;

EndProcedure

#EndRegion
