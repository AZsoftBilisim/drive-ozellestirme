#Region Variables

&AtClient
Var LinkTreeStringKey;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ObjectBefore = Parameters.Description;
	ObjectBeforeID = Parameters.ID;
	ObjectBeforeType = Parameters.Type;
	MapItemDMNavigationLink = Parameters.URL;
	
	Title = StrTemplate(NStr("vi = 'Liên kết: %1';
							|ru = 'Связи: %1';
							|en = 'Links: %1'; fa = 'Links: %1';
							|it = 'Links: %1';
							|pl = 'Links: %1';
							|tr = 'Bağlantılar: %1'"), ObjectBefore);
	
	PreviewOfLinksStorage = Common.CommonSettingsStorageLoad(
		"ObjectsLinksBefore",
		"PreviewBIDFiles");
	If PreviewOfLinksStorage = Undefined Then
		PreviewLinks = False;
	Else
		PreviewLinks = PreviewOfLinksStorage;
	EndIf;
	
	Items.LinkTreePreview.Check = PreviewLinks;
	Items.ViewPages.Visible = PreviewLinks;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TestConnection();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If ShowPDFUsing1C Then
		ThisObject["PDFDocumentAttributes"] = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Not IsOpen() Then
		Return;
	EndIf;
	
	If EventName = "IntegrationWith1CDocumentManagement_SuccessfulConnection" Then
		If Source <> ThisObject Then
			WhenConnecting();
		EndIf;
		
	ElsIf EventName = "HTMLObjectPreviewReceived" Then
		If Not IntegrationWith1CDocumentManagementCoreClientServer.TheseAreNotificationParametersHTMLObjectPreviewReceived(
				Parameter) Then
			Return;
		EndIf;
		ProcessHTMLPreviewReceiptEvent(Parameter, Source);
		
	ElsIf EventName = "Recording_1CDocumentManagementFile" Then
		If TypeOf(Parameter) <> Type("Structure")
				Or Not Parameter.Property("FileOperation")
				Or Not Parameter.Property("FileID")
				Or Not Parameter.Property("FileOwner")
				Or Not Parameter.Property("FileName")
				Or Not Parameter.Property("FormUniqueID")
				Or Not Parameter.FileOperation.InformFileListForm Then
			Return;
		EndIf;
		OwnerRow = IntegrationWith1CDocumentManagement3ClientServer.LinkByID(
			LinkTree.GetItems(),
			Parameter.FileOwner);
		If OwnerRow <> Undefined Then
			If Parameter.FormUniqueID = Undefined Then
				OutputIdleWindow = (Source = ThisObject);
			Else
				OutputIdleWindow = (UUID = Parameter.FormUniqueID);
			EndIf;
			StartUpdatingForm(OutputIdleWindow);
		EndIf;
		
	ElsIf EventName = "AddingObjectLinksTO" Or EventName = "DeletingObjectLinksBEFORE" Then
		If TypeOf(Parameter) <> Type("Structure")
				Or Not Parameter.Property("ID")
				Or Not Parameter.Property("Type") Then
			Return;
		EndIf;
		NeedUpdate = (Parameter.ID = ObjectBeforeID) And (Parameter.Type = ObjectBeforeType);
		If NeedUpdate Then
			OutputIdleWindow = (Source <> ThisObject);
			StartUpdatingForm(OutputIdleWindow);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AuthorizationSettingsDecorationClick(Item)
	
	Notification = New CallbackDescription("AuthorizationSettingsDecorationClickCompletion", ThisObject);
	NameOfParameterForm =
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.AuthorizationIn1CDocumentManagement";
	
	OpenForm(NameOfParameterForm,, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AuthorizationSettingsDecorationClickCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		WhenConnecting();
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowOnlyOriginalsInLinksOnChange(Item)
	
	StartUpdatingForm(True);
	
EndProcedure

&AtClient
Procedure PresentationOfHTMLLinkWhenClicked(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(EventData.Href) Then
		Return;
	EndIf;
	
	RelationshipTreeCurrentData = IntegrationWith1CDocumentManagement3Client.LinkTreeCurrentDataToView(
		Items.LinkTree);
	
	If StrFind(EventData.Href, "OpenForEdit") Then
		
		OpenCurFileForEditing(RelationshipTreeCurrentData);
		
	ElsIf StrFind(EventData.Href, "OpenForView") Then
		
		OpenCurFileForReading(RelationshipTreeCurrentData);
		
	ElsIf StrFind(EventData.Href, "CreatePreview") Then
		
		UpdateLinkPreview(True, True);
		
	ElsIf StrFind(EventData.Href, "v8doc:status") Then
		
		IntegrationWith1CDocumentManagement3Client.OpenWorkflowFormFromLinkTree(
			"ProcessingPage",
			RelationshipTreeCurrentData,
			UUID);
		
	ElsIf StrFind(EventData.Href, "ShowLinks") Then
		
		If RelationshipTreeCurrentData <> Undefined Then
			LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				RelationshipTreeCurrentData.LinkedObjectID,
				RelationshipTreeCurrentData.LinkedObjectType,
				RelationshipTreeCurrentData.LinkedObject,,
				RelationshipTreeCurrentData.URL);
			IntegrationWith1CDocumentManagement3Client.ShowObjectConnections(LinkedObjectBefore);
		EndIf;
		
	ElsIf IntegrationWith1CDocumentManagementCoreClient.IsURL(EventData.Href) Then
		
		IntegrationWith1CDocumentManagementCoreClient.OpenURL(EventData.Href);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLinkTree

&AtClient
Procedure LinkTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	RelationshipTreeCurrentData = IntegrationWith1CDocumentManagement3Client.LinkTreeCurrentDataToView(
		Items.LinkTree);
	IntegrationWith1CDocumentManagement3Client.OpenLinkedObjectForViewing(
		RelationshipTreeCurrentData,
		UUID);
	
EndProcedure

&AtClient
Procedure LinkTreeBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
	If Not CreatingLinksIsAvailable Then
		Return;
	EndIf;
	
	InitialObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		ObjectBeforeID,
		ObjectBeforeType,
		ObjectBefore,,
		MapItemDMNavigationLink);
	IntegrationWith1CDocumentManagement3Client.StartAddingLink(InitialObjectBefore);
	
EndProcedure

&AtClient
Procedure LinkTreeBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	RelationshipTreeCurrentData = IntegrationWith1CDocumentManagement3Client.LinkTreeCurrentDataToView(
		Items.LinkTree);
	If RelationshipTreeCurrentData = Undefined Then
		Return;
	EndIf;
	If Not ValueIsFilled(RelationshipTreeCurrentData.LinkedObjectID)
			Or Not ValueIsFilled(RelationshipTreeCurrentData.LinkedObjectType) Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		RelationshipTreeCurrentData.LinkedObjectType,
		RelationshipTreeCurrentData.LinkedObjectID,
		ThisObject);
	
EndProcedure

&AtClient
Procedure LinkTreeBeforeExpand(Item, String, Cancel)
	
	TreeRow = LinkTree.FindByID(String);
	ParentRow = TreeRow.GetParent();
	
	If ParentRow <> Undefined
			And TreeRow.ThisIsCommunicationBranch
			And TreeRow.GetItems().Count() > 0 Then
		SubordinateRow = TreeRow.GetItems()[0];
		If SubordinateRow.ServiceLine Then
			If TreeOfLinksIsExpandedString <> 0 Then
				Cancel = True;
				Return;
			EndIf;
			SubordinateRow.LinkedObject = NStr("vi = 'Đang chờ lấy dữ liệu từ 1C:Document Management...';
												|ru = 'Ожидается получение данных из 1С:Документооборота...';
												|en = 'Expecting data from 1C:Document Management...'; fa = 'Expecting data from 1C:Document Management...';
												|it = 'Expecting data from 1C:Document Management...';
												|pl = 'Expecting data from 1C:Document Management...';
												|tr = '1C:Document Management üzerinden veri alınması bekleniyor...'");
			TreeOfLinksIsExpandedString = TreeRow.GetID();
			StartUpdatingForm(False);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure LinkTreeBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	If Not CreatingLinksIsAvailable Then
		Return;
	EndIf;
	
	InitialObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		ObjectBeforeID,
		ObjectBeforeType,
		ObjectBefore,,
		MapItemDMNavigationLink);
	IntegrationWith1CDocumentManagement3Client.StartDeletingLink(Items.LinkTree, InitialObjectBefore);
	
EndProcedure

&AtClient
Procedure LinkTreeOnActivateRow(Item)
	
	If Item.CurrentRow = Undefined Or Item.CurrentRow = LinkTreeStringKey Then
		Return;
	EndIf;
	LinkTreeStringKey = Item.CurrentRow;
	
	LinkCanBeDeleted = IntegrationWith1CDocumentManagement3Client.LinkCanBeDeleted(Items.LinkTree.CurrentData);
	Items.LinkTreeDelete.Enabled = LinkCanBeDeleted;
	Items.LinkTreeContextMenuDelete.Enabled = LinkCanBeDeleted;
	
	RelationshipTreeCurrentData = IntegrationWith1CDocumentManagement3Client.LinkTreeCurrentDataToView(
		Items.LinkTree);
	If RelationshipTreeCurrentData = Undefined Then
		Return;
	EndIf;
	
	IsReferenceObject = ValueIsFilled(RelationshipTreeCurrentData.LinkedObjectID)
		And ValueIsFilled(RelationshipTreeCurrentData.LinkedObjectType);
	IsFile = (RelationshipTreeCurrentData.LinkedObjectType = "DMFile");
	
	Items.LinkTreeOpen.Enabled = IsReferenceObject;
	Items.LinkTreeContextMenuOpenButton.Enabled = IsReferenceObject;
	Items.LinkTreeChange.Enabled = IsReferenceObject;
	Items.LinkTreeContextMenuEditButton.Enabled = IsReferenceObject;
	
	Items.SaveLinkTreeAs.Enabled = IsFile;
	Items.LinkTreeContextMenuSaveAsButton.Enabled = IsFile;
	Items.LinkTreePrintFiles.Enabled = IsFile;
	Items.LinkTreeContextMenuPrintFilesButton.Enabled = IsFile;
	
	HTMLLinkPresentation = IntegrationWith1CDocumentManagementCoreClientServer.DownloadMessage();
	Items.ViewPages.CurrentPage = Items.HTMLGroupPage;
	Items.GroupPreviewCut.Visible = False;
	AttachIdleHandler("UpdatePreviewOfWaitHandlerConnection", 0.2, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PDFDocumentLeftTurn(Command)
	
	Items["DocumentPDFField"].Orientation = Items["DocumentPDFField"].Orientation - 90;
	
EndProcedure

&AtClient
Procedure PDFDocumentTurnRight(Command)
	
	Items["DocumentPDFField"].Orientation = Items["DocumentPDFField"].Orientation + 90;
	
EndProcedure

&AtClient
Procedure PDFDocumentEnlarge(Command)
	
	Items["DocumentPDFField"].Scale = Items["DocumentPDFField"].Scale + 10;
	
EndProcedure

&AtClient
Procedure PDFDocumentReduce(Command)
	
	If Items["DocumentPDFField"].Scale <= 10 Then
		Return;
	EndIf;
	
	Items["DocumentPDFField"].Scale = Items["DocumentPDFField"].Scale - 10;
	
EndProcedure

&AtClient
Procedure UpdateLinkPreviewCommand(Command)
	
	UpdateLinkPreview(True);
	
EndProcedure

&AtClient
Procedure UpdateConnectionsCommand(Command)
	
	StartUpdatingForm(True);
	
EndProcedure

&AtClient
Procedure OpenALink(Command)
	
	RelationshipTreeCurrentData = IntegrationWith1CDocumentManagement3Client.LinkTreeCurrentDataToView(
		Items.LinkTree);
	IntegrationWith1CDocumentManagement3Client.OpenLinkedObjectForViewing(
		RelationshipTreeCurrentData,
		UUID);
	
EndProcedure

&AtClient
Procedure SwitchPreviewOfLinks(Command)
	
	PreviewLinks = Not PreviewLinks;
	Items.LinkTreePreview.Check = PreviewLinks;
	Items.ViewPages.Visible = PreviewLinks;
	CommonServerCall.CommonSettingsStorageSave(
		"ObjectsLinksBefore",
		"PreviewBIDFiles",
		PreviewLinks);
	UpdateLinkPreview();
	
EndProcedure

&AtClient
Procedure ShowAllConnections(Command)
	
	OnlyImportantConnections = False;
	Items.LinkTreeShowAllLinks.Enabled = False;
	Items.InfoCommunicationGroup.Visible = False;
	
	StartUpdatingForm(True);
	
EndProcedure

&AtClient
Procedure SaveLinkTreeAs(Command)
	
	RelationshipTreeCurrentData = IntegrationWith1CDocumentManagement3Client.LinkTreeCurrentDataToView(
		Items.LinkTree);
	If RelationshipTreeCurrentData = Undefined Or RelationshipTreeCurrentData.LinkedObjectType <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.SaveFileAs(
		RelationshipTreeCurrentData.LinkedObjectID,
		RelationshipTreeCurrentData.LinkedObject,
		RelationshipTreeCurrentData.FileExtention,
		UUID);
	
EndProcedure

&AtClient
Procedure LinkTreePrintFiles(Command)
	
#If WebClient Then
	ShowMessageBox(,NStr("vi = 'Trên Web-client không hỗ trợ in tệp.';
						|ru = 'В Веб-клиенте печать файлов не поддерживается.';
						|en = 'Printing of files is not supported in the web client.'; fa = 'Printing of files is not supported in the web client.';
						|it = 'Non è supportata la stampa di file nel client web.';
						|pl = 'W kliencie webowym drukowanie plików nie jest obsługiwane.';
						|tr = 'Web istemcisi, dosyaların yazdırılmasını desteklemez.'"));
	Return;
#EndIf
	
	Selected_Files = New Array;
	
	For Each SelectedRow In Items.LinkTree.SelectedRows Do
		Data = LinkTree.FindByID(SelectedRow);
		If Data.LinkedObjectType <> "DMFileRole" Then
			FileData = IntegrationWith1CDocumentManagementCoreClientServer.FileData(
				Data.LinkedObject,
				Data.LinkedObjectID,
				Data.LinkedObjectType,
				Data.FileExtention,
				Data.LinkedObjectID);
			Selected_Files.Add(FileData);
		EndIf;
	EndDo;
	
	IntegrationWith1CDocumentManagementCoreClient.PrintFiles(
		Selected_Files,
		Items.LinkTree.SelectedRows,
		UUID);
	
EndProcedure

#EndRegion

#Region Private

#Region Client

&AtClient
Procedure UpdateLinkPreview(UpdateData1 = False, IgnoreMaxSize = False)
	
	If Not PreviewLinks Then
		Return;
	EndIf;
	
	HTMLLinkPresentation = IntegrationWith1CDocumentManagementCoreClientServer.DownloadMessage();
	Items.ViewPages.CurrentPage = Items.HTMLGroupPage;
	Items.GroupPreviewCut.Visible = False;
	
	RelationshipTreeCurrentData = IntegrationWith1CDocumentManagement3Client.LinkTreeCurrentDataToView(
		Items.LinkTree);
	If RelationshipTreeCurrentData = Undefined Then
		HTMLLinkPresentation = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
			TitleOfMessageInPreviewArea);
		Return;
	EndIf;
	If RelationshipTreeCurrentData.WaitingForPreview Then
		Return;
	EndIf;
	
	// The receipt of the document's NDPS is combined with the receipt of a preview for optimization.
	// We will get the NDPS in one batch request together with the preview, for one service call BEFORE.
	// In advance, when receiving the task list, it is impossible to get the NDPS of all items, because this
	// will significantly slow down the updating of the list.
	ObjectForGettingPersonalData = Undefined;
	DocumentLine = IntegrationWith1CDocumentManagement3ClientServer.DocumentStringInLinkTree(RelationshipTreeCurrentData);
	If DocumentLine <> Undefined Then
		ObjectForGettingPersonalData =
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				DocumentLine.LinkedObjectID,
				DocumentLine.LinkedObjectType);
	EndIf;
	
	ReturnBinaryData = ShowPDFUsing1C
		And (Lower(RelationshipTreeCurrentData.FileExtention) = "pdf")
		And Not RelationshipTreeCurrentData.Encrypted;
	ThereIsPreviewFile = IsTempStorageURL(RelationshipTreeCurrentData.AddressInPreviewFileStorage)
		And Not RelationshipTreeCurrentData.Encrypted;
	
	If (RelationshipTreeCurrentData.LinkedObjectType = "DMFile"
				Or IntegrationWith1CDocumentManagement3ClientCached.ThisIsWellKnownObjectOfReview(RelationshipTreeCurrentData.LinkedObjectType))
			And (UpdateData1
				Or (ReturnBinaryData And Not ThereIsPreviewFile)
				Or (Not ValueIsFilled(RelationshipTreeCurrentData.PresentationHTML) And Not ThereIsPreviewFile)) Then
		
		RelationshipTreeCurrentData.WaitingForPreview = True;
		TimeConsumingOperation = IntegrationWith1CDocumentManagement3ServerCall.GetHTMLPreviewOfObjectAsynchronously(
			UUID,
			RelationshipTreeCurrentData.LinkedObjectID,
			RelationshipTreeCurrentData.LinkedObjectType,
			IgnoreMaxSize,
			ObjectForGettingPersonalData,
			ReturnBinaryData);
		
		CallbackOnCompletion = New CallbackDescription(
			"UpdateLinkPreviewCompletion",
			ThisObject,
			RelationshipTreeCurrentData);
		
		IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
			ThisObject,
			TimeConsumingOperation,
			CallbackOnCompletion,
			False,,
			False);
		
		Return;
		
	EndIf;
	
	If Not RelationshipTreeCurrentData.EditedByCurUser
			And RelationshipTreeCurrentData.PreviewCut Then
		Items.GroupPreviewCut.Visible = True;
	EndIf;
	
	If ValueIsFilled(RelationshipTreeCurrentData.PresentationHTML) Then
		HTMLLinkPresentation = RelationshipTreeCurrentData.PresentationHTML;
	ElsIf ThereIsPreviewFile Then
		If RelationshipTreeCurrentData.EditedByCurUser Then
			HTMLLinkPresentation = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutEditing(
				TitleOfMessageInPreviewArea);
		Else
			PDFDocument = IntegrationWith1CDocumentManagementCoreServerCall.GetPDFDocument(
				RelationshipTreeCurrentData.AddressInPreviewFileStorage);
			If PDFDocument = Undefined Then
				HTMLLinkPresentation = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
					TitleOfMessageInPreviewArea);
			Else
				ThisObject["PDFDocumentAttributes"] = PDFDocument;
				Items.ViewPages.CurrentPage = Items.PageGroupPDF;
				Items["DocumentPDFField"].CurrentPageNumber = 1;
			EndIf;
		EndIf;
	Else
		HTMLLinkPresentation = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
			TitleOfMessageInPreviewArea);
	EndIf;
	
