#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InvoiceGoods = GetFromTempStorage(Parameters.AddressGoods);
	
	FillInDetailsWhenCreating(InvoiceGoods);
	
	If Parameters.Property("AddressBarcodesOfPackages") Then
		BarcodesOfWaybillPackages = GetFromTempStorage(Parameters.AddressBarcodesOfPackages);
	Else
		BarcodesOfWaybillPackages = WarehousesLocalization.ToFormStructureOfBarcodesOfWaybillPackages();
	EndIf;
	
	FillInTheGoodsTable(InvoiceGoods, BarcodesOfWaybillPackages);
	
	SetRowSelection();
	
	CustomizeFormElementsWhenCreating();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If Not ClosingInProgress And Modified Then
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject),
		NStr("vi = 'Dữ liệu bị thay đổi. Đưa các thay đổi vào chứng từ?';
			|ru = 'Данные были изменены. Перенести изменения в документ?';
			|en = 'The data was modified. Migrate the changes to the document?'; fa = 'The data was modified. Migrate the changes to the document?';
			|it = 'I dati sono stati modificati. Trasferire le modifiche nel documento?';
			|pl = 'Dane zostały zmienione. Przenieść zmiany do dokumentu?';
			|tr = 'Veriler değiştirildi. Değişiklikler belgeye aktarılsın mı?'"), QuestionDialogMode.YesNoCancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		ClosingInProgress = True;
		MoveLinesToDocument();
		
	ElsIf QuestionResult = DialogReturnCode.No Then
		
		Modified = False;
		ClosingInProgress = True;
		Close();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ByNoteOnChange(Item)
	
	CalculateIndicatorOfQuantityRow();
	
EndProcedure

&AtClient
Procedure ByOrderOnChange(Item)
	
	ByOrdersOnChangeServer();
	
EndProcedure

&AtClient
Procedure HeaderOrdersTextClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	If ThisIsShipmentWithoutTransferOfOwnership2_5 Or ThisIsShipmentOfGoodsToCustomer Then
		OrderListHeader = NStr("vi = 'Lệnh (%DocumentsCount%)';
								|ru = 'Распоряжения (%DocumentsCount%)';
								|en = 'References (%DocumentsCount%)'; fa = 'References (%DocumentsCount%)';
								|it = 'Disposizioni (%DocumentsCount%)';
								|pl = 'Zamówienia (%DocumentsCount%)';
								|tr = 'Talimatlar (%DocumentsCount%)'");
	Else
		OrderListHeader = NStr("vi = 'Đơn hàng (%DocumentsCount%)';
								|ru = 'Заказы (%DocumentsCount%)';
								|en = 'Orders (%DocumentsCount%)'; fa = 'Orders (%DocumentsCount%)';
								|it = 'Ordini (%DocumentsCount%)';
								|pl = 'Zamówienia (%DocumentsCount%)';
								|tr = 'Siparişler (%DocumentsCount%)'");
	EndIf;
	FormParameters = New Structure("DocumentsList, Title", ListOfOrders_, OrderListHeader);
	
	OpenForm("CommonForm.ViewingListOfDocuments", FormParameters, ThisObject, UUID,,,
		Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsTable

&AtClient
Procedure GoodsTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.GoodsTable.CurrentData <> Undefined Then
		
		If Field.Name = "OrderDocument"
			And ValueIsFilled(Items.GoodsTable.CurrentData.OrderDocument) Then
			ShowValue(Undefined, Items.GoodsTable.CurrentData.OrderDocument);
		ElsIf Field.Name = "SalesOpportunity"
			And ValueIsFilled(Items.GoodsTable.CurrentData.SalesOpportunity) Then
			ShowValue(Undefined, Items.GoodsTable.CurrentData.SalesOpportunity);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectRows(Command)

	MarkLines(True);

EndProcedure

&AtClient
Procedure ClearRows(Command)

	MarkLines(False);

EndProcedure

&AtClient
Procedure MoveToDocument(Command)

	MoveLinesToDocument();

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "UnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "GoodsTable.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrderDocument.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsTable.OrderDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PackagingQuantityInTheOrder.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ByNote");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.BackgroundColorIsFullyProvided);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PackagingQuantityInTheNote.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ByNote");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.BackgroundColorIsFullyProvided);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.NumberOfPackages.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsTable.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GoodsTable.RowIsSelected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<xóa bỏ>';
													|ru = '<удалить>';
													|en = '<delete>'; fa = '<delete>';
													|it = '<cancellare>';
													|pl = '<delete>';
													|tr = '<sil>'"));

EndProcedure

&AtServer
Procedure FillInDetailsWhenCreating(InvoiceGoods)
	
	// Requisites.
	UseInvoicesForSeveralOrders = Parameters.UseInvoicesForSeveralOrders;
	UseAdvancedWarehousing                = Parameters.AdvancedWarehousingOnShipment Or Parameters.AdvancedWarehousingOnGoodsReceipt;
	OrdersUse                       = Parameters.OrdersAreUsed;
	
	Invoice             = Parameters.Invoice;
	OrderDocument                 = Parameters.OrderDocument;
	ByOrders             = Parameters.InvoiceForOrders;
	InvoiceManagerName = Metadata.FindByType(TypeOf(Invoice)).Name;
	FieldNameOrder          = Documents[InvoiceManagerName].DocumentFillingParameters().FieldNameOrder;
	AdditionalFields    = ?(Parameters.AdditionalFields = Undefined, New Structure, Parameters.AdditionalFields);
	
	ThisIsShipmentOfGoodsToCustomer = TypeOf(Invoice) = Type("DocumentRef.GoodsShipmentToCustomer");
	ThisIsShipmentWithoutTransferOfOwnership2_5 =
		TypeOf(Invoice) = Type("DocumentRef.WriteOffOfShippedGoods")
			Or TypeOf(Invoice) = Type("DocumentRef.GoodsReceiptFromCustomer")
			Or TypeOf(Invoice) = Type("DocumentRef.RecognitionOfStockSurplusShippedToCustomer");
	
	If Parameters.AdvancedWarehousingOnShipment Then
		ByNote = Not ByOrders Or (Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get()
			= Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst);
	ElsIf Parameters.AdvancedWarehousingOnGoodsReceipt Then
		ByNote = Not ByOrders;
	Else
		ByNote = False;
	EndIf;
	
	UpdateOrderInformationInForm(InvoiceGoods);
	
	SetFormHeaders();
	
	SelectGoodsClientServer.CreateSelectionFormHeader(Title, Invoice);
	
	WarehousesLocalization.AddMarkingAttributes(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInTheGoodsTable(InvoiceGoods, BarcodesOfWaybillPackages)
	
	InvoiceManager = Documents[InvoiceManagerName];
	
	GoodsOfInvoiceColumn = InvoiceGoods.Columns;		// ValueTableColumnCollection
	GoodsOfInvoiceColumn.Add("QuantityInInvoice", New TypeDescription("Number"));
	GoodsOfInvoiceColumn.Add("PackagingQuantityInInvoice", New TypeDescription("Number"));
	GoodsOfInvoiceColumn.Add("ExistsInTheDocument", New TypeDescription("Boolean"));
	
	For Each String In InvoiceGoods Do
		String.QuantityInInvoice = String.Count;
		String.PackagingQuantityInInvoice = String.NumberOfPackages;
		String.ExistsInTheDocument = True;
	EndDo;
	
	If UseInvoicesForSeveralOrders Then
		// We get a complete list of suitable orders
		AnArrayOfOrders = InvoiceManager.WaybillOrders(Invoice, Parameters.HeaderAttributes);
	Else
		AnArrayOfOrders = New Array();
		AnArrayOfOrders.Add(OrderDocument);
		AnArrayOfOrders.Add(Invoice);
	EndIf;
	
	FillParameters = InvoiceManager.DocumentFillingParameters();
	FillParameters.Insert("FillByWarehouseDocument", UseAdvancedWarehousing);
	If Parameters.FillInResources <> Undefined Then
		FillParameters.Insert("Resources", Parameters.FillInResources);
	EndIf;
	InvoiceManager.InitializeFillingParameters(FillParameters, Parameters.HeaderAttributes, AnArrayOfOrders);
	
	InvoiceManager.FillInByOrdersOrders(InvoiceGoods, Invoice, FillParameters, TableOfBarcodesOfPackages);
	
	AddressInvoiceGoods = PutToTempStorage(InvoiceGoods.Copy(), UUID);
	
	If GoodsOfInvoiceColumn.Find(FieldNameOrder) <> Undefined Then
		GoodsOfInvoiceColumn[FieldNameOrder].Name = "OrderDocument";
	EndIf;
	
	GoodsTable.Load(InvoiceGoods);
	For IndexOf = 0 To GoodsTable.Count() - 1 Do
		GoodsTable[IndexOf].InvoiceGoodsIndex = IndexOf;
	EndDo;
	
	WarehousesLocalization.DistributeStamps(BarcodesOfWaybillPackages, TableOfBarcodesOfPackages, GoodsTable);
	DeleteRowsWithoutDeviations();
	RecalculateNumberOfPackages();
	CalculateIndicatorOfQuantityRow();
	
EndProcedure

&AtServer
Procedure DeleteRowsWithoutDeviations()
	
	RowsCount = GoodsTable.Count();
	For Counter = 1 To RowsCount Do
		
		TableRow = GoodsTable[RowsCount - Counter];
		
		OrderInvoice = TypeOf(TableRow.OrderDocument) = TypeOf(Invoice);
		
		ThereAreNoDeviations = OrderInvoice
			Or TableRow.QuantityInOrder = 0
			Or TableRow.QuantityInInvoice = TableRow.QuantityInOrder;
		
		NoDeviationsOrder = Not UseAdvancedWarehousing Or TableRow.QuantityInInvoice = TableRow.NoteQuantity;
		NoDeviations = ThereAreNoDeviations And NoDeviationsOrder;
		
		If NoDeviations Then
			GoodsTable.Delete(RowsCount - Counter);
			Continue;
		EndIf;
		
		If OrderInvoice Then
			TableRow.OrderDocument = Undefined;
		EndIf;
		
		If TableRow.OrderDocument = OrderDocument Or ListOfOrders_.FindByValue(TableRow.OrderDocument) <> Undefined Then
			TableRow.OrderFromInvoice = True;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfPackages()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateNumberOfSuffixPacks");
	
	For Each String In GoodsTable Do
		
		StructureOfActions.RecalculateNumberOfSuffixPacks = "InOrder";
		BatchProcessingOfTablePartClientServer.RecalculateNumberOfSuffixPacksInTSString(String,
			StructureOfActions, CachedValues);
		
		StructureOfActions.RecalculateNumberOfSuffixPacks = "AssemblyInProgress";
		BatchProcessingOfTablePartClientServer.RecalculateNumberOfSuffixPacksInTSString(String,
			StructureOfActions, CachedValues);
		
		StructureOfActions.RecalculateNumberOfSuffixPacks = "InNote";
		BatchProcessingOfTablePartClientServer.RecalculateNumberOfSuffixPacksInTSString(String,
			StructureOfActions, CachedValues);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CalculateIndicatorOfQuantityRow()
	
	For Each CurrentRow In GoodsTable Do
		CurrentRow.NumberOfPackages = ?(ByNote, CurrentRow.PackagingQuantityInTheNote, CurrentRow.PackagingQuantityInTheOrder);
		CurrentRow.Count = ?(ByNote, CurrentRow.NoteQuantity, CurrentRow.QuantityInOrder);
		
		CurrentRow.RowIsSelected = (CurrentRow.NumberOfPackages <> CurrentRow.PackagingQuantityInInvoice)
			And (CurrentRow.OrderFromInvoice And ByOrders Or Not ByOrders);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CustomizeFormElementsWhenCreating()
	
	InvoiceManager = Documents[InvoiceManagerName];
	
	// form element.
	Items.ByNote.Visible			= OrdersUse And UseAdvancedWarehousing;
	Items.PagesOrder.Visible	= OrdersUse And Parameters.InvoiceForOrders
		And UseInvoicesForSeveralOrders;
	If Not Parameters.AdvancedWarehousingOnShipment Then
		Items.ByNote.EditFormat = NStr("vi = 'BF=''Tất cả đã ra lệnh''; BT=''Tất cả được chấp nhận''';
										|ru = 'БЛ=''Все заказанные''; БИ=''Все принятые''';
										|en = 'BF=''All ordered''; BT=''All received'''; fa = 'BF=''همه سفارش‌داده‌شده''; BT=''همه دریافت‌شده''';
										|it = 'BF=''Tutti ordinati''; BT=''tutti accettati''';
										|pl = 'BF=''Wszyscy zamówione''; BT=''Wszyscy zaakceptowani''';
										|tr = 'BL=''Tüm siparişler''; BI=''Tümü kabul edildi'''");
	EndIf;
	
	// Elements of the product table.
	For Each AdditionalField_ In AdditionalFields Do
		FormItem = Items[AdditionalField_.Key]; // FormField -
		FormItem.Visible = True;
		If ValueIsFilled(AdditionalField_.Value) Then
			FormItem.Title = AdditionalField_.Value;
		EndIf;
	EndDo;
	
	ObjectParameters = New Structure(InvoiceManager.NamesOfDetailsForFillingInParametersForSpecifyingSeries());
	FillPropertyValues(ObjectParameters, Parameters.HeaderAttributes);
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ObjectParameters, InvoiceManager);
	
	If SeriesSpecificationParameters.Property("UseItemsBatch") Then
		Items.Series.Visible = SeriesSpecificationParameters.UseItemsBatch;
	ElsIf SeriesSpecificationParameters.Property("TS") Then
		Items.Series.Visible = SeriesSpecificationParameters.TS.UseItemsBatch
												Or SeriesSpecificationParameters.Header.UseItemsBatch;
	EndIf;
	
	Items.PackagingQuantityInTheNote.Visible    = UseAdvancedWarehousing;
	Items.NumberOfPackagesCollected.Visible = UseAdvancedWarehousing;
	
	Items.PackagingQuantityInTheOrder.Visible    = OrdersUse;
	Items.OrderDocument.Visible                        = OrdersUse;
	Items.RowCode.Visible                    = OrdersUse;
	
	ThereAreGatheringGoods = GoodsTable.Total("NumberInProgress") > 0;
	Items.InfoDecoration.Visible = ThereAreGatheringGoods;
	Items.DecorationInformationThereAreCollectedGoods.Visible = ThereAreGatheringGoods;
	
EndProcedure

&AtServer
Procedure UpdateOrderInformationInForm(InvoiceGoods)
	
	If Not UseInvoicesForSeveralOrders Then
		Return;
	EndIf;
	
	ListOfOrders_.Clear();
	For Each CurRow In InvoiceGoods Do
		If ValueIsFilled(CurRow[FieldNameOrder]) And ListOfOrders_.FindByValue(CurRow[FieldNameOrder]) = Undefined Then
			ListOfOrders_.Add(CurRow[FieldNameOrder]);
		EndIf;
	EndDo;
	
	If UseInvoicesForSeveralOrders Then
		If ListOfOrders_.Count() = 1 Then
			OrderDocument = ListOfOrders_[0].Value;
		ElsIf ListOfOrders_.Count() > 1 Then
			OrderDocument = Undefined;
		EndIf;
	EndIf;
	
	If ListOfOrders_.Count() > 1 Then
		If ThisIsShipmentWithoutTransferOfOwnership2_5 Or ThisIsShipmentOfGoodsToCustomer Then
			LabelTotalOrders = NStr("vi = 'Tổng số lệnh';
									|ru = 'Всего распоряжений';
									|en = 'Total references'; fa = 'Total references';
									|it = 'Totale disposizioni';
									|pl = 'Łącznie zamówień';
									|tr = 'Toplam emirler'");
		Else
			LabelTotalOrders = NStr("vi = 'Tổng số đơn hàng';
									|ru = 'Всего заказов';
									|en = 'Total orders'; fa = 'Total orders';
									|it = 'Ordini in tutto';
									|pl = 'Łącznie zamówień';
									|tr = 'Toplam siparişler'");
		EndIf;
		HeaderOrdersText = LabelTotalOrders + ": " + ListOfOrders_.Count();
	EndIf;
	
	If ListOfOrders_.Count() <= 1 Then
		Items.PagesOrder.CurrentPage = Items.PageOrder;
	Else
		Items.PagesOrder.CurrentPage = Items.OrdersPage;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFormHeaders()
	
	If ThisIsShipmentWithoutTransferOfOwnership2_5 Then
		Title = NStr("vi = 'Chọn hàng hóa theo lệnh';
					|ru = 'Подбор товаров по распоряжениям';
					|en = 'Pick goods by references'; fa = 'Pick goods by references';
					|it = 'Pick goods by references';
					|pl = 'Pick goods by references';
					|tr = 'Siparişlere göre ürünlerin seçimi'");
	ElsIf ThisIsShipmentOfGoodsToCustomer And OrdersUse And UseAdvancedWarehousing Then
		Title = NStr("vi = 'Chọn hàng hóa theo lệnh/phiếu';
					|ru = 'Подбор товаров по распоряжениям/ордерам';
					|en = 'Pick goods by references/notes'; fa = 'انتخاب کالا بر اساس مراجع/حواله‌ها';
					|it = 'Pick goods by references/notes';
					|pl = 'Pick goods by references/notes';
					|tr = 'Siparişlere/talimatlara göre ürün seçimi'");
	ElsIf ThisIsShipmentOfGoodsToCustomer And OrdersUse Then
		Title = NStr("vi = 'Chọn hàng hóa theo lệnh';
					|ru = 'Подбор товаров по распоряжениям';
					|en = 'Pick goods by references'; fa = 'Pick goods by references';
					|it = 'Pick goods by references';
					|pl = 'Pick goods by references';
					|tr = 'Siparişlere göre ürünlerin seçimi'");
	ElsIf OrdersUse And UseAdvancedWarehousing Then
		Title = NStr("vi = 'Chọn hàng theo đơn/phiếu';
					|ru = 'Подбор товаров по заказу/ордерам';
					|en = 'Pick goods by order/notes'; fa = 'Pick goods by order/notes';
					|it = 'Selezione delle merci secondo gli ordini/mandati';
					|pl = 'Wybór towarów wg zamówienia/zleceń';
					|tr = 'Siparişe/emre göre ürünlerin seçimi'");
	ElsIf OrdersUse Then
		Title = NStr("vi = 'Chọn hàng theo đơn';
					|ru = 'Подбор товаров по заказу';
					|en = 'Pick goods against order'; fa = 'Pick goods against order';
					|it = 'Selezione delle merci secondo gli ordini';
					|pl = 'Wybór towarów wg zamówienia';
					|tr = 'Siparişe göre ürünlerin seçimi'");
	Else
		Title = NStr("vi = 'Lựa chọn hàng hóa theo lệnh';
					|ru = 'Подбор товаров по ордерам';
					|en = 'Pick goods by notes'; fa = 'انتخاب کالا بر اساس حواله‌ها';
					|it = 'Selezione delle merci per mandati';
					|pl = 'Wybór towarów wg zleceń';
					|tr = 'Emire göre ürünlerin seçimi'");
	EndIf;
	
	If ThisIsShipmentWithoutTransferOfOwnership2_5 Or ThisIsShipmentOfGoodsToCustomer Then
		Items.ByOrder.Title = NStr("vi = 'Chỉ lệnh đã chọn trong hóa đơn';
									|ru = 'Только распоряжение, уже выбранное в накладной';
									|en = 'Only the reference already selected in the invoice'; fa = 'Only the reference already selected in the invoice';
									|it = 'Only the reference already selected in the invoice';
									|pl = 'Only the reference already selected in the invoice';
									|tr = 'Sadece irsaliyede halihazırda seçilmiş talimat'");
		Items.ByOrders.Title = NStr("vi = 'Chỉ lệnh đã chọn trong hóa đơn';
									|ru = 'Только распоряжения, уже выбранные в накладной';
									|en = 'Only the references already selected in the invoice'; fa = 'Only the references already selected in the invoice';
									|it = 'Only the references already selected in the invoice';
									|pl = 'Only the references already selected in the invoice';
									|tr = 'Yalnızca faturada seçili olan talimatlar'");
		Items.OrderDocument.Title = NStr("vi = 'Lệnh';
										|ru = 'Распоряжение';
										|en = 'Reference'; fa = 'مرجع';
										|it = 'Reference';
										|pl = 'Reference';
										|tr = 'Sipariş'");
	Else
		Items.ByOrder.Title = NStr("vi = 'Chỉ đơn hàng đã được chọn trên hóa đơn';
									|ru = 'Только заказ, уже выбранный в накладной';
									|en = 'Only order already selected in the invoice'; fa = 'فقط سفارشی که قبلاً در فاکتور انتخاب شده';
									|it = 'Solo l''ordine già selezionato nei documenti di trasporto';
									|pl = 'Tylko zamówienie, już wybrane w fakturze';
									|tr = 'Yalnızca irsaliyede seçili olan sipariş'");
		Items.ByOrders.Title = NStr("vi = 'Chỉ những đơn hàng đã được chọn trên hóa đơn';
									|ru = 'Только заказы, уже выбранные в накладной';
									|en = 'Only orders already selected in the invoice'; fa = 'فقط سفارش‌هایی که قبلاً در فاکتور انتخاب شده‌اند';
									|it = 'Solo gli ordini già selezionati nei documenti di trasporto';
									|pl = 'Tylko zamówienia, już wybrane w fakturze';
									|tr = 'Yalnızca irsaliyede seçili olan siparişler'");
		Items.OrderDocument.Title = NStr("vi = 'Đơn hàng';
										|ru = 'Заказ';
										|en = 'Order'; fa = 'سفارش';
										|it = 'Order';
										|pl = 'Order';
										|tr = 'Sipariş'");
	EndIf;
	
	If ThisIsShipmentWithoutTransferOfOwnership2_5 Then
		Items.PackagingQuantityInTheOrder.Title = NStr("vi = 'Hàng đi đường';
														|ru = 'В пути';
														|en = 'In transit'; fa = 'در راه';
														|it = 'В пути';
														|pl = 'W drodze';
														|tr = 'Nakil halinde'");
	ElsIf ThisIsShipmentOfGoodsToCustomer Then
		Items.PackagingQuantityInTheOrder.Title = NStr("vi = 'Trong lệnh';
														|ru = 'В распоряжении';
														|en = 'In the reference'; fa = 'In the reference';
														|it = 'In the reference';
														|pl = 'In the reference';
														|tr = 'Talimatta'");
	Else
		Items.PackagingQuantityInTheOrder.Title = NStr("vi = 'Trong đơn hàng';
														|ru = 'В заказе';
														|en = 'In order'; fa = 'در سفارش';
														|it = 'Nell''ordine';
														|pl = 'W zamówieniu';
														|tr = 'Siparişte'");
	EndIf;
	
EndProcedure

&AtServer
Function PutProductsInStorage()
	
	InvoiceGoods = GetFromTempStorage(AddressInvoiceGoods);
	
	Goods = InvoiceGoods.CopyColumns();//ValueTable
	Goods.Columns.Add("UnlinkFromOrder");
	
	// generating stamp data (if any) for uploading to a document
	PackageBarcodes = TableOfBarcodesOfPackages.Unload(New Structure("UploadToDocument", True));
	
	For Each String In GoodsTable Do
		If String.RowIsSelected Then
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, InvoiceGoods[String.InvoiceGoodsIndex]);
			NewRow.NumberOfPackages = String.NumberOfPackages;
			NewRow.Count         = String.Count;
			NewRow.UnlinkFromOrder   = String.QuantityInOrder = 0;
			
			
		EndIf;
	EndDo;
	
	Return PutToTempStorage(New Structure("Goods, PackageBarcodes", Goods, PackageBarcodes));
	
EndFunction

&AtClient
Procedure MoveLinesToDocument()
	
	// Removal of modification, because before closing, the attribute is checked.
	Modified = False;
	
	WarningText = CheckMultipleOrderSelection();
	
	If Not IsBlankString(WarningText) Then
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	AddressInStorage = PutProductsInStorage();

	Close();

	NotifyChoice(New Structure("CurrentOperation1, AddressInStorage",
						"AddItemsFromSalesOrderGoodsIssue", AddressInStorage));
	
EndProcedure

&AtClient
Function CheckMultipleOrderSelection()
	
	If UseInvoicesForSeveralOrders Then
		
		FirstOrder_ = Undefined;
		SelectedRowWithoutOrder = False;
		If ThisIsShipmentWithoutTransferOfOwnership2_5 Or ThisIsShipmentOfGoodsToCustomer Then
			TemplateForMoreThanOneOrder = NStr("vi = 'Không thể chọn hàng hóa từ nhiều hơn một lệnh.';
												|ru = 'Нельзя выбрать товары больше, чем по одному распоряжению.';
												|en = 'Cannot select more goods than against one reference.'; fa = 'Cannot select more goods than against one reference.';
												|it = 'Cannot select more goods than against one reference.';
												|pl = 'Cannot select more goods than against one reference.';
												|tr = 'Aynı anda bir siparişten fazlasını seçemezsiniz.'");
			TemplateWithoutOrderAndByOrder = NStr("vi = 'Không thể chọn hàng hóa theo lệnh, mà không chỉ định lệnh.';
													|ru = 'Нельзя выбрать товары по распоряжению и без указания распоряжения одновременно.';
													|en = 'Cannot select goods with references and without references at the same time.'; fa = 'Cannot select goods with references and without references at the same time.';
													|it = 'Cannot select goods with references and without references at the same time.';
													|pl = 'Cannot select goods with references and without references at the same time.';
													|tr = 'Aynı anda hem sipariş edilen ürünleri, hem de sipariş edilmeyen ürünleri seçemezsiniz.'");
		Else
			TemplateForMoreThanOneOrder = NStr("vi = 'Không thể chọn hàng hóa nhiều hơn trong một đơn hàng.';
												|ru = 'Нельзя выбрать товары больше, чем по одному заказу.';
												|en = 'You cannot select more goods than against one order.'; fa = 'You cannot select more goods than against one order.';
												|it = 'Non è possibile selezionare prodotti per più di un ordine.';
												|pl = 'Nie można wybrać towarów dla więcej niż jednego zamówienia.';
												|tr = 'Bir siparişten fazla ürün seçilmemeli.'");
			TemplateWithoutOrderAndByOrder = NStr("vi = 'Không thể chọn hàng hóa theo đơn mà đồng thời không chỉ ra đơn hàng.';
													|ru = 'Нельзя выбрать товары по заказу и без указания заказа одновременно.';
													|en = 'You cannot select goods against the order and without specifying the order at the same time.'; fa = 'You cannot select goods against the order and without specifying the order at the same time.';
													|it = 'Non è possibile selezionare prodotti per l''ordine e senza specificare l''ordine allo stesso tempo.';
													|pl = 'Nie można wybrać towarów wg zamówienia i bez określenia zamówienia jednocześnie.';
													|tr = 'Siparişe göre ve aynı zamanda sipariş belirtmeden ürün seçimi yapılmamalı.'");
		EndIf;
		
		For Each LineProducts_ In GoodsTable Do
			
			If LineProducts_.RowIsSelected And LineProducts_.Count <> 0 Then
				
				If FirstOrder_ <> Undefined And LineProducts_.OrderDocument <> FirstOrder_
					And Not UseInvoicesForSeveralOrders Then
					Return TemplateForMoreThanOneOrder;
				ElsIf ValueIsFilled(LineProducts_.OrderDocument) Then
					FirstOrder_ = LineProducts_.OrderDocument;
				EndIf;
				
				If Not ValueIsFilled(LineProducts_.OrderDocument) Then
					SelectedRowWithoutOrder = True;
				EndIf;
				
				If SelectedRowWithoutOrder And FirstOrder_ <> Undefined Then
					Return TemplateWithoutOrderAndByOrder;
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return "";
	
EndFunction

&AtServer
Procedure ByOrdersOnChangeServer()
	
	SetRowSelection();
	
	For Each RowOfGoods In GoodsTable Do
		RowOfGoods.RowIsSelected = (RowOfGoods.NumberOfPackages <> RowOfGoods.PackagingQuantityInInvoice)
			And (RowOfGoods.OrderFromInvoice And ByOrders Or Not ByOrders);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetRowSelection()
	
	If ByOrders Then
		Items.GoodsTable.RowFilter = New FixedStructure("OrderFromInvoice", True);
	Else
		Items.GoodsTable.RowFilter = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure MarkLines(Value)
	
	For Each RowOfGoods In GoodsTable Do
		RowOfGoods.RowIsSelected = (RowOfGoods.OrderFromInvoice And ByOrders Or Not ByOrders) And Value;
	EndDo;
	
EndProcedure

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion
