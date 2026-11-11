////////////////////////////////////////////////////////////////////////////////
// The module "Product Selection Client" contains the procedures and functions necessary for
// the operation of the product selection forms. Working with selections, event handlers 
// of form elements.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region KeyboardShortcuts

// The procedure sets the desired selection panel as the current element, depending
// on the navigation option set.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetTheCurrentNavigationElement(Form) Export
	
	NavigationOption = Form.NavigationOption;
	
	If NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByHierarchy") Then
		
		Form.CurrentItem = Form.Items.ProductsHierarchy;
		
	ElsIf NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByProperties")
			Or NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKindsAndProperties")
			Or NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKinds") Then
		
		Form.CurrentItem = Form.Items.FilterTree;
		
	ElsIf NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByGoodsSoldTogether") Then
		
		Form.CurrentItem = Form.Items.TableItemSoldTogetherPremise;
		
	EndIf;
	
EndProcedure

// The procedure sets the item list as the current item.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetTheCurrentItemProductList(Form) Export
	
	If Form.CharacteristicNavigation Then
		Form.CurrentItem = Form.Items[SelectGoodsClientServer.NameOfListOfCharacteristicsBySearchOption(Form)];
	Else
		Form.CurrentItem = Form.Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form)];
	EndIf;
	
EndProcedure

// The procedure sets the current item - the list of selected products - to the shopping cart.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetTheCurrentItemTrash(Form) Export
	
	Form.CurrentItem = Form.Items.junk;
	
EndProcedure

// The procedure sets the current item - the list of supplier items.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetTheCurrentPartnerItemItem(Form) Export
	
	Form.CurrentItem = Form.Items[SelectGoodsClientServer.NameOfListOfPartnerProductsForSearchOption(Form)];
	
EndProcedure

// Returns the name of the current search string element on the selection form.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
// Returns:
//	String - the name of the current element of the search bar of the selection form.
//
Function NameOfCurElementOfSearchString(Form) Export
	
	ThisIsFormOfSelectionInPurchaseDocuments = SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode);
	ThisIsFormOfMatching = SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode);
	
	CurrentItemName = "SearchStringProducts";
	
	If ThisIsFormOfMatching Then
		If ThisIsFormOfSelectionInPurchaseDocuments Then
			If Form.NavigationThroughThePartnerSProductRange Then
				CurrentItemName = "SearchBarPartnerItem";
			ElsIf Form.CharacteristicNavigation Then
				CurrentItemName = "SearchBarCharacteristics";
			EndIf;
		Else
			If Form.CharacteristicNavigation Then
				CurrentItemName = "SearchBarCharacteristics";
			EndIf;
		EndIf;
	EndIf;
	
	Return CurrentItemName;

EndFunction

// The procedure sets the search bar on the form as the current element.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure SetTheCurrentSearchBarItem(Form) Export
	
	SearchMode = SelectGoodsClientServer.CurrentSearchOption(Form);
	If Not SearchMode = "Advanced" Then
		Return;
	EndIf;
	
	CurrentItemName = NameOfCurElementOfSearchString(Form);
	
	Form.CurrentItem = Form.Items[CurrentItemName];
	
EndProcedure

#EndRegion

#Region WorkingWithBasket

// Invoked before the form is closed the selection of goods. If you do not set
// the option to transfer products to the cart, but there are selected products in the cart,
// then you will get a question.
//
// Parameters:
//	Form - ClientApplicationForm - form the selection of goods,
//	Object - DataProcessorObjectDataProcessorName - processing the selection of goods,
//	Cancel - Boolean - the variable that the failure flag is written to.
//
Procedure BeforeClosingProductSelectionForm(Form, Object, Cancel) Export
	
	If Form.MoveToDocument Or Form.ClosingInProgress Then
		Return;
	EndIf;
	
	If Object.junk.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Chưa chuyển hàng hóa đã chọn vào chứng từ. Chuyển?';
					|ru = 'Подобранные товары не перенесены в документ. Перенести?';
					|en = 'Selected items are not added to the document. Do you want to add them?'; fa = 'Selected items are not added to the document. Do you want to add them?';
					|it = 'La merce selezionata non è stata trasferita nel documento. Trasferire?';
					|pl = 'Wybrane wiersze pozycji nie zostały przeniesione do dokumentu. Przenieść?';
					|tr = 'Seçili ürünler belgeye aktarılmadı. Aktarılsın mı?'");
	If TypeOf(Form.Parameters.Document) = Type("CatalogRef.BillsOfMaterials") Then
		QueryText = NStr("vi = 'Chưa chuyển hàng hóa đã chọn vào danh mục. Chuyển?';
						|ru = 'Подобранные товары не перенесены в справочник. Перенести?';
						|en = 'Picked goods are not added to the catalog. Do you want to add them?'; fa = 'Picked goods are not added to the catalog. Do you want to add them?';
						|it = 'Le merci selezionate non sono state trasferite nell''anagrafica. Trasferire?';
						|pl = 'Wybrane towary nie zostały przeniesione do katalogu. Przenieść?';
						|tr = 'Seçili ürünler kataloğa aktarılmadı. aktarılsın mı?'");
	EndIf;
	Cancel = True;
	ShowQueryBox(
		New CallbackDescription("BeforeClosingProductSelectionFormCompletion", ThisObject, 
			New Structure("Form", Form)), 
		QueryText, 
		QuestionDialogMode.YesNoCancel);
		
EndProcedure

// The service procedure.
//
// Parameters:
// 	QuestionResult - DialogReturnCode - code of the selected answer to the question
// 	AdditionalParameters - Structure - additional parameters for the notification description.
//
Procedure BeforeClosingProductSelectionFormCompletion(QuestionResult, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	ElsIf QuestionResult = DialogReturnCode.Yes Then
		Form.MoveToDocument = True;
		Form.ClosingInProgress = True;
		Form.Close(DialogReturnCode.OK);
		Form.ClosingInProgress = False;
		Return;
	EndIf;
	
	Form.ClosingInProgress = True;
	Form.Close();
	Form.ClosingInProgress = False;

EndProcedure

#EndRegion

#Region EventHandlersForFormElements

// This procedure is called when a list row in the item hierarchy is activated.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form.
//
Procedure WhenProductHierarchyLineIsActivated(Form) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"CommonModule.SelectGoodsClient.WhenProductHierarchyLineIsActivated");
	
	If Form.NavigationOption <>
		PredefinedValue("Enum.ItemFormNavigationOptions.ByHierarchy") Then
		Return;
	EndIf;
	
	If Form.CurrentProductsHierarchy = Form.Items.ProductsHierarchy.CurrentRow Then
		Return;
	EndIf;
	
	Form.CurrentProductsHierarchy = Form.Items.ProductsHierarchy.CurrentRow;
	
	If Not Form.UseFilters Then
		Return;
	EndIf;
	
	Form.AttachIdleHandler("ProductHierarchyWhenActivatingWaitHandlerLine", 0.1, True);
	
EndProcedure

// This procedure is called when a list row in the item hierarchy is activated.
//
// Parameters:
//	Form - See SelectGoodsServer.WhenCreatingMatchingFormOnServer.Form
//
Procedure HandlerForActivatingLineInProductHierarchy(Form) Export
	
	SelectGoodsClientServer.SetSelectionByProductHierarchy(Form);
	
	If ValueIsFilled(Form.SearchStringProducts) Then
		
		//@skip-check notify-description-to-server-procedure
		//@skip-check bsl-legacy-check-string-literal
		PerformingAdvancedSearchIsPossible(
			Form,
			New CallbackDescription("SearchForProductsCompletion", Form));
		
	EndIf;
	
	If SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode)
		And Form.CharacteristicNavigation Then
		
		GoToListOfProducts(Form);
		
	EndIf;

EndProcedure

// This procedure is called when a line in the list of item types is activated.
//
// Parameters:
//	Form - See SelectGoodsServer.WhenCreatingMatchingFormOnServer.Form
//
Procedure WhenActivatingProductTypesListLine(Form) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"CommonModule.SelectGoodsClient.WhenActivatingProductTypesListLine");
	
	If Not (Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByProperties")
		Or Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKindsAndProperties")
		Or Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKinds")) Then
		Return;
	EndIf;
	
	CurrentData = Form.Items.ItemKinds.CurrentData;
	
	If CurrentData = Undefined
		Or Form.ProductKind = CurrentData.Ref Then
		Return;
	EndIf;
	
	Form.ProductKind = CurrentData.Ref;
	
	If Not Form.UseFilters Then
		Return;
	EndIf;
		
	Form.AttachIdleHandler("TypesOfProductsWhenActivatingWaitHandlerLine", 0.1, True);
EndProcedure

// This procedure is called when a list row in the supplier's item hierarchy is activated.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form.
//
Procedure WhenActivatingLineInPartnerProductHierarchy(Form) Export
	
	If Not Form.UseThePartnerItemFilter_3 Then
		Return;
	EndIf;
	
	Form.AttachIdleHandler("HierarchyOfPartnerProductsWhenWaitHandlerLineIsActivated", 0.1, True);
	
EndProcedure

// This procedure is called when a line in the item list is activated.
//
// Parameters:
//	Form - ClientApplicationForm - list form.
//
Procedure WhenActivatingLineInListOfProducts(Form) Export
	
	Form.AttachIdleHandler("ListWhenWaitHandlerLineIsActivated", 0.1, True);
	
EndProcedure

// This procedure is called when a row in the item table is activated on the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - form the selection of goods,
//	Item - FormTable - list of items.
//
Procedure WhenActivatingRowInProductTable(Form, Item) Export
	
	NameOfProductList = SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form);
	
	If Item.Name <> NameOfProductList Then
		Return;
	EndIf;
	
	If Form.CharacteristicNavigation Then
		Return;
	EndIf;
	
	RowOfProductTable = Item.CurrentData;
	
	If RowOfProductTable = Undefined Then
		
		SelectGoodsClientServer.ClearRemainderTable(Form);
		Form.CurrentLineOfProducts = SelectGoodsClientServer.StructureOfProductLine();
		
	Else
		
		If Form.CurrentLineOfProducts <> Undefined Then
			
			If RowOfProductTable.Property("RowGroup")
				Or (Form.CurrentLineOfProducts.Products = RowOfProductTable.Products) Then
				
				Return;
				
			EndIf;
			
		EndIf;
		
		Form.CurrentLineOfProducts = SelectGoodsClientServer.StructureOfProductLine();
		FillPropertyValues(Form.CurrentLineOfProducts, RowOfProductTable);
		
		SetCurRowOfProductHierarchy(Form);
		
		If Form.ShowBalance Then
			Form.AttachIdleHandler("TableSelectionWhenActivatingWaitHandlerLine", 0.1, True);
		EndIf;
		
	EndIf;
	
