#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Document = Undefined Then
		Raise NStr("vi = 'Chỉ có thể mở bộ xử lý từ chứng từ';
					|ru = 'Предусмотрено открытие обработки только из документов.';
					|en = 'Data processor can be opened only from documents.'; fa = 'Data processor can be opened only from documents.';
					|it = 'Viene fornita l''apertura dell''elaborazione solo dalle forme dei documenti';
					|pl = 'Przewidziano otwarcie przetwarzania tylko z dokumentów.';
					|tr = 'Yalnızca belgelerden işlem açmak için provizyon sağlanmıştır.'");
	EndIf;
	
	FormCode = "Processing_SelectionByProductCategory_Form";
	GoodsSearchOption = "Advanced";
	
	PlanningObject = Parameters.PlanningObject;
	Stage = Parameters.Stage;
	Phase = Parameters.Phase;
	ItemsCollection = Parameters.ItemsCollection;
	ValidityStartDate = Parameters.ValidityStartDate;
	
	If GetFunctionalOption("UseCollectionManagement") Then
		CommonClientServer.SetDynamicListFilterItem(ListProducts, "Ref.ItemsCollection", ItemsCollection, DataCompositionComparisonType.Equal,,True);
	EndIf; 
	
	SavedSettings = Common.CommonSettingsStorageLoad("ProductSelectionByCategoryFormSettings", "");
	If SavedSettings = Undefined Then
		ShowSelectedGoods = True;
	Else
		If SavedSettings.Property("ShowSelectedGoods") Then
			ShowSelectedGoods = SavedSettings.ShowSelectedGoods;
		EndIf;
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(ListProducts, "OnDate", ValidityStartDate, True);
	CommonClientServer.SetDynamicListParameter(ListProducts, "PlanningObject", PlanningObject, True);
	PriceKind = Common.ObjectAttributeValue(PlanningObject, "RetailPriceType");
	CommonClientServer.SetDynamicListParameter(ListProducts, "PriceKind", PriceKind, True);
	
	If Parameters.FormATreeWhenOpened Then
		CreateCategoryTreeServer();
	EndIf;
	
	If Parameters.Property("GoodsAddressInStorage") Then
		TemporaryTableOfGoods_ = GetFromTempStorage(Parameters.GoodsAddressInStorage);
		Object.SelectedGoodsTable.Load(TemporaryTableOfGoods_);
		
		SetSelectionOfListOfProductsForSelectedProduct(ThisForm);
		
		For Each RowData In Object.SelectedGoodsTable Do
			UpdateContentBasedOnSelectionInTree(RowData.ProductRangePhase, RowData.ProductCategory, RowData.Brand, 1);
		EndDo; 
	EndIf; 
	
	ThisForm.Title = NStr("vi = 'Chọn theo thể loại';
							|ru = 'Подбор по категориям';
							|en = 'Pick by categories'; fa = 'برداشت بر اساس دسته‌ها';
							|it = 'Selezione per categorie';
							|pl = 'Wybór wg kategorii';
							|tr = 'Kategorilere göre seçim'");
	Items.FormMoveToDocument.Visible = True;
	Items.FormMoveToDocument.DefaultButton = True;
	
	Items.AreaSelectedGoods.Visible = ShowSelectedGoods;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateInformationLabelOfQuantityOfGoods();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If Not ClosingInProgress And Not MoveToDocument And Modified Then
		
		QueryText = NStr("vi = 'Đã thay đổi thành phần hàng hóa.
								|Chuyển vị trí đã chọn vào chứng từ?';
								|ru = 'Состав выбранных товаров был изменен.
								|Перенести выбранные позиции в документ?';
								|en = 'Content of the selected goods was changed.
								|Transfer the selected items to the document?'; fa = 'Content of the selected goods was changed.
								|Transfer the selected items to the document?';
								|it = 'La composizione degli elementi selezionati è stata cambiata.
								|Spostare gli oggetti selezionati per documentare??';
								|pl = 'Skład wybranych towarów został zmieniony.
								|Przenieść wybrane pozycje do dokumentu?';
								|tr = 'Seçilen ürünlerin içeriği değiştirildi.
								|Seçilen ürünleri belgeye transfer et?'");
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), QueryText,QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Yes Then
		MoveToDocument = True;
		ClosingInProgress = True;
		Close();
	ElsIf Response = DialogReturnCode.No Then
		ClosingInProgress = True;
		Close();
	EndIf;

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	ClosingParameters = New Structure;
	ClosingParameters.Insert("ShowSelectedGoods", ShowSelectedGoods);
	CommonSettingsStorageSave(ClosingParameters);
	
	If MoveToDocument Then
		AddressStructure = PutProductsInStorage();
		NotifyChoice(AddressStructure);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SearchStringOnChange(Item)
	
	ExecuteSearch();
	
EndProcedure

&AtClient
Procedure SearchStringClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	SearchStringProducts = "";
	
	DeselectProductSearchBarOnServer();
	
EndProcedure

&AtClient
Procedure SearchStringAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing)
	
	SelectionListsClientServer.AutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing);
	
EndProcedure

&AtClient
Procedure HelpTextClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ShowSelectedGoods = Not ShowSelectedGoods;
	Items.AreaSelectedGoods.Visible = ShowSelectedGoods;
	UpdateInformationLabelOfQuantityOfGoods();
	
EndProcedure

&AtClient
Procedure FindByExactMatchWhenChanging(Item)
	
	ExecuteSearch();
	
EndProcedure

&AtClient
Procedure CategoriesOnChange(Item)
	
	If Categories = 1 
		And Items.CategoryTree.CurrentRow <> Undefined
		And Not CategoryTree.FindByID(Items.CategoryTree.CurrentRow).QuotaIsNotFilledIn Then
		
		Items.CategoryTree.CurrentRow = Undefined;
		For Each TreeRow In CategoryTree.GetItems() Do
		
			If TreeRow.QuotaIsNotFilledIn Then
			
				Items.CategoryTree.CurrentRow = TreeRow.GetID();
				Break;
			
			EndIf; 
		
		EndDo; 
		
	
	ElsIf Categories = 2
		And Items.CategoryTree.CurrentRow <> Undefined
		And Not CategoryTree.FindByID(Items.CategoryTree.CurrentRow).QuotaIsFull Then
		
		Items.CategoryTree.CurrentRow = Undefined;
		For Each TreeRow In CategoryTree.GetItems() Do
		
			If TreeRow.QuotaIsFull Then
			
				Items.CategoryTree.CurrentRow = TreeRow.GetID();
				Break;
			
			EndIf; 
		
		EndDo;
	
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListAdvancedSearchProducts

&AtClient
Procedure ListAdvancedSearchProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TableRow = Item.CurrentData;
	
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	If TableRow.IsFolder Then
		Return;
	EndIf;
	
	ListOfSelectedProducts = New Array;
	ListOfSelectedProducts.Add(ProductData_8(TableRow));
	CheckAndAddProductsToCart(ListOfSelectedProducts);
	
EndProcedure

&AtClient
Procedure ListAdvancedSearchProductsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListAdvancedSearchProductsDragStart(Item, DragParameters, Perform)
	
	DragParameters.AllowedActions = DragAllowedActions.Move;
	
	GetDragAndDropData(DragParameters);   
	
EndProcedure

&AtClient
Procedure ListAdvancedSearchProductsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If TypeOf(DragParameters.Value) = Type("Structure") 
		And DragParameters.Value.Property("ArrayOfRowKeysForSelectedProducts") Then
		
		DeleteSelectedProductsByKeyOnServer(DragParameters.Value.ArrayOfRowKeysForSelectedProducts);
		
		AfterDeletingRowsFromTableOfSelectedProducts();
		
		Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCategoryTree

