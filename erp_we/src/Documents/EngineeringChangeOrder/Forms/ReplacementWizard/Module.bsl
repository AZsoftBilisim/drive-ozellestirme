
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ListOfProperties = "OneToOneReplacement, Material, ItemVariantOfMaterial, Resolution, ReplacementPriority, RoleOfAnalogues, Stage";
	FillPropertyValues(ThisObject, Parameters, ListOfProperties);
	
	SelectionOfInterchangeableAnalogues = (RoleOfAnalogues = Enums.SubstituteRoles.InterchangeableSubstitute);
	
	If ValueIsFilled(ReplacementPriority)
	   And Not GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		ReplacementPriority = Enums.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials;
	EndIf;
	
	SetConditionalAppearance();
	
	Items.FormPages.CurrentPage = Items.PageOfMaterialsAndAnalogues;
	
	If ValueIsFilled(Stage) Then
		
		ModeFromDocument = True;
		TableFromDocument = GetFromTempStorage(Parameters.GoodsTableAddress);
		GoodsFromDocument.Load(TableFromDocument);
		
		InventoryTable = ?(IsTempStorageURL(Parameters.InventoryAllocation), 
							GetFromTempStorage(Parameters.InventoryAllocation), 
							Undefined);
							
		If InventoryTable <> Undefined Then
		
			TableRowFilter = New Structure("ThisIsRemainder, ThisIsDocumentWarehouse", True, True);
			RowsOfInventoryTables = InventoryTable.FindRows(TableRowFilter);
			
			For Each InventoryTableRow In RowsOfInventoryTables Do
			
				RemainderLine_ = RemnantsOfAnalogues.Add();
				FillPropertyValues(RemainderLine_, InventoryTableRow, "Products, Characteristic, Warehouse, Purpose");
				RemainderLine_.AvailableForInventoryAllocation = InventoryTableRow.Count;
			
			EndDo;
		
		EndIf;
	
	EndIf;
	
	SetHyperlinkOfMaterialBeingReplaced();
	SetItemsVisibility();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateStageDataOnForm();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductionOrderSelectionOnChange(Item)
	SetLineSelectionStages();
	ProcessDataWhenSettingSelection();
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	SetLineSelectionStages();
	ProcessDataWhenSettingSelection();
EndProcedure

&AtClient
Procedure BillOfMaterialsOnChange(Item)
	SetLineSelectionStages();
	ProcessDataWhenSettingSelection();
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	SetLineSelectionStages();
	ProcessDataWhenSettingSelection();
EndProcedure

