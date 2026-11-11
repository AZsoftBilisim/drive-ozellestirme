
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Var FilterValue;
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.Title) Then
		Title = Parameters.Title;
	EndIf;
	
	FillInListOfOrders_();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	OrderInformation = New Structure();
	OrderInformation.Insert("SalesOrder",Items.ListOfOrders_.CurrentData.Ref);
	OrderInformation.Insert("Purpose",Items.ListOfOrders_.CurrentData.Purpose);

	Close(OrderInformation);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	If TMCommonUseClient.CheckForSelectedLinesInList(Items.ListOfOrders_) Then
		OrderInformation = New Structure();
		OrderInformation.Insert("SalesOrder",Items.ListOfOrders_.CurrentData.Ref);
		OrderInformation.Insert("Purpose",Items.ListOfOrders_.CurrentData.Purpose);
		Close(OrderInformation);
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

	QueryText =
	"SELECT
	|	OrdersTable.SalesOrder AS SalesOrder,
	|	SUM(OrdersTable.ToRegister) AS ToRegister
	|INTO OrdersTable2
	|FROM
	|	(SELECT
	|		TurnoversByOrders.ReferenceOrder AS SalesOrder,
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover
	|			- TurnoversByOrders.IssuedQuantityTurnover) AS ToRegister
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded AS TurnoversByOrders
	|	WHERE
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover
	|			- TurnoversByOrders.IssuedQuantityTurnover) <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SalesOrder.Ref,
	|		CustomerOrderGoods.Count
	|	FROM
	|		Document.RequestForReturnOfGoodsFromCustomer AS SalesOrder
	|			INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS CustomerOrderGoods
	|			ON SalesOrder.Ref = CustomerOrderGoods.Ref
	|	WHERE
	|		SalesOrder.Organization = &Organization
	|		AND SalesOrder.Currency = &Currency
	|		AND SalesOrder.Counterparty = &Counterparty
	|		AND SalesOrder.Contract = &Contract
	|		AND SalesOrder.Partner = &Partner
	|		AND CustomerOrderGoods.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoice)
	|		AND (SalesOrder.Warehouse = &Warehouse
	|				OR SalesOrder.Warehouse IN HIERARCHY (&Warehouse)
	|				OR SalesOrder.Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|		AND CASE
	|				WHEN NOT &UseLinesOfBusiness
	|					THEN TRUE
	|				ELSE SalesOrder.LineOfBusiness = &LineOfBusiness
	|			END
	|		AND NOT CustomerOrderGoods.Canceled
	|		AND NOT &UseAdvancedFeaturesOfSalesOrder
	|		AND NOT SalesOrder.DeletionMark
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OrdersRegisterRecords.ReferenceOrder,
	|		CASE
	|			WHEN OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
	|				THEN -OrdersRegisterRecords.Count
	|			ELSE OrdersRegisterRecords.Count
	|		END
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS OrdersRegisterRecords
	|	WHERE
	|		OrdersRegisterRecords.Recorder = &Recorder
	|		AND OrdersRegisterRecords.Factor IN
	|			(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1))
	|		AND OrdersRegisterRecords.Active
	|		AND OrdersRegisterRecords.ReferenceOrder.Organization = &Organization
	|		AND OrdersRegisterRecords.ReferenceOrder.Currency = &Currency
	|		AND OrdersRegisterRecords.ReferenceOrder.Counterparty = &Counterparty
	|		AND OrdersRegisterRecords.ReferenceOrder.Contract = &Contract
	|		AND OrdersRegisterRecords.ReferenceOrder.Partner = &Partner
	|		AND OrdersRegisterRecords.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoice)
	|		AND CASE
	|				WHEN NOT &UseLinesOfBusiness
	|					THEN TRUE
	|				ELSE OrdersRegisterRecords.ReferenceOrder.LineOfBusiness = &LineOfBusiness
	|			END
	|		AND (OrdersRegisterRecords.Warehouse = &Warehouse
	|				OR OrdersRegisterRecords.Warehouse IN HIERARCHY (&Warehouse)
	|				OR OrdersRegisterRecords.Warehouse = VALUE(Catalog.Warehouses.EmptyRef))) AS OrdersTable
	|
	|GROUP BY
	|	OrdersTable.SalesOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Orders.Ref AS Ref,
	|	VALUETYPE(Orders.Ref) AS TypeOfOrder_,
	|	Orders.Date AS Date,
	|	Orders.Number AS Number,
	|	Orders.Partner AS Partner,
	|	Orders.Counterparty AS Counterparty,
	|	Orders.Contract AS Contract,
	|	Orders.Terms AS Terms,
	|	Orders.Organization AS Organization,
	|	Orders.Warehouse AS Warehouse,
	|	Orders.Currency AS Currency,
	|	Orders.Manager AS Manager,
	|	Orders.Status AS Status,
	|	Orders.DocumentAmount AS DocumentAmount,
	|	Orders.Priority AS Priority,
	|	Orders.BusinessOperation AS BusinessOperation,
	|	Orders.ARAPObjectSettings AS ARAPObjectSettings,
	|	Orders.Comment AS Comment,
	|	CASE
	|		WHEN Orders.Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute)
	|			THEN 0
	|		WHEN Orders.Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute DESC)
	|			THEN 2
	|		ELSE 1
	|	END AS PictureOfPriority,
	|	Orders.Purpose AS Purpose
	|FROM
	|	Document.SalesOrder AS Orders
	|		INNER JOIN OrdersTable1 AS OrdersTable1
	|		ON Orders.Ref = OrdersTable1.OrderDocument
	|	
	|	UNION ALL
	|	
	|SELECT
	|	Orders.Ref                AS Ref,
	|	VALUETYPE(Orders.Ref)   AS TypeOfOrder_,
	|	Orders.Date                  AS Date,
	|	Orders.Number                 AS Number,
	|	Orders.Partner               AS Partner,
	|	Orders.Counterparty            AS Counterparty,
	|	Orders.Contract               AS Contract,
	|	UNDEFINED                 AS Terms,
	|	Orders.Organization           AS Organization,
	|	Orders.Warehouse                 AS Warehouse,
	|	Orders.Currency                AS Currency,
	|	Orders.Manager              AS Manager,
	|	Orders.Status                AS Status,
	|	Orders.DocumentAmount        AS DocumentAmount,
	|	Orders.Priority             AS Priority,
	|	Orders.BusinessOperation AS BusinessOperation,
	|	Orders.ARAPObjectSettings       AS ARAPObjectSettings,
	|	Orders.Comment           AS Comment,
	|	CASE
	|		WHEN Orders.Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute)
	|			THEN 0
	|		WHEN Orders.Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute DESC)
	|			THEN 2
	|		ELSE 1
	|	END                        AS PictureOfPriority,
	|	Orders.Purpose            AS Purpose
	|FROM
	|	Document.MaterialProviderOrder2_5 AS Orders
	|		INNER JOIN OrdersTable1 AS OrdersTable1
	|		ON Orders.Ref = OrdersTable1.OrderDocument
	|";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder.Organization = &Organization
		|		AND ReferenceOrder.Currency = &Currency
		|		AND ReferenceOrder.Counterparty = &Counterparty
		|		AND ReferenceOrder.Contract = &Contract
		|		AND ReferenceOrder.Partner = &Partner
		|		AND Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoice)
		|		AND CASE
		|				WHEN NOT &UseLinesOfBusiness
		|					THEN TRUE
		|				ELSE ReferenceOrder.LineOfBusiness = &LineOfBusiness
		|			END
		|		AND (Warehouse = &Warehouse
		|			OR Warehouse IN HIERARCHY (&Warehouse)
		|			OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef))";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add(Documents.GoodsShipmentFromStorage.QueryTextTableOrders("OrdersTable1"));
	ArrayOfTexts.Add(QueryText);
	
	Query = New Query;
	Query.Text = StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Organization",				Parameters.Filter.Organization);
	Query.SetParameter("Counterparty",					Parameters.Filter.Counterparty);
	Query.SetParameter("Currency",						Parameters.Filter.Currency);
	Query.SetParameter("Partner",					Parameters.Filter.Partner);
	Query.SetParameter("Contract",					Parameters.Filter.Contract);
	Query.SetParameter("LineOfBusiness",	Parameters.Filter.LineOfBusiness);
	BusinessOperation = Undefined;
	Parameters.Filter.Property("BusinessOperation", BusinessOperation);
	Query.SetParameter("BusinessOperation",		BusinessOperation);
	Query.SetParameter("Recorder", Parameters.Recorder);
	Query.SetParameter("Warehouse", Parameters.Warehouse);
	
	Query.SetParameter("ToUseTermsOfSales", 
								GetFunctionalOption("ToUseTermsOfSales"));
	Query.SetParameter("UseAdvancedFeaturesOfSalesOrder", 
								GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	Query.SetParameter("UseLinesOfBusiness", 
								GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness"));
	
	If Parameters.Filter.Property("BusinessOperation") Then
		
		If ValueIsFilled(Parameters.Filter.BusinessOperation) Then
			
			TransactionList = Documents.CustomerInvoice.AcceptableOperationsOfBaseDocuments(Parameters.Filter.BusinessOperation);
			
			Condition = "	And ";
			Query.SetParameter("BusinessTransactionList", TransactionList);
			
		Else
			
			TransactionList = New ValueList;
			TransactionList.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
			TransactionList.Add(Enums.BusinessTransactions.ReturnFromCommissionAgent);
			TransactionList.Add(Enums.BusinessTransactions.ReturnFromRetailCustomer);
			
			Condition = "	AND NOT ";
			Query.SetParameter("BusinessTransactionList", TransactionList);
			
		EndIf;
		
		Query.Text = StrReplace(Query.Text,
									"//ConditionOfEconomicOperationOrders",
									Condition + "Orders.BusinessOperation IN (&BusinessTransactionList)");
		
		Query.Text = StrReplace(Query.Text,
									"//ConditionOfEconomicOperationOfApplication",
									Condition + "Requests.BusinessOperation IN (&BusinessTransactionList)");
		
	EndIf;
	
	Result = Query.Execute();
	ListOfOrders_.Load(Result.Unload());
	
EndProcedure

#EndRegion

