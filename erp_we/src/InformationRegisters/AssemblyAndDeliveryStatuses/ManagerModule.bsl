#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the status of the order.
//
// Parameters:
//  OrderDocument - DocumentRef.SalesOrder - order.
//
// Returns:
//  EnumRef.AssemblyAndDeliveryStatuses - Current status of the order
//
Function GetOrderStatus(OrderDocument) Export

	Query = New Query;
	Query.Text =
	"SELECT
	|	AssemblyAndDeliveryStatuses.Status AS Status,
	|	AssemblyAndDeliveryStatuses.OrderData AS OrderData
	|FROM
	|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	|WHERE
	|	AssemblyAndDeliveryStatuses.ReferenceOrder = &ReferenceOrder";

	Query.SetParameter("ReferenceOrder", OrderDocument);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Return Selection.Status;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Returns intermediate saved order data.
//
// Parameters:
//  ReferenceOrder - DocumentRef.SalesOrder - order.
//
// Returns:
//  ValueStorage - saved intermediate assembly data.
//
Function GetIntermediateBuildData(ReferenceOrder) Export

	Query = New Query;
	Query.Text =
	"SELECT
	|	AssemblyAndDeliveryStatuses.OrderData AS OrderData
	|FROM
	|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	|WHERE
	|	AssemblyAndDeliveryStatuses.ReferenceOrder = &ReferenceOrder";

	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Return Selection.OrderData;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Records the status of the transmitted order.
// 
// Parameters:
// 	ReferenceOrder - DocumentRef.SalesOrder, DocumentRef.CustomerInvoice - 
// 	Cancel - Boolean
// 	RemovalOfBody - Boolean
//
Procedure RecordStatusFromOrder(ReferenceOrder, Cancel, RemovalOfBody = False) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	If TypeOf(ReferenceOrder) = Type("DocumentRef.SalesOrder") Then
		
		OrderStatus = Common.ObjectAttributeValue(ReferenceOrder, "Status");
		If OrderStatus = Enums.SalesOrderStatuses.NotApproved Then
			DeleteEntryWithStatus(ReferenceOrder);
			Return;
		EndIf;
		
		Products_From_Orders = Common.ObjectAttributeValue(ReferenceOrder, "Goods").Unload(); // ValueTable
		
		If OrderStatus = Enums.SalesOrderStatuses.Closed Then
			RowsCount = Products_From_Orders.Count();
			
			SearchParameters = New Structure("Canceled", True);
			CancelledRows = Products_From_Orders.FindRows(SearchParameters);
			
			If RowsCount = CancelledRows.Count() Then
				InformationRegisters.AssemblyAndDeliveryStatuses.RecordStatus(ReferenceOrder, Enums.AssemblyAndDeliveryStatuses.RolledBack_);
				Return;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If RemovalOfBody Then
		DeleteEntryWithStatus(ReferenceOrder);
		Return
	EndIf;
	
	StatusSet = StatusOfOrderIsSet(ReferenceOrder);
	
	If StatusSet Then
		Return;
	EndIf;
	
	Warehouse = Common.ObjectAttributeValue(ReferenceOrder, "Warehouse");
	DocumentDate = Common.ObjectAttributeValue(ReferenceOrder, "Date");
	
	AssemblyIsSupported = WarehousesServer.ThereIsSupportForBuildingOrders(Warehouse, DocumentDate);
	If AssemblyIsSupported Then
		Status = Enums.AssemblyAndDeliveryStatuses.ForAssembly;
		RecordStatus(ReferenceOrder, Status);
		Return;
	EndIf;
	
	DeliveryIsSupported = WarehousesServer.ThereIsSupportForDeliveryByYourOwnCouriers(Warehouse, DocumentDate);
	If DeliveryIsSupported Then
		Status = Enums.AssemblyAndDeliveryStatuses.ReadyForDelivery;
		RecordStatus(ReferenceOrder, Status);
		Return;
	EndIf;
	
EndProcedure

// Sets the status of the transmitted order.
// 
// Parameters:
// 	ReferenceOrder - DocumentRef.CustomerInvoice, DocumentRef.SalesOrder - 
// 	Status - EnumRef.AssemblyAndDeliveryStatuses
//
Procedure RecordStatus(ReferenceOrder, Status) Export
	
	RegisterRecord = InformationRegisters.AssemblyAndDeliveryStatuses.CreateRecordManager();
	RegisterRecord.ReferenceOrder = ReferenceOrder;
	RegisterRecord.Read();
	
	RegisterRecord.ReferenceOrder = ReferenceOrder;
	RegisterRecord.Status = Status;

	Products_From_Orders = Common.ObjectAttributeValue(ReferenceOrder, "Goods").Unload(); // ValueTable
	RegisterRecord.NumberOfRowsInOrder = Products_From_Orders.Count();
	
	Try
		RegisterRecord.Write(True);
	Except
		ErrorText = NStr("vi = 'Không thể ghi lại trạng thái.';
						|ru = 'Не удалось записать статус.';
						|en = 'Cannot save status.'; fa = 'Cannot save status.';
						|it = 'Non è stato possibile registrare lo stato.';
						|pl = 'Nie udało się zapisać statusu.';
						|tr = 'Durum kaydedilmedi.'");
		ErrorText = ErrorText + Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Common.MessageToUser(ErrorText);
	EndTry;
	
EndProcedure

// Writes the intermediate information in the build.
// 
// Parameters:
// 	ReferenceOrder - DocumentRef.SalesOrder, DocumentRef.CustomerInvoice - 
// 	Data - ValueStorage
// 	NumberOfRowsAssembled - Number
//
Procedure WriteIntermediateAssemblyData(ReferenceOrder, Data, NumberOfRowsAssembled) Export
	
	RecordSet = InformationRegisters.AssemblyAndDeliveryStatuses.CreateRecordSet(); 
	RecordSet.Filter.ReferenceOrder.Set(ReferenceOrder);
	RecordSet.Read(); 
	
	For Each Record In RecordSet Do
		Record.OrderData = Data;
		Record.NumberOfRowsAssembled = NumberOfRowsAssembled;
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

#EndRegion

#Region Private

Function StatusOfOrderIsSet(ReferenceOrder)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	AssemblyAndDeliveryStatuses.Status AS Status
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|WHERE
		|	AssemblyAndDeliveryStatuses.ReferenceOrder = &ReferenceOrder";
	
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

Procedure DeleteEntryWithStatus(ReferenceOrder)
	
	Set = InformationRegisters.AssemblyAndDeliveryStatuses.CreateRecordSet();
	Set.Filter.ReferenceOrder.Set(ReferenceOrder);
	Set.Write(True);
	
EndProcedure

#EndRegion

#EndIf