EndProcedure

// This procedure is called when a row in the characteristics table is activated on the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - form the selection of goods,
//	Item - FormTable - list of features.
//
Procedure WhenActivatingRowInCharacteristicsTable(Form, Item) Export
	
	NameOfListOfCharacteristics = SelectGoodsClientServer.NameOfListOfCharacteristicsBySearchOption(Form);
	
	If Item.Name <> NameOfListOfCharacteristics Then
		Return;
	EndIf;
	
	CharacteristicsTableRow = Item.CurrentData;
	
	If CharacteristicsTableRow = Undefined Then
		
		If Form.CharacteristicNavigation Then
			SelectGoodsClientServer.ClearRemainderTable(Form);
		EndIf;
		Form.CurrentCharacteristicLine = SelectGoodsClientServer.StructureOfCharacteristicsString();
		
		Return;
		
	ElsIf CharacteristicsTableRow.Property("RowGroup") Then
		Return;
	EndIf;
	
	Form.CurrentCharacteristicLine = SelectGoodsClientServer.StructureOfCharacteristicsString();
	FillPropertyValues(Form.CurrentCharacteristicLine, CharacteristicsTableRow);
	
	If Not Form.CharacteristicNavigation Then
		Return;
	EndIf;
	
	If Form.CharacteristicNavigation Then
		Form.AttachIdleHandler("TableSelectionWhenActivatingWaitHandlerLine", 0.1, True);
	EndIf;
	
EndProcedure

// This procedure is called when a row in the supplier's item table is activated on the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - form the selection of goods,
//	Item - FormTable - the list of the supplier's nomenclature contains, among other things:
//				* CurrentData - FormDataStructure - contains including:
//					** Ref - CatalogRef
//
Procedure WhenActivatingPartnerProductLine(Form, Item) Export
	
	If Not Form.NavigationThroughThePartnerSProductRange Then
		Return;
	EndIf;
	
	RowInPartnerProductTable = Item.CurrentData;
	If RowInPartnerProductTable = Undefined Then
		StockBalance = Form.SupplierStockBalance.GetItems();
		StockBalance.Clear();
		
		Form.TheCurrentLineOfThePartnerSItem = SelectGoodsClientServer.ProductParameters_1();
		Return;
	EndIf;
	
	ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
	ProductParameters_1.Insert("PartnerProducts", RowInPartnerProductTable.Ref);
	ProductParameters_1.ItemVariantsAreUsed =
		Not (RowInPartnerProductTable.UseVariants = PredefinedValue("Enum.ItemVariantsUsageOptions.DontUse"));
	
	FillPropertyValues(ProductParameters_1, RowInPartnerProductTable);
	
	Form.TheCurrentLineOfThePartnerSItem = ProductParameters_1;
	
	Form.AttachIdleHandler("TableSelectionWhenActivatingWaitHandlerLine", 0.1, True);
	
EndProcedure

// This procedure is called when the "Display balances" checkbox on the selection forms is changed.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure WhenChangingDisplayOfBalancesByWarehousesInDocument(Form) Export
	
	Form.ShowBalance = Not Form.ShowBalance;
	Form.Items.StockBalance.Visible = Form.ShowBalance;
	
	Form.AttachIdleHandler("TableSelectionWhenActivatingWaitHandlerLine",0.1,True);
	SelectGoodsClientServer.SetCaptionTextToDisplayLeftovers(Form);
	
	If SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode) Then
		
		SelectGoodsClientServer.SetLabelTextToDisplayPartnerProductRemnants(Form);
		Form.Items.SupplierStockBalance.Visible = Form.ShowBalance;
		
	EndIf;
	
EndProcedure

// This procedure is called when selecting a row in the characteristics table in
// the selection forms. The procedure checks whether the string selection is valid.
//
// Parameters:
//	Form - ClientApplicationForm - selection form,
//	Item - FormTable - current list of characteristics,
//	NotificationOfSuccessfulSelection - CallbackDescription - Description of the successful selection notification.
//
Procedure WhenSelectingRowInCharacteristicsTable(Form, Item, NotificationOfSuccessfulSelection) Export
	
	CharacteristicsTableRow = Item.CurrentData;
	If CharacteristicsTableRow = Undefined
		Or CharacteristicsTableRow.Property("RowGroup") Then
		
		Return;
		
	EndIf;
	
	If CharacteristicsTableRow.DeletionMark Then
		ShowQueryBox(
			New CallbackDescription("WhenSelectingRowInCharacteristicsTableCompletion", ThisObject, 
				New Structure("NotificationOfSuccessfulSelection", NotificationOfSuccessfulSelection)), 
			NStr("vi = 'Đã đặt dấu xóa dữ liệu được chọn.
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
			|Bu verilerin seçimini gerçekleştir?'"), 
			QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	RunCallback(NotificationOfSuccessfulSelection);
	
EndProcedure

// The service procedure.
//
// Parameters:
// 	QuestionResult		 - DialogReturnCode - code of the selected answer to the question
// 	AdditionalParameters	 - Structure - additional parameters for the notification description.
//
Procedure WhenSelectingRowInCharacteristicsTableCompletion(QuestionResult, AdditionalParameters) Export
	
	NotificationOfSuccessfulSelection = AdditionalParameters.NotificationOfSuccessfulSelection;
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	RunCallback(NotificationOfSuccessfulSelection);

EndProcedure

// This procedure is called when you select a row in the item table in
// the selection forms. The procedure checks whether the string selection is valid.
//
// Parameters:
//	Form - ClientApplicationForm - selection form,
//	NotificationOfSuccessfulSelection - CallbackDescription - Description of the successful selection notification.
//
Procedure WhenSelectingRowInProductTable(Form, NotificationOfSuccessfulSelection) Export
	
	RowOfProductTable = Form.Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form)].CurrentData;
	If RowOfProductTable = Undefined Then
		Return;
	EndIf;
	If RowOfProductTable.IsFolder Then
		Return;
	EndIf;
	
	If RowOfProductTable.DeletionMark Then
		ShowQueryBox(
			New CallbackDescription("WhenSelectingRowInProductTableCompletion", ThisObject, 
				New Structure("NotificationOfSuccessfulSelection", NotificationOfSuccessfulSelection)), 
			NStr("vi = 'Đã đặt dấu xóa dữ liệu được chọn.
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
			|Bu verilerin seçimini gerçekleştir?'"), 
			QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	RunCallback(NotificationOfSuccessfulSelection);
	
EndProcedure

// The service procedure.
//
// Parameters:
// 	QuestionResult		 - DialogReturnCode - code of the selected answer to the question
// 	AdditionalParameters	 - Structure - additional parameters for the notification description.
//
Procedure WhenSelectingRowInProductTableCompletion(QuestionResult, AdditionalParameters) Export
	
	NotificationOfSuccessfulSelection = AdditionalParameters.NotificationOfSuccessfulSelection;
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	RunCallback(NotificationOfSuccessfulSelection);

EndProcedure

// Called when switching the item page in the product selection form
// to purchase documents. Occurs when switching to the page with the supplier's item and back.
//
// Parameters:
//	Form - See SelectGoodsServer.WhenCreatingMatchingFormOnServer.Form
//
Procedure PagesWhenChangingProductListPage(Form) Export
	
	Items = Form.Items;
	
	Form.NavigationThroughThePartnerSProductRange = (Items.Pages.CurrentPage = Items.ThePartnerSNomenclaturePage);
	
	Items.CommandBarCreateProducts.Enabled = (Items.Pages.CurrentPage = Items.NomenclaturePage);
	Items.CommandBarCreateCharacteristic.Enabled = (Form.CharacteristicNavigation And Not Form.NavigationThroughThePartnerSProductRange);
		
	If Form.NavigationThroughThePartnerSProductRange Then
		WhenActivatingPartnerProductLine(Form, Items[SelectGoodsClientServer.NameOfListOfPartnerProductsForSearchOption(Form)]);
	ElsIf Form.CharacteristicNavigation Then
		WhenActivatingRowInCharacteristicsTable(Form, Items[SelectGoodsClientServer.NameOfListOfCharacteristicsBySearchOption(Form)]);
	Else
		WhenActivatingRowInProductTable(Form, Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form)]);
	EndIf;
	
EndProcedure

#EndRegion

#Region NavigatingPartnerProductHierarchy

// Called from the selection forms when the use filters for the supplier's item check box is changed.
//
// Parameters:
//	Form - ClientApplicationForm - the list form item or the form of selection.
//
Procedure WhenYouChangeUseOfPartnerProductFilters(Form) Export
	
	If Form.UseThePartnerItemFilter_3 Then
		SetSelectionByParentOfCurRowOfPartnerProductList(Form);
		SelectGoodsClientServer.SetSelectionByPartnerProductHierarchy(Form);
	Else
		SelectGoodsClientServer.DeletePartnerProductHierarchySelection(Form);
	EndIf;
	
	SelectGoodsClientServer.SetAvailabilityOfPartnerProductFilterElements(Form);
	
EndProcedure

// Called when a row in the table field of the item hierarchy is activated.
//
// Parameters:
//	Form - See SelectGoodsServer.WhenCreatingMatchingFormOnServer.Form
//
Procedure HandlerForActivatingLineInPartnerProductHierarchy(Form) Export
	
	If Form.CurrentPartnerItemHierarchy = Form.Items.TheHierarchyOfItemPartner.CurrentRow Then
		Return;
	EndIf;
	
	Form.CurrentPartnerItemHierarchy = Form.Items.TheHierarchyOfItemPartner.CurrentRow;
	
	SelectGoodsClientServer.SetSelectionByPartnerProductHierarchy(Form);
	
