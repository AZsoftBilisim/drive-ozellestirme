
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Parameters.Property("Mode", Mode);
	Parameters.Property("TSName", TSName);
	Parameters.Property("AddressInStorage", AddressInStorage);
	Parameters.Property("CurrentRef", CurrentRef);
	Parameters.Property("CurrentOperationId", CurrentOperationId);
	
	AdditionalAttributes = Undefined; // Array of Structure
	If Parameters.Property("AdditionalAttributes", AdditionalAttributes)
		And AdditionalAttributes.UBound() <> -1 Then
		
		AttributesToBeAdded = New Array;
		For Each Attribute In AdditionalAttributes Do
			AttributesToBeAdded.Add(
				New FormAttribute(Attribute.Name, Attribute.Type, "Tree"));
		EndDo;
		ChangeAttributes(AttributesToBeAdded);
		
		For Each Attribute In AdditionalAttributes Do
			NewItem = Items.Add(
				Attribute.Name,
				Type("FormField"),
				Items.Tree);
			NewItem.Type = FormFieldType.LabelField;
			NewItem.Title = Attribute.Title;
			NewItem.DataPath = "Tree." + Attribute.Name;
		EndDo;
	EndIf;
	
	FillInElementTree();
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TreeItems = Tree.GetItems();
	
	If TreeItems.Count() = 1 Then
		Items.Tree.Expand(TreeItems[0].GetID());
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTree

&AtClient
Procedure TreeValueChoice(Item, Value, StandardProcessing)
	
	CurrentData = Items.Tree.CurrentData;
	Department = Undefined;
	
	Result = ProductionProcessEditorClientServer.StructureOfValueOfProductionProcessElementConstructor();
	
	If CurrentData.ItemKind = ProductionProcessEditorClientServer.TypeOfStageElement() Then
		Result.Stage = CurrentData.Ref;
		Result.StagePresentation = CurrentData.Description;
		Department = CurrentData.Department;
	ElsIf CurrentData.ItemKind = ProductionProcessEditorClientServer.TypeOfElementOfOperation() Then
		ParentElement = CurrentData.GetParent();
		If ParentElement <> Undefined Then
			ElementStage = ?(ParentElement.ItemKind = ProductionProcessEditorClientServer.TypeOfStageElement(),
				ParentElement,
				ParentElement.GetParent());
			If ElementStage <> Undefined Then
				Result.Stage = ElementStage.Ref;
				Result.StagePresentation = ElementStage.Description;
				Department = ElementStage.Department;
			EndIf;
		EndIf;
		Result.Operation = CurrentData.Ref;
		Result.OperationPresentation = CurrentData.Description;
		Result.OperationID = CurrentData.OperationID;
		Result.ProductionOperation = CurrentData.ProductionOperation;
	EndIf;
	
	Result.Insert("Mode", Mode);
	Result.Insert("AddIntermediateReleaseOnSelection", CurrentData.AddIntermediateReleaseOnSelection);
	Result.Insert("Department", Department);
	
	NotifyChoice(Result);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowAllItems(Command)
	
	Items.ShowAllForm.Check = Not Items.ShowAllForm.Check;
	
	FillInElementTree(False);
	
EndProcedure

&AtClient
Procedure CollapseTree(Command)
	
	ConvolutionTree(Tree, True);
	
EndProcedure

