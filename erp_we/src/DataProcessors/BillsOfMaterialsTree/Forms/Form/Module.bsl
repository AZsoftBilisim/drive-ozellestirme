
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not Parameters.Property("Date", TreeDate) Then
		TreeDate = CurrentSessionDate();
	EndIf;
	
	ProductDataManagement.LoadSelectionSettingsOfSpecificationTree(ThisObject);
	
	CurrentSettingValueIsToDisplayBalanceOfGoods = ValueOfSettingOutputOfWarehouseBalances();
	If CurrentSettingValueIsToDisplayBalanceOfGoods = Undefined Then
		AskQuestionAboutSavingSettingsOfBalanceOutput = True;
	Else
		DisplayGoodsBalance = CurrentSettingValueIsToDisplayBalanceOfGoods;
	EndIf;
		
	If Parameters.Property("Products") Then
		If Parameters.Products.IsFolder Then
			Return;
		EndIf;
		TreeProducts = Parameters.Products;
		
		// We check the use of characteristics for the item.
		CheckResult = Catalogs.Products.CharacteristicAndPackagingBelongToOwner(
			TreeProducts,
			Catalogs.ItemsCharacteristics.EmptyRef(),
			Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
		
		ProductCharacteristicIsUsed = CheckResult.ItemVariantsAreUsed;
	EndIf;
	
	If Parameters.Property("ProductCharacteristic") Then
		TheTreeIsACharacteristicOfAnItem = Parameters.ProductCharacteristic;
	EndIf;
	
	If Parameters.Property("BillOfMaterials") Then
		BillOfMaterials = CheckGetSpecification(Parameters.BillOfMaterials);
	EndIf;
	
	If Parameters.Property("Mode") Then
		Mode = Parameters.Mode;
	Else
		Mode = ProductDataManagementClientServer.SpecificationTreeMode();
	EndIf;
	
	ConfigureSpecificationAssignmentParameters(Parameters);
	
	ConfigureTaggingOfAdditionalCommands(ThisObject);
	
	If Mode = ProductDataManagementClientServer.OrderSpecificationTreeMode() Then
		
		FillInOrderSpecificationDetails(Parameters);
		
		Items.BOMsTree.ReadOnly = True;
		Items.GroupListOfAvailableSpecifications.Visible = False;
	
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		CloseOnOwnerClose = True;
		
	EndIf;
	
	DynamicReading = (Mode = ProductDataManagementClientServer.SpecificationTreeMode());
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(New Structure(), DataProcessors.BillsOfMaterialsTree);
	
	If Not Parameters.Property("Title", Title) And Not BillOfMaterials.IsEmpty() Then
		Title = StrTemplate(NStr("vi = 'Cây bảng kê chi tiết các nguồn lực sản xuất ''''%1''''';
								|ru = 'Дерево спецификации ""%1""';
								|en = '""%1"" BOM tree'; fa = '""%1"" BOM tree';
								|it = 'Albero della specifica ""%1""';
								|pl = 'Drzewo specyfikacji ""%1""';
								|tr = '""%1"" ürün ağacı'"), BillOfMaterials);
	EndIf;
	
	If Parameters.Property("GenerateOnOpen") Then
		CreateSpecificationTreeOnServer();
	EndIf;
	
	ExpandedLevelsOfCacheTree = ProductDataManagementClientServer.ExpandedLevelsOfCacheConstructorTree();
	
	SetPropertiesOfDynamicListOfAvailableSpecifications();
	
	CurrentSessionDate = CurrentSessionDate();
	SelectedModeColor = StyleColors.FormTextColor;
	UnselectedModeColor = StyleColors.HyperlinkColor;
	
	ConfigureDependentFormElements(ThisObject);
	CustomizeBasementPages();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Mode <> ProductDataManagementClientServer.OrderSpecificationTreeMode()
		And Not ValueIsFilled(BillOfMaterials)
		And Not ValueIsFilled(TreeProducts) Then
		
		WarningText = NStr("vi = 'Cây bảng kê chi tiết các nguồn lực sản xuất được xây dựng trong ngữ cảnh mặt hàng, danh sách bảng kê chi tiết các nguồn lực sản xuất hoặc bảng kê chi tiết các nguồn lực sản xuất đơn hàng.';
							|ru = 'Дерево спецификаций строится в контексте номенклатуры, ресурсной спецификации или спецификации заказа.';
							|en = 'BOM tree is built for products, BOM or order BOM.'; fa = 'BOM tree is built for products, BOM or order BOM.';
							|it = 'Albero della specifica viene creato nel contesto di articolo, della specifica di risorse o della specifica dell''ordine.';
							|pl = 'Drzewo specyfikacji buduje się w kontekście nomenklatury, zasobów specyfikacji lub specyfikacji zamówienia.';
							|tr = 'Ürün ağacı; öğe, ürün reçetesi veya sipariş ürün reçetesi kapsamında oluşturulmaktadır.'");
		ShowMessageBox(,WarningText);
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	CurrentRow = Items.BOMsTree.CurrentRow;
	
	If ChoiceSource.FormName = "Catalog.BillsOfMaterials.Form.ChoiceFormByItems" Then
		
		ChangeSpecificationInCurLine(CurrentRow, ValueSelected);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_BillsOfMaterials" Then
		
		If Not Items.ListOfAvailableBillsOfResources.Visible Then
			Items.ListOfAvailableBillsOfResources.Refresh();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateData1();
	
EndProcedure

&AtClient
Procedure DisplayStagesWhenChanging(Item)
	
	FilterParametersAreChanged();
	
EndProcedure

&AtClient
Procedure OutputOutputItemsWhenChanging(Item)
	
	FilterParametersAreChanged();
	
EndProcedure

&AtClient
Procedure OutputMaterialsWhenChanged(Item)
	
	FilterParametersAreChanged();
	
EndProcedure

&AtClient
Procedure OutputLaborCostsWhenChanging(Item)
	
	FilterParametersAreChanged();
	
EndProcedure

&AtClient
Procedure ProductionDispatcherBusinessUnitOnChange(Item)
	WhenChangingValueOfSpecificationAssignmentParameter();
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	WhenChangingValueOfSpecificationAssignmentParameter();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBOMsTree

&AtClient
Procedure BOMsTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "BOMsTreeProducts" 
		And ValueIsFilled(Item.CurrentData.Products) 
		And TypeOf(Item.CurrentData.Products) <> Type("String")
		And Not ValueIsFilled(Item.CurrentData.ProductKind) Then
		
		StandardProcessing = False;
		ShowValue(Undefined, Item.CurrentData.Products);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BOMsTreeOnActivateRow(Item)
	
	If Mode = ProductDataManagementClientServer.SpecificationTreeMode() Then
		AttachIdleHandler("HandleTreeRowActivation", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure BOMsTreeBeforeExpand(Item, String, Cancel)
	
	ProductDataManagementClient.BOMsTreeBeforeExpand(ThisObject, String, Cancel);
	
EndProcedure

&AtClient
Procedure BOMsTreeBeforeCollapse(Item, String, Cancel)
	
	ProductDataManagementClient.BOMsTreeBeforeCollapse(ThisObject, String, Cancel);
	
EndProcedure

&AtClient
Procedure BOMsTreeBillOfMaterialsStartChoice(Item, ChoiceData, StandardProcessing)
	
	ProductDataManagementClient.BOMsTreeBillOfMaterialsStartChoice(
		ThisObject, Item, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BOMsTreeBillOfMaterialsClearing(Item, StandardProcessing)
	
	CurrentRow = Items.BOMsTree.CurrentRow;
	ChangeSpecificationInCurLine(CurrentRow);
	
EndProcedure

&AtClient
Procedure BOMsTreeProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.BOMsTree.CurrentData;
	
	If ValueIsFilled(CurrentData.ProductKind) Then
		
		Item.TypeRestriction = New TypeDescription("CatalogRef.Products");
		
	Else
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BOMsTreeProductsOnChange(Item)
	
	CurrentRow = Items.BOMsTree.CurrentRow;
	CurrentData = Items.BOMsTree.CurrentData;
	
	ProductDataManagementClient.SaveExpandedTreeLevels(ThisObject, CurrentData);
	
	ProductSpecificationTreeWhenModifiedOnServer(CurrentRow);
	
	ProductDataManagementClient.RestoreExpandedTreeLevels(ThisObject, CurrentData);
	
EndProcedure

&AtServer
Procedure ProductSpecificationTreeWhenModifiedOnServer(CurrentRow)
	
	CurrentData = BOMsTree.FindByID(CurrentRow);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	StructureOfActions.Insert("CheckPackagingByOwner", CurrentData.Package);
	StructureOfActions.Insert("FillInUnitOfMeasurementAttribute", New Structure("Products", "UnitOfMeasure"));
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
	HandleChangingTreeRowPropsOnServer(CurrentRow);
	
EndProcedure

&AtClient
Procedure BOMsTreeCharacteristicOnChange(Item)
	
	CurrentRow = Items.BOMsTree.CurrentRow;
	CurrentData = Items.BOMsTree.CurrentData;
	
	ProductDataManagementClient.SaveExpandedTreeLevels(ThisObject, CurrentData);
	
	SpecificationTreeCharacteristicWhenModifiedOnServer(CurrentRow);
	
	ProductDataManagementClient.RestoreExpandedTreeLevels(ThisObject, CurrentData);
	
EndProcedure

&AtServer
Procedure SpecificationTreeCharacteristicWhenModifiedOnServer(CurrentRow)
	
	CurrentData = BOMsTree.FindByID(CurrentRow);
	
	Var_Key = ProductDataManagementClientServer.KeyParametersForSelectingTreeSpecifications(CurrentData);
	
	StructureOfSpecificationFilling = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		ThisObject, CurrentData, BOMSelectionParameters[Var_Key]);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillSpecification", StructureOfSpecificationFilling);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
	HandleChangingTreeRowPropsOnServer(CurrentRow);
	
EndProcedure

&AtClient
Procedure BOMsTreePackageOnChange(Item)
	
	CurrentRow = Items.BOMsTree.CurrentRow;
	CurrentData = Items.BOMsTree.CurrentData;
	
	ProductDataManagementClient.SaveExpandedTreeLevels(ThisObject, CurrentData);
	
	SpecificationTreePackagingWhenModifiedOnServer(CurrentRow);
	
	ProductDataManagementClient.RestoreExpandedTreeLevels(ThisObject, CurrentData);

EndProcedure

&AtServer
Procedure SpecificationTreePackagingWhenModifiedOnServer(CurrentRow)
	
	CurrentData = BOMsTree.FindByID(CurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
	HandleChangingTreeRowPropsOnServer(CurrentRow);
	
EndProcedure

&AtClient
Procedure BOMsTreeNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.BOMsTree.CurrentRow;
	CurrentData = Items.BOMsTree.CurrentData;
	
	ProductDataManagementClient.SaveExpandedTreeLevels(ThisObject, CurrentData);
	
	SpecificationTreeNumberOfPackagesWhenChangedOnServer(CurrentRow);
	
	ProductDataManagementClient.RestoreExpandedTreeLevels(ThisObject, CurrentData);
	
EndProcedure

&AtServer
Procedure SpecificationTreeNumberOfPackagesWhenChangedOnServer(CurrentRow)
	
	CurrentData = BOMsTree.FindByID(CurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
	HandleChangingTreeRowPropsOnServer(CurrentRow);
	
EndProcedure

&AtClient
Procedure BOMsTreeBeforeRowChange(Item, Cancel)
	
	ProductDataManagementClient.BOMsTreeBeforeRowChange(Item, Cancel);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfAvailableBillsOfResources

&AtClient
Procedure ListOfAvailableBillsOfResourcesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.ListOfAvailableBillsOfResources.CurrentData;
	If CurrentData <> Undefined Then
		ShowValue(,CurrentData.BillOfMaterials);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GenerateTree(Command)
	
	UpdateData1();
	
EndProcedure

&AtClient
Procedure PrintBORTree(Command)
	
	CommandParameter = New Array;
	CommandParameter.Add(PredefinedValue("Catalog.BillsOfMaterials.EmptyRef"));
	
	TemplatesNames = "BOMsTree";
	PrintParameters = SpecificationTreePrintingOptions();
	
	PrintManagementClient.ExecutePrintCommand(
		"DataProcessor.BillsOfMaterialsTree",
		TemplatesNames,
		CommandParameter,
		ThisObject,
		PrintParameters);
	
EndProcedure

&AtClient
Procedure TheCommandToDeployAll(Command)
	
	ProductDataManagementClient.ExpandAllLevelsOfTree(ThisObject);
	
EndProcedure

&AtClient
Procedure CollapseAllCommand(Command)
	
	ProductDataManagementClient.CollapseAllLevelsOfTree(ThisObject);
	
EndProcedure

&AtClient
Procedure HideGroupingTitles(Command)
	
	TreeDisplayGroupingHeaders = Not TreeDisplayGroupingHeaders;
	
	ConfigureTaggingOfAdditionalCommands(ThisObject);
	
	FilterParametersAreChanged();
	
EndProcedure

&AtClient
Procedure OutputOfOperationsTogetherWithStages(Command)
	
	TreeOutputOfOperations = Not TreeOutputOfOperations;
	
	ConfigureTaggingOfAdditionalCommands(ThisObject);
	
	FilterParametersAreChanged();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ListOfAvailableBillsOfResources.ConditionalAppearance.Items.Clear();
	Catalogs.BillsOfMaterials.SetConditionalAppearanceOfListOfAvailableSpecifications(ListOfAvailableBillsOfResources.ConditionalAppearance);
	ProductDataManagement.ConfigureConditionalAppearanceOfSpecificationTree(ConditionalAppearance);
	
	#Region StockBalance
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("StockBalancePeriodDescription");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StockBalance.Period");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = BegOfDay(CurrentSessionDate());

	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);
	
	#EndRegion
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("MainLevel")
		Or Initialize Then
		
		Rows = Form.BOMsTree.GetItems();
		If Rows.Count() > 0 Then
			
			MainLevel = Rows[0];
			If ValueIsFilled(MainLevel.ProductKind) Then
				Items.BOMsTreeProducts.HeaderPicture = PictureLib.Change;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("StockBalance")
		Or Initialize Then
		
		ItemArray = New Array; // Array of String
		ItemArray.Add(Items.BOMsTreeWarehouse.Name);
		ItemArray.Add(Items.BOMsTreeInStock.Name);
		ItemArray.Add(Items.BOMsTreeAvailable.Name);
	
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Form.Items, ItemArray, "Visible", Form.DisplayGoodsBalance);
			
		Form.Items.ShowBalance.Check = Form.DisplayGoodsBalance;
	
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPropertiesOfDynamicListOfAvailableSpecifications()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	QueryText = Catalogs.BillsOfMaterials.RequestTextForDynamicListOfAvailableSpecifications();
	ListProperties.QueryText = QueryText;
	
	ListProperties.MainTable = "";
	ListProperties.DynamicDataRead = False;
	
	Common.SetDynamicListProperties(Items.ListOfAvailableBillsOfResources, ListProperties);
	
	CurrentFilter = ProductDataManagementClientServer.SelectionStructureOfListOfAvailableSpecifications();
	CurrentFilter.Products   = TreeProducts;
	CurrentFilter.Characteristic = TheTreeIsACharacteristicOfAnItem;
	
	SetParametersForListOfAvailableSpecifications(CurrentFilter);
	
EndProcedure

&AtServerNoContext
Function CheckGetSpecification(BillOfMaterials)
	
	Query = New Query(
	"SELECT
	|	Table.Ref AS BillOfMaterials
	|FROM
	|	Catalog.BillsOfMaterials AS Table
	|WHERE
	|	Table.Ref = &BillOfMaterials AND NOT Table.IsFolder");
	Query.SetParameter("BillOfMaterials", BillOfMaterials);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	If Selection.Next() Then
		Result = Selection.BillOfMaterials;
	Else
		Result = Catalogs.BillsOfMaterials.EmptyRef();
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInOrderSpecificationDetails(FillingData)
	
	OrderBOMAttributes = New Structure;
	
	OrderBOMAttributes.Insert("ConnectionKey", FillingData.ConnectionKey);
	
	OrderBOMAttributes.Insert("OutputProductPackaging", FillingData.Package);
	OrderBOMAttributes.Insert("OutputProductQuantity", FillingData.Count);
	OrderBOMAttributes.Insert("NumberOfPackagesOfOutputProduct", FillingData.NumberOfPackages);
	
	OrderBOMAttributes.Insert("AddressInStorage", Parameters.AddressInStorage);

EndProcedure

&AtServer
Function SpecificationTreePrintingOptions()
	
	Tree = ProductDataManagement.ReadSpecTree(ThisObject);
	
	PrintParameters = New Structure;
	PrintParameters.Insert("AddressInStorage", PutToTempStorage(Tree, UUID));
	
	Return PrintParameters;
	
EndFunction

&AtClient
Procedure UpdateData1()
	
	ProductDataManagementClient.SaveExpandedTreeLevels(ThisObject);
	
	CreateSpecificationTreeOnServer();
	
	ProductDataManagementClient.RestoreExpandedTreeLevels(ThisObject);
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure HandleTreeRowActivation()
	
	CheckSetParametersForListOfAvailableSpecifications();
	
	CheckSetParametersOfGoodsBalanceTree();
	
EndProcedure

&AtServer
Function SpecificationTreeParameters()
	
	TreeParameters = ProductDataManagementClientServer.SpecificationTreeParameters();
	
	If BOMsTree.GetItems().Count() <> 0 Then
		String = BOMsTree.GetItems()[0];
		TreeParameters.Products               = String.Products;
		TreeParameters.ProductCharacteristic = String.Characteristic;
		TreeParameters.BillOfMaterials               = String.BillOfMaterials;
	Else
		TreeParameters.Products               = TreeProducts;
		TreeParameters.ProductCharacteristic = TheTreeIsACharacteristicOfAnItem;
		TreeParameters.BillOfMaterials               = BillOfMaterials;
	EndIf;
	
	TreeParameters.BOMSelectionParameters  = BOMSelectionParameters;
	
	TreeParameters.Date                         = TreeDate;
	TreeParameters.ProductionDispatcherBusinessUnit       = AssignmentParameterDivisionManager;
	TreeParameters.LineOfBusiness      = DestinationParameterActivityDirection;
	
	TreeParameters.DynamicReading       = DynamicReading;
	
	ProductDataManagement.FillInSelectionSettingsOfSpecificationTree(TreeParameters, ThisObject);
	
	If Mode = ProductDataManagementClientServer.SpecificationTreeMode() Then
		TreeParameters.UnravelSemiFinishedProducts = True;
		
		Parameters.Property("OutputProductQuantity",         TreeParameters.OutputProductQuantity);
		Parameters.Property("NumberOfPackagesOfOutputProduct", TreeParameters.NumberOfPackagesOfOutputProduct);
		Parameters.Property("OutputProductPackaging",           TreeParameters.OutputProductPackaging);
		
	EndIf;
	
	If Mode = ProductDataManagementClientServer.OrderSpecificationTreeMode() Then
		FillPropertyValues(TreeParameters, OrderBOMAttributes);
	EndIf;
	
	TreeParameters.DisplayBalanceOfGoods = DisplayGoodsBalance;
	
	Return TreeParameters;
	
EndFunction

&AtServer
Procedure CreateSpecificationTreeOnServer()
	
	If FilterParametersAreChanged Then
		SaveSelectionParameters();
	EndIf;
	
	TreeParameters = SpecificationTreeParameters();
	
	ProductDataManagement.BuildSpecificationTree(ThisObject, TreeParameters);
	
EndProcedure

&AtClient
Function FindStringByID_(TreeItemsCollection, Id)
	
	For Each String In TreeItemsCollection Do
		
		If String.Id = Id Then
			Return String;
		Else
			Result = FindStringByID_(String.GetItems(), Id);
			If Result <> Undefined Then
				Return Result;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure CheckSetParametersForListOfAvailableSpecifications()
	
	CurrentData = Items.BOMsTree.CurrentData;
	
	NewFilter = ProductDataManagementClientServer.SelectionStructureOfListOfAvailableSpecifications();
	
	If CurrentData <> Undefined Then
		
		If TypeOf(CurrentData.Products) = Type("CatalogRef.Products") Then
			NewFilter.Products   = CurrentData.Products;
			NewFilter.Characteristic = CurrentData.Characteristic;
		EndIf;
		
	EndIf;
	
	If NewFilter.Products <> CurrentFilter.Products
		Or NewFilter.Characteristic <> CurrentFilter.Characteristic Then
		SetParametersForListOfAvailableSpecifications(NewFilter);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetParametersForListOfAvailableSpecifications(NewFilter)
	
	CurrentFilter = NewFilter;
	AvailableSpecifications = Undefined;
	CurrentRow = Items.BOMsTree.CurrentRow;
	
	If ValueIsFilled(NewFilter.Products) And CurrentRow <> Undefined Then
		
		CurrentData = BOMsTree.FindByID(CurrentRow);
		
		ProductData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
		ProductData.Products            = NewFilter.Products;
		ProductData.Characteristic          = NewFilter.Characteristic;
		ProductData.ProductionStart      = TreeDate;
		ProductData.LineOfBusiness = DestinationParameterActivityDirection;
		ProductData.ProductionDispatcherBusinessUnit  = AssignmentParameterDivisionManager;
		
		Var_Key = ProductDataManagementClientServer.KeyParametersForSelectingTreeSpecifications(CurrentData);
		
		AvailableSpecifications = ProductDataManagement.ListOfSpecificationsByProduct(
			ProductData,
			BOMSelectionParameters[Var_Key]);
	
	EndIf; 
	
	CommonClientServer.SetDynamicListParameter(
									ListOfAvailableBillsOfResources, "BOMList", AvailableSpecifications);
	
EndProcedure

&AtServer
Procedure HandleChangingTreeRowPropsOnServer(CurrentRow)

	CurrentData = BOMsTree.FindByID(CurrentRow);

	CurrentData.GetItems().Clear();
	
	CurrentData.ThereIsBOM = ValueIsFilled(CurrentData.BillOfMaterials);
	CurrentData.BOMIsRead = False;
	
	If CurrentData.ThereIsBOM Then
		
		TreeParameters = SpecificationTreeParameters();
		If TreeParameters.BillOfMaterials <> CurrentData.BillOfMaterials Then
			TreeParameters.BillOfMaterials = Catalogs.BillsOfMaterials.EmptyRef();
		EndIf;
		ProductDataManagement.ChangeSpecificationInTreeLine(ThisObject, TreeParameters, CurrentData);
		
	ElsIf DynamicReading Then
		
		ProductDataManagement.UpdateTreeRowDetailsInRepository(ThisObject, CurrentData);
		
	EndIf;

EndProcedure

&AtClient
Procedure ChangeSpecificationInCurLine(CurrentRow, NewSpecification = Undefined)
	
	CurrentData = BOMsTree.FindByID(CurrentRow);
	
	CurrentData.BillOfMaterials = NewSpecification;
	
	HandleChangingTreeRowPropsOnServer(CurrentRow);
	
	ExpandSpecificationTree(CurrentRow, CurrentData.Id);

EndProcedure

&AtClient
Procedure ExpandSpecificationTree(CurrentRow, Id)
	
	If Items.BOMsTree.CurrentRow <> CurrentRow Then
		
		CurrentData = FindStringByID_(BOMsTree.GetItems(), Id);
		If CurrentData <> Undefined Then
			Items.BOMsTree.CurrentRow = CurrentData.GetID();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterParametersAreChanged()
	
	FilterParametersAreChanged = True;
	Items.PrintProductTree.Enabled = False;
	
EndProcedure

&AtServer
Procedure SaveSelectionParameters()
	
	ProductDataManagement.SaveSelectionSettingsOfSpecificationTree(ThisObject);
	
	Items.PrintProductTree.Enabled = True;
	FilterParametersAreChanged = False;
	
EndProcedure

&AtClient
Procedure WhenChangingValueOfSpecificationAssignmentParameter()
	
	UpdateHeaderOfSpecificationAssignmentParameterGroup(ThisObject);
	UpdateData1();
	
EndProcedure

&AtServer
Procedure ConfigureSpecificationAssignmentParameters(Var_Parameters)
	
	ItemAttribute = New Structure;
	ItemAttribute.Insert("ProductionDispatcherBusinessUnit",  "AssignmentParameterDivisionManager");
	ItemAttribute.Insert("LineOfBusiness", "DestinationParameterActivityDirection");
	
	GroupVisibility = False;
	
	For Each KeyAndValue In ItemAttribute Do
		ParameterName = KeyAndValue.Key;
		If ProductDataManagementCached.TypeOfDestinationParameterIsUsed(
					Enums.TypesOfBOMAssignmentParameters[ParameterName]) Then
			Items[ParameterName].Visible      = True;
			Items[ParameterName].ReadOnly = (Mode = ProductDataManagementClientServer.OrderSpecificationTreeMode());
			GroupVisibility = True;
			Var_Parameters.Property(ParameterName, ThisObject[KeyAndValue.Value]);
		EndIf;
	EndDo;
	
	Items.SpecificationAssignmentParametersGroup.Visible = GroupVisibility;
	If GroupVisibility Then
		UpdateHeaderOfSpecificationAssignmentParameterGroup(ThisObject);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureTaggingOfAdditionalCommands(Form)
	
	Form.Items.HideGroupingTitles.Check   = Not Form.TreeDisplayGroupingHeaders;
	Form.Items.OutputOfOperationsTogetherWithStages.Check = Form.TreeOutputOfOperations;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateHeaderOfSpecificationAssignmentParameterGroup(Form)
	
	QuantityFilled = 0;
	
	If ValueIsFilled(Form.AssignmentParameterDivisionManager) Then
		QuantityFilled = QuantityFilled + 1;
	EndIf;
	
	If ValueIsFilled(Form.DestinationParameterActivityDirection) Then
		QuantityFilled = QuantityFilled + 1;
	EndIf;
	
	Form.AssignmentParameterNumberOfFilledOnes = QuantityFilled;
	
EndProcedure

&AtClientAtServerNoContext
Function PageIndexAvailableSpecifications()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function IndexOfGoodsBalancePage()
	
	Return 2;
	
EndFunction

&AtClient
Procedure AvailableSpecificationsClick(Item)
	
	IndexOfCurPageOfBasement = PageIndexAvailableSpecifications();
	
	WhenSwitchingBasementPages();
	
EndProcedure

&AtClient
Procedure BalancesAndAvailabilityPressing(Item)
	
	If AskQuestionAboutSavingSettingsOfBalanceOutput Then
		AskQuestionAboutSavingBalanceOutputSettings();
	EndIf;
	
	IndexOfCurPageOfBasement = IndexOfGoodsBalancePage();
	
	WhenSwitchingBasementPages();
	
EndProcedure

&AtClient
Procedure ExpandBasement(Command)
	
	IndexOfCurPageOfBasement = ?(IndexOfCurPageOfBasement > 0, 0, 1);
	
	WhenSwitchingBasementPages();
	
EndProcedure

&AtClient
Procedure DisplayHideWarehouseBalances()
	
	AskQuestionAboutSavingSettingsOfBalanceOutput = False;
	DisplayGoodsBalance = Not DisplayGoodsBalance;
	SaveBalanceOutputSetting(DisplayGoodsBalance);
	ConfigureDependentFormElements(ThisObject, "StockBalance");
	UpdateData1();

EndProcedure

&AtClient
Procedure ShowBalance(Command)
	
	DisplayHideWarehouseBalances();
	
EndProcedure

&AtClient
Procedure WhenSwitchingBasementPages()
	
	ProductDataManagementClient.SaveExpandedTreeLevels(ThisObject);
	CustomizeBasementPages();
	ProductDataManagementClient.RestoreExpandedTreeLevels(ThisObject);
	
EndProcedure

&AtServer
Procedure CustomizeBasementPages()
	
	BasementVisibility = IndexOfCurPageOfBasement > 0;
	
	If BasementVisibility <> Items.FooterPages.Visible Then
		Items.FooterPages.Visible = BasementVisibility;
		If BasementVisibility Then
			Items.ExpandBasement.Picture = PictureLib.DownArrow;
		Else
			Items.ExpandBasement.Picture = PictureLib.RightArrow;
		EndIf;
	EndIf;
	
	TheseAreAvailableSpecifications = IndexOfCurPageOfBasement = PageIndexAvailableSpecifications();
	TheseAreBalancesOfGoods        = IndexOfCurPageOfBasement = IndexOfGoodsBalancePage();
	
	If TheseAreAvailableSpecifications Then
		Items.FooterPages.CurrentPage = Items.GroupListOfAvailableSpecifications;
	ElsIf TheseAreBalancesOfGoods Then
		Items.FooterPages.CurrentPage = Items.BalanceOfGoodsGroup;
	EndIf;
	
	Items.AvailableSpecificationsPage.Hyperlink = Not TheseAreAvailableSpecifications Or Not BasementVisibility;
	Items.AvailableSpecificationsPage.TextColor = ?(Items.AvailableSpecificationsPage.Hyperlink, UnselectedModeColor, SelectedModeColor);
	Items.ProductBalancePage.Hyperlink = Not TheseAreBalancesOfGoods Or Not BasementVisibility;
	Items.ProductBalancePage.TextColor = ?(Items.ProductBalancePage.Hyperlink , UnselectedModeColor, SelectedModeColor);
	
EndProcedure

&AtClient
Async Procedure AskQuestionAboutSavingBalanceOutputSettings()
	
	QueryText = NStr("vi = 'Đối với cây bảng kê chi tiết các nguồn lực sản xuất, cho phép hiển thị số dư trong kho theo sơ đồ đảm bảo trong các cột riêng biệt. Có thể quản lý phần hiển thị các cột trong menu Hơn nữa. Hiển thị các cột?';
					|ru = 'Для дерева спецификаций доступно отображение остатков на складе по схеме обеспечения в отдельных колонках. Управлять видимостью колонок можно в подменю Еще. Вывести колонки?';
					|en = 'For the product tree, you can display warehouse balances by supply schemes in separate columns. To control the visibility of columns, use the More actions submenu. Display the columns?'; fa = 'For the product tree, you can display warehouse balances by supply schemes in separate columns. To control the visibility of columns, use the More actions submenu. Display the columns?';
					|it = 'Для дерева спецификаций доступно отображение остатков на складе по схеме обеспечения в отдельных колонках. Управлять видимостью колонок можно в подменю Еще. Вывести колонки?';
					|pl = 'For the product tree, you can display warehouse balances by supply schemes in separate columns. To control the visibility of columns, use the More actions submenu. Display the columns?';
					|tr = 'Ürün ağacı için arz şemasına göre ambar bakiyelerini ayrı sütunlarda görüntülemek mümkündür. Daha fazla alt menüsünde sütunların görünürlüğünü kontrol edebilirsiniz. Sütunlar gösterilsin mi?'");
	
	Promise = DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	Result = Await Promise;
	
	IsAnswered = True;
	
	If Result = DialogReturnCode.Yes Then
		SaveBalanceOutputSetting(True);
		DisplayHideWarehouseBalances();
	ElsIf Result = DialogReturnCode.No Then 
		SaveBalanceOutputSetting(False);
	Else
		IsAnswered = False;
	EndIf;
	
	AskQuestionAboutSavingSettingsOfBalanceOutput = Not IsAnswered;
	
EndProcedure

&AtClient
Procedure CheckSetParametersOfGoodsBalanceTree()
	
	CurrentData = Items.BOMsTree.CurrentData;
	
	TypesOfRows = New Array;
	TypesOfRows.Add(PredefinedValue("Enum.TypesOfSpecificationLines.Products"));
	TypesOfRows.Add(PredefinedValue("Enum.TypesOfSpecificationLines.Material"));
	TypesOfRows.Add(PredefinedValue("Enum.TypesOfSpecificationLines.IntermediateSemiFinishedProduct"));
	TypesOfRows.Add(PredefinedValue("Enum.TypesOfSpecificationLines.FinishedProduct"));
	TypesOfRows.Add(PredefinedValue("Enum.TypesOfSpecificationLines.SideExit"));
	TypesOfRows.Add(PredefinedValue("Enum.TypesOfSpecificationLines.IncomingProduct"));
	
	ItemsTypes = New Array;
	ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	
	If IndexOfCurPageOfBasement <> IndexOfGoodsBalancePage()
		Or CurrentData = Undefined
		Or TypesOfRows.Find(CurrentData.LineKind) = Undefined
		Or ItemsTypes.Find(CurrentData.ItemsType) = Undefined Then
		StockBalance.GetItems().Clear();
		Return;
	EndIf;
	
	ItemData = New Structure;
	ItemData.Insert("Products");
	ItemData.Insert("Characteristic");
	
	If CurrentData <> Undefined
		And TypeOf(CurrentData.Products) = Type("CatalogRef.Products") Then
		
		ItemData.Products   = CurrentData.Products;
		ItemData.Characteristic = CurrentData.Characteristic;
		
	EndIf;
	
	ProductionSupplyClient.FillInGoodsBalanceTree(ThisObject, ItemData);
	
EndProcedure

&AtServerNoContext
Procedure SaveBalanceOutputSetting(SettingValue)

	Common.CommonSettingsStorageSave("BillsOfMaterialsTree", "DisplayGoodsBalance", SettingValue);

EndProcedure 

&AtServerNoContext
Function ValueOfSettingOutputOfWarehouseBalances()

	Return Common.CommonSettingsStorageLoad("BillsOfMaterialsTree", "DisplayGoodsBalance");

EndFunction

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_TreeDate" Then
		DateOnChange(Items.Date);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
