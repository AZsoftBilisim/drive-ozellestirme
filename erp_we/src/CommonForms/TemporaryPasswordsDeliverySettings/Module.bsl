#Region Variables

&AtClient
Var CloseProgrammatically;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	FillInVariablesForPhoneAndEmailVerification(ThisObject);

	Certificate = Parameters.Certificate;

	// "Change" - full verification, "Confirmation" - only checking new phones
	CheckMode = "Update";
	If Parameters.Property("CheckMode") Then
		CheckMode = Parameters.CheckMode;
	EndIf;

	If CheckMode = "Update" Then
		Result = CryptographyService.GetSettingsForGettingTemporaryPasswords(CryptographyServiceInternal.Id(Certificate));
		PhoneForPasswords = Result.Phone;
		EmailForPasswords = Result.Email;
	Else
		Items.PhoneForPasswords.AutoMarkIncomplete = True;
	EndIf;

	ConfirmPhoneNumberForPasswords.SourceValue = PhoneForPasswords;
	ConfirmEmailForPasswords.SourceValue = EmailForPasswords;

	InstallLabels();

	FormControl(ThisObject);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	AttachIdleHandler("Attachable_UpdateFieldTexts", 0.1, True);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	If CloseProgrammatically <> True Then
		CloseProgrammatically = True;
		Cancel = True;

		CloseForm();
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PhoneChangeConfirmationNoteURLProcessing(Item,
		FormattedStringURL, StandardProcessing)

	StandardProcessing = False;

	FormParameters = New Structure;
	FormParameters.Insert("Certificate", Certificate);
	FormParameters.Insert("NewPhone", "");

	If ConfirmPhoneNumberForPasswords.ConfirmationCompleted Then
		FormParameters.Insert("NewPhone", PhoneForPasswords);
		FormParameters.Insert("CheckID", ConfirmPhoneNumberForPasswords.CheckID);
	EndIf;

	OpenForm("CommonForm.PhoneNumberChange", FormParameters, ThisObject);

EndProcedure

&AtClient
Procedure PhoneForPasswordsOnChange(Item)

	PhoneForPasswordsEditTextChange(Item, Item.EditText, True);

EndProcedure

&AtClient
Procedure PhoneForPasswordsEditTextChange(Item, Text, StandardProcessing)

	ClearMessages();

	Presentation = DigitalSignatureSaaSClientServer.GetPhonePresentation(Text);
	PhoneForPasswords = Presentation;

	ConfirmPhoneNumberForPasswords.ValueEntered = ValueIsFilled(Presentation)
		And Presentation <> ConfirmPhoneNumberForPasswords.SourceValue;
	If Not ValueIsFilled(Presentation) Then
		PhoneForPasswords = Text;
	EndIf;

	DetachIdleHandler("Attachable_HandlerCountdown");
	DetachIdleHandler("Attachable_UpdateYourPhoneForPasswords");
	AttachIdleHandler("Attachable_UpdateYourPhoneForPasswords", 1, True);

EndProcedure

&AtClient
Procedure ConfirmationCodePhoneNumberOnChange(Item)

	ConfirmationCodePhoneNumberEditTextChange(Item, Item.EditText, True);

EndProcedure

&AtClient
Procedure ConfirmationCodePhoneNumberEditTextChange(Item, Text, StandardProcessing)

	If StrLen(TrimAll(Text)) = 6 Then
		ConfirmationCode = TrimAll(Text);
		AttachIdleHandler("Attachable_CheckConfirmationCode", 0.5, True);
	EndIf;

EndProcedure

&AtClient
Procedure EmailForPasswordsOnChange(Item)

	EmailForPasswordsEditTextChange(Item, Item.EditText, True);

EndProcedure

&AtClient
Procedure EmailForPasswordsEditTextChange(Item,
		Text, StandardProcessing)

	Presentation = TrimAll(Text);
	EmailForPasswords = Presentation;

	ConfirmEmailForPasswords.ValueEntered = CommonClientServer.EmailAddressMeetsRequirements(Presentation)
		And Presentation <> ConfirmPhoneNumberForPasswords.SourceValue;

	DetachIdleHandler("Attachable_HandlerCountdown");
	DetachIdleHandler("Attachable_UpdateEmailForPasswords");
	AttachIdleHandler("Attachable_UpdateEmailForPasswords", 1, True);

EndProcedure

&AtClient
Procedure ConfirmationCodeEmailOnChange(Item)

	ConfirmationCodeEmailEditTextChange(Item, Item.EditText, True);

EndProcedure

&AtClient
Procedure ConfirmationCodeEmailEditTextChange(Item, Text, StandardProcessing)

	If StrLen(TrimAll(Text)) = 6 Then
		ConfirmationCode = TrimAll(Text);
		AttachIdleHandler("Attachable_CheckConfirmationCode", 0.5, True);
	EndIf;

EndProcedure

&AtClient
Procedure ConfirmationCodeOldPhoneNumberOnChange(Item)

	ConfirmationCodeOldPhoneNumberEditTextChange(Item, Item.EditText, True);

EndProcedure

&AtClient
Procedure ConfirmationCodeOldPhoneNumberEditTextChange(Item, Text, StandardProcessing)

	If StrLen(TrimAll(Text)) = 6 Then
		ConfirmationCode = TrimAll(Text);
		AttachIdleHandler("Attachable_CheckConfirmationCode", 0.5, True);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConfirmPhoneNumber(Command)

	SendPhoneConfirmationCodeForPasswords();

EndProcedure

&AtClient
Procedure ResendCodePhoneNumber(Command)

	SendPhoneConfirmationCodeForPasswords();

EndProcedure

&AtClient
Procedure CancelPhoneNumberChangeClick(Item)

	ConfirmPhoneNumberForPasswords = ConfirmPhoneNumberForPasswords(False, False, "", False, False, ConfirmPhoneNumberForPasswords.SourceValue);
	PhoneForPasswords = ConfirmPhoneNumberForPasswords.SourceValue;
	Timer = 0;
	DetachIdleHandler("Attachable_HandlerCountdown");
	AttachIdleHandler("Attachable_UpdateFieldTexts", 0.1, True);
	FormControl(ThisObject);

EndProcedure

&AtClient
Procedure ValidateAddress(Command)

	SendConfirmationCodeEmailForPasswords();

EndProcedure

&AtClient
Procedure ResendCodeEmail(Command)

	SendConfirmationCodeEmailForPasswords();

EndProcedure

&AtClient
Procedure CancelEmailChangeClick(Item)

	ConfirmEmailForPasswords = ConfirmPhoneNumberForPasswords(False, False, "", False, False, ConfirmEmailForPasswords.SourceValue);
	EmailForPasswords = ConfirmEmailForPasswords.SourceValue;
	Timer = 0;
	DetachIdleHandler("Attachable_HandlerCountdown");
	AttachIdleHandler("Attachable_UpdateFieldTexts", 0.1, True);
	FormControl(ThisObject);

EndProcedure

&AtClient
Procedure ConfirmUpdate(Command)

	SendConfirmationCodeOldPhoneNumber();

EndProcedure

&AtClient
Procedure ResendCodeOldPhoneNumber(Command)

	SendConfirmationCodeOldPhoneNumber();

EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure FillInVariablesForPhoneAndEmailVerification(Form)

	Form.ConfirmPhoneNumberForPasswords = ConfirmPhoneNumberForPasswords(False, False, "", False, False, "");
	Form.ConfirmEmailForPasswords = ConfirmPhoneNumberForPasswords(False, False, "", False, False, "");
	Form.ConfirmOldPhoneNumber = ConfirmPhoneNumberForPasswords(False, False, "", False, False, "");

EndProcedure

