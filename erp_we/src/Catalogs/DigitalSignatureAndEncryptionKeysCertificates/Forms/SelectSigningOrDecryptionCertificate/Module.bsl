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
Var InternalData, PasswordProperties;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DigitalSignatureInternal.SetVisibilityOfRefToAppsTroubleshootingGuide(Items.Instruction);
	
	HaveRightToAddInDirectory = AccessRight("Insert",
		Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates);
	IsFullUser = Users.IsFullUser(Users.CurrentUser());
	CertificateIssueRequestAvailable = DigitalSignature.CommonSettings().CertificateIssueRequestAvailable;
	
	ConditionalAppearance.Items.Clear();
	If Not HaveRightToAddInDirectory Then
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
		AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
		AppearanceColorItem.Use = True;
		
		AppearanceField = ConditionalAppearanceItem.Fields.Items.Add();
		AppearanceField.Field = New DataCompositionField("Certificates");
		AppearanceField.Use = True;
		
		FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue = New DataCompositionField("Certificates.Isinthedirectory");
		FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = False;
		FilterElement.Use = True;
	EndIf;
	
	DigitalSignatureInternal.SetPasswordEntryNote(ThisObject,
		Items.CertificateEnterPasswordInElectronicSignatureProgram.Name,
		Items.AdvancedPasswordNote.Name);
	
	CertificateAttributeParameters =
		DigitalSignatureInternal.NewParametersForCertificateDetails();
	
	If ValueIsFilled(Parameters.Organization) Then
		CertificateAttributeParameters.Insert("Organization", Parameters.Organization);
	EndIf;
	
	ExecuteAtServer = Parameters.ExecuteAtServer;
	
	RefSelectionMode = Parameters.RefSelectionMode;
	
	HasCloudSignature = DigitalSignatureInternal.UseCloudSignatureService();
	
	FilterByCompany = Parameters.FilterByCompany;
	
	If Parameters.CanAddToList Then
		CanAddToList = True;
		Items.Select.Title = NStr("vi = 'Thêm';
									|ru = 'Добавить';
									|en = 'Add'; fa = 'افزودن';
									|it = 'Aggiungere';
									|pl = 'Add';
									|tr = 'Ekle'");
		
		Items.AdvancedPasswordNote.Title =
			NStr("vi = 'Nhấn Thêm để chuyển đến nhập mật khẩu.';
				|ru = 'Нажмите Добавить, чтобы перейти к вводу пароля.';
				|en = 'Click Add to enter the password.'; fa = 'Click Add to enter the password.';
				|it = 'Cliccare su ""Aggiungere"", per passare all''inserimento della password.';
				|pl = 'Naciśnij Dodaj, żeby przejść do wprowadzania hasła.';
				|tr = 'Şifre girmek için Ekle tuşuna basın.'");
		
		PersonalListOnAdd = Parameters.PersonalListOnAdd;
		Items.ShowAll.ToolTip =
			NStr("vi = 'Hiển thị tất cả chứng thư mà không lọc (ví dụ, bao gồm cả chứng thư bổ sung và quá hạn)';
				|ru = 'Показать все сертификаты без отбора (например, включая добавленные и просроченные)';
				|en = 'Show all certificates without filter (for example, including added and overdue)'; fa = 'Show all certificates without filter (for example, including added and overdue)';
				|it = 'Mostrare tutti i certificati senza filtri (ad esempio, includendo quelli scaduti)';
				|pl = 'Pokaż wszystkie certyfikaty bez wyboru (na przykład, włączając dodane i przeterminowane)';
				|tr = 'Filtresiz tüm sertifikaları görüntüle (örnek, eklenen ve vadesi geçenler dahil)'");
	EndIf;
	
	ToEncryptAndDecrypt = Parameters.ToEncryptAndDecrypt;
	ReturnPassword = Parameters.ReturnPassword;
	
	If ToEncryptAndDecrypt = True Then
		If Parameters.CanAddToList Then
			Title = NStr("vi = 'Thêm chứng thư để mã hóa và giải mã dữ liệu';
						|ru = 'Добавление сертификата для шифрования и расшифровки данных';
						|en = 'Add a certificate to encrypt and decrypt data'; fa = 'Add a certificate to encrypt and decrypt data';
						|it = 'Aggiungere certificato per la crittografia e decrittografia dei dati';
						|pl = 'Dodawanie certyfikatu do szyfrowania i deszyfrowania danych';
						|tr = 'Veri şifreleme ve şifre çözme sertifikasının eklenmesi'");
		Else
			Title = NStr("vi = 'Chọn chứng thư để mã hóa và giải mã dữ liệu';
						|ru = 'Выбор сертификата для шифрования и расшифровки данных';
						|en = 'Select certificate to encrypt and decrypt data'; fa = 'Select certificate to encrypt and decrypt data';
						|it = 'Selezione certificato per la crittografia e decrittografia dei dati';
						|pl = 'Wybór certyfikatu do szyfrowania i deszyfrowania danych';
						|tr = 'Veri şifreleme ve şifre çözme sertifikasının seçilmesi'");
		EndIf;
	ElsIf ToEncryptAndDecrypt = False Then
		If Parameters.CanAddToList Then
			Title = NStr("vi = 'Thêm chứng thư để ký dữ liệu';
						|ru = 'Добавление сертификата для подписания данных';
						|en = 'Add a certificate for signing data'; fa = 'Add a certificate for signing data';
						|it = 'Aggiungere certificato per la firma dei dati';
						|pl = 'Dodawanie certyfikatu do podpisywania danych';
						|tr = 'Verilerin imzalanması için sertifikanın eklenmesi'");
		EndIf;
	ElsIf DigitalSignature.UseEncryption() Then
		Title = NStr("vi = 'Thêm chứng thư để ký và mã hóa dữ liệu';
					|ru = 'Добавление сертификата для подписания и шифрования данных';
					|en = 'Add a certificate for signing and encrypting data'; fa = 'Add a certificate for signing and encrypting data';
					|it = 'Aggiungere certificato per la firma e crittografia dei dati';
					|pl = 'Dodawanie certyfikatu do podpisywania i szyfrowania danych';
					|tr = 'Verilen imzalanması ve şifrelenmesi için sertifikanın eklenmesi'");
	Else
		Title = NStr("vi = 'Thêm chứng thư để ký dữ liệu';
					|ru = 'Добавление сертификата для подписания данных';
					|en = 'Add a certificate for signing data'; fa = 'Add a certificate for signing data';
					|it = 'Aggiungere certificato per la firma dei dati';
					|pl = 'Dodawanie certyfikatu do podpisywania danych';
					|tr = 'Verilerin imzalanması için sertifikanın eklenmesi'");
	EndIf;
		
	AreCertificatesOnServerUsed = DigitalSignature.GenerateDigitalSignaturesAtServer() 
		And ExecuteAtServer <> False Or HasCloudSignature;
	
	If Common.IsMobileClient() Then
		If AreCertificatesOnServerUsed Then
			If ExecuteAtServer = True Then
				Items.CertificatesGroup.Title = NStr("vi = 'Chứng thư cá nhân trên máy chủ';
													|ru = 'Личные сертификаты на сервере';
													|en = 'Personal certificates on the server'; fa = 'Personal certificates on the server';
													|it = 'Certificati personali su server';
													|pl = 'Certyfikaty osobiste na serwerze';
													|tr = 'Sunucudaki kişisel sertifikalar'");
			Else
				Items.CertificatesGroup.Title = NStr("ru = 'Личные сертификаты на устройстве и сервере';
													|vi = 'Personal certificates on device and on server';
													|en = 'Personal certificates on device and on server'; fa = 'Personal certificates on device and on server';
													|it = 'Personal certificates on device and on server';
													|pl = 'Personal certificates on device and on server';
													|tr = 'Cihazdaki ve sunucudaki kişisel sertifikalar'");
			EndIf;
		Else
			Items.CertificatesGroup.Title = NStr("ru = 'Личные сертификаты на устройстве';
												|vi = 'Personal certificates on device';
												|en = 'Personal certificates on device'; fa = 'Personal certificates on device';
												|it = 'Personal certificates on device';
												|pl = 'Personal certificates on device';
												|tr = 'Cihazdaki kişisel sertifikalar'");
		EndIf;
	Else
		If AreCertificatesOnServerUsed Then
			If ExecuteAtServer = True Then
				Items.CertificatesGroup.Title = NStr("vi = 'Chứng thư cá nhân trên máy chủ';
													|ru = 'Личные сертификаты на сервере';
													|en = 'Personal certificates on the server'; fa = 'Personal certificates on the server';
													|it = 'Certificati personali su server';
													|pl = 'Certyfikaty osobiste na serwerze';
													|tr = 'Sunucudaki kişisel sertifikalar'");
			Else
				Items.CertificatesGroup.Title = NStr("vi = 'Chứng thư riêng trên máy tính và Server';
													|ru = 'Личные сертификаты на компьютере и сервере';
													|en = 'Personal certificates on computer and on server'; fa = 'Personal certificates on computer and on server';
													|it = 'Certificati personali sul computer e sul server';
													|pl = 'Certyfikaty prywatne na komputerze i serwerze';
													|tr = 'Bilgisayar ve sunucudaki kişisel sertifikalar'");
			EndIf;
		EndIf;
	EndIf;

	CertificateAddress = Parameters.CertificateAddress;
	If IsTempStorageURL(CertificateAddress) Then
		Items.Back.Visible = False;
	EndIf;
	
	HasCompanies = DigitalSignature.CommonSettings().IsCompanyUsed;
	Items.CertificateCompany.Visible = HasCompanies;
	
	Items.CertificateUser1.ToolTip =
		Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.Attributes.User.Tooltip;
	
	Items.CertificateCompany.ToolTip =
		Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.Attributes.Organization.Tooltip;
	
	Items.GroupInidividual.Visible = DigitalSignature.CommonSettings().IndividualUsed;
		
	If ValueIsFilled(Parameters.SelectedCertificateThumbprint) Then
		SelectedCertificateThumbprintNotFound = False;
		SelectedCertificateThumbprint = Parameters.SelectedCertificateThumbprint;
	Else
		SelectedCertificateThumbprint = Common.ObjectAttributeValue(
			Parameters.SelectedCertificate, "Thumbprint");
	EndIf;
	
	ErrorOnGetCertificatesAtClient = Parameters.ErrorOnGetCertificatesAtClient;
	UpdateCertificatesListAtServer(Parameters.CertificatesPropertiesAtClient);
	
	If ValueIsFilled(Parameters.SelectedCertificateThumbprint)
		And Parameters.SelectedCertificateThumbprint <> SelectedCertificateThumbprint Then
		
		SelectedCertificateThumbprintNotFound = True;
	EndIf;
	
	Items.CommandsSelectCancel.Visible = RefSelectionMode;
	Items.SelectRef.DefaultButton = RefSelectionMode;
	Items.CommandsNextAndCancel.Visible = Not RefSelectionMode;
	Items.Next.DefaultButton = Not RefSelectionMode;
	
	SetVisibilityForCertificateAdditionCommands();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If InternalData = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	If Certificates.Count() = 0
		And Not Items.CertificatesUnavailableAtClientGroup.Visible
		And Not Items.CertificatesUnavailableAtServerGroup.Visible
		And Not Items.CloudSignatureAuthorizationGroup.Visible Then
		WarningTextOnOpen = ?(CanAddToList,
			NStr("ru = 'Нет доступных сертификатов для добавления. Возможно, отсутствуют права на добавление сертификатов, обратитесь к администратору.';
				|vi = 'No certificates are available. You may have insufficient permission to add certificates; contact your administrator.';
				|en = 'No certificates are available. You may have insufficient permission to add certificates; contact your administrator.'; fa = 'No certificates are available. You may have insufficient permission to add certificates; contact your administrator.';
				|it = 'No certificates are available. You may have insufficient permission to add certificates; contact your administrator.';
				|pl = 'No certificates are available. You may have insufficient permission to add certificates; contact your administrator.';
				|tr = 'Eklemek için uygun sertifika bulunamadı. Sertifika ekleme yetkiniz olmayabilir, yöneticinize başvurun.'"),
			NStr("ru = 'Нет доступных сертификатов для выбора. Возможно, отсутствуют права на добавление сертификатов, обратитесь к администратору.';
				|vi = 'No certificates are available. You may have insufficient permission to select certificates; contact your administrator.';
				|en = 'No certificates are available. You may have insufficient permission to select certificates; contact your administrator.'; fa = 'No certificates are available. You may have insufficient permission to select certificates; contact your administrator.';
				|it = 'No certificates are available. You may have insufficient permission to select certificates; contact your administrator.';
				|pl = 'No certificates are available. You may have insufficient permission to select certificates; contact your administrator.';
				|tr = 'Seçmek için uygun sertifika bulunamadı. Sertifika ekleme yetkiniz olmayabilir, yöneticinize başvurun.'"));
		Cancel = True;
	EndIf;
		
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionApplications")
		Or Upper(EventName) = Upper("Write_PathsToDigitalSignatureAndEncryptionApplicationsOnLinuxServers") Then
		
		RefreshReusableValues();
		UpdateCertificatesList();
		Return;
	EndIf;
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionKeysCertificates") Then
		
		CurrentData = Items.Certificates.CurrentData;
		
		If Parameter.Property("Is_Specified") And Parameter.Is_Specified And CurrentData <> Undefined
			And TypeOf(Source) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates")
			And Source = Certificate  And Not CurrentData.AtServer Then
			
			CertificateProperties = AddedCertificateProperties(Source);
			FillPropertyValues(CurrentData, CertificateProperties);
			Next(Undefined);
			
		Else
			UpdateCertificatesList();
		EndIf;
		
		Return;
		
	EndIf;
	
	If Upper(EventName) = Upper("InstallCryptoExtension")
		Or Upper(EventName) = Upper("Installation_AddInExtraCryptoAPI") Then
		UpdateCertificatesList();
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// Check the description for uniqueness.
	DigitalSignatureInternal.CheckPresentationUniqueness(
		DescriptionCertificate, Certificate, "DescriptionCertificate", Cancel);
		
	// Validate company value population.
	If Items.CertificateCompany.Visible
	   And Not Items.CertificateCompany.ReadOnly
	   And Items.CertificateCompany.AutoMarkIncomplete = True
	   And Not ValueIsFilled(CertificateCompany) Then
		
		MessageText = NStr("vi = 'Chưa điền trường Doanh nghiệp.';
							|ru = 'Поле Организация не заполнено.';
							|en = 'Company is not populated.'; fa = 'Company is not populated.';
							|it = 'Il campo ""Azienda"" non è compilato.';
							|pl = 'Nie wypełniono pola Firma.';
							|tr = 'İş yeri alanı doldurulmadı.'");
		Common.MessageToUser(MessageText,, "CertificateCompany",, Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	ReturnValue = New Structure;
	ReturnValue.Insert("Ref", Certificate);
	ReturnValue.Insert("Added", ValueIsFilled(Certificate));
	Close(ReturnValue);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PasswordStartChoice(Item, ChoiceData, StandardProcessing)
	DigitalSignatureInternalClient.PasswordFieldStartChoice(ThisObject,
		InternalData, PasswordProperties, StandardProcessing);
EndProcedure

&AtClient
Procedure CertificatesUnavailableAtClientLabelClick(Item)
	
	DigitalSignatureInternalClient.ShowApplicationCallError(
		NStr("vi = 'Chứng thư không hợp lệ trên máy tính';
			|ru = 'Сертификаты недоступны на компьютере';
			|en = 'Certificates not available on computer'; fa = 'گواهی‌ها در رایانه در دسترس نیستند';
			|it = 'Certificati non disponibili sul computer';
			|pl = 'Certyfikaty są niedostępne na komputerze';
			|tr = 'Sertifikalar bilgisayarda mevcut değil'"),
		"",
		ErrorOnGetCertificatesAtClient,
		New Structure);
	
EndProcedure

&AtClient
Procedure CertificatesUnavailableAtServerLabelClick(Item)
	
	DigitalSignatureInternalClient.ShowApplicationCallError(
		NStr("vi = 'Chứng thư không hợp lệ trên Server';
			|ru = 'Сертификаты недоступны на сервере';
			|en = 'Certificates not available on server'; fa = 'گواهی‌ها در سرور در دسترس نیستند';
			|it = 'Certificati non disponibili sul server';
			|pl = 'Certyfikaty są niedostępne na serwerze';
			|tr = 'Sertifikalar sunucuda mevcut değil'"),
		"",
		New Structure,
		ErrorGettingCertificatesAtServer);
	
EndProcedure

&AtClient
Procedure ShowAllOnChange(Item)
	
	UpdateCertificatesList();
	
EndProcedure

&AtClient
Procedure InstructionClick(Item)
	
	DigitalSignatureInternalClient.OpenInstructionOfWorkWithApplications();
	
EndProcedure

&AtClient
Procedure CertificateEnterPasswordInElectronicSignatureProgramOnChange(Item)
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, New Structure("OnChangeCertificateProperties", True));
	
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
Procedure CloudSignatureAuthenticationRequiredLabelClick(Item)
	
	TheNotificationIsAsFollows = New CallbackDescription("RequiresAuthenticationOfTheCloudSignatureInscriptionAfterAuthentication", ThisObject);
	OperationParametersList = New Structure();
	OperationParametersList.Insert("AccountsList", AccountsList.UnloadValues());
	
	TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
	TheDSSCryptographyServiceModuleClient.VerifyingUserAuthentication(TheNotificationIsAsFollows, Undefined, OperationParametersList);
	
EndProcedure

&AtClient
Procedure RequiresAuthenticationOfTheCloudSignatureInscriptionAfterAuthentication(CallResult, AdditionalParameters) Export
	
	If CallResult.Completed2 Then
		UpdateCertificatesList();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCertificates

&AtClient
Procedure CertificatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If RefSelectionMode Then
		SelectRef(Undefined);
	Else
		Next(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure CertificatesOnActivateRow(Item)
	
	If Items.Certificates.CurrentData = Undefined Then
		SelectedCertificateThumbprint = "";
	Else
		SelectedCertificateThumbprint = Items.Certificates.CurrentData.Thumbprint;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	UpdateCertificatesList();
	
EndProcedure

&AtClient
Procedure ShowCurrentCertificateData(Command)
	
	CurrentData = Items.Certificates.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.LocationType = 3 Then
		TheDSSCryptographyServiceModuleClientServer = CommonClient.CommonModule("DSSCryptographyServiceClientServer");
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		CertificateThumbprint = New Structure();
		CertificateThumbprint.Insert("Thumbprint", TheDSSCryptographyServiceModuleClientServer.TransformFingerprint(CurrentData.Thumbprint));
		
		OperationParametersList = New Structure;
		OperationParametersList.Insert("GetBinaryData", True);
		
		CycleParameters = New Structure("IsRequest", CurrentData.IsRequest);
		
		TheNotificationIsAsFollows = New CallbackDescription("OpenTheCloudSignatureCertificate", ThisObject, CycleParameters);
		TheDSSCryptographyServiceModuleClient.FindCertificate(TheNotificationIsAsFollows, CertificateThumbprint, OperationParametersList);
	Else
		DigitalSignatureClient.OpenCertificate(CurrentData.Thumbprint, Not CurrentData.IsRequest);
	EndIf;
	
EndProcedure

&AtClient
Procedure Next(Command)
	
	Items.Next.Enabled = False;
	
	GoToCurrentCertificateChoice(New CallbackDescription(
		"NextAfterGoToCurrentCertificateSelection", ThisObject));
	
EndProcedure

// Continues the Next procedure.
&AtClient
Procedure NextAfterGoToCurrentCertificateSelection(Result, Context) Export
	
	If Result = True Then
		Items.Next.Enabled = True;
		Return;
	EndIf;
	
	Context = Result;
	
	If Context.UpdateCertificatesList Then
		UpdateCertificatesList(New CallbackDescription(
			"NextAfterCertificatesListUpdate", ThisObject, Context));
	Else
		NextAfterCertificatesListUpdate(Undefined, Context);
	EndIf;
	
EndProcedure

// Continues the Next procedure.
&AtClient
Procedure NextAfterCertificatesListUpdate(Result, Context) Export
	
	ShowMessageBox(, Context.ErrorDescription);
	Items.Next.Enabled = True;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	Items.MainPages.CurrentPage = Items.CertificateSelectionPage;
	Items.Next.DefaultButton = True;
	
	UpdateCertificatesList();
	
EndProcedure

&AtClient
Procedure Select(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	If CloudSignatureCertificate Then
		TheDSSCryptographyServiceModuleClientServer = CommonClient.CommonModule("DSSCryptographyServiceClientServer");
		TheDSSCryptographyServiceModuleInternalServerCall = CommonClient.CommonModule("DSSCryptographyServiceInternalServerCall");
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		
		CertificateThumbprint = TheDSSCryptographyServiceModuleClientServer.TransformFingerprint(SelectedCertificateThumbprint);
		UserSettings = TheDSSCryptographyServiceModuleInternalServerCall.GetUserSettingsByCertificate(CertificateThumbprint);
		
		OperationParametersList = New Structure();
		OperationParametersList.Insert("Account", UserSettings.Ref);
		OperationParametersList.Insert("CertificateThumbprint", CertificateThumbprint);
		
		TheDSSCryptographyServiceModuleClient.CheckCertificate(
			New CallbackDescription("SelectAfterVerifyingTheCloudSignatureCertificate", ThisObject, OperationParametersList),
			UserSettings,
			GetFromTempStorage(AddressOfCertificate));
	
	ElsIf CertificateInCloudService Then
		
		ModuleCryptographyServiceClient = CommonClient.CommonModule("CryptographyServiceClient");
		ModuleCryptographyServiceClient.CheckCertificate(
			New CallbackDescription("SelectAfterCertificateCheckInSaaSMode", ThisObject, Undefined),
			GetFromTempStorage(AddressOfCertificate));
		
	Else
		
		CertificateParameters = DigitalSignatureClient.CertificateRecordParameters();
		CertificateParameters.Description = DescriptionCertificate;
		CertificateParameters.User = CertificateUser1;
		CertificateParameters.Organization = CertificateCompany;
		CertificateParameters.Individual = CertificateIndividual;
		CertificateParameters.EnterPasswordInDigitalSignatureApplication = CertificateEnterPasswordInElectronicSignatureProgram;
		
		DigitalSignatureClient.WriteCertificateToCatalog(
			New CallbackDescription("SelectAfterCertificateCheck", ThisObject, Undefined),
			AddressOfCertificate, PasswordProperties.Value, ToEncryptAndDecrypt, CertificateParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectRef(Command)
	
	CurrentData = Items.Certificates.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.Certificates.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CompletionNotification = New CallbackDescription("SelectRefCompletion", ThisObject);
	
	If CurrentData.LocationType = 3 Then
		TheDSSCryptographyServiceModuleClientServer = CommonClient.CommonModule("DSSCryptographyServiceClientServer");
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		CertificateThumbprint = New Structure();
		CertificateThumbprint.Insert("Thumbprint", TheDSSCryptographyServiceModuleClientServer.TransformFingerprint(CurrentData.Thumbprint));
		
		OperationParametersList = New Structure;
		OperationParametersList.Insert("GetBinaryData", True);
		TheDSSCryptographyServiceModuleClient.FindCertificate(CompletionNotification, CertificateThumbprint, OperationParametersList);
	Else
		DigitalSignatureInternalClient.GetCertificateByThumbprint(CompletionNotification, CurrentData.Thumbprint, False);
	EndIf;
	
EndProcedure

// Continues the SelectRef procedure.
&AtClient
Procedure SelectRefCompletion(Result, Context) Export 
	Close(Result.Unload());
EndProcedure

// Continues the Select procedure.
&AtClient
Procedure SelectAfterCertificateCheck(Result, Context) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters = DigitalSignatureInternalClient.ParametersNotificationWhenWritingCertificate();
	
	If Not ValueIsFilled(Certificate) Then
		AdditionalParameters.IsNew = True;
		AdditionalParameters.Is_Specified = True;
	EndIf;
	
	Certificate = Result;
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject,
		InternalData, PasswordProperties, New Structure("OnOperationSuccess", True));
		
	DigitalSignatureInternalClient.AfterAddingElectronicSignatureCertificatesToCatalog(Certificate, AdditionalParameters);
	
	If ReturnPassword Then
		
		InternalData.Insert("SelectedCertificate", Certificate);
		If Not RememberPassword Then
			InternalData.Insert("SelectedCertificatePassword", PasswordProperties.Value);
		EndIf;
		
		NotifyChoice(True);
		
	Else
		NotifyChoice(Certificate);
	EndIf;
	
EndProcedure

// Continues the Select procedure.
&AtClient
Procedure SelectAfterVerifyingTheCloudSignatureCertificate(Result, Context) Export
	
	AdditionalParameters = DigitalSignatureInternalClient.ParametersNotificationWhenWritingCertificate();
	If Not Result.Completed2 Then
		ErrorDescription = Result.Error;
	ElsIf Not Result.Result Then
		ErrorDescription = DigitalSignatureInternalClientServer.ServiceErrorTextCertificateInvalid();
	EndIf;
	
	If ValueIsFilled(ErrorDescription) Then
		If ToEncryptAndDecrypt = True Then
			FormCaption = NStr("vi = 'Kiểm tra mã hóa và giải mã';
								|ru = 'Проверка шифрования и расшифровки';
								|en = 'Encryption and decryption check'; fa = 'Encryption and decryption check';
								|it = 'Verifica di crittografia e decrittografia';
								|pl = 'Weryfikacja szyfrowania i deszyfracji';
								|tr = 'Şifreleme ve şifre çözme kontrolü'");
		Else
			FormCaption = NStr("vi = 'Kiểm tra thiết lập chữ ký điện tử';
								|ru = 'Проверка установки электронной подписи';
								|en = 'Digital signature verification'; fa = 'Digital signature verification';
								|it = 'Verifica impostazione della firma elettronica';
								|pl = 'Weryfikacja instalacji podpisu elektronicznego';
								|tr = 'Dijital imza kurulumunun kontrolü'");
		EndIf;
		DigitalSignatureInternalClient.ShowApplicationCallError(
			FormCaption, "", New Structure("ErrorDescription", ErrorDescription), New Structure);
		Return;
	EndIf;
	
	If Not ValueIsFilled(Certificate) Then
		AdditionalParameters.IsNew = True;
	EndIf;
	
	WriteTheCertificateToTheCloudSignatureDirectory(Context.Account);
	
	DigitalSignatureInternalClient.AfterAddingElectronicSignatureCertificatesToCatalog(Certificate, AdditionalParameters);
	
	NotifyChoice(Certificate);
	
EndProcedure

// Continues the Select procedure.
&AtClient
Procedure SelectAfterCertificateCheckInSaaSMode(Result, Context) Export
	
	AdditionalParameters = DigitalSignatureInternalClient.ParametersNotificationWhenWritingCertificate();
	If Not Result.Completed2 Then
		ErrorDescription = ErrorProcessing.BriefErrorDescription(Result.ErrorInfo);
	ElsIf Not Result.Valid1 Then
		ErrorDescription = DigitalSignatureInternalClientServer.ServiceErrorTextCertificateInvalid();
	EndIf;
	
	If ValueIsFilled(ErrorDescription) Then
		If ToEncryptAndDecrypt = True Then
			FormCaption = NStr("vi = 'Kiểm tra mã hóa và giải mã';
								|ru = 'Проверка шифрования и расшифровки';
								|en = 'Encryption and decryption check'; fa = 'Encryption and decryption check';
								|it = 'Verifica di crittografia e decrittografia';
								|pl = 'Weryfikacja szyfrowania i deszyfracji';
								|tr = 'Şifreleme ve şifre çözme kontrolü'");
		Else
			FormCaption = NStr("vi = 'Kiểm tra thiết lập chữ ký điện tử';
								|ru = 'Проверка установки электронной подписи';
								|en = 'Digital signature verification'; fa = 'Digital signature verification';
								|it = 'Verifica impostazione della firma elettronica';
								|pl = 'Weryfikacja instalacji podpisu elektronicznego';
								|tr = 'Dijital imza kurulumunun kontrolü'");
		EndIf;
		AdditionalParameters = New Structure("Certificate", AddressOfCertificate);
		DigitalSignatureInternalClient.ShowApplicationCallError(FormCaption,
			"", New Structure("ErrorDescription", ErrorDescription), New Structure, AdditionalParameters);
		Return;
	EndIf;
	
	If Not ValueIsFilled(Certificate) Then
		AdditionalParameters.IsNew = True;
	EndIf;
	
	WriteCertificateToCatalogSaaS();
	DigitalSignatureInternalClient.AfterAddingElectronicSignatureCertificatesToCatalog(Certificate, AdditionalParameters);
	NotifyChoice(Certificate);
	
EndProcedure

&AtClient
Procedure ShowCertificateData(Command)
	
	If ValueIsFilled(AddressOfCertificate) Then
		DigitalSignatureClient.OpenCertificate(AddressOfCertificate, True);
	Else
		DigitalSignatureClient.OpenCertificate(ThumbprintOfCertificate, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure PickIndividual(Command)
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Property", NStr("vi = 'Người nhận:';
											|ru = 'Кому выдан:';
											|en = 'Owner:'; fa = 'Owner:';
											|it = 'Rilasciato a:';
											|pl = 'Wydano dla:';
											|tr = 'Kime verildi:'"));
	CertificateDataDetailsStrings = DetailsOfCertificateData.FindRows(FilterParameters);
	If CertificateDataDetailsStrings.Count() = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Không có cá nhân phù hợp.';
										|ru = 'Подходящее физическое лицо не существует.';
										|en = 'An appropriate individual does not exist.'; fa = 'An appropriate individual does not exist.';
										|it = 'Подходящее физическое лицо не существует.';
										|pl = 'An appropriate individual does not exist.';
										|tr = 'Uygun bir gerçek kişi yok.'"));
		Return;
	EndIf;
	
	IssuedTo = CertificateDataDetailsStrings[0].Value;
	
	DigitalSignatureInternalClient.PickIndividualForCertificate(ThisObject, IssuedTo, CertificateIndividual);

EndProcedure

&AtClient
Procedure AddCertificateIssueRequest(Command)
	
	CreationParameters = DigitalSignatureInternalClient.CertificateAddingOptions();
	CreationParameters.CreateRequest = True;
	DigitalSignatureInternalClient.AddCertificateAfterPurposeChoice("CertificateIssueRequest", 
		CreationParameters);
	
EndProcedure

&AtClient
Procedure AddForSigningAndEncryptionFromFiles(Command)
	
	CreationParameters = DigitalSignatureInternalClient.CertificateAddingOptions();
	CreationParameters.CompletionHandler = New CallbackDescription("AfterAddCertificate", ThisObject);
	DigitalSignatureInternalClient.AddCertificateAfterPurposeChoice("ForSigningEncryptionAndDecryptionFromFiles", CreationParameters);
	
EndProcedure

#EndRegion

#Region Private

// ACC:78-off - Intended for the secure transfer of data between forms on the client without sending it to the server.
&AtClient
Procedure ContinueOpening(Notification, CommonInternalData) Export
// ACC:78-on - Intended for the secure transfer of data between forms on the client without sending it to the server.
	
	InternalData = CommonInternalData;
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject, InternalData, PasswordProperties);
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	
	If SelectedCertificateThumbprintNotFound = Undefined
		Or SelectedCertificateThumbprintNotFound = True Then
		
		ContinueOpeningAfterGoToChooseCurrentCertificate(Undefined, Context);
	Else
		GoToCurrentCertificateChoice(New CallbackDescription(
			"ContinueOpeningAfterGoToChooseCurrentCertificate", ThisObject, Context));
	EndIf;
	
EndProcedure

// Continues the ContinueOpening procedure.
&AtClient
Procedure ContinueOpeningAfterGoToChooseCurrentCertificate(Result, Context) Export
	
	If TypeOf(Result) = Type("Structure") Then
		NotifyChoice(False);
	Else
		Open();
	EndIf;
	
	If ValueIsFilled(CertificateAddress) Then
		CertificateData = New Structure;
		CertificateData.Insert("Certificate", CertificateAddress);
		AfterAddCertificate(CertificateData, Undefined);
	EndIf;
	
	RunCallback(Context.Notification);
	
EndProcedure

&AtServer
Function FillCurrentCertificatePropertiesAtServer(Val Thumbprint, SavedProperties)
	
	CryptoCertificate = DigitalSignatureInternal.GetCertificateByThumbprint(Thumbprint, False);
	If CryptoCertificate = Undefined Then
		Return False;
	EndIf;
	
	AddressOfCertificate = PutToTempStorage(CryptoCertificate.Unload(),
		UUID);
	
	ThumbprintOfCertificate = Thumbprint;
	
	DigitalSignatureInternalClientServer.FillCertificateDataDetails(DetailsOfCertificateData,
		DigitalSignature.CertificateProperties(CryptoCertificate));
	
	SavedProperties = SavedCertificateProperties(Thumbprint,
		AddressOfCertificate, CertificateAttributeParameters);
	
	Return True;
	
EndFunction

&AtServerNoContext
Function SavedCertificateProperties(Val Thumbprint, Val Address, AttributesParameters)
	
	Return DigitalSignatureInternal.SavedCertificateProperties(Thumbprint, Address, AttributesParameters);
	
EndFunction

&AtClient
Procedure UpdateCertificatesList(Notification = Undefined)
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	
	If DigitalSignatureClient.GenerateDigitalSignaturesAtServer()
		And ExecuteAtServer = True Then
		
		Result = New Structure;
		Result.Insert("CertificatesPropertiesAtClient", New Array);
		Result.Insert("ErrorOnGetCertificatesAtClient", New Structure);
		
		UpdateCertificatesListContinued(Result, Context);
	Else
		DigitalSignatureInternalClient.GetCertificatesPropertiesAtClient(New CallbackDescription(
			"UpdateCertificatesListContinued", ThisObject, Context), True, ShowAll);
	EndIf;
	
EndProcedure

// Continues the UpdateCertificatesList procedure.
&AtClient
Procedure UpdateCertificatesListContinued(Result, Context) Export
	
	ErrorOnGetCertificatesAtClient = Result.ErrorOnGetCertificatesAtClient;
	
	UpdateCertificatesListAtServer(Result.CertificatesPropertiesAtClient);
	
	If Context.Notification <> Undefined Then
		RunCallback(Context.Notification);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateCertificatesListAtServer(Val CertificatesPropertiesAtClient)
	
	ErrorGettingCertificatesAtServer = New Structure;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FilterByCompany", FilterByCompany);
	AdditionalParameters.Insert("ExecuteAtServer", ExecuteAtServer);
	AdditionalParameters.Insert("AreAvailableOnlyWithKey", Not ShowAll);
	
	DigitalSignatureInternal.UpdateCertificatesList(Certificates, CertificatesPropertiesAtClient,
		CanAddToList, True, ErrorGettingCertificatesAtServer, ShowAll, AdditionalParameters);
	
	If CertificateIssueRequestAvailable Then
		
		ModuleApplicationForIssuingANewQualifiedCertificate = Common.CommonModule("DataProcessors.ApplicationForNewQualifiedCertificateIssue");
		ModuleApplicationForIssuingANewQualifiedCertificate.AddStatementsToCertificateTable(Certificates);
		
	EndIf;
	
	If HaveRightToAddInDirectory Then
		Certificates.Sort("IsRequest Asc, Presentation Asc");
	Else
		Certificates.Sort("Isinthedirectory Desc, IsRequest Asc, Presentation Asc");
	EndIf;
	
	If ValueIsFilled(SelectedCertificateThumbprint)
		And (Items.Certificates.CurrentRow = Undefined
		Or Certificates.FindByID(Items.Certificates.CurrentRow) = Undefined
		Or Certificates.FindByID(Items.Certificates.CurrentRow).Thumbprint <> SelectedCertificateThumbprint) Then
		
		Filter = New Structure("Thumbprint", SelectedCertificateThumbprint);
		Rows = Certificates.FindRows(Filter);
		If Rows.Count() > 0 Then
			Items.Certificates.CurrentRow = Rows[0].GetID();
		EndIf;
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.CertificatesUnavailableAtClientGroup.Visible = False;
	Else
		Items.CertificatesUnavailableAtClientGroup.Visible =
			ValueIsFilled(ErrorOnGetCertificatesAtClient);
	EndIf;
	
	Items.CertificatesUnavailableAtServerGroup.Visible =
		ValueIsFilled(ErrorGettingCertificatesAtServer);
	
	AuthenticationVisibility = False;
	If DigitalSignatureInternal.UseCloudSignatureService() Then
		TheDSSCryptographyServiceModuleInternal = Common.CommonModule("DSSCryptographyServiceInternal");
		AccountsList.LoadValues(TheDSSCryptographyServiceModuleInternal.AccountsWithoutCertificates());
		AuthenticationVisibility = AccountsList.Count() > 0;
	EndIf;
	
	Items.CloudSignatureAuthorizationGroup.Visible = AuthenticationVisibility;
	
	If Items.Certificates.CurrentRow = Undefined Then
		SelectedCertificateThumbprint = "";
	Else
		String = Certificates.FindByID(Items.Certificates.CurrentRow);
		SelectedCertificateThumbprint = ?(String = Undefined, "", String.Thumbprint);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenTheCloudSignatureCertificate(SearchResult, AdditionalParameters) Export
	
	If SearchResult.Completed2 Then
		DigitalSignatureClient.OpenCertificate(SearchResult.CertificateData.Certificate, Not AdditionalParameters.IsRequest);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToCurrentCertificateChoice(Notification)
	
	Result = New Structure;
	Result.Insert("ErrorDescription", "");
	Result.Insert("UpdateCertificatesList", False);
	
	If Items.Certificates.CurrentData = Undefined Then
		If Not ValueIsFilled(CertificateAddress) Then
			Result.ErrorDescription = NStr("vi = 'Hãy chọn chứng thư sẽ sử dụng.';
											|ru = 'Выделите сертификат, который будет использоваться.';
											|en = 'Select a certificate to be used.'; fa = 'Select a certificate to be used.';
											|it = 'Selezionare il certificato che sarà utilizzato.';
											|pl = 'Zaznacz certyfikat, który będzie wykorzystywany.';
											|tr = 'Kullanılacak sertifikayı vurgulayın.'");
			RunCallback(Notification, Result);
		EndIf;
		Return;
	EndIf;
	
	CurrentData = Items.Certificates.CurrentData;
	
	If CurrentData.IsRequest Then
		If ValueIsFilled(CurrentData.Ref) Then
			Items.Next.Enabled = True;
			FormParameters = New Structure;
			FormParameters.Insert("Key", CurrentData.Ref);
			OpenForm("Catalog.DigitalSignatureAndEncryptionKeysCertificates.ObjectForm", FormParameters, ThisObject);
		Else
			Result.UpdateCertificatesList = True;
			Result.ErrorDescription =
				NStr("vi = 'Đối với chứng chỉ này, ứng dụng cấp chứng chỉ chưa được thực hiện.
				           |Mở ứng dụng cấp chứng chỉ và làm theo các bước bắt buộc.';
				           |ru = 'Для этого сертификата заявление на выпуск еще не исполнено.
				           |Откройте заявление на выпуск сертификата и выполните требуемые шаги.';
				           |en = 'The application for this certificate has not yet been fulfilled.
				           |Open the application and complete the necessary steps.'; fa = 'The application for this certificate has not yet been fulfilled.
				           |Open the application and complete the necessary steps.';
				           |it = 'Per questo certificato, la domanda di rilascio non è stata ancora eseguita.
				           | Aprire l''applicazione per il rilascio del certificato e seguire i passaggi richiesti.';
				           |pl = 'Dla tego certyfikatu nie wykonano jeszcze wniosku o wydanie.
				           |Otwórz wniosek o wydanie certyfikatu i wykonaj niezbędne kroki.';
				           |tr = 'Bu sertifika için düzenleme başvurusu henüz yapılmadı.
				           |Düzenleme başvurusunu açın ve gereken adımları yerine getirin.'");
			RunCallback(Notification, Result);
		EndIf;
		Return;
	EndIf;
	
	If Not HaveRightToAddInDirectory And Not CurrentData.Isinthedirectory Then
		Result.UpdateCertificatesList = True;
		Result.ErrorDescription =
			NStr("ru = 'Отсутствуют права на добавление сертификатов в справочник. Обратитесь к администратору.';
				|vi = 'Insufficient permission to add certificates; contact your administrator.';
				|en = 'Insufficient permission to add certificates; contact your administrator.'; fa = 'Insufficient permission to add certificates; contact your administrator.';
				|it = 'Insufficient permission to add certificates; contact your administrator.';
				|pl = 'Insufficient permission to add certificates; contact your administrator.';
				|tr = 'Kılavuza sertifika ekleme yetkisi bulunmuyor. Yöneticinize başvurun.'");
		RunCallback(Notification, Result);
		Return;
	EndIf;
	
	CertificateAtClient = CurrentData.AtClient;
	CertificateAtServer = CurrentData.AtServer;
	CertificateInCloudService = CurrentData.InCloudService;
	CloudSignatureCertificate = DigitalSignatureInternalClientServer.PlacementOfTheCertificate(CurrentData.LocationType) = "CloudSignature";
	
	Context = New Structure;
	Context.Insert("Notification",          Notification);
	Context.Insert("Result",           Result);
	Context.Insert("CurrentData",       CurrentData);
	Context.Insert("SavedProperties", Undefined);
	
	If CertificateAtServer Then
		If FillCurrentCertificatePropertiesAtServer(CurrentData.Thumbprint, Context.SavedProperties) Then
			GoToCurrentCertificateChoiceAfterFillCertificateProperties(Context);
		Else
			Result.ErrorDescription = NStr("vi = 'Chứng chỉ bị thiếu trên máy chủ (có thể bị xóa).';
											|ru = 'Сертификат отсутствует на сервере (возможно удален).';
											|en = 'Certificate does not exist on the server (it might have been deleted).'; fa = 'Certificate does not exist on the server (it might have been deleted).';
											|it = 'Certificato non trovato sul server (probabilmente eliminato).';
											|pl = 'Nie ma certyfikatu na serwerze (mógł być usunięty).';
											|tr = 'Sertifika sunucuda mevcut değil (silinmiş olabilir).'");
			Result.UpdateCertificatesList = True;
			RunCallback(Notification, Result);
		EndIf;
		Return;
	EndIf;
	
	If DigitalSignatureInternalClientServer.PlacementOfTheCertificate(CurrentData.LocationType) = "CloudSignature" Then
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		TheDSSCryptographyServiceModuleClientServer = CommonClient.CommonModule("DSSCryptographyServiceClientServer");
		
		OperationParametersList = New Structure;
		OperationParametersList.Insert("GetBinaryData", True);

		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Thumbprint", TheDSSCryptographyServiceModuleClientServer.TransformFingerprint(CurrentData.Thumbprint));
		
		TheDSSCryptographyServiceModuleClient.FindCertificate(New CallbackDescription(
			"GoToTheCurrentCertificateSelectionAfterSearchingForTheCertificateInTheCloudSignature", ThisObject, Context), TheStructureOfTheSearch, OperationParametersList);
	
	ElsIf CurrentData.InCloudService Then
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Thumbprint", Base64Value(CurrentData.Thumbprint));
		ModuleCertificateStoreClient = CommonClient.CommonModule("CertificatesStorageClient");
		ModuleCertificateStoreClient.FindCertificate(New CallbackDescription(
			"GoToCurrentCertificateChoiceAfterCertificateSearchInCloudService", ThisObject, Context), TheStructureOfTheSearch);
	Else
		DigitalSignatureInternalClient.GetCertificateByThumbprint(
			New CallbackDescription("GoToCurrentCertificateChoiceAfterCertificateSearch", ThisObject, Context),
			CurrentData.Thumbprint, False, Undefined);
	EndIf;
	
EndProcedure

// Continues the GoToCurrentCertificateChoice procedure.
// 
// Parameters:
//   SearchResult - CryptoCertificate
//   Context - Structure
//
&AtClient
Procedure GoToCurrentCertificateChoiceAfterCertificateSearch(SearchResult, Context) Export
	
	If TypeOf(SearchResult) <> Type("CryptoCertificate") Then
		If SearchResult.Property("CertificateNotFound") Then
			Context.Result.ErrorDescription = NStr("vi = 'Chứng chỉ không được cài đặt trên máy tính (có thể bị xóa).';
													|ru = 'Сертификат не установлен на компьютере (возможно удален).';
													|en = 'The certificate is not installed or was deleted from your computer.'; fa = 'The certificate is not installed or was deleted from your computer.';
													|it = 'Certificato non installato nel computer (è possibile sia stato eliminato).';
													|pl = 'Certyfikat nie został zainstalowany na komputerze (mógł być usunięty).';
													|tr = 'Sertifika bilgisayarda kurulu değil (silinmiş olabilir).'");
		Else
			Context.Result.ErrorDescription = SearchResult.ErrorDescription;
		EndIf;
		Context.Result.UpdateCertificatesList = True;
		RunCallback(Context.Notification, Context.Result);
		Return;
	EndIf;
	
	Context.Insert("CryptoCertificate", SearchResult);
	
	SearchResult.BeginUnloading(New CallbackDescription(
		"GoToCurrentCertificateChoiceAfterCertificateExport", ThisObject, Context));
	
EndProcedure

// Continues the GoToCurrentCertificateChoice procedure.
// 
// Parameters:
//   SearchResult - Structure:
//   * Completed2 - Boolean
//   * ErrorDescription - Structure:
//   ** LongDesc - String
//   Context - Structure
//
&AtClient
Procedure GoToCurrentCertificateChoiceAfterCertificateSearchInCloudService(SearchResult, Context) Export
	
	If Not SearchResult.Completed2 Then
		Context.Result.ErrorDescription = SearchResult.ErrorDescription.LongDesc;
		Context.Result.UpdateCertificatesList = True;
		RunCallback(Context.Notification, Context.Result);
		Return;
	EndIf;
	
	If Not ValueIsFilled(SearchResult.Certificate) Then
		Context.Result.ErrorDescription = NStr("vi = 'Không tồn tại chứng thư trong dịch vụ (có thể là đã bị xóa).';
												|ru = 'Сертификат отсутствует в сервисе (возможно удален).';
												|en = 'The certificate does not exist in the service. It might have been deleted.'; fa = 'The certificate does not exist in the service. It might have been deleted.';
												|it = 'Certificato assente nel servizio (forse eliminato).';
												|pl = 'Brak certyfikatu w usłudze (mógł być usunięty).';
												|tr = 'Hizmette sertifika eksik (silinmiş olabilir).'");
		Context.Result.UpdateCertificatesList = True;
		RunCallback(Context.Notification, Context.Result);
		Return;
	EndIf;
	
	Context.Insert("CryptoCertificate", SearchResult.Certificate);
	GoToCurrentCertificateChoiceAfterCertificateExport(SearchResult.Certificate.Certificate, Context);
	
EndProcedure

// Continues the GoToCurrentCertificateChoice procedure.
// 
// Parameters:
//   SearchResult - Structure:
//   * Completed2 - Boolean
//   * Error - String
//   Context - Structure
//
&AtClient
Procedure GoToTheCurrentCertificateSelectionAfterSearchingForTheCertificateInTheCloudSignature(SearchResult, Context) Export
	
	If Not SearchResult.Completed2 Then
		Context.Result.ErrorDescription = SearchResult.Error;
		Context.Result.UpdateCertificatesList = True;
		RunCallback(Context.Notification, Context.Result);
		Return;
	EndIf;
	
	If Not ValueIsFilled(SearchResult.CertificateData) Then
		Context.Result.ErrorDescription = NStr("vi = 'Không tồn tại chứng thư trên máy chủ DSS (có thể là đã bị xóa).';
												|ru = 'Сертификат отсутствует на сервере DSS (возможно удален).';
												|en = 'Certificate does not exist on the DSS server (it might have been deleted).'; fa = 'Certificate does not exist on the DSS server (it might have been deleted).';
												|it = 'Certificato assente su server DSS (forse eliminato).';
												|pl = 'Brak certyfikatu na serwerze DSS (mógł być usunięty).';
												|tr = 'DSS sunucusunda sertifika eksik (silinmiş olabilir).'");
		Context.Result.UpdateCertificatesList = True;
		RunCallback(Context.Notification, Context.Result);
		Return;
	EndIf;
	
	Context.Insert("CryptoCertificate", SearchResult.CertificateData);
	GoToCurrentCertificateChoiceAfterCertificateExport(SearchResult.CertificateData.Certificate, Context);
	
EndProcedure

// Continues the GoToCurrentCertificateChoice procedure.
&AtClient
Async Procedure GoToCurrentCertificateChoiceAfterCertificateExport(ExportedData, Context) Export
	
	AddressOfCertificate = PutToTempStorage(ExportedData, UUID);
	
	ThumbprintOfCertificate = Context.CurrentData.Thumbprint;
	
	DigitalSignatureInternalClientServer.FillCertificateDataDetails(DetailsOfCertificateData,
		Await DigitalSignatureInternalClient.CertificateProperties(Context.CryptoCertificate));
	
	Context.SavedProperties = SavedCertificateProperties(Context.CurrentData.Thumbprint,
		AddressOfCertificate, CertificateAttributeParameters);
		
	If ValueIsFilled(FilterByCompany) Then
		Context.SavedProperties.Insert("Organization", FilterByCompany);
	EndIf;
	
	GoToCurrentCertificateChoiceAfterFillCertificateProperties(Context);
	
EndProcedure

// Continues the GoToCurrentCertificateChoice procedure.
&AtClient
Procedure GoToCurrentCertificateChoiceAfterFillCertificateProperties(Context)
	
	If CertificateAttributeParameters.Property("Description") Then
		AttributesParameters = CertificateAttributeParameters; // See DigitalSignatureInternal.NewParametersForCertificateDetails
		If AttributesParameters.Description.ReadOnly Then
			Items.DescriptionCertificate.ReadOnly = True;
		EndIf;
	EndIf;
	
	If HasCompanies Then
		If CertificateAttributeParameters.Property("Organization") Then
			If Not CertificateAttributeParameters.Organization.Visible Then
				Items.CertificateCompany.Visible = False;
			ElsIf CertificateAttributeParameters.Organization.ReadOnly Then
				Items.CertificateCompany.ReadOnly = True;
			ElsIf CertificateAttributeParameters.Organization.FillChecking Then
				Items.CertificateCompany.AutoMarkIncomplete = True;
			EndIf;
		EndIf;
	EndIf;

#If MobileAppClient Or MobileClient Then
	Items.CertificateEnterPasswordInElectronicSignatureProgram.Visible = False;
#Else
	If CertificateAttributeParameters.Property("EnterPasswordInDigitalSignatureApplication") Then
		If Not CertificateAttributeParameters.EnterPasswordInDigitalSignatureApplication.Visible Then
			Items.CertificateEnterPasswordInElectronicSignatureProgram.Visible = False;
		ElsIf CertificateAttributeParameters.EnterPasswordInDigitalSignatureApplication.ReadOnly Then
			Items.CertificateEnterPasswordInElectronicSignatureProgram.ReadOnly = True;
		EndIf;
	EndIf;
#EndIf
	
	CertificateUser1 = UsersClient.CurrentUser();
	If Not IsFullUser Then
		Items.CertificateUser1.ReadOnly = True;
	EndIf;
	
	Certificate             = Context.SavedProperties.Ref;
	CertificateCompany  = Context.SavedProperties.Organization;
	DescriptionCertificate = Context.SavedProperties.Description;
	CertificateIndividual = Context.SavedProperties.Individual;
	CertificateEnterPasswordInElectronicSignatureProgram = Context.SavedProperties.EnterPasswordInDigitalSignatureApplication;
	
	DigitalSignatureInternalClient.ProcessPasswordInForm(ThisObject, InternalData, PasswordProperties);
	
	Items.MainPages.CurrentPage = Items.PromptForCertificatePropertiesPage;
	Items.Select.DefaultButton = True;
	
	If CanAddToList Then
		String = ?(ValueIsFilled(Certificate), NStr("vi = 'Cập nhật';
													|ru = 'Обновить';
													|en = 'Update'; fa = 'به‌روزرسانی';
													|it = 'Aggiornare';
													|pl = 'Zaktualizuj';
													|tr = 'Yenile'"), NStr("vi = 'Thêm';
																			|ru = 'Добавить';
																			|en = 'Add'; fa = 'افزودن';
																			|it = 'Aggiungere';
																			|pl = 'Dodaj';
																			|tr = 'Ekle'"));
		If Items.Select.Title <> String Then
			Items.Select.Title = String;
		EndIf;
	EndIf;
	
	If CertificateInCloudService Or CloudSignatureCertificate Then
		Items.GroupEnterPasswordInElectronicSignatureProgram.Visible = False;
	Else
		Items.GroupEnterPasswordInElectronicSignatureProgram.Visible = True;
		AttachIdleHandler("IdleHandlerActivateItemPassword", 0.1, True);
	EndIf;
	
	If Context.Notification <> Undefined Then
		RunCallback(Context.Notification, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure IdleHandlerActivateItemPassword()
	
	CurrentItem = Items.Password;
	
EndProcedure

&AtServer
Procedure WriteCertificateToCatalogSaaS()
	
	BuiltinCryptoprovider = DigitalSignatureInternal.BuiltinCryptoprovider();
	CertificateEnterPasswordInElectronicSignatureProgram = False;
	
	DigitalSignatureInternal.WriteCertificateToCatalog(ThisObject, BuiltinCryptoprovider, False);
	
EndProcedure

&AtServer
Procedure WriteTheCertificateToTheCloudSignatureDirectory(Account)
	
	CertificateEnterPasswordInElectronicSignatureProgram = False;
	
	DigitalSignatureInternal.WriteCertificateToCatalog(ThisObject, Account, False);
	
EndProcedure

&AtClient
Procedure OnCloseIndividualChoiceForm(Value, Var_Parameters) Export

	If Value = Undefined Then
		Return;
	EndIf;
	
	CertificateIndividual = Value;

EndProcedure

&AtServer
Procedure SetVisibilityForCertificateAdditionCommands()
	
	If Not DigitalSignatureInternal.HasRightToAddCertificatesToCatalog()
		Or Not Parameters.ShouldDisplayAddCommands Or Common.IsMobileClient() Then
		
		Items.AddForSigningAndEncryptionFromFiles.Visible = False;
		Items.AddCertificateIssueRequest.Visible = False;
		
		Return;
		
	EndIf;
	
	Items.AddCertificateIssueRequest.Visible = CertificateIssueRequestAvailable;
	
EndProcedure

&AtClient
Async Procedure AfterAddCertificate(Result, Context) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	AddressOfCertificate = Result.Certificate;
	
	If IsBlankString(AddressOfCertificate) Then
		FormParameters = New Structure;
		FormParameters.Insert("WarningTitle", NStr("vi = 'Không thể cài đặt chứng thư';
													|ru = 'Не удалось установить сертификат';
													|en = 'Cannot install the certificate.'; fa = 'Cannot install the certificate.';
													|it = 'Не удалось установить сертификат';
													|pl = 'Cannot install the certificate.';
													|tr = 'Sertifika kurulamadı'"));
		FormParameters.Insert("ErrorTextClient", Result.Message);
		DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(FormParameters, ThisObject);
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification",          Undefined);
	Context.Insert("SavedProperties", Undefined);
	
	CertificateData = GetFromTempStorage(AddressOfCertificate);
	CryptoCertificate = New CryptoCertificate;
	Await CryptoCertificate.InitializeAsync(CertificateData);
	
	CertificateProperties = DigitalSignatureClient.CertificateProperties(CryptoCertificate);
	
	ThumbprintOfCertificate = CertificateProperties.Thumbprint;
	
	DigitalSignatureInternalClientServer.FillCertificateDataDetails(DetailsOfCertificateData, CertificateProperties);
	
	Context.SavedProperties = SavedCertificateProperties(CertificateProperties.Thumbprint,
		AddressOfCertificate, CertificateAttributeParameters);
			
	If ValueIsFilled(FilterByCompany) Then
		Context.SavedProperties.Insert("Organization", FilterByCompany);
	EndIf;
	
	GoToCurrentCertificateChoiceAfterFillCertificateProperties(Context);
	
EndProcedure

&AtServerNoContext
Function AddedCertificateProperties(Val Certificate)
	
	Result = New Structure;
	Result.Insert("IsRequest", False);
	Result.Insert("AtClient", True);
	Result.Insert("Isinthedirectory", True);
	Result.Insert("Thumbprint", Common.ObjectAttributeValue(Certificate, "Thumbprint"));
	
	Return Result;
	
EndFunction

#EndRegion