EndProcedure

// Called after getting a preview of the object BEFORE.
//
// Parameters:
//   Result - See TimeConsumingOperations.ActionCompleted
//   NotificationParameters - See IntegrationWith1CDocumentManagementCoreClientServer.FileData
//
&AtClient
Procedure UpdateLinkPreviewCompletion(Result, NotificationParameters) Export
	
	HTMLObjectPreview =
		IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview();
	
	If Result <> Undefined And Result.Status = "Error" Then
		HTMLMessage =
			IntegrationWith1CDocumentManagementCoreClientServer.PreviewMessage(
				Result.BriefErrorDescription,
				TitleOfMessageInPreviewArea);
		HTMLObjectPreview.ID = NotificationParameters.LinkedObjectID;
		HTMLObjectPreview.Type = NotificationParameters.LinkedObjectType;
		HTMLObjectPreview.Extension = NotificationParameters.FileExtention;
		HTMLObjectPreview.PresentationHTML = HTMLMessage;
		Notify("HTMLObjectPreviewReceived", HTMLObjectPreview, ThisObject);
	EndIf;
	
	ProcessAForm = False;
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		IntegrationWith1CDocumentManagementCoreClientServer.AddPersonalData(HTMLObjectPreview);
		FillPropertyValues(HTMLObjectPreview, Result.ResultLongOperation);
		HTMLObjectPreview.ID = NotificationParameters.LinkedObjectID;
		HTMLObjectPreview.Type = NotificationParameters.LinkedObjectType;
		HTMLObjectPreview.Extension = NotificationParameters.FileExtention;
		If IsBlankString(HTMLObjectPreview.PresentationHTML) Then
			HTMLObjectPreview.PresentationHTML =
				IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
					TitleOfMessageInPreviewArea);
		EndIf;
		Notify("HTMLObjectPreviewReceived", HTMLObjectPreview, ThisObject);
	ElsIf ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdatePreviewOfWaitHandlerConnection()
	
	UpdateLinkPreview();
	
