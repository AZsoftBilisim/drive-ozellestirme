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
	
	UninstalledAtOnceCount = 0;
	ShouldCheckCryptoProvider = Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined;
	
	RequiredAddInName = Parameters.RequiredAddInName;
	If Parameters.Components <> Undefined Then
		FillPropertyValues(Parameters, Parameters.Components);
	EndIf;
	
	If Parameters.IsCryptoProviderInstalled And ShouldCheckCryptoProvider Then
		Items.GroupCheckCryptographicProviderInstalled.Visible = False;
		CryptoProviderInstallationState = 2;
	Else
		Items.GroupCheckCryptographicProviderInstalled.Visible = True;
		CryptoProviderInstallationState = 0;
	EndIf;
	If Parameters.Is1CEnterpriseExtensionInstalled Then
		Items.GroupCheck1CExtensionInstalled.Visible = False;
		InstallationStateOf1CEnterpriseExtension = 2;
	Else
		Items.GroupCheck1CExtensionInstalled.Visible = True;
		InstallationStateOf1CEnterpriseExtension = 0;
		UninstalledAtOnceCount = UninstalledAtOnceCount + 1;
	EndIf;
	If Parameters.IsCryptographicExtensionInstalled Then
		Items.GroupCheckDigitalSigningExtensionInstalled.Visible = False;
		CryptographicExtensionInstallationState = 2;
	Else
		Items.GroupCheckDigitalSigningExtensionInstalled.Visible = True;
		CryptographicExtensionInstallationState = 0;
		UninstalledAtOnceCount = UninstalledAtOnceCount + 1;
	EndIf;
	If Parameters.IsExtraCryptoAPIAddInInstalled Then
		Items.GroupCheckAddInInstalled.Visible = False;
		ExtraCryptoAPIExtensionInstallationState = 2;
	Else
		Items.GroupCheckAddInInstalled.Visible = True;
		ExtraCryptoAPIExtensionInstallationState = 0;
		UninstalledAtOnceCount = UninstalledAtOnceCount + 1;
	EndIf;
	
	If UninstalledAtOnceCount = 1 Then
		Items.SetAll.Title = NStr("vi = 'Cài đặt';
									|ru = 'Установить';
									|en = 'Install'; fa = 'نصب';
									|it = 'Install';
									|pl = 'Install';
									|tr = 'Ayarla'");
	EndIf;
	
	If Common.IsWindowsClient() Then
		Items.SetAllExtendedTooltip.Title = 
			NStr("vi = 'Sau khi hoàn tất quá trình tải xuống từng tệp, hãy nhấp vào tệp đã tải và làm theo hướng dẫn của trình cài đặt.';
				|ru = 'После окончания загрузки каждого из файлов нажмите на загруженный файл и следуйте инструкциям установщика.';
				|en = 'After each of the files is downloaded, click the file and follow the installer instructions.'; fa = 'After each of the files is downloaded, click the file and follow the installer instructions.';
				|it = 'After each of the files is downloaded, click the file and follow the installer instructions.';
				|pl = 'After each of the files is downloaded, click the file and follow the installer instructions.';
				|tr = 'Tüm dosyaların indirmesi tamamlandığında, indirilen dosyaya tıklayın ve yükleyicinin talimatlarını uygulayın.'");
	ElsIf Common.IsLinuxClient() Or Common.IsMacOSClient() Then
		Items.SetAllExtendedTooltip.Title = StringFunctions.FormattedString(
			NStr("vi = 'Để cài đặt cuối cùng của từng cấu phần, bạn phải thực hiện các thao tác sau: 
				|1. Trong cửa sổ xuất hiện, chọn lưu tệp.
				|2. Nhấn vào nút mà mũi tên trỏ tới và chọn tệp đã tải xuống.
				|3. Làm cho tệp thực thi được và khởi chạy.';
				|ru = 'Для окончательной установки каждой компоненты необходимо выполнить следующие действия:
				|1. В появившемся окне выберите сохранение файла.
				|2. Нажмите на кнопку, на которую будет указывать стрелка, и выберите скачанный файл.
				|3. Сделайте файл исполняемым и запустите.';
				|en = 'For the final installation of each add-in, perform the following steps:
				|1. In the window that appears, select Save file.
				|2. Click the button indicated by the arrow and select the downloaded file.
				|3. Make the file executable and run it.'; fa = 'For the final installation of each add-in, perform the following steps:
				|1. In the window that appears, select Save file.
				|2. Click the button indicated by the arrow and select the downloaded file.
				|3. Make the file executable and run it.';
				|it = 'For the final installation of each add-in, perform the following steps:
				|1. In the window that appears, select Save file.
				|2. Click the button indicated by the arrow and select the downloaded file.
				|3. Make the file executable and run it.';
				|pl = 'For the final installation of each add-in, perform the following steps:
				|1. In the window that appears, select Save file.
				|2. Click the button indicated by the arrow and select the downloaded file.
				|3. Make the file executable and run it.';
				|tr = 'Tüm eklentilerin kurulumunu tamamlamak için şu adımları uygulamak gerekmektedir:
				|1. Açılan pencerede dosyayı kaydetmeyi seçin.
				|2. Okla gösterilen düğmeye tıklayın ve indirilen dosyayı seçin.
				|3. Dosyayı çalıştırılabilir hale getirin ve çalıştırın.'"));
	Else
		Items.SetAllExtendedTooltip.Title = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetDecorationValueDependingOnAddInsInstallationState();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Installation_CryptoApp" Then
		
		RequireReload = ?(Parameter = True, True, False);
		If RequireReload Then
			Items.ContinueWork.Title = NStr("vi = 'Kết nhập lại';
											|ru = 'Перезагрузить';
											|en = 'Restart'; fa = 'راه‌اندازی مجدد';
											|it = 'Restart';
											|pl = 'Restart';
											|tr = 'Yeniden yükle'");
		EndIf;
		
		AfterCryptoAppInstalled();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	ContinueWork(Undefined);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationCryptoProviderInstalledNoteURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	InstallCryptoApp();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetAll(Command)
	
	If InstallationStateOf1CEnterpriseExtension = 2 Then
		ContinueInstallAddInsAfter1CEnterpriseExtensionInstalled(True);
	Else
		InstallationStateOf1CEnterpriseExtension = 1;
		SetDecorationValueDependingOnAddInsInstallationState();
		BeginInstallFileSystemExtension(New CallbackDescription(
			"After1CEnterpriseExtensionInstalled", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinueWork(Command)
	
	If RequiredAddInName = "ExtensionFor1CEnterprise" Then
		If InstallationStateOf1CEnterpriseExtension = 2 Then
			Close(True);
		Else
			Close(False);
		EndIf;
	ElsIf RequiredAddInName = "CryptographicExtension" Then
		If CryptographicExtensionInstallationState = 2 Then
			Close(True);
		Else
			Close(False);
		EndIf;
	ElsIf RequiredAddInName = "ComponentExtraCryptoAPI" Then
		ClosingParameters = New Structure("Attached, ErrorDescription");
		ClosingParameters.Attached = ?(ExtraCryptoAPIExtensionInstallationState = 2, True, False);
		ClosingParameters.ErrorDescription = "";
		Close(ClosingParameters);
	Else
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetDecorationValueDependingOnAddInsInstallationState()
	
	If CryptoProviderInstallationState = 2 Then
		TextRebootIsRequired = ?(RequireReload, NStr("vi = ', cần khởi động lại phiên làm việc';
													|ru = ', требуется перезапустить сеанс';
													|en = ', restart the application'; fa = ', restart the application';
													|it = ', restart the application';
													|pl = ', restart the application';
													|tr = ', oturum yeniden başlatılmasıdır'"), "");
		Items.DecorationCryptoProviderInstalled.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã cài đặt công cụ bảo vệ thông tin bằng mã hóa%1';
				|ru = 'Установлено средство криптографической защиты информации%1';
				|en = 'A cryptographic data protection tool is installed%1'; fa = 'A cryptographic data protection tool is installed%1';
				|it = 'A cryptographic data protection tool is installed%1';
				|pl = 'A cryptographic data protection tool is installed%1';
				|tr = 'Kriptografik bilgi koruma aracı yüklenmiş%1'"), TextRebootIsRequired);
		Items.DecorationCryptoProviderInstalledNote.Visible = False;
	ElsIf CryptoProviderInstallationState = 1 Then
		Items.DecorationCryptoProviderInstalled.Title = NStr("vi = 'Đang cài đặt công cụ bảo mật thông tin bằng mã hóa';
															|ru = 'Выполняется установка средства криптографической защиты информации';
															|en = 'Installing a cryptographic data protection tool'; fa = 'Installing a cryptographic data protection tool';
															|it = 'Installing a cryptographic data protection tool';
															|pl = 'Installing a cryptographic data protection tool';
															|tr = 'Kriptografik bilgi koruma aracı yükleniyor'");
		Items.DecorationCryptoProviderInstalledNote.Visible = False;
	Else
		Items.DecorationCryptoProviderInstalled.Title = NStr("vi = 'Chưa cài đặt công cụ bảo vệ thông tin bằng mã hóa';
															|ru = 'Не установлено средство криптографической защиты информации';
															|en = 'No cryptographic data protection tool is installed'; fa = 'No cryptographic data protection tool is installed';
															|it = 'No cryptographic data protection tool is installed';
															|pl = 'No cryptographic data protection tool is installed';
															|tr = 'Kriptografik bilgi koruma aracı yüklenmemiş'");
		Items.DecorationCryptoProviderInstalledNote.Visible = True;
	EndIf;
	
	If InstallationStateOf1CEnterpriseExtension = 2 Then
		Items.Decoration1CExtensionInstalled.Title = NStr("vi = 'Đã cài đặt thành công tiện ích mở rộng để làm việc với 1C:Enterprise';
															|ru = 'Расширение для работы с 1С:Предприятием успешно установлено';
															|en = '1C:Enterprise Extension has been installed'; fa = '1C:Enterprise Extension has been installed';
															|it = '1C:Enterprise Extension has been installed';
															|pl = '1C:Enterprise Extension has been installed';
															|tr = '1C:Enterprise işleri için eklenti başarıyla yüklendi'");
	ElsIf InstallationStateOf1CEnterpriseExtension = 1 Then
		Items.Decoration1CExtensionInstalled.Title = NStr("vi = 'Đang cài đặt tiện ích mở rộng để làm việc với 1C:Enterprise';
															|ru = 'Выполняется установка расширения для работы с 1С:Предприятием';
															|en = 'Installing 1C:Enterprise Extension'; fa = 'Installing 1C:Enterprise Extension';
															|it = 'Installing 1C:Enterprise Extension';
															|pl = 'Installing 1C:Enterprise Extension';
															|tr = '1C:Enterprise işleri için eklenti yükleniyor'");
	Else
		Items.Decoration1CExtensionInstalled.Title = NStr("vi = 'Đã cài đặt tiện ích mở rộng để hoạt động với 1C:Enterprise';
															|ru = 'Расширение для работы с 1С:Предприятием не установлено';
															|en = '1C:Enterprise Extension is not installed'; fa = '1C:Enterprise Extension is not installed';
															|it = '1C:Enterprise Extension is not installed';
															|pl = '1C:Enterprise Extension is not installed';
															|tr = '1C:Enterprise işleri için eklenti kurulamadı'");
	EndIf;
	
	If CryptographicExtensionInstallationState = 2 Then
		Items.DecorationCryptographicProviderExtensionInstalled.Title = NStr("vi = 'Đã cài đặt thành công tiện ích mở rộng để làm việc với 1C:Enterprise';
																			|ru = 'Расширение для работы с криптографией успешно установлено';
																			|en = 'The cryptography extension  has been installed'; fa = 'افزونه رمزنگاری نصب شده است';
																			|it = 'The cryptography extension  has been installed';
																			|pl = 'The cryptography extension  has been installed';
																			|tr = 'Konfigürsayon işleri için eklenti başarıyla kuruldu'");
	ElsIf CryptographicExtensionInstallationState = 1 Then
		Items.DecorationCryptographicProviderExtensionInstalled.Title = NStr("vi = 'Đang cài đặt tiện ích mở rộng để làm việc với mã hóa';
																			|ru = 'Выполняется установка расширения для работы с криптографией';
																			|en = 'Installing the cryptography extension'; fa = 'Installing the cryptography extension';
																			|it = 'Installing the cryptography extension';
																			|pl = 'Installing the cryptography extension';
																			|tr = 'Kriptografi eklentisi yükleniyor'");
	Else
		Items.DecorationCryptographicProviderExtensionInstalled.Title = NStr("vi = 'Chưa cài đặt tiện ích mở rộng để làm việc với mã hóa';
																			|ru = 'Расширение для работы с криптографией не установлено';
																			|en = 'The cryptography extension is not installed'; fa = 'The cryptography extension is not installed';
																			|it = 'The cryptography extension is not installed';
																			|pl = 'The cryptography extension is not installed';
																			|tr = 'Şifreleme uzantısı eklentisi yüklenemedi'");
	EndIf;
	
	If ExtraCryptoAPIExtensionInstallationState = 2 Then
		Items.DecorationAddInInstalled.Title = NStr("vi = 'Đã cài đặt thành công cấu phần ExtraCryptoAPI';
													|ru = 'Компонента ExtraCryptoAPI успешно установлена';
													|en = 'ExtraCryptoAPI has been installed.'; fa = 'ExtraCryptoAPI has been installed.';
													|it = 'ExtraCryptoAPI has been installed.';
													|pl = 'ExtraCryptoAPI has been installed.';
													|tr = 'ExtraCryptoAPI eklentisi başarıyla yüklendi'");
	ElsIf ExtraCryptoAPIExtensionInstallationState = 1 Then
		Items.DecorationAddInInstalled.Title = NStr("vi = 'Đang cài đặt cấu phần ExtraCryptoAPI';
													|ru = 'Выполняется установка компоненты ExtraCryptoAPI';
													|en = 'Installing ExtraCryptoAPI'; fa = 'Installing ExtraCryptoAPI';
													|it = 'Installing ExtraCryptoAPI';
													|pl = 'Installing ExtraCryptoAPI';
													|tr = 'ExtraCryptoAPI eklentisi yükleniyor'");
	Else
		Items.DecorationAddInInstalled.Title = NStr("vi = 'Chưa cài đặt cấu phần ExtraCryptoAPI';
													|ru = 'Компонента ExtraCryptoAPI не установлена';
													|en = 'Add-in ExtraCryptoAPI is not installed.'; fa = 'Add-in ExtraCryptoAPI is not installed.';
													|it = 'Add-in ExtraCryptoAPI is not installed.';
													|pl = 'Add-in ExtraCryptoAPI is not installed.';
													|tr = 'ExtraCryptoAPI  eklentisi ayarlanmadı'");
	EndIf;
	
	If InstallationStateOf1CEnterpriseExtension = 2
		And CryptographicExtensionInstallationState = 2
		And ExtraCryptoAPIExtensionInstallationState = 2 Then
		
		Items.GroupInstallAtOnce.Visible = False;
		
		If CryptoProviderInstallationState = 2 Then
			Items.GroupInstallationsHeader.Visible = False;
			Items.GroupResumeOperation.Visible = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InstallCryptoApp()
	DigitalSignatureInternalClient.OpenCryptoProviderAppsInstallationForm(, ThisObject);
EndProcedure

&AtClient
Procedure AfterCryptoAppInstalled()
	
	CryptoProviderInstallationState = 2;
	SetDecorationValueDependingOnAddInsInstallationState();
	
EndProcedure

&AtClient
Procedure After1CEnterpriseExtensionInstalled(Result) Export
	
	BeginAttachingFileSystemExtension(
		New CallbackDescription("ContinueInstallAddInsAfter1CEnterpriseExtensionInstalled", ThisObject));
	
EndProcedure

&AtClient
Procedure ContinueInstallAddInsAfter1CEnterpriseExtensionInstalled(Attached, Context = Undefined) Export
	
	If Attached = True Then
		InstallationStateOf1CEnterpriseExtension = 2;
		AfterAddInAndExtensionsInstalled();
	Else
		AttachIdleHandler("WaitFor1CEnterpriseExtensionInstallation", 3);
	EndIf;
	
	If CryptographicExtensionInstallationState = 2 Then
		ContinueInstallAddInAfterCryptographicExtensionInstalled(True);
	Else
		CryptographicExtensionInstallationState = 1;
		SetDecorationValueDependingOnAddInsInstallationState();
		BeginInstallCryptoExtension(New CallbackDescription(
			"AfterCryptographicExtensionInstalled", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Async Procedure WaitFor1CEnterpriseExtensionInstallation()
	
	Attached = Await AttachFileSystemExtensionAsync();
	If Attached Then
		DetachIdleHandler("WaitFor1CEnterpriseExtensionInstallation");
		InstallationStateOf1CEnterpriseExtension = 2;
		AfterAddInAndExtensionsInstalled();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCryptographicExtensionInstalled(Context) Export
	
	BeginAttachingCryptoExtension(New CallbackDescription(
		"ContinueInstallAddInAfterCryptographicExtensionInstalled", ThisObject, Context));
	
EndProcedure

&AtClient
Async Procedure ContinueInstallAddInAfterCryptographicExtensionInstalled(Attached, Context = Undefined) Export
	
	If Attached = True Then
		Notify("InstallCryptoExtension");
		CryptographicExtensionInstallationState = 2;
		AfterAddInAndExtensionsInstalled();
	Else
		AttachIdleHandler("WaitForCryptographyExtensionInstallation", 3);
	EndIf;
	
	If ExtraCryptoAPIExtensionInstallationState = 2 Then
		AfterAddInAndExtensionsInstalled();
	Else
		ConnectionParameters = CommonClient.AddInAttachmentParameters();
		ConnectionParameters.SuggestInstall = True;
		ConnectionParameters.SuggestToImport = True;
		ConnectionParameters.ShouldShowInstallationPrompt = False;
		ComponentDetails = DigitalSignatureInternalClientServer.ComponentDetails();
		
		ExtraCryptoAPIExtensionInstallationState = 1;
		SetDecorationValueDependingOnAddInsInstallationState();
		
		Result = Await CommonClient.AttachAddInFromTemplateAsync(
			ComponentDetails.ObjectName,
			ComponentDetails.FullTemplateName,
			ConnectionParameters);
		
		If Result.Attached Then
			ExtraCryptoAPIExtensionInstallationState = 2;
			AfterAddInAndExtensionsInstalled();
		EndIf;
	EndIf;

EndProcedure

&AtClient
Async Procedure WaitForCryptographyExtensionInstallation()
	
	Attached = Await AttachCryptoExtensionAsync();
	If Attached Then
		DetachIdleHandler("WaitForCryptographyExtensionInstallation");
		CryptographicExtensionInstallationState = 2;
		AfterAddInAndExtensionsInstalled();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterAddInAndExtensionsInstalled()
	
	// If not all required add-ins for downloading the cryptography tool or token are installed,
	// only the installation status of the component will be updated.
	If InstallationStateOf1CEnterpriseExtension = 2
		And CryptographicExtensionInstallationState = 2
		And ExtraCryptoAPIExtensionInstallationState = 2 Then
		
		CheckCryptoProviderAfterAddInAndExtensionsInstalled();
		
	Else
		SetDecorationValueDependingOnAddInsInstallationState();
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckCryptoProviderAfterAddInAndExtensionsInstalled()
	
	If DigitalSignatureClient.VerifyDigitalSignaturesOnTheServer()
		Or DigitalSignatureClient.GenerateDigitalSignaturesAtServer()
		Or DigitalSignatureInternalClient.UseCloudSignatureService()
		Or DigitalSignatureInternalClient.UseDigitalSignatureSaaS()
		Or Not ShouldCheckCryptoProvider Then
		
		SetDecorationValueDependingOnAddInsInstallationState();
		Return;
		
	EndIf;
	
	If Not RequiredAddInName = "CryptographicApp"
		And Not Items.GroupCheckCryptographicProviderInstalled.Visible Then
		
		CheckParameters = New Structure;
		CheckParameters.Insert("ShouldPromptToInstallApp", False);
		
		CryptoProviderInstallationState = 1;
		Items.GroupCheckCryptographicProviderInstalled.Visible = True;
		Items.GroupCryptographicProviderInstallationStatus.Visible = False;
		Items.GroupCheckRunning.Visible = True;
		
		DigitalSignatureInternalClient.CheckCryptographyAppsInstallation(ThisObject, CheckParameters,
			New CallbackDescription("AfterCryptoAppsInstallationChecked", ThisObject));
			
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCryptoAppsInstallationChecked(Result, Context) Export
	
	If Result.CheckCompleted Then
		
		IsCryptoProviderInstalled = Result.Tokens.Count() > 0;
		
		If Not IsCryptoProviderInstalled Then
			For Each Cryptoprovider In Result.Programs Do
				If ValueIsFilled(Cryptoprovider.Application) And Not IsCryptoProviderInstalled Then
					IsCryptoProviderInstalled = True;
				EndIf;
			EndDo;
		EndIf;
		
		If IsCryptoProviderInstalled Then
			CryptoProviderInstallationState = 2;
		Else
			Items.GroupCheckCryptographicProviderInstalled.Visible = True;
			CryptoProviderInstallationState = 0;
		EndIf;
		
		Items.GroupCryptographicProviderInstallationStatus.Visible = True;
		Items.GroupCheckRunning.Visible = False;
		
		SetDecorationValueDependingOnAddInsInstallationState();
		
	EndIf;
	
EndProcedure

#EndRegion