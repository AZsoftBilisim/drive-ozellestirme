
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FormCode = "Catalog_Products_ChoiceForm";
	
	SelectGoodsServer.OnCreateAtServer(ThisForm);
	
	AdditionalParametersPassed = Undefined;
	If Parameters.Property("AdditionalParameters", AdditionalParametersPassed) And AdditionalParametersPassed <> Undefined Then
		CreationParameters = New FixedStructure(AdditionalParametersPassed);
	Else
		CreationParameters = New FixedStructure;
	EndIf;
		
	If Not Parameters.Property("RegisterBarcode",RegisterBarcode) Then
		RegisterBarcode = False;
	EndIf;
	
	If Parameters.Property("VATTaxation") Then
		Restrictions = VATAccountingERP.RestrictionOfGoodsOnTaxation(Parameters.VATTaxation);
		For Each Restriction In Restrictions Do
			CommonClientServer.SetDynamicListFilterItem(ListProducts,
																					Restriction.Attribute,
																					Restriction.Value,
																					Restriction.ComparisonType,
																					"FilterDefault",
																					True);
		EndDo;
	EndIf;
		
	If ValueIsFilled(Parameters.SetPriceCalculationOptions) Then
		CommonClientServer.SetDynamicListParameter(ListProducts, "SetPriceCalculationOptions", Parameters.SetPriceCalculationOptions, True);
	EndIf;
		
	// Let's remember the selected item of the nomenclature in the form that caused the opening of this selection form.
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
	
	Parameters.Property("ProductSegment", ProductSegment);
	If ValueIsFilled(ProductSegment) Then
		ProductItemSegmentWhenChangedOnServer();
	EndIf;
	
	If Parameters.ForbiddingTheEditingOfAnItemSegment Then
		Items.ProductSegment.ReadOnly = True;
	EndIf;
	
	SelectGoodsOfOtherQuality = Parameters.SelectGoodsOfOtherQuality;
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject,
		Items.CommandBarListAdvancedSearchProducts);
	// End IntegrationWith1CDocumentManagementSubsystem
	
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
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		SaveFormSettingsOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_Products" And ValueIsFilled(Source) Then
		If ValueIsFilled(SearchStringProducts) Then
			SearchForProducts();
		EndIf;
		ProductFormTable = Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(ThisForm)]; // FormTable
		ProductFormTable.CurrentRow = Source;
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

&AtClient
Procedure SearchStringProductsAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing)
	
	SelectionListsClientServer.AutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing);
	
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
Procedure ProductSegmentOnChange(Item)
	
	ProductItemSegmentWhenChangedOnServer();
	
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

#Region FormTableItemsEventHandlersListAdvancedSearchProducts

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not Copy And Not Var_Group Then
		
		Cancel = True;
		
		ParametersForCreatingForm = New Structure(CreationParameters);
		
		ParametersForCreatingForm.Insert("Parent");
		ParametersForCreatingForm.Insert("ProductKind");
		ParametersForCreatingForm.Insert("AddressOfParameterTable");
		ParametersForCreatingForm.Insert("AddressOfMappingTable");
		ParametersForCreatingForm.Insert("RegisterBarcode");
		
		ParametersForCreatingForm.RegisterBarcode             = RegisterBarcode;
		
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
	
EndProcedure

&AtClient
Procedure ListAdvancedSearchProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CheckDeleteMarkAndSelect(Item.CurrentData, RowSelected);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListStandardSearchProducts

&AtClient
Procedure ListStandardSearchProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CheckDeleteMarkAndSelect(Item.CurrentData, RowSelected);
	
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
Procedure Search(Command)
	
	CurMessageToUser = "";
	
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
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	SourceList = ?(Items.PagesOfLists.CurrentPage = Items.PageAdvancedSearchProducts,
		Items.ListAdvancedSearchProducts,
		Items.ListStandardSearchProducts);
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, SourceList);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

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
	ItemField.Field = New DataCompositionField(Items.FilterTree.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsHierarchy.Name);
	
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

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SearchStringProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectionSearchIsNotSuccessful");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FieldWithAnErrorBackground);

	//

EndProcedure

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

&AtClient
Procedure ConfigureSearch(Command)
	
	SelectGoodsClient.ConfigureSearch(ThisForm);
	
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
	CaptionNavigationOptionNavigationLinksOnServer(Var_URL, StandardProcessing);
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
Procedure SaveFormSettingsOnServer()
	
	SelectGoodsServer.SaveFormSettings(ThisForm);
	
EndProcedure

&AtServer
Function AddressOfSelectionTreeParameterTablesOnServer()
	
	Structure = New Structure("AddressOfParameterTable, AddressOfMappingTable");
	
	Structure.AddressOfParameterTable = SelectGoodsServer.AddressOfSelectionTreeParameterTable(ThisForm);
	Structure.AddressOfMappingTable = SelectGoodsServer.AddressOfSelectionTreeMappingTable(ThisForm);

	Return Structure;
	
EndFunction

&AtServer
Procedure ProductsOfDifferentQualityOnServer()
	
	SelectGoodsServer.EstablishSelectionForProductsOfDifferentQuality(ThisForm);
	
EndProcedure

&AtServer
Procedure ResetSelectionsByPropertiesOnServer()
	
	SelectGoodsServer.ResetFiltersByProperties(ThisForm);
	
EndProcedure

&AtClient
Procedure SelectProductsValue(Command)
	
	ProductsRow = Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(ThisForm)].CurrentData;
	
	If ProductsRow <> Undefined Then
		CheckDeleteMarkAndSelect(ProductsRow, ProductsRow.Ref);
	EndIf;
	
EndProcedure

// Checks the deletion mark for the item item.
//
// Parameters:
//	ProductsRow - FormDataStructure - data for the current line in the item list
//
&AtClient
Procedure CheckDeleteMarkAndSelect(ProductsRow, ProductsLink)
	
	If ProductsRow = Undefined Then
		Return;
	EndIf;
	
	If ProductsRow.DeletionMark Then
		ShowQueryBox(
		New CallbackDescription("CheckDeleteMarkAndSelectCompletion", ThisObject, 
				New Structure("ProductsLink", ProductsLink)), 
			NStr("vi = 'Dữ liệu được chọn đã bị đặt dấu xóa.
				|Chọn dữ liệu này?';
				|ru = 'Выбранные данные помечены на удаление.
				|Выполнить выбор этих данных?';
				|en = 'Selected data is marked for deletion.
				|Select this data?'; fa = 'Selected data is marked for deletion.
				|Select this data?';
				|it = 'Selezionati dei dati contrassegnati per la cancellazione.
				|Effettuare la scelta dei dati?';
				|pl = 'Wybrane dane są zaznaczone do usunięcia.
				|Wybrać te dane?';
				|tr = 'Seçilen veriler silinmek üzere işaretlenir.
				|Bu verilerin seçimini gerçekleştir?'") , 
			QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	NotifyChoice(ProductsLink);
	
EndProcedure

&AtClient
Procedure CheckDeleteMarkAndSelectCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ProductsLink = AdditionalParameters.ProductsLink;
	
	NotifyChoice(ProductsLink);

EndProcedure

#EndRegion

#EndRegion