&AtClient
Procedure CategoryTreeOnActivateRow(Item)
	
	AttachIdleHandler("SetSelectionOnCurRowOfWaitHandlerTree", 0.2, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedGoodsTable

&AtClient
Procedure SelectedGoodsTableBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure SelectedGoodsTableBeforeDeleteRow(Item, Cancel)
	
	// Let's remember the data of the deleted rows, because after deleting, you need to update the data on the form.
	For Each RowID In Items.SelectedGoodsTable.SelectedRows Do
		RowData = Object.SelectedGoodsTable.FindByID(RowID);
		FillPropertyValues(DeletedRowsFromTheSelectedGoodsTable.Add(), RowData);
	EndDo; 
	
EndProcedure

&AtClient
Procedure SelectedGoodsTableAfterDeleteRow(Item)
	
	AfterDeletingRowsFromTableOfSelectedProducts();
	
EndProcedure

&AtClient
Procedure SelectedGoodsTableDragStart(Item, DragParameters, Perform)
	
	DragParameters.AllowedActions = DragAllowedActions.Move;
	
	ArrayOfStringKeys = New Array; 
	
	For Each RowKey In DragParameters.Value Do
		ArrayOfStringKeys.Add(RowKey);
	EndDo;
	
	DragParameters.Value = New Structure("ArrayOfRowKeysForSelectedProducts", ArrayOfStringKeys);
	
EndProcedure

&AtClient
Procedure SelectedGoodsTableDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	DontProcess = True;
	If TypeOf(DragParameters.Value) = Type("Structure") 
		Or TypeOf(DragParameters.Value) = Type("Array")
			And DragParameters.Value.Count() <> 0
			And TypeOf(DragParameters.Value[0]) = Type("Structure") Then
		DontProcess = False;
	EndIf;
	
	If DontProcess Then
		DragParameters.AllowedActions = DragAllowedActions.DontProcess;
	EndIf; 
	
EndProcedure

&AtClient
Procedure SelectedGoodsTableDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	CheckAndAddProductsToCart(DragParameters.Value);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	MoveToDocument = True;
	Close();
EndProcedure

&AtClient
Procedure Search(Command)
	
	ExecuteSearch();
	
EndProcedure

&AtClient
Procedure OpenGoodsProfile(Command)
	
	CurrentRow = Items.ListAdvancedSearchProducts.CurrentData;
	If CurrentRow = Undefined Then
		Return;
	EndIf; 
	
	ShowValue(Undefined, CurrentRow.Ref);
	
EndProcedure

&AtClient
Procedure ChangeTheItem(Command)
	
	SelectGoodsClient.OpenGoodsProfile(ThisForm);
	
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
	ItemFilter.LeftValue = New DataCompositionField("SelectionSearchIsNotSuccessful");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.ErrorFullTextSearchBackground);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CategoryTreePresentation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CategoryTreeTotalProducts.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CategoryTreeContentContent.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CategoryTreeFillingConsideringSelection.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CategoryTreeQuota.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Categories");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CategoryTree.QuotaIsNotFilledIn");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CategoryTreePresentation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CategoryTreeTotalProducts.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CategoryTreeContentContent.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CategoryTreeFillingConsideringSelection.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CategoryTreeQuota.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Categories");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CategoryTree.QuotaIsFull");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableOfProductsBrand.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListProducts.Brand");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Nhãn hiệu khác';
													|ru = 'Прочие марки';
													|en = 'Other brands'; fa = 'Other brands';
													|it = 'Altri marchi';
													|pl = 'Inne marki';
													|tr = 'Diğer markalar'"));
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsTableBrand.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SelectedGoodsTable.Brand");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Nhãn hiệu khác';
													|ru = 'Прочие марки';
													|en = 'Other brands'; fa = 'Other brands';
													|it = 'Altri marchi';
													|pl = 'Inne marki';
													|tr = 'Diğer markalar'"));
	
EndProcedure

&AtClient
Procedure TableOfSelectedProductsWhenChanging()
	
	UpdateInformationLabelOfQuantityOfGoods();
	
EndProcedure

