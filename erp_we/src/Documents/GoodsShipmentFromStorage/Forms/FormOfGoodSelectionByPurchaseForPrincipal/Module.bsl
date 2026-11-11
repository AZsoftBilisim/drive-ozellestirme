#Region Variables

&AtClient
Var ClosingInProgress Export;

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

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
		Raise NStr("vi = 'Chỉ có thể mở bộ xử lý từ chứng từ';
					|ru = 'Предусмотрено открытие обработки только из документов.';
					|en = 'Data processor can be opened only from documents.'; fa = 'Data processor can be opened only from documents.';
					|it = 'Viene fornita l''apertura dell''elaborazione solo dalle forme dei documenti';
					|pl = 'Przewidziano otwarcie przetwarzania tylko z dokumentów.';
					|tr = 'Yalnızca belgelerden işlem açmak için provizyon sağlanmıştır.'");
	EndIf;
	
	Partner                    = Parameters.Owner;
	Organization                = Parameters.Organization;
	Date                       = Parameters.Date;
	Warehouse                      = Parameters.Warehouse;
	Contract                    = Parameters.Contract;
	BusinessOperation      = Parameters.BusinessOperation;
	DocumentShipments           = Parameters.DocumentShipments;
	Counterparty                 = Parameters.Counterparty;
	AdvancedWarehousingOnShipment   = Parameters.AdvancedWarehousingOnShipment;
	ByOrder                   = Parameters.ByOrder;
	If ByOrder Then
		OnlySelectedOrders = True;
	EndIf;
	
	If ValueIsFilled(Parameters.OrderList) Then
		SalesOrders.LoadValues(Parameters.OrderList.UnloadValues());
		If Parameters.OrderList.Count() = 1 Then
			SalesOrder = Parameters.OrderList[0].Value;
		EndIf;
	EndIf;	
	
	If ValueIsFilled(Parameters.AddressOfTheShipmentItemsInTheTemporaryStorage) Then
		DataOnShipmentItems = GetFromTempStorage(Parameters.AddressOfTheShipmentItemsInTheTemporaryStorage);
		If ValueIsFilled(DataOnShipmentItems) Then
			DocumentGoods.Load(DataOnShipmentItems);
		EndIf;
	EndIf;
	
	UseSaleByMultipleOrders = GetFunctionalOption("UseSaleByMultipleOrders");
	
	FillInSelectionListForBalances();
	FillWarehousesAdjustVisibility();
	FillInProductsTable_();
	
	SetVisibilityByOrders();
	
	CreateInformationLabelSelections()
	
EndProcedure

&AtServer
Procedure FillInProductsTable_()
	
	FilterParameters = New Structure();
	FilterParameters.Insert("Partner", Partner);
	FilterParameters.Insert("Counterparty", Counterparty);	
	FilterParameters.Insert("Organization", Organization);
	FilterParameters.Insert("Warehouse", Warehouse);
	FilterParameters.Insert("Contract", Contract);
	If OnlySelectedOrders Then
		FilterParameters.Insert("SalesOrders", SalesOrders.UnloadValues());
	Else
		FilterParameters.Insert("SalesOrders", New Array());
	EndIf;
	
	FilterParameters.Insert("GoodsShipment", DocumentGoods.Unload());
	FilterParameters.Insert("DocumentShipments", DocumentShipments);
	FilterParameters.Insert("ByOrder", ByOrder);
	ShipmentData = Documents.GoodsShipmentFromStorage.GetTableOfShipmentBalances(FilterParameters);
	
	SelectedGoods.Clear();
	
	SerialNumber = 1;
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array;
	ProcessedRowsRecalculatingAmounts = New Array;
	
	For Each ShipmentLine In ShipmentData Do
		RowOfProduct = SelectedGoods.Add();
		FillPropertyValues(RowOfProduct, ShipmentLine);
		
		RowOfProduct.LineNumber = SerialNumber;
		SerialNumber = SerialNumber + 1;
		
		RowOfProduct.NumberOfPackages = ?(ShipmentLine.Count <> 0,
				ShipmentLine.Count / ShipmentLine.ZoomRatio,0);
				
		RowOfProduct.CountBalance = ?(ShipmentLine.CountBalance <> 0,
				ShipmentLine.CountBalance / ShipmentLine.ZoomRatio,0);
				
		RowOfProduct.QuantityInOrder = ?(ShipmentLine.QuantityInOrder <> 0,
				ShipmentLine.QuantityInOrder / ShipmentLine.ZoomRatio,0);
		
		RowOfProduct.QuantityInInvoice = ?(ShipmentLine.QuantityInInvoice <> 0,
				ShipmentLine.QuantityInInvoice / ShipmentLine.ZoomRatio,0);
				
		RowOfProduct.NumberInReport = ?(ShipmentLine.NumberInReport <> 0,
				ShipmentLine.NumberInReport / ShipmentLine.ZoomRatio,0);
		
		RowOfProduct.QuantityIsCollected = ?(ShipmentLine.QuantityIsCollected <> 0,
				ShipmentLine.QuantityIsCollected / ShipmentLine.ZoomRatio,0);
		
		RowOfProduct.NumberInProgress = ?(ShipmentLine.NumberInProgress <> 0,
				ShipmentLine.NumberInProgress / ShipmentLine.ZoomRatio,0);
		
		RowOfProduct.DocumentQuantity = ?(ShipmentLine.DocumentQuantity <> 0, 
				ShipmentLine.DocumentQuantity / ShipmentLine.ZoomRatio,0);
		
		If BalanceMode = "ByReport" Then
			RowOfProduct.NumberOfPackages = RowOfProduct.NumberInReport;
		ElsIf BalanceMode = "AllOrdered" Then
			RowOfProduct.NumberOfPackages = RowOfProduct.QuantityInOrder;
		ElsIf BalanceMode = "ByNote" Then
			RowOfProduct.NumberOfPackages = RowOfProduct.QuantityIsCollected;
		ElsIf BalanceMode = "ByBalance" Then
			RowOfProduct.NumberOfPackages = RowOfProduct.CountBalance;
		EndIf;
		
		If RowOfProduct.NumberOfPackages > 0
			And RowOfProduct.NumberOfPackages <> RowOfProduct.QuantityInInvoice Then
			RowOfProduct.Check = True;
		EndIf;
		
		RecalculateAmount_ = ?(RowOfProduct.DocumentQuantity = RowOfProduct.NumberOfPackages, False, True);
		
		If RecalculateAmount_ Then
			ProcessedRowsRecalculatingAmounts.Add(RowOfProduct);
		Else
			RowsToProcess.Add(RowOfProduct);
		EndIf;
		
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		SelectedGoods,
		CachedValues);
		
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, True);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedRowsRecalculatingAmounts,
		StructureOfActions,
		SelectedGoods,
		CachedValues);
		
	For Each ShipmentLine In ShipmentData Do
		
		RecalculateAmount_ = ?(RowOfProduct.DocumentQuantity = RowOfProduct.NumberOfPackages, False, True);
		
		If Not RecalculateAmount_ Then
			RowOfProduct.Sum = RowOfProduct.DocumentAmount;
		EndIf;
		
	EndDo;
	
	BarcodesOfWaybillPackages = WarehousesLocalization.ToFormStructureOfBarcodesOfWaybillPackages();
	If SalesOrders.Count() > 0 Then
		GoodsShipmentFromStorageLocalization.FillInBarcodesOfPackages(
			SalesOrders, SelectedGoods.Unload(), BarcodesOfWaybillPackages);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit
		And Modified Then
		
		Cancel = True;
		WarningText = NStr("vi = 'Dữ liệu đã thay đổi. Tất cả thay đổi sẽ bị mất.';
							|ru = 'Данные были изменены. Все изменения будут потеряны.';
							|en = 'The data has changed. All changes will be lost.'; fa = 'The data has changed. All changes will be lost.';
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
	
	For Each RowOfProduct In SelectedGoods Do
		SetQuantityByMode(RowOfProduct);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure SelectedProductsQuantitySelectedOnChange(Item)
	
	CurrentRow = Items.SelectedGoods.CurrentData;
	CurrentRow.ThereIsAManualChange = True;
	CalculateSumAndQuantityForCurRow(CurrentRow);

EndProcedure

&AtClient
Procedure SelectedGoodsCheckOnChange(Item)
	
	Modified = True;
	
	CurrentData = Items.SelectedGoods.CurrentData;
	CurrentData.ThereIsAManualChange = True;
	
	CalculateSumAndQuantityForCurRow(CurrentData);
	
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
	
	SelectSelectedRows(True);
	
EndProcedure

&AtClient
Procedure ClearMark(Command)
	
	SelectSelectedRows(False);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectSelectedRows(SelectionValue = True)
	
	For Each LineNumber In Items.SelectedGoods.SelectedRows Do
		TSRow = SelectedGoods.FindByID(LineNumber);
		If Not SelectionValue And (SelectionValue And TSRow.NumberOfPackages > 0) Then
			TSRow.Check = SelectionValue;
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsCountBalance.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedGoods.CountBalance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("SelectedGoods.NumberOfPackages");

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsCountBalance.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedGoods.CountBalance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("SelectedGoods.NumberOfPackages");

	Item.Appearance.SetParameterValue("TextColor", WebColors.Green);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsCountBalance.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedGoods.CountBalance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("SelectedGoods.NumberOfPackages");

	Item.Appearance.SetParameterValue("TextColor", WebColors.Blue);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsNumberInReport.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedGoods.NumberInReport");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("SelectedGoods.NumberOfPackages");
	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsNumberInReport.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedGoods.NumberInReport");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("SelectedGoods.NumberOfPackages");
	Item.Appearance.SetParameterValue("TextColor", WebColors.Green);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsNumberInReport.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedGoods.NumberInReport");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("SelectedGoods.NumberOfPackages");
	Item.Appearance.SetParameterValue("TextColor", WebColors.Blue);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsQuantityInOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedGoods.QuantityInOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("SelectedGoods.NumberOfPackages");

	Item.Appearance.SetParameterValue("TextColor", WebColors.FireBrick);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsQuantityInOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedGoods.QuantityInOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("SelectedGoods.NumberOfPackages");

	Item.Appearance.SetParameterValue("TextColor", WebColors.Green);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsQuantityInOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedGoods.QuantityInOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("SelectedGoods.NumberOfPackages");

	Item.Appearance.SetParameterValue("TextColor", WebColors.Blue);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsSalesOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedGoods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsSalesOrder.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsRowCode.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsQuantityInOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ByOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsNumberInProgress.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedGoodsQuantityIsCollected.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AdvancedWarehousingOnShipment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "SelectedGoodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "SelectedGoods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
EndProcedure

&AtServer
Procedure FillInSelectionListForBalances()
	
	ResidueModesAvailableValues = New ValueList;
	
	If ByOrder Then
		ResidueModesAvailableValues.Add("AllOrdered", NStr("vi = 'Tất cả đơn đặt hàng';
															|ru = 'Все заказанные';
															|en = 'All ordered'; fa = 'همه موارد سفارش‌داده‌شده';
															|it = 'Tutti ordinati';
															|pl = 'Wszystkie zamówione';
															|tr = 'Tüm siparişler'"));
		ResidueModesAvailableValues.Add("ByReport", NStr("vi = 'Theo báo cáo';
														|ru = 'По отчету';
														|en = 'By report'; fa = 'بر اساس گزارش';
														|it = 'Per report';
														|pl = 'Wg raportu';
														|tr = 'Rapora göre'"));
		If AdvancedWarehousingOnShipment Then
			ResidueModesAvailableValues.Add("ByNote", NStr("vi = 'Theo đơn';
															|ru = 'По ордеру';
															|en = 'By note'; fa = 'بر اساس یادداشت';
															|it = 'Per ordine';
															|pl = 'Według zlecenia wydania';
															|tr = 'Siparişlere ilişkin'"));
		EndIf;
	Else
		ResidueModesAvailableValues.Add("ByBalance", NStr("vi = 'Tất cả có sẵn';
															|ru = 'Все доступные';
															|en = 'All available'; fa = 'All available';
															|it = 'Tutti disponibili';
															|pl = 'Wszystkie dostępne';
															|tr = 'Hepsi mevcut'"));
		ResidueModesAvailableValues.Add("ByReport", NStr("vi = 'Theo báo cáo';
														|ru = 'По отчету';
														|en = 'By report'; fa = 'بر اساس گزارش';
														|it = 'Per report';
														|pl = 'Wg raportu';
														|tr = 'Rapora göre'"));
		If AdvancedWarehousingOnShipment Then
			ResidueModesAvailableValues.Add("ByNote", NStr("vi = 'Theo đơn';
															|ru = 'По ордеру';
															|en = 'By note'; fa = 'بر اساس یادداشت';
															|it = 'Per ordine';
															|pl = 'Według zlecenia wydania';
															|tr = 'Siparişlere ilişkin'"));
		EndIf;
	EndIf;	
		
	Items.BalanceMode.ChoiceList.Clear();
		
	For Each ResidueModeValue In ResidueModesAvailableValues Do
		Items.BalanceMode.ChoiceList.Add(ResidueModeValue.Value, ResidueModeValue.Presentation);
	EndDo;
	
	If ResidueModesAvailableValues.Count() = 1 Then
		Items.BalanceMode.Visible = False;
		BalanceMode = ResidueModesAvailableValues.Get(0).Value;
	Else
		UploadFormSettingsToServer(ResidueModesAvailableValues);
	EndIf;
	
EndProcedure

&AtServer
Procedure UploadFormSettingsToServer(ResidueModesAvailableValues)
	
	ObjectKey             = "ShipmentOfGoodsFromStorage_FormOfSelectionOfGoodsByPurchaseForPrincipal";
	SettingResidueMode = Common.CommonSettingsStorageLoad(ObjectKey, "");
	
	If SettingResidueMode = Undefined Then
		BalanceMode = ResidueModesAvailableValues.Get(0).Value;
	Else
		
		ModeValue = ResidueModesAvailableValues.FindByValue(SettingResidueMode);
		
		If ModeValue <> Undefined Then
			BalanceMode = ModeValue.Value;
		Else
			BalanceMode = ResidueModesAvailableValues.Get(0).Value;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillWarehousesAdjustVisibility()
	
	If TypeOf(Warehouse) = Type("CatalogRef.Warehouses")
		And Catalogs.Warehouses.IsFolder(Warehouse) Then
		
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
		
		Query.SetParameter("Warehouse", Warehouse);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		
		While Selection.Next() Do
			Warehouses.Add(Selection.Warehouse);
		EndDo;
		
	ElsIf ValueIsFilled(Warehouse) Then
		Warehouses.Add(Warehouse);
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveFormSettingsOnServer()
	
	ObjectKey = "ShipmentOfGoodsFromStorage_FormOfSelectionOfGoodsByPurchaseForPrincipal";
	
	Common.CommonSettingsStorageSave(ObjectKey, "", BalanceMode);
	
EndProcedure

&AtServer
Function GoodsAddressInStorage()
	
	Filter = New Structure("Check", True);
	SelectedGoodItems      = SelectedGoods.Unload(Filter);
	
	Result = New Structure;
	Result.Insert("Goods", SelectedGoodItems);

	// generating stamp data (if any) for uploading to a document
	PackageBarcodes = TableOfBarcodesOfPackages.Unload(New Array);
	
	
	Result.Insert("PackageBarcodes", PackageBarcodes);
	
	Return PutToTempStorage(Result, UUID);
	
EndFunction

&AtServer
Function AllowResultsToBeTransferredToDocument()
	
	Cancel = False;
	
	Filter = New Structure("Check", True);
	TaggedProducts = SelectedGoods.FindRows(Filter); // Array of LineOfATabularSection
	SelectedOrders = New Array();
	
	For Each RowOfGoods In TaggedProducts Do
		
		If RowOfGoods.NumberOfPackages = 0 Then
			MessageText = NStr("vi = 'Cột ""Số lượng trong lô hàng sau"" không được điền vào số dòng %LineNumber%';
								|ru = 'Не заполнена колонка ""Количество в отгрузке после"" в строке номер %LineNumber%';
								|en = '""Quantity in shipment"" column is not filled in the line number %LineNumber%'; fa = '""Quantity in shipment"" column is not filled in the line number %LineNumber%';
								|it = 'La colonna ""Quantità in spedizione dopo"" non è compilata alla riga numero %LineNumber%';
								|pl = 'Nie wypełniono kolumny ""Ilość w wysyłce po"" w wierszu numer %LineNumber%';
								|tr = '%LineNumber%sayılı satırdaki ""Sevkiyat sonrası miktar"" sütunu doldurulmamış '");
			MessageText = StrReplace(MessageText, "%LineNumber%", RowOfGoods.LineNumber);
			
			Field = CommonClientServer.PathToTabularSection("SelectedGoods", RowOfGoods.LineNumber, "NumberOfPackages");
			
			Common.MessageToUser(MessageText, Undefined, Field, "", Cancel);
		EndIf;
		
		If ByOrder
			And SelectedOrders.Find(RowOfGoods.SalesOrder) = Undefined Then
			SelectedOrders.Add(RowOfGoods.SalesOrder);
		EndIf;
		
	EndDo;
	
	If ByOrder
		And Not UseSaleByMultipleOrders
		And SelectedOrders.Count() > 1 Then
		MessageText =  NStr("vi = 'Lô hàng cho một số lệnh bị cấm. Bạn phải chọn hàng hóa hoặc làm việc cho một lệnh.';
							|ru = 'Запрещена отгрузка по нескольким заказам. Необходимо выбрать товары или работы по одному заказу.';
							|en = 'Shipment on several orders is prohibited. You should select products or works by one order.'; fa = 'Shipment on several orders is prohibited. You should select products or works by one order.';
							|it = 'La spedizioni per più ordini non è consentita. è necessario selezionare merci o lavori per un solo ordine.';
							|pl = 'Jest zabroniona wysyłka wg kilku zamówień. Należy wybrać wiersze pozycji lub prace wg jednego zamówienia.';
							|tr = 'Birden fazla sipariş için bir sevkiyata izin verilmez. Ürün veya işleri her sipariş için ayrı seçmelisiniz.'");
		Common.MessageToUser(MessageText, Undefined, Field, "", Cancel);
	EndIf;
	Return Not Cancel;
	
EndFunction

&AtServer
Procedure UpdateAtServer()
	
	SelectedGoods.Clear();
	FillInProductsTable_();
	
EndProcedure

&AtServer
Procedure CreateInformationLabelSelections()

	If Not TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		InformationLabelSelections = NStr("vi = 'Lọc theo: %Organization%, %Partner%, %Contract%, %Warehouse%';
											|ru = 'Отбор по: %Organization%, %Partner%, %Contract%, %Warehouse%';
											|en = 'Filter by: %Organization%, %Partner%, %Contract%, %Warehouse%'; fa = 'Filter by: %Organization%, %Partner%, %Contract%, %Warehouse%';
											|it = 'Selezione per: %Organization%, %Partner%, %Contract%, %Warehouse%';
											|pl = 'Filtr według: %Organization%, %Partner%, %Contract%, %Warehouse%';
											|tr = 'Filtre: %Organization%, %Partner%, %Contract%, %Warehouse%'");
	Else
		InformationLabelSelections = NStr("vi = 'Lọc theo: %Contract%, %Warehouse%';
											|ru = 'Отбор по: %Contract%, %Warehouse%';
											|en = 'Filter by: %Contract%, %Warehouse%'; fa = 'Filter by: %Contract%, %Warehouse%';
											|it = 'Selezione per: %Contract%, %Warehouse%';
											|pl = 'Filtr według: %Contract%, %Warehouse%';
											|tr = 'Seçim:%Contract%,%Warehouse%'");
	EndIf;
	
	If Warehouses.Count() > 1 Then
		LabelWarehouse = NStr("vi = 'nhóm kho bãi: ""%Warehouse%""';
								|ru = 'группе складов: ""%Warehouse%""';
								|en = 'warehouse group: ""%Warehouse%""'; fa = 'warehouse group: ""%Warehouse%""';
								|it = 'gruppo di magazzini: ""%Warehouse%""';
								|pl = 'grupie magazynów: ""%Warehouse%""';
								|tr = 'depo grubu: ""%Warehouse%""'");
		LabelWarehouse = StrReplace(LabelWarehouse, "%Warehouse%", Warehouse);
	Else
		LabelWarehouse = "";
	EndIf;
		
	InformationLabelSelections = StrReplace(InformationLabelSelections, "%Organization%", Organization);
	InformationLabelSelections = StrReplace(InformationLabelSelections, "%Partner%",     Partner);
	InformationLabelSelections = StrReplace(InformationLabelSelections, "%Contract%",     Contract);
	InformationLabelSelections = StrReplace(InformationLabelSelections, "%Warehouse%",       LabelWarehouse);
	
	If Right(InformationLabelSelections, 2) = ", " Then
		InformationLabelSelections = Left(InformationLabelSelections, StrLen(InformationLabelSelections) - 2);
	EndIf;
	
	InformationLabelSelections = InformationLabelSelections + ".";

EndProcedure

&AtServer
Procedure SetVisibilityByOrders()

	If ByOrder Then
		UpdateOrderInformation(SelectedGoods);
	Else
		Items.PagesOrder.Visible = False;
	EndIf;

EndProcedure	

&AtServer
Procedure UpdateOrderInformation(GoodsSales_)

	ParametersOfUpdate = OrdersServer.ParametersForUpdatingOrderInformationInForm();
	
	ParametersOfUpdate.PropsNameOrderList         = "SalesOrders";
	ParametersOfUpdate.OrderPathInHeader                  = "SalesOrder";
	ParametersOfUpdate.TitleLabelName               = "LabelHeaderSalesOrders";
	ParametersOfUpdate.OrderNameInTablePart          = "SalesOrder";
	ParametersOfUpdate.UseOrdersInTabularSection = True;
	
	OrdersServer.UpdateOrderInformationInForm(ThisForm, GoodsSales_, ParametersOfUpdate);

EndProcedure

&AtClient
Procedure SetQuantityByMode(CurrentRow)

	If BalanceMode = "ByReport" Then
		CurrentRow.NumberOfPackages = CurrentRow.NumberInReport;
	ElsIf BalanceMode = "AllOrdered" Then
		CurrentRow.NumberOfPackages = CurrentRow.QuantityInOrder;
	ElsIf BalanceMode = "ByNote" Then
		CurrentRow.NumberOfPackages = CurrentRow.QuantityIsCollected;
	ElsIf BalanceMode = "ByBalance" Then
		CurrentRow.NumberOfPackages = CurrentRow.CountBalance;
	EndIf;
	
	If CurrentRow.NumberOfPackages > 0 
		And CurrentRow.NumberOfPackages <> CurrentRow.QuantityInInvoice Then
		CurrentRow.Check = True;
	Else
		CurrentRow.Check = False;
	EndIf;

	CalculateSumAndQuantityForCurRow(CurrentRow);

EndProcedure

&AtClient
Procedure CalculateRowSum(CurrentRow)
	
	RecalculateAmount_ = ?(CurrentRow.DocumentQuantity = CurrentRow.NumberOfPackages, False, True);
	If Not RecalculateAmount_ Then
		CurrentRow.Sum = CurrentRow.DocumentAmount;
	EndIf;
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, RecalculateAmount_);
	CachedValues = Undefined;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure CalculateSumAndQuantityForCurRow(CurrentRow)
	
	CalculateRowSum(CurrentRow);
	If Not CurrentRow.ThereIsAManualChange Then
		If BalanceMode = "ByReport" Then
			CurrentRow.LeftToSelect = CurrentRow.NumberInReport - CurrentRow.NumberOfPackages;
		ElsIf BalanceMode = "AllOrdered" Then
			CurrentRow.LeftToSelect = CurrentRow.QuantityInOrder - CurrentRow.NumberOfPackages;
		ElsIf BalanceMode = "ByNote" Then
			CurrentRow.LeftToSelect = CurrentRow.QuantityIsCollected - CurrentRow.NumberOfPackages;
		EndIf;
	EndIf;
	
	Filter = New Structure("Check", True);
	MarkedLines_ = SelectedGoods.FindRows(Filter);
	
	GoodsAreSelected = MarkedLines_.Count() > 0;

EndProcedure

&AtServer
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, RecalculateAmount_ = True)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	If RecalculateAmount_ Then
		StructureOfActions.Insert("RecalculateAmount");
	EndIf;
	
EndProcedure

&AtClient
Procedure InformationAboutOrdersClick(Item, StandardProcessing)

	StandardProcessing = False;
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			SalesOrders,
			NStr("vi = 'Đơn hàng của người đặt ký gửi(%DocumentsCount%)';
				|ru = 'Заказы принципала (%DocumentsCount%)';
				|en = 'Principal''s order (%DocumentsCount%)'; fa = 'Principal''s order (%DocumentsCount%)';
				|it = 'Gli ordini del mandante (%DocumentsCount%)';
				|pl = 'Zamówienia zleceniodawcy (%DocumentsCount%)';
				|tr = 'İş veren siparişi (%DocumentsCount%)'")),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure SelectedGoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.SelectedGoods.CurrentData <> Undefined Then
		If Field.Name = "SelectedGoodsSalesOrder" Then
			ShowValue(Undefined, Items.SelectedGoods.CurrentData.SalesOrder);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure ByOrdersOnChange(Item)
	FillInProductsTable_();
EndProcedure

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
