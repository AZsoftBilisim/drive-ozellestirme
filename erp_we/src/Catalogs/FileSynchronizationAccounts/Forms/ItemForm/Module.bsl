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
	
	If ValueIsFilled(Object.FilesAuthor) Then
		AsFilesAuthor = "User";
		Items.FilesAuthor.Enabled = True;
	Else
		AsFilesAuthor = "ExchangePlan";
		Items.FilesAuthor.Enabled = False;
	EndIf;
	
	CloudServices = New ValueList();
	FilesOperationsLocalization.OnDefineCloudServices(CloudServices);
	For Each CloudService In CloudServices Do
		Items.Service.ChoiceList.Insert(0, CloudService.Value, CloudService.Presentation);
	EndDo;
	
	AutoDescription = IsBlankString(Object.Description); 
	If Not IsBlankString(Object.Description) Then
		Items.AsFilesAuthor.ChoiceList[0].Presentation =
			StringFunctionsClientServer.SubstituteParametersToString(Items.AsFilesAuthor.Title, "(" + Object.Description + ")");
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ObjectAttributesLock") Then
		ModuleObjectAttributesLock = Common.CommonModule("ObjectAttributesLock");
		ModuleObjectAttributesLock.LockAttributes(ThisObject);
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		
		SetPrivilegedMode(True);
		AccountParameters1 = Common.ReadDataFromSecureStorage(Object.Ref, "Login, Password");
		SetPrivilegedMode(False);
		
		Login  = AccountParameters1.Login;
		Password = ?(ValueIsFilled(AccountParameters1.Password), UUID, "");
		
	EndIf;

	If Common.IsMobileClient() Then
		Items.Description.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
	ConfigureWarningAboutUnsafeResource(ThisObject);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Cancel Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	Common.WriteDataToSecureStorage(CurrentObject.Ref, Login, "Login");
	If PasswordChanged Then
		Common.WriteDataToSecureStorage(CurrentObject.Ref, Password);
	EndIf;
	SetPrivilegedMode(False);
		
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	AutoDescription = IsBlankString(Object.Description); 
EndProcedure

