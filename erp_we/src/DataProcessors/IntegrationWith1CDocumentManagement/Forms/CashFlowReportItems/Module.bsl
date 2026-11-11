#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ReadOnly = Parameters.ReadOnly;
	If ReadOnly Then
		Items.Done.Visible = False;
		Items.Cancel.Visible = False;
		Items.Close.Visible = True;
	EndIf;
	
	Sum = Parameters.Sum;
	VATAmount = Parameters.VATAmount;
	ConsiderVAT = Parameters.ConsiderVAT;
	For Each ParameterString In Parameters.CFItems Do
		FillPropertyValues(SelectedArticles.Add(), ParameterString);
	EndDo;
	
	FillInArticleTree(ArticleTree.GetItems());
	
	Items.SelectedArticlesVATAmount.Visible = ConsiderVAT;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpgradeBasement();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersArticleTree

&AtClient
Procedure ArticleTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.ArticleTree.CurrentData;
	If CurrentData <> Undefined
		And Not CurrentData.IsFolder Then
		AddArticleToSelectedOnes(CurrentData);
	EndIf;

EndProcedure

&AtClient
Procedure ArticleTreeBeforeExpand(Item, String, Cancel)
	
	Leaf = ArticleTree.FindByID(String);
	
	If Leaf = Undefined Then
		Return;
	EndIf;
	
	If Not Leaf.SubfoldersRead Then
		FillInArticleTreeById(String, Leaf.CFItemID);
		Leaf.SubfoldersRead = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ArticleTreeOnActivateRow(Item)
	
	CurrentData = Items.ArticleTree.CurrentData;
	ChoiceAvailable = (CurrentData <> Undefined)
		And Not CurrentData.IsFolder
		And Not ReadOnly;
	If ChoiceAvailable Then
		TheStructureOfTheSearch = New Structure("CFItemID", CurrentData.CFItemID);
		ChoiceAvailable = ChoiceAvailable
			And (SelectedArticles.FindRows(TheStructureOfTheSearch).Count() = 0);
	EndIf;
	
	Items.MoveToRight.Enabled = ChoiceAvailable;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedArticles

&AtClient
Procedure SelectedArticlesOnActivateRow(Item)
	
	CurrentData = Items.SelectedArticles.CurrentData;
	ChoiceAvailable = (CurrentData <> Undefined)
		And Not ReadOnly;
	Items.MoveLeft.Enabled = ChoiceAvailable;
	
EndProcedure

