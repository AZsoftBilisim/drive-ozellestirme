#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillFoldersTree(FolderTree.GetItems(), ""); // root folders
	
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

#Region FormTableItemsEventHandlersDocumentsList

&AtClient
Procedure DocumentsListSelection(Item, RowSelected, Field, StandardProcessing)
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
		"DMInternalDocumentFolder");
	
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
Procedure UpdateListOfDocuments()
	
	DocumentsList.Clear();
	
	XDTODocuments = IntegrationWith1CDocumentManagement.DocumentsOnOwner(
		IDOfCurFolder,
		CurFolderName,
		"DMInternalDocumentFolder");
	
	For Each DocumentInformation_ In XDTODocuments.documents Do
		NewRow = DocumentsList.Add();
		
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(NewRow,DocumentInformation_,"Document");
		NewRow.SignedWithDS = DocumentInformation_.signatures.Count() > 0;
		If DocumentInformation_.IsSet("author") Then
			NewRow.Author = DocumentInformation_.author.name;
		EndIf;
		NewRow.PictureIndex = IntegrationWith1CDocumentManagementCore.IndexOfImageOfCatalogElement();
	EndDo;
	
EndProcedure

&AtClient
Procedure OpenCardExecute()
	
	If Items.DocumentsList.CurrentData = Undefined Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(Items.DocumentsList.CurrentData.DocumentType,Items.DocumentsList.CurrentData.DocumentID);
	
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
		UpdateListOfDocuments();
	EndIf;
		
EndProcedure

&AtClient
Procedure SelectExecute()
	
	If Items.DocumentsList.CurrentData = Undefined Then
		Return;
	EndIf;
	
	ChoiceData = New Structure;
	ChoiceData.Insert("AttributeID",Items.DocumentsList.CurrentData.DocumentID);
	ChoiceData.Insert("AttributeType",Items.DocumentsList.CurrentData.DocumentType);
	ChoiceData.Insert("AttributePresentation",Items.DocumentsList.CurrentData.Document);
	
	Close(ChoiceData);
	
EndProcedure

#EndRegion
