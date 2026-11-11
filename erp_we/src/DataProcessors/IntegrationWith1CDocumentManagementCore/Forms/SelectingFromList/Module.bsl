#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SelectedElement = Undefined;
	Parameters.Property("SelectedElement", SelectedElement);
	
	If Parameters.ListOfValuesToSelect <> Undefined
			And Parameters.ListOfValuesToSelect.Count() > 0 Then
		
		TreeItems = Tree.GetItems();
		For Each Item In Parameters.ListOfValuesToSelect Do
			NewRow = TreeItems.Add();
			NewRow.Description = Item.Value.Name;
			NewRow.ID = Item.Value.ID;
			NewRow.Type = Item.Value.Type;
			NewRow.Picture = IntegrationWith1CDocumentManagementCore.IndexOfImageOfCatalogElement();
		EndDo;
		
		Items.FormFind.Visible = False;
		Items.FormCancelSearch.Visible = False;
		Items.TreeContextMenuFind.Visible = False;
		Items.TreeContextMenuCancelSearch.Visible = False;
		
	Else
		
		TypeOfSelectionObject = Parameters.TypeOfSelectionObject;
		Filter = Parameters.Filter;
		
		FillFoldersTree(Tree.GetItems(), , , SelectedElement); // Root folders.
		
	EndIf;
	
	If ValueIsFilled(Parameters.Title) Then
		Title = Parameters.Title;
	EndIf;
	
	Items.FormCreateFolderOfInternalDocuments.Visible = (TypeOfSelectionObject = "DMInternalDocumentFolder");
	
	SelectGroups = Parameters.SelectGroups;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTree

&AtClient
Procedure TreeValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Tree.FindByID(Value);
	ValueChoice(CurrentData);
	
EndProcedure

&AtClient
Procedure TreeBeforeExpand(Item, String, Cancel)
	
	Leaf = Tree.FindByID(String);
	
	If Leaf = Undefined Then
		Return;
	EndIf;
	
	If Not Leaf.SubfoldersRead Then
		PopulateFolderTreeById(String, Leaf.ID);
		Leaf.SubfoldersRead = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FindExecute(Command)
	
	Notification = New CallbackDescription("FindExecuteCompletion", ThisObject);
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SearchInList",,,,,, Notification);
	
EndProcedure