EndProcedure

// Handler for the "GETTHTML Object view" event.
//
// Parameters:
//   Parameter - See IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview
//   Source - Arbitrary - event source.
//
&AtClient
Procedure ProcessHTMLPreviewReceiptEvent(Parameter, Source)
	
	String = IntegrationWith1CDocumentManagement3ClientServer.LinkByID(
		LinkTree.GetItems(),
		Parameter.ID,
		Parameter.Type);
	If String <> Undefined Then
		String.WaitingForPreview = False;
		If TypeOf(Parameter.BinaryData) = Type("BinaryData") And Lower(Parameter.Extension) = "pdf" Then
			String.PresentationHTML = "";
			String.PreviewCut = False;
			String.AddressInPreviewFileStorage = PutToTempStorage(
				Parameter.BinaryData,
				UUID);
		Else
			String.PresentationHTML = Parameter.PresentationHTML;
			String.PreviewCut = Parameter.PreviewCut;
		EndIf;
		UpdateLinkPreview();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenCurFileForEditing(RelationshipTreeCurrentData)
	
	If RelationshipTreeCurrentData = Undefined Or RelationshipTreeCurrentData.LinkedObjectType <> "DMFile" Then
		Return;
	EndIf;
	
	OwnerID = Undefined;
	DocumentLine = IntegrationWith1CDocumentManagement3ClientServer.DocumentStringInLinkTree(RelationshipTreeCurrentData);
	If DocumentLine <> Undefined Then
		OwnerID = DocumentLine.LinkedObjectID;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenFile(
		RelationshipTreeCurrentData.LinkedObjectID,
		RelationshipTreeCurrentData.LinkedObject,
		RelationshipTreeCurrentData.FileExtention,
		UUID,
		False,,
		OwnerID);
	
