// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Warehouse = Parameters.Warehouse;
	
	FillList();
	
	Items.ListWarehouse.Visible = Not ValueIsFilled(Warehouse)
		Or Common.ObjectAttributeValue(Warehouse, "IsFolder");
	
	TitleTemplate1 = NStr("vi = 'Trọng lượng, %1';
							|ru = 'Вес, %1';
							|en = 'Weight, %1'; fa = 'Weight, %1';
							|it = 'Вес, %1';
							|pl = 'Waga, %1';
							|tr = 'Ağırlık, %1'");
	Items.ListWeight.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TitleTemplate1,
		String(Constants.UnitOfMeasureForWeight.Get()));
		
	TitleTemplate1 = NStr("vi = 'khối lượng %1%1';
							|ru = 'Объем, %1';
							|en = 'Volume, %1'; fa = 'Volume, %1';
							|it = 'Объем, %1';
							|pl = 'Objętość, %1';
							|tr = 'Hacim, %1'");
	Items.ListVolumeM3.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TitleTemplate1,
		String(Constants.UnitOfMeasureForVolume.Get()));
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(,Item.CurrentData.ReferenceOrder);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ReturnToDelivery(Command)
	
	If Items.List.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	ReferenceAddress = ReturnToDeliveryOnServer();
	Notify("CancelingDeliveryException", New Structure("ReferenceAddress", ReferenceAddress));
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	FillList();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillList()
	
	QueryText = 
	"SELECT
	|	GoodsToDeliver.ReferenceOrder.Number AS Number,
	|	GoodsToDeliver.ReferenceOrder.Date AS Date,
	|	GoodsToDeliver.ReferenceOrder AS ReferenceOrder,
	|	VALUETYPE(GoodsToDeliver.ReferenceOrder) AS TypeOfOrder_,
	|	GoodsToDeliver.Warehouse AS Warehouse,
	|	SUM(GoodsToDeliver.Count) AS Count,
	|	GoodsToDeliver.RecipientSender AS RecipientSender,
	|	SUM(GoodsToDeliver.Weight) AS Weight,
	|	SUM(GoodsToDeliver.VolumeM3) AS VolumeM3
	|FROM
	|	InformationRegister.GoodsToDeliver AS GoodsToDeliver
	|WHERE
	|	GoodsToDeliver.TransportationJob = VALUE(Document.TransportationJob.EmptyRef)
	|	AND (GoodsToDeliver.Warehouse IN HIERARCHY(&Warehouse)
	|		OR GoodsToDeliver.Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|
	|GROUP BY
	|	GoodsToDeliver.ReferenceOrder,
	|	GoodsToDeliver.Warehouse,
	|	GoodsToDeliver.RecipientSender,
	|	GoodsToDeliver.ReferenceOrder.Number,
	|	GoodsToDeliver.ReferenceOrder.Date
	|
	|ORDER BY
	|	GoodsToDeliver.ReferenceOrder.Date";
	
	Query = New Query(QueryText);
	Query.SetParameter("Warehouse", Warehouse);
	List.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Function ReturnToDeliveryOnServer()
	
	ModesOfFormationOfSpendingOrdersAutomatically = Constants.GoodsIssueNoteGenerationMode.Get() = Enums.GoodsIssueNoteGenerationModes.Automatically;
	ShipmentReferenceOrderType = Metadata.DefinedTypes.ShipmentReferenceOrder.Type;
	
	References = New ValueTable;
	References.Columns.Add("ReferenceOrder", Metadata.DefinedTypes.DeliveryReferenceOrder.Type);
	References.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	
	For Each LineID In Items.List.SelectedRows Do // Number
		CurrentRow = List.FindByID(LineID);
		FillPropertyValues(References.Add(), CurrentRow);
		RecordSet = InformationRegisters.GoodsToDeliver.CreateRecordSet();
		RecordSet.Filter.TransportationJob.Set(Documents.TransportationJob.EmptyRef());
		RecordSet.Filter.ReferenceOrder.Set(CurrentRow.ReferenceOrder);
		RecordSet.Filter.Warehouse.Set(CurrentRow.Warehouse);
		
		BeginTransaction();
		
		Try
			RecordSet.Write();
			
			If ModesOfFormationOfSpendingOrdersAutomatically
				And ShipmentReferenceOrderType.ContainsType(TypeOf(CurrentRow.ReferenceOrder)) Then
				If WarehousesServer.YouNeedToReissueSpendingOrders(CurrentRow.Warehouse, CurrentRow.RecipientSender) Then
					WarehousesServer.AddToQueueForFormingSpendingOrders(CurrentRow.Warehouse, CurrentRow.RecipientSender);
				EndIf;
			EndIf;
			
			List.Delete(CurrentRow);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			MessageText = NStr("vi = 'Không thể trả lại %ReferenceOrder% cho danh sách giao hàng.';
								|ru = 'Не удалось вернуть %ReferenceOrder% в список доставки.';
								|en = 'Cannot return %ReferenceOrder% to the delivery list.'; fa = 'Cannot return %ReferenceOrder% to the delivery list.';
								|it = 'Impossibile restituire %ReferenceOrder% alla lista di consegna.';
								|pl = 'Nie udało się wrócić %ReferenceOrder% do listy dostawy.';
								|tr = '%ReferenceOrder% teslimat listesine döndürülemedi.'");
			MessageText = StrReplace(MessageText, "%ReferenceOrder%", String(CurrentRow.ReferenceOrder));
			Common.MessageToUser(MessageText);
			
			DefaultLanguageCode = Common.DefaultLanguageCode(); // To record an event in the registration Log.
			WriteLogEvent(NStr("vi = 'Không thể trả lại đơn hàng vào danh sách giao hàng.';
								|ru = 'Не удалось вернуть распоряжение в список доставки.';
								|en = 'Cannot return the reference to the delivery list.'; fa = 'Cannot return the reference to the delivery list.';
								|it = 'Impossibile restituire la disposizione alla lista di consegna.';
								|pl = 'Nie udało się zwrócić zamówienie do listy dostawy.';
								|tr = 'Sipariş teslimat listesine döndürülemedi.'", DefaultLanguageCode),
				EventLogLevel.Error, , ,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		EndTry;
		
	EndDo;
	
	Return PutToTempStorage(References);
	
EndFunction

&AtServer
Procedure WarehouseOnChangeServer()
	
	Items.ListWarehouse.Visible = Not ValueIsFilled(Warehouse)
		Or Common.ObjectAttributeValue(Warehouse, "IsFolder");
	FillList();
	
EndProcedure

#EndRegion