&AtClient
Procedure FindExecuteCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("String") Then
		FillFolderTreeFromRoot(, Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelSearch(Command)
	
	// Cancel the search mode.
	FillFolderTreeFromRoot(""); // Root folders.
	
EndProcedure

&AtClient
Procedure Select(Command)
	
	CurrentData = Items.Tree.CurrentData;
	ValueChoice(CurrentData);
	
EndProcedure

&AtClient
Procedure CreateFolderOfInternalDocuments(Command)
	
	FormParameters = New Structure;
	
	CurrentData = Items.Tree.CurrentData;
	If CurrentData <> Undefined Then
		FormParameters.Insert("ParentID",  CurrentData.ID);
		FormParameters.Insert("ParentType", CurrentData.Type);
		FormParameters.Insert("Parent", CurrentData.Description);
	EndIf;
	
	FormNameInternalDocumentsFolder = "DataProcessor.IntegrationWith1CDocumentManagement.Form.InternalDocumentFolder";
	OpenForm(
		FormNameInternalDocumentsFolder,
		FormParameters,
		ThisObject,,,,
		New CallbackDescription("CreateCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ValueChoice(CurrentData)
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.IsFolder And Not SelectGroups Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn phần tử, mà không phải nhóm.';
								|ru = 'Выберите элемент, а не группу.';
								|en = 'Select an item, not a group.'; fa = 'Select an item, not a group.';
								|it = 'Scegliete un elemento, e non un gruppo';
								|pl = 'Wybierz element, a nie grupę.';
								|tr = 'Grup değil, öğe seç.'"));
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("AttributeID", CurrentData.ID);
	Result.Insert("AttributeType", CurrentData.Type);
	Result.Insert("AttributePresentation", CurrentData.Description);
	Result.Insert("AttributeNavigationLink", CurrentData.URL);
	
	Close(Result);
	
EndProcedure

&AtServer
Procedure FillFoldersTree(TreeBranch1, FolderID_ = "", SearchString = Undefined,
		SelectedElement = Undefined)
	
	TreeBranch1.Clear();
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Conditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	ListOfSelectionConditions = Conditions.conditions; // XDTOList
	
	If ValueIsFilled(FolderID_) Then
		
		ParentID__ = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			FolderID_,
			TypeOfSelectionObject);
		
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "Parent";
		Condition.value = ParentID__;
		If Condition.Properties().Get("comparisonOperator") <> Undefined Then
			Condition.comparisonOperator = "=";
		EndIf;
		
		ListOfSelectionConditions.Add(Condition);
		
	EndIf;
	
	If SearchString <> Undefined Then
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "Name";
		Condition.value = SearchString;
		ListOfSelectionConditions.Add(Condition);
	EndIf;
	
	If ValueIsFilled(SelectedElement) Then
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "SelectedItem"; // Makes sense only for a hierarchical Catalog.
		ParentID__ = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			SelectedElement,
			TypeOfSelectionObject);
		Condition.value = ParentID__;
		ListOfSelectionConditions.Add(Condition);
	EndIf;
	
	If TypeOf(Filter) = Type("Structure") Then
		For Each FIlterRow In Filter Do
			Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
			Condition.property = FIlterRow.Key;
			
			If TypeOf(FIlterRow.Value) = Type("Structure") Then
				Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
					Proxy,
					FIlterRow.Value.ID,
					FIlterRow.Value.type);
			Else
				Condition.value = FIlterRow.Value;
			EndIf;
			
			ListOfSelectionConditions.Add(Condition);
		EndDo;
	EndIf;
	
	Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		TypeOfSelectionObject,
		Conditions);
	
	If Not ValueIsFilled(SelectedElement) Then
		
		For Each Item In Result.items Do
			If IntegrationWith1CDocumentManagementCore.PropertySet(Item, "parentID") Then
				IDOfElementSParent = Item.parentID.ID;
			Else
				IDOfElementSParent = "";
			EndIf;
			If FolderID_ = IDOfElementSParent
				Or ValueIsFilled(SearchString) Then
				NewRow = TreeBranch1.Add();
				FillInTreeElement(NewRow, Item, SearchString);
			EndIf;
		EndDo;
		
	Else
		// Fill in the tree - insert the necessary elements for each level and restore the current row.
		ThereAreChildElements = False;
		BranchIDOfSelectedItem = Undefined;
		FillLevelOfTree(
			TreeBranch1,
			"", // "" - the root.
			Result.items,
			SearchString,
			ThereAreChildElements,
			SelectedElement,
			BranchIDOfSelectedItem);
		
		If BranchIDOfSelectedItem <> Undefined Then
			Items.Tree.CurrentRow = BranchIDOfSelectedItem;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillLevelOfTree(TreeBranch1, ParentID, XDTOElements, SearchString, ThereAreChildElements,
		SelectedElement, BranchIDOfSelectedItem)
	
	ThereAreChildElements = False;
	
	For Each Item In XDTOElements Do
		
		If (Item.parentID <> Undefined And Item.parentID.ID = ParentID)
				Or (Item.parentID = Undefined And ParentID = "") Then
			
			NewRow = TreeBranch1.Add();
			FillInTreeElement(NewRow, Item, SearchString, False);
			ThereAreChildElements = True;
			
			If NewRow.ID = SelectedElement Then
				BranchIDOfSelectedItem = NewRow.GetID();
			EndIf;
			
			ThereAreChildrenInSubordinateBranch = False;
			FillLevelOfTree(
				NewRow.GetItems(),
				Item.object.objectID.ID,
				XDTOElements,
				SearchString,
				ThereAreChildrenInSubordinateBranch,
				SelectedElement,
				BranchIDOfSelectedItem);
			
			If ThereAreChildrenInSubordinateBranch Then
				NewRow.SubfoldersRead = True;
			Else
				If Item.canHaveChildren And (SearchString = Undefined) Then
					NewRow.SubfoldersRead = False;
					NewRow.GetItems().Add(); // To get a plus sign.
				Else
					NewRow.SubfoldersRead = True;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInTreeElement(NewRow, Item, SearchString, CreateDummySheet = True)
	
	NewRow.Description = Item.object.name;
	NewRow.ID = Item.object.objectID.ID;
	NewRow.Type = Item.object.objectID.type;
	NewRow.IsFolder = Item.isFolder;
	NewRow.URL = Item.object.objectID.navigationRef;
	
	If TypeOfSelectionObject = "DMFileFolder" Or TypeOfSelectionObject = "DMInternalDocumentFolder" Then
		NewRow.Picture = 0;
	Else
		If Item.isFolder Then
			NewRow.Picture = 0;
		Else
			NewRow.Picture = IntegrationWith1CDocumentManagementCore.IndexOfImageOfCatalogElement();
		EndIf;
	EndIf;
	
	If CreateDummySheet Then
		If Item.canHaveChildren And (SearchString = Undefined) Then
			NewRow.SubfoldersRead = False;
			NewRow.GetItems().Add(); // To get a plus sign.
		Else
			NewRow.SubfoldersRead = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure PopulateFolderTreeById(IDOfTreeElement, FolderID_)
	
	Leaf = Tree.FindByID(IDOfTreeElement);
	
	If Leaf = Undefined Then
		Return;
	EndIf;
	
	FillFoldersTree(Leaf.GetItems(), Leaf.ID);
	
EndProcedure

&AtServer
Procedure FillFolderTreeFromRoot(FolderID_ = Undefined, SearchString = Undefined)
	
	FillFoldersTree(Tree.GetItems(), FolderID_, SearchString);
	
EndProcedure

&AtClient
Procedure CreateCompletion(Result, Var_Parameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		UpdateTreeAndActivate(Result.ID);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateTreeAndActivate(SelectedElement)
	
	FillFoldersTree(Tree.GetItems(),,, SelectedElement);
	
EndProcedure

#EndRegion