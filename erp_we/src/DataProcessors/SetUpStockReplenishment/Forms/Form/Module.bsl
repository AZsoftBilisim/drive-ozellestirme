
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	LegendOfInventoryLevelControlForProducts		= 3;
	LegendControlOfProductsLevelInGeneral	= 4;
	LegendOfInventoryLevelControlForGroup			= 0;
	
	InitializeUserSettings();
	
	ConfigureFormByRightsAndFunctionalOptions();
	ConfigureFormByParameters();
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		Object.Warehouse = Catalogs.Warehouses.DefaultWarehouse();
	EndIf;
	
	RequestAListOfSupportedStocks = ControlledInventoryList.QueryText;
	
	If ValueIsFilled(Object.Warehouse) Then
		SetAccessibilityOfAddButtons(ThisObject, True);
		CalculateStockMaintenanceRecommendations();
	Else
		SetAccessibilityOfAddButtons(ThisObject, False);
	EndIf;
	
	RecommendationMode = 0;
	CurrentGroup = Undefined;
	SetRecommendationAndReviewMode();
	
	CommonClientServer.SetDynamicListParameter(
		ControlledInventoryList,
		"RecommendationToSupport",
		NStr("vi = 'Duy trì hàng tồn kho';
			|ru = 'Поддерживать запас';
			|en = 'Control inventory level'; fa = 'Control inventory level';
			|it = 'Mantenere le scorte';
			|pl = 'Utrzymaj zapasy';
			|tr = 'Stok yenileme'"));
	CommonClientServer.SetDynamicListParameter(
		ControlledInventoryList,
		"RecommendationNotToSupport",
		NStr("vi = 'Không duy trì hàng tồn kho';
			|ru = 'Не поддерживать запас';
			|en = 'Do not control inventory level'; fa = 'Do not control inventory level';
			|it = 'Non mantenere le scorte';
			|pl = 'Nie utrzymuj zapasów';
			|tr = 'Stok tutmayın'"));
	
	RestoreSettings();
	LoadCustomListSettings();
	
	OldWarehouse = Object.Warehouse;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Cancel = True;
		WarningText = NStr("vi = 'Thay đổi lựa chọn sản phẩm sẽ bị mất.';
							|ru = 'Изменения отбора товаров будут потеряны.';
							|en = 'Changes of good filter will be lost.'; fa = 'Changes of good filter will be lost.';
							|it = 'Modifiche nella selezione di merci andranno perse';
							|pl = 'Zmiany wyboru towarów zostaną stracone.';
							|tr = 'Mal seçimindeki değişiklikler kaybolacaktır.'");
	Else
	SynchronizeComposerSettings();
	ShouldSaveSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ExpectCalculationOfWarehouseInventoryMaintenanceRecommendations();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.GoodsRestrictionGrouping.Form.ChoiceForm" Then
		
		RecordsArray = Items.ControlledInventoryList.SelectedRows;
		MoveToGroupOnServer(RecordsArray, ValueSelected, Object.Warehouse);
		If CurGroupIsEmpty(CurrentGroup, Object.Warehouse) Then
			DisplayMode = 1;
			CurrentGroup = Undefined;
			SetRecommendationAndReviewMode();
		Else
			Items.ControlledInventoryList.Refresh();
		EndIf;
		
	ElsIf ChoiceSource.FormName = "DataProcessor.DemandFulfillment.Form.EditFormSupplyParameters" Then
		
		If TypeOf(ValueSelected) = Type("Structure") Then
			
			RecordsArray = Items.ControlledInventoryList.SelectedRows;
			FillInCollateralMethodOnServer(RecordsArray, ValueSelected);
			Items.ControlledInventoryList.Refresh();
			
		ElsIf TypeOf(ValueSelected) = Type("String") And ValueSelected = "ParameterRecorded" Then
			
			Items.ControlledInventoryList.Refresh();
			
		EndIf;
		
	ElsIf ChoiceSource.FormName = "Catalog.Products.Form.ChoiceForm" Then
		
		AddProductInventoryMaintenanceOnServer(ValueSelected, Object.Warehouse, CurrentGroup);
		Items.ControlledInventoryList.Refresh();
		
	ElsIf ChoiceSource.FormName = "Catalog.ItemsCharacteristics.Form.ChoiceForm" Then
		
		AddMaintainingStockOfCharacteristicsOnServer(CurrentProducts, ValueSelected, CurrentWarehouse, CurrentGroup);
		Items.ControlledInventoryList.Refresh();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FormatOnChange(Item)
	
	CommonClientServer.SetDynamicListParameter(
			ControlledInventoryList,
			"StoreFormat",
			Object.Format,
			ValueIsFilled(Object.Format));
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Item.Warehouse.OnChange");
	
	// If recommendations for the previous warehouse value were not calculated ON changing the warehouse, the calculation data is deleted.
	RelevanceString = GetUpToDateWarehouseRecommendations(RecommendationRelevance, OldWarehouse);
	If RelevanceString <> Undefined And ValueIsFilled(RelevanceString.JobID) Then
		RecommendationRelevance.Delete(RelevanceString);
	EndIf;
	
	ExpectRecommendationsToBeCalculated = WarehouseWhenChangedOnServer();
	
	If ExpectRecommendationsToBeCalculated Then
		ExpectCalculationOfWarehouseInventoryMaintenanceRecommendations();
	EndIf;
	
	OldWarehouse = Object.Warehouse;
	
EndProcedure

&AtClient
Procedure ProductCategoryOnChange(Item)
	
	CommonClientServer.SetDynamicListParameter(
			ControlledInventoryList,
			"ProductCategory",
			Object.ProductCategory,
			ValueIsFilled(Object.ProductCategory));
	
EndProcedure

&AtClient
Procedure RecommendationModeOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Item.RecommendationMode.OnChange");
	
	SetRecommendationAndReviewMode();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersControlledInventoryList

&AtClient
Procedure ControlledInventoryListSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Item.ControlledInventoryList.Selection");
	
	StandardProcessing = False;
	
	If Field = Items.ControlledInventoryListProducts
		Or Field = Items.ListOfSupportedStocksGrouping Then
		If Item.CurrentData.IsFolder Then
			ProductGrouping = Item.CurrentData.GroupingProductRestrictions;
			If DisplayMode = 1 Then
				DisplayMode = 2;
				CurrentGroup = ProductGrouping;
				SetRecommendationAndReviewMode();
				StandardProcessing = False;
			ElsIf DisplayMode = 2 And Item.CurrentData.IsFolder Then
				DisplayMode = 1;
				CurrentGroup = Undefined;
				SetRecommendationAndReviewMode();
				StandardProcessing = False;
			EndIf;
		Else
			ShowValue(,Item.CurrentData.Products);
		EndIf;
	ElsIf  Field = Items.ControlledInventoryListCharacteristic Then
		ShowValue(,Item.CurrentData.Characteristic);
	ElsIf Field = Items.ControlledInventoryListWarehouse Then
		ShowValue(,Item.CurrentData.Warehouse);
	ElsIf Field = Items.ControlledInventoryListUnitOfMeasure Then
		ShowValue(,Item.CurrentData.UnitOfMeasure);
	ElsIf Field = Items.ControlledInventoryListSupplyMethod Then
		ShowValue(,Item.CurrentData.SupplyMethod);
	ElsIf Field = Items.ControlledInventoryListSupplySource
		And Item.CurrentData.SupplySource <> Undefined Then
		ShowValue(,Item.CurrentData.SupplySource);
	ElsIf Field = Items.ControlledInventoryListSupplyScheme Then
		ShowValue(,Item.CurrentData.SupplyScheme);
	ElsIf Item.CurrentData.IsFolder Or Not ValueIsFilled(Item.CurrentData.GroupingProductRestrictions) Then
		OpenParameterEditingForm(Item.CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure ControlledInventoryListBeforeRowChange(Item, Cancel)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Item.ControlledInventoryList.BeforeRowChange");
	
	Cancel = True;
	OpenParameterEditingForm(Item.CurrentData);
	
EndProcedure

&AtClient
Procedure ControlledInventoryListBeforeDeleteRow(Item, Cancel)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.ExcludeFromMaintainingStock");
	
	Cancel = True;
	
	If ThereAreHighlightedLines() Then
		RecordsArray = Items.ControlledInventoryList.SelectedRows;
		RemoveMaintainingStockOnServer(RecordsArray, Object.Warehouse);
		If CurGroupIsEmpty(CurrentGroup, Object.Warehouse) Then
			DisplayMode = 1;
			CurrentGroup = Undefined;
			SetRecommendationAndReviewMode();
		Else
			Items.ControlledInventoryList.Refresh();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddGoodsByPicking(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.AddGoodsByPicking");
	
	FormParameters = New Structure();
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("FilterByProductType",
		New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
	
	OpenForm("DataProcessor.GoodsSelectionByPicking.Form.Form", FormParameters, ThisForm,,,,
		New CallbackDescription("AddProducts_2Completion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.ImportFromExternalFile");
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.ImportQuantity = False;
	ImportParameters.ImportInventory     = True;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Notification = New CallbackDescription("AddProducts_2Completion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure AddedFeature(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.AddedFeature");
		
	RowData = Items.ControlledInventoryList.CurrentData;
	
	If RowData = Undefined Or Not ValueIsFilled(RowData.Products) Then
		ShowMessageBox(,
			NStr("vi = 'Không có mục nào được chọn cho các đặc điểm cần thiết để đặt các tham số riêng lẻ. Thực thi lệnh là không thể.';
				|ru = 'Не выбрана номенклатура, для характеристик которой требуется установить индивидуальные параметры. Выполнение команды невозможно.';
				|en = 'Items with variants which require individual parameter specification are not selected. Cannot execute the command.'; fa = 'Items with variants which require individual parameter specification are not selected. Cannot execute the command.';
				|it = 'L''articolo non è selezionato, per le caratteristiche della quale si desidera impostare i parametri individuali. Il comando non può essere eseguito.';
				|pl = 'Nie jest wybrana nomenklatura, dla której charakterystyki chcesz ustawić poszczególne parametry. Polecenie nie może zostać wykonane.';
				|tr = 'Özellikleri için ayrı parametrelerin ayarlanacağı ürün seçilmedi. Komut çalıştırılamaz.'"));
	ElsIf Not RowData.ItemVariantsAreUsed Then
		ShowMessageBox(,
			NStr("vi = 'Không có đặc tính được sử dụng cho các mục đã chọn. Thực thi lệnh là không thể.';
				|ru = 'Для выбранной номенклатуры характеристики не используются. Выполнение команды невозможно.';
				|en = 'Variants are not used for the selected item. Cannot execute the command.'; fa = 'Variants are not used for the selected item. Cannot execute the command.';
				|it = 'Per l''articolo selezionato non vengono utilizzate le caratteristiche. Il comando non può essere eseguito.';
				|pl = 'Dla wybranej nomenklatury nie są używane żadne cechy. Polecenie nie może zostać wykonane.';
				|tr = 'Seçili ürün için varyantlar kullanılmamaktadır. Komut çalıştırılamıyor.'"));
	Else
		Data = Items.ControlledInventoryList.CurrentData;
		CurrentProducts = Data.Products;
		CurrentWarehouse        = Data.Warehouse;
		
		FormParameters = New Structure;
		FormParameters.Insert("CloseOnChoice", False);
		FormParameters.Insert("MultipleChoice", True);
		FormParameters.Insert("Products", CurrentProducts);
		OpenForm("Catalog.ItemsCharacteristics.ChoiceForm", FormParameters, ThisForm);
	EndIf;
EndProcedure

&AtClient
Procedure FillInSupplyMethod(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.FillInSupplyMethod");
	
	If ThereAreHighlightedLines() Then
		CurrentData = Items.ControlledInventoryList.CurrentData;
		NeedKey = New Structure;
		NeedKey.Insert("StrategyOfProcurement",
			?(CurrentData = Undefined,
			PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentMinMax"),
			CurrentData.InventoryLevelControl));
		FormParameters = New Structure("NeedKey, OpeningMode", NeedKey, "MethodOnly");
	
		OpenForm("DataProcessor.DemandFulfillment.Form.EditFormSupplyParameters", FormParameters, ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheMinimumInventory(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.FillInTheMinimumInventory");
	
	If ThereAreHighlightedLines() Then
		FillInResource("MinimumInventoryQuantity");
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheMaximumInventory(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.FillInTheMaximumInventory");
	
	If ThereAreHighlightedLines() Then
		FillInResource("MaximumInventoryAmount");
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheSafetyStock(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.FillInTheSafetyStock");
	
	If ThereAreHighlightedLines() Then
		FillInResource("SafetyStockQuantity");
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheConsumptionRate(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.FillInTheConsumptionRate");
	
	If ThereAreHighlightedLines() Then
		FillInResource("ConsumptionRate");
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInOrderFulfillment(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.FillInOrderFulfillment");
	
	If ThereAreHighlightedLines() Then
		FillInResource("OrderFulfillmentWithinInventoryReplenishment");
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateRecommendationsAndConsumptionStatistics(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.CalculateConsumptionStatistics");
	
	RecommendationState = NStr("vi = 'Khuyến nghị đang được tính toán';
								|ru = 'Идет расчет рекомендаций';
								|en = 'Calculating recommendations'; fa = 'Calculating recommendations';
								|it = 'Calcolo delle raccomandazioni in corso';
								|pl = 'Obliczanie zaleceń w toku';
								|tr = 'Öneriler hesaplanıyor'");
	Items.RecommendationMode.Enabled = False;
		
	CalculationResult2 = CalculationOfRecommendationsForMaintainingWarehouseInventoryInBackground(True);
	
	RelevanceString = GetUpToDateWarehouseRecommendations(RecommendationRelevance, Object.Warehouse);
	If RelevanceString = Undefined Then
		RelevanceString = RecommendationRelevance.Add();
		RelevanceString.Warehouse = Object.Warehouse;
	EndIf;
	
	If CalculationResult2.Status = "Completed2" Then
		RecommendationState = NStr("vi = 'Khuyến nghị tính toán';
									|ru = 'Рекомендации рассчитаны';
									|en = 'Recommendations are calculated'; fa = 'Recommendations are calculated';
									|it = 'Le raccomandazioni sono calcolate';
									|pl = 'Zalecenia zostały obliczone';
									|tr = 'Öneriler hesaplanır'");
		Items.RecommendationMode.Enabled = True;
		RelevanceString.RecommendationsAreRelevant = True;
		RelevanceString.JobID = Undefined;
		If Items.ControlledInventoryListAverageDailyConsumption.Visible
			Or Items.ControlledInventoryListDeviationOfConsumption.Visible Then
			Items.ControlledInventoryList.Refresh();
		EndIf;
	Else
		RelevanceString.JobID = CalculationResult2.JobID;
		RelevanceString.BackgroundJobResult = CalculationResult2;
		ExpectCalculationOfWarehouseInventoryMaintenanceRecommendations();
	EndIf;
	
EndProcedure

&AtClient
Procedure RemoveFromGroup(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.RemoveFromGroup");
	
	If ThereAreHighlightedLines() Then
		RecordsArray = Items.ControlledInventoryList.SelectedRows;
		MoveToGroupOnServer(RecordsArray, Undefined, Object.Warehouse);
		If CurGroupIsEmpty(CurrentGroup, Object.Warehouse) Then
			DisplayMode = 1;
			CurrentGroup = Undefined;
			SetRecommendationAndReviewMode();
		Else
			Items.ControlledInventoryList.Refresh();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSettingUpTheCalculationOfAverageDailyConsumption(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.OpenSettingUpTheCalculationOfAverageDailyConsumption");
	
	OpenForm("DataProcessor.SetUpStockReplenishment.Form.CustomizeSettingsOfAverageDailyConsumptionCalculation", , ThisForm);
EndProcedure

&AtClient
Procedure MoveToGroupCommand(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.MoveToGroupCommand");
		
	If ThereAreHighlightedLines() Then
		OpenForm("Catalog.GoodsRestrictionGrouping.ChoiceForm",, ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.SelectGoods");
	
	FormParameters = New Structure;
	FormParameters.Insert("CloseOnChoice", False);
	Filter = New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	FormParameters.Insert("Filter", New Structure("ItemsType", Filter));
	
	OpenForm("Catalog.Products.Form.ChoiceForm", FormParameters, ThisForm, UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Group(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.Group");
	
	If ThereAreHighlightedLines() Then
		PropertiesOfSelectedRows = New Structure;
		PropertiesOfSelectedRows.Insert("Format",		Object.Format);
		PropertiesOfSelectedRows.Insert("Warehouse",		Object.Warehouse);
		PropertiesOfSelectedRows.Insert("Category",	Object.ProductCategory);
		PropertiesOfSelectedRows.Insert("Products",Object.Products);
		ResultStructure1 = NameOfNewDefaultGrouping(PropertiesOfSelectedRows);
		CallbackDescription = New CallbackDescription("GroupAfterEnteringName", ThisForm, 
			Items.ControlledInventoryList.SelectedRows);
		ShowInputValue(CallbackDescription, ResultStructure1.Description,
			NStr("vi = 'Nhập tên nhóm';
				|ru = 'Введите наименование группы';
				|en = 'Enter group name'; fa = 'Enter group name';
				|it = 'Inserire il nome del gruppo';
				|pl = 'Wprowadź nazwę grupy';
				|tr = 'Grubun adını girin'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteCharacteristics(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.DeleteCharacteristics");
	
	If ThereAreHighlightedLines() Then
		RecordsArray = Items.ControlledInventoryList.SelectedRows;
		If DeleteDetailedSettingOnServer(RecordsArray) Then
			Items.ControlledInventoryList.Refresh();
		Else
			ShowMessageBox(, NStr("vi = 'Không một dòng nào được chọn với các tham số riêng cho các đặc tính. Thực thi lệnh là không thể.';
									|ru = 'Не выделено ни одной строки с индивидуальными параметрами для характеристик. Выполнение команды невозможно.';
									|en = 'No line with individual parameters for variants is selected. Cannot execute the command.'; fa = 'No line with individual parameters for variants is selected. Cannot execute the command.';
									|it = 'Non esiste una singola riga con parametri individuali per le caratteristiche. Il comando non può essere eseguito.';
									|pl = 'Nie ma pojedynczego wiersza z indywidualnymi parametrami dla charakterystyk. Polecenie nie może zostać wykonane.';
									|tr = 'Özellikler için ayrı parametreler içeren hiçbir satır vurgulanmaz. Komut çalıştırılamaz.'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ViewModeHierarchy(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.ViewModeHierarchy");
	
	If Items.ControlledInventoryList.CurrentData <> Undefined
		And Not Items.ControlledInventoryList.CurrentData.IsFolder Then
		CurrentGroup = Items.ControlledInventoryList.CurrentData.GroupingProductRestrictions;
	EndIf;
	DisplayMode = ?(ValueIsFilled(CurrentGroup), 2, 1);
	HandlingViewModeChanges();
	
EndProcedure

&AtClient
Procedure ViewModeList(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.ViewModeList");
	
	DisplayMode = 0;
	HandlingViewModeChanges();
	
EndProcedure

&AtClient
Procedure ConfigureTheListOfSupportedStocks_3(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.ConfigureTheListOfSupportedStocks_3");
		
	OpenForm("DataProcessor.SetUpStockReplenishment.Form.ListSettings", ConfigurationFormParameters(),
		ThisForm, UUID,,,
		New CallbackDescription("ConfigureTheListOfSupportedStocks_3Completion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CustomizeStandardSettings(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SetUpStockReplenishment.Form.Form.Command.CustomizeStandardSettings");
		
	SetStandardSettingsAtServer();
	
EndProcedure

#EndRegion

#Region Private

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()
	
	FormattedFields = New Array;
	
	ConditionalAppearanceOfList = ControlledInventoryList.ConditionalAppearance;
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "IsFolder", "IsFolder", True);
	Item.Appearance.SetParameterValue("Show",	False);
	
	FormattedFields.Add("Characteristic");
	FormattedFields.Add("UnitOfMeasure");
	FormattedFields.Add("Warehouse");
	FormattedFields.Add("Recommendation");
	FormattedFields.Add("AverageDailyConsumption");
	FormattedFields.Add("DeviationOfConsumption");
	FormattedFields.Add("SupplyMethod");
	FormattedFields.Add("SupplySource");
	FormattedFields.Add("DeliveryPeriodDays");
	FormattedFields.Add("CoveredPeriod");
	FormattedFields.Add("SupplyScheme");
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, FormattedFields, "IsFolder", True);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<chỉ dành cho các yếu tố>';
																|ru = '<только для элементов>';
																|en = '<only for items>'; fa = '<only for items>';
																|it = '<solo per elementi>';
																|pl = '<tylko dla elementów>';
																|tr = '<sadece öğeler için>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	FormattedFields.Clear();
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "Characteristic", "ItemVariantsAreUsed", False);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<không sử dụng đặc tính>';
																|ru = '<характеристики не используются>';
																|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
																|it = '<le caratteristiche non vengono usate>';
																|pl = '<charakterystyki nie dotyczą>';
																|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "Characteristic", "ItemVariantsAreUsed", True);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<đối với tất cả đặc tính>';
																|ru = '<для всех характеристик>';
																|en = '<for all variants>'; fa = '<برای همه گونه‌ها>';
																|it = '<comune per tutte le caratteristiche>';
																|pl = '<dla wszystkich charakterystyk>';
																|tr = '<tüm varyantlar için>'"));
	
	FormattedFields.Add("AverageDailyConsumption");
	FormattedFields.Add("DeviationOfConsumption");
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, FormattedFields, "ItemVariantsAreUsed", True);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<chỉ dành cho đặc tính>';
																|ru = '<только для характеристик>';
																|en = '<only for variants>'; fa = '<only for variants>';
																|it = '<solo per le caratteristiche>';
																|pl = '<tylko dla właściwości>';
																|tr = '<Yalnızca özellikler için>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	FormattedFields.Clear();
	
	FormattedFields.Add("SafetyStock");
	FormattedFields.Add("ConsumptionRate");
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, FormattedFields,
		"InventoryLevelControl", Enums.InventoryReplenishmentMethods.StockReplenishmentMinMax);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<không sử dụng>';
																|ru = '<не используется>';
																|en = '<not used>'; fa = '<استفاده نمی‌شود>';
																|it = '<non viene utilizzato>';
																|pl = '<nie używa się>';
																|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	FormattedFields.Clear();
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "ConsumptionRate", "InventoryLevelControl",
		Enums.InventoryReplenishmentMethods.StockReplenishmentByStatistics);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<không sử dụng>';
																|ru = '<не используется>';
																|en = '<not used>'; fa = '<استفاده نمی‌شود>';
																|it = '<non viene utilizzato>';
																|pl = '<nie używa się>';
																|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	
	FormattedFields.Add("MinimumInventory");
	FormattedFields.Add("MaximumInventory");
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, FormattedFields,
		"InventoryLevelControl", Enums.InventoryReplenishmentMethods.StockReplenishmentByStatistics);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<tự động tính toán theo thống kê>';
																|ru = '<авторасчет по статистике>';
																|en = '<automatic calculation by statistics>'; fa = '<automatic calculation by statistics>';
																|it = '<calcolo automatico per le statistiche>';
																|pl = '<automatyczne obliczanie statystyk>';
																|tr = '<İstatistiklere göre otomatik hesaplama>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, FormattedFields,
		"InventoryLevelControl", Enums.InventoryReplenishmentMethods.StockReplenishmentByStandard);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<tự động tính toán theo định mức>';
																|ru = '<авторасчет по норме>';
																|en = '<automatic calculation by standard>'; fa = '<automatic calculation by standard>';
																|it = '<calcolo automatico per la normativa>';
																|pl = '<automatyczne wg normy>';
																|tr = '<norma göre otomatik hesaplama>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	FormattedFields.Clear();
	
	FormattedFields.Add("MinimumInventory");
	FormattedFields.Add("MaximumInventory");
	FormattedFields.Add("SafetyStock");
	FormattedFields.Add("ConsumptionRate");
	FormattedFields.Add("OrderFulfillment");
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, FormattedFields,
		"InventoryLevelControl", Enums.InventoryReplenishmentMethods.OrderAgainstOrder);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<không sử dụng>';
																|ru = '<не используется>';
																|en = '<not used>'; fa = '<استفاده نمی‌شود>';
																|it = '<non viene utilizzato>';
																|pl = '<nie używa się>';
																|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	
	FormattedFields.Add("InventoryLevelControl");
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, FormattedFields,
		"GroupingProductRestrictions",, DataCompositionComparisonType.Filled);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.UnavailableTextColor);
	FormattedFields.Clear();
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "GroupingProductRestrictions",
		"IsFolder", False);
	Item.Appearance.SetParameterValue("Show",	False);

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
													|tr = 'Sonraki teslimat tarihine kadar'"));
	
	Item = AddDesignElementWithCondition(ConditionalAppearanceOfList, "SupplyScheme",
		"SupplyScheme",, DataCompositionComparisonType.NotFilled);
	Item.Appearance.SetParameterValue("Text",			NStr("vi = '<chưa chỉ ra>';
																|ru = '<не указана>';
																|en = '<not specified>'; fa = '<مشخص نشده>';
																|it = '<non indicata>';
																|pl = '<nie określono>';
																|tr = '<belirtilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.EmptyTableField);
	
	Item = ConditionalAppearanceOfList.Items.Add();
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InventoryLevelControl");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.InventoryReplenishmentMethods.OrderAgainstOrder;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThisIsTheRecommendationMode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("TextColor",	StyleColors.UnavailableTextColor);
	
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
													|tr = '<herhangi bir sağlayıcı>'"));
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfSourceInputField);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSecurityTypeField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SupplyTypes.ProductionByThirdParty;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSoftwareSourceField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<bên nhận gia công bất kỳ>';
													|ru = '<любые переработчики>';
													|en = '<Any subcontractor>'; fa = '<Any subcontractor>';
													|it = '<qualsiasi subfornitore>';
													|pl = '<dowolni przetwórcy>';
													|tr = '<herhangi bir fason üretici>'"));
	
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
Procedure AddProducts_2Completion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		AddInventorySupportOnServer(ImportedDataAddress, Object.Warehouse, CurrentGroup);
		Items.ControlledInventoryList.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupAfterEnteringName(Description, RecordsArray) Export
	
	If Description = Undefined Then
		Return;
	EndIf;
	MoveToGroupOnServer(RecordsArray, Description, Object.Warehouse);
	If CurGroupIsEmpty(CurrentGroup, Object.Warehouse) Then
		DisplayMode = 1;
		CurrentGroup = Undefined;
		SetRecommendationAndReviewMode();
	Else
		Items.ControlledInventoryList.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInResourceAfterEnteringValue(Number, AdditionalParameters) Export
	
	If Number = Undefined Then
		Return;
	EndIf;
	
	Resource = AdditionalParameters.Resource;
	ErrorMessageText = AdditionalParameters.ErrorMessageText;
	
	RecordsArray = Items.ControlledInventoryList.SelectedRows;
	ProcessedRows_ = FillInResourceOnServer(RecordsArray, Resource, Number);
	
	If ProcessedRows_ > 0 Then
		StringPattern = NStr("vi = 'Các mục đã xử lý: %1.';
							|ru = 'Обработано позиций: %1.';
							|en = 'Items processed: %1.'; fa = 'Items processed: %1.';
							|it = 'Posizioni elaborate: %1.';
							|pl = 'Przetworzone pozycje: %1.';
							|tr = 'İşlenen pozisyonlar:%1 .'");
		TextProcessedLines = StrTemplate(StringPattern, ProcessedRows_);
		ShowUserNotification(NStr("vi = 'Hoàn thành điền';
									|ru = 'Заполнение завершено';
									|en = 'Population is completed'; fa = 'Population is completed';
									|it = 'Compilazione terminata';
									|pl = 'Wypełnianie ukończone';
									|tr = 'Dolum tamamlandı'"), , TextProcessedLines);
		Items.ControlledInventoryList.Refresh();
	Else
		ShowUserNotification(NStr("vi = 'Không điền';
									|ru = 'Заполнение не произведено';
									|en = 'Not filled in'; fa = 'تکمیل نشده';
									|it = 'Compilazione non è effettuata';
									|pl = 'Wypełnianie nie ukończone';
									|tr = 'Dolum yapılmaz'"), , ErrorMessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureTheListOfSupportedStocks_3Completion(AddressOfDataCompositionSettings, AdditionalParameters) Export
	If ValueIsFilled(AddressOfDataCompositionSettings) Then
		UserSettingsComposer.LoadUserSettings(
			GetFromTempStorage(AddressOfDataCompositionSettings));
		ConfigureTheListOfSupportedStocks_3CompletionServer();
	EndIf;
EndProcedure

&AtServer
Procedure ConfigureTheListOfSupportedStocks_3CompletionServer()
	
	ShouldSaveSettings();
	LoadCustomListSettings();
	
EndProcedure

#EndRegion

#Region CalculatingRecommendations

&AtServer
Function CalculateStockMaintenanceRecommendations()
	
	If ReadOnly Then
		
		Items.RecommendationMode.Enabled = False;
		
	ElsIf RoutineTaskIsUsed() Then
		
		RelevanceString = RecommendationRelevance.Add();
		RelevanceString.Warehouse = Object.Warehouse;
		RelevanceString.RecommendationsAreRelevant = True;
		
		RecommendationState = NStr("vi = 'Khuyến nghị có liên quan';
									|ru = 'Рекомендации актуальны';
									|en = 'Recommendations are up-to-date'; fa = 'توصیه‌ها به‌روز هستند';
									|it = 'Le raccomandazioni sono pertinenti';
									|pl = 'Zalecenia aktualne';
									|tr = 'Öneriler günceldir'");
		Items.RecommendationMode.Enabled = True;
		
	Else
		
		RecommendationState = NStr("vi = 'Khuyến nghị đang được tính toán';
									|ru = 'Идет расчет рекомендаций';
									|en = 'Calculating recommendations'; fa = 'Calculating recommendations';
									|it = 'Calcolo delle raccomandazioni in corso';
									|pl = 'Obliczanie zaleceń w toku';
									|tr = 'Öneriler hesaplanıyor'");
		Items.RecommendationMode.Enabled = False;
		
		CalculationResult2 = CalculationOfRecommendationsForMaintainingWarehouseInventoryInBackground();
		
		RelevanceString = RecommendationRelevance.Add();
		RelevanceString.Warehouse = Object.Warehouse;
		
		If CalculationResult2.Status = "Completed2" Then
			RecommendationState = NStr("vi = 'Khuyến nghị tính toán';
										|ru = 'Рекомендации рассчитаны';
										|en = 'Recommendations are calculated'; fa = 'Recommendations are calculated';
										|it = 'Le raccomandazioni sono calcolate';
										|pl = 'Zalecenia zostały obliczone';
										|tr = 'Öneriler hesaplanır'");
			Items.RecommendationMode.Enabled = True;
			RelevanceString.RecommendationsAreRelevant = True;
			RelevanceString.JobID = Undefined;
		Else
			RelevanceString.JobID = CalculationResult2.JobID;
			RelevanceString.BackgroundJobResult = CalculationResult2;
		EndIf;
		
	EndIf;
	
EndFunction

&AtServerNoContext
Function RoutineTaskIsUsed()
	
	SetPrivilegedMode(True);
	Filter = New Structure();
	Filter.Insert("Metadata", Metadata.ScheduledJobs.CalculationOfStockReplenishmentRecommendations);
	FoundJobs = ScheduledJobsServer.FindJobs(Filter);
	
	For Each Job In FoundJobs Do
		If Job.Use Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Procedure ExpectCalculationOfWarehouseInventoryMaintenanceRecommendations()
	
	RelevanceString = GetUpToDateWarehouseRecommendations(RecommendationRelevance, Object.Warehouse);
	
	If RelevanceString <> Undefined And ValueIsFilled(RelevanceString.JobID) Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription(
			"CalculationOfRecommendationsForMaintainingWarehouseStocksNotification", ThisObject);
	
		TimeConsumingOperationsClient.WaitCompletion(
			RelevanceString.BackgroundJobResult, CallbackOnCompletion, IdleParameters);

	EndIf;
	
EndProcedure

&AtClient
Procedure CalculationOfRecommendationsForMaintainingWarehouseStocksNotification(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	If Result.Status = "Completed2"Then
		
		RelevanceString = GetUpToDateWarehouseRecommendations(RecommendationRelevance, Object.Warehouse);
		If RelevanceString <> Undefined Then
			Items.RecommendationMode.Enabled = True;
			RelevanceString.RecommendationsAreRelevant = True;
			RelevanceString.JobID = Undefined;
			RelevanceString.BackgroundJobResult = Undefined;
			RecommendationState = NStr("vi = 'Khuyến nghị có liên quan';
										|ru = 'Рекомендации актуальны';
										|en = 'Recommendations are up-to-date'; fa = 'توصیه‌ها به‌روز هستند';
										|it = 'Le raccomandazioni sono pertinenti';
										|pl = 'Zalecenia aktualne';
										|tr = 'Öneriler günceldir'");
			Items.RecommendationMode.Enabled = True;
			If Items.ControlledInventoryListAverageDailyConsumption.Visible
				Or Items.ControlledInventoryListDeviationOfConsumption.Visible Then
				Items.ControlledInventoryList.Refresh();
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function CalculationOfRecommendationsForMaintainingWarehouseInventoryInBackground(ManualStart1 = False)
	
	JobDescription = NStr("vi = 'Tính toán các đề xuất để duy trì hàng tồn kho: %1';
							|ru = 'Расчет рекомендаций поддержания запасов склада: %1';
							|en = 'Calculate recommendations of warehouse inventory level control: %1'; fa = 'Calculate recommendations of warehouse inventory level control: %1';
							|it = 'Calcolo delle raccomandazioni per mantenere le scorte di magazzino: %1';
							|pl = 'Obliczanie zaleceń dotyczących utrzymywania zapasów magazynu: %1';
							|tr = 'Ambarındaki stok yenileme için önerilerin hesaplanması:%1'");
	JobDescription = StrTemplate(JobDescription, Object.Warehouse);
	
	JobParameters = New Structure;
	JobParameters.Insert("Warehouse", Object.Warehouse);
	If ManualStart1 Then
		JobParameters.Insert("UpdateDate", CurrentSessionDate());
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"SupplyServer.CalculationOfStockMaintenanceRecommendations",
		JobParameters,
		ExecutionParameters);
		
EndFunction

&AtClientAtServerNoContext
Function GetUpToDateWarehouseRecommendations(RecommendationRelevance, Warehouse)
	
	For Each Item In RecommendationRelevance Do
		If Item.Warehouse = Warehouse Then
			Return Item;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region FormSettingsItem

&AtServer
Procedure ConfigureFormByParameters()
	
	// Determining the source of the form call, filling in the details of the selection parameters and the form header.
	Title = NStr("vi = 'Thiết lập tham số đảm bảo';
				|ru = 'Настройка поддержания запасов';
				|en = 'Inventory replenishment parameters'; fa = 'پارامترهای تکمیل موجودی';
				|it = 'Configurazione di mantenimento delle scorte';
				|pl = 'Ustawienia podtrzymania stanów magazynowych';
				|tr = 'Stok yenileme ayarları'");
	Source = Undefined;
	Parameters.Property("Source", Source);
	DisplayMode = 1;
	If Source = "ProductRangeChange" Then
		
		Parameters.Filter.Property("Document", Object.ProductRangeChange);
		
		CommonClientServer.SetDynamicListParameter(ControlledInventoryList,
			"ProductRangeChangeDocument", Parameters.Filter.Document);
		
		Template = NStr("vi = 'Thiết lập tham số đảm bảo (Chứng từ: ""%1"")';
						|ru = 'Настройка поддержания запасов (Документ: ""%1"")';
						|en = 'Inventory replenishment parameters (Document: ""%1"")'; fa = 'Inventory replenishment parameters (Document: ""%1"")';
						|it = 'Configurazione del mantenimento delle scorte (Documento: ""%1"")';
						|pl = 'Ustawianie konserwacji zapasów (Dokument: ""%1"")';
						|tr = 'Stok yenilemeyi ayarlama (Belge: ""%1"")'");
		Title = StrTemplate(Template, Object.ProductRangeChange);
		
		DisplayMode = 0;
		
	ElsIf Source = "ShopStorerooms" Then
		
		FixedFilter = ControlledInventoryList.SettingsComposer.FixedSettings.Filter;
		CommonClientServer.AddCompositionItem(FixedFilter,
			"Warehouse.ShopFloorStockroom", DataCompositionComparisonType.Equal, True,, True,
			DataCompositionSettingsItemViewMode.QuickAccess);
		
		DisplayMode = 0;
		
	ElsIf Source = "Warehouse" Then
		
		Parameters.Filter.Property("Warehouse", Object.Warehouse);
		
	ElsIf Source = "DemandFulfillment" Then
		
		Parameters.Filter.Property("Warehouse", Object.Warehouse);
		
	ElsIf Source = "Products" Then
		
		Parameters.Filter.Property("Products", Object.Products);
		
		FixedFilter = ControlledInventoryList.SettingsComposer.FixedSettings.Filter;
		CommonClientServer.AddCompositionItem(FixedFilter,
			"Products", DataCompositionComparisonType.Equal, Object.Products,, True,
			DataCompositionSettingsItemViewMode.QuickAccess);
		
		DisplayMode = 0;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureFormByRightsAndFunctionalOptions()
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		Items.ControlledInventoryListWarehouse.Visible = False;
		Items.Warehouse.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseItemVariants") Then
		Items.ControlledInventoryListCharacteristic.Visible		= False;
	EndIf;
	
	ReadOnly = Not SupplyServer.WriteAccessRightsForMethodOrMethod().ProductRestrictions;
	If ReadOnly Then
		Items.RecommendationState.Visible	= False;
		Items.AddProductCommands.Visible		= False;
		Items.CommandsGrouping.Visible		= False;
		Items.FillInCommands_2.Visible			= False;
		Items.CalculateRecommendationsAndConsumptionStatistics.Visible		= False;
		Items.OpenSettingUpTheCalculationOfAverageDailyConsumption.Visible	= False;
		Items.ControlledInventoryListContextMenuAddedFeature.Visible	= False;
		Items.ControlledInventoryListContextMenuDeleteCharacteristics.Visible	= False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAccessibilityOfAddButtons(Form, Available)
	
	Form.Items.AddProductCommands.Enabled							= Available;
	Form.Items.RecommendationMode.Enabled							= Available;
	Form.Items.CalculateRecommendationsAndConsumptionStatistics.Enabled	= Available;
	If Not Available Then
		Form.RecommendationState = NStr("vi = 'Đề xuất và thêm sản phẩm chỉ có sẵn cho một lựa chọn nhất định theo kho';
										|ru = 'Рекомендации и добавление товаров доступны только при заданном отборе по складу';
										|en = 'Recommendations and goods adding are available only if the filter by warehouse is set'; fa = 'Recommendations and goods adding are available only if the filter by warehouse is set';
										|it = 'Le raccomandazioni e l''aggiunta delle merci sono disponibili solo per la selezione per magazzino impostata';
										|pl = 'Zalecenia i dodawanie towarów są dostępne tylko dla danego wyboru według magazynu';
										|tr = 'Öneriler ve ürün ekleme, yalnızca ambara göre belirli bir seçimle kullanılabilir'");
	EndIf;
	
EndProcedure

#EndRegion

#Region Commands_Grouping_Service

&AtServerNoContext
Function NameOfNewDefaultGrouping(PropertiesOfSelectedRows)
	
	Return Catalogs.GoodsRestrictionGrouping.NameOfNewDefaultGrouping(PropertiesOfSelectedRows);
	
EndFunction

&AtServerNoContext
Procedure MoveToGroupOnServer(RecordsArray, Group, Warehouse)
	
	BeginTransaction();
	Try
		
		If TypeOf(Group) = Type("String") Then
			ObjectGrouping = Catalogs.GoodsRestrictionGrouping.CreateItem();
			ObjectGrouping.Description = Group;
			ObjectGrouping.Write();
			GroupingKey = InformationRegisters.ProductRestrictions.KeyForRecordingDimensions(ObjectGrouping.Ref);
		Else
			GroupingKey = InformationRegisters.ProductRestrictions.KeyForRecordingDimensions(Group);
		EndIf;
		
		RecordsKeys = New Array;
		DimensionsToDelete = New Array;
		For Each RegisterRecordKey In RecordsArray Do
			
			If RegisterRecordKey.GroupingProductRestrictions = GroupingKey.GroupingProductRestrictions Then
				Continue;
			EndIf;
			
			If Not ValueIsFilled(RegisterRecordKey.Products) Then
				KeyForRecordingDimensions = InformationRegisters.ProductRestrictions.KeyForRecordingDimensions(RegisterRecordKey.GroupingProductRestrictions);
				DimensionsToDelete.Add(RegisterRecordKey.GroupingProductRestrictions);
				CommonClientServer.SupplementArray(RecordsKeys,
					InformationRegisters.ProductRestrictions.KeysForProductEntriesInDimension(RegisterRecordKey.GroupingProductRestrictions, Warehouse));
				Continue;
			ElsIf ValueIsFilled(RegisterRecordKey.Characteristic) Then
				ProductRecordKey = InformationRegisters.ProductRestrictions.FeatureRecordingKey();
			Else
				ProductRecordKey = InformationRegisters.ProductRestrictions.ProductEntryKey();
			EndIf;
			FillPropertyValues(ProductRecordKey, RegisterRecordKey);
			RecordsKeys.Add(ProductRecordKey);
			
		EndDo;
		
		InformationRegisters.ProductRestrictions.AddInventoryMaintenanceByGrouping(RecordsKeys, GroupingKey);
		
		Catalogs.GoodsRestrictionGrouping.DeleteUnusedDimensions(DimensionsToDelete);
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("vi = 'Nhóm cài đặt bảo trì hàng tồn kho';
							|ru = 'Группировка настроек поддержания запаса';
							|en = 'Grouping of inventory level control settings'; fa = 'Grouping of inventory level control settings';
							|it = 'Raggruppamento delle impostazioni di mantenimento delle scorte';
							|pl = 'Grupowanie ustawień utrzymania zapasów';
							|tr = 'Stok yenileme ayarlarını gruplama'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region Commands___Service

&AtServerNoContext
Procedure FillInCollateralMethodOnServer(RecordsArray, ParametersOfInventoryLevelControl)
	
	RecordsKeys = New Array;
	For Each RegisterRecordKey In RecordsArray Do
		If Not ValueIsFilled(RegisterRecordKey.Products) Then
			ParameterEntryKey = InformationRegisters.ProductRestrictions.KeyForRecordingDimensions();
		ElsIf ValueIsFilled(RegisterRecordKey.Characteristic) Then
			ParameterEntryKey = InformationRegisters.ProductRestrictions.FeatureRecordingKey();
		Else
			ParameterEntryKey = InformationRegisters.ProductRestrictions.ProductEntryKey();
		EndIf;
		FillPropertyValues(ParameterEntryKey, RegisterRecordKey);
		RecordsKeys.Add(ParameterEntryKey);
	EndDo;
	
	StrategyOfProcurement = ParametersOfInventoryLevelControl.InventoryReplenishmentMethod;
	If StrategyOfProcurement = 
		PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentMinMax") Then
		WriteParameters = InformationRegisters.ProductRestrictions.ParametersMinMax();
		FillPropertyValues(WriteParameters, ParametersOfInventoryLevelControl);
		InformationRegisters.ProductRestrictions.AddStockMaintenanceMinMax(RecordsKeys, WriteParameters);
	ElsIf StrategyOfProcurement = 
		PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentByStandard") Then
		WriteParameters = InformationRegisters.ProductRestrictions.ParametersCalculationByNorm();
		FillPropertyValues(WriteParameters, ParametersOfInventoryLevelControl);
		InformationRegisters.ProductRestrictions.AddStockMaintenanceRateCalculation(RecordsKeys, WriteParameters);
	ElsIf StrategyOfProcurement = 
		PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentByStatistics") Then
		WriteParameters = InformationRegisters.ProductRestrictions.ParametersCalculationBasedOnStatistics();
		FillPropertyValues(WriteParameters, ParametersOfInventoryLevelControl);
		InformationRegisters.ProductRestrictions.AddStockMaintenanceCalculationByStatistics(RecordsKeys, WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInResource(Resource)
	Var ResourceValue;
	
	TitleOfValueEntryWindow =
		?(Resource = "MinimumInventoryQuantity",  NStr("vi = 'Hãy nhập hàng tồn kho tối thiểu';
														|ru = 'Введите минимальный запас';
														|en = 'Enter min inventory'; fa = 'Enter min inventory';
														|it = 'Inserire scorte minime';
														|pl = 'Wprowadź minimalny zapas';
														|tr = 'Minimum stoku girin'"),
		?(Resource = "MaximumInventoryAmount", NStr("vi = 'Hãy nhập hàng tồn kho tối đa';
													|ru = 'Введите максимальный запас';
													|en = 'Enter max inventory'; fa = 'Enter max inventory';
													|it = 'Inserire scorte massime';
													|pl = 'Wprowadź maksymalny zapas';
													|tr = 'Maksimum marjı girin'"),
		?(Resource = "SafetyStockQuantity",    NStr("vi = 'Hãy nhập số dư đảm bảo hàng tồn kho';
													|ru = 'Введите страховой запас';
													|en = 'Enter safety stock'; fa = 'Enter safety stock';
													|it = 'Inserire scorte di sicurezza';
													|pl = 'Wprowadź zapasy bezpieczeństwa';
													|tr = 'Güvenlik stoku girin'"),
		?(Resource = "ConsumptionRate",             NStr("vi = 'Hãy nhập định mức sử dụng trong ngày';
														|ru = 'Введите норму потребления в день';
														|en = 'Enter daily consumption rate'; fa = 'Enter daily consumption rate';
														|it = 'Inserire la norma del consumo giornaliero';
														|pl = 'Wprowadź stawkę zużycia na dzień';
														|tr = 'Günlük tüketim oranını girin'"),
			NStr("vi = 'Chọn đảm bảo đơn hàng';
				|ru = 'Выберите обеспечение заказов';
				|en = 'Select order fulfillment'; fa = 'Select order fulfillment';
				|it = 'Inserire approvvigionamento degli ordini';
				|pl = 'Wybierz zabezpieczenia zamówienia';
				|tr = 'Sipariş karşılama seçin'")))));
	
	ErrorMessageText =
		?(Resource = "MinimumInventoryQuantity", NStr("vi = 'Chỉ điền tồn kho tối thiểu cho các dòng có duy trì mức tồn kho ""Min - max"".';
														|ru = 'Заполнение минимального запаса возможно только для строк с поддержанием запаса ""Min - max"".';
														|en = 'Filling in minimum inventory is only possible for lines with the ""Min - max"" inventory level control.'; fa = 'Filling in minimum inventory is only possible for lines with the ""Min - max"" inventory level control.';
														|it = 'Compilare le scorte minime è possibile solo per le righe con mantenimento delle scorte ""Min - max"".';
														|pl = 'Napełnianie zapasów minimalnych jest możliwe tylko dla rzędów z utrzymaniem zapasów ""Min - max"".';
														|tr = 'Minimum stokun doldurulması sadece ""Min - max"" stok seviye kontrolü satırları için mümkündür.'"),
		?(Resource = "MaximumInventoryAmount", NStr("vi = 'Việc điền vào lề tối đa chỉ có thể cho các dòng có duy trì lề ""Tối thiểu - tối đa"".';
													|ru = 'Заполнение максимального запаса возможно только для строк с поддержанием запаса ""Min - max"".';
													|en = 'Filling in maximum inventory is only possible for lines with the ""Min - max"" inventory level control.'; fa = 'Filling in maximum inventory is only possible for lines with the ""Min - max"" inventory level control.';
													|it = 'Compilare le scorte massime è possibile solo per le righe con mantenimento delle scorte ""Min - max"".';
													|pl = 'Wypełnienie maksymalnego marginesu jest możliwe tylko dla wierszy z zachowaniem marginesu ""Min - max."".';
													|tr = 'Maksimum stokun doldurulması sadece ""Min - max"" stok seviye kontrolü satırları için mümkündür.'"),
		?(Resource = "SafetyStockQuantity", NStr("vi = 'Điền vào kho bảo quản chỉ có thể áp dụng cho các dòng có bảo trì hàng tồn kho ""Tính toán theo định mức"", ""Tính toán theo thống kê"".';
												|ru = 'Заполнение страхового запаса возможно только для строк с поддержанием запаса ""Расчет по норме"", ""Расчет по статистике"".';
												|en = 'You can fill in safety stock only in lines with the ""Fixed consumption forecasting"" and ""Rolling consumption forecasting"" inventory level control.'; fa = 'You can fill in safety stock only in lines with the ""Fixed consumption forecasting"" and ""Rolling consumption forecasting"" inventory level control.';
												|it = 'Compilare le scorte di sicurezza è possibile solo per le righe con il mantenimento delle scorte ""Calcolo secondo la norma"", ""Calcolo secondo le statistiche"".';
												|pl = 'Wypełnienie zapasów bezpieczeństwa jest możliwe tylko dla rzędów z utrzymaniem zapasów ""Obliczanie zgodnie z normą"", ""Obliczanie według statystyk"".';
												|tr = 'Güvenlik stokunun doldurulması sadece ""Normlara göre hesaplama"", ""İstatistiklere göre hesaplama"" gibi stok yenileme satırları için mümkündür.'"),
		?(Resource = "ConsumptionRate", NStr("vi = 'Việc điền vào tỷ lệ tiêu thụ chỉ có thể đối với các dòng có bảo trì hàng tồn kho ""Tính toán theo định mức.""';
											|ru = 'Заполнение нормы потребления возможно только для строк с поддержанием запаса ""Расчет по норме"".';
											|en = 'You can fill in the consumption rate only in lines with the ""Fixed consumption forecasting"" inventory level control.'; fa = 'You can fill in the consumption rate only in lines with the ""Fixed consumption forecasting"" inventory level control.';
											|it = 'Compilare le scorte di consumo è possibile solo per le righe con il mantenimento delle scorte ""Calcolo secondo la norma"".';
											|pl = 'Wypełnienie wskaźnika zużycia możliwe jest tylko dla rzędów z utrzymaniem stanu ""Obliczanie na poziomie"".';
											|tr = 'Tüketim oranının doldurulması sadece ""Orana göre hesaplama"" stok yenileme satırları için mümkündür .'"), 
		NStr("vi = 'Điền đảm bảo đơn hàng chỉ có thể cho các dòng hàng tồn kho.';
			|ru = 'Заполнение обеспечения заказа возможно только для строк с поддержанием запаса.';
			|en = 'You can fill in order fulfillment only in lines with inventory level control.'; fa = 'You can fill in order fulfillment only in lines with inventory level control.';
			|it = 'Compilare approvvigionamento dell''ordine è possibile solo per le righe con il mantenimento delle scorte.';
			|pl = 'Zabezpieczenie zamówienia wypełnienia jest możliwe tylko w przypadku linii magazynowych.';
			|tr = 'Sipariş teminatının doldurulması sadece stok yenileme satırları için mümkündür.'")))));
	
	TextResourceFilledIn =
		?(Resource = "MinimumInventoryQuantity",  NStr("vi = 'Đã điền hàng tồn kho tối thiểu.';
														|ru = 'Минимальный запас заполнен.';
														|en = 'Min inventory is filled in.'; fa = 'Min inventory is filled in.';
														|it = 'Le scorte minime sono compilate.';
														|pl = 'Minimalny zapas jest pełny.';
														|tr = 'Minimum stok doldurulur.'"),
		?(Resource = "MaximumInventoryAmount", NStr("vi = 'Đã điền hàng tồn kho tối đa';
													|ru = 'Максимальный запас заполнен.';
													|en = 'Max inventory is filled in.'; fa = 'Max inventory is filled in.';
													|it = 'Le scorte massime sono compilate.';
													|pl = 'Maksymalny zapas jest pełny.';
													|tr = 'Maksimum stok dolu.'"),
		?(Resource = "SafetyStockQuantity",    NStr("vi = 'Đã điền hàng tồn kho dự phòng';
													|ru = 'Страховой запас заполнен.';
													|en = 'Safety stock is filled in.'; fa = 'Safety stock is filled in.';
													|it = 'Le scorte di sicurezza sono compilate.';
													|pl = 'Zapasy bezpieczeństwa są pełne.';
													|tr = 'Güvenlik stoku dolu.'"),
		?(Resource = "ConsumptionRate",             NStr("vi = 'Đã điền định mức tiêu dùng.';
														|ru = 'Норма потребления заполнена.';
														|en = 'Consumption rate is filled in.'; fa = 'Consumption rate is filled in.';
														|it = 'La norma di consumo è compilata.';
														|pl = 'Stopień zużycia jest pełny.';
														|tr = 'Tüketim oranı doldurulur.'"),
			NStr("vi = 'Đảm bảo đơn hàng được điền.';
				|ru = 'Обеспечение заказов заполнено.';
				|en = 'Order fulfillment is filled in.'; fa = 'Order fulfillment is filled in.';
				|it = 'Approvvigionamento degli ordini è compilato.';
				|pl = 'Zabezpieczenie zamówień wypełniono.';
				|tr = 'Sipariş karşılama dolduruldu.'")))));
	
	AdditionalParameters = New Structure("Resource, TextResourceFilledIn, ErrorMessageText");
	AdditionalParameters.Resource                 = Resource;
	AdditionalParameters.TextResourceFilledIn    = TextResourceFilledIn;
	AdditionalParameters.ErrorMessageText = ErrorMessageText;
	
	CallbackDescription = New CallbackDescription("FillInResourceAfterEnteringValue", ThisObject, AdditionalParameters);
	
	If Resource = "OrderFulfillmentWithinInventoryReplenishment" Then
		ShowInputValue(CallbackDescription, ResourceValue, TitleOfValueEntryWindow,
			New TypeDescription("EnumRef.OrderFulfillmentWithinInventoryReplenishment"));
	Else
		ShowInputNumber(CallbackDescription, ResourceValue, TitleOfValueEntryWindow, 15, 3);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function FillInResourceOnServer(RecordsArray, ResourceName, Value)
	
	RecordsKeys = New Array;
	For Each RegisterRecordKey In RecordsArray Do
		If Not ValueIsFilled(RegisterRecordKey.Products) Then
			ParameterEntryKey = InformationRegisters.ProductRestrictions.KeyForRecordingDimensions();
		ElsIf ValueIsFilled(RegisterRecordKey.Characteristic) Then
			ParameterEntryKey = InformationRegisters.ProductRestrictions.FeatureRecordingKey();
		Else
			ParameterEntryKey = InformationRegisters.ProductRestrictions.ProductEntryKey();
		EndIf;
		FillPropertyValues(ParameterEntryKey, RegisterRecordKey);
		RecordsKeys.Add(ParameterEntryKey);
	EndDo;
	
	Return InformationRegisters.ProductRestrictions.FillInStockMaintenanceParameter(RecordsKeys, ResourceName, Value);
	
EndFunction

#EndRegion

#Region ListSettings

&AtServer
Procedure ShouldSaveSettings()
	
	Settings = New Structure();
	Settings.Insert("UserSettings", UserSettingsComposer.UserSettings);
	
	Common.CommonSettingsStorageSave("DataProcessor.SetUpStockReplenishment",
		"Main" + Source, Settings);
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.SetUpStockReplenishment",
		"Main" + Source);
	
	If TypeOf(SettingsValue) = Type("Structure") Then
		
		UserSettingsComposer.LoadUserSettings(SettingsValue.UserSettings);
		UserSettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeUserSettings()
	
	DCS                               = New DataCompositionSchema;
	DataSource                    = DCS.DataSources.Add();
	DataSource.Name                = "DataSource";
	DataSource.DataSourceType = "Local";
	
	DataSet                 = DCS.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Name             = "List";
	DataSet.Query          = ControlledInventoryList.QueryText;
	DataSet.DataSource  = "DataSource";
	DataSet.AutoFillAvailableFields = False;
	
	AddressOfDataCompositionSchema = PutToTempStorage(DCS, UUID);
	
	ControlledInventoryList.SettingsComposer.Settings.Filter.UserSettingID				= "Filter";
	ControlledInventoryList.SettingsComposer.Settings.Order.UserSettingID			= "";
	ControlledInventoryList.SettingsComposer.Settings.ConditionalAppearance.UserSettingID	= "ConditionalAppearance";
	ControlledInventoryList.SettingsComposer.Settings.Structure.UserSettingID			= "";
	
	UserSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema));
	UserSettingsComposer.Settings.Filter.UserSettingID				= "Filter";
	UserSettingsComposer.Settings.Order.UserSettingID			= "Order";
	UserSettingsComposer.Settings.ConditionalAppearance.UserSettingID	= "ConditionalAppearance";
	UserSettingsComposer.Settings.Structure.UserSettingID			= "";
	
	SetStandardCustomListSettings();
	
EndProcedure

&AtServer
Procedure SynchronizeComposerSettings()
	
	SourceElements = GetLayoutObjectByType(Type("DataCompositionOrder")).Items;
	UserSettingsComposer.LoadUserSettings(
		ControlledInventoryList.SettingsComposer.UserSettings);
	
	FilterItems1 = GetLayoutObjectByType(Type("DataCompositionFilter")).Items;
	If FilterItems1.Count() > 0
		And FilterItems1[0].UserSettingID = "AddedGroupOr" Then
	
		OrGroup = FilterItems1[0];
		AndGroup = OrGroup.Items[0];
		AndGroup.Items.Delete(0);
		
		FillInSettingsProperties(FilterItems1, AndGroup.Items);
		FilterItems1.Delete(OrGroup);
		
	EndIf;
	
	ReceiverElements = GetLayoutObjectByType(Type("DataCompositionOrder")).Items;
	FillInSettingsProperties(ReceiverElements, SourceElements);
	
EndProcedure

&AtServer
Function ConfigurationFormParameters()
	
	SynchronizeComposerSettings();
	
	AddressForConfiguringDataLayout = PutToTempStorage(
		UserSettingsComposer.UserSettings, UUID);
	
	Return New Structure("AddressOfDataCompositionSchema, AddressOfDataCompositionSettings",
		AddressOfDataCompositionSchema, AddressForConfiguringDataLayout);
	
EndFunction

&AtServer
Procedure SetStandardSettingsAtServer()
	
	SetStandardCustomListSettings();
	LoadCustomListSettings();
	
EndProcedure

&AtServer
Procedure SetStandardCustomListSettings()
	
	For Each SettingItem In UserSettingsComposer.UserSettings.Items Do
		If TypeOf(SettingItem) = Type("DataCompositionSettingStructure") Then
			SettingItem.Structure.Clear();
		Else
			SettingItem.Items.Clear();
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure LoadCustomListSettings()
	
	ControlledInventoryList.SettingsComposer.LoadUserSettings(
		UserSettingsComposer.UserSettings);
	
	FilterItems1 = GetLayoutObjectByType(Type("DataCompositionFilter")).Items;
	If FilterItems1.Count() > 0 And DisplayMode <> 0 Then
		
		For Each Item In ControlledInventoryList.SettingsComposer.UserSettings.Items Do
			If TypeOf(Item) = Type("DataCompositionFilter") Then
				UserSelection_ = Item;
				UserSelection_.Items.Clear();
				
				OrGroup = UserSelection_.Items.Add(Type("DataCompositionFilterItemGroup"));
				OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
				OrGroup.Use = True;
				OrGroup.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
				OrGroup.UserSettingID = "AddedGroupOr";
				
				AndGroup = OrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
				AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
				AndGroup.ViewMode = DataCompositionSettingsItemViewMode.Normal;
				AndGroup.Use = True;
				
				IsFolder = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
				IsFolder.LeftValue = New DataCompositionField("IsFolder");
				IsFolder.ComparisonType = DataCompositionComparisonType.Equal;
				IsFolder.RightValue = True;
				
				TrueField = AndGroup.Items.Insert(0, Type("DataCompositionFilterItem"));
				TrueField.LeftValue = New DataCompositionField("TrueField");
				TrueField.ComparisonType = DataCompositionComparisonType.Equal;
				TrueField.RightValue = True;
				
				FillInSettingsProperties(AndGroup.Items, FilterItems1);
				Continue;
			EndIf;
		EndDo;
		
	EndIf;
	
	SourceElements = GetLayoutObjectByType(Type("DataCompositionOrder")).Items;
	ReceiverElements = ControlledInventoryList.Order.Items;
	ReceiverElements.Clear();
	
	OrderItem = ReceiverElements.Insert(0, Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("IsFolder");
	OrderItem.OrderType	= DataCompositionSortDirection.Desc;
	OrderItem.ViewMode		= DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use		= True;
	
	FillInSettingsProperties(ReceiverElements, SourceElements);
	
	Items.ControlledInventoryList.CreateUserSettingsFormItems(
		Items.GroupOfUserSettingsForTheListOfSupportedStocks);
	
EndProcedure

&AtServer
Function GetLayoutObjectByType(ObjectType)
	
	For Each SettingItem In UserSettingsComposer.UserSettings.Items Do
		If TypeOf(SettingItem) = ObjectType Then
			Return SettingItem;
		EndIf;
	EndDo;
	
EndFunction

// Parameters:
//   ElementsReceiver - DataCompositionFilterItemCollection, DataCompositionOrderItemCollection - Elements which need to be filled.
//   SourceElements_ - DataCompositionFilterItemCollection, DataCompositionOrderItemCollection - The elements that need to be filled.
&AtServerNoContext
Procedure FillInSettingsProperties(ElementsReceiver,SourceElements_)
	For Each SourceItem In SourceElements_ Do
		SourceType = TypeOf(SourceItem);
		DestinationItem = ElementsReceiver.Add(SourceType);
		FillPropertyValues(DestinationItem, SourceItem);
		If SourceType=Type("DataCompositionFilterItemGroup") Then
			FillInSettingsProperties(DestinationItem.Items, SourceItem.Items);
		EndIf;
	EndDo;
EndProcedure

#EndRegion

&AtClient
Function ThereAreHighlightedLines()
	
	If Items.ControlledInventoryList.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không một dòng nào được chọn. Thực thi lệnh là không thể.';
								|ru = 'Не выделено ни одной строки. Выполнение команды невозможно.';
								|en = 'No lines are selected. Cannot execute the command.'; fa = 'No lines are selected. Cannot execute the command.';
								|it = 'Nessuna riga selezionata. Il comando non può essere eseguito.';
								|pl = 'Nie wybrano ani jednego wierszu. Wykonanie polecenia jest niemożliwe.';
								|tr = 'Herhangi bir satır belirtilmedi. Komutun gerçekleştirilmesi mümkün değildir.'"));
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

&AtServerNoContext
Function CurGroupIsEmpty(CurrentGroup, FilterByWarehouse)
	
	If CurrentGroup <> Undefined Then
		
		Query = New Query;
		Query.Text = 
			"SELECT TOP 1
			|	ProductRestrictions.Products
			|FROM
			|	InformationRegister.ProductRestrictions AS ProductRestrictions
			|WHERE
			|	ProductRestrictions.GroupingProductRestrictions = &GroupingProductRestrictions";
		
		Query.SetParameter("GroupingProductRestrictions", CurrentGroup);
		If Not FilterByWarehouse.IsEmpty() Then
			Query.Text = Query.Text + " AND ProductRestrictions.Warehouse = &Warehouse";
			Query.SetParameter("Warehouse", FilterByWarehouse);
		EndIf;
		
		Return Query.Execute().IsEmpty();
		
	Else
		
		Return False;
		
	EndIf;

EndFunction

&AtServer
Function WarehouseWhenChangedOnServer()
	
	ExpectRecommendationsToBeCalculated = False;
	
	If ValueIsFilled(Object.Warehouse) Then
		
		If CurGroupIsEmpty(CurrentGroup, Object.Warehouse) Then
			DisplayMode = 1;
			CurrentGroup = Undefined;
		EndIf;
		
		SetAccessibilityOfAddButtons(ThisForm, True);
		
		RelevanceString = GetUpToDateWarehouseRecommendations(RecommendationRelevance, Object.Warehouse);
		
		If RelevanceString = Undefined Then
			CalculateStockMaintenanceRecommendations();
			ExpectRecommendationsToBeCalculated = True;
		ElsIf RelevanceString.RecommendationsAreRelevant Then
			RecommendationState = NStr("vi = 'Khuyến nghị có liên quan';
										|ru = 'Рекомендации актуальны';
										|en = 'Recommendations are up-to-date'; fa = 'توصیه‌ها به‌روز هستند';
										|it = 'Le raccomandazioni sono pertinenti';
										|pl = 'Zalecenia aktualne';
										|tr = 'Öneriler günceldir'");
			Items.RecommendationMode.Enabled = True;
		Else
			RecommendationState = NStr("vi = 'Khuyến nghị đang được tính toán';
										|ru = 'Идет расчет рекомендаций';
										|en = 'Calculating recommendations'; fa = 'Calculating recommendations';
										|it = 'Calcolo delle raccomandazioni in corso';
										|pl = 'Obliczanie zaleceń w toku';
										|tr = 'Öneriler hesaplanıyor'");
			Items.RecommendationMode.Enabled = False;
			ExpectRecommendationsToBeCalculated = True;
		EndIf;
		
	Else
		SetAccessibilityOfAddButtons(ThisForm, False);
	EndIf;
	
	SetRecommendationAndReviewMode();
	
	Return ExpectRecommendationsToBeCalculated;
	
EndFunction

&AtServer
Procedure HandlingViewModeChanges()
	SetRecommendationAndReviewMode();
	SynchronizeComposerSettings();
	LoadCustomListSettings();
EndProcedure

&AtClient
Procedure OpenParameterEditingForm(Data)
	NeedKey = New Structure();
	If Data.IsFolder Then
		NeedKey.Insert("Products", PredefinedValue("Catalog.Products.EmptyRef"));
		NeedKey.Insert("GroupingProductRestrictions", Data.GroupingProductRestrictions);
	Else
		NeedKey.Insert("Products", Data.Products);
	EndIf;
	NeedKey.Insert("Characteristic",	Data.Characteristic);
	NeedKey.Insert("Warehouse",			Data.Warehouse);
	NeedKey.Insert("ThisIsWork",		False);
	
	FormParameters = New Structure("NeedKey, CalculateStatistics, OpeningMode",
	NeedKey, False, "ParametersOnly");
	
	OpenForm("DataProcessor.DemandFulfillment.Form.EditFormSupplyParameters", FormParameters, ThisForm,
	UUID);
EndProcedure

&AtServer
Procedure SetRecommendationAndReviewMode();
	
	If Not Items.RecommendationMode.Enabled Then
		RecommendationMode = 0;
	EndIf;
	
	Items.ControlledInventoryListRecommendation.Visible				= RecommendationMode = 1;
	Items.ControlledInventoryListAverageDailyConsumption.Visible	= RecommendationMode = 1;
	Items.ControlledInventoryListDeviationOfConsumption.Visible		= RecommendationMode = 1;
	
	Fixing = ?(RecommendationMode = 1, FixingInTable.Left, FixingInTable.None);
	Items.ControlledInventoryListRecommendation.FixingInTable = Fixing;
	
	NewQuery = RequestAListOfSupportedStocks;
	If RecommendationMode = 0 Then
		NewQuery = StrReplace(NewQuery, "&RecommendationMode",
			"ProductRestrictionsOverridable.ThisIsAValidParameter");
	Else
		NewQuery = StrReplace(NewQuery, "&RecommendationMode",
			"ProductRestrictionsOverridable.ThereIsRecommendationForChange");
	EndIf;
	
	Items.ListOfSupportedStocksViewModeList.Check	= DisplayMode = 0;
	Items.ListOfSupportedStocksViewModeHierarchy.Check	= DisplayMode <> 0;
	Items.ControlledInventoryListIsFolder.Visible				= DisplayMode = 2;
	
	If DisplayMode = 0 Then
		If ValueIsFilled(Object.Warehouse) Then
			NewQuery = StrReplace(NewQuery, "&DisplayMode",
			"ProductRestrictionsOverridable.Warehouse = &Warehouse");
		Else
			NewQuery = StrReplace(NewQuery, "&DisplayMode",
			"(ProductRestrictionsOverridable.Products <> VALUE(Catalog.Products.EmptyRef)
			|	OR ProductRestrictionsOverridable.Warehouse = &Warehouse)");
		EndIf;
		CurrentGroup = Undefined;
	ElsIf DisplayMode = 1 Then
		If ValueIsFilled(Object.Warehouse) Then
			NewQuery = StrReplace(NewQuery, "&DisplayMode",
			"(ProductRestrictionsOverridable.GroupingProductRestrictions = VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)
			|	OR ProductRestrictionsOverridable.Products = VALUE(Catalog.Products.EmptyRef))
			|	AND ProductRestrictionsOverridable.Warehouse = &Warehouse");
		Else
			NewQuery = StrReplace(NewQuery, "&DisplayMode",
			"(ProductRestrictionsOverridable.GroupingProductRestrictions = VALUE(Catalog.GoodsRestrictionGrouping.EmptyRef)
			|	OR ProductRestrictionsOverridable.Warehouse = &Warehouse)");
		EndIf;
	Else
		If ValueIsFilled(Object.Warehouse) Then
			NewQuery = StrReplace(NewQuery, "&DisplayMode",
			"ProductRestrictionsOverridable.GroupingProductRestrictions = &GroupingProductRestrictions
			|	AND ProductRestrictionsOverridable.Warehouse = &Warehouse");
		Else
			NewQuery = StrReplace(NewQuery, "&DisplayMode",
			"ProductRestrictionsOverridable.GroupingProductRestrictions = &GroupingProductRestrictions
			|	AND (ProductRestrictionsOverridable.Products <> VALUE(Catalog.Products.EmptyRef)
			|		OR ProductRestrictionsOverridable.Warehouse = &Warehouse)");
		EndIf;
	EndIf;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, ControlledInventoryList);
	ListProperties.QueryText = NewQuery;
	Common.SetDynamicListProperties(Items.ControlledInventoryList, ListProperties);
	
	CommonClientServer.SetDynamicListParameter(
		ControlledInventoryList,
		"ThisIsTheRecommendationMode",
		RecommendationMode = 1);
	
	CommonClientServer.SetDynamicListParameter(
		ControlledInventoryList,
		"ViewMode",
		DisplayMode);
		
	CommonClientServer.SetDynamicListParameter(
		ControlledInventoryList,
		"Warehouse",
		Object.Warehouse);
	
	If DisplayMode = 2 Then
		CommonClientServer.SetDynamicListParameter(
			ControlledInventoryList,
			"GroupingProductRestrictions",
			CurrentGroup);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure AddMaintainingStockOfCharacteristicsOnServer(Products, Characteristics, Warehouse, Group)
	
	RecordsKeys = New Array;
	For Each Characteristic In Characteristics Do
		RecordKey = InformationRegisters.ProductRestrictions.FeatureRecordingKey();
		RecordKey.Products = Products;
		RecordKey.Characteristic = Characteristic;
		RecordKey.Warehouse = Warehouse;
		RecordsKeys.Add(RecordKey);
	EndDo;
	
	If ValueIsFilled(Group) Then
		InformationRegisters.ProductRestrictions.AddInventoryMaintenanceByGrouping(RecordsKeys,
			InformationRegisters.ProductRestrictions.KeyForRecordingDimensions(Group));
	Else
		InformationRegisters.ProductRestrictions.AddStockMaintenanceMinMax(RecordsKeys);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure AddProductInventoryMaintenanceOnServer(Products, Warehouse, Group)
	
	RecordKey = InformationRegisters.ProductRestrictions.ProductEntryKey();
	RecordKey.Products = Products;
	RecordKey.Warehouse = Warehouse;
	If ValueIsFilled(Group) Then
		InformationRegisters.ProductRestrictions.AddInventoryMaintenanceByGrouping(RecordKey,
			InformationRegisters.ProductRestrictions.KeyForRecordingDimensions(Group));
	Else
		InformationRegisters.ProductRestrictions.AddStockMaintenanceMinMax(RecordKey);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure RemoveMaintainingStockOnServer(RecordsArray, Warehouse)
	
	BeginTransaction();
	Try
		
		RecordsKeys = New Array;
		DimensionsToDelete = New Array;
		For Each RegisterRecordKey In RecordsArray Do
			If Not ValueIsFilled(RegisterRecordKey.Products) Then
				DimensionsToDelete.Add(RegisterRecordKey.GroupingProductRestrictions);
				If ValueIsFilled(Warehouse) Then
					CommonClientServer.SupplementArray(RecordsKeys,
						InformationRegisters.ProductRestrictions.KeysForProductEntriesInDimension(RegisterRecordKey.GroupingProductRestrictions, Warehouse));
					Continue;
				Else
					ParameterEntryKey = InformationRegisters.ProductRestrictions.KeyForRecordingDimensions();
				EndIf;
			ElsIf ValueIsFilled(RegisterRecordKey.Characteristic) Then
				ParameterEntryKey = InformationRegisters.ProductRestrictions.FeatureRecordingKey();
			Else
				ParameterEntryKey = InformationRegisters.ProductRestrictions.ProductEntryKey();
			EndIf;
			FillPropertyValues(ParameterEntryKey, RegisterRecordKey);
			RecordsKeys.Add(ParameterEntryKey);
		EndDo;
		
		InformationRegisters.ProductRestrictions.RemoveStockMaintenance(RecordsKeys);
		Catalogs.GoodsRestrictionGrouping.DeleteUnusedDimensions(DimensionsToDelete);
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("vi = 'Loại bỏ hàng tồn kho được hỗ trợ';
							|ru = 'Удаление поддерживаемых запасов';
							|en = 'Delete controlled inventory'; fa = 'Delete controlled inventory';
							|it = 'Cancellazione delle scorte supportate';
							|pl = 'Usuń obsługiwane zapasy';
							|tr = 'Desteklenen Envanteri Kaldırma'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

&AtServerNoContext
Function DeleteDetailedSettingOnServer(RecordsArray)
	
	RecordsKeys = New Array;
	For Each RegisterRecordKey In RecordsArray Do
		If ValueIsFilled(RegisterRecordKey.Characteristic) Then
			ParameterEntryKey = InformationRegisters.ProductRestrictions.FeatureRecordingKey();
			FillPropertyValues(ParameterEntryKey, RegisterRecordKey);
			RecordsKeys.Add(ParameterEntryKey);
		EndIf;
	EndDo;
	If RecordsKeys.Count() = 0 Then
		Return False;
	EndIf;
	
	InformationRegisters.ProductRestrictions.SetStockMaintenanceAsForProducts(RecordsKeys);
	Return True;
	
EndFunction

&AtServerNoContext
Procedure AddInventorySupportOnServer(AddressInTempStorage, Warehouse, Group)
	
	GoodsTable	= GetFromTempStorage(AddressInTempStorage);
	ThereAreMinMax		= GoodsTable.Columns.Find("MinimumBalance") <> Undefined And
		GoodsTable.Columns.Find("MaximumBalance") <> Undefined;
	RecordsKeys	= New Array;
	For Each TableRow In GoodsTable Do
		If ValueIsFilled(TableRow.Characteristic) Then
			ProductRecordKey =InformationRegisters.ProductRestrictions.FeatureRecordingKey();
			ProductRecordKey.Characteristic = TableRow.Characteristic;
		Else
			ProductRecordKey = InformationRegisters.ProductRestrictions.ProductEntryKey();
		EndIf;
		ProductRecordKey.Products = TableRow.Products;
		ProductRecordKey.Warehouse = Warehouse;
		
		If ThereAreMinMax And Not ValueIsFilled(Group) And (ValueIsFilled(TableRow.MinimumBalance)
			Or ValueIsFilled(TableRow.MaximumBalance)) Then
			ParametersMinMax = InformationRegisters.ProductRestrictions.ParametersMinMax();
			ParametersMinMax.MinimumInventoryQuantity	= TableRow.MinimumBalance;
			ParametersMinMax.MaximumInventoryAmount	= TableRow.MaximumBalance;
			InformationRegisters.ProductRestrictions.AddStockMaintenanceMinMax(ProductRecordKey, ParametersMinMax);
		Else
			RecordsKeys.Add(ProductRecordKey);
		EndIf;
	EndDo;
	
	If ValueIsFilled(Group) Then
		InformationRegisters.ProductRestrictions.AddInventoryMaintenanceByGrouping(RecordsKeys,
			InformationRegisters.ProductRestrictions.KeyForRecordingDimensions(Group));
	Else
		InformationRegisters.ProductRestrictions.AddStockMaintenanceMinMax(RecordsKeys);
	EndIf;
	
EndProcedure

#EndRegion