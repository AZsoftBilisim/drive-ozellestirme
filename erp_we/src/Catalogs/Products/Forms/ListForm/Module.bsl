#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FormCode = "Catalog_Products_ListForm";
	
	SelectGoodsServer.OnCreateAtServer(ThisForm);
	
	UncontrolledInputIsAvailable = Catalogs.Products.UncontrolledInputIsAvailable();
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	ThereIsTheRightToEdit = AccessRight("Edit", Metadata.Catalogs.Products);
	
	Items.CommandPanelListStandardSearchItemFormEditSelectedItems.Visible = ThereIsTheRightToEdit;
	Items.CommandPanelListAdvancedSearchItemFormEditSelectedItems.Visible = ThereIsTheRightToEdit;
	
	If Not AccessRight("Read", Metadata.InformationRegisters.ItemsBarcodes) Then
		Items.CommandPanelListAdvancedSearchItemFormBarcodeSearch.Visible = False;
		Items.CommandPanelListStandardSearchItemFormBarcodeSearch.Visible = False;
	EndIf;
	
	If ValueIsFilled(Parameters.FilterNomenclatureByProperties) Then
		SelectGoodsServer.FilterBySimilarProperties(ThisForm, Parameters.FilterNomenclatureByProperties);
	EndIf;
	
	PrintCommandPanel = ?(Items.PagesOfLists.CurrentPage = Items.PageAdvancedSearchProducts,
		Items.PrintListAdvancedSubmenu,
		Items.PrintListStandardSubmenu);
		
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = ?(Items.PagesOfLists.CurrentPage = Items.PageAdvancedSearchProducts,
											Items.CommandBarListAdvancedSearchProducts,
											Items.ListStandardSearchProductsCommandBar);
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, PrintCommandPanel);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	If UserRightsCached.ThisIsPartner() Then
		Items.CommandPanelListAdvancedSearchItemFormBarcodeSearch.Visible = False;
		Items.CommandPanelListStandardSearchItemFormBarcodeSearch.Visible = False;
	EndIf;
	
	Items.CommandPanelListAdvancedSearchItemFormEditSelectedItems.Visible = ThereIsTheRightToEdit;
	Items.ListAdvancedSearchItemContextMenuEditSelectedItems.Visible = ThereIsTheRightToEdit;
	Items.CommandPanelListStandardSearchItemFormEditSelectedItems.Visible = ThereIsTheRightToEdit;
	Items.ListStandardSearchItemContextMenuEditSelectedItems.Visible = ThereIsTheRightToEdit;
	Items.ItemHierarchyContextMenuEditSelectedItems.Visible = ThereIsTheRightToEdit;
	
	Parameters.Property("CurrentRow", ProductsItemWhenOpening);
	
	If ValueIsFilled(ProductsItemWhenOpening)
		And UseFilters Then
		If NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByHierarchy") Then
			ProductsParentWhenOpening = Common.ObjectAttributeValue(ProductsItemWhenOpening, "Parent");
		ElsIf NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByProperties")
			Or NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKindsAndProperties")
			Or NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKinds") Then
			ProductKind = Common.ObjectAttributeValue(ProductsItemWhenOpening, "ProductKind");
			ProductTypeWhenChangedOnServer();
			ProductKindOnOpening = ProductKind;
		EndIf;
	ElsIf Parameters.Property("FilterByTheProductKind") Then
		ProductKindOnOpening = ProductKind;
	EndIf;
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning

	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, ,"ListProducts");
	// End StandardSubsystems.Core
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Let's set the positioning to the selected item of the nomenclature in the form that caused the opening of this selection form.
	If ValueIsFilled(ProductsItemWhenOpening) Then
		If NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByHierarchy") Then
			Items.ProductsHierarchy.CurrentRow = ProductsParentWhenOpening;
			SelectGoodsClient.HandlerForActivatingLineInProductHierarchy(ThisForm);
		EndIf;
		ProductFormTable = Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(ThisForm)]; // FormTable
		ProductFormTable.CurrentRow = ProductsItemWhenOpening;
		Items.ItemKinds.CurrentRow = ProductKindOnOpening;
	ElsIf ValueIsFilled(ProductKindOnOpening) Then
		Items.ItemKinds.CurrentRow = ProductKindOnOpening;
	EndIf;
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
	If Not Exit Then
		SaveFormSettingsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData" Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
		
	EndIf;
	// End Peripherals
	
	
	If EventName = "Write_Products" Then
		If ValueIsFilled(SearchStringProducts) Then
			SearchForProducts();
		EndIf;
		If ValueIsFilled(Source) Then
			ProductFormTable = Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(ThisObject)]; // FormTable
			ProductFormTable.CurrentRow = Source;
		EndIf;
	EndIf;
	
	If EventName = "FilterBySimilarProperties_Products" Then
		If ValueIsFilled(Parameter) Then
			FilterBySimilarProperties(Parameter);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region EventHandlersForSearchStrings

