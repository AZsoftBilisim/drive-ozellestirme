#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillFoldersTree(FolderTree.GetItems(), ""); // Root folders.
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFolderTree

&AtClient
Procedure FolderTreeBeforeExpand(Item, String, Cancel)
	
	Leaf = FolderTree.FindByID(String);
	
	If Leaf = Undefined Then
		Return;
	EndIf;
	
	If Not Leaf.SubfoldersRead Then
		PopulateFolderTreeById(String, Leaf.ID);
		Leaf.SubfoldersRead = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure FolderTreeOnActivateRow(Item)
	
	If Items.FolderTree.CurrentRow <> Undefined Then
		AttachIdleHandler("IdleHandler", 0.2, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfFiles

&AtClient
Procedure ListOfFilesSelection(Item, RowSelected, Field, StandardProcessing)
	SelectExecute();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenCard(Command)
	
	OpenCardExecute();
	
EndProcedure
&AtClient
Procedure Select(Command)
	SelectExecute();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillFoldersTree(TreeBranch1, FolderID_)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetSubFoldersRequest");
	
	Query.folder = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		FolderID_,
		"DMFileFolder");
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	TreeBranch1.Clear();
	
	For Each XDTOFolder In Response.folders Do
		Leaf = TreeBranch1.Add();
		Leaf.ID = XDTOFolder.objectID.ID;
		Leaf.Description = XDTOFolder.name;
		Leaf.PictureIndex = 0;
		Leaf.SubfoldersRead = False;
		
		Leaf.GetItems().Add(); // to get a plus sign
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateFileList()
	
	ListOfFiles.Clear();
	
	Files = IntegrationWith1CDocumentManagementCoreServerCall.FilesByOwner(
		IDOfCurFolder,
		CurFolderName,
		"DMFileFolder");
	
	For Each FileInfo1 In Files.files Do
		NewRow = ListOfFiles.Add();
		
		NewRow.File = FileInfo1.name;
		NewRow.Extension = FileInfo1.extension;
		NewRow.LongDesc = FileInfo1.description;
		NewRow.Size = Format(FileInfo1.size/1024, "ND=10; NZ=0");
		NewRow.SignedWithDS = FileInfo1.signed;
		NewRow.ID = FileInfo1.objectID.ID;
		NewRow.CreationDate = FileInfo1.creationDate;
		If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "author") Then
			NewRow.Author = FileInfo1.author.name;
		EndIf;
		NewRow.URL = FileInfo1.objectID.navigationRef;
		
		DeletionMark = False;
		If IntegrationWith1CDocumentManagementCore.PropertySet(FileInfo1, "deletionMark") Then
			DeletionMark = FileInfo1.deletionMark;
		EndIf;
		NewRow.PictureIndex =
			IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(
				NewRow.Extension,
				DeletionMark);
	EndDo;
	
EndProcedure

&AtClient
Procedure OpenCardExecute()
	
	If Items.ListOfFiles.CurrentData = Undefined Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		"DMFile",
		Items.ListOfFiles.CurrentData.ID);
	
EndProcedure

&AtServer
Procedure PopulateFolderTreeById(IDOfTreeElement, FolderID_)
	
	Leaf = FolderTree.FindByID(IDOfTreeElement);
	
	If Leaf = Undefined Then
		Return;
	EndIf;
	
	FillFoldersTree(Leaf.GetItems(), Leaf.ID);
	
EndProcedure

&AtClient
Procedure IdleHandler()
	
	Data = Items.FolderTree.CurrentData;
	
	If Data.ID <> IDOfCurFolder Then
		IDOfCurFolder = Data.ID;
		CurFolderName = Data.Description;
		UpdateFileList();
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectExecute()
	
	CurrentData = Items.ListOfFiles.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("AttributeID", CurrentData.ID);
	Result.Insert("AttributeType", "DMFile");
	Result.Insert("AttributePresentation", CurrentData.File);
	Result.Insert("AttributeNavigationLink", CurrentData.URL);
	Close(Result);
	
EndProcedure

#EndRegion