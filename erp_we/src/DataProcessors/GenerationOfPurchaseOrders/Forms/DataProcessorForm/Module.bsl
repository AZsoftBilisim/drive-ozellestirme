
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Not GetFunctionalOption("NotUseAdvancedDemandFulfillment") Then
		Raise NStr("vi = 'Bộ xử lý không dùng để mở tùy chọn chức năng đã tắt ""Không sử dụng đảm bảo nhu cầu mở rộng""';
					|ru = 'Обработка не предназначена для открытия с выключенной функциональной опцией ""Не использовать расширенное обеспечение потребностей""';
					|en = 'The data processor is not intended for opening with disabled ""Do not use advanced demand fulfillment"" functional option'; fa = 'The data processor is not intended for opening with disabled ""Do not use advanced demand fulfillment"" functional option';
					|it = 'L''elaborazione non è prevista per l''apertura con opzione di funzione disattivata ""Non utilizzare il soddisfacimento esteso dei consumi""';
					|pl = 'Procesor danych nie jest przeznaczony do otwarcia z wyłączoną opcją funkcjonalną ""Nie używaj rozszerzonego zaspokojenia zapotrzebowania""';
					|tr = 'İşleme, ""Gelişmiş talebi karşılamayı kullanma"" fonksiyon seçeneği kapalıyken açılmak üzere tasarlanmamıştır'");
	EndIf;
	
	// Setting up a form that does not require initialization of the details.
	SetConditionalAppearance();
	SwitchPages("Inventories", Items);
	Items.AverageDailyConsumption.Title
		= NStr("vi = 'Tiêu dùng trung bình hàng ngày';
				|ru = 'Среднедневное потребление';
				|en = 'Average daily consumption'; fa = 'میانگین مصرف روزانه';
				|it = 'Consumo medio giornaliero';
				|pl = 'Średnie dzienne spożycie';
				|tr = 'Ortalama günlük tüketim'"); // otherwise, it is not possible to reduce the column width to the required one.
	Items.CurrencyLabel.Title = String(Constants.ManagementAccountingCurrency.Get());
	Items.UnitOfMeasurementLabel.Title = String(Constants.UnitOfMeasureForWeight.Get());
	Items.VolumeUnitLabel.Title = String(Constants.UnitOfMeasureForVolume.Get());

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	// Initialization of the form details.
	RestoreSettings();
	Object.Warehouse = SettingsValueCached.GetDefaultWarehouse();

	FillTables();

	CustomizeItemsWhenChangingBankingDetails();

	UseStatuses = GetFunctionalOption("UsePurchaseOrderStatuses");
	ListDocuments.Parameters.SetParameterValue("UpdateDate", BegOfDay(CurrentSessionDate()));
	ListDocuments.Parameters.SetParameterValue("UseStatuses", UseStatuses);
	ListDocuments.Parameters.SetParameterValue("CreatedDocuments", New Array);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then

		ProcessingSelectionOnServer(ValueSelected.GoodsAddressInStorage);

	ElsIf ChoiceSource.FormName = "DataProcessor.GoodsSelectionByPicking.Form.Form" Then

		ProcessingSelectionOnServer(ValueSelected.GoodsAddressInStorage);

	ElsIf ChoiceSource.FormName = "Catalog.Partners.Form.ChoiceForm"
		Or ChoiceSource.FormName = "Catalog.Partners.Form.SelectionFormWithoutFullTextSearch" Then

		FillInProviderOnServer(ValueSelected);

	ElsIf ChoiceSource.FormName = "DataProcessor.GenerationOfPurchaseOrders.Form.EnterValue" Then

		EnteringValueOnServer(ValueSelected);

	ElsIf ValueSelected.Property("DeliveryParametersOptimal") Then

		Context = CurPageContext(ThisForm);
		String = Context.Collection.FindByID(Context.CurrentRow);
		String.Vendor  = ValueSelected.DeliveryParametersOptimal.SupplySource;
		String.Terms = ValueSelected.DeliveryParametersOptimal.Terms;
		String.Price       = ValueSelected.DeliveryParametersOptimal.PriceInTheCurrencyOfManagementAccounting;
		String.VendorPriceKind = ValueSelected.DeliveryParametersOptimal.PriceKind;
		UpdateTotalsInRow(String);
		UpdateTotals(ThisForm);

	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If ProcessingOfDocumentWritingNotificationsIsEnabled And EventName = "Write_PurchaseOrder" Then
		
		Items.ListDocuments.Refresh();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure WarehouseOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.GenerationOfPurchaseOrders.Form.DataProcessorForm.Item.Warehouse.OnChange");
	
	FillTables(False);
	SwitchPages("Inventories", Items);
	CustomizeItemsWhenChangingBankingDetails("Warehouse");
	
EndProcedure

&AtClient
Procedure FulfillOrdersChoiceProcessing(Item, ValueSelected, StandardProcessing)

	If Items.Tabs.CurrentPage = Items.PageDocuments Then

		If OrdersAreCreated Then

			OrdersAreCreated = False;
			ProcessingOfDocumentWritingNotificationsIsEnabled = False;
			DeleteDocuments();
			ClearMessages();
			ShowUserNotification(NStr("vi = 'Xóa chứng từ';
										|ru = 'Удаление документов';
										|en = 'Remove documents'; fa = 'Remove documents';
										|it = 'Cancellazione documenti';
										|pl = 'Usuwanie dokumentów';
										|tr = 'Belgelerin silinmesi'"), , NStr("vi = 'Đơn hàng đã lập bị xóa bỏ.';
																		|ru = 'Сформированные заказы удалены.';
																		|en = 'Generated orders are removed.'; fa = 'Generated orders are removed.';
																		|it = 'Ordini formati sono stati cancellati.';
																		|pl = 'Utworzone zamówienia zostały usunięte';
																		|tr = 'Oluşturulan siparişler silindi.'"));

		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure FulfillOrdersOnChange(Item)

	ProvideOrdersWhenChangedOnServer();

EndProcedure

&AtClient
Procedure FulfillOrdersClearing(Item, StandardProcessing)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure SalesPeriodOnChange(Item)

	CalculateAverageDailyConsumptionOnServer();

EndProcedure

&AtClient
Procedure OnlyCheckedTheFilterWhenYouChangeStocks(Item)

	UpdateFilter();

EndProcedure

&AtClient
Procedure OnlyMarkedFilterOrdersWhenChanging(Item)

	FilterStructure1 = New Structure();
	If OnlyOrdersMarkedWithTheFilter Then
		FilterStructure1.Insert("Mark", True);
	EndIf;

	If ValueIsFilled(FilterStructure1) Then
		Items.Orders.RowFilter = New FixedStructure(FilterStructure1);
	Else
		Items.Orders.RowFilter = Undefined;
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInventories

&AtClient
Procedure InventoriesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.ProductsInventory Then
		
		ShowValue(,Items.Inventories.CurrentData.Products);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MaximumBalanceOnChange(Item)

	RecordCurLineStockMaintenanceParameters();

EndProcedure

&AtClient
Procedure MinimumBalanceOnChange(Item)

	RecordCurLineStockMaintenanceParameters();

EndProcedure

&AtClient
Procedure MarkInventoryOnChange(Item)

	String = Items.Inventories.CurrentData;
	UpdateTotalsInRow(String);
	UpdateTotals(ThisForm);

	ModifiedTheInventoryTable = True;

EndProcedure

&AtClient
Procedure ToOrderInventoryOnChange(Item)

	String = Items.Inventories.CurrentData;
	String.Mark = String.ToOrder > 0;
	UpdateTotalsInRow(String);
	UpdateTotals(ThisForm);

	ModifiedTheInventoryTable = True;

EndProcedure

&AtClient
Procedure TheSupplierReservesStartChoice(Item, ChoiceData, StandardProcessing)

	String = Items.Inventories.CurrentData;

	FormParameters = New Structure("Warehouse, Products, Characteristic, ThisIsWork, SupplyType");
	FillPropertyValues(FormParameters, String);
	FormParameters.SupplyType = PredefinedValue("Enum.SupplyTypes.Purchase");
	FormParameters.ThisIsWork = False;
	StandardProcessing = False;
	OpenForm("DataProcessor.DemandFulfillment.Form.SelectionFormOfSourceOfSupply", FormParameters, ThisForm);

EndProcedure

&AtClient
Procedure TheSupplierReservesOnChange(Item)
	
	TableRow = Items.Inventories.CurrentData;
	ProviderWhenChangingOnClient(TableRow);
	
EndProcedure

&AtClient
Procedure ThePriceOfStocksOnChange(Item)

	String = Items.Inventories.CurrentData;
	UpdateTotalsInRow(String);
	UpdateTotals(ThisForm);

EndProcedure

&AtClient
Procedure InventoriesAfterDeleteRow(Item)

	ModifiedTheInventoryTable = True;
	UpdateTotals(ThisForm);

EndProcedure

&AtClient
Procedure InventoriesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)

	Cancel = True;

	If ValueIsFilled(Object.Warehouse) Then
		PickUpProductsOnClient();
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOrders

&AtClient
Procedure OrdersSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.ProductsOrders Then
		
		ShowValue(,Items.Orders.CurrentData.Products);
		
	ElsIf Field = Items.OrderDocument Then
		
		ShowValue(,Items.Orders.CurrentData.OrderDocument);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OrderDocumentStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure OrderDocumentClearing(Item, StandardProcessing)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure OrderDocumentCreating(Item, StandardProcessing)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure ProductsOrdersStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure ProductsOrdersClearing(Item, StandardProcessing)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure ProductsOrdersCreating(Item, StandardProcessing)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure MarkOrdersOnChange(Item)

	String = Items.Orders.CurrentData;
	UpdateTotalsInRow(String);
	UpdateTotals(ThisForm);
	FilterStructure1 = New Structure();
	If OnlyOrdersMarkedWithTheFilter Then
		FilterStructure1.Insert("Mark", True);
	EndIf;

	If ValueIsFilled(FilterStructure1) Then
		Items.Orders.RowFilter = New FixedStructure(FilterStructure1);
	Else
		Items.Orders.RowFilter = Undefined;
	EndIf;

EndProcedure

&AtClient
Procedure ToOrderOrdersOnChange(Item)

	String = Items.Orders.CurrentData;
	String.Mark = String.ToOrder > 0;
	UpdateTotalsInRow(String);
	UpdateTotals(ThisForm);

EndProcedure

&AtClient
Procedure SupplierOrdersStartChoice(Item, ChoiceData, StandardProcessing)

	String = Items.Orders.CurrentData;

	FormParameters = New Structure("Warehouse, Products, Characteristic, ThisIsWork, SupplyType");
	FillPropertyValues(FormParameters, String);
	FormParameters.SupplyType = PredefinedValue("Enum.SupplyTypes.Purchase");
	FormParameters.ThisIsWork = ValueIsFilled(String.ReceivingBusinessUnit);
	StandardProcessing = False;
	OpenForm("DataProcessor.DemandFulfillment.Form.SelectionFormOfSourceOfSupply", FormParameters, ThisForm);

EndProcedure

&AtClient
Procedure SupplierOrdersOnChange(Item)
	
	TableRow = Items.Orders.CurrentData;
	ProviderWhenChangingOnClient(TableRow);
	
EndProcedure

&AtClient
Procedure PriceOrdersOnChange(Item)

	String = Items.Orders.CurrentData;
	UpdateTotalsInRow(String);
	UpdateTotals(ThisForm);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region SwitchingBookmarks

&AtClient
Procedure Next(Command)

	If Object.Orders.Count() = 0 And Items.Tabs.CurrentPage = Items.TheInventoryPage Then

		FillInOrdersTable();
		ModifiedTheInventoryTable = False;

	ElsIf ModifiedTheInventoryTable And Items.Tabs.CurrentPage = Items.TheInventoryPage Then

		AddressInChangeStore = Undefined;
		If ThereAreChanges(AddressInChangeStore) And FulfillOrders = TextAtExpenseOfRemainder() Then

			FillInOrdersTable();
			ModifiedTheInventoryTable = False;

		EndIf;

	ElsIf Items.Tabs.CurrentPage = Items.OrdersPage Then

		Notifications = ToFormTheOrders();
		For Each Notification In Notifications Do
			Notify(Notification.EventName, Notification.NotificationParameters, Notification.Source);
		EndDo;
		
		ProcessingOfDocumentWritingNotificationsIsEnabled = True;

	ElsIf Items.Tabs.CurrentPage = Items.PageDocuments Then

		FillTables(False);

	EndIf;

	If Items.Tabs.CurrentPage = Items.TheInventoryPage Then
		SwitchPages("Orders", Items);
	ElsIf Items.Tabs.CurrentPage = Items.OrdersPage Then
		SwitchPages("Documents", Items);
	ElsIf Items.Tabs.CurrentPage = Items.PageDocuments Then
		SwitchPages("Inventories", Items);
		OrdersAreCreated = False;
		ProcessingOfDocumentWritingNotificationsIsEnabled = False;
	EndIf;

EndProcedure

&AtClient
Procedure Back(Command)

	If Items.Tabs.CurrentPage = Items.OrdersPage Then

		SwitchPages("Inventories", Items);

	ElsIf OrdersAreCreated Then

		SwitchPages("Orders", Items);
		OrdersAreCreated = False;
		ProcessingOfDocumentWritingNotificationsIsEnabled = False;
		ClearMessages();
		DeleteDocuments();
		ShowUserNotification(
			NStr("vi = 'Đánh dấu xóa chứng từ';
				|ru = 'Установка пометки удаления документов';
				|en = 'Set document deletion mark'; fa = 'Set document deletion mark';
				|it = 'Impostazione del contrassegno per l''eliminazione dei documenti';
				|pl = 'Ustawianie zaznaczenia usunięcia dokumentów';
				|tr = 'Belge silme işaretinin ayarlanması'"),
			,
			NStr("vi = 'Đã đánh dấu xóa đơn hàng đã tạo.';
				|ru = 'Сформированные заказы помечены на удаление.';
				|en = 'Generated documents are marked for deletion.'; fa = 'Generated documents are marked for deletion.';
				|it = 'Gli ordini generati sono stati contrassegnati per l''eliminazione.';
				|pl = 'Utworzone zamówienia są zaznaczone do usunięcia.';
				|tr = 'Oluşturulan siparişler silinmek üzere işaretlendi.'"));

	ElsIf Items.Tabs.CurrentPage = Items.PageDocuments Then

		SwitchPages("Orders", Items);

	EndIf;

EndProcedure

#EndRegion

#Region InventoryTableCommands

&AtClient
Procedure ToMarkInventory(Command)

	SetCheck(True, "Inventories");

EndProcedure

&AtClient
Procedure UnmarkInventory(Command)

	SetCheck(False, "Inventories");

EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.GenerationOfPurchaseOrders.DataProcessorForm.Command.SelectGoods");
	
	PickUpProductsOnClient();

EndProcedure

&AtClient
Procedure LoadFromFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.CheckCharacteristicPopulation = True;
	ImportParameters.ImportQuantity = False;
	ImportParameters.ImportInventory     = True;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Notification = New CallbackDescription("LoadFromFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure LoadFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		ProcessingSelectionOnServer(ImportedDataAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure ByFilter(Command)

	FormParameters = New Structure();
	FormParameters.Insert("Title",                NStr("vi = 'Chọn hàng hóa';
														|ru = 'Подбор товаров';
														|en = 'Pick goods'; fa = 'انتخاب کالاها';
														|it = 'Selezione delle merci';
														|pl = 'Wybór towarów';
														|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("TransferButtonTitle", NStr("vi = 'Chuyển vào danh sách';
														|ru = 'Перенести в список';
														|en = 'Move to list'; fa = 'Move to list';
														|it = 'Trasferire nell''elenco';
														|pl = 'Przenieś do listy';
														|tr = 'Listeye transfer et'"));
	FormParameters.Insert("UUID",  UUID);
	FormParameters.Insert("ChoiceMode",              True);

	ItemsTypes = New Array();
	ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	FilterByProductType = New FixedArray(ItemsTypes);
	FormParameters.Insert("FilterByProductType", FilterByProductType);

	OpenForm("DataProcessor.GoodsSelectionByPicking.Form", FormParameters, ThisForm);

EndProcedure

&AtClient
Procedure FillInTheSupplier(Command)

	Context = CurPageContext(ThisForm);

	If Context.SelectedRows.Count() = 0 Then

		ShowUserNotification(NStr("vi = 'Điền nhà cung cấp';
									|ru = 'Заполнение поставщика';
									|en = 'Fill in vendor'; fa = 'تکمیل تأمین‌کننده';
									|it = 'Compilazione del fornitore';
									|pl = 'Wypełnianie dostawcy';
									|tr = 'Tedarikçi doldurma'"),
			, NStr("vi = 'Để điền nhà cung cấp, cần tách chọn dòng của danh sách.';
					|ru = 'Для заполнения поставщика необходимо выделить строки списка.';
					|en = 'To fill in the vendor, select the list lines.'; fa = 'To fill in the vendor, select the list lines.';
					|it = 'Per compilare il fornitore è necessario selezionare le righe dell''elenco.';
					|pl = 'Dla wypełnienia dostawcy należy wybrać wiersze listy.';
					|tr = 'Tedarikçiyi doldurmak için listedeki satırlar seçilmeli.'"));

	Else

		ParametersOfSelectionForm = New Structure("Vendor");
		FormParameters = New Structure("Filter", ParametersOfSelectionForm);
		OpenForm("Catalog.Partners.ChoiceForm", FormParameters, ThisForm, UUID);

	EndIf;

EndProcedure

&AtClient
Procedure FillInMinBalance(Command)

	Context = CurPageContext(ThisForm);

	If Context.SelectedRows.Count() = 0 Then

		ShowUserNotification(NStr("vi = 'Điền số dư tối thiểu';
									|ru = 'Заполнение минимального остатка';
									|en = 'Fill in min stock level'; fa = 'تکمیل حداقل سطح موجودی';
									|it = 'Compilazione del residuo minimo';
									|pl = 'Wypełnienie minimalnego ostatku';
									|tr = 'Minimum bakiyenin doldurulması'"),
			, NStr("vi = 'Để điền số dư tối thiểu, cần tách chọn dòng của danh sách.';
					|ru = 'Для заполнения минимального остатка необходимо выделить строки списка.';
					|en = 'To fill in min stock level, select list lines.'; fa = 'To fill in min stock level, select list lines.';
					|it = 'Per la compilazione del residuo minimo è necessario selezionare le righe dell''elenco.';
					|pl = 'Dla wypełnienia minimalnego ostatku należy wybrać wiersze listy.';
					|tr = 'Minimum bakiyeyi doldurmak için listedeki satırlar seçilmeli.'"));

	Else

		FormParameters = New Structure("Mode", "MinimumBalance");
		OpenForm("DataProcessor.GenerationOfPurchaseOrders.Form.EnterValue",
			FormParameters, ThisForm, UUID);

	EndIf;

EndProcedure

&AtClient
Procedure FillInMaxBalance(Command)

	Context = CurPageContext(ThisForm);

	If Context.SelectedRows.Count() = 0 Then

		ShowUserNotification(NStr("vi = 'Điền số dư tối đa';
									|ru = 'Заполнение максимального остатка';
									|en = 'Fill in max balance'; fa = 'تکمیل حداکثر مانده';
									|it = 'Compilazione del residuo massimo';
									|pl = 'Wypełnienie maksymalnego ostatku';
									|tr = 'Maksimum bakiyenin doldurulması'"),
			, NStr("vi = 'Để điền số dư tối đa, cần tách chọn dòng của danh sách.';
					|ru = 'Для заполнения максимального остатка необходимо выделить строки списка.';
					|en = 'To fill in max balance, select list lines.'; fa = 'To fill in max balance, select list lines.';
					|it = 'Per la compilazione del residuo massimo è necessario selezionare le righe dell''elenco.';
					|pl = 'Dla wypełnienia maksymalnego ostatku należy wybrać wiersze listy.';
					|tr = 'Maksimum bakiyeyi doldurmak için listenin satırları seçilmeli.'"));

	Else

		FormParameters = New Structure("Mode", "MaximumBalance");
		OpenForm("DataProcessor.GenerationOfPurchaseOrders.Form.EnterValue",
			FormParameters, ThisForm, UUID);

	EndIf;

EndProcedure

&AtClient
Procedure LessThanMinBalance(Command)

	TagCommand("LessThanMinBalance");

EndProcedure

&AtClient
Procedure LessThanTheDoubleMinimumBalance(Command)

	TagCommand("LessThanTheDoubleMinimumBalance");

EndProcedure

&AtClient
Procedure OverMinimumBalance(Command)

	TagCommand("OverMinimumBalance");

EndProcedure

&AtClient
Procedure MoreThanMaxBalance(Command)

	TagCommand("MoreThanMaxBalance");

EndProcedure

&AtClient
Procedure DoNotReplenishGoods(Command)

	DoNotMaintainBalanceOnServer();

EndProcedure

#EndRegion

#Region TableCommandsOrders

&AtClient
Procedure ToMarkOrders(Command)

	SetCheck(True, "Orders");

EndProcedure

&AtClient
Procedure UnmarkOrders(Command)

	SetCheck(False, "Orders");

EndProcedure

#EndRegion

#Region SettingStatus

&AtClient
Procedure SetTheStatusNotAgreed_5(Command)

	SetStatus(New CallbackDescription("SetTheStatusNotAgreed_5Completion", ThisObject), "NotApproved", NStr("vi = 'Không thống nhất';
																											|ru = 'Не согласован';
																											|en = 'Not approved'; fa = 'تأییدنشده';
																											|it = 'Non concordato';
																											|pl = 'Nieuzgodniony';
																											|tr = 'Onaylanmadı'"));

EndProcedure

&AtClient
Procedure SetTheStatusToConfirmed(Command)

	SetStatus(New CallbackDescription("SetTheStatusToConfirmedCompletion", ThisObject), "Confirmed_", NStr("vi = 'Đã xác nhận';
																											|ru = 'Подтвержден';
																											|en = 'Confirmed'; fa = 'تأییدشده';
																											|it = 'Confermato';
																											|pl = 'Potwierdzony';
																											|tr = 'Teyit edildi'"));

EndProcedure

&AtClient
Procedure SetTheStatusOfTheAgreed_3(Command)

	SetStatus(New CallbackDescription("SetTheStatusOfTheAgreed_3Completion", ThisObject), "Approved", NStr("vi = 'Đã thống nhất';
																											|ru = 'Согласован';
																											|en = 'Approved'; fa = 'تأییدشده';
																											|it = 'Concordato';
																											|pl = 'Uzgodniony';
																											|tr = 'Onaylandı'"));

EndProcedure

&AtClient
Procedure MarkToDelete(Command)

	Rows = Items.ListDocuments.SelectedRows;
	If Rows.Count() = 0 Then
		Return;
	EndIf;
	Action = ?(Items.ListDocuments.CurrentData.DeletionMark, "UncheckDelete", "MarkToDelete");

	If Rows.Count() = 1 And Action = "MarkToDelete" Then

		Text = StrTemplate(NStr("vi = 'Đánh dấu xóa ""%1""';
								|ru = 'Пометить ""%1"" на удаление';
								|en = 'Mark ""%1"" for deletion.'; fa = 'Mark ""%1"" for deletion.';
								|it = 'Cotrassegnare ""%1"" per l''eliminazione';
								|pl = 'Zaznacz ""%1"" do usunięcia';
								|tr = '""%1"" silinmek üzere işaretle'"), Rows[0]);

	ElsIf Rows.Count() = 1 And Action = "UncheckDelete" Then

		Text = StrTemplate(NStr("vi = 'Bỏ dấu xóa từ ""%1""?';
								|ru = 'Снять с ""%1"" пометку удаления';
								|en = 'Clear deletion mark for ""%1""'; fa = 'Clear deletion mark for ""%1""';
								|it = 'Togliere il contrassegno di eliminazione da ""%1""';
								|pl = 'Usuń z ""%1"" zaznaczenie do usunięcia';
								|tr = 'Silinmek üzere ""%1"" işaretini kaldır'"), Rows[0]);

	ElsIf Action = "MarkToDelete" Then

		Text = NStr("vi = 'Đánh dấu xóa các đối tượng đã chọn';
					|ru = 'Пометить выделенные элементы на удаление';
					|en = 'Mark the selected items for deletion'; fa = 'Mark the selected items for deletion';
					|it = 'Contrassegnare gli elementi selezionari per la cancellazione';
					|pl = 'Zaznacz wybrane elementy do usunięcia';
					|tr = 'Seçilen öğeleri silinmek üzere işaretle'");

	ElsIf Action = "UncheckDelete" Then

		Text = NStr("vi = 'Bỏ dấu xóa của các phần tử được chọn';
					|ru = 'Снять с выделенных элементов опметку удаления';
					|en = 'Clear a deletion mark for the selected items'; fa = 'Clear a deletion mark for the selected items';
					|it = 'Togliere il contrassegno per la cancellazione da elementi selezionati';
					|pl = 'Usuń z wybranych elementów zaznaczenie do usunięcia';
					|tr = 'Seçilen öğelerin silinmek üzere işaretini kaldır'");

	EndIf;

	AddlParameters = New Structure("Action", Action);
	Notification = New CallbackDescription("RunDocumentsListCommand", ThisForm, AddlParameters);
	ShowQueryBox(Notification, Text, QuestionDialogMode.YesNo);

EndProcedure

&AtClient
Procedure Refresh(Command)
	
	Items.ListDocuments.Refresh();
	
EndProcedure

&AtClient
Procedure UndoPosting(Command)

	ClearMessages();
	RunDocumentsListCommandServer("CancelPosting");

EndProcedure

&AtClient
Procedure Post(Command)

	ClearMessages();
	RunDocumentsListCommandServer("Post");

EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Announcements

&AtClientAtServerNoContext
Function AttributesToSave()

	Return New Structure("FulfillOrders, SalesPeriod");

EndFunction

&AtClientAtServerNoContext
Function TextAtExpenseOfRemainder()

	Return NStr("vi = 'Do sự cân bằng';
				|ru = 'За счет остатка';
				|en = 'Use stock balance'; fa = 'استفاده از مانده موجودی';
				|it = 'Per il resto della fattura pro-forma';
				|pl = 'Z ostatka';
				|tr = 'Bakiye hesabına'");

EndFunction

#EndRegion

#Region FormSettings

&AtServer
Procedure ShouldSaveSettings()

	SettingsValue = AttributesToSave();
	FillPropertyValues(SettingsValue, ThisForm);
	SettingsValue.SalesPeriod = Object.SalesPeriod;
	Common.CommonSettingsStorageSave("DataProcessor.GenerationOfPurchaseOrders", "Main",
		SettingsValue);

EndProcedure

&AtServer
Procedure RestoreSettings()

	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessor.GenerationOfPurchaseOrders",
		"Main", , Users.CurrentUser());

	If Not TypeOf(SettingsValue) = Type("Structure") Then // first launch of the form, default settings

		SettingsValue = AttributesToSave();
		SettingsValue.FulfillOrders = TextAtExpenseOfRemainder();
		SettingsValue.SalesPeriod = 30;

	EndIf;

	FillPropertyValues(ThisForm, SettingsValue);
	Object.SalesPeriod = SettingsValue.SalesPeriod;

EndProcedure

#EndRegion

#Region FormCommandHandlersBackend

&AtServer
Procedure FillInProviderOnServer(Ref)
	
	PurchaseConditions = SupplyServer.PartnerSTermsOfPurchase(Ref);
	
	SessionDate = CurrentSessionDate();
	ParametersForGettingPrices = PartnerPricesFillingServer.NewParametersForGettingPartnerProductPrices();
	ParametersForGettingPrices.Date                         = SessionDate;
	ParametersForGettingPrices.Currency                       = PurchaseConditions.Currency;
	ParametersForGettingPrices.VATTaxation           = Enums.VATTaxationTypes.EmptyRef();
	ParametersForGettingPrices.ReturnReusablePackage = False;
	
	Table = New ValueTable();
	
	Table.Columns.Add("LineNumber",       Common.TypeDescriptionNumber(15, 0));
	Table.Columns.Add("Products",      New TypeDescription("CatalogRef.Products"));
	Table.Columns.Add("Characteristic",    New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Table.Columns.Add("Package",          New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Table.Columns.Add("VendorPriceKind", New TypeDescription("CatalogRef.VendorPriceTypes"));
	
	Context = CurPageContext(ThisForm);
	
	EmptyPackaging = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	CurrencyOfManAccounting_ = Constants.ManagementAccountingCurrency.Get();
	ZoomRatio = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		PurchaseConditions.Currency, CurrencyOfManAccounting_, SessionDate);
	
	For Each Id In Context.SelectedRows Do
	
		String = Context.Collection.FindByID(Id);
		
		String.Vendor         = Ref;
		String.Terms        = PurchaseConditions.Terms;
		String.VendorPriceKind = PurchaseConditions.VendorPriceKind;
		String.Price              = 0;
		
		If ValueIsFilled(String.VendorPriceKind) Then
			
			NewRow = Table.Add();
			
			NewRow.LineNumber       = Id;
			NewRow.Products      = String.Products;
			NewRow.Characteristic    = String.Characteristic;
			NewRow.Package          = EmptyPackaging;
			NewRow.VendorPriceKind = String.VendorPriceKind;
			
		EndIf;
		
	EndDo;
	
	QueryResult = PartnerPricesFillingServer.PartnerProductPrices(Table, ParametersForGettingPrices);
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		String = Context.Collection.FindByID(Selection.LineNumber);
		If ValueIsFilled(Selection.Price) Then
		
			String.Price = Selection.Price * ZoomRatio;
			
		EndIf;
		
	EndDo;
	
	For Each Id In Context.SelectedRows Do
	
		String = Context.Collection.FindByID(Id);
		UpdateTotalsInRow(String);
		
	EndDo;
	
	UpdateTotals(ThisForm);
	
EndProcedure

&AtServer
Procedure CalculateAverageDailyConsumptionOnServer()

	CalculationParameters = New Structure("SupplyFromStock", FulfillOrders = TextAtExpenseOfRemainder());
	DataProcessors.GenerationOfPurchaseOrders.UpdateSalesData(Object, CalculationParameters);
	
	ShouldSaveSettings();

EndProcedure

&AtServer
Function FillInFieldInSelectedLines(FieldName, Value, Calculate = False)

	Result = TableRegisterProductRestrictions();
	SupplyFromStock = FulfillOrders = TextAtExpenseOfRemainder();

	Context = CurPageContext(ThisForm);
	ThisIsFillingInSeveralFields = TypeOf(Value) = Type("Structure");

	For Each Id In Context.SelectedRows Do

		String = Context.Collection.FindByID(Id);

		If Not Calculate Then

			If ThisIsFillingInSeveralFields Then
				FillPropertyValues(String, Value, FieldName);
			Else
				String[FieldName] = Value;
			EndIf;

		ElsIf FieldName = "MinimumBalance" Or FieldName = "MaximumBalance" Then

			String[FieldName] = Value * String.AverageDailyConsumption;

		EndIf;

		If FieldName = "MinimumBalance" Or FieldName = "MaximumBalance" Then

			If String.PieceUnitOfMeasure Then

				If Not Calculate Then

					String[FieldName] = Int(String[FieldName]);

				Else

					String[FieldName] = Int(String[FieldName]) + ?(Int(String[FieldName]) < String[FieldName], 1, 0);

				EndIf;

			EndIf;

			CalculationResult2 = DataProcessors.GenerationOfPurchaseOrders.ToOrderToMaintainStock(String, SupplyFromStock);
			FillPropertyValues(String, CalculationResult2);

			NewRow = Result.Add();
			FillPropertyValues(NewRow, String);

			CalculationResult2 = DataProcessors.GenerationOfPurchaseOrders.ServiceDetails_(String);
			FillPropertyValues(String, CalculationResult2);
			NameOfMarkedCommandStockLevel = InventoryLevel();
			String.NotSatisfiesTheFilter = DataProcessors.GenerationOfPurchaseOrders.NotSatisfiesTheFilter(
				String, NameOfMarkedCommandStockLevel, FulfillOrders);

		EndIf;

	EndDo;

	Return Result;

EndFunction

&AtServer
Function TableRegisterProductRestrictions()

	Result = New ValueTable();
	Result.Columns.Add("Products",   New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Result.Columns.Add("Warehouse",          New TypeDescription("CatalogRef.Warehouses"));
	Result.Columns.Add("MinimumBalance",  TMCommonUse.GetDescriptionOfNumberTypes(15, 3));
	Result.Columns.Add("MaximumBalance", TMCommonUse.GetDescriptionOfNumberTypes(15, 3));

	Return Result;

EndFunction

&AtClientAtServerNoContext
Function CurPageContext(Form)

	Result = New Structure("Collection, SelectedRows, CurrentRow");

	If Form.Items.Tabs.CurrentPage = Form.Items.TheInventoryPage Then

		Result.Collection = Form.Object.Inventories;
		Result.SelectedRows = Form.Items.Inventories.SelectedRows;
		Result.CurrentRow = Form.Items.Inventories.CurrentRow;

	ElsIf Form.Items.Tabs.CurrentPage = Form.Items.OrdersPage Then

		Result.Collection = Form.Object.Orders;
		Result.SelectedRows = Form.Items.Orders.SelectedRows;
		Result.CurrentRow = Form.Items.Orders.CurrentRow;

	EndIf;

	Return Result;

EndFunction

&AtServer
Procedure FillTables(DeleteDocuments_ = True)

	If DeleteDocuments_ Then

		DeleteDocuments();

	EndIf;

	GeneratedOrders.Clear();
	Object.Inventories.Clear();
	Object.Orders.Clear();
	InventoryCopy.Clear();
	ModifiedTheInventoryTable = False;

	If ValueIsFilled(Object.Warehouse) Then

		CalculationParameters = New Structure("SupplyFromStock", FulfillOrders = TextAtExpenseOfRemainder());
		DataProcessors.GenerationOfPurchaseOrders.FillInByStockState(Object, CalculationParameters);
		Object.Inventories.Sort("Products, Characteristic, Warehouse");

		Columns = "Products, Characteristic, Warehouse, ToOrder";
		InventoryCopy.Load(Object.Inventories.Unload(New Structure("Mark", True), Columns));

	EndIf;

	UpdateTotals(ThisForm);

EndProcedure

&AtServer
Procedure ProcessingSelectionOnServer(ValueSelected)

	If IsTempStorageURL(ValueSelected) Then

		Table = GetFromTempStorage(ValueSelected);

	Else

		Table = New ValueTable();
		Table.Columns.Add("Products",   New TypeDescription("CatalogRef.Products"));
		Table.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));

		If TypeOf(ValueSelected) = Type("Array") Then

			For Each Item In ValueSelected Do
				NewRow = Table.Add();
				NewRow.Products = Item;
			EndDo;

		ElsIf TypeOf(ValueSelected) = Type("CatalogRef.Products") Then

			NewRow = Table.Add();
			NewRow.Products = ValueSelected;

		EndIf;

	EndIf;

	If Table.Columns.Find("Warehouse") = Undefined Then
		Table.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	EndIf;
	Table.FillValues(Object.Warehouse, "Warehouse");

	CalculationParameters = New Structure("SupplyFromStock", FulfillOrders = TextAtExpenseOfRemainder());
	CalculationParameters.Insert("ModifiedTheInventoryTable", False);
	DataProcessors.GenerationOfPurchaseOrders.AddProductsToInventoryTable(
		Object, Table, CalculationParameters, InventoryLevel(), FulfillOrders);
	ModifiedTheInventoryTable = CalculationParameters.ModifiedTheInventoryTable;

	UpdateTotals(ThisForm);

EndProcedure

&AtServer
Procedure EnteringValueOnServer(ValueSelected)

	If ValueSelected.Mode = "MinimumBalance" Or ValueSelected.Mode = "MaximumBalance" Then

		Table = FillInFieldInSelectedLines(ValueSelected.Mode, ValueSelected.Value,
			ValueSelected.Calculate);

	EndIf;

	DataProcessors.GenerationOfPurchaseOrders.RecordStockMaintenanceParameters(Table);
	UpdateTotals(ThisForm);

EndProcedure

&AtServer
Procedure RecordCurLineStockMaintenanceParameters()

	Table = TableRegisterProductRestrictions();

	String = Object.Inventories.FindByID(Items.Inventories.CurrentRow);
	FillPropertyValues(Table.Add(), String);
	DataProcessors.GenerationOfPurchaseOrders.RecordStockMaintenanceParameters(Table);

	SupplyFromStock = FulfillOrders = TextAtExpenseOfRemainder();

	CalculationResult2 = DataProcessors.GenerationOfPurchaseOrders.ToOrderToMaintainStock(String, SupplyFromStock);
	FillPropertyValues(String, CalculationResult2);

	CalculationResult2 = DataProcessors.GenerationOfPurchaseOrders.ServiceDetails_(String);
	FillPropertyValues(String, CalculationResult2);
	NameOfMarkedCommandStockLevel = InventoryLevel();
	String.NotSatisfiesTheFilter = DataProcessors.GenerationOfPurchaseOrders.NotSatisfiesTheFilter(
		String, NameOfMarkedCommandStockLevel, FulfillOrders);

	UpdateTotals(ThisForm);

EndProcedure

&AtServer
Procedure SetCheck(Mark, TableName)
	
	SelectedRows = ?(TableName = "Inventories", Items.Inventories.SelectedRows,
	                                            Items.Orders.SelectedRows);
	
	For Each Id In SelectedRows Do
		
		String = Object[TableName].FindByID(Id);
		String.Mark = Mark;
		UpdateTotalsInRow(String);
		
	EndDo;
	
	UpdateTotals(ThisForm);

EndProcedure

&AtServer
Procedure DoNotMaintainBalanceOnServer()

	For Each Id In Items.Inventories.SelectedRows Do

		String = Object.Inventories.FindByID(Id);
		
		If ValueIsFilled(String.Characteristic) Then
			RecordKey = InformationRegisters.ProductRestrictions.FeatureRecordingKey();
			RecordKey.Characteristic = String.Characteristic;
		Else
			RecordKey = InformationRegisters.ProductRestrictions.ProductEntryKey();
		EndIf;
		RecordKey.Products	= String.Products;
		RecordKey.Warehouse		= String.Warehouse;
		InformationRegisters.ProductRestrictions.RemoveStockMaintenance(RecordKey);
		
		String.MinimumBalance  = 0;
		String.MaximumBalance = 0;
		
		SupplyFromStock = FulfillOrders = TextAtExpenseOfRemainder();
		
		CalculationResult2 = DataProcessors.GenerationOfPurchaseOrders.ToOrderToMaintainStock(String, SupplyFromStock);
		FillPropertyValues(String, CalculationResult2);
		
		CalculationResult2 = DataProcessors.GenerationOfPurchaseOrders.ServiceDetails_(String);
		FillPropertyValues(String, CalculationResult2);
		NameOfMarkedCommandStockLevel = InventoryLevel();
		String.NotSatisfiesTheFilter = DataProcessors.GenerationOfPurchaseOrders.NotSatisfiesTheFilter(
			String, NameOfMarkedCommandStockLevel, FulfillOrders);
		ModifiedTheInventoryTable = True;

	EndDo;
	UpdateTotals(ThisForm);

EndProcedure

// Parameters:
//  QuestionResult - DialogReturnCode - The result of closing the window with a question to the user. 
//  AdditionalParameters - Structure - Structure of additional parameters for the execution of the alert.
&AtClient
Procedure RunDocumentsListCommand(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		ClearMessages();
		RunDocumentsListCommandServer(AdditionalParameters.Action);
	EndIf;

EndProcedure

&AtServer
Procedure RunDocumentsListCommandServer(Action = Undefined)

	If Action <> Undefined Then

		For Each Ref In Items.ListDocuments.SelectedRows Do

			Document = Ref.GetObject();

			Document.Lock();
			IsLocked = Document.IsLocked();

			If IsLocked Then

				If Action = "MarkToDelete" Then
					Document.SetDeletionMark(True);
				ElsIf Action = "UncheckDelete" Then
					Document.SetDeletionMark(False);
				ElsIf Action = "Post" Then
					If Document.CheckFilling() Then
						Document.Write(DocumentWriteMode.Posting);
					EndIf;
				ElsIf Action = "CancelPosting" Then
					Document.Write(DocumentWriteMode.UndoPosting);
				EndIf;

			EndIf;

		EndDo;

	EndIf;

	Items.ListDocuments.Refresh();

EndProcedure

#EndRegion

#Region DisplayFilters

&AtServer
Procedure TagCommand(CommandName)

	If Items[CommandName].Check Then Items[CommandName].Check = False;

		UpdateFilter("");

	Else

		Items.LessThanMinBalance.Check           = False;
		Items.LessThanTheDoubleMinimumBalance.Check = False;
		Items.OverMinimumBalance.Check           = False;
		Items.MoreThanMaxBalance.Check          = False;
		Items[CommandName].Check = True;

		UpdateFilter(CommandName);

	EndIf;

EndProcedure

&AtServer
Procedure UpdateFilter(InventoryLevel = Undefined)

	If InventoryLevel <> Undefined Then

		For Each String In Object.Inventories Do

			String.NotSatisfiesTheFilter = DataProcessors.GenerationOfPurchaseOrders.NotSatisfiesTheFilter(
				String, InventoryLevel, FulfillOrders);

		EndDo;

	EndIf;

	FilterStructure1 = New Structure();
	If InventoryLevel <> Undefined Then
		FilterStructure1.Insert("NotSatisfiesTheFilter", False);
	EndIf;

	If OnlyMarkedFilter Then
		FilterStructure1.Insert("Mark", True);
	EndIf;

	If ValueIsFilled(FilterStructure1) Then
		Items.Inventories.RowFilter = New FixedStructure(FilterStructure1);
	Else
		Items.Inventories.RowFilter = Undefined;
	EndIf;

EndProcedure

&AtServer
Function InventoryLevel()

	Result = ?(Items.LessThanMinBalance.Check, "LessThanMinBalance",
				?(Items.LessThanTheDoubleMinimumBalance.Check, "LessThanTheDoubleMinimumBalance",
				?(Items.OverMinimumBalance.Check, "OverMinimumBalance",
				?(Items.MoreThanMaxBalance.Check, "MoreThanMaxBalance",
					""))));

	Return Result;

EndFunction

#EndRegion

#Region SwitchingPages

&AtClient
Procedure TabsOnCurrentPageChange(Item, CurrentPage)

	If OrdersAreCreated Then

		OrdersAreCreated = False;
		ProcessingOfDocumentWritingNotificationsIsEnabled = False;
		DeleteDocuments();
		ClearMessages();
		ShowUserNotification(NStr("vi = 'Xóa chứng từ';
									|ru = 'Удаление документов';
									|en = 'Remove documents'; fa = 'Remove documents';
									|it = 'Cancellazione documenti';
									|pl = 'Usuwanie dokumentów';
									|tr = 'Belgelerin silinmesi'"), , NStr("vi = 'Đơn hàng đã lập bị xóa bỏ.';
																	|ru = 'Сформированные заказы удалены.';
																	|en = 'Generated orders are removed.'; fa = 'Generated orders are removed.';
																	|it = 'Ordini formati sono stati cancellati.';
																	|pl = 'Utworzone zamówienia zostały usunięte';
																	|tr = 'Oluşturulan siparişler silindi.'"));

	EndIf;

	If Items.Tabs.CurrentPage = Items.TheInventoryPage Then
		SwitchPages("Inventories", Items);
	ElsIf Items.Tabs.CurrentPage = Items.OrdersPage Then
		SwitchPages("Orders", Items);
	ElsIf Items.Tabs.CurrentPage = Items.PageDocuments Then
		SwitchPages("Documents", Items);
	EndIf;

	If Object.Orders.Count() = 0 And Items.Tabs.CurrentPage = Items.OrdersPage Then

		FillInOrdersTable();
		ModifiedTheInventoryTable = False;

	ElsIf ModifiedTheInventoryTable And Items.Tabs.CurrentPage = Items.OrdersPage Then

		AddressInChangeStore = Undefined;
		If ThereAreChanges(AddressInChangeStore) And FulfillOrders = TextAtExpenseOfRemainder() Then

			FillInOrdersTable();
			ModifiedTheInventoryTable = False;

		EndIf;

	ElsIf Items.Tabs.CurrentPage = Items.PageDocuments Then

		If Object.Orders.Count() = 0 Then

			FillInOrdersTable();
			ModifiedTheInventoryTable = False;

		EndIf;

		Notifications = ToFormTheOrders();
		For Each Notification In Notifications Do
			Notify(Notification.EventName, Notification.NotificationParameters, Notification.Source);
		EndDo;
		
		ProcessingOfDocumentWritingNotificationsIsEnabled = True;

	EndIf;

EndProcedure

&AtServer
Procedure FillInOrdersTable()

	DataProcessors.GenerationOfPurchaseOrders.FillByOrderState(Object, FulfillOrders = TextAtExpenseOfRemainder());
	UpdateTotals(ThisForm);

EndProcedure

&AtClientAtServerNoContext
Procedure SwitchPages(StepName, Items)

	If StepName = "Inventories" Then

		Items.Tabs.CurrentPage      = Items.TheInventoryPage;
		Items.FooterSteps.CurrentPage    = Items.PageFooterDemands;

		Items.PagesBack.CurrentPage = Items.BackHide;
		Items.PagesNext.CurrentPage = Items.NextVisibility;
		Items.Next.DefaultButton = True;

	ElsIf StepName = "Orders" Then

		Items.Tabs.CurrentPage      = Items.OrdersPage;
		Items.FooterSteps.CurrentPage    = Items.PageFooterDemands;

		Items.PagesBack.CurrentPage = Items.BackVisibility;
		Items.PagesNext.CurrentPage = Items.NextVisibility;
		Items.Next.DefaultButton = True;

	ElsIf StepName = "Documents" Then

		Items.Tabs.CurrentPage      = Items.PageDocuments;
		Items.FooterSteps.CurrentPage    = Items.PageFooterCreatedOrders;

		Items.PagesBack.CurrentPage = Items.BackVisibility;
		Items.PagesNext.CurrentPage = Items.ContinueForAnotherWarehouseVisibility;
		Items.Done.DefaultButton = True;

	EndIf;

EndProcedure

&AtServer
Function ThereAreChanges(AddressInChangeStore)

	String_Key = "Products,Characteristic,Warehouse";
	Columns     = "Products, Characteristic, Warehouse, ToOrder";

	OrderRequirementsTable = Object.Inventories.Unload(New Structure("Mark", True), Columns);
	MergeParameters = SupplyClientServer.TableJoinParameters();
	MergeParameters.AddLines_ = True;
	MergeParameters.Defaults = New Structure("ToOrder", 0);

	Table1Copy = InventoryCopy.Unload();
	SupplyServer.UpdateCollectionWithDataFromTable(
		Table1Copy, OrderRequirementsTable, String_Key, MergeParameters);

	HasChanges = MergeParameters.ModifiedRows.Count() > 0 Or MergeParameters.NewLines.Count() > 0;

	If HasChanges Then

		InventoryCopy.Load(OrderRequirementsTable);

		For Each String In MergeParameters.NewLines Do

			NewRow = MergeParameters.ModifiedRows.Add();
			FillPropertyValues(NewRow, String);

		EndDo;

		AddressInChangeStore = PutToTempStorage(MergeParameters.ModifiedRows);

	EndIf;

	Return HasChanges;

EndFunction

&AtServer
Procedure ProvideOrdersWhenChangedOnServer()

	CustomizeItemsWhenChangingBankingDetails("FulfillOrders");
	SwitchPages("Inventories", Items);
	FillTables(False);
	ModifiedTheInventoryTable = False;
	
	ShouldSaveSettings();

EndProcedure

#EndRegion

#Region Other

&AtClient
Function ProviderWhenChangingOnClient(TableRow)
	
	ProductDetails_ = New Structure("Products, Characteristic");
	FillPropertyValues(ProductDetails_, TableRow);
	PurchaseConditions = PurchaseConditions(TableRow.Vendor, ProductDetails_);
	FillPropertyValues(TableRow, PurchaseConditions, "Terms,VendorPriceKind,Price");
	UpdateTotalsInRow(TableRow);
	UpdateTotals(ThisForm);
	
EndFunction

&AtServerNoContext
Function PurchaseConditions(Vendor, ProductDetails_)
	
	PurchaseConditions = SupplyServer.PartnerSTermsOfPurchase(Vendor);
	
	SessionDate = CurrentSessionDate();
	ParametersForGettingPrices = PartnerPricesFillingServer.NewParametersForGettingPartnerProductPrices();
	ParametersForGettingPrices.Date         = SessionDate;
	ParametersForGettingPrices.Currency       = PurchaseConditions.Currency;
	ParametersForGettingPrices.VATTaxation           = Enums.VATTaxationTypes.EmptyRef();
	ParametersForGettingPrices.ReturnReusablePackage = False;
	
	Table = New ValueTable();
	
	Table.Columns.Add("LineNumber",       Common.TypeDescriptionNumber(15, 0));
	Table.Columns.Add("Products",      New TypeDescription("CatalogRef.Products"));
	Table.Columns.Add("Characteristic",    New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Table.Columns.Add("Package",          New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Table.Columns.Add("VendorPriceKind", New TypeDescription("CatalogRef.VendorPriceTypes"));
	
	NewRow = Table.Add();
	
	NewRow.Products      = ProductDetails_.Products;
	NewRow.Characteristic    = ProductDetails_.Characteristic;
	NewRow.Package          = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	NewRow.VendorPriceKind = PurchaseConditions.VendorPriceKind;
	
	QueryResult = PartnerPricesFillingServer.PartnerProductPrices(Table, ParametersForGettingPrices);
	PurchaseConditions.Price = 0;
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		If ValueIsFilled(Selection.Price) Then
			
			CurrencyOfManAccounting_ = Constants.ManagementAccountingCurrency.Get();
			ZoomRatio = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
				PurchaseConditions.Currency, CurrencyOfManAccounting_, SessionDate);
				
			PurchaseConditions.Price = Selection.Price * ZoomRatio;
			
		EndIf;
		
	EndIf;
	
	Return PurchaseConditions;
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateTotalsInRow(String)

	String.WeightTotal   = ?(String.Mark, String.ToOrder * String.Weight, 0);
	String.VolumeTotal = ?(String.Mark, String.ToOrder * String.VolumeM3, 0);
	String.Sum     = String.Price * String.ToOrder;
	String.AmountTotal = ?(String.Mark, String.Sum, 0);

EndProcedure

&AtClientAtServerNoContext
Procedure UpdateTotals(Form)

	Form.TotalAmount_5 = Form.Object.Inventories.Total("AmountTotal") + Form.Object.Orders.Total("AmountTotal");
	Form.TotalWeight_2   = Form.Object.Inventories.Total("WeightTotal") + Form.Object.Orders.Total("WeightTotal");
	Form.TotalVolume_3 = Form.Object.Inventories.Total("VolumeTotal") + Form.Object.Orders.Total("VolumeTotal");

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	// Allocation of zero maximum residuals.
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaximumBalance.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Inventories.MaximumBalance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

	// Allocation of zero prices.
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ThePriceOfStocks.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Inventories.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PriceOrders.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Orders.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	
	// The document has a high priority
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chứng từ có mức ưu tiên cao';
							|ru = 'Документ имеет высокий приоритет';
							|en = 'High priority document'; fa = 'سند با اولویت بالا';
							|it = 'Il documento ha priorità alta';
							|pl = 'Dokument ma wysoki priorytet';
							|tr = 'Belge yüksek önceliğe sahiptir'");

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Orders.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Orders.Priority");
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
	ItemField.Field = New DataCompositionField(Items.Orders.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Orders.Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Priorities.GetLowerPriority();
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.LowDocumentPriority);
	
	// Conditional design of the dynamic list "List"
	ListOfConditionalAppearance = ListDocuments.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearance.Items.Clear();
	
	// The document has a high priority
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chứng từ có mức ưu tiên cao';
							|ru = 'Документ имеет высокий приоритет';
							|en = 'High priority document'; fa = 'سند با اولویت بالا';
							|it = 'Il documento ha priorità alta';
							|pl = 'Dokument ma wysoki priorytet';
							|tr = 'Belge yüksek önceliğe sahiptir'");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Priorities.GetTopPriority();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.PurchaseOrderStates.Closed;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.HighPriorityDocument);
	
	// The document has a low priority
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chứng từ có mức ưu tiên thấp';
							|ru = 'Документ имеет низкий приоритет';
							|en = 'Low priority document'; fa = 'Low priority document';
							|it = 'Il documento ha priorità bassa';
							|pl = 'Dokument ma niski priorytet';
							|tr = 'Belge düşük önceliğe sahiptir'");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Priorities.GetLowerPriority();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.PurchaseOrderStates.Closed;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.LowDocumentPriority);
	
	// Color highlighting of the "Closed" status
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tách trạng thái ""Đã đóng"" bằng màu';
							|ru = 'Выделение цветом состояния ""Закрыт""';
							|en = 'Highlighting the ""Closed"" state'; fa = 'Highlighting the ""Closed"" state';
							|it = 'Evidenziamento con il colore dello stato ""Chiuso""';
							|pl = 'Wyróżnienie kolorem statusu ""Закрыт""';
							|tr = '""Kapalı"" durumunun vurgu rengi'");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PurchaseOrderStates.Closed;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
	// Highlighting an overdue order in color
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tách đơn hàng quá hạn bằng màu';
							|ru = 'Выделение цветом просроченного заказа';
							|en = 'Highlighting overdue order'; fa = 'Highlighting overdue order';
							|it = 'Evidenziamento con il colore di un ordine scaduto';
							|pl = 'Wyróżnienie kolorem zaległego zamówienia';
							|tr = 'Vadesi geçmiş siparişin vurgu rengi'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField("State");
	Item.Fields.Items.Add().Field = New DataCompositionField("EventDate");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Overdue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDocument);

EndProcedure

&AtServer
Procedure CustomizeItemsWhenChangingBankingDetails(Var_AttributeName = Undefined)

	If Var_AttributeName = "FulfillOrders" Or Var_AttributeName = Undefined Then

		SupplyFromStock = FulfillOrders = TextAtExpenseOfRemainder();

		ItemsDueToInventory = New Array();
		ItemsDueToInventory.Add(Items.Balance);
		ItemsDueToInventory.Add(Items.OnQualityControlBalance);
		ItemsDueToInventory.Add(Items.OrdersPendingGoodsReceipt);
		ItemsDueToInventory.Add(Items.OrderPointIsAchieved);

		ItemsNotAtExpenseOfInventory = New Array();
		ItemsNotAtExpenseOfInventory.Add(Items.AvailableStock);
		ItemsNotAtExpenseOfInventory.Add(Items.UnderQualityControlAvailableBalance);
		ItemsNotAtExpenseOfInventory.Add(Items.OrdersPendingGoodsReceiptFree);
		ItemsNotAtExpenseOfInventory.Add(Items.TheOrderHasReachedTheFreeBalance);

		For Each Item In ItemsDueToInventory Do
			Item.Visible = SupplyFromStock;
		EndDo;

		For Each Item In ItemsNotAtExpenseOfInventory Do
			Item.Visible = Not SupplyFromStock;
		EndDo;

	EndIf;

	If Var_AttributeName = "Warehouse" Or Var_AttributeName = Undefined Then

		MutableElements = New Array();
		MutableElements.Add(Items.SelectGoods);
		MutableElements.Add(Items.LoadFromFile);
		MutableElements.Add(Items.ByFilter);
		MutableElements.Add(Items.LessThanMinBalance);
		MutableElements.Add(Items.LessThanTheDoubleMinimumBalance);
		MutableElements.Add(Items.OverMinimumBalance);
		MutableElements.Add(Items.MoreThanMaxBalance);
		MutableElements.Add(Items.FillInTheSupplierSInventory);
		MutableElements.Add(Items.FillInMinBalance);
		MutableElements.Add(Items.FillInMaxBalance);
		MutableElements.Add(Items.DonTMaintainTheBalance);
		MutableElements.Add(Items.ToMarkInventory);
		MutableElements.Add(Items.UnmarkInventory);
		MutableElements.Add(Items.OnlyMarkedStocks);
		MutableElements.Add(Items.FillInTheSupplierInventoryContext);
		MutableElements.Add(Items.FillInTheMinimumBalanceContext);
		MutableElements.Add(Items.FillInTheMaximumRemainingContext);
		MutableElements.Add(Items.DonTSupportTheRestOfTheContext);

		MutableElements.Add(Items.ToMarkOrders);
		MutableElements.Add(Items.UnmarkOrders);
		MutableElements.Add(Items.OnlyTheCheckedOrders);
		MutableElements.Add(Items.FillOutSupplierOrders);
		MutableElements.Add(Items.FillInTheSupplierOrdersContext);

		WarehouseIsFull = ValueIsFilled(Object.Warehouse);

		For Each Item In MutableElements Do
			Item.Enabled = WarehouseIsFull;
		EndDo;

	EndIf;

EndProcedure

&AtServer
Procedure DeleteDocuments()

	ArrayOfDeleteLinks = GeneratedOrders.UnloadValues();
	ErrorList = TMCommonUse.SetMarkForDeletingDocuments(ArrayOfDeleteLinks);
	CommonClientServer.ReportErrorsToUser(ErrorList);
	
	GeneratedOrders.Clear();

EndProcedure

// Returns:
//  Array of Structure:
//   * EventName - String - event name.
//   * NotificationParameters - Structure - Structure of notification parameters.
//   * Source - DocumentRef - link to the document. 
&AtServer
Function ToFormTheOrders()
	
	DeleteDocuments();
	
	Result = DataProcessors.GenerationOfPurchaseOrders.CreateOrders(Object);
	
	Notifications = New Array();
	For Each Document In Result.Documents Do
		
		GeneratedOrders.Add(Document.Ref);
		
		WriteMode = ?(Document.Posted = 0, DocumentWriteMode.Posting, DocumentWriteMode.Write);
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("WriteMode", WriteMode);
		NotificationParameters.Insert("ThereIsOrder_", True);
		
		Notifications.Add(New Structure("EventName, NotificationParameters, Source",
			"Write_PurchaseOrder", NotificationParameters, Document.Ref));
		
	EndDo;
	
	For Each Message In Result.Messages Do
		Message.Message();
	EndDo;
	
	OrdersAreCreated = GeneratedOrders.Count() > 0;
	
	ListDocuments.Parameters.SetParameterValue("CreatedDocuments", GeneratedOrders.UnloadValues());

	Return Notifications;

EndFunction

&AtClient
Procedure PickUpProductsOnClient()

	FormParameters = New Structure();
	FormParameters.Insert("TransferButtonTitle", NStr("vi = 'Chuyển vào danh sách hàng hóa';
														|ru = 'Перенести в список товаров';
														|en = 'Move to the Item list'; fa = 'Move to the Item list';
														|it = 'Trasferire nell''elenco di merci';
														|pl = 'Przenieś do listy towarów';
														|tr = 'Ürün listesine transfer'"));
	FormParameters.Insert("ModeOfSelectionWithoutQuantitativeParameters", True);
	FormParameters.Insert("SelectionModeWithoutAmountParameters",       True);
	FormParameters.Insert("Warehouse",                                   Object.Warehouse);
	FormParameters.Insert("Document",                                NStr("vi = 'Lập đơn hàng đặt nhà cung cấp';
																			|ru = 'Формирование заказов поставщикам';
																			|en = 'Purchase order generation'; fa = 'ایجاد سفارش خرید';
																			|it = 'Generazione di ordini ai fornitori';
																			|pl = 'Tworzenie zamówień do dostawców';
																			|tr = 'Satın alma siparişini oluşturma'"));
	FormParameters.Insert("CheckFilling",                     True);

	ListOfProductTypes = New ValueList();
	ListOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ListOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));

	FormParameters.Insert("FilterByProductType", ListOfProductTypes);

	FormParameters.Insert("Filter", New Structure("ItemsType", ListOfProductTypes));

	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisObject, UUID);

EndProcedure

#EndRegion

#Region FormCommandHandlersClientPart

&AtClient
Procedure SetTheStatusNotAgreed_5Completion(Result, AdditionalParameters) Export
	
	Items.ListDocuments.Refresh();
	
EndProcedure

&AtClient
Procedure SetTheStatusToConfirmedCompletion(Result, AdditionalParameters) Export
	
	Items.ListDocuments.Refresh();
	
EndProcedure

&AtClient
Procedure SetTheStatusOfTheAgreed_3Completion(Result, AdditionalParameters) Export
	
	Items.ListDocuments.Refresh();
	
EndProcedure

&AtClient
Procedure SetStatus(Val Notification, Status, StatusText)

	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.ListDocuments);
	If SelectedRows.Count() = 0 Then
		RunCallback(Notification);
		Return;
	EndIf;
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Trong các đơn hàng đã chọn từ danh sách sẽ đặt trạng thái ""%1"". Tiếp tục?';
			|ru = 'У выделенных в списке заказов будет установлен статус ""%1"". Продолжить?';
			|en = 'The ""%1"" status will be set for the orders selected in the list. Continue?'; fa = 'The ""%1"" status will be set for the orders selected in the list. Continue?';
			|it = 'Per gli ordini selezionati nell''elenco verrà impostato lo stato ""%1"". Continuare?';
			|pl = 'Dla wybranych w liście zamówień będzie ustawiony status ""%1"". Kontynuować?';
			|tr = 'Sipariş listesinde seçilen siparişlerin durumu ""%1"" olacaktır. Devam edilsin mi?'"), StatusText);

	Response = Undefined;

	AdditionalStatusSettings = New Structure("SelectedRows, Notification, Status, StatusText");
	AdditionalStatusSettings.SelectedRows = SelectedRows;
	AdditionalStatusSettings.Notification       = Notification;
	AdditionalStatusSettings.Status           = Status;
	AdditionalStatusSettings.StatusText     = StatusText;
	
	DescriptionOfStatusSettingNotification = New CallbackDescription("SetStatusCompletion", ThisObject, AdditionalStatusSettings);
	ShowQueryBox(DescriptionOfStatusSettingNotification, QueryText, QuestionDialogMode.YesNo);

EndProcedure

&AtClient
Procedure SetStatusCompletion(QuestionResult, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    Notification = AdditionalParameters.Notification;
    Status = AdditionalParameters.Status;
    StatusText = AdditionalParameters.StatusText;
    
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.No Then
        RunCallback(Notification);
        Return;
    EndIf;
    
    ClearMessages();
    ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, Status);
    TMCommonUseClient.NotifyUserAboutSettingStatus(Items.ListDocuments, ProcessedItemsCount,
    SelectedRows.Count(), StatusText);
    
    RunCallback(Notification);

EndProcedure

#EndRegion

#EndRegion