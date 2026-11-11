
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Title = NStr("vi = 'Giấy đề nghị trả hàng từ người mua';
				|ru = 'Заявки на возврат товаров от клиентов';
				|en = 'Sales return requests'; fa = 'درخواست‌های برگشت از فروش';
				|it = 'Domande di reso merci dai clienti';
				|pl = 'Wnioski o zwrot towarów od klientów';
				|tr = 'Müşteriden mal iadesi talebi'");
	If Parameters.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		Title = NStr("vi = 'Giấy đề nghị trả hàng từ người nhận ký gửi';
					|ru = 'Заявки на возврат товаров от комиссионера';
					|en = 'Requests for goods return from consignee'; fa = 'Requests for goods return from consignee';
					|it = 'Dichiarazioni di reso articoli dal commissionario';
					|pl = 'Wnioski o zwrot towarów od komisanta';
					|tr = 'Konsinyeden mal iadesi talebi'");
	EndIf;
	If Parameters.BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5 Then
		Title = NStr("vi = 'Đơn đặt hàng gia công';
					|ru = 'Заказы переработчикам';
					|en = 'Subcontracting purchase orders'; fa = 'سفارش‌های خرید پیمانکاری فرعی';
					|it = 'Ordini agli addetti alla lavorazione';
					|pl = 'Zamówienia do przetwórców';
					|tr = 'Fason üretici satın alma siparişleri'");
	EndIf;
	FillInListOfOrders_();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	Close(Items.ListOfOrders_.CurrentData.Ref);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	If TMCommonUseClient.CheckForSelectedLinesInList(Items.ListOfOrders_) Then
		Close(Items.ListOfOrders_.CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInListOfOrders_()
	
	Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(Parameters.BusinessOperation);
	
	QueryTexts = New Array;
	
	RequestTextParameters = TMCommonUse.ParametersOfRequestTextForOrdersInvoices();
	RequestTextParameters.GenerateTT = True;
	RequestTextParameters.TTName = "WaybillOrders";
	
	QueryTexts.Add(Handler.QueryTextWaybillOrders(RequestTextParameters));
	QueryTexts.Add(Handler.QueryTextInstructionsForRegistration());
	
	QueryText =
	"SELECT ALLOWED
	|	Orders.ReferenceOrder                     AS Ref,
	|	VALUETYPE(Orders.ReferenceOrder)        AS TypeOfOrder_,
	|	Orders.ReferenceOrder.Priority           AS Priority,
	|	CASE
	|		WHEN Orders.ReferenceOrder.Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute)
	|			THEN 0
	|		WHEN Orders.ReferenceOrder.Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute DESC)
	|			THEN 2
	|		ELSE 1
	|	END                                   AS PictureOfPriority,
	|	Orders.ReferenceOrder.Date                AS Date,
	|	Orders.ReferenceOrder.Number               AS Number,
	|	Orders.ReferenceOrder.Status              AS Status,
	|	Orders.ReferenceOrder.Partner             AS Partner,
	|	Orders.ReferenceOrder.Counterparty          AS Counterparty,
	|	Orders.ReferenceOrder.Terms          AS Terms,
	|	Orders.ReferenceOrder.Organization         AS Organization,
	|	Orders.ReferenceOrder.Contract             AS Contract,
	|	Orders.ReferenceOrder.Warehouse               AS Warehouse,
	|	Orders.ReferenceOrder.Currency              AS Currency,
	|	Orders.ReferenceOrder.Manager            AS Manager,
	|	Orders.ReferenceOrder.Comment         AS Comment,
	|	Orders.ReferenceOrder.DocumentAmount      AS DocumentAmount
	|FROM
	|	InstructionsForRegistration AS Orders
	|";
	QueryTexts.Add(QueryText);
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager();
	EndIf;
	
	Query.SetParameter("Recorder",				Parameters.Recorder);
	Query.SetParameter("Partner",					Parameters.Filter.Partner);
	Query.SetParameter("Counterparty",					Parameters.Filter.Counterparty);
	Query.SetParameter("Terms",					Parameters.Filter.Terms);
	Query.SetParameter("Organization",				Parameters.Filter.Organization);
	Query.SetParameter("Contract",					Parameters.Filter.Contract);
	Query.SetParameter("Warehouse",						Parameters.Warehouse);
	Query.SetParameter("Currency",						Parameters.Filter.Currency);
	Query.SetParameter("SalesOpportunity",						Parameters.Filter.SalesOpportunity);
	Query.SetParameter("LineOfBusiness",	Parameters.Filter.LineOfBusiness);
	Query.SetParameter("ToReturnReusablePackage",	Parameters.Filter.ToReturnReusablePackage);
	
	Result = Query.Execute();
	
	ListOfOrders_.Load(Result.Unload());
	
EndProcedure

#EndRegion