&AtClient
Procedure SetSelectionOnCurRowOfWaitHandlerTree()
	
	CurrentTreeRow = Items.CategoryTree.CurrentData;
	
	CommonClientServer.SetDynamicListFilterItem(ListProducts, "FilterProductKind",,,,False);
	CommonClientServer.SetDynamicListFilterItem(ListProducts, "FilterProductCategory",,,,False);
	CommonClientServer.SetDynamicListFilterItem(ListProducts, "FilterBrand",,,,False);
	
	If CurrentTreeRow<>Undefined Then
		If TypeOf(CurrentTreeRow.TypeCategoryBrand) = Type("CatalogRef.ItemKinds") Then
			If CurrentTreeRow.ThisIsKindGroup Then
				CommonClientServer.SetDynamicListFilterItem(
					ListProducts,
					"FilterProductKind",
					CurrentTreeRow.TypeCategoryBrand,
					DataCompositionComparisonType.InHierarchy,,
					True);
			Else
				AdditionalSpeciesFound = AdditionalKinds.Get(CurrentTreeRow.TypeCategoryBrand); // FixedArray of FixedStructure
				
				If AdditionalSpeciesFound = Undefined Then 
					CommonClientServer.SetDynamicListFilterItem(
						ListProducts,
						"FilterProductKind",
						CurrentTreeRow.TypeCategoryBrand,
						DataCompositionComparisonType.Equal,,
						True);
				Else
					
					ListOfSpecies = New ValueList;
					ListOfSpecies.Add(CurrentTreeRow.TypeCategoryBrand);
					
					For Each AdditionalView In AdditionalSpeciesFound Do
						ListOfSpecies.Add(AdditionalView.ItemTypeReference);
					EndDo;
					
					CommonClientServer.SetDynamicListFilterItem(
						ListProducts,
						"FilterProductKind",
						ListOfSpecies,
						DataCompositionComparisonType.InList,,
						True);
				EndIf;
				
			EndIf;
		ElsIf TypeOf(CurrentTreeRow.TypeCategoryBrand) = Type("CatalogRef.ProductCategories") Then
			If CurrentTreeRow.ThisIsCategoryGroup Then
				CommonClientServer.SetDynamicListFilterItem(
					ListProducts,
					"FilterProductCategory",
					CurrentTreeRow.TypeCategoryBrand,
					DataCompositionComparisonType.InHierarchy,,
					True);
			Else
				CommonClientServer.SetDynamicListFilterItem(
					ListProducts,
					"FilterProductCategory",
					CurrentTreeRow.TypeCategoryBrand,
					DataCompositionComparisonType.Equal,,
					True);
			EndIf;
		ElsIf TypeOf(CurrentTreeRow.TypeCategoryBrand) = Type("CatalogRef.Brands")
			Or TypeOf(CurrentTreeRow.TypeCategoryBrand) = Type("String") Then
			ParentOfTreeRow = CurrentTreeRow.GetParent();
			If ParentOfTreeRow<>Undefined Then
				CommonClientServer.SetDynamicListFilterItem(
					ListProducts,
					"FilterProductCategory",
					ParentOfTreeRow.TypeCategoryBrand,
					DataCompositionComparisonType.Equal,,
					True);
			EndIf;
			CommonClientServer.SetDynamicListFilterItem(
				ListProducts,
				"FilterBrand",
				CurrentTreeRow.TypeCategoryBrand,
				DataCompositionComparisonType.Equal,,
				True);
		EndIf;
	EndIf;
	
	If ValueIsFilled(SearchStringProducts) Then
		ExecuteSearch();
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateCategoryTreeServer()
	
	Query = New Query;
	Query.Text  = 
	"SELECT
	|	Quotas.ProductCategory AS ProductCategory,
	|	Quotas.Brand AS Brand,
	|	Quotas.Quota AS Quota,
	|	Quotas.VariancePercentage AS VariancePercentage
	|INTO TTCategoryPlan
	|FROM
	|	InformationRegister.ProductMixQuotas.SliceLast(
	|			&OnDate,
	|			PlanningObject = &PlanningObject
	|				AND Period IN
	|					(SELECT
	|						MAX(K.Period)
	|					FROM
	|						InformationRegister.ProductMixQuotas AS K
	|					WHERE
	|						K.Period <=  &OnDate
	|						AND K.PlanningObject = &PlanningObject
	|						AND &FilterCollections2)
	|				AND &FilterCollections1) AS Quotas
	|
	|INDEX BY
	|	ProductCategory,
	|	Brand
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CatalogProducts.Ref AS Ref,
	|	CatalogProducts.ProductCategory AS ProductCategory,
	|	CatalogProducts.ProductKind AS ProductKind,
	|	ISNULL(CategoryPlan.Brand, VALUE(Catalog.Brands.EmptyRef)) AS Brand,
	|	ISNULL(CategoryPlan.Quota, 0) AS Quota,
	|	ProductRange.Products AS FillingProducts_,
	|	ISNULL(ProductRange.ProductRangeRole, VALUE(Enum.ProductRangeRoles.EmptyRef)) AS ProductRangeRole,
	|	ISNULL(ProductRange.PurchasesAreAllowed, FALSE) AS PurchasesAreAllowed,
	|	ISNULL(ProductRange.SalesAreAllowed, FALSE) AS SalesAreAllowed,
	|	ProductRange.PriceKind AS PriceKind
	|INTO TTCurRange
	|FROM
	|	Catalog.Products AS CatalogProducts
	|		LEFT JOIN InformationRegister.ProductRange.SliceLast(ENDOFPERIOD(&OnDate, DAY), PlanningObject = &PlanningObject) AS ProductRange
	|		ON (ProductRange.Products = CatalogProducts.Ref)
	|		LEFT JOIN TTCategoryPlan AS CategoryPlan
	|		ON CatalogProducts.ProductCategory = CategoryPlan.ProductCategory
	|			AND CatalogProducts.Brand = CategoryPlan.Brand
	|WHERE
	|	NOT CatalogProducts.IsFolder
	|	AND &FilterCollections3
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurRange.ProductKind,
	|	CurRange.ProductCategory,
	|	CurRange.Brand,
	|	COUNT(DISTINCT CurRange.Ref) AS TotalProductsInCategory,
	|	COUNT(DISTINCT CurRange.FillingProducts_) AS CategoryContent
	|INTO TTTotalsByCategory
	|FROM
	|	TTCurRange AS CurRange
	|
	|GROUP BY
	|	CurRange.ProductKind,
	|	CurRange.ProductCategory,
	|	CurRange.Brand
	|
	|INDEX BY
	|	CurRange.ProductKind,
	|	CurRange.ProductCategory,
	|	CurRange.Brand
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CatalogCategories.Owner AS ProductKind,
	|	CatalogCategories.Ref AS ProductCategory,
	|	ISNULL(CategoryPlan.Brand, VALUE(Catalog.Brands.EmptyRef)) AS Brand,
	|	ISNULL(CategoryPlan.Brand.Description, &TextOtherBrands) AS BrandName,
	|	ISNULL(CategoryPlan.Quota, 0) AS Quota,
	|	ISNULL(CategoryPlan.VariancePercentage, 0) AS VariancePercentage
	|INTO TTCategories
	|FROM
	|	Catalog.ProductCategories AS CatalogCategories
	|		LEFT JOIN TTCategoryPlan AS CategoryPlan
	|		ON CatalogCategories.Ref = CategoryPlan.ProductCategory
	|WHERE
	|	NOT CatalogCategories.IsFolder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProductCategories.ProductKind AS ProductKind,
	|	ItemKinds.Description AS NameOfAdditionalTypeOfProduct,
	|	ItemKinds.Ref AS AdditionalTypeOfProducts
	|FROM
	|	TTCategories AS ProductCategories
	|		INNER JOIN Catalog.ItemKinds AS ItemKinds
	|		ON ProductCategories.ProductKind = ItemKinds.ProductCategoryOwner
	|ORDER BY
	|	ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTCategories.ProductKind AS ProductKind,
	|	TTCategories.ProductKind.Description AS NameOfTypeOfProduct,
	|	TTCategories.ProductKind.IsFolder AS ThisIsKindGroup,
	|	TTCategories.ProductCategory AS ProductCategory,
	|	TTCategories.ProductCategory.Description AS CategoryName,
	|	TTCategories.ProductCategory.IsFolder AS ThisIsCategoryGroup,
	|	TTCategories.Brand AS Brand,
	|	TTCategories.BrandName AS BrandName,
	|	TTCategories.Quota AS Quota,
	|	TTCategories.VariancePercentage AS VariancePercentage,
	|	TotalsByCategory.TotalProductsInCategory AS TotalProducts,
	|	TotalsByCategory.CategoryContent AS ContentContent
	|FROM
	|	TTCategories AS TTCategories
	|		LEFT JOIN TTTotalsByCategory AS TotalsByCategory
	|		ON TTCategories.ProductKind = TotalsByCategory.ProductKind
	|			AND TTCategories.ProductCategory = TotalsByCategory.ProductCategory
	|			AND TTCategories.Brand = TotalsByCategory.Brand
	|
	|ORDER BY
	|	NameOfTypeOfProduct,
	|	CategoryName,
	|	BrandName
	|TOTALS
	|	MAX(BrandName),
	|	SUM(Quota),
	|	0 AS VariancePercentage,
	|	SUM(TotalProducts),
	|	SUM(ContentContent)
	|BY
	|	ProductKind HIERARCHY,
	|	ProductCategory HIERARCHY";
	
	Query.SetParameter("PlanningObject", PlanningObject);
	Query.SetParameter("OnDate", ValidityStartDate);
	Query.SetParameter("TextOtherBrands", NStr("vi = 'Nhãn hiệu khác';
												|ru = 'Прочие марки';
												|en = 'Other brands'; fa = 'Other brands';
												|it = 'Altri marchi';
												|pl = 'Inne marki';
												|tr = 'Diğer markalar'"));
	
	FilterCollections1 = "TRUE";
	FilterCollections2 = "TRUE";
	FilterCollections3 = "TRUE";
	If GetFunctionalOption("UseCollectionManagement") Then
	
		FilterCollections1 = " ItemsCollection = &ItemsCollection";
		FilterCollections2 = " K.ItemsCollection = &ItemsCollection";
		FilterCollections3 = " CatalogProducts.ItemsCollection = &ItemsCollection";
		Query.SetParameter("ItemsCollection", ItemsCollection);
	
	EndIf; 
	Query.Text = StrReplace(Query.Text, "&FilterCollections1", FilterCollections1);
	Query.Text = StrReplace(Query.Text, "&FilterCollections2", FilterCollections2);
	Query.Text = StrReplace(Query.Text, "&FilterCollections3", FilterCollections3);
	
	QueryResult = Query.ExecuteBatch();
	SelectionByAdditionalTypesQueryResult = QueryResult[QueryResult.Count() - 2]; // QueryResult - 
	SamplingByAdditionalSpecies = SelectionByAdditionalTypesQueryResult.Select();
	
	If SamplingByAdditionalSpecies.Next() Then
		AdditionalTypesOfCompliance = New Map;
		
		CurrentKind = SamplingByAdditionalSpecies.ProductKind; 
		ArrayOfAdditionalViews = New Array;
		
		SamplingByAdditionalSpecies.Reset();
		While SamplingByAdditionalSpecies.Next() Do
			
			If SamplingByAdditionalSpecies.ProductKind <> CurrentKind Then
				
				AdditionalTypesOfCompliance.Insert(CurrentKind, New FixedArray(ArrayOfAdditionalViews));
				ArrayOfAdditionalViews = New Array;
				
			EndIf;
			
			DescriptionOfAppearance = New Structure;
			DescriptionOfAppearance.Insert("ItemTypeReference",SamplingByAdditionalSpecies.AdditionalTypeOfProducts); 
			DescriptionOfAppearance.Insert("NameOfTypeOfProduct",SamplingByAdditionalSpecies.NameOfAdditionalTypeOfProduct); 
			
			ArrayOfAdditionalViews.Add(New FixedStructure(DescriptionOfAppearance));
			
		EndDo;	
		AdditionalTypesOfCompliance.Insert(CurrentKind, New FixedArray(ArrayOfAdditionalViews));
		
		AdditionalKinds = New FixedMap(AdditionalTypesOfCompliance);
	Else
		AdditionalKinds = New FixedMap(New Map);
	EndIf;
		
	FillInTreeBasedOnQueryResult(QueryResult[QueryResult.Count() - 1]);
	
EndProcedure

&AtServer
Procedure FillInTreeBasedOnQueryResult(QueryResult)
	
	TreeObject = FormAttributeToValue("CategoryTree",Type("ValueTree"));
	TreeObject.Rows.Clear();
	
	TreeResult = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	FillInSubordinateRows(TreeObject, TreeResult);
	
	ValueToFormAttribute(TreeObject,"CategoryTree");
	Items.CategoryTree.InitialTreeView = InitialTreeView.ExpandTopLevel;
	
EndProcedure

&AtServer
Procedure FillInSubordinateRows(DestinationParent, SourceParent)
	
	For Each SourceRow1 In SourceParent.Rows Do
		DestinationRow1 = DestinationParent.Rows.Add();
		FillPropertyValues(DestinationRow1,SourceRow1);
		DestinationRow1.FillingConsideringSelection = SourceRow1.ContentContent;
		
		If SourceRow1.Brand <> Null Then
			If ValueIsFilled(SourceRow1.Brand) Then
				DestinationRow1.TypeCategoryBrand = SourceRow1.Brand;
				DestinationRow1.Presentation = SourceRow1.BrandName;
			Else
				DestinationRow1.TypeCategoryBrand = Catalogs.Brands.EmptyRef();
				DestinationRow1.Presentation = SourceRow1.BrandName;
			EndIf;
			DestinationRow1.ThisIsTotal = False;
			DestinationRow1.PictureIndex = 2;
		ElsIf SourceRow1.ProductCategory <> Null Then
			DestinationRow1.TypeCategoryBrand = SourceRow1.ProductCategory;
			DestinationRow1.Presentation = SourceRow1.CategoryName;
			DestinationRow1.ThisIsTotal = True;
			If SourceRow1.ThisIsCategoryGroup Then
				DestinationRow1.PictureIndex = 0;
			Else
				DestinationRow1.PictureIndex = 1;
			EndIf;
		Else
			DestinationRow1.TypeCategoryBrand = SourceRow1.ProductKind;
			TextOfAdditionalViews = "";
			TypeText = NStr("vi = '%MainView%';
							|ru = '%MainView%';
							|en = '%MainView%'; fa = '%MainView%';
							|it = '%MainView%';
							|pl = '%MainView%';
							|tr = '%MainView%'");
			
			If Not SourceRow1.ThisIsKindGroup Then 
				
				AdditionalTypesOfVariable = AdditionalKinds; // FixedMap
				
				AdditionalSpeciesFound = AdditionalTypesOfVariable.Get(SourceRow1.ProductKind); // FixedArray of FixedStructure
				
				If AdditionalSpeciesFound <> Undefined Then
					TypeText = NStr("vi = '%MainView% (cũng như %AdditionalKinds%)';
									|ru = '%MainView% (а так же %AdditionalKinds%)';
									|en = '%MainView% (as well as %AdditionalKinds%)'; fa = '%MainView% (as well as %AdditionalKinds%)';
									|it = '%MainView% (e anche %AdditionalKinds%)';
									|pl = '%MainView% (a tаk że %AdditionalKinds%)';
									|tr = '%MainView% (aynı zamanda %AdditionalKinds%)'");
					
					For Each AdditionalView In AdditionalSpeciesFound Do
						TextOfAdditionalViews = TextOfAdditionalViews + AdditionalView.NameOfTypeOfProduct + ", ";	
					EndDo;
					
					TextOfAdditionalViews = Left(TextOfAdditionalViews, StrLen(TextOfAdditionalViews) - 2);
				EndIf;
				
			EndIf;
			
			DestinationRow1.Presentation = TypeText;
			DestinationRow1.Presentation = StrReplace(DestinationRow1.Presentation, "%MainView%", SourceRow1.NameOfTypeOfProduct);
			DestinationRow1.Presentation = StrReplace(DestinationRow1.Presentation, "%AdditionalKinds%", TextOfAdditionalViews);
			
			DestinationRow1.ThisIsTotal = True;
			DestinationRow1.PictureIndex = 0;
		EndIf;
		
		DestinationRow1.QuotaIsNotFilledIn = DestinationRow1.FillingConsideringSelection < DestinationRow1.Quota;
		DestinationRow1.QuotaIsFull = DestinationRow1.FillingConsideringSelection > DestinationRow1.Quota;
		
		// And recursively subordinate
		FillInSubordinateRows(DestinationRow1,SourceRow1);
		
		If TypeOf(DestinationParent) = Type("ValueTreeRow") Then
		
			DestinationParent.QuotaIsNotFilledIn = DestinationParent.QuotaIsNotFilledIn Or DestinationRow1.QuotaIsNotFilledIn;
			DestinationParent.QuotaIsFull = DestinationParent.QuotaIsFull Or DestinationRow1.QuotaIsFull;
		
		EndIf; 
		
	EndDo;

EndProcedure

&AtServer
Function PutProductsInStorage()
	
	TemporaryTableOfGoods_ = Object.SelectedGoodsTable.Unload();
	
	GoodsAddressInStorage = PutToTempStorage(TemporaryTableOfGoods_, UUID);
	AddressStructure = New Structure;
	AddressStructure.Insert("GoodsAddressInStorage", GoodsAddressInStorage);
	
	Return AddressStructure;
	
EndFunction

&AtClient
Procedure UpdateInformationLabelOfQuantityOfGoods()
	
	ItemsInWords = Lower(NumberInWords(Object.SelectedGoodsTable.Count(), "FS = False; SN = True; FN = False;", NStr("vi = 'mặt hàng,mặt hàng, mặt hàng,f,,,,,0';
																													|ru = 'позиция,позиции,позиций,ж,,,,,0';
																													|en = 'position,positions,,,0'; fa = 'position,positions,,,0';
																													|it = 'posizione,di posizione,di posizioni,zh,,,,,0';
																													|pl = 'pozycja,pozycji,pozycji,ж,,,,,0';
																													|tr = 'konum,konumlar,konumların,,,,,,0'")));
	HelpText = NStr("vi = 'Tất cả đã chọn %1 (%2)';
					|ru = 'Всего подобрано %1 (%2)';
					|en = 'Total items picked %1 (%2)'; fa = 'Total items picked %1 (%2)';
					|it = 'Всего подобрано %1 (%2)';
					|pl = 'Total items picked %1 (%2)';
					|tr = 'Toplam seçilen %1 (%2)'");
	StringFunctionsClientServer.SubstituteParametersToString(HelpText, ItemsInWords, ?(ShowSelectedGoods, "Hide", "Show"));
	
EndProcedure

&AtServer
Procedure UpdateContentBasedOnSelectionInTree(ProductRangePhase, ProductCategory, Brand, Count)
	
	ShouldUpdate = False;
	
	If (ProductRangePhase <> Enums.ProductRangePhases.PurchasesAndSalesArePermitted 
		And ProductRangePhase <> Enums.ProductRangePhases.OnlyPurchasesAreAllowed)
		And (Stage <> Enums.ProductRangeChangeSteps.RemoveFromProductRange
			And Stage <> Enums.ProductRangeChangeSteps.TransferToArchiveRevoke) Then
		// If the product was banned from purchase - i.e. it was not in the assortment,
		// and the stage of not withdrawing from the assortment
		// , then as a result, the fullness will change in a big way.
		ShouldUpdate = True;
	ElsIf (ProductRangePhase = Enums.ProductRangePhases.PurchasesAndSalesArePermitted 
		Or ProductRangePhase = Enums.ProductRangePhases.OnlyPurchasesAreAllowed)
		And (Stage = Enums.ProductRangeChangeSteps.RemoveFromProductRange
			Or Stage = Enums.ProductRangeChangeSteps.TransferToArchiveRevoke) Then
		// If the product was allowed to be purchased - i.e. it was present in the assortment,
		// and the stage of withdrawal from the assortment
		// , then as a result, the fullness will change to a smaller side => change the sign.
		ShouldUpdate = True;
		Count = - Count;
	EndIf;
	
	If Not ShouldUpdate Then
		Return;
	EndIf;
	
	TreeRow = FindRowInCollectionTree(CategoryTree, ProductCategory);
	If TreeRow <> Undefined Then
		TreeRow.FillingConsideringSelection = TreeRow.FillingConsideringSelection + Count;
		TreeRow.QuotaIsNotFilledIn = TreeRow.FillingConsideringSelection < TreeRow.Quota;
		TreeRow.QuotaIsFull = TreeRow.FillingConsideringSelection > TreeRow.Quota;
		StringTreeString_ = TreeRow.GetItems();
		For Each SubordinateRow In StringTreeString_  Do
			If SubordinateRow.TypeCategoryBrand = Brand
				Or (SubordinateRow.TypeCategoryBrand = NStr("vi = 'Nhãn hiệu khác';
															|ru = 'Прочие марки';
															|en = 'Other brands'; fa = 'Other brands';
															|it = 'Altri marchi';
															|pl = 'Inne marki';
															|tr = 'Diğer markalar'") And Not ValueIsFilled(Brand)) Then
				
				SubordinateRow.FillingConsideringSelection = SubordinateRow.FillingConsideringSelection + Count;
				SubordinateRow.QuotaIsNotFilledIn = SubordinateRow.FillingConsideringSelection < SubordinateRow.Quota;
				SubordinateRow.QuotaIsFull = SubordinateRow.FillingConsideringSelection > SubordinateRow.Quota;
				
				If SubordinateRow.QuotaIsNotFilledIn Then
					TreeRow.QuotaIsNotFilledIn = True;
				EndIf;
				
				If SubordinateRow.QuotaIsFull Then
					TreeRow.QuotaIsFull = True;
				EndIf;
				
				Break;
				
			EndIf;
		EndDo;
		UpdateContentBasedOnLineParentSelection(TreeRow, Count);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateContentBasedOnLineParentSelection(TreeRow, Count)
	
	CurRowParent = TreeRow.GetParent();
	
	If CurRowParent <> Undefined Then
		CurRowParent.FillingConsideringSelection = CurRowParent.FillingConsideringSelection + Count;
		QuotaIsNotFilledIn = False;
		QuotaIsFull = False;
		TreeRows = CurRowParent.GetItems();
		For Each String In TreeRows Do
			
			QuotaIsNotFilledIn = QuotaIsNotFilledIn Or String.QuotaIsNotFilledIn;
			QuotaIsFull = QuotaIsFull Or String.QuotaIsFull;
			
			If QuotaIsNotFilledIn And QuotaIsFull Then
				Break;
			EndIf; 
		EndDo; 
		CurRowParent.QuotaIsNotFilledIn = QuotaIsNotFilledIn Or CurRowParent.FillingConsideringSelection < CurRowParent.Quota;
		CurRowParent.QuotaIsFull = QuotaIsFull Or CurRowParent.FillingConsideringSelection > CurRowParent.Quota;
		UpdateContentBasedOnLineParentSelection(CurRowParent, Count);
	EndIf;
	
EndProcedure

&AtServer
Function FindRowInCollectionTree(TreeCollection, ProductCategory)
	
	FoundRow = Undefined;
	CollectionItems = TreeCollection.GetItems();
	
	For Each CollectionItem In CollectionItems Do
		If CollectionItem.TypeCategoryBrand = ProductCategory Then
			FoundRow = CollectionItem;
			Break;
		Else
			CollectionItemInSubordinates = FindRowInCollectionTree(CollectionItem, ProductCategory);
			If CollectionItemInSubordinates <> Undefined Then
				FoundRow = CollectionItemInSubordinates;
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	Return FoundRow;
	
EndFunction

&AtServerNoContext
Function QuotaStructureByCategory(Val PlanningObject, Val ProductCategory, Val BrandSelection, Val ValidityStartDate)
	
	QuotaStructure = ProductRangeServer.QuotaStructureByCategory(
		PlanningObject,
		ProductCategory,
		BrandSelection,
		ValidityStartDate);
	
	Return QuotaStructure;
	
EndFunction

&AtServerNoContext
Procedure CommonSettingsStorageSave(ClosingParameters)
	
	Common.CommonSettingsStorageSave(
		"ProductSelectionByCategoryFormSettings",
		 "",
		ClosingParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionOfListOfProductsForSelectedProduct(Form)

	FilterOfProductItem = New ValueList;
	For Each TSRow In Form.Object.SelectedGoodsTable Do
		FilterOfProductItem.Add(TSRow.Products);
	EndDo; 
	
	CommonClientServer.SetDynamicListFilterItem(Form.ListProducts, "Ref", FilterOfProductItem, DataCompositionComparisonType.NotInList,,True);
	
EndProcedure

&AtClient
Procedure ExecuteSearch()
	
	SelectGoodsClient.PerformingAdvancedSearchIsPossible(ThisForm, 
		New CallbackDescription("ExecuteSearchCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure ExecuteSearchCompletion(Result, AdditionalParameters) Export 
	
	SearchForProductsOnServer_();
	
	SelectGoodsClient.AfterSearchingForProducts(ThisForm);

EndProcedure

&AtServer
Procedure SearchForProductsOnServer_()
	
	SelectGoodsServer.SearchForProducts(ThisForm);
	
EndProcedure

&AtServer
Procedure DeselectProductSearchBarOnServer()
	
	SelectGoodsClientServer.DeselectProductSearchBar(ThisForm);
	
EndProcedure

&AtClient
Procedure CheckAndAddProductsToCart(ListOfSelectedProducts)

	ListOfSelectedProductsToAdd = New Array;
	
	// Let's determine what problems there are with adding the product
	CheckResultOnAddingToAShoppingCart.Clear();
	For Each ProductData_8 In ListOfSelectedProducts Do
		
		CanBeAddedToCart = True;
		
		If (Stage = PredefinedValue("Enum.ProductRangeChangeSteps.RemoveFromProductRange")
			Or Stage = PredefinedValue("Enum.ProductRangeChangeSteps.TransferToArchiveRevoke")) Then
			
			If (ProductData_8.ProductRangePhase = Phase Or Not ValueIsFilled(ProductData_8.ProductRangePhase)) Then
				AddIssueWhenAddingProduct("ProductHasAlreadyBeenRemovedFromRange", CanBeAddedToCart);
			EndIf;
			
		Else
			
			If ProductData_8.ProductRangePhase = Phase
				And Stage <> PredefinedValue("Enum.ProductRangeChangeSteps.ChangeOfProductRangeStatus") Then
				
				AddIssueWhenAddingProduct("GoodsAreAlreadyInStage", CanBeAddedToCart);
			EndIf;
			
			QuotaStructure = QuotaStructureByCategory(PlanningObject,
														ProductData_8.ProductCategory,
														ProductData_8.Brand,
														ValidityStartDate);
														
			If QuotaStructure.Quota = 0 Then
				AddIssueWhenAddingProduct("QuotaNotSet", CanBeAddedToCart);
			EndIf;
		EndIf;
		
		If CanBeAddedToCart Then
			ListOfSelectedProductsToAdd.Add(ProductData_8);
		EndIf; 
		
	EndDo; 
	
	QueryText = Undefined;
	
	If CheckResultOnAddingToAShoppingCart.Count() = 1 Then
		
		ProblemOfAddingGoods = CheckResultOnAddingToAShoppingCart[0];
		
		If ProblemOfAddingGoods.IssueName = "ProductHasAlreadyBeenRemovedFromRange" Then
			
			If ListOfSelectedProductsToAdd.Count() = 0 Then
				// There is not a single product that can be added without a question
				If ProblemOfAddingGoods.GoodsQuantity = 1 Then
					QueryText = NStr("vi = 'Hàng hóa này đã loại khỏi danh điểm.
												  |Không cần thêm chúng vào chứng từ.';
												  |ru = 'Данный товар уже выведен из ассортимента.
												  |Добавление его в документ не требуется.';
												  |en = 'This item has been discontinued.
												  |Do not add it to the document.'; fa = 'This item has been discontinued.
												  |Do not add it to the document.';
												  |it = 'Questa merce è già ritirata dall''assortimento.
												  |Non è necessario aggiungerlo al documento.';
												  |pl = 'Ten towar jest już wycofany z asortymentu.
												  |Dodawanie go do dokumentu nie jest wymagane.';
												  |tr = 'Bu ürün halihazırda ürün yelpazesinden çıkarılmıştır.
												  |Belgeye eklenmesi gerekli değildir.'");
				Else
					QueryText = NStr("vi = 'Đã chọn hàng hóa đã lấy ra từ danh điểm.
												  |Không cần thêm chúng vào chứng từ.';
												  |ru = 'Выбранные товары уже выведены из ассортимента.
												  |Добавление их в документ не требуется.';
												  |en = 'All of the selected items have already been discontinued.
												  |Do not add them to the document.'; fa = 'All of the selected items have already been discontinued.
												  |Do not add them to the document.';
												  |it = 'Una parte delle merci selezionato è già stata ritirata dall''assortimento.
												  |Non è necessario aggiungerli al documento.';
												  |pl = 'Te wiersze pozycji są już wycofane z asortymentu.
												  |Dodawanie ich do dokumentu nie jest wymagane.';
												  |tr = 'Seçilen ürünler artık ürün yelpazesinden çıkarılmıştır.
												  |Bunları belgeye eklemeye gerek yoktur.'");
				EndIf; 
			Else
				// Some products can be added without question
				QueryText = NStr("vi = 'Một phần của hàng hóa đã chọn đã được lấy ra từ danh điểm.
											  |Không cần thêm chúng vào chứng từ.';
											  |ru = 'Часть выбранного товара уже выведена из ассортимента.
											  |Добавление их в документ не требуется.';
											  |en = 'Some of the selected items have already been discontinued.
											  |Do not add them to the document.'; fa = 'Some of the selected items have already been discontinued.
											  |Do not add them to the document.';
											  |it = 'Una parte delle merci selezionato è già stata ritirata dall''assortimento.
											  |Non è necessario aggiungerli al documento.';
											  |pl = 'Część wybranego towaru są już wycofane z asortymentu.
											  |Dodawanie ich do dokumentu nie jest wymagane.';
											  |tr = 'Seçilen ürünlerden bazıları artık ürün yelpazesinden çıkarılmıştır.
											  |Bunları belgeye eklemeye gerek yoktur.'");
			EndIf;

		ElsIf ProblemOfAddingGoods.IssueName = "GoodsAreAlreadyInStage" Then	
			
			If ListOfSelectedProductsToAdd.Count() = 0 Then
				// There is not a single product that can be added without a question
				If ProblemOfAddingGoods.GoodsQuantity = 1 Then
					QueryText = NStr("vi = 'Hàng hóa này đã ở giai đoạn ""%1"".
									  			| Không bắt buộc phải thêm vào chứng từ.';
									  			|ru = 'Данный товар уже находится в стадии ""%1"".
									  			|Добавление его в документ не требуется.';
									  			|en = 'This product is already on step ""%1"".
									  			|It is not required to add it to the document.'; fa = 'This product is already on step ""%1"".
									  			|It is not required to add it to the document.';
									  			|it = 'Questa merce non si trova nella fase ""%1"".
									  			|Non è necessario aggiungerlo al documento.';
									  			|pl = 'Ten towar znajduje się już w fazie ""%1"".
									  			|Dodawanie go do dokumentu nie jest wymagane.';
									  			|tr = 'Bu ürün zaten ""%1"" aşamasındadır.
									  			|Belgeye eklenmesi gerekli değildir.'");
				Else
					QueryText = NStr("vi = 'Hàng hóa đã chọn đã ở giai đoạn ""%1"".
												  | Không bắt buộc phải thêm vào chứng từ.';
												  |ru = 'Выбранные товары уже находится в стадии ""%1"".
												  |Добавление их в документ не требуется.';
												  |en = 'Selected goods are already at the ""%1"" step.
												  |You do not need to add them to the document.'; fa = 'Selected goods are already at the ""%1"" step.
												  |You do not need to add them to the document.';
												  |it = 'Le merci seelzionate non si trovano nella fase ""%1"".
												  |Non è necessario aggiungerli al documento.';
												  |pl = 'Te wiersze pozycji znajdują się już w fazie ""%1"".
												  |Dodawanie ich do dokumentu nie jest wymagane.';
												  |tr = 'Seçilen ürünler artık ""%1"" aşamasındadır.
												  |Bunları belgeye eklemeye gerek yoktur.'");
				EndIf; 
			Else
				// Some products can be added without question
				QueryText = NStr("vi = 'Một phần của hàng hóa đã chọn đã ở giai đoạn ""%1"".
											  | Không bắt buộc phải thêm vào chứng từ.';
											  |ru = 'Часть выбранного товара уже находится в стадии ""%1"".
											  |Добавление их в документ не требуется.';
											  |en = 'Some of the selected goods are already at the ""%1"" step.
											  |You do not need to add them to the document.'; fa = 'Some of the selected goods are already at the ""%1"" step.
											  |You do not need to add them to the document.';
											  |it = 'La parte delle merci selezionate già si trovano nella fase ""%1"".
											  |Non è necessario aggiungerli al documento.';
											  |pl = 'Część wybranego towaru znajduje się już w fazie ""%1"".
											  |Dodawanie ich do dokumentu nie jest wymagane.';
											  |tr = 'Seçilen ürünün bir bölümü zaten ""%1"" aşamasındadır.
											  |Bunları belgeye eklemeye gerek yoktur.'");
			EndIf;
			
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText, Phase);
			
		ElsIf ProblemOfAddingGoods.IssueName = "QuotaNotSet" Then
			
			If ListOfSelectedProductsToAdd.Count() = 0 Then
				// There is not a single product that can be added without a question
				If ProblemOfAddingGoods.GoodsQuantity = 1 Then
					// One product is selected, let's take its data
					ProductCategory = ListOfSelectedProducts[0].ProductCategory;
					Brand = ListOfSelectedProducts[0].Brand;
					If ValueIsFilled(Brand) Then
						QueryText = StringFunctionsClientServer.SubstituteParametersToString(
												NStr("vi = 'Chưa đặt hạn mức theo thể loại mặt hàng ""%1"" và nhãn hiệu ""%2"".
															|Sự hiện diện của sản phẩm này trong danh điểm
												  			| mâu thuẫn với chính sách danh điểm.';
												  			|ru = 'По товарной категории ""%1"" и марке ""%2"" не установлена квота.
												  			|Присутствие данного товара в ассортименте
												  			|противоречит ассортиментной политике.';
												  			|en = 'Quota is not set for product category ""%1"" and brand ""%2"".
												  			|Presence of these goods in the product range 
												  			|violates the product range policy.'; fa = 'Quota is not set for product category ""%1"" and brand ""%2"".
															|Presence of these goods in the product range 
															|violates the product range policy.';
												  			|it = 'Nella categoria dell''articolo ""%1"" e marchio ""%2"" non è stata impostata la quota.
												  			|La presenza di questa merce  nell''assortimento
												  			|contraddice la politica di assortimento.';
												  			|pl = 'Dla kategorii produktów ""%1"" i marki ""%2"" nie ustalono limitu.
												  			|Obecność tego produktu w asortymencie
												  			|jest sprzeczne z polityką asortymentową.';
												  			|tr = '""%1"" ürün kategorisi ve ""%2"" markası için kota yok.
												  			|Bu ürünün ürün gamında
												  			|bulunması ürün gamı politikasına aykırıdır.'"),
												ProductCategory,
												Brand);
					Else
						QueryText = StringFunctionsClientServer.SubstituteParametersToString(
												NStr("vi = 'Chưa đặt hạn mức theo thể loại hàng hóa ""%1"".
															|Sự hiện diện của sản phẩm này trong danh điểm
														  	| mâu thuẫn với chính sách danh điểm.';
														  	|ru = 'По товарной категории ""%1"" не установлена квота.
														  	|Присутствие данного товара в ассортименте
														  	|противоречит ассортиментной политике.';
														  	|en = 'Quota is not set for product category ""%1"".
														  	|Presence of these goods in the product range 
														  	|violates the product range policy.'; fa = 'Quota is not set for product category ""%1"".
															|Presence of these goods in the product range 
															|violates the product range policy.';
														  	|it = 'Nella categoria dell''articolo ""%1"" non è impostata la quota.
														  	|La presenza di questa merce  nell''assortimento
														  	|contraddice la politica di assortimento.';
														  	|pl = 'Dla kategorii produktów ""%1"" nie ustalono limitu.
														  	|Obecność tego produktu w asortymencie
														  	|jest sprzeczne z polityką asortymentową.';
														  	|tr = '""%1"" ürün kategorisi için kota yok.
														  	|Bu ürünün ürün gamında
														  	|bulunması ürün gamı politikasına aykırıdır.'"),
												ProductCategory);
					EndIf; 
				Else
					QueryText = NStr("vi = 'Chưa đặt hạn mức cho các theo thể loại hàng hóa đối với hàng hóa đã chọn. 
												|Sự hiện diện của các sản phẩm đã chọn trong danh điểm
									  			| mâu thuẫn với chính sách danh điểm.';
									  			|ru = 'По товарным категориям выбранных товаров не установлена квота.
									  			|Присутствие выбранных товаров в ассортименте
									  			|противоречит ассортиментной политике.';
									  			|en = 'Quota is not set for product categories of the selected goods.
									  			|Presence of the selected goods in the product range 
									  			|violates the product range policy.'; fa = 'Quota is not set for product categories of the selected goods.
												|Presence of the selected goods in the product range 
												|violates the product range policy.';
									  			|it = 'Per categorie dell''articoli  non è stata impostata la quota.
									  			|La presenza di questa merce  nell''assortimento
									  			|contraddice la politica di assortimento.';
									  			|pl = 'Dla kategorii produktów wybranych towarów nie ustalono limitu.
									  			|Obecność wybranych produktów w asortymencie
									  			|jest sprzeczne z polityką asortymentową.';
									  			|tr = 'Seçilen ürünlerin ürün kategorileri için herhangi bir kota belirlenmedi.
									  			|Seçilen ürünlerin ürün gamında bulunması
									  			|ürün gamı politikasına aykırıdır.'");
				EndIf; 
			Else
				// Some products can be added without question
				QueryText = NStr("vi = 'Chưa đặt hạn mức theo thể loại hàng hóa đối với một phần hàng hóa đã chọn.
											|Sự hiện diện của các hàng hóa này trong danh điểm mâu thuẫn với chính sách danh điểm.';
											|ru = 'По товарным категориям части выбранных товаров не установлена квота.
											|Присутствие этих товаров в ассортименте противоречит ассортиментной политике.';
											|en = 'Quota is not set for product categories of some of the selected goods.
											|Presence of these goods in the product range violates the product range policy.'; fa = 'Quota is not set for product categories of some of the selected goods.
											|Presence of these goods in the product range violates the product range policy.';
											|it = 'Per categorie dell''articoli selezionati non è stata impostata la quota.
											|La presenza di questa merce  nell''assortimento contraddice la politica di assortimento..';
											|pl = 'Dla kategorii produktów części wybranych towarów nie ustalono limitu.
											|Obecność tych produktów w asortymencie jest sprzeczne z polityką asortymentową.';
											|tr = 'Seçilen bazı ürünlerin ürün kategorileri için kota belirlenmedi.
											|Bu ürünlerin ürün gamında bulunması ürün gamı politikasına aykırıdır.'");
			EndIf;
			
		EndIf; 
	
	ElsIf CheckResultOnAddingToAShoppingCart.Count() > 1 Then
		
		// There were several problems
		
		If ListOfSelectedProductsToAdd.Count() = 0 Then
			// There is not a single product that can be added without a question
			If ListOfSelectedProducts.Count() = 1 Then
				QueryText = NStr("vi = 'Không cần thêm hàng hóa vào chứng từ:';
								|ru = 'Добавление товара в документ не требуется:';
								|en = 'It is not required to add the goods to the document:'; fa = 'It is not required to add the goods to the document:';
								|it = 'L''aggiunta di merci al documento non è richiesta:';
								|pl = 'Dodanie towaru do dokumentu nie jest wymagane:';
								|tr = 'Ürünü belgeye eklemeye gerek yoktur:'");
			Else
				QueryText = NStr("vi = 'Không nên thêm các hàng hóa đã chọn vào chứng từ:';
								|ru = 'Добавление выбранных товаров в документ не требуется:';
								|en = 'It is not required to add the selected goods to the document:'; fa = 'It is not required to add the selected goods to the document:';
								|it = 'L''aggiunta di merci al documento non è richiesta:';
								|pl = 'Dodanie wybranych towarów do dokumentu nie jest wymagane:';
								|tr = 'Seçilen ürünleri belgeye eklemeye gerek yoktur:'");
			EndIf;
		Else
			// Some products can be added without question
			QueryText = NStr("vi = 'Một phần hàng hóa đã chọn không cần bổ sung vào chứng từ:';
							|ru = 'Часть выбранного товара не требуется добавлять в документ:';
							|en = 'It is not required to add some of the selected goods to the document:'; fa = 'It is not required to add some of the selected goods to the document:';
							|it = 'La parte delle merci selezionate non è necessario aggiungere al docuemnto:';
							|pl = 'Część wybranego towaru nie trzeba dodawać do dokumentu:';
							|tr = 'Seçilen ürünün bir bölümünün belgeye eklenmesine gerek yoktur:'");
		EndIf;
		
		SecurityIssues = "";
		For Each ProblemOfAddingGoods In CheckResultOnAddingToAShoppingCart Do
			
			If ProblemOfAddingGoods.IssueName = "ProductHasAlreadyBeenRemovedFromRange" Then
				
				IssuePresentation = NStr("vi = '- hàng hóa được lấy ra từ danh điểm';
										|ru = '- товар уже выведен из ассортимента';
										|en = '- product has already been removed from the product range'; fa = '- product has already been removed from the product range';
										|it = '- la merce è già stata ritirata dall''assortimento';
										|pl = '- towar jest już wycofany z asortymentu';
										|tr = '- ürün halihazırda ürün gamından çekilmiştir'");
				
			ElsIf ProblemOfAddingGoods.IssueName = "GoodsAreAlreadyInStage" Then
				
				IssuePresentation = StringFunctionsClientServer.SubstituteParametersToString(
											NStr("vi = '- hàng hóa đã có trong giai đoạn ""%1""';
												|ru = '- товар уже находится в стадии ""%1""';
												|en = '- goods are already on step ""%1""'; fa = '- goods are already on step ""%1""';
												|it = '- la fase già si trova nella fase ""%1""';
												|pl = '- towar znajduje się już w fazie ""%1""';
												|tr = '- ürün zaten ""%1"" aşamasındadır'"), 
											Phase);
											
			ElsIf ProblemOfAddingGoods.IssueName = "QuotaNotSet" Then

				IssuePresentation = NStr("vi = '- chưa thiết lập hạn ngạch';
										|ru = '- не установлена квота';
										|en = '- quota is not set'; fa = '- quota is not set';
										|it = '- quota non impostata';
										|pl = '- nie ustalono limitu';
										|tr = '- kota ayarlanmadı'");
				
			EndIf;
			
			SecurityIssues = SecurityIssues 
								+ ?(SecurityIssues = "", "", Chars.LF)
								+ IssuePresentation;
		EndDo; 
		
		QueryText = QueryText + Chars.LF + SecurityIssues;
		
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ListOfSelectedProducts", ListOfSelectedProducts);
	AdditionalParameters.Insert("ListOfSelectedProductsToAdd", ListOfSelectedProductsToAdd);
	If QueryText <> Undefined Then
		CallbackDescription = New CallbackDescription("AddProductsToCartEnd", ThisObject, AdditionalParameters);
		ButtonsList = New ValueList;
		If ListOfSelectedProducts.Count() = 1 Then
			ButtonsList.Add("AddAll", NStr("vi = 'Thêm';
											|ru = 'Добавить';
											|en = 'Add'; fa = 'افزودن';
											|it = 'Aggiungere';
											|pl = 'Add';
											|tr = 'Ekle'"));
			ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Chưa thêm';
														|ru = 'Не добавлять';
														|en = 'Do not add'; fa = 'افزوده نشود';
														|it = 'Non aggiungere';
														|pl = 'Nie dodawaj';
														|tr = 'Eklemeyin'"));
			
		ElsIf ListOfSelectedProductsToAdd.Count() <> 0 Then
			ButtonsList.Add("AddSuitableOnes", NStr("vi = 'Thêm chỉ hàng hóa phù hợp';
													|ru = 'Добавить только подходящие';
													|en = 'Add only suitable'; fa = 'Add only suitable';
													|it = 'Visualizzare solo idonei';
													|pl = 'Dodać tylko odpowiednie';
													|tr = 'Sadece uygun olanları ekle'"));
			ButtonsList.Add("AddAll", NStr("vi = 'Thêm tất cả';
											|ru = 'Добавить все';
											|en = 'Add all'; fa = 'Add all';
											|it = 'Aggiungere tutto';
											|pl = 'Dodać wszystko';
											|tr = 'Tümünü ekle'"));
			ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Chưa thêm';
														|ru = 'Не добавлять';
														|en = 'Do not add'; fa = 'افزوده نشود';
														|it = 'Non aggiungere';
														|pl = 'Nie dodawaj';
														|tr = 'Eklemeyin'"));
		Else
			ButtonsList.Add("AddAll", NStr("vi = 'Thêm tất cả';
											|ru = 'Добавить все';
											|en = 'Add all'; fa = 'Add all';
											|it = 'Aggiungere tutto';
											|pl = 'Dodać wszystko';
											|tr = 'Tümünü ekle'"));
			ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Chưa thêm';
														|ru = 'Не добавлять';
														|en = 'Do not add'; fa = 'افزوده نشود';
														|it = 'Non aggiungere';
														|pl = 'Nie dodawaj';
														|tr = 'Eklemeyin'"));
		EndIf; 
		
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
	Else
		AddProductsToCartEnd("AddAll", AdditionalParameters);
	EndIf; 
		
EndProcedure

&AtClient
Procedure AddProductsToCartEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = "AddAll" Then
		ListOfSelectedProducts = AdditionalParameters.ListOfSelectedProducts;
	ElsIf QuestionResult = "AddSuitableOnes" Then
		ListOfSelectedProducts = AdditionalParameters.ListOfSelectedProductsToAdd;
	Else
		Return;
	EndIf;
	
	AddProductsToCartOnServer(ListOfSelectedProducts);
	
	TableOfSelectedProductsWhenChanging();
	
	If Not ShowSelectedGoods Then
		
		If ListOfSelectedProducts.Count() = 1 Then
			ProductData_8 = ListOfSelectedProducts[0];
			EventText = NStr("vi = 'Đã thêm hàng hóa vào bảng lựa chọn';
							|ru = 'Товар добавлен в таблицу подбора';
							|en = 'Goods are added to the picking table'; fa = 'Goods are added to the picking table';
							|it = 'Merce aggiunta alla tabella di selezione';
							|pl = 'Towar został dodany do tabeli doboru';
							|tr = 'Ürün seçim tablosuna eklendi'");
			NotificationText1 = NStr("vi = 'Hàng hóa %OwnGoods% được thêm vào bảng lựa chọn';
									|ru = 'Товар %OwnGoods% добавлен в таблицу подбора';
									|en = 'The %OwnGoods% goods are added to the picking table'; fa = 'The %OwnGoods% goods are added to the picking table';
									|it = 'Merce %OwnGoods% aggiunta alla tabella di selezione';
									|pl = 'Towar %OwnGoods% został dodany do tabeli doboru';
									|tr = 'Ürün %OwnGoods% seçim tablosuna eklendi'");
			NotificationText1 = StrReplace(NotificationText1, "%OwnGoods%", String(ProductData_8.Products));
		Else
			EventText = NStr("vi = 'Hàng hóa được thêm vào bảng chọn';
							|ru = 'Товары добавлены в таблицу подбора';
							|en = 'Goods are added to picking table'; fa = 'Goods are added to picking table';
							|it = 'Merci aggiunti alla tabella di selezione';
							|pl = 'Wiersze pozycji zostały dodane do tabeli doboru';
							|tr = 'Seçim tablosuna ürünler eklendi'");
			NotificationText1 = NStr("vi = 'Hàng hóa đã chọn được thêm vào phần bảng chọn';
									|ru = 'Выбранные товары добавлены в таблицу подбора';
									|en = 'Picked goods are added to the picking table'; fa = 'Picked goods are added to the picking table';
									|it = 'Merci selezionate aggiunte alla tabella di selezione';
									|pl = 'Wybrane wiersze pozycji zostały dodane do tabeli doboru';
									|tr = 'Seçilen ürünler seçim tablosuna eklendi'");
		EndIf;
		
		ShowUserNotification(EventText, ,NotificationText1);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AddProductsToCartOnServer(ListOfSelectedProducts)

	For Each ProductData_8 In ListOfSelectedProducts Do
		NewRow = Object.SelectedGoodsTable.Add();
		FillPropertyValues(NewRow, ProductData_8);
		UpdateContentBasedOnSelectionInTree(NewRow.ProductRangePhase, NewRow.ProductCategory, NewRow.Brand, 1);
	EndDo; 
	
	Modified = True;
	
	SetSelectionOfListOfProductsForSelectedProduct(ThisForm);

EndProcedure

&AtClient
Procedure AddIssueWhenAddingProduct(IssueName, CanBeAddedToCart)

	TheStructureOfTheSearch = New Structure("IssueName", IssueName);
 	StringsList = CheckResultOnAddingToAShoppingCart.FindRows(TheStructureOfTheSearch);
	If StringsList.Count() <> 0 Then
		CheckResultString = StringsList[0];
	Else
		CheckResultString = CheckResultOnAddingToAShoppingCart.Add();
		CheckResultString.IssueName = IssueName;
	EndIf;
	
	CheckResultString.GoodsQuantity = CheckResultString.GoodsQuantity + 1;
	
	CanBeAddedToCart = False;
	
EndProcedure

&AtClient
Function ProductData_8(StringProducts_)

	ProductData_8 = SelectGoodsClientServer.ProductParameters_1();
	FillPropertyValues(ProductData_8, StringProducts_);
	
	Return ProductData_8;

EndFunction

&AtClient
Procedure GetDragAndDropData(DragParameters)
	
	ParametersArray = New Array; 
	
	For Each RowKey In DragParameters.Value Do
		
		RowData = Items.ListAdvancedSearchProducts.RowData(RowKey);
		
		If RowData = Undefined Then
			Continue;
		EndIf;
		
		ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
		FillPropertyValues(ProductParameters_1, RowData);
		
		ParametersArray.Add(ProductParameters_1);
		
	EndDo;
	
	DragParameters.Value = ParametersArray;
	
EndProcedure

&AtServer
Procedure DeleteSelectedProductsByKeyOnServer(KeyArray)
	
	DeletedRowsFromTheSelectedGoodsTable.Clear();
	For Each RowID In KeyArray Do
		RowData = Object.SelectedGoodsTable.FindByID(RowID);
		FillPropertyValues(DeletedRowsFromTheSelectedGoodsTable.Add(), RowData);
		Object.SelectedGoodsTable.Delete(RowData);
	EndDo;
	
EndProcedure

&AtClient
Procedure AfterDeletingRowsFromTableOfSelectedProducts()

	UpdateInformationLabelOfQuantityOfGoods();
	
	AfterDeletingRowsFromTableOfSelectedProductsOnServer();

EndProcedure

&AtServer
Procedure AfterDeletingRowsFromTableOfSelectedProductsOnServer()

	For Each RowData In DeletedRowsFromTheSelectedGoodsTable Do
		UpdateContentBasedOnSelectionInTree(
					RowData.ProductRangePhase, 
					RowData.ProductCategory, 
					RowData.Brand, -1);
	EndDo;
	
	SetSelectionOfListOfProductsForSelectedProduct(ThisForm);
	
	DeletedRowsFromTheSelectedGoodsTable.Clear();
	
EndProcedure

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