EndProcedure

#EndRegion

#Region WorkingWithPropertyTreeOfProductType

// The procedure is called when a "fixed" value is selected in the selection tree.
//
// Parameters:
// 	Form					 - ClientApplicationForm	 - the list form item or the form of selection.
// 	NotificationAfterProcessing - CallbackDescription - description of the notification after processing.
//
Procedure FilterTreeSelection(Form, NotificationAfterProcessing = Undefined) Export
	
	If Not Form.UseFilters Then
		If NotificationAfterProcessing <> Undefined Then
			RunCallback(NotificationAfterProcessing, False);
		EndIf;
	EndIf;
	
	ActionOption = OptionsForSelectingValueOfSelectionTree(Form);
	
	If ActionOption = 1 Then // clicked on a hyperlink with a "fixed" value
		SetFixedSelection(Form, NotificationAfterProcessing);
	EndIf;
	
EndProcedure

// Called before starting to change the property value in the selection tree by item type properties.
// 
// Parameters:
//	Form - ClientApplicationForm - item list form, selection form, selection form,
//	Cancel - Boolean - True - indicates that changes were rejected.
//
Procedure FilterTreeBeforeRowChange(Form, Cancel) Export
	
	If (Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByProperties")
		Or Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKindsAndProperties")
		Or Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKinds"))
		And Form.UseFilters
		And Form.CharacteristicNavigation 
		And Not Form.Items.FilterTree.CurrentData.FilterFeatures Then
		
		Cancel = True;
		
	EndIf; 
	
EndProcedure

// This procedure is called when the value in the selection tree changes based on
// 	the item type properties on list forms and selection forms.
//
// Parameters:
// 	Form - ClientApplicationForm - the list form item or the form of selection.
// 	NotificationAfterProcessing - CallbackDescription - description of the notification after processing.
//
Procedure FilterTreeFilterOnChange(Form, NotificationAfterProcessing = Undefined) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"CommonModule.SelectGoodsClient.FilterTreeFilterOnChange");
	
	If Not Form.UseFilters Then
		If NotificationAfterProcessing <> Undefined Then
			RunCallback(NotificationAfterProcessing, False);
		EndIf;
	EndIf;
	
	ActionOption = ActionOptionWhenChangingSelectionOfSelectionTree(Form);
	
	If ActionOption = 3 Then // check the box on the line with an empty "fixed" value
		SetFixedSelection(Form, NotificationAfterProcessing);
	Else
		RunCallback(NotificationAfterProcessing, True);
	EndIf;
	
EndProcedure

// The procedure is called after changing the value in the selection tree by
// 	item type properties on list forms and selection forms.
//
// Parameters:
// 	Form - ClientApplicationForm	 - the list form item or the form of selection.
//
Procedure SelectionTreeWhenStateChanges(Form) Export

	CurrentData = Form.Items.FilterTree.CurrentData;
	FilterParametersTable = Form.FilterParametersTable;
	
	If CurrentData.FixedValue
		Or TypeOf(CurrentData.FilterValue) = Type("Boolean") Then
		
		If CurrentData.Filter Then
			
			Filter = New Structure();
			Filter.Insert("AttributeName",CurrentData.AttributeName);
			PickedRows = FilterParametersTable.FindRows(Filter);
			If PickedRows.Count()>0 Then
				FillPropertyValues(PickedRows[0],CurrentData);
				PickedRows[0].AttributeName = CurrentData.AttributeName;
			Else
				NewRow = FilterParametersTable.Add();
				FillPropertyValues(NewRow,CurrentData);
				NewRow.AttributeName = CurrentData.AttributeName; 
			EndIf;
			
		Else
			
			Filter = New Structure();
			Filter.Insert("AttributeName",CurrentData.AttributeName);
			PickedRows = FilterParametersTable.FindRows(Filter);
			For Each RowForDeletion In PickedRows Do
				FilterParametersTable.Delete(RowForDeletion);
			EndDo;
		
		EndIf;
		
	Else
		
		Parent = CurrentData.GetParent();
		
		If Parent = Undefined Then // parent row selected
			
			SubordinateTreeItems = CurrentData.GetItems();
			
			If CurrentData.Filter Then
				For Each TreeItem In SubordinateTreeItems Do
					NewRow = FilterParametersTable.Add();
					FillPropertyValues(NewRow,TreeItem);
					NewRow.AttributeName = CurrentData.AttributeName;
				EndDo;
			Else
				Filter = New Structure();
				Filter.Insert("AttributeName",CurrentData.AttributeName);
				PickedRows = FilterParametersTable.FindRows(Filter);
				For Each RowForDeletion In PickedRows Do
					FilterParametersTable.Delete(RowForDeletion);
				EndDo;
			EndIf;
			
		Else
			
			If CurrentData.Filter Then
				NewRow = FilterParametersTable.Add();
				FillPropertyValues(NewRow,CurrentData);
			Else
				Filter = New Structure();
				Filter.Insert("AttributeName",CurrentData.AttributeName);
				Filter.Insert("Presentation",CurrentData.Presentation);
				PickedRows = FilterParametersTable.FindRows(Filter);
				For Each RowForDeletion In PickedRows Do
					FilterParametersTable.Delete(RowForDeletion);
				EndDo;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// The 10155915 platform has a jackdaw in the selection tree in the web client. In 8.3.8, it should be deleted.
	Form.RefreshDataRepresentation();
	
EndProcedure

#EndRegion

#Region SearchOnMatchingForms

// If a full-text search is used, the function checks whether the index is up-to-date.
// If the index is not up-to-date, a dialog is displayed asking you to update
// the full-text search index. If the user refuses to update the index,
// it is still allowed to perform an advanced search, because it is allowed that information
// about products often does not change.
//
// Parameters:
//	Form - ClientApplicationForm - the form from which the search function is called,
//	NotificationAfterVerification - CallbackDescription - description of the notification after checking whether
//		advanced search can be used.
//
Procedure PerformingAdvancedSearchIsPossible(Form, NotificationAfterVerification) Export
	
	// When the "Exact match search" checkbox is enabled, a non-full-text search is performed, 
	// accordingly, there is no need to check the relevance of the full-text search index.
	If Form.FindAnItemByExactMatch Then
		RunCallback(NotificationAfterVerification);
		Return;
	EndIf;
	
	// Verification is only necessary when using full-text search.
	If Not Form.UseFullTextSearch Then
		RunCallback(NotificationAfterVerification);
		Return;
	EndIf;
	
	If Form.FileInfobase And Not Form.FullTextSearchIndexIsUpToDate Then
		
		ShowQueryBox(
			New CallbackDescription(
				"PerformingAdvancedSearchIsPossibleCompletion",
				ThisObject,
				New Structure("NotificationAfterVerification, Form", NotificationAfterVerification, Form)),
			NStr("vi = 'Chưa kích hoạt chỉ mục tìm kiếm toàn văn. Cập nhật chỉ mục?';
				|ru = 'Индекс полнотекстового поиска неактуален. Обновить индекс?';
				|en = 'Full-text search index is invalid. Update the index?'; fa = 'Full-text search index is invalid. Update the index?';
				|it = 'L''indice di ricerca full-text è irrilevante. Aggiornare l''indice?';
				|pl = 'Indeks wyszukiwania pełnotekstowego jest nieaktualny. Zaktualizować indeks?';
				|tr = 'Tam metin arama endeksi güncel değil. Endeksi güncelle?'"),
			QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	RunCallback(NotificationAfterVerification);
	
EndProcedure

// The service procedure.
//
// Parameters:
// 	QuestionResult - DialogReturnCode
// 	AdditionalParameters - Structure of Arbitrary
//
Procedure PerformingAdvancedSearchIsPossibleCompletion(QuestionResult, AdditionalParameters) Export
	
	NotificationAfterVerification = AdditionalParameters.NotificationAfterVerification;
	Form = AdditionalParameters.Form;
	
	If QuestionResult = DialogReturnCode.Yes Then
		UpdateFullTextSearchIndex();
		Form.FullTextSearchIndexIsUpToDate = True;
	EndIf;
	
	RunCallback(NotificationAfterVerification);

EndProcedure

// Handles the return flag for the feature search function.
// If the search was not performed, a warning is displayed.
//
// Parameters:
//	Form - ClientApplicationForm - the form from which the product search function was called by line,
//	DisplayWarning - Boolean - flag for displaying a warning when the search fails.
//
Procedure AfterPerformingFeatureSearch(Form, DisplayWarning = True) Export
	
	SearchCompleted_ = Not Form.FailedToFindCharacteristics;
	ErrorCode = Form.SearchErrorCode;
	
	SearchString = Form.SearchBarCharacteristics;
	
	If ValueIsFilled(SearchString) Then
		If Not SearchCompleted_ And DisplayWarning Then
			ShowMessageBox(,AdvancedSearchErrorWarningText(ErrorCode), 120, "Search");
		EndIf;
		SelectionListsClientServer.UpdateSelectionList(Form.Items.SearchBarCharacteristics.ChoiceList, SearchString, 21);
	EndIf;
	
	// Set the current form element.
	CurrentItem = Form.Items[SelectGoodsClientServer.NameOfListOfCharacteristicsBySearchOption(Form)];
	If Not SearchCompleted_ Then
		CurrentItem = Form.Items.SearchBarCharacteristics;
	EndIf;
	
	Form.CurrentItem = CurrentItem;
	
EndProcedure

// Handles the return flag for the item search function.
// If the search was not performed, a warning is displayed.
//
// Parameters:
//	Form - ClientApplicationForm - the form from which the product search function was called by line,
//	DisplayWarning - Boolean - flag for displaying a warning when the search fails.
//
Procedure AfterSearchingForProducts(Form, DisplayWarning = True) Export
	
	SearchCompleted_ = Not Form.ProductsSearchReturnedNoResults;
	ErrorCode = Form.SearchErrorCode;
	
	SearchString = Form.SearchStringProducts;
	
	If ValueIsFilled(SearchString) Then
		If Not SearchCompleted_ And DisplayWarning And Not ErrorCode = "FoundNothing" Then
			ShowUserNotification(AdvancedSearchErrorWarningText(ErrorCode));
		EndIf;
		SelectionListsClientServer.UpdateSelectionList(Form.Items.SearchStringProducts.ChoiceList, SearchString, 21);
	EndIf;
	
	// Set the current form element.
	If Not SelectGoodsClientServer.ThisIsFormForSelectingProductsByCategory(Form.FormCode) Then
		CurrentItem = Form.Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form)];
	Else
		CurrentItem = Form.Items["ListAdvancedSearchProducts"];
	EndIf;
	
	If Not SearchCompleted_ Then
		CurrentItem = Form.Items.SearchStringProducts;
	EndIf;
	
	Form.CurrentItem = CurrentItem;
	
