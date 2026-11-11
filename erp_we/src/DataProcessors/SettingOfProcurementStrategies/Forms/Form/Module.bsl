
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ConfigureFormByRightsAndFunctionalOptions();
	
	ConfigureFormByParameters();
	If SupplyScheme.Ref.IsEmpty() And Not ValueIsFilled(SupplyScheme.Description) Then
		SupplyScheme.Description = NStr("vi = '<Sơ đồ bảo đảm mới>';
										|ru = '<Новая схема обеспечения>';
										|en = '<New supply scheme>'; fa = '<New supply scheme>';
										|it = '<Nuovo schema di approvvigionamento>';
										|pl = '<Nowy schemat zaopatrzenia>';
										|tr = '<Yeni arz şeması>'");
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.ProcurementStrategies.Form.ChoiceForm" Then
		
		If Context = "WaysToSecureWarehouse" Then
			DataArray = New Array;
			For Each Id In Items.ListOfWarehouseSupplyMethods.SelectedRows Do
				ListLine = Items.ListOfWarehouseSupplyMethods.RowData(Id);
				Data = New Structure("Products, Characteristic, Warehouse",
					ListLine.Products, ListLine.Characteristic, FilterWarehouse);
				DataArray.Add(Data);
			EndDo;
			FillInMethodForSecuringWarehouseOnSrever(DataArray, ValueSelected);
			Items.ListOfWarehouseSupplyMethods.Refresh();
		ElsIf Context = "MethodsOfProvidingProducts" Then
			If Not FillInMethodOfProvidingProductsOnServer(ValueSelected) Then
				ShowMessageBox(, NStr("vi = 'Không một dòng nào với kho đã được chọn. Thực thi lệnh là không thể.';
										|ru = 'Не выделено ни одной строки со складом. Выполнение команды невозможно.';
										|en = 'No line with a warehouse is selected. Cannot execute the command.'; fa = 'No line with a warehouse is selected. Cannot execute the command.';
										|it = 'Non è selezionata alcuna riga con magazzino. Il comando non può essere eseguito.';
										|pl = 'Ani jeden wiersz z magazynem nie jest wybrany. Polecenie nie może zostać wykonane.';
										|tr = 'Ambar içeren tek bir satır seçilmemiştir. Komut çalıştırılamıyor.'"));
			EndIf;
		EndIf;
		Context = "";
		
	ElsIf ChoiceSource.FormName = "Catalog.PackagesAndUnitsOfMeasure.Form.PackageChoiceForm" Then
		
		If Context = "WaysToSecureWarehouse" Then
			Data = Items.ListOfWarehouseSupplyMethods.CurrentData;
			FillInOrderPackagingInWarehouseOnServer(Data.Products, Data.Characteristic, FilterWarehouse,
				ValueSelected);
			Items.ListOfWarehouseSupplyMethods.Refresh();
		ElsIf Context = "MethodsOfProvidingProducts" Then
			FillInProductOrderPackagingOnServer(ValueSelected);
		EndIf;
		Context = "";
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	WriteAtClient();
	Modified = False;
EndProcedure

&AtClient
Procedure DescriptionTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If Not ValueIsFilled(Text) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure LabelUsingTheSchemeURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterParameters = New Structure("SupplyScheme", FilterSupplyScheme); 
	
	ReportParameters = New Structure;
	ReportParameters.Insert("Filter", FilterParameters);
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("ThisIsTheTranscript", True);
	ReportParameters.Insert("VariantKey", "ProductsOfSecuritySchemeContext");
	
	OpenForm("Report.SupplySchemeGoods.ObjectForm", ReportParameters);
	
EndProcedure

&AtClient
Procedure CharacteristicOnChange(Item)
	CommonClientServer.SetDynamicListParameter(WarehousesList,
		"Characteristic", FilterCharacteristic);
	LoadFormatTree(True);
	
	If MethodSettingIsAvailable Then
		TheAvailabilityStatusChangeTheWay = ?(ValueIsFilled(FilterCharacteristic), "",
			NStr("vi = 'Cài đặt của phương thức ký quỹ chỉ khả dụng cho một lựa chọn nhất định theo đặc tính';
				|ru = 'Установка способа обеспечения доступна только при заданном отборе по характеристике';
				|en = 'Procurement strategy setting is available only if the filter by item variant is set'; fa = 'Procurement strategy setting is available only if the filter by item variant is set';
				|it = 'L''impostazione della modalità di approvvigionamento è disponibile solo per la selezione stabilita per caratteristica';
				|pl = 'Ustawienie metody zabezpieczenia dostępu jest dostępne tylko dla konkretnego wyboru według charakterystyki';
				|tr = 'Tedarik stratejisi ayarı, yalnızca özelliklere göre belirli bir filtre ile kullanılabilir.'"));
		Items.CommandsOfSettingProductSupplyMethod.Enabled = ValueIsFilled(FilterCharacteristic);
		Items.FormatTreeContextMenuCommandsOfSettingProductSupplyMethod.Enabled =
			ValueIsFilled(FilterCharacteristic);
		Items.WarehouseListContextMenuSettingCommandsOfProductSupplyMethod.Enabled =
			ValueIsFilled(FilterCharacteristic);
	EndIf;
EndProcedure

&AtClient
Procedure RepresentationOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SettingOfProcurementStrategies.Form.Form.Item.Representation.OnChange");
	
	Items.PagesDisplayMode.CurrentPage = ?(Representation = "Formats",
		Items.PagesDisplayMode.ChildItems.PageFormats,
		Items.PagesDisplayMode.ChildItems.WarehousesPage);
	
	If ChangedWarehouses.Count() > 0 Then
		LoadFormatTree(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnlySuppliedProductsOnChange(Item)
	CommonClientServer.SetDynamicListParameter(
			ListOfWarehouseSupplyMethods,
			"OnlySuppliedProducts",
			OnlySuppliedProducts,
			OnlySuppliedProducts);
EndProcedure

#EndRegion

#Region EventHandlersForItemsInListOfWarehouseSecurityMethods

&AtClient
Procedure ListOfWarehouseSupplyMethodsSelection(Item, RowSelected, Field, StandardProcessing)
	If Field = Items.ListOfWarehouseSupplyMethodsProducts Then
		ShowValue(,Item.CurrentData.Products);
	ElsIf Field = Items.ListOfWarehouseSupplyMethodsCharacteristic Then
		ShowValue(,Item.CurrentData.Characteristic);
	ElsIf Field = Items.ListOfWarehouseSupplyMethodsSupplySource
		And Item.CurrentData.SupplySource <> Undefined Then
		ShowValue(,Item.CurrentData.SupplySource);
	ElsIf Field = Items.ListOfWarehouseSupplyMethodsSupplyScheme
		Or Field = Items.ListOfWarehouseSupplyMethodsSupplyMethod
		Or Field = Items.ListOfWarehouseSupplyMethodsSupplyType
		Or Field = Items.ListOfWarehouseSupplyMethodsDeliveryPeriodDays
		Or Field = Items.ListOfWarehouseSupplyMethodsCoveredPeriod
		Or Field = Items.ListOfWaysToSecureAWarehouseIndividualConfiguration Then
		If Item.CurrentData.ThisIsAPersonalSetting Then
			ShowValue(,Item.CurrentData.SupplyMethod);
		Else
			FormParameters = New Structure("Key, Warehouse", Item.CurrentData.SupplyScheme, FilterWarehouse);
			OpenForm("Catalog.SupplySchemes.ObjectForm", FormParameters, ThisForm);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFormatTree

&AtClient
Procedure FormatTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.FormatTreeWarehouseFormat Then
		ShowValue(,Item.CurrentData.WarehouseFormat);
	ElsIf Field = Items.FormatTreeSupplySource And Item.CurrentData.SupplySource <> Undefined Then
		ShowValue(,Item.CurrentData.SupplySource);
	ElsIf Field = Items.FormatTreeSupplyMethod
		Or Field = Items.FormatTreeSupplyType
		Or Field = Items.FormatTreeDeliveryPeriodDays
		Or Field = Items.FormatTreeCoveredPeriod
		Or Field = Items.FormatTreeThereIsSettingForGoods Then
			ShowValue(,Item.CurrentData.SupplyMethod);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormTableElementsListOfWaysToProvide

&AtClient
Procedure WarehousesListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	If Field = Items.WarehousesListWarehouse Then
		ShowValue(, Item.CurrentData.Warehouse);
	ElsIf Field = Items.WarehousesListStoreFormat Then
		ShowValue(, Item.CurrentData.StoreFormat);
	ElsIf Field = Items.WarehousesListSupplyMethod
		Or Field = Items.WarehousesListSupplyType
		Or Field = Items.WarehousesListDeliveryPeriodDays
		Or Field = Items.WarehousesListCoveredPeriod
		Or Field = Items.WarehousesListThereIsSettingForGoods Then
		ShowValue(, Item.CurrentData.SupplyMethod);
	ElsIf Field = Items.WarehousesListSupplySource
		And Item.CurrentData.SupplySource <> Undefined Then
		ShowValue(, Item.CurrentData.SupplySource);
	ElsIf Field = Items.WarehousesListOrderPackage Then
		ShowValue(, Item.CurrentData.OrderPackage);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDepartmentList

&AtClient
Procedure DepartmentListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.DepartmentList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.DepartmentListDescription Then
		ShowValue(, CurrentData.Ref);
	ElsIf Field = Items.DepartmentListWarehouse And ValueIsFilled(CurrentData.Warehouse) Then
		ShowValue(, CurrentData.Warehouse);
	EndIf;
	
	If Field = Items.DepartmentListChangeWarehouse Then
		
		If Not CurrentData.ProductionBusinessUnit Then
			ShowMessageBox(, NStr("vi = 'Chỉ có thể thay đổi kho bãi cho bộ phận sản xuất';
									|ru = 'Изменить склад можно только для производственного подразделения';
									|en = 'You can only change the warehouse for a production business unit'; fa = 'You can only change the warehouse for a production business unit';
									|it = 'Il magazzino può essere modificato solo per il reparto di produzione';
									|pl = 'Zmienić magazyn można tylko dla działu produkcyjnego';
									|tr = 'Yalnızca üretim departmanı için ambar değiştirebilir'"));
		EndIf; 
		
		WriteBeforeExecutingCommand("DepartmentListChangeWarehouse");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region Commands_WaysToSecureWarehouse

&AtClient
Procedure FillInTheWarehouseSecurityMethod(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SettingOfProcurementStrategies.Form.Form.Command.FillInTheWarehouseSecurityMethod");
	
	Context = "WaysToSecureWarehouse";
	
	If ThereAreHighlightedRowsInTable(Items.ListOfWarehouseSupplyMethods) Then
		
		FormParameters = New Structure("Warehouse", FilterWarehouse);
		OpenForm("Catalog.ProcurementStrategies.ChoiceForm", FormParameters, ThisForm,
			UUID);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearTheWayToEnsureTheWarehouse(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SettingOfProcurementStrategies.Form.Form.Command.ClearTheWayToEnsureTheWarehouse");
	
	If ThereAreHighlightedRowsInTable(Items.ListOfWarehouseSupplyMethods) Then
		DataArray = New Array;
		For Each Id In Items.ListOfWarehouseSupplyMethods.SelectedRows Do
			ListLine = Items.ListOfWarehouseSupplyMethods.RowData(Id);
			Data = New Structure("Products, Characteristic, Warehouse",
						ListLine.Products, ListLine.Characteristic, FilterWarehouse);
			DataArray.Add(Data);
		EndDo;
		FillInMethodForSecuringWarehouseOnSrever(DataArray);
		Items.ListOfWarehouseSupplyMethods.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillOutTheOrderPackagingInTheWarehouse(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SettingOfProcurementStrategies.Form.Form.Command.FillOutTheOrderPackagingInTheWarehouse");
	
	If ThereAreHighlightedRowsInTable(Items.ListOfWarehouseSupplyMethods) Then
		Data = Items.ListOfWarehouseSupplyMethods.CurrentData;
		If Data.PackagesAreUsed Then
			Context = "WaysToSecureWarehouse";
			FormParameters = New Structure("Products", Data.Products);
			OpenForm("Catalog.PackagesAndUnitsOfMeasure.Form.PackageChoiceForm", FormParameters, ThisForm,
				UUID,,,, FormWindowOpeningMode.LockOwnerWindow);
		Else
			ShowMessageBox(, NStr("vi = 'Không có gói nào được sử dụng cho phạm vi sản phẩm đã chọn. Thực thi lệnh là không thể.';
									|ru = 'Для выбранной номенклатуры упаковки не используются. Выполнение команды невозможно.';
									|en = 'Packaging units are not used for the selected items. Cannot execute the command.'; fa = 'Packaging units are not used for the selected items. Cannot execute the command.';
									|it = 'Per l''articolo selezionato non vengono utilizzati imballaggi. Il comando non può essere eseguito.';
									|pl = 'Dla wybranej nomenklatury opakowania nie są używane. Polecenie nie może zostać wykonane.';
									|tr = 'Paketleme ünitesi seçilen ürün gamı için kullanılmaz. Komut çalıştırılamıyor.'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearTheOrderPackagingInTheWarehouse(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SettingOfProcurementStrategies.Form.Form.Command.ClearTheOrderPackagingInTheWarehouse");
	
	If ThereAreHighlightedRowsInTable(Items.ListOfWarehouseSupplyMethods) Then
		Data = Items.ListOfWarehouseSupplyMethods.CurrentData;
		If Data.PackagesAreUsed Then
			FillInOrderPackagingInWarehouseOnServer(Data.Products, Data.Characteristic, FilterWarehouse);
			Items.ListOfWarehouseSupplyMethods.Refresh();
		Else
			ShowMessageBox(, NStr("vi = 'Không có gói nào được sử dụng cho phạm vi sản phẩm đã chọn. Thực thi lệnh là không thể.';
									|ru = 'Для выбранной номенклатуры упаковки не используются. Выполнение команды невозможно.';
									|en = 'Packaging units are not used for the selected items. Cannot execute the command.'; fa = 'Packaging units are not used for the selected items. Cannot execute the command.';
									|it = 'Per l''articolo selezionato non vengono utilizzati imballaggi. Il comando non può essere eseguito.';
									|pl = 'Dla wybranej nomenklatury opakowania nie są używane. Polecenie nie może zostać wykonane.';
									|tr = 'Paketleme ünitesi seçilen ürün gamı için kullanılmaz. Komut çalıştırılamıyor.'"));
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Commands_WaysToProvideProducts

&AtClient
Procedure FillInTheMethodOfProvidingTheItem(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SettingOfProcurementStrategies.Form.Form.Command.FillInTheMethodOfProvidingTheItem");
	
	CurrentTable = ?(Representation = "Warehouses", Items.WarehousesList, Items.FormatTree);
	If ThereAreHighlightedRowsInTable(CurrentTable) Then
		WriteBeforeExecutingCommand(Command.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearTheMethodForProvidingTheItem(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SettingOfProcurementStrategies.Form.Form.Command.ClearTheMethodForProvidingTheItem");
		
	CurrentTable = ?(Representation = "Warehouses", Items.WarehousesList, Items.FormatTree);
	If ThereAreHighlightedRowsInTable(CurrentTable) Then
		WriteBeforeExecutingCommand(Command.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheItemOrderPackaging(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SettingOfProcurementStrategies.Form.Form.Command.FillInTheItemOrderPackaging");
	
	CurrentTable = ?(Representation = "Warehouses", Items.WarehousesList, Items.FormatTree);
	If ThereAreHighlightedRowsInTable(CurrentTable) Then
		Context = "MethodsOfProvidingProducts";
		FormParameters = New Structure("Products", FilterProducts);
		OpenForm("Catalog.PackagesAndUnitsOfMeasure.Form.PackageChoiceForm", FormParameters, ThisForm,
			UUID,,,, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearItemOrderPackaging(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SettingOfProcurementStrategies.Form.Form.Command.ClearItemOrderPackaging");
	
	CurrentTable = ?(Representation = "Warehouses", Items.WarehousesList, Items.FormatTree);
	If ThereAreHighlightedRowsInTable(CurrentTable) Then
		FillInProductOrderPackagingOnServer(PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateTheTreeList(Command)
	
	LoadFormatTree();
	Items.WarehousesList.Refresh();
	
EndProcedure

#EndRegion

&AtClient
Procedure FillInTheWarehouse(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SettingOfProcurementStrategies.Form.Form.Command.FillInTheWarehouse");
	
	If ThereAreHighlightedRowsInTable(Items.DepartmentList) Then
		WriteBeforeExecutingCommand(Command.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearWarehouse(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SettingOfProcurementStrategies.Form.Form.Command.ClearWarehouse");
	
	If ThereAreHighlightedRowsInTable(Items.DepartmentList) Then
		WriteBeforeExecutingCommand(Command.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenTheProcessingHelp(Command)
	OpenHelp("DataProcessor.SettingOfProcurementStrategies");
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChangeNameEnd(ClosingResult, AdditionalParameters) Export
	
	If ValueIsFilled(ClosingResult) Then
		SupplyScheme.Description = ClosingResult;
	Else
		ShowMessageBox(, 
			NStr("vi = 'Không thể đặt tên trống cho sơ đồ đảm bảo. Thay đổi không được chấp nhận.';
				|ru = 'Нельзя устанавливать пустое наименование схемы обеспечения. Изменения не применены.';
				|en = 'Cannot set an empty supply scheme name. The changes are not applied.'; fa = 'Cannot set an empty supply scheme name. The changes are not applied.';
				|it = 'Impossibile lasciare vuoto il campo nome dello schema di approvvigionamento. Modifiche non salvate.';
				|pl = 'Nie można ustawić pustej nazwy schematu zaopatrzenia. Zmiany nie zostały zastosowane.';
				|tr = 'Boş bir arz şeması adı ayarlanmamalı. Değişiklikler uygulanmadı.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteAtClient()
	
	ClearMessages();
	WritingOnServer();
	Template = NStr("vi = '%1 (Sơ đồ đảm bảo)';
					|ru = '%1 (Схема обеспечения)';
					|en = '%1 (Supply scheme)'; fa = '%1 (Supply scheme)';
					|it = '%1 (Schema di approvvigionamento)';
					|pl = '%1 (Schemat zabezpieczeń)';
					|tr = '%1 (Arz şeması)'");
	Title = StrTemplate(Template, SupplyScheme.Description);
	NotifyChanged(SupplyScheme.Ref);
	
EndProcedure

&AtServer
Procedure WritingOnServer()
	
	ObjectToWrite1 = FormAttributeToValue("SupplyScheme");
	ObjectToWrite1.Write();
	ValueToFormAttribute(ObjectToWrite1, "SupplyScheme");
	
	If FilterSupplyScheme <> SupplyScheme.Ref Then
		FilterSupplyScheme = SupplyScheme.Ref;
		CommonClientServer.SetDynamicListParameter(WarehousesList,
			"SupplyScheme", FilterSupplyScheme);
		CommonClientServer.SetDynamicListParameter(DepartmentList,
			"SupplyScheme", FilterSupplyScheme);
	EndIf;
	
EndProcedure

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()
	
	FormattedFields = New Array;
	
	#Region ListOfWarehouseSupplyMethods
	ConditionalAppearanceOfList = ListOfWarehouseSupplyMethods.ConditionalAppearance;
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "Characteristic",
		"ItemVariantsAreUsed", False);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<không sử dụng đặc tính>';
																|ru = '<характеристики не используются>';
																|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
																|it = '<le caratteristiche non vengono usate>';
																|pl = '<charakterystyki nie dotyczą>';
																|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "SupplyMethod",
		"ThisIsAPersonalSetting", False);
	Item.Appearance.SetParameterValue("Show",		False);
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "SupplyScheme",
		"ThisIsAPersonalSetting", True);
	Item.Appearance.SetParameterValue("Show",		False);
	
	FormattedFields.Add("SupplyMethod");
	FormattedFields.Add("SupplyType");
	FormattedFields.Add("SupplySource");
	FormattedFields.Add("DeliveryPeriodDays");
	FormattedFields.Add("CoveredPeriod");
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, FormattedFields, 
		"SupplyMethod",, DataCompositionComparisonType.NotFilled);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<không được thiết lập>';
																|ru = '<не установлен>';
																|en = '<not set>'; fa = '<تنظیم نشده>';
																|it = '<non impostato>';
																|pl = '<nie ustawiony>';
																|tr = '<ayarlanmadı>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	FormattedFields.Clear();
	
	IssueSourceOfCollateral(ConditionalAppearanceOfList, "SupplySource",
		"SupplySource", "SupplyType");
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "DeliveryPeriodDays", "DeliveryPeriodDays", 0);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SupplyMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<bất cứ ngày nào>';
																|ru = '<в любой день>';
																|en = '<any day>'; fa = '<any day>';
																|it = '<nel giorno qualsiasi>';
																|pl = '<dowolnego dnia>';
																|tr = '<herhangi bir gün>'"));
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "CoveredPeriod",
		"CoveredPeriodOption", Enums.CoveredPeriodOptions.NoExpiration);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SupplyMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không hạn chế>';
													|ru = '<не ограничен>';
													|en = '<not limited>'; fa = '<not limited>';
													|it = '<non limitato>';
													|pl = '<nie ograniczony>';
													|tr = '<sınırsız>'"));
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "CoveredPeriod",
		"CoveredPeriodOption", Enums.CoveredPeriodOptions.UpToTheNextDeliveryDate);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SupplyMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Trước ngày giao hàng tiếp theo';
													|ru = 'До даты следующей поставки';
													|en = 'Up to the next delivery date'; fa = 'Up to the next delivery date';
													|it = 'До даты следующей поставки';
													|pl = 'Up to the next delivery date';
													|tr = 'Sonraki tedarik tarihine kadar'"));

	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "SupplyScheme",
		"SupplyScheme",, DataCompositionComparisonType.NotFilled);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SupplyMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<chưa chỉ ra>';
																|ru = '<не указана>';
																|en = '<not specified>'; fa = '<مشخص نشده>';
																|it = '<non indicata>';
																|pl = '<nie określono>';
																|tr = '<belirtilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "OrderPackage",
		"PackagesAreUsed", False);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<không sử dụng>';
																|ru = '<не используется>';
																|en = '<not used>'; fa = '<استفاده نمی‌شود>';
																|it = '<non viene utilizzato>';
																|pl = '<nie używa się>';
																|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "OrderPackage",
		"PackagesAreUsed", True);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrderPackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<chưa thiết lập>';
																|ru = '<не установлена>';
																|en = '<packaging unit not set>'; fa = '<packaging unit not set>';
																|it = '<non impostata>';
																|pl = '<nie zainstalowana>';
																|tr = '<ayarlanmadı>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	#EndRegion
	
	#Region FormatTree
	Item = AddDesignElementWithCondition(ConditionalAppearance, Items.FormatTreeWarehouseFormat.Name,
		"FormatTree.WarehouseFormat",, DataCompositionComparisonType.NotFilled);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<không có định dạng>';
																|ru = '<без формата>';
																|en = '<without format>'; fa = '<without format>';
																|it = '<senza formato>';
																|pl = '<bez formatu>';
																|tr = '<biçimsiz>'"));
	
	FormattedFields.Add(Items.FormatTreeSupplyMethod.Name);
	FormattedFields.Add(Items.FormatTreeSupplyType.Name);
	FormattedFields.Add(Items.FormatTreeCoveredPeriod.Name);
	FormattedFields.Add(Items.FormatTreeDeliveryPeriodDays.Name);
	FormattedFields.Add(Items.FormatTreeSupplySource.Name);
	Item = AddDesignElementWithCondition(ConditionalAppearance, FormattedFields, "FormatTree.WarehouseFormat",,
		DataCompositionComparisonType.NotFilled);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<không sử dụng>';
																|ru = '<не используется>';
																|en = '<not used>'; fa = '<استفاده نمی‌شود>';
																|it = '<non viene utilizzato>';
																|pl = '<nie używa się>';
																|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("ReadOnly",True);
	
	Item = AddDesignElementWithCondition(ConditionalAppearance, FormattedFields, "FormatTree.SupplyMethod",,
		DataCompositionComparisonType.NotFilled);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FormatTree.WarehouseFormat");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<không được thiết lập>';
																|ru = '<не установлен>';
																|en = '<not set>'; fa = '<تنظیم نشده>';
																|it = '<non impostato>';
																|pl = '<nie ustawiony>';
																|tr = '<ayarlanmadı>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	FormattedFields.Clear();
	
	Item = AddDesignElementWithCondition(ConditionalAppearance, Items.FormatTreeSupplyMethod.Name,
		"FormatTree.ThereIsASettingForFormat", True);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FormatTree.ThereIsSettingForGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FormatTree.ThereIsASettingForWarehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<đối với toàn bộ định dạng>';
																|ru = '<как для формата в целом>';
																|en = '<as for the format in general>'; fa = '<as for the format in general>';
																|it = '<come per il formato nel suo complesso>';
																|pl = '<jak dla formatu w całości>';
																|tr = '<biçim olarak bir bütün olarak>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	
	Item = AddDesignElementWithCondition(ConditionalAppearance,
		Items.FormatTreeThereIsSettingForGoods.Name,
		"FormatTree.ThereIsSettingForGoods", False);
	Item.Appearance.SetParameterValue("Text",		NStr("vi = 'Sơ đồ đảm bảo';
															|ru = 'Схема обеспечения';
															|en = 'Supply scheme'; fa = 'طرح تأمین';
															|it = 'Schema di approvvigionamento';
															|pl = 'Schemat zaopatrzenia';
															|tr = 'Arz şeması'"));
	
	Item = AddDesignElementWithCondition(ConditionalAppearance,
		Items.FormatTreeThereIsSettingForGoods.Name,
		"FormatTree.ThereIsSettingForGoods", True);
	Item.Appearance.SetParameterValue("Text",		NStr("vi = 'Phương thức đảm bảo';
															|ru = 'Способ обеспечения';
															|en = 'Procurement strategy'; fa = 'راهبرد تدارکات';
															|it = 'Modalità di approvvigionamento';
															|pl = 'Sposób zaopatrzenia';
															|tr = 'Tedarik stratejisi'"));
	
	IssueSourceOfCollateral(ConditionalAppearance, Items.FormatTreeSupplySource.Name,
		"FormatTree.SupplySource", "FormatTree.SupplyType");
	
	Item = AddDesignElementWithCondition(ConditionalAppearance, Items.FormatTreeDeliveryPeriodDays.Name,
		"FormatTree.DeliveryPeriodDays", 0);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FormatTree.SupplyMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<bất cứ ngày nào>';
																|ru = '<в любой день>';
																|en = '<any day>'; fa = '<any day>';
																|it = '<nel giorno qualsiasi>';
																|pl = '<dowolnego dnia>';
																|tr = '<herhangi bir gün>'"));
	
	Item = AddDesignElementWithCondition(ConditionalAppearance, Items.FormatTreeCoveredPeriod.Name,
		"FormatTree.CoveredPeriodOption", Enums.CoveredPeriodOptions.NoExpiration);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FormatTree.SupplyMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không hạn chế>';
													|ru = '<не ограничен>';
													|en = '<not limited>'; fa = '<not limited>';
													|it = '<non limitato>';
													|pl = '<nie ograniczony>';
													|tr = '<sınırsız>'"));
	
	Item = AddDesignElementWithCondition(ConditionalAppearance, Items.FormatTreeCoveredPeriod.Name,
		"FormatTree.CoveredPeriodOption", Enums.CoveredPeriodOptions.UpToTheNextDeliveryDate);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FormatTree.SupplyMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Trước ngày giao hàng tiếp theo';
													|ru = 'До даты следующей поставки';
													|en = 'Up to the next delivery date'; fa = 'Up to the next delivery date';
													|it = 'До даты следующей поставки';
													|pl = 'Up to the next delivery date';
													|tr = 'Sonraki tedarik tarihine kadar'"));

	Item = AddDesignElementWithCondition(ConditionalAppearance, Items.FormatTreeOrderPackage.Name,
		"FormatTree.ItIsFormat", True);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<không sử dụng>';
																|ru = '<не используется>';
																|en = '<not used>'; fa = '<استفاده نمی‌شود>';
																|it = '<non viene utilizzato>';
																|pl = '<nie używa się>';
																|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("ReadOnly",True);
	
	Item = AddDesignElementWithCondition(ConditionalAppearance, Items.FormatTreeOrderPackage.Name,
		"FormatTree.ItIsFormat", False);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FormatTree.OrderPackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<chưa thiết lập>';
																|ru = '<не установлена>';
																|en = '<packaging unit not set>'; fa = '<packaging unit not set>';
																|it = '<non impostata>';
																|pl = '<nie zainstalowana>';
																|tr = '<ayarlanmadı>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	#EndRegion
	
	#Region WarehousesList
	ConditionalAppearanceOfList = WarehousesList.ConditionalAppearance;
	
	FormattedFields.Add("StoreFormat");
	FormattedFields.Add("ThereIsSettingForGoods");
	FormattedFields.Add("SupplyMethod");
	FormattedFields.Add("SupplyType");
	FormattedFields.Add("SupplySource");
	FormattedFields.Add("DeliveryPeriodDays");
	FormattedFields.Add("CoveredPeriod");
	FormattedFields.Add("OrderPackage");
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, FormattedFields, "IsFolder", True);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<chỉ dành cho các yếu tố>';
																|ru = '<только для элементов>';
																|en = '<only for items>'; fa = '<only for items>';
																|it = '<solo per elementi>';
																|pl = '<tylko dla elementów>';
																|tr = '<sadece öğeler için>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	FormattedFields.Clear();
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "StoreFormat", "ThereIsFormat", False);
	SetRegistrationSelectionNotForGroup(Item);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<không có định dạng>';
																|ru = '<без формата>';
																|en = '<without format>'; fa = '<without format>';
																|it = '<senza formato>';
																|pl = '<bez formatu>';
																|tr = '<biçimsiz>'"));
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "SupplyMethod",
		"ThereIsASettingForFormat", True);
	SetRegistrationSelectionNotForGroup(Item);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThereIsSettingForGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThereIsASettingForWarehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<đối với toàn bộ định dạng>';
																|ru = '<как для формата в целом>';
																|en = '<as for the format in general>'; fa = '<as for the format in general>';
																|it = '<come per il formato nel suo complesso>';
																|pl = '<jak dla formatu w całości>';
																|tr = '<biçim olarak bir bütün olarak>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "ThereIsSettingForGoods",
		"ThereIsSettingForGoods", False);
	SetRegistrationSelectionNotForGroup(Item);
	Item.Appearance.SetParameterValue("Text",		NStr("vi = 'Sơ đồ đảm bảo';
															|ru = 'Схема обеспечения';
															|en = 'Supply scheme'; fa = 'طرح تأمین';
															|it = 'Schema di approvvigionamento';
															|pl = 'Schemat zaopatrzenia';
															|tr = 'Arz şeması'"));
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "ThereIsSettingForGoods",
		"ThereIsSettingForGoods", True);
	SetRegistrationSelectionNotForGroup(Item);
	Item.Appearance.SetParameterValue("Text",		NStr("vi = 'Phương thức đảm bảo';
															|ru = 'Способ обеспечения';
															|en = 'Procurement strategy'; fa = 'راهبرد تدارکات';
															|it = 'Modalità di approvvigionamento';
															|pl = 'Sposób zaopatrzenia';
															|tr = 'Tedarik stratejisi'"));
	
	FormattedFields.Add("SupplyType");
	FormattedFields.Add("SupplyMethod");
	FormattedFields.Add("SupplySource");
	FormattedFields.Add("DeliveryPeriodDays");
	FormattedFields.Add("CoveredPeriod");
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, FormattedFields, "SupplyMethod",,
		DataCompositionComparisonType.NotFilled);
	SetRegistrationSelectionNotForGroup(Item);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<không được thiết lập>';
																|ru = '<не установлен>';
																|en = '<not set>'; fa = '<تنظیم نشده>';
																|it = '<non impostato>';
																|pl = '<nie ustawiony>';
																|tr = '<ayarlanmadı>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	FormattedFields.Clear();
	
	IssueSourceOfCollateral(ConditionalAppearanceOfList, "SupplySource", "SupplySource",
		"SupplyType");
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "DeliveryPeriodDays", "DeliveryPeriodDays", 0);
	SetRegistrationSelectionNotForGroup(Item);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SupplyMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<bất cứ ngày nào>';
																|ru = '<в любой день>';
																|en = '<any day>'; fa = '<any day>';
																|it = '<nel giorno qualsiasi>';
																|pl = '<dowolnego dnia>';
																|tr = '<herhangi bir gün>'"));
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "CoveredPeriod",
		"CoveredPeriodOption", Enums.CoveredPeriodOptions.NoExpiration);
	SetRegistrationSelectionNotForGroup(Item);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SupplyMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không hạn chế>';
													|ru = '<не ограничен>';
													|en = '<not limited>'; fa = '<not limited>';
													|it = '<non limitato>';
													|pl = '<nie ograniczony>';
													|tr = '<sınırsız>'"));
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "CoveredPeriod",
		"CoveredPeriodOption", Enums.CoveredPeriodOptions.UpToTheNextDeliveryDate);
	SetRegistrationSelectionNotForGroup(Item);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SupplyMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Trước ngày giao hàng tiếp theo';
													|ru = 'До даты следующей поставки';
													|en = 'Up to the next delivery date'; fa = 'Up to the next delivery date';
													|it = 'До даты следующей поставки';
													|pl = 'Up to the next delivery date';
													|tr = 'Sonraki tedarik tarihine kadar'"));
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "OrderPackage", "OrderPackage",,
		DataCompositionComparisonType.NotFilled);
	SetRegistrationSelectionNotForGroup(Item);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<chưa thiết lập>';
																|ru = '<не установлена>';
																|en = '<packaging unit not set>'; fa = '<packaging unit not set>';
																|it = '<non impostata>';
																|pl = '<nie zainstalowana>';
																|tr = '<ayarlanmadı>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	#EndRegion
	#Region DepartmentList
	// Text <not set> if the warehouse is empty
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepartmentListWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DepartmentList.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DepartmentList.ProductionBusinessUnit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được thiết lập>';
													|ru = '<не установлен>';
													|en = '<not set>'; fa = '<تنظیم نشده>';
													|it = '<non impostato>';
													|pl = '<nie ustawiony>';
													|tr = '<ayarlanmadı>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	// Graying out non-production units
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepartmentList.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DepartmentList.ProductionBusinessUnit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	// Text <not used> for non-production units
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepartmentListWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DepartmentList.ProductionBusinessUnit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	// Hiding the warehouse change button.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepartmentListChangeWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DepartmentList.ProductionBusinessUnit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Show", False);
	
	#EndRegion
EndProcedure

&AtServerNoContext
Procedure IssueSourceOfCollateral(ConditionalAppearance, NameOfSourceInputField,
									PathToSoftwareSourceField, PathToSecurityTypeField)

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfSourceInputField);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSecurityTypeField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SupplyTypes.Move;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSoftwareSourceField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<bất kỳ kho hàng>';
													|ru = '<любые склады>';
													|en = '<any warehouses>'; fa = '<any warehouses>';
													|it = '<qualsiasi magazzino>';
													|pl = '<dowolne magazyny>';
													|tr = '<herhangi bir ambar>'"));

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfSourceInputField);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSecurityTypeField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SupplyTypes.Production;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSoftwareSourceField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<bất kỳ đơn vị>';
													|ru = '<любые подразделения>';
													|en = '<any business units>'; fa = '<any business units>';
													|it = '<qualsiasi reparto>';
													|pl = '<dowolne działy>';
													|tr = '<herhangi bir departman>'"));

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfSourceInputField);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSecurityTypeField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SupplyTypes.AssemblyDisassembly;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đóng bộ hàng hóa>';
													|ru = '<сборка товаров>';
													|en = '<product kitting>'; fa = '<product kitting>';
													|it = '<assemblaggio di merci>';
													|pl = '<kompletowanie towarów>';
													|tr = '<ürün montajı>'"));

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfSourceInputField);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSecurityTypeField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SupplyTypes.Purchase;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSoftwareSourceField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<bất kỳ nhà cung cấp>';
													|ru = '<любые поставщики>';
													|en = '<any vendors>'; fa = '<any vendors>';
													|it = '<qualsiasi fornitore>';
													|pl = '<dowolni dostawcy>';
													|tr = '<herhangi bir tedarikçi>'"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetRegistrationSelectionNotForGroup(Item)
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
EndProcedure

&AtServer
Function AddDesignElementWithCondition(Var_ConditionalAppearance, FormattedFields, DataPath,
											Value = Undefined, Var_ComparisonType = Undefined)
	
	Item = Var_ConditionalAppearance.Items.Add();
	
	If TypeOf(FormattedFields) = Type("String") Then
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FormattedFields);
	Else
		For Each Field In FormattedFields Do
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(Field);
		EndDo;
	EndIf;
	
	If Var_ComparisonType = Undefined Then
		Var_ComparisonType = DataCompositionComparisonType.Equal;
	EndIf; 
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(DataPath);
	ItemFilter.ComparisonType = Var_ComparisonType;
	If Value <> Undefined Then
		ItemFilter.RightValue = Value;
	EndIf;
	
	Return Item;
	
EndFunction

#EndRegion

#Region NotificationsHandlers

&AtClient
Procedure RunCommandAfterQuestion(Result, CommandExecuteParameters) Export
	
	If Result = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If Result = DialogReturnCode.OK Then
		
		WriteAtClient();
		If Not ValueIsFilled(SupplyScheme.Ref) Then
			If CommandExecuteParameters.Name = "TreeFormatsWayToEnsureWhenChanging" Then
				Items.FormatTree.CurrentData.SupplyMethod = 
					Items.FormatTree.CurrentData.InheritedSupplyMethod;
			EndIf;
			Return;
		EndIf;
		
	EndIf;
		
	If CommandExecuteParameters.Name = "DepartmentListChangeWarehouse" Then
		
		RowsSelected = New Array();
		RowsSelected.Add(Items.DepartmentList.CurrentRow);
		CallbackDescription = New CallbackDescription("CommandFillWarehouseCompletion", ThisObject, RowsSelected);
		OpenForm("Catalog.Warehouses.ChoiceForm",, ThisObject,,,, CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
			
	ElsIf CommandExecuteParameters.Name = "FillInTheMethodOfProvidingTheItem" Then
		
		Context = "MethodsOfProvidingProducts";
		If Representation = "Formats" Then
			FormParameters = New Structure("Warehouse", Items.FormatTree.CurrentData.WarehouseFormat);
		ElsIf Items.WarehousesList.CurrentData.IsFolder Then
			FormParameters = New Structure();
		Else
			FormParameters = New Structure("Warehouse", Items.WarehousesList.CurrentRow);
		EndIf;
		
		OpenForm("Catalog.ProcurementStrategies.ChoiceForm", FormParameters, ThisForm,
			UUID);
		
	ElsIf CommandExecuteParameters.Name = "ClearTheMethodForProvidingTheItem" Then
		
		If Not FillInMethodOfProvidingProductsOnServer() Then
			ShowMessageBox(, NStr("vi = 'Không một dòng nào với kho đã được chọn. Thực thi lệnh là không thể.';
									|ru = 'Не выделено ни одной строки со складом. Выполнение команды невозможно.';
									|en = 'No line with a warehouse is selected. Cannot execute the command.'; fa = 'No line with a warehouse is selected. Cannot execute the command.';
									|it = 'Non è selezionata alcuna riga con magazzino. Il comando non può essere eseguito.';
									|pl = 'Ani jeden wiersz z magazynem nie jest wybrany. Polecenie nie może zostać wykonane.';
									|tr = 'Ambar içeren tek bir satır seçilmemiştir. Komut çalıştırılamıyor.'"));
		EndIf;
	ElsIf CommandExecuteParameters.Name = "FillInTheWarehouse" Then
		
		SelectedDivisions = New Array;
		RowsSelected = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.DepartmentList);
		For Each UnitReference_ In RowsSelected Do
			If Not ValueIsFilled(UnitReference_) Then
				Continue;
			EndIf;
			RowData = Items.DepartmentList.RowData(UnitReference_);
			If RowData.ProductionBusinessUnit Then
				SelectedDivisions.Add(RowData.Ref);
			EndIf; 
		EndDo;
		
		If SelectedDivisions.Count() = 0 Then
			ShowMessageBox(, NStr("vi = 'Cần phải chọn đơn vị sản xuất';
									|ru = 'Необходимо выбрать производственные подразделения';
									|en = 'Select production business units'; fa = 'Select production business units';
									|it = 'È necessario selezionare i reparti di produzione';
									|pl = 'Musisz wybrać działy produkcyjne';
									|tr = 'Üretim departmanlarını seçmeniz gerekiyor'"));
			Return;
		EndIf; 
		
		CallbackDescription = New CallbackDescription("CommandFillWarehouseCompletion", ThisObject, SelectedDivisions);
		OpenForm("Catalog.Warehouses.ChoiceForm",
			New Structure("ChoiceFoldersAndItems", FoldersAndItemsUse.Items),
			ThisObject,
			,
			,
			,
			CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf CommandExecuteParameters.Name = "ClearWarehouse" Then
		
		SelectedDivisions =
			TMCommonUseClient.CheckGetLinksHighlightedInList(Items.DepartmentList);
		If SelectedDivisions.Count() = 0 Then
			Return;
		EndIf;
		
		QueryText = NStr("vi = 'Đối với các đơn vị được chọn, kho sẽ bị xóa. Tiếp tục?';
						|ru = 'Для выбранных подразделений будет очищен склад. Продолжить?';
						|en = 'Warehouse for the selected business units will be cleared. Continue?'; fa = 'Warehouse for the selected business units will be cleared. Continue?';
						|it = 'Per i reparti selezionate verrà cancellato il magazzino. Continuare?';
						|pl = 'Dla wybranych działów zostanie wyczyszczony magazyn. Kontynuować?';
						|tr = 'Ambar, seçilen departmanlar için temizlenecektir. Devam edilsin mi?'");
		CallbackDescription = New CallbackDescription("ClearWarehouseCompletion", ThisObject, SelectedDivisions);
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continuare';
													|pl = 'Continue';
													|tr = 'Devam et'"));
		ButtonsList.Add(DialogReturnCode.Cancel);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
	EndIf;
	
EndProcedure

&AtClient
Procedure CommandFillWarehouseCompletion(ClosingResult, SelectedDivisions) Export

	If ClosingResult <> Undefined Then
		FillWarehouseOnServer(ClosingResult, SelectedDivisions);
		Items.DepartmentList.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearWarehouseCompletion(QuestionResult, SelectedDivisions) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillWarehouseOnServer(PredefinedValue("Catalog.Warehouses.EmptyRef"), SelectedDivisions);
		Items.DepartmentList.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormSettingsItem

&AtServer
Procedure ConfigureFormByParameters()
	
	// Determining the source of the form call, filling in the details of the selection parameters and the form header.
	Source = Undefined;
	Parameters.Property("Source", Source);
	
	If Source = "Warehouse" Then
		
		Parameters.Filter.Property("Warehouse", FilterWarehouse);
		
		UsePackages = False;
		
		Template = NStr("vi = 'Thiết lập các cách để đảm bảo nhu cầu (Kho: ""%1"")';
						|ru = 'Настройка способов обеспечения потребностей (Склад: ""%1"")';
						|en = 'Set up procurement strategies (Warehouse: ""%1"")'; fa = 'Set up procurement strategies (Warehouse: ""%1"")';
						|it = 'Impostazione delle modalità di approvvigionamento dei fabbisogni (Magazzino: ""%1"")';
						|pl = 'Dostosowywanie sposobów zaspokajania potrzeb (Magazyn: ""%1"")';
						|tr = 'Tedarik stratejisi ayarı (Ambar: ""%1"")'");
		Title = StrTemplate(Template, FilterWarehouse);
		
	ElsIf Source = "Products" Then
		
		Parameters.Filter.Property("Products", FilterProducts);
		
		ValuesOfProductItemDetails = Common.ObjectAttributesValues(FilterProducts,
			"SupplyScheme, UsePackages");
		FilterSupplyScheme	= ValuesOfProductItemDetails.SupplyScheme;
		UsePackages	= ValuesOfProductItemDetails.UsePackages;
		
		Template = NStr("vi = 'Thiết lập các cách để đảm bảo nhu cầu (Mặt hàng: ""%1"")';
						|ru = 'Настройка способов обеспечения потребностей (Номенклатура: ""%1"")';
						|en = 'Set up procurement strategies (Items: ""%1"")'; fa = 'Set up procurement strategies (Items: ""%1"")';
						|it = 'Impostazione delle modalità di approvvigionamento dei fabbisogni (articolo: ""%1"")';
						|pl = 'Dostosowywanie sposobów zaspokajania potrzeb (Nomenklatura: ""%1"")';
						|tr = 'Tedarik stratejisi ayarı (Öğe: ""%1"")'");
		Title = StrTemplate(Template, FilterProducts);
		
	ElsIf Source = "SupplySchemeGoods" Then
		
		Parameters.Property("Products",	FilterProducts);
		Parameters.Property("Characteristic",FilterCharacteristic);
		Parameters.Property("Warehouse",			FilterWarehouse);
		
		ValuesOfProductItemDetails = Common.ObjectAttributesValues(FilterProducts,
			"SupplyScheme, UsePackages");
		FilterSupplyScheme	= ValuesOfProductItemDetails.SupplyScheme;
		UsePackages	= ValuesOfProductItemDetails.UsePackages;
		
		Template = NStr("vi = 'Thiết lập các cách để đảm bảo nhu cầu (Mặt hàng: ""%1"")';
						|ru = 'Настройка способов обеспечения потребностей (Номенклатура: ""%1"")';
						|en = 'Set up procurement strategies (Items: ""%1"")'; fa = 'Set up procurement strategies (Items: ""%1"")';
						|it = 'Impostazione delle modalità di approvvigionamento dei fabbisogni (articolo: ""%1"")';
						|pl = 'Dostosowywanie sposobów zaspokajania potrzeb (Nomenklatura: ""%1"")';
						|tr = 'Tedarik stratejisi ayarı (Öğe: ""%1"")'");
		Title = StrTemplate(Template, FilterProducts);
		
	ElsIf Source = "SupplyScheme" Then
		
		Parameters.Property("Key",	FilterSupplyScheme);
		Parameters.Property("Warehouse",	FilterWarehouse);
		
		UsePackages = False;
		
		If ValueIsFilled(FilterSupplyScheme) Then
			ValueToFormAttribute(FilterSupplyScheme.GetObject(), "SupplyScheme");
			Template = NStr("vi = '%1 (Sơ đồ đảm bảo)';
							|ru = '%1 (Схема обеспечения)';
							|en = '%1 (Supply scheme)'; fa = '%1 (Supply scheme)';
							|it = '%1 (Schema di approvvigionamento)';
							|pl = '%1 (Schemat zabezpieczeń)';
							|tr = '%1 (Arz şeması)'");
			Title = StrTemplate(Template, SupplyScheme.Description);
		Else
			Title = NStr("vi = 'Sơ đồ đảm bảo (tạo)';
						|ru = 'Схема обеспечения (создание)';
						|en = 'Supply scheme (Create)'; fa = 'Supply scheme (Create)';
						|it = 'Schema di approvvigionamento (creazione)';
						|pl = 'Schemat udostępniania (tworzenie)';
						|tr = 'Arz şeması (oluşturma)'");
		EndIf;
		
		If Parameters.Property("CopyingValue") Then
			SupplyScheme.Description = String(Parameters.CopyingValue);
		EndIf;
		
	Else
		Raise NStr("vi = 'Mở trực tiếp của hình thức này không được cung cấp!';
					|ru = 'Непосредственное открытие этой формы не предусмотрено!';
					|en = 'Application cannot open this form explicitly.'; fa = 'Application cannot open this form explicitly.';
					|it = 'L''apertura diretta di questo modulo non è prevista!';
					|pl = 'Bezpośrednie otwarcie tego formularza nie jest przewidziane!';
					|tr = 'Bu formun doğrudan açılması sağlanmamaktadır!'");
	EndIf;
	
	// Setting up form elements.
	ThisIsAssuranceScheme = Source = "SupplyScheme";
	
	Items.CommandBarSupplySchemes.Visible	= ThisIsAssuranceScheme;
	Items.SecuritySchemeHeader.Visible			= ThisIsAssuranceScheme;
	
	Items.CommandsFormsOfProductSupplyMethods.Visible	= Not ThisIsAssuranceScheme;
	Items.ToAccessTheHelpButton.Visible	= Not ThisIsAssuranceScheme;
	
	Items.PageWaysToSecureAWarehouse.Visible = Source = "Warehouse";
	Items.PageWaysToProvideAnItem.Visible	=
		ThisIsAssuranceScheme Or Source = "Products" Or Source = "SupplySchemeGoods";
	Items.DepartmentSetupPage.Visible	= ThisIsAssuranceScheme;
	
	Items.FilterByItemVariant.Visible = Not ThisIsAssuranceScheme And
		Catalogs.Products.ItemVariantsAreUsed(FilterProducts);
	
	If Not UsePackages Then
		Items.CommandsOfSettingOrderPackagingByProducts.Visible	= False;
		
		Items.FormatTreeContextMenuFillInTheItemOrderPackaging.Visible	= False;
		Items.FormatTreeContextMenuClearItemOrderPackaging.Visible	= False;
		Items.WarehousesListContextMenuFillInTheItemOrderPackaging.Visible	= False;
		Items.WarehousesListContextMenuClearItemOrderPackaging.Visible	= False;
		
		Items.FormatTreeOrderPackage.Visible			= False;
		Items.WarehousesListOrderPackage.Visible			= False;
		Items.FormatTreeThereIsSettingForGoods.Visible	= False;
		Items.WarehousesListThereIsSettingForGoods.Visible	= False;
	EndIf;
	
	If Items.SecuritySchemeHeader.Visible Then
		
		NumberOfUses = Catalogs.SupplySchemes.NumberOfUses(FilterSupplyScheme);
		If NumberOfUses > 0 Then
			RowsArray = New Array;
			RowsArray.Add(NStr("vi = 'Dùng cho hàng hóa';
								|ru = 'Используется для товаров';
								|en = 'Used for goods'; fa = 'Used for goods';
								|it = 'Utilizzato per le merci';
								|pl = 'Używany dla towarów';
								|tr = 'Ürünler için kullanılır'"));
			RowsArray.Add(" (");
			TextTotal = StrTemplate(NStr("vi = 'tổng cộng: %1';
										|ru = 'всего: %1';
										|en = 'total: %1'; fa = 'total: %1';
										|it = 'totale: %1';
										|pl = 'razem: %1';
										|tr = 'toplam: %1'"),
				NumberOfUses);
			If AccessRight("View", Metadata.Reports.SupplySchemeGoods) Then
				RowsArray.Add(New FormattedString(TextTotal,,,, "#GoTo"));
			Else
				RowsArray.Add(TextTotal);
			EndIf;
			RowsArray.Add(")");
			Items.LabelUsingTheScheme.Title = New FormattedString(RowsArray);
		Else
			Items.LabelUsingTheScheme.Title = NStr("vi = 'Không được chỉ định cho bất kỳ sản phẩm';
													|ru = 'Не назначена ни одному товару';
													|en = 'Not assigned to any goods'; fa = 'Not assigned to any goods';
													|it = 'Non è assegnata ad alcun prodotto';
													|pl = 'Nie przypisany do żadnego towaru';
													|tr = 'Herhangi bir ürüne atanmadı'");
		EndIf;
		
	EndIf;
	
	If Items.PageWaysToSecureAWarehouse.Visible Then
		
		Items.PagesSupplyParameters.PagesRepresentation = FormPagesRepresentation.None;
		
		CommonClientServer.SetDynamicListParameter(ListOfWarehouseSupplyMethods,
			"Warehouse", FilterWarehouse);
		
		OnlySuppliedProducts = True;
		CommonClientServer.SetDynamicListParameter(ListOfWarehouseSupplyMethods,
			"OnlySuppliedProducts", OnlySuppliedProducts, OnlySuppliedProducts);
		
		CommonClientServer.SetDynamicListParameter(ListOfWarehouseSupplyMethods,
			"SourceSchema", NStr("vi = 'Sơ đồ đảm bảo';
								|ru = 'Схема обеспечения';
								|en = 'Supply scheme'; fa = 'طرح تأمین';
								|it = 'Schema di approvvigionamento';
								|pl = 'Schemat zaopatrzenia';
								|tr = 'Arz şeması'"));
		CommonClientServer.SetDynamicListParameter(ListOfWarehouseSupplyMethods,
			"SourceMethod", NStr("vi = 'Phương thức đảm bảo';
								|ru = 'Способ обеспечения';
								|en = 'Procurement strategy'; fa = 'راهبرد تدارکات';
								|it = 'Modalità di approvvigionamento';
								|pl = 'Sposób zaopatrzenia';
								|tr = 'Tedarik stratejisi'"));
		
	EndIf;
	
	If Items.PageWaysToProvideAnItem.Visible Then
		
		If Not ThisIsAssuranceScheme Then
			Items.PagesSupplyParameters.PagesRepresentation = FormPagesRepresentation.None;
		EndIf;
		
		If Items.FormatTree.Visible Then
			LoadFormatTree();
		EndIf;
		
		CommonClientServer.SetDynamicListParameter(WarehousesList,
			"SupplyScheme", FilterSupplyScheme);
		CommonClientServer.SetDynamicListParameter(WarehousesList,
			"Products", FilterProducts);
		CommonClientServer.SetDynamicListParameter(WarehousesList,
			"Characteristic", FilterCharacteristic);
		
		If Items.FilterByItemVariant.Visible And MethodSettingIsAvailable Then
			TheAvailabilityStatusChangeTheWay = ?(ValueIsFilled(FilterCharacteristic), "",
				NStr("vi = 'Cài đặt của phương thức ký quỹ chỉ khả dụng cho một lựa chọn nhất định theo đặc tính';
					|ru = 'Установка способа обеспечения доступна только при заданном отборе по характеристике';
					|en = 'Procurement strategy setting is available only if the filter by item variant is set'; fa = 'Procurement strategy setting is available only if the filter by item variant is set';
					|it = 'L''impostazione della modalità di approvvigionamento è disponibile solo per la selezione stabilita per caratteristica';
					|pl = 'Ustawienie metody zabezpieczenia dostępu jest dostępne tylko dla konkretnego wyboru według charakterystyki';
					|tr = 'Tedarik stratejisi ayarı, yalnızca özelliklere göre belirli bir filtre ile kullanılabilir.'"));
			Items.CommandsOfSettingProductSupplyMethod.Enabled = ValueIsFilled(FilterCharacteristic);
			Items.FormatTreeContextMenuCommandsOfSettingProductSupplyMethod.Enabled =
				ValueIsFilled(FilterCharacteristic);
			Items.WarehouseListContextMenuSettingCommandsOfProductSupplyMethod.Enabled =
				ValueIsFilled(FilterCharacteristic);
		EndIf;
		
		If ValueIsFilled(FilterWarehouse) Then
			
			WarehouseFormats = FormatTree.GetItems();
			For Each WarehouseFormat In WarehouseFormats Do
				Warehouses = WarehouseFormat.GetItems();
				For Each Warehouse In Warehouses Do
					If Warehouse.WarehouseFormat = FilterWarehouse Then
						Items.FormatTree.CurrentRow = Warehouse.GetID();
						Break;
					EndIf;
				EndDo;
			EndDo;
			
			Items.WarehousesList.CurrentRow = FilterWarehouse;
			
		EndIf
		
	EndIf;
	If Items.DepartmentSetupPage.Visible Then
		
		SetRequestTextForListOfDivisions();
		CommonClientServer.SetDynamicListParameter(DepartmentList, "SupplyScheme", FilterSupplyScheme);
		
	EndIf;
EndProcedure

&AtServer
Procedure ConfigureFormByRightsAndFunctionalOptions()
	
	If GetFunctionalOption("UseStoreFormats") And GetFunctionalOption("UseSeveralWarehouses") Then
		Representation = "Formats";
		Items.PagesDisplayMode.CurrentPage = Items.PageFormats;
	Else
		Representation = "Warehouses";
		Items.PagesDisplayMode.CurrentPage = Items.WarehousesPage;
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		Items.WarehousesListWarehouse.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseItemVariants") Then
		Items.ListOfWarehouseSupplyMethodsCharacteristic.Visible	= False;
	EndIf;
	
	If Not GetFunctionalOption("UseItemPackages") Then
		Items.ListOfWarehouseSupplyMethodsOrderPackage.Visible	= False;
		Items.WarehousesListOrderPackage.Visible	= False;
		Items.FormatTreeOrderPackage.Visible	= False;
	EndIf;
	
	If Parameters.Source = "SupplyScheme" Then
		SetVisibilityAvailabilityByRolesSoftwareSchema();
		MethodSettingIsAvailable = AccessRight("Edit", Metadata.Catalogs.SupplySchemes);
	Else
		AccessRights = SupplyServer.WriteAccessRightsForMethodOrMethod();
		MethodSettingIsAvailable = AccessRights.SupplyOptions;
		If Not AccessRights.ProductRestrictions Then
			Items.CommandsOfSettingOrderPackagingByProducts.Enabled = False;
			Items.CommandsOfSettingWarehouseOrderPackaging.Enabled = False;
			
			Items.FormatTreeContextMenuCommandsOfSettingOrderPackagingByProducts.Enabled = False;
			Items.WarehouseListContextMenuCommandsOfSettingOrderPackagingByProducts.Enabled = False;
			Items.CommandsOfSettingWarehouseOrderPackaging.Enabled = False;
		EndIf;
	EndIf;
	
	If Not MethodSettingIsAvailable Then
		Items.TheAvailabilityStatusChangeTheWay.Visible = False;
		
		Items.CommandsOfSettingProductSupplyMethod.Enabled = False;
		Items.CommandsOfSettingWarehouseSupplyMethod.Enabled = False;
		
		Items.FormatTreeContextMenuCommandsOfSettingProductSupplyMethod.Enabled = False;
		Items.WarehouseListContextMenuSettingCommandsOfProductSupplyMethod.Enabled = False;
		Items.CommandsOfSettingWarehouseSupplyMethod.Enabled = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region OtherWaysToSecureWarehouse

&AtServerNoContext
Procedure FillInMethodForSecuringWarehouseOnSrever(DataArray, SupplyMethod = Undefined)
	
	If DataArray.Count() = 0 Then
		Return;
	EndIf;
	
	If SupplyMethod = Undefined Then
		SupplyMethod = PredefinedValue("Catalog.ProcurementStrategies.EmptyRef");
	EndIf;
	
	TableOfGoods = New ValueTable();
	TableOfGoods.Columns.Add("Id",	New TypeDescription("Number"));
	TableOfGoods.Columns.Add("Products",		New TypeDescription("CatalogRef.Products"));
	TableOfGoods.Columns.Add("Characteristic",	New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfGoods.Columns.Add("Warehouse",			New TypeDescription("CatalogRef.Warehouses"));
	
	For Each Data In DataArray Do
		RowOfProduct = TableOfGoods.Add();
		RowOfProduct.Products	= Data.Products;
		RowOfProduct.Characteristic	= Data.Characteristic;
		RowOfProduct.Warehouse			= Data.Warehouse;
	EndDo;
	
	InformationRegisters.GoodsProcurementStrategy.FillInCollateralMethod(TableOfGoods, SupplyMethod);
	
EndProcedure

&AtServerNoContext
Procedure FillInOrderPackagingInWarehouseOnServer(Products, Characteristic, Warehouse, OrderPackage = Undefined)
	
	If OrderPackage = Undefined Then
		PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef")
	EndIf;
	
	InformationRegisters.ProductRestrictions.SetProductPackaging(Products, Characteristic, Warehouse, OrderPackage);
	
EndProcedure

#EndRegion

#Region OtherCollateral

&AtServer
Procedure SetVisibilityAvailabilityByRolesSoftwareSchema()
	
	CanEdit1 = AccessRight("Edit", Metadata.Catalogs.SupplySchemes);
	Items.Description.Enabled = CanEdit1;
	
	AddingChangingLogisticParametersIsAvailable = AccessRight("Read", Metadata.InformationRegisters.SupplySchemes);
	If Not AddingChangingLogisticParametersIsAvailable Then
		
		Items.PagesDisplayMode.Visible = False;
		Items.HeaderOfTheListOfSecurityMethods.Visible = False;
		Items.LabelUsingTheScheme.Visible = False;
		
	EndIf;
	
	ReadingProductionAssuranceScheme = False;
	ReadingProductionAssuranceScheme = AccessRight("Read", Metadata.InformationRegisters.ProductionSupplySchemes);
	If Not ReadingProductionAssuranceScheme Then
		Items.DepartmentList.Visible = False;
	EndIf;
	If Not AccessRight("Update", Metadata.InformationRegisters.ProductionSupplySchemes) Then
		Items.DepartmentListWarehouseSettingCommandGroup.Enabled = False;
		Items.DepartmentListContextMenuWarehouseSettingCommands.Enabled = False;
	EndIf;
	If Not GetFunctionalOption("UseProductionManagement2_2")
		Or Not ReadingProductionAssuranceScheme 
		Or Not AddingChangingLogisticParametersIsAvailable Then
		Items.PagesSupplyParameters.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteBeforeExecutingCommand(CommandName)
	
	CommandExecuteParameters = New Structure("Name", CommandName);
	If Parameters.Source = "SupplyScheme" And Not ValueIsFilled(SupplyScheme.Ref) Then
		
		QueryText = NStr("vi = 'Để thực hiện một lệnh, cần ghi một đối tượng. Ghi lại?';
						|ru = 'Для выполнения команды необходимо записать объект. Записать?';
						|en = 'To run the command, save the object. Save it?'; fa = 'To run the command, save the object. Save it?';
						|it = 'Per eseguire un comando, è necessario registrare un oggetto. Registrare?';
						|pl = 'Aby wykonać polecenie, musisz zapisać obiekt. Zapisać?';
						|tr = 'Komutu yürütmek için nesnenin kaydedilmesi gerekir. Kaydet?'");
		CallbackDescription = New CallbackDescription("RunCommandAfterQuestion", ThisObject, CommandExecuteParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.OKCancel);
		
	Else
		
		RunCommandAfterQuestion(Undefined, CommandExecuteParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LoadFormatTree(Refresh = False)
	
	If Not Refresh And Items.FormatTree.CurrentRow <> Undefined Then
		WarehouseFormat = FormatTree.FindByID(Items.FormatTree.CurrentRow).WarehouseFormat;
	EndIf;
	
	WarehousesToUpgrade = ?(Refresh, ChangedWarehouses.UnloadValues(), Undefined);
	FormatsToUpdate = ?(Refresh, ChangedFormats.UnloadValues(), Undefined);
	
	DataProcessors.SettingOfProcurementStrategies.LoadFormatTree(FormatTree, FilterSupplyScheme,
		FilterProducts, FilterCharacteristic, WarehousesToUpgrade, FormatsToUpdate);
	ChangedWarehouses.Clear();
	ChangedFormats.Clear();
	
	If Not Refresh And Items.FormatTree.CurrentRow <> Undefined
		And (FormatTree.FindByID(Items.FormatTree.CurrentRow) = Undefined
		Or FormatTree.FindByID(Items.FormatTree.CurrentRow).WarehouseFormat <> WarehouseFormat) Then
		
		WarehouseFormats = FormatTree.GetItems();
		For Each Var_71_WarehouseFormat In WarehouseFormats Do
			If Var_71_WarehouseFormat.WarehouseFormat = WarehouseFormat Then
				Items.FormatTree.CurrentRow = Var_71_WarehouseFormat.GetID();
				Return;
			EndIf;
			
			Warehouses = Var_71_WarehouseFormat.GetItems();
			For Each Warehouse In Warehouses Do
				If Warehouse.WarehouseFormat = WarehouseFormat Then
					Items.FormatTree.CurrentRow = Warehouse.GetID();
					Return;
				EndIf;
			EndDo;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetRequestTextForListOfDivisions()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, DepartmentList);
	
	ListProperties.QueryText =
	"SELECT
	|	CatalogBusinessStructure.Ref AS Ref,
	|	CatalogBusinessStructure.Description AS Description,
	|	CatalogBusinessStructure.ProductionBusinessUnit AS ProductionBusinessUnit,
	|	CatalogBusinessStructure.DeletionMark AS DeletionMark,
	|	CatalogBusinessStructure.Parent AS Parent,
	|	ISNULL(ProductionSupplySchemes.Warehouse, VALUE(Catalog.Warehouses.EmptyRef)) AS Warehouse,
	|	0 AS ChangeWarehouse
	|FROM
	|	Catalog.BusinessStructure AS CatalogBusinessStructure
	|		LEFT JOIN InformationRegister.ProductionSupplySchemes AS ProductionSupplySchemes
	|		ON CatalogBusinessStructure.Ref = ProductionSupplySchemes.Department
	|			AND (ProductionSupplySchemes.SupplyScheme = &SupplyScheme)";
	
	Common.SetDynamicListProperties(Items.DepartmentList, ListProperties);
	
EndProcedure

&AtServer
Procedure FillWarehouseOnServer(Warehouse, SelectedDivisions)

	For Each Department In SelectedDivisions Do
		
		RegisterRecord = InformationRegisters.ProductionSupplySchemes.CreateRecordManager();
		RegisterRecord.SupplyScheme = SupplyScheme.Ref;
		RegisterRecord.Department = Department;
		If ValueIsFilled(Warehouse) Then
			RegisterRecord.Warehouse = Warehouse;
			RegisterRecord.Write();
		Else
			RegisterRecord.Delete();
		EndIf; 
		
	EndDo;

EndProcedure

#EndRegion

#Region OtherWaysToProvideProducts

&AtServer
Function FillInMethodOfProvidingProductsOnServer(SupplyMethod = Undefined)
	
	If SupplyMethod = Undefined Then
		SupplyMethod = PredefinedValue("Catalog.ProcurementStrategies.EmptyRef");
	EndIf;
	
	ThisIsForProduct	= ValueIsFilled(FilterProducts);
	IsInstallation	= ValueIsFilled(SupplyMethod);
	
	If Representation = "Warehouses" Then
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	Warehouses.Ref AS Id,
			|	Warehouses.Ref AS Warehouse,
			|	&Products,
			|	&Characteristic
			|FROM
			|	Catalog.Warehouses AS Warehouses
			|WHERE
			|	NOT Warehouses.IsFolder
			|	AND Warehouses.Ref IN(&Warehouses)";
		
		Query.SetParameter("Products", FilterProducts);
		Query.SetParameter("Characteristic", FilterCharacteristic);
		Query.SetParameter("Warehouses", Items.WarehousesList.SelectedRows);
	
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			Return False;
		EndIf;
		
		If ThisIsForProduct Then
			ProcessedRows = InformationRegisters.GoodsProcurementStrategy.FillInCollateralMethod(
				QueryResult.Unload(), SupplyMethod);
			CommonClientServer.SupplementArray(ChangedWarehouses, ProcessedRows, True);
		Else
			Selection = QueryResult.Select();
			While Selection.Next() Do
				If IsInstallation Then
					InformationRegisters.SupplySchemes.Add(Selection.Warehouse, FilterSupplyScheme, SupplyMethod);
				Else
					InformationRegisters.SupplySchemes.Delete(Selection.Warehouse, FilterSupplyScheme);
				EndIf;
				ChangedWarehouses.Add(Selection.Warehouse);
			EndDo;
		EndIf;
		
		Items.WarehousesList.Refresh();
		
	Else
		
		If ThisIsForProduct Then
			TableOfGoods = New ValueTable();
			TableOfGoods.Columns.Add("Id",	New TypeDescription("CatalogRef.Warehouses"));
			TableOfGoods.Columns.Add("Products",		New TypeDescription("CatalogRef.Products"));
			TableOfGoods.Columns.Add("Characteristic",	New TypeDescription("CatalogRef.ItemsCharacteristics"));
			TableOfGoods.Columns.Add("Warehouse",			New TypeDescription("CatalogRef.Warehouses"));
		EndIf;
		
		For Each Id In Items.FormatTree.SelectedRows Do
			
			TreeRow = FormatTree.FindByID(Id);
			
			If Not ValueIsFilled(TreeRow.WarehouseFormat) Then
				Continue;
			EndIf;
			If ThisIsForProduct Then
				If TreeRow.ItIsFormat Then
					Continue;
				EndIf;
				RowOfProduct = TableOfGoods.Add();
				RowOfProduct.Id	= TreeRow.WarehouseFormat;
				RowOfProduct.Products	= FilterProducts;
				RowOfProduct.Characteristic	= FilterCharacteristic;
				RowOfProduct.Warehouse			= TreeRow.WarehouseFormat;
			Else
				If IsInstallation Then
					InformationRegisters.SupplySchemes.Add(TreeRow.WarehouseFormat, FilterSupplyScheme, SupplyMethod);
				Else
					InformationRegisters.SupplySchemes.Delete(TreeRow.WarehouseFormat, FilterSupplyScheme);
				EndIf;
				If TreeRow.ItIsFormat Then
					ChangedFormats.Add(TreeRow.WarehouseFormat);
				Else
					ChangedWarehouses.Add(TreeRow.WarehouseFormat);
				EndIf;
			EndIf;
			
		EndDo;
			
		If ThisIsForProduct Then
			If TableOfGoods.Count() = 0 Then
				Return False;
			EndIf;
			ProcessedRows = InformationRegisters.GoodsProcurementStrategy.FillInCollateralMethod(TableOfGoods,
				SupplyMethod);
			CommonClientServer.SupplementArray(ChangedWarehouses, ProcessedRows, True);
		EndIf;
		
		LoadFormatTree(True);
		
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure FillInProductOrderPackagingOnServer(OrderPackage)
	
	If Representation = "Warehouses" Then
		
		For Each Warehouse In Items.WarehousesList.SelectedRows Do
			
			If Warehouse.IsFolder Then
				Continue;
			EndIf;
			
			InformationRegisters.ProductRestrictions.SetProductPackaging(FilterProducts, FilterCharacteristic,
				Warehouse, OrderPackage);
				
			ChangedWarehouses.Add(Warehouse);
			
		EndDo;
		
		Items.WarehousesList.Refresh();
		
	Else
		
		For Each Id In Items.FormatTree.SelectedRows Do
			
			TreeRow = FormatTree.FindByID(Id);
			
			If Not ValueIsFilled(TreeRow.WarehouseFormat) Or TreeRow.ItIsFormat Then
				Continue;
			EndIf;
			
			InformationRegisters.ProductRestrictions.SetProductPackaging(FilterProducts, FilterCharacteristic,
				TreeRow.WarehouseFormat, OrderPackage);
			
			TreeRow.OrderPackage = OrderPackage;
			
		EndDo;
		
	EndIf;
		
EndProcedure

#EndRegion

&AtClient
Function ThereAreHighlightedRowsInTable(FormTable)
	
	If FormTable.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không một dòng nào được chọn. Thực thi lệnh là không thể.';
								|ru = 'Не выделено ни одной строки. Выполнение команды невозможно.';
								|en = 'No lines are selected. Cannot execute the command.'; fa = 'No lines are selected. Cannot execute the command.';
								|it = 'Nessuna riga selezionata. Il comando non può essere eseguito.';
								|pl = 'Nie wybrano ani jednego wierszu. Wykonanie polecenia jest niemożliwe.';
								|tr = 'Hiçbir satır vurgulanmadı. Komut çalıştırılamıyor.'"));
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_ProcurementStrategy" Then
		If Items.PageWaysToProvideAnItem.Visible Then
			WarehouseFormats = FormatTree.GetItems();
			For Each WarehouseFormat In WarehouseFormats Do
				If WarehouseFormat.SupplyMethod = Source Then
					ChangedFormats.Add(WarehouseFormat.WarehouseFormat);
				EndIf;
				
				Warehouses = WarehouseFormat.GetItems();
				For Each Warehouse In Warehouses Do
					If Warehouse.SupplyMethod = Source Then
						ChangedWarehouses.Add(Warehouse.WarehouseFormat);
					EndIf;
				EndDo;
			EndDo;
			
			If Representation = "Formats"
			And (ChangedWarehouses.Count() > 0 Or ChangedFormats.Count() > 0) Then
				LoadFormatTree(True);
			EndIf;
		ElsIf Items.PageWaysToSecureAWarehouse.Visible Then
			Items.ListOfWarehouseSupplyMethods.Refresh();
		EndIf;
	EndIf;
EndProcedure

#EndRegion