&AtClient
Procedure ProductPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenForm("Catalog.Products.Form.ItemForm", New Structure("Key", Material), ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStages

&AtClient
Procedure StagesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "StagesOrderPresentation" Then
	
		ShowValue(, Items.Stages.CurrentData.Stage);
		
	ElsIf Field.Name = "StagesProducts" Then
		
		CurrentData = Items.Stages.CurrentData;
		OpenForm("Catalog.Products.Form.ItemForm", New Structure("Key", CurrentData.Products), ThisObject);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure StagesOnActivateRow(Item)
	
	If ModeFromDocument Then
	
		CurrentData = Items.Stages.CurrentData;
		
		If CurrentData <> Undefined Then
		
			If CurrentLine_Number <> CurrentData.LineNumberDocument Then
		
				SearchForStrings = New Structure("DisplayPermission", True);
				For Each SpecificationRow In Substitutes.FindRows(SearchForStrings) Do
					SpecificationRow.DisplayPermission = False;
					SpecificationRow.Count = 0;
				EndDo;
				
				MaterialSearch = New Structure("Products, Characteristic, ThisIsASubstitute");
				MaterialSearch.ThisIsASubstitute = False;
				FillPropertyValues(MaterialSearch, CurrentData);
				
				SearchForStrings = New Structure("Resolution, ConnectionKey, ThisIsASubstitute", Undefined, 0, True);
				BalancesOfAnalogsMatching = MatchingBalances(CurrentData.Warehouse, CurrentData.Purpose);
				
				For Each SpecificationRow In Substitutes.FindRows(MaterialSearch) Do
					
					SearchForStrings.Resolution = SpecificationRow.Resolution;
					SearchForStrings.ConnectionKey = SpecificationRow.ConnectionKey;
					For Each SpecificationRow In Substitutes.FindRows(SearchForStrings) Do
					
						SpecificationRow.DisplayPermission = True;
						SpecificationRow.Warehouse = CurrentData.Warehouse;
						
						SpecificationRow.WarehouseStockBalance = BalanceOfAnalogFromMatch(
							BalancesOfAnalogsMatching,
							SpecificationRow.Products,
							SpecificationRow.Characteristic);
							
						SpecificationRow.IsBalance = SpecificationRow.WarehouseStockBalance > 0;
						
						SpecificationRow.Count = AmountOfAnalogUsed(
							SpecificationRow.Resolution,
							SpecificationRow.ConnectionKey,
							SpecificationRow.Products,
							SpecificationRow.Characteristic,
							CurrentData.LineNumberDocument);
						
					EndDo;
					
				EndDo;
				
				SetRowSelection();
			
			EndIf;
			
			CurrentLine_Number = CurrentData.LineNumberDocument;	
		
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StagesBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure StagesToReplaceOnChange(Item)
	
	ClearMessages();
	
	If Not ModeFromDocument Then
	
		CurrentData = Items.Stages.CurrentData;
		
		NumberOfSets = ProductionClientServer.CoefficientByStandard(
			False, CurrentData.ToReplace - CurrentData.ToBeReplacedBeforeChange, CurrentData.NormativeStandard, CurrentData.PackageData);
		
		If NumberOfSets <> 0 Then
			ProcessManualChange(CurrentData.Stage, CurrentData.ConnectionKey, NumberOfSets);
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure StagesFlagOnChange(Item)
	
	If Not ModeFromDocument Then
	
		CurrentData = Items.Stages.CurrentData;
		
		If CurrentData.Selected Then
			
			CurrentData.ToReplace = CurrentData.Total - CurrentData.Shipped;
			
		Else
			
			CurrentData.ToReplace = 0;
		
		EndIf;
		
		NumberOfSets = ProductionClientServer.CoefficientByStandard(
			False, CurrentData.ToReplace - CurrentData.ToBeReplacedBeforeChange, CurrentData.NormativeStandard, CurrentData.PackageData);
		
		If NumberOfSets <> 0 Then
			ProcessManualChange(CurrentData.Stage, CurrentData.ConnectionKey, NumberOfSets);
		EndIf;
	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReplacementTree

&AtClient
Procedure ReplacementTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "ReplacementTreeProducts" Then
		
		CurrentData = Items.ReplacementTree.CurrentData;
		OpenForm("Catalog.Products.Form.ItemForm", New Structure("Key", CurrentData.Products), ThisObject);
	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSubstitutes

&AtClient
Procedure SubstitutesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.SubstitutesWarehouseStockBalance  Then
		
		ZoomRatio = ConversionFactor_();
		
		If ZoomRatio > 0 Then
		
			ProcessSelectionOfAnalogues(ZoomRatio);
		
		EndIf;
		
	ElsIf Field = Items.SubstitutesProducts Then
		
		CurrentData = Items.Substitutes.CurrentData;
		OpenForm("Catalog.Products.Form.ItemForm", New Structure("Key", CurrentData.Products), ThisObject);
		
	ElsIf Field = Items.AnalogsResolution Then
		
		CurrentData = Items.Substitutes.CurrentData;
		ShowValue(, CurrentData.Resolution);

	EndIf;
	
EndProcedure

&AtClient
Procedure SubstitutesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure SubstitutesBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure SubstitutesOnStartEdit(Item, NewRow, Copy)
	AnalogsQuantityBeforeChange = Items.Substitutes.CurrentData.Count;
EndProcedure

&AtClient
Procedure SubstitutesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	CurrentData = Items.Substitutes.CurrentData;
	
	If Not CancelEdit And CurrentData.Count <> AnalogsQuantityBeforeChange Then
		
		ClearMessages();
		
		CurDataAnalogues = Items.Substitutes.CurrentData;
		CalculationCoefficient = ProductionClientServer.CoefficientByStandard(
			False,
			CurDataAnalogues.Count - AnalogsQuantityBeforeChange,
			CurDataAnalogues.NormativeStandard,
			CurDataAnalogues.PackageData);
		
		CheckPossibilityOfRecalculation(CalculationCoefficient, Cancel);
		
		If Not Cancel Then
			
			CurrentData.Count = AnalogsQuantityBeforeChange;
			ProcessSelectionOfAnalogues(CalculationCoefficient);
			AnalogsQuantityBeforeChange = CurrentData.Count;
			
		EndIf;
		
	Else
		
		CurrentData.Count = AnalogsQuantityBeforeChange;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SubstitutesOnEditEnd(Item, NewRow, CancelEdit)
	
	Items.Substitutes.SelectedRows.Clear();
	Items.Substitutes.SelectedRows.Add(Items.Substitutes.CurrentRow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Reread(Command)
	
	FillOutFormDataATServer();
	
EndProcedure

&AtClient
Procedure Replace_With_Analogues(Command)
	
	ClearMessages();

	ReplaceWithAnalogsAtServer();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction(False);
		OperationText = NStr("vi = 'Đang thay thế sang vật tư tương tự...';
							|ru = 'Выполняется замена на аналоги...';
							|en = 'Replacing with substitutes...'; fa = 'Replacing with substitutes...';
							|it = 'Replacing with substitutes...';
							|pl = 'Replacing with substitutes...';
							|tr = 'İkamelere değiştirme yapılıyor...'");
		SetUpWaitingInForm(ThisObject, True, OperationText);
		
	ElsIf ReReadDataAfterReplacement Then
		UpdateStageDataOnForm();
	Else
		SetUpWaitingInForm(ThisObject, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure Notice(Command)

	HandleFlagChange(True);
	
EndProcedure

&AtClient
Procedure ClearMark1(Command)

	HandleFlagChange(False);
	
EndProcedure

&AtClient
Procedure FillInUnsecured(Command)
	
	ClearMessages();
	FillInByStrategyAtServer(False);
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction(False);
		OperationText = NStr("vi = 'Đang điền số lượng không đảm bảo...';
							|ru = 'Выполняется заполнение необеспеченного количества...';
							|en = 'Filling in non-supplied quantity...'; fa = 'Filling in non-supplied quantity...';
							|it = 'Filling in non-supplied quantity...';
							|pl = 'Filling in non-supplied quantity...';
							|tr = 'Temin edilmeyen miktarın doldurulması gerçekleştiriliyor…'");
		SetUpWaitingInForm(ThisObject, True, OperationText);
	
	Else
		SetUpWaitingInForm(ThisObject, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInUnloaded(Command)
	
	ClearMessages();
	FillInByStrategyAtServer(True);
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction(False);
		OperationText = NStr("vi = 'Đang thực hiện điền số lượng chưa xuất...';
							|ru = 'Выполняется заполнение неотгруженного количества...';
							|en = 'Filling in unshipped quantity...'; fa = 'Filling in unshipped quantity...';
							|it = 'Filling in unshipped quantity...';
							|pl = 'Filling in unshipped quantity...';
							|tr = 'Teslim edilmemiş miktarın doldurulması gerçekleştiriliyor…'");
		SetUpWaitingInForm(ThisObject, True, OperationText);
	
	Else
		SetUpWaitingInForm(ThisObject, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInByAvailability(Command)
	
	ClearMessages();
	FillInByAvailabilityAtServer();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction(False);
		OperationText = NStr("vi = 'Đang điền theo tính khả dụng...';
							|ru = 'Выполняется заполнение по доступности...';
							|en = 'Filling in by availability...'; fa = 'Filling in by availability...';
							|it = 'Filling in by availability...';
							|pl = 'Filling in by availability...';
							|tr = 'Mevcudiyete göre doldurma gerçekleştiriliyor…'");
		SetUpWaitingInForm(ThisObject, True, OperationText);
	
	Else
		SetUpWaitingInForm(ThisObject, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure Next(Command)
	
	ReplacementResultAddress = CalculationResult1();
	
	Close(ReplacementResultAddress);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, 
		"ReplacementTreeCharacteristic",
		"ReplacementTree.ItemVariantsAreUsed");
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, 
		"StagesCharacteristic",
		"Stages.ItemVariantsAreUsed");
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, 
		"SubstitutesCharacteristic",
		"Substitutes.ItemVariantsAreUsed");
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Stages.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Stages.ToReplace");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Stages.Total");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	If ValueIsFilled(Stage) Then
	
		Item = ConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.StagesToReplace.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Stages.ToReplace");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
		ItemFilter.RightValue = 0;

		Item.Appearance.SetParameterValue("Font", StyleFonts.BoldFont);
	
	EndIf
	
EndProcedure

&AtServer
Procedure SetHyperlinkOfMaterialBeingReplaced()
	
	If ValueIsFilled(Material) And Not SelectionOfInterchangeableAnalogues Then
		ProductPresentation = ProductsClientServer.ProductPresentation(
			Material, ItemVariantOfMaterial);
	EndIf;
	
	Items.ProductPresentation.Visible = Not IsBlankString(ProductPresentation);
	
EndProcedure

&AtServer
Procedure SetItemsVisibility()
	
	Items.StagesProducts.Visible = Not OneToOneReplacement Or SelectionOfInterchangeableAnalogues;
	Items.StagesCharacteristic.Visible = Not OneToOneReplacement Or SelectionOfInterchangeableAnalogues;
	
	If ReplacementPriority <> Enums.RulesOfReplacingWithSubstitutes.EmptyRef() Then
		
		Items.AnalogsGroup.Visible = False;
		
	EndIf;
	
	If ValueIsFilled(Stage) Then
	
		Items.StagesOrderPresentation.Visible = False;
		Items.StagesFlag.Visible = False;
		Items.StagesShipped.Visible = False;
		Items.StagesSupplied.Visible = False;
		Items.StagesToReplace.HeaderPicture = New Picture;
		Items.StagesToReplace.ReadOnly = True;
		Items.ReplacementTreeGroup.Visible = False;
		Items.GroupFilters.Visible = False;
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		Items.StagesAvailable.Visible = False;
		Items.FillSubmenu.Visible = False;
		
		Title = StrReplace(NStr("vi = 'Trạng thái đảm bảo (thay thế sang vật tư tương tự): %OrderDocument%';
								|ru = 'Состояние обеспечения (замена на аналоги): %OrderDocument%';
								|en = 'Supply forecast (replacement with substitutes): %OrderDocument%'; fa = 'Supply forecast (replacement with substitutes): %OrderDocument%';
								|it = 'Supply forecast (replacement with substitutes): %OrderDocument%';
								|pl = 'Supply forecast (replacement with substitutes): %OrderDocument%';
								|tr = 'Tedarik durumu (İkame ile değiştirme): %OrderDocument%'"), "%OrderDocument%", String(Stage));
		Items.Next.DefaultButton = True;
		Items.Replace_With_Analogues.Visible = False;
		CommandBarLocation = FormCommandBarLabelLocation.None;
		Items.StagesCommandBar.Visible = False;
		
		Items.AnalogsResolutionPriorityOfReplacement.Visible = GetFunctionalOption("DynamicStructureOfProductionOrders");
	
	EndIf;

EndProcedure

&AtServer
Procedure SetRowSelection()

	RowFilter = New Structure;
	RowFilter.Insert("ThisIsASubstitute", True);
	RowFilter.Insert("DisplayPermission", True);
	
	Items.Substitutes.RowFilter = New FixedStructure(RowFilter);

EndProcedure

&AtServer
Procedure SetLineSelectionStages()

	Items.Stages.RowFilter = New FixedStructure(StageSelectionStructure());

EndProcedure

&AtServer
Function StageSelectionStructure()

	RowFilter = New Structure;
	
	If ValueIsFilled(ProductionOrderSelection) Then
	
		RowFilter.Insert("ProductionOrder", ProductionOrderSelection);
	
	EndIf;
	
	If ValueIsFilled(DepartmentFilter) Then
	
		RowFilter.Insert("Department", DepartmentFilter);
	
	EndIf;
	
	If ValueIsFilled(SpecificationSelection) Then
	
		RowFilter.Insert("BillOfMaterials", SpecificationSelection);
	
	EndIf;
	
	If ValueIsFilled(PurposeSelection) Then
	
		RowFilter.Insert("Purpose", PurposeSelection);
	
	EndIf;
	
	Return RowFilter;

EndFunction

&AtServer
Procedure ProcessDataWhenSettingSelection()

	RowFilter = StageSelectionStructure();
	LineSelectionComparison = New Structure;
	
	For Each StructureItem In RowFilter Do
	
		LineSelectionComparison.Insert(StructureItem.Key, Undefined);
	
	EndDo;
	
	UpdateAvailability1 = False;
	
	Tree = FormAttributeToValue("ReplacementTree");
	LinesByProductName = Tree.Rows;
	TableOfBalancesOfAnalogues = RemnantsOfAnalogues.Unload();
	TableOfBalancesOfAnalogues.Indexes.Add("Products, Characteristic, Warehouse, Purpose");
	
	For Each TableRow In Stages Do
	
		If TableRow.Selected Then
		
			FillPropertyValues(LineSelectionComparison, TableRow);
			
			DataMatch = Common.DataMatch(LineSelectionComparison, RowFilter);
			
			If Not DataMatch Then
			
				TableRow.Selected = False;
				TableRow.ToReplace = 0;
				
				NumberOfSets = ProductionClientServer.CoefficientByStandard(
					False, TableRow.ToReplace - TableRow.ToBeReplacedBeforeChange, TableRow.NormativeStandard, TableRow.PackageData);
					
				If NumberOfSets <> 0 Then
					ToProcessUpdate(LinesByProductName, TableOfBalancesOfAnalogues, TableRow.Stage, TableRow.ConnectionKey, NumberOfSets, TableRow);
					UpdateAvailability1 = True;
				EndIf;
				
			EndIf;
		
		EndIf;
	
	EndDo;
	
	ValueToFormAttribute(Tree, "ReplacementTree");
	
	If UpdateAvailability1 Then
		UpdateColumnAvailable(TableOfBalancesOfAnalogues);
	EndIf;
	
	RemnantsOfAnalogues.Load(TableOfBalancesOfAnalogues);
	
EndProcedure

&AtClient
Procedure UpdateStageDataOnForm()

	FillOutFormDataATServer();
	
	If StartAwaitingLongAction Then
		
		StartAwaitingLongAction(False);
		OperationText = NStr("vi = 'Đang nhận dữ liệu...';
							|ru = 'Выполняется получение данных...';
							|en = 'Receiving data…'; fa = 'Receiving data…';
							|it = 'Ottenimento dei dati in corso...';
							|pl = 'Trwa pobieranie danych...';
							|tr = 'Veri alınıyor ...'");
		SetUpWaitingInForm(ThisObject, True, OperationText);
		
	Else
		
		SetUpWaitingInForm(ThisObject, False);
		
	EndIf;

EndProcedure

&AtServer
Procedure FillOutFormDataATServer()
		
	CancelLongRunningOperation();
	
	Stages.Clear();
	Substitutes.Clear();
	TreeData = ReplacementTree.GetItems();
	TreeData.Clear();
	
	ReReadDataAfterReplacement = False;
	
	If ValueIsFilled(Stage) Then
		InventoryTable = RemnantsOfAnalogues.Unload();
	Else
		InventoryTable = Undefined;
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("RoleOfAnalogues", RoleOfAnalogues);
	ProcedureParameters.Insert("Resolution", Resolution);
	ProcedureParameters.Insert("Stages", Stages.Unload());
	ProcedureParameters.Insert("Substitutes", Substitutes.Unload());
	ProcedureParameters.Insert("ReplacementPriority", ReplacementPriority);
	ProcedureParameters.Insert("Stage", Stage);
	ProcedureParameters.Insert("GoodsFromDocument", GoodsFromDocument.Unload());
	ProcedureParameters.Insert("InventoryTable", InventoryTable);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Trợ lý thực hiện thay thế sang vật tư tương tự: điền dữ liệu của các công đoạn';
														|ru = 'Помощник выполнения замен на аналоги: заполнение данных этапов';
														|en = 'Wizard of replacing with substitutes: fill stage data'; fa = 'Wizard of replacing with substitutes: fill stage data';
														|it = 'Wizard of replacing with substitutes: fill stage data';
														|pl = 'Wizard of replacing with substitutes: fill stage data';
														|tr = 'İkame ile değiştirme işlemleri asistanı: aşama verilerinin doldurulması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Documents.EngineeringChangeOrder.DataOfStagesToReplace",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = "FillInStageDataOnDeferredBasisCompletion";
		StartAwaitingLongAction = True;
		
	Else
		
		FillInStageDataOnDeferredBasis(TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInStageDataOnDeferredBasisCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		FillInStageDataOnDeferredBasis(Result);
		SetUpWaitingInForm(ThisObject, False);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInStageDataOnDeferredBasis(Result)
	
	If Result.Status = "Completed2" Then
		
		FillingData = GetFromTempStorage(Result.ResultAddress);
		
		If ModeFromDocument Then
			
			Stages.Load(FillingData.Stages);
			RemnantsOfAnalogues.Load(FillingData.RemnantsOfAnalogues);
			Substitutes.Load(FillingData.Substitutes);
			SetRowSelection();
			
		Else
			
			Stages.Load(FillingData.Stages);
			Standards.Load(FillingData.Standards);
			
			UpdateColumnAvailable();
		
		EndIf;
		
		SetHyperlinkOfMaterialBeingReplaced();
		SetItemsVisibility();
		
	Else
		
		If Result.Status = "Error" Then
			
			Raise Result.BriefErrorDescription;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Function MatchingBalances(Warehouse, Purpose)

	SearchForBalances = New Structure("Warehouse, Purpose");
	SearchForBalances.Warehouse = Warehouse;
	SearchForBalances.Purpose = PredefinedValue("Catalog.Assignments.EmptyRef");
	
	AvailableStock = RemnantsOfAnalogues.FindRows(SearchForBalances);
	
	Map = New Map;
	For Each TableRow In AvailableStock Do
		
		Current_Balance = TableRow.AvailableForInventoryAllocation - TableRow.Used_;
		
		MapValue = Map.Get(TableRow.Products);
		
		If MapValue = Undefined Then
			
			MatchBalance = New Map;
			MatchBalance.Insert(TableRow.Characteristic, Current_Balance); 
			Map.Insert(TableRow.Products, MatchBalance);
			
		Else
			
			MapValue.Insert(TableRow.Characteristic, Current_Balance); 
		
		EndIf;
	
	EndDo;
	
	If ValueIsFilled(Purpose) Then
	
		SearchForBalances.Purpose = Purpose;
		BalancesAsIntended = RemnantsOfAnalogues.FindRows(SearchForBalances);
		
		For Each TableRow In BalancesAsIntended Do
			
			Current_Balance = TableRow.AvailableForInventoryAllocation - TableRow.Used_;
			
			MapValue = Map.Get(TableRow.Products);
			
			If MapValue = Undefined Then
				
				MatchBalance = New Map;
				MatchBalance.Insert(TableRow.Characteristic, Current_Balance); 
				Map.Insert(TableRow.Products, MatchBalance);
				
			Else
				
				Var_59_AvailableStock = MapValue.Get(TableRow.Characteristic);
				Current_Balance = Current_Balance + ?(Var_59_AvailableStock = Undefined, 0, Var_59_AvailableStock);
				MapValue.Insert(TableRow.Characteristic, Current_Balance);
			
			EndIf;
		
		EndDo;
	
	EndIf;
	
	Return Map;

EndFunction

&AtClient
Function BalanceOfAnalogFromMatch(BalancesOfAnalogsMatching, Products, Characteristic)

	Balance = 0;
	
	MapValue = BalancesOfAnalogsMatching.Get(Products);
	
	If MapValue <> Undefined Then
			
		BalancesByCharacteristic = MapValue.Get(Characteristic);
		If BalancesByCharacteristic <> Undefined Then
			Balance = BalancesByCharacteristic;
		EndIf;
	
	EndIf;
	
	Return Balance;

EndFunction

&AtClient
Function ConversionFactor_()
	
	CurrentDataAnalog = Items.Substitutes.CurrentData;
	CurrentDataMaterial = Items.Stages.CurrentData;
	
	CurrentResolution = CurrentDataAnalog.Resolution;
	ConnectionKey = CurrentDataAnalog.ConnectionKey;
	
	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("Resolution", CurrentResolution);
	TheStructureOfTheSearch.Insert("ConnectionKey", ConnectionKey);
	
	RowsArray = Substitutes.FindRows(TheStructureOfTheSearch);
	ZoomRatio = -1;
	
	For Each SpecificationRow In RowsArray Do
	
		If SpecificationRow.ThisIsASubstitute Then
			Count = SpecificationRow.WarehouseStockBalance;
		Else
			
			If SpecificationRow.Products = CurrentDataMaterial.Products
			   And SpecificationRow.Characteristic = CurrentDataMaterial.Characteristic Then
			
				Count = CurrentDataMaterial.Total - CurrentDataMaterial.ToReplace;
			
			Else	
				Count = MaterialQuantity(SpecificationRow.Products, SpecificationRow.Characteristic);
			EndIf;
			
		EndIf;
			
		CoefficientByStandard = ProductionClientServer.CoefficientByStandard(
			SpecificationRow.ControlMultiplier, Count, SpecificationRow.NormativeStandard, SpecificationRow.PackageData);
				
		If ZoomRatio = -1 Then
			ZoomRatio = CoefficientByStandard;
		Else
			ZoomRatio = Min(ZoomRatio, CoefficientByStandard);
		EndIf;
	
	EndDo;
	
	Return ZoomRatio;

EndFunction

&AtClient
Procedure CheckPossibilityOfRecalculation(CalculationCoefficient, Cancel)

	CurDataAnalogues = Items.Substitutes.CurrentData;
	
	StandardCoefficient = ProductionClientServer.CoefficientByStandard(
		False, CurDataAnalogues.Count, CurDataAnalogues.NormativeStandard, CurDataAnalogues.PackageData);
	
	If CurDataAnalogues.ControlMultiplier And StandardCoefficient <> Int(StandardCoefficient) Then
		
		MessageText = NStr("vi = 'Nhập bội số của tiêu chuẩn.';
							|ru = 'Введите количество кратное нормативу.';
							|en = 'Enter the amount multiple of the standard'; fa = 'Enter the amount multiple of the standard';
							|it = 'Inserite un numero multiplo della quantità standard.';
							|pl = 'Wprowadź ilość wielokrotną normie.';
							|tr = 'Miktarı standardın katları olarak girin.'");
		
	ElsIf CurDataAnalogues.Count > AnalogsQuantityBeforeChange Then
		
		SearchForMaterials = New Structure;
		SearchForMaterials.Insert("Resolution", CurDataAnalogues.Resolution);
		SearchForMaterials.Insert("ConnectionKey", CurDataAnalogues.ConnectionKey);
		SearchForMaterials.Insert("ThisIsASubstitute", False);
		
		FilterMaterial = New Structure("Products, Characteristic");
		
		ArrayOfMaterials = Substitutes.FindRows(SearchForMaterials);
		
		For Each StringMaterial In ArrayOfMaterials Do
		
			FillPropertyValues(FilterMaterial, StringMaterial);
			ContentLines = Stages.FindRows(FilterMaterial);
			MaterialsStandard = StringMaterial.NormativeStandard;
			Remaining_Quantity = 0;
			
			For Each SpecificationRow In ContentLines Do
				Remaining_Quantity = Remaining_Quantity + SpecificationRow.Total - SpecificationRow.ToReplace;
			EndDo;
			
			NeedsToBeReplaced = EstimatedNumberOfItems(MaterialsStandard, CalculationCoefficient, StringMaterial.PackageData); 
			
			If NeedsToBeReplaced > Remaining_Quantity Then
				
				Template = NStr("vi = 'Để thực hiện thay thế, không đủ %1 %2 nguyên liệu đã chọn %3';
								|ru = 'Для выполнения замены не хватает %1 %2 выбранного материала %3';
								|en = '%1 %2 of the selected material %3 is missing to complete the replacement'; fa = '%1 %2 of the selected material %3 is missing to complete the replacement';
								|it = 'Per la sostituzione manca %1%2 del materiale selezionato %3';
								|pl = 'Dla wykonania zmiany nie wystarcza %1 %2 wybranego materiału %3';
								|tr = 'Değişimin gerçekleştirilmesi için %3 seçili malzemenin %2 %1 yetersiz'");
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					Template, 
					Round(NeedsToBeReplaced - Remaining_Quantity, 3),
					StringMaterial.UnitOfMeasurePresentation,
					ProductsClientServer.ProductPresentation(StringMaterial.ProductsPresentation, StringMaterial.CharacteristicPresentation));
					
				Break;
			
			EndIf;
		
		EndDo;
		
	EndIf;
	
	If Not IsBlankString(MessageText) Then
		CommonClient.MessageToUser(MessageText,,,, Cancel);
	EndIf;

EndProcedure

&AtClient
Procedure ProcessSelectionOfAnalogues(ZoomRatio)
	
	CurrentDataMaterial = Items.Stages.CurrentData;
	CurrentData = Items.Substitutes.CurrentData;
	
	CurrentResolution = CurrentData.Resolution;
	ConnectionKey = CurrentData.ConnectionKey;
	
	MaterialLineNumbers = New Map;
	MaterialRowData = New Map;
	AnalogStrings = New Array;
	NumberOfDifferentMaterials = 0;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Resolution", CurrentResolution);
	TheStructureOfTheSearch.Insert("ConnectionKey", ConnectionKey);
		
	FilterMaterial = New Structure("Products, Characteristic");
	
	RowsArray = Substitutes.FindRows(TheStructureOfTheSearch);
	
	For Each SpecificationRow In RowsArray Do
		
		If SpecificationRow.ThisIsASubstitute Then
		
			QuantityToWriteOff = EstimatedNumberOfItems(SpecificationRow.NormativeStandard, ZoomRatio, SpecificationRow.PackageData);
			AnalogStrings.Add(SpecificationRow);
		
			SpecificationRow.Count = SpecificationRow.Count + QuantityToWriteOff;
			
			SearchForBalances = New Structure();
			SearchForBalances.Insert("Products", SpecificationRow.Products);
			SearchForBalances.Insert("Characteristic", SpecificationRow.Characteristic);
			SearchForBalances.Insert("Purpose", CurrentDataMaterial.Purpose);
			SearchForBalances.Insert("Warehouse", SpecificationRow.Warehouse);
			
			BalancesAsIntended = RemnantsOfAnalogues.FindRows(SearchForBalances);
			For Each StringBalance In BalancesAsIntended Do
				
				If ZoomRatio > 0 Then
				
					BalanceBeforeChange = StringBalance.AvailableForInventoryAllocation - StringBalance.Used_;
					If BalanceBeforeChange > 0 Then
						BalanceToBeWrittenOff = Min(BalanceBeforeChange, QuantityToWriteOff);
						QuantityToWriteOff = QuantityToWriteOff - BalanceToBeWrittenOff;
						StringBalance.Used_ = StringBalance.Used_ + BalanceToBeWrittenOff;
					EndIf;
					
				Else
					
					BalanceToBeWrittenOff = Min(StringBalance.Used_, -QuantityToWriteOff);
					StringBalance.Used_ = StringBalance.Used_ - BalanceToBeWrittenOff;
					QuantityToWriteOff = QuantityToWriteOff + BalanceToBeWrittenOff;
					
				EndIf;
				
			EndDo;
			
			If QuantityToWriteOff <> 0 Then
			
				SearchForBalances.Purpose = PredefinedValue("Catalog.Assignments.EmptyRef");
				AvailableStock = RemnantsOfAnalogues.FindRows(SearchForBalances);
				For Each StringBalance In AvailableStock Do
					
					If ZoomRatio > 0 Then
					
						StringBalance.Used_ = StringBalance.Used_ + QuantityToWriteOff;
					
					Else
					
						BalanceToBeWrittenOff = Min(StringBalance.Used_, -QuantityToWriteOff);
						StringBalance.Used_ = StringBalance.Used_ - BalanceToBeWrittenOff;
					
					EndIf;
					
				EndDo;
				
			EndIf;
			
		Else
			
			NumberOfDifferentMaterials = NumberOfDifferentMaterials + 1;
			QuantityToDistribution = EstimatedNumberOfItems(SpecificationRow.NormativeStandard, ZoomRatio, SpecificationRow.PackageData);
			
			If SpecificationRow.Products = CurrentDataMaterial.Products
			   And SpecificationRow.Characteristic = CurrentDataMaterial.Characteristic Then
			
				If ZoomRatio > 0 Then
					QuantityToWriteOff = Min(CurrentDataMaterial.Total - CurrentDataMaterial.ToReplace, QuantityToDistribution);
				Else
					QuantityToWriteOff = Max(QuantityToDistribution, -CurrentDataMaterial.ToReplace);;
				EndIf;
				
				QuantityToDistribution = QuantityToDistribution - QuantityToWriteOff;
				
				CurrentDataMaterial.ToReplace = CurrentDataMaterial.ToReplace + QuantityToWriteOff;
				CurrentDataMaterial.Selected = CurrentDataMaterial.ToReplace > 0;
				MaterialLineNumbers.Insert(CurrentDataMaterial.LineNumberDocument, QuantityToWriteOff);
				MaterialRowData.Insert(CurrentDataMaterial.LineNumberDocument, 
					New Structure("Material, ItemVariantOfMaterial", CurrentDataMaterial.Products, CurrentDataMaterial.Characteristic));
				
			EndIf;
			
			If QuantityToDistribution <> 0 Then
			
				FillPropertyValues(FilterMaterial, SpecificationRow);
				ArrayOfMaterials = Stages.FindRows(FilterMaterial);
				
				For Each StringMaterial In ArrayOfMaterials Do
					
					If QuantityToDistribution = 0 Then
						Break;
					EndIf;
					
					If StringMaterial.LineNumberDocument = CurrentDataMaterial.LineNumberDocument Then
						Continue;
					EndIf;
					
					If ZoomRatio > 0 Then
						QuantityToWriteOff = Min(StringMaterial.Total - StringMaterial.ToReplace, QuantityToDistribution);
					Else
						QuantityToWriteOff = Max(QuantityToDistribution, -StringMaterial.ToReplace);
					EndIf;
					
					If QuantityToWriteOff <> 0 Then
						
						QuantityToDistribution = QuantityToDistribution - QuantityToWriteOff;
						
						StringMaterial.ToReplace = StringMaterial.ToReplace + QuantityToWriteOff;
						StringMaterial.Selected = StringMaterial.ToReplace > 0;
						MaterialLineNumbers.Insert(StringMaterial.LineNumberDocument, QuantityToWriteOff);
						MaterialRowData.Insert(StringMaterial.LineNumberDocument, 
							New Structure("Material, ItemVariantOfMaterial", StringMaterial.Products, StringMaterial.Characteristic));
						
					EndIf;
					
				EndDo;
			
			EndIf;
				
		EndIf;
		
	EndDo;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Resolution");
	FilterParameters.Insert("ConnectionKey");
	FilterParameters.Insert("Products");
	FilterParameters.Insert("Characteristic");
	FilterParameters.Insert("LineNumberDocument");
	
	FilterRemainingGoodsByShelfLives = New Structure("Products, Characteristic, ThisIsASubstitute");
	FilterRemainingGoodsByShelfLives.ThisIsASubstitute = True;
	
	FilterOfAnalogues = New Structure("Products, Characteristic, Warehouse");
	
	BalancesOfAnalogsMatching = MatchingBalances(CurrentDataMaterial.Warehouse, CurrentDataMaterial.Purpose);
	
	For Each ReadyForProcessing In AnalogStrings Do
		
		AddedQuantity = EstimatedNumberOfItems(ReadyForProcessing.NormativeStandard, ZoomRatio, ReadyForProcessing.PackageData); 
		FillPropertyValues(FilterRemainingGoodsByShelfLives, ReadyForProcessing,, "ThisIsASubstitute");
		ArrayOfAnalogs = Substitutes.FindRows(FilterRemainingGoodsByShelfLives);
		
		For Each StringAnalog In ArrayOfAnalogs Do
			
			StringAnalog.WarehouseStockBalance = BalanceOfAnalogFromMatch(
				BalancesOfAnalogsMatching,
				StringAnalog.Products,
				StringAnalog.Characteristic);
				
			StringAnalog.IsBalance = StringAnalog.WarehouseStockBalance > 0;
			
		EndDo;
		
		FillPropertyValues(FilterParameters, ReadyForProcessing, "Resolution, ConnectionKey, Products, Characteristic");
		
		For Each KeyValue In MaterialLineNumbers Do
		
			FilterParameters.LineNumberDocument = KeyValue.Key;
			FoundRows = UsedAnaloguesLineByLine.FindRows(FilterParameters);
			
			QuantityToBeAccountedFor = EstimatedNumberOfItems(ReadyForProcessing.NormativeStandard, KeyValue.Value, ReadyForProcessing.PackageData);
			
			If FoundRows.Count() = 0 Then
				
				UsageRow = UsedAnaloguesLineByLine.Add();
				FillPropertyValues(UsageRow, FilterParameters);
				
				RowData = MaterialRowData.Get(KeyValue.Key);
				FillPropertyValues(UsageRow, RowData, "Material, ItemVariantOfMaterial");
				
				UsageRow.SeveralMaterials = NumberOfDifferentMaterials > 1;
				UsageRow.Count = QuantityToBeAccountedFor;
				
			Else
				
				UsageRow = FoundRows[0];
				UsageRow.Count = UsageRow.Count + QuantityToBeAccountedFor;
				
			EndIf;
		
		EndDo;
		
		FillPropertyValues(FilterOfAnalogues, ReadyForProcessing);
		FoundAnalogStrings = UsedAnalogues.FindRows(FilterOfAnalogues);
		If FoundAnalogStrings.Count() = 0 Then
			
			StringOfFoundAnalogues = UsedAnalogues.Add();
			FillPropertyValues(StringOfFoundAnalogues, FilterOfAnalogues);
			StringOfFoundAnalogues.Count = AddedQuantity;
			
		Else	
			
			UsageRow = FoundAnalogStrings[0];
			UsageRow.Count = UsageRow.Count + AddedQuantity;
			
		EndIf;
		
	EndDo;

EndProcedure

&AtClient
Function MaterialQuantity(Products, Characteristic)

	SearchForMaterial = New Structure("Products, Characteristic", Products, Characteristic);
	ArrayOfMaterials = Stages.FindRows(SearchForMaterial);
	
	Remaining_Quantity = 0;
	
	For Each SpecificationRow In ArrayOfMaterials Do
	
		Remaining_Quantity = Remaining_Quantity + SpecificationRow.Total - SpecificationRow.ToReplace;
	
	EndDo;
	
	Return Remaining_Quantity;

EndFunction

&AtClient
Function AmountOfAnalogUsed(Resolution, ConnectionKey, Products, Characteristic, LineNumberDocument)

	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Resolution", Resolution);
	TheStructureOfTheSearch.Insert("ConnectionKey", ConnectionKey);
	TheStructureOfTheSearch.Insert("Products", Products);
	TheStructureOfTheSearch.Insert("Characteristic", Characteristic);
	TheStructureOfTheSearch.Insert("LineNumberDocument", LineNumberDocument);
	
	Count = 0;
	
	For Each SpecificationRow In UsedAnaloguesLineByLine.FindRows(TheStructureOfTheSearch) Do
	
		Count = Count + SpecificationRow.Count;
	
	EndDo;
	
	Return Count;

EndFunction

&AtServer
Procedure HandleFlagChange(FlagValue1)
	
	SearchForRelatedStrings = New Structure("Stage, ConnectionKey");
	
	Tree = FormAttributeToValue("ReplacementTree");
	LinesByProductName = Tree.Rows;
	TableOfBalancesOfAnalogues = RemnantsOfAnalogues.Unload();
	TableOfBalancesOfAnalogues.Indexes.Add("Products, Characteristic, Warehouse, Purpose");
	
	For Each Id In Items.Stages.SelectedRows Do
		
		TableRow = Stages.FindByID(Id);
		TableRow.Selected = FlagValue1;
		
		If TableRow.Stage = SearchForRelatedStrings.Stage
		   And TableRow.ConnectionKey = SearchForRelatedStrings.ConnectionKey Then
			Continue;
		EndIf;
		
		FillPropertyValues(SearchForRelatedStrings, TableRow);
		
		StringsByKey = Stages.FindRows(SearchForRelatedStrings);
		
		NumberOfSetsToProcess = Undefined;
		
		For Each StringOfStages In StringsByKey Do
			
			StringOfStages.Selected = FlagValue1;
			
			If StringOfStages.Selected Then
				ToReplace = StringOfStages.Total - StringOfStages.Shipped;
			Else
				ToReplace = 0;
			EndIf;
			
			NumberOfSets = ProductionClientServer.CoefficientByStandard(
				False, ToReplace - StringOfStages.ToBeReplacedBeforeChange, StringOfStages.NormativeStandard, StringOfStages.PackageData);
			
			If NumberOfSetsToProcess = Undefined Then
				NumberOfSetsToProcess = NumberOfSets;
			ElsIf FlagValue1 Then
				NumberOfSetsToProcess = Min(NumberOfSetsToProcess, NumberOfSets);
			Else
				NumberOfSetsToProcess = Max(NumberOfSetsToProcess, NumberOfSets);
			EndIf;
			
		EndDo;
		
		If TableRow.Selected Then
			EstimatedQuantity = EstimatedNumberOfItems(
				TableRow.NormativeStandard, NumberOfSetsToProcess, TableRow.PackageData);
			ToReplaceInstall = TableRow.ToReplace + EstimatedQuantity;
		Else
			ToReplaceInstall = 0;
		EndIf;
		
		If NumberOfSetsToProcess <> 0 Then
			ToProcessUpdate(LinesByProductName, TableOfBalancesOfAnalogues, TableRow.Stage, TableRow.ConnectionKey, NumberOfSetsToProcess, TableRow);
		EndIf;
		
		TableRow.ToReplace = ToReplaceInstall;
		TableRow.ToBeReplacedBeforeChange = TableRow.ToReplace;
		TableRow.Selected = TableRow.ToReplace > 0;
	
	EndDo;
	
	ValueToFormAttribute(Tree, "ReplacementTree");
	
	UpdateColumnAvailable(TableOfBalancesOfAnalogues);

EndProcedure

&AtServer
Procedure UpdateColumnAvailable(BalanceTable = Undefined)
	
	StepsTable = Stages.Unload();
	
	StructureOfFormData = New Structure;
	FillInStructureWithAttributesOfForm(StructureOfFormData);
	StructureOfFormData.Insert("RemnantsOfAnalogues", RemnantsOfAnalogues.Unload());
	StructureOfFormData.Insert("Standards", Standards.Unload());
	
	Documents.EngineeringChangeOrder.UpdateColumnAvailable(StructureOfFormData, StepsTable, BalanceTable);
	
	Stages.Load(StepsTable);
	RemnantsOfAnalogues.Load(BalanceTable);
		
EndProcedure

&AtServer
Procedure InitializeData()

	TreeData = ReplacementTree.GetItems();
	TreeData.Clear();
	
	For Each SpecificationRow In RemnantsOfAnalogues Do
		SpecificationRow.Used_ = 0;
		SpecificationRow.UsedInExcessOfBalance = 0;
	EndDo;
	
	For Each TableRow In Stages Do
		TableRow.ToReplace = 0;
		TableRow.ToBeReplacedBeforeChange = 0;
		TableRow.Selected = False;
	EndDo;

EndProcedure

&AtServer
Procedure ReplaceWithAnalogsAtServer()
		
	Tree = FormAttributeToValue("ReplacementTree");
	
	If Tree.Rows.Count() = 0 Then
		
		StartAwaitingLongAction = False;
		MessageText = NStr("vi = 'Chưa chọn dòng cần thay thế sang vật tư tương tự';
							|ru = 'Не выбраны строки к замене на аналоги';
							|en = 'Lines for replacing with substitutes are not selected'; fa = 'Lines for replacing with substitutes are not selected';
							|it = 'Lines for replacing with substitutes are not selected';
							|pl = 'Lines for replacing with substitutes are not selected';
							|tr = 'İkame ile değiştirilecek satır seçilmedi'");
		Common.MessageToUser(MessageText,, "Stages");
		Return;
	
	EndIf;
	
	TableOfMaterials = New ValueTable;
	TableOfMaterials.Columns.Add("Ref", New TypeDescription("DocumentRef.ProductionStage2_2"));
	TableOfMaterials.Columns.Add("Presentation", New TypeDescription("String"));
	TableOfMaterials.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfMaterials.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfMaterials.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	TableOfMaterials.Columns.Add("Count", Common.TypeDescriptionNumber(15,3));
	
	TableOfAnalogues = New ValueTable;
	TableOfAnalogues.Columns.Add("Ref", New TypeDescription("DocumentRef.ProductionStage2_2"));
	TableOfAnalogues.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableOfAnalogues.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfAnalogues.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	TableOfAnalogues.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	TableOfAnalogues.Columns.Add("Count", Common.TypeDescriptionNumber(15,3));
	
	For Each TreeRow In Tree.Rows Do
	
		If TreeRow.Flag = 0 Then
			
			For Each DecryptionString In TreeRow.Rows Do
			
				NewRow = TableOfAnalogues.Add();
				FillPropertyValues(NewRow, DecryptionString);
				NewRow.Ref = DecryptionString.Stage;
			
			EndDo;	
		
		ElsIf TreeRow.Flag = 1 Then
		
			For Each DecryptionString In TreeRow.Rows Do
			
				NewRow = TableOfMaterials.Add();
				FillPropertyValues(NewRow, DecryptionString);
				NewRow.Ref = DecryptionString.Stage;
				NewRow.Presentation = DecryptionString.OrderPresentation;
			
			EndDo;
		
		EndIf;
	
	EndDo;
	
	// Starting the formation
	CancelLongRunningOperation();
	
	TableOfMaterials.Sort("Ref", New CompareValues);
	TableOfAnalogues.Sort("Ref", New CompareValues);
	
	ReferencesArrray = Common.UnloadColumn(TableOfMaterials, "Ref", True);
		
	ParametersForProcessing = New Structure;
	ParametersForProcessing.Insert("TableOfStagesForProcessing", TableOfMaterials);
	ParametersForProcessing.Insert("TableOfAnalogues", TableOfAnalogues);
	ParametersForProcessing.Insert("ReferencesArrray", ReferencesArrray);
	
	AddressIsResultOfFormation = PutToTempStorage(
		Documents.EngineeringChangeOrder.ResultOfFormation(), UUID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Trợ lý thực hiện thay thế: thay thế bằng hàng tương tự';
														|ru = 'Помощник выполнения замен: замена на аналоги';
														|en = 'Replacement wizard: replace with substitutes'; fa = 'Replacement wizard: replace with substitutes';
														|it = 'Replacement wizard: replace with substitutes';
														|pl = 'Replacement wizard: replace with substitutes';
														|tr = 'Değiştirme işlemleri asistanı: ikame ile değiştirme'");
	ExecutionParameters.ResultAddress = AddressIsResultOfFormation;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Documents.EngineeringChangeOrder.ReplaceWithAnalogsInProductionStagesDelayed",
		ParametersForProcessing,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = "ReplaceWithAnalogsInProductionStagesDelayedCompletion";
		StartAwaitingLongAction = True;
		
	Else
		
		ReplaceWithAnalogsDeferred(TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
		If ReReadDataAfterReplacement Then
			
			OperationText = NStr("vi = 'Đang nhận dữ liệu...';
								|ru = 'Выполняется получение данных...';
								|en = 'Receiving data…'; fa = 'Receiving data…';
								|it = 'Ottenimento dei dati in corso...';
								|pl = 'Trwa pobieranie danych...';
								|tr = 'Veri alınıyor ...'");
			SetUpWaitingInForm(ThisObject, True, OperationText);
			FillOutFormDataATServer();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReplaceWithAnalogsInProductionStagesDelayedCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	SetUpWaitingInForm(ThisObject, False);
	
	ReplaceWithAnalogsDeferred(Result);
	
	If Result <> Undefined And Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	EndIf;
	
	If ReReadDataAfterReplacement Then
		
		UpdateStageDataOnForm();
		
	EndIf
	
EndProcedure

&AtServer
Procedure ReplaceWithAnalogsDeferred(Result)
	
	IsJobCompleted = False;
	
	If IsTempStorageURL(AddressIsResultOfFormation) Then
		
		ResultStructure1 = GetFromTempStorage(AddressIsResultOfFormation);
		AddressIsResultOfFormation = Undefined;
		
		MessageText = NStr("vi = 'Đã hoàn tất quy trình thay thế nguyên vật liệu sang vật tư tương tự';
							|ru = 'Завершен процесс замены материалов на аналоги';
							|en = 'Materials are replaced with substitutes'; fa = 'Materials are replaced with substitutes';
							|it = 'Materials are replaced with substitutes';
							|pl = 'Materials are replaced with substitutes';
							|tr = 'Malzemelerin ikame ile değiştirilmesi işlemi tamamlandı'");
		
		Common.MessageToUser(MessageText);
		IsJobCompleted = True;
		
		For Each TSRow In ResultStructure1.Errors Do
		
			Common.MessageToUser(TSRow.MessageText);
		
		EndDo;
				
	EndIf;
	
	If TypeOf(Result) = Type("Structure")
		And CommonClientServer.HasAttributeOrObjectProperty(Result, "Messages") Then
		For Each Message In Result.Messages Do
			Message.Message();
		EndDo;
	EndIf;
	
	If Result = Undefined
		Or Result.Status <> "Completed2" Then
		Common.MessageToUser(NStr("vi = 'Chưa xử lý đầy đủ chứng từ';
									|ru = 'Документы обработаны не полностью';
									|en = 'Documents are not fully processed'; fa = 'Documents are not fully processed';
									|it = 'Documents are not fully processed';
									|pl = 'Documents are not fully processed';
									|tr = 'Belgeler tam olarak işlenmedi'"));
	EndIf;
	
	If IsJobCompleted Then
	
		Items.FormPages.CurrentPage = Items.PageOfMaterialsAndAnalogues;
		Items.Replace_With_Analogues.Visible = True;
		Items.FormReread.Visible = True;
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		ReReadDataAfterReplacement = True;
	
	EndIf;
	
EndProcedure

&AtServer
Procedure CancelLongRunningOperation()
	
	If Not TimeConsumingOperation = Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessManualChange(Stage, ConnectionKey, NumberOfSets)
	
	Tree = FormAttributeToValue("ReplacementTree");
	LinesByProductName = Tree.Rows;
	
	TableOfBalancesOfAnalogues = RemnantsOfAnalogues.Unload();
	TableOfBalancesOfAnalogues.Indexes.Add("Products, Characteristic, Warehouse, Purpose");
	
	UpdateAvailability1 = ToProcessUpdate(LinesByProductName, TableOfBalancesOfAnalogues, Stage, ConnectionKey, NumberOfSets);
	
	RemnantsOfAnalogues.Load(TableOfBalancesOfAnalogues);
	
	ValueToFormAttribute(Tree, "ReplacementTree");
	
	If UpdateAvailability1 Then
		
		BalanceTable = RemnantsOfAnalogues.Unload();
		BalanceTable.Indexes.Add("Products, Characteristic, Purpose, Warehouse");
		UpdateColumnAvailable(BalanceTable);
		
	EndIf;
	
EndProcedure

&AtServer
Function ToProcessUpdate(LinesByProductName, TableOfBalancesOfAnalogues, Stage, ConnectionKey, NumberOfSets, StageString_ = Undefined)
	
	StructureOfFormData = New Structure;
	FillInStructureWithAttributesOfForm(StructureOfFormData);
	StructureOfFormData.Insert("Stages", Stages);
	StructureOfFormData.Insert("Standards", Standards.Unload());
	
	If StageString_ = Undefined Then
		SelectedRow = Stages.FindByID(Items.Stages.CurrentRow);
	Else
		SelectedRow = StageString_;
	EndIf;
	
	Return Documents.EngineeringChangeOrder.ToProcessUpdate(
		StructureOfFormData, LinesByProductName, TableOfBalancesOfAnalogues, Stage, ConnectionKey, NumberOfSets, SelectedRow, False);

EndFunction

&AtClientAtServerNoContext
Function EstimatedNumberOfItems(NormativeStandard, ConversionFactor_, PackageData)
	
	EstimatedQuantity = NormativeStandard * ConversionFactor_
		* PackageData.Numerator / PackageData.Denominator;
			
	CurrentCount = Int(EstimatedQuantity);
	If EstimatedQuantity > CurrentCount Then
		CurrentCount = CurrentCount + Int((EstimatedQuantity - CurrentCount) * 1000) / 1000;
	EndIf;
	
	Return EstimatedQuantity;

EndFunction

&AtServer
Function CalculationResult1()

	QueryText = 
	"SELECT
	|	TableOfMaterials.LineNumberDocument AS LineNumberDocument,
	|	TableOfMaterials.Products AS Products,
	|	TableOfMaterials.Characteristic AS Characteristic,
	|	TableOfMaterials.Warehouse AS Warehouse,
	|	TableOfMaterials.Total AS Total,
	|	TableOfMaterials.ToReplace AS ToReplace
	|INTO TableOfMaterials
	|FROM
	|	&UsedMaterials AS TableOfMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfAnalogues.Products AS Products,
	|	TableOfAnalogues.Characteristic AS Characteristic,
	|	TableOfAnalogues.Warehouse AS Warehouse,
	|	TableOfAnalogues.Count AS Count
	|INTO TableOfAnalogues
	|FROM
	|	&Substitutes AS TableOfAnalogues
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaterialsOfPermission.Products AS Products,
	|	MaterialsOfPermission.Characteristic AS Characteristic,
	|	MaterialsOfPermission.Resolution AS Resolution,
	|	MaterialsOfPermission.LineNumber AS LineNumber
	|INTO MaterialsOfPermission
	|FROM
	|	&MaterialsOfPermission AS MaterialsOfPermission
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Resolution,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SeparateAnalogues.Products AS Products,
	|	SeparateAnalogues.Characteristic AS Characteristic,
	|	SeparateAnalogues.Warehouse AS Warehouse,
	|	SeparateAnalogues.Purpose AS Purpose,
	|	SeparateAnalogues.Used_ AS Count
	|INTO TableOfIsolatedAnalogues
	|FROM
	|	&SeparateAnalogues AS SeparateAnalogues
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Products AS Products,
	|	T.Characteristic AS Characteristic,
	|	T.LineNumberDocument AS LineNumberDocument,
	|	T.Material AS Material,
	|	T.ItemVariantOfMaterial AS ItemVariantOfMaterial,
	|	T.Resolution AS Resolution,
	|	T.SeveralMaterials AS SeveralMaterials,
	|	T.Count AS Count
	|INTO TableAnaloguesLineByLine
	|FROM
	|	&AnalogsLineByLine AS T
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Resolution,
	|	SeveralMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfIsolatedAnalogues.Products AS Products,
	|	TableOfIsolatedAnalogues.Characteristic AS Characteristic,
	|	TableOfIsolatedAnalogues.Warehouse AS Warehouse,
	|	SUM(TableOfIsolatedAnalogues.Count) AS Count
	|INTO TableIsUsedSeparately
	|FROM
	|	TableOfIsolatedAnalogues AS TableOfIsolatedAnalogues
	|WHERE
	|	TableOfIsolatedAnalogues.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|
	|GROUP BY
	|	TableOfIsolatedAnalogues.Products,
	|	TableOfIsolatedAnalogues.Warehouse,
	|	TableOfIsolatedAnalogues.Characteristic
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableAnaloguesLineByLine.Products AS Products,
	|	TableAnaloguesLineByLine.Characteristic AS Characteristic,
	|	TableAnaloguesLineByLine.LineNumberDocument AS LineNumberDocument,
	|	TableAnaloguesLineByLine.Material AS Material,
	|	TableAnaloguesLineByLine.ItemVariantOfMaterial AS ItemVariantOfMaterial,
	|	TableAnaloguesLineByLine.SeveralMaterials AS SeveralMaterials,
	|	TableAnaloguesLineByLine.Count AS Count,
	|	CASE
	|		WHEN TableAnaloguesLineByLine.SeveralMaterials
	|			THEN NOT MaterialsOfPermission.Resolution IS NULL
	|		ELSE TRUE
	|	END AS LineBeingConsidered
	|FROM
	|	TableAnaloguesLineByLine AS TableAnaloguesLineByLine
	|		LEFT JOIN MaterialsOfPermission AS MaterialsOfPermission
	|		ON TableAnaloguesLineByLine.Material = MaterialsOfPermission.Products
	|			AND TableAnaloguesLineByLine.ItemVariantOfMaterial = MaterialsOfPermission.Characteristic
	|			AND TableAnaloguesLineByLine.Resolution = MaterialsOfPermission.Resolution
	|			AND (MaterialsOfPermission.LineNumber = 1)
	|			AND (TableAnaloguesLineByLine.SeveralMaterials)
	|WHERE
	|	CASE
	|			WHEN TableAnaloguesLineByLine.SeveralMaterials
	|				THEN NOT MaterialsOfPermission.Resolution IS NULL
	|			ELSE TRUE
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfMaterials.LineNumberDocument AS LineNumberDocument,
	|	TableOfMaterials.Products AS Products,
	|	TableOfMaterials.Characteristic AS Characteristic,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	TableOfMaterials.Warehouse AS Warehouse,
	|	TableOfMaterials.Total - TableOfMaterials.ToReplace AS Count,
	|	FALSE AS ThisIsASubstitute,
	|	TableOfMaterials.ToReplace > 0 AS NumberHasChanged
	|FROM
	|	TableOfMaterials AS TableOfMaterials
	|
	|UNION ALL
	|
	|SELECT
	|	0,
	|	TableOfIsolatedAnalogues.Products,
	|	TableOfIsolatedAnalogues.Characteristic,
	|	TableOfIsolatedAnalogues.Purpose,
	|	TableOfIsolatedAnalogues.Warehouse,
	|	TableOfIsolatedAnalogues.Count,
	|	TRUE,
	|	TRUE
	|FROM
	|	TableOfIsolatedAnalogues AS TableOfIsolatedAnalogues
	|WHERE
	|	TableOfIsolatedAnalogues.Count > 0
	|	AND TableOfIsolatedAnalogues.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	0,
	|	TableOfAnalogues.Products,
	|	TableOfAnalogues.Characteristic,
	|	VALUE(Catalog.Assignments.EmptyRef),
	|	TableOfAnalogues.Warehouse,
	|	TableOfAnalogues.Count - ISNULL(TableIsUsedSeparately.Count, 0),
	|	TRUE,
	|	TRUE
	|FROM
	|	TableOfAnalogues AS TableOfAnalogues
	|		LEFT JOIN TableIsUsedSeparately AS TableIsUsedSeparately
	|		ON TableOfAnalogues.Products = TableIsUsedSeparately.Products
	|			AND TableOfAnalogues.Characteristic = TableIsUsedSeparately.Characteristic
	|			AND TableOfAnalogues.Warehouse = TableIsUsedSeparately.Warehouse
	|WHERE
	|	TableOfAnalogues.Count - ISNULL(TableIsUsedSeparately.Count, 0) > 0
	|
	|ORDER BY
	|	ThisIsASubstitute DESC,
	|	LineNumberDocument,
	|	Purpose DESC";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("UsedMaterials", Stages.Unload());
	Query.SetParameter("Substitutes", UsedAnalogues.Unload());
	Query.SetParameter("SeparateAnalogues", RemnantsOfAnalogues.Unload());
	Query.SetParameter("AnalogsLineByLine", UsedAnaloguesLineByLine.Unload());
	
	MaterialsOfPermission = Substitutes.Unload(New Structure("ThisIsASubstitute", False), "Products, Characteristic, Resolution, LineNumber");
	MaterialsOfPermission.GroupBy("Products, Characteristic, Resolution, LineNumber");
	
	Query.SetParameter("MaterialsOfPermission", MaterialsOfPermission);
	
	Results = Query.ExecuteBatch();
	NumberOfPackages_ = Results.UBound();
	
	DataTable = Results[NumberOfPackages_].Unload();
	AnalogsLineByLine = Results[NumberOfPackages_ - 1].Unload();
	
	SummaryData = DataTable.CopyColumns();
	SearchForAnalogue = New Structure("Products, Characteristic");
	
	For Each TableRow In DataTable Do
	
		If TableRow.ThisIsASubstitute Then
			
			QuantityToDistribute = TableRow.Count;
			FillPropertyValues(SearchForAnalogue, TableRow);
			ArrayOfAnalogsLineByLine = AnalogsLineByLine.FindRows(SearchForAnalogue);
			
			For Each SpecificationRow In ArrayOfAnalogsLineByLine Do
			
				SubstituteQuantity = Min(QuantityToDistribute, SpecificationRow.Count);
				If SubstituteQuantity <> 0 Then
				
					SpecificationRow.Count = SpecificationRow.Count - SubstituteQuantity;
					QuantityToDistribute = QuantityToDistribute - SubstituteQuantity;
					
					NewRow = SummaryData.Add();
					FillPropertyValues(NewRow, TableRow,, "Count, LineNumberDocument");
					NewRow.Count = SubstituteQuantity;
					NewRow.LineNumberDocument = SpecificationRow.LineNumberDocument;	
				
				EndIf;
				
				If QuantityToDistribute = 0 Then
					Break;
				EndIf;
			
			EndDo;
			
			If QuantityToDistribute > 0 Then
				NewRow = SummaryData.Add();
				FillPropertyValues(NewRow, TableRow);
				NewRow.Count = QuantityToDistribute;
				NewRow.LineNumberDocument = -1;
			EndIf;
			
		Else
			
			NewRow = SummaryData.Add();
			FillPropertyValues(NewRow, TableRow);
		
		EndIf;
	
	EndDo;
	
	Return PutToTempStorage(SummaryData);

EndFunction

&AtClientAtServerNoContext
Procedure SetUpWaitingInForm(Form, ShowTimeConsumingOperation, PresentationOperation = "")
	
	Items = Form.Items;
	
	Items.FormPages.CurrentPage = ?(ShowTimeConsumingOperation,
		Items.TimeConsumingOperationPage, Items.PageOfMaterialsAndAnalogues);
	Items.Replace_With_Analogues.Visible = Not ShowTimeConsumingOperation And Not Form.ModeFromDocument;
	Items.FormReread.Visible = Not ShowTimeConsumingOperation And Not Form.ModeFromDocument;
	Form.CommandBarLocation = ?(ShowTimeConsumingOperation Or Form.ModeFromDocument,
		FormCommandBarLabelLocation.None, FormCommandBarLabelLocation.Auto);
	
	Items.TimeConsumingOperationPresentation.Title = PresentationOperation;
	
EndProcedure

&AtClient
Procedure StartAwaitingLongAction(OutputIdleWindow = True)
	
	CallbackOnCompletion = New CallbackDescription(TimeConsumingOperationIdleHandler, ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	
	IdleParameters.OutputIdleWindow = OutputIdleWindow;
	
	TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			CallbackOnCompletion,
			IdleParameters);
	
	StartAwaitingLongAction = False;
	
EndProcedure

&AtServer
Procedure FillInStructureWithAttributesOfForm(StructureOfFormData)

	StructureOfFormData.Insert("Resolution", Resolution);
	StructureOfFormData.Insert("ReplacementPriority", ReplacementPriority);
	StructureOfFormData.Insert("SelectionOfInterchangeableAnalogues", SelectionOfInterchangeableAnalogues);

EndProcedure

&AtServer
Procedure FillInByStrategyAtServer(FillingInUnloaded)
	
	If Stages.Count() = 0 Then
		
		StartAwaitingLongAction = False;
		MessageText = NStr("vi = 'Không có dữ liệu để điền';
							|ru = 'Нет данных для заполнения';
							|en = 'No data to fill'; fa = 'No data to fill';
							|it = 'Нет данных для заполнения';
							|pl = 'No data to fill';
							|tr = 'Doldurulacak veri yok'");
		Common.MessageToUser(MessageText,, "Stages");
		Return;
	
	EndIf;
	
	InitializeData();
		
	Tree = FormAttributeToValue("ReplacementTree");
	
	StructureOfFormData = New Structure;
	FillInStructureWithAttributesOfForm(StructureOfFormData);
	StructureOfFormData.Insert("RemnantsOfAnalogues", RemnantsOfAnalogues.Unload());
	StructureOfFormData.Insert("Stages", Stages.Unload());
	StructureOfFormData.Insert("Standards", Standards.Unload());
	StructureOfFormData.Insert("StageSelectionStructure", StageSelectionStructure());
	StructureOfFormData.Insert("Tree", Tree);
	StructureOfFormData.Insert("FillingInUnloaded", FillingInUnloaded);	
	
	// Starting the formation
	CancelLongRunningOperation();
		
	ParametersForProcessing = New Structure;
	ParametersForProcessing.Insert("StructureOfFormData", StructureOfFormData);
	
	AddressIsResultOfFormation = PutToTempStorage(
		Documents.EngineeringChangeOrder.ResultOfAutomaticFillingOfAssistant(), UUID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Trợ lý thực hiện thay thế: điền theo chiến lược';
														|ru = 'Помощник выполнения замен: заполнение по стратегии';
														|en = 'Replacement wizard: fill in by strategy'; fa = 'Replacement wizard: fill in by strategy';
														|it = 'Replacement wizard: fill in by strategy';
														|pl = 'Replacement wizard: fill in by strategy';
														|tr = 'Yer değiştirme sihirbazı: stratejiye göre doldurma'");
	ExecutionParameters.ResultAddress = AddressIsResultOfFormation;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Documents.EngineeringChangeOrder.FillOutStrategyAssistantOnHold",
		ParametersForProcessing,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = "FillInUsingDeferredStrategyCompletion";
		StartAwaitingLongAction = True;
		
	Else
		
		FillInUsingDeferredStrategy(TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;	

EndProcedure

&AtClient
Procedure FillInUsingDeferredStrategyCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	SetUpWaitingInForm(ThisObject, False);
	
	FillInUsingDeferredStrategy(Result);
	
	If Result <> Undefined And Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInUsingDeferredStrategy(Result)
	
	IsJobCompleted = False;
	
	If IsTempStorageURL(AddressIsResultOfFormation) Then
		
		ResultStructure1 = GetFromTempStorage(AddressIsResultOfFormation);
		AddressIsResultOfFormation = Undefined;
		
		ValueToFormAttribute(ResultStructure1.Tree, "ReplacementTree");
		RemnantsOfAnalogues.Load(ResultStructure1.BalanceTable);
		Stages.Load(ResultStructure1.StepsTable);
		
		MessageText = NStr("vi = 'Đã hoàn tất quy trình điền';
							|ru = 'Завершен процесс заполнения';
							|en = 'Filling process is completed'; fa = 'Filling process is completed';
							|it = 'Filling process is completed';
							|pl = 'Filling process is completed';
							|tr = 'Doldurma süreci tamamlandı'");
		
		Common.MessageToUser(MessageText);
		IsJobCompleted = True;
				
	EndIf;
	
	If Result = Undefined
		Or Result.Status <> "Completed2" Then
		Common.MessageToUser(NStr("vi = 'Không thể điền biểu mẫu';
									|ru = 'Не удалось заполнить форму';
									|en = 'Cannot fill in the form'; fa = 'Cannot fill in the form';
									|it = 'Cannot fill in the form';
									|pl = 'Cannot fill in the form';
									|tr = 'Form doldurulamadı'"));
	EndIf;
	
	If IsJobCompleted Then
	
		Items.FormPages.CurrentPage = Items.PageOfMaterialsAndAnalogues;
		Items.Replace_With_Analogues.Visible = True;
		Items.FormReread.Visible = True;
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInByAvailabilityAtServer()
	
	If Stages.Count() = 0 Then
		
		StartAwaitingLongAction = False;
		MessageText = NStr("vi = 'Không có dữ liệu để điền theo tính khả dụng';
							|ru = 'Нет данных для заполнения по доступности';
							|en = 'There is no data to fill in by availability'; fa = 'There is no data to fill in by availability';
							|it = 'There is no data to fill in by availability';
							|pl = 'There is no data to fill in by availability';
							|tr = 'Mevcudiyete göre doldurma için veri yok'");
		Common.MessageToUser(MessageText,, "Stages");
		Return;
	
	EndIf;
	
	InitializeData();
		
	Tree = FormAttributeToValue("ReplacementTree");
	
	StructureOfFormData = New Structure;
	FillInStructureWithAttributesOfForm(StructureOfFormData);
	StructureOfFormData.Insert("RemnantsOfAnalogues", RemnantsOfAnalogues.Unload());
	StructureOfFormData.Insert("Stages", Stages.Unload());
	StructureOfFormData.Insert("Standards", Standards.Unload());
	StructureOfFormData.Insert("StageSelectionStructure", StageSelectionStructure());
	StructureOfFormData.Insert("Tree", Tree);
	
	// Starting the formation
	CancelLongRunningOperation();
		
	ParametersForProcessing = New Structure;
	ParametersForProcessing.Insert("StructureOfFormData", StructureOfFormData);
	
	AddressIsResultOfFormation = PutToTempStorage(
		Documents.EngineeringChangeOrder.ResultOfAutomaticFillingOfAssistant(), UUID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Trợ lý thực hiện thay thế: điền theo tính khả dụng';
														|ru = 'Помощник выполнения замен: заполнение по доступности';
														|en = 'Replacement wizard: fill in by availability'; fa = 'Replacement wizard: fill in by availability';
														|it = 'Replacement wizard: fill in by availability';
														|pl = 'Replacement wizard: fill in by availability';
														|tr = 'Yer değiştirme sihirbazı: mevcudiyete göre doldurma'");
	ExecutionParameters.ResultAddress = AddressIsResultOfFormation;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Documents.EngineeringChangeOrder.FillOutAccessibilityAssistantOnHold",
		ParametersForProcessing,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		TimeConsumingOperationIdleHandler = "FillInByAvailabilityDeferredCompletion";
		StartAwaitingLongAction = True;
		
	Else
		
		FillInByAvailabilityDeferred(TimeConsumingOperation);
		
		StartAwaitingLongAction = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;	

EndProcedure

&AtClient
Procedure FillInByAvailabilityDeferredCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	SetUpWaitingInForm(ThisObject, False);
	
	FillInByAvailabilityDeferred(Result);
	
	If Result <> Undefined And Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInByAvailabilityDeferred(Result)
	
	IsJobCompleted = False;
	
	If IsTempStorageURL(AddressIsResultOfFormation) Then
		
		ResultStructure1 = GetFromTempStorage(AddressIsResultOfFormation);
		AddressIsResultOfFormation = Undefined;
		
		ValueToFormAttribute(ResultStructure1.Tree, "ReplacementTree");
		RemnantsOfAnalogues.Load(ResultStructure1.BalanceTable);
		Stages.Load(ResultStructure1.StepsTable);
		
		MessageText = NStr("vi = 'Đã hoàn tất quy trình điền theo tính khả dụng';
							|ru = 'Завершен процесс заполнения по доступности';
							|en = 'Filling by availability is completed'; fa = 'Filling by availability is completed';
							|it = 'Filling by availability is completed';
							|pl = 'Filling by availability is completed';
							|tr = 'Mevcudiyete göre doldurma işlemi tamamlandı'");
		
		Common.MessageToUser(MessageText);
		IsJobCompleted = True;
				
	EndIf;
	
	If Result = Undefined
		Or Result.Status <> "Completed2" Then
		Common.MessageToUser(NStr("vi = 'Không thể điền biểu mẫu theo tính khả dụng';
									|ru = 'Не удалось заполнить форму по доступности';
									|en = 'Cannot fill in the form by availability'; fa = 'Cannot fill in the form by availability';
									|it = 'Cannot fill in the form by availability';
									|pl = 'Cannot fill in the form by availability';
									|tr = 'Mevcudiyete göre form doldurulamadı'"));
	EndIf;
	
	If IsJobCompleted Then
	
		Items.FormPages.CurrentPage = Items.PageOfMaterialsAndAnalogues;
		Items.Replace_With_Analogues.Visible = True;
		Items.FormReread.Visible = True;
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	
	EndIf;
	
EndProcedure

#EndRegion