&AtClient
Procedure ExpandTree(Command)
	
	ConvolutionTree(Tree, False);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	If Mode = "ReleaseStage" Then
		
		If Parameters.Property("Products")
				And Parameters.Property("Characteristic")
				And ValueIsFilled(Parameters.Products) Then
			Title = StrTemplate(NStr("vi = 'Các công đoạn sản xuất chi tiết %1';
									|ru = 'Этапы производства изделия %1';
									|en = 'Manufacturing stages of %1 product'; fa = 'Manufacturing stages of %1 product';
									|it = 'Fasi di produzione del prodotto %1';
									|pl = 'Etapy produkcji wyrobu %1';
									|tr = '%1 nihai ürün üretim aşamaları'"),
				ProductsClientServer.ProductPresentation(Parameters.Products, Parameters.Characteristic));
		EndIf;
		
		Items.ShowAllForm.Visible = Tree.GetItems().Count() > 0;
		
		Items.WoodPackaging.Visible = True;
		Items.TreeCount.Visible = True;
	
	EndIf;
	
	ThereAreOperations = False;
	ThereAreOperations = TreeParameters.ItemsKinds.Find(ProductionProcessEditorClientServer.TypeOfElementOfOperation()) <> Undefined;
	If Not ThereAreOperations Then
		Items.TreeWorkCenter.Visible = False;
		Items.TreeGroupDivisionWorkCenter.Title = Items.TreeDepartment.Title;
	EndIf;
	
	If TreeParameters.ItemsKinds.Count() < 2 Then
		Items.TreeGroupCollapseExpand.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Tree.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.QuantityAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Mode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "ReleaseStage";
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeCount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.CalculationByFormula");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<theo công thức>';
													|ru = '<по формуле>';
													|en = '<using formula>'; fa = '<using formula>';
													|it = '<secondo la formula>';
													|pl = '<wg formuły>';
													|tr = '<formüle göre>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TreeNumber.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TreeTheNumberOfTheNextOne.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = ProductionProcessEditorClientServer.TypeOfElementOfOperation();
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.TreeWorkCenter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tree.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = ProductionProcessEditorClientServer.TypeOfElementOfOperation();
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
EndProcedure

&AtServer
Procedure FillInElementTree(Initialize = True)
	
	If Initialize Then
		TreeParameters = New Structure();
		TreeParameters.Insert("ItemsKinds", New Array);
	EndIf;
	
	If IsTempStorageURL(AddressInStorage) Then
		
		DataToFill = GetFromTempStorage(AddressInStorage);
		
		If TypeOf(DataToFill) = Type("ValueTree") Then
			StringsSources = DataToFill.Rows;
		Else
			StringsSources = DataToFill;
			If Initialize Then
				Items.ShowAllForm.Check = StringsSources.FindRows(New Structure("QuantityAvailable", True)).UBound() = -1;
			EndIf;
		EndIf;
		
	Else
		Return;
	EndIf;
	
	RecipientRows = Tree.GetItems();
	RecipientRows.Clear();
	
	FillInRowsOfElementTree(StringsSources, RecipientRows);
	
EndProcedure

&AtServer
Procedure FillInRowsOfElementTree(StringsSources = Undefined, RecipientRows = Undefined)
	
	ItemsKinds = TreeParameters.ItemsKinds; // Array
	
	For Each String In StringsSources Do
		
		If Not Items.ShowAllForm.Check
				And Not String.QuantityAvailable Then
			Continue;
		EndIf;
		
		NewRow = RecipientRows.Add();
		FillPropertyValues(NewRow, String);
		
		If TypeOf(String) = Type("ValueTreeRow") Then
			FillInRowsOfElementTree(String.Rows, NewRow.GetItems());
		Else
			NewRow.ItemKind = ProductionProcessEditorClientServer.TypeOfStageElement();
			NewRow.Picture = PictureLib.ManufacturingProcessProductionStage;
		EndIf;
		
		If NewRow.Ref = CurrentRef
			And (CurrentOperationId = 0
				Or NewRow.OperationID = CurrentOperationId) Then
			Items.Tree.CurrentRow = NewRow.GetID();
		EndIf;
		
		ItemsKinds.Add(NewRow.ItemKind);
		
	EndDo;
	
	TMCommonUse.DeleteDuplicateElementsFromArray(TreeParameters.ItemsKinds);
	
EndProcedure

&AtClient
Procedure ConvolutionTree(RowsCollection, GroupBy = True)
	
	For Each TreeRow In RowsCollection.GetItems() Do
		If GroupBy Then
			ConvolutionTree(TreeRow, GroupBy);
			Items.Tree.Collapse(TreeRow.GetID());
		Else
			Items.Tree.Expand(TreeRow.GetID(), True);
		EndIf;
	EndDo;

EndProcedure

#EndRegion