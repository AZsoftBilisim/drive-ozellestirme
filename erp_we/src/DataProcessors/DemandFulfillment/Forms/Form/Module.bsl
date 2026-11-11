#Region Variables

&AtClient
Var ValuesInCache;

&AtClient
Var DeliveryDateBeforeChange;

&AtClient
Var LineBeforeChange;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Filling in additional details
	TextNotFilledIn = NStr("vi = '<chưa điền>';
							|ru = '<не заполнено>';
							|en = '<not filled in>'; fa = '<not filled in>';
							|it = '<Non compilato>';
							|pl = '<nie wypełniono>';
							|tr = '<doldurulmadı>'");
	
	UsePurchaseOrders = GetFunctionalOption("UsePurchaseOrders");
	UsePurchaseRequests = GetFunctionalOption("UsePurchaseRequests");
	UseTermsOfPurchases = GetFunctionalOption("UseTermsOfPurchases");
	OptimizeDistributionCenterInventory = GetFunctionalOption("OptimizeDistributionCenterInventory");
	UseOrderSupplyWithAssignment = GetFunctionalOption("UseOrderSupplyWithAssignment");
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	UseGoodsQualityControl = GetFunctionalOption("UseGoodsQualityControl");
	
	Items.PreviewTerms.Visible = UseTermsOfPurchases;
	Items.LabelFeaturesOfDistributionNetwork.Visible = OptimizeDistributionCenterInventory;
	Items.CalculationOfSeparateNeedsTakingIntoAccountBalancesInAllWarehouses.Visible = UseOrderSupplyWithAssignment
		And UseSeveralWarehouses;
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CurrencyExchangeRateManAccounting = ProcessingOfExchangeRatesTM.GetCurrencyRate(Constants.ManagementAccountingCurrency.Get(), BegOfDay(CurrentSessionDate()));
	If CurrencyExchangeRateManAccounting.CourseDenominator = 0 Then
		If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
			ExceptionText = NStr("vi = 'Chưa đặt tỷ giá tiền tệ kế toán quản trị. Không thể tạo giấy đề nghị.';
								|ru = 'Не задан курс валюты управленческого учета. Формирование заявок невозможно.';
								|en = 'Exchange rate of management accounting is not specified. You cannot generate requests.'; fa = 'Exchange rate of management accounting is not specified. You cannot generate requests.';
								|it = 'Exchange rate of management accounting is not specified. You cannot generate requests.';
								|pl = 'Exchange rate of management accounting is not specified. You cannot generate requests.';
								|tr = 'Yönetim muhasebesi para birimi ayarlanmadı. Talep oluşumu mümkün değildir.'");
		Else
			ExceptionText = NStr("vi = 'Chưa đặt tỷ giá tiền tệ kế toán quản trị. Không thể tạo đơn hàng.';
								|ru = 'Не задан курс валюты управленческого учета. Формирование заказов невозможно.';
								|en = 'Exchange rate of management accounting is not specified. You cannot generate orders.'; fa = 'Exchange rate of management accounting is not specified. You cannot generate orders.';
								|it = 'Non è indicato il tasso di cambio della contabilità gestionale. Impossibile creare gli ordini.';
								|pl = 'Exchange rate of management accounting is not specified. You cannot generate orders.';
								|tr = 'Yönetim muhasebesi para birimi kuru ayarlanmadı. Sipariş oluşumu mümkün değildir.'");
		EndIf;
		Raise ExceptionText;
	EndIf;
	
	SetAvailabilityOfCommandsByFunctionalOptions();
	ConfigureTaxiClientAppFormElements();
	
	UnitOfMeasureForWeight = Constants.UnitOfMeasureForWeight.Get();
	Items.UnitOfMeasureForWeight.Title = String(UnitOfMeasureForWeight);
	Items.WeightUnitStep5.Title = String(UnitOfMeasureForWeight);
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	Items.CurrencyOfManAccounting.Title = String(ManagementAccountingCurrency);
	Items.CurrencyOfUPRAccountingStep5.Title = String(ManagementAccountingCurrency);
	
	UsePackages = GetFunctionalOption("UseItemPackages");
	Items.PreviewOrderPackage.Visible = UsePackages;
	HasAccessToPackageChange = AccessRight("Update", Metadata.InformationRegisters.ProductRestrictions);
	
	OrderTypes.LoadValues(Metadata.Catalogs.Assignments.Attributes.OrderDocument.Type.Types());
	
	ThereIsInventoryStep = Not Parameters.Property("ThereIsInventoryStep") Or Parameters.ThereIsInventoryStep;
	
	// Limitation of the list of software type selection in simple and extended selections.
	SelectionBySoftwareTypeParameter = Undefined;
	Parameters.Property("FilterBySupplyType", SelectionBySoftwareTypeParameter);
	ProcessSoftwareAvailability(SelectionBySoftwareTypeParameter);
	
	CustomizeFormForIntendedUse();
	
	// Initializing the settings builder to display the selection table at the first step of the assistant.
	If Items.FilterBySupplyType.Type = FormFieldType.LabelField Then
		AvailableTypesOfCollateral = New Array();
		AvailableTypesOfCollateral.Add(FilterBySupplyType);
	Else
		AvailableTypesOfCollateral = Items.FilterBySupplyType.ChoiceList.UnloadValues();
	EndIf;
	
	InitializeSettingsComposerForSelections(AvailableTypesOfCollateral);
	RestoreSettings();
	Items.LabelFeaturesOfDistributionNetwork.Title
		= OnChangesCalculationOfIsolatedNeedsTakingIntoAccountBalancesInAllWarehouses(
			CalculationOfSeparateNeedsTakingIntoAccountBalancesInAllWarehouses);
	
	If Parameters.Property("FilterBySupplyType") Or Items.FilterBySupplyType.Type = FormFieldType.LabelField Then
		ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer, "SupplyType", FilterBySupplyType, False);
	EndIf;
	
	If Parameters.Property("FilterByBusinessUnit") Then
		FilterByBusinessUnit = Parameters.FilterByBusinessUnit;
		ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer, "Department", FilterByBusinessUnit, False);
	EndIf;
	
	If Parameters.Property("FilterBySupplySource") And ValueIsFilled(Parameters.FilterBySupplySource) Then
		FilterBySupplySource = Parameters.FilterBySupplySource;
		ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer, "SupplySource", FilterBySupplySource,
			ThisIsGroupSelectionOnServer(FilterBySupplySource));
	EndIf;
	
	If Parameters.Property("FilterByManager") Then
		FilterByManager = Parameters.FilterByManager;
		ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer, "Manager", FilterByManager, False);
	EndIf;
	
	If Parameters.Property("SelectionByWorkshopStorerooms") And Parameters.SelectionByWorkshopStorerooms Then
		
		SelectionByWorkshopStorerooms = True;
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.ShopFloorStockroom", True));
		Items.FilterByWarehouse.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
		ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer, "Warehouse.ShopFloorStockroom", True, False);
		
	Else
		Items.SelectionByWorkshopStorerooms.Visible = False;
		ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer, "Warehouse.ShopFloorStockroom", Undefined, False);
	EndIf;
	
	InstallAssistantPages("StepDemandFilter");
	
	Items.RecommendationBar.Visible = Items.RecommendationsStocks.Check;
	
	FillStockLevelFilterSelectionList();
	
	InstallHints();
	SetAccessibilityOfFormElementsByRights();
	
	CachedValues = New Structure("LowestPriority, HighestPriority",
		Catalogs.Priorities.GetLowerPriority(),
		Catalogs.Priorities.GetTopPriority());
		
	Items.WarehouseInventory.Visible = UseSeveralWarehouses;
	Items.PreviewWarehouse.Visible = UseSeveralWarehouses;

	FillWarehouseVisibility = GetFunctionalOption("UseTransferOrders");
	FillProviderVisibility = GetFunctionalOption("UsePurchaseOrders");
	FillProviderVisibility = FillProviderVisibility
		Or GetFunctionalOption("UseProductionByThirdParty2_5");
	FillInVisibilityDivision = False;
	FillInVisibilityDivision = FillInVisibilityDivision
		Or GetFunctionalOption("UseProductionManagement2_2");
	Items.FillInTheSupplierOnTheOrdersStep.Visible    = FillProviderVisibility;
	Items.FillInTheWarehouseOnTheOrdersStep.Visible         = FillWarehouseVisibility;
	Items.FillInTheDivisionOnTheOrdersStep.Visible = FillInVisibilityDivision;

	Items.FillInTheSupplierInTheInventoryStep.Visible    = FillProviderVisibility;
	Items.FillInTheWarehouseOnTheInventoryStep.Visible         = FillWarehouseVisibility;
	Items.FillInTheDivisionInTheInventoryStep.Visible = FillInVisibilityDivision;
	
	OrderingByDocumentDate = Constants.OptionOfOrderingDemandsByOrdersForSupply.Get()
		= Enums.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndDocumentDate;
		
	If OrderingByDocumentDate Then
		Items.InscriptionDateOfShipmentDateOfOrderHasArrived.Visible = False;
		Items.FilterToOrderNoLaterThanOrders.Visible = False;
	EndIf;
	If GetFunctionalOption("UseProduction") Then
		Items.PartnerWarehouse.Title = NStr("vi = 'Bạn hàng/Kho/Bộ phận';
											|ru = 'Партнер/Склад/Подразделение';
											|en = 'Partner/Warehouse/Business unit'; fa = 'Partner/Warehouse/Business unit';
											|it = 'Partner/Magazzino/Reparto';
											|pl = 'Partner/Warehouse/Business unit';
											|tr = 'İş ortağı/Ambar/Departman'");
	EndIf;
	If UseGoodsQualityControl Then
		
		Items.SupplyMethodsBoundaryOfCoveredPeriod.Title
			= NStr("vi = 'Đáp ứng nhu cầu trước ngày (không có thời hạn kiểm soát chất lượng)';
					|ru = 'Обеспечить потребности до даты (без срока контроля качества)';
					|en = 'Cover demand up to date (without quality control period)'; fa = 'Cover demand up to date (without quality control period)';
					|it = 'Cover demand up to date (without quality control period)';
					|pl = 'Cover demand up to date (without quality control period)';
					|tr = 'Gereksinimleri tarihe kadar karşıla (kalite kontrol süresi olmadan)'");
			
		Items.DeliveryPeriodDays43.Title = NStr("vi = 'Thời hạn giao hàng và kiểm soát chất lượng';
												|ru = 'Срок поставки и контроля качества';
												|en = 'Delivery and quality control period'; fa = 'Delivery and quality control period';
												|it = 'Delivery and quality control period';
												|pl = 'Delivery and quality control period';
												|tr = 'Teslimat ve kalite kontrol süresi'");
		Items.DeliveryPeriodDays3.Title = NStr("vi = 'Thời hạn giao hàng và kiểm soát chất lượng';
												|ru = 'Срок поставки и контроля качества';
												|en = 'Delivery and quality control period'; fa = 'Delivery and quality control period';
												|it = 'Delivery and quality control period';
												|pl = 'Delivery and quality control period';
												|tr = 'Teslimat ve kalite kontrol süresi'");
		Items.CoveredPeriod43.Title = NStr("vi = 'Giai đoạn được đảm bảo (có kiểm soát chất lượng)';
											|ru = 'Обеспечиваемый период (с контролем качества)';
											|en = 'Covered period (with quality control)'; fa = 'Covered period (with quality control)';
											|it = 'Covered period (with quality control)';
											|pl = 'Covered period (with quality control)';
											|tr = 'Karşılanan dönem (kalite kontrollü)'");
		Items.CoveredPeriod3.Title = NStr("vi = 'Giai đoạn được đảm bảo (có kiểm soát chất lượng)';
											|ru = 'Обеспечиваемый период (с контролем качества)';
											|en = 'Covered period (with quality control)'; fa = 'Covered period (with quality control)';
											|it = 'Covered period (with quality control)';
											|pl = 'Covered period (with quality control)';
											|tr = 'Karşılanan dönem (kalite kontrollü)'");
		
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ReflectLayoutSelectionInSimpleSelections() Then
		Items.SelectionPages.CurrentPage = Items.PageSimpleFilters;
	Else
		Items.SelectionPages.CurrentPage = Items.PageRandomFilters;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Items.Assistant.CurrentPage = Items.StepDemandFilter And ShouldSaveSettings Then
		If Exit Then
			Cancel = True;
			WarningText = NStr("vi = 'Việc lựa chọn các nhu cầu đã được thay đổi. Tất cả các thay đổi sẽ bị mất.';
								|ru = 'Отбор потребностей был изменен. Все изменения будут потеряны.';
								|en = 'Demand filter was changed. All changes will be lost.'; fa = 'Demand filter was changed. All changes will be lost.';
								|it = 'La selezione dei fabbisogni è stata modificata. Tutte le modifiche andranno perse.';
								|pl = 'Filtr potrzeb został zmieniony. Wszystkie zmiany zostaną utracone.';
								|tr = 'Gereksinim filtresi değiştirildi. Tüm değişiklikler kaybolacak.'");
		Else
			ShouldSaveSettings();
		EndIf;
		Return;
	EndIf;
	
	ThereAreUnprocessedListItems = Items.Assistant.CurrentPage = Items.DemandStep
		And ShoppingCartTotalFieldTotalLines > 0;
	
	If Exit
		And ThereAreUnprocessedListItems 
		And Not ClearTheDemandTableResponseReceived Then
		
		Cancel = True;
		If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
			WarningText = NStr("vi = 'Danh sách các yêu cầu chứa các mục được đánh dấu mà giấy đề nghị chưa được lập.';
								|ru = 'В списке потребностей имеются отмеченные позиции, заявки по которым не сформированы.';
								|en = 'In the demand list, there are selected items for which requests were not generated.'; fa = 'In the demand list, there are selected items for which requests were not generated.';
								|it = 'In the demand list, there are selected items for which requests were not generated.';
								|pl = 'In the demand list, there are selected items for which requests were not generated.';
								|tr = 'Gereksinimler listesinde talepleri oluşturulmamış işaretlenmiş pozisyonlar mevcut.'");
		Else
			WarningText = NStr("vi = 'Danh sách các yêu cầu chứa các mục được đánh dấu mà đơn hàng chưa được lập.';
								|ru = 'В списке потребностей имеются отмеченные позиции, заказы по которым не сформированы.';
								|en = 'In the demand list, there are selected items for which orders were not generated.'; fa = 'In the demand list, there are selected items for which orders were not generated.';
								|it = 'Nella lista dei fabbisogni sono presenti le voci contrassegnate, gli ordini per le quali non sono stati formati.';
								|pl = 'Na liście potrzeb znajdują się oznaczone pozycje, których zamówienia nie są tworzone.';
								|tr = 'Gereksinimler listesinde, siparişleri oluşturulmamış işaretlenmiş pozisyonlar mevcut.'");
		EndIf;
		
		Return;
		
	EndIf;
	
	If ThereAreUnprocessedListItems Then
		
		If Not ClearTheDemandTableResponseReceived Then
			StandardProcessing = False;
			Cancel = True;
			ClearingNeedsTableIsIssue("Close"); // Calling a non-modal question window.
		Else
			ClearTheDemandTableResponseReceived = False; // Reset the attribute.
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	TableName = ?(Items.PagesDemandTable.CurrentPage = Items.PageTableInventory,
	"Inventories", "OrdersPendingSupply");
	
	If ChoiceSource.FormName = "DataProcessor.DemandFulfillment.Form.SelectionFormOfPackageUnit" Then
		
		Shipment = Items[TableName].CurrentData;
		FillWritePackingOnIndexTree(Shipment.IndexID, ValueSelected);
		
		RowsMap = RecalculateRounding(Shipment, TableName = "Inventories");
		
		DisplayCalculatedRounding(Shipment, TableName = "Inventories");
		
		CalculateTotals();
		
	Else
		
		If Not TypeOf(ValueSelected) = Type("Structure") Then
			Return;
		EndIf;
		
		If Items.Assistant.CurrentPage = Items.StepOrderEditing Then
			
			PreviewDeliveryParametersOptimalSelectionProcessingAtServer(ValueSelected.DeliveryParametersOptimal);
			Rows = CommonClientServer.ValueInArray(Items.Preview.CurrentRow);
			FindOutPositionOfRowsAndGroupingsInTree(Rows);
			Return;
			
		EndIf;
		
		If ValueSelected.Property("DeliveryParametersOptimal") Then
			
			SourceType = TypeOf(ValueSelected.DeliveryParametersOptimal.SupplySource);
			
			For Each Id In Items[TableName].SelectedRows Do
				
				Shipment = Object[TableName].FindByID(Id);
				If SourceType = Type("CatalogRef.Partners")
						And Shipment.SupplyType <> PredefinedValue("Enum.SupplyTypes.Purchase")
						And Shipment.SupplyType <> PredefinedValue("Enum.SupplyTypes.ProductionByThirdParty")
					Or SourceType = Type("CatalogRef.Warehouses")
						And Shipment.SupplyType <> PredefinedValue("Enum.SupplyTypes.Move")
					Or SourceType = Type("CatalogRef.BusinessStructure")
						And Shipment.SupplyType <> PredefinedValue("Enum.SupplyTypes.Production")
					Or Shipment.SupplySourceViewOnly Then
					Continue;
				EndIf;
				
				If Shipment.Mark Then
					CalculateTotals();
				EndIf;
				
				PackageBeforeChange = Shipment.OrderPackage;
				FillPropertyValues(Shipment, ValueSelected.DeliveryParametersOptimal);
				If Not ValueIsFilled(Shipment.OrderPackage) Then
					Shipment.OrderPackage = PackageBeforeChange;
				EndIf;
				FillWritePackingOnIndexTree(Shipment.IndexID, ValueSelected.DeliveryParametersOptimal.OrderPackage, True);
				
				If Shipment.Mark Then
					CalculateTotals();
				EndIf;
				
				RowsMap = RecalculateRounding(Shipment, TableName = "Inventories");
				
				DisplayCalculatedRounding(Shipment, TableName = "Inventories");
				
				CalculateTotals();
				
			EndDo;
			
		ElsIf ValueSelected.Property("StockLevelCode") Then
			
			InventoryLevelFilter = StockLevelByCode(ValueSelected.StockLevelCode);
			SelectingStocksOnServer();
			
		ElsIf ValueSelected.Property("SupplyMethod") Then
			
			If Items.PagesDemandTable.CurrentPage = Items.PageTableInventory Then
				
				If Not ValueIsFilled(ValueSelected.SupplyMethod) Then // do not change the method selected in the table
					CalculateInventoryTableRowOnClient(Items.Inventories.CurrentData.SupplyMethod);
				Else
					CalculateInventoryTableRowOnClient(ValueSelected.SupplyMethod);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If ProcessingOfDocumentWritingNotificationsIsEnabled
		And ( EventName = "Write_TransferOrder"
		Or EventName = "Write_ByAssemblyDisassemblyOrder"
		Or EventName = "Write_OrderOfMaterialsForProduction"
		Or EventName = "Write_SubcontractOrder2_5"
		Or EventName = "Write_ProductionOrder"
		Or EventName = "Write_PurchaseOrder"
		Or EventName = "Write_PurchaseRequest") Then
		
		Ref = Source;
		If EventName = "Write_ProductionOrder" Then
			Ref = Parameter;
		EndIf;
		UpdateDocumentTableDetails(Ref);
		
	EndIf;
	
	If EventName = "Write_ProcurementStrategy" Then
		
		AssuranceMethodsWhenAssuranceMethodChanges();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region ServerSelections

&AtClient
Procedure FilterByWarehouseOnChange(Item)
	
	ShouldSaveSettings = True;
	ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer,
		"Warehouse", FilterByWarehouse, ThisIsGroupSelection(FilterByWarehouse));
	
EndProcedure

&AtClient
Procedure FilterByReceivingDepartmentOnChange(Item)
	
	ShouldSaveSettings = True;
	ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer,
		"ReceivingBusinessUnit", FilterByReceivingDepartment, False);
	
EndProcedure

&AtClient
Procedure FilterByAssignmentOnChange(Item)
	
	ShouldSaveSettings = True;
	ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer,
		"Purpose", FilterByAssignment, False);
	
EndProcedure

&AtClient
Procedure FilterByLineOfBusinessOnChange(Item)
	
	ShouldSaveSettings = True;
	ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer,
		"LineOfBusiness", FilterByLineOfBusiness, False);
	
EndProcedure

&AtClient
Procedure FilterBySegmentOnChange(Item)
	
	ShouldSaveSettings = True;
	ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer,
		"ProductSegment", FilterBySegment, ThisIsGroupSelection(FilterBySegment));
	
EndProcedure

&AtClient
Procedure FilterRemainingGoodsByShelfLivesOnChange(Item)
	
	ShouldSaveSettings = True;
	ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer,
		"Products", FilterRemainingGoodsByShelfLives, ThisIsGroupSelection(FilterRemainingGoodsByShelfLives));
	
EndProcedure

&AtClient
Procedure FilterByBrandOnChange(Item)
	
	ShouldSaveSettings = True;
	ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer,
		"Products.Brand", FilterByBrand, ThisIsGroupSelection(FilterByBrand));
	
EndProcedure

&AtClient
Procedure SelectionByProductCategoryOnChange(Item)
	
	ShouldSaveSettings = True;
	ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer,
		"Products.ProductCategory", SelectionByProductCategory, ThisIsGroupSelection(SelectionByProductCategory));
	
EndProcedure

&AtClient
Procedure FilterByBusinessUnitOnChange(Item)
	
	ShouldSaveSettings = True;
	ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer,
		"Department", FilterByBusinessUnit, False);
	
EndProcedure

&AtClient
Procedure FilterBySupplyTypeOnChange(Item)
	
	ShouldSaveSettings = True;
	ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer,
		"SupplyType", FilterBySupplyType, False);
	
EndProcedure

&AtClient
Procedure FilterByManagerOnChange(Item)
	
	ShouldSaveSettings = True;
	ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer,
		"Manager", FilterByManager, False);
	
EndProcedure

&AtClient
Procedure FilterBySupplySourceOnChange(Item)
	
	ShouldSaveSettings = True;
	ReflectSimpleSelectionInLayoutSelections(FilterSettingsComposer,
		"SupplySource", FilterBySupplySource, ThisIsGroupSelection(FilterBySupplySource));
	
EndProcedure

&AtClient
Procedure ToUseARandomSelectionClick(Item)
	Items.SelectionPages.CurrentPage = Items.PageRandomFilters;
EndProcedure

&AtClient
Procedure TheUseOfSimpleSelectionsClick(Item)
	
	If ReflectLayoutSelectionInSimpleSelections() Then
		Items.SelectionPages.CurrentPage = Items.PageSimpleFilters;
	Else
		ShowMessageBox(Undefined, NStr("vi = 'Không thể chuyển bộ lọc đã đặt sang dạng lọc đơn giản.';
										|ru = 'Установленные отборы невозможно преобразовать к виду простых отборов.';
										|en = 'Cannot convert the set filters into simple filters.'; fa = 'Cannot convert the set filters into simple filters.';
										|it = 'Le selezioni impostate non possono essere convertite nel tipo di selezioni semplici.';
										|pl = 'Zainstalowanych wyborów nie można konwertować do postaci prostych wyborów.';
										|tr = 'Yerleşik filtreler basit filtrelere dönüştürülemez.'"));
	EndIf;

EndProcedure

#EndRegion

#Region ClientFilters

&AtClient
Procedure CalculationOfSeparateNeedsTakingIntoAccountBalancesInAllWarehousesOnChange(Item)
	
	ShouldSaveSettings = True;
	
	Items.LabelFeaturesOfDistributionNetwork.Title
		= OnChangesCalculationOfIsolatedNeedsTakingIntoAccountBalancesInAllWarehouses(
			CalculationOfSeparateNeedsTakingIntoAccountBalancesInAllWarehouses);
	
EndProcedure

&AtClient
Procedure FilterMarkInventoryOnChange(Item)

	SelectingStocksOnServer();

EndProcedure

&AtClient
Procedure InventoryLevelFilterOnChange(Item)

	SelectingStocksOnServer();

EndProcedure

&AtClient
Procedure InventoryLevelFilterStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	FormParameters = New Structure("StockLevelCode", StockLevelCode(InventoryLevelFilter));
	OpenForm("DataProcessor.DemandFulfillment.Form.InventoryLevelChoiceForm",
		FormParameters, ThisObject, UUID);

EndProcedure

&AtClient
Procedure InventoryLevelFilterClearing(Item, StandardProcessing)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure FilterToOrderNoLaterThanInventoryOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi

	SelectingStocksOnServer();

EndProcedure

&AtClient
Procedure FilterToOrderNoLaterThanOrdersOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SelectingOrdersOnServer();
	
EndProcedure

&AtClient
Procedure FilterMarkOrdersOnChange(Item)

	SelectingOrdersOnServer();

EndProcedure

&AtClient
Procedure PriorityFilterOnChange(Item)

	SelectingOrdersOnServer();

EndProcedure

&AtClient
Procedure FilterToShipNotEarlierOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi

	SelectingOrdersOnServer();

EndProcedure

&AtClient
Procedure FilterForShipmentNoLaterThanOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi

	SelectingOrdersOnServer();

EndProcedure

&AtClient
Procedure FilterToShipNotEarlierTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)

	CheckCorrectnessOfFillingFilterForShipmentNoEarlier(StringToDate(Text), StandardProcessing);

EndProcedure

&AtClient
Procedure FilterForShipmentNoLaterThanTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)

	CheckCorrectnessOfFillingFilterForShipmentNoLaterThan(StringToDate(Text), StandardProcessing);

EndProcedure

&AtClient
Procedure FilterForShipmentNoLaterThanChoiceProcessing(Item, ValueSelected, StandardProcessing)

	CheckCorrectnessOfFillingFilterForShipmentNoLaterThan(ValueSelected, StandardProcessing);

EndProcedure

&AtClient
Procedure FilterToShipNotEarlierChoiceProcessing(Item, ValueSelected, StandardProcessing)

	CheckCorrectnessOfFillingFilterForShipmentNoEarlier(ValueSelected, StandardProcessing);

EndProcedure

&AtClient
Procedure FilterUnsecuredOnChange(Item)

	FilterUnsecuredWhenModifiedOnServer();

EndProcedure

#EndRegion

#Region RecommendationBar

&AtClient
Procedure MinimumInventory1Click(Item, StandardProcessing)

	StandardProcessing = False;
	OpenCollateralMethod("Inventories");

EndProcedure

&AtClient
Procedure MaximumOrder1Click(Item, StandardProcessing)

	StandardProcessing = False;
	OpenCollateralMethod("Inventories");

EndProcedure

&AtClient
Procedure MinimumInventory2Click(Item, StandardProcessing)

	StandardProcessing = False;
	OpenCollateralMethod("Inventories");

EndProcedure

&AtClient
Procedure MaximumOrder2Click(Item, StandardProcessing)

	StandardProcessing = False;
	OpenCollateralMethod("Inventories");

EndProcedure

&AtClient
Procedure DeliveryPeriodDays3Click(Item, StandardProcessing)

	StandardProcessing = False;
	OpenMethodOfProviding("Inventories");

EndProcedure

&AtClient
Procedure CoveredPeriod3Click(Item, StandardProcessing)

	StandardProcessing = False;
	OpenMethodOfProviding("Inventories");

EndProcedure

&AtClient
Procedure AverageDailyConsumption3Click(Item, StandardProcessing)

	StandardProcessing = False;
	OpenCollateralMethod("Inventories");

EndProcedure

&AtClient
Procedure SafetyStock3Click(Item, StandardProcessing)

	StandardProcessing = False;
	OpenCollateralMethod("Inventories");

EndProcedure

&AtClient
Procedure DeliveryPeriodDays43Click(Item, StandardProcessing)

	StandardProcessing = False;
	OpenMethodOfProviding("Inventories");

EndProcedure

&AtClient
Procedure CoveredPeriod43Click(Item, StandardProcessing)

	StandardProcessing = False;
	OpenMethodOfProviding("Inventories");

EndProcedure

&AtClient
Procedure AverageDailyConsumption4Click(Item, StandardProcessing)

	StandardProcessing = False;
	OpenCollateralMethod("Inventories");

EndProcedure

&AtClient
Procedure SafetyStock4Click(Item, StandardProcessing)

	StandardProcessing = False;
	OpenCollateralMethod("Inventories");

EndProcedure

#EndRegion

#Region BDRLimits

&AtClient
Procedure PurchaseObjectiveOnChange(Item)
	ShouldSaveSettings = True;
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersArbitraryFiltersItems

&AtClient
Procedure ArbitraryFiltersItemsOnChange(Item)
	ShouldSaveSettings = True;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSupplyMethods

&AtClient
Procedure SupplyMethodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.SupplyMethods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.SupplyMethodsSupplyMethod Then
		
		If ValueIsFilled(CurrentData.SupplyMethod) Then
		
			StandardProcessing = False;
			NameOfFormToOpen = "Catalog.ProcurementStrategies.ObjectForm";
			FormParameters = New Structure("Key", CurrentData.SupplyMethod);
			OpenForm(NameOfFormToOpen,
				FormParameters,
				ThisObject,
				UUID,
				,
				,
				,
				FormWindowOpeningMode.LockOwnerWindow);
				
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyMethodsDemandConversionOptionOnChange(Item)
	
	TableRow = Items.SupplyMethods.CurrentData;
	TableRow.LineChanged = True;
	ProvisionInDocumentsClient.FillInDatesInSecondStepOfDemandFulfillment(TableRow);
	
EndProcedure

&AtClient
Procedure SupplyMethodsShipmentDateOnChange(Item)
	TableRow = Items.SupplyMethods.CurrentData;
	TableRow.LineChanged = True;
EndProcedure

&AtClient
Procedure SupplyMethodsBoundaryOfCoveredPeriodOnChange(Item)
	TableRow = Items.SupplyMethods.CurrentData;
	TableRow.LineChanged = True;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInventories

&AtClient
Procedure InventoriesSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Form.Item.Inventories.Selection");
	
	If Item.CurrentItem = Items.StrategyOfProcurement Then

		StandardProcessing = False;
		OpenCollateralMethod("Inventories");
		
	ElsIf Field = Items.ProductsInventory Then
		ShowValue(,Item.CurrentData.Products);
	ElsIf Field = Items.WarehouseInventory Then
		ShowValue(,Item.CurrentData.Warehouse);
	EndIf;

EndProcedure

&AtClient
Procedure InventoriesOnActivateRow(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Item.Inventories.OnActivateRow");
	
	If Items.PagesDemandTable.CurrentPage = Items.PageTableInventory Then
		AttachIdleHandler("ReservesWhenActivatingWaitHandlerLine", 0.1, True);
	EndIf;

EndProcedure

&AtClient
Procedure InventoriesOnActivateCell(Item)
	
	RowStocks = Items.Inventories.CurrentData;
	If Item.CurrentItem = Items.MethodOfSecuringStocks And RowStocks <> Undefined Then
		
		If RowStocks.TransferIsAllowed Then
			AvailableSupplyTypesForSelection = AvailableSupplyTypesWithTransfer;
		Else
			AvailableSupplyTypesForSelection = AvailableSupplyTypesWithoutTransfer;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MarkInventoryOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Item.MarkInventory.OnChange");
	
	Shipment = Items.Inventories.CurrentData;
	
	RowsMap = RecalculateRounding(Shipment, True);
	
	DisplayCalculatedRounding(Shipment, True);
	
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure ToOrderInventoryOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Item.ToOrderInventory.OnChange");
	
	Shipment = Items.Inventories.CurrentData;
	Shipment.Mark = Shipment.ToOrder > 0;
	
	RowsMap = RecalculateRounding(Shipment, True);
	
	DisplayCalculatedRounding(Shipment, True);
	
	CalculateTotals();

EndProcedure

&AtClient
Procedure MethodOfSecuringStocksOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Item.MethodOfSecuringStocks.OnChange");
	
	Shipment = Items.Inventories.CurrentData;
	
	CalculateInventoryTableRowOnClient(Shipment.SupplyMethod);
	
	RowsMap = RecalculateRounding(Shipment, True);
	
	DisplayCalculatedRounding(Shipment, True);
	
	CalculateTotals();

EndProcedure

&AtClient
Procedure MethodOfSecuringStocksClearing(Item, StandardProcessing)
	
	Shipment = Items.Inventories.CurrentData;
	MethodOfProvidingCleaning(Shipment, False);
	MethodOfSecuringStocksOnChange(Item);
	
EndProcedure

&AtClient
Procedure MethodOfSecuringStocksChoiceProcessing(Item, ValueSelected, StandardProcessing)

	Shipment = Items.Inventories.CurrentData;
	Shipment.Mark = False;
	CalculateTotals();

EndProcedure

&AtClient
Procedure MethodOfSecuringStocksTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	If Text = "" Then
		
		Shipment = Items.Inventories.CurrentData;
		MethodOfProvidingCleaning(Shipment, False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TheSourceOfSupplyForReservesStartChoice(Item, ChoiceData, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Form.Item.TheSourceOfSupplyForReserves.StartChoice");
	
	Shipment = Items.Inventories.CurrentData;
	
	FormParameters = New Structure("Warehouse, Products, Characteristic, ThisIsWork, SupplyType");
	FillPropertyValues(FormParameters, Shipment);
	FormParameters.ThisIsWork = False;
	
	StandardProcessing = False;
	OpenForm("DataProcessor.DemandFulfillment.Form.SelectionFormOfSourceOfSupply", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure TheSourceOfSupplyForReservesClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	Shipment = Items.Inventories.CurrentData;

	If Shipment.Mark Then

		CalculateTotals();

	EndIf;

	Shipment.SupplySource = TextNotFilledIn;

	ClearPurchaseTerms(Shipment);

	QuantityToOrder_ = Shipment.Rounded * ?(Shipment.Mark, 1, 0);
	CalculateTotals();

EndProcedure

&AtClient
Procedure TheSourceOfSupplyForReservesChoiceProcessing(Item, ValueSelected, StandardProcessing)

	StandardProcessing = False;

	Shipment = Items.Inventories.CurrentData;

	If Shipment.Mark Then

		CalculateTotals();

	EndIf;

	ClearPurchaseTerms(Shipment);

	Shipment.SupplySource = ProcessEmptySource(ValueSelected, TextNotFilledIn);
	
	QuantityToOrder_ = Shipment.Rounded * ?(Shipment.Mark, 1, 0);
	CalculateTotals();

EndProcedure

&AtClient
Procedure TheSourceOfSupplyForReservesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)

	If Text = "" Then

		Shipment = Items.Inventories.CurrentData;

		If Shipment.Mark Then

			CalculateTotals();

		EndIf;

		ClearPurchaseTerms(Shipment);

		Shipment.SupplySource = TextNotFilledIn;

		QuantityToOrder_ = Shipment.Rounded * ?(Shipment.Mark, 1, 0);
		CalculateTotals();

	EndIf;

EndProcedure

&AtClient
Procedure DeliveryDateInventoryClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	Shipment = Items.Inventories.CurrentData;

	If Shipment.Mark Then

		CalculateTotals();

	EndIf;

	Shipment.ShipmentDate = '00010101';

	QuantityToOrder_ = Shipment.Rounded * ?(Shipment.Mark, 1, 0);
	CalculateTotals();

EndProcedure

&AtClient
Procedure DeliveryDateInventoryChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;

	Shipment = Items.Inventories.CurrentData;

	If Shipment.Mark Then

		CalculateTotals();

	EndIf;

	Shipment.ShipmentDate = ValueSelected;
	QuantityToOrder_ = Shipment.Rounded * ?(Shipment.Mark, 1, 0);
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure DeliveryDateInventoryTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	DeliveryDateBeforeChange = Items.Inventories.CurrentData.ShipmentDate;
	
EndProcedure

&AtClient
Procedure DeliveryDateInventoryOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Item.DeliveryDateInventory.OnChange");
	
	Shipment = Items.Inventories.CurrentData;
	
	If Shipment.Mark Then
		
		NewDeliveryDate = Shipment.ShipmentDate;
		Shipment.ShipmentDate = DeliveryDateBeforeChange;
		CalculateTotals();
		Shipment.ShipmentDate = NewDeliveryDate;
		
	EndIf;
	
	QuantityToOrder_ = Shipment.Rounded * ?(Shipment.Mark, 1, 0);
	CalculateTotals();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOrdersPendingSupply

&AtClient
Procedure OrdersPendingSupplyOnActivateCell(Item)
	
	OrdersLine = Items.OrdersPendingSupply.CurrentData;
	If Item.CurrentItem = Items.MethodOfSecuringOrders And OrdersLine <> Undefined Then
		
		If OrdersLine.ThisIsWork Then
			AvailableSupplyTypesForSelection = AvailableTypesOfWorkSupply;
		ElsIf OrdersLine.TransferIsAllowed Then
			AvailableSupplyTypesForSelection = AvailableSupplyTypesWithTransfer;
		Else
			AvailableSupplyTypesForSelection = AvailableSupplyTypesWithoutTransfer;
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure OrdersPendingSupplySelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.OrderDocument Then
		If Item.CurrentData.OrderDocument = Undefined Then
			Return;
		EndIf;
		ShowValue(,Item.CurrentData.OrderDocument);
	ElsIf Field = Items.ProductsOrders Then
		ShowValue(,Item.CurrentData.Products);
	ElsIf Field = Items.Recipient And ValueIsFilled(Item.CurrentData.Recipient) Then
		ShowValue(,Item.CurrentData.Recipient);
	EndIf;
	
EndProcedure

&AtClient
Procedure OrdersPendingSupplyOnActivateRow(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Item.OrdersPendingSupply.OnActivateRow");
	
	If Items.PagesDemandTable.CurrentPage = Items.PageTableOrders Then
		AttachIdleHandler("OrdersWhenActivatingWaitHandlerLine", 0.1, True);
	EndIf;

EndProcedure

&AtClient
Procedure MarkOrdersOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Item.MarkOrders.OnChange");
	
	Shipment = Items.OrdersPendingSupply.CurrentData;
	
	RowsMap = RecalculateRounding(Shipment, False);
	
	DisplayCalculatedRounding(Shipment, False);
	
	CalculateTotals();

EndProcedure

&AtClient
Procedure ToOrderOrdersOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Item.ToOrderOrders.OnChange");
	
	Shipment = Items.OrdersPendingSupply.CurrentData;
	Shipment.Mark = Shipment.ToOrder > 0;
	
	RowsMap = RecalculateRounding(Shipment, False);
	
	DisplayCalculatedRounding(Shipment, False);
	
	CalculateTotals();

EndProcedure

&AtClient
Procedure MethodOfSecuringOrdersOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Item.MethodOfSecuringOrders.OnChange");
	
	Shipment = Items.OrdersPendingSupply.CurrentData;
	
	CalculateOrdersToProvideTableRowOnClient(Shipment.SupplyMethod);
	
	RowsMap = RecalculateRounding(Shipment, False);
	
	DisplayCalculatedRounding(Shipment, False);
	
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure MethodOfSecuringOrdersClearing(Item, StandardProcessing)
	
	Shipment = Items.OrdersPendingSupply.CurrentData;
	MethodOfProvidingCleaning(Shipment, True);
	MethodOfSecuringOrdersOnChange(Item);
	
EndProcedure

&AtClient
Procedure MethodOfSecuringOrdersChoiceProcessing(Item, ValueSelected, StandardProcessing)

	Shipment = Items.OrdersPendingSupply.CurrentData;
	Shipment.Mark = False;
	CalculateTotals();

EndProcedure

&AtClient
Procedure MethodOfSecuringOrdersTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	If Text = "" Then
	
		Shipment = Items.OrdersPendingSupply.CurrentData;
		MethodOfProvidingCleaning(Shipment, True);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure TheSourceOfTheOrdersStartChoice(Item, ChoiceData, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Form.Item.TheSourceOfTheOrders.StartChoice");

	Shipment = Items.OrdersPendingSupply.CurrentData;

	FormParameters = New Structure("Warehouse, Products, Characteristic, ThisIsWork, SupplyType");
	FillPropertyValues(FormParameters, Shipment);

	StandardProcessing = False;
	OpenForm("DataProcessor.DemandFulfillment.Form.SelectionFormOfSourceOfSupply", FormParameters, ThisForm, UUID);

EndProcedure

&AtClient
Procedure TheSourceOfTheOrdersClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	Shipment = Items.OrdersPendingSupply.CurrentData;

	If Shipment.Mark Then

		CalculateTotals();

	EndIf;

	Shipment.SupplySource = TextNotFilledIn;

	ClearPurchaseTerms(Shipment);

	QuantityToOrder_ = Shipment.Rounded * ?(Shipment.Mark, 1, 0);
	CalculateTotals();

EndProcedure

&AtClient
Procedure TheSourceOfTheOrdersChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;

	Shipment = Items.OrdersPendingSupply.CurrentData;

	If Shipment.Mark Then

		CalculateTotals();

	EndIf;

	ClearPurchaseTerms(Shipment);

	Shipment.SupplySource = ProcessEmptySource(ValueSelected, TextNotFilledIn);
	QuantityToOrder_ = Shipment.Rounded * ?(Shipment.Mark, 1, 0);
	CalculateTotals();

EndProcedure

&AtClient
Procedure TheSourceOfTheOrdersTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)

	If Text = "" Then

		Shipment = Items.OrdersPendingSupply.CurrentData;

		If Shipment.Mark Then

			CalculateTotals();

		EndIf;

		ClearPurchaseTerms(Shipment);

		Shipment.SupplySource = TextNotFilledIn;

		QuantityToOrder_ = Shipment.Rounded * ?(Shipment.Mark, 1, 0);
		CalculateTotals();

	EndIf;

EndProcedure

&AtClient
Procedure DeliveryDateOrdersClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	Shipment = Items.OrdersPendingSupply.CurrentData;

	If Shipment.Mark Then

		CalculateTotals();

	EndIf;

	Shipment.ShipmentDate = '00010101';

	QuantityToOrder_ = Shipment.Rounded * ?(Shipment.Mark, 1, 0);
	CalculateTotals();

EndProcedure

&AtClient
Procedure DeliveryDateOrdersChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;

	Shipment = Items.OrdersPendingSupply.CurrentData;

	If Shipment.Mark Then

		CalculateTotals();

	EndIf;

	Shipment.ShipmentDate = ValueSelected;
	QuantityToOrder_ = Shipment.Rounded * ?(Shipment.Mark, 1, 0);
	CalculateTotals();

EndProcedure

&AtClient
Procedure DeliveryDateOrdersTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)

	DeliveryDateBeforeChange = Items.OrdersPendingSupply.CurrentData.ShipmentDate;

EndProcedure

&AtClient
Procedure DeliveryDateOrdersOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Item.DeliveryDateOrders.OnChange");
	
	Shipment = Items.OrdersPendingSupply.CurrentData;

	If Shipment.Mark Then

		NewDeliveryDate = Shipment.ShipmentDate;
		Shipment.ShipmentDate = DeliveryDateBeforeChange;
		CalculateTotals();
		Shipment.ShipmentDate = NewDeliveryDate;

	EndIf;

	Shipment = Items.OrdersPendingSupply.CurrentData;
	QuantityToOrder_ = Shipment.Rounded * ?(Shipment.Mark, 1, 0);
	CalculateTotals();

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGeneratedOrders

// Opening the created order form.
//
&AtClient
Procedure DocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	DocumentLine = Items.GeneratedOrders.CurrentData;
	DocumentRef  = DocumentLine.Document;
	ShowValue(Undefined, DocumentRef);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPreview

&AtClient
Procedure PreviewWarehouseChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	PreviewWarehouseSelectionProcessingAtServer(ValueSelected);
	Rows = CommonClientServer.ValueInArray(Items.Preview.CurrentRow);
	FindOutPositionOfRowsAndGroupingsInTree(Rows);
	
EndProcedure

&AtClient
Procedure PreviewManagerChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
	
	PreviewManagerSelectionProcessingAtServer(ValueSelected);
	Rows = CommonClientServer.ValueInArray(Items.Preview.CurrentRow);
	FindOutPositionOfRowsAndGroupingsInTree(Rows);
	
EndProcedure

&AtClient
Procedure PreviewTermsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	PreviewAgreementSelectionProcessingAtServer(ValueSelected);
	Rows = CommonClientServer.ValueInArray(Items.Preview.CurrentRow);
	FindOutPositionOfRowsAndGroupingsInTree(Rows);
	
EndProcedure

&AtServerNoContext
Function GetMinimumOrderAmount(SupplyMethod)
	Return Common.ObjectAttributeValue(SupplyMethod, "MinimumOrderAmount");
EndFunction

&AtClient
Procedure PreviewSupplyMethodChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	OrderLine = Item.Parent.CurrentData;
	
	PreviewIsWayToEnsureSelectionProcessingAtServer(ValueSelected);
	Rows = CommonClientServer.ValueInArray(Items.Preview.CurrentRow);
	FindOutPositionOfRowsAndGroupingsInTree(Rows);
	
EndProcedure

&AtServerNoContext
Function GetSourceAndAgreement(SupplyMethod)
	Return Common.ObjectAttributesValues(SupplyMethod, "SourceOfDemandSupply, Terms, SupplyType");
EndFunction

&AtClient
Procedure PreviewSupplySourceStartChoice(Item, ChoiceData, StandardProcessing)
	Shipment = Items.Preview.CurrentData;
	
	FormParameters = New Structure("Warehouse, Products, Characteristic, ThisIsWork, SupplyType");
	FillPropertyValues(FormParameters, Shipment);
	FormParameters.ThisIsWork = False;
	
	StandardProcessing = False;
	OpenForm("DataProcessor.DemandFulfillment.Form.SelectionFormOfSourceOfSupply", FormParameters, ThisForm, UUID);

EndProcedure

&AtClient
Procedure PreviewBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure PreviewOnActivateRow(Item)
	
	GenerateWarningLabel(Item);
	
	LinePreview = Items.Preview.CurrentData;
	If LinePreview <> Undefined Then
		
		If LinePreview.TransferIsAllowed Then
			AvailableSupplyTypesForSelection = AvailableSupplyTypesWithTransfer;
		Else
			AvailableSupplyTypesForSelection = AvailableSupplyTypesWithoutTransfer;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PreviewOnActivateCell(Item)
		
	LinePreview= Items.Preview.CurrentData;
	If Item.CurrentItem = Items.PreviewSupplyMethod And LinePreview <> Undefined Then
		
		If LinePreview.ThisIsWork Then
			AvailableSupplyTypesForSelection = AvailableTypesOfWorkSupply;
		ElsIf LinePreview.TransferIsAllowed Then
			AvailableSupplyTypesForSelection = AvailableSupplyTypesWithTransfer;
		Else
			AvailableSupplyTypesForSelection = AvailableSupplyTypesWithoutTransfer;
		EndIf;
	
	EndIf;
	
EndProcedure

&AtClient
Procedure PreviewSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "PreviewToOrder"
		Or Field.Name = "PreviewOrderPackage" Then
		
		StandardProcessing = False;
		If Item.CurrentData.LevelInTheTree = 0 Then
			Items.Preview.Expand(RowSelected);
			Return;
		EndIf;
		
		Var_Key = "SupplyMethod,SupplySource,Terms,Warehouse,Products,Characteristic";
		SearchParameters = New Structure(Var_Key);
		FillPropertyValues(SearchParameters, Item.CurrentData);
		
		FoundStocks = Object.Inventories.FindRows(SearchParameters);
		OrdersFound = Object.OrdersPendingSupply.FindRows(SearchParameters);
		
		Rows = New Array;
		
		For Each It_ In FoundStocks Do
			If Not It_.Mark Then 
				Continue;
			EndIf;
			
			Structure = PrepareStringStructure();
			FillPropertyValues(Structure, It_);
			Structure.Insert("Demand", It_.MaximumInventory);
			Structure.Insert("ThisIsInventory", True);
			
			Rows.Add(Structure);
		EndDo;
		
		For Each It_ In OrdersFound Do
			If Not It_.Mark Then 
				Continue;
			EndIf;
			
			Structure = PrepareStringStructure();
			FillPropertyValues(Structure, It_);
			Structure.Insert("Demand", It_.Required2);
			Structure.Insert("ThisIsInventory", False);
			
			Rows.Add(Structure);
		EndDo;
		
		ParametersForEditingForm = New Structure;
		ParametersForEditingForm.Insert("Rows",                      Rows);
		ParametersForEditingForm.Insert("RowSelected",             RowSelected);
		ParametersForEditingForm.Insert("Count",                  Item.CurrentData.ToOrder);
		ParametersForEditingForm.Insert("SupplyType",              Item.CurrentData.SupplyType);
		ParametersForEditingForm.Insert("MinimumDeliveryLot",   Item.CurrentData.MinimumDeliveryLot);
		ParametersForEditingForm.Insert("PurposeUseKey", PurposeUseKey);
		
		CallbackDescription = New CallbackDescription("FinishEditingQuantity", ThisObject);
		OpenForm("DataProcessor.DemandFulfillment.Form.QuantityEditingForm", ParametersForEditingForm,,,,,CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf Field.Name = "PreviewWarning" Then
		
		If Item.CurrentData.Warning Then
			
			ShowHideWarning();
			
		EndIf;
		
	ElsIf Field = Items.PreviewProducts Then
		ShowValue(,Item.CurrentData.Products);
	EndIf; 

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Back(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Command.Back");
	
	ClearMessages();
	
	If Items.Assistant.CurrentPage = Items.StepCreatedOrders Then
		
		If TableDocuments.Count() > 0 Then
			
			Buttons = New ValueList();
			If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
				QueryText = NStr("vi = 'Khi quay trở lại, các giấy đề nghị được lập sẽ được đánh dấu để xóa.';
								|ru = 'При переходе назад сформированные заявки будут помечены на удаление.';
								|en = 'Generated requests will be marked for deletion while going back.'; fa = 'Generated requests will be marked for deletion while going back.';
								|it = 'Generated requests will be marked for deletion while going back.';
								|pl = 'Generated requests will be marked for deletion while going back.';
								|tr = 'Geri dönüldüğünde oluşturulan talepler silinmek üzere işaretlenecektir.'");
				PresentationOfYesButton = NStr("vi = 'Đặt dấu xóa giấy đề nghị đã tạo';
												|ru = 'Пометить на удаление сформированные заявки';
												|en = 'Mark generated requests for deletion'; fa = 'Mark generated requests for deletion';
												|it = 'Mark generated requests for deletion';
												|pl = 'Mark generated requests for deletion';
												|tr = 'Oluşturulan talepleri silmek için işaretle'");
			Else
				QueryText = NStr("vi = 'Khi quay trở lại, các đơn đặt hàng được lập sẽ được đánh dấu để xóa.';
								|ru = 'При переходе назад сформированные заказы будут помечены на удаление.';
								|en = 'Generated orders will be marked to deletion while going back.'; fa = 'Generated orders will be marked to deletion while going back.';
								|it = 'Tornando indietro gli ordini generati verranno contrassegnati per l''eliminazione.';
								|pl = 'Podczas przejścia z powrotem utworzone zamówienia będą zaznaczone do usunięcia.';
								|tr = 'Geri dönüşte oluşturulan siparişler silinmek üzere işaretlenecektir.'");
				PresentationOfYesButton = NStr("vi = 'Đặt dấu xóa đơn hàng đã tạo';
												|ru = 'Пометить на удаление сформированные заказы';
												|en = 'Mark generated orders for deletion'; fa = 'Mark generated orders for deletion';
												|it = 'Contrassegnare per l''eliminazione gli ordini generati';
												|pl = 'Zaznacz do usunięcia utworzone zamówienia';
												|tr = 'Oluşturulan siparişleri silmek için işaretle'");
			EndIf;
			Buttons.Add(DialogReturnCode.Yes, PresentationOfYesButton);
			Buttons.Add(DialogReturnCode.Cancel);
			
			ShowQueryBox(New CallbackDescription("BackCompletion", ThisObject), QueryText, Buttons);
			Return;
			
		EndIf;
		
		BackFragment();
		
	ElsIf Items.Assistant.CurrentPage = Items.StepOrderEditing Then
		
		If Object.OrdersPendingSupply.Count() > 0 Then
			InstallAssistantPages("StepOrders");
		Else
			InstallAssistantPages("StepInventories");
		EndIf;
		
	ElsIf Items.Assistant.CurrentPage = Items.DemandStep And
		Items.PagesDemandTable.CurrentPage = Items.PageTableOrders Then
		
		GetConfirmationOfClearingOrdersToProvideTable(New CallbackDescription("BackAfterConfirmation", ThisObject));
		
	ElsIf Items.Assistant.CurrentPage = Items.DemandStep Then
		
		If ShoppingCartTotalFieldTotalLines > 0 Then
			ClearingNeedsTableIsIssue("StepBack");
		Else
			ClearMessages();
			InstallAssistantPages("StepCustomizeSupplyMethods");
		EndIf;
		
	ElsIf Items.Assistant.CurrentPage = Items.StepCustomizeSupplyMethods Then
		
		ClearMessages();
		InstallAssistantPages("StepDemandFilter");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BackAfterConfirmation(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	ChangeMarkToAllLines("OrdersPendingSupply", False);
	
	Object.OrdersPendingSupply.Clear();
	
	// Recalculating rounding for all marked lines
	For Each String In Object.Inventories Do
		If String.Mark Then
			// There are no duplicate rows in the Inventory table. Each line is rounded separately
			
			RowsMap = New Map();
			RowsMap.Insert(String, True);
			RoundUpMatchingRows(RowsMap, UsePackages);
		EndIf;
	EndDo;
	
	If Object.Inventories.Count() = 0 Then
		
		InstallAssistantPages("StepCustomizeSupplyMethods");
		ClearIndexTree(True);
		
	Else
		
		InstallAssistantPages("StepInventories");
		ClearIndexTree(False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BackCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	BackFragment();
	
EndProcedure

&AtClient
Procedure BackFragment()
	
	ClearMessages();
	
	TimeConsumingOperation = DeletingOrdersInBackground();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisForm);
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation,
		New CallbackDescription("DeletingOrdersInBackgroundCompletion", ThisForm),
		IdleParameters);
	
EndProcedure

&AtClient
Procedure Next(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Command.Next");
	
	ClearMessages();
	
	If Items.Assistant.CurrentPage = Items.StepDemandFilter Then
		
		If Not ValueIsFilled(PurchaseObjective) Then
			
			ErrorText = CommonClientServer.FillingErrorText(
				"Field",
				"FillType",
				NStr("vi = 'Mục đích mua hàng';
					|ru = 'Цель закупки';
					|en = 'Purchase objective'; fa = 'هدف خرید';
					|it = 'Purchase objective';
					|pl = 'Purchase objective';
					|tr = 'Satın alma amacı'"));
			
			CommonClient.MessageToUser(ErrorText,, "PurchaseObjective");
			
			Return;
		
		EndIf;
		
		TimeConsumingOperation = GettingTableOfSupportMethodsInBackground();
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisForm);
		
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation,
			New CallbackDescription("GettingTableOfSupportMethodsInBackgroundCompletion", ThisForm),
			IdleParameters);
		
	ElsIf Items.Assistant.CurrentPage = Items.StepCustomizeSupplyMethods And ThereIsInventoryStep Then
		
		If MethodTableIsFilledInCorrectly() Then
			
			TimeConsumingOperation = GettingInventoryTableInBackground();
			
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisForm);
			
			TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation,
				New CallbackDescription("GettingInventoryTableInBackgroundCompletion", ThisForm),
				IdleParameters);
			
		EndIf;
		
	ElsIf Items.Assistant.CurrentPage = Items.StepCustomizeSupplyMethods And Not ThereIsInventoryStep Then
		
		If MethodTableIsFilledInCorrectly() Then
			
			TimeConsumingOperation = GettingTableOfOrdersForCollateralInBackground();
			
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisForm);
			
			TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation,
				New CallbackDescription("GettingTableOfOrdersForCollateralInBackgroundCompletion", ThisForm),
				IdleParameters);
				
		EndIf;
		
	ElsIf Items.Assistant.CurrentPage = Items.DemandStep
				And Items.PagesDemandTable.CurrentPage = Items.PageTableInventory Then
		
		TimeConsumingOperation = GettingTableOfOrdersForCollateralInBackground();
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisForm);
		
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation,
			New CallbackDescription("GettingTableOfOrdersForCollateralInBackgroundCompletion", ThisForm),
			IdleParameters);
			
	ElsIf Items.Assistant.CurrentPage = Items.DemandStep
		And Items.PagesDemandTable.CurrentPage = Items.PageTableOrders Then
		
			Preview.GetItems().Clear();
			TimeConsumingOperation = CreatingOrderTreeInBackground();
			
			IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisForm);
		
			TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation,
				New CallbackDescription("GoToEditOrdersEnd", ThisForm),
				IdleParameters);
		
	ElsIf Items.Assistant.CurrentPage = Items.StepOrderEditing Then
		
		GoToDocumentsStepOnClient();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinueWithOtherFilters(Command)

	ClearMessages();
	ContinueWithOtherSelectionsOnServer();

EndProcedure

&AtClient
Procedure ConfigureInventoryLevelControl(Command)
	
	ParametersOfSelectionForm = New Structure("Warehouse", FilterByWarehouse);
	FormParameters = New Structure("Filter, Source", ParametersOfSelectionForm, "DemandFulfillment");
	OpenForm("DataProcessor.SetUpStockReplenishment.Form.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure ConfigureConsumptionStatisticsCalculation(Command)
	
	OpenForm("DataProcessor.SetUpStockReplenishment.Form.CustomizeSettingsOfAverageDailyConsumptionCalculation",, ThisForm);
	
EndProcedure

&AtClient
Procedure SelectCheckBoxesInTheSupplyMethodsTable(Command)

	ChangeCheckboxesInSecurityMethodsTable(True);

EndProcedure

&AtClient
Procedure ClearCheckBoxesInTheSupplyMethodTable(Command)

	ChangeCheckboxesInSecurityMethodsTable(False);

EndProcedure

&AtClient
Procedure FillInForOrderTheGoodsThatHaveReachedTheOrderPointForSelectedLines(Command)
	FillInProductsForOrder(False);
EndProcedure

&AtClient
Procedure ShowHideTheRecommendationsPanel(Command)

		Items.RecommendationsStocks.Check = Not Items.RecommendationsStocks.Check;
		Items.RecommendationsOrders.Check = Not Items.RecommendationsOrders.Check;
		Items.RecommendationBar.Visible = Items.RecommendationsStocks.Check;

EndProcedure

&AtClient
Procedure FillInForOrderAllGoodsForSelectedLines(Command)
	FillInProductsForOrder(True);
EndProcedure

&AtClient
Procedure AddInventoryToTheOrder(Command)

	ChangeMark_("Inventories", True);
	
	CurrentRow = Items.Inventories.CurrentData;
	
	DisplayCalculatedRounding(CurrentRow, True);

EndProcedure

&AtClient
Procedure UnmarkInventory(Command)

	ChangeMark_("Inventories", False);
	
	CurrentRow = Items.Inventories.CurrentData;
	
	DisplayCalculatedRounding(CurrentRow, True);

EndProcedure

&AtClient
Procedure MarkToOrderOrders(Command)
	
	ChangeMark_("OrdersPendingSupply", True);
	
	CurrentRow = Items.OrdersPendingSupply.CurrentData;
	
	DisplayCalculatedRounding(CurrentRow, False);
	
EndProcedure

&AtClient
Procedure UnmarkOrders(Command)
	
	ChangeMark_("OrdersPendingSupply", False);
	
	CurrentRow = Items.OrdersPendingSupply.CurrentData;
	
	DisplayCalculatedRounding(CurrentRow, False);
	
EndProcedure

&AtClient
Procedure FillInTheSupplier(Command)
	
	TypesArray = New Array();
	TypesArray.Add(PredefinedValue("Enum.SupplyTypes.Purchase"));
	TypesArray.Add(PredefinedValue("Enum.SupplyTypes.ProductionByThirdParty"));
	FillInSourceOfProvision(TypesArray);
	
EndProcedure

&AtClient
Procedure FillInTheWarehouse(Command)

	TypesArray = New Array();
	TypesArray.Add(PredefinedValue("Enum.SupplyTypes.Move"));
	FillInSourceOfProvision(TypesArray);
	
EndProcedure

&AtClient
Procedure FillInTheDepartment(Command)

	TypesArray = New Array();
	TypesArray.Add(PredefinedValue("Enum.SupplyTypes.Production"));
	FillInSourceOfProvision(TypesArray);
	
EndProcedure

&AtClient
Procedure FillInManager_(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Form.Command.FillInManager_");
	
	Notification = New CallbackDescription("FillInManager_Completion", ThisObject);
	OpenManagerSelectionForm(Notification);
	
EndProcedure

&AtClient
Procedure FillInDeliveryDate(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Form.Command.FillInDeliveryDate");
	
	CallbackDescription = New CallbackDescription("FillInDeliveryDateAfterEnteringValue", ThisObject);
	ShipmentDate = CommonClient.SessionDate();
	ShowInputDate(CallbackDescription, ShipmentDate, NStr("vi = 'Nhập ngày giao hàng';
															|ru = 'Введите дату поставки';
															|en = 'Enter delivery date'; fa = 'Enter delivery date';
															|it = 'Inserire la data di consegna';
															|pl = 'Wprowadź datę dostawy';
															|tr = 'Tedarik tarihini girin'"), DateFractions.Date);
	
EndProcedure

&AtClient
Procedure FillInDeliveryDateAfterEnteringValue(Date, AdditionalParameters) Export
	
	If Date = Undefined Then
		Return;
	EndIf;
	
	CurrentTable = ?(Items.PagesDemandTable.CurrentPage = Items.PageTableInventory,
		"Inventories", "OrdersPendingSupply");
	
	For Each Id In Items[CurrentTable].SelectedRows Do
		
		Shipment = Object[CurrentTable].FindByID(Id);
		
		If Shipment.Mark Then
			CalculateTotals();
		EndIf;
		Shipment.ShipmentDate = Date;
		QuantityToOrder_ = Shipment.Rounded * ?(Shipment.Mark, 1, 0);
		CalculateTotals();
		
	EndDo;
	
EndProcedure

&AtClient
Procedure InformationBarURLProcessing(Item, Var_URL, StandardProcessing)
	
	If Var_URL = "OpenPackageSelectionForm" Then
		StandardProcessing = False;
		
		If Items.PagesDemandTable.CurrentPage = Items.PageTableInventory Then
			SelectPackagingClient("Inventories");
		Else
			SelectPackagingClient("OrdersPendingSupply");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateGeneratedOrders(Command)
	UpdateValuesOfDocumentTableDetails();
EndProcedure

&AtClient
Procedure TheOrderToTheSupplierIsConfirmed(Command)
	
	ClearMessages();
	
	ReferencesArrray = New Array();
	For Each Id In Items.GeneratedOrders.SelectedRows Do
		ListLine = TableDocuments.FindByID(Id);
		If TypeOf(ListLine.Document) = Type("DocumentRef.PurchaseOrder") Then
			ReferencesArrray.Add(New Structure("Ref, RowID", ListLine.Document, Id));
		EndIf;
	EndDo;
	
	If ValueIsFilled(ReferencesArrray) Then
		SetStatusOnServer(ReferencesArrray, "Confirmed_");
	Else
		CommonClientServer.MessageToUser(NStr("vi = 'Không thể đặt trạng thái. Không có đơn hàng nào được chọn cho nhà cung cấp';
												|ru = 'Невозможно установить статус. Не выбраны заказы поставщику';
												|en = 'Cannot set the status. Purchase orders are not selected'; fa = 'Cannot set the status. Purchase orders are not selected';
												|it = 'Impossibile impostare lo stato. Nessun ordine al fornitore selezionato';
												|pl = 'Nie można ustawić statusu. Nie wybrano żadnych zamówień dostawców';
												|tr = 'Durum ayarlanamıyor. Tedarik siparişi seçilmedi'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure OrderToTheProcessorForExecution(Command)
	ClearMessages();
	
	ReferencesArrray = New Array();
	For Each Id In Items.GeneratedOrders.SelectedRows Do
		ListLine = TableDocuments.FindByID(Id);
		If TypeOf(ListLine.Document) = Type("DocumentRef.SubcontractOrder2_5")
		 Or False Then
			ReferencesArrray.Add(New Structure("Ref, RowID", ListLine.Document, Id));
		EndIf;
	EndDo;
	
	If ValueIsFilled(ReferencesArrray) Then
		SetStatusOnServer(ReferencesArrray, "ForFulfillment");
	Else
		CommonClient.MessageToUser(NStr("vi = 'Không thể đặt trạng thái. Không có đơn hàng nào được chọn cho gia công';
										|ru = 'Невозможно установить статус. Не выбраны заказы переработчику';
										|en = 'Cannot set the status. Subcontracting purchase orders are not selected'; fa = 'Cannot set the status. Subcontracting purchase orders are not selected';
										|it = 'Impossibile impostare lo stato. Nessun ordine al subfornitore selezionato';
										|pl = 'Nie można ustawić statusu. Nie wybrano żadnych zamówień przetwórstwa';
										|tr = 'Durum ayarlanamıyor. Fason satın alma siparişi seçilmedi'"));
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure ProductionOrderForProduction(Command)
	ClearMessages();
	
	ReferencesArrray = New Array();
	For Each Id In Items.GeneratedOrders.SelectedRows Do
		ListLine = TableDocuments.FindByID(Id);
		If TypeOf(ListLine.Document) = Type("DocumentRef.ProductionOrder2_2")
		Then
			ReferencesArrray.Add(New Structure("Ref, RowID", ListLine.Document, Id));
		EndIf;
	EndDo;
	
	If ValueIsFilled(ReferencesArrray) Then
		SetStatusOnServer(ReferencesArrray, "ToProduce");
	Else
		CommonClient.MessageToUser(NStr("vi = 'Không thể đặt trạng thái. Không có đơn đặt hàng sản xuất được chọn';
										|ru = 'Невозможно установить статус. Не выбраны заказы на производство';
										|en = 'Cannot set the status. No production orders are selected'; fa = 'Cannot set the status. No production orders are selected';
										|it = 'Impossibile impostare lo stato. Nessun ordine di produzione selezionato';
										|pl = 'Nie można ustawić statusu. Nie wybrano żadnych zamówień produkcyjnych';
										|tr = 'Durum ayarlanamıyor. Üretim emri seçilmedi'"));
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure ExpandLines(Command)
	
	TreeItemsCollection=Preview.GetItems();
	
	For Each String In TreeItemsCollection Do
		RowID=String.GetID();
		Items.Preview.Expand(RowID);
	EndDo;
	
EndProcedure

&AtClient
Procedure CollapseLines(Command)
	
	TreeItemsCollection=Preview.GetItems();
	
	For Each String In TreeItemsCollection Do
		RowID=String.GetID();
		Items.Preview.Collapse(RowID);
	EndDo;
	
EndProcedure

&AtClient
Procedure ShowHideWarningsClick(Item)
	
	ShowHideWarning();
	
EndProcedure

&AtClient
Procedure ChangeWarehouse(Command)
	
	OpenForm(
		"Catalog.Warehouses.Form.ChoiceForm",
		New Structure("ChoiceFoldersAndItems", FoldersAndItemsUse.Items),
		ThisObject,
		,
		,
		,
		New CallbackDescription("SelectWarehouseCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure ChangeManager(Command)
	
	Notification = New CallbackDescription("ManagerSelectionEnd", ThisObject);
	OpenManagerSelectionForm(Notification);
	
EndProcedure

&AtClient
Procedure ChangeFulfillmentMethod(Command)
	
	OpeningParameters = New Structure;
	If ValueIsFilled(FilterBySupplyType) Then
		OpeningParameters.Insert("Filter", New Structure);
		OpeningParameters.Filter.Insert("SupplyType", CommonClientServer.ValueInArray(FilterBySupplyType));
	EndIf;
	
	OpenForm(
		"Catalog.ProcurementStrategies.Form.ChoiceForm", OpeningParameters,
		ThisObject,,,, New CallbackDescription("ChoosingSecurityMethod", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

#EndRegion

#Region Private

#Region StepCustomizeSupplyMethods

&AtServer
Function GettingTableOfSupportMethodsInBackground()
	
	If ShouldSaveSettings Then
		ShouldSaveSettings();
	EndIf;
	
	ProcedureParameters = New Structure();
	ProcedureParameters.Insert("Settings", FilterSettingsComposer.GetSettings());
	ProcedureParameters.Insert("GoodsOfSupportedStock", ThereIsInventoryStep);
	ProcedureParameters.Insert("SupplyMethod", Undefined);
	ProcedureParameters.Insert("PurposeUseKey", PurposeUseKey);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập giấy đề nghị: nhận bảng phương pháp đảm bảo';
															|ru = 'Формирование заявок: получение таблицы способов обеспечения';
															|en = 'Generate requests: receive the procurement strategy table'; fa = 'Generate requests: receive the procurement strategy table';
															|it = 'Generate requests: receive the procurement strategy table';
															|pl = 'Generate requests: receive the procurement strategy table';
															|tr = 'Taleplerin oluşturulması: tedarik yöntemleri tablosunun elde edilmesi'");
	Else
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập đơn hàng: nhận bảng phương pháp đảm bảo';
															|ru = 'Формирование заказов: получение таблицы способов обеспечения';
															|en = 'Generate orders: receive the procurement strategy table'; fa = 'Generate orders: receive the procurement strategy table';
															|it = 'Generazione ordini: ricezione della tabella delle modalità di approvvigionamento';
															|pl = 'Zamawianie: uzyskanie tabeli sposobów dostarczenia';
															|tr = 'Siparişlerin oluşturulması: tedarik yöntemleri tablosunun elde edilmesi'");
	EndIf;
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.DemandFulfillment.TableOfSecurityMethods",
		ProcedureParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure GettingTableOfSupportMethodsInBackgroundCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	ElsIf Not NextGoToStepConfiguringSecurityMethodsOnServer(Result) Then
		ReportNoNeeds();
	EndIf;
	
EndProcedure

&AtServer
Function GettingInventoryTableInBackground()
	
	TableWaysToEnsure = Object.SupplyMethods.Unload(New Structure("Mark", True));
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("FilterType", "LayoutSelections");
	ProcedureParameters.Insert("Filter", FilterSettingsComposer.UserSettings);
	ProcedureParameters.Insert("TableOfSecurityMethods", TableWaysToEnsure);
	ProcedureParameters.Insert("GeneratePurchaseRequests", GeneratePurchaseRequests);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập giấy đề nghị: nhận bảng hàng tồn kho';
															|ru = 'Формирование заявок: получение таблицы запасов';
															|en = 'Generate requests: receive the inventory table'; fa = 'Generate requests: receive the inventory table';
															|it = 'Generate requests: receive the inventory table';
															|pl = 'Generate requests: receive the inventory table';
															|tr = 'Taleplerin oluşturulması: stok tablosunun elde edilmesi'");
	Else
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập đơn hàng: nhận bảng hàng tồn kho';
															|ru = 'Формирование заказов: получение таблицы запасов';
															|en = 'Generate orders: receive the inventory table'; fa = 'Generate orders: receive the inventory table';
															|it = 'Generazione ordini: ricezione della tabella delle scorte';
															|pl = 'Formowanie zamówień: uzyskanie tabeli spisów';
															|tr = 'Siparişlerin oluşturulması: stok tablosu elde edilmesi'");
	EndIf;
		
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.DemandFulfillment.TableInventory",
		ProcedureParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure GettingInventoryTableInBackgroundCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	ElsIf Not NextToInventoryStep(Result) Then
		
		TimeConsumingOperation = GettingTableOfOrdersForCollateralInBackground();
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisForm);
		
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation,
			New CallbackDescription("GettingTableOfOrdersForCollateralInBackgroundCompletion", ThisForm),
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Function GettingTableOfOrdersForCollateralInBackground()
	
	Filter = New Structure("Mark", True);
	TableInventory = Object.Inventories.Unload(Filter, "Products,Characteristic,Warehouse,ToOrder,Mark,IndexID");
	TableWaysToEnsure = Object.SupplyMethods.Unload(Filter);
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("FilterType", "LayoutSelections");
	ProcedureParameters.Insert("Filter", FilterSettingsComposer.UserSettings);
	ProcedureParameters.Insert("TableOfSecurityMethods", TableWaysToEnsure);
	ProcedureParameters.Insert("TableInventory", TableInventory);
	ProcedureParameters.Insert("GeneratePurchaseRequests", GeneratePurchaseRequests);
	ProcedureParameters.Insert("CalculationOfSeparateNeedsTakingIntoAccountBalancesInAllWarehouses",
		CalculationOfSeparateNeedsTakingIntoAccountBalancesInAllWarehouses);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập giấy đề nghị: nhận bảng đơn đặt hàng cho đảm bảo';
															|ru = 'Формирование заявок: получение таблицы заказов к обеспечению';
															|en = 'Generate requests: receive the table of orders to supply'; fa = 'Generate requests: receive the table of orders to supply';
															|it = 'Generate requests: receive the table of orders to supply';
															|pl = 'Generate requests: receive the table of orders to supply';
															|tr = 'Taleplerin oluşturulması: tedarik edilecek siparişler tablosunun elde edilmesi'");
	Else
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập đơn hàng: nhận bảng đơn đặt hàng cho đảm bảo';
															|ru = 'Формирование заказов: получение таблицы заказов к обеспечению';
															|en = 'Generate orders: receive the table of orders to supply'; fa = 'Generate orders: receive the table of orders to supply';
															|it = 'Generazione ordini: ricezione della tabella degli ordini di approvvigionamento';
															|pl = 'Formowanie zamówień: uzyskanie tabeli zamówień do zabezpieczenia';
															|tr = 'Siparişlerin oluşturulması: tedarik edilecek siparişlerin tablosunun elde edilmesi'");
	EndIf;
	
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.DemandFulfillment.TableOfOrderRequirementsAndBalances",
		ProcedureParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure GettingTableOfOrdersForCollateralInBackgroundCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	ElsIf Not NextToOrdersStep(Result) Then
		GoToEditOrdersEnd(Result, AdditionalParameters);
		Preview.GetItems().Clear();
		TimeConsumingOperation = CreatingOrderTreeInBackground();
			
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisForm);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation,
			New CallbackDescription("GoToEditOrdersEnd", ThisForm),
			IdleParameters);
	EndIf;
	
EndProcedure

&AtServer
Function CreatingOrderTreeInBackground()
	
	OrderTree = FormAttributeToValue("Preview");
	
	ProcedureParameters = New Structure();
	ProcedureParameters.Insert("OrderTree", OrderTree);
	ProcedureParameters.Insert("Inventories", Object.Inventories.Unload(,"SupplySource, Warehouse, SupplyMethod, Manager, 
								|MaximumInventory, MinimumDeliveryLot, TransferIsAllowed,
								|Terms, Products, Characteristic, OrderPackage, ToOrder,
								|PriceInTheCurrencyOfAgreement, AgreementCurrencyAmount, SupplySourceViewOnly,
								|Mark, Rounded, UnitOfMeasure, AgreementCurrency, Weight,
								|MinimumOrderAmount, SupplyType, PriceKind, UnitOfMeasureType, RecommendedToOrder"));
	ProcedureParameters.Insert("OrdersPendingSupply", Object.OrdersPendingSupply.Unload(,"SupplySource, Warehouse,
								|SupplyMethod, Manager, Required2, MinimumDeliveryLot, TransferIsAllowed,
								|Terms, Products, Characteristic, OrderPackage, ToOrder, ThisIsWork,
								|PriceInTheCurrencyOfAgreement, AgreementCurrencyAmount, SupplySourceViewOnly,
								|Mark, Rounded, UnitOfMeasure, AgreementCurrency, Weight,
								|MinimumOrderAmount, SupplyType, PriceKind, UnitOfMeasureType, RecommendedToOrder"));
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập giấy đề nghị';
															|ru = 'Формирование заявок';
															|en = 'Generate requests'; fa = 'Generate requests';
															|it = 'Generate requests';
															|pl = 'Generate requests';
															|tr = 'Başvuru oluşturma'");
	Else
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập đơn hàng';
															|ru = 'Формирование заказов';
															|en = 'Generate orders'; fa = 'ایجاد سفارش‌ها';
															|it = 'Generazione degli ordini';
															|pl = 'Tworzenie zamówień';
															|tr = 'Siparişleri oluşturma'");
	EndIf;
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.DemandFulfillment.CreateOrderTree",
		ProcedureParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure GoToEditOrdersEnd(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	Else
		NextToOrderEditingStep(Result);
	EndIf;
	
EndProcedure

&AtServer
Function CreatingOrdersInBackground()
	
	SectionsForUnloading = "NeedProperties, DetailsOfProvidingOrder, OrderDetailsToBeSecured";
	Fields = DataProcessors.DemandFulfillment.FieldsInOrdersTable(SectionsForUnloading);
	Fields.Insert("PackageNumerator", New TypeDescription("Number"));
	Fields.Insert("PackageDenominator", New TypeDescription("Number"));
	Fields.Insert("UnitOfMeasureType", New TypeDescription("EnumRef.TypesOfMeasuredValues"));
	Fields.Insert("Mark", New TypeDescription("Boolean"));
	Fields.Insert("OrderPackage", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Fields.Insert("MinimumDeliveryLot", New TypeDescription("Number"));
	Fields.Insert("DoNotRoundBeforeCreatingOrder", New TypeDescription("Boolean"));
	
	TableOfNeeds = New ValueTable();
	For Each Field In Fields Do
		TableOfNeeds.Columns.Add(Field.Key, Field.Value);
	EndDo;
	UploadItemsMarkedToOrder(TableOfNeeds, "OrdersPendingSupply");
	UploadItemsMarkedToOrder(TableOfNeeds, "Inventories");
	
	DocumentsTable = TableDocuments.Unload(New Array);
	OrderPlacementResultAddress = PutToTempStorage(Undefined, UUID);
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("TableOfNeeds", TableOfNeeds);
	ProcedureParameters.Insert("UsePackages", UsePackages);
	ProcedureParameters.Insert("PurchaseObjective", PurchaseObjective);
	ProcedureParameters.Insert("OrderPlacementResultAddress", OrderPlacementResultAddress);
	ProcedureParameters.Insert("DocumentsTable", DocumentsTable);
	ProcedureParameters.Insert("GeneratePurchaseRequests", GeneratePurchaseRequests);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập giấy đề nghị: tạo chứng từ';
															|ru = 'Формирование заявок: создание документов';
															|en = 'Generate requests: create documents'; fa = 'Generate requests: create documents';
															|it = 'Generate requests: create documents';
															|pl = 'Generate requests: create documents';
															|tr = 'Taleplerin oluşturulması: belge oluşturma'");
	Else
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập đơn hàng: tạo chứng từ';
															|ru = 'Формирование заказов: создание документов';
															|en = 'Order generation: document creation'; fa = 'Order generation: document creation';
															|it = 'Generazione ordini: creazione documenti';
															|pl = 'Tworzenie zamówień: tworzenie dokumentów';
															|tr = 'Siparişleri oluşturma: belge oluşturma'");
	EndIf;
		
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.DemandFulfillment.ToFormTheOrders",
		ProcedureParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure CreatingOrdersInBackgroundCompletion(Result, AdditionalParameters) Export
	
	Notifications = NextToGeneratedOrdersStep(Result);
	
	If ValueIsFilled(Notifications) Then // If there are no alerts, then the documents have not been generated
		
		For Each Notification In Notifications Do
			Notify(Notification.EventName, Notification.NotificationParameters, Notification.Source);
		EndDo;
		
		ProcessingOfDocumentWritingNotificationsIsEnabled = True;
		
	EndIf;
	
	If Result <> Undefined And Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	EndIf;
	
EndProcedure

&AtServer
Function DeletingOrdersInBackground()
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("RemovalLinks", GeneratedOrders.UnloadValues());
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập giấy đề nghị: xóa chứng từ';
															|ru = 'Формирование заявок: удаление документов';
															|en = 'Generate requests: delete documents'; fa = 'Generate requests: delete documents';
															|it = 'Generate requests: delete documents';
															|pl = 'Generate requests: delete documents';
															|tr = 'Taleplerin oluşturulması: belgeleri silme'");
	Else
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập đơn hàng: xóa chứng từ';
															|ru = 'Формирование заказов: удаление документов';
															|en = 'Order generation: document deletion'; fa = 'Order generation: document deletion';
															|it = 'Generazione ordini: cancellazione documenti';
															|pl = 'Tworzenie zamówień: usunięcie dokumentów';
															|tr = 'Siparişleri oluşturma: belgeleri silme'");
	EndIf;
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.DemandFulfillment.DeleteOrders",
		ProcedureParameters, ExecutionParameters);
	
EndFunction

&AtClient
Procedure DeletingOrdersInBackgroundCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	ElsIf Result.Status = "Error" Then
		ShowMessageBox(, Result.BriefErrorDescription);
	Else
		BackToStepsOfSelectingNeedsOnClient(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeCheckboxesInSecurityMethodsTable(Install)
	For Each TableRow In Object.SupplyMethods Do
		TableRow.Mark = Install;
	EndDo;
EndProcedure

&AtClient
Procedure FillInProductsForOrder(ThisIsPlannedOrder)

	RowsIDs = Items.SupplyMethods.SelectedRows;
	For Each Id In RowsIDs Do
		TableRow = Object.SupplyMethods.FindByID(Id);
		TableRow.DemandConversionOption = ThisIsPlannedOrder;
		ProvisionInDocumentsClient.FillInDatesInSecondStepOfDemandFulfillment(TableRow);
		TableRow.LineChanged = True;
	EndDo;
	
	If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
		MessageText = NStr("vi = 'Đã thiết lập giá trị mới trong cột: ""Cần đặt hàng"". Đã xử lý, tổng số dòng: %1';
							|ru = 'Установлено новое значение в колонке: ""К заказу товары"". Всего обработано строк: %1';
							|en = 'New value is specified in the column: ""Demand conversion option"". Total number of processed lines: %1'; fa = 'New value is specified in the column: ""Demand conversion option"". Total number of processed lines: %1';
							|it = 'Установлено новое значение в колонке: ""К заказу товары"". Всего обработано строк: %1';
							|pl = 'New value is specified in the column: ""Demand conversion option"". Total number of processed lines: %1';
							|tr = 'Sütuna yeni bir değer eklendi: ""Sipariş edilecek mallar"". Toplam işlenen satır sayısı: %1'");
	Else
		MessageText = NStr("vi = 'Đã thiết lập giá trị mới trong cột: ""Cần đặt hàng"". Đã xử lý, tổng số dòng: %1';
							|ru = 'Установлено новое значение в колонке: ""К заказу товары"". Всего обработано строк: %1';
							|en = 'New value is specified in the column: ""Demand conversion option"". Total number of processed lines: %1'; fa = 'New value is specified in the column: ""Demand conversion option"". Total number of processed lines: %1';
							|it = 'Установлено новое значение в колонке: ""К заказу товары"". Всего обработано строк: %1';
							|pl = 'New value is specified in the column: ""Demand conversion option"". Total number of processed lines: %1';
							|tr = 'Sütuna yeni bir değer eklendi: ""Sipariş edilecek mallar"". Toplam işlenen satır sayısı: %1'");
	EndIf;
	
	MessageText = StrTemplate(
		MessageText,
		RowsIDs.Count());
	
	ShowUserNotification(NStr("vi = 'Xử lý dòng';
								|ru = 'Обработка строк';
								|en = 'Line processing'; fa = 'Line processing';
								|it = 'Elaborazione delle righe';
								|pl = 'Przetwarzanie wierszy';
								|tr = 'Satır işleme'"), , MessageText);

EndProcedure

&AtServer
Procedure SetAccessibilityOfFormElementsByRights()

	AccessRights = SupplyServer.WriteAccessRightsForMethodOrMethod();
	If Not AccessRights.SupplyOptions Then
		
		Items.MethodOfSecuringStocks.Enabled = False;
		Items.MethodOfSecuringStocks.HeaderPicture = New Picture();
		Items.MethodOfSecuringOrders.Enabled = False;
		Items.MethodOfSecuringOrders.HeaderPicture = New Picture();
		Items.SupplyMethodsSupplyMethod.Enabled = False;
		
	EndIf;
	
	If Not AccessRights.ProductRestrictions Then
		
		Items.ConfigureInventoryLevelControl.Enabled = False;
		
	EndIf;

EndProcedure

&AtClient
Procedure AssuranceMethodsWhenAssuranceMethodChanges()
	
	TableRow = Items.SupplyMethods.CurrentData;
	If TableRow = Undefined
		Or Items.Assistant.CurrentPage <> Items.StepCustomizeSupplyMethods Then
		Return;
	EndIf;
	
	Attributes = DataFillingInRowOfSupplyMethodsTable(
		TableRow.SupplyMethod,
		PurposeUseKey);
		
	FillPropertyValues(TableRow, Attributes);
	
EndProcedure

&AtServerNoContext
Function DataFillingInRowOfSupplyMethodsTable(Ref, Val PurposeUseKey)
	
	ProcedureParameters = New Structure();
	ProcedureParameters.Insert("Settings", Undefined);
	ProcedureParameters.Insert("GoodsOfSupportedStock", Undefined);
	ProcedureParameters.Insert("SupplyMethod", Ref);
	ProcedureParameters.Insert("PurposeUseKey", PurposeUseKey);
	Address = PutToTempStorage(Undefined);
	DataProcessors.DemandFulfillment.TableOfSecurityMethods(ProcedureParameters, Address);
	Table = GetFromTempStorage(Address);
	Result = New Structure();
	For Each Column In Table.Columns Do
		Result.Insert(Column.Name);
	EndDo;
	FillPropertyValues(Result, Table[0]);
	DeleteFromTempStorage(Address);
	Return Result;
	
EndFunction

#EndRegion

#Region StepInventories

&AtClient
Procedure ReservesWhenActivatingWaitHandlerLine()

	String = Items.Inventories.CurrentData;
	
	If String = Undefined Then
		
		Items.RecommendationBar.CurrentPage = Items.PageLineNotSelected;
		
	Else
		
		FormatLine = "NFD=3; NZ=0.000";
		UnitOfMeasure = String.UnitOfMeasure;
		
		Balance = CaptionInFormat(String.Balance, UnitOfMeasure, FormatLine);
		OrdersPendingGoodsReceipt = CaptionInFormat(String.OrdersPendingGoodsReceipt,   UnitOfMeasure, FormatLine);
		MinimumInventory   = CaptionInFormat(String.MinimumInventory,     UnitOfMeasure, FormatLine);
		MaximumInventory  = CaptionInFormat(String.MaximumInventory,    UnitOfMeasure, FormatLine);
		SafetyStock     = CaptionInFormat(String.SafetyStock,       UnitOfMeasure, FormatLine);
		BeforeTheOrderPoint      = CaptionInFormat(String.BeforeTheOrderPoint,        UnitOfMeasure, FormatLine);
		QuantityToOrderText  = CaptionInFormat(String.RecommendedToOrder, UnitOfMeasure, FormatLine);
		AverageDailyConsumption = CaptionInFormat(String.AverageDailyConsumption, UnitOfMeasure, FormatLine);
		DeliveryPeriodDays = StrTemplate(NStr("vi = '%1 ngày';
												|ru = '%1 дн';
												|en = '%1 days'; fa = '%1 days';
												|it = '%1 дн';
												|pl = '%1 dn';
												|tr = '%1 gün'"), String.DeliveryPeriodDays);
		CoveredPeriod = StrTemplate(NStr("vi = '%1 ngày';
										|ru = '%1 дн';
										|en = '%1 days'; fa = '%1 days';
										|it = '%1 дн';
										|pl = '%1 dn';
										|tr = '%1 gün'"), String.CoveredPeriod);
		
		FormatLine = "DLF=D";
		
		MinMaxMethod = String.StrategyOfProcurement
		= PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentMinMax");
		
		If String.DemandConversionOption = 0 Then // order by reordering point
			
			If String.BeforeTheOrderPoint > 0 Then // The reorder point hasn't been reached
				
				RecommendationText = NStr("vi = 'Không cần chỉ ra hàng hóa. Cần đợi đến điểm đặt hàng.';
											|ru = 'Не заказывать товар. Ожидать наступления точки заказа.';
											|en = 'Do not order the inventory. Wait till the reorder point.'; fa = 'Do not order the inventory. Wait till the reorder point.';
											|it = 'Non ordinare le merci. Attendere il raggiungimento del livello necessario all''ordinazione.';
											|pl = 'Nie zamawiaj towarów. Poczekaj na punkt wpływ do punktu zamówienia.';
											|tr = 'Ürün siparişi yapma. Yeniden sipariş noktası gelişini bekle.'");
				
				ThisIsPointOfOrdering = False;
				ThisIsOrderDate = False;
				Order = False;
				
			Else // The reorder point has been reached
				
				If String.OrdersPendingGoodsReceipt = 0 Then
					
					If MinMaxMethod Or String.SafetyStock = 0 Then
						RecommendationText = NStr("vi = 'Đặt số lượng bằng vật tư tối đa.';
													|ru = 'Заказать количество, равное максимальному запасу.';
													|en = 'Order the quantity equal to the maximum inventory.'; fa = 'Order the quantity equal to the maximum inventory.';
													|it = 'Ordinare una quantità pari alle scorte massime.';
													|pl = 'Zamów ilość równą maksymalnemu zapasowi.';
													|tr = 'Maksimum stok miktarına eşit miktarda sipariş yap.'");
					Else
						RecommendationText = NStr("vi = 'Đặt một số tiền bằng với hàng tồn kho tối đa trừ đi hàng tồn kho bảo hiểm, bổ sung hàng tồn kho bảo hiểm (nếu cần).';
													|ru = 'Заказать количество, равное максимальному запасу за вычетом страхового запаса, пополнить страховой запас (при необходимости).';
													|en = 'Order the quantity equal to the maximum stock minus the safety stock, replenish the safety stock (if necessary).'; fa = 'Order the quantity equal to the maximum stock minus the safety stock, replenish the safety stock (if necessary).';
													|it = 'Ordinare una quantità pari alle scorte massime meno le scorte di garanzia, rifornire le scorte di garanzia (se necessario).';
													|pl = 'Zamów ilość równą maksymalnemu zapasowi minus zapas bezpieczeństwa, uzupełnij zapasy bezpieczeństwa (jeśli to konieczne).';
													|tr = 'Maksimum stok eksi güvenlik stokuna eşit bir miktar siparişi yap, güvenlik stokunu doldur (gerektiğinde).'");
					EndIf;
					
					ThisIsPointOfOrdering = True;
					ThisIsOrderDate = False;
					Order = True;
					
				ElsIf String.OrdersPendingGoodsReceipt < String.MaximumInventory Then
					
					If MinMaxMethod Or String.SafetyStock = 0 Then
						RecommendationText = NStr("vi = 'Đặt số lượng bằng vật tư tối đa trừ số lượng đã đặt trước đó.';
													|ru = 'Заказать количество, равное максимальному запасу за вычетом заказанного ранее.';
													|en = 'Order the quantity equal to the maximum inventory minus the quantity ordered earlier.'; fa = 'Order the quantity equal to the maximum inventory minus the quantity ordered earlier.';
													|it = 'Ordinare una quantità pari alle scorte massime meno quella precedentemente ordinata.';
													|pl = 'Zamów ilość równą maksymalnemu zapasowi minus poprzednio zamówiony.';
													|tr = 'Maksimum stok eksi daha önce sipariş edilene eşit bir miktar siparişi yap.'");
					Else
						RecommendationText = NStr("vi = 'Đặt một số tiền bằng với hàng tồn kho tối đa, trừ đi hàng tồn kho bảo hiểm và trừ đi thứ tự trước đó, bổ sung hàng tồn kho bảo hiểm (nếu cần thiết).';
													|ru = 'Заказать количество, равное максимальному запасу, за вычетом страхового запаса и за вычетом заказанного ранее, пополнить страховой запас (при необходимости).';
													|en = 'Order the quantity equal to the maximum stock minus the safety stock and the quantity ordered earlier, replenish the safety stock (if necessary).'; fa = 'Order the quantity equal to the maximum stock minus the safety stock and the quantity ordered earlier, replenish the safety stock (if necessary).';
													|it = 'Ordinare una quantità pari alle scorte massime meno le scorte di garanzia e meno quella precedentemente ordinata, rifornire le scorte di garanzia (se necessario).';
													|pl = 'Zamów ilość ilość równą zapasowi maksymalnemu, pomniejszoną o zapasy bezpieczeństwa i pomniejszoną o zamówioną wcześniej ilość, uzupełnij zapasy bezpieczeństwa (jeśli to konieczne).';
													|tr = 'Maksimum stoktan güvenlik stoku ve eksi önceden sipariş edilene eşit bir miktar siparişi yap, güvenlik stokunu (gerektiğinde) yenile.'");
					EndIf;
					
					ThisIsPointOfOrdering = True;
					ThisIsOrderDate = False;
					Order = True;
					
				Else
					
					RecommendationText = NStr("vi = 'Không cần chỉ ra hàng hóa. Đơn hàng cần thiết đã được lập từ trước.';
												|ru = 'Не заказывать товар. Необходимые заказы сформированы ранее.';
												|en = 'Do not order the goods. Necessary orders were placed earlier.'; fa = 'Do not order the goods. Necessary orders were placed earlier.';
												|it = 'Non ordinare merci. Gli ordini necessari sono generati precedentemente.';
												|pl = 'Nie zamawiaj towarów. Wymagane zamówienia są generowane wcześniej.';
												|tr = 'Ürün siparişi yapma. Gerekli siparişler artık yapıldı.'");
					
					ThisIsPointOfOrdering = True;
					ThisIsOrderDate = False;
					Order = False;
					
				EndIf;
				
			EndIf;
			
		ElsIf String.DemandConversionOption = 1 Then // planned replenishment of the stock
			
			If String.BeforeTheOrderPoint <= 0 And String.SafetyStock > 0 Then
				RecommendationText = NStr("vi = 'Đặt số tiền để bổ sung vào hàng tồn kho tối đa, bổ sung hàng tồn kho bảo hiểm (nếu cần thiết).';
											|ru = 'Заказать количество для пополнения до максимального запаса, пополнить страховой запас (при необходимости).';
											|en = 'Order quantity to replenish up to a maximum inventory, replenish safety stock (if needed).'; fa = 'Order quantity to replenish up to a maximum inventory, replenish safety stock (if needed).';
											|it = 'Ordinare la quantità per il rifornimento delle scorte fino al massimo, integrare le scorte di garanzia (se necessario).';
											|pl = 'Zamów ilość do uzupełnienia do maksymalnej ilości, uzupełnij zapas bezpieczeństwa (jeśli to konieczne).';
											|tr = 'Maksimum stoka kadar doldurulacak miktarı sipariş et, güvenlik stokunu (gerektiğinde) doldur.'");
			Else
				RecommendationText = NStr("vi = 'Đặt số lượng để bổ sung đến vật tư tối đa.';
											|ru = 'Заказать количество для пополнения до максимального запаса.';
											|en = 'Order the quantity to replenish the inventory level up to the maximum level.'; fa = 'Order the quantity to replenish the inventory level up to the maximum level.';
											|it = 'Ordinare la quantità per il rifornimento delle scorte fino al massimo.';
											|pl = 'Zamów ilość do uzupełnienia do maksimum zapasów.';
											|tr = 'Maksimum stoka kadar doldurulacak miktar sipariş et.'");
			EndIf;
			
			ThisIsPointOfOrdering = String.BeforeTheOrderPoint <= 0;
			ThisIsOrderDate  = True;
			Order = True;
			
		Else // do not order items
			
			RecommendationText = NStr("vi = 'Không cần chỉ ra hàng hóa. Cần đợi đến ngày đặt hàng theo lịch biểu.';
										|ru = 'Не заказывать товар. Ожидать наступления даты заказа по графику.';
										|en = 'Do not order the goods. Wait for scheduled order date.'; fa = 'Do not order the goods. Wait for scheduled order date.';
										|it = 'Non ordinare merci. Attendere la data dell''ordine in conformità al piano.';
										|pl = 'Nie zamawiaj towarów. Zaczekaj na termin realizacji zamówienia zgodnie z harmonogramem.';
										|tr = 'Ürün siparişi yapma. Programa göre sipariş tarihini bekle.'");
			ThisIsPointOfOrdering = String.BeforeTheOrderPoint <= 0;
			ThisIsOrderDate = False;
			Order = False;
			
		EndIf;
		
		SwitchRecommendationPanelPagesInventories(String.StrategyOfProcurement,
			String.DemandConversionOption, ThisIsPointOfOrdering, ThisIsOrderDate, Order);
		
	EndIf;
	
	DisplayCalculatedRounding(String, True);

EndProcedure

&AtClient
Procedure SwitchRecommendationPanelPagesInventories(Method, DemandConversionOption, ThisIsPointOfOrdering, ThisIsOrderDate, Order)
	
	MinMaxMethod = PredefinedValue("Enum.InventoryReplenishmentMethods.StockReplenishmentMinMax");
	
	If DemandConversionOption = 0 Then // order by reordering point
		
		If Method = MinMaxMethod Then
			
			Items.RecommendationBar.CurrentPage = Items.PageMinMaxOnOrderPoint;
			Items.PagesOrderPoint1.CurrentPage = ?(ThisIsPointOfOrdering,
				Items.PageOrderPointAchieved1,
				Items.PageOrderPointNotReached1);
				
			Items.PagesRecommendation1.CurrentPage = ?(Order,
				Items.PageRecommendationToOrder1,
				Items.PageRecommendationNotToOrder1);
				
			Items.PagesToOrderFormula1.CurrentPage = ?(ThisIsPointOfOrdering,
				Items.PageToOrderOrderPointReached1,
				Items.PageToOrderOrderPointNotReached1);
				
		Else
			
			Items.RecommendationBar.CurrentPage = Items.PageForecastByOrderPoint;
			Items.OrderPoint3Pages.CurrentPage = ?(ThisIsPointOfOrdering,
				Items.PageOrderPointReached3,
				Items.PageOrderPointNotReached3);
				
			Items.PagesRecommendation3.CurrentPage = ?(Order,
				Items.PageRecommendationOrder3,
				Items.PageRecommendationNotToOrder3);
				
			Items.PagesToOrderFormula3.CurrentPage = ?(ThisIsPointOfOrdering,
				Items.PageToOrderOrderPointIsAchieved3,
				Items.PageToOrderOrderPointIsNotAchieved3);
			
		EndIf;
	
	ElsIf DemandConversionOption = 1 Then // the planned formation of the order.
		
		If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
			OrderDateHasArrived = NStr("vi = 'Tạo giấy đề nghị theo kế hoạch';
										|ru = 'Плановое формирование заявок';
										|en = 'Scheduled request generation'; fa = 'Scheduled request generation';
										|it = 'Scheduled request generation';
										|pl = 'Scheduled request generation';
										|tr = 'Planlı talep oluşturma'");
		Else
			OrderDateHasArrived = NStr("vi = 'Tạo đơn hàng theo kế hoạch';
										|ru = 'Плановое формирование заказов';
										|en = 'Scheduled order generation'; fa = 'Scheduled order generation';
										|it = 'Плановое формирование заказов';
										|pl = 'Scheduled order generation';
										|tr = 'Planlı sipariş oluşturma'");
		EndIf;
		
		If Method = MinMaxMethod Then
			
			Items.RecommendationBar.CurrentPage = Items.PageMinMaxOnSchedule;
			Items.OrderPoint2Pages.CurrentPage = ?(ThisIsPointOfOrdering,
				Items.PageOrderPointReached2,
				Items.PageOrderPointNotReached2);
				
			Items.PagesRecommendation2.CurrentPage = Items.PageRecommendationOrder2;
				
			Items.PagesToOrderFormula2.CurrentPage = ?(ThisIsPointOfOrdering,
				Items.PageToOrderOrderPointReached2,
				Items.PageToOrderOrderPointNotReached2);
				
			Items.PagesOrderSchedule2.CurrentPage  = Items.PageOrderDateIsDue2;
			
		Else
			
			Items.RecommendationBar.CurrentPage = Items.PageScheduleForecast;
			Items.OrderPoint4Pages.CurrentPage = ?(ThisIsPointOfOrdering,
				Items.PageOrderPointReached4,
				Items.PageOrderPointNotReached4);
				
			Items.PagesOrderDateRecommendation.CurrentPage = Items.PageOrderDateIsDue;
			
			Items.PagesToOrderFormula4.CurrentPage = ?(ThisIsPointOfOrdering,
				Items.PageToOrderOrderPointReached4,
				Items.PageToOrderAPointOfOrder4IsNotAchieved);
			
			Items.OrderSchedulePages4.CurrentPage = Items.PageOrderDateIsDue4;
			
		EndIf;
		
	ElsIf DemandConversionOption = 2 Then // do not order.
		
		UpToTheOrderDateDays = NStr("vi = 'Không đặt hàng hôm nay';
									|ru = 'Не заказывать сегодня';
									|en = 'Do not order today'; fa = 'امروز سفارش داده نشود';
									|it = 'Не заказывать сегодня';
									|pl = 'Do not order today';
									|tr = 'Sipariş bugün işleme alınmasın'");
		If Method = MinMaxMethod Then
			
			Items.RecommendationBar.CurrentPage = Items.PageMinMaxOnSchedule;
			Items.OrderPoint2Pages.CurrentPage = ?(ThisIsPointOfOrdering,
				Items.PageOrderPointReached2,
				Items.PageOrderPointNotReached2);
				
			Items.PagesRecommendation2.CurrentPage = Items.PageRecommendationNotToOrder2;
				
			Items.PagesToOrderFormula2.CurrentPage = ?(ThisIsPointOfOrdering,
				Items.PageToOrderOrderPointReached2,
				Items.PageToOrderOrderPointNotReached2);
				
			Items.PagesOrderSchedule2.CurrentPage  = Items.PageOrderDateIsNotDue2;
			
		Else
			
			Items.RecommendationBar.CurrentPage = Items.PageScheduleForecast;
			Items.OrderPoint4Pages.CurrentPage = ?(ThisIsPointOfOrdering,
				Items.PageOrderPointReached4,
				Items.PageOrderPointNotReached4);
				
			Items.PagesOrderDateRecommendation.CurrentPage = Items.PageOrderDateIsNotDue;
			
			Items.PagesToOrderFormula4.CurrentPage = ?(ThisIsPointOfOrdering,
				Items.PageToOrderOrderPointReached4,
				Items.PageToOrderAPointOfOrder4IsNotAchieved);
			
			Items.OrderSchedulePages4.CurrentPage = Items.PageOrderDateIsNotDue4;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateInventoryTableRowOnClient(SupplyMethod)

	Shipment = Items.Inventories.CurrentData;

	If Shipment.Mark Then

		CalculateTotals();

	EndIf;

	Filter = New Structure("Products,Characteristic,Warehouse,SupplyMethod");
	FillPropertyValues(Filter, Shipment);
	Filter.SupplyMethod = SupplyMethod;
	CalculateRowOfInventoryTable(Items.Inventories.CurrentRow, Filter);
	
	If Not ValueIsFilled(Shipment.ShipmentDate) Then
		Approaches = Object.SupplyMethods.FindRows(New Structure("SupplyMethod", SupplyMethod));
		If Approaches.Count() > 0 Then
			Shipment.ShipmentDate = Approaches[0].ShipmentDate;
		EndIf;
	EndIf;
	
	RecalculateRounding(Shipment, True);
	
	DisplayCalculatedRounding(Shipment, True);
	
	CalculateTotals();
	
	InventoriesOnActivateRow(Undefined);

EndProcedure

&AtServer
Procedure CalculateRowOfInventoryTable(RowID, Filter)
	
	StorageAddress = PutToTempStorage(Undefined, UUID);
	
	InventoryReceiptParameters = New Structure;
	InventoryReceiptParameters.Insert("FilterType", "FilterByValues");
	InventoryReceiptParameters.Insert("Filter", Filter);
	InventoryReceiptParameters.Insert("GeneratePurchaseRequests", GeneratePurchaseRequests);
	
	DataProcessors.DemandFulfillment.TableInventory(
		InventoryReceiptParameters,
		StorageAddress);
	
	Table = GetFromTempStorage(StorageAddress);
	RowStocks = Object.Inventories.FindByID(RowID);
	
	If Table.Count() > 0 Then
	
		OwnGoods = Table[0];
		FillPropertyValues(RowStocks, OwnGoods);
	
		CalculationResult2 = DataProcessors.DemandFulfillment.MinimumAndMaximumStocks(RowStocks);
		FillPropertyValues(RowStocks, CalculationResult2);
	
		CalculationResult2 = DataProcessors.DemandFulfillment.QuantityToOrderToMaintainStock(RowStocks);
		FillPropertyValues(RowStocks, CalculationResult2);
	
		CalculationResult2 = DataProcessors.DemandFulfillment.StockLevelAndPictureChangeMethod(RowStocks);
		FillPropertyValues(RowStocks, CalculationResult2);
	
		RowStocks.RecommendedToOrder = RowStocks.ToOrder;
		RowStocks.SupplySource = ProcessEmptySource(RowStocks.SupplySource, TextNotFilledIn);
		
	EndIf;

EndProcedure

&AtClient
Procedure CalculateOrdersToProvideTableRowOnClient(SupplyMethod)

	Shipment = Items.OrdersPendingSupply.CurrentData;

	If Shipment.Mark Then

		CalculateTotals();

	EndIf;

	Filter = New Structure("Products, Characteristic, Warehouse, Purpose, SupplyMethod,
		|OrderDocument, DateOfShipment, ReceivingBusinessUnit, OrderShipmentDate, OrderShipmentWarehouse");
	FillPropertyValues(Filter, Shipment);
	Filter.SupplyMethod = SupplyMethod;
	CalculateRowOfOrdersToProvideTable(Items.OrdersPendingSupply.CurrentRow, Filter);
	CalculateTotals();
	OrdersPendingSupplyOnActivateRow(Undefined);

EndProcedure

&AtServer
Procedure CalculateRowOfOrdersToProvideTable(RowID, Filter)
	
	StorageAddress = PutToTempStorage(Undefined, UUID);
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("FilterType", "FilterByValues");
	ProcedureParameters.Insert("Filter", Filter);
	ProcedureParameters.Insert("GeneratePurchaseRequests", GeneratePurchaseRequests);
	
	DataProcessors.DemandFulfillment.TableOfOrderRequirementsAndBalances(ProcedureParameters, StorageAddress);
	
	Table = GetFromTempStorage(StorageAddress);
	OrdersLine = Object.OrdersPendingSupply.FindByID(RowID);
	
	If Table.Count() > 0 Then
	
		OwnGoods = Table[0];
	
		FillPropertyValues(OrdersLine, OwnGoods,
			"EstimatedDeliveryDate,
			|ShipmentDate,
			|OrderDateNoLaterThan,
			|DeliveryDateByProcurementStrategy,
			|SupplyType,
			|SupplySource,
			|Terms,
			|Manager,
			|AgreementCurrency,
			|PriceKind,
			|PriceInTheCurrencyOfAgreement,
			|PriceInTheCurrencyOfManagementAccounting,
			|SupplySourceViewOnly");
	
		CalculationResult2 = DataProcessors.DemandFulfillment.QuantityToOrderToEnsureOrders(OrdersLine);
		FillPropertyValues(OrdersLine, CalculationResult2);
	
		FillInCalculatedFieldsOfOrdersLine(OrdersLine, CachedValues);
		
		OrdersLine.SupplySource = ProcessEmptySource(OrdersLine.SupplySource, TextNotFilledIn);
	
	EndIf;
	
EndProcedure

#EndRegion

#Region StepOrders

&AtClient
Procedure OrdersWhenActivatingWaitHandlerLine()
	
	String = Items.OrdersPendingSupply.CurrentData;
	
	If String = Undefined Then
		
		Items.RecommendationBar.CurrentPage = Items.PageLineNotSelected;
		
	Else
		
		FormatLine = "NFD=3; NZ=0.000";
		UnitOfMeasure = String.UnitOfMeasure;
		
		If Not ValueIsFilled(String.DateOfShipment) Then
			
			DateOfShipment = NStr("vi = '-';
									|ru = '-';
									|en = '-'; fa = '-';
									|it = '-';
									|pl = '-';
									|tr = '-'");
			
		Else
			
			DateOfShipment = CaptionInFormat(String.DateOfShipment, "", "DLF=D");
			
		EndIf;
		
		DeliveryScheduleIsNotCompleted = String.EstimatedDeliveryDate = '00010101'
			And String.DeliveryDateByProcurementStrategy > '00010101';
		If DeliveryScheduleIsNotCompleted Then
			ShipmentDate = NStr("vi = '<chưa điền lịch biểu giao hàng>';
								|ru = 'не заполнен график поставок';
								|en = 'delivery schedule is not filled in'; fa = 'delivery schedule is not filled in';
								|it = 'не заполнен график поставок';
								|pl = 'delivery schedule is not filled in';
								|tr = 'tedarik programı doldurulmadı'");
		Else
			ShipmentDate = CaptionInFormat(String.EstimatedDeliveryDate, "", "DLF=D");
		EndIf;
		
		Required2    = CaptionInFormat(String.Required2,  UnitOfMeasure, FormatLine);
		Supplied   = CaptionInFormat(String.Supplied, UnitOfMeasure, FormatLine);
			
		QuantityToOrderText = CaptionInFormat(String.RecommendedToOrder, UnitOfMeasure, FormatLine);
		
		ShipmentWithinPeriod = String.EstimatedDeliveryDate <= String.DeliveryDateByProcurementStrategy;
		
		If String.DemandConversionOption = 2 Then
			
			RecommendationText = NStr("vi = 'Không cần đặt hàng. Đợi đến ngày đặt hàng theo lịch biểu.';
										|ru = 'Не заказывать товар. Ожидать наступления даты заказа по графику.';
										|en = 'Do not order the goods. Wait for the scheduled order date.'; fa = 'Do not order the goods. Wait for the scheduled order date.';
										|it = 'Не заказывать товар. Ожидать наступления даты заказа по графику.';
										|pl = 'Nie zamawiaj towarów. Zaczekaj na termin realizacji zamówienia zgodnie z harmonogramem.';
										|tr = 'Ürün siparişi yapma. Programa göre sipariş tarihini bekle.'");
			
		ElsIf ShipmentWithinPeriod Then
			
			If String.Supplied = 0 Then
				RecommendationText = NStr("vi = 'Đặt số lượng cần cho đơn hàng';
											|ru = 'Заказать количество, требующееся по заказу';
											|en = 'Order the quantity required for the order.'; fa = 'Order the quantity required for the order.';
											|it = 'Ordinare una quantità richiesta per l''ordine';
											|pl = 'Zamów ilość wymaganą na zamówienie';
											|tr = 'Siparişe göre gerekli miktarı sipariş et'");
			Else
				RecommendationText = NStr("vi = 'Đặt số lượng cần cho đơn hàng, trừ số lượng cần đảm bảo trước đó';
											|ru = 'Заказать количество, требующееся по заказу, за вычетом обеспеченного ранее';
											|en = 'Order the quantity required for the order minus the quantity supplied earlier'; fa = 'Order the quantity required for the order minus the quantity supplied earlier';
											|it = 'Ordinare una quantità richiesta per l''ordine meno quella rifornita precedentemente';
											|pl = 'Zamów ilość wymaganą przez zamówienie minus wcześniej zabezpieczone';
											|tr = 'Siparişin gerektirdiği miktarı eksi önceden güvence altına alınan miktarı sipariş et'");
			EndIf;
			
		Else
			
			RecommendationText = NStr("vi = 'Chưa đặt hàng. Đợi ngày giao hàng đến gần';
										|ru = 'Не заказывать товар. Ожидать приближения даты отгрузки';
										|en = 'Do not order the goods. Wait for the shipment date'; fa = 'Do not order the goods. Wait for the shipment date';
										|it = 'Не заказывать товар. Ожидать приближения даты отгрузки';
										|pl = 'Do not order the goods. Wait for the shipment date';
										|tr = 'Ürünü sipariş etmeyin. Sevkiyat tarihinin yaklaşmasını bekleyin'");
			
		EndIf;
		
		If ShipmentWithinPeriod Then
			If DeliveryScheduleIsNotCompleted Then
				ShipmentDateText = NStr("vi = 'Không thể tính ngày giao hàng vào ngày giao hàng này';
										|ru = 'Не удалось рассчитать дату поставки на данную дату отгрузки';
										|en = 'Cannot calculate the delivery date for the given shipment date'; fa = 'Cannot calculate the delivery date for the given shipment date';
										|it = 'Не удалось рассчитать дату поставки на данную дату отгрузки';
										|pl = 'Cannot calculate the delivery date for the given shipment date';
										|tr = 'Belirtilen sevkiyat tarihi için teslim tarihi hesaplanamadı'");
			Else
				ShipmentDateText = NStr("vi = 'Ngày giao hàng được đảm bảo bằng việc giao hàng sắp tới';
										|ru = 'Дата отгрузки обеспечивается ближайшей поставкой';
										|en = 'The shipment date is supplied by the nearest delivery'; fa = 'The shipment date is supplied by the nearest delivery';
										|it = 'Дата отгрузки обеспечивается ближайшей поставкой';
										|pl = 'The shipment date is supplied by the nearest delivery';
										|tr = 'Sevkiyat tarihi, en yakın tedarik seçilerek güvenceye alınır'");
			EndIf;
		Else
			ShipmentDateText = NStr("vi = 'Ngày giao hàng được đảm bảo bằng một trong các lần giao hàng tiếp theo';
									|ru = 'Дата отгрузки обеспечивается одной из следующих поставок';
									|en = 'The shipment date is supplied by one of the next deliveries'; fa = 'The shipment date is supplied by one of the next deliveries';
									|it = 'Дата отгрузки обеспечивается одной из следующих поставок';
									|pl = 'The shipment date is supplied by one of the next deliveries';
									|tr = 'Sevkiyat tarihi, sonraki tedariklerden biri seçilerek güvenceye alınır'");
		EndIf;
		
		Items.RecommendationBar.CurrentPage = Items.PageScheduledOrdersDue;
		
		Items.PagesRecommendation7.CurrentPage   = ?(ShipmentWithinPeriod,
			Items.PageRecommendationOrder7,
			Items.PageRecommendationNotToOrder7);
		
	EndIf;
	
	DisplayCalculatedRounding(String, False);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInCalculatedFieldsOfOrdersLine(String, CachedValues)

	String.PictureOfPriority = ?(String.Priority = CachedValues.HighestPriority, 0,
		?(String.Priority = CachedValues.LowestPriority, 2, 1));

EndProcedure

#EndRegion

#Region DemandStep

&AtClient
Procedure OpenCollateralMethod(TableName)

	Shipment = Items[TableName].CurrentData;
	ProductListKey = New Structure("Products, Characteristic, Warehouse, ThisIsWork");
	ProductListKey.ThisIsWork = False;
	FillPropertyValues(ProductListKey, Shipment);

	OpeningMode = "Full";

	FormParameters = New Structure("NeedKey, CalculateStatistics, OpeningMode",
		ProductListKey, True, OpeningMode);

	OpenForm("DataProcessor.DemandFulfillment.Form.EditFormSupplyParameters", FormParameters, ThisForm, UUID);

EndProcedure

&AtClient
Procedure OpenMethodOfProviding(TableName)
	
	String = Items[TableName].CurrentData;
	If ValueIsFilled(String.SupplyMethod) Then
		
		FormParameters = New Structure("Key", String.SupplyMethod);
		OpenForm("Catalog.ProcurementStrategies.Form.ItemForm", FormParameters, ThisForm, UUID);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearPurchaseTerms(Shipment)

	Shipment.Terms = PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef");
	Shipment.PriceInTheCurrencyOfManagementAccounting = 0;
	Shipment.PriceInTheCurrencyOfAgreement = 0;
	Shipment.AgreementCurrency = PredefinedValue("Catalog.Currencies.EmptyRef");

EndProcedure

&AtClient
Procedure MethodOfProvidingCleaning(Shipment, PossibleWorks)
	
	If Shipment.Mark Then
		
		CalculateTotals();
		
	EndIf;
	
	ClearPurchaseTerms(Shipment);

	Shipment.SupplySource = TextNotFilledIn;
	Shipment.SupplyMethod = PredefinedValue("Catalog.ProcurementStrategies.EmptyRef");
	Shipment.SupplyType = PredefinedValue("Enum.SupplyTypes.Purchase");
	Shipment.SupplySourceViewOnly = False;
	
	QuantityToOrder_ = Shipment.Rounded * ?(Shipment.Mark, 1, 0);
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure FillInManager_Completion(Manager, AdditionalParameters) Export
	
	If Manager = Undefined Then
		Return;
	EndIf;
	
	For Each Id In Items.Inventories.SelectedRows Do
		
		TSRow = Object.Inventories.FindByID(Id);
		TSRow.Manager = Manager;
		
	EndDo;
	
	CalculateTotals();
	
EndProcedure

#EndRegion

#Region OrderBasket

&AtClient
Procedure CalculateTotals()
	
	ShoppingCartTotalFieldTotalLines = 0;
	TheCartSummaryBoxTotalWeight   = 0;
	OrderBasketTotalAmountField      = 0;
	
	For Each String In Object.Inventories Do
		If String.Mark And String.ToOrder > 0 Then
			
			If String.DoNotRoundBeforeCreatingOrder Then
				OrderBasketTotalAmountField = OrderBasketTotalAmountField + String.PriceInTheCurrencyOfManagementAccounting * String.ToOrder;
				TheCartSummaryBoxTotalWeight = TheCartSummaryBoxTotalWeight + String.ToOrder * String.Weight;
				ShoppingCartTotalFieldTotalLines = ShoppingCartTotalFieldTotalLines + 1;
			Else
				OrderBasketTotalAmountField = OrderBasketTotalAmountField + String.PriceInTheCurrencyOfManagementAccounting * String.Rounded;
				TheCartSummaryBoxTotalWeight = TheCartSummaryBoxTotalWeight + String.Rounded * String.Weight;
				ShoppingCartTotalFieldTotalLines = ShoppingCartTotalFieldTotalLines + 1;
			EndIf;
			
		EndIf;
	EndDo;
	
	For Each String In Object.OrdersPendingSupply Do
		If String.Mark And String.ToOrder Then
			
			If String.DoNotRoundBeforeCreatingOrder Then
				OrderBasketTotalAmountField = OrderBasketTotalAmountField + String.PriceInTheCurrencyOfManagementAccounting * String.ToOrder;
				TheCartSummaryBoxTotalWeight = TheCartSummaryBoxTotalWeight + String.ToOrder * String.Weight;
				ShoppingCartTotalFieldTotalLines = ShoppingCartTotalFieldTotalLines + 1;
			Else
				OrderBasketTotalAmountField = OrderBasketTotalAmountField + String.PriceInTheCurrencyOfManagementAccounting * String.Rounded;
				TheCartSummaryBoxTotalWeight = TheCartSummaryBoxTotalWeight + String.Rounded * String.Weight;
				ShoppingCartTotalFieldTotalLines = ShoppingCartTotalFieldTotalLines + 1;
			EndIf;
		
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure CalculateTotalsOnServer()
	
	ShoppingCartTotalFieldTotalLines = 0;
	TheCartSummaryBoxTotalWeight   = 0;
	OrderBasketTotalAmountField      = 0;
	
	For Each String In Object.Inventories Do
		If String.Mark Then
		
			OrderBasketTotalAmountField = OrderBasketTotalAmountField + String.PriceInTheCurrencyOfManagementAccounting * String.Rounded;
			TheCartSummaryBoxTotalWeight = TheCartSummaryBoxTotalWeight + String.Rounded * String.Weight;
			ShoppingCartTotalFieldTotalLines = ShoppingCartTotalFieldTotalLines + 1;
		
		EndIf;
	EndDo;
	
	For Each String In Object.OrdersPendingSupply Do
		If String.Mark Then
		
			OrderBasketTotalAmountField = OrderBasketTotalAmountField + String.PriceInTheCurrencyOfManagementAccounting * String.Rounded;
			TheCartSummaryBoxTotalWeight = TheCartSummaryBoxTotalWeight + String.Rounded * String.Weight;
			ShoppingCartTotalFieldTotalLines = ShoppingCartTotalFieldTotalLines + 1;
		
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure ChangeMark_(TableName, Set)
	
	SelectedRows = ?(TableName = "Inventories", Items.Inventories.SelectedRows,
	                                            Items.OrdersPendingSupply.SelectedRows);
	
	For Each Id In SelectedRows Do
		
		String = Object[TableName].FindByID(Id);
		
		String.Mark = Set;
		
		RecalculateRoundingServer(String, TableName = "Inventories");
		
	EndDo;
	
	CalculateTotalsOnServer();
	
EndProcedure

&AtServer
Procedure ChangeMarkToAllLines(TableName, Set)
	
	Table = Object[TableName];

	For Each String In Table Do
		
		String.Mark = Set;
	EndDo;
	
	CalculateTotalsOnServer();
	
EndProcedure

&AtServer
Procedure FillInPricesAtServer(GoodsList, Terms)
	
	ListOfProductsWithPrices = GetPrices(GoodsList, Terms);
	For Each OwnGoods In ListOfProductsWithPrices Do
		
		TreeRow = Preview.FindByID(OwnGoods.ID);
		TreeRow.PriceInTheCurrencyOfAgreement               = OwnGoods.PriceInTheCurrencyOfAgreement;
		TreeRow.AgreementCurrencyAmount               = TreeRow.PriceInTheCurrencyOfAgreement * TreeRow.ToOrder;
		TreeRow.PriceInTheCurrencyOfManagementAccounting     = OwnGoods.PriceInTheCurrencyOfManagementAccounting;
		TreeRow.AmountManAccounting                        = TreeRow.PriceInTheCurrencyOfManagementAccounting * TreeRow.ToOrder;
		TreeRow.OrderPackage                      = OwnGoods.OrderPackage;
		TreeRow.MinimumDeliveryLot           = OwnGoods.MinimumDeliveryLot;
		TreeRow.PriceKind                             = OwnGoods.PriceKind;
		TreeRow.AgreementCurrency                    = OwnGoods.AgreementCurrency;
		
	EndDo;
	
EndProcedure

&AtServer
Function GetPrices(GoodsList, Terms)
	
	VendorPriceKind = Common.ObjectAttributeValue(Terms, "VendorPriceKind");

	GoodsTable = New ValueTable;
	
	NumberDetails = New TypeDescription("Number");
	ProductDescription_1 = New TypeDescription("CatalogRef.Products");
	DescriptionOfProductCharacteristics = New TypeDescription("CatalogRef.ItemsCharacteristics");
	DescriptionWaysToMeetNeeds = New TypeDescription("CatalogRef.ProcurementStrategies");
	DescriptionOfAgreementWithSuppliers = New TypeDescription("CatalogRef.TermsOfPurchaseFromVendors");
	DescriptionSupplierPriceType = New TypeDescription("CatalogRef.VendorPriceTypes");
	
	GoodsTable.Columns.Add("Products", ProductDescription_1);
	GoodsTable.Columns.Add("Characteristic", DescriptionOfProductCharacteristics);
	GoodsTable.Columns.Add("Terms", DescriptionOfAgreementWithSuppliers);
	GoodsTable.Columns.Add("SupplyMethod", DescriptionWaysToMeetNeeds);
	GoodsTable.Columns.Add("VendorPriceKind", DescriptionSupplierPriceType);
	GoodsTable.Columns.Add("ID", NumberDetails);
	
	For Each OwnGoods In GoodsList Do
		NewRow = GoodsTable.Add();
		FillPropertyValues(NewRow, OwnGoods);
		NewRow.VendorPriceKind = VendorPriceKind;
	EndDo;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("FillingData", GoodsTable);
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	Query.SetParameter("Date", CurrentSessionDate());
	Query.SetParameter("MainCountry", SettingsValueClientServerCached.MainCountry());
	
	Query.Text = 
		"SELECT
		|	FillingData.Products AS Products,
		|	FillingData.Characteristic AS Characteristic,
		|	FillingData.Terms AS Terms,
		|	FillingData.SupplyMethod AS SupplyMethod,
		|	FillingData.VendorPriceKind AS VendorPriceKind,
		|	FillingData.ID AS ID
		|INTO FillingData
		|FROM
		|	&FillingData AS FillingData
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Terms,
		|	SupplyMethod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CurrencyRatesCut.Currency AS Currency,
		|	CASE
		|		WHEN CurrencyRatesCut.CourseDenominator = 0
		|			THEN 0
		|		ELSE CurrencyRatesCut.CourseNumerator / CurrencyRatesCut.CourseDenominator
		|	END AS ZoomRatio
		|INTO ExchangeRates
		|FROM
		|	InformationRegister.RelativeExchangeRates.SliceLast(, BaseCurrency = &BaseCurrency) AS CurrencyRatesCut
		|
		|INDEX BY
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SupplierPrices.Products AS Products,
		|	SupplierPrices.Characteristic AS Characteristic,
		|	SupplierPrices.VendorPriceKind AS VendorPriceKind,
		|	ISNULL(&PackagingFactor,1) AS ZoomRatio,
		|	SupplierPrices.Package AS Package,
		|	SupplierPrices.Currency AS Currency,
		|	SupplierPrices.Price AS Price
		|INTO SupplierPrices
		|FROM
		|	InformationRegister.ItemsPricesOfVendor.SliceLast(
		|			,
		|			(Products, Characteristic, VendorPriceKind) IN
		|				(SELECT
		|					FillingData.Products AS Products,
		|					FillingData.Characteristic AS Characteristic,
		|					FillingData.VendorPriceKind AS VendorPriceKind
		|				FROM
		|					FillingData AS FillingData)) AS SupplierPrices
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	VendorPriceKind
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PurchaseConditions.Products              AS Products,
		|	PurchaseConditions.Characteristic            AS Characteristic,
		|	PurchaseConditions.VendorPriceKind         AS VendorPriceKind,
		|	PurchaseConditions.OrderPackage            AS OrderPackage,
		|	PurchaseConditions.MinimumDeliveryLot AS MinimumDeliveryLot
		|INTO PurchaseConditions
		|FROM
		|	InformationRegister.PurchaseConditions.SliceLast(
		|			,
		|			(Products, Characteristic, VendorPriceKind) IN
		|				(SELECT
		|					FillingData.Products AS Products,
		|					FillingData.Characteristic AS Characteristic,
		|					FillingData.VendorPriceKind AS VendorPriceKind
		|				FROM
		|					FillingData AS FillingData)) AS PurchaseConditions
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	VendorPriceKind
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FillingData.Products AS Products,
		|	FillingData.Characteristic AS Characteristic,
		|	FillingData.VendorPriceKind AS PriceKind,
		|	SupplierPrices.Currency AS Currency,
		|	SupplierPrices.Package AS Package,
		|	SupplierPrices.Price AS Price,
		|	ISNULL(FillingData.Terms.Currency, FillingData.SupplyMethod.Terms.Currency) AS AgreementCurrency,
		|	CASE 
		|		WHEN NOT ISNULL(FillingData.Terms.PriceIncludesVAT, FillingData.SupplyMethod.Terms.PriceIncludesVAT) THEN
		|			(CASE
		|				WHEN NOT (ISNULL(VATRatesForProductsOfCountryOfRegistration.VATRate, ISNULL(BasicVATRatesOfCountryOfRegistration.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1 IS NULL
		|					THEN (ISNULL(VATRatesForProductsOfCountryOfRegistration.VATRate, ISNULL(BasicVATRatesOfCountryOfRegistration.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1
		|				WHEN NOT (ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1 IS NULL
		|					THEN (ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1
		|				ELSE 0
		|			END + 100) / 100
		|		ELSE
		|		1
		|		END
		|	* SupplierPrices.Price * ExchangeRates.ZoomRatio / &CurrencyCoefficientOfManAccounting / SupplierPrices.ZoomRatio AS PriceInTheCurrencyOfManagementAccounting,
		|	CASE 
		|		WHEN NOT ISNULL(FillingData.Terms.PriceIncludesVAT, FillingData.SupplyMethod.Terms.PriceIncludesVAT) THEN
		|			(CASE
		|				WHEN NOT (ISNULL(VATRatesForProductsOfCountryOfRegistration.VATRate, ISNULL(BasicVATRatesOfCountryOfRegistration.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1 IS NULL
		|					THEN (ISNULL(VATRatesForProductsOfCountryOfRegistration.VATRate, ISNULL(BasicVATRatesOfCountryOfRegistration.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1
		|				WHEN NOT (ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1 IS NULL
		|					THEN (ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1
		|				ELSE 0
		|			END + 100) / 100
		|		ELSE
		|		1
		|		END
		|	* SupplierPrices.Price * ExchangeRates.ZoomRatio / ExchangeRatesOfAgreement.ZoomRatio / SupplierPrices.ZoomRatio AS PriceInTheCurrencyOfAgreement,
		|	PurchaseConditions.OrderPackage AS OrderPackage,
		|	PurchaseConditions.MinimumDeliveryLot AS MinimumDeliveryLot,
		|	FillingData.ID AS ID
		|FROM
		|	FillingData AS FillingData
		|		LEFT JOIN SupplierPrices AS SupplierPrices
		|			LEFT JOIN ExchangeRates AS ExchangeRates
		|			ON SupplierPrices.Currency = ExchangeRates.Currency
		|		ON FillingData.Products = SupplierPrices.Products
		|			AND FillingData.Characteristic = SupplierPrices.Characteristic
		|			AND FillingData.VendorPriceKind = SupplierPrices.VendorPriceKind
		|		LEFT JOIN PurchaseConditions AS PurchaseConditions
		|		ON FillingData.Products            = PurchaseConditions.Products
		|			AND FillingData.Characteristic       = PurchaseConditions.Characteristic
		|			AND FillingData.VendorPriceKind    = PurchaseConditions.VendorPriceKind
		|		LEFT JOIN ExchangeRates AS ExchangeRatesOfAgreement
		|		ON ISNULL(FillingData.Terms.Currency, FillingData.SupplyMethod.Terms.Currency) = ExchangeRatesOfAgreement.Currency
		|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Date) AS VATRatesForProductsOfCountryOfRegistration
		|		ON FillingData.Products = VATRatesForProductsOfCountryOfRegistration.Products
		|			AND FillingData.SupplyMethod.Organization.RegistrationCountry = VATRatesForProductsOfCountryOfRegistration.Country
		|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Date) AS BasicVATRatesOfCountryOfRegistration
		|		ON FillingData.SupplyMethod.Organization.RegistrationCountry = BasicVATRatesOfCountryOfRegistration.Country		
		|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Date, Country = &MainCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
		|		ON FillingData.Products = ProductsVATRates.Products
		|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Date, Country = &MainCountry) AS BasicVATRates
		|		ON (TRUE)
		|";
	
	Query.Text = StrReplace(Query.Text, "&PackagingFactor", Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"SupplierPrices.Package",
			"SupplierPrices.Products"));
	
	CurrencyExchangeRateManAccounting = ProcessingOfExchangeRatesTM.GetCurrencyRate(Constants.ManagementAccountingCurrency.Get(), BegOfDay(CurrentSessionDate()));
	CurrencyCoefficientOfManAccounting = CurrencyExchangeRateManAccounting.CourseNumerator / CurrencyExchangeRateManAccounting.CourseDenominator;
	Query.SetParameter("CurrencyCoefficientOfManAccounting", CurrencyCoefficientOfManAccounting);
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	ListOfProductsWithPrices = New Array;
	
	While SelectionDetailRecords.Next() Do
		Structure = New Structure;
		Structure.Insert("Products",                    SelectionDetailRecords.Products);
		Structure.Insert("Characteristic",                  SelectionDetailRecords.Characteristic);
		Structure.Insert("ID",                              SelectionDetailRecords.ID);
		Structure.Insert("PriceInTheCurrencyOfAgreement",           SelectionDetailRecords.PriceInTheCurrencyOfAgreement);
		Structure.Insert("PriceInTheCurrencyOfManagementAccounting", SelectionDetailRecords.PriceInTheCurrencyOfManagementAccounting);
		Structure.Insert("PriceKind",                         SelectionDetailRecords.PriceKind);
		Structure.Insert("AgreementCurrency",                SelectionDetailRecords.AgreementCurrency);
		Structure.Insert("OrderPackage",                  SelectionDetailRecords.OrderPackage);
		Structure.Insert("MinimumDeliveryLot",       SelectionDetailRecords.MinimumDeliveryLot);
		
		ListOfProductsWithPrices.Add(Structure);
	EndDo;
	
	Return ListOfProductsWithPrices;
	
EndFunction

#EndRegion

#Region StepOrderEditing

&AtServer
Procedure PreviewAgreementSelectionProcessingAtServer(ValueSelected)
	
	RowSelected = Preview.FindByID(Items.Preview.CurrentRow);
	
	NewValues = New Structure();
	NewValues.Insert("Terms", ValueSelected);
	NewValues.Insert("MinimumOrderAmount", GetMinimumOrderAmount(ValueSelected));
	
	If RowSelected.LevelInTheTree = 0 Then
		RowsToProcess = RowSelected.GetItems();
	Else
		RowsToProcess = New Array();
		RowsToProcess.Add(RowSelected);
	EndIf;
	
	GoodsList = New Array();
	For Each TreeRow In RowsToProcess Do
		OwnGoods = New Structure();
		OwnGoods.Insert("Products", TreeRow.Products);
		OwnGoods.Insert("Characteristic", TreeRow.Characteristic);
		OwnGoods.Insert("Terms", NewValues.Terms);
		OwnGoods.Insert("SupplyMethod", TreeRow.SupplyMethod);
		OwnGoods.Insert("ID", TreeRow.GetID());
		GoodsList.Add(OwnGoods);
	EndDo;
	FillInPricesAtServer(GoodsList, ValueSelected);
	
	ChangeRowsInTablePartsAtServer(RowsToProcess, NewValues);
	
EndProcedure

&AtServer
Procedure PreviewDeliveryParametersOptimalSelectionProcessingAtServer(ValueSelected)
	
	RowSelected = Preview.FindByID(Items.Preview.CurrentRow);
	
	NewValues = New Structure();
	NewValues.Insert("Terms", ValueSelected.Terms);
	NewValues.Insert("SupplySource", ValueSelected.SupplySource);
	NewValues.Insert("MinimumOrderAmount",
		GetMinimumOrderAmount(ValueSelected.Terms));
	NewValues.SupplySource = ?(NewValues.SupplySource = Undefined, TextNotFilledIn, NewValues.SupplySource);
	
	If RowSelected.LevelInTheTree = 0 Then
		RowsToProcess = RowSelected.GetItems();
	Else
		RowsToProcess = New Array();
		RowsToProcess.Add(RowSelected);
	EndIf;
	
	If RowSelected.SupplyType = Enums.SupplyTypes.Purchase Then
		
		GoodsList = New Array();
		For Each TreeRow In RowsToProcess Do
			OwnGoods = New Structure();
			OwnGoods.Insert("Products", TreeRow.Products);
			OwnGoods.Insert("Characteristic", TreeRow.Characteristic);
			OwnGoods.Insert("Terms", NewValues.Terms);
			OwnGoods.Insert("SupplyMethod", TreeRow.SupplyMethod);
			OwnGoods.Insert("ID", TreeRow.GetID());
			GoodsList.Add(OwnGoods);
		EndDo;
		FillInPricesAtServer(GoodsList, ValueSelected.Terms);
		
	EndIf; 
	ChangeRowsInTablePartsAtServer(RowsToProcess, NewValues);
	
EndProcedure

&AtServer
Procedure PreviewIsWayToEnsureSelectionProcessingAtServer(ValueSelected)
	
	OrderProperties = GetSourceAndAgreement(ValueSelected);
	
	NewValues = New Structure;
	NewValues.Insert("SupplyMethod", ValueSelected);
	NewValues.Insert("Terms", OrderProperties.Terms);
	NewValues.Insert("SupplySource", OrderProperties.SourceOfDemandSupply);
	NewValues.Insert("SupplyType", OrderProperties.SupplyType);
	NewValues.Insert("MinimumOrderAmount", GetMinimumOrderAmount(OrderProperties.Terms));
	NewValues.Insert("SupplySourceViewOnly", ?(NewValues.SupplySource = Undefined, False, True));
	NewValues.SupplySource = ?(NewValues.SupplySource = Undefined, TextNotFilledIn, NewValues.SupplySource);
	
	RowSelected = Preview.FindByID(Items.Preview.CurrentRow);
	
	If RowSelected.LevelInTheTree = 0 Then
		RowsToProcess = RowSelected.GetItems();
	Else
		RowsToProcess = New Array();
		RowsToProcess.Add(RowSelected);
	EndIf;
	
	GoodsList = New Array();
	For Each TreeRow In RowsToProcess Do
		OwnGoods = New Structure();
		OwnGoods.Insert("Products", TreeRow.Products);
		OwnGoods.Insert("Characteristic", TreeRow.Characteristic);
		OwnGoods.Insert("Terms", NewValues.Terms);
		OwnGoods.Insert("SupplyMethod", NewValues.SupplyMethod);
		OwnGoods.Insert("ID", TreeRow.GetID());
		GoodsList.Add(OwnGoods);
	EndDo;
	FillInPricesAtServer(GoodsList, OrderProperties.Terms);
	
	ChangeRowsInTablePartsAtServer(RowsToProcess, NewValues);
	
EndProcedure

&AtServer
Procedure PreviewWarehouseSelectionProcessingAtServer(ValueSelected)
	
	NewValues = New Structure();
	NewValues.Insert("Warehouse", ValueSelected);
	RowSelected = Preview.FindByID(Items.Preview.CurrentRow);
	
	If RowSelected.LevelInTheTree = 0 Then
		RowsToProcess = RowSelected.GetItems();
	Else
		RowsToProcess = New Array();
		RowsToProcess.Add(RowSelected);
	EndIf;
	
	ChangeRowsInTablePartsAtServer(RowsToProcess, NewValues);
	
EndProcedure

&AtServer
Procedure PreviewManagerSelectionProcessingAtServer(ValueSelected)
	
	NewValues = New Structure();
	NewValues.Insert("Manager", ValueSelected);
	RowSelected = Preview.FindByID(Items.Preview.CurrentRow);
	
	If RowSelected.LevelInTheTree = 0 Then
		RowsToProcess = RowSelected.GetItems();
	Else
		RowsToProcess = New Array();
		RowsToProcess.Add(RowSelected);
	EndIf;
	
	ChangeRowsInTablePartsAtServer(RowsToProcess, NewValues);
	
EndProcedure

&AtServer
Procedure WarehouseSelectionEndsAtServer(Warehouse)
	
	NewValues = New Structure();
	NewValues.Insert("Warehouse", Warehouse);
	
	Orders = New Map();
	RowsToProcess = New Array();
	For Each Id In Items.Preview.SelectedRows Do
		
		RowSelected = Preview.FindByID(Id);
		If RowSelected.LevelInTheTree = 0 Then
			Orders.Insert(RowSelected, False);
			Rows = RowSelected.GetItems();
			For Each String In Rows Do
				RowsToProcess.Add(String); 
			EndDo;
		EndIf;
		
	EndDo;
	
	For Each Id In Items.Preview.SelectedRows Do
		
		RowSelected = Preview.FindByID(Id);
		If RowSelected.LevelInTheTree <> 0 Then
			RowParent = RowSelected.GetParent();
			If Orders.Get(RowParent) = Undefined Then
				RowsToProcess.Add(RowSelected);
			EndIf;
		EndIf;
		
	EndDo;
	
	ChangeRowsInTablePartsAtServer(RowsToProcess, NewValues);
	
EndProcedure

&AtServer
Procedure ChoosingWayToEnsureEndAtServer(Method)
	
	OrderProperties = GetSourceAndAgreement(Method);
	
	NewValues = New Structure();
	NewValues.Insert("SupplyMethod", Method);
	NewValues.Insert("Terms", OrderProperties.Terms);
	NewValues.Insert("SupplySource", OrderProperties.SourceOfDemandSupply);
	NewValues.Insert("SupplyType", OrderProperties.SupplyType);
	NewValues.Insert("MinimumOrderAmount", GetMinimumOrderAmount(OrderProperties.Terms));
	NewValues.Insert("SupplySourceViewOnly", ?(NewValues.SupplySource = Undefined, False, True));
	NewValues.SupplySource = ?(NewValues.SupplySource = Undefined, TextNotFilledIn, NewValues.SupplySource);
	
	Orders = New Map();
	RowsToProcess = New Array();
	For Each Id In Items.Preview.SelectedRows Do
		
		RowSelected = Preview.FindByID(Id);
		If RowSelected.LevelInTheTree = 0 Then
			Orders.Insert(RowSelected, False);
			Rows = RowSelected.GetItems();
			For Each String In Rows Do
				RowsToProcess.Add(String); 
			EndDo;
		EndIf;
		
	EndDo;
	
	For Each Id In Items.Preview.SelectedRows Do
		
		RowSelected = Preview.FindByID(Id);
		If RowSelected.LevelInTheTree <> 0 Then
			RowParent = RowSelected.GetParent();
			If Orders.Get(RowParent) = Undefined Then
				RowsToProcess.Add(RowSelected);
			EndIf;
		EndIf;
		
	EndDo;
	
	GoodsList = New Array();
	For Each TreeRow In RowsToProcess Do
		OwnGoods = New Structure();
		OwnGoods.Insert("Products", TreeRow.Products);
		OwnGoods.Insert("Characteristic", TreeRow.Characteristic);
		OwnGoods.Insert("Terms", NewValues.Terms);
		OwnGoods.Insert("SupplyMethod", NewValues.SupplyMethod);
		OwnGoods.Insert("ID", TreeRow.GetID());
		GoodsList.Add(OwnGoods);
	EndDo;
	FillInPricesAtServer(GoodsList, NewValues.Terms);
	
	ChangeRowsInTablePartsAtServer(RowsToProcess, NewValues);

EndProcedure

&AtServer
Procedure ChoosingManagerToEndAtServer(Manager)
	
	NewValues = New Structure();
	NewValues.Insert("Manager", Manager);
	
	Orders = New Map();
	RowsToProcess = New Array();
	For Each Id In Items.Preview.SelectedRows Do
		
		RowSelected = Preview.FindByID(Id);
		If RowSelected.LevelInTheTree = 0 Then
			Orders.Insert(RowSelected, False);
			Rows = RowSelected.GetItems();
			For Each String In Rows Do
				RowsToProcess.Add(String); 
			EndDo;
		EndIf;
		
	EndDo;
	
	For Each Id In Items.Preview.SelectedRows Do
		
		RowSelected = Preview.FindByID(Id);
		If RowSelected.LevelInTheTree <> 0 Then
			RowParent = RowSelected.GetParent();
			If Orders.Get(RowParent) = Undefined Then
				RowsToProcess.Add(RowSelected);
			EndIf;
		EndIf;
		
	EndDo;
	
	ChangeRowsInTablePartsAtServer(RowsToProcess, NewValues);
	
EndProcedure

&AtClient
Procedure RecalculateOrderTotals(OrderLine)
	
	OrderLine.Demand = 0;
	OrderLine.ToOrder = 0;
	OrderLine.AgreementCurrencyAmount = 0;
	OrderLine.LinesInTheOrder = 0;
	OrderLine.Weight = 0;
	
	For Each RowGoods In OrderLine.GetItems() Do
		
		RowGoods.AgreementCurrencyAmount = RowGoods.ToOrder * RowGoods.PriceInTheCurrencyOfAgreement;
		
		OrderLine.Demand = OrderLine.Demand + RowGoods.Demand;
		OrderLine.ToOrder = OrderLine.ToOrder + RowGoods.ToOrder;
		OrderLine.AgreementCurrencyAmount = OrderLine.AgreementCurrencyAmount + RowGoods.AgreementCurrencyAmount;
		OrderLine.LinesInTheOrder   = OrderLine.LinesInTheOrder + RowGoods.LinesInTheOrder;
		OrderLine.Weight = OrderLine.Weight + RowGoods.Weight;
		
	EndDo;
	
	If OrderLine.MinimumOrderAmount > 0 And OrderLine.MinimumOrderAmount > OrderLine.AgreementCurrencyAmount Then
		OrderLine.Warning = True;
	Else
		OrderLine.Warning = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateWarningLabel(Item)

	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentData.LevelInTheTree = 0 Then
		OrderLine = Item.CurrentData;
	Else
		OrderLine = Item.CurrentData.GetParent();
	EndIf;
	
	OrderAmount      = Format(OrderLine.AgreementCurrencyAmount,  "NFD=2; NZ=0,00");
	AgreementAmount  = Format(OrderLine.MinimumOrderAmount, "NFD=2; NZ=0,00");
	AdditionalOrderAmount   = Format(OrderLine.MinimumOrderAmount - OrderLine.AgreementCurrencyAmount, "NFD=2; NZ=0,00");
	AgreementCurrency = String(OrderLine.AgreementCurrency);
	
	If OrderLine.Warning Then
		
		If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
			TextOfRecommendationToIncreaseAmount = NStr("vi = 'Nên tăng số tiền giấy đề nghị thành %3';
														|ru = 'Рекомендуется увеличить сумму заявки на %3';
														|en = 'It is recommended that you increase the request amount by %3'; fa = 'It is recommended that you increase the request amount by %3';
														|it = 'It is recommended that you increase the request amount by %3';
														|pl = 'It is recommended that you increase the request amount by %3';
														|tr = 'Talep tutarının %3 kadar artırılması önerilmektedir'");
		Else
			TextOfRecommendationToIncreaseAmount = NStr("vi = 'Nên tăng số tiền đơn hàng thành %3';
														|ru = 'Рекомендуется увеличить сумму заказа на %3';
														|en = 'It is recommended to increase order amount by %3'; fa = 'It is recommended to increase order amount by %3';
														|it = 'Si consiglia di aumentare l''importo dell''ordine di %3';
														|pl = 'Zaleca się zwiększyć kwotę zamówienia o %3';
														|tr = 'Sipariş miktarının %3 kadar artırılması önerilmektedir'");
		EndIf;
		
		WarningText = NStr("vi = 'Số tiền đặt hàng tối thiểu theo thỏa thuận %1, số tiền hiện tại %2';
							|ru = 'Минимальная сумма заказа по соглашению %1, текущая сумма %2';
							|en = 'Minimum order amount as per agreement %1, current amount %2'; fa = 'Minimum order amount as per agreement %1, current amount %2';
							|it = 'Importo minimo dell''ordine in base al contratto %1, importo corrente %2';
							|pl = 'Minimalna kwota zamówienia wg umowy %1, bieżąca kwota %2';
							|tr = 'Anlaşmaya göre minimum sipariş tutarı %1, mevcut tutar%2'");
		WarningText = WarningText + Chars.LF + TextOfRecommendationToIncreaseAmount;
		
		WarningText = StrReplace(WarningText, "%1", AgreementAmount + " " + AgreementCurrency);
		WarningText = StrReplace(WarningText, "%2", OrderAmount     + " " + AgreementCurrency);
		WarningText = StrReplace(WarningText, "%3", AdditionalOrderAmount  + " " + AgreementCurrency);
	Else
		WarningText = "";
	EndIf;

	Items.WarnString.Title = WarningText;
	
EndProcedure

&AtServer
Procedure ChangeRowsInTablePartsAtServer(TreeRows, NewValues)
	
	FieldsToFillIn =
		"AgreementCurrency,
		|PriceKind,
		|SupplySource,
		|SupplySourceViewOnly,
		|Manager,
		|MinimumOrderAmount,
		|MinimumDeliveryLot,
		|TransferIsAllowed,
		|Warehouse,
		|Terms,
		|SupplyMethod,
		|SupplyType,
		|PriceInTheCurrencyOfAgreement,
		|PriceInTheCurrencyOfManagementAccounting";
	
	Var_Key = "SupplyMethod,SupplySource,Terms,Warehouse,Products,Characteristic,Manager";
	TableInventory = Object.Inventories.Unload(, Var_Key);
	TableOfOrdersToProvide = Object.OrdersPendingSupply.Unload(, Var_Key);
	
	TableInventory.Indexes.Add(Var_Key);
	TableOfOrdersToProvide.Indexes.Add(Var_Key);
	
	FilterParameters = New Structure(Var_Key);
	
	For Each TreeRow In TreeRows Do
		
		FillPropertyValues(FilterParameters, TreeRow);
		If FilterParameters.SupplySource = Undefined Then
			FilterParameters.SupplySource = TextNotFilledIn;
		EndIf;
		FillPropertyValues(TreeRow, NewValues);
		
		ToOrder = 0;
		
		FoundRows = TableInventory.FindRows(FilterParameters);
		For Each FoundRow In FoundRows Do
			
			String = Object.Inventories[TableInventory.IndexOf(FoundRow)];
			FillPropertyValues(String, TreeRow, FieldsToFillIn);
			RecalculateRoundingServer(String, True);
			ToOrder = ToOrder + String.Rounded;
			
		EndDo;
		
		FoundRows = TableOfOrdersToProvide.FindRows(FilterParameters);
		For Each FoundRow In FoundRows Do
			
			String = Object.OrdersPendingSupply[TableOfOrdersToProvide.IndexOf(FoundRow)];
			
			FillPropertyValues(String, TreeRow, FieldsToFillIn);
			RecalculateRoundingServer(String, False);
			ToOrder = ToOrder + String.Rounded;
			
		EndDo;
		
		TreeRow.ToOrder = ToOrder;
		TreeRow.AgreementCurrencyAmount = TreeRow.ToOrder * TreeRow.PriceInTheCurrencyOfAgreement;
		TreeRow.AmountManAccounting = TreeRow.ToOrder * TreeRow.PriceInTheCurrencyOfManagementAccounting;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FindOutPositionOfRowsAndGroupingsInTree(Rows)
	
	Orders = New Map();
	For Each Id In Rows Do
		
		RowSelected = Preview.FindByID(Id);
		If RowSelected.LevelInTheTree = 0 Then
			Orders.Insert(RowSelected, False);
		EndIf;
		
	EndDo;
	
	RowsToProcess = New Array();
	For Each Id In Rows Do
		
		RowSelected = Preview.FindByID(Id);
		If RowSelected.LevelInTheTree <> 0 Then
			RowParent = RowSelected.GetParent();
			If Orders.Get(RowParent) = Undefined Then
				RowsToProcess.Add(RowSelected);
			EndIf;
		Else
			SubordinateRows = RowSelected.GetItems();
			For Each SubordinateRow In SubordinateRows Do
				RowsToProcess.Add(SubordinateRow);
			EndDo;
		EndIf;
		
	EndDo;
	
	For Each LineToEdit In RowsToProcess Do
		
		OrderFound_ = False;
		OldOrder = LineToEdit.GetParent();
		Orders.Insert(OldOrder, False);
		
		// If the main details have not changed, we will recalculate the results
		If OldOrder.SupplySource = LineToEdit.SupplySource 
			And OldOrder.Warehouse = LineToEdit.Warehouse 
			And OldOrder.Manager = LineToEdit.Manager
			And OldOrder.Terms = LineToEdit.Terms Then
			
			Continue;
		EndIf;
		
		AllOrders = Preview.GetItems();
		For Each OrderDocument In AllOrders Do
			
			// Checking whether the line fits the order
			If OrderDocument.SupplySource = LineToEdit.SupplySource
				And OrderDocument.Warehouse = LineToEdit.Warehouse
				And OrderDocument.Manager = LineToEdit.Manager
				And OrderDocument.Terms = LineToEdit.Terms Then
				
				Orders.Insert(OrderDocument, False);
				
				// Move it to a new order
				NewRow = Undefined;
				OrderLines_ = OrderDocument.GetItems();
				For Each CurItem In OrderLines_ Do
					If CurItem.SupplyMethod = LineToEdit.SupplyMethod
							And CurItem.Products = LineToEdit.Products
							And CurItem.Characteristic = LineToEdit.Characteristic Then
							
							NewRow = CurItem;
							NewRow.ToOrder = NewRow.ToOrder + LineToEdit.ToOrder;
							NewRow.Demand = NewRow.Demand + LineToEdit.Demand;
							NewRow.Weight = NewRow.Weight + LineToEdit.Weight;
							NewRow.AgreementCurrencyAmount = NewRow.AgreementCurrencyAmount + LineToEdit.AgreementCurrencyAmount;
							If Items.Preview.CurrentRow = LineToEdit.GetID() Then
								Items.Preview.CurrentRow = NewRow.GetID();
							EndIf;
							Break;
					EndIf;
				EndDo;
				
				If NewRow = Undefined Then
					NewRow = OrderLines_.Add();
					FillPropertyValues(NewRow, LineToEdit);
				EndIf;
				
				// We will remove it from the order
				OldOrderData = OldOrder.GetItems();
				OldOrderData.Delete(LineToEdit);
				
				OrderFound_ = True;
				
			EndIf;
			
		EndDo;
		
		// If the line being edited does not find the order, create a new one
		If Not OrderFound_ Then
			
			NewOrder = AllOrders.Add();
			FillPropertyValues(NewOrder, LineToEdit, "Terms, SupplySource, SupplyMethod, 
			|SupplyType, AgreementCurrency, Warehouse, Manager, MinimumOrderAmount, SupplySourceViewOnly,TransferIsAllowed");
			NewOrder.LevelInTheTree = 0;
			
			Orders.Insert(NewOrder, False);
			
			NewRow = NewOrder.GetItems().Add();
			FillPropertyValues(NewRow, LineToEdit);
			
			If Items.Preview.CurrentRow = LineToEdit.GetID() Then
				Items.Preview.CurrentRow = NewRow.GetID();
			EndIf;
			
			OldOrder.GetItems().Delete(LineToEdit);
			
		EndIf;
		
	EndDo;
	
	For Each Item In Orders Do
		
		OrderDocument = Item.Key;
		OrderLines_ = OrderDocument.GetItems();
		If OrderLines_.Count() = 0 Then
			Preview.GetItems().Delete(OrderDocument);
		Else
			OrderDocument.MinimumOrderAmount = OrderLines_[0].MinimumOrderAmount;
			RecalculateOrderTotals(OrderDocument);
		EndIf;
		
	EndDo;
	
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure SetPropertiesOfCollapsibleGroup(GroupItem1, PictureGroup, GroupCollapsed)

	GroupItem1.Visible = GroupCollapsed;
	
	If GroupCollapsed Then
		PictureGroup.Picture = PictureLib.DownArrow;
	Else
		PictureGroup.Picture = PictureLib.RightArrow;
	EndIf; 

EndProcedure

&AtClient
Procedure ShowHideWarning()
	
	CollapsedWarningGroup = Not Items.WarningGroup.Visible;
	
	SetPropertiesOfCollapsibleGroup(
	Items.WarningGroup,
	Items.ShowHideWarnings,
	CollapsedWarningGroup);
	
EndProcedure

&AtClient
Function PrepareStringStructure()
	
	StringStructure = New Structure("SupplyMethod, SupplySource, Terms, Warehouse, Products,
	|Characteristic, ToOrder, OrderPackage, UnitOfMeasure, PackageNumerator, PackageDenominator,
	|LineNumber, Mark, Purpose, PriceInTheCurrencyOfAgreement, AgreementCurrency, Demand");
	
	Return StringStructure;
	
EndFunction

&AtClient
Procedure FinishEditingQuantity(Response, AdditionalParameters) Export
	
	Weight = 0;
	
	If Response = Undefined Then
		Return;
	EndIf;
	
	For Each String In Response.Rows Do
		
		SearchParameters = New Structure("LineNumber");
		FillPropertyValues(SearchParameters, String);
		
		If String.ThisIsInventory Then
			FoundRows = Object.Inventories.FindRows(SearchParameters);
		Else
			FoundRows = Object.OrdersPendingSupply.FindRows(SearchParameters);
		EndIf;
		
		For Each It_ In FoundRows Do
			It_.ToOrder = String.ToOrder;
			It_.Rounded = 0;
			It_.OrderPackage = String.OrderPackage;
			It_.MinimumDeliveryLot = 0;
			It_.Mark = True;
			It_.DoNotRoundBeforeCreatingOrder = Response.HasChanges;
			Weight = It_.Weight;
		EndDo;
		
		// Creating a new line in orders with an empty destination
		If FoundRows.Count() = 0 Then
			NwRw = Object.OrdersPendingSupply.Add();
			FillPropertyValues(NwRw, It_);
			NwRw.Purpose = Undefined;
			NwRw.OrderDocument      = Undefined;
			NwRw.Required2  = 0;
			NwRw.ToOrder    = String.ToOrder;
			NwRw.DoNotRoundBeforeCreatingOrder = Response.HasChanges;

			
			FillIndexTree(False);
		EndIf;
		
	EndDo;
	
	TreeRow = Preview.FindByID(Response.TreeLineNumber);
	TreeRow.ToOrder = Response.InTotal;
	TreeRow.OrderPackage = String.OrderPackage;
	TreeRow.Weight = TreeRow.ToOrder * Weight;
	RecalculateOrderTotals(TreeRow.GetParent());
	CalculateTotals();
	GenerateWarningLabel(Items.Preview);
	
EndProcedure

&AtClient
Procedure SelectWarehouseCompletion(Warehouse, AdditionalParameters) Export
	
	If Warehouse = Undefined Then
		Return;
	EndIf;
	
	WarehouseSelectionEndsAtServer(Warehouse);
	FindOutPositionOfRowsAndGroupingsInTree(Items.Preview.SelectedRows);
	
EndProcedure

&AtClient
Procedure ChoosingSecurityMethod(Method, AdditionalParameters) Export
	
	If Method = Undefined Then
		Return;
	EndIf;
	
	ChoosingWayToEnsureEndAtServer(Method);
	FindOutPositionOfRowsAndGroupingsInTree(Items.Preview.SelectedRows);
	
EndProcedure

&AtClient
Procedure ManagerSelectionEnd(Manager, AdditionalParameters) Export
	
	If Manager = Undefined Then
		Return;
	EndIf;
	
	ChoosingManagerToEndAtServer(Manager);
	FindOutPositionOfRowsAndGroupingsInTree(Items.Preview.SelectedRows);
	
EndProcedure

#EndRegion

#Region StepCreatedOrders

&AtServer
Procedure SetStatusOnServer(ReferencesArrray, Status)
	
	BlockErrorTemplate     = NStr("vi = 'Không thể phong tỏa %1. %2';
									|ru = 'Не удалось заблокировать %1. %2';
									|en = 'Cannot block %1. %2'; fa = 'Cannot block %1. %2';
									|it = 'Impossibile bloccare %1. %2';
									|pl = 'Nie udało się zablokować %1. %2';
									|tr = '%1 engellenemedi. %2'");
	WriteErrorTemplate          = NStr("vi = 'Không thể ghi lại %1. %2';
										|ru = 'Не удалось записать %1. %2';
										|en = 'Cannot save %1. %2'; fa = 'Cannot save %1. %2';
										|it = 'Impossibile registrare %1. %2';
										|pl = 'Nie udało się zapisać %1. %2';
										|tr = '%1 kaydedilemedi. %2'");
	
	For Each Item In ReferencesArrray Do
		
		// Capturing an object for editing
		Try
			LockDataForEdit(Item.Ref);
		Except
			ErrorText = StrTemplate(BlockErrorTemplate, Item.Ref, BriefErrorDescription(ErrorInfo()));
			Common.MessageToUser(ErrorText, Item.Ref);
			Continue;
		EndTry;
		
		// Getting a Document object
		DocumentObject = Item.Ref.GetObject();
		
		// Setting the document status
		If Not DocumentObject.SetStatus(Status, Undefined) Then
			Continue;
		EndIf;
		
		// Document recording
		Try
			
			DocumentObject.Write(?(DocumentObject.Posted, DocumentWriteMode.Posting, DocumentWriteMode.Write));
			
			TableRow = TableDocuments.FindByID(Item.RowID);
			TableRow.Status = DocumentObject.Status;
			
		Except
			ErrorText = StrTemplate(WriteErrorTemplate, Item.Ref, BriefErrorDescription(ErrorInfo()));
			Common.MessageToUser(ErrorText, Item.Ref);
		EndTry;
		
	EndDo;
	
EndProcedure

#Region ServiceProceduresForCreatingOrders

&AtServer
Procedure UploadItemsMarkedToOrder(Table, TableName)

	For Each String In Object[TableName] Do

		If String.Mark And String.ToOrder > 0 Then

			NewRow = Table.Add();
			FillPropertyValues(NewRow, String);

		EndIf;

	EndDo;

EndProcedure

#EndRegion

&AtServer
Procedure ContinueWithOtherSelectionsOnServer()

	Object.Inventories.Clear();
	Object.OrdersPendingSupply.Clear();
	Object.SupplyMethods.Clear();
	TableDocuments.Clear();
	GeneratedOrders.Clear();
	InstallAssistantPages("StepDemandFilter");

EndProcedure

&AtServer
Procedure UpdateDocumentTableDetails(Ref)

	FilterParameters = New Structure("Document", Ref);

	ArrayOfFoundStrings = TableDocuments.FindRows(FilterParameters);
	If ArrayOfFoundStrings.Count() > 0 Then

		NewPropsValues = GetValuesOfDocumentDetailsFromLink(Ref);
		FillPropertyValues(ArrayOfFoundStrings[0], NewPropsValues);

	EndIf;

EndProcedure

&AtServerNoContext
Function RequestTextByDocumentType(DocumentType)
	
	If DocumentType = Type("DocumentRef.ByAssemblyDisassemblyOrder") Then
	
		QueryText = 
		"SELECT
		|	T.Ref                             AS Document,
		|	MAX(T.Status)                   AS Status,
		|	MAX(CASE
		|		WHEN T.Posted
		|			THEN 0
		|		WHEN T.DeletionMark
		|			THEN 1
		|		ELSE 2
		|	END)                               AS StandardPicture,
		|	MAX(T.Organization)              AS Organization,
		|	MAX(T.Warehouse)                    AS SupplySource,
		|	0                                    AS Sum,
		|	0                                    AS Currency,
		|	MAX(T.AssemblyDisassemblyEnd)  AS ShipmentDate,
		|	MIN(T.AssemblyDisassemblyEnd)   AS DeliveryDateMinimum
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS T
		|WHERE 
		|	T.Ref IN (&LinksToDocuments)
		|GROUP BY 
		|	T.Ref";
	
	ElsIf DocumentType = Type("DocumentRef.TransferOrder") Then
	
		QueryText = 
		"SELECT
		|	T.Ref                             AS Document,
		|	MAX(T.Status)                   AS Status,
		|	MAX(CASE
		|		WHEN T.Posted
		|			THEN 0
		|		WHEN T.DeletionMark
		|			THEN 1
		|		ELSE 2
		|	END)                               AS StandardPicture,
		|	MAX(T.Organization)              AS Organization,
		|	MAX(T.SourceWarehouse)               AS SupplySource,
		|	0                                          AS Sum,
		|	0                                          AS Currency,
		|	MAX(OrderingProducts.ReceiptEnd) AS ShipmentDate,
		|	MIN(OrderingProducts.ReceiptEnd)  AS DeliveryDateMinimum
		|FROM
		|	Document.TransferOrder AS T
		|		LEFT JOIN Document.TransferOrder.Goods AS OrderingProducts
		|		ON OrderingProducts.Ref = T.Ref
		|WHERE 
		|	T.Ref IN (&LinksToDocuments)
		|GROUP BY 
		|	T.Ref";
	
	ElsIf DocumentType = Type("DocumentRef.PurchaseRequest") Then
		
		QueryText = 
		"SELECT
		|	T.Ref                       AS Document,
		|	MAX(T.Status)             AS Status,
		|	MAX(CASE
		|		WHEN T.Posted
		|			THEN 0
		|		WHEN T.DeletionMark
		|			THEN 1
		|		ELSE 2
		|	END)                         AS StandardPicture,
		|	MAX(T.Organization)        AS Organization,
		|	MAX(ApplicationProducts.Partner) AS SupplySource,
		|	MAX(T.DocumentAmount)     AS Sum,
		|	MAX(T.Currency)             AS Currency,
		|	MAX(ApplicationProducts.RequestedDeliveryDate) AS ShipmentDate,
		|	MIN(ApplicationProducts.RequestedDeliveryDate) AS DeliveryDateMinimum
		|FROM
		|	Document.PurchaseRequest AS T
		|		LEFT JOIN Document.PurchaseRequest.Goods AS ApplicationProducts
		|		ON ApplicationProducts.Ref = T.Ref
		|WHERE 
		|	T.Ref IN (&LinksToDocuments)
		|GROUP BY 
		|	T.Ref";
		
	ElsIf DocumentType = Type("DocumentRef.PurchaseOrder") Then
		
		QueryText = 
		"SELECT
		|	T.Ref                             AS Document,
		|	MAX(T.Status)                   AS Status,
		|	MAX(CASE
		|		WHEN T.Posted
		|			THEN 0
		|		WHEN T.DeletionMark
		|			THEN 1
		|		ELSE 2
		|	END)                               AS StandardPicture,
		|	MAX(T.Organization)              AS Organization,
		|	MAX(T.Partner)                  AS SupplySource,
		|	MAX(T.DocumentAmount)           AS Sum,
		|	MAX(T.Currency)                   AS Currency,
		|	MAX(OrderingProducts.DateOfReceipt) AS ShipmentDate,
		|	MIN(OrderingProducts.DateOfReceipt)  AS DeliveryDateMinimum
		|FROM
		|	Document.PurchaseOrder AS T
		|		LEFT JOIN Document.PurchaseOrder.Goods AS OrderingProducts
		|		ON OrderingProducts.Ref = T.Ref
		|WHERE 
		|	T.Ref IN (&LinksToDocuments)
		|GROUP BY 
		|	T.Ref";
	ElsIf DocumentType = Type("DocumentRef.OrderOfMaterialsForProduction") Then
	
		QueryText = 
		"SELECT
		|	T.Ref                             AS Document,
		|	MAX(T.Status)                   AS Status,
		|	MAX(CASE
		|		WHEN T.Posted
		|			THEN 0
		|		WHEN T.DeletionMark
		|			THEN 1
		|		ELSE 2
		|	END)                               AS StandardPicture,
		|	MAX(T.Organization)              AS Organization,
		|	MAX(T.Warehouse)                          AS SupplySource,
		|	0                                          AS Sum,
		|	0                                          AS Currency,
		|	MAX(OrderingProducts.ReceiptEnd) AS ShipmentDate,
		|	MIN(OrderingProducts.ReceiptEnd)  AS DeliveryDateMinimum
		|FROM
		|	Document.OrderOfMaterialsForProduction AS T
		|		LEFT JOIN Document.OrderOfMaterialsForProduction.Goods AS OrderingProducts
		|		ON OrderingProducts.Ref = T.Ref
		|WHERE 
		|	T.Ref IN (&LinksToDocuments)
		|GROUP BY 
		|	T.Ref";
		
	ElsIf DocumentType = Type("DocumentRef.SubcontractOrder2_5") Then
		
		QueryText = 
		"SELECT
		|	T.Ref                             AS Document,
		|	MAX(T.Status)                   AS Status,
		|	MAX(CASE
		|		WHEN T.Posted
		|			THEN 0
		|		WHEN T.DeletionMark
		|			THEN 1
		|		ELSE 2
		|	END)                               AS StandardPicture,
		|	MAX(T.Organization)              AS Organization,
		|	MAX(T.Partner)                  AS SupplySource,
		|	MAX(T.DocumentAmount)           AS Sum,
		|	MAX(T.Currency)                   AS Currency,
		|	MAX(
		|		ISNULL(StageGoods.ProductionDate, 
		|		OrderingProducts.DateOfReceipt
		|			)
		|		) AS ShipmentDate,
		|	MIN(
		|		ISNULL(StageGoods.ProductionDate, 
		|		OrderingProducts.DateOfReceipt
		|			)
		|		)  AS DeliveryDateMinimum,
		|	MAX(CASE WHEN T.Posted AND T.Status IN(
		|		VALUE(Enum.TollingOrderStatuses.ToSupply),
		|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
		|		VALUE(Enum.TollingOrderStatuses.Closed)) THEN 0
		|			ELSE 1
		|		END)                               AS NotOnSchedule,
		|	0                                        AS NotScheduledForProduction
		|FROM
		|	Document.SubcontractOrder2_5 AS T
		|	
		|	LEFT JOIN Document.SubcontractOrder2_5.ManufacturedProducts AS OrderingProducts
		|	ON OrderingProducts.Ref = T.Ref
		|	
		|	LEFT JOIN Document.ProductionStage2_2.ManufacturedProducts AS StageGoods
		|	ON StageGoods.Ref.SubcontractOrder = T.Ref
		|	AND NOT StageGoods.Canceled
		|WHERE 
		|	T.Ref IN (&LinksToDocuments)
		|
		|GROUP BY 
		|	T.Ref
		|";
		

	ElsIf DocumentType = Type("DocumentRef.ProductionOrder2_2") Then
		
		QueryText = 
		"SELECT
		|	T.Ref                             AS Document,
		|	MAX(T.Status)                   AS Status,
		|	MAX(CASE
		|		WHEN T.Posted
		|			THEN 0
		|		WHEN T.DeletionMark
		|			THEN 1
		|		ELSE 2
		|	END)                               AS StandardPicture,
		|	MAX(T.Organization)              AS Organization,
		|	MAX(T.Department)   AS SupplySource,
		|	0                           AS Sum,
		|	0                           AS Currency,
		|	MAX(T.DemandDate) AS ShipmentDate,
		|	MIN(T.DemandDate)  AS DeliveryDateMinimum
		|FROM
		|	Document.ProductionOrder2_2 AS T
		|WHERE 
		|	T.Ref IN (&LinksToDocuments)
		|GROUP BY 
		|	T.Ref";
	EndIf;
	
	Return QueryText;
EndFunction

&AtServerNoContext
Function GetValuesOfDocumentDetailsFromLink(DocumentRef)
	
	Query = New Query(RequestTextByDocumentType(TypeOf(DocumentRef)));
	Query.SetParameter("LinksToDocuments", DocumentRef);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	AttributesValues = New Structure("
		|Document,
		|Status,
		|StandardPicture,
		|Organization,
		|SupplySource,
		|ShipmentDate,
		|Sum,
		|Currency");
	
	FillPropertyValues(AttributesValues, Selection);
	If AttributesValues.ShipmentDate <> Selection.DeliveryDateMinimum Then
		AttributesValues.ShipmentDate = '00010101'; //we clear the delivery date if there are several of them in the document and they are different
	EndIf;
	
	Return AttributesValues;
	
EndFunction

&AtServer
Procedure UpdateValuesOfDocumentTableDetails()
	
	TypesUsed	= New Array;
	LinksToDocuments	= New Array;
	QueriesArray		= New Array;
	
	For Each TableRow In TableDocuments Do
		DocumentType = TypeOf(TableRow.Document);
		LinksToDocuments.Add(TableRow.Document);
		If TypesUsed.Find(DocumentType) = Undefined Then
			TypesUsed.Add(DocumentType);
			QueriesArray.Add(RequestTextByDocumentType(DocumentType));
		EndIf;
	EndDo;
	
	Query = New Query(StrConcat(QueriesArray, TMCommonUse.QuerySeparatorInJoin()));
	Query.SetParameter("LinksToDocuments", LinksToDocuments);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		ArrayOfFoundStrings = TableDocuments.FindRows(New Structure("Document", Selection.Document));
		If ArrayOfFoundStrings.Count() > 0 Then
			FillPropertyValues(ArrayOfFoundStrings[0], Selection);
			If ArrayOfFoundStrings[0].ShipmentDate <> Selection.DeliveryDateMinimum Then
				ArrayOfFoundStrings[0].ShipmentDate = '00010101'; //we clear the delivery date if there are several of them in the document and they are different
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region LogicOfForm

&AtServer
Function NextGoToStepConfiguringSecurityMethodsOnServer(Result)
	
	TableOfMethods = GetFromTempStorage(Result.ResultAddress);
	
	If ValueIsFilled(TableOfMethods) Then
		
		Object.SupplyMethods.Load(TableOfMethods);
		InstallAssistantPages("StepCustomizeSupplyMethods");
		
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtServer
Function NextToInventoryStep(Result)
	
	ClearSelections_();
	
	Object.Inventories.Clear();
	
	Table = GetFromTempStorage(Result.ResultAddress);
	If Not ValueIsFilled(Table) Then
		Return False;
	EndIf;
	ThisIsFirstMessageMinInventory = True;
	ThisIsFirstMessageMaxInventory = True;
	ThisIsFirstMessageInterval = True;
	For Each OwnGoods In Table Do
	
		RowStocks = Object.Inventories.Add();
	
		FillPropertyValues(RowStocks, OwnGoods);
	
		CalculationResult2 = DataProcessors.DemandFulfillment.MinimumAndMaximumStocks(RowStocks);
		FillPropertyValues(RowStocks, CalculationResult2);
	
		CalculationResult2 = DataProcessors.DemandFulfillment.QuantityToOrderToMaintainStock(RowStocks);
		FillPropertyValues(RowStocks, CalculationResult2);
	
		CalculationResult2 = DataProcessors.DemandFulfillment.StockLevelAndPictureChangeMethod(RowStocks);
		FillPropertyValues(RowStocks, CalculationResult2);
	
		RowStocks.RecommendedToOrder = RowStocks.ToOrder;
		RowStocks.SupplySource = ProcessEmptySource(RowStocks.SupplySource, TextNotFilledIn);
		
		If OwnGoods.ErrorInCalculatingIntervalBeforeDeliveryDate
				And Not OwnGoods.ErrorSettingIntervalToDeliveryDate And ThisIsFirstMessageMinInventory Then
			MessageText = NStr("vi = 'Chưa điền lịch biểu làm việc của kho đến ngày giao hàng. Để tính toán vật tư tối thiểu, tất cả các ngày trước ngày giao hàng được coi là ngày làm việc.';
								|ru = 'Не заполнен график работы склада до даты поставки. Для расчета минимального запаса все дни до даты поставки посчитаны рабочими.';
								|en = 'The warehouse''s work schedule is not filled till the delivery date. To calculate minimum inventory, all days before the delivery date are considered workdays.'; fa = 'The warehouse''s work schedule is not filled till the delivery date. To calculate minimum inventory, all days before the delivery date are considered workdays.';
								|it = 'Не заполнен график работы склада до даты поставки. Для расчета минимального запаса все дни до даты поставки посчитаны рабочими.';
								|pl = 'The warehouse''s work schedule is not filled till the delivery date. To calculate minimum inventory, all days before the delivery date are considered workdays.';
								|tr = 'Teslimat tarihine kadarki ambar çalışma takvimi doldurulmadı. Minimum stoku hesaplamak için, teslimat tarihinden önceki tüm günler iş günü sayılmaktadır.'");
			Common.MessageToUser(MessageText);
			ThisIsFirstMessageMinInventory = False;
		EndIf;
		If OwnGoods.ErrorInCalculatingIntervalBetweenDeliveries
				And Not OwnGoods.ErrorSettingIntervalBetweenDeliveries And ThisIsFirstMessageMaxInventory Then
			MessageText = NStr("vi = 'Chưa điền lịch biểu làm việc của kho đến giới hạn của khoảng thời gian đảm bảo. Để tính vật tư tối đa, tất cả các ngày từ ngày giao hàng đến giới hạn khoảng thời gian đảm bảo được tính là ngày làm việc.';
								|ru = 'Не заполнен график работы склада до границы обеспечиваемого периода. Для расчета максимального запаса все дни от даты поставки до границы обеспечиваемого периода посчитаны рабочими.';
								|en = 'The warehouse''s work schedule is not filled till the covered period boundary. To calculate maximum inventory, all days from the delivery date to the covered period boundary are considered workdays.'; fa = 'The warehouse''s work schedule is not filled till the covered period boundary. To calculate maximum inventory, all days from the delivery date to the covered period boundary are considered workdays.';
								|it = 'Не заполнен график работы склада до границы обеспечиваемого периода. Для расчета максимального запаса все дни от даты поставки до границы обеспечиваемого периода посчитаны рабочими.';
								|pl = 'The warehouse''s work schedule is not filled till the covered period boundary. To calculate maximum inventory, all days from the delivery date to the covered period boundary are considered workdays.';
								|tr = 'Teminat verilecek süre sınırına kadar olan ambar çalışma takvimi doldurulmadı. Maksimum stoku hesaplayabilmek için, teslim tarihi itibarıyla temin edilecek süre sınırlamasına kadar tüm günler, iş günü sayılacaktır.'");
			Common.MessageToUser(MessageText);
			ThisIsFirstMessageMaxInventory = False;
		EndIf;
		If OwnGoods.ErrorSettingIntervalBetweenDeliveries And ThisIsFirstMessageInterval Then
			MessageText = NStr("vi = 'Chưa điền ngày giao hàng và/hoặc giới hạn của kỳ đảm bảo. Chưa tính toán vật tư tối đa trong các dòng như vậy';
								|ru = 'Не заполнены даты поставки и/или граница обеспечиваемого периода. Максимальный запас в таких строках не рассчитан';
								|en = 'The delivery dates and/or the covered period boundary are not filled in. Maximum inventory in such lines is not calculated'; fa = 'The delivery dates and/or the covered period boundary are not filled in. Maximum inventory in such lines is not calculated';
								|it = 'Не заполнены даты поставки и/или граница обеспечиваемого периода. Максимальный запас в таких строках не рассчитан';
								|pl = 'The delivery dates and/or the covered period boundary are not filled in. Maximum inventory in such lines is not calculated';
								|tr = 'Не заполнены даты поставки и/или граница обеспечиваемого периода. Максимальный запас в таких строках не рассчитан'");
			Common.MessageToUser(MessageText);
			ThisIsFirstMessageInterval = False;
		EndIf;

	EndDo;
	
	FillIndexTree(True);
	
	// Recalculating rounding for all marked lines
	For Each String In Object.Inventories Do
		If String.Mark Then
			// There are no duplicate rows in the Inventory table. Each line is rounded separately
			
			RowsMap = New Map();
			RowsMap.Insert(String, True);
			RoundUpMatchingRows(RowsMap, UsePackages);
		EndIf;
	EndDo;
	
	CalculateTotalsOnServer();
	
	InstallAssistantPages("StepInventories");
	
	Return True;
	
EndFunction

&AtServer
Function NextToOrdersStep(Result)
	
	Table = GetFromTempStorage(Result.ResultAddress);
	If Not ValueIsFilled(Table) Then
		Return False;
	EndIf;
	
	If Not UsePurchaseOrders Then
		HasErrors = False;
		EmptyMethods = Object.Inventories.FindRows(New Structure("SupplyMethod", Catalogs.ProcurementStrategies.EmptyRef()));
		For Each String In EmptyMethods Do
			If String.ToOrder > 0 And String.Mark Then
				HasErrors = True;
				Break;
			EndIf;
		EndDo;
		If HasErrors Then
			ReportErrorInEmptySecurityMethod(EmptyMethods);
			Return False;
		EndIf;
	EndIf;
	
	Object.OrdersPendingSupply.Load(Table);
	
	// The final calculation of the recommendation for the order.
	ThereAreWorks = False;
	ThereAreProducts_ = False;
	For Each OrdersLine In Object.OrdersPendingSupply Do
		
		CalculationResult2 = DataProcessors.DemandFulfillment.QuantityToOrderToEnsureOrders(OrdersLine);
		FillPropertyValues(OrdersLine, CalculationResult2);
	
		OrdersLine.RecommendedToOrder = OrdersLine.ToOrder;
		OrdersLine.Supplied = OrdersLine.ToReserve;
	
		OrdersLine.Recipient = ?(OrdersLine.ThisIsWork, OrdersLine.ReceivingBusinessUnit, OrdersLine.Warehouse);
		FillInCalculatedFieldsOfOrdersLine(OrdersLine, CachedValues);
	
		OrdersLine.SupplySource = ProcessEmptySource(OrdersLine.SupplySource, TextNotFilledIn);
		
		ThereAreWorks = ThereAreWorks Or OrdersLine.ThisIsWork;
		ThereAreProducts_ = ThereAreProducts_ Or Not OrdersLine.ThisIsWork;
	
	EndDo;
	
	ClearSelectionsOrders();
	
	Items.Recipient.Title = ?(ThereAreWorks And ThereAreProducts_, NStr("vi = 'Người nhận';
																		|ru = 'Получатель';
																		|en = 'Recipient'; fa = 'گیرنده';
																		|it = 'Destinatario';
																		|pl = 'Recipient';
																		|tr = 'Alıcı'"),
		?(ThereAreWorks, NStr("vi = 'Bộ phận-nơi nhận';
								|ru = 'Подразделение-получатель';
								|en = 'Receiving business unit'; fa = 'واحد تجاری دریافت‌کننده';
								|it = 'Reparto-destinatario';
								|pl = 'Receiving business unit';
								|tr = 'Alıcı departman'"), NStr("vi = 'Kho bãi';
																		|ru = 'Склад';
																		|en = 'Warehouse'; fa = 'Warehouse';
																		|it = 'Magazzino';
																		|pl = 'Warehouse';
																		|tr = 'Ambar'")));
		
	Items.Recipient.Visible = UseSeveralWarehouses Or ThereAreWorks;
	
	FillIndexTree(False);
	
	RowsMap = New Map();
	Collection = SearchIndexes.GetItems(); 
	For Each Root In Collection Do
		
		RowsMap.Clear();
		Rows = Root.GetItems();
		For Each TreeRow In Rows Do
			
			FormTable = ?(TreeRow.TableInventory, Object.Inventories, Object.OrdersPendingSupply);
			TableRow = FormTable.FindByID(TreeRow.LineID);
			
			If TableRow.Mark Then
				RowsMap.Insert(TableRow, TreeRow.TableInventory);
			EndIf;
			
		EndDo;
		
		RoundUpMatchingRows(RowsMap, UsePackages);
		
	EndDo;
	
	CalculateTotalsOnServer();
	
	InstallAssistantPages("StepOrders");
	
	Return True;
	
EndFunction

&AtServer
Function NextToOrderEditingStep(Result)
	
	OrderTree = GetFromTempStorage(Result.ResultAddress);
	If Not ValueIsFilled(OrderTree) Then
		Return False;
	EndIf;
	
	If Not UsePurchaseOrders Then
		HasErrors = False;
		EmptyMethods = Object.OrdersPendingSupply.FindRows(New Structure("SupplyMethod", Catalogs.ProcurementStrategies.EmptyRef()));
		For Each String In EmptyMethods Do
			If String.ToOrder > 0 And String.Mark Then
				HasErrors = True;
				Break;
			EndIf;
		EndDo;
		If HasErrors Then
			ReportErrorInEmptySecurityMethod(EmptyMethods);
			Return False;
		EndIf;
	EndIf;
	
	InstallAssistantPages("StepOrderEditing");
	
	ValueToFormAttribute(OrderTree, "Preview");
	
	Return True;
	
EndFunction

// Returns:
// 	See RecordAlerts
&AtServer
Function NextToGeneratedOrdersStep(Result)
	
	OrderGenerationResults = GetFromTempStorage(OrderPlacementResultAddress);
	
	If ValueIsFilled(OrderGenerationResults) Then // The task was interrupted before something was recorded
		
		TableDocuments.Load(OrderGenerationResults.DocumentsTable);
		GeneratedOrders.LoadValues(OrderGenerationResults.DocumentsTable.UnloadColumn("Document"));
		Items.Status.Visible = TableDocuments.Total("UsingStatuses");
		
		InstallAssistantPages("StepCreatedOrders");
		
		For Each Message In OrderGenerationResults.ListOfMessages Do
			Message.Message();
		EndDo;
		
		If Result = Undefined Or Result.Status <> "Completed2" Then
			Message = New UserMessage();
			If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
				Message.Text = NStr("vi = 'Các giấy đề nghị chưa được lập đầy đủ';
									|ru = 'Заявки были сформированы не полностью';
									|en = 'Requests were not fully generated'; fa = 'Requests were not fully generated';
									|it = 'Requests were not fully generated';
									|pl = 'Requests were not fully generated';
									|tr = 'Talepler tam olarak oluşturulmadı'");
			Else
				Message.Text = NStr("vi = 'Đơn đặt hàng chưa được lập đầy đủ';
									|ru = 'Заказы были сформированы не полностью';
									|en = 'Orders were not fully generated'; fa = 'Orders were not fully generated';
									|it = 'Gli ordini non sono stati completamente generati';
									|pl = 'Zamówienia nie zostały w pełni uformowane';
									|tr = 'Siparişler tam olarak oluşturulmadı'");
			EndIf;
			Message.Message();
		EndIf;
		
		Return RecordAlerts();
		
	Else
		
		Return New Array();
		
	EndIf;
	
EndFunction

&AtServer
Procedure BackToStepsOfSelectingNeedsOnClient(Result)
	
	ErrorList = GetFromTempStorage(Result.ResultAddress);
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
	TableDocuments.Clear();
	GeneratedOrders.Clear();
	
	InstallAssistantPages("StepOrderEditing");
	
EndProcedure

// Returns:
//  Array of Structure:
// 	 * EventName - String - event name.
//   * NotificationParameters - Structure - Structure.
//   * Source - DocumentRef.PurchaseOrder - Document.
&AtServer
Function RecordAlerts()
	
	Notifications = New Array();
	For Each String In TableDocuments Do
		
		EventName = StrTemplate("Record_%1", String.Document.Metadata().Name);
		WriteMode = ?(String.StandardPicture = 0, DocumentWriteMode.Posting, DocumentWriteMode.Write);
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("WriteMode", WriteMode);
		NotificationParameters.Insert("ThereIsOrder_", True);
		If EventName = "Write_ProductionOrder" Then
			NotificationParameters = String.Document;
		ElsIf EventName = "Write_ProductionOrder2_2" Then
			EventName = "Write_ProductionOrder";
			NotificationParameters = String.Document;
		EndIf;
		Notifications.Add(
			New Structure("EventName, NotificationParameters, Source",
			EventName, NotificationParameters, String.Document));
		
	EndDo;
	
	Return Notifications;
	
EndFunction

&AtServer
Procedure InstallAssistantPages(StepName)

	If StepName = "StepDemandFilter" Then

		Items.Next.DefaultButton = True;
		Items.Assistant.CurrentPage = Items.StepDemandFilter;
		Items.TheWritingStep.Title = NStr("vi = 'Bước 1/6. Lọc nhu cầu';
											|ru = 'Шаг 1 из 6. Отбор потребностей';
											|en = 'Step 1 of 6. Filter demands'; fa = 'Step 1 of 6. Filter demands';
											|it = 'Passaggio 1 di 6. Selezione dei fabbisogni';
											|pl = 'Krok 1 z 6. Filtr potrzeb';
											|tr = '6 adım arasından 1. adım: Gereksinim filtresi'");

	ElsIf StepName = "StepCustomizeSupplyMethods" Then

		Items.NextSetup_3.DefaultButton = True;
		Items.Assistant.CurrentPage = Items.StepCustomizeSupplyMethods;
		Items.TheWritingStep.Title = NStr("vi = 'Bước 2/6. Tùy chỉnh phương thức đảm bảo';
											|ru = 'Шаг 2 из 6. Настройка способов обеспечения';
											|en = 'Step 2 of 6. Customize procurement strategy'; fa = 'Step 2 of 6. Customize procurement strategy';
											|it = 'Passaggio 2 di 6. Configurazione dei metodi di approvvigionamento';
											|pl = 'Krok 2 z 6. Ustawienie metody zaopatrzenia';
											|tr = '6 adımdan 2''cisi: Tedarik yöntemi ayarları'");

	ElsIf StepName = "StepInventories" Then

		Items.Assistant.CurrentPage = Items.DemandStep;
		Items.PagesCommandsAndDemandFilters.CurrentPage = Items.PageCommandsAndFiltersInventory;
		Items.PageCommandsAndFiltersOrders.Visible = False;
		Items.PageCommandsAndFiltersInventory.Visible = True;
		Items.PagesDemandTable.CurrentPage = Items.PageTableInventory;
		Items.NextTheOrderStructure.DefaultButton = True;
		Items.TheWritingStep.Title = NStr("vi = 'Bước 3/6. Duy trì số dư trong kho';
											|ru = 'Шаг 3 из 6. Поддержание запасов';
											|en = 'Step 3 of 6. Inventory level control'; fa = 'Step 3 of 6. Inventory level control';
											|it = 'Passaggio 3 di 6. Mantenimento delle scorte';
											|pl = 'Krok 3 z 6. Utrzymanie zapasów';
											|tr = '6 adımdan 3''cüsü. Stok desteği'");

	ElsIf StepName = "StepOrders" Then

		Items.Assistant.CurrentPage = Items.DemandStep;
		Items.PagesCommandsAndDemandFilters.CurrentPage = Items.PageCommandsAndFiltersOrders;
		Items.PageCommandsAndFiltersOrders.Visible = True;
		Items.PageCommandsAndFiltersInventory.Visible = False;
		Items.PagesDemandTable.CurrentPage = Items.PageTableOrders;
		Items.NextTheOrderStructure.DefaultButton = True;
		Items.TheWritingStep.Title = NStr("vi = 'Bước 4/6. Đảm bảo đơn hàng cần giao';
											|ru = 'Шаг 4 из 6. Обеспечение заказов к отгрузке';
											|en = 'Step 4 of 6. Select the demand'; fa = 'Step 4 of 6. Select the demand';
											|it = 'Passaggio 4 di 6. Approvvigionamento degli ordini per la spedizione';
											|pl = 'Krok 4 z 6. Zabezpieczanie zamówień do wysyłki';
											|tr = '6 adımdan 4''cüsü. Karşılanacak siparişlerin sevkiyatı'");
		
	ElsIf StepName = "StepOrderEditing" Then

		Items.Assistant.CurrentPage = Items.StepOrderEditing;
		Items.ToFormTheOrders.DefaultButton = True;
		If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
			Items.TheWritingStep.Title = NStr("vi = 'Bước 5/6. Xem trước và chỉnh sửa giấy đề nghị';
												|ru = 'Шаг 5 из 6. Предварительный просмотр и редактирование заявок';
												|en = 'Step 5 of 6. Request preview and editing'; fa = 'Step 5 of 6. Request preview and editing';
												|it = 'Step 5 of 6. Request preview and editing';
												|pl = 'Step 5 of 6. Request preview and editing';
												|tr = 'Adım 5 / 6. Taleplerin önizlenmesi ve düzenlenmesi'");
		Else
			Items.TheWritingStep.Title = NStr("vi = 'Bước 5/6. Xem trước và chỉnh sửa đơn hàng';
												|ru = 'Шаг 5 из 6. Предварительный просмотр и редактирование заказов';
												|en = 'Step 5 of 6. Order preview and editing'; fa = 'Step 5 of 6. Order preview and editing';
												|it = 'Passaggio 5 di 6. Anteprima e rettifica degli ordini';
												|pl = 'Krok 5 z 6. Wstępny przegląd i edycja zamówień';
												|tr = '6 adımdan 5''cisi. Siparişleri ön görüntüle ve düzenle'");
		EndIf;

	ElsIf StepName = "StepCreatedOrders" Then
		
		Items.Assistant.CurrentPage = Items.StepCreatedOrders;
		Items.ContinueWithOtherFilters.DefaultButton = True;
		If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
			Items.TheWritingStep.Title = NStr("vi = 'Bước 6/6. Làm rõ giấy đề nghị đã tạo';
												|ru = 'Шаг 6 из 6. Уточнение сформированных заявок';
												|en = 'Step 6 of 6. Confirmation of created requests'; fa = 'Step 6 of 6. Confirmation of created requests';
												|it = 'Step 6 of 6. Confirmation of created requests';
												|pl = 'Step 6 of 6. Confirmation of created requests';
												|tr = 'Adım 6 / 6. Oluşturulan taleplerin netleştirilmesi'");
		Else
			Items.TheWritingStep.Title = NStr("vi = 'Bước 6/6. Làm rõ đơn hàng đã tạo';
												|ru = 'Шаг 6 из 6. Уточнение сформированных заказов';
												|en = 'Step 6 of 6. Confirmation of created orders'; fa = 'Step 6 of 6. Confirmation of created orders';
												|it = 'Passaggio 6 di 6. Perfezionamento degli ordini generati';
												|pl = 'Krok 6 z 6. Uściślenie utworzonych zamówień';
												|tr = '6 adımdan 6''cısı. Oluşturulan siparişlerin iyileştirilmesi'");
		EndIf;
	EndIf;
	
	ProcessingOfDocumentWritingNotificationsIsEnabled = False;

EndProcedure

&AtClient
Procedure GoToDocumentsStepOnClient()
	
	If ShoppingCartTotalFieldTotalLines = 0 Then
		
		If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
			ErrorText = NStr("vi = 'Không có yêu cầu cần lập. Hãy đặt dấu số lượng tại cột ""Chuyển sang giấy đề nghị"" đối với mặt hàng cần đặt.';
							|ru = 'Нет заявок к оформлению. Отметьте флажком количество в колонке ""В заявку"" для номенклатурной позиции, которую необходимо заказать.';
							|en = 'No requests for registration. Select the quantity in the ""To request"" column for the item to be ordered.'; fa = 'No requests for registration. Select the quantity in the ""To request"" column for the item to be ordered.';
							|it = 'No requests for registration. Select the quantity in the ""To request"" column for the item to be ordered.';
							|pl = 'No requests for registration. Select the quantity in the ""To request"" column for the item to be ordered.';
							|tr = 'Düzenlenecek talep mevcut değil. Lütfen sipariş etmek istediğiniz ürün için ""Talebe ekle"" sütunundaki miktarı işaretleyin.'");
		Else
			ErrorText = NStr("vi = 'Không có đơn hàng cần lập. Hãy đánh dấu bằng hộp kiểm số lượng trong cột ""Cần đặt"" đối với mặt hàng cần đặt.';
							|ru = 'Нет заказов к оформлению. Отметьте флажком количество в колонке ""К заказу"" для номенклатурной позиции, которую необходимо заказать.';
							|en = 'No orders for registration. Select quantity in the ""To order"" column for product item to be ordered.'; fa = 'No orders for registration. Select quantity in the ""To order"" column for product item to be ordered.';
							|it = 'No orders for registration. Select quantity in the ""To order"" column for product item to be ordered.';
							|pl = 'No orders for registration. Select quantity in the ""To order"" column for product item to be ordered.';
							|tr = 'Düzenlenecek sipariş mevcut değil. Lütfen sipariş etmek istediğiniz ürünün ""Sipariş edilecek"" sütunundaki miktarını kontrol edin.'");
		EndIf;
		CommonClient.MessageToUser(ErrorText);
		
	Else
		
		TimeConsumingOperation = CreatingOrdersInBackground();
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisForm);
		
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation,
			New CallbackDescription("CreatingOrdersInBackgroundCompletion", ThisForm),
			IdleParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DCSSelections

&AtServer
Procedure InitializeSettingsComposerForSelections(AvailableTypesOfCollateral)
	
	DataProcessor = FormAttributeToValue("Object");
	DataCompositionSchema = DataProcessor.GetTemplate("TemplateForServerFilters");
	HideSupplyTypeSelection(DataCompositionSchema, AvailableTypesOfCollateral);
	SetAvailableTypesOfVSKDSoftware(DataCompositionSchema, AvailableTypesOfCollateral);
	SetParametersForSelectingVskdStorerooms(DataCompositionSchema);
	
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	
	SettingsSource = New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema); 
	FilterSettingsComposer.Initialize(SettingsSource);
	FilterSettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	FilterSettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);

EndProcedure

&AtServer
Procedure SetAvailableTypesOfVSKDSoftware(DataCompositionSchema, AvailableTypesOfCollateral)
	
	SecurityTypeField = DataCompositionSchema.DataSets[0].Fields.Find(New DataCompositionField("SupplyType"));
	
	List = New ValueList();
	List.LoadValues(AvailableTypesOfCollateral);
	SecurityTypeField.SetAvailableValues(List);
	
	SecuritySourceField = DataCompositionSchema.DataSets[0].Fields.Find(New DataCompositionField("SupplySource"));
	
	SecuritySourceField.ValueType = AvailableCollateralSourceTypes(AvailableTypesOfCollateral);
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingVskdStorerooms(DataCompositionSchema)

	If Parameters.Property("SelectionByWorkshopStorerooms") And Parameters.SelectionByWorkshopStorerooms Then
		WarehouseField = DataCompositionSchema.DataSets[0].Fields.Find(New DataCompositionField("Warehouse"));
		TMCommonUseClientServer.AddSelectionParameter(WarehouseField, "ShopFloorStockroom", True);
	EndIf;
	
EndProcedure

&AtServer
Procedure HideSupplyTypeSelection(DataCompositionSchema, AvailableTypesOfCollateral)
	
	If Not AvailableTypesOfCollateral.Count() = 1 Then
		Return;
	EndIf;
	
	SupplyTypeLayoutField = New DataCompositionField("SupplyType");
	For Each FilterElement In DataCompositionSchema.DefaultSettings.Filter.Items Do
		
		If FilterElement.LeftValue = SupplyTypeLayoutField Then
			FilterElement.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	Settings = New Structure();
	Settings.Insert("FilterUnsecured");
	Settings.Insert("CalculationOfSeparateNeedsTakingIntoAccountBalancesInAllWarehouses");
	Settings.Insert("PurchaseObjective");
	
	FillPropertyValues(Settings, ThisObject);
	Settings.Insert("UserSettings", FilterSettingsComposer.UserSettings);
	
	SettingsKey = ?(ValueIsFilled(PurposeUseKey), PurposeUseKey, "Main");
	Common.CommonSettingsStorageSave("DataProcessor.DataProcessorDemandFulfillment", SettingsKey, Settings);
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	SettingsKey = ?(ValueIsFilled(PurposeUseKey), PurposeUseKey, "Main");
	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.DataProcessorDemandFulfillment", SettingsKey);

	If TypeOf(SettingsValue) = Type("Structure") Then

		FilterSettingsComposer.LoadUserSettings(SettingsValue.UserSettings);
		FilterSettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);

		FillPropertyValues(ThisObject, SettingsValue);

		If Not SettingsValue.Property("FilterUnsecured") Then

			FilterUnsecured = True;

		EndIf;
		
		If Not SettingsValue.Property("CalculationOfSeparateNeedsTakingIntoAccountBalancesInAllWarehouses") Then
			CalculationOfSeparateNeedsTakingIntoAccountBalancesInAllWarehouses = 1;
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure ProcessSoftwareAvailability(SelectionParameter)
	
	ChoiceList = Items.FilterBySupplyType.ChoiceList;
	
	// We limit the possible types of security depending on the rights and functional options.
	AvailableTypes = DataProcessors.DemandFulfillment.AvailableTypesOfCollateral(PurposeUseKey);
	If AvailableTypes <> Undefined Then
		ChoiceList.Clear();
		For Each SupplyType In AvailableTypes Do
			ChoiceList.Add(SupplyType);
		EndDo;
	EndIf;
	
	AvailableSourceTypes = AvailableCollateralSourceTypes(AvailableTypes);
	If ValueIsFilled(AvailableSourceTypes) Then
		Items.FilterBySupplySource.TypeRestriction = AvailableSourceTypes;
	Else
		Items.FilterBySupplySource.Visible = False;
	EndIf;
	
	// We are preparing lists of selection restrictions for the method support fields
	AvailableTypes = ChoiceList.UnloadValues();
	AvailableSupplyTypesWithTransfer = New FixedArray(AvailableTypes);
	DisplacementIndex = AvailableTypes.Find(PredefinedValue("Enum.SupplyTypes.Move"));
	If DisplacementIndex <> Undefined Then
		AvailableTypes.Delete(DisplacementIndex);
	EndIf;
	AvailableSupplyTypesWithoutTransfer = New FixedArray(AvailableTypes);
	AssemblyIndex = AvailableTypes.Find(PredefinedValue("Enum.SupplyTypes.AssemblyDisassembly"));
	If AssemblyIndex <> Undefined Then
		AvailableTypes.Delete(AssemblyIndex);
	EndIf;
	RecyclingIndex = AvailableTypes.Find(PredefinedValue("Enum.SupplyTypes.ProductionByThirdParty"));
	If RecyclingIndex <> Undefined Then
		AvailableTypes.Delete(RecyclingIndex);
	EndIf;
	AvailableTypesOfWorkSupply = New FixedArray(AvailableTypes);
	
	// We limit the possible types of support when starting processing from the production subsystem.
	If ValueIsFilled(SelectionParameter) Then
		If ChoiceList.FindByValue(SelectionParameter) = Undefined Then
			ChoiceList.Clear();
			FilterBySupplyType = Enums.SupplyTypes.EmptyRef();
		Else
			ChoiceList.Clear();
			ChoiceList.Add(SelectionParameter);
			FilterBySupplyType = SelectionParameter;
		EndIf;
	EndIf;

	If ChoiceList.Count() = 1 Then
		FilterBySupplyType = Items.FilterBySupplyType.ChoiceList[0].Value;
	EndIf;
	
	// Customize the form as a whole depending on the types of software available.
	If ChoiceList.Count() = 1 Then
		
		Items.FilterBySupplyType.Type = FormFieldType.LabelField;
		Items.FilterBySupplyType.TextColor = StyleColors.NoteText;
		Items.FilterBySupplyType.Font = New Font(Items.FilterBySupplyType.Font,,,True);
		
	ElsIf ChoiceList.Count() = 0 Then
		
		If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
			
			If Not UsePurchaseRequests Then
				Items.NoAvailableSupplyTypes.Title =
					NStr("vi = 'Cài đặt hiện tại không cho phép tạo giấy đề nghị mua hàng.
					|Để tạo giấy đề nghị, cần thiết lập việc sử dụng chúng trong phần ""Quản trị"" --> ""Mua hàng""';
					|ru = 'Текущая настройка не позволяет формировать заявки на закупку.
					|Для создания заявок необходимо настроить их использование в разделе ""Администрирование"" --> ""Закупки""';
					|en = 'The current setting does not allow you to generate purchase requests.
					|To create requests, enable them in ""Administration"" --> ""Purchasing""'; fa = 'The current setting does not allow you to generate purchase requests.
					|To create requests, enable them in ""Administration"" --> ""Purchasing""';
					|it = 'The current setting does not allow you to generate purchase requests.
					|To create requests, enable them in ""Administration"" --> ""Purchasing""';
					|pl = 'The current setting does not allow you to generate purchase requests.
					|To create requests, enable them in ""Administration"" --> ""Purchasing""';
					|tr = 'Mevcut ayarlar satın alma taleplerinin oluşturulmasına izin vermiyor. 
					|Talep oluşturmak için ""Yönetim"" --> ""Satın Alma"" bölümünden taleplerin kullanımını yapılandırmanız gerekmektedir.'");
			Else // Restriction of rights
				 Items.NoAvailableSupplyTypes.Title =
					NStr("vi = 'Không có quyền truy cập để thêm giấy đề nghị mua hàng.';
						|ru = 'Нет прав доступа для добавления заявок на закупку.';
						|en = 'Insufficient rights to add purchase requests.'; fa = 'Insufficient rights to add purchase requests.';
						|it = 'Insufficient rights to add purchase requests.';
						|pl = 'Insufficient rights to add purchase requests.';
						|tr = 'Satın alma talebi eklemek için erişim yetkisi yok.'");
			EndIf;
				
		Else
			Items.NoAvailableSupplyTypes.Title =
				NStr("vi = 'Cài đặt hiện tại không cho phép tạo đơn đặt hàng dự phòng.
					|Để tạo đơn đặt hàng, cần thiết lập việc sử dụng đơn đặt hàng trong phần ""Quản trị""';
					|ru = 'Текущая настройка не позволяет формировать обеспечивающие заказы.
					|Для создания заказов необходимо настроить использование заказов в разделе ""Администрирование""';
					|en = 'The current settings do not allow you to generate orders.
					|To generate orders, set up order use in the Settings section'; fa = 'The current settings do not allow you to generate orders.
					|To generate orders, set up order use in the Settings section';
					|it = 'L''impostazione corrente non consente di creare ordini di approvvigionamento.
					|Per creare ordini, è necessario configurare l''utilizzo degli ordini nella sezione ""Amministrazione""';
					|pl = 'Obecne ustawienie nie pozwala na tworzenie bezpiecznych zamówień.
					| Aby tworzyć zamówienia, musisz skonfigurować korzystanie z zamówień w sekcji ""Administracja""';
					|tr = 'Mevcut ayar, tedarik siparişlerinin oluşturulmasına izin vermiyor.
					|Sipariş oluşturmak için, ""Yönetim"" bölümünde siparişlerin kullanımının yapılandırılması gerekir.'");
		EndIf;
		
		Items.NoAvailableSupplyTypes.Visible = True;
		Items.Assistant.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function AvailableCollateralSourceTypes(AvailableTypesOfCollateral)
	
	If Not ValueIsFilled(AvailableTypesOfCollateral) Then
		Return Metadata.Catalogs.ProcurementStrategies.Attributes.SourceOfDemandSupply.Type;
	EndIf;
	
	Types = New Array;
	For Each SupplyType In AvailableTypesOfCollateral Do
		If SupplyType = Enums.SupplyTypes.Purchase
			Or SupplyType = Enums.SupplyTypes.ProductionByThirdParty Then
			Types.Add(Type("CatalogRef.Partners"));
		ElsIf SupplyType = Enums.SupplyTypes.Move Then
			Types.Add(Type("CatalogRef.Warehouses"));
		ElsIf SupplyType = Enums.SupplyTypes.Production Then
			Types.Add(Type("CatalogRef.BusinessStructure"));
		EndIf;
	EndDo;
	
	Return New TypeDescription(Types);
	
EndFunction

&AtClient
Procedure FillOutSimpleSelection(FormAttribute, FieldName, DefaultValue, FilterElement, UserSettingItem)
	
	LayoutField = New DataCompositionField(FieldName);
	If LayoutField = FilterElement.LeftValue Then
		
		FormAttribute = ?(UserSettingItem.Use,
			UserSettingItem.RightValue, DefaultValue);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ReflectSimpleSelectionInLayoutSelections(SettingsComposer, FieldName, Value, ThisIsGroupSelection)
	
	// The selection is predefined in the SKD settings.
	SearchValue = New DataCompositionField(FieldName);
	ElementFound_ = False;
	For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
		
		If FilterElement.LeftValue = SearchValue Then
			
			UserSettingItem = SettingsComposer.UserSettings.Items.Find(
													FilterElement.UserSettingID);
					
			If Not UserSettingItem = Undefined Then
				
				UserSettingItem.Use = (Value <> Undefined) And ValueIsFilled(Value);
				If UserSettingItem.Use Then
					
					If ThisIsGroupSelection Then
						VariantOfComparisonType = DataCompositionComparisonType.InHierarchy;
					Else
						VariantOfComparisonType = DataCompositionComparisonType.Equal;
					EndIf;
					
					UserSettingItem.ComparisonType   = VariantOfComparisonType;
					UserSettingItem.RightValue = Value;
					
				EndIf;
				
				ElementFound_ = True;
				Break;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// Selection by subordinate fields (search in user-added selection elements).
	If Not ElementFound_ Then
		
		SelectionID_ = SettingsComposer.Settings.Filter.UserSettingID;
		Filter = SettingsComposer.UserSettings.Items.Find(SelectionID_);
		FilterElement = Undefined;
		For Each ExistingSelectionElement In Filter.Items Do
			
			If String(ExistingSelectionElement.LeftValue) = FieldName Then
				FilterElement = ExistingSelectionElement;
				Break;
			EndIf;
		EndDo;
		If FilterElement = Undefined Then
			FilterElement = Filter.Items.Add(Type("DataCompositionFilterItem"));
		EndIf;
		
		FilterElement.Use  = ValueIsFilled(Value);
		FilterElement.LeftValue  = New DataCompositionField(FieldName);
		FilterElement.RightValue = Value;
		
		FilterElement.ComparisonType   = ?(ThisIsGroupSelection, DataCompositionComparisonType.InHierarchy, DataCompositionComparisonType.Equal);
		
	EndIf;
	
EndProcedure

&AtClient
Function ReflectLayoutSelectionInSimpleSelections()
	
	// Selection by subordinate fields (search in user-added selection elements).
	// In simple selections, it is possible to reflect only selections in the fields "Product category" and "Brand", subordinate to the Nomenclature.
	SelectionID_ = FilterSettingsComposer.Settings.Filter.UserSettingID;
	Filter = FilterSettingsComposer.UserSettings.Items.Find(SelectionID_);
	For Each FilterElement In Filter.Items Do
		
		If FilterElement.Use Then
			
			If TypeOf(FilterElement) <> Type("DataCompositionFilterItem") Then
				Return False;
			EndIf;
			
			GroupSelectionIsAvailable = Not TypeOf(FilterElement.RightValue) = Type("CatalogRef.Partners")
				And Not TypeOf(FilterElement.RightValue) = Type("CatalogRef.BusinessStructure");
				
			StringLeftValue = String(FilterElement.LeftValue);
			ReflectionIsAcceptable = (StringLeftValue = "Products.ProductCategory"
					Or StringLeftValue = "Products.Brand")
				And (FilterElement.ComparisonType = DataCompositionComparisonType.Equal
					Or FilterElement.ComparisonType = DataCompositionComparisonType.InHierarchy And GroupSelectionIsAvailable)
				And ValueIsFilled(FilterElement.RightValue)
				And TypeOf(FilterElement.RightValue) <> Type("DataCompositionField")
				And StringLeftValue <> "Characteristic"
				And StringLeftValue <> "SupplyMethod";
			
			If Not ReflectionIsAcceptable Then
				Return False;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each FilterElement In FilterSettingsComposer.UserSettings.Items Do
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") And FilterElement.Use Then
			
			GroupSelectionIsAvailable = Not TypeOf(FilterElement.RightValue) = Type("CatalogRef.Partners")
				And Not TypeOf(FilterElement.RightValue) = Type("CatalogRef.BusinessStructure");
				
			ReflectionIsAcceptable = (FilterElement.ComparisonType = DataCompositionComparisonType.Equal
					Or FilterElement.ComparisonType = DataCompositionComparisonType.InHierarchy And GroupSelectionIsAvailable)
				And ValueIsFilled(FilterElement.RightValue)
				And TypeOf(FilterElement.RightValue) <> Type("DataCompositionField")
				And TypeOf(FilterElement.RightValue) <> Type("CatalogRef.ItemsCharacteristics")
				And TypeOf(FilterElement.RightValue) <> Type("CatalogRef.ProcurementStrategies")
				And OrderTypes.FindByValue(TypeOf(FilterElement.RightValue)) = Undefined;
				
			If Not ReflectionIsAcceptable Then
				Return False;
			EndIf;
			
		EndIf;
		
	EndDo;

	// Filling in simple selections by subordinate fields.
	SelectionByProductCategory = PredefinedValue("Catalog.ProductCategories.EmptyRef");
	FilterByBrand             = PredefinedValue("Catalog.Brands.EmptyRef");
	
	For Each FilterElement In Filter.Items Do
		
		If Not FilterElement.Use Then
			Continue;
		EndIf;
		
		StringLeftValue = String(FilterElement.LeftValue);
		
		If StringLeftValue = "Products.ProductCategory" Then
			SelectionByProductCategory = FilterElement.RightValue;
		ElsIf StringLeftValue = "Products.Brand" Then
			FilterByBrand = FilterElement.RightValue;
		EndIf;
		
	EndDo;
	
	// Filling in simple selections from predefined SKD selections.
	For Each FilterElement In FilterSettingsComposer.Settings.Filter.Items Do
		
		UserSettingItem = FilterSettingsComposer.UserSettings.Items.Find(FilterElement.UserSettingID);
		If Not UserSettingItem = Undefined Then
			
			FillOutSimpleSelection(FilterByWarehouse,
				"Warehouse", PredefinedValue("Catalog.Warehouses.EmptyRef"), 
				FilterElement, UserSettingItem);
				
			FillOutSimpleSelection(FilterByReceivingDepartment,
				"ReceivingBusinessUnit", PredefinedValue("Catalog.BusinessStructure.EmptyRef"), 
				FilterElement, UserSettingItem);
				
			FillOutSimpleSelection(FilterRemainingGoodsByShelfLives,
				"Products", PredefinedValue("Catalog.Products.EmptyRef"),
				FilterElement, UserSettingItem);
				
			FillOutSimpleSelection(FilterBySupplyType,
				"SupplyType", PredefinedValue("Enum.SupplyTypes.EmptyRef"),
				FilterElement, UserSettingItem);
				
			FillOutSimpleSelection(FilterBySegment,
				"ProductSegment", PredefinedValue("Catalog.ProductSegments.EmptyRef"),
				FilterElement, UserSettingItem);
				
			FillOutSimpleSelection(FilterBySupplySource,
				"SupplySource", TextNotFilledIn,
				FilterElement, UserSettingItem);
				
			FillOutSimpleSelection(FilterByBusinessUnit,
				"Department", PredefinedValue("Catalog.BusinessStructure.EmptyRef"),
				FilterElement, UserSettingItem);
			
			FillOutSimpleSelection(FilterByManager,
				"Manager", PredefinedValue("Catalog.Users.EmptyRef"),
				FilterElement, UserSettingItem);
				
			FillOutSimpleSelection(FilterByAssignment,
				"Purpose", PredefinedValue("Catalog.Assignments.EmptyRef"),
				FilterElement, UserSettingItem);
				
			FillOutSimpleSelection(FilterByLineOfBusiness,
				"LineOfBusiness", PredefinedValue("Catalog.LinesOfBusiness.EmptyRef"),
				FilterElement, UserSettingItem);
				
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

&AtServerNoContext
Function ThisIsGroupSelectionOnServer(FilterValue)
	
	If Not ValueIsFilled(FilterValue) Then
		Return False;
	EndIf;
	
	MetadataObject_ = Metadata.FindByType(TypeOf(FilterValue));
	
	If Not MetadataObject_.Hierarchical
		Or MetadataObject_.HierarchyType <> Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
		Return False;
	EndIf;
	
	Query = New Query();
	Query.Text = 
		"SELECT ALLOWED
		|	CatalogTable.IsFolder AS IsFolder
		|FROM
		|	&CatalogTable AS CatalogTable
		|WHERE
		|	CatalogTable.Ref = &Ref";
	Query.Text = StrReplace(Query.Text, "&CatalogTable",
		"Catalog." + MetadataObject_.Name);
	Query.SetParameter("Ref", FilterValue);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		Return Selection.IsFolder;
		
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Function ThisIsGroupSelection(Var_Key)
	
	If ValuesInCache = Undefined Then 
		
		ValuesInCache = New Structure("FilterByGroup");
		ValuesInCache.FilterByGroup = New Map();
		
	EndIf;
	
	GroupSelectionFlag = ValuesInCache.FilterByGroup.Get(Var_Key);
	If GroupSelectionFlag = Undefined Then
		
		GroupSelectionFlag = ThisIsGroupSelectionOnServer(Var_Key);
		ValuesInCache.FilterByGroup.Insert(Var_Key, GroupSelectionFlag);
		
	EndIf;
	
	Return GroupSelectionFlag;
	
EndFunction

#EndRegion

#Region NeedTableFilters

&AtClientAtServerNoContext
Function AnyText()
	Return NStr("vi = '<bất kỳ>';
				|ru = '<любой>';
				|en = '<any>'; fa = '<هر>';
				|it = '<qualsiasi>';
				|pl = '<any>';
				|tr = '<herhangi>'");
EndFunction

&AtClientAtServerNoContext
Function StockLevelCode(Level)
	
	Code = 0;
	While Code < 7 Do
		
		If Level = StockLevelByCode(Code) Then
			Return Code;
		EndIf;
		
		Code = Code + 1;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtClientAtServerNoContext
Function StockLevelByCode(Code)
	
	Return
		?(Code = 0, AnyText(),
		?(Code = 1, NStr("vi = 'Tới hạn';
						|ru = 'Критический';
						|en = 'Critical'; fa = 'بحرانی';
						|it = 'Critico';
						|pl = 'Critical';
						|tr = 'Kritik'"),
		?(Code = 2, NStr("vi = 'Gần tới giới hạn';
						|ru = 'Близкий к критическому';
						|en = 'Close to critical'; fa = 'Close to critical';
						|it = 'Prossimo a critico';
						|pl = 'Blisko krytyczny';
						|tr = 'Kritik yakın'"),
		?(Code = 3, NStr("vi = 'Cần hủy bỏ đơn hàng';
						|ru = 'К отмене заказа';
						|en = 'For order cancellation'; fa = 'برای لغو سفارش';
						|it = 'Per la cancellazione dell''ordine';
						|pl = 'Do anulowania zamówienia';
						|tr = 'Sipariş iptali için'"),
		?(Code = 4, NStr("vi = 'Nhỏ hơn một nửa';
						|ru = 'Меньше половины';
						|en = 'Less than half'; fa = 'کمتر از نصف';
						|it = 'Meno della metà';
						|pl = 'Mniej niż połowa';
						|tr = 'Yarısından az'"),
		?(Code = 5, NStr("vi = 'Lớn hơn 1 nửa';
						|ru = 'Больше половины';
						|en = 'Over half'; fa = 'بیش از نصف';
						|it = 'Più della metà';
						|pl = 'Więcej niż połowa';
						|tr = 'Yarısından fazla'"),
		?(Code = 6, NStr("vi = 'Dư thừa';
						|ru = 'Избыток';
						|en = 'Surplus'; fa = 'مازاد';
						|it = 'Eccesso';
						|pl = 'Nadmiar';
						|tr = 'Fazlalık'"), Undefined)))))));
	
EndFunction

&AtServer
Procedure SelectingStocksOnServer()

	FilterStructure1 = New Structure();

	If FilterMarkInventory Then
		FilterStructure1.Insert("Mark", True);
	EndIf;

	If InventoryLevelFilter <> AnyText() Then

		If StockLevelCode(InventoryLevelFilter) = 3 Then // to cancel the order
			FilterStructure1.Insert("ForOrderCancellationImage", True);
		ElsIf StockLevelCode(InventoryLevelFilter) = 1
			Or StockLevelCode(InventoryLevelFilter) = 2
			Or StockLevelCode(InventoryLevelFilter) = 4 Then
			FilterStructure1.Insert("InventoryLevel", StockLevelCode(InventoryLevelFilter));
		ElsIf StockLevelCode(InventoryLevelFilter) = 5 Or StockLevelCode(InventoryLevelFilter) = 6 Then
			FilterStructure1.Insert("MaximumInventoryLevel", StockLevelCode(InventoryLevelFilter));
		EndIf;

	EndIf;

	If ValueIsFilled(FilterToOrderNoLaterThanInventory) Then

		FilterStructure1.Insert("SatisfiesTheFilter", True);
		UpdateFilterToOrderNoLaterThanInventory();

	EndIf;

	If ValueIsFilled(FilterStructure1) Then
		Items.Inventories.RowFilter = New FixedStructure(FilterStructure1);
	Else
		Items.Inventories.RowFilter = Undefined;
	EndIf;

EndProcedure

&AtServer
Procedure SelectingOrdersOnServer()

	FilterStructure1 = New Structure();

	If FilterMarkOrders Then
		FilterStructure1.Insert("Mark", True);
	EndIf;

	If FilterUnsecured Then
		FilterStructure1.Insert("SatisfiesTheFilter", True);
	EndIf;

	If ValueIsFilled(PriorityFilter) Then
		FilterStructure1.Insert("Priority", PriorityFilter);
	EndIf;

	If ValueIsFilled(FilterToShipNotEarlier) Then
		FilterStructure1.Insert("SatisfiesTheFilter", True);
	EndIf;

	If ValueIsFilled(FilterForShipmentNoLaterThan) Then
		FilterStructure1.Insert("SatisfiesTheFilter", True);
	EndIf;

	If ValueIsFilled(FilterToOrderNoLaterThanOrders) Then
		FilterStructure1.Insert("SatisfiesTheFilter", True);
	EndIf;
	
	If FilterStructure1.Property("SatisfiesTheFilter") Then
		UpdateFilterForOrderToBeShipped();
	EndIf;

	If ValueIsFilled(FilterStructure1) Then
		Items.OrdersPendingSupply.RowFilter = New FixedStructure(FilterStructure1);
	Else
		Items.OrdersPendingSupply.RowFilter = Undefined;
	EndIf;

EndProcedure

&AtServer
Procedure UpdateFilterToOrderNoLaterThanInventory()
	
	UpToOrderPointDays = (FilterToOrderNoLaterThanInventory - BegOfDay(CurrentSessionDate())) / 86400; //86400 - duration of the day
	For Each String In Object.Inventories Do
		
		OrderPointWillOccur = ?(String.StrategyOfProcurement = Enums.InventoryReplenishmentMethods.StockReplenishmentMinMax,
			String.OrderPointPicture,
			String.AverageDailyConsumption > 0 And String.BeforeTheOrderPoint / String.AverageDailyConsumption <= UpToOrderPointDays);
			
		ThereIsQuantityToOrder = String.Balance + String.OrdersPendingGoodsReceipt - String.MinimumInventory < String.MaximumInventory;
		String.SatisfiesTheFilter = OrderPointWillOccur And ThereIsQuantityToOrder;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateFilterForOrderToBeShipped()

	For Each String In Object.OrdersPendingSupply Do

		String.SatisfiesTheFilter =
			String.DateOfShipment >= FilterToShipNotEarlier
				And (String.DateOfShipment <= FilterForShipmentNoLaterThan Or Not ValueIsFilled(FilterForShipmentNoLaterThan))
				And (String.Required2 > String.Supplied Or Not FilterUnsecured)
				And (String.OrderDateNoLaterThan <= FilterToOrderNoLaterThanOrders
					Or Not ValueIsFilled(FilterToOrderNoLaterThanOrders))

	EndDo;

EndProcedure

&AtServer
Procedure ClearSelections_()

	FilterToOrderNoLaterThanInventory = '00010101'; //clearing the date
	InventoryLevelFilter = AnyText();
	FilterMarkInventory = False;
	SelectingStocksOnServer();

EndProcedure

&AtServer
Procedure ClearSelectionsOrders()
	
	FilterToOrderNoLaterThanOrders = '00010101'; //clearing the date
	FilterToShipNotEarlier = '00010101'; //clearing the date
	FilterForShipmentNoLaterThan = '00010101'; //clearing the date
	FilterMarkOrders = False;
	PriorityFilter = Catalogs.Priorities.EmptyRef();
	SelectingOrdersOnServer();

EndProcedure

&AtServer
Procedure FillStockLevelFilterSelectionList()

	ChoiceList = Items.InventoryLevelFilter.ChoiceList;
	ChoiceList.Clear();

	For Counter = 0 To 6 Do

		ChoiceList.Add(StockLevelByCode(Counter));

	EndDo;

EndProcedure

#EndRegion

#Region ChecksAbilityToPerformActions

&AtClient
Function MethodTableIsFilledInCorrectly()
	
	NoErrors_ = True;
	ThereAreMarked = False;
	BeginningOfThisDay = BegOfDay(CommonClient.SessionDate());
	For Each TableRow In Object.SupplyMethods Do
		If Not TableRow.Mark Then
			Continue;
		Else
			
			If TableRow.ShipmentDate < BeginningOfThisDay
					And ValueIsFilled(TableRow.ShipmentDate) Then
				
				ErrorText = NStr("vi = 'Trong dòng %1 trong trường ""Ngày giao hàng"" đã thiết lập ngày vừa qua.';
								|ru = 'В строке %1 в поле ""Дата поставки"" установлена прошедшая дата.';
								|en = 'In line %1, the ""Delivery date"" field contains the past date.'; fa = 'In line %1, the ""Delivery date"" field contains the past date.';
								|it = 'В строке %1 в поле ""Дата поставки"" установлена прошедшая дата.';
								|pl = 'In line %1, the ""Delivery date"" field contains the past date.';
								|tr = 'В строке %1 в поле ""Дата поставки"" установлена прошедшая дата.'");
				ErrorText = StrTemplate(ErrorText, TableRow.LineNumber);
				CommonClient.MessageToUser(
					ErrorText,
					,
					,
					StrTemplate("SupplyMethods[%1].ShipmentDate", TableRow.LineNumber - 1),
					"Object");
				
				NoErrors_ = False;
				
			EndIf;
			
			If TableRow.BoundaryOfCoveredPeriod < BeginningOfThisDay
					And ValueIsFilled(TableRow.BoundaryOfCoveredPeriod) Then
				
				ErrorText = NStr("vi = 'Trong dòng %1 trong trường ""Đảm bảo nhu cầu đến ngày"" đã thiết lập ngày vừa qua.';
								|ru = 'В строке %1 в поле ""Обеспечить потребности до даты"" установлена прошедшая дата.';
								|en = 'In line %1, the ""Cover demand up to date"" field contains the past date.'; fa = 'In line %1, the ""Cover demand up to date"" field contains the past date.';
								|it = 'В строке %1 в поле ""Обеспечить потребности до даты"" установлена прошедшая дата.';
								|pl = 'In line %1, the ""Cover demand up to date"" field contains the past date.';
								|tr = 'Satır  %1''de, ""Talebi şu tarihe kadar karşıla"" alanı geçmiş tarihi içerir.'");
				ErrorText = StrTemplate(ErrorText, TableRow.LineNumber);
				CommonClient.MessageToUser(
					ErrorText,
					,
					,
					StrTemplate("SupplyMethods[%1].BoundaryOfCoveredPeriod", TableRow.LineNumber - 1),
					"Object");
				
				NoErrors_ = False;
				
			EndIf;
			
			If ValueIsFilled(TableRow.BoundaryOfCoveredPeriod)
					And TableRow.BoundaryOfCoveredPeriod <= TableRow.ShipmentDate Then
					
					ErrorText = NStr("vi = 'Trong dòng %1 trong trường ""Đảm bảo nhu cầu đến ngày"" đã thiết lập nhỏ hơn hoặc bằng ngày giao hàng.';
									|ru = 'В строке %1 в поле ""Обеспечить потребности до даты"" установлена дата меньше или равная дате поставки.';
									|en = 'In line %1, the ""Cover demand up to date"" field contains the date earlier than or equal to the delivery date.'; fa = 'In line %1, the ""Cover demand up to date"" field contains the date earlier than or equal to the delivery date.';
									|it = 'В строке %1 в поле ""Обеспечить потребности до даты"" установлена дата меньше или равная дате поставки.';
									|pl = 'In line %1, the ""Cover demand up to date"" field contains the date earlier than or equal to the delivery date.';
									|tr = 'Satır  %1''de, ""Talebi şu tarihe kadar karşıla"" alanı teslimat tarihini veya daha önceki  bir tarihi içerir.'");
					ErrorText = StrTemplate(ErrorText, TableRow.LineNumber);
					CommonClient.MessageToUser(
						ErrorText,
						,
						,
						StrTemplate("SupplyMethods[%1]." + "BoundaryOfCoveredPeriod",
						TableRow.LineNumber - 1),
						"Object");
						
					NoErrors_ = False;
					
			EndIf;
			ThereAreMarked = True;
			
		EndIf;
	EndDo;
	
	If Not ThereAreMarked Then

		ErrorText = NStr("vi = 'Để chuyển sang bước tiếp theo, cần đánh dấu ít nhất một phương pháp đảm bảo từ danh sách';
						|ru = 'Для перехода к следующему шагу необходимо отметить хотя бы один способ обеспечения из списка';
						|en = 'To go to the next step, select at least one procurement strategy from the list'; fa = 'To go to the next step, select at least one procurement strategy from the list';
						|it = 'Per procedere al passaggio successivo, è necessario contrassegnare almeno una modalità di approvvigionamento dall''elenco';
						|pl = 'Aby przejść do następnego kroku, należy odnotować co najmniej jedną metodę podawania z listy';
						|tr = 'Bir sonraki adıma geçmek için listeden en az bir tedarik stratejisi seçilmeli.'");
		ShowMessageBox(, ErrorText);

		NoErrors_ = False;

	EndIf;
	
	Return NoErrors_;
	
EndFunction

&AtClient
Procedure ReportNoNeeds()
	
	WarningText = NStr("vi = 'Đối với hàng hóa chưa đặt tham số duy trì vật tư
			|và không có đơn hàng của khách, đơn hàng điều chuyển... cần đảm bảo.
			|Hãy đặt tham số đảm bảo nhu cầu, hoặc thay đổi điều kiện lọc nhu cầu.
			|Chú ý: chưa tính đến đơn hàng đã giao %1đầy đủ.';
			|ru = 'Для товаров не установлены параметры поддержания запаса
			|и нет заказов клиентов, заказов на перемещение и т.п. к обеспечению.
			|Установите параметры обеспечения потребностей, либо измените условия отбора потребностей.
			|Важно: полностью отгруженные заказы %1не учитываются.';
			|en = 'Inventory replenishment settings are not configured for the goods,
			|and there are no sales orders, transfer orders, etc.
			|Set the parameters to meet the demand or change the conditions of demand filtering.
			|Important: fully shipped orders %1 are not considered.'; fa = 'Inventory replenishment settings are not configured for the goods,
			|and there are no sales orders, transfer orders, etc.
			|Set the parameters to meet the demand or change the conditions of demand filtering.
			|Important: fully shipped orders %1 are not considered.';
			|it = 'Per le merci non sono impostati i parametri di mantenimento scorte
			|e non sono presenti gli ordini dei clienti, ordini per la movimentazione ecc. per approvvigionamento.
			|Impostare i parametri di approvvigionamento dei fabbisogni o modificare le condizioni della selezione dei fabbisogni.
			|È importante: gli ordini completamente spediti %1 non vengono presi in considerazione.';
			|pl = 'Dla towarów nie są ustawione parametry utrzymania zapasów
			|i brak zamówień klientów, zamówień na przenoszenie itp. do zabezpieczenia.
			|Zaznacz opcje zabezpieczenia potrzeb, albo zmień kryteria selekcji potrzeb.
			|Ważne: w pełni wysłane zamówienia %1 nie są brane pod uwagę.';
			|tr = 'Ürünler için stok yenileme parametreleri ayarlanmadı
			|ve tedarik edilecek satış, transfer siparişleri vb. mevcut değil.
			|Talebi karşılama parametrelerini ayarla veya gereksinim seçim koşullarını değiştir.
			|Önemli: Tam sevk edilen siparişler %1dikkate alınmaz.'");

	StatusesAreUsed = StatusesAreUsed();
	WarningText = StrReplace(WarningText, "%1", ?(StatusesAreUsed,
		NStr("vi = 'và đơn hàng theo trạng thái thấp hơn mức ""Cần đảm bảo""';
			|ru = 'и заказы в статусе ниже чем ""К обеспечению""';
			|en = 'and orders with status lower than ""To supply""'; fa = 'and orders with status lower than ""To supply""';
			|it = 'e gli ordini nello stato inferiore di ""Per approvvigionamento""';
			|pl = 'i zamówienia w statusie niższym niż ""Do zapewnienia""';
			|tr = 've ""Tedarik edilecek""ten daha düşük durumdaki siparişler'") + " ", ""));

	ShowMessageBox(Undefined, WarningText);
	
EndProcedure

&AtServerNoContext
Function StatusesAreUsed()

	StatusesAreUsed = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder")
		Or GetFunctionalOption("UseStatusesOfInventoryConsumptionOrders")
		Or GetFunctionalOption("UseStatusesOfTransferOrders")
		Or GetFunctionalOption("UseStatusesOfAssemblyOrders");

		
	StatusesAreUsed =
		StatusesAreUsed
		Or GetFunctionalOption("UseTollingOrderStatuses2_5");
	StatusesAreUsed =
		StatusesAreUsed
		Or GetFunctionalOption("UseStatusesOfMaterialProviderOrders2_5");
	Return StatusesAreUsed;

EndFunction

&AtClient
Procedure ClearingNeedsTableIssueAlert(QuestionResult, AdditionalParameters) Export

	Result = True;
	If QuestionResult = DialogReturnCode.Cancel Then
		Result = False;
	EndIf;

	If Result Then

		If AdditionalParameters.Operation = "Close" Then

			ClearTheDemandTableResponseReceived = True;
			Close();

		ElsIf AdditionalParameters.Operation = "StepBack" Then

			// in order not to transfer unnecessary data to the server.
			Object.Inventories.Clear();
			Object.OrdersPendingSupply.Clear();

			ClearIndexTree(True);
			
			ClearMessages();
			InstallAssistantPages("StepCustomizeSupplyMethods");

		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure ClearingNeedsTableIsIssue(Operation)

	Buttons = New ValueList();
	Text = NStr("vi = 'Xóa danh sách nhu cầu';
				|ru = 'Очистить список потребностей';
				|en = 'Clear demand list'; fa = 'Clear demand list';
				|it = 'Cancellare l''elenco dei fabbisogni';
				|pl = 'Wyczyść listę potrzeb';
				|tr = 'Gereksinimler listesini temizle'");
	Buttons.Add(DialogReturnCode.Yes, Text);
	Buttons.Add(DialogReturnCode.Cancel);
	If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
		QueryText = NStr("vi = 'Trong danh sách nhu cầu có các mục được đánh dấu, mà chưa lập giấy đề nghị. Danh sách nhu cầu sẽ bị xóa.';
						|ru = 'В списке потребностей имеются отмеченные позиции, заявки по которым не сформированы. Список потребностей будет очищен.';
						|en = 'In the list of demands, there are selected items for which requests were not generated. The demand list will be cleared.'; fa = 'In the list of demands, there are selected items for which requests were not generated. The demand list will be cleared.';
						|it = 'In the list of demands, there are selected items for which requests were not generated. The demand list will be cleared.';
						|pl = 'In the list of demands, there are selected items for which requests were not generated. The demand list will be cleared.';
						|tr = 'Gereksinimler listesinde, talepleri oluşturulmamış işaretlenmiş pozisyonlar mevcut. Gereksinim listesi temizlenecek.'");
	Else
		QueryText = NStr("vi = 'Trong danh sách nhu cầu có các mục được đánh dấu, mà chưa lập đơn hàng. Danh sách nhu cầu sẽ bị xóa.';
						|ru = 'В списке потребностей имеются отмеченные позиции, заказы по которым не сформированы. Список потребностей будет очищен.';
						|en = 'In the list of demands, there are selected items for which orders were not generated. The demand list will be cleared.'; fa = 'In the list of demands, there are selected items for which orders were not generated. The demand list will be cleared.';
						|it = 'Nell''elenco dei fabbisogni sono contrassegnate le voci, ordini per le quali non sono stati generati. L''elenco dei fabbisogni sarà cancellato.';
						|pl = 'Na liście potrzeb znajdują się oznaczone pozycje, których zamówienia nie są tworzone. Lista potrzeb zostanie wyczyszczona.';
						|tr = 'Gereksinimler listesinde, siparişleri oluşturulmamış işaretlenmiş pozisyonlar mevcut. Gereksinim listesi temizlenecek.'");
	EndIf;

	AdditionalParameters = New Structure("Operation", Operation);
	CallbackDescription = New CallbackDescription("ClearingNeedsTableIssueAlert",
		ThisForm, AdditionalParameters);
	ShowQueryBox(CallbackDescription, QueryText, Buttons);

EndProcedure

&AtClient
Procedure GetConfirmationOfClearingOrdersToProvideTable(Val Notification)
	
	If Object.OrdersPendingSupply.Count() = 0 Then
		RunCallback(Notification, True);
		Return;
	EndIf;
	
	Mode = New ValueList();
	Text = NStr("vi = 'Xóa danh sách nhu cầu';
				|ru = 'Очистить список потребностей';
				|en = 'Clear demand list'; fa = 'Clear demand list';
				|it = 'Cancellare l''elenco dei fabbisogni';
				|pl = 'Wyczyść listę potrzeb';
				|tr = 'Gereksinimler listesini temizle'");
	Mode.Add(DialogReturnCode.Yes, Text);
	Mode.Add(DialogReturnCode.Cancel);
	If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
		QueryText = NStr("vi = 'Trong danh sách nhu cầu có các mục được đánh dấu, mà chưa lập giấy đề nghị. Danh sách nhu cầu sẽ bị xóa.';
						|ru = 'В списке потребностей имеются отмеченные позиции, заявки по которым не сформированы. Список потребностей будет очищен.';
						|en = 'In the list of demands, there are selected items for which requests were not generated. The demand list will be cleared.'; fa = 'In the list of demands, there are selected items for which requests were not generated. The demand list will be cleared.';
						|it = 'In the list of demands, there are selected items for which requests were not generated. The demand list will be cleared.';
						|pl = 'In the list of demands, there are selected items for which requests were not generated. The demand list will be cleared.';
						|tr = 'Gereksinimler listesinde, talepleri oluşturulmamış işaretlenmiş pozisyonlar mevcut. Gereksinim listesi temizlenecek.'");
	Else
		QueryText = NStr("vi = 'Trong danh sách nhu cầu có các mục được đánh dấu, mà chưa lập đơn hàng. Danh sách nhu cầu sẽ bị xóa.';
						|ru = 'В списке потребностей имеются отмеченные позиции, заказы по которым не сформированы. Список потребностей будет очищен.';
						|en = 'In the list of demands, there are selected items for which orders were not generated. The demand list will be cleared.'; fa = 'In the list of demands, there are selected items for which orders were not generated. The demand list will be cleared.';
						|it = 'Nell''elenco dei fabbisogni sono contrassegnate le voci, ordini per le quali non sono stati generati. L''elenco dei fabbisogni sarà cancellato.';
						|pl = 'Na liście potrzeb znajdują się oznaczone pozycje, których zamówienia nie są tworzone. Lista potrzeb zostanie wyczyszczona.';
						|tr = 'Gereksinimler listesinde, siparişleri oluşturulmamış işaretlenmiş pozisyonlar mevcut. Gereksinim listesi temizlenecek.'");
	EndIf;
	
	ShowQueryBox(New CallbackDescription("GetConfirmationOfClearingOrdersToProvideTableCompletion", ThisObject, New Structure("Notification", Notification)), QueryText, Mode, 0);
	
EndProcedure

&AtClient
Procedure GetConfirmationOfClearingOrdersToProvideTableCompletion(QuestionResult, AdditionalParameters) Export
	
	RunCallback(AdditionalParameters.Notification, QuestionResult = DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure CheckCorrectnessOfFillingFilterForShipmentNoEarlier(Date, StandardProcessing)
	
	If Date > FilterForShipmentNoLaterThan And ValueIsFilled(FilterForShipmentNoLaterThan) Then
		
		StandardProcessing = False;
		ShowMessageBox(, NStr("vi = 'Ngày đầu kỳ không thể lớn hơn ngày kết thúc';
								|ru = 'Дата начала периода не может быть больше даты окончания';
								|en = 'Period start date cannot exceed period end date'; fa = 'Period start date cannot exceed period end date';
								|it = 'La data di inizio periodo non può essere superiore alla data del termine';
								|pl = 'Data rozpoczęcia okresu nie może być dłuższa niż data zakończenia';
								|tr = 'Dönemin başlangıç ​​tarihi, bitiş tarihinden büyük olamaz'"), , );
		
	EndIf;
	
EndProcedure

#EndRegion

#Region OtherProceduresAndFunctions_

&AtClientAtServerNoContext
Function OnChangesCalculationOfIsolatedNeedsTakingIntoAccountBalancesInAllWarehouses(CalculationTakingIntoAccountBalancesInAllWarehouses)
	
	If CalculationTakingIntoAccountBalancesInAllWarehouses = 0 Then // Only in the shipment warehouse
		Text = NStr("vi = 'Đối với trung tâm mạng lưới phân phối, tùy chỉnh bị bỏ qua - ghi nhận số dư của tất cả kho trong mạng lưới';
					|ru = 'Для центра распределительной сети настройка игнорируется - учитываются остатки всех складов сети';
					|en = 'For the distribution network center, the setting is ignored: balances of all network warehouses are taken into account'; fa = 'For the distribution network center, the setting is ignored: balances of all network warehouses are taken into account';
					|it = 'Для центра распределительной сети настройка игнорируется - учитываются остатки всех складов сети';
					|pl = 'For the distribution network center, the setting is ignored: balances of all network warehouses are taken into account';
					|tr = 'Dağıtım ağı merkezi için ayarlar görmezden gelinir, ağdaki tüm ambarların bakiyeleri hesaba katılır'");
	Else
		Text = NStr("vi = 'Đối với kho của mạng lưới phân phối ở xa, việc tùy chỉnh bị bỏ qua - ghi nhận số dư chỉ của kho ở xa';
					|ru = 'Для удаленного склада распределительной сети настройка игнорируется - учитываются остатки только удаленного склада';
					|en = 'For a remote warehouse of the distribution network, the setting is ignored: only balances of this remote warehouse are taken into account'; fa = 'For a remote warehouse of the distribution network, the setting is ignored: only balances of this remote warehouse are taken into account';
					|it = 'Для удаленного склада распределительной сети настройка игнорируется - учитываются остатки только удаленного склада';
					|pl = 'For a remote warehouse of the distribution network, the setting is ignored: only balances of this remote warehouse are taken into account';
					|tr = 'Dağıtım ağının uzakta bulunan ambarı için bu ayarlar görmezden gelinir, sadece uzakta bulunan ambarın bakiyeleri hesaba katılır'");
	EndIf;
	
	Return Text;
	
EndFunction

&AtServer
Procedure SetAvailabilityOfCommandsByFunctionalOptions()
	
	CommandVisibility = False;
	CommandVisibility =
		GetFunctionalOption("UseTollingOrderStatuses2_5")
		Or False;
	Items.FormOrderToTheProcessorForExecution.Visible = CommandVisibility;
	
	CommandVisibility = False;
	CommandVisibility = GetFunctionalOption("UseProductionManagement")
		Or GetFunctionalOption("UseProductionManagement2_2");
	Items.FormProductionOrderForProduction.Visible = CommandVisibility;
	
	CommandVisibility = GetFunctionalOption("UsePurchaseOrderStatuses");
	Items.FormTheOrderToTheSupplierIsConfirmed.Visible = CommandVisibility;
	
EndProcedure

&AtServer
Procedure FilterUnsecuredWhenModifiedOnServer()
	
	ShouldSaveSettings();
	SelectingOrdersOnServer();
	
EndProcedure

&AtServer
Procedure ConfigureTaxiClientAppFormElements()
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Taxi Then
		Items.MarkToOrderOrders.Representation = ButtonRepresentation.Picture;
		Items.AddInventoryToTheOrder.Representation = ButtonRepresentation.Picture;
		Items.UnmarkOrders.Representation    = ButtonRepresentation.Picture;
		Items.UnmarkInventory.Representation    = ButtonRepresentation.Picture;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function CaptionInFormat(Parameter, UnitOfMeasure, FormatString)
	Return StrTemplate("%1 %2", Format(Parameter, FormatString), UnitOfMeasure);
EndFunction

&AtClientAtServerNoContext
Function StringToDate(DateAsString)
	
	Year = Right(DateAsString,4);
	Month = Mid(DateAsString,4,2);
	Day = Left(DateAsString,2);
	
	If Not ValueIsFilled(Year + Month + Day) Then
		Return Date(1,1,1);
	Else
		Return Date(Year, Month, Day);
		
	EndIf;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// The first level of grouping in the order basket is bold

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Preview.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Preview.LevelInTheTree");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));
	
	// Unavailability of agreement selection for all security methods except purchase

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PreviewTerms.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Preview.SupplyType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.SupplyTypes.Purchase;
		
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Prohibiting the selection of a warehouse for the "Work" item type
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PreviewWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Preview.ThisIsWork");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Unavailability of the security source, if it is specified in the security method

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PreviewSupplySource.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Preview.SupplySourceViewOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);

	// No access to the order
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Không có quyền truy cập để đặt hàng';
							|ru = 'Нет доступа к заказу';
							|en = 'No access to order'; fa = 'No access to order';
							|it = 'Nessun accesso all''ordine';
							|pl = 'Brak dostępu do zamówienia';
							|tr = 'Siparişe erişim mevcut değildir'");

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderDocument.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OrdersPendingSupply.OrderDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có quyền truy cập vào dữ liệu đặt hàng>';
													|ru = '<нет доступа к данным заказа>';
													|en = '<no access to the order data>'; fa = '<no access to the order data>';
													|it = '<nessun accesso ai dati dell''ordine>';
													|pl = '<brak dostępu do danych zamówienia>';
													|tr = '<sipariş verilerine erişim mevcut değildir>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// No access to the order
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = '<Chỉnh sửa thủ công>';
							|ru = '<Ручное редактирование>';
							|en = '<Manual editing>'; fa = '<Manual editing>';
							|it = '<Modifica manuale>';
							|pl = '<Ręczna edycja>';
							|tr = '<Manuel düzenleme>'");

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderDocument.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OrdersPendingSupply.OrderDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Undefined;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Chỉnh sửa thủ công>';
													|ru = '<Ручное редактирование>';
													|en = '<Manual editing>'; fa = '<Manual editing>';
													|it = '<Modifica manuale>';
													|pl = '<Ręczna edycja>';
													|tr = '<Manuel düzenleme>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Hyperlink method of providing needs
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Hyperlink phương pháp đảm bảo';
							|ru = 'Гиперссылка метод обеспечения';
							|en = 'Hyperlink inventory replenishment method'; fa = 'Hyperlink inventory replenishment method';
							|it = 'Hyperlink metodo di approvvigionamento';
							|pl = 'Metoda udostępniania hiperłącza';
							|tr = 'Köprü tedarik yöntemi'");

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StrategyOfProcurement.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Inventories.StrategyOfProcurement");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

	// The document has a high priority
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chứng từ có mức ưu tiên cao';
							|ru = 'Документ имеет высокий приоритет';
							|en = 'High priority document'; fa = 'سند با اولویت بالا';
							|it = 'Il documento ha priorità alta';
							|pl = 'Dokument ma wysoki priorytet';
							|tr = 'Belge yüksek önceliğe sahiptir'");

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrdersPendingSupply.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OrdersPendingSupply.Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Priorities.GetTopPriority();
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.HighPriorityDocument);

	// The document has a low priority
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chứng từ có mức ưu tiên thấp';
							|ru = 'Документ имеет низкий приоритет';
							|en = 'Low priority document'; fa = 'Low priority document';
							|it = 'Il documento ha priorità bassa';
							|pl = 'Dokument ma niski priorytet';
							|tr = 'Belge düşük önceliğe sahiptir'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrdersPendingSupply.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OrdersPendingSupply.Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Priorities.GetLowerPriority();
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.LowDocumentPriority);

	// The text of the "Method of provision" field for the item provided without specifying the method.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyMethodsSupplyMethod.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.SupplyMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đảm bảo mà chưa chỉ ra phương thức>';
													|ru = '<обеспечение без указания способа>';
													|en = '<supply without indication of a method>'; fa = '<supply without indication of a method>';
													|it = '<approvvigionamento senza modalità indicata>';
													|pl = '<zabezpieczanie bez określania metody>';
													|tr = '<yöntem belirtimi olmadan sipariş karşılama>'"));

	// Highlighting the error in the "Days before the planned order" field when the order date is overdue according to the plan, there is no planned
	// delivery date or the calendar is empty.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyMethodsDaysBeforeTheOrderAccordingToTheSchedule.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.DaysBeforePlannedOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.PlannedOrderDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	
	// Text in the "To order items" field.
	
	For Counter = 0 To 2 Do
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.SupplyMethodsDemandConversionOption.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.DemandConversionOption");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Counter;
		
		Text = Items.SupplyMethodsDemandConversionOption.ChoiceList[Counter].Presentation;
		Item.Appearance.SetParameterValue("Text", Text);
		
	EndDo;
	
	// Error text in the "Delivery date" field when the calendar is empty

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyMethodsShipmentDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.ShipmentDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.LineChanged");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa điền lịch biểu làm việc của doanh nghiệp>';
													|ru = '<не заполнен график работы предприятия>';
													|en = '<enterprise schedule is not filled in>'; fa = '<enterprise schedule is not filled in>';
													|it = '<l''orario di lavoro della società non è compilato>';
													|pl = '<nie wypełniony harmonogram prac w przedsiębiorstwie>';
													|tr = '<işletme çalışma takvimi doldurulmadı>'"));

	// The text <without period restrictions> in the "Security period boundary" field if the border is not filled in

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyMethodsBoundaryOfCoveredPeriod.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.BoundaryOfCoveredPeriod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có giới hạn kỳ>';
													|ru = '<без ограничений периода>';
													|en = '<without period restrictions>'; fa = '<without period restrictions>';
													|it = '<без ограничений периода>';
													|pl = '<without period restrictions>';
													|tr = '<kısıtlamalı dönemsiz>'"));

	// The text <the work schedule of the enterprise is not filled in> in the "Security period boundary" field when the calendar is not filled in
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyMethodsBoundaryOfCoveredPeriod.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.BoundaryOfCoveredPeriod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.CoveredPeriodOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.CoveredPeriodOptions.NoExpiration;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.DemandConversionOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 2;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.LineChanged");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa điền lịch biểu làm việc của doanh nghiệp>';
													|ru = '<не заполнен график работы предприятия>';
													|en = '<enterprise schedule is not filled in>'; fa = '<enterprise schedule is not filled in>';
													|it = '<l''orario di lavoro della società non è compilato>';
													|pl = '<nie wypełniony harmonogram prac w przedsiębiorstwie>';
													|tr = '<işletme çalışma takvimi doldurulmadı>'"));

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyMethodsBoundaryOfCoveredPeriod.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.BoundaryOfCoveredPeriod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.DemandConversionOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.GenerateOrdersOnSchedule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyMethods.CoveredPeriodOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.CoveredPeriodOptions.UpToTheNextDeliveryDate;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa điền lịch biểu làm việc của doanh nghiệp>';
													|ru = '<не заполнен график работы предприятия>';
													|en = '<enterprise schedule is not filled in>'; fa = '<enterprise schedule is not filled in>';
													|it = '<l''orario di lavoro della società non è compilato>';
													|pl = '<nie wypełniony harmonogram prac w przedsiębiorstwie>';
													|tr = '<işletme çalışma takvimi doldurulmadı>'"));
	
	// If there is no status of the created order, then the inscription is not carried out.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Status.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableDocuments.StandardPicture");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không kết chuyển>';
													|ru = '<не проведен>';
													|en = '<not posted>'; fa = '<not posted>';
													|it = '<non registrato>';
													|pl = '<nie zatwierdzony>';
													|tr = '<kaydedilmedi>'"));

	// Highlighting the negative stock balance in color

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Balance.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Inventories.Balance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

	// Text <assembly> in the software source

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheSourceOfTheOrders.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OrdersPendingSupply.SupplyType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SupplyTypes.AssemblyDisassembly;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đóng bộ>';
													|ru = '<сборка>';
													|en = '<kitting>'; fa = '<kitting>';
													|it = '<assemblaggio>';
													|pl = '<kitting>';
													|tr = '<montaj>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheSourceOfSupplyForReserves.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Inventories.SupplyType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SupplyTypes.AssemblyDisassembly;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đóng bộ>';
													|ru = '<сборка>';
													|en = '<kitting>'; fa = '<kitting>';
													|it = '<assemblaggio>';
													|pl = '<kitting>';
													|tr = '<montaj>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	// Unavailability of the security source, if it is specified in the security method

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheSourceOfSupplyForReserves.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Inventories.SupplySourceViewOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheSourceOfTheOrders.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OrdersPendingSupply.SupplySourceViewOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// The text "<not used>" in the Order Shipment Warehouse field

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderShipmentWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OrdersPendingSupply.ThisIsWork");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));

	// The text "<not used>" in the Status field

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Status.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableDocuments.UsingStatuses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));

	// The text "<multiple values>" in the Partner field/Warehouse/Division

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PartnerWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableDocuments.NumberOfSupplySources");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<một số giá trị>';
													|ru = '<несколько значений>';
													|en = '<multiple values>'; fa = '<multiple values>';
													|it = '<multiple values>';
													|pl = '<multiple values>';
													|tr = '<birden fazla değer>'"));

	// Overdue shipment date of the order requirement
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfShipment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OrdersPendingSupply.DateOfShipment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("Object.OrdersPendingSupply.ShipmentDate");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

	If Not UsePurchaseOrders Then
		
		// The mark of an unfilled security method.
		Item = ConditionalAppearance.Items.Add();
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.MethodOfSecuringStocks.Name);
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Inventories.SupplyMethod");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Inventories.Mark");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		Item.Appearance.SetParameterValue("MarkIncomplete", True);
		
		Item = ConditionalAppearance.Items.Add();
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.MethodOfSecuringOrders.Name);
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.OrdersPendingSupply.SupplyMethod");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.OrdersPendingSupply.Mark");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		Item.Appearance.SetParameterValue("MarkIncomplete", True);
		
		Item = ConditionalAppearance.Items.Add();
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.TheSourceOfSupplyForReserves.Name);
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Inventories.SupplyMethod");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Inventories.Mark");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
		Item = ConditionalAppearance.Items.Add();
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.TheSourceOfTheOrders.Name);
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.OrdersPendingSupply.SupplyMethod");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.OrdersPendingSupply.Mark");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure InstallHints()
	
	Hints = New Structure();
	
	If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
		
		Hints.Insert("SupplyMethodsDemandConversionOption",
			NStr("vi = 'Xác định thành phần hàng hóa,
			|được tự động đưa vào
			|giấy đề nghị được tạo của các bước làm việc tiếp theo';
			|ru = 'Определяет состав товаров,
			|автоматически включаемых в
			|формируемую заявку следующих шагах работы';
			|en = 'Determines which goods
			|will be automatically included in
			|the generated request on the next steps'; fa = 'Determines which goods
			|will be automatically included in
			|the generated request on the next steps';
			|it = 'Determines which goods
			|will be automatically included in
			|the generated request on the next steps';
			|pl = 'Determines which goods
			|will be automatically included in
			|the generated request on the next steps';
			|tr = 'Sonraki işlem adımlarında oluşturulan 
			| talebe 
			| otomatik olarak dahil edilen malları belirler.'"));
			
		Hints.Insert("SupplyMethodsShipmentDate",
			NStr("vi = 'Ngày dự tính tiếp nhận mà
			|sẽ được chỉ ra trong giấy đề nghị sẽ lập';
			|ru = 'Дата ожидаемого поступления, которая
			|будет указана в формируемой заявке';
			|en = 'Date of expected receipt which
			|will be indicated in the request generated'; fa = 'Date of expected receipt which
			|will be indicated in the request generated';
			|it = 'Date of expected receipt which
			|will be indicated in the request generated';
			|pl = 'Date of expected receipt which
			|will be indicated in the request generated';
			|tr = 'Oluşturulan talepte belirtilecek 
			| beklenen giriş tarihi'"));
			
		Hints.Insert("SupplyMethodsDaysBeforeTheOrderAccordingToTheSchedule",
			NStr("vi = 'Số ngày đến ngày lập
			|giấy đề nghị để giao gần nhất theo lịch biểu';
			|ru = 'Число дней до даты формирования
			|заявки на ближайшую поставку по графику';
			|en = 'Number of days before the date of request generation
			|for the nearest delivery on schedule'; fa = 'Number of days before the date of request generation
			|for the nearest delivery on schedule';
			|it = 'Number of days before the date of request generation
			|for the nearest delivery on schedule';
			|pl = 'Number of days before the date of request generation
			|for the nearest delivery on schedule';
			|tr = 'Çizelgeye göre en yakın
			|teslimat talebinin oluşturulma tarihine kalan gün sayısı'"));
			
		Hints.Insert("GroupToOrderInventory",
			NStr("vi = 'Số lượng sẽ chỉ ra
			|trong giấy đề nghị đặt ra
			|để duy trì vật tư';
			|ru = 'Количество, которое будет указано
			|в формируемой заявке, заказываемое
			|для поддержания запаса';
			|en = 'Number that will be indicated
			|in generated request to maintain 
			|the inventory level'; fa = 'Number that will be indicated
			|in generated request to maintain 
			|the inventory level';
			|it = 'Number that will be indicated
			|in generated request to maintain 
			|the inventory level';
			|pl = 'Number that will be indicated
			|in generated request to maintain 
			|the inventory level';
			|tr = 'Stok seviyesini korumak için sipariş edilen 
			| ve oluşturulacak talep formunda gösterilecek 
			| miktar'"));
			
		Hints.Insert("OrdersPendingGoodsReceipt",
			NStr("vi = 'Số lượng đã đặt từ trước và số lượng dự kiến
			|tiếp nhận';
			|ru = 'Количество, заказаное ранее и ожидаемое к
			|поступлению';
			|en = 'Quantity ordered earlier and anticipated for
			|arrival'; fa = 'Quantity ordered earlier and anticipated for
			|arrival';
			|it = 'Quantità ordinata in precedenza e quella prevista in
			|arrivo';
			|pl = 'Ilość, zamówiona wcześniej i oczekiwana do
			| wpływu';
			|tr = 'Önceden sipariş edilen ve alımı
			|beklenen miktar'"));
			
	Else
		
		Hints.Insert("SupplyMethodsDemandConversionOption",
			NStr("vi = 'Xác định thành phần hàng hóa,
			|được tự động đưa vào
			|đơn hàng được tạo của các bước làm việc tiếp theo';
			|ru = 'Определяет состав товаров,
			|автоматически включаемых в
			|формируемый заказ следующих шагах работы';
			|en = 'Determines which goods
			|will be automatically included in
			|the generated order on the next steps'; fa = 'Determines which goods
			|will be automatically included in
			|the generated order on the next steps';
			|it = 'Определяет состав товаров,
			|автоматически включаемых в
			|формируемый заказ следующих шагах работы';
			|pl = 'Determines which goods
			|will be automatically included in
			|the generated order on the next steps';
			|tr = 'Определяет состав товаров,
			|автоматически включаемых в
			|формируемый заказ следующих шагах работы'"));
			
		Hints.Insert("SupplyMethodsShipmentDate",
			NStr("vi = 'Ngày dự tính tiếp nhận mà
			|sẽ được chỉ ra trong đơn hàng sẽ lập';
			|ru = 'Дата ожидаемого поступления, которая
			|будет указана в формируемом заказе';
			|en = 'Date of expected receipt which
			|will be indicated in the order generated'; fa = 'Date of expected receipt which
			|will be indicated in the order generated';
			|it = 'La data dell''arrivo prevista, che
			|sarà specificata nell''ordine in corso di generazione';
			|pl = 'Data oczekiwanego otrzymania, która
			|zostanie określona w formowanym zamówieniu';
			|tr = 'Oluşturulan siparişte belirtilecek
			|olan beklenen alım tarihi'"));
			
		Hints.Insert("SupplyMethodsDaysBeforeTheOrderAccordingToTheSchedule",
			NStr("vi = 'Số ngày đến ngày lập
			|đơn hàng để giao gần nhất theo lịch biểu';
			|ru = 'Число дней до даты формирования
			|заказа на ближайшую поставку по графику';
			|en = 'Number of days before the date of order generation
			|for the nearest delivery on schedule'; fa = 'Number of days before the date of order generation
			|for the nearest delivery on schedule';
			|it = 'Il numero di giorni fino alla data di generazione
			|dell''ordine per la consegna programmata più vicina';
			|pl = 'Liczba dni przed datą złożenia
			|zamówienia na najbliższą dostawę zgodnie z harmonogramem';
			|tr = 'Programa göre en yakın tedarik için siparişin
			|oluşturulduğu tarihten önceki gün sayısı'"));
			
		Hints.Insert("GroupToOrderInventory",
			NStr("vi = 'Số lượng sẽ chỉ ra
			|trong đơn hàng đặt ra
			|để duy trì vật tư';
			|ru = 'Количество, которое будет указано
			|в формируемом заказе, заказываемое
			|для поддержания запаса';
			|en = 'Number that will be indicated
			|in generated order to maintain 
			|the inventory level'; fa = 'Number that will be indicated
			|in generated order to maintain 
			|the inventory level';
			|it = 'La quantità che verrà specificata
			|nell''ordine in corso di generazione, ordinata
			|per mantenere le scorte';
			|pl = 'Ilość, która zostanie określona
			|w formowanym zamówieniu, zamówiona
			|do utrzymania zapasów';
			|tr = 'Oluşturulan siparişte belirtilecek
			|olan miktar, stoku korumak için sipariş
			|edilir'"));
			
		Hints.Insert("OrdersPendingGoodsReceipt",
			NStr("vi = 'Số lượng đã đặt từ trước và số lượng dự kiến
			|tiếp nhận';
			|ru = 'Количество, заказаное ранее и ожидаемое к
			|поступлению';
			|en = 'Quantity ordered earlier and anticipated for
			|arrival'; fa = 'Quantity ordered earlier and anticipated for
			|arrival';
			|it = 'Quantità ordinata in precedenza e quella prevista in
			|arrivo';
			|pl = 'Ilość, zamówiona wcześniej i oczekiwana do
			| wpływu';
			|tr = 'Önceden sipariş edilen ve alımı
			|beklenen miktar'"));
			
	EndIf;
	
	If UseGoodsQualityControl Then
		
		Hints.Insert("SupplyMethodsBoundaryOfCoveredPeriod",
			NStr("vi = 'Mốc thời hạn của giai đoạn được đáp ứng bởi việc cung cấp. Nếu hàng hóa trong kho phải kiểm soát chất lượng, thời hạn kiểm soát chất lượng sẽ tự động được thêm vào mốc thời hạn đã thiết lập';
				|ru = 'Граница периода, обеспечиваемого поставкой. Если товар на складе подлежит контролю качества, то к установленной границе будет автоматически добавлен срок контроля качества';
				|en = 'The boundary of the period covered by the delivery. If the goods in the warehouse are subject to quality control, the quality control period will be automatically added to the specified boundary'; fa = 'The boundary of the period covered by the delivery. If the goods in the warehouse are subject to quality control, the quality control period will be automatically added to the specified boundary';
				|it = 'The boundary of the period covered by the delivery. If the goods in the warehouse are subject to quality control, the quality control period will be automatically added to the specified boundary';
				|pl = 'The boundary of the period covered by the delivery. If the goods in the warehouse are subject to quality control, the quality control period will be automatically added to the specified boundary';
				|tr = 'Teslimatla karşılanan dönemin sınırı. Ambardaki ürün kalite kontrolüne tabiyse, belirlenen sınıra otomatik olarak kalite kontrol süresi eklenir.'"));
		
	Else
		
		Hints.Insert("SupplyMethodsBoundaryOfCoveredPeriod",
			NStr("vi = 'Biên của kỳ, được đảm bảo bằng việc giao hàng';
				|ru = 'Граница периода, обеспечиваемого поставкой';
				|en = 'Boundary of the period covered by the delivery'; fa = 'Boundary of the period covered by the delivery';
				|it = 'Граница периода, обеспечиваемого поставкой';
				|pl = 'Boundary of the period covered by the delivery';
				|tr = 'Programa göre tedariğin sağladığı süre sınırı'"));
		
	EndIf;
	
	Hints.Insert("StrategyOfProcurement",
		NStr("vi = 'Phương thức đảm bảo nhu cầu đang có hiệu lực.
		|Duy trì vật tư có thiết lập vật tư tối thiểu
		|và tối đa thủ công, hoặc bằng cách tính toán
		|theo số hoặc thống kê nhu cầu';
		|ru = 'Действующий метод обеспечения потребностей.
		|Поддержание запаса с установкой минимального
		|и максимального запасов вручную, либо расчетным
		|путем по норме или по статистике потребления';
		|en = 'Current method to meet the demand.
		|The inventory is maintained through manual setup of minimum
		|and maximum inventory or calculations by the rate or
		|consumption rate statistics'; fa = 'Current method to meet the demand.
		|The inventory is maintained through manual setup of minimum
		|and maximum inventory or calculations by the rate or
		|consumption rate statistics';
		|it = 'L''attuale metodo di approvvigionamento dei fabbisogni.
		|Mantenimento delle scorte con l''impostazione delle scorte minime
		|e massime manualmente, oppure tramite il calcolo
		|in base alla norma o alle statistiche di consumo';
		|pl = 'Obecny sposób zaspokojenia potrzeb.
		|Utrzymywanie zapasów wraz z instalacją rezerw minimalnych
		| i maksymalnych ręcznie lub obliczane 
		|przez normę lub statystyki zużycia';
		|tr = 'Mevcut talebi karşılama yöntemi.
		|Minimum
		|ve maksimum stokların manuel olarak ayarlanmasıyla veya orana göre veya tüketim istatistiklerine göre hesaplanarak
		|stokun bakımı'"));
	
	Hints.Insert("MinimumInventory",
		NStr("vi = 'Số lượng vật tư tối thiểu,
		|đã chỉ ra trong hạn chế hàng hóa,
		|hoặc tính theo thống kê';
		|ru = 'Минимальное количество запаса,
		|указанное в товарном ограничении,
		|или рассчитанное по статистике';
		|en = 'Minimum inventory quantity
		|specified in goods restriction
		|or calculated by statistics'; fa = 'Minimum inventory quantity
		|specified in goods restriction
		|or calculated by statistics';
		|it = 'La quantità minima delle scorte,
		| specificata nella restrizione del prodotto,
		| oppure calcolata in base alle statistiche';
		|pl = 'Minimalna ilość zapasów,
		|określona w ograniczeniu towaru
		|lub obliczona zgodnie ze statystykami';
		|tr = 'Ürün sınırı ile
		|belirtilen
		|veya istatistiklerden hesaplanan minimum stok miktarı'"));
	
	Hints.Insert("MaximumInventory",
		NStr("vi = 'Số lượng vật tư tối đa,
		|đã chỉ ra trong hạn chế hàng hóa,
		|hoặc tính theo thống kê';
		|ru = 'Максимальное количество запаса,
		|указанное в товарном ограничении,
		|или рассчитанное по статистике';
		|en = 'Maximum inventory amount
		|specified in goods restriction
		|or calculated by statistics'; fa = 'Maximum inventory amount
		|specified in goods restriction
		|or calculated by statistics';
		|it = 'La quantità massima delle scorte,
		| specificata nella restrizione del prodotto,
		| oppure calcolata in base alle statistiche';
		|pl = 'Maksymalna ilość zapasów,
		|określona w ograniczeniu towaru
		|lub obliczona zgodnie ze statystykami';
		|tr = 'Ürün sınırı ile
		|belirtilen
		|veya istatistiklerden hesaplanan maksimum stok miktarı'"));
	
	Hints.Insert("Balance", NStr("vi = 'Số dư hiện tại của hàng hóa trong kho';
								|ru = 'Текущий остаток товара на складе';
								|en = 'Current stock balance in the warehouse'; fa = 'Current stock balance in the warehouse';
								|it = 'Giacenze attuali delle merci nel magazzino';
								|pl = 'Aktualny stan zapasów';
								|tr = 'Mevcut ambar bakiyesi'"));
	
	For Each ToolTip In Hints Do
		Items[ToolTip.Key].ToolTip = ToolTip.Value;
	EndDo;
	
EndProcedure

&AtClient
Procedure CheckCorrectnessOfFillingFilterForShipmentNoLaterThan(Date, StandardProcessing)

	If Date < FilterToShipNotEarlier And ValueIsFilled(FilterToShipNotEarlier) Then

		StandardProcessing = False;
		ShowMessageBox(, NStr("vi = 'Ngày kết thúc kỳ không thể nhỏ hơn ngày bắt đầu';
								|ru = 'Дата окончания периода не может быть меньше даты начала';
								|en = 'Period end date cannot be less than start date'; fa = 'Period end date cannot be less than start date';
								|it = 'La data di fine periodo non può essere inferiore alla data d''inizio';
								|pl = 'Data zakończenia okresu nie może być mniejsza od daty rozpoczęcia';
								|tr = 'Dönemin bitiş tarihi, başlangıç ​​tarihinden önce olamaz'"), , );

	EndIf;

EndProcedure

&AtClientAtServerNoContext
Function ProcessEmptySource(SupplySource, TextNotFilledIn)
	
	If Not ValueIsFilled(SupplySource) Then
		SupplySource = TextNotFilledIn;
	EndIf;
	
	Return SupplySource;
	
EndFunction

&AtServer
Procedure ReportErrorInEmptySecurityMethod(Table)
	
	TextTemplate1 = Undefined;
	If Items.PagesDemandTable.CurrentPage = Items.PageTableInventory Then
		
		TableName = "Inventories";
		TextTemplate1 = NStr("vi = 'Chưa điền cột ""Phương thức đảm bảo"" tại dòng %LineNumber% danh sách ""Duy trì vật tư""';
							|ru = 'Не заполнена колонка ""Способ обеспечения"" в строке %LineNumber% списка ""Поддержание запасов""';
							|en = 'Column ""Procurement strategy"" in line %LineNumber% of the ""Inventory level control"" list is not filled in'; fa = 'Column ""Procurement strategy"" in line %LineNumber% of the ""Inventory level control"" list is not filled in';
							|it = 'Non è compilata la colonna ""Metodo di approvviggionamento"" nella riga %LineNumber% dell''elenco ""Sostentamento delle riserve""';
							|pl = 'Nie wypełniono kolumny ""Sposób zaspokojenia"" w wierszu %LineNumber% listy ""Utrzymanie zapasów""';
							|tr = '""Stok yenileme"" listesinin satırında %LineNumber% ""Tedarik stratejisi"" sütunu doldurulmaz'");
		
	ElsIf Items.PagesDemandTable.CurrentPage = Items.PageTableOrders Then
		
		TableName = "OrdersPendingSupply";
		TextTemplate1 = NStr("vi = 'Chưa điền cột ""Phương thức đảm bảo"" tại dòng %LineNumber% danh sách ""Đảm bảo đơn hàng""';
							|ru = 'Не заполнена колонка ""Способ обеспечения"" в строке %LineNumber% списка ""Обеспечение заказов""';
							|en = 'Column ""Procurement strategy"" column in line %LineNumber% of the ""Order fulfillment"" list is not filled in'; fa = 'Column ""Procurement strategy"" column in line %LineNumber% of the ""Order fulfillment"" list is not filled in';
							|it = 'Non è compilata la colonna ""Metodo di approvviggionamento"" nella riga %LineNumber% dell''elenco ""Fornitura di ordini""';
							|pl = 'Nie wypełniono kolumny ""Sposób zaspokojenia"" w wierszu %LineNumber% listy ""Zabezpieczenie zamówień""';
							|tr = '""Stokların bakımı"" listesinin satırında %LineNumber% ""Tedarik stratejisi"" sütunu doldurulmaz'");
		
	EndIf;
	
	Table = Object[TableName]; // Data FormCollection - 
	
	For Each String In Table Do
		
		If String.Mark And Not ValueIsFilled(String.SupplyMethod) Then
			
			ErrorText = StrReplace(TextTemplate1, "%LineNumber%", Table.IndexOf(String) + 1);
			PathToTop = CommonClientServer.PathToTabularSection(TableName,
				Table.IndexOf(String) + 1, "SupplyMethod");
			Common.MessageToUser(ErrorText, Undefined, "Object." + PathToTop);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FillInSourceOfProvision(ArrayOfTypesSupply)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.DemandFulfillment.Form.Form.Command.FillInSourceOfProvision");
	
	CurrentTable = ?(Items.PagesDemandTable.CurrentPage = Items.PageTableInventory,
		"Inventories", "OrdersPendingSupply");
	
	FormParameters = New Structure("SupplyType, GroupFillingIn", Undefined, True);
	For Each Id In Items[CurrentTable].SelectedRows Do
		NeedString = Object[CurrentTable].FindByID(Id);
		If Not NeedString.SupplySourceViewOnly
			And ArrayOfTypesSupply.Find(NeedString.SupplyType) <> Undefined Then
			FormParameters.SupplyType = NeedString.SupplyType;
			Break;
		EndIf;
	EndDo;
	
	If FormParameters.SupplyType <> Undefined Then
		OpenForm("DataProcessor.DemandFulfillment.Form.SelectionFormOfSourceOfSupply", FormParameters, ThisForm, UUID);
	Else
		ShowMessageBox(, NStr("vi = 'Không một dòng nào được chọn với nguồn đảm bảo có thể thay đổi. Thực thi lệnh là không thể.';
								|ru = 'Не выделено ни одной строки с доступным для изменения источником обеспечения. Выполнение команды невозможно.';
								|en = 'No lines with editable sources of supply are selected. Cannot run the command.'; fa = 'No lines with editable sources of supply are selected. Cannot run the command.';
								|it = 'Non è stata selezionata una singola riga con una fonte di approvvigionamento disponibile alla modifica. Il comando non può essere eseguito.';
								|pl = 'Żaden wiersz nie został przydzielony ze źródłem zabezpieczenia, które można zmienić. Polecenie nie może zostać wykonane.';
								|tr = 'Değişim için erişilebilir tedarik kaynağı olan tek bir satır bile seçilmemiştir. Komut çalıştırılamıyor.'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomizeFormForIntendedUse()
	
	ThisIsFormationOfApplications = PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds();
	
	If Not ThisIsFormationOfApplications
		Or Not Documents.PurchaseRequest.UseBDRLimits() Then
			// Purchase goals are not used.
			PurchaseObjective = PurchaseRequestClientServer.DefaultPurchaseTarget();
			Items.PurchaseObjective.Visible = False;
	EndIf;
	
	If Not ThisIsFormationOfApplications Then
		Return;
	EndIf;
	
	AutoTitle = False;
	Title = NStr("vi = 'Lập giấy đề nghị mua hàng theo nhu cầu';
				|ru = 'Формирование заявок на закупку по потребностям';
				|en = 'Generate purchase requests by demand'; fa = 'ایجاد درخواست‌های خرید بر اساس نیاز';
				|it = 'Generate purchase requests by demand';
				|pl = 'Generate purchase requests by demand';
				|tr = 'İhtiyaca göre satın alma talebi oluşturma'");
	
	Items.AllActionsGeneratedOrders.Title = NStr("vi = 'Các giấy đề nghị đã được tạo (Tất cả các thao tác)';
												|ru = 'Сформированные заявки (Все действия)';
												|en = 'Generated requests (All actions)'; fa = 'Generated requests (All actions)';
												|it = 'Generated requests (All actions)';
												|pl = 'Generated requests (All actions)';
												|tr = 'Oluşturulan talepler (Tüm İşlemler)'");
	Items.GroupOrdersToBeReceived.Title = NStr("vi = 'Cần tiếp nhận';
												|ru = 'К поступлению';
												|en = 'To receive'; fa = 'برای دریافت';
												|it = 'In arrivo';
												|pl = 'Do przyjęcia';
												|tr = 'Teslim alınacak'");
	Items.Totals1Group.Title = NStr("vi = 'Tổng cộng vào giấy đề nghị';
									|ru = 'Итого в заявку';
									|en = 'Total to request'; fa = 'Total to request';
									|it = 'Total to request';
									|pl = 'Total to request';
									|tr = 'Talebe eklenecek toplam'");
	Items.GroupResultsStep5.Title = NStr("vi = 'Tổng cộng vào giấy đề nghị';
										|ru = 'Итого в заявку';
										|en = 'Total to request'; fa = 'Total to request';
										|it = 'Total to request';
										|pl = 'Total to request';
										|tr = 'Talebe eklenecek toplam'");
	
	Items.ForOrderGroup1.Title = NStr("vi = 'Nhóm vào giấy đề nghị (1)';
										|ru = 'Группа в заявку (1)';
										|en = 'Group to request (1)'; fa = 'Group to request (1)';
										|it = 'Group to request (1)';
										|pl = 'Group to request (1)';
										|tr = 'Grup talebe ekle (1)'");
	Items.ForOrderGroup2.Title = NStr("vi = 'Nhóm vào giấy đề nghị (2)';
										|ru = 'Группа в заявку (2)';
										|en = 'Group to request (2)'; fa = 'Group to request (2)';
										|it = 'Group to request (2)';
										|pl = 'Group to request (2)';
										|tr = 'Grup talebe ekle (2)'");
	Items.ForOrderGroup3.Title = NStr("vi = 'Nhóm vào giấy đề nghị (3)';
										|ru = 'Группа в заявку (3)';
										|en = 'Group to request (3)'; fa = 'Group to request (3)';
										|it = 'Group to request (3)';
										|pl = 'Group to request (3)';
										|tr = 'Grup talebe ekle (3)'");
	Items.ForOrderGroup4.Title = NStr("vi = 'Nhóm vào giấy đề nghị (4)';
										|ru = 'Группа в заявку (4)';
										|en = 'Group to request (4)'; fa = 'Group to request (4)';
										|it = 'Group to request (4)';
										|pl = 'Group to request (4)';
										|tr = 'Grup talebe ekle (4)'");
	Items.ForOrderGroup7.Title = NStr("vi = 'Nhóm vào giấy đề nghị (7)';
										|ru = 'Группа в заявку (7)';
										|en = 'Group to request (7)'; fa = 'Group to request (7)';
										|it = 'Group to request (7)';
										|pl = 'Group to request (7)';
										|tr = 'Grup talebe ekle (7)'");
	
	Items.GroupToOrderOrders.Title = NStr("vi = 'Vào giấy đề nghị (các giấy đề nghị)';
											|ru = 'В заявку (заявки)';
											|en = 'To request (requests)'; fa = 'To request (requests)';
											|it = 'To request (requests)';
											|pl = 'To request (requests)';
											|tr = 'Talebe ekle (talepler)'");
	Items.GroupToOrderInventory.Title = NStr("vi = 'Vào giấy đề nghị (hàng tồn kho)';
											|ru = 'В заявку (запасы)';
											|en = 'To request (inventory)'; fa = 'To request (inventory)';
											|it = 'To request (inventory)';
											|pl = 'To request (inventory)';
											|tr = 'Talebe ekle (stoklar)'");
	Items.GroupOrderEditingStepFooter.Title = NStr("vi = 'Nhóm dưới bước điều chỉnh giấy đề nghị';
													|ru = 'Группа подвал шага редактирование заявкок';
													|en = 'Group request editing step footer'; fa = 'Group request editing step footer';
													|it = 'Group request editing step footer';
													|pl = 'Group request editing step footer';
													|tr = 'Grup aşamanın alt bilgisi talebin düzenlenmesi'");
	
	Items.OrdersPendingGoodsReceipt.Title = NStr("vi = 'Cần thu';
												|ru = 'К поступлению';
												|en = 'To receive'; fa = 'برای دریافت';
												|it = 'In arrivo';
												|pl = 'Do przyjęcia';
												|tr = 'Teslim alınacak'");
	
	Items.OrdersPendingGoodsReceipt.ToolTip = NStr("vi = 'Số lượng đã đặt từ trước và số lượng dự kiến
	|tiếp nhận';
	|ru = 'Количество, заказаное ранее и ожидаемое к
	|поступлению';
	|en = 'Quantity ordered earlier and anticipated for
	|arrival'; fa = 'Quantity ordered earlier and anticipated for
	|arrival';
	|it = 'Quantità ordinata in precedenza e quella prevista in
	|arrivo';
	|pl = 'Ilość, zamówiona wcześniej i oczekiwana do
	| wpływu';
	|tr = 'Önceden sipariş edilen ve alımı
	|beklenen miktar'");
	Items.OrdersPendingGoodsReceipt1.Title = NStr("vi = 'Cần thu';
													|ru = 'К поступлению';
													|en = 'To receive'; fa = 'برای دریافت';
													|it = 'In arrivo';
													|pl = 'Do przyjęcia';
													|tr = 'Teslim alınacak'");
	Items.OrdersPendingGoodsReceipt2.Title = NStr("vi = 'Cần thu';
													|ru = 'К поступлению';
													|en = 'To receive'; fa = 'برای دریافت';
													|it = 'In arrivo';
													|pl = 'Do przyjęcia';
													|tr = 'Teslim alınacak'");
	Items.OrdersPendingGoodsReceipt3.Title = NStr("vi = 'Cần thu';
													|ru = 'К поступлению';
													|en = 'To receive'; fa = 'برای دریافت';
													|it = 'In arrivo';
													|pl = 'Do przyjęcia';
													|tr = 'Teslim alınacak'");
	Items.OrdersPendingGoodsReceipt4.Title = NStr("vi = 'Cần thu';
													|ru = 'К поступлению';
													|en = 'To receive'; fa = 'برای دریافت';
													|it = 'In arrivo';
													|pl = 'Do przyjęcia';
													|tr = 'Teslim alınacak'");
	Items.FillInForOrderAllGoodsForSelectedLines.Title = NStr("vi = 'Xong, tạo giấy đề nghị theo kế hoạch.';
																|ru = 'Все, плановое формирование заявки';
																|en = 'All, scheduled request placement'; fa = 'All, scheduled request placement';
																|it = 'All, scheduled request placement';
																|pl = 'All, scheduled request placement';
																|tr = 'Hepsi, planlı talep oluşumu'");
	Commands.Find(Items.FillInForOrderAllGoodsForSelectedLines.CommandName).ToolTip = NStr("vi = 'Điền tất cả hàng hóa của các dòng được chọn vào giấy đề nghị';
																							|ru = 'Заполнить в заявку все товары выделенных строк';
																							|en = 'Add all items in the selected lines to the request'; fa = 'Add all items in the selected lines to the request';
																							|it = 'Add all items in the selected lines to the request';
																							|pl = 'Add all items in the selected lines to the request';
																							|tr = 'Seçili satırlardaki talep edilecek tüm malları doldur'");
	
	Items.FillInForOrderTheGoodsThatHaveReachedTheOrderPointForSelectedLines.Title = NStr("vi = 'Điểm đặt hàng đã đạt';
																							|ru = 'Достигшие точки заказа';
																							|en = 'Reached reorder point'; fa = 'به نقطه سفارش مجدد رسیده';
																							|it = 'Raggiunto il punto di ordine';
																							|pl = 'Osiągnęły punkt zamówienia';
																							|tr = 'Yeniden sipariş noktasına varmış olanlar'");
	Commands.Find(Items.FillInForOrderTheGoodsThatHaveReachedTheOrderPointForSelectedLines.CommandName).ToolTip = NStr("vi = 'Điền vào giấy đề nghị các hàng hóa đã đạt đến điểm đặt hàng đối với các dòng được chọn';
																														|ru = 'Заполнить в заявку товары достигшие точки заказа для выделенных строк';
																														|en = 'Add the goods that have reached the reorder point for selected lines to the request'; fa = 'Add the goods that have reached the reorder point for selected lines to the request';
																														|it = 'Add the goods that have reached the reorder point for selected lines to the request';
																														|pl = 'Add the goods that have reached the reorder point for selected lines to the request';
																														|tr = 'Seçilen satırlar için yeniden sipariş noktasına ulaşan talep edilecek malları doldur'");
	Items.TotalOrders.Title = NStr("vi = 'Tổng cộng theo các giấy đề nghị:';
									|ru = 'Итого по заявкам:';
									|en = 'Total by requests:'; fa = 'Total by requests:';
									|it = 'Total by requests:';
									|pl = 'Total by requests:';
									|tr = 'Taleplere göre toplam:'");
	Items.TotalOrdersStep5.Title = NStr("vi = 'Tổng cộng theo các yêu cầu:';
										|ru = 'Итого по заявкам:';
										|en = 'Total by requests:'; fa = 'Total by requests:';
										|it = 'Total by requests:';
										|pl = 'Total by requests:';
										|tr = 'Taleplere göre toplam:'");
	
	Items.ToOrder1.Title = NStr("vi = 'Số lượng trong giấy đề nghị ghi chú';
								|ru = 'Количество в заявку надпись';
								|en = 'Quantity to request label'; fa = 'Quantity to request label';
								|it = 'Quantity to request label';
								|pl = 'Quantity to request label';
								|tr = 'Sipariş sayısı etiket'");
	Items.ToOrder2.Title = NStr("vi = 'Số lượng trong giấy đề nghị ghi chú';
								|ru = 'Количество в заявку надпись';
								|en = 'Quantity to request label'; fa = 'Quantity to request label';
								|it = 'Quantity to request label';
								|pl = 'Quantity to request label';
								|tr = 'Sipariş sayısı etiket'");
	Items.ToOrder3.Title = NStr("vi = 'Số lượng trong giấy đề nghị ghi chú';
								|ru = 'Количество в заявку надпись';
								|en = 'Quantity to request label'; fa = 'Quantity to request label';
								|it = 'Quantity to request label';
								|pl = 'Quantity to request label';
								|tr = 'Sipariş sayısı etiket'");
	
	Items.ToOrder4.Title = NStr("vi = 'Chuyển vào giấy đề nghị';
								|ru = 'В заявку';
								|en = 'To request'; fa = 'To request';
								|it = 'To request';
								|pl = 'To request';
								|tr = 'Talebe ekle'");
	Items.ToOrder7.Title = NStr("vi = 'Chuyển vào giấy đề nghị';
								|ru = 'В заявку';
								|en = 'To request'; fa = 'To request';
								|it = 'To request';
								|pl = 'To request';
								|tr = 'Talebe ekle'");
	Items.ToOrderOrders.Title = NStr("vi = 'Chuyển vào giấy đề nghị';
									|ru = 'В заявку';
									|en = 'To request'; fa = 'To request';
									|it = 'To request';
									|pl = 'To request';
									|tr = 'Talebe ekle'");
	Items.ToOrderInventory.Title = NStr("vi = 'Chuyển vào giấy đề nghị';
										|ru = 'В заявку';
										|en = 'To request'; fa = 'To request';
										|it = 'To request';
										|pl = 'To request';
										|tr = 'Talebe ekle'");
	
	Items.ToOrderLabel1.Title = NStr("vi = 'Chuyển vào giấy đề nghị:';
									|ru = 'В заявку:';
									|en = 'To request:'; fa = 'To request:';
									|it = 'To request:';
									|pl = 'To request:';
									|tr = 'Talebe ekle:'");
	Items.OrderLabel2.Title = NStr("vi = 'Chuyển vào giấy đề nghị:';
									|ru = 'В заявку:';
									|en = 'To request:'; fa = 'To request:';
									|it = 'To request:';
									|pl = 'To request:';
									|tr = 'Talebe ekle:'");
	Items.ToOrderTheLabel3.Title = NStr("vi = 'Chuyển vào giấy đề nghị:';
										|ru = 'В заявку:';
										|en = 'To request:'; fa = 'To request:';
										|it = 'To request:';
										|pl = 'To request:';
										|tr = 'Talebe ekle:'");
	Items.OrderLabel4.Title = NStr("vi = 'Chuyển vào giấy đề nghị:';
									|ru = 'В заявку:';
									|en = 'To request:'; fa = 'To request:';
									|it = 'To request:';
									|pl = 'To request:';
									|tr = 'Talebe ekle:'");
	Items.OrderLabel7.Title = NStr("vi = 'Chuyển vào giấy đề nghị:';
									|ru = 'В заявку:';
									|en = 'To request:'; fa = 'To request:';
									|it = 'To request:';
									|pl = 'To request:';
									|tr = 'Talebe ekle:'");
	
	Items.CommandsMoreOrders.Title = NStr("vi = 'Các lệnh khác cho giấy đề nghị';
											|ru = 'Команды еще заявки';
											|en = 'Commands more requests'; fa = 'Commands more requests';
											|it = 'Commands more requests';
											|pl = 'Commands more requests';
											|tr = 'Komutlar diğer talepler'");
	Items.CommandsToFillInTheOrderItems.Title = NStr("vi = 'Điền ""Chuyển vào giấy đề nghị hàng hóa""';
													|ru = 'Заполнить ""В заявку товары""';
													|en = 'Fill ""Demand conversion option""'; fa = 'Fill ""Demand conversion option""';
													|it = 'Fill ""Demand conversion option""';
													|pl = 'Fill ""Demand conversion option""';
													|tr = '""Talebe eklenecek mallar"" kısmını doldur'");
	
	Items.CommandsLeftStepOrdersEditing.Title = NStr("vi = 'Lệnh trái bước điều chỉnh giấy đề nghị';
													|ru = 'Команды лево шаг редактирование заявок';
													|en = 'Commands left step request editing'; fa = 'Commands left step request editing';
													|it = 'Commands left step request editing';
													|pl = 'Commands left step request editing';
													|tr = 'Komutlar sol adım talebi düzenleme'");
	Items.CommandsLeftStepGeneratedOrders.Title = NStr("vi = 'Lệnh trái bước lập giấy đề nghị';
														|ru = 'Команды лево шаг сформированные заявки';
														|en = 'Commands left step generated requests'; fa = 'Commands left step generated requests';
														|it = 'Commands left step generated requests';
														|pl = 'Commands left step generated requests';
														|tr = 'Komutlar sol adım oluşturulan talepler'");
	Items.CommandsBottomStepOrdersEditing.Title = NStr("vi = 'Lệnh dưới bước điều chỉnh giấy đề nghị';
														|ru = 'Команды низ шаг редактирование заявок';
														|en = 'Commands bottom step request editing'; fa = 'Commands bottom step request editing';
														|it = 'Commands bottom step request editing';
														|pl = 'Commands bottom step request editing';
														|tr = 'Komutlar aşağı adım talebi düzenleme'");
	Items.CommandsBottomStepGeneratedOrders.Title = NStr("vi = 'Lệnh bước dưới lập giấy đề nghị';
														|ru = 'Команды низ шаг сформированные заявки';
														|en = 'Commands bottom step generated requests'; fa = 'Commands bottom step generated requests';
														|it = 'Commands bottom step generated requests';
														|pl = 'Commands bottom step generated requests';
														|tr = 'Komutlar aşağı adım oluşturulan talepler'");
	Items.CommandsRightStepOrdersEditing.Title = NStr("vi = 'Lệnh phải bước điều chỉnh giấy đề nghị';
														|ru = 'Команды право шаг редактирование заявок';
														|en = 'Commands right step request editing'; fa = 'Commands right step request editing';
														|it = 'Commands right step request editing';
														|pl = 'Commands right step request editing';
														|tr = 'Komutlar sağ adım talebi düzenleme'");
	Items.CommandsRightStepGeneratedOrders.Title = NStr("vi = 'Lệnh phải bước lập giấy đề nghị';
														|ru = 'Команды право шаг сформированные заявки';
														|en = 'Commands right step generated requests'; fa = 'Commands right step generated requests';
														|it = 'Commands right step generated requests';
														|pl = 'Commands right step generated requests';
														|tr = 'Komutlar sağ adım oluşturulan talepler'");
	
	Items.ForOrderCancellationImage.Title = NStr("vi = 'Cần hủy bỏ giấy đề nghị hình vẽ';
												|ru = 'К отмене заявки картинка';
												|en = 'To cancel request picture'; fa = 'To cancel request picture';
												|it = 'To cancel request picture';
												|pl = 'To cancel request picture';
												|tr = 'Sipariş iptali için resim'");
	Items.MarkToOrderOrders.Title = NStr("vi = 'Đánh dấu trong giấy đề nghị';
										|ru = 'Отметить в заявку';
										|en = 'Select in request'; fa = 'Select in request';
										|it = 'Select in request';
										|pl = 'Select in request';
										|tr = 'Talep için işaretle'");
	Commands.Find(Items.MarkToOrderOrders.CommandName).ToolTip = NStr("vi = 'Đánh dấu chọn vào cột ""Chuyển vào giấy đề nghị""';
																		|ru = 'Установить флажок в колонке ""В заявку""';
																		|en = 'Select the checkbox in the ""To request"" column'; fa = 'Select the checkbox in the ""To request"" column';
																		|it = 'Select the checkbox in the ""To request"" column';
																		|pl = 'Select the checkbox in the ""To request"" column';
																		|tr = '""Talebe ekle"" sütununda bayrağı ayarla'");
	Items.AddInventoryToTheOrder.Title = NStr("vi = 'Đánh dấu trong giấy đề nghị';
												|ru = 'Отметить в заявку';
												|en = 'Select in request'; fa = 'Select in request';
												|it = 'Select in request';
												|pl = 'Select in request';
												|tr = 'Talep için işaretle'");
	Commands.Find(Items.AddInventoryToTheOrder.CommandName).ToolTip = NStr("vi = 'Đánh dấu chọn vào cột ""Chuyển vào giấy đề nghị""';
																			|ru = 'Установить флажок в колонке ""В заявку""';
																			|en = 'Select the checkbox in the ""To request"" column'; fa = 'Select the checkbox in the ""To request"" column';
																			|it = 'Select the checkbox in the ""To request"" column';
																			|pl = 'Select the checkbox in the ""To request"" column';
																			|tr = '""Talebe ekle"" sütununda bayrağı ayarla'");
	Items.PreviewToOrder.Title = NStr("vi = 'Chuyển vào giấy đề nghị';
										|ru = 'В заявку';
										|en = 'To request'; fa = 'To request';
										|it = 'To request';
										|pl = 'To request';
										|tr = 'Başvuruya'");
	
	Items.OrderCalculation1.Title = NStr("vi = 'Tính toán giấy đề nghị';
										|ru = 'Расчет заявки';
										|en = 'Request calculation'; fa = 'Request calculation';
										|it = 'Request calculation';
										|pl = 'Request calculation';
										|tr = 'Talep hesaplama'");
	Items.OrderCalculation2.Title = NStr("vi = 'Tính toán giấy đề nghị';
										|ru = 'Расчет заявки';
										|en = 'Request calculation'; fa = 'Request calculation';
										|it = 'Request calculation';
										|pl = 'Request calculation';
										|tr = 'Talep hesaplama'");
	Items.OrderCalculation3.Title = NStr("vi = 'Tính toán giấy đề nghị';
										|ru = 'Расчет заявки';
										|en = 'Request calculation'; fa = 'Request calculation';
										|it = 'Request calculation';
										|pl = 'Request calculation';
										|tr = 'Talep hesaplama'");
	Items.OrderCalculation4.Title = NStr("vi = 'Tính toán giấy đề nghị';
										|ru = 'Расчет заявки';
										|en = 'Request calculation'; fa = 'Request calculation';
										|it = 'Request calculation';
										|pl = 'Request calculation';
										|tr = 'Talep hesaplama'");
	Items.OrderCalculation4.ToolTip = NStr("vi = 'Tính toán giấy đề nghị';
											|ru = 'Расчет заявки';
											|en = 'Request calculation'; fa = 'Request calculation';
											|it = 'Request calculation';
											|pl = 'Request calculation';
											|tr = 'Talep hesaplama'");
	Items.OrderCalculation7.Title = NStr("vi = 'Tính toán giấy đề nghị';
										|ru = 'Расчет заявки';
										|en = 'Request calculation'; fa = 'Request calculation';
										|it = 'Request calculation';
										|pl = 'Request calculation';
										|tr = 'Talep hesaplama'");
	
	Commands.Find(Items.UnmarkOrders.CommandName).ToolTip = NStr("vi = 'Bỏ đánh dấu chọn vào cột ""Chuyển vào giấy đề nghị""';
																|ru = 'Снять флажок в колонке ""В заявку""';
																|en = 'Clear the checkbox in the ""To request"" column'; fa = 'Clear the checkbox in the ""To request"" column';
																|it = 'Clear the checkbox in the ""To request"" column';
																|pl = 'Clear the checkbox in the ""To request"" column';
																|tr = '""Talebe ekle"" sütununda bayrağı kaldır'");
	Commands.Find(Items.UnmarkInventory.CommandName).ToolTip = NStr("vi = 'Bỏ đánh dấu chọn vào cột ""Chuyển vào giấy đề nghị""';
																	|ru = 'Снять флажок в колонке ""В заявку""';
																	|en = 'Clear the checkbox in the ""To request"" column'; fa = 'Clear the checkbox in the ""To request"" column';
																	|it = 'Clear the checkbox in the ""To request"" column';
																	|pl = 'Clear the checkbox in the ""To request"" column';
																	|tr = '""Talebe ekle"" sütununda bayrağı kaldır'");
	
	Items.SupplyMethodsDemandConversionOption.Title = NStr("vi = 'Chuyển vào giấy đề nghị hàng hóa';
															|ru = 'В заявку товары';
															|en = 'Demand conversion option'; fa = 'گزینه تبدیل نیاز';
															|it = 'Demand conversion option';
															|pl = 'Demand conversion option';
															|tr = 'Talebe eklenecek mallar'");
	
	Items.PageCommandsAndFiltersOrders.Title = NStr("vi = 'Trang lệnh và bộ lọc giấy đề nghị';
													|ru = 'Страница команды и фильтры заявки';
													|en = 'Page commands and filters requests'; fa = 'Page commands and filters requests';
													|it = 'Page commands and filters requests';
													|pl = 'Page commands and filters requests';
													|tr = 'Sayfa komutlar ve filtreler talepler'");
	Items.PageTableOrders.Title = NStr("vi = 'Trang bảng giấy đề nghị';
										|ru = 'Страница таблица заявки';
										|en = 'Page table requests'; fa = 'Page table requests';
										|it = 'Page table requests';
										|pl = 'Page table requests';
										|tr = 'Sayfa tablo talepler'");
	
	Items.PagesToOrderFormula1.Title = NStr("vi = 'Trang vào giấy đề nghị công thức 1';
											|ru = 'Страницы в заявку формула 1';
											|en = 'Pages to request formula 1'; fa = 'Pages to request formula 1';
											|it = 'Pages to request formula 1';
											|pl = 'Pages to request formula 1';
											|tr = 'Sayfalar talebe ekle formül 1'");
	Items.PagesToOrderFormula2.Title = NStr("vi = 'Trang vào giấy đề nghị công thức 2';
											|ru = 'Страницы в заявку формула 2';
											|en = 'Pages to request formula 2'; fa = 'Pages to request formula 2';
											|it = 'Pages to request formula 2';
											|pl = 'Pages to request formula 2';
											|tr = 'Sayfalar talebe ekle formül 2'");
	Items.PagesToOrderFormula3.Title = NStr("vi = 'Trang vào giấy đề nghị công thức 3';
											|ru = 'Страницы в заявку формула 3';
											|en = 'Pages to request formula 3'; fa = 'Pages to request formula 3';
											|it = 'Pages to request formula 3';
											|pl = 'Pages to request formula 3';
											|tr = 'Sayfalar talebe ekle formül 3'");
	Items.PagesToOrderFormula3.ToolTip = NStr("vi = 'Trang vào giấy đề nghị công thức 3';
												|ru = 'Страницы в заявку формула 3';
												|en = 'Pages to request formula 3'; fa = 'Pages to request formula 3';
												|it = 'Pages to request formula 3';
												|pl = 'Pages to request formula 3';
												|tr = 'Sayfalar talebe ekle formül 3'");
	Items.PagesToOrderFormula4.Title = NStr("vi = 'Trang vào giấy đề nghị công thức 4';
											|ru = 'Страницы в заявку формула 4';
											|en = 'Pages to request formula 4'; fa = 'Pages to request formula 4';
											|it = 'Pages to request formula 4';
											|pl = 'Pages to request formula 4';
											|tr = 'Sayfalar talebe ekle formül 4'");
	Items.PagesToOrderFormula4.ToolTip = NStr("vi = 'Trang vào giấy đề nghị công thức 4';
												|ru = 'Страницы в заявку формула 4';
												|en = 'Pages to request formula 4'; fa = 'Pages to request formula 4';
												|it = 'Pages to request formula 4';
												|pl = 'Pages to request formula 4';
												|tr = 'Sayfalar talebe ekle formül 4'");
	
	Items.WarnString.Title = NStr("vi = 'Số tiền đặt hàng tối thiểu theo thỏa thuận %1 số tiền hiện tại %2 Nên tăng tổng cộng giấy đề nghị.';
									|ru = 'Минимальная сумма заказа по соглашению %1 текущая сумма %2 рекомендуется увеличить сумму заявки.';
									|en = 'Minimum order amount as per terms of purchase %1 Current amount %2 Increase the request amount.'; fa = 'Minimum order amount as per terms of purchase %1 Current amount %2 Increase the request amount.';
									|it = 'Minimum order amount as per terms of purchase %1 Current amount %2 Increase the request amount.';
									|pl = 'Minimum order amount as per terms of purchase %1 Current amount %2 Increase the request amount.';
									|tr = 'Anlaşmaya göre minimum sipariş tutarı %1 mevcut tutar %2 talep tutarının arttırılması öneriliyor.'");
	Items.GeneratedOrders.Title = NStr("vi = 'Giấy đề nghị đã lập';
										|ru = 'Сформированные заявки';
										|en = 'Generated requests'; fa = 'Generated requests';
										|it = 'Generated requests';
										|pl = 'Generated requests';
										|tr = 'Oluşturulan başvurular'");
	Items.ToFormTheOrders.Title = NStr("vi = 'Lập giấy đề nghị >';
										|ru = 'Сформировать заявки >';
										|en = 'Generate requests  >'; fa = 'Generate requests  >';
										|it = 'Generate requests  >';
										|pl = 'Generate requests  >';
										|tr = 'Oluşturulan talepler >'");
	Items.OrderPackage.Title = NStr("vi = 'Đóng gói giấy đề nghị';
									|ru = 'Упаковка заявки';
									|en = 'Request packaging unit'; fa = 'Request packaging unit';
									|it = 'Request packaging unit';
									|pl = 'Request packaging unit';
									|tr = 'Talep paketleme ünitesi'");
	Items.OrderPackagingInventory.Title = NStr("vi = 'Đóng gói giấy đề nghị';
												|ru = 'Упаковка заявки';
												|en = 'Request packaging unit'; fa = 'Request packaging unit';
												|it = 'Request packaging unit';
												|pl = 'Request packaging unit';
												|tr = 'Talep paketleme ünitesi'");
	Items.OrderFilters.Title = NStr("vi = 'Bộ lọc của giấy đề nghị';
									|ru = 'Фильтры заявки';
									|en = 'Request filters'; fa = 'Request filters';
									|it = 'Request filters';
									|pl = 'Request filters';
									|tr = 'Talep filtreleri'");
	Commands.Find(Items.UpdateGeneratedOrdersForm.CommandName).ToolTip = NStr("vi = 'Cập nhật danh sách các giấy đề nghị đã tạo';
																				|ru = 'Обновить список сформированных заявок';
																				|en = 'Refresh the generated request list'; fa = 'Refresh the generated request list';
																				|it = 'Refresh the generated request list';
																				|pl = 'Refresh the generated request list';
																				|tr = 'Oluşturulan talepler listesini güncelle'");
	
	Items.FormulaOrderPointReached1.ToolTip = NStr("vi = '[ Максимальный запас ]
	|- [ К поступлению ]';
	|ru = '[ Максимальный запас ]
	|- [ К поступлению ]';
	|en = '[ Maximum inventory ]
	|- [ To receive ]'; fa = '[ Maximum inventory ]
	|- [ To receive ]';
	|it = '[ Maximum inventory ]
	|- [ To receive ]';
	|pl = '[ Maximum inventory ]
	|- [ To receive ]';
	|tr = '[ Maksimum stok ]
	|- [ Teslim alınacak ]'");
	Items.FormulaOrderPointReached2.ToolTip = NStr("vi = '[ Максимальный запас ]
	|- [ К поступлению ]';
	|ru = '[ Максимальный запас ]
	|- [ К поступлению ]';
	|en = '[ Maximum inventory ]
	|- [ To receive ]'; fa = '[ Maximum inventory ]
	|- [ To receive ]';
	|it = '[ Maximum inventory ]
	|- [ To receive ]';
	|pl = '[ Maximum inventory ]
	|- [ To receive ]';
	|tr = '[ Maksimum stok ]
	|- [ Teslim alınacak ]'");
	Items.FormulaOrderPointReached3.ToolTip = NStr("vi = '[ Максимальный запас ]
	|- [ К поступлению ]
	|- [ Страховой запас ]
	|+ [ Восполнение страхового запаса ]';
	|ru = '[ Максимальный запас ]
	|- [ К поступлению ]
	|- [ Страховой запас ]
	|+ [ Восполнение страхового запаса ]';
	|en = '[ Maximum inventory ]
	|- [ To receive ]
	|- [ Safety stock ]
	|+ [ Safety stock replenishment ]'; fa = '[ Maximum inventory ]
	|- [ To receive ]
	|- [ Safety stock ]
	|+ [ Safety stock replenishment ]';
	|it = '[ Maximum inventory ]
	|- [ To receive ]
	|- [ Safety stock ]
	|+ [ Safety stock replenishment ]';
	|pl = '[ Maximum inventory ]
	|- [ To receive ]
	|- [ Safety stock ]
	|+ [ Safety stock replenishment ]';
	|tr = '[ Maksimum stok ]
	|- [ Teslim alınacak ]
	|- [ Güvenlik stoku ]
	|+ [ Güvenlik stokunun yenilenmesi ]'");
	Items.FormulaOrderPointReached4.ToolTip = NStr("vi = '[ Максимальный запас ]
	|- [ К поступлению ]
	|- [ Страховой запас ]
	|+ [ Восполнение страхового запаса ]';
	|ru = '[ Максимальный запас ]
	|- [ К поступлению ]
	|- [ Страховой запас ]
	|+ [ Восполнение страхового запаса ]';
	|en = '[ Maximum inventory ]
	|- [ To receive ]
	|- [ Safety stock ]
	|+ [ Safety stock replenishment ]'; fa = '[ Maximum inventory ]
	|- [ To receive ]
	|- [ Safety stock ]
	|+ [ Safety stock replenishment ]';
	|it = '[ Maximum inventory ]
	|- [ To receive ]
	|- [ Safety stock ]
	|+ [ Safety stock replenishment ]';
	|pl = '[ Maximum inventory ]
	|- [ To receive ]
	|- [ Safety stock ]
	|+ [ Safety stock replenishment ]';
	|tr = '[ Maksimum stok ]
	|- [ Teslim alınacak ]
	|- [ Güvenlik stoku ]
	|+ [ Güvenlik stokunun yenilenmesi ]'");
	Items.FormulaOrderPointNotReached1.ToolTip = NStr("vi = '[ Максимальный запас ]
	|- [ К поступлению ]
	|- (  [ В наличии ] - [ Минимальный запас ]  )';
	|ru = '[ Максимальный запас ]
	|- [ К поступлению ]
	|- (  [ В наличии ] - [ Минимальный запас ]  )';
	|en = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ In stock ] - [ Minimum inventory ]  )'; fa = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ In stock ] - [ Minimum inventory ]  )';
	|it = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ In stock ] - [ Minimum inventory ]  )';
	|pl = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ In stock ] - [ Minimum inventory ]  )';
	|tr = '[ Maksimum stok ]
	|- [ Teslim alınacak ]
	|- (  [ Stokta ] - [ Minimum stok ]  )'");
	Items.FormulaOrderPointNotReached2.ToolTip = NStr("vi = '[ Максимальный запас ]
	|- [ К поступлению ]
	|- (  [ В наличии ] - [ Минимальный запас ]  )';
	|ru = '[ Максимальный запас ]
	|- [ К поступлению ]
	|- (  [ В наличии ] - [ Минимальный запас ]  )';
	|en = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ In stock ] - [ Minimum inventory ]  )'; fa = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ In stock ] - [ Minimum inventory ]  )';
	|it = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ In stock ] - [ Minimum inventory ]  )';
	|pl = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ In stock ] - [ Minimum inventory ]  )';
	|tr = '[ Maksimum stok ]
	|- [ Teslim alınacak ]
	|- (  [ Stokta ] - [ Minimum stok ]  )'");
	Items.FormulaOrderPointNotReached3.ToolTip = NStr("vi = '[ Максимальный запас ]
	|- [ К поступлению ]
	|- (  [ Остаток ] - [ Минимальный запас ]  )
	|- [ Страховой запас ]';
	|ru = '[ Максимальный запас ]
	|- [ К поступлению ]
	|- (  [ Остаток ] - [ Минимальный запас ]  )
	|- [ Страховой запас ]';
	|en = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ Balance ] - [ Minimum inventory ]  )
	|- [ Safety stock ]'; fa = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ Balance ] - [ Minimum inventory ]  )
	|- [ Safety stock ]';
	|it = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ Balance ] - [ Minimum inventory ]  )
	|- [ Safety stock ]';
	|pl = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ Balance ] - [ Minimum inventory ]  )
	|- [ Safety stock ]';
	|tr = '[ Maksimum stok ]
	|- [ Teslim alınacak ]
	|- (  [ Bakiye ] - [ Minimum stok ]  )
	| - [ Güvenlik stoku ]'");
	Items.FormulaOrderPointNotReached4.ToolTip = NStr("vi = '[ Максимальный запас ]
	|- [ К поступлению ]
	|- (  [ Остаток ] - [ Минимальный запас ]  )
	|- [ Страховой запас ]';
	|ru = '[ Максимальный запас ]
	|- [ К поступлению ]
	|- (  [ Остаток ] - [ Минимальный запас ]  )
	|- [ Страховой запас ]';
	|en = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ Balance ] - [ Minimum inventory ]  )
	|- [ Safety stock ]'; fa = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ Balance ] - [ Minimum inventory ]  )
	|- [ Safety stock ]';
	|it = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ Balance ] - [ Minimum inventory ]  )
	|- [ Safety stock ]';
	|pl = '[ Maximum inventory ]
	|- [ To receive ]
	|- (  [ Balance ] - [ Minimum inventory ]  )
	|- [ Safety stock ]';
	|tr = '[ Maksimum stok ]
	|- [ Teslim alınacak ]
	|- (  [ Bakiye ] - [ Minimum stok ]  )
	| - [ Güvenlik stoku ]'");
	
	Items.StepOrderEditing.Title = NStr("vi = 'Bước điều chỉnh giấy đề nghị';
										|ru = 'Шаг редактирование заявок';
										|en = 'Step request editing'; fa = 'Step request editing';
										|it = 'Step request editing';
										|pl = 'Step request editing';
										|tr = 'Aşama talep düzenleme'");
	Items.StepCreatedOrders.Title = NStr("vi = 'Bước giấy đề nghị đã lập';
										|ru = 'Шаг сформированные заявки';
										|en = 'Step generated requests'; fa = 'Step generated requests';
										|it = 'Step generated requests';
										|pl = 'Step generated requests';
										|tr = 'Aşama talep düzenleme'");
		
	GeneratePurchaseRequests = True;
	Items.SetStatus.Visible = False; // Statuses for purchase requests are not set, the rest are irrelevant.
	
EndProcedure

&AtClient
Procedure OpenManagerSelectionForm(Notification)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ChoiceMode", True);
	
	OpenForm(
		"Catalog.Users.ChoiceForm",
		OpeningParameters,
		ThisObject,
		,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region RoundingQuantity

// Recalculates rounding for all rows corresponding to the Idindex root
//
// Parameters:
//  String	 - FormDataCollection	 - A string containing the ID of the root in the index Search tree that the algorithm uses for branches
//  Inventories	 - Boolean	 - Indicates that the procedure is being called at Step 1.
//  	  
// Returns:
//   Map - processed rows.
&AtClient
Function RecalculateRounding(String, Inventories = False)
	
	If String = Undefined Then

		Return Undefined;
	EndIf;
	
	IndexID = String.IndexID;
	
	RowsMap = PrepareStringMatchesForRoundingClient(IndexID);
	
	Structure = RoundUpMatchingRows(RowsMap, UsePackages);
	
	Return RowsMap;
	
EndFunction

// Recalculates rounding for all rows corresponding to the Idindex root
//
// Parameters:
//  String	 - FormDataCollection	 - A string containing the ID of the root in the index Search tree that the algorithm uses for branches
//  Inventories	 - Boolean	 - Indicates that the procedure is being called at Step 1.
//  	  
// Returns:
//   Map - processed rows.
&AtServer
Function RecalculateRoundingServer(String, Inventories = False)
	
	If String = Undefined Then
		Return Undefined;
	EndIf;
	
	IndexID = String.IndexID;
	
	RowsMap = PrepareStringMatchesForRoundingServer(IndexID);
	
	Structure = RoundUpMatchingRows(RowsMap, UsePackages);
	
	Return RowsMap;
	
EndFunction

&AtClient
Function PrepareStringMatchesForRoundingClient(IndexID)
	
	Root = SearchIndexes.FindByID(IndexID);
	
	RootBranches = Root.GetItems();
	
	// Sorting the result using an additional table to distribute the remainder of the rounding by date.
	SearchIndexesSortingTable.Clear();
	
	For Each Branch In RootBranches Do
		String = ?(Branch.TableInventory, Object.Inventories.FindByID(Branch.LineID),
			Object.OrdersPendingSupply.FindByID(Branch.LineID));
		
		SortingLine = SearchIndexesSortingTable.Add();
		FillPropertyValues(SortingLine, Branch);
		SortingLine.ShipmentDate = String.ShipmentDate;
	EndDo;
	
	SearchIndexesSortingTable.Sort("ShipmentDate");
	
	Map = New Map();
	
	For Each SortingLine In SearchIndexesSortingTable Do
		String = ?(SortingLine.TableInventory, Object.Inventories.FindByID(SortingLine.LineID),
			Object.OrdersPendingSupply.FindByID(SortingLine.LineID));
		
		Map.Insert(String, SortingLine.TableInventory);
	EndDo;
	
	Return Map;
	
EndFunction

&AtServer
Function PrepareStringMatchesForRoundingServer(IndexID)
	
	Root = SearchIndexes.FindByID(IndexID);
	
	RootBranches = Root.GetItems();
	
	// Sorting the result using an additional table to distribute the remainder of the rounding by date.
	SearchIndexesSortingTable.Clear();
	
	For Each Branch In RootBranches Do
		String = ?(Branch.TableInventory, Object.Inventories.FindByID(Branch.LineID),
			Object.OrdersPendingSupply.FindByID(Branch.LineID));
		
		SortingLine = SearchIndexesSortingTable.Add();
		FillPropertyValues(SortingLine, Branch);
		SortingLine.ShipmentDate = String.ShipmentDate;
	EndDo;
	
	SearchIndexesSortingTable.Sort("ShipmentDate");
	
	Map = New Map();
	
	For Each SortingLine In SearchIndexesSortingTable Do
		String = ?(SortingLine.TableInventory, Object.Inventories.FindByID(SortingLine.LineID),
			Object.OrdersPendingSupply.FindByID(SortingLine.LineID));
		
		Map.Insert(String, SortingLine.TableInventory);
	EndDo;
	
	Return Map;
	
EndFunction

&AtClientAtServerNoContext
Function RoundUpMatchingRows(RowsMap, UsePackages)
	
	RoundingRemainder = 0;
	RoundedTotal = 0;
	ToOrderTotal = 0;
	
	ToOrderTotalInventory = 0;
	ToOrderTotalOrders = 0;
	
	RoundedToMinimumBatch = False;
	
	For Each KeyValue In RowsMap Do
		
		String = KeyValue.Key;
		String.DoNotRoundBeforeCreatingOrder = False;
		
		Rounded = 0;
		
		If String <> Undefined Then
			If String.Mark Then
				
				If UsePackages Then
					If RoundingRemainder >= String.ToOrder Then
						RoundingRemainder = RoundingRemainder - String.ToOrder;
						Rounded = 0; // The rest of the rounding is written off completely or partially. This line is fully secured
					Else
						ToOrder = String.ToOrder - RoundingRemainder; // The rest of the rounding is written off in full due to the quantity of the order
						Rounded = RoundOff(ToOrder, ?(String.PackageNumerator = 0 Or String.PackageDenominator = 0, 1, String.PackageNumerator / String.PackageDenominator),
						String.UnitOfMeasureType);
						
						If Not RoundedToMinimumBatch Then
							Repetition = ?(String.PackageNumerator = 0 Or String.PackageDenominator = 0, 1, String.PackageNumerator / String.PackageDenominator);
							MinimumDeliveryLot = String.MinimumDeliveryLot * Repetition;
							Rounded = Max(MinimumDeliveryLot, Rounded);
							RoundedToMinimumBatch = True;
						EndIf;
						
						RoundingRemainder = Rounded - ToOrder;
					EndIf;
				Else
					Rounded = String.ToOrder;
				EndIf;
				
				String.Rounded = Rounded;
				RoundedTotal = RoundedTotal + Rounded;
				
				ToOrderTotal = ToOrderTotal + String.ToOrder;
				
				// If true, the total is accumulated according to the inventory table, otherwise - orders
				If KeyValue.Value Then
					ToOrderTotalInventory = ToOrderTotalInventory + String.ToOrder;
				Else
					ToOrderTotalOrders = ToOrderTotalOrders + String.ToOrder;
				EndIf;
				
			EndIf;
			
		EndIf;
	EndDo;
	
	Structure = New Structure();
	Structure.Insert("RoundedTotal", 	RoundedTotal);
	Structure.Insert("ToOrderTotal", 		ToOrderTotal);
	Structure.Insert("ToOrderTotalInventory", ToOrderTotalInventory);
	Structure.Insert("ToOrderTotalOrders", ToOrderTotalOrders);
	
	Return Structure;
	
EndFunction

&AtClientAtServerNoContext
Function RoundOff(Count, Repetition, UnitOfMeasureType)
	
	If Repetition <> 1
		Or UnitOfMeasureType = PredefinedValue("Enum.TypesOfMeasuredValues.NumberOfPieces") Then
		If Count % Repetition <> 0 Then
			Balance = Int(Count / Repetition) + 1;
			Return Balance * Repetition;
		Else
			Return Count;
		EndIf;
	Else 
		Return Count;
	EndIf;
	
EndFunction

&AtClient
Procedure DisplayCalculatedRounding(String, Inventories)
	
	If String = Undefined Then
		Totals = InformationLineParameters();
		GenerateInformationLine(Undefined, Totals, Inventories);
		Return;
	EndIf;
	
	IndexID = String.IndexID;
	
	Root = SearchIndexes.FindByID(IndexID);
	RootBranches = Root.GetItems();
	
	RoundedTotal = 0;
	ToOrderTotal = 0;
	
	ToOrderTotalInventory = 0;
	ToOrderTotalOrders = 0;
	
	AmountTotal = 0;
	ThereIsLineWithEmptyPrice = False;
	
	For Each Branch In RootBranches Do
		Rounded = 0;
		TreeLine = ?(Branch.TableInventory, Object.Inventories.FindByID(Branch.LineID), 
		Object.OrdersPendingSupply.FindByID(Branch.LineID));
		
		If TreeLine <> Undefined Then
			If TreeLine.Mark Then
				
				Rounded = TreeLine.Rounded;
				RoundedTotal = RoundedTotal + Rounded;
				ToOrderTotal = ToOrderTotal + TreeLine.ToOrder;
				AmountTotal = AmountTotal + (Rounded * TreeLine.PriceInTheCurrencyOfManagementAccounting);
				
				If TreeLine.PriceInTheCurrencyOfManagementAccounting = 0 Then
					
					ThereIsLineWithEmptyPrice = True;
					
				EndIf;
				
				If Branch.TableInventory Then
					ToOrderTotalInventory = ToOrderTotalInventory + TreeLine.ToOrder;
				Else
					ToOrderTotalOrders = ToOrderTotalOrders + TreeLine.ToOrder;
				EndIf;
				
			EndIf;
			
		EndIf;
	EndDo;
	
	Totals = InformationLineParameters();
	Totals.RoundedTotal = 			RoundedTotal;
	Totals.ToOrderTotal = 			ToOrderTotal;
	Totals.ToOrderTotalInventory = 		ToOrderTotalInventory;
	Totals.ToOrderTotalOrders = 		ToOrderTotalOrders;
	Totals.AmountTotal = 				AmountTotal;
	Totals.ThereIsLineWithEmptyPrice = 	ThereIsLineWithEmptyPrice;
	
	GenerateInformationLine(String, Totals, Inventories);
	
EndProcedure

// Updates the information Line form details
//
// Parameters:
//  String				 - FormDataCollection - data source for generating the information string
//  Totals	 - Structure - contains the following data:
//  	Roundeditog			 - Number - the final value for rounding
//  	To order				 - Number - total value by quantity to order
//  	To order Stocks		 - Number - total value by quantity to order table Stocks
//  	KZakazuItogZakazy		 - Number - total value by quantity to order table Orders
//  	Sumitog				 - Number - the total value of the sum
//  	There is a line with a price	 - Boolean - a sign that the amount has been calculated approximately, because the price is not specified for all lines
//  Inventories				 - Boolean - Indicates that the procedure is being called at Step 1.
&AtClient
Procedure GenerateInformationLine(String, Totals, Inventories)

	RoundedTotal = 			Totals.RoundedTotal;
	ToOrderTotal = 				Totals.ToOrderTotal;
	ToOrderTotalInventory = 		Totals.ToOrderTotalInventory;
	ToOrderTotalOrders = 		Totals.ToOrderTotalOrders;
	AmountTotal = 				Totals.AmountTotal;
	ThereIsLineWithEmptyPrice = 	Totals.ThereIsLineWithEmptyPrice;
	
	Font = Items.InformationBar.Font;
	FontBold = New Font(Font, , , True);
	FontItalics = New Font(Font, , , , True);
	
	InformationStringArray = New Array();
	
	If String = Undefined Then
		InformationStringArray.Add(NStr("vi = 'Không có hàng nào được chọn';
										|ru = 'Строка не выбрана';
										|en = 'Line is not selected'; fa = 'Line is not selected';
										|it = 'Nessuna riga selezionata';
										|pl = 'Nie wybrano wiersza';
										|tr = 'Satır seçilmedi'"));
	Else
	
		InformationStringArray.Add(New FormattedString(String(String.Products), , , ,
			GetURL(String.Products)));
		
		If Not String.Characteristic.IsEmpty() Then
			
			InformationStringArray.Add(New FormattedString(", "));
			
			InformationStringArray.Add(New FormattedString(String(String.Characteristic), , , ,
				GetURL(String.Characteristic)));
				
		EndIf;
			
		If Not String.Warehouse.IsEmpty()
			And UseSeveralWarehouses Then
			
			InformationStringArray.Add(New FormattedString(", "));
			
			InformationStringArray.Add(New FormattedString(String(String.Warehouse), , , ,
				GetURL(String.Warehouse)));
		
		EndIf;
		InformationStringArray.Add(New FormattedString(": "));
		
		If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
			
			If Inventories Then
				InformationStringArray.Add(New FormattedString(NStr("vi = 'Vào giấy đề nghị theo tồn kho:';
																	|ru = 'В заявку по запасам:';
																	|en = 'To request by inventory:'; fa = 'To request by inventory:';
																	|it = 'To request by inventory:';
																	|pl = 'To request by inventory:';
																	|tr = 'Stoklara göre talebe ekle:'")));
			Else
				InformationStringArray.Add(New FormattedString(NStr("vi = 'Tổng cộng vào giấy đề nghị:';
																	|ru = 'Всего в заявку:';
																	|en = 'Total to request:'; fa = 'Total to request:';
																	|it = 'Total to request:';
																	|pl = 'Total to request:';
																	|tr = 'Тalebe eklenecek toplam'")));
			EndIf;
			
		Else
			
			If Inventories Then
				InformationStringArray.Add(New FormattedString(NStr("vi = 'Để hàng tồn kho đặt hàng:';
																	|ru = 'К заказу по запасам:';
																	|en = 'To order according to inventory:'; fa = 'To order according to inventory:';
																	|it = 'Ordinare per le scorte:';
																	|pl = 'Aby zamówić według stanu magazynowego:';
																	|tr = 'Stoklara göre siparişe ekle:'")));
			Else
				InformationStringArray.Add(New FormattedString(NStr("vi = 'Tổng số để đặt hàng:';
																	|ru = 'Всего к заказу:';
																	|en = 'Total to order:'; fa = 'Total to order:';
																	|it = 'Totale da ordinare:';
																	|pl = 'Razem na zamówienie:';
																	|tr = 'Toplam siparişe:'")));
			EndIf;
			
		EndIf;
		
		InformationStringArray.Add(New FormattedString(" "));
		InformationStringArray.Add(New FormattedString(String(ToOrderTotal) + " ", FontBold));
		InformationStringArray.Add(New FormattedString(String(String.UnitOfMeasure), FontBold));
		
		If Not Inventories And RoundedTotal > 0 Then
			
			InformationStringArray.Add(New FormattedString(" "));
			
			InformationStringArray.Add(New FormattedString(NStr("vi = '(theo hàng tồn kho:';
																|ru = '(по запасам:';
																|en = '(by inventory:'; fa = '(by inventory:';
																|it = '(per le scorte:';
																|pl = '(wg stanu magazynowego:';
																|tr = '(stoklara göre:'")));
			InformationStringArray.Add(New FormattedString(" "));
			InformationStringArray.Add(New FormattedString(String(ToOrderTotalInventory), FontBold));
			InformationStringArray.Add(New FormattedString(", "));
			
			InformationStringArray.Add(New FormattedString(NStr("vi = 'theo đơn đặt hàng:';
																|ru = 'по заказам:';
																|en = 'by orders:'; fa = 'by orders:';
																|it = 'per gli ordini:';
																|pl = 'według zamówień:';
																|tr = 'siparişlere göre:'")));
			InformationStringArray.Add(New FormattedString(" "));
			InformationStringArray.Add(New FormattedString(String(ToOrderTotalOrders), FontBold));
			InformationStringArray.Add(New FormattedString("), "));
			
		Else
			
			InformationStringArray.Add(New FormattedString(", "));
			
		EndIf;
		
		If RoundedTotal > 0 And UsePackages Then
			
			LinkPackaging = "OpenPackageSelectionForm";
			
			// Output of packaging information.
			If String.OrderPackage.IsEmpty() Then
				If String.UsePackages 
					And HasAccessToPackageChange Then
					Package = NStr("vi = '<chỉ định bao bì để làm tròn>';
									|ru = '<задать упаковку для округления>';
									|en = '<set a packaging unit for rounding>'; fa = '<set a packaging unit for rounding>';
									|it = '<impostare imballaggio per l''arrotondamento>';
									|pl = '<ustaw opakowanie do zaokrąglenia>';
									|tr = '<yuvarlama için paketleme ünitesini ayarla>'");
					If RoundedTotal <> ToOrderTotal Then
						InformationStringArray.Add(New FormattedString(NStr("vi = 'Làm tròn đến:';
																			|ru = 'Округлено до:';
																			|en = 'Rounded to:'; fa = 'Rounded to:';
																			|it = 'Arrotondato a:';
																			|pl = 'Zaokrąglone do:';
																			|tr = 'Yuvarlandı:'")));
						InformationStringArray.Add(New FormattedString(" "));
						InformationStringArray.Add(New FormattedString(String(RoundedTotal) + " ", FontBold));
					EndIf;
					InformationStringArray.Add(New FormattedString(Package + " ", FontItalics, , , LinkPackaging));
				EndIf;
			ElsIf RoundedTotal > 0 And String.OrderPackage.IsEmpty() Then
				InformationStringArray.Add(New FormattedString(NStr("vi = 'Làm tròn đến:';
																	|ru = 'Округлено до:';
																	|en = 'Rounded to:'; fa = 'Rounded to:';
																	|it = 'Arrotondato a:';
																	|pl = 'Zaokrąglone do:';
																	|tr = 'Yuvarlandı:'")));
				InformationStringArray.Add(New FormattedString(" "));
				InformationStringArray.Add(New FormattedString(String(RoundedTotal) + " ", FontBold));
				InformationStringArray.Add(New FormattedString(String(String.UnitOfMeasure) + ", ", FontBold));
				InformationStringArray.Add(New FormattedString(" "));
			Else
				InformationStringArray.Add(New FormattedString(NStr("vi = 'Làm tròn đến:';
																	|ru = 'Округлено до:';
																	|en = 'Rounded to:'; fa = 'Rounded to:';
																	|it = 'Arrotondato a:';
																	|pl = 'Zaokrąglone do:';
																	|tr = 'Yuvarlandı:'")));
				InformationStringArray.Add(New FormattedString(" "));
				InformationStringArray.Add(New FormattedString(String(RoundedTotal) + " ", FontBold));
				InformationStringArray.Add(New FormattedString(String(String.UnitOfMeasure) + ", ", FontBold));
				InformationStringArray.Add(New FormattedString(NStr("vi = '(Đóng gói:';
																	|ru = '(Упаковка:';
																	|en = '(Packaging unit:'; fa = '(Packaging unit:';
																	|it = '(Imballaggio:';
																	|pl = '(Packaging unit:';
																	|tr = '(Paketleme ünitesi:'"), FontItalics));
				InformationStringArray.Add(New FormattedString(" "));
				
				Package = String(String.OrderPackage);
				InformationStringArray.Add(New FormattedString(Package, FontItalics, , , LinkPackaging));
				InformationStringArray.Add(New FormattedString("), ", FontItalics));
			EndIf;
		EndIf;
		
		SignIsApproximatelyEqualTo = ?(ThereIsLineWithEmptyPrice, "~", "");
		
		InformationStringArray.Add(New FormattedString(NStr("vi = 'Số tiền:';
															|ru = 'На сумму:';
															|en = 'Amount:'; fa = 'مبلغ:';
															|it = 'Per importo:';
															|pl = 'Na ilość:';
															|tr = 'Tutar:'")));
		InformationStringArray.Add(New FormattedString(" "));
		InformationStringArray.Add(New FormattedString(SignIsApproximatelyEqualTo, FontBold));
		InformationStringArray.Add(New FormattedString(String(AmountTotal), FontBold));
		InformationStringArray.Add(New FormattedString(" " + ManagementAccountingCurrency, FontBold));
		
	EndIf;
		
	InformationBar = New FormattedString(InformationStringArray);

EndProcedure

&AtClient
Function InformationLineParameters()
	
	ReturnStructure = New Structure();
	ReturnStructure.Insert("RoundedTotal", 0);
	ReturnStructure.Insert("ToOrderTotal", 0);
	ReturnStructure.Insert("ToOrderTotalInventory", 0);
	ReturnStructure.Insert("ToOrderTotalOrders", 0);
	ReturnStructure.Insert("AmountTotal", 0);
	ReturnStructure.Insert("ThereIsLineWithEmptyPrice", False);
	
	Return ReturnStructure;
	
EndFunction

// Indexes the table defined by the Inventory parameter
// Duplicate rows for the Item, Characteristic, and Warehouse key are collapsed
// into a single root element of the index Search tree.
//
// Parameters:
//  Inventories	 - Boolean - Indicates that the procedure is being called at Step 1.
&AtServer
Procedure FillIndexTree(Inventories)
	
	Query = New Query();
	Query.SetParameter("TableInventory", UploadProductsWithRowIDs(Object.Inventories)); 
	Query.SetParameter("OrdersTable", UploadProductsWithRowIDs(Object.OrdersPendingSupply));
	Query.Text =
		"SELECT
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse          AS Warehouse,
		|	Table.ShipmentDate   AS ShipmentDate,
		|	Table.IndexOf         AS IndexOf
		|INTO TTInventoryTable
		|FROM
		|	&TableInventory AS Table
		|;
		|
		|SELECT
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse          AS Warehouse,
		|	Table.ShipmentDate   AS ShipmentDate,
		|	Table.IndexOf         AS IndexOf
		|INTO TTTableOrders
		|FROM
		|	&OrdersTable AS Table
		|;
		|
		|SELECT
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse          AS Warehouse,
		|	Table.IndexOf         AS IndexOf,
		|	Table.ShipmentDate   AS ShipmentDate,
		|	TRUE                 AS TheseAreStocks
		|FROM
		|	TTInventoryTable AS Table
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse          AS Warehouse,
		|	Table.IndexOf         AS IndexOf,
		|	Table.ShipmentDate   AS ShipmentDate,
		|	FALSE                   AS TheseAreStocks
		|FROM
		|	TTTableOrders AS Table
		|
		|ORDER BY
		|	Products, Characteristic, Warehouse, ShipmentDate";
		
	Selection = Query.Execute().Select();
	
	Collection = SearchIndexes.GetItems();
	Collection.Clear();
	
	Var_Key = New Structure("Products, Characteristic, Warehouse");
	While Selection.Next() Do
		
		If Var_Key.Products <> Selection.Products Or Var_Key.Characteristic <> Selection.Characteristic Or Var_Key.Warehouse <> Selection.Warehouse Then
			
			FillPropertyValues(Var_Key, Selection);
			Root = Collection.Add();
			Rows = Root.GetItems();
			
		EndIf;
		
		FormTable = ?(Selection.TheseAreStocks, Object.Inventories, Object.OrdersPendingSupply);
		
		NewRow = Rows.Add();
		NewRow.LineID      = FormTable[Selection.IndexOf].GetID(); 
		NewRow.TableInventory = Selection.TheseAreStocks; 
		
		FormTable[Selection.IndexOf].IndexID = Root.GetID();
		
	EndDo;
		
EndProcedure

&AtServer
Function UploadProductsWithRowIDs(FormTable)
	
	ExportedTable = New ValueTable();
	ExportedTable.Columns.Add("Products",   New TypeDescription("CatalogRef.Products"));
	ExportedTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	ExportedTable.Columns.Add("Warehouse",          New TypeDescription("CatalogRef.Warehouses"));
	ExportedTable.Columns.Add("ShipmentDate",   New TypeDescription("Date"));
	ExportedTable.Columns.Add("IndexOf",         New TypeDescription("Number"));
	
	TotalRows = FormTable.Count() - 1;
	For IndexOf = 0 To TotalRows Do
		
		TableRow = FormTable[IndexOf];
		UnloadedString = ExportedTable.Add();
		FillPropertyValues(UnloadedString, TableRow);
		UnloadedString.IndexOf = IndexOf;
		
	EndDo;
	Return ExportedTable;
	
EndFunction

&AtClient
Procedure SelectPackagingClient(TableName)

	Shipment = Items[TableName].CurrentData;

	UnitsOfMeasurement = New Array();
	UnitsOfMeasurement.Add(Shipment.UnitOfMeasure);
	
	ParametersOfSelectionForm = New Structure("Owner", Shipment.Products);
	FormParameters = New Structure("Filter", ParametersOfSelectionForm);
	FormParameters.Insert("UnitsOfMeasurement", UnitsOfMeasurement);
	
	OpenForm("DataProcessor.DemandFulfillment.Form.SelectionFormOfPackageUnit", FormParameters, ThisForm, UUID);
	
EndProcedure

// Distributes packing changes across the Inventory and Order tables
// Writes the packaging change to the database.
//
// Parameters:
//  IndexID		 - Number - ID of the root in the index Search tree that the algorithm uses for branches
//  Package		 - CatalogRef.PackagesAndUnitsOfMeasure - new packaging value.
//  ThisIsPackagingUnitOfSupplier - Boolean - This is the packaging unit of the supplier, filled only if it is not empty and does not lead
//                                   to a change in the logistics packaging unit (packaging unit of product restrictions).
&AtServer
Procedure FillWritePackingOnIndexTree(IndexID, Package, ThisIsPackagingUnitOfSupplier = False)
	
	If Package = Undefined Then
		Return;
	EndIf;
	
	If ThisIsPackagingUnitOfSupplier And Not ValueIsFilled(Package) Then
		Return;
	EndIf;
	
	NumeratorAndDenominatorPacking = New Structure("Numerator, Denominator", 1, 1);
	
	// Choosing a unit of measurement means a command to purify
	If Package.MeasuredValueType = Enums.TypesOfMeasuredValues.Package Then
		NumeratorAndDenominatorPacking = Common.ObjectAttributesValues(Package, "Numerator, Denominator");
	Else
		Package = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	EndIf;
	
	Root = SearchIndexes.FindByID(IndexID);
	
	// Traversing all the corresponding rows in both tables, with the replacement of packaging and coefficient.
	Collection = Root.GetItems();
	String = Undefined;
	
	If Collection.Count() > 0 Then
		String = ?(Collection[0].TableInventory, Object.Inventories.FindByID(Collection[0].LineID),
			Object.OrdersPendingSupply.FindByID(Collection[0].LineID));
	EndIf;
	
	If String <> Undefined Then
		
		If Not ThisIsPackagingUnitOfSupplier Then
			// Recording changes in the register of information of commodity restrictions
			InformationRegisters.ProductRestrictions.SetProductPackaging(String.Products, String.Characteristic,
				String.Warehouse, Package);
		EndIf;
		
		For Each Branch In Collection Do
			
			String = ?(Branch.TableInventory, Object.Inventories.FindByID(Branch.LineID),
				Object.OrdersPendingSupply.FindByID(Branch.LineID));
			
			String.OrderPackage = Package;
			String.PackageNumerator = NumeratorAndDenominatorPacking.Numerator;
			String.PackageDenominator = NumeratorAndDenominatorPacking.Denominator;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Clears the search Index tree completely, or only records that refer to the order table.
//
// Parameters:
//  Inventories	 - Boolean - Indicates that the procedure is being called at Step 1.
&AtClient
Procedure ClearIndexTree(Inventories)
	
	Roots = SearchIndexes.GetItems();
	
	// The Inventory table is the first. Clearing it with the Back button is equivalent to completely clearing the table.
	If Inventories Then
		Roots.Clear();
	EndIf;
	
	Count = Roots.Count() - 1;
	For N1 = 0 To Count Do
		
		RootIndex = Count - N1;
		Root = Roots[RootIndex];
		
		Branches = Root.GetItems();
		NumberOfBranches = Branches.Count() - 1;
		
		// Deleting branches associated with the Support Order table
		For M = 0 To NumberOfBranches Do
			
			BranchIndex = NumberOfBranches - M;
			Branch = Branches[BranchIndex];
			If Branch.TableInventory = False Then
				Branches.Delete(BranchIndex);
			EndIf;
			
		EndDo;
		
		// If all branches are removed from the root, the root is removed
		If Root.GetItems().Count() = 0 Then
			Roots.Delete(RootIndex);
		EndIf;
		
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
	If Item.Name = "sh_ShamsiInput_F_FilterToOrderNoLaterThanInventory" Then
		FilterToOrderNoLaterThanInventoryOnChange(Items.FilterToOrderNoLaterThanInventory);
	ElsIf Item.Name = "sh_ShamsiInput_F_FilterToShipNotEarlier" Then
		FilterToShipNotEarlierOnChange(Items.FilterToShipNotEarlier);
	ElsIf Item.Name = "sh_ShamsiInput_F_FilterForShipmentNoLaterThan" Then
		FilterForShipmentNoLaterThanOnChange(Items.FilterForShipmentNoLaterThan);
	ElsIf Item.Name = "sh_ShamsiInput_F_FilterToOrderNoLaterThanOrders" Then
		FilterToOrderNoLaterThanOrdersOnChange(Items.FilterToOrderNoLaterThanOrders);
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