EndProcedure

&AtClient
Procedure OpenCurFileForReading(RelationshipTreeCurrentData)
	
	If RelationshipTreeCurrentData = Undefined Or RelationshipTreeCurrentData.LinkedObjectType <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenFile(
		RelationshipTreeCurrentData.LinkedObjectID,
		RelationshipTreeCurrentData.LinkedObject,
		RelationshipTreeCurrentData.FileExtention,
		UUID);
	
EndProcedure

#EndRegion

#Region Connection

// Checks the connection to the DO by displaying the authorization window, if necessary, and changing the form according to the result.
//
&AtClient
Procedure TestConnection()
	
	CallbackDescription = New CallbackDescription("TestConnectionCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.TestConnection(
		CallbackDescription,
		ThisObject,,
		False,
		True);
	
EndProcedure

&AtClient
Procedure TestConnectionCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		WhenConnecting();
	Else // Couldn't connect to BEFORE.
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenConnecting()
	
	If ProcessFormAccordingToServiceVersion() Then
		OnlyImportantConnections = True;
		ShowOnlyOriginalsInLinks = False;
		Items.LinkTreeShowAllLinks.Enabled = True;
		Items.InfoCommunicationGroup.Visible = True;
		
		StartUpdatingForm(False, True);
	EndIf;
	