EndProcedure

// Handles the return flag for the item search function.
// If the search was not performed, a warning is displayed.
//
// Parameters:
//	Form - ClientApplicationForm - the form from which the product search function was called by line,
//	DisplayWarning - Boolean - flag for displaying a warning when the search fails.
//
Procedure AfterSearchingForPartnerProducts(Form, DisplayWarning = True) Export
	
	SearchCompleted_ = Not Form.TheSearchForThePartnerSNomenclatureIsNotSuccessful;
	ErrorCode = Form.SearchErrorCode;
	
	// Update the list of values to select from the search bar.
	SearchString = Form.SearchBarPartnerItem;
	
	If ValueIsFilled(SearchString) Then
		If Not SearchCompleted_ And DisplayWarning Then
			ShowMessageBox(,AdvancedSearchErrorWarningText(ErrorCode), 120, "Search");
		EndIf;
		SelectionListsClientServer.UpdateSelectionList(Form.Items.SearchBarPartnerItem.ChoiceList, SearchString, 21);
	EndIf;
	
	// Set the current form element.
	CurrentItem = Form.Items[SelectGoodsClientServer.NameOfListOfPartnerProductsForSearchOption(Form)];
	If Not SearchCompleted_ Then
		CurrentItem = Form.Items.SearchBarPartnerItem;
	EndIf;
	
	Form.CurrentItem = CurrentItem;
	
EndProcedure

// Calls the function for updating the full-text search index on the server.
//
Procedure UpdateFullTextSearchIndex() Export
	
	Status(NStr("vi = 'Đang cập nhật chỉ mục tìm kiếm toàn văn...';
				|ru = 'Идет обновление индекса полнотекстового поиска ...';
				|en = 'Updating full-text search index...'; fa = 'Updating full-text search index...';
				|it = 'Aggiornamento dell''indice di ricerca full-text in corso ...';
				|pl = 'Trwa aktualizacja indeksu wyszukiwania pełnotekstowego ...';
				|tr = 'Tam metin arama endeksi güncelleniyor ...'"));
	
	SelectGoodsServerCall.UpdateFullTextSearchIndex();
	
	Status(NStr("vi = 'Đã cập nhật chỉ mục tìm kiếm toàn văn.';
				|ru = 'Обновление индекса полнотекстового поиска завершено.';
				|en = 'Full-text search index update completed.'; fa = 'Full-text search index update completed.';
				|it = 'Aggiornamento dell''indice di ricerca full-text completato.';
				|pl = 'Aktualizacja indeksu wyszukiwania pełnotekstowego jest zakończona.';
				|tr = 'Tam metin arama endeksi güncellenmesi tamamlandı.'"));
	
EndProcedure

#EndRegion

#Region NavigationProcedures

// Sets The Cur Row of the item hierarchy in the item and selection list forms.
// 
// Parameters:
//	Form - See SelectGoodsServer.WhenCreatingMatchingFormOnServer.Form
//
Procedure SetCurRowOfProductHierarchy(Form) Export
	
	If Form.UseFilters
		And Not (Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByProperties")
		Or Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKindsAndProperties")
		Or Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByKinds") 
		Or Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByHierarchy")) Then
		Return;
	EndIf;
	
	ThisIsFormOfMatching = SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode);
	
	NameOfProductList = SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form);
	
	CurrentRow = Form.Items[NameOfProductList].CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(CurrentRow) = Type("DynamicListGroupRow") Then
		Return;
	EndIf;
	
	If ThisIsFormOfMatching And Form.CharacteristicNavigation Then
		Return;
	EndIf;
	
	CurrentData = Form.Items[NameOfProductList].CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Form.NavigationOption = PredefinedValue("Enum.ItemFormNavigationOptions.ByHierarchy") Then
		
		If Form.Items.ProductsHierarchy.CurrentRow = CurrentData.Parent Then
			Return;
		EndIf;
		
		Form.Items.ProductsHierarchy.CurrentRow = CurrentData.Parent;
		Form.CurrentProductsHierarchy = CurrentData.Parent;
	Else
		
		If Form.Items.ItemKinds.CurrentRow = CurrentData.ProductKind Then
			Return;
		EndIf;
		
		Form.Items.ItemKinds.CurrentRow = CurrentData.ProductKind;
		Form.ProductKind = CurrentData.ProductKind; 
		
	EndIf;
	
EndProcedure

// Sets the current page with the list of items.
// Used in the selection forms (in the sales and purchase document).
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure GoToListOfProducts(Form) Export
	
	ThisIsFormOfMatching = SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode);
	ThisIsProductListForm = SelectGoodsClientServer.ThisIsProductListForm(Form.FormCode);
	ThisIsFormOfProductSelection = SelectGoodsClientServer.ThisIsFormOfProductSelection(Form.FormCode);
	
	If Not ThisIsFormOfMatching Then
		If ThisIsProductListForm
			Or ThisIsFormOfProductSelection Then
			SelectGoodsClientServer.SetAvailabilityOfFilterElements(Form);
		EndIf;
		Return;
	EndIf;
	
	Form.CharacteristicNavigation = False;
	Form.Items.PagesOfLists.CurrentPage = Form.Items[SelectGoodsClientServer.CurPageNameBySearchOption(Form)];
	Form.Items.ProductSegment.ReadOnly = False;
	
	SelectGoodsClientServer.SetAvailabilityOfFilterElements(Form);
	
	If ValueIsFilled(Form.SearchStringProducts) Then
		Form.CurrentItem = Form.Items.SearchStringProducts;
	Else
		Form.CurrentItem = Form.Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form)];
	EndIf;
	
	Form.Items.PagesCreate.CurrentPage = Form.Items.PageCreateProducts;
	
	If Form.ShowBalance Then
		Form.AttachIdleHandler("TableSelectionWhenActivatingWaitHandlerLine", 0.1, True);
	EndIf;
	
EndProcedure

// The procedure is called after going to the list of characteristics.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form.
//
Procedure AfterGoingToListOfCharacteristics(Form) Export
	
	If Form.ShowBalance Then
		Form.AttachIdleHandler("TableSelectionWhenActivatingWaitHandlerLine", 0.1, True);
	EndIf;
	
EndProcedure

// This procedure is called when you change the navigation option for creating and displaying the menu.
//
// Parameters:
//	Form - ClientApplicationForm - list form, selection form.
//
Procedure ChangeNavigationOption(Form) Export
	
	SelectionListOfNavigationOptions = New ValueList;
	
	SelectionListOfNavigationOptions.Add(
		PredefinedValue("Enum.ItemFormNavigationOptions.ByKindsAndProperties"),
		NStr("vi = 'Điều hướng loại và tài sản';
			|ru = 'Навигация по видам и свойствам';
			|en = 'Filter by kinds and attributes'; fa = 'Filter by kinds and attributes';
			|it = 'Navigazione per tipi e proprietà';
			|pl = 'Nawigacja wg rodzajów i właściwości';
			|tr = 'Tür ve özelliklere göre gezinme'"));
	
	SelectionListOfNavigationOptions.Add(
		PredefinedValue("Enum.ItemFormNavigationOptions.ByHierarchy"),
		NStr("vi = 'Điều hướng phân cấp';
			|ru = 'Навигация по иерархии';
			|en = 'Filter by tree'; fa = 'Filter by tree';
			|it = 'Navigazione per gerarchia';
			|pl = 'Nawigacja wg hierarchii';
			|tr = 'Hiyerarşiye göre gezinme'"));
	
	//@skip-check notify-description-to-server-procedure
	//@skip-check bsl-legacy-check-string-literal
	CallbackDescription = New CallbackDescription("ChangeNavigationOptionCompletion", Form);
	
	Form.ShowChooseFromMenu(CallbackDescription,
		SelectionListOfNavigationOptions,
		Form.Items.CommandBarNavigationOption);
	
EndProcedure

#EndRegion

#Region OtherItems

// The procedure opens a form for viewing product prices. Used in the form of rebounds.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure ItemsPrices(Form) Export
	
	FormParameters = New Structure("Products, Characteristic, Date");
	
	RowOfProductTable = Form.Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form)].CurrentData;
		
	If Form.CharacteristicNavigation Then
		CharacteristicsTableRow = Form.Items[SelectGoodsClientServer.NameOfListOfCharacteristicsBySearchOption(Form)].CurrentData;
		
		If CharacteristicsTableRow = Undefined Then
			Return;
		EndIf;
		
		FormParameters.Characteristic = CharacteristicsTableRow.Characteristic;
		FormParameters.Products = CharacteristicsTableRow.Products;
		
	Else
		If RowOfProductTable = Undefined Then
			Return;
		EndIf;
		
		FormParameters.Products = RowOfProductTable.Products;
	EndIf;
	
	If SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode) Then
		
		FormParameters.Date = Form.Date;
		DataProcessorName = "SelectGoodsToPurchaseDocument";
		FormName = "ItemsPrices";
		
	ElsIf SelectGoodsClientServer.ThisIsFormOfMatchingInSalesDocuments(Form.FormCode) Then
		
		FormParameters.Date = Form.Date;
		DataProcessorName = "SelectGoodsToSalesDocument";
		If Form.UsePriceManagementSystem25 Then
			FormName = "ItemsPrices2_5";
			FormParameters.Insert("ObjectForStoringSalesTermsAndConditions", Form.ObjectForStoringSalesTermsAndConditions);
		Else
			FormName = "ItemsPrices";
		EndIf;
		
	EndIf;
	
	FormName = "DataProcessor." + DataProcessorName + ".Form." + FormName;
	
	OpenForm(FormName, FormParameters, Form, FormParameters.Products);
	
EndProcedure

// This procedure opens the item card form. Used in the form of rebounds.
//
// Parameters:
//	Form - ClientApplicationForm - selection form.
//
Procedure OpenGoodsProfile(Form) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"CommonModule.SelectGoodsClient.OpenGoodsProfile");
	
	SearchFormTable = Form.Items[SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form)]; // FormTable
	
	CurrentRow = SearchFormTable.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure("Key", CurrentRow);
	OpenForm("Catalog.Products.Form.ItemForm", FormParameters);
	
