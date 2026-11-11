////////////////////////////////////////////////////////////////////////////////
// Subsystem "Electronic signature in the service model".
//  
////////////////////////////////////////////////////////////////////////////////
//


#Region Public

// Parameters:
// 	Phone - String
// 	
// Returns:
// 	String
//
Function GetPhonePresentation(Phone) Export
		
	Presentation = "";
	TextToProcess = TrimAll(Phone); 
	NumbersOnly = "";
	For IndexOf = 1 To StrLen(TextToProcess) Do
		CurrentChar = Mid(TextToProcess, IndexOf, 1);
		If StrFind("0123456789", CurrentChar) Then
			NumbersOnly = NumbersOnly + CurrentChar;
		EndIf;
	EndDo;
	If StrLen(NumbersOnly) = 11 Then
		NumbersOnly = Mid(NumbersOnly, 2);
	EndIf;

	If StrLen(NumbersOnly) = 10 Then
		Presentation = StrTemplate(
			"+7 %1 %2-%3-%4", 
			Mid(NumbersOnly, 1, 3), 
			Mid(NumbersOnly, 4, 3),
			Mid(NumbersOnly, 7, 2),
			Mid(NumbersOnly, 9));		
	EndIf;
	
	Return Presentation;	

EndFunction

// Returns:
// 	String
//
Function GetDescriptionOfWaysToConfirmCryptoOperations() Export
	
	Result = NStr(
	"vi = 'Dấu hiệu xác nhận các giao dịch có khóa người sử dụng được lưu trong chương trình.
	|Xác nhận liên quan đến việc nhập mật khẩu tạm thời được gửi qua SMS hoặc E-mail.';
	|ru = 'Признак подтверждения операций с ключом пользователя, хранящимся в программе.
	|Подтверждение предполагает ввод временного пароля, высылаемого в SMS или на эл. почту.';
	|en = 'A sign of confirming operations with a user key stored in the application. 
	|To confirm, a temporary password is entered sent via text message or email.'; fa = 'A sign of confirming operations with a user key stored in the application. 
	|To confirm, a temporary password is entered sent via text message or email.';
	|it = 'Segno di conferma dell''operazione con chiave utente salvata nel programma.
	|La conferma prevede l''inserimento della password temporanea inviata per SMS o posta elettronica.';
	|pl = 'Oznaka potwierdzenia operacji z kluczem użytkownika, która jest przechowywana w programie.
	|Potwierdzenie przewiduje wprowadzenie hasła tymczasowego, wysyłanego w wiadomości SMS lub e-mail.';
	|tr = 'Uygulamada saklı kullanıcı anahtarı ile yapılan işlemlerin bayrağı.
	|Onay, SMS veya e-posta yoluyla gönderilen geçici şifrenin girilmesini içerir.'");
	
	Return Result;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// See DigitalSignatureSaaSClient.UsageAllowed.
// See DigitalSignatureSaaS.UsageAllowed.
//
// Returns:
// 	Boolean
//
Function UsageAllowed() Export
	
	#If Client Then
		Return StandardSubsystemsClient.ClientRunParameters()["UsingElectronicSignatureInServiceModelIsPossible"];
	#Else
		Return DigitalSignatureSaaS.UsageAllowed();		
	#EndIf
	
EndFunction

#EndRegion

#EndRegion	