EndProcedure

&AtServer
Function ProcessFormAccordingToServiceVersion()
	
	ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
	If Not IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsUnavailable;
		Return False;
	EndIf;
	
	FormProcessedSuccessfully = True;
	
	Try
		
		CreatingLinksIsAvailable = IntegrationWith1CDocumentManagement3.CreatingLinksIsAvailable();
		
		If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.17.36") Then
			
			Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
			
			If (IntegrationWith1CDocumentManagement3.IsDocumentBefore3(ObjectBeforeType) Or ObjectBeforeType = "DMMeeting")
					And StringFunctionsClientServer.IsUUID(ObjectBeforeID) Then
				
				Items.GroupOfPageForReceivingCommunicationData.CurrentPage = Items.PageDataReceivedLinks;
				
				If Not CreatingLinksIsAvailable Then
					Items.LinkTreeAdd.Visible = False;
					Items.LinkTreeContextMenuAdd.Visible = False;
					Items.LinkTreeContextMenuDelete.Visible = False;
				EndIf;
				
				SettingsOf1CDocumentManagement = IntegrationWith1CDocumentManagementCoreCached.GetSettings();
				TitleOfMessageInPreviewArea = SettingsOf1CDocumentManagement.TitleOfMessageInPreviewArea;
				
				ShowPDFUsing1C = SettingsOf1CDocumentManagement.ShowPDFUsing1C;
				If ShowPDFUsing1C Then
					IntegrationWith1CDocumentManagement3.OutputPDFDocumentToForm(ThisObject, "PageGroupPDF");
				EndIf;
				
			Else
				
				Items.GroupOfPageForReceivingCommunicationData.CurrentPage = Items.LinksPageIsUnavailable;
				FormProcessedSuccessfully = False;
				
			EndIf;
			
		Else
			
			Items.ConnectionPageGroup.CurrentPage = Items.VersionPageIsNotSupported;
			FormProcessedSuccessfully = False;
			
		EndIf;
		
	Except
		
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo()) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		
	EndTry;
	
	Return FormProcessedSuccessfully;
	
