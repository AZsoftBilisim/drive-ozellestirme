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
Var IsPasswordsCertificatesChanged;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MailingRecipientType        = Parameters.MailingRecipientType;
	RecipientsEmailAddressKind = Parameters.RecipientsEmailAddressKind;
	MailingDescription          = Parameters.MailingDescription;
	Ref = Parameters.Ref;
	
	FillRecipientsTypeInfo(Cancel);
	PrepareItemVisibility(Parameters.Archive);
	PopulateDefaultFilters();
	
	If IsTempStorageURL(Parameters.RecipientsAddress) Then
		PopulateDistributionRecipientsWithEmailAddress(GetFromTempStorage(Parameters.RecipientsAddress));
		DeleteFromTempStorage(Parameters.RecipientsAddress); 
	EndIf;

	TableRecipients = FormAttributeToValue("Recipients");
	ValueToFormAttribute(TableRecipients, "RecipientsNoFilters");
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
		Items.WriteAndClose.Representation = ButtonRepresentation.Picture;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	IsPasswordsCertificatesChanged = False;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If IsPasswordsCertificatesChanged Then
		Cancel = True;
		QueryText = StringFunctionsClient.FormattedString(NStr(
		"vi = 'Đối với người nhận khi gửi hàng loạt, đã thay đổi mật khẩu và chứng thư để mã hóa. Lưu các thay đổi?
		|
		|• Nhấn <b>Có</b>, để lưu các thay đổi.
		|• Nhấn <b>Không</b>, để đóng mà không lưu.';
		|ru = 'Для получателей рассылки были изменены пароли и сертификаты для шифрования. Сохранить изменения?
		|
		|• Нажмите <b>Да</b>, чтобы  сохранить изменения.
		|• Нажмите <b>Нет</b>, чтобы закрыть без сохранения.';
		|en = 'Passwords and encryption certificates have been changed for report distribution recipients. Do you want to save the changes?
		|
		|• Click <b>Yes</b> to save the changes.
		|• Click<b>No</b> to close the dialog box without saving the changes.'; fa = 'Passwords and encryption certificates have been changed for report distribution recipients. Do you want to save the changes?
		|
		|• Click <b>Yes</b> to save the changes.
		|• Click<b>No</b> to close the dialog box without saving the changes.';
		|it = 'Для получателей рассылки были изменены пароли и сертификаты для шифрования. Сохранить изменения?
		|
		|• Нажмите <b>Да</b>, чтобы  сохранить изменения.
		|• Нажмите <b>Нет</b>, чтобы закрыть без сохранения.';
		|pl = 'Passwords and encryption certificates have been changed for report distribution recipients. Do you want to save the changes?
		|
		|• Click <b>Yes</b> to save the changes.
		|• Click<b>No</b> to close the dialog box without saving the changes.';
		|tr = 'Dağıtım listesindeki kullanıcılar için şifreler ve şifreleme için sertifikalar değiştirildi. Değişiklikler kaydedilsin mi?
		|
		|• Değişikliklerin kaydedilmesi için <b>Evet</b> düğmesine basın.
		|• Kaydetmeden çıkmak için <b>Hayır</b> düğmesine basın.'"));

		ShowQueryBox(New CallbackDescription("ResponseSaveChangeCertificatesPasswords", ThisObject), QueryText,
			QuestionDialogMode.YesNoCancel, , DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseFilterPasswordSetOnChange(Item)
	SetFilters();
EndProcedure

&AtClient
Procedure FilterPasswordIsSetOnChange(Item)
	SetFilters();
EndProcedure

&AtClient
Procedure UseFilterPasswordChangedOnChange(Item)
	SetFilters();
EndProcedure

&AtClient
Procedure FilterPasswordChangedOnChange(Item)
	SetFilters();
EndProcedure

&AtClient
Procedure UseFilterCertificateSpecifiedOnChange(Item)
	SetFilters();
EndProcedure

&AtClient
Procedure FilterCertificateSpecifiedOnChange(Item)
	SetFilters();
EndProcedure

&AtClient
Procedure UseFilterCertificateChangedOnChange(Item)
	SetFilters();
EndProcedure

&AtClient
Procedure FilterIsCertificateChangedOnChange(Item)
	SetFilters();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRecipients

&AtClient
Procedure RecipientsBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure RecipientsSelection(Item, RowSelected, Field, StandardProcessing)
	
	Recipient = Items.Recipients.CurrentData.Recipient;
	
	If Item.CurrentItem = Items.RecipientsRecipient Or Item.CurrentItem = Items.RecipientsEmail Then
		If ValueIsFilled(Recipient) Then
			ShowValue( , Recipient);
		EndIf;
	EndIf;
		
EndProcedure

&AtClient
Procedure RecipientsBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure RecipientsArchivePasswordOnChange(Item)
	
	RowRecipients = Items.Recipients.CurrentData;
	RowRecipients.PasswordChanged = True;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Recipient", RowRecipients.Recipient);
	
	StringsRecipientsNoFilter = RecipientsNoFilters.FindRows(FilterParameters);
	If StringsRecipientsNoFilter.Count() > 0 Then
		StringsRecipientsNoFilter[0].ArchivePassword = RowRecipients.ArchivePassword;
		StringsRecipientsNoFilter[0].PasswordChanged = True;
	EndIf;
	
	IsPasswordsCertificatesChanged = True;
		
	UpdateFilters();	
		
EndProcedure

&AtClient
Procedure Attachable_RecipientsEncryptionCertificateOnChange(Item)
	
	RowRecipients = Items.Recipients.CurrentData;
	RowRecipients.IsCertificateChanged = True;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Recipient", RowRecipients.Recipient);
	
	StringsRecipientsNoFilter = RecipientsNoFilters.FindRows(FilterParameters);
	If StringsRecipientsNoFilter.Count() > 0 Then
		StringRecipientsNoFilter = StringsRecipientsNoFilter[0]; 
		StringRecipientsNoFilter["CertificateToEncrypt"] = RowRecipients["CertificateToEncrypt"];
		StringRecipientsNoFilter.IsCertificateChanged = True;
	EndIf;
	
	IsPasswordsCertificatesChanged = True;
	
	UpdateFilters();
		
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PopulateCertificates(Command)

	QueryText = StringFunctionsClient.FormattedString(NStr(
		"vi = 'Đối với người nhận khi gửi hàng loạt, sẽ điền chứng thư để mã hóa, nếu họ đã tồn tại đối với cá nhân tương ứng.
		|
		|• Nhấn <b>Có</b> để điền lại chứng thư, ngay cả khi chúng đã điền+.
		|• Nhấn <b>Không</b> để chỉ điền các chứng thư còn thiếu.';
		|ru = 'Для получателей рассылки будут заполнены сертификаты для шифрования, если они существуют для соответствующего физического лица.
		|
		|• Нажмите <b>Да</b>, чтобы  перезаполнить сертификаты, даже если они уже были указаны.
		|• Нажмите <b>Нет</b>, чтобы заполнить только отсутствующие сертификаты.';
		|en = 'Encryption certificates will be filled for report distribution recipients if they are available for the respective individual.
		|
		|• Click <b>Yes</b> to re-fill certificates even if they are already specified.
		|• Click <b>No</b> to fill only missing certificates.'; fa = 'Encryption certificates will be filled for report distribution recipients if they are available for the respective individual.
		|
		|• Click <b>Yes</b> to re-fill certificates even if they are already specified.
		|• Click <b>No</b> to fill only missing certificates.';
		|it = 'Для получателей рассылки будут заполнены сертификаты для шифрования, если они существуют для соответствующего физического лица.
		|
		|• Нажмите <b>Да</b>, чтобы  перезаполнить сертификаты, даже если они уже были указаны.
		|• Нажмите <b>Нет</b>, чтобы заполнить только отсутствующие сертификаты.';
		|pl = 'Encryption certificates will be filled for report distribution recipients if they are available for the respective individual.
		|
		|• Click <b>Yes</b> to re-fill certificates even if they are already specified.
		|• Click <b>No</b> to fill only missing certificates.';
		|tr = 'İlgili gerçek kişi için mevcut ise, dağıtım listesindeki kullanıcılar için şifreleme için sertifikalar doldurulacaktır. 
		|
		|• Zaten belirtilmiş olsalar bile sertifikaları tekrar doldurmak için <b>Evet</b> düğmesine basın.
		|• Sadece mevcut olmayan sertifikaları doldurmak için <b>Hayır</b> düğmesine basın.'"));

	ShowQueryBox(
			New CallbackDescription("BeforePopulateCertificates", ThisObject), QueryText,
		QuestionDialogMode.YesNoCancel, , DialogReturnCode.No);

EndProcedure

&AtClient
Procedure SetPasswords(Command)

	QueryText = StringFunctionsClient.FormattedString(NStr(
		"vi = 'Đối với người nhận khi gửi hàng loạt sẽ đặt mật khẩu.
		|
		|• Nhấn <b>Có</b> để đặt mật khẩu mới, ngay cả khi mật khẩu đã đặt.
		|• Nhấn <b>Không</b> để đặt mật khẩu, chỉ khi không có mật khẩu.';
		|ru = 'Для получателей рассылки будут установлены пароли.
		|
		|• Нажмите <b>Да</b>, чтобы  устанавливать новые пароли, даже если они уже были установлены.
		|• Нажмите <b>Нет</b>, чтобы установить пароли,  только при их отсутствии.';
		|en = 'Passwords will be set for report distribution recipients.
		|
		|• Click <b>Yes</b> to set new passwords even if they are already set.
		|• Click <b>No</b> to set passwords only if no passwords are set.'; fa = 'Passwords will be set for report distribution recipients.
		|
		|• Click <b>Yes</b> to set new passwords even if they are already set.
		|• Click <b>No</b> to set passwords only if no passwords are set.';
		|it = 'Для получателей рассылки будут установлены пароли.
		|
		|• Нажмите <b>Да</b>, чтобы  устанавливать новые пароли, даже если они уже были установлены.
		|• Нажмите <b>Нет</b>, чтобы установить пароли,  только при их отсутствии.';
		|pl = 'Passwords will be set for report distribution recipients.
		|
		|• Click <b>Yes</b> to set new passwords even if they are already set.
		|• Click <b>No</b> to set passwords only if no passwords are set.';
		|tr = 'Bülten alıcıları için parolalar oluşturulacaktır.
		|
		|• Zaten oluşturulmuş olsalar bile yeni parolalar oluşturmak için <b>Evet</b>düğmesine basın.
		|• Sadece mevcut olmayan parolaları oluşturmak için<b>Hayır</b> düğmesine basın.'"));

	ShowQueryBox(
			New CallbackDescription("BeforeSetPasswords", ThisObject), QueryText,
		QuestionDialogMode.YesNoCancel, , DialogReturnCode.No);

EndProcedure

&AtClient
Procedure TogglePasswordsMasking(Command)
	
	If Items.RecipientsArchivePassword.Visible Then
		Items.RecipientsArchivePassword.Visible = False;
		Items.RecipientsArchivePassword2.Visible = True;
		Items.TogglePasswordsMasking.Picture = PictureLib.CharsBeingTypedHidden;
	Else
		Items.RecipientsArchivePassword.Visible = True;
		Items.RecipientsArchivePassword2.Visible = False;
		Items.TogglePasswordsMasking.Picture = PictureLib.CharsBeingTypedShown;
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintPasswordsList(Command)
	
	ArrayOfRecipients_ = New Array;
	For Each String In Recipients Do
		RecipientInfo = New Structure;
		RecipientInfo.Insert("Recipient", String.Recipient);
		RecipientInfo.Insert("Email", String.Email);
		RecipientInfo.Insert("ArchivePassword", String.ArchivePassword);
		ArrayOfRecipients_.Add(RecipientInfo);
	EndDo;

	PrintParameters = New Structure;
	PrintParameters.Insert("Recipients", ArrayOfRecipients_);
	PrintParameters.Insert("MailingRecipientType", MailingRecipientType);
	PrintParameters.Insert("MetadataObjectID", MetadataObjectID);
	PrintParameters.Insert("MailingDescription", MailingDescription);
	PrintParameters.Insert("Ref", Ref);
	
	CommandParameter = New Array;
	CommandParameter.Add(Ref);
	
	ModulePrintManagerClient = CommonClient.CommonModule("PrintManagementClient");
	ModulePrintManagerClient.ExecutePrintCommand("Catalog.ReportMailings", "ReportDistributionPasswords", 
		CommandParameter, ThisObject, PrintParameters);
	
EndProcedure

&AtClient
Procedure DeliverPasswordsViaSMS(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("RecipientsAddress", PutRecipientsInStorage());
	FormParameters.Insert("MailingRecipientType", MailingRecipientType);
	FormParameters.Insert("Ref", Ref);
	FormParameters.Insert("MailingDescription", MailingDescription);
	FormParameters.Insert("MetadataObjectID", MetadataObjectID);
	OpenForm("Catalog.ReportMailings.Form.PasswordDeliveryViaSMS", FormParameters, ThisObject, , , , ,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	WritePasswordsAndEncryptionCertificatesToSecureStorage();
	IsPasswordsCertificatesChanged = False;
	Close();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateFilters()
	
	If UseFilterPasswordSet Or UseFilterPasswordChanged Or UseFilterCertificateSpecified
		Or UseFilterCertificateChanged Then
		SetFilters();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforePopulateCertificates(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		PopulateRecipientsCertificatesAtServer(True);
		IsPasswordsCertificatesChanged = True;
	ElsIf Result = DialogReturnCode.No Then
		PopulateRecipientsCertificatesAtServer(False);
		IsPasswordsCertificatesChanged = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeSetPasswords(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		SetRecipientsPasswordsAtServer(True);
		IsPasswordsCertificatesChanged = True;
	ElsIf Result = DialogReturnCode.No Then
		SetRecipientsPasswordsAtServer(False);
		IsPasswordsCertificatesChanged = True;
	EndIf;
	
EndProcedure
	
&AtClient
Procedure ResponseSaveChangeCertificatesPasswords(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		WritePasswordsAndEncryptionCertificatesToSecureStorage();
		IsPasswordsCertificatesChanged = False;
	ElsIf Result = DialogReturnCode.No Then
		IsPasswordsCertificatesChanged = False;
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure PopulateRecipientsCertificatesAtServer(ShouldRepopulateCertificates)
	
	TableRecipients = FormAttributeToValue("Recipients");
	
	If Not ShouldRepopulateCertificates Then	
		ArrayOfRecipients_ = New Array;
		For Each RowRecipients In TableRecipients Do
			If Not ValueIsFilled(RowRecipients.CertificateToEncrypt) Then
				ArrayOfRecipients_.Add(RowRecipients.Recipient);
			EndIf;
		EndDo;
	Else
		// Clear up certificates.
		CertificatesEmptyRef = New (TableRecipients.Columns["CertificateToEncrypt"].ValueType.Types()[0]);
		For Each RowRecipients In Recipients Do
			If ValueIsFilled(RowRecipients.CertificateToEncrypt) Then
				RowRecipients.IsCertificateChanged = True;
				RowRecipients["CertificateToEncrypt"] = CertificatesEmptyRef;

				FilterParameters = New Structure;
				FilterParameters.Insert("Recipient", RowRecipients.Recipient);

				StringsRecipientsNoFilter = RecipientsNoFilters.FindRows(FilterParameters);
				If StringsRecipientsNoFilter.Count() > 0 Then
					StringRecipientsNoFilter = StringsRecipientsNoFilter[0];
					StringRecipientsNoFilter["CertificateToEncrypt"] = CertificatesEmptyRef;
					StringRecipientsNoFilter.IsCertificateChanged = True;
				EndIf;
			EndIf;
		EndDo;
		
		ArrayOfRecipients_ = TableRecipients.UnloadColumn("Recipient");
	EndIf;
	
	ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
	
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Users"));
	TypesArray.Add(Type("CatalogRef.UserGroups"));

	SelectionOfIndividuals = False;
	If MailingRecipientType = Metadata.DefinedTypes.Individual.Type Then
		Selection = ModuleDigitalSignatureInternal.CertificatesOfIndividuals(ArrayOfRecipients_);
		SelectionOfIndividuals = True;
	ElsIf MailingRecipientType = New TypeDescription(TypesArray) Then
		Selection = ModuleDigitalSignatureInternal.CertificatesOfIndividualsUsers(ArrayOfRecipients_);
	Else
		Return;
	EndIf;
	
	While Selection.Next() Do
		FilterParameters = New Structure;
		FilterParameters.Insert("Recipient", ?(SelectionOfIndividuals, Selection.Individual, Selection.User));
	
		StringsRecipientsNoFilter = RecipientsNoFilters.FindRows(FilterParameters);
		If StringsRecipientsNoFilter.Count() > 0 Then
			StringRecipientsNoFilter = StringsRecipientsNoFilter[0]; 
			StringRecipientsNoFilter["CertificateToEncrypt"] = Selection.Certificate;
			StringRecipientsNoFilter.IsCertificateChanged = True;
		EndIf;
	EndDo;
	
	SetFilters();

EndProcedure

&AtServer
Procedure SetRecipientsPasswordsAtServer(ShouldResetPasswords)
	
	PasswordProperties = Users.PasswordProperties();
	PasswordProperties.MinLength = 8;
	
	For Each RowRecipients In Recipients Do
		
		If Not ShouldResetPasswords And ValueIsFilled(RowRecipients.ArchivePassword) Then	
			Continue;	
		EndIf;
		
		RowRecipients.ArchivePassword = Users.CreatePassword(PasswordProperties);
		RowRecipients.PasswordChanged = True;
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Recipient", RowRecipients.Recipient);
		
		StringsRecipientsNoFilter = RecipientsNoFilters.FindRows(FilterParameters);
		If StringsRecipientsNoFilter.Count() > 0 Then
			FillPropertyValues(StringsRecipientsNoFilter[0], RowRecipients);
		EndIf;
	
	EndDo;
	
	SetFilters();
	
EndProcedure

&AtServer
Procedure SetFilters()

	TableRecipientsNoFilters = FormAttributeToValue("RecipientsNoFilters");

	Builder = New QueryBuilder;
	Builder.DataSource = New DataSourceDescription(TableRecipientsNoFilters);

	Filter = Builder.Filter;

	PasswordSet = Filter.Add("ArchivePassword");
	PasswordSet.ComparisonType	= ?(FilterPasswordIsSet, ComparisonType.NotEqual, ComparisonType.Equal);
	PasswordSet.Value		= "";
	PasswordSet.Use	= UseFilterPasswordSet;

	NewPassword = Filter.Add("PasswordChanged");
	NewPassword.ComparisonType	= ComparisonType.Equal;
	NewPassword.Value		= FilterPasswordChanged;
	NewPassword.Use	= UseFilterPasswordChanged;

	If ReportMailing.CanEncryptAttachments() Then
		CertificatePopulated = Filter.Add("CertificateToEncrypt");
		CertificatePopulated.ComparisonType	 = ?(FilterCertificateSpecified, ComparisonType.NotEqual, ComparisonType.Equal);
		CertificatePopulated.Value = New (TableRecipientsNoFilters.Columns["CertificateToEncrypt"].ValueType.Types()[0]);
		CertificatePopulated.Use = UseFilterCertificateSpecified;

		NewCertificate = Filter.Add("IsCertificateChanged");
		NewCertificate.ComparisonType	= ComparisonType.Equal;
		NewCertificate.Value		= FilterIsCertificateChanged;
		NewCertificate.Use	= UseFilterCertificateChanged;
	EndIf;
	
	Builder.Execute();
	ResultTable1 = 	Builder.Result.Unload();

	ValueToFormAttribute(ResultTable1, "Recipients");
	
EndProcedure

&AtServer
Procedure PopulateDistributionRecipientsWithEmailAddress(TableOfRecipients)
	
	RecipientsParameters = ReportMailingClientServer.RecipientsParameters();
	RecipientsParameters.Ref = Ref;
	RecipientsParameters.Recipients = TableOfRecipients;
	RecipientsParameters.Author = Undefined;
	RecipientsParameters.Personal = False;
	RecipientsParameters.MailingRecipientType = MetadataObjectID;
	RecipientsParameters.RecipientsEmailAddressKind = RecipientsEmailAddressKind;
	
	DistributionRecipientsList = ReportMailing.GenerateMailingRecipientsList(RecipientsParameters, Undefined);
	
	ArrayOfRecipients_ = New Array;
	For Each Recipient In DistributionRecipientsList Do
		RowRecipients = Recipients.Add();
		RowRecipients.Recipient = Recipient.Key;
		ArrayOfRecipients_.Add(Recipient.Key);
		RowRecipients.Email = Recipient.Value;
	EndDo;
	
	PopulateArchivePasswordsAndEncryptionCertificates(ArrayOfRecipients_);
	
EndProcedure

&AtServer
Procedure FillRecipientsTypeInfo(Cancel)
	RecipientsTypesTable = ReportMailingCached.RecipientsTypesTable();
	FoundItems = RecipientsTypesTable.FindRows(New Structure("RecipientsType", MailingRecipientType));
	If FoundItems.Count() = 1 Then
		RecipientRow = FoundItems[0];
		MetadataObjectID = RecipientRow.MetadataObjectID;
	Else
		Cancel = True;
	EndIf;
EndProcedure

&AtServer
Procedure PopulateArchivePasswordsAndEncryptionCertificates(RecipientsList)
	
	SetPrivilegedMode(True);
	RecipientsPasswords = Common.ReadOwnersDataFromSecureStorage(RecipientsList, "ArchivePassword");
	SetPrivilegedMode(False);
	
	For Each Recipient In RecipientsPasswords Do
		RecipientLines_ = Recipients.FindRows(New Structure("Recipient", Recipient.Key));
		If RecipientLines_.Count() > 0 Then
			RecipientLines_[0].ArchivePassword = Recipient.Value;
		EndIf;
	EndDo;
	
	If ReportMailing.CanEncryptAttachments() Then
		RecipientsCertificates = ReportMailing.GetEncryptionCertificatesForDistributionRecipients(RecipientsList);
		For Each RowRecipients In RecipientsCertificates Do
			RecipientLines_ = Recipients.FindRows(New Structure("Recipient", RowRecipients.BulkEmailRecipient));
			If RecipientLines_.Count() > 0 Then
				FillPropertyValues(RecipientLines_[0], RowRecipients);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure WritePasswordsAndEncryptionCertificatesToSecureStorage()
	
	CanEncryptAttachments = ReportMailing.CanEncryptAttachments();
	
	For Each String In RecipientsNoFilters Do
		If String.PasswordChanged Then
			SetPrivilegedMode(True);
			Common.WriteDataToSecureStorage(String.Recipient, String.ArchivePassword, "ArchivePassword");
			SetPrivilegedMode(False);
		EndIf;
		If CanEncryptAttachments And String.IsCertificateChanged Then
			InformationRegisters.CertificatesOfReportDistributionRecipients.SaveCertificateForDistributionRecipient(
				String.Recipient, String.CertificateToEncrypt);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure PrepareItemVisibility(Archive)
	
	AutoTitle = False;
	
	If ReportMailing.CanEncryptAttachments() Then
		AttributesToAddArray = New Array;
		AttributesToAddArray.Add(New FormAttribute("CertificateToEncrypt",
			New TypeDescription("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates"), "Recipients", NStr(
			"vi = 'Chứng thư để mã hóa';
			|ru = 'Сертификат для шифрования';
			|en = 'Encryption certificate'; fa = 'گواهی رمزگذاری';
			|it = 'Сертификат для шифрования';
			|pl = 'Encryption certificate';
			|tr = 'Şifreleme için sertifika'")));
		AttributesToAddArray.Add(New FormAttribute("CertificateToEncrypt",
			New TypeDescription("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates"), "RecipientsNoFilters", NStr(
			"vi = 'Chứng thư để mã hóa';
			|ru = 'Сертификат для шифрования';
			|en = 'Encryption certificate'; fa = 'گواهی رمزگذاری';
			|it = 'Сертификат для шифрования';
			|pl = 'Encryption certificate';
			|tr = 'Şifreleme için sertifika'")));

		ChangeAttributes(AttributesToAddArray);

		Item = Items.Add("RecipientsEncryptionCertificate", Type("FormField"), Items.Recipients);
		Item.Title = NStr("vi = 'Chứng thư để mã hóa';
							|ru = 'Сертификат для шифрования';
							|en = 'Encryption certificate'; fa = 'گواهی رمزگذاری';
							|it = 'Сертификат для шифрования';
							|pl = 'Encryption certificate';
							|tr = 'Şifreleme için sertifika'");
		Item.DataPath = "Recipients.CertificateToEncrypt";
		Item.Type = FormFieldType.InputField;
		Item.EditMode = ColumnEditMode.EnterOnInput;
		Item.Width = 30;
		Item.HeaderPicture = PictureLib.Change;
		Item.BackColor = StyleColors.MasterFieldBackground;
		Item.SetAction("OnChange", "Attachable_RecipientsEncryptionCertificateOnChange");
		
		TypesArray = New Array;
		TypesArray.Add(Type("CatalogRef.Users"));
		TypesArray.Add(Type("CatalogRef.UserGroups"));

		IndividualsTypesDetails = Metadata.DefinedTypes.Individual.Type;
		If IndividualsTypesDetails.Types()[0] = Type("String") Or (MailingRecipientType
			<> IndividualsTypesDetails And MailingRecipientType <> New TypeDescription(TypesArray)) Then
			Items.PopulateCertificates.Visible = False;
		EndIf;	
	
		Title = ?(Archive, NStr("vi = 'Mật khẩu và mã hóa để gửi báo cáo hàng loạt';
								|ru = 'Пароли и шифрование для рассылки отчетов';
								|en = 'Passwords and encryption for report distribution'; fa = 'Passwords and encryption for report distribution';
								|it = 'Пароли и шифрование для рассылки отчетов';
								|pl = 'Passwords and encryption for report distribution';
								|tr = 'Rapor dağıtımları için şifreler ve şifreleme'"), NStr(
			"vi = 'Mã hóa để gửi báo cáo hàng loạt';
			|ru = 'Шифрование для рассылки отчетов';
			|en = 'Encryption for report distribution'; fa = 'Encryption for report distribution';
			|it = 'Шифрование для рассылки отчетов';
			|pl = 'Encryption for report distribution';
			|tr = 'Rapor dağıtımları için şifreleme'"));	
		
	Else
		Items.GroupCertificateFilters.Visible = False;
		Items.PopulateCertificates.Visible   = False;
		Title = NStr("vi = 'Mật khẩu để gửi báo cáo hàng loạt';
					|ru = 'Пароли для рассылки отчетов';
					|en = 'Passwords for report distribution'; fa = 'Passwords for report distribution';
					|it = 'Пароли для рассылки отчетов';
					|pl = 'Passwords for report distribution';
					|tr = 'Rapor dağıtımı için şifreler'");
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.Print") Then
		Items.PrintPasswordsList.Visible = False;	
	EndIf;
	
	If Not Common.SubsystemExists("StandardSubsystems.SendSMSMessage") Then
		Items.DeliverPasswordsViaSMS.Visible    = False;
	EndIf;
	
	If Not Archive Then
		Items.GroupPasswordFilters.Visible      = False;
		Items.SetPasswords.Visible        = False;
		Items.PrintPasswordsList.Visible     = False;
		Items.DeliverPasswordsViaSMS.Visible    = False;
		Items.TogglePasswordsMasking.Visible    = False;
		Items.RecipientsArchivePassword.Visible  = False;
	ElsIf Not AccessRight("Update", Metadata.Catalogs.ReportMailings) Then
		Items.TogglePasswordsMasking.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure PopulateDefaultFilters()
	
	FilterPasswordIsSet = True;
	FilterPasswordChanged = True;
	FilterCertificateSpecified = True;
	FilterIsCertificateChanged = True;
	
EndProcedure

&AtServer
Function PutRecipientsInStorage()
	Return PutToTempStorage(Recipients.Unload( , "Recipient, ArchivePassword"), UUID);
EndFunction

#EndRegion
