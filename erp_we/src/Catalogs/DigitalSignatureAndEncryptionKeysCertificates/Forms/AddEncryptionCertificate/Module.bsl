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
	
	DigitalSignatureInternal.SetVisibilityOfRefToAppsTroubleshootingGuide(Items.Instruction);
	
	HaveRightToAddInDirectory = DigitalSignatureInternal.HasRightToAddCertificatesToCatalog();
	
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
	
	CertificateAttributeParameters =
		DigitalSignatureInternal.NewParametersForCertificateDetails();
	
	If ValueIsFilled(Parameters.Organization) Then
		CertificateAttributeParameters.Insert("Organization", Parameters.Organization);
	EndIf;
	
	If ValueIsFilled(Parameters.CertificateDataAddress) Then
		CertificateData = GetFromTempStorage(Parameters.CertificateDataAddress);
		
		CryptoCertificate = DigitalSignatureInternal.CertificateFromBinaryData(CertificateData);
		If CryptoCertificate = Undefined Then
			Cancel = True;
			Return;
		EndIf;
		
		CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
		
		ShowCertificatePropertiesAdjustmentPage(ThisObject,
			CryptoCertificate,
			CryptoCertificate.Unload(),
			CertificateProperties);
		
		Items.Back.Visible = False;
	Else
		If DigitalSignature.GenerateDigitalSignaturesAtServer() Then
			Items.CertificatesGroup.Title =
				NStr("vi = 'Chứng thư riêng trên máy tính và Server';
					|ru = 'Личные сертификаты на компьютере и сервере';
					|en = 'Personal certificates on computer and on server'; fa = 'Personal certificates on computer and on server';
					|it = 'Certificati personali sul computer e sul server';
					|pl = 'Certyfikaty prywatne na komputerze i serwerze';
					|tr = 'Bilgisayar ve sunucudaki kişisel sertifikalar'");
		EndIf;
		
		ErrorOnGetCertificatesAtClient = Parameters.ErrorOnGetCertificatesAtClient;
		UpdateCertificatesListAtServer(Parameters.CertificatesPropertiesAtClient);
	EndIf;
	
	If Not DigitalSignature.CommonSettings().IsCompanyUsed Then
		Items.CertificateCompany.Visible = False;
	Else
		CompanyTypeToDefineConfigured = True;
	EndIf;
	
	Items.GroupInidividual.Visible = DigitalSignature.CommonSettings().IndividualUsed;
	
	Items.CertificateUser1.ToolTip =
		Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.Attributes.User.Tooltip;
	
	Items.CertificateCompany.ToolTip =
		Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.Attributes.Organization.Tooltip;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(Certificate) Then
		Cancel = True;
		Return;
	EndIf;
	
	If ValueIsFilled(AddressOfCertificate) Then
		Return;
	EndIf;
	
	If Certificates.Count() = 0
		And Not Items.CertificatesUnavailableAtClientGroup.Visible
		And Not Items.CertificatesUnavailableAtServerGroup.Visible Then
		WarningTextOnOpen =
			NStr("ru = 'Нет доступных сертификатов для добавления. Возможно, отсутствуют права на добавление сертификатов, обратитесь к администратору.';
				|vi = 'No certificates are available. You may have insufficient permission to add certificates; contact your administrator.';
				|en = 'No certificates are available. You may have insufficient permission to add certificates; contact your administrator.'; fa = 'No certificates are available. You may have insufficient permission to add certificates; contact your administrator.';
				|it = 'No certificates are available. You may have insufficient permission to add certificates; contact your administrator.';
				|pl = 'No certificates are available. You may have insufficient permission to add certificates; contact your administrator.';
				|tr = 'Eklemek için uygun sertifika bulunamadı. Sertifika ekleme yetkiniz olmayabilir, yöneticinize başvurun.'");
		Cancel = True;
	EndIf;
		
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionApplications")
	 Or Upper(EventName) = Upper("Write_PathsToDigitalSignatureAndEncryptionApplicationsOnLinuxServers") Then
		
		RefreshReusableValues();
		If Items.Back.Visible Then
			UpdateCertificatesList();
		EndIf;
		Return;
	EndIf;
	
	If Upper(EventName) = Upper("Write_DigitalSignatureAndEncryptionKeysCertificates") Then
		UpdateCertificatesList();
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

#EndRegion

#Region FormTableItemsEventHandlersCertificates

&AtClient
Procedure CertificatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	Next(Undefined);
	
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
	
	DigitalSignatureClient.OpenCertificate(CurrentData.Thumbprint, Not CurrentData.IsRequest);
	
EndProcedure

&AtClient
Procedure Next(Command)
	
	If Items.Certificates.CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn chứng thư mà cần bổ sung.';
								|ru = 'Выделите сертификаты, которые требуется добавить.';
								|en = 'Select certificates that you want to add.'; fa = 'Select certificates that you want to add.';
								|it = 'Selezionare i certificati da aggiungere.';
								|pl = 'Wprowadź certyfikaty, które należy dodać.';
								|tr = 'Eklenmesi gereken sertifikaları seçin.'"));
		Return;
	EndIf;
	
	CurrentData = Items.Certificates.CurrentData;
	
	If CurrentData.IsRequest Then
		ShowMessageBox(,
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
			           |Düzenleme başvurusunu açın ve gereken adımları yerine getirin.'"));
		UpdateCertificatesList();
		Return;
	EndIf;
	
	If Not HaveRightToAddInDirectory And Not CurrentData.Isinthedirectory Then
		Raise(NStr("ru = 'Отсутствуют права на добавление сертификатов в справочник. Обратитесь к администратору.';
					|vi = 'Insufficient permission to add certificates; contact your administrator.';
					|en = 'Insufficient permission to add certificates; contact your administrator.'; fa = 'Insufficient permission to add certificates; contact your administrator.';
					|it = 'Insufficient permission to add certificates; contact your administrator.';
					|pl = 'Insufficient permission to add certificates; contact your administrator.';
					|tr = 'Kılavuza sertifika ekleme yetkisi bulunmuyor. Yöneticinize başvurun.'"),
			ErrorCategory.AccessViolation);
	EndIf;
	
	Items.Next.Enabled = False;
	
	Account = Undefined;
	If DigitalSignatureInternalClientServer.PlacementOfTheCertificate(CurrentData.LocationType) = "CloudSignature" Then
		TheDSSCryptographyServiceModuleClientServer = CommonClient.CommonModule("DSSCryptographyServiceClientServer");
		TheDSSCryptographyServiceModuleInternalServerCall = CommonClient.CommonModule("DSSCryptographyServiceInternalServerCall");
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		
		CertificateThumbprint = TheDSSCryptographyServiceModuleClientServer.TransformFingerprint(CurrentData.Thumbprint);
		UserSettings = TheDSSCryptographyServiceModuleInternalServerCall.GetUserSettingsByCertificate(CertificateThumbprint);
		Account = UserSettings.Ref;

		OperationParametersList = New Structure;
		OperationParametersList.Insert("GetBinaryData", True);

		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Thumbprint", CertificateThumbprint);
		
		TheDSSCryptographyServiceModuleClient.FindCertificate(New CallbackDescription(
			"NextAfterSearchingForTheCertificateTheCloudSignature", ThisObject, Account), TheStructureOfTheSearch, OperationParametersList);
	
	ElsIf DigitalSignatureInternalClient.UseDigitalSignatureSaaS() And CurrentData.InCloudService Then
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Thumbprint", Base64Value(CurrentData.Thumbprint));
		ModuleCertificateStoreClient = CommonClient.CommonModule("CertificatesStorageClient");
		ModuleCertificateStoreClient.FindCertificate(New CallbackDescription(
			"NextAfterCertificateSearchInCloudService", ThisObject), TheStructureOfTheSearch);
	Else
		DigitalSignatureInternalClient.GetCertificateByThumbprint(New CallbackDescription(
			"NextAfterCertificateSearch", ThisObject), CurrentData.Thumbprint, False, Undefined);
	EndIf;
	
EndProcedure

// Continues the Next procedure.
&AtClient
Procedure NextAfterCertificateSearch(Result, Context) Export
	
	If TypeOf(Result) = Type("CryptoCertificate") Then
		Result.BeginUnloading(New CallbackDescription(
			"NextAfterCertificateExport", ThisObject, Result));
		Return;
	EndIf;
	
	Context = New Structure;
	
	If Result.Property("CertificateNotFound") Then
		Context.Insert("ErrorDescription", NStr("vi = 'Chứng chỉ không được cài đặt trên máy tính (có thể bị xóa).';
												|ru = 'Сертификат не установлен на компьютере (возможно удален).';
												|en = 'The certificate is not installed or was deleted from your computer.'; fa = 'The certificate is not installed or was deleted from your computer.';
												|it = 'Certificato non installato nel computer (è possibile sia stato eliminato).';
												|pl = 'Certyfikat nie został zainstalowany na komputerze (mógł być usunięty).';
												|tr = 'Sertifika bilgisayarda kurulu değil (silinmiş olabilir).'"));
	Else
		Context.Insert("ErrorDescription", Result.ErrorDescription);
	EndIf;
	
	UpdateCertificatesList(New CallbackDescription(
		"NextAfterCertificatesListUpdate", ThisObject, Context));
	
EndProcedure

// Continues the Next procedure.
&AtClient
Procedure NextAfterSearchingForTheCertificateTheCloudSignature(Result, Context) Export
	
	If Not Result.Completed2 Then
		Context = New Structure;
		Context.Insert("ErrorDescription", Result.Error);
		UpdateCertificatesList(New CallbackDescription(
			"NextAfterCertificatesListUpdate", ThisObject, Context));
		Return;
	EndIf;
		
	If Not ValueIsFilled(Result.CertificateData) Then
		Context = New Structure;
		Context.Insert("ErrorDescription", NStr("vi = 'Không tồn tại chứng thư trong dịch vụ (có thể là đã bị xóa).';
												|ru = 'Сертификат отсутствует в сервисе (возможно удален).';
												|en = 'The certificate does not exist in the service. It might have been deleted.'; fa = 'The certificate does not exist in the service. It might have been deleted.';
												|it = 'Certificato assente nel servizio (forse eliminato).';
												|pl = 'Brak certyfikatu w usłudze (mógł być usunięty).';
												|tr = 'Hizmette sertifika eksik (silinmiş olabilir).'"));
		UpdateCertificatesList(New CallbackDescription(
			"NextAfterCertificatesListUpdate", ThisObject, Context));
		Return;
	EndIf;
		
	NextAfterCertificateExport(Result.CertificateData.Certificate, Result.CertificateData);
	
EndProcedure

// Continues the Next procedure.
&AtClient
Async Procedure NextAfterCertificateExport(ExportedData, CryptoCertificate) Export
	
	ShowCertificatePropertiesAdjustmentPage(ThisObject,
		CryptoCertificate,
		ExportedData,
		Await DigitalSignatureInternalClient.CertificateProperties(CryptoCertificate));
	
EndProcedure

// Continues the Next procedure.
&AtClient
Procedure NextAfterCertificatesListUpdate(Result, Context) Export
	
	ShowMessageBox(, Context.ErrorDescription);
	Items.Next.Enabled = True;
	
EndProcedure

// Continues the Next procedure.
//
// Parameters:
//   Result - Structure:
//   * ErrorDescription - Structure:
//   ** LongDesc - String
//   Context - Structure
//
&AtClient
Procedure NextAfterCertificateSearchInCloudService(Result, Context) Export
	
	If Not Result.Completed2 Then
		Context = New Structure;
		Context.Insert("ErrorDescription", Result.ErrorDescription.LongDesc);
		UpdateCertificatesList(New CallbackDescription(
			"NextAfterCertificatesListUpdate", ThisObject, Context));
		Return;
	EndIf;
		
	If Not ValueIsFilled(Result.Certificate) Then
		Context = New Structure;
		Context.Insert("ErrorDescription", NStr("vi = 'Không tồn tại chứng thư trong dịch vụ (có thể là đã bị xóa).';
												|ru = 'Сертификат отсутствует в сервисе (возможно удален).';
												|en = 'The certificate does not exist in the service. It might have been deleted.'; fa = 'The certificate does not exist in the service. It might have been deleted.';
												|it = 'Certificato assente nel servizio (forse eliminato).';
												|pl = 'Brak certyfikatu w usłudze (mógł być usunięty).';
												|tr = 'Hizmette sertifika eksik (silinmiş olabilir).'"));
		UpdateCertificatesList(New CallbackDescription(
			"NextAfterCertificatesListUpdate", ThisObject, Context));
		Return;
	EndIf;
		
	NextAfterCertificateExport(Result.Certificate.Certificate, Result.Certificate);
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	Items.Pages.CurrentPage = Items.CertificateSelectionPage;
	Items.Next.DefaultButton = True;
	
	UpdateCertificatesList();
	
EndProcedure

&AtClient
Procedure Add(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	AdditionalParameters = DigitalSignatureInternalClient.ParametersNotificationWhenWritingCertificate();
	If Not ValueIsFilled(Certificate) Then
		AdditionalParameters.IsNew = True;
	EndIf;
	
	WriteCertificateToCatalog();
	
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

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure ShowCertificatePropertiesAdjustmentPage(Form, CryptoCertificate, CertificateData, CertificateProperties)
	
	Items = Form.Items;
	
	Form.AddressOfCertificate = PutToTempStorage(CertificateData, Form.UUID);
	
	Form.ThumbprintOfCertificate = Base64String(CryptoCertificate.Thumbprint);
	
	DigitalSignatureInternalClientServer.FillCertificateDataDetails(
		Form.DetailsOfCertificateData, CertificateProperties);
	
	CertificateAttributeParameters = Form.CertificateAttributeParameters; // See DigitalSignatureInternal.NewParametersForCertificateDetails
	SavedProperties = SavedCertificateProperties(
		Form.ThumbprintOfCertificate,
		Form.AddressOfCertificate,
		CertificateAttributeParameters);
	
	If CertificateAttributeParameters.Property("Description") Then
		CertificateDescription = CertificateAttributeParameters.Description; 
		If CertificateDescription.ReadOnly Then
			Items.DescriptionCertificate.ReadOnly = True;
		EndIf;
	EndIf;
	
	If Form.CompanyTypeToDefineConfigured Then
		If CertificateAttributeParameters.Property("Organization") Then
			If Not CertificateAttributeParameters.Organization.Visible Then
				Items.CertificateCompany.Visible = False;
			ElsIf CertificateAttributeParameters.Organization.ReadOnly Then
				Items.CertificateCompany.ReadOnly = True;
			EndIf;
		EndIf;
	EndIf;
	
	Form.Certificate             = SavedProperties.Ref;
	Form.DescriptionCertificate = SavedProperties.Description;
	Form.CertificateUser1 = SavedProperties.User;
	Form.CertificateCompany  = SavedProperties.Organization;
	Form.CertificateIndividual = SavedProperties.Individual;
	
	Items.Pages.CurrentPage   = Items.PromptForCertificatePropertiesPage;
	Items.Add.DefaultButton = True;
	Items.Next.Enabled          = True;
	
	String = ?(ValueIsFilled(Form.Certificate), NStr("vi = 'Cập nhật';
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
	If Items.Add.Title <> String Then
		Items.Add.Title = String;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function SavedCertificateProperties(Val Thumbprint, Address, AttributesParameters)
	
	Return DigitalSignatureInternal.SavedCertificateProperties(Thumbprint, Address, AttributesParameters, True);
	
EndFunction

&AtClient
Procedure UpdateCertificatesList(Notification = Undefined)
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	
	DigitalSignatureInternalClient.GetCertificatesPropertiesAtClient(New CallbackDescription(
		"UpdateCertificatesListContinued", ThisObject, Context), False, ShowAll);
	
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
	
	DigitalSignatureInternal.UpdateCertificatesList(Certificates, CertificatesPropertiesAtClient,
		True, False, ErrorGettingCertificatesAtServer, ShowAll);
	
	If HaveRightToAddInDirectory Then
		Certificates.Sort("IsRequest Asc, Presentation Asc");
	Else
		Certificates.Sort("Isinthedirectory Desc, IsRequest Asc, Presentation Asc");
	EndIf;
	
	If ValueIsFilled(SelectedCertificateThumbprint)
	   And (    Items.Certificates.CurrentRow = Undefined
	      Or Certificates.FindByID(Items.Certificates.CurrentRow) = Undefined
	      Or Certificates.FindByID(Items.Certificates.CurrentRow).Thumbprint
	              <> SelectedCertificateThumbprint) Then
		
		Filter = New Structure("Thumbprint", SelectedCertificateThumbprint);
		Rows = Certificates.FindRows(Filter);
		If Rows.Count() > 0 Then
			Items.Certificates.CurrentRow = Rows[0].GetID();
		EndIf;
	EndIf;
	
	Items.CertificatesUnavailableAtClientGroup.Visible =
		ValueIsFilled(ErrorOnGetCertificatesAtClient)
		And ValueIsFilled(ErrorOnGetCertificatesAtClient.ErrorDescription);
	
	Items.CertificatesUnavailableAtServerGroup.Visible =
		ValueIsFilled(ErrorGettingCertificatesAtServer)
		And ValueIsFilled(ErrorGettingCertificatesAtServer.ErrorDescription);
	
EndProcedure

&AtServer
Procedure WriteCertificateToCatalog()
	
	If ValueIsFilled(Account) Then
		DigitalSignatureInternal.WriteCertificateToCatalog(ThisObject, Account, True);
	Else	
		DigitalSignatureInternal.WriteCertificateToCatalog(ThisObject, , True);
	EndIf;	
	
EndProcedure

&AtClient
Procedure OnCloseIndividualChoiceForm(Value, Var_Parameters) Export

	If Value = Undefined Then
		Return;
	EndIf;
	
	CertificateIndividual = Value;

EndProcedure

#EndRegion
