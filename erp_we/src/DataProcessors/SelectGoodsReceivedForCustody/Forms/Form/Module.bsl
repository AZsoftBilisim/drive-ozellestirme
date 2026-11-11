
#Region Variables

&AtClient
Var ClosingInProgress Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Parameters.Owner) Then
		Raise NStr("vi = 'Chỉ có thể mở bộ xử lý từ chứng từ.';
					|ru = 'Предусмотрено открытие обработки только из документов.';
					|en = 'Data processor can be opened only from documents.'; fa = 'Data processor can be opened only from documents.';
					|it = 'Viene fornita l''apertura dell''elaborazione solo dalle forme dei documenti';
					|pl = 'Przewidziano otwarcie przetwarzania tylko z dokumentów.';
					|tr = 'Yalnızca belgelerden işlem açmak için provizyon sağlanmıştır.'");
	EndIf;
	
	Object.Owner       = Parameters.Owner;
	Object.Organization    = Parameters.Organization;
	Object.Warehouse          = Parameters.Warehouse;
	Object.Contract        = Parameters.Contract;
	Object.InventoryType     = Parameters.InventoryType;
	BusinessOperation = Parameters.BusinessOperation;
	OrderDocument                 = Parameters.OrderDocument;
	
	Parameters.Property("Ref", Ref);
	Parameters.Property("AddressOfGoodsInvoiceInVault", AddressOfGoodsInvoiceInVault);
	
	If ValueIsFilled(Parameters.Title) Then
		AutoTitle = False;
		Title     = Parameters.Title;
	EndIf;
	
	FillInSelectionListForBalances();
	FillWarehousesAdjustVisibility();
	FillInProductsTable_();
	
	CreateInformationLabelSelections();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit
		And Modified Then
		
		Cancel = True;
		WarningText = NStr("vi = 'Dữ liệu đã thay đổi. Tất cả thay đổi sẽ bị mất.';
							|ru = 'Данные были изменены. Все изменения будут потеряны.';
							|en = 'All changes made to the data will be lost.'; fa = 'All changes made to the data will be lost.';
							|it = 'I dati sono stati modificati. Tutte le modifiche verranno perse.';
							|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
							|tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'");
		
		Return;
		
	EndIf;
	
	If MoveToDocument
		Or ClosingInProgress
		Or Not GoodsAreSelected Then
		
		Return;
		
	Else
		Cancel = True;
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		QueryText = NStr("vi = 'Hàng hóa đã chọn chưa được chuyển vào chứng từ. Chuyển?';
						|ru = 'Подобранные товары не перенесены в документ. Перенести?';
						|en = 'Picked items are not added to the document. Do you want to add them?'; fa = 'Picked items are not added to the document. Do you want to add them?';
						|it = 'La merce selezionata non è stata trasferita nel documento. Trasferire?';
						|pl = 'Wybrane wiersze pozycji nie zostały przeniesione do dokumentu. Przenieść?';
						|tr = 'Seçili ürünler belgeye aktarılmadı. Aktarılsın mı?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	ElsIf QuestionResult = DialogReturnCode.Yes Then
		
		If AllowResultsToBeTransferredToDocument() Then
			MoveToDocument  = True;
			ClosingInProgress = True;
			
			Close();
		EndIf;
		
		Return;
		
	EndIf;
	
	ClosingInProgress = True;
	
	Close();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	SaveFormSettingsOnServer();
	
	If MoveToDocument Then
		Structure = New Structure("GoodsAddressInStorage", GoodsAddressInStorage());
		NotifyChoice(Structure);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BalanceModeOnChange(Item)
	
	BalanceModeWhenChangingOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsCheckOnChange(Item)
	
	Modified = True;
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData.Check Then
		CurrentData.QuantityIsSelected = CurrentData.CountBalance;
	Else
		CurrentData.QuantityIsSelected = CurrentData.QuantityInInvoice;
	EndIf;
	
	CalculateNumberInRow(Object.Goods, CurrentData, GoodsAreSelected);
	
EndProcedure

&AtClient
Procedure GoodsQuantityIsSelectedOnChange(Item)
	
	Modified = True;
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentData.Check = CurrentData.QuantityIsSelected > 0;
	
	CalculateNumberInRow(Object.Goods, CurrentData, GoodsAreSelected);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	ClearMessages();
	
	If AllowResultsToBeTransferredToDocument() Then
		MoveToDocument = True;
		
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	MarkEverythingOnServer();
	
EndProcedure

&AtClient
Procedure ClearMark(Command)
	
	UncheckServer();
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Setting the conditional design for the 'Quantity Selected' element of the 'Products' tabular part.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQuantityIsSelected.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Check");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Fully selected lines are highlighted in gray
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.QuantityInInvoice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.Goods.CountBalance");

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.LeftToSelect");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
	// The changed lines are highlighted in gray
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQuantityIsSelected.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.QuantityInInvoice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Object.Goods.QuantityIsSelected");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
EndProcedure

&AtServer
Procedure FillInSelectionListForBalances()
	
	ResidueModes = New ValueList;
	
	If BusinessOperation = Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale Then
		
		ResidueModes.Add("AllReceived", NStr("vi = 'Tất cả được chấp nhận';
											|ru = 'Все принятые';
											|en = 'All received'; fa = 'همه دریافت‌شده';
											|it = 'Tutte incluse';
											|pl = 'Wszystkie przyjęte';
											|tr = 'Tüm kabul edilenler'"));
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.WriteOffOfAcceptedGoodsAtExpenseOfDepositor
		Or BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses Then
		
		ResidueModes.Add("ToWriteOff", NStr("vi = 'Cần ghi giảm';
											|ru = 'К списанию';
											|en = 'To write off'; fa = 'برای برداشت';
											|it = 'Da stornare';
											|pl = 'Do rozchodu';
											|tr = 'Gider yazılacak'"));
	ElsIf BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
		Or BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
	
		ResidueModes.Add("ToWriteOff", NStr("vi = 'Cần ghi giảm';
											|ru = 'К списанию';
											|en = 'To write off'; fa = 'برای برداشت';
											|it = 'Da stornare';
											|pl = 'Do rozchodu';
											|tr = 'Gider yazılacak'"));
	
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
		  Or BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5
		  Or BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		  Or BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		  Or BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		  Or BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		  Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5
		  Or BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
		
		ResidueModes.Add("AllReceived", NStr("vi = 'Tất cả được chấp nhận';
											|ru = 'Все принятые';
											|en = 'All received'; fa = 'همه دریافت‌شده';
											|it = 'Tutte incluse';
											|pl = 'Wszystkie przyjęte';
											|tr = 'Tüm kabul edilenler'"));
	Else
		
		ResidueModes.Add("AllReceived", NStr("vi = 'Tất cả được chấp nhận';
											|ru = 'Все принятые';
											|en = 'All received'; fa = 'همه دریافت‌شده';
											|it = 'Tutte incluse';
											|pl = 'Wszystkie przyjęte';
											|tr = 'Tüm kabul edilenler'"));
		ResidueModes.Add("Retired", NStr("vi = 'Xuất';
										|ru = 'Выбывшие';
										|en = 'Disposed'; fa = 'واگذارشده';
										|it = 'Spediti';
										|pl = 'Wyprowadzone';
										|tr = 'Ayrılanlar'"));
		
	EndIf;
	
	Items.BalanceMode.ChoiceList.Clear();
	
	For Each Mode In ResidueModes Do
		Items.BalanceMode.ChoiceList.Add(Mode.Value, Mode.Presentation);
	EndDo;
	
	If ResidueModes.Count() = 1 Then
		Items.BalanceMode.Visible = False;
		Object.BalanceMode = ResidueModes.Get(0).Value;
	Else
		UploadFormSettingsToServer(ResidueModes);
	EndIf;
	
	CustomizeForm();
	
EndProcedure

&AtServer
Procedure UploadFormSettingsToServer(ResidueModes)
	
	ObjectKey             = "Processing_SelectionOfGoodsAcceptedForResponsibleStorage";
	SettingResidueMode = Common.CommonSettingsStorageLoad(ObjectKey, "");
	
	If SettingResidueMode = Undefined Then
		Object.BalanceMode = ResidueModes.Get(0).Value;
	Else
		
		ModeValue = ResidueModes.FindByValue(SettingResidueMode);
		
		If ModeValue <> Undefined Then
			Object.BalanceMode = ModeValue.Value;
		Else
			Object.BalanceMode = ResidueModes.Get(0).Value;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomizeForm()
	
	ColumnVisibilityStorageLocation = GetFunctionalOption("UseSeveralWarehouses")
									Or GetFunctionalOption("UseProduction")
									Or GetFunctionalOption("UseTollManufacturing2_5")
									Or GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
	
	ColumnTitleStorageLocation = NStr("vi = 'Nơi cất giữ';
										|ru = 'Место хранения';
										|en = 'Storage location'; fa = 'محل نگهداری';
										|it = 'Luogo di stoccaggio';
										|pl = 'Miejsce przechowywania';
										|tr = 'Saklama yeri'");
	ColumnTitleBalance       = NStr("vi = 'Số dư';
									|ru = 'Остаток';
									|en = 'Remaining stock'; fa = 'موجودی باقیمانده';
									|it = 'Rimanenze';
									|pl = 'Ostatek';
									|tr = 'Bakiye'");
	
	If Object.BalanceMode = "AllReceived" Then
		
		ColumnTitleBalance       = NStr("vi = 'Tổng số được chấp nhận';
										|ru = 'Всего принято';
										|en = 'Total received'; fa = 'کل دریافتی';
										|it = 'In totale accettato';
										|pl = 'Odebrano ogółem';
										|tr = 'Toplam kabul edildi'");
		
		If BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsFromStorage Then
			ColumnVisibilityStorageLocation = GetFunctionalOption("UseSeveralWarehouses");
		ElsIf BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
			ColumnVisibilityStorageLocation = GetFunctionalOption("UseSeveralWarehouses");
		Else
			ColumnVisibilityStorageLocation = Warehouses.Count() > 1;
			ColumnTitleStorageLocation = NStr("vi = 'Kho bãi';
												|ru = 'Склад';
												|en = 'Warehouse'; fa = 'Warehouse';
												|it = 'Magazzino';
												|pl = 'Magazyn';
												|tr = 'Ambar'");
		EndIf;
		If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToMaterialProvider2_5")
			Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReportToMaterialProvider2_5")
			Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.Subcontracting2_5")
			Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5")
			Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5")
			Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5") Then
			ColumnTitleBalance = NStr("vi = 'Tổng số đã sản xuất';
										|ru = 'Всего произведено';
										|en = 'Total produced'; fa = 'Total produced';
										|it = 'Total produced';
										|pl = 'Total produced';
										|tr = 'Toplam üretilen'");
		EndIf;
	ElsIf Object.BalanceMode = "Retired" Then
		ColumnTitleBalance = NStr("vi = 'Xuất';
									|ru = 'Выбыло';
									|en = 'Disposed'; fa = 'واگذارشده';
									|it = 'Venduti';
									|pl = 'Odpadły';
									|tr = 'Ayrıldı'");
	ElsIf Object.BalanceMode = "ToWriteOff" Then
		ColumnTitleBalance = NStr("vi = 'Cần ghi giảm';
									|ru = 'К списанию';
									|en = 'To write off'; fa = 'برای برداشت';
									|it = 'Da stornare';
									|pl = 'Do rozchodu';
									|tr = 'Gider yazılacak'");
	EndIf;
	
	Items.ProductsGroupStorageLocation.Visible = ColumnVisibilityStorageLocation;
	
	Items.GoodsStorageLocation.Title     = ColumnTitleStorageLocation;
	Items.GoodsCountBalance.Title = ColumnTitleBalance;
	
EndProcedure

&AtServer
Procedure FillWarehousesAdjustVisibility()
	
	If TypeOf(Object.Warehouse) = Type("CatalogRef.Warehouses")
		And Catalogs.Warehouses.IsFolder(Object.Warehouse) Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	Warehouses.Ref AS Warehouse
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Ref IN HIERARCHY(&Warehouse)
		|	AND NOT Warehouses.IsFolder
		|	AND NOT Warehouses.DeletionMark";
		
		Query.SetParameter("Warehouse", Object.Warehouse);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		
		While Selection.Next() Do
			Warehouses.Add(Selection.Warehouse);
		EndDo;
		
	ElsIf ValueIsFilled(Object.Warehouse) Then
		Warehouses.Add(Object.Warehouse);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInProductsTable_(ToCacheData = True)
	
	UpdateSelectedProducts(ToCacheData);
	
	If Object.BalanceMode = "AllReceived" Then
		
		// The option of selecting goods in the documents "Purchase of goods accepted for storage", "Shipment of goods from storage".
		If Not AccessRight("Read", Metadata.AccumulationRegisters.CompanyGoods) Then
			
			Object.Goods.Clear();
			Return;
			
		Else
			
			QueryText =
			"SELECT
			|	InvoiceGoods.LineNumber AS LineNumber,
			|	InvoiceGoods.Products AS Products,
			|	InvoiceGoods.Characteristic AS Characteristic,
			|	InvoiceGoods.Series AS Series,
			|	InvoiceGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	InvoiceGoods.Purpose AS Purpose,
			|	InvoiceGoods.StorageLocation AS StorageLocation,
			|	InvoiceGoods.Count AS Count
			|INTO TTGoodsWaybill
			|FROM
			|	&Goods AS InvoiceGoods
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	MIN(TTGoodsWaybill.LineNumber) AS LineNumber,
			|	TTGoodsWaybill.Products AS Products,
			|	TTGoodsWaybill.Characteristic AS Characteristic,
			|	CASE
			|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
			|			AND NOT TTSeriesAccountingPolicies.UseCostAccountingByBatches
			|			AND TTSeriesAccountingPolicies.SpecifyWhenPlanningShipment
			|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
			|		ELSE TTGoodsWaybill.Series
			|	END AS Series,
			|	CASE
			|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
			|			AND NOT TTSeriesAccountingPolicies.UseCostAccountingByBatches
			|			AND TTSeriesAccountingPolicies.SpecifyWhenPlanningShipment
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS DifferentSeriesAccounting,
			|	TTGoodsWaybill.Purpose AS Purpose,
			|	TTGoodsWaybill.StorageLocation AS StorageLocation,
			|	SUM(TTGoodsWaybill.Count) AS Count
			|INTO InvoiceGoods
			|FROM
			|	TTGoodsWaybill AS TTGoodsWaybill
			|		
			|		LEFT JOIN Catalog.Products AS TT_Products
			|		ON TTGoodsWaybill.Products = TT_Products.Ref
			|		
			|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
			|		ON TT_Products.ProductKind = BatchAccountingPolicies.Ref
			|			AND TTGoodsWaybill.StorageLocation = BatchAccountingPolicies.Warehouse
			|		
			|		LEFT JOIN Catalog.BatchAccountingPolicies AS TTSeriesAccountingPolicies
			|		ON BatchAccountingPolicies.BatchAccountingPolicy = TTSeriesAccountingPolicies.Ref
			|		
			|GROUP BY
			|	TTGoodsWaybill.Products,
			|	TTGoodsWaybill.Characteristic,
			|	CASE
			|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
			|			AND NOT TTSeriesAccountingPolicies.UseCostAccountingByBatches
			|			AND TTSeriesAccountingPolicies.SpecifyWhenPlanningShipment
			|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
			|		ELSE TTGoodsWaybill.Series
			|	END,
			|	CASE
			|		WHEN TTGoodsWaybill.BatchesIndicationStatus <> 0
			|			AND NOT TTSeriesAccountingPolicies.UseCostAccountingByBatches
			|			AND TTSeriesAccountingPolicies.SpecifyWhenPlanningShipment
			|			THEN TRUE
			|		ELSE FALSE
			|	END,
			|	TTGoodsWaybill.Purpose,
			|	TTGoodsWaybill.StorageLocation
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	InventoryKinds.Ref AS InventoryOwnerAttribute
			|INTO InventoryTable
			|FROM
			|	Catalog.InventoryKinds AS InventoryKinds
			|WHERE
			|	InventoryKinds.GoodsOwner = &Partner
			|	AND InventoryKinds.Organization  = &Organization
			|	AND InventoryKinds.Contract      = &Contract
			|	AND (&ForAllTypes
			|		OR InventoryKinds.InventoryType IN (&InventoryTypes))
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	GoodsAccepted.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	GoodsAccepted.Organization                AS Organization,
			|	SUM(GoodsAccepted.CountBalance)   AS CountBalance
			|INTO TableOfAcceptedProducts
			|FROM
			|	(SELECT
			|		GoodsAcceptedBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
			|		GoodsAcceptedBalance.Organization                AS Organization,
			|		GoodsAcceptedBalance.CountBalance          AS CountBalance
			|	FROM
			|		AccumulationRegister.CompanyGoods.Balance(,
			|			Organization = &Organization
			|				AND InventoryOwnerAttribute IN
			|					(SELECT
			|						InventoryTable.InventoryOwnerAttribute
			|					FROM
			|						InventoryTable AS InventoryTable)) AS GoodsAcceptedBalance
			|
			|	UNION ALL
			|
			|	SELECT
			|		GoodsAcceptedByRegistrar.ItemsLocationAttributes,
			|		GoodsAcceptedByRegistrar.Organization,
			|		GoodsAcceptedByRegistrar.Count
			|	FROM
			|		AccumulationRegister.CompanyGoods AS GoodsAcceptedByRegistrar
			|	WHERE
			|		GoodsAcceptedByRegistrar.Recorder = &Recorder
			|		AND GoodsAcceptedByRegistrar.Active
			|		AND GoodsAcceptedByRegistrar.Organization = &Organization
			|		AND GoodsAcceptedByRegistrar.InventoryOwnerAttribute IN
			|			(SELECT
			|				InventoryTable.InventoryOwnerAttribute
			|			FROM
			|				InventoryTable AS InventoryTable)) AS GoodsAccepted
			|
			|GROUP BY
			|	GoodsAccepted.ItemsLocationAttributes,
			|	GoodsAccepted.Organization
			|
			|HAVING
			|	SUM(GoodsAccepted.CountBalance) > 0
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ISNULL(ProductAccountingAnalysts.StorageLocation, UNDEFINED) AS StorageLocation,
			|	ISNULL(ProductAccountingAnalysts.Products, VALUE(Catalog.Products.EmptyRef)) AS Products,
			|	ISNULL(ProductAccountingAnalysts.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
			|	CASE
			|		WHEN Goods.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|			THEN VALUE(Catalog.Assignments.EmptyRef)
			|		ELSE ISNULL(ProductAccountingAnalysts.Purpose, VALUE(Catalog.Assignments.EmptyRef))
			|	END                                     AS Purpose,
			|	ISNULL(ProductAccountingAnalysts.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
			|	SUM(GoodsAccepted.CountBalance)   AS CountBalance
			|INTO GoodsAcceptedGrouping
			|FROM
			|	TableOfAcceptedProducts AS GoodsAccepted
			|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS ProductAccountingAnalysts
			|		ON GoodsAccepted.ItemsLocationAttributes = ProductAccountingAnalysts.Ref
			|
			|		LEFT JOIN Catalog.Products AS Goods
			|		ON ProductAccountingAnalysts.Products = Goods.Ref
			|WHERE
			|	ProductAccountingAnalysts.StorageType <> VALUE(Enum.StorageLocationTypes.CounterpartyContract)
			|	AND (ProductAccountingAnalysts.StorageLocation IN(&Warehouses)
			|		OR &InAllWarehouses)
			|	AND (&ForAllOrders OR ProductAccountingAnalysts.Purpose.OrderDocument IN (&AnArrayOfOrders))
			|
			|GROUP BY
			|	ISNULL(ProductAccountingAnalysts.StorageLocation, UNDEFINED),
			|	ISNULL(ProductAccountingAnalysts.Products, VALUE(Catalog.Products.EmptyRef)),
			|	ISNULL(ProductAccountingAnalysts.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
			|	CASE
			|		WHEN Goods.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|			THEN VALUE(Catalog.Assignments.EmptyRef)
			|		ELSE ISNULL(ProductAccountingAnalysts.Purpose, VALUE(Catalog.Assignments.EmptyRef))
			|	END,
			|	ISNULL(ProductAccountingAnalysts.Series, VALUE(Catalog.ItemsBatches.EmptyRef))
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	GoodsAccepted.Products AS Products,
			|	GoodsAccepted.Characteristic AS Characteristic,
			|	GoodsAccepted.Purpose AS Purpose,
			|	GoodsAccepted.Series AS Series,
			|	ISNULL(InvoiceGoods.DifferentSeriesAccounting, FALSE) AS DifferentSeriesAccounting,
			|	GoodsAccepted.StorageLocation AS StorageLocation,
			|	GoodsAccepted.CountBalance AS CountBalance,
			|	GoodsAccepted.CountBalance - ISNULL(InvoiceGoods.Count, 0) AS LeftToSelect,
			|	ISNULL(InvoiceGoods.Count, 0) AS QuantityIsSelected,
			|	ISNULL(InvoiceGoods.Count, 0) AS QuantityInInvoice
			|
			|FROM
			|	GoodsAcceptedGrouping AS GoodsAccepted
			|		LEFT JOIN InvoiceGoods AS InvoiceGoods
			|		ON GoodsAccepted.Products = InvoiceGoods.Products
			|		AND GoodsAccepted.Characteristic = InvoiceGoods.Characteristic
			|		AND GoodsAccepted.Purpose = InvoiceGoods.Purpose
			|		AND GoodsAccepted.Series = InvoiceGoods.Series
			|		AND GoodsAccepted.StorageLocation = InvoiceGoods.StorageLocation
			|
			|ORDER BY
			|	ISNULL(InvoiceGoods.LineNumber, 99999),
			|	StorageLocation,
			|	Products,
			|	Characteristic,
			|	Purpose,
			|	Series
			|";
			
		EndIf;
		
	ElsIf Object.BalanceMode = "Retired" Then
		
		// A variant of the selection of goods in the document "Redemption of goods accepted for storage".
		If Not AccessRight("Read", Metadata.AccumulationRegisters.CompanySafeStock) Then
			
			Object.Goods.Clear();
			Return;
			
		Else
			
			QueryText =
			"SELECT
			|	InvoiceGoods.LineNumber AS LineNumber,
			|	InvoiceGoods.Products AS Products,
			|	InvoiceGoods.Characteristic AS Characteristic,
			|	InvoiceGoods.Series AS Series,
			|	InvoiceGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	InvoiceGoods.Purpose AS Purpose,
			|	InvoiceGoods.StorageLocation AS StorageLocation,
			|	InvoiceGoods.Custodian AS Custodian,
			|	InvoiceGoods.Count AS Count
			|INTO TTGoodsWaybill
			|FROM
			|	&Goods AS InvoiceGoods
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	MIN(TTGoodsWaybill.LineNumber) AS LineNumber,
			|	TTGoodsWaybill.Products AS Products,
			|	TTGoodsWaybill.Characteristic AS Characteristic,
			|	TTGoodsWaybill.Series AS Series,
			|	FALSE AS DifferentSeriesAccounting,
			|	TTGoodsWaybill.Purpose AS Purpose,
			|	TTGoodsWaybill.StorageLocation AS StorageLocation,
			|	TTGoodsWaybill.Custodian AS Custodian,
			|	SUM(TTGoodsWaybill.Count) AS Count
			|INTO InvoiceGoods
			|FROM
			|	TTGoodsWaybill AS TTGoodsWaybill
			|GROUP BY
			|	TTGoodsWaybill.Products,
			|	TTGoodsWaybill.Characteristic,
			|	TTGoodsWaybill.Series,
			|	TTGoodsWaybill.Purpose,
			|	TTGoodsWaybill.StorageLocation,
			|	TTGoodsWaybill.Custodian
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	InventoryKinds.Ref AS InventoryOwnerAttribute
			|
			|INTO InventoryTable
			|FROM
			|	Catalog.InventoryKinds AS InventoryKinds
			|
			|WHERE
			|	InventoryKinds.GoodsOwner = &Partner
			|	AND InventoryKinds.Organization  = &Organization
			|	AND InventoryKinds.Contract      = &Contract
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	GoodsDisposedOf.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	GoodsDisposedOf.Organization                AS Organization,
			|	SUM(GoodsDisposedOf.CountBalance)  AS CountBalance
			|INTO TableOfRetiredGoods
			|FROM
			|	(SELECT
			|		GoodsDisposedOfBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
			|		GoodsDisposedOfBalance.Organization                AS Organization,
			|		-GoodsDisposedOfBalance.CountBalance         AS CountBalance
			|	FROM
			|		AccumulationRegister.CompanySafeStock.Balance(,
			|			Organization = &Organization
			|				AND InventoryOwnerAttribute IN
			|					(SELECT
			|						InventoryTable.InventoryOwnerAttribute
			|					FROM
			|						InventoryTable AS InventoryTable)) AS GoodsDisposedOfBalance
			|
			|	UNION ALL
			|
			|	SELECT
			|		GoodsRetiredRegistrar.ItemsLocationAttributes,
			|		GoodsRetiredRegistrar.Organization,
			|		-GoodsRetiredRegistrar.Count
			|	FROM
			|		AccumulationRegister.CompanySafeStock AS GoodsRetiredRegistrar
			|	WHERE
			|		GoodsRetiredRegistrar.Recorder = &Recorder
			|		AND GoodsRetiredRegistrar.Active
			|		AND GoodsRetiredRegistrar.Organization = &Organization
			|		AND GoodsRetiredRegistrar.InventoryOwnerAttribute IN
			|			(SELECT
			|				InventoryTable.InventoryOwnerAttribute
			|			FROM
			|				InventoryTable AS InventoryTable)) AS GoodsDisposedOf
			|
			|GROUP BY
			|	GoodsDisposedOf.ItemsLocationAttributes,
			|	GoodsDisposedOf.Organization
			|
			|HAVING
			|	SUM(GoodsDisposedOf.CountBalance) > 0
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ISNULL(ProductAccountingAnalysts.StorageLocation, UNDEFINED) AS StorageLocation,
			|	CASE
			|		WHEN ProductAccountingAnalysts.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
			|			THEN ISNULL(ProductAccountingAnalysts.Partner, VALUE(Catalog.Partners.EmptyRef))
			|		ELSE VALUE(Catalog.Partners.EmptyRef)
			|	END                                     AS Custodian,
			|	ISNULL(ProductAccountingAnalysts.Products, VALUE(Catalog.Products.EmptyRef)) AS Products,
			|	ISNULL(ProductAccountingAnalysts.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
			|	CASE
			|		WHEN Goods.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|			THEN VALUE(Catalog.Assignments.EmptyRef)
			|		ELSE ISNULL(ProductAccountingAnalysts.Purpose, VALUE(Catalog.Assignments.EmptyRef))
			|	END                                     AS Purpose,
			|	ISNULL(ProductAccountingAnalysts.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
			|	SUM(GoodsDisposedOf.CountBalance)   AS CountBalance
			|INTO RetiredGoodsGrouping
			|FROM
			|	TableOfRetiredGoods AS GoodsDisposedOf
			|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS ProductAccountingAnalysts
			|		ON GoodsDisposedOf.ItemsLocationAttributes = ProductAccountingAnalysts.Ref
			|		
			|		LEFT JOIN Catalog.Products AS Goods
			|		ON ProductAccountingAnalysts.Products = Goods.Ref
			|
			|GROUP BY
			|	ISNULL(ProductAccountingAnalysts.StorageLocation, UNDEFINED),
			|	CASE
			|		WHEN ProductAccountingAnalysts.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
			|			THEN ISNULL(ProductAccountingAnalysts.Partner, VALUE(Catalog.Partners.EmptyRef))
			|		ELSE VALUE(Catalog.Partners.EmptyRef)
			|	END,
			|	ISNULL(ProductAccountingAnalysts.Products, VALUE(Catalog.Products.EmptyRef)),
			|	ISNULL(ProductAccountingAnalysts.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)),
			|	CASE
			|		WHEN Goods.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|			THEN VALUE(Catalog.Assignments.EmptyRef)
			|		ELSE ISNULL(ProductAccountingAnalysts.Purpose, VALUE(Catalog.Assignments.EmptyRef))
			|	END,
			|	ISNULL(ProductAccountingAnalysts.Series, VALUE(Catalog.ItemsBatches.EmptyRef))
			|;
			|
			|SELECT
			|	GoodsDisposedOf.StorageLocation AS StorageLocation,
			|	GoodsDisposedOf.Custodian AS Custodian,
			|	GoodsDisposedOf.Products AS Products,
			|	GoodsDisposedOf.Characteristic AS Characteristic,
			|	GoodsDisposedOf.Purpose AS Purpose,
			|	GoodsDisposedOf.Series AS Series,
			|	ISNULL(InvoiceGoods.DifferentSeriesAccounting, FALSE) AS DifferentSeriesAccounting,
			|	GoodsDisposedOf.CountBalance AS CountBalance,
			|	GoodsDisposedOf.CountBalance - ISNULL(InvoiceGoods.Count, 0) AS LeftToSelect,
			|	ISNULL(InvoiceGoods.Count, 0) AS QuantityIsSelected,
			|	ISNULL(InvoiceGoods.Count, 0) AS QuantityInInvoice
			|
			|FROM
			|	RetiredGoodsGrouping AS GoodsDisposedOf
			|		LEFT JOIN InvoiceGoods AS InvoiceGoods
			|		ON GoodsDisposedOf.Products = InvoiceGoods.Products
			|		AND GoodsDisposedOf.Characteristic = InvoiceGoods.Characteristic
			|		AND GoodsDisposedOf.Purpose = InvoiceGoods.Purpose
			|		AND GoodsDisposedOf.Series = InvoiceGoods.Series
			|		AND GoodsDisposedOf.StorageLocation = InvoiceGoods.StorageLocation
			|		AND GoodsDisposedOf.Custodian = InvoiceGoods.Custodian
			|	
			|ORDER BY
			|	ISNULL(InvoiceGoods.LineNumber, 99999),
			|	StorageLocation,
			|	Products,
			|	Characteristic,
			|	Purpose,
			|	Series
			|";
			
		EndIf;
		
	ElsIf Object.BalanceMode = "ToWriteOff" Then
		
		// The option of selecting goods in the document "Reporting and storage of goods".
		If Not AccessRight("Read", Metadata.AccumulationRegisters.CompanyGoods) Then
			
			Object.Goods.Clear();
			Return;
			
		Else
			
			QueryText =
			"SELECT
			|	InvoiceGoods.LineNumber AS LineNumber,
			|	InvoiceGoods.Products AS Products,
			|	InvoiceGoods.Characteristic AS Characteristic,
			|	InvoiceGoods.Series AS Series,
			|	InvoiceGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	InvoiceGoods.Purpose AS Purpose,
			|	InvoiceGoods.StorageLocation AS StorageLocation,
			|	InvoiceGoods.Custodian AS Custodian,
			|	InvoiceGoods.Count AS Count
			|INTO TTGoodsWaybill
			|FROM
			|	&Goods AS InvoiceGoods
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	MIN(TTGoodsWaybill.LineNumber) AS LineNumber,
			|	TTGoodsWaybill.Products AS Products,
			|	TTGoodsWaybill.Characteristic AS Characteristic,
			|	TTGoodsWaybill.Series AS Series,
			|	FALSE AS DifferentSeriesAccounting,
			|	TTGoodsWaybill.Purpose AS Purpose,
			|	TTGoodsWaybill.StorageLocation AS StorageLocation,
			|	TTGoodsWaybill.Custodian AS Custodian,
			|	SUM(TTGoodsWaybill.Count) AS Count
			|INTO InvoiceGoods
			|FROM
			|	TTGoodsWaybill AS TTGoodsWaybill
			|GROUP BY
			|	TTGoodsWaybill.Products,
			|	TTGoodsWaybill.Characteristic,
			|	TTGoodsWaybill.Series,
			|	TTGoodsWaybill.Purpose,
			|	TTGoodsWaybill.Custodian,
			|	TTGoodsWaybill.StorageLocation
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	InventoryKinds.Ref AS InventoryOwnerAttribute
			|INTO InventoryTable
			|FROM
			|	Catalog.InventoryKinds AS InventoryKinds
			|
			|WHERE
			|	InventoryKinds.GoodsOwner = &Partner
			|	AND InventoryKinds.Organization  = &Organization
			|	AND InventoryKinds.Contract      = &Contract
			|	AND (&ForAllTypes
			|		OR InventoryKinds.InventoryType IN (&InventoryTypes))
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	GoodsToWriteOff.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	SUM(GoodsToWriteOff.ToRegisterGoodsIssueBalance) AS ToRegisterGoodsIssueBalance
			|INTO GoodsToWriteOff
			|FROM
			|	(SELECT
			|		GoodsToWriteOffBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
			|		GoodsToWriteOffBalance.ToRegisterGoodsIssueBalance AS ToRegisterGoodsIssueBalance
			|	FROM
			|		AccumulationRegister.CompanyGoods.Balance(,
			|			Organization = &Organization
			|				AND InventoryOwnerAttribute IN
			|					(SELECT
			|						InventoryTable.InventoryOwnerAttribute
			|					FROM
			|						InventoryTable AS InventoryTable)) AS GoodsToWriteOffBalance
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsToBeDebitedRegistrar.ItemsLocationAttributes,
			|		GoodsToBeDebitedRegistrar.ToRegisterGoodsIssue
			|	FROM
			|		AccumulationRegister.CompanyGoods AS GoodsToBeDebitedRegistrar
			|	WHERE
			|		GoodsToBeDebitedRegistrar.Recorder = &Recorder
			|		AND GoodsToBeDebitedRegistrar.Active
			|		AND GoodsToBeDebitedRegistrar.Organization = &Organization
			|		AND GoodsToBeDebitedRegistrar.InventoryOwnerAttribute IN
			|			(SELECT
			|				InventoryTable.InventoryOwnerAttribute
			|			FROM
			|				InventoryTable AS InventoryTable)) AS GoodsToWriteOff
			|
			|GROUP BY
			|	GoodsToWriteOff.ItemsLocationAttributes
			|
			|HAVING
			|	SUM(GoodsToWriteOff.ToRegisterGoodsIssueBalance) > 0
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	ItemsLocationAttributes.StorageLocation  AS StorageLocation,
			|	CASE
			|		WHEN ProductAccountingAnalysts.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
			|			THEN ProductAccountingAnalysts.Partner
			|		ELSE VALUE(Catalog.Partners.EmptyRef)
			|	END                                     AS Custodian,
			|	ItemsLocationAttributes.Products   AS Products,
			|	ItemsLocationAttributes.Characteristic AS Characteristic,
			|	CASE
			|		WHEN ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
			|			THEN VALUE(Catalog.Assignments.EmptyRef)
			|		ELSE ItemsLocationAttributes.Purpose
			|	END                                     AS Purpose,
			|	ItemsLocationAttributes.Series          AS Series,
			|	ToRegisterGoodsIssueBalance                AS ToRegisterGoodsIssueBalance
			|INTO TTItemsToBeDebited
			|FROM
			|	GoodsToWriteOff AS GoodsToWriteOff
			|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS ProductAccountingAnalysts
			|		ON GoodsToWriteOff.ItemsLocationAttributes = ProductAccountingAnalysts.Ref
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	GoodsToWriteOff.StorageLocation AS StorageLocation,
			|	GoodsToWriteOff.Custodian AS Custodian,
			|	GoodsToWriteOff.Products AS Products,
			|	GoodsToWriteOff.Characteristic AS Characteristic,
			|	GoodsToWriteOff.Purpose AS Purpose,
			|	GoodsToWriteOff.Series AS Series,
			|	ISNULL(InvoiceGoods.DifferentSeriesAccounting, FALSE) AS DifferentSeriesAccounting,
			|	GoodsToWriteOff.ToRegisterGoodsIssueBalance AS CountBalance,
			|	GoodsToWriteOff.ToRegisterGoodsIssueBalance - ISNULL(InvoiceGoods.Count, 0) AS LeftToSelect,
			|	ISNULL(InvoiceGoods.Count, 0) AS QuantityIsSelected,
			|	ISNULL(InvoiceGoods.Count, 0) AS QuantityInInvoice
			|
			|FROM TTItemsToBeDebited AS GoodsToWriteOff
			|	LEFT JOIN InvoiceGoods AS InvoiceGoods
			|		ON GoodsToWriteOff.Products = InvoiceGoods.Products
			|		AND GoodsToWriteOff.Characteristic = InvoiceGoods.Characteristic
			|		AND GoodsToWriteOff.Purpose = InvoiceGoods.Purpose
			|		AND GoodsToWriteOff.Series = InvoiceGoods.Series
			|		AND GoodsToWriteOff.StorageLocation = InvoiceGoods.StorageLocation
			|		AND GoodsToWriteOff.Custodian = InvoiceGoods.Custodian
			|
			|ORDER BY
			|	ISNULL(InvoiceGoods.LineNumber, 99999),
			|	GoodsToWriteOff.StorageLocation,
			|	GoodsToWriteOff.Products,
			|	GoodsToWriteOff.Characteristic,
			|	GoodsToWriteOff.Purpose,
			|	GoodsToWriteOff.Series
			|";
			
		EndIf;
		
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	
	If Not ValueIsFilled(Object.InventoryType) Then
		InventoryTypes = Undefined;
	ElsIf TypeOf(Object.InventoryType) = Type("ValueList") Then
		InventoryTypes = Object.InventoryType;
	Else
		InventoryTypes = New ValueList;
		InventoryTypes.Add(Object.InventoryType);
	EndIf;
	
	If Not ValueIsFilled(OrderDocument) Then
		AnArrayOfOrders = Undefined;
	Else
		AnArrayOfOrders = New Array;
		AnArrayOfOrders.Add(OrderDocument);
		If BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
			Or BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
			Or BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
			Or BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
			Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
			AnArrayOfOrders.Add(Undefined);
		EndIf;
	EndIf;
	
	Query.SetParameter("Recorder",   Ref);
	Query.SetParameter("Partner",       Object.Owner);
	Query.SetParameter("Organization",   Object.Organization);
	Query.SetParameter("Warehouses",        Warehouses);
	Query.SetParameter("InAllWarehouses", Warehouses.Count() = 0);
	Query.SetParameter("Contract",       Object.Contract);
	Query.SetParameter("InventoryTypes",   InventoryTypes);
	Query.SetParameter("ForAllTypes",   InventoryTypes = Undefined);
	Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
	Query.SetParameter("ForAllOrders",  AnArrayOfOrders = Undefined);
	
	If ValueIsFilled(AddressOfGoodsInvoiceInVault) Then
		Goods = GetFromTempStorage(AddressOfGoodsInvoiceInVault); // ValueTable
		
		If (Object.BalanceMode = "ToWriteOff" Or Object.BalanceMode = "Retired")
			And Goods.Columns.Find("Custodian") = Undefined Then
			Goods.Columns.Add("Custodian", New TypeDescription("CatalogRef.Partners"));
		EndIf;
		
		Query.SetParameter("Goods", Goods);
		
	EndIf;
	
	Object.Goods.Load(Query.Execute().Unload());
	
	FillProductsWithSelectedProducts();
	
EndProcedure

&AtServer
Procedure UpdateSelectedProducts(ToCacheData)
	
	BsnsTransactions = New Array;
	BsnsTransactions.Add(Enums.BusinessTransactions.RedemptionOfGoodsFromStorage);
	BsnsTransactions.Add(Enums.BusinessTransactions.RedemptionOfProviderGoods);
	If BsnsTransactions.Find(BusinessOperation) = Undefined
		Or Not ToCacheData Then
		
		Return;
		
	EndIf;
	
	Filter = New Structure("Products, Characteristic, Purpose, Series, StorageLocation");
	
	For Each RowOfGoods In Object.Goods Do
		
		If RowOfGoods.Check
			Or RowOfGoods.QuantityIsSelected > 0 Then
			
			FillPropertyValues(Filter, RowOfGoods);
			
			RowsOfSelectedProducts = SelectedGoods.FindRows(Filter);
			
			If RowsOfSelectedProducts.Count() = 0 Then
				NewRow = SelectedGoods.Add();
				FillPropertyValues(NewRow, RowOfGoods);
			Else
				FillPropertyValues(RowsOfSelectedProducts[0], RowOfGoods);
			EndIf;
			
		ElsIf Not RowOfGoods.Check
			And RowOfGoods.QuantityIsSelected = 0 Then
			
			FillPropertyValues(Filter, RowOfGoods);
			
			RowsOfSelectedProducts = SelectedGoods.FindRows(Filter);
			
			If RowsOfSelectedProducts.Count() > 0 Then
				SelectedGoods.Delete(RowsOfSelectedProducts[0]);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillProductsWithSelectedProducts()
	
	BsnsTransactions = New Array;
	BsnsTransactions.Add(Enums.BusinessTransactions.RedemptionOfGoodsFromStorage);
	BsnsTransactions.Add(Enums.BusinessTransactions.RedemptionOfProviderGoods);
	If BsnsTransactions.Find(BusinessOperation) = Undefined
		Or Object.Goods.Count() = 0 Then
		
		Return;
		
	EndIf;
	
	Filter = New Structure("Products, Characteristic, Purpose, Series, StorageLocation");
	
	For Each LineOfSelectedProducts In SelectedGoods Do
		
		FillPropertyValues(Filter, LineOfSelectedProducts);
		
		ProductLines_2 = Object.Goods.FindRows(Filter);
		
		If ProductLines_2.Count() > 0 Then
			VariableString = ProductLines_2[0];
			FillPropertyValues(VariableString, LineOfSelectedProducts);
			
			If VariableString.Check Then
				
				VariableString.LeftToSelect = VariableString.CountBalance
																- VariableString.QuantityIsSelected;
				
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SaveFormSettingsOnServer()
	
	ObjectKey = "Processing_SelectionOfGoodsAcceptedForResponsibleStorage";
	
	Common.CommonSettingsStorageSave(ObjectKey, "", Object.BalanceMode);
	
EndProcedure

&AtServer
Function GoodsAddressInStorage()
	
	Filter = New Structure("Check", True);
	SelectedGoodItems      = Object.Goods.Unload(Filter);
	
	Return PutToTempStorage(SelectedGoodItems, UUID);
	
EndFunction

&AtServer
Procedure BalanceModeWhenChangingOnServer()
	
	FillInProductsTable_();
	CustomizeForm();
	
EndProcedure

&AtServer
Function AllowResultsToBeTransferredToDocument()
	
	Return CheckFilling();
	
EndFunction

&AtServer
Procedure MarkEverythingOnServer()
	
	Modified = True;
	
	For Each RowOfGoods In Object.Goods Do
		RowOfGoods.QuantityIsSelected = RowOfGoods.CountBalance;
		RowOfGoods.Check = True;
		
		CalculateNumberInRow(Object.Goods, RowOfGoods, GoodsAreSelected);
	EndDo;
	
EndProcedure

&AtServer
Procedure UncheckServer()
	
	For Each RowOfGoods In Object.Goods Do
		RowOfGoods.Check = False;
		RowOfGoods.QuantityIsSelected = RowOfGoods.QuantityInInvoice;
		
		CalculateNumberInRow(Object.Goods, RowOfGoods, GoodsAreSelected);
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateAtServer()
	
	SelectedGoods.Clear();
	FillInProductsTable_(False);
	
EndProcedure

&AtServer
Procedure CreateInformationLabelSelections()
	
	If Not TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		InformationLabelSelections = NStr("vi = 'Lọc theo: %Organization%, %Partner%, %Contract%, %Warehouse%';
											|ru = 'Отбор по: %Organization%, %Partner%, %Contract%, %Warehouse%';
											|en = 'Filter by: %Organization%, %Partner%, %Contract%, %Warehouse%'; fa = 'Filter by: %Organization%, %Partner%, %Contract%, %Warehouse%';
											|it = 'Selezione per: %Organization%, %Partner%, %Contract%, %Warehouse%';
											|pl = 'Filtr według: %Organization%, %Partner%, %Contract%, %Warehouse%';
											|tr = 'Filtre: %Organization%,%Partner%,%Contract%,%Warehouse%'");
	Else
		InformationLabelSelections = NStr("vi = 'Lọc theo: %Contract%, %Warehouse%';
											|ru = 'Отбор по: %Contract%, %Warehouse%';
											|en = 'Filter by: %Contract%, %Warehouse%'; fa = 'Filter by: %Contract%, %Warehouse%';
											|it = 'Selezione per: %Contract%, %Warehouse%';
											|pl = 'Filtr według: %Contract%, %Warehouse%';
											|tr = 'Filtre: %Contract%,%Warehouse%'");
	EndIf;
	
	If Warehouses.Count() > 1 Then
		LabelWarehouse = NStr("vi = 'nhóm kho: ""%Warehouse%""';
								|ru = 'группе складов: ""%Warehouse%""';
								|en = 'warehouse group: ""%Warehouse%""'; fa = 'warehouse group: ""%Warehouse%""';
								|it = 'gruppo di magazzini: ""%Warehouse%""';
								|pl = 'grupie magazynów: ""%Warehouse%""';
								|tr = 'depo grubu: ""%Warehouse%""'");
		LabelWarehouse = StrReplace(LabelWarehouse, "%Warehouse%", Object.Warehouse);
	Else
		LabelWarehouse = "";
	EndIf;
	
	InformationLabelSelections = StrReplace(InformationLabelSelections, "%Organization%", Object.Organization);
	InformationLabelSelections = StrReplace(InformationLabelSelections, "%Partner%",     Object.Owner);
	InformationLabelSelections = StrReplace(InformationLabelSelections, "%Contract%",     Object.Contract);
	InformationLabelSelections = StrReplace(InformationLabelSelections, "%Warehouse%",       LabelWarehouse);
	
	If Right(InformationLabelSelections, 2) = ", " Then
		InformationLabelSelections = Left(InformationLabelSelections, StrLen(InformationLabelSelections) - 2);
	EndIf;
	
	InformationLabelSelections = InformationLabelSelections + ".";
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateNumberInRow(Goods, CurrentData, GoodsAreSelected)
	
	CurrentData.LeftToSelect = CurrentData.CountBalance -CurrentData.QuantityIsSelected;
	
	Filter = New Structure("Check", True);
	MarkedLines_ = Goods.FindRows(Filter);
	
	GoodsAreSelected = MarkedLines_.Count() > 0;
	
EndProcedure

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
