///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Opens a form where a user can change a password.
Procedure OpenChangePasswordForm(User = Undefined, ContinuationHandler = Undefined, AdditionalParameters = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ReturnPasswordAndDoNotSet", False);
	FormParameters.Insert("PreviousPassword", Undefined);
	FormParameters.Insert("LoginName",  "");
	If AdditionalParameters <> Undefined Then
		FillPropertyValues(FormParameters, AdditionalParameters);
	EndIf;
	FormParameters.Insert("User", User);
	
	OpenForm("CommonForm.PasswordChange", FormParameters,,,,, ContinuationHandler);
	
EndProcedure

// See UsersInternalSaaSClient.RequestPasswordForAuthenticationInService.
Procedure RequestPasswordForAuthenticationInService(ContinuationHandler, OwnerForm = Undefined, ServiceUserPassword = Undefined) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.SaaSOperations.UsersSaaS") Then
		
		ModuleUsersInternalSaaSClient = CommonClient.CommonModule(
			"UsersInternalSaaSClient");
		
		ModuleUsersInternalSaaSClient.RequestPasswordForAuthenticationInService(
			ContinuationHandler, OwnerForm, ServiceUserPassword);
	EndIf;
	
EndProcedure

Procedure InstallInteractiveDataProcessorOnInsufficientRightsToSignInError(Parameters, ErrorDescription) Export
	
	Parameters.Cancel = True;
	Parameters.InteractiveHandler = New CallbackDescription(
		"InteractiveDataProcessorOnInsufficientRightsToSignInError", ThisObject, ErrorDescription);
	
EndProcedure

#Region ForRolesInterfaceOperationInManagedForm

// For internal use only.
//
// Parameters:
//  Form - ClientApplicationForm
//  Unconditionally - Boolean
//
Procedure ExpandRoleSubsystems(Form, Unconditionally = True) Export
	
	Items = Form.Items;
	
	If Not Unconditionally
	   And Not Items.RolesShowSelectedRolesOnly.Check Then
		
		Return;
	EndIf;
	
	// Expand all.
	For Each TableRow In Form.Roles.GetItems() Do
		Items.Roles.Expand(TableRow.GetID(), True);
	EndDo;
	
EndProcedure

// For internal use only.
Procedure SelectPurpose(FormData1, Title, SelectUsersAllowed = True, IsFilter = False, CallbackDescription = Undefined) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormData1", FormData1);
	AdditionalParameters.Insert("IsFilter", IsFilter);
	AdditionalParameters.Insert("CallbackDescription", CallbackDescription);
	
	OnCloseNotifyDescription = New CallbackDescription("AfterAssignmentChoice", ThisObject, AdditionalParameters);
	
	Purpose = ?(IsFilter, FormData1.UsersKind, FormData1.Object.Purpose);
	
	FormParameters = New Structure;
	FormParameters.Insert("Title", Title);
	FormParameters.Insert("Purpose", Purpose);
	FormParameters.Insert("SelectUsersAllowed", SelectUsersAllowed);
	FormParameters.Insert("IsFilter", IsFilter);
	OpenForm("CommonForm.SelectUsersTypes", FormParameters,,,,, OnCloseNotifyDescription);
	
EndProcedure

// Opens a security warning window of the given type.
//
// Parameters:
//  Notification - CallbackDescription - A notification about closing the form. The output value is either "Undefined" or "String".
//                 If "String", then it contains the name of the selected button (depending on the warning type).
//             - Undefined - Do not notify.
//
//  WarningKind - See UsersInternalClientServer.SecurityWarningKinds
//
//  AdditionalParameter - Arbitrary - Parameter corresponding to the warning type.
//
Procedure ShowSecurityWarning(Notification, WarningKind, AdditionalParameter = Undefined) Export
	
	If Not UsersInternalClientServer.SecurityWarningKinds().Property(WarningKind) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sai giá trị tham số %1 trong thủ tục %2:
			           |""%3"".';
			           |ru = 'Неверное значение параметра %1 в процедуре %2:
			           |""%3"".';
			           |en = 'Invalid value of parameter ""%1"" in procedure ""%2"":
			           |""%3"".'; fa = 'Invalid value of parameter ""%1"" in procedure ""%2"":
			           |""%3"".';
			           |it = 'Неверное значение параметра %1 в процедуре %2:
			           |""%3"".';
			           |pl = 'Invalid value of parameter ""%1"" in procedure ""%2"":
			           |""%3"".';
			           |tr = '%2 prosedüründe %1 parametresi için geçersiz değer:
			           |""%3""'"),
			"WarningKind",
			"UsersInternalClient.ShowSecurityWarning",
			WarningKind);
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", WarningKind);
	FormParameters.Insert("AdditionalParameter", AdditionalParameter);
	
	OpenForm("CommonForm.SecurityWarning", FormParameters,,,,, Notification);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Idle handlers.

