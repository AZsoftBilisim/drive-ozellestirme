#Region Variables

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
	
	Certificate = Parameters.Certificate;
	
	If Not ValueIsFilled(Certificate) Then
		Cancel = True;
		Return;
	EndIf;
	
	PasswordsDeliveryMethod = "phone";
	
	ProcedureParameters = New Structure("CertificateID", CryptographyServiceInternal.Id(Certificate));
	
	TimeConsumingOperation = CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetSettingsForGettingTemporaryPasswords", ProcedureParameters);
	
	PasswordBeingSent = True;
	Items.FormOtherMethod.Visible = False;	
	Phone = "...";
	
	NewTitle 		= "";
	NewDetails 		= "";
	OperationParametersList 	= Undefined;
	Parameters.Property("OperationParametersList", OperationParametersList);
	
	If TypeOf(OperationParametersList) = Type("Structure") Then
		OperationParametersList.Property("Operation", NewTitle);
		OperationParametersList.Property("DataTitle", NewDetails);
	EndIf;
	
	If ValueIsFilled(NewTitle) Then
		Title = NewTitle;
	EndIf;
	
	If ValueIsFilled(NewDetails) Then
		Items.DetailsDecoration.Title = NewDetails;
	Else
		Items.DetailsDecoration.Visible = False;
	EndIf;
	
	Items.TimeConsumingOperationIndicator.Picture = GetLibraryImage("TimeConsumingOperation16");
	
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
Procedure DigitEditTextChange(Item, Text, StandardProcessing)
	
	StandardProcessing 	= True;
	
	If StrLen(Text) = 6 Then
		FinalNumber = TrimAll(Text);
		Digits = "";
		Items.Digits.UpdateEditText();
		ValidateEnteredCode(FinalNumber);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OtherMethod(Command)
	
	If PasswordsDeliveryMethod = "phone" Then
		PasswordsDeliveryMethod = "email";
	Else
		PasswordsDeliveryMethod = "phone";
	EndIf;
	
	SessionID = "";
	ResendPassword(False);
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure Settings(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Certificate", Certificate);
	FormParameters.Insert("State", "ChangingSettingsForGettingTemporaryPasswords");
	
	CloseOpen(FormParameters);
	
EndProcedure

&AtClient
Procedure SendAgain(Command)

	ResendPassword();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ResendPassword(Resending = True)

	Notification = New CallbackDescription("GetTemporaryPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, GetPasswordOnServer(Resending, SessionID));
		
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure GetSettingsForGettingTemporaryPasswordsAfterExecution(Result, IncomingContext) Export
	
	Result = CryptographyServiceInternalClient.GetBackgroundExecutionResult(Result);
	
	If Result.Completed2 Then
		Phone          = Result.ExecutionResult.Phone;
		Email = Result.ExecutionResult.Email;
		
		Notification = New CallbackDescription("GetTemporaryPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, GetPasswordOnServer());
		FormControl(ThisObject);
		
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
		CurrentItem = Items.Digits;
		#If MobileAppClient Then
			BeginEditingItem();
		#EndIf	
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
Procedure StartCountdown()
	
	AttachIdleHandler("Attachable_HandlerCountdown", 1, True);
	
EndProcedure

&AtClient
Procedure Attachable_HandlerCountdown()
	
	Timer 		= Timer - 1;
	Delay1	= Max(Delay1 - 1, 0);

	If Timer >= 0 Then
		If Delay1 = 0 Then
			ErrorState = StrTemplate(NStr("vi = 'Lặp lại sau %1 giây.';
											|ru = 'Повторить через %1 сек.';
											|en = 'Retry in %1 sec.'; fa = 'Retry in %1 sec.';
											|it = 'Ripetere tra %1 sec.';
											|pl = 'Powtórz po %1 sek.';
											|tr = '%1 saniye sonra tekrar dene'"), Timer);
		EndIf;	
		AttachIdleHandler("Attachable_HandlerCountdown", 1, True);		
	Else
		ErrorState = "";
		PasswordSent = False;		
		Items.FormOtherMethod.Visible = ValueIsFilled(Email);
		Items.FormSettings.Title = NStr("vi = 'Thay đổi địa chỉ';
										|ru = 'Изменить адрес';
										|en = 'Change address'; fa = 'Change address';
										|it = 'Modificare indirizzo';
										|pl = 'Zmień adres';
										|tr = 'Adresi değiştir'");
		
		FormControl(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseOpen(FormParameters)
	
	If IsOpen() Then 
		Close(FormParameters);
	EndIf;
	
EndProcedure

&AtServer
Function ConfirmOnServer(CurrentCode, SessionID = Undefined)
	
	PasswordBeingChecked = True;

	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("CertificateID", CryptographyServiceInternal.Id(Certificate));
	ProcedureParameters.Insert("TemporaryPassword", CurrentCode);
	ProcedureParameters.Insert("SessionID", SessionID);
	
	Return CryptographyServiceInternal.ExecuteInBackground(
		"CryptographyServiceInternal.GetSessionKey", ProcedureParameters);
	
EndFunction

&AtClient
Procedure AfterDisplayingWarning(IncomingContext) Export
	
	CloseOpen(Undefined);
	
EndProcedure

&AtClient
Procedure ValidateEnteredCode(CurrentCode)
	
	ErrorState = "";
	If ValueIsFilled(CurrentCode) And StrLen(CurrentCode) = 6 Then
		Notification = New CallbackDescription("ConfirmPasswordAfterExecution", ThisObject);
		CryptographyServiceInternalClient.WaitForExecutionCompletionInBackground(Notification, ConfirmOnServer(CurrentCode, SessionID));
		FormControl(ThisObject);
	ElsIf ValueIsFilled(CurrentCode) And StrLen(CurrentCode) <> 6 Then
		ErrorState = NStr("vi = 'Mật khẩu bao gồm 6 số';
							|ru = 'Пароль из 6 цифр';
							|en = '6-digit password'; fa = '6-digit password';
							|it = 'Пароль из 6 цифр';
							|pl = 'Hasło z 6 cyfr';
							|tr = '6 rakamlı parola'");
		Delay1		= 10;
	Else
		ErrorState = NStr("vi = 'Chưa chỉ ra mật khẩu';
							|ru = 'Пароль не указан';
							|en = 'Password is not specified'; fa = 'Password is not specified';
							|it = 'Пароль не указан';
							|pl = 'Nie wskazano hasła';
							|tr = 'Parola belirtilmedi'");
		Delay1		= 10;
	EndIf;
	
EndProcedure

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
			ErrorState = NStr("vi = 'Đã chỉ ra sai mật khẩu';
								|ru = 'Указан неверный пароль';
								|en = 'Password is incorrect'; fa = 'Password is incorrect';
								|it = 'Password errata';
								|pl = 'Wskazano nieprawidłowe hasło';
								|tr = 'Parola hatalı'");
			Delay1		= 10;
			CurrentItem = Items.Digits;
			#If MobileAppClient Then
				BeginEditingItem();
			#EndIf	
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

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Items = Form.Items;
	
	Items.SendAgain.Enabled = Not Form.PasswordSent And Not Form.PasswordBeingSent;
	
	CommandText 	= NStr("vi = 'Gửi mật khẩu đến %1';
							|ru = 'Отправить пароль на %1';
							|en = 'Send password to %1'; fa = 'Send password to %1';
							|it = 'Inviare password a %1';
							|pl = 'Wyślij hasło na %1';
							|tr = 'Parolayı %1 gönderin'");
	SubjectOfSubmission	= "";
	If Form.PasswordsDeliveryMethod = "phone" Then
		If Form.PasswordBeingSent Then
			SubjectOfSubmission = NStr("vi = 'Đang gửi mật khẩu qua tin nhắn SMS đến số';
										|ru = 'Выполняется отправка пароля в SMS-сообщении на номер';
										|en = 'Sending SMS message with password to the number'; fa = 'Sending SMS message with password to the number';
										|it = 'Invio in corso della password tramite SMS al numero';
										|pl = 'Trwa wysyłanie hasła w wiadomości SMS na numer';
										|tr = 'Parola SMS ile bu numaraya gönderiliyor'");
		Else
			SubjectOfSubmission = NStr("vi = 'Đã gửi mật khẩu qua tin nhắn SMS đến số';
										|ru = 'Пароль отправлен в SMS-сообщении на номер';
										|en = 'SMS message with password is sent to the number'; fa = 'SMS message with password is sent to the number';
										|it = 'Passowrd inviata tramite SMS al numero';
										|pl = 'Hasło zostało wysłane w wiadomości SMS na numer';
										|tr = 'Parola SMS ile bu numaraya gönderildi'");
		EndIf;
		Items.FormSettings.Title = NStr("vi = 'Thay đổi số';
										|ru = 'Изменить номер';
										|en = 'Change number'; fa = 'تغییر شماره';
										|it = 'Modificare numero';
										|pl = 'Zmień numer';
										|tr = 'Numarayı değiştir'");
		Items.FormOtherMethod.Title = StrTemplate(CommandText, Form.Email);
		SubjectOfSubmission = SubjectOfSubmission + Chars.LF + Form.Phone;
	ElsIf Form.PasswordsDeliveryMethod = "email" Then
		If Form.PasswordBeingSent Then
			SubjectOfSubmission = NStr("vi = 'Đang gửi mật khẩu qua email đến địa chỉ';
										|ru = 'Выполняется отправка пароля в письме на адрес';
										|en = 'Sending password to email:'; fa = 'Sending password to email:';
										|it = 'Invio della password in corso tramite mail all''indirizzo';
										|pl = 'Trwa wysyłanie hasła mailem na adres';
										|tr = 'Parola bir e-posta ile bu adrese gönderiliyor'");
		Else
			SubjectOfSubmission = NStr("vi = 'Đã gửi mật khẩu qua email đến địa chỉ';
										|ru = 'Пароль отправлен в письме на адрес';
										|en = 'Password is sent to email:'; fa = 'Password is sent to email:';
										|it = 'Password inviata tramite mail all''indirizzo';
										|pl = 'Hasło zostało wysłane mailem na adres';
										|tr = 'Parola bir e-posta ile bu adrese gönderildi'");
		EndIf;	
		Items.FormSettings.Title = NStr("vi = 'Thay đổi địa chỉ';
										|ru = 'Изменить адрес';
										|en = 'Change address'; fa = 'Change address';
										|it = 'Modificare indirizzo';
										|pl = 'Zmień adres';
										|tr = 'Adresi değiştir'");
		Items.FormOtherMethod.Title = StrTemplate(CommandText, Form.Phone);
		SubjectOfSubmission = SubjectOfSubmission + Chars.LF + Form.Email;
	EndIf;
	
	Form.CurrentStatus = SubjectOfSubmission;
	Items.TimeConsumingOperationIndicator.Visible = Form.PasswordBeingSent Or Form.PasswordBeingChecked;
	Items.CodeGroup.Enabled = Not Form.PasswordBeingSent And Not Form.PasswordBeingChecked;		
	Items.CommandGroup.Enabled = Not Form.PasswordBeingSent And Not Form.PasswordBeingChecked;
		
EndProcedure

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
