
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	Dispatcher = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);

	OrderList.Parameters.SetParameterValue("UpdateDate", BegOfDay(CurrentSessionDate()));

	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterDueDate_2.ChoiceList);
	ListSelectionsClientServer.SelectionByRelevanceWhenCreatingOnServer(OrderList, Relevance, Items.FilterDueDate_2.ChoiceList, EventDate, QuickFilterStructure);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	FillInCouriersAndPickers();
	CommonClientServer.SetDynamicListFilterItem(OrderList, "Status", Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));
	CommonClientServer.SetDynamicListFilterItem(OrderList, "EventDate", EventDate, DataCompositionComparisonType.Equal,, ValueIsFilled(EventDate));
	CommonClientServer.SetDynamicListFilterItem(OrderList, "Warehouse", WarehouseSelection, DataCompositionComparisonType.Equal,, ValueIsFilled(WarehouseSelection));
	CommonClientServer.SetDynamicListFilterItem(OrderList, "DeliveryZone", DeliveryZone, DataCompositionComparisonType.Equal,, ValueIsFilled(DeliveryZone));

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)

	ListSelectionsClientServer.SelectionByRelevanceWhenLoadingFromSettings(OrderList, Relevance, Items.FilterDueDate_2.ChoiceList, EventDate, QuickFilterStructure, Settings);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterDueDate_2OnChange(Item)

	ListSelectionsClientServer.WhenChangingRelevanceSelection(OrderList, Relevance, EventDate, Items.FilterDueDate_2.ChoiceList);
	
EndProcedure

&AtClient
Procedure FilterDueDate_2ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TMCommonUseClient.WhenSelectingRelevanceSelection(
		ValueSelected, 
		StandardProcessing, 
		ThisObject,
		OrderList, 
		"Relevance",
		"FilterDueDate_2",
		"EventDate");
	
EndProcedure

&AtClient
Procedure FilterCompletionDateCleaningUp(Item, StandardProcessing)
	
	ListSelectionsClientServer.WhenClearingSelectionByRelevance(OrderList, Relevance, EventDate, StandardProcessing);
	FillInCouriersAndPickers();
	If Not ValueIsFilled(Relevance) Then
		StandardProcessing = False;
	EndIf
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)

	CommonClientServer.SetDynamicListFilterItem(OrderList, "Status", Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));

EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)

	CommonClientServer.SetDynamicListFilterItem(OrderList, "Warehouse", WarehouseSelection, DataCompositionComparisonType.Equal,, ValueIsFilled(WarehouseSelection));
	FillInCouriersAndPickers();

EndProcedure

&AtClient
Procedure DeliveryZoneOnChange(Item)

	CommonClientServer.SetDynamicListFilterItem(OrderList, "DeliveryZone", DeliveryZone, DataCompositionComparisonType.Equal,, ValueIsFilled(DeliveryZone));

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOrderList

&AtClient
Procedure OrderListOnActivateRow(Item)
	CurrentOrder = Item.CurrentRow;
	AttachIdleHandler("ProcessListRowActivation", 0.2, True);
EndProcedure

&AtClient
Procedure OrderListSelection(Item, RowSelected, Field, StandardProcessing)
	ShowValue(, RowSelected);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCouriers

&AtClient
Procedure CouriersDragCheck(Item, DragParameters, StandardProcessing, String, Field)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure CouriersDrag(Item, DragParameters, StandardProcessing, String, Field)

	If String = Undefined Then
		Return;
	EndIf;

	Courier = Couriers.FindByID(String).Courier;

	ClearMessages();
	InstallCourierInOrders(DragParameters.Value, Courier);
	UpdateDataOnForm();

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCollectors

&AtClient
Procedure CollectorsDragCheck(Item, DragParameters, StandardProcessing, String, Field)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure CollectorsDrag(Item, DragParameters, StandardProcessing, String, Field)

	If String = Undefined Then
		Return;
	EndIf;

	Picker = Collectors.FindByID(String).Picker;

	ClearMessages();
	InstallCollectorInOrders(DragParameters.Value, Picker);
	UpdateDataOnForm();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	AttachIdleHandler("ProcessListRowActivation", 0.2, True);
