
#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

&AtClient
Var CurDataInitialState;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	StructureOfData = New Structure;
	
	If IsTempStorageURL(Parameters.AddressInStorage) Then
		
		StructureOfData = GetFromTempStorage(Parameters.AddressInStorage);

	ElsIf Parameters.Property("FillParameters") Then
		
		StructureOfData = Parameters.FillParameters;

	EndIf;
	
	If StructureOfData.Count() > 0 Then
		
		If StructureOfData.Property("Date") Then
			Object.Date = StructureOfData.Date;
		Else
			Object.Date = CurrentSessionDate();
		EndIf;

		EstablishUseOfPricing(Object.Date);
		FillInSourceProductsPrepareFillingParameters(StructureOfData);
		
	Else
		
		Object.Date = CurrentSessionDate();
		EstablishUseOfPricing(Object.Date);
		
	EndIf;
	
	If Parameters.Property("PrintToPrinter", PrintToPrinter)
		And StructureOfData.Property("Goods") Then
		
		CheckFillingOfLabelTemplates(StructureOfData.Goods, Cancel);
		
		If Cancel Then
			Return;
		EndIf;
		
	Else
		TMCommonUse.CustomizePeripherals(ThisObject);
		
		UseExchangeWithOfflinePeripherals = GetFunctionalOption(
			"UseExchangeWithOfflinePeripherals");
	EndIf;
	
	SupportedPeripheralTypes = "BarcodeScanner";
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	UseProductRange			= GetFunctionalOption("UseProductRange");
	UseItemsBatch	= GetFunctionalOption("UseItemsBatch");
	
	LoadDefaultSelectionSettings();
	
	Object.TemplateAssignment = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag;
	
	If StructureOfData.Property("Goods") Then
		
		If ValueIsFilled(StructureOfData.StructureOfActions) Then
			
			ActionParameter = Undefined;
			
			If StructureOfData.StructureOfActions.Property("FillInOrganization", ActionParameter) Then
				Object.Organization = ActionParameter;
			EndIf;
			
			If StructureOfData.StructureOfActions.Property("FillInTheWarehouse", ActionParameter) Then
				If ValueIsFilled(ActionParameter) And TypeOf(ActionParameter) = Type("CatalogRef.Warehouses") Then
					WarehouseStore = Common.ObjectAttributeValue(ActionParameter, "WarehouseStore");
					ThisIsRetailWarehouse = (WarehouseStore = Enums.TypesOfWarehouses.RetailStore);
					If ThisIsRetailWarehouse Then
						SetDCSSelectionElement("Warehouse", ActionParameter, True);
						Object.Warehouse = ActionParameter;
					EndIf;
				EndIf;
			EndIf;
			
			If StructureOfData.StructureOfActions.Property("FillInPriceView", ActionParameter) Then
				Object.PriceKind = ActionParameter;
			EndIf;
			
			If StructureOfData.StructureOfActions.Property("FillInExchangeRule", ActionParameter) Then
				Object.ExchangeRule = ActionParameter;
			EndIf;
			
			If StructureOfData.StructureOfActions.Property("ShowQuantityColumnInDocument", ActionParameter) Then
				Items.GoodsQuantityOfGoodsInDocument.Visible = ActionParameter;
			EndIf;
			
			If StructureOfData.StructureOfActions.Property("SetPrintModeFromDocument", ActionParameter) Then
				PrintFromDocument = True;
				Items.Settings.Visible = False;
			EndIf;
			
			FillInTheNumberOfLabelsForTheDocument        = StructureOfData.StructureOfActions.Property("FillInTheNumberOfLabelsForTheDocument", ActionParameter);
			FillInTheNumberOfLabelsForStockBalances = StructureOfData.StructureOfActions.Property("FillInTheNumberOfLabelsForStockBalances", ActionParameter);
			FillInTheNumberOfPriceTagsForTheDocument        = StructureOfData.StructureOfActions.Property("FillInTheNumberOfPriceTagsForTheDocument", ActionParameter);
			FillInTheNumberOfPriceTagsForStockBalances = StructureOfData.StructureOfActions.Property("FillInTheNumberOfPriceTagsForStockBalances", ActionParameter);
			
			If StructureOfData.StructureOfActions.Property("SetMode", ActionParameter) Then
				SetMode(ActionParameter);
			Else
				Raise NStr("vi = 'Chưa đặt chế độ in';
							|ru = 'Режим печати не установлен';
							|en = 'Print mode is not set'; fa = 'Print mode is not set';
							|it = 'Modalità di stampa non impostata';
							|pl = 'Tryb druku nie jest ustawiony';
							|tr = 'Yazdırma modu ayarlanmamış'");
			EndIf;
			
			If StructureOfData.StructureOfActions.Property("FillInTheGoodsTable", ActionParameter) Then
				
				FillInTableOfProductsOnServer(True);
				
				If StructureOfData.Goods.Columns.Find("Price") <> Undefined Then
					
					For Each TSRow In StructureOfData.Goods Do
						
						FilterParameters = New Structure;
						FilterParameters.Insert("Products", TSRow.Products);
						FilterParameters.Insert("Characteristic", TSRow.Characteristic);
						If UsePriceManagementSystem25 Then
							If GetFunctionalOption("UseItemPackages") Then
								FilterParameters.Insert("Package", TSRow.Package);
							EndIf;
							If UseItemsBatch Then
								FilterParameters.Insert("Series", TSRow.Series);
							EndIf;
						EndIf;
						FoundRows = Object.Goods.FindRows(FilterParameters);
						For Each FoundRow In FoundRows Do
							FoundRow.Price = TSRow.Price;
						EndDo;
						
					EndDo;
					
				EndIf;
				
				If StructureOfData.Property("ErrorTableBySeries")
					And StructureOfData.ErrorTableBySeries.Count() > 0 Then
					
					ReportProblemsFillingInItemSeries(StructureOfData.ErrorTableBySeries);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	Else
		
		// Calling processing from the interface
		FillInTheNumberOfLabelsForTheDocument        = False;
		FillInTheNumberOfLabelsForStockBalances = True;
		FillInTheNumberOfPriceTagsForTheDocument        = False;
		FillInTheNumberOfPriceTagsForStockBalances = True;
		
		SetModeToPrintLabelsAndPriceTagsOnServer();
		
	EndIf;
	
	UpdateTemplatesThatAffectVisibilityOfElements();
	
	UpdateVisibilityOfTemplateDependentFields();
	
	Items.ProductsSetANewBarcode.Enabled = AccessRight("Update", Metadata.InformationRegisters.ItemsBarcodes);
	
	If UseProductRange Then
		Object.PriceReceivingMode = 2;
	Else
		Object.PriceReceivingMode = 1;
		Items.Warehouse.Visible = False;
	EndIf;
	SwitchForGettingPricesWhenPriceChanges();
	
	FillInDefaultValues();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
	// Unknown barcodes
	If Source = "Peripherals"
		And EventName = "UnknownBarcodes"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5);
		
	EndIf;
	
	If EventName = "Write_LabelAndPriceTagTemplates" Then
		
		UpdateTemplatesThatAffectVisibilityOfElements();
		UpdateVisibilityOfTemplateDependentFields();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If PrintToPrinter Then
		Cancel = True;
		
		PrintToPrinter(Undefined);
	Else
		EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, SupportedPeripheralTypes);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	If IsTempStorageURL(SavedSettings) Then
		
		TableSavedSettings = GetFromTempStorage(SavedSettings);
		For Each TSRow In TableSavedSettings Do
			Settings.Insert(TSRow.Key, TSRow.Value);
		EndDo;
		SavedSettings = PutToTempStorage(TableSavedSettings, UUID);
	
	Else
		
		// The selection is saved only if it is not printing from a document
		Settings.Insert("Filter_Settings",New ValueStorage(SettingsComposer.Settings));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Parameters.Property("AddressInStorage") And IsTempStorageURL(Parameters.AddressInStorage) Then
		
		TableSavedSettings = New ValueTable;
		TableSavedSettings.Columns.Add("Key");
		TableSavedSettings.Columns.Add("Value");
		
		For Each KeyAndValue In Settings Do
			NewRow = TableSavedSettings.Add();
			NewRow.Key = KeyAndValue.Key;
			NewRow.Value = KeyAndValue.Value;
		EndDo;
		
		SavedSettings = PutToTempStorage(TableSavedSettings, UUID);
		
		Object.WarehouseGroup = Settings["Object.WarehouseGroup"];
		Object.Variant = Settings["Object.Variant"];
		
		Settings.Clear();
		
	Else
		
		FilterVisibility = Settings.Get("FilterVisibility");
		Items.GroupFilter.Visible = FilterVisibility;
		If FilterVisibility Then
			Items.Filter.Title = NStr("vi = 'Ẩn lọc';
										|ru = 'Скрыть отбор';
										|en = 'Hide filter'; fa = 'Hide filter';
										|it = 'Nascondere selezione';
										|pl = 'Ukryj wybór';
										|tr = 'Filtreyi gizle'");
		Else
			Items.Filter.Title = NStr("vi = 'Hiển thị lọc';
										|ru = 'Показать отбор';
										|en = 'Show filter'; fa = 'نمایش فیلتر';
										|it = 'Visualizzare selezione';
										|pl = 'Pokaż filtr';
										|tr = 'Filtreyi göster'");
		EndIf;
		
		VisibilityOfFillMode = Settings.Get("VisibilityOfFillMode");
		Items.GroupFillMode.Visible = VisibilityOfFillMode;
		If VisibilityOfFillMode Then
			Items.FillMode.Title = NStr("vi = 'Ẩn chế độ điền';
										|ru = 'Скрыть режим заполнения';
										|en = 'Hide fill mode'; fa = 'Hide fill mode';
										|it = 'Nascondere la modalità di compilazione';
										|pl = 'Ukryj tryb wypełnienia';
										|tr = 'Doldurma modunu gizle'");
		Else
			Items.FillMode.Title = NStr("vi = 'Hiển thị chế độ điền';
										|ru = 'Показать режим заполнения';
										|en = 'Show fill mode'; fa = 'نمایش حالت تکمیل';
										|it = 'Visualizzare la modalità di compilazione';
										|pl = 'Pokaż tryb wypełniania';
										|tr = 'Doldurma modunu göster'");
		EndIf;
		
		Filter_Settings = Settings.Get("Filter_Settings"); // ValueStorage
		If Filter_Settings <> Undefined Then
			SettingsComposer.LoadSettings(Filter_Settings.Get());
		Else
			LoadDefaultSelectionSettings();
		EndIf;
		
		Mode = Settings.Get("Mode");
		If ValueIsFilled(Mode)
			And (Mode = "PrintPriceTagsAndLabels" Or Mode = "PrintingPriceTags" Or Mode = "PrintLabels") Then
			SetMode(Mode);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	SetDCSSelectionElement("Warehouse", Object.Warehouse, ValueIsFilled(Object.Warehouse));
	
EndProcedure

&AtClient
Procedure PriceReceiptModeSwitchFieldOnChange(Item)
	
	SwitchForGettingPricesWhenPriceChanges();
	ClearMarkIncomplete();
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure GoodsPriceTagTemplateOnChange(Item)
	UpdateVisibilityOfTemplateDependentFields();
EndProcedure

&AtClient
Procedure GoodsLabelsTemplateOnChange(Item)
	UpdateVisibilityOfTemplateDependentFields();
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Not Item.CurrentItem = Items.GoodsBarcode Then
		Return;
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Items.GoodsBarcode.ChoiceList.Clear();
		
		Return;
	EndIf;
	
	ProductData_8 = New Structure;
	ProductData_8.Insert("Products",	CurrentData.Products);
	ProductData_8.Insert("Characteristic",	CurrentData.Characteristic);
	ProductData_8.Insert("Package",		CurrentData.Package);
	ProductData_8.Insert("Series",			CurrentData.Series);
	
	Items.GoodsBarcode.ChoiceList.LoadValues(
		RetailSalesServerCall.GetProductBarcodes(ProductData_8));
	
EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	
	CurrentData = Items.Goods.CurrentData;
	CurDataInitialState = New Structure;
	CurDataInitialState.Insert("Package",             CurrentData.Package);
	CurDataInitialState.Insert("QuantityOfGoodsInDocument", CurrentData.QuantityOfGoodsInDocument);
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	CurDataInitialState = New Structure;
	CurDataInitialState.Insert("Package", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	CurDataInitialState.Insert("QuantityOfGoodsInDocument", 0);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentData = New Structure("Products, Characteristic, Series, Package");
	FillPropertyValues(CurrentData, Items.Goods.CurrentData);
	FillPropertyValues(Items.Goods.CurrentData, WhenChangingProducts(CurrentData));
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentData = New Structure("Products, Characteristic, Series, Package");
	FillPropertyValues(CurrentData, Items.Goods.CurrentData);
	FillPropertyValues(Items.Goods.CurrentData, WhenChangingProducts(CurrentData));
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentData = New Structure("Products, Characteristic, Series, Package, OldPackaging, OldQuantityInDocument, NumberOfLabels");
	FillPropertyValues(CurrentData, Items.Goods.CurrentData);
	CurrentData.OldPackaging = CurDataInitialState.Package;
	CurrentData.OldQuantityInDocument = CurDataInitialState.QuantityOfGoodsInDocument;
	
	FillPropertyValues(Items.Goods.CurrentData, WhenChangingProducts(CurrentData));
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	CurrentData = New Structure("Products, Characteristic, Series, Package");
	FillPropertyValues(CurrentData, Items.Goods.CurrentData);
	FillPropertyValues(Items.Goods.CurrentData, WhenChangingProducts(CurrentData));
	
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	If Not ValueIsFilled(Object.PriceKind) Then
		Return;
	EndIf;
	
	RefillPrices();
	
EndProcedure

&AtClient
Procedure PriceKindAdditionalOnChange(Item)
	
	If Not ValueIsFilled(Object.PriceKindAdditional) Then
		Return;
	EndIf;
	
	RefillPrices();
	
EndProcedure

&AtClient
Procedure DateTypeOfPriceOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	EstablishUseOfPricing(Object.Date);
	
	If Not ValueIsFilled(Object.PriceKind) Then
		Return;
	EndIf;
	
	RefillPrices();
	
EndProcedure

&AtClient
Procedure DateTypeOfPriceAdditionalOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	EstablishUseOfPricing(Object.DateAdditionally);
	
	If Not ValueIsFilled(Object.PriceKindAdditional) Then
		Return;
	EndIf;
	
	RefillPrices();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectSelectedRows(Command)
	
	RowsArray = Items.Goods.SelectedRows;
	
	If RowsArray.Count() = 0 Then
		MessageText = NStr("vi = 'Trong danh sách không có các dòng được chọn';
							|ru = 'В списке отсутствуют выделенные строки';
							|en = 'No selected lines in the list'; fa = 'No selected lines in the list';
							|it = 'Nell''elenco mancano le righe selezionate';
							|pl = 'Na liście brakuje wybranych wierszy';
							|tr = 'Listede seçili satır yok'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;
	
	For Each LineNumber In RowsArray Do
		TSRow = Object.Goods.FindByID(LineNumber);
		TSRow.Selected = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearSelectedRows(Command)
	
	RowsArray = Items.Goods.SelectedRows;
	
	If RowsArray.Count() = 0 Then
		MessageText = NStr("vi = 'Trong danh sách không có các dòng được chọn';
							|ru = 'В списке отсутствуют выделенные строки';
							|en = 'No selected lines in the list'; fa = 'No selected lines in the list';
							|it = 'Nell''elenco mancano le righe selezionate';
							|pl = 'Na liście brakuje wybranych wierszy';
							|tr = 'Listede seçili satır yok'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;
	
	For Each LineNumber In RowsArray Do
		TSRow = Object.Goods.FindByID(LineNumber);
		TSRow.Selected = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure SetDefaultQuantity(Command)
	
	SetDefaultQuantityOnServer();
	
EndProcedure

&AtClient
Procedure FillInTheGoodsTable(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	If Object.Goods.Count() = 0 Then
		
		FillInTableOfProductsOnServer(False);
		
	Else
		
		QueryText = NStr("vi = 'Lưu dữ liệu về số lượng, khuôn mẫu trong phần bảng khi điền lại?';
						|ru = 'Сохранить данные о количестве, шаблонах в табличной части при перезаполнении?';
						|en = 'Save information on quantity and templates in the table when refilling?'; fa = 'Save information on quantity and templates in the table when refilling?';
						|it = 'Salvare i dati sul numero, sui modelli nella parte tabulare durante il ricompilazione?';
						|pl = 'Zapisać dane o ilości, szablonach w tabelarycznej części przy ponownym wypełnianiu?';
						|tr = 'Yeniden doldurma sırasında tablo kısmındaki miktarlar, şablonlar hakkındaki veriler kaydedilsin mi?'");
		CallbackDescription = New CallbackDescription("FillInTheGoodsTableCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel,,DialogReturnCode.Yes);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheGoodsTableCompletion(QuestionResult, AdditionalParameters) Export
	
	Result = QuestionResult;
	If Result = DialogReturnCode.Yes Then
		
		FillInTableOfProductsOnServer(True);
		
	ElsIf Result = DialogReturnCode.No Then
		
		FillInTableOfProductsOnServer(False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	ClearMessages();
	
	CheckResult = ExecuteCheck(ThisForm);
	If Not CheckResult.ProductsSelected Then
		MessageText = NStr("vi = 'Chưa chọn mặt hàng nào';
							|ru = 'Не выбрано ни одного товара';
							|en = 'No goods selected'; fa = 'No goods selected';
							|it = 'Nessuna merce è stata selezionata';
							|pl = 'Nie wybrano ani jednego towaru';
							|tr = 'Hiç bir ürün seçilmedi'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;
	
	If CheckResult.CheckCompleted Then
		
		CommandParameter = New Array;
		CommandParameter.Add(PredefinedValue("Catalog.Products.EmptyRef"));
		
		TemplatesNames = "";
		
		If Mode = "PrintPriceTagsAndLabels" Then
			TemplatesNames = "LabelProducts_,PriceTagProducts";
		ElsIf Mode = "PrintingPriceTags" Then
			TemplatesNames = "PriceTagProducts";
		ElsIf Mode = "PrintLabels" Then
			TemplatesNames = "LabelProducts_";
		EndIf;
		
		PrintManagementClient.ExecutePrintCommand(
			"DataProcessor.PrintPriceTagsAndLabels",
			TemplatesNames,
			CommandParameter,
			ThisForm,
			GetParameters());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintToPrinter(Command)
	
	TemplatesNames       = "LabelProducts_";
	PrintManagerName = "DataProcessor.PrintPriceTagsAndLabels";
	
	ObjectsArray = New Array;
	ObjectsArray.Add(PredefinedValue("Catalog.Products.EmptyRef"));
	
	PrintManagementClient.ExecutePrintToPrinterCommand(PrintManagerName, TemplatesNames, ObjectsArray,
		GetParameters());
	
EndProcedure

&AtClient
Procedure ShowHideFilter(Command)
	
	FilterVisibility = Not FilterVisibility;
	Items.GroupFilter.Visible = FilterVisibility;
	If FilterVisibility Then
		Items.Filter.Title = NStr("vi = 'Ẩn lọc';
									|ru = 'Скрыть отбор';
									|en = 'Hide filter'; fa = 'Hide filter';
									|it = 'Nascondere selezione';
									|pl = 'Ukryj wybór';
									|tr = 'Filtreyi gizle'");
	Else
		Items.Filter.Title = NStr("vi = 'Hiển thị lọc';
									|ru = 'Показать отбор';
									|en = 'Show filter'; fa = 'نمایش فیلتر';
									|it = 'Visualizzare selezione';
									|pl = 'Pokaż filtr';
									|tr = 'Filtreyi göster'");
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowHideFillMode(Command)
	
	VisibilityOfFillMode = Not VisibilityOfFillMode;
	Items.GroupFillMode.Visible = VisibilityOfFillMode;
	If VisibilityOfFillMode Then
		Items.FillMode.Title = NStr("vi = 'Ẩn chế độ điền';
									|ru = 'Скрыть режим заполнения';
									|en = 'Hide fill mode'; fa = 'Hide fill mode';
									|it = 'Nascondere la modalità di compilazione';
									|pl = 'Ukryj tryb wypełnienia';
									|tr = 'Doldurma modunu gizle'");
	Else
		Items.FillMode.Title = NStr("vi = 'Hiển thị chế độ điền';
									|ru = 'Показать режим заполнения';
									|en = 'Show fill mode'; fa = 'نمایش حالت تکمیل';
									|it = 'Visualizzare la modalità di compilazione';
									|pl = 'Pokaż tryb wypełniania';
									|tr = 'Doldurma modunu göster'");
	EndIf;
	
EndProcedure

&AtClient
Procedure SetPriceTagQuantity(Command)
	
	RowsArray = Items.Goods.SelectedRows;
	If RowsArray.Count() = 0 Then
		MessageText = NStr("vi = 'Trong danh sách không có các dòng được chọn';
							|ru = 'В списке отсутствуют выделенные строки';
							|en = 'No selected lines in the list'; fa = 'No selected lines in the list';
							|it = 'Nell''elenco mancano le righe selezionate';
							|pl = 'Na liście brakuje wybranych wierszy';
							|tr = 'Listede seçili satır yok'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;
	
	ValueSelected = Undefined;
	AddlParameters = New Structure("RowsArray, ValueSelected", RowsArray, ValueSelected);
	CallbackDescription = New CallbackDescription("SetPriceTagQuantityCompletion", ThisObject, AddlParameters);
	ToolTipText = NStr("vi = 'Nhập số lượng nhãn';
						|ru = 'Введите количество ценников';
						|en = 'Enter price tag quantity'; fa = 'Enter price tag quantity';
						|it = 'Inserire il numero di cartellini dei prezzi';
						|pl = 'Wpisz ilość cenników';
						|tr = 'Fiyat etiketi miktarını girin'");
	ShowInputNumber(CallbackDescription, ValueSelected, ToolTipText, 10, 2);
	
EndProcedure

&AtClient
Procedure SetPriceTagQuantityCompletion(Number, AdditionalParameters) Export
	
	RowsArray = AdditionalParameters.RowsArray;
	ValueSelected = ?(Number = Undefined, AdditionalParameters.ValueSelected, Number);
	
	If (Number <> Undefined) Then
		
		For Each LineNumber In RowsArray Do
			TSRow = Object.Goods.FindByID(LineNumber);
			TSRow.NumberOfPriceTags = ValueSelected;
		EndDo;
		
	EndIf;

EndProcedure

&AtClient
Procedure SetTheNumberOfLabels_3(Command)
	
	RowsArray = Items.Goods.SelectedRows;
	If RowsArray.Count() = 0 Then
		MessageText = NStr("vi = 'Trong danh sách không có các dòng được chọn';
							|ru = 'В списке отсутствуют выделенные строки';
							|en = 'No selected lines in the list'; fa = 'No selected lines in the list';
							|it = 'Nell''elenco mancano le righe selezionate';
							|pl = 'Na liście brakuje wybranych wierszy';
							|tr = 'Listede seçili satır yok'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;
	
	ValueSelected = Undefined;
	AddlParameters = New Structure("RowsArray, ValueSelected", RowsArray, ValueSelected);
	CallbackDescription = New CallbackDescription("SetTheNumberOfLabels_3Completion", ThisObject, AddlParameters);
	ToolTipText = NStr("vi = 'Nhập số lượng';
						|ru = 'Введите количество';
						|en = 'Enter quantity'; fa = 'ورود مقدار';
						|it = 'Inserire il numero';
						|pl = 'Wpisz ilość';
						|tr = 'Lütfen, miktar girin'");
	ShowInputNumber(CallbackDescription, ValueSelected, ToolTipText, 10, 2);
	
EndProcedure

&AtClient
Procedure SetTheNumberOfLabels_3Completion(Number, AdditionalParameters) Export
	
	RowsArray = AdditionalParameters.RowsArray;
	ValueSelected = ?(Number = Undefined, AdditionalParameters.ValueSelected, Number);
	
	If (Number <> Undefined) Then
		
		For Each LineNumber In RowsArray Do
			TSRow = Object.Goods.FindByID(LineNumber);
			TSRow.NumberOfLabels = ValueSelected;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetPriceTagTemplate(Command)
	
	RowsArray = Items.Goods.SelectedRows;
	If RowsArray.Count() = 0 Then
		MessageText = NStr("vi = 'Trong danh sách không có các dòng được chọn';
							|ru = 'В списке отсутствуют выделенные строки';
							|en = 'No selected lines in the list'; fa = 'No selected lines in the list';
							|it = 'Nell''elenco mancano le righe selezionate';
							|pl = 'Na liście brakuje wybranych wierszy';
							|tr = 'Listede seçili satır yok'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("Filter", New Structure("Purpose", PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag")));
	
	AddlParameters = New Structure("RowsArray", RowsArray);
	CallbackDescription = New CallbackDescription("SetPriceTagTemplateCompletion", ThisObject, AddlParameters);
	OpenForm("Catalog.LabelAndPriceTagTemplates.ChoiceForm",
		ChoiceFormParameters, ThisForm,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetPriceTagTemplateCompletion(Result, AdditionalParameters) Export
	
	RowsArray = AdditionalParameters.RowsArray;
	
	ValueSelected = Result;
	
	If ValueIsFilled(ValueSelected) Then
		
		For Each LineNumber In RowsArray Do
			TSRow = Object.Goods.FindByID(LineNumber);
			TSRow.PriceTagTemplate  = ValueSelected;
		EndDo;
		
	EndIf;
	
	UpdateVisibilityOfTemplateDependentFields();
	
EndProcedure

&AtClient
Procedure SetLabelTemplate(Command)
	
	RowsArray = Items.Goods.SelectedRows;
	If RowsArray.Count() = 0 Then
		MessageText = NStr("vi = 'Trong danh sách không có các dòng được chọn';
							|ru = 'В списке отсутствуют выделенные строки';
							|en = 'No selected lines in the list'; fa = 'No selected lines in the list';
							|it = 'Nell''elenco mancano le righe selezionate';
							|pl = 'Na liście brakuje wybranych wierszy';
							|tr = 'Listede seçili satır yok'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	EndIf;
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("Filter", New Structure("Purpose", PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel")));
	
	AddlParameters = New Structure("RowsArray", RowsArray);
	CallbackDescription = New CallbackDescription("SetLabelTemplateCompletion", ThisObject, AddlParameters);
	OpenForm("Catalog.LabelAndPriceTagTemplates.ChoiceForm",
		ChoiceFormParameters, ThisObject,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetLabelTemplateCompletion(Result, AdditionalParameters) Export
	
	RowsArray = AdditionalParameters.RowsArray;
	
	ValueSelected = Result;
	
	If ValueIsFilled(ValueSelected) Then
		
		For Each LineNumber In RowsArray Do
			TSRow = Object.Goods.FindByID(LineNumber);
			TSRow.LabelsTemplate = ValueSelected;
		EndDo;
		
	EndIf;
	
	UpdateVisibilityOfTemplateDependentFields();
	
EndProcedure

&AtClient
Procedure SetModePrintPriceTags(Command)
	
	SetPrintPriceTagsModeOnServer();
	
EndProcedure

&AtClient
Procedure SetModePrintLabelsAndPriceTags(Command)
	
	SetModeToPrintLabelsAndPriceTagsOnServer();
	
EndProcedure

&AtClient
Procedure SetModePrintLabels(Command)
	
	SetLabelPrintingModeOnServer();
	
EndProcedure

&AtClient
Procedure InstallANewBarcodeEAN13(Command)
	
	ClearMessages();
	
	HasErrors	= False;
	RowsArray	= New Array;
	
	For Each RowID In Items.Goods.SelectedRows Do
		CurrentRow = Object.Goods.FindByID(RowID);
		
		If CurrentRow = Undefined Then
			Continue;
		EndIf;
		
		LineNumber = CurrentRow["LineNumber"];
		
		If Not ValueIsFilled(CurrentRow.Products) Then
			MessageText = NStr("ru = 'Не заполнена колонка ""Номенклатура"" в строке %1.';
								|vi = 'The ""Items"" column is not filled in line %1.';
								|en = 'The ""Items"" column is not filled in line %1.'; fa = 'The ""Items"" column is not filled in line %1.';
								|it = 'The ""Items"" column is not filled in line %1.';
								|pl = 'The ""Items"" column is not filled in line %1.';
								|tr = '%1 satırında ""Öğe"" sütunu doldurulmamış.'");
			MessageText = StrTemplate(MessageText, LineNumber);
			
			Field = CommonClientServer.PathToTabularSection( "Goods", LineNumber, "Products");
			
			CommonClient.MessageToUser(MessageText, Undefined, Field, "Object", HasErrors);
			
			Continue;
		EndIf;
		
		If ValueIsFilled(CurrentRow.Products)
			And Not ValueIsFilled(CurrentRow.Characteristic)
			And CurrentRow.ItemVariantsAreUsed Then
			
			MessageText = NStr("ru = 'Не заполнена колонка ""Характеристика"" в строке %1.';
								|vi = 'The ""Variant"" column is not filled in line %1.';
								|en = 'The ""Variant"" column is not filled in line %1.'; fa = 'The ""Variant"" column is not filled in line %1.';
								|it = 'The ""Variant"" column is not filled in line %1.';
								|pl = 'The ""Variant"" column is not filled in line %1.';
								|tr = '%1 satırında ""Varyant"" sütunu doldurulmamış.'");
			MessageText = StrTemplate(MessageText, LineNumber);
			
			Field = CommonClientServer.PathToTabularSection("Goods", LineNumber, "Characteristic");
			
			CommonClient.MessageToUser(MessageText, Undefined, Field, "Object", HasErrors);
			
			Continue;
			
		EndIf;
		
		RowsArray.Add(RowID);
	EndDo;
	
	If Not HasErrors
		And RowsArray.Count() = 0 Then
		
		MessageText = NStr("vi = 'Trong danh sách không có các dòng được chọn';
							|ru = 'В списке отсутствуют выделенные строки';
							|en = 'No selected lines in the list'; fa = 'No selected lines in the list';
							|it = 'Nell''elenco mancano le righe selezionate';
							|pl = 'Na liście brakuje wybranych wierszy';
							|tr = 'Listede seçili satır yok'");
		
		ShowMessageBox(Undefined, MessageText);
		
		Return;
	EndIf;
	
	ErrorDescription	= "";
	Result		= InstallNewEAN13BarcodesOnServer(RowsArray, ErrorDescription);
	
	If Result = 0
		And Not IsBlankString(ErrorDescription) Then
		
		ShowMessageBox(Undefined, ErrorDescription);
		
		Return;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RestoreDefaultFilterSettings(Command)
	
	LoadDefaultSelectionSettings();
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.PrintPriceTagsAndLabels.FormGoods.Command.SelectGoods",,True);
	
	FormParameters = New Structure;
	FormParameters.Insert("ModeOfSelectionWithoutQuantitativeParameters", True);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",       True);
	FormParameters.Insert("HideTheViewPriceColumn",                  True);
	FormParameters.Insert("HideTheItemPricesCommand",         True);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses",         True);
	FormParameters.Insert("HideTheRequestQuantityButton",     True);
	FormParameters.Insert("Document ",                               PredefinedValue("Document.PriceSetup.EmptyRef"));
	FormParameters.Insert("Title",                               NStr("vi = 'Chọn hàng hóa';
																		|ru = 'Подбор товаров';
																		|en = 'Pick goods'; fa = 'انتخاب کالاها';
																		|it = 'Selezione delle merci';
																		|pl = 'Wybór towarów';
																		|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date",                                    Object.Date);
	FormParameters.Insert("DoNotSplitSetsByComponents",        True);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);

EndProcedure

&AtClient
Procedure SelectPackagingFillingOption(Command)
	
	RowsSelected = New Array;
	ClearMessages = True;
	
	If Items.Goods.SelectedRows.Count() = 0 Then
		CheckClearMessages(ClearMessages);
		MessageText = NStr("vi = 'Không một dòng nào được chọn. Đóng gói là không thể.';
							|ru = 'Не выделено ни одной строки. Заполнение упаковок невозможно.';
							|en = 'No lines selected. Cannot fill in packaging units.'; fa = 'No lines selected. Cannot fill in packaging units.';
							|it = 'Nessuna riga selezionata. La compilazione di imballaggio non è possibile.';
							|pl = 'Nie wybrano ani jednego wiersza. Wypełnienie opakowań jest niemożliwe.';
							|tr = 'Hiçbir satır vurgulanmadı. Paketleri doldurmak mümkün değildir.'");
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	For Each RowID In Items.Goods.SelectedRows Do
		String = Object.Goods.FindByID(RowID);
		If String <> Undefined Then
			If String.Selected Then
				If String.NumberOfLabels = 0 Then
					CheckClearMessages(ClearMessages);
					MessageText = NStr("vi = 'Dòng %Number% không cho biết số lượng nhãn. Gói trong đó sẽ không được điền.';
										|ru = 'В строке %Number% не указано количество этикеток. Упаковки в ней не будут заполнены.';
										|en = 'Number of labels is not specified in line %Number%. Packaging units will not be populated in it.'; fa = 'Number of labels is not specified in line %Number%. Packaging units will not be populated in it.';
										|it = 'Nella riga %Number% non è indicato il numero di etichette. Gli imballaggi in essa non verranno compilati.';
										|pl = 'W wierszu %Number% nie podano ilość etykiet. Opakowania nie zostaną w nim wypełnione.';
										|tr = '%Number% satır etiket sayısını içermemektedir. İçindeki paketler doldurulmayacaktır.'");
					MessageText = StrReplace(MessageText, "%Number%", String.LineNumber);
					CommonClient.MessageToUser(MessageText, );
				Else
					RowsSelected.Add(RowID);
				EndIf;				
			Else
				CheckClearMessages(ClearMessages);
				MessageText = NStr("vi = 'Dòng %Number% không được chọn. Gói trong đó sẽ không được điền.';
									|ru = 'Строка %Number% не выбрана. Упаковки в ней не будут заполнены.';
									|en = 'Line %Number% is not selected. Packaging units in this line will not be populated.'; fa = 'Line %Number% is not selected. Packaging units in this line will not be populated.';
									|it = 'La riga %Number% non è selezionata. Gli imballaggi in essa non verranno compilati.';
									|pl = 'Wiersz %Number% nie jest wybrany. Opakowania nie zostaną w nim wypełnione.';
									|tr = '%Number% satırı seçilmedi. İçindeki paketler doldurulmayacaktır.'");
				MessageText = StrReplace(MessageText, "%Number%", String.LineNumber);
				CommonClient.MessageToUser(MessageText);
			EndIf;
		EndIf;
	EndDo;
	
	If RowsSelected.Count() = 0 Then
		Return;
	EndIf;
				
	CallbackDescriptionOnClose = New CallbackDescription("SelectPackagingFillingOptionCompletion", ThisForm, RowsSelected);
	
	ParametersOfFormToOpen = New Structure("Variant, WarehouseGroup", Object.Variant, Object.WarehouseGroup);
	OpenForm("DataProcessor.PrintPriceTagsAndLabels.Form.SelectFillingVariantByPackages",
		ParametersOfFormToOpen, ThisForm,,,, CallbackDescriptionOnClose, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	
	If Mode = "PrintingPriceTags" Then
		StringSplittingParameters.FieldNameQuantity = "NumberOfPriceTags";
	ElsIf Mode = "PrintLabels" Then
		StringSplittingParameters.FieldNameQuantity = "NumberOfLabels";
	Else
		Raise NStr("vi = 'Lệnh ngắt dòng không được hỗ trợ trong việc in thẻ giá và nhãn';
					|ru = 'Команда разбиения строк не поддерживается в режиме печати ценников и этикеток';
					|en = 'Line split command is not supported in the mode of printing price tags and labels'; fa = 'Line split command is not supported in the mode of printing price tags and labels';
					|it = 'Il comando della divisione delle righe non è supportato nella modalità di stampa dei cartellini prezzi e delle etichette';
					|pl = 'Komenda podziału wierszy nie jest obsługiwana w trybie drukowania cenników i etykiet';
					|tr = 'Satır sonu komutu fiyat etiketi ve etiket yazdırma modunda desteklenmez'");
	EndIf;
	
	StringSplittingParameters.Title = NStr("vi = 'Nhập số lượng nhãn trong một dòng mới';
											|ru = 'Введите количество этикеток в новой строке';
											|en = 'Enter label quantity in a new line'; fa = 'Enter label quantity in a new line';
											|it = 'Inserire il numero di etichette nella nuova riga';
											|pl = 'Wpisz ilość etykiet w nowym wierszu';
											|tr = 'Etiket miktarını yeni bir satıra girin'");
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable,, StringSplittingParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfLabels.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.LabelsTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPriceTags.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceTagTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPriceTags.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NumberOfPriceTags");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPriceTagTemplate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceTagTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfLabels.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NumberOfLabels");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsLabelsTemplate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.LabelsTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

EndProcedure

#Region FillingAndInitialization

&AtServer
Procedure FillInDefaultValues()
	
	Object.PriceKind = Catalogs.TypesOfPrices.DefaultPriceType(Object.PriceKind);
	Object.Warehouse = SettingsValueCached.GetDefaultRetailWarehouse(Object.Warehouse);
	Object.Organization = SettingsValueCached.GetDefaultOrganization(Object.Organization);
	
EndProcedure

&AtServer
Procedure FillInSourceProductsPrepareFillingParameters(FillParameters)
	
	If TypeOf(FillParameters.Goods) <> Type("ValueTable") Then
		
		Order  = 1;
		NumberType = New TypeDescription("Number", New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
		
		Goods = New ValueTable;
		Goods.Columns.Add("Order",        NumberType);
		Goods.Columns.Add("Products",   New TypeDescription("CatalogRef.Products"));
		Goods.Columns.Add("Package",       New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		Goods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		Goods.Columns.Add("Count",     NumberType);
		
		For Each RowOfGoods In FillParameters.Goods Do
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, RowOfGoods);
			
			NewRow.Order = Order;
			
			Order = Order + 1;
		EndDo;
		
		FillParameters.Goods = Goods.Copy();
		
	EndIf;
	
	Object.InitialDataGoods.Load(FillParameters.Goods);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function GetParameters()
	
	Goods = New ValueTable;
	Goods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Goods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Goods.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	Goods.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Goods.Columns.Add("Price", New TypeDescription("Number"));
	Goods.Columns.Add("PriceAdditionally", New TypeDescription("Number"));
	Goods.Columns.Add("Barcode", New TypeDescription("String"));
	Goods.Columns.Add("PriceTagTemplate", New TypeDescription("CatalogRef.LabelAndPriceTagTemplates"));
	Goods.Columns.Add("NumberOfPriceTags", New TypeDescription("Number"));
	Goods.Columns.Add("LabelsTemplate", New TypeDescription("CatalogRef.LabelAndPriceTagTemplates"));
	Goods.Columns.Add("LabelTemplatePrepared", New TypeDescription("CatalogRef.LabelAndPriceTagTemplates"));
	Goods.Columns.Add("NumberOfLabels", New TypeDescription("Number"));
	Goods.Columns.Add("WarehouseStockBalance", New TypeDescription("Number"));
	Goods.Columns.Add("QuantityOfGoodsInDocument", New TypeDescription("Number"));
	Goods.Columns.Add("SoldByWeight", New TypeDescription("Boolean"));
	Goods.Columns.Add("LastPriceChangeDate", New TypeDescription("Date"));
	Goods.Columns.Add("LastPriceChangeDateAdditionally", New TypeDescription("Date"));
	
	For Each TSRow In Object.Goods Do
		If Not TSRow.Selected Then
			Continue;
		EndIf;
		NewRow = Goods.Add();
		FillPropertyValues(NewRow, TSRow);
		If Not ValueIsFilled(NewRow.LabelsTemplate) Then
			NewRow.NumberOfLabels = 0;
		EndIf;
		If Not ValueIsFilled(NewRow.PriceTagTemplate) Then
			NewRow.NumberOfPriceTags = 0;
		EndIf;
	EndDo;
	
	MaximumCodeOfGoodsSoldByWeight = OfflinePeripheralsServerCall.MaximumCodeOfGoodsSoldByWeight();
	SetPrivilegedMode(True);
	RuleOfExportToScales = (Common.ObjectAttributeValue(Object.ExchangeRule, "PeripheralType") = Enums.PeripheralTypes.LabelPrintingScales);
	SetPrivilegedMode(False);
	
	RegistrationCountry = ?(ValueIsFilled(Object.Organization), SettingsValueClientServerCached.CountryOfOrganizationRegistration(Object.Organization), Constants.MainCountry.Get());
	
	PrintParameters = New Structure;
	PrintParameters.Insert("Goods", PutToTempStorage(Goods, UUID));
	PrintParameters.Insert("Organization",   Object.Organization);
	PrintParameters.Insert("RegistrationCountry", RegistrationCountry);
	PrintParameters.Insert("ExchangeRule", Object.ExchangeRule);
	PrintParameters.Insert("MaximumCodeOfGoodsSoldByWeight", MaximumCodeOfGoodsSoldByWeight);
	PrintParameters.Insert("RuleOfExportToScales",          RuleOfExportToScales);
	PrintParameters.Insert("PriceKind",       Object.PriceKind);
	PrintParameters.Insert("Date",          Object.Date);
	PrintParameters.Insert("Warehouse",         Object.Warehouse);
	PrintParameters.Insert("PriceKindAdditional", Object.PriceKindAdditional);
	PrintParameters.Insert("DateAdditionally",    Object.DateAdditionally);
	PrintParameters.Insert("StructureOfTemplateTemplate", Undefined);
	
	Return PrintParameters;
	
EndFunction

&AtServer
Procedure SetModeToPrintLabelsAndPriceTagsOnServer()
	
	AutoTitle = False;
	Mode = "PrintPriceTagsAndLabels";
	
	If PrintFromDocument Then
		Title = NStr("vi = 'In nhãn tem và nhãn giá từ chứng từ';
					|ru = 'Печать этикеток и ценников из документа';
					|en = 'Print labels and price tags from document'; fa = 'Print labels and price tags from document';
					|it = 'Stampa di etichette e cartellini prezzi da un documento';
					|pl = 'Drukowanie etykiet i cenników z dokumentu';
					|tr = 'Fiyat etiketlerini ve etiketleri belgeden yazdır'");
	Else
		Title = NStr("vi = 'In nhãn giá và nhãn tem';
					|ru = 'Печать этикеток и ценников';
					|en = 'Print price tags and labels'; fa = 'چاپ برچسب‌های قیمت و برچسب‌ها';
					|it = 'Stampa di etichette e cartellini prezzi';
					|pl = 'Drukowanie etykiet i cenników';
					|tr = 'Fiyat etiketlerini ve etiketleri yazdır'");
	EndIf;
	
	UpdateItemsVisibility();
	
EndProcedure

&AtServer
Procedure SetLabelPrintingModeOnServer()
	
	AutoTitle = False;
	Mode = "PrintLabels";
	
	If PrintFromDocument Then
		Title = NStr("vi = 'In nhãn tem từ chứng từ';
					|ru = 'Печать этикеток из документа';
					|en = 'Print labels from document'; fa = 'Print labels from document';
					|it = 'Stampa di etichette da un documento';
					|pl = 'Drukowanie etykiet z dokumentu';
					|tr = 'Etiketleri belgeden yazdır'");
	Else
		Title = NStr("vi = 'In nhãn tem';
					|ru = 'Печать этикеток';
					|en = 'Print labels'; fa = 'چاپ برچسب‌ها';
					|it = 'Stampa di etichette';
					|pl = 'Drukowanie etykiet';
					|tr = 'Etiketleri yazdır'");
	EndIf;
	
	UpdateItemsVisibility();
	
EndProcedure

&AtServer
Procedure UpdateItemsVisibility()
	
	LabelVisibility = False;
	VisibilityPriceTags  = False;
	
	If Mode = "PrintPriceTagsAndLabels" Then
		LabelVisibility = True;
		VisibilityPriceTags  = True;
	ElsIf Mode = "PrintingPriceTags" Then
		LabelVisibility = False;
		VisibilityPriceTags  = True;
	ElsIf Mode = "PrintLabels" Then
		LabelVisibility = True;
		VisibilityPriceTags  = False;
	EndIf;
	
	Items.GoodsSplitRow.Visible = Not (VisibilityPriceTags And LabelVisibility);
	
	Items.GoodsNumberOfLabels.Visible               = LabelVisibility;
	Items.GoodsLabelsTemplate.Visible                   = LabelVisibility;
	Items.GoodsSetLabelTemplate.Visible         = LabelVisibility;
	Items.GoodsSetTheNumberOfLabels_3.Visible     = LabelVisibility;
	Items.TheFillModeLabel.Visible                = LabelVisibility;
	Items.FillInTheNumberOfLabelsForTheDocument.Visible = LabelVisibility And PrintFromDocument;
	
	Items.GoodsNumberOfPriceTags.Visible               = VisibilityPriceTags;
	Items.GoodsPriceTagTemplate.Visible                    = VisibilityPriceTags;
	Items.GoodsSetPriceTagTemplate.Visible         = VisibilityPriceTags;
	Items.GoodsSetPriceTagQuantity.Visible     = VisibilityPriceTags;
	Items.PriceTagFillMode.Visible                = VisibilityPriceTags;
	Items.FillInTheNumberOfPriceTagsForTheDocument.Visible = VisibilityPriceTags And PrintFromDocument;
	Items.GoodsSelectPackagingFillingOption.Visible = LabelVisibility;
	
EndProcedure

&AtServer
Procedure SetPrintPriceTagsModeOnServer()
	
	AutoTitle = False;
	Mode = "PrintingPriceTags";
	
	If PrintFromDocument Then
		Title = NStr("vi = 'In nhãn giá từ chứng từ';
					|ru = 'Печать ценников из документа';
					|en = 'Print price tags from document'; fa = 'Print price tags from document';
					|it = 'Stampa dei cartellini prezzi da un documento';
					|pl = 'Drukowanie cenników z dokumentu';
					|tr = 'Belgeden fiyat etiketlerini yazdır'");
	Else
		Title = NStr("vi = 'In nhãn giá';
					|ru = 'Печать ценников';
					|en = 'Print price tags'; fa = 'چاپ برچسب‌های قیمت';
					|it = 'Stampa dei cartellini prezzi';
					|pl = 'Drukowanie cenników';
					|tr = 'Fiyat etiketlerini yazdır'");
	EndIf;
	
	UpdateItemsVisibility();
	
EndProcedure

&AtServer
Procedure SetMode(ModeParameter)
	
	If ModeParameter = "PrintPriceTagsAndLabels" Then
		SetModeToPrintLabelsAndPriceTagsOnServer();
	ElsIf ModeParameter = "PrintingPriceTags" Then
		SetPrintPriceTagsModeOnServer();
	ElsIf ModeParameter = "PrintLabels" Then
		SetLabelPrintingModeOnServer();
	Else
		Raise NStr("vi = 'Không hỗ trợ chế độ in được cài đặt';
					|ru = 'Установленный режим печати не поддерживается';
					|en = 'Set print mode is not supported'; fa = 'Set print mode is not supported';
					|it = 'La modalità di stampa impostata non è supportata';
					|pl = 'Wybrany tryb drukowania nie jest obsługiwany';
					|tr = 'Yazdırma modunu ayarlama desteklenmiyor'");
	EndIf;
	
EndProcedure

&AtServer
Function InstallNewEAN13BarcodesOnServer(SelectedRows, ErrorDescription = "")
	
	Count	= 0;
	Barcodes	= New Map;
	
	MaximumValuesOfUnitBarcodes = InformationRegisters.ItemsBarcodes.GetMaximumValuesOfUnitBarcodes();
	MaximumValueOfWeightBarCode  = InformationRegisters.ItemsBarcodes.GetMaximumCodeValueOfWeightBarcodes();
	MaximumUnitProductCode              = InformationRegisters.ItemsBarcodes.MaximumUnitProductCode();
	MaximumCodeOfGoodsSoldByWeight              = InformationRegisters.ItemsBarcodes.MaximumCodeOfGoodsSoldByWeight();
	BarcodeNodePrefix                       = InformationRegisters.ItemsBarcodes.BarcodeNodePrefix();
	
	UseItemVariants	= GetFunctionalOption("UseItemVariants");
	UseItemPackages		= GetFunctionalOption("UseItemPackages");
	
	BeginTransaction();
	
	Try
		Block = New DataLock();
		
		LockItem = Block.Add("InformationRegister.ItemsBarcodes");
		LockItem.Mode = DataLockMode.Exclusive;
		
		Block.Lock();
		
		For Each LineNumber In SelectedRows Do
			TSRow = Object.Goods.FindByID(LineNumber);
			
			If IsBlankString(TSRow.Barcode) Then
				Count = Count + 1;
			Else
				Continue;
			EndIf;
			
			Code			= Undefined;
			Span	= Undefined;
			
			If Not TSRow.SoldByWeight Then
				For Each StringTSMaximumValues In MaximumValuesOfUnitBarcodes Do
					If StringTSMaximumValues.Code >= MaximumUnitProductCode Then
						Continue;
					EndIf;
					
					StringTSMaximumValues.Code = StringTSMaximumValues.Code + 1;
					
					Code			= StringTSMaximumValues.Code;
					Span	= StringTSMaximumValues.Span;
					
					Break;
				EndDo;
				
				If Code = Undefined Then
					Raise InformationRegisters.ItemsBarcodes.MessageTextNoFreeCodesPieceBarcodes();
				EndIf;
				
				Barcode = InformationRegisters.ItemsBarcodes.GetBarcodeByCode(Code, Span, BarcodeNodePrefix);
			Else
				If MaximumValueOfWeightBarCode = Undefined
					Or MaximumValueOfWeightBarCode >= MaximumCodeOfGoodsSoldByWeight Then
					
					Raise InformationRegisters.ItemsBarcodes.MessageTextNoFreeWeightBarcodesCodes();
					
				EndIf;
				
				MaximumValueOfWeightBarCode = MaximumValueOfWeightBarCode + 1;
				
				Barcode = InformationRegisters.ItemsBarcodes.GetBarcodeOfWeightProductByCode(MaximumValueOfWeightBarCode, BarcodeNodePrefix);
			EndIf;
			
			NewBarcode = InformationRegisters.ItemsBarcodes.CreateRecordManager();
			NewBarcode.Barcode = Barcode;
			NewBarcode.Products = TSRow.Products;
			If UseItemVariants Then
				NewBarcode.Characteristic = TSRow.Characteristic;
			EndIf;
			If UseItemsBatch Then
				NewBarcode.Series = TSRow.Series;
			EndIf;
			If UseItemPackages Then
				NewBarcode.Package = TSRow.Package;
			EndIf;
			
			NewBarcode.Write();
			
			If TSRow.SoldByWeight Then
				Barcodes.Insert(TSRow, InformationRegisters.ItemsBarcodes.PrepareBarcode(NewBarcode.Barcode));
			Else
				Barcodes.Insert(TSRow, NewBarcode.Barcode);
			EndIf;
		EndDo;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		ErrorDescription = NStr("vi = 'Đã xảy ra lỗi khi ghi mã vạch.
								|Ghi mã vạch không thành công.
								|Mô tả bổ sung:
								|%AdditionalDetails%';
								|ru = 'При записи штрихкодов произошла ошибка.
								|Запись штрихкодов не выполнена.
								|Дополнительное описание:
								|%AdditionalDetails%';
								|en = 'An error occurred while saving barcodes.
								|Barcodes are not saved.
								|Additional description:
								|%AdditionalDetails%'; fa = 'An error occurred while saving barcodes.
								|Barcodes are not saved.
								|Additional description:
								|%AdditionalDetails%';
								|it = 'Nel corso della registrazione dei codici a barre si è verificato un errore.
								|La registrazione dei codici a barre non è stata effettuata.
								|Descrizione aggiuntiva:
								|%AdditionalDetails%';
								|pl = 'Podczas zapisu kodów kreskowych wystąpił błąd.
								|Zapis kodów kreskowych nie powiódł się.
								|Dodatkowy opis: 
								|%AdditionalDetails%';
								|tr = 'Barkodlar yazılırken bir hata oluştu.
								| Barkodlar yazılmadı.
								| Detaylı açıklama:
								| %AdditionalDetails%'");
		ErrorDescription = StrReplace(ErrorDescription, "%AdditionalDetails%", ErrorInfo().Description);
		
		Return 0;
	EndTry;
	
	For Each KeyAndValue In Barcodes Do
		KeyAndValue.Key.Barcode = KeyAndValue.Value;
	EndDo;
	
	Return Count;
	
EndFunction

&AtServer
Procedure SetDefaultQuantityInTSStringOnServer(TSRow)
	
	// Calculation of the number of Labels.
	If FillInTheNumberOfLabelsForTheDocument And Not FillInTheNumberOfLabelsForStockBalances Then
		TSRow.NumberOfLabels = TSRow.QuantityOfGoodsInDocument;
	ElsIf FillInTheNumberOfLabelsForTheDocument And FillInTheNumberOfLabelsForStockBalances Then
		TSRow.NumberOfLabels = ?(TSRow.QuantityOfGoodsInDocument > TSRow.WarehouseStockBalance,TSRow.WarehouseStockBalance,TSRow.QuantityOfGoodsInDocument);
	ElsIf Not FillInTheNumberOfLabelsForTheDocument And FillInTheNumberOfLabelsForStockBalances Then
		TSRow.NumberOfLabels = ?(TSRow.WarehouseStockBalance > 0, TSRow.WarehouseStockBalance, 0);
	EndIf;
	
	// Calculation of the number of Price Tags.
	If FillInTheNumberOfPriceTagsForTheDocument And Not FillInTheNumberOfPriceTagsForStockBalances Then
		TSRow.NumberOfPriceTags = ?(TSRow.QuantityOfGoodsInDocument > 0, 1, 0);
	ElsIf FillInTheNumberOfPriceTagsForTheDocument And FillInTheNumberOfPriceTagsForStockBalances Then
		TSRow.NumberOfPriceTags = ?(TSRow.WarehouseStockBalance > 0 Or TSRow.QuantityOfGoodsInDocument > 0, 1, 0);
	ElsIf Not FillInTheNumberOfPriceTagsForTheDocument And FillInTheNumberOfPriceTagsForStockBalances Then
		TSRow.NumberOfPriceTags = ?(TSRow.WarehouseStockBalance > 0, 1, 0);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetDataParameters(SettingsStructure)
	
	SettingsStructure.DataParameters.Insert("Organization",          Object.Organization);
	If ValueIsFilled(Object.Date) Then
		SettingsStructure.DataParameters.Insert("Date",             Object.Date);
	Else
		SettingsStructure.DataParameters.Insert("Date",             CurrentSessionDate());
	EndIf;
	
	If ValueIsFilled(Object.DateAdditionally) Then
		SettingsStructure.DataParameters.Insert("DateAdditionally",    Object.DateAdditionally);
	Else
		SettingsStructure.DataParameters.Insert("DateAdditionally",    CurrentSessionDate());
	EndIf;
	
	MaximumCodeOfGoodsSoldByWeight = OfflinePeripheralsServerCall.MaximumCodeOfGoodsSoldByWeight();
	SetPrivilegedMode(True);
	RuleOfExportToScales = (Common.ObjectAttributeValue(Object.ExchangeRule, "PeripheralType") = Enums.PeripheralTypes.LabelPrintingScales);
	SetPrivilegedMode(False);
	
	SettingsStructure.DataParameters.Insert("PriceKind",              Object.PriceKind);
	SettingsStructure.DataParameters.Insert("PriceKindAdditional", Object.PriceKindAdditional);
	SettingsStructure.DataParameters.Insert("ExchangeRule",        Object.ExchangeRule);
	SettingsStructure.DataParameters.Insert("MaximumCodeOfGoodsSoldByWeight", MaximumCodeOfGoodsSoldByWeight);
	SettingsStructure.DataParameters.Insert("RuleOfExportToScales",          RuleOfExportToScales);
	SettingsStructure.DataParameters.Insert("PlanningObject",            ProductRangeServer.PlanningObject(Object.Warehouse, Object.Date));
	
EndProcedure

&AtServer
Procedure SetRequiredDataFields(SettingsStructure, AddTemplates = False)
	
	SettingsStructure.RequiredFields.Add("Barcode");
	SettingsStructure.RequiredFields.Add("Count");
	SettingsStructure.RequiredFields.Add("Products");
	If GetFunctionalOption("UseItemVariants") Then
		SettingsStructure.RequiredFields.Add("Characteristic");
		SettingsStructure.RequiredFields.Add("ItemVariantsAreUsed");
	EndIf;
	If UseItemsBatch Then
		SettingsStructure.RequiredFields.Add("Series");
	EndIf;
	If GetFunctionalOption("UseItemPackages") Then
		SettingsStructure.RequiredFields.Add("Package");
	EndIf;
	SettingsStructure.RequiredFields.Add("SoldByWeight");
	SettingsStructure.RequiredFields.Add("WarehouseStockBalance");
	
	SettingsStructure.RequiredFields.Add("Price");
	SettingsStructure.RequiredFields.Add("LastPriceChangeDate");
	
	If UseTheAdvancedPriceView And ValueIsFilled(Object.PriceKindAdditional) Then
		SettingsStructure.RequiredFields.Add("PriceAdditionally");
		SettingsStructure.RequiredFields.Add("LastPriceChangeDateAdditionally");
	EndIf;
	
	// Templates of labels and price tags.
	If AddTemplates Then
		SettingsStructure.RequiredFields.Add("Products.ProductKind.LabelsTemplate");
		SettingsStructure.RequiredFields.Add("Products.ProductKind.PriceTagTemplate");
		SettingsStructure.RequiredFields.Add("Products.LabelsTemplate");
		SettingsStructure.RequiredFields.Add("Products.PriceTagTemplate");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTableOfProductsOnServer(SavePatternsAndQuantities, UpdatingDataOnSelectedProducts = False)
	
	ControlProductRange = False;
	If Object.PriceReceivingMode = 2 Then
		
		ControlProductRange = ProductRangeServerCached.ControlProductRange(Object.Warehouse, Object.Date);
		
	EndIf;
	
	// Saving the selected positions for their subsequent recovery.
	If SavePatternsAndQuantities Then
		TableSelectedPositions = Object.Goods.Unload(,"Products, Characteristic, Series, Package, PriceTagTemplate, NumberOfPriceTags, LabelsTemplate, NumberOfLabels");
	EndIf;
	
	// The fields required for output to the table of products on the form.
	SettingsStructure = DataProcessors.PrintPriceTagsAndLabels.SettingsStructure();
	
	SetRequiredDataFields(SettingsStructure, True);
	
	SetDataParameters(SettingsStructure);
	
	SettingsStructure.SettingsComposer = SettingsComposer;
	
	If Object.InitialDataGoods.Count() > 0 Or PrintFromDocument Or UpdatingDataOnSelectedProducts Then
		If ControlProductRange Then
			SettingsStructure.NameOfDataLayoutSchemaTemplate = "TemplateFieldsGoodsProductRange";
		Else
			SettingsStructure.NameOfDataLayoutSchemaTemplate = "TemplateFieldsGoods";
		EndIf;
		If UpdatingDataOnSelectedProducts Then
			RawData = Object.Goods.Unload(,"Products, Characteristic, Series, Package");
			RawData.Columns.Add("Count", New TypeDescription("Number"));
			SettingsStructure.RawData = RawData;
		Else
			SettingsStructure.RawData = Object.InitialDataGoods.Unload();
		EndIf;
	Else
		If ControlProductRange Then
			SettingsStructure.NameOfDataLayoutSchemaTemplate = "DBTemplateFieldsGoodsRange";
		Else
			SettingsStructure.NameOfDataLayoutSchemaTemplate = "DBTemplateFieldsGoods";
		EndIf;
	EndIf;
	
	Object.Goods.Clear();

	LineNumber = 0;
	
	SettingsStructure.UsePriceManagementSystem25 = UsePriceManagementSystem25;
	
	// Loading the generated list of products.
	ResultStructure1 = DataProcessors.PrintPriceTagsAndLabels.PrepareDataStructure(SettingsStructure, "Goods");
	
	CheckSinglePackaging = True;
	If ResultStructure1.Table.Columns.Find("UsePackages") = Undefined 
		Or ResultStructure1.Table.Columns.Find("NotOneSinglePackaging") = Undefined Then
		CheckSinglePackaging = False;
	EndIf;
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseItemPackages = GetFunctionalOption("UseItemPackages");
	
	For Each TSRow In ResultStructure1.Table Do
		
		NewRow = Object.Goods.Add();
		NewRow.Products         = TSRow.Products;
		
		If UseItemVariants Then
			NewRow.Characteristic       = TSRow.Characteristic;
		EndIf;
		If UseItemsBatch Then
			NewRow.Series          = TSRow.Series;
		EndIf;
		If UseItemPackages Then
			NewRow.Package             = TSRow.Package;
		EndIf;
		
		NewRow.Price                        = TSRow.Price;
		NewRow.LastPriceChangeDate = TSRow.LastPriceChangeDate;
		If ValueIsFilled(Object.PriceKindAdditional) Then
			NewRow.PriceAdditionally                        = TSRow.PriceAdditionally;
			NewRow.LastPriceChangeDateAdditionally = TSRow.LastPriceChangeDateAdditionally;
		EndIf;
		
		If TSRow.SoldByWeight Then
			NewRow.Barcode = InformationRegisters.ItemsBarcodes.PrepareBarcode(TSRow.Barcode);
		Else
			NewRow.Barcode = TSRow.Barcode;
		EndIf;
		
		ProductTypePriceTagTemplate    = TSRow[ResultStructure1.MatchingDCSFieldsToTableColumns.Get("Products.ProductKind.PriceTagTemplate")];
		ProductPriceTagTemplate        = TSRow[ResultStructure1.MatchingDCSFieldsToTableColumns.Get("Products.PriceTagTemplate")];
		NewRow.PriceTagTemplate        = ?(ValueIsFilled(ProductPriceTagTemplate), ProductPriceTagTemplate, ProductTypePriceTagTemplate);
		
		ProductTypePriceTagTemplate    = TSRow[ResultStructure1.MatchingDCSFieldsToTableColumns.Get("Products.ProductKind.LabelsTemplate")];
		ProductPriceTagTemplate        = TSRow[ResultStructure1.MatchingDCSFieldsToTableColumns.Get("Products.LabelsTemplate")];
		NewRow.LabelsTemplate       = ?(ValueIsFilled(ProductPriceTagTemplate), ProductPriceTagTemplate, ProductTypePriceTagTemplate);
		
		NewRow.WarehouseStockBalance      = TSRow.WarehouseStockBalance;
		NewRow.QuantityOfGoodsInDocument = TSRow.Count;
		NewRow.SoldByWeight              = TSRow.SoldByWeight;
		If UseItemVariants Then
			NewRow.ItemVariantsAreUsed = TSRow.ItemVariantsAreUsed;
		EndIf;
		
		SetDefaultQuantityInTSStringOnServer(NewRow);
		
		// Restoring positions saved before filling in PM.
		If SavePatternsAndQuantities Then
			FilterParameters = New Structure();
			FilterParameters.Insert("Products", NewRow.Products);
			If UseItemVariants Then
				FilterParameters.Insert("Characteristic", NewRow.Characteristic);
			EndIf;
			If UseItemsBatch Then
				FilterParameters.Insert("Series", NewRow.Series);
			EndIf;
			If UseItemPackages Then
				FilterParameters.Insert("Package", NewRow.Package);
			EndIf;
			FoundRows = TableSelectedPositions.FindRows(FilterParameters);
			If FoundRows.Count() > 0 Then
				FillPropertyValues(NewRow, FoundRows[0]);
			EndIf;
		EndIf;
		
		NewRow.Selected = True;
		LineNumber = LineNumber + 1;
		
		If CheckSinglePackaging Then
			If TSRow.UsePackages
				And TSRow.NotOneSinglePackaging Then
				
				MessageText = NStr("vi = 'Mặt hàng ""%Products%"" sử dụng đóng gói với đơn vị tính ""%UnitOfMeasure%"" và hệ số bằng 1. Để gán mã vạch chi tiết, cần sử dụng một đơn vị đóng gói.';
									|ru = 'У номенклатуры ""%Products%"" используется несколько упаковок с единицей измерения ""%UnitOfMeasure%"" и коэффициентом 1. Для корректной привязки штрихкодов рекомендуется использовать одну единичную упаковку.';
									|en = 'Several packaging units with unit of measure ""%UnitOfMeasure%"" and factor 1 are used for items ""%Products%"". To link barcodes correctly, it is recommended that you use one single packaging unit.'; fa = 'Several packaging units with unit of measure ""%UnitOfMeasure%"" and factor 1 are used for items ""%Products%"". To link barcodes correctly, it is recommended that you use one single packaging unit.';
									|it = 'Per l''articolo ""%Products%"" vengono utilizzate più imballaggi con l''unità di misura ""%UnitOfMeasure%"" e coefficiente 1. Per il corretto collegamento dei codici a barre, si consiglia di utilizzare un singolo imballaggio.';
									|pl = 'Nomenklatura ""%Products%"" używa wielu paczek z jednostką miary ""%UnitOfMeasure%"" i współczynnik 1. Dla prawidłowego wiązania kodów kreskowych, zaleca się użycie jednego pakietu jednostkowego.';
									|tr = '""%Products%"" öğesi, ""%UnitOfMeasure%"" ölçü birimi ve faktör 1 ile birden fazla pakete sahiptir. Doğru barkod eşlemesi için bir birim paketi kullanılması önerilmektedir.'");
				MessageText = StrReplace(MessageText, "%Products%", String(TSRow.Products));
				MessageText = StrReplace(MessageText, "%UnitOfMeasure%", String(TSRow.UnitOfMeasure));
				
				Common.MessageToUser(MessageText,
					TSRow.Products,
					CommonClientServer.PathToTabularSection("Object.Goods", LineNumber, "Products"),
					"Object",
					False);
				
			EndIf;
		EndIf;
		
	EndDo;
	
	UpdateVisibilityOfTemplateDependentFields();
	
	Items.Goods.Refresh();
	
EndProcedure

&AtClientAtServerNoContext
Function ExecuteCheck(Form)
	
	HasErrors = False;
	
	For Each TSRow In Form.Object.Goods Do
		
		If Not TSRow.Selected Then
			Continue;
		EndIf;
		
		LineNumber = TSRow.LineNumber - 1;
		
		If Form.Mode = "PrintLabels" Or Form.Mode = "PrintPriceTagsAndLabels" Then
			
			If TSRow.NumberOfLabels = 0 Then
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền số lượng nhãn tem tại dòng: %1';
						|ru = 'Не заполнено количество этикеток в строке: %1';
						|en = 'Number of labels is required in line: %1'; fa = 'Number of labels is required in line: %1';
						|it = 'Non è compilato il numero delle etichette nella riga: %1';
						|pl = 'Nie została wypełniona ilość etykiet w wierszu: %1';
						|tr = 'Satırda etiket miktarı doldurulmadı: %1'"),
					LineNumber + 1);
				
				CommonClientServer.MessageToUser(
					MessageText,,
					"Object.Goods["+LineNumber+"].NumberOfLabels",,
					HasErrors);
				
			EndIf;
			
			If Not ValueIsFilled(TSRow.LabelsTemplate) Then
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa chọn khuôn mẫu nhãn tem tại dòng: %1';
						|ru = 'Не выбран шаблон этикетки в строке: %1';
						|en = 'Label template is not selected in line: %1'; fa = 'Label template is not selected in line: %1';
						|it = 'Nessun modello di etichetta selezionato nella riga: %1';
						|pl = 'Nie został wybrany szablon etykiety w wierszu: %1';
						|tr = 'Satırdaki etiket numunesi seçili değil: %1'"),
					LineNumber + 1);
				
				CommonClientServer.MessageToUser(
					MessageText,,
					"Object.Goods["+LineNumber+"].LabelsTemplate",,
					HasErrors);
				
			EndIf;
			
		EndIf;
		
		If Form.Mode = "PrintingPriceTags" Or Form.Mode = "PrintPriceTagsAndLabels" Then
			
			If TSRow.NumberOfPriceTags = 0 Then
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa điền số lượng nhãn giá tại dòng: %1';
						|ru = 'Не заполнено количество ценников в строке: %1';
						|en = 'Number of price tags is required in line: %1'; fa = 'Number of price tags is required in line: %1';
						|it = 'Non è compilato il numero dei cartellini prezzi nella riga: %1';
						|pl = 'Nie wypełniono ilość cenników w wierszu: %1';
						|tr = 'Satırda fiyat etiketlerinin miktarı doldurulmadı: %1'"),
					LineNumber + 1);
				
				CommonClientServer.MessageToUser(
					MessageText,,
					"Object.Goods["+LineNumber+"].NumberOfPriceTags",,
					HasErrors);
				
			EndIf;
			
			If Not ValueIsFilled(TSRow.PriceTagTemplate) Then
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chưa chọn khuôn mẫu nhãn giá tại dòng: %1';
						|ru = 'Не выбран шаблон ценника в строке: %1';
						|en = 'Price tag template is not selected in line: %1'; fa = 'Price tag template is not selected in line: %1';
						|it = 'Nessun modello di cartellino prezzi selezionato nella riga: %1';
						|pl = 'Nie został wybrany szablon cennika w wierszu: %1';
						|tr = 'Satırdaki fiyat etiketi numunesi seçili değil: %1'"),
					LineNumber + 1);
				
				CommonClientServer.MessageToUser(
					MessageText,,
					"Object.Goods["+LineNumber+"].PriceTagTemplate",,
					HasErrors);
				
			EndIf;
			
		EndIf;
	
	EndDo;

	Filter = New Structure("Selected", True);
	ProductsSelected = Form.Object.Goods.FindRows(Filter).Count() > 0;
	
	Return New Structure("ProductsSelected, CheckCompleted", ProductsSelected, Not HasErrors And Form.CheckFilling());
	
EndFunction

&AtServer
Procedure CheckFillingOfLabelTemplates(ProductsForPrinting, HasErrors = False)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Goods.Products AS Products
	|INTO Goods
	|FROM
	|	&GoodsTable AS Goods
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Goods.Products AS Products,
	|	CASE
	|		WHEN CatProducts.LabelsTemplate <> VALUE(Catalog.LabelAndPriceTagTemplates.EmptyRef)
	|			THEN CatProducts.LabelsTemplate
	|		ELSE CatProducts.ProductKind.LabelsTemplate
	|	END               AS LabelsTemplate
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON Goods.Products = CatProducts.Ref";
	
	Query.SetParameter("GoodsTable", ProductsForPrinting);
	
	TableOfGoods = Query.Execute().Unload();
	
	Filter = New Structure("LabelsTemplate", Catalogs.LabelAndPriceTagTemplates.EmptyRef());
	ProductLines_2 = TableOfGoods.FindRows(Filter);
	
	For Each RowOfGoods In ProductLines_2 Do
		MessageText = NStr("vi = 'Mặt hàng ""%Products%"" không có mẫu nhãn được chọn.';
							|ru = 'У номенклатуры ""%Products%"" не выбран шаблон этикетки.';
							|en = 'Label template is not selected for the ""%Products%"" items.'; fa = 'Label template is not selected for the ""%Products%"" items.';
							|it = 'Nessun modello di etichetta selezionato per l''articolo""%Products%"".';
							|pl = 'W nomenklaturze ""%Products%"" nie został wybrany szablon etykiety.';
							|tr = '""%Products%"" öğesinde etiket numunesi seçili değil.'");
		MessageText = StrReplace(MessageText, "%Products%", String(RowOfGoods.Products));
		
		Common.MessageToUser(MessageText, RowOfGoods.Products, "", "", HasErrors);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetDefaultQuantityOnServer()
	
	For Each TSRow In Object.Goods Do
		
		SetDefaultQuantityInTSStringOnServer(TSRow);		
		
	EndDo;
	
EndProcedure

&AtServer
Function SetDCSSelectionElement(ParameterName, ParameterValue, Use = True)

	FoundItem = Undefined;
	
	Field = New DataCompositionField(ParameterName);
	
	Filter = SettingsComposer.Settings.Filter;
	For Each FilterElement In Filter.Items Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			Continue;
		EndIf;
		If FilterElement.LeftValue = Field Then
			FoundItem = FilterElement;
		EndIf;
	EndDo;
	
	If FoundItem = Undefined Then
		FoundItem = Filter.Items.Add(Type("DataCompositionFilterItem"));
	EndIf;
	
	If TypeOf(ParameterValue) = Type("Array") Then
		FoundItem.ComparisonType = DataCompositionComparisonType.InList;
		ValueList = New ValueList;
		ValueList.LoadValues(ParameterValue);
		RightValue = ValueList;
	ElsIf TypeOf(ParameterValue) = Type("CatalogRef.Warehouses") And Catalogs.Warehouses.IsFolder(ParameterValue) Then
		FoundItem.ComparisonType = DataCompositionComparisonType.InHierarchy;
		RightValue = ParameterValue;
	Else
		FoundItem.ComparisonType = DataCompositionComparisonType.Equal;
		RightValue = ParameterValue;
	EndIf;
	
	FoundItem.Use  = Use;
	FoundItem.LeftValue  = Field;
	FoundItem.RightValue = RightValue;
	
	Return FoundItem;

EndFunction

&AtServer
Procedure LoadDefaultSelectionSettings()
	
	DataCompositionSchema = DataProcessors.PrintPriceTagsAndLabels.GetTemplate("TemplateFieldsGoods");

	DataSet25 = DataCompositionSchema.DataSets.Find("DataSet2_5");
	If DataSet25 <> Undefined Then
		If UsePriceManagementSystem25 Then
			DataCompositionSchema.DataSets.DataSet.Query = DataSet25.Query;
		EndIf;
		DataCompositionSchema.DataSets.Delete(DataSet25);
	EndIf;
	
	QueryText = DataCompositionSchema.DataSets.DataSet.Query;
	 
	QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor1",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPackages",
			"RawData.Products"));

	QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor2",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"SinglePackages.Package",
			"SinglePackages.Products"));

	QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor3",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"RawData.Package",
			"RawData.Products"));

	QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor4",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"SinglePackagesOfProducts.Package",
			"SinglePackagesOfProducts.Products"));
	
	ReplacementText = ?(UseItemsBatch,
					"RawData.Series",
					"VALUE(Catalog.ItemsBatches.EmptyRef)");
	
	QueryText = StrReplace(QueryText, "&DataBySeriesOverridable", ReplacementText);
	
	DataCompositionSchema.DataSets.DataSet.Query = QueryText;
	
	SettingsComposer.Initialize(
		New DataCompositionAvailableSettingsSource(PutToTempStorage(DataCompositionSchema, UUID)));
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
EndProcedure

&AtServer
Function WhenChangingProducts(CurrentData)
	
	// The fields required for output to the table of products on the form.
	SettingsStructure = DataProcessors.PrintPriceTagsAndLabels.SettingsStructure();
	
	SetRequiredDataFields(SettingsStructure, True);
	
	SetDataParameters(SettingsStructure);
	
	Table = New ValueTable;
	Table.Columns.Add("Products",   New TypeDescription("CatalogRef.Products"));
	Table.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Table.Columns.Add("Series",          New TypeDescription("CatalogRef.ItemsBatches"));
	Table.Columns.Add("Package",       New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Table.Columns.Add("Count",     New TypeDescription("Number"));
	NewRow = Table.Add();
	FillPropertyValues(NewRow, CurrentData);
	
	SettingsStructure.NameOfDataLayoutSchemaTemplate = "TemplateFieldsGoods";
	SettingsStructure.RawData                 = Table;
	
	SettingsStructure.UsePriceManagementSystem25 = UsePriceManagementSystem25;
	
	ResultStructure1 = DataProcessors.PrintPriceTagsAndLabels.PrepareDataStructure(SettingsStructure, "Goods");
	Data = ResultStructure1.Table[0];
	
	ReturnValue = New Structure("Barcode, SoldByWeight, WarehouseStockBalance, Price, LastPriceChangeDate, LabelsTemplate, PriceTagTemplate, ItemVariantsAreUsed");
	ReturnValue.Barcode = InformationRegisters.ItemsBarcodes.PrepareBarcode(
		Data[ResultStructure1.MatchingDCSFieldsToTableColumns["Barcode"]]);
	ReturnValue.Price            = Data[ResultStructure1.MatchingDCSFieldsToTableColumns["Price"]];
	ReturnValue.LastPriceChangeDate = Data[ResultStructure1.MatchingDCSFieldsToTableColumns["LastPriceChangeDate"]];
	ReturnValue.SoldByWeight         = Data[ResultStructure1.MatchingDCSFieldsToTableColumns["SoldByWeight"]];
	ReturnValue.WarehouseStockBalance = Data[ResultStructure1.MatchingDCSFieldsToTableColumns["WarehouseStockBalance"]];
	If GetFunctionalOption("UseItemVariants") Then
		ReturnValue.ItemVariantsAreUsed = Data[ResultStructure1.MatchingDCSFieldsToTableColumns["ItemVariantsAreUsed"]];
	Else
		ReturnValue.ItemVariantsAreUsed = False;
	EndIf;
	
	ProductTypePriceTagTemplate      = Data[ResultStructure1.MatchingDCSFieldsToTableColumns.Get("Products.ProductKind.PriceTagTemplate")];
	ProductPriceTagTemplate          = Data[ResultStructure1.MatchingDCSFieldsToTableColumns.Get("Products.PriceTagTemplate")];
	ReturnValue.PriceTagTemplate = ?(ValueIsFilled(ProductPriceTagTemplate), ProductPriceTagTemplate, ProductTypePriceTagTemplate);
	
	ProductTypePriceTagTemplate       = Data[ResultStructure1.MatchingDCSFieldsToTableColumns.Get("Products.ProductKind.LabelsTemplate")];
	ProductPriceTagTemplate           = Data[ResultStructure1.MatchingDCSFieldsToTableColumns.Get("Products.LabelsTemplate")];
	ReturnValue.LabelsTemplate = ?(ValueIsFilled(ProductPriceTagTemplate), ProductPriceTagTemplate, ProductTypePriceTagTemplate);
	
	If CurrentData.Property("OldPackaging") Then
		OldPackingRatio = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(CurrentData.OldPackaging, CurrentData.Products);
		PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(CurrentData.Package, CurrentData.Products);
		
		QuantityOfGoodsInDocument = CurrentData.OldQuantityInDocument
		/ ?(ValueIsFilled(PackagingFactor), PackagingFactor, 1)
		* ?(ValueIsFilled(OldPackingRatio), OldPackingRatio, 1);
		
		NumberOfLabels = CurrentData.NumberOfLabels
		/ ?(ValueIsFilled(PackagingFactor), PackagingFactor, 1)
		* ?(ValueIsFilled(OldPackingRatio), OldPackingRatio, 1);
		
		ReturnValue.Insert("NumberOfLabels", NumberOfLabels);
		ReturnValue.Insert("Count", QuantityOfGoodsInDocument);
		ReturnValue.Insert("QuantityOfGoodsInDocument", QuantityOfGoodsInDocument);
	EndIf;
	
	Return ReturnValue;
	
EndFunction

&AtServer
Function AddProductsByBarcode(BarcodeData_5, CachedValues)
	
	LockFormDataForEdit();
	
	Table = New ValueTable;
	Table.Columns.Add("Products",   New TypeDescription("CatalogRef.Products"));
	Table.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Table.Columns.Add("Series",          New TypeDescription("CatalogRef.ItemsBatches"));
	Table.Columns.Add("Package",       New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Table.Columns.Add("Count",     New TypeDescription("Number"));
	
	If CachedValues = Undefined Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	
	WeightBarCodePrefixes		= SettingsValueCached.GetWeightBarCodePrefixes();
	GetBarcodeData		= Not (BarcodeData_5.Count() > 0
										And BarcodeData_5[0].Property("Products"));
	ItemsBarcodes			= New Array;
	UnknownBarcodes			= New Array;
	PreviouslyUnencashedBarcodes	= New Array;
	NonCacheableBarcodes			= New Array;
	BatchBarcodes					= New Array;
	
	For Each CurBarcode In BarcodeData_5 Do
		CurBarcode.Barcode = Upper(TrimAll(CurBarcode.Barcode));
		InformationRegisters.ItemsBarcodes.ConvertWeightBarcode(CurBarcode, WeightBarCodePrefixes);
		
		If GetBarcodeData Then
			If Not ValueIsFilled(CachedValues.Barcodes[CurBarcode.Barcode])
				Or CachedValues.Barcodes[CurBarcode.Barcode].UnknownBarcode Then
				
				PreviouslyUnencashedBarcodes.Add(CurBarcode.Barcode);
				
			EndIf;
		Else
			ItemsBarcodes.Add(CurBarcode);
			PreviouslyUnencashedBarcodes.Add(CurBarcode.Barcode);
		EndIf;
	EndDo;
	
	If PreviouslyUnencashedBarcodes.Count() > 0 Then
		If GetBarcodeData Then
			InformationRegisters.ItemsBarcodes.GetDataOnBarcodesAdvanced(CachedValues,
																						PreviouslyUnencashedBarcodes);
		Else
			InformationRegisters.ItemsBarcodes.GetDataOnItemBarcodes(CachedValues,
																							ItemsBarcodes);
		EndIf;
	EndIf;
	
	ColumnsNames = "Products, Characteristic, Series, Package";
	
	For Each CurBarcode In BarcodeData_5 Do
		AddedData = CachedValues.Barcodes[CurBarcode.Barcode];
		
		If Not GetBarcodeData
			And (AddedData.NonUniqueBarcode
				Or Not AddedData.ReceivedAccordingToInfobaseData) Then
			
			NonCacheableBarcodes.Add(CurBarcode.Barcode);
			
		EndIf;
		
		If Not AddedData.ItemsBarcode
			And AddedData.ItemsType <> Enums.ItemsTypes.Set Then
			
			BatchBarcodes.Add(CurBarcode.Barcode);
			
		EndIf;
		
		If AddedData.UnknownBarcode Then
			UnknownBarcodes.Add(CurBarcode);
		Else
			NewRow = Table.Add();
			FillPropertyValues(NewRow, AddedData, ColumnsNames);
		EndIf;
	EndDo;
	
	For Each Barcode In NonCacheableBarcodes Do
		CachedValues.Barcodes.Delete(Barcode);
	EndDo;
	
	If BatchBarcodes.Count() > 0 Then
		InformationRegisters.ItemsBarcodes.RegisterBarcodesOfLabelsOfBatchesOfItems(
			BatchBarcodes,
			CachedValues);
	EndIf;
	
	AddProducts_2(Table);
	
	Return UnknownBarcodes;
	
EndFunction

&AtServer
Procedure AddProducts_2(Table)
	
	// The fields required for output to the table of products on the form.
	SettingsStructure = DataProcessors.PrintPriceTagsAndLabels.SettingsStructure();
	
	SetRequiredDataFields(SettingsStructure, True);
	SetDataParameters(SettingsStructure);
	
	SettingsStructure.NameOfDataLayoutSchemaTemplate	= "TemplateFieldsGoods";
	SettingsStructure.RawData					= Table;
	SettingsStructure.UsePriceManagementSystem25		= UsePriceManagementSystem25;
	
	ResultStructure1 = DataProcessors.PrintPriceTagsAndLabels.PrepareDataStructure(SettingsStructure, "Goods");
	For Each TSRow In ResultStructure1.Table Do
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, TSRow);
		NewRow.Barcode = InformationRegisters.ItemsBarcodes.PrepareBarcode(
			TSRow[ResultStructure1.MatchingDCSFieldsToTableColumns["Barcode"]]);
		NewRow.Price            = TSRow[ResultStructure1.MatchingDCSFieldsToTableColumns["Price"]];
		NewRow.SoldByWeight         = TSRow[ResultStructure1.MatchingDCSFieldsToTableColumns["SoldByWeight"]];
		NewRow.WarehouseStockBalance = TSRow[ResultStructure1.MatchingDCSFieldsToTableColumns["WarehouseStockBalance"]];
		
		ProductTypePriceTagTemplate      = TSRow[ResultStructure1.MatchingDCSFieldsToTableColumns.Get("Products.ProductKind.PriceTagTemplate")];
		ProductPriceTagTemplate          = TSRow[ResultStructure1.MatchingDCSFieldsToTableColumns.Get("Products.PriceTagTemplate")];
		NewRow.PriceTagTemplate = ?(ValueIsFilled(ProductPriceTagTemplate), ProductPriceTagTemplate, ProductTypePriceTagTemplate);
		
		ProductTypePriceTagTemplate       = TSRow[ResultStructure1.MatchingDCSFieldsToTableColumns.Get("Products.ProductKind.LabelsTemplate")];
		ProductPriceTagTemplate           = TSRow[ResultStructure1.MatchingDCSFieldsToTableColumns.Get("Products.LabelsTemplate")];
		NewRow.LabelsTemplate = ?(ValueIsFilled(ProductPriceTagTemplate), ProductPriceTagTemplate, ProductTypePriceTagTemplate);
	EndDo;
	
EndProcedure

// ExternalEquipmentMechanism
&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	If TypeOf(BarcodeData_5) = Type("Array") Then
		ArrayOfBarcodes = BarcodeData_5;
	Else
		ArrayOfBarcodes = New Array;
		ArrayOfBarcodes.Add(BarcodeData_5);
	EndIf;
	
	UnknownBarcodes = AddProductsByBarcode(ArrayOfBarcodes, CachedValues);
	
	StructureOfActionParameters = New Structure;
	StructureOfActionParameters.Insert("UnknownBarcodes", UnknownBarcodes);
	StructureOfActionParameters.Insert("TransferSpecifiedGoodsToDocument", True);
	
	If StructureOfActionParameters.UnknownBarcodes.Count() > 0 Then
		BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActionParameters, Undefined, ThisObject);
	EndIf;
	
EndProcedure // The resulting barcode()
// is the end of the mechanism of the external equipment

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	Table = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	AddProducts_2(Table);
	
EndProcedure

&AtServer
Procedure UpdateVisibilityOfTemplateDependentFields()
	
	If TemplatesDeterminingItemVisibility = Undefined Then
		UpdateTemplatesThatAffectVisibilityOfElements();
	EndIf;
	
	If Mode = "PrintLabels" Or Mode = "PrintPriceTagsAndLabels" Then
		Templates = Object.Goods.Unload(, "LabelsTemplate").UnloadColumn("LabelsTemplate");
	Else
		Templates = New Array;
	EndIf;
	If Mode = "PrintingPriceTags" Or Mode = "PrintPriceTagsAndLabels" Then
		PriceTags = Object.Goods.Unload(, "PriceTagTemplate").UnloadColumn("PriceTagTemplate");
		For Each Template In PriceTags Do
			If Templates.Find(Template) = Undefined Then
				Templates.Add(Template);
			EndIf;
		EndDo;
	EndIf;
	
	UseTheAdvancedPriceView = False;
	VisibilitySharingRule = False;
	For Each Template In Templates Do
		If TemplatesDeterminingItemVisibility.PriceKindAdditional.Find(Template) <> Undefined Then
			UseTheAdvancedPriceView = True;
		EndIf;
		If TemplatesDeterminingItemVisibility.ExchangeRule.Find(Template) <> Undefined Then
			VisibilitySharingRule = True;
		EndIf;
	EndDo;
	
	Items.PriceKindAdditional.Visible     = UseTheAdvancedPriceView;
	Items.DateTypeOfPriceAdditional.Visible = UseTheAdvancedPriceView;
	Items.GoodsPriceAdditionally.Visible  = UseTheAdvancedPriceView;
	Items.ExchangeRule.Visible            = VisibilitySharingRule;
	
EndProcedure

&AtServer
Procedure SwitchForGettingPricesWhenPriceChanges()
	
	Items.PriceKind.Visible = Object.PriceReceivingMode = 1;
	Items.Warehouse.Visible  = Object.PriceReceivingMode = 2;
	
EndProcedure

&AtServer
Procedure UpdateTemplatesThatAffectVisibilityOfElements()
	
	TemplatesDeterminingItemVisibility = New Structure;
	TemplatesDeterminingItemVisibility.Insert("PriceKindAdditional", New Array);
	TemplatesDeterminingItemVisibility.Insert("ExchangeRule", New Array);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	LabelAndPriceTagTemplates.Ref,
	|	LabelAndPriceTagTemplates.Template
	|FROM
	|	Catalog.LabelAndPriceTagTemplates AS LabelAndPriceTagTemplates
	|WHERE
	|	LabelAndPriceTagTemplates.Purpose IN(&Purpose)";
	Assignments = New Array;
	Assignments.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsLabel);
	Assignments.Add(Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag);
	Query.SetParameter("Purpose", Assignments);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		Template = Selection.Template; // ValueStorage
		
		TemplateParameters1 = Template.Get();
		For Each Parameter In TemplateParameters1.TemplateParameters Do
			If StrFind(Parameter.Key ,"CodeOfConnectedEquipmentOffline") > 0 Then
				If TemplatesDeterminingItemVisibility.ExchangeRule.Find(Selection.Ref) = Undefined Then
					TemplatesDeterminingItemVisibility.ExchangeRule.Add(Selection.Ref);
				EndIf;
			EndIf;
			If StrFind(Parameter.Key ,"PLU") > 0 Then
				If TemplatesDeterminingItemVisibility.ExchangeRule.Find(Selection.Ref) = Undefined Then
					TemplatesDeterminingItemVisibility.ExchangeRule.Add(Selection.Ref);
				EndIf;
			EndIf;
			If StrFind(Parameter.Key ,"PriceAdditionally") > 0 Then
				If TemplatesDeterminingItemVisibility.PriceKindAdditional.Find(Selection.Ref) = Undefined Then
					TemplatesDeterminingItemVisibility.PriceKindAdditional.Add(Selection.Ref);
				EndIf;
			EndIf;
			If StrFind(Parameter.Key, "PriceKindAdditional") > 0 Then
				If TemplatesDeterminingItemVisibility.PriceKindAdditional.Find(Selection.Ref) = Undefined Then
					TemplatesDeterminingItemVisibility.PriceKindAdditional.Add(Selection.Ref);
				EndIf;
			EndIf;
		EndDo;
	
	EndDo;
	
EndProcedure

// Parameters:
// 	Result - Structure - Contains:
// 	* Variant - String - 
// 	* WarehouseGroup - CatalogRef.WarehousePackageGroups - 
// 	AdditionalParameters - Array
&AtClient
Procedure SelectPackagingFillingOptionCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.Variant = Result.Variant;
	Object.WarehouseGroup = Result.WarehouseGroup;
	
	RowsSelected = AdditionalParameters;
	
	If Object.Variant = "Optimal" Then
		SplitByPackagesOnServer(RowsSelected);
	ElsIf Object.Variant = "ByWarehouseGroup" Then
		SplitByPackagesOnServer(RowsSelected, False, Result.WarehouseGroup);
	Else
		SplitByPackagesOnServer(RowsSelected, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure SplitByPackagesOnServer(RowsSelected, Basic = False, WarehouseGroup = Undefined)
	
	Goods = Object.Goods;
	
	For Each RowID In RowsSelected Do
		RowGoods		= Goods.FindByID(RowID);
		RowIndex	= Goods.IndexOf(RowGoods);
		
		RowGoods.QuantityOfGoodsInDocument = ?(RowGoods.QuantityOfGoodsInDocument,
											RowGoods.NumberOfLabels,
											RowGoods.QuantityOfGoodsInDocument);
		
		PackingTable_		= WarehousesServer.GetPacking(RowGoods.Products, Basic, WarehouseGroup);
		PackagingFactor	= Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(
								RowGoods.Package,
								RowGoods.Products);
		
		RequiredQuantity = RowGoods.QuantityOfGoodsInDocument * ?(PackagingFactor, PackagingFactor, 1);
		RequiredQuantity = ?(RequiredQuantity > 0,
								RequiredQuantity,
								RowGoods.NumberOfLabels * ?(PackagingFactor, PackagingFactor, 1));
		
		WarehousesServer.BreakUpByPackages(PackingTable_, RequiredQuantity);
		
		AddedLines_ = 0;
		
		For Each StringPacking In PackingTable_ Do
			If StringPacking.Count = 0 Then
				Continue
			EndIf;
			
			NewRow = Goods.Insert(RowIndex + 1);
			FillPropertyValues(NewRow, RowGoods);
			FillPropertyValues(NewRow, StringPacking);
			
			Barcodes = RetailSalesServerCall.GetProductBarcodes(NewRow);
			
			If Barcodes.Count() > 0 Then
				NewRow.Barcode = Barcodes[0];
			Else
				NewRow.Barcode = "";
			EndIf;
			
			NewRow.QuantityOfGoodsInDocument	= StringPacking.NumberOfPackages;
			NewRow.NumberOfLabels		= StringPacking.NumberOfPackages;
			NewRow.NumberOfPriceTags		= StringPacking.NumberOfPackages;
			
			AddedLines_ = AddedLines_ + 1;
		EndDo;
		
		If AddedLines_ Then
			Goods.Delete(RowIndex);
		EndIf;
	EndDo;
	
	If IsTempStorageURL(SavedSettings) Then
		TableSavedSettings = GetFromTempStorage(SavedSettings);
		
		SettingString = TableSavedSettings.Find("Object.Variant", "Key");
		
		If SettingString <> Undefined Then
			SettingString.Value = Object.Variant;
		EndIf;
		
		SettingString = TableSavedSettings.Find("Object.WarehouseGroup", "Key");
		If SettingString <> Undefined Then
			SettingString.Value = Object.WarehouseGroup;
		EndIf;
		
		SavedSettings = PutToTempStorage(TableSavedSettings, UUID);
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishUseOfPricing(Date = Undefined)
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(Date);
	
EndProcedure

&AtClient
Procedure RefillPrices()
	
	If Object.Goods.Count() > 0 Then
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Điền lại';
												|ru = 'Перезаполнить';
												|en = 'Refill'; fa = 'پرکردن مجدد';
												|it = 'Ricompilare';
												|pl = 'Refill';
												|tr = 'Yeniden doldur'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Không';
												|ru = 'Нет';
												|en = 'No'; fa = 'خیر';
												|it = 'Non ci sono';
												|pl = 'No';
												|tr = 'Hayır'"));
		
		QueryText = NStr("vi = 'Điền lại đơn giá?';
						|ru = 'Перезаполнить цены?';
						|en = 'Refill prices?'; fa = 'Refill prices?';
						|it = 'Ricompilare i prezzi?';
						|pl = 'Ponownie wypełnić ceny?';
						|tr = 'Fiyatlar yeniden doldurulsun mu?'");
		CallbackDescription = New CallbackDescription("ReFillPricesIssueCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, Buttons,, DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReFillPricesIssueCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		FillInTableOfProductsOnServer(True, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckClearMessages(ItIsNecessaryToPurify)
	
	If ItIsNecessaryToPurify Then
		ClearMessages();
		
		ItIsNecessaryToPurify = False;
	EndIf;
	
EndProcedure

// Parameters:
//	ErrorsTable - ValueTable
//
&AtServer
Procedure ReportProblemsFillingInItemSeries(ErrorsTable)
	
	ErrorsTable.Indexes.Add("Products, Characteristic");
	
	RowFilter = New Structure("Products, Characteristic");
	MessageTemplate = NStr("ru = 'По данным документа %1 не удалось сопоставить сведения о сериях для товара ""%2"", учитываемого в различных упаковках.';
							|vi = 'Cannot map batch information for the ""%2"" item, which is accounted for in different packaging units, based on the ""%1"" document data';
							|en = 'Cannot map batch information for the ""%2"" item, which is accounted for in different packaging units, based on the ""%1"" document data'; fa = 'Cannot map batch information for the ""%2"" item, which is accounted for in different packaging units, based on the ""%1"" document data';
							|it = 'Cannot map batch information for the ""%2"" item, which is accounted for in different packaging units, based on the ""%1"" document data';
							|pl = 'Cannot map batch information for the ""%2"" item, which is accounted for in different packaging units, based on the ""%1"" document data';
							|tr = '%1 belgesi verilerine göre, farklı paketlerde takip edilen ""%2"" ürünü için parti bilgileri eşleştirilemedi.'");
	
	For Each RowOfGoods In Object.Goods Do
		If ValueIsFilled(RowOfGoods.Series) Then
			Continue;
		EndIf;
		
		FillPropertyValues(RowFilter, RowOfGoods);
		
		ErrorLines = ErrorsTable.FindRows(RowFilter);
		
		For Each DataOfError In ErrorLines Do
			GoodsPresentation = ProductsClientServer.ProductPresentation(
									DataOfError.Products,
									DataOfError.Characteristic);
			
			MessageText= StrTemplate(MessageTemplate, String(DataOfError.Ref), GoodsPresentation);
			Field = CommonClientServer.PathToTabularSection(
					"Goods",
					RowOfGoods.LineNumber,
					"Products");
			
			Common.MessageToUser(MessageText, Undefined, Field, "Object");
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateTypeOfPriceOnChange(Items.DateTypeOfPrice);
	ElsIf Item.Name = "sh_ShamsiInput_DateAdditionally" Then
		DateTypeOfPriceAdditionalOnChange(Items.DateTypeOfPriceAdditional);
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
