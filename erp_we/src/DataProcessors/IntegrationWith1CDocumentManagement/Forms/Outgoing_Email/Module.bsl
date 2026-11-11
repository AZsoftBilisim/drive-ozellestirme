#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	// Mail
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.8.1.CORP") Then
		Raise(NStr("vi = 'Tính năng này không được hỗ trợ trong phiên bản 1C:Document Management hiện tại.';
					|ru = 'Функционал не поддерживается в данной версии 1С:Документооборота.';
					|en = 'Functionality is not supported in this version of 1C:Document Management.'; fa = 'این قابلیت در این نسخه از 1C:Document Management پشتیبانی نمی‌شود.';
					|it = 'La funzione non è supportata in questa versione di 1C:Document Management.';
					|pl = 'Funkcja nie jest obsługiwana w tej wersji 1C:Document Management.';
					|tr = 'Fonksiyonellik, 1C:Document Management''ın bu sürümünde desteklenmemektedir.'"));
	EndIf;
	
	If Parameters.Property("SubjectOf") And ValueIsFilled(Parameters.SubjectOf) Then
		FillInNewEmailCard(Proxy, Parameters);
		
	ElsIf ValueIsFilled(Parameters.ID) And ValueIsFilled(Parameters.type) Then
		// The card of the existing letter opens
		XDTOLetter = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			Parameters.type,
			Parameters.ID);
		FillOutFormFromXDTOObject(XDTOLetter);
		
	Else
		XDTOLetter = IntegrationWith1CDocumentManagementCore.NewOutgoingEmail(Proxy);
		FillOutFormFromXDTOObject(XDTOLetter);
		
	EndIf;
	
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.8.1") Then
		Items.FormForwardMail.Enabled = False;
	EndIf;
	
	If ValueIsFilled(ID) And Sent Then
		ReadOnly = True;
		Items.FormClose.Visible = True;
		Items.PlainText.Visible = False;
		Items.FormClose.DefaultButton = True;
		Items.FormSend.Visible = False;
		
		Items.ApplicationTree.ReadOnly = True;
		Items.Recipients.ReadOnly = True;
		Items.Importance.ReadOnly = True;
		Items.Add.Enabled = False;
		Items.Delete.Enabled = False;
		Items.Subject.ReadOnly = True;
		Items.FormAddAddressees.Visible = False;
	Else
		Items.HTMLPresentation.Visible = False;
		Items.FormClose.Visible = False;
		Items.FormForwardMail.Visible = False;
		Items.CreateBasedOn.Visible = False;
	EndIf;
	
	DisplayNumberOfServerFiles();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(ID) And Recipients.Count() = 0 Then
		AttachIdleHandler("SetCurRecipientElement", 0.2, True);
	ElsIf Not ValueIsFilled(Subject) Then
		AttachIdleHandler("SetCurThemeItem", 0.2, True);
	Else
		AttachIdleHandler("SetCurTextElement", 0.2, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure EmailBasisClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(EmailBasisID) Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			EmailBasisType,
			EmailBasisID,
			Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure SubjectOfClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(SubjectOfID) Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(SubjectOfType, SubjectOfID, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportanceStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheDropDownList(
		"DMEMailImportance",
		"Importance",
		ThisObject);
	
EndProcedure

&AtClient
Procedure ImportanceAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEMailImportance",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportanceTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEMailImportance",
			ChoiceData,
			Text,
			StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Importance",
				ChoiceData[0].Value,
				StandardProcessing,
				ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportanceChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Importance",
		ValueSelected,
		StandardProcessing,
		ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersApplicationTree

&AtClient
Procedure ApplicationTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenApplicationTreeElement(Item.CurrentData);
	
EndProcedure

&AtClient
Procedure ApplicationTreeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	StartAddingFileFromDisk();
	
EndProcedure

&AtClient
Procedure ApplicationTreeDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If TypeOf(DragParameters.Value) = Type("File") Then
		FullFileNames = New Array;
		FullFileNames.Add(DragParameters.Value.FullName);
		StartAddingFileFromDiskByNameArray(FullFileNames);
	ElsIf TypeOf(DragParameters.Value) = Type("Array") Then
		FullFileNames = New Array;
		For Each ArrayElement In DragParameters.Value Do
			If TypeOf(ArrayElement) = Type("File") Then
				FullFileNames.Add(ArrayElement.FullName);
			EndIf;
		EndDo;
		If FullFileNames.Count() > 0 Then
			StartAddingFileFromDiskByNameArray(FullFileNames);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationTreeDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	DraggableValue = DragParameters.Value;
	If TypeOf(DraggableValue) <> Type("Array")
		And TypeOf(DraggableValue) <> Type("File") Then
		
		StandardProcessing = True;
		Return;
		
	EndIf;
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRecipients

&AtClient
Procedure RecipientsOnStartEdit(Item, NewRow, Copy)
	
	Item.CurrentItem = Items.RecipientsAddressee;
	
	DataString1 = Recipients.FindByID(Items.Recipients.CurrentRow);
	NumberOfRecipientsBeforeAdding = Recipients.Count();
	If Not ValueIsFilled(DataString1.AddressType) Then
		If NumberOfRecipientsBeforeAdding = 1 Then
			DataString1.AddressType = NStr("vi = 'Người nhận:';
											|ru = 'Кому:';
											|en = 'To:'; fa = 'به:';
											|it = 'A chi:';
											|pl = 'Do:';
											|tr = 'Kime:'");
		Else
			DataString1.AddressType = NStr("vi = 'Cc:';
											|ru = 'Копия:';
											|en = 'Cc:'; fa = 'رونوشت:';
											|it = 'Copia:';
											|pl = 'Kopia:';
											|tr = 'Cc:'");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AddresseesAddresseeAddressStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("AddresseesAddresseeAddressStartOfSelectionCompletion", ThisObject);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.AddressBook",,Item,,,, Notification);
	
EndProcedure

&AtClient
Procedure SMSMessageRecipientsAddresseeTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		DataForAutomaticDestinationSelection(ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Addressee",
				ChoiceData[0].Value,
				StandardProcessing,
				ThisObject,
				True,
				Item);
			Item.Parent.CurrentData.NotFound = False;
			StandardProcessing = True;
		ElsIf ChoiceData.Count() = 0 Then
			StandardProcessing = True;
			Item.Parent.CurrentData.NotFound = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SMSMessageRecipientsAddresseeAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		DataForAutomaticDestinationSelection(ChoiceData, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure SMSMessageRecipientsAddresseeChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Addressee",
		ValueSelected,
		StandardProcessing,
		ThisObject,
		True,
		Item);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ForwardMail(Command)
	
	FormParameters = New Structure("SubjectOf", New Structure);
	
	FormParameters.SubjectOf.Insert("name", Subject);
	FormParameters.SubjectOf.Insert("ID", ID);
	FormParameters.SubjectOf.Insert("type", Type);
	FormParameters.Insert("answerType", "transfer");
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Outgoing_Email", FormParameters);
	AttachIdleHandler("CloseFormForForwarding", 0.2, True);
	
EndProcedure

&AtClient
Procedure CreateProcess(Command)
	
	FormParameters = New Structure("SubjectOf", New Structure);
	
	FormParameters.SubjectOf.Insert("ID", ID);
	FormParameters.SubjectOf.Insert("type", Type);
	FormParameters.SubjectOf.Insert("name", Presentation);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.CreatingBusinessProcess", FormParameters);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	Close();
EndProcedure

&AtClient
Procedure Send(Command)
	
	ReadyToSend = CheckEmailBeforeSending();
	
	If Not ReadyToSend Then
		Return;
	EndIf;
	
	// Preparing files for transfer
	FilesArray = New Array;
	
	For Each String In ApplicationTree Do
		If ValueIsFilled(String.TempFileStorageAddress) Then
			FilesArray.Add(PrepareFileFromDisk(String));
		Else
			FilesArray.Add(PrepareAFileInThe1CDocumentManagement(String));
		EndIf;
	EndDo;
	
	SendOnServer(FilesArray);
	IntegrationWith1CDocumentManagementClient.Notify_OutgoingEmailRecord(ThisObject);
	AttachIdleHandler("CloseFormForForwarding",0.2, True);
	
	Status(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã gửi E-mail ""%1"".';
			|ru = 'Письмо ""%1"" отправлено.';
			|en = 'Mail ""%1"" sent.'; fa = 'Mail ""%1"" sent.';
			|it = 'Posta ""%1"" inviata.';
			|pl = 'Wiadomość ""%1"" została wysłana.';
			|tr = '""%1"" mektup gönderildi.'"), Subject));
	
EndProcedure

&AtClient
Procedure AddAddressee(Command)
	
	Items.Recipients.AddRow();
	DataString1 = Recipients.FindByID(Items.Recipients.CurrentRow);
	
	Notification = New CallbackDescription("AddAddresseeCompletion", ThisObject, DataString1);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.AddressBook",,DataString1,,,,
		Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AppendFile(Command)
	StartAddingFileFromDisk();
EndProcedure

&AtClient
Procedure DeleteFile(Command)
	CurrentRow = Items.ApplicationTree.CurrentData;
	If CurrentRow <> Undefined Then
		ApplicationTree.Delete(CurrentRow);
	EndIf;
EndProcedure

&AtClient
Procedure OpenFile(Command)
	
	OpenApplicationTreeElement(Items.ApplicationTree.CurrentData);
	
EndProcedure

&AtClient
Procedure BasisOnChange(Item)
	If ValueIsFilled(Basis) Then
		Basis.Open();
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AddresseesAddresseeAddressStartOfSelectionCompletion(SelectionResult, NotificationParameters) Export
	
	ProcessDestinationSelection(SelectionResult);
	
EndProcedure

&AtClient
Procedure AddAddresseeCompletion(SelectionResult, DataString1) Export
	
	If TypeOf(SelectionResult) = Type("Array") Then
		If SelectionResult.Count() = 1 Then
			FillPropertyValues(DataString1, SelectionResult[0]);
		Else
			For Each ArrayElement In SelectionResult Do
				If SelectionResult.Find(ArrayElement) = 0 Then
					FillPropertyValues(DataString1, SelectionResult[0]);
				Else
					CurrentRow = Recipients.Add();
					FillPropertyValues(CurrentRow,ArrayElement);
					CurrentRow.AddressType =  DataString1.AddressType;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	CancelEdit = False;
	Items.Recipients.EndEditRow(CancelEdit);
	
EndProcedure

&AtClient
Procedure OpenApplicationTreeElement(String)
	
	If String <> Undefined Then
		If ValueIsFilled(String.RefID) Then
			IntegrationWith1CDocumentManagementCoreClient.OpenFile(
				String.RefID,
				String.Ref,
				String.Extension,
				UUID);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillOutFormFromXDTOObject(XDTOLetter, NewEmail = False)
	
	ID = XDTOLetter.objectID.ID;
	Type = XDTOLetter.objectID.type;
	Presentation = XDTOLetter.objectID.presentation;
	Subject = XDTOLetter.subject;
	EmailText = XDTOLetter.body;
	
	// is the sent property being filled in?
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3") Then
		Sent = XDTOLetter.sent;
		If Not Sent And Not NewEmail Then // Convert HTML to plaintext.
			TextOfLetterIsFormatted.SetHTML(XDTOLetter.body, New Structure);
			EmailText = TextOfLetterIsFormatted.GetText();
		EndIf;
	Else
		Sent = True;
	EndIf;
	
	If ValueIsFilled(XDTOLetter.objectID.ID) Then
		AddAddressees(XDTOLetter.senderAddress, NStr("vi = 'Người gửi:';
													|ru = 'От:';
													|en = 'From:'; fa = 'از:';
													|it = 'Del:';
													|pl = 'From:';
													|tr = 'Kimden:'"));
	Else
		Sender = XDTOLetter.senderAddress;
	EndIf;
	
	AddAddressees(XDTOLetter.recipients, NStr("vi = 'Người nhận:';
												|ru = 'Кому:';
												|en = 'To:'; fa = 'به:';
												|it = 'A chi:';
												|pl = 'Do:';
												|tr = 'Kime:'"));
	AddAddressees(XDTOLetter.courtesyCopyRecipients, NStr("vi = 'Cc:';
															|ru = 'Копия:';
															|en = 'Cc:'; fa = 'رونوشت:';
															|it = 'Copia:';
															|pl = 'Kopia:';
															|tr = 'Cc:'"));
	AddAddressees(XDTOLetter.blindCourtesyCopyRecipients, NStr("vi = 'CK:';
																|ru = 'СК:';
																|en = 'Bcc:'; fa = 'رونوشت مخفی:';
																|it = 'CN:';
																|pl = 'UDW:';
																|tr = 'Bcc:'"));
	
	CreationDate = XDTOLetter.creationDate;
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject, XDTOLetter.importance,"Importance");
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject, XDTOLetter.target,"SubjectOf");
	
	If Not ValueIsFilled(SubjectOfID) Then
		SubjectOf = "None";
		Items.SubjectOf.Hyperlink = False;
		Items.Basis.Visible = False;
	Else
		Basis1 = IntegrationWith1CDocumentManagementCore.LinksToExternalObjects(XDTOLetter.target);
		If Basis1.Count() = 0 Then
			Items.Basis.Visible = False;
		Else
			Basis = Basis1[0];
		EndIf;
	EndIf;
	
	If XDTOLetter.IsSet("answerType") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			ThisObject, XDTOLetter.answerType,"ReplyType");
	EndIf;
	
	If ReplyTypeID = "ПересылкаПисьма" Or Not ValueIsFilled(ReplyTypeID) Then //@NON-NLS-1
		Items.EmailBasis.Visible = False;
	EndIf;
	
	If XDTOLetter.IsSet("baseObject") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			ThisObject, XDTOLetter.baseObject,"EmailBasis");
	Else
		Items.EmailBasis.Visible = False;
	EndIf;
	
	If ValueIsFilled(XDTOLetter.subject) Then
		Title = StrTemplate(NStr("vi = '%1 (E-mail đi)';
								|ru = '%1 (Исходящее письмо)';
								|en = '%1 (Outgoing email)'; fa = '%1 (Outgoing email)';
								|it = '%1 (Posta in uscita)';
								|pl = '%1 (Wiadomość wychodząca)';
								|tr = '%1(Giden e-posta)'"), XDTOLetter.subject);
	Else
		Title = XDTOLetter.objectID.presentation;
	EndIf;
	
	If XDTOLetter.Properties().Get("files") <> Undefined Then
		For Each File In XDTOLetter.files Do
			String = ApplicationTree.Add();
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(String, File, "Ref");
			String.Extension = File.extension;
			String.Modified = File.modificationDateUniversal;
			String.Size = File.size;
			
			DeletionMark = False;
			If IntegrationWith1CDocumentManagementCore.PropertySet(File, "deletionMark") Then
				DeletionMark = File.deletionMark;
			EndIf;
			String.ItemTypeImage =
				IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(
					String.Extension,
					DeletionMark);
			
			SetItemTypeImage(String);
		EndDo;
	EndIf;
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.SetNavigationLink(ThisObject, XDTOLetter);
	
EndProcedure

&AtServer
Procedure AddAddressees(AddresseeString, AddressType)
	
	If Not IsBlankString(AddresseeString) Then
		ArrayOfRecipients = StrSplit(AddresseeString, ";", False);
		For Each Addressee In ArrayOfRecipients Do
			If Not IsBlankString(TrimAll(Addressee)) Then
				StringAddressee = Recipients.Add();
				StringAddressee.AddressType = AddressType;
				StringAddressee.Addressee = TrimAll(Addressee);
				StringAddressee.AddresseeType = "DMObject";
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetItemTypeImage(SubjectLine)
	If StrFind(SubjectLine.RefType,"Document.") <> 0 Then
		SubjectLine.ItemTypeImage = PictureLib.Document;
	ElsIf StrFind(SubjectLine.RefType,"Catalog.") <> 0 Then
		SubjectLine.ItemTypeImage = PictureLib.Catalog
	ElsIf StrFind(SubjectLine.RefType,"BusinessProcess.") <> 0 Then
		SubjectLine.ItemTypeImage = PictureLib.BusinessProcess;
	ElsIf StrFind(SubjectLine.RefType,"Task.") <> 0 Then
		SubjectLine.ItemTypeImage = PictureLib.Task;
	EndIf;
EndProcedure

&AtServer
Procedure FillInNewEmailCard(Proxy, Var_Parameters)
	
	If Var_Parameters.SubjectOf.type = "DMIncomingEMail" Then
		NewObject = GetResponseToIncomingEmail(Proxy, Var_Parameters);
		
	ElsIf Var_Parameters.SubjectOf.type = "DMOutgoingEMail"
			And Var_Parameters.Property("answerType") <> Undefined
			And Var_Parameters.answerType = "transfer" Then
		NewObject = GetOutgoingEmailForForwarding(Proxy, Var_Parameters);
		
	Else
		NewObject = IntegrationWith1CDocumentManagementCore.NewObjectBefore(
			Proxy,
			"DMOutgoingEMail",
			Var_Parameters.SubjectOf);
	EndIf;
	
	FillOutFormFromXDTOObject(NewObject, True);
	
EndProcedure

&AtServer
Function GetResponseToIncomingEmail(Proxy, Var_Parameters)
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetIncomingEMailAnswerRequest");
	Query.type = "DMOutgoingEmail";
	
	Query.targetID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		Var_Parameters.SubjectOf.ID,
		Var_Parameters.SubjectOf.type);
	
	Query.answerType = Var_Parameters.answerType;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMGetIncomingEMailAnswerResponse") Then
		Return Response.object;
	EndIf;
	
EndFunction

&AtServer
Function GetOutgoingEmailForForwarding(Proxy, Var_Parameters)
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetOutgoingEMailForwardRequest");
	Query.type = "DMOutgoingEmail";
	
	Query.targetID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		Var_Parameters.SubjectOf.ID,
		Var_Parameters.SubjectOf.type);
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMGetOutgoingEMailForwardResponse") Then
		Return Response.object;
	EndIf;
	
EndFunction

&AtServer
Procedure DisplayNumberOfServerFiles()
	
	If ApplicationTree.Count() > 0 Then
		Items.ApplicationTreeRef.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tệp (%1)';
				|ru = 'Файлы (%1)';
				|en = 'Files (%1)'; fa = 'Files (%1)';
				|it = 'File (%1)';
				|pl = 'Pliki (%1)';
				|tr = 'Dosyalar (%1)'"),
			ApplicationTree.Count());
	Else
		Items.ApplicationTreeRef.Title = NStr("vi = 'Tệp';
												|ru = 'Файлы';
												|en = 'Files'; fa = 'فایل‌ها';
												|it = 'File';
												|pl = 'Files';
												|tr = 'Dosyalar'");
	EndIf;
	
EndProcedure

&AtServer
Procedure SendOnServer(FilesArray)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	MailMessage = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMOutgoingEMail");
	AttachedFiles = MailMessage.files; // XDTOList
	
	MailMessage.name = Subject;
	MailMessage.subject = Subject;
	MailMessage.body = EmailText;
	MailMessage.creationDate = CurrentSessionDate();
	MailMessage.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, "", "DMOutgoingEMail");
	
	If ValueIsFilled(EmailBasis) Then
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy, ThisObject, "EmailBasis", MailMessage.baseObject, "DMObject");
	EndIf;
	
	If ValueIsFilled(ReplyType) Then
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy, ThisObject, "ReplyType", MailMessage.answerType, "DMEMailAnswerType");
	EndIf;
	
	If ValueIsFilled(SubjectOf) Then
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy, ThisObject, "SubjectOf", MailMessage.target, "DMObject");
	EndIf;
	
	IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
		Proxy, ThisObject, "Importance", MailMessage.importance, "DMEMailImportance");
	
	MailMessage.recipients = GetStringOfRecipients("Whom:");
	MailMessage.courtesyCopyRecipients = GetStringOfRecipients("Copy:");
	MailMessage.blindCourtesyCopyRecipients = GetStringOfRecipients("SK:");
	
	MailMessage.readyToBeSent = CurrentSessionDate();
	MailMessage.senderAddress = Sender;
	
	// file transfer
	For Each FileParameters In FilesArray Do
		AttachedFiles.Add(PrepareFileForSubmission(Proxy, FileParameters));
	EndDo;
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMCreateRequest");
	Query.object = MailMessage;
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
EndProcedure

&AtServer
Function GetStringOfRecipients(AddressType)
	
	RecipientLines = Recipients.FindRows(New Structure("AddressType",AddressType));
	RecipientsByString = "";
	For Each String In RecipientLines Do
		RecipientsByString = RecipientsByString + String.Addressee + "; ";
	EndDo;
	
	Return RecipientsByString;
	
EndFunction

&AtClient
Function PrepareFileFromDisk(String)
	
	CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		String.Ref,
		Undefined,
		"DMFile",
		String.Extension);
	CurrentFile.Size = String.Size;
	CurrentFile.ModificationDate = String.Modified;
	CurrentFile.UniversalModificationDate = String.ModificationTimeUniversal;
	
	CreationParameters = IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions(
		CurrentFile);
	CreationParameters.TempFileStorageAddress = String.TempFileStorageAddress;
	
	Return CreationParameters;
	
EndFunction

&AtClient
Function PrepareAFileInThe1CDocumentManagement(String)
	
	CurrentFile = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
		String.Ref,
		String.RefID,
		String.RefType,
		String.Extension);
	CurrentFile.Size = String.Size;
	CurrentFile.ModificationDate = String.Modified;
	CurrentFile.UniversalModificationDate = String.ModificationTimeUniversal;
	
	CreationParameters = IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions(
		CurrentFile);
	
	Return CreationParameters;
	
EndFunction

&AtClient
Procedure StartAddingFileFromDisk()
	
	BeginAttachingFileSystemExtension(New CallbackDescription(
		"StartAddingFileFromDiskAfterConnectingExtension", ThisObject));
	
EndProcedure

&AtClient
Procedure StartAddingFileFromDiskAfterConnectingExtension(Attached, NotificationParameters) Export
	
	If Attached Then
		
		SelectingFile = New FileDialog(FileDialogMode.Open);
		SelectingFile.Multiselect = True;
		SelectingFile.Title = NStr("vi = 'Chọn tệp';
									|ru = 'Выбор файла';
									|en = 'Select file'; fa = 'انتخاب فایل';
									|it = 'Selezione del file';
									|pl = 'Wybór pliku';
									|tr = 'Dosya seçimi'");
		SelectingFile.Filter = NStr("vi = 'Tất cả tệp (*.*)|*.*';
									|ru = 'Все файлы (*.*)|*.*';
									|en = 'All files (*.*)|*.*'; fa = 'All files (*.*)|*.*';
									|it = 'Tutti i file (*.*)|*.*';
									|pl = 'Wszystkie pliki (*.*)|*.*';
									|tr = 'Tüm dosyalar (*.*)|*.*'");
		SelectingFile.Show(New CallbackDescription(
			"StartAddingFileFromDiskAfterFileSelectionDialog", ThisObject));
		
	Else
		
		ShowMessageBox(, NStr("vi = 'Cần kết nối phần mở rộng để làm việc với tệp.';
								|ru = 'Необходимо подключить расширение для работы с файлами.';
								|en = 'Attach the 1C:Enterprise Extension.'; fa = 'Attach the 1C:Enterprise Extension.';
								|it = 'Необходимо подключить расширение для работы с файлами.';
								|pl = 'Attach the 1C:Enterprise Extension.';
								|tr = 'Dosyalarla çalışmak için uzantıyı bağlamanız gerekir.'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StartAddingFileFromDiskAfterFileSelectionDialog(FullFileNames, NotificationParameters) Export
	
	If FullFileNames <> Undefined Then
		StartAddingFileFromDiskByNameArray(FullFileNames);
	EndIf;
	
EndProcedure

&AtClient
Procedure StartAddingFileFromDiskByNameArray(FullFileNames)
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("FilesDetails1", New Array);
	For Each FullFileName In FullFileNames Do
		FileDetails = New Structure;
		FileDetails.Insert("FullFileName", FullFileName);
		// Let's analyze the full path by name and extension.
		NameStructure = IntegrationWith1CDocumentManagementCoreClient.ParseFullFileName(
			FullFileName);
		FileDetails.Insert("Extension", NameStructure.Extension);
		FileDetails.Insert("Name", NameStructure.BaseName);
		FileDetails.Insert("ItemTypeImage",
			IntegrationWith1CDocumentManagementCoreClient.IndexOfFileIcon(
				NameStructure.Extension));
		NotificationParameters.FilesDetails1.Add(FileDetails);
	EndDo;
	NotificationParameters.Insert("FileNumber", 0);
	
	File = New File(NotificationParameters.FilesDetails1[0].FullFileName);
	NotificationParameters.FilesDetails1[0].Insert("File", File);
	
	File.BeginGettingSize(
		New CallbackDescription("StartAddingFileFromDiskAfterGettingSize",
			ThisObject, NotificationParameters));
	
EndProcedure

&AtClient
Procedure StartAddingFileFromDiskAfterGettingSize(Size, NotificationParameters) Export
	
	FileDetails = NotificationParameters.FilesDetails1[NotificationParameters.FileNumber];
	FileDetails.Insert("Size", Size);
	FileDetails.File.BeginGettingModificationTime(
		New CallbackDescription("StartAddingFileFromDiskAfterGettingChangeTime",
			ThisObject, NotificationParameters));
	
EndProcedure

&AtClient
Procedure StartAddingFileFromDiskAfterGettingChangeTime(Var_Modified, NotificationParameters) Export
	
	FileDetails = NotificationParameters.FilesDetails1[NotificationParameters.FileNumber];
	FileDetails.Insert("Modified", Var_Modified);
	FileDetails.File.BeginGettingModificationUniversalTime(
		New CallbackDescription("StartAddingFileFromDiskAfterGettingUniversalChangeTime",
			ThisObject, NotificationParameters));
	
EndProcedure

&AtClient
Procedure StartAddingFileFromDiskAfterGettingUniversalChangeTime(ModificationTimeUniversal,
		NotificationParameters) Export
	
	FileDetails = NotificationParameters.FilesDetails1[NotificationParameters.FileNumber];
	FileDetails.Insert("ModificationTimeUniversal", ModificationTimeUniversal);
	
	// Are there any more files?
	If NotificationParameters.FileNumber < NotificationParameters.FilesDetails1.Count() - 1 Then
		NotificationParameters.FileNumber = NotificationParameters.FileNumber + 1;
		File = New File(NotificationParameters.FilesDetails1[NotificationParameters.FileNumber].FullFileName);
		NotificationParameters.FilesDetails1[NotificationParameters.FileNumber].Insert("File", File);
		
		File.BeginGettingSize(
			New CallbackDescription("StartAddingFileFromDiskAfterGettingSize",
				ThisObject, NotificationParameters));
	Else
		Files = New Array;
		For Each FileDetails In NotificationParameters.FilesDetails1 Do
			Files.Add(New TransferableFileDescription(FileDetails.FullFileName, ""));
		EndDo;
		ImportParameters = FileSystemClient.FileImportParameters();
		ImportParameters.Interactively = False;
		ImportParameters.FormIdentifier = UUID;
		FileSystemClient.ImportFiles(
			New CallbackDescription(
				"StartAddingFileFromDiskAfterPlacingFiles",
				ThisObject,
				NotificationParameters),
			ImportParameters,
			Files);
	EndIf;
	
EndProcedure

// Continuation of the procedure to begin the addition of the file after the receipt of the universal time of the change.
//
// Parameters:
//   PlacedFiles - Array of TransferredFileDescription
//   NotificationParameters - Structure:
//     * FilesDetails1 - Array of Structure:
//         ** FullFileName - String
//         ** Extension - String
//         ** Name - String
//         ** ItemTypeImage - Number
//     * FileNumber - Number
//
&AtClient
Procedure StartAddingFileFromDiskAfterPlacingFiles(PlacedFiles, NotificationParameters) Export
	
	For FileNumber = 0 To PlacedFiles.UBound() Do
		FileThatWasPut = PlacedFiles[FileNumber];
		FileDetails = NotificationParameters.FilesDetails1[FileNumber];
		NewRow = ApplicationTree.Add();
		NewRow.Ref = FileDetails.Name;
		NewRow.Extension = FileDetails.Extension;
		NewRow.ItemTypeImage = FileDetails.ItemTypeImage;
		NewRow.Size = FileDetails.Size;
		NewRow.Modified = FileDetails.Modified;
		NewRow.ModificationTimeUniversal = FileDetails.ModificationTimeUniversal;
		NewRow.TempFileStorageAddress = FileThatWasPut.Location;
	EndDo;
	
EndProcedure

// Creates an XDTO object of the DMFile type.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   CreationParameters - Structure - IntegrationWith1CDocumentManagementCoreClientServer.NewFileCreationOptions
//
// Returns:
//   XDTODataObject
//
&AtServer
Function PrepareFileForSubmission(Proxy, CreationParameters)
	
	File = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMFile");
	
	File.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, "", "DMFile");
	File.name = CreationParameters.CurrentFile.Description;
	
	If ValueIsFilled(CreationParameters.CurrentFile.ID) Then
		File.objectID.ID = CreationParameters.CurrentFile.ID;
	Else
		File.binaryData = GetFromTempStorage(CreationParameters.TempFileStorageAddress);
		File.extension = CreationParameters.CurrentFile.Extension;
		File.modificationDate = CreationParameters.CurrentFile.ModificationDate;
		File.modificationDateUniversal = CreationParameters.CurrentFile.UniversalModificationDate;
		File.size = CreationParameters.CurrentFile.Size;
		If Not IsBlankString(CreationParameters.CurrentFile.Text) Then
			File.text = CreationParameters.CurrentFile.Text;
		EndIf;
	EndIf;
	
	Return File;
	
EndFunction

&AtClient
Procedure CloseFormForForwarding()
	
	Close();
	
EndProcedure

&AtServerNoContext
Procedure DataForAutomaticDestinationSelection(ChoiceData, Text, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceData = New ValueList;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetRecipientsListByNameRequest");
	Query.query = Text;
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
	FoundValues =  Result.items;
	
	For Each ValueFound In FoundValues Do
		
		DataToSelect = New Structure;
		DataToSelect.Insert("ID", "");
		DataToSelect.Insert("type", "DMObject");
		DataToSelect.Insert("name", ValueFound);
		DataToSelect.Insert("presentation", ValueFound);
		DataToSelect.Insert("isNotAvailableAccordingCommunicationRules", False);
		ChoiceData.Add(DataToSelect, ValueFound);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SetCurRecipientElement()
		
	AddressEditingStartedAutomatically = True;
	Items.Recipients.AddRow();
	Modified = False;
	
EndProcedure

&AtClient
Procedure SetCurThemeItem()
	
	CurrentItem = Items.Subject;
	
EndProcedure

&AtClient
Procedure SetCurTextElement()
	
	CurrentItem = Items.Subject;
	
	If ValueIsFilled(ID) Then
		CurrentItem = Items.HTMLPresentation;
	Else
		CurrentItem = Items.PlainText;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessDestinationSelection(SelectionResult)
	
	If TypeOf(SelectionResult) = Type("Array") Then
		If SelectionResult.Count() = 1 Then
			FillPropertyValues(Items.Recipients.CurrentData, SelectionResult[0]);
			Items.Recipients.CurrentData.NotFound = False;
		Else
			For Each ArrayElement In SelectionResult Do
				If SelectionResult.Find(ArrayElement) = 0 Then
					FillPropertyValues(Items.Recipients.CurrentData, SelectionResult[0]);
					Items.Recipients.CurrentData.NotFound = False;
				Else
					CurrentRow = Recipients.Add();
					FillPropertyValues(CurrentRow,ArrayElement);
					CurrentRow.AddressType =  Items.Recipients.CurrentData.AddressType;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function CheckEmailBeforeSending()
	
	ReturnCode = True;
	
	AddressesList = New Array;
	For Each Page1 In Recipients Do
		If ValueIsFilled(Page1.Addressee) Then
			AddressesList.Add(Page1.Addressee);
		EndIf;
	EndDo;
	
	If AddressesList.Count() = 0 Then
		
		Common.MessageToUser(
			NStr("vi = 'Không thể gửi thư. Cần chỉ ra ít nhất một người nhận.';
				|ru = 'Нельзя отправить письмо. Необходимо указать хотя бы одного получателя.';
				|en = 'Cannot send email. Specify at least one recipient.'; fa = 'Cannot send email. Specify at least one recipient.';
				|it = 'Non è possibile inviare il messaggio. È necessario indicare almeno un destinatario.';
				|pl = 'Nie można wysłać wiadomości. Należy wskazać co najmniej jednemu odbiorcy.';
				|tr = 'E-posta gönderilemez. En az bir alıcı belirtmek gerekir.'"),,
				"Recipients");
		
		ReturnCode = False;
		
	EndIf;
	
	If IsBlankString(Subject) Then
		
		Common.MessageToUser(
			NStr("vi = 'Không thể gửi thư. Chưa điền chủ đề.';
				|ru = 'Нельзя отправить письмо. Не заполнена тема.';
				|en = 'Cannot send email. Subject is required.'; fa = 'Cannot send email. Subject is required.';
				|it = 'Non è possibile inviare il messaggio. Oggetto non compilato.';
				|pl = 'Nie można wysłać wiadomości. Temat nie jest wypełniony.';
				|tr = 'E-posta gönderilemiyor. Konu doldurulmadı.'"),,
			"Subject");
		
		ReturnCode = False;
		
	EndIf;
	
	If ReturnCode = False Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

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
