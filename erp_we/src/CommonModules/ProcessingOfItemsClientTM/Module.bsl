////////////////////////////////////////////////////////////////////////////////
// Subsystem "Working with nomenclature".
// General module.The work of the nomenclature of the client.
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region ProductSearchFormByBarcode

// See WorkingWithProductItemsClientOverridable.SearchForProductsByBarcodeWhenOpening.
Procedure SearchForProductsByBarcodeWhenOpening(Form) Export
	
	#If Not WebClient Then
	Beep();
	#EndIf
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, Form, "BarcodeScanner");
	
EndProcedure

// See WorkingWithProductItemsClientOverridable.SearchForProductsByBarcodeWhenClosing.
Procedure SearchForProductsByBarcodeWhenClosing(Form, Exit) Export
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, Form);
	
EndProcedure

// See WorkingWithProductItemsClientOverridable.ProductSearchByBarcodeNotificationProcessing.
Procedure ProductSearchByBarcodeNotificationProcessing(Form, EventName, Parameter, Source, Barcodes) Export
	
	// Peripherals
	If Form.IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(Form, EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
EndProcedure

// See WorkingWithProductItemsClientOverridable.ProductSearchByBarcodeSelectionProcessing.
Procedure ProductSearchByBarcodeSelectionProcessing(Form, ValueSelected, ChoiceSource) Export
EndProcedure

// Procedure called when you change the Item field in the search nomenclature form by Barcode.
//
// Parameters:
//  Form	 - ClientApplicationForm - bar code search form for an item.
//  Item	 - FormField - a form field that can be changed.
//
Procedure SearchForProductsByBarcodeProductsWhenChanged(Form, Item) Export
	
	CurrentData = Form.Items.ItemsBarcodes.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner",	CurrentData.Characteristic);
	StructureOfActions.Insert("CheckBatchByOwner",				CurrentData.Series);
	StructureOfActions.Insert("CheckFillPackageByOwner",	CurrentData.Package);
	StructureOfActions.Insert("CheckBarcodeRegistration",			CurrentData.Registered);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
EndProcedure

// Procedure called when creating the search nomenclature form in the Nomenclature field by Barcode.
//
// Parameters:
//  Form - ClientApplicationForm - the form from the event handler where the procedure is called.
//  Item				 - FormField - form element.
//  StandardProcessing - Boolean - indicates standard processing.
//
Procedure SearchForProductsByBarcodeProductsCreation(Form, Item, StandardProcessing) Export
EndProcedure

// Procedure that is called when you start selecting items in the Nomenclature field of the search nomenclature form by Barcode.
//
// Parameters:
//  Form - ClientApplicationForm - the form from the event handler where the procedure is called.
//  Item				 - FormField - form element.
//  ChoiceData		 - ValueList - the selection data..
//  StandardProcessing - Boolean -  indicates standard processing.
//
Procedure SearchForProductsByBarcodeProductsStartSelection(Form, Item, ChoiceData, StandardProcessing) Export
EndProcedure

// Procedure that is called when changing the Feature field of the search nomenclature form by Barcode.
//
// Parameters:
//	Form - ClientApplicationForm - bar code search form for an item.
//	Item - FormField - a form field that can be changed.
//
Procedure SearchForProductsByBarcodeCharacteristicWhenChanging(Form, Item) Export
	
	CurrentData = Form.Items.ItemsBarcodes.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckBarcodeRegistration", CurrentData.Registered);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
EndProcedure

// The procedure that is called ON changing an element of the connected command Form of the search nomenclature by barcode.
//
// Parameters:
//	Form - ClientApplicationForm - the form from the event handler where the procedure is called.
//	Item - FormField - form element.
//
Procedure SearchForItemsByBarcodeONChange(Form, Item) Export
	
	Items = Form.Items;
	
	If Items.Package.Name = Item.Name
		Or Items.Series.Name = Item.Name Then
		
		CurrentData = Form.Items.ItemsBarcodes.CurrentData;
		
		If CurrentData <> Undefined Then
			StructureOfActions = New Structure;
			StructureOfActions.Insert("CheckBarcodeRegistration", CurrentData.Registered);
			
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

// See WorkingWithProductItemsClientOverridable.CreateProductsInteractively.
Procedure CreateProductsInteractively(FormParameters, OnCloseNotifyDescription) Export 
	
	OpenForm("Catalog.Products.Form.ItemForm", FormParameters,,,,, OnCloseNotifyDescription);
	
EndProcedure

// See WorkingWithProductItemsClientOverridable.CreateProductViewInteractively.
Procedure CreateProductViewInteractively(FormParameters, OnCloseNotifyDescription) Export 
	
	OpenForm("Catalog.ItemKinds.Form.ItemForm", 
		FormParameters, , , , , OnCloseNotifyDescription, FormWindowOpeningMode.Independent);
	
EndProcedure

// See WorkingWithProductItemsClientOverridable.OpenAdditionalValueForm.
Procedure OpenAdditionalValueForm(FormParameters, Form) Export
	
	FillingValues = New Structure;
	FillingValues.Insert("Owner",     FormParameters.AttributeRef);
	FillingValues.Insert("Description", FormParameters.Description);
	
	FormParameters = New Structure("FillingValues", FillingValues);
	
	OpenForm("Catalog.ObjectsPropertiesValues.Form.ItemForm", FormParameters, Form);
	
EndProcedure

// See WorkingWithProductItemsClientOverridable.OpenFormForAdditionalBankingDetails.
Procedure OpenFormForAdditionalBankingDetails(FormParameters, Form) Export
	
	OpenForm("ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Form.ItemForm", FormParameters, Form);
	
EndProcedure

// See WorkingWithProductItemsClientOverridable.OpenProductsForm.
Procedure OpenProductsForm(ProductsLink, Form) Export
	
	OpenForm("Catalog.Products.Form.ItemForm", New Structure("Key", ProductsLink), Form);
	
EndProcedure
	
// See WorkingWithProductItemsClientOverridable.OpenProductItemForm.
Procedure OpenProductItemForm(ProductKindReference, Form) Export
	
	OpenForm("Catalog.ItemKinds.Form.ItemForm", New Structure("Key", ProductKindReference), Form);
	
EndProcedure

// See WorkingWithProductItemsClientOverridable.OpenListFormInProductsView.
Procedure OpenListFormInProductsView(ProductKindReference, Form, OnCloseNotifyDescription) Export
	
	FormParameters = New Structure();
	FormParameters.Insert("Filter", New Structure("Ref", ProductKindReference));
	
	OpenForm("Catalog.ItemKinds.Form.ListForm", FormParameters, Form,,,,OnCloseNotifyDescription);
	
EndProcedure

// See WorkingWithProductItemsClientOverridable.OpenProductListForm.
Procedure OpenProductListForm(ProductsLink, Form) Export
	
	FormParameters = New Structure();
	FormParameters.Insert("Filter", New Structure("Ref", ProductsLink));
	
	OpenForm("Catalog.Products.Form.ListForm", FormParameters, Form);
	
EndProcedure

// Notification handler for nomenlature selection.
//
// Parameters:
//  Products - CatalogRef.Products - selected value.
//  AdditionalParameters - ClientApplicationForm - the form from the event handler where the procedure is called.
//
Procedure WhenSelectingProducts(Products, AdditionalParameters) Export
	
	Var CachedValues;
	
	If Products = Undefined Then
		Return;
	EndIf;
	
	CurrentData = AdditionalParameters.Items.ItemsBarcodes.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.Products = Products;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner",	CurrentData.Characteristic);
	StructureOfActions.Insert("CheckBatchByOwner",				CurrentData.Series);
	StructureOfActions.Insert("CheckFillPackageByOwner",	CurrentData.Package);
	StructureOfActions.Insert("CheckBarcodeRegistration",			CurrentData.Registered);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

// See WorkingWithProductItemsClientOverridable.OpenProductSelectionForm.
Procedure OpenProductSelectionForm(FormParameters, 
	Owner = Undefined,
	OnCloseNotifyDescription = Undefined, 
	Var_FormWindowOpeningMode = Undefined) Export
	
	UniqueKey = New UUID;
	If CommonClientServer.HasAttributeOrObjectProperty(Owner, "UUID") Then
		UniqueKey = Owner.UUID;
	EndIf;
	
	OpenForm("Catalog.Products.Form.SelectionOfGroupsAndItemsForm", 
		FormParameters, Owner, UniqueKey,,,OnCloseNotifyDescription, Var_FormWindowOpeningMode);
	
EndProcedure

// See WorkingWithProductItemsClientOverridable.OpenProductSelectionForm.
Procedure OpenFormForSelectingProductsWithCharacteristics(Owner = Undefined,
			OnCloseNotifyDescription = Undefined, Var_FormWindowOpeningMode = Undefined) Export
	
	UniqueKey = New UUID;
	If CommonClientServer.HasAttributeOrObjectProperty(Owner, "UUID") Then
		UniqueKey = Owner.UUID;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ReturnReusablePackage",            False);
	FormParameters.Insert("FilterByProductType",                 ProductsClientServer.SelectionByProductMultiTurnContainer(True));
	FormParameters.Insert("ModeOfSelectionWithoutQuantitativeParameters", True);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",       True);
	FormParameters.Insert("SelectionModeWithoutAgreementsWithCustomers",     True);
	FormParameters.Insert("HideTheViewPriceColumn",                  True);
	FormParameters.Insert("HideTheItemPricesCommand",         True);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses",         True);
	FormParameters.Insert("HideTheRequestQuantityButton",     True);
	FormParameters.Insert("HideManualDiscounts",                    True);
	FormParameters.Insert("AllWarehouseBalance",                    True);
	FormParameters.Insert("SelectSupplyOptions",              False);
	FormParameters.Insert("UseShipmentDates",                False);
	FormParameters.Insert("DoNotSplitSetsByComponents",        True);
	FormParameters.Insert("Title",                               NStr("vi = 'Hãy chọn mặt hàng để kết xuất';
																		|ru = 'Выберите номенклатуру для выгрузки';
																		|en = 'Select products to export'; fa = 'Select products to export';
																		|it = 'Select products to export';
																		|pl = 'Select products to export';
																		|tr = 'Dışa aktarma için öğeyi seçin'"));
	FormParameters.Insert("TransferButtonTitle",                NStr("vi = 'Chuyển sang kết xuất';
																	|ru = 'Перенести в выгрузку';
																	|en = 'Move to export'; fa = 'Move to export';
																	|it = 'Move to export';
																	|pl = 'Move to export';
																	|tr = 'Dışa aktarma için transfer'"));
	FormParameters.Insert("Date",                                    CommonClient.SessionDate());
	FormParameters.Insert("Document",                                PredefinedValue("Document.PriceSetup.EmptyRef"));
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form",
		FormParameters, Owner, UniqueKey,,, OnCloseNotifyDescription, Var_FormWindowOpeningMode);
	
EndProcedure


#EndRegion

#Region Private

Procedure ProcessBarcodes(Form, BarcodeData_5)
	
	ClearMessages();
	
	RowFilter						= New Structure("Barcode");
	ItemsBarcodes			= Form.ItemsBarcodes;
	NumberOfInvalidBarcodes	= 0;
	UnknownBarcodes			= New Array;
	QuantityByBarcodes			= New Map();
	CachedValues			= BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	FillableProperties				= "Products, Characteristic, Series, Package, ItemVariantsAreUsed, 
										|SeriesAreUsed";
	
	For Each BarcodeData_1 In BarcodeData_5 Do
		FillPropertyValues(RowFilter, BarcodeData_1);
		FoundRows = ItemsBarcodes.FindRows(RowFilter);
		
		If FoundRows.Count() > 0 Then
			FoundRows[0].Count = FoundRows[0].Count + BarcodeData_1.Count;
		Else
			If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_1, False) Then
				NumberOfInvalidBarcodes = NumberOfInvalidBarcodes + 1;
				
				Continue;
			EndIf;
			
			CurrentBarcode = Upper(TrimAll(BarcodeData_1.Barcode));
			
			UnknownBarcodes.Add(CurrentBarcode);
			
			DataAboutQuantity = QuantityByBarcodes.Get(CurrentBarcode);
			
			If DataAboutQuantity = Undefined Then
				QuantityByBarcodes.Insert(CurrentBarcode, BarcodeData_1.Count);
			Else
				DataAboutQuantity.Count = DataAboutQuantity.Count + BarcodeData_1.Count;
				
				QuantityByBarcodes.Insert(CurrentBarcode, DataAboutQuantity);
			EndIf;
		EndIf;
	EndDo;
	
	If UnknownBarcodes.Count() > 0 Then
		UnknownBarcodes = CommonClientServer.CollapseArray(UnknownBarcodes);
		ProcessingOfItemsServerCallTM.GetBarcodeData(CachedValues, UnknownBarcodes);
	EndIf;
	
	For Each Barcode In UnknownBarcodes Do
		BarcodeData_1	= CachedValues.Barcodes.Get(Barcode);
		Count		= QuantityByBarcodes.Get(Barcode);
		
		NewRow = ItemsBarcodes.Add();
		FillPropertyValues(NewRow, BarcodeData_1, FillableProperties);
		
		If BarcodeData_1 = Undefined Then
			NewRow.Registered = True;
		ElsIf BarcodeData_1.UnknownBarcode Then
			NewRow.Registered = False;
		ElsIf Not BarcodeData_1.ItemsBarcode Then
			NewRow.Registered = False;
		Else
			NewRow.Registered = True;
		EndIf;
		
		NewRow.Barcode					= Barcode;
		NewRow.Count					= Count;
		NewRow.SearchInTheServiceWasNotUsed	= True;
	EndDo;
	
	If NumberOfInvalidBarcodes > 0 Then
		NotificationText1 = ?(NumberOfInvalidBarcodes = 1,
							NStr("ru = 'Ошибка чтения штрихкодов.';
								|vi = 'Barcode read error.';
								|en = 'Barcode read error.'; fa = 'Barcode read error.';
								|it = 'Barcode read error.';
								|pl = 'Barcode read error.';
								|tr = 'Barkodlar okunurken hata oluştu.'"),
							NStr("ru = 'Ошибка чтения штрихкодов.';
								|vi = 'Barcode read error.';
								|en = 'Barcode read error.'; fa = 'Barcode read error.';
								|it = 'Barcode read error.';
								|pl = 'Barcode read error.';
								|tr = 'Barkodlar okunurken hata oluştu.'"));
		NotificationComment = NStr("vi = 'Biểu mẫu này không được dùng để làm việc với mã dán nhãn.';
									|ru = 'Эта форма не предназначена для работы с кодами маркировки.';
									|en = 'You cannot use this form for operations with marking codes.'; fa = 'You cannot use this form for operations with marking codes.';
									|it = 'Эта форма не предназначена для работы с кодами маркировки.';
									|pl = 'You cannot use this form for operations with marking codes.';
									|tr = 'Bu form, işaretleme kodlarıyla çalışmak için öngörülmemiştir.'");
		
		ShowUserNotification(NotificationText1, , NotificationComment, PictureLib.Warning32);
	EndIf;
	
EndProcedure

#EndRegion