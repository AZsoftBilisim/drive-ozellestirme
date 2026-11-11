
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Var FilterValue;
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, List);
	ListProperties.QueryText = QueryTextList();
	Common.SetDynamicListProperties(Items.List, ListProperties);
	ThisIsTransferOfOwnership2_5 = False;
	
	If Parameters.Filter.Property("BusinessOperation") Then
		
		If ValueIsFilled(Parameters.Filter.BusinessOperation) Then
			
			BusinessTransactionParameter = Parameters.Filter.BusinessOperation;
			
			If Parameters.Filter.BusinessOperation =
				Enums.BusinessTransactions.TransferOfTitleToGoods Then
				
				BusinessTransactionParameter = Enums.BusinessTransactions.SaleToCustomer;
				ThisIsTransferOfOwnership2_5 = True;
			EndIf;
			
			CommonClientServer.SetDynamicListFilterItem(
				List,
				"BusinessOperation",
				BusinessTransactionParameter,
				,,True);
			
		Else
			
			CommonClientServer.SetDynamicListFilterItem(
				List,
				"BusinessOperation",
				Enums.BusinessTransactions.TransferToCommissionAgent,
				DataCompositionComparisonType.NotEqual,, True);
			
		EndIf;
		
		Parameters.Filter.Delete("BusinessOperation");
		
	EndIf;
	
	ArrayOfSelections = New Array;
	ArrayOfSelections.Add("Organization");
	ArrayOfSelections.Add("Currency");
	ArrayOfSelections.Add("Counterparty");
	ArrayOfSelections.Add("Contract");
	ArrayOfSelections.Add("VATTaxation");
	ArrayOfSelections.Add("Partner");
	ArrayOfSelections.Add("Terms");
	ArrayOfSelections.Add("PriceIncludesVAT");
	
	For Each FilterName In ArrayOfSelections Do
		If Parameters.Filter.Property(FilterName, FilterValue) Then
			
			CommonClientServer.SetDynamicListParameter(
				List,
				FilterName,
				FilterValue);
			
			Parameters.Filter.Delete(FilterName);
			
		EndIf;
	EndDo;
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"Warehouse",
		Parameters.Warehouse);
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"DocumentBasis",
		Parameters.DocumentBasis);
		
	CommonClientServer.SetDynamicListParameter(
		List,
		"ToUseTermsOfSales",
		GetFunctionalOption("ToUseTermsOfSales"));
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"ThisIsTransferOfOwnership2_5",
		ThisIsTransferOfOwnership2_5);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.List.CurrentData;
	NotifyChoice(CurrentRow.Ref);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectReference(Command)
	
	CurrentRow = Items.List.CurrentData;
	
	If CurrentRow <> Undefined Then
		NotifyChoice(CurrentRow.Ref);
	Else
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenDocument(Command)
	
	CurrentRow = Items.List.CurrentData;
	
	If CurrentRow <> Undefined Then
		ShowValue(Undefined, CurrentRow.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function QueryTextList()
	
	QueryText =
	"SELECT ALLOWED
	|	OrdersTable.SalesOrder AS Ref,
	|	VALUETYPE(OrdersTable.SalesOrder) AS TypeOfOrder_,
	|	OrdersTable.SalesOrder.Date AS Date,
	|	OrdersTable.SalesOrder.Number AS Number,
	|	OrdersTable.SalesOrder.Partner AS Partner,
	|	OrdersTable.SalesOrder.Counterparty AS Counterparty,
	|	OrdersTable.SalesOrder.Contract AS Contract,
	|	OrdersTable.SalesOrder.Terms AS Terms,
	|	OrdersTable.SalesOrder.Organization AS Organization,
	|	OrdersTable.SalesOrder.Warehouse AS Warehouse,
	|	OrdersTable.SalesOrder.Currency AS Currency,
	|	OrdersTable.SalesOrder.Manager AS Manager,
	|	OrdersTable.SalesOrder.Status AS Status,
	|	OrdersTable.SalesOrder.DocumentAmount AS DocumentAmount,
	|	OrdersTable.SalesOrder.Priority AS Priority,
	|	OrdersTable.SalesOrder.BusinessOperation AS BusinessOperation,
	|	OrdersTable.SalesOrder.VATTaxation AS VATTaxation,
	|	CASE
	|		WHEN OrdersTable.SalesOrder REFS Document.GoodsShipmentToCustomer
	|			THEN TRUE
	|		WHEN OrdersTable.SalesOrder REFS Document.SourceDocument
	|			THEN UNDEFINED
	|		ELSE
	|			OrdersTable.SalesOrder.PriceIncludesVAT
	|	END AS PriceIncludesVAT,
	|	OrdersTable.SalesOrder.Comment AS Comment,
	|	CASE
	|		WHEN OrdersTable.SalesOrder.Priority IN
	|			(SELECT TOP 1
	|				Priorities.Ref AS Priority
	|			FROM
	|				Catalog.Priorities AS Priorities
	|
	|			ORDER BY
	|				Priorities.AddlOrderingAttribute)
	|			THEN 0
	|		WHEN OrdersTable.SalesOrder.Priority IN
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
	|	(SELECT
	|		OrdersTable.SalesOrder AS SalesOrder,
	|		SUM(OrdersTable.ToRegister) AS ToRegister
	|	FROM
	|		(SELECT
	|			TurnoversByOrders.ReferenceOrder AS SalesOrder,
	|			CASE
	|				WHEN &ThisIsTransferOfOwnership2_5
	|					THEN TurnoversByOrders.ShippedQuantityTurnover
	|							+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|							- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|							- TurnoversByOrders.QuantityAccepted_Turnover
	|							- TurnoversByOrders.IssuedQuantityTurnover
	|				ELSE
	|					TurnoversByOrders.QuantityToBeShippedTurnover
	|						- TurnoversByOrders.ShippedQuantityTurnover
	|			END AS ToRegister
	|		FROM
	|			#ShipmentOrdersTurnoverExpanded1 AS TurnoversByOrders
	|		WHERE
	|			CASE
	|				WHEN &ThisIsTransferOfOwnership2_5
	|					THEN TurnoversByOrders.ShippedQuantityTurnover
	|							+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|							- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|							- TurnoversByOrders.QuantityAccepted_Turnover
	|							- TurnoversByOrders.IssuedQuantityTurnover
	|				ELSE
	|					TurnoversByOrders.QuantityToBeShippedTurnover
	|						- TurnoversByOrders.ShippedQuantityTurnover
	|			END <> 0
	|
	|		UNION ALL
	|
	|		SELECT
	|			TurnoversByOrders.ReferenceOrder AS SalesOrder,
	|			CASE
	|				WHEN &ThisIsTransferOfOwnership2_5
	|					THEN TurnoversByOrders.ShippedQuantityTurnover
	|							+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|							- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|							- TurnoversByOrders.QuantityAccepted_Turnover
	|							- TurnoversByOrders.IssuedQuantityTurnover
	|				ELSE
	|					TurnoversByOrders.QuantityToBeShippedTurnover
	|						- TurnoversByOrders.ShippedQuantityTurnover
	|			END AS ToRegister
	|		FROM
	|			#ShipmentOrdersTurnoverExpanded2 AS TurnoversByOrders
	|		WHERE
	|			CASE
	|				WHEN &ThisIsTransferOfOwnership2_5
	|					THEN TurnoversByOrders.ShippedQuantityTurnover
	|							+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|							- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|							- TurnoversByOrders.QuantityAccepted_Turnover
	|							- TurnoversByOrders.IssuedQuantityTurnover
	|				ELSE
	|					TurnoversByOrders.QuantityToBeShippedTurnover
	|						- TurnoversByOrders.ShippedQuantityTurnover
	|			END <> 0
	|
	|		UNION ALL
	|
	|		SELECT
	|			TurnoversByOrders.ReferenceOrder AS SalesOrder,
	|			(TurnoversByOrders.ForRegistrationQuantityTurnover -
	|				TurnoversByOrders.IssuedQuantityTurnover) AS ToRegister
	|		FROM
	|			#ShipmentOrdersTurnoverExpanded3 AS TurnoversByOrders
	|		WHERE
	|			(TurnoversByOrders.ForRegistrationQuantityTurnover -
	|				TurnoversByOrders.IssuedQuantityTurnover) <> 0
	|
	|		UNION ALL
	|
	|
	|		SELECT
	|			TurnoversByOrders.ReferenceOrder AS SalesOrder,
	|			TurnoversByOrders.ShippedQuantityTurnover
	|				+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|				- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|				- TurnoversByOrders.QuantityAccepted_Turnover
	|				- TurnoversByOrders.IssuedQuantityTurnover AS ToRegister
	|		FROM
	|			#ShipmentOrdersTurnoverExpanded4 AS TurnoversByOrders
	|		WHERE
	|			TurnoversByOrders.ShippedQuantityTurnover
	|				+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|				- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|				- TurnoversByOrders.QuantityAccepted_Turnover
	|				- TurnoversByOrders.IssuedQuantityTurnover <> 0
	|
	|		UNION ALL
	|
	|		SELECT
	|			TurnoversByOrders.ReferenceOrder AS SalesOrder,
	|			TurnoversByOrders.ShippedQuantityTurnover
	|				+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|				- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|				- TurnoversByOrders.QuantityAccepted_Turnover
	|				- TurnoversByOrders.IssuedQuantityTurnover AS ToRegister
	|		FROM
	|			#ShipmentOrdersTurnoverExpanded5 AS TurnoversByOrders
	|		WHERE
	|			TurnoversByOrders.ShippedQuantityTurnover
	|				+ TurnoversByOrders.RegisteredUpToPPPQuantityTurnover
	|				- TurnoversByOrders.DeductedToPPPQuantityTurnover
	|				- TurnoversByOrders.QuantityAccepted_Turnover
	|				- TurnoversByOrders.IssuedQuantityTurnover <> 0
	|
	|		UNION ALL
	|
	|		SELECT
	|			OrdersRegisterRecords.ReferenceOrder,
	|			OrdersRegisterRecords.ForRegistrationQuantity + OrdersRegisterRecords.IssuedQuantity
	|		FROM
	|			#OrdersForShipmentRegisteredRecordsExpanded AS OrdersRegisterRecords) AS OrdersTable
	|
	|	GROUP BY
	|		OrdersTable.SalesOrder) AS OrdersTable
	|WHERE
	|	OrdersTable.ToRegister > 0";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"VALUETYPE(ReferenceOrder) = TYPE(Document.SalesOrder)
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).Organization = &Organization
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).Currency = &Currency
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).Counterparty = &Counterparty
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).Contract = &Contract
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).VATTaxation IN (&VATTaxation)
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).Partner = &Partner
		|	AND CASE
		|		WHEN NOT &ToUseTermsOfSales
		|			THEN TRUE
		|		ELSE
		|			CAST(ReferenceOrder AS Document.SalesOrder).Terms = &Terms
		|	END
		|	AND CAST(ReferenceOrder AS Document.SalesOrder).PriceIncludesVAT = &PriceIncludesVAT
		|	AND (Warehouse = &Warehouse
		|		OR Warehouse IN HIERARCHY (&Warehouse)
		|		OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		OR &ThisIsTransferOfOwnership2_5)";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators =
		"ToShip, Shipped, ReceivedBeforeTransferOfTitleToGoods, WrittenOffBeforeTransferOfTitleToGoods, Accepted, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded1",
		ShipmentOrdersTurnoverExpanded1);
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"VALUETYPE(ReferenceOrder) = TYPE(Document.RequestForReturnOfGoodsFromCustomer)
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Organization = &Organization
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Currency = &Currency
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Counterparty = &Counterparty
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Contract = &Contract
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).VATTaxation IN (&VATTaxation)
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Partner = &Partner
		|	AND CASE
		|		WHEN NOT &ToUseTermsOfSales
		|			THEN TRUE
		|		ELSE CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Terms = &Terms
		|	END
		|	AND CAST(ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).PriceIncludesVAT = &PriceIncludesVAT
		|	AND (Warehouse = &Warehouse
		|		OR Warehouse IN HIERARCHY (&Warehouse)
		|		OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		OR &ThisIsTransferOfOwnership2_5)";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators =
		"ToShip, Shipped, ReceivedBeforeTransferOfTitleToGoods, WrittenOffBeforeTransferOfTitleToGoods, Accepted, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"VALUETYPE(ReferenceOrder) = TYPE(Document.MaterialProviderOrder2_5)
		|	AND CAST(ReferenceOrder AS Document.MaterialProviderOrder2_5).Organization = &Organization
		|	AND CAST(ReferenceOrder AS Document.MaterialProviderOrder2_5).Currency = &Currency
		|	AND CAST(ReferenceOrder AS Document.MaterialProviderOrder2_5).Counterparty = &Counterparty
		|	AND CAST(ReferenceOrder AS Document.MaterialProviderOrder2_5).Contract = &Contract
		|	AND CAST(ReferenceOrder AS Document.MaterialProviderOrder2_5).VATTaxation IN (&VATTaxation)
		|	AND CAST(ReferenceOrder AS Document.MaterialProviderOrder2_5).Partner = &Partner
		|	AND CAST(ReferenceOrder AS Document.MaterialProviderOrder2_5).PriceIncludesVAT = &PriceIncludesVAT
		|	AND (Warehouse = &Warehouse
		|		OR Warehouse IN HIERARCHY (&Warehouse)
		|		OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef))";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded3 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded3",
		ShipmentOrdersTurnoverExpanded3);
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"VALUETYPE(ReferenceOrder) = TYPE(Document.GoodsShipmentToCustomer)
		|	AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Organization = &Organization
		|	AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Currency = &Currency
		|	AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Counterparty = &Counterparty
		|	AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Contract = &Contract
		|	AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).VATTaxation IN (&VATTaxation)
		|	AND CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Partner = &Partner
		|	AND CASE
		|		WHEN NOT &ToUseTermsOfSales
		|			THEN TRUE
		|		ELSE CAST(ReferenceOrder AS Document.GoodsShipmentToCustomer).Terms = &Terms
		|	END
		|	AND &PriceIncludesVAT = TRUE";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators =
		"ToShip, Shipped, ReceivedBeforeTransferOfTitleToGoods, WrittenOffBeforeTransferOfTitleToGoods, Accepted, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded4 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded4",
		ShipmentOrdersTurnoverExpanded4);

	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"VALUETYPE(ReferenceOrder) = TYPE(Document.SourceDocument)
		|	AND CAST(ReferenceOrder AS Document.SourceDocument).Organization = &Organization
		|	AND CAST(ReferenceOrder AS Document.SourceDocument).Currency = &Currency
		|	AND CAST(ReferenceOrder AS Document.SourceDocument).Counterparty = &Counterparty
		|	AND CAST(ReferenceOrder AS Document.SourceDocument).Contract = &Contract
		|	AND CAST(ReferenceOrder AS Document.SourceDocument).VATTaxation IN (&VATTaxation)
		|	AND CAST(ReferenceOrder AS Document.SourceDocument).Partner = &Partner";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators =
		"ToShip, Shipped, ReceivedBeforeTransferOfTitleToGoods, WrittenOffBeforeTransferOfTitleToGoods, Accepted, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded5 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded5",
		ShipmentOrdersTurnoverExpanded5);

	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"(Recorder = &DocumentBasis
		|		OR Recorder IN
		|			(SELECT
		|					AdjustingEntries.Ref
		|				FROM
		|					Document.SaleAdjustment AS AdjustingEntries
		|				WHERE
		|					AdjustingEntries.DocumentBasis = &DocumentBasis
		|					AND AdjustingEntries.Posted))
		|	AND Active
		|	AND (VALUETYPE(ReferenceOrder) = TYPE(Document.SalesOrder)
		|		OR VALUETYPE(ReferenceOrder) = TYPE(Document.MaterialProviderOrder2_5)
		|		OR VALUETYPE(ReferenceOrder) = TYPE(Document.RequestForReturnOfGoodsFromCustomer))";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.PhysicalTable = True;
	
	OrdersForShipmentRegisteredRecordsExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#OrdersForShipmentRegisteredRecordsExpanded",
		OrdersForShipmentRegisteredRecordsExpanded);

	Return QueryText;
	
EndFunction

#EndRegion