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
	
	ChoiceList = Items.InstallationOption.ChoiceList;
	ChoiceList.Clear();
	
	If Not ValueIsFilled(Parameters.InstallationOptions) Then
		InstallationOptions = CertificateInstallationOptions();
		For Each CurrentVariantOfSetting In InstallationOptions Do
			ChoiceList.Add(CurrentVariantOfSetting.Value, CurrentVariantOfSetting.Presentation);
		EndDo;
	ElsIf Parameters.InstallationOptions = "Container" Then
		ChoiceList.Add("Container", NStr("vi = 'Nơi chứa và kho chứa riêng';
										|ru = 'Контейнер и личное хранилище';
										|en = 'Container and Personal store'; fa = 'کانتینر و مخزن شخصی';
										|it = 'Контейнер и личное хранилище';
										|pl = 'Container and Personal store';
										|tr = 'Konteyner ve kişisel saklama'"));
	ElsIf TypeOf(Parameters.InstallationOptions) = Type("String") Then
		ChoiceList.Add(Parameters.InstallationOptions);
	Else
		For Each CurrentVariantOfSetting In Parameters.InstallationOptions Do
			ChoiceList.Add(CurrentVariantOfSetting.Value, CurrentVariantOfSetting.Presentation);
		EndDo;
	EndIf;
	
	InstallationOption = ChoiceList[0].Value;
	
	Items.InstallationOption.ReadOnly = ChoiceList.Count() = 1;
	
	CertificateBinaryData_ = Undefined;
	If IsTempStorageURL(Parameters.Certificate) Then
		CertificateBinaryData_ = GetFromTempStorage(Parameters.Certificate);
		CertificateAddress = Parameters.Certificate;
	ElsIf ValueIsFilled(Parameters.Certificate) Then
		CertificateBinaryData_ = Base64Value(Parameters.Certificate);
		CertificateAddress = PutToTempStorage(CertificateBinaryData_, UUID);
	EndIf;
	
	If CertificateBinaryData_ <> Undefined Then
		CertificateProperties = DigitalSignature.CertificateProperties(
			New CryptoCertificate(CertificateBinaryData_));
		DigitalSignatureInternalClientServer.FillCertificateDataDetails(
			DetailsOfCertificateData, CertificateProperties);
	EndIf;
	
	Items.ShowCertificateData.Visible = ValueIsFilled(CertificateAddress);
	Items.DecorationCurrentContainer.Visible = False;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	InstallationOptionOnChange(Undefined);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InstallationOptionOnChange(Item)
	
	If InstallationOption = "Container" Then
		Items.GroupContainers.Visible = True;
		Items.ContainersRefresh.Visible = True;
		If Containers.Count() = 0 Then
			AttachIdleHandler("FindContainers", 0.1, True);
		EndIf;
	Else
		Items.GroupContainers.Visible = False;
		Items.ContainersRefresh.Visible = False;
	EndIf;
	
	Items.WarningDecoration.Visible = Upper(InstallationOption) = "ROOT";
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	AttachIdleHandler("FindContainers", 0.1, True);
	
EndProcedure

&AtClient
Procedure Set(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CertificateInstallationParameters = DigitalSignatureInternalClient.CertificateInstallationParameters(Parameters.Certificate);
	CertificateInstallationParameters.Form = ThisObject;
	CertificateInstallationParameters.CallbackOnCompletion = New CallbackDescription("AfterInstallingTheCertificate", ThisObject, CertificateInstallationParameters);
	
	If InstallationOption = "Container" Then
		
		CurrentData = Items.Containers.CurrentData;
		If CurrentData = Undefined Then
			ShowMessageBox(, NStr("vi = 'Hãy chọn nơi chứa dữ liệu';
									|ru = 'Выберите контейнер';
									|en = 'Select a container'; fa = 'Select a container';
									|it = 'Выберите контейнер';
									|pl = 'Select a container';
									|tr = 'Konteyner seçin'"));
			Return;
		EndIf;
		
		ContainerProperties = DigitalSignatureInternalClient.ContainerNewProperties();
		FillPropertyValues(ContainerProperties, CurrentData);
		CertificateInstallationParameters.ContainerProperties = ContainerProperties;
		CertificateInstallationParameters.Storage = NStr("vi = 'nơi chứa dữ liệu';
														|ru = 'контейнер';
														|en = 'container'; fa = 'container';
														|it = 'контейнер';
														|pl = 'container';
														|tr = 'konteyner'");
		
	Else
		
		ListItem = Items.InstallationOption.ChoiceList.FindByValue(InstallationOption);
		CertificateInstallationParameters.Storage = New Structure("Value, Presentation", InstallationOption, ListItem.Presentation);
		
	EndIf;
	
	DigitalSignatureInternalClient.InstallCertificateAfterInstallationOptionSelected(CertificateInstallationParameters);
	
EndProcedure

&AtClient
Procedure ShowCertificateData(Command)
	
	DigitalSignatureClient.OpenCertificate(CertificateAddress, True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterInstallingTheCertificate(Result, Context) Export
	
	If Result.IsInstalledSuccessfully = True Then
		Close(Result);
	Else
		FormParameters = New Structure;
		FormParameters.Insert("WarningTitle", NStr("vi = 'Không thể cài đặt chứng thư.';
													|ru = 'Не удалось установить сертификат.';
													|en = 'Cannot install the certificate.'; fa = 'Cannot install the certificate.';
													|it = 'Не удалось установить сертификат.';
													|pl = 'Cannot install the certificate.';
													|tr = 'Sertifika kurulamadı.'"));
		FormParameters.Insert("ErrorTextClient", Result.Message);
		
		DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(FormParameters, Context.Form);
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure FindContainers()
	
	Items.GroupContainers.CurrentPage = Items.UpdateOfTable;
	Containers.Clear();
	Items.DecorationCurrentContainer.Visible = False;
	Items.DecorationCurrentContainer.Title= "";
	
	ContainersByCertificate = Await DigitalSignatureInternalClient.ContainersByCertificate(
		Parameters.Certificate); // Array of See DigitalSignatureInternalClient.ContainerNewProperties
		
	If ContainersByCertificate = Undefined Then
		Items.GroupContainers.CurrentPage = Items.TableContainers;
		Return;
	EndIf;
	
	For Each Container In ContainersByCertificate Do 
		NewRow = Containers.Add();
		FillPropertyValues(NewRow, Container);
		NewRow.ReadingTool = ReadingTool(Container.Name);
		If Container.IsCurrentContainer = True Then
			Items.DecorationCurrentContainer.Visible = True;
			Items.DecorationCurrentContainer.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chứng thư được thiết lập trong nơi chứa dữ liệu: %1';
					|ru = 'Сертификат установлен в контейнер: %1';
					|en = 'The certificate is installed in the container: %1'; fa = 'The certificate is installed in the container: %1';
					|it = 'Сертификат установлен в контейнер: %1';
					|pl = 'The certificate is installed in the container: %1';
					|tr = 'Konteynere kurulan sertifika: %1'"), Container.Name);
		EndIf;
	EndDo;
	
	Items.GroupContainers.CurrentPage = Items.TableContainers;
	If ContainersByCertificate.Count() = 0 Then
		Items.DecorationCurrentContainer.Title = NStr("vi = 'Chưa tìm thấy nơi chứa dữ liệu phù hợp để thiết lập chứng thư';
														|ru = 'Не найдено подходящих контейнеров для установки сертификата';
														|en = 'Appropriate containers to install the certificate are not found'; fa = 'Appropriate containers to install the certificate are not found';
														|it = 'Не найдено подходящих контейнеров для установки сертификата';
														|pl = 'Appropriate containers to install the certificate are not found';
														|tr = 'Sertifikanın kurulması için uygun konteyner bulunamadı'");
	EndIf;
	
EndProcedure

&AtClient
Function ReadingTool(Val NameOfContainer)
	
	NameOfContainer = Upper(NameOfContainer);
	
	If StrStartsWith(NameOfContainer, "\\.\REGISTRY") Then
		Return NStr("vi = 'Sổ đăng ký';
					|ru = 'Реестр';
					|en = 'Registry'; fa = 'دفتر ثبت';
					|it = 'Реестр';
					|pl = 'Registry';
					|tr = 'Kayıt'");
	EndIf;

	If StrStartsWith(NameOfContainer, "\\.\FAT12") Then
		Return StringFunctionsClientServer.SubstituteParametersToString( 
			NStr("vi = 'Đĩa %1';
				|ru = 'Диск %1';
				|en = 'Hard drive %1'; fa = 'Hard drive %1';
				|it = 'Диск %1';
				|pl = 'Hard drive %1';
				|tr = '%1 sabit sürücüsü'"), Mid(NameOfContainer, 11, 1));
	EndIf;
	
	If StrStartsWith(NameOfContainer, "\\.\HDIMAGE") Then
		Return NStr("vi = 'Đĩa';
					|ru = 'Диск';
					|en = 'Disk'; fa = 'Disk';
					|it = 'Диск';
					|pl = 'Disk';
					|tr = 'Sabit sürücü'");
	EndIf;
	
	Return "";
	
EndFunction

&AtServer
Function CertificateInstallationOptions()
	
	ValueList = New ValueList;
	ValueList.Add("MY", NStr("vi = 'Kho chứa riêng chứng thư';
							|ru = 'Личное хранилище сертификатов';
							|en = 'Personal certificate store'; fa = 'Personal certificate store';
							|it = 'Личное хранилище сертификатов';
							|pl = 'Personal certificate store';
							|tr = 'Güvenilir kök sertifikaları'"));
	ValueList.Add("CA", NStr("vi = 'Chứng thư trung gian';
							|ru = 'Промежуточные сертификаты';
							|en = 'Intermediate certificates'; fa = 'Intermediate certificates';
							|it = 'Промежуточные сертификаты';
							|pl = 'Intermediate certificates';
							|tr = 'Geçici sertifikalar'"));
	ValueList.Add("ROOT", NStr("vi = 'Chứng thư gốc tin cậy';
								|ru = 'Доверенные корневые сертификаты';
								|en = 'Trusted root certificates'; fa = 'گواهی‌های ریشه مورد اعتماد';
								|it = 'Доверенные корневые сертификаты';
								|pl = 'Trusted root certificates';
								|tr = 'Güvenilir kök sertifikaları'"));
	ValueList.Add("Container", NStr("vi = 'Nơi chứa và kho chứa riêng';
									|ru = 'Контейнер и личное хранилище';
									|en = 'Container and Personal store'; fa = 'کانتینر و مخزن شخصی';
									|it = 'Контейнер и личное хранилище';
									|pl = 'Container and Personal store';
									|tr = 'Konteyner ve kişisel saklama'"));
	Return ValueList;
	
EndFunction

#EndRegion
