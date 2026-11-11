///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var RecipientsHistory;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Common.SetChoiceListConditionalAppearance(ThisObject, 
		"RecipientsEmailAddressSendingOption", "RecipientsMailAddresses.SendingOption");
	
	SuccessResultColor = StyleColors.SuccessResultColor;
	
	AttachmentsForEmail = New Structure;
	
	If TypeOf(Parameters.Attachments) = Type("ValueList") Or TypeOf(Parameters.Attachments) = Type("Array") Then
		For Each Attachment In Parameters.Attachments Do
			DetermineEmailAttachmentPurpose(Attachment, AttachmentsForEmail);
		EndDo;
	EndIf;
	
	EmailSubject = Parameters.Subject;
	EmailBody.SetHTML(HTMLWrappedText(Parameters.Text), AttachmentsForEmail);
	ReplyToAddress = Parameters.ReplyToAddress;
	SubjectOf = Parameters.SubjectOf;
	EmailImportance = "Ordinary";
	
	If Not ValueIsFilled(Parameters.Sender) Then
		// Account is not passed. Selecting the first available account.
		AvailableEmailAccounts = EmailOperations.AvailableEmailAccounts(True);
		If AvailableEmailAccounts.Count() = 0 Then
			MessageText = NStr("vi = 'Không tìm thấy tài khoản hợp lệ, hãy liên hệ với người quản trị hệ thống.';
								|ru = 'Не обнаружены доступные учетные записи электронной почты, обратитесь к администратору системы.';
								|en = 'There are no email accounts available. Please contact your system administrator.'; fa = 'There are no email accounts available. Please contact your system administrator.';
								|it = 'Non sono stati rilevati account di posta elettronica disponibili, rivolgersi all''amministratore di sistema.';
								|pl = 'Nie znaleziono dostępnych kont poczty elektronicznej, skontaktuj się z administratorem systemu.';
								|tr = 'Kullanılabilir e-posta hesapları bulunamadı, sistem yöneticisine başvurun.'");
			Common.MessageToUser(MessageText,,,,Cancel);
			Return;
		EndIf;
		
		Account = AvailableEmailAccounts[0].Ref;
		
	ElsIf TypeOf(Parameters.Sender) = Type("CatalogRef.EmailAccounts") Then
		Account = Parameters.Sender;
	ElsIf TypeOf(Parameters.Sender) = Type("ValueList") Then
		EmailAccountList = Parameters.Sender;
		
		If EmailAccountList.Count() = 0 Then
			MessageText = NStr("vi = 'Chưa chỉ ra tài khoản để gửi tin nhắn, hãy liên hệ với người quản trị hệ thống.';
								|ru = 'Не указаны учетные записи для отправки сообщения, обратитесь к администратору системы.';
								|en = 'No accounts for sending mail are specified. Please contact your system administrator.'; fa = 'No accounts for sending mail are specified. Please contact your system administrator.';
								|it = 'Non sono indicati account per l''invio del messaggio, rivolgersi all''amministratore di sistema.';
								|pl = 'Nie wskazano kont do wysłania wiadomości, skontaktuj się z administratorem systemu.';
								|tr = 'E-posta hesapları belirtilmedi, sistem yöneticisine başvurun.'");
			Common.MessageToUser(MessageText,,,, Cancel);
			Return;
		EndIf;
		
		For Each ItemAccount In EmailAccountList Do
			Items.Account.ChoiceList.Add(
										ItemAccount.Value,
										ItemAccount.Presentation);
			If ItemAccount.Value.UseForReceiving Then
				ReplyToAddressesByAccounts.Add(ItemAccount.Value,
														GetEmailAddressByAccount(ItemAccount.Value));
			EndIf;
		EndDo;
		
		Items.Account.ChoiceList.SortByPresentation();
		Account = EmailAccountList[0].Value;
		
		// Selecting accounts from the passed account list.
		Items.Account.DropListButton = True;
	EndIf;
	
	If TypeOf(Parameters.Recipient) = Type("ValueList") Then
		
		For Each ItemEmailAddress In Parameters.Recipient Do
			NewRecipient = RecipientsMailAddresses.Add();
			NewRecipient.SendingOption = "Whom";
			If ValueIsFilled(ItemEmailAddress.Presentation) Then
				NewRecipient.Presentation = ItemEmailAddress.Presentation
										+ " <"
										+ ItemEmailAddress.Value
										+ ">"
			Else
				NewRecipient.Presentation = ItemEmailAddress.Value;
			EndIf;
		EndDo;
		
	ElsIf TypeOf(Parameters.Recipient) = Type("String") Then
		NewRecipient                 = RecipientsMailAddresses.Add();
		NewRecipient.SendingOption = "Whom";
		NewRecipient.Presentation   = Parameters.Recipient;
	ElsIf TypeOf(Parameters.Recipient) = Type("Array") Then
		For Each RecipientStructure1 In Parameters.Recipient Do
			HasPropertySelected = RecipientStructure1.Property("Selected");
			AddressesArray      = StrSplit(RecipientStructure1.Address, ";");
			SendingOption = ?(RecipientStructure1.Property("SendingOption"), RecipientStructure1.SendingOption, "Whom");
			
			If SendingOption = "ReplyTo" Then
				ReplyToAddress = ?(IsBlankString(ReplyToAddress), RecipientStructure1.Address, 
					ReplyToAddress + ";" + RecipientStructure1.Address);
				Continue;
			EndIf;
			
			If Items.RecipientsEmailAddressSendingOption.ChoiceList.FindByValue(SendingOption) = Undefined Then
				SendingOption = "Whom";
			EndIf;
			
			For Each Address In AddressesArray Do
				If IsBlankString(Address) Then
					Continue;
				EndIf;
				If (HasPropertySelected And RecipientStructure1.Selected) Or (Not HasPropertySelected) Then
					NewRecipient                 = RecipientsMailAddresses.Add();
					NewRecipient.SendingOption = SendingOption;
					NewRecipient.Presentation   = RecipientStructure1.Presentation + " <" + TrimAll(Address) + ">";
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	If TypeOf(Parameters.Recipient) = Type("Array") Then
		If TypeOf(Parameters.Recipient) = Type("String") Then
			FillRecipientsTableFromRow(Parameters.Recipient);
		ElsIf TypeOf(Parameters.Recipient) = Type("ValueList") Then
			MessageRecipients = (Parameters.Recipient);
		ElsIf TypeOf(Parameters.Recipient) = Type("Array") Then
			FillRecipientsTableFromStructuresArray(Parameters.Recipient);
		EndIf;
		
		RecipientDetailsInTempStorage = PutToTempStorage(Parameters.Recipient, UUID);
	Else
		RecipientDetailsInTempStorage = PutToTempStorage(New Array, UUID);
	EndIf;
	
	If RecipientsMailAddresses.Count() = 0 Then
		NewRow                 = RecipientsMailAddresses.Add();
		NewRow.SendingOption = "Whom";
		NewRow.Presentation   = "";
	EndIf;
	
	// Getting the list of addresses that the user previously used.
	ReplyToList = Common.CommonSettingsStorageLoad(
		"EditNewEmailMessage", "ReplyToList");
	
	If ReplyToList <> Undefined And ReplyToList.Count() > 0 Then
		For Each ReplyToItem In ReplyToList Do
			Items.ReplyToAddress.ChoiceList.Add(ReplyToItem.Value, ReplyToItem.Presentation);
		EndDo;
		
		Items.ReplyToAddress.DropListButton = True;
	EndIf;
	
	If ValueIsFilled(ReplyToAddress) Then
		FillReplyToAddressAutomatically = False;
	Else
		UserAccountAttributes = Common.ObjectAttributesValues(Account,
			"UseForReceiving,UserName,Email");
		
		If UserAccountAttributes.UseForReceiving Then
			// Setting default email address
			If ValueIsFilled(UserAccountAttributes.UserName) Then 
				ReplyToAddress = UserAccountAttributes.UserName + " <" + UserAccountAttributes.Email + ">";
			Else
				ReplyToAddress = UserAccountAttributes.Email;
			EndIf;
		EndIf;
		
		FillReplyToAddressAutomatically = True;
	EndIf;
	
	// StandardSubsystems.MessageTemplates
	
	Items.FormGenerateFromTemplate.Visible = False;
	Items.FormSaveAsTemplate.Visible    = False;
	
	If Common.SubsystemExists("StandardSubsystems.MessageTemplates")Then
		ModuleMessageTemplatesInternal = Common.CommonModule("MessageTemplatesInternal");
		
		If ModuleMessageTemplatesInternal.MessageTemplatesUsed() Then
			Items.FormGenerateFromTemplate.Visible = ModuleMessageTemplatesInternal.HasAvailableTemplates("MailMessage", SubjectOf);
			Items.FormSaveAsTemplate.Visible    = True;
		EndIf;
		
	EndIf;
	
	// End StandardSubsystems.MessageTemplates
	
	If Common.IsMobileClient() Then
		Items.Attachment2.Visible = False;
		Items.EmailBodyMainGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.EmailSubject.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ImportAttachmentsFromFiles();
	RefreshAttachmentPresentation();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	If Not FormClosingConfirmationRequired Then
		Return;
	EndIf;
	
	Cancel = True;
	If Exit Then
		Return;
	EndIf;
	
	AttachIdleHandler("ShowQueryBoxBeforeCloseForm", 0.1, True);
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Not Exit Then
		AttachmentAddresses = New Array;
		For Each Attachment In Attachments Do
			AttachmentAddresses.Add(Attachment.AddressInTempStorage);
		EndDo;
		ClearAttachments(AttachmentAddresses);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// Populating the reply address if the flag of automatic reply address substitution is set.
//
&AtClient
Procedure AccountChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If IsBlankString(ReplyToAddress) Then
		FillReplyToAddressAutomatically = True;
	EndIf;
	
	If FillReplyToAddressAutomatically Then
		If ReplyToAddressesByAccounts.FindByValue(ValueSelected) <> Undefined Then
			ReplyToAddress = ReplyToAddressesByAccounts.FindByValue(ValueSelected).Presentation;
		Else
			ReplyToAddress = GetEmailAddressByAccount(ValueSelected);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetFormModificationFlag(Item)
	FormClosingConfirmationRequired = True;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRecipientsMailAddresses

&AtClient
Procedure RecipientPostalAddressesBeforeDelete(Item, Cancel)
	
	If RecipientsMailAddresses.Count() = 1 Then
		Cancel = True;
		RecipientsMailAddresses[0].Presentation = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure RecipientPostalAddressesOnStartEdit(Item, NewRow, Copy)
	If NewRow Then
		Item.CurrentData.SendingOption = "Whom";
		Item.CurrentItem                = Items.RecipientsEmailAddressPresentation;
	EndIf;
EndProcedure

&AtClient
Procedure RecipientsEmailAddressPresentationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If MessageRecipients.Count() = 0 Then
		ChoiceData = SimilarRecipientsFromHistory(Text);
	Else
		ChoiceData = SimilarRecipientsFromPassedRecipients(Text);
	EndIf;
	
	If ChoiceData.Count() > 0 Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure RecipientPostalAddressesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If CancelEdit Then
		Return;
	EndIf;
	
	RowData = Item.CurrentData;
	If RowData = Undefined Then
		Return;
	EndIf;
	
	For Each Recipient In CommonClientServer.EmailsFromString(RowData.Presentation) Do
		If Not IsBlankString(Recipient.ErrorDescription) Then
			ShowMessageBox(, Recipient.ErrorDescription);
			Cancel = True;
			Return;
		EndIf;
	EndDo;
	
	Duplicates = New Map;
	For Each EmailRecipient In RecipientsMailAddresses Do
		MailAddr = EmailAddressFromPresentation(EmailRecipient.Presentation);
		If Duplicates[Upper(MailAddr)] = Undefined Then
			Duplicates.Insert(Upper(MailAddr), True);
		Else
			ShowMessageBox(, NStr("vi = 'Địa chỉ thư như vậy đã có trong danh sách.';
									|ru = 'Такой адрес электронной почты уже есть в списке.';
									|en = 'This email address already exists.'; fa = 'This email address already exists.';
									|it = 'Indirizzo di posta elettronica già presente nell''elenco.';
									|pl = 'Taki adres poczty elektronicznej jest już na liście.';
									|tr = 'Bu e-posta adresi listede zaten mevcut.'"));
			Cancel = True;
			Return;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion


#Region FormTableItemsEventHandlersAttachments

// Removes an attachment from the list and also calls the function
// that updates the table of attachment presentations.
//
&AtClient
Procedure AttachmentsBeforeDeleteRow(Item, Cancel)
	
	AttachmentDescription = Item.CurrentData[Item.CurrentItem.Name];
	
	For Position = -Attachments.Count() + 1 To 0 Do
		If Attachments.Get(-Position).Presentation = AttachmentDescription Then
			Attachments.Delete(-Position);
		EndIf;
	EndDo;
	
	RefreshAttachmentPresentation();
	
EndProcedure

&AtClient
Procedure AttachmentsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	AddFileToAttachments();
	
EndProcedure

&AtClient
Procedure AttachmentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenAttachment();
	
EndProcedure

&AtClient
Procedure AttachmentsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AttachmentsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	ValueCollection = DragParameters.Value;
	If TypeOf(ValueCollection) <> Type("Array") Then
		ValueCollection = CommonClientServer.ValueInArray(DragParameters.Value);
	EndIf;
	
	FilesToUpload = New Array;
	For Each File In ValueCollection Do
		If TypeOf(File) = Type("FileRef") Then
			FilesToUpload.Add(File);
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(FilesToUpload) Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("OnImportAttachments", ThisObject);
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	ImportParameters.Interactively = False;
	FileSystemClient.ImportFiles(CallbackDescription, ImportParameters, FilesToUpload);
	
EndProcedure

&AtClient
Procedure ReplyToAddressTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	
	FillReplyToAddressAutomatically = False;
	ReplyToAddress = GetNormalizedEmailInFormat(Text);
	
EndProcedure

&AtClient
Procedure ReplyToAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	FillReplyToAddressAutomatically = False;
	
EndProcedure

&AtClient
Procedure ReplyToAddressClearing(Item, StandardProcessing)

	StandardProcessing = False;
	SaveReplyTo(ReplyToAddress, False);
	
	For Position = -Items.ReplyToAddress.ChoiceList.Count() + 1 To 0 Do
		ReplyToItem = Items.ReplyToAddress.ChoiceList.Get(-Position);
		If ReplyToItem.Value = ReplyToAddress
		   And ReplyToItem.Presentation = ReplyToAddress Then
			Items.ReplyToAddress.ChoiceList.Delete(-Position);
		EndIf;
	EndDo;
	
	ReplyToAddress = "";
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenFile(Command)
	OpenAttachment();
EndProcedure

&AtClient
Procedure SendMail()
	
	ClearMessages();
	HasWrongRecipients = False;
	MessageSent = False;
	
	If Not FieldsFilledCorrectly() Then
		Return;
	EndIf;
	
	Try
		MessageSent = SendEmailMessage(HasWrongRecipients);
	Except
		
		ErrorInfo = ErrorInfo();
		
		If Not EmailOperationsInternalClientServer.IsInternetMailError(ErrorInfo) Then
			Raise;
		EndIf;
		
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		ErrorTitle = NStr("vi = 'Chưa gửi thư';
							|ru = 'Письмо не отправлено';
							|en = 'The message is not sent'; fa = 'The message is not sent';
							|it = 'Posta non inviata';
							|pl = 'Wiadomość nie była wysłana';
							|tr = 'E-posta gönderilmedi'");
		EmailOperationsClient.ReportConnectionError(Account, ErrorTitle, ErrorText);
		
		Return;
		
	EndTry;
	
	If MessageSent Then
		SaveReplyTo(ReplyToAddress);
		FormClosingConfirmationRequired = False;
		
		ShowUserNotification(NStr("vi = 'Đã gửi thông báo:';
									|ru = 'Сообщение отправлено:';
									|en = 'Message sent:'; fa = 'Message sent:';
									|it = 'Messaggio inviato:';
									|pl = 'Wiadomość została wysłana:';
									|tr = 'Mesaj gönderildi:'"), ,
			?(IsBlankString(EmailSubject), NStr("vi = '<Không có chủ đề>';
												|ru = '<Без темы>';
												|en = '<No subject>'; fa = '<No subject>';
												|it = '<senza soggetto>';
												|pl = '<Bez tematu>';
												|tr = '<Konu yok>'"), EmailSubject), PictureLib.DialogInformation);
		
		If HasWrongRecipients Then
			ShowMessageBox(, NStr("vi = 'Bức thư không được gửi đến tất cả người nhận.';
									|ru = 'Письмо отправлено не всем получателям.';
									|en = 'The message is not sent to some recipients.'; fa = 'The message is not sent to some recipients.';
									|it = 'La lettera non è stata inviata a tutti i destinatari.';
									|pl = 'Wiadomość została nie wszystkim odbiorcom.';
									|tr = 'E-posta tüm alıcılara gönderilmedi.'"));
		Else
			Close();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function FieldsFilledCorrectly()
	Result = True;
	
	If RecipientsMailAddresses.Count() = 0 Then
		CommonClient.MessageToUser(
			NStr("vi = 'Hãy điền người nhận E-mail';
				|ru = 'Заполните получателя письма';
				|en = 'Please specify at least one recipient.'; fa = 'Please specify at least one recipient.';
				|it = 'Compilare destinatario lettera';
				|pl = 'Wypełnij odbiorcę wiadomości';
				|tr = 'E-posta alıcısını ekle'"), , "RecipientsMailAddresses");
		Result = False;
	EndIf;
	For Each EmailRecipient1 In RecipientsMailAddresses Do
		Address = EmailAddressFromPresentation(EmailRecipient1.Presentation);
		If IsBlankString(Address) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Hãy điền người nhận E-mail';
					|ru = 'Заполните получателя письма';
					|en = 'Please specify at least one recipient.'; fa = 'Please specify at least one recipient.';
					|it = 'Compilare destinatario lettera';
					|pl = 'Wypełnij odbiorcę wiadomości';
					|tr = 'E-posta alıcısını ekle'"),, "RecipientsMailAddresses[" + Format(RecipientsMailAddresses.IndexOf(EmailRecipient1), "NG=0") + "].Presentation");
			Result = False;
		ElsIf Not CommonClientServer.EmailAddressMeetsRequirements(Address, False) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Sai địa chỉ thư';
					|ru = 'Неверный адрес электронной почты';
					|en = 'Invalid email address.'; fa = 'Invalid email address.';
					|it = 'Indirizzo di posta elettronica errato';
					|pl = 'Nieprawidłowy adres poczty elektronicznej';
					|tr = 'Yanlış e-posta adresi'"),, "RecipientsMailAddresses[" + Format(RecipientsMailAddresses.IndexOf(EmailRecipient1), "NG=0") + "].Presentation");
			Result = False;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure AttachFileExecute()
	
	AddFileToAttachments();
	
EndProcedure

&AtClient
Procedure ImportanceHigh(Command)
	EmailImportance = EmailOperationsInternalClientServer.InternetMailMessageImportanceHigh();
	Items.SeverityGroup.Picture = PictureLib.ImportanceHigh;
	Items.SeverityGroup.ToolTip = NStr("vi = 'Mức độ quan trọng cao';
										|ru = 'Высокая важность';
										|en = 'High importance'; fa = 'اهمیت بالا';
										|it = 'Alta importanza';
										|pl = 'Wysoka ważność';
										|tr = 'Yüksek önemlilik'");
	Modified = True;
EndProcedure

&AtClient
Procedure ImportanceNormal(Command)
	EmailImportance = EmailOperationsInternalClientServer.InternetMailMessageImportanceStandard();
	Items.SeverityGroup.Picture = PictureLib.ImportanceNotSpecified;
	Items.SeverityGroup.ToolTip = NStr("vi = 'Mức độ quan trọng thường';
										|ru = 'Обычная важность';
										|en = 'Normal importance'; fa = 'اهمیت عادی';
										|it = 'Media importanza';
										|pl = 'Zwykła ważność';
										|tr = 'Normal önemlilik'");
	Modified = True;
EndProcedure

&AtClient
Procedure ImportanceLow(Command)
	EmailImportance = EmailOperationsInternalClientServer.InternetMailMessageImportanceLow();
	Items.SeverityGroup.Picture = PictureLib.ImportanceLow;
	Items.SeverityGroup.ToolTip = NStr("vi = 'Mức độ quan trọng thấp';
										|ru = 'Низкая важность';
										|en = 'Low importance'; fa = 'اهمیت پایین';
										|it = 'Bassa importanza';
										|pl = 'Niska ważność';
										|tr = 'Az önemlilik'");
	Modified = True;
EndProcedure

// StandardSubsystems.MessageTemplates

&AtClient
Procedure GenerateFromTemplate(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.MessageTemplates") Then
		ModuleMessageTemplatesClient = CommonClient.CommonModule("MessageTemplatesClient");
		Notification = New CallbackDescription("FillByTemplateAfterTemplateChoice", ThisObject);
		MessageSubject = ?(ValueIsFilled(SubjectOf), SubjectOf, "Shared");
		ModuleMessageTemplatesClient.PrepareMessageFromTemplate(MessageSubject, "MailMessage", Notification);
	EndIf
	
EndProcedure

// End StandardSubsystems.MessageTemplates

#EndRegion

#Region Private

&AtServer
Function SendEmailMessage(HasWrongRecipients)
	
	EmailParameters = GenerateEmailParameters();
	If EmailParameters = Undefined Then
		Return False;
	EndIf;
	
	MailMessage = EmailOperations.PrepareEmail(Account, EmailParameters);
	SendingResult = EmailOperations.SendMail(Account, MailMessage);
	EmailOperationsOverridable.AfterEmailSending(EmailParameters);
	
	AddRecipientsToHistory(EmailParameters.Whom);
	
	WrongRecipients = SendingResult.WrongRecipients;
	If WrongRecipients.Count() > 0 Then
		For Each WrongRecipient In WrongRecipients Do
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1: %2';
					|ru = '%1: %2';
					|en = '%1: %2'; fa = '%1: %2';
					|it = '%1: %2';
					|pl = '%1: %2';
					|tr = '%1: %2'"),
				WrongRecipient.Key, WrongRecipient.Value);
				
			Field = "RecipientsMailAddresses";
			For Each RecipientAddress In RecipientsMailAddresses Do
				If StrFind(RecipientAddress.Presentation, WrongRecipient.Key) > 0 Then
					Field = Field + "[" + XMLString(RecipientsMailAddresses.IndexOf(RecipientAddress)) + "].Presentation";
					Break;
				EndIf;
			EndDo;
				
			Common.MessageToUser(ErrorText, , Field);
		EndDo;
		
		HasWrongRecipients = True;
		Return RecipientsMailAddresses.Count() > WrongRecipients.Count();
	EndIf;
	
	Return True;
	
EndFunction

&AtServerNoContext
Function GetEmailAddressByAccount(Val Account)
	
	Return TrimAll(Account.UserName)
			+ ? (IsBlankString(TrimAll(Account.UserName)),
					Account.Email,
					" <" + Account.Email + ">");
	
EndFunction

&AtClient
Procedure OpenAttachment()
	
	SelectedAttachment = SelectedAttachment();
	If SelectedAttachment = Undefined Then
		Return;
	EndIf;
	
#If Not WebClient Then
	If StrEndsWith(SelectedAttachment.Presentation, ".mxl") Then
		CallbackDescription = New CallbackDescription("ContinueOpeningMXLFileAfterCreateDirectory", ThisObject, SelectedAttachment);
		FileSystemClient.CreateTemporaryDirectory(CallbackDescription);
		Return;
	EndIf;
#EndIf
	
	FileSystemClient.OpenFile(SelectedAttachment.AddressInTempStorage, , SelectedAttachment.Presentation);
	
EndProcedure

&AtClient
Procedure ContinueOpeningMXLFileAfterCreateDirectory(TempDirectoryName, SelectedAttachment) Export
	
#If Not WebClient Then
	TempFileName = CommonClientServer.AddLastPathSeparator(TempDirectoryName) 
		+ SelectedAttachment.Presentation;
	SpreadsheetDocument = GetSpreadsheetDocumentByBinaryData(SelectedAttachment.AddressInTempStorage);
	
	BinaryData = GetFromTempStorage(SelectedAttachment.AddressInTempStorage); // BinaryData
	BinaryData.Write(TempFileName);
	File = New File(TempFileName);
	File.SetReadOnly(True);
	
	FormParameters = StandardSubsystemsClient.SpreadsheetEditorParameters();
	FormParameters.DocumentName = SelectedAttachment.Presentation;
	FormParameters.PathToFile = TempFileName;
	
	StandardSubsystemsClient.ShowSpreadsheetEditor(SpreadsheetDocument, FormParameters);
#EndIf
	
EndProcedure

&AtClient
Function SelectedAttachment()
	
	Result = Undefined;
	If Items.Attachments.CurrentData <> Undefined Then
		AttachmentDescription = Items.Attachments.CurrentData[Items.Attachments.CurrentItem.Name];
		For Each Attachment In Attachments Do
			If Attachment.Presentation = AttachmentDescription Then
				Result = New Structure("Presentation, AddressInTempStorage");
				FillPropertyValues(Result, Attachment);
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function GetSpreadsheetDocumentByBinaryData(Val BinaryData)
	
	If TypeOf(BinaryData) = Type("String") Then
		// Transferring binary data address to temporary storage.
		BinaryData = GetFromTempStorage(BinaryData); // BinaryData
	EndIf;
	
	FileName = GetTempFileName("mxl");
	BinaryData.Write(FileName);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Read(FileName);
	
	Try
		DeleteFiles(FileName);
	Except
		WriteLogEvent(NStr("vi = 'Nhận văn bản dạng bảng';
							|ru = 'Получение табличного документа';
							|en = 'Get spreadsheet document'; fa = 'Get spreadsheet document';
							|it = 'Ricezione del documento tabulare';
							|pl = 'Pobieranie dokumentu tabelarycznego';
							|tr = 'Elektronik çizelge belgesini al'", Common.DefaultLanguageCode()), EventLogLevel.Error, , , 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return SpreadsheetDocument;
	
EndFunction

&AtClient
Procedure AddFileToAttachments()
	
	CallbackDescription = New CallbackDescription("AddFileToAttachmentsOnPutFiles", ThisObject);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	FileSystemClient.ImportFiles(CallbackDescription, ImportParameters);
	
EndProcedure

&AtClient
Procedure AddFileToAttachmentsOnPutFiles(PlacedFiles, AdditionalParameters) Export
	If PlacedFiles = Undefined Or PlacedFiles.Count() = 0 Then
		Return;
	EndIf;
	AddFilesToList(PlacedFiles);
	RefreshAttachmentPresentation();
	FormClosingConfirmationRequired = True;
EndProcedure

&AtServer
Procedure AddFilesToList(PlacedFiles)
	
	For Each FileDetails In PlacedFiles Do
		File = New File(FileDetails.Name);
		Attachment = Attachments.Add();
		Attachment.Presentation = File.Name;
		Attachment.AddressInTempStorage = PutToTempStorage(GetFromTempStorage(FileDetails.Location), UUID);
	EndDo;
	
EndProcedure

&AtClient
Procedure RefreshAttachmentPresentation()
	
	AttachmentsPresentation.Clear();
	
	IndexOf = 0;
	
	For Each Attachment In Attachments Do
		If IndexOf = 0 Then
			PresentationRow = AttachmentsPresentation.Add();
		EndIf;
		
		PresentationRow["Attachment" + Format(IndexOf + 1, "NG=0")] = Attachment.Presentation;
		If Items.Attachment2.Visible Then // For mobile client.
			IndexOf = IndexOf + 1;
			If IndexOf = 2 Then 
				IndexOf = 0;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Checks whether it is possible to send the email.
// If it is possible, sending parameters are generated.
//
&AtServer
Function GenerateEmailParameters()
	
	EmailParameters = New Structure;
	Whom = New Array;
	Cc = New Array;
	BCCs = New Array;
	
	For Each Recipient In RecipientsMailAddresses Do
		RecipientsEmailAddr = CommonClientServer.EmailsFromString(Recipient.Presentation);
		For Each RecipientEmailAddr In RecipientsEmailAddr Do
			If Recipient.SendingOption = "HiddenCopy" Then
				BCCs.Add(New Structure("Address, Presentation", RecipientEmailAddr.Address, RecipientEmailAddr.Alias));
			ElsIf Recipient.SendingOption = "Copy" Then
				Cc.Add(New Structure("Address, Presentation", RecipientEmailAddr.Address, RecipientEmailAddr.Alias));
			Else
				Whom.Add(New Structure("Address, Presentation", RecipientEmailAddr.Address, RecipientEmailAddr.Alias));
			EndIf;
		EndDo;
	EndDo;
	
	If Whom.Count() > 0 Then
		EmailParameters.Insert("Whom", Whom);
	EndIf;
	If Cc.Count() > 0 Then
		EmailParameters.Insert("Cc", Cc);
	EndIf;
	If BCCs.Count() > 0 Then
		EmailParameters.Insert("BCCs", BCCs);
	EndIf;
	
	RecipientsList = CommonClientServer.EmailsFromString(ReplyToAddress);
	Whom = New Array;
	For Each Recipient In RecipientsList Do
		If Not IsBlankString(Recipient.ErrorDescription) Then
			Common.MessageToUser(
				Recipient.ErrorDescription, , "ReplyToAddress");
			Return Undefined;
		EndIf;
		Whom.Add(New Structure("Address, Presentation", Recipient.Address, Recipient.Alias));
	EndDo;
	
	If ValueIsFilled(ReplyToAddress) Then
		EmailParameters.Insert("ReplyToAddress", ReplyToAddress);
	EndIf;
	
	If ValueIsFilled(EmailSubject) Then
		EmailParameters.Insert("Subject", EmailSubject);
	EndIf;
	
	If ValueIsFilled(RecipientDetailsInTempStorage) Then
		EmailParameters.Insert("MessageRecipients", GetFromTempStorage(RecipientDetailsInTempStorage));
	EndIf;
	
	EmailParameters.Insert("Body", EmailBody);
	EmailParameters.Insert("Attachments", Attachments());
	EmailParameters.Insert("Importance", ?(ValueIsFilled(EmailImportance),
		EmailOperationsInternal.InternetMailMessageImportanceFromString(EmailImportance), InternetMailMessageImportance.Normal));
	
	Return EmailParameters;
	
EndFunction

&AtServer
Function HTMLWrappedText(Text)
	
	If StrFind(Lower(Text), "</html>", SearchDirection.FromEnd) > 0 Then
		Return Text;
	EndIf;
	
	HTMLDocument = New HTMLDocument;
	
	ItemBody = HTMLDocument.CreateElement("body");
	HTMLDocument.Body = ItemBody;
	
	For LineNumber = 1 To StrLineCount(Text) Do
		String = StrGetLine(Text, LineNumber);
		
		ItemBlock = HTMLDocument.CreateElement("p");
		ItemBody.AppendChild(ItemBlock);
		
		Item_Text = HTMLDocument.CreateTextNode(String);
		ItemBlock.AppendChild(Item_Text);
	EndDo;
	
	DOMWriter = New DOMWriter;
	HTMLWriter = New HTMLWriter;
	HTMLWriter.SetString();
	DOMWriter.Write(HTMLDocument, HTMLWriter);
	Result = HTMLWriter.Close();
	
	Return Result;
	
EndFunction

&AtServer
Function Attachments()
	
	Result = New Array;
	For Each Attachment In Attachments Do
		AttachmentDetails = New Structure;
		AttachmentDetails.Insert("Presentation", Attachment.Presentation);
		AttachmentDetails.Insert("AddressInTempStorage", Attachment.AddressInTempStorage);
		AttachmentDetails.Insert("Encoding", Attachment.Encoding);
		AttachmentDetails.Insert("Id", Attachment.Id);
		Result.Add(AttachmentDetails);
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure DetermineEmailAttachmentPurpose(Attachment, AttachmentsForEmail)
	
	If Attachment.Property("Id") And ValueIsFilled(Attachment.Id) Then
		PictureAttachment = New Picture(GetFromTempStorage(Attachment.AddressInTempStorage));
		AttachmentsForEmail.Insert(Attachment.Presentation, PictureAttachment);
	Else
		AttachmentDetails = Attachments.Add();
		FillPropertyValues(AttachmentDetails, Attachment);
		If Not IsBlankString(AttachmentDetails.AddressInTempStorage) Then
			AttachmentDetails.AddressInTempStorage = PutToTempStorage(
			GetFromTempStorage(AttachmentDetails.AddressInTempStorage), UUID);
		EndIf;
	EndIf;

EndProcedure

&AtServerNoContext
Procedure SaveReplyTo(Val ReplyToAddress, Val AddAddressToList = True)
	
	// Getting the list of addresses that the user previously used.
	ReplyToList = Common.CommonSettingsStorageLoad(
		"EditNewEmailMessage",
		"ReplyToList");
	
	If ReplyToList = Undefined Then
		ReplyToList = New ValueList();
	EndIf;
	
	For Position = -ReplyToList.Count() + 1 To 0 Do
		ItemReplyTo = ReplyToList.Get(-Position);
		If ItemReplyTo.Value = ReplyToAddress
		   And ItemReplyTo.Presentation = ReplyToAddress Then
			ReplyToList.Delete(-Position);
		EndIf;
	EndDo;
	
	If AddAddressToList
	   And ValueIsFilled(ReplyToAddress) Then
		ReplyToList.Insert(0, ReplyToAddress, ReplyToAddress);
	EndIf;
	
	Common.CommonSettingsStorageSave(
		"EditNewEmailMessage",
		"ReplyToList",
		ReplyToList);
	
EndProcedure

&AtClient
Function GetNormalizedEmailInFormat(Text)
	AddressesAsString = "";
	Addresses = CommonClientServer.EmailsFromString(Text);
	
	If Addresses.Count() > 1 Then
		CommonClient.MessageToUser(
			NStr("vi = 'Có thể chỉ ra một địa chỉ để phản hồi.';
				|ru = 'Можно указывать только один адрес для ответа.';
				|en = 'Please specify a single reply-to address.'; fa = 'Please specify a single reply-to address.';
				|it = 'È possibile indicare un solo indirizzo per la risposta.';
				|pl = 'Można określać tylko jeden adres do odpowiedzi.';
				|tr = 'Cevap için sadece bir adres belirtilebilir.'"), , "ReplyToAddress");
		Return Text;
	EndIf;
	
	For Each AddrDetails In Addresses Do
		If Not IsBlankString(AddrDetails.ErrorDescription) Then
			CommonClient.MessageToUser(AddrDetails.ErrorDescription, , "ReplyToAddress");
		EndIf;
		
		If Not IsBlankString(AddressesAsString) Then
			AddressesAsString = AddressesAsString + "; ";
		EndIf;
		AddressesAsString = AddressesAsString + AddressAsString(AddrDetails);
	EndDo;
	
	Return AddressesAsString;
EndFunction

&AtClient
Function AddressAsString(AddrDetails)
	Result = "";
	If IsBlankString(AddrDetails.Alias) Then
		Result = AddrDetails.Address;
	Else
		If IsBlankString(AddrDetails.Address) Then
			Result = AddrDetails.Alias;
		Else
			Result = StringFunctionsClientServer.SubstituteParametersToString(
				"%1 <%2>", AddrDetails.Alias, AddrDetails.Address);
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

&AtClient
Procedure OnImportAttachments(Files, AdditionalParameters) Export
	
	If Files = Undefined Then
		Return;
	EndIf;
	
	AddFilesToList(Files);
	RefreshAttachmentPresentation();
	FormClosingConfirmationRequired = True;
	
EndProcedure

&AtClient
Procedure ImportAttachmentsFromFiles()
	
	For Each Attachment In Attachments Do
		If Not IsBlankString(Attachment.PathToFile) Then
			BinaryData = New BinaryData(Attachment.PathToFile);
			Attachment.AddressInTempStorage = PutToTempStorage(BinaryData, UUID);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ShowQueryBoxBeforeCloseForm()
	QueryText = NStr("vi = 'Còn chưa gửi thông báo. Đóng biểu mẫu?';
					|ru = 'Сообщение еще не отправлено. Закрыть форму?';
					|en = 'The message is not yet sent. Do you want to close the window?'; fa = 'The message is not yet sent. Do you want to close the window?';
					|it = 'Messaggio ancora non inviato. Chiudere modulo?';
					|pl = 'Wiadomość nie została jeszcze wysłana. Zamknąć formularz?';
					|tr = 'Mesaj henüz gönderilmedi. Formu kapat?'");
	CallbackDescription = New CallbackDescription("CloseFormConfirmed", ThisObject);
	Buttons = New ValueList;
	Buttons.Add("Close", NStr("vi = 'Đóng';
								|ru = 'Закрыть';
								|en = 'Close'; fa = 'بستن';
								|it = 'Chiudere';
								|pl = 'Zamknij';
								|tr = 'Kapat'"));
	Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Không đóng';
												|ru = 'Не закрывать';
												|en = 'Do not close'; fa = 'بسته نشود';
												|it = 'Non chiudere';
												|pl = 'Nie zamykaj';
												|tr = 'Kapatmayın'"));
	ShowQueryBox(CallbackDescription, QueryText, Buttons,,
		DialogReturnCode.Cancel, NStr("vi = 'Gửi thông điệp';
										|ru = 'Отправка сообщения';
										|en = 'Send message'; fa = 'ارسال پیام';
										|it = 'Invio del messaggio';
										|pl = 'Wysyłanie wiadomości';
										|tr = 'Mesaj gönder'"));
EndProcedure

&AtClient
Procedure CloseFormConfirmed(QuestionResult, AdditionalParameters = Undefined) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	FormClosingConfirmationRequired = False;
	Close();
	
EndProcedure

&AtClient
Procedure SaveAsTemplate(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.MessageTemplates") Then
		ModuleMessageTemplatesClientServer = CommonClient.CommonModule("MessageTemplatesClientServer");
		TemplateParameters = ModuleMessageTemplatesClientServer.TemplateParametersDetails();
		ModuleMessageTemplatesClient = CommonClient.CommonModule("MessageTemplatesClient");
		TemplateParameters.Subject = EmailSubject;
		TemplateParameters.Text = EmailBody.GetText();
		TemplateParameters.TemplateType = "MailMessage";
		ModuleMessageTemplatesClient.ShowTemplateForm(TemplateParameters);
	EndIf;
	
EndProcedure

// Parameters:
//  Result - See MessageTemplatesInternal.GenerateMessage
//  AdditionalParameters - Arbitrary
//
&AtClient
Procedure FillByTemplateAfterTemplateChoice(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		EmailSubject = Result.Subject;
		SetEmailTextAndAttachments(Result.Text, Result.Attachments);
		RefreshAttachmentPresentation();
		
		If TypeOf(Result.Recipient) = Type("ValueList") Then
			For Each Recipient In Result.Recipient Do
				RecipientAddress                 = RecipientsMailAddresses.Add();
				RecipientAddress.SendingOption = "Whom";
				RecipientAddress.Presentation   = Recipient.Presentation;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure SetEmailTextAndAttachments(Text, AttachmentsStructure)
	
	HTMLAttachments = New Structure();
	If TypeOf(AttachmentsStructure) = Type("Array") Then
		For Each Attachment In AttachmentsStructure Do
			DetermineEmailAttachmentPurpose(Attachment, HTMLAttachments);
		EndDo;
	EndIf;
		
	EmailBody.SetHTML(Text, HTMLAttachments);
	
EndProcedure

&AtClient
Function EmailAddressFromPresentation(Val Presentation)
	
	Address = Presentation;
	PositionStart = StrFind(Presentation, "<");
	If PositionStart > 0 Then
		PositionEnd1 = StrFind(Presentation, ">", SearchDirection.FromBegin, PositionStart);
		If PositionEnd1 > 0 Then
			Address = Mid(Presentation, PositionStart + 1, PositionEnd1 - PositionStart - 1);
		EndIf;
	EndIf;
	
	Return TrimAll(Address);

EndFunction

&AtServer
Procedure FillRecipientsTableFromStructuresArray(MessageRecipientParameters)
	
	For Each RecipientParameters In MessageRecipientParameters Do
		If ValueIsFilled(RecipientParameters.Address) Then
			Address = StrReplace(RecipientParameters.Presentation, ",", " ") + " < "+ RecipientParameters.Address + ">";
			
			If RecipientParameters.Property("EmailAddressKind") 
				And ValueIsFilled(RecipientParameters.EmailAddressKind) Then
				Presentation = Address + " (" + RecipientParameters.EmailAddressKind + ")";
			ElsIf RecipientParameters.Property("ContactInformationSource")
				And ValueIsFilled(RecipientParameters.ContactInformationSource) Then
				Presentation = Address + " (" + String(RecipientParameters.ContactInformationSource) + ")";
			Else
				Presentation = Address;
			EndIf;
			MessageRecipients.Add(Address, Presentation);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillRecipientsTableFromRow(Val MessageRecipientParameters)
	
	MessageRecipientParameters = CommonClientServer.EmailsFromString(MessageRecipientParameters);
	
	For Each RecipientParameters In MessageRecipientParameters Do
		If ValueIsFilled(RecipientParameters.Address) Then
			MessageRecipients.Add(RecipientParameters.Address, RecipientParameters.Alias);
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure ClearAttachments(AttachmentAddresses)
	For Each AttachmentAddress In AttachmentAddresses Do
		DeleteFromTempStorage(AttachmentAddress);
	EndDo;
EndProcedure

&AtServerNoContext
Procedure AddRecipientsToHistory(EmailRecipients)
	
	RecipientsHistory = RecipientsHistory();
	For Each Recipient In EmailRecipients Do
		RecipientsHistory.Insert(Recipient.Address, Recipient.Presentation);
	EndDo;
	
	Common.CommonSettingsStorageSave("EditNewEmailMessage", "RecipientsHistory", RecipientsHistory);
	
EndProcedure

&AtServerNoContext
Function RecipientsHistory()
	
	Return Common.CommonSettingsStorageLoad("EditNewEmailMessage", "RecipientsHistory", New Map);
	
EndFunction

&AtClient
Function AddressPresentation(Address, RecipientPresentation1)
	Result = Address;
	If Not IsBlankString(RecipientPresentation1) Then
		Result = StringFunctionsClientServer.SubstituteParametersToString("%1 <%2>", RecipientPresentation1, Address);
	EndIf;
	Return Result;
EndFunction

&AtClient
Function SimilarRecipientsFromHistory(String)
	
	Result = New ValueList;
	If StrLen(String) = 0 Then
		Return Result;
	EndIf;
	
	If RecipientsHistory = Undefined Then
		RecipientsHistory = RecipientsHistory();
	EndIf;
	
	For Each Recipient In RecipientsHistory Do
		AddressPresentation = AddressPresentation(Recipient.Key, Recipient.Value);
		Position = StrFind(Lower(AddressPresentation), Lower(String));
		If Position > 0 Then
			SubstringBeforeOccurence = Left(AddressPresentation, Position - 1);
			OccurenceSubstring = Mid(AddressPresentation, Position, StrLen(String));
			SubstringAfterOccurence = Mid(AddressPresentation, Position + StrLen(String));
			HighlightedString = New FormattedString(
				SubstringBeforeOccurence,
				New FormattedString(OccurenceSubstring, StyleFontImportantLabelFont(), SuccessResultColor),
				SubstringAfterOccurence);
			Result.Add(AddressPresentation, HighlightedString);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Function SimilarRecipientsFromPassedRecipients(Val Text)
	
	Result = New ValueList;
	
	AddressesList = New Array;
	For Each TableRow In RecipientsMailAddresses Do
		Address = EmailAddressFromPresentation(TableRow.Presentation);
		If ValueIsFilled(Address) Then
			AddressesList.Add(Upper(Address));
		EndIf;
	EndDo;
	
	PresentationSelect = New FormattedString(Text, StyleFontImportantLabelFont(), SuccessResultColor);
	TextLength = StrLen(Text);
	For Each Mail In MessageRecipients Do
		Address = EmailAddressFromPresentation(Mail.Value);
		If AddressesList.Find(Upper(Address)) = Undefined Then
			Position = StrFind(Mail.Value, Text);
			If Position > 0 Then
				Presentation= New FormattedString(Left(Mail.Presentation, Position - 1), PresentationSelect, Mid(Mail.Presentation, Position + TextLength));
				Result.Add(Mail.Value, Presentation);
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Function StyleFontImportantLabelFont()
	Return CommonClient.StyleFont("ImportantLabelFont");
EndFunction
	

#EndRegion
