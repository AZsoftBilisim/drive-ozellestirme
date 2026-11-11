#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	HideInappropriateValues = Parameters.HideInappropriateValues;
	
	TransactionSettings = Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings(
		Parameters.PostingGenerationSetting);
	
	Common.FillFormDataTreeItemCollection(
		TreeOfAccountingObjects.GetItems(),
		Enums.DeleteFinancialAccountingObjects.TreeOfAccountingObjects(TransactionSettings, False));
	
	AccumulationRegistersMetadata = Metadata.AccumulationRegisters;
	
	For Each Var_Group In TreeOfAccountingObjects.GetItems() Do
		For Each AccountingObjectLine In Var_Group.GetItems() Do
			If AccountingObjectLine.AccountingObject = Parameters.CurrentRow Then
				Items.TreeOfAccountingObjects.CurrentRow = AccountingObjectLine.GetID();
			EndIf;
			
			RegisterMetadata = AccumulationRegistersMetadata.Find(AccountingObjectLine.DataSource);
			If RegisterMetadata <> Undefined Then
				AccountingObjectLine.DataSourcePresentation = RegisterMetadata.Synonym;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#Region EventHandlersFormTablesAccountingObjectTree

&AtClient
Procedure TreeOfAccountingObjectsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = TreeOfAccountingObjects.FindByID(RowSelected);
	If CurrentData.IsFolder Then
		Return;
	EndIf;
	
	NotifyChoice(CurrentData.AccountingObject);
	
EndProcedure

&AtClient
Procedure TreeOfAccountingObjectsValueChoice(Item, Value, StandardProcessing)
	
	CurrentData = TreeOfAccountingObjects.FindByID(Value);
	If CurrentData.IsFolder Then
		Return;
	EndIf;
	
	NotifyChoice(CurrentData.AccountingObject);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfAccountingObjects.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfAccountingObjectsIsFolder.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfAccountingObjectsPresentation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfAccountingObjectsDataSourcePresentation.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TreeOfAccountingObjects.ImproperValues");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("HideInappropriateValues");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

#EndRegion
