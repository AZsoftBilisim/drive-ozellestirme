
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	FontBold = Items.OrderPositionLabel.Font;
	UnitOfMeasure = String(Parameters.UnitOfMeasure);
	Products = Parameters.Products;
	Characteristic = Parameters.Characteristic;
	Purpose = Parameters.Purpose;
	Warehouse = Parameters.Warehouse;
	ShipmentOrder = Parameters.ShipmentOrder;
	
	UpdateAtServer();

	Items.ShipmentOrder.Title = StrTemplate(NStr("vi = 'Đơn hàng: %1';
												|ru = 'Заказ: %1';
												|en = 'Order: %1'; fa = 'Order: %1';
												|it = 'Заказ: %1';
												|pl = 'Order: %1';
												|tr = 'Sipariş: %1'"), Parameters.ShipmentOrder);
	
	Comma = NStr("vi = ',';
				|ru = ',';
				|en = ','; fa = ',';
				|it = ',';
				|pl = ',';
				|tr = ','") + Chars.NBSp;
	If ValueIsFilled(Parameters.Characteristic) Then
		TextItemAndWarehouse = String(Parameters.Products) + Comma + String(Parameters.Characteristic) + Comma + String(Parameters.Warehouse);
	Else
		TextItemAndWarehouse = String(Parameters.Products) + Comma + String(Parameters.Warehouse);
	EndIf;
	
	Items.OrderPositionLabel.Title = StrTemplate(NStr("vi = 'Vị trí đơn hàng: %1';
														|ru = 'Позиция заказа: %1';
														|en = 'Order item: %1'; fa = 'Order item: %1';
														|it = 'Позиция заказа: %1';
														|pl = 'Order item: %1';
														|tr = 'Sipariş kalemi: %1'"), TextItemAndWarehouse);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTheOrdersTable

&AtClient
Procedure TheOrdersTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	TableRow = TheOrdersTable.FindByID(RowSelected);
	If Field = Items.TheOrdersTableOrderDocument Then
		
		ShowValue(, TableRow.OrderDocument);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TheOrdersTableMarkOnChange(Item)
	
	CurrentData = Items.TheOrdersTable.CurrentData;
	CurrentData.ToReserveBasedOnFlag = ?(CurrentData.Mark, CurrentData.ToReserve, 0);
	ReservesOfOtherOrders = TheOrdersTable.Total("ToReserveBasedOnFlag");
	
EndProcedure

&AtClient
Procedure TheOrdersTableToReserveOnChange(Item)
	
	CurrentData = Items.TheOrdersTable.CurrentData;
	CurrentData.Mark = CurrentData.Count > 0;
	CurrentData.ToReserveBasedOnFlag = ?(CurrentData.Mark, CurrentData.ToReserve, 0);
	ReservesOfOtherOrders = TheOrdersTable.Total("ToReserveBasedOnFlag");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	UpdateAtServer();
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	AddressInStorage = PutInStorage(FormOwner.UUID);
	If AddressInStorage = Undefined Then
		Return;
	EndIf;
	Close(AddressInStorage);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function TableOfOtherOrders()
	
	Query = New Query();
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("ShipmentOrder", ShipmentOrder);
	Query.Text =
		"SELECT ALLOWED
		|	MAX(RegistryData.Priority) AS Priority,
		|	Table.ShipmentOrder AS OrderDocument,
		|	Table.RequestShipmentOn AS RequestShipmentOn,
		|	CASE
		|		WHEN Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse)
		|			THEN VALUE(Enum.SupplyOptions.FromWarehouse)
		|		ELSE VALUE(Enum.SupplyOptions.ReserveAsReceived)
		|	END AS Action,
		|	SUM(Table.Count) AS Count,
		|	MAX(Table.Products.UnitOfMeasure) AS UnitOfMeasure
		|INTO Orders
		|FROM
		|	InformationRegister.InventoryAllocation AS Table
		|		
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegistryData
		|		ON RegistryData.Ref = Table.ShipmentOrder
		|		AND NOT RegistryData.AdditionalRecord
		|WHERE
		|	Table.Products = &Products
		|		AND Table.Characteristic = &Characteristic
		|		AND Table.Warehouse = &Warehouse
		|		AND Table.Purpose = &Purpose
		|		AND Table.ShipmentOrder <> &ShipmentOrder
		|		AND Table.Count > 0
		|		AND Table.InventoryState = VALUE(Enum.InventoryStates.InStock)
		|		AND Table.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse),
		|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived))
		|GROUP BY
		|	Table.ShipmentOrder,
		|	Table.RequestShipmentOn,
		|	CASE
		|		WHEN Table.DemandCharacteristic = VALUE(Enum.DemandCharacteristics.ReserveAtWarehouse)
		|			THEN VALUE(Enum.SupplyOptions.FromWarehouse)
		|		ELSE VALUE(Enum.SupplyOptions.ReserveAsReceived)
		|	END
		|INDEX BY
		|	OrderDocument
		|;
		|
		|/////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Table.Priority AS Priority,
		|	Table.OrderDocument.Ref AS OrderDocument,
		|	Table.RequestShipmentOn AS RequestShipmentOn,
		|	Table.Action AS Action,
		|	Table.Count AS Count,
		|	Table.UnitOfMeasure AS UnitOfMeasure,
		|	VALUETYPE(Table.OrderDocument) = TYPE(Document.CustomerInvoice)
		
		
		|		OR VALUETYPE(Table.OrderDocument) = TYPE(Document.DiscrepancyReportFollowingTransfer)
		|		OR VALUETYPE(Table.OrderDocument) = TYPE(Document.DiscrepancyReportFollowingShipment)
		|		OR ISNULL(CAST(Table.OrderDocument AS Document.SalesOrder).ThisIsOrderAsInvoice, FALSE)
		|		OR ISNULL(CAST(Table.OrderDocument AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice, FALSE)
		|		OR ISNULL(CAST(Table.OrderDocument AS Document.ByAssemblyDisassemblyOrder).BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents), FALSE)
		|		OR VALUETYPE(Table.OrderDocument) IN(
		|				TYPE(Document.SalesOrder),
		|				TYPE(Document.RequestForReturnOfGoodsFromCustomer))
		|			AND LineByLineShipment.Value IS NULL AS ReadOnly
		|FROM
		|	Orders AS Table
		|		LEFT JOIN Constant.UseShipmentByRowsInSalesOrder AS LineByLineShipment
		|		ON LineByLineShipment.Value
		|
		|ORDER BY
		|	Priority, RequestShipmentOn, OrderDocument, Action";
		
	Table = Query.Execute().Unload();
	Return Table;
	
EndFunction

&AtServer
Procedure UpdateAtServer()
	
	Indicators = DataProcessors.OrderSupplyForecast.NumericalReservationParameters(
		Products,
		Characteristic,
		Purpose,
		Warehouse,
		ShipmentOrder);
		
	FillPropertyValues(ThisObject, Indicators);
	
	Rows = New Array();
	If ValueIsFilled(Purpose) Then
		Rows.Add(NStr("vi = 'Tổng số đã đặt (đặt riêng):';
						|ru = 'Всего заказано (обособленно):';
						|en = 'Total ordered (assigned):'; fa = 'Total ordered (assigned):';
						|it = 'Всего заказано (обособленно):';
						|pl = 'Total ordered (assigned):';
						|tr = 'Toplam sipariş edilen (ayrı):'"));
	Else
		Rows.Add(NStr("vi = 'Tổng số đặt hàng:';
						|ru = 'Всего заказано:';
						|en = 'Total ordered:'; fa = 'Total ordered:';
						|it = 'Всего заказано:';
						|pl = 'Total ordered:';
						|tr = 'Toplam sipariş edilen:'"));
	EndIf;
	Rows.Add(Chars.NBSp);
	Text = New FormattedString(Format(NeedForOrder, "NFD=3; NZ=0,000;"), FontBold);
	Rows.Add(Text);
	Rows.Add(Chars.NBSp);
	Rows.Add(UnitOfMeasure);
	Rows.Add(NStr("vi = '; trong số chúng ""Dự phòng tại kho"":';
					|ru = '; из них ""Резервировать на складе"":';
					|en = '; out of them ""Reserve at warehouse"":'; fa = '; out of them ""Reserve at warehouse"":';
					|it = '; из них ""Резервировать на складе"":';
					|pl = '; out of them ""Reserve at warehouse"":';
					|tr = '; bunlardan ""Ambarda rezerve et"":'"));
	Rows.Add(Chars.NBSp);
	Text = New FormattedString(Format(ReserveUnderOrder, "NFD=3; NZ=0,000;"), FontBold);
	Rows.Add(Text);
	Rows.Add(Chars.NBSp);
	Rows.Add(UnitOfMeasure);
	Items.TotalOrderedInscription.Title = New FormattedString(Rows);
	
	TheOrdersTable.Load(TableOfOtherOrders());
	
EndProcedure

&AtServer
Function PutInStorage(OwnerID)
	
	Marked = New Structure("Mark", True);
	Table = TheOrdersTable.Unload(Marked, "OrderDocument, RequestShipmentOn,Action,ToReserve");
	Table.Columns.Add("ToWithdrawReserveFromWarehouse", Table.Columns.ToReserve.ValueType);
	TotalRows = Table.Count();
	For Counter = 1 To TotalRows Do
		TableRow = Table[TotalRows - Counter];
		If TableRow.ToReserve = 0 Then
			Table.Delete(TotalRows - Counter);
		Else
			If TableRow.Action = Enums.SupplyOptions.FromWarehouse Then
				TableRow.ToWithdrawReserveFromWarehouse = TableRow.ToReserve;
				TableRow.ToReserve = 0;
			EndIf;
		EndIf;
	EndDo;
	
	Cancel = False;
	MessageTextWithParameters = NStr("vi = 'Số lượng cần dự phòng %1%2 trong dòng vượt quá số lượng dự phòng sẵn có trong đơn hàng %3 %2';
									|ru = 'Количество к резервированию %1 %2 в строке превышает количество резервов имеющихся в заказе %3 %2';
									|en = 'The quantity to reserve %1 %2 in the line exceeds the number of reserves in the order %3 %2'; fa = 'The quantity to reserve %1 %2 in the line exceeds the number of reserves in the order %3 %2';
									|it = 'Количество к резервированию %1 %2 в строке превышает количество резервов имеющихся в заказе %3 %2';
									|pl = 'The quantity to reserve %1 %2 in the line exceeds the number of reserves in the order %3 %2';
									|tr = 'Satırdaki %1 %2 rezervinin miktarı, %3 %2 siparişinde bulunan rezervlerin miktarını aşmaktadır'");
	For IndexOf = 0 To Table.Count() - 1 Do
		
		String = TheOrdersTable[IndexOf];
		If String.Count < String.ToReserve Then
			
			ErrorText = StrTemplate(
				MessageTextWithParameters,
				String.ToReserve,
				UnitOfMeasure,
				String.Count);
				
			DataPath = CommonClientServer.PathToTabularSection("TheOrdersTable", IndexOf + 1, "ToReserve");
			Common.MessageToUser(ErrorText, Undefined, "TheOrdersTableToReserve", DataPath, Cancel);
			
		EndIf;
		
	EndDo;
	
	If ReservesOfOtherOrders > 0 And NeedForOrder - ReserveUnderOrder - Available < ReservesOfOtherOrders Then
		MessageTextWithParameters = NStr("vi = 'Số lượng cần dự phòng từ đơn hàng khác %1 %2 vượt quá số lượng được phép tối đa %3 %2';
										|ru = 'Количество к резервированию из других заказов %1 %2 превышает максимально допустимое %3 %2';
										|en = 'The quantity to reserve from other orders %1 %2 exceeds the maximum allowed quantity %3 %2'; fa = 'The quantity to reserve from other orders %1 %2 exceeds the maximum allowed quantity %3 %2';
										|it = 'Количество к резервированию из других заказов %1 %2 превышает максимально допустимое %3 %2';
										|pl = 'The quantity to reserve from other orders %1 %2 exceeds the maximum allowed quantity %3 %2';
										|tr = 'Diğer %1 %2 siparişlerinden rezerve edilecek miktar, izin verilen maksimum %3 %2 miktarını aşmaktadır'");
			ErrorText = StrTemplate(
				MessageTextWithParameters,
				ReservesOfOtherOrders,
				UnitOfMeasure,
				Max(0, NeedForOrder - ReserveUnderOrder - Available));
		Common.MessageToUser(ErrorText, Undefined, Undefined, Undefined, Cancel);
	EndIf;
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	Table.Columns.ToReserve.Name = "ToWithdrawReserveAsReceived";
	Result = New Structure();
	Result.Insert("ShipmentOrder", ShipmentOrder);
	Result.Insert("Products", Products);
	Result.Insert("Characteristic", Characteristic);
	Result.Insert("Warehouse", Warehouse);
	Result.Insert("Purpose", Purpose);
	Result.Insert("ToReserveEverything",
		Available + Table.Total("ToWithdrawReserveFromWarehouse") + Table.Total("ToWithdrawReserveAsReceived"));
	Result.Insert("AddressInStorage", PutToTempStorage(Table, OwnerID));
	Return Result;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheOrdersTable.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheOrdersTable.ReadOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableData);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

#EndRegion