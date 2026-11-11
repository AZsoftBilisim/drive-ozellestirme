
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	TypeOfDocuments="";
	
	If Parameters.Property("CreatedDocumentKind", TypeOfDocuments) Then
		If TypeOfDocuments = "TransferOrder" Then
			ViewOfTheTypeOfDocumentsBeingCreated = NStr("vi = 'Đơn hàng điều chuyển nội bộ';
														|ru = 'Заказ на перемещение товаров';
														|en = 'Goods transfer order'; fa = 'سفارش انتقال کالا';
														|it = 'Ordine di trasferimento delle merci';
														|pl = 'Zamówienie przemieszczenia towarów';
														|tr = 'Mal transferi emri'");
			Items.PagesMain.CurrentPage = Items.PageTransferOrders;
			Items.PageOrdersForInternalConsumption.Visible = False;
		ElsIf TypeOfDocuments = "InventoryConsumptionOrder" Then
			ViewOfTheTypeOfDocumentsBeingCreated = NStr("vi = 'Đơn hàng tiêu dùng nội bộ';
														|ru = 'Заказ на внутреннее потребление';
														|en = 'Inventory consumption order'; fa = 'سفارش مصرف موجودی';
														|it = 'Ordine per il consumo interno';
														|pl = 'Zamówienie na konsumpcję wewnętrzną';
														|tr = 'İç tüketim siparişi'");
			Items.PagesMain.CurrentPage = Items.PageOrdersForInternalConsumption;
			Items.PageTransferOrders.Visible = False;
		Else
			ExceptionText = NStr("vi = 'Sai tham số mở biểu mẫu';
								|ru = 'Некорректные параметры открытия формы';
								|en = 'Incorrect form opening parameters'; fa = 'Incorrect form opening parameters';
								|it = 'Parametri di apertura del modulo non corretti';
								|pl = 'Nieprawidłowe ustawienia otwierania formularzu';
								|tr = 'Yanlış form açma parametreleri'");
			Cancel = True;
			Raise ExceptionText;
		EndIf;
	Else
		ExceptionText = NStr("vi = 'Sai tham số mở biểu mẫu';
							|ru = 'Некорректные параметры открытия формы';
							|en = 'Incorrect form opening parameters'; fa = 'Incorrect form opening parameters';
							|it = 'Parametri di apertura del modulo non corretti';
							|pl = 'Nieprawidłowe ustawienia otwierania formularzu';
							|tr = 'Yanlış form açma parametreleri'");
		Cancel = True;
		Raise ExceptionText;
	EndIf;
	
	If Parameters.Property("DocumentBasis") Then
		Object.DocumentBasis = Parameters.DocumentBasis;
	EndIf;
	
	//
	If Not Common.ObjectAttributeValue(Object.DocumentBasis, "Posted") Then
		ExceptionText = NStr("vi = 'Chưa kết chuyển chứng từ cơ sở %1. Không thể tạo chứng từ.';
							|ru = 'Документ-основание %1 не проведен. Формирование документов не возможно.';
							|en = 'Base document %1 is not posted. Cannot generate the documents.'; fa = 'Base document %1 is not posted. Cannot generate the documents.';
							|it = 'Documento-causale %1 non è registrato. Impossibile generare i documenti.';
							|pl = 'Dokument podstawa %1 nie został zatwierdzony. Tworzenie dokumentów jest niemożliwe.';
							|tr = 'Temel belge %1 gerçekleştirilmedi. Belgelerin oluşturulması mümkün değil.'");
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionText, Object.DocumentBasis);
		Cancel = True;
		Raise ExceptionText;
	EndIf;
	//
	
	Object.CreatedDocumentKind = TypeOfDocuments;
	FillInListOfWarehouses();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsTransferOrders

&AtClient
Procedure GoodsTransferOrdersBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure GoodsTransferOrdersBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
EndProcedure

&AtClient
Procedure GoodsTransferOrdersSelection(Item, RowSelected, Field, StandardProcessing)
	If Field.Name = "MovementTheMovementOfGoods" Then
		StandardProcessing = False;
		If ValueIsFilled(Item.CurrentData.TransferOrder)
			And TypeOf(Item.CurrentData.TransferOrder) = Type("DocumentRef.TransferOrder") Then
			ShowValue(Undefined, Item.CurrentData.TransferOrder);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInventoryConsumptionOrders

&AtClient
Procedure InventoryConsumptionOrdersBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure InventoryConsumptionOrdersBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
EndProcedure

&AtClient
Procedure InventoryConsumptionOrdersSelection(Item, RowSelected, Field, StandardProcessing)
	If Field.Name = "OrdersDomesticConsumptionOrder" Then
		StandardProcessing = False;
		If ValueIsFilled(Item.CurrentData.InventoryConsumptionOrder)
			And TypeOf(Item.CurrentData.InventoryConsumptionOrder) = Type("DocumentRef.InventoryConsumptionOrder") Then
			ShowValue(Undefined, Item.CurrentData.InventoryConsumptionOrder);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateDocuments(Command)
	CreateDocumentsServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CreateDocumentsServer()
	If Object.ProcessSucceeded Then
		MessageText = NStr("vi = 'Đã tạo tất cả chứng từ có thể';
							|ru = 'Все возможные документы уже созданы';
							|en = 'All possible documents are already created'; fa = 'All possible documents are already created';
							|it = 'Tutti i documenti possibili sono già stati creati';
							|pl = 'Wszystkie możliwe dokumenty zostały już utworzone.';
							|tr = 'Tüm olası belgeler artık oluşturuldu'");
		CommonClientServer.MessageToUser(MessageText);
		Return;
	EndIf;
	
	If Object.CreatedDocumentKind = "TransferOrder" Then
		TSName = "GoodsTransferOrders";
		WarehouseName_ = "SourceWarehouse";
		RecipientSWarehouseName = "DestinationWarehouse";
		NameOfShipmentDate = "ShipmentStart";
		NameOfAcceptanceDate = "ReceiptEnd";
	ElsIf Object.CreatedDocumentKind = "InventoryConsumptionOrder" Then
		TSName = "InventoryConsumptionOrders";
		WarehouseName_ = "Warehouse";
		RecipientSWarehouseName = "";
		NameOfShipmentDate = "DateOfShipment";
		NameOfAcceptanceDate = "";
	Else
		ExceptionText = NStr("vi = 'Sai tham số điền';
							|ru = 'Некорректные параметры заполнения';
							|en = 'Incorrect filling parameters'; fa = 'Incorrect filling parameters';
							|it = 'Parametri di compilazione non corretti';
							|pl = 'Nieprawidłowe ustawienia wypełnienia';
							|tr = 'Yanlış doldurma parametreleri'");
		Raise ExceptionText;
	EndIf;
	WarehouseArray = Object[TSName].Unload().UnloadColumn("Warehouse");
	QueryResult = ResultOfRequestForBalancesForWithdrawalFromAssortment(TSName);
	
	SampleWarehouses = QueryResult.Select(QueryResultIteration.ByGroups);
	While SampleWarehouses.Next() Do
		CurrentDate = CurrentSessionDate();
		NewOrder = Documents[Object.CreatedDocumentKind].CreateDocument(); // DocumentObject.TransferOrder, DocumentObject.InventoryConsumptionOrder
		NewOrder.Date = CurrentDate;
		NewOrder.Fill(Undefined);
		NewOrder[WarehouseName_] = SampleWarehouses.Warehouse;
		If Not IsBlankString(RecipientSWarehouseName) Then
			NewOrder[RecipientSWarehouseName] = SampleWarehouses.DestinationWarehouse;
		EndIf;
		NewOrder.DocumentBasis = Object.DocumentBasis;
		NewOrder.Department = SampleWarehouses.Department;
		SampleProducts_ = SampleWarehouses.Select(QueryResultIteration.ByGroups);
		While SampleProducts_.Next() Do
			NewLineOfDocument = NewOrder.Goods.Add();
			FillPropertyValues(NewLineOfDocument, SampleProducts_);
			NewLineOfDocument[NameOfShipmentDate] = CurrentDate;
			If Not IsBlankString(NameOfAcceptanceDate) Then
				NewLineOfDocument[NameOfAcceptanceDate] = CurrentDate;
			EndIf;
		EndDo;
		ProvisionInDocumentsServer.FillInDefaultSecurityOption(NewOrder.Goods);
		NewOrder.Write(DocumentWriteMode.Write);
		TSStrings = Object[TSName].FindRows(New Structure("Warehouse", SampleWarehouses.Warehouse));
		If TSStrings.Count() = 0 Then
			TSRow = Object[TSName].Add();
		Else
			TSRow = TSStrings[0];
		EndIf;
		TSRow.Warehouse = SampleWarehouses.Warehouse;
		TSRow[Object.CreatedDocumentKind] = NewOrder.Ref;
		If Not IsBlankString(RecipientSWarehouseName) Then
			TSRow[RecipientSWarehouseName] = SampleWarehouses.DestinationWarehouse;
		EndIf;
	EndDo;
	Object.ProcessSucceeded = True;
EndProcedure

&AtServer
Procedure FillInListOfWarehouses()
	
	Texts = New Array();
	QueryText =
		"SELECT ALLOWED
		|	History.Warehouse
		|INTO Warehouses
		|FROM
		|	InformationRegister.HistoryOfStoreFormatChange.SliceLast(&Date, ) AS History
		|WHERE
		|	History.StoreFormat = &StoreFormat
		|	AND History.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore)
		|	AND NOT History.Warehouse.DeletionMark
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ChangingProductRange.Products AS Products
		|INTO TTProducts_1
		|FROM
		|	Document.ProductRangeChange.Goods AS ChangingProductRange
		|WHERE
		|	ChangingProductRange.Ref = &DocumentBasis
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Warehouses.Warehouse AS Warehouse
		|FROM
		|	Warehouses AS Warehouses";
	Texts.Add(QueryText);
	QueryText =
		"SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND Products IN(
		|				SELECT
		|					TTProducts_1.Products
		|				FROM
		|					TTProducts_1)
		|			AND Warehouse IN(
		|				SELECT
		|					Warehouses.Warehouse
		|				FROM
		|					Warehouses)) AS Inventories
		|;
		|
		|//////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	Calculation.Warehouse AS Warehouse,
		|	CAST(Calculation.Warehouse AS Catalog.Warehouses).Description AS NameOfTheWarehouse
		|FROM
		|	CalculationOfBalancesForSettingActions AS Calculation
		|WHERE
		|	Calculation.QuantityInStock > 0
		|ORDER BY
		|	NameOfTheWarehouse";
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	
	Texts.Add(QueryText);
	
	Query = New Query;
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	StoreFormat = Common.ObjectAttributeValue(Object.DocumentBasis, "PlanningObject");
	Query.SetParameter("StoreFormat", StoreFormat);
	Query.SetParameter("DocumentBasis",Object.DocumentBasis);
	Query.SetParameter("Date", CurrentSessionDate());
	
	If Object.CreatedDocumentKind = "TransferOrder" Then
		TabularSectionName = "GoodsTransferOrders";
	Else
		TabularSectionName = "InventoryConsumptionOrders";
	EndIf;
	ResultsArray = Query.ExecuteBatch();
	ResultWarehouses = ResultsArray[2];
	ResultBalance = ResultsArray[ResultsArray.Count() - 1];
	CreationIsAvailable = False;
	If ResultWarehouses.IsEmpty() Then
		MessageText = NStr("vi = 'Không tồn tại cửa hàng bán lẻ nào có khuôn dạng ""%1"". Không cần tạo chứng từ.';
							|ru = 'Не существует ни одного розничного магазина, принадлежащего формату ""%1"". Создание документов не требуется.';
							|en = 'No retail store of format ""%1"" exists. It is not required to create documents.'; fa = 'No retail store of format ""%1"" exists. It is not required to create documents.';
							|it = 'Nessun negozio al dettaglio appartenente al formato ""%1"". Non è necessario creare i documenti.';
							|pl = 'Nie ma ani jednego sklepu detalicznego, należącego do formatu ""%1"". Tworzenie dokumentów nie jest wymagane.';
							|tr = '""%1"" formatına ait perakende mağaza bulunmamaktadır. Belgelerin oluşturulması gerekli değildir.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, StoreFormat);
		CommonClientServer.MessageToUser(MessageText);
	ElsIf ResultBalance.IsEmpty() Then
		MessageText = NStr("vi = 'Theo số dư tự do không tính bất kỳ hàng hóa nào, mà được lấy ra từ danh điểm. Không cần tạo chứng từ.';
							|ru = 'В свободных остатках не числится ни одного товара, выводимого из ассортимента. Создание документов не требуется.';
							|en = 'No goods to be removed from the product range are recorded in available inventory. Document creation is not required.'; fa = 'No goods to be removed from the product range are recorded in available inventory. Document creation is not required.';
							|it = 'Nessuna merce ritirata dall''assortimento è presente nei saldi liberi. Non è necessario creare i documenti.';
							|pl = 'W wolnych pozostałościach nie figuruje ani jednego towaru, usuwanego z asortymentu. Tworzenie dokumentów nie jest wymagane.';
							|tr = 'Serbest stokta ürün gamından çekilecek ürün yoktur. Hiçbir belge oluşturulmasına gerek yoktur.'");
		CommonClientServer.MessageToUser(MessageText);
	Else
		TabularSection = Object[TabularSectionName]; // TabularSection
		Selection = ResultBalance.Select();
		While Selection.Next() Do
			NewRow = TabularSection.Add();
			FillPropertyValues(NewRow, Selection);
			CreationIsAvailable = True;
		EndDo;
	EndIf;
	Items.FormCreateDocuments.Enabled = CreationIsAvailable;
EndProcedure

&AtServer
Function ResultOfRequestForBalancesForWithdrawalFromAssortment(TSName)
	
	Query=New Query();
	Texts = New Array();
	QueryText =
		"SELECT
		|	Warehouses.Warehouse AS Warehouse,
		|	Warehouses.DestinationWarehouse AS DestinationWarehouse
		|INTO Warehouses
		|FROM
		|	&Warehouses AS Warehouses
		|;
		|
		|SELECT ALLOWED
		|	ChangingProductRange.Products AS Products
		|INTO TTProducts_1
		|FROM
		|	Document.ProductRangeChange.Goods AS ChangingProductRange
		|WHERE
		|	ChangingProductRange.Ref = &DocumentBasis";
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND Products IN(
		|				SELECT
		|					TTProducts_1.Products
		|				FROM
		|					TTProducts_1)
		|			AND Warehouse IN(
		|				SELECT
		|					Warehouses.Warehouse
		|				FROM
		|					Warehouses)) AS Inventories
		|;
		|
		|//////////////////////////////////////////////////
		|SELECT
		|	Calculation.Warehouse AS Warehouse,
		|	Calculation.Products AS Products,
		|	Calculation.Characteristic AS Characteristic,
		|	Calculation.QuantityInStock AS Count
		|INTO BalanceTable
		|FROM
		|	CalculationOfBalancesForSettingActions AS Calculation
		|INDEX BY
		|	Warehouse";
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	Texts.Add(QueryText);

	QueryText =
		"SELECT ALLOWED
		|	Balance.Warehouse AS Warehouse,
		|	Balance.Warehouse.Department AS Department,
		|	Warehouses.DestinationWarehouse AS DestinationWarehouse,
		|	Balance.Products AS Products,
		|	Balance.Characteristic AS Characteristic,
		|	SUM(Balance.Count) AS Count,
		|	SUM(Balance.Count) AS NumberOfPackages
		|FROM
		|	BalanceTable AS Balance
		|		INNER JOIN Warehouses AS Warehouses ON Warehouses.Warehouse = Balance.Warehouse
		|
		|GROUP BY
		|	Balance.Warehouse, Balance.Products, Balance.Characteristic, Warehouses.DestinationWarehouse
		|
		|ORDER BY
		|	Balance.Warehouse.Description, Balance.Products.Description
		|TOTALS
		|	MAX(Warehouses.DestinationWarehouse) AS DestinationWarehouse
		|BY Warehouse";
	Texts.Add(QueryText);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Query.SetParameter("DocumentBasis",Object.DocumentBasis);
	ObjectTable = Object[TSName].Unload(New Array()); //ValueTable
	EmptyRef = Documents[Object.CreatedDocumentKind].EmptyRef();
	For Each String In Object[TSName] Do
		
		If String[Object.CreatedDocumentKind] = EmptyRef
				Or TypeOf(String[Object.CreatedDocumentKind])
					<> Type("DocumentRef." + Object.CreatedDocumentKind) Then
			FillPropertyValues(ObjectTable.Add(), String);
		EndIf;
		
	EndDo;
	
	Query.SetParameter("Warehouses", ObjectTable);
	Query.SetParameter("Date", CurrentSessionDate());
	QueryResult = Query.Execute();
	Return QueryResult;
	
EndFunction

#EndRegion
