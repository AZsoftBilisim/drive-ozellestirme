
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	WarehouseDocument = Parameters.WarehouseDocument;
	OrderDetails_1 = Common.ObjectAttributesValues(WarehouseDocument, "Warehouse,Premise,WarehouseOperation,Recipient,ShipmentUnderTransportationJob");
	FillPropertyValues(ThisObject,OrderDetails_1); 
	
	ChoiceItem = Items.FilterByReferences.ChoiceList.FindByValue("OrdersByRecipient");
	ChoiceItem.Presentation = StrReplace(ChoiceItem.Presentation, "%Recipient%", Recipient);

	Items.GoodsIssueNotesVehicle_.Visible = ShipmentUnderTransportationJob;
	Items.GoodsIssueNotesTransportationTaskNumber.Visible = ShipmentUnderTransportationJob;
	
	FilterByReferences = "OrdersByReferences";
	
	FillListOfOrders();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterByReferencesOnChange(Item)
	FillListOfOrders();
EndProcedure

&AtClient
Procedure FilterByReferencesClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReferences

&AtClient
Procedure GoodsIssueNotesSelection(Item, RowSelected, Field, StandardProcessing)
	CurrentData = Items.GoodsIssueNotes.CurrentData;
	NotifyChoice(CurrentData.ExpenseOrder);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	CurrentData = Items.GoodsIssueNotes.CurrentData;
	
	If CurrentData = Undefined Then
		WarningText = NStr("vi = 'Hãy chọn phiếu xuất kho.';
							|ru = 'Выберите расходный ордер.';
							|en = 'Select goods issue note.'; fa = 'Select goods issue note.';
							|it = 'Selezionate un mandato di pagamento.';
							|pl = 'Wybierz zlecenie wydania.';
							|tr = 'Ambar çıkış fişini seç.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
		
	NotifyChoice(CurrentData.ExpenseOrder);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillListOfOrders()
	
	If IsBlankString(FilterByReferences) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If FilterByReferences = "OrdersByReferences" Then
		QueryText =
		"SELECT DISTINCT
		|	GoodsIssueNoteGoodsByReferences.ReferenceOrder
		|INTO OrdersOrders
		|FROM
		|	Document.GoodsIssueNote.GoodsByReferences AS GoodsIssueNoteGoodsByReferences
		|WHERE
		|	GoodsIssueNoteGoodsByReferences.Ref = &WarehouseDocument
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ExpenditureOrderOrders.Ref AS Ref,
		|	ExpenditureOrderOrders.ReferenceOrder AS ReferenceOrder
		|INTO OtherSpendingOrdersOrders
		|FROM
		|	Document.GoodsIssueNote.GoodsByReferences AS ExpenditureOrderOrders
		|WHERE
		|	ExpenditureOrderOrders.Ref <> &WarehouseDocument
		|	AND ExpenditureOrderOrders.Ref.Warehouse = &Warehouse
		|	AND ExpenditureOrderOrders.Ref.Premise = &Premise
		|	AND ExpenditureOrderOrders.Ref.ShipmentUnderTransportationJob = &ShipmentUnderTransportationJob
		|	AND ExpenditureOrderOrders.Ref.WarehouseOperation = &WarehouseOperation
		|	AND ExpenditureOrderOrders.Ref.Recipient = &Recipient
		|	AND ExpenditureOrderOrders.Ref.Posted
		|	AND ExpenditureOrderOrders.ReferenceOrder IN
		|			(SELECT
		|				OrdersOrders.ReferenceOrder
		|			FROM
		|				OrdersOrders)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Ref
		|INTO SelectedOrders_2
		|FROM
		|	(SELECT
		|		OtherSpendingOrdersOrders.Ref AS Ref,
		|		COUNT(DISTINCT OtherSpendingOrdersOrders.ReferenceOrder) AS NumberOfOrdersInAnotherOrder
		|	FROM
		|		OtherSpendingOrdersOrders AS OtherSpendingOrdersOrders
		|	
		|	GROUP BY
		|		OtherSpendingOrdersOrders.Ref
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ISNULL(OtherSpendingOrdersOrders.Ref, UNDEFINED),
		|		-COUNT(DISTINCT OrdersOrders.ReferenceOrder)
		|	FROM
		|		OrdersOrders AS OrdersOrders
		|			LEFT JOIN OtherSpendingOrdersOrders AS OtherSpendingOrdersOrders
		|			ON OrdersOrders.ReferenceOrder = OtherSpendingOrdersOrders.ReferenceOrder
		|	
		|	GROUP BY
		|		ISNULL(OtherSpendingOrdersOrders.Ref, UNDEFINED)) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Ref
		|
		|HAVING
		|	SUM(NestedQuery.NumberOfOrdersInAnotherOrder) = 0";
	ElsIf FilterByReferences = "OrdersByRecipient" Then
		QueryText =
		"SELECT
		|	ExpenseOrder.Ref AS Ref
		|INTO SelectedOrders_2
		|FROM
		|	Document.GoodsIssueNote AS ExpenseOrder
		|WHERE
		|	ExpenseOrder.Ref <> &WarehouseDocument
		|	AND ExpenseOrder.Warehouse = &Warehouse
		|	AND ExpenseOrder.Premise = &Premise
		|	AND ExpenseOrder.ShipmentUnderTransportationJob = &ShipmentUnderTransportationJob
		|	AND ExpenseOrder.WarehouseOperation = &WarehouseOperation
		|	AND ExpenseOrder.Recipient = &Recipient
		|	AND ExpenseOrder.Posted";
	EndIf;
	
	QueryText = 	QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	QueryText = 	QueryText + 	
	"SELECT
	|	SelectedOrders_2.Ref AS ExpenseOrder,
	|	SelectedOrders_2.Ref.TransportationJob.Number AS TransportationTaskNumber,
	|	SelectedOrders_2.Ref.DateOfShipment AS DateOfShipment,
	|	SelectedOrders_2.Ref.TransportationJob.Vehicle_ AS Vehicle_
	|FROM
	|	SelectedOrders_2 AS SelectedOrders_2
	|
	|ORDER BY
	|	DateOfShipment DESC";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("WarehouseDocument",WarehouseDocument);
	Query.SetParameter("Warehouse",Warehouse);
	Query.SetParameter("Premise",Premise);
	Query.SetParameter("ShipmentUnderTransportationJob",ShipmentUnderTransportationJob);
	Query.SetParameter("WarehouseOperation",WarehouseOperation);
	Query.SetParameter("Recipient",Recipient);
	
	
	GoodsIssueNotes.Load(Query.Execute().Unload());
EndProcedure

#EndRegion