#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CustomizeFormWhenCreatingIt();
	FillInFormDetailsWhenCreating();
	
	SeparatePurchaseOperations = PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections();
	GoodsWaybillBasicInscription = NStr("vi = 'Chênh lệch giữa hóa đơn và đơn hàng:';
										|ru = 'Расхождения между накладными и ордерами:';
										|en = 'Discrepancies between invoices and notes:'; fa = 'Discrepancies between invoices and notes:';
										|it = 'Расхождения между накладными и ордерами:';
										|pl = 'Discrepancies between invoices and notes:';
										|tr = 'İrsaliyeler ve emirler arasındaki tutarsızlıklar:'");
	
	If ValueIsFilled(BusinessOperation)
		And SeparatePurchaseOperations.Find(BusinessOperation) <> Undefined Then
		
		If ThisIsTheReceiptOfGoodsDocument Then
			CaptionInfoTitle = NStr("vi = 'Theo các lệnh được chọn đã tạo tiếp nhận. Cần điều chỉnh tiếp nhận sẵn có và có tính đến đơn đặt hàng bằng lệnh ""Điền lại đã chọn"" hoặc tạo tiếp nhận mới đối với hàng hóa chưa tạo còn lại bằng lệnh ""Tạo mới"".';
									|ru = 'По выбранным распоряжениям уже оформлены поступления. Необходимо скорректировать имеющиеся поступления с учетом ордера командой ""Перезаполнить выбранное"" или оформить новое поступление на оставшиеся неоформленными товары командой ""Оформить новое"".';
									|en = 'Incoming payments are already registered for the selected references. Adjust the incoming payments considering the note by clicking ""Refill selected one"", or register a new receipt for the remaining unregistered goods by clicking ""Register new receipt"".'; fa = 'Incoming payments are already registered for the selected references. Adjust the incoming payments considering the note by clicking ""Refill selected one"", or register a new receipt for the remaining unregistered goods by clicking ""Register new receipt"".';
									|it = 'Per disposizioni selezionate sono già stati registrati gli arrivi. È necessario rettificare gli arrivi esistenti in considerazione della lettera di vettura tramite il comando ""Ricompilare selezionato"" o registrare un nuovo arrivo per le merci rimaste non registrate tramite il comando ""Registrare nuovo"".';
									|pl = 'Dla wybranych zamówień sporządzono już wpływy. Należy skorygować istniejące wpływy z uwzględnieniem dowodu kasowego poleceniem ""Wypełnij ponownie wybrane"" lub sporządzić nowy wpływ na nie zarejestrowane wiersze pozycji poleceniem ""Sporządź nowy"".';
									|tr = 'Seçilen siparişlere göre girişler artık düzenlendi. Mevcut girişlerin ""Seçilenleri doldur"" komutu ile sipariş dikkate alınarak düzeltilmesi veya ""Yenisini düzenle"" komutu ile kayıt dışı kalan ürünler için yeni bir giriş düzenlenmesi gerekir.'");
			
			ReFillHeader = NStr("vi = 'Điền lại đã chọn';
								|ru = 'Перезаполнить выбранную';
								|en = 'Refill selected one'; fa = 'پرکردن مجدد انتخاب‌شده';
								|it = 'Ricompilare selezionata';
								|pl = 'Wypełnij ponownie wybrany';
								|tr = 'Seçileni doldur'");
			IssueNewHeader = NStr("vi = 'Lập mới';
									|ru = 'Оформить новое';
									|en = 'Register new receipt'; fa = 'Register new receipt';
									|it = 'Emettere nuovo';
									|pl = 'Sporządź nowy';
									|tr = 'Yenisini düzenle'");
			
			GoodsWaybillBasicInscription = NStr("vi = 'Sự khác biệt giữa tiếp nhận và đơn đặt hàng:';
												|ru = 'Расхождения между поступлениями и ордерами:';
												|en = 'Discrepancies between receipts and notes:'; fa = 'Discrepancies between receipts and notes:';
												|it = 'Расхождения между поступлениями и ордерами:';
												|pl = 'Discrepancies between receipts and notes:';
												|tr = ':Giriş ve emirler arasında tutarsızlık:'");
			InvoiceHeader_1			= NStr("vi = 'Thu';
												|ru = 'Поступление';
												|en = 'Receipt'; fa = 'دریافت';
												|it = 'Arrivo';
												|pl = 'Wpływ';
												|tr = 'Tahsilat'");
			
			DecoratedInvoices = NStr("vi = 'Doanh thu bán hàng và cung cấp dịch vụ';
									|ru = 'Поступления';
									|en = 'Receipts'; fa = 'دریافت‌ها';
									|it = 'Arrivi';
									|pl = 'Wpływy';
									|tr = 'Tahsilatlar'");
		Else
			CaptionInfoTitle = NStr("vi = 'Theo lệnh được chọn đã tạo phiếu nhập kho. Cần điều chỉnh phiếu nhập kho sẵn có và có tính đến tiếp nhận bằng lệnh ""Điền lại đã chọn"" hoặc tạo phiếu nhập kho mới đối với hàng hóa chưa tạo còn lại bằng lệnh ""Tạo mới"".';
									|ru = 'По выбранным распоряжениям уже оформлены накладные. Необходимо скорректировать имеющиеся накладные с учетом поступления командой ""Перезаполнить выбранную"" или оформить новую накладную на оставшиеся неоформленными товары командой ""Оформить новую"".';
									|en = 'Invoices are already registered for the selected references. Adjust the invoices considering the goods receipt by clicking ""Refill selected one"", or register a new invoice for the remaining unregistered goods by clicking ""Register new invoice"".'; fa = 'Invoices are already registered for the selected references. Adjust the invoices considering the goods receipt by clicking ""Refill selected one"", or register a new invoice for the remaining unregistered goods by clicking ""Register new invoice"".';
									|it = 'Per le disposizioni selezionate sono già state emesse le lettere di vettura. È necessario rettificare le lettere di vettura esistenti in considerazione dell''arrivo con il comando ""Ricompilare selezionata"" o emettere una nuova lettera di vettura per le merci rimaste tramite il comando ""Emettere nuova"".';
									|pl = 'Dla wybranych zamówień sporządzono już listy przewozowe. Należy skorygować istniejące listy przewozowe z uwzględnieniem wpływu poleceniem ""Wypełnij ponownie wybrany"" lub sporządzić nowy list przewozowy na pozostałe wiersze pozycji poleceniem ""Sporządź nowy"".';
									|tr = 'Seçilen siparişler için irsaliyeler artık düzenlendi. ""Seçileni doldur"" komutu kullanılarak giriş dikkate alınarak mevcut irsaliyelerin düzeltilmesi veya ""Yenisini düzenle"" komutu kullanılarak kalan kayıtlı olmayan ürünler için yeni bir irsaliye düzenlenmesi gerekir.'");
			
			ReFillHeader = NStr("vi = 'Điền lại đã chọn';
								|ru = 'Перезаполнить выбранную';
								|en = 'Refill selected one'; fa = 'پرکردن مجدد انتخاب‌شده';
								|it = 'Ricompilare selezionata';
								|pl = 'Wypełnij ponownie wybrany';
								|tr = 'Seçileni doldur'");
			IssueNewHeader = NStr("vi = 'Lập mới';
									|ru = 'Оформить новую';
									|en = 'Register new invoice'; fa = 'Register new invoice';
									|it = 'Emettere una nuova';
									|pl = 'Wystawić nową';
									|tr = 'Yenisini düzenle'");
			
			GoodsWaybillBasicInscription	= NStr("vi = 'Sự khác biệt giữa phiếu nhập kho và tiếp nhận:';
													|ru = 'Расхождения между накладными и поступлениями:';
													|en = 'Discrepancies between invoices and receipts:'; fa = 'Discrepancies between invoices and receipts:';
													|it = 'Расхождения между накладными и поступлениями:';
													|pl = 'Discrepancies between invoices and receipts:';
													|tr = 'İrsaliye ve girişler arasında tutarsızlık:'");
			InvoiceHeader_1			= NStr("vi = 'Phiếu nhập kho';
												|ru = 'Накладная';
												|en = 'Invoice'; fa = 'فاکتور';
												|it = 'Lettera di vettura';
												|pl = 'Faktura';
												|tr = 'İrsaliye'");
			
			DecoratedInvoices = NStr("vi = 'Phiếu nhập kho';
									|ru = 'Накладные';
									|en = 'Invoices'; fa = 'فاکتورها';
									|it = 'Lettere di vettura';
									|pl = 'Listy przewozowe';
									|tr = 'İrsaliye'");
		EndIf;
		
		Items.InfoLabel.Title = CaptionInfoTitle;
		
		Items.Refill.Title = ReFillHeader;
		Items.RegisterNewOne.Title = IssueNewHeader;
		
		Items.Invoice.Title		= InvoiceHeader_1;
		
		Items.CreateInvoices.Title = DecoratedInvoices;
		
	EndIf;
	
	GoodsHeadingOfConsignmentNote = New FormattedString(GoodsWaybillBasicInscription);
	
EndProcedure

#EndRegion

#Region EventHandlersForHeaderElements

&AtClient
Procedure HeaderOrdersTextClick(Item, StandardProcessing)
	StandardProcessing = False;
	OpenForm(
		"CommonForm.ViewingListOfDocuments",
		New Structure("DocumentsList, Title",
			OrderList,
			NStr("vi = 'Lệnh (%DocumentsCount%)';
				|ru = 'Распоряжения (%DocumentsCount%)';
				|en = 'References (%DocumentsCount%)'; fa = 'References (%DocumentsCount%)';
				|it = 'Disposizioni (%DocumentsCount%)';
				|pl = 'Zamówienia (%DocumentsCount%)';
				|tr = 'Emirler (%DocumentsCount%)'")
		),
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure StandardPeriodOnChange(Item)
	StandardPeriodOnChangeServer();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCreateInvoices

&AtClient
Procedure CreateInvoicesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	DataInvoice = Items.CreateInvoices.CurrentData;
	ShowValue(, DataInvoice.Invoice);
	
EndProcedure

&AtClient
Procedure CreateInvoicesOnActivateRow(Item)
	
	AttachIdleHandler("FillInGoodsInvoiceTableDeferred", 0.2, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refill(Command)

	CurrentData = Items.CreateInvoices.CurrentData;

	If CurrentData <> Undefined Then

		CorrectiveDocument = DocumentCorrectionServerCall.LastCorrectiveDocument(CurrentData.Invoice);

		If CorrectiveDocument = Undefined Then

			FillingValues = New Structure("FillByWarehouseDocument, AnArrayOfOrders, FilterByGoods", True,
				OrderList.UnloadValues());

			Parameters.HeaderAttributes.Property("FilterByGoods", FillingValues.FilterByGoods);

			FormParameters = New Structure("Key, FillingValues", CurrentData.Invoice, FillingValues);

			OpenForm(NameOfTheInvoiceForm, FormParameters);

		Else

			InvoicesClient.WarningAboutPresenceOfFix(CorrectiveDocument.Ref, NameOfTheInvoiceForm);

		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure RegisterNewOne(Command)
	
	CurrentData =Items.CreateInvoices.CurrentData;
	
	If CurrentData <> Undefined Then
		
		If InvoiceGoods.Total("Increase") <= 0 Then
			
			WarningText = NStr("vi = 'Không có sự khác biệt tích cực. Không xem xét tạo phiếu nhập kho mới.';
								|ru = 'Нет положительных расхождений. Оформление новой накладной не предусмотрено.';
								|en = 'No positive discrepancies. Cannot register a new invoice.'; fa = 'No positive discrepancies. Cannot register a new invoice.';
								|it = 'Non ci sono discrepanze positive. Non è prevista la formalizzazione di una nuova lettera di vettura.';
								|pl = 'Brak odchylenia dodatniego. Sporządzenie nowego listu przewozowego nie jest przewidziane.';
								|tr = 'Olumlu tutarsızlıklar mevcut değil. Yeni irsaliye düzenlenmesi öngörülmemektedir.'");
			ShowMessageBox(, WarningText);
			Return;
			
		EndIf;
		
		If Not ValueIsFilled(FillingData) Then
			AnArrayOfOrders = OrderList.UnloadValues();
			
			// Creating an invoice for selected orders.
			FillingData = New Structure("AnArrayOfOrders, FillByWarehouseDocument, HeaderAttributes",
				AnArrayOfOrders, True, Parameters.HeaderAttributes);
			
			// The specifics of transmitting parameters for filling out the sale of goods.
			SaleRegistrationOption = PredefinedValue("Enum.SalesRegistrationOptions.CustomerInvoice");
			FillingData.Insert("SaleRegistrationOption", SaleRegistrationOption);
			FillingData.Insert("FillInByLeftovers",      True);
			FillingData.Insert("DocumentBasis",        AnArrayOfOrders);
			FillingData.Insert("OriginWarehouse",            Warehouse);
			FillingData.Insert("WarehouseForReceipt",         Warehouse);
			FillingData.Insert("DesignParameters",      New Structure("ByOrders, ByNotes", False, True));
		Else
			FillingData = FillingData;
		EndIf;
		OpenForm(NameOfTheInvoiceForm, New Structure("Basis", FillingData));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormWhenCreatingIt()
	
	RenewalFormSettings = InvoicesServer.SettingsOfInvoiceReissueForm();
	FillPropertyValues(RenewalFormSettings, Parameters.FormSettings);
	
	FillingData = RenewalFormSettings.FillingData;
	
	NameOfTheInvoiceForm = RenewalFormSettings.NameOfTheInvoiceForm;
	FormCaption = RenewalFormSettings.Title;
	ShippingSlip = RenewalFormSettings.ShippingSlip;
	ReceivingDocument = RenewalFormSettings.ReceivingDocument;
	ThisIsTheReceiptOfGoodsDocument = RenewalFormSettings.ThisIsTheReceiptOfGoodsDocument;
	
	BasicNomenclature = RenewalFormSettings.MainGoods.Key.Products;
	MainFeature = RenewalFormSettings.MainGoods.Key.Characteristic;
	
	HeaderPicture = RenewalFormSettings.MainGoods.HeaderPicture;
	ValuesPicture = RenewalFormSettings.MainGoods.ValuesPicture;	
	
	If FormCaption <> Undefined Then
		AutoTitle = False;
		Title = FormCaption;
	EndIf;
	
	OrderDocument = Parameters.Orders.Get(0);
	If Parameters.Orders.Count() = 1 Then
		Items.PageReferences.CurrentPage = Items.PageOrder;
	Else
		HeaderOrdersText = NStr("vi = 'Tổng số đơn đặt hàng';
								|ru = 'Всего распоряжений';
								|en = 'Total references'; fa = 'Total references';
								|it = 'Totale disposizioni';
								|pl = 'Łącznie zamówień';
								|tr = 'Toplam emirler'") + ": " + Parameters.Orders.Count();
		Items.PageReferences.CurrentPage = Items.OrdersPage;
	EndIf;
	Items.OrderTable_5.Visible = Parameters.Orders.Count() > 1;
	Items.MainGoods.Visible        = BasicNomenclature <> Undefined;
	Items.MainGoods.HeaderPicture    = HeaderPicture;
	Items.MainGoods.ValuesPicture = ValuesPicture;
	
EndProcedure

&AtServer
Procedure FillInFormDetailsWhenCreating()
	
	WarehouseFromShapka = Catalogs.Warehouses.EmptyRef();
	Parameters.HeaderAttributes.Property("Warehouse", WarehouseFromShapka);
	
	Warehouse = ?(ValueIsFilled(Parameters.Warehouse),Parameters.Warehouse, WarehouseFromShapka);
	Warehouses.LoadValues(WarehouseOrGroup(Warehouse));
	Parameters.HeaderAttributes.Property("BusinessOperation", BusinessOperation);
	OrderList.LoadValues(Parameters.Orders);
	InvoiceTable_ = InvoicesForOrders(Parameters.Orders);
	CreateInvoices.Load(InvoiceTable_);
	
EndProcedure

&AtServer
Function WarehouseOrGroup(Warehouse)
	
	If Common.ObjectAttributeValue(Warehouse, "IsFolder") = True Then
		
		Query = New Query();
		Query.Text =
			"SELECT ALLOWED DISTINCT
			|	CatWarehouses.Ref AS Ref
			|FROM
			|	Catalog.Warehouses AS CatWarehouses
			|WHERE
			|	NOT CatWarehouses.DeletionMark
			|	AND CatWarehouses.Ref IN HIERARCHY (&Warehouse)";
		Query.SetParameter("Warehouse", Warehouse);
		Return Query.Execute().Unload().UnloadColumn("Ref");
		
	Else
		
		WarehouseArray = New Array();
		WarehouseArray.Add(Warehouse);
		Return WarehouseArray;
		
	EndIf;
	
EndFunction

#Region FillType

&AtServer
Procedure FillInGoodsInvoiceTable(Invoice)
	
	RequiredGoods		= Undefined;
	References		= OrderList.UnloadValues();
	FiltersSettings	= GetSelectionSettings_(Parameters.HeaderAttributes);
	
	If Parameters.HeaderAttributes.Property("RequiredGoods") Then
		RequiredGoods = GetFromTempStorage(Parameters.HeaderAttributes.RequiredGoods);
	EndIf;
	
	ThereIsSelectionByWarehouse			= ValueIsFilled(Warehouse);
	ThereIsSelectionByProduct			= ValueIsFilled(RequiredGoods);
	ThereIsSelectionForGoodsOfOrder	= FiltersSettings <> Undefined;
	
	Query = New Query();
	Query.Text = TextOfGoodsRequestInvoice(ThereIsSelectionByWarehouse, ThereIsSelectionByProduct, ThereIsSelectionForGoodsOfOrder);
	
	Query.SetParameter("AnArrayOfOrders",			References);
	Query.SetParameter("Invoice",				Invoice);
	Query.SetParameter("BusinessOperation",	BusinessOperation);
	Query.SetParameter("Warehouse",					Warehouses.UnloadValues());
	Query.SetParameter("ProductsByOrders",		?(FiltersSettings = Undefined,
															Undefined,
															FiltersSettings.TableFilters));
	Query.SetParameter("ReceivingDocument",		ReceivingDocument);
	Query.SetParameter("ShippingSlip",	ShippingSlip);
	Query.SetParameter("RequiredGoods",		RequiredGoods);
	Query.SetParameter("BasicNomenclature",	BasicNomenclature);
	Query.SetParameter("MainFeature",	MainFeature);
	
	If ThisIsTheReceiptOfGoodsDocument Then
		Query.SetParameter("BusinessTransactionsSeparatePurchaseOperations", New Array);
	Else
		Query.SetParameter("BusinessTransactionsSeparatePurchaseOperations",
									PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections());
	EndIf;
	
	InvoiceGoods.Load(Query.Execute().Unload());
	
	For Each LineProducts_ In InvoiceGoods Do
		LineProducts_.Increase = ?(LineProducts_.Discrepancy > 0, 1, 0);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function TextOfGoodsRequestInvoice(ThereIsSelectionByWarehouse, ThereIsSelectionByProduct, ThereIsSelectionForGoodsOfOrder)
	
	QueryTextFilterByGoods = ?(ThereIsSelectionByProduct,
		"SELECT
		|	FilterTable.Products		AS Products,
		|	FilterTable.Characteristic	AS Characteristic
		|INTO TTSelectionTable
		|FROM
		|	&RequiredGoods AS FilterTable
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|",
		"");
	
	QueryTextSelectionByOrderItems = ?(ThereIsSelectionForGoodsOfOrder,
		"SELECT
		|	TTTableOfSelectionsByOrderItems.Ref			AS OrderDocument,
		|	TTTableOfSelectionsByOrderItems.Products	AS Products,
		|	TTTableOfSelectionsByOrderItems.Characteristic	AS Characteristic
		|INTO TTTableOfSelectionsByOrderItems
		|FROM
		|	&ProductsByOrders AS TTTableOfSelectionsByOrderItems
		|
		|INDEX BY
		|	Ref,
		|	Products,
		|	Characteristic
		|;
		|",
		"");
	
	QueryText = QueryTextFilterByGoods + QueryTextSelectionByOrderItems +
	"SELECT ALLOWED
	|	Table.DocumentShipments	AS OrderDocument,
	|	Table.Warehouse				AS Warehouse,
	|	Table.Products		AS Products,
	|	Table.Characteristic		AS Characteristic,
	|	Table.Series				AS Series,
	|	Table.Purpose			AS Purpose,
	|	Table.ToShipExpense + Table.AssembledReceipt - Table.ToRegisterExpense AS DiscrepancyByOrder
	|INTO TTProducts_1
	|FROM
	|	AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(
	|			,
	|			,
	|			,
	|			,
	|			&FilterGoodsForIssue
	|	) AS Table
	|
	|WHERE
	|	&ShippingSlip
	|	AND Table.ToShipExpense + Table.AssembledReceipt - Table.ToRegisterExpense <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Table.DocumentInflow	AS OrderDocument,
	|	Table.Warehouse				AS Warehouse,
	|	Table.Products		AS Products,
	|	Table.Characteristic		AS Characteristic,
	|	Table.Series				AS Series,
	|	Table.Purpose			AS Purpose,
	|	Table.ToRegisterGoodsReceiptsBalance AS DiscrepancyByOrder
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			&FilterGoodsReadyForReceipt
	|			AND CASE
	|				WHEN NOT BusinessOperation IN(&BusinessTransactionsSeparatePurchaseOperations)
	|					THEN BusinessOperation = &BusinessOperation
	|				ELSE FALSE
	|			END
	|		) AS Table
	|
	|WHERE
	|	&ReceivingDocument
	|	AND Table.ToRegisterGoodsReceiptsBalance <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Table.DocumentInflow	AS OrderDocument,
	|	Table.Warehouse				AS Warehouse,
	|	Table.Products		AS Products,
	|	Table.Characteristic		AS Characteristic,
	|	Table.Series				AS Series,
	|	Table.Purpose			AS Purpose,
	|	-Table.ToRegisterReceiptsByInvoicesBalance AS DiscrepancyByOrder
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			&FilterGoodsReadyForReceipt
	|			AND CASE
	|				WHEN BusinessOperation IN(&BusinessTransactionsSeparatePurchaseOperations)
	|					THEN BusinessOperation = &BusinessOperation
	|				ELSE FALSE
	|			END
	|	) AS Table
	|
	|WHERE
	|	&ReceivingDocument
	|	AND Table.ToRegisterReceiptsByInvoicesBalance <> 0
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Purpose,
	|	Warehouse,
	|	OrderDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////
	// Discrepancy on all orders.
	|SELECT
	|	Table.Products				AS Products,
	|	Table.Characteristic				AS Characteristic,
	|	Table.Series						AS Series,
	|	Table.Purpose					AS Purpose,
	|	Table.Warehouse						AS Warehouse,
	|	SUM(Table.DiscrepancyByOrder)	AS Count
	|INTO TTDiscrepancy
	|FROM
	|	TTProducts_1 AS Table
	|
	|GROUP BY
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Series,
	|	Table.Purpose,
	|	Table.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Purpose,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////
	// The nomenclature of the invoice.
	|SELECT ALLOWED
	|	Table.DocumentShipments	AS OrderDocument,
	|	Table.Products		AS Products,
	|	Table.Characteristic		AS Characteristic,
	|	Table.Series				AS Series,
	|	Table.Purpose			AS Purpose,
	|	Table.Warehouse				AS Warehouse,
	|	SUM(Table.ToRegister)	AS Count
	|INTO TTInvoice
	|FROM
	|	AccumulationRegister.GoodsForIssue AS Table
	|WHERE
	|	Table.Active
	|	AND &ShippingSlip
	|	AND Table.Recorder = &Invoice
	|	AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND NOT Table.ReversingEntry
	|
	|GROUP BY
	|	Table.DocumentShipments,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Series,
	|	Table.Purpose,
	|	Table.Warehouse
	|
	|HAVING
	|	SUM(Table.ToRegister) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Table.DocumentInflow	AS OrderDocument,
	|	Table.Products		AS Products,
	|	Table.Characteristic		AS Characteristic,
	|	Table.Series				AS Series,
	|	Table.Purpose			AS Purpose,
	|	Table.Warehouse				AS Warehouse,
	|	SUM(Table.ToRegisterGoodsReceipts) AS Count
	|
	|FROM
	|	AccumulationRegister.GoodsToReceive AS Table
	|WHERE
	|	Table.Active
	|	AND &ReceivingDocument
	|	AND Table.Recorder = &Invoice
	|	AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND NOT Table.ReversingEntry
	|	AND CASE
	|		WHEN NOT Table.BusinessOperation IN(&BusinessTransactionsSeparatePurchaseOperations)
	|			THEN Table.BusinessOperation = &BusinessOperation
	|		ELSE FALSE
	|	END
	|
	|GROUP BY
	|	Table.DocumentInflow,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Series,
	|	Table.Purpose,
	|	Table.Warehouse
	|
	|HAVING
	|	SUM(Table.ToRegisterGoodsReceipts) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	Table.DocumentInflow	AS OrderDocument,
	|	Table.Products		AS Products,
	|	Table.Characteristic		AS Characteristic,
	|	Table.Series				AS Series,
	|	Table.Purpose			AS Purpose,
	|	Table.Warehouse				AS Warehouse,
	|	SUM(Table.ToRegisterReceiptsByInvoices) AS Count
	|FROM
	|	AccumulationRegister.GoodsToReceive AS Table
	|WHERE
	|	Table.Active
	|	AND &ReceivingDocument
	|	AND Table.Recorder = &Invoice
	|	AND Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND NOT Table.ReversingEntry
	|	AND CASE
	|		WHEN Table.BusinessOperation IN(&BusinessTransactionsSeparatePurchaseOperations)
	|			THEN Table.BusinessOperation = &BusinessOperation
	|		ELSE FALSE
	|	END
	|
	|GROUP BY
	|	Table.DocumentInflow,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Series,
	|	Table.Purpose,
	|	Table.Warehouse
	|
	|HAVING
	|	SUM(Table.ToRegisterReceiptsByInvoices) <> 0
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Purpose,
	|	Warehouse,
	|	OrderDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.OrderDocument						AS OrderDocument,
	|	CASE
	|		WHEN Table.Products= &BasicNomenclature
	|				AND Table.Characteristic = &MainFeature
	|				AND Table.Warehouse IN(&Warehouse)
	|			THEN 1
	|		ELSE 0
	|	END								AS MainGoods,
	|	Table.Products				AS Products,
	|	ISNULL(CatProducts.Description, """") AS NomenclatureName,
	|	Table.Characteristic				AS Characteristic,
	|	Table.Characteristic.Description	AS CharacteristicName,
	|	CASE
	|		WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END								AS ItemVariantsAreUsed,
	|	Table.Series						AS Series,
	|	Table.Purpose					AS Purpose,
	|	CatProducts.UnitOfMeasure	AS UnitOfMeasure,
	|	Table.Warehouse						AS Warehouse,
	|	Table.Warehouse.Description			AS WarehouseName,
	|	TableDiscrepancyTotal.Count	AS Discrepancy,
	|	InvoiceTable.Count			AS QuantityInInvoice,
	|	CASE
	|		WHEN Table.DiscrepancyByOrder < 0
	|				AND ISNULL(InvoiceTable.Count, 0) < -Table.DiscrepancyByOrder
	|			THEN -InvoiceTable.Count
	|		ELSE Table.DiscrepancyByOrder
	|	END								AS ZoomInZoomOut
	|FROM
	|	TTProducts_1 AS Table
	|		LEFT JOIN TTInvoice AS InvoiceTable
	|		ON Table.Products = InvoiceTable.Products
	|			AND Table.Characteristic = InvoiceTable.Characteristic
	|			AND Table.Series = InvoiceTable.Series
	|			AND Table.Purpose = InvoiceTable.Purpose
	|			AND Table.Warehouse = InvoiceTable.Warehouse
	|			AND Table.OrderDocument = InvoiceTable.OrderDocument
	|		
	|		LEFT JOIN TTDiscrepancy AS TableDiscrepancyTotal
	|		ON Table.Products = TableDiscrepancyTotal.Products
	|			AND Table.Characteristic = TableDiscrepancyTotal.Characteristic
	|			AND Table.Series = TableDiscrepancyTotal.Series
	|			AND Table.Purpose = TableDiscrepancyTotal.Purpose
	|			AND Table.Warehouse = TableDiscrepancyTotal.Warehouse
	|		
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = Table.Products
	|
	|ORDER BY
	|	NomenclatureName,
	|	CharacteristicName,
	|	WarehouseName,
	|	OrderDocument";
		
	If ThereIsSelectionForGoodsOfOrder Then
		FilterGoodsForIssue =
			"(DocumentShipments, Products, Characteristic) IN
			|			(SELECT
			|				TTTableOfSelectionsByOrderItems.OrderDocument,
			|				TTTableOfSelectionsByOrderItems.Products,
			|				TTTableOfSelectionsByOrderItems.Characteristic
			|			FROM
			|				TTTableOfSelectionsByOrderItems)";
		
		GoodsReadyForReceipt =
			"(DocumentInflow, Products, Characteristic) IN
			|			(SELECT
			|				TTTableOfSelectionsByOrderItems.OrderDocument,
			|				TTTableOfSelectionsByOrderItems.Products,
			|				TTTableOfSelectionsByOrderItems.Characteristic
			|			FROM
			|				TTTableOfSelectionsByOrderItems)";
	Else
		FilterGoodsForIssue			= "DocumentShipments IN (&AnArrayOfOrders)";
		GoodsReadyForReceipt	= "DocumentInflow IN (&AnArrayOfOrders)";
	EndIf;
	
	If ThereIsSelectionByWarehouse Then
		FilterGoodsForIssue			= "Warehouse IN(&Warehouse) AND " + FilterGoodsForIssue;
		GoodsReadyForReceipt	= "Warehouse IN(&Warehouse) AND " + GoodsReadyForReceipt;
	EndIf;
	
	If ThereIsSelectionByProduct Then
		FilterByGoods =
		"(Products, Characteristic) IN
		|			(SELECT
		|				FilterTable.Products AS Products,
		|				FilterTable.Characteristic AS Characteristic
		|			FROM
		|				TTSelectionTable AS FilterTable)";
		
		FilterGoodsForIssue			= FilterGoodsForIssue + " And " + FilterByGoods;
		GoodsReadyForReceipt	= GoodsReadyForReceipt + " And " + FilterByGoods;
	EndIf;
	
	QueryText = StrReplace(QueryText, "&FilterGoodsForIssue",				FilterGoodsForIssue);
	QueryText = StrReplace(QueryText, "&FilterGoodsReadyForReceipt",	GoodsReadyForReceipt);
	
	Return QueryText;
	
EndFunction

#EndRegion

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Positive overall difference
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Sự khác biệt tổng thể tích cực';
							|ru = 'Положительная общая разница';
							|en = 'Total positive difference'; fa = 'Total positive difference';
							|it = 'Differenza complessiva positiva';
							|pl = 'Różnica dodatnia łączna';
							|tr = 'Olumlu genel fark'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Discrepancy.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InvoiceGoods.Discrepancy");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.PositiveTaskCompletionFlag);
	
	// Negative overall difference
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tổng chênh lệch âm';
							|ru = 'Отрицательная общая разница';
							|en = 'Total negative difference'; fa = 'Total negative difference';
							|it = 'Differenza complessiva negativa';
							|pl = 'Różnica ujemna łączna';
							|tr = 'Olumsuz genel fark'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Discrepancy.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InvoiceGoods.Discrepancy");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTaskCompletionFlag);
	
	// Positive difference
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Sự khác biệt dương';
							|ru = 'Положительная разница';
							|en = 'Positive difference'; fa = 'Positive difference';
							|it = 'Differenza positiva';
							|pl = 'Różnica dodatnia';
							|tr = 'Olumlu fark'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ZoomInZoomOut.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InvoiceGoods.ZoomInZoomOut");
	ItemFilter.ComparisonType = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.PositiveTaskCompletionFlag);
	
	// Negative difference
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Sự khác biệt âm';
							|ru = 'Отрицательная разница';
							|en = 'Negative difference'; fa = 'Negative difference';
							|it = 'Differenza negativa';
							|pl = 'Różnica ujemna';
							|tr = 'Olumsuz fark'");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ZoomInZoomOut.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InvoiceGoods.ZoomInZoomOut");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTaskCompletionFlag);
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisForm, "Characteristic", "InvoiceGoods.ItemVariantsAreUsed");
	
EndProcedure

&AtServer
Function InvoicesForOrders(Orders)
	
	QueryText = 
	"SELECT ALLOWED DISTINCT
	|	Table.Recorder					AS Invoice,
	|	DocumentAttributes.IBDocumentDate	AS Date
	|FROM
	|	AccumulationRegister.GoodsForIssue AS Table
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentAttributes
	|		ON DocumentAttributes.Ref = Table.Recorder
	|			AND NOT DocumentAttributes.AdditionalRecord
	|WHERE
	|	Table.Active
	|	AND &FilterByOrders_2
	|	AND &FilterByGoods_2
	|	AND &FilterByGoods_3
	|	AND CASE
	|		WHEN &WarehouseIsFull
	|			THEN Table.Warehouse IN(&Warehouse)
	|		ELSE TRUE
	|	END
	|	AND &ShippingSlip
	|	AND Table.ToRegister > 0
	|	AND Table.Period BETWEEN &StartDate AND &EndDate
	|	AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND NOT DocumentAttributes.ReverseTransactionCorrection
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Table.Recorder					AS Invoice,
	|	DocumentAttributes.IBDocumentDate	AS Date
	|FROM
	|	AccumulationRegister.GoodsToReceive AS Table
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentAttributes
	|		ON DocumentAttributes.Ref = Table.Recorder
	|			AND NOT DocumentAttributes.AdditionalRecord
	|WHERE
	|	Table.Active
	|	AND &FilterByOrders_1
	|	AND &FilterByGoods_1
	|	AND &FilterByGoods_3
	|	AND CASE
	|		WHEN &WarehouseIsFull
	|			THEN Table.Warehouse IN(&Warehouse)
	|		ELSE TRUE
	|	END
	|	AND CASE
	|		WHEN NOT Table.BusinessOperation IN(&BusinessTransactionsSeparatePurchaseOperations)
	|			THEN Table.BusinessOperation = &BusinessOperation
	|		ELSE FALSE
	|	END
	|	AND &ReceivingDocument
	|	AND Table.ToRegisterGoodsReceipts > 0
	|	AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND (&StartDate = UNDEFINED
	|		OR Table.Period BETWEEN &StartDate AND &EndDate)
	|	AND NOT DocumentAttributes.ReverseTransactionCorrection
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Table.Recorder AS Invoice,
	|	ISNULL(DocumentAttributes.IBDocumentDate, DATETIME(1,1,1)) AS Date
	|FROM
	|	AccumulationRegister.GoodsToReceive AS Table
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentAttributes
	|		ON DocumentAttributes.Ref = Table.Recorder
	|			AND NOT DocumentAttributes.AdditionalRecord
	|WHERE
	|	Table.Active
	|	AND &FilterByOrders_1
	|	AND &FilterByGoods_1
	|	AND &FilterByGoods_3
	|	AND CASE
	|		WHEN &WarehouseIsFull
	|			THEN Table.Warehouse IN(&Warehouse)
	|		ELSE TRUE
	|	END
	|	AND CASE
	|		WHEN Table.BusinessOperation IN(&BusinessTransactionsSeparatePurchaseOperations)
	|			THEN Table.BusinessOperation = &BusinessOperation
	|		ELSE FALSE
	|	END
	|	AND &ReceivingDocument
	|	AND Table.ToRegisterReceiptsByInvoices > 0
	|	AND Table.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND (&StartDate = UNDEFINED
	|		OR Table.Period BETWEEN &StartDate AND &EndDate)
	|	AND NOT DocumentAttributes.ReverseTransactionCorrection
	|
	|ORDER BY
	|	Date DESC";
	
	FiltersSettings = GetSelectionSettings_(Parameters.HeaderAttributes);
	
	If FiltersSettings = Undefined Then

		QueryText = StrReplace(QueryText, "AND &FilterByOrders_1", "AND Table.DocumentInflow IN(&Orders)");
		QueryText = StrReplace(QueryText, "AND &FilterByOrders_2", "AND Table.DocumentShipments IN(&Orders)");

		QueryText = StrReplace(QueryText, "AND &FilterByGoods_1", "");
		QueryText = StrReplace(QueryText, "AND &FilterByGoods_2", "");
		QueryText = StrReplace(QueryText, "AND &FilterByGoods_3", "");
		
	Else
		
		QueryText = StrReplace(QueryText, "AND &FilterByOrders_1", "");
		QueryText = StrReplace(QueryText, "AND &FilterByOrders_2", "");

		QueryText = StrReplace(QueryText, "AND &FilterByGoods_1", "AND (Table.DocumentInflow, Table.Products, Table.Characteristic) IN");
		QueryText = StrReplace(QueryText, "AND &FilterByGoods_2", "AND (Table.DocumentShipments, Table.Products, Table.Characteristic) IN");
		QueryText = StrReplace(QueryText, "AND &FilterByGoods_3", 
													"		(SELECT
													|				TTTableOfSelectionsByOrderItems.OrderDocument,
													|				TTTableOfSelectionsByOrderItems.Products,
													|				TTTableOfSelectionsByOrderItems.Characteristic
													|			FROM
													|				TTTableOfSelectionsByOrderItems)");
		
		QueryTextFilterByGoods =
		"SELECT
		|	TTTableOfSelectionsByOrderItems.Ref			AS OrderDocument,
		|	TTTableOfSelectionsByOrderItems.Products	AS Products,
		|	TTTableOfSelectionsByOrderItems.Characteristic	AS Characteristic
		|INTO TTTableOfSelectionsByOrderItems
		|FROM
		|	&Orders AS TTTableOfSelectionsByOrderItems
		|
		|INDEX BY
		|	OrderDocument,
		|	Products,
		|	Characteristic
		|";
		
		QueriesTexts = New Array;
		QueriesTexts.Add(QueryTextFilterByGoods);
		QueriesTexts.Add(QueryText);
		
		QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Orders",					?(FiltersSettings = Undefined,
															Orders,
															FiltersSettings.TableFilters));
	Query.SetParameter("Warehouse",					Warehouses.UnloadValues());
	Query.SetParameter("WarehouseIsFull",			ValueIsFilled(Warehouse));
	Query.SetParameter("BusinessOperation",	BusinessOperation);
	Query.SetParameter("StartDate",				?(ValueIsFilled(StandardPeriod.StartDate),
															StandardPeriod.StartDate,
															Undefined));
	Query.SetParameter("EndDate",			?(ValueIsFilled(StandardPeriod.EndDate),
															StandardPeriod.EndDate,
															Date(3999,12,31)));
	Query.SetParameter("ReceivingDocument",		ReceivingDocument);
	Query.SetParameter("ShippingSlip",	ShippingSlip);
	
	If ThisIsTheReceiptOfGoodsDocument Then
		Query.SetParameter("BusinessTransactionsSeparatePurchaseOperations", New Array);
	Else
		Query.SetParameter("BusinessTransactionsSeparatePurchaseOperations",
									PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections());
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

&AtClient
Procedure FillInGoodsInvoiceTableDeferred()
	
	InvoiceGoods.Clear();
	LineProducts_ = Items.CreateInvoices.CurrentData;
	If LineProducts_ <> Undefined Then
		
		Invoice = LineProducts_.Invoice;
		CorrectiveDocument = DocumentCorrectionServerCall.LastCorrectiveDocument(Invoice);
		
		If CorrectiveDocument <> Undefined Then
			Invoice = CorrectiveDocument.Ref;
			RowsArray = New Array();
			RowsArray.Add(GoodsWaybillBasicInscription); 
			RowsArray.Add(Chars.LF + NStr("vi = ' (cm';
											|ru = ' (см.';
											|en = ' (see'; fa = ' (see';
											|it = ' (см.';
											|pl = ' (see';
											|tr = ' (cm'"));
			RowsArray.Add(New FormattedString(String(Invoice),,,, GetURL(Invoice)));
			RowsArray.Add(NStr("vi = ')';
								|ru = ')';
								|en = ')'; fa = ')';
								|it = ')';
								|pl = ')';
								|tr = ')'"));
			GoodsHeadingOfConsignmentNote = New FormattedString(RowsArray);
		Else
			GoodsHeadingOfConsignmentNote = New FormattedString(GoodsWaybillBasicInscription);
		EndIf;
		
		FillInGoodsInvoiceTable(Invoice);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StandardPeriodOnChangeServer()
	InvoiceTable_ = InvoicesForOrders(OrderList);
	CreateInvoices.Load(InvoiceTable_);
EndProcedure

&AtServer
Function GetSelectionSettings_(SelectionParameters_2) 

	TableFilters = New ValueTable;

	FilterByGoods = Undefined;
	SelectionParameters_2.Property("FilterByGoods", FilterByGoods);

	If ValueIsFilled(FilterByGoods) Then

		TableFilters.Columns.Add("Ref",
			Documents.AllRefsType());
		
		TableFilters.Columns.Add("Products",
			New TypeDescription("CatalogRef.Products"));

		TableFilters.Columns.Add("Characteristic",
			New TypeDescription("CatalogRef.ItemsCharacteristics"));

		For Each FilterElement In FilterByGoods Do

			DocumentSource = FilterElement.Key;

			FilterValues = FilterElement.Value;
			For Each FilterValue In FilterValues Do

				SelectionTableRow = TableFilters.Add();
				SelectionTableRow.Ref = DocumentSource;
				FillPropertyValues(SelectionTableRow, FilterValue.Value);

			EndDo;

		EndDo;

	EndIf;

	AdvancedFilter = ?(TableFilters.Columns.Count() = 0,
		Undefined, New Structure("TableFilters", TableFilters));

	Return AdvancedFilter;

EndFunction

#EndRegion