&AtServer
Procedure InstallLabels()

	If CheckMode = "Update" Then
		ChangesConfirmationNote = NStr("vi = 'Cần xác nhận thay đổi bằng cách nhập mã đã được gửi đến %1.
			|Nếu số điện thoại này không còn sử dụng nữa thì hãy tham khảo <a href = ""#Инструкция"">hướng dẫn</a>.';
			|ru = 'Изменения необходимо будет подтвердить, введя код отправленный на %1.
			|Если этот телефон больше не доступен, то воспользуйтесь <a href = ""#Инструкция"">инструкцией</a>.';
			|en = 'To confirm the changes, enter the code sent to %1.
			|If this number is no longer available, see the <a href = ""#Инструкция"">instructions</a>.'; fa = 'To confirm the changes, enter the code sent to %1.
			|If this number is no longer available, see the <a href = ""#Инструкция"">instructions</a>.';
			|it = 'Изменения необходимо будет подтвердить, введя код отправленный на %1.
			|Если этот телефон больше не доступен, то воспользуйтесь <a href = ""#Инструкция"">инструкцией</a>.';
			|pl = 'To confirm the changes, enter the code sent to %1.
			|If this number is no longer available, see the <a href = ""#Инструкция"">instructions</a>.';
			|tr = '%1 numarasına gönderilen kodu girerek değişikliği onaylamanız gerekecektir.
			|Bu telefon artık kullanılamıyorsa, instruction kullanın.'");
		ChangesConfirmationNote = StrTemplate(ChangesConfirmationNote, ConfirmPhoneNumberForPasswords.SourceValue);
		ExplanationTitle = NStr("vi = 'Để thay đổi số điện thoại và/hoặc địa chỉ email của bạn, hãy nhập giá trị mới vào các trường bên dưới.';
								|ru = 'Для изменения телефона и/или адреса электронной почты укажите их новые значения в полях ниже.';
								|en = 'To change the phone number and/or the email address, specify their new values in the fields below.'; fa = 'To change the phone number and/or the email address, specify their new values in the fields below.';
								|it = 'Per modificare il numero di telefono e/o indirizzo di posta elettronica indicate i nuovi valori nei campi sotto.';
								|pl = 'Aby zmienić telefon i/lub adres poczty elektronicznej, wprowadź nowe wartości w poniższych polach.';
								|tr = 'Telefon numaranızı ve/veya e-posta adresinizi değiştirmek için aşağıdaki alanlara yeni değerlerini girin.'");
		FormCaption = NStr("vi = 'Tùy chỉnh nhận mật khẩu tạm thời';
							|ru = 'Настройки получения временных паролей';
							|en = 'Settings of receiving temporary passwords'; fa = 'تنظیمات دریافت رمزهای عبور موقت';
							|it = 'Impostazioni di ricezione della password monouso';
							|pl = 'Ustawienia otrzymania hasel tymczasowych';
							|tr = 'Geçici parola alma ayarları'");
		OldPhoneTitle = StrTemplate(NStr("vi = 'Mã được gửi đến
			|%1:';
			|ru = 'Код отправлен на
			|%1:';
			|en = 'Code is sent to
			|%1:'; fa = 'Code is sent to
			|%1:';
			|it = 'Codice di invio in 
			|%1:';
			|pl = 'Kod został wysłany na
			|%1:';
			|tr = 'Kod gönderildi
			|%1:'"), ConfirmPhoneNumberForPasswords.SourceValue);
	Else
		ChangesConfirmationNote = NStr("vi = 'Cần nhập và xác nhận số điện thoại bằng cách nhập mã đã gửi đến.';
										|ru = 'Необходимо будет ввести номер телефона и его подтвердить, введя отправленный код.';
										|en = 'You need to enter the phone number and confirm it by entering the received code.'; fa = 'You need to enter the phone number and confirm it by entering the received code.';
										|it = 'Sarà necessario inserire il numero di telefono e confermarlo inserendo il codice ricevuto.';
										|pl = 'Trzeba będzie wpisać numer telefonu i potwierdzić go, wpisując wysłany kod.';
										|tr = 'Bir telefon numarası girmeniz ve gönderilen kodu girerek onaylamanız gerekecektir.'") + Chars.LF;
		ExplanationTitle = NStr("vi = 'Để xác nhận điện thoại và / hoặc địa chỉ email, chỉ định giá trị của chúng trong các trường bên dưới.';
								|ru = 'Для подтверждения телефона и/или адреса электронной почты укажите их значения в полях ниже.';
								|en = 'To confirm the phone number and/or the email address, specify their values in the fields below.'; fa = 'To confirm the phone number and/or the email address, specify their values in the fields below.';
								|it = 'Per confermare il numero di telefono e/o indirizzo di posta elettronica indicate i loro valori nei campi sotto.';
								|pl = 'Aby potwierdzić telefon i/lub adres poczty elektronicznej, wpisz wartości w poniższych polach.';
								|tr = 'Telefon numaranızı ve/veya e-posta adresinizi onaylamak için aşağıdaki alanlara değerlerini girin.'");
		FormCaption = NStr("vi = 'Xác nhận tùy chỉnh để nhận mật khẩu tạm thời';
							|ru = 'Подтверждение настроек для получения временных паролей';
							|en = 'Confirm settings to receive temporary passwords'; fa = 'Confirm settings to receive temporary passwords';
							|it = 'Conferma delle imposazioni per la ricezione di password temporanee';
							|pl = 'Potwierdzenie ustawień do przekazania haseł tymczasowych';
							|tr = 'Geçici parolalar için ayarları onayla'");
		OldPhoneTitle = "";
	EndIf;

	Title = FormCaption;
	Items.TitleDecoration.Title = StringFunctions.FormattedString(ExplanationTitle);
	Items.OldPhoneNumberHeader.Title = OldPhoneTitle;
	Items.ChangesConfirmationNote.Title = StringFunctions.FormattedString(ChangesConfirmationNote);

EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(Form)

	Items = Form.Items;

	// Phone number for passwords
	Items.PhoneNumberConfirmedPicture.Visible = Form.ConfirmPhoneNumberForPasswords.ConfirmationCompleted;
	Items.ConfirmPhoneNumber.Visible = Form.ConfirmPhoneNumberForPasswords.ValueEntered
		And Not Form.ConfirmPhoneNumberForPasswords.ConfirmationCompleted
		And Not Form.ConfirmPhoneNumberForPasswords.CheckInProgress;
	Items.PhoneForPasswords.ReadOnly = ValueIsFilled(Form.ConfirmPhoneNumberForPasswords.CheckID);
	Items.ConfirmationCodePhoneNumberGroup.Visible = Form.ConfirmPhoneNumberForPasswords.CheckInProgress
		And Not Form.ConfirmPhoneNumberForPasswords.ConfirmationCompleted;

	Items.ResendCodePhoneNumber.Visible = Not Form.ConfirmPhoneNumberForPasswords.CodeSent;
	Items.CountdownLabelPhoneNumber.Visible = Form.ConfirmPhoneNumberForPasswords.CodeSent;

	// Email for passwords
	Items.EmailConfirmedPicture.Visible = Form.ConfirmEmailForPasswords.ConfirmationCompleted;
	Items.ValidateAddress.Visible = Form.ConfirmEmailForPasswords.ValueEntered
		And Not Form.ConfirmEmailForPasswords.ConfirmationCompleted
		And Not Form.ConfirmEmailForPasswords.CheckInProgress;
	Items.EmailForPasswords.ReadOnly = ValueIsFilled(Form.ConfirmEmailForPasswords.CheckID);
	Items.ConfirmationCodeEmailGroup.Visible = Form.ConfirmEmailForPasswords.CheckInProgress
		And Not Form.ConfirmEmailForPasswords.ConfirmationCompleted;

	Items.ResendCodeEmail.Visible = Not Form.ConfirmEmailForPasswords.CodeSent;
	Items.CountdownLabelEmail.Visible = Form.ConfirmEmailForPasswords.CodeSent;

	// Confirmation of changes
	If Form.CheckMode = "Update" Then
		YouCanConfirmChanges = Form.ConfirmPhoneNumberForPasswords.ConfirmationCompleted
			Or Form.ConfirmEmailForPasswords.ConfirmationCompleted
			Or Form.ConfirmEmailForPasswords.SourceValue <> Form.EmailForPasswords
			And Not ValueIsFilled(Form.EmailForPasswords)
			And Not Form.ConfirmOldPhoneNumber.ConfirmationCompleted
			And Not Form.ConfirmPhoneNumberForPasswords.CheckInProgress
			And Not Form.ConfirmEmailForPasswords.CheckInProgress;
	Else
		YouCanConfirmChanges = Form.ConfirmPhoneNumberForPasswords.ConfirmationCompleted
			And Not Form.ConfirmPhoneNumberForPasswords.CheckInProgress
			And Not Form.ConfirmEmailForPasswords.CheckInProgress
			And (Not ValueIsFilled(Form.EmailForPasswords) 
			Or Form.ConfirmEmailForPasswords.ConfirmationCompleted);
	EndIf;
	Items.ConfirmChanges.Visible = YouCanConfirmChanges;
	Items.ConfirmChanges.Enabled = Not Form.ConfirmOldPhoneNumber.CheckInProgress;

	Items.ResendCodeOldPhoneNumber.Visible = Not Form.ConfirmOldPhoneNumber.CodeSent;
	Items.CountdownLabelOldPhoneNumber.Visible = Form.ConfirmOldPhoneNumber.CodeSent;

	Items.OldPhoneNumberHeaderAndCodeGroup.Visible = Form.ConfirmOldPhoneNumber.CheckInProgress
		And YouCanConfirmChanges And Form.CheckMode = "Update";

EndProcedure

&AtClient
Procedure Attachable_UpdateFieldTexts()

	Items.PhoneForPasswords.UpdateEditText();
	Items.EmailForPasswords.UpdateEditText();

EndProcedure

&AtClient
Procedure Attachable_HandlerCountdown()

	Timer = Timer - 1;
	If Timer >= 0 Then
		CountdownLabel = StrTemplate(NStr("vi = 'Có thể sẽ hỏi lại mã sau %1 giây.';
											|ru = 'Запросить код повторно можно будет через %1 сек.';
											|en = 'You can request the code again in %1 sec.'; fa = 'You can request the code again in %1 sec.';
											|it = 'È possibile richiedere ancora il codice tra %1 secondi';
											|pl = 'Ponowna prośba o wysłanie kodu będzie możliwa przez %1 sek.';
											|tr = '%1 saniye içerisinde kodu tekrar isteyebilirsiniz.'"), Timer);
		AttachIdleHandler("Attachable_HandlerCountdown", 1, True);
	Else
		CountdownLabel = "";
		ConfirmPhoneNumberForPasswords.CodeSent = False;
		ConfirmEmailForPasswords.CodeSent = False;
		ConfirmOldPhoneNumber.CodeSent = False;
		FormControl(ThisObject);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_UpdateYourPhoneForPasswords()

	Items.ConfirmPhoneNumber.Visible = ConfirmPhoneNumberForPasswords.ValueEntered;
	If ConfirmPhoneNumberForPasswords.ValueEntered Then
		Items.PhoneForPasswords.UpdateEditText();
		DetachIdleHandler("Attachable_ActivateCheckNumberButton");
		AttachIdleHandler("Attachable_ActivateCheckNumberButton", 0.1, True);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_ActivateCheckNumberButton()

	CurrentItem = Items.ConfirmPhoneNumber;

EndProcedure

&AtClient
Procedure Attachable_CheckConfirmationCode()

	ClearMessages();

	ConfirmationCode = TrimAll(ConfirmationCode);
	If StrLen(ConfirmationCode) = 6 Then

		Result = Undefined;

		If ConfirmPhoneNumberForPasswords.CheckInProgress Then
			Result = CheckPhoneByCodeOnServer(ConfirmPhoneNumberForPasswords.CheckID, ConfirmationCode);
			If Result.Completed2 Then
				ConfirmPhoneNumberForPasswords.CheckInProgress = False;
				ConfirmPhoneNumberForPasswords.ConfirmationCompleted = True;
			EndIf;
		ElsIf ConfirmOldPhoneNumber.CheckInProgress Then
			Result = CheckOldPhoneByCodeOnServer(ConfirmOldPhoneNumber.CheckID, ConfirmationCode);
			If Result.Completed2 Then
				ConfirmOldPhoneNumber.CheckInProgress = False;
				ConfirmOldPhoneNumber.ConfirmationCompleted = True;

				CallbackDescription = New CallbackDescription("CloseFormAfterConfirmingOldNumber", ThisObject);

				If ConfirmPhoneNumberForPasswords.ConfirmationCompleted
						And ConfirmEmailForPasswords.ConfirmationCompleted Then
					WarningText = NStr("vi = 'Đã thay đổi thành công số điện thoại và địa chỉ email của bạn';
										|ru = 'Ваш номер телефона и адрес электронной почты успешно изменены';
										|en = 'Your phone number and email address were changed successfully'; fa = 'Your phone number and email address were changed successfully';
										|it = 'Il Vostro numero di telefono e indirizzo di posta elettronica modificati con successo';
										|pl = 'Twój numer telefonu i adres poczty elektronicznej zostały zmienione pomyślnie';
										|tr = 'Telefon numaranız ve e-posta adresiniz başarıyla değiştirildi'");
				ElsIf ConfirmPhoneNumberForPasswords.ConfirmationCompleted Then
					WarningText = NStr("vi = 'Đã thay đổi thành công số điện thoại của bạn';
										|ru = 'Ваш номер телефона успешно изменен';
										|en = 'Your phone number was changed successfully'; fa = 'Your phone number was changed successfully';
										|it = 'Il Vostro numero di telefono è stato modificato con successo';
										|pl = 'Twój numer telefonu został zmieniony pomyślnie';
										|tr = 'Telefon numaranız başarıyla değiştirildi'");
				Else
					WarningText = NStr("vi = 'Đã thay đổi địa chỉ email của bạn';
										|ru = 'Ваш адрес электронной почты успешно изменен';
										|en = 'Your email address was changed successfully'; fa = 'Your email address was changed successfully';
										|it = 'Il Vostro indirizzo di posta elettronica è stato modificato con successo';
										|pl = 'Twój adres poczty elektronicznej został zmieniony pomyślnie';
										|tr = 'E-posta adresiniz başarıyla değiştirildi'");
				EndIf;
				ShowMessageBox(CallbackDescription, WarningText);
			EndIf;
		ElsIf ConfirmEmailForPasswords.CheckInProgress Then
			Result = CheckEmailByCodeOnServer(ConfirmEmailForPasswords.CheckID, ConfirmationCode);
			If Result.Completed2 Then
				ConfirmEmailForPasswords.CheckInProgress = False;
				ConfirmEmailForPasswords.ConfirmationCompleted = True;
			EndIf;
		EndIf;

		If Result <> Undefined Then
			If Result.Completed2 Then
				DetachIdleHandler("Attachable_HandlerCountdown");
				FormControl(ThisObject);
			Else
				CommonClient.MessageToUser(Result.ErrorDescription, , "ConfirmationCode");
			EndIf;
		EndIf;

	EndIf;

EndProcedure

&AtServerNoContext
Function CheckPhoneByCodeOnServer(Id, ConfirmationCode)

	Return CryptographyServiceManager.CheckPhoneNumberByCode(Id, ConfirmationCode);

EndFunction

&AtServerNoContext
Function CheckEmailByCodeOnServer(Id, ConfirmationCode)

	Return CryptographyServiceManager.CheckEmailByCode(Id, ConfirmationCode);

EndFunction

&AtClient
Procedure Attachable_UpdateEmailForPasswords()

	Items.ValidateAddress.Visible = ConfirmEmailForPasswords.ValueEntered;
	ValueCleared = (ConfirmEmailForPasswords.SourceValue <> EmailForPasswords
		And Not ValueIsFilled(EmailForPasswords))
		Or (CheckMode <> "Update" And Not ValueIsFilled(EmailForPasswords));
	If ConfirmEmailForPasswords.ValueEntered Or ValueCleared Then
		Items.EmailForPasswords.UpdateEditText();
		DetachIdleHandler("Attachable_ActivateCheckAddressButton");
		AttachIdleHandler("Attachable_ActivateCheckAddressButton", 0.1, True);
		FormControl(ThisObject);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_ActivateCheckAddressButton()

	CurrentItem = Items.ValidateAddress;

EndProcedure

&AtClient
Procedure SendPhoneConfirmationCodeForPasswords()

	DetachIdleHandler("Attachable_UpdateYourPhoneForPasswords");
	ClearMessages();
	ConfirmationCode = Undefined;

	Result = CheckNumberOnServer(PhoneForPasswords, ConfirmPhoneNumberForPasswords.CheckID);
	If Result.Completed2 Then
		Timer = Result.DelayBeforeResending;
		ConfirmPhoneNumberForPasswords.CheckID = Result.Id;
		StartCountdown();
		ConfirmPhoneNumberForPasswords.CheckInProgress = True;
		ConfirmPhoneNumberForPasswords.CodeSent = True;

		AttachIdleHandler("Attachable_ActivateConfirmationCodePhoneField", 0.1, True);
	Else
		CommonClient.MessageToUser(Result.ErrorDescription, , "PhoneForPasswords");
	EndIf;
	FormControl(ThisObject);

EndProcedure

&AtClient
Procedure SendConfirmationCodeEmailForPasswords()

	DetachIdleHandler("Attachable_UpdateEmailForPasswords");
	ClearMessages();
	ConfirmationCode = Undefined;

	Result = CheckAddressOnServer(EmailForPasswords, ConfirmEmailForPasswords.CheckID);
	If Result.Completed2 Then
		Timer = Result.DelayBeforeResending;
		ConfirmEmailForPasswords.CheckID = Result.Id;
		StartCountdown();
		ConfirmEmailForPasswords.CheckInProgress = True;
		ConfirmEmailForPasswords.CodeSent = True;
		AttachIdleHandler("Attachable_ActivateConfirmationCodeEMailField", 0.1, True);
	Else
		CommonClient.MessageToUser(Result.ErrorDescription, , "EmailForPasswords");
	EndIf;
	FormControl(ThisObject);

EndProcedure

&AtClient
Procedure Attachable_ActivateConfirmationCodePhoneField()

	CurrentItem = Items.ConfirmationCodePhoneNumber;

EndProcedure

&AtClient
Procedure Attachable_ActivateConfirmationCodeEMailField()

	CurrentItem = Items.ConfirmationCodeEmail;

EndProcedure

&AtClient
Procedure StartCountdown()

	AttachIdleHandler("Attachable_HandlerCountdown", 1, True);

EndProcedure

&AtServerNoContext
Function CheckNumberOnServer(Phone, Id)

	Return CryptographyServiceManager.GetPhoneVerificationCode(Phone, Id);

EndFunction

&AtServerNoContext
Function CheckAddressOnServer(Email, Id)

	Return CryptographyServiceManager.GetEmailVerificationCode(Email, Id);

EndFunction

&AtClient
Procedure Attachable_ActivateConfirmationCodeFieldOldPhone()

	CurrentItem = Items.ConfirmationCodeOldPhoneNumber;

EndProcedure

&AtClient
Procedure SendConfirmationCodeOldPhoneNumber()

	ClearMessages();
	ConfirmationCode = Undefined;

	If ValueIsFilled(ConfirmEmailForPasswords.CheckID) Then
		Email = ConfirmEmailForPasswords.CheckID;
	ElsIf Not ValueIsFilled(EmailForPasswords)
			And EmailForPasswords <> ConfirmEmailForPasswords.SourceValue Then
		Email = "";
	EndIf;

	If CheckMode = "Confirmation" Then
		ClosingParameters = New Structure();
		ClosingParameters.Insert("PhoneNumber", ConfirmPhoneNumberForPasswords.CheckID);
		ClosingParameters.Insert("Email", Email);
		CloseForm(ClosingParameters);
	Else
		Result = SendConfirmationCodeToOldNumber(
			CryptographyServiceInternalClient.Id(Certificate), 
			?(ValueIsFilled(ConfirmPhoneNumberForPasswords.CheckID), ConfirmPhoneNumberForPasswords.CheckID, Undefined), 
			Email, 
			ConfirmOldPhoneNumber.CheckID);
		If Result.Completed2 Then
			Timer = Result.DelayBeforeResending;
			ConfirmOldPhoneNumber.CheckID = Result.Id;
			StartCountdown();
			ConfirmOldPhoneNumber.CheckInProgress = True;
			ConfirmOldPhoneNumber.CodeSent = True;

			AttachIdleHandler("Attachable_ActivateConfirmationCodeFieldOldPhone", 0.1, True);
		Else
			CommonClient.MessageToUser(Result.ErrorDescription);
		EndIf;
		FormControl(ThisObject);
	EndIf;

EndProcedure

&AtServerNoContext
Function CheckOldPhoneByCodeOnServer(Id, ConfirmationCode)

	Return CryptographyServiceManager.FinishChangingSettingsForGettingTemporaryPasswords(Id, ConfirmationCode);

EndFunction

&AtClient
Procedure CloseFormAfterConfirmingOldNumber(IncomingContext) Export

	CloseForm();

EndProcedure

&AtClient
Procedure CloseForm(ClosingParameters = Undefined)

	CloseProgrammatically = True;

	If ClosingParameters = Undefined Then
		ClosingParameters = New Structure;
		ClosingParameters.Insert("PhoneNumberChanged", ConfirmPhoneNumberForPasswords.ConfirmationCompleted);
		ClosingParameters.Insert("EmailChanged", ConfirmEmailForPasswords.ConfirmationCompleted);
	EndIf;

	Close(ClosingParameters);

EndProcedure

&AtServerNoContext
Function SendConfirmationCodeToOldNumber(CertificateID, Phone, Email, Id)

	Return CryptographyServiceManager.StartChangingSettingsForGettingTemporaryPasswords(CertificateID, Phone, Email, Id);

EndFunction

&AtClientAtServerNoContext
Function ConfirmPhoneNumberForPasswords(ValueEntered, CheckInProgress,
		CheckID, ConfirmationCompleted, CodeSent, SourceValue)

	ConfirmPhoneNumberForPasswords = New Structure;

	ConfirmPhoneNumberForPasswords.Insert("ValueEntered", ValueEntered);
	ConfirmPhoneNumberForPasswords.Insert("CheckInProgress", CheckInProgress);
	ConfirmPhoneNumberForPasswords.Insert("CheckID", CheckID);
	ConfirmPhoneNumberForPasswords.Insert("ConfirmationCompleted", ConfirmationCompleted);
	ConfirmPhoneNumberForPasswords.Insert("CodeSent", CodeSent);
	ConfirmPhoneNumberForPasswords.Insert("SourceValue", SourceValue);

	Return ConfirmPhoneNumberForPasswords;

EndFunction

#EndRegion