&AtClient
Procedure ServiceChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If Not AutoDescription Then
		Return;
	EndIf;

	SelectedService = Items.Service.ChoiceList.FindByValue(ValueSelected);
	If Not IsBlankString(ValueSelected) And SelectedService <> Undefined Then
		Object.Description = SelectedService.Presentation;	
	Else
		Object.Description = NStr("vi = 'Dịch vụ đám mây của tệp';
									|ru = 'Облачный сервис файлов';
									|en = 'Cloud file service'; fa = 'Cloud file service';
									|it = 'Облачный сервис файлов';
									|pl = 'Cloud file service';
									|tr = 'Bulut dosya hizmeti'");	
	EndIf;
	
EndProcedure

&AtClient
Procedure AsFilesAuthorOnChange(Item)
	
	Object.FilesAuthor = Undefined;
	Items.FilesAuthor.Enabled = False;
	
EndProcedure

&AtClient
Procedure PasswordOnChange(Item)
	
	PasswordChanged = True;
	
EndProcedure

&AtClient
Procedure ServiceOnChange(Item)
	ConfigureWarningAboutUnsafeResource(ThisObject);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CheckSettings(Command)
	
	ClearMessages();
	
	If Object.Ref.IsEmpty() Or Modified Then
		CallbackDescription = New CallbackDescription("CheckSettingsCompletion", ThisObject);
		QueryText = NStr("vi = 'Để kiểm tra tùy chỉnh, cần ghi lại dữ liệu tài khoản. Tiếp tục?';
						|ru = 'Для проверки настроек необходимо записать данные учетной записи. Продолжить?';
						|en = 'To proceed with the settings validation, save the account data. Do you want to continue?'; fa = 'To proceed with the settings validation, save the account data. Do you want to continue?';
						|it = 'Per verificare le impostazioni è necessario registrare le informazioni dell''account. Continuare?';
						|pl = 'Aby zweryfikować ustawienia, należy zapisać dane konta. Kontynuować?';
						|tr = 'Ayarları doğrulamak için hesap bilgilerini kaydetmeniz gerekir. Devam edilsin mi?'");
		Buttons = New ValueList;
		Buttons.Add("Continue", NStr("vi = 'Tiếp tục';
									|ru = 'Продолжить';
									|en = 'Continue'; fa = 'ادامه';
									|it = 'Continuare';
									|pl = 'Continue';
									|tr = 'Devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);
		ShowQueryBox(CallbackDescription, QueryText, Buttons);
		Return;
	EndIf;
	
	CheckCanSyncWithCloudService();
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ModuleObjectAttributesLockClient = CommonClient.CommonModule("ObjectAttributesLockClient");
	ModuleObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure ConfigureWarningAboutUnsafeResource(Form)
	URIStructure = CommonClientServer.URIStructure(Form.Object.Service);
	ThisIsInsecureService = URIStructure.Schema = "http";
	Form.Items.InsecureProtocolWarningGroup.Visible = ThisIsInsecureService;
EndProcedure

&AtClient
Procedure CheckSettingsCompletion(DialogResult, AdditionalParameters) Export
	
	If DialogResult <> "Continue" Then
		Return;
	EndIf;
	
	If Not Write() Then
		Return;
	EndIf;
	
	CheckCanSyncWithCloudService();
	
EndProcedure

&AtClient
Procedure CheckCanSyncWithCloudService()
	
	ResultStructure1 = ExecuteConnectionCheck(Object.Ref);
	
	ResultProtocol = ResultStructure1.ResultProtocol;
	ResultText = ResultStructure1.ResultText;
	
	If ResultStructure1.Cancel Then
		
		ErrorMessage = NStr("vi = 'Đã kiểm tra tham số để đồng bộ tệp không thành công.
				|
				|Lời khuyên:
				|%3
				|
				|Chi tiết kỹ thuật:
				|Dịch vụ %1 đã trả lại mã lỗi %2.
				|%5%4';
				|ru = 'Проверка параметров для синхронизации файлов завершилась неудачно.
				|
				|Рекомендуем:
				|%3
				|
				|Технические подробности:
				|Сервис %1 вернул код ошибки %2.
				|%5%4';
				|en = 'Failed to check parameters for file synchronization.
				|
				|We recommend that you:
				|%3
				|
				|Technical details:
				|The %1 service returned the error code %2.
				|%5%4'; fa = 'Failed to check parameters for file synchronization.
				|
				|We recommend that you:
				|%3
				|
				|Technical details:
				|The %1 service returned the error code %2.
				|%5%4';
				|it = 'Проверка параметров для синхронизации файлов завершилась неудачно.
				|
				|Рекомендуем:
				|%3
				|
				|Технические подробности:
				|Сервис %1 вернул код ошибки %2.
				|%5%4';
				|pl = 'Failed to check parameters for file synchronization.
				|
				|We recommend that you:
				|%3
				|
				|Technical details:
				|The %1 service returned the error code %2.
				|%5%4';
				|tr = 'Dosya senkronizasyonu için parametre kontrolü başarısız oldu.
				|
				|Tavsiyemiz:
				|%3
				|
				|Teknik detaylar:
				|Servis%1, %2 hata kodunu geri gönderdi.
				|%5%4'");
		Recommendations = New Array;
		Recommendations.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thử lại sau (có thể có sự cố tạm thời trong dịch vụ). Liên hệ với bộ phận dịch vụ %1.';
				|ru = 'Повторить попытку позднее (возможно временные неполадки на сервисе). Обратиться в поддержку сервиса %1.';
				|en = 'Try again later (there might be temporary issues in the service). Contact the technical service %1.'; fa = 'Try again later (there might be temporary issues in the service). Contact the technical service %1.';
				|it = 'Повторить попытку позднее (возможно временные неполадки на сервисе). Обратиться в поддержку сервиса %1.';
				|pl = 'Try again later (there might be temporary issues in the service). Contact the technical service %1.';
				|tr = 'Sonra tekrar deneyin (Serviste geçici bir arıza olabilir). %1 hizmet desteği ile iletişime geçin.'"),
			Object.Service));
		Recommendations.Add(NStr("vi = 'Chọn dịch vụ khác để đồng bộ tệp.';
								|ru = 'Выбрать другой сервис для синхронизации файлов.';
								|en = 'Select another service for file synchronization.'; fa = 'Select another service for file synchronization.';
								|it = 'Выбрать другой сервис для синхронизации файлов.';
								|pl = 'Select another service for file synchronization.';
								|tr = 'Dosya senkronizasyonu için başka hizmet seç.'"));
		
		ErrorText = "";
		
		ProtocolText = StringFunctionsClientServer.ExtractTextFromHTML(ResultProtocol);
		If Not ValueIsFilled(ResultStructure1.ErrorCode) Then
			
			DiagnosticsResult = CheckConnection(Object.Service, ProtocolText);
			ErrorText          = DiagnosticsResult.ErrorDescription;
			ProtocolText       = DiagnosticsResult.DiagnosticsLog;
			
		ElsIf ResultStructure1.ErrorCode = 404 Then
			Recommendations.Insert(0, NStr("vi = 'Kiểm tra thư mục gốc được chỉ định đã có trong dịch vụ đám mây.';
											|ru = 'Проверить, что указанная корневая папка существует в облачном сервисе.';
											|en = 'Check whether the specified root folder exists in the cloud service.'; fa = 'Check whether the specified root folder exists in the cloud service.';
											|it = 'Проверить, что указанная корневая папка существует в облачном сервисе.';
											|pl = 'Check whether the specified root folder exists in the cloud service.';
											|tr = 'Alan hizmetinde kök klasörünün mevcut olup olmadığını kontrol et.'"));
		ElsIf ResultStructure1.ErrorCode = 401 Then
			Recommendations.Insert(0, NStr("vi = 'Kiểm tra tính chính xác tên đăng nhập và mật khẩu đã nhập.';
											|ru = 'Проверить правильность введенных логина и пароля.';
											|en = 'Check whether the username and password are valid.'; fa = 'Check whether the username and password are valid.';
											|it = 'Проверить правильность введенных логина и пароля.';
											|pl = 'Check whether the username and password are valid.';
											|tr = 'Girilen kullanıcı adının ve şifrenin doğruluğunu kontrol et.'"));
		ElsIf ResultStructure1.ErrorCode = 10404 Then
			ResultStructure1.ErrorCode = ResultStructure1.ErrorCode - 10000;
			// The server does not allow saving additional file properties
		ElsIf ResultStructure1.ErrorCode = 501 Then
			// No WebDAV protocol method is implemented on the server
		Else
			Recommendations.Insert(0, NStr("vi = 'Kiểm tra dữ liệu đã nhập có đúng không.';
											|ru = 'Проверьте правильность введенных данных.';
											|en = 'Check the validity of the data you entered.'; fa = 'Check the validity of the data you entered.';
											|it = 'Verificare che i dati inseriti siano corretti.';
											|pl = 'Sprawdź poprawność wprowadzonych danych.';
											|tr = 'Girilen bilgilerin doğruluğunu kontrol edin.'"));
		EndIf;
		
		QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionParameters.PromptDontAskAgain = False;
		QuestionParameters.Picture = PictureLib.DialogStop;
		QuestionParameters.Title = NStr("vi = 'Kiểm tra tùy chỉnh';
										|ru = 'Проверка настройки';
										|en = 'Check the setting'; fa = 'Check the setting';
										|it = 'Проверка настройки';
										|pl = 'Check the setting';
										|tr = 'Ayar kontrolü'");
		
		RecommendationsText = "";
		
		For RecommendationIndex = 0 To Recommendations.UBound() Do
			RecommendationsText = RecommendationsText + StringFunctionsClientServer.SubstituteParametersToString("
			|    %1. %2", RecommendationIndex+1, Recommendations[RecommendationIndex]);
		EndDo;
			
		StandardSubsystemsClient.ShowQuestionToUser(
			Undefined,
			 StringFunctionsClientServer.SubstituteParametersToString(
			ErrorMessage,
				Object.Service, ResultStructure1.ErrorCode, RecommendationsText, ProtocolText, 
				?(ValueIsFilled(ErrorText),"", Chars.LF+ErrorText)),
			QuestionDialogMode.OK,
			QuestionParameters);
		
	Else

		QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionParameters.PromptDontAskAgain = False;
		QuestionParameters.Picture = PictureLib.Success32;
		QuestionParameters.Title = NStr("vi = 'Kiểm tra tùy chỉnh';
										|ru = 'Проверка настройки';
										|en = 'Check the setting'; fa = 'Check the setting';
										|it = 'Проверка настройки';
										|pl = 'Check the setting';
										|tr = 'Ayar kontrolü'");
	
		StandardSubsystemsClient.ShowQuestionToUser(
			Undefined,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã kiểm tra thành công tham số để đồng bộ tệp. 
						   |%1';
						   |ru = 'Проверка параметров для синхронизации файлов завершилась успешно. 
						   |%1';
						   |en = 'Parameters for file synchronization are successfully checked. 
						   |%1'; fa = 'Parameters for file synchronization are successfully checked. 
						   |%1';
						   |it = 'Verifica dei parametri per la sincronizzazione dei file completata con successo. 
						   |%1';
						   |pl = 'Sprawdzenie parametrów do synchronizacji plików zostało zakończone pomyślnie. 
						   |%1';
						   |tr = 'Dosyaların senkronizasyonu için parametre kontrolü başarı ile tamamlandı. 
						   |%1'"),
				ResultText),
			QuestionDialogMode.OK,
			QuestionParameters);
		
	EndIf;
		
EndProcedure

&AtServer
Function ExecuteConnectionCheck(Val Account)
	ResultStructure1 = Undefined;
	FilesOperationsInternal.ExecuteConnectionCheck(Account, ResultStructure1);
	Return ResultStructure1; 
EndFunction

&AtServerNoContext
Function CheckConnection(Val Service, Val ProtocolText)
	
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		Return ModuleNetworkDownload.ConnectionDiagnostics(Service);
	Else
		
		Return New Structure("ErrorDescription, DiagnosticsLog",
			NStr("vi = 'Kiểm tra kết nối internet của bạn.';
				|ru = 'Проверьте соединение с сетью Интернет.';
				|en = 'Please check the Internet connection.'; fa = 'Please check the Internet connection.';
				|it = 'Verificare la connessione a internet.';
				|pl = 'Sprawdź swoje połączenie internetowe.';
				|tr = 'İnternet bağlantınızı kontrol edin.'"), ProtocolText);
			
	EndIf;
	
EndFunction

&AtClient
Procedure AsFilesAuthorUserOnChange(Item)
	
	Items.FilesAuthor.Enabled = True;
	
EndProcedure

#EndRegion