EndProcedure

&AtClient
Procedure AssignACourier(Command)
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("ThisIsCourier", True);
	ChoiceParameters.Insert("Warehouse", WarehouseSelection);
	
	CallbackDescription = New CallbackDescription("AssignACourierCompletion", ThisObject);
	
	OpenForm("DataProcessor.DispatchingAssemblyAndDelivery.Form.EmployeeChoiceForm",
		ChoiceParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure ToAppointTheCollector(Command)
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("ThisIsCourier", False);
	ChoiceParameters.Insert("Warehouse", WarehouseSelection);
	
	CallbackDescription = New CallbackDescription("ToAppointTheCollectorCompletion", ThisObject);
	
	OpenForm("DataProcessor.DispatchingAssemblyAndDelivery.Form.EmployeeChoiceForm",
		ChoiceParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure RemoveTheCourier(Command)

	RemoveCourierFromServer();
	UpdateDataOnForm();

EndProcedure

&AtClient
Procedure RemoveTheCollector(Command)

	RemoveMailFetcherFromServer();
	UpdateDataOnForm();

EndProcedure

&AtClient
Procedure NewOrder(Command)
	OpenForm("Document.SalesOrder.ObjectForm");
EndProcedure

&AtClient
Procedure NewImplementation(Command)
	OpenForm("Document.CustomerInvoice.ObjectForm");
EndProcedure

&AtClient
Procedure Settings(Command)

	OpenForm("DataProcessor.DispatchingAssemblyAndDelivery.Form.Settings",,
		ThisObject,,,,
		New CallbackDescription("SettingsCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure SettingsCompletion(ClosingResult, AdditionalParameters) Export

	UpdateDataOnForm();

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessListRowActivation()
	
	FillInOrderInformationOnServer();
	
EndProcedure

&AtServer
Procedure FillInOrderInformationOnServer()
	
	If CurrentOrder.IsEmpty() Then
		OrderPresentation = "";
		Details_Of_Order = "";
		InformationAboutOrder = "";
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SalesOrder.DeliveryAddress AS DeliveryAddress,
	|	SalesOrder.Comment AS Comment,
	|	SalesOrder.Number AS Number,
	|	SalesOrder.DocumentAmount AS DocumentAmount,
	|	SalesOrder.Partner AS Partner,
	|	SalesOrder.Currency AS Currency
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|WHERE
	|	SalesOrder.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CustomerOrderGoods.Products AS OwnGoods,
	|	SUM(CustomerOrderGoods.Count) AS Count,
	|	SUM(CustomerOrderGoods.Sum) AS Sum
	|FROM
	|	Document.SalesOrder.Goods AS CustomerOrderGoods
	|WHERE
	|	CustomerOrderGoods.Ref = &Ref
	|
	|GROUP BY
	|	CustomerOrderGoods.Products";
	
	Query.SetParameter("Ref", CurrentOrder);
	
	QueryResult = Query.ExecuteBatch();
	
	Goods = QueryResult[1].Unload();
	OrderComposition.Load(Goods);

	OrderProperties = QueryResult[0].Unload()[0];
	
	CIKindPhone = Catalogs.ContactInformationKinds.PartnerSPhoneNumber;
	CustomerSPhoneNumber = ContactsManager.ObjectContactInformation(OrderProperties.Partner, CIKindPhone,, True);

	OrderPresentation = New FormattedString(StrTemplate(NStr("vi = 'Đơn hàng: %1';
															|ru = 'Заказ № %1';
															|en = 'Order No. %1'; fa = 'Order No. %1';
															|it = 'Заказ № %1';
															|pl = 'Order No. %1';
															|tr = 'Sipariş: %1'"), OrderProperties.Number), StyleFonts.DesignationTitleFont);
	Details_Of_Order = New FormattedString(StrTemplate(NStr("vi = 'Số tiền: %1 %2';
															|ru = 'Сумма: %1 %2';
															|en = 'Amount: %1 %2'; fa = 'Amount: %1 %2';
															|it = 'Сумма: %1 %2';
															|pl = 'Amount: %1 %2';
															|tr = 'Tutar: %1%2'"), Format(OrderProperties.DocumentAmount, "NFD=2; NZ=0"), OrderProperties.Currency));

	PartsOfFormattedString = New Array;
	If ValueIsFilled(OrderProperties.Partner) Then
		PartsOfFormattedString.Add(New FormattedString(NStr("vi = 'Khách hàng';
															|ru = 'Клиент';
															|en = 'Customer'; fa = 'مشتری';
															|it = 'Клиент';
															|pl = 'Customer';
															|tr = 'İstemci'") + ": ", StyleFonts.ImportantLabelFont));
		PartsOfFormattedString.Add(String(OrderProperties.Partner));
	EndIf;
	If Not IsBlankString(CustomerSPhoneNumber) Then
		If PartsOfFormattedString.Count() Then
			PartsOfFormattedString.Add(" ");
		EndIf;
		PartsOfFormattedString.Add(New FormattedString(NStr("vi = 'Điện thoại';
															|ru = 'Телефон';
															|en = 'Phone number'; fa = 'شماره تلفن';
															|it = 'Телефон';
															|pl = 'Phone number';
															|tr = 'Telefon'") + ": ", StyleFonts.ImportantLabelFont));
		PartsOfFormattedString.Add(CustomerSPhoneNumber);
	EndIf;
	If Not IsBlankString(OrderProperties.DeliveryAddress) Then
		If PartsOfFormattedString.Count() Then
			PartsOfFormattedString.Add(" ");
		EndIf;
		PartsOfFormattedString.Add(New FormattedString(NStr("vi = 'Địa chỉ giao nhận';
															|ru = 'Адрес доставки';
															|en = 'Delivery address'; fa = 'آدرس تحویل';
															|it = 'Адрес доставки';
															|pl = 'Adres dostawy';
															|tr = 'Teslimat adresi'") + ": ", StyleFonts.ImportantLabelFont));
		PartsOfFormattedString.Add(OrderProperties.DeliveryAddress);
	EndIf;
	If Not IsBlankString(OrderProperties.Comment) Then
		If PartsOfFormattedString.Count() Then
			PartsOfFormattedString.Add(" ");
		EndIf;
		PartsOfFormattedString.Add(New FormattedString(NStr("vi = 'Ghi chú';
															|ru = 'Комментарий';
															|en = 'Comment'; fa = 'توضیحات';
															|it = 'Комментарий';
															|pl = 'Comment';
															|tr = 'Yorum'") + ": ", StyleFonts.ImportantLabelFont));
		PartsOfFormattedString.Add(OrderProperties.Comment);
	EndIf;

	InformationAboutOrder = New FormattedString(PartsOfFormattedString);
	
EndProcedure

&AtServer
Procedure FillInCouriersAndPickers()
	
	Couriers.Clear();
	
	DeliveryStatuses = New Array;
	DeliveryStatuses.Add(Enums.AssemblyAndDeliveryStatuses.ForAssembly);
	DeliveryStatuses.Add(Enums.AssemblyAndDeliveryStatuses.AssemblyInProgress);
	DeliveryStatuses.Add(Enums.AssemblyAndDeliveryStatuses.Assembled_);
	DeliveryStatuses.Add(Enums.AssemblyAndDeliveryStatuses.ReadyForDelivery);
	DeliveryStatuses.Add(Enums.AssemblyAndDeliveryStatuses.InProcessing);
	DeliveryStatuses.Add(Enums.AssemblyAndDeliveryStatuses.DeliveryInProgress);
	
	BuildStatuses = New Array;
	BuildStatuses.Add(Enums.AssemblyAndDeliveryStatuses.ForAssembly);
	BuildStatuses.Add(Enums.AssemblyAndDeliveryStatuses.AssemblyInProgress);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Assigned_,
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Courier AS Courier
		|INTO OrdersInDelivery
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|WHERE
		|	AssemblyAndDeliveryStatuses.Status IN(&DeliveryStatuses)
		|
		|GROUP BY
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Courier
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Delivered,
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Courier AS Courier
		|INTO OrdersDelivered
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|WHERE
		|	AssemblyAndDeliveryStatuses.DeliveryDate BETWEEN &BegOfDay AND &EndOfDay
		|
		|GROUP BY
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Courier
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(AssemblyAndDeliveryStatuses.DeliveryDate) AS DeliveryDate,
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Courier AS Courier
		|INTO TheLastShipment_3
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|
		|GROUP BY
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Courier
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker AS Picker,
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Assigned_
		|INTO OrdersInAssembly
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|WHERE
		|	AssemblyAndDeliveryStatuses.Status IN(&BuildStatuses)
		|
		|GROUP BY
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Assembled,
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker AS Picker
		|INTO OrdersCollected
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|WHERE
		|	AssemblyAndDeliveryStatuses.AssemblyDate BETWEEN &BegOfDay AND &EndOfDay
		|
		|GROUP BY
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker AS Picker,
		|	MAX(AssemblyAndDeliveryStatuses.AssemblyDate) AS AssemblyDate
		|INTO LatestBuild
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|
		|GROUP BY
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	StoreEmployees.Warehouse AS Warehouse
		|INTO DispatcherWarehouses
		|FROM
		|	InformationRegister.StoreEmployees AS StoreEmployees
		|WHERE
		|	StoreEmployees.Employee = &Employee
		|	AND StoreEmployees.Dispatcher = TRUE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Collectors.Employee AS Picker
		|INTO Collectors
		|FROM
		|	DispatcherWarehouses AS DispatcherWarehouses
		|		LEFT JOIN InformationRegister.StoreEmployees AS Collectors
		|		ON DispatcherWarehouses.Warehouse = Collectors.Warehouse
		|WHERE
		|	Collectors.Picker = TRUE
		|	AND Collectors.Warehouse  = &AvailableWarehouses
		|
		|GROUP BY
		|	Collectors.Employee
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	StoreEmployees.Employee AS Courier
		|INTO Couriers
		|FROM
		|	DispatcherWarehouses AS DispatcherWarehouses
		|		LEFT JOIN InformationRegister.StoreEmployees AS StoreEmployees
		|		ON DispatcherWarehouses.Warehouse = StoreEmployees.Warehouse
		|WHERE
		|	StoreEmployees.Courier = TRUE
		|	AND StoreEmployees.Warehouse = &AvailableWarehouses
		|
		|GROUP BY
		|	StoreEmployees.Employee
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Collectors.Picker AS Picker,
		|	SUM(ISNULL(OrdersInAssembly.Assigned_, 0)) AS Assigned_,
		|	SUM(ISNULL(OrdersCollected.Assembled, 0)) AS Assembled,
		|	LatestBuild.AssemblyDate AS AssemblyDate
		|FROM
		|	Collectors AS Collectors
		|		LEFT JOIN OrdersInAssembly AS OrdersInAssembly
		|		ON Collectors.Picker = OrdersInAssembly.Picker
		|		LEFT JOIN OrdersCollected AS OrdersCollected
		|		ON Collectors.Picker = OrdersCollected.Picker
		|		LEFT JOIN LatestBuild AS LatestBuild
		|		ON Collectors.Picker = LatestBuild.Picker
		|
		|GROUP BY
		|	Collectors.Picker,
		|	LatestBuild.AssemblyDate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Couriers.Courier AS Courier,
		|	SUM(ISNULL(OrdersInDelivery.Assigned_, 0)) AS Assigned_,
		|	ISNULL(OrdersDelivered.Delivered, 0) AS Delivered,
		|	TheLastShipment_3.DeliveryDate AS DeliveryDate
		|FROM
		|	Couriers AS Couriers
		|		LEFT JOIN OrdersInDelivery AS OrdersInDelivery
		|		ON Couriers.Courier = OrdersInDelivery.Courier
		|		LEFT JOIN OrdersDelivered AS OrdersDelivered
		|		ON Couriers.Courier = OrdersDelivered.Courier
		|		LEFT JOIN TheLastShipment_3 AS TheLastShipment_3
		|		ON Couriers.Courier = TheLastShipment_3.Courier
		|
		|GROUP BY
		|	Couriers.Courier,
		|	TheLastShipment_3.DeliveryDate,
		|	ISNULL(OrdersDelivered.Delivered, 0)";
	
	If Not WarehouseSelection.IsEmpty() Then
		Query.SetParameter("AvailableWarehouses", WarehouseSelection);
	Else
		Query.Text = StrReplace(Query.Text, "AND Collectors.Warehouse  = &AvailableWarehouses", "");
		Query.Text = StrReplace(Query.Text, "AND StoreEmployees.Warehouse = &AvailableWarehouses", "");
	EndIf;
	
	Query.SetParameter("Employee", Dispatcher);
	Query.SetParameter("DeliveryStatuses", DeliveryStatuses);
	Query.SetParameter("BuildStatuses", BuildStatuses);
	Query.SetParameter("BegOfDay", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("EndOfDay", EndOfDay(CurrentSessionDate()));
	
	Results = Query.ExecuteBatch();
	
	Collectors.Load(Results[9].Unload());
	Couriers.Load(Results[10].Unload());
	
EndProcedure

&AtServer
Function InstallCourierInOrders(References, Courier)

	ThisIsAppointment = ValueIsFilled(Courier);
	If ThisIsAppointment Then
		StatusesOfOrders = StatusesOfOrders(References);
	EndIf;
	InstructionsForInstallation = New Array;

	For Each ReferenceOrder In References Do
		
		DetailsOfOrder = Common.ObjectAttributesValues(ReferenceOrder, "Warehouse, Courier");
		If DetailsOfOrder.Courier = Courier Then
			Continue;
		EndIf;

		If ThisIsAppointment Then
		
			OrderStatus_ = StatusesOfOrders[ReferenceOrder];
			If OrderStatus_ = Enums.AssemblyAndDeliveryStatuses.RolledBack_ 
				Or OrderStatus_ = Enums.AssemblyAndDeliveryStatuses.Delivered_5 Then
				MessageText = NStr("vi = 'Chưa chỉ định người vận chuyển: %1
										 | Đơn hàng chưa sẵn sàng để giao';
										 |ru = 'Курьер не назначен: %1
										 | Заказ не готов к доставке';
										 |en = 'No courier assigned: %1
										 | The order is not ready for delivery'; fa = 'No courier assigned: %1
										 | The order is not ready for delivery';
										 |it = 'Курьер не назначен: %1
										 | Заказ не готов к доставке';
										 |pl = 'Kurier nie jest przydzielony: %1
										 | Zamówienie nie jest gotowe do dostawy';
										 |tr = 'Kurye atanmadı: %1
										 | Sipariş teslimat için hazır değil'");
				MessageText = StrTemplate(MessageText, String(ReferenceOrder));
				Common.MessageToUser(MessageText);
				Continue;
			EndIf;
			
			AssignmentIsAllowed_ = CourierWorksInWarehouse(DetailsOfOrder.Warehouse, Courier);
			
			If Not AssignmentIsAllowed_ Then
				MessageText = NStr("vi = 'Chưa ấn định người chuyển hàng: %1
										  |%2 không làm việc trong kho %3';
										  |ru = 'Курьер не назначен: %1
										  |%2 не работает на складе %3';
										  |en = 'No courier assigned: %1
										  |%2 is not employed on warehouse %3'; fa = 'No courier assigned: %1
										  |%2 is not employed on warehouse %3';
										  |it = 'Курьер не назначен: %1
										  |%2 не работает на складе %3';
										  |pl = 'Kurier nie jest przydzielony: %1
										  |%2 nie pracuje w magazynie%3';
										  |tr = 'Kurye atanmadı: %1
										  |%2 ambarda çalışmıyor %3'");
				MessageText = StrTemplate(MessageText, String(ReferenceOrder), String(Courier), String(DetailsOfOrder.Warehouse));
				Common.MessageToUser(MessageText);
				Continue;
			EndIf;

		EndIf;
		
		InstructionsForInstallation.Add(ReferenceOrder);

	EndDo;

	If InstructionsForInstallation.Count() = 0 Then
		Return False;
	EndIf;

	ErrorText = "";
	BeginTransaction();
	Try
		Block = New DataLock();

		LockSpace = Metadata.Documents.SalesOrder.FullName();
		For Each ReferenceOrder In InstructionsForInstallation Do
			LockItem = Block.Add(LockSpace);
			LockItem.SetValue("Ref", ReferenceOrder);
			LockItem.Mode = DataLockMode.Exclusive;
		EndDo;

		ErrorText = NStr("vi = 'Không thể thiết lập phong tỏa. Chưa thực hiện cài đặt của người vận chuyển.';
						|ru = 'Не удалось установить блокировку. Установка курьера не выполнена.';
						|en = 'Cannot set the lock. The courier is not set.'; fa = 'Cannot set the lock. The courier is not set.';
						|it = 'Не удалось установить блокировку. Установка курьера не выполнена.';
						|pl = 'Cannot set the lock. The courier is not set.';
						|tr = 'Kilit ayarlanamadı. Kurye kurulumu başarısız oldu.'");
		Block.Lock();

		For Each ReferenceOrder In InstructionsForInstallation Do
			OrderObject__ = ReferenceOrder.GetObject();	//DocumentObject.SalesOrder
			OrderObject__.Courier = Courier;
			OrderObject__.Write(DocumentWriteMode.Posting);
		EndDo;
		CommitTransaction();
		Return True;
	Except
		RollbackTransaction();
		If Not IsBlankString(ErrorText) Then
			Common.MessageToUser(ErrorText);
		EndIf;
		Return False;
	EndTry;

EndFunction

&AtServer
Function InstallCollectorInOrders(References, Picker)

	ThisIsAppointment = ValueIsFilled(Picker);
	If ThisIsAppointment Then
		StatusesOfOrders = StatusesOfOrders(References);
	EndIf;
	InstructionsForInstallation = New Array;

	For Each ReferenceOrder In References Do
		
		DetailsOfOrder = Common.ObjectAttributesValues(ReferenceOrder, "Warehouse, Picker");
		If DetailsOfOrder.Picker = Picker Then
			Continue;
		EndIf;

		If ThisIsAppointment Then
		
			OrderStatus_ = StatusesOfOrders[ReferenceOrder];
			If OrderStatus_ <> Enums.AssemblyAndDeliveryStatuses.ForAssembly Then
				MessageText = NStr("vi = 'Chưa chỉ định bộ đóng gói: %1
					|Lệnh không có trạng thái ""Cần đóng bộ""';
					|ru = 'Сборщик не назначен: %1
					|Распоряжение не в статусе ""К сборке""';
					|en = 'No picker assigned: %1
					|Reference must have ""For kitting"" status'; fa = 'No picker assigned: %1
					|Reference must have ""For kitting"" status';
					|it = 'Сборщик не назначен: %1
					|Распоряжение не в статусе ""К сборке""';
					|pl = 'Zbieracz nie jest przydzielony: %1
					|Zamówienie nie w statusie ""Do kompletacji""';
					|tr = 'Kurye atanmadı: %1
					| Emir ""Montaj yapılacak"" durumunda değil'");
				MessageText = StrTemplate(MessageText, String(ReferenceOrder));
				Common.MessageToUser(MessageText);
				Continue;
			EndIf;
		
			AssignmentIsAllowed_ = AssemblerWorksInWarehouse(DetailsOfOrder.Warehouse, Picker);
			
			If Not AssignmentIsAllowed_ Then
				MessageText = NStr("vi = 'Chưa chỉ định bộ đóng gói: %1
					|%2 không làm việc trong kho %3';
					|ru = 'Сборщик не назначен: %1
					|%2 не работает на складе %3';
					|en = 'No picker assigned: %1
					|%2 is not employed on warehouse %3'; fa = 'No picker assigned: %1
					|%2 is not employed on warehouse %3';
					|it = 'Сборщик не назначен: %1
					|%2 не работает на складе %3';
					|pl = 'Zbieracz nie jest przydzielony: %1
					|%2 nie pracuje w magazynie%3';
					|tr = 'Montajcı atanmadı: %1
					|%2 ambarda çalışmıyor %3'");
				MessageText = StrTemplate(MessageText, String(ReferenceOrder), String(Picker), String(DetailsOfOrder.Warehouse));
				Common.MessageToUser(MessageText);
				Continue;
			EndIf;

		EndIf;

		InstructionsForInstallation.Add(ReferenceOrder);

	EndDo;

	If InstructionsForInstallation.Count() = 0 Then
		Return False;
	EndIf;

	ErrorText = "";
	BeginTransaction();
	Try
		Block = New DataLock();

		LockSpace = Metadata.Documents.SalesOrder.FullName();
		For Each ReferenceOrder In InstructionsForInstallation Do
			LockItem = Block.Add(LockSpace);
			LockItem.SetValue("Ref", ReferenceOrder);
			LockItem.Mode = DataLockMode.Exclusive;
		EndDo;

		ErrorText = NStr("vi = 'Không thể thiết lập phong tỏa. Chưa thực hiện cài đặt của người gom hàng.';
						|ru = 'Не удалось установить блокировку. Установка сборщика не выполнена.';
						|en = 'Cannot set the lock. The picker is not set.'; fa = 'Cannot set the lock. The picker is not set.';
						|it = 'Не удалось установить блокировку. Установка сборщика не выполнена.';
						|pl = 'Cannot set the lock. The picker is not set.';
						|tr = 'Kilit ayarlanamadı. Montajcı kurulumu başarısız oldu.'");
		Block.Lock();

		For Each ReferenceOrder In InstructionsForInstallation Do
			OrderObject__ = ReferenceOrder.GetObject();	//DocumentObject.SalesOrder
			OrderObject__.Picker = Picker;
			OrderObject__.Write(DocumentWriteMode.Posting);
		EndDo;
		CommitTransaction();
		Return True;
	Except
		RollbackTransaction();
		If Not IsBlankString(ErrorText) Then
			Common.MessageToUser(ErrorText);
		EndIf;
		Return False;
	EndTry;

EndFunction

&AtServer
Function CourierWorksInWarehouse(Warehouse, Courier)

	Filter = New Structure("Courier, Warehouse", Courier, Warehouse);
	Result = CourierCache.FindRows(Filter);
	If Result.Count() > 0 Then
		Return Result[0].ItWorks;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	&Employee AS Courier,
	|	&Warehouse AS Warehouse
	|INTO TTSelection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTSelection.Courier AS Courier,
	|	TTSelection.Warehouse AS Warehouse,
	|	ISNULL(StoreEmployees.Courier, FALSE) AS ItWorks
	|FROM
	|	TTSelection AS TTSelection
	|		LEFT JOIN InformationRegister.StoreEmployees AS StoreEmployees
	|		ON TTSelection.Courier = StoreEmployees.Employee
	|			AND TTSelection.Warehouse = StoreEmployees.Warehouse
	|			AND (StoreEmployees.Courier)";
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Employee", Courier);

	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	If Selection.Next() Then
		CacheLine = CourierCache.Add();
		FillPropertyValues(CacheLine, Selection);
		Return Selection.ItWorks;
	Else
		Return False;
	EndIf;

EndFunction

&AtServer
Function AssemblerWorksInWarehouse(Warehouse, Picker)
	
	Filter = New Structure("Picker, Warehouse", Picker, Warehouse);
	Result = CollectorCache.FindRows(Filter);
	If Result.Count() > 0 Then
		Return Result[0].ItWorks;
	EndIf;

	Query = New Query;
	Query.Text = 
	"SELECT
	|	&Employee AS Picker,
	|	&Warehouse AS Warehouse
	|INTO TTSelection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTSelection.Picker AS Picker,
	|	TTSelection.Warehouse AS Warehouse,
	|	ISNULL(StoreEmployees.Picker, FALSE) AS ItWorks
	|FROM
	|	TTSelection AS TTSelection
	|		LEFT JOIN InformationRegister.StoreEmployees AS StoreEmployees
	|		ON TTSelection.Picker = StoreEmployees.Employee
	|			AND TTSelection.Warehouse = StoreEmployees.Warehouse
	|			AND (StoreEmployees.Picker)";
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Employee", Picker);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	If Selection.Next() Then
		CacheLine = CollectorCache.Add();
		FillPropertyValues(CacheLine, Selection);
		Return Selection.ItWorks;
	Else
		Return False;
	EndIf;

EndFunction

&AtServer
Procedure RemoveCourierFromServer()

	InstallCourierInOrders(Items.OrderList.SelectedRows, Catalogs.Persons.EmptyRef());

EndProcedure

&AtServer
Procedure RemoveMailFetcherFromServer()

	IsInstalledSuccessfully = InstallCollectorInOrders(Items.OrderList.SelectedRows, Catalogs.Persons.EmptyRef());

	If IsInstalledSuccessfully Then
		For Each ReferenceOrder In Items.OrderList.SelectedRows Do
			InformationRegisters.AssemblyAndDeliveryStatuses.RecordStatus(ReferenceOrder, Enums.AssemblyAndDeliveryStatuses.ForAssembly);
		EndDo;
	EndIf;

EndProcedure

&AtClient
Procedure UpdateDataOnForm()

	Items.OrderList.Refresh();
	FillInCouriersAndPickers();

EndProcedure

&AtClient
Procedure ToAppointTheCollectorCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then
		Return;
	EndIf;

	ClearMessages();

	References = Items.OrderList.SelectedRows;
	InstallCollectorInOrders(References, ClosingResult);

	UpdateDataOnForm();

EndProcedure

&AtClient
Procedure AssignACourierCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then
		Return;
	EndIf;

	ClearMessages();

	References = Items.OrderList.SelectedRows;
	InstallCourierInOrders(References, ClosingResult);

	UpdateDataOnForm();
	
EndProcedure

&AtServer
Function StatusesOfOrders(References)

	Statuses = New Map;

	Query = New Query;
	Query.Text = 
	"SELECT
	|	SalesOrder.Ref AS ReferenceOrder,
	|	ISNULL(AssemblyAndDeliveryStatuses.Status, VALUE(Enum.AssemblyAndDeliveryStatuses.EmptyRef)) AS Status
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|		LEFT JOIN InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	|		ON SalesOrder.Ref = AssemblyAndDeliveryStatuses.ReferenceOrder
	|WHERE
	|	SalesOrder.Ref IN(&References)";

	Query.SetParameter("References", References);
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Statuses;
	EndIf;

	Selection = Result.Select();
	While Selection.Next() Do
		Statuses.Insert(Selection.ReferenceOrder, Selection.Status);
	EndDo;
	Return Statuses;

EndFunction

#EndRegion