&AtClient
Procedure SelectedArticlesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field <> Items.SelectedArticlesCFItem Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	CurrentData = Items.SelectedArticles.CurrentData;
	If CurrentData <> Undefined
		And Not ReadOnly Then
		DeleteArticleFromSelectedOnes(CurrentData);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveLeft(Command)
	
	CurrentData = Items.SelectedArticles.CurrentData;
	If CurrentData <> Undefined Then
		DeleteArticleFromSelectedOnes(CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveToRight(Command)
	
	CurrentData = Items.ArticleTree.CurrentData;
	If CurrentData <> Undefined
		And Not CurrentData.IsFolder Then
		AddArticleToSelectedOnes(CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure Done(Command)
	
	Result = New Array;
	For Each String In SelectedArticles Do
		ResultString1 = New Structure;
		ResultString1.Insert("CFItem", String.CFItem);
		ResultString1.Insert("CFItemID", String.CFItemID);
		ResultString1.Insert("CFItemType", String.CFItemType);
		ResultString1.Insert("Sum", String.Sum);
		ResultString1.Insert("VATAmount", String.VATAmount);
		Result.Add(ResultString1);
	EndDo;
	
	Close(Result);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInArticleTree(TreeBranch1, FolderID_ = "")
	
	TreeBranch1.Clear();
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	FilterConditions = ListOfConditions.conditions; // XDTOList
	
	If ValueIsFilled(FolderID_) Then
		
		ParentID__ = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			FolderID_,
			"DMCashFlowItem");
		
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "Parent";
		Condition.value = ParentID__;
		If Condition.Properties().Get("comparisonOperator") <> Undefined Then
			Condition.comparisonOperator = "=";
		EndIf;
		
		FilterConditions.Add(Condition);
		
	EndIf;
	
	Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMCashFlowItem",
		ListOfConditions);
	
	For Each Item In Result.items Do
		If Item.IsSet("parentID") Then
			IDOfElementSParent = Item.parentID.ID;
		Else
			IDOfElementSParent = "";
		EndIf;
		If FolderID_ = IDOfElementSParent Then
			NewRow = TreeBranch1.Add();
			FillInArticleTreeElement(NewRow, Item);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInArticleTreeElement(NewRow, Item)
	
	NewRow.CFItem = Item.object.name;
	NewRow.CFItemID = Item.object.objectID.ID;
	NewRow.CFItemType = Item.object.objectID.type;
	NewRow.IsFolder = Item.isFolder;
	
	If Item.isFolder Then
		NewRow.PictureNumber = 0;
	Else
		NewRow.PictureNumber = IntegrationWith1CDocumentManagementCore.IndexOfImageOfCatalogElement();
	EndIf;
	
	If Item.isFolder Then
		NewRow.SubfoldersRead = False;
		NewRow.GetItems().Add();
	Else
		NewRow.SubfoldersRead = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInArticleTreeById(IDOfTreeElement, FolderID_)
	
	Leaf = ArticleTree.FindByID(IDOfTreeElement);
	
	If Leaf = Undefined Then
		Return;
	EndIf;
	
	FillInArticleTree(Leaf.GetItems(), Leaf.CFItemID);
	
EndProcedure

// Adds an article to the selected list, updating the general list.
//
// Parameters:
//   RowSelected - FormDataCollectionItem - the row selected to be added.
//
&AtClient
Procedure AddArticleToSelectedOnes(RowSelected)
	
	TotalAmount_5 = 0; TotalVATAmount = 0;
	For Each String In SelectedArticles Do
		If String.CFItemID = RowSelected.CFItemID Then
			Return;
		EndIf;
		TotalAmount_5 = TotalAmount_5 + String.Sum;
		TotalVATAmount = TotalVATAmount + String.VATAmount;
	EndDo;
	
	String = SelectedArticles.Add();
	String.CFItem = RowSelected.CFItem;
	String.CFItemID = RowSelected.CFItemID;
	String.CFItemType = RowSelected.CFItemType;
	If TotalAmount_5 < Sum Then
		String.Sum = Sum - TotalAmount_5;
		If TotalVATAmount < VATAmount Then
			String.VATAmount = VATAmount - TotalVATAmount;
		EndIf;
	EndIf;
	
	UpgradeBasement();
	
EndProcedure

// Deletes an article from the selected list, updating the general list.
//
// Parameters:
//   RowSelected - FormDataCollectionItem - the row selected for deletion.
//
&AtClient
Procedure DeleteArticleFromSelectedOnes(RowSelected)
	
	For Each String In SelectedArticles Do
		If String.CFItemID = RowSelected.CFItemID Then
			SelectedArticles.Delete(String);
			UpgradeBasement();
			Break;
		EndIf;
	EndDo;
	
EndProcedure

// Updates the totals in the basement.
//
&AtClient
Procedure UpgradeBasement()
	
	TotalAmount_5 = 0;
	TotalVATAmount = 0;
	For Each String In SelectedArticles Do
		TotalAmount_5 = TotalAmount_5 + String.Sum;
		TotalVATAmount = TotalVATAmount + String.VATAmount;
	EndDo;
	Items.SelectedArticlesSum.FooterText = Format(TotalAmount_5, "NFD=2; NG=3,0");
	Items.SelectedArticlesVATAmount.FooterText = Format(TotalVATAmount, "NFD=2; NG=3,0");
	
EndProcedure

#EndRegion