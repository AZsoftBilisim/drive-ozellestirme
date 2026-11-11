#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SelectedItemsOfAssetsLiabilities.Load(GetFromTempStorage(Parameters.AddressInTempStorage));
	FillInAssetLiabilityArticleTree();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTreeOfTypesOfFinancialReports

&AtClient
Procedure TreeOfTypesOfFinancialReportsCheckOnChange(Item)
	
	CurrentData = CurrentItem.CurrentData;
	MarkNestedItemsRecursively(CurrentData);
	
	If CurrentData.Check Then
		MarkParentsInTree(CurrentData);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	Address = "";
	DoneServer(Address);
	Close(Address);
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	MarkElementsByTreeRows(AssetLiabilityArticleTree.GetItems(), True);
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	MarkElementsByTreeRows(AssetLiabilityArticleTree.GetItems(), False);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DoneServer(Address)
	UpdateCollectionOfSelectedTypesOfFinancialReports();
	Address = PutToTempStorage(SelectedItemsOfAssetsLiabilities.Unload(), UUID)
EndProcedure

&AtServer
Procedure FillInAssetLiabilityArticleTree()
	
	DataCompositionSchema = DataProcessors.FinancialAccountingModelExportAndImportWizard.GetTemplate("AssetsLiabilitiesItemsHierarchy");
	
	TemplateComposer = New DataCompositionTemplateComposer;
	Template = TemplateComposer.Execute(DataCompositionSchema, DataCompositionSchema.DefaultSettings,,,
		Type("DataCompositionValueCollectionTemplateGenerator"));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Template);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	Tree = New ValueTree;
	OutputProcessor.SetObject(Tree);
	
	OutputProcessor.Output(CompositionProcessor);
	
	If Tree.Rows.Count() Then
		MarkItemsBySelectedItems(Tree.Rows);
		ValueToFormAttribute(Tree, "AssetLiabilityArticleTree");
	EndIf;
	
EndProcedure

&AtServer
Procedure MarkItemsBySelectedItems(Rows)
	
	For Each String In Rows Do
		
		Filter = New Structure;
		Filter.Insert("AssetAndLiabilityItem", String.AssetAndLiabilityItem);
		FoundRows = SelectedItemsOfAssetsLiabilities.FindRows(Filter);
		For Each FoundRow In FoundRows Do
			String.Check = FoundRow.Check;
		EndDo;
		
		MarkItemsBySelectedItems(String.Rows);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SelectedTreeElementsInList(Var_Items)

	For Each Item In Var_Items Do
		NewRow = SelectedItemsOfAssetsLiabilities.Add();
		NewRow.AssetAndLiabilityItem = Item.AssetAndLiabilityItem;
		NewRow.Check = Item.Check;
		
		SelectedTreeElementsInList(Item.GetItems());
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateCollectionOfSelectedTypesOfFinancialReports()
	
	SelectedItemsOfAssetsLiabilities.Clear();
	SelectedTreeElementsInList(AssetLiabilityArticleTree.GetItems());
	
EndProcedure

&AtClient
Procedure MarkElementsByTreeRows(Rows, Check)
	
	For Each String In Rows Do
		String.Check = Check;
		MarkElementsByTreeRows(String.GetItems(), Check);
	EndDo;
	
EndProcedure

&AtClient
Procedure MarkNestedItemsRecursively(TreeItem)
	
	NestedItems = TreeItem.GetItems();
	
	For Each NestedItem In NestedItems Do
		NestedItem.Check = TreeItem.Check;
		MarkNestedItemsRecursively(NestedItem);
	EndDo;
	
EndProcedure

&AtClient
Procedure MarkParentsInTree(TreeItem)
	
	ParentRow = TreeItem.GetParent();
	
	If ParentRow <> Undefined Then
		ParentRow.Check = TreeItem.Check;
		MarkParentsInTree(ParentRow);
	EndIf;
		
EndProcedure

#EndRegion