&AtClient
Procedure SearchStringProductsOnChange(Item)
	
	SearchForProducts();
	
EndProcedure

&AtClient
Procedure SearchStringProductsClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	SearchStringProducts = "";
	
	DeselectProductSearchBarOnServer();
	
EndProcedure

#EndRegion

#Region EventHandlersForExactMatchFlags

&AtClient
Procedure FindAnItemByExactMatchOnChange(Item)
	
	SearchForProducts();
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure ProductSegmentOnChange(Item)
	
	ProductItemSegmentWhenChangedOnServer();
	
	If ValueIsFilled(SearchStringProducts) Then
		SearchForProducts();
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductKindOnChange(Item)
	
	ProductTypeWhenChangedOnServer();
	
	If ValueIsFilled(SearchStringProducts) Then
		SearchForProducts();
	EndIf;
	
EndProcedure

&AtClient
Procedure UseFiltersOnChange(Item)
	
	UseFiltersWhenChangingOnServer();
	
	If ValueIsFilled(SearchStringProducts) Then
		SearchForProducts();
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsOfOriginalQualityOnChange(Item)
	
	SourceQualityProductsWhenChangedOnServer();
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not Copy And Not Var_Group Then
		
		Cancel = True;
		
		ParametersForCreatingForm = New Structure("Parent, ProductKind,  AddressOfParameterTable, AddressOfMappingTable");
		
		If UseFilters Then
			
			If NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKindsAndProperties")
				Or NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByProperties") Then
				
				If ValueIsFilled(ProductKind) Then
					
					TableAddressStructure = AddressOfSelectionTreeParameterTablesOnServer();
					
					ParametersForCreatingForm.AddressOfParameterTable = TableAddressStructure.AddressOfParameterTable;
					ParametersForCreatingForm.AddressOfMappingTable = TableAddressStructure.AddressOfMappingTable;
					
					ParametersForCreatingForm.ProductKind = ProductKind;
					
				EndIf;
			ElsIf NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKinds") Then
				If ValueIsFilled(ProductKind) Then
					ParametersForCreatingForm.ProductKind = ProductKind;
				EndIf;
			Else
				
				ParametersForCreatingForm.Parent = ?(Items.ProductsHierarchy.CurrentData = Undefined, PredefinedValue("Catalog.Products.EmptyRef"),
				Items.ProductsHierarchy.CurrentData.Ref);
				
			EndIf;
			
		EndIf;
		
		OpenForm("Catalog.Products.ObjectForm", New Structure("AdditionalParameters", ParametersForCreatingForm), ThisForm);
	
	ElsIf Var_Group Then
		
		CurrentData = Items.ProductsHierarchy.CurrentData;
		
		If CurrentData <> Undefined Then
			
			Cancel = True;
			
			ParametersForCreatingForm = New Structure("Parent", CurrentData.Ref);
			OpenForm("Catalog.Products.FolderForm", New Structure("AdditionalParameters", ParametersForCreatingForm), ThisForm);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	SelectGoodsClient.WhenActivatingLineInListOfProducts(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFilterTree

&AtClient
Procedure FilterTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectGoodsClient.FilterTreeSelection(ThisForm, New CallbackDescription("SelectionTreeWhenStateChanges", ThisObject));
	
EndProcedure

&AtClient
Procedure SelectionTreeWhenStateChanges(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf Result Then
		SelectGoodsClient.SelectionTreeWhenStateChanges(ThisForm);
		
		SelectionTreeSelectionWhenModifiedOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterTreeFilterOnChange(Item)
	
	SelectGoodsClient.FilterTreeFilterOnChange(ThisForm, New CallbackDescription("SelectionTreeWhenStateChanges", ThisObject));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersItemKinds

&AtClient
Procedure ItemKindsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	If TypeOf(DragParameters.Value) <> Type("CatalogRef.ItemKinds") Then
	 	StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure ItemKindsDrag(Item, DragParameters, StandardProcessing, String, Field)
	If TypeOf(DragParameters.Value) <> Type("CatalogRef.ItemKinds") Then
		StandardProcessing = False;
		TypesOfProductsDragAndDropOnServer(DragParameters.Value, StandardProcessing, String);
	EndIf;
EndProcedure

&AtServer
Procedure TypesOfProductsDragAndDropOnServer(ArrayOfProducts, StandardProcessing, ProductKind)
	
	UpdateList = False;
	
	If Common.ObjectAttributeValue(ProductKind, "IsFolder") Then
		StandardProcessing = False;
	Else
		For Each Products In ArrayOfProducts Do
			ItemProducts_ = Products.GetObject();	// CatalogObject.Products
			If ItemProducts_.ProductKind <> ProductKind Then
				ItemProducts_.ProductKind = ProductKind;
				ItemProducts_.Write();
				UpdateList = True;
			EndIf;
		EndDo;
	EndIf;
	
	If UpdateList Then
		ProductFormTable = Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(ThisForm)]; // FormTable
		ProductFormTable.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductsHierarchy

&AtClient
Procedure ProductsHierarchyOnActivateRow(Item)
	
	SelectGoodsClient.WhenProductHierarchyLineIsActivated(ThisForm);
	
EndProcedure

&AtClient
Procedure ProductHierarchyWhenActivatingWaitHandlerLine()
	
	SelectGoodsClient.HandlerForActivatingLineInProductHierarchy(ThisForm);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListQualities

&AtClient
Procedure QualityListTaggingOnChange(Item)
	
	QualityListFlaggedWhenChangedOnServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EditSelectedAdvancedSearch(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.ListAdvancedSearchProducts);
	
EndProcedure

&AtClient
Procedure ChangeTheSelectedStandardSearch(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.ListStandardSearchProducts);
	
EndProcedure

&AtClient
Procedure EditSelectedGroup(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.ProductsHierarchy);
	
EndProcedure

&AtClient
Procedure Search(Command)
	
	SearchForProducts();
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure ProductsWithSimilarProperties(Command)
	
	ClearMessages();
	
	If SelectGoodsClient.ThereAreSelectedLinesInListOfItems(ThisObject) Then
		ProductsWithSimilarPropertiesOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure AnotherQualityGoods(Command)
	
	If SelectGoodsClient.ThereAreSelectedLinesInListOfItems(ThisObject) Then
		ProductsOfDifferentQualityOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ResetFiltersByProperties(Command)
	
	ResetSelectionsByPropertiesOnServer();
	
EndProcedure

&AtClient
Procedure ConfigureSearch(Command)
	
	SelectGoodsClient.ConfigureSearch(ThisForm);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	CommandsList = ?(Items.PagesOfLists.CurrentPage = Items.PageAdvancedSearchProducts,
		Items.ListAdvancedSearchProducts,
		Items.ListStandardSearchProducts);
		
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, CommandsList);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtServer
Procedure FilterBySimilarProperties(FilterNomenclatureByProperties)
	SelectGoodsServer.FilterBySimilarProperties(ThisForm, FilterNomenclatureByProperties);
