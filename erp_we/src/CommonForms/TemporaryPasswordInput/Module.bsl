#Region Variables

&AtClient
Var SessionID;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Certificate = Parameters.Certificate; // Data Formstructure - See CryptographyServiceInternalClient.GetSecurityToken 
	
	If Not ValueIsFilled(Certificate) Then
		Cancel = True;
		Return;
	EndIf;
	
	PasswordsDeliveryMethod = "phone";
	
	ProcedureParameters = New Structure("CertificateID", CryptographyServiceInternal.Id(Certificate));
	
	TimeConsumingOperation = CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetSettingsForGettingTemporaryPasswords", ProcedureParameters);
	
	UseToken = DigitalSignatureSaaS.LongTermTokenUsageIsPossible();
	PasswordBeingSent = True;
	Items.GetTempPasswordUsingAnotherMethod.Visible = False;	
	Phone = "...";
	
	Items.ConfigureConfirmation.Title = GetSettingsHeader(UseToken, NStr("vi = 'Thay đổi người nhận';
																		|ru = 'Изменить получателя';
																		|en = 'Change recipient'; fa = 'تغییر گیرنده';
																		|it = 'Modifica il destinatario';
																		|pl = 'Zmień odbiorcę';
																		|tr = 'Alıcıyı değiştir'"));
	Items.ConfigureConfirmation.ExtendedTooltip.Title = ?(UseToken, 
				NStr("vi = 'Thay đổi cài đặt xác nhận thao tác chính';
					|ru = 'Изменить настройки подтверждения операций с ключом';
					|en = 'Change settings of confirming operations with the key'; fa = 'تغییر تنظیمات تأیید عملیات با کلید';
					|it = 'Modificare le impostazioni di conferma delle operazioni con la chiave';
					|pl = 'Zmień ustawienia potwierdzenia operacji z kluczem';
					|tr = 'Tuş işlemi doğrulama ayarlarını değiştir'"), "");
	Items.TimeConsumingOperationIndicator.Picture = GetLibraryImage("TimeConsumingOperation16");
	Items.TimeConsumingOperationIndicator2.Picture = GetLibraryImage("TimeConsumingOperation16");

	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SessionID = Undefined;
	Notification = New CallbackDescription("GetSettingsForGettingTemporaryPasswordsAfterExecution", ThisObject);
	CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, TimeConsumingOperation);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PasswordOnChange(Item)
	
	If Items.PasswordGroup.Enabled Then 
		PasswordEditTextChange(Item, Item.EditText, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure PasswordEditTextChange(Item, Text, StandardProcessing)
	
	Password = TrimAll(Text);
	If ValueIsFilled(Password) And StrLen(Password) = 6 Then
		DetachIdleHandler("Attachable_VerifyPassword");
		AttachIdleHandler("Attachable_VerifyPassword", 0.5, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseOpen(FormParameters)
	
	DetachIdleHandler("Attachable_VerifyPassword");
	If IsOpen() Then 
		Close(FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ResendPassword(Command)

	Password = Undefined;
	Notification = New CallbackDescription("GetTemporaryPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, GetPasswordOnServer(True, SessionID));
		
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure Confirm(Command)
	
	DetachIdleHandler("Attachable_VerifyPassword");
	ClearMessages();
	ErrorText = "";
	Password = TrimAll(Password);
	If ValueIsFilled(Password) And StrLen(Password) = 6 Then
		Notification = New CallbackDescription("ConfirmPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, ConfirmOnServer(SessionID));
		FormControl(ThisObject);
	ElsIf ValueIsFilled(Password) And StrLen(Password) <> 6 Then
		ErrorText = NStr("vi = 'Mật khẩu cần có 6 chữ số';
						|ru = 'Пароль должен состоять из 6 цифр';
						|en = 'The password must contain 6 digits'; fa = 'The password must contain 6 digits';
						|it = 'La password deve contenere 6 cifre';
						|pl = 'Hasło musi zawierać 6 cyfr';
						|tr = 'Parola, 6 rakamdan oluşmalıdır'");
	Else
		ErrorText = NStr("vi = 'Chưa chỉ ra mật khẩu';
						|ru = 'Пароль не указан';
						|en = 'Password is not specified'; fa = 'Password is not specified';
						|it = 'Password non indicata';
						|pl = 'Nie wskazano hasła';
						|tr = 'Parola belirtilmedi'");
	EndIf;

EndProcedure

&AtClient
Procedure GetTempPasswordUsingAnotherMethod(Command)
	
	If PasswordsDeliveryMethod = "phone" Then
		PasswordsDeliveryMethod = "email";
	Else
		PasswordsDeliveryMethod = "phone";
	EndIf;
	
	ResendPassword(Undefined);
	
	FormControl(ThisObject);

EndProcedure

&AtClient
Procedure ConfigureConfirmation(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Certificate", Certificate);
	If UseToken Then
		FormParameters.Insert("State", "ChangingMethodOfConfirmingCryptoOperation");
	Else
		FormParameters.Insert("State", "ChangingSettingsForGettingTemporaryPasswords");
	EndIf;	
	
	CloseOpen(FormParameters);

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ConfirmPasswordAfterExecution(Result, IncomingContext) Export

	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		SaveSecurityTokens(Result.ExecutionResult);
		CloseOpen(New Structure("State", "PasswordAccepted"));
	Else
		PasswordBeingChecked = False;
		FormControl(ThisObject);
		
		ExceptionText = ErrorProcessing.DetailErrorDescription(Result.ErrorInfo);
		If StrFind(ExceptionText, "PasswordIsIncorrect") Then
			ErrorText = NStr("vi = 'Đã chỉ ra sai mật khẩu';
							|ru = 'Указан неверный пароль';
							|en = 'Password is incorrect'; fa = 'Password is incorrect';
							|it = 'Password errata';
							|pl = 'Wskazano nieprawidłowe hasło';
							|tr = 'Parola hatalı'");
		ElsIf StrFind(ExceptionText, "ExceededNumberOfAttemptsToEnterPassword") Then
			CloseOpen(New Structure("State, ErrorDescription", "PasswordNotAccepted", NStr("vi = 'Đã vượt quá số lần thử nhập mật khẩu';
																							|ru = 'Превышен лимит попыток ввода пароля';
																							|en = 'Exceeded number of attempts to enter password'; fa = 'Exceeded number of attempts to enter password';
																							|it = 'Numero massimo di tentativi di inserimento password superato';
																							|pl = 'Przekroczono limit prób wprowadzenia hasła';
																							|tr = 'Parola deneme sınırı aşıldı'"))); 
		ElsIf StrFind(ExceptionText, "PasswordExpired") Then
			CloseOpen(New Structure("State, ErrorDescription", "PasswordNotAccepted", NStr("vi = 'Đã hết hạn thời hạn hiệu lực của mật khẩu';
																							|ru = 'Срок действия пароля истек';
																							|en = 'Password expired'; fa = 'Password expired';
																							|it = 'Il periodo di validità della password è scaduto';
																							|pl = 'Termin ważności hasła upłynął';
																							|tr = 'Parolanın süresi doldu'")));
		Else 
			CloseOpen(New Structure("State, ErrorDescription", "PasswordNotAccepted", NStr("vi = 'Tạm thời không thể thực hiện thao tác';
																							|ru = 'Выполнение операции временно невозможно';
																							|en = 'Operation temporarily cannot be executed'; fa = 'Operation temporarily cannot be executed';
																							|it = 'È momentaneamente impossibile eseguire l''operazione';
																							|pl = 'Wykonanie operacji jest czasowo niemożliwe';
																							|tr = 'İşlem geçici olarak mümkün değil'")));
		EndIf;		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SaveSecurityTokens(Val SecurityTokens)
	
	SetPrivilegedMode(True);
	CryptographyServiceInternal.SaveSecurityTokens(SecurityTokens);
	SetPrivilegedMode(False);
	
EndProcedure

&AtClient
Procedure GetSettingsForGettingTemporaryPasswordsAfterExecution(Result, IncomingContext) Export
	
	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		Phone          = Result.ExecutionResult.Phone;
		Email = Result.ExecutionResult.Email;
		
		Recipient = Phone;
		
		Notification = New CallbackDescription("GetTemporaryPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, GetPasswordOnServer());
	Else
		ErrorData = GetErrorDetails(Result.ErrorInfo);
		Notification = New CallbackDescription("AfterDisplayingWarning", ThisObject, ErrorData);
		ShowMessageBox(Notification, ErrorData.Information);		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterDisplayingWarning(IncomingContext) Export
	
	CloseOpen(IncomingContext);
	
EndProcedure

&AtClient
Procedure GetTemporaryPasswordAfterExecution(Result, IncomingContext) Export
	
	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		Timer = Result.ExecutionResult.DelayBeforeResending;
		PasswordSent = True;
		PasswordBeingSent = False;
		If Result.ExecutionResult.Property("SessionID") Then 
			SessionID = Result.ExecutionResult.SessionID;
		EndIf;
		StartCountdown();
		FormControl(ThisObject);
		AttachIdleHandler("Attachable_ActivatePasswordField", 0.1, True);
	Else
		Notification = New CallbackDescription("AfterDisplayingWarning", ThisObject);
		ShowMessageBox(Notification, NStr("vi = 'Tạm thời không sử dụng được dịch vụ gửi tin nhắn SMS. Hãy thử lại sau.';
											|ru = 'Сервис отправки SMS-сообщений временно недоступен. Повторите попытку позже.';
											|en = 'SMS service is temporarily unavailable. Try again later.'; fa = 'SMS service is temporarily unavailable. Try again later.';
											|it = 'Il servizio di invio SMS non è momentaneamente disponibile. Provare più tardi.';
											|pl = 'Serwis wysyłki wiadomości SMS jest czasowo niedostępny. Spróbuj ponownie później.';
											|tr = 'SMS mesajlaşma servisi geçici olarak kullanılamıyor. Lütfen daha sonra tekrar deneyin.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_VerifyPassword()
	
	Confirm(Undefined);
	
EndProcedure

&AtClient
Procedure Attachable_ActivatePasswordField()
	
	Password = Undefined;
	Items.Password.UpdateEditText();
	CurrentItem = Items.Password;
	
EndProcedure

&AtServer
Function GetPasswordOnServer(Repeatedly = False, SessionID = Undefined)
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("CertificateID", CryptographyServiceInternal.Id(Certificate));
	ProcedureParameters.Insert("Resending", Repeatedly);
	ProcedureParameters.Insert("Type", PasswordsDeliveryMethod);
	ProcedureParameters.Insert("SessionID", SessionID);
	
	Return CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetTemporaryPassword", ProcedureParameters);
	
EndFunction

&AtClient
Procedure StartCountdown()
	
	AttachIdleHandler("Attachable_HandlerCountdown", 1, True);
	
EndProcedure

&AtClient
Procedure Attachable_HandlerCountdown()
	
	Timer = Timer - 1;
	If Timer >= 0 Then
		CountdownLabel = StrTemplate(NStr("vi = 'Có thể sẽ hỏi lại mật khẩu sau %1 giây.';
											|ru = 'Запросить пароль повторно можно будет через %1 сек.';
											|en = 'You can request the password again in %1 sec.'; fa = 'You can request the password again in %1 sec.';
											|it = 'È possibile richiedere la password tra %1 sec.';
											|pl = 'Ponownie poprosić o hasło można będzie przez %1 sek.';
											|tr = 'Parolayı %1 saniye içinde tekrar isteyebilirsiniz.'"), Timer);
		AttachIdleHandler("Attachable_HandlerCountdown", 1, True);		
	Else
		CountdownLabel = "";
		PasswordSent = False;		
		NewTitle	= NStr("vi = 'Thay đổi địa chỉ';
							|ru = 'Изменить адрес';
							|en = 'Change address'; fa = 'Change address';
							|it = 'Modificare indirizzo';
							|pl = 'Zmień adres';
							|tr = 'Adresi değiştir'");
		Items.GetTempPasswordUsingAnotherMethod.Visible = ValueIsFilled(Email);
		Items.ConfigureConfirmation.Title = GetSettingsHeader(UseToken, NewTitle);
		
		FormControl(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Function GetErrorDetails(ErrorData)
	
	ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorData);
	
	Result = New Structure();
	Result.Insert("State", "PasswordNotAccepted");
	Result.Insert("Information", NStr("vi = 'Tạm thời không sử dụng được dịch vụ gửi tin nhắn SMS. Hãy thử lại sau.';
										|ru = 'Сервис отправки SMS-сообщений временно недоступен. Повторите попытку позже.';
										|en = 'SMS service is temporarily unavailable. Try again later.'; fa = 'SMS service is temporarily unavailable. Try again later.';
										|it = 'Il servizio di invio SMS non è momentaneamente disponibile. Provare più tardi.';
										|pl = 'Serwis wysyłki wiadomości SMS jest czasowo niedostępny. Spróbuj ponownie później.';
										|tr = 'SMS mesajlaşma servisi geçici olarak kullanılamıyor. Lütfen daha sonra tekrar deneyin.'"));
	Result.Insert("ErrorDescription", ExceptionText);
	
	If StrFind(ExceptionText, "InvalidCertificateIdError") Then
		Position = StrFind(ExceptionText, "Invalid certificate id");
		If Position > 0 Then
			Result.Insert("ErrorDescription", NStr("vi = 'Không tìm thấy chứng chỉ trong chương trình';
													|ru = 'Не обнаружен сертификат в программе';
													|en = 'The certificate is not found in the application'; fa = 'The certificate is not found in the application';
													|it = 'Certificato non rilevato nel programma';
													|pl = 'Nie wykryto certyfikatu w programie';
													|tr = 'Programda sertifika bulunamadı'") + ": " + Mid(ExceptionText, Position + 23, 40) + ".");
		Else	
			Result.Insert("ErrorDescription", NStr("vi = 'Không tìm thấy chứng chỉ trong chương trình.';
													|ru = 'Не обнаружен сертификат в программе.';
													|en = 'The certificate is not found in the application.'; fa = 'The certificate is not found in the application.';
													|it = 'Certificato non rilevato nel programma.';
													|pl = 'Nie wykryto certyfikatu w programie.';
													|tr = 'Programda sertifika bulunamadı.'"));
		EndIf;	
		Result.Insert("Information", NStr("vi = 'Không tìm thấy chứng chỉ được chỉ định trong chương trình.';
											|ru = 'Указанный сертификат не обнаружен в программе.';
											|en = 'The specified certificate is not found in the application.'; fa = 'The specified certificate is not found in the application.';
											|it = 'Il certificato indicato non è stato rilevato nel programma.';
											|pl = 'Nie wykryto podanego certyfikatu w programie.';
											|tr = 'Belirtilen sertifika programda bulunamadı.'"));
	EndIf;

	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function GetSettingsHeader(CurrentMode, NewTitle)
	
	Result = "Settings";
	If Not CurrentMode Then
		Result = NewTitle;
	EndIf;
	
	Return Result;
	
EndFunction	

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Items = Form.Items;
	
	Items.CountdownLabel.Visible = Form.PasswordSent;	
	Items.ResendPassword.Visible = Not Form.PasswordSent And Not Form.PasswordBeingSent;
	Items.IndentDecoration.Visible = Items.GetTempPasswordUsingAnotherMethod.Visible;
	
	CommandText = NStr("vi = 'Gửi mật khẩu đến %1';
						|ru = 'Отправить пароль на %1';
						|en = 'Send password to %1'; fa = 'Send password to %1';
						|it = 'Inviare password a %1';
						|pl = 'Wyślij hasło na %1';
						|tr = 'Parolayı %1 gönderin'");
	If Form.PasswordsDeliveryMethod = "phone" Then
		If Form.PasswordBeingSent Then
			Items.Explanation.Title = NStr("vi = 'Đang gửi mật khẩu qua tin nhắn SMS đến số';
											|ru = 'Выполняется отправка пароля в SMS-сообщении на номер';
											|en = 'Sending SMS message with password to the number'; fa = 'Sending SMS message with password to the number';
											|it = 'Invio in corso della password tramite SMS al numero';
											|pl = 'Trwa wysyłanie hasła w wiadomości SMS na numer';
											|tr = 'Parola SMS ile bu numaraya gönderiliyor'");
		Else
			Items.Explanation.Title = NStr("vi = 'Đã gửi mật khẩu qua tin nhắn SMS đến số';
											|ru = 'Пароль отправлен в SMS-сообщении на номер';
											|en = 'SMS message with password is sent to the number'; fa = 'SMS message with password is sent to the number';
											|it = 'Passowrd inviata tramite SMS al numero';
											|pl = 'Hasło zostało wysłane w wiadomości SMS na numer';
											|tr = 'Parola SMS ile bu numaraya gönderildi'");
		EndIf;
		NewTitle = NStr("vi = 'Thay đổi số';
						|ru = 'Изменить номер';
						|en = 'Change number'; fa = 'تغییر شماره';
						|it = 'Modificare numero';
						|pl = 'Zmień numer';
						|tr = 'Numarayı değiştir'");
		Items.ConfigureConfirmation.Title = GetSettingsHeader(Form.UseToken, NewTitle);
		Items.GetTempPasswordUsingAnotherMethod.Title = StrTemplate(CommandText, Form.Email);
		Form.Recipient = Form.Phone;
		Items.Password.InputHint = NStr("vi = 'Hãy nhập mật khẩu từ tin nhắn';
										|ru = 'Введите пароль из SMS';
										|en = 'Enter password from the text message'; fa = 'رمز عبور پیامک را وارد کنید';
										|it = 'Inserisci la password dal SMS';
										|pl = 'Wpisz hasło z SMS';
										|tr = 'SMS''teki parolayı girin'");
	ElsIf Form.PasswordsDeliveryMethod = "email" Then
		If Form.PasswordBeingSent Then
			Items.Explanation.Title = NStr("vi = 'Đang gửi mật khẩu qua email đến địa chỉ';
											|ru = 'Выполняется отправка пароля в письме на адрес';
											|en = 'Sending password to email:'; fa = 'Sending password to email:';
											|it = 'Invio della password in corso tramite mail all''indirizzo';
											|pl = 'Trwa wysyłanie hasła mailem na adres';
											|tr = 'Parola bir e-posta ile bu adrese gönderiliyor'");
		Else
			Items.Explanation.Title = NStr("vi = 'Đã gửi mật khẩu qua email đến địa chỉ';
											|ru = 'Пароль отправлен в письме на адрес';
											|en = 'Password is sent to email:'; fa = 'Password is sent to email:';
											|it = 'Password inviata tramite mail all''indirizzo';
											|pl = 'Hasło zostało wysłane mailem na adres';
											|tr = 'Parola bir e-posta ile bu adrese gönderildi'");
		EndIf;	
		NewTitle = NStr("vi = 'Thay đổi địa chỉ';
						|ru = 'Изменить адрес';
						|en = 'Change address'; fa = 'Change address';
						|it = 'Modificare indirizzo';
						|pl = 'Zmień adres';
						|tr = 'Adresi değiştir'");
		Items.ConfigureConfirmation.Title = GetSettingsHeader(Form.UseToken, NewTitle);
		Items.GetTempPasswordUsingAnotherMethod.Title = StrTemplate(CommandText, Form.Phone);
		Form.Recipient = Form.Email;
		Items.Password.InputHint = NStr("vi = 'Hãy nhập mật khẩu từ email';
										|ru = 'Введите пароль из письма';
										|en = 'Enter password from the mail'; fa = 'Enter password from the mail';
										|it = 'Inserire la password contenuta nella mail';
										|pl = 'Wprowadź hasło z wiadomości mailowej';
										|tr = 'E-postadaki parolayı girin'");
	EndIf;

	Items.TimeConsumingOperationIndicator.Visible = Form.PasswordBeingSent
			And Items.TimeConsumingOperationIndicator.Picture.Type <> PictureType.Empty;
	Items.TimeConsumingOperationIndicator2.Visible = Form.PasswordBeingChecked 
			And Items.TimeConsumingOperationIndicator2.Picture.Type <> PictureType.Empty;
	
	Items.PasswordGroup.Enabled = Not Form.PasswordBeingSent And Not Form.PasswordBeingChecked;		
	Items.AdvancedGroup.Enabled = Not Form.PasswordBeingSent And Not Form.PasswordBeingChecked;
		
	Items.PasswordCheckLabel.Visible = Form.PasswordBeingChecked;
	Items.ErrorText.Visible = Not Form.PasswordBeingChecked;
	
EndProcedure

&AtServer
Function ConfirmOnServer(SessionID = Undefined)
	
	PasswordBeingChecked = True;

	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("CertificateID", CryptographyServiceInternal.Id(Certificate));
	ProcedureParameters.Insert("TemporaryPassword", Password);
	ProcedureParameters.Insert("SessionID", SessionID);
	
	Return CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetSessionKey", ProcedureParameters);
	
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

#EndRegion