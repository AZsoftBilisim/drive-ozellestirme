#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	Parameters.Property("SubscriberCode", SubscriberCode);
	Parameters.Property("Login", AuthorizationLogin);
	Parameters.Property("Password", AuthorizationPassword);
	Parameters.Property("APIAddress", APIAddress);
	Parameters.Property("FullName", FullName);
	Parameters.Property("Id", Id);
	Parameters.Property("Mail", Mail);
	If ValueIsFilled(Mail) Then
		Login = Mail;
	EndIf;

	Items.PasswordIsPrivate.ChoiceButtonPicture = Items.ThePictureIsClosed.Picture;
	Items.PasswordIsOpen.ChoiceButtonPicture = Items.PictureOpen.Picture;

	UserRole = "user";
	TimeZone = SessionTimeZone();

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)

	If UserRole = Enums.SubscriberUsersRoles.SubscriberUser Then
		CheckedAttributes.Add("Mail");
	EndIf;

	Try
		Result = CommonClientServer.ParseStringWithEmailAddresses(Mail);
	Except
		ErrorText = CloudTechnology.ShortErrorText(ErrorInfo());
		Common.MessageToUser(ErrorText, , "Mail", , Cancel);
		Return;
	EndTry;
	If Result.Count() > 1 Then
		ErrorText = NStr("vi = 'Chỉ có thể nhập một e-mail.';
						|ru = 'Можно ввести только один e-mail.';
						|en = 'You can enter only one email.'; fa = 'You can enter only one email.';
						|it = 'È possibile inserire solo una e-mail.';
						|pl = 'Możesz wpisać tylko jeden e-mail.';
						|tr = 'Sadece bir tane e-posta adresi girilebilir.'");
		Common.MessageToUser(ErrorText, , "Mail", , Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MailOnChange(Item)

	If ValueIsFilled(Mail) And Not ValueIsFilled(Login) Then
		Login = Mail;
	EndIf;

EndProcedure

&AtClient
Procedure PasswordStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	Items.PasswordIsPrivate.Visible = False;
	Items.PasswordIsOpen.Visible = True;

EndProcedure

&AtClient
Procedure PasswordIsOpenStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	Items.PasswordIsPrivate.Visible = True;
	Items.PasswordIsOpen.Visible = False;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)

	If DoneOnServer() Then

		ReturnParameters1 = New Structure;
		ReturnParameters1.Insert("Result", True);
		ReturnParameters1.Insert("Login", Login);
		ReturnParameters1.Insert("FullName", FullName);
		ReturnParameters1.Insert("Role", UserRole);
		ReturnParameters1.Insert("Id", Id);
		ReturnParameters1.Insert("Mail", Mail);

		Close(ReturnParameters1);

	EndIf;

EndProcedure

&AtClient
Procedure Cancel(Command)

	Close();

EndProcedure

#EndRegion

#Region Private

&AtServer
Function DoneOnServer()

	Data = New Structure;
	Data.Insert("id", SubscriberCode);
	Data.Insert("login", Login);
	If ValueIsFilled(Password) Then
		Data.Insert("password", Password);
	EndIf;
	Data.Insert("email_required", ValueIsFilled(Mail));
	Data.Insert("email", Mail);
	Data.Insert("role", UserRole);
	Data.Insert("name", FullName);
	Data.Insert("phone", Phone);
	Data.Insert("timezone", SessionTimeZone());

	DataProcessorObject = FormAttributeToValue("Object");
	Authorization = DataProcessorObject.AuthorizationParameters(AuthorizationLogin, AuthorizationPassword, SubscriberCode);

	QueryOptions = New Structure;
	QueryOptions.Insert("APIAddress", APIAddress);
	QueryOptions.Insert("Method", "usr/account/users/create");
	QueryOptions.Insert("Authorization", Authorization);
	QueryOptions.Insert("Data", Data);

	ResultAddress = PutToTempStorage(Undefined, UUID);

	DataProcessorObject.ExecuteExternalInterfaceMethod(QueryOptions, ResultAddress);
	Result = GetFromTempStorage(ResultAddress);

	If Result.Error Then
		Raise Result.ErrorMessage;
	ElsIf Result.Data.general.Error Then
		Raise Result.Data.general.message;
	Else
		Return True;
	EndIf;

EndFunction
#EndRegion