EndProcedure

&AtClient
Procedure MarkDuplicatesHighlightedAdvancedSearch(Command)
	SearchAndReplaceDuplicatesMasterDataClient.MarkSelectedOnesWithDuplicates(Items.ListAdvancedSearchProducts);
EndProcedure

&AtClient
Procedure MarkSelectedStandardSearchAsDuplicates(Command)
	SearchAndReplaceDuplicatesMasterDataClient.MarkSelectedOnesWithDuplicates(Items.ListStandardSearchProducts);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SearchStringProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsSearchReturnedNoResults");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FieldWithAnErrorBackground);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterTreeFilterPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterTree.FixedValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, True, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterTreePresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterTree.Filter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsHierarchy.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FilterTree.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemKinds.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListQualities.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseFilters");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FormBackColor);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductKind.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseFilters");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//

EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

// ExternalEquipmentMechanism
&AtClient
Procedure ProcessBarcodes(BarcodeData_1)
	
	ProcessingParameters = BarcodingOfItemsClient.BarcodeProcessingParameters();
	ProcessingParameters.Barcodes							= BarcodeData_1;
	ProcessingParameters.BlockFormData				= False;
	ProcessingParameters.ActionsWithUnknownBarcodes		= "OnlyRegister";
	ProcessingParameters.TransferSpecifiedGoodsToDocument	= False;
	
	Products = BarcodeProducts(ProcessingParameters, CachedValues);
	
	If Products <> Undefined Then
		ProductFormTable = Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(ThisObject)]; // FormTable
		ProductFormTable.CurrentRow = Products;
		
		ShowValue(, Products);
	Else
		BarcodingOfItemsClient.ProcessUnknownBarcodes(ProcessingParameters, CachedValues, ThisObject);
	EndIf;
	
