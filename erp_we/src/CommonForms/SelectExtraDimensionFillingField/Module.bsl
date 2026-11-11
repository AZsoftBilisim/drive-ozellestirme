
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ExtDimensionType = Parameters.ExtDimensionType;
	AddressOfDataCompositionSchema = Parameters.AddressOfDataCompositionSchema;
	CurrentExpression = Parameters.CurrentExpression;
	HideAdditionalAttributes = Parameters.HideAdditionalAttributes;
	
	ValueType = Common.ObjectAttributeValue(ExtDimensionType, "ValueType");
	
	MaximumRowExpansionLevel = 2;
	FinancialReportingServer.FillInAvailableFieldsAccordingToDataLayoutScheme(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectionTreeBeforeExpand(Item, String, Cancel)
	
	CurrentData = SelectionTree.FindByID(String);
	If CurrentData.ExpandToAttributes
		And Not CurrentData.SubordinateRowsExpanded Then
		// If there are subordinate details and the details of the next level have not been received for them.
		ExpandSubordinateRowsOfOperandTree(String);
	EndIf;
	
EndProcedure

&AtServer
Procedure ExpandSubordinateRowsOfOperandTree(IDOfCurRowOfOperandTree)
	
	ProcessingOfFormulas.ExpandOperandStringOfFormTree(SelectionTree,
		IDOfCurRowOfOperandTree,
		MaximumRowExpansionLevel);
	
	// Processing restrictions by value type or identifier add.the props on the form.
	CurrentData = SelectionTree.FindByID(IDOfCurRowOfOperandTree);
	For Each AddedRow In CurrentData.GetItems() Do
		If AddedRow.OperandSelectionAllowed Then
			AddedRow.OperandSelectionAllowed = FinancialReportingServer.SuitableSelectionField(AddedRow,
				ValueType, AdditionalPropertyID);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectionTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ProcessSelection(RowSelected);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	ProcessSelection(Items.SelectionTree.CurrentRow);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectionTreePresentation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectionTreeId.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectionTreeValueType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectionTree.OperandSelectionAllowed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OutdatedListTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectionTree.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectionTreePresentation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectionTreeId.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectionTreeValueType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectionTree.TreeItemType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "AdditionalAttribute";
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("HideAdditionalAttributes");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtClient
Procedure ProcessSelection(RowSelected)
	
	TreeRow = SelectionTree.FindByID(RowSelected);
	If Not TreeRow.OperandSelectionAllowed Then
		Return;
	EndIf;
	
	NotifyChoice(TreeRow.FullRowID);
	
EndProcedure


#EndRegion