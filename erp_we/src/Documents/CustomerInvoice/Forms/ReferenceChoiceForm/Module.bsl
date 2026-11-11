
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Var FilterValue;
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FillInListOfOrders_();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	Close(New Structure("SalesOrder, ARAPObjectSettings", 
			                Items.ListOfOrders_.CurrentData.Ref,
			                Items.ListOfOrders_.CurrentData.ARAPObjectSettings));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	If TMCommonUseClient.CheckForSelectedLinesInList(Items.ListOfOrders_) Then
		Close(
			New Structure("SalesOrder, ARAPObjectSettings", 
			                Items.ListOfOrders_.CurrentData.Ref,
			                Items.ListOfOrders_.CurrentData.ARAPObjectSettings));
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

	Query = New Query;
	Query.Text = 
	"SELECT
	|	OrdersTable.SalesOrder AS SalesOrder,
	|	SUM(OrdersTable.ToRegister) AS ToRegister
	|INTO OrdersTable1
	|FROM
	|	(SELECT
	|		CAST(TurnoversByOrders.ReferenceOrder AS Document.SalesOrder) AS SalesOrder,
	|		CASE
	|			WHEN &EconomicOperationOfRealization <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|				THEN TurnoversByOrders.QuantityToBeShippedTurnover - TurnoversByOrders.ShippedQuantityTurnover
	|			ELSE
	|				TurnoversByOrders.ShippedQuantityTurnover
	|					+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|					- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|					- TurnoversByOrders.QuantityAccepted_Turnover
	|					- TurnoversByOrders.IssuedQuantityTurnover
	|		END AS ToRegister
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded1 AS TurnoversByOrders
	|	WHERE
	|		CASE
	|			WHEN &EconomicOperationOfRealization <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|				THEN TurnoversByOrders.QuantityToBeShippedTurnover - TurnoversByOrders.ShippedQuantityTurnover
	|			ELSE
	|				TurnoversByOrders.ShippedQuantityTurnover
	|					+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|					- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|					- TurnoversByOrders.QuantityAccepted_Turnover
	|					- TurnoversByOrders.IssuedQuantityTurnover
	|		END <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		SalesOrder.Ref AS SalesOrder,
	|		CustomerOrderGoods.Count AS ToRegister
	|	FROM
	|		Document.SalesOrder AS SalesOrder
	|			INNER JOIN Document.SalesOrder.Goods AS CustomerOrderGoods
	|			ON SalesOrder.Ref = CustomerOrderGoods.Ref
	|	WHERE
	|		SalesOrder.Organization = &Organization
	|		AND SalesOrder.Currency = &Currency
	|		AND SalesOrder.Counterparty = &Counterparty
	|		AND SalesOrder.Contract = &Contract
	|		AND CASE
	|			WHEN SalesOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
	|				VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
	|				THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|			ELSE SalesOrder.VATTaxation
	|		END = &VATTaxation
	|		AND SalesOrder.Partner = &Partner
	|		AND CASE
	|			WHEN NOT &ToUseTermsOfSales
	|				THEN TRUE
	|			ELSE SalesOrder.Terms = &Terms
	|		END
	|		AND SalesOrder.PriceIncludesVAT = &PriceIncludesVAT
	|		AND SalesOrder.SalesOpportunity = &SalesOpportunity
	|		AND SalesOrder.ToReturnReusablePackage = &ToReturnReusablePackage
	|		AND SalesOrder.PackageDepositIsRequired = &PackageDepositIsRequired
	|		AND CustomerOrderGoods.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoice)
	|		AND (SalesOrder.Warehouse = &Warehouse
	|		OR SalesOrder.Warehouse IN HIERARCHY (&Warehouse)
	|		OR SalesOrder.Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|		AND CASE
	|			WHEN NOT &UseLinesOfBusiness
	|				THEN TRUE
	|			ELSE SalesOrder.LineOfBusiness = &LineOfBusiness
	|		END
	|		AND NOT CustomerOrderGoods.Canceled
	|		AND SalesOrder.ThisIsOrderAsInvoice
	|		AND &ThisIsOrderAsInvoice
	|		AND &EconomicOperationOfRealization <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|		AND NOT SalesOrder.DeletionMark
	|
	|	UNION ALL
	|
	|	SELECT
	|		CAST(OrdersRegisterRecords.ReferenceOrder AS Document.SalesOrder) AS SalesOrder,
	|		OrdersRegisterRecords.Count AS ToRegister
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS OrdersRegisterRecords
	|	WHERE
	|		OrdersRegisterRecords.Recorder = &Recorder
	|		AND OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|		AND OrdersRegisterRecords.Active
	|		AND OrdersRegisterRecords.ReferenceOrder REFS Document.SalesOrder) AS OrdersTable
	|
	|GROUP BY
	|	OrdersTable.SalesOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersTable.SalesOrder AS SalesOrder,
	|	SUM(OrdersTable.ToRegister) AS ToRegister
	|INTO OrdersTable2
	|FROM
	|	(SELECT
	|		CAST(TurnoversByOrders.ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer) AS SalesOrder,
	|		CASE
	|			WHEN &EconomicOperationOfRealization <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|				THEN TurnoversByOrders.QuantityToBeShippedTurnover - TurnoversByOrders.ShippedQuantityTurnover
	|			ELSE
	|				TurnoversByOrders.ShippedQuantityTurnover
	|					+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|					- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|					- TurnoversByOrders.QuantityAccepted_Turnover
	|					- TurnoversByOrders.IssuedQuantityTurnover
	|		END AS ToRegister
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded2 AS TurnoversByOrders
	|	WHERE
	|		CASE
	|			WHEN &EconomicOperationOfRealization <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|				THEN TurnoversByOrders.QuantityToBeShippedTurnover - TurnoversByOrders.ShippedQuantityTurnover
	|			ELSE
	|				TurnoversByOrders.ShippedQuantityTurnover
	|					+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|					- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|					- TurnoversByOrders.QuantityAccepted_Turnover
	|					- TurnoversByOrders.IssuedQuantityTurnover
	|		END <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		SalesOrder.Ref AS SalesOrder,
	|		CustomerOrderGoods.Count AS ToRegister
	|	FROM
	|		Document.RequestForReturnOfGoodsFromCustomer AS SalesOrder
	|			INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS CustomerOrderGoods
	|			ON SalesOrder.Ref = CustomerOrderGoods.Ref
	|	WHERE
	|		SalesOrder.Organization = &Organization
	|		AND SalesOrder.Currency = &Currency
	|		AND SalesOrder.Counterparty = &Counterparty
	|		AND SalesOrder.Contract = &Contract
	|		AND CASE
	|			WHEN SalesOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
	|				VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
	|				THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|			ELSE SalesOrder.VATTaxation
	|		END = &VATTaxation
	|		AND SalesOrder.Partner = &Partner
	|		AND CASE
	|			WHEN NOT &ToUseTermsOfSales
	|				THEN TRUE
	|			ELSE SalesOrder.Terms = &Terms
	|		END
	|		AND SalesOrder.PriceIncludesVAT = &PriceIncludesVAT
	|		AND SalesOrder.SalesOpportunity = &SalesOpportunity
	|		AND SalesOrder.ToReturnReusablePackage = &ToReturnReusablePackage
	|		AND CustomerOrderGoods.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoice)
	|		AND (SalesOrder.Warehouse = &Warehouse
	|		OR SalesOrder.Warehouse IN HIERARCHY (&Warehouse)
	|		OR SalesOrder.Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|		AND CASE
	|			WHEN NOT &UseLinesOfBusiness
	|				THEN TRUE
	|			ELSE SalesOrder.LineOfBusiness = &LineOfBusiness
	|		END
	|		AND NOT CustomerOrderGoods.Canceled
	|		AND SalesOrder.ThisIsOrderAsInvoice
	|		AND &ThisIsOrderAsInvoice
	|		AND &EconomicOperationOfRealization <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|		AND NOT SalesOrder.DeletionMark
	|
	|	UNION ALL
	|
	|	SELECT
	|		CAST(OrdersRegisterRecords.ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer) AS SalesOrder,
	|		CASE
	|			WHEN OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
	|				THEN -OrdersRegisterRecords.Count
	|			ELSE OrdersRegisterRecords.Count
	|		END AS ToRegister
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS OrdersRegisterRecords
	|	WHERE
	|		OrdersRegisterRecords.Recorder = &Recorder
	|		AND OrdersRegisterRecords.Factor IN(
	|					VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|					VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|					)
	|		AND OrdersRegisterRecords.Active
	|		AND OrdersRegisterRecords.ReferenceOrder REFS Document.RequestForReturnOfGoodsFromCustomer) AS OrdersTable
	|
	|GROUP BY
	|	OrdersTable.SalesOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersTable.SalesOrder AS GoodsShipmentToCustomer,
	|	SUM(OrdersTable.ToRegister) AS ToRegister
	|INTO GoodsShipmentTable
	|FROM
	|	(SELECT
	|		CAST(TurnoversByOrders.ReferenceOrder AS Document.GoodsShipmentToCustomer) AS SalesOrder,
	|		TurnoversByOrders.ShippedQuantityTurnover
	|			+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|			- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|			- TurnoversByOrders.QuantityAccepted_Turnover
	|			- TurnoversByOrders.IssuedQuantityTurnover AS ToRegister
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded3 AS TurnoversByOrders
	|	WHERE
	|		TurnoversByOrders.ShippedQuantityTurnover
	|			+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|			- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|			- TurnoversByOrders.QuantityAccepted_Turnover
	|			- TurnoversByOrders.IssuedQuantityTurnover <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		CAST(OrdersRegisterRecords.ReferenceOrder AS Document.GoodsShipmentToCustomer) AS SalesOrder,
	|		CASE
	|			WHEN OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
	|				THEN -OrdersRegisterRecords.Count
	|			ELSE 
	|				OrdersRegisterRecords.Count
	|		END AS ToRegister
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS OrdersRegisterRecords
	|	WHERE
	|		&EconomicOperationOfRealization = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|		AND OrdersRegisterRecords.Active
	|		AND OrdersRegisterRecords.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|		AND OrdersRegisterRecords.Recorder = &Recorder
	|		AND OrdersRegisterRecords.Factor IN(
	|					VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|					VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|					)) AS OrdersTable
	|
	|GROUP BY
	|	OrdersTable.SalesOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersTable.SalesOrder AS SourceDocument,
	|	SUM(OrdersTable.ToRegister) AS ToRegister
	|INTO TablePrimaryDocuments
	|FROM
	|	(SELECT
	|		CAST(TurnoversByOrders.ReferenceOrder AS Document.SourceDocument) AS SalesOrder,
	|		TurnoversByOrders.ShippedQuantityTurnover
	|			+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|			- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|			- TurnoversByOrders.QuantityAccepted_Turnover
	|			- TurnoversByOrders.IssuedQuantityTurnover AS ToRegister
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded4 AS TurnoversByOrders
	|	WHERE
	|		TurnoversByOrders.ShippedQuantityTurnover
	|			+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|			- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|			- TurnoversByOrders.QuantityAccepted_Turnover
	|			- TurnoversByOrders.IssuedQuantityTurnover <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		CAST(OrdersRegisterRecords.ReferenceOrder AS Document.SourceDocument) AS SalesOrder,
	|		CASE
	|			WHEN OrdersRegisterRecords.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
	|				THEN -OrdersRegisterRecords.Count
	|			ELSE 
	|				OrdersRegisterRecords.Count
	|		END AS ToRegister
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS OrdersRegisterRecords
	|	WHERE
	|		&EconomicOperationOfRealization = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|		AND OrdersRegisterRecords.Active
	|		AND OrdersRegisterRecords.ReferenceOrder REFS Document.SourceDocument
	|		AND OrdersRegisterRecords.Recorder = &Recorder
	|		AND OrdersRegisterRecords.Factor IN(
	|					VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|					VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|					)) AS OrdersTable
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
	|	Orders.VATTaxation AS VATTaxation,
	|	Orders.PriceIncludesVAT AS PriceIncludesVAT,
	|	Orders.ARAPObjectSettings AS ARAPObjectSettings,
	|	CAST(Orders.Comment AS STRING(100)),
	|	CASE
	|		WHEN Orders.Priority IN
	|			(SELECT TOP 1
	|				Priorities.Ref AS Priority
	|			FROM
	|				Catalog.Priorities AS Priorities
	|
	|			ORDER BY
	|				Priorities.AddlOrderingAttribute)
	|			THEN 0
	|		WHEN Orders.Priority IN
	|			(SELECT TOP 1
	|				Priorities.Ref AS Priority
	|			FROM
	|				Catalog.Priorities AS Priorities
	|
	|			ORDER BY
	|				Priorities.AddlOrderingAttribute DESC)
	|			THEN 2
	|		ELSE 1
	|	END AS PictureOfPriority
	|FROM
	|	Document.SalesOrder AS Orders
	|		LEFT JOIN OrdersTable1 AS OrdersTable1
	|		ON Orders.Ref = OrdersTable1.SalesOrder
	|WHERE
	|	OrdersTable1.ToRegister > 0
	|
	|UNION ALL
	|
	|SELECT
	|	Requests.Ref,
	|	VALUETYPE(Requests.Ref),
	|	Requests.Date,
	|	Requests.Number,
	|	Requests.Partner,
	|	Requests.Counterparty,
	|	Requests.Contract,
	|	Requests.Terms,
	|	Requests.Organization,
	|	Requests.Warehouse,
	|	Requests.Currency,
	|	Requests.Manager,
	|	Requests.Status,
	|	Requests.DocumentAmount,
	|	Requests.Priority,
	|	Requests.BusinessOperation,
	|	Requests.VATTaxation,
	|	Requests.PriceIncludesVAT,
	|	Requests.ARAPObjectSettings,
	|	CAST(Requests.Comment AS STRING(100)),
	|	CASE
	|		WHEN Requests.Priority IN
	|			(SELECT TOP 1
	|				Priorities.Ref AS Priority
	|			FROM
	|				Catalog.Priorities AS Priorities
	|
	|			ORDER BY
	|				Priorities.AddlOrderingAttribute)
	|			THEN 0
	|		WHEN Requests.Priority IN
	|			(SELECT TOP 1
	|				Priorities.Ref AS Priority
	|			FROM
	|				Catalog.Priorities AS Priorities
	|
	|			ORDER BY
	|				Priorities.AddlOrderingAttribute DESC)
	|			THEN 2
	|		ELSE 1
	|	END
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS Requests
	|		LEFT JOIN OrdersTable2 AS OrdersTable2
	|		ON Requests.Ref = OrdersTable2.SalesOrder
	|WHERE
	|	OrdersTable2.ToRegister > 0
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                       AS Ref,
	|	VALUETYPE(DocumentData.Ref)          AS TypeOfOrder_,
	|	DocumentData.Date                         AS Date,
	|	DocumentData.Number                        AS Number,
	|	DocumentData.Partner                      AS Partner,
	|	DocumentData.Counterparty                   AS Counterparty,
	|	DocumentData.Contract                      AS Contract,
	|	DocumentData.Terms                   AS Terms,
	|	DocumentData.Organization                  AS Organization,
	|	DocumentData.Warehouse                        AS Warehouse,
	|	DocumentData.Currency                       AS Currency,
	|	DocumentData.Manager                     AS Manager,
	|	VALUE(Enum.SalesOrderStatuses.EmptyRef) AS Status,
	|	DocumentData.DocumentAmount               AS DocumentAmount,
	|	VALUE(Catalog.Priorities.EmptyRef) AS Priority,
	|	DocumentData.BusinessOperation        AS BusinessOperation,
	|	DocumentData.VATTaxation           AS VATTaxation,
	|	TRUE                                       AS PriceIncludesVAT,
	|	VALUE(Enum.ARAPObjectSettings.EmptyRef) AS ARAPObjectSettings,
	|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
	|	1                                            AS PictureOfPriority
	|FROM
	|	Document.GoodsShipmentToCustomer AS DocumentData
	|		INNER JOIN GoodsShipmentTable AS GoodsShipmentTable
	|		ON DocumentData.Ref = GoodsShipmentTable.GoodsShipmentToCustomer
	|WHERE
	|	GoodsShipmentTable.ToRegister > 0
	|
	|UNION ALL
	|
	|SELECT
	|	TablePrimaryDocuments.SourceDocument                    AS Ref,
	|	VALUETYPE(TablePrimaryDocuments.SourceDocument)       AS TypeOfOrder_,
	|	TablePrimaryDocuments.SourceDocument.Date               AS Date,
	|	TablePrimaryDocuments.SourceDocument.Number              AS Number,
	|	TablePrimaryDocuments.SourceDocument.Partner            AS Partner,
	|	TablePrimaryDocuments.SourceDocument.Counterparty         AS Counterparty,
	|	TablePrimaryDocuments.SourceDocument.Contract            AS Contract,
	|	GoodsTable.Ref.CustomerTermsOfSales                       AS Terms,
	|	TablePrimaryDocuments.SourceDocument.Organization        AS Organization,
	|	GoodsTable.Ref.Warehouse                                     AS Warehouse,
	|	TablePrimaryDocuments.SourceDocument.Currency             AS Currency,
	|	GoodsTable.Ref.Manager                                  AS Manager,
	|	VALUE(Enum.SalesOrderStatuses.EmptyRef)     AS Status,
	|	SUM(GoodsTable.AmountIncludingVAT)                                 AS DocumentAmount,
	|	VALUE(Catalog.Priorities.EmptyRef)                   AS Priority,
	|	GoodsTable.Ref.BusinessOperation                     AS BusinessOperation,
	|	TablePrimaryDocuments.SourceDocument.VATTaxation AS VATTaxation,
	|	GoodsTable.Ref.PriceIncludesVAT                           AS PriceIncludesVAT,
	|	VALUE(Enum.ARAPObjectSettings.EmptyRef)            AS ARAPObjectSettings,
	|	CAST(TablePrimaryDocuments.SourceDocument.Comment AS STRING(100)) AS Comment,
	|	1                                                              AS PictureOfPriority
	|FROM
	|	Document.OBEntryGoods.Goods AS GoodsTable
	|		INNER JOIN TablePrimaryDocuments AS TablePrimaryDocuments
	|		ON GoodsTable.Ref.Lot = TablePrimaryDocuments.SourceDocument
	|WHERE
	|	GoodsTable.Ref.Posted
	|	AND GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryShippedGoods)
	|	AND TablePrimaryDocuments.ToRegister > 0
	|
	|GROUP BY
	|	TablePrimaryDocuments.SourceDocument,
	|	VALUETYPE(TablePrimaryDocuments.SourceDocument),
	|	TablePrimaryDocuments.SourceDocument.Date,
	|	TablePrimaryDocuments.SourceDocument.Number,
	|	TablePrimaryDocuments.SourceDocument.Partner,
	|	TablePrimaryDocuments.SourceDocument.Counterparty,
	|	TablePrimaryDocuments.SourceDocument.Contract,
	|	GoodsTable.Ref.CustomerTermsOfSales,
	|	TablePrimaryDocuments.SourceDocument.Organization,
	|	GoodsTable.Ref.Warehouse,
	|	TablePrimaryDocuments.SourceDocument.Currency,
	|	GoodsTable.Ref.Manager,
	|	GoodsTable.Ref.BusinessOperation,
	|	TablePrimaryDocuments.SourceDocument.VATTaxation,
	|	GoodsTable.Ref.PriceIncludesVAT,
	|	CAST(TablePrimaryDocuments.SourceDocument.Comment AS STRING(100))
	|";
	
	// 1. For customer orders
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"VALUETYPE(ReferenceOrder) = TYPE(Document.SalesOrder)
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).Organization = &Organization
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).Currency = &Currency
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).Counterparty = &Counterparty
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).Contract = &Contract
		|	AND CASE
		|		WHEN CAST(ReferenceOrder AS Document.SalesOrder).VATTaxation IN(
		|					VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
		|					VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
		|					)
		|			THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|		ELSE
		|			CAST(ReferenceOrder AS Document.SalesOrder).VATTaxation
		|	END = &VATTaxation
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).Partner = &Partner
		|	AND CASE
		|		WHEN NOT &ToUseTermsOfSales
		|			THEN TRUE
		|		ELSE
		|			CAST(ReferenceOrder AS Document.SalesOrder).Terms = &Terms
		|	END
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).PriceIncludesVAT = &PriceIncludesVAT
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).SalesOpportunity = &SalesOpportunity
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).ToReturnReusablePackage = &ToReturnReusablePackage
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).PackageDepositIsRequired = &PackageDepositIsRequired
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).ThisIsOrderAsInvoice = &ThisIsOrderAsInvoice
		|	AND Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoice)
		|	AND CASE
		|		WHEN NOT &UseLinesOfBusiness
		|			THEN TRUE
		|		ELSE
		|			CAST(ReferenceOrder AS Document.SalesOrder).LineOfBusiness = &LineOfBusiness
		|	END
		|	AND (Warehouse = &Warehouse
		|		OR Warehouse IN HIERARCHY (&Warehouse)
		|		OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		OR &EconomicOperationOfRealization <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods))
		|";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators =
		"ToShip, Shipped, ReceivedBeforeTransferOfTitleToGoods, WrittenOffBeforeTransferOfTitleToGoods, Accepted, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded1",
		ShipmentOrdersTurnoverExpanded1);
	
	// 2. For return requests
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"VALUETYPE(ReferenceOrder) = TYPE(Document.RequestForReturnOfGoodsFromCustomer)
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Organization = &Organization
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Currency = &Currency
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Counterparty = &Counterparty
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Contract = &Contract
		|	AND CASE
		|		WHEN CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).VATTaxation IN(
		|					VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
		|					VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
		|					)
		|			THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|		ELSE
		|			CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).VATTaxation
		|	END = &VATTaxation
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Partner = &Partner
		|	AND CASE
		|		WHEN NOT &ToUseTermsOfSales
		|			THEN TRUE
		|		ELSE
		|			CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Terms = &Terms
		|	END
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).PriceIncludesVAT = &PriceIncludesVAT
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).SalesOpportunity = &SalesOpportunity
		|	AND CAST(ReferenceOrder AS
		|		Document.RequestForReturnOfGoodsFromCustomer).ToReturnReusablePackage = &ToReturnReusablePackage
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).PackageDepositIsRequired = &PackageDepositIsRequired
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice = &ThisIsOrderAsInvoice
		|	AND Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoice)
		|	AND CASE
		|		WHEN NOT &UseLinesOfBusiness
		|			THEN TRUE
		|		ELSE CAST(ReferenceOrder AS
		|			Document.RequestForReturnOfGoodsFromCustomer).LineOfBusiness = &LineOfBusiness
		|	END
		|	AND (Warehouse = &Warehouse
		|		OR Warehouse IN HIERARCHY (&Warehouse)
		|		OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		OR &EconomicOperationOfRealization <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods))
		|";
		
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators =
		"ToShip, Shipped, ReceivedBeforeTransferOfTitleToGoods, WrittenOffBeforeTransferOfTitleToGoods, Accepted, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);

	// 3. For shipment of goods to the customer without orders
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"VALUETYPE(ReferenceOrder) = TYPE(Document.GoodsShipmentToCustomer)
		|	AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Organization = &Organization
		|	AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Currency = &Currency
		|	AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Counterparty = &Counterparty
		|	AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Contract = &Contract
		|	AND CASE
		|		WHEN CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).VATTaxation IN (
		|					VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
		|					VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
		|					)
		|			THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|		ELSE 
		|			CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).VATTaxation
		|	END = &VATTaxation
		|	AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Partner = &Partner
		|	AND CASE
		|		WHEN NOT &ToUseTermsOfSales
		|			THEN TRUE
		|		ELSE 
		|			CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Terms = &Terms
		|	END
		|	AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).SalesOpportunity = &SalesOpportunity
		|	AND CASE
		|		WHEN NOT &UseLinesOfBusiness
		|			THEN TRUE
		|		ELSE 
		|			CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).LineOfBusiness = &LineOfBusiness
		|	END
		|	AND &EconomicOperationOfRealization = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|";
		
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators =
		"Shipped, ReceivedBeforeTransferOfTitleToGoods, WrittenOffBeforeTransferOfTitleToGoods, Accepted, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded3 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded3",
		ShipmentOrdersTurnoverExpanded3);

	// 4. For primary documents
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"VALUETYPE(ReferenceOrder) = TYPE(Document.SourceDocument)
		|	AND CAST(ReferenceOrder AS Document.SourceDocument).Organization = &Organization
		|	AND CAST(ReferenceOrder AS Document.SourceDocument).Currency = &Currency
		|	AND CAST(ReferenceOrder AS Document.SourceDocument).Counterparty = &Counterparty
		|	AND CAST(ReferenceOrder AS Document.SourceDocument).Contract = &Contract
		|	AND CAST(ReferenceOrder AS Document.SourceDocument).Partner = &Partner
		|	AND CASE
		|		WHEN CAST(ReferenceOrder AS Document.SourceDocument).VATTaxation IN (
		|					VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
		|					VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
		|					)
		|			THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|		ELSE 
		|			CAST(ReferenceOrder AS Document.SourceDocument).VATTaxation
		|	END = &VATTaxation
		|	AND &EconomicOperationOfRealization = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
		|";
		
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators =
		"Shipped, ReceivedBeforeTransferOfTitleToGoods, WrittenOffBeforeTransferOfTitleToGoods, Accepted, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded4 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded4",
		ShipmentOrdersTurnoverExpanded4);

	Query.SetParameter("Organization",               Parameters.Filter.Organization);
	Query.SetParameter("Counterparty",                Parameters.Filter.Counterparty);
	Query.SetParameter("Currency",                    Parameters.Filter.Currency);
	Query.SetParameter("Partner",                   Parameters.Filter.Partner);
	Query.SetParameter("VATTaxation",        Parameters.Filter.VATTaxation);
	Query.SetParameter("Terms",                Parameters.Filter.Terms);
	Query.SetParameter("PriceIncludesVAT",           Parameters.Filter.PriceIncludesVAT);
	Query.SetParameter("SalesOpportunity",                    Parameters.Filter.SalesOpportunity);
	Query.SetParameter("ToReturnReusablePackage", Parameters.Filter.ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired",      Parameters.Filter.PackageDepositIsRequired);
	Query.SetParameter("Contract",                   Parameters.Filter.Contract);
	Query.SetParameter("LineOfBusiness",   Parameters.Filter.LineOfBusiness);
	Query.SetParameter("ThisIsOrderAsInvoice",           Not Parameters.Filter.UseAdvancedFeaturesOfSalesOrder);
		
	Query.SetParameter("Recorder", Parameters.Recorder);
	Query.SetParameter("Warehouse",       Parameters.Warehouse);
	
	Query.SetParameter("ToUseTermsOfSales",
								GetFunctionalOption("ToUseTermsOfSales"));
	Query.SetParameter("UseLinesOfBusiness",
								GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness"));
	
	If Parameters.Filter.Property("BusinessOperation") Then
		
		If ValueIsFilled(Parameters.Filter.BusinessOperation) Then
			
			TransactionList = Documents.CustomerInvoice.AcceptableOperationsOfBaseDocuments(Parameters.Filter.BusinessOperation);
			
			Condition = "	And ";
			Query.SetParameter("BusinessTransactionList", TransactionList);
			Query.SetParameter("EconomicOperationOfRealization", Parameters.Filter.BusinessOperation);
			
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