// Opens a security warning window on startup (if applicable).
Procedure ShowSecurityWarningOnStartupIfNeeded() Export
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	Var_Key = CommonClientServer.StructureProperty(ClientRunParameters, "SecurityWarningKey");
	If ValueIsFilled(Var_Key) Then
		ShowSecurityWarning(Undefined, Var_Key);
	EndIf;
	
EndProcedure

Procedure OnControlRestartWhenAccessRightsReduced() Export
	NotifyAboutAppRestart();
EndProcedure

#EndRegion

#Region ConfigurationSubsystemsEventHandlers

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart(Parameters) Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientParameters.Property("ErrorInsufficientRightsForAuthorization") Then
		Parameters.RetrievedClientParameters.Insert("ErrorInsufficientRightsForAuthorization");
		InstallInteractiveDataProcessorOnInsufficientRightsToSignInError(Parameters,
			ClientParameters.ErrorInsufficientRightsForAuthorization);
	EndIf;
	
EndProcedure

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart2(Parameters) Export
	
	// Checks user authorization result and generates an error message.
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientParameters.Property("AuthorizationError") Then
		Parameters.Cancel = True;
		Parameters.InteractiveHandler = New CallbackDescription("ShowMessageBoxAndContinue",
			StandardSubsystemsClient, ClientParameters.AuthorizationError);
		Return;
	EndIf;
	
EndProcedure

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart3(Parameters) Export
	
	// Requires to change a password if necessary.
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If ClientParameters.Property("PasswordChangeRequired") Then
		Parameters.InteractiveHandler = New CallbackDescription(
			"InteractiveHandlerOnChangePasswordOnStart", ThisObject);
		Return;
	EndIf;
	
