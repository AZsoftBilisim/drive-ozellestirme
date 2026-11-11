#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SelectedTypesOfFinancialStatements.Load(GetFromTempStorage(Parameters.AddressInTempStorage));
	FillInTreeOfTypesOfFinancialReports();
	SetConditionalAppearance();
	
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
	MarkElementsByTreeRows(TreeOfTypesOfFinancialReports.GetItems(), True);
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	MarkElementsByTreeRows(TreeOfTypesOfFinancialReports.GetItems(), False);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = Items.TreeOfTypesOfFinancialReportsCheck.Name;

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfTypesOfFinancialReportsCheck.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TreeOfTypesOfFinancialReports.RelatedSelection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Enabled", False);

	//
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = Items.TreeOfTypesOfFinancialReportsFinancialReportType.Name;

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TreeOfTypesOfFinancialReportsFinancialReportType.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TreeOfTypesOfFinancialReports.RelatedSelection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableData);
	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtServer
Procedure SetVisibilityAvailability(ThereIsRelatedSelection)
	
	If ThereIsRelatedSelection Then
		
		Items.TreeOfTypesOfFinancialReports.ToolTip = NStr("vi = 'Màu xám là các phần tử có bộ lọc phụ thuộc, không nên bỏ chọn chúng';
															|ru = 'Серым цветом выделены элементы с зависимым отбором, отменить их выбор нельзя';
															|en = 'Items with dependent filter are highlighted in gray, you cannot unselect them'; fa = 'Items with dependent filter are highlighted in gray, you cannot unselect them';
															|it = 'Gli elementi con filtro dipendente sono evidenziati di grigio, non è possibile annullare la loro selezione';
															|pl = 'Szarym kolorem są podświetlone elementy z filtrem zależnym, wybór tych elementów nie można anulować';
															|tr = 'Bağımlı seçime sahip öğeler gri renkle vurgulanır, onların filtresini kaldıramazsınız'");
		Items.TreeOfTypesOfFinancialReports.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		
	Else
		
		Items.TreeOfTypesOfFinancialReports.ToolTip = "";
		Items.TreeOfTypesOfFinancialReports.ToolTipRepresentation = ToolTipRepresentation.None;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DoneServer(Address)
	UpdateCollectionOfSelectedTypesOfFinancialReports();
	Address = PutToTempStorage(SelectedTypesOfFinancialStatements.Unload(), UUID)
EndProcedure

&AtServer
Procedure FillInTreeOfTypesOfFinancialReports()
	
	DataCompositionSchema = DataProcessors.FinancialAccountingModelExportAndImportWizard.GetTemplate("FinancialReportKindsHierarchy");
	
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
		ThereIsRelatedSelection = False;
		MarkItemsBySelectedItems(Tree.Rows, ThereIsRelatedSelection);
		SetVisibilityAvailability(ThereIsRelatedSelection);
		ValueToFormAttribute(Tree, "TreeOfTypesOfFinancialReports");
	EndIf;
	
EndProcedure

&AtServer
Procedure MarkItemsBySelectedItems(Rows, ThereIsRelatedSelection)
	
	For Each String In Rows Do
		
		Filter = New Structure;
		Filter.Insert("FinancialReportType", String.FinancialReportType);
		FoundRows = SelectedTypesOfFinancialStatements.FindRows(Filter);
		For Each FoundRow In FoundRows Do
			String.Check = FoundRow.Check;
			String.Software = FoundRow.Software;
			String.RelatedSelection = FoundRow.RelatedSelection;
			If FoundRow.RelatedSelection Then
				ThereIsRelatedSelection = True;
			EndIf;
		EndDo;
		
		MarkItemsBySelectedItems(String.Rows, ThereIsRelatedSelection);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SelectedTreeElementsInList(Var_Items)

	For Each Item In Var_Items Do
		NewRow = SelectedTypesOfFinancialStatements.Add();
		NewRow.FinancialReportType = Item.FinancialReportType;
		NewRow.Check = Item.Check;
		NewRow.Software = Item.Software;
		NewRow.RelatedSelection = Item.RelatedSelection;
		
		SelectedTreeElementsInList(Item.GetItems());
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateCollectionOfSelectedTypesOfFinancialReports()
	
	SelectedTypesOfFinancialStatements.Clear();
	SelectedTreeElementsInList(TreeOfTypesOfFinancialReports.GetItems());
	
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
		If Not NestedItem.RelatedSelection Then
			NestedItem.Check = TreeItem.Check;
		EndIf;
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
