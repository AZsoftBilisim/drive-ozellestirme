#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var ClosingInProgress Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CurrentSessionDate = CurrentSessionDate();
	
	If Parameters.Document = Undefined Then
		Raise NStr("vi = 'Chỉ có thể mở bộ xử lý từ chứng từ.';
					|ru = 'Предусмотрено открытие обработки только из документов.';
					|en = 'Data processor can be opened only from documents.'; fa = 'Data processor can be opened only from documents.';
					|it = 'Viene fornita l''apertura dell''elaborazione solo dalle forme dei documenti';
					|pl = 'Przewidziano otwarcie przetwarzania tylko z dokumentów.';
					|tr = 'Yalnızca belgelerden işlem açmak için provizyon sağlanmıştır.'");
	EndIf;
	
	FormCode = "Processing_SelectionOfGoodsInPurchaseDocument_Form";
	
	SelectGoodsServer.WhenCreatingMatchingFormOnServer(ThisObject);
	FillPropertyValues(FormSettingsWhenOpening, ThisObject);
	SelectGoodsClientServer.SetSelectionFormHeader(ThisObject);
	SetConditionalAppearance();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	SelectGoodsClientServer.SetCaptionTextToDisplayLeftovers(ThisObject);
	
	If GoodsSearchOption = "Advanced"
		Or (GoodsSearchOption = "Default" And Not UseStandardSearchWhenSelectingGoods) Then
		CurrentItem = Items.SearchStringProducts;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit
		And Object.junk.Count() > 0 Then
		
		Cancel = True;
		WarningText = NStr("vi = 'Đã thay đổi dữ liệu. Tất cả thay đổi sẽ bị mất.';
							|ru = 'Данные были изменены. Все изменения будут потеряны.';
							|en = 'All changes made to the data will be lost.'; fa = 'All changes made to the data will be lost.';
							|it = 'I dati sono stati modificati. Tutte le modifiche verranno perse.';
							|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
							|tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'");
		
		Return;
		
	EndIf;
	
	SelectGoodsClient.BeforeClosingProductSelectionForm(ThisObject, Object, Cancel);
	
	If MoveToDocument And CheckFilling And Not CheckFilling() And Not ClosingInProgress Then
		MoveToDocument = False;
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If SelectGoodsClient.SavingSettingsIsRequired(ThisObject) Then
		SaveFormSettingsOnServer();
	EndIf;
	GoodsAddressInStorage = GoodsAddressInStorage();
	
	If MoveToDocument And GoodsAddressInStorage <> Undefined Then
		Structure = New Structure("GoodsAddressInStorage", GoodsAddressInStorage);
		NotifyChoice(Structure);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_Products" 
		And Parameter.ThisIsNewProduct Then
		If ValueIsFilled(SearchStringProducts) Then
			SearchForProducts();
		EndIf;
		NameOfProductList = SelectGoodsClientServer.NameOfListOfProductsBySearchOption(ThisObject);
		ProductFormTable = Items[NameOfProductList]; // FormTable
		ProductFormTable.CurrentRow = Source;
		
		WhenWritingNewProductOnServer(Source);
		
		If GoodsForAddingToTheCart <> Undefined Then
			AddToCart(GoodsForAddingToTheCart);
			GoodsForAddingToTheCart = Undefined;
		EndIf;
	EndIf;
	
	If EventName = "Write_ItemsCharacteristics"
		And Parameter.ThisIsNewCharacteristic Then
		
		WhenRecordingNewCharacteristicOnServer(Source);
		
		If GoodsForAddingToTheCart <> Undefined Then
			AddToCart(GoodsForAddingToTheCart);
			GoodsForAddingToTheCart = Undefined;
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

&AtClient
Procedure SearchBarCharacteristicsOnChange(Item)
	
	SearchForCharacteristics();
	
EndProcedure

&AtClient
Procedure SearchBarCharacteristicsClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	SearchBarCharacteristics = "";
	
	DeselectCharacteristicsSearchBarOnServer();
	
EndProcedure

&AtClient
Procedure SearchBarPartnerItemOnChange(Item)
	
	SearchForPartnerProducts();
	
EndProcedure

&AtClient
Procedure SearchBarPartnerItemAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing)
	
	SelectionListsClientServer.AutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SearchBarPartnerItemClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	SearchBarPartnerItem = "";
	
	DeselectPartnerProductSearchBarOnServer();
	
EndProcedure

&AtClient
Procedure FindAnItemByExactMatchOnChange(Item)
	
	SearchForProducts();
	
EndProcedure

&AtClient
Procedure FindCharacteristicsByExactMatchOnChange(Item)
	
	SearchForCharacteristics();
	
EndProcedure

&AtClient
Procedure FindThePartnerSItemByExactMatchOnChange(Item)
	
	SearchForPartnerProducts()
	
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
Procedure ProductKindClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure HelpTextClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	SelectGoodsClient.WhenYouClickOnInformationLabel(ThisObject, Object);
	
EndProcedure

&AtClient
Procedure DisplayBalanceLabelClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	SelectGoodsClient.WhenChangingDisplayOfBalancesByWarehousesInDocument(ThisObject);
	
EndProcedure

&AtClient
Procedure DisplayTheRemainingInventoryItemsOfThePartnerLabelClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	SelectGoodsClient.WhenChangingDisplayOfBalancesByWarehousesInDocument(ThisObject);
	
EndProcedure

&AtClient
Procedure UseFiltersOnChange(Item)
	
	UseFiltersWhenChangingOnServer();
	
	If ValueIsFilled(SearchStringProducts) Then
		SearchForProducts();
	EndIf;
	
EndProcedure

&AtClient
Procedure UseThePartnerItemFilterOnChange(Item)
	
	SelectGoodsClient.WhenYouChangeUseOfPartnerProductFilters(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterPriceFromOnChange(Item)
	
	SelectGoodsClientServer.SetSelectionByPriceRange(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterPriceUpToOnChange(Item)
	
	SelectGoodsClientServer.SetSelectionByPriceRange(ThisObject);
	
EndProcedure

&AtClient
Procedure SelectionPriceFromSupplierOnChange(Item)
	
	WhenChangingVendorPriceRangeOnServer();

EndProcedure

&AtClient
Procedure SelectionPriceToSupplierOnChange(Item)
	
	WhenChangingVendorPriceRangeOnServer();

EndProcedure

&AtClient
Procedure SegmentOnChange(Item)
	
	ProductItemSegmentWhenChangedOnServer();
	
	If ValueIsFilled(SearchStringProducts) Then
		SearchForProducts();
	EndIf;
	
EndProcedure

&AtClient
Procedure VendorPriceKindOnChange(Item)
	
	SupplierPriceViewWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure OnlyInStockOnChange(Item)
	
	OnlyInStockOnChangeAtServer();
	
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

#Region FormTableItemsEventHandlersFilterTree

&AtClient
Procedure FilterTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectGoodsClient.FilterTreeSelection(ThisObject, New CallbackDescription("SelectionTreeWhenStateChanges", ThisObject));
	
EndProcedure

&AtClient
Procedure SelectionTreeWhenStateChanges(Result, AdditionalParameters) Export 
	
	If Result = Undefined Then
		Return;
	ElsIf Result Then
		SelectGoodsClient.SelectionTreeWhenStateChanges(ThisObject);
		
		SelectionTreeSelectionWhenModifiedOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterTreeBeforeRowChange(Item, Cancel)
	
	SelectGoodsClient.FilterTreeBeforeRowChange(ThisObject, Cancel);
	
EndProcedure

&AtClient
Procedure FilterTreeFilterOnChange(Item)
	
	SelectGoodsClient.FilterTreeFilterOnChange(ThisObject, New CallbackDescription("SelectionTreeWhenStateChanges", ThisObject));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductsHierarchy

&AtClient
Procedure ProductsHierarchySelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ProductsHierarchyOnActivateRow(Item)
	
	SelectGoodsClient.WhenProductHierarchyLineIsActivated(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTheHierarchyOfItemPartner

&AtClient
Procedure TheHierarchyOfItemPartnerSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure TheHierarchyOfItemPartnerOnActivateRow(Item)
	
	SelectGoodsClient.WhenActivatingLineInPartnerProductHierarchy(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStockBalance

&AtClient
Procedure StockBalanceSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If CurrentLineOfProducts = Undefined Then
		Return;
	EndIf;
	
	RowOfRemainderTable = StockBalance.FindByID(RowSelected);
	If RowOfRemainderTable = Undefined Then
		Return;
	EndIf;
	
	If Not RowOfRemainderTable.WarehouseIsAvailableForSelection Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn kho này trong chứng từ đang soạn.';
										|ru = 'Данный склад не был выбран в редактируемом документе.';
										|en = 'This warehouse was not selected in the document you edit.'; fa = 'This warehouse was not selected in the document you edit.';
										|it = 'Questo magazzino non è stato selezionato nel documento modificato.';
										|pl = 'Ten magazyn nie został wybrany w edytowanym dokumencie.';
										|tr = 'Bu ambar düzenlenmekte olan belgede seçilmedi.'"));
		Return;
	EndIf;
	
	If UseItemVariants 
		And CurrentLineOfProducts.ItemVariantsAreUsed 
		And Not CharacteristicNavigation Then
		
		Response = Undefined;

		
		ShowQueryBox(New CallbackDescription("StockBalanceSelectionCompletion", ThisObject), NStr("vi = 'Chưa chọn đặc tính. Chuyển sang chọn đặc tính?';
																									|ru = 'Не выбрана характеристика. Перейти к выбору характеристик?';
																									|en = 'Variant is not selected. Go to variant selection?'; fa = 'Variant is not selected. Go to variant selection?';
																									|it = 'Non è stata scelta la caratteristica.Passare alla scelta della caratteristica?';
																									|pl = 'Nie jest wybrana charakterystyka. Przejść do wyboru cech?';
																									|tr = 'Özellik seçilmedi. Özellik seçmeye git?'"), QuestionDialogMode.OKCancel);
		
		Return;
		
	EndIf;
	
	ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
	
	If CharacteristicNavigation Then
		
		CharacteristicsTableRow = Items[SelectGoodsClientServer.NameOfListOfCharacteristicsBySearchOption(ThisObject)].CurrentData;
		FillPropertyValues(ProductParameters_1, CharacteristicsTableRow);
		
	Else
		
		FillPropertyValues(ProductParameters_1, CurrentLineOfProducts);
		
	EndIf;
	
	If CurrentLineOfProducts.ThisIsAProduct And SelectionModeUseWarehousesInTabularSection Then
		ProductParameters_1.Warehouse = RowOfRemainderTable.Warehouse;
	EndIf;
	
	ProductParameters_1.NumberOfPackages = 1;
	
	AddToCart(ProductParameters_1);
	
EndProcedure

&AtClient
Procedure StockBalanceSelectionCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.OK Then
		GoToListOfCharacteristics();
		SelectGoodsClient.AfterGoingToListOfCharacteristics(ThisObject);
    EndIf;

EndProcedure

&AtClient
Procedure StockBalanceDragStart(Item, DragParameters, Perform)
	
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	SelectGoodsClient.GetDragAndDropDataForLeftovers(ThisObject, Item, DragParameters);	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSupplierStockBalance

&AtClient
Procedure SupplierStockBalanceSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	RowInPartnerProductTable = Items[SelectGoodsClientServer.NameOfListOfPartnerProductsForSearchOption(ThisObject)].CurrentData;
	If RowInPartnerProductTable = Undefined Then
		Return;
	EndIf;
	
	RowOfRemainderTable = SupplierStockBalance.FindByID(RowSelected);
	If RowOfRemainderTable = Undefined Then
		Return;
	EndIf; 
	
	If Not RowOfRemainderTable.WarehouseIsAvailableForSelection Then
		
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn kho này trong chứng từ đang soạn.';
										|ru = 'Данный склад не был выбран в редактируемом документе.';
										|en = 'This warehouse was not selected in the document you edit.'; fa = 'This warehouse was not selected in the document you edit.';
										|it = 'Questo magazzino non è stato selezionato nel documento modificato.';
										|pl = 'Ten magazyn nie został wybrany w edytowanym dokumencie.';
										|tr = 'Bu ambar düzenlenmekte olan belgede seçilmedi.'"));
		Return;
		
	EndIf;
	
	ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
	FillPropertyValues(ProductParameters_1, RowInPartnerProductTable);
	
	If RowInPartnerProductTable.ThisIsAProduct And SelectionModeUseWarehousesInTabularSection And Warehouses.Count() = 1 Then
		ProductParameters_1.Warehouse = RowOfRemainderTable.Warehouse;
	EndIf;
	
	ProductParameters_1.NumberOfPackages = 1;
	ProductParameters_1.ItemVariantsAreUsed =
		Not (RowInPartnerProductTable.UseVariants = PredefinedValue("Enum.ItemVariantsUsageOptions.DontUse"));
	
	AddToCart(ProductParameters_1);
	
EndProcedure

&AtClient
Procedure SupplierStockBalanceDragStart(Item, DragParameters, Perform)
	
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	SelectGoodsClient.GetDragAndDropDataForLeftovers(ThisObject, Item, DragParameters);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormTableElementsSelectionPartnerProductTable

&AtClient
Procedure SelectionOfThePartnerSItemTableWhenActivatingTheLine(Item)
	
	SelectGoodsClient.WhenActivatingPartnerProductLine(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure SelectionTableOfThePartnerSNomenclatureSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	TBLString = Item.CurrentData;
	If TBLString.IsFolder Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(TBLString.Products) Then
		
		ShowUserNotification(
			NStr("vi = 'Không thể chọn mặt hàng';
				|ru = 'Невозможно подобрать номенклатуру';
				|en = 'Cannot pick products'; fa = 'Cannot pick products';
				|it = 'Impossibile scegliere articoli';
				|pl = 'Nie można dobrać nomenklaturę';
				|tr = 'Öğe seçilemiyor'"),,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trong mặt hàng của nhà cung cấp ""%1"" chưa chỉ định mặt hàng.';
																			|ru = 'В номенклатуре поставщика ""%1"" не указана номенклатура.';
																			|en = 'In the %1 vendor part number, the item is required.'; fa = 'In the %1 vendor part number, the item is required.';
																			|it = 'В номенклатуре поставщика ""%1"" не указана номенклатура.';
																			|pl = 'In the %1 vendor part number, the item is required.';
																			|tr = 'Satıcının ""%1"" parça numarasında herhangi bir öğe belirtilmedi.'"), TBLString.Ref), 
			PictureLib.Information32);
		
		ShowValue(Undefined, TBLString.Ref);
		Return;
		
	EndIf;
	
	If TBLString.DeletionMark Then
		ShowQueryBox(New CallbackDescription("SelectionTableOfThePartnerSNomenclatureSelectionCompletion", ThisObject, New Structure("TBLString", TBLString)), NStr("vi = 'Đã đặt dữ liệu được chọn.
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
			|Bu verilerin seçimini gerçekleştir?'") , QuestionDialogMode.YesNo);
        Return;
	EndIf;
	
	SelectionTableOfPartnerProductsSelectionFragment(TBLString);
EndProcedure

&AtClient
Procedure SelectionTableOfThePartnerSNomenclatureSelectionCompletion(QuestionResult, AdditionalParameters) Export
	
	TBLString = AdditionalParameters.TBLString;
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	SelectionTableOfPartnerProductsSelectionFragment(TBLString);

EndProcedure

&AtClient
Procedure SelectionTableOfPartnerProductsSelectionFragment(Val TBLString)
	
	Var ProductParameters_1;
	
	ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
	
	FillPropertyValues(ProductParameters_1, TBLString);
	
	If Warehouses.Count() = 1 And SelectionModeUseWarehousesInTabularSection Then
		ProductParameters_1.Warehouse = Warehouses.Get(0).Value;
	EndIf;
	
	ProductParameters_1.NumberOfPackages = 1;
	ProductParameters_1.ItemVariantsAreUsed =
		Not (TBLString.UseVariants = PredefinedValue("Enum.ItemVariantsUsageOptions.DontUse"));
	
	AddToCart(ProductParameters_1);

EndProcedure

&AtClient
Procedure SelectionTablePartnerNomenclatureStartDragging(Item, DragParameters, Perform)
	
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	SelectGoodsClient.GetDragAndDropData(ThisObject, Item, DragParameters);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormTableElementsSelectionCharacteristicsTable

&AtClient
Procedure SelectionTableCharacteristicsWhenActivatingARow(Item)
	
	SelectGoodsClient.WhenActivatingRowInCharacteristicsTable(ThisObject, Item);
	
EndProcedure

// Function-constructor of additional parameters 
// Returns:
// 	Structure - advanced setting:
// * Item - FormGroup, FormTable, FormField, FormButton - Form element
&AtClient
Function AdditionalCompletionProcessingParameters()
	
	Result = New Structure;
	Result.Insert("Item");
	Return Result;
	
EndFunction

&AtClient
Procedure SelectionTableCharacteristicsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.Item = Item;
	
	// Check the selected row of characteristics.
	Notification = New CallbackDescription("SelectionTableCharacteristicsSelectionCompletion", ThisObject, 
		AdditionalParameters);
	SelectGoodsClient.WhenSelectingRowInCharacteristicsTable(ThisObject, Item, Notification);
	
EndProcedure

// Selection table characteristics selection completion.
// 
// Parameters:
//  Result - Arbitrary
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure SelectionTableCharacteristicsSelectionCompletion(Result, AdditionalParameters) Export
	
	CharacteristicsTableRow = AdditionalParameters.Item.CurrentData;
	
	If CharacteristicsTableRow = Undefined Then
		Return;
	EndIf;
	
	ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
	
	FillPropertyValues(ProductParameters_1, CharacteristicsTableRow);
	ProductParameters_1.IsService = CurrentLineOfProducts.IsService;
	If CurrentLineOfProducts.ThisIsAProduct
		And SelectionModeUseWarehousesInTabularSection
		And Warehouses.Count() = 1 Then
		
		ProductParameters_1.Warehouse = Warehouses.Get(0).Value;
		
	EndIf;
	
	ProductParameters_1.NumberOfPackages = 1;
	
	AddToCart(ProductParameters_1);

EndProcedure

&AtClient
Procedure SelectionTableCharacteristicsStartOfDraggingArray(Item, DragParameters, Perform)
	
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	
	SelectGoodsClient.GetDragAndDropData(ThisObject, Item, DragParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure SelectionTableItemWhenActivatingALine(Item)
	
	SelectGoodsClient.WhenActivatingRowInProductTable(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure SelectionOfTableItemSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.Item = Item;
	
	// Check the selected item line.
	Notification = New CallbackDescription("SelectionOfTableItemSelectionCompletion", ThisObject, 
		AdditionalParameters);
	SelectGoodsClient.WhenSelectingRowInProductTable(ThisObject, Notification);
	
EndProcedure


// Selection table nomenclature selection completion.
// 
// Parameters:
//  Result - Arbitrary
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure SelectionOfTableItemSelectionCompletion(Result, AdditionalParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SelectGoodsToPurchaseDocument.Form.Notification.SelectionOfTableItemSelectionCompletion");
	
	TBLString = AdditionalParameters.Item.CurrentData;
	If TBLString.IsFolder Then
		Return;
	EndIf;
	
	If UseItemVariants And TBLString.ItemVariantsAreUsed Then
		GoToListOfCharacteristics();
		SelectGoodsClient.AfterGoingToListOfCharacteristics(ThisObject);
	Else
		
		ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
		
		FillPropertyValues(ProductParameters_1, TBLString);
		
		If TBLString.ThisIsAProduct And Warehouses.Count() = 1 And SelectionModeUseWarehousesInTabularSection Then
			ProductParameters_1.Warehouse = Warehouses.Get(0).Value;
		EndIf;
		
		ProductParameters_1.NumberOfPackages = 1;
		
		AddToCart(ProductParameters_1);
		
	EndIf;

EndProcedure

&AtClient
Procedure StartDragList(Item, DragParameters, Perform)
	
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	SelectGoodsClient.GetDragAndDropData(ThisObject, Item, DragParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersjunk

&AtClient
Procedure junkOnActivateRow(Item)
	
	AttachIdleHandler("FillInPartnerProductSelectionList", 0.1, True);
	
EndProcedure

&AtClient
Procedure junkOnChange(Item)
	
	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	
EndProcedure

&AtClient
Procedure junkPercentRateOfManualDiscountOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;	
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure junkManualDiscountOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("RecalculateAmountOfManualDiscount_", False));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ShoppingCartPartnerSItemWhenChanging(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	PriceFillingParameters_ = BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(ThisObject);
	PriceFillingParameters_.Date = CurrentSessionDate;
	
	StructureOfActions.Insert("FillInPurchasePrice",
		PriceFillingParameters_);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure junkProductsOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Partner);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	PriceFillingParameters_ = BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(ThisObject);
	PriceFillingParameters_.Date = CurrentSessionDate;
	
	StructureOfActions.Insert("FillInPurchasePrice", PriceFillingParameters_);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillInPartnerProductSelectionList();
	
EndProcedure

&AtClient
Procedure junkCharacteristicOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	PriceFillingParameters_ = BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(ThisObject);
	PriceFillingParameters_.Date = CurrentSessionDate;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("FillInPurchasePrice", PriceFillingParameters_);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Partner);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillInPartnerProductSelectionList();
	
EndProcedure

&AtClient
Procedure junkNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure junkPackageOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Partner);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	If CurrentRow.Count > 0 Then
		
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
		
	Else
		
		PriceFillingParameters_ = BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(ThisObject);
		PriceFillingParameters_.Date = CurrentSessionDate;
		
		StructureOfActions.Insert("FillInPurchasePrice", PriceFillingParameters_);
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillInPartnerProductSelectionList();
	
EndProcedure

&AtClient
Procedure junkVendorPriceKindOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	PriceFillingParameters_ = BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(ThisObject);
	PriceFillingParameters_.Date = CurrentSessionDate;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInPurchasePrice", PriceFillingParameters_);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure junkPriceOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure junkSumOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountForAmountInPurchases", New Structure("UseManualDiscounts"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure junkDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	DragToTrashOnServer(DragParameters.Value);
	
EndProcedure

&AtClient
Procedure ShoppingCartPartnerItemStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.junk.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification);
	
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
Procedure SetTheCurrentNavigationElement(Command)
	
	SelectGoodsClient.SetTheCurrentNavigationElement(ThisObject);
	
EndProcedure

&AtClient
Procedure SetTheCurrentItemProductList(Command)
	
	SelectGoodsClient.SetTheCurrentItemProductList(ThisObject);
	
EndProcedure

&AtClient
Procedure SetTheCurrentPartnerItemItem(Command)
	
	SelectGoodsClient.SetTheCurrentPartnerItemItem(ThisObject);
	
EndProcedure

&AtClient
Procedure SetTheCurrentItemTrash(Command)
	
	SelectGoodsClient.SetTheCurrentItemTrash(ThisObject);
	
EndProcedure

&AtClient
Procedure SetTheCurrentSearchBarItem(Command)
	
	SelectGoodsClient.SetTheCurrentSearchBarItem(ThisObject);
	
EndProcedure

&AtClient
Procedure ChangeRequestQuantity(Command)
	
	RequestQuantity = Not RequestQuantity;
	Items.RequestQuantityPrice.Check = RequestQuantity;
	
EndProcedure

&AtClient
Procedure Search(Command)
	
	CurMessageToUser = "";
	
EndProcedure

&AtClient
Procedure MoveToDocument(Command)
	
	MoveToDocument = True;
	Close(DialogReturnCode.OK);
	
EndProcedure

&AtClient
Procedure SelectionGoToTheListOfItemsAdvancedSearch(Command)
	
	SelectGoodsClient.GoToListOfProducts(ThisObject);
	
EndProcedure

&AtClient
Procedure SelectionGoToTheListOfItemsStandardSearch(Command)
	
	SelectGoodsClient.GoToListOfProducts(ThisObject);
	
EndProcedure

&AtClient
Procedure ItemsPrices(Command)
	
	SelectGoodsClient.ItemsPrices(ThisObject);
	
EndProcedure

&AtClient
Procedure CreateNewProducts(Command)
	
	OpenForm("Catalog.Products.ObjectForm",
		New Structure("AdditionalParameters", ParametersForCreatingNewProductItemOnServer()), ThisObject);
	
EndProcedure

&AtClient
Procedure CreateNewCharacteristic(Command)
	
	OpenForm("Catalog.ItemsCharacteristics.ObjectForm",
		New Structure("AdditionalParameters", ParametersForCreatingNewCharacteristicOnServer()), ThisObject);
	
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
Procedure ProductsWithSimilarProperties(Command)
	
	If SelectGoodsClient.ThereAreSelectedLinesInListOfItems(ThisObject) Then
		ProductsWithSimilarPropertiesOnServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheHierarchyOfItemPartner.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseThePartnerItemFilter_3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.FormBackColor);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SearchBarPartnerItem.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheSearchForThePartnerSNomenclatureIsNotSuccessful");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("BackColor", WebColors.MistyRose);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PartnerProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn nhà cung cấp>';
													|ru = '<выберите поставщика>';
													|en = '<select vendor>'; fa = '<select vendor>';
													|it = '<selezionare il fornitore>';
													|pl = '<wybierz dostawcę>';
													|tr = '<tedarikçi seçin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//
	
	SelectGoodsServer.SetConditionalAppearanceOfDynamicLists(ThisObject, True);
	
	//
	
	SelectGoodsServer.SetConditionalAppearanceOfSelectionFormElements(ThisObject, True);

EndProcedure

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Function AddToCartOnClient(ProductParameters_1, NewLines)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	For Each NewRow In NewLines Do
		
		Filter = New Structure;
		
		Filter.Insert("Products",               ProductParameters_1.Products);
		
		If ValueIsFilled(ProductParameters_1.PartnerProducts) Then
			Filter.Insert("PartnerProducts", ProductParameters_1.PartnerProducts);
		EndIf;
		
		Filter.Insert("Characteristic",             ProductParameters_1.Characteristic);
		Filter.Insert("ItemVariantsAreUsed", ProductParameters_1.ItemVariantsAreUsed);
		
		Filter.Insert("Package",                   NewRow.Package);
		Filter.Insert("Price",                       NewRow.Price);
		Filter.Insert("VendorPriceKind",          NewRow.VendorPriceKind);
		Filter.Insert("Warehouse",                      NewRow.Warehouse);
		Filter.Insert("PercentRateOfManualDiscount",        NewRow.PercentRateOfManualDiscount);
		
		RowFound = False;
		SearchResult = Object.junk.FindRows(Filter);
		
		If SearchResult.Count() = 0 Then
			CurrentRow = Object.junk.Add();
			FillPropertyValues(CurrentRow, Filter);
		Else
			RowFound = True;
			CurrentRow = SearchResult[0];
		EndIf;
		
		CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackages + NewRow.NumberOfPackages;
		
		If Not RowFound Then
			If ProductParameters_1.Property("PartnerProducts") Then
				If Not ValueIsFilled(ProductParameters_1.PartnerProducts) Then
					StructureOfActions.Insert("FillInProductNameOfProductPartner", Partner);
				EndIf;
			Else
				StructureOfActions.Insert("FillInProductNameOfProductPartner", Partner);
			EndIf;
		EndIf;
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
		
		If Not ShowSelectedGoods Then
			
			NotificationText1 = Chars.LF + NStr("vi = 'Hàng hóa ""[OwnGoods]"" với giá trị [Price] [Currency] số lượng [NumberOfPackages] [UnitOfMeasure] đã thêm vào giỏ';
												|ru = 'Товар ""[OwnGoods]"" стоимостью [Price] [Currency] в количестве [NumberOfPackages] [UnitOfMeasure] добавлен в корзину';
												|en = 'The ""[OwnGoods]"" goods of value [Price] [Currency] are added to the cart in quantity of [NumberOfPackages] [UnitOfMeasure]'; fa = 'The ""[OwnGoods]"" goods of value [Price] [Currency] are added to the cart in quantity of [NumberOfPackages] [UnitOfMeasure]';
												|it = 'La merce ""[OwnGoods]"" con valore  [Price] [Currency] in quantità [NumberOfPackages] [UnitOfMeasure] è aggiunto al carrello';
												|pl = 'Towar ""[OwnGoods]"" o wartości [Price][Currency] o ilości [NumberOfPackages] [UnitOfMeasure] został dodany do koszyka';
												|tr = '[Price] [Currency] değerinde [NumberOfPackages] [UnitOfMeasure] miktarında ürün ""[OwnGoods]"" sepete eklendi'");
			
			ValuesToInsert = New Structure("OwnGoods, Price, Currency, NumberOfPackages, UnitOfMeasure");
			
			ValuesToInsert.OwnGoods              = String(CurrentRow.Products) + ?(ValueIsFilled(ProductParameters_1.Characteristic)," ("+ProductParameters_1.Characteristic+")","");
			ValuesToInsert.Price               = Format(CurrentRow.Price, "NFD=2; NZ=");
			ValuesToInsert.Currency             = Currency;
			ValuesToInsert.UnitOfMeasure   = ?(ValueIsFilled(NewRow.Package), NewRow.Package, NStr("vi = 'đvt';
																									|ru = 'ед.';
																									|en = 'unit'; fa = 'واحد';
																									|it = 'unità';
																									|pl = 'unit';
																									|tr = 'birim.'"));
			ValuesToInsert.NumberOfPackages = NewRow.NumberOfPackages;
			
			NotificationText1 = StringFunctionsClientServer.InsertParametersIntoString(NotificationText1, ValuesToInsert);
			
		EndIf;
		
	EndDo;
	
	If NewLines.Count() > 0 Then
		Items.junk.CurrentRow = CurrentRow.GetID();
	EndIf;
	
	Return NotificationText1;
	
EndFunction

&AtServer
Procedure DragToTrashOnServer(NewLines)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");

	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	RowsToProcess = New Array;
	ProcessedLinesFillingInPartnerSNomenclature = New Array;
		
	PartnerProducts = Catalogs.ProductCrossReferences.EmptyRef();

	For Each NewRow In NewLines Do
		
		Filter = New Structure;
		
		Filter.Insert("Products",               NewRow.Products);
		
		If TypeOf(NewRow.PartnerProducts) = Type("CatalogRef.ProductCrossReferences") Then
			PartnerProducts = NewRow.PartnerProducts;
		ElsIf TypeOf(NewRow.PartnerProducts) = Type("FormDataStructure") Then
			PartnerProducts = NewRow.PartnerProducts.Ref; // CatalogRef.ProductCrossReferences -
		ElsIf NewRow.PartnerProducts = Undefined Then
			PartnerProducts = Catalogs.ProductCrossReferences.EmptyRef();
		EndIf;
		If ValueIsFilled(PartnerProducts) Then
			Filter.Insert("PartnerProducts", PartnerProducts);
		EndIf;
		
		Filter.Insert("Characteristic",             NewRow.Characteristic);
		Filter.Insert("ItemVariantsAreUsed", NewRow.ItemVariantsAreUsed);
		
		Filter.Insert("Package",                   NewRow.Package);
		Filter.Insert("Price",                       NewRow.Price);
		Filter.Insert("VendorPriceKind",          NewRow.VendorPriceKind);
		Filter.Insert("Warehouse",                      NewRow.Warehouse);
		
		RowFound = False;
		SearchResult = Object.junk.FindRows(Filter);
		
		If SearchResult.Count() = 0 Then
			CurrentRow = Object.junk.Add();
			FillPropertyValues(CurrentRow, Filter);
		Else
			RowFound = True;
			CurrentRow = SearchResult[0];
		EndIf;
		
		CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackages + NewRow.NumberOfPackages;
		
		If Not RowFound Then
			
			If NewRow.Property("PartnerProducts") Then
				If Not ValueIsFilled(NewRow.PartnerProducts) Then
					ProcessedLinesFillingInPartnerSNomenclature.Add(CurrentRow);
				EndIf;
			Else
				ProcessedLinesFillingInPartnerSNomenclature.Add(CurrentRow);
			EndIf;
			
		EndIf;
		
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.junk,
		CachedValues);
	
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Partner);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesFillingInPartnerSNomenclature,
		StructureOfActions,
		Object.junk,
		CachedValues);
	
	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	
EndProcedure

// Function-constructor of additional parameters 
// Returns:
// 	Structure - advanced setting:
// * NewLines - Array
// * ProductParameters_1 - Structure
&AtClient
Function AdditionalParametersForProcessingCompletionOfAddingToCart()
	
	Result = New Structure;
	Result.Insert("NewLines", New Array);
	Result.Insert("ProductParameters_1");
	Return Result;
	
EndFunction

&AtClient
Procedure AddToCart(ProductParameters_1)
	
	If Not ValueIsFilled(ProductParameters_1) Then
		Return;
	EndIf;
	
	AdditionalParameters = AdditionalParametersForProcessingCompletionOfAddingToCart();
	AdditionalParameters.ProductParameters_1 = ProductParameters_1;
	
	If RequestQuantity And Not ModeOfSelectionWithoutQuantitativeParameters Then
		
		FormParameters = New Structure("Products, Characteristic, Package, Price, PriceIncludesVAT, Date, Currency, Warehouses, Warehouse, IsService, Terms, Partner, UseWarehousesInTheTablePart,
		|HidePrice, EditThePrice, MaximumPercentageOfTheManualDiscount, HideManualDiscounts, UseDiscountAdjustmentsInPurchases");
		
		FillPropertyValues(FormParameters, ProductParameters_1);
		
		FormParameters.Date                              = Date;
		FormParameters.Currency                            = Currency;
		FormParameters["Warehouses"]                         = Warehouses.UnloadValues();
		FormParameters.Partner                           = Partner;
		FormParameters.Terms                        = Terms;
		FormParameters.PriceIncludesVAT                   = Object.PriceIncludesVAT;
		FormParameters.UseWarehousesInTheTablePart = SelectionModeUseWarehousesInTabularSection;
		FormParameters.HidePrice                        = SelectionModeWithoutAmountParameters;
		FormParameters.EditThePrice                 = True;
		FormParameters.HideManualDiscounts              = HideManualDiscounts Or SelectionModeWithoutAmountParameters;
		FormParameters.MaximumPercentageOfTheManualDiscount           = MaximumPercentageOfTheManualDiscount;
		FormParameters.Package                          = ProductParameters_1.Package;
		FormParameters.UseDiscountAdjustmentsInPurchases = UseDiscountAdjustmentsInPurchases;
		
		If UseDiscountAdjustmentsInPurchases Then
			AddressInTempStorage = AddressOfDataForCalculatingManualDiscountsForSelectionInTemporaryStorageOnServer(ProductParameters_1);
		Else
			AddressInTempStorage = Undefined;
		EndIf;
		
		FormParameters.Insert("AddressInTempStorage", AddressInTempStorage);
		FormParameters.Insert("VendorPriceKind",         VendorPriceKind);
		
		OpenForm(
			"DataProcessor.SelectGoodsToPurchaseDocument.Form.QuantityRequest",
			FormParameters,
			ThisObject,
			,
			,
			,
			New CallbackDescription("AddToCartQuantityRequestCompletion", ThisObject, AdditionalParameters),
			FormWindowOpeningMode.LockOwnerWindow);
			
		Return;
			
	Else
		
		NewRow = SelectGoodsClientServer.ProductParameters_1();
		FillPropertyValues(NewRow, ProductParameters_1);
		NewRow.VendorPriceKind = VendorPriceKind;
		
		AdditionalParameters.NewLines.Add(NewRow);
		
	EndIf;
	
	AddFragmentToCart(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure AddFragmentToCart(AdditionalParameters)
	
	NotificationText1 = AddToCartOnClient(AdditionalParameters.ProductParameters_1, AdditionalParameters.NewLines);
	
	If Not ShowSelectedGoods Then
		ShowUserNotification(NStr("vi = 'Thêm vào giỏ hàng';
									|ru = 'Товар добавлен в корзину';
									|en = 'The goods are added to the cart'; fa = 'The goods are added to the cart';
									|it = 'Merce aggiunta al carrello';
									|pl = 'Towar został dodany do koszyka';
									|tr = 'Ürün sepete eklendi'"), , NotificationText1);
	EndIf;
	
	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	
	// If the product was added to the cart when the search bar was filled in,
	// then return the input focus to the search bar.
	NameOfCurElementOfSearchString = SelectGoodsClient.NameOfCurElementOfSearchString(ThisObject);
	If ValueIsFilled(ThisObject[NameOfCurElementOfSearchString]) Then
		SelectGoodsClient.SetTheCurrentSearchBarItem(ThisObject);
	EndIf;
	
EndProcedure

// Add to cart request quantity completion.
// 
// Parameters:
//  SelectedGoods - Arbitrary
// 	AdditionalParameters - See AdditionalParametersForProcessingCompletionOfAddingToCart
&AtClient
Procedure AddToCartQuantityRequestCompletion(SelectedGoods, AdditionalParameters) Export
	
	If SelectedGoods = Undefined Then
		Return;
	EndIf;
	
	For Each SelectedGoodItem In SelectedGoods Do
		
		NewRow = SelectGoodsClientServer.ProductParameters_1();
		
		FillPropertyValues(NewRow, AdditionalParameters.ProductParameters_1);
		FillPropertyValues(NewRow, SelectedGoodItem);
		
		AdditionalParameters.NewLines.Add(NewRow);
		
	EndDo;

	AddFragmentToCart(AdditionalParameters);
	
EndProcedure

#EndRegion

#Region PluggableWaitHandlers

&AtClient
Procedure ProductHierarchyWhenActivatingWaitHandlerLine()
	
	SelectGoodsClient.HandlerForActivatingLineInProductHierarchy(ThisObject);
	
EndProcedure

&AtClient
Procedure HierarchyOfPartnerProductsWhenWaitHandlerLineIsActivated()
	
	SelectGoodsClient.HandlerForActivatingLineInPartnerProductHierarchy(ThisObject);
	
EndProcedure

&AtClient
Procedure TableSelectionWhenActivatingWaitHandlerLine()
	
	SelectGoodsClient.GetProductInformationWhenPurchasing(ThisObject);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function PutProductsInStorage()
	
	Goods = Object.junk.Unload();
	GoodsAddressInStorage = PutToTempStorage(Goods, UUID);
	
	Return GoodsAddressInStorage;
	
EndFunction

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	NavigationThroughThePartnerSProductRange = (Items.Pages.CurrentPage = Items.ThePartnerSNomenclaturePage);
	If NavigationThroughThePartnerSProductRange 
		And UseThePartnerItemFilter_3 Then
		If CurrentPartnerItemHierarchy = Undefined Then
			CurrentPartnerItemHierarchy = Items.TheHierarchyOfItemPartner.CurrentRow;
		EndIf;
		SelectGoodsClientServer.SetSelectionByPartnerProductHierarchy(ThisObject);
	EndIf;
	
	SelectGoodsClient.PagesWhenChangingProductListPage(ThisObject);
	
EndProcedure

&AtClient
Procedure OpenGoodsProfile(Command)
	
	SelectGoodsClient.OpenGoodsProfile(ThisObject);
	
EndProcedure

#EndRegion

#Region Search

&AtClient
Procedure SearchForProducts()
	
	SelectGoodsClient.PerformingAdvancedSearchIsPossible(ThisObject, 
		New CallbackDescription("SearchForProductsCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure SearchForProductsCompletion(Result, AdditionalParameters) Export 
	
	SearchForProductsOnServer();
	
	SelectGoodsClient.AfterSearchingForProducts(ThisObject);

EndProcedure

&AtServer
Procedure SearchForProductsOnServer()
	
	SelectGoodsServer.SearchForProducts(ThisObject);
	
EndProcedure

&AtServer
Procedure DeselectCharacteristicsSearchBarOnServer()
	
	SelectGoodsClientServer.DeselectByCharacteristicsSearchBar(ThisObject);
	
EndProcedure

&AtServer
Procedure DeselectProductSearchBarOnServer()
	
	SelectGoodsClientServer.DeselectProductSearchBar(ThisObject);
	
EndProcedure

&AtServer
Procedure DeselectPartnerProductSearchBarOnServer()
	
	SelectGoodsClientServer.DeselectPartnerProductSearchBar(ThisObject);
	
EndProcedure

&AtClient
Procedure SearchForCharacteristics()
	
	SelectGoodsClient.PerformingAdvancedSearchIsPossible(ThisObject, 
		New CallbackDescription("SearchForCharacteristicsCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure SearchForCharacteristicsCompletion(Result, AdditionalParameters) Export 
	
	SearchForCharacteristicsOnServer();
	
	SelectGoodsClient.AfterPerformingFeatureSearch(ThisObject);

EndProcedure

&AtServer
Procedure SearchForCharacteristicsOnServer()
	
	SelectGoodsServer.SearchForCharacteristics(ThisObject);
	
EndProcedure

&AtClient
Procedure SearchForPartnerProducts()
	
	SelectGoodsClient.PerformingAdvancedSearchIsPossible(ThisObject, 
		New CallbackDescription("SearchForPartnerProductsCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure SearchForPartnerProductsCompletion(Result, AdditionalParameters) Export 
	
	SearchForPartnerProductsOnServer();
	
	SelectGoodsClient.AfterSearchingForPartnerProducts(ThisObject);

EndProcedure

&AtServer
Procedure SearchForPartnerProductsOnServer()
	
	SelectGoodsServer.SearchForPartnerProducts(ThisObject);
	
EndProcedure

#EndRegion

#Region ManagingNavigationOption

&AtClient
Procedure ItemKindsOnActivateRow(Item)
 	SelectGoodsClient.WhenActivatingProductTypesListLine(ThisObject);
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
	SelectGoodsServer.LabelNavigationOptionNavigationLink(ThisObject, Var_URL, StandardProcessing)
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
	
	SelectGoodsServer.WhenChangingNavigationOption(ThisObject);
	
	If ValueIsFilled(ProductKind) Then
			
			SelectGoodsServer.GoToListOfProducts(ThisObject);
			SelectGoodsServer.SetQueryTextsForMatchingFormLists(ThisObject);
	
	EndIf;
		
EndProcedure

#EndRegion

#Region Other

&AtServer
Function GoodsAddressInStorage()
	
	AddressInStorage = Undefined;
	
	If MoveToDocument Then
		AddressInStorage = PutProductsInStorage();
	EndIf;
	
	Return AddressInStorage;
	
EndFunction

&AtClient
Procedure ConfigureSearch(Command)
	
	SelectGoodsClient.ConfigureSearch(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInPartnerProductSelectionList()
	
	CurrentData = Items.junk.CurrentData;
	
	PartnersProductsClient.FillInPartnerProductSelectionList(
		Partner, CurrentData, Items.PartnerProducts.ChoiceList);
	
	PartnersProductsClient.SetPackageSelectionParameters(
			Items.PartnerProducts.ChoiceParameters, CurrentData);
	
EndProcedure

// Parameters:
// ValueSelected - CatalogRef.ProductCrossReferences
// AdditionalParameters - Structure
// 
&AtClient
Procedure ProcessResultOfSelectingPartnerProductName(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.CurrentRow.PartnerProducts = ValueSelected;
	
	ShoppingCartPartnerSItemWhenChanging(AdditionalParameters.FormItem);
	
EndProcedure

#EndRegion

#Region EventHandlersOnServer

&AtServer
Procedure GoToListOfCharacteristics() 
	SelectGoodsServer.GoToListOfCharacteristics(ThisObject);
EndProcedure		

&AtServer
Procedure UseFiltersWhenChangingOnServer()
	
	SelectGoodsServer.WhenChangingUseOfFilters(ThisObject);
	
	If (NavigationOption = Enums.ItemFormNavigationOptions.ByProperties
				Or NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties
				Or NavigationOption = Enums.ItemFormNavigationOptions.ByKinds) 
			And ValueIsFilled(ProductKind) Then
			
			SelectGoodsServer.GoToListOfProducts(ThisObject);
			SelectGoodsServer.SetQueryTextsForMatchingFormLists(ThisObject);
	
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductTypeWhenChangedOnServer()
	
	SelectGoodsServer.WhenChangingTypeOfProductItem(ThisObject);
	
	If UseFilters
			And (NavigationOption = Enums.ItemFormNavigationOptions.ByProperties
				Or NavigationOption = Enums.ItemFormNavigationOptions.ByKindsAndProperties
				Or NavigationOption = Enums.ItemFormNavigationOptions.ByKinds)
			And ProductKind = ProductsKindBeforeChange Then
			
			SelectGoodsServer.GoToListOfProducts(ThisObject);
			SelectGoodsServer.SetQueryTextsForMatchingFormLists(ThisObject);
	
	EndIf;
		
EndProcedure

&AtServer
Procedure WhenChangingVendorPriceRangeOnServer()
	
	SelectGoodsClientServer.SetSelectionBySupplierPriceRange(ThisObject);
	
EndProcedure

&AtServer
Procedure ProductItemSegmentWhenChangedOnServer()
	
	SelectGoodsServer.WhenProductItemSegmentChanges(ThisObject);
	
EndProcedure

&AtServer
Procedure SupplierPriceViewWhenChangedOnServer()
	
	SelectGoodsServer.WhenChangingSupplierSPriceType(ThisObject);
	
EndProcedure

&AtServer
Procedure OnlyInStockOnChangeAtServer()
	
	SelectGoodsServer.SetQueryTextsForMatchingFormLists(ThisObject);
	SelectGoodsServer.SetFilterOnlyInStock(ThisObject);
	
EndProcedure

&AtServer
Procedure SelectionTreeSelectionWhenModifiedOnServer()
	
	SelectGoodsServer.FilterTreeFilterOnChange(ThisObject);
	
EndProcedure

&AtServer
Procedure SourceQualityProductsWhenChangedOnServer()
	
	SelectGoodsServer.ProductsOfOriginalQualityOnChange(ThisObject);
	
EndProcedure

&AtServer
Procedure QualityListFlaggedWhenChangedOnServer()
	
	SelectGoodsServer.QualityListTaggingOnChange(ThisObject);
	
EndProcedure

&AtServer
Procedure SaveFormSettingsOnServer()
	
	SelectGoodsServer.SaveSelectionFormSettings(ThisObject);
	
EndProcedure

&AtServer
Procedure ProductsOfDifferentQualityOnServer()
	
	SelectGoodsServer.EstablishSelectionForProductsOfDifferentQuality(ThisObject);
	
EndProcedure

&AtServer
Procedure ResetSelectionsByPropertiesOnServer()
	
	SelectGoodsServer.ResetFiltersByProperties(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenWritingNewProductOnServer(NewProductItem)
	
	SelectGoodsServer.WhenWritingNewProductItem(ThisObject, NewProductItem);
	
EndProcedure

&AtServer
Procedure WhenRecordingNewCharacteristicOnServer(NewFeatureElement)
	
	SelectGoodsServer.WhenRecordingNewCharacteristic(ThisObject, NewFeatureElement);
	
EndProcedure

&AtServer
Function ParametersForCreatingNewProductItemOnServer()
	
	Return SelectGoodsServer.ParametersForCreatingNewProductItem(ThisObject);
	
EndFunction

&AtServer
Function ParametersForCreatingNewCharacteristicOnServer()
	
	Return SelectGoodsServer.ParametersForCreatingNewCharacteristic(ThisObject);
	
EndFunction

&AtServer
Function AddressOfDataForCalculatingManualDiscountsForSelectionInTemporaryStorageOnServer(ProductParameters_1)
	
	Return SelectGoodsServer.AddressOfDataForCalculatingManualDiscountsForMatchingInTemporaryStorage(ThisObject, ProductParameters_1);
	
EndFunction

&AtServer
Procedure ProductsWithSimilarPropertiesOnServer()
	
	SelectGoodsServer.WhenChangingDisplayOfItemWithSimilarProperties(ThisObject);
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