EndProcedure
// End ExternalEquipmentMechanism

&AtServerNoContext
Function BarcodeProducts(ProcessingParameters, CachedValues)
	
	Return BarcodingOfItemsServer.BarcodeProducts(ProcessingParameters, CachedValues);
	
EndFunction

#EndRegion

#Region Search

&AtClient
Procedure SearchForProducts()
	
	SelectGoodsClient.PerformingAdvancedSearchIsPossible(ThisForm, 
		New CallbackDescription("SearchForProductsCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure SearchForProductsCompletion(Result, AdditionalParameters) Export 
	
	SearchForProductsOnServer();
	SelectGoodsClient.AfterSearchingForProducts(ThisForm);
	
EndProcedure

&AtServer
Procedure SearchForProductsOnServer()
	
	SelectGoodsServer.SearchForProducts(ThisForm);
	
EndProcedure

&AtServer
Procedure DeselectProductSearchBarOnServer()
	
	SelectGoodsClientServer.DeselectProductSearchBar(ThisForm);
	
EndProcedure

#EndRegion

#Region EventHandlersOnServer

&AtServer
Procedure UseFiltersWhenChangingOnServer()
	
	SelectGoodsServer.WhenChangingUseOfFilters(ThisForm);
	
EndProcedure

&AtServer
Procedure ProductTypeWhenChangedOnServer()
	
	SelectGoodsServer.WhenChangingTypeOfProductItem(ThisForm);
	
EndProcedure

&AtServer
Procedure ProductItemSegmentWhenChangedOnServer()
	
	SelectGoodsServer.WhenProductItemSegmentChanges(ThisForm);
	
EndProcedure

&AtServer
Procedure ProductsWithSimilarPropertiesOnServer()
	
	SelectGoodsServer.WhenChangingDisplayOfItemWithSimilarProperties(ThisForm);
	
EndProcedure

&AtServer
Procedure SelectionTreeSelectionWhenModifiedOnServer()
	
	SelectGoodsServer.FilterTreeFilterOnChange(ThisForm);
	
EndProcedure

&AtServer
Procedure SourceQualityProductsWhenChangedOnServer()
	
	SelectGoodsServer.ProductsOfOriginalQualityOnChange(ThisForm);
	
EndProcedure

&AtServer
Procedure QualityListFlaggedWhenChangedOnServer()
	
	SelectGoodsServer.QualityListTaggingOnChange(ThisForm);
	
EndProcedure

#EndRegion

#Region KeyboardShortcuts

&AtClient
Procedure SetTheCurrentSearchBarItem(Command)
	
	SelectGoodsClient.SetTheCurrentSearchBarItem(ThisForm);
	
EndProcedure

#EndRegion

#Region IdleHandlers

&AtClient
Procedure ListWhenWaitHandlerLineIsActivated()
	
	SelectGoodsClient.SetCurRowOfProductHierarchy(ThisForm);
	
EndProcedure

#EndRegion

#Region ManagingNavigationOption

&AtClient
Procedure ItemKindsOnActivateRow(Item)
	
	SelectGoodsClient.WhenActivatingProductTypesListLine(ThisForm);
	
EndProcedure

&AtClient
Procedure TypesOfProductsWhenActivatingWaitHandlerLine()
	
	CurrentData = Items.ItemKinds.CurrentData;
	
	If CurrentData <> Undefined Then
		
		ProductTypeWhenChangedOnServer();
		
		If ValueIsFilled(SearchStringProducts) Then
			SearchForProducts();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LabelNavigationOptionNavigationLink(Item, Var_URL, StandardProcessing)
	
	ProductTypeBeforeTransition = ProductKind;
	CaptionNavigationOptionNavigationLinksOnServer(Var_URL, StandardProcessing);
	
	If NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKindsAndProperties")
		Or NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKinds") Then
		Items.ItemKinds.CurrentRow = ProductTypeBeforeTransition;
	EndIf;
	
EndProcedure

&AtServer
Procedure CaptionNavigationOptionNavigationLinksOnServer(Var_URL, StandardProcessing)
	
	SelectGoodsServer.LabelNavigationOptionNavigationLink(ThisForm, Var_URL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ChangeNavigationOption(Command)
	SelectGoodsClient.ChangeNavigationOption(ThisObject);
EndProcedure

&AtClient
Procedure ChangeNavigationOptionCompletion(Result, AdditionalParameters) Export

	If Result = Undefined 
		Or NavigationOption = Result.Value Then
		Return;
	EndIf;
	
	NavigationOption = Result.Value;
	NavigationOptionWhenChangingOnServer();	
	
EndProcedure

&AtServer
Procedure NavigationOptionWhenChangingOnServer()
	
	SelectGoodsServer.WhenChangingNavigationOption(ThisForm);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function AddressOfSelectionTreeParameterTablesOnServer()
	
	Structure = New Structure("AddressOfParameterTable, AddressOfMappingTable");
	
	Structure.AddressOfParameterTable = SelectGoodsServer.AddressOfSelectionTreeParameterTable(ThisForm);
	Structure.AddressOfMappingTable = SelectGoodsServer.AddressOfSelectionTreeMappingTable(ThisForm);

	Return Structure;
	
EndFunction

&AtServer
Procedure SaveFormSettingsOnServer()
	
	SelectGoodsServer.SaveFormSettings(ThisForm);
	
EndProcedure

&AtServer
Procedure ProductsOfDifferentQualityOnServer()
	
	SelectGoodsServer.EstablishSelectionForProductsOfDifferentQuality(ThisForm);
	
EndProcedure

&AtServer
Procedure ResetSelectionsByPropertiesOnServer()
	
	SelectGoodsServer.ResetFiltersByProperties(ThisForm);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	PrintList_ = ?(Items.PagesOfLists.CurrentPage = Items.PageAdvancedSearchProducts,
		Items.ListAdvancedSearchProducts,
		Items.ListStandardSearchProducts);
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, PrintList_);
	
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	
	PrintList_ = ?(Items.PagesOfLists.CurrentPage = Items.PageAdvancedSearchProducts,
		Items.ListAdvancedSearchProducts,
		Items.ListStandardSearchProducts);	
	AttachableCommands.ExecuteCommand(ThisObject, Context, PrintList_, Result);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	PrintList_ = ?(Items.PagesOfLists.CurrentPage = Items.PageAdvancedSearchProducts,
		Items.ListAdvancedSearchProducts,
		Items.ListStandardSearchProducts);	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, PrintList_);
	
EndProcedure
// End StandardSubsystems.AttachableCommands


#EndRegion

#EndRegion

#Region Performance

&AtClient
Procedure ListStandardSearchProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Catalog.Products.ListForm.Item.ListStandardSearchProducts.Selection");
	
	
EndProcedure

&AtClient
Procedure ListAdvancedSearchProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Catalog.Products.ListForm.Item.ListAdvancedSearchProducts.Selection");
	
	
EndProcedure

#EndRegion
