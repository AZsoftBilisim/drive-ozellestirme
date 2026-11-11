
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	If Parameters.BusinessOperation = Enums.BusinessTransactions.TransferToToller2_5 Then
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
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(Parameters.BusinessOperation);
	
	QueryTexts = New Array;
	
	RequestTextParameters = TMCommonUse.ParametersOfRequestTextForOrdersInvoices();
	RequestTextParameters.GenerateTT = True;
	RequestTextParameters.TTName = "WaybillOrders";
	
	QueryTexts.Add(Handler.QueryTextWaybillOrders(RequestTextParameters));
	QueryTexts.Add(Documents.TransferOfGoodsToBailee.QueryTextRemnantsOfGoodsForRegistration("GoodsForRegistration"));
	
	QueryText =
	"SELECT
	|	GoodsForRegistration.ReferenceOrder AS ReferenceOrder,
	|	GoodsForRegistration.Warehouse        AS Warehouse
	|INTO InstructionsForRegistration
	|FROM
	|	GoodsForRegistration AS GoodsForRegistration
	|
	|GROUP BY
	|	GoodsForRegistration.ReferenceOrder,
	|	GoodsForRegistration.Warehouse
	|
	|INDEX BY
	|	ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	InstructionsForRegistration.ReferenceOrder              AS Ref,
	|	VALUETYPE(InstructionsForRegistration.ReferenceOrder) AS TypeOfOrder_,
	|	CASE
	|		WHEN VALUETYPE(InstructionsForRegistration.ReferenceOrder) = TYPE(Document.SalesOrder)
	|			THEN CAST(InstructionsForRegistration.ReferenceOrder AS Document.SalesOrder).Priority
	|		WHEN VALUETYPE(InstructionsForRegistration.ReferenceOrder) = TYPE(Document.SubcontractOrder2_5)
	|			THEN CAST(InstructionsForRegistration.ReferenceOrder AS Document.SubcontractOrder2_5).Priority
	|	END                                             AS Priority,
	|	CASE
	|		WHEN VALUETYPE(InstructionsForRegistration.ReferenceOrder) = TYPE(Document.SalesOrder)
	|			AND CAST(InstructionsForRegistration.ReferenceOrder AS Document.SalesOrder).Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute)
	|			THEN 0
	|		WHEN VALUETYPE(InstructionsForRegistration.ReferenceOrder) = TYPE(Document.SubcontractOrder2_5)
	|			AND CAST(InstructionsForRegistration.ReferenceOrder AS Document.SubcontractOrder2_5).Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute)
	|			THEN 0
	|		WHEN VALUETYPE(InstructionsForRegistration.ReferenceOrder) = TYPE(Document.SalesOrder)
	|			AND CAST(InstructionsForRegistration.ReferenceOrder AS Document.SalesOrder).Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute DESC)
	|			THEN 2
	|		WHEN VALUETYPE(InstructionsForRegistration.ReferenceOrder) = TYPE(Document.SubcontractOrder2_5)
	|			AND CAST(InstructionsForRegistration.ReferenceOrder AS Document.SubcontractOrder2_5).Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute DESC)
	|			THEN 2
	|		ELSE 1
	|	END                                             AS PictureOfPriority,
	|	DocumentsRegistry.IBDocumentDate                  AS Date,
	|	DocumentsRegistry.IBDocumentNumber                 AS Number,
	|	DocumentsRegistry.Status                           AS Status,
	|	DocumentsRegistry.Partner                          AS Partner,
	|	DocumentsRegistry.Counterparty.Key                  AS Counterparty,
	|	CAST(InstructionsForRegistration.ReferenceOrder AS Document.SalesOrder).Terms AS Terms,
	|	DocumentsRegistry.Organization                      AS Organization,
	|	DocumentsRegistry.Contract                          AS Contract,
	|	InstructionsForRegistration.Warehouse                     AS Warehouse,
	|	DocumentsRegistry.Currency                           AS Currency,
	|	DocumentsRegistry.EmployeeResponsible                    AS Manager,
	|	DocumentsRegistry.Comment                      AS Comment,
	|	DocumentsRegistry.Sum                            AS DocumentAmount
	|FROM
	|	InstructionsForRegistration AS InstructionsForRegistration
	|	
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	ON DocumentsRegistry.Ref = InstructionsForRegistration.ReferenceOrder
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|";
	QueryTexts.Add(QueryText);
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
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

