#Region Variables

&AtClient
Var CachedValues; //current nomenclature to be passed to wait handlers

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
	
	If Parameters.Document = Undefined Then
		Raise NStr("vi = 'Chỉ có thể mở bộ xử lý từ chứng từ.';
					|ru = 'Предусмотрено открытие обработки только из документов.';
					|en = 'Data processor can be opened only from documents.'; fa = 'Data processor can be opened only from documents.';
					|it = 'Viene fornita l''apertura dell''elaborazione solo dalle forme dei documenti';
					|pl = 'Przewidziano otwarcie przetwarzania tylko z dokumentów.';
					|tr = 'Yalnızca belgelerden işlem açmak için provizyon sağlanmıştır.'");
	EndIf;
	
	CurrentSessionDate = CurrentSessionDate();
	
	FormCode = "Processing_SelectionOfGoodsInSalesDocument_Form";
	
	SelectionModeByProductRange = Parameters.SelectionModeByProductRange;
	SelectionModeForRetailSales = Parameters.SelectionModeForRetailSales;
	LimitSupplyOptions = Parameters.LimitSupplyOptions;
	
	Parameters.Property("SelectSupplyOptions", SelectSupplyOptions);
	Parameters.Property("ObjectForStoringSalesTermsAndConditions", ObjectForStoringSalesTermsAndConditions);
	
	ValidSeparateActionsFromParameter.LoadValues(
		Parameters.AcceptableSeparateActions.UnloadValues());
	ValidNonIsolatedActionsFromParameter.LoadValues(
		Parameters.AllowedNonIsolatedActions.UnloadValues());
	Parameters.Property("ControlledLotReference", ControlledLotReference);
	
	
	SelectGoodsServer.WhenCreatingMatchingFormOnServer(ThisObject);
	FillPropertyValues(FormSettingsWhenOpening, ThisObject);
	
	If Not Parameters.Property("SeriesSpecificationParameters",SeriesSpecificationParameters) Then
		Items.junkSeries.Visible = False;
	EndIf;
	
	If TheModeOfSelectionForDocumentsPricing Then
		Items.junkCharacteristic.Visible = False;
	EndIf;
	
	DocumentRef = Parameters.Document;
	Parameters.Property("Purpose", Purpose);
	Parameters.Property("Department", Department);
	Parameters.Property("Organization", Organization);
	
	SecurityOptionAndFlagSeparately = Parameters.SecurityOptionAndFlagSeparately;
	UseOrderSupplyWithAssignment = GetFunctionalOption("UseOrderSupplyWithAssignment");
	
	Warehouse = Parameters.Warehouse;
	
	TheShipmentDateOfAllLinesIsASingleDate = ProvisionInDocumentsServer.TheShipmentDateOfAllLinesIsASingleDate(
		Parameters.AvailableRemainingDocumentParameters);
		
	If ValueIsFilled(Parameters.TitleOfCheckBoxIsOnlyAvailable) Then
		Items.OnlyInStock.Title = Parameters.TitleOfCheckBoxIsOnlyAvailable;
	EndIf;
	
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
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If SelectGoodsClient.SavingSettingsIsRequired(ThisObject) Then
		SaveFormSettingsOnServer();
	EndIf;
		
	If MoveToDocument Then
		GoodsAddressInStorage = GoodsAddressInStorage(FormOwner.UUID);
	Else
		GoodsAddressInStorage = Undefined;
	EndIf;
	
	If GoodsAddressInStorage <> Undefined Then
		
		Structure = New Structure("GoodsAddressInStorage", GoodsAddressInStorage);
		Structure.Insert("TheShipmentDateOfAllLinesIsASingleDate", TheShipmentDateOfAllLinesIsASingleDate);
		
		ProvisionInDocumentsClient.InsertParametersOfSelectedProducts(
			Structure,
			Object.junk,
			TheShipmentDateOfAllLinesIsASingleDate);
		
		NotifyChoice(Structure);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	KeyOperation = "DataProcessor.SelectGoodsToSalesDocument.Form.Event.NotificationProcessing";
	PerformanceMonitorClient.TimeMeasurement(KeyOperation);
	
	If EventName = "Closing_EditingSet"
		And Parameter.OwnerForm = UUID Then
		AtEndOfEditingSet(Parameter.AddressInTempStorage);

		If UseItemsSoldTogether Then
			EstablishVisibilityOfProductSelectionTeamSoldJointly();
		EndIf;
	EndIf;
	
	If EventName = "EditSet"
		And Parameter.OwnerForm = UUID Then
		
		KitParameters = New Structure;
		KitParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
		KitParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		KitParameters.Insert("DialColumns", DialColumns(ThisObject));
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("ProductsInSet",   Parameter.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		OpeningParameters.Insert("Currency", Currency);
		OpeningParameters.Insert("Partner", Partner);
		OpeningParameters.Insert("Terms", Terms);
		OpeningParameters.Insert("Date", Date);
		OpeningParameters.Insert("ProhibitionOfSetContent", ProhibitionOfSetContent);
		OpeningParameters.Insert("ProhibitPriceEditing", ProhibitionOfEditingSetPrice);
		OpeningParameters.Insert("RecalculateAmounts", True);
		OpeningParameters.Insert("Warehouse", Object.Warehouse);
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
	
	EndIf;
	
	If EventName = "Write_Products"
		And Parameter.ThisIsNewProduct Then
		If ValueIsFilled(SearchStringProducts) Then
			SearchForProducts();
		EndIf;
		NameOfProductList = SelectGoodsClientServer.NameOfListOfProductsBySearchOption(ThisObject);
		ProductFormTable = Items[NameOfProductList]; // FormTable
		ProductFormTable.CurrentRow = Source;
		
		FormParameters = WhenWritingNewProductOnServer(Source);
		
		If GoodsForAddingToTheCart <> Undefined Then
			GoodsForAddingToTheCart.Warehouse = Warehouse;
			AddToCart(GoodsForAddingToTheCart, FormParameters);
			GoodsForAddingToTheCart = Undefined;
		EndIf;
	EndIf;

	If EventName = "Write_ItemsCharacteristics"
		And Parameter.ThisIsNewCharacteristic Then
		
		FormParameters = WhenRecordingNewCharacteristicOnServer(Source);
		
		If GoodsForAddingToTheCart <> Undefined Then
			GoodsForAddingToTheCart.Warehouse = Warehouse;
			AddToCart(GoodsForAddingToTheCart, FormParameters);
			GoodsForAddingToTheCart = Undefined;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	EventName = "DataProcessor.SelectGoodsToSalesDocument.Form.Event.ChoiceProcessing";
	PerformanceMonitorClient.TimeMeasurement(EventName);

	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		CurrentData = Items.junk.CurrentData;
		CurrentData.Series = ValueSelected.Value;
		
		ProductsSeriesRecalculatePrices(CurrentData);
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

#EndRegion

#Region EventHandlersForExactMatchFlags

&AtClient
Procedure FindAnItemByExactMatchOnChange(Item)
	
	SearchForProducts();
	
EndProcedure

&AtClient
Procedure FindCharacteristicsByExactMatchOnChange(Item)
	
	SearchForCharacteristics();
	
EndProcedure

#EndRegion

#Region EventHandlersSeparateFlags

&AtClient
Procedure ApartFromStandardSearchNomenclatureOnChange(Item)
	
	WithAssignmentOnChange();
	
EndProcedure

&AtClient
Procedure StandAloneStandardFeatureSearchOnChange(Item)
	
	WithAssignmentOnChange();
	
EndProcedure

&AtClient
Procedure SeparatelyAdvancedSearchNomenclatureOnChange(Item)
	
	WithAssignmentOnChange();
	
EndProcedure

&AtClient
Procedure SeparatelyAdvancedFeatureSearchOnChange(Item)
	
	WithAssignmentOnChange();
	
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
Procedure FilterPriceUpToOnChange(Item)
	
	SelectGoodsClientServer.SetSelectionByPriceRange(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterPriceFromOnChange(Item)
	
	SelectGoodsClientServer.SetSelectionByPriceRange(ThisObject);
	
EndProcedure

&AtClient
Procedure SegmentOnChange(Item)
	
	ProductItemSegmentWhenChangedOnServer();
	
	If ValueIsFilled(SearchStringProducts) Then
		SearchForProducts();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnlyInStockOnChange(Item)
	
	OnlyInStockOnChangeAtServer();
	
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

#Region FormTableItemsEventHandlersjunk

&AtClient
Procedure junkProductsOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	CurrentRow.Series = Undefined;
	CurrentRow.SupplyOption = Undefined;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner",    CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	SupplementStructureWithPriceCalculationActions(ThisObject, StructureOfActions, CurrentRow);
	
	SupplementStructureWithActionsForRecalculatingAmounts(StructureOfActions);
	StructureOfActions.Insert("FillInFlagForWhetherThereIsProductSoldJointly", AnalysisOptionOfProductsSoldTogether);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	FillInCollateralOptionAndFlagOnClient(CurrentRow);
	
	DownloadSelectionListOfSecurityOptions();
	
	If ValueIsFilled(SeriesSpecificationParameters) Then
		If Not CheckSetStatusOfBatches(CurrentRow, SeriesSpecificationParameters) Then
			FillInStatusesOfSpecifyingSeriesById(CurrentRow.GetID());
		EndIf;
	EndIf;

	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	
EndProcedure

&AtClient
Procedure junkSupplyOptionOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	CurrentRow.Series = Undefined;
	
	If ValueIsFilled(SeriesSpecificationParameters) Then
		If Not CheckSetStatusOfBatches(CurrentRow, SeriesSpecificationParameters) Then
			FillInStatusesOfSpecifyingSeriesById(CurrentRow.GetID());
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure junkSupplyOptionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure junkWithAssignmentOnChange(Item)
	
	DownloadSelectionListOfSecurityOptions();
	
	CurrentRow = Items.junk.CurrentData;
	If Items.junkSupplyOption.ChoiceList.FindByValue(CurrentRow.SupplyOption) = Undefined Then
		CurrentRow.SupplyOption = Items.junkSupplyOption.ChoiceList[0].Value;
	EndIf;
	
	CurrentRow.Series = Undefined;
	
	If ValueIsFilled(SeriesSpecificationParameters) Then
		If Not CheckSetStatusOfBatches(CurrentRow, SeriesSpecificationParameters) Then
			FillInStatusesOfSpecifyingSeriesById(CurrentRow.GetID());
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure junkSupplyOptionStartChoice(Item, ChoiceData, StandardProcessing)
	
	DownloadSelectionListOfSecurityOptions();
	
EndProcedure

&AtClient
Procedure junkCharacteristicOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	CurrentRow.Series = Undefined;
	
	StructureOfActions = New Structure;
	
	SupplementStructureWithPriceCalculationActions(ThisObject, StructureOfActions, CurrentRow);
	
	SupplementStructureWithActionsForRecalculatingAmounts(StructureOfActions);
	StructureOfActions.Insert("FillInFlagForWhetherThereIsProductSoldJointly", AnalysisOptionOfProductsSoldTogether);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	
EndProcedure

&AtClient
Procedure junkNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	SupplementStructureWithActionsForRecalculatingAmounts(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	
EndProcedure

&AtClient
Procedure junkPackageOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	SupplementStructureWithPriceCalculationActions(ThisObject, StructureOfActions, CurrentRow);
	
	SupplementStructureWithActionsForRecalculatingAmounts(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	
EndProcedure

&AtClient
Procedure junkPriceKindOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	PriceFillingStructure = New Structure;
	PriceFillingStructure.Insert("Date",
		?(ValueIsFilled(Date),
			Date,
			CurrentSessionDate));
	
	PriceFillingStructure.Insert("Currency", Currency);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", PriceFillingStructure);
	
	SupplementStructureWithActionsForRecalculatingAmounts(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	
EndProcedure

&AtClient
Procedure junkPriceOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	StructureOfActions = New Structure;
	SupplementStructureWithActionsForRecalculatingAmounts(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	
EndProcedure

&AtClient
Procedure junkSumOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfPriceConversion = New Structure("UseManualDiscounts");
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales",StructureOfPriceConversion);
	
	BatchProcessingOfTablePartClient.ProcessTSString(Items.junk.CurrentData, StructureOfActions, CachedValues);
	
	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	
EndProcedure

&AtClient
Procedure junkDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	DragToTrashOnServer(DragParameters.Value);
	
	If Not UseItemsSoldTogether Then	
		SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	Else
		EstablishVisibilityOfProductSelectionTeamSoldJointly();
	EndIf;
	
EndProcedure

&AtClient
Procedure junkPercentRateOfManualDiscountOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	SupplementStructureWithActionsForRecalculatingAmounts(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	
EndProcedure

&AtClient
Procedure junkManualDiscountOnChange(Item)
	
	CurrentRow = Items.junk.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount");
	SupplementStructureWithActionsForRecalculatingAmounts(StructureOfActions, False);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	
EndProcedure

&AtClient
Procedure junkOnChange(Item)
	
	If UseItemsSoldTogether Then
		WhenChangingBucketOnServer();
		EstablishVisibilityOfProductSelectionTeamSoldJointly();
	Else	
		SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure junkSelection(Item, RowSelected, Field, StandardProcessing)
	
	If SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.junk.FindByID(RowSelected);
		
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			KitParameters = New Structure;
			KitParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
			KitParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			KitParameters.Insert("DialColumns", DialColumns(ThisObject));
			
			SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
			
			OpeningParameters = New Structure;
			OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
			OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
			OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
			OpeningParameters.Insert("Currency", Currency);
			OpeningParameters.Insert("Partner", Partner);
			OpeningParameters.Insert("Terms", Terms);
			OpeningParameters.Insert("Date", Date);
			OpeningParameters.Insert("ProhibitionOfSetContent", ProhibitionOfSetContent);
			OpeningParameters.Insert("ProhibitPriceEditing", ProhibitionOfEditingSetPrice);
			OpeningParameters.Insert("RecalculateAmounts", True);
			OpeningParameters.Insert("FilterByProductType", FilterByProductType.UnloadValues());
			OpeningParameters.Insert("Warehouse", Object.Warehouse);
			OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
			
			OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
		
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure junkBeforeDeleteRow(Item, Cancel)
	
	SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "junk", Cancel);
	
EndProcedure

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

&AtClient
Procedure ProductHierarchyWhenActivatingWaitHandlerLine()
	
	SelectGoodsClient.HandlerForActivatingLineInProductHierarchy(ThisObject);
	
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
	
	ProductParameters_1.DateOfShipment = RowOfRemainderTable.Period;
	ProductParameters_1.NumberOfPackages = 1;
	
	FormParameters = New Structure();
	FormAndProductParametersOnServer(FormParameters, ProductParameters_1);
	
	AddToCart(ProductParameters_1, FormParameters);
	
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
	
	EventName = "DataProcessor.SelectGoodsToSalesDocument.Form.Event.SelectionTableCharacteristicsSelectionCompletion";
	PerformanceMonitorClient.TimeMeasurement(EventName);
	
	CharacteristicsTableRow = AdditionalParameters.Item.CurrentData;
	If CharacteristicsTableRow = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	ProductParameters_1 = GetProductParametersBeforeAddingToCart(FormParameters);
	FillPropertyValues(ProductParameters_1, CharacteristicsTableRow);
	
	AddToCart(ProductParameters_1, FormParameters);
	
EndProcedure

&AtClient
Procedure SelectionTableCharacteristicsStartOfDragging(Item, DragParameters, Perform)
	
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
	
	ClearMessages();
	
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
	
	EventName = "DataProcessor.SelectGoodsToSalesDocument.Form.Event.SelectionOfTableItemSelectionCompletion";
	PerformanceMonitorClient.TimeMeasurement(EventName);
	
	RowOfProductTable = AdditionalParameters.Item.CurrentData;
	
	If RowOfProductTable.IsFolder Then
		Return;
	EndIf;
	
	If (TheModeOfSelectionForDocumentsPricing) 
		Or Not (UseItemVariants And RowOfProductTable.ItemVariantsAreUsed) Then
		
		FormParameters = New Structure;
		ProductParameters_1 = GetProductParametersBeforeAddingToCart(FormParameters);
		
		AddToCart(ProductParameters_1, FormParameters);
		
	
	Else
		
		GoToListOfCharacteristics();
		SelectGoodsClient.AfterGoingToListOfCharacteristics(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StartDragList(Item, DragParameters, Perform)
	
	DragParameters.AllowedActions = DragAllowedActions.Copy;
	
	SelectGoodsClient.GetDragAndDropData(ThisObject, Item, DragParameters);
	
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
Procedure SetTheCurrentItemTrash(Command)
	
	SelectGoodsClient.SetTheCurrentItemTrash(ThisObject);
	
EndProcedure

&AtClient
Procedure SetTheCurrentSearchBarItem(Command)
	
	SelectGoodsClient.SetTheCurrentSearchBarItem(ThisObject);
	
EndProcedure

&AtClient
Procedure ChangeDoNotRequestQuantity(Command)
	
	RequestQuantity = False;
	RequestPrice = False;
	Items.NotRequestQuantity.Check = True;
	Items.RequestQuantity.Check = False;
	Items.RequestQuantityPrice.Check = False;
	
EndProcedure

&AtClient
Procedure ChangeRequestQuantity(Command)
	
	If Items.RequestQuantityPrice.Visible Then
		RequestPrice = False;
		RequestQuantity = True;
		Items.NotRequestQuantity.Check = False;
		Items.RequestQuantity.Check = True;
		Items.RequestQuantityPrice.Check = False;
	Else
		RequestQuantity = Not RequestQuantity;
		Items.NotRequestQuantity.Check = False;
		Items.RequestQuantity.Check = RequestQuantity;
		Items.RequestQuantityPrice.Check = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeRequestQuantityAndPrice(Command)
	
	RequestQuantity = True;
	RequestPrice = True;
	Items.NotRequestQuantity.Check = False;
	Items.RequestQuantity.Check = False;
	Items.RequestQuantityPrice.Check = True;
	
EndProcedure

&AtClient
Procedure Search(Command)
	
	CurMessageToUser = "";
	
EndProcedure

&AtClient
Procedure MoveToDocument(Command)
	
	If Not CheckFillingOfBasket() Then
		Return;
	EndIf;
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcesor.SelectGoodsToSalesDocument.Form.Form.MoveToDocument");
	MoveToDocument = True;
	Close(DialogReturnCode.OK);
	
EndProcedure

&AtClient
Procedure ItemsPrices(Command)
	
	SelectGoodsClient.ItemsPrices(ThisForm);
	
EndProcedure

&AtClient
Procedure OpenGoodsProfile(Command)
	
	SelectGoodsClient.OpenGoodsProfile(ThisObject);
	
EndProcedure

&AtClient
Procedure ChangeTheItem(Command)
	
	SelectGoodsClient.OpenGoodsProfile(ThisObject);
	
EndProcedure

&AtClient
Procedure WithTheSelectedItemItIsJointlySold(Command)
	
	WithSelectedProductsJointlySoldOnServer();
	
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
Procedure CreateNewProducts(Command)
	
	OpenForm("Catalog.Products.ObjectForm", New Structure("AdditionalParameters", ParametersForCreatingNewProductItemOnServer()), ThisObject);
	
EndProcedure

&AtClient
Procedure CreateNewCharacteristic(Command)
	
	OpenForm("Catalog.ItemsCharacteristics.ObjectForm",
		New Structure("AdditionalParameters", ParametersForCreatingNewCharacteristicOnServer()), ThisObject);
	
EndProcedure

&AtClient
Procedure ResetFiltersByProperties(Command)
	
	ResetSelectionsByPropertiesOnServer();
	
EndProcedure

&AtClient
Procedure SetComposition(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.SelectGoodsToSalesDocument.Form.Command.SetComposition");
	
	ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
	
	If CharacteristicNavigation Then
		CharacteristicsTableRow = Items[SelectGoodsClientServer.NameOfListOfCharacteristicsBySearchOption(ThisObject)].CurrentData;
		
		If CharacteristicsTableRow = Undefined Then
			Return;
		EndIf;
		
		FillPropertyValues(ProductParameters_1, CharacteristicsTableRow);
	Else
		
		If CurrentLineOfProducts = Undefined Then
			Return;
		EndIf;
		
		FillPropertyValues(ProductParameters_1, CurrentLineOfProducts);
	EndIf;
	
	If ProductParameters_1.ItemsType <> PredefinedValue("Enum.ItemsTypes.Set") Then
		ShowMessageBox(Undefined, NStr("vi = 'Cho phép xem thành phần bộ chỉ đối với mặt hàng kiểu ""Bộ""';
										|ru = 'Просмотр состава набора доступен только для номенклатуры типа ""Набор""';
										|en = 'Set content is available only for items of the ""Set"" type'; fa = 'Set content is available only for items of the ""Set"" type';
										|it = 'L''elenco dei set di visualizzazione è disponibile solo per la voce di tipo ""Set"".';
										|pl = 'Przeglądanie składu zestawu jest dostępne tylko dla nomenklatury rodzaju ""Zestaw""';
										|tr = 'Küme içeriğinin görüntülenmesi yalnızca ""Küme"" tipi öğeler için kullanılabilir'"));
		Return;
	EndIf;
	
	ProductParameters_1.NumberOfPackages = 1;
	
		FormParameters = New Structure;
		
		FormParameters.Insert("Products",                      ProductParameters_1.Products);
		FormParameters.Insert("Characteristic",                    ProductParameters_1.Characteristic);
		FormParameters.Insert("PriceKind",                           ProductParameters_1.PriceKind);
		FormParameters.Insert("ControlledLotReference",              ControlledLotReference);
		FormParameters.Insert("Partner",                           Partner);
		FormParameters.Insert("Terms",                        Terms);
		FormParameters.Insert("Package",                          ProductParameters_1.Package);
		FormParameters.Insert("Price",                              ProductParameters_1.Price);
		FormParameters.Insert("Warehouse",                             ProductParameters_1.Warehouse);
		FormParameters.Insert("DateOfShipment",                      ProductParameters_1.DateOfShipment);
		FormParameters.Insert("ItemsType",                   ProductParameters_1.ItemsType);
		FormParameters.Insert("Date",                              Date);
		FormParameters.Insert("Currency",                            Currency);
		FormParameters.Insert("HidePrice",                        SelectionModeWithoutAmountParameters);
		FormParameters.Insert("EditPriceType",              Items.junkPriceKind.Visible);
		FormParameters.Insert("UseShipmentDates",          UseShipmentDates);
		FormParameters.Insert("UseWarehousesInTheTablePart", SelectionModeUseWarehousesInTabularSection);
		FormParameters.Insert("UsePriceManagementSystem25",     UsePriceManagementSystem25);
		FormParameters.Insert("PriceIncludesVAT",                   Object.PriceIncludesVAT);
		FormParameters.Insert("HideManualDiscounts",              HideManualDiscounts Or SelectionModeWithoutAmountParameters);
		FormParameters.Insert("UseDiscountAdjustmentsInSales", UseDiscountAdjustmentsInSales);
		FormParameters.Insert("Warehouses",                            Warehouses.UnloadValues());
		FormParameters.Insert("TypesOfPrices",                           TypesOfPrices.UnloadValues());
		FormParameters.Insert("ShowBalance",                 ShowBalance);
		
		If UseDiscountAdjustmentsInSales Then
			AddressInTempStorage = AddressOfDataForCalculatingManualDiscountsForSelectionInTemporaryStorageOnServer(ProductParameters_1);
		Else
			AddressInTempStorage = Undefined;
		EndIf;
		
		FormParameters.Insert("AddressInTempStorage", AddressInTempStorage);
		
		NewDescriptionOfAlert = New CallbackDescription(
			"SetCompositionCompletion",
			ThisObject,
			New Structure("ProductParameters_1", ProductParameters_1));
			
		OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form.SetComposition",
			FormParameters,
			ThisObject,
			,
			,
			,
			NewDescriptionOfAlert,
			FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetCompositionCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	SelectedGoods	= Result.SelectedGoods;
	ProductParameters_1		= AdditionalParameters.ProductParameters_1;
	NewLines			= New Array;
	
	For Each SelectedGoodItem In SelectedGoods Do
		NewRow = SelectGoodsClientServer.ProductParameters_1();
		
		FillPropertyValues(NewRow, ProductParameters_1);
		FillPropertyValues(NewRow, SelectedGoodItem);
		
		NewLines.Add(NewRow);
	EndDo;
	
	AddToCartOnClient(ProductParameters_1, NewLines);
	
EndProcedure

#Region PricesAndDiscounts

&AtClient
Procedure AutoTestFillInPricesByAgreement(Command) Export

	If Object.junk.Count() = 0 Then
		
		WarningText = NStr("vi = 'Chưa điền giỏ hàng. Không thể điền đơn giá.';
							|ru = 'Корзина не заполнена. Цены не могут быть заполнены.';
							|en = 'The shopping cart is empty. Cannot fill in the prices.'; fa = 'The shopping cart is empty. Cannot fill in the prices.';
							|it = 'Il carrello non è pieno. I prezzi non possono essere compilati.';
							|pl = 'Koszyk nie jest wypełniony. Ceny nie mogą być wypełnione.';
							|tr = 'Sepet doldurulmadı. Fiyatlar doldurulamaz.'");
		ShowMessageBox(, WarningText);
		Return;
		
	EndIf;
		
	PricesCalculated = FillThePricesByTermsOfSalesServer();
	SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceType(Command)

	If Object.junk.Count() = 0 Then
		
		WarningText = NStr("vi = 'Chưa điền giỏ hàng. Không thể điền đơn giá.';
							|ru = 'Корзина не заполнена. Цены не могут быть заполнены.';
							|en = 'The shopping cart is empty. Cannot fill in the prices.'; fa = 'The shopping cart is empty. Cannot fill in the prices.';
							|it = 'Il carrello non è pieno. I prezzi non possono essere compilati.';
							|pl = 'Koszyk nie jest wypełniony. Ceny nie mogą być wypełnione.';
							|tr = 'Sepet doldurulmadı. Fiyatlar doldurulamaz.'");
		ShowMessageBox(, WarningText);
		Return;
		
	EndIf;
	
	PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
	PriceSelectionOptions.CallbackDescription = 
		New CallbackDescription("FillInPricesOfSelectedRowsByPriceTypeCompletion", ThisObject);
	PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
	PriceSelectionOptions.UseWhileSellingToCustomers = True;
	PriceSelectionOptions.OwnerOfAnIndividualPriceType = ?(ToUseTermsOfSales, Terms, Partner);
	
	EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);

EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceTypeCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignAManualDiscount(Command)
	
	If Object.junk.Count() = 0 Then
		
		WarningText = NStr("vi = 'Chưa điền giỏ hàng. Không thể ấn định chiết khấu (phụ thu).';
							|ru = 'Корзина не заполнена. Ручная скидка (наценка) не может быть назначена.';
							|en = 'The shopping cart is empty. Cannot apply discount/markup adjustment.'; fa = 'The shopping cart is empty. Cannot apply discount/markup adjustment.';
							|it = 'Il carrello non è pieno.Sconto manuale (markup) non può essere assegnata.';
							|pl = 'Koszyk nie jest wypełniony. Ręczna zniżka (marża) nie może być przypisana.';
							|tr = 'Sepet doldurulmadı. İndirim (zam) düzeltmesi atanamaz.'");
		ShowMessageBox(, WarningText);
		Return;
		
	EndIf;
	
	AddressInTempStorage = AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(False);
	
	Notification = New CallbackDescription(
		"AssignAManualDiscountCompletion", 
		ThisObject, 
		New Structure("AddressInTempStorage", AddressInTempStorage));
	
	DiscountsMarkupsFillingClient.OpenFormForAssigningManualDiscounts(
		AddressInTempStorage,
		Currency,
		Notification);
	
EndProcedure

&AtClient
Procedure AssignAManualDiscountCompletion(AmountOfManualDiscountMarkUp, AdditionalParameters) Export 
	
	AddressInTempStorage = AdditionalParameters.AddressInTempStorage;
	
	If AmountOfManualDiscountMarkUp <> Undefined Then
		
		AssignManualDiscountOnServer(AmountOfManualDiscountMarkUp, AddressInTempStorage);
		DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins(AmountOfManualDiscountMarkUp, Currency);
		
	EndIf;

EndProcedure

&AtClient
Procedure AssignAManualDiscountForSelectedLines(Command)
	
	If Object.junk.Count() = 0 Then
		
		WarningText = NStr("vi = 'Chưa điền giỏ hàng. Không thể ấn định chiết khấu (phụ thu)';
							|ru = 'Корзина не заполнена. Ручная скидка (наценка) не может быть назначена';
							|en = 'The shopping cart is empty. Cannot apply discount/markup adjustment'; fa = 'The shopping cart is empty. Cannot apply discount/markup adjustment';
							|it = 'Il carrello non è pieno.Sconto manuale (markup) non può essere assegnata.';
							|pl = 'Koszyk nie jest wypełniony. Ręczna zniżka (marża) nie może być przypisana';
							|tr = 'Sepet doldurulmadı. İndirim (zam) düzeltmesi atanamaz'");
		ShowMessageBox(,WarningText);
		Return;
		
	EndIf;
	
	AddressInTempStorage = AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(True);
	
	Notification = New CallbackDescription(
		"AssignAManualDiscountForSelectedLinesCompletion", 
		ThisObject, 
		New Structure("AddressInTempStorage", AddressInTempStorage));
	
	DiscountsMarkupsFillingClient.OpenFormForAssigningManualDiscounts(
		AddressInTempStorage,
		Currency,
		Notification);
	
EndProcedure

&AtClient
Procedure AssignAManualDiscountForSelectedLinesCompletion(AmountOfManualDiscountMarkUp, AdditionalParameters) Export 
	
	AddressInTempStorage = AdditionalParameters.AddressInTempStorage;
	
	If AmountOfManualDiscountMarkUp <> Undefined Then
		
		AssignManualDiscountOnServer(AmountOfManualDiscountMarkUp, AddressInTempStorage, Items.junk.SelectedRows);
		DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins(AmountOfManualDiscountMarkUp, Currency);
		
	EndIf;

EndProcedure

&AtClient
Procedure CancelManualDiscounts(Command)
	
	If Object.junk.Count() = 0 Then
		
		WarningText = NStr("vi = 'Chưa điền giỏ hàng. Không thể hủy bỏ chiết khấu (phụ thu) thủ công';
							|ru = 'Корзина не заполнена. Ручные скидки (наценки) не могут быть отменены';
							|en = 'The shopping cart is empty. Cannot clear discount/markup adjustments'; fa = 'The shopping cart is empty. Cannot clear discount/markup adjustments';
							|it = 'Il carrello non è pieno.Sconti manuali (markup) non possono essere annullati.';
							|pl = 'Koszyk nie jest wypełniony. Ręczne zniżki (marże) nie mogą być anulowane';
							|tr = 'Sepet doldurulmadı. İndirim (zam) düzeltmesi iptal edilemez'");
		ShowMessageBox(,WarningText);
		Return;
		
	ElsIf Object.junk.Total("ManualDiscount") = 0 Then
		
		WarningText = NStr("vi = 'Trong giỏ, chưa điền số tiền chiết khấu thủ công. Không thể hủy bỏ chiết khấu thủ công (phụ thu)';
							|ru = 'В корзине не заполнена сумма ручной скидки. Ручные скидки (наценки) не могут быть отменены';
							|en = 'Discounts for the items weren''t adjusted. Cannot clear discount/markup adjustments'; fa = 'Discounts for the items weren''t adjusted. Cannot clear discount/markup adjustments';
							|it = 'Nel carrello non è compilato l''importo dello sconto manuale .Gli sconti manuali (markup) non possono essere annullati.';
							|pl = 'W koszyku nie jest wypełniona wartość ręcznej zniżki. Ręczne zniżki (marże) nie mogą zostać anulowane';
							|tr = 'Sepette indirim düzeltmesi tutarı doldurulmadı. İndirim (zam) düzeltmesi iptal edilemez'");
		ShowMessageBox(,WarningText);
		Return;
		
	EndIf;
	
	CancelManualDiscountsOnServer();
	DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins();
	
EndProcedure

#EndRegion


#Region PricingAndDiscounts

&AtServer
Function FillThePricesByTermsOfSalesServer(OnAllLines = False)
	
	If OnAllLines Then
		RowsArray = Undefined;
	Else
		RowsArray = New Array;
		For Each String In Items.junk.SelectedRows Do
			RowsArray.Add(Object.junk.FindByID(String));
		EndDo;
	EndIf;
	
	SetsServerCall.AddToFullSet(Object.junk, RowsArray);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	SupplementStructureWithActionsForRecalculatingAmounts(StructureOfActions);
	
	PriceFillingParameters = New Structure;
	PriceFillingParameters.Insert("Date",               Date);
	PriceFillingParameters.Insert("Currency",             Currency);
	PriceFillingParameters.Insert("Partner",            Partner);
	PriceFillingParameters.Insert("Terms",         Terms);
	PriceFillingParameters.Insert("VATTaxation", Object.VATTaxation);
	PriceFillingParameters.Insert("ReturnReusablePackage", ReturnReusablePackage);
	PriceFillingParameters.Insert("Organization",        Organization);
	PriceFillingParameters.Insert("CalculateSets", True);
	PriceFillingParameters.Insert("PopulationFields",     "Price, PriceKind, DeliveryPeriodDays");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.junk,
		RowsArray, // Array of rows or selection structure
		PriceFillingParameters, // The fill parameters
		StructureOfActions);
	
	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind)
	
	RowsArray = New Array;
	For Each String In Items.junk.SelectedRows Do
		RowsArray.Add(Object.junk.FindByID(String));
	EndDo;
	
	SetsServerCall.AddToFullSet(Object.junk, RowsArray);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions = New Structure;
	SupplementStructureWithActionsForRecalculatingAmounts(StructureOfActions);
	
	PriceFillingParameters = New Structure;
	PriceFillingParameters.Insert("Date",               Date);
	PriceFillingParameters.Insert("Currency",             Currency);
	PriceFillingParameters.Insert("PriceKind",            PricesKind);
	PriceFillingParameters.Insert("Organization",        Organization);
	PriceFillingParameters.Insert("CalculateSets", True);
	PriceFillingParameters.Insert("PopulationFields",     "Price, PriceKind");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.junk,
		RowsArray, // Array of rows or selection structure
		PriceFillingParameters, // The fill parameters
		StructureOfActions);
	
	SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(SelectedLinesOnly)
	
	ParametersStructure = DiscountsMarkupsFillingServer.NewParametersAddressDataForCalculatingManualDiscounts();
	ParametersStructure.TableName				 = "junk";
	ParametersStructure.OnlyForSelectedLines = SelectedLinesOnly;
	Return DiscountsMarkupsFillingServer.AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(
		ThisObject, UUID, ParametersStructure);
	
EndFunction

&AtServer
Procedure AssignManualDiscountOnServer(AmountOfDiscountMarkUp, AddressInTempStorage, Val SelectedRows = Undefined)
	
	DiscountParameters = DiscountsMarkupsFillingServer.NewOptionsAssignManualDiscount();
	DiscountParameters.AutomaticDiscountsAreUsed = True;
	DiscountParameters.OnlyForActiveRows			 = False;
	DiscountParameters.CalculateAmountWithVAT			 = True;
	DiscountParameters.SelectedRows				 = SelectedRows;
	DiscountParameters.AddressInTempStorage		 = AddressInTempStorage;
	
	DiscountsMarkupsFillingServer.AssignAManualDiscount(Object, "junk", AmountOfDiscountMarkUp, DiscountParameters);
	
EndProcedure

&AtServer
Procedure CancelManualDiscountsOnServer()
	
	DiscountsMarkupsFillingServer.CancelManualDiscounts(Object, "junk", True, True);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SupplementStructureWithActionsForRecalculatingAmounts(StructureOfActions, RecalculateAmountOfManualDiscount_ = True)
	
	RecalculationParameters = New Structure;
	RecalculationParameters.Insert("Clear", False);
	RecalculationParameters.Insert("RecalculateAmountOfManualDiscount_", RecalculateAmountOfManualDiscount_);
	
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", RecalculationParameters);
	StructureOfActions.Insert("RecalculateAmount");
		
EndProcedure

&AtClientAtServerNoContext
Procedure SupplementStructureWithPriceCalculationActions(Object, StructureOfActions, CurrentRow)

	ObjectDetails = New Structure;
	ObjectDetails.Insert("Date", ?(ValueIsFilled(Object.Date), Object.Date, Object.CurrentSessionDate));
	ObjectDetails.Insert("Currency", Object.Currency);
	ObjectDetails.Insert("PriceKind", PredefinedValue("Catalog.TypesOfPrices.EmptyRef"));
	If Object.TypesOfPrices.Count() And ValueIsFilled(Object.TypesOfPrices[0].Value) Then
		ObjectDetails.PriceKind = Object.TypesOfPrices[0].Value;
	EndIf;
	ObjectDetails.Insert("Partner",    Object.Partner);
	ObjectDetails.Insert("Terms", Object.Terms);
	ObjectDetails.Insert("Ref",     Undefined);

	If Object.OnlyOneSalePriceKind Then

		PriceFillingStructure = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(ObjectDetails, True);
		StructureOfActions.Insert("FillInSalePrice", PriceFillingStructure);

	ElsIf Object.ToUseTermsOfSales And ValueIsFilled(Object.Terms) 
		Or Not Object.ToUseTermsOfSales And ValueIsFilled(Object.Partner) And Object.UsePartnersAndCounterparties Then
		
		StructureOfFillingInSalesConditions = BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(ObjectDetails);
		StructureOfActions.Insert("FillIn_TermsOfSales", StructureOfFillingInSalesConditions);
		
	ElsIf Object.SelectionModeForRetailSales Then

		StructureOfFillingInTermsOfRetailSales = BatchProcessingOfTablePartClientServer.GetStructureForFillingInRetailSalesTermsInTSLine(ObjectDetails, Object.ObjectForStoringSalesTermsAndConditions);
		StructureOfActions.Insert("FillInRetailSalesTermsAndConditions", StructureOfFillingInTermsOfRetailSales);

	ElsIf ValueIsFilled(CurrentRow.PriceKind)
				Or PriceManagementSystemServerCall.ItIsNecessaryToRecalculatePriceWhenChanging(CurrentRow.Products, "Series", Undefined) Then
		
		PriceFillingStructure = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(ObjectDetails, True);
		StructureOfActions.Insert("FillInSalePrice", PriceFillingStructure);
	
	EndIf;

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.junkPrice.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.junkSum.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.junk.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisObject, 
														"junkPriceKind", 
														"Object.junk.PriceKind");

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.junkIndexGoodsSoldTogether.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectionModeWithoutAmountParameters");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	If Not UserRightsCached.ThisIsPartner() Then
		
		Item = ConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchProductsInStockBalance.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchProductsAvailable.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchProductsInStockBalance.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchProductsAvailable.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ListProducts.ItemsType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.ItemsTypes.Set;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<xem bộ>';
														|ru = '<см. набор>';
														|en = '<see the set>'; fa = '<see the set>';
														|it = '<vedi set>';
														|pl = '<patrz zestaw>';
														|tr = '<kümeye bak>'"));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.HelpText);
	
	EndIf;
	
	//
	If GetFunctionalOption("UseSets") Then	
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchProductsPrice.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchProductsPrice.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ListProducts.SetPricingOption");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<xem bộ>';
														|ru = '<см. набор>';
														|en = '<see the set>'; fa = '<see the set>';
														|it = '<vedi set>';
														|pl = '<patrz zestaw>';
														|tr = '<kümeye bak>'"));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.HelpText);
	EndIf;
	//
	
	If Not UserRightsCached.ThisIsPartner() Then
	
		Item = ConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchCharacteristicsInStockBalance.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchCharacteristicsAvailable.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchCharacteristicsInStockBalance.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchCharacteristicsAvailable.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("FeatureList.ItemsType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.ItemsTypes.Set;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<xem bộ>';
														|ru = '<см. набор>';
														|en = '<see the set>'; fa = '<see the set>';
														|it = '<vedi set>';
														|pl = '<patrz zestaw>';
														|tr = '<kümeye bak>'"));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.HelpText);
	
	EndIf;
	
	//
	
	If GetFunctionalOption("UseSets") Then
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListAdvancedSearchCharacteristicsPrice.Name);
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListStandardSearchCharacteristicsPrice.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("FeatureList.SetPricingOption");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<xem bộ>';
														|ru = '<см. набор>';
														|en = '<see the set>'; fa = '<see the set>';
														|it = '<vedi set>';
														|pl = '<patrz zestaw>';
														|tr = '<kümeye bak>'"));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.HelpText);
	EndIf;
	
	//
	
	SetsServer.SetConditionalAppearance(ThisObject, "junk");
	
	//
	
	SelectGoodsServer.SetConditionalAppearanceOfDynamicLists(ThisObject);
	
	//
	
	SelectGoodsServer.SetConditionalAppearanceOfSelectionFormElements(ThisObject);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.junkSeries.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.junk.BatchesIndicationStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra sê-ri>';
													|ru = '<серия не указывается>';
													|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
													|it = '<serie non è indicata>';
													|pl = '<seria nie jest określana>';
													|tr = '<parti belirtilmemektedir>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	// The ability to change the flag Separately.
	If ValidNonIsolatedActionsFromParameter.Count() > 0
				And ValidSeparateActionsFromParameter.Count() = 0
			Or ValidNonIsolatedActionsFromParameter.Count() = 0
				And ValidSeparateActionsFromParameter.Count() > 0 Then
		
		Item = ConditionalAppearance.Items.Add();
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.junkWithAssignment.Name);
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
	EndIf;
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.junkWithAssignment.Name);
	
	VariantList = New ValueList();
	VariantList.Add(Enums.ItemsTypes.ReusablePackage);
	VariantList.Add(Enums.ItemsTypes.OperationService);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.junk.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = VariantList;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Restrictions for a set picked up in the basket in the Unbreakable Set mode
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.junkWithAssignment.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.junkSupplyOption.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.junkSeries.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.junk.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Set;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	RetailSalesLocalization.SetConditionalAppearance(ThisObject);
	
EndProcedure

#Region EventHandlersOnServer

&AtServer
Procedure ProductItemSegmentWhenChangedOnServer()
	
	SelectGoodsServer.WhenProductItemSegmentChanges(ThisObject);
	
EndProcedure

&AtServer
Procedure SourceQualityProductsWhenChangedOnServer()
	
	SelectGoodsServer.ProductsOfOriginalQualityOnChange(ThisObject);
	
EndProcedure

&AtServer
Procedure GoToListOfCharacteristics()

	SelectGoodsServer.GoToListOfCharacteristics(ThisObject);

EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure TableSelectionWhenActivatingWaitHandlerLine()
	
	SelectGoodsClient.GetProductInformationWhenSelling(ThisObject);
	
EndProcedure

&AtServer
Function AddToCartOnClient(ProductParameters_1, NewLines)
	
	EmptyShoppingCart = Object.junk.Count() = 0;
	FilterAttributes = "SKU, ProductsInSet, ItemVariantOfSet, Products, Characteristic,
		|ItemVariantsAreUsed, Package, Price, PriceKind, Warehouse, PercentRateOfManualDiscount, ItemsType,
		|DeliveryPeriodDays, SupplyOption, WithAssignment, Series";
	If UseShipmentDates Then
		FilterAttributes = FilterAttributes + ", DateOfShipment";
	EndIf;
	Filter = New Structure(FilterAttributes);
	
	IdsForSettingStatusOfSeries = New Array;
	RowsToProcess = New Array;
	ProcessedLinesWithError = New Array;
	ErrorOfLines = New Map();
	ProcessedRowsWithPrice = New Array;
	
	For Each NewRow In NewLines Do
		
		FillPropertyValues(Filter, NewRow);
		
		If Not ValueIsFilled(Filter.ItemsType) Then
			Filter.ItemsType = ProductParameters_1.ItemsType;
		EndIf;
		
		If Not ValueIsFilled(Filter.SupplyOption)
				And Not Filter.ItemsType = PredefinedValue("Enum.ItemsTypes.Set") Then
			FillInSecurityOptionAndFlagAtServer(Filter);
		EndIf;
		
		If EmptyShoppingCart Then
			SearchResult = New Array;
		Else
			SearchResult = Object.junk.FindRows(Filter);
		EndIf;
		
		TargetArray = RowsToProcess;
		
		If SearchResult.Count() = 0 Or NewRow.Error_ <> 0 Then
			
			CurrentRow = Object.junk.Add();
			FillPropertyValues(CurrentRow, Filter);
			CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
			
			TargetArray = ProcessedLinesWithError;
			ErrorOfLines.Insert(CurrentRow, NewRow.Error_);

			If Not ProductParameters_1.ItemsType = PredefinedValue("Enum.ItemsTypes.Set")
				And (SelectionModeWithoutAmountParameters 
				Or Not RequestPrice
				Or PriceManagementSystemServerCall.ItIsNecessaryToRecalculatePriceWhenChanging(CurrentRow.Products, "Series", Undefined)) Then
				
				TargetArray = ProcessedRowsWithPrice;

			EndIf;
			
		Else
			CurrentRow = SearchResult[0];
		EndIf;
		
		CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackages + NewRow.NumberOfPackages;
		
		TargetArray.Add(CurrentRow);
		
		If Not ShowSelectedGoods Then
			
			NotificationText1 = Chars.LF + NStr("vi = 'Hàng hóa ""[OwnGoods]"" với giá trị [Price] [Currency] số lượng [NumberOfPackages] [UnitOfMeasure] đã thêm vào giỏ';
												|ru = 'Товар ""[OwnGoods]"" стоимостью [Price] [Currency] в количестве [NumberOfPackages] [UnitOfMeasure] добавлен в корзину';
												|en = 'The ""[OwnGoods]"" goods of value [Price] [Currency] are added to the cart in quantity of [NumberOfPackages] [UnitOfMeasure]'; fa = 'The ""[OwnGoods]"" goods of value [Price] [Currency] are added to the cart in quantity of [NumberOfPackages] [UnitOfMeasure]';
												|it = 'La merce ""[OwnGoods]"" con valore  [Price] [Currency] in quantità [NumberOfPackages] [UnitOfMeasure] è aggiunto al carrello';
												|pl = 'Towar ""[OwnGoods]"" o wartości [Price][Currency] o ilości [NumberOfPackages] [UnitOfMeasure] został dodany do koszyka';
												|tr = '[Price] [Currency] değerinde [NumberOfPackages] [UnitOfMeasure] miktarında ürün ""[OwnGoods]"" sepete eklendi'");
			
			ValuesToInsert = New Structure("OwnGoods, Price, Currency, NumberOfPackages, UnitOfMeasure");
			
			ValuesToInsert.OwnGoods              = String(CurrentRow.Products) + ?(ValueIsFilled(NewRow.Characteristic)," (" + NewRow.Characteristic + ")","");
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
		
		CurrentRow.OrderToWarehouse = True;
		If ValueIsFilled(SeriesSpecificationParameters) Then
			If Not CheckSetStatusOfBatches(CurrentRow, SeriesSpecificationParameters) Then
				IdsForSettingStatusOfSeries.Add(CurrentRow.GetID());
			EndIf;
		EndIf;
		
	EndDo;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	SupplementStructureWithActionsForRecalculatingAmounts(StructureOfActions);

	StructureOfActionsWithError = Common.CopyRecursive(StructureOfActions, False);
	StructureOfActionsWithError.Insert("RecalculateAmountTakingIntoAccountRoundingError",
		New Structure("ErrorsByLines", ErrorOfLines));
		
	StructureOfActionsWithError.Insert("FillInFlagForWhetherThereIsProductSoldJointly",
		AnalysisOptionOfProductsSoldTogether);

	StructureOfActionsWithPrice = New Structure(); 
	If ProcessedRowsWithPrice.Count() Then
		StructureOfActionsWithPrice = Common.CopyRecursive(StructureOfActionsWithError, False);
		SupplementStructureWithPriceCalculationActions(ThisObject, StructureOfActionsWithPrice, ProcessedRowsWithPrice[0]);
	EndIf;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.junk,
		Undefined);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesWithError,
		StructureOfActionsWithError,
		Object.junk,
		Undefined);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedRowsWithPrice,
		StructureOfActionsWithPrice,
		Object.junk,
		Undefined);

	If IdsForSettingStatusOfSeries.Count() > 0 Then
		FillInStatusesOfSpecifyingSeriesById(IdsForSettingStatusOfSeries);
	EndIf;
	
	If NewLines.Count() > 0 Then
		Items.junk.CurrentRow = CurrentRow.GetID();
	EndIf;
	
	Return NotificationText1;
	
EndFunction

&AtServer
Function GetAddressOfTableOnServer()
	
	TablePickedUpEarlier = Object.junk.Unload();
	TablePickedUpEarlier.Columns.Add("Department");
	TablePickedUpEarlier.Columns.Add("Purpose");
	For Each String In TablePickedUpEarlier Do
		String.Department = Department;
		String.Purpose = ?(String.WithAssignment, Purpose, Catalogs.Assignments.EmptyRef());
	EndDo;
	Return PutToTempStorage(TablePickedUpEarlier, UUID)
	
EndFunction

&AtClient
Procedure AddToCart(ProductParameters_1, FormParameters = Undefined)
	
	If Not ValueIsFilled(ProductParameters_1) Then
		Return;
	EndIf;
	
	If RequestQuantity And Not ModeOfSelectionWithoutQuantitativeParameters Then
		
		If Not ValueIsFilled(FormParameters) Then
			FormParameters = New Structure;
		EndIf;
		
		FormParameters.Insert("Products",                      ProductParameters_1.Products);
		FormParameters.Insert("Characteristic",                    ProductParameters_1.Characteristic);
		FormParameters.Insert("PriceKind",                           ProductParameters_1.PriceKind);
		FormParameters.Insert("Partner",                           Partner);
		FormParameters.Insert("Terms",                        Terms);
		FormParameters.Insert("Package",                          ProductParameters_1.Package);
		FormParameters.Insert("Price",                              ProductParameters_1.Price);
		FormParameters.Insert("Warehouse",                             ProductParameters_1.Warehouse);
		FormParameters.Insert("DateOfShipment",                      ProductParameters_1.DateOfShipment);
		FormParameters.Insert("ItemsType",                   ProductParameters_1.ItemsType);
		FormParameters.Insert("Date",                              Date);
		FormParameters.Insert("Currency",                            Currency);
		FormParameters.Insert("HidePrice",                        SelectionModeWithoutAmountParameters Or Not RequestPrice);
		FormParameters.Insert("EditPriceType",              Items.junkPriceKind.Visible);
		FormParameters.Insert("Warehouses",                            Warehouses.UnloadValues());
		FormParameters.Insert("UseShipmentDates",          UseShipmentDates);
		FormParameters.Insert("UseWarehousesInTheTablePart", SelectionModeUseWarehousesInTabularSection);
		FormParameters.Insert("PriceIncludesVAT",                   Object.PriceIncludesVAT);
		FormParameters.Insert("HideManualDiscounts",              HideManualDiscounts Or SelectionModeWithoutAmountParameters Or Not RequestPrice);
		FormParameters.Insert("UseDiscountAdjustmentsInSales", UseDiscountAdjustmentsInSales);
		FormParameters.Insert("TypesOfPrices",                           TypesOfPrices.UnloadValues());
		FormParameters.Insert("ShowBalance",                 ShowBalance);
		FormParameters.Insert("WithoutFilterByVATInclusionInPrice",      WithoutFilterByVATInclusionInPrice);
		FormParameters.Insert("UsePriceManagementSystem25",     UsePriceManagementSystem25);
		FormParameters.Insert("WithoutFilterByUseWhileSellingToCustomersInPrice",      WithoutFilterByUseWhileSellingToCustomersInPrice);
		
		If (SelectSupplyOptions
				Or (Not (ProductParameters_1.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
				Or ProductParameters_1.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService")))
				And ((ProductParameters_1.BatchesIndicationStatus <> 0
					And ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(ProductParameters_1.BatchesIndicationStatus, SeriesSpecificationParameters))
				Or Warehouses.Count()>1))
			And (Not LimitSupplyOptions
			Or (Not (ProductParameters_1.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
				Or ProductParameters_1.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService"))))
			And Not HideCommandRemainingQuantityInWarehouses
			And (Not DoNotSplitSetsByComponents
				Or Not ProductParameters_1.ItemsType = PredefinedValue("Enum.ItemsTypes.Set"))
			And (ValueIsFilled(Warehouse) Or Warehouses.Count() > 0 Or AllWarehouseBalance) Then
			
				If ProductParameters_1.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
						Or ProductParameters_1.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
					
					NameOfQuantityRequestForm = "DataProcessor.QuantityAndBatchRequest.Form.FormForWorksAndServices";
					
				Else
					
					NameOfQuantityRequestForm = "DataProcessor.QuantityAndBatchRequest.Form";
					
				EndIf;
				
				AddressInTempStorage        = FormParameters.AddressInTempStorage;
				TableAddressSelectedEarlier       = FormParameters.TableAddressSelectedEarlier;
				
				FormParameters = ProvisionInDocumentsClientServer.ParametersOfQuantityAndSeriesRequestForm();
				
				FormParameters.SelectGoods                     = True;
				FormParameters.SelectSeries                       = ValueIsFilled(SeriesSpecificationParameters);
				FormParameters.SelectSupplyOptions        = SelectSupplyOptions;
				FormParameters.HidePrice                        = SelectionModeWithoutAmountParameters Or Not RequestPrice;
				FormParameters.UsePriceManagementSystem25     = UsePriceManagementSystem25;
				FormParameters.EditPriceType              = Items.junkPriceKind.Visible;
				FormParameters.HideManualDiscounts              = HideManualDiscounts Or SelectionModeWithoutAmountParameters Or Not RequestPrice;
				FormParameters.UseDiscountAdjustmentsInSales = UseDiscountAdjustmentsInSales;
				FormParameters.LimitSupplyOptions   = LimitSupplyOptions;
				FormParameters.Products                      = ProductParameters_1.Products;
				FormParameters.Characteristic                    = ProductParameters_1.Characteristic;
				FormParameters.Purpose                        = ?(ValueIsFilled(FilterByAssignment), FilterByAssignment, Purpose);
				FormParameters.ControlledLotReference              = ControlledLotReference;
				FormParameters.Department                     = Department;
				FormParameters.Warehouse                             = Warehouse;
				FormParameters.Warehouses                            = Warehouses.UnloadValues();
				FormParameters.TableAddressSelectedEarlier        = TableAddressSelectedEarlier;
				FormParameters.Recorder                       = DocumentRef;
				FormParameters.Price                              = ProductParameters_1.Price;
				FormParameters.PriceKind                           = ProductParameters_1.PriceKind;
				FormParameters.Package                          = ProductParameters_1.Package;
				FormParameters.Currency                            = Currency;
				FormParameters.Date                              = Date;
				FormParameters.PriceIncludesVAT                   = Object.PriceIncludesVAT;
				FormParameters.WithoutFilterByVATInclusionInPrice      = WithoutFilterByVATInclusionInPrice;
				FormParameters.Terms                        = Terms;
				FormParameters.Partner                           = Partner;
				FormParameters.AddressInTempStorage         = AddressInTempStorage;
				FormParameters.TheDisplayOfGoods           = ?(OnlyInStock, "AvailableStock", "All");
				
				ProductAttributes = ProductDetailsForFillingOutSecurityOption(ProductParameters_1.Products);
				FormParameters.WithAssignment = ProductAttributes.AssignedPurchaseSale Or WithAssignment;
				FormParameters.SecurityOptionAndFlagSeparately  = SecurityOptionAndFlagSeparately;
				FormParameters.Insert("DetachedSet", WithAssignment);
				
				Actions = AcceptableSeparateAndNonSeparateActionsOnClient(ProductAttributes.ItemsType);
				
				FormParameters.AllowedNonIsolatedActions  = Actions.AllowedNonIsolatedActions;
				FormParameters.AcceptableSeparateActions    = Actions.AcceptableSeparateActions;
				
				FormParameters.SeriesSpecificationParameters            = SeriesSpecificationParameters;
				
		Else
			If ProductParameters_1.ItemsType = PredefinedValue("Enum.ItemsTypes.Set")
					And Not DoNotSplitSetsByComponents Then
				NameOfQuantityRequestForm = "DataProcessor.SelectGoodsToSalesDocument.Form.SetComposition";
			Else
				NameOfQuantityRequestForm = "DataProcessor.SelectGoodsToSalesDocument.Form.QuantityRequest";
			EndIf;
		EndIf;
		
		OpenForm(NameOfQuantityRequestForm,
			FormParameters,
			ThisObject,,,,
			New CallbackDescription("AddToCartAfterSelectingQuantity", ThisObject, ProductParameters_1),
			FormWindowOpeningMode.LockOwnerWindow);
		
		Return;
		
	Else
		
		NewLines = New Array;
		
		If ProductParameters_1.ItemsType = PredefinedValue("Enum.ItemsTypes.Set")
			And (Not DoNotSplitSetsByComponents) 
			And Not (TheModeOfSelectionForDocumentsPricing And UsePriceManagementSystem25) Then
			
			ComponentParameters = SelectGoodsClientServer.ProductParameters_1();
			FillPropertyValues(ComponentParameters, ProductParameters_1);
			ComponentParameters.ProductsInSet   = ProductParameters_1.Products;
			ComponentParameters.ItemVariantOfSet = ProductParameters_1.Characteristic;
			If Warehouses.Count() = 1 Then
				ComponentParameters.Warehouse = Warehouses.Get(0).Value;
			EndIf;
			ComponentParameters.Insert("ItemKitConfiguration", Undefined);
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("Date", Date);
			AdditionalParameters.Insert("Organization", Organization);
			AdditionalParameters.Insert("Currency", Currency);
			AdditionalParameters.Insert("Warehouses", Warehouses.UnloadValues());
			AdditionalParameters.Insert("Terms", Terms);
			AdditionalParameters.Insert("Price", ProductParameters_1.Price);
			AdditionalParameters.Insert("PriceKind", ProductParameters_1.PriceKind);
			SelectedGoods = SetsServerCall.Components(ComponentParameters, AdditionalParameters);
			
			For Each SelectedGoodItem In SelectedGoods Do
				NewLines.Add(SelectedGoodItem);
			EndDo;
			
		Else
			NewRow = SelectGoodsClientServer.ProductParameters_1();
			FillPropertyValues(NewRow, ProductParameters_1);
			
			NewLines.Add(NewRow);
		EndIf;
		
	EndIf;
	
	AddToCartCompletion(ProductParameters_1, NewLines);
	
EndProcedure

&AtClient
Procedure AddToCartAfterSelectingQuantity(Result, AdditionalParameters) Export 
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	NewLines = New Array;
	
	For Each SelectedGoodItem In Result.SelectedGoods Do
		
		NewRow = SelectGoodsClientServer.ProductParameters_1();
		
		FillPropertyValues(NewRow, AdditionalParameters);
		FillPropertyValues(NewRow, SelectedGoodItem);
		
		NewLines.Add(NewRow);
		
	EndDo;
	
	AddToCartCompletion(AdditionalParameters, NewLines);
	
EndProcedure

&AtClient
Procedure AddToCartCompletion(ProductParameters_1, NewLines)
	
	NotificationText1 = AddToCartOnClient(ProductParameters_1, NewLines);
	
	If Not ShowSelectedGoods Then
		ShowUserNotification(NStr("vi = 'Thêm vào giỏ hàng';
									|ru = 'Товар добавлен в корзину';
									|en = 'The goods are added to the cart'; fa = 'The goods are added to the cart';
									|it = 'Merce aggiunta al carrello';
									|pl = 'Towar został dodany do koszyka';
									|tr = 'Ürün sepete eklendi'"), , NotificationText1);
	EndIf;
	
	If UseItemsSoldTogether Then
		WhenChangingBucketOnServer();
		EstablishVisibilityOfProductSelectionTeamSoldJointly();
	Else
		SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
		
		
	EndIf;
	
	// If the product was added to the cart when the search bar was filled in,
	// then return the input focus to the search bar.
	NameOfCurElementOfSearchString = SelectGoodsClient.NameOfCurElementOfSearchString(ThisObject);
	If ValueIsFilled(ThisObject[NameOfCurElementOfSearchString]) Then
		SelectGoodsClient.SetTheCurrentSearchBarItem(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure DragToTrashOnServer(Data)
	
	If TypeOf(Data) <> Type("Array") Then
		Return;
	EndIf;
	
	NewLines = New Array;
	For Each ProductParameters_1 In Data Do
		If ProductParameters_1.ItemsType = PredefinedValue("Enum.ItemsTypes.Set")
			And (Not DoNotSplitSetsByComponents) Then
			
			ComponentParameters = SelectGoodsClientServer.ProductParameters_1();
			FillPropertyValues(ComponentParameters, ProductParameters_1);
			ComponentParameters.ProductsInSet   = ProductParameters_1.Products;
			ComponentParameters.ItemVariantOfSet = ProductParameters_1.Characteristic;
			If Warehouses.Count() = 1 Then
				ComponentParameters.Warehouse = Warehouses.Get(0).Value;
			EndIf;
			ComponentParameters.Insert("ItemKitConfiguration", Undefined);
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("Date", Date);
			AdditionalParameters.Insert("Organization", Organization);
			AdditionalParameters.Insert("Currency", Currency);
			AdditionalParameters.Insert("Warehouses", Warehouses.UnloadValues());
			AdditionalParameters.Insert("Terms", Terms);
			AdditionalParameters.Insert("Price", ProductParameters_1.Price);
			AdditionalParameters.Insert("PriceKind", ProductParameters_1.PriceKind);
			SelectedGoods = SetsServerCall.Components(ComponentParameters, AdditionalParameters);
			
			For Each SelectedGoodItem In SelectedGoods Do
				NewLines.Add(SelectedGoodItem);
			EndDo;
			
		Else
			NewLines.Add(ProductParameters_1);
		EndIf;
	EndDo;

	EmptyShoppingCart = Object.junk.Count() = 0;
	LineDetails = "Products, Characteristic, SupplyOption, WithAssignment, Package,
		|Price, Count, NumberOfPackages, Sum, PriceKind, Warehouse, DateOfShipment, DeliveryPeriodDays,
		|IndexGoodsSoldTogether, PercentRateOfManualDiscount, ManualDiscount";
	RowParameters = New Structure(LineDetails);
	FilterAttributes = "SKU, ProductsInSet, ItemVariantOfSet, Products, Characteristic,
		|ItemVariantsAreUsed, Package, Price, PriceKind, Warehouse, PercentRateOfManualDiscount, ItemsType,
		|DeliveryPeriodDays, SupplyOption, WithAssignment, Series";
	If UseShipmentDates Then
		FilterAttributes = FilterAttributes + ", DateOfShipment";
	EndIf;
	Filter = New Structure(FilterAttributes);
	LinesForSettingStatusOfSeries = New Array;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	SupplementStructureWithActionsForRecalculatingAmounts(StructureOfActions);
	
	ProcessedRowsFound = New Array;
	ProcessedLinesAreNew = New Array;
	Errors_ = New Map();
	
	For Each NewRow In NewLines Do

		FillPropertyValues(Filter, NewRow);

		If Not ValueIsFilled(Filter.SupplyOption)
			And Not Filter.ItemsType = PredefinedValue("Enum.ItemsTypes.Set") Then
			FillInSecurityOptionAndFlagAtServer(Filter);
		EndIf;

		If EmptyShoppingCart Then
			SearchResult = New Array;
		Else
			SearchResult = Object.junk.FindRows(Filter);
		EndIf;

		If SearchResult.Count() = 0 Or NewRow.Error_ <> 0 Then
			CurrentRow = Object.junk.Add();
			FillPropertyValues(CurrentRow, Filter);
			CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
			
			ProcessedLinesAreNew.Add(CurrentRow);
			Errors_.Insert(CurrentRow, NewRow.Error_);
		Else
			CurrentRow = SearchResult[0];
			ProcessedRowsFound.Add(CurrentRow);
		EndIf;

		CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackages + NewRow.NumberOfPackages;

		CurrentRow.OrderToWarehouse = True;
		LinesForSettingStatusOfSeries.Add(CurrentRow);

	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedRowsFound,
		StructureOfActions,
		Object.junk);
	
	StructureOfActions.Insert("FillInFlagForWhetherThereIsProductSoldJointly",
		Enums.AnalysisOptionsForItemsSoldTogether.Wholesale);
		
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountRoundingError",
		New Structure("ErrorsByLines", Errors_));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesAreNew,
		StructureOfActions,
		Object.junk);
	
	If LinesForSettingStatusOfSeries.Count()
		And SeriesSpecificationParameters <> Undefined Then
		FillInStatusesForSpecifyingSeries(LinesForSettingStatusOfSeries);
	EndIf;

	If UseItemsSoldTogether Then
		WhenChangingBucketOnServer();
	EndIf;
	
EndProcedure

&AtServer
Function GetProductParametersBeforeAddingToCart(FormParameters)
	
	ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1(CurrentLineOfProducts.Products);
	ProductParameters_1.ItemVariantsAreUsed = True;
	
	FillPropertyValues(ProductParameters_1, CurrentLineOfProducts);
	ProductParameters_1.IsService = CurrentLineOfProducts.IsService;	
	If CurrentLineOfProducts.ThisIsAProduct And Warehouses.Count() = 1 Then
		ProductParameters_1.Warehouse = Warehouses.Get(0).Value;
	EndIf;
	
	If Not ValueIsFilled(ProductParameters_1.PriceKind)
		And TypesOfPrices.Count() = 1 Then
		
		ProductParameters_1.PriceKind = TypesOfPrices.Get(0).Value;
		
	EndIf;
	
	ProductParameters_1.NumberOfPackages = 1;
	FormAndProductParametersOnServer(FormParameters, ProductParameters_1);
	
	Return ProductParameters_1
	
EndFunction

&AtServer
Procedure FormAndProductParametersOnServer(FormParameters, ProductParameters_1)
	
	If ProductParameters_1 = Undefined Then
		Return;
	EndIf;
	
	FormParameters.Insert("TableAddressSelectedEarlier",       GetAddressOfTableOnServer());
	FormParameters.Insert("AddressInTempStorage",        Undefined);
	If UseDiscountAdjustmentsInSales Then
		FormParameters.AddressInTempStorage = AddressOfDataForCalculatingManualDiscountsForSelectionInTemporaryStorageOnServer(ProductParameters_1);
	EndIf;
	
	ProductParameters_1.Insert("BatchesIndicationStatus",0);
	
	If ValueIsFilled(SeriesSpecificationParameters) Then
		FillInStatusOfSeriesIndicationInStructure(ProductParameters_1, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInCollateralOptionAndFlagOnClient(CurrentRow)
	
	If ValueIsFilled(CurrentRow.Products) Then
		
		ProductAttributes = ProductDetailsForFillingOutSecurityOption(CurrentRow.Products);
		If ModeForSelectingBalancesByBusinessLine Then
			
			CurrentRow.WithAssignment = WithAssignment
				And (ProductAttributes.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
					Or ProductAttributes.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5"));
			
		Else
			
			Actions = AcceptableSeparateAndNonSeparateActionsOnClient(ProductAttributes.ItemsType);
			
			Result = ProvisionInDocumentsClientServer.DefaultOptionAndFlagForMatching(
				ProductAttributes.ItemsType,
				Actions.AcceptableSeparateActions,
				Actions.AllowedNonIsolatedActions,
				LimitSupplyOptions,
				SecurityOptionAndFlagSeparately,
				ProductAttributes.AssignedPurchaseSale Or WithAssignment);
			
			CurrentRow.SupplyOption = Result.SupplyOption;
			CurrentRow.WithAssignment = Result.WithAssignment;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSecurityOptionAndFlagAtServer(CurrentRow)
	
	If ValueIsFilled(CurrentRow.Products) Then
		
		ProductAttributes = ProductDetailsForFillingOutSecurityOption(CurrentRow.Products);
		If ModeForSelectingBalancesByBusinessLine Then
			
			CurrentRow.WithAssignment = WithAssignment
				And (ProductAttributes.ItemsType = Enums.ItemsTypes.OwnGoods
					Or ProductAttributes.ItemsType = Enums.ItemsTypes.Work_5);
			
		Else
			
			Actions = AllowedSeparateAndNonSeparateActionsOnServer(ProductAttributes.ItemsType);
			
			Result = ProvisionInDocumentsClientServer.DefaultOptionAndFlagForMatching(
				ProductAttributes.ItemsType,
				Actions.AcceptableSeparateActions,
				Actions.AllowedNonIsolatedActions,
				LimitSupplyOptions,
				SecurityOptionAndFlagSeparately,
				ProductAttributes.AssignedPurchaseSale Or WithAssignment);
			
			CurrentRow.SupplyOption = Result.SupplyOption;
			CurrentRow.WithAssignment = Result.WithAssignment;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ProductDetailsForFillingOutSecurityOption(Ref)
	
	Return Common.ObjectAttributesValues(Ref, "ItemsType,AssignedPurchaseSale");
	
EndFunction

&AtClient
Procedure EstablishVisibilityOfProductSelectionTeamSoldJointly()
	
	Items.WithTheSelectedItemItIsJointlySold.Visible = ThereIsItemSoldJointly;
	
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
Procedure DeselectProductSearchBarOnServer()
	
	SelectGoodsClientServer.DeselectProductSearchBar(ThisObject);
	
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

&AtServer
Procedure DeselectCharacteristicsSearchBarOnServer()
	
	SelectGoodsClientServer.DeselectByCharacteristicsSearchBar(ThisObject);
	
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

&AtClient
Procedure WithAssignmentOnChange()
	
	SeparateWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure SeparateWhenChangingOnServer()
	
	TheSelectionForTheAppointmentOfTheCurrent = ?(WithAssignment, FilterByAssignment, Undefined);
	SelectGoodsServer.SetQueryTextsForMatchingFormLists(ThisObject);
	
	SelectGoodsClientServer.SetDynamicListParameter(
		ListProducts,
		"Purpose",
		TheSelectionForTheAppointmentOfTheCurrent);
	
	If UseItemVariants Then
		
		SelectGoodsClientServer.SetDynamicListParameter(
			FeatureList,
			"Purpose",
			TheSelectionForTheAppointmentOfTheCurrent);
		
	EndIf;
	
	SelectGoodsServer.SetVisibilityOfAvailableMatchingBalancesInSalesDocument(ThisObject);	
	
EndProcedure

&AtServer
Function GoodsAddressInStorage(UniqueOwnerID)

	AddressInStorage = Undefined;

	If MoveToDocument Then
		Goods = Object.junk.Unload();
		AddressInStorage = PutToTempStorage(Goods, UniqueOwnerID);
	EndIf;

	Return AddressInStorage;

EndFunction

&AtClient
Procedure ConfigureSearch(Command)
	
	SelectGoodsClient.ConfigureSearch(ThisObject);
	
EndProcedure

// Returns the fact that there were errors made when filling the Bucket.
// Displays the necessary information messages to the user.
//
// Returns:
// 	Boolean
//
&AtClient
Function CheckFillingOfBasket()
	
	ClearMessages();
	
	Result = True;
	
	For Each TSRow In Object.junk Do
		
		If Not ValueIsFilled(TSRow.Characteristic)
			And TSRow.ItemVariantsAreUsed Then
			
			LineNumber = TSRow["LineNumber"];
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не заполнена колонка ""Характеристика"" в строке %1 списка корзины.';
					|vi = 'Column ""Variant"" in line %1 of the shopping cart list is not filled in.';
					|en = 'Column ""Variant"" in line %1 of the shopping cart list is not filled in.'; fa = 'Column ""Variant"" in line %1 of the shopping cart list is not filled in.';
					|it = 'Column ""Variant"" in line %1 of the shopping cart list is not filled in.';
					|pl = 'Column ""Variant"" in line %1 of the shopping cart list is not filled in.';
					|tr = 'Sepet listesinin %1 satırında ""Varyant"" sütunu doldurulmadı.'"),
				LineNumber);
			
			CommonClient.MessageToUser(
				ErrorText,,
				CommonClientServer.PathToTabularSection("Object.junk", LineNumber, "Characteristic"));
			
			Result = False;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region EventHandlersOnServer

&AtServer
Procedure SaveFormSettingsOnServer()
	
	SelectGoodsServer.SaveSelectionFormSettings(ThisObject);
	
EndProcedure

&AtServer
Procedure OnlyInStockOnChangeAtServer()
	
	SelectGoodsServer.SetQueryTextsForMatchingFormLists(ThisObject);
	SelectGoodsServer.SetFilterOnlyInStock(ThisObject);
	
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
Procedure SelectionTreeSelectionWhenModifiedOnServer()
	
	SelectGoodsServer.FilterTreeFilterOnChange(ThisObject);
	
EndProcedure

&AtServer
Procedure QualityListFlaggedWhenChangedOnServer()
	
	SelectGoodsServer.QualityListTaggingOnChange(ThisObject);
	
EndProcedure

&AtServer
Procedure ProductsWithSimilarPropertiesOnServer()
	
	SelectGoodsServer.WhenChangingDisplayOfItemWithSimilarProperties(ThisObject);
	
EndProcedure

&AtServer
Procedure WithSelectedProductsJointlySoldOnServer()
	
	SelectGoodsServer.WhenSettingSelectionForProductSoldJointly(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenChangingBucketOnServer()
	
	SelectGoodsServer.WhenChangingBucket(ThisObject);
	
	
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
Function WhenWritingNewProductOnServer(NewProductItem)
	
	SelectGoodsServer.WhenWritingNewProductItem(ThisObject, NewProductItem);
	
	FormParameters = New Structure;
	FormAndProductParametersOnServer(FormParameters, GoodsForAddingToTheCart);
	
	Return FormParameters
EndFunction

&AtServer
Function WhenRecordingNewCharacteristicOnServer(NewFeatureElement)
	
	SelectGoodsServer.WhenRecordingNewCharacteristic(ThisObject, NewFeatureElement);
	
	FormParameters = New Structure;
	FormAndProductParametersOnServer(FormParameters, GoodsForAddingToTheCart);
	
	Return FormParameters
EndFunction

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

&AtClient
Procedure SelectionGoToTheListOfItemsAdvancedSearch(Command)
	
	SelectGoodsClient.GoToListOfProducts(ThisObject);
	
EndProcedure

&AtClient
Procedure SelectionGoToTheListOfItemsStandardSearch(Command)
	
	SelectGoodsClient.GoToListOfProducts(ThisObject);
	
EndProcedure

#EndRegion

#Region Sets

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters)
	
	Return SetsServer.SetAddressInTemporaryStorage(ThisObject, Var_Parameters, "junk");
	
EndFunction

&AtClientAtServerNoContext
Function DialColumns(Form)
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	Columns.Add("Price");
	Columns.Add("PriceKind");
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	Columns.Add("Sum");
	If Not Form.HideManualDiscounts Then
		Columns.Add("PercentRateOfManualDiscount");
		Columns.Add("ManualDiscount");
	EndIf;
	
	Return Columns;
	
EndFunction

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	Data = GetFromTempStorage(AddressInTempStorage);
	
	Filter = New Structure;
	Filter.Insert("ProductsInSet", Data.ProductsInSet);
	Filter.Insert("ItemVariantOfSet", Data.ItemVariantOfSet);
	
	SetLines = Object.junk.FindRows(Filter);
	
	Columns = DialColumns(ThisObject);
	
	For Each TSRow In Data.Components Do
		
		Filter = New Structure;
		Filter.Insert("LineNumber", TSRow.DocumentRowNumber);
		
		FoundRows = Object.junk.FindRows(Filter);
		If FoundRows.Count() > 0 Then
			
			For Each Column In Columns Do
				FoundRows[0][Column] = TSRow[Column];
			EndDo;
			
			RowIndex = SetLines.Find(FoundRows[0]);
			If Not RowIndex = Undefined Then
				SetLines.Delete(RowIndex);
			EndIf;
			FillInStatusesForSpecifyingSeries(FoundRows[0]);

		Else
			
			NewRow = Object.junk.Add();
			NewRow.ProductsInSet = Data.ProductsInSet;
			NewRow.ItemVariantOfSet = Data.ItemVariantOfSet;
			FillPropertyValues(NewRow, TSRow);
			If (NewRow.ItemsType = Enums.ItemsTypes.OwnGoods
				Or NewRow.ItemsType = Enums.ItemsTypes.ReusablePackage)
				And Warehouses.Count() = 1 Then
				NewRow.Warehouse = Warehouses[0].Value;
			EndIf;
			NewRow.SetIndex = ?(ValueIsFilled(NewRow.ProductsInSet), 1, 0);
			FillInStatusesForSpecifyingSeries(NewRow);

		EndIf;
		
	EndDo;
	
	For Each SetString_ In SetLines Do
		Object.junk.Delete(SetString_);
	EndDo;
	
	If UseItemsSoldTogether Then
		WhenChangingBucketOnServer()
	Else	
		SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenRemovingComponents(Action, AdditionalParameter) Export
	
	If SetsClient.EditSetAction(Action) Then
		SetsClient.WhenRemovingComponents(ThisObject, "junk", AdditionalParameter);
	ElsIf SetsClient.DeleteEntireSetAction(Action) Then
		WhenRemovingComponentsOnServer("junk", AdditionalParameter);
	EndIf;
	
	If UseItemsSoldTogether Then
		WhenChangingBucketOnServer();
		EstablishVisibilityOfProductSelectionTeamSoldJointly();
	Else	
		SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	SetsServer.WhenRemovingComponents(ThisObject, TSName, AdditionalParameter);
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure junkSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.junk.CurrentData;
	SeriesSelectionParameters_ = New Structure;
	SeriesSelectionParameters_.Insert("ReadOnly", False);
	SeriesSelectionParameters_.Insert("Products", CurrentData.Products);
	SeriesSelectionParameters_.Insert("Characteristic", CurrentData.Characteristic);
	SeriesSelectionParameters_.Insert("Count", CurrentData.Count);
	If CurrentData.WithAssignment Then
		SeriesSelectionParameters_.Insert("Purpose", Purpose);
	Else
		SeriesSelectionParameters_.Insert("Purpose", PredefinedValue("Catalog.Assignments.EmptyRef"));
	EndIf;
	SeriesSelectionParameters_.Insert("AssignmentSender", PredefinedValue("Catalog.Assignments.EmptyRef"));
	
	SeriesSelectionParameters_.Insert("Series", CurrentData.Series);
	SeriesSelectionParameters_.Insert("Recorder", DocumentRef);
	SeriesSelectionParameters_.Insert("Warehouse", CurrentData.Warehouse);
	
	SeriesSelectionParameters_.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	SeriesSelectionParameters_.Insert("FieldValuesToIdentifyReferences", New Array);
	CurrentRowID = CurrentData.GetID();
	SeriesSelectionParameters_.Insert("CurrentRowID", CurrentRowID);
	SeriesSelectionParameters_.Insert("Text", "");
	
	OpenForm("DataProcessor.SelectBatchToDocuments.Form.BatchIndicationInGoodsRow",SeriesSelectionParameters_, ThisObject);
	
EndProcedure

&AtClient
Procedure junkSeriesOnChange(Item)
	ProductsSeriesRecalculatePrices();
EndProcedure

&AtClientAtServerNoContext
Function CheckSetStatusOfBatches(String, SeriesSpecificationParameters)
	
	SupplyOption = String.SupplyOption;
	If Not SeriesSpecificationParameters.UseItemsBatch
		Or Not ValueIsFilled(String.Products)
		Or Not ValueIsFilled(String.Warehouse)
		Or SeriesSpecificationParameters.ThisIsOrder
			And SupplyOption <> PredefinedValue("Enum.SupplyOptions.Ship")
			And SupplyOption <> PredefinedValue("Enum.SupplyOptions.FromWarehouse") Then
		String.BatchesIndicationStatus = 0;
		String.Series = PredefinedValue("Catalog.ItemsBatches.EmptyRef");
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesById(Val IdsForSettingStatusOfSeries)

	If SeriesSpecificationParameters = Undefined Then
		Return;
	EndIf;

	LinesForSettingStatusOfSeries = New Array;
	If TypeOf(IdsForSettingStatusOfSeries) = Type("Number") Then
		CurrentRow = Object.junk.FindByID(IdsForSettingStatusOfSeries);
		LinesForSettingStatusOfSeries.Add(CurrentRow);
	Else
		For Each RowID In IdsForSettingStatusOfSeries Do
			LinesForSettingStatusOfSeries.Add(Object.junk.FindByID(RowID));
		EndDo;
	EndIf;

	FillInStatusesForSpecifyingSeries(LinesForSettingStatusOfSeries);

EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeries(LinesForSettingStatusOfSeries)

	If SeriesSpecificationParameters = Undefined Then
		Return;
	EndIf;

	If TypeOf(LinesForSettingStatusOfSeries) <> Type("Array") Then
		CurrentRow = LinesForSettingStatusOfSeries;
		LinesForSettingStatusOfSeries = New Array;
		LinesForSettingStatusOfSeries.Add(CurrentRow);
	EndIf;

	DataProcessors.SelectGoodsToSalesDocument.FillInStatusOfSeriesInLine(
		LinesForSettingStatusOfSeries,
		SeriesSpecificationParameters);

EndProcedure

&AtServerNoContext
Procedure FillInStatusOfSeriesIndicationInStructure(Val LineForSettingStatusOfSeries, SeriesSpecificationParameters)

	If SeriesSpecificationParameters = Undefined Then
		Return;
	EndIf;

	LinesForSettingStatusOfSeries = New Array;
	LinesForSettingStatusOfSeries.Add(LineForSettingStatusOfSeries);

	DataProcessors.SelectGoodsToSalesDocument.FillInStatusOfSeriesInLine(
		LinesForSettingStatusOfSeries,
		SeriesSpecificationParameters);

EndProcedure

&AtClient
Procedure DownloadSelectionListOfSecurityOptions()
	
	CurrentData = Items.junk.CurrentData;
	
	Actions = AcceptableSeparateAndNonSeparateActionsOnClient(CurrentData.ItemsType);
	
	SeparatePurchaseSaleShoppingCart = False;
	ProductTypeShoppingCart = Undefined;
	If ValueIsFilled(CurrentData.Products) Then
		ProductAttributes = ProductDetailsForFillingOutSecurityOption(CurrentData.Products);
		SeparatePurchaseSaleShoppingCart = ProductAttributes.AssignedPurchaseSale;
		ProductTypeShoppingCart = ProductAttributes.ItemsType;
	EndIf;
	SecurityOptionAndFlag = SecurityOptionAndFlagSeparately;
	If SecurityOptionAndFlag = Undefined Then
		SecurityOptionAndFlag = ProvisionInDocumentsClientServer.ProvisionOptionAndFlagAreSeparateByDefault(
			SeparatePurchaseSaleShoppingCart);
	EndIf;
	
	AcceptableSecurityOptions = ProvisionInDocumentsClientServer.AcceptableSecurityOptions(
		ProductTypeShoppingCart,
		Actions.AcceptableSeparateActions,
		Actions.AllowedNonIsolatedActions,
		LimitSupplyOptions,
		SecurityOptionAndFlag);
	
	If CurrentData.WithAssignment Then
		Items.junkSupplyOption.ChoiceList.LoadValues(AcceptableSecurityOptions.Separate_);
	Else
		Items.junkSupplyOption.ChoiceList.LoadValues(AcceptableSecurityOptions.NonIsolated);
	EndIf;
	
EndProcedure

&AtClient
Function AcceptableSeparateAndNonSeparateActionsOnClient(ItemsType)
	
	AllowedNonIsolatedActions  = ProvisionInDocumentsClientServer.AllActions();
	AcceptableSeparateActions    = ProvisionInDocumentsClientServer.AllActions();
	If ValidNonIsolatedActionsFromParameter.Count() > 0
			Or ValidSeparateActionsFromParameter.Count() > 0 Then
		AllowedNonIsolatedActions  = ValidNonIsolatedActionsFromParameter;
		AcceptableSeparateActions    = ValidSeparateActionsFromParameter;
	EndIf;
	If AllowedNonIsolatedActions.Count() = 0
			And (ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")
				Or ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService")) Then
					AllowedNonIsolatedActions = ProvisionInDocumentsClientServer.AllActions();
	EndIf;
	Result = New Structure();
	Result.Insert("AllowedNonIsolatedActions", AllowedNonIsolatedActions);
	Result.Insert("AcceptableSeparateActions", AcceptableSeparateActions);
	Return Result;
	
EndFunction

&AtServer
Function AllowedSeparateAndNonSeparateActionsOnServer(ItemsType)
	
	AllowedNonIsolatedActions  = ProvisionInDocumentsClientServer.AllActions();
	AcceptableSeparateActions    = ProvisionInDocumentsClientServer.AllActions();
	If ValidNonIsolatedActionsFromParameter.Count() > 0
			Or ValidSeparateActionsFromParameter.Count() > 0 Then
		AllowedNonIsolatedActions  = ValidNonIsolatedActionsFromParameter;
		AcceptableSeparateActions    = ValidSeparateActionsFromParameter;
	EndIf;
	If AllowedNonIsolatedActions.Count() = 0
			And (ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")
				Or ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService")) Then
					AllowedNonIsolatedActions = ProvisionInDocumentsClientServer.AllActions();
	EndIf;
	Result = New Structure();
	Result.Insert("AllowedNonIsolatedActions", AllowedNonIsolatedActions);
	Result.Insert("AcceptableSeparateActions", AcceptableSeparateActions);
	Return Result;
	
EndFunction

&AtClient
Procedure ProductsSeriesRecalculatePrices(CurrentRow = Undefined)
	
	If CurrentRow = Undefined Then
		CurrentRow = Items.junk.CurrentData;
	EndIf;
	
	If PriceManagementSystemClient.ItIsNecessaryToRecalculatePriceWhenChanging(CurrentRow.Products, "Series") Then
		
		StructureOfActions = New Structure;

		SupplementStructureWithPriceCalculationActions(ThisObject, StructureOfActions, CurrentRow);

		SupplementStructureWithActionsForRecalculatingAmounts(StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		SelectGoodsClientServer.SetTextOfInformationLabel(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure junkBeforeRowChange(Item, Cancel)
	
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
