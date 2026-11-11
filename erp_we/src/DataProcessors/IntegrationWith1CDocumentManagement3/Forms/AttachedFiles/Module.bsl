#Region Variables

&AtClient
Var LinesForDisclosure;

&AtClient
Var CurRowId_;

&AtClient
Var CurCurrentStringType;

&AtClient
Var FileTreeStringKey;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("FileOwner", Owner);
	Parameters.Property("FileOwnerID", ID);
	Parameters.Property("FileOwnerType", Type);
	Parameters.Property("OwnerPresentation", OwnerPresentation);
	Parameters.Property("CurrentFile", CurrentFile);
	
	HasOwner = ValueIsFilled(Owner);
	
	// We will show the owner when opening the file from the card.
	Items.FileOwner.Visible = ValueIsFilled(CurrentFile) And HasOwner;
	
	If Parameters.Property("FormCaption") Then
		Title = Parameters.FormCaption;
		TitleIsSet = True;
	ElsIf HasOwner Then
		Title = StrTemplate("%1: %2", Title, Owner);
	EndIf;
	
	IntegrationRule = Undefined;
	If Parameters.Property("IntegrationRule") And Parameters.IntegrationRule <> Undefined Then
		IntegrationRule = Parameters.IntegrationRule;
	ElsIf HasOwner Then
		Rules = IntegrationWith1CDocumentManagementCoreServerCall.FindCreateAppropriateRules(
			Owner);
		If Rules.Count() > 0 Then
			IntegrationRule = Rules[0];
		EndIf;
	EndIf;
	
	If IntegrationRule <> Undefined Then
		Type = IntegrationRule.ObjectTypeDM;
		TypeOfDocumentType = IntegrationRule.TypeOfDocumentType;
		IDOfDocumentType = IntegrationRule.IDOfDocumentType;
	EndIf;
	
	If Not HasOwner And IntegrationRule = Undefined And ID = "" And Type = "" Then
		Enabled = False;
	EndIf;
	
	UseDigitalSignatureIS =
		IntegrationWith1CDocumentManagementCoreServerCall.UseElectronicDigitalSignatures();
	
	If Parameters.Property("SimpleForm") Then
		Items.OpenForEditing.OnlyInAllActions = True;
		Items.OpenForReading.OnlyInAllActions = True;
		Items.EndEdit.OnlyInAllActions = True;
	EndIf;
	
	FileCatalogType = "Undefined";
	OwnerTypePresentation = "object_";
	If HasOwner Then
		Owner_Metadata = Owner.Metadata();
		FileCatalogType = Owner_Metadata.FullName();
		ObjectTypeArray = StrSplit(FileCatalogType, ".");
		If ObjectTypeArray[0] = "Catalog" Then
			OwnerTypePresentation = "catalog_";
		ElsIf ObjectTypeArray[0] = "Document" Then
			OwnerTypePresentation = "document_";
		EndIf;
	EndIf;
	
	AbbreviatedNameOfConfiguration =
		IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	
	SendingViaIPIsAvailable = Common.SubsystemExists("StandardSubsystems.EmailOperations");
	
	PreviewStorage = Common.CommonSettingsStorageLoad(
		FileCatalogType,
		"PreviewBIDFiles");
	If PreviewStorage = Undefined Then
		Preview = True;
	Else
		Preview = PreviewStorage;
	EndIf;
	
	Items.SwitchPreview.Check = Preview;
	Items.ViewPages.Visible = Preview;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ObjectDMFromFormData(FormOwner);
	If ValueIsFilled(ObjectBefore.ID) And ValueIsFilled(ObjectBefore.Type) Then
		ID = ObjectBefore.ID;
		Type = ObjectBefore.Type;
	EndIf;
	
	If Not TitleIsSet Then
		IntegrationWith1CDocumentManagementCoreClient.SetTitleWhenOpening(ThisObject);
	EndIf;
	
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
	
	If Not ValueIsFilled(ID) Then
		FillInIDByOwner();
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
				Or Not Parameter.Property("FormUniqueID")
				Or Not Parameter.FileOperation.InformFileListForm
				Or ID = ""
				Or Parameter.FileOwner <> ID
				Or (Parameter.FileOperation.DeleteFile
					And UUID = Parameter.FormUniqueID) Then
			Return;
		EndIf;
		NeedUpdate = True;
		If Parameter.FileOperation.EditingFile Then
			String = IntegrationWith1CDocumentManagement3Client.FileTreeStringByID(
				FilesTree,
				UseFileRoles,
				Parameter.FileID,
				"DMFile");
			If String = Undefined Then
				NeedUpdate = False;
			Else
				NeedUpdate = Not String.IsBeingEdited;
			EndIf;
		EndIf;
		If NeedUpdate Then
			If Parameter.FormUniqueID = Undefined Then
				OutputIdleWindow = (Source = ThisObject);
			Else
				OutputIdleWindow = (UUID = Parameter.FormUniqueID);
			EndIf;
			UpdateFileListClient(Parameter.FileID, OutputIdleWindow);
		EndIf;
		
	ElsIf EventName = "DocumentManagement_AddingALink" Then
		If TypeOf(Parameter) <> Type("Structure")
				Or Not Parameter.Property("ID")
				Or Not Parameter.Property("Type")
				Or Not Parameter.Property("Object")
				Or Not Parameter.Property("FormUniqueID")
				Or Parameter.ID <> ID
				Or Parameter.Type <> Type
				Or UUID = Parameter.FormUniqueID Then
			Return;
		EndIf;
		ParametersOfUpdate = FilesUpdateParameters();
		ParametersOfUpdate.OnOpen = True;
		ParametersOfUpdate.AskQuestionAboutFileTransfer = False;
		StartUpdatingFiles(ParametersOfUpdate);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AuthorizationSettingsDecorationClick(Item)
	
	Notification = New CallbackDescription("AuthorizationSettingsDecorationClickCompletion", ThisObject);
	NameOfParameterForm = "DataProcessor.IntegrationWith1CDocumentManagementCore.Form.AuthorizationIn1CDocumentManagement";
	
	OpenForm(NameOfParameterForm,, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AuthorizationSettingsDecorationClickCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		WhenConnecting();
	EndIf;
	
EndProcedure

&AtClient
Procedure PresentationHTMLOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	If Not ValueIsFilled(EventData.Href) Then
		Return;
	EndIf;
	
	If StrFind(EventData.Href, "OpenForEdit") Then
		
		OpenCurFileForEditing();
		
	ElsIf StrFind(EventData.Href, "OpenForView") Then
		
		OpenCurFileForReading();
		
	ElsIf StrFind(EventData.Href, "CreatePreview") Then
		
		UpdatePreview1(True, True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFilesTree

&AtClient
Procedure FilesTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenCurFileForReading();
	
EndProcedure

&AtClient
Procedure FilesTreeBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	OpenCard();
	
EndProcedure

&AtClient
Procedure FilesTreeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	If Copy Then
		CurrentData = Items.FilesTree.CurrentData;
		If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
			Return;
		EndIf;
		AddByCopying(Items.FilesTree.CurrentData.ID);
	Else
		AddFromDisk(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure FilesTreeBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("AfterDeletingFiles", ThisObject);
	
	Selected_Files = IntegrationWith1CDocumentManagementCoreClient.Selected_Files(
		FilesTree,
		Items.FilesTree.SelectedRows);
	IntegrationWith1CDocumentManagementCoreClient.MarkForDeletionUncheckFiles(
		Selected_Files,
		CurrentData.DeletionMark,
		Notification,
		ID,
		UUID);
	
EndProcedure

&AtClient
Procedure FilesTreeOnActivateRow(Item)
	
	If Item.CurrentRow = Undefined Or Item.CurrentRow = FileTreeStringKey Then
		Return;
	EndIf;
	FileTreeStringKey = Item.CurrentRow;
	
	SetAvailabilityOfFileListCommands();
	
	PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.DownloadMessage();
	Items.ViewPages.CurrentPage = Items.HTMLGroupPage;
	Items.GroupPreviewCut.Visible = False;
	AttachIdleHandler("UpdateFilePreview", 0.2, True);
	
EndProcedure

&AtClient
Procedure FilesTreeDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	DragParameters.Action = DragAction.Cancel;
	
	FilesArray = IntegrationWith1CDocumentManagement3Client.ArrayOfFilesFromDragAndDropOptions(
		FilesTree,
		DragParameters.Value);
	If FilesArray.Count() = 0 Then
		Return;
	EndIf;
	
	If UseFileRoles Then
		NewRoleOfIDFile = IntegrationWith1CDocumentManagement3Client.CurCurrentFileRole(FilesTree, String);
	Else
		NewRoleOfIDFile = "";
	EndIf;
	
	For Each FileToDrag In FilesArray Do
		If TypeOf(FileToDrag) = Type("Structure")
				And (NewRoleOfIDFile = "" Or FileToDrag.FileRoleID = NewRoleOfIDFile) Then
			Return;
		EndIf;
	EndDo;
	
	DragParameters.Action = DragAction.Move;
	
EndProcedure

&AtClient
Procedure FilesTreeDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If UseFileRoles Then
		FileRoleID = IntegrationWith1CDocumentManagement3Client.CurCurrentFileRole(
			FilesTree, String);
	Else
		FileRoleID = "";
	EndIf;
	
	FilesArray = IntegrationWith1CDocumentManagement3Client.ArrayOfFilesFromDragAndDropOptions(
		FilesTree,
		DragParameters.Value);
	If FilesArray.Count() = 0 Then
		Return;
	EndIf;
	
	If TypeOf(FilesArray[0]) = Type("Structure") Then
		IntegrationWith1CDocumentManagement3Client.ReplaceRoleOfFiles(
			FilesArray,
			FileRoleID,
			ID,
			UUID);
	ElsIf TypeOf(FilesArray[0]) = Type("File") Then
		NotificationParameters = New Structure("FilesArray, FileRoleID", FilesArray, FileRoleID);
		CallbackDescription = New CallbackDescription("FilesDragCompletion", ThisObject, NotificationParameters);
		If ValueIsFilled(ID) Then
			RunCallback(CallbackDescription, Undefined);
		Else
			IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
				Owner,
				CallbackDescription,,,
				False);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Async Procedure FilesDragCompletion(Val Result, Val NotificationParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		// The owner of the file on the DO side could have been created directly at the time of dragging.
		// In this case, the data of the created object BEFORE will be contained in the "Result" structure.
		ID = Result.ID;
		Type = Result.type;
	EndIf;
	If Not ValueIsFilled(ID) Then
		Return;
	EndIf;
	
	YouNeedToAddScannedCopy =
		Await IntegrationWith1CDocumentManagementCoreClient.YouNeedToAddScannedCopyAsync(
			StateAllowsAddingScannedCopy,
			StateAllowsFileAddition);
	
	If YouNeedToAddScannedCopy = DialogReturnCode.Yes Then
		ParametersForStartOfCreation = FileCreationStartParameters();
		ParametersForStartOfCreation.CurrentFile.FileRoleID = NotificationParameters.FileRoleID;
		IntegrationWith1CDocumentManagementCoreClient.CreateFileFromDiskByDraggingAndDropping(
			NotificationParameters.FilesArray,
			ParametersForStartOfCreation);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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
Procedure PDFDocumentLeftTurn(Command)
	
	Items["DocumentPDFField"].Orientation = Items["DocumentPDFField"].Orientation - 90;
	
EndProcedure

&AtClient
Procedure PDFDocumentTurnRight(Command)
	
	Items["DocumentPDFField"].Orientation = Items["DocumentPDFField"].Orientation + 90;
	
EndProcedure

&AtClient
Procedure ChooseFileRole(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("FilesOwner", ID);
	FormParameters.Insert("AvailableRoles", AvailableRoles);
	FormParameters.Insert("IdOfOwnerSForm", UUID);
	FormParameters.Insert("UseFileRoles", UseFileRoles);
	
	IntegrationWith1CDocumentManagement3Client.ChooseFileRole(FilesTree, Items.FilesTree, FormParameters);
	
EndProcedure

&AtClient
Procedure AddFromDisk(Command)
	
	CallbackDescription = New CallbackDescription("AddFromDiskCompletion", ThisObject);
	If ValueIsFilled(ID) Then // The associated object is already known.
		RunCallback(CallbackDescription, Undefined);
	Else // The linked object should be found or created.
		IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
			Owner,
			CallbackDescription,,,
			False);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddPrintedForm(Command)
	
	CallbackDescription = New CallbackDescription("AddPrintedFormCompletion", ThisObject);
	If ValueIsFilled(ID) Then // The associated object is already known.
		RunCallback(CallbackDescription, Undefined);
	Else // The linked object should be found or created.
		IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
			Owner,
			CallbackDescription,,,
			False);
	EndIf;
	
EndProcedure

&AtClient
Procedure TransferFilesAndSvTOCommand(Command)
	
	TransferFilesAndSvTO();
	
EndProcedure

&AtClient
Procedure OpenForReading(Command)
	
	OpenCurFileForReading();
	
EndProcedure

&AtClient
Procedure OpenForEditing(Command)
	
	OpenCurFileForEditing();
	
EndProcedure

&AtClient
Procedure EndEdit(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.EndFileEditing(
		CurrentData.ID,
		CurrentData.Description,
		CurrentData.Extension,
		UUID,,
		ID);
	
EndProcedure

&AtClient
Procedure SaveToDisk(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.StartSavingSelectedFiles(
		FilesTree,
		Items.FilesTree.SelectedRows,
		UUID);
	
EndProcedure

&AtClient
Procedure UpdateFromFileOnHardDrive(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.UpdateFromFileOnHardDrive(
		CurrentData.ID,
		CurrentData.Description,
		CurrentData.Extension,
		CurrentData.ModificationDate,
		UUID,,
		ID);
	
EndProcedure

&AtClient
Procedure UpdatePreviewCommand(Command)
	
	UpdatePreview1(True);
	
EndProcedure

&AtClient
Procedure CancelEdit(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.UndoFileEditing(
		CurrentData.ID,,
		ID,
		UUID);
	
EndProcedure

&AtClient
Procedure OpenFileDirectory(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenFileDirectory(CurrentData.ID);
	
EndProcedure

&AtClient
Procedure SaveChanges(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.SaveChangesToEditedFile(
		CurrentData.ID,
		CurrentData.Description,
		CurrentData.Extension,
		UUID,,
		ID);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	If Not ValueIsFilled(ID) Then
		FillInIDByOwner();
	EndIf;
	
	UpdateFileListClient();
	
EndProcedure

&AtClient
Procedure ShowDeleted(Command)
	
	ShowDeleted = Not ShowDeleted;
	Items.ShowDeleted.Check = ShowDeleted;
	
	UpdateFileListClient();
	
EndProcedure

&AtClient
Procedure SwitchPreview(Command)
	
	Preview = Not Preview;
	Items.SwitchPreview.Check = Preview;
	Items.ViewPages.Visible = Preview;
	CommonServerCall.CommonSettingsStorageSave(
		FileCatalogType,
		"PreviewBIDFiles",
		Preview);
	UpdatePreview1();
	
EndProcedure

&AtClient
Procedure Print(Command)
	
#If WebClient Then
	ShowMessageBox(,NStr("vi = 'Trên Web-client không hỗ trợ in tệp.';
						|ru = 'В Веб-клиенте печать файлов не поддерживается.';
						|en = 'Printing of files is not supported in the web client.'; fa = 'Printing of files is not supported in the web client.';
						|it = 'Non è supportata la stampa di file nel client web.';
						|pl = 'W kliencie webowym drukowanie plików nie jest obsługiwane.';
						|tr = 'Web istemcisi, dosyaların yazdırılmasını desteklemez.'"));
	Return;
#EndIf
	
	IntegrationWith1CDocumentManagementCoreClient.PrintFiles(
		FilesTree,
		Items.FilesTree.SelectedRows,
		UUID);
	
EndProcedure

&AtClient
Procedure Send(Command)
	
	SendViaIS();
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////////////////////////
// Files (EP)

&AtClient
Procedure SignFile(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(
		Signatures,,
		CurrentData.ID);
	
	FileProperties = IntegrationWith1CDocumentManagementCoreClientServer.FileProperties();
	FileProperties.FileID = CurrentData.ID;
	FileProperties.FileName = CurrentData.Description;
	FileProperties.FileOwner = ID;
	FileProperties.IsBeingEdited = CurrentData.IsBeingEdited;
	FileProperties.Encrypted = CurrentData.Encrypted;
	FileProperties.FileDetails = CurrentData.LongDesc;
	FileProperties.FormUniqueID = UUID;
	FileProperties.FileSignatureData =
		IntegrationWith1CDocumentManagementCoreClient.DataOfSignatures(SignatureTable);
	
	IntegrationWith1CDocumentManagementCoreClient.SignFile(FileProperties);
	
EndProcedure

&AtClient
Procedure AddDSFromFile(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	FileID = CurrentData.ID;
	SignatureTable = IntegrationWith1CDocumentManagementCoreClientServer.SignatureTable(
		Signatures,,
		FileID);
	FileSignatureData = IntegrationWith1CDocumentManagementCoreClient.DataOfSignatures(SignatureTable);
	
	FileProperties = IntegrationWith1CDocumentManagementCoreClientServer.FileProperties();
	FileProperties.FileID = FileID;
	FileProperties.FileName = CurrentData.Description;
	FileProperties.FileDetails = CurrentData.LongDesc;
	FileProperties.IsBeingEdited = CurrentData.IsBeingEdited;
	FileProperties.Encrypted = CurrentData.Encrypted;
	FileProperties.FileSignatureData = FileSignatureData;
	FileProperties.FormUniqueID = UUID;
	FileProperties.FileOwner = ID;
	
	IntegrationWith1CDocumentManagementCoreClient.StartAddingItemsFromFile(FileProperties);
	
EndProcedure

&AtClient
Procedure SaveFileTogetherBOT(Command)
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.StartSavingTogetherBOT(
		CurrentData.ID,
		CurrentData.Extension,
		CurrentData.Description,
		CurrentData.Size * 1024,
		CurrentData.ModificationDate,
		UUID);
	
EndProcedure

#EndRegion

#Region Private

#Region Client

&AtClient
Procedure RestorePositionInList()
	
	// Open the tree.
	For Each LineToDisclosure In LinesForDisclosure Do
		String = IntegrationWith1CDocumentManagement3Client.FileTreeStringByID(
			FilesTree,
			UseFileRoles,
			LineToDisclosure);
		If String <> Undefined Then
			Items.FilesTree.Expand(String.GetID(), True);
		EndIf;
	EndDo;
	
	CurLineIsSet = False;
	
	// if the Cur row id is passed, we will set the Cur row to it.
	If ValueIsFilled(CurRowId_) Then
		String = IntegrationWith1CDocumentManagement3Client.FileTreeStringByID(
			FilesTree,
			UseFileRoles,
			CurRowId_,
			CurCurrentStringType);
		If String <> Undefined Then
			Items.FilesTree.CurrentRow = String.GetID();
			CurLineIsSet = True;
		EndIf;
	EndIf;
	
	// if the Cur line id is not passed, we will set the first line with the html representation of the file to the Cur one.
	If Not CurLineIsSet Then
		
		For Each String In FilesTree.GetItems() Do
			
			If UseFileRoles Then
				For Each FileRow In String.GetItems() Do
					If ValueIsFilled(FileRow.PresentationHTML) Then
						Items.FilesTree.CurrentRow = FileRow.GetID();
						CurLineIsSet = True;
						Break;
					EndIf;
				EndDo;
			Else
				If ValueIsFilled(String.PresentationHTML) Then
					Items.FilesTree.CurrentRow = String.GetID();
					CurLineIsSet = True;
				EndIf;
			EndIf;
			
			If CurLineIsSet Then
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	// If there are no files with HTML Presentation, set the line to the first file.
	If Not CurLineIsSet Then
		LineToDisclosure = Undefined;
		If LinesForDisclosure.Count() > 0 Then
			LineToDisclosure = IntegrationWith1CDocumentManagement3Client.FileTreeStringByID(
				FilesTree,
				UseFileRoles,
				LinesForDisclosure[0]);
		EndIf;
		For Each String In FilesTree.GetItems() Do
			If String.Type = "DMFile" Then
				// File roles are not used, set the line to the first file.
				Items.FilesTree.CurrentRow = String.GetID();
				CurLineIsSet = True;
				Break;
			EndIf;
			For Each FileRow In String.GetItems() Do
				If FileRow.Type = "DMFile"
						And (LineToDisclosure = Undefined Or FileRow.FileRoleID = LineToDisclosure.ID) Then
					Items.FilesTree.CurrentRow = FileRow.GetID();
					CurLineIsSet = True;
					Break;
				EndIf;
			EndDo;
			If CurLineIsSet Then
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	// If there are no files, set the line to the first mandatory role of the files.
	If Not CurLineIsSet And LinesForDisclosure.Count() > 0 Then
		LineToDisclosure = IntegrationWith1CDocumentManagement3Client.FileTreeStringByID(
			FilesTree,
			UseFileRoles,
			LinesForDisclosure[0]);
		If LineToDisclosure <> Undefined Then
			Items.FilesTree.CurrentRow = LineToDisclosure.GetID();
			CurLineIsSet = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AddByCopying(OriginalID)
	
	IntegrationWith1CDocumentManagementCoreClient.CreateFileByCopying(OriginalID);
	
EndProcedure

// Continues adding the owner's printed form.
//
&AtClient
Procedure AddPrintedFormCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ID = Result.ID;
		Type = Result.type;
	EndIf;
	If Not ValueIsFilled(ID) Then
		Return;
	EndIf;
	
	If UseFileRoles Then
		FileRoleID = IntegrationWith1CDocumentManagement3Client.CurCurrentFileRole(
			FilesTree,
			Items.FilesTree.CurrentRow);
	Else
		FileRoleID = "";
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectIS", Owner);
	FormParameters.Insert("ObjectIDDM", ID);
	FormParameters.Insert("ObjectTypeDM", Type);
	FormParameters.Insert("FileRoleID", FileRoleID);
	FormParameters.Insert("UniqueOwnerID", UUID);
	AdditionForm = OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.InsertPrintForm",
		FormParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockWholeInterface);
	If AdditionForm = Undefined Then
		ObjectTypeArray = StrSplit(FileCatalogType, ".");
		WarningText = StrTemplate(NStr("ru = '%1 ""%2"" не имеет печатных форм.';
										|vi = '%1 ""%2"" has no print forms.';
										|en = '%1 ""%2"" has no print forms.'; fa = '%1 ""%2"" has no print forms.';
										|it = '%1 ""%2"" has no print forms.';
										|pl = '%1 ""%2"" has no print forms.';
										|tr = '%1 ""%2"" yazdırılabilir formları mevcut değil.'"),
			ObjectTypeArray[0],
			String(Owner));
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

// Completes adding a file from disk and updates the form.
//
&AtClient
Async Procedure AddFromDiskCompletion(Val Result, Val AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ID = Result.ID;
		Type = Result.type;
	EndIf;
	If Not ValueIsFilled(ID) Then
		Return;
	EndIf;
	
	YouNeedToAddScannedCopy =
		Await IntegrationWith1CDocumentManagementCoreClient.YouNeedToAddScannedCopyAsync(
			StateAllowsAddingScannedCopy,
			StateAllowsFileAddition);
	
	If YouNeedToAddScannedCopy = DialogReturnCode.Yes Then
		ParametersForStartOfCreation = FileCreationStartParameters();
		If UseFileRoles Then
			ParametersForStartOfCreation.CurrentFile.FileRoleID = IntegrationWith1CDocumentManagement3Client.CurCurrentFileRole(
				FilesTree,
				Items.FilesTree.CurrentRow);
		EndIf;
		IntegrationWith1CDocumentManagementCoreClient.CreateFileFromDisk(ParametersForStartOfCreation);
	EndIf;
	
EndProcedure

&AtClient
Procedure StartUpdatingFiles(ParametersOfUpdate)
	
	UpdateCompletedSuccessfully = False;
	Items.AddGroup.Enabled = False;
	Items.ListContextMenuCommandsGroupAdd.Enabled = False;
	RemoveAvailabilityOfCommands();
	PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.DownloadMessage();
	
	CallbackOnCompletion = New CallbackDescription("FileUpdateEnd", ThisObject, ParametersOfUpdate);
	MessageText = NStr("vi = 'Nhận danh sách tệp từ 1C:Document Management.';
						|ru = 'Получение списка файлов из 1С:Документооборот.';
						|en = 'Get a file list from 1C:Document Management.'; fa = 'Get a file list from 1C:Document Management.';
						|it = 'Получение списка файлов из 1С:Документооборот.';
						|pl = 'Get a file list from 1C:Document Management.';
						|tr = '1C:Document Management''ten dosya listesi alımı.'");
	
	FieldsReceived = New Array;
	
	If ValueIsFilled(ID) Then
		
		FieldsReceived.Add("files");
		If Preview Then
			If ShowPDFUsing1C Then
				FieldsReceived.Add("binaryData");
			EndIf;
			FieldsReceived.Add("htmlView");
		EndIf;
		If IntegrationWith1CDocumentManagement3ClientCached.IsDocumentBefore3(Type) Then
			FieldsReceived.Add("documentType");
			FieldsReceived.Add("enabledProperties");
		EndIf;
		If ShowDeleted Then
			FieldsReceived.Add("ignoreDeletionMark");
		EndIf;
		
		TimeConsumingOperation = IntegrationWith1CDocumentManagementCoreServerCall.GetObjectAsynchronously(
			UUID,
			Type,
			ID,
			FieldsReceived,,
			?(HasOwner, Owner, Undefined));
		
		IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
			ThisObject,
			TimeConsumingOperation,
			CallbackOnCompletion,
			ParametersOfUpdate.OutputIdleWindow,
			MessageText,
			ParametersOfUpdate.HideInterface);
		
	ElsIf IntegrationWith1CDocumentManagement3ClientCached.IsDocumentBefore3(Type)
			And ValueIsFilled(TypeOfDocumentType) And ValueIsFilled(IDOfDocumentType) Then
		
		FieldsReceived.Add("roles");
		
		TimeConsumingOperation = IntegrationWith1CDocumentManagementCoreServerCall.GetObjectAsynchronously(
			UUID,
			TypeOfDocumentType,
			IDOfDocumentType,
			FieldsReceived);
		
		IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
			ThisObject,
			TimeConsumingOperation,
			CallbackOnCompletion,
			ParametersOfUpdate.OutputIdleWindow,
			MessageText,
			ParametersOfUpdate.HideInterface);
		
	Else
		
		Result = New Structure;
		If ValueIsFilled(Type) Then
			Result.Insert("Status", "Completed2");
			Result.Insert("ResultLongOperation", New Structure("Type", Type));
		Else
			If ValueIsFilled(OwnerPresentation) Then
				ErrorText = StrTemplate(
					NStr("vi = 'Xem danh sách tệp đối tượng ""%1"" được phép chỉ ở bên 1C:Document Management.';
						|ru = 'Просмотр списка файлов объекта ""%1"" доступен только на стороне 1С:Документооборот.';
						|en = 'You can only preview the file list of the ""%1"" object in 1C:Document Management.'; fa = 'You can only preview the file list of the ""%1"" object in 1C:Document Management.';
						|it = 'Просмотр списка файлов объекта ""%1"" доступен только на стороне 1С:Документооборот.';
						|pl = 'You can only preview the file list of the ""%1"" object in 1C:Document Management.';
						|tr = '""%1"" nesnesinin dosya listesini görüntülemek sadece 1C:Document Management tarafında mümkündür.'"),
					OwnerPresentation);
			Else
				ErrorText = NStr("vi = 'Đối tượng tệp không hỗ trợ tích hợp liền mạch.
					|Việc xem danh sách tệp được phép chỉ bên 1C:Document Management.';
					|ru = 'Владелец файлов не поддерживается бесшовной интеграцией.
					|Просмотр списка файлов доступен только на стороне 1С:Документооборот.';
					|en = 'Seamless integration does not support the file owner.
					|You can only preview the file list in 1C:Document Management.'; fa = 'Seamless integration does not support the file owner.
					|You can only preview the file list in 1C:Document Management.';
					|it = 'Владелец файлов не поддерживается бесшовной интеграцией.
					|Просмотр списка файлов доступен только на стороне 1С:Документооборот.';
					|pl = 'Seamless integration does not support the file owner.
					|You can only preview the file list in 1C:Document Management.';
					|tr = 'Dosya sahibi eksiksiz entegrasyon tarafından desteklenmemektedir.
					|Dosya listesinin görüntülenmesi sadece 1C:Document Management tarafında mümkündür.'");
			EndIf;
			Result.Insert("Status", "Error");
			Result.Insert("BriefErrorDescription", ErrorText);
		EndIf;
		RunCallback(CallbackOnCompletion, Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateFilePreview()
	
	UpdatePreview1();
	
EndProcedure

// Updates the preview image.
//
&AtClient
Procedure UpdatePreview1(UpdateData1 = False, IgnoreMaxSize = False)
	
	If Preview = False Then
		Return;
	EndIf;
	
	PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.DownloadMessage();
	Items.ViewPages.CurrentPage = Items.HTMLGroupPage;
	Items.GroupPreviewCut.Visible = False;
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Then
		PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
			TitleOfMessageInPreviewArea);
		Return;
	EndIf;
	If CurrentData.WaitingForPreview Then
		Return;
	EndIf;
	
	ReturnBinaryData = ShowPDFUsing1C
		And (Lower(CurrentData.Extension) = "pdf")
		And Not CurrentData.Encrypted;
	ThereIsPreviewFile = IsTempStorageURL(CurrentData.AddressInPreviewFileStorage)
		And Not CurrentData.Encrypted;
	
	If CurrentData.Type = "DMFile"
			And (UpdateData1
				Or (ReturnBinaryData And Not ThereIsPreviewFile)
				Or (Not ValueIsFilled(CurrentData.PresentationHTML) And Not ThereIsPreviewFile)) Then
		
		CurrentData.WaitingForPreview = True;
		TimeConsumingOperation = IntegrationWith1CDocumentManagement3ServerCall.GetHTMLPreviewOfObjectAsynchronously(
			UUID,
			CurrentData.ID,
			CurrentData.Type,
			IgnoreMaxSize,
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(ID, Type),
			ReturnBinaryData);
		
		CallbackOnCompletion = New CallbackDescription(
			"UpdatePreview1Completion",
			ThisObject,
			CurrentData);
		
		IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
			ThisObject,
			TimeConsumingOperation,
			CallbackOnCompletion,
			False,,
			False);
		
		Return;
		
	EndIf;
	
	If Not CurrentData.EditedByCurUser And CurrentData.PreviewCut Then
		Items.GroupPreviewCut.Visible = True;
	EndIf;
	
	If ValueIsFilled(CurrentData.PresentationHTML) Then
		PresentationHTML = CurrentData.PresentationHTML;
	ElsIf ThereIsPreviewFile Then
		If CurrentData.EditedByCurUser Then
			PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutEditing(
				TitleOfMessageInPreviewArea);
		Else
			PDFDocument = IntegrationWith1CDocumentManagementCoreServerCall.GetPDFDocument(
				CurrentData.AddressInPreviewFileStorage);
			If PDFDocument = Undefined Then
				PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
					TitleOfMessageInPreviewArea);
			Else
				ThisObject["PDFDocumentAttributes"] = PDFDocument;
				Items.ViewPages.CurrentPage = Items.PageGroupPDF;
				Items["DocumentPDFField"].CurrentPageNumber = 1;
			EndIf;
		EndIf;
	Else
		PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
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
Procedure UpdatePreview1Completion(Result, NotificationParameters) Export
	
	HTMLObjectPreview =
		IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview();
	
	If Result <> Undefined And Result.Status = "Error" Then
		HTMLMessage =
			IntegrationWith1CDocumentManagementCoreClientServer.PreviewMessage(
				Result.BriefErrorDescription,
				TitleOfMessageInPreviewArea);
		HTMLObjectPreview.ID = NotificationParameters.ID;
		HTMLObjectPreview.Type = NotificationParameters.Type;
		HTMLObjectPreview.Extension = NotificationParameters.Extension;
		HTMLObjectPreview.PresentationHTML = HTMLMessage;
		Notify("HTMLObjectPreviewReceived", HTMLObjectPreview, ThisObject);
	EndIf;
	
	ProcessAForm = False;
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		IntegrationWith1CDocumentManagementCoreClientServer.AddPersonalData(HTMLObjectPreview);
		FillPropertyValues(HTMLObjectPreview, Result.ResultLongOperation);
		HTMLObjectPreview.ID = NotificationParameters.ID;
		HTMLObjectPreview.Type = NotificationParameters.Type;
		HTMLObjectPreview.Extension = NotificationParameters.Extension;
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

// Updates the file list by retrieving it from BEFORE.
//
&AtClient
Procedure UpdateFileListClient(FileID = Undefined,
		OutputIdleWindow = True, HideInterface = False)
	
	CurRowId_ = Undefined;
	CurCurrentStringType = Undefined;
	If FileID <> Undefined Then
		CurRowId_ = FileID;
		CurCurrentStringType = "DMFile";
	ElsIf Items.FilesTree.CurrentData <> Undefined Then
		CurRowId_ = Items.FilesTree.CurrentData.ID;
		CurCurrentStringType = Items.FilesTree.CurrentData.Type;
	EndIf;
	LinesForDisclosure = New Array;
	If UseFileRoles Then
		For Each String In FilesTree.GetItems() Do
			If Items.FilesTree.Expanded(String.GetID()) Then
				LinesForDisclosure.Add(String.ID);
			EndIf;
		EndDo;
	EndIf;
	
	ParametersOfUpdate = FilesUpdateParameters();
	ParametersOfUpdate.OutputIdleWindow = OutputIdleWindow;
	ParametersOfUpdate.HideInterface = HideInterface;
	StartUpdatingFiles(ParametersOfUpdate);
	
EndProcedure

&AtClient
Procedure UpdateFormElements()
	
	Items.ChooseFileRole.Visible = UseFileRoles;
	Items.SelectRoleOfContextFile.Visible = UseFileRoles;
	
	ThereAreAttachedVISFiles = (AttachedVISFiles.Count() > 0);
	Items.TransferFilesAndSvTO.Visible = ThereAreAttachedVISFiles;
	Items.FilesTreeContextMenuTransferFilesAndSvTO.Visible = ThereAreAttachedVISFiles;
	
	If ThereAreAttachedVISFiles
			And ValueIsFilled(AbbreviatedNameOfConfiguration) Then
		CommandTitle = StrTemplate(
			NStr("vi = 'Tệp %1 từ %2...';
				|ru = 'Файлы %1 из %2...';
				|en = 'The %1 files from %2...'; fa = 'The %1 files from %2...';
				|it = 'Файлы %1 из %2...';
				|pl = 'The %1 files from %2...';
				|tr = '%1 dosyaları %2den...'"),
			OwnerTypePresentation,
			AbbreviatedNameOfConfiguration);
		Items.TransferFilesAndSvTO.Title = CommandTitle;
		Items.FilesTreeContextMenuTransferFilesAndSvTO.Title = CommandTitle;
	EndIf;
	
	Items.AddPrintedForm.Visible = HasOwner;
	Items.FilesTreeContextMenuAddPrintedForm.Visible = HasOwner;
	If HasOwner Then
		CommandTitle = StrTemplate(NStr("vi = 'Mẫu in từ %1...';
										|ru = 'Печатную форму из %1...';
										|en = 'Print form from %1...'; fa = 'Print form from %1...';
										|it = 'Печатную форму из %1...';
										|pl = 'Print form from %1...';
										|tr = '%1yazdırma formundan...'"), OwnerTypePresentation);
		Items.AddPrintedForm.Title = CommandTitle;
		Items.FilesTreeContextMenuAddPrintedForm.Title = CommandTitle;
		Items.AddPrintedForm.Enabled = StateAllowsFileAddition;
		Items.FilesTreeContextMenuAddPrintedForm.Enabled = StateAllowsFileAddition;
	EndIf;
	
	Items.Send.Visible = SendingViaIPIsAvailable;
	
	Items.ChooseFileRole.Enabled = StateAllowsFileAddition;
	Items.SelectRoleOfContextFile.Enabled = StateAllowsFileAddition;
	Items.AddFromDisk.Enabled = (StateAllowsFileAddition
		Or StateAllowsAddingScannedCopy);
	Items.AddContextFromDisk.Enabled = (StateAllowsFileAddition
		Or StateAllowsAddingScannedCopy);
	
	Items.OpenForEditing.Enabled = StateAllowsFileEditing;
	Items.ContextOpenForEditing.Enabled = StateAllowsFileEditing;
	Items.EndEdit.Enabled = StateAllowsFileEditing;
	Items.ContextEdit.Enabled = StateAllowsFileEditing;
	Items.UpdateFromFileOnHardDrive.Enabled = StateAllowsFileEditing;
	Items.UpdateFromFileOnDiskContext.Enabled = StateAllowsFileEditing;
	Items.SaveChanges.Enabled = StateAllowsFileEditing;
	
EndProcedure

&AtClient
Procedure FileUpdateEnd(Result, ParametersOfUpdate) Export
	
	ProcessAForm = False;
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		
		UpdateCompletedSuccessfully = True;
		
		FilesTree.GetItems().Clear();
		
		Items.AddGroup.Enabled = True;
		Items.ListContextMenuCommandsGroupAdd.Enabled = True;
		
		ObjectPreview = ReadAndUpdateFileList(Result.ResultLongOperation);
		If ObjectPreview <> Undefined Then
			Notify("HTMLObjectPreviewReceived", ObjectPreview, ThisObject);
		EndIf;
		
		UpdateFormElements();
		
		If ParametersOfUpdate.OnOpen Then
			LinesForDisclosure = New Array;
			If UseFileRoles Then
				For Each String In FilesTree.GetItems() Do
					If ValueIsFilled(String.ID) And String.RoleIsMandatory Then
						LinesForDisclosure.Add(String.ID);
					EndIf;
				EndDo;
			EndIf;
			CurRowId_ = CurrentFile;
			CurCurrentStringType = "DMFile";
		EndIf;
		
		RestorePositionInList();
		
		If ParametersOfUpdate.AskQuestionAboutFileTransfer Then
			LinkData = New Structure;
			LinkData.Insert("ID", ID);
			LinkData.Insert("Type", Type);
			LinkData.Insert("Object", Owner);
			FileTransferOptions =
				IntegrationWith1CDocumentManagementCoreServerCall.ParametersForTransferringFilesToDM(
					LinkData,
					AttachedVISFiles,
					FileCatalogType,
					OwnerTypePresentation);
			If FileTransferOptions.NeedToAskQuestionAboutTransferringFilesToDM Then
				If StateAllowsFileAddition Or StateAllowsAddingScannedCopy Then
					IntegrationWith1CDocumentManagement3Client.ToAskQuestionAboutTransferringFilesToDM(
						FileTransferOptions,
						New CallbackDescription("TransferFilesAndSvTOCompletion", ThisObject),
						UUID);
				Else
					QueryText = StrTemplate(
						NStr("vi = 'Trong %1 ""%2"" có tệp đính kèm được thêm vào %3 trước khi cài đặt lưu tệp bên phía  1C:Document Management.
							|Nên chuyển các tệp này vào Document Management.
							|
							|Hiển thị tệp được lưu bên phía %3?';
							|ru = 'У %1 ""%2"" есть присоединенные файлы, добавленные в %3 до настройки хранения файлов на стороне 1С:Документооборота.
							|Рекомендуется перенести эти файлы в 1С:Документооборот.
							|
							|Показать файлы, хранящиеся на стороне %3?';
							|en = 'The ""%2"" %1 has attachments that were added to %3 before configuring file storage in 1C:Document Management.
							|We recommended that you transfer these files to 1C:Document management.
							|
							|Show files stored in %3?'; fa = 'The ""%2"" %1 has attachments that were added to %3 before configuring file storage in 1C:Document Management.
							|We recommended that you transfer these files to 1C:Document management.
							|
							|Show files stored in %3?';
							|it = 'У %1 ""%2"" есть присоединенные файлы, добавленные в %3 до настройки хранения файлов на стороне 1С:Документооборота.
							|Рекомендуется перенести эти файлы в 1С:Документооборот.
							|
							|Показать файлы, хранящиеся на стороне %3?';
							|pl = 'The ""%2"" %1 has attachments that were added to %3 before configuring file storage in 1C:Document Management.
							|We recommended that you transfer these files to 1C:Document management.
							|
							|Show files stored in %3?';
							|tr = '""%2""%1, 1C:Document Management tarafındaki dosya depolama %3ayarlarına eklenmiş dosyalara sahip.
							|Bu dosyaların 1C:Document Management''a taşınması önerilmektedir.
							|
							|Yanda saklanan dosyalar gösterilsin mi%3?'"),
						FileTransferOptions.OwnerTypePresentation,
						String(FileTransferOptions.OwnerIS),
						FileTransferOptions.AbbreviatedNameOfConfiguration);
					WarningParameters = StandardSubsystemsClient.QuestionToUserParameters();
					WarningParameters.DefaultButton = DialogReturnCode.Yes;
					WarningParameters.Picture = PictureLib.Information32;
					WarningParameters.PromptDontAskAgain = False;
					WarningParameters.Title = NStr("vi = 'Tệp lưu trữ';
													|ru = 'Архивные файлы';
													|en = 'Archived files'; fa = 'Archived files';
													|it = 'Архивные файлы';
													|pl = 'Archived files';
													|tr = 'Arşivlenmiş dosyalar'");
					Buttons = New ValueList;
					Buttons.Add(DialogReturnCode.Yes);
					Buttons.Add(DialogReturnCode.No);
					StandardSubsystemsClient.ShowQuestionToUser(
						New CallbackDescription("ShowIPFilesContinued", ThisObject),
						QueryText,
						Buttons,
						WarningParameters);
				EndIf;
			EndIf;
		EndIf;
		
	ElsIf ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

// Handler for the "GETTHTML Object view" event.
//
// Parameters:
//   Parameter - See IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview
//   Source - Arbitrary - event source.
//
&AtClient
Procedure ProcessHTMLPreviewReceiptEvent(Parameter, Source)
	
	String = IntegrationWith1CDocumentManagement3Client.FileTreeStringByID(
		FilesTree,
		UseFileRoles,
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
		UpdatePreview1();
	EndIf;
	
EndProcedure

// Opens the card of the selected file.
//
&AtClient
Procedure OpenCard()
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure("EditingAllowed", StateAllowsFileEditing);
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		CurrentData.Type,
		CurrentData.ID,
		ThisObject,
		AdditionalParameters);
	
EndProcedure

&AtClient
Procedure OpenCurFileForEditing()
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenFile(
		CurrentData.ID,
		CurrentData.Description,
		CurrentData.Extension,
		UUID,
		False,,
		ID);
	
EndProcedure

&AtClient
Procedure OpenCurFileForReading()
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenFile(
		CurrentData.ID,
		CurrentData.Description,
		CurrentData.Extension,
		UUID);
	
EndProcedure

// Constructor of the parameter structure to start creating a file.
//
// Returns:
//   See IntegrationWith1CDocumentManagementCoreClient.FileCreationStartParameters
//
&AtClient
Function FileCreationStartParameters()
	
	ParametersForStartOfCreation =
		IntegrationWith1CDocumentManagementCoreClient.FileCreationStartParameters();
	ParametersForStartOfCreation.IsScannedCopy =
		(StateAllowsAddingScannedCopy And Not StateAllowsFileAddition);
	ParametersForStartOfCreation.OwnerID = ID;
	ParametersForStartOfCreation.OwnerType = Type;
	ParametersForStartOfCreation.FormUniqueID = UUID;
	ParametersForStartOfCreation.OwnerPresentation = String(Owner);
	ParametersForStartOfCreation.Owner = Owner;
	
	Return ParametersForStartOfCreation;
	
EndFunction

&AtClient
Function FilesUpdateParameters()
	
	FilesUpdateParameters = New Structure;
	FilesUpdateParameters.Insert("OnOpen", False);
	FilesUpdateParameters.Insert("AskQuestionAboutFileTransfer", False);
	FilesUpdateParameters.Insert("OutputIdleWindow", False);
	FilesUpdateParameters.Insert("HideInterface", True);
	
	Return FilesUpdateParameters;
	
EndFunction

&AtClient
Procedure TransferFilesAndSvTO()
	
	CallbackDescription = New CallbackDescription("TransferFilesAndSvTOCompletion", ThisObject);
	If ValueIsFilled(ID) Then // The associated object is already known.
		RunCallback(CallbackDescription, Undefined);
	Else // The linked object should be found or created.
		IntegrationWith1CDocumentManagementCoreClient.StartSearchingForARelatedObjectDM(
			Owner,
			CallbackDescription,,,
			False);
	EndIf;
	
EndProcedure

// Continues transferring files from the integrated system.
//
&AtClient
Procedure TransferFilesAndSvTOCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ID = Result.ID;
		Type = Result.type;
	EndIf;
	If Not ValueIsFilled(ID) Then
		Return;
	EndIf;
	
	If UseFileRoles Then
		FileRoleID = IntegrationWith1CDocumentManagement3Client.CurCurrentFileRole(
			FilesTree,
			Items.FilesTree.CurrentRow);
	Else
		FileRoleID = "";
	EndIf;
	
	IntegrationWith1CDocumentManagement3Client.TransferFilesAndSvTO(
		AttachedVISFiles,
		ID,
		Type,
		Owner,
		FileRoleID,
		UUID);
	
	ThereAreAttachedVISFiles = (AttachedVISFiles.Count() > 0);
	Items.TransferFilesAndSvTO.Visible = ThereAreAttachedVISFiles;
	Items.FilesTreeContextMenuTransferFilesAndSvTO.Visible = ThereAreAttachedVISFiles;
	
EndProcedure

// It is called after asking the user about opening IP files.
//
&AtClient
Procedure ShowIPFilesContinued(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Value = DialogReturnCode.Yes Then
		IntegrationWith1CDocumentManagementCoreClient.OpenBSPFileListForm(Owner);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterDeletingFiles(Result, NotificationParameters) Export
	
	UpdateFileListClient();
	
EndProcedure

&AtClient
Procedure WhenConnecting()
	
	If ProcessFormAccordingToServiceVersion() Then
		ParametersOfUpdate = FilesUpdateParameters();
		ParametersOfUpdate.OnOpen = True;
		ParametersOfUpdate.AskQuestionAboutFileTransfer = True;
		StartUpdatingFiles(ParametersOfUpdate);
	EndIf;
	
EndProcedure

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

// It is called after checking the connection to BEFORE and changes the form according to the result.
//
&AtClient
Procedure TestConnectionCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		WhenConnecting();
	Else // Couldn't connect to BEFORE.
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtClient
Procedure RemoveAvailabilityOfCommands()
	
	Items.OpenForReading.Enabled = False;
	Items.ContextOpenForReading.Enabled = False;
	Items.OpenForEditing.Enabled = False;
	Items.ContextOpenForEditing.Enabled = False;
	Items.EndEdit.Enabled = False;
	Items.ContextEdit.Enabled = False;
	Items.SaveChanges.Enabled = False;
	Items.CancelEdit.Enabled = False;
	Items.CancelEditingContext.Enabled = False;
	Items.SaveToDisk.Enabled = False;
	Items.SaveToDiskContext.Enabled = False;
	Items.UpdateFromFileOnHardDrive.Enabled = False;
	Items.UpdateFromFileOnDiskContext.Enabled = False;
	Items.OpenCard.Enabled = False;
	Items.OpenContextCard.Enabled = False;
	Items.Delete.Enabled = False;
	Items.RemoveContext.Enabled = False;
	Items.PrintSubmenu.Enabled = False;
	Items.Send.Enabled = False;
	Items.EPGroup.Enabled = False;
	Items.ContextItemInstanceGroup.Enabled = False;
	Items.FormGroupMore.Enabled = False;
	Items.SelectRoleOfContextFile.Enabled = False;
	Items.Copy.Enabled = False;
	Items.CopyContext.Enabled = False;
	Items.OpenDirectoryOfContextFile.Enabled = False;
	Items.SaveWithDigitalSignature.Enabled = False;
	Items.SaveTogetherBotContext.Enabled = False;
	
EndProcedure

// Changes the availability of commands depending on the selected file.
//
&AtClient
Procedure SetAvailabilityOfFileListCommands()
	
	CurrentData = Items.FilesTree.CurrentData;
	If CurrentData = Undefined
			Or Not UpdateCompletedSuccessfully
			Or (CurrentData <> Undefined And CurrentData.Type = "DMFileRole") Then
		
		RemoveAvailabilityOfCommands();
		
	Else
		
		IsBeingEdited = CurrentData.IsBeingEdited;
		EditedByCurUser = CurrentData.EditedByCurUser;
		HasSignatures = CurrentData.SignedWithDS;
		Encrypted = CurrentData.Encrypted;
		
		EditedByAnotherUser =
			IsBeingEdited
			And Not EditedByCurUser;
		CanBeCaptured =
			StateAllowsFileEditing
			And Not EditedByAnotherUser
			And Not Encrypted
			And Not HasSignatures;
		YouCanLetGo =
			StateAllowsFileEditing
			And EditedByCurUser
			And Not Encrypted
			And Not HasSignatures;
		
		Items.OpenForReading.Enabled = Not Encrypted;
		Items.ContextOpenForReading.Enabled = Not Encrypted;
		Items.OpenForEditing.Enabled = CanBeCaptured;
		Items.ContextOpenForEditing.Enabled = CanBeCaptured;
		Items.EndEdit.Enabled = YouCanLetGo;
		Items.ContextEdit.Enabled = YouCanLetGo;
		Items.SaveChanges.Enabled = YouCanLetGo;
		Items.CancelEdit.Enabled = YouCanLetGo;
		Items.CancelEditingContext.Enabled = YouCanLetGo;
		Items.SaveToDisk.Enabled = Not Encrypted;
		Items.SaveToDiskContext.Enabled = Not Encrypted;
		Items.UpdateFromFileOnHardDrive.Enabled = CanBeCaptured;
		Items.UpdateFromFileOnDiskContext.Enabled = CanBeCaptured;
		Items.OpenCard.Enabled = True;
		Items.OpenContextCard.Enabled = True;
		Items.Delete.Enabled = Not IsBeingEdited And StateAllowsFileDeletion;
		Items.RemoveContext.Enabled = Not IsBeingEdited And StateAllowsFileDeletion;
		Items.PrintSubmenu.Enabled = Not Encrypted;
		Items.Send.Enabled = True;
		Items.EPGroup.Enabled = StateAllowsChangesToItemInstance;
		Items.ContextItemInstanceGroup.Enabled = StateAllowsChangesToItemInstance;
		Items.FormGroupMore.Enabled = True;
		Items.SelectRoleOfContextFile.Enabled = StateAllowsFileAddition;
		Items.Copy.Enabled = StateAllowsFileAddition;
		Items.CopyContext.Enabled = StateAllowsFileAddition;
		Items.OpenDirectoryOfContextFile.Enabled = True;
		Items.SaveWithDigitalSignature.Enabled = HasSignatures;
		Items.SaveTogetherBotContext.Enabled = HasSignatures;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Server

&AtServer
Procedure FillInIDByOwner()
	
	If Not HasOwner Then
		Return;
	EndIf;
	
	LinkedObjectBefore = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ObjectDataUpToExternalObject(
		Owner);
	If LinkedObjectBefore <> Undefined Then
		ID = LinkedObjectBefore.ID;
		Type = LinkedObjectBefore.type;
	EndIf;
	
EndProcedure

// Modifies the form according to the availability of the service BEFORE and its version number.
//
&AtServer
Function ProcessFormAccordingToServiceVersion()
	
	ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
	If Not IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsUnavailable;
		Return False;
	EndIf;
	
	FormProcessedSuccessfully = True;
	
	Try
		
		If IntegrationWith1CDocumentManagement3.FileFunctionalityIsAvailable() Then
			
			Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
			
			// Let's process the EP settings.
			SettingsBefore = IntegrationWith1CDocumentManagementCoreCached.GetSettings();
			TitleOfMessageInPreviewArea = SettingsBefore.TitleOfMessageInPreviewArea;
			UseDigitalSignatureBefore = (SettingsBefore.UseElectronicDigitalSignatures = True);
			UseDigitalSignature = (UseDigitalSignatureBefore And UseDigitalSignatureIS);
			ShowPDFUsing1C = SettingsBefore.ShowPDFUsing1C;
			If ShowPDFUsing1C Then
				IntegrationWith1CDocumentManagement3.OutputPDFDocumentToForm(ThisObject, "PageGroupPDF");
			EndIf;
			
			Items.FilesTreeSignedEncryptedPictureNumber.Visible = UseDigitalSignatureBefore;
			Items.Sign.Visible = UseDigitalSignature;
			Items.AddDSFromFile.Visible = UseDigitalSignature;
			Items.SaveWithDigitalSignature.Visible = UseDigitalSignature;
			Items.SignContext.Visible = UseDigitalSignature;
			Items.AddItemInstancesFromContextFile.Visible = UseDigitalSignature;
			Items.SaveTogetherBotContext.Visible = UseDigitalSignature;
			
			IntegrationWith1CDocumentManagementCoreClientServer.SetValuesOfAllNDPSFields(
				ThisObject,
				True);
			
			FillInIDByOwner();
			
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

&AtServer
Function ReadAndUpdateFileList(ResultLongOperation)
	
	HTMLObjectPreview = Undefined;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	If TypeOf(ResultLongOperation) = Type("Structure") Then
		XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			ResultLongOperation.Type);
	Else
		XDTODataObject = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(
			Proxy,
			ResultLongOperation);
	EndIf;
	
	FileRoles = New Array;
	If IntegrationWith1CDocumentManagement3.IsDocumentBefore3(XDTODataObject.objectID.type) Then
		FileRoles = XDTODataObject.documentType.roles;
	ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "roles") Then
		FileRoles = XDTODataObject.roles;
	EndIf;
	
	ListOfFiles = New Array;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "files") Then
		ListOfFiles = XDTODataObject.files; // XDTOList
	EndIf;
	
	If ListOfFiles.Count() = 0 Then
		PresentationHTML = IntegrationWith1CDocumentManagementCoreClientServer.MessageAboutAbsenceOfPreview(
			TitleOfMessageInPreviewArea);
	EndIf;
	
	For Each XDTOFile In ListOfFiles Do
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "htmlView")
				Or IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "binaryData") Then
			HTMLObjectPreview =
				IntegrationWith1CDocumentManagementCoreClientServer.NotificationParametersReceivedHTMLObjectPreview();
			HTMLObjectPreview.ID = XDTOFile.ObjectID.ID;
			HTMLObjectPreview.Type = XDTOFile.ObjectID.type;
			HTMLObjectPreview.Extension = XDTOFile.extension;
			If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "binaryData") Then
				HTMLObjectPreview.BinaryData = XDTOFile.binaryData;
			Else
				HTMLObjectPreview.PresentationHTML = XDTOFile.htmlView;
				HTMLObjectPreview.PreviewCut = XDTOFile.htmlViewTruncated;
			EndIf;
			Break;
		EndIf;
	EndDo;
	
	UseFileRoles = (FileRoles.Count() > 0);
	
	FilesTree.GetItems().Clear();
	IntegrationWith1CDocumentManagementCoreServerCall.UpdateFileTree(
		FilesTree,
		AvailableRoles,
		ListOfFiles,
		UseFileRoles,
		FileRoles);
	
	If HasOwner Then
		IntegrationWith1CDocumentManagementCore.FillInNonTransferredToDMAttachedFilesToIS(
			AttachedVISFiles,
			Owner,
			ListOfFiles);
	EndIf;
	
	If UseDigitalSignature Then
		IntegrationWith1CDocumentManagementCore.UpdateListOfFileSignatures(
			ListOfFiles,
			Signatures,
			UUID);
	EndIf;
	
	// Let's clarify the availability of the add and edit commands.
	IntegrationWith1CDocumentManagementCore.FillInPPEOfXDTOObject(ThisObject, XDTODataObject);
	
	Return HTMLObjectPreview;
	
EndFunction

#EndRegion

#Region Mail

// Starts sending a message by means of IC, if the use of mail is turned off before.
//
&AtClient
Procedure SendViaIS()
	
	If SendingViaIPIsAvailable Then
		CallbackDescription = New CallbackDescription("SendViaISAccountSettingProposed", ThisObject);
		ModuleEmailOperationsClient =
			CommonClient.CommonModule("EmailOperationsClient");
		ModuleEmailOperationsClient.CheckAccountForSendingEmailExists(CallbackDescription);
	Else
		ShowMessageBox(,NStr("vi = 'Không hỗ trợ gửi tệp';
							|ru = 'Отправка файлов не поддерживается';
							|en = 'File sending is not supported'; fa = 'File sending is not supported';
							|it = 'Отправка файлов не поддерживается';
							|pl = 'File sending is not supported';
							|tr = 'Dosya gönderimi desteklenmemektedir'"));
	EndIf;
	
EndProcedure

// Continues sending emails by means of IC after placing files from BEFORE in the repository.
//
&AtClient
Procedure SendViaISAccountSettingProposed(AccountSetUp, Var_Parameters) Export
	
	If AccountSetUp <> True Then
		Return;
	EndIf;
	
	Selected_Files = IntegrationWith1CDocumentManagementCoreClient.Selected_Files(
		FilesTree,
		Items.FilesTree.SelectedRows);
	Attachments = New Array;
	For Each Selected_File In Selected_Files Do
		Presentation = StrTemplate("%1.%2", Selected_File.Description, Selected_File.Extension);
		Attachment = New Structure;
		Attachment.Insert("Presentation", Presentation);
		Attachment.Insert("Id", Undefined);
		Attachment.Insert("IdBefore", Selected_File.ID);
		Attachments.Add(Attachment);
	EndDo;
	
	Var_Parameters = OutgoingMessageParameters(Owner, Attachments, UUID);
	
	ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
	ModuleEmailOperationsClient.CreateNewEmailMessage(Var_Parameters);
	
EndProcedure

// Generates parameters of an outgoing email with attachments.
//
// Parameters:
//   Owner - Arbitrary - the owner of the files.
//   Attachments - Array - array of structures with properties:
//     Presentation - String - File Presentation;
//     Id - String - file ID in UP to.
//   FormUniqueID - UUID - ID of the calling form.
//
&AtServerNoContext
Function OutgoingMessageParameters(Val Owner, Val Attachments, Val FormUniqueID)
	
	// Let's prepare the title of the letter.
	EmailParameters = New Structure("DeleteFilesAfterSending", True);
	OneAttachment = Attachments.Count() = 1;
	
	// recipient.
	If IntegrationWith1CDocumentManagementCoreCached.SubsystemExists("SendingMailMessages") Then
		ModuleSendingMailMessages = Common.CommonModule("SendingMailMessages");
	Else
		ModuleSendingMailMessages = Undefined;
	EndIf;
	
	If Common.HasObjectAttribute("Counterparty", Owner.Metadata())
			And ModuleSendingMailMessages <> Undefined Then
		Counterparty = Common.ObjectAttributeValue(Owner, "Counterparty");
		EmailParameters.Insert("Recipient", ModuleSendingMailMessages.Emails(Counterparty));
	Else
		EmailParameters.Insert("Recipient", "");
	EndIf;
	
	// Topic.
	DocumentNumber = Common.ObjectAttributeValue(Owner, "Number");
	If Metadata.CommonModules.Find("ObjectsPrefixesClientServer") <> Undefined Then
		ModuleObjectsPrefixesClientServer = Common.CommonModule("ObjectsPrefixesClientServer");
		DocumentNumber = ModuleObjectsPrefixesClientServer.NumberForPrinting(DocumentNumber, True, True);
	EndIf;
	DocumentDate = Format(Common.ObjectAttributeValue(Owner, "Date"), "DLF=DD");
	Subject = StrTemplate(NStr("vi = '%1, %2 kèm theo chứng từ %3 %4 ngày %5';
								|ru = '%1, %2 к документу %3 %4 от %5';
								|en = '%1, %2 to document %3 %4 from %5'; fa = '%1, %2 to document %3 %4 from %5';
								|it = '%1, %2 al documento %3 %4 di %5';
								|pl = '%1, %2 do dokumentu %3 %4 z dnia %5';
								|tr = '%1, %2 belgeye %3 %4 %5itibaren'"),
		?(OneAttachment, NStr("vi = 'Tệp';
								|ru = 'Файл';
								|en = 'File'; fa = 'فایل';
								|it = 'Файл';
								|pl = 'Plik';
								|tr = 'Dosya'"), NStr("vi = 'Tệp';
													|ru = 'Файлы';
													|en = 'Files'; fa = 'فایل‌ها';
													|it = 'Файлы';
													|pl = 'Pliki';
													|tr = 'Dosyalar'")),
		?(OneAttachment, NStr("vi = 'đính kèm';
								|ru = 'присоединенный';
								|en = 'attached file'; fa = 'attached file';
								|it = 'присоединенный';
								|pl = 'załączony';
								|tr = 'ekli'"), NStr("vi = 'đính kèm';
															|ru = 'присоединенные';
															|en = 'attached files'; fa = 'attached files';
															|it = 'присоединенные';
															|pl = 'załączone';
															|tr = 'ekler'")),
		TypeOf(Owner),
		DocumentNumber,
		DocumentDate);
	EmailParameters.Insert("Subject", Subject);
	
	// Text.
	Text = StrTemplate(NStr("vi = 'Kèm E-mail %1 %2:';
							|ru = 'К письму %1 %2:';
							|en = 'To email %1 %2:'; fa = 'To email %1 %2:';
							|it = 'Alla posta %1 %2:';
							|pl = 'Do wiadomości %1 %2:';
							|tr = '%1 %2mektuba:'"),
		?(OneAttachment, NStr("vi = 'đính kèm';
								|ru = 'присоединен';
								|en = 'attached'; fa = 'attached';
								|it = 'присоединен';
								|pl = 'załączony';
								|tr = 'eklendi'"), NStr("vi = 'đính kèm';
														|ru = 'присоединены';
														|en = 'are attached'; fa = 'are attached';
														|it = 'присоединены';
														|pl = 'załączone';
														|tr = 'eklendi'")),
		?(OneAttachment, NStr("vi = 'tệp';
								|ru = 'файл';
								|en = 'file'; fa = 'file';
								|it = 'файл';
								|pl = 'plik';
								|tr = 'dosya'"), NStr("vi = 'tệp';
													|ru = 'файлы';
													|en = 'files'; fa = 'files';
													|it = 'файлы';
													|pl = 'pliki';
													|tr = 'dosyalar'")));
	
	// We will get attachments from BEFORE.
	For Each Attachment In Attachments Do
		UseVisualizationOfItemInstanceStamp = True;
		AddressInTempStorage =
			IntegrationWith1CDocumentManagementCoreServerCall.GetFileAndPutItInStorage(
				Attachment.IdBefore,
				UseVisualizationOfItemInstanceStamp,
				FormUniqueID);
		Attachment.Insert("AddressInTempStorage", AddressInTempStorage);
		Text = Text + Chars.LF + StrTemplate(NStr("vi = '- %1';
													|ru = '- %1';
													|en = '- %1'; fa = '- %1';
													|it = '- %1';
													|pl = '- %1';
													|tr = '- %1'"), Attachment.Presentation);
	EndDo;
	EmailParameters.Insert("Attachments", Attachments);
	
	If ModuleSendingMailMessages <> Undefined Then
		PreparedText = ModuleSendingMailMessages.PrepareTextOfLetter(Text);
		EmailParameters.Insert("Text", PreparedText);
		ModuleSendingMailMessages.AddEmailParameters(EmailParameters);
	EndIf;
	
	Return EmailParameters;
	
EndFunction

#EndRegion

#EndRegion