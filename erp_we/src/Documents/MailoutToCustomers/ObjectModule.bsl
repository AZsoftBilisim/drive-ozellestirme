#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If DesignedForSMSMessage Then
		
		EmailTextType =  Undefined;
		EmailText     = "";
		HTMLEmailText = ""; 
		
	Else
		
		SMSMessageText = "";
		SendInTransliteration = False;
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If DesignedForEmails Then
		
		NotCheckedAttributeArray.Add("SMSMessageText");
		
		If EmailTextType = Enums.EmailEditingMethods.HTML Then
			
			NotCheckedAttributeArray.Add("EmailText");
			
		EndIf;
		
	EndIf;
	
	If DesignedForSMSMessage Then
		
		NotCheckedAttributeArray.Add("EmailTextType");
		NotCheckedAttributeArray.Add("EmailText");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	If UpdateDate <> Date(1, 1, 1) 
		And (Status = Enums.CustomerMailoutStatuses.Draft Or Status = Enums.CustomerMailoutStatuses.ForDispatch) Then
		
		If UpdateDate < CurrentSessionDate() Then
			
			MessageText= NStr("vi = 'Ngày cập nhật đã chỉ ra trước ngày hiện tại, tin nhắn sẽ không bao giờ được gửi đi.';
								|ru = 'Указанная дата актуальности меньше текущей даты, сообщения никогда не будут отправлены.';
								|en = 'The specified relevance date is less than the current date, messages will never be sent.'; fa = 'The specified relevance date is less than the current date, messages will never be sent.';
								|it = 'La data di rilevanza indicata è antecedente alla data corrente, i messaggi non saranno mai inviati.';
								|pl = 'Podana data aktualności jest mniejsza niż bieżąca data, wiadomości nie zostaną wysłane.';
								|tr = 'Belirtilen uygunluk tarihi mevcut tarihten öncedir, mesajlar asla gönderilmeyecektir.'");
			CommonClientServer.MessageToUser(MessageText,, "UpdateDate",,Cancel);
			
		EndIf;
		
		If UpdateDate < MailingDate Then
			
			MessageText= NStr("vi = 'Ngày cập nhật đã chỉ ra trước ngày hiện tại, thư sẽ không bao giờ được gửi đi.';
								|ru = 'Указанная дата актуальности меньше даты рассылки, сообщения никогда не будут отправлены.';
								|en = 'The specified relevance date is earlier than the mailout date. Messages will not be sent.'; fa = 'The specified relevance date is earlier than the mailout date. Messages will not be sent.';
								|it = 'La data di rilevanza indicata è antecedente alla data di mailing, i messaggi non saranno mai inviati.';
								|pl = 'Podana data aktualności jest mniejsza niż data wysłania, wiadomości nie zostaną wysłane.';
								|tr = 'Belirtilen uygunluk tarihi bülten tarihten öncedir, mesajlar asla gönderilmeyecektir.'");
			CommonClientServer.MessageToUser(MessageText,, "UpdateDate",,Cancel);
			
		EndIf;
		
	EndIf;
	
	For Each AdditionalRecipient In AdditionalRecipients Do
	
		If IsBlankString(AdditionalRecipient.ContactInformation) Then
			Continue;
		EndIf;
		
		LineNumber = AdditionalRecipient.LineNumber;
		
		PathToTabularSection = CommonClientServer.PathToTabularSection("Object.AdditionalRecipients",
		                                                                       AdditionalRecipient.LineNumber,
		                                                                      "ContactInformation");
		
		If DesignedForSMSMessage Then
		
			If StringFunctionsClientServer.SplitStringIntoSubstringsArray(AdditionalRecipient.ContactInformation, ";", True).Count() > 1 Then
			
				MessageText = NStr("vi = 'Tại dòng %1 đã chỉ ra nhiều hơn một số điện thoại.';
									|ru = 'В строке %1 указан более чем один номер телефона.';
									|en = 'Line %1 contains more than one phone number.'; fa = 'Line %1 contains more than one phone number.';
									|it = 'Nella riga %1 è indicato più di un numero di telefono.';
									|pl = 'W wierszu %1 jest podano kilka numerów telefonów.';
									|tr = '%1 satırında birden fazla telefon numarası belirtildi.'");
				MessageText = StringFunctionsClientServer.InsertParametersIntoString(MessageText, LineNumber);
				
				CommonClientServer.MessageToUser(
				       MessageText,
				       ,
				      PathToTabularSection,
				      ,
				      Cancel);
				Continue;
				
			EndIf;
			
			MessageText = NStr("vi = 'Tại dòng%1 cần chỉ ra số điện thoại với định dạng ""+xx (xxx) xxxxxxx"".';
								|ru = 'Номер телефона в строке %1 должен быть указан в формате ""+xx (xxx) xxxxxxx"".';
								|en = 'Phone number should be specified in format ""+xx (xxx) xxxxxxx"" in line %1.'; fa = 'Phone number should be specified in format ""+xx (xxx) xxxxxxx"" in line %1.';
								|it = 'Il numero di telefono nella riga %1 deve avere il formato ""+xx (xxx) xxxxxxx"".';
								|pl = 'Numer telefonu w wierszu %1 musi być podany w formacie ""+xx (xxx) xxxxxxx"".';
								|tr = '%1 satırındaki telefon numarası ""+xx (xxx) xxxxxxx"" formatında belirtilmelidir.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, LineNumber);
			
			If Not Interactions.PhoneNumberSpecifiedCorrectly(AdditionalRecipient.ContactInformation) Then
				
				CommonClientServer.MessageToUser(
				      MessageText,
				      ,
				      PathToTabularSection,
				      ,
				      Cancel);
				
			EndIf;
			
		Else
			
			AddressesArray = CommonClientServer.EmailsFromString(AdditionalRecipient.ContactInformation);
			
			If AddressesArray.Count() > 1 Then
				
				MessageText = NStr("vi = 'Tại dòng %1 đã chỉ ra nhiều hơn một địa chỉ email.';
									|ru = 'В строке %1 указан более чем один адрес электронной почты.';
									|en = 'More than one email address is specified in line %1.'; fa = 'More than one email address is specified in line %1.';
									|it = 'Nella riga %1 è indicato più di un indirizzo di posta elettronica.';
									|pl = 'W wierszu %1 jest podano kilka adresów poczty elektronicznej.';
									|tr = '%1 satırında birden fazla e-posta adresi belirtildi.'");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, LineNumber);
				
				CommonClientServer.MessageToUser(
				       MessageText,
				       ,
				       PathToTabularSection,
				       ,
				       Cancel);
				Continue;
				
			EndIf;
			
			If AddressesArray.Count() = 1 And Not IsBlankString(AddressesArray[0].ErrorDescription) Then
				
				MessageText = NStr("vi = 'Lỗi tại dòng %1. %2';
									|ru = 'Ошибка в строке %1. %2';
									|en = 'An error occurred in line %1. %2'; fa = 'An error occurred in line %1. %2';
									|it = 'Errore nella riga %1. %2';
									|pl = 'Błąd w wierszu %1. %2';
									|tr = '%1 satırında hata oluştu. %2'");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, LineNumber, AddressesArray[0].ErrorDescription);
				
				CommonClientServer.MessageToUser(
					MessageText,
					,
					PathToTabularSection,
					,
					Cancel);
				
			EndIf;
			
		EndIf;
	
	EndDo;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("CatalogRef.MarketingActivities") Then
		
		Basis = FillingData;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.PollPurpose") Then
		
		Basis = FillingData;
		
		SurveyDetails = Common.ObjectAttributesValues(FillingData, "Description, Date, StartDate, EndDate, RespondentsType");
		
		If SurveyDetails.RespondentsType = Catalogs.Users.EmptyRef() Then
			Raise NStr("vi = 'Không nên gửi hàng loạt cho khách hàng trên cơ sở khảo sát được thực hiện với người sử dụng.';
						|ru = 'Рассылку клиентам нельзя создать на основании опроса, проводимого среди пользователей.';
						|en = 'Customer mailout cannot be created on the basis of a survey conducted among users.'; fa = 'Customer mailout cannot be created on the basis of a survey conducted among users.';
						|it = 'L''invio di messaggi in blocco non può essere creato in base ad un sondaggio condotto tra gli utenti.';
						|pl = 'Rozsyłkę klientom nie można utworzyć na podstawie sondażu, przeprowadzonego wśród użytkowników.';
						|tr = 'Müşteriler arasında yapılan anket temelinde müşterilere bülten gönderilemez.'")
		EndIf;
		
		SurveyDetails = Common.ObjectAttributesValues(FillingData, "Description, Date, StartDate, EndDate");
		Subject      = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Gửi theo khảo sát ""%1"" ngày %2.';
																					|ru = 'Рассылка по опросу ""%1"" от %2.';
																					|en = 'Mailout based on the ""%1"" survey dated %2.'; fa = 'Mailout based on the ""%1"" survey dated %2.';
																					|it = 'Invio dei messaggi in blocco in base al sondaggio ""%1"" del %2.';
																					|pl = 'Newsletter dotyczący ankietowania ""%1"" z dnia %2.';
																					|tr = '%2 tarihli ""%1"" anket bülteni.'"),
		                                                                    SurveyDetails.Description, SurveyDetails.Date);
		
		MailingDate     = ?(ValueIsFilled(SurveyDetails.StartDate), BegOfDay(SurveyDetails.StartDate), Date(1, 1, 1));
		UpdateDate = ?(ValueIsFilled(SurveyDetails.EndDate), EndOfDay(SurveyDetails.EndDate), Date(1, 1, 1));
		
	EndIf;
	
	EmployeeResponsible = Users.CurrentUser();
	MailingDate  = ?(MailingDate = Date(1, 1, 1), CurrentSessionDate(), MailingDate);
	
EndProcedure

#EndRegion

#Region Private

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	Status = Enums.CustomerMailoutStatuses[NewStatus];
	
	Return CheckFilling();
	
EndFunction

Procedure OnCopy(CopiedObject)
	
	Status = Enums.CustomerMailoutStatuses.Draft;
	
EndProcedure

#EndRegion

#EndIf