EndFunction

#EndRegion

#Region UpdateForm

&AtClient
Procedure StartUpdatingForm(OutputIdleWindow = True, HideInterface = False)
	
	If TreeOfLinksIsExpandedString = 0 Then
		HTMLLinkPresentation =
			IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
				TitleOfMessageInPreviewArea);
		ReadLinks = 0;
		TotalConnections = 0;
	EndIf;
	
	TimeConsumingOperation = UpdateForm();
	
	NotificationParameters = New Structure("OutputIdleWindow",
		OutputIdleWindow);
	CallbackOnCompletion = New CallbackDescription(
		"UpdatingFormEnd",
		ThisObject,
		NotificationParameters);
	
	IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
		ThisObject,
		TimeConsumingOperation,
		CallbackOnCompletion,
		OutputIdleWindow,
		NStr("vi = 'Nhận dữ liệu từ 1C:Document Management.';
			|ru = 'Получение данных из 1С:Документооборота.';
			|en = 'Get data from 1C:Document Management.'; fa = 'Get data from 1C:Document Management.';
			|it = 'Получение данных из 1С:Документооборота.';
			|pl = 'Get data from 1C:Document Management.';
			|tr = '1C:Document Management üzerinden verilerin alınması.'"),
		HideInterface);
	
EndProcedure

