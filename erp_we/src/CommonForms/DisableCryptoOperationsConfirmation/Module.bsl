#Region Variables

&AtClient
Var CloseProgrammatically;

&AtClient
Var ArrayOfResources;

&AtClient
Var SessionID;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Certificate 					= Parameters.Certificate;
	ProcedureParameters 			= New Structure("CertificateID", CryptographyServiceInternal.Id(Certificate));
	TimeConsumingOperation 			= CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetSettingsForGettingTemporaryPasswords", ProcedureParameters);
	
	CertificateThumbprint		= DigitalSignatureSaaS.FindCertificateById(Certificate);
	UserData			= GetCurUserData();
	
	StoredPasswordValue 	= UserData.StoredPasswordValue;
	Login 						= UserData.Login;
	PasswordVerified				= Not ValueIsFilled(StoredPasswordValue);
	AuthorizationStep 				= 1;
	Items.TimeConsumingOperationIndicator.Picture = GetLibraryImage("TimeConsumingOperation16");
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ArrayOfResources		= PrepareArrayOfResources();
	CurrentItem		= Items.Confirm;
	CloseProgrammatically	= False;
	
	If TimeConsumingOperation <> Undefined Then
		ShowMessage(NStr("vi = 'Nhận tùy chỉnh';
						|ru = 'Получение настроек';
						|en = 'Getting settings'; fa = 'دریافت تنظیمات';
						|it = 'Ottenere impostazioni';
						|pl = 'Pobieranie ustawień';
						|tr = 'Ayarları al'"), True);
		Notification = New CallbackDescription("GetSettingsForGettingTemporaryPasswordsAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, TimeConsumingOperation);
	EndIf;	
	
	ChangePasswordVisibility(True);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If CloseProgrammatically <> True Then
		CloseProgrammatically = True;
		Cancel = True;
		
		CloseOpen(Undefined);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PasswordStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ChangePasswordVisibility();
	
EndProcedure

&AtClient
Procedure PasswordOnChange(Item)
	
	PasswordVerified = VerifyUserPassword(StoredPasswordValue, UserPassword);
	If AuthorizationStep = 2 Then
		CurrentItem = Items.PhoneCode;
	Else
		CurrentItem = Items.Confirm;
	EndIf;	
	
EndProcedure

&AtClient
Procedure UserPasswordEditTextChange(Item, Text, StandardProcessing)
	
	PasswordStatus 	= "";
	
EndProcedure

&AtClient
Procedure PhoneCodeOnChange(Item)
	
	CheckPhoneCode(PhoneCode);
	
EndProcedure

&AtClient
Procedure PhoneCodeEditTextChange(Item, Text, StandardProcessing)
	
	StandardProcessing = False;
	If StrLen(Text) = 6 Then
		PhoneCode = Text;
		CheckPhoneCode(Text);
	EndIf;	
	
EndProcedure

&AtClient
Procedure RepeatCodeClick(Item, StandardProcessing)
	
	ShowMessage(NStr("vi = 'Đang gửi mật khẩu qua tin nhắn SMS đến số';
					|ru = 'Выполняется отправка пароля в SMS-сообщении на номер';
					|en = 'Sending SMS message with password to the number'; fa = 'Sending SMS message with password to the number';
					|it = 'Invio in corso della password tramite SMS al numero';
					|pl = 'Trwa wysyłanie hasła w wiadomości SMS na numer';
					|tr = 'Parola SMS ile bu numaraya gönderiliyor'"), True);
	
	StandardProcessing 	= False;
	PhoneCode 			= "";
	CodeStatus				= "";
	DisableCountdown = 99;
	Notification 	= New CallbackDescription("GetTemporaryPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, GetPasswordOnServer(True, SessionID));
		
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseOpen(FormParameters)
	
	CloseProgrammatically = True;
	
	If FormParameters = Undefined Then
		FormParameters = New Structure();
		FormParameters.Insert("CryptoOperationsConfirmationMethod", PredefinedValue("Enum.CryptoOperationsConfirmationMethods.SessionToken"));
		FormParameters.Insert("Completed2", False);
		FormParameters.Insert("State", "ContinueReceivingSecurityToken");
		FormParameters.Insert("Certificate", Certificate);
	EndIf;
	
	If IsOpen() Then 
		Close(FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure Confirm(Command)
	
	If AuthorizationStep > 2 And PasswordVerified Then
		If Not IsCheckOnly Then
			ReflectChangesServer();
		EndIf;
		
		FormParameters = New Structure();
		FormParameters.Insert("CryptoOperationsConfirmationMethod", PredefinedValue("Enum.CryptoOperationsConfirmationMethods.LongLivedToken"));
		FormParameters.Insert("Completed2", True);
		FormParameters.Insert("State", "PasswordAccepted");
		FormParameters.Insert("Certificate", Certificate);
		
		CloseOpen(FormParameters);
		
	ElsIf Not PasswordVerified Then
		ShowMessageBox(, 
			NStr("vi = 'Vì lý do bảo mật, để tắt xác nhận giao dịch có khóa, 
			|cần điền đúng mật khẩu của người sử dụng 1C.';
			|ru = 'В целях безопасности, для отключения подтверждения операций с ключом, 
			|следует правильно указать пароль пользователя 1С.';
			|en = 'For security purposes, to disable confirmation of operations with the key, 
			|the 1C user password must be correctly specified.'; fa = 'For security purposes, to disable confirmation of operations with the key, 
			|the 1C user password must be correctly specified.';
			|it = 'Per motivi di sicurezza 
			|bisogna indicare correttamente la password dell''utente di 1C, per poter disattivare la conferma di operazioni con la chiave.';
			|pl = 'W celach bezpieczeństwa, aby odłączyć potwierdzenie operacji z kluczem, 
			|należy prawidłowo wpisać hasło użytkownika 1C.';
			|tr = 'Güvenlik nedeniyle, tuş işlemi onayını devre dışı bırakmak için
			| doğru 1C kullanıcı parolası girilmelidir.'"), 30, 
			NStr("vi = 'Thủ tục chưa hoàn thành.';
				|ru = 'Процедура не закончена.';
				|en = 'The procedure is not completed.'; fa = 'The procedure is not completed.';
				|it = 'Procedura non completata';
				|pl = 'Nie zakończono procedury.';
				|tr = 'Prosedür tamamlanmadı.'"));
		
	Else
		ShowMessageBox(, 
			NStr("vi = 'Vì lý do bảo mật, để tắt xác nhận các giao dịch có khóa, 
			|nên thực hiện toàn bộ thủ tục nhận dạng qua SMS.';
			|ru = 'В целях безопасности, для отключения подтверждения операций с ключом, 
			|следует полностью пройти процедуру идентификации по SMS.';
			|en = 'For security reasons, in order to disable the confirmation of operations with the key, 
			|you must completely go through the identification procedure by SMS.'; fa = 'For security reasons, in order to disable the confirmation of operations with the key, 
			|you must completely go through the identification procedure by SMS.';
			|it = 'Per motivi di sicurezza 
			|bisogna seguire la procedura di identificazione via SMS, per poter disattivare la conferma di operazioni con la chiave.';
			|pl = 'W celach bezpieczeństwa, aby odłączyć potwierdzenie operacji z kluczem, 
			|należy w całości przejść procedurę identyfikacji poprzez SMS.';
			|tr = 'Güvenlik nedeniyle, tuş işlemi onayını devre dışı bırakmak için
			| SMS ile kimlik doğrulama prosedürünü eksiksiz olarak uygulamanız gerekir.'"), 30, 
			NStr("vi = 'Thủ tục chưa hoàn thành.';
				|ru = 'Процедура не закончена.';
				|en = 'The procedure is not completed.'; fa = 'The procedure is not completed.';
				|it = 'Procedura non completata';
				|pl = 'Nie zakończono procedury.';
				|tr = 'Prosedür tamamlanmadı.'"));
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region Private

#Region IdleHandlers

&AtClient
Procedure CountdownPhoneCode()
	
	Timer		= TimerEnd - CurrentDate();
	TimerIsShared	= PeriodTimer - CurrentDate();
	
	If AuthorizationStep <> 2 Then
		RepeatCode 	= "";
		
	ElsIf DisableCountdown <> 99 Then
		If Timer > 0 Then
			RepeatCode = StrTemplate(NStr("vi = 'Có thể sẽ hỏi lại mật khẩu sau %1 giây.';
											|ru = 'Запросить пароль повторно можно будет через %1 сек.';
											|en = 'You can request the password again in %1 sec.'; fa = 'You can request the password again in %1 sec.';
											|it = 'È possibile richiedere la password tra %1 sec.';
											|pl = 'Ponownie poprosić o hasło można będzie przez %1 sek.';
											|tr = 'Parolayı %1 saniye içinde tekrar isteyebilirsiniz.'"), Timer);
		ElsIf Items.RepeatCode.Hyperlink = False Then
			RepeatCode = NStr("vi = 'Gửi lại mật khẩu';
								|ru = 'Отправить пароль повторно';
								|en = 'Re-send the password'; fa = 'Re-send the password';
								|it = 'Invia di nuovo la password';
								|pl = 'Wyślij hasło ponownie';
								|tr = 'Parolayı tekrar gönder'");
			Items.RepeatCode.Hyperlink = True;
		EndIf;	
		
		If DisableCountdown > 0 Then
			DisableCountdown = DisableCountdown - 1;
		ElsIf TimerIsShared > 0 And Timer > 0 Then
			CodeStatus = "";
		ElsIf TimerIsShared > 0 Then
			CodeStatus = StrTemplate(NStr("vi = 'Hết hạn trong %1: %2';
											|ru = 'Истекает через %1:%2';
											|en = 'Expires in %1:%2'; fa = 'Expires in %1:%2';
											|it = 'Scade tra %1:%2';
											|pl = 'Upływa za %1:%2';
											|tr = '%1 içinde sona erer:%2'"), Int(TimerIsShared / 60), Format(TimerIsShared % 60, "ND=2; NLZ="));
		Else
			CodeStatus = NStr("vi = 'Mật khẩu đã hết hạn';
								|ru = 'Истек срок действия пароля';
								|en = 'Password has expired'; fa = 'Password has expired';
								|it = 'Password scaduta';
								|pl = 'Upłynął termin ważności hasła';
								|tr = 'Parolanın süresi doldu'");
			Items.CodeStatus.TextColor = WebColors.Red;
		EndIf;
		
		If TimerIsShared > 0 Or Timer > 0 Then
			AttachIdleHandler("CountdownPhoneCode", 1, True);
		EndIf;
		
	EndIf;	
	
EndProcedure

&AtClient
Procedure StartPhoneCodeCountdown(Timer, ValidityPeriod)
	
	TimerEnd = CurrentDate() + Timer;
	PeriodTimer		= CurrentDate() + ValidityPeriod;
	RepeatCode 	= "";
	CodeStatus		= "";
	
	Items.CodeStatus.TextColor = WebColors.Gray;
	Items.RepeatCode.Hyperlink = False;
	DisableCountdown = 0;
	AttachIdleHandler("CountdownPhoneCode", 1, True);
	
EndProcedure

#EndRegion

&AtClient
Procedure CheckNextStep()
	
	AuthorizationStep = AuthorizationStep + 1;
	
	If AuthorizationStep = 2 Then
		Step_PhoneCode();
		
	ElsIf AuthorizationStep = 3 Then
		If Not ValueIsFilled(StoredPasswordValue) Then
			AuthorizationStep = 4;
		EndIf;
		ShowMessage("", False);
		
	EndIf;	
	
	FormControl(ThisObject);
	
	If AuthorizationStep = 2 Then
		CurrentItem 	= Items.PhoneCode;
	ElsIf AuthorizationStep = 3 And Not PasswordVerified Then
		CurrentItem 	= Items.UserPassword;
	Else
		CurrentItem 	= Items.Confirm;
	EndIf;	
	
EndProcedure

&AtClient
Procedure Step_PhoneCode()
	
	ShowMessage(NStr("vi = 'Đang gửi mật khẩu qua tin nhắn SMS đến số';
					|ru = 'Выполняется отправка пароля в SMS-сообщении на номер';
					|en = 'Sending SMS message with password to the number'; fa = 'Sending SMS message with password to the number';
					|it = 'Invio in corso della password tramite SMS al numero';
					|pl = 'Trwa wysyłanie hasła w wiadomości SMS na numer';
					|tr = 'Parola SMS ile bu numaraya gönderiliyor'"), True);
	CurrentItem 	= Items.PhoneCode;
	Notification 		= New CallbackDescription("GetTemporaryPasswordAfterExecution", ThisObject);
	CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, GetPasswordOnServer());
	
EndProcedure

&AtClient
Procedure ShowMessage(MessageText, Wait = False, IsError = False)
	
	Items.Explanation.Title = MessageText;
	If IsError Then 
		Items.Explanation.TextColor = WebColors.Red;
	Else
		Items.Explanation.TextColor = Items.RepeatCode.TextColor;
	EndIf;	
	
	If Items.TimeConsumingOperationIndicator.Visible <> Wait Then
		Items.TimeConsumingOperationIndicator.Visible = Wait;
	EndIf;	
	
EndProcedure

&AtClient
Procedure GetTemporaryPasswordAfterExecution(Result, IncomingContext) Export
	
	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		Timer = Result.ExecutionResult.DelayBeforeResending;
		If Result.ExecutionResult.Property("SessionID") Then 
			SessionID = Result.ExecutionResult.SessionID;
		EndIf;
		
		ShowMessage(NStr("vi = 'Mật khẩu đã được gửi đến số:';
						|ru = 'Пароль отправлен на номер:';
						|en = 'Password is sent to the number:'; fa = 'Password is sent to the number:';
						|it = 'Password inviata al numero:';
						|pl = 'Hasło zostało wysłano na numer:';
						|tr = 'Parola bu numaraya gönderildi:'") + " " + PhonePresentation(Recipient));

		StartPhoneCodeCountdown(Timer, 600);
		FormControl(ThisObject);
		
	Else
		ShowMessage(NStr("vi = 'Dịch vụ gửi tin nhắn SMS tạm thời không khả dụng.';
						|ru = 'Сервис отправки SMS-сообщений временно недоступен.';
						|en = 'SMS message sending service is temporarily unavailable.'; fa = 'SMS message sending service is temporarily unavailable.';
						|it = 'Servizio di invio di SMS temporaneamente non disponibile.';
						|pl = 'Serwis wysyłki wiadomości SMS jest czasowo niedostępny.';
						|tr = 'SMS Mesajlama servisi geçici olarak kullanılamıyor.'"), , True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckPhoneCode(CurrentCode)
	
	If AuthorizationStep <> 2 Then
		DisableCountdown = 99;
		
	ElsIf CheckInProgress Then
		CodeStatus 	= NStr("vi = 'Đang chờ phản hồi';
								|ru = 'Ожидается ответ';
								|en = 'Waiting for response'; fa = 'Waiting for response';
								|it = 'In attesa di risposta';
								|pl = 'Oczekuje się odpowiedź';
								|tr = 'Yanıt bekleniyor'");
		DisableCountdown = 10;
		
	ElsIf DisableCountdown = 99 Then
		CodeStatus 	= NStr("vi = 'Cần lặp lại thủ tục';
								|ru = 'Необходимо повторить процедуру';
								|en = 'Repeat the procedure'; fa = 'Repeat the procedure';
								|it = 'È necessario ripetere la procedura';
								|pl = 'Należy powtórzyć procedurę';
								|tr = 'Prosedürü tekrarlayın'");
		
	ElsIf ValueIsFilled(CurrentCode) And StrLen(CurrentCode) = 6 Then
		CheckInProgress = True;
		ShowMessage(NStr("vi = 'Đang xác minh mật khẩu';
						|ru = 'Выполняется проверка пароля';
						|en = 'Checking the password'; fa = 'Checking the password';
						|it = 'Verifica della password in corso';
						|pl = 'Trwa weryfikacja hasła';
						|tr = 'Parola kontrol ediliyor'"), True);
		Notification 			= New CallbackDescription("ConfirmPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, ConfirmOnServer(SessionID));
		
	ElsIf ValueIsFilled(CurrentCode) And StrLen(CurrentCode) <> 6 Then
		CodeStatus 	= NStr("vi = 'Mật khẩu phải có 6 chữ số';
								|ru = 'Пароль должен быть из 6 цифр';
								|en = 'The password must contain 6 digits'; fa = 'The password must contain 6 digits';
								|it = 'La password deve contenere 6 cifre';
								|pl = 'Hasło powinno zawierać 6 cyfr';
								|tr = 'Parola, 6 rakamdan oluşmalıdır'");
		DisableCountdown = 10;
		
	Else
		CodeStatus 	= NStr("vi = 'Chưa chỉ ra mật khẩu';
								|ru = 'Пароль не указан';
								|en = 'Password is not specified'; fa = 'Password is not specified';
								|it = 'Password non indicata';
								|pl = 'Nie wskazano hasła';
								|tr = 'Parola belirtilmedi'");
		DisableCountdown = 10;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GetSettingsForGettingTemporaryPasswordsAfterExecution(Result, IncomingContext) Export
	
	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		PhoneSettings   = Result.ExecutionResult;
		Recipient 			= PhoneSettings.Phone;
		ShowMessage("", False);
		CheckNextStep();
		
	Else	
		ShowMessage(NStr("vi = 'Tạm thời không sử dụng được dịch vụ gửi tin nhắn SMS. Hãy thử lại sau.';
						|ru = 'Сервис отправки SMS-сообщений временно недоступен. Повторите попытку позже.';
						|en = 'SMS service is temporarily unavailable. Try again later.'; fa = 'SMS service is temporarily unavailable. Try again later.';
						|it = 'Il servizio di invio SMS non è momentaneamente disponibile. Provare più tardi.';
						|pl = 'Serwis wysyłki wiadomości SMS jest czasowo niedostępny. Spróbuj ponownie później.';
						|tr = 'SMS mesajlaşma servisi geçici olarak kullanılamıyor. Lütfen daha sonra tekrar deneyin.'"), , True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterDisplayingWarning(IncomingContext) Export
	
	CloseOpen(Undefined);
	
EndProcedure

&AtClient
Procedure ChangePasswordVisibility(ForciblyHide = False)
	
	NewMode 	= Not Items.UserPassword.PasswordMode;
	Items.UserPassword.ChoiceButton = Not ArrayOfResources[0].Kind = PictureType.Empty;
	
	If ForciblyHide Then
		Items.UserPassword.ChoiceButtonPicture = ArrayOfResources[0];
		Items.UserPassword.PasswordMode = True;
		
	ElsIf Not NewMode Then
		Items.UserPassword.ChoiceButtonPicture = ArrayOfResources[1];
		Items.UserPassword.PasswordMode = NewMode;
		
	EndIf;	
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Items 	= Form.Items;
	
	Items.PhoneCode.Enabled = Form.AuthorizationStep = 2;
	
EndProcedure

&AtServer
Function GetPasswordOnServer(Repeatedly = False, SessionID = Undefined)
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("CertificateID", CryptographyServiceInternal.Id(Certificate));
	ProcedureParameters.Insert("Resending", Repeatedly);
	ProcedureParameters.Insert("Type", "phone");
	ProcedureParameters.Insert("SessionID", SessionID);
	
	Return CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetTemporaryPassword", ProcedureParameters);
	
EndFunction

&AtServerNoContext
Function GetCurUserData()
	
	Result = New Structure("Login, StoredPasswordValue");
	
	SetPrivilegedMode(True);
	
	CurrentUser 		= Users.AuthorizedUser();
	UserIdentificator 	= Common.ObjectAttributeValue(CurrentUser, "IBUserID");
	UserProperties 		= Users.IBUserProperies(UserIdentificator);
	
	If UserProperties <> Undefined Then
		Result.Login 					= UserProperties.Name;
		Result.StoredPasswordValue = UserProperties.StoredPasswordValue;
	EndIf;	
	
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function VerifyUserPassword(StoredPasswordValue, CurrentPassword)
	
	Result = False;
	
	If Not ValueIsFilled(StoredPasswordValue) And IsBlankString(CurrentPassword) Then
		Result = True;
		
	ElsIf ValueIsFilled(StoredPasswordValue) Then
		IBUser = InfoBaseUsers.CurrentUser();
		If CommonClientServer.HasAttributeOrObjectProperty(IBUser, "PasswordHashAlgorithmType") Then
			CallParameters = New Structure();
			CallParameters.Insert("UserSecret", CurrentPassword);
			CallParameters.Insert("IBUser", IBUser);
			Result = Common.CalculateInSafeMode(
				"CheckUserPasswordComplianceWithStoredValue(Parameters.UserSecret, Parameters.IBUser)",
				CallParameters);
		Else
			Result = StoredPasswordValue = Users.PasswordHashString(CurrentPassword);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure ReflectChangesServer()
	
	DigitalSignatureSaaS.ConfigureUseOfLongTermToken(Enums.CryptoOperationsConfirmationMethods.LongLivedToken, Certificate);
	
EndProcedure	

&AtServerNoContext
Procedure SaveSecurityTokens(Val SecurityTokens)
	
	SetPrivilegedMode(True);
	CryptographyServiceInternal.SaveSecurityTokens(SecurityTokens);
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Function ConfirmOnServer(SessionID = Undefined)
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("CertificateID", CryptographyServiceInternal.Id(Certificate));
	ProcedureParameters.Insert("TemporaryPassword", PhoneCode);
	ProcedureParameters.Insert("SessionID", SessionID);
	
	Return CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetSessionKey", ProcedureParameters);
	
EndFunction

&AtServerNoContext
Function PhonePresentation(CurrentPhone)
	
	Result   = TrimAll(CurrentPhone);
	Counter 	= StrLen(Result);
	DigitsTotal	= 0;
	
	While Counter > 0 Do
		IsDigit    = StrFind("0123456789", Mid(Result, Counter, 1))  > 0;
		If IsDigit Then
			DigitsTotal = DigitsTotal + 1;
		EndIf;
		
		If DigitsTotal > 2 And IsDigit Then
			Result = Mid(Result, 1, Counter - 1) + "*" + Mid(Result, Counter + 1);
		EndIf;
		
		If DigitsTotal >= 7 Then
			Break;
		EndIf;
		
		Counter 	= Counter - 1;
		
	EndDo;	
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function PrepareArrayOfResources()
	
	Result = New Array;
	Result.Add(GetLibraryImage("VisibilityClosed"));
	Result.Add(GetLibraryImage("VisibilityOpen"));
	Result.Add(PredefinedValue("Enum.CryptoOperationsConfirmationMethods.LongLivedToken"));
	
	Return Result;

EndFunction

&AtServerNoContext
Function GetLibraryImage(IconName)
	
	If Metadata.CommonPictures.Find(IconName) <> Undefined Then
		Result = PictureLib[IconName];
	Else
		Result = New Picture;
	EndIf;	
	
	Return Result;
	
EndFunction

&AtClient
Procedure ConfirmPasswordAfterExecution(Result, IncomingContext) Export

	Result 			= CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	CheckInProgress = False;
	
	ShowMessage("", False);
	
	If Result.Completed2 Then
		SaveSecurityTokens(Result.ExecutionResult);
		CodeStatus		= NStr("vi = 'Mật khẩu là chính xác.';
								|ru = 'Указан верный пароль';
								|en = 'Password is correct'; fa = 'Password is correct';
								|it = 'Password corretta';
								|pl = 'Podano prawidłowe hasło';
								|tr = 'Parola doğru'");
		CheckNextStep();
		FormControl(ThisObject);
		
	Else
		ExceptionText = ErrorProcessing.DetailErrorDescription(Result.ErrorInfo);
		If StrFind(ExceptionText, "PasswordIsIncorrect") Then
			CodeStatus = NStr("vi = 'Sai mật khẩu';
								|ru = 'Указан неверный пароль';
								|en = 'Password is incorrect'; fa = 'Password is incorrect';
								|it = 'Password errata';
								|pl = 'Wskazano nieprawidłowe hasło';
								|tr = 'Parola hatalı'");
			DisableCountdown = 10;
		ElsIf StrFind(ExceptionText, "ExceededNumberOfAttemptsToEnterPassword") Then
			CodeStatus = NStr("vi = 'Vượt quá hạn mức';
								|ru = 'Превышен лимит попыток';
								|en = 'Attempt limit exceeded'; fa = 'Attempt limit exceeded';
								|it = 'Limite tentativi superato';
								|pl = 'Przekroczono limit prób';
								|tr = 'Deneme sınırı aşıldı'"); 
			SessionID = "";
			DisableCountdown = 99;
		ElsIf StrFind(ExceptionText, "PasswordExpired") Then
			CodeStatus = NStr("vi = 'Đã hết hạn thời hạn hiệu lực của mật khẩu';
								|ru = 'Срок действия пароля истек';
								|en = 'Password expired'; fa = 'Password expired';
								|it = 'Il periodo di validità della password è scaduto';
								|pl = 'Termin ważności hasła upłynął';
								|tr = 'Parolanın süresi doldu'");
			SessionID = "";
			DisableCountdown = 99;
		Else 
			CodeStatus = NStr("vi = 'Tạm thời không thể thực hiện thao tác';
								|ru = 'Выполнение операции временно невозможно';
								|en = 'Operation temporarily cannot be executed'; fa = 'Operation temporarily cannot be executed';
								|it = 'È momentaneamente impossibile eseguire l''operazione';
								|pl = 'Wykonanie operacji jest czasowo niemożliwe';
								|tr = 'İşlem geçici olarak mümkün değil'");
			DisableCountdown = 99;
		EndIf;		
	EndIf;
	
EndProcedure

#EndRegion