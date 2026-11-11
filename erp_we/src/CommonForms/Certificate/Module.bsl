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
	
	ErrorAtClient = Parameters.ErrorAtClient;
	
	If ValueIsFilled(Parameters.CertificateAddress) Then

		CertificateData = GetFromTempStorage(Parameters.CertificateAddress);
		If TypeOf(CertificateData) = Type("String") Then
			CertificateData = Base64Value(CertificateData);
		EndIf;
		Certificate = New CryptoCertificate(CertificateData);
		CertificateAddress = PutToTempStorage(CertificateData, UUID);
		
	ElsIf ValueIsFilled(Parameters.Ref) Then
		CertificateAddress = CertificateAddress(Parameters.Ref, UUID);
		
		If Not ValueIsFilled(CertificateAddress) Then
			ErrorAtServer = New Structure;
			ErrorAtServer.Insert("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không tìm thấy chứng chỉ ""%1"",
				           |trong danh mục chứng chỉ.';
				           |ru = 'Сертификат ""%1"",
				           |не найден в справочнике сертификатов.';
				           |en = 'Certificate ""%1"",
				           |not found in the certificate catalog.'; fa = 'Certificate ""%1"",
				           |not found in the certificate catalog.';
				           |it = 'Certificato ""%1""
				           | non trovato nella directory dei certificati.';
				           |pl = 'Nie znaleziono certyfikatu ""%1"",
				           |w katalogu certyfikatów.';
				           |tr = '""%1"",
				           | sertifika sertifika kataloğunda bulunamadı.'"), Parameters.Ref));
			Return;
		EndIf;
	Else // Thumbprint.
		CertificateAddress = CertificateAddress(Parameters.Thumbprint, UUID);
		
		If Not ValueIsFilled(CertificateAddress) Then
			ErrorAtServer = New Structure;
			ErrorAtServer.Insert("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không tìm thấy chứng chỉ theo dấu ""%1"".';
					|ru = 'Сертификат не найден по отпечатку ""%1"".';
					|en = 'Certificate not found by thumbprint ""%1"".'; fa = 'Certificate not found by thumbprint ""%1"".';
					|it = 'Certificato non trovato per stampa ""%1"".';
					|pl = 'Nie znaleziono certyfikatów według odcisku ""%1"".';
					|tr = '""%1"" damgaya göre sertifika bulunamadı.'"), Parameters.Thumbprint));
			Return;
		EndIf;
	EndIf;
	
	If CertificateData = Undefined Then
		CertificateData = GetFromTempStorage(CertificateAddress);
		Certificate = New CryptoCertificate(CertificateData);
	EndIf;
	
	CertificateProperties = DigitalSignature.CertificateProperties(Certificate);
	
	AreCertificateAdditionalPropertiesAvailable = DigitalSignatureInternalClientServer.AreCertificateAdditionalPropertiesAvailable();
	
	If AreCertificateAdditionalPropertiesAvailable Then
		Items.GroupLicenseCryptoPro.Visible = CertificateProperties.ContainsEmbeddedLicenseCryptoPro;
		SignAlgorithm = DigitalSignatureInternalClientServer.SignAlgorithmPresentation(
			CertificateProperties.PublicKeyAlgorithm, True, True);
		Items.GroupErrorGettingReviewLists.Visible = False;
		AssignmentCodes = StrReplace(CertificateProperties.Purpose, Chars.LF, ", ");
		For Each Address In CertificateProperties.AddressesOfRevocationLists Do
			NewRow = RevocationLists.Add();
			NewRow.Address = Address;
		EndDo;
	Else
		CertificateAdditionalProperties = DigitalSignatureInternalClientServer.CertificateAdditionalProperties(
			CertificateData);
		Items.GroupLicenseCryptoPro.Visible = CertificateAdditionalProperties.ContainsEmbeddedLicenseCryptoPro;
		SignAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(
			CertificateData, True);
		FillCertificatePurposeCodes(CertificateProperties.Purpose, AssignmentCodes);
	EndIf;
	
	AssignmentSign = Certificate.UseToSign;
	AssignmentEncryption = Certificate.UseToEncrypt;
	
	Thumbprint      = CertificateProperties.Thumbprint;
	IssuedTo      = CertificateProperties.IssuedTo;
	IssuedBy       = CertificateProperties.IssuedBy;
	EndDate  = CertificateProperties.EndDate;
	PrivateKeyExpirationDate = CertificateProperties.PrivateKeyExpirationDate;
	Items.PrivateKeyExpirationDate.Visible = ValueIsFilled(PrivateKeyExpirationDate);
	
	Items.SignAlgorithm.ToolTip =
		Metadata.Catalogs.DigitalSignatureAndEncryptionApplications.Attributes.SignAlgorithm.Tooltip;
	
	FillSubjectProperties(Certificate);
	FillIssuerProperties(Certificate);
	
	InternalFieldsGroup = "Overall";
	FillInternalCertificateFields();
	
	ComponentObject = Undefined;
	
	If DigitalSignature.CommonSettings().VerifyDigitalSignaturesOnTheServer
		Or DigitalSignature.CommonSettings().GenerateDigitalSignaturesAtServer Then
		
		ResultCertificatesChain = DigitalSignatureInternal.CertificatesChain(
			CertificateData, UUID, ComponentObject);
			
		If Not ValueIsFilled(ResultCertificatesChain.Error) Then
			For Each CurrentCertificate In ResultCertificatesChain.Certificates Do
				CryptoCertificate = New CryptoCertificate(
					Base64Value(GetFromTempStorage(CurrentCertificate.CertificateData)));
				NewRow = CertificationPath.Insert(0);
				CertificateProperties = DigitalSignature.CertificateProperties(CryptoCertificate);
				NewRow.Presentation = CertificateProperties.Presentation;
				NewRow.CertificateData = CurrentCertificate.CertificateData;
			EndDo;
			Items.GroupErrorGettingCertificatesChain.Visible = False;
		Else
			ErrorGettingCertificationPathAtServer = ResultCertificatesChain.Error;
			Items.GroupErrorGettingCertificatesChain.Visible = True;
		EndIf;
		
		If Not DigitalSignatureInternalClientServer.AreCertificateAdditionalPropertiesAvailable() Then
			CertificatePropertiesExtended = DigitalSignatureInternal.CertificatePropertiesExtended(
				CertificateData, UUID, ComponentObject);
			ErrorWhenGettingReviewListAddressesOnServer = CertificatePropertiesExtended.Error;
			HasError = ValueIsFilled(CertificatePropertiesExtended.Error);
			Items.GroupErrorGettingReviewLists.Visible = HasError;
			Items.RevocationLists.Visible = Not HasError;
			If Not HasError Then
				For Each CurrentAddress In CertificatePropertiesExtended.CertificateProperties.AddressesOfRevocationLists Do
					NewRow = RevocationLists.Add();
					NewRow.Address = CurrentAddress;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	If Parameters.Property("OpeningFromCertificateItemForm") Then
		Items.FormSaveToFile.Visible = False;
		Items.FormValidate.Visible = False;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(ErrorAtServer) Then
		Cancel = True;
		DigitalSignatureInternalClient.ShowApplicationCallError(
			NStr("vi = 'Không thể mở chứng chỉ';
				|ru = 'Не удалось открыть сертификат';
				|en = 'Cannot open the certificate'; fa = 'Cannot open the certificate';
				|it = 'Non è stato possibile aprire il certificato';
				|pl = 'Nie udało się otworzyć certyfikatu';
				|tr = 'Sertifika açılamadı'"), "", 
			ErrorAtClient, ErrorAtServer);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InternalFieldsGroupOnChange(Item)
	
	FillInternalCertificateFields();
	
EndProcedure

&AtClient
Procedure InternalFieldsGroupClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.PageRootCertificates 
		And (ValueIsFilled(ErrorGettingCertificationPathAtServer) Or CertificationPath.Count() = 0) Then
			
		PopulateRootCertificates();
		
	EndIf;
	
	If CurrentPage = Items.PageRevocationLists 
		And RevocationLists.Count() = 0
		And Not DigitalSignatureInternalClientServer.AreCertificateAdditionalPropertiesAvailable() Then

		FillInReviewLists();
		
	EndIf;
		
EndProcedure

&AtClient
Procedure DecorationErrorGettingCertificatesChainClick(Item)
	
	DigitalSignatureInternalClient.ShowApplicationCallError(
		NStr("vi = 'Không thể nhận đường dẫn chứng thư';
			|ru = 'Не удалось получить путь сертификации';
			|en = 'Cannot receive a certification path'; fa = 'Cannot receive a certification path';
			|it = 'Не удалось получить путь сертификации';
			|pl = 'Cannot receive a certification path';
			|tr = 'Sertifika yolu alınamadı'"), "", 
		New Structure("ErrorDescription", ErrorGettingCertificationPaths),
		New Structure("ErrorDescription", ErrorGettingCertificationPathAtServer));
		
EndProcedure

&AtClient
Procedure DecorationErrorGettingReviewListsClick(Item)
	
	DigitalSignatureInternalClient.ShowApplicationCallError(
		NStr("vi = 'Không thể nhận địa chỉ danh sách thu hồi chứng thư';
			|ru = 'Не удалось получить адреса списков отзыва сертификата';
			|en = 'Could not receive the addresses of certificate revocation lists'; fa = 'Could not receive the addresses of certificate revocation lists';
			|it = 'Не удалось получить адреса списков отзыва сертификата';
			|pl = 'Could not receive the addresses of certificate revocation lists';
			|tr = 'Sertifikanın geri bildirim listesi adresi alınamadı'"), "", 
		New Structure("ErrorDescription", ErrorGettingListOfRevocationListsAddresses),
		New Structure("ErrorDescription", ErrorWhenGettingReviewListAddressesOnServer));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRevocationLists

&AtClient
Procedure RevocationListsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRootCertificates

&AtClient
Procedure RootCertificatesChoice(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.CertificationPath.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CertificateAddress", CurrentData.CertificateData);
	
	DigitalSignatureInternalClient.OpenCertificateForm(FormParameters);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveToFile(Command)
	
	DigitalSignatureInternalClient.SaveCertificate(Undefined, CertificateAddress);
	
EndProcedure

&AtClient
Procedure Validate(Command)
	
	AdditionalInspectionParameters = DigitalSignatureInternalClient.AdditionalCertificateVerificationParameters();
	AdditionalInspectionParameters.MergeCertificateDataErrors = False;
	DigitalSignatureInternalClient.CheckCertificate(New CallbackDescription(
		"ValidateCompletion", ThisObject), CertificateAddress,,, AdditionalInspectionParameters);
	Items.FormValidate.Enabled = False;
	
EndProcedure

&AtClient
Procedure SetRevocationList(Command)
	
	RevocationListInstallationParameters = DigitalSignatureInternalClient.RevocationListInstallationParameters(CertificateAddress);
	DigitalSignatureInternalClient.SetListOfCertificateRevocation(RevocationListInstallationParameters);

EndProcedure

&AtClient
Procedure InstallCertificate(Command)
	
	CurrentData = Items.CertificationPath.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;

	BinaryData = Base64Value(GetFromTempStorage(CurrentData.CertificateData));
	CertificateInstallationParameters = DigitalSignatureInternalClient.CertificateInstallationParameters(
		PutToTempStorage(BinaryData, UUID));
		
	If CertificationPath.Count() > 1 Then
		
		If CurrentData.GetID() = CertificationPath[0].GetID() Then
			InstallationOptions = New ValueList;
			InstallationOptions.Add("ROOT", NStr("vi = 'Chứng thư gốc tin cậy';
												|ru = 'Доверенные корневые сертификаты';
												|en = 'Trusted root certificates'; fa = 'گواهی‌های ریشه مورد اعتماد';
												|it = 'Доверенные корневые сертификаты';
												|pl = 'Trusted root certificates';
												|tr = 'Güvenilir kök sertifikaları'"));
			InstallationOptions.Add("CA", NStr("vi = 'Chứng thư trung gian';
												|ru = 'Промежуточные сертификаты';
												|en = 'Intermediate certificates'; fa = 'Intermediate certificates';
												|it = 'Промежуточные сертификаты';
												|pl = 'Intermediate certificates';
												|tr = 'Geçici sertifikalar'"));
			InstallationOptions.Add("MY", NStr("vi = 'Kho chứa riêng chứng thư';
												|ru = 'Личное хранилище сертификатов';
												|en = 'Personal certificate store'; fa = 'Personal certificate store';
												|it = 'Личное хранилище сертификатов';
												|pl = 'Personal certificate store';
												|tr = 'Güvenilir kök sertifikaları'"));
			InstallationOptions.Add("Container", NStr("vi = 'Nơi chứa và kho chứa riêng';
														|ru = 'Контейнер и личное хранилище';
														|en = 'Container and personal storage'; fa = 'Container and personal storage';
														|it = 'Контейнер и личное хранилище';
														|pl = 'Container and personal storage';
														|tr = 'Konteyner ve kişisel saklama'"));
			CertificateInstallationParameters.InstallationOptions = InstallationOptions;
		ElsIf CurrentData.GetID() <> CertificationPath[CertificationPath.Count() - 1].GetID() Then
			InstallationOptions = New ValueList;
			InstallationOptions.Add("CA", NStr("vi = 'Chứng thư trung gian';
												|ru = 'Промежуточные сертификаты';
												|en = 'Intermediate certificates'; fa = 'Intermediate certificates';
												|it = 'Промежуточные сертификаты';
												|pl = 'Intermediate certificates';
												|tr = 'Geçici sertifikalar'"));
			InstallationOptions.Add("ROOT", NStr("vi = 'Chứng thư gốc tin cậy';
												|ru = 'Доверенные корневые сертификаты';
												|en = 'Trusted root certificates'; fa = 'گواهی‌های ریشه مورد اعتماد';
												|it = 'Доверенные корневые сертификаты';
												|pl = 'Trusted root certificates';
												|tr = 'Güvenilir kök sertifikaları'"));
			InstallationOptions.Add("MY", NStr("vi = 'Kho chứa riêng chứng thư';
												|ru = 'Личное хранилище сертификатов';
												|en = 'Personal certificate store'; fa = 'Personal certificate store';
												|it = 'Личное хранилище сертификатов';
												|pl = 'Personal certificate store';
												|tr = 'Güvenilir kök sertifikaları'"));
			InstallationOptions.Add("Container", NStr("vi = 'Nơi chứa và kho chứa riêng';
														|ru = 'Контейнер и личное хранилище';
														|en = 'Container and personal storage'; fa = 'Container and personal storage';
														|it = 'Контейнер и личное хранилище';
														|pl = 'Container and personal storage';
														|tr = 'Konteyner ve kişisel saklama'"));
			CertificateInstallationParameters.InstallationOptions = InstallationOptions;
		EndIf;
	EndIf;
	
	DigitalSignatureInternalClient.InstallCertificate(CertificateInstallationParameters);
	
EndProcedure

#EndRegion

#Region Private

// Continues the Check procedure.
&AtClient
Procedure ValidateCompletion(Result, Context) Export
	
	If Result = True Then
		ShowMessageBox(, NStr("vi = 'Chứng chỉ có hiệu lực.';
								|ru = 'Сертификат действителен.';
								|en = 'Certificate is valid.'; fa = 'Certificate is valid.';
								|it = 'Certificato valido.';
								|pl = 'Certyfikat jest ważny.';
								|tr = 'Sertifika geçerli.'"));
	ElsIf Result <> Undefined Then
		
		AdditionalData = DigitalSignatureInternalClient.AdditionalDataForErrorClassifier();
		AdditionalData.CertificateData = CertificateAddress;
		
		WarningParameters = New Structure;
		WarningParameters.Insert("AdditionalData", AdditionalData);
		
		WarningParameters.Insert("WarningTitle",
			NStr("vi = 'Chứng chỉ không có hiệu lực do:';
				|ru = 'Сертификат недействителен по причине:';
				|en = 'Certificate is invalid due to:'; fa = 'Certificate is invalid due to:';
				|it = 'Certificato non valido a causa di:';
				|pl = 'Certyfikat jest nieważny z powodu:';
				|tr = 'Sertifika şu sebeple geçerli değildir:'"));
		
		If TypeOf(Result) = Type("Structure") Then
			WarningParameters.Insert("ErrorTextClient",
				Result.ErrorDetailsAtClient);
			WarningParameters.Insert("ErrorTextServer",
				Result.ErrorDescriptionAtServer);
		Else
			WarningParameters.Insert("ErrorTextClient",
				Result);
		EndIf;
		
		DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(WarningParameters, ThisObject);
		
	EndIf;
	
	Items.FormValidate.Enabled = True;
	
EndProcedure

&AtServer
Procedure FillSubjectProperties(Certificate)
	
	Collection = DigitalSignature.CertificateSubjectProperties(Certificate);
	
	PropertiesPresentations = New Map;
	PropertiesPresentations["CommonName"] = NStr("vi = 'Tên chung';
												|ru = 'Общее имя';
												|en = 'Common name'; fa = 'Common name';
												|it = 'Nome comune';
												|pl = 'Nazwa ogólna';
												|tr = 'Genel ad'");
	PropertiesPresentations["Country"] = NStr("vi = 'Quốc gia';
												|ru = 'Страна';
												|en = 'Country'; fa = 'کشور';
												|it = 'Paese';
												|pl = 'Country';
												|tr = 'Ülke'");
	PropertiesPresentations["State"] = NStr("vi = 'Tỉnh/thành phố';
											|ru = 'Регион';
											|en = 'State'; fa = 'وضعیت';
											|it = 'Regione';
											|pl = 'State';
											|tr = 'Bölge'");
	PropertiesPresentations["Locality"] = NStr("vi = 'Khu dân cư';
												|ru = 'Населенный пункт';
												|en = 'Locality'; fa = 'Locality';
												|it = 'Località';
												|pl = 'Miejscowość';
												|tr = 'Yerleşim yeri'");
	PropertiesPresentations["Street"] = NStr("vi = 'Đường phố';
											|ru = 'Улица';
											|en = 'Street'; fa = 'Street';
											|it = 'Via';
											|pl = 'Street';
											|tr = 'Sokak'");
	PropertiesPresentations["Organization"] = NStr("vi = 'Doanh nghiệp';
													|ru = 'Организация';
													|en = 'Company'; fa = 'Company';
													|it = 'Azienda';
													|pl = 'Organizacja';
													|tr = 'İş yeri'");
	PropertiesPresentations["Department"] = NStr("vi = 'Bộ phận';
												|ru = 'Подразделение';
												|en = 'Department'; fa = 'دپارتمان';
												|it = 'Reparto';
												|pl = 'Dział';
												|tr = 'Departman'");
	PropertiesPresentations["Email"] = NStr("vi = 'Email';
											|ru = 'Электронная почта';
											|en = 'Email'; fa = 'ایمیل';
											|it = 'Posta elettronica';
											|pl = 'Poczta elektroniczna';
											|tr = 'E-posta'");
	
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		CommonClientServer.SupplementMap(PropertiesPresentations,
			DataProcessors["DigitalSignatureAndEncryptionApplications"].PresentationOfCertificateSubjectProperties(), True);
	EndIf;
	
	For Each ListItem In PropertiesPresentations Do
		
		If ListItem.Key = "NamePatronymic" Then
			Name = CommonClientServer.StructureProperty(Collection, "Name");
			MiddleName = CommonClientServer.StructureProperty(Collection, "MiddleName");
			PropertyValue = ?(ValueIsFilled(Name), Name, "") + ?(ValueIsFilled(MiddleName), ?(ValueIsFilled(
				Name), " ", "") + MiddleName, "");
		Else
			PropertyValue = CommonClientServer.StructureProperty(Collection, ListItem.Key);
		EndIf;
		
		If Not ValueIsFilled(PropertyValue) Then
			Continue;
		EndIf;
		
		String = Subject.Add();
		String.Property = ListItem.Value;
		String.Value = PropertyValue;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillIssuerProperties(Certificate)
	
	Collection = DigitalSignature.CertificateIssuerProperties(Certificate);
	
	PropertiesPresentations = New Map;
	PropertiesPresentations["CommonName"] = NStr("vi = 'Tên chung';
												|ru = 'Общее имя';
												|en = 'Common name'; fa = 'Common name';
												|it = 'Nome comune';
												|pl = 'Nazwa ogólna';
												|tr = 'Genel ad'");
	PropertiesPresentations["Country"] = NStr("vi = 'Quốc gia';
												|ru = 'Страна';
												|en = 'Country'; fa = 'کشور';
												|it = 'Paese';
												|pl = 'Country';
												|tr = 'Ülke'");
	PropertiesPresentations["State"] = NStr("vi = 'Tỉnh/thành phố';
											|ru = 'Регион';
											|en = 'State'; fa = 'وضعیت';
											|it = 'Regione';
											|pl = 'State';
											|tr = 'Bölge'");
	PropertiesPresentations["Locality"] = NStr("vi = 'Khu dân cư';
												|ru = 'Населенный пункт';
												|en = 'Locality'; fa = 'Locality';
												|it = 'Località';
												|pl = 'Miejscowość';
												|tr = 'Yerleşim yeri'");
	PropertiesPresentations["Street"] = NStr("vi = 'Đường phố';
											|ru = 'Улица';
											|en = 'Street'; fa = 'Street';
											|it = 'Via';
											|pl = 'Street';
											|tr = 'Sokak'");
	PropertiesPresentations["Organization"] = NStr("vi = 'Doanh nghiệp';
													|ru = 'Организация';
													|en = 'Company'; fa = 'Company';
													|it = 'Azienda';
													|pl = 'Organizacja';
													|tr = 'İş yeri'");
	PropertiesPresentations["Department"] = NStr("vi = 'Bộ phận';
												|ru = 'Подразделение';
												|en = 'Department'; fa = 'دپارتمان';
												|it = 'Reparto';
												|pl = 'Dział';
												|tr = 'Departman'");
	PropertiesPresentations["Email"] = NStr("vi = 'Email';
											|ru = 'Электронная почта';
											|en = 'Email'; fa = 'ایمیل';
											|it = 'Posta elettronica';
											|pl = 'Poczta elektroniczna';
											|tr = 'E-posta'");
	
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		CommonClientServer.SupplementMap(PropertiesPresentations,
			DataProcessors["DigitalSignatureAndEncryptionApplications"].CertificatePublisherPropertyPresentations(), True);
	EndIf;
	
	For Each ListItem In PropertiesPresentations Do
		PropertyValue = CommonClientServer.StructureProperty(Collection, ListItem.Key);
		If Not ValueIsFilled(PropertyValue) Then
			Continue;
		EndIf;
		String = Issuer.Add();
		String.Property = ListItem.Value;
		String.Value = PropertyValue;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInternalCertificateFields()
	
	InternalContent.Clear();
	CertificateBinaryData = GetFromTempStorage(CertificateAddress);
	Certificate = New CryptoCertificate(CertificateBinaryData);
	AreCertificateAdditionalPropertiesAvailable = DigitalSignatureInternalClientServer.AreCertificateAdditionalPropertiesAvailable();
	Items.InternalContentId.Visible = True;
	Items.InternalContentProperty.Visible = True;

	If InternalFieldsGroup = "Overall" Then
		Items.InternalContentId.Visible = False;
		
		AddProperty(Certificate, "Version",                    NStr("vi = 'Phiên bản';
																	|ru = 'Версия';
																	|en = 'Version'; fa = 'نسخه';
																	|it = 'Versione';
																	|pl = 'Version';
																	|tr = 'Sürüm'"));
		AddProperty(Certificate, "ValidFrom",                NStr("vi = 'Ngày bắt đầu';
																	|ru = 'Дата начала';
																	|en = 'Start date'; fa = 'تاریخ شروع';
																	|it = 'Data di inizio';
																	|pl = 'Data rozpoczęcia';
																	|tr = 'Başlangıç tarihi'"));
		AddProperty(Certificate, "ValidTo",             NStr("vi = 'Ngày kết thúc';
															|ru = 'Дата окончания';
															|en = 'End date'; fa = 'تاریخ پایان';
															|it = 'Data di fine';
															|pl = 'Data zakończenia';
															|tr = 'Bitiş tarihi'"));
		
		If AreCertificateAdditionalPropertiesAvailable Then
			If ValueIsFilled(Certificate.StartUniversalDateOfPrivateKey) Then
				AddProperty(Certificate, "StartUniversalDateOfPrivateKey",    NStr("vi = 'Ngày bắt đầu khóa riêng';
																					|ru = 'Дата начала закрытого ключа';
																					|en = 'Private key start date'; fa = 'Private key start date';
																					|it = 'Дата начала закрытого ключа';
																					|pl = 'Private key start date';
																					|tr = 'Özel anahtarın başlangıç tarihi'"));
			EndIf;
			If ValueIsFilled(Certificate.UniversalDateOfPrivateKeyExpiration) Then
				AddProperty(Certificate, "UniversalDateOfPrivateKeyExpiration", NStr("vi = 'Ngày kết thúc khóa riêng';
																					|ru = 'Дата окончания закрытого ключа';
																					|en = 'Private key end date'; fa = 'تاریخ پایان کلید خصوصی';
																					|it = 'Дата окончания закрытого ключа';
																					|pl = 'Private key end date';
																					|tr = 'Özel anahtarın bitiş tarihi'"));
			EndIf;
		Else
			If ValueIsFilled(CertificateAdditionalProperties.PrivateKeyStartDate) Then
				AddProperty(CertificateAdditionalProperties, "PrivateKeyStartDate",    NStr("vi = 'Ngày bắt đầu khóa riêng';
																							|ru = 'Дата начала закрытого ключа';
																							|en = 'Private key start date'; fa = 'Private key start date';
																							|it = 'Дата начала закрытого ключа';
																							|pl = 'Private key start date';
																							|tr = 'Özel anahtarın başlangıç tarihi'"));
			EndIf;
			If ValueIsFilled(CertificateAdditionalProperties.PrivateKeyExpirationDate) Then
				AddProperty(CertificateAdditionalProperties, "PrivateKeyExpirationDate", NStr("vi = 'Ngày kết thúc khóa riêng';
																								|ru = 'Дата окончания закрытого ключа';
																								|en = 'Private key end date'; fa = 'تاریخ پایان کلید خصوصی';
																								|it = 'Дата окончания закрытого ключа';
																								|pl = 'Private key end date';
																								|tr = 'Özel anahtarın bitiş tarihi'"));
			EndIf;
		EndIf;
		
		AddProperty(Certificate, "UseToSign",    NStr("vi = 'Sử dụng đối với chữ ký';
														|ru = 'Использовать для подписи';
														|en = 'Use for signature'; fa = 'Use for signature';
														|it = 'Utilizzare per la firma';
														|pl = 'Używaj do podpisywania';
														|tr = 'İmza için kullanın'"));
		AddProperty(Certificate, "UseToEncrypt", NStr("vi = 'Sử dụng để mã hóa';
														|ru = 'Использовать для шифрования';
														|en = 'Use for encryption'; fa = 'Use for encryption';
														|it = 'Utilizzare per la crittografia';
														|pl = 'Używaj do szyfrowania';
														|tr = 'Şifreleme için kullanın'"));
		AddProperty(Certificate, "PublicKey",              NStr("vi = 'Khóa mở';
																|ru = 'Открытый ключ';
																|en = 'Public key'; fa = 'Public key';
																|it = 'Aprire chiave';
																|pl = 'Klucz publiczny';
																|tr = 'Genel anahtar'"), True);
		AddProperty(Certificate, "Thumbprint",                 NStr("vi = 'Đóng dấu';
																	|ru = 'Отпечаток';
																	|en = 'Thumbprint'; fa = 'اثر انگشت';
																	|it = 'Identificazione personale';
																	|pl = 'Odcisk';
																	|tr = 'Parmak izi'"), True);
		AddProperty(Certificate, "SerialNumber",             NStr("vi = 'Số sê-ri';
																	|ru = 'Серийный номер';
																	|en = 'Serial number'; fa = 'شماره سریال';
																	|it = 'Numero di serie';
																	|pl = 'Numer seryjny';
																	|tr = 'Seri numarası'"), True);
		
	ElsIf InternalFieldsGroup = "Extensions" And AreCertificateAdditionalPropertiesAvailable Then
		
		IDsNames = New ValueList;
		IDsNames.Add("2.5.29.31", NStr("vi = 'Điểm phân phối danh sách thu hồi';
										|ru = 'Точки распространения списков отзыва';
										|en = 'Revocation list distribution points'; fa = 'Revocation list distribution points';
										|it = 'Revocation list distribution points';
										|pl = 'Revocation list distribution points';
										|tr = 'İptal listelerinde dağıtım noktaları'"));
		IDsNames.Add("2.5.29.16", NStr("vi = 'Kỳ sử dụng khóa đóng';
										|ru = 'Период использования закрытого ключа';
										|en = 'Privet key validity period'; fa = 'Privet key validity period';
										|it = 'Privet key validity period';
										|pl = 'Privet key validity period';
										|tr = 'Özel anahtar kullanım dönemi'"));
		IDsNames.Add("2.5.29.15", NStr("vi = 'Sử dụng khóa';
										|ru = 'Использование ключа';
										|en = 'Key usage'; fa = 'Key usage';
										|it = 'Key usage';
										|pl = 'Key usage';
										|tr = 'Anahtar kullanımı'"));
		IDsNames.Add("2.5.29.37", NStr("vi = 'Khóa nâng cao';
										|ru = 'Улучшенный ключ';
										|en = 'Enhanced key'; fa = 'Enhanced key';
										|it = 'Chiave migliorata';
										|pl = 'Ulepszony klucz';
										|tr = 'Geliştirilmiş anahtar'"));
		IDsNames.Add("1.2.643.100.114", NStr("vi = 'Kiểu ID khi cấp chứng thư';
											|ru = 'Тип идентификации при выдаче сертификата';
											|en = 'Identification type during the certificate issuance'; fa = 'Identification type during the certificate issuance';
											|it = 'Identification type during the certificate issuance';
											|pl = 'Identification type during the certificate issuance';
											|tr = 'Sertifika verilirkenki tanımlayıcı türü'"));
		IDsNames.Add("1.2.643.100.112", NStr("vi = 'Phương tiện chữ ký điện tử và Trung tâm chứng thực của bên phát hành';
											|ru = 'Средства электронной подписи и УЦ издателя';
											|en = 'Issuer CA and digital signature tools'; fa = 'Issuer CA and digital signature tools';
											|it = 'Issuer CA and digital signature tools';
											|pl = 'Issuer CA and digital signature tools';
											|tr = 'Dijital imza araçları ve yayıncının SM''si'"));
		IDsNames.Add("2.5.29.32", NStr("vi = 'Chính sách chứng thư';
										|ru = 'Политики сертификата';
										|en = 'Certificate policies'; fa = 'Certificate policies';
										|it = 'Certificate policies';
										|pl = 'Certificate policies';
										|tr = 'Sertifika politikaları'"));
		IDsNames.Add("1.3.6.1.5.5.7.1.1", NStr("vi = 'Địa chỉ để kết nhập chứng thư của bên phát hành và dịch vụ OCSP';
												|ru = 'Адреса для загрузки сертификатов издателя и OCSP служб';
												|en = 'Addresses for importing issuer certificates and OCSP services'; fa = 'Addresses for importing issuer certificates and OCSP services';
												|it = 'Addresses for importing issuer certificates and OCSP services';
												|pl = 'Addresses for importing issuer certificates and OCSP services';
												|tr = 'Yayıncı sertifikalarının ve OCSP hizmet sertifikalarının indirilebileceği adresler'"));
		IDsNames.Add("1.2.643.100.111", NStr("vi = 'Phương tiện chữ ký điện tử của đối tượng chủ';
											|ru = 'Средство электронной подписи владельца';
											|en = 'Owner digital signature tool'; fa = 'Owner digital signature tool';
											|it = 'Owner digital signature tool';
											|pl = 'Owner digital signature tool';
											|tr = 'Sahibin dijital imza aracı'"));
		IDsNames.Add("2.5.29.19", NStr("vi = 'Hạn chế chính';
										|ru = 'Основные ограничения';
										|en = 'Main limitations'; fa = 'Main limitations';
										|it = 'Main limitations';
										|pl = 'Main limitations';
										|tr = 'Ana kısıtlamalar'"));
		IDsNames.Add("1.2.643.2.2.49.2", NStr("vi = 'Giấy phép hạn chế CryptoPro CSP';
												|ru = 'Ограниченная лицензия КриптоПро CSP';
												|en = 'Limited CryptoPro CSP license'; fa = 'Limited CryptoPro CSP license';
												|it = 'Limited CryptoPro CSP license';
												|pl = 'Limited CryptoPro CSP license';
												|tr = 'Sınırlandırılmış CryptoPro CSP lisansı'"));
				
		Collection = Certificate.CertificateExtensions;
		
		NamesAndIDs = New Map;
		
		For Each ListItem In IDsNames Do
			If Collection[ListItem.Value] <> Undefined Then
				AddProperty(Collection, ListItem.Value, ListItem.Presentation);
			EndIf;
			NamesAndIDs.Insert(ListItem.Value, True);
			NamesAndIDs.Insert(ListItem.Presentation, True);
		EndDo;
		
		For Each KeyAndValue In Collection Do
			If NamesAndIDs.Get(KeyAndValue.Key) = Undefined Then
				AddProperty(Collection, KeyAndValue.Key, KeyAndValue.Key);
			EndIf;
		EndDo;
		
	ElsIf InternalFieldsGroup = "Extensions" Then
		Items.InternalContentId.Visible = False;
		
		Collection = Certificate.Extensions;
		
		For Each KeyAndValue In Collection Do
			AddProperty(Collection, KeyAndValue.Key, KeyAndValue.Key);
		EndDo;
	
	Else
		
		IDsNames = New ValueList;
		IDsNames.Add("OID2_5_4_3",              "CN");
		IDsNames.Add("OID2_5_4_6",              "C");
		IDsNames.Add("OID2_5_4_8",              "ST");
		IDsNames.Add("OID2_5_4_7",              "L");
		IDsNames.Add("OID2_5_4_9",              "Street");
		IDsNames.Add("OID2_5_4_10",             "O");
		IDsNames.Add("OID2_5_4_11",             "OU");
		IDsNames.Add("OID2_5_4_12",             "T");
		IDsNames.Add("OID1_2_840_113549_1_9_1", "E");
		
		IDsNames.Add("OID1_2_643_100_1",     "OGRN");
		IDsNames.Add("OID1_2_643_100_5",     "OGRNIP");
		IDsNames.Add("OID1_2_643_100_3",     "SNILS");
		IDsNames.Add("OID1_2_643_3_131_1_1", "INN");
		IDsNames.Add("OID1_2_643_100_4",     "INNLE");
		IDsNames.Add("OID2_5_4_4",           "SN");
		IDsNames.Add("OID2_5_4_42",          "GN");
		
		NamesAndIDs = New Map;
		Collection = Certificate[InternalFieldsGroup];
		
		For Each ListItem In IDsNames Do
			If Collection.Property(ListItem.Value) Then
				AddProperty(Collection, ListItem.Value, ListItem.Presentation);
			EndIf;
			NamesAndIDs.Insert(ListItem.Value, True);
			NamesAndIDs.Insert(ListItem.Presentation, True);
		EndDo;
		
		For Each KeyAndValue In Collection Do
			If NamesAndIDs.Get(KeyAndValue.Key) = Undefined Then
				AddProperty(Collection, KeyAndValue.Key, KeyAndValue.Key);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure AddProperty(PropertiesValues, Property, Presentation, Lowercase = Undefined)
	
	Value = PropertiesValues[Property];
	
	If TypeOf(Value) = Type("Date") Then
		Value = ToLocalTime(Value, SessionTimeZone());
	ElsIf TypeOf(Value) = Type("Number") And Property = "2.5.29.15" Then
		Value = DigitalSignatureInternal.UsingKeyAsString(Value);
	ElsIf TypeOf(Value) = Type("FixedArray") Or TypeOf(Value) = Type("Array") Then
		FixedArray = Value;
		Value = "";
		For Each ArrayElement In FixedArray Do
			If TypeOf(ArrayElement) = Type("Date") Then
				ArrayElement = StrTemplate("%1 UTC", ArrayElement);
			EndIf;
			Value = Value + ?(Value = "", "", Chars.LF) + TrimAll(ArrayElement);
		EndDo;
	EndIf;
	
	String = InternalContent.Add();
	If StrStartsWith(Property, "OID") Then
		String.Id = StrReplace(Mid(Property, 4), "_", ".");
		If Property <> Presentation Then
			String.Property = Presentation;
		EndIf;
	Else
		String.Id = Property;
		String.Property = Presentation;
	EndIf;
	
	If Lowercase = True Then
		String.Value = Lower(Value);
	Else
		String.Value = Value;
	EndIf;
	
EndProcedure

// Transforms certificate purposes into purpose codes.
//
// Parameters:
//  Purpose    - String - Multiline certificate purpose. For example:
//                           "Microsoft Encrypted File System (1.3.6.1.4.1.311.10.3.4)
//                           |E-mail Protection (1.3.6.1.5.5.7.3.4)
//                           |TLS Web Client Authentication (1.3.6.1.5.5.7.3.2)".
//  
//  PurposeCodes - String - purpose codes "1.3.6.1.4.1.311.10.3.4, 1.3.6.1.5.5.7.3.4, 1.3.6.1.5.5.7.3.2".
//
&AtServer
Procedure FillCertificatePurposeCodes(Purpose, PurposeCodes)
	
	SetPrivilegedMode(True);
	
	Codes = "";
	
	For IndexOf = 1 To StrLineCount(Purpose) Do
		
		String = StrGetLine(Purpose, IndexOf);
		CurrentCode = "";
		
		Position = StrFind(String, "(", SearchDirection.FromEnd);
		If Position <> 0 Then
			CurrentCode = Mid(String, Position + 1, StrLen(String) - Position - 1);
		EndIf;
		
		If ValueIsFilled(CurrentCode) Then
			Codes = Codes + ?(Codes = "", "", ", ") + TrimAll(CurrentCode);
		EndIf;
		
	EndDo;
	
	PurposeCodes = Codes;
	
EndProcedure

&AtClient
Procedure PopulateRootCertificates()
	
	DigitalSignatureInternalClient.GetCertificateChain(New CallbackDescription("AfterGotCertificatesChain", ThisObject),
		CertificateAddress, UUID);
	
EndProcedure

&AtClient
Async Procedure AfterGotCertificatesChain(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result.Error) Then
		For Each CurrentCertificate In Result.Certificates Do
			CryptoCertificate = New CryptoCertificate();
			Await CryptoCertificate.InitializeAsync(
				Base64Value(GetFromTempStorage(CurrentCertificate.CertificateData)));
			NewRow = CertificationPath.Insert(0);
			
			CertificateProperties = Await DigitalSignatureInternalClient.CertificateProperties(CryptoCertificate);
			
			NewRow.Presentation = CertificateProperties.Presentation;
			NewRow.CertificateData = CurrentCertificate.CertificateData;
		EndDo;
		Items.GroupErrorGettingCertificatesChain.Visible = False;
	Else
		ErrorGettingCertificationPaths = Result.Error;
		Items.GroupErrorGettingCertificatesChain.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Async Procedure FillInReviewLists()
	
	ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr(
		"vi = 'Để nhận dữ liệu về địa chỉ danh sách thu hồi chứng thư, cần cài đặt cấu phần ngoài %1.';
		|ru = 'Для получения данных об адресах списков отзыва сертификата требуется установка внешней компоненты %1.';
		|en = 'To receive addresses of certificate revocation lists, install the %1 add-in.'; fa = 'To receive addresses of certificate revocation lists, install the %1 add-in.';
		|it = 'Для получения данных об адресах списков отзыва сертификата требуется установка внешней компоненты %1.';
		|pl = 'To receive addresses of certificate revocation lists, install the %1 add-in.';
		|tr = 'Sertifika iptal listesi adresleri hakkında veri elde etmek için harici bir%1 bileşen yüklemeniz gerekir.'"),
		"ExtraCryptoAPI");

	Try
		ComponentObject = Await DigitalSignatureInternalClient.AnObjectOfAnExternalComponentOfTheExtraCryptoAPI(True, ExplanationText);
	Except
		ErrorGettingListOfRevocationListsAddresses = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Items.GroupErrorGettingReviewLists.Visible = True;
		Items.RevocationLists.Visible = False;
		Return;
	EndTry;
	
	CertificatePropertiesExtended = Await DigitalSignatureInternalClient.GetCertificatePropertiesAsync(
		CertificateAddress, ComponentObject);
		
	If ValueIsFilled(CertificatePropertiesExtended.Error) Then
		ErrorGettingListOfRevocationListsAddresses = CertificatePropertiesExtended.Error;
		Items.GroupErrorGettingReviewLists.Visible = True;
		Items.RevocationLists.Visible = False;
		Return;
	EndIf;
	
	Items.GroupErrorGettingReviewLists.Visible = False;
	Items.RevocationLists.Visible = True;
		
	AddressesOfRevocationLists = CertificatePropertiesExtended.CertificateProperties.AddressesOfRevocationLists;
	For Each CurrentAddress In CertificatePropertiesExtended.CertificateProperties.AddressesOfRevocationLists Do
		NewRow = RevocationLists.Add();
		NewRow.Address = CurrentAddress;
	EndDo;
	
EndProcedure

&AtServer
Function CertificateAddress(RefThumbprint, FormIdentifier = Undefined)
	
	CertificateData = Undefined;
	
	If TypeOf(RefThumbprint) = Type("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates") Then
		Storage = Common.ObjectAttributeValue(RefThumbprint, "CertificateData");
		If TypeOf(Storage) = Type("ValueStorage") Then
			CertificateData = Storage.Get();
		EndIf;
	Else
		Query = New Query;
		Query.SetParameter("Thumbprint", RefThumbprint);
		Query.Text =
		"SELECT ALLOWED
		|	Certificates.CertificateData
		|FROM
		|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS Certificates
		|WHERE
		|	Certificates.Thumbprint = &Thumbprint";
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			CertificateData = Selection.CertificateData.Get();
		Else
			Certificate = DigitalSignatureInternal.GetCertificateByThumbprint(RefThumbprint, False, False);
			If Certificate <> Undefined Then
				CertificateData = Certificate.Unload();
			EndIf;
		EndIf;
	EndIf;
	
	If TypeOf(CertificateData) = Type("BinaryData") Then
		Return PutToTempStorage(CertificateData, FormIdentifier);
	EndIf;
	
	Return "";
	
EndFunction

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
