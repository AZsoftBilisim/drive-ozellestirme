#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = FormHeaderByParameters();
	
	Package = Parameters.Package;
	If Not ValueIsFilled(Package) Then
		Package = Common.ObjectAttributeValue(Parameters.Products, "UnitOfMeasure");
	EndIf;
	Items.ListCount.Title = StrTemplate(NStr("vi = 'Số lượng, %1';
											|ru = 'Количество, %1';
											|en = 'Quantity, %1'; fa = 'Quantity, %1';
											|it = 'Quantità, %1';
											|pl = 'Ilość, %1';
											|tr = 'Miktar, %1'"), Package);
	PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(
		Parameters.Package,
		Parameters.Products);
		
	TextToReserve = String(Enums.SupplyOptions.FromWarehouse);
	ReserveTextAsNeeded = String(Enums.SupplyOptions.ReserveAsReceived);
	
	If Not ValueIsFilled(PackagingFactor) Then
		PackagingFactor = 1;
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"Products",
		Parameters.Products);
		
	CommonClientServer.SetDynamicListParameter(
		List,
		"Characteristic",
		Parameters.Characteristic);
		
	CommonClientServer.SetDynamicListParameter(
		List,
		"Warehouse",
		Parameters.Warehouse);
		
	CommonClientServer.SetDynamicListParameter(
		List,
		"Purpose",
		Parameters.Purpose);
		
	CommonClientServer.SetDynamicListParameter(
		List,
		"ControlledLotReference",
		Parameters.ControlledLotReference);
		
	CommonClientServer.SetDynamicListParameter(
		List,
		"PackagingFactor",
		PackagingFactor);
		
	CommonClientServer.SetDynamicListParameter(
		List,
		"ShippingOrders",
		Parameters.ShippingOrders);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ShowValue( , Items.List.CurrentData.OrderDocument);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function FormHeaderByParameters()
	
	Text = Undefined;
	
	If GetFunctionalOption("UseSeveralWarehouses") Then
		
		If GetFunctionalOption("UseOrderSupplyWithAssignment") Then
			
			If ValueIsFilled(Parameters.Characteristic) Then
				
				If ValueIsFilled(Parameters.Purpose) Then
					Text = NStr("vi = 'Dự phòng theo đơn hàng đặt riêng (Mặt hàng: %1, Đặc tính: %2, Kho bãi: %3)';
								|ru = 'Резервы по обособленным заказам (Номенклатура: %1, Характеристика: %2, Склад: %3)';
								|en = 'Reserves by assigned orders (Item: %1, Variant: %2, Warehouse: %3)'; fa = 'Reserves by assigned orders (Item: %1, Variant: %2, Warehouse: %3)';
								|it = 'Prenotazioni per ordini separati (Articolo: %1, Caratteristica: %2, Magazzino: %3)';
								|pl = 'Rezerwy wg odosobnionych zamówień (Pozycja: %1, Charakterystyka: %2, Magazyn: %3)';
								|tr = 'Ayrıştırılmış siparişlere göre rezervler (Öğe: %1, Özellik: %2, Ambar: %3)'");
				Else
					Text = NStr("vi = 'Dự phòng theo đơn hàng đặt riêng (Mặt hàng: %1, Đặc tính: %2, Kho bãi: %3)';
								|ru = 'Резервы по обособленным заказам (Номенклатура: %1, Характеристика: %2, Склад: %3)';
								|en = 'Reserves by assigned orders (Item: %1, Variant: %2, Warehouse: %3)'; fa = 'Reserves by assigned orders (Item: %1, Variant: %2, Warehouse: %3)';
								|it = 'Prenotazioni per ordini separati (Articolo: %1, Caratteristica: %2, Magazzino: %3)';
								|pl = 'Rezerwy wg odosobnionych zamówień (Pozycja: %1, Charakterystyka: %2, Magazyn: %3)';
								|tr = 'Ayrıştırılmış siparişlere göre rezervler (Öğe: %1, Özellik: %2, Ambar: %3)'");
				EndIf;
				Text = StrTemplate(Text, Parameters.Products, Parameters.Characteristic, Parameters.Warehouse);
				
			Else
				
				If ValueIsFilled(Parameters.Purpose) Then
					Text = NStr("vi = 'Dự phòng theo đơn hàng đặt riêng (Mặt hàng: %1, Kho bãi: %2)';
								|ru = 'Резервы по обособленным заказам (Номенклатура: %1, Склад: %2)';
								|en = 'Reserves by assigned orders (Item: %1, Warehouse: %2)'; fa = 'Reserves by assigned orders (Item: %1, Warehouse: %2)';
								|it = 'Prenotazioni per ordini separati (Articolo: %1, Magazzino: %2)';
								|pl = 'Rezerwy wg odosobnionych zamówień (Pozycja: %1, Magazyn: %2)';
								|tr = 'Ayrıştırılmış siparişler için rezervler (Öğe: %1, Ambar: %2)'");
				Else
					Text = NStr("vi = 'Dự phòng theo đơn hàng đặt riêng (Mặt hàng: %1, Kho bãi: %2)';
								|ru = 'Резервы по необособленным заказам (Номенклатура: %1, Склад: %2)';
								|en = 'Reserves by non-assigned orders (Item: %1, Warehouse: %2)'; fa = 'Reserves by non-assigned orders (Item: %1, Warehouse: %2)';
								|it = 'Prenotazione per ordini non separati (Articolo: %1, Magazzino: %2)';
								|pl = 'Rezerwy wg nieodosobnionych zamówień (Pozycja: %1, Magazyn: %2)';
								|tr = 'Ayrıştırılmayan siparişler için rezervler (Öğe: %1, Ambar: %2)'");
				EndIf;
				Text = StrTemplate(Text, Parameters.Products, Parameters.Warehouse);
				
			EndIf;
			
		Else
			
			If ValueIsFilled(Parameters.Characteristic) Then
				
				Text = NStr("vi = 'Dự phòng theo đơn hàng (Mặt hàng: %1, Đặc tính: %2, Kho bãi: %3)';
							|ru = 'Резервы по заказам (Номенклатура: %1, Характеристика: %2, Склад: %3)';
							|en = 'Reserves by orders (Item: %1, Variant: %2, Warehouse: %3)'; fa = 'Reserves by orders (Item: %1, Variant: %2, Warehouse: %3)';
							|it = 'Prenotazioni per ordini (Articolo: %1, Caratteristica: %2, Magazzino: %3)';
							|pl = 'Rezerwy wg zamówień (Pozycja: %1, Charakterystyka: %2, Magazyn: %3)';
							|tr = 'Sipariş rezervleri (Öğe: %1, Karakteristik: %2, Ambar: %3)'");
				Text = StrTemplate(Text, Parameters.Products, Parameters.Characteristic, Parameters.Warehouse);
				
			Else
				
				Text = NStr("vi = 'Dự phòng theo đơn hàng (Mặt hàng: %1, Kho bãi: %2)';
							|ru = 'Резервы по заказам (Номенклатура: %1, Склад: %2)';
							|en = 'Reserves by orders (Item: %1, Warehouse: %2)'; fa = 'Reserves by orders (Item: %1, Warehouse: %2)';
							|it = 'Prenotazioni per ordini (Articolo: %1, Magazzino: %2)';
							|pl = 'Rezerwy wg zamówień (Pozycja: %1, Magazyn: %2)';
							|tr = 'Sipariş rezervleri (Öğe: %1, Ambar: %2)'");
				Text = StrTemplate(Text, Parameters.Products, Parameters.Warehouse);
				
			EndIf;
			
		EndIf;
		
	Else
		
		If GetFunctionalOption("UseOrderSupplyWithAssignment") Then
			
			If ValueIsFilled(Parameters.Characteristic) Then
				
				If ValueIsFilled(Parameters.Purpose) Then
					Text = NStr("vi = 'Dự phòng theo đơn hàng đặt riêng (Mặt hàng: %1, Đặc tính: %2)';
								|ru = 'Резервы по обособленным заказам (Номенклатура: %1, Характеристика: %2)';
								|en = 'Reserves by assigned orders (Item: %1, Variant: %2)'; fa = 'Reserves by assigned orders (Item: %1, Variant: %2)';
								|it = 'Prenotazioni per ordini separati (Articolo: %1, Caratteristica: %2)';
								|pl = 'Rezerwy wg odosobnionych zamówień (Pozycja: %1, Charakterystyka: %2)';
								|tr = 'Ayrıştırılmış siparişler için rezervler (Öğe: %1, Karakteristik: %2)'");
				Else
					Text = NStr("vi = 'Dự phòng theo đơn hàng đặt riêng (Mặt hàng: %1, Đặc tính: %2)';
								|ru = 'Резервы по обособленным заказам (Номенклатура: %1, Характеристика: %2)';
								|en = 'Reserves by assigned orders (Item: %1, Variant: %2)'; fa = 'Reserves by assigned orders (Item: %1, Variant: %2)';
								|it = 'Prenotazioni per ordini separati (Articolo: %1, Caratteristica: %2)';
								|pl = 'Rezerwy wg odosobnionych zamówień (Pozycja: %1, Charakterystyka: %2)';
								|tr = 'Ayrıştırılmış siparişler için rezervler (Öğe: %1, Karakteristik: %2)'");
				EndIf;
				Text = StrTemplate(Text, Parameters.Products, Parameters.Characteristic);
				
			Else
				
				If ValueIsFilled(Parameters.Purpose) Then
					Text = NStr("vi = 'Dự phòng theo đơn hàng đặt riêng (Mặt hàng: %1)';
								|ru = 'Резервы по обособленным заказам (Номенклатура: %1)';
								|en = 'Reserves by assigned orders (Item: %1)'; fa = 'Reserves by assigned orders (Item: %1)';
								|it = 'Prenotazioni per ordini separati (Articolo: %1)';
								|pl = 'Rezerwy wg odosobnionych zamówień (Pozycja: %1)';
								|tr = 'Ayrıştırılmış siparişler için rezervler (Öğe: %1)'");
				Else
					Text = NStr("vi = 'Dự phòng theo đơn hàng đặt riêng (Mặt hàng: %1)';
								|ru = 'Резервы по необособленным заказам (Номенклатура: %1)';
								|en = 'Reserves by non-assigned orders (Item: %1)'; fa = 'Reserves by non-assigned orders (Item: %1)';
								|it = 'Prenotazione per ordini non separati (Articolo: %1)';
								|pl = 'Rezerwy wg nieodosobnionych zamówień (Pozycja: %1)';
								|tr = 'Ayrıştırılmayan  siparişler için rezervler (Öğe: %1)'");
				EndIf;
				Text = StrTemplate(Text, Parameters.Products);
				
			EndIf;
			
		Else
			
			If ValueIsFilled(Parameters.Characteristic) Then
				
				Text = NStr("vi = 'Dự phòng theo đơn hàng (Mặt hàng: %1, Đặc tính: %2)';
							|ru = 'Резервы по заказам (Номенклатура: %1, Характеристика: %2)';
							|en = 'Reserves by orders (Item: %1, Variant: %2)'; fa = 'Reserves by orders (Item: %1, Variant: %2)';
							|it = 'Prenotazioni per ordini (Articolo: %1, Caratteristica: %2)';
							|pl = 'Rezerwy wg zamówień (Pozycja: %1, Charakterystyka: %2)';
							|tr = 'Sipariş rezervleri (Öğe: %1, Özellik: %2)'");
				Text = StrTemplate(Text, Parameters.Products, Parameters.Characteristic);
				
			Else
				
				Text = NStr("vi = 'Dự phòng theo đơn hàng (Mặt hàng: %1)';
							|ru = 'Резервы по заказам (Номенклатура: %1)';
							|en = 'Reserves by orders (Item: %1)'; fa = 'Reserves by orders (Item: %1)';
							|it = 'Prenotazioni per ordini (Articolo: %1)';
							|pl = 'Rezerwy wg zamówień (Pozycja: %1)';
							|tr = 'Sipariş rezervleri (Öğe: %1)'");
				Text = StrTemplate(Text, Parameters.Products);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Text;
	
EndFunction

#EndRegion
