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
Var ChoiceContext;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Disable creation of new mail messages.
	If Not ValueIsFilled(Object.Ref) Then
		Cancel = True;
		Return;
	EndIf;
	
	Object.HTMLText = CommonClientServer.ReplaceProhibitedXMLChars(Object.HTMLText);
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	Interactions.SetEmailFormHeader(ThisObject);
	RestrictedExtensions = FilesOperationsInternal.DeniedExtensionsList();
	DoDisplayImportance();
	
	Interactions.FillChoiceListForReviewAfter(Items.ReviewAfter.ChoiceList);
	If Reviewed Then
		Items.ReviewAfter.Enabled = False;
	EndIf;
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ItemForPlacementName", "AdditionalAttributesPage");
		AdditionalParameters.Insert("DeferredInitialization", True);
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	EndIf;
	// End StandardSubsystems.Properties
	
	If Object.Ref.IsEmpty() Then
		Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	EnableUnsafeContent = False;
	
	Object.HTMLText = CommonClientServer.ReplaceProhibitedXMLChars(Object.HTMLText);
	
	Interactions.SetInteractionFormAttributesByRegisterData(ThisObject);
	
	Attachments.Clear();
	AttachmentTable = EmailManagement.GetEmailAttachments(Object.Ref, True);
	
	If AttachmentTable.Count() > 0 Then
		
		FoundRows = AttachmentTable.FindRows(New Structure("EmailFileID", ""));
		CommonClientServer.SupplementTable(FoundRows, Attachments);
		
	EndIf;
	
	For Each DeletedAttachment In CurrentObject.PendingAttachments Do
		
		NewAttachment = Attachments.Add();
		NewAttachment.FileName = DeletedAttachment.NameAttachment;
		NewAttachment.PictureIndex = FilesOperationsInternalClientServer.IndexOfFileIcon(".msg") + 1;
		
	EndDo;
	
	If Attachments.Count() = 0 Then
		
		Items.Attachments.Visible = False;
		
	EndIf;
	
	If Object.TextType = Enums.EmailTextTypes.HTML Then
		ReadHTMLEmailText();
		Items.EmailText.Type = FormFieldType.HTMLDocumentField;
		Items.EmailText.ReadOnly = False;
	Else
		EmailText = Object.Text;
		Items.EmailText.Type = FormFieldType.TextDocumentField;
	EndIf;
	SetSecurityWarningVisiblity();
	
	SenderPresentation = InteractionsClientServer.GetAddresseePresentation(
		Object.SenderPresentation, Object.SenderAddress,"");
	
	// Generating the To and CC presentation.
	RecipientsPresentation =
		InteractionsClientServer.GetAddressesListPresentation(Object.EmailRecipients, False);
	CCRecipientsPresentation =
		InteractionsClientServer.GetAddressesListPresentation(Object.CCRecipients, False);
	ReplyRecipientsPresentation = 
		InteractionsClientServer.GetAddressesListPresentation(Object.ReplyRecipients, False);
		
	If IsBlankString(CCRecipientsPresentation) Then
		Items.CCRecipientsPresentation.Visible = False;
	EndIf;

	FillAdditionalInformation();
	
	ProcessReadReceiptNecessity();
	
	InteractionsClientServer.CheckContactsFilling(Object, ThisObject, "IncomingEmail");
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = Common.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		If ModulePropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
			UpdateAdditionalAttributesItems();
			ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		EndIf;
	EndIf;
	// End StandardSubsystems.Properties
	
	InteractionsClient.DoProcessNotification(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("CommonForm.ContactsClarification") Then
		
		If TypeOf(ValueSelected) <> Type("Array") Then
			Return;
		EndIf;
		
		FillClarifiedContacts(ValueSelected);
		ContactsChanged = True;
		Modified = True;
		
	Else
		
		InteractionsClient.ChoiceProcessingForm(ThisObject, ValueSelected, ChoiceSource, ChoiceContext);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteMode, PostingMode)
	
	Interactions.BeforeWriteInteractionFromForm(ThisObject, CurrentObject, ContactsChanged);
	
	If Reviewed And ReceiptSendingFlagRequired Then
		SetNotificationSendingFlag(Object.Ref, True);
	EndIf;
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Interactions.OnWriteInteractionFromForm(CurrentObject, ThisObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DetailsPagesAdditionalOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CommonClient.SubsystemExists("StandardSubsystems.Properties")
		And CurrentPage.Name = "AdditionalAttributesPage"
		And Not PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure ReviewAfterChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	InteractionsClient.ProcessSelectionInReviewAfterField(ReviewAfter,
	                                                          ValueSelected,
	                                                          StandardProcessing,
	                                                          Modified);
	
EndProcedure

&AtClient
Procedure ReviewedOnChange(Item)
	
	Items.ReviewAfter.Enabled = Not Reviewed;
	If Reviewed And ReadReceiptRequestRequired Then
		
		OnCloseNotifyHandler = New CallbackDescription("PromptForSendingReadReceiptAfterCompletion", ThisObject);
		ShowQueryBox(OnCloseNotifyHandler,
		       NStr("vi = 'Người gửi đã yêu cầu thông báo về việc đọc. Gửi?';
					|ru = 'Отправитель запросил уведомление о прочтении. Отправить?';
					|en = 'Sender has requested a read receipt. Do you want to send a receipt?'; fa = 'Sender has requested a read receipt. Do you want to send a receipt?';
					|it = 'Mittente ha richiesto l''avviso di lettura. Inviare?';
					|pl = 'Nadawca zażądał wysłania potwierdzenia odczytu. Wysłać?';
					|tr = 'Gönderen, okundu bilgisi talep etti. Gönderilsin mi?'"),
		       QuestionDialogMode.YesNo,
		       ,
		       DialogReturnCode.Yes,
		       NStr("vi = 'Yêu cầu thông báo';
					|ru = 'Запрос уведомления';
					|en = 'Read receipt request'; fa = 'Read receipt request';
					|it = 'Richiesta di avviso';
					|pl = 'Żądanie powiadomienia';
					|tr = 'Bildirim sorgusu'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure EditRecipients()
	
	SendersArray = New Array;
	SendersArray.Add(New Structure("Address,Presentation,Contact",
		Object.SenderAddress,
		Object.SenderPresentation, 
		Object.SenderContact));
	
	RecipientsList = New ValueList;
	RecipientsList.Add(SendersArray, "Sender");
	RecipientsList.Add(
		EmailManagementClient.ContactsTableToArray(Object.EmailRecipients), "Recipients");
	RecipientsList.Add(
		EmailManagementClient.ContactsTableToArray(Object.CCRecipients),  "Cc");
	RecipientsList.Add(
		EmailManagementClient.ContactsTableToArray(Object.ReplyRecipients), "Response");
	
	FormParameters = New Structure;
	FormParameters.Insert("Account", Object.Account);
	FormParameters.Insert("SelectedItemsList", RecipientsList);
	FormParameters.Insert("SubjectOf", SubjectOf);
	FormParameters.Insert("MailMessage", Object.Ref);
	
	OpenForm("CommonForm.ContactsClarification", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure FillClarifiedContacts(Result)
	
	Object.CCRecipients.Clear();
	Object.ReplyRecipients.Clear();
	Object.EmailRecipients.Clear();
	
	For Each ArrayElement In Result Do
	
		If ArrayElement.Group = "Recipients" Then
			TableOfRecipients = Object.EmailRecipients;
		ElsIf ArrayElement.Group = "Cc" Then
			TableOfRecipients = Object.CCRecipients;
		ElsIf ArrayElement.Group = "Response" Then
			TableOfRecipients = Object.ReplyRecipients;
		ElsIf ArrayElement.Group = "Sender" Then
			Object.SenderAddress = ArrayElement.Address;
			Object.SenderContact = ArrayElement.Contact;
			Continue;
		Else
			Continue;
		EndIf;
		
		RowRecipients = TableOfRecipients.Add();
		FillPropertyValues(RowRecipients,ArrayElement);
	
	EndDo;
	
	SenderPresentation = InteractionsClientServer.GetAddresseePresentation(
		Object.SenderPresentation, Object.SenderAddress, "");
	
	// Generating the To and CC presentation.
	RecipientsPresentation       =
		InteractionsClientServer.GetAddressesListPresentation(Object.EmailRecipients, False);
	CCRecipientsPresentation  =
		InteractionsClientServer.GetAddressesListPresentation(Object.CCRecipients, False);
	ReplyRecipientsPresentation = 
		InteractionsClientServer.GetAddressesListPresentation(Object.ReplyRecipients, False);
	
	InteractionsClientServer.CheckContactsFilling(Object, ThisObject, "IncomingEmail");

EndProcedure

&AtClient
Procedure SenderPresentationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	If ValueIsFilled(Object.SenderContact) Then
		ShowValue(, Object.SenderContact);
	Else
		EditRecipients();
	EndIf;
	
EndProcedure

&AtClient
Procedure EmailTextOnClick(Item, EventData, StandardProcessing)
	
	InteractionsClient.HTMLFieldOnClick(Item, EventData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SubjectOfStartChoice(Item, ChoiceData, StandardProcessing)
	
	InteractionsClient.SubjectOfStartChoice(ThisObject, Item, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure WarningAboutUnsafeContentURLProcessing(Item, FormattedStringURL, StandardProcessing)
	If FormattedStringURL = "EnableUnsafeContent" Then
		StandardProcessing = False;
		EnableUnsafeContent = True;
		ReadHTMLEmailText();
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttachments

&AtClient
Procedure AttachmentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	OpenAttachment();
	
EndProcedure

&AtClient
Procedure AttachmentsOnActivateRow(Item)
	
	CurrentData = Items.Attachments.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	AttachmentExists = ValueIsFilled(CurrentData.Ref);
	Items.AttachmentsContextMenuAttachmentProperties.Enabled = AttachmentExists;
	Items.OpenAttachment.Enabled = AttachmentExists;
	Items.SaveAttachment.Enabled = AttachmentExists;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenAttachmentExecute()
	
	OpenAttachment();
	
EndProcedure

&AtClient
Procedure SaveAttachmentExecute()
	
	CurrentData = Items.Attachments.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
		
	If Not ValueIsFilled(CurrentData.Ref) Then
		Return;
	EndIf;
		
	FileGettingParameters = FilesOperationsClient.ParametersForAsynchronousFileReceipt("SaveAs", "FilesOperationsInternal.FileDataEmailManagementAsync");
	FileGettingParameters.AttachedFile	= CurrentData.Ref;
	FileGettingParameters.OwnerForm 		= ThisObject;

	FilesOperationsClient.SaveFileAs(FileGettingParameters);

EndProcedure

&AtClient
Procedure SpecifyContacts(Command)
	
	EditRecipients();
	
EndProcedure

&AtClient
Procedure EmailParameters(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("CreatedOn",             Object.Date);
	FormParameters.Insert("ReceivedEmails",            Object.DateReceived);
	FormParameters.Insert("RequestDeliveryReceipt",  Object.RequestDeliveryReceipt);
	FormParameters.Insert("RequestReadReceipt", Object.RequestReadReceipt);
	FormParameters.Insert("InternetTitles",  Object.InternalTitle);
	FormParameters.Insert("MailMessage",              Object.Ref);
	FormParameters.Insert("EmailType",           "IncomingEmail");
	FormParameters.Insert("Encoding",           Object.Encoding);
	FormParameters.Insert("InternalNumber",     Object.Number);
	FormParameters.Insert("Account",       Object.Account);
	
	OpenForm("DocumentJournal.Interactions.Form.EmailMessageParameters", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure LinkedInteractionsExecute()
	
	FormParameters = New Structure;
	FormParameters.Insert("FilterObject", Object.SubjectOf);
	
	OpenForm("DocumentJournal.Interactions.ListForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ChangeEncoding(Command)
	
	EncodingsList = EncodingsList();
	OnCloseNotifyHandler = New CallbackDescription("SelectEncodingAfterCompletion", ThisObject);
	EncodingsList.ShowChooseItem(OnCloseNotifyHandler,
		NStr("vi = 'Hãy chọn mã hóa';
			|ru = 'Выберите кодировку';
			|en = 'Select encoding'; fa = 'انتخاب کدگذاری';
			|it = 'Selezionate il set di caratteri';
			|pl = 'Wybierz kodowanie';
			|tr = 'Kodlama seç'"), EncodingsList.FindByValue(Lower(Object.Encoding)));
	
EndProcedure 

&AtClient
Procedure AttachmentProperties(Command)
	
	CurrentData = Items.Attachments.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentData.Ref) Then
		Return;
	EndIf;
	
	FormParameters = New Structure("ReadOnly", True);
	FilesOperationsClient.OpenFileForm(CurrentData.Ref, );
	
EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	EndIf;
	
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region Private

&AtClient
Procedure OpenAttachment()
	
	CurrentData = Items.Attachments.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(CurrentData.Ref) Then
		Return;
	EndIf;
		
	If InteractionsClientServer.IsFileEmail(CurrentData.FileName) Then
		AttachmentParameters = InteractionsClient.EmailAttachmentParameters();
		AttachmentParameters.BaseEmailDate = Object.DateReceived;
		AttachmentParameters.EmailBasis     = Object.Ref;
		AttachmentParameters.BaseEmailSubject = Object.Subject;
		InteractionsClient.OpenAttachmentEmail(CurrentData.Ref, AttachmentParameters, ThisObject);
	Else
		EmailManagementClient.OpenAttachment(CurrentData.Ref, ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure TransformEmailEncoding(SelectedEncoding)
	
	TempFileName = GetTempFileName();
	TextWriter = New TextWriter(TempFileName, Object.Encoding);
	TextWriter.Write(
		?(Object.TextType = Enums.EmailTextTypes.HTML, Object.HTMLText, Object.Text));
	TextWriter.Close();
	
	TextReader = New TextReader(TempFileName, SelectedEncoding);
	If Object.TextType = Enums.EmailTextTypes.HTML Then
		Object.HTMLText = TextReader.Read();
		EmailText = Object.HTMLText;
		Interactions.FilterHTMLTextContent(EmailText, SelectedEncoding, Not EnableUnsafeContent, HasUnsafeContent);
	Else
		Object.Text = TextReader.Read();
		EmailText = Object.Text;
	EndIf;
	TextReader.Close();
	DeleteFiles(TempFileName);
	
	TempFileName = GetTempFileName();
	TextWriter = New TextWriter(TempFileName, Object.Encoding);
	TextWriter.WriteLine(SenderPresentation);
	TextWriter.WriteLine(CCRecipientsPresentation);
	TextWriter.WriteLine(ReplyRecipientsPresentation);
	TextWriter.WriteLine(RecipientsPresentation);
	TextWriter.WriteLine(Object.Subject);
	TextWriter.Close();
	
	TextReader = New TextReader(TempFileName, SelectedEncoding);
	SenderPresentation = TextReader.ReadLine();
	CCRecipientsPresentation = TextReader.ReadLine();
	ReplyRecipientsPresentation = TextReader.ReadLine();
	RecipientsPresentation = TextReader.ReadLine();
	Object.Subject = TextReader.ReadLine();
	TextReader.Close();
	DeleteFiles(TempFileName);
	
	Object.Encoding = SelectedEncoding;
	
EndProcedure

&AtServer
Procedure FillAdditionalInformation()
	
	AdditionalInformationAboutEmail = NStr("vi = 'Đã tạo:';
											|ru = 'Создано:';
											|en = 'Created on:'; fa = 'Created on:';
											|it = 'Creato:';
											|pl = 'Utworzono:';
											|tr = 'Oluşturuldu:'") + "   " + Object.Date 
	+ Chars.LF + NStr("vi = 'Đã nhận';
						|ru = 'Получено';
						|en = 'Received'; fa = 'دریافت‌شده';
						|it = 'Ricevuto';
						|pl = 'Otrzymano';
						|tr = 'Alındı'") + ":  " + Object.DateReceived 
	+ Chars.LF + NStr("vi = 'Mức độ quan trọng';
						|ru = 'Важность';
						|en = 'Importance'; fa = 'اهمیت';
						|it = 'Rilevanza';
						|pl = 'Ważność';
						|tr = 'Önem'") + ":  " + Object.Importance
	+ Chars.LF + NStr("vi = 'Mã hóa';
						|ru = 'Кодировка';
						|en = 'Encoding'; fa = 'کدگذاری';
						|it = 'Codifica';
						|pl = 'Kodowanie';
						|tr = 'Kodlama'") + ": " + Object.Encoding;
	
EndProcedure

&AtServer
Procedure DoDisplayImportance()

	Items.DecorationImportance.Visible = True;

	If Object.Importance = Enums.InteractionImportanceOptions.High Then
		Items.DecorationImportance.Picture = PictureLib.ImportanceHigh;
		Items.DecorationImportance.ToolTip = NStr("vi = 'Mức độ quan trọng cao';
													|ru = 'Высокая важность';
													|en = 'High importance'; fa = 'اهمیت بالا';
													|it = 'Alta importanza';
													|pl = 'Wysoka ważność';
													|tr = 'Yüksek önemlilik'");
		
	ElsIf Object.Importance = Enums.InteractionImportanceOptions.Low Then
		Items.DecorationImportance.Picture = PictureLib.ImportanceLow;
		Items.DecorationImportance.ToolTip = NStr("vi = 'Mức độ quan trọng thấp';
													|ru = 'Низкая важность';
													|en = 'Low importance'; fa = 'اهمیت پایین';
													|it = 'Bassa importanza';
													|pl = 'Niska ważność';
													|tr = 'Az önemlilik'");
		
	Else
		Items.DecorationImportance.Picture = PictureLib.ImportanceNotSpecified;
		Items.DecorationImportance.ToolTip = NStr("vi = 'Mức độ quan trọng thường';
													|ru = 'Обычная важность';
													|en = 'Normal importance'; fa = 'اهمیت عادی';
													|it = 'Media importanza';
													|pl = 'Zwykła ważność';
													|tr = 'Normal önemlilik'");
		Items.DecorationImportance.Visible = False;
	EndIf;

EndProcedure

&AtServer
Procedure ProcessReadReceiptNecessity()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReadReceipts.MailMessage
	|FROM
	|	InformationRegister.ReadReceipts AS ReadReceipts
	|WHERE
	|	ReadReceipts.MailMessage = &MailMessage
	|	AND (NOT ReadReceipts.SendingRequired)";
	
	Query.SetParameter("MailMessage",Object.Ref);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	NecessaryAction = Interactions.GetUserParametersForIncomingEmail();
	
	If NecessaryAction = Enums.ReplyToReadReceiptPolicies.AlwaysSendReadReceipt Then
		
		ReceiptSendingFlagRequired = True;
		
	ElsIf NecessaryAction = 
		Enums.ReplyToReadReceiptPolicies.NeverSendReadReceipt Then
		
		EmailManagement.SetNotificationSendingFlag(Object.Ref,False);
		
	ElsIf NecessaryAction = 
		Enums.ReplyToReadReceiptPolicies.AskBeforeSendReadReceipt Then
		
		ReadReceiptRequestRequired = True;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SetNotificationSendingFlag(Ref, Flag)

	EmailManagement.SetNotificationSendingFlag(Ref, Flag)

EndProcedure

&AtClient
Procedure PromptForSendingReadReceiptAfterCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		SetNotificationSendingFlag(Object.Ref, True);
	ElsIf QuestionResult = DialogReturnCode.No Then
		SetNotificationSendingFlag(Object.Ref, False);
	EndIf;
	ReadReceiptRequestRequired = False;
	
EndProcedure

&AtClient
Procedure SelectEncodingAfterCompletion(SelectedElement, AdditionalParameters) Export

	If SelectedElement <> Undefined Then
		TransformEmailEncoding(SelectedElement.Value);
	EndIf;

EndProcedure

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.FillAdditionalAttributesInForm(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	EndIf;
	
EndProcedure

// End StandardSubsystems.Properties

&AtClient
Function EncodingsList()
	
	EncodingsList = New ValueList;
	
	EncodingsList.Add("ibm852",       NStr("vi = 'ibm852 (DOS Trung Âu)';
											|ru = 'ibm852 (Центральноевропейская DOS)';
											|en = 'IBM852 (DOS Central European)'; fa = 'IBM852 (DOS Central European)';
											|it = 'ibm852 (DOS dell''Europa centrale)';
											|pl = 'IBM852 (Europa środkowa DOS)';
											|tr = 'iBM852 (Orta Avrupa DOS)'"));
	EncodingsList.Add("ibm866",       NStr("vi = 'ibm866 (DOS Cyrillic)';
											|ru = 'ibm866 (Кириллица DOS)';
											|en = 'IBM866 (DOS Cyrillic Russian)'; fa = 'IBM866 (DOS Cyrillic Russian)';
											|it = 'ibm866 (Alfabeto cirillico DOS)';
											|pl = 'IBM866 (Cyrylica DOS)';
											|tr = 'iBM866 (Kiril DOS)'"));
	EncodingsList.Add("iso-8859-1",   NStr("vi = 'iso-8859-1 (ISO Tây Âu)';
											|ru = 'iso-8859-1 (Западноевропейская ISO)';
											|en = 'ISO-8859-1 (ISO Western Europe)'; fa = 'ISO-8859-1 (ISO Western Europe)';
											|it = 'iso-8859-1 (ISO dell''Europa occidentale)';
											|pl = 'iso-8859-1 (Europa Zachodnia ISO)';
											|tr = 'ISO-8859-1 (Batı Avrupa ISO)'"));
	EncodingsList.Add("iso-8859-2",   NStr("vi = 'iso-8859-2 ((ISO Trung Âu)';
											|ru = 'iso-8859-2 (Центральноевропейская ISO)';
											|en = 'ISO-8859-2 (ISO Central European)'; fa = 'ISO-8859-2 (ISO Central European)';
											|it = 'iso-8859-2 (ISO dell''Europa centrale)';
											|pl = 'iso-8859-2 (Europa środkowa ISO)';
											|tr = 'ISO-8859-2 (Orta Avrupa ISO)'"));
	EncodingsList.Add("iso-8859-3",   NStr("vi = 'iso-8859-3 (3 ISO Latin)';
											|ru = 'iso-8859-3 (Латиница 3 ISO)';
											|en = 'ISO-8859-3 (ISO Latin 3)'; fa = 'ISO-8859-3 (ISO Latin 3)';
											|it = 'iso-8859-3 (Alfabeto latino 3 ISO)';
											|pl = 'iso-8859-3 (Łaciński 3 ISO)';
											|tr = 'ISO-8859-3 (Latin 3 ISO)'"));
	EncodingsList.Add("iso-8859-4",   NStr("vi = 'iso-8859-4 (ISO Baltic)';
											|ru = 'iso-8859-4 (Балтийская ISO)';
											|en = 'ISO-8859-4 (ISO Baltic)'; fa = 'ISO-8859-4 (ISO Baltic)';
											|it = 'iso-8859-4 (ISO del Baltico)';
											|pl = 'iso-8859-4 (Bałtycki ISO)';
											|tr = 'ISO-8859-4 (Baltik ISO)'"));
	EncodingsList.Add("iso-8859-5",   NStr("vi = 'iso-8859-5 (ISO Cyrillic)';
											|ru = 'iso-8859-5 (Кириллица ISO)';
											|en = 'ISO-8859-5 (ISO Cyrillic)'; fa = 'ISO-8859-5 (ISO Cyrillic)';
											|it = 'iso-8859-5 (Alfabeto cirillico ISO)';
											|pl = 'iso-8859-5 (Cyrylica ISO)';
											|tr = 'ISO-8859-5 (Kiril ISO)'"));
	EncodingsList.Add("iso-8859-7",   NStr("vi = 'iso-8859-7 (ISO Hy Lạp)';
											|ru = 'iso-8859-7 (Греческая ISO)';
											|en = 'ISO-8859-7 (ISO Greek)'; fa = 'ISO-8859-7 (ISO Greek)';
											|it = 'iso-8859-7 (ISO greca)';
											|pl = 'iso-8859-7 (Grecki ISO)';
											|tr = 'ISO-8859-7 (Yunan ISO)'"));
	EncodingsList.Add("iso-8859-9",   NStr("vi = 'ISO-8859-9 (ISO Thổ Nhĩ Kỳ)';
											|ru = 'iso-8859-9 (Турецкая ISO)';
											|en = 'ISO-8859-9 (ISO Turkish)'; fa = 'ISO-8859-9 (ISO Turkish)';
											|it = 'iso-8859-9 (ISO turca)';
											|pl = 'iso-8859-9 (Turecki ISO)';
											|tr = 'ISO-8859-9 (Türkçe ISO)'"));
	EncodingsList.Add("iso-8859-15",  NStr("vi = 'iso-8859-15 (9 ISO Latin)';
											|ru = 'iso-8859-15 (Латиница 9 ISO)';
											|en = 'ISO-8859-15 (ISO Latin 9)'; fa = 'ISO-8859-15 (ISO Latin 9)';
											|it = 'iso-8859-15 (Alfabeto latino 9 ISO)';
											|pl = 'iso-8859-15 (Łaciński 9 ISO)';
											|tr = 'ISO-8859-15 (Latin 9 ISO)'"));
	EncodingsList.Add("koi8-r",       NStr("vi = 'koi8-r (KOI8-R Cyrillic)';
											|ru = 'koi8-r (Кириллица KOI8-R)';
											|en = 'KOI8-R (KOI8-R Cyrillic)'; fa = 'KOI8-R (KOI8-R Cyrillic)';
											|it = 'koi8-r (Alfabeto cirillico KOI8-R)';
											|pl = 'koi8-r (Cyrylica KOI8-R)';
											|tr = 'KOI8-R (Kiril KOI8-R)'"));
	EncodingsList.Add("koi8-u",       NStr("vi = 'koi8-u (KOI8-U Cyrillic)';
											|ru = 'koi8-u (Кириллица KOI8-U)';
											|en = 'KOI8-U (KOI8-U Cyrillic)'; fa = 'KOI8-U (KOI8-U Cyrillic)';
											|it = 'koi8-u (Alfabeto cirillico KOI8-U)';
											|pl = 'koi8-u (Cyrylica KOI8-U)';
											|tr = 'KOI8-U (Kiril KOI8-U)'"));
	EncodingsList.Add("us-ascii",     NStr("vi = 'us-ascii USA';
											|ru = 'us-ascii США';
											|en = 'US-ASCII (USA)'; fa = 'US-ASCII (USA)';
											|it = 'us-ascii USA';
											|pl = 'us-ascii USA';
											|tr = 'us-ascii ABD'"));
	EncodingsList.Add("utf-8",        NStr("vi = 'utf-8 (Unicode UTF-8)';
											|ru = 'utf-8 (Юникод UTF-8)';
											|en = 'UTF-8 (Unicode UTF-8)'; fa = 'UTF-8 (Unicode UTF-8)';
											|it = 'utf-8 (Unicode UTF-8)';
											|pl = 'utf-8 (Unikod UTF-8)';
											|tr = 'UTF-8 (Unicode UTF-8)'"));
	EncodingsList.Add("windows-1250", NStr("vi = 'windows-1250 ((Windows Trung Âu)';
											|ru = 'windows-1250 (Центральноевропейская Windows)';
											|en = 'Windows-1250 (Central European)'; fa = 'Windows-1250 (Central European)';
											|it = 'wndows-1250 (Windows dell''Europa centrale)';
											|pl = 'Windows-1250 (Europa Środkowa Windows)';
											|tr = 'Windows-1250 (Orta Avrupa Windows)'"));
	EncodingsList.Add("windows-1251", NStr("vi = 'windows-1251 (Windows Cyrillic)';
											|ru = 'windows-1251 (Кириллица Windows)';
											|en = 'Windows-1251 (Windows Cyrillic)'; fa = 'Windows-1251 (Windows Cyrillic)';
											|it = 'windows-1251 (Alfabeto cirillico Windows)';
											|pl = 'windows-1251 (Cyrylica Windows)';
											|tr = 'Windows-1251 (Kiril Windows)'"));
	EncodingsList.Add("windows-1252", NStr("vi = 'Windows-1252 (Windows Tây Âu)';
											|ru = 'windows-1252 (Западноевропейская Windows)';
											|en = 'Windows-1252 (Western European)'; fa = 'Windows-1252 (Western European)';
											|it = 'windows-1252 (Windows dell''Europa occidentale)';
											|pl = 'Windows-1252 (Europa Zachodnia Windows)';
											|tr = 'Windows-1252 (Batı Avrupa Windows)'"));
	EncodingsList.Add("windows-1253", NStr("vi = 'Windows-1253 (Windows Hy Lạp)';
											|ru = 'windows-1253 (Греческая Windows)';
											|en = 'Windows-1253 (Windows Greek)'; fa = 'Windows-1253 (Windows Greek)';
											|it = 'windows-1253 (Windows greco)';
											|pl = 'Windows-1253 (Grecki Windows)';
											|tr = 'Windows-1253 (Yunan Windows)'"));
	EncodingsList.Add("windows-1254", NStr("vi = 'Windows-1254 (Windows Thổ Nhĩ Kỳ)';
											|ru = 'windows-1254 (Турецкая Windows)';
											|en = 'Windows-1254 (Windows Turkish)'; fa = 'Windows-1254 (Windows Turkish)';
											|it = 'windows-1254 (Windows turco)';
											|pl = 'Windows-1254 (Turecki Windows)';
											|tr = 'Windows-1254 (Türkçe Windows)'"));
	EncodingsList.Add("windows-1257", NStr("vi = 'Windows-1257 (Windows Baltic)';
											|ru = 'windows-1257 (Балтийская Windows)';
											|en = 'Windows-1257 (Windows Baltic)'; fa = 'Windows-1257 (Windows Baltic)';
											|it = 'windows-1257 (Windows baltico)';
											|pl = 'Windows-1257 (Bałtycki Windows)';
											|tr = 'Windows-1257 (Baltik Windows)'"));
	
	Return EncodingsList;

EndFunction

&AtServer
Procedure SetSecurityWarningVisiblity()
	UnsafeContentDisplayInEmailsProhibited = Interactions.UnsafeContentDisplayInEmailsProhibited();
	Items.SecurityWarning.Visible = Not UnsafeContentDisplayInEmailsProhibited
		And HasUnsafeContent And Not EnableUnsafeContent;
EndProcedure

&AtServer
Procedure ReadHTMLEmailText()
	EmailText = Interactions.ProcessHTMLText(Object.Ref, Not EnableUnsafeContent, HasUnsafeContent);
	SetSecurityWarningVisiblity();
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
	ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
	ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
	ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