EndProcedure

// The procedure is called when you click on the information label-a line with information 
// about the number and amount of selected products on the selection forms.
//
// Parameters:
//	Form - ClientApplicationForm - selection form,
//	Object - FormDataStructure - the object of selection.
//
Procedure WhenYouClickOnInformationLabel(Form, Object) Export
	
	Form.ShowSelectedGoods = Not Form.ShowSelectedGoods;
	SelectGoodsClientServer.SetTextOfInformationLabel(Form);
	
EndProcedure

// Gets information about the product - the sale price and product balances.
// Used in the form of rebounds.
//
// Parameters:
//	Form - See DataProcessor.SelectGoodsToSalesDocument.Form.Form
//
Procedure GetProductInformationWhenSelling(Form) Export
	
	If Not Form.ShowBalance Then
		Return;
	EndIf;
	
	StockInWarehouses = Form.StockBalance.GetItems();
	StockInWarehouses.Clear();
	
	If Form.SelectionModeWithoutAmountParameters And Not Form.ShowBalance Then
		Return;
	EndIf;
	
	ItemVariantsAreUsed = Form.CurrentLineOfProducts.ItemVariantsAreUsed;
	ThisIsAProduct = Form.CurrentLineOfProducts.ThisIsAProduct;
	
	If Not ThisIsAProduct 
			Or (Form.CharacteristicNavigation And 
			Not ValueIsFilled(Form.CurrentCharacteristicLine.Characteristic))Then
		Return;
	EndIf;
	
	Currency = Form.Currency;
	Terms = Form.Terms;
	
	ParametersForGettingPriceAndBalances = SelectGoodsClientServer.NewParametersForGettingPriceAndBalanceOfGoods();
	ParametersForGettingPriceAndBalances.Products = Form.CurrentLineOfProducts.Products;
	ParametersForGettingPriceAndBalances.Terms = Terms;
	ParametersForGettingPriceAndBalances.Currency = Currency;
	ParametersForGettingPriceAndBalances.Warehouses = Form.Warehouses;
	ParametersForGettingPriceAndBalances.TypesOfPrices = Form.TypesOfPrices;
	ParametersForGettingPriceAndBalances.ControlledLotReference = Form.ControlledLotReference;
	ParametersForGettingPriceAndBalances.GetBalance = Form.ShowBalance;
	ParametersForGettingPriceAndBalances.GetPrice = Not Form.SelectionModeWithoutAmountParameters;
	
	If Form.CharacteristicNavigation Then
		
		If ValueIsFilled(Form.CurrentCharacteristicLine.Characteristic) Then
			ParametersForGettingPriceAndBalances.Characteristic = Form.CurrentCharacteristicLine.Characteristic;
		Else
			Return;
		EndIf;
		
	Else
		ParametersForGettingPriceAndBalances.Characteristic = Undefined;
	EndIf;
	
	GoodsInformation = SelectGoodsServerCall.SalePriceAndProductBalances(ParametersForGettingPriceAndBalances);
	
	SalePriceOfGoods = GoodsInformation.Price;
	
	PackageNameUnitsOfMeasurement = ?(ValueIsFilled(SalePriceOfGoods.Package), 
		String(SalePriceOfGoods.Package), 
		String(SalePriceOfGoods.UnitOfMeasure));
	
	For Each TBLString In GoodsInformation.CurrentItemsBalance Do
		
		InventoryBalancesLine = StockInWarehouses.Add();
		
		InventoryBalancesLine.Period = Form.CurrentSessionDate;
		InventoryBalancesLine.PeriodDescription = NStr("vi = 'Hiện tại';
														|ru = 'Сейчас';
														|en = 'Now'; fa = 'اکنون';
														|it = 'Adesso';
														|pl = 'Now';
														|tr = 'Şimdi'");
		InventoryBalancesLine.Available = TBLString.AvailableForInventoryAllocation;
		InventoryBalancesLine.Inventory = TBLString.Inventory;
		
		InventoryBalancesLine.StockDescription = DescriptionOfQuantityInBalanceLine(
			InventoryBalancesLine.Inventory,
			PackageNameUnitsOfMeasurement,
			ItemVariantsAreUsed,
			Form.CharacteristicNavigation);
		
		InventoryBalancesLine.DescriptionAvailable = DescriptionOfQuantityInBalanceLine(
			InventoryBalancesLine.Available,
			PackageNameUnitsOfMeasurement,
			ItemVariantsAreUsed,
			Form.CharacteristicNavigation);
		
		InventoryBalancesLine.Warehouse = TBLString.Warehouse;
		InventoryBalancesLine.WarehouseDescription = String(TBLString.Warehouse);
		InventoryBalancesLine.WarehouseIsAvailableForSelection = WarehouseIsAvailableForSelection(Form, InventoryBalancesLine.Warehouse);
		
		PlannedBalancesByDate = InventoryBalancesLine.GetItems();
			
		ThereArePlannedRemnants = False;
		For Each TBLString In GoodsInformation.PlannedBalances_ Do
			
			If Not (TBLString.Warehouse = InventoryBalancesLine.Warehouse) Then
				Continue;
			EndIf;
			
			ThereArePlannedRemnants = True;
			
			LinePlannedBalancesByDate = PlannedBalancesByDate.Add();
			
			LinePlannedBalancesByDate.Period = TBLString.Period;
			LinePlannedBalancesByDate.PeriodDescription = Format(TBLString.Period, "DLF=D");
			LinePlannedBalancesByDate.Available = TBLString.Available;
			LinePlannedBalancesByDate.Inventory = TBLString.Inventory;
			
			LinePlannedBalancesByDate.StockDescription = DescriptionOfQuantityInBalanceLine(
				LinePlannedBalancesByDate.Inventory,
				PackageNameUnitsOfMeasurement,
				ItemVariantsAreUsed,
				Form.CharacteristicNavigation);
			
			LinePlannedBalancesByDate.DescriptionAvailable = DescriptionOfQuantityInBalanceLine(
				LinePlannedBalancesByDate.Available,
				PackageNameUnitsOfMeasurement,
				ItemVariantsAreUsed,
				Form.CharacteristicNavigation);
			
			LinePlannedBalancesByDate.Warehouse = TBLString.Warehouse;
			LinePlannedBalancesByDate.WarehouseDescription = "";
			LinePlannedBalancesByDate.WarehouseIsAvailableForSelection = WarehouseIsAvailableForSelection(Form, LinePlannedBalancesByDate.Warehouse);
			
		EndDo;
		
		If InventoryBalancesLine.Inventory = 0 And Not ThereArePlannedRemnants Then
			StockInWarehouses.Delete(InventoryBalancesLine);
		EndIf;
		
	EndDo;
	
EndProcedure

// Gets information about the product - the purchase price and product balances.
//
// Parameters:
//	Form - See SelectGoodsServer.WhenCreatingMatchingFormOnServer.Form
//
Procedure GetProductInformationWhenPurchasing(Form) Export
	
	If Not Form.ShowBalance Then
		Return;
	EndIf;
	
	StockInWarehouses = Form.StockBalance.GetItems();
	StockInWarehouses.Clear();
	
	SupplierSWarehouseBalances = Form.SupplierStockBalance.GetItems();
	SupplierSWarehouseBalances.Clear();
	
	If Form.SelectionModeWithoutAmountParameters And Not Form.ShowBalance Then
		Return;
	EndIf;
	
	ItemVariantsAreUsed = Form.CurrentLineOfProducts.ItemVariantsAreUsed;
	ThisIsAProduct = Form.CurrentLineOfProducts.ThisIsAProduct;
	
	If ThisIsAProduct <> True Then
		Return;
	EndIf;
	
	If Form.NavigationThroughThePartnerSProductRange Then
		
		RowInPartnerProductTable = Form.Items[SelectGoodsClientServer.NameOfListOfPartnerProductsForSearchOption(Form)].CurrentData;
		If RowInPartnerProductTable = Undefined Then
			Return;
		EndIf;
		
		Products = RowInPartnerProductTable.Products;
		If ItemVariantsAreUsed Then
			Characteristic = RowInPartnerProductTable.Characteristic;
		EndIf;
		
		SetCurRowOfPartnerProductHierarchy(Form);
	Else
		Products = Form.CurrentLineOfProducts.Products;
		Characteristic = Form.CurrentCharacteristicLine.Characteristic;
	EndIf;
		
	If Not Form.CharacteristicNavigation Then
		Characteristic = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
	EndIf;
	
	ParametersForGettingPriceAndBalances = SelectGoodsClientServer.NewParametersForGettingPriceAndBalanceOfGoods();
	ParametersForGettingPriceAndBalances.Products = Products;
	ParametersForGettingPriceAndBalances.Characteristic = Characteristic;
	ParametersForGettingPriceAndBalances.Terms = Form.Terms;
	ParametersForGettingPriceAndBalances.Currency = Form.Currency;
	ParametersForGettingPriceAndBalances.Warehouses = Form.Warehouses;
	ParametersForGettingPriceAndBalances.GetBalance = Form.ShowBalance;
	ParametersForGettingPriceAndBalances.GetPrice = Not Form.SelectionModeWithoutAmountParameters;
	
	GoodsInformation = SelectGoodsServerCall.PurchasePriceAndProductBalances(ParametersForGettingPriceAndBalances);
	
	StructurePrice = GoodsInformation.Price;
	
	PackageNameUnitsOfMeasurement = ?(ValueIsFilled(StructurePrice.Package), 
		String(StructurePrice.Package), 
		String(StructurePrice.UnitOfMeasure));
	
	For Each LineCurBalances In GoodsInformation.CurrentItemsBalance Do
		
		InventoryBalancesLine = StockInWarehouses.Add();
		
		InventoryBalancesLine.Period = Form.CurrentSessionDate;
		InventoryBalancesLine.PeriodDescription = NStr("vi = 'Hiện tại';
														|ru = 'Сейчас';
														|en = 'Now'; fa = 'اکنون';
														|it = 'Adesso';
														|pl = 'Now';
														|tr = 'Şimdi'");
		
		InventoryBalancesLine.Available = LineCurBalances.AvailableForInventoryAllocation;
		InventoryBalancesLine.Inventory = LineCurBalances.Inventory;
		
		InventoryBalancesLine.StockDescription = DescriptionOfQuantityInBalanceLine(
			InventoryBalancesLine.Inventory,
			PackageNameUnitsOfMeasurement,
			ItemVariantsAreUsed,
			Form.CharacteristicNavigation Or Form.NavigationThroughThePartnerSProductRange);
		
		InventoryBalancesLine.DescriptionAvailable = DescriptionOfQuantityInBalanceLine(
			InventoryBalancesLine.Available,
			PackageNameUnitsOfMeasurement,
			ItemVariantsAreUsed,
			Form.CharacteristicNavigation Or Form.NavigationThroughThePartnerSProductRange);
		
		InventoryBalancesLine.Warehouse = LineCurBalances.Warehouse;
		InventoryBalancesLine.WarehouseDescription = String(LineCurBalances.Warehouse);
		InventoryBalancesLine.WarehouseIsAvailableForSelection = WarehouseIsAvailableForSelection(Form, InventoryBalancesLine.Warehouse);
		
		SupplierInventoryBalancesLine = SupplierSWarehouseBalances.Add();
		FillPropertyValues(SupplierInventoryBalancesLine, InventoryBalancesLine);
		
		PlannedBalancesByDate = InventoryBalancesLine.GetItems();
		PlannedBalancesBySupplierDates = SupplierInventoryBalancesLine.GetItems();
		
		// Display the planned balances according to the schedule of goods movements.
		ThereArePlannedRemnants = False;
		For Each LinePlannedBalances In GoodsInformation.PlannedBalances_ Do
			
			If Not (LinePlannedBalances.Warehouse = InventoryBalancesLine.Warehouse) Then
				Continue;
			EndIf;
			
			ThereArePlannedRemnants = True;
			
			// ... to the table of planned balances by dates.
			LinePlannedBalancesByDate = PlannedBalancesByDate.Add();
			
			LinePlannedBalancesByDate.Period = LinePlannedBalances.Period;
			LinePlannedBalancesByDate.PeriodDescription = Format(LinePlannedBalances.Period, "DLF=D");
			
			LinePlannedBalancesByDate.Available = LinePlannedBalances.Available;
			LinePlannedBalancesByDate.Inventory = LinePlannedBalances.Inventory;
			
			LinePlannedBalancesByDate.StockDescription = DescriptionOfQuantityInBalanceLine(
				LinePlannedBalancesByDate.Inventory,
				PackageNameUnitsOfMeasurement,
				ItemVariantsAreUsed,
				Form.CharacteristicNavigation);
			
			LinePlannedBalancesByDate.DescriptionAvailable = DescriptionOfQuantityInBalanceLine(
				LinePlannedBalancesByDate.Available,
				PackageNameUnitsOfMeasurement,
				ItemVariantsAreUsed,
				Form.CharacteristicNavigation);
			
			LinePlannedBalancesByDate.Warehouse = LinePlannedBalances.Warehouse;
			LinePlannedBalancesByDate.WarehouseDescription = "";
			LinePlannedBalancesByDate.WarehouseIsAvailableForSelection = WarehouseIsAvailableForSelection(Form, LinePlannedBalancesByDate.Warehouse);
			
			// ... to the table of planned supplier balances by date.
			LinePlannedSupplierBalancesByDate = PlannedBalancesBySupplierDates.Add();
			FillPropertyValues(LinePlannedSupplierBalancesByDate, LinePlannedBalancesByDate);
			
		EndDo;
		
		If InventoryBalancesLine.Inventory = 0 And Not ThereArePlannedRemnants Then
			StockInWarehouses.Delete(InventoryBalancesLine);
			SupplierSWarehouseBalances.Delete(SupplierInventoryBalancesLine);
		EndIf;
		
	EndDo;
	
EndProcedure

// Opens the search settings form - advanced or platform.
//
// Parameters:
//	Form - ClientApplicationForm - form the list form of selection.
//
Procedure ConfigureSearch(Form) Export
	
	OpenForm("Catalog.Products.Form.CustomizeSearchOption", 
		New Structure("GoodsSearchOption", Form.GoodsSearchOption),,,,,
		New CallbackDescription("ConfigureSearchCompletion",
			ThisObject,
			New Structure("Form", Form)), FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

// The service procedure.
//
// Parameters:
// 	Result - Arbitrary
// 	AdditionalParameters - Structure of Arbitrary
//
Procedure ConfigureSearchCompletion(Result, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	
	ParametersStructure = Result;
	If ParametersStructure <> Undefined Then
		
		If Form.GoodsSearchOption <> ParametersStructure.GoodsSearchOption Then
			
			Form.GoodsSearchOption = ParametersStructure.GoodsSearchOption;
			SelectGoodsClientServer.SetCurPagesBySearchOption(Form);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Determines whether the changed selection settings should be saved to the settings store
//
// Parameters:
//	Form - See SelectGoodsServer.WhenCreatingMatchingFormOnServer.Form
//
// Returns:
//	Boolean - Indicates whether the settings need to be saved.
//
Function SavingSettingsIsRequired(Form) Export
	
	If Form.FormSettingsWhenOpening.SavingIsRequired = True Then
		Return True;
	Else
		CurrentSetings = CommonClient.CopyRecursive(Form.FormSettingsWhenOpening);
		FillPropertyValues(CurrentSetings, Form);
		For Each Setting In CurrentSetings Do
			If Setting.Value <> CommonClientServer.StructureProperty(
												Form.FormSettingsWhenOpening, Setting.Key) Then
				Return True;
			EndIf;
		EndDo;
	EndIf;
	
	Return False;
	
EndFunction

// Returns the result of checking whether the selected lines in the Item list contain links to Catalog items.
//
// Parameters:
//	Form - ClientApplicationForm - a form containing the Item list.
//
// Returns:
//	Boolean - True if the selected lines contain links to items in the Item Catalog.
//
Function ThereAreSelectedLinesInListOfItems(Form) Export
	
	ListName			= SelectGoodsClientServer.NameOfListOfProductsBySearchOption(Form);
	ItemList	= Form.Items[ListName];
	SelectedRows	= TMCommonUseClient.CheckGetLinksHighlightedInList(ItemList);
	
	ThereAreHighlightedLines = SelectedRows.Count() > 0;
	
	Return ThereAreHighlightedLines;
	
EndFunction

#EndRegion

#Region DragAndDropOnSelectionForms

// The function generates drag-and-drop parameters from the lists of items, supplier items, and item characteristics.
//
// Parameters:
// 	Form - ClientApplicationForm - selection form,
// 	Item - FormItems - the form element that the action is performed on,
// 	DragParameters - DragParameters - parameters for dragging a form element.
//
Procedure GetDragAndDropData(Form, Item, DragParameters) Export
	
	ParametersArray = New Array; 
	
	FeaturesPage = False;
	If SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode) Then
		If Form.CharacteristicNavigation And Not Form.NavigationThroughThePartnerSProductRange Then
			FeaturesPage = True;
		EndIf;
	Else
		If Form.CharacteristicNavigation Then
			FeaturesPage = True;
		EndIf; 
	EndIf;
		
	For Each RowKey In DragParameters.Value Do
		
		RowData = Item.RowData(RowKey);
		
		If RowData = Undefined Then
			Continue;
		EndIf;
		
		ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
		If SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode) Then
			ProductParameters_1.Insert("VendorPriceKind", Form.VendorPriceKind);
		EndIf;
		
		FillPropertyValues(ProductParameters_1, RowData);
		
		If SelectGoodsClientServer.ThisIsFormOfMatchingInSalesDocuments(Form.FormCode)
			And Not ValueIsFilled(ProductParameters_1.PriceKind) Then
				
			If ValueIsFilled(Form.PriceKind) Then
				PriceTypeForSubstitution = Form.PriceKind;
			ElsIf Form.TypesOfPrices.Count() = 1 Then
				PriceTypeForSubstitution = Form.TypesOfPrices.Get(0).Value;
			Else
				PriceTypeForSubstitution = PredefinedValue("Catalog.TypesOfPrices.EmptyRef");
			EndIf;
			
			ProductParameters_1.PriceKind = PriceTypeForSubstitution;
			
		EndIf;
		
		If FeaturesPage Then
			ThisIsAProduct = Form.CurrentLineOfProducts.ThisIsAProduct;
			If ThisIsAProduct Then
				ProductParameters_1.SKU = Form.CurrentLineOfProducts.SKU;
			EndIf;
		Else 
			ThisIsAProduct = RowData.ThisIsAProduct;
		EndIf;
		
		If ThisIsAProduct And Form.Warehouses.Count() = 1 Then
			ProductParameters_1.Warehouse = Form.Warehouses.Get(0).Value;
		EndIf;
		
		ProductParameters_1.NumberOfPackages = 1;
		ProductParameters_1.ItemVariantsAreUsed = RowData.ItemVariantsAreUsed;
		
		ParametersArray.Add(ProductParameters_1);
		
	EndDo;
	
	DragParameters.Value = ParametersArray;
	
EndProcedure

// The function generates drag and drop parameters from the table part of the remainder
//
// Parameters:
//	Form - ClientApplicationForm - selection form,
//	Item - FormItems - the form element that the action is performed on,
//	DragParameters - DragParameters - parameters for dragging a form element.
//
Procedure GetDragAndDropDataForLeftovers(Form, Item, DragParameters) Export
	
	ParametersArray = New Array; 
	
	CurLineBase = Form.CurrentLineOfProducts;
	
	If Form.CharacteristicNavigation Then
		CurLineBase = Form.CurrentCharacteristicLine;
	ElsIf SelectGoodsClientServer.ThisIsFormOfSelectionInPurchaseDocuments(Form.FormCode) Then
		If Form.NavigationThroughThePartnerSProductRange Then
			CurLineBase = Form.TheCurrentLineOfThePartnerSItem;
		EndIf;
	EndIf;
	
	For Each RowKey In DragParameters.Value Do
		
		RowData = Item.RowData(RowKey);
		
		ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
		ProductParameters_1.Insert("PartnerProducts");
		
		FillPropertyValues(ProductParameters_1, CurLineBase);
		FillPropertyValues(ProductParameters_1, RowData);
		
		ProductParameters_1.NumberOfPackages = 1;
		
		ParametersArray.Add(ProductParameters_1);
		
	EndDo;
	
	DragParameters.Value = ParametersArray;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region WorkingWithPropertyTreeOfProductType

// Returns an indication of whether it is necessary to set the selection of a dynamic list of items
// 	on the selection Forms, based on the values of the selection tree. Called when you click on the selection field
// 	a fixed value in the row of the selection tree.
// 	Returns in the notification: True - the value in the selection tree has been changed and you need to apply the selection value
// 	to the item list, or False - the selection value has not been changed.
//
// Parameters:
// 	Form - ClientApplicationForm - the list form or form of selection.
// 	NotificationAfterProcessing - CallbackDescription - description of the notification after processing.
//
Procedure SetFixedSelection(Form, NotificationAfterProcessing = Undefined)
	
	CurrentData = Form.Items.FilterTree.CurrentData;
	
	If SelectGoodsClientServer.ThisIsFormOfMatching(Form.FormCode)
		And Form.CharacteristicNavigation
		And CurrentData.Property("FilterFeatures")
		And Not CurrentData.FilterFeatures Then
		
		Return;
		
	EndIf;
	
	If Not CurrentData.FixedValue Then
		If NotificationAfterProcessing <> Undefined Then
			RunCallback(NotificationAfterProcessing, False);
		EndIf;
	EndIf;
	
	ProductKind		= Form.ProductKind;
	ValueTypeFilter	= TypeOf(CurrentData.FilterValue);
	AttributeName		= ?(CurrentData.IsAddlAttribute,
							CurrentData.Presentation,
							CurrentData.AttributeName);
	
	If ValueTypeFilter = Type("ValueList") Then
		
		// The value type is a string. In this case, the value setting form opens and the selection list
		// of the value selection field is filled with the available values.
		RemainingGoodsByShelfLives = True;
		
		If CurrentData.Property("FilterFeatures") Then
			RemainingGoodsByShelfLives = Not CurrentData.FilterFeatures;
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("AttributeName",			AttributeName);
		FormParameters.Insert("FilterValue",		CurrentData.FilterValue);
		FormParameters.Insert("IsAddlAttribute",		CurrentData.IsAddlAttribute);
		FormParameters.Insert("FilterRemainingGoodsByShelfLives",	RemainingGoodsByShelfLives);
		FormParameters.Insert("ProductKind",		ProductKind);
		
	ElsIf ValueTypeFilter = Type("String") Then
		
		// The value type is a string. In this case, the value setting form opens and the selection list
		// of the value selection field is filled with the available values.
		RemainingGoodsByShelfLives = True;
		
		If CurrentData.Property("FilterFeatures") Then
			RemainingGoodsByShelfLives = Not CurrentData.FilterFeatures;
		EndIf;
		
		ListOfPropsValues = SelectGoodsServerCall.ListOfPropsValues(
									ProductKind,
									AttributeName,
									CurrentData.IsAddlAttribute,
									RemainingGoodsByShelfLives);
			
		FormParameters = New Structure;
		FormParameters.Insert("AttributeName",			AttributeName);
		FormParameters.Insert("ListOfSelectionLines",	ListOfPropsValues);
		FormParameters.Insert("FilterValue",		CurrentData.FilterValue);
		FormParameters.Insert("ValueType",			ValueTypeFilter);
		
	Else
		
		// The value type is a number or a date, in this case the interval setting form opens.
		FormParameters = New Structure;
		FormParameters.Insert("AttributeName",	AttributeName);
		FormParameters.Insert("ValueFrom_2",	CurrentData.IntervalFrom);
		FormParameters.Insert("ValueUpTo",	CurrentData.IntervalTo);
		FormParameters.Insert("ValueType",	TypeOf(CurrentData.FilterValue));
		
	EndIf;
	
	FormName				= ?(ValueTypeFilter = Type("ValueList"),
								"Catalog.Products.Form.FilterValueSettingForm",
								"Catalog.Products.Form.IntervalSettingForm");
	AdditionalParameters	= New Structure("NotificationAfterProcessing, CurrentData",
												NotificationAfterProcessing, CurrentData);
	CallbackDescription		= New CallbackDescription("SetFixedSelectionCompletion",
														ThisObject,
														AdditionalParameters);
	
	OpenForm(FormName, FormParameters, Form, , , , CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

// The service procedure.
//
// Parameters:
// 	SelectionValue - DialogReturnCode
// 	AdditionalParameters - Structure of Arbitrary
//
Procedure SetFixedSelectionCompletion(SelectionValue, AdditionalParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"CommonModule.SelectGoodsClient.SetFixedSelectionCompletion");
	
	NotificationAfterProcessing = AdditionalParameters.NotificationAfterProcessing;
	CurrentData = AdditionalParameters.CurrentData;
	ValueTypeFilter = TypeOf(CurrentData.FilterValue);
	
	SetListSelection = False;
	
	If SelectionValue = Undefined Then
		
		CurrentData.Filter =
			?(ValueTypeFilter = Type("String") Or ValueTypeFilter = Type("ValueList"),
				ValueIsFilled(CurrentData.FilterValue),
				ValueIsFilled(CurrentData.IntervalFrom)
					Or ValueIsFilled(CurrentData.IntervalTo));
		
		CurrentData.FilterIs_Specified = CurrentData.Filter;
		
		RunCallback(NotificationAfterProcessing, SetListSelection);
		Return;
		
	EndIf;
	
	If ValueTypeFilter = Type("String")
		Or ValueTypeFilter = Type("ValueList") Then
		
		If SelectionValue <> Undefined Then
			
			FilterValue = SelectionValue.FilterValue;
			
			CurrentData.Filter = ValueIsFilled(FilterValue);
			CurrentData.FilterIs_Specified = CurrentData.Filter;
			CurrentData.FilterValue = FilterValue;
			CurrentData.FilterPresentation =
				?(ValueIsFilled(FilterValue),
					FilterValue,
					NStr("vi = '<chưa đặt>';
						|ru = '<не задано>';
						|en = '<not set>'; fa = '<تنظیم نشده>';
						|it = '<non indicato>';
						|pl = '<nie określono>';
						|tr = '<belirtilmedi>'"));
			
			SetListSelection = True;
			
		EndIf;
		
	Else
		
		If SelectionValue <> Undefined Then
			
			If SelectionValue.IntervalFrom <> CurrentData.IntervalFrom 
				Or SelectionValue.IntervalTo <> CurrentData.IntervalTo Then
				
				CurrentData.IntervalFrom = SelectionValue.IntervalFrom;
				CurrentData.IntervalTo = SelectionValue.IntervalTo;
				CurrentData.FilterPresentation = PresentationOfSelectionInterval(
					SelectionValue.IntervalFrom,
					SelectionValue.IntervalTo);
				
				SetListSelection = True;
				
			EndIf;
			
			CurrentData.Filter = ValueIsFilled(SelectionValue.IntervalFrom)
				Or ValueIsFilled(SelectionValue.IntervalTo);
			
		EndIf;
		
	EndIf;
	
	If NotificationAfterProcessing <> Undefined Then
		RunCallback(NotificationAfterProcessing, SetListSelection);
	EndIf;
	
EndProcedure

// Returns a string representation of the selection interval.
//
// Parameters:
//	IntervalFrom - Number, String, Date - initial value of the interval,
//	IntervalTo - Number, String, Date - the final value of the interval.
//
// Returns:
//	String - representation of the interval.
//
Function PresentationOfSelectionInterval(IntervalFrom, IntervalTo)
	
	If Not ValueIsFilled(IntervalFrom)
		And Not ValueIsFilled(IntervalTo) Then
		FilterPresentation = NStr("vi = '<chưa đặt>';
									|ru = '<не задано>';
									|en = '<not set>'; fa = '<تنظیم نشده>';
									|it = '<non indicato>';
									|pl = '<nie określono>';
									|tr = '<belirtilmedi>'");
		Return FilterPresentation;
	ElsIf ValueIsFilled(IntervalFrom)
		And ValueIsFilled(IntervalTo) Then
		FilterPresentation = NStr("vi = 'từ %IntervalFrom% đến %IntervalTo%';
									|ru = 'от %IntervalFrom% до %IntervalTo%';
									|en = 'from %IntervalFrom% to %IntervalTo%'; fa = 'from %IntervalFrom% to %IntervalTo%';
									|it = 'dal %IntervalFrom% al %IntervalTo%';
									|pl = 'od %IntervalFrom% do %IntervalTo%';
									|tr = '%IntervalFrom% itibaren %IntervalTo% kadar'");
	ElsIf ValueIsFilled(IntervalFrom) Then 
		FilterPresentation = NStr("vi = 'từ %IntervalFrom%';
									|ru = 'от %IntervalFrom%';
									|en = 'from %IntervalFrom%'; fa = 'from %IntervalFrom%';
									|it = 'dal %IntervalFrom%';
									|pl = 'od %IntervalFrom%';
									|tr = '%IntervalFrom% itibaren'");
	Else
		FilterPresentation = NStr("vi = 'lên đến %IntervalTo%';
									|ru = 'до %IntervalTo%';
									|en = 'until %IntervalTo%'; fa = 'until %IntervalTo%';
									|it = 'al %IntervalTo%';
									|pl = 'do %IntervalTo%';
									|tr = '%IntervalTo% kadar'");
	EndIf;
	
	FilterPresentation = StrReplace(FilterPresentation, "%IntervalFrom%", IntervalFrom);	
	FilterPresentation = StrReplace(FilterPresentation, "%IntervalTo%", IntervalTo);	
	
	Return FilterPresentation;
	
EndFunction

// Returns a number - the code of the action option that was performed with the selection tree.
//
// Parameters:
//	Form - ClientApplicationForm - the list form of the nomenclature reference list or the selection form.
//
// Returns:
//	Number - .
//	0 - there was no change in the values in the selection tree;
//	1 - has been installed/unchecked the checkbox for the row (or parent row) of values, for example:
//		, it was set/unchecked the "New" quality line or the "Quality" line;
//	2 - has been installed/the checkbox on the "fixed value" line has been unchecked, and the fixed
//		value has already been specified, for example: a specific value of the cable diameter was specified in the selection tree line
//		and the checkbox was checked/unchecked;
//	3 - a check mark was set on the line with a "fixed value", and the fixed value
//		in the line has not yet been specified, for example: a specific value
//		of the cable diameter was not specified in the line of the selection tree and a check mark was set for the line. This option leads to the fact that an
//		additional form of setting values (or interval) of a fixed value opens.
//
Function ActionOptionWhenChangingSelectionOfSelectionTree(Form)
	
	ActionOption = 0;
	
	CurrentData = Form.Items.FilterTree.CurrentData;
	
	If CurrentData.FixedValue Then
		
		// A fixed value - for example, an article is entered, or
		// some specific numeric, string value, or date interval is specified.
		
		ActionOption = 2; // checked/unchecked the fixed value field
		
		If CurrentData.Filter Then
			
			ValueTypeFilter = TypeOf(CurrentData.FilterValue);
			
			If Not (ValueTypeFilter = Type("String")
					And ValueIsFilled(CurrentData.FilterValue)
				Or ValueTypeFilter <> Type("String")
					And (ValueIsFilled(CurrentData.IntervalFrom)
						Or ValueIsFilled(CurrentData.IntervalTo))) Then
				
				ActionOption = 3; // CHECK the box on a fixed value field that is not filled with a value
				
			EndIf;
			
		EndIf;
		
	Else
		
		ActionOption = 1; // set/uncheck the box on the line of a specific value or group of values
		
		Parent = CurrentData.GetParent();
		
		If Parent = Undefined Then // parent row selected
			
			// Set/uncheck the selection checkbox for all subordinate rows.
			
			SubordinateTreeItems = CurrentData.GetItems();
			
			For Each TreeItem In SubordinateTreeItems Do
				TreeItem.Filter = CurrentData.Filter;
			EndDo;
			
		Else
			
			// The subordinate line is selected.
			
			Parent.Filter = False;
			
			SubordinateTreeItems = Parent.GetItems();
			
			// Go through all the subordinate rows of the parent of the selected row, and if
			// at least one row has a selection checkbox, then enable the selection checkbox
			// of the parent row as well.
			
			For Each TreeItem In SubordinateTreeItems Do
				
				If TreeItem.Filter Then
					Parent.Filter = True;
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return ActionOption;
	
EndFunction

// Returns a number-the code of the action option that was performed with the selection tree
// when the value selection event occurred in the selection tree.
//
// Parameters:
//	Form - ClientApplicationForm - the list form of the nomenclature reference list or the selection form.
//
// Returns:
//	Number - .
//	0 - there was no change in the values in the selection tree,
//	1 - a value was selected in a row with a "fixed" value,
//	in this case it is necessary to open the "fixed" value setting form.
//
Function OptionsForSelectingValueOfSelectionTree(Form)
	
	FilterTree = Form.Items.FilterTree;
	CurrentItem = Form.Items.FilterTree.CurrentItem;
	CurrentRow = Form.Items.FilterTree.CurrentRow;
	CurrentData = Form.Items.FilterTree.CurrentData;
	
	ActionOption = 0;
	
	If CurrentItem = Form.Items.FilterTreeFilterPresentation Then
		
		If CurrentData.FixedValue Then
			
			ActionOption = 1;
			
		EndIf;
		
	ElsIf CurrentItem = Form.Items.FilterTreePresentation Then
		
		If CurrentData.FixedValue Then
			
			ActionOption = 1;
			
		ElsIf Not CurrentData.FilterAvailable Then
			
			// If there was a click on the parent row, then collapse/expand the node.
			
			If FilterTree.Expanded(CurrentRow) Then
				FilterTree.Collapse(CurrentRow);
			Else
				FilterTree.Expand(CurrentRow);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return ActionOption;
	
EndFunction

// Returns whether the warehouse is available for selection.
//
// Parameters:
// 	Form - ClientApplicationForm - Product Selection Form
// 	Warehouse - CatalogRef.Warehouses
//
// Returns:
// 	Boolean
//
Function WarehouseIsAvailableForSelection(Form, Warehouse)

	Return Form.Warehouses.FindByValue(Warehouse) <> Undefined;

EndFunction

// Returns a string description of the quantity. Used when displaying
// rows in the Balance table in the Forms of product selection in the sales document
// , purchase document.
//
// Parameters:
// 	Count - Number - quantity of goods
// 	PackageNameUnitsOfMeasurement - String - package name, units of measurement
// 	ItemVariantsAreUsed - Boolean - a sign of keeping records of the characteristics of the goods
// 	CharacteristicNavigation - Boolean - whether to navigate by characteristics on the selection Form
//
// Returns:
// 	String - Description of the number of goods for the current line in the selection Form
//
Function DescriptionOfQuantityInBalanceLine(
	Count,
	PackageNameUnitsOfMeasurement,
	ItemVariantsAreUsed,
	CharacteristicNavigation)
	
	QuantityDescription = "";
	
	If ValueIsFilled(Count) Then
		QuantityDescription = Format(Count,"NFD=3") + " " + PackageNameUnitsOfMeasurement;
	EndIf;
	
	Return QuantityDescription;
	
EndFunction

// Returns the warning text for the extended search error code.
//
// Parameters:
//	ErrorCode - String - extended search error code.
//
// Returns:
//	String - the text of the advanced search error warning.
//
Function AdvancedSearchErrorWarningText(ErrorCode)
	
	If ErrorCode = "FoundNothing" Then
		WarningText = NStr("vi = 'Không tìm thấy gì, hãy làm rõ truy vấn.';
							|ru = 'Ничего не найдено, уточните запрос.';
							|en = 'No results found, specify the request.'; fa = 'No results found, specify the request.';
							|it = 'Nulla trovato, perfezionare la query.';
							|pl = 'Nic nie znaleziono, uściślij zapytanie.';
							|tr = 'Bulunamadı, sorgunu netleştir.'");
	ElsIf ErrorCode = "TooManyResults" Then
		WarningText = NStr("vi = 'Có rất nhiều kết quả tìm kiếm, hãy làm rõ truy vấn.';
							|ru = 'Слишком много результатов поиска, уточните запрос.';
							|en = 'Too many search results, refine your query.'; fa = 'Too many search results, refine your query.';
							|it = 'Troppi risultati, perfezionare la query.';
							|pl = 'Zbyt dużo wyników wyszukiwania, uściślij zapytanie.';
							|tr = 'Çok fazla arama sonucu mevcut, sorgunu netleştir.'");
	ElsIf ErrorCode = "SearchError" Then
		WarningText = NStr("vi = 'Khi thực hiện tìm kiếm đã xảy ra lỗi, hãy thử thay đổi biểu thức tìm kiếm.';
							|ru = 'При выполнении поиска произошла ошибка, попробуйте изменить выражение поиска.';
							|en = 'An error occurred when performing search. Try to change search expression.'; fa = 'An error occurred when performing search. Try to change search expression.';
							|it = 'Si è verificato un errore durante l''esecuzione di una ricerca, prova a cambiare l''inserimento di ricerca';
							|pl = 'Przy wykonaniu wyszukiwania wystąpił błąd, spróbuj zmienić wyrażenie wyszukiwania.';
							|tr = 'Arama yapılırken hata oluştu, arama ifadesini değiştirmeyi dene.'");
	Else
		WarningText = "";
	EndIf;
	
	Return WarningText;
	
EndFunction

// Sets selection by the parent of the current line in the supplier's item list
// in the product selection forms.
//
// Parameters:
//	Form - See SelectGoodsServer.WhenCreatingMatchingFormOnServer.Form
//
Procedure SetSelectionByParentOfCurRowOfPartnerProductList(Form)
	
	SearchFormTable = Form.Items[SelectGoodsClientServer.NameOfListOfPartnerProductsForSearchOption(Form)]; // FormTable
	
	CurrentRow = SearchFormTable.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	Parent = GeneralPurposeTMServerCall.ObjectAttributeValue(CurrentRow, "Parent");
	
	Form.Items.TheHierarchyOfItemPartner.CurrentRow = Parent;
	Form.CurrentPartnerItemHierarchy = Parent;
	
EndProcedure

#EndRegion

#Region NavigationProceduresAndFunctions

// Sets The Cur Row of the item hierarchy of the supplier's item in the procurement selection form.
// 
// Parameters:
//	Form - ClientApplicationForm - form the list form of selection.
//
Procedure SetCurRowOfPartnerProductHierarchy(Form)
	
	If Form.UseThePartnerItemFilter_3
		Or Not Form.NavigationThroughThePartnerSProductRange Then
		Return;
	EndIf;
	
	NameOfProductList = SelectGoodsClientServer.NameOfListOfPartnerProductsForSearchOption(Form);
	
	CurrentRow = Form.Items[NameOfProductList].CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(CurrentRow) = Type("DynamicListGroupRow") Then
		Return;
	EndIf;
	
	CurrentData = Form.Items[NameOfProductList].CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Form.Items.TheHierarchyOfItemPartner.CurrentRow = CurrentData.Parent Then
		Return;
	EndIf;
	
	Form.Items.TheHierarchyOfItemPartner.CurrentRow = CurrentData.Parent;
	Form.CurrentPartnerItemHierarchy = CurrentData.Parent;
	
EndProcedure

#EndRegion

#EndRegion
