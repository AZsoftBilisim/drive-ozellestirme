
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
		Close(New Structure("SalesOrder, ARAPObjectSettings", 
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
	|INTO TheOrdersTable1
	|FROM
	|	(SELECT
	|		TurnoversByOrders.ReferenceOrder AS SalesOrder,
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover -
	|			TurnoversByOrders.IssuedQuantityTurnover) AS ToRegister
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded1 AS TurnoversByOrders
	|	WHERE
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover -
	|			TurnoversByOrders.IssuedQuantityTurnover) > 0
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
	|			WHEN SalesOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
	|				THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|			ELSE SalesOrder.VATTaxation
	|		END = &VATTaxation
	|		AND SalesOrder.Partner = &Partner
	|		AND CASE
	|				WHEN NOT &ToUseTermsOfSales
	|					THEN TRUE
	|				ELSE SalesOrder.Terms = &Terms
	|			END
	|		AND SalesOrder.PriceIncludesVAT = &PriceIncludesVAT
	|		AND SalesOrder.SalesOpportunity = &SalesOpportunity
	|		AND CustomerOrderGoods.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
	|		AND SalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|		AND NOT CustomerOrderGoods.Canceled
	|		AND SalesOrder.ThisIsOrderAsInvoice
	|		AND NOT SalesOrder.DeletionMark
	|		AND CASE
	|				WHEN NOT &UseLinesOfBusiness
	|					THEN TRUE
	|				ELSE SalesOrder.LineOfBusiness = &LineOfBusiness
	|			END
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OrdersRegisterRecords.ReferenceOrder AS SalesOrder,
	|		OrdersRegisterRecords.IssuedQuantity AS ToRegister
	|	FROM
	|		#OrdersForShipmentRegisteredRecordsExpanded1 AS OrdersRegisterRecords) AS OrdersTable
	|
	|GROUP BY
	|	OrdersTable.SalesOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersTable.SalesOrder AS SalesOrder,
	|	SUM(OrdersTable.ToRegister) AS ToRegister
	|INTO TheOrdersTable2
	|FROM
	|	(SELECT
	|		TurnoversByOrders.ReferenceOrder AS SalesOrder,
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover -
	|			TurnoversByOrders.IssuedQuantityTurnover) AS ToRegister
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded2 AS TurnoversByOrders
	|	WHERE
	|		(TurnoversByOrders.ForRegistrationQuantityTurnover -
	|			TurnoversByOrders.IssuedQuantityTurnover) > 0
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
	|			WHEN SalesOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
	|				THEN VALUE(Enum.VATTaxationTypes.ExportSale)
	|			ELSE SalesOrder.VATTaxation
	|		END = &VATTaxation
	|		AND SalesOrder.Partner = &Partner
	|		AND CASE
	|				WHEN NOT &ToUseTermsOfSales
	|					THEN TRUE
	|				ELSE SalesOrder.Terms = &Terms
	|			END
	|		AND SalesOrder.PriceIncludesVAT = &PriceIncludesVAT
	|		AND SalesOrder.SalesOpportunity = &SalesOpportunity
	|		AND CustomerOrderGoods.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
	|		AND SalesOrder.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleToCustomer), 
	|			VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer), 
	|			VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer))
	|		AND NOT CustomerOrderGoods.Canceled
	|		AND SalesOrder.ThisIsOrderAsInvoice
	|		AND NOT SalesOrder.DeletionMark
	|		AND CASE
	|				WHEN NOT &UseLinesOfBusiness
	|					THEN TRUE
	|				ELSE SalesOrder.LineOfBusiness = &LineOfBusiness
	|			END
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		OrdersRegisterRecords.ReferenceOrder AS SalesOrder,
	|		OrdersRegisterRecords.IssuedQuantity AS ToRegister
	|	FROM
	|		#OrdersForShipmentRegisteredRecordsExpanded2 AS OrdersRegisterRecords) AS OrdersTable
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
	|	END AS PictureOfPriority
	|FROM
	|	Document.SalesOrder AS Orders
	|		LEFT JOIN TheOrdersTable1 AS TheOrdersTable1
	|		ON Orders.Ref = TheOrdersTable1.SalesOrder
	|WHERE
	|	TheOrdersTable1.ToRegister > 0
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
	|	Requests.Comment,
	|	CASE
	|		WHEN Requests.Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute)
	|			THEN 0
	|		WHEN Requests.Priority IN
	|				(SELECT TOP 1
	|					Priorities.Ref AS Priority
	|				FROM
	|					Catalog.Priorities AS Priorities
	|				ORDER BY
	|					Priorities.AddlOrderingAttribute DESC)
	|			THEN 2
	|		ELSE 1
	|	END
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS Requests
	|		LEFT JOIN TheOrdersTable2 AS TheOrdersTable2
	|		ON Requests.Ref = TheOrdersTable2.SalesOrder
	|WHERE
	|	TheOrdersTable2.ToRegister > 0";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"Recorder = &Recorder
		|		AND Active
		|		AND ReferenceOrder.Organization = &Organization
		|		AND ReferenceOrder.Currency = &Currency
		|		AND ReferenceOrder.Counterparty = &Counterparty
		|		AND CASE
		|			WHEN ReferenceOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
		|				THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|			ELSE ReferenceOrder.VATTaxation
		|		END = &VATTaxation
		|		AND ReferenceOrder.Partner = &Partner
		|		AND CASE
		|				WHEN NOT &ToUseTermsOfSales
		|					THEN TRUE
		|				ELSE ReferenceOrder.Terms = &Terms
		|			END
		|		AND ReferenceOrder.PriceIncludesVAT = &PriceIncludesVAT
		|		AND ReferenceOrder.SalesOpportunity = &SalesOpportunity
		|		AND Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
		|		AND ReferenceOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|		AND CASE
		|				WHEN NOT &UseLinesOfBusiness
		|					THEN TRUE
		|				ELSE ReferenceOrder.LineOfBusiness = &LineOfBusiness
		|			END";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators = "Issued_1";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.PhysicalTable = True;
	
	OrdersForShipmentRegisteredRecordsExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#OrdersForShipmentRegisteredRecordsExpanded1",
		OrdersForShipmentRegisteredRecordsExpanded1);
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"Recorder = &Recorder
		|		AND Active
		|		AND ReferenceOrder.Organization = &Organization
		|		AND ReferenceOrder.Currency = &Currency
		|		AND ReferenceOrder.Counterparty = &Counterparty
		|		AND CASE
		|			WHEN ReferenceOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
		|				THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|			ELSE ReferenceOrder.VATTaxation
		|		END = &VATTaxation
		|		AND ReferenceOrder.Partner = &Partner
		|		AND CASE
		|				WHEN NOT &ToUseTermsOfSales
		|					THEN TRUE
		|				ELSE ReferenceOrder.Terms = &Terms
		|			END
		|		AND ReferenceOrder.PriceIncludesVAT = &PriceIncludesVAT
		|		AND ReferenceOrder.SalesOpportunity = &SalesOpportunity
		|		AND Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
		|		AND CASE
		|				WHEN NOT &UseLinesOfBusiness
		|					THEN TRUE
		|				ELSE ReferenceOrder.LineOfBusiness = &LineOfBusiness
		|			END
		|		AND ReferenceOrder.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleToCustomer), 
		|			VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer), 
		|			VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer))";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators = "Issued_1";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.PhysicalTable = True;
	
	OrdersForShipmentRegisteredRecordsExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#OrdersForShipmentRegisteredRecordsExpanded2",
		OrdersForShipmentRegisteredRecordsExpanded2);
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder.Organization = &Organization
		|		AND ReferenceOrder.Currency = &Currency
		|		AND ReferenceOrder.Counterparty = &Counterparty
		|		AND CASE
		|				WHEN ReferenceOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
		|					THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|				ELSE ReferenceOrder.VATTaxation
		|			END = &VATTaxation
		|		AND ReferenceOrder.Partner = &Partner
		|		AND CASE
		|				WHEN NOT &ToUseTermsOfSales
		|					THEN TRUE
		|				ELSE ReferenceOrder.Terms = &Terms
		|			END
		|		AND ReferenceOrder.PriceIncludesVAT = &PriceIncludesVAT
		|		AND ReferenceOrder.SalesOpportunity = &SalesOpportunity
		|		AND Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
		|		AND ReferenceOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|		AND CASE
		|				WHEN NOT &UseLinesOfBusiness
		|					THEN TRUE
		|				ELSE ReferenceOrder.LineOfBusiness = &LineOfBusiness
		|			END";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded1",
		ShipmentOrdersTurnoverExpanded1);
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder.Organization = &Organization
		|		AND ReferenceOrder.Currency = &Currency
		|		AND ReferenceOrder.Counterparty = &Counterparty
		|		AND CASE
		|				WHEN ReferenceOrder.VATTaxation IN (VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks), VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods))
		|					THEN VALUE(Enum.VATTaxationTypes.ExportSale)
		|				ELSE ReferenceOrder.VATTaxation
		|			END = &VATTaxation
		|		AND ReferenceOrder.Partner = &Partner
		|		AND CASE
		|				WHEN NOT &ToUseTermsOfSales
		|					THEN TRUE
		|				ELSE ReferenceOrder.Terms = &Terms
		|			END
		|		AND ReferenceOrder.PriceIncludesVAT = &PriceIncludesVAT
		|		AND ReferenceOrder.SalesOpportunity = &SalesOpportunity
		|		AND Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.CustomerInvoiceServices)
		|		AND CASE
		|				WHEN NOT &UseLinesOfBusiness
		|					THEN TRUE
		|				ELSE ReferenceOrder.LineOfBusiness = &LineOfBusiness
		|			END
		|		AND ReferenceOrder.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleToCustomer), 
		|			VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer), 
		|			VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer))";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded2",
		ShipmentOrdersTurnoverExpanded2);
	
	Query.SetParameter("Organization", 			 Parameters.Filter.Organization);
	Query.SetParameter("Counterparty",  			 Parameters.Filter.Counterparty);
	Query.SetParameter("Currency",     			 Parameters.Filter.Currency);
	Query.SetParameter("Partner",    			 Parameters.Filter.Partner);
	Query.SetParameter("VATTaxation",      Parameters.Filter.VATTaxation);
	Query.SetParameter("Terms", 			 Parameters.Filter.Terms);
	Query.SetParameter("PriceIncludesVAT", 		 Parameters.Filter.PriceIncludesVAT);
	Query.SetParameter("SalesOpportunity", 				 Parameters.Filter.SalesOpportunity);
	Query.SetParameter("LineOfBusiness", Parameters.Filter.LineOfBusiness);
	Query.SetParameter("Contract",		 		 Parameters.Filter.Contract);
	
	Query.SetParameter("Recorder", Parameters.Recorder);
	
	Query.SetParameter("ToUseTermsOfSales", 
								GetFunctionalOption("ToUseTermsOfSales"));
	Query.SetParameter("UseLinesOfBusiness", 
								GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness"));
		
	Result = Query.Execute();
	ListOfOrders_.Load(Result.Unload());
	
EndProcedure

#EndRegion
