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
	
	OutboundMessageStatus = NStr("vi = 'Đang gửi thông báo...';
								|ru = 'Сообщение отправляется...';
								|en = 'Sending message…'; fa = 'Sending message…';
								|it = 'Invio messaggio...';
								|pl = 'Wysyłanie wiadomości...';
								|tr = 'Mesaj gönderiliyor...'");
	MessageText = Parameters.Text;
	
	PhoneNumbers = New Array;
	If TypeOf(Parameters.RecipientsNumbers) = Type("Array") Then
		For Each PhoneInformation In Parameters.RecipientsNumbers Do
			PhoneNumbers.Add(PhoneInformation.Phone);
		EndDo;
	ElsIf TypeOf(Parameters.RecipientsNumbers) = Type("ValueList") Then
		For Each PhoneInformation In Parameters.RecipientsNumbers Do
			PhoneNumbers.Add(PhoneInformation.Value);
		EndDo;
	Else
		PhoneNumbers.Add(String(Parameters.RecipientsNumbers));
	EndIf;
	
	If PhoneNumbers.Count() = 0 Then
		Items.RecipientNumberGroup.Visible = True;
	EndIf;
	
	RecipientsNumbers = StrConcat(PhoneNumbers, ", ");
	
	TitleTemplate1 = NStr("vi = 'Gửi tin nhắn SMS đến số điện thoại %1';
							|ru = 'Отправка SMS на телефон %1';
							|en = 'Text message to: %1'; fa = 'Text message to: %1';
							|it = 'Invio SMS al telefono %1';
							|pl = 'Wysyłanie SMS na telefon %1';
							|tr = 'Telefonda SMS Mesajlaması %1'");
	If PhoneNumbers.Count() > 1 Then
		TitleTemplate1 = NStr("vi = 'Gửi tin nhắn SMS đến số điện thoại: %1';
								|ru = 'Отправка SMS на телефоны: %1';
								|en = 'Text message to: %1 phones'; fa = 'Text message to: %1 phones';
								|it = 'Invio SMS ai telefoni: %1';
								|pl = 'Wysyłanie SMS na telefony: %1';
								|tr = 'Telefonda SMS Mesajlaması: %1'");
	EndIf;
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, RecipientsNumbers);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	CharactersInMessage = StrLen(MessageText);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MentionSenderNameOnChange(Item)
	Items.SenderName.Enabled = MentionSenderName;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Send(Command)
	
	If StrLen(MessageText) = 0 Then
		ShowMessageBox(, NStr("vi = 'Hãy nhập nội dung tin nhắn';
								|ru = 'Введите текст сообщения';
								|en = 'Enter a message text'; fa = 'Enter a message text';
								|it = 'Inserire testo del messaggio';
								|pl = 'Wprowadź tekst wiadomości';
								|tr = 'Mesaj metnini girin'"));
		Return;
	EndIf;
	
	If Not SMSMessageSendingIsSetUp() Then
		OpenForm("CommonForm.OutboundSMSSettings");
		Return;
	EndIf;
	
	Items.Pages.CurrentPage = Items.StatusPage;
	
	If Items.Find("SMSSendingOpenSetting") <> Undefined Then
		Items.SMSSendingOpenSetting.Visible = False;
	EndIf;
	
	Items.Close.Visible = True;
	Items.Close.DefaultButton = True;
	Items.Send.Visible = False;
	
	// Send from server context.
	SendSMS();

	// Check a sending status.
	If Not IsBlankString(MessageID) Then
		Items.Pages.CurrentPage = Items.MessageSentPage;
		AttachIdleHandler("CheckDeliveryStatus", 2, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SendSMS()
	
	MessageID = "";
	NumbersArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(RecipientsNumbers, ", ", True);
	SendingResult = SendSMSMessage.SendSMS(NumbersArray, MessageText, ?(MentionSenderName, SenderName, Undefined), SendInTransliteration);
	
	If IsBlankString(SendingResult.ErrorDescription) Then
		// Check delivery for the first recipient.
		If SendingResult.SentMessages.Count() > 0 Then
			MessageID = SendingResult.SentMessages[0].MessageID;
		EndIf;
		Items.Pages.CurrentPage = Items.MessageSentPage;
	Else
		Items.Pages.CurrentPage = Items.MessageNotSentPage;
		
		MessageTemplate = NStr("vi = 'Chưa gửi:
		|%1.';
		|ru = 'Отправка не выполнена:
		|%1.';
		|en = 'Couldn''t send the text message.
		|%1.'; fa = 'Couldn''t send the text message.
		|%1.';
		|it = 'Invio fallito:
		|%1.';
		|pl = 'Nie wykonano wysyłania:
		|%1.';
		|tr = 'Gönderilmedi:
		|%1.'");
		Items.MessageNotSentText.Title = FormattedString(StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate, SendingResult.ErrorDescription));
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckDeliveryStatus()
	
	DeliveryResult = DeliveryStatus(MessageID);
	OutboundMessageStatus = DeliveryResult.LongDesc;
	
	DeliveryResults = New Array;
	DeliveryResults.Add("Error");
	DeliveryResults.Add("NotDelivered");
	DeliveryResults.Add("Delivered");
	DeliveryResults.Add("NotSent");
	
	StatusCheckCompleted = DeliveryResults.Find(DeliveryResult.Status) <> Undefined;
	Items.DeliveryStatusCheckGroup.Visible = StatusCheckCompleted;
	
	StateTemplate = NStr("vi = 'Đã gửi tin nhắn. Trạng thái gửi:
		|%1.';
		|ru = 'Отправка сообщения выполнена. Состояние доставки:
		|%1.';
		|en = 'The message is sent. Delivery status:
		|%1'; fa = 'The message is sent. Delivery status:
		|%1';
		|it = 'Invio del messaggio riuscito. Stato dell''invio: 
		|%1.';
		|pl = 'Wysyłanie wiadomości zostało wykonane. Stan dostarczenia:
		|%1.';
		|tr = 'Mesaj gönderildi. Teslimat durumu:
		|%1.'");
	Items.MessageSentText.Title = StringFunctionsClientServer.SubstituteParametersToString(
		StateTemplate, DeliveryResult.LongDesc);
	
	
	If DeliveryResult.Status = "Error" Then
		Items.MessageSentPicture.Picture = PictureLib.DialogStop;
	Else
		If DeliveryResults.Find(DeliveryResult.Status) <> Undefined Then
			If Not DeliveryResult.Status = "Delivered" Then
				Items.MessageSentPicture.Picture = PictureLib.DialogExclamation;
			EndIf;
			Items.DeliveryStatusCheckGroup.Visible = False;
		Else
			AttachIdleHandler("CheckDeliveryStatus", 2, True);
			Items.DeliveryStatusCheckGroup.Visible = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DeliveryStatus(MessageID)
	
	DeliveryStatuses = New Map;
	DeliveryStatuses.Insert("Error", NStr("vi = 'không có kết nối đến nhà cung cấp SMS';
											|ru = 'нет подключения к провайдеру SMS';
											|en = 'no connection to the text message service owner'; fa = 'no connection to the text message service owner';
											|it = 'нет подключения к провайдеру SMS';
											|pl = 'no connection to the text message service owner';
											|tr = 'SMS sağlayıcısına bağlanılamadı'"));
	DeliveryStatuses.Insert("Pending", NStr("vi = 'nhà cung cấp chưa gửi tin nhắn';
											|ru = 'сообщение не отправлялось провайдером';
											|en = 'Provider queued message for delivery'; fa = 'Provider queued message for delivery';
											|it = 'Il messaggio non è stato inviato dal provider';
											|pl = 'wiadomość nie była wysyłana przez dostawcę';
											|tr = 'mesaj sağlayıcı tarafından gönderilmedi'"));
	DeliveryStatuses.Insert("Sending2", NStr("vi = 'nhà cung cấp đang gửi';
											|ru = 'выполняется отправка провайдером';
											|en = 'Provider is delivering message'; fa = 'Provider is delivering message';
											|it = 'Invio del messaggio da parte del provider in corso';
											|pl = 'trwa wysyłanie przez dostawcę';
											|tr = 'sağlayıcı tarafından gönderim yapılıyor'"));
	DeliveryStatuses.Insert("Sent", NStr("vi = 'nhà cung cấp đã gửi';
										|ru = 'отправлено провайдером';
										|en = 'Provider sent the message'; fa = 'Provider sent the message';
										|it = 'inviato dal provider';
										|pl = 'wysłano przez dostawcę';
										|tr = 'sağlayıcı tarafından gönderildi'"));
	DeliveryStatuses.Insert("NotSent", NStr("vi = 'nhà cung cấp chưa gửi tin nhắn';
											|ru = 'сообщение не отправлено провайдером';
											|en = 'Provider did not send message'; fa = 'Provider did not send message';
											|it = 'Messaggio non inviato da parte del provider';
											|pl = 'wiadomość nie została wysłana przez dostawcę';
											|tr = 'mesaj sağlayıcı tarafından gönderilmedi'"));
	DeliveryStatuses.Insert("Delivered", NStr("vi = ' đã gửi tin nhắn';
												|ru = 'сообщение доставлено';
												|en = 'Message is delivered'; fa = 'Message is delivered';
												|it = 'messaggio inviato';
												|pl = 'wiadomość została dostarczona';
												|tr = 'mesaj teslim edildi'"));
	DeliveryStatuses.Insert("NotDelivered", NStr("vi = 'chưa gửi tin nhắn';
												|ru = 'сообщение не доставлено';
												|en = 'Message is not delivered'; fa = 'Message is not delivered';
												|it = 'messaggio non inviato';
												|pl = 'wiadomość nie została dostarczona';
												|tr = 'mesaj teslim edilmedi'"));
	
	DeliveryResult = New Structure("Status, LongDesc");
	DeliveryResult.Status = SendSMSMessage.DeliveryStatus(MessageID);
	DeliveryResult.LongDesc = DeliveryStatuses[DeliveryResult.Status];
	If DeliveryResult.LongDesc = Undefined Then
		DeliveryResult.LongDesc = "<" + DeliveryResult.Status + ">";
	EndIf;
	
	Return DeliveryResult;
	
EndFunction

&AtClient
Procedure TextChangeEditText(Item, Text, StandardProcessing)
	CharactersInMessage = StrLen(Text);
	StandardProcessing = False;
EndProcedure

&AtServerNoContext
Function SMSMessageSendingIsSetUp()
 	Return SendSMSMessage.SMSMessageSendingSetupCompleted();
EndFunction

&AtServerNoContext
Function FormattedString(Text)
	
	FormattedStrings = New Array;
	
	Rows = StrSplit(Text, Chars.LF, True);
	For RowsIndex = 0 To Rows.UBound() Do
		String = Rows[RowsIndex];
		Words = StrSplit(String, " ", True);
		For WordIndex = 0 To Words.UBound() Do
			Particle = Words[WordIndex];
			If StrStartsWith(Particle, "http://") Or StrStartsWith(Particle, "https://") Then
				FormattedStrings.Add(New FormattedString(Particle, , , , Particle));
			Else
				FormattedStrings.Add(New FormattedString(Particle));
			EndIf;
			If WordIndex <> Words.UBound() Then
				FormattedStrings.Add(" ");
			EndIf;
		EndDo;
		If RowsIndex <> Rows.UBound() Then
			FormattedStrings.Add(Chars.LF);
		EndIf;
	EndDo;
	
	Return New FormattedString(FormattedStrings); // ACC:1356 Does not prevent translating into other languages.
	
EndFunction

#EndRegion