EndProcedure

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	Var_Key = CommonClientServer.StructureProperty(ClientRunParameters, "SecurityWarningKey");
	If ValueIsFilled(Var_Key) Then
		// Slight delay so that the platform has time to draw the current window, on top of which a warning window is displayed.
		AttachIdleHandler("ShowSecurityWarningAfterStart", 0.3, True);
	EndIf;
	
	If ClientRunParameters.Property("AskAboutDisablingOpenIDConnect") Then
		ClickNotification = New CallbackDescription("AskAboutDisablingOpenIDConnect", ThisObject);
		MessageTitle = NStr("vi = 'Cảnh báo bảo mật';
							|ru = 'Предупреждение безопасности';
							|en = 'Security warning'; fa = 'هشدار امنیتی';
							|it = 'Avvertenza di sicurezza';
							|pl = 'Ostrzeżenie bezpieczeństwa';
							|tr = 'Güvenlik uyarısı'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hãy tắt đăng nhập %1, nếu không sử dụng.';
				|ru = 'Отключите аутентификацию %1, если не используется.';
				|en = 'Disable %1 authentication if it is not used.'; fa = 'Disable %1 authentication if it is not used.';
				|it = 'Отключите аутентификацию %1, если не используется.';
				|pl = 'Disable %1 authentication if it is not used.';
				|tr = 'Eğer kullanılmıyorsa %1 doğrulamasını devre dışı bırakın.'"), "OpenID-Connect");
		ShowUserNotification(MessageTitle, ClickNotification,
			MessageText, PictureLib.DialogExclamation, UserNotificationStatus.Important);
	EndIf;
	
EndProcedure

// See StandardSubsystemsClient.OnReceiptServerNotification.
Procedure OnReceiptServerNotification(NameOfAlert, Result) Export
	
	If Result = "AuthorizationDenied" Then
		StopAppRestart();
		OpenForm("CommonForm.AuthorizationDenied");
		
	ElsIf Result = "RolesReduced" Then
		InitiateAppRestart();
		
	ElsIf Result = "RolesIncreased" Then
		StopAppRestart();
		ShowUserNotification(
			NStr("vi = 'Đã cập nhật quyền truy cập';
				|ru = 'Права доступа обновлены';
				|en = 'Access rights updated'; fa = 'حقوق دسترسی به‌روزرسانی شد';
				|it = 'Diritti di accesso aggiornati';
				|pl = 'Prawa dostępu zostały zaktualizowane';
				|tr = 'Erişim yetkileri güncellendi'"),
			"e1cib/app/CommonForm.InfobaseUserRoleChangeControl",
			NStr("vi = 'Hãy khởi động lại ứng dụng để chúng có hiệu lực.';
				|ru = 'Перезапустите приложение, чтобы они вступили в силу.';
				|en = 'Restart the application so that they come into force.'; fa = 'Restart the application so that they come into force.';
				|it = 'Перезапустите приложение, чтобы они вступили в силу.';
				|pl = 'Restart the application so that they come into force.';
				|tr = 'Devreye girmeleri için uygulamayı yeniden başlatın.'"),
			PictureLib.DialogExclamation,
			UserNotificationStatus.Important,
			"InfobaseUserRoleChangeControl");
		
	ElsIf TypeOf(Result) = Type("Number") Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sau %1, ứng dụng sẽ trở nên không khả dụng.
			           |Nếu cần gia hạn thời hạn, hãy liên hệ với người quản trị.';
			           |ru = 'Через %1 приложение станет недоступным.
			           |Если требуется продлить срок, обратитесь к администратору.';
			           |en = 'Your access will expire in %1.
			           |To extend access, contact your administrator.'; fa = 'Your access will expire in %1.
			           |To extend access, contact your administrator.';
			           |it = 'Через %1 приложение станет недоступным.
			           |Если требуется продлить срок, обратитесь к администратору.';
			           |pl = 'Your access will expire in %1.
			           |To extend access, contact your administrator.';
			           |tr = '%1''den sonra uygulama kullanılamayacak.
			           |Süreyi uzatmanız gerekirse yöneticinizle iletişime geçin.'"),
			Format(Result, "NG=") + " "
				+ UsersInternalClientServer.IntegerSubject(Result,
					"", NStr("vi = 'một ngày,hai ngày,nhiều ngày,,,,,,0';
							|ru = 'день,дня,дней,,,,,,0';
							|en = 'day,days,,,0'; fa = 'day,days,,,0';
							|it = 'день,дня,дней,,,,,,0';
							|pl = 'day,days,,,0';
							|tr = 'gün, gün, gün,,,,,,0'")));
		
		ShowUserNotification(
			NStr("vi = 'Đã quá thời hạn hiệu lực đăng nhập';
				|ru = 'Истекает срок действия входа';
				|en = 'Access about to expire'; fa = 'Access about to expire';
				|it = 'Истекает срок действия входа';
				|pl = 'Access about to expire';
				|tr = 'Oturum açma süresi dolmak üzere'"),,
			MessageText,
			PictureLib.DialogExclamation,
			UserNotificationStatus.Important,
			"UserExpirationInApp");
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

///////////////////////////////////////////////////////////////////////////////
// Notification handlers.

// Warns the user about the error of the lack of rights to sign in to the application.
Procedure InteractiveDataProcessorOnInsufficientRightsToSignInError(Parameters, ErrorDescription) Export
	
	ShowMessageBox(
		New CallbackDescription("InteractiveDataProcessorOnInsufficientRightsToSignInErrorAfterWarning",
			ThisObject, Parameters),
		ErrorDescription);
	
EndProcedure

// Exit the application after warning the user about the error of the lack of rights to sign in to the application.
Procedure InteractiveDataProcessorOnInsufficientRightsToSignInErrorAfterWarning(Parameters) Export
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// Suggests the user to change a password or exit application.
Procedure InteractiveHandlerOnChangePasswordOnStart(Parameters, Context) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("OnAuthorization", True);
	
	OpenForm("CommonForm.PasswordChange", FormParameters,,,,, New CallbackDescription(
		"InteractiveHandlerOnChangePasswordOnStartCompletion", ThisObject, Parameters));
	
EndProcedure

// Continue the InteractiveDataProcessorOnChangePasswordOnStart procedure.
Procedure InteractiveHandlerOnChangePasswordOnStartCompletion(Result, Parameters) Export
	
	If Not ValueIsFilled(Result) Then
		Parameters.Cancel = True;
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// Prompts to disable OpenID-Connect authentication on startup.
Procedure AskAboutDisablingOpenIDConnect(Context) Export
	
	CompletionProcessing = New CallbackDescription(
		"AskAboutDisablingOpenIDConnectCompletion", ThisObject);
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Người sử dụng đã bật đăng nhập %1.
		           |Nếu không sử dụng dạng đăng nhập này thì nên vô hiệu nó.';
		           |ru = 'Для пользователей включена аутентификация %1.
		           |Если такой вид аутентификации не используется, рекомендуется его отключить.';
		           |en = '%1 authentication is enabled for users.
		           |If you do not use this authentication kind, disable it.'; fa = '%1 authentication is enabled for users.
		           |If you do not use this authentication kind, disable it.';
		           |it = 'Для пользователей включена аутентификация %1.
		           |Если такой вид аутентификации не используется, рекомендуется его отключить.';
		           |pl = '%1 authentication is enabled for users.
		           |If you do not use this authentication kind, disable it.';
		           |tr = 'Kullanıcılar için %1 doğrulaması dahildir.
		           |Eğer böyle bir doğrulama türü kullanılmıyorsa devre dışı bırakmanız önerilir.'"),
		"OpenID-Connect");
	
	Buttons = New ValueList;
	Buttons.Add("DisabledForAllUsers", NStr("vi = 'Vô hiệu đối với tất cả người sử dụng';
											|ru = 'Отключить у всех пользователей';
											|en = 'Disable for all users'; fa = 'Disable for all users';
											|it = 'Отключить у всех пользователей';
											|pl = 'Disable for all users';
											|tr = 'Tüm kullanıcılar için devre dışı bırak'"));
	Buttons.Add("DoNotDisable",                 NStr("vi = 'Không vô hiệu';
													|ru = 'Не отключать';
													|en = 'Do not disable'; fa = 'Do not disable';
													|it = 'Не отключать';
													|pl = 'Do not disable';
													|tr = 'Devre dışı bırakma'"));
	Buttons.Add("RemindLater",              NStr("vi = 'Nhắc sau';
												|ru = 'Напомнить позже';
												|en = 'Remind me later'; fa = 'Remind me later';
												|it = 'Ricordare più tardi';
												|pl = 'Przypomnij później';
												|tr = 'Daha sonra hatırlat'"));
	
	AdditionalParameters = StandardSubsystemsClient.QuestionToUserParameters();
	AdditionalParameters.Title = NStr("vi = 'Cảnh báo bảo mật';
										|ru = 'Предупреждение безопасности';
										|en = 'Security warning'; fa = 'هشدار امنیتی';
										|it = 'Avvertenza di sicurezza';
										|pl = 'Ostrzeżenie bezpieczeństwa';
										|tr = 'Güvenlik uyarısı'");
	AdditionalParameters.PromptDontAskAgain = False;
	
	StandardSubsystemsClient.ShowQuestionToUser(CompletionProcessing,
		QueryText, Buttons, AdditionalParameters);
	
EndProcedure

// Continues the "AskAboutDisablingOpenIDConnect" procedure.
Procedure AskAboutDisablingOpenIDConnectCompletion(Result, Parameters) Export
	
	Response = ?(Result <> Undefined, Result.Value, "RemindLater");
	
	If Response = "DisabledForAllUsers" Then
		StandardSubsystemsServerCall.ProcessAnswerOnDisconnectingOpenIDConnect(True);
	ElsIf Response = "DoNotDisable" Then
		StandardSubsystemsServerCall.ProcessAnswerOnDisconnectingOpenIDConnect(False);
	EndIf;
	
EndProcedure

// Writes the results of assignment selection in the form.
//
// Parameters:
//  ClosingResult - Undefined
//                    - ValueList
//  AdditionalParameters - Structure:
//    * FormData1 - ClientApplicationForm
//                  - ManagedFormExtensionForObjects:
//        ** Object - FormDataStructure
//        ** Items - FormAllItems:
//              *** SelectPurpose - FormButton
//    * IsFilter - Boolean
//    * CallbackDescription - CallbackDescription
//
Procedure AfterAssignmentChoice(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	If Not AdditionalParameters.IsFilter Then
		Purpose = AdditionalParameters.FormData1.Object.Purpose;
		Purpose.Clear();
	EndIf;
	
	SynonymArray = New Array;
	TypesArray = New Array;
	
	For Each Item In ClosingResult Do
		
		If Item.Check Then
			SynonymArray.Add(Item.Presentation);
			TypesArray.Add(Item.Value);
			If Not AdditionalParameters.IsFilter Then
				NewRow = Purpose.Add();
				NewRow.UsersType = Item.Value;
			EndIf;
		EndIf;
		
	EndDo;
	
	ItemTitle = StrConcat(SynonymArray, ", ");
	
	If AdditionalParameters.IsFilter Then
		AdditionalParameters.FormData1.UsersKind = ItemTitle;
	Else
		AdditionalParameters.FormData1.Items.SelectPurpose.Title = ItemTitle;
	EndIf;
	
	If AdditionalParameters.CallbackDescription <> Undefined Then
		RunCallback(AdditionalParameters.CallbackDescription, TypesArray);
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Procedures and functions for UsersSettings data processor.

// Opens the report or form that is passed to it.
//
// Parameters:
//  CurrentItem               - FormTable - a selected row of value tree.
//  User                 - String - the name of an infobase user,
//  CurrentUser          - String - an infobase user name. To open the form,
//                                 this value should match the value of the User parameter.
//  PersonalSettingsFormName - String - a path to open a form of personal settings.
//                                 The CommonForm.FormName kind.
//
Procedure OpenReportOrForm(CurrentItem, User, CurrentUser, PersonalSettingsFormName) Export
	
	ValueTreeItem = CurrentItem;
	If ValueTreeItem.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If User <> CurrentUser Then
		WarningText =
			NStr("vi = 'Để xem tùy chỉnh của người sử dụng khác,
			           |,cần khởi động ứng dụng với tên của người đó và mở tùy chỉnh cần thiết.';
			           |ru = 'Для просмотра настроек другого пользователя необходимо
			           |запустить приложение от его имени и открыть нужную настройку.';
			           |en = 'To view settings of another user,
			           |restart the application on behalf of that user and open the setting.'; fa = 'To view settings of another user,
			           |restart the application on behalf of that user and open the setting.';
			           |it = 'Для просмотра настроек другого пользователя необходимо
			           |запустить приложение от его имени и открыть нужную настройку.';
			           |pl = 'To view settings of another user,
			           |restart the application on behalf of that user and open the setting.';
			           |tr = 'Diğer kullanıcının ayarlarını görüntülemek için uygulama onun adı ile
			           |başlatılmalı ve gereken ayar gönderilmelidir.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	If ValueTreeItem.Name = "ReportSettingsTree" Then
		
		ObjectKey = ValueTreeItem.CurrentData.Keys[0].Value;
		ObjectKeyRowArray = StrSplit(ObjectKey, "/", False);
		VariantKey = ObjectKeyRowArray[1];
		ReportParameters = New Structure("VariantKey, UserSettingsKey", VariantKey, "");
		
		If ValueTreeItem.CurrentData.Type = "ReportSettings1" Then
			UserSettingsKey = ValueTreeItem.CurrentData.Keys[0].Presentation;
			ReportParameters.Insert("UserSettingsKey", UserSettingsKey);
		EndIf;
		
		OpenForm(ObjectKeyRowArray[0] + ".Form", ReportParameters);
		Return;
		
	ElsIf ValueTreeItem.Name = "Interface" Then
		
		For Each ObjectKey In ValueTreeItem.CurrentData.Keys Do
			
			If ObjectKey.Check = True Then
				
				FormName = StrSplit(ObjectKey.Value, "/")[0];
				FormNameParts = StrSplit(FormName, ".");
				While FormNameParts.Count() > 4 Do
					FormNameParts.Delete(4);
				EndDo;
				FormName = StrConcat(FormNameParts, ".");
				OpenForm(FormName);
				Return;
			Else
				ItemParent = ValueTreeItem.CurrentData.GetParent();
				
				If ValueTreeItem.CurrentData.RowType = "DesktopSettings" Then
					ShowMessageBox(,
						NStr("vi = 'Để xem tùy chỉnh trang đầu, hãy chuyển đến phần
							|""Trang đầu"" trong giao diện lệnh của ứng dụng.';
							|ru = 'Для просмотра настроек начальной страницы перейдите к разделу
							|""Начальная страница"" в командном интерфейсе приложения.';
							|en = 'Navigate to ""Home page"" to view its settings.'; fa = 'Navigate to ""Home page"" to view its settings.';
							|it = 'Для просмотра настроек начальной страницы перейдите к разделу
							|""Начальная страница"" в командном интерфейсе приложения.';
							|pl = 'Navigate to ""Home page"" to view its settings.';
							|tr = 'Masaüstü ayarlarını görmek için, uygulamanın
							|komut arayüzündeki ""Masaüstü"" bölümüne gidin.'"));
					Return;
				EndIf;
				
				If ValueTreeItem.CurrentData.RowType = "CommandInterfaceSettings" Then
					ShowMessageBox(,
						NStr("vi = 'Để xem tùy chỉnh giao diện lệnh
						           |,hãy chọn phân hệ cần thiết của giao diện lệnh trong ứng dụng.';
						           |ru = 'Для просмотра настроек командного интерфейса
						           |выберите нужный раздел командного интерфейса приложения.';
						           |en = 'To view the command interface settings,
						           |select a section in the application command interface.'; fa = 'To view the command interface settings,
						           |select a section in the application command interface.';
						           |it = 'Для просмотра настроек командного интерфейса
						           |выберите нужный раздел командного интерфейса приложения.';
						           |pl = 'To view the command interface settings,
						           |select a section in the application command interface.';
						           |tr = 'Komut arayüz ayarlarını görüntülemek için, 
						           |uygulamanın komut arayüzün gerekli bölümünü seçin.'"));
					Return;
				EndIf;
				
				If ItemParent <> Undefined Then
					WarningText =
						NStr("vi = 'Để xem tùy chỉnh này, hãy mở ""%1"" 
						           |và sau đó chuyển đến biểu mẫu ""%2"".';
						           |ru = 'Для просмотра данной настройки откройте ""%1"" 
						           |и затем перейдите к форме ""%2"".';
						           |en = 'To view this setting, open ""%1""
						           |and go to the ""%2"" form.'; fa = 'To view this setting, open ""%1""
						           |and go to the ""%2"" form.';
						           |it = 'Per visualizzare questa impostazione, aprire ""%1""
						           |e passare al modulo ""%2"".';
						           |pl = 'Aby przejrzeć to ustawienie otwórz ""%1"" 
						           |i następnie przejdź do formularza ""%2"".';
						           |tr = 'Bu ayarı görüntülemek için ""%1"" 
						           | açın ve ardından ""%2"" formuna gidin.'");
					WarningText = StringFunctionsClientServer.SubstituteParametersToString(WarningText,
						ItemParent.Setting, ValueTreeItem.CurrentData.Setting);
					ShowMessageBox(,WarningText);
					Return;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		ShowMessageBox(,NStr("vi = 'Không cho phép xem tùy chỉnh này.';
							|ru = 'Просмотр данной настройки не предусмотрен.';
							|en = 'Cannot view this setting.'; fa = 'Cannot view this setting.';
							|it = 'La visualizzazione di questa impostazione non è disponibile.';
							|pl = 'Przegląd tego ustawienia nie jest przewidziane.';
							|tr = 'Bu ayar görüntülenemiyor.'"));
		Return;
		
	ElsIf ValueTreeItem.Name = "OtherSettings" Then
		
		If ValueTreeItem.CurrentData.Type = "PersonalSettings"
			And PersonalSettingsFormName <> "" Then
			OpenForm(PersonalSettingsFormName);
			Return;
		EndIf;
		
		ShowMessageBox(,NStr("vi = 'Không cho phép xem tùy chỉnh này.';
							|ru = 'Просмотр данной настройки не предусмотрен.';
							|en = 'Cannot view this setting.'; fa = 'Cannot view this setting.';
							|it = 'La visualizzazione di questa impostazione non è disponibile.';
							|pl = 'Przegląd tego ustawienia nie jest przewidziane.';
							|tr = 'Bu ayar görüntülenemiyor.'"));
		Return;
		
	EndIf;
	
	ShowMessageBox(,NStr("vi = 'Hãy chọn tùy chỉnh để xem.';
						|ru = 'Выберите настройку для просмотра.';
						|en = 'Select a setting to view.'; fa = 'Select a setting to view.';
						|it = 'Selezionate un''impostazione da visualizzare.';
						|pl = 'Wybierz ustawienie do wyświetlenia.';
						|tr = 'Görüntülemek için bir ayar seçin.'"));
	
EndProcedure

// Generates a message to display after settings are copied.
//
// Parameters:
//  SettingPresentation            - String - a setting name. It is used when a single setting is copied.
//  SettingsCount                - Number  - settings count. It is used when multiple settings are copied.
//  SettingsCopiedToNote - String - to whom settings are copied.
//
// Returns:
//  String - a note text when copying settings.
//
Function GenerateNoteOnCopy(SettingPresentation, SettingsCount, SettingsCopiedToNote) Export
	
	If SettingsCount = 1 Then
		
		If StrLen(SettingPresentation) > 24 Then
			SettingPresentation = Left(SettingPresentation, 24) + "...";
		EndIf;
		
		NotificationComment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '""%1"" được sao chép %2';
				|ru = '""%1"" скопирована %2';
				|en = '""%1"" copied to %2.'; fa = '""%1"" copied to %2.';
				|it = '""%1"" copiata %2';
				|pl = '""%1"" skopiowana %2';
				|tr = '""%1"" kopyalandı %2'"),
			SettingPresentation,
			SettingsCopiedToNote);
	Else
		SubjectInWords = Format(SettingsCount, "NFD=0") + " "
			+ UsersInternalClientServer.IntegerSubject(SettingsCount,
				"", NStr("vi = 'tùy chỉnh,tùy chỉnh,tùy chỉnh,,,,,,0';
						|ru = 'настройка,настройки,настроек,,,,,,0';
						|en = 'setting,settings,,,0'; fa = 'setting,settings,,,0';
						|it = 'impostazione,impostazioni,delle impostazioni,,,,,,0';
						|pl = 'ustawienie,ustawienia,ustawień,,,,,,0';
						|tr = 'ayar, ayarlar, ayarlar,,,,,,0'"));
		
		NotificationComment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã sao chép %1 %2';
				|ru = 'Скопировано %1 %2';
				|en = '%1 copied to %2.'; fa = '%1 copied to %2.';
				|it = 'Copiato %1 %2';
				|pl = 'Skopiowano %1 %2';
				|tr = 'Kopyalandı %1 %2'"),
			SubjectInWords,
			SettingsCopiedToNote);
	EndIf;
	
	Return NotificationComment;
	
EndFunction

// Generates a string that describes the destination users.
//
// Parameters:
//  UsersCount - Number  - used if value is greater than 1.
//  User            - String - a username. It is used if the number of users
//                            is 1.
//
// Returns:
//  String - a note about the target user.
//
Function UsersNote(UsersCount, User) Export
	
	If UsersCount = 1 Then
		SettingsCopiedToNote = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'người sử dụng ""%1""';
				|ru = 'пользователю ""%1""';
				|en = 'user ""%1""'; fa = 'user ""%1""';
				|it = 'all''utente ""%1""';
				|pl = 'użytkownikowi ""%1""';
				|tr = 'kullanıcı ""%1""'"), User);
	Else
		SettingsCopiedToNote = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 cho người sử dụng';
				|ru = '%1 пользователям';
				|en = '%1 users.'; fa = '%1 users.';
				|it = '%1 per gli utenti';
				|pl = '%1 użytkownikom';
				|tr = '%1 kullanıcılar'"), UsersCount);
	EndIf;
	
	Return SettingsCopiedToNote;
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Procedures and functions for restarting the app upon the removal of user roles.

Procedure InitiateAppRestart()
	
	Parameters = RestartNotificationParameters();
	If ValueIsFilled(Parameters.RestartDate) Then
		Return;
	EndIf;
	
	Parameters.RestartDate = CommonClient.SessionDate() + 15*60; // 15 minutes.
	
	AttachIdleHandler("ControlRestartWhenAccessRightsReduced", 60);
	NotifyAboutAppRestart();
	
EndProcedure

Procedure StopAppRestart()
	
	DetachIdleHandler("ControlRestartWhenAccessRightsReduced");
	ClearRestartAlert();
	RestartNotificationParameters().RestartDate = '00010101';
	
EndProcedure

Procedure NotifyAboutAppRestart()
	
	Parameters = RestartNotificationParameters();
	If Not ValueIsFilled(Parameters.RestartDate) Then
		Return;
	EndIf;
	
	If Not StandardSubsystemsServerCall.AreCurrentUserRolesReduced() Then
		StopAppRestart();
		Return;
	EndIf;
	
	WaitTimeout = 10; // 10 minutes.
	ExitWithConfirmationTimeout = 5; // 5 minutes.
	CurrentMoment = CommonClient.SessionDate();
	
	If Parameters.RestartDate - CurrentMoment < 5 Then
		RestartNow();
		Return;
	EndIf;
	
	MinutesLeft = MinutesBeforeRestart(Parameters.RestartDate, CurrentMoment);
	MinutesLeftPresentation = MinutesBeforeRestartPresentation(MinutesLeft);
	
	ShowRestartAlert(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Nên lưu tất cả dữ liệu của mình. Khởi động lại sau %1';
			|ru = 'Рекомендуется сохранить все свои данные. Перезапуск через %1';
			|en = 'App will restart in %1. Save the changes.'; fa = 'App will restart in %1. Save the changes.';
			|it = 'Рекомендуется сохранить все свои данные. Перезапуск через %1';
			|pl = 'App will restart in %1. Save the changes.';
			|tr = 'Tüm verilerinizi kaydetmeniz önerilir. Şu süreden sonra yeniden başlat:%1'"),
		MinutesLeftPresentation));
	
	If MinutesLeft <= ExitWithConfirmationTimeout Then
		AskOnTermination(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Nên lưu tất cả dữ liệu của mình.
			           |Khởi động lại sau %1. Khởi động ngay?';
			           |ru = 'Рекомендуется сохранить все свои данные.
			           |Перезапуск через %1. Перезапустить сейчас?';
			           |en = 'App will restart in %1. Save the changes.
			           |Restart now?'; fa = 'App will restart in %1. Save the changes.
			           |Restart now?';
			           |it = 'Рекомендуется сохранить все свои данные.
			           |Перезапуск через %1. Перезапустить сейчас?';
			           |pl = 'App will restart in %1. Save the changes.
			           |Restart now?';
			           |tr = 'Tüm verilerinizi kaydetmeniz önerilir. %1Şu süreden sonra yeniden başlat:
			           |Yeniden başlatılsın mı?'"),
			MinutesLeftPresentation));
		
	ElsIf MinutesLeft <= WaitTimeout Then
		ShowWarningOnExit(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Nên lưu tất cả dữ liệu của mình.
				|Khởi động lại sau %1';
				|ru = 'Рекомендуется сохранить все свои данные.
				|Перезапуск через %1';
				|en = 'App will restart in %1. Save the changes.'; fa = 'App will restart in %1. Save the changes.';
				|it = 'Рекомендуется сохранить все свои данные.
				|Перезапуск через %1';
				|pl = 'App will restart in %1. Save the changes.';
				|tr = 'Tüm verilerinizi kaydetmeniz önerilir. Şu süreden sonra 
				|yeniden başlat:%1'"),
			MinutesLeftPresentation));
	EndIf;
	
EndProcedure

Function MinutesBeforeRestart(RestartDate, CurrentMoment = Undefined) Export
	
	If CurrentMoment = Undefined Then
		CurrentMoment = CommonClient.SessionDate();
	EndIf;
	
	MinutesLeft = Int((RestartDate - CurrentMoment) / 60);
	
	Return ?(MinutesLeft > 0, MinutesLeft, 1);
	
EndFunction

Function MinutesBeforeRestartPresentation(MinutesLeft) Export
	
	Return StringFunctionsClientServer.StringWithNumberForAnyLanguage(
		NStr("vi = ';%1 phút;%1 phút;%1 phút;%1 phút;%1 phút';
			|ru = ';%1 минута;%1 минуты;%1 минут;%1 минут;%1 минут';
			|en = ';%1 minute;;;;%1 minutes'; fa = ';%1 minute;;;;%1 minutes';
			|it = ';%1 минута;%1 минуты;%1 минут;%1 минут;%1 минут';
			|pl = ';%1 minute;;;;%1 minutes';
			|tr = ';%1 dakika;;%1 dakika;%1 dakika;%1 dakika'"),
		MinutesLeft);
	
EndFunction

// Parameters:
//  ShouldUpdateLastWarningOrQuestionDate - Boolean
//
// Returns:
//  Structure:
//   * IsNotificationDisplayed - Boolean
//   * ShowWarningOrQuestion - Boolean
//   * LastQuestionOrWarningDate - Date
//   * RestartDate - Date
//
Function RestartNotificationParameters(ShouldUpdateLastWarningOrQuestionDate = False) Export
	
	ParameterName = "StandardSubsystems.Users.RestartNotificationParameters";
	Properties = ApplicationParameters[ParameterName];
	If Properties = Undefined Or Not ValueIsFilled(Properties.RestartDate) Then
		Properties = New Structure;
		Properties.Insert("IsNotificationDisplayed", False);
		Properties.Insert("ShowWarningOrQuestion", False);
		Properties.Insert("LastQuestionOrWarningDate", '00010101');
		Properties.Insert("RestartDate", '00010101');
		ApplicationParameters.Insert(ParameterName, Properties);
	EndIf;
	
	If ShouldUpdateLastWarningOrQuestionDate Then
		SessionDate = CommonClient.SessionDate();
		If Properties.LastQuestionOrWarningDate + 50 < SessionDate Then
			Properties.LastQuestionOrWarningDate = SessionDate;
			Properties.ShowWarningOrQuestion = True;
		Else
			Properties.ShowWarningOrQuestion = False;
		EndIf;
	EndIf;
	
	Return Properties;
	
EndFunction

Procedure ShowRestartAlert(MessageText)
	
	Parameters = RestartNotificationParameters();
	If Parameters.IsNotificationDisplayed Then
		Return;
	EndIf;
	
	ShowUserNotification(
		NStr("vi = 'Sẽ khởi động lại ứng dụng';
			|ru = 'Приложение будет перезапущено';
			|en = 'App will restart'; fa = 'App will restart';
			|it = 'Приложение будет перезапущено';
			|pl = 'App will restart';
			|tr = 'Uygulama yeniden başlatılacak'"),
		"e1cib/app/CommonForm.InfobaseUserRoleChangeControl",
		MessageText,
		PictureLib.DialogExclamation,
		UserNotificationStatus.Important,
		"ControlRestartWhenAccessRightsReduced");
	
	Parameters.IsNotificationDisplayed = True;
	
EndProcedure

Procedure ClearRestartAlert()
	
	Parameters = RestartNotificationParameters();
	If Not Parameters.IsNotificationDisplayed Then
		Return;
	EndIf;
	Parameters.IsNotificationDisplayed = False;
	
	ShowUserNotification(NStr("vi = 'Đã hủy bỏ khởi động lại ứng dụng';
								|ru = 'Перезапуск приложения отменен';
								|en = 'Restart canceled'; fa = 'Restart canceled';
								|it = 'Перезапуск приложения отменен';
								|pl = 'Restart canceled';
								|tr = 'Uygulamanın yeniden başlatılması iptal edildi'"),,,,
		UserNotificationStatus.Important, "ControlRestartWhenAccessRightsReduced");
	
EndProcedure

Procedure ShowWarningOnExit(WarningText)
	
	Parameters = RestartNotificationParameters(True);
	If Not Parameters.ShowWarningOrQuestion Then
		Return;
	EndIf;
	
	ShowMessageBox(, WarningText, 30);
	
EndProcedure

Procedure AskOnTermination(QueryText)
	
	Parameters = RestartNotificationParameters(True);
	If Not Parameters.ShowWarningOrQuestion Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("AskOnTerminationCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, 30, DialogReturnCode.Yes);
	
EndProcedure

Procedure AskOnTerminationCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		RestartNow();
	EndIf;
	
EndProcedure

Procedure RestartNow()
	
	StandardSubsystemsClient.SkipExitConfirmation();
	Exit(True, True);
	
EndProcedure

#EndRegion