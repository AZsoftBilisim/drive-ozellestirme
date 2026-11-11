#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("ID") Then
		SubjectOfID = Parameters.ID;
		SubjectOfType = Parameters.type;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.8.1.CORP")
			And Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.1.1") Then
		GetFillInEmailTree();
	Else
		DataProcessors.IntegrationWith1CDocumentManagement.ProcessFormIfServiceVersionFunctionalityIsUnavailable(ThisObject);
		Items.MessageTree.Visible = False;
	EndIf;
	
	If SubjectOfType = "DMCorrespondent" Then
		Items.MessageTreeNumber.Visible = True;
		Items.MessageTreeRecipients.Visible = False;
		Items.MessageTreeMailMessage.Title = NStr("vi = 'Văn bản';
													|ru = 'Документ';
													|en = 'Document'; fa = 'سند';
													|it = 'Documento';
													|pl = 'Dokument';
													|tr = 'Belge'");
	Else
		Items.MessageTreeNumber.Visible = False;
		Items.MessageTreeRecipients.Visible = True;
		Items.MessageTreeMailMessage.Title = NStr("vi = 'E-mail';
													|ru = 'Письмо';
													|en = 'Email'; fa = 'ایمیل';
													|it = 'Mail';
													|pl = 'Email';
													|tr = 'E-posta'");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ExpandMessageTree();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Recording_1CDocumentManagementOutgoingEmail" Then
		If Source = ThisObject Then
			GetFillInEmailTree();
			ExpandMessageTree();
		ElsIf ValueIsFilled(Parameter) Then
			If Parameter.SubjectOfID = SubjectOfID Then
				GetFillInEmailTree();
				ExpandMessageTree();
			ElsIf EmailIsInList(Parameter.EmailBasisID) Then
				GetFillInEmailTree();
				ExpandMessageTree();
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMessageTree

&AtClient
Procedure MessageTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = MessageTree.FindByID(RowSelected);
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(CurrentRow.MailMessageType, CurrentRow.MailMessageID, ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	GetFillInEmailTree();
	
EndProcedure

&AtClient
Procedure OpenObject(Command)
	
	CurrentRow = Items.MessageTree.CurrentData;
	
	If CurrentRow <> Undefined Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(CurrentRow.MailMessageType, CurrentRow.MailMessageID, ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GetFillInEmailTree()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetCorrespondenceTreeQuery");
	CorrespondenceObjects = ListOfConditions.target; // XDTOList
	
	SubjectXDTO = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObject");
	SubjectXDTO.name = "";
	SubjectXDTO.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		SubjectOfID,
		SubjectOfType);
	CorrespondenceObjects.Add(SubjectXDTO);
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetCorrespondenceTreeRequest");
	Query.query = ListOfConditions;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	Tree = FormAttributeToValue("MessageTree");
	Tree.Rows.Clear();
	For Each Item In Response.followers Do
		FillInTreeLine(Tree.Rows, Item);
	EndDo;
	ValueToFormAttribute(Tree, "MessageTree");
	
EndProcedure

&AtServer
Procedure FillInTreeLine(TreeRows, XDTORow)
	
	TreeRow = TreeRows.Add();
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TreeRow, XDTORow.object, "MailMessage");
	TreeRow.Recipients = XDTORow.recipients;
	TreeRow.Date = XDTORow.date;
	
	If SubjectOfType = "DMCorrespondent" Or SubjectOfType = "DMOutgoingEMail" Then
		If XDTORow.Properties().Get("regNumber") <> Undefined Then
			TreeRow.Number = XDTORow.regNumber;
		EndIf;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTORow, "sent") Then
		TreeRow.Shipped_5 = XDTORow.sent;
	Else
		TreeRow.Shipped_5 = False;
	EndIf;
	
	If TreeRow.MailMessageType = "DMIncomingEMail" Then
		TreeRow.Picture = 0;
	ElsIf TreeRow.MailMessageType = "DMOutgoingEMail" Then
		// is the sent property being filled in?
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
			If TreeRow.Shipped_5 = True Then
				TreeRow.Picture = 1;
			Else
				TreeRow.Picture = 3;
			EndIf;
		Else
			TreeRow.Picture = 1;
		EndIf;
	ElsIf SubjectOfType = "DMCorrespondent" Then
		If TreeRow.MailMessageType = "DMInternalDocument" Then
			TreeRow.Picture = 2;
		ElsIf TreeRow.MailMessageType = "DMIncomingDocument" Then
			TreeRow.Picture = 0;
		Else
			If TreeRow.Shipped_5 Then
				TreeRow.Picture = 1;
			Else
				TreeRow.Picture = 3;
			EndIf;
		EndIf;
	Else
		TreeRow.Picture = 2;
	EndIf;
	
	For Each Item In XDTORow.followers Do
		FillInTreeLine(TreeRow.Rows, Item);
	EndDo;
	
EndProcedure

&AtClient
Procedure ExpandMessageTree()
	
	TreeItems = MessageTree.GetItems();
	For Each TreeItem In TreeItems Do
		Items.MessageTree.Expand(TreeItem.GetID(), True);
	EndDo;
	
EndProcedure

&AtClient
Function EmailIsInList(MailMessageID)
	
	TreeItems = MessageTree.GetItems();
	Return CheckForTreeElement(TreeItems,MailMessageID);
	
EndFunction

&AtClient
Function CheckForTreeElement(TreeItems, MailMessageID)
	
	For Each TreeItem In TreeItems Do
		If TreeItem.MailMessageID = MailMessageID Then
			Return True;
		EndIf;
		SubordinateItems = TreeItem.GetItems();
		
		Return CheckForTreeElement(SubordinateItems, MailMessageID)
	EndDo;

	Return False;
	
EndFunction

#EndRegion