&AtServer
Function UpdateForm()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = Undefined;
	
	If TreeOfLinksIsExpandedString <> 0 Then
		LinkTreeString = LinkTree.FindByID(TreeOfLinksIsExpandedString).GetParent();
		ObjectAttributes =
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				LinkTreeString.LinkedObjectID, LinkTreeString.LinkedObjectType);
	Else
		ObjectAttributes =
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				ObjectBeforeID, ObjectBeforeType);
	EndIf;
	Query = IntegrationWith1CDocumentManagement3.ConnectionsOfRequestObject(Proxy, ObjectAttributes);
	
	If Query <> Undefined Then
		Return IntegrationWith1CDocumentManagementCore.ExecuteRequestAsynchronously(
			Proxy,
			Query,
			UUID,
			NStr("vi = 'Nhận dữ liệu từ 1C:Document Management.';
				|ru = 'Получение данных из 1С:Документооборота';
				|en = 'Get data from 1C:Document Management'; fa = 'Get data from 1C:Document Management';
				|it = 'Получение данных из 1С:Документооборота';
				|pl = 'Get data from 1C:Document Management';
				|tr = '1C:Document Management üzerinden verilerin alınması'"));
	EndIf;
	
EndFunction

&AtClient
Procedure UpdatingFormEnd(Result, NotificationParameters) Export
	
	ProcessAForm = False;
	IntegrationWith1CDocumentManagementCoreClient.CheckForErrorsWhenUpdatingForm(
		ThisObject,
		Result,
		ProcessAForm);
	If ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		UpdateFormCompletion(Result.ResultLongOperation, NotificationParameters);
		IntegrationWith1CDocumentManagement3Client.ExpandLinkTreeLevel(
			TreeOfLinksIsExpandedString,
			LinkTree,
			Items.LinkTree);
		TreeOfLinksIsExpandedString = 0;
	ElsIf ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateFormCompletion(Val Response_String, Val NotificationParameters)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Response = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(Proxy, Response_String);
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMError") Then
		TextOfUpdateError = Response.description;
		Items.ConnectionPageGroup.CurrentPage = Items.PageUpdateError;
	Else
		IntegrationWith1CDocumentManagement3.FillInLinkTreeInForm(ThisObject, Response);
		If Not NotificationParameters.OutputIdleWindow Then
			Items.GroupOfPageForReceivingCommunicationData.CurrentPage = Items.PageDataReceivedLinks;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion