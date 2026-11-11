
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.GeneratePurchaseRequests Then
		Title = NStr("vi = 'Tham số tạo mới yêu cầu';
					|ru = 'Параметры создания заявки';
					|en = 'Request creation parameters'; fa = 'Request creation parameters';
					|it = 'Request creation parameters';
					|pl = 'Request creation parameters';
					|tr = 'Talep oluşturma parametreleri'");
		Items.SplitOrdersByOrderDates.Title = NStr("vi = 'theo ngày yêu cầu';
													|ru = 'по датам заявки';
													|en = 'by request dates'; fa = 'by request dates';
													|it = 'by request dates';
													|pl = 'by request dates';
													|tr = 'talep tarihlerine göre'");
	Else
		Title = NStr("vi = 'Tham số tạo mới đơn hàng';
					|ru = 'Параметры создания заказа';
					|en = 'Order creation parameters'; fa = 'پارامترهای ایجاد سفارش';
					|it = 'Opzioni di creazione dell''ordine';
					|pl = 'Parametry tworzenia zamówienia';
					|tr = 'Sipariş oluşturma parametreleri'");
	EndIf;
	
	SplitOrdersByOrderDates = Parameters.SplitOrdersByOrderDates;
	SplitOrdersByDeliveryDates = Parameters.SplitOrdersByDeliveryDates;
	SplitOrdersByAssignments = Parameters.SplitOrdersByAssignments;
	SplitOrdersByWarehouses = Parameters.SplitOrdersByWarehouses;
	SplitOrdersByPlanLines = Parameters.SplitOrdersByPlanLines;
	
	Items.SplitOrdersByAssignments.Visible = Parameters.DestinationVisibility;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	OrderCreationParameters = New Structure();
	OrderCreationParameters.Insert("SplitOrdersByOrderDates", SplitOrdersByOrderDates);
	OrderCreationParameters.Insert("SplitOrdersByDeliveryDates", SplitOrdersByDeliveryDates);
	OrderCreationParameters.Insert("SplitOrdersByAssignments", SplitOrdersByAssignments);
	OrderCreationParameters.Insert("SplitOrdersByWarehouses", SplitOrdersByWarehouses);
	OrderCreationParameters.Insert("SplitOrdersByPlanLines", SplitOrdersByPlanLines);
	
	NotifyChoice(OrderCreationParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
