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
	
	SubjectOf            = Parameters.SubjectOf;
	MessageKind       = Parameters.MessageKind;
	ChoiceMode        = Parameters.ChoiceMode;
	TemplateOwner    = Parameters.TemplateOwner;
	MessageParameters = Parameters.MessageParameters;
	PrepareTemplate  = Parameters.PrepareTemplate;
	
	If TypeOf(MessageParameters) = Type("Structure") And MessageParameters.Property("MessageSourceFormName") Then
		MessageSourceFormName = MessageParameters.MessageSourceFormName;
	EndIf;
	
	If ValueIsFilled(SubjectOf) And TypeOf(SubjectOf) <> Type("String") Then
		FullBasisTypeName = SubjectOf.Metadata().FullName();
	EndIf;
	
	If MessageKind = "SMSMessage" Then
		ForSMSMessages = True;
		Title = NStr("vi = 'Mẫu tin nhắn SMS';
					|ru = 'Шаблоны сообщений SMS';
					|en = 'Text templates'; fa = 'Text templates';
					|it = 'Modelli di messaggi SMS';
					|pl = 'Szablony wiadomości SMS';
					|tr = 'SMS şablonları'");
	ElsIf MessageKind = "MailMessage" Then
		ForEmails = True;
	Else
		Title = NStr("vi = 'Mẫu tin nhắn';
					|ru = 'Шаблоны сообщений';
					|en = 'Message templates'; fa = 'الگوهای پیام';
					|it = 'Modelli dei messaggi';
					|pl = 'Szablony wiadomości';
					|tr = 'İleti şablonları'");
	EndIf;
	
	If Not AccessRight("Update", Metadata.Catalogs.MessageTemplates) Then
		HasUpdateRight = False;
		Items.FormChange.Visible = False;
		Items.FormCreate.Visible  = False;
	Else
		HasUpdateRight = True;
	EndIf;
	
	AttachmentsKinds.Add("PrintForms", NStr("vi = 'Mẫu in';
											|ru = 'Печатные формы';
											|en = 'Print forms'; fa = 'فرم‌های چاپی';
											|it = 'Modelli di stampa';
											|pl = 'Formularze wydruku';
											|tr = 'Yazdırma formları'"));
	AttachmentsKinds.Add("ExportFiles", NStr("vi = 'Tệp kết xuất';
											|ru = 'Файлы выгрузки';
											|en = 'Export files'; fa = 'Export files';
											|it = 'Export files';
											|pl = 'Export files';
											|tr = 'Yükleme dosyaları'"));
	
	SetConditionalAppearance();
	
	If ChoiceMode Or MessageKind = "Arbitrary" Then
		Items.FormGenerateAndSend.Visible = False;
		Items.FormGenerate.Title = NStr("vi = 'Chọn';
										|ru = 'Выбрать';
										|en = 'Select'; fa = 'انتخاب';
										|it = 'Selezionare';
										|pl = 'Select';
										|tr = 'Seç'");
	ElsIf PrepareTemplate Then
		Items.FormGenerateAndSend.Visible = False;
	EndIf;
	
	FillAvailableTemplatesList();
	FillPrintFormsAndExportTemplatesList();
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		For Each SaveFormat In ModulePrintManager.SpreadsheetDocumentSaveFormatsSettings() Do
			SelectedSaveFormats.Add(String(SaveFormat.SpreadsheetDocumentFileType), SaveFormat.Presentation, False, SaveFormat.Picture);
		EndDo;
		Items.SignatureAndSeal.Visible = ModulePrintManager.PrintSettings().UseSignaturesAndSeals;
		
		If Common.SubsystemExists("StandardSubsystems.ExportObjectsToFiles") Then
			
			TitleSelectPrintForms = NStr("vi = 'Hãy chọn mẫu in hoặc tệp kết xuất';
										|ru = 'Выберите печатные формы или файлы выгрузки';
										|en = 'Choose print forms or export files'; fa = 'Choose print forms or export files';
										|it = 'Choose print forms or export files';
										|pl = 'Choose print forms or export files';
										|tr = 'Yazdırma formlarını seçin veya dosya yükleyin'");
			Items.SelectPrintFormsExportFiles.Title = TitleSelectPrintForms;
			
		EndIf;
		
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_MessageTemplates" Then
		SelectedItemRef = Undefined;
		If Items.Templates.CurrentData <> Undefined Then
			SelectedItemRef = Items.Templates.CurrentData.Ref;
		EndIf;
		FillAvailableTemplatesList();
		FoundRows = Templates.FindRows(New Structure("Ref", SelectedItemRef));
		If FoundRows.Count() > 0 Then
			Items.Templates.CurrentRow = FoundRows[0].GetID();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ShowTemplatesChoiceForm Then
		If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
			SetFormatSelection();
			GeneratePresentationForSelectedFormats();
		EndIf;
	Else
		SendOptions = SendOptionsConstructor();
		SendOptions.AdditionalParameters.ConvertHTMLForFormattedDocument = False;
		GenerateMessageToSend(SendOptions);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AttachmentFormatClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("OnSelectAttachmentFormat", ThisObject);
	CommonClient.ShowAttachmentsFormatSelection(CallbackDescription, SelectedFormatSettings(), ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTemplates

&AtClient
Procedure TemplatesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	Cancel = True;
	If Copy And Not Var_Group Then
		CreateNewTemplate(Item.CurrentData.Ref);
	Else
		CreateNewTemplate();
	EndIf;
EndProcedure

&AtClient
Procedure TemplatesBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure TemplatesOnActivateRow(Item)
	If Item.CurrentData <> Undefined Then
		TemplateSelected = Item.CurrentData.Name <> "<NoTemplate>";
		Items.FormGenerateAndSend.Enabled = TemplateSelected;
		If TemplateSelected Or Not CommonClient.SubsystemExists("StandardSubsystems.Print") Then
			If Item.CurrentData.EmailTextType = PredefinedValue("Enum.EmailEditingMethods.HTML") Then
				Items.PreviewPages.CurrentPage = Items.FormattedDocumentPage;
				AttachIdleHandler("UpdatePreviewData", 0.2, True);
			Else
				Items.PreviewPages.CurrentPage = Items.PlainTextPage;
				PreviewPlainText.SetText(Item.CurrentData.TemplateText);
			EndIf;
		Else
			Items.PreviewPages.CurrentPage = Items.PagePrintFormsExportFiles;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure TemplatesBeforeRowChange(Item, Cancel)
	Cancel = True;
	If Item.CurrentData <> Undefined Then
		FormParameters = New Structure("Key", Item.CurrentData.Ref);
		OpenForm("Catalog.MessageTemplates.ObjectForm", FormParameters);
	EndIf;
EndProcedure

&AtClient
Procedure TemplatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	GenerateMessageFromSelectedTemplate();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttachments

&AtClient
Procedure AttachmentsSelectedItemsCountOnChange(Item)
	
	CurrentData = Items.Attachments.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.SelectedItemsCount = 2 Then
		CurrentData.SelectedItemsCount = 0;
	EndIf;
	
	SetSubordinateMarks(CurrentData, "SelectedItemsCount");
	SetParentMarks(CurrentData, "SelectedItemsCount");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	
	GenerateMessageFromSelectedTemplate();
	
EndProcedure

&AtClient
Procedure GenerateAndSend(Command)
	
	If TypeOf(Items.Templates.CurrentRow) <> Type("Number") Then
		Return;
	EndIf;
	
	CurrentData = Templates.FindByID(Items.Templates.CurrentRow);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SendOptions = SendOptionsConstructor(CurrentData.Ref);
	GenerateAndSend = True;
	If CurrentData.HasArbitraryParameters Then
		ParametersInput(CurrentData.Ref, SendOptions);
	Else
		SendMessage1(SendOptions);
	EndIf;
	
EndProcedure

&AtClient
Procedure Create(Command)
	CreateNewTemplate();
EndProcedure

&AtClient
Procedure ParametersInput(Template, SendOptions)
	
	ParametersToFill = New Structure("Template, SubjectOf", Template, SubjectOf);
	
	Notification = New CallbackDescription("AfterParametersInput", ThisObject, SendOptions);
	OpenForm("Catalog.MessageTemplates.Form.FillArbitraryParameters", ParametersToFill,,,,, Notification);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GenerateMessageFromSelectedTemplate()

	If TypeOf(Items.Templates.CurrentRow) <> Type("Number") Then
		Return;
	EndIf;
	
	CurrentData = Templates.FindByID(Items.Templates.CurrentRow);
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ChoiceMode Or MessageKind = "Arbitrary" Then
		Close(CurrentData.Ref);
		Return;
	EndIf;
	
	SendOptions = SendOptionsConstructor(CurrentData.Ref);
	SendOptions.AdditionalParameters.ConvertHTMLForFormattedDocument = True;
	
	If CurrentData.HasArbitraryParameters Then
		ParametersInput(CurrentData.Ref, SendOptions);
	Else
		GenerateMessageToSend(SendOptions);
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateMessageToSend(SendOptions)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		CompletionHandler = New CallbackDescription(
			"BeforeContinueGenerateMessageToSend", ThisObject, SendOptions);
		
		ModulePrintManagerClient = CommonClient.CommonModule("PrintManagementClient");
		ModulePrintManagerClient.BeforeStartExecutePrintCommand(
			SubjectOf, SendOptions.AdditionalParameters.PrintForms, CompletionHandler);
		
		Return;
	EndIf;
	
	ContinueGenerateMessageToSend(SendOptions);
	
EndProcedure

&AtClient
Procedure BeforeContinueGenerateMessageToSend(PrintForms, SendOptions) Export
	
	SendOptions.AdditionalParameters.PrintForms = PrintForms;
	
	ContinueGenerateMessageToSend(SendOptions);
	
EndProcedure

&AtClient
Procedure ContinueGenerateMessageToSend(SendOptions)
	
	ShouldGenerateWithoutTempl = Not ValueIsFilled(SendOptions.Template);
	If ShouldGenerateWithoutTempl Then
		
		SaveSelectedPrintFormsAndExportFiles();
		
	EndIf;
	
	TempStorageAddress = Undefined;
	TempStorageAddress = PutToTempStorage(Undefined, UUID);
	
	ShouldGenerateWithoutTemplateAndSign = ShouldGenerateWithoutTempl And Sign;
	If ShouldGenerateWithoutTemplateAndSign Then
		SendOptions.AdditionalParameters.SettingsForSaving.PackToArchive = False;
	EndIf;
	
	ResultAddress = GenerateMessageAtServer(TempStorageAddress, SendOptions, MessageKind);
	
	Result = GetFromTempStorage(ResultAddress); // See MessageTemplatesInternal.GenerateMessage
	
	Result.Insert("SubjectOf", SubjectOf);
	Result.Insert("Template",  SendOptions.Template);
	If SendOptions.AdditionalParameters.Property("MessageParameters")
		And TypeOf(SendOptions.AdditionalParameters.MessageParameters) = Type("Structure") Then
		CommonClientServer.SupplementStructure(Result, MessageParameters, False);
	EndIf;
	
	If ShouldGenerateWithoutTemplateAndSign 
	   And TypeOf(Result.Attachments) = Type("Array") 
	   And Result.Attachments.Count() > 0 Then
		SendOptions.AdditionalParameters.SettingsForSaving.PackToArchive = PackToArchive;
		SIgnFiles(Result, SendOptions);
	Else
		GenerateMessageToSendEnding(Result, SendOptions)
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateMessageToSendEnding(Result, SendOptions)
	
	If GenerateAndSend Then
		AfterGenerateAndSendMessage(Result, SendOptions);
	Else
		If PrepareTemplate Then
			Close(Result);
		Else
			Close();
			ShowMessageForm(Result);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function GenerateMessageAtServer(TempStorageAddress, SendOptions, MessageKind)
	
	ServerCallParameters = New Structure();
	ServerCallParameters.Insert("SendOptions", SendOptions);
	ServerCallParameters.Insert("MessageKind",      MessageKind);
	If Common.SubsystemExists("StandardSubsystems.Interactions") Then
		ModuleInteractions = Common.CommonModule("Interactions");
		SendOptions.AdditionalParameters.Insert("ExtendedRecipientsList", ModuleInteractions.AreOtherInteractionsUsed());
	EndIf;
	
	MessageTemplatesInternal.GenerateMessageInBackground(ServerCallParameters, TempStorageAddress, GenerateAndSend);
	
	Return TempStorageAddress;
	
EndFunction

// Parameters:
//  Result - Map - if data was entered by the user:
//            - DialogReturnCode - — if data input is canceled
//            - Undefined - — if the window was closed
//  SendOptions - See MessageTemplatesClientServer.SendOptionsConstructor
//
&AtClient
Procedure AfterParametersInput(Result, SendOptions) Export
	
	If Result <> Undefined And Result <> DialogReturnCode.Cancel Then
		SendOptions.AdditionalParameters.ArbitraryParameters = Result;
		GenerateMessageToSend(SendOptions);
	EndIf;
	
EndProcedure

&AtClient
Procedure SendMessage1(Val MessageSendOptions)
	
	If MessageKind = "MailMessage" Then
		If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
			CallbackDescription = New CallbackDescription("SendMessageAccountCheckCompleted", ThisObject, MessageSendOptions);
			ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
			ModuleEmailOperationsClient.CheckAccountForSendingEmailExists(CallbackDescription);
		EndIf;
	ElsIf MessageKind = "SMSMessage" Then
		GenerateMessageToSend(MessageSendOptions);
	EndIf;
	
EndProcedure

&AtClient
Procedure SendMessageAccountCheckCompleted(AccountSetUp, SendOptions) Export
	
	If AccountSetUp = True Then
		GenerateMessageToSend(SendOptions);
	EndIf;
	
EndProcedure


// Parameters:
//  Result - See MessageTemplatesInternal.EmailSendingResult
//  SendOptions - Structure
//
&AtClient
Procedure AfterGenerateAndSendMessage(Result, SendOptions)
	
	If IsBlankString(Result.ErrorDescription)Then;
		Close();
	Else
		Notification = New CallbackDescription("AfterQuestionOnOpenMessageForm", ThisObject, SendOptions);
		ErrorDescription = Result.ErrorDescription + Chars.LF + NStr("vi = 'Mở biểu mẫu gửi tin nhắn?';
																	|ru = 'Открыть форму отправки сообщения?';
																	|en = 'Do you want to open the message?'; fa = 'Do you want to open the message?';
																	|it = 'Aprire il modulo per inviare un messaggio?';
																	|pl = 'Otworzyć formularz wysyłania wiadomości?';
																	|tr = 'İletiyi açmak istiyor musunuz?'");
		ShowQueryBox(Notification, ErrorDescription, QuestionDialogMode.YesNo);
	EndIf;

EndProcedure

&AtClient
Procedure ShowMessageForm(Message)
	
	If MessageKind = "SMSMessage" Then
		If CommonClient.SubsystemExists("StandardSubsystems.SendSMSMessage") Then 
			ModuleSMSClient= CommonClient.CommonModule("SendSMSMessageClient");
			
			AdditionalParameters = New Structure("Transliterate");
			If Message.AdditionalParameters <> Undefined Then
				FillPropertyValues(AdditionalParameters, Message.AdditionalParameters);
			EndIf;
			
			AdditionalParameters.Transliterate = ?(Message.AdditionalParameters.Property("Transliterate"),
				Message.AdditionalParameters.Transliterate, False);
			AdditionalParameters.Insert("SubjectOf", SubjectOf);
			Text      = ?(Message.Property("Text"), Message.Text, "");
			
			Recipient = New Array;
			IsValueList = (TypeOf(Message.Recipient) = Type("ValueList"));
			
			For Each InformationOnRecipient In Message.Recipient Do
				If IsValueList Then
					Phone                      = InformationOnRecipient.Value;
					ContactInformationSource = "";
				Else 
					Phone                      = InformationOnRecipient.PhoneNumber;
					ContactInformationSource = InformationOnRecipient.ContactInformationSource ;
				EndIf;
				
				RecipientData = New Structure();
				RecipientData.Insert("Presentation",                InformationOnRecipient.Presentation);
				RecipientData.Insert("Phone",                      Phone);
				RecipientData.Insert("ContactInformationSource", ContactInformationSource);
				Recipient.Add(RecipientData);
				
			EndDo;
			
			ModuleSMSClient.SendSMS(Recipient, Text, AdditionalParameters);
		EndIf;
	ElsIf MessageKind = "MailMessage" Then
		If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
			ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
			ModuleEmailOperationsClient.CreateNewEmailMessage(Message);
		EndIf;
	EndIf;
	
	If Message.Property("UserMessages")
		And Message.UserMessages <> Undefined
		And Message.UserMessages.Count() > 0 Then
			For Each UserMessages In Message.UserMessages Do
				CommonClient.MessageToUser(UserMessages.Text,
					UserMessages.DataKey, UserMessages.Field, UserMessages.DataPath);
			EndDo;
	EndIf;
	
EndProcedure

&AtClient
Function SendOptionsConstructor(Template = Undefined)
	
	SendOptions = MessageTemplatesClientServer.SendOptionsConstructor(Template, SubjectOf, UUID);
	SendOptions.AdditionalParameters.MessageKind       = MessageKind;
	SendOptions.AdditionalParameters.MessageParameters = MessageParameters;
	
	If Not ValueIsFilled(Template) Then
		
		SupplementSendOptionsWithPrintForms(SendOptions);
		SupplementSendOptionsWithExportTemplates(SendOptions);
		SendOptions.AdditionalParameters.SettingsForSaving = SelectedFormatSettings();
		
	EndIf;
	
	Return SendOptions;
	
EndFunction

&AtClient
Procedure SupplementSendOptionsWithPrintForms(SendOptions)
	
	TreeRow = BranchByAttachmentKind(Attachments, AttachmentsKinds[0]);
	If TreeRow = Undefined Then
		Return;
	EndIf;
	
	For Each PrintForm In TreeRow.GetItems() Do
		
		If PrintForm.SelectedItemsCount = 1 Then
			SendOptions.AdditionalParameters.PrintForms.Add(PrintForm.AttachmentCommand);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SupplementSendOptionsWithExportTemplates(SendOptions)
	
	TreeRow = BranchByAttachmentKind(Attachments, AttachmentsKinds[1]);
	If TreeRow = Undefined Then
		Return;
	EndIf;
	 
	For Each ExportedTemplate In TreeRow.GetItems() Do
			
		If ExportedTemplate.SelectedItemsCount = 1 Then
			SendOptions.AdditionalParameters.ExportTemplates.Add(ExportedTemplate.AttachmentCommand);
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  Result - DialogReturnCode
//  SendOptions -See MessageTemplatesClientServer.SendOptionsConstructor
// 
&AtClient
Procedure AfterQuestionOnOpenMessageForm(Result, SendOptions) Export
	
	If Result = DialogReturnCode.Yes Then
		GenerateAndSend = False;
		SendOptions.AdditionalParameters.ConvertHTMLForFormattedDocument = True;
		GenerateMessageToSend(SendOptions);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateNewTemplate(CopyingValue = Undefined)
	
	FormParameters = New Structure();
	FormParameters.Insert("MessageKind"          , MessageKind);
	FormParameters.Insert("FullBasisTypeName",
		?(ValueIsFilled(FullBasisTypeName), FullBasisTypeName, SubjectOf));
	FormParameters.Insert("AuthorOnly",        True);
	FormParameters.Insert("TemplateOwner",        TemplateOwner);
	FormParameters.Insert("CopyingValue",    CopyingValue);
	FormParameters.Insert("New",                  True);
	
	OpenForm("Catalog.MessageTemplates.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

&AtServer
Procedure FillAvailableTemplatesList()
	
	Templates.Clear();
	
	TemplateType = "Arbitrary";
	If ForSMSMessages Then
		TemplateType = "SMS";
	ElsIf ForEmails Then
		TemplateType = "MailMessage";
	EndIf;
	
	Query = MessageTemplatesInternal.PrepareQueryToGetTemplatesList(TemplateType, SubjectOf, TemplateOwner);
	
	QueryResult = Query.Execute().Select();
		
	While QueryResult.Next() Do
		NewRow = Templates.Add();
		FillPropertyValues(NewRow, QueryResult);
		
		If QueryResult.TemplateByExternalDataProcessor
			And Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
				ModuleAdditionalReportsAndDataProcessors = Common.CommonModule("AdditionalReportsAndDataProcessors");
				ExternalObject = ModuleAdditionalReportsAndDataProcessors.ExternalDataProcessorObject(QueryResult.ExternalDataProcessor);
				TemplateParameters = ExternalObject.TemplateParameters();
				
				If TemplateParameters.Count() > 1 Then
					HasArbitraryParameters = True;
				Else
					HasArbitraryParameters = False;
				EndIf;
		Else
			ArbitraryParameters = QueryResult.HasArbitraryParameters.Unload();
			HasArbitraryParameters = ArbitraryParameters.Count() > 0;
		EndIf;
		
		NewRow.HasArbitraryParameters = HasArbitraryParameters;
	EndDo;
	
	If Templates.Count() = 0 Then
		MessageTemplatesSettings = MessageTemplatesInternalCached.OnDefineSettings();
		ShowTemplatesChoiceForm = MessageTemplatesSettings.AlwaysShowTemplatesChoiceForm;
	Else
		ShowTemplatesChoiceForm = True;
	EndIf;
	
	Templates.Sort("Presentation");
	
	If Not ChoiceMode And Not PrepareTemplate Then
		FirstRow = Templates.Insert(0);
		FirstRow.Name = "<NoTemplate>";
		FirstRow.Presentation = NStr("vi = '<Không có mẫu>';
									|ru = '<Без шаблона>';
									|en = '<No template>'; fa = '<No template>';
									|it = '<Senza un modello>';
									|pl = '<Bez szablonu>';
									|tr = '<Şablonsuz>'");
	EndIf;
	
	If Templates.Count() = 0 Then
		Items.FormCreate.LocationInCommandBar = ButtonLocationInCommandBar.InCommandBar;
		Items.FormCreate.Representation = ButtonRepresentation.PictureAndText;
		Items.FormGenerate.Enabled           = False;
		Items.FormGenerateAndSend.Enabled = False;
	Else
		Items.FormGenerate.Enabled           = True;
		Items.FormGenerateAndSend.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdatePreviewData()
	CurrentData = Items.Templates.CurrentData;
	If CurrentData <> Undefined Then
		SetHTMLInFormattedDocument(CurrentData.TemplateText, CurrentData.Ref);
	EndIf;
EndProcedure

&AtServer
Procedure SetHTMLInFormattedDocument(HTMLEmailTemplateText, CurrentObjectRef);
	
	Message = MessageTemplatesInternal.MessageConstructor();
	
	TemplateParameter = New Structure("Template, UUID");
	TemplateParameter.Template = CurrentObjectRef;
	TemplateParameter.UUID = UUID;
	Message.Text = HTMLEmailTemplateText;
	MessageTemplatesInternal.ProcessHTMLForFormattedDocument(TemplateParameter, Message, True);
	AttachmentsStructure = New Structure();
	For Each HTMLAttachment In Message.Attachments Do
		Image = New Picture(GetFromTempStorage(HTMLAttachment.AddressInTempStorage));
		AttachmentsStructure.Insert(HTMLAttachment.Presentation, Image);
	EndDo;
	
	TemplateParameters = MessageTemplatesInternal.TemplateParameters(CurrentObjectRef);
	TemplateInfo = MessageTemplatesInternal.TemplateInfo(TemplateParameters);
	
	Message.Text = MessageTemplatesInternal.ConvertTemplateText(Message.Text , TemplateInfo.Attributes, "ParametersInPresentation");
	Message.Text = MessageTemplatesInternal.ConvertTemplateText(Message.Text , TemplateInfo.CommonAttributes, "ParametersInPresentation");
	PreviewFormattedDocument.SetHTML(Message.Text, AttachmentsStructure);
	
EndProcedure

&AtClient
Procedure SetFormatSelection(Val SaveFormats = Undefined)
	
	HasSelectedFormat = False;
	For Each SelectedFormat In SelectedSaveFormats Do
		If SaveFormats <> Undefined Then
			SelectedFormat.Check = SaveFormats.Find(SelectedFormat.Value) <> Undefined;
		EndIf;
			
		If SelectedFormat.Check Then
			HasSelectedFormat = True;
		EndIf;
	EndDo;
	
	If Not HasSelectedFormat Then
		SelectedSaveFormats[0].Check = True; // The default choice is the first in the list.
	EndIf;
	
EndProcedure

&AtClient
Procedure GeneratePresentationForSelectedFormats()
	
	AttachmentFormat = "";
	FormatsCount = 0;
	For Each SelectedFormat In SelectedSaveFormats Do
		If SelectedFormat.Check Then
			If Not IsBlankString(AttachmentFormat) Then
				AttachmentFormat = AttachmentFormat + ", ";
			EndIf;
			AttachmentFormat = AttachmentFormat + SelectedFormat.Presentation;
			FormatsCount = FormatsCount + 1;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Function SelectedFormatSettings()
	
	Result = CommonInternalClient.PrintFormFormatSettings();
	
	For Each SelectedFormat In SelectedSaveFormats Do
		If SelectedFormat.Check Then
			Result.SaveFormats.Add(SelectedFormat.Value);
		EndIf;
	EndDo;

	Result.PackToArchive = PackToArchive;
	Result.TransliterateFilesNames = TransliterateFilesNames;
	Result.SignatureAndSeal = SignatureAndSeal;
	
	Return Result;
	
EndFunction

&AtClient
Procedure OnSelectAttachmentFormat(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected <> DialogReturnCode.Cancel And ValueSelected <> Undefined Then
		SetFormatSelection(ValueSelected.SaveFormats);
		PackToArchive = ValueSelected.PackToArchive;
		TransliterateFilesNames = ValueSelected.TransliterateFilesNames;
		Sign = ValueSelected.Sign;
		GeneratePresentationForSelectedFormats();
	EndIf;
		
EndProcedure

&AtServer
Procedure FillPrintFormsAndExportTemplatesList()
	
	If MessageKind = "Arbitrary" Or MessageKind = "SMSMessage" Or ChoiceMode Or PrepareTemplate
		Or TypeOf(SubjectOf) = Type("String") Or Not ValueIsFilled(SubjectOf) Then
		
		Items.SelectPrintFormsExportFiles.Visible = False;
		Return;
		
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		
		ModulePrintManager = Common.CommonModule("PrintManagement");
		
		PrintCommands = Undefined;
		ExportCommands = Undefined;
		
		If ValueIsFilled(MessageSourceFormName) Then
			
			PrintCommands = Common.ValueTableToArray(ModulePrintManager.FormPrintCommands(
				MessageSourceFormName, CommonClientServer.ValueInArray(SubjectOf.Metadata())));
			
			ListOfObjects = CommonClientServer.ValueInArray(SubjectOf.Metadata());
			
			If Common.SubsystemExists("StandardSubsystems.ExportObjectsToFiles") Then
				
				ModuleExportObjectsToFiles = Common.CommonModule("ExportObjectsToFiles");
				FormExportCommands = ModuleExportObjectsToFiles.FormExportCommands(
					MessageSourceFormName, 
					ListOfObjects);
				ExportCommands = Common.ValueTableToArray(FormExportCommands);
				
			EndIf;
			
		EndIf;
		
		AttachmentTree = FormAttributeToValue("Attachments");
		
		FillPrintFormsList(AttachmentTree, PrintCommands);
		
		If ExportCommands <> Undefined Then
			FillExportTemplateList(AttachmentTree, ExportCommands);
		EndIf;
		
		ValueToFormAttribute(AttachmentTree, "Attachments");
		
		Items.SelectPrintFormsExportFiles.Visible = (ValueIsFilled(PrintCommands) Or ValueIsFilled(ExportCommands));
		
	EndIf;
	
EndProcedure

&AtServer 
Procedure FillPrintFormsList(AttachmentTree, PrintCommands)
	
	If Not ValueIsFilled(PrintCommands) Then
		Return;
	EndIf;
	
	AttachmentKindIndexes = IndexAttachmentKindMap(AttachmentsKinds);
	AttachmentKindIndex = AttachmentKindIndexes[AttachmentsKinds[0]];
	
	TreeRow = AttachmentTree.Rows.Add();
	TreeRow.Presentation = AttachmentsKinds[0].Presentation;
	TreeRow.AttachmentKindPicture = PictureLib.Print;
	
	ObjectKey = "SendPrintFormsAndExportFilesWithoutTemplate";
	SelectedPrintedForms = PreviouslySelectedObjects(ObjectKey);
	AreAllSelected = False;
	
	For Each PrintCommand In PrintCommands Do
		
		SelectedItemsCount = 0;
		Check = (SelectedPrintedForms.Find(PrintCommand.UUID) <> Undefined);
		
		If Check Then
			SelectedItemsCount = 1;
		EndIf;
		
		NewRow = TreeRow.Rows.Add();
		NewRow.Presentation = PrintCommand.Presentation;
		NewRow.AttachmentCommand = PrintCommand;
		NewRow.PictureIndex = IndexOfFileIcon("mxl");
		TreeRow.AttachmentKindIndex = AttachmentKindIndex;
		NewRow.SelectedItemsCount = SelectedItemsCount;
		
		AreAllSelected = Min(AreAllSelected, SelectedItemsCount);
		If SelectedItemsCount <> 0 Then
			TreeRow.SelectedItemsCount = 2;
		EndIf;
		
	EndDo;
	
	If AreAllSelected Then
		TreeRow.SelectedItemsCount = 1;
	EndIf;
	
EndProcedure

&AtServer 
Procedure FillExportTemplateList(AttachmentTree, ExportCommands)
	
	If ExportCommands.Count() = 0 Then
		
		Return;
		
	EndIf;
	
	AttachmentKindIndexes = IndexAttachmentKindMap(AttachmentsKinds);
	AttachmentKindIndex = AttachmentKindIndexes[AttachmentsKinds[1]];
	
	TreeRow = AttachmentTree.Rows.Add();
	TreeRow.Presentation = AttachmentsKinds[1].Presentation;
	TreeRow.AttachmentKindPicture = PictureLib.SaveFileAs;
	
	ObjectKey = "SendPrintFormsAndExportFilesWithoutTemplate";
	SelectedExportTemplates = PreviouslySelectedObjects(ObjectKey);
	AreAllSelected = False;
	ExportFormatExtensionMap = Undefined;
	
	If Common.SubsystemExists("StandardSubsystems.ExportObjectsToFiles") Then
		
		ModuleExportObjectsToFiles = Common.CommonModule("ExportObjectsToFiles");
		ExportFormatExtensionMap = ModuleExportObjectsToFiles.ExportFormatSaveFormatMap();
		
	EndIf;
	
	For Each ExportCommand In ExportCommands Do
		
		SelectedItemsCount = 0;
		
		Check = (SelectedExportTemplates.Find(ExportCommand.UUID) <> Undefined);
		
		If Check Then
			SelectedItemsCount = 1;
		EndIf;
		
		NewRow = TreeRow.Rows.Add();
		NewRow.Presentation = ExportCommand.Presentation;
		NewRow.AttachmentCommand = ExportCommand;
		Extension = ?(IsBlankString(ExportCommand.SaveFormat), "mxl", ExportCommand.SaveFormat);
		If ExportFormatExtensionMap <> Undefined Then
			Extension = ExportFormatExtensionMap[Extension];
		EndIf;
		
		NewRow.PictureIndex = IndexOfFileIcon(Extension);
		TreeRow.AttachmentKindIndex = AttachmentKindIndex;
		NewRow.SelectedItemsCount = SelectedItemsCount;
		
		AreAllSelected = Min(AreAllSelected, SelectedItemsCount);
		If SelectedItemsCount <> 0 Then
			TreeRow.SelectedItemsCount = 2;
		EndIf;
		
	EndDo;
	
	If AreAllSelected Then
		TreeRow.SelectedItemsCount = 1;
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveSelectedPrintFormsAndExportFiles()
	
	If Not ValueIsFilled(MessageSourceFormName) Then
		Return;
	EndIf;
	
	IDs = New Array;
	
	TreeRow = BranchByAttachmentKind(Attachments, AttachmentsKinds[0]);
	If TreeRow <> Undefined Then
		
		For Each PrintForm In TreeRow.GetItems() Do
			
			If PrintForm.SelectedItemsCount = 1 Then
				IDs.Add(PrintForm.AttachmentCommand.UUID);
			EndIf;
			
		EndDo;
		
	EndIf;
		
	TreeRow = BranchByAttachmentKind(Attachments, AttachmentsKinds[1]);
	If TreeRow <> Undefined Then
		
		For Each ExportedTemplate In TreeRow.GetItems() Do
			
			If ExportedTemplate.SelectedItemsCount = 1 Then
				IDs.Add(ExportedTemplate.AttachmentCommand.UUID);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	SaveSelectedPrintFormsAndExportFilesAtServer(IDs);
	
EndProcedure

&AtServer
Procedure SaveSelectedPrintFormsAndExportFilesAtServer(Val IDs)
	
	If IDs.Count() = 0 Then
		Return;
	EndIf;
	
	Common.CommonSettingsStorageSave(
		"SendPrintFormsAndExportFilesWithoutTemplate", MessageSourceFormName, IDs);
	
EndProcedure

&AtServer
Function PreviouslySelectedObjects(ObjectKey)
	
	Result = New Array;
	
	If ValueIsFilled("MessageSourceFormName") Then
		
		Result = Common.CommonSettingsStorageLoad(
			ObjectKey, MessageSourceFormName, New Array);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure SIgnFiles(Result, SendOptions)
	FilesToSign = Result.Attachments;
	
	Context = New Structure;
	Context.Insert("Result", Result);
	Context.Insert("SendOptions", SendOptions);
	
	CallbackDescription = New CallbackDescription("GenerateMessageToSendContinued", ThisObject, Context);
	
	If CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		DataDetails = New Structure;
		DataDetails.Insert("ShowComment", False);
		If FilesToSign.Count() > 1 Then
			DataDetails.Insert("Operation",            NStr("vi = 'Ký tệp';
															|ru = 'Подписание файлов';
															|en = 'Sign files'; fa = 'Sign files';
															|it = 'Подписание файлов';
															|pl = 'Sign files';
															|tr = 'Dosyanın imzalanması'"));
			DataDetails.Insert("DataTitle",     NStr("vi = 'Tệp';
													|ru = 'Файлы';
													|en = 'Files'; fa = 'فایل‌ها';
													|it = 'Файлы';
													|pl = 'Files';
													|tr = 'Dosyalar'"));
			
			DataSet = New Array;
			For Each File In FilesToSign Do
				DescriptionOfFileData = New Structure;
				DescriptionOfFileData.Insert("Presentation", File.Presentation);
				DescriptionOfFileData.Insert("Data", File.AddressInTempStorage);
				DescriptionOfFileData.Insert("PrintObject", SubjectOf);
				DataSet.Add(DescriptionOfFileData);
			EndDo;
			
			DataDetails.Insert("DataSet", DataSet);
			DataDetails.Insert("SetPresentation", "Files (%1)");
		Else
			File = FilesToSign[0];
			DataDetails.Insert("Operation",        NStr("vi = 'Ký tên tệp';
														|ru = 'Подписание файла';
														|en = 'Sign a file'; fa = 'Sign a file';
														|it = 'Firma del file';
														|pl = 'Podpisanie pliku';
														|tr = 'Dosya imzalama'"));
			DataDetails.Insert("DataTitle", NStr("vi = 'Tệp';
												|ru = 'Файл';
												|en = 'File'; fa = 'فایل';
												|it = 'Файл';
												|pl = 'File';
												|tr = 'Dosya'"));
			DataDetails.Insert("Presentation", File.Presentation);
			DataDetails.Insert("Data", File.AddressInTempStorage);
			DataDetails.Insert("PrintObject", SubjectOf);
		EndIf;
		
		ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
		SignatureParameters = ModuleDigitalSignatureClient.NewSignatureType();
		SignatureParameters.CanSelectLetterOfAuthority = True;
		ModuleDigitalSignatureClient.Sign(DataDetails,,CallbackDescription, SignatureParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateMessageToSendContinued(SigningResult, Context) Export
	
	If TypeOf(SigningResult) = Type("Structure") And SigningResult.Property("Success") And Not SigningResult.Success Then
		Return;
	EndIf;
	
	AttachmentsForSending = GetSignatureFilesAndPutToArchive(
		SigningResult,
		TransliterateFilesNames,
		Context.SendOptions.AdditionalParameters.SettingsForSaving);

	Result = Context.Result;
	Result.Attachments.Clear();
	
	CommonClientServer.SupplementArray(Result.Attachments, AttachmentsForSending);
	
	GenerateMessageToSendEnding(Result, Context.SendOptions);
	
EndProcedure

&AtServer
Function GetSignatureFilesAndPutToArchive(SigningResult, TransliterateFilesNames, SettingsForSaving)
		
	ModuleDigitalSignatureInternal = Common.CommonModule("DigitalSignatureInternal");
	
	FilesReceiptParameters = ModuleDigitalSignatureInternal.FilesReceiptParameters();
	FilesReceiptParameters.TransliterateFilesNames = TransliterateFilesNames;
	Files = ModuleDigitalSignatureInternal.GetFilesFromSigningResult(
		SigningResult, FilesReceiptParameters, UUID);
	
	FilesInTempStorage = New Array;
	For Each File In Files Do
		StructureOfFileDetails = New Structure("AddressInTempStorage, Presentation, Id, Encoding");
		StructureOfFileDetails.AddressInTempStorage = File.Data;
		StructureOfFileDetails.Presentation = File.FileName;
		FilesInTempStorage.Add(StructureOfFileDetails);
	EndDo;
	
	FilesInTempStorage = PutFilesToArchive(FilesInTempStorage, SettingsForSaving);
	
	Return FilesInTempStorage;
	
EndFunction

&AtServer
Function PutFilesToArchive(DocsPrintForms, PassedSettings)
	
	Result = New Array;
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		SettingsForSaving = ModulePrintManager.SettingsForSaving();
		FillPropertyValues(SettingsForSaving, PassedSettings);
		
		If Not SettingsForSaving.PackToArchive Then
			Return DocsPrintForms;
		EndIf;
		SavingOption = Undefined; 
		PassedSettings.Property("SavingOption", SavingOption);
		SetPrintObject = SavingOption = "Join";	
		
		TransliterateFilesNames = SettingsForSaving.TransliterateFilesNames;
		
		TempDirectoryName = CommonClientServer.AddLastPathSeparator(GetTempFileName());
		CreateDirectory(TempDirectoryName);
		
		ArchiveName = GetTempFileName("zip");
		ZipFileWriter = New ZipFileWriter(ArchiveName);
	
		For Each FileStructure In DocsPrintForms Do
				
			FileData = GetFromTempStorage(FileStructure.AddressInTempStorage);
			FullFileName = TempDirectoryName + FileStructure.Presentation;
			FullFileName = FileSystem.UniqueFileName(FullFileName);
			FileData.Write(FullFileName);
			ZipFileWriter.Add(FullFileName);
	
		EndDo;
			
		ZipFileWriter.Write();
		BinaryData = New BinaryData(ArchiveName);
		PathInTempStorage = PutToTempStorage(BinaryData, UUID);
		FileDetails = New Structure;
		File = New File(ArchiveName);
		FileDetails.Insert("Presentation", File.Name);
		FileDetails.Insert("AddressInTempStorage", PathInTempStorage);
		Result.Add(FileDetails);
		DeleteFiles(ArchiveName);
			
		DeleteFiles(TempDirectoryName);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function IndexOfFileIcon(Extension)
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternalClientServer = Common.CommonModule("FilesOperationsInternalClientServer");
		Return ModuleFilesOperationsInternalClientServer.IndexOfFileIcon(Extension);
	EndIf;
	
	Return 0;
	
EndFunction

&AtClientAtServerNoContext
Function IndexAttachmentKindMap(AttachmentsKinds)
	
	AttachmentKindIndexes = New Map;
	
	For Cnt = 0 To AttachmentsKinds.Count() - 1 Do
		
		AttachmentKindIndexes.Insert(AttachmentsKinds[Cnt], Cnt);
	
	EndDo;
	
	Return AttachmentKindIndexes;
	
EndFunction

&AtClient
Function BranchByAttachmentKind(AttachmentTree, AttachmentsKind)
	
	AttachmentKindIndexes = IndexAttachmentKindMap(AttachmentsKinds);
	AttachmentKindIndex = AttachmentKindIndexes[AttachmentsKind];
	TreeRow = Undefined;
	
	TreeRows = AttachmentTree.GetItems();
	For Each CurrentTreeRow In TreeRows Do
		
		If CurrentTreeRow.AttachmentKindIndex = AttachmentKindIndex Then
			
			TreeRow = CurrentTreeRow;
			Break;
			
		EndIf;
		
	EndDo;
	
	Return TreeRow;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttachmentsPictureIndex.Name);
	
	FilterGroupsOR = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroupsOR.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	For Each AttachmentsKind In AttachmentsKinds Do
		
		ItemFilter = FilterGroupsOR.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Attachments.Presentation");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Contains;
		ItemFilter.RightValue = AttachmentsKind.Presentation;
		
	EndDo;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AttachmentsAttachmentKindPicture.Name);
	
	FilterElement = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = New DataCompositionField("Attachments.AttachmentKindPicture");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtClient
Procedure SetSubordinateMarks(CurRow, CheckBoxName)
	
	SubordinateItems = CurRow.GetItems();
	
	If SubordinateItems.Count() = 0 Then
		Return;
	EndIf;
	
	For Each String In SubordinateItems Do
		
		String[CheckBoxName] = CurRow[CheckBoxName];
		
		SetSubordinateMarks(String, CheckBoxName);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SetParentMarks(CurRow, CheckBoxName)
	
	Parent = CurRow.GetParent();
	If Parent = Undefined Then
		Return;
	EndIf;
	
	CurState = Parent[CheckBoxName];
	
	EnabledItemsFound  = False;
	DisabledItemsFound = False;
	
	AllDisabled = 0;
	AllEnabled = 1;
	NotAllEnabled = 2;
	
	For Each String In Parent.GetItems() Do
		
		If String[CheckBoxName] = AllDisabled Then
			DisabledItemsFound = True;
		ElsIf String[CheckBoxName] = AllEnabled
			Or String[CheckBoxName] = NotAllEnabled Then
			EnabledItemsFound = True;
		EndIf; 
		
		If EnabledItemsFound And DisabledItemsFound Then
			Break;
		EndIf;
		
	EndDo;
	
	If (EnabledItemsFound And DisabledItemsFound)
	 Or (Not EnabledItemsFound And Not DisabledItemsFound) Then
		Enable = NotAllEnabled;
	ElsIf EnabledItemsFound And Not DisabledItemsFound Then
		Enable = AllEnabled;
	Else
		Enable = AllDisabled;
	EndIf;
	
	If Enable = CurState Then
		Return;
	Else
		Parent[CheckBoxName] = Enable;
		SetParentMarks(Parent, CheckBoxName);
	EndIf;
	
EndProcedure

#EndRegion