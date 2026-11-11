#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SelectedStandartOperations.Load(GetFromTempStorage(Parameters.AddressInTempStorage));
	FillInTreeOfTypicalOperations();
	SetConditionalAppearance();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTreeTypicalOperations

&AtClient
Procedure TreeTypicalOperationsTaggingTaggingWhenChanging(Item)
	
	CurrentData = CurrentItem.CurrentData;
	MarkNestedElementsRecursively(CurrentData);
	
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
	MarkElementsByTreeRows(TreeTypicalOperations.GetItems(), True);
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	MarkElementsByTreeRows(TreeTypicalOperations.GetItems(), False);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeTypicalOperationsCheck.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TreeTypicalOperations.Enabled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Enabled", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeTypicalOperationsStandartOperation.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeTypicalOperationsChartOfAccounts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TreeTypicalOperations.Enabled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableData);
	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtServer
Procedure SetVisibilityAvailability(ThereAreNotAvailableOnes)
	
	If ThereAreNotAvailableOnes Then
		Items.TreeTypicalOperations.ToolTip = NStr("vi = 'Để có thể sử dụng các phần tử, cần bật sử dụng kết xuất đối với hệ thống tài khoản tương ứng';
													|ru = 'Для доступности элементов необходимо включить выгрузку у соответсвующих планов счетов';
													|en = 'To make the items available, enable the export for the corresponding charts of accounts'; fa = 'برای در دسترس قرار دادن اقلام، خروج اطلاعات را برای سرفصل حساب‌های مربوطه فعال کنید';
													|it = 'Per accedere agli elementi è necessario attivare l''upload presso i piani dei conti corrispondenti';
													|pl = 'Dla dostępności elementów należy włączyć eksport odpowiednich planów kont';
													|tr = 'Öğelerin kullanılabilir olması için ilgili hesap planlarının yüklenmesini etkinleştirmeniz gerekir.'");
		Items.TreeTypicalOperations.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
	Else
		Items.TreeTypicalOperations.ToolTip = "";
		Items.TreeTypicalOperations.ToolTipRepresentation = ToolTipRepresentation.None;
	EndIf;
	
EndProcedure

&AtServer
Procedure DoneServer(Address)
	UpdateCollectionOfSelectedTypesOfFinancialReports();
	Address = PutToTempStorage(SelectedStandartOperations.Unload(), UUID)
EndProcedure

&AtServer
Procedure FillInTreeOfTypicalOperations()
	
	DataCompositionSchema = DataProcessors.FinancialAccountingModelExportAndImportWizard.GetTemplate("StandardTransactionsHierarchy");
	
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
		ThereAreNotAvailableOnes = False;
		MarkItemsBySelectedItems(Tree.Rows, ThereAreNotAvailableOnes);
		SetVisibilityAvailability(ThereAreNotAvailableOnes);
		ValueToFormAttribute(Tree, "TreeTypicalOperations");
	EndIf;
	
EndProcedure

&AtServer
Procedure MarkItemsBySelectedItems(Rows, ThereAreNotAvailableOnes)
	
	For Each String In Rows Do
		
		Filter = New Structure;
		Filter.Insert("StandartOperation", String.StandartOperation);
		FoundRows = SelectedStandartOperations.FindRows(Filter);
		For Each FoundRow In FoundRows Do
			String.Check = FoundRow.Check;
			String.ChartOfAccounts = FoundRow.ChartOfAccounts;
			String.Enabled = FoundRow.Enabled;
			If Not FoundRow.Enabled Then
				ThereAreNotAvailableOnes = True;
			EndIf;
		EndDo;
		
		MarkItemsBySelectedItems(String.Rows, ThereAreNotAvailableOnes);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SelectedTreeElementsInList(Var_Items)

	For Each Item In Var_Items Do
		NewRow = SelectedStandartOperations.Add();
		NewRow.StandartOperation = Item.StandartOperation;
		NewRow.Check = Item.Check;
		NewRow.ChartOfAccounts = Item.ChartOfAccounts;
		NewRow.Enabled = Item.Enabled;
		
		SelectedTreeElementsInList(Item.GetItems());
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateCollectionOfSelectedTypesOfFinancialReports()
	
	SelectedStandartOperations.Clear();
	SelectedTreeElementsInList(TreeTypicalOperations.GetItems());
	
EndProcedure

&AtClient
Procedure MarkElementsByTreeRows(Rows, Check)
	
	For Each String In Rows Do
		
		If String.Enabled Then
			String.Check = Check;
		EndIf;

		MarkElementsByTreeRows(String.GetItems(), Check);

	EndDo;
	
EndProcedure

&AtClient
Procedure MarkNestedElementsRecursively(TreeItem)
	
	NestedItems = TreeItem.GetItems();
	
	For Each NestedItem In NestedItems Do
		If NestedItem.Enabled Then
			NestedItem.Check = TreeItem.Check;
		EndIf;
		MarkNestedElementsRecursively(NestedItem);
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
