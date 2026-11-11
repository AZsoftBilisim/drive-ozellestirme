
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("ReferenceArray") Then
		References = Parameters.ReferenceArray;
	Else
		References = New Array;
	EndIf;
	
	ReferenceArray.LoadValues(References);
	IssueSpendingOrdersOnServer(Cancel);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CreatedGoodsIssueNotesSelection(Item, RowSelected, Field, StandardProcessing)
	ShowValue(Undefined, Item.CurrentData.ExpenseOrder);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

&AtClient
Procedure Change(Command)
	If Items.CreatedGoodsIssueNotes.CurrentData <> Undefined Then
		ShowValue(Undefined, Items.CreatedGoodsIssueNotes.CurrentData.ExpenseOrder);
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure IssueSpendingOrdersOnServer(Cancel)
	
	ParametersForReissuingSpendingOrders = WarehousesServer.ParametersForReissuingSpendingOrders();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	DocumentGoods.InventoryConsumptionOrder AS DocumentShipments,
	|	DocumentGoods.Ref.Warehouse AS Warehouse
	|INTO ShippingDocuments
	|FROM
	|	Document.InventoryConsumption.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.ConsumptionByOrders
	|	AND DocumentGoods.Ref.Posted
	|	AND NOT DocumentGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.InventoryConsumption AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.InventoryConsumptionOrder AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.TransferOrder,
	|	DocumentGoods.Ref.SourceWarehouse
	|FROM
	|	Document.InventoryTransfer.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.TransferAgainstOrders
	|	AND DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.SourceWarehouse
	|FROM
	|	Document.InventoryTransfer AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.SourceWarehouse
	|FROM
	|	Document.TransferOrder AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.SalesOrder,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.CustomerInvoice.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.OrderSales
	|	AND DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.CustomerInvoice.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.SalesOrder,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.Posted
	|	AND DocumentGoods.Ref.ShipmentByOrders
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.SalesOrder.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Document.ByAssemblyDisassemblyOrder,
	|	Document.Warehouse
	|FROM
	|	Document.AssemblyFromComponents AS Document
	|WHERE
	|	Document.Ref IN(&ReferenceArray)
	|	AND Document.ByAssemblyDisassemblyOrder <> VALUE(Document.ByAssemblyDisassemblyOrder.EmptyRef)
	|	AND Document.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Document.Ref,
	|	Document.Warehouse
	|FROM
	|	Document.AssemblyFromComponents AS Document
	|WHERE
	|	Document.Ref IN(&ReferenceArray)
	|	AND Document.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.ReturnOfGoodsToVendor AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Document.Ref,
	|	Document.Warehouse
	|FROM
	|	Document.ByAssemblyDisassemblyOrder AS Document
	|WHERE
	|	Document.Ref IN(&ReferenceArray)
	|	AND Document.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.ReferenceOrder,
	|	DocumentGoods.Ref.Sender
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.ByReferences
	|	AND DocumentGoods.Ref.Posted
	|	AND DocumentGoods.Ref.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|		VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Sender
	|FROM
	|	Document.MovementOfProductsAndMaterials AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Posted
	|	AND DocumentGoods.Ref.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.MaterialTransferToProduction),
	|		VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.GoodsShipmentFromStorage.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.SalesOrder,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.GoodsShipmentFromStorage.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.Posted
	|	AND DocumentGoods.Ref.ByOrder
	|
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.OrderOfMaterialsForProduction AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.SalesOrder,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.TransferByOrders
	|	AND DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.TransferOfGoodsToBailee AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.BackflushProduction.MaterialsAndWorks AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage
	|	
	|	INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS DocumentGoods
	|	ON ProductionStage.Ref = DocumentGoods.Ref
	|	
	|WHERE
	|	ProductionStage.SubcontractOrder IN(&ReferenceArray)
	|	AND ProductionStage.Posted
	|	AND NOT DocumentGoods.Canceled
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.Posted
	|	AND NOT DocumentGoods.Canceled
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.Posted
	|	AND NOT DocumentGoods.Canceled
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse
	|FROM
	|	Document.RMOrder.MaterialsAndWorks AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&ReferenceArray)
	|	AND DocumentGoods.Ref.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TransportationTask.Ref AS TransportationJob,
	|	TransportationTask.ReferenceOrder AS DocumentShipments,
	|	TransportationTask.Warehouse AS Warehouse
	|INTO ShipmentDocumentsOfTransportationOrder
	|FROM
	|	Document.TransportationJob.References AS TransportationTask
	|WHERE
	|	TransportationTask.Ref IN(&ReferenceArray)
	|	AND &UsedDelivery20
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TripOrders.Ref,
	|	TripOrders.ReferenceOrder,
	|	TripOrders.Ref.DepartureWarehouse
	|FROM
	|	Document.Trip.Content AS TripOrders
	|WHERE
	|	TripOrders.Ref IN(&ReferenceArray)
	|	AND &UsedDelivery25
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	VALUE(Document.TransportationJob.EmptyRef) AS TransportationJob,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	GoodsForIssue.DocumentShipments AS DocumentShipments,
	|	GoodsForIssue.Recipient AS Recipient,
	|	ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)) AS Date
	|INTO DataForReissuingOrders
	|FROM
	|	AccumulationRegister.GoodsForIssue AS GoodsForIssue
	|		INNER JOIN ShippingDocuments AS ShippingDocuments
	|		ON GoodsForIssue.DocumentShipments = ShippingDocuments.DocumentShipments
	|			AND GoodsForIssue.Warehouse = ShippingDocuments.Warehouse
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|			ON GoodsForIssue.DocumentShipments = DetailsOfOrder.Ref
	|				AND NOT DetailsOfOrder.AdditionalRecord
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ShipmentDocumentsOfTransportationOrder.TransportationJob,
	|	GoodsForIssue.Warehouse,
	|	GoodsForIssue.DocumentShipments,
	|	GoodsForIssue.Recipient,
	|		CASE
	|		WHEN ShipmentDocumentsOfTransportationOrder.TransportationJob REFS Document.TransportationJob
	|			THEN ShipmentDocumentsOfTransportationOrder.TransportationJob.PlanTripStartTime
	|		ELSE ShipmentDocumentsOfTransportationOrder.TransportationJob.DateOfDeparture
	|	END
	|FROM
	|	AccumulationRegister.GoodsForIssue AS GoodsForIssue
	|		INNER JOIN ShipmentDocumentsOfTransportationOrder AS ShipmentDocumentsOfTransportationOrder
	|		ON GoodsForIssue.DocumentShipments = ShipmentDocumentsOfTransportationOrder.DocumentShipments
	|			AND GoodsForIssue.Warehouse = ShipmentDocumentsOfTransportationOrder.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataForReissuingOrders.TransportationJob,
	|	DataForReissuingOrders.Warehouse,
	|	DataForReissuingOrders.DocumentShipments,
	|	DataForReissuingOrders.Recipient
	|FROM
	|	DataForReissuingOrders AS DataForReissuingOrders
	|WHERE
	|	DataForReissuingOrders.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|	AND DataForReissuingOrders.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= DataForReissuingOrders.Date
	|
	|ORDER BY
	|	TransportationJob,
	|	Warehouse,
	|	Recipient,
	|	DocumentShipments";
	
	Query.SetParameter("ReferenceArray", ReferenceArray.UnloadValues());
	Query.SetParameter("UsedDelivery20", GoodsDeliveryClientServer.UsedDelivery20());
	Query.SetParameter("UsedDelivery25", GoodsDeliveryClientServer.UsedDelivery25());
	
	SetPrivilegedMode(True);
	RequestPackage = Query.ExecuteBatch();
	Selection = RequestPackage[3].Select();
	SetPrivilegedMode(False);
	
	CreateNotes = False;
	
	While Selection.NextByFieldValue("TransportationJob") Do
		
		ParametersForReissuingSpendingOrders.TransportationJob = Selection.TransportationJob;
		
		While Selection.NextByFieldValue("Warehouse") Do
			
			CreateNotes = True;
			
			ParametersForReissuingSpendingOrders.Warehouse = Selection.Warehouse;
			
			While Selection.NextByFieldValue("Recipient") Do
				
				ParametersForReissuingSpendingOrders.Recipient = Selection.Recipient;
				
				References = New Array;
				While Selection.Next() Do
					References.Add(Selection.DocumentShipments);
				EndDo;
				
				ParametersForReissuingSpendingOrders.ShipmentReferences = References;
				
				JobStructure_ = WarehousesServer.ReissueSpendingOrders(ParametersForReissuingSpendingOrders);
				For Each ExecutedOrdersLine In JobStructure_.ExecutedOrders Do
					NewRow = CreatedGoodsIssueNotes.Add();
					FillPropertyValues(NewRow, ExecutedOrdersLine);
					NewRow.Recipient = Selection.Recipient;
				EndDo;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	If Not CreateNotes Then
		
		Cancel = True;
		
		MessageText = NStr("vi = 'Theo các đơn đặt hàng đã chọn, lô hàng không bắt buộc.';
							|ru = 'По выбранным распоряжениям не требуется отгрузка товаров.';
							|en = 'Goods shipment is not required for the selected references.'; fa = 'Goods shipment is not required for the selected references.';
							|it = 'Per le disposizioni selezionate non è richiesta alcuna spedizione di merce.';
							|pl = 'Według wybranych zamówień nie jest wymagana wysyłka towarów.';
							|tr = 'Seçilen ürünler için sevkiyat gerekmiyor.'");
		CommonClientServer.MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

